#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <target_range>"
    exit 1
fi

target_range="$1"

# Clear the livehosts.txt file before starting
> livehosts.txt

# ICMP Ping Sweep
nmap -sn $target_range -oG - | awk '/Up$/{print $2}' >> livehosts.txt &

# TCP SYN Ping
nmap -sn -PS22,80,443,3389 $target_range -oG - | awk '/Up$/{print $2}' >> livehosts.txt &

# TCP ACK Ping
nmap -sn -PA22,80,443,3389 $target_range -oG - | awk '/Up$/{print $2}' >> livehosts.txt &

# ARP Discovery (if scanning a local network)
nmap -sn -PR $target_range -oG - | awk '/Up$/{print $2}' >> livehosts.txt &

# Wait for all background processes to finish
wait

# Consolidate and Deduplicate
sort livehosts.txt | uniq > temp_livehosts.txt && mv temp_livehosts.txt livehosts.txt

# Display the results
cat livehosts.txt
