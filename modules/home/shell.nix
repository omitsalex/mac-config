# Shell configuration with ZSH
# NOTE: All iCloud paths and personal symlinks removed.
#       Secrets are handled via sops-nix, not iCloud.
{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "docker"
        "docker-compose"
        "kubectl"
        "terraform"
        "history"
        "python"
        "tmux"
        "kube-ps1"
      ];
      theme = "";
    };

    history = {
      size = 50000;
      save = 50000;
      path = "${config.home.homeDirectory}/.zsh_history";
      ignoreDups = true;
      expireDuplicatesFirst = true;
      extended = true;
      share = true;
    };

    defaultKeymap = "emacs";

    initContent = lib.mkMerge [
      # First: Instant prompt
      (lib.mkBefore ''
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
        typeset -ag _omz_async_functions || true
        export KONSOLE_PROFILE_NAME=""
        export KONSOLE_DBUS_SESSION=""
        export KUBE_PS1_ENABLED=1
        export KUBECONFIG=""

        # Krew for kubectl plugins
        export PATH="$HOME/.krew/bin:$PATH"

        # NVM (Node Version Manager)
        export NVM_DIR="$HOME/.nvm"
        if [ -s "/opt/homebrew/opt/nvm/nvm.sh" ]; then
          source "/opt/homebrew/opt/nvm/nvm.sh"
        elif [ -s "/usr/local/opt/nvm/nvm.sh" ]; then
          source "/usr/local/opt/nvm/nvm.sh"
        elif [ -s "$NVM_DIR/nvm.sh" ]; then
          source "$NVM_DIR/nvm.sh"
        fi
        if [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ]; then
          source "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
        elif [ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ]; then
          source "/usr/local/opt/nvm/etc/bash_completion.d/nvm"
        elif [ -s "$NVM_DIR/bash_completion" ]; then
          source "$NVM_DIR/bash_completion"
        fi
      '')

      # Second: Powerlevel10k theme
      (lib.mkOrder 550 ''
        POWERLEVEL10K_INSTALLATION_PATH="${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k"
        if [ -f "$POWERLEVEL10K_INSTALLATION_PATH/powerlevel10k.zsh-theme" ]; then
          source "$POWERLEVEL10K_INSTALLATION_PATH/powerlevel10k.zsh-theme"
        fi
      '')

      # Third: Main configuration
      ''
        POSTDISPLAY=""

        # Better directory navigation
        setopt AUTO_PUSHD
        setopt PUSHD_IGNORE_DUPS
        setopt PUSHD_SILENT

        # Improved command history
        setopt HIST_VERIFY
        setopt HIST_IGNORE_SPACE
        setopt HIST_SAVE_NO_DUPS

        # Initialize zoxide (smart cd)
        # fzf, zoxide and direnv zsh integration are provided by their
        # home-manager modules (fzf.nix / direnv.nix) — no manual eval here.

        # Key bindings
        bindkey '^[[A' up-line-or-search
        bindkey '^[[B' down-line-or-search
        bindkey '^[[1;5D' backward-word
        bindkey '^[[1;5C' forward-word
        bindkey -s '^o' 'nvim $(fzf)^M'
        bindkey '^r' history-incremental-search-backward

        # Project directories
        mkdir -p $HOME/Projects/Sandbox

        # ── AWS / Kubernetes / Auth0 helpers ──────────────────────────────
        # Generic & parameterized — NO company names here. Put your real
        # profile / cluster / tenant names in ~/.zshrc_local (untracked).
        #
        # Set TF_AWS_REPO in ~/.zshrc_local to your terraform repo to auto-
        # discover AWS profiles + EKS clusters defined there, e.g.:
        #   export TF_AWS_REPO="$HOME/Projects/<org>/terraform"

        # AWS profiles: ~/.aws/config ∪ $TF_AWS_REPO/.aws/config ∪ profile="…" in TF files
        _aws_profiles() {
          {
            aws configure list-profiles 2>/dev/null
            if [ -n "$TF_AWS_REPO" ] && [ -d "$TF_AWS_REPO" ]; then
              # INI-style [profile X] from repo .aws/config
              [ -f "$TF_AWS_REPO/.aws/config" ] && \
                awk '/^\[profile / { sub(/^\[profile[[:space:]]+/, ""); sub(/\].*/, ""); print }' \
                  "$TF_AWS_REPO/.aws/config" 2>/dev/null
              # HCL-style profile = "X" from .tf files
              grep -rhoE 'profile[[:space:]]*=[[:space:]]*"[^"]+"' "$TF_AWS_REPO" \
                --include='*.tf' --include='*.hcl' 2>/dev/null \
                | sed -E 's/.*"([^"]+)".*/\1/'
            fi
          } | sed '/^$/d' | sort -u
        }
        # Resolve the region for a given profile from all known AWS config files
        # (TF_AWS_REPO/.aws/config first, then ~/.aws/config).
        _aws_profile_region() {
          local p="$1" cfg region
          for cfg in \
            "''${TF_AWS_REPO:+$TF_AWS_REPO/.aws/config}" \
            "$HOME/.aws/config"; do
            [ -n "$cfg" ] && [ -f "$cfg" ] || continue
            region=$(awk -v p="$p" '
              /^\[profile / { cur = $0; sub(/^\[profile[[:space:]]+/, "", cur); sub(/\].*/, "", cur) }
              cur == p && /^[[:space:]]*region[[:space:]]*=/ { sub(/.*=[[:space:]]*/, ""); print; exit }
            ' "$cfg")
            [ -n "$region" ] && { echo "$region"; return; }
          done
        }
        # List profiles with their regions (tab-separated) for fzf display
        _aws_profiles_with_region() {
          local profiles p r
          profiles=("''${(@f)$(_aws_profiles)}")
          for p in "''${profiles[@]}"; do
            r=$(_aws_profile_region "$p")
            printf '%s\t%s\n' "$p" "''${r:-us-east-1}"
          done
        }
        awsp() {                       # awsp [profile]  (fzf over aws + terraform profiles)
          local p="$1"
          if [ -z "$p" ] && command -v fzf >/dev/null 2>&1; then
            p=$(_aws_profiles_with_region \
              | column -t -s $'\t' \
              | fzf --prompt='aws profile> ' \
              | awk '{print $1}')
          fi
          if [ -n "$p" ]; then
            export AWS_PROFILE="$p"
            local r; r=$(_aws_profile_region "$p")
            r="''${r:-us-east-1}"
            export AWS_REGION="$r" AWS_DEFAULT_REGION="$r"
          fi
          echo "AWS_PROFILE=''${AWS_PROFILE:-<unset>}  AWS_REGION=''${AWS_REGION:-<unset>}"
        }
        awsx()        { unset AWS_PROFILE AWS_DEFAULT_PROFILE; echo "AWS profile cleared"; }
        awsprofiles() { _aws_profiles; }
        awswho()      { aws sts get-caller-identity; }
        awsregion()   { [ -n "$1" ] && export AWS_REGION="$1" AWS_DEFAULT_REGION="$1"; echo "AWS_REGION=''${AWS_REGION:-<unset>}"; }
        # Okta → AWS auth (okta-awscli); defaults to current AWS_PROFILE
        oktalogin()   { command -v okta-awscli >/dev/null 2>&1 && okta-awscli -p "''${1:-$AWS_PROFILE}"; }

        # Kubernetes context / namespace
        kctx() { if [ -n "$1" ]; then kubectl config use-context "$1"; else kubectl config get-contexts; fi; }
        kns()  { if [ -n "$1" ]; then kubectl config set-context --current --namespace="$1" && echo "namespace=$1"; else kubectl get ns; fi; }
        # EKS clusters: live (aws eks list-clusters) ∪ names found in $TF_AWS_REPO
        _eks_clusters() {
          {
            aws eks list-clusters --query 'clusters[]' --output text 2>/dev/null | tr '\t' '\n'
            [ -n "$TF_AWS_REPO" ] && [ -d "$TF_AWS_REPO" ] && \
              grep -rhoE '(cluster_name|cluster-name|eks_cluster_name)[[:space:]]*=[[:space:]]*"[^"]+"' "$TF_AWS_REPO" 2>/dev/null \
              | sed -E 's/.*"([^"]+)".*/\1/'
          } | sed '/^$/d' | sort -u
        }
        keksp() {                      # keksp [cluster] [region]  (fzf over live + terraform clusters)
          local c="$1" region="''${2:-''${AWS_REGION:-us-east-1}}"
          [ -z "$c" ] && command -v fzf >/dev/null 2>&1 && c=$(_eks_clusters | fzf --prompt='eks cluster> ')
          [ -n "$c" ] && aws eks update-kubeconfig --name "$c" --region "$region"
        }
        keks()      { aws eks update-kubeconfig --name "$1" --region "''${2:-''${AWS_REGION:-us-east-1}}"; }   # keks <cluster> [region]
        kclusters() { _eks_clusters; }

        # Auth0 tenant switching (auth0 CLI)
        a0use() {                      # a0use [tenant]  (fzf picker if no arg)
          if [ -n "$1" ]; then auth0 tenants use "$1"
          elif command -v fzf >/dev/null 2>&1; then
            local t; t=$(auth0 tenants list 2>/dev/null | awk 'NR>1{print $1}' | fzf) && auth0 tenants use "$t"
          fi
        }
        a0tenants() { auth0 tenants list; }
        a0login()   { auth0 login; }
        # ──────────────────────────────────────────────────────────────────

        # p10k configuration
        if [[ ! -f ~/.p10k.zsh ]]; then
          echo "# Default p10k configuration" > ~/.p10k.zsh
          echo "# Run 'p10k configure' to regenerate" >> ~/.p10k.zsh
        fi
        [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
        [[ -f ~/.p10k-custom.zsh ]] && source ~/.p10k-custom.zsh

        # Personal config overlay (optional)
        [[ -f ~/.zshrc_personal ]] && source ~/.zshrc_personal
        # Machine-local overlay — your real AWS profiles / clusters / Auth0
        # tenants live here. NOT managed by this repo (create it yourself).
        [[ -f ~/.zshrc_local ]] && source ~/.zshrc_local
      ''
    ];

    shellAliases = {
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      cd = "z";

      ls = "eza --icons --group-directories-first";
      ll = "eza -l --icons --group-directories-first";
      la = "eza -la --icons --group-directories-first";
      lt = "eza --tree --icons --group-directories-first";
      mkdir = "mkdir -p";
      rm = "rm -i";
      cp = "cp -i";
      mv = "mv -i";

      g = "git";
      ga = "git add";
      gc = "git commit";
      gco = "git checkout";
      gd = "git diff";
      gs = "git status";
      gl = "git log";
      gp = "git push";
      gpl = "git pull";

      cat = "bat --plain";
      top = "btop";
      htop = "btop";
      find = "fd";
      grep = "rg";
      du = "dust";

      k = "kubectl";
      tf = "terraform";
      dc = "docker-compose";

      nrs = "darwin-rebuild switch --flake .";
      nfu = "nix flake update";
      nfc = "nix flake check";

      lg = "lazygit";
      h = "history";
      j = "jobs -l";
      diskspace = "df -h";
      tldr = "tldr --color always";
    };
  };

  home.packages = with pkgs; [
    zsh-powerlevel10k
  ];

  # Starship prompt (disabled — using powerlevel10k)
  programs.starship = {
    enable = false;
    settings = {
      add_newline = true;
      format =
        ""
        + "$username"
        + "$hostname"
        + "$directory"
        + "$git_branch$git_state$git_status"
        + "$aws$kubernetes"
        + "$line_break"
        + "$character";

      aws = {
        format = "[$symbol$profile(\\($region\\))]($style) ";
        symbol = "AWS ";
        style = "bold yellow";
      };

      kubernetes = {
        format = "[$symbol$context( \\($namespace\\))]($style) ";
        symbol = "K8S ";
        style = "bold cyan";
        disabled = false;
      };

      directory = {
        truncation_length = 3;
        truncation_symbol = ".../";
        style = "bold blue";
      };

      git_branch = {
        symbol = "BR ";
        style = "bold green";
      };

      character = {
        success_symbol = "[>](bold green)";
        error_symbol = "[x](bold red)";
      };
    };
  };
}
