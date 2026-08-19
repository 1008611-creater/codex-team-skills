param(
  [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

Set-Location $Root
$envFile = Join-Path $Root '.env'
if (-not (Test-Path $envFile)) {
  throw "Missing configuration file: $envFile. Copy .env.example to .env first."
}
Get-Content $envFile | ForEach-Object {
  $line = $_.Trim()
  if ($line -and -not $line.StartsWith('#')) {
    $pair = $line.Split('=', 2)
    if ($pair.Count -eq 2) {
      [Environment]::SetEnvironmentVariable($pair[0].Trim(), $pair[1].Trim(), 'Process')
    }
  }
}
docker compose -f docker-compose.infra.yml up -d
$env:PYTHONPATH = $Root
$python = Join-Path $Root '.venv\Scripts\python.exe'
if (-not (Test-Path $python)) {
  throw "Missing virtual environment: $python"
}
Start-Process $python -ArgumentList '-m','celery','-A','app.tasks.celery_app','worker','--loglevel=INFO','--pool=solo' -WorkingDirectory $Root -WindowStyle Hidden
& $python -m uvicorn app.main:app --host 127.0.0.1 --port 8090
