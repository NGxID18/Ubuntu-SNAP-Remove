#!/bin/bash

# Ensure the script is run with root privileges
if [ "$EUID" -ne 0 ]; then 
  echo "Please run this script as root (sudo bash flatpak.sh)"
  exit
fi

echo "--- Starting GNOME Software & Flatpak Configuration ---"

# 1. Update APT package database
echo "[1/4] Updating APT package lists..."
apt update

# 2. Install Flatpak and GNOME Software with Flatpak plugin
# This will allow GNOME Software to handle both .deb and Flatpak formats
echo "[2/4] Installing Flatpak and GNOME Software Plugin..."
apt install -y flatpak gnome-software gnome-software-plugin-flatpak

# 3. Add the Flathub repository
# Flathub is the primary remote repository for Flatpak applications
echo "[3/4] Adding Flathub repository..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# 4. Finalizing installation
echo "[4/4] Installation complete!"
echo "------------------------------------------------------------"
echo "Please restart your system to ensure all changes take effect"
echo "and Flathub apps appear correctly in GNOME Software."
echo "------------------------------------------------------------"
