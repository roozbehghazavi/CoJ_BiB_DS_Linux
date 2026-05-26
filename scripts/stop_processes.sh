#!/bin/bash
# ================================================================
# Stop all CoJ2-related Wine processes inside the container
# ================================================================
echo "[stop] Stopping CoJ2 Dedicated Server..."
pkill -f "CoJBiBGame_x86.exe"    2>/dev/null || true
pkill -f "CoJ2Game_x86_ds.exe"   2>/dev/null || true

echo "[stop] Stopping CoJ2 Controller..."
pkill -f "CoJ2Controller.exe"    2>/dev/null || true

echo "[stop] Stopping GameRanger..."
pkill -f "GameRanger.exe"        2>/dev/null || true

echo "[stop] Stopping Wine server..."
wineserver -k 2>/dev/null || true

echo "[stop] Done."
