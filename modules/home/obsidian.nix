# Obsidian vault structure — creates memory skeleton directories.
# Only runs on profiles with iCloud enabled (vault lives in iCloud Drive).
{
  config,
  osConfig,
  lib,
  ...
}: let
  cfg = osConfig.local.profile;
  vaultPath = "${config.home.homeDirectory}/Library/Mobile Documents/com~apple~CloudDocs/Obsidian";

  knownProjects =
    [
      "mac-config"
    ]
    ++ lib.optionals (cfg.name == "personal") [
      "claude-cowork"
      "openclaw"
      "yaroslav"
    ];

  projectSubdirs = [
    "research"
    "decisions"
    "bugs"
    "patterns"
    "sessions"
  ];

  mkProjectDirs = project:
    lib.concatMapStringsSep "\n" (
      sub: ''$DRY_RUN_CMD mkdir -p "${vaultPath}/Projects/${project}/${sub}"''
    )
    projectSubdirs;
in {
  home.activation.setupObsidian = lib.mkIf cfg.enableICloud (
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p "${vaultPath}/claude/memory"
      $DRY_RUN_CMD mkdir -p "${vaultPath}/claude/sessions"
      $DRY_RUN_CMD mkdir -p "${vaultPath}/claude/skills"
      $DRY_RUN_CMD mkdir -p "${vaultPath}/claude/projects"
      $DRY_RUN_CMD mkdir -p "${vaultPath}/inbox"

      ${lib.concatMapStringsSep "\n" mkProjectDirs knownProjects}
    ''
  );
}
