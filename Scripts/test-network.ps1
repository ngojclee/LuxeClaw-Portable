# test-network.ps1 - Test network connectivity from VM
# Run this on VM to diagnose Supabase connection issues

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Network Connectivity Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Basic internet
Write-Host "[1] Testing basic internet (google.com)..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://www.google.com" -UseBasicParsing -TimeoutSec 5
    Write-Host "  ✅ OK - Status: $($response.StatusCode)" -ForegroundColor Green
}
catch {
    Write-Host "  ❌ FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Supabase endpoint
Write-Host ""
Write-Host "[2] Testing Supabase (nailboxdb.lengoc.me)..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://nailboxdb.lengoc.me/rest/v1/" -UseBasicParsing -TimeoutSec 5
    Write-Host "  ✅ OK - Status: $($response.StatusCode)" -ForegroundColor Green
}
catch {
    Write-Host "  ❌ FAILED - $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Possible causes:" -ForegroundColor Yellow
    Write-Host "    - VM has no internet access" -ForegroundColor White
    Write-Host "    - Firewall blocking HTTPS" -ForegroundColor White
    Write-Host "    - DNS resolution issue" -ForegroundColor White
}

# Test 3: DNS resolution
Write-Host ""
Write-Host "[3] Testing DNS resolution..." -ForegroundColor Yellow
try {
    $dns = Resolve-DnsName -Name "nailboxdb.lengoc.me" -ErrorAction Stop
    Write-Host "  ✅ OK - IP: $($dns[0].IPAddress)" -ForegroundColor Green
}
catch {
    Write-Host "  ❌ FAILED - Cannot resolve DNS" -ForegroundColor Red
}

# Test 4: Ping test
Write-Host ""
Write-Host "[4] Testing ping to Supabase..." -ForegroundColor Yellow
try {
    $ping = Test-Connection -ComputerName "nailboxdb.lengoc.me" -Count 2 -Quiet
    if ($ping) {
        Write-Host "  ✅ OK - Server is reachable" -ForegroundColor Green
    }
    else {
        Write-Host "  ❌ FAILED - Server not reachable" -ForegroundColor Red
    }
}
catch {
    Write-Host "  ❌ FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Check proxy settings
Write-Host ""
Write-Host "[5] Checking proxy settings..." -ForegroundColor Yellow
$proxy = [System.Net.WebRequest]::GetSystemWebProxy()
$proxyUri = $proxy.GetProxy("https://nailboxdb.lengoc.me")
if ($proxyUri.Host -eq "nailboxdb.lengoc.me") {
    Write-Host "  ✅ No proxy configured" -ForegroundColor Green
}
else {
    Write-Host "  ⚠️  Proxy detected: $proxyUri" -ForegroundColor Yellow
    Write-Host "     This might interfere with Supabase connection" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Recommendations" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "If Supabase test failed:" -ForegroundColor Yellow
Write-Host "  1. Check VM internet connection" -ForegroundColor White
Write-Host "  2. Disable Windows Firewall temporarily:" -ForegroundColor White
Write-Host "     Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False" -ForegroundColor Gray
Write-Host "  3. Check if antivirus is blocking HTTPS" -ForegroundColor White
Write-Host "  4. Try accessing https://nailboxdb.lengoc.me in browser" -ForegroundColor White
Write-Host ""
