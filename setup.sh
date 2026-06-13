#!/bin/bash

# Ensure the script is run with root privileges
if [ "$EUID" -ne 0 ]; then 
  echo "Please run this script as root (e.g., sudo bash setup.sh)"
  exit
fi

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
echo "         SETUP PROCESS COMPLETE"
echo "========================================="
echo "Please restart your system to ensure all changes and GNOME Software integration take effect."
