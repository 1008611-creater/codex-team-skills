$ErrorActionPreference = "Stop"

$proxyPort = 58271
$node = (Get-Command node -ErrorAction Stop).Source
$proxyScript = Join-Path $PSScriptRoot "image-bridge-proxy.js"

$listening = $false
try {
  $client = [System.Net.Sockets.TcpClient]::new()
  $client.Connect("127.0.0.1", $proxyPort)
  $client.Close()
  $listening = $true
} catch {
  $listening = $false
}

if (-not $listening) {
  Start-Process -FilePath $node -ArgumentList "`"$proxyScript`"" -WindowStyle Hidden
}
