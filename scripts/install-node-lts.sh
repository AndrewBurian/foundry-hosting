#!/usr/bin/env bash
# install-node-lts.sh
# Installs Node.js 22 LTS system-wide via the NodeSource apt repository.
# Must be run as a user with sudo access.
set -euo pipefail

NODE_MAJOR=22

echo "==> Installing Node.js ${NODE_MAJOR}.x LTS via NodeSource..."

sudo apt-get update -qq
sudo apt-get install -y curl ca-certificates

# Add the NodeSource apt repository and signing key
curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | sudo -E bash -

sudo apt-get install -y nodejs

echo ""
echo "==> Done."
node --version
npm --version
