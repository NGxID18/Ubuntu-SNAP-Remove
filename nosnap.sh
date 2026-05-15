#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root: sudo ./nosnap.sh"
  exit
fi

echo "=== Starting Snap Removal Process ==="

# 1. Remove all Snap packages (Ordered based on your specific list)
echo "Removing application packages..."
snap remove --purge firefox
snap remove --purge snap-store
snap remove --purge firmware-updater
snap remove --purge desktop-security-center
snap remove --purge prompting-client
snap remove --purge snapd-desktop-integration

echo "Removing runtimes and theme packages..."
snap remove --purge gtk-common-themes
snap remove --purge gnome-46-2404
snap remove --purge mesa-2404
snap remove --purge core24
snap remove --purge bare
snap remove --purge snapd

# 2. Purge the snapd daemon from the system
echo "Purging snapd daemon..."
apt purge snapd -y
apt autoremove --purge -y

# 3. Clean up remaining directories
echo "Cleaning up leftover directories and cache..."
rm -rf /var/snap
rm -rf /var/lib/snapd
rm -rf /var/cache/snapd
rm -rf ~/snap

# 4. Apply APT Pinning to block Snap permanently
echo "Configuring APT to block snapd reinstallation..."
cat <<EOF > /etc/apt/preferences.d/nosnap.pref
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF

echo "=== PROCESS COMPLETE ==="
echo "Snap has been completely removed and blocked from your system."
