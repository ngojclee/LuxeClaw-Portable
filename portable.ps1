<#
.SYNOPSIS
    LuxeClaw Portable - Main Menu
.DESCRIPTION
    Interactive menu for managing portable Chromium profiles for multiple Etsy shops.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = $PSScriptRoot

function Show-Menu {
    Clear-Host
    Write-Host ""
    Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║   LuxeClaw Portable - Main Menu        ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Initial Setup" -ForegroundColor Yellow
    Write-Host "      └─ Download Chromium & create template profile" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [2] Clone Profiles" -ForegroundColor Yellow
    Write-Host "      └─ Create profiles for all shops in shops.json" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [3] Launch All Shops" -ForegroundColor Yellow
    Write-Host "      └─ Open all shop profiles in separate windows" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [4] Backup Profiles" -ForegroundColor Yellow
    Write-Host "      └─ Create ZIP backup (excludes cache)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [5] Restore Profiles" -ForegroundColor Yellow
    Write-Host "      └─ Restore from backup ZIP" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [6] Sync Profiles" -ForegroundColor Yellow
    Write-Host "      └─ Update all profiles from template" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [0] Exit" -ForegroundColor Red
    Write-Host ""
    Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

function Run-Script {
    param([string]$ScriptName)
    
    $scriptPath = Join-Path $scriptDir $ScriptName
    
    if (-not (Test-Path $scriptPath)) {
        Write-Host "ERROR: Script not found: $scriptPath" -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }
    
    Write-Host ""
    Write-Host "Running: $ScriptName" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    & $scriptPath
    
    Write-Host ""
    Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
    Read-Host "Press Enter to return to menu"
}

# Main loop
while ($true) {
    Show-Menu
    $choice = Read-Host "Select an option"
    
    switch ($choice) {
        "1" { Run-Script "1-setup.ps1" }
        "2" { Run-Script "2-clone-profiles.ps1" }
        "3" { Run-Script "3-launch-all.ps1" }
        "4" { Run-Script "4-backup.ps1" }
        "5" { Run-Script "5-restore.ps1" }
        "6" { Run-Script "utils\sync-profiles.ps1" }
        "0" { 
            Write-Host ""
            Write-Host "Goodbye! 👋" -ForegroundColor Green
            Write-Host ""
            exit 0
        }
        default {
            Write-Host ""
            Write-Host "Invalid option. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
