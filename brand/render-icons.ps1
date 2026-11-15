# =====================================================================
#  School On App Connect - icon renderer
#  Renders every icon size needed by the web manifest and the Android app
#  from a single source logo.
#
#  Usage:
#     pwsh -File .\brand\render-icons.ps1
#     pwsh -File .\brand\render-icons.ps1 -Source C:\path\to\real-logo.png
#     pwsh -File .\brand\render-icons.ps1 -Brand "#0F4C81"
#
#  Notes:
#   - If the source image is smaller than 200px (the current one is a
#     124x124 placeholder from the school site), a clean "SOA" letter mark
#     is rendered instead so you do not ship a broken placeholder icon.
#   - Replace brand/source-logo.png with the real logo and re-run.
# =====================================================================

param(
    [string]$Source = (Join-Path $PSScriptRoot 'source-logo.png'),
    [string]$Brand = '#5061AB',
    [string]$Root = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

if (-not (Test-Path $Source)) {
    throw "Source logo not found: $Source"
}

$script:src = [System.Drawing.Image]::FromFile((Resolve-Path $Source).Path)
$script:useLetter = $script:src.Width -lt 200
Write-Host ("Source: {0} ({1}x{2}) -> {3}" -f (Split-Path $Source -Leaf), $script:src.Width, $script:src.Height, $(if ($script:useLetter) { 'letter-mark fallback (source too small)' } else { 'drawing logo' }))

function Save-Icon {
    param(
        [int]$Size,
        [double]$Coverage,
        [bool]$Transparent,
        [string]$Path
    )

    $dir = Split-Path $Path -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }

    $bmp = New-Object System.Drawing.Bitmap -ArgumentList $Size, $Size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

    if ($Transparent) {
        $g.Clear([System.Drawing.Color]::Transparent)
    } else {
        $g.Clear([System.Drawing.ColorTranslator]::FromHtml($Brand))
    }

    if ($script:useLetter) {
        $fontSize = [float]($Size * 0.30)
        $font = New-Object System.Drawing.Font -ArgumentList 'Segoe UI', $fontSize, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
        $fmt = New-Object System.Drawing.StringFormat
        $fmt.Alignment = [System.Drawing.StringAlignment]::Center
        $fmt.LineAlignment = [System.Drawing.StringAlignment]::Center
        $rect = New-Object System.Drawing.RectangleF -ArgumentList 0, 0, ([float]$Size), ([float]$Size)
        $brush = New-Object System.Drawing.SolidBrush -ArgumentList ([System.Drawing.Color]::White)
        $g.DrawString('SOA', $font, $brush, $rect, $fmt)
        $font.Dispose(); $brush.Dispose(); $fmt.Dispose()
    } else {
        $target = $Size * $Coverage
        $scale = [Math]::Min($target / $script:src.Width, $target / $script:src.Height)
        $w = [int]($script:src.Width * $scale)
        $h = [int]($script:src.Height * $scale)
        $x = [int](($Size - $w) / 2)
        $y = [int](($Size - $h) / 2)
        $g.DrawImage($script:src, $x, $y, $w, $h)
    }

    $g.Dispose()
    $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host ("  {0,-62} {1}x{1}" -f $Path.Replace($Root, '.'), $Size)
}

# --- Web manifest icons ------------------------------------------------
$siteIcons = Join-Path $Root 'site\icons'
Save-Icon -Size 192 -Coverage 0.78 -Transparent $false -Path (Join-Path $siteIcons 'icon-192.png')
Save-Icon -Size 512 -Coverage 0.78 -Transparent $false -Path (Join-Path $siteIcons 'icon-512.png')
Save-Icon -Size 512 -Coverage 0.58 -Transparent $false -Path (Join-Path $siteIcons 'icon-maskable-512.png')

# --- Android launcher icons -------------------------------------------
$res = Join-Path $Root 'android\SchoolOnAppConnect\app\src\main\res'
$legacy = [ordered]@{ 'mdpi' = 48; 'hdpi' = 72; 'xhdpi' = 96; 'xxhdpi' = 144; 'xxxhdpi' = 192 }
foreach ($density in $legacy.Keys) {
    Save-Icon -Size $legacy[$density] -Coverage 0.80 -Transparent $false -Path (Join-Path $res "mipmap-$density\ic_launcher.png")
    Save-Icon -Size $legacy[$density] -Coverage 0.80 -Transparent $false -Path (Join-Path $res "mipmap-$density\ic_launcher_round.png")
}

# --- Adaptive icon foreground (108dp grid, logo inside the 66dp safe zone)
$foreground = [ordered]@{ 'mdpi' = 108; 'hdpi' = 162; 'xhdpi' = 216; 'xxhdpi' = 324; 'xxxhdpi' = 432 }
foreach ($density in $foreground.Keys) {
    Save-Icon -Size $foreground[$density] -Coverage 0.58 -Transparent $true -Path (Join-Path $res "mipmap-$density\ic_launcher_foreground.png")
}

# --- Splash + store listing -------------------------------------------
Save-Icon -Size 512 -Coverage 0.72 -Transparent $true -Path (Join-Path $res 'drawable-nodpi\splash_logo.png')
Save-Icon -Size 1024 -Coverage 0.80 -Transparent $false -Path (Join-Path $Root 'brand\icon-1024.png')

$script:src.Dispose()
Write-Host ''
Write-Host 'Done. Icons written for site + Android.'
