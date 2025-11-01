#!/bin/bash
sudo apt update && sudo apt install -y wmctrl xdotool ffmpeg x11-utils x11-xserver-utils systemd \
	bpftrace git jq asciinema

KERNEL_VERSION="$(uname -r)"
sudo apt install "linux-headers-${KERNEL_VERSION}"

sudo apt autoremove -y
