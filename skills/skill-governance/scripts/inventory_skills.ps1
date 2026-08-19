[CmdletBinding()]
param(
  [string[]]$Roots = @(),
  [ValidateSet("tsv", "json")]
  [string]$Format = "tsv",
  [ValidateSet("entries", "registry")]
  [string]$View = "entries",
  [ValidateSet("active", "raw-cache")]
  [string]$Scope = "active",
  [switch]$IncludePluginBackups,
  [string]$ConfigPath = "$HOME\.codex\config.toml",
  [string]$OverridesPath = (Join-Path $PSScriptRoot "..\references\skill-registry-overrides.json"),
  [string]$DomainsPath = (Join-Path $PSScriptRoot "..\references\skill-routing-domains.json"),
  [string]$LocalizationPath = (Join-Path $PSScriptRoot "..\references\skill-localization.zh-CN.json"),
  [string]$RegistryPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$codexRoot = [IO.Path]::GetFullPath("$HOME\.codex\skills")
$systemRoot = [IO.Path]::GetFullPath("$HOME\.codex\skills\.system")
$agentsRoot = [IO.Path]::GetFullPath("$HOME\.agents\skills")
$pluginsRoot = [IO.Path]::GetFullPath("$HOME\.codex\plugins\cache")
$agentsLockPath = [IO.Path]::GetFullPath("$HOME\.agents\.skill-lock.json")
$scoreLogPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\references\skill-use-log.md"))
$evidenceLedgerPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\references\skill-use-ledger.jsonl"))

function Test-PathWithin {
  param([string]$Path, [string]$Root)

  $fullPath = [IO.Path]::GetFullPath($Path).TrimEnd('\')
  $fullRoot = [IO.Path]::GetFullPath($Root).TrimEnd('\')
  return $fullPath.Equals($fullRoot, [StringComparison]::OrdinalIgnoreCase) -or
    $fullPath.StartsWith($fullRoot + '\', [StringComparison]::OrdinalIgnoreCase)
}

function Get-ObjectProperty {
  param([object]$Object, [string]$Name)

  if ($null -eq $Object) {
    return $null
  }
  $property = $Object.PSObject.Properties[$Name]
  if ($null -eq $property) {
    return $null
  }
  return $property.Value
}

function Resolve-SkillLocalization {
  param(
    [string]$Name,
    [string]$RoutingStatus,
    [object]$Localization
  )

  $localizedSkills = Get-ObjectProperty -Object $Localization -Name 'skills'
  $curated = Get-ObjectProperty -Object $localizedSkills -Name $Name
  $displayName = Get-ObjectProperty -Object $curated -Name 'display_name_zh'
  $description = Get-ObjectProperty -Object $curated -Name 'description_zh'
  $aliases = Get-ObjectProperty -Object $curated -Name 'aliases_zh'
  $source = 'curated'

  if ([string]::IsNullOrWhiteSpace([string]$displayName)) {
    $translations = Get-ObjectProperty -Object $Localization -Name 'token_translations'
    $tokens = @($Name -split '[-_:]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $translated = foreach ($token in $tokens) {
      $value = Get-ObjectProperty -Object $translations -Name $token.ToLowerInvariant()
      if ($null -ne $value) { [string]$value } else { $token }
    }
    $displayName = ($translated -join ' ').Trim()
    if ([string]::IsNullOrWhiteSpace($displayName)) { $displayName = $Name }
    if ($displayName -notmatch '[\p{IsCJKUnifiedIdeographs}]') { $displayName = "$displayName 工具" }
    $description = ('用于「{0}」相关任务；具体职责以原 Skill 说明和项目规则为准。' -f $displayName)
    $aliases = @($displayName)
    $source = 'generated'
  }

  if ($null -eq $aliases) { $aliases = @($displayName) }
  $triggerMode = if ($RoutingStatus -in @('explicit_only', 'candidate', 'unassessed', 'archived', 'unavailable_legacy')) { 'display_only' } else { 'governed' }
  [pscustomobject]@{
    display_name_zh = [string]$displayName
    description_zh = [string]$description
    aliases_zh = @($aliases | ForEach-Object { [string]$_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
    localization_source = $source
    chinese_trigger_mode = $triggerMode
  }
}

function Resolve-DomainRole {
  param(
    [string]$Name,
    [string]$RoutingStatus,
    [object]$Domain
  )

  if ($null -ne $Domain) {
    if (@(Get-ObjectProperty -Object $Domain -Name 'entry_routes') -contains $Name) { return 'entry' }
    if (@(Get-ObjectProperty -Object $Domain -Name 'default_routes') -contains $Name) { return 'default' }
    if (@(Get-ObjectProperty -Object $Domain -Name 'supporting_routes') -contains $Name) { return 'supporting' }
    if (@(Get-ObjectProperty -Object $Domain -Name 'explicit_execution_routes') -contains $Name) { return 'explicit_execution' }
    if (@(Get-ObjectProperty -Object $Domain -Name 'candidate_routes') -contains $Name) { return 'candidate' }
  }

  switch ($RoutingStatus) {
    'mandatory' { return 'prerequisite' }
    'user_designated' { return 'default' }
    'evidence_backed_champion' { return 'default' }
    'provisional_default' { return 'default' }
    'primary' { return 'specialist_primary' }
    'supporting' { return 'supporting' }
    'explicit_only' { return 'explicit_only' }
    'candidate' { return 'candidate' }
    'archived' { return 'inactive' }
    'unavailable_legacy' { return 'inactive' }
    default { return 'unassessed' }
  }
}

function Get-EnabledPluginSpecs {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    throw "Codex config not found: $Path. Pass -Roots for an explicit inventory."
  }

  $enabledIds = [Collections.Generic.List[string]]::new()
  $currentPlugin = $null
  foreach ($line in Get-Content -LiteralPath $Path) {
    if ($line -match '^\s*\[plugins\."([^"]+)"\]\s*$') {
      $currentPlugin = $Matches[1]
      continue
    }
    if ($line -match '^\s*\[') {
      $currentPlugin = $null
      continue
    }
    if ($null -ne $currentPlugin -and $line -match '^\s*enabled\s*=\s*(true|false)\s*$') {
      if ($Matches[1] -eq 'true') {
        $enabledIds.Add($currentPlugin)
      }
      $currentPlugin = $null
    }
  }

  foreach ($pluginId in $enabledIds) {
    $separator = $pluginId.LastIndexOf('@')
    if ($separator -lt 1 -or $separator -eq ($pluginId.Length - 1)) {
      throw "Invalid enabled plugin id in ${Path}: $pluginId"
    }
    $pluginName = $pluginId.Substring(0, $separator)
    $marketplace = $pluginId.Substring($separator + 1)
    $pluginRoot = Join-Path $pluginsRoot "$marketplace\$pluginName"
    if (-not (Test-Path -LiteralPath $pluginRoot -PathType Container)) {
      throw "Enabled plugin cache is missing: $pluginId -> $pluginRoot"
    }

    $latestPath = Join-Path $pluginRoot 'latest'
    if ((Test-Path -LiteralPath $latestPath -PathType Container) -and
        (Test-Path -LiteralPath (Join-Path $latestPath 'skills') -PathType Container)) {
      $latestItem = Get-Item -LiteralPath $latestPath
      $target = @($latestItem.Target)[0]
      if ([string]::IsNullOrWhiteSpace($target)) {
        throw "Enabled plugin latest alias has no target: $pluginId -> $latestPath"
      }
      if (-not [IO.Path]::IsPathRooted($target)) {
        $target = Join-Path $pluginRoot $target
      }
      $versions = @(Get-Item -LiteralPath ([IO.Path]::GetFullPath($target)))
    } else {
      $versions = @(
        Get-ChildItem -LiteralPath $pluginRoot -Directory |
          Where-Object {
            $_.Name -ne 'latest' -and
            (Test-Path -LiteralPath (Join-Path $_.FullName 'skills') -PathType Container)
          }
      )
    }
    if ($versions.Count -ne 1) {
      $found = if ($versions.Count -eq 0) { '<none>' } else { ($versions.Name -join ', ') }
      throw "Enabled plugin $pluginId must resolve to exactly one cached version; found: $found"
    }

    [pscustomobject]@{
      PluginId = $pluginId
      PluginName = $pluginName
      Marketplace = $marketplace
      Version = $versions[0].Name
      Path = $versions[0].FullName
    }
  }
}

function Get-PluginMetadataFromPath {
  param([string]$Path)

  $relative = [IO.Path]::GetRelativePath($pluginsRoot, $Path)
  $segments = $relative -split '[\\/]'
  if ($segments.Count -lt 4) {
    return $null
  }
  if ($segments[1] -like 'plugin-backup-*') {
    return [pscustomobject]@{
      PluginId = "$($segments[1])@$($segments[0])"
      PluginName = $segments[1]
      Marketplace = $segments[0]
      Version = if ($segments.Count -gt 3) { $segments[3] } else { '' }
    }
  }
  return [pscustomobject]@{
    PluginId = "$($segments[1])@$($segments[0])"
    PluginName = $segments[1]
    Marketplace = $segments[0]
    Version = $segments[2]
  }
}

function Read-SkillMetadata {
  param([IO.FileInfo]$File)

  $text = Get-Content -Raw -LiteralPath $File.FullName
  if ([string]::IsNullOrEmpty($text) -or $text.IndexOf([char]0) -ge 0) {
    throw "Skill entry is empty or contains NUL bytes: $($File.FullName)"
  }
  $name = $File.Directory.Name
  $description = ""
  $missingName = $true

  if ($text -match '(?m)^name:\s*(.+?)\s*$') {
    $name = $Matches[1].Trim(" `"'")
    $missingName = $false
  }
  if ($text -match '(?ms)^description:\s*(.+?)(?:\r?\n[a-zA-Z_-]+:|\r?\n---)') {
    $description = $Matches[1].Trim().Trim('"').Replace("`r", " ").Replace("`n", " ")
    $description = $description -replace '\s+', ' '
  }

  [pscustomobject]@{
    Name = $name
    Description = $description
    MissingName = $missingName
    Lines = ($text -split "\r?\n").Count
    SHA256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $File.FullName).Hash.ToLowerInvariant()
  }
}

$agentsLock = $null
if (Test-Path -LiteralPath $agentsLockPath -PathType Leaf) {
  $agentsLock = Get-Content -Raw -LiteralPath $agentsLockPath | ConvertFrom-Json -Depth 20
}

$overrides = $null
if (Test-Path -LiteralPath $OverridesPath -PathType Leaf) {
  $overrides = Get-Content -Raw -LiteralPath $OverridesPath | ConvertFrom-Json -Depth 30
}

$domainContract = $null
if (Test-Path -LiteralPath $DomainsPath -PathType Leaf) {
  $domainContract = Get-Content -Raw -LiteralPath $DomainsPath | ConvertFrom-Json -Depth 30
}
if ($null -eq $domainContract) {
  throw "Skill routing domain contract not found: $DomainsPath"
}

$localization = $null
if (Test-Path -LiteralPath $LocalizationPath -PathType Leaf) {
  $localization = Get-Content -Raw -LiteralPath $LocalizationPath | ConvertFrom-Json -Depth 30
}
if ($null -eq $localization) {
  throw "Missing Skill localization catalog: $LocalizationPath"
}
$routingDomains = @(Get-ObjectProperty -Object $domainContract -Name 'domains')
$controlPlanes = @(Get-ObjectProperty -Object $domainContract -Name 'control_planes')
$capabilityEnvelope = Get-ObjectProperty -Object $domainContract -Name 'capability_envelope'
$domainByFamily = @{}
$domainById = @{}
foreach ($domain in $routingDomains) {
  $domainId = [string](Get-ObjectProperty -Object $domain -Name 'id')
  if ([string]::IsNullOrWhiteSpace($domainId) -or $domainById.ContainsKey($domainId)) {
    throw "Skill routing domain ids must be present and unique: $domainId"
  }
  $domainById[$domainId] = $domain
  foreach ($family in @(Get-ObjectProperty -Object $domain -Name 'families')) {
    if ($domainByFamily.ContainsKey($family)) {
      throw "Skill family is mapped to more than one routing domain: $family"
    }
    $domainByFamily[$family] = $domain
  }
}

$rootSpecs = [Collections.Generic.List[object]]::new()
if ($Roots.Count -gt 0) {
  foreach ($root in $Roots) {
    $rootSpecs.Add([pscustomobject]@{ Path = [IO.Path]::GetFullPath($root); Plugin = $null })
  }
} else {
  $rootSpecs.Add([pscustomobject]@{ Path = $codexRoot; Plugin = $null })
  $rootSpecs.Add([pscustomobject]@{ Path = $agentsRoot; Plugin = $null })
  if ($Scope -eq 'active') {
    foreach ($plugin in Get-EnabledPluginSpecs -Path $ConfigPath) {
      $rootSpecs.Add([pscustomobject]@{ Path = $plugin.Path; Plugin = $plugin })
    }
  } else {
    $rootSpecs.Add([pscustomobject]@{ Path = $pluginsRoot; Plugin = $null })
  }
}

$filesByPath = @{}
foreach ($rootSpec in $rootSpecs) {
  if (-not (Test-Path -LiteralPath $rootSpec.Path -PathType Container)) {
    continue
  }
  foreach ($file in Get-ChildItem -LiteralPath $rootSpec.Path -Recurse -Filter SKILL.md -File) {
    if (-not $IncludePluginBackups -and $file.FullName -match '\\plugin-backup-[^\\]+\\') {
      continue
    }
    if (Test-PathWithin -Path $file.FullName -Root $codexRoot) {
      $codexRelative = [IO.Path]::GetRelativePath($codexRoot, $file.FullName)
      $codexTopFolder = ($codexRelative -split '[\\/]')[0]
      if ($codexTopFolder -eq 'skill_route_snapshots' -or $codexTopFolder -like '_backup*') {
        continue
      }
    }
    $key = [IO.Path]::GetFullPath($file.FullName).ToLowerInvariant()
    if (-not $filesByPath.ContainsKey($key)) {
      $filesByPath[$key] = [pscustomobject]@{ File = $file; Plugin = $rootSpec.Plugin }
    }
  }
}

$issues = [Collections.Generic.List[object]]::new()
$items = foreach ($record in $filesByPath.Values) {
  $file = $record.File
  $metadata = Read-SkillMetadata -File $file
  $source = if (Test-PathWithin -Path $file.FullName -Root $systemRoot) {
    'system'
  } elseif (Test-PathWithin -Path $file.FullName -Root $codexRoot) {
    'codex-user'
  } elseif (Test-PathWithin -Path $file.FullName -Root $agentsRoot) {
    'agents'
  } elseif (Test-PathWithin -Path $file.FullName -Root $pluginsRoot) {
    'plugin'
  } else {
    'custom'
  }

  $plugin = $record.Plugin
  if ($source -eq 'plugin' -and $null -eq $plugin) {
    $plugin = Get-PluginMetadataFromPath -Path $file.FullName
  }

  $owner = switch ($source) {
    'system' { 'openai-system' }
    'codex-user' { 'user' }
    'plugin' { "plugin:$($plugin.PluginId)" }
    'agents' {
      $relative = [IO.Path]::GetRelativePath($agentsRoot, $file.FullName)
      $folder = ($relative -split '[\\/]')[0]
      $lockedSkill = if ($null -ne $agentsLock) { Get-ObjectProperty -Object $agentsLock.skills -Name $folder } else { $null }
      $lockedSource = Get-ObjectProperty -Object $lockedSkill -Name 'source'
      if ($null -ne $lockedSource) { "github:$lockedSource" } else { 'agents-local' }
    }
    default { 'custom' }
  }

  $qualifiedId = if ($source -eq 'plugin') { "$($plugin.PluginName):$($metadata.Name)" } else { $metadata.Name }
  $flags = [Collections.Generic.List[string]]::new()
  if ($file.FullName -match '(?i)\\[^\\]*backup[^\\]*\\') {
    $flags.Add('backup_path')
  }
  if ($file.FullName -match '(?i)\\assets\\.*\\system_entry_skill\\SKILL\.md$') {
    $flags.Add('template_or_fixture_entry')
  }
  if ($source -eq 'codex-user') {
    $relative = [IO.Path]::GetRelativePath($codexRoot, $file.FullName)
    if (($relative -split '[\\/]').Count -gt 2) {
      $flags.Add('nested_entry')
    }
  }
  if ($metadata.MissingName) {
    $flags.Add('missing_name_frontmatter')
    $issues.Add([pscustomobject]@{
      code = 'missing_name_frontmatter'
      path = $file.FullName
      fallback_name = $metadata.Name
    })
  }

  [pscustomobject]@{
    Name = $metadata.Name
    QualifiedId = $qualifiedId
    Source = $source
    Owner = $owner
    Path = $file.FullName
    SHA256 = $metadata.SHA256
    Lines = $metadata.Lines
    Description = $metadata.Description
    PluginId = if ($source -eq 'plugin') { $plugin.PluginId } else { $null }
    PluginVersion = if ($source -eq 'plugin') { $plugin.Version } else { $null }
    PathFlags = @($flags)
  }
}

$items = @(
  $items |
    Group-Object { "$($_.QualifiedId)|$($_.SHA256)" } |
    ForEach-Object {
      if ($_.Count -eq 1) {
        $_.Group[0]
      } else {
        $_.Group |
          Sort-Object @{ Expression = { if ($_.Path -match '(?i)\\.cursor\\skills\\') { 1 } else { 0 } } }, Path |
          Select-Object -First 1
      }
    } |
    Sort-Object Name, QualifiedId, Path
)

$scoreCounts = @{}
if (Test-Path -LiteralPath $scoreLogPath -PathType Leaf) {
  foreach ($match in Select-String -LiteralPath $scoreLogPath -Pattern '^- skill:\s*`([^`]+)`\s*$') {
    $skillName = $match.Matches[0].Groups[1].Value
    if (-not $scoreCounts.ContainsKey($skillName)) {
      $scoreCounts[$skillName] = 0
    }
    $scoreCounts[$skillName]++
  }
}

$realUseCounts = @{}
if (Test-Path -LiteralPath $evidenceLedgerPath -PathType Leaf) {
  $lineNumber = 0
  foreach ($line in Get-Content -LiteralPath $evidenceLedgerPath) {
    $lineNumber++
    if ([string]::IsNullOrWhiteSpace($line)) {
      continue
    }
    try {
      $record = $line | ConvertFrom-Json -Depth 20
    } catch {
      throw "Skill evidence ledger has invalid JSON at line ${lineNumber}: $evidenceLedgerPath"
    }
    $skillName = Get-ObjectProperty -Object $record -Name 'skill'
    if ([string]::IsNullOrWhiteSpace($skillName)) {
      throw "Skill evidence ledger record has no skill at line ${lineNumber}: $evidenceLedgerPath"
    }
    if (-not $realUseCounts.ContainsKey($skillName)) {
      $realUseCounts[$skillName] = 0
    }
    $realUseCounts[$skillName]++
  }
}

$overrideSkills = if ($null -ne $overrides) { Get-ObjectProperty -Object $overrides -Name 'skills' } else { $null }
$seenNames = @{}
$registrySkills = foreach ($group in $items | Group-Object Name | Sort-Object Name) {
  $seenNames[$group.Name] = $true
  $override = Get-ObjectProperty -Object $overrideSkills -Name $group.Name
  $hashCount = @($group.Group.SHA256 | Sort-Object -Unique).Count
  $duplicateKind = if ($group.Count -le 1) { 'none' } elseif ($hashCount -eq 1) { 'identical' } else { 'divergent' }
  $sourceOfTruth = Get-ObjectProperty -Object $override -Name 'source_of_truth_qualified_id'
  if ($null -eq $sourceOfTruth -and $group.Count -eq 1) {
    $sourceOfTruth = $group.Group[0].QualifiedId
  }
  $entryStatuses = Get-ObjectProperty -Object $override -Name 'entry_statuses'
  $family = Get-ObjectProperty -Object $override -Name 'family'
  $routingStatus = if ($null -ne (Get-ObjectProperty -Object $override -Name 'status')) { $override.status } else { 'unassessed' }
  $localized = Resolve-SkillLocalization -Name $group.Name -RoutingStatus $routingStatus -Localization $localization
  $domain = if ($null -ne $family -and $domainByFamily.ContainsKey($family)) { $domainByFamily[$family] } else { $null }
  $entries = foreach ($entry in $group.Group | Sort-Object QualifiedId, Path) {
    $entryStatus = Get-ObjectProperty -Object $entryStatuses -Name $entry.QualifiedId
    if ($null -eq $entryStatus) {
      $entryStatus = 'active'
    }
    [pscustomobject]@{
      qualified_id = $entry.QualifiedId
      source = $entry.Source
      owner = $entry.Owner
      status = $entryStatus
      path = $entry.Path
      sha256 = $entry.SHA256
      lines = $entry.Lines
      description = $entry.Description
      plugin_id = $entry.PluginId
      plugin_version = $entry.PluginVersion
      path_flags = $entry.PathFlags
    }
  }

  [pscustomobject]@{
    name = $group.Name
    display_name_zh = $localized.display_name_zh
    description_zh = $localized.description_zh
    aliases_zh = @($localized.aliases_zh)
    localization_source = $localized.localization_source
    chinese_trigger_mode = $localized.chinese_trigger_mode
    family = $family
    routing_domain = if ($null -ne $domain) { Get-ObjectProperty -Object $domain -Name 'id' } else { $null }
    domain_role = Resolve-DomainRole -Name $group.Name -RoutingStatus $routingStatus -Domain $domain
    status = if ($null -ne (Get-ObjectProperty -Object $override -Name 'status')) { $override.status } else { 'active' }
    discovery_status = 'active'
    routing_status = $routingStatus
    classification_status = if ($null -ne (Get-ObjectProperty -Object $override -Name 'family')) { 'classified' } else { 'unclassified' }
    source_of_truth_qualified_id = $sourceOfTruth
    duplicate_kind = $duplicateKind
    evidence_count = if ($realUseCounts.ContainsKey($group.Name)) { $realUseCounts[$group.Name] } else { 0 }
    historical_evidence_count = if ($scoreCounts.ContainsKey($group.Name)) { $scoreCounts[$group.Name] } else { 0 }
    evidence_status = if ($realUseCounts.ContainsKey($group.Name)) { 'real_use_observed' } elseif ($scoreCounts.ContainsKey($group.Name)) { 'historical_summary_only' } else { 'no_real_use' }
    notes = Get-ObjectProperty -Object $override -Name 'notes'
    entries = @($entries)
  }
}

if ($null -ne $overrideSkills) {
  foreach ($property in $overrideSkills.PSObject.Properties | Sort-Object Name) {
    if ($seenNames.ContainsKey($property.Name)) {
      continue
    }
    $override = $property.Value
    $family = Get-ObjectProperty -Object $override -Name 'family'
    $routingStatus = Get-ObjectProperty -Object $override -Name 'status'
    $localized = Resolve-SkillLocalization -Name $property.Name -RoutingStatus $routingStatus -Localization $localization
    $domain = if ($null -ne $family -and $domainByFamily.ContainsKey($family)) { $domainByFamily[$family] } else { $null }
    $registrySkills += [pscustomobject]@{
      name = $property.Name
      display_name_zh = $localized.display_name_zh
      description_zh = $localized.description_zh
      aliases_zh = @($localized.aliases_zh)
      localization_source = $localized.localization_source
      chinese_trigger_mode = $localized.chinese_trigger_mode
      family = $family
      routing_domain = if ($null -ne $domain) { Get-ObjectProperty -Object $domain -Name 'id' } else { $null }
      domain_role = Resolve-DomainRole -Name $property.Name -RoutingStatus $routingStatus -Domain $domain
      status = Get-ObjectProperty -Object $override -Name 'status'
      discovery_status = 'unavailable'
      routing_status = $routingStatus
      classification_status = if ($null -ne (Get-ObjectProperty -Object $override -Name 'family')) { 'classified' } else { 'unclassified' }
      source_of_truth_qualified_id = Get-ObjectProperty -Object $override -Name 'source_of_truth_qualified_id'
      duplicate_kind = 'none'
      evidence_count = if ($realUseCounts.ContainsKey($property.Name)) { $realUseCounts[$property.Name] } else { 0 }
      historical_evidence_count = if ($scoreCounts.ContainsKey($property.Name)) { $scoreCounts[$property.Name] } else { 0 }
      evidence_status = if ($realUseCounts.ContainsKey($property.Name)) { 'real_use_observed' } elseif ($scoreCounts.ContainsKey($property.Name)) { 'historical_summary_only' } else { 'no_real_use' }
      notes = Get-ObjectProperty -Object $override -Name 'notes'
      entries = @()
    }
  }
}
$registrySkills = @($registrySkills | Sort-Object name)

$learningGovernance = if ($null -ne $overrides) { Get-ObjectProperty -Object $overrides -Name 'learning_governance' } else { $null }
$managedInstallations = @()
if ($null -ne $learningGovernance) {
  $clusterByFolder = @{}
  foreach ($cluster in @(Get-ObjectProperty -Object $learningGovernance -Name 'clusters')) {
    foreach ($folderName in @(Get-ObjectProperty -Object $cluster -Name 'members')) {
      if ($clusterByFolder.ContainsKey($folderName)) {
        throw "Learning-governance folder belongs to more than one cluster: $folderName"
      }
      $clusterByFolder[$folderName] = $cluster
    }
  }
  $folderOverrides = Get-ObjectProperty -Object $learningGovernance -Name 'folder_overrides'
  $skillByName = @{}
  foreach ($skill in $registrySkills) { $skillByName[$skill.name] = $skill }
  $reviewedAt = Get-ObjectProperty -Object $learningGovernance -Name 'reviewed_at'
  $managedFolders = @(
    Get-ChildItem -LiteralPath $codexRoot -Directory |
      Where-Object { $_.Name -ne '.system' -and $_.Name -ne 'skill_route_snapshots' -and $_.Name -notlike '_backup*' } |
      Sort-Object Name
  )
  foreach ($folder in $managedFolders) {
    $skillFile = Join-Path $folder.FullName 'SKILL.md'
    if (-not (Test-Path -LiteralPath $skillFile -PathType Leaf)) {
      $managedInstallations += [pscustomobject]@{
        folder_name = $folder.Name
        stable_skill_id = $null
        path = $folder.FullName
        inclusion_status = 'excluded_non_skill_folder'
        exclusion_reason = '一级目录未包含 SKILL.md，不能作为可路由 Skill。'
        cluster_id = $null
        cluster_name_zh = $null
        key_sections = @()
        value_level = '不适用'
        route_mode = '禁止自动路由'
        duplicate_relationship = '无'
        provenance_type = '本地工具目录'
        real_use_evidence = '不适用'
        current_limitations = '不是 Skill；保留为安装辅助目录。'
        reviewed_at = $reviewedAt
        archival_reason = '不移动；不参与学习卡和默认路由。'
        recovery_path = $folder.FullName
      }
      continue
    }
    $metadata = Read-SkillMetadata -File (Get-Item -LiteralPath $skillFile)
    $skill = $skillByName[$metadata.Name]
    $cluster = $clusterByFolder[$folder.Name]
    $folderOverride = Get-ObjectProperty -Object $folderOverrides -Name $folder.Name
    $headings = @(
      Get-Content -LiteralPath $skillFile |
        Where-Object { $_ -match '^##\s+[^#]' } |
        ForEach-Object { ($_ -replace '^##\s+', '').Trim() } |
        Select-Object -First 3
    )
    $routingStatus = if ($null -ne $skill) { [string]$skill.routing_status } else { 'unassessed' }
    $defaultValue = switch ($routingStatus) {
      'evidence_backed_champion' { '冠军' }
      { $_ -in @('mandatory', 'user_designated', 'provisional_default', 'primary') } { '保留' }
      { $_ -in @('supporting', 'explicit_only') } { '按需' }
      { $_ -in @('archived', 'unavailable_legacy') } { '已归档' }
      default { '待验证' }
    }
    $defaultRoute = switch ($routingStatus) {
      { $_ -in @('mandatory', 'user_designated', 'provisional_default', 'primary', 'evidence_backed_champion') } { '默认或主路由' }
      'supporting' { '辅助' }
      { $_ -in @('archived', 'unavailable_legacy') } { '禁止自动路由' }
      default { '明确指定才用' }
    }
    $profileSections = Get-ObjectProperty -Object $folderOverride -Name 'key_sections'
    $valueLevel = Get-ObjectProperty -Object $folderOverride -Name 'value_level'
    $routeMode = Get-ObjectProperty -Object $folderOverride -Name 'route_mode'
    $managedInstallations += [pscustomobject]@{
      folder_name = $folder.Name
      stable_skill_id = $metadata.Name
      path = $folder.FullName
      inclusion_status = 'managed_skill'
      exclusion_reason = $null
      cluster_id = if ($null -ne $cluster) { Get-ObjectProperty -Object $cluster -Name 'id' } else { 'unassigned' }
      cluster_name_zh = if ($null -ne $cluster) { Get-ObjectProperty -Object $cluster -Name 'name_zh' } else { '待归类' }
      key_sections = if ($null -ne $profileSections) { @($profileSections) } else { $headings }
      value_level = if ($null -ne $valueLevel) { $valueLevel } else { $defaultValue }
      route_mode = if ($null -ne $routeMode) { $routeMode } else { $defaultRoute }
      duplicate_relationship = if ($null -ne (Get-ObjectProperty -Object $folderOverride -Name 'duplicate_relationship')) { $folderOverride.duplicate_relationship } else { '无已确认合并关系' }
      provenance_type = if ($null -ne (Get-ObjectProperty -Object $folderOverride -Name 'provenance_type')) { $folderOverride.provenance_type } else { '本地自建或本地固化' }
      real_use_evidence = if ($null -ne $skill) { $skill.evidence_status } else { '未进入旧注册表；待本轮生成后复核' }
      current_limitations = if ($null -ne (Get-ObjectProperty -Object $folderOverride -Name 'current_limitations')) { $folderOverride.current_limitations } else { '未记录实测时，不得因描述或来源直接升为冠军。' }
      reviewed_at = $reviewedAt
      archival_reason = if ($null -ne (Get-ObjectProperty -Object $folderOverride -Name 'archival_reason')) { $folderOverride.archival_reason } else { $null }
      recovery_path = $folder.FullName
    }
  }
}

$duplicateGroups = @($registrySkills | Where-Object { $_.entries.Count -gt 1 })
$registry = [ordered]@{
  schema_version = 4
  generated_at = (Get-Date).ToUniversalTime().ToString('o')
  scope = $Scope
  summary = [ordered]@{
    entry_count = $items.Count
    unique_raw_names = @($items.Name | Sort-Object -Unique).Count
    unique_qualified_ids = @($items.QualifiedId | Sort-Object -Unique).Count
    duplicate_name_groups = $duplicateGroups.Count
    identical_duplicate_groups = @($duplicateGroups | Where-Object duplicate_kind -eq 'identical').Count
    divergent_duplicate_groups = @($duplicateGroups | Where-Object duplicate_kind -eq 'divergent').Count
    routing_domain_count = $routingDomains.Count
    control_plane_count = $controlPlanes.Count
    capability_contract_count = @($routingDomains | Where-Object { $null -ne (Get-ObjectProperty -Object $_ -Name 'capability_contract') }).Count
    unmapped_domain_skills = @($registrySkills | Where-Object { [string]::IsNullOrWhiteSpace($_.routing_domain) }).Count
    localized_skill_count = @($registrySkills | Where-Object { -not [string]::IsNullOrWhiteSpace($_.display_name_zh) }).Count
    curated_localization_count = @($registrySkills | Where-Object localization_source -eq 'curated').Count
    generated_localization_count = @($registrySkills | Where-Object localization_source -eq 'generated').Count
    display_only_chinese_count = @($registrySkills | Where-Object chinese_trigger_mode -eq 'display_only').Count
    managed_installation_folder_count = $managedInstallations.Count
    managed_skill_count = @($managedInstallations | Where-Object inclusion_status -eq 'managed_skill').Count
    managed_excluded_folder_count = @($managedInstallations | Where-Object inclusion_status -ne 'managed_skill').Count
    by_routing_domain = @(
      $registrySkills | Group-Object routing_domain | Sort-Object Name | ForEach-Object {
        [pscustomobject]@{ routing_domain = $_.Name; count = $_.Count }
      }
    )
    by_source = @(
      $items | Group-Object Source | Sort-Object Name | ForEach-Object {
        [pscustomobject]@{ source = $_.Name; count = $_.Count }
      }
    )
  }
  status_definitions = if ($null -ne $overrides) { Get-ObjectProperty -Object $overrides -Name 'status_definitions' } else { $null }
  routing_domains = $routingDomains
  control_planes = $controlPlanes
  capability_envelope = $capabilityEnvelope
  managed_installations = [ordered]@{
    scope = if ($null -ne $learningGovernance) { Get-ObjectProperty -Object $learningGovernance -Name 'scope' } else { $null }
    reviewed_at = if ($null -ne $learningGovernance) { Get-ObjectProperty -Object $learningGovernance -Name 'reviewed_at' } else { $null }
    clusters = if ($null -ne $learningGovernance) { Get-ObjectProperty -Object $learningGovernance -Name 'clusters' } else { @() }
    exclusions = if ($null -ne $learningGovernance) { Get-ObjectProperty -Object $learningGovernance -Name 'exclusions' } else { @() }
    items = @($managedInstallations)
  }
  non_discoverable_assets = if ($null -ne $overrides) { Get-ObjectProperty -Object $overrides -Name 'non_discoverable_assets' } else { $null }
  issues = @($issues)
  skills = $registrySkills
}

if ($RegistryPath) {
  $fullRegistryPath = [IO.Path]::GetFullPath($RegistryPath)
  $parent = Split-Path -Parent $fullRegistryPath
  if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
    New-Item -ItemType Directory -Path $parent | Out-Null
  }
  $temporaryPath = "$fullRegistryPath.tmp-$PID"
  $registry | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $temporaryPath -Encoding utf8NoBOM
  Move-Item -LiteralPath $temporaryPath -Destination $fullRegistryPath -Force
}

if ($Format -eq 'json') {
  if ($View -eq 'registry') {
    $registry | ConvertTo-Json -Depth 30
  } else {
    $items | ConvertTo-Json -Depth 10
  }
  exit
}

if ($View -eq 'registry') {
  "Metric`tValue"
  foreach ($property in $registry.summary.GetEnumerator()) {
    $value = if ($property.Value -is [Array]) { $property.Value | ConvertTo-Json -Compress } else { $property.Value }
    "{0}`t{1}" -f $property.Key, $value
  }
  exit
}

"Name`tQualifiedId`tSource`tOwner`tLines`tSHA256`tPath`tDescription"
$items | ForEach-Object {
  $desc = $_.Description -replace "`t", " " -replace "\s+", " "
  "{0}`t{1}`t{2}`t{3}`t{4}`t{5}`t{6}`t{7}" -f $_.Name, $_.QualifiedId, $_.Source, $_.Owner, $_.Lines, $_.SHA256, $_.Path, $desc
}
