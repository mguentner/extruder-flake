# extruder-flake

NixOS aarch64 flake for Raspberry Pi 4 to control a [Kingroon KP3S](https://kingroon.com/products/official-kingroon-kp3s-3d-printer) printer running [Klipper](https://www.klipper3d.org/).
Builds an SD-card image and allows `nixos-rebuild switch` on the device all with the same `configuration.nix`!

- USB Webcam Support via ustreamer
- Automatic connection to Wifi
- provisioned ssh keys

## Building the sd image

```
$ nix build '.#nixosConfigurations.sdcard.config.system.build.sdImage'
```

## Flashing the image

```
$ zstdcat result/sd-image/nixos-sd-image-23.05.20230421.2362848-aarch64-linux.img.zst  | sudo dd of=/dev/sdc bs=8M oflag=direct status=progress iflag=fullblock

```

## Rebuilding on the device

```
$ nixos-rebuild switch --flake '.#'
```

## TODO

- [ ] move `klipper_config` (back) to own repository / submodule to track [upstream](https://github.com/9R/Klipper_KP3S) [changes](https://github.com/nehilo/Klipper-KingRoon-Printers).
