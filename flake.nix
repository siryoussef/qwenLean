{
  description = "Qwen Studio - Open-source Qwen AI desktop client";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    devenv.url = "github:cachix/devenv";
  };

  outputs = { self, nixpkgs, flake-utils, devenv, ... } @ inputs:
    let
      overlays = [
        (final: prev: {
          qwen-studio = final.callPackage ./nix/package.nix { };
        })
      ];
    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          inherit overlays;
        };
      in
      {
        packages.default = pkgs.qwen-studio;

        devShells.default = devenv.lib.mkShell {
          inherit inputs pkgs;
          modules = [
            ./devenv.nix
          ];
        };
      }) // {
      # Global outputs (system-independent)
      overlays.default = nixpkgs.lib.composeManyExtensions overlays;

      nixosModules.default = import ./nix/nixos.nix;
      homeManagerModules.default = import ./nix/home-manager.nix;
    };
}
