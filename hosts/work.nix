# Host-specific configuration for work (Intel-based desktop)
{
  hostname,
  lib,
  ...
}: {
  networking.hostName = hostname;
  networking.localHostName = hostname;

  system.stateVersion = 4;

  system.activationScripts.computerName.text = ''
    scutil --set ComputerName "${hostname}"
  '';

  # Desktop-specific settings
  system.keyboard.remapCapsLockToControl = lib.mkForce true;

  # Desktop energy settings — less aggressive than laptops
  system.activationScripts.desktopEnergySettings = {
    enable = true;
    text = ''
      echo "Setting desktop energy settings for work..."
      /usr/bin/pmset -c displaysleep 30
    '';
  };
}
