{
  description = "NixOS configuration with Caelestia and Quickshell";

  inputs = {
    # Use unstable since you're on 25.11 ISO
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager";  # master branch for unstable
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Quickshell flake - works on unstable (has wayland-protocols >= 1.41)
    quickshell = {
      url = "github:quickshell-mirror/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, quickshell, ... }@inputs:
    let
      system = "x86_64-linux";
      hostname = "caelestia";
      username = "mei";
      
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs hostname username; };
        modules = [
          ./configuration.nix
          
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${username} = import ./home.nix;
            home-manager.extraSpecialArgs = { inherit inputs hostname username; };
          }
        ];
      };
      
      # Dev shell for working on configs
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          nil
          nixpkgs-fmt
        ];
      };
    };
}
