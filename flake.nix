{
  description = "Tres Popp's system config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
    };

  };

  outputs = { self, nixpkgs, home-manager, impermanence, ... }@inputs:
    let
      system = "x86_64-linux";
  in {

    homeConfigurations = {

      tpopp = home-manager.lib.homeManagerConfiguration {
        modules = [
          impermanence.nixosModules.home-manager.impermanence
          ./home.nix
        ];
      };

    };

    # Put home.nix here because impermanence requires that part be there
    nixosConfigurations = {
      deskmini-x300 = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          impermanence.nixosModule
          ./machine/deskmini-x300.nix
          ./configuration.nix
          # impermanence.nixosModules.home-manager.impermanence
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.sharedModules = [ impermanence.nixosModules.home-manager.impermanence ];
            home-manager.users.tpopp.imports = [ ./home.nix ];
          }
        ];

      };
    };
    # packages.${system}.tpopp = self.homeConfigurations.tpopp.activationPackage;

  };

}
