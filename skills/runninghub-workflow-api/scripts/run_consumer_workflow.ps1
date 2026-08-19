[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$WorkflowId,

    [ValidateSet('default', 'plus', 'ultra')]
    [string]$InstanceType = 'plus',

    [string[]]$FileInput = @(),
    [string[]]$ValueInput = @(),
    [string]$ApiKey = $env:RUNNINGHUB_API_KEY,
    [string]$OutputDirectory = (Join-Path $env:USERPROFILE 'Downloads\RunningHubOutputs'),
    [int]$PollSeconds = 15,
    [int]$MaxPollMinutes = 60,
    [int]$UploadTimeoutSeconds = 600,
    [int]$UploadRetries = 4,
    [bool]$RequireCoins = $true,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function ConvertTo-NodeMapping {
    param([Parameter(Mandatory = $true)][string]$Text)

    $pair = $Text -split '=', 2
    if ($pair.Count -ne 2 -or [string]::IsNullOrWhiteSpace($pair[1])) {
        throw "Invalid mapping '$Text'. Expected nodeId.fieldName=value."
    }
    $key = $pair[0] -split '\.', 2
    if ($key.Count -ne 2 -or [string]::IsNullOrWhiteSpace($key[0]) -or [string]::IsNullOrWhiteSpace($key[1])) {
        throw "Invalid mapping key '$($pair[0])'. Expected nodeId.fieldName."
    }
    [pscustomobject]@{ nodeId = $key[0]; fieldName = $key[1]; value = $pair[1] }
}

function Get-MimeType {
    param([Parameter(Mandatory = $true)][string]$Path)

    switch ([IO.Path]::GetExtension($Path).ToLowerInvariant()) {
        '.mp4' { 'video/mp4' }
        '.mov' { 'video/quicktime' }
        '.webm' { 'video/webm' }
        '.png' { 'image/png' }
        '.jpg' { 'image/jpeg' }
        '.jpeg' { 'image/jpeg' }
        '.webp' { 'image/webp' }
        '.wav' { 'audio/wav' }
        '.mp3' { 'audio/mpeg' }
        '.m4a' { 'audio/mp4' }
        default { 'application/octet-stream' }
    }
}

function Invoke-CurlJson {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = 'curl.exe'
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($argument in $Arguments) {
        [void]$startInfo.ArgumentList.Add($argument)
    }

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    [void]$process.Start()
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    if ($process.ExitCode -ne 0) {
        throw "curl failed with exit code $($process.ExitCode): $stderr"
    }
    try {
        return $stdout | ConvertFrom-Json
    } catch {
        throw "RunningHub returned non-JSON data: $stdout"
    }
}

function Send-MediaFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$BearerKey
    )

    $mimeType = Get-MimeType -Path $Path
    $response = Invoke-CurlJson -Arguments @(
        '--http1.1', '--silent', '--show-error',
        '--connect-timeout', '30', '--max-time', [string]$UploadTimeoutSeconds,
        '--retry', [string]$UploadRetries, '--retry-delay', '3', '--retry-all-errors',
        '--location', 'https://www.runninghub.cn/openapi/v2/media/upload/binary',
        '--header', "Authorization: Bearer $BearerKey",
        '--form', "file=@$Path;type=$mimeType"
    )
    if ($response.code -ne 0) {
        throw "Upload failed for '$Path': $($response.message)"
    }
    $url = if ($response.data.download_url) { $response.data.download_url } else { $response.data.fileName }
    if ([string]::IsNullOrWhiteSpace($url)) {
        throw "Upload succeeded without data.download_url or data.fileName for '$Path'."
    }
    return $url
}

if ([string]::IsNullOrWhiteSpace($WorkflowId) -or $WorkflowId -notmatch '^\d+$') {
    throw 'WorkflowId must contain digits only.'
}
if ($PollSeconds -lt 5 -or $MaxPollMinutes -lt 1) {
    throw 'PollSeconds must be at least 5 and MaxPollMinutes at least 1.'
}

$fileMappings = @($FileInput | ForEach-Object { ConvertTo-NodeMapping -Text $_ })
$valueMappings = @($ValueInput | ForEach-Object { ConvertTo-NodeMapping -Text $_ })
if (($fileMappings.Count + $valueMappings.Count) -eq 0) {
    throw 'At least one FileInput or ValueInput is required.'
}
$duplicateNodeInputs = @($fileMappings + $valueMappings | Group-Object { "$($_.nodeId).$($_.fieldName)" } | Where-Object Count -gt 1)
if ($duplicateNodeInputs.Count -gt 0) {
    throw "Duplicate node inputs: $(@($duplicateNodeInputs.Name) -join ', ')"
}

$resolvedFiles = @{}
foreach ($mapping in $fileMappings) {
    $resolved = (Resolve-Path -LiteralPath $mapping.value).Path
    if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
        throw "Input file does not exist: $resolved"
    }
    $mapping.value = $resolved
    $resolvedFiles[$resolved] = $null
}

if ($DryRun) {
    [pscustomobject]@{
        dryRun = $true
        workflowId = $WorkflowId
        instanceType = $InstanceType
        fileInputs = @($fileMappings | ForEach-Object { "$($_.nodeId).$($_.fieldName)=$([IO.Path]::GetFileName($_.value))" })
        valueInputs = @($valueMappings | ForEach-Object { "$($_.nodeId).$($_.fieldName)=<value>" })
        uniqueUploadCount = $resolvedFiles.Count
        requireCoins = $RequireCoins
    } | ConvertTo-Json -Depth 5
    return
}

