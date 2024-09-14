{
  description = "Generic flake for golang";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-shells = {
      url = "../../";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, nix-shells }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        shells = nix-shells.shells.${system} { };
        mkShells = nix-shells.mergeShells.${system};
      in
      {
        devShells.default = mkShells [
          {
            buildInputs = with pkgs; [
              go_1_21
            ];
          }
          shells.base
          shells.golang
        ];
      });
}
