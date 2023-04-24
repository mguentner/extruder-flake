{ config, lib, pkgs, modules, ... }:
let
  src = lib.cleanSource ./.;
in
{
  boot.postBootCommands = ''
    cp -na ${src}/* /etc/nixos/.
  '';
}
