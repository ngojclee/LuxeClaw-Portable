# VM Setup Troubleshooting

## Common Issue: "Failed to fetch" from Supabase

### Symptoms
```
TypeError: Failed to fetch
at chrome-extension://xxx/lib/supabase.js:7:5128
```

Extensions affected: **LuxeClawInstaScraper**, **EtsyAutomation** (Cookie Profiles), **EtsyListingCreator**

### Root Cause
VM cannot reach Supabase server (`https://nailboxdb.lengoc.me`)

### Diagnosis Steps

Run the network test script:
```powershell
cd C:\NgocScript\Luxeclaw-Extension\Portable
.\Scripts\test-network.ps1
```

This will test:
1. Basic internet connectivity
2. Supabase endpoint accessibility
3. DNS resolution
4. Ping to server
5. Proxy settings

### Solutions

#### Option 1: Fix VM Network (Recommended)
```powershell
# Test if VM has internet
Test-Connection google.com

# Test Supabase directly
Invoke-WebRequest https://nailboxdb.lengoc.me/rest/v1/

# If failed, check:
# 1. VM network adapter settings
# 2. Windows Firewall (temporarily disable to test)
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

# 3. Antivirus/Security software
# 4. Proxy settings in Windows
```

#### Option 2: Use Extensions Without Supabase
Some extensions can work without Supabase:
- **EtsyAutomation**: Core features (tracking, notes, printing) work without Cookie Profiles
- **LuxeClawInstaScraper**: Can scrape but won't save profiles to DB

#### Option 3: Local Supabase (Advanced)
Run Supabase locally on VM:
```powershell
# Install Docker Desktop on VM
# Run Supabase locally
docker run -p 54321:54321 supabase/postgres
```

Then update `lib/config.js` in each extension:
```javascript
SUPABASE_URL: "http://localhost:54321"
```

### Quick Test in Browser

Open Chromium on VM and navigate to:
```
https://nailboxdb.lengoc.me/rest/v1/
```

**Expected**: JSON response with `{"message":"..."}`  
**If failed**: Network issue confirmed

### Firewall Rules

If Windows Firewall is blocking, add rule:
```powershell
New-NetFirewallRule -DisplayName "Supabase HTTPS" -Direction Outbound -Action Allow -Protocol TCP -RemotePort 443 -RemoteAddress nailboxdb.lengoc.me
```

### Still Not Working?

Check VM's internet routing:
```powershell
# Check default gateway
Get-NetRoute -DestinationPrefix 0.0.0.0/0

# Check DNS servers
Get-DnsClientServerAddress

# Flush DNS cache
Clear-DnsClientCache

# Test with different DNS (Google DNS)
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses ("8.8.8.8","8.8.4.4")
```

### Workaround: Use Extensions Offline

Extensions will gracefully degrade:
- **EtsyAutomation**: Manual cookie management (export/import via browser)
- **InstaScraper**: Download images without saving to DB
- **EtsyListingCreator**: Use local storage only

No code changes needed - extensions detect failed Supabase connection and continue.
