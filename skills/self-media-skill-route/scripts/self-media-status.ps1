param(
  [string]$Root = $(if ($env:SELF_MEDIA_STACK_ROOT) { $env:SELF_MEDIA_STACK_ROOT } else { 'E:\codex\aisp\aidaihuo\.third-party\self-media-skill-route' })
)

$repoRoot = Join-Path $Root 'repos'
if (-not (Test-Path -LiteralPath $repoRoot)) {
  throw "Third-party repo root not found: $repoRoot"
}

$runtime = [ordered]@{
  node = (node --version 2>$null)
  npm = (npm --version 2>$null)
  pnpm = (pnpm --version 2>$null)
  go = (go version 2>$null)
  python = (& 'C:\Users\lsb\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' --version 2>$null)
  ffmpeg = (ffmpeg -version 2>$null | Select-Object -First 1)
}

Write-Output '=== 自媒体 Skill 路由状态 ==='
Write-Output "Root: $Root"
Write-Output ('Runtime: ' + (($runtime.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '; '))
Write-Output ''

Get-ChildItem -Directory -LiteralPath $repoRoot | Sort-Object Name | ForEach-Object {
  $repo = $_.FullName
  $head = git -C $repo rev-parse --short HEAD 2>$null
  $branch = git -C $repo branch --show-current 2>$null
  $readme = Test-Path -LiteralPath (Join-Path $repo 'README.md')
  $nodeModules = Test-Path -LiteralPath (Join-Path $repo 'node_modules')
  $venv = (Test-Path -LiteralPath (Join-Path $repo '.venv')) -or (Test-Path -LiteralPath (Join-Path $repo '.venv-mcp'))
  [pscustomobject]@{
    Repo = $_.Name
    Branch = $branch
    Commit = $head
    Readme = $readme
    NodeModules = $nodeModules
    PythonVenv = $venv
  }
} | Format-Table -AutoSize
