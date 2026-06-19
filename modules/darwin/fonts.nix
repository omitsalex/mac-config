# Font configuration for macOS
{pkgs, ...}: {
  fonts = {
    packages = [
      # Include JetBrains Mono Nerd Font from repo
      (pkgs.stdenv.mkDerivation {
        pname = "JetBrainsMonoNerd";
        version = "1.0";
        dontUnpack = true;
        src = builtins.toPath ../../Fonts/JetBrainsMonoNerdFont.ttf;
        installPhase = ''
          install -Dm644 $src $out/share/fonts/truetype/JetBrainsMonoNerdFont.ttf
        '';
      })

      pkgs.noto-fonts
      pkgs.noto-fonts-color-emoji
      pkgs.liberation_ttf
      pkgs.fira-code
      pkgs.fira-code-symbols
      pkgs.font-awesome
    ];
  };
}
