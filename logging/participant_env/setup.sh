#!/bin/bash

# set execution permissions and install required packages
sudo chmod -R +x .
sudo ./requirements.sh

# Install screen recording, automatic uploading, and logging command
cd ./screen-record/ || exit
sudo ../setup/install-screen-record.sh

# Install command, activity watch and network logging
cd ../verbose-log/ || exit
sudo mkdir -p ./logs
sudo chmod 777 ./logs
../setup/install-command-log.py
sudo ../setup/install-logcmd.sh
sudo ../setup/install-bpf-log.sh

# Ensure latest kernel headers are installed for BPF service
cd ..
sudo ./setup/install-kernel-headers.sh
