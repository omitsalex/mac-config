# GPG configuration
# NOTE: No iCloud paths. Keys are imported from a local directory or manually.
{
  config,
  lib,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    gnupg
    pinentry_mac
  ];

  programs.gpg = {
    enable = true;

    settings = {
      keyserver = "hkps://keys.openpgp.org";
      trust-model = "tofu+pgp";
      use-agent = true;
      no-greeting = true;
      no-permission-warning = true;
      no-comments = true;
      no-emit-version = true;
      fixed-list-mode = true;
      with-fingerprint = true;
      keyid-format = "long";
      charset = "utf-8";

      personal-cipher-preferences = "AES256 AES192 AES";
      personal-digest-preferences = "SHA512 SHA384 SHA256";
      personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";

      cert-digest-algo = "SHA512";
      default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";

      list-options = "show-uid-validity";
      verify-options = "show-uid-validity";

      s2k-cipher-algo = "AES256";
      s2k-digest-algo = "SHA512";

      require-cross-certification = true;
      no-symkey-cache = true;
    };
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = false;
    pinentry.package = pkgs.pinentry_mac;
    defaultCacheTtl = 3600;
    defaultCacheTtlSsh = 3600;
    maxCacheTtl = 14400;
    maxCacheTtlSsh = 14400;
    extraConfig = ''
      allow-preset-passphrase
    '';
  };

  home.sessionVariables = {
    GPG_TTY = "$(tty)";
  };

  # Import GPG keys from a local directory (not iCloud)
  # Place your .asc/.gpg/.key files in ~/.config/gpg-keys/ before running install
  home.activation.importGpgKeys = lib.hm.dag.entryAfter ["writeBoundary"] ''
    GPG_KEYS_DIR="${config.home.homeDirectory}/.config/gpg-keys"

    if [ -d "$GPG_KEYS_DIR" ] && [ "$(ls -A "$GPG_KEYS_DIR" 2>/dev/null)" ]; then
      echo "Importing GPG keys from $GPG_KEYS_DIR..."
      mkdir -p "${config.home.homeDirectory}/.gnupg"
      chmod 700 "${config.home.homeDirectory}/.gnupg"

      for key_file in "$GPG_KEYS_DIR"/*.asc "$GPG_KEYS_DIR"/*.gpg "$GPG_KEYS_DIR"/*.key; do
        if [ -f "$key_file" ]; then
          echo "Importing key: $key_file"
          ${pkgs.gnupg}/bin/gpg --batch --no-tty --import "$key_file" || echo "Failed to import: $key_file"
        fi
      done
      echo "GPG key import completed."
    else
      echo "No GPG keys found in $GPG_KEYS_DIR. Skipping import."
      echo "  To import keys later, place .asc/.gpg/.key files in $GPG_KEYS_DIR"
    fi
  '';
}
