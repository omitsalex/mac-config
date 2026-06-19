# fzf + zoxide via home-manager (Nix-managed zsh integration)
# Replaces the manual `eval "$(... init zsh)"` / oh-my-zsh fzf plugin.
{...}: {
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;

    # Use fd for listing (respects .gitignore, includes hidden, skips .git)
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
      "--info=inline"
    ];

    # Ctrl-T (file widget) with bat preview
    fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
    fileWidgetOptions = [
      "--preview 'bat --color=always --style=numbers --line-range=:200 {}'"
    ];

    # Alt-C (cd widget) with eza tree preview
    changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";
    changeDirWidgetOptions = [
      "--preview 'eza --tree --color=always {} | head -200'"
    ];

    # Ctrl-R (history widget)
    historyWidgetOptions = ["--sort" "--exact"];
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}
