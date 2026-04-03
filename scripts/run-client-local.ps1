param(
    [string]$DeviceId = "130183749P000298",
    [string]$HostIp = "192.168.100.13",
    [string]$GoogleWebClientId = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$backendPath = Join-Path $repoRoot "backend"
$frontendPath = Join-Path $repoRoot "frontend"
$venvPython = Join-Path $backendPath ".venv\Scripts\python.exe"

if ([string]::IsNullOrWhiteSpace($HostIp)) {
    throw "HostIp cannot be empty. Pass -HostIp with your machine LAN IP, for example 192.168.100.13"
}

$apiBaseUrl = "http://$HostIp`:8000/api/v1"
try {
    $apiBaseUri = [uri]$apiBaseUrl
} catch {
    throw "Invalid HostIp value '$HostIp'. Could not build a valid API URL."
}

if ([string]::IsNullOrWhiteSpace($apiBaseUri.Host)) {
    throw "Invalid HostIp value '$HostIp'. API URL host is empty."
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter command not found. Install Flutter first."
}

if (-not (Test-Path $venvPython)) {
    Push-Location $backendPath
    python -m venv .venv
    Pop-Location
}

$backendCmd = @"
Set-Location '$backendPath'
& '$venvPython' -m pip install -r requirements.txt
& '$venvPython' manage.py migrate
& '$venvPython' manage.py runserver 0.0.0.0:8000
"@

$frontendCmd = @"
Set-Location '$frontendPath'
flutter pub get
flutter run -d $DeviceId --dart-define=API_BASE_URL=$apiBaseUrl --dart-define=GOOGLE_WEB_CLIENT_ID=$GoogleWebClientId
"@

Start-Process powershell -ArgumentList "-NoExit", "-Command", $backendCmd
Start-Process powershell -ArgumentList "-NoExit", "-Command", $frontendCmd

Write-Host "Started backend and frontend in separate terminals." -ForegroundColor Green
Write-Host "Backend URL: $($apiBaseUri.Scheme)://$($apiBaseUri.Host):$($apiBaseUri.Port)" -ForegroundColor Cyan
Write-Host "Frontend API base: $apiBaseUrl" -ForegroundColor Cyan
