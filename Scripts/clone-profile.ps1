<#
clone-profile.ps1 - Clone _TEMPLATE to all shops in shops.json
Creates desktop shortcuts for each shop (normal + kiosk printing)
#>

param(
    [string[]]$Only,           # Clone specific shops only
    [switch]$Force              # Overwrite existing profiles
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = $PSScriptRoot
$portableRoot = Split-Path $scriptDir -Parent
$browserDir = Join-Path $portableRoot "Browser"
$profilesDir = Join-Path $portableRoot "Profiles"
$templateDir = Join-Path $profilesDir "_TEMPLATE"
$shopsFile = Join-Path $portableRoot "shops.json"

$chromiumExe = Join-Path $browserDir "chrome.exe"

# ========================================
# Validation
# ========================================
if (-not (Test-Path $chromiumExe)) {
    Write-Host "Chromium chua duoc cai dat! Chay setup.ps1 truoc." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path (Join-Path $templateDir "Default\Preferences"))) {
    Write-Host "_TEMPLATE chua duoc tao! Chay setup.ps1 truoc." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $shopsFile)) {
    Write-Host "shops.json khong tim thay! Tao file truoc." -ForegroundColor Red
    exit 1
}

# ========================================
# Read config
# ========================================
$config = Get-Content $shopsFile -Raw | ConvertFrom-Json
$shops = @($config.shops)

if ($Only -and $Only.Count -gt 0) {
    $shops = $shops | Where-Object { $Only -contains $_.name }
}

if ($shops.Count -eq 0) {
    Write-Host "Khong co shop nao de clone." -ForegroundColor Yellow
    exit 0
}

# ========================================
# Find extensions for shortcuts
# ========================================
function Find-ExtensionDir {
    $extensionRoot = Join-Path (Split-Path $portableRoot -Parent) "Chrome"
    if (-not (Test-Path $extensionRoot)) {
        $extensionRoot = "C:\NgocScript\Luxeclaw-Extension\Chrome"
    }
    if (Test-Path $extensionRoot) { return $extensionRoot }
    return $null
}

function Get-ExtensionPaths {
    param([string]$ExtRoot)
    $paths = @()
    if (-not $ExtRoot -or -not (Test-Path $ExtRoot)) { return $paths }
    
    Get-ChildItem -Path $ExtRoot -Directory | ForEach-Object {
        $manifest = Join-Path $_.FullName "manifest.json"
        if (Test-Path $manifest) {
            $paths += $_.FullName
        }
    }
    return $paths
}

$extRoot = Find-ExtensionDir
$extPaths = Get-ExtensionPaths -ExtRoot $extRoot

$localArg = ""
if ($extPaths.Count -gt 0) {
    $joined = ($extPaths -join ",")
    $localArg = " --load-extension=`"$joined`""
}

# ========================================
# Clone profiles
# ========================================
$desktop = [Environment]::GetFolderPath("Desktop")
$created = 0
$skipped = 0

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Cloning profiles from _TEMPLATE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

foreach ($shop in $shops) {
    $shopName = $shop.name
    $shopDir = Join-Path $profilesDir $shopName

    if ((Test-Path $shopDir) -and -not $Force) {
        Write-Host "  [SKIP] $shopName (da ton tai, dung -Force de ghi de)" -ForegroundColor Yellow
        $skipped++
        continue
    }

    # Clone TEMPLATE
    Write-Host "  [CLONE] $shopName..." -ForegroundColor Green
    
    if ($Force -and (Test-Path $shopDir)) {
        Remove-Item $shopDir -Recurse -Force
    }
    
    Copy-Item -Path $templateDir -Destination $shopDir -Recurse -Force

    # Clean unique/sensitive files
    $defaultDir = Join-Path $shopDir "Default"
    $toCleanup = @(
        "Cookies", "Cookies-journal",
        "History", "History-journal",
        "Login Data", "Login Data-journal",
        "Web Data", "Web Data-journal",
        "Secure Preferences",
        "Network Action Predictor", "Network Action Predictor-journal",
        "Visited Links", "Top Sites", "Top Sites-journal",
        "Shortcuts", "Shortcuts-journal"
    )
    
    foreach ($file in $toCleanup) {
        $filePath = Join-Path $defaultDir $file
        if (Test-Path $filePath) { Remove-Item $filePath -Force }
        
        # Also check Network subfolder (newer Chrome versions)
        $netPath = Join-Path $defaultDir "Network\$file"
        if (Test-Path $netPath) { Remove-Item $netPath -Force }
    }

    # Clean cache directories
    $cacheDirs = @("Cache", "Code Cache", "GPUCache", "Service Worker", "blob_storage")
    foreach ($dir in $cacheDirs) {
        $dirPath = Join-Path $defaultDir $dir
        if (Test-Path $dirPath) { Remove-Item $dirPath -Recurse -Force }
    }
    
    # Ensure First Run marker
    New-Item -ItemType File -Force -Path (Join-Path $shopDir "First Run") | Out-Null

    # Create desktop shortcuts
    $commonArgs = "--user-data-dir=`"$shopDir`" --profile-directory=`"Default`" --no-first-run --no-default-browser-check --disable-search-engine-choice-screen"
    
    # Normal shortcut
    $lnkNormal = Join-Path $desktop "$shopName.lnk"
    if (Test-Path $lnkNormal) { Remove-Item $lnkNormal -Force }
    
    $wsh = New-Object -ComObject WScript.Shell
    $sc = $wsh.CreateShortcut($lnkNormal)
    $sc.TargetPath = $chromiumExe
    $sc.Arguments = "$commonArgs$localArg"
    $sc.WorkingDirectory = $browserDir
    $sc.IconLocation = "$chromiumExe,0"
    $sc.Save()

    # Kiosk printing shortcut
    $lnkPrint = Join-Path $desktop "$shopName-print.lnk"
    if (Test-Path $lnkPrint) { Remove-Item $lnkPrint -Force }
    
    $sc2 = $wsh.CreateShortcut($lnkPrint)
    $sc2.TargetPath = $chromiumExe
    $sc2.Arguments = "$commonArgs$localArg --kiosk-printing"
    $sc2.WorkingDirectory = $browserDir
    $sc2.IconLocation = "$chromiumExe,0"
    $sc2.Save()

    $created++
    Write-Host "    > Shortcuts: $shopName.lnk + $shopName-print.lnk" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " Clone hoan tat!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Created: $created | Skipped: $skipped" -ForegroundColor White
Write-Host ""
Write-Host "Buoc tiep:" -ForegroundColor Cyan
Write-Host "  - Dang nhap Etsy cho tung shop" -ForegroundColor White
Write-Host "  - Hoac inject cookies tu Cookie Profiles (EtsyAutomation extension)" -ForegroundColor White
Write-Host "  - Chay: .\Scripts\launch-shop.ps1 -Shop `"ShopName`"" -ForegroundColor White
Write-Host "  - Hoac: .\Scripts\launch-all.ps1" -ForegroundColor White
