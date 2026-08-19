param(
  [string]$Root = (Join-Path $PSScriptRoot '..\references\repos')
)

$repos = @(
  @{ Name = 'web2api'; Url = 'https://github.com/Endogen/web2api.git' },
  @{ Name = 'desafio-01'; Url = 'https://github.com/FaBrCh/desafio-01.git' },
  @{ Name = 'sample-browser-order-automation-agentcore'; Url = 'https://github.com/aws-samples/sample-browser-order-automation-agentcore.git' },
  @{ Name = 'editapi'; Url = 'https://github.com/iminoaru/editapi.git' },
  @{ Name = 'ChromaFFmpeg'; Url = 'https://github.com/leksautomate/ChromaFFmpeg.git' }
)

New-Item -ItemType Directory -Force $Root | Out-Null
foreach ($repo in $repos) {
  $path = Join-Path $Root $repo.Name
  if (Test-Path (Join-Path $path '.git')) {
    git -C $path fetch --depth 1 origin
    git -C $path reset --hard origin/HEAD
  } else {
    git clone --depth 1 $repo.Url $path
  }
  if ($LASTEXITCODE -ne 0) { throw "Failed to sync $($repo.Name)" }
}
