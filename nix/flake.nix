{
  description = "Multi-machine NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    jovian.url = "github:Jovian-Experiments/Jovian-NixOS";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, jovian, home-manager, ... }:
    let
      # Helper function to create a host configuration
      mkHost = hostname: system: user: extraModules: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit self nixpkgs jovian home-manager; };
        modules = [
          ./hosts/${hostname}
          home-manager.nixosModules.home-manager
          {
            networking.hostName = hostname;
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              users.${user} = import ./users/${user};
            };
          }
        ] ++ extraModules;
      };
    in
    {
      # Define your hosts here
      nixosConfigurations = {
        # Steam Deck configuration
        steamdeck = mkHost "steamdeck" "x86_64-linux" "deck" [
          jovian.nixosModules.jovian
        ];

        # Add more hosts as needed:
        # laptop = mkHost "laptop" "x86_64-linux" "youruser" [];
        # desktop = mkHost "desktop" "x86_64-linux" "youruser" [];
      };
    };
}
