param(
  [string]$WorkspaceRoot = 'E:\codex\aisp\aidaihuo'
)

$ErrorActionPreference = 'Continue'
$projectsRoot = Join-Path $WorkspaceRoot 'github-selected-projects'
$logDir = Join-Path $projectsRoot 'logs'
$pidFile = Join-Path $logDir 'worldmonitor.pid'
if (Test-Path $pidFile) {
  $pidValue = Get-Content -Raw -LiteralPath $pidFile
  $process = Get-Process -Id ([int]$pidValue.Trim()) -ErrorAction SilentlyContinue
  if ($process) {
    Stop-Process -Id $process.Id -Force
    "WorldMonitor stopped (PID $($process.Id))"
  }
}

$deepTutor = Join-Path $projectsRoot 'deeptutor'
Push-Location $deepTutor
try {
  docker compose -p github-deeptutor -f docker-compose.ghcr.yml down
} finally {
  Pop-Location
}
