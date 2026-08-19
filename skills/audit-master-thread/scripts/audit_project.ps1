param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot,
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$issues = [System.Collections.Generic.List[object]]::new()

function Add-Issue {
    param([string]$Category, [string]$Severity, [string]$Message, [string]$Path)
    $issues.Add([ordered]@{
        category = $Category
        severity = $Severity
        message = $Message
        path = $Path
    })
}

function Collect-ReferencedPaths {
    param($Value)
    if ($null -eq $Value) { return }
    if ($Value -is [string]) {
        if ($Value -match '(?i)(^|[\\/])[^\\/]+\.(md|ya?ml|json)$') { $script:references.Add($Value) }
        return
    }
    if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string]) {
        foreach ($item in $Value) { Collect-ReferencedPaths $item }
        return
    }
    foreach ($property in $Value.PSObject.Properties) { Collect-ReferencedPaths $property.Value }
}

$contextPath = Join-Path $root 'project_context.json'
$context = $null
if (-not (Test-Path -LiteralPath $contextPath -PathType Leaf)) {
    Add-Issue 'project-data' 'high' 'project_context.json is missing' $contextPath
} else {
    try {
        $context = Get-Content -LiteralPath $contextPath -Encoding utf8 -Raw | ConvertFrom-Json
    } catch {
        Add-Issue 'project-data' 'high' "project_context.json is invalid JSON: $($_.Exception.Message)" $contextPath
    }
}

$requiredFiles = @('01_input_packet.md', 'project_state.yaml')
foreach ($relative in $requiredFiles) {
    $path = Join-Path $root $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-Issue 'handoff-gap' 'high' "required project file is missing: $relative" $path
    }
}

$statePath = Join-Path $root 'project_state.yaml'
$inputPath = Join-Path $root '01_input_packet.md'
$stateText = if (Test-Path -LiteralPath $statePath) { Get-Content -LiteralPath $statePath -Encoding utf8 -Raw } else { '' }
$inputText = if (Test-Path -LiteralPath $inputPath) { Get-Content -LiteralPath $inputPath -Encoding utf8 -Raw } else { '' }

$contextProjectId = if ($context) { [string]$context.project_id } else { '' }
$ids = [System.Collections.Generic.List[string]]::new()
if ($contextProjectId) { $ids.Add($contextProjectId) }
foreach ($text in @($stateText, $inputText)) {
    foreach ($match in [regex]::Matches($text, '(?im)^\s*project_id\s*:\s*["'']?([^\s"''#]+)')) {
        $ids.Add($match.Groups[1].Value)
    }
}
$distinctIds = @($ids | Sort-Object -Unique)
if ($distinctIds.Count -gt 1) {
    Add-Issue 'project-data' 'high' "project_id mismatch: $($distinctIds -join ', ')" $contextPath
}

$references = [System.Collections.Generic.List[string]]::new()
if ($context) { Collect-ReferencedPaths $context }
foreach ($reference in @($references | Sort-Object -Unique)) {
    $candidate = $reference
    if ([IO.Path]::IsPathRooted($candidate)) { $resolved = $candidate } else { $resolved = Join-Path $root $candidate }
    if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
        Add-Issue 'handoff-gap' 'high' "authority reference is missing: $reference" $resolved
    }
}

$validator = Join-Path $root 'tools\validate-project-context.ps1'
$validatorResult = $null
if (Test-Path -LiteralPath $validator -PathType Leaf) {
    try {
        $pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
        if (-not $pwsh) { $pwsh = (Get-Command powershell).Source }
        $validatorOutput = @(& $pwsh -NoProfile -ExecutionPolicy Bypass -File $validator -ProjectRoot $root -Operation read 2>&1 | Out-String)
        $validatorResult = [ordered]@{ passed = ($LASTEXITCODE -eq 0); output = ($validatorOutput -join '').Trim() }
        if (-not $validatorResult.passed) {
            Add-Issue 'project-data' 'high' 'project context validator failed' $validator
        }
    } catch {
        Add-Issue 'executor-defect' 'medium' "project context validator could not run: $($_.Exception.Message)" $validator
    }
}

function Get-FieldValue {
    param([string]$Text, [string]$Names)
    $pattern = '(?im)^\s*(?:[-*]\s*)?(?:`|")?(?:' + $Names + ')(?:`|")?\s*:\s*(.+?)\s*$'
    $match = [regex]::Match($Text, $pattern)
    if (-not $match.Success) { return '' }
    return $match.Groups[1].Value.Trim().Trim('"', "'", '`')
}

$stateStage = Get-FieldValue $stateText 'current_stage|stage'
$inputStage = Get-FieldValue $inputText 'current_stage|stage'
$stateChampion = Get-FieldValue $stateText 'current_champion|champion'
$inputChampion = Get-FieldValue $inputText 'current_champion|champion'
$stage = if ($stateStage) { $stateStage } else { $inputStage }
$champion = if ($stateChampion) { $stateChampion } else { $inputChampion }
if ($stateStage -and $inputStage -and $stateStage -ne $inputStage) {
    Add-Issue 'project-data' 'high' "stage mismatch between project_state and input packet: '$stateStage' vs '$inputStage'" $statePath
}
if ($stateChampion -and $inputChampion -and $stateChampion -ne $inputChampion) {
    Add-Issue 'project-data' 'high' "champion mismatch between project_state and input packet: '$stateChampion' vs '$inputChampion'" $statePath
}

if ($stage -match '(?i)资产|asset|P2') {
    $manifest = @('asset_manifest.yaml', 'asset_manifest.yml', 'asset_manifest.json', 'asset_manifest.md') |
        Where-Object { Test-Path -LiteralPath (Join-Path $root $_) -PathType Leaf }
    if ($manifest.Count -eq 0) {
        Add-Issue 'handoff-gap' 'medium' 'asset stage has no asset_manifest file' (Join-Path $root 'asset_manifest.yaml')
    }
}

$status = if ($issues.Count -eq 0) { 'ready-for-stage-audit' } else { 'blocked-at-earliest-gap' }
$nextAction = if ($issues.Count -gt 0) { $issues[0].message } else { 'Read the current champion input contract and execute the smallest verifiable stage action.' }
$result = [ordered]@{
    project_root = $root
    project_id = $contextProjectId
    stage = $stage
    champion = $champion
    status = $status
    earliest_gap = if ($issues.Count -gt 0) { $issues[0] } else { $null }
    issues = @($issues)
    validator = $validatorResult
    next_action = $nextAction
}
$json = $result | ConvertTo-Json -Depth 8
if ($OutputPath) { $json | Set-Content -LiteralPath $OutputPath -Encoding utf8 }
$json
