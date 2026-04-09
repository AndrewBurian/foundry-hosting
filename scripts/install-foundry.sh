#!/usr/bin/env bash
# install-foundry.sh
# Downloads a Foundry VTT release from a signed URL and installs it to
# /opt/foundry.<version>. Does NOT switch the active symlink — run
# switch-version.sh when you're ready to cut over.
#
# Usage: ./install-foundry.sh "<signed-url>" <version>
# Example: ./install-foundry.sh "https://foundryvtt.s3.amazonaws.com/..." 14
#
# Requirements:
#   - sudo access
#   - unzip installed  (sudo apt-get install -y unzip)
#   - The foundry system user and group must already exist
set -euo pipefail

SIGNED_URL="${1:?Error: signed URL is required as the first argument}"
VERSION="${2:?Error: Foundry major version is required as the second argument (e.g. 14)}"

INSTALL_DIR="/opt/foundry.${VERSION}"
TMP_DIR=$(mktemp -d)

cleanup() {
    echo "==> Cleaning up ${TMP_DIR}..."
    rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

# ── Download ──────────────────────────────────────────────────────────────────

echo "==> Downloading Foundry VTT ${VERSION} to ${TMP_DIR}..."
curl -L --progress-bar -o "${TMP_DIR}/foundryvtt.zip" "${SIGNED_URL}"

# ── Unpack ────────────────────────────────────────────────────────────────────

echo "==> Unpacking..."
sudo apt-get install -y unzip -qq
unzip -q "${TMP_DIR}/foundryvtt.zip" -d "${TMP_DIR}/foundry"

# ── Install ───────────────────────────────────────────────────────────────────

if [[ -d "${INSTALL_DIR}" ]]; then
    echo "==> ${INSTALL_DIR} already exists — removing before reinstall."
    sudo rm -rf "${INSTALL_DIR}"
fi

echo "==> Creating ${INSTALL_DIR}..."
sudo mkdir -p "${INSTALL_DIR}"

echo "==> Copying files..."
sudo cp -a "${TMP_DIR}/foundry/." "${INSTALL_DIR}/"

echo "==> Setting ownership to foundry:foundry..."
sudo chown -R foundry:foundry "${INSTALL_DIR}"

# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
echo "==> Foundry ${VERSION} installed to ${INSTALL_DIR}"
echo ""
echo "    Verify it works, then run:"
echo "      bash scripts/switch-version.sh ${VERSION}"
