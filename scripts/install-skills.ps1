param(
  [string]$Source = (Join-Path $PSScriptRoot "..\skills"),
  [string]$Destination = (Join-Path $env:USERPROFILE ".codex\skills"),
  [string[]]$Only = @(),
  [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

$sourcePath = (Resolve-Path -LiteralPath $Source).Path
if (-not (Test-Path -LiteralPath $Destination)) {
  New-Item -ItemType Directory -Force -Path $Destination | Out-Null
}
$destPath = (Resolve-Path -LiteralPath $Destination).Path

$skills = Get-ChildItem -LiteralPath $sourcePath -Directory | Sort-Object Name
if ($Only.Count -gt 0) {
  $wanted = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
  foreach ($name in $Only) { [void]$wanted.Add($name) }
  $skills = $skills | Where-Object { $wanted.Contains($_.Name) }
}

if (-not $skills) {
  Write-Host "No skills matched." -ForegroundColor Yellow
  exit 0
}

foreach ($skill in $skills) {
  $target = Join-Path $destPath $skill.Name
  Write-Host "Installing $($skill.Name) -> $target"
  if ($WhatIf) { continue }
  if (Test-Path -LiteralPath $target) {
    Remove-Item -LiteralPath $target -Recurse -Force
  }
  Copy-Item -LiteralPath $skill.FullName -Destination $target -Recurse -Force
}

Write-Host "Done. Installed $($skills.Count) skill(s)." -ForegroundColor Green
