<#
setup.ps1 - One-time setup for Portable Chromium
1. Download ungoogled-chromium portable (if not present)
2. Create _TEMPLATE profile with Preferences
3. Launch _TEMPLATE so user can install FoxyProxy + configure
4. User closes browser -> _TEMPLATE ready for cloning
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = $PSScriptRoot
$portableRoot = Split-Path $scriptDir -Parent
$browserDir = Join-Path $portableRoot "Browser"
$profilesDir = Join-Path $portableRoot "Profiles"
$templateDir = Join-Path $profilesDir "_TEMPLATE"
$shopsFile = Join-Path $portableRoot "shops.json"

# ========================================
# Detect extension directory
# ========================================
function Find-ExtensionDir {
    # 1. Try relative path (assuming we are in Portable/Scripts)
    $relativeRoot = Join-Path (Split-Path (Split-Path $scriptDir -Parent) -Parent) "Chrome"
    
    # 2. Try current working directory hierarchy
    if (-not (Test-Path $relativeRoot)) {
        $relativeRoot = Join-Path (Get-Location) "Chrome"
    }

    # 3. Fallback to hardcoded VM path
    if (-not (Test-Path $relativeRoot)) {
        $relativeRoot = "C:\NgocScript\Luxeclaw-Extension\Chrome"
    }

    if (-not (Test-Path $relativeRoot)) {
        Write-Host "WARNING: Cannot find extension directory!" -ForegroundColor Yellow
        Write-Host "  Paths tried: $relativeRoot"
        return $null
    }
    return $relativeRoot
}

function Get-ExtensionPaths {
    param([string]$ExtRoot)
    $paths = @()
    if (-not $ExtRoot -or -not (Test-Path $ExtRoot)) { return $paths }
    
    Get-ChildItem -Path $ExtRoot -Directory | ForEach-Object {
        $manifest = Join-Path $_.FullName "manifest.json"
        if (Test-Path $manifest) {
            $paths += $_.FullName
            Write-Host "  [Extension Path] $($_.FullName)" -ForegroundColor Cyan
        }
    }
    return $paths
}

# ========================================
# Step 1: Download Chromium
# ========================================
$chromiumExe = Join-Path $browserDir "chrome.exe"

if (-not (Test-Path $chromiumExe)) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " STEP 1: Download Chromium Portable" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Chromium portable not found. Tải thủ công hoặc dùng script:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Option A: https://github.com/Hibbiki/chromium-win64/releases" -ForegroundColor Green
    Write-Host "  Option B: https://chromium.woolyss.com/download/" -ForegroundColor Green
    Write-Host ""
    
    $autoDownload = Read-Host "Bạn muốn script tự động tải Chromium (Hibbiki build)? [y/N]"
    
    if ($autoDownload.Trim().ToLower() -eq "y") {
        Write-Host "Tìm kiếm phiên bản mới nhất..." -ForegroundColor Yellow
        
        try {
            # Use Hibbiki's stable portable release
            $downloadUrl = "https://github.com/Hibbiki/chromium-win64/releases/latest/download/chrome.zip"
            $zipFile = Join-Path $portableRoot "chromium-download.zip"

            Write-Host "Downloading: $downloadUrl"
            Write-Host "Dung lượng khoảng 150MB, vui lòng chờ..."
            
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $ProgressPreference = 'Continue' # Show progress for large download
            Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile -UseBasicParsing
            
            if (-not (Test-Path $browserDir)) { New-Item -ItemType Directory -Path $browserDir -Force }
            
            Write-Host "Giải nén vào $browserDir ..."
            Expand-Archive -Path $zipFile -DestinationPath $browserDir -Force
            
            # Move files out of subfolder if present
            $innerChromePath = Get-ChildItem -Path $browserDir -Filter "chrome.exe" -Recurse | Select-Object -First 1
            if ($innerChromePath -and (Split-Path $innerChromePath.DirectoryName -Leaf) -ne "Browser") {
                Write-Host "Sắp xếp lại thư mục..."
                $innerDir = $innerChromePath.DirectoryName
                Get-ChildItem -Path $innerDir | Move-Item -Destination $browserDir -Force
                # Clean empty nested folders
                # Remove-Item $innerDir -Recurse -Force -ErrorAction SilentlyContinue
            }
            
            Remove-Item $zipFile -Force -ErrorAction SilentlyContinue
            
            if (Test-Path $chromiumExe) {
                Write-Host "Tải và giải nén THÀNH CÔNG!" -ForegroundColor Green
            }
            else {
                Write-Host "Giải nén xong nhưng không thấy chrome.exe." -ForegroundColor Red
                exit 1
            }
        }
        catch {
            Write-Host "Lỗi: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Hãy tải thủ công và giải nén vào thư mục Browser." -ForegroundColor Yellow
            exit 1
        }
    }
    else {
        Write-Host "Vui lòng tải thủ công rồi chạy lại script." -ForegroundColor Yellow
        exit 0
    }
}
else {
    Write-Host "[OK] Chromium da co tai: $chromiumExe" -ForegroundColor Green
}

