param(
  [int]$Window,
  [int[]]$Ports,
  [switch]$RawEndpoint
)

$ErrorActionPreference = "SilentlyContinue"

if (-not $Ports -or $Ports.Count -eq 0) {
  $Ports = Get-NetTCPConnection -State Listen |
    Where-Object {
      $_.LocalAddress -in @("127.0.0.1", "0.0.0.0") -and
      $_.LocalPort -ge 50000 -and
      ((Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName -like "*BitBrowser*")
    } |
    Select-Object -ExpandProperty LocalPort
}

$results = @()
foreach ($port in ($Ports | Sort-Object -Unique)) {
  try {
    $version = Invoke-RestMethod -Uri "http://127.0.0.1:$port/json/version" -TimeoutSec 1
    if (-not $version.Browser -or $version.Browser -notmatch "Chrome") { continue }
    $tabs = Invoke-RestMethod -Uri "http://127.0.0.1:$port/json/list" -TimeoutSec 1
    $tabText = ($tabs | ForEach-Object { "$($_.title) <$($_.url)>" }) -join " || "
    $workbench = $tabs | Where-Object { $_.title -match "^\d+-工作台$" } | Select-Object -First 1
    $num = $null
    if ($workbench -and $workbench.title -match "^(\d+)-工作台$") {
      $num = [int]$Matches[1]
    }
    $results += [PSCustomObject]@{
      Window = $num
      Port = $port
      Endpoint = "http://127.0.0.1:$port"
      Workbench = $workbench.title
      Tabs = $tabText
    }
  } catch {}
}

if ($Window) {
  $match = $results | Where-Object { $_.Window -eq $Window } | Select-Object -First 1
  if (-not $match) {
    Write-Error "No BitBrowser CDP endpoint found for window $Window."
    $results | Format-Table Window,Port,Endpoint,Workbench -AutoSize
    exit 1
  }
  if ($RawEndpoint) {
    Write-Output $match.Endpoint
    exit 0
  }
  $match | Format-List
  exit 0
}

$results | Sort-Object Window,Port | Format-Table Window,Port,Endpoint,Workbench -AutoSize
