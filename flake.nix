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
      #----------------------------------------------------------------------------
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
      #formatter = pkgs.writeShellApplication {
      #  name = "nix-format";
      #  runtimeInputs = [ nixpkgs-fmt.packages.${system}.nixpkgs-fmt ];
      #  text = "nixpkgs-fmt $@";
      #};
      #----------------------------------------------------------------------------


      #----------------------------------------------------------------------------
      # Development Environment (shell)
      #----------------------------------------------------------------------------
      #
      # To enter the development environment:
      #   If using direnv (.envrc; use flake; direnv allow); just enter the project directory
      #   OR
      #   nix develop
      #
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

          echo ""
          echo "================================================"
          echo "    NixOS Custom ISO Development Environment    "
          echo "------------------------------------------------"

          echo -e "\033[1;34mAvailable commands:\033[0m"
          echo "  build-iso    - Build the customized ISO image"
          echo "  run-vm       - Start the ISO in QEMU VM"
          echo "  format       - Format Nix files"
          echo "  lint         - Check for Nix code issues"
          echo "  clean        - Remove build artifacts"

          echo -e "\n\033[1;34mQuick Start:\033[0m"
          echo "  1. First build:     nix build .#iso"
          echo "  2. Then run VM:     nix run .#vm"
          echo "  3. Format configs:  nix develop -c format"

          echo -e "\n\033[1;33mTIP:\033[0m These aliases work in the dev shell:"
          echo "  build-iso = nix build .#iso"
          echo "  run-vm    = nix run .#vm"
          echo "  format    = nixpkgs-fmt flake.nix && statix ."
          echo "  lint      = statix check . && deadnix ."
          echo "  clean     = rm -f result && echo 'Cleaned!'"

          alias build-iso='nix build .#iso'
          alias run-vm="nix run .#vm"
          alias format="nixpkgs-fmt flake.nix && statix ."
          alias lint="statix check . && deadnix ."
          alias clean="rm -f result && echo 'Cleaned!'"

          echo "================================================"
          echo ""
        '';
        #
        #shellHook = ''
        #  echo "=== Environment Help ==="
        #  cat ${./USAGE.md} 2>/dev/null || echo "Run 'nix run .#help' for usage"
        #  alias help="nix run .#help"
        #'';
      };
      #----------------------------------------------------------------------------


      #----------------------------------------------------------------------------
      # Configuration for the custom NixOS ISO
      #----------------------------------------------------------------------------
      nixosConfigurations.custom-iso = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          #"${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix"
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-gnome.nix"
          ({ pkgs, ... }: {
            # Custom packages
            environment.systemPackages = with pkgs; [
              tmux
              neovim
              htop
              bind # provides dig
              dig
              git

              #nixos-install-tools
              #gnome-terminal
              parted
              gparted
              polkit_gnome

              nixpkgs-fmt
              statix
              deadnix
            ];

            # Select internationalisation properties.
            i18n.defaultLocale = "en_US.UTF-8";
            console = {
              #font = "Lat2-Terminus16";
              keyMap = "dvorak"; #"us";
              #useXkbConfig = true; # use xkb.options in tty.
            };

            # Configure keymap in X11
            # services.xserver.xkb.layout = "us";
            # services.xserver.xkb.options = "eurosign:e,caps:escape";
            services.xserver.xkb.layout = "us,us";
            services.xserver.xkb.variant = "dvorak,";
            services.xserver.xkb.options = "grp:shift_caps_toggle";

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
      # Generate Custom NixOS ISO
      #----------------------------------------------------------------------------
      #
      #  To generate the custom NixOS ISO:
      #    nix build .#iso
      #
      packages.x86_64-linux.iso = self.nixosConfigurations.custom-iso.config.system.build.isoImage;
      #----------------------------------------------------------------------------


      #----------------------------------------------------------------------------
      # Generate and then View documentation
      #----------------------------------------------------------------------------
      #
      # To view documentation:
      #   nix build .#docs && cat result
      #   cat USAGE.txt
      #
      #packages.x86_64-linux.docs = pkgs.writeText "USAGE.txt" ''
      #  [Custom ISO Documentation]
      #    # NixOS Custom ISO Workflow
      #
      #    ## Commands
      #      `build-iso` - Build installation image
      #      `run-vm`    - Test in QEMU virtual machine
      #      `format`    - Format/lint configuration files
      #
      #    ## Typical Workflow
      #      1. Build ISO: `nix build .#iso`
      #      2. Start VM: `nix run .#vm`
      #      3. Edit files and repeat
      #'';
      #----------------------------------------------------------------------------


      #----------------------------------------------------------------------------
      # Configuration for QEMU VM
      #----------------------------------------------------------------------------
      #
      # Key QEMU controls:
      #   Ctrl+Alt+G: Release mouse/keyboard
      #   Ctrl+Alt+2: Switch to QEMU monitor
      #   Ctrl+Alt+1: Switch back to main view
      #   Power button: In the GNOME top bar to shutdown
      #
      packages.x86_64-linux.vm = let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
      in pkgs.writeShellScriptBin "run-vm" ''
        set -e
        ISO_PATH="${self.packages.x86_64-linux.iso}/iso/nixos-*.iso"
        ISO=$(ls $ISO_PATH 2>/dev/null || true)

        echo "Looking for $ISO ..."
        #if ! [ -f "$ISO" ]; then
        #  echo "ISO not found! Build it first with: nix build .#iso"
        #  exit 1
        #fi
        if [ -z "$ISO" ]; then
          echo "ERROR: No ISO found at path: $ISO_PATH"
          echo "First build the ISO with:"
          echo "  nix build .#iso"
          exit 1
        fi

        echo "Starting QEMU VM with:"
        echo "  ISO: $ISO"
        echo "Press Ctrl+Alt+G to release mouse/keyboard"
        echo "Use Ctrl+Alt+2 to enter QEMU monitor, then 'quit' to exit"

        ${pkgs.qemu}/bin/qemu-system-x86_64 \
          -machine accel=kvm,type=q35 \
          -cpu host \
          -smp 2 \
          -m 2048 \
          -cdrom "$ISO" \
          -boot d \
          -audiodev pa,id=snd0 \
          -device AC97,audiodev=snd0 \
          -nic user,model=virtio-net-pci \
          -usb \
          -device usb-tablet \
          -name "NixOS-Custom-ISO"
      '';
          #-display gtk,gl=on \
          #-device virtio-vga-gl \
      # To make RAM 4GB: '-m 4096'
      # To disable GUI: replace '-display gtk' with '-nographic'
      # To disable audio: delete '-audiodev' and '-device AC97' lines
      #----------------------------------------------------------------------------


      #----------------------------------------------------------------------------
      # App (shortcut) for running the VM
      #----------------------------------------------------------------------------
      #
      # To start the VM:
      #   nix run .#vm
      #   OR
      #   nix develop -c run-vm
      #
      apps.x86_64-linux.vm = {
        type = "app";
        program = "${self.packages.x86_64-linux.vm}/bin/run-vm";
      };
      #----------------------------------------------------------------------------


    }; # End outputs

}
