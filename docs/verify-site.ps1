# =====================================================================
#  Verifies the live PWA / TWA files on schoolonapp.in
#  Usage:  pwsh -File .\docs\verify-site.ps1
#          pwsh -File .\docs\verify-site.ps1 -BaseUrl https://staging.schoolonapp.in
# =====================================================================

param(
    [string]$BaseUrl = 'https://schoolonapp.in'
)

$ErrorActionPreference = 'Continue'
$script:fail = 0
$script:warn = 0

function Get-Probe {
    param([string]$Url)
    $raw = curl.exe -sS -L --max-time 25 -o "$env:TEMP\probe.bin" -w "%{http_code}|%{content_type}|%{url_effective}" $Url 2>$null
    $parts = $raw -split '\|'
    return [pscustomobject]@{
        Url         = $Url
        Status      = $parts[0]
        ContentType = if ($parts.Count -gt 1) { $parts[1] } else { '' }
        FinalUrl    = if ($parts.Count -gt 2) { $parts[2] } else { '' }
        Body        = if (Test-Path "$env:TEMP\probe.bin") { Get-Content "$env:TEMP\probe.bin" -Raw } else { '' }
    }
}

function Report {
    param([string]$Name, [bool]$Ok, [string]$Detail, [bool]$IsWarning = $false)
    if ($Ok) {
        Write-Host ("  PASS  {0,-34} {1}" -f $Name, $Detail) -ForegroundColor Green
    } elseif ($IsWarning) {
        $script:warn++
        Write-Host ("  WARN  {0,-34} {1}" -f $Name, $Detail) -ForegroundColor Yellow
    } else {
        $script:fail++
        Write-Host ("  FAIL  {0,-34} {1}" -f $Name, $Detail) -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Checking $BaseUrl" -ForegroundColor Cyan
Write-Host ("-" * 72)

# --- manifest ---------------------------------------------------------
$r = Get-Probe "$BaseUrl/manifest.json"
$isJson = $r.ContentType -match 'json'
$jsonOk = $false
$manifest = $null
if ($isJson) {
    try { $manifest = $r.Body | ConvertFrom-Json; $jsonOk = $true } catch { $jsonOk = $false }
}
Report 'manifest.json status' ($r.Status -eq '200') "HTTP $($r.Status) ($($r.ContentType))"
Report 'manifest.json not redirected' ($r.FinalUrl -eq "$BaseUrl/manifest.json") "$($r.FinalUrl)"
Report 'manifest.json is JSON' $jsonOk $(if ($jsonOk) { 'parsed' } else { 'not valid JSON' })
if ($jsonOk) {
    Report 'manifest name' ([bool]$manifest.name) $(if ($manifest.name) { $manifest.name } else { 'missing' })
    Report 'manifest start_url' ($manifest.start_url -eq '/') "$($manifest.start_url)"
    Report 'manifest display' ($manifest.display -eq 'standalone') "$($manifest.display)"
    $sizes = @($manifest.icons | ForEach-Object { $_.sizes })
    Report 'manifest 192 icon' ($sizes -contains '192x192') ($sizes -join ', ')
    Report 'manifest 512 icon' ($sizes -contains '512x512') ($sizes -join ', ')
    Report 'manifest maskable' ([bool](@($manifest.icons | Where-Object { $_.purpose -eq 'maskable' }).Count)) 'maskable icon present'
}

# --- service worker ---------------------------------------------------
$r = Get-Probe "$BaseUrl/sw.js"
$isJs = $r.ContentType -match 'javascript|ecmascript'
Report 'sw.js status' ($r.Status -eq '200') "HTTP $($r.Status) ($($r.ContentType))"
Report 'sw.js is JavaScript' $isJs $(if ($isJs) { 'ok' } else { "content-type $($r.ContentType)" })
Report 'sw.js has fetch handler' ($r.Body -match 'addEventListener\(.fetch.') $(if ($r.Body -match 'addEventListener\(.fetch.') { 'ok' } else { 'not found' })
Report 'sw.js no accidental redirect' ($r.FinalUrl -eq "$BaseUrl/sw.js") "$($r.FinalUrl)"

# --- offline page -----------------------------------------------------
$r = Get-Probe "$BaseUrl/offline.html"
Report 'offline.html status' ($r.Status -eq '200') "HTTP $($r.Status) ($($r.ContentType))"
Report 'offline.html not redirected' ($r.FinalUrl -eq "$BaseUrl/offline.html") "$($r.FinalUrl)"

# --- icons ------------------------------------------------------------
foreach ($icon in 'icon-192.png', 'icon-512.png', 'icon-maskable-512.png') {
    $r = Get-Probe "$BaseUrl/icons/$icon"
    Report "icons/$icon" ($r.Status -eq '200' -and $r.ContentType -match 'image/png') "HTTP $($r.Status) ($($r.ContentType))"
}

# --- asset links ------------------------------------------------------
$r = Get-Probe "$BaseUrl/.well-known/assetlinks.json"
Report 'assetlinks status' ($r.Status -eq '200') "HTTP $($r.Status) ($($r.ContentType))"
Report 'assetlinks not redirected' ($r.FinalUrl -eq "$BaseUrl/.well-known/assetlinks.json") "$($r.FinalUrl)"
Report 'assetlinks is JSON' ($r.ContentType -match 'json') "$($r.ContentType)"
if ($r.ContentType -match 'json') {
    $al = $null
    try { $al = $r.Body | ConvertFrom-Json } catch { }
    if ($al) {
        $target = @($al)[0].target
        Report 'assetlinks package' ($target.package_name -eq 'in.schoolonapp.connect') "$($target.package_name)"
        $fps = @($target.sha256_cert_fingerprints)
        $real = @($fps | Where-Object { $_ -match '^([0-9A-F]{2}:){31}[0-9A-F]{2}$' })
        Report 'assetlinks SHA-256' ($real.Count -gt 0) $(if ($real.Count -gt 0) { "$($real.Count) fingerprint(s)" } else { 'placeholder or invalid' })
    } else {
        Report 'assetlinks parses' $false 'invalid JSON'
    }
}

Write-Host ("-" * 72)
if ($script:fail -eq 0) {
    Write-Host "ALL CHECKS PASSED" -ForegroundColor Green
    if ($script:warn -gt 0) { Write-Host "$($script:warn) warning(s)" -ForegroundColor Yellow }
    exit 0
} else {
    Write-Host "$($script:fail) check(s) failed" -ForegroundColor Red
    exit 1
}
