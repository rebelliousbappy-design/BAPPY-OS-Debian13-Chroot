# BAPPY-OS (Debian 13 Trixie Chroot on Android)
**Developer:** RebelliousBappy  
**Target Device:** Infinix Hot 70 (XOS 16.3, Android 16 Kernel, KernelSU Root, 3.6GB RAM)  
**Display Stack:** TigerVNC (:1) + AVNC + XFCE4 + 4-Thread Mesa Software Rendering  

## Core Custom Tools (`/usr/local/bin/`)
1. **bappy-launcher & bappy-cat.py:** Whisker-style Rofi category grid application launcher.
2. **chameleon-shift:** Dual-mode system controller (`CYBER CHILL` vs `GIS BEAST MODE` with XFWM4 compositor toggle).
3. **jarvis-voice-guard:** Automatic RAM monitor that purges pagecache when memory usage hits >=85%.
4. **bappy-power:** Rofi power menu (VNC shutdown, desktop reload, manual RAM turbo).
5. **v-enter & toggle-enter:** Floating Xlib Enter button for portrait-mode typing convenience.
6. **clean-sys:** Deep system and cache cleanup utility.
