[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Reference,
    [Parameter(Mandatory, ParameterSetName = 'Inline')][string]$Prompt,
    [Parameter(Mandatory, ParameterSetName = 'File')][string]$PromptFile,
    [Parameter(Mandatory)][string]$Output,
    [string]$Channel = 'krill',
    [string]$Model = 'gpt-image-2',
    [string]$Size = '1024x1024'
)

$ErrorActionPreference = 'Stop'

function Get-Sha256([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-ChannelSettings([string]$Name) {
    if ($Name -eq 'krill') {
        return [pscustomobject]@{
            base_url = [string]$env:KRILL_BASE_URL
            api_key = [string]$env:KRILL_API_KEY
        }
    }

    $configPath = Join-Path $env:USERPROFILE '.codex\secrets\krill-image2.channels.json'
    if (-not (Test-Path -LiteralPath $configPath)) {
        throw "Image2 channel '$Name' is not configured."
    }
    try {
        $config = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $entry = $config.channels.$Name
    } catch {
        throw "Image2 channel configuration is invalid: $($_.Exception.Message)"
    }
    if ($null -eq $entry) {
        throw "Image2 channel '$Name' is not configured."
    }
    return [pscustomobject]@{
        base_url = [string]$entry.base_url
        api_prefix = [string]$entry.api_prefix
        api_key = [string]$entry.api_key
    }
}

$referencePath = (Resolve-Path -LiteralPath $Reference).Path
if ([IO.Path]::GetExtension($referencePath).ToLowerInvariant() -notin '.png', '.jpg', '.jpeg', '.webp') {
    throw 'Reference must be a PNG, JPEG, or WebP image.'
}
if ($PSCmdlet.ParameterSetName -eq 'File') {
    $Prompt = Get-Content -LiteralPath $PromptFile -Raw -Encoding UTF8
}
if ([string]::IsNullOrWhiteSpace($Prompt)) {
    throw 'Prompt must not be empty.'
}
if ($Size -notmatch '^(\d+)x(\d+)$' -or [int]$Matches[1] -gt 3840 -or [int]$Matches[2] -gt 3840 -or [int]$Matches[1] % 16 -ne 0 -or [int]$Matches[2] % 16 -ne 0) {
    throw 'Size must use WIDTHxHEIGHT; neither edge may exceed 3840 and both must be divisible by 16.'
}
if ($Channel -eq 'yunfei-1k' -and ($Model -ne 'gpt-image-2' -or $Size -ne '1024x1024')) {
    throw "Image2 channel 'yunfei-1k' is restricted to model gpt-image-2 at 1024x1024."
}
if ($Channel -eq 'yunfei-hd' -and ($Model -ne 'gpt-image-2' -or ($Size -ne '2048x1152' -and $Size -ne '3840x2160'))) {
    throw "Image2 channel 'yunfei-hd' is restricted to model gpt-image-2 at 2048x1152 (2K) or 3840x2160 (4K)."
}
$channelSettings = Get-ChannelSettings $Channel
$baseUrl = [string]$channelSettings.base_url
$apiPrefix = [string]$channelSettings.api_prefix
$apiKey = [string]$channelSettings.api_key
if (-not $baseUrl.StartsWith('https://') -or [string]::IsNullOrWhiteSpace($apiKey)) {
    throw "Image2 channel '$Channel' has no valid HTTPS base URL or API key."
}
$outputPath = [IO.Path]::GetFullPath($Output)
$outputDirectory = Split-Path -Parent $outputPath
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null

try {
    $editUri = $baseUrl.TrimEnd('/') + $apiPrefix.TrimEnd('/') + '/images/edits'
    $response = Invoke-RestMethod -Uri $editUri -Method Post `
        -Headers @{ Authorization = "Bearer $apiKey" } `
        -Form @{ model = $Model; image = Get-Item -LiteralPath $referencePath; prompt = $Prompt; size = $Size; n = '1' } `
        -TimeoutSec 240
} catch {
    $detail = $_.ErrorDetails.Message
    if ($detail.Length -gt 1000) { $detail = $detail.Substring(0, 1000) }
    throw "Krill Image2 request failed: $($_.Exception.Message) $detail"
}
$encoded = @($response.data)[0].b64_json
if (-not [string]::IsNullOrWhiteSpace($encoded)) {
    [IO.File]::WriteAllBytes($outputPath, [Convert]::FromBase64String([string]$encoded))
} else {
    $resultUrl = [string](@($response.data)[0].url)
    if ([string]::IsNullOrWhiteSpace($resultUrl)) {
        throw 'Krill Image2 response did not include b64_json or a downloadable URL.'
    }
    Invoke-WebRequest -Uri $resultUrl -OutFile $outputPath -TimeoutSec 120
}
if ((Get-Item -LiteralPath $outputPath).Length -eq 0) {
    throw 'Krill Image2 returned an empty image file.'
}
$manifest = [ordered]@{
    provider = 'krill'
    channel = $Channel
    endpoint = '/images/edits'
    model = $Model
    reference_path = $referencePath
    reference_sha256 = Get-Sha256 $referencePath
    prompt_sha256 = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($Prompt))).ToLowerInvariant()
    output_path = $outputPath
    output_sha256 = Get-Sha256 $outputPath
    output_bytes = (Get-Item -LiteralPath $outputPath).Length
    created_at = [DateTime]::UtcNow.ToString('o')
}
$manifestPath = "$outputPath.manifest.json"
$manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
[pscustomobject]@{ output = $outputPath; manifest = $manifestPath; sha256 = $manifest.output_sha256 } | ConvertTo-Json -Compress
