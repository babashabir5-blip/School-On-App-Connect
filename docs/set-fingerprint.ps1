# =====================================================================
#  Extracts a signing certificate's SHA-256 fingerprint and writes it
#  into site/.well-known/assetlinks.json.
#
#  Usage:
#     # from the debug keystore (default after any debug build)
#     pwsh -File .\docs\set-fingerprint.ps1 -Debug
#
#     # from the release keystore
#     pwsh -File .\docs\set-fingerprint.ps1 `
#          -Keystore C:\Users\user\schoolonapp-connect\keys\schoolonapp-connect.jks `
#          -Alias schoolonapp
#
#     # from an already built APK (reads the signature, no keystore needed)
#     pwsh -File .\docs\set-fingerprint.ps1 -Apk .\android\SchoolOnAppConnect\app\build\outputs\apk\release\app-release.apk
#
#  After running, upload site/.well-known/assetlinks.json to the server at
#  https://schoolonapp.in/.well-known/assetlinks.json
# =====================================================================

param(
    [string]$Keystore,
    [string]$Alias,
    [string]$Apk,
    [switch]$Debug,

    [string]$PackageName = 'in.schoolonapp.connect',
    [string]$Jdk = ''
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$assetlinks = Join-Path $root 'site\.well-known\assetlinks.json'

# --- locate keytool ----------------------------------------------------
if (-not $Jdk) {
    $Jdk = (Get-ChildItem 'C:\Program Files\Eclipse Adoptium' -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like 'jdk-17*' } | Select-Object -First 1).FullName
}
$keytool = if ($Jdk -and (Test-Path (Join-Path $Jdk 'bin\keytool.exe'))) {
    Join-Path $Jdk 'bin\keytool.exe'
} else {
    (Get-Command keytool -ErrorAction SilentlyContinue).Source
}
if (-not $Apk -and -not $keytool) { throw 'keytool not found. Pass -Jdk <path to a JDK>.' }

$fingerprints = @()

if ($Apk) {
    # --- read the signature straight out of the APK -------------------
    if (-not (Test-Path $Apk)) { throw "APK not found: $Apk" }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path $Apk).Path)
    try {
        $entry = $zip.Entries | Where-Object { $_.FullName -match '^META-INF/.*\.(RSA|DSA|EC)$' } | Select-Object -First 1
        if (-not $entry) { throw "No signature block (.RSA/.DSA/.EC) found in $Apk - is it signed?" }
        $ms = New-Object System.IO.MemoryStream
        $entry.Open().CopyTo($ms)
        $ms.Position = 0
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList (, $ms.ToArray())
        $sha = [System.Security.Cryptography.SHA256]::Create().ComputeHash($cert.RawData)
        $fingerprints += (($sha | ForEach-Object { $_.ToString('X2') }) -join ':')
        Write-Host "APK      : $Apk"
        Write-Host "Signed by: $($cert.Subject)"
    }
    finally { $zip.Dispose() }
}
else {
    # --- read from the keystore ---------------------------------------
    if ($Debug) {
        $Keystore = Join-Path $env:USERPROFILE '.android\debug.keystore'
        $Alias = 'androiddebugkey'
        $storePass = 'android'
    } else {
        if (-not $Keystore) { throw 'Pass -Debug, or -Keystore <path> -Alias <alias>.' }
        if (-not $Alias) { throw '-Alias is required with -Keystore.' }
        $secure = Read-Host -AsSecureString "Keystore password for $Keystore"
        $storePass = [System.Net.NetworkCredential]::new('', $secure).Password
    }
    if (-not (Test-Path $Keystore)) { throw "Keystore not found: $Keystore (build the app once so the debug key is created)" }

    $out = & $keytool -list -v -keystore $Keystore -alias $Alias -storepass $storePass 2>&1
    $line = ($out | Select-String -Pattern 'SHA256:\s*([0-9A-Fa-f:]{95,})' | Select-Object -First 1)
    if (-not $line) { throw "Could not read a SHA256 fingerprint. keytool said:`n$($out -join "`n")" }
    $fingerprints += $line.Matches[0].Groups[1].Value.Trim()
}

# --- rewrite assetlinks.json ------------------------------------------
$doc = @(
    [ordered]@{
        relation = @('delegate_permission/common.handle_all_urls')
        target   = [ordered]@{
            namespace                = 'android_app'
            package_name             = $PackageName
            sha256_cert_fingerprints = @($fingerprints)
        }
    }
)
$json = ConvertTo-Json -InputObject $doc -Depth 6
Set-Content -Path $assetlinks -Value $json -Encoding utf8NoBOM

Write-Host ''
Write-Host "Wrote $assetlinks" -ForegroundColor Green
Write-Host "  package       : $PackageName"
foreach ($f in $fingerprints) { Write-Host "  SHA-256       : $f" }

if (-not $Debug) {
    Write-Host ''
    Write-Host 'Next: upload this file to https://schoolonapp.in/.well-known/assetlinks.json'
    Write-Host '      then run: pwsh -File .\docs\verify-site.ps1'
}

# --- round-trip check -------------------------------------------------
try { Get-Content $assetlinks -Raw | ConvertFrom-Json | Out-Null; Write-Host 'JSON re-parsed OK.' -ForegroundColor Green }
catch { throw "Written file is not valid JSON: $($_.Exception.Message)" }
