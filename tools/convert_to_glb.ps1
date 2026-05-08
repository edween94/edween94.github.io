<#
.SYNOPSIS
    Converts a KiCad VRML (.wrl) file to a GLB using Blender, then copies
    the result into the portfolio's assets/projects folder.

.PARAMETER InputVRML
    Path to the VRML (.wrl) file you want to convert.
    Defaults to the KiCad ESC project location.

.PARAMETER OutputName
    Name of the output GLB file (no path needed).
    Defaults to ElectronicSpeedController.glb

.EXAMPLE
    .\convert_to_glb.ps1
    .\convert_to_glb.ps1 -InputVRML "C:\path\to\board.wrl" -OutputName "MyBoard.glb"
#>
param(
    [string]$InputVRML  = "C:\Users\ebaid\OneDrive\Documents\Drone Design Project\Electronics Design\ElectronicSpeedController\ElectronicSpeedController.wrl",
    [string]$OutputName = "ElectronicSpeedController.glb"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Resolve paths ────────────────────────────────────────────────────────────
$scriptDir    = Split-Path -Parent $MyInvocation.MyCommand.Path
$portfolioDir = Split-Path -Parent $scriptDir
$outputDir    = Join-Path $portfolioDir "assets\projects"
$outputPath   = Join-Path $outputDir $OutputName
$pythonScript = Join-Path $scriptDir "vrml_to_glb.py"

# ── Find Blender ─────────────────────────────────────────────────────────────
$blenderCandidates = @(
    "C:\Program Files\Blender Foundation\Blender 5.1\blender.exe",
    "C:\Program Files\Blender Foundation\Blender 5.0\blender.exe",
    "C:\Program Files\Blender Foundation\Blender 4.4\blender.exe",
    "C:\Program Files\Blender Foundation\Blender 4.3\blender.exe",
    "C:\Program Files\Blender Foundation\Blender 4.2\blender.exe",
    "C:\Program Files\Blender Foundation\Blender 4.1\blender.exe",
    "C:\Program Files\Blender Foundation\Blender 4.0\blender.exe",
    "C:\Program Files\Blender Foundation\Blender 3.6\blender.exe",
    "C:\Program Files\Blender Foundation\Blender 3.5\blender.exe"
)

$blenderExe = $blenderCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $blenderExe) {
    # Try PATH
    $fromPath = Get-Command blender -ErrorAction SilentlyContinue
    if ($fromPath) { $blenderExe = $fromPath.Source }
}

if (-not $blenderExe) {
    Write-Host ""
    Write-Host "ERROR: Blender not found." -ForegroundColor Red
    Write-Host "Download free from: https://www.blender.org/download/" -ForegroundColor Yellow
    Write-Host "Then re-run this script." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Blender  : $blenderExe" -ForegroundColor Cyan
Write-Host "Input    : $InputVRML"  -ForegroundColor Cyan
Write-Host "Output   : $outputPath" -ForegroundColor Cyan
Write-Host ""

# ── Validate input ───────────────────────────────────────────────────────────
if (-not (Test-Path $InputVRML)) {
    Write-Host "ERROR: Input VRML not found: $InputVRML" -ForegroundColor Red
    Write-Host "Pass the correct path with -InputVRML" -ForegroundColor Yellow
    exit 1
}

# ── Ensure output directory exists ───────────────────────────────────────────
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

# ── Run Blender conversion ───────────────────────────────────────────────────
$kicadModels = "$env:LOCALAPPDATA\Programs\KiCad\9.0\share\kicad\3dmodels"
Write-Host "Running Blender conversion (this may take 30-60 seconds)..." -ForegroundColor Yellow

$env:KICAD9_3DMODEL_DIR = $kicadModels
& $blenderExe --background --python $pythonScript -- $InputVRML $outputPath

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: Blender exited with code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}

# ── Confirm output ───────────────────────────────────────────────────────────
if (Test-Path $outputPath) {
    $sizeMB = [math]::Round((Get-Item $outputPath).Length / 1MB, 1)
    Write-Host ""
    Write-Host "SUCCESS: $OutputName written to assets/projects/ ($sizeMB MB)" -ForegroundColor Green
    Write-Host "Refresh your browser to see the updated model." -ForegroundColor Green
} else {
    Write-Host "ERROR: Output file was not created. Check Blender output above." -ForegroundColor Red
    exit 1
}
