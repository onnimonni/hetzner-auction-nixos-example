# Copied directly from https://github.com/nix-community/infra/blob/db5fdfe6821fbf6132c2652b9dc3d6507dbfc8dd/modules/nixos/disko-zfs.nix#L4

##
# TL;DR: All 3 blocks imports = ..., options = ... and config = must be defined in files with optional parameters
##
# Nix Flakes can be pretty complicated. Passing parameters like list of disks to this module is not trivial
# Best practice seems to be to add separate imports = ..., options = ... and config = ...
# Normally files only contain config directly but when they have "options" all of the other directives need
# to be wrapped in config = { } block
# This post tries to explain it as well: https://discourse.nixos.org/t/whats-wrong-etc-nixos-configuration-nix-has-an-unsupported-attribute-boot/22899/3
# See good example here: https://github.com/kuutamolabs/kld/blob/752b6eb31ee2d12c463063dd0d1825d40d6d99d5/nix/modules/hardware.nix
# Using options block seems to be the best way to pass parameters to modules according to Nix forums:
# https://discourse.nixos.org/t/passing-parameters-into-import/34082/4?u=onnimonni


# Only small modifications were needed, TODO: check if this could be srvos module too
{ lib, config, disko, ... }:
{
  options.myHost.disko.disks = lib.mkOption {
    type = lib.types.listOf lib.types.path;
    default = [ "/dev/nvme0n1" "/dev/nvme1n1" ];
    description = lib.mdDoc "Disks formatted by disko";
  };

  config = {
    # this is both efi and bios compatible
    boot.loader.grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      # FIXME: This doesn't seem to work if I boot to rescue mode and format the disk with /boot partition and reboot
      # Use all created EFI partitions as backup boots
      mirroredBoots = (map (device: {
        path = if (builtins.elemAt config.myHost.disko.disks 0) == device
                  then "/boot" # First disk is /boot and others use the fallback
                  else "/boot-fallback" + lib.replaceStrings [ "/" ] [ "-" ] device;
        devices = [ "nodev" ];
      }) config.myHost.disko.disks);
    };

    # the default zpool import services somehow times out while this import works fine?
    boot.initrd.systemd.services.zfs-import-zroot.serviceConfig.ExecStartPre = "${config.boot.zfs.package}/bin/zpool import -N -f zroot";

    # Sometimes fails after the first try, with duplicate pool name errors
    boot.initrd.systemd.services.zfs-import-zroot.serviceConfig.Restart = "on-failure";

    disko.devices = {
      disk = lib.genAttrs config.myHost.disko.disks (device: {
        name = lib.replaceStrings [ "/" ] [ "_" ] device;
        device = device;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02"; # for grub MBR
            };
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                # Mount first device into /boot and others to /boot-fallback-dev-sdb ...
                mountpoint =
                  if (builtins.elemAt config.myHost.disko.disks 0) == device
                  then "/boot"
                  else "/boot-fallback" + lib.replaceStrings [ "/" ] [ "-" ] device;
                mountOptions = [ "nofail" ];
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };
          };
        };
      });
      zpool = {
        zroot = {
          type = "zpool";
          mode = "mirror";
          options = {
            # Check the sector size of the physical drive and match this with the alignment shift
            # For example a HDD mounted in /dev/sda:
            # $ fdisk -l /dev/sda
            # Disk /dev/sda: 9.1 TiB, 10000831348736 bytes, 19532873728 sectors
            # Disk model: ST10000NM0156-2A
            # Units: sectors of 1 * 512 = 512 bytes
            # Sector size (logical/physical): 512 bytes / 4096 bytes
            # I/O size (minimum/optimal): 4096 bytes / 4096 bytes
            # Then check the value from the following table:
            # ashift | Sector size
            # 9	     | 512 bytes
            # 10	   | 1 KB
            # 11	   | 2 KB
            # 12	   | 4 KB
            # 13	   | 8 KB
            # 14	   | 16 KB
            ashift = "12";
          };
          rootFsOptions = {
            acltype = "posixacl";
            atime = "off"; # Don't store access time because it causes way too many writes
            compression = "zstd"; # For small text files zstd seems to be 25% slower than lz4 but requires 31% less disk space
            mountpoint = "none";
            xattr = "sa";
            "com.sun:auto-snapshot" = "false";
          };
          datasets = {
            root = {
              type = "zfs_fs";
              mountpoint = "/";
              options.mountpoint = "legacy";
            };
          };
        };
      };
    };
  };
}
