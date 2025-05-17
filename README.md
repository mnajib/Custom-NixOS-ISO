# Custom-NixOS-ISO

  Configure Custom NixOS ISO, Generate the ISO, and then Test run the ISO in QEMU

# Usage

  - To build ISO:         nix build .#iso"
  - To create Disks:      nix run .#create-drives"
  - To start VM (ISO):    nix run .#vm-iso"
  - To start VM (Disk):   nix run .#vm-disk"
  - To clean ISO:         nix run .#clean-iso"
  - To clean Disks:       nix run .#clean-disks"

# TODO

   - use nix-utils
