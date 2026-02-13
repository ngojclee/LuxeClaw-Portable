<#
sync-profiles.ps1 - Sync _TEMPLATE settings to all shop profiles
Copies Preferences from _TEMPLATE to selected profiles.
Cleans Secure Preferences to prevent Chrome reset warnings.

Usage:
  .\sync-profiles.ps1                  # Sync all shops
  .\sync-profiles.ps1 -Only "Shop1","Shop2"  # Sync specific shops
#>

param(
    [string[]]$Only
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = $PSScriptRoot
$portableRoot = Split-Path $scriptDir -Parent
$profilesDir = Join-Path $portableRoot "Profiles"
$templateDir = Join-Path $profilesDir "_TEMPLATE"
$shopsFile = Join-Path $portableRoot "shops.json"

$templatePref = Join-Path $templateDir "Default\Preferences"

if (-not (Test-Path $templatePref)) {
    Write-Host "_TEMPLATE Preferences khong ton tai! Chay setup.ps1 truoc." -ForegroundColor Red
    exit 1
}

# Get list of shop profiles to sync
$targetDirs = @()

if ($Only -and $Only.Count -gt 0) {
    foreach ($name in $Only) {
        $dir = Join-Path $profilesDir $name
        if (Test-Path $dir) {
            $targetDirs += @{ Name = $name; Path = $dir }
        }
        else {
            Write-Host "  [SKIP] $name (khong ton tai)" -ForegroundColor Yellow
        }
    }
}
else {
    # Sync all shop profiles (exclude _TEMPLATE)
    Get-ChildItem -Path $profilesDir -Directory | Where-Object { $_.Name -ne "_TEMPLATE" } | ForEach-Object {
        $targetDirs += @{ Name = $_.Name; Path = $_.FullName }
    }
}

if ($targetDirs.Count -eq 0) {
    Write-Host "Khong co profile nao de dong bo." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Syncing _TEMPLATE -> $($targetDirs.Count) profiles" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$masterContent = Get-Content -Path $templatePref -Raw

foreach ($target in $targetDirs) {
    $targetPref = Join-Path $target.Path "Default\Preferences"
    $targetDir = Join-Path $target.Path "Default"
    
    if (-not (Test-Path $targetDir)) {
        Write-Host "  [SKIP] $($target.Name) (no Default folder)" -ForegroundColor Yellow
        continue
    }
    
    Set-Content -Path $targetPref -Value $masterContent -Encoding UTF8
    
    # Clean Secure Preferences to prevent Chrome "Settings were reset" warning
    $securePref = Join-Path $targetDir "Secure Preferences"
    if (Test-Path $securePref) { Remove-Item $securePref -Force }
    
    Write-Host "  [SYNC] $($target.Name)" -ForegroundColor Green
}

Write-Host ""
Write-Host "Dong bo hoan tat! Preferences da duoc cap nhat." -ForegroundColor Green
Write-Host "NOTE: Cookies va login KHONG bi anh huong." -ForegroundColor Cyan
