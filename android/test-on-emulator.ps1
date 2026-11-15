# =====================================================================
#  Installs the built APK on a running emulator or USB device, launches
#  it, and saves a screenshot. Use this to verify the TWA without
#  touching a real phone.
#
#  Usage:
#     # install the debug APK on whatever device/emulator is connected
#     pwsh -File .\android\test-on-emulator.ps1
#
#     # a specific APK and output image
#     pwsh -File .\android\test-on-emulator.ps1 `
#          -Apk .\dist\SchoolOnAppConnect-debug.apk `
#          -Screenshot C:\Users\user\Desktop\app-shot.png
#
#  Requires: platform-tools (adb) in the Android SDK.
# =====================================================================

param(
    [string]$Apk = (Join-Path (Split-Path $PSScriptRoot -Parent) 'dist\SchoolOnAppConnect-debug.apk'),
    [string]$Screenshot = '',
    [string]$Sdk = '',
    [int]$BootTimeoutSeconds = 240
)

$ErrorActionPreference = 'Stop'
$Package = 'in.schoolonapp.connect'
$Activity = 'in.schoolonapp.connect.LauncherActivity'

if (-not $Sdk) {
    foreach ($candidate in "$env:LOCALAPPDATA\Android\Sdk", 'C:\Users\user\Android\Sdk') {
        if (Test-Path (Join-Path $candidate 'platform-tools\adb.exe')) { $Sdk = $candidate; break }
    }
}
if (-not $Sdk) { throw 'Android SDK not found. Pass -Sdk <path>.' }

$adb = Join-Path $Sdk 'platform-tools\adb.exe'
if (-not (Test-Path $Apk)) {
    throw "APK not found: $Apk`nBuild it first:  pwsh -File .\android\build.ps1"
}

& $adb start-server 2>&1 | Out-Null

# --- wait for a device to be ready ------------------------------------
$deadline = (Get-Date).AddSeconds($BootTimeoutSeconds)
$serial = $null
while ((Get-Date) -lt $deadline) {
    $devices = (& $adb devices) 2>&1 | Select-String -Pattern '^(emulator-\d+|\S+)\s+device$'
    if ($devices) { $serial = ($devices[-1].Line -split '\s+')[0]; break }
    Start-Sleep -Seconds 3
}
if (-not $serial) {
    throw "No device/emulator online after $BootTimeoutSeconds s. Start one with:`n  $Sdk\emulator\emulator.exe -avd <name>`nList AVDs:  $Sdk\emulator\emulator.exe -list-avds"
}

Write-Host "Device : $serial"
Write-Host "Android: $((& $adb -s $serial shell getprop ro.build.version.release).Trim()) (API $((& $adb -s $serial shell getprop ro.build.version.sdk).Trim()))"

# --- wait for boot ----------------------------------------------------
while ((Get-Date) -lt $deadline) {
    $booted = ((& $adb -s $serial shell getprop sys.boot_completed 2>&1) -join '').Trim()
    if ($booted -eq '1') { break }
    Start-Sleep -Seconds 3
}
Write-Host 'Booted.'

# A Trusted Web Activity needs Chrome (or a Chromium browser) on the device.
$hasChrome = (& $adb -s $serial shell pm list packages 2>&1) -match 'com\.android\.chrome'
Write-Host ('Chrome : ' + $(if ($hasChrome) { 'present' } else { 'MISSING - the TWA will fall back to a Custom Tab with a URL bar' }))

# --- install ----------------------------------------------------------
Write-Host 'Installing...'
& $adb -s $serial install -r -t $Apk 2>&1 | ForEach-Object { "  $_" }

# --- launch -----------------------------------------------------------
& $adb -s $serial logcat -c 2>&1 | Out-Null
& $adb -s $serial shell am start -n "$Package/$Activity" 2>&1 | ForEach-Object { "  $_" }
Start-Sleep -Seconds 8

Write-Host ''
Write-Host '--- recent app log ---'
& $adb -s $serial logcat -d -t 40 2>&1 |
    Select-String -Pattern 'schoolonapp|AndroidRuntime|FATAL|TrustedWebActivity|CustomTab' |
    ForEach-Object { $_.Line }

# --- screenshot -------------------------------------------------------
if (-not $Screenshot) {
    $Screenshot = Join-Path $env:TEMP 'opencode\schoolonapp-emulator.png'
}
New-Item -ItemType Directory -Force -Path (Split-Path $Screenshot) | Out-Null
& $adb -s $serial exec-out screencap -p > $Screenshot
Write-Host ''
Write-Host "Screenshot: $Screenshot" -ForegroundColor Green
