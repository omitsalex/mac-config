# Obsidian vault — installs the knowledge-base skeleton and seeds the memory
# "rules" (templates + index). Runs on any profile with Obsidian enabled.
# Vault lives in iCloud on personal, locally (~/Documents/Obsidian) elsewhere.
{
  config,
  osConfig,
  lib,
  ...
}: let
  cfg = osConfig.local.profile;

  vaultPath =
    if cfg.enableICloud
    then "${config.home.homeDirectory}/Library/Mobile Documents/com~apple~CloudDocs/Obsidian"
    else "${config.home.homeDirectory}/Documents/Obsidian";

  seed = ../../obsidian/vault-seed;

  knownProjects =
    ["mac-config"]
    ++ lib.optionals (cfg.name == "personal") [
      "claude-cowork"
      "openclaw"
      "yaroslav"
    ];

  projectSubdirs = ["research" "decisions" "bugs" "patterns" "sessions"];

  mkProjectDirs = project:
    lib.concatMapStringsSep "\n" (
      sub: ''$DRY_RUN_CMD mkdir -p "${vaultPath}/Projects/${project}/${sub}"''
    )
    projectSubdirs;
in {
  home.activation.setupObsidian = lib.mkIf cfg.enableObsidian (
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p "${vaultPath}/claude/memory"
      $DRY_RUN_CMD mkdir -p "${vaultPath}/claude/sessions"
      $DRY_RUN_CMD mkdir -p "${vaultPath}/claude/templates"
      $DRY_RUN_CMD mkdir -p "${vaultPath}/claude/projects"
      $DRY_RUN_CMD mkdir -p "${vaultPath}/inbox"

      ${lib.concatMapStringsSep "\n" mkProjectDirs knownProjects}

      # Seed the memory "rules" (templates + index) — copy-if-absent so user
      # edits are never overwritten; make the copies writable (store is 0444).
      $DRY_RUN_CMD cp -Rn ${seed}/claude/. "${vaultPath}/claude/" 2>/dev/null || true
      $DRY_RUN_CMD chmod -R u+w "${vaultPath}/claude" 2>/dev/null || true
    ''
  );
}
