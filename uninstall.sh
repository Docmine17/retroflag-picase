#!/bin/bash
set -e

# Check if root--------------------------------------
if [[ $EUID -ne 0 ]]; then
    echo "Please execute script as root."
    exit 1
fi
#-----------------------------------------------------------

# Stop and disable systemd service-------------------
ServiceFile="/etc/systemd/system/retroflag-picase.service"
if [[ -f "$ServiceFile" ]] || systemctl list-unit-files | grep -q "^retroflag-picase\.service"; then
    systemctl stop retroflag-picase.service 2>/dev/null || true
    systemctl disable retroflag-picase.service 2>/dev/null || true
    rm -f "$ServiceFile"
    systemctl daemon-reload
    echo "Systemd service retroflag-picase.service removed."
fi

# Clean legacy /etc/rc.local entry if present--------
if [[ -f "/etc/rc.local" ]]; then
    sed -i --follow-symlinks '/SafeShutdown\.py/d' "/etc/rc.local"
fi
#-----------------------------------------------------------

# Remove installed scripts---------------------------
if [[ -d "/opt/RetroFlag" ]]; then
    rm -rf "/opt/RetroFlag"
    echo "Removed /opt/RetroFlag."
fi
#-----------------------------------------------------------

# Remove overlay and config.txt entries--------------
if command -v dtoverlay >/dev/null 2>&1; then
    dtoverlay -r RetroFlag_pw_io 2>/dev/null || true
fi

for BootDir in "/boot/firmware" "/boot"; do
    OverlayFile="$BootDir/overlays/RetroFlag_pw_io.dtbo"
    if [[ -f "$OverlayFile" && ! -L "$BootDir/overlays" ]]; then
        rm -f "$OverlayFile"
        echo "Removed $OverlayFile."
    fi

    ConfigFile="$BootDir/config.txt"
    if [[ -f "$ConfigFile" && ! -L "$ConfigFile" ]]; then
        sed -i --follow-symlinks '/dtoverlay=RetroFlag_pw_io/d' "$ConfigFile"
        sed -i --follow-symlinks '/^[[:space:]]*enable_uart=1/d' "$ConfigFile"
        echo "Cleaned $ConfigFile."
    fi
done
#-----------------------------------------------------------

if [[ -n "$(find /proc/device-tree -name 'power_pins' 2>/dev/null)" ]]; then
    echo "RetroFlag Pi Case uninstallation done. Boot-loaded overlay will be unloaded on the next reboot."
else
    echo "RetroFlag Pi Case uninstallation done. No reboot is required."
fi
echo "If you keep using the case without this service, set the internal SAFE SHUTDOWN switch to OFF."
