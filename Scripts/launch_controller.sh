#!/bin/bash

export WINEPREFIX=/root/wine-coj2
export DISPLAY=:99
export WINEDEBUG=-all
export WINEDLLOVERRIDES="version=n,b"

nohup bash -c 'wine "/root/CoJ_BiB_DS_Linux/Applications/CoJ2 Controller/CoJ2Controller.exe"' >/dev/null 2>&1 & disown

echo "✅ Controller started in background."
