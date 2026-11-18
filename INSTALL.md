# Quick Installation Guide for BAPPY-OS Scripts

1. Copy all custom tools from `scripts/` to `/usr/local/bin/` inside your Debian 13 Chroot:
   ```bash
   cp scripts/* /usr/local/bin/
   chmod +x /usr/local/bin/*
   ```

2. Copy autostart configurations to `~/.config/autostart/`:
   ```bash
   mkdir -p ~/.config/autostart
   cp configs/autostart/*.desktop ~/.config/autostart/
   ```

3. Replace `~/.vnc/xstartup` with `configs/xstartup` and make it executable:
   ```bash
   cp configs/xstartup ~/.vnc/xstartup
   chmod +x ~/.vnc/xstartup
   ```

4. Set your own VNC password inside chroot using `vncpasswd`.
5. Launch your VNC session from Termux Root (`tsu`) using `./START` and connect via AVNC at `localhost:5901`.
