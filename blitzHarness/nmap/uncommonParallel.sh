#!/bin/bash

# Check if livehosts.txt exists
if [ ! -f livehosts.txt ]; then
    echo "livehosts.txt not found. Please ensure you have the file in the current directory."
    exit 1
fi

tcp_output_file="uncommon_tcp_ports_scan_results.txt"
udp_output_file="uncommon_udp_ports_scan_results.txt"
> "$tcp_output_file"  # Clear the TCP output file before starting
> "$udp_output_file"  # Clear the UDP output file before starting

scan_host_tcp() {
    local host=$1
    echo "Scanning $host for uncommon TCP ports..." | tee -a "$tcp_output_file"
    nmap -Pn -sS --top-ports 10000 --exclude-ports 1-1000 $host | tee -a "$tcp_output_file"
    echo "" | tee -a "$tcp_output_file"
}

scan_host_udp() {
    local host=$1
    echo "Scanning $host for uncommon UDP ports..." | tee -a "$udp_output_file"
    nmap -Pn -sU --top-ports 10000 --exclude-ports 1-1000 $host | tee -a "$udp_output_file"
    echo "" | tee -a "$udp_output_file"
}

while IFS= read -r host
do
    scan_host_tcp $host &
    sleep 0.5  # Delay to prevent overwhelming the network
done < livehosts.txt

wait

echo "TCP Scans completed." | tee -a "$tcp_output_file"

while IFS= read -r host
do
    scan_host_udp $host &
    sleep 0.5  # Delay to prevent overwhelming the network
done < livehosts.txt

wait

echo "UDP Scans completed." | tee -a "$udp_output_file"
