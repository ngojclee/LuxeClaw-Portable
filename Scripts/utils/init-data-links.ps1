<#
.SYNOPSIS
    Initialize Portable with external data directory (symlinks)
.DESCRIPTION
    Creates Browser and Profiles folders OUTSIDE the Git repo to prevent data loss
    when doing rm -rf && git clone. Uses symbolic links to connect them.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = $PSScriptRoot
$portableRoot = Split-Path $scriptDir -Parent
$repoRoot = Split-Path (Split-Path $portableRoot -Parent) -Parent

# Determine external data directory
$externalDataDir = Join-Path (Split-Path $repoRoot -Parent) "LuxeClawData"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " LuxeClaw Portable - Init Data Links" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Repo location: $repoRoot" -ForegroundColor Gray
Write-Host "Data location: $externalDataDir" -ForegroundColor Gray
Write-Host ""

# Create external data directory if not exists
if (-not (Test-Path $externalDataDir)) {
    Write-Host "Creating external data directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $externalDataDir -Force | Out-Null
}

$browserExternal = Join-Path $externalDataDir "Browser"
$profilesExternal = Join-Path $externalDataDir "Profiles"

# Create external folders
if (-not (Test-Path $browserExternal)) {
    New-Item -ItemType Directory -Path $browserExternal -Force | Out-Null
    Write-Host "Created: $browserExternal" -ForegroundColor Green
}

if (-not (Test-Path $profilesExternal)) {
    New-Item -ItemType Directory -Path $profilesExternal -Force | Out-Null
    Write-Host "Created: $profilesExternal" -ForegroundColor Green
}

# Create symlinks in repo
$browserLink = Join-Path $portableRoot "Browser"
$profilesLink = Join-Path $portableRoot "Profiles"

# Remove existing if they are regular folders (not symlinks)
if ((Test-Path $browserLink) -and -not (Get-Item $browserLink).Attributes.HasFlag([System.IO.FileAttributes]::ReparsePoint)) {
    Write-Host "Removing old Browser folder..." -ForegroundColor Yellow
    Remove-Item $browserLink -Recurse -Force
}

if ((Test-Path $profilesLink) -and -not (Get-Item $profilesLink).Attributes.HasFlag([System.IO.FileAttributes]::ReparsePoint)) {
    Write-Host "Removing old Profiles folder..." -ForegroundColor Yellow
    Remove-Item $profilesLink -Recurse -Force
}

# Create symlinks (requires Admin on Windows)
if (-not (Test-Path $browserLink)) {
    Write-Host "Creating symlink: Browser -> $browserExternal" -ForegroundColor Cyan
    New-Item -ItemType SymbolicLink -Path $browserLink -Target $browserExternal -Force | Out-Null
}

if (-not (Test-Path $profilesLink)) {
    Write-Host "Creating symlink: Profiles -> $profilesExternal" -ForegroundColor Cyan
    New-Item -ItemType SymbolicLink -Path $profilesLink -Target $profilesExternal -Force | Out-Null
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Data is now stored OUTSIDE the Git repo." -ForegroundColor Green
Write-Host "You can safely run: rm -rf && git clone" -ForegroundColor Green
Write-Host ""
Write-Host "Next step: Run setup.ps1 to download Chromium" -ForegroundColor Cyan
