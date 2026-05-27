#!/bin/bash
# ================================================================
# install_server.sh — runs inside `docker build` via RUN
# Inno Setup needs a real display even with /VERYSILENT.
# We spin up Xvfb just for this step, same as start_display.sh did.
# ================================================================

export WINEPREFIX=/root/wine-coj2
export WINEARCH=win32
export DISPLAY=:99
export XDG_RUNTIME_DIR=/tmp/runtime-root
export WINEDLLOVERRIDES="mscoree,mshtml="

mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# ── Start Xvfb ──────────────────────────────────────────────────
rm -f /tmp/.X99-lock /tmp/.X11-unix/X99 2>/dev/null || true

echo "[install_server] Starting Xvfb..."
Xvfb :99 -ac -screen 0 1280x1024x24 &
XVFB_PID=$!

# Wait for the display to be ready (same approach as start_display.sh sleep 2,
# but we poll so we don't wait longer than needed)
for i in $(seq 1 30); do
    if xdpyinfo -display :99 >/dev/null 2>&1; then
        echo "[install_server] Xvfb ready."
        break
    fi
    sleep 1
done

# ── Run the silent installer ─────────────────────────────────────
INSTALLER="/tmp/CoJ_BiB_DedicatedServer_setup.exe"
INSTALL_DIR="C:\\Program Files\\Techland\\Call of Juarez - Bound in Blood Dedicated Server"

echo "[install_server] Running silent installer..."
wine "$INSTALLER" \
    /VERYSILENT \
    /SUPPRESSMSGBOXES \
    /NORESTART \
    "/DIR=${INSTALL_DIR}" || true

wineserver --wait
echo "[install_server] Installer finished."

# ── Tear down Xvfb ──────────────────────────────────────────────
kill "$XVFB_PID" 2>/dev/null || true
wait "$XVFB_PID" 2>/dev/null || true
rm -f /tmp/.X99-lock /tmp/.X11-unix/X99 2>/dev/null || true

rm -f "$INSTALLER"
echo "[install_server] Done."