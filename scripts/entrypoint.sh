#!/bin/bash
# ================================================================
# Entrypoint for CoJ2 Dedicated Server container
# Starts: Xvfb → x11vnc → Fluxbox → (optionally) CoJ2 Controller
# ================================================================
set -euo pipefail

DISPLAY_NUM=":99"
VNC_PORT="${VNC_PORT:-6900}"
RESOLUTION="${RESOLUTION:-1280x1024x24}"
VNC_PASS="${VNC_PASS:-}"             # Set this env var to add a VNC password
AUTO_START="${AUTO_START:-false}"    # Set to "true" to auto-launch the controller

export DISPLAY="$DISPLAY_NUM"
export WINEPREFIX="${WINEPREFIX:-/root/wine-coj2}"
export WINEARCH=win32
export WINEDEBUG=-all
export XDG_RUNTIME_DIR=/tmp/runtime-root

# ── Cleanup stale locks from previous runs ──────────────────────
mkdir -p "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR"
rm -f /tmp/.X99-lock /tmp/.X11-unix/X99 2>/dev/null || true

# ── Start Xvfb ──────────────────────────────────────────────────
echo "[entrypoint] Starting Xvfb on $DISPLAY_NUM ($RESOLUTION)..."
Xvfb "$DISPLAY_NUM" -ac -screen 0 "$RESOLUTION" &
XVFB_PID=$!
sleep 2

# Verify Xvfb is running
if ! kill -0 "$XVFB_PID" 2>/dev/null; then
    echo "[entrypoint] ERROR: Xvfb failed to start. Exiting."
    exit 1
fi
echo "[entrypoint] Xvfb started (PID $XVFB_PID)."

# ── Start x11vnc ────────────────────────────────────────────────
echo "[entrypoint] Starting x11vnc on port $VNC_PORT..."
VNC_OPTS="-display ${DISPLAY_NUM}.0 -forever -rfbport $VNC_PORT -noxrecord -noxfixes -noxdamage"

if [[ -n "$VNC_PASS" ]]; then
    echo "$VNC_PASS" | x11vnc -storepasswd /tmp/vncpass
    VNC_OPTS="$VNC_OPTS -rfbauth /tmp/vncpass"
    echo "[entrypoint] VNC password protection enabled."
else
    echo "[entrypoint] WARNING: VNC is running WITHOUT a password."
    VNC_OPTS="$VNC_OPTS -nopw"
fi

# shellcheck disable=SC2086
x11vnc $VNC_OPTS -bg -logfile /var/log/x11vnc.log
sleep 1
echo "[entrypoint] x11vnc started."

# ── Start Fluxbox ────────────────────────────────────────────────
echo "[entrypoint] Starting Fluxbox window manager..."
fluxbox &>/var/log/fluxbox.log &
sleep 2
echo "[entrypoint] Fluxbox started."

# ── Auto-launch controller if requested ─────────────────────────
if [[ "$AUTO_START" == "true" ]]; then
    echo "[entrypoint] AUTO_START=true — launching CoJ2 Controller..."
    /scripts/launch_controller.sh
fi

# ── Keep container alive (tail logs so docker logs works) ───────
echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   CoJ2 Dedicated Server container is running    ║"
echo "║                                                  ║"
echo "║  VNC  →  <host-ip>:${VNC_PORT}                       ║"
echo "║  Game →  <host-ip>:${COJ_PORT:-27632}/udp             ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# Wait on Xvfb; if it dies the container exits cleanly
wait "$XVFB_PID"
