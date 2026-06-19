# OpenCode configuration
# Obsidian MCP server is enabled only on personal profile (requires iCloud).
{
  pkgs,
  config,
  osConfig,
  ...
}: let
  cfg = osConfig.local.profile;
  opencodeBin = "${pkgs.opencode}/bin/opencode";
  dockerBin = "docker";
  npxBin = "${pkgs.nodejs}/bin/npx";

  vaultPath =
    if cfg.enableICloud
    then "${config.home.homeDirectory}/Library/Mobile Documents/com~apple~CloudDocs/Obsidian"
    else "${config.home.homeDirectory}/Documents/Obsidian";

  # Obsidian vault MCP — enabled on profiles with Obsidian (personal + work)
  obsidianMCP =
    if cfg.enableObsidianMCP
    then {
      obsidian_memory = {
        type = "local";
        command = [npxBin "-y" "@anthropic/mcp-server-filesystem" vaultPath];
        enabled = true;
      };
    }
    else {};
in {
  programs.zsh.shellAliases = {
    o = "opencode";
    oc = "opencode --continue";
    or = "opencode run";
  };

  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    model = "github-copilot/claude-opus-4.6";
    small_model = "github-copilot/gpt-4o-mini";

    mcp =
      {
        github = {
          type = "local";
          command = ["${pkgs.github-mcp-server}/bin/github-mcp-server" "stdio"];
          enabled = false;
          environment = {
            GITHUB_PERSONAL_ACCESS_TOKEN = "{env:GITHUB_PERSONAL_ACCESS_TOKEN}";
          };
        };

        sentry = {
          type = "remote";
          url = "https://mcp.sentry.dev/mcp";
          enabled = false;
          oauth = {};
        };

        grafana = {
          type = "local";
          command = [
            dockerBin
            "run"
            "--rm"
            "-i"
            "-e"
            "GRAFANA_URL"
            "-e"
            "GRAFANA_SERVICE_ACCOUNT_TOKEN"
            "grafana/mcp-grafana"
            "-t"
            "stdio"
          ];
          enabled = false;
          environment = {
            GRAFANA_URL = "{env:GRAFANA_URL}";
            GRAFANA_SERVICE_ACCOUNT_TOKEN = "{env:GRAFANA_SERVICE_ACCOUNT_TOKEN}";
          };
        };

        prometheus = {
          type = "local";
          command = [npxBin "-y" "@anthropic/mcp-server-prometheus"];
          enabled = false;
          environment = {
            PROMETHEUS_URL = "{env:PROMETHEUS_URL}";
          };
        };

        elasticsearch = {
          type = "local";
          command = [npxBin "-y" "@anthropic/mcp-server-elasticsearch"];
          enabled = false;
          environment = {
            ELASTICSEARCH_URL = "{env:ELASTICSEARCH_URL}";
            ELASTICSEARCH_API_KEY = "{env:ELASTICSEARCH_API_KEY}";
          };
        };

        terraform = {
          type = "local";
          command = ["${pkgs.terraform-mcp-server}/bin/terraform-mcp-server"];
          enabled = false;
        };

        k8s = {
          type = "local";
          command = ["${pkgs.mcp-k8s-go}/bin/mcp-k8s-go"];
          enabled = false;
        };

        atlassian = {
          type = "remote";
          url = "https://mcp.atlassian.com/v1/mcp";
          enabled = true;
          oauth = {};
        };

        context7 = {
          type = "remote";
          url = "https://mcp.context7.com/mcp";
          enabled = false;
        };

        gh_grep = {
          type = "remote";
          url = "https://mcp.grep.app";
          enabled = false;
        };
      }
      // obsidianMCP;
  };

  # Custom commands — deterministic triggers over the memory protocol.
  # /recall pulls vault context; /flush persists session state; /lint audits wiki.
  xdg.configFile."opencode/commands/recall.md".text = ''
    ---
    description: Pull vault context on a topic into the session
    ---
    Search the project vault for everything relevant to: $ARGUMENTS

    Read matching notes across research/, decisions/, bugs/, patterns/ and their
    _index.md links. Summarise in ≤6 lines what exists and how it bears on the
    current work. If nothing exists, say so plainly — do not invent.
  '';

  xdg.configFile."opencode/commands/flush.md".text = ''
    ---
    description: Persist current session state to Obsidian now
    ---
    Apply the ingest and incremental update protocols for everything since the
    last write:
    - new research → research/{topic}.md
    - design choices → decisions/{NNNN}-{slug}.md
    - bugs found/fixed → bugs/{slug}.md
    - reusable patterns → patterns/{slug}.md
    - useful syntheses/analyses → file as new wiki pages

    For each new note, also update any existing notes that are affected by the
    new information (cross-references, contradictions, extensions).

    Append progress to the current session file and update _index.md for every
    new or modified note. Report in 3-5 lines what you wrote — paths only.
  '';

  xdg.configFile."opencode/commands/lint.md".text = ''
    ---
    description: Health-check the project wiki
    ---
    Read the project `_index.md` and scan the vault folder for this project.
    Check for:

    1. **Orphan pages** — files in the project folder not linked from _index.md
    2. **Dead links** — wikilinks in _index.md pointing to non-existent files
    3. **Stale notes** — research/ notes older than 90 days without update
    4. **Missing cross-references** — notes that mention the same topic but
       don't link to each other
    5. **Empty sections** — _index.md sections with no entries
    6. **Contradictions** — notes where newer information supersedes older claims
       but the old note isn't marked as superseded

    Report findings as a numbered list. For each issue, state the fix.
    Ask before applying fixes.
  '';

  launchd.agents.opencode-web = {
    enable = true;
    config = {
      ProgramArguments = [opencodeBin "web"];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
