param(
    [Parameter(Mandatory = $true)]
    [string]$ApiBaseUrl,

    [string]$GoogleWebClientId = "",

    [switch]$SkipAndroidBuild,
    [switch]$SkipTests
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-Command {
    param([Parameter(Mandatory = $true)][string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command not found: $Name"
    }
}

function Set-Or-ReplaceEnvKey {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)][string]$Value
    )

    $content = Get-Content -Path $Path -Raw
    if ($content -match "(?m)^$Key=") {
        $content = [Regex]::Replace($content, "(?m)^$Key=.*$", "$Key=$Value")
    } else {
        $content = $content.TrimEnd() + "`r`n$Key=$Value`r`n"
    }
    Set-Content -Path $Path -Value $content -Encoding UTF8
}

function New-RandomSecret {
    $bytes = New-Object byte[] 48
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::Create()
    $rng.GetBytes($bytes)
    $rng.Dispose()
    return [Convert]::ToBase64String($bytes)
}

function Assert-AndroidNdkReady {
    $sdkRoot = $env:ANDROID_SDK_ROOT
    if ([string]::IsNullOrWhiteSpace($sdkRoot)) {
        $sdkRoot = Join-Path $env:LOCALAPPDATA "Android\sdk"
    }

    $ndkRoot = Join-Path $sdkRoot "ndk"
    if (-not (Test-Path $ndkRoot)) {
        throw "Android NDK folder not found at $ndkRoot. Install NDK from Android Studio SDK Manager."
    }

    $validNdk = Get-ChildItem -Path $ndkRoot -Directory | Where-Object {
        Test-Path (Join-Path $_.FullName "source.properties")
    } | Select-Object -First 1

    if (-not $validNdk) {
        throw "No valid NDK installation found in $ndkRoot (missing source.properties). Reinstall NDK from Android Studio."
    }
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$backendPath = Join-Path $repoRoot "backend"
$frontendPath = Join-Path $repoRoot "frontend"
$backendEnv = Join-Path $backendPath ".env"
$backendEnvExample = Join-Path $backendPath ".env.example"
$venvPython = Join-Path $backendPath ".venv\Scripts\python.exe"

Write-Host "== SnaqQuest One-Command Deploy Start ==" -ForegroundColor Cyan

Assert-Command -Name "python"
Assert-Command -Name "flutter"

if (-not (Test-Path $backendEnv)) {
    Copy-Item -Path $backendEnvExample -Destination $backendEnv
    Write-Host "Created backend/.env from .env.example" -ForegroundColor Yellow
    Write-Host "IMPORTANT: Fill Firebase + production values in backend/.env" -ForegroundColor Yellow
}

$dotenvContent = Get-Content -Path $backendEnv -Raw
if ($dotenvContent -match "(?m)^DJANGO_SECRET_KEY=(.*)$") {
    $currentSecret = $Matches[1].Trim()
    if ([string]::IsNullOrWhiteSpace($currentSecret) -or $currentSecret.StartsWith("change-me") -or $currentSecret.Length -lt 32) {
        $newSecret = New-RandomSecret
        Set-Or-ReplaceEnvKey -Path $backendEnv -Key "DJANGO_SECRET_KEY" -Value $newSecret
        Write-Host "Generated secure DJANGO_SECRET_KEY in backend/.env" -ForegroundColor Yellow
    }
}

if (-not (Test-Path $venvPython)) {
    Write-Host "Creating backend virtual environment..." -ForegroundColor Cyan
    Push-Location $backendPath
    python -m venv .venv
    Pop-Location
}

Write-Host "Installing backend dependencies..." -ForegroundColor Cyan
& $venvPython -m pip install --upgrade pip
& $venvPython -m pip install -r (Join-Path $backendPath "requirements.txt")

Push-Location $backendPath
Write-Host "Running backend migrations and checks..." -ForegroundColor Cyan
& $venvPython manage.py migrate
& $venvPython manage.py collectstatic --noinput
& $venvPython manage.py check
if (-not $SkipTests) {
    & $venvPython manage.py test
}
Pop-Location

Push-Location $frontendPath
Write-Host "Installing frontend dependencies and validating app..." -ForegroundColor Cyan
flutter pub get
flutter analyze
if (-not $SkipTests) {
    flutter test
}

if (-not $SkipAndroidBuild) {
    Assert-AndroidNdkReady
    Write-Host "Building release APK..." -ForegroundColor Cyan
    $buildArgs = @(
        "build", "apk", "--release",
        "--dart-define=API_BASE_URL=$ApiBaseUrl"
    )

    if (-not [string]::IsNullOrWhiteSpace($GoogleWebClientId)) {
        $buildArgs += "--dart-define=GOOGLE_WEB_CLIENT_ID=$GoogleWebClientId"
    }

    flutter @buildArgs
    Write-Host "APK ready at frontend/build/app/outputs/flutter-apk/app-release.apk" -ForegroundColor Green
} else {
    Write-Host "Android build skipped by flag." -ForegroundColor Yellow
}
Pop-Location

Write-Host "== One-command deploy complete ==" -ForegroundColor Green
Write-Host "Next: start backend with backend/.venv/Scripts/python.exe backend/manage.py runserver" -ForegroundColor Cyan
