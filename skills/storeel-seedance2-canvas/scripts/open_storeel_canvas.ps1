$ErrorActionPreference = "Stop"
$scriptPath = Join-Path $PSScriptRoot "open_storeel_canvas.mjs"
$skillRoot = Split-Path $PSScriptRoot -Parent
Push-Location $skillRoot
try {
  node $scriptPath
} finally {
  Pop-Location
}
