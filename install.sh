#!/usr/bin/env bash
# =============================================================================
# install.sh — Build and activate macOS configuration
#
# Supports two modes:
#   nix  — Full nix-darwin + home-manager + Homebrew (default, requires sudo)
#   brew — Homebrew + dotfile symlinks only (no sudo for Nix, works on restricted machines)
#
# Usage:
#   ./install.sh --hostname openclaw                    # Nix mode (default)
#   ./install.sh --hostname work --mode brew        # Brew-only mode
#   ./install.sh --hostname airmac --profile personal   # Override profile
# =============================================================================
set -euo pipefail

BOLD="\033[1m"
NORMAL="\033[0m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RED="\033[31m"

repo_dir="$(cd "$(dirname "$0")" && pwd)"
cd "$repo_dir"

# When run via a pipe (e.g. `curl ... | bash`) stdin is the script, not the
# terminal, so interactive `read` prompts get EOF and are skipped. Reattach
# stdin to the controlling TTY so prompts (git identity, Homebrew y/n, day-user
# password) work. No-op when already interactive or when no TTY is available.
if [ ! -t 0 ] && [ -r /dev/tty ]; then
  exec </dev/tty
fi

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
HOSTNAME=""
MODE="nix"
PROFILE=""

printHelp() {
  echo -e "${BOLD}Usage:${NORMAL}"
  echo -e "  ./install.sh [options]"
  echo -e ""
  echo -e "${BOLD}Options:${NORMAL}"
  echo -e "  -n, --hostname NAME   Specify the hostname for this machine"
  echo -e "  -m, --mode MODE       Installation mode: nix (default) or brew"
  echo -e "  -p, --profile NAME    Override profile: personal, work, openclaw"
  echo -e "  -h, --help            Show this help message"
  echo -e ""
  echo -e "${BOLD}Modes:${NORMAL}"
  echo -e "  nix   Full nix-darwin + home-manager + Homebrew (requires sudo for Nix)"
  echo -e "  brew  Homebrew + dotfile symlinks only (works without Nix/sudo)"
  echo -e ""
  echo -e "${BOLD}Available hosts:${NORMAL}"
  for f in "$repo_dir"/hosts/*.nix; do
    [ -f "$f" ] || continue
    name="$(basename "$f" .nix)"
    [ "$name" = "templates" ] && continue
    echo "  - $name"
  done
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--hostname) HOSTNAME="$2"; shift 2 ;;
    -m|--mode)     MODE="$2"; shift 2 ;;
    -p|--profile)  PROFILE="$2"; shift 2 ;;
    -h|--help)     printHelp; exit 0 ;;
    *)             echo -e "${RED}Unknown option: $1${NORMAL}"; printHelp; exit 1 ;;
  esac
done

# Validate mode
if [[ "$MODE" != "nix" && "$MODE" != "brew" ]]; then
  echo -e "${RED}Invalid mode: $MODE (must be 'nix' or 'brew')${NORMAL}"
  exit 1
fi

# Fall back to current hostname
if [ -z "$HOSTNAME" ]; then
  HOSTNAME="$(hostname -s)"
  echo -e "${YELLOW}No hostname specified, using current: $HOSTNAME${NORMAL}"
fi

# Validate host config exists
HOST_CONFIG="$repo_dir/hosts/$HOSTNAME.nix"
if [ ! -f "$HOST_CONFIG" ]; then
  echo -e "${RED}Host configuration not found: $HOST_CONFIG${NORMAL}"
  echo -e "${YELLOW}Available hosts:${NORMAL}"
  for f in "$repo_dir"/hosts/*.nix; do
    [ -f "$f" ] || continue
    name="$(basename "$f" .nix)"
    [ "$name" = "templates" ] && continue
    echo "  - $name"
  done
  exit 1
fi

# ---------------------------------------------------------------------------
# Detect profile from flake.nix if not overridden
# ---------------------------------------------------------------------------
if [ -z "$PROFILE" ]; then
  _host_block=$(awk "/^[[:space:]]*${HOSTNAME}[[:space:]]*=/{found=1} found{print; if(/};/){exit}}" "$repo_dir/flake.nix")
  PROFILE=$(echo "$_host_block" | grep 'profile' | head -1 | sed 's/.*"\(.*\)".*/\1/' || true)
  if [ -z "$PROFILE" ]; then
    PROFILE="personal"
  fi
  unset _host_block
fi

echo -e "${BOLD}${BLUE}macOS Configuration Installer${NORMAL}"
echo -e "${BOLD}Host:${NORMAL}    $HOSTNAME"
echo -e "${BOLD}Profile:${NORMAL} $PROFILE"
echo -e "${BOLD}Mode:${NORMAL}    $MODE"
echo -e ""

###############################################################################
# 1. Git identity (GitHub user.name + user.email — required, must be entered)
###############################################################################
_git_user="$(git config --global user.name 2>/dev/null || true)"
_git_email="$(git config --global user.email 2>/dev/null || true)"
if [ -z "$_git_user" ] || [ -z "$_git_email" ]; then
  echo -e "${YELLOW}Git identity not configured — enter your GitHub details.${NORMAL}"

  GIT_NAME=""
  while [ -z "$GIT_NAME" ]; do
    read -rp "GitHub username (git user.name): " GIT_NAME || break
    [ -z "$GIT_NAME" ] && echo -e "${RED}Name cannot be empty.${NORMAL}"
  done

  GIT_EMAIL=""
  while [ -z "$GIT_EMAIL" ]; do
    read -rp "GitHub email (git user.email): " GIT_EMAIL || break
    [ -z "$GIT_EMAIL" ] && echo -e "${RED}Email cannot be empty.${NORMAL}"
  done

  if [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL" ]; then
    echo -e "${RED}GitHub username and email are required (no input available). Aborting.${NORMAL}"
    exit 1
  fi

  git config --global user.name "$GIT_NAME"
  git config --global user.email "$GIT_EMAIL"
  echo -e "${GREEN}Git identity set: $GIT_NAME <$GIT_EMAIL>${NORMAL}"
fi
unset _git_user _git_email

###############################################################################
# 1.5. Sudo convenience — suppress password/Touch-ID spam during install
###############################################################################
# The Homebrew and Nix installers each call sudo hundreds of times and do not
# reuse cached credentials in this context, which floods you with prompts.
# We install a TEMPORARY passwordless-sudo rule for the current admin user,
# auto-removed when this script exits (trap + explicit cleanup).
#
# NOTE: Touch ID for sudo is intentionally NOT enabled here. nix-darwin manages
# /etc/pam.d/sudo_local declaratively (security.pam.services.sudo_local.touchIdAuth
# in modules/darwin/system.nix); creating that file imperatively makes nix-darwin
# abort activation with "Unexpected files in /etc". Touch ID is enabled for you
# automatically once the nix-darwin system activates.
ADMIN_USER="$(whoami)"
SUDO_TMP_RULE="/etc/sudoers.d/10-mac-config-install"

cleanup_sudo_rule() {
  if [ -f "$SUDO_TMP_RULE" ]; then
    sudo rm -f "$SUDO_TMP_RULE" 2>/dev/null || true
    echo -e "${GREEN}Removed temporary passwordless-sudo rule.${NORMAL}"
  fi
}
trap cleanup_sudo_rule EXIT INT TERM

# Temporary passwordless sudo so the installers don't prompt per command.
# Removed automatically when this script exits.
if [ ! -f "$SUDO_TMP_RULE" ]; then
  echo -e "${YELLOW}Installing TEMPORARY passwordless-sudo for '$ADMIN_USER' (auto-removed on exit)...${NORMAL}"
  echo -e "${YELLOW}You may be asked for your password once now.${NORMAL}"
  printf '%s ALL=(ALL) NOPASSWD: ALL\n' "$ADMIN_USER" | sudo tee "$SUDO_TMP_RULE" >/dev/null
  sudo chmod 0440 "$SUDO_TMP_RULE"
  if sudo visudo -cf "$SUDO_TMP_RULE" >/dev/null 2>&1; then
    echo -e "${GREEN}Temporary passwordless-sudo active for this install.${NORMAL}"
  else
    echo -e "${RED}Invalid sudoers rule — removing (you may be prompted normally).${NORMAL}"
    sudo rm -f "$SUDO_TMP_RULE"
  fi
fi



###############################################################################
# 2. Commit any local changes (keep flake clean)
###############################################################################
if git -C "$repo_dir" status --porcelain | grep -q .; then
  echo -e "${YELLOW}Git: Committing local changes...${NORMAL}"
  git add -A
  git -c commit.gpgsign=false commit -m "auto-update $(date -Iseconds)" || true
fi

###############################################################################
# 2.5. Multi-user check — create day-to-day user if needed
###############################################################################
ADMIN_USER="$(whoami)"
DAY_USER=""

_host_block=$(awk "/^[[:space:]]*${HOSTNAME}[[:space:]]*=/{found=1} found{print; if(/};/){exit}}" "$repo_dir/flake.nix")
_username=$(echo "$_host_block" | grep 'username' | head -1 | sed 's/.*"\(.*\)".*/\1/' || true)
_admin_username=$(echo "$_host_block" | grep 'adminUsername' | head -1 | sed 's/.*"\(.*\)".*/\1/' || true)

if [ -n "$_admin_username" ] && [ "$_admin_username" != "$_username" ]; then
  DAY_USER="$_username"
  echo -e "${BLUE}Multi-user host detected:${NORMAL}"
  echo -e "  Admin user (runs darwin-rebuild): ${BOLD}$_admin_username${NORMAL}"
  echo -e "  Day-to-day user (gets home-manager): ${BOLD}$DAY_USER${NORMAL}"

  if [ "$ADMIN_USER" != "$_admin_username" ]; then
    echo -e "${RED}WARNING: You are logged in as '$ADMIN_USER' but the config expects admin '$_admin_username'.${NORMAL}"
    echo -e "${RED}Proceeding anyway — make sure '$ADMIN_USER' has admin rights.${NORMAL}"
  fi

  # Check if the day-to-day user exists; create if not
  if ! dscl . -read /Users/"$DAY_USER" &>/dev/null; then
    echo -e "${YELLOW}User '$DAY_USER' does not exist. Creating...${NORMAL}"
    read -rsp "Set a password for '$DAY_USER': " DAY_PASS
    echo ""
    sudo sysadminctl -addUser "$DAY_USER" -password "$DAY_PASS" -shell /bin/zsh
    echo -e "${GREEN}User '$DAY_USER' created (non-admin).${NORMAL}"
    unset DAY_PASS
  else
    echo -e "${GREEN}User '$DAY_USER' already exists.${NORMAL}"
    if dseditgroup -o checkmember -m "$DAY_USER" admin &>/dev/null; then
      echo -e "${YELLOW}NOTE: '$DAY_USER' is currently an admin user.${NORMAL}"
      echo -e "${YELLOW}To demote to standard user: System Settings > Users & Groups${NORMAL}"
    fi
  fi
else
  echo -e "${BLUE}Single-user host: admin and day-to-day user are both '${_username:-$ADMIN_USER}'${NORMAL}"
fi
unset _host_block _username _admin_username

###############################################################################
# 3. Homebrew (needed for both modes)
###############################################################################
BREW_PATH=""
if [ -x "/opt/homebrew/bin/brew" ]; then
  BREW_PATH="/opt/homebrew/bin/brew"
elif [ -x "/usr/local/bin/brew" ]; then
  BREW_PATH="/usr/local/bin/brew"
fi

if [ -z "$BREW_PATH" ]; then
  echo -e "${YELLOW}Homebrew not installed. Do you want to install it? (y/n)${NORMAL}"
  read -r install_brew
  if [[ "$install_brew" =~ ^[Yy]$ ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ -x "/opt/homebrew/bin/brew" ]; then
      BREW_PATH="/opt/homebrew/bin/brew"
    elif [ -x "/usr/local/bin/brew" ]; then
      BREW_PATH="/usr/local/bin/brew"
    fi
  fi
else
  echo -e "${GREEN}Homebrew at: $BREW_PATH${NORMAL}"
fi

if [ -n "$BREW_PATH" ]; then
  eval "$($BREW_PATH shellenv)"
fi

###############################################################################
# 4. Detect architecture
###############################################################################
REAL_ARCH="$(sysctl -n machdep.cpu.brand_string)"
if [[ "$REAL_ARCH" =~ "Apple" ]]; then
  ARCH="aarch64-darwin"
  echo -e "${YELLOW}Detected Apple Silicon${NORMAL}"
else
  ARCH="x86_64-darwin"
  echo -e "${YELLOW}Detected Intel Mac${NORMAL}"
fi

###############################################################################
# Shared function: install Homebrew packages (profile-aware)
###############################################################################
_install_brewfiles() {
  export HOMEBREW_GIT_PROTOCOL="https"

  # Temporarily hide XDG git config (url rewrite breaks brew on fresh machines)
  _xdg_git_config="$HOME/.config/git/config"
  _xdg_git_backup=""
  if [ -f "$_xdg_git_config" ] && grep -q 'insteadOf' "$_xdg_git_config" 2>/dev/null; then
    _xdg_git_backup="${_xdg_git_config}.brew-tmp"
    mv "$_xdg_git_config" "$_xdg_git_backup"
  fi

  brew update || true

  # Trust third-party taps up front. Homebrew's newer security policy refuses
  # formulae from untrusted taps, and `brew bundle` aborts the WHOLE file on the
  # first such formula (e.g. smudge/smudge/nightlight, hashicorp/tap/packer) —
  # which would silently skip everything after it, including casks like iterm2.
  for _tap in hashicorp/tap smudge/smudge mongodb/brew auth0/auth0-cli; do
    brew tap "$_tap" >/dev/null 2>&1 || true
    brew trust "$_tap" >/dev/null 2>&1 || true
  done

  # In brew-only mode, also install CLI tools that Nix would normally provide
  local brewfiles=("$repo_dir/brew/Brewfile.base")
  if [[ "$MODE" == "brew" ]]; then
    brewfiles+=("$repo_dir/brew/Brewfile.cli")
  fi

  # Add profile-specific Brewfile
  local profile_brewfile="$repo_dir/brew/Brewfile.$PROFILE"
  if [ -f "$profile_brewfile" ]; then
    brewfiles+=("$profile_brewfile")
  fi

  for bf in "${brewfiles[@]}"; do
    if [ -f "$bf" ]; then
      echo -e "  ${YELLOW}Installing from $(basename "$bf")...${NORMAL}"
      if [[ "$ARCH" == "aarch64-darwin" ]]; then
        arch -arm64 brew bundle --file="$bf" || true
      else
        brew bundle --file="$bf" || true
      fi
    fi
  done

  if [ -n "$_xdg_git_backup" ] && [ -f "$_xdg_git_backup" ]; then
    mv "$_xdg_git_backup" "$_xdg_git_config"
  fi

  echo -e "${GREEN}Homebrew packages done.${NORMAL}"
}

###############################################################################
# MODE SPLIT — Nix vs Brew-only
###############################################################################
if [[ "$MODE" == "nix" ]]; then
  #############################################################################
  # NIX MODE
  #############################################################################

  # --- Install Nix ---
  # Uses the official upstream installer. nix-darwin manages Nix natively
  # (nix.enable), so we deliberately avoid the Determinate Systems installer
  # here: it now installs Determinate Nix + determinate-nixd, which manages
  # /etc/nix/nix.conf itself and conflicts with nix-darwin's ownership.
  #
  # Source the daemon profile first: on a re-run from a non-login/non-interactive
  # shell (e.g. curl | bash) `nix` may not be on PATH even though it is installed.
  # Without this we would wrongly try to reinstall Nix and abort.
  if ! command -v nix >/dev/null 2>&1 \
     && [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
  if ! command -v nix >/dev/null 2>&1; then
    echo -e "${YELLOW}Installing Nix (requires sudo)...${NORMAL}"
    curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes
    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
      source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
  else
    echo -e "${GREEN}Nix already installed.${NORMAL}"
  fi

  # --- Enable flakes ---
  echo -e "\n${YELLOW}Enabling Nix flakes...${NORMAL}"
  mkdir -p ~/.config/nix
  if [ ! -f ~/.config/nix/nix.conf ] || ! grep -q "^experimental-features =" ~/.config/nix/nix.conf 2>/dev/null; then
    printf "experimental-features = nix-command flakes\n" >> ~/.config/nix/nix.conf
  fi

  # --- Clean up conflicting system files ---
  echo -e "\n${YELLOW}Checking for conflicting system configuration files...${NORMAL}"
  for rc in /etc/bashrc /etc/zshrc; do
    if [ -f "$rc" ] && ! grep -q "^# Default system.*from nix-darwin" "$rc" 2>/dev/null; then
      target="${rc}.before-nix-darwin"
      [ -e "$target" ] && target="${rc}.before-nix-darwin.$(date +%Y%m%d%H%M%S)"
      echo -e "${YELLOW}Renaming $rc -> $target${NORMAL}"
      sudo mv "$rc" "$target"
    fi
  done
  for f in /etc/zshrc.backup-before-nix /etc/bashrc.backup-before-nix; do
    if [ -e "$f" ]; then
      new_f="${f}.$(date +%Y%m%d%H%M%S)"
      echo -e "${YELLOW}Renaming leftover: $f -> $new_f${NORMAL}"
      sudo mv "$f" "$new_f"
    fi
  done

  # --- SOPS age key ---
  echo -e "\n${YELLOW}Setting up SOPS age key...${NORMAL}"
  LOCAL_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
  mkdir -p "$(dirname "$LOCAL_AGE_KEY_FILE")"

  if [ ! -f "$LOCAL_AGE_KEY_FILE" ]; then
    if [ -f "$HOME/.ssh/id_ed25519" ]; then
      echo -e "${YELLOW}Generating SOPS age key from SSH key...${NORMAL}"
      if command -v ssh-to-age >/dev/null 2>&1; then
        ssh-to-age -private-key -i "$HOME/.ssh/id_ed25519" > "$LOCAL_AGE_KEY_FILE"
      else
        nix --extra-experimental-features "nix-command flakes" run nixpkgs#ssh-to-age -- \
          -private-key -i "$HOME/.ssh/id_ed25519" > "$LOCAL_AGE_KEY_FILE"
      fi
      chmod 600 "$LOCAL_AGE_KEY_FILE"
      echo -e "${GREEN}Age key generated.${NORMAL}"
    else
      echo -e "${YELLOW}No SSH key found. You can create an age key later:${NORMAL}"
      echo -e "  age-keygen -o \"$LOCAL_AGE_KEY_FILE\""
    fi
  else
    echo -e "${GREEN}Age key exists at: $LOCAL_AGE_KEY_FILE${NORMAL}"
  fi

  # --- Update flake and build ---
  echo -e "\n${YELLOW}Updating flake inputs...${NORMAL}"
  nix --extra-experimental-features "nix-command flakes" flake update

  if git -C "$repo_dir" status --porcelain | grep -q 'flake.lock'; then
    git add flake.lock
    git -c commit.gpgsign=false commit -m "flake.lock update $(date -Iseconds)" || true
  fi

  export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

  DARWIN_CONFIG=".#$HOSTNAME"

  # Run darwin-rebuild, auto-healing the "Unexpected files in /etc" abort:
  # nix-darwin refuses to overwrite pre-existing /etc files it manages
  # (e.g. /etc/pam.d/sudo_local, /etc/bashrc, /etc/zshrc). If that happens we
  # move each flagged file aside to *.before-nix-darwin and retry once.
  _heal_etc_conflicts() {
    local logf="$1" f target
    grep -Eo '/etc/[^[:space:]]+' "$logf" | sort -u | while read -r f; do
      if [ -e "$f" ]; then
        target="${f}.before-nix-darwin"
        [ -e "$target" ] && target="${target}.$(date +%Y%m%d%H%M%S)"
        echo -e "${YELLOW}Moving conflicting $f -> $target${NORMAL}"
        sudo mv "$f" "$target"
      fi
    done
  }

  echo -e "${YELLOW}Building and activating nix-darwin for $HOSTNAME...${NORMAL}"
  if ! nix --extra-experimental-features "nix-command flakes" build ".#darwinConfigurations.$HOSTNAME.system" 2>/dev/null; then
    echo -e "${YELLOW}Bootstrapping nix-darwin (first build)...${NORMAL}"
  fi

  _logf="$(mktemp)"
  set +e
  if [ -x ./result/sw/bin/darwin-rebuild ]; then
    sudo ./result/sw/bin/darwin-rebuild switch --flake "$DARWIN_CONFIG" 2>&1 | tee "$_logf"
  else
    sudo -H nix run --extra-experimental-features 'nix-command flakes' \
      github:LnL7/nix-darwin#darwin-rebuild -- switch --flake "$DARWIN_CONFIG" 2>&1 | tee "$_logf"
  fi
  _rc=${PIPESTATUS[0]}
  set -e

  if [ "$_rc" -ne 0 ] && grep -q "Unexpected files in /etc" "$_logf"; then
    echo -e "${YELLOW}Resolving conflicting /etc files and retrying activation...${NORMAL}"
    _heal_etc_conflicts "$_logf"
    set +e
    if [ -x ./result/sw/bin/darwin-rebuild ]; then
      sudo ./result/sw/bin/darwin-rebuild switch --flake "$DARWIN_CONFIG" 2>&1 | tee "$_logf"
    else
      sudo -H nix run --extra-experimental-features 'nix-command flakes' \
        github:LnL7/nix-darwin#darwin-rebuild -- switch --flake "$DARWIN_CONFIG" 2>&1 | tee "$_logf"
    fi
    _rc=${PIPESTATUS[0]}
    set -e
  fi
  rm -f "$_logf"

  if [ "$_rc" -ne 0 ]; then
    echo -e "${RED}nix-darwin activation failed (exit $_rc). See output above.${NORMAL}"
    exit "$_rc"
  fi

  echo -e "${GREEN}Nix-darwin configuration applied!${NORMAL}"

  # --- Homebrew packages (profile-aware from brew/ directory) ---
  if [ -n "$BREW_PATH" ]; then
    echo -e "\n${YELLOW}Installing Homebrew packages...${NORMAL}"
    _install_brewfiles
  fi

elif [[ "$MODE" == "brew" ]]; then
  #############################################################################
  # BREW-ONLY MODE — no Nix, no sudo for system config
  #############################################################################
  echo -e "${BOLD}${BLUE}Running in brew-only mode (no Nix required)${NORMAL}\n"

  if [ -z "$BREW_PATH" ]; then
    echo -e "${RED}Homebrew is required for brew-only mode. Install it first.${NORMAL}"
    exit 1
  fi

  # --- Homebrew packages ---
  echo -e "${YELLOW}Installing Homebrew packages...${NORMAL}"
  _install_brewfiles

  # --- Dotfile symlinks (replaces home-manager) ---
  echo -e "\n${YELLOW}Setting up dotfiles...${NORMAL}"

  # iTerm2 config
  if [ -d "$repo_dir/iterm2" ]; then
    mkdir -p "$HOME/.config/iterm2"
    ln -sfn "$repo_dir/iterm2" "$HOME/.config/iterm2"
    echo -e "  ${GREEN}Linked iterm2 config${NORMAL}"
  fi

  # Powerlevel10k custom
  if [ -f "$repo_dir/dotfiles/p10k-custom.zsh" ]; then
    ln -sf "$repo_dir/dotfiles/p10k-custom.zsh" "$HOME/.p10k-custom.zsh"
    echo -e "  ${GREEN}Linked .p10k-custom.zsh${NORMAL}"
  fi

  # Git config (set basic settings if not already configured)
  if ! git config --global pull.rebase >/dev/null 2>&1; then
    git config --global pull.rebase true
    git config --global fetch.prune true
    git config --global push.autoSetupRemote true
    git config --global init.defaultBranch main
    git config --global core.editor vim
    git config --global core.autocrlf input
    echo -e "  ${GREEN}Applied base git config${NORMAL}"
  fi

  # Gitignore global
  if [ -f "$repo_dir/modules/home/gitignore_global" ]; then
    mkdir -p "$HOME/.config/git"
    ln -sf "$repo_dir/modules/home/gitignore_global" "$HOME/.config/git/gitignore_global"
    git config --global core.excludesfile "$HOME/.config/git/gitignore_global"
    echo -e "  ${GREEN}Linked gitignore_global${NORMAL}"
  fi

  # Shell aliases and config — create .zshrc_personal with brew-mode essentials
  cat > "$HOME/.zshrc_personal" <<'ZSHRC'
# Auto-generated by mac-config install.sh (brew-only mode)
# Aliases matching the nix-darwin shell.nix config

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# Modern CLI replacements
if command -v eza &>/dev/null; then
  alias ls="eza --icons --group-directories-first"
  alias ll="eza -l --icons --group-directories-first"
  alias la="eza -la --icons --group-directories-first"
  alias lt="eza --tree --icons --group-directories-first"
fi
if command -v bat &>/dev/null; then alias cat="bat --plain"; fi
if command -v btop &>/dev/null; then alias top="btop"; alias htop="btop"; fi
if command -v fd &>/dev/null; then alias find="fd"; fi
if command -v rg &>/dev/null; then alias grep="rg"; fi
if command -v dust &>/dev/null; then alias du="dust"; fi
if command -v zoxide &>/dev/null; then eval "$(zoxide init zsh)"; alias cd="z"; fi

# File safety
alias mkdir="mkdir -p"
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"

# Git
alias g="git"
alias ga="git add"
alias gc="git commit"
alias gco="git checkout"
alias gd="git diff"
alias gs="git status"
alias gl="git log"
alias gp="git push"
alias gpl="git pull"
alias lg="lazygit"

# K8s / Infra
alias k="kubectl"
alias tf="terraform"
alias dc="docker-compose"

# Nix (no-ops in brew mode, here as reminders)
# alias nrs="darwin-rebuild switch --flake ."
# alias nfu="nix flake update"

# Direnv
if command -v direnv &>/dev/null; then eval "$(direnv hook zsh)"; fi

# Starship prompt (if installed via brew)
if command -v starship &>/dev/null; then eval "$(starship init zsh)"; fi

# Atuin (if installed)
if command -v atuin &>/dev/null; then eval "$(atuin init zsh)"; fi

alias h="history"
alias j="jobs -l"
alias diskspace="df -h"
ZSHRC
  echo -e "  ${GREEN}Generated ~/.zshrc_personal with shell aliases${NORMAL}"

  # Ensure .zshrc_personal is sourced
  if [ -f "$HOME/.zshrc" ] && ! grep -q 'zshrc_personal' "$HOME/.zshrc" 2>/dev/null; then
    echo '' >> "$HOME/.zshrc"
    echo '# Load mac-config personal overrides' >> "$HOME/.zshrc"
    echo '[[ -f ~/.zshrc_personal ]] && source ~/.zshrc_personal' >> "$HOME/.zshrc"
    echo -e "  ${GREEN}Added .zshrc_personal source to .zshrc${NORMAL}"
  fi

  # Ensure Projects directory exists
  mkdir -p "$HOME/Projects/Sandbox"

  # --- macOS defaults (doesn't require sudo) ---
  echo -e "\n${YELLOW}Applying macOS preferences...${NORMAL}"
  # Keyboard
  defaults write -g KeyRepeat -int 1
  defaults write -g InitialKeyRepeat -int 10
  defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false
  defaults write -g NSAutomaticCapitalizationEnabled -bool false
  defaults write -g NSAutomaticDashSubstitutionEnabled -bool false
  defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false
  defaults write -g NSAutomaticQuoteSubstitutionEnabled -bool false
  # Finder
  defaults write com.apple.finder AppleShowAllExtensions -bool true
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write com.apple.finder ShowStatusBar -bool true
  defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
  # Dock
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock show-recents -bool false
  defaults write com.apple.dock tilesize -int 40
  defaults write com.apple.dock mru-spaces -bool false
  # Trackpad
  defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
  # Login
  defaults write com.apple.loginwindow GuestEnabled -bool false
  # Time Machine
  defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

  echo -e "${GREEN}macOS preferences applied.${NORMAL}"
  echo -e "${YELLOW}NOTE: Some settings require logout/restart to take effect.${NORMAL}"

fi

###############################################################################
# Common post-install steps (both modes)
###############################################################################

# --- Node.js LTS via NVM ---
echo -e "\n${YELLOW}Installing Node.js LTS via NVM...${NORMAL}"
export NVM_DIR="$HOME/.nvm"
if [ -n "$BREW_PATH" ] && [ -s "$(brew --prefix nvm 2>/dev/null)/nvm.sh" ]; then
  source "$(brew --prefix nvm)/nvm.sh"
fi
if command -v nvm >/dev/null 2>&1; then
  nvm install --lts || true
  nvm alias default 'lts/*' || true
fi

# --- Disable startup sound (requires sudo, skip if unavailable) ---
if sudo -n true 2>/dev/null; then
  echo -e "\n${YELLOW}Disabling Mac startup sound...${NORMAL}"
  sudo nvram StartupMute=%01 || true
fi

# --- Restart GPG agent ---
gpgconf --kill all 2>/dev/null || true

###############################################################################
# Done
###############################################################################
echo -e "\n${BOLD}${GREEN}============================================================${NORMAL}"
echo -e "${BOLD}${GREEN}  macOS Configuration Applied!${NORMAL}"
echo -e "${BOLD}${GREEN}============================================================${NORMAL}"

echo -e "\n${BOLD}Host:${NORMAL}         $HOSTNAME"
echo -e "${BOLD}Profile:${NORMAL}      $PROFILE"
echo -e "${BOLD}Mode:${NORMAL}         $MODE"
echo -e "${BOLD}Architecture:${NORMAL} $ARCH"
echo -e "${BOLD}Admin user:${NORMAL}   $(whoami)"
if [ -n "$DAY_USER" ]; then
  echo -e "${BOLD}Day-to-day:${NORMAL}   $DAY_USER (non-admin)"
fi

echo -e "\n${BOLD}${YELLOW}Next steps:${NORMAL}"
if [[ "$MODE" == "nix" ]]; then
  if [ -n "$DAY_USER" ]; then
    echo -e "  1. Log in as ${BLUE}$DAY_USER${NORMAL} to use the provisioned environment"
    echo -e "  2. Run ${BLUE}p10k configure${NORMAL} to customize the prompt"
    echo -e "  3. To update system config, log back in as ${BLUE}$(whoami)${NORMAL} and re-run:"
    echo -e "     ${BLUE}darwin-rebuild switch --flake .#$HOSTNAME${NORMAL}"
  else
    echo -e "  1. Restart your terminal or run: ${BLUE}source ~/.zshrc${NORMAL}"
    echo -e "  2. Run ${BLUE}p10k configure${NORMAL} to customize your prompt"
  fi
  echo -e "  3. Open Neovim and run ${BLUE}:PlugInstall${NORMAL} (for coc extensions)"
  echo -e "  4. In tmux, press ${BLUE}prefix + I${NORMAL} to install plugins"
  echo -e "  5. Configure GPG: place keys in ${BLUE}~/.config/gpg-keys/${NORMAL}"
  echo -e "  6. Configure git signing: ${BLUE}git config --global user.signingkey <KEY_ID>${NORMAL}"
  echo -e "\n${BOLD}Update commands:${NORMAL}"
  echo -e "  ${BLUE}nix flake update${NORMAL}"
  echo -e "  ${BLUE}darwin-rebuild switch --flake .#$HOSTNAME${NORMAL}"
  echo -e "  ${BLUE}brew bundle --file=Brewfile${NORMAL}"
else
  echo -e "  1. Restart your terminal or run: ${BLUE}source ~/.zshrc${NORMAL}"
  echo -e "  2. Run ${BLUE}p10k configure${NORMAL} to customize your prompt"
  echo -e "  3. Configure GPG: place keys in ${BLUE}~/.config/gpg-keys/${NORMAL}"
  echo -e "  4. Configure git signing: ${BLUE}git config --global user.signingkey <KEY_ID>${NORMAL}"
  echo -e "\n${BOLD}Update commands:${NORMAL}"
  echo -e "  ${BLUE}cd $repo_dir && ./install.sh --hostname $HOSTNAME --mode brew${NORMAL}"
  echo -e "  ${BLUE}brew update && brew upgrade${NORMAL}"
fi

echo -e "\n${BOLD}${GREEN}Setup complete!${NORMAL}\n"

# Remove the temporary passwordless-sudo rule before replacing the process
# (exec does not fire the EXIT trap, so clean up explicitly here too).
cleanup_sudo_rule
trap - EXIT INT TERM

exec $SHELL -l
