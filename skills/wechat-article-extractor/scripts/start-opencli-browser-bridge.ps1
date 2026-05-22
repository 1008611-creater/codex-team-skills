param(
  [switch]$RestartProfile,
  [string]$CacheRoot = "$env:USERPROFILE\.codex\tools\opencli-browser-bridge",
  [string]$ReleaseTag = "v1.8.0",
  [string]$ExtensionVersion = "1.0.15",
  [string]$EdgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

if (-not (Test-Path $EdgePath)) {
  throw "Edge executable not found: $EdgePath"
}

$zipName = "opencli-extension-v$ExtensionVersion.zip"
$zipPath = Join-Path $CacheRoot $zipName
$extDir = Join-Path $CacheRoot "opencli-extension-v$ExtensionVersion"
$profileDir = Join-Path $CacheRoot "edge-profile"
$manifestPath = Join-Path $extDir "manifest.json"

New-Item -ItemType Directory -Force -Path $CacheRoot | Out-Null

if (-not (Test-Path $manifestPath)) {
  $url = "https://github.com/jackwener/OpenCLI/releases/download/$ReleaseTag/$zipName"
  Invoke-WebRequest -Uri $url -OutFile $zipPath
  if (Test-Path $extDir) {
    Remove-Item -Recurse -Force -Path $extDir
  }
  Expand-Archive -Path $zipPath -DestinationPath $extDir -Force
}

if (-not (Test-Path $manifestPath)) {
  throw "OpenCLI extension manifest not found after setup: $manifestPath"
}

if ($RestartProfile) {
  $procs = Get-CimInstance Win32_Process |
    Where-Object { $_.Name -eq "msedge.exe" -and $_.CommandLine -like "*$profileDir*" }
  foreach ($p in $procs) {
    Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
  }
  Start-Sleep -Seconds 2
}

npx -y @jackwener/opencli daemon restart | Write-Output

New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
$args = @(
  "--user-data-dir=$profileDir",
  "--disable-extensions-except=$extDir",
  "--load-extension=$extDir",
  "--no-first-run",
  "--no-proxy-server",
  "--disable-ipv6",
  "--new-window",
  "edge://extensions/"
)

Start-Process -FilePath $EdgePath -ArgumentList $args
Start-Sleep -Seconds 8
npx -y @jackwener/opencli doctor
