#!/bin/bash
# ============================================================
#  Nort TV — uninstaller
#  Removes everything the installer put on the system
#  Run as root: sudo bash uninstall.sh
# ============================================================

set -e

echo ""
echo "  Nort TV — uninstaller"
echo "  ====================="
echo ""

# ── Preflight ─────────────────────────────────────────────────────────
if [ "$(id -u)" -ne 0 ]; then
  echo "  ERROR: Please run as root: sudo bash uninstall.sh"
  exit 1
fi

if [ -z "$SUDO_USER" ]; then
  echo "  ERROR: Could not detect your username. Run with sudo, not as root directly."
  exit 1
fi

TV_USER="$SUDO_USER"
TV_HOME="/home/$TV_USER"

echo "  Removing installation for user: $TV_USER"
echo ""

# ── 1. Stop and disable the systemd service ───────────────────────────
echo "  [1/6] Stopping systemd service..."
systemctl stop "nort-tv@$TV_USER.service" 2>/dev/null && echo "        Stopped nort-tv@$TV_USER" || echo "        (service was not running)"
systemctl disable "nort-tv@$TV_USER.service" 2>/dev/null && echo "        Disabled nort-tv@$TV_USER" || echo "        (service was not enabled)"

# ── 2. Remove the service file ────────────────────────────────────────
echo "  [2/6] Removing service file..."
if [ -f /etc/systemd/system/nort-tv@.service ]; then
  rm /etc/systemd/system/nort-tv@.service
  echo "        Removed /etc/systemd/system/nort-tv@.service"
else
  echo "        (not found — skipping)"
fi
systemctl daemon-reload

# ── 3. Remove auto-login override ────────────────────────────────────
echo "  [3/6] Removing auto-login config..."
if [ -f /etc/systemd/system/getty@tty1.service.d/autologin.conf ]; then
  rm /etc/systemd/system/getty@tty1.service.d/autologin.conf
  rmdir /etc/systemd/system/getty@tty1.service.d 2>/dev/null || true
  systemctl daemon-reload
  echo "        Removed auto-login override"
else
  echo "        (not found — skipping)"
fi

# ── 4. Remove openbox autostart ───────────────────────────────────────
echo "  [4/6] Removing openbox autostart..."
OPENBOX_AUTOSTART="$TV_HOME/.config/openbox/autostart"
if [ -f "$OPENBOX_AUTOSTART" ]; then
  rm "$OPENBOX_AUTOSTART"
  echo "        Removed $OPENBOX_AUTOSTART"
  # Remove the openbox dir if it's now empty
  rmdir "$TV_HOME/.config/openbox" 2>/dev/null && echo "        Removed empty openbox config dir" || true
else
  echo "        (not found — skipping)"
fi

# ── 5. Remove startx line from .bash_profile ─────────────────────────
echo "  [5/6] Cleaning .bash_profile..."
BASH_PROFILE="$TV_HOME/.bash_profile"
if [ -f "$BASH_PROFILE" ] && grep -q "startx" "$BASH_PROFILE"; then
  # Remove the block we added (comment + if block)
  sed -i '/# Nort TV: start X on tty1 login/,/^fi$/d' "$BASH_PROFILE"
  # Also clean up any blank lines left at end of file
  sed -i -e :a -e '/^\s*$/{$d;N;ba}' "$BASH_PROFILE"
  echo "        Removed startx block from $BASH_PROFILE"
else
  echo "        (nothing to remove)"
fi

# ── 6. Remove app files ───────────────────────────────────────────────
echo "  [6/6] Removing app files..."
if [ -d /opt/nort-tv ]; then
  rm -rf /opt/nort-tv
  echo "        Removed /opt/nort-tv"
else
  echo "        (not found — skipping)"
fi

# ── Done ─────────────────────────────────────────────────────────────
echo ""
echo "  ✓ Nort TV has been fully removed."
echo ""
echo "  What was removed:"
echo "    - systemd service (nort-tv@$TV_USER)"
echo "    - auto-login on tty1"
echo "    - openbox autostart config"
echo "    - startx block in ~/.bash_profile"
echo "    - app files in /opt/nort-tv"
echo ""
echo "  What was NOT touched:"
echo "    - chromium, openbox, xorg (packages left installed)"
echo "    - all other system config and services"
echo "    - your SSH access and other running services"
echo ""
echo "  To also remove the packages if you want:"
echo "    sudo apt remove --purge openbox unclutter x11-xserver-utils"
echo "    (leave chromium unless you specifically want it gone)"
echo ""
echo "  Reboot to return to a clean terminal: sudo reboot"
echo ""
