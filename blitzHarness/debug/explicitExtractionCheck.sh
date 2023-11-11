#!/bin/bash

# Required files
input_file="consolidated_ports_info.txt"
output_file="indepth_ports.txt"

# Check for input file
if [ ! -f "$input_file" ]; then
    echo "$input_file not found. Please ensure you have the file in the current directory."
    exit 1
fi

# Clear the output file before starting
> "$output_file"

# Function to perform an in-depth scan
indepth_scan() {
    local ip=$1
    local port=$2
    
    echo "Scanning $ip on port $port ..." | tee -a "$output_file"

    # Here we do the in-depth nmap scan
    nmap -p "$port" -A -sVC "$ip" | tee -a "$output_file"

    echo "---------------------------------------" | tee -a "$output_file"
}

# Parse the consolidated_ports_info.txt for IPs and their open ports
mapfile -t scans < <(awk '/Nmap scan report for /{ip=$5} /[0-9]+\/tcp/{print ip, $1}' "$input_file")

for scan in "${scans[@]}"; do
    ip=$(echo "$scan" | awk '{print $1}')
    port=$(echo "$scan" | awk '{print $2}' | cut -d '/' -f 1)
    
    # Perform in-depth scan for this ip and port
    indepth_scan "$ip" "$port"
done

echo "Scans completed." | tee -a "$output_file"
