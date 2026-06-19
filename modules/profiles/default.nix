# Profile system — derives capability flags from a single profile enum.
# Hosts set `profile = "personal" | "work" | "openclaw"` and all modules
# branch on the resulting flags.
{
  lib,
  config,
  ...
}: let
  cfg = config.local.profile;
in {
  options.local.profile = {
    name = lib.mkOption {
      type = lib.types.enum ["personal" "work" "openclaw"];
      description = "Machine profile — controls iCloud, AppStore, signing, etc.";
    };

    # Derived flags — modules consume these, not the profile name directly.
    # Hosts can override individual flags if needed.
    enableICloud = lib.mkOption {
      type = lib.types.bool;
      default = cfg.name == "personal";
      description = "Whether iCloud is available (synced folders, vault paths).";
    };

    enableMAS = lib.mkOption {
      type = lib.types.bool;
      default = cfg.name == "personal";
      description = "Whether Mac App Store installs are allowed.";
    };

    enableAppStoreCasks = lib.mkOption {
      type = lib.types.bool;
      default = cfg.name != "openclaw";
      description = "Whether paid/personal Homebrew casks (1Password, Spotify, etc.) are available.";
    };

    enableGPGSigning = lib.mkOption {
      type = lib.types.bool;
      default = cfg.name == "personal";
      description = "Whether git commits should be GPG-signed by default.";
    };

    enableObsidianMCP = lib.mkOption {
      type = lib.types.bool;
      default = cfg.name == "personal" || cfg.name == "work";
      description = "Whether Obsidian vault MCP server is enabled for AI tools.";
    };

    enableObsidian = lib.mkOption {
      type = lib.types.bool;
      default = cfg.name == "personal" || cfg.name == "work";
      description = "Whether to install Obsidian and provision a local knowledge vault.";
    };

    enableFirewallHardening = lib.mkOption {
      type = lib.types.bool;
      default = cfg.name == "openclaw";
      description = "Whether to enable strict firewall (stealth mode).";
    };

    personalCasks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default =
        if cfg.name == "personal"
        then [
          "1password"
          "spotify"
          "telegram"
          "obsidian"
          "chatgpt"
          "claude"
        ]
        else [];
      description = "Personal casks only available on personal profile.";
    };
  };
}
