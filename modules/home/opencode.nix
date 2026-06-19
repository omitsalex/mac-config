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

  launchd.agents.opencode-web = {
    enable = true;
    config = {
      ProgramArguments = [opencodeBin "web"];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
