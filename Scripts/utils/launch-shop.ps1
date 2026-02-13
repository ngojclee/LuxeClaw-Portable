<#
launch-shop.ps1 - Launch a single shop profile
Usage:
  .\launch-shop.ps1 -Shop "AnneNailArt"           # Normal
  .\launch-shop.ps1 -Shop "AnneNailArt" -Kiosk     # Kiosk printing
  .\launch-shop.ps1 -Shop "AnneNailArt" -NoExt      # Without extensions
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Shop,
    [switch]$Kiosk,
    [switch]$NoExt
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = $PSScriptRoot
$portableRoot = Split-Path $scriptDir -Parent
$browserDir = Join-Path $portableRoot "Browser"
$profilesDir = Join-Path $portableRoot "Profiles"

$chromiumExe = Join-Path $browserDir "chrome.exe"
$shopDir = Join-Path $profilesDir $Shop

# ========================================
# Validation
# ========================================
if (-not (Test-Path $chromiumExe)) {
    Write-Host "Chromium chua duoc cai dat! Chay setup.ps1 truoc." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $shopDir)) {
    Write-Host "Profile '$Shop' khong ton tai!" -ForegroundColor Red
    Write-Host "Cac profile co san:" -ForegroundColor Yellow
    Get-ChildItem -Path $profilesDir -Directory | Where-Object { $_.Name -ne "_TEMPLATE" } | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor White
    }
    exit 1
}

# ========================================
# Auto-discover extensions
# ========================================
function Find-ExtensionDir {
    $extensionRoot = Join-Path (Split-Path $portableRoot -Parent) "Chrome"
    if (-not (Test-Path $extensionRoot)) {
        $extensionRoot = "C:\NgocScript\Luxeclaw-Extension\Chrome"
    }
    if (Test-Path $extensionRoot) { return $extensionRoot }
    return $null
}

$extArg = ""
if (-not $NoExt) {
    $extRoot = Find-ExtensionDir
    if ($extRoot) {
        $extPaths = @()
        Get-ChildItem -Path $extRoot -Directory | ForEach-Object {
            $manifest = Join-Path $_.FullName "manifest.json"
            if (Test-Path $manifest) {
                $extPaths += $_.FullName
            }
        }
        if ($extPaths.Count -gt 0) {
            $joined = ($extPaths -join ",")
            $extArg = " --load-extension=`"$joined`""
        }
    }
}

# ========================================
# Build launch args
# ========================================
$launchArgs = "--user-data-dir=`"$shopDir`" --profile-directory=`"Default`" --no-first-run --no-default-browser-check --disable-search-engine-choice-screen$extArg"

if ($Kiosk) {
    $launchArgs += " --kiosk-printing"
}

# Read startup URL from shops.json
$shopsFile = Join-Path $portableRoot "shops.json"
$startupUrl = "https://www.etsy.com/your/orders/sold/new"
if (Test-Path $shopsFile) {
    $config = Get-Content $shopsFile -Raw | ConvertFrom-Json
    if ($config.defaults.startup_urls -and $config.defaults.startup_urls.Count -gt 0) {
        $startupUrl = ($config.defaults.startup_urls -join " ")
    }
}

$launchArgs += " $startupUrl"

# ========================================
# Launch
# ========================================
$mode = if ($Kiosk) { "KIOSK PRINTING" } else { "NORMAL" }
Write-Host "Launching $Shop ($mode)..." -ForegroundColor Green

Start-Process -FilePath $chromiumExe -ArgumentList $launchArgs
