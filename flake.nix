{
  description = "macOS provisioning with Nix — multi-host, GitHub-hosted";

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Official OpenClaw Nix flake — tracks releases directly, no nixpkgs lag
    nix-openclaw = {
      url = "github:openclaw/nix-openclaw";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    darwin,
    home-manager,
    sops-nix,
    nix-openclaw,
    ...
  } @ inputs: let
    supportedSystems = ["x86_64-darwin" "aarch64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    mkPkgs = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          (import ./overlays/default.nix)
        ];
      };

    # =========================================================================
    # Host registry — add new machines here
    # =========================================================================
    hosts = {
      # Personal laptops (admin = day-to-day user)
      airmac = {
        system = "aarch64-darwin";
        username = "user";
        profile = "personal";
      };
      airmac2 = {
        system = "aarch64-darwin";
        username = "user";
        profile = "personal";
      };

      # Intel laptop
      rock = {
        system = "x86_64-darwin";
        username = "user";
        profile = "personal";
      };

      # Work machine (M4 Apple Silicon, admin = day-to-day user)
      work = {
        system = "aarch64-darwin";
        username = "user";
        profile = "work";
      };

      # OpenClaw provisioning laptop (Apple Silicon)
      # Admin "user" runs darwin-rebuild; day-to-day user is "openclaw" (non-admin)
      openclaw = {
        system = "aarch64-darwin";
        adminUsername = "user";
        username = "openclaw";
        profile = "openclaw";
      };
    };

    # =========================================================================
    # Builder — creates a darwin system for any registered host
    # =========================================================================
    mkDarwinSystem = {
      hostname,
      system,
      username ? "user",
      adminUsername ? username,
      profile ? "personal",
    }: let
      pkgs = mkPkgs system;
      isMultiUser = adminUsername != username;
    in
      darwin.lib.darwinSystem {
        inherit system;
        specialArgs = {inherit inputs hostname system username adminUsername isMultiUser nix-openclaw;};
        modules = [
          # Overlays and nixpkgs config
          {
            nixpkgs.overlays = [(import ./overlays/default.nix)];
          }

          # Profile system — sets capability flags based on machine role
          ./modules/profiles/default.nix
          {local.profile.name = profile;}

          # Common darwin configuration
          ./modules/darwin/default.nix

          # sops-nix for secrets management
          sops-nix.darwinModules.sops

          # Home-manager — provisions the day-to-day user's home
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {inherit inputs pkgs hostname system username adminUsername isMultiUser;};
              users.${username} = import ./modules/users/user.nix;
              backupFileExtension = "backup";
              sharedModules = [
                sops-nix.homeManagerModules.sops
              ];
            };
          }

          # Host-specific configuration
          (./hosts + "/${hostname}.nix")

          # Ensure day-to-day user home directory is set
          {users.users.${username}.home = "/Users/${username}";}
        ];
      };
  in {
    darwinConfigurations =
      nixpkgs.lib.mapAttrs
      (hostname: hostConfig:
        mkDarwinSystem {
          inherit hostname;
          inherit (hostConfig) system;
          username = hostConfig.username;
          adminUsername = hostConfig.adminUsername or hostConfig.username;
          profile = hostConfig.profile or "personal";
        })
      hosts;

    # Development shell
    devShells = forAllSystems (system: let
      pkgs = mkPkgs system;
    in {
      default = pkgs.mkShell {
        name = "mac-config-dev";
        buildInputs = with pkgs; [
          nil
          nixpkgs-fmt
          alejandra
          deadnix
          statix
          sops
          age
          ssh-to-age
          git
          gh
          just
        ];

        shellHook = ''
          echo "mac-config development shell"
          echo ""
          echo "  nix flake check     - Run all checks"
          echo "  alejandra .         - Format all Nix files"
          echo "  deadnix -f          - Find and fix dead code"
          echo "  statix check        - Lint Nix files"
        '';
      };
    });

    formatter = forAllSystems (system: let
      pkgs = mkPkgs system;
    in
      pkgs.alejandra);

    checks = forAllSystems (system: let
      pkgs = mkPkgs system;
    in {
      formatting =
        pkgs.runCommand "check-formatting" {
          buildInputs = [pkgs.alejandra];
        } ''
          alejandra --check ${./.}
          touch $out
        '';

      deadnix-check =
        pkgs.runCommand "check-deadnix" {
          buildInputs = [pkgs.deadnix];
        } ''
          deadnix --fail ${./.}
          touch $out
        '';
    });
  };
}
