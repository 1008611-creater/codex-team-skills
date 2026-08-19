param(
  [string]$WorkspaceRoot = 'E:\codex\aisp\aidaihuo'
)

$ErrorActionPreference = 'Continue'
$projectsRoot = Join-Path $WorkspaceRoot 'github-selected-projects'
$worldMonitor = Join-Path $projectsRoot 'worldmonitor-upstream'
$deepTutor = Join-Path $projectsRoot 'deeptutor'
$crg = Join-Path $projectsRoot 'code-review-graph'
$archscribe = Join-Path $projectsRoot 'archscribe'
$officeCli = Get-Command officecli -ErrorAction SilentlyContinue

function Test-HttpEndpoint([string]$Name, [string]$Uri) {
  try {
    $response = Invoke-WebRequest -UseBasicParsing -Uri $Uri -TimeoutSec 5
    "${Name}: UP ($($response.StatusCode)) $Uri"
  } catch {
    "${Name}: DOWN $Uri"
  }
}

"Workspace: $WorkspaceRoot"
Test-HttpEndpoint 'WorldMonitor' 'http://127.0.0.1:3000'
Test-HttpEndpoint 'DeepTutor frontend' 'http://127.0.0.1:3782'
Test-HttpEndpoint 'DeepTutor backend' 'http://127.0.0.1:8001/'

$viteCmd = Join-Path $worldMonitor 'node_modules\.bin\vite.cmd'
$viteJs = Join-Path $worldMonitor 'node_modules\vite\bin\vite.js'
if ((Test-Path $viteCmd) -or (Test-Path $viteJs)) {
  'WorldMonitor install: READY'
} else {
  'WorldMonitor install: MISSING'
}

$crgExe = Join-Path $crg '.venv\Scripts\code-review-graph.exe'
if (Test-Path $crgExe) {
  'code-review-graph install: READY'
  & $crgExe --version 2>&1
} else {
  'code-review-graph install: MISSING'
}

$graphPath = Join-Path $crg '.code-review-graph'
if (Test-Path $graphPath) {
  'code-review-graph default index: PRESENT'
} else {
  'code-review-graph default index: NOT BUILT'
}

Push-Location $crg
try {
  & $crgExe status 2>&1
} finally {
  Pop-Location
}

$archscribePy = Join-Path $archscribe '.venv\Scripts\python.exe'
if (Test-Path $archscribePy) {
  'Archscribe install: READY'
  Push-Location $archscribe
  try {
    & $archscribePy scripts\doctor.py 2>&1
  } finally {
    Pop-Location
  }
} else {
  'Archscribe install: MISSING'
}

if ($officeCli) {
  'OfficeCLI install: READY'
  officecli --version 2>&1
  officecli config status 2>&1
} else {
  'OfficeCLI install: MISSING'
}

Push-Location $deepTutor
try {
  docker compose -p github-deeptutor -f docker-compose.ghcr.yml ps
} finally {
  Pop-Location
}
