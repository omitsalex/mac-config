# Atuin — magical shell history
# Sync shell history across machines with optional self-hosted or cloud sync
{...}: {
  programs.atuin = {
    enable = false; # Set to true to enable
    enableZshIntegration = true;

    settings = {
      search_mode = "fuzzy";
      filter_mode = "global";
      style = "compact";
      inline_height = 20;
      show_preview = true;

      auto_sync = false;
      update_check = false;
      exit_mode = "return-query";

      history_filter = [
        "^ls"
        "^cd"
        "^pwd"
        "^exit"
      ];

      show_help = true;
      max_preview_height = 4;
    };
  };

  # To enable atuin sync:
  # 1. Register at https://atuin.sh or self-host
  # 2. atuin register -u <username> -e <email>
  # 3. atuin login -u <username>
  # 4. Set auto_sync = true above
}
