# User configuration for home-manager
# NOTE: username and homeDirectory are parameterized — no hardcoded values
{
  pkgs,
  username,
  lib,
  osConfig,
  ...
}: let
  isWork = (osConfig.local.profile.name or "personal") == "work";
in {
  imports = [
    ../home/shell.nix
    ../home/git.nix
    ../home/neovim.nix
    ../home/tmux.nix
    ../home/direnv.nix
    ../home/fzf.nix
    ../home/atuin.nix
    ../home/nodejs-fix.nix
    ../home/gpg.nix
    ../home/secrets.nix
    ../home/mcp.nix
    ../home/opencode.nix
    ../home/claude.nix
    ../home/obsidian.nix
  ];

  home = {
    inherit username;
    homeDirectory = "/Users/${username}";
    stateVersion = "24.05";

    packages = with pkgs; [
      bzip2
      sqlite
      xz
      python3
      k9s
    ];

    file =
      {
        ".config/iterm2".source = ../../iterm2;

        # Powerlevel10k custom overlay
        ".p10k-custom.zsh".source = ../../dotfiles/p10k-custom.zsh;

        # Custom zsh overrides (empty by default — user can populate)
        ".zshrc_personal".text = ''
          # Personal aliases and settings — add your own here
        '';
      }
      // lib.optionalAttrs isWork {
        # iTerm2 auto-loads Dynamic Profiles from this path — no manual import,
        # no "load prefs from custom folder" needed. Adds the "Work" profile.
        "Library/Application Support/iTerm2/DynamicProfiles/work.json".source =
          ../../iterm2/DynamicProfiles/work.json;
      };
  };
}
