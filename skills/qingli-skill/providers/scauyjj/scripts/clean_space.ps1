param(
  [ValidateSet('L1','L2')]
  [string]$Level = 'L1',
  [string[]]$Drives = @('C:'),
  [int]$MinCandidateMB = 10,
  [string]$PlanPath = '',
  [ValidateSet('All','SAFE_DELETE','SAFE_IF_CLOSED','ADMIN_SAFE')]
  [string]$Only = 'All',
  [switch]$IncludeRunning,
  [switch]$DryRun,
  [switch]$Json
)

$ErrorActionPreference = 'Continue'

$Deleted = New-Object System.Collections.Generic.List[object]
$Skipped = New-Object System.Collections.Generic.List[object]

function Get-IsAdmin {
  ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-FreeRows {
  foreach ($drive in $Drives) {
    $disk = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='{0}'" -f $drive) -ErrorAction SilentlyContinue
    if ($disk) {
      [pscustomobject]@{
        drive = $disk.DeviceID
        free_gb = [math]::Round($disk.FreeSpace / 1GB, 2)
        used_gb = [math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)
        free_pct = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 1)
      }
    }
  }
}

function Get-TreeBytes {
  param([string]$Path)
  if (!(Test-Path -LiteralPath $Path)) { return 0L }
  $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
  if ($null -eq $item) { return 0L }
  if (-not $item.PSIsContainer) { return [int64]$item.Length }

  $out = & "$env:SystemRoot\System32\robocopy.exe" $Path $env:TEMP /L /S /BYTES /XJ /R:0 /W:0 /NFL /NDL /NJH /NP 2>$null
  foreach ($line in $out) {
    if ($line -match '^\s*Bytes\s*:\s+([0-9]+)') { return [int64]$matches[1] }
  }
  return 0L
}

function Get-NormalPath {
  param([string]$Path)
  if ([string]::IsNullOrWhiteSpace($Path)) { return $null }
  return [System.IO.Path]::GetFullPath($Path).TrimEnd('\')
}

function Add-Skipped {
  param(
    [string]$Reason,
    [string]$Path,
    [double]$SizeMB = 0,
    [string]$Message = ''
  )
  $Skipped.Add([pscustomobject]@{
    reason = $Reason
    path = $Path
    size_mb = [math]::Round($SizeMB, 2)
    message = $Message
  }) | Out-Null
}

function Get-RunningProcessNames {
  $set = @{}
  Get-Process -ErrorAction SilentlyContinue | ForEach-Object {
    $set[$_.ProcessName.ToLowerInvariant()] = $true
  }
  return $set
}

function Get-AllowedRoots {
  $roots = New-Object System.Collections.Generic.List[string]
  foreach ($path in @(
    (Join-Path $env:LOCALAPPDATA 'Temp'),
    $env:LOCALAPPDATA,
    $env:APPDATA,
    (Join-Path $env:ProgramData 'Microsoft\Windows\WER'),
    (Join-Path $env:SystemRoot 'Temp'),
    (Join-Path $env:SystemRoot 'Minidump'),
    (Join-Path $env:SystemRoot 'LiveKernelReports'),
    (Join-Path $env:USERPROFILE '.cache')
  )) {
    if ($path -and (Test-Path -LiteralPath $path)) {
      $roots.Add((Get-NormalPath $path)) | Out-Null
    }
  }

  foreach ($drive in $Drives) {
    foreach ($name in @('DeliveryOptimization','WUDownloadCache')) {
      $root = "$drive\$name"
      if (Test-Path -LiteralPath $root) { $roots.Add((Get-NormalPath $root)) | Out-Null }
    }
  }

  @($roots | Select-Object -Unique)
}

$AllowedRoots = @(Get-AllowedRoots)
$RunningProcesses = Get-RunningProcessNames
$IsAdmin = Get-IsAdmin
$ProtectedPaths = @()
if (-not [string]::IsNullOrWhiteSpace($PlanPath)) {
  $ProtectedPaths += (Get-NormalPath $PlanPath)
}

function Test-UnderAllowedRoot {
  param([string]$Path)
  $full = Get-NormalPath $Path
  foreach ($root in $AllowedRoots) {
    if ($full.Equals($root, [StringComparison]::OrdinalIgnoreCase) -or
        $full.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase)) {
      return $true
    }
  }
  return $false
}

function Test-NeverDelete {
  param([string]$Path)
  $p = Get-NormalPath $Path
  $fragments = @(
    '\Windows\WinSxS\',
    '\Windows\Installer\',
    '\Program Files\',
    '\Program Files (x86)\',
    '\Windows\System32\',
    '\DriverStore\',
    '\.codex\sessions',
    '\.codex\sqlite',
    '\.cache\codex-runtimes',
    '\AppData\Local\Packages\',
    '\WeChat Files\',
    '\WXWork\Msg\',
    '\MobileSync\Backup\'
  )
  foreach ($fragment in $fragments) {
    if ($p.IndexOf($fragment, [StringComparison]::OrdinalIgnoreCase) -ge 0) { return $true }
  }
  return $false
}

