#!/bin/bash

if [ ! -f livehosts.txt ]; then
    echo "livehosts.txt not found. Please ensure you have the file in the current directory."
    exit 1
fi

output_file="consolidated_ports_info.txt"
> "$output_file"  # Clear the output file before starting

delimiter="----------------------------------------------------------"

scan_host() {
    local host=$1
    echo -e "\n$delimiter" | tee -a "$output_file"
    echo "Scanning $host for common ports..." | tee -a "$output_file"
    echo -e "$delimiter\n" | tee -a "$output_file"
    
    # Scanning the top 1,000 ports, resolving hostnames (-R), and attempting version detection (-sV)
    nmap -Pn -F -R -sV $host | tee -a "$output_file"
    echo -e "\n$delimiter\n" | tee -a "$output_file"
}

while IFS= read -r host
do
    scan_host $host &
    sleep 0.5  # Introduce a short delay before starting the next scan to prevent overwhelming the network
done < livehosts.txt

# Wait for all background processes to finish
wait

echo "Scans completed." | tee -a "$output_file"
