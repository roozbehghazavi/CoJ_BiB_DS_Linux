#!/bin/bash
# ------------------------------------------------------------------
# Script: start_display.sh
# Purpose: Start a virtual X11 environment (Xvfb + Fluxbox + x11vnc)
# Usage: ./start_display.sh
# ------------------------------------------------------------------

DISPLAY_NUM=":99"
VNC_PORT=6900
RESOLUTION="1280x1024x24"

export DISPLAY=$DISPLAY_NUM
export XDG_RUNTIME_DIR=/tmp/runtime-root

mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

echo "[*] Starting virtual display on $DISPLAY_NUM..."

# --- Start Xvfb (Virtual X Server) ---
if ! pgrep -x "Xvfb" > /dev/null; then
    nohup Xvfb $DISPLAY_NUM -ac -screen 0 $RESOLUTION \
        > /dev/null 2>&1 &
    echo "    → Xvfb started."
else
    echo "    → Xvfb already running."
fi

# Wait a moment for Xvfb to initialize
sleep 2

# --- Start x11vnc (VNC Server) ---
if ! pgrep -x "x11vnc" > /dev/null; then
    nohup x11vnc -display $DISPLAY_NUM.0 -forever -bg -rfbport $VNC_PORT \
        > /dev/null 2>&1 &
    echo "    → x11vnc started on port $VNC_PORT."
else
    echo "    → x11vnc already running."
fi

# --- Start Fluxbox (Lightweight Window Manager) ---
if ! pgrep -x "fluxbox" > /dev/null; then
    nohup fluxbox > /dev/null 2>&1 &
    echo "    → Fluxbox window manager started."
else
    echo "    → Fluxbox already running."
fi

echo
echo "[✓] Virtual GUI environment is ready!"
echo "    Connect using a VNC client to port $VNC_PORT."
echo "    DISPLAY variable set to $DISPLAY_NUM."

