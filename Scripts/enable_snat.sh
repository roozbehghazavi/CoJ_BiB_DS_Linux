#!/bin/bash
# Activate SNAT rule for GameRanger (UDP 27632)
# This makes your CoJ2 server directly joinable via GameRanger.

IP="YOURIP"
PORT=27632

echo "Activating SNAT for $IP:$PORT ..."
sudo iptables -t nat -A INPUT -p udp -d $IP --dport $PORT -j SNAT --to-source $IP
#sudo iptables -t nat -A POSTROUTING -o eth0 -p udp --dport $PORT -j SNAT --to-source $IP
echo "SNAT rule added successfully."

