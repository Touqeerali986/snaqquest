param(
    [string]$ExpectedProjectId = "",
    [string]$ExpectedPackageName = "com.snaqquest.app.snaqquest_frontend"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Parse-EnvFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    $result = @{}
    foreach ($line in Get-Content -Path $Path) {
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }
        if ($trimmed.StartsWith("#")) { continue }

        $split = $trimmed -split "=", 2
        if ($split.Count -ne 2) { continue }

        $key = $split[0].Trim()
        $value = $split[1].Trim()
        $result[$key] = $value
    }

    return $result
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$googleServicesPath = Join-Path $repoRoot "frontend\android\app\google-services.json"
$backendEnvPath = Join-Path $repoRoot "backend\.env"
$googleProjectId = $null

$errors = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

if (-not (Test-Path $googleServicesPath)) {
    $errors.Add("Missing frontend/android/app/google-services.json")
} else {
    $googleConfig = Get-Content -Path $googleServicesPath -Raw | ConvertFrom-Json
    $googleProjectId = $googleConfig.project_info.project_id
    if ([string]::IsNullOrWhiteSpace($googleProjectId)) {
        $errors.Add("google-services.json does not contain project_info.project_id")
    }

    $packageNames = @()
    foreach ($client in $googleConfig.client) {
        if ($client.client_info.android_client_info.package_name) {
            $packageNames += $client.client_info.android_client_info.package_name
        }
    }

    if ($packageNames -notcontains $ExpectedPackageName) {
        $errors.Add("Package name mismatch. Expected $ExpectedPackageName in google-services.json client list")
    }

    if (-not [string]::IsNullOrWhiteSpace($ExpectedProjectId) -and $googleProjectId -ne $ExpectedProjectId) {
        $errors.Add("google-services.json project_id mismatch. Found $googleProjectId expected $ExpectedProjectId")
    }

    $webClientIds = @()
    foreach ($client in $googleConfig.client) {
        foreach ($oauthClient in $client.oauth_client) {
            if ($oauthClient.client_type -eq 3 -and $oauthClient.client_id) {
                $webClientIds += $oauthClient.client_id
            }
        }
    }

    if ($webClientIds.Count -eq 0) {
        $warnings.Add("No web client id found in google-services.json. Ensure GOOGLE_WEB_CLIENT_ID is from Firebase Web OAuth client.")
    } else {
        Write-Host "Detected Firebase Web Client IDs:" -ForegroundColor Cyan
        $webClientIds | Sort-Object -Unique | ForEach-Object { Write-Host " - $_" }
    }
}

if (-not (Test-Path $backendEnvPath)) {
    $errors.Add("Missing backend/.env")
} else {
    $envMap = Parse-EnvFile -Path $backendEnvPath
    foreach ($requiredKey in @("FIREBASE_PROJECT_ID", "FIREBASE_CLIENT_EMAIL", "FIREBASE_PRIVATE_KEY")) {
        if (-not $envMap.ContainsKey($requiredKey) -or [string]::IsNullOrWhiteSpace($envMap[$requiredKey])) {
            $errors.Add("backend/.env missing value for $requiredKey")
        }
    }
    
        foreach ($requiredKey in @("FIREBASE_PROJECT_ID", "FIREBASE_CLIENT_EMAIL", "FIREBASE_PRIVATE_KEY")) {
            if ($envMap.ContainsKey($requiredKey) -and $envMap[$requiredKey].StartsWith("change-me")) {
                $errors.Add("backend/.env contains placeholder value for $requiredKey")
            }
        }

    if ($envMap.ContainsKey("FIREBASE_PRIVATE_KEY") -and -not ($envMap["FIREBASE_PRIVATE_KEY"] -match '\\n')) {
        $warnings.Add("FIREBASE_PRIVATE_KEY should contain escaped \\n separators in one line.")
    }

    if ($googleProjectId -and $envMap.ContainsKey("FIREBASE_PROJECT_ID") -and $envMap["FIREBASE_PROJECT_ID"] -ne $googleProjectId) {
        $errors.Add("FIREBASE_PROJECT_ID in backend/.env does not match google-services.json project_id")
    }
}

if ($warnings.Count -gt 0) {
    Write-Host "Warnings:" -ForegroundColor Yellow
    $warnings | ForEach-Object { Write-Host " - $_" -ForegroundColor Yellow }
}

if ($errors.Count -gt 0) {
    Write-Host "Firebase config verification FAILED:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host "Firebase config verification PASSED." -ForegroundColor Green
Write-Host "Next: run app login with Google once and verify backend /api/v1/auth/google/ success." -ForegroundColor Cyan
