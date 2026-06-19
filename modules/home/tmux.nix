# tmux configuration
{pkgs, ...}: {
  programs.tmux = {
    enable = true;

    baseIndex = 1;
    escapeTime = 0;
    historyLimit = 50000;
    keyMode = "vi";
    mouse = true;

    terminal = "screen-256color";
    shortcut = "a";

    extraConfig = ''
      set-option -g status-position top

      set -g default-terminal "screen-256color"
      set -ga terminal-overrides ",xterm-256color:Tc"

      set -g focus-events on

      setw -g monitor-activity on
      set -g visual-activity on

      set -g renumber-windows on

      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %

      bind r source-file ~/.tmux.conf \; display-message "Config reloaded!"

      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D

      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi y send-keys -X copy-selection
      bind-key -T copy-mode-vi r send-keys -X rectangle-toggle

      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      bind-key -n C-S-Left swap-window -t -1
      bind-key -n C-S-Right swap-window -t +1

      bind-key S set-window-option synchronize-panes\; display-message "synchronize-panes is now #{?pane_synchronized,on,off}"

      set -g status-style fg=white,bg=black
      set -g window-status-current-style fg=black,bold,bg=white
      set -g pane-border-style fg=white
      set -g pane-active-border-style fg=green
      set -g message-style fg=white,bold,bg=black

      set -g status-left-length 40
      set -g status-left "#[fg=green]Session: #S #[fg=yellow]#I #[fg=cyan]#P"
      set -g status-right "#[fg=cyan]%d %b %R #[fg=magenta]#H"
      set -g status-interval 60
      set -g status-justify centre
    '';

    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      resurrect
      continuum
      {
        plugin = dracula;
        extraConfig = ''
          set -g @dracula-show-battery false
          set -g @dracula-show-network false
          set -g @dracula-show-weather false
          set -g @dracula-show-fahrenheit false
          set -g @dracula-show-powerline true
          set -g @dracula-show-left-icon session
          set -g @dracula-border-contrast true
          set -g @dracula-cpu-usage true
          set -g @dracula-ram-usage true
          set -g @dracula-day-month true
        '';
      }
    ];
  };
}
