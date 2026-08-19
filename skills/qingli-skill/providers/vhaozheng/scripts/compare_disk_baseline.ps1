[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$BaselinePath,
    [Parameter(Mandatory = $true)]
    [string]$CurrentPath,
    [int]$Top = 20,
    [switch]$OutputJson
)

$ErrorActionPreference = "Stop"

function Read-ScanJson {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Scan file not found: $Path"
    }
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Add-SectionToMap {
    param(
        [hashtable]$Map,
        $Items
    )
    foreach ($item in @($Items)) {
        if (-not $item) { continue }
        if (-not $item.Path) { continue }
        $Map[$item.Path] = [double]$item.SizeGB
    }
}

$baseline = Read-ScanJson -Path $BaselinePath
$current = Read-ScanJson -Path $CurrentPath

$baselineMap = @{}
$currentMap = @{}

$sections = @(
    "RootDirectories",
    "UserRootDirectories",
    "LocalAppDataDirectories",
    "RoamingAppDataDirectories",
    "LowRiskCandidates",
    "ReviewCandidates"
)

foreach ($section in $sections) {
    Add-SectionToMap -Map $baselineMap -Items $baseline.$section
    Add-SectionToMap -Map $currentMap -Items $current.$section
}

$allPaths = New-Object System.Collections.Generic.HashSet[string]
foreach ($path in $baselineMap.Keys) { [void]$allPaths.Add($path) }
foreach ($path in $currentMap.Keys) { [void]$allPaths.Add($path) }

$growth = foreach ($path in $allPaths) {
    $before = if ($baselineMap.ContainsKey($path)) { $baselineMap[$path] } else { 0.0 }
    $after = if ($currentMap.ContainsKey($path)) { $currentMap[$path] } else { 0.0 }
    [pscustomobject]@{
        Path = $path
        BeforeGB = [math]::Round($before, 2)
        AfterGB = [math]::Round($after, 2)
        DeltaGB = [math]::Round(($after - $before), 2)
    }
}

$report = [pscustomobject]@{
    BaselinePath = $BaselinePath
    CurrentPath = $CurrentPath
    BaselineCreatedAt = $baseline.CreatedAt
    CurrentCreatedAt = $current.CreatedAt
    DriveBefore = $baseline.DriveSummary
    DriveAfter = $current.DriveSummary
    LargestGrowth = $growth | Sort-Object DeltaGB -Descending | Select-Object -First $Top
    LargestDrops = $growth | Sort-Object DeltaGB | Select-Object -First $Top
}

if ($OutputJson) {
    $report | ConvertTo-Json -Depth 6
    return
}

Write-Host ""
Write-Host "Baseline"
$report.DriveBefore | Format-List

Write-Host ""
Write-Host "Current"
$report.DriveAfter | Format-List

Write-Host ""
Write-Host "Largest growth"
$report.LargestGrowth | Format-Table -AutoSize

Write-Host ""
Write-Host "Largest drops"
$report.LargestDrops | Format-Table -AutoSize
