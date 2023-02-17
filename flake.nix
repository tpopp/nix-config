{
  description = "Tres Popp's system config";

  inputs = {
    nixpgs.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }@inputs:
    let
    inherit (nixpkgs) lib;


  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
    config.permittedInsecurePackages = [ nixpkgs.google-chrome ];
    overlays = [];
  };

  system = "x86_64-linux";
  in {

    homeConfigurations = {

      tpopp = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home.nix
        ];
      };

    };

    nixosConfigurations = {
      deskmini-x300 = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./machine/deskmini-x300.nix
          ./configuration.nix
        ];

      };
    };

  };

}
