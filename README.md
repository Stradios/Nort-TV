# Nort TV

A minimal fullscreen TV UI — currently shows your background wallpaper and a clock.
Built to run on Ubuntu Server, Debian, Raspberry Pi OS Lite, or Arch Linux.

## What this does right now
- Boots straight to a fullscreen background (your Watchtower image)
- Shows a live clock and date in the bottom-left corner
- Hides the mouse cursor automatically
- Survives reboots — starts automatically via systemd
- SSH still works — the server is untouched underneath

## Install on Ubuntu Server

```bash
# 1. Copy this folder to your machine (USB, git clone, scp, etc.)
git clone https://github.com/YOUR_USERNAME/nort-tv

# 2. Run the installer as root
cd nort-tv
sudo bash scripts/install.sh

# 3. Reboot
sudo reboot
```

That's it. On reboot the machine logs in automatically and launches the UI fullscreen.

## File structure

```
nort-tv/
├── index.html          ← The actual UI (edit this to change the interface)
├── scripts/
│   ├── install.sh      ← One-shot installer for Ubuntu/Debian/Pi OS
│   └── nort-tv@.service ← Systemd service file
└── README.md
```

## Changing the background

Edit `index.html` and find this line:

```css
background-image: url('YOUR_IMAGE_URL_HERE');
```

Replace the URL with any image URL or a local file path like `file:///opt/nort-tv/bg.jpg`.
Then copy the new `index.html` to `/opt/nort-tv/index.html` and refresh.

## Useful commands

```bash
# Check if the service is running
sudo systemctl status nort-tv@YOUR_USERNAME

# Restart the UI (if you updated index.html)
sudo systemctl restart nort-tv@YOUR_USERNAME

# Stop the UI (returns to normal terminal)
sudo systemctl stop nort-tv@YOUR_USERNAME

# View logs if something goes wrong
journalctl -u nort-tv@YOUR_USERNAME -f
```

## Coming next
- App launcher grid
- Browser mode with ad blocking
- Settings panel
- Gamepad / remote control navigation
