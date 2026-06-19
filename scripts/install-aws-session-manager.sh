#!/usr/bin/env bash
# Install AWS Session Manager Plugin
set -euo pipefail

echo "Installing AWS Session Manager Plugin..."

if command -v session-manager-plugin >/dev/null 2>&1; then
  echo "AWS Session Manager Plugin already installed:"
  session-manager-plugin --version
  exit 0
fi

TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

if [[ "$(uname -m)" == "arm64" ]]; then
  echo "Downloading for Apple Silicon (ARM64)..."
  curl -LO "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac_arm64/sessionmanager-bundle.zip"
else
  echo "Downloading for Intel (x86_64)..."
  curl -LO "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/sessionmanager-bundle.zip"
fi

echo "Extracting..."
unzip -q sessionmanager-bundle.zip

echo "Installing (requires sudo)..."
sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin

cd -
rm -rf "$TMP_DIR"

if command -v session-manager-plugin >/dev/null 2>&1; then
  echo "AWS Session Manager Plugin installed successfully!"
  session-manager-plugin --version
else
  echo "Installation failed. See: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"
  exit 1
fi
