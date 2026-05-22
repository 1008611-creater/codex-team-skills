param(
  [string]$DbPath = "$env:USERPROFILE\.codex_agent_mem\codex_agent_mem.db",
  [string]$ProjectKey = (Get-Location).Path,
  [string]$ConfigPath = "$env:USERPROFILE\.codex\config.toml"
)

$ErrorActionPreference = "Stop"

$ScriptsDir = "$env:USERPROFILE\pipx\venvs\codex-agent-mem\Scripts"
$Smoke = Join-Path $ScriptsDir "codex-agent-mem-smoke.exe"
$Python = Join-Path $ScriptsDir "python.exe"

Write-Host "codex-agent-mem check"
Write-Host "Scripts: $ScriptsDir"
Write-Host "DB:      $DbPath"
Write-Host "Project: $ProjectKey"

if (-not (Test-Path -LiteralPath $Smoke)) {
  throw "codex-agent-mem-smoke.exe not found. Install with: python -m pipx install `"git+https://github.com/MarceloCaporale/codex-agent-mem.git`""
}

if (-not (Test-Path -LiteralPath $Python)) {
  throw "codex-agent-mem python.exe not found at $Python"
}

& $Smoke --db-path $DbPath --project-key $ProjectKey

if (Test-Path -LiteralPath $ConfigPath) {
  $config = Get-Content -LiteralPath $ConfigPath -Raw
  Write-Host ""
  Write-Host "Config checks:"
  Write-Host ("notify:               " + ($config -match "codex_agent_mem\.codex_notify"))
  Write-Host ("mcp server:           " + ($config -match '\[mcp_servers\."codex-agent-mem"\]'))
  Write-Host ("idle timeout 1800:    " + ($config -match "'1800'"))
  Write-Host ("compact response:     " + ($config -match "'compact'"))
} else {
  Write-Warning "Config file not found: $ConfigPath"
}
