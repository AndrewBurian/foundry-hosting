#!/usr/bin/env bash
# install-node-lts.sh
# Installs the latest Node.js 22 LTS as a standalone binary to
# /usr/local/node-22/. Does NOT touch or replace any existing Node
# installation, so Foundry 13 continues to use whatever node it currently has.
#
# The Foundry 14 systemd service references /usr/local/node-22/bin/node
# directly, so no PATH changes are needed.
set -euo pipefail

NODE_MAJOR=22
INSTALL_PREFIX="/usr/local/node-${NODE_MAJOR}"
ARCH="linux-x64"

# ── Resolve latest patch version ──────────────────────────────────────────────

echo "==> Fetching latest Node.js ${NODE_MAJOR}.x LTS version..."
NODE_VERSION=$(curl -fsSL "https://nodejs.org/dist/index.json" \
    | python3 -c "
import sys, json
releases = json.load(sys.stdin)
latest = next(
    r['version'] for r in releases
    if r['lts'] and r['version'].startswith('v${NODE_MAJOR}.')
)
print(latest)
")

echo "==> Latest: ${NODE_VERSION}"

TARBALL="node-${NODE_VERSION}-${ARCH}.tar.xz"
DOWNLOAD_URL="https://nodejs.org/dist/${NODE_VERSION}/${TARBALL}"
TMP_DIR=$(mktemp -d)

cleanup() { rm -rf "${TMP_DIR}"; }
trap cleanup EXIT

# ── Download and verify ───────────────────────────────────────────────────────

echo "==> Downloading ${TARBALL}..."
curl -L --progress-bar -o "${TMP_DIR}/${TARBALL}" "${DOWNLOAD_URL}"

echo "==> Verifying checksum..."
curl -fsSL "${DOWNLOAD_URL}.sha256" -o "${TMP_DIR}/${TARBALL}.sha256"
# The .sha256 file is just the hash, no filename — build a checksum line manually
echo "$(cat "${TMP_DIR}/${TARBALL}.sha256")  ${TMP_DIR}/${TARBALL}" | sha256sum -c -

# ── Install ───────────────────────────────────────────────────────────────────

echo "==> Installing to ${INSTALL_PREFIX}..."
TMP_EXTRACT="${TMP_DIR}/extract"
mkdir -p "${TMP_EXTRACT}"
tar -xJf "${TMP_DIR}/${TARBALL}" -C "${TMP_EXTRACT}" --strip-components=1

sudo mkdir -p "${INSTALL_PREFIX}"
sudo cp -a "${TMP_EXTRACT}/." "${INSTALL_PREFIX}/"

echo "==> Symlinking /usr/local/bin/node${NODE_MAJOR}..."
sudo ln -sfn "${INSTALL_PREFIX}/bin/node" "/usr/local/bin/node${NODE_MAJOR}"

# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
echo "==> Installed:"
"${INSTALL_PREFIX}/bin/node" --version
"${INSTALL_PREFIX}/bin/npm" --version
echo ""
echo "    Versioned binary: node${NODE_MAJOR} ($(node${NODE_MAJOR} --version))"
echo "    Full path for systemd: ${INSTALL_PREFIX}/bin/node"
echo "    Existing system node is unchanged: $(node --version 2>/dev/null || echo '(none)')"
