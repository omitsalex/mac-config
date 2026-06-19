# Secrets management via sops-nix
# Personal profile: secrets from iCloud vault. Others: from repo.
{
  config,
  osConfig,
  lib,
  ...
}: let
  cfg = osConfig.local.profile;

  # iCloud secrets path (personal profile only)
  iCloudSecretsFile = "${config.home.homeDirectory}/Library/Mobile Documents/com~apple~CloudDocs/Backups/osx/secrets/sops/secrets.yaml";
  iCloudAgeKeyFile = "${config.home.homeDirectory}/Library/Application Support/sops/age/keys.txt";

  # Repo secrets path (work/openclaw profiles)
  repoSecretsFile = ../../secrets/secrets.yaml;
  localAgeKeyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

  secretsFile =
    if cfg.enableICloud
    then iCloudSecretsFile
    else repoSecretsFile;
  ageKeyFile =
    if cfg.enableICloud
    then iCloudAgeKeyFile
    else localAgeKeyFile;
in {
  home.sessionVariables = {
    SOPS_AGE_KEY_FILE = ageKeyFile;
  };

  sops = lib.mkMerge [
    {
      age = {
        keyFile = ageKeyFile;
        generateKey = false;
      };
    }
    (lib.mkIf (cfg.enableICloud || builtins.pathExists repoSecretsFile) {
      defaultSopsFile =
        if cfg.enableICloud
        then iCloudSecretsFile
        else repoSecretsFile;
      validateSopsFiles = false;
    })
  ];
}
