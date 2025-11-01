#!/usr/bin/env bash
#
# install-bpf-services.sh
#   Installs three systemd units (one per bpftrace script).
#   Run with sudo:  sudo ./install-bpf-services.sh
#
set -euo pipefail

# ────────────────────────────────
# 0.  Config
# ────────────────────────────────
SCRIPTS=(tcp-tracker.bt udp-tracker.bt)
SERVICE_PREFIX="bpf"             # final names: bpf-tcp-tracker.service …
BPFTRACE_BIN="/usr/bin/bpftrace" # adjust if different
RESTART_SEC=10

# ────────────────────────────────
# 1.  Locate directories
# ────────────────────────────────
BASE_DIR="$(pwd)"
BPF_DIR="${BASE_DIR}/bpf-scripts"
LOG_DIR="${BASE_DIR}/network-logs"

mkdir -p "${LOG_DIR}"

# verify scripts
for s in "${SCRIPTS[@]}"; do
	[[ -f "${BPF_DIR}/${s}" ]] || {
		echo "Missing ${BPF_DIR}/${s}"
		exit 1
	}
done

# ────────────────────────────────
# 2.  Create a unit for each script
# ────────────────────────────────
for s in "${SCRIPTS[@]}"; do
	svc_name="${SERVICE_PREFIX}-${s%.bt}.service"
	svc_path="/etc/systemd/system/${svc_name}"
	log_file="${LOG_DIR}/${s%.bt}.log"
	script_path="${BPF_DIR}/${s}"

	sudo tee "${svc_path}" >/dev/null <<EOF
[Unit]
Description=BPF telemetry – ${s}
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/bash -c '${BPFTRACE_BIN} ${script_path} >> ${log_file} 2>&1'
WorkingDirectory=${BASE_DIR}
User=root
KillSignal=SIGINT
Restart=always
RestartSec=${RESTART_SEC}

[Install]
WantedBy=multi-user.target
EOF

	echo "Installed ${svc_name}"
done

# ────────────────────────────────
# 3.  Enable units & (optionally) start them
# ────────────────────────────────
sudo systemctl daemon-reload

for s in "${SCRIPTS[@]}"; do
	sudo systemctl enable "${SERVICE_PREFIX}-${s%.bt}.service"
done

read -rp "Start all BPF telemetry services now? [y/N]: " yn
if [[ ${yn,,} == "y" ]]; then
	for s in "${SCRIPTS[@]}"; do
		sudo systemctl restart "${SERVICE_PREFIX}-${s%.bt}.service"
	done
	echo "Services started.  Use:"
	echo "   systemctl status ${SERVICE_PREFIX}-*.service"
else
	echo "Services enabled; they will start at the next boot."
fi

echo "Logs are written to:  ${LOG_DIR}/<script>.log"