function Remove-SafePath {
  param(
    [string]$Path,
    [string]$Reason,
    [switch]$ContentsOnly
  )

  if (!(Test-Path -LiteralPath $Path)) { return }
  $full = Get-NormalPath $Path

  if (Test-NeverDelete $full) {
    Add-Skipped -Reason $Reason -Path $full -Message 'protected path'
    return
  }
  foreach ($protected in $ProtectedPaths) {
    if ($protected -and $full.Equals($protected, [StringComparison]::OrdinalIgnoreCase)) {
      Add-Skipped -Reason $Reason -Path $full -Message 'current cleanup plan'
      return
    }
  }
  if (!(Test-UnderAllowedRoot $full)) {
    Add-Skipped -Reason $Reason -Path $full -Message 'outside allowed cleanup roots'
    return
  }

  if ($ContentsOnly) {
    Get-ChildItem -LiteralPath $full -Force -ErrorAction SilentlyContinue | ForEach-Object {
      Remove-SafePath -Path $_.FullName -Reason $Reason
    }
    return
  }

  $bytes = Get-TreeBytes -Path $full
  if ($bytes -lt 1) { return }

  if ($DryRun) {
    $Deleted.Add([pscustomobject]@{
      action = 'would_delete'
      reason = $Reason
      path = $full
      size_mb = [math]::Round($bytes / 1MB, 2)
    }) | Out-Null
    return
  }

  try {
    Remove-Item -LiteralPath $full -Recurse -Force -ErrorAction Stop
    $Deleted.Add([pscustomobject]@{
      action = 'deleted'
      reason = $Reason
      path = $full
      size_mb = [math]::Round($bytes / 1MB, 2)
    }) | Out-Null
  } catch {
    Add-Skipped -Reason $Reason -Path $full -SizeMB ([math]::Round($bytes / 1MB, 2)) -Message $_.Exception.Message
  }
}

function Test-CandidateRunning {
  param([object]$Candidate)
  $matched = @()
  foreach ($name in @($Candidate.process_names)) {
    if ($null -eq $name) { continue }
    $key = ([string]$name).ToLowerInvariant()
    if ($RunningProcesses.ContainsKey($key)) { $matched += $key }
  }
  return @($matched | Select-Object -Unique)
}

function Invoke-PlanCleanup {
  param([string]$Path)

  if (!(Test-Path -LiteralPath $Path)) {
    throw "Plan file not found: $Path"
  }

  $plan = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
  if ($plan.target_drives) {
    $script:Drives = @($plan.target_drives)
  }

  foreach ($candidate in @($plan.candidates)) {
    if ($Only -ne 'All' -and $candidate.risk -ne $Only) {
      continue
    }

    if ($candidate.risk -eq 'ADMIN_SAFE' -and -not $IsAdmin) {
      Add-Skipped -Reason $candidate.category -Path $candidate.path -SizeMB $candidate.size_mb -Message 'administrator permission required'
      continue
    }

    if ($candidate.risk -eq 'SAFE_IF_CLOSED' -and -not $IncludeRunning) {
      $matched = @(Test-CandidateRunning -Candidate $candidate)
      if ($matched.Count -gt 0) {
        Add-Skipped -Reason $candidate.category -Path $candidate.path -SizeMB $candidate.size_mb -Message ("close first: {0}" -f ($matched -join ', '))
        continue
      }
    }

    $contentsOnly = ([string]$candidate.cleanup_action -eq 'contents')
    Remove-SafePath -Path $candidate.path -Reason $candidate.category -ContentsOnly:$contentsOnly
  }
}

function New-FallbackCandidate {
  param(
    [string]$Path,
    [string]$Category,
    [string]$Risk,
    [string]$Action,
    [string[]]$ProcessNames = @()
  )
  if (!(Test-Path -LiteralPath $Path)) { return $null }
  $bytes = Get-TreeBytes -Path $Path
  if ($bytes -lt ($MinCandidateMB * 1MB)) { return $null }
  [pscustomobject]@{
    path = Get-NormalPath $Path
    category = $Category
    risk = $Risk
    cleanup_action = $Action
    size_mb = [math]::Round($bytes / 1MB, 2)
    process_names = @($ProcessNames)
  }
}

