#!/bin/bash
# ===============================================================
# Wine Prefix Setup for Call of Juarez 2 + GameRanger
# Installs essential Windows dependencies using winetricks
# ===============================================================

# --- Configuration ---
export WINEPREFIX=/root/wine-coj2
export WINEARCH=win32
export DISPLAY=:99
export XDG_RUNTIME_DIR=/tmp/runtime-root

# --- Ensure runtime directory exists ---
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR

echo "🍷 Creating Wine prefix at $WINEPREFIX ..."
wineboot --init

echo "🧰 Installing Winetricks..."
sudo apt install -y winetricks

echo "🔧 Installing required Wine components..."
# ---------------------------------------------------------------
# dotnet40      - Required for GameRanger & CoJ controller
# vcrun2005-2015 - Common Visual C++ runtimes
# d3dx9_43, d3dcompiler_43 - DirectX shader compilers
# corefonts     - Basic Windows fonts
# win10         - Sets Windows 10 compatibility mode
# mfc42         - Requiered for Gameranger Installation
# ---------------------------------------------------------------
winetricks -q \
    dotnet40 \
    vcrun2005 vcrun2008 vcrun2010 vcrun2012 vcrun2013 vcrun2015 \
    d3dx9_43 d3dcompiler_43 \
    corefonts mfc42 \
    win10

echo "🧩 Disabling crash dialogs..."
winetricks nocrashdialog

echo "🪟 Setting DirectX to native mode..."
wine reg add "HKCU\\Software\\Wine\\Direct3D" /v DirectDrawRenderer /t REG_SZ /d opengl /f


echo "✅ Wine prefix setup complete!"
echo ""
echo "📂 Prefix path: $WINEPREFIX"

