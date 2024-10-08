# Built from this example: https://github.com/nix-community/infra/blob/master/hosts/build01/default.nix
{ inputs, lib, ... }:
{
  imports = [
    ./disko-zfs.nix
  ];

  # For some reason nix-channel is missing from the server
  # https://discourse.nixos.org/t/nix-channel-not-found-in-nixos-server/52322/2?u=onnimonni
  nix.channel.enable = lib.mkForce true;

  users.users.root.openssh.authorizedKeys.keys = [
    # FIXME: Set your own public key here!
    "ecdsa-sha2-nistp256 AAAAyourpublickeygoeshere"
  ];

  # FIXME: Set your hetzner ipv6 address here
  systemd.network.networks."10-uplink".networkConfig.Address = "XXXX:YYY:ZZZ:WWWW::2/64";

  system.stateVersion = "23.11";
}