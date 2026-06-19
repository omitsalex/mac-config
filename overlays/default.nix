# Custom overlays for Nixpkgs
_final: prev: {
  # Disable Node.js 20 (causes build issues on macOS)
  nodejs_20_x = prev.nodejs_20_x.overrideAttrs (_old: {
    meta.broken = true;
  });

  nodejs-20_x = prev.nodejs-20_x.overrideAttrs (_old: {
    meta.broken = true;
  });

  # Use Node.js 24 (current LTS) as default
  nodejs = prev.nodejs_24;

  # Disable problematic fonts
  iosevka = prev.iosevka.overrideAttrs (_oldAttrs: {
    meta.broken = true;
  });

  # Disable problematic Python packages
  python3Packages =
    prev.python3Packages
    // {
      inline-snapshot = prev.python3Packages.inline-snapshot.overrideAttrs (_oldAttrs: {
        meta.broken = true;
      });
      fastapi = prev.python3Packages.fastapi.overrideAttrs (_oldAttrs: {
        meta.broken = true;
      });
    };
}
