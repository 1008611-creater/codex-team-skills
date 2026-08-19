$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Skill = Join-Path $Root "payload\director-color-card"
$Required = @(
  "SKILL.md",
  "agents\openai.yaml",
  "scripts\build_palette_card.py",
  "scripts\palette_core.py",
  "scripts\verify_palette_card.py",
  "references\director-index.md",
  "references\card-schema.md",
  "references\palette-rendering-workflow.md",
  "references\llm-director-color-card-master-prompt.md",
  "references\seedance-prompts-index.csv",
  "assets\director-manifest-example.json",
  "assets\universal-prompts.md",
  "assets\palette-templates\director-dark.html",
  "assets\palette-templates\director-light.html",
  "assets\palette-templates\scene-analysis.html",
  "assets\branding\branding-manifest.json",
  "tests\test_color_card_skill.py"
)
foreach ($Relative in $Required) {
  if (-not (Test-Path -LiteralPath (Join-Path $Skill $Relative))) { throw "Missing required file: $Relative" }
}
$PromptCount = @(Get-ChildItem -LiteralPath (Join-Path $Skill "references\seedance-prompts") -File -Filter "D*.md").Count
if ($PromptCount -ne 175) { throw "Prompt count error: $PromptCount" }
$VolumeCount = @(Get-ChildItem -LiteralPath (Join-Path $Skill "references") -File -Filter "*-*-*.md" | Where-Object { $_.Name -match "001-025|026-050|051-075|076-100|101-125|126-150|151-175" }).Count
if ($VolumeCount -ne 7) { throw "Director volume count error: $VolumeCount" }
$LibraryCount = @(Get-ChildItem -LiteralPath (Join-Path $Skill "references") -File -Filter "*Seedance2.0*Prompt*.md").Count
if ($LibraryCount -lt 1) { throw "Missing full Seedance prompt library" }
$SkillText = Get-Content -Encoding UTF8 -Raw -LiteralPath (Join-Path $Skill "SKILL.md")
if ($SkillText -match "director-color-card" -and $SkillText -match "AIGC") {
  Write-Output "PASS package structure ok, Seedance Prompt=175, scope=color-card only"
} else {
  throw "SKILL.md does not declare color-card-only scope."
}
