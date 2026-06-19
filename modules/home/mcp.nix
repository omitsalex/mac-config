# MCP server packages and global config
{pkgs, ...}: {
  home.packages = [
    pkgs.github-mcp-server
    pkgs.mcp-grafana
    pkgs.mcp-k8s-go
    pkgs.terraform-mcp-server
  ];

  xdg.configFile."mcp/mcp.json".text = builtins.toJSON {
    servers = {
      github = {
        command = "${pkgs.github-mcp-server}/bin/github-mcp-server";
      };
      terraform = {
        command = "${pkgs.terraform-mcp-server}/bin/terraform-mcp-server";
      };
      k8s = {
        command = "${pkgs.mcp-k8s-go}/bin/mcp-k8s-go";
      };
    };
  };
}
