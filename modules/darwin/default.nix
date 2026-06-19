# Base macOS/Darwin configuration module
{
  pkgs,
  lib,
  username,
  adminUsername,
  isMultiUser,
  ...
}: {
  imports = [
    ./system.nix
    ./packages-full.nix
    ./fonts.nix
  ];

  # Fix for nixbld group GID mismatch
  ids.gids.nixbld = 350;

  # Essential Nix settings
  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      trusted-users = ["@admin"];
    };
    optimise = {
      automatic = true;
      interval = {
        Weekday = 0;
      };
    };
    gc = {
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 2;
      };
      options = "--delete-older-than 30d";
    };
  };

  programs.zsh.enable = true;

  # Day-to-day user — gets home-manager, shell, etc.
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
    shell = pkgs.zsh;
  };

  time.timeZone = "Europe/Lisbon";

  environment.systemPath = ["/opt/homebrew/bin" "/usr/local/bin"];
}
