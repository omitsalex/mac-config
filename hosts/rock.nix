# Host-specific configuration for rock (Intel laptop)
{hostname, ...}: {
  imports = [./templates/laptop.nix];

  networking.hostName = hostname;
  networking.localHostName = hostname;

  system.stateVersion = 4;

  system.activationScripts.computerName.text = ''
    echo "Setting ComputerName to ${hostname}" >&2
    scutil --set ComputerName "${hostname}"
  '';
}
