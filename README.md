# Nort TV

A fullscreen TV UI for Linux — built to run on Ubuntu Server, Debian, Raspberry Pi OS Lite, or Arch Linux. Currently shows your Watchtower background with a live clock. More features coming.

## What it does right now

- Boots straight to a fullscreen background (Watchtower image)
- Live clock and date — bottom left corner
- Mouse cursor hidden automatically
- Survives reboots — starts via systemd on every boot
- SSH still works — nothing on your server is touched

## Install

```bash
# Clone the repo
git clone https://github.com/Stradios/Nort-TV
cd Nort-TV

# Run the installer as root
sudo bash install.sh

# Reboot — the UI appears fullscreen automatically
sudo reboot
```

That's it. The installer handles everything: packages, autostart, auto-login, Chromium kiosk setup.

## File structure

```
Nort-TV/
├── index.html         ← The UI — edit this to change anything
├── install.sh         ← One-shot installer for Ubuntu/Debian/Pi OS/Arch
├── nort-tv@.service   ← Systemd service (install.sh uses this automatically)
└── README.md
```

## Updating the UI

After editing `index.html` locally, push to GitHub and pull on your machine:

```bash
# On your Ubuntu/Pi machine:
cd Nort-TV
git pull
sudo cp index.html /opt/nort-tv/index.html
sudo systemctl restart nort-tv@$USER
```

Or just copy the file directly if you're editing on the machine itself:

```bash
sudo cp index.html /opt/nort-tv/index.html
sudo systemctl restart nort-tv@$USER
```

## Useful commands

```bash
# Check status
sudo systemctl status nort-tv@$USER

# Restart after a change
sudo systemctl restart nort-tv@$USER

# Stop (returns to terminal)
sudo systemctl stop nort-tv@$USER

# View live logs
journalctl -u nort-tv@$USER -f
```

## Changing the background

Open `index.html` and find this line near the top:

```css
background-image: url('https://raw.githubusercontent.com/...');
```

Replace with any image URL, or a local file:

```css
background-image: url('file:///opt/nort-tv/bg.jpg');
```

Then copy the updated file and restart as shown above.

## Coming next

- App launcher grid (D-pad navigable)
- Browser mode with built-in ad blocking
- Settings panel
- Gamepad / TV remote / HDMI-CEC support
- Background picker in the UI
