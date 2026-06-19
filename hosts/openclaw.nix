# Host-specific configuration for OpenClaw provisioning laptop (Apple Silicon)
# Admin user "user" runs darwin-rebuild; day-to-day user "openclaw" is non-admin
{
  hostname,
  lib,
  pkgs,
  system,
  config,
  nix-openclaw,
  ...
}: {
  imports = [./templates/laptop.nix];

  networking.hostName = hostname;
  networking.localHostName = hostname;

  system.stateVersion = 4;

  system.activationScripts.computerName.text = ''
    scutil --set ComputerName "${hostname}"
  '';

  # OpenClaw AI assistant — sourced from official nix-openclaw flake (always latest release)
  environment.systemPackages = [nix-openclaw.packages.${system}.openclaw];

  system.defaults.dock = {
    # Minimal dock for a provisioning/dev machine
    tilesize = lib.mkForce 36;
    autohide = lib.mkForce true;
    show-recents = lib.mkForce false;
  };

  # Firewall hardening — driven by profile flag
  system.activationScripts.firewallSettings = lib.mkIf config.local.profile.enableFirewallHardening {
    enable = true;
    text = ''
      echo "Enabling macOS firewall..."
      /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
      /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
    '';
  };
}
