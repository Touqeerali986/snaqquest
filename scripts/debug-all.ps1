Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$backendPath = Join-Path $repoRoot "backend"
$frontendPath = Join-Path $repoRoot "frontend"
$venvPython = Join-Path $backendPath ".venv\Scripts\python.exe"

if (-not (Test-Path $venvPython)) {
    Push-Location $backendPath
    python -m venv .venv
    Pop-Location
}

Write-Host "[1/2] Debug backend checks/tests" -ForegroundColor Cyan
Push-Location $backendPath
& $venvPython -m pip install -r requirements.txt
& $venvPython manage.py check
& $venvPython manage.py migrate
& $venvPython manage.py test
Pop-Location

Write-Host "[2/2] Debug frontend checks/tests" -ForegroundColor Cyan
Push-Location $frontendPath
flutter pub get
flutter analyze
flutter test
Pop-Location

Write-Host "Debug completed: backend and frontend checks are green." -ForegroundColor Green
