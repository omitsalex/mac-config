#!/usr/bin/env bash
# Download and install StevenBlack ad-blocking hosts file
# Run with sudo: sudo ./update-hosts.sh
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root (sudo)."
  exit 1
fi

echo "Updating hosts file with StevenBlack's ad-blocking list..."

if [ ! -f "/etc/hosts.backup" ]; then
  echo "Creating backup of original hosts file..."
  cp /etc/hosts /etc/hosts.backup
fi

TEMP_HOSTS=$(mktemp)
HOSTS_URL="https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"

echo "Downloading latest hosts file..."
curl -sf "$HOSTS_URL" > "$TEMP_HOSTS"

if [ ! -s "$TEMP_HOSTS" ]; then
  echo "Error: Failed to download hosts file."
  rm -f "$TEMP_HOSTS"
  exit 1
fi

echo "Extracting localhost entries..."
LOCAL_ENTRIES=$(grep -E '^127.0.0.1|^::1|^fe80::' /etc/hosts.backup)

echo "$LOCAL_ENTRIES" > /etc/hosts
echo "" >> /etc/hosts
grep -v -E '^127.0.0.1|^::1|^fe80::' "$TEMP_HOSTS" >> /etc/hosts

chmod 644 /etc/hosts
rm -f "$TEMP_HOSTS"

echo "Hosts file updated. Total blocking entries: $(grep -c '^0.0.0.0' /etc/hosts)"
