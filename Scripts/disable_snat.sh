#!/bin/bash
# Deactivate SNAT rule for GameRanger (UDP 27632)

IP="YOURIP"
PORT=27632

echo "Removing SNAT for $IP:$PORT ..."
sudo iptables -t nat -D INPUT -p udp -d $IP --dport $PORT -j SNAT --to-source $IP
echo "SNAT rule removed successfully."

