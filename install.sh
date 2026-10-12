#!/bin/bash
set -e

SourcePath=https://raw.githubusercontent.com/Docmine17/retroflag-picase/master
ScriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"

# Check if root--------------------------------------
if [[ $EUID -ne 0 ]]; then
    echo "Please execute script as root."
    exit 1
fi
#-----------------------------------------------------------

# Detect boot directory (/boot/firmware on Bookworm+, /boot on legacy)
if [[ -d "/boot/firmware/overlays" && -f "/boot/firmware/config.txt" ]]; then
    BootDir="/boot/firmware"
else
    BootDir="/boot"
fi

File="$BootDir/config.txt"
OverlayDir="$BootDir/overlays"

# RetroFlag pw io ;2:in ;3:in ;4:in ;14:out 1----------------------------------------
if [[ -n "${BASH_SOURCE[0]}" && -f "$ScriptDir/RetroFlag_pw_io.dtbo" ]]; then
    cp "$ScriptDir/RetroFlag_pw_io.dtbo" "$OverlayDir/RetroFlag_pw_io.dtbo"
else
    wget -O "$OverlayDir/RetroFlag_pw_io.dtbo" "$SourcePath/RetroFlag_pw_io.dtbo"
fi

# Clean previous entries to avoid duplicates or placement inside model filters
sed -i --follow-symlinks '/dtoverlay=RetroFlag_pw_io/d' "$File"
sed -i --follow-symlinks '/^[[:space:]]*enable_uart=/d' "$File"

# Ensure settings are placed under the [all] section if model filters exist
LastSection=$(grep -E '^[[:space:]]*\[.*\]' "$File" | tail -n 1 | tr -d '[:space:]' || true)
if [[ -n "$LastSection" && "$LastSection" != "[all]" ]]; then
    echo "" >> "$File"
    echo "[all]" >> "$File"
fi

echo "dtoverlay=RetroFlag_pw_io.dtbo" >> "$File"
echo "PW IO enabled."
echo "enable_uart=1" >> "$File"
echo "UART enabled."

# Load overlay at runtime so no reboot is needed
if command -v dtoverlay >/dev/null 2>&1; then
    if ! dtoverlay -l | grep -q "RetroFlag_pw_io" && [[ -z "$(find /proc/device-tree/ -name 'power_pins' 2>/dev/null)" ]]; then
        dtoverlay -d "$OverlayDir" RetroFlag_pw_io 2>/dev/null || dtoverlay RetroFlag_pw_io 2>/dev/null || true
    fi
fi
#-----------------------------------------------------------

# Ensure Python 3 RPi.GPIO module is installed--------------
if ! python3 -c "import RPi.GPIO" >/dev/null 2>&1; then
    echo "Installing Python 3 GPIO dependency..."
    apt-get update
    if apt-cache show python3-rpi-lgpio >/dev/null 2>&1; then
        apt-get install -y python3-rpi-lgpio
    else
        apt-get install -y python3-rpi.gpio
    fi
fi
#-----------------------------------------------------------

# Download Python script-----------------------------
mkdir -p "/opt/RetroFlag"
script="/opt/RetroFlag/SafeShutdown.py"
if [[ -n "${BASH_SOURCE[0]}" && -f "$ScriptDir/SafeShutdown.py" ]]; then
    cp "$ScriptDir/SafeShutdown.py" "$script"
else
    wget -O "$script" "$SourcePath/SafeShutdown.py"
fi
chmod +x "$script"
#-----------------------------------------------------------

# Enable Python script to run on start up via systemd-------
if [[ -f "/etc/rc.local" ]]; then
    sed -i --follow-symlinks '/SafeShutdown\.py/d' "/etc/rc.local"
fi

ServiceFile="/etc/systemd/system/retroflag-picase.service"
cat << 'EOF' > "$ServiceFile"
[Unit]
Description=RetroFlag Pi Case Safe Shutdown Service
After=local-fs.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /opt/RetroFlag/SafeShutdown.py
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable retroflag-picase.service
systemctl restart retroflag-picase.service
echo "Systemd service retroflag-picase.service configured and started."
#-----------------------------------------------------------

echo "RetroFlag Pi Case installation done. The service is active and no reboot is required."
#-----------------------------------------------------------