function Get-FallbackCandidates {
  $rows = New-Object System.Collections.Generic.List[object]

  foreach ($item in @(
    @{ Path = (Join-Path $env:LOCALAPPDATA 'Temp'); Category = 'user temp'; Risk = 'SAFE_DELETE'; Action = 'contents'; Processes = @() },
    @{ Path = (Join-Path $env:SystemRoot 'Temp'); Category = 'windows temp'; Risk = 'ADMIN_SAFE'; Action = 'contents'; Processes = @() },
    @{ Path = (Join-Path $env:ProgramData 'Microsoft\Windows\WER'); Category = 'error reports'; Risk = 'ADMIN_SAFE'; Action = 'contents'; Processes = @() },
    @{ Path = (Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data\Profile 1\Cache'); Category = 'browser cache'; Risk = 'SAFE_IF_CLOSED'; Action = 'delete_directory'; Processes = @('chrome') },
    @{ Path = (Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data\Profile 1\Code Cache'); Category = 'browser cache'; Risk = 'SAFE_IF_CLOSED'; Action = 'delete_directory'; Processes = @('chrome') },
    @{ Path = (Join-Path $env:APPDATA 'kingsoft\office6\cache'); Category = 'app cache'; Risk = 'SAFE_IF_CLOSED'; Action = 'delete_directory'; Processes = @('wps','wpp','et','wpscloudsvr','wpsdoccenter') },
    @{ Path = (Join-Path $env:APPDATA 'Sangfor\aTrust\logs'); Category = 'security app logs'; Risk = 'SAFE_IF_CLOSED'; Action = 'delete_directory'; Processes = @('atrust','atrustxtunnel','atrusttray','atrustagent') }
  )) {
    $row = New-FallbackCandidate -Path $item.Path -Category $item.Category -Risk $item.Risk -Action $item.Action -ProcessNames $item.Processes
    if ($row) { $rows.Add($row) | Out-Null }
  }

  return @($rows.ToArray())
}

function Invoke-FallbackCleanup {
  foreach ($candidate in @(Get-FallbackCandidates)) {
    if ($Only -ne 'All' -and $candidate.risk -ne $Only) { continue }
    if ($candidate.risk -eq 'ADMIN_SAFE' -and -not $IsAdmin) {
      Add-Skipped -Reason $candidate.category -Path $candidate.path -SizeMB $candidate.size_mb -Message 'administrator permission required'
      continue
    }
    if ($candidate.risk -eq 'SAFE_IF_CLOSED' -and -not $IncludeRunning) {
      $matched = @(Test-CandidateRunning -Candidate $candidate)
      if ($matched.Count -gt 0) {
        Add-Skipped -Reason $candidate.category -Path $candidate.path -SizeMB $candidate.size_mb -Message ("close first: {0}" -f ($matched -join ', '))
        continue
      }
    }
    Remove-SafePath -Path $candidate.path -Reason $candidate.category -ContentsOnly:([string]$candidate.cleanup_action -eq 'contents')
  }
}

$before = @(Get-FreeRows)

if ([string]::IsNullOrWhiteSpace($PlanPath)) {
  Invoke-FallbackCleanup
} else {
  Invoke-PlanCleanup -Path $PlanPath
}

if (-not $DryRun) {
  try { Clear-RecycleBin -Force -ErrorAction SilentlyContinue } catch {}
}

$after = @(Get-FreeRows)

$deletedMb = ($Deleted | Measure-Object size_mb -Sum).Sum
if ($null -eq $deletedMb) { $deletedMb = 0 }
$skippedMb = ($Skipped | Measure-Object size_mb -Sum).Sum
if ($null -eq $skippedMb) { $skippedMb = 0 }

$result = [pscustomobject]@{
  generated_at = (Get-Date).ToString('s')
  level = $Level
  dry_run = [bool]$DryRun
  plan_path = $PlanPath
  only = $Only
  include_running = [bool]$IncludeRunning
  before = @($before)
  after = @($after)
  estimated_deleted_mb = [math]::Round($deletedMb, 2)
  estimated_skipped_mb = [math]::Round($skippedMb, 2)
  deleted_count = $Deleted.Count
  skipped_count = $Skipped.Count
  deleted = @($Deleted.ToArray())
  skipped = @($Skipped.ToArray() | Sort-Object size_mb -Descending | Select-Object -First 100)
}

if ($Json) {
  $result | ConvertTo-Json -Depth 8
} else {
  'Before'
  $before | Format-Table -AutoSize
  ''
  'After'
  $after | Format-Table -AutoSize
  ''
  'Summary'
  $result | Select-Object level,dry_run,only,estimated_deleted_mb,estimated_skipped_mb,deleted_count,skipped_count | Format-List
  ''
  'Deleted groups'
  $Deleted | Group-Object reason | ForEach-Object {
    $mb = ($_.Group | Measure-Object size_mb -Sum).Sum
    [pscustomobject]@{ reason = $_.Name; items = $_.Count; size_mb = [math]::Round($mb, 2) }
  } | Sort-Object size_mb -Descending | Format-Table -AutoSize
  ''
  'Skipped groups'
  $Skipped | Group-Object message | ForEach-Object {
    $mb = ($_.Group | Measure-Object size_mb -Sum).Sum
    [pscustomobject]@{ message = $_.Name; items = $_.Count; size_mb = [math]::Round($mb, 2) }
  } | Sort-Object size_mb -Descending | Format-Table -AutoSize
}
