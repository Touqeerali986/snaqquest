param(
    [Parameter(Mandatory = $true)]
    [string]$StorePassword,

    [Parameter(Mandatory = $true)]
    [string]$KeyPassword,

    [string]$KeyAlias = "snaqquest_upload",
    [string]$KeystoreFileName = "upload-keystore.jks",
    [int]$ValidityDays = 10000,
    [string]$DistinguishedName = "CN=SnaqQuest, OU=Mobile, O=SnaqQuest, L=City, S=State, C=US"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Get-Command keytool -ErrorAction SilentlyContinue)) {
    throw "keytool not found. Install JDK and ensure keytool is available in PATH."
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$androidPath = Join-Path $repoRoot "frontend\android"
$keystorePath = Join-Path $androidPath $KeystoreFileName
$keyPropertiesPath = Join-Path $androidPath "key.properties"

if (Test-Path $keystorePath) {
    throw "Keystore already exists at $keystorePath. Remove it first if you want to regenerate."
}

Write-Host "Generating Android upload keystore..." -ForegroundColor Cyan
& keytool -genkeypair -v `
    -keystore "$keystorePath" `
    -keyalg RSA `
    -keysize 2048 `
    -validity $ValidityDays `
    -alias "$KeyAlias" `
    -storepass "$StorePassword" `
    -keypass "$KeyPassword" `
    -dname "$DistinguishedName"

$keyProperties = @"
storePassword=$StorePassword
keyPassword=$KeyPassword
keyAlias=$KeyAlias
storeFile=$KeystoreFileName
"@

Set-Content -Path $keyPropertiesPath -Value $keyProperties -Encoding UTF8

Write-Host "Signing setup complete." -ForegroundColor Green
Write-Host "Created: frontend/android/$KeystoreFileName" -ForegroundColor Green
Write-Host "Created: frontend/android/key.properties" -ForegroundColor Green
Write-Host "Keep both files private and backed up securely." -ForegroundColor Yellow
