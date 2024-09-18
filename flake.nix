{
  description = "My machines flakes";
  inputs = {
    # Reusable packages for nixos configs
    # Use the version of nixpkgs that has been tested to work with SrvOS
    srvos.url = "github:nix-community/srvos";
    nixpkgs.follows = "srvos/nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, srvos, disko }: {
    nixosConfigurations.myHost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # This machine is a server
        srvos.nixosModules.server
        # Deployed on the AMD Hetzner bare metal hardware
        srvos.nixosModules.hardware-hetzner-online-amd
        # Setup disks with disko
        disko.nixosModules.disko
        # Finally add your configuration here
        ./myHost.nix
        # Setup programs
        ./programs.nix
      ];
    };
  };
}