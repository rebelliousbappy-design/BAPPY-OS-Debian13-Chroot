#!/data/data/com.termux/files/usr/bin/bash
# BAPPY-OS (Debian 13 Trixie Chroot) Official Automated Installer
# Target: Android 16 (KernelSU Root, 3.6GB/4GB RAM)
# STRICT RULE: Zero -c flags used anywhere in this script.

set -e

CHROOT_PATH="/data/data/com.termux/files/home/.suroot/debian-chroot"
HOME_DIR="/data/data/com.termux/files/home"
REPO_ZIP_URL="https://githubusercontent.com"

echo "=================================================="
echo "  BAPPY-OS (Debian 13 Trixie) Installer Starting  "
echo "=================================================="

# 1. Verify root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "[ERROR] Enter root# shell first using 'tsu', then run: bash install-bappy-os.sh"
    exit 1
fi

# 2. Verify Termux host tools (must be installed in normal $ mode before running tsu)
echo "[1/7] Checking Termux host dependencies..."
for cmd in debootstrap wget unzip tar; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "[ERROR] '$cmd' is missing! Exit root, run 'pkg install -y debootstrap wget unzip tar' in normal $ mode, then run 'tsu' again."
        exit 1
    fi
done

# 3. Two-Stage Native Bootstrap (Avoids Termux proot crash in root mode)
if [ ! -d "$CHROOT_PATH/bin" ]; then
    echo "[2/7] Bootstrapping Debian 13 Trixie ARM64 (Stage 1: Foreign Fetch)..."
    /system/bin/mkdir -p "$CHROOT_PATH"
    debootstrap --no-check-gpg --foreign --arch=arm64 trixie "$CHROOT_PATH" http://debian.org
else
    echo "[2/7] Existing Debian rootfs detected. Skipping Stage 1..."
fi

# 4. Mount virtual filesystems early so Stage 2 runs natively inside KernelSU chroot
echo "[3/7] Mounting virtual filesystems..."
/system/bin/mkdir -p "$CHROOT_PATH/dev/pts" "$CHROOT_PATH/dev/shm" "$CHROOT_PATH/proc" "$CHROOT_PATH/sys" "$CHROOT_PATH/root/Pictures"
/system/bin/mount | /system/bin/grep -q "$CHROOT_PATH/dev " || /system/bin/mount --bind /dev "$CHROOT_PATH/dev"
/system/bin/mount | /system/bin/grep -q "$CHROOT_PATH/dev/pts" || /system/bin/mount --bind /dev/pts "$CHROOT_PATH/dev/pts"
/system/bin/mount | /system/bin/grep -q "$CHROOT_PATH/proc" || /system/bin/mount -t proc proc "$CHROOT_PATH/proc"
/system/bin/mount | /system/bin/grep -q "$CHROOT_PATH/sys" || /system/bin/mount -t sysfs sysfs "$CHROOT_PATH/sys"
/system/bin/mount | /system/bin/grep -q "$CHROOT_PATH/dev/shm" || /system/bin/mount -t tmpfs -o size=1G,noatime tmpfs "$CHROOT_PATH/dev/shm"
/system/bin/mount | /system/bin/grep -q "$CHROOT_PATH/root/Pictures" || /system/bin/mount --bind -o noatime /sdcard "$CHROOT_PATH/root/Pictures"

if [ -d "$CHROOT_PATH/debootstrap" ]; then
    echo "[4/7] Completing Debian 13 Base System (Stage 2: Native Chroot)..."
    /system/bin/env -i HOME=/root TERM=$TERM USER=root PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
        /system/bin/chroot "$CHROOT_PATH" /debootstrap/debootstrap --second-stage
fi

# 5. Configure DNS & Hostname
echo "[5/7] Configuring DNS and Hostname..."
/system/bin/echo "nameserver 1.1.1.1" > "$CHROOT_PATH/etc/resolv.conf"
/system/bin/echo "nameserver 8.8.8.8" >> "$CHROOT_PATH/etc/resolv.conf"
/system/bin/echo "bappy-os" > "$CHROOT_PATH/etc/hostname"
/system/bin/echo "127.0.0.1 localhost bappy-os" > "$CHROOT_PATH/etc/hosts"

# 6. Download & Install Controller Scripts + Custom Tools
echo "[6/7] Downloading and installing BAPPY-OS Scripts..."
wget -O "$HOME_DIR/BAPPY-OS-Scripts.zip" "$REPO_ZIP_URL"
/system/bin/mkdir -p "$CHROOT_PATH/usr/local/bin"
unzip -jo "$HOME_DIR/BAPPY-OS-Scripts.zip" -d "$HOME_DIR/"
/system/bin/chmod +x "$HOME_DIR/start" "$HOME_DIR/stop" "$HOME_DIR/login" "$HOME_DIR/backup" 2>/dev/null || true
/system/bin/rm -f "$HOME_DIR/BAPPY-OS-Scripts.zip"

# 7. Install Desktop Environment, GIS/CAD/Office Suite & Configure TigerVNC
echo "[7/7] Installing XFCE4, TigerVNC, QGIS, LibreCAD, and Office Suite..."
cat << 'CHROOT_EOF' > "$CHROOT_PATH/root/setup-inside-chroot.sh"
#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

apt update && apt upgrade -y
apt install -y \
    xfce4 xfce4-goodies tigervnc-standalone-server tigervnc-common \
    dbus-x11 rofi python3 python3-tk python3-psutil libx11-dev \
    qgis librecad libreoffice-writer libreoffice-calc \
    mesa-utils fastfetch htop nano curl wget git

mkdir -p /root/.vnc
cat << 'VNC_EOF' > /root/.vnc/xstartup
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export LP_NUM_THREADS=4
export mesa_glthread=true
exec startxfce4
VNC_EOF
chmod +x /root/.vnc/xstartup

echo "bappyos" | vncpasswd -f > /root/.vnc/passwd
chmod 600 /root/.vnc/passwd
CHROOT_EOF

/system/bin/chmod +x "$CHROOT_PATH/root/setup-inside-chroot.sh"

/system/bin/env -i HOME=/root TERM=$TERM USER=root LANG=en_US.UTF-8 PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    /system/bin/chroot "$CHROOT_PATH" /bin/bash /root/setup-inside-chroot.sh

echo "=================================================="
echo "  BAPPY-OS INSTALLATION COMPLETE!                 "
echo "  Run './start' and open AVNC on 127.0.0.1:5901   "
echo "=================================================="
