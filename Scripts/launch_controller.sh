#!/bin/bash

export WINEPREFIX=/root/wine-coj2
export DISPLAY=:99

nohup bash -c 'wine "/root/wine-coj2/drive_c/Program Files/CoJ2 Controller/CoJ2Controller.exe"' >/dev/null 2>&1 & disown

echo "✅ Controller started in background."
