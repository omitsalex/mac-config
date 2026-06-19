# Common settings for laptop hosts
{lib, ...}: {
  # Laptop-focused energy settings
  system.activationScripts.laptopEnergySettings = {
    enable = true;
    text = ''
      echo "Setting laptop energy optimization settings..."
      /usr/bin/pmset -b displaysleep 5
      /usr/bin/pmset -b sleep 15
      /usr/bin/pmset -c displaysleep 15
    '';
  };

  system.keyboard.remapCapsLockToControl = lib.mkForce true;
}
