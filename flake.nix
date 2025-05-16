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

          # Other tools
          git
          jq
          gnugrep
          vim
          neovim
          htop
          tmux
          dig
          wget
          parted
          coreutils
          dosfstools # for mkfs.fat
          zfs # for zpool/zfs
          strace
          lsof
          sysstat

          # For testing ISO builds
          #self.packages.${system}.iso

          # Virtualization tools
          qemu #qemu_kvm
          virt-manager #
          libvirt # Virtualization API toolkit
          edk2 #
          OVMF # UEFI firmware for VMs

          # KVM utilities
          virtiofsd # For fast filesystem sharing
          swtpm # TPM emulation
        ];

        shellHook = ''
          export PS1="[L$SHLVL] $PS1"

          echo ""
          echo "================================================"
          echo "    NixOS Custom ISO Development Environment    "
          echo "      by NajibMalaysia <mnajib@gmail.com>"
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

          # Define check-kvm function
          check-kvm() {
            echo -e "\n\033[1;36mKVM Status Check:\033[0m"
            if [ -c /dev/kvm ]; then
              echo "✓ KVM device found at /dev/kvm"
              ${nixpkgs.legacyPackages.x86_64-linux.gnugrep}/bin/grep -E '(vmx|svm)' /proc/cpuinfo | \
                ${nixpkgs.legacyPackages.x86_64-linux.coreutils}/bin/head -n 1 | \
                ${nixpkgs.legacyPackages.x86_64-linux.coreutils}/bin/sed 's/^/✓ CPU virtualization flags: /'
            else
              echo -e "\033[1;31m✗ KVM device not found!\033[0m"
              echo "  Ensure:"
              echo "  1. Virtualization enabled in BIOS"
              echo "  2. Kernel modules loaded (kvm_intel/kvm_amd)"
              echo "  3. User in kvm group (run: sudo usermod -aG kvm $USER)"
            fi
          }

          # Define test-vm function
          test-vm() {
            echo -e "\n\033[1;36mStarting Test VM:\033[0m"
            ${nixpkgs.legacyPackages.x86_64-linux.qemu}/bin/qemu-system-x86_64 \
              -machine accel=kvm \
              -cpu host \
              -m 512 \
              -nographic \
              -nodefaults \
              -serial mon:stdio \
              -device virtio-net,netdev=user0 \
              -netdev user,id=user0
          }

          alias build-iso='nix build .#iso'
          alias run-vm="nix run .#vm"
          alias vm-start="nix run .#vm"
          alias vm-stop="pkill qemu-system-x86"
          alias vm-info="virsh list --all"
          alias format="nixpkgs-fmt flake.nix && statix ."
          alias lint="statix check . && deadnix ."
          alias clean="rm -f result && echo 'Cleaned!'"
          alias check-kvm="check-kvm"
          alias test-vm="test-vm"
          alias full-workflow="nix build .#iso && check-kvm && nix run .#vm"

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

          ({ config, pkgs, lib, ... }: {

            imports = [
              #./users.nix
            ];

            # ISO image configuration
            isoImage = {
              #isoName = lib.mkDefault "najib-nixos-gnome-installer.iso";
              #isoName = lib.mkForce "nixos-najib-gnome-installer.iso";
              makeEfiBootable = true;
              makeUsbBootable = true;
            };

            networking.hostName = "najib-nixos";

            # Embed flake in ISO
            environment.etc."nixos-flake".source = self.outPath;

            # Custom packages
            environment.systemPackages = with pkgs; [
              tmux
              neovim
              htop
              bind # provides dig
              dig
              git

              #nixos-install-tools
              gnome-terminal
              parted
              gparted
              polkit_gnome

              nixpkgs-fmt
              statix
              deadnix

              self.packages.x86_64-linux.zfs-installer

              strace
              lsof
              sysstat
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

            systemd.services."autovt@tty1".enable = false; # Show proper login prompt

            # Auto-run script on first boot
            #systemd.services.autoinstall = {
            #  wantedBy = [ "multi-user.target" ];
            #  script = ''
            #    if [ ! -f /etc/install-done ]; then
            #      /run/current-system/sw/bin/install-zfs-nixos
            #      touch /etc/install-done
            #      reboot
            #    fi
            #  '';
            #  serviceConfig.Type = "oneshot";
            #};

            services.udisks2.enable = true;
            services.gvfs.enable = true;
            services.accounts-daemon.enable = true;

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
        name = "nixos-test-vm";
      in pkgs.writeShellScriptBin "run-vm" ''
        set -e
        set -euxo pipefail

        TMPDIR=$(mktemp -d)
        trap "rm -rf $TMPDIR" EXIT

        DISK1="$TMPDIR/disk1.qcow2"
        DISK2="$TMPDIR/disk2.qcow2"

        # Location for the generated ISO
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

        echo "Creating virtual disks..."
        ${pkgs.qemu}/bin/qemu-img create -f qcow2 "$DISK1" 11G
        ${pkgs.qemu}/bin/qemu-img create -f qcow2 "$DISK2" 11G

        echo "Starting QEMU VM with:"
        echo "  ISO: $ISO"
        echo "Press Ctrl+Alt+G to release mouse/keyboard"
        echo "Use Ctrl+Alt+2 to enter QEMU monitor, then 'quit' to exit"

        ${pkgs.qemu}/bin/qemu-system-x86_64 \
          -machine accel=kvm,type=q35 \
          -cpu host \
          -smp 2 \
          -m 2048 \
          -drive file=$TMPDIR/disk1.qcow2,if=virtio,format=qcow2 \
          -drive file=$TMPDIR/disk2.qcow2,if=virtio,format=qcow2 \
          -cdrom "$ISO" \
          -boot d \
          -nic user,model=virtio-net-pci \
          -usb \
          -device usb-tablet \
          -name "NixOS-Custom-ISO"
      '';
        #${pkgs.qemu}/bin/qemu-system-x86_64 \
        #${pkgs.qemu_kvm}/bin/qemu-system-x86_64 \
          #-bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
          #-drive file=$TMPDIR/nixos.iso,media=cdrom \
          #-drive file=$TMPDIR/disk1.qcow2,if=virtio,format=qcow2 \
          #-drive file=$TMPDIR/disk2.qcow2,if=virtio,format=qcow2 \
          #-netdev user,id=net0,hostfwd=tcp::2222-:22 \
          #-device virtio-net,netdev=net0 \
          #-enable-kvm \
          #-display gtk,gl=on \
          #-device virtio-vga-gl \
          #-audiodev pa,id=snd0 \
          #-device AC97,audiodev=snd0 \
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


      #----------------------------------------------------------------------------
      # Configuration to just run the installed NixOS
      #----------------------------------------------------------------------------
      #
      # Key QEMU controls:
      #   Ctrl+Alt+G: Release mouse/keyboard
      #   Ctrl+Alt+2: Switch to QEMU monitor
      #   Ctrl+Alt+1: Switch back to main view
      #   Power button: In the GNOME top bar to shutdown
      #
      packages.x86_64-linux.vm2 = let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        name = "nixos-test-vm";
      in pkgs.writeShellScriptBin "run-with-installed-vm" ''
        set -euxo pipefail
        TMPDIR=$(mktemp -d)
        trap "rm -rf $TMPDIR" EXIT

        DISK1="$TMPDIR/disk1.qcow2"
        DISK2="$TMPDIR/disk2.qcow2"

        # Location for the generated ISO
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

        #echo "Creating virtual disks..."
        #${pkgs.qemu}/bin/qemu-img create -f qcow2 "$DISK1" 11G
        #${pkgs.qemu}/bin/qemu-img create -f qcow2 "$DISK2" 11G

        echo "Starting QEMU VM with:"
        echo "  ISO: $ISO"
        echo "Press Ctrl+Alt+G to release mouse/keyboard"
        echo "Use Ctrl+Alt+2 to enter QEMU monitor, then 'quit' to exit"

        ${pkgs.qemu}/bin/qemu-system-x86_64 \
          -machine accel=kvm,type=q35 \
          -cpu host \
          -smp 2 \
          -m 2048 \
          -drive file=$TMPDIR/disk1.qcow2,if=virtio,format=qcow2 \
          -drive file=$TMPDIR/disk2.qcow2,if=virtio,format=qcow2 \
          -cdrom "$ISO" \
          -boot d \
          -nic user,model=virtio-net-pci \
          -usb \
          -device usb-tablet \
          -name "NixOS-Custom-ISO"
      '';
        #${pkgs.qemu}/bin/qemu-system-x86_64 \
        #${pkgs.qemu_kvm}/bin/qemu-system-x86_64 \
          #-bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
          #-drive file=$TMPDIR/nixos.iso,media=cdrom \
          #-drive file=$TMPDIR/disk1.qcow2,if=virtio,format=qcow2 \
          #-drive file=$TMPDIR/disk2.qcow2,if=virtio,format=qcow2 \
          #-netdev user,id=net0,hostfwd=tcp::2222-:22 \
          #-device virtio-net,netdev=net0 \
          #-enable-kvm \
          #-display gtk,gl=on \
          #-device virtio-vga-gl \
          #-audiodev pa,id=snd0 \
          #-device AC97,audiodev=snd0 \
      # To make RAM 4GB: '-m 4096'
      # To disable GUI: replace '-display gtk' with '-nographic'
      # To disable audio: delete '-audiodev' and '-device AC97' lines
      #----------------------------------------------------------------------------


      #----------------------------------------------------------------------------
      # App (shortcut) for running the vm2 with (suppose) installed NixOS
      #----------------------------------------------------------------------------
      #
      # To start the VM:
      #   nix run .#vm2
      #   OR
      #   nix develop -c run-installed-vm
      #
      apps.x86_64-linux.vm2 = {
        type = "app";
        program = "${self.packages.x86_64-linux.vm2}/bin/run-installed-vm";
      };
      #----------------------------------------------------------------------------


      #----------------------------------------------------------------------------
      # NixOs config for guest OS (to be installed on the VM drives)
      #----------------------------------------------------------------------------
      #
      # Boot from ISO using QEMU as VM, then run install script that come from the ISO. The install
      # script will use this config to install it into drives)
      #
      # Flake-based NixOS configuration to install with ZFS
      guestConfig = { config, pkgs, ... }: {
        imports = [ ];

        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
        boot.supportedFilesystems = [ "zfs" ];

        networking.hostName = "syuhada";
        networking.hostId = builtins.substring 0 8 (
          builtins.hashString "sha256" config.networking.hostName
        );

        fileSystems."/" = {
          device = "zroot/root";
          fsType = "zfs";
        };

        services.sshd.enable = true;
        users.users.nixos = {
          isNormalUser = true;
          password = "nixos";
          extraGroups = [ "wheel" ];
        };
        #services.getty.autoLogin.enable = true;
        #services.getty.autoLogin.user = "nixos";
        system.stateVersion = "24.05";
      };
      #----------------------------------------------------------------------------
      #
      # To call this, use command ...
      #
      nixosConfigurations.syuhada-vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ self.guestConfig ];
      };
      #----------------------------------------------------------------------------


      #----------------------------------------------------------------------------
      # NixOS installer script
      #----------------------------------------------------------------------------
      packages.x86_64-linux.zfs-installer = let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
      in
        pkgs.writeShellScriptBin "install-zfs-nixos" ''
          set -euxo pipefail
          ${pkgs.parted}/bin/parted /dev/vda -- mklabel gpt
          ${pkgs.parted}/bin/parted /dev/vda -- mkpart ESP fat32 1MiB 512MiB
          ${pkgs.parted}/bin/parted /dev/vda -- set 1 esp on
          ${pkgs.parted}/bin/parted /dev/vda -- mkpart primary 512MiB 100%
          # swap partition ... ?

          ${pkgs.parted}/bin/parted /dev/vdb -- mklabel gpt
          ${pkgs.parted}/bin/parted /dev/vdb -- mkpart ESP fat32 1MiB 512MiB
          ${pkgs.parted}/bin/parted /dev/vdb -- set 1 esp on
          ${pkgs.parted}/bin/parted /dev/vdb -- mkpart primary 512MiB 100%
          # swap partition ... ?

          # make swap filesystem ...
          # make swap filesystem ...

          ${pkgs.dosfstools}/bin/mkfs.fat -F32 /dev/vda1
          ${pkgs.dosfstools}/bin/mkfs.fat -F32 /dev/vdb1

          ${pkgs.kmod}/bin/modprobe zfs || true
          ${pkgs.zfs}/bin/zpool create -f -o ashift=12 \
            -O mountpoint=none \
            -O compression=lz4 \
            -O atime=off \
            zroot mirror /dev/vda2 /dev/vdb2

          ${pkgs.zfs}/bin/zfs create -o mountpoint=legacy zroot/root
          mount -t zfs zroot/root /mnt
          mkdir -p /mnt/boot
          mount /dev/vda1 /mnt/boot
          #swapon ...

          nixos-generate-config --root /mnt
          nixos-install --flake ${self}#syuhada-vm --no-root-passwd
        '';
      #----------------------------------------------------------------------------


      #----------------------------------------------------------------------------
      # App (shortcut) for the NixOS installer script
      #----------------------------------------------------------------------------
      #
      # Become root
      #   sudo -i
      #
      # Run the ZFS installer
      #   nix run github:your-username/your-repo#zfs-install
      #
      # Or if using the local flake:
      #   /nix/var/nix/profiles/system/activate/install-zfs-nixos
      #
      apps.x86_64-linux.zfs-install = {
        type = "app";
        program = "${self.packages.x86_64-linux.zfs-installer}/bin/install-zfs-nixos";
      };
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


      # nix run
      #apps.default = {
      #  type = "app";
      #  program = "${runVM}/bin/run-zfs-vm";
      #};


    }; # End outputs

}
