param(
  [string]$WorkspaceRoot = 'E:\codex\aisp\aidaihuo'
)

$ErrorActionPreference = 'Stop'
$projectsRoot = Join-Path $WorkspaceRoot 'github-selected-projects'
$worldMonitor = Join-Path $projectsRoot 'worldmonitor-upstream'
$deepTutor = Join-Path $projectsRoot 'deeptutor'
$logDir = Join-Path $projectsRoot 'logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

 $viteCmd = Join-Path $worldMonitor 'node_modules\.bin\vite.cmd'
 $viteJs = Join-Path $worldMonitor 'node_modules\vite\bin\vite.js'
if (-not (Test-Path $viteCmd) -and -not (Test-Path $viteJs)) {
  throw "WorldMonitor dependencies are missing. Run npm ci in $worldMonitor first."
}

$worldLog = Join-Path $logDir 'worldmonitor.log'
$worldErr = Join-Path $logDir 'worldmonitor.err.log'
if (Test-Path $viteCmd) {
  $worldProcess = Start-Process -FilePath 'npm.cmd' -ArgumentList 'run','dev','--','--host','127.0.0.1','--port','3000' -WorkingDirectory $worldMonitor -RedirectStandardOutput $worldLog -RedirectStandardError $worldErr -PassThru -WindowStyle Hidden
} else {
  $worldProcess = Start-Process -FilePath 'node.exe' -ArgumentList $viteJs,'--host','127.0.0.1','--port','3000' -WorkingDirectory $worldMonitor -RedirectStandardOutput $worldLog -RedirectStandardError $worldErr -PassThru -WindowStyle Hidden
}
Set-Content -LiteralPath (Join-Path $logDir 'worldmonitor.pid') -Value $worldProcess.Id -Encoding ascii

Push-Location $deepTutor
try {
  docker compose -p github-deeptutor -f docker-compose.ghcr.yml up -d
} finally {
  Pop-Location
}

"WorldMonitor started: http://127.0.0.1:3000 (PID $($worldProcess.Id))"
"DeepTutor starting: http://127.0.0.1:3782"
