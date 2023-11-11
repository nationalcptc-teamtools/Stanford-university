#!/bin/bash

# Files to be compared
common_ports_file="consolidated_ports_info.txt"  # Adjust this filename if needed
uncommon_tcp_file="uncommon_tcp_ports_scan_results.txt"
uncommon_udp_file="uncommon_udp_ports_scan_results.txt"

# Output file
new_ports_file="new_ports_with_ips_discovered.txt"
> "$new_ports_file"  # Clear the output file before starting

# Check if required files exist
if [ ! -f "$common_ports_file" ] || [ ! -f "$uncommon_tcp_file" ] || [ ! -f "$uncommon_udp_file" ]; then
    echo "One or more required files not found. Please ensure you have the necessary files in the current directory."
    exit 1
fi

# Function to extract IP and port information
extract_ip_port() {
    awk '/Nmap scan report for /{ip=$5} /[0-9]+\/(tcp|udp)/{print ip, $1}' "$1"
}

# Extract IP and port information from files
extract_ip_port "$common_ports_file" | sort | uniq > common_ip_ports.txt
extract_ip_port "$uncommon_tcp_file" > uncommon_tcp_ip_ports.txt
extract_ip_port "$uncommon_udp_file" > uncommon_udp_ip_ports.txt

# Find IP and port pairs in uncommon scan but not in common scan
cat uncommon_tcp_ip_ports.txt uncommon_udp_ip_ports.txt | sort | uniq > uncommon_ip_ports.txt
comm -23 uncommon_ip_ports.txt common_ip_ports.txt > "$new_ports_file"

# Cleanup intermediate files
rm common_ip_ports.txt uncommon_tcp_ip_ports.txt uncommon_udp_ip_ports.txt uncommon_ip_ports.txt

# Display results
if [ -s "$new_ports_file" ]; then
    echo "New ports with associated IPs discovered in the uncommon ports scan:"
    cat "$new_ports_file"
else
    echo "No new ports with associated IPs were discovered in the uncommon ports scan."
fi
