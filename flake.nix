{
  description = "Custom NixOS ISO";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    #nixpkgs-fmt.url = "github:nix-community/nixpkgs-fmt";
  };

  outputs =
    { self
    , nixpkgs
    , #nixpkgs-fmt,
      ...
    }: {


      #----------------------------------------------------------------------------
      # Formatter
      #
      # To format all Nix files
      #   nix fmt
      #
      # To check for Nix anti-patterns
      #   statix
      #
      # To find unused variables
      #   deadnix
      #
      #----------------------------------------------------------------------------
      #formatter = pkgs.writeShellApplication {
      #  name = "nix-format";
      #  runtimeInputs = [ nixpkgs-fmt.packages.${system}.nixpkgs-fmt ];
      #  text = "nixpkgs-fmt $@";
      #};
      #----------------------------------------------------------------------------


      #----------------------------------------------------------------------------
      # nix develop
      #----------------------------------------------------------------------------
      devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
        packages = with nixpkgs.legacyPackages.x86_64-linux; [
          # Formatter and linter
          nixpkgs-fmt
          statix
          deadnix

          # Helpful tools
          git
          jq
          vim
          neovim
          htop
          tmux
          dig

          # For testing ISO builds
          #self.packages.${system}.iso
        ];

        shellHook = ''
          export PS1="[L$SHLVL] $PS1"
          echo "Custom ISO dev shell"
          echo "Available packages: git, nixpkgs-fmt, jq, vim"
          echo "Build ISO with: nix build .#iso"
          echo "Available commands:"
          echo "  nixpkgs-fmt flake.nix    - Format Nix files"
          echo "  statix .                 - Lint Nix files"
          echo "  deadnix .                - Find unused variables"
        '';
      };
      #----------------------------------------------------------------------------


      #----------------------------------------------------------------------------
      #
      #----------------------------------------------------------------------------
      nixosConfigurations.custom-iso = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix"
          ({ pkgs, ... }: {
            # Custom packages
            environment.systemPackages = with pkgs; [
              tmux
              neovim
              htop
              bind # provides dig
              dig
              git

              nixpkgs-fmt
              statix
              deadnix
            ];

            # User configuration
            users.users.najib = {
              isNormalUser = true;
              uid = 1001;
              group = "najib";
              extraGroups = [ "users" "wheel" ]; # wheel for sudo access
              createHome = true;
              home = "/home/najib";
            };

            users.groups.najib = {
              gid = 1001;
            };

            # Git configuration
            programs.git = {
              enable = true;
              config = {
                alias = {
                  hist = "log --pretty=format:'%h %ad | %s%d [%an]' --graph --date=short";
                  hist2 = "log --pretty=format:'%h %s' --graph";
                };
              };
            };

            # Optional: Auto-login as najib (common for live environments)
            #services.xserver.displayManager.autoLogin = {
            #  enable = true;
            #  user = "najib";
            #};

          })
        ];
      }; # End nixosConfigurations
      #----------------------------------------------------------------------------


      #----------------------------------------------------------------------------
      # nix build .#iso
      #----------------------------------------------------------------------------
      packages.x86_64-linux.iso = self.nixosConfigurations.custom-iso.config.system.build.isoImage;
      #----------------------------------------------------------------------------


    }; # End outputs

}
