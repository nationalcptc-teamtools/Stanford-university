#!/usr/bin/env bash
# setup-ensure-kernel-headers.sh
# Run this script as root.

set -euo pipefail

SERVICE_NAME="ensure-kernel-headers.service"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"
HELPER_PATH="/usr/local/sbin/ensure-kernel-headers.sh"

# --- create helper that does the check + install ---
install -d -m 0755 "$(dirname "${HELPER_PATH}")"
cat >"${HELPER_PATH}" <<"EOF"
#!/usr/bin/env bash
set -euo pipefail

KERNEL_VERSION="$(uname -r)"
PKG="linux-headers-${KERNEL_VERSION}"

# If already installed, nothing to do
if dpkg -s "$PKG" >/dev/null 2>&1; then
  exit 0
fi

# Install using the exact command (no sudo needed under systemd root service)
apt install "linux-headers-${KERNEL_VERSION}" -y
EOF
chmod 0755 "${HELPER_PATH}"

# --- create systemd unit ---
cat >"${SERVICE_PATH}" <<EOF
[Unit]
Description=Ensure kernel headers for the current kernel are installed at boot
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=${HELPER_PATH}

[Install]
WantedBy=multi-user.target
EOF

# --- enable and start once now ---
systemctl daemon-reload
systemctl enable "${SERVICE_NAME}"
systemctl start "${SERVICE_NAME}" || true

echo "Done. Check status/logs with:"
echo "  systemctl status ${SERVICE_NAME}"
echo "  journalctl -u ${SERVICE_NAME} -n 50 --no-pager"
