#!/bin/bash
# ================================================================
# Launch CoJ2 Server Controller GUI under Wine
# ================================================================
export WINEPREFIX="${WINEPREFIX:-/root/wine-coj2}"
export DISPLAY="${DISPLAY:-:99}"
export WINEDEBUG=-all

CONTROLLER="/root/CoJ_BiB_DS_Linux/Applications/CoJ2 Controller/CoJ2Controller.exe"

if [[ ! -f "$CONTROLLER" ]]; then
    echo "[launch_controller] ERROR: Controller not found at:"
    echo "    $CONTROLLER"
    echo "  Mount your game files or install them via VNC first."
    exit 1
fi

echo "[launch_controller] Starting CoJ2 Controller..."
nohup wine "$CONTROLLER" >/var/log/coj2controller.log 2>&1 &
disown

echo "[launch_controller] Controller launched (logs: /var/log/coj2controller.log)"
