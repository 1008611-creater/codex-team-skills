param(
  [string]$DbPath = "$env:USERPROFILE\.codex_agent_mem\codex_agent_mem.db",
  [int]$IdleTimeoutSeconds = 1800,
  [ValidateSet("minimal", "standard", "full")]
  [string]$Profile = "full",
  [ValidateSet("compact", "balanced", "verbose")]
  [string]$ResponseMode = "compact"
)

$ErrorActionPreference = "Stop"

$Bootstrap = "$env:USERPROFILE\pipx\venvs\codex-agent-mem\Scripts\codex-agent-mem-bootstrap-codex.exe"
if (-not (Test-Path -LiteralPath $Bootstrap)) {
  throw "codex-agent-mem-bootstrap-codex.exe not found. Install codex-agent-mem with pipx first."
}

& $Bootstrap `
  --db-path $DbPath `
  --idle-timeout-seconds $IdleTimeoutSeconds `
  --mcp-profile $Profile `
  --response-mode $ResponseMode
