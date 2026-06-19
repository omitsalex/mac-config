# Obsidian vault — installs the knowledge-base skeleton and seeds the memory
# "rules" (templates + index). Runs on any profile with Obsidian enabled.
# Vault lives in iCloud on personal, locally (~/Documents/Obsidian) on work.
#
# Layout mirrors the personal vault so work→personal merge is a straight copy:
#   work/       — work project folders (echo, terraform, etc.)
#   pets/       — personal projects (mac-config, pp)  [personal only]
#   personal/   — personal life notes                  [personal only]
#   openclaw/   — openclaw sub-projects                [personal only]
#   claude/     — memory index, templates, sessions
#   inbox/      — quick capture
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

  projectSubdirs = ["research" "decisions" "bugs" "patterns" "sessions"];

  # Top-level category dirs to scaffold — work profile only gets work/.
  # Projects inside are created organically (by AI or user), not pre-built.
  topLevelDirs =
    ["work"]
    ++ lib.optionals (cfg.name == "personal") [
      "pets"
      "personal"
      "openclaw"
    ];

  mkProjectDirs = project:
    lib.concatMapStringsSep "\n" (
      sub: ''$DRY_RUN_CMD mkdir -p "${vaultPath}/${project}/${sub}"''
    )
    projectSubdirs;

  # Seed projects — only mac-config (under pets/) on personal.
  # Work profile: no pre-built projects, just the work/ dir.
  seedProjects = lib.optionals (cfg.name == "personal") [
    "pets/mac-config"
    "pets/pp"
  ];
in {
  home.activation.setupObsidian = lib.mkIf cfg.enableObsidian (
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Claude memory + templates
      $DRY_RUN_CMD mkdir -p "${vaultPath}/claude/memory"
      $DRY_RUN_CMD mkdir -p "${vaultPath}/claude/sessions"
      $DRY_RUN_CMD mkdir -p "${vaultPath}/claude/templates"
      $DRY_RUN_CMD mkdir -p "${vaultPath}/inbox"

      # Top-level category dirs
      ${lib.concatMapStringsSep "\n" (d: ''$DRY_RUN_CMD mkdir -p "${vaultPath}/${d}"'') topLevelDirs}

      # Seed project scaffolds (if any)
      ${lib.concatMapStringsSep "\n" mkProjectDirs seedProjects}

      # Seed the memory "rules" (templates + index) — copy-if-absent so user
      # edits are never overwritten; make the copies writable (store is 0444).
      $DRY_RUN_CMD cp -Rn ${seed}/claude/. "${vaultPath}/claude/" 2>/dev/null || true
      $DRY_RUN_CMD chmod -R u+w "${vaultPath}/claude" 2>/dev/null || true
    ''
  );
}
