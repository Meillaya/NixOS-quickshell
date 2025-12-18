{
  description = "NixOS configuration with Caelestia and Quickshell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # NOTE: We use pkgs.quickshell from nixpkgs instead of the flake.
    # The flake requires wayland-protocols >= 1.41, but nixos-24.11 only has 1.38.
    # If you want the absolute latest quickshell after install, you can add the flake
    # input back and use nixpkgs-unstable for its follows, or build from source.
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      hostname = "caelestia";
      username = "mei";
      
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs pkgs-unstable hostname username; };
        modules = [
          ./configuration.nix
          
          # Home Manager as a NixOS module
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${username} = import ./home.nix;
            home-manager.extraSpecialArgs = { inherit pkgs-unstable hostname username; };
          }
        ];
      };
      
      # Also provide a dev shell for working on configs
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          nil  # Nix LSP
          nixpkgs-fmt
        ];
      };
    };
}

