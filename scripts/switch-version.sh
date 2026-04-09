#!/usr/bin/env bash
# switch-version.sh
# Updates /opt/foundry to point to a specific installed version, then
# restarts the systemd service.
#
# Usage: ./switch-version.sh <version>
# Example: ./switch-version.sh 14
set -euo pipefail

VERSION="${1:?Error: version number is required (e.g. 14)}"

INSTALL_DIR="/opt/foundry.${VERSION}"
SYMLINK="/opt/foundry"
SERVICE="foundry"

# ── Pre-flight ────────────────────────────────────────────────────────────────

if [[ ! -d "${INSTALL_DIR}" ]]; then
    echo "Error: ${INSTALL_DIR} does not exist."
    echo "Run scripts/install-foundry.sh first."
    exit 1
fi

CURRENT=$(readlink "${SYMLINK}" 2>/dev/null || echo "(none)")
echo "==> Current:  ${CURRENT}"
echo "==> Switching to: ${INSTALL_DIR}"
echo ""
read -rp "Continue? [y/N] " CONFIRM
[[ "${CONFIRM}" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

# ── Switch ────────────────────────────────────────────────────────────────────

echo "==> Stopping ${SERVICE}..."
sudo systemctl stop "${SERVICE}"

echo "==> Updating symlink..."
sudo ln -sfn "${INSTALL_DIR}" "${SYMLINK}"

echo "==> Starting ${SERVICE}..."
sudo systemctl start "${SERVICE}"

# ── Status ────────────────────────────────────────────────────────────────────

echo ""
echo "==> Active version: $(readlink -f "${SYMLINK}")"
echo ""
sudo systemctl status "${SERVICE}" --no-pager
