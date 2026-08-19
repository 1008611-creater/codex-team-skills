[CmdletBinding()]
param(
    [string]$Drive = "C",
    [int]$TopDirs = 15,
    [int]$TopFiles = 20,
    [string]$SavePath,
    [switch]$OutputJson
)

$ErrorActionPreference = "SilentlyContinue"

function Get-DirectorySizeBytes {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return 0L }
    return (Get-ChildItem -LiteralPath $Path -Force -Recurse -File -ErrorAction SilentlyContinue |
        Measure-Object -Property Length -Sum).Sum
}

function Get-TopDirectories {
    param(
        [string]$ParentPath,
        [int]$Count
    )
    if (-not (Test-Path -LiteralPath $ParentPath)) { return @() }

    $items = foreach ($child in Get-ChildItem -LiteralPath $ParentPath -Force -Directory -ErrorAction SilentlyContinue) {
        $size = Get-DirectorySizeBytes -Path $child.FullName
        [pscustomobject]@{
            Path = $child.FullName
            SizeGB = [math]::Round(($size / 1GB), 2)
            LastWriteTime = $child.LastWriteTime
        }
    }

    return $items | Sort-Object SizeGB -Descending | Select-Object -First $Count
}

function Get-LargestFiles {
    param(
        [string]$RootPath,
        [int]$Count
    )
    if (-not (Test-Path -LiteralPath $RootPath)) { return @() }

    return Get-ChildItem -LiteralPath $RootPath -Force -Recurse -File -ErrorAction SilentlyContinue |
        Sort-Object Length -Descending |
        Select-Object -First $Count @{Name = "Path"; Expression = { $_.FullName } },
        @{Name = "SizeGB"; Expression = { [math]::Round(($_.Length / 1GB), 2) } },
        LastWriteTime
}

function Get-SizedPathObject {
    param(
        [string]$Path,
        [string]$Category,
        [string]$Note
    )
    if (-not (Test-Path -LiteralPath $Path)) { return $null }

    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if (-not $item) { return $null }

    $size = if ($item.PSIsContainer) {
        Get-DirectorySizeBytes -Path $Path
    }
    else {
        $item.Length
    }

    return [pscustomobject]@{
        Path = $Path
        SizeGB = [math]::Round(($size / 1GB), 2)
        Category = $Category
        Note = $Note
    }
}

function Get-MigrationDriveSuggestions {
    param([string]$ExcludeDrive)

    $excludeName = $ExcludeDrive.TrimEnd(":").ToUpperInvariant()
    $candidates = foreach ($drive in Get-PSDrive -PSProvider FileSystem) {
        if ($drive.Name.ToUpperInvariant() -eq $excludeName) { continue }
        if (($drive.Used + $drive.Free) -le 0) { continue }

        [pscustomobject]@{
            Drive = "$($drive.Name):"
            FreeGB = [math]::Round(($drive.Free / 1GB), 2)
            UsedGB = [math]::Round(($drive.Used / 1GB), 2)
            TotalGB = [math]::Round((($drive.Used + $drive.Free) / 1GB), 2)
            SuggestedRoot = "$($drive.Name):\migrated-from-$($excludeName.ToLowerInvariant())"
        }
    }

    return $candidates | Sort-Object FreeGB -Descending
}

