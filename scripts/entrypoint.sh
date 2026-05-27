#!/bin/bash
# ================================================================
# Entrypoint for CoJ2 Dedicated Server container
# Starts: Xvfb → Fluxbox → x11vnc → (optionally) CoJ2 Controller
# ================================================================

# No set -e — we want the container to keep running even if
# a non-critical step fails

export DISPLAY=:99
export WINEPREFIX="${WINEPREFIX:-/root/wine-coj2}"
export WINEARCH=win32
export WINEDEBUG=-all
export WINEDLLOVERRIDES="mscoree,mshtml="
export XDG_RUNTIME_DIR=/tmp/runtime-root

VNC_PORT="${VNC_PORT:-6900}"
RESOLUTION="${RESOLUTION:-1280x1024x24}"
VNC_PASS="${VNC_PASS:-}"
AUTO_START="${AUTO_START:-false}"

# ── Cleanup stale locks ──────────────────────────────────────────
mkdir -p "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR"
rm -f /tmp/.X99-lock /tmp/.X11-unix/X99 2>/dev/null || true

# ── Start Xvfb ──────────────────────────────────────────────────
echo "[entrypoint] Starting Xvfb ($RESOLUTION)..."
Xvfb :99 -ac -screen 0 "$RESOLUTION" &
XVFB_PID=$!
sleep 2

if ! kill -0 "$XVFB_PID" 2>/dev/null; then
    echo "[entrypoint] ERROR: Xvfb failed to start."
    exit 1
fi
echo "[entrypoint] Xvfb started (PID $XVFB_PID)."

# ── Start Fluxbox ────────────────────────────────────────────────
echo "[entrypoint] Starting Fluxbox..."
fluxbox &>/var/log/fluxbox.log &
sleep 1
echo "[entrypoint] Fluxbox started."

# ── Start x11vnc ────────────────────────────────────────────────
echo "[entrypoint] Starting x11vnc on port $VNC_PORT..."

if [[ -n "$VNC_PASS" ]]; then
    # -storepasswd in non-interactive mode: pass the password directly
    # via the two-argument form which writes the file without prompting
    x11vnc -storepasswd "$VNC_PASS" /tmp/vncpass
    x11vnc \
        -display :99 \
        -forever \
        -rfbport "$VNC_PORT" \
        -rfbauth /tmp/vncpass \
        -noxrecord -noxfixes -noxdamage \
        -bg -logfile /var/log/x11vnc.log
    echo "[entrypoint] x11vnc started (password protected)."
else
    echo "[entrypoint] WARNING: VNC running without password."
    x11vnc \
        -display :99 \
        -forever \
        -rfbport "$VNC_PORT" \
        -nopw \
        -noxrecord -noxfixes -noxdamage \
        -bg -logfile /var/log/x11vnc.log
    echo "[entrypoint] x11vnc started."
fi

# ── Auto-launch controller ───────────────────────────────────────
if [[ "$AUTO_START" == "true" ]]; then
    echo "[entrypoint] AUTO_START=true — launching CoJ2 Controller..."
    sleep 1
    /scripts/launch_controller.sh
fi

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   CoJ2 Dedicated Server container is running    ║"
echo "║                                                  ║"
echo "║  VNC  →  <host-ip>:${VNC_PORT}                       ║"
echo "║  Game →  <host-ip>:${COJ_PORT:-27632}/udp             ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# Keep container alive
wait "$XVFB_PID"