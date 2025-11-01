#!/bin/bash

if [[ ${EUID} -ne 0 ]]; then
	echo "This script must be run as root. Use: sudo $0"
	exit 1
fi

SCRIPT_PATH="$(realpath log-cmd-install.sh)"
SCRIPT_DIR="$(dirname "${SCRIPT_PATH}")"
LOGS_DIR="${SCRIPT_DIR}/logs"
LOG_PATH="${LOGS_DIR}/events.log"
LOG_COMMAND_PATH="/usr/local/bin/log"

# Add custom logging command to path
read -r -d '' COSTUMLOG_SCRIPT <<EOF
#!/bin/bash

LOG_FILE=${LOG_PATH}

if [[ "\$1" == "--help" || "\$1" == "-h" ]]; then
    echo "Usage: log \"your message here\""
    echo "Appends a timestamped message to \$LOG_FILE."
    echo "Format: YYYY-MM-DD_HH-MM-SS           \"your message here\""
    exit 0
fi

TIMESTAMP=\$(date '+%Y-%m-%d_%H-%M-%S')

echo "\$TIMESTAMP           \"\$*\"" >> "\$LOG_FILE"
EOF

echo "${COSTUMLOG_SCRIPT}" >"${LOG_COMMAND_PATH}"

chmod +x "${LOG_COMMAND_PATH}"
touch "${LOG_PATH}"
chmod 777 "${LOG_PATH}"

echo "Custom log command for marking video events complete!"
