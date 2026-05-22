param(
  [Parameter(Mandatory = $true)]
  [string]$Url,
  [string]$OutputDir = "D:\codex-work\ip\output\demand_radar\weixin-opencli-test",
  [switch]$DownloadImages,
  [switch]$EnsureBridge
)

$ErrorActionPreference = "Stop"

if ($Url -notmatch "^https://mp\.weixin\.qq\.com/") {
  throw "Expected a mp.weixin.qq.com URL, got: $Url"
}

if ($EnsureBridge) {
  $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
  & (Join-Path $scriptDir "start-opencli-browser-bridge.ps1")
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$downloadImagesValue = if ($DownloadImages) { "true" } else { "false" }
npx -y @jackwener/opencli weixin download `
  --url $Url `
  --output $OutputDir `
  --download-images $downloadImagesValue `
  --site-session persistent `
  -f yaml `
  --trace retain-on-failure
