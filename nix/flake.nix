{
  description = "Multi-machine NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    jovian.url = "github:sebastianusk/Jovian-NixOS";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, jovian, home-manager, ... }: {
    nixosConfigurations.steamdeck = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/steamdeck
        jovian.nixosModules.jovian
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.deck = import ./users/deck;
          };
        }
      ];
    };
  };
}
