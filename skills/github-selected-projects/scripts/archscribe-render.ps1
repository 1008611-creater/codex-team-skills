param(
  [string]$WorkspaceRoot = 'E:\codex\aisp\aidaihuo',
  [string]$Spec = 'assets\default-spec.json',
  [string]$OutDir = 'outputs',
  [string]$BaseName = 'diagram',
  [string]$Formats = 'png'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Join-Path (Join-Path $WorkspaceRoot 'github-selected-projects') 'archscribe'
$python = Join-Path $projectRoot '.venv\Scripts\python.exe'

if (-not (Test-Path $python)) {
  throw "Archscribe virtual environment not found: $python"
}

$specPath = if ([System.IO.Path]::IsPathRooted($Spec)) { $Spec } else { Join-Path $projectRoot $Spec }
$outPath = if ([System.IO.Path]::IsPathRooted($OutDir)) { $OutDir } else { Join-Path $projectRoot $OutDir }

if (-not (Test-Path $specPath)) {
  throw "Archscribe spec not found: $specPath"
}

Push-Location $projectRoot
try {
  & $python -X utf8 scripts\render_animated_diagram.py `
    --spec $specPath `
    --outdir $outPath `
    --basename $BaseName `
    --formats $Formats `
    --verify `
    --check `
    --strict-formats
  if ($LASTEXITCODE -ne 0) {
    throw "Archscribe render failed with exit code $LASTEXITCODE"
  }
} finally {
  Pop-Location
}
