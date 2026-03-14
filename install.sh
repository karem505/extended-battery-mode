#!/usr/bin/env bash
set -euo pipefail

# Extended Battery Mode — Installer
# One-command setup for Linux laptop power saving

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
    echo "Usage: sudo bash install.sh"
    exit 1
fi

echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Extended Battery Mode — Installer            ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""

# Step 1: Install dependencies
echo -e "${YELLOW}[1/9] Installing dependencies...${NC}"
if command -v apt-get &>/dev/null; then
    apt-get update -qq
    apt-get install -y -qq gir1.2-ayatanaappindicator3-0.1 2>/dev/null || \
        echo -e "  ${BLUE}[i] gir1.2-ayatanaappindicator3-0.1 may already be installed or unavailable${NC}"
elif command -v dnf &>/dev/null; then
    dnf install -y -q libayatana-appindicator-gtk3 2>/dev/null || \
        echo -e "  ${BLUE}[i] libayatana-appindicator-gtk3 may already be installed${NC}"
else
    echo -e "  ${BLUE}[i] Please install AyatanaAppIndicator3 GObject introspection bindings manually${NC}"
fi
echo -e "  ${GREEN}[✓] Dependencies checked${NC}"

# Step 2: Install main script
echo -e "${YELLOW}[2/9] Installing extended-battery-mode to /usr/local/bin/...${NC}"
cp "$SCRIPT_DIR/extended-battery-mode" /usr/local/bin/extended-battery-mode
chmod 755 /usr/local/bin/extended-battery-mode
echo -e "  ${GREEN}[✓] /usr/local/bin/extended-battery-mode${NC}"

# Step 3: Install indicator
echo -e "${YELLOW}[3/9] Installing panel indicator...${NC}"
mkdir -p "$REAL_HOME/.local/bin"
cp "$SCRIPT_DIR/indicator/extended-battery-indicator.py" "$REAL_HOME/.local/bin/extended-battery-indicator.py"
chmod 755 "$REAL_HOME/.local/bin/extended-battery-indicator.py"
chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.local/bin/extended-battery-indicator.py"
echo -e "  ${GREEN}[✓] $REAL_HOME/.local/bin/extended-battery-indicator.py${NC}"

# Step 4: Install icons
echo -e "${YELLOW}[4/9] Installing tray icons...${NC}"
ICON_DIR="$REAL_HOME/.local/share/icons/hicolor/scalable/status"
mkdir -p "$ICON_DIR"
cp "$SCRIPT_DIR/icons/extended-battery-on.svg" "$ICON_DIR/"
cp "$SCRIPT_DIR/icons/extended-battery-off.svg" "$ICON_DIR/"
chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.local/share/icons/hicolor"
echo -e "  ${GREEN}[✓] Icons installed to $ICON_DIR${NC}"

# Step 5: Update icon cache
echo -e "${YELLOW}[5/9] Updating icon cache...${NC}"
if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -f "$REAL_HOME/.local/share/icons/hicolor" 2>/dev/null || true
    echo -e "  ${GREEN}[✓] Icon cache updated${NC}"
else
    echo -e "  ${BLUE}[i] gtk-update-icon-cache not found, skipping${NC}"
fi

# Step 6: Create autostart entry
echo -e "${YELLOW}[6/9] Setting up autostart...${NC}"
AUTOSTART_DIR="$REAL_HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"
sed "s|HOME_PLACEHOLDER|$REAL_HOME|g" "$SCRIPT_DIR/indicator/extended-battery-indicator.desktop" \
    > "$AUTOSTART_DIR/extended-battery-indicator.desktop"
chown "$REAL_USER:$REAL_USER" "$AUTOSTART_DIR/extended-battery-indicator.desktop"
echo -e "  ${GREEN}[✓] Autostart entry created${NC}"

# Step 7: Configure sudoers (passwordless for this script)
echo -e "${YELLOW}[7/9] Configuring sudoers for passwordless access...${NC}"
SUDOERS_FILE="/etc/sudoers.d/extended-battery-mode"
cat > "$SUDOERS_FILE" << EOF
# Allow all users to run extended-battery-mode without password
ALL ALL=(root) NOPASSWD: /usr/local/bin/extended-battery-mode
EOF
chmod 440 "$SUDOERS_FILE"
# Validate sudoers syntax
if visudo -cf "$SUDOERS_FILE" &>/dev/null; then
    echo -e "  ${GREEN}[✓] Sudoers rule added (no password needed)${NC}"
else
    rm -f "$SUDOERS_FILE"
    echo -e "  ${RED}[✗] Sudoers validation failed, removed${NC}"
fi

# Step 8: Add bash aliases
echo -e "${YELLOW}[8/9] Adding shell aliases...${NC}"
BASHRC="$REAL_HOME/.bashrc"
ALIAS_MARKER="# Extended Battery Mode aliases"
if ! grep -q "$ALIAS_MARKER" "$BASHRC" 2>/dev/null; then
    cat >> "$BASHRC" << 'EOF'

# Extended Battery Mode aliases
alias battery-save='sudo extended-battery-mode on'
alias battery-normal='sudo extended-battery-mode off'
alias battery-status='sudo extended-battery-mode status'
alias battery-toggle='sudo extended-battery-mode toggle'
EOF
    chown "$REAL_USER:$REAL_USER" "$BASHRC"
    echo -e "  ${GREEN}[✓] Aliases added: battery-save, battery-normal, battery-status, battery-toggle${NC}"
else
    echo -e "  ${BLUE}[i] Aliases already present in .bashrc${NC}"
fi

# Step 9: Verify installation
echo -e "${YELLOW}[9/9] Verifying installation...${NC}"
if [[ -x /usr/local/bin/extended-battery-mode ]]; then
    echo -e "  ${GREEN}[✓] Main script: OK${NC}"
else
    echo -e "  ${RED}[✗] Main script: MISSING${NC}"
fi
if [[ -f "$REAL_HOME/.local/bin/extended-battery-indicator.py" ]]; then
    echo -e "  ${GREEN}[✓] Indicator: OK${NC}"
else
    echo -e "  ${RED}[✗] Indicator: MISSING${NC}"
fi
if [[ -f "$ICON_DIR/extended-battery-on.svg" && -f "$ICON_DIR/extended-battery-off.svg" ]]; then
    echo -e "  ${GREEN}[✓] Icons: OK${NC}"
else
    echo -e "  ${RED}[✗] Icons: MISSING${NC}"
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Installation Complete!                        ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BLUE}Usage:${NC}"
echo -e "    sudo extended-battery-mode on       # Enable power saving"
echo -e "    sudo extended-battery-mode off      # Restore performance"
echo -e "    sudo extended-battery-mode status   # Show current status"
echo -e "    sudo extended-battery-mode toggle   # Toggle mode"
echo ""
echo -e "  ${BLUE}Shortcuts (after restarting your shell):${NC}"
echo -e "    battery-save    battery-normal    battery-status    battery-toggle"
echo ""
echo -e "  ${BLUE}Panel indicator:${NC} Log out and back in, or run:"
echo -e "    python3 ~/.local/bin/extended-battery-indicator.py &"
echo ""
