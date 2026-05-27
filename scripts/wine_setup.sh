#!/bin/bash
# ================================================================
# wine_setup.sh — runs inside `docker build` via RUN
# Mirrors the working setup_wine.sh from bare metal exactly.
# No display needed — wineboot and winetricks run headlessly.
# ================================================================

# NOTE: intentionally no `set -e` — winetricks exits non-zero even
# on successful installs (e.g. status 43 = already installed / warning)

export WINEPREFIX=/root/wine-coj2
export WINEARCH=win32
export DISPLAY=:99
export XDG_RUNTIME_DIR=/tmp/runtime-root
# NOTE: do NOT set WINEDLLOVERRIDES="mscoree,mshtml=" here.
# That override prevents mscoree.dll (.NET runtime) from being installed,
# which breaks CoJ2Controller.exe (it's an IL-only .NET binary).
# Mono/Gecko popups are harmless during a headless build — just let them be.

mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

echo "[wine_setup] Initialising Wine prefix..."
wineboot --init
wineserver --wait

echo "[wine_setup] Installing VC++ runtimes..."
winetricks -q vcrun2005 vcrun2008 vcrun2010 vcrun2012 vcrun2013 vcrun2015 || true
wineserver --wait

echo "[wine_setup] Installing DirectX + fonts + MFC..."
winetricks -q d3dx9_43 d3dcompiler_43 corefonts mfc42 || true
wineserver --wait

echo "[wine_setup] Setting win10 compat + tweaks..."
winetricks -q win10 || true
winetricks nocrashdialog || true
wine reg add "HKCU\\Software\\Wine\\Direct3D" \
    /v DirectDrawRenderer /t REG_SZ /d opengl /f || true
wineserver --wait

echo "[wine_setup] Installing dotnet40..."
winetricks -q dotnet40 || true
wineserver --wait

echo "[wine_setup] All done."