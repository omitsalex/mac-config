# Install Node.js 24 (current LTS) and npm; set related env vars
# Note: overlay in overlays/default.nix maps pkgs.nodejs → nodejs_24
{pkgs, ...}: {
  home.packages = with pkgs; [
    nodejs # resolves to nodejs_24 via overlay
  ];

  home.sessionVariables = {
    NODE_SKIP_PLATFORM_CHECK = "1";
    NODE_NO_WARNINGS = "1";
    NODE_OPTIONS = "--max-old-space-size=4096";
    NO_UPDATE_NOTIFIER = "true";
  };
}
