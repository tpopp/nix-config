{
  description = "Tres Popp's system config";

  inputs = {
    nixpgs.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
    };

    awsvpnclient.url = "github:ymatsiuk/awsvpnclient";

  };

  outputs = { self, nixpkgs, home-manager, impermanence, awsvpnclient, ... }@inputs:
    let
    inherit (nixpkgs) lib;


  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
    config.permittedInsecurePackages = [ nixpkgs.google-chrome ];
    overlays = [ awsvpnclient.overlay ];
  };

  system = "x86_64-linux";
  in {

    homeConfigurations = {

      tpopp = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
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
