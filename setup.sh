#!/bin/bash

# Ensure the script is run with root privileges
if [ "$EUID" -ne 0 ]; then 
  echo "Please run this script as root (e.g., sudo bash setup.sh)"
  exit
fi

# ---------------------------------------------------------
# DETECT REAL UNPRIVILEGED USER
# ---------------------------------------------------------
# Required to place the Fastfetch configuration in the correct user's home directory
ACTUAL_USER=${SUDO_USER:-$(logname)}
USER_HOME=$(eval echo ~$ACTUAL_USER)

echo "========================================="
echo "     STARTING SNAP REMOVAL PROCESS"
echo "========================================="

echo "[1/4] Removing Snap application packages..."
snap remove --purge firefox
snap remove --purge snap-store
snap remove --purge firmware-updater
snap remove --purge desktop-security-center
snap remove --purge prompting-client
snap remove --purge snapd-desktop-integration

echo "[2/4] Removing runtimes and theme packages..."
snap remove --purge gtk-common-themes
snap remove --purge gnome-46-2404
snap remove --purge mesa-2404
snap remove --purge core24
snap remove --purge bare
snap remove --purge snapd

echo "[3/4] Purging snapd daemon via APT..."
apt purge snapd -y
apt autoremove --purge -y

echo "[4/4] Cleaning up remaining Snap directories and cache..."
rm -rf /var/snap
rm -rf /var/lib/snapd
rm -rf /var/cache/snapd
rm -rf "$USER_HOME/snap"

echo "Configuring APT to permanently block snapd reinstallation..."
cat <<EOF > /etc/apt/preferences.d/nosnap.pref
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF
echo "-> Snap has been completely removed and blocked."
echo ""

echo "========================================="
echo " STARTING FLATPAK & GNOME SOFTWARE SETUP"
echo "========================================="

echo "[1/3] Updating APT package database..."
apt update

echo "[2/3] Installing Flatpak and GNOME Software plugin..."
apt install -y flatpak gnome-software gnome-software-plugin-flatpak

echo "[3/3] Adding Flathub remote repository..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
echo "-> Flatpak and Flathub have been successfully configured."
echo ""

echo "========================================="
echo "   STARTING FASTFETCH INSTALL & CONFIG"
echo "========================================="

echo "[1/3] Installing Fastfetch package..."
apt install -y fastfetch

echo "[2/3] Preparing configuration directory for user: $ACTUAL_USER..."
mkdir -p "$USER_HOME/.config/fastfetch"

