[CmdletBinding()]
param(
  [string]$ConfigPath = "$HOME\.codex\config.toml",
  [string]$DurableRegistryPath = (Join-Path $PSScriptRoot '..\references\skill-registry.json'),
  [string]$LocalizationPath = (Join-Path $PSScriptRoot '..\references\skill-localization.zh-CN.json')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$inventoryScript = Join-Path $PSScriptRoot 'inventory_skills.ps1'
$temporaryRegistry = Join-Path ([IO.Path]::GetTempPath()) "skill-registry-test-$PID.json"

function Assert-True {
  param([bool]$Condition, [string]$Message)

  if (-not $Condition) {
    throw $Message
  }
}

function Get-ComparableRegistryJson {
  param([object]$Registry)

  $Registry.generated_at = '<ignored>'
  return $Registry | ConvertTo-Json -Depth 30 -Compress
}

try {
  $activeJson = & $inventoryScript -ConfigPath $ConfigPath -LocalizationPath $LocalizationPath -Format json -View registry -RegistryPath $temporaryRegistry
  $active = $activeJson | ConvertFrom-Json -Depth 30
  $written = Get-Content -Raw -LiteralPath $temporaryRegistry | ConvertFrom-Json -Depth 30
  $durable = Get-Content -Raw -LiteralPath $DurableRegistryPath | ConvertFrom-Json -Depth 30

  $sourceTotal = ($active.summary.by_source | Measure-Object -Property count -Sum).Sum
  Assert-True ($sourceTotal -eq $active.summary.entry_count) 'Source counts do not sum to entry_count.'
  $activeComparable = Get-ComparableRegistryJson -Registry $active
  Assert-True ((Get-ComparableRegistryJson -Registry $written) -eq $activeComparable) 'Written registry differs semantically from stdout registry.'
  Assert-True ((Get-ComparableRegistryJson -Registry $durable) -eq $activeComparable) 'Durable skill-registry.json is stale; regenerate it before completion.'
  Assert-True ($active.schema_version -eq 4) 'Registry schema must expose governance, routing-domain, evidence, and Chinese localization dimensions.'
  Assert-True ($active.routing_domains.Count -eq 12) 'Registry must expose exactly 12 governed routing domains.'
  Assert-True ($active.control_planes.Count -eq 8) 'Registry must expose exactly 8 cross-cutting control planes.'
  Assert-True ($active.summary.capability_contract_count -eq 12) 'Every routing domain must expose one capability input/output contract.'
  Assert-True ($null -ne $active.capability_envelope) 'Registry must expose the shared capability input/output envelope.'
  Assert-True ($active.summary.unmapped_domain_skills -eq 0) 'Every Skill must map to one governed routing domain.'
  $localized = @($active.skills | Where-Object {
    -not [string]::IsNullOrWhiteSpace($_.display_name_zh) -and
    -not [string]::IsNullOrWhiteSpace($_.description_zh) -and
    $_.aliases_zh.Count -gt 0
  })
  Assert-True ($localized.Count -eq $active.skills.Count) 'Every Skill must have a complete zh-CN semantic layer.'
  $duplicateChineseNames = @($active.skills | Group-Object display_name_zh | Where-Object Count -gt 1)
  Assert-True ($duplicateChineseNames.Count -eq 0) 'Chinese Skill display names must be unique.'
  $unsafeChineseTriggers = @($active.skills | Where-Object {
    $_.routing_status -in @('explicit_only', 'candidate', 'unassessed', 'archived', 'unavailable_legacy') -and
    $_.chinese_trigger_mode -ne 'display_only'
  })
  Assert-True ($unsafeChineseTriggers.Count -eq 0) 'High-risk or unassessed Skills cannot gain Chinese auto-trigger authority.'
  Assert-True ($active.summary.identical_duplicate_groups -eq 0) 'Identical active duplicate groups remain after deduplication.'
  $expectedDivergentNames = @('figma-create-new-file', 'figma-generate-design', 'figma-generate-library', 'figma-use', 'pdf')
  $actualDivergentNames = @(
    $active.skills |
      Where-Object duplicate_kind -eq 'divergent' |
      Sort-Object name |
      ForEach-Object name
  )
  Assert-True (($actualDivergentNames -join ',') -eq (($expectedDivergentNames | Sort-Object) -join ',')) 'Governed divergent name groups differ from the enabled-plugin-aware expected set.'

  $missingGovernanceFields = @($active.skills | Where-Object {
    [string]::IsNullOrWhiteSpace($_.discovery_status) -or
    [string]::IsNullOrWhiteSpace($_.routing_status) -or
    [string]::IsNullOrWhiteSpace($_.classification_status) -or
    [string]::IsNullOrWhiteSpace($_.evidence_status) -or
    [string]::IsNullOrWhiteSpace($_.routing_domain) -or
    [string]::IsNullOrWhiteSpace($_.domain_role)
  })
  Assert-True ($missingGovernanceFields.Count -eq 0) 'One or more registry records omit a governance dimension.'
  $unassessedActive = @($active.skills | Where-Object { $_.discovery_status -eq 'active' -and $_.routing_status -eq 'unassessed' })
  Assert-True ($unassessedActive.Count -eq 0) 'All active routes must be deliberately classified instead of being promoted by inventory presence.'
  $unclassifiedActive = @($active.skills | Where-Object { $_.discovery_status -eq 'active' -and $_.classification_status -eq 'unclassified' })
  Assert-True ($unclassifiedActive.Count -eq 0) 'All active routes must have a deliberate family classification after the family-governance pass.'

  $pdf = @($active.skills | Where-Object name -eq 'pdf')
  Assert-True ($pdf.Count -eq 1) 'PDF registry group is missing or duplicated.'
  Assert-True ($pdf[0].duplicate_kind -eq 'divergent') 'PDF group must remain explicitly divergent.'
  Assert-True ($pdf[0].status -eq 'provisional_default') 'PDF group must remain provisional until comparative real-use evidence exists.'
  Assert-True ($pdf[0].routing_status -eq 'provisional_default') 'PDF routing level must remain provisional until comparative real-use evidence exists.'
  Assert-True ($pdf[0].evidence_count -eq 0) 'PDF group unexpectedly claims real-use evidence.'
  Assert-True ($pdf[0].source_of_truth_qualified_id -eq 'pdf') 'Local PDF route is not the recorded source of truth.'
  $pdfIds = @($pdf[0].entries.qualified_id | Sort-Object)
  Assert-True (($pdfIds -join ',') -eq 'pdf,pdf:pdf') 'PDF qualified ids do not match the governed split.'
  $localPdf = @($pdf[0].entries | Where-Object qualified_id -eq 'pdf')
  $pluginPdf = @($pdf[0].entries | Where-Object qualified_id -eq 'pdf:pdf')
  Assert-True ($localPdf[0].status -eq 'provisional_default') 'Local PDF continuity route must be labeled provisional.'
  Assert-True ($pluginPdf[0].status -eq 'candidate') 'Qualified plugin PDF route must remain a candidate.'

  $governance = @($active.skills | Where-Object name -eq 'skill-governance')
  Assert-True ($governance.Count -eq 1) 'Skill-governance registry record is missing.'
  Assert-True ($governance[0].historical_evidence_count -gt 0) 'Historical score summaries must remain visible separately.'
  Assert-True ($governance[0].evidence_count -gt 0) 'Current real-use ledger evidence for skill-governance is missing.'
  Assert-True ($governance[0].evidence_status -eq 'real_use_observed') 'Real-use JSONL evidence must take precedence over historical-summary-only status.'

  foreach ($name in @('douyin-publish-operator', 'douyin-workflow-orchestrator', 'kuaishou-content-pipeline', 'kuaishou-publisher', 'post-to-x', 'goofish-publish-item', 'goofish-reply-buyer', 'xianyu-product-publisher', 'xiaohongshu-ops', 'xhs-note-creator')) {
    $skill = @($active.skills | Where-Object name -eq $name)
    Assert-True ($skill.Count -eq 1 -and $skill[0].routing_status -eq 'explicit_only') "$name must remain explicit-only because it can write external state."
  }

  foreach ($name in @('ai-image-video-channel-router', 'ai-video-channel-router', 'artflash-video-channel', 'djpsd-video-channel', 'dola-video-channel', 'echoon-seedance2-film-workflow', 'hilight-video-channel', 'mimo-8001-video-channel', 'sd2-video-generation', 'storeel-seedance2-canvas')) {
    $skill = @($active.skills | Where-Object name -eq $name)
    Assert-True ($skill.Count -eq 1 -and $skill[0].routing_status -eq 'explicit_only') "$name must remain explicit-only because it can access an external provider or submit work."
  }

  $mxRouter = @($active.skills | Where-Object name -eq 'mx-shortdrama-00-router')
  Assert-True ($mxRouter.Count -eq 1 -and $mxRouter[0].routing_status -eq 'primary') 'MX short-drama router must remain the primary redraw classification route.'
  foreach ($name in @('mx-shortdrama-03-mexico-localize', 'mx-shortdrama-05-asset-images', 'mx-shortdrama-frame-anchor-addon')) {
    $skill = @($active.skills | Where-Object name -eq $name)
    Assert-True ($skill.Count -eq 1 -and $skill[0].routing_status -eq 'explicit_only') "$name must remain an explicit-only optional or execution phase."
  }

  foreach ($name in @('web-miniapp-product-router', 'website-product-router', 'miniapp-product-router', 'frontend-product-design-router', 'web-visual-motion-planner', 'website-quality-router')) {
    $skill = @($active.skills | Where-Object name -eq $name)
    Assert-True ($skill.Count -eq 1 -and $skill[0].routing_status -eq 'primary') "$name must remain the primary route for its explicitly scoped delivery or quality phase."
  }
  $commercialProgram = @($active.skills | Where-Object name -eq 'commercial-website-program-router')
  Assert-True ($commercialProgram.Count -eq 1 -and $commercialProgram[0].routing_status -eq 'supporting') 'Commercial website program routing must remain a strategy/gate phase, not a duplicate implementation primary.'
  foreach ($name in @('figma-create-new-file', 'figma-generate-design', 'figma-generate-library', 'figma-create-design-system-rules')) {
    $skill = @($active.skills | Where-Object name -eq $name)
    Assert-True ($skill.Count -eq 1 -and $skill[0].routing_status -eq 'explicit_only') "$name must remain explicit-only because it writes external Figma state."
  }
  $figmaUse = @($active.skills | Where-Object name -eq 'figma-use')
  Assert-True ($figmaUse.Count -eq 1 -and $figmaUse[0].routing_status -eq 'mandatory') 'figma-use must remain the mandatory prerequisite for use_figma calls.'

  foreach ($name in @('feishu-docx', 'feishu-inout', 'server-fleet-ssh-router', 'hermes-codex-bridge', 'wechat-redraw-word-sender', 'win-mac-codex-bridge')) {
    $skill = @($active.skills | Where-Object name -eq $name)
    Assert-True ($skill.Count -eq 1 -and $skill[0].routing_status -eq 'explicit_only') "$name must remain explicit-only because it can write to or operate an external system."
  }
  foreach ($name in @('docx', 'xlsx', 'json-canvas', 'obsidian-cli', 'master-control-router', 'exam-cram-docx-router', 'email-otp-auth')) {
    $skill = @($active.skills | Where-Object name -eq $name)
    Assert-True ($skill.Count -eq 1 -and $skill[0].routing_status -eq 'primary') "$name must remain the primary route for its scoped local artifact or control domain."
  }

  foreach ($name in @('gpt-image', 'hermes-canvas-image2', 'krill-image2', 'oiioii-canvas-workflow', 'oocimage2skill', 'runninghub-canvas-fallback', 'runninghub-image2-image', 'runninghub-image2-text')) {
    $skill = @($active.skills | Where-Object name -eq $name)
    Assert-True ($skill.Count -eq 1 -and $skill[0].routing_status -eq 'explicit_only') "$name must remain explicit-only because it can create remote image work or write cloud state."
  }
  foreach ($name in @('product-marketing', 'obviously-awesome', 'pricing', 'copywriting', 'prompt-skill-router')) {
    $skill = @($active.skills | Where-Object name -eq $name)
    Assert-True ($skill.Count -eq 1 -and $skill[0].routing_status -eq 'primary') "$name must remain the primary route for its scoped method or marketing phase."
  }

  $unassessedActive = @($active.skills | Where-Object { $_.discovery_status -eq 'active' -and $_.routing_status -eq 'unassessed' })
  Assert-True ($unassessedActive.Count -eq 0) 'All active Skills must have an explicit routing status after the family-governance pass.'

  $ikun = @($active.skills | Where-Object name -eq 'ikun-image2')
  Assert-True ($ikun.Count -eq 1 -and $ikun[0].status -eq 'unavailable_legacy') 'ikun-image2 legacy tombstone is missing.'
  Assert-True ($ikun[0].entries.Count -eq 0) 'ikun-image2 unexpectedly resolves to an active entry.'

  foreach ($name in @('generated-production-system', 'ai-image-video-production-system')) {
    $activeEntries = @($active.skills | Where-Object { $_.name -eq $name -and $_.entries.Count -gt 0 })
    Assert-True ($activeEntries.Count -eq 0) "$name is still discoverable as an active Skill."
  }

  $flaggedEntries = @(
    $active.skills.entries |
      Where-Object { $_.path_flags -contains 'backup_path' -or $_.path_flags -contains 'template_or_fixture_entry' }
  )
  Assert-True ($flaggedEntries.Count -eq 0) 'Active inventory still contains a backup or factory template entry.'

  $pluginEntries = @($active.skills.entries | Where-Object source -eq 'plugin')
  Assert-True ($pluginEntries.Count -gt 0) 'Enabled plugin inventory is empty.'
  Assert-True (@($pluginEntries | Where-Object { $_.qualified_id -notmatch '^[^:]+:.+$' }).Count -eq 0) 'Plugin qualified ids are malformed.'

  $rawJson = & $inventoryScript -ConfigPath $ConfigPath -Scope raw-cache -Format json -View registry
  $raw = $rawJson | ConvertFrom-Json -Depth 30
  Assert-True ($raw.summary.entry_count -gt $active.summary.entry_count) 'Raw-cache scope does not expose more cache entries than active scope.'

  [pscustomobject]@{
    status = 'ok'
    active_entries = $active.summary.entry_count
    active_raw_names = $active.summary.unique_raw_names
    active_qualified_ids = $active.summary.unique_qualified_ids
    divergent_groups = $active.summary.divergent_duplicate_groups
    raw_cache_entries = $raw.summary.entry_count
  } | ConvertTo-Json -Depth 5
} finally {
  if (Test-Path -LiteralPath $temporaryRegistry -PathType Leaf) {
    Remove-Item -LiteralPath $temporaryRegistry -Force
  }
}