$driveRoot = if ($Drive.EndsWith(":")) { "$Drive\" } else { "$Drive`:\" }
$userProfile = $env:USERPROFILE
$localAppData = $env:LOCALAPPDATA
$roamingAppData = $env:APPDATA

$driveInfo = Get-PSDrive -Name $Drive.TrimEnd(":")
$lowRiskCandidates = @(
    Get-SizedPathObject -Path (Join-Path $localAppData "Temp") -Category "low-risk" -Note "Temp files"
    Get-SizedPathObject -Path (Join-Path $localAppData "Temp\wsl-crashes") -Category "low-risk" -Note "WSL crash dumps"
    Get-SizedPathObject -Path (Join-Path $localAppData "pip\cache") -Category "low-risk" -Note "pip download cache"
    Get-SizedPathObject -Path (Join-Path $localAppData "npm-cache") -Category "low-risk" -Note "npm cache"
    Get-SizedPathObject -Path (Join-Path $localAppData "CrashDumps") -Category "low-risk" -Note "Windows crash dumps"
    Get-SizedPathObject -Path (Join-Path $localAppData "Microsoft\vscode-cpptools") -Category "low-risk" -Note "VS Code C/C++ index cache"
    Get-SizedPathObject -Path (Join-Path $localAppData "UnityHub\downloads") -Category "low-risk" -Note "Unity Hub downloads"
) | Where-Object { $_ }

$reviewCandidates = @(
    Get-SizedPathObject -Path (Join-Path $userProfile "Documents") -Category "review-first" -Note "User documents"
    Get-SizedPathObject -Path (Join-Path $userProfile "Downloads") -Category "review-first" -Note "Downloaded files"
    Get-SizedPathObject -Path (Join-Path $userProfile ".codex") -Category "review-first" -Note "Codex logs and session state"
    Get-SizedPathObject -Path (Join-Path $roamingAppData "yuque-desktop") -Category "review-first" -Note "Note app local database"
    Get-SizedPathObject -Path (Join-Path $roamingAppData "Tencent\xwechat") -Category "review-first" -Note "Chat data"
    Get-SizedPathObject -Path (Join-Path $env:SystemDrive "qqpcmgr_docpro") -Category "review-first" -Note "Vendor-managed backup folder"
    Get-SizedPathObject -Path (Join-Path $localAppData "Arduino15\packages") -Category "review-first" -Note "Toolchain package store"
) | Where-Object { $_ }

$result = [pscustomobject]@{
    CreatedAt = Get-Date
    DriveSummary = [pscustomobject]@{
        Drive = $Drive.TrimEnd(":").ToUpperInvariant() + ":"
        UsedGB = [math]::Round(($driveInfo.Used / 1GB), 2)
        FreeGB = [math]::Round(($driveInfo.Free / 1GB), 2)
        TotalGB = [math]::Round((($driveInfo.Used + $driveInfo.Free) / 1GB), 2)
    }
    RootDirectories = Get-TopDirectories -ParentPath $driveRoot -Count $TopDirs
    LargestFiles = Get-LargestFiles -RootPath $driveRoot -Count $TopFiles
    UserRootDirectories = Get-TopDirectories -ParentPath $userProfile -Count $TopDirs
    LocalAppDataDirectories = Get-TopDirectories -ParentPath $localAppData -Count $TopDirs
    RoamingAppDataDirectories = Get-TopDirectories -ParentPath $roamingAppData -Count $TopDirs
    LowRiskCandidates = $lowRiskCandidates | Sort-Object SizeGB -Descending
    ReviewCandidates = $reviewCandidates | Sort-Object SizeGB -Descending
    AvoidDirectDeletion = @(
        "C:\Windows\Installer",
        "C:\Windows\WinSxS",
        "C:\Program Files (x86)\InstallShield Installation Information"
    )
    SuggestedMigrationDrives = Get-MigrationDriveSuggestions -ExcludeDrive $Drive
}

if ($SavePath) {
    $saveDir = Split-Path -Parent $SavePath
    if ($saveDir) {
        New-Item -ItemType Directory -Path $saveDir -Force | Out-Null
    }
    $result | ConvertTo-Json -Depth 6 | Set-Content -Path $SavePath -Encoding UTF8
}

if ($OutputJson) {
    $result | ConvertTo-Json -Depth 6
    return
}

Write-Host ""
Write-Host "Drive summary"
$result.DriveSummary | Format-List

Write-Host ""
Write-Host "Top root directories"
$result.RootDirectories | Format-Table -AutoSize

Write-Host ""
Write-Host "Largest files"
$result.LargestFiles | Format-Table -AutoSize

Write-Host ""
Write-Host "Low-risk candidates"
$result.LowRiskCandidates | Format-Table -AutoSize

Write-Host ""
Write-Host "Review-first candidates"
$result.ReviewCandidates | Format-Table -AutoSize

Write-Host ""
Write-Host "Suggested migration drives"
$result.SuggestedMigrationDrives | Format-Table -AutoSize
