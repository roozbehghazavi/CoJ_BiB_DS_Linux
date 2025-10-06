#!/bin/bash

echo "Stopping CoJ2 Dedicated Server..."
pkill -f "CoJBiBGame_x86.exe"
pkill -f "CoJ2Game_x86_ds.exe"

echo "Stopping CoJ2 Controller..."
pkill -f "CoJ2Controller.exe"

echo "Stopping GameRanger..."
pkill -f "GameRanger.exe"

echo "All processes stopped."

