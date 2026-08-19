param(
  [string]$Root = $(if ($env:SELF_MEDIA_STACK_ROOT) { $env:SELF_MEDIA_STACK_ROOT } else { 'E:\codex\aisp\aidaihuo\.third-party\self-media-skill-route' })
)

$repoRoot = Join-Path $Root 'repos'
$py = 'C:\Users\lsb\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$results = [System.Collections.Generic.List[object]]::new()

function Add-Result([string]$Name, [string]$Check, [string]$Status, [string]$Evidence) {
  $results.Add([pscustomobject]@{ Project = $Name; Check = $Check; Status = $Status; Evidence = $Evidence })
}

function Run-Check([string]$Name, [string]$Check, [scriptblock]$Action) {
  try {
    $global:LASTEXITCODE = 0
    $output = & $Action 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) { Add-Result $Name $Check 'PASS' (($output.Trim() -replace '\s+', ' ') | Select-Object -First 1) }
    else { Add-Result $Name $Check 'FAIL' (($output.Trim() -replace '\s+', ' ') | Select-Object -First 1) }
  } catch {
    Add-Result $Name $Check 'BLOCKED' $_.Exception.Message
  }
}

Run-Check 'visual-director-skill' 'Codex plugin manifest' { if (Test-Path -LiteralPath (Join-Path $repoRoot 'visual-director-skill\plugins\visual-director\.codex-plugin\plugin.json')) { 'present' } else { throw 'manifest missing' } }
Run-Check 'socialforge' 'Codex plugin manifest' { if (Test-Path -LiteralPath (Join-Path $repoRoot 'socialforge\.codex-plugin\plugin.json')) { 'present' } else { throw 'manifest missing' } }
Run-Check 'social-video-planner-skill' 'SKILL.md present' { if (Test-Path -LiteralPath (Join-Path $repoRoot 'social-video-planner-skill\SKILL.md')) { 'present' } else { throw 'SKILL.md missing' } }
Run-Check 'awesome-social-media-skills' 'Skill collection present' { if (Test-Path -LiteralPath (Join-Path $repoRoot 'awesome-social-media-skills\skills')) { 'present' } else { throw 'skills directory missing' } }
Run-Check 'social-push' 'Skill workflow present' { if (Test-Path -LiteralPath (Join-Path $repoRoot 'social-push\skills\social-push\SKILL.md')) { 'present' } else { throw 'SKILL.md missing' } }

if (Test-Path -LiteralPath (Join-Path $repoRoot 'chinese-sensitive-words-mcp\package.json')) {
  Run-Check 'chinese-sensitive-words-mcp' 'build and tests' { Push-Location (Join-Path $repoRoot 'chinese-sensitive-words-mcp'); npm test; Pop-Location }
}

if (Test-Path -LiteralPath (Join-Path $repoRoot 'douyin-upload-mcp-skill\package.json')) {
  Run-Check 'douyin-upload-mcp-skill' 'module import' { Push-Location (Join-Path $repoRoot 'douyin-upload-mcp-skill'); node --check src/mcp-server.js; Pop-Location }
}

if (Test-Path -LiteralPath (Join-Path $repoRoot 'agent-reach\pyproject.toml')) {
  Run-Check 'agent-reach' 'package metadata' { & (Join-Path $repoRoot 'agent-reach\.venv\Scripts\python.exe') -m pip show agent-reach }
}

if (Test-Path -LiteralPath (Join-Path $repoRoot 'douyin-mcp\pyproject.toml')) {
  Run-Check 'douyin-mcp' 'package metadata' { & (Join-Path $repoRoot 'douyin-mcp\.venv\Scripts\python.exe') -m pip show douyin-creator-mcp }
}

if (Test-Path -LiteralPath (Join-Path $repoRoot 'xiaohongshu-mcp\go.mod')) {
  Run-Check 'xiaohongshu-mcp' 'go build' { Push-Location (Join-Path $repoRoot 'xiaohongshu-mcp'); go build ./...; Pop-Location }
}

if (Test-Path -LiteralPath (Join-Path $repoRoot 'clipforge\package.json')) {
  Run-Check 'clipforge' 'package metadata' { Push-Location (Join-Path $repoRoot 'clipforge'); pnpm --version; Pop-Location }
}

$results | Format-Table -AutoSize
$results | ConvertTo-Json -Depth 4 | Set-Content -Encoding utf8 -LiteralPath (Join-Path $Root 'smoke-results.json')
