[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,
    [int]$ReserveFreeGB = 20,
    [int]$CandidateCount = 5,
    [switch]$OutputJson
)

$ErrorActionPreference = "Stop"

function Get-DirectorySizeBytes {
    param([string]$Path)
    return (Get-ChildItem -LiteralPath $Path -Force -Recurse -File -ErrorAction SilentlyContinue |
        Measure-Object -Property Length -Sum).Sum
}

if (-not (Test-Path -LiteralPath $SourcePath)) {
    throw "Source path not found: $SourcePath"
}

$sourceItem = Get-Item -LiteralPath $SourcePath -Force
$sourceSizeBytes = if ($sourceItem.PSIsContainer) { Get-DirectorySizeBytes -Path $SourcePath } else { $sourceItem.Length }
$sourceSizeGB = [math]::Round(($sourceSizeBytes / 1GB), 2)
$sourceDrive = [System.IO.Path]::GetPathRoot($sourceItem.FullName).TrimEnd("\")
$leafName = Split-Path -Path $SourcePath -Leaf

$candidates = foreach ($drive in Get-PSDrive -PSProvider FileSystem) {
    $driveName = "$($drive.Name):"
    if ($driveName -eq $sourceDrive) { continue }
    if (($drive.Used + $drive.Free) -le 0) { continue }

    $freeAfterBytes = $drive.Free - $sourceSizeBytes
    $isEnough = $freeAfterBytes -ge ($ReserveFreeGB * 1GB)

    [pscustomobject]@{
        Drive = $driveName
        CurrentFreeGB = [math]::Round(($drive.Free / 1GB), 2)
        EstimatedFreeAfterGB = [math]::Round(($freeAfterBytes / 1GB), 2)
        TotalGB = [math]::Round((($drive.Used + $drive.Free) / 1GB), 2)
        SourceSizeGB = $sourceSizeGB
        MeetsReserve = $isEnough
        SuggestedDestinationRoot = "$driveName\migrated-from-$($sourceDrive.TrimEnd(':').ToLowerInvariant())"
        SuggestedFullPath = "$driveName\migrated-from-$($sourceDrive.TrimEnd(':').ToLowerInvariant())\$leafName"
    }
}

$ranked = $candidates |
    Sort-Object @{ Expression = { if ($_.MeetsReserve) { 0 } else { 1 } } }, @{ Expression = "EstimatedFreeAfterGB"; Descending = $true } |
    Select-Object -First $CandidateCount

$report = [pscustomobject]@{
    SourcePath = $SourcePath
    SourceDrive = $sourceDrive
    SourceSizeGB = $sourceSizeGB
    ReserveFreeGB = $ReserveFreeGB
    RankedDestinations = $ranked
}

if ($OutputJson) {
    $report | ConvertTo-Json -Depth 5
    return
}

Write-Host ""
Write-Host "Source"
$report | Select-Object SourcePath, SourceDrive, SourceSizeGB, ReserveFreeGB | Format-List

Write-Host ""
Write-Host "Suggested destinations"
$report.RankedDestinations | Format-Table -AutoSize
