# Comprehensive package configuration for macOS
# MAS apps and personal casks are conditional on profile flags.
{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.local.profile;

  # Base casks — available on all profiles
  baseCasks = [
    "iterm2"
    "visual-studio-code"
    "docker-desktop"
    "postman"
    "alt-tab"
    "gpg-suite"
    "slack"
    "google-chrome"
    "firefox"
    "zen"
    "vlc"
  ];

  # Personal-only casks (require AppStore account or personal license)
  personalCasks = lib.optionals cfg.enableAppStoreCasks [
    "1password"
    "spotify"
  ];

  # MAS apps — only on personal profile
  masApps =
    if cfg.enableMAS
    then {
      "1Password for Safari" = 1569813296;
      "AdBlock Pro" = 1018301773;
      "Magnet" = 441258766;
    }
    else {};
in {
  # =========================================================================
  # CLI tools installed via Nix
  # =========================================================================
  environment.systemPackages = with pkgs; [
    # Essential CLI tools
    vim
    curl
    wget
    git
    git-crypt
    coreutils
    ripgrep
    tree
    tmux
    fzf
    jq
    yq-go
    htop
    btop
    bat
    watch
    pwgen
    unzip
    p7zip
    pigz
    mosh
    zlib

    # Network tools
    nmap
    mtr
    openssl
    iperf3
    sshuttle

    # Development tools
    direnv
    nix-direnv
    neovim
    starship

    # AI coding tools
    opencode

    # Modern productivity tools
    eza
    zoxide
    fd
    ripgrep
    delta
    dust
    tealdeer
    gh
    atuin

    # Infrastructure tools
    sops
    age
    envconsul
    (kubernetes-helmPlugins.helm-diff)
    (kubernetes-helmPlugins.helm-secrets)

    # Container tools
    colima

    # Git tools
    lazygit
  ];

  # =========================================================================
  # Kubectl plugins (ctx, ns) via activation script
  # =========================================================================
  system.activationScripts.installKubectlPlugins = {
    enable = true;
    text = ''
      echo "Installing kubectl plugins (ctx and ns)..."
      if [ ! -w "/usr/local/bin" ]; then
        SUDO_CMD="sudo"
      else
        SUDO_CMD=""
      fi
      BIN_DIR="/usr/local/bin"
      TMP_DIR="$(mktemp -d)"
      cd "$TMP_DIR"
      curl -s -o "kubectl-ctx" https://raw.githubusercontent.com/weibeld/kubectl-ctx/master/kubectl-ctx
      chmod +x "kubectl-ctx"
      $SUDO_CMD mv "kubectl-ctx" "$BIN_DIR/kubectl-ctx"
      curl -s -o "kubectl-ns" https://raw.githubusercontent.com/weibeld/kubectl-ns/master/kubectl-ns
      chmod +x "kubectl-ns"
      $SUDO_CMD mv "kubectl-ns" "$BIN_DIR/kubectl-ns"
      cd - > /dev/null
      rm -rf "$TMP_DIR"
    '';
  };

  # =========================================================================
  # Homebrew — disabled by default; use `brew bundle` manually
  # =========================================================================
  homebrew = {
    enable = false;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
    };

    taps = [
      "hashicorp/tap"
      "mongodb/brew"
      "smudge/smudge"
    ];

    brews = [
      "nightlight"
      "pinentry-mac"
      "ncdu"
      "awscli"
      "tfenv"
      "nvm"
      "pyenv"
      "rbenv"
      "terragrunt"
      "terraformer"
      "hashicorp/tap/vault"
      "ansible"
      "argocd"
      "kubernetes-cli"
      "helm"
      "helmfile"
      "kops"
      "kube-ps1"
      "stern"
      "krew"
      "aws-iam-authenticator"
      "libpq"
      "hugo"
      "iproute2mac"
      "archey4"
      "zsh-autosuggestions"
      "zsh-syntax-highlighting"
    ];

    casks = baseCasks ++ personalCasks ++ cfg.personalCasks;

    masApps = masApps;
  };
}
