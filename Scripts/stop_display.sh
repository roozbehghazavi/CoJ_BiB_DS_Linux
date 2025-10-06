#!/bin/bash

# ------------------------------------------------------------------
# Script: stop_display.sh
# Purpose: Stop virtual display environment including Xvfb, VNC, and Fluxbox
# Usage: ./stop_display.sh
# ------------------------------------------------------------------

echo "Stopping Fluxbox, x11vnc, and Xvfb..."

# Stop Fluxbox (window manager)
kill -int $(pidof fluxbox) 2>/dev/null

# Stop x11vnc (VNC server)
kill -int $(pidof x11vnc) 2>/dev/null

# Stop Xvfb (virtual display)
kill -int $(pidof Xvfb) 2>/dev/null

echo "All GUI components stopped."

