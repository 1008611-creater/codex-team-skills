[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,
    [Parameter(Mandatory = $true)]
    [string]$DestinationRoot,
    [string]$RestoreGuidePath,
    [switch]$KeepOldCopy
)

$ErrorActionPreference = "Stop"

function Get-DirectorySizeBytes {
    param([string]$Path)
    return (Get-ChildItem -LiteralPath $Path -Force -Recurse -File -ErrorAction SilentlyContinue |
        Measure-Object -Property Length -Sum).Sum
}

function Invoke-RobocopyChecked {
    param(
        [string]$Source,
        [string]$Destination
    )

    robocopy $Source $Destination /E /COPY:DAT /DCOPY:DAT /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
    $exitCode = $LASTEXITCODE
    if ($exitCode -gt 7) {
        throw "Robocopy failed with exit code $exitCode"
    }
}

function Remove-DirectoryRobust {
    param([string]$Path)

    try {
        Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
        return
    }
    catch {
        $empty = Join-Path (Split-Path -Parent $Path) "_empty_cleanup_dir"
        New-Item -ItemType Directory -Path $empty -Force | Out-Null
        robocopy $empty $Path /MIR /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
        Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
        Remove-Item -LiteralPath $empty -Force -ErrorAction SilentlyContinue
    }
}

function Append-RestoreNote {
    param(
        [string]$GuidePath,
        [string]$Source,
        [string]$Destination,
        [double]$SizeGB
    )

    if (-not $GuidePath) { return }

    $dir = Split-Path -Parent $GuidePath
    if ($dir) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $note = @"

## Migrated Path

- Recorded at: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- Original path: ``$Source``
- Destination path: ``$Destination``
- Approximate size: $SizeGB GB

### Restore steps

1. Close any application using the original path.
2. Delete the junction at ``$Source``.
3. Copy ``$Destination`` back to ``$Source``.
4. Reopen the application and verify it works.
"@

    Add-Content -Path $GuidePath -Value $note -Encoding UTF8
}

if (-not (Test-Path -LiteralPath $SourcePath)) {
    throw "Source path not found: $SourcePath"
}

$sourceItem = Get-Item -LiteralPath $SourcePath -Force
if (-not $sourceItem.PSIsContainer) {
    throw "Source must be a directory: $SourcePath"
}
if ($sourceItem.LinkType) {
    throw "Source is already a link or junction. Inspect its target before migrating."
}

$sourceDrive = [System.IO.Path]::GetPathRoot($sourceItem.FullName).TrimEnd("\")
$destinationRootItem = Get-Item -LiteralPath $DestinationRoot -Force -ErrorAction SilentlyContinue
if (-not $destinationRootItem) {
    New-Item -ItemType Directory -Path $DestinationRoot -Force | Out-Null
}

$relativePart = $SourcePath -replace ":", ""
$relativePart = $relativePart.TrimStart("\")
$destinationPath = Join-Path $DestinationRoot $relativePart

if (Test-Path -LiteralPath $destinationPath) {
    throw "Destination already exists: $destinationPath"
}

$sourceSizeBytes = Get-DirectorySizeBytes -Path $SourcePath
$sourceSizeGB = [math]::Round(($sourceSizeBytes / 1GB), 2)
$backupPath = "$SourcePath.pre_migration_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

if (-not $PSCmdlet.ShouldProcess($SourcePath, "Migrate to $destinationPath and replace source with a junction")) {
    return
}

$destinationParent = Split-Path -Parent $destinationPath
New-Item -ItemType Directory -Path $destinationParent -Force | Out-Null
Invoke-RobocopyChecked -Source $SourcePath -Destination $destinationPath

$destinationSizeBytes = Get-DirectorySizeBytes -Path $destinationPath
if ($destinationSizeBytes -ne $sourceSizeBytes) {
    throw "Copy verification failed. Source=$sourceSizeBytes Destination=$destinationSizeBytes"
}

Move-Item -LiteralPath $SourcePath -Destination $backupPath -Force
try {
    cmd /c mklink /J "$SourcePath" "$destinationPath" | Out-Null
}
catch {
    if (-not (Test-Path -LiteralPath $SourcePath) -and (Test-Path -LiteralPath $backupPath)) {
        Move-Item -LiteralPath $backupPath -Destination $SourcePath -Force
    }
    throw
}

$junctionItem = Get-Item -LiteralPath $SourcePath -Force
if ($junctionItem.LinkType -ne "Junction") {
    throw "Junction creation failed for $SourcePath"
}

$viaLinkBytes = Get-DirectorySizeBytes -Path $SourcePath
if ($viaLinkBytes -ne $destinationSizeBytes) {
    throw "Junction verification failed. Junction size does not match destination size."
}

if (-not $KeepOldCopy) {
    Remove-DirectoryRobust -Path $backupPath
}

Append-RestoreNote -GuidePath $RestoreGuidePath -Source $SourcePath -Destination $destinationPath -SizeGB $sourceSizeGB

[pscustomobject]@{
    SourcePath = $SourcePath
    DestinationPath = $destinationPath
    SourceSizeGB = $sourceSizeGB
    LinkType = $junctionItem.LinkType
    RestoreGuidePath = $RestoreGuidePath
    KeptOldCopy = [bool]$KeepOldCopy
} | Format-List
