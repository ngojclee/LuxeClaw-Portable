<#
.SYNOPSIS
    Restore Portable Profiles from backup ZIP
.DESCRIPTION
    Downloads and extracts profile backup to the Portable/Profiles directory.
    Optionally downloads Chromium from a custom URL.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = $PSScriptRoot
$portableRoot = Split-Path $scriptDir -Parent
$profilesDir = Join-Path $portableRoot "Profiles"
$browserDir = Join-Path $portableRoot "Browser"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " LuxeClaw Portable - Restore Profiles" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Restore Profiles
$backupSource = Read-Host "Enter backup ZIP path or URL"

if ($backupSource -match "^https?://") {
    Write-Host "Downloading backup from URL..." -ForegroundColor Yellow
    $backupFile = Join-Path $env:TEMP "profiles_backup.zip"
    Invoke-WebRequest -Uri $backupSource -OutFile $backupFile -UseBasicParsing
}
else {
    $backupFile = $backupSource
}

if (-not (Test-Path $backupFile)) {
    Write-Host "ERROR: Backup file not found: $backupFile" -ForegroundColor Red
    exit 1
}

Write-Host "Extracting profiles..." -ForegroundColor Yellow
if (Test-Path $profilesDir) {
    $overwrite = Read-Host "Profiles directory exists. Overwrite? [y/N]"
    if ($overwrite.Trim().ToLower() -ne "y") {
        Write-Host "Restore cancelled." -ForegroundColor Yellow
        exit 0
    }
    Remove-Item $profilesDir -Recurse -Force
}

Expand-Archive -Path $backupFile -DestinationPath $profilesDir -Force
Write-Host "Profiles restored successfully!" -ForegroundColor Green

# Step 2: Setup Chromium
Write-Host ""
$setupChromium = Read-Host "Download Chromium now? [y/N]"

if ($setupChromium.Trim().ToLower() -eq "y") {
    $chromiumUrl = Read-Host "Enter Chromium ZIP URL (or press Enter for default Hibbiki build)"
    
    if ([string]::IsNullOrWhiteSpace($chromiumUrl)) {
        $chromiumUrl = "https://github.com/Hibbiki/chromium-win64/releases/latest/download/chrome.zip"
    }
    
    Write-Host "Downloading Chromium from: $chromiumUrl" -ForegroundColor Yellow
    $chromiumZip = Join-Path $env:TEMP "chromium.zip"
    
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $chromiumUrl -OutFile $chromiumZip -UseBasicParsing
    
    Write-Host "Extracting Chromium..." -ForegroundColor Yellow
    if (-not (Test-Path $browserDir)) { New-Item -ItemType Directory -Path $browserDir -Force }
    Expand-Archive -Path $chromiumZip -DestinationPath $browserDir -Force
    
    # Flatten nested directories if needed
    $chromeExe = Get-ChildItem -Path $browserDir -Filter "chrome.exe" -Recurse | Select-Object -First 1
    if ($chromeExe -and (Split-Path $chromeExe.DirectoryName -Leaf) -ne "Browser") {
        $innerDir = $chromeExe.DirectoryName
        Get-ChildItem -Path $innerDir | Move-Item -Destination $browserDir -Force
    }
    
    Remove-Item $chromiumZip -Force -ErrorAction SilentlyContinue
    Write-Host "Chromium installed!" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " Restore Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Run: .\Scripts\launch-all.ps1" -ForegroundColor White
Write-Host "  2. Verify all shops are logged in" -ForegroundColor White
