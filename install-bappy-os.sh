#!/data/data/com.termux/files/usr/bin/bash
# BAPPY-OS (Debian 13 Trixie Chroot) Official Automated Installer
# Target: Android 16 (KernelSU Root, 3.6GB/4GB RAM)
# STRICT RULE: Zero -c flags used anywhere in this script.

set -e

CHROOT_PATH="/data/data/com.termux/files/home/.suroot/debian-chroot"
HOME_DIR="/data/data/com.termux/files/home"
REPO_ZIP_URL="https://raw.githubusercontent"".com/rebelliousbappy-design/BAPPY-OS-Debian13-Chroot/main/BAPPY-OS-Scripts.zip"

echo "=================================================="
echo "  BAPPY-OS (Debian 13 Trixie) Installer Starting  "
echo "=================================================="

if [ "$(id -u)" -ne 0 ]; then
    echo "[ERROR] Enter root# shell first using 'tsu', then run: bash install-bappy-os.sh"
    exit 1
fi

echo "[1/7] Installing Termux host dependencies..."
pkg update -y && pkg install -y debootstrap wget unzip tar

if [ ! -d "$CHROOT_PATH/bin" ]; then
    echo "[2/7] Bootstrapping Debian 13 Trixie ARM64 into $CHROOT_PATH..."
    /system/bin/mkdir -p "$CHROOT_PATH"
    debootstrap --arch=arm64 trixie "$CHROOT_PATH" http://debian.org
else
    echo "[2/7] Existing Debian rootfs detected. Skipping debootstrap..."
fi

echo "[3/7] Configuring DNS and Hostname..."
/system/bin/echo "nameserver 1.1.1.1" > "$CHROOT_PATH/etc/resolv.conf"
/system/bin/echo "nameserver 8.8.8.8" >> "$CHROOT_PATH/etc/resolv.conf"
/system/bin/echo "bappy-os" > "$CHROOT_PATH/etc/hostname"
/system/bin/echo "127.0.0.1 localhost bappy-os" > "$CHROOT_PATH/etc/hosts"

echo "[4/7] Downloading and installing BAPPY-OS Custom Tools..."
wget -O "$HOME_DIR/BAPPY-OS-Scripts.zip" "$REPO_ZIP_URL"
/system/bin/mkdir -p "$CHROOT_PATH/usr/local/bin"
unzip -jo "$HOME_DIR/BAPPY-OS-Scripts.zip" -d "$CHROOT_PATH/usr/local/bin/"
/system/bin/chmod +x "$CHROOT_PATH/usr/local/bin/"*
/system/bin/rm -f "$HOME_DIR/BAPPY-OS-Scripts.zip"

