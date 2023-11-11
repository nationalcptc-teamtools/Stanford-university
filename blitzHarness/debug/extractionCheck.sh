#!/bin/bash

declare -A PORTS

# Use ":" instead of "." for IP addresses when creating array keys
sanitize_ip() {
    echo "$1" | tr '.' ':'
}

# Parsing the consolidated_ports_info.txt to extract IP addresses and open ports
awk '/Nmap scan report for /{ip=$5} /[0-9]+\/tcp/{print ip, $1}' consolidated_ports_info.txt | while read -r line; do
    IP=$(sanitize_ip $(echo $line | cut -d' ' -f1))
    PORT=$(echo $line | cut -d' ' -f2 | cut -d'/' -f1)
    PORTS["$IP"]="${PORTS["$IP"]} $PORT"
done

# Display the IPs and associated ports
for key in "${!PORTS[@]}"; do
    IP=$(echo "$key" | tr ':' '.')
    echo "$IP has open ports:${PORTS["$key"]}"
done
