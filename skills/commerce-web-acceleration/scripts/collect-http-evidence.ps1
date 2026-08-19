[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^https://')]
    [string]$Url,
    [switch]$RangeProbe
)

$redactedUri = [Uri]$Url
$safeUrl = $redactedUri.GetLeftPart([System.UriPartial]::Path)
$headerFile = Join-Path ([System.IO.Path]::GetTempPath()) ("commerce-web-acceleration-{0}.headers" -f [Guid]::NewGuid().ToString('N'))
$curlArgs = @('-sS', '--max-time', '30', '-D', $headerFile, '-o', 'NUL', '-w', 'dns=%{time_namelookup};connect=%{time_connect};tls=%{time_appconnect};ttfb=%{time_starttransfer};total=%{time_total};status=%{http_code};size=%{size_download}')
if ($RangeProbe) {
    $curlArgs += @('-H', 'Range: bytes=0-1023')
}
$curlArgs += @('--', $Url)
try {
    $timing = & curl.exe @curlArgs
    $headers = Get-Content -Raw $headerFile
} finally {
    Remove-Item -LiteralPath $headerFile -Force -ErrorAction SilentlyContinue
}

function Get-HeaderValue([string]$Name) {
    $match = $headers -split "`r?`n" | Where-Object { $_ -match "^$([regex]::Escape($Name)):\s*(.+)$" } | Select-Object -Last 1
    if ($match -match '^.+?:\s*(.+)$') { return $Matches[1].Trim() }
    return $null
}

$timingFields = @{}
$timing -split ';' | ForEach-Object {
    $parts = $_ -split '=', 2
    if ($parts.Count -eq 2) { $timingFields[$parts[0]] = $parts[1] }
}

[pscustomobject]@{
    url = $safeUrl
    rangeProbe = [bool]$RangeProbe
    status = $timingFields.status
    dnsMs = [math]::Round([double]$timingFields.dns * 1000, 1)
    connectMs = [math]::Round([double]$timingFields.connect * 1000, 1)
    tlsMs = [math]::Round([double]$timingFields.tls * 1000, 1)
    ttfbMs = [math]::Round([double]$timingFields.ttfb * 1000, 1)
    totalMs = [math]::Round([double]$timingFields.total * 1000, 1)
    transferredBytes = $timingFields.size
    contentType = Get-HeaderValue 'Content-Type'
    contentLength = Get-HeaderValue 'Content-Length'
    acceptRanges = Get-HeaderValue 'Accept-Ranges'
    cacheStatus = Get-HeaderValue 'CF-Cache-Status'
    ageSeconds = Get-HeaderValue 'Age'
    edgeRay = Get-HeaderValue 'CF-RAY'
} | ConvertTo-Json -Depth 3
