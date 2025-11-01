#!/bin/bash

if [[ ${EUID} -ne 0 ]]; then
	echo "This script must be run as root. Use: sudo $0"
	exit 1
fi

# === Common Paths ===
SCRIPT_PATH="$(realpath screen-record.py)"
BASE_DIR="$(dirname "${SCRIPT_PATH}")"
LOGS_DIR="${BASE_DIR}/logs"

# === screen-record.service Setup ===
RECORD_SCRIPT="${BASE_DIR}/screen-record.py"
RECORD_LOG="${LOGS_DIR}/screen-record.log"
RECORD_SERVICE="/etc/systemd/system/screen-record.service"

mkdir -p "${LOGS_DIR}/in_progress" "${LOGS_DIR}/recordings"
touch "${RECORD_LOG}"
chmod 777 "${RECORD_LOG}" "${LOGS_DIR}/in_progress" "${LOGS_DIR}/recordings"
chown -R "${SUDO_USER}:${SUDO_USER}" "${BASE_DIR}"

tee "${RECORD_SERVICE}" >/dev/null <<EOF
[Unit]
Description=FFmpeg Screen Recording Daemon

[Service]
ExecStart=${RECORD_SCRIPT}
ExecStop=/bin/kill -SIGINT \$MAINPID
Restart=always
RestartSec=15s
User=${SUDO_USER}
WorkingDirectory=${BASE_DIR}
StandardOutput=append:${RECORD_LOG}
StandardError=append:${RECORD_LOG}
KillSignal=SIGINT

[Install]
WantedBy=multi-user.target
EOF

# === Enable screen recording service ===
systemctl daemon-reload
systemctl enable screen-record

read -r -p "Start screen recording now? (y/n): " start_rec
if [[ ${start_rec} == "y" ]]; then
	systemctl restart screen-record
	echo "Screen recording started. Check: systemctl status screen-record"
else
	echo "Recording will start automatically on boot."
fi

echo "Screen recording installation complete."