echo "[5/7] Generating ~/start, ~/stop, and ~/login controller scripts..."
cat << 'START_EOF' > "$HOME_DIR/start"
#!/bin/bash
CHROOT_PATH=/data/data/com.termux/files/home/.suroot/debian-chroot
/system/bin/device_config put activity_manager max_phantom_processes 2147483647 2>/dev/null
/system/bin/settings put global max_phantom_processes 2147483647 2>/dev/null
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    /system/bin/echo performance > "$cpu" 2>/dev/null
done
/system/bin/mkdir -p $CHROOT_PATH/dev/pts $CHROOT_PATH/dev/shm $CHROOT_PATH/proc $CHROOT_PATH/sys $CHROOT_PATH/tmp/.X11-unix $CHROOT_PATH/root/Pictures
/system/bin/mount | /system/bin/grep -q "$CHROOT_PATH/dev " || /system/bin/mount --bind /dev $CHROOT_PATH/dev
/system/bin/mount | /system/bin/grep -q "$CHROOT_PATH/dev/pts" || /system/bin/mount --bind /dev/pts $CHROOT_PATH/dev/pts
/system/bin/mount | /system/bin/grep -q "$CHROOT_PATH/proc" || /system/bin/mount -t proc proc $CHROOT_PATH/proc
/system/bin/mount | /system/bin/grep -q "$CHROOT_PATH/sys" || /system/bin/mount -t sysfs sysfs $CHROOT_PATH/sys
/system/bin/mount | /system/bin/grep -q "$CHROOT_PATH/dev/shm" || /system/bin/mount -t tmpfs -o size=1G,noatime tmpfs $CHROOT_PATH/dev/shm
/system/bin/mount | /system/bin/grep -q "$CHROOT_PATH/root/Pictures" || /system/bin/mount --bind -o noatime /sdcard $CHROOT_PATH/root/Pictures
/system/bin/echo "nameserver 1.1.1.1" > $CHROOT_PATH/etc/resolv.conf
/system/bin/rm -f $CHROOT_PATH/tmp/.X*-lock $CHROOT_PATH/tmp/.X11-unix/X* $CHROOT_PATH/root/.vnc/*.log $CHROOT_PATH/root/.vnc/*.pid
/system/bin/env -i HOME=/root TERM=$TERM USER=root LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 LP_NUM_THREADS=4 mesa_glthread=true PATH=/usr/sbin:/usr/bin:/sbin:/bin /system/bin/chroot $CHROOT_PATH /usr/bin/vncserver :1 -geometry 1480x720 -depth 24 -dpi 96 -FrameRate 60 -ZlibLevel 0 -CompareFB 1 -AlwaysShared
/system/bin/sleep 2
/system/bin/env -i HOME=/root TERM=$TERM USER=root LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 DISPLAY=:1 /system/bin/chroot $CHROOT_PATH /usr/bin/vncconfig -nowin &
echo "BAPPY-OS Started! Connect AVNC to 127.0.0.1:5901 (Password: bappyos)"
START_EOF

cat << 'STOP_EOF' > "$HOME_DIR/stop"
#!/bin/bash
CHROOT_PATH=/data/data/com.termux/files/home/.suroot/debian-chroot
/system/bin/env -i HOME=/root TERM=$TERM USER=root PATH=/usr/sbin:/usr/bin:/sbin:/bin /system/bin/chroot $CHROOT_PATH tigervncserver -kill :1
pkill -9 -f "Xtigervnc|xfce4|dbus-daemon|freecad|librecad|qgis|vncconfig|chameleon-shift|conky|jarvis-voice-guard|v-enter|ibus-daemon" 2>/dev/null
rm -f $CHROOT_PATH/tmp/.X*-lock $CHROOT_PATH/tmp/.X11-unix/X* $CHROOT_PATH/root/.vnc/*.pid 2>/dev/null
sync
umount -l $CHROOT_PATH/root/Pictures 2>/dev/null
umount -l $CHROOT_PATH/dev/shm 2>/dev/null
umount -l $CHROOT_PATH/dev/pts 2>/dev/null
umount -l $CHROOT_PATH/dev 2>/dev/null
umount -l $CHROOT_PATH/sys 2>/dev/null
umount -l $CHROOT_PATH/proc 2>/dev/null
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    /system/bin/echo schedutil > "$cpu" 2>/dev/null
done
echo "BAPPY-OS Session Safely Stopped & Unmounted!"
STOP_EOF

cat << 'LOGIN_EOF' > "$HOME_DIR/login"
#!/bin/bash
CHROOT_PATH=/data/data/com.termux/files/home/.suroot/debian-chroot
unset LD_PRELOAD
exec chroot $CHROOT_PATH /usr/bin/env -i HOME=/root TERM=$TERM LANG=en_US.UTF-8 LP_NUM_THREADS=4 mesa_glthread=true PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin /bin/bash
LOGIN_EOF

/system/bin/chmod +x "$HOME_DIR/start" "$HOME_DIR/stop" "$HOME_DIR/login"

echo "[6/7] Preparing internal Debian 13 setup script..."
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
    mesa-utils neofetch htop nano curl wget git

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

echo "[7/7] Mounting virtual filesystems & running internal setup..."
/system/bin/mkdir -p "$CHROOT_PATH/dev/pts" "$CHROOT_PATH/dev/shm" "$CHROOT_PATH/proc" "$CHROOT_PATH/sys" "$CHROOT_PATH/root/Pictures"
/system/bin/mount --bind /dev "$CHROOT_PATH/dev" 2>/dev/null || true
/system/bin/mount --bind /dev/pts "$CHROOT_PATH/dev/pts" 2>/dev/null || true
/system/bin/mount -t proc proc "$CHROOT_PATH/proc" 2>/dev/null || true
/system/bin/mount -t sysfs sysfs "$CHROOT_PATH/sys" 2>/dev/null || true
/system/bin/mount -t tmpfs -o size=1G,noatime tmpfs "$CHROOT_PATH/dev/shm" 2>/dev/null || true
/system/bin/mount --bind -o noatime /sdcard "$CHROOT_PATH/root/Pictures" 2>/dev/null || true

/system/bin/env -i HOME=/root TERM=$TERM USER=root LANG=en_US.UTF-8 PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    /system/bin/chroot "$CHROOT_PATH" /bin/bash /root/setup-inside-chroot.sh

echo "=================================================="
echo "  BAPPY-OS INSTALLATION COMPLETE!                 "
echo "  Run './start' and open AVNC on 127.0.0.1:5901   "
echo "=================================================="
