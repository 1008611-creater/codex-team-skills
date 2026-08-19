param(
  [string]$CodexHome = ""
)
$ErrorActionPreference = "Stop"
$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Source = Join-Path $PackageRoot "payload\director-color-card"
if (-not (Test-Path -LiteralPath (Join-Path $Source "SKILL.md"))) {
  throw "Package incomplete: missing payload\director-color-card\SKILL.md"
}
if ([string]::IsNullOrWhiteSpace($CodexHome)) {
  if (-not [string]::IsNullOrWhiteSpace($env:CODEX_HOME)) {
    $CodexHome = $env:CODEX_HOME
  } else {
    $CodexHome = Join-Path $HOME ".codex"
  }
}
$CodexHome = [IO.Path]::GetFullPath($CodexHome)
$SkillsRoot = Join-Path $CodexHome "skills"
$Target = Join-Path $SkillsRoot "director-color-card"
New-Item -ItemType Directory -Path $SkillsRoot -Force | Out-Null
if (Test-Path -LiteralPath $Target) {
  $Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
  $Backup = Join-Path $SkillsRoot ("director-color-card.backup-" + $Stamp)
  Move-Item -LiteralPath $Target -Destination $Backup
  Write-Output ("Backed up previous version: " + $Backup)
}
Copy-Item -LiteralPath $Source -Destination $Target -Recurse
$PromptCount = @(Get-ChildItem -LiteralPath (Join-Path $Target "references\seedance-prompts") -File -Filter "D*.md").Count
if ($PromptCount -ne 175) { throw "Install check failed: Seedance prompt count is $PromptCount, expected 175." }
if (-not (Test-Path -LiteralPath (Join-Path $Target "references\director-index.md"))) {
  throw "Install check failed: missing director index."
}
Write-Output "Installed successfully: $Target"
Write-Output "Restart Codex or create a new task, then type:"
Write-Output '$director-color-card Ozu, copy-ready Seedance 2.0 color prompt'