if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    throw 'Set RUNNINGHUB_API_KEY or pass ApiKey. The key is never written to disk.'
}

$uploadedUrls = @{}
foreach ($path in @($resolvedFiles.Keys)) {
    Write-Host "Uploading $([IO.Path]::GetFileName($path)) over HTTP/1.1..."
    $uploadedUrls[$path] = Send-MediaFile -Path $path -BearerKey $ApiKey
}

$nodeInfoList = @()
foreach ($mapping in $fileMappings) {
    $nodeInfoList += @{ nodeId = $mapping.nodeId; fieldName = $mapping.fieldName; fieldValue = $uploadedUrls[$mapping.value] }
}
foreach ($mapping in $valueMappings) {
    $nodeInfoList += @{ nodeId = $mapping.nodeId; fieldName = $mapping.fieldName; fieldValue = $mapping.value }
}

$headers = @{ Authorization = "Bearer $ApiKey"; 'Content-Type' = 'application/json' }
$submitBody = @{
    addMetadata = $true
    nodeInfoList = $nodeInfoList
    instanceType = $InstanceType
    usePersonalQueue = $false
} | ConvertTo-Json -Depth 8 -Compress

# Do not automatically retry this request: an ambiguous retry can create a second paid task.
$submit = Invoke-RestMethod -Method Post -Uri "https://www.runninghub.cn/openapi/v2/run/workflow/$WorkflowId" `
    -Headers $headers -Body $submitBody -TimeoutSec 180
if ([string]::IsNullOrWhiteSpace($submit.taskId)) {
    throw "Workflow submission returned no taskId: $($submit | ConvertTo-Json -Depth 8 -Compress)"
}
$taskId = [string]$submit.taskId
Write-Host "Submitted task $taskId with status $($submit.status)."

$queryBody = @{ taskId = $taskId } | ConvertTo-Json -Compress
$deadline = (Get-Date).AddMinutes($MaxPollMinutes)
$result = $null
while ((Get-Date) -lt $deadline) {
    try {
        $result = Invoke-RestMethod -Method Post -Uri 'https://www.runninghub.cn/openapi/v2/query' `
            -Headers $headers -Body $queryBody -TimeoutSec 60
    } catch {
        Write-Warning "Transient query failure for task ${taskId}: $($_.Exception.Message)"
        Start-Sleep -Seconds $PollSeconds
        continue
    }
    Write-Host "Task $taskId status: $($result.status)"
    if ($result.status -in @('SUCCESS', 'FAILED')) { break }
    Start-Sleep -Seconds $PollSeconds
}

if ($null -eq $result -or $result.status -notin @('SUCCESS', 'FAILED')) {
    throw "Polling timed out for task $taskId. Query this task again; do not resubmit it."
}
if ($result.status -eq 'FAILED') {
    throw "Task $taskId failed [$($result.errorCode)]: $($result.errorMessage); failedReason=$($result.failedReason | ConvertTo-Json -Depth 8 -Compress)"
}

$coins = [decimal]::Zero
$money = [decimal]::Zero
$hasCoins = $null -ne $result.usage.consumeCoins -and [decimal]::TryParse([string]$result.usage.consumeCoins, [ref]$coins) -and $coins -gt 0
$moneyIsZero = $null -eq $result.usage.consumeMoney -or $result.usage.consumeMoney -eq '' -or ([decimal]::TryParse([string]$result.usage.consumeMoney, [ref]$money) -and $money -eq 0)
if ($RequireCoins -and (-not $hasCoins -or -not $moneyIsZero)) {
    throw "Task $taskId succeeded but RH billing validation failed: consumeCoins=$($result.usage.consumeCoins), consumeMoney=$($result.usage.consumeMoney)."
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$downloaded = @()
foreach ($output in @($result.results | Where-Object { $_.url })) {
    $extension = ([string]$output.outputType).TrimStart('.')
    if ([string]::IsNullOrWhiteSpace($extension)) { $extension = 'bin' }
    $nodeId = ([string]$output.nodeId) -replace '[^A-Za-z0-9_-]', '_'
    $target = Join-Path $OutputDirectory "$taskId`_$nodeId.$extension"
    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
        $partial = "$target.$([guid]::NewGuid().ToString('N')).part"
        try {
            Invoke-WebRequest -Uri $output.url -OutFile $partial -TimeoutSec 600
            if ((Get-Item -LiteralPath $partial).Length -le 0) { throw "Downloaded file is empty: $partial" }
            Move-Item -LiteralPath $partial -Destination $target
        } finally {
            if (Test-Path -LiteralPath $partial) { Remove-Item -LiteralPath $partial -Force }
        }
    }
    if ((Get-Item -LiteralPath $target).Length -le 0) { throw "Output file is empty: $target" }
    if ($extension -match '^(mp4|mov|webm|mkv)$' -and (Get-Command ffprobe -ErrorAction SilentlyContinue)) {
        & ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,width,height,duration -of json -- $target | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "ffprobe could not read video output: $target" }
    }
    $downloaded += $target
}
if ($downloaded.Count -eq 0) { throw "Task $taskId succeeded without downloadable results." }

[pscustomobject]@{
    taskId = $taskId
    status = $result.status
    consumeCoins = $result.usage.consumeCoins
    consumeMoney = $result.usage.consumeMoney
    thirdPartyConsumeMoney = $result.usage.thirdPartyConsumeMoney
    taskCostTime = $result.usage.taskCostTime
    downloaded = $downloaded
} | ConvertTo-Json -Depth 6
