param(
  [string]$Root = (Split-Path -Parent $PSScriptRoot),
  [string]$SshTarget = 'haika-niannian',
  [int]$RemotePort = 18090,
  [int]$LocalPort = 8090
)

$ErrorActionPreference = 'Stop'
$startupScript = Join-Path $Root 'scripts\run-local.ps1'

function Test-DolaHealth {
  try {
    $response = Invoke-RestMethod -Uri "http://127.0.0.1:$LocalPort/healthz" -TimeoutSec 5
    return $response.status -eq 'ok'
  } catch {
    return $false
  }
}

function Start-DolaApi {
  if (Test-DolaHealth) {
    return
  }

  if (-not (Test-Path -LiteralPath $startupScript)) {
    throw "Dola startup script is missing: $startupScript"
  }

  Start-Process -FilePath 'powershell.exe' -ArgumentList @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $startupScript, '-Root', $Root
  ) -WorkingDirectory $Root -WindowStyle Hidden

  for ($attempt = 0; $attempt -lt 24; $attempt++) {
    Start-Sleep -Seconds 5
    if (Test-DolaHealth) {
      return
    }
  }

  throw 'Dola Desktop API did not become healthy after startup.'
}

while ($true) {
  try {
    Start-DolaApi
    & ssh.exe -NT `
      -o BatchMode=yes `
      -o ExitOnForwardFailure=yes `
      -o ServerAliveInterval=30 `
      -o ServerAliveCountMax=3 `
      -R "127.0.0.1:$RemotePort`:127.0.0.1:$LocalPort" `
      $SshTarget
  } catch {
    # Keep retrying after local startup or network failures.
  }

  Start-Sleep -Seconds 5
}
