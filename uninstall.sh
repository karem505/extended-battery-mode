#!/usr/bin/env bash
set -euo pipefail

# Extended Battery Mode — Uninstaller
# Cleanly removes all installed components

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
    echo "Usage: sudo bash uninstall.sh"
    exit 1
fi

echo -e "${YELLOW}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║     Extended Battery Mode — Uninstaller          ║${NC}"
echo -e "${YELLOW}╚══════════════════════════════════════════════════╝${NC}"
echo ""

# Step 1: Restore defaults if currently on
echo -e "${YELLOW}[1/6] Restoring default power settings...${NC}"
if [[ -f /tmp/extended-battery-mode.state ]]; then
    /usr/local/bin/extended-battery-mode off 2>/dev/null || true
    echo -e "  ${GREEN}[✓] Power settings restored to normal${NC}"
else
    echo -e "  [i] Already in normal mode${NC}"
fi

# Step 2: Remove main script
echo -e "${YELLOW}[2/6] Removing main script...${NC}"
rm -f /usr/local/bin/extended-battery-mode
echo -e "  ${GREEN}[✓] /usr/local/bin/extended-battery-mode removed${NC}"

# Step 3: Remove indicator and autostart
echo -e "${YELLOW}[3/6] Removing panel indicator...${NC}"
# Kill running indicator
pkill -f "extended-battery-indicator.py" 2>/dev/null || true
rm -f "$REAL_HOME/.local/bin/extended-battery-indicator.py"
rm -f "$REAL_HOME/.config/autostart/extended-battery-indicator.desktop"
echo -e "  ${GREEN}[✓] Indicator and autostart entry removed${NC}"

# Step 4: Remove icons
echo -e "${YELLOW}[4/6] Removing icons...${NC}"
ICON_DIR="$REAL_HOME/.local/share/icons/hicolor/scalable/status"
rm -f "$ICON_DIR/extended-battery-on.svg"
rm -f "$ICON_DIR/extended-battery-off.svg"
if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -f "$REAL_HOME/.local/share/icons/hicolor" 2>/dev/null || true
fi
echo -e "  ${GREEN}[✓] Icons removed${NC}"

# Step 5: Remove sudoers rule
echo -e "${YELLOW}[5/6] Removing sudoers rule...${NC}"
rm -f /etc/sudoers.d/extended-battery-mode
echo -e "  ${GREEN}[✓] Sudoers rule removed${NC}"

# Step 6: Remove bash aliases
echo -e "${YELLOW}[6/6] Removing shell aliases...${NC}"
BASHRC="$REAL_HOME/.bashrc"
if grep -q "# Extended Battery Mode aliases" "$BASHRC" 2>/dev/null; then
    # Remove the alias block (marker + 4 alias lines + blank line before)
    sed -i '/^$/N;/\n# Extended Battery Mode aliases/{N;N;N;N;d}' "$BASHRC" 2>/dev/null || \
    sed -i '/# Extended Battery Mode aliases/,+4d' "$BASHRC" 2>/dev/null || true
    chown "$REAL_USER:$REAL_USER" "$BASHRC"
    echo -e "  ${GREEN}[✓] Aliases removed from .bashrc${NC}"
else
    echo -e "  [i] No aliases found in .bashrc${NC}"
fi

# Cleanup state files
rm -f /tmp/extended-battery-mode.state
rm -f /tmp/extended-battery-charge-sample

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Uninstall Complete!                          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  All components have been removed. Your system is back to default."
echo ""
