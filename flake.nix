{
  description = "NixOS Config for fluidd + klipper for Kingroon KP3";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";
  };

  outputs = { self, nixpkgs, ... }@inputs: with inputs; {
    nixosConfigurations.sdcard = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        ./sd_image.nix
        ./clone_flake.nix
        nixos-hardware.nixosModules.raspberry-pi-4
        ./configuration.nix
      ];
    };

    nixosConfigurations.extruder = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        nixos-hardware.nixosModules.raspberry-pi-4
        ./configuration.nix
      ];
    };
  };
}
