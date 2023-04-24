{ config, modulesPath, pkgs, lib, ... }:
{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64-new-kernel-no-zfs-installer.nix"
  ];

  sdImage = {
    # usage is around 70 MiB
    firmwareSize = 150;
  };
}
