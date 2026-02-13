<#
.SYNOPSIS
    Update LuxeClaw Portable scripts without losing data
.DESCRIPTION
    Safely updates scripts and config from Git while preserving Browser and Profiles.
    Supports private repos with GitHub token.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$currentDir = Get-Location

# GitHub Configuration (edit this for private repos)
$githubToken = ""  # Leave empty for public repos, or paste your token: "ghp_xxxxx"
$repoUrl = "https://github.com/ngojclee/LuxeClaw-Portable.git"

# Build authenticated URL if token is provided
if ($githubToken) {
    $repoUrl = $repoUrl -replace "https://", "https://$githubToken@"
}

$tempDir = Join-Path $env:TEMP "LuxeClaw-Portable-Update"

Write-Host ""
Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   LuxeClaw Portable - Update Scripts  ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Step 1: Clone latest version to temp
Write-Host "[1/4] Downloading latest version..." -ForegroundColor Yellow
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }

git clone --depth 1 $repoUrl $tempDir 2>&1 | Out-Null

if (-not (Test-Path $tempDir)) {
    Write-Host "ERROR: Failed to download updates" -ForegroundColor Red
    Write-Host "Tip: If repo is private, add your token to line 14 of update.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host "      ✓ Downloaded" -ForegroundColor Green

# Step 2: Backup current Browser and Profiles (if they exist)
$browserBackup = $null
$profilesBackup = $null

if (Test-Path "Browser") {
    Write-Host "[2/4] Preserving Browser..." -ForegroundColor Yellow
    $browserBackup = Join-Path $env:TEMP "Browser_Backup_$(Get-Date -Format 'yyyyMMddHHmmss')"
    Move-Item "Browser" $browserBackup -Force
    Write-Host "      ✓ Saved to temp" -ForegroundColor Green
}

if (Test-Path "Profiles") {
    Write-Host "[3/4] Preserving Profiles..." -ForegroundColor Yellow
    $profilesBackup = Join-Path $env:TEMP "Profiles_Backup_$(Get-Date -Format 'yyyyMMddHHmmss')"
    Move-Item "Profiles" $profilesBackup -Force
    Write-Host "      ✓ Saved to temp" -ForegroundColor Green
}

# Step 3: Update Scripts and config files
Write-Host "[4/4] Updating scripts..." -ForegroundColor Yellow

# Copy new files (excluding .git)
Get-ChildItem -Path $tempDir -Exclude ".git" | ForEach-Object {
    $dest = Join-Path $currentDir $_.Name
    if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
    Copy-Item $_.FullName -Destination $currentDir -Recurse -Force
}

Write-Host "      ✓ Scripts updated" -ForegroundColor Green

# Step 4: Restore Browser and Profiles
if ($browserBackup) {
    Move-Item $browserBackup "Browser" -Force
    Write-Host "      ✓ Browser restored" -ForegroundColor Green
}

if ($profilesBackup) {
    Move-Item $profilesBackup "Profiles" -Force
    Write-Host "      ✓ Profiles restored" -ForegroundColor Green
}

# Cleanup
Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "════════════════════════════════════════" -ForegroundColor Green
Write-Host "✅ Update complete!" -ForegroundColor Green
Write-Host "════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Your Browser and Profiles are intact." -ForegroundColor Cyan
Write-Host "Scripts have been updated to the latest version." -ForegroundColor Cyan
Write-Host ""
