#!/bin/bash
# ============================================================
#  Nort TV — installer
#  Supports: Ubuntu Server, Debian, Raspberry Pi OS Lite, Arch
#  Run as root: sudo bash install.sh
# ============================================================

set -e

echo ""
echo "  ███╗   ██╗ ██████╗ ██████╗ ████████╗    ████████╗██╗   ██╗"
echo "  ████╗  ██║██╔═══██╗██╔══██╗╚══██╔══╝    ╚══██╔══╝██║   ██║"
echo "  ██╔██╗ ██║██║   ██║██████╔╝   ██║          ██║   ██║   ██║"
echo "  ██║╚██╗██║██║   ██║██╔══██╗   ██║          ██║   ╚██╗ ██╔╝"
echo "  ██║ ╚████║╚██████╔╝██║  ██║   ██║          ██║    ╚████╔╝ "
echo "  ╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝          ╚═╝     ╚═══╝  "
echo ""

# ── Preflight checks ─────────────────────────────────────────────────────
if [ "$(id -u)" -ne 0 ]; then
  echo "  ERROR: Please run as root: sudo bash install.sh"
  exit 1
fi

if [ -z "$SUDO_USER" ]; then
  echo "  ERROR: Could not detect your username. Run with sudo, not as root directly."
  exit 1
fi

TV_USER="$SUDO_USER"
TV_HOME="/home/$TV_USER"
INSTALL_DIR="/opt/nort-tv"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "  Installing for user : $TV_USER"
echo "  App will live at    : $INSTALL_DIR"
echo ""

# ── Detect distro ────────────────────────────────────────────────────────
if command -v apt-get &>/dev/null; then
  PKG_MANAGER="apt"
elif command -v pacman &>/dev/null; then
  PKG_MANAGER="pacman"
else
  echo "  ERROR: Unsupported distro — only apt (Ubuntu/Debian/Pi OS) and pacman (Arch) supported."
  exit 1
fi

# ── Install packages ─────────────────────────────────────────────────────
echo "  [1/5] Installing packages..."

if [ "$PKG_MANAGER" = "apt" ]; then
  apt-get update -qq
  apt-get install -y -qq chromium-browser xorg openbox x11-xserver-utils unclutter 2>/dev/null || \
  apt-get install -y -qq chromium xorg openbox x11-xserver-utils unclutter
  CHROMIUM_BIN=$(command -v chromium-browser || command -v chromium)
else
  pacman -Sy --noconfirm chromium xorg-server xorg-xinit openbox unclutter
  CHROMIUM_BIN=$(command -v chromium)
fi

echo "  Chromium found at: $CHROMIUM_BIN"

# ── Copy app files ───────────────────────────────────────────────────────
echo "  [2/5] Installing app files to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
cp "$SCRIPT_DIR/index.html" "$INSTALL_DIR/index.html"
chown -R "$TV_USER:$TV_USER" "$INSTALL_DIR"

# ── Systemd service ──────────────────────────────────────────────────────
echo "  [3/5] Installing systemd service..."
SERVICE_FILE="/etc/systemd/system/nort-tv@.service"

cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Nort TV UI
After=network-online.target
Wants=network-online.target

[Service]
User=%i
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/%i/.Xauthority
Environment=XDG_RUNTIME_DIR=/run/user/$(id -u "$TV_USER")
ExecStartPre=/bin/sleep 2
ExecStart=$CHROMIUM_BIN \\
  --kiosk \\
  --noerrdialogs \\
  --disable-infobars \\
  --no-first-run \\
  --disable-translate \\
  --disable-features=TranslateUI \\
  --disable-session-crashed-bubble \\
  --check-for-update-interval=31536000 \\
  --app=file:///opt/nort-tv/index.html
Restart=always
RestartSec=5

[Install]
WantedBy=graphical.target
EOF

systemctl daemon-reload
systemctl enable "nort-tv@$TV_USER.service"

# ── Auto-login ───────────────────────────────────────────────────────────
echo "  [4/5] Setting up auto-login on tty1..."
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $TV_USER --noclear %I \$TERM
EOF

# ── Openbox autostart (launches on login) ────────────────────────────────
echo "  [5/5] Configuring display startup..."

# .bash_profile: starts X automatically when logging in on tty1
BASH_PROFILE="$TV_HOME/.bash_profile"
if ! grep -q "startx" "$BASH_PROFILE" 2>/dev/null; then
  cat >> "$BASH_PROFILE" << 'PROFILE'

# Nort TV: start X on tty1 login
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
  exec startx
fi
PROFILE
fi

# Openbox autostart
OPENBOX_DIR="$TV_HOME/.config/openbox"
mkdir -p "$OPENBOX_DIR"
cat > "$OPENBOX_DIR/autostart" << AUTOSTART
# Disable screen blanking / DPMS
xset s off
xset -dpms
xset s noblank

# Hide cursor after 1s idle
unclutter -idle 1 &

# Launch Nort TV
$CHROMIUM_BIN \\
  --kiosk \\
  --noerrdialogs \\
  --disable-infobars \\
  --no-first-run \\
  --check-for-update-interval=31536000 \\
  --app=file:///opt/nort-tv/index.html &
AUTOSTART

chown -R "$TV_USER:$TV_USER" "$TV_HOME/.config" "$BASH_PROFILE" 2>/dev/null || true

# ── Done ─────────────────────────────────────────────────────────────────
echo ""
echo "  ✓ Installation complete!"
echo ""
echo "  Useful commands:"
echo "    sudo systemctl status nort-tv@$TV_USER   — check if running"
echo "    sudo systemctl restart nort-tv@$TV_USER  — restart after changes"
echo "    journalctl -u nort-tv@$TV_USER -f        — view live logs"
echo ""
echo "  To update the UI after editing index.html:"
echo "    sudo cp index.html /opt/nort-tv/index.html"
echo "    sudo systemctl restart nort-tv@$TV_USER"
echo ""
echo "  Reboot to go fullscreen:  sudo reboot"
echo ""
