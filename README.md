# mac-config

Declarative macOS provisioning with **nix-darwin** + **home-manager**.
Multi-host, GitHub-hosted, secret-safe.

## Quick Start (fresh Mac)

```bash
# One-liner from a clean machine:
curl -fsSL https://raw.githubusercontent.com/omitsalex/mac-config/main/bootstrap.sh \
  | bash -s -- --hostname openclaw

# Or clone manually:
git clone https://github.com/omitsalex/mac-config.git ~/mac-config
cd ~/mac-config
./install.sh --hostname openclaw
```

## Hosts

| Host | Arch | Admin User | Day-to-day User | Description |
|------|------|------------|-----------------|-------------|
| `airmac` | Apple Silicon | `user` | `user` | Personal MacBook Air |
| `airmac2` | Apple Silicon | `user` | `user` | Personal MacBook Air #2 |
| `work` | Intel | `user` | `user` | Work desktop |
| `openclaw` | Apple Silicon | `user` | `openclaw` | OpenClaw provisioning laptop |

### Single-user hosts (airmac, airmac2, work)

The admin and day-to-day user are the same. Run install as yourself:

```bash
./install.sh --hostname airmac
```

### Multi-user hosts (openclaw)

The admin user `user` runs `darwin-rebuild` (system-level changes).
The day-to-day user `openclaw` is a non-admin standard account that gets
home-manager (dotfiles, shell, git, neovim, etc.).

```bash
# Log in as the admin user, then:
./install.sh --hostname openclaw
# The installer will create the "openclaw" user if it doesn't exist.
# System settings + home-manager for "openclaw" are applied in one step.
# Log in as "openclaw" for daily use.
```

To update later (as admin):

```bash
darwin-rebuild switch --flake .#openclaw
```

### Adding a new host

1. Add entry to the `hosts` attrset in `flake.nix`
   - For multi-user: set `adminUsername` and `username` separately
   - For single-user: only set `username` (admin defaults to same)
2. Create `hosts/<hostname>.nix`
3. Run `./install.sh --hostname <hostname>`

## Architecture

```
flake.nix                  # Entry point — host registry + builder
hosts/
  openclaw.nix             # Host-specific: networking, firewall, dock
  airmac.nix
  templates/laptop.nix     # Shared laptop settings (energy, keyboard)
modules/
  darwin/
    default.nix            # Nix settings, user creation, timezone
    system.nix             # macOS defaults (dock, finder, trackpad, etc.)
    packages-full.nix      # System-level packages (Nix + Homebrew config)
    fonts.nix              # Font packages
  home/
    shell.nix              # ZSH + oh-my-zsh + powerlevel10k + aliases
    git.nix                # Git config (no hardcoded keys)
    gpg.nix                # GPG agent + local key import
    secrets.nix            # sops-nix integration (local age key)
    opencode.nix           # OpenCode CLI + MCP servers
    mcp.nix                # MCP server packages
    tmux.nix               # tmux + dracula theme
    neovim.nix             # Neovim + coc + gruvbox
    direnv.nix             # direnv + nix-direnv
    atuin.nix              # Shell history sync (optional)
    nodejs-fix.nix         # Node.js 22 override
  users/user.nix           # Home-manager user config
overlays/default.nix       # Nixpkgs overlays
Brewfile                   # Homebrew packages (GUI apps, env managers)
bootstrap.sh               # One-liner for fresh machines
install.sh                 # Full installer
```

## Secrets Management

Secrets are managed with [sops-nix](https://github.com/Mic92/sops-nix) + [age](https://github.com/FiloSottile/age).

**No secrets are stored in this repository.** The `.gitignore` blocks:
- Age private keys (`keys.txt`)
- GPG private keys (`.asc`, `.gpg`, `.key`)
- AWS credentials, VPN configs, `.env` files

### Setup

```bash
# Generate an age key (or derive from SSH key)
age-keygen -o ~/.config/sops/age/keys.txt

# Add your public key to .sops.yaml
age-keygen -y ~/.config/sops/age/keys.txt
# Copy the public key into .sops.yaml

# Create encrypted secrets
cp secrets/secrets.yaml.example secrets/secrets.yaml
sops --encrypt --in-place secrets/secrets.yaml

# Edit secrets
sops secrets/secrets.yaml
```

### GPG Keys

Place your GPG key files in `~/.config/gpg-keys/` before running install.
They will be automatically imported during `darwin-rebuild switch`.

## Updating

```bash
nix flake update                              # Update Nix inputs
darwin-rebuild switch --flake .#openclaw      # Apply config
brew bundle --file=Brewfile                   # Update Homebrew packages
```

## What's Included

### Via Nix
Core CLI: git, curl, wget, vim, neovim, tmux, fzf, jq, bat, eza, fd, ripgrep,
delta, dust, zoxide, lazygit, btop, htop, starship, opencode, gh, sops, age,
colima, k9s, python3, and more.

### Via Homebrew
GUI apps: iTerm2, VS Code, Docker Desktop, 1Password, Slack, Zoom, Chrome,
Firefox, Spotify, VLC, and more. Plus env managers (nvm, pyenv, rbenv, tfenv)
and Kubernetes tools.

### macOS System Defaults
Auto-configured: dock (autohide, no recents), finder (show extensions, path bar),
trackpad (tap to click, three-finger drag), keyboard (fast repeat, caps->ctrl),
Touch ID for sudo, Night Shift auto, dark wallpaper, firewall (OpenClaw).

## License

MIT
