# Portable Chromium Multi-Shop Setup Guide

## Architecture

**1 Chromium binary + N profiles** (same as Multilogin/GoLogin)

```
Chromium Portable ─┬── Profile: Shop1 (cookies + settings riêng)
   (1 binary)      ├── Profile: Shop2
                    └── Profile: ShopN   (all run in parallel)
```

## Quick Start

### First Time Setup

```powershell
cd D:\Python\projects\LuxeClaw\Extension\Portable

# 1. Download Chromium + create TEMPLATE
.\Scripts\setup.ps1

# 2. In the browser that opens:
#    - Install FoxyProxy from Web Store
#    - Configure proxy settings
#    - Set any other browser preferences
#    - DO NOT sign into Google
#    - CLOSE the browser when done

# 3. Edit shops.json with your shop names

# 4. Clone TEMPLATE to all shops
.\Scripts\clone-profile.ps1

# 5. Login to each Etsy account
.\Scripts\launch-all.ps1
```

### Adding New Shops

```powershell
# 1. Edit shops.json, add new shop entry
# 2. Clone (only creates new shops, skips existing)
.\Scripts\clone-profile.ps1
```

### Daily Use

```powershell
.\Scripts\launch-all.ps1              # Launch all shops
.\Scripts\launch-shop.ps1 -Shop "X"   # Launch one shop
.\Scripts\launch-shop.ps1 -Shop "X" -Kiosk  # With kiosk printing
```

### Sync Settings

After changing settings in _TEMPLATE:
```powershell
.\Scripts\sync-profiles.ps1           # All shops
.\Scripts\sync-profiles.ps1 -Only "Shop1","Shop2"  # Specific
```

## On New Machine (VM)

```powershell
# 1. Clone repo
git clone <repo-url> C:\NgocScript\Luxeclaw-Extension

# 2. Setup Chromium
cd C:\NgocScript\Luxeclaw-Extension\Portable
.\Scripts\setup.ps1

# 3. Clone profiles
.\Scripts\clone-profile.ps1

# 4. Inject cookies via EtsyAutomation Cookie Profiles
#    or login manually to each shop
.\Scripts\launch-all.ps1
```

## Download Chromium

Download from: https://chromium.woolyss.com/download/
- Choose: **ungoogled-chromium** > Windows 64-bit > Portable
- Extract to: `Portable/Browser/`
- Ensure `chrome.exe` is at: `Portable/Browser/chrome.exe`

## Directory Structure

```
Portable/
├── Browser/          # Chromium binary (gitignored, ~200MB)
├── Profiles/
│   ├── _TEMPLATE/    # Master profile (Preferences only in Git)
│   ├── Shop1/        # gitignored
│   └── Shop2/        # gitignored
├── Scripts/          # PS1 automation scripts (in Git)
├── docs/             # Documentation (in Git)
└── shops.json        # Shop registry (in Git)
```

## Notes

- **Chromium does NOT auto-update** — stable for automation
- **Extensions loaded from**: `Chrome/` directory (shared, not per-profile)
- **FoxyProxy**: Install in `_TEMPLATE` → auto-cloned to all shops
- **Cookies**: Managed per-profile, or via EtsyAutomation Cookie Profiles (Supabase)
