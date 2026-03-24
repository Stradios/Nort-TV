#!/bin/bash
# Nort TV — install script for Ubuntu Server / Debian / Pi OS Lite
# Run as root: sudo bash install.sh

set -e

echo ""
echo "  Nort TV — installer"
echo "  ==================="
echo ""

# --- Detect user ---
if [ -z "$SUDO_USER" ]; then
  echo "  Run with sudo: sudo bash install.sh"
  exit 1
fi
TV_USER="$SUDO_USER"
echo "  Installing for user: $TV_USER"
echo ""

# --- Install dependencies ---
echo "  [1/4] Installing packages..."
apt-get update -qq
apt-get install -y -qq \
  chromium-browser \
  xorg \
  openbox \
  x11-xserver-utils \
  unclutter

echo "  [2/4] Copying app files..."
mkdir -p /opt/nort-tv
cp -r "$(dirname "$0")"/../* /opt/nort-tv/
chown -R "$TV_USER:$TV_USER" /opt/nort-tv

echo "  [3/4] Installing systemd service..."
cp "$(dirname "$0")"/nort-tv@.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable "nort-tv@$TV_USER.service"

echo "  [4/4] Setting up auto-login for $TV_USER..."
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $TV_USER --noclear %I \$TERM
EOF

# Auto-start X + openbox on login
BASH_PROFILE="/home/$TV_USER/.bash_profile"
if ! grep -q "startx" "$BASH_PROFILE" 2>/dev/null; then
  cat >> "$BASH_PROFILE" << 'EOF'

# Start X automatically on tty1
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
  exec startx
fi
EOF
fi

# Openbox autostart
OPENBOX_DIR="/home/$TV_USER/.config/openbox"
mkdir -p "$OPENBOX_DIR"
cat > "$OPENBOX_DIR/autostart" << EOF
# Disable screen blanking
xset s off
xset -dpms
xset s noblank

# Hide cursor after 1 second of inactivity
unclutter -idle 1 &

# Launch Nort TV
chromium-browser \\
  --kiosk \\
  --noerrdialogs \\
  --disable-infobars \\
  --no-first-run \\
  --check-for-update-interval=31536000 \\
  --app=file:///opt/nort-tv/index.html &
EOF

chown -R "$TV_USER:$TV_USER" "/home/$TV_USER/.config"
chown "$TV_USER:$TV_USER" "$BASH_PROFILE" 2>/dev/null || true

echo ""
echo "  Done! Nort TV is installed."
echo ""
echo "  To start now:  sudo systemctl start nort-tv@$TV_USER"
echo "  To test only:  reboot"
echo ""
echo "  The UI will appear fullscreen on next boot."
echo "  SSH still works normally — nothing else on the system changes."
echo ""
