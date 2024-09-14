{
  description = "git.soma.salesforce.com/buildpacks/falcon-buildpack flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # poetry-nixpkgs.url = "github:NixOS/nixpkgs/aa463a0d1dcc495202049a16a59c8b70269bdcfe";
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
        # poetry-pkgs = poetry-nixpkgs.legacyPackages.${system};
        shells = nix-shells.shells.${system} { };
        mkShells = nix-shells.mergeShells.${system};
      in
      {
        devShells.default = mkShells [
          shells.base
          # shells.python310
          {
            buildInputs = [
              pkgs.python311
              pkgs.basedpyright
              pkgs.poetry
              pkgs.ruff
              # pkgs.python310Packages.ruff-lsp
              # pkgs.pylyzer
            ];
          }
        ];
      });
}
