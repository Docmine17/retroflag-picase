# RetroFlag Pi Case — Safe Shutdown for Raspberry Pi OS

Safe Shutdown and Reset service for **RetroFlag Pi Cases** (**SuperPi**, **NESPi+**, **MegaPi**, and **NESPi 4**) running **Raspberry Pi OS** (Bookworm, Trixie, and earlier Debian-based releases, including RetroPie).

---

## Hardware Prerequisite

Before installing the software, make sure the physical **SAFE SHUTDOWN** switch inside the case is set to the **ON** position.

---

## Installation

### One-Line Install
Run the following command in your Raspberry Pi terminal:

```bash
wget -O - "https://raw.githubusercontent.com/Docmine17/retroflag-picase/master/install.sh" | sudo bash
```

### Local Clone Install
Alternatively, clone the repository and run the installer locally:

```bash
git clone https://github.com/Docmine17/retroflag-picase.git
cd retroflag-picase
sudo ./install.sh
```

The installer will automatically:
1. Detect your boot partition (`/boot/firmware` or `/boot`), install the `RetroFlag_pw_io.dtbo` device tree overlay, and load it at runtime via `dtoverlay`.
2. Enable `dtoverlay=RetroFlag_pw_io.dtbo` and `enable_uart=1` under `[all]` in `config.txt`.
3. Ensure the Python 3 `RPi.GPIO` library (`python3-rpi-lgpio` or `python3-rpi.gpio`) is installed.
4. Install `/opt/RetroFlag/SafeShutdown.py` and enable/start the `retroflag-picase.service` `systemd` unit immediately (**no reboot is required**).

---

## Service Management

You can check the service status and logs with `systemd`:

```bash
# Check service status
systemctl status retroflag-picase.service

# View service logs
journalctl -u retroflag-picase.service -f
```

---

## Uninstallation

To completely stop and remove the service, scripts, runtime overlay (`dtoverlay -r`), and `config.txt` changes:

```bash
wget -O - "https://raw.githubusercontent.com/Docmine17/retroflag-picase/master/uninstall.sh" | sudo bash
```

Or from a local clone:

```bash
sudo ./uninstall.sh
```

---

## GPIO Pin Mapping

| Function | BCM GPIO | Physical Pin | Direction | Active State |
| :--- | :---: | :---: | :---: | :---: |
| **Reset Button** | `BCM 2` (SDA1) | Pin 3 | Input (Pull-Up) | `LOW` when pressed |
| **Power Switch** | `BCM 3` (SCL1) | Pin 5 | Input (Pull-Up) | `LOW` when switched OFF |
| **Power Enable** | `BCM 4` (GPCLK0) | Pin 7 | Output | `HIGH` while running |
| **Power LED** | `BCM 14` (UART0 TXD) | Pin 8 | Output | `HIGH` (blinks during shutdown) |

---

## Other Distributions & Cases

- **Batocera:** Modern Batocera releases natively support RetroFlag cases without external scripts. Set `system.power.switch=RETROFLAG` in `/userdata/system/batocera.conf` and reboot (see the [Batocera Wiki](https://wiki.batocera.org/add_powerdevices_rpi_only)).
- **Recalbox:** Modern Recalbox releases include built-in auto-detection for RetroFlag cases (or can be configured via `system.power.switch=PIN356ONOFFRESET` in `recalbox.conf`; see the [Recalbox Wiki](https://wiki.recalbox.com/en/tutorials/cases/list-of-supported-cases)).
- **GPi Case / GPi Case 2:** For handheld GPi Case hardware, refer to the official [RetroFlag/retroflag-picase](https://github.com/RetroFlag/retroflag-picase) and [RetroFlag/GPiCase2-Script](https://github.com/RetroFlag/GPiCase2-Script) repositories.
