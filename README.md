# LuxeClaw Portable

Portable Chromium setup for managing multiple Etsy shop profiles with LuxeClaw extensions.

## Quick Start

### 1. Clone this repo
```bash
git clone https://github.com/ngojclee/LuxeClaw-Portable.git
cd LuxeClaw-Portable
```

### 2. Run the Interactive Menu
```powershell
powershell -ExecutionPolicy Bypass -File .\portable.ps1
```

The menu will guide you through:
1. **Initial Setup** - Download Chromium & create template
2. **Clone Profiles** - Create profiles for all shops
3. **Launch All Shops** - Open all profiles at once
4. **Backup/Restore** - Save and restore your configurations

### Alternative: Run Scripts Directly
```powershell
# Step-by-step manual execution
powershell -ExecutionPolicy Bypass -File .\Scripts\1-setup.ps1
powershell -ExecutionPolicy Bypass -File .\Scripts\2-clone-profiles.ps1
powershell -ExecutionPolicy Bypass -File .\Scripts\3-launch-all.ps1
```

### 3. Configure Shops
Edit `shops.json` to add your shop names:
```json
{
  "shops": [
    "Shop1",
    "Shop2",
    "Shop3"
  ],
  "defaults": {
    "startup_mode": 4,
    "startup_urls": ["https://www.etsy.com/your/orders/sold/new"],
    "dev_mode": true
  }
}
```

### 4. Clone Profiles
```powershell
powershell -ExecutionPolicy Bypass -File .\Scripts\clone-profile.ps1
```

### 5. Launch All Shops
```powershell
powershell -ExecutionPolicy Bypass -File .\Scripts\launch-all.ps1
```

## Backup & Restore

### Backup Profiles
```powershell
powershell -ExecutionPolicy Bypass -File .\Scripts\backup-portable.ps1
```

### Restore on New Machine
```powershell
powershell -ExecutionPolicy Bypass -File .\Scripts\restore-portable.ps1
```

## Directory Structure

```
LuxeClaw-Portable/
├── Scripts/           # PowerShell automation scripts
├── Browser/           # Chromium portable (gitignored)
├── Profiles/          # Shop profiles (gitignored)
└── shops.json         # Shop configuration
```

## Requirements

- Windows 10/11
- PowerShell 5.1+
- LuxeClaw Chrome Extensions (from main repo)

## Related Repos

- [LuxeClaw Extensions](https://github.com/ngojclee/Luxeclaw-Extension) - Chrome extensions for Etsy automation
