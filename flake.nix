{
  description = "NixOS ISO with custom packages, user, and Git config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs }: {
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
            git
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
    };

    packages.x86_64-linux.iso = self.nixosConfigurations.custom-iso.config.system.build.isoImage;
  };
}
