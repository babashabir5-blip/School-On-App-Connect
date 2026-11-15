# =====================================================================
#  Builds the School On App Connect APK from the command line.
#  No Android Studio required.
#
#  Usage:
#     pwsh -File .\android\build.ps1
#     pwsh -File .\android\build.ps1 -Variant release
#     pwsh -File .\android\build.ps1 -Variant release -Keystore C:\path\app.jks -Alias schoolonapp
#
#  Requirements (already installed on this machine):
#     - JDK 17          C:\Program Files\Eclipse Adoptium\jdk-17*
#     - Android SDK     C:\Users\user\Android\Sdk  (platform 36, build-tools 36.0.0)
#     - Gradle 8.13     C:\Users\user\tools\gradle-8.13  (only needed once, to create the wrapper)
# =====================================================================

param(
    [ValidateSet('debug', 'release')]
    [string]$Variant = 'debug',

    [string]$Keystore,
    [string]$Alias,
    [string]$StorePassword,
    [string]$KeyPassword,

    [string]$Jdk = '',
    [string]$Sdk = 'C:\Users\user\Android\Sdk'
)

$ErrorActionPreference = 'Stop'

# --- locate JDK 17 -----------------------------------------------------
if (-not $Jdk) {
    $Jdk = (Get-ChildItem 'C:\Program Files\Eclipse Adoptium' -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like 'jdk-17*' } | Select-Object -First 1).FullName
}
if (-not $Jdk -or -not (Test-Path $Jdk)) {
    throw 'JDK 17 not found. Install Eclipse Temurin 17 or pass -Jdk <path>.'
}

if (-not (Test-Path $Sdk)) {
    throw "Android SDK not found at $Sdk. Pass -Sdk <path>."
}

$env:JAVA_HOME = $Jdk
$env:ANDROID_HOME = $Sdk
$env:ANDROID_SDK_ROOT = $Sdk
$env:PATH = "$Jdk\bin;$env:PATH"

$proj = Join-Path $PSScriptRoot 'SchoolOnAppConnect'
Set-Content -Path (Join-Path $proj 'local.properties') -Value "sdk.dir=$($Sdk -replace '\\', '\\' -replace ':', '\:')" -Encoding ascii

Write-Host "JDK : $Jdk"
Write-Host "SDK : $Sdk"
Write-Host "Build: $Variant"
Write-Host ''

Push-Location $proj
try {
    # Create the Gradle wrapper once, if it is missing.
    if (-not (Test-Path '.\gradlew.bat')) {
        $gradle = 'C:\Users\user\tools\gradle-8.13\bin\gradle.bat'
        if (-not (Test-Path $gradle)) {
            throw 'gradlew is missing and Gradle 8.13 was not found at C:\Users\user\tools\gradle-8.13.'
        }
        Write-Host 'Generating Gradle wrapper...'
        & $gradle wrapper --gradle-version 8.13 --console=plain --no-daemon
    }

    if ($Variant -eq 'debug') {
        & .\gradlew.bat assembleDebug --console=plain
    } else {
        if ($Keystore) {
            if (-not $Alias) { throw '-Alias is required with -Keystore.' }
            if (-not $StorePassword) { $StorePassword = Read-Host -AsSecureString 'Keystore password' | ConvertFrom-SecureString -AsPlainText }
            if (-not $KeyPassword) { $KeyPassword = $StorePassword }
            & .\gradlew.bat assembleRelease --console=plain `
                "-Pandroid.injected.signing.store.file=$Keystore" `
                "-Pandroid.injected.signing.store.password=$StorePassword" `
                "-Pandroid.injected.signing.key.alias=$Alias" `
                "-Pandroid.injected.signing.key.password=$KeyPassword"
        } else {
            Write-Host 'No -Keystore given: building an UNSIGNED release APK.' -ForegroundColor Yellow
            & .\gradlew.bat assembleRelease --console=plain
        }
    }

    if ($LASTEXITCODE -ne 0) { throw "Gradle failed with exit code $LASTEXITCODE." }
}
finally {
    Pop-Location
}

$out = Join-Path $proj "app\build\outputs\apk\$Variant"
Write-Host ''
Get-ChildItem $out -Filter *.apk -ErrorAction SilentlyContinue |
    Select-Object FullName, @{n = 'MB'; e = { [math]::Round($_.Length / 1MB, 2) } }, LastWriteTime |
    Format-Table -AutoSize
