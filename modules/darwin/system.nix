# macOS system settings — consolidated common configuration
# NOTE: No personal data. All user-specific values come from host configs or variables.
{
  pkgs,
  adminUsername,
  ...
}: {
  environment.shells = with pkgs; [zsh bash];

  # Primary user — the admin who runs darwin-rebuild
  system.primaryUser = adminUsername;

  # macOS system defaults
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyleSwitchesAutomatically = true;
      AppleShowAllExtensions = true;
      NSAutomaticSpellingCorrectionEnabled = false;
      "com.apple.swipescrolldirection" = true;

      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;

      AppleEnableMouseSwipeNavigateWithScrolls = true;
      AppleEnableSwipeNavigateWithScrolls = true;
      "com.apple.mouse.tapBehavior" = 1;
      "com.apple.trackpad.enableSecondaryClick" = true;
      "com.apple.trackpad.trackpadCornerClickBehavior" = 1;

      NSTableViewDefaultSizeMode = 2;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
    };

    dock = {
      autohide = true;
      show-recents = false;
      tilesize = 40;
      mru-spaces = false;
      minimize-to-application = true;
      orientation = "bottom";
      showhidden = true;
    };

    finder = {
      AppleShowAllExtensions = true;
      CreateDesktop = true;
      FXEnableExtensionChangeWarning = false;
      QuitMenuItem = true;
      _FXShowPosixPathInTitle = true;
      ShowPathbar = true;
      ShowStatusBar = true;
    };

    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = true;
    };

    loginwindow = {
      GuestEnabled = false;
      SHOWFULLNAME = true;
    };
  };

  # Keyboard settings
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  system.activationScripts.keyboardSettings.text = ''
    echo "Setting up keyboard repeat rate..."
    defaults write -g KeyRepeat -int 1
    defaults write -g InitialKeyRepeat -int 10
  '';

  # Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # Energy saving defaults (hosts can override)
  system.activationScripts.extraActivation.enable = true;
  system.activationScripts.extraActivation.text = ''
    echo "Setting energy saving preferences..."
    /usr/bin/pmset -b displaysleep 15
    /usr/bin/pmset -b sleep 30
    /usr/bin/pmset -c displaysleep 30
    /usr/bin/pmset -c sleep 0
  '';

  # Night Shift (auto mode)
  system.activationScripts.night.text = ''
    ${pkgs.nightshiftcontrol}/bin/nightshiftcontrol -m auto
  '';

  # Time Machine — don't prompt for new drives
  system.activationScripts.timeMachine = {
    enable = true;
    text = ''
      echo "Setting up Time Machine preferences..."
      defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
    '';
  };

  # Dark wallpaper
  system.activationScripts.darkWallpaper = {
    enable = true;
    text = ''
      echo "Setting dark wallpaper..."
      osascript -e '
        tell application "System Events"
          tell every desktop
            set picture to ""
            set background color to {0, 0, 0}
          end tell
        end tell'
    '';
  };
}