# ========================================
# Step 2: Create _TEMPLATE profile
# ========================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " STEP 2: Setup TEMPLATE Profile" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$templateDefault = Join-Path $templateDir "Default"
$templatePref = Join-Path $templateDefault "Preferences"

# Read config from shops.json
$config = @{ defaults = @{ startup_mode = 4; startup_urls = @("https://www.etsy.com/your/orders/sold/new"); dev_mode = $true } }
if (Test-Path $shopsFile) {
    $config = Get-Content $shopsFile -Raw | ConvertFrom-Json
}

# Build Preferences JSON
$prefs = [ordered]@{
    session = [ordered]@{
        restore_on_startup = $config.defaults.startup_mode
    }
}

if ($config.defaults.startup_mode -eq 4 -and $config.defaults.startup_urls) {
    $prefs.session.startup_urls = @($config.defaults.startup_urls)
}

if ($config.defaults.dev_mode) {
    $prefs.extensions = [ordered]@{
        ui = [ordered]@{
            developer_mode = $true
        }
    }
}

New-Item -ItemType Directory -Force -Path $templateDefault | Out-Null
New-Item -ItemType File -Force -Path (Join-Path $templateDir "First Run") | Out-Null

$prefsJson = $prefs | ConvertTo-Json -Depth 20
Set-Content -Path $templatePref -Value $prefsJson -Encoding UTF8
Write-Host "[OK] Preferences written to: $templatePref" -ForegroundColor Green

# ========================================
# Step 3: Launch TEMPLATE for manual config
# ========================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " STEP 3: Manual Configuration" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Chromium se mo voi profile _TEMPLATE." -ForegroundColor Yellow
Write-Host "Ban can lam:" -ForegroundColor Yellow
Write-Host "  1. Cai FoxyProxy tu Chrome Web Store" -ForegroundColor White
Write-Host "  2. Cai dat Proxy trong FoxyProxy (neu can)" -ForegroundColor White
Write-Host "  3. Chinh cac setting khac (Home page, etc.)" -ForegroundColor White
Write-Host "  4. KHONG dang nhap Google/Sync" -ForegroundColor Red
Write-Host "  5. DONG Chromium khi xong" -ForegroundColor Red
Write-Host ""

# Find extensions
$extRoot = Find-ExtensionDir
$extPaths = @()
if ($extRoot) {
    Write-Host "Auto-discovered extensions:" -ForegroundColor Green
    $extPaths = Get-ExtensionPaths -ExtRoot $extRoot
}

# Build launch args
$launchArgs = @(
    "--user-data-dir=`"$templateDir`"",
    "--profile-directory=`"Default`"",
    "--no-first-run",
    "--no-default-browser-check",
    "--disable-search-engine-choice-screen"
)

if ($extPaths.Count -gt 0) {
    $joined = ($extPaths -join ",")
    $launchArgs += "--load-extension=`"$joined`""
}

$launchArgs += "https://www.etsy.com/your/orders/sold/new"

Write-Host "Dang mo Chromium... Hay cai dat xong roi DONG trinh duyet." -ForegroundColor Yellow
Write-Host ""

Start-Process -FilePath $chromiumExe -ArgumentList $launchArgs -Wait

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " SETUP HOAN TAT!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "TEMPLATE profile da san sang." -ForegroundColor Green
Write-Host "Buoc tiep theo:" -ForegroundColor Cyan
Write-Host "  1. Chinh sua shops.json (them ten shop)" -ForegroundColor White
Write-Host "  2. Chay: .\Scripts\clone-profile.ps1" -ForegroundColor White
Write-Host "  3. Chay: .\Scripts\launch-all.ps1" -ForegroundColor White
