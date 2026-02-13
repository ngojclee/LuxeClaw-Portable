<#
launch-all.ps1 - Launch all shops from shops.json
Usage:
  .\launch-all.ps1               # Normal mode
  .\launch-all.ps1 -Kiosk        # All with kiosk printing
  .\launch-all.ps1 -Delay 3      # 3 second delay between launches
#>

param(
    [switch]$Kiosk,
    [int]$Delay = 2
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = $PSScriptRoot
$portableRoot = Split-Path $scriptDir -Parent
$shopsFile = Join-Path $portableRoot "shops.json"
$profilesDir = Join-Path $portableRoot "Profiles"

if (-not (Test-Path $shopsFile)) {
    Write-Host "shops.json khong tim thay!" -ForegroundColor Red
    exit 1
}

$config = Get-Content $shopsFile -Raw | ConvertFrom-Json
$shops = @($config.shops)

if ($shops.Count -eq 0) {
    Write-Host "Khong co shop nao trong shops.json." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Launching $($shops.Count) shops" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$launched = 0
foreach ($shop in $shops) {
    $shopDir = Join-Path $profilesDir $shop.name
    
    if (-not (Test-Path $shopDir)) {
        Write-Host "  [SKIP] $($shop.name) - profile khong ton tai" -ForegroundColor Yellow
        continue
    }

    $extraArgs = @()
    if ($Kiosk) { $extraArgs += "-Kiosk" }
    
    Write-Host "  [LAUNCH] $($shop.name)..." -ForegroundColor Green
    & "$scriptDir\launch-shop.ps1" -Shop $shop.name @extraArgs
    
    $launched++
    
    if ($launched -lt $shops.Count) {
        Write-Host "    Waiting ${Delay}s..." -ForegroundColor Gray
        Start-Sleep -Seconds $Delay
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " Launched $launched/$($shops.Count) shops" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
