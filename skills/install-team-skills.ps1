param(
  [string]$CodexHome = "$env:USERPROFILE\.codex",
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$source = Split-Path -Parent $MyInvocation.MyCommand.Path
$targetRoot = Join-Path $CodexHome "skills"

if (-not (Test-Path -LiteralPath $source)) {
  throw "Source skills directory not found: $source"
}

New-Item -ItemType Directory -Force -Path $targetRoot | Out-Null

$excludedNames = @(
  ".git",
  "node_modules",
  "__pycache__",
  ".env",
  ".env.local",
  "config.env",
  "desktop.ini",
  "Thumbs.db"
)

$skills = Get-ChildItem -LiteralPath $source -Directory |
  Where-Object { $_.Name -notin @(".system") }

foreach ($skill in $skills) {
  $dest = Join-Path $targetRoot $skill.Name
  Write-Host "Installing skill: $($skill.Name) -> $dest"

  if ($DryRun) {
    continue
  }

  New-Item -ItemType Directory -Force -Path $dest | Out-Null
  Get-ChildItem -LiteralPath $skill.FullName -Recurse -File | ForEach-Object {
    if ($excludedNames -contains $_.Name) {
      return
    }

    $relative = $_.FullName.Substring($skill.FullName.Length).TrimStart("\", "/")
    $outPath = Join-Path $dest $relative
    $outDir = Split-Path -Parent $outPath
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
    Copy-Item -LiteralPath $_.FullName -Destination $outPath -Force
  }
}

Write-Host ""
Write-Host "Done. Restart Codex so it can discover the installed skills."
Write-Host "Installed count: $($skills.Count)"
