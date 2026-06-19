# Git configuration
# GPG signing is controlled by the profile system.
{
  lib,
  pkgs,
  osConfig,
  ...
}: let
  cfg = osConfig.local.profile;
in {
  home.packages = with pkgs; [
    git
    git-lfs
    delta
    gnupg
  ];

  programs.git = {
    enable = true;

    # Set these per-machine or via sops secrets:
    #   git config --global user.name "Your Name"
    #   git config --global user.email "you@example.com"
    # userName = "Your Name";
    # userEmail = "you@example.com";

    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
      fetch.prune = true;
      push.autoSetupRemote = true;

      core = {
        editor = "vim";
        autocrlf = "input";
        excludesfile = "~/.config/git/gitignore_global";
        preloadIndex = true;
        fscache = true;
      };

      gpg.program = "${pkgs.gnupg}/bin/gpg";

      # GPG signing — enabled only on personal profile.
      # On other profiles, set manually:
      #   git config --global user.signingkey <KEY_ID>
      #   git config --global commit.gpgsign true
      commit.gpgsign = cfg.enableGPGSigning;
      tag.gpgsign = cfg.enableGPGSigning;

      diff = {
        algorithm = "histogram";
        colorMoved = "default";
      };

      merge.conflictstyle = "diff3";

      status = {
        showUntrackedFiles = "all";
        showStash = true;
      };

      color = {
        ui = "auto";
        diff = "auto";
        status = "auto";
        branch = "auto";
      };

      url = {
        "git@github.com:" = {
          insteadOf = "gh:";
          pushInsteadOf = ["github:" "git://github.com/"];
        };
        "git@gitlab.com:" = {
          insteadOf = "gl:";
          pushInsteadOf = ["gitlab:" "git://gitlab.com/"];
        };
        # NOTE: https->ssh rewrite intentionally removed.
        # It breaks `brew update` on fresh machines without SSH keys.
      };

      alias = {
        st = "status";
        ci = "commit";
        co = "checkout";
        br = "branch";
        unstage = "reset HEAD --";
        last = "log -1 HEAD";
        lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        wip = "!git add -A && git commit -m \"wip: $(date -Iseconds)\" && git push -u origin HEAD";
        sync = "!git fetch --all --prune && git pull --rebase --autostash";
        undo = "reset HEAD~1 --mixed";
        amend = "commit --amend";
        cleanup = "!git branch --merged | grep -v '\\*\\|master\\|main\\|dev' | xargs -n 1 git branch -d";
      };
    };

    signing.format = "openpgp";

    ignores = lib.strings.splitString "\n" (builtins.readFile ./gitignore_global);

    lfs.enable = true;
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      features = "decorations";
      side-by-side = true;
      line-numbers = true;
      navigate = true;
    };
  };

  home.file = {
    ".config/git/gitignore_global".source = ./gitignore_global;
  };
}
