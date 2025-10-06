#!/bin/bash

# ------------------------------------------------------------------
# Script: run_coj2_gameranger.sh
# Purpose: Launch GameRanger using Wine (detached)
# ------------------------------------------------------------------

export WINEPREFIX=/root/wine-coj2
export DISPLAY=:99

nohup bash -c 'wine "/root/wine-coj2/drive_c/users/root/AppData/Roaming/GameRanger/GameRanger/GameRanger.exe"' >/dev/null 2>&1 & disown

echo "✅ GameRanger started in background."

