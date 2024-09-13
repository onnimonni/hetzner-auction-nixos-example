# Built from this example: https://github.com/nix-community/infra/blob/master/hosts/build01/default.nix
{ inputs, ... }:
{
  imports = [
    ./disko-zfs.nix
  ];

  users.users.root.openssh.authorizedKeys.keys = [
    # FIXME: Set your own public key here!
    "ecdsa-sha2-nistp256 AAAAyourpublickeygoeshere"
  ];

  # FIXME: Set your hetzner ipv6 address here
  systemd.network.networks."10-uplink".networkConfig.Address = "XXXX:YYY:ZZZ:WWWW::2/64";

  system.stateVersion = "23.11";
}