# Host-specific configuration for airmac (ARM-based MacBook)
{hostname, ...}: {
  imports = [./templates/laptop.nix];

  networking.hostName = hostname;
  networking.localHostName = hostname;

  system.stateVersion = 4;

  system.activationScripts.computerName.text = ''
    scutil --set ComputerName "${hostname}"
  '';

  system.defaults.NSGlobalDomain = {};
  system.defaults.dock = {};
}
