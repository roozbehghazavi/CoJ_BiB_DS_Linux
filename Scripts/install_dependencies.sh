#!/bin/bash
# ===============================================================
# Ubuntu 24.04 LTS – Wine + X11VNC + Fluxbox environment
# ===============================================================

echo "🔄 Updating system packages..."
sudo apt update && sudo apt upgrade -y

echo "🧩 Installing essential system utilities..."
sudo apt install -y software-properties-common wget curl cabextract gnupg2 apt-transport-https

echo "🪟 Adding 32-bit architecture for Wine..."
sudo dpkg --add-architecture i386

echo "📦 Installing X11, VNC, and lightweight desktop..."
sudo apt install -y xvfb x11vnc fluxbox xauth xinit dbus-x11 unzip net-tools

echo "🍷 Adding WineHQ repository..."
sudo mkdir -pm755 /etc/apt/keyrings
sudo wget -qO /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
sudo wget -qNP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/noble/winehq-noble.sources

echo "🔁 Updating package lists..."
sudo apt update

echo "🍇 Installing Wine Stable (with 32-bit support)..."
sudo apt install -y --install-recommends winehq-stable winbind

echo "🧹 Cleaning up..."
sudo apt autoremove -y
sudo apt clean

echo "✅ All dependencies installed successfully!"

