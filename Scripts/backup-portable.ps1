<#
.SYNOPSIS
    Backup Portable Profiles to a ZIP file
.DESCRIPTION
    Creates a clean backup of Profiles (excluding cache/junk) for easy transfer to other VMs.
    Optionally uploads to Google Drive or a remote server.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = $PSScriptRoot
$portableRoot = Split-Path $scriptDir -Parent
$profilesDir = Join-Path $portableRoot "Profiles"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = Join-Path $portableRoot "Profiles_Backup_$timestamp.zip"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " LuxeClaw Portable - Backup Profiles" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $profilesDir)) {
    Write-Host "ERROR: Profiles directory not found: $profilesDir" -ForegroundColor Red
    exit 1
}

# Create temporary staging directory (to exclude cache before zipping)
$stagingDir = Join-Path $env:TEMP "LuxeClaw_Backup_Staging"
if (Test-Path $stagingDir) { Remove-Item $stagingDir -Recurse -Force }
New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null

Write-Host "Copying Profiles (excluding cache)..." -ForegroundColor Yellow

# Copy all profiles but exclude heavy cache folders
$excludeDirs = @(
    "Cache", "Code Cache", "GPUCache", "Service Worker", 
    "Media Cache", "VideoDecodeStats", "GrShaderCache", "GraphiteDawnCache"
)

Get-ChildItem -Path $profilesDir -Directory | ForEach-Object {
    $profileName = $_.Name
    $sourcePath = $_.FullName
    $destPath = Join-Path $stagingDir $profileName
    
    Write-Host "  Processing: $profileName" -ForegroundColor Gray
    
    # Use robocopy for efficient selective copy
    $excludeArgs = $excludeDirs | ForEach-Object { "/XD `"$_`"" }
    $robocopyCmd = "robocopy `"$sourcePath`" `"$destPath`" /E /NFL /NDL /NJH /NJS $($excludeArgs -join ' ')"
    
    Invoke-Expression $robocopyCmd | Out-Null
}

Write-Host ""
Write-Host "Creating ZIP archive..." -ForegroundColor Yellow
Compress-Archive -Path "$stagingDir\*" -DestinationPath $backupFile -Force

# Cleanup staging
Remove-Item $stagingDir -Recurse -Force

$backupSize = (Get-Item $backupFile).Length / 1MB
Write-Host ""
Write-Host "Backup created: $backupFile" -ForegroundColor Green
Write-Host "Size: $([math]::Round($backupSize, 2)) MB" -ForegroundColor Green
Write-Host ""

# Optional: Upload to remote location
$uploadChoice = Read-Host "Upload to remote location? [y/N]"
if ($uploadChoice.Trim().ToLower() -eq "y") {
    $uploadUrl = Read-Host "Enter upload URL (e.g., Google Drive folder ID or server path)"
    
    # Example for rclone (if installed)
    if (Get-Command rclone -ErrorAction SilentlyContinue) {
        Write-Host "Uploading via rclone..." -ForegroundColor Yellow
        rclone copy $backupFile "$uploadUrl"
        Write-Host "Upload complete!" -ForegroundColor Green
    }
    else {
        Write-Host "rclone not found. Manual upload required." -ForegroundColor Yellow
        Write-Host "File location: $backupFile"
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " Backup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
