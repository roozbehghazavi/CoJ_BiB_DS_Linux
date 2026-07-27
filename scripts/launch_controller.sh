#!/bin/bash
# ================================================================
# Launch CoJ2 Server Controller
# The controller is not installed — it's just a folder of files.
# Wine runs the .exe directly from wherever it lives.
# ================================================================
export WINEPREFIX="${WINEPREFIX:-/root/wine-coj2}"
export DISPLAY="${DISPLAY:-:99}"
export WINEDEBUG=-all
export WINEDLLOVERRIDES="version=n,b"

CONTROLLER="/root/CoJ_BiB_DS_Linux/Applications/CoJ2 Controller/CoJ2Controller.exe"

if [[ ! -f "$CONTROLLER" ]]; then
    echo "[launch_controller] ERROR: Controller not found at:"
    echo "    $CONTROLLER"
    echo "  Make sure CoJ_BiB_DS_Linux/Applications/CoJ2 Controller/ is present"
    echo "  next to the Dockerfile before building the image."
    exit 1
fi

echo "[launch_controller] Starting CoJ2 Controller..."
nohup wine "$CONTROLLER" >/var/log/coj2controller.log 2>&1 &
disown

echo "[launch_controller] Controller launched. Log: /var/log/coj2controller.log"