echo "[3/3] Writing custom config.jsonc file..."
# Single quotes around 'EOF' prevent Bash from expanding variables inside the JSON text
cat << 'EOF' > "$USER_HOME/.config/fastfetch/config.jsonc"
{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/master/doc/json_schema.json",
  "display": {
    "separator": ": ",
    "percent": {
      "type": 2
    }
  },
  "modules": [
    "title",
    "separator",
    { "type": "uptime", "key": "Uptime          ", "keyColor": "yellow" },
    { "type": "os", "key": "OS              ", "keyColor": "yellow" },
    { "type": "kernel", "key": "Kernel          ", "keyColor": "yellow" },
    { "type": "de", "key": "DE              ", "keyColor": "yellow" },
    { "type": "wm", "key": "WM              ", "keyColor": "yellow" },
    { "type": "packages", "key": "Packages        ", "keyColor": "yellow" },
    {
      "type": "command",
      "key": "AppImages       ",
      "keyColor": "yellow",
      "text": "find $HOME -maxdepth 2 -name '*.AppImage' 2>/dev/null | wc -l"
    },
    { "type": "shell", "key": "Shell           ", "keyColor": "yellow" },
    { "type": "terminal", "key": "Terminal        ", "keyColor": "yellow" },
    "break",
    { "type": "display", "key": "Display         ", "keyColor": "magenta" },
    { "type": "host", "key": "Host            ", "keyColor": "magenta" },
    { "type": "cpu", "key": "CPU             ", "keyColor": "magenta" },
    { "type": "gpu", "key": "GPU             ", "keyColor": "magenta" },
    {
      "type": "command",
      "key": "Memory          ",
      "keyColor": "magenta",
      "shell": "/bin/bash",
      "text": "free -m | awk 'NR==2 {u=$3; t=$2; p=(t>0)?(u/t*100):0; b=\"[ \"; for(i=0;i<10;i++) b=b(i<int(p/10)?\"\u001b[1;32m█\u001b[0m\":\"-\"); b=b\" ]\"; printf \"%s \u001b[1;32m%d%%\u001b[0m %.2f GiB / %.2f GiB\", b, p, u/1024, t/1024}'"
    },
    {
      "type": "command",
      "key": "Swap            ",
      "keyColor": "magenta",
      "shell": "/bin/bash",
      "text": "free -m | awk 'NR==3 {u=$3; t=$2; p=(t>0)?(u/t*100):0; b=\"[ \"; for(i=0;i<10;i++) b=b(i<int(p/10)?\"\u001b[1;32m█\u001b[0m\":\"-\"); b=b\" ]\"; printf \"%s \u001b[1;32m%d%%\u001b[0m %.2f GiB / %.2f GiB\", b, p, u/1024, t/1024}'"
    },
    "break",
    {
        "type": "command",
        "key": "                ",
        "separator": "  ",
        "shell": "/bin/bash",
        "text": "C=48; P=50; out=\"\"; for d in $(lsblk -ndpo NAME | grep -vE 'loop|ram'); do m=$(lsblk -ndpo MODEL \"$d\" | xargs); [ -z \"$m\" ] && m=$(basename \"$d\"); parts=$(lsblk -npo MOUNTPOINT,SIZE,FSUSE%,FSUSED,FSTYPE \"$d\" | awk '$1 ~ \"^/\"'); if [ -n \"$parts\" ]; then out+=\"\\r\\e[${C}G\\e[1;36m${m}\\e[0m\\e[K\\n\"; while read -r mp size perc used fstype; do u=${perc//%/}; [ -z \"$u\" ] && u=0; p=$((u/10)); b='[ '; for((i=0;i<10;i++)); do [ $i -lt $p ] && b+='\\e[1;32m█\\e[0m' || b+='-'; done; b+=' ]'; if [ \"$mp\" = \"/\" ]; then s_mp=\"/\"; else s_mp=\"/$(basename \"$mp\")\"; fi; printf -v line \"\\r\\e[${P}G%-14s: %b \\e[1;32m%s\\e[0m %s / %s - %s\\e[K\\n\" \"($s_mp)\" \"$b\" \"$perc\" \"$used\" \"$size\" \"$fstype\"; out+=\"$line\"; done <<< \"$parts\"; fi; done; echo -ne \"${out%\\n}\""
    },
    "break",
    {
        "type": "command",
        "key": "LAN - enp5s0    ",
        "keyColor": "blue",
        "shell": "/bin/bash",
        "text": "ip -4 addr show enp5s0 | grep -oP '(?<=inet\\s)\\d+(\\.\\d+){3}' || echo 'Disconnected'"
    },
    {
        "type": "command",
        "key": "Wifi - wlp6s0   ",
        "keyColor": "blue",
        "shell": "/bin/bash",
        "text": "ip -4 addr show wlp6s0 | grep -oP '(?<=inet\\s)\\d+(\\.\\d+){3}' || echo 'Disconnected'"
    },
    {
        "type": "command",
        "key": "VPN - tailscale0",
        "keyColor": "blue",
        "shell": "/bin/bash",
        "text": "ip -4 addr show tailscale0 | grep -oP '(?<=inet\\s)\\d+(\\.\\d+){3}' || echo 'Disconnected'"
    },
    "break",
    "colors"
  ]
}
EOF

# Restore proper file ownership to the real non-root user
chown -R $ACTUAL_USER:$ACTUAL_USER "$USER_HOME/.config/fastfetch"
echo "-> Fastfetch configuration successfully created."
echo ""

echo "========================================="
echo "         SETUP PROCESS COMPLETE"
echo "========================================="
echo "Please restart your system to ensure all changes and GNOME Software integration take effect."
