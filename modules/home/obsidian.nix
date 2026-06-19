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
  pkgs,
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

  # obsidian-sync script — push/pull vault archives to/from S3
  obsidianSync = pkgs.writeShellScriptBin "obsidian-sync" ''
    set -euo pipefail

    usage() { echo "Usage: obsidian-sync <push|pull|clean> <s3-bucket> [vault-name]"; exit 1; }

    ACTION="''${1:-}"; [ -z "$ACTION" ] && usage
    BUCKET="''${2:-}"; [ -z "$BUCKET" ] && usage
    VAULT="''${3:-work}"
    VAULT_DIR="${vaultPath}/$VAULT"
    S3_PREFIX="s3://''${BUCKET}/obsidian"

    case "$ACTION" in
      push)
        [ -d "$VAULT_DIR" ] || { echo "vault not found: $VAULT_DIR"; exit 1; }
        ARCHIVE="obsidian-''${VAULT}-$(date +%Y%m%d-%H%M%S).tar.gz"
        tar --exclude='.obsidian' --exclude='.DS_Store' --exclude='.trash' \
          -czf "/tmp/''${ARCHIVE}" -C "$(dirname "$VAULT_DIR")" "$VAULT"
        aws s3 cp "/tmp/''${ARCHIVE}" "''${S3_PREFIX}/''${ARCHIVE}"
        echo "pushed ''${S3_PREFIX}/''${ARCHIVE} ($(du -h "/tmp/''${ARCHIVE}" | cut -f1))"
        rm -f "/tmp/''${ARCHIVE}"
        ;;
      pull)
        LATEST=$(aws s3 ls "''${S3_PREFIX}/obsidian-''${VAULT}-" \
          | sort | tail -1 | awk '{print $NF}')
        [ -z "$LATEST" ] && { echo "no archive found in ''${S3_PREFIX}/"; exit 1; }
        aws s3 cp "''${S3_PREFIX}/''${LATEST}" "/tmp/obsidian-pull.tar.gz"
        mkdir -p "$(dirname "$VAULT_DIR")"
        tar xzf "/tmp/obsidian-pull.tar.gz" -C "$(dirname "$VAULT_DIR")"
        echo "pulled ''${S3_PREFIX}/''${LATEST} → $VAULT_DIR/"
        rm -f "/tmp/obsidian-pull.tar.gz"
        ;;
      clean)
        echo "deleting all objects under ''${S3_PREFIX}/"
        aws s3 rm "''${S3_PREFIX}/" --recursive
        echo "done"
        ;;
      *)
        usage
        ;;
    esac
  '';
in {
  home.packages = lib.mkIf cfg.enableObsidian [obsidianSync];

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
