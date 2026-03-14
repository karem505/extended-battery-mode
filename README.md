# Extended Battery Mode — Double Your Linux Laptop Battery Life

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%20|%2024.04%20|%2024.10-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash&logoColor=white)](#)
[![GNOME](https://img.shields.io/badge/GNOME-Panel%20Indicator-4A86CF?logo=gnome&logoColor=white)](#panel-indicator)

> **One command to cut your Linux laptop power consumption in half.** A toggleable battery-saving mode with GNOME panel indicator — like Windows battery saver, but for Linux. No background daemon, no bloat.

---

## The Problem

Linux laptops drain battery **significantly faster** than the same hardware running Windows. Out of the box, Linux doesn't aggressively manage power the way Windows does with its built-in battery saver mode. The result:

- **3–4 hours** on Linux vs **6–8 hours** on Windows with the same laptop
- CPU turbo boost running constantly, even during light tasks
- Display at full brightness eating watts
- WiFi, audio, and PCIe devices consuming power unnecessarily
- No simple toggle to switch between performance and battery life

Tools like TLP help, but they require configuration, run as a background daemon, and don't give you a simple on/off toggle.

## The Solution

**Extended Battery Mode** applies **10 proven power-saving tweaks** with a single command and reverses them all just as easily. No daemon, no config files, no learning curve.

### Before & After

| Metric | Normal Mode | Extended Battery Mode | Savings |
|--------|-------------|----------------------|---------|
| CPU frequency | Up to 4.7 GHz (turbo) | Capped at ~1.5 GHz (30%) | ~60% CPU power |
| Display brightness | 100% | 40% | ~50% backlight power |
| WiFi power save | Off | On | ~0.5W |
| Audio codec | Always on | Power save | ~0.2W |
| PCIe ASPM | Default | Power supersave | ~0.5W |
| **Estimated total** | **~15–20W** | **~6–10W** | **~50% less** |

> On an HP ZBook Firefly 15 G7, this extends battery life from **~3.5 hours to ~7+ hours** for typical coding/browsing workloads.

## Quick Install

```bash
git clone https://github.com/karem505/extended-battery-mode.git
cd extended-battery-mode
sudo bash install.sh
```

That's it. The installer:
- Copies the script to `/usr/local/bin/`
- Installs the GNOME panel indicator
- Sets up passwordless sudo for the script
- Adds convenient shell aliases
- Configures autostart for the indicator

## Usage

### Command Line

```bash
# Enable battery saving mode
sudo extended-battery-mode on

# Restore full performance
sudo extended-battery-mode off

# Check current status (outputs JSON)
sudo extended-battery-mode status

# Toggle between modes
sudo extended-battery-mode toggle
```

### Shell Aliases (after install)

```bash
battery-save      # Enable power saving
battery-normal    # Restore performance
battery-status    # Show current status
battery-toggle    # Toggle mode
```

### Panel Indicator

A GNOME panel (system tray) indicator gives you:
- **One-click toggle** between battery save and normal mode
- **Live battery stats** — percentage, power draw, time remaining
- **Brightness control** — quick presets (20%, 40%, 60%, 80%, 100%)
- **Visual icon** — green leaf (saving) / gray bolt (normal)

The indicator auto-starts on login. To start it manually:

```bash
python3 ~/.local/bin/extended-battery-indicator.py &
```

## What It Does — 10 Power Tweaks

When you enable Extended Battery Mode, these changes are applied:

| # | Tweak | What it does | How it saves power |
|---|-------|-------------|-------------------|
| 1 | **Disable turbo boost** | Caps CPU at base frequency | Eliminates power spikes from turbo |
| 2 | **CPU cap at 30%** | Limits `max_perf_pct` to 30 | Keeps CPU at ~1.5 GHz, plenty for browsing/coding |
| 3 | **EPP → power** | Sets energy performance preference | Tells CPU governor to prioritize efficiency |
| 4 | **Dim display to 40%** | Reduces backlight brightness | Display is one of the biggest power consumers |
| 5 | **WiFi power save** | Enables 802.11 power management | WiFi chip sleeps between beacons |
| 6 | **Audio power save** | Enables HDA Intel codec power save | Audio codec enters low-power when idle |
| 7 | **ASPM powersupersave** | Aggressive PCIe link power management | PCIe devices use minimum power |
| 8 | **Dirty writeback 15s** | Delays disk writes to every 15 seconds | Fewer disk wake-ups, more batched I/O |
| 9 | **NMI watchdog off** | Disables hardware lockup detector | Eliminates periodic CPU wake-ups |
| 10 | **i915 GPU savings** | Enables FBC, PSR, DC power states | Intel GPU uses minimum power |

**All changes are reversed** when you run `extended-battery-mode off`.

## Compatibility

### Tested On

| Hardware | OS | Status |
|----------|-----|--------|
| HP ZBook Firefly 15 G7 | Ubuntu 24.04 | ✅ Fully tested |
| HP ZBook Firefly 15 G7 | Ubuntu 24.10 | ✅ Fully tested |

### Should Work On

- **Any Intel laptop** with `intel_pstate` CPU driver
- **Ubuntu 22.04+**, Debian 12+, Fedora 38+, or any systemd-based distro
- **GNOME desktop** for the panel indicator (the CLI works on any DE)
- Laptops with `intel_backlight` for brightness control

### Requirements

- Linux kernel 4.18+ (for intel_pstate and i915 power features)
- `intel_pstate` CPU frequency driver (check: `cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver`)
- `intel_backlight` (most Intel laptops)
- Python 3.8+ and `gir1.2-ayatanaappindicator3-0.1` (for the panel indicator only)
- `iw` command (for WiFi power save)

### How to Check Compatibility

```bash
# Check CPU driver (should show "intel_pstate")
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver

# Check backlight (should show "intel_backlight")
ls /sys/class/backlight/

# Check battery (should show "BAT0" or "BAT1")
ls /sys/class/power_supply/
```

## FAQ

**Q: Is this safe? Will it damage my hardware?**
A: Completely safe. All changes are software-level kernel parameter tweaks that the CPU, GPU, and peripherals are designed to handle. Everything is instantly reversible with `extended-battery-mode off`.

**Q: How does this compare to TLP?**
A: TLP is a comprehensive power management daemon that runs in the background and auto-switches profiles. Extended Battery Mode is a simpler, manual toggle — no daemon, no config, no learning curve. You can use both together if you want: TLP for baseline optimization, Extended Battery Mode for when you really need to stretch battery life.

**Q: Can I use this alongside TLP / power-profiles-daemon / auto-cpufreq?**
A: Yes. Extended Battery Mode writes directly to sysfs, which takes effect immediately. Other tools may overwrite these settings on their next cycle, so for best results either disable conflicting profiles or use Extended Battery Mode as your primary tool.

**Q: Will this make my laptop slow?**
A: Yes, intentionally. CPU is capped at 30% (~1.5 GHz on a typical Intel laptop). This is still plenty for web browsing, coding, writing, video calls, and terminal work. When you need full performance, just toggle it off.

**Q: Does it work on AMD laptops?**
A: Not currently. The script uses `intel_pstate` and `i915` parameters. AMD laptops use different drivers (`amd-pstate`, `amdgpu`). AMD support may be added in a future version.

**Q: Does it persist after reboot?**
A: No. Extended Battery Mode always starts in "off" (normal) mode after reboot. The panel indicator will start automatically and let you re-enable it with one click.

**Q: How do I check my current power draw?**
A: Run `sudo extended-battery-mode status` — it outputs JSON with battery percentage, power draw in watts, and estimated time remaining. The panel indicator also shows this information.

**Q: My laptop doesn't have `intel_backlight`. Will it still work?**
A: Yes, but brightness control won't work. All other tweaks (CPU, WiFi, audio, ASPM, etc.) will still apply and save power.

## Uninstall

```bash
cd extended-battery-mode
sudo bash uninstall.sh
```

This cleanly removes everything: the script, indicator, icons, autostart entry, sudoers rule, and shell aliases. Your system is restored to its original state.

## Contributing

Found a bug or want to add support for AMD/other hardware? [Open an issue](../../issues) or submit a pull request.

Ideas for future improvements:
- AMD laptop support (`amd-pstate` + `amdgpu`)
- Configurable CPU cap percentage
- Auto-enable when unplugged
- KDE Plasma widget
- Wayland-native indicator

## License

[MIT](LICENSE)

---

**Keywords:** linux battery life, ubuntu battery optimization, extend battery life linux, laptop power saving linux, ubuntu 24.04 battery, linux power management tool, intel laptop battery linux, reduce power consumption ubuntu, linux battery mode, TLP alternative, GNOME battery indicator, linux battery saver, HP ZBook battery linux, intel pstate power saving, linux laptop power consumption, ubuntu battery saver mode, linux power saving script, battery life extension ubuntu, power management linux laptop, energy saving linux
