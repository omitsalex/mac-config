#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh — Single-command macOS provisioning from a clean machine
#
# Usage (from a fresh Mac) — invoke via `bash -c "$(curl ...)"` so that stdin
# stays attached to your terminal for interactive prompts. Do NOT use
# `curl ... | bash`: that feeds the script itself on stdin and hangs.
#
#   # Full Nix mode (default):
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/omitsalex/mac-config/main/bootstrap.sh)" mac-config --hostname work
#
#   # Brew-only mode (no Nix, no sudo required for system config):
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/omitsalex/mac-config/main/bootstrap.sh)" mac-config --hostname work --mode brew
#
#   # With SSH clone:
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/omitsalex/mac-config/main/bootstrap.sh)" mac-config --hostname work --ssh
# =============================================================================
set -euo pipefail

# Interactive prompts read from the terminal directly (see the xcode step and
# install.sh). We intentionally do NOT `exec </dev/tty` here: when this script
# is itself piped on stdin, redirecting stdin cuts off script reading and hangs.

BOLD="\033[1m"
NORMAL="\033[0m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RED="\033[31m"

# Defaults
HOSTNAME=""
MODE="nix"
PROFILE=""
USE_SSH=false
REPO_DIR="$HOME/mac-config"
# IMPORTANT: Update these if you fork the repo
REPO_HTTPS="https://github.com/omitsalex/mac-config.git"
REPO_SSH="git@github.com:omitsalex/mac-config.git"

usage() {
  echo -e "${BOLD}Usage:${NORMAL}"
  echo -e "  bootstrap.sh --hostname <name> [--mode nix|brew] [--profile <name>] [--ssh] [--dir <path>]"
  echo -e ""
  echo -e "${BOLD}Options:${NORMAL}"
  echo -e "  --hostname NAME   Host profile to provision (required)"
  echo -e "  --mode MODE       Installation mode: nix (default) or brew"
  echo -e "  --profile NAME    Override profile: personal, work, openclaw"
  echo -e "  --ssh             Clone via SSH instead of HTTPS"
  echo -e "  --dir PATH        Clone destination (default: ~/mac-config)"
  echo -e "  --help            Show this message"
  echo -e ""
  echo -e "${BOLD}Modes:${NORMAL}"
  echo -e "  nix   Full nix-darwin + home-manager + Homebrew (requires sudo for Nix)"
  echo -e "  brew  Homebrew + dotfile symlinks only (works without Nix/sudo)"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --hostname|-n)  HOSTNAME="$2"; shift 2 ;;
    --mode|-m)      MODE="$2"; shift 2 ;;
    --profile|-p)   PROFILE="$2"; shift 2 ;;
    --ssh)          USE_SSH=true; shift ;;
    --dir)          REPO_DIR="$2"; shift 2 ;;
    --help|-h)      usage; exit 0 ;;
    *)              echo -e "${RED}Unknown option: $1${NORMAL}"; usage; exit 1 ;;
  esac
done

if [ -z "$HOSTNAME" ]; then
  echo -e "${RED}Error: --hostname is required${NORMAL}"
  usage
  exit 1
fi

echo -e "${BOLD}${BLUE}macOS Bootstrap — profile: $HOSTNAME, mode: $MODE${NORMAL}\n"

# ============================================================================
# 1. Xcode Command Line Tools
# ============================================================================
echo -e "${YELLOW}[1/4] Checking Xcode Command Line Tools...${NORMAL}"
if ! xcode-select -p &>/dev/null; then
  echo -e "${YELLOW}Installing Xcode Command Line Tools...${NORMAL}"
  xcode-select --install
  echo -e "${YELLOW}Press Enter after the installation completes...${NORMAL}"
  read -r </dev/tty 2>/dev/null || true
else
  echo -e "${GREEN}Xcode CLT already installed.${NORMAL}"
fi

# ============================================================================
# 2. Clone or update the repo
# ============================================================================
echo -e "\n${YELLOW}[2/4] Setting up repository...${NORMAL}"
if [ -d "$REPO_DIR/.git" ]; then
  echo -e "${YELLOW}Repository exists at $REPO_DIR — pulling latest...${NORMAL}"
  git -C "$REPO_DIR" pull --rebase --autostash || true
else
  CLONE_URL="$REPO_HTTPS"
  if $USE_SSH; then
    CLONE_URL="$REPO_SSH"
  fi
  echo -e "${YELLOW}Cloning $CLONE_URL into $REPO_DIR...${NORMAL}"
  git clone "$CLONE_URL" "$REPO_DIR"
fi

# ============================================================================
# 3. Validate host config exists
# ============================================================================
echo -e "\n${YELLOW}[3/4] Validating host configuration...${NORMAL}"
HOST_CONFIG="$REPO_DIR/hosts/$HOSTNAME.nix"
if [ ! -f "$HOST_CONFIG" ]; then
  echo -e "${RED}Error: Host configuration not found: $HOST_CONFIG${NORMAL}"
  echo -e "${YELLOW}Available hosts:${NORMAL}"
  for f in "$REPO_DIR"/hosts/*.nix; do
    [ -f "$f" ] && echo "  - $(basename "$f" .nix)"
  done
  exit 1
fi
echo -e "${GREEN}Found host config: $HOST_CONFIG${NORMAL}"

# ============================================================================
# 4. Hand off to install.sh
# ============================================================================
echo -e "\n${YELLOW}[4/4] Running install.sh...${NORMAL}"
chmod +x "$REPO_DIR/install.sh"

INSTALL_ARGS=(--hostname "$HOSTNAME" --mode "$MODE")
if [ -n "$PROFILE" ]; then
  INSTALL_ARGS+=(--profile "$PROFILE")
fi

exec "$REPO_DIR/install.sh" "${INSTALL_ARGS[@]}"
