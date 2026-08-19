param(
  [string]$RepoPath = 'E:\codex\aisp\aidaihuo\github-selected-projects\code-review-graph',
  [string]$WorkspaceRoot = 'E:\codex\aisp\aidaihuo'
)

$ErrorActionPreference = 'Stop'
$crgExe = Join-Path $WorkspaceRoot 'github-selected-projects\code-review-graph\.venv\Scripts\code-review-graph.exe'
if (-not (Test-Path $crgExe)) {
  throw "code-review-graph is not installed: $crgExe"
}
if (-not (Test-Path (Join-Path $RepoPath '.git'))) {
  throw "RepoPath must be a Git repository: $RepoPath"
}

Push-Location $RepoPath
try {
  & $crgExe build
  & $crgExe status
} finally {
  Pop-Location
}
