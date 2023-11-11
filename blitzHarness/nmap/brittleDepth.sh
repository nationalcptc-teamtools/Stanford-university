#!/bin/bash

# Check for required files
if [ ! -f consolidated_ports_info.txt ]; then
    echo "consolidated_ports_info.txt not found. Please ensure you have the file in the current directory."
    exit 1
fi

if [ ! -f excluded_ports_services.txt ]; then
    echo "excluded_ports_services.txt not found. Please ensure you have the file in the current directory."
    exit 1
fi

# Output file
output_file="indepth_ports.txt"
> "$output_file"  # Clear the output file before starting

delimiter="----------------------------------------------------------"

declare -A EXCLUDED_PORTS_SERVICES

# Populate the EXCLUDED_PORTS_SERVICES dictionary
while IFS= read -r line; do
    port=$(echo "$line" | cut -d' ' -f1)
    service=$(echo "$line" | cut -d' ' -f2-)
    EXCLUDED_PORTS_SERVICES["$port"]="$service"
done < "excluded_ports_services.txt"

# Function to check if a port is in the exclusion list
is_port_excluded() {
    local port=$1
    [[ ${EXCLUDED_PORTS_SERVICES["$port"]} ]] && echo "yes" || echo "no"
}

# Function to run an in-depth scan on a given host for a list of ports
scan_host_ports() {
    local host=$1
    shift
    local ports="$@"
    if [[ ! -z "$ports" ]]; then
        echo -e "\n$delimiter" | tee -a "$output_file"
        echo "Running in-depth scan on $host for ports $ports..." | tee -a "$output_file"
        echo -e "$delimiter\n" | tee -a "$output_file"
        nmap -p "$ports" -A -sVC "$host" | tee -a "$output_file"
    fi
}

# Extract hosts and corresponding ports
hosts_ports=$(awk '/Nmap scan report for /{ip=$5} /[0-9]+\/tcp/{print ip, $1}' consolidated_ports_info.txt)

# Process each host and its ports
previous_host=""
ports_for_host=""

echo "$hosts_ports" | while read -r host port; do
    if [[ "$host" != "$previous_host" && ! -z "$previous_host" ]]; then
        scan_host_ports "$previous_host" $ports_for_host &
        ports_for_host=""
    fi

    if [[ $(is_port_excluded "${port%/*}") == "no" ]]; then
        if [[ -z "$ports_for_host" ]]; then
            ports_for_host="${port%/*}"
        else
            ports_for_host="$ports_for_host,${port%/*}"
        fi
    fi
    previous_host="$host"
done

# Last host
if [[ ! -z "$ports_for_host" ]]; then
    scan_host_ports "$previous_host" $ports_for_host &
fi

# Wait for all background processes to finish
wait

echo "Scans completed." | tee -a "$output_file"
