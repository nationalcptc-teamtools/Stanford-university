#!/bin/bash

# Check if livehosts.txt exists
if [ ! -f livehosts.txt ]; then
    echo "livehosts.txt not found. Please ensure you have the file in the current directory."
    exit 1
fi

output_file="udp_scan_results.txt"
> "$output_file"  # Clear the output file before starting

scan_host_udp() {
    local host=$1
    echo "Scanning $host for UDP ports..." | tee -a "$output_file"
    nmap -Pn -sU -F $host | tee -a "$output_file"
    echo "" | tee -a "$output_file"
}

while IFS= read -r host
do
    scan_host_udp $host &
    sleep 0.5  # Delay to prevent overwhelming the network
done < livehosts.txt

wait

echo "UDP Scans completed." | tee -a "$output_file"
                                                      
