# Justfile for mac-config
# Run `just` or `just --list` to see available commands

default:
    @just --list

# ===========================================================================
# Nix mode commands
# ===========================================================================

# Build the configuration for the current host
build HOST=`hostname -s`:
    darwin-rebuild build --flake .#{{HOST}}

# Switch to the new configuration
switch HOST=`hostname -s`:
    darwin-rebuild switch --flake .#{{HOST}}

# Update flake inputs to latest versions
update:
    nix flake update

# Full rebuild cycle (update + build + switch)
rebuild HOST=`hostname -s`: update
    darwin-rebuild switch --flake .#{{HOST}}

# ===========================================================================
# Brew-only mode commands
# ===========================================================================

# Install brew packages for a profile (brew-only mode)
brew-install PROFILE="personal":
    brew update
    brew bundle --file=brew/Brewfile.base
    brew bundle --file=brew/Brewfile.cli
    test -f brew/Brewfile.{{PROFILE}} && brew bundle --file=brew/Brewfile.{{PROFILE}} || true

# Update all brew packages
brew-update:
    brew update && brew upgrade

# Run full brew-only install (packages + dotfiles + macOS defaults)
brew-setup HOST=`hostname -s` PROFILE="personal":
    ./install.sh --hostname {{HOST}} --mode brew --profile {{PROFILE}}

# ===========================================================================
# Code quality
# ===========================================================================

# Format all Nix files
fmt:
    alejandra .

# Check formatting without changing files
fmt-check:
    alejandra --check .

# Find dead code
deadnix:
    deadnix

# Fix dead code automatically
deadnix-fix:
    deadnix -f

# Lint Nix files
lint:
    statix check

# Run all checks (format, deadnix, lint, flake check)
check: fmt-check
    deadnix --fail
    statix check
    nix flake check

# Clean build artifacts
clean:
    rm -rf result result-*

# ===========================================================================
# Secrets & keys
# ===========================================================================

# Generate age key from SSH key
gen-age-key:
    @echo "Your age public key:"
    @ssh-to-age < ~/.ssh/id_ed25519.pub
    @echo "\nYour age private key (save securely):"
    @ssh-to-age -private-key -i ~/.ssh/id_ed25519

# Setup SOPS age key
setup-sops:
    mkdir -p ~/.config/sops/age
    ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt
    chmod 600 ~/.config/sops/age/keys.txt
    @echo "SOPS age key created at ~/.config/sops/age/keys.txt"

# Create/edit a secret file
secret FILE:
    sops {{FILE}}

# ===========================================================================
# Info & utilities
# ===========================================================================

# Show flake metadata
info:
    nix flake metadata

# Show configuration for a specific host
show HOST=`hostname -s`:
    nix eval .#darwinConfigurations.{{HOST}}.config.system.build.toplevel

# Backup current npm globals
backup-npm:
    npm list -g --depth=0 > ~/npm-globals-backup-$(date +%Y%m%d).txt
    @echo "Global npm packages backed up to ~/npm-globals-backup-$(date +%Y%m%d).txt"

# Git: Create WIP commit and push
wip MESSAGE="wip: $(date -Iseconds)":
    git add -A
    git commit -m "{{MESSAGE}}"
    git push -u origin HEAD

# Git: Sync with remote (fetch, prune, pull with rebase)
sync:
    git fetch --all --prune
    git pull --rebase --autostash

# Show system info (works in both modes)
sysinfo:
    @echo "=== System Information ==="
    @echo "Hostname: $(hostname)"
    @echo "Architecture: $(uname -m)"
    @echo "macOS Version: $(sw_vers -productVersion)"
    @echo ""
    @echo "=== Homebrew ==="
    @brew --version 2>/dev/null || echo "Not installed"
    @echo ""
    @echo "=== Nix ==="
    @nix --version 2>/dev/null || echo "Not installed (brew-only mode)"
