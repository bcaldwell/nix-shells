{
  description = "Flake that contains common package sets for various languages";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        defaultpkgs = nixpkgs.legacyPackages.${system};
        rest = a: builtins.removeAttrs a [
          "buildInputs"
          "nativeBuildInputs"
          "propagatedBuildInputs"
          "propagatedNativeBuildInputs"
          "shellHook"
        ];
        lib = defaultpkgs.lib;
        mergeAttr = a: b: attr: (lib.attrByPath [ attr ] [ ] a) ++ (lib.attrByPath [ attr ] [ ] b);
      in
      rec {
        mergeShells = envs: defaultpkgs.mkShell (builtins.foldl'
          (a: v: ({
            buildInputs = mergeAttr a v "buildInputs";
            nativeBuildInputs = mergeAttr a v "nativeBuildInputs";
            propagatedBuildInputs = mergeAttr a v "propagatedBuildInputs";
            propagatedNativeBuildInputs = mergeAttr a v "propagatedNativeBuildInputs";
            shellHook = (lib.attrByPath [ "shellHook" ] "" a) + "\n" + (lib.attrByPath [ "shellHook" ] "" v);
          } // rest a // rest v))
          { buildInputs = [ ]; }
          envs);

        shells = { pkgs ? defaultpkgs }:
          let
            evaluatedEnv = (env { inherit pkgs; });
          in
          builtins.mapAttrs
            (name: value: {
              buildInputs = value;
            } // (lib.attrByPath [ name ] { } evaluatedEnv))
            (buildInputs { inherit pkgs; });

        buildInputs = { pkgs ? defaultpkgs }: {
          base = with pkgs; [ gnumake ];
          golang = [
            pkgs.go_1_19
            pkgs.gopls
            pkgs.delve
            pkgs.golangci-lint
            (pkgs.runCommand "go-tools-subset" { } ''
              mkdir -p $out/bin
              ln -s ${pkgs.gotools}/bin/goimports $out/bin/goimports
              ln -s ${pkgs.gotools}/bin/godoc $out/bin/godoc
            '')
          ];

          terraform = with pkgs; [
            terraform
            terraform-ls
          ];

          python310 = with pkgs; [
            python310
            nodePackages.pyright
            python310Packages.mypy
            python310Packages.pytest
            python310Packages.pytest-cov
            python310Packages.black
          ];

          python39 = with pkgs; [
            python39
            nodePackages.pyright
            python39Packages.mypy
            python39Packages.pytest
            python39Packages.pytest-cov
            python39Packages.black
          ];

          rust = with pkgs; [
            cargo
            rustc
            rustfmt
            rust-analyzer
            cargo-edit
          ];
        };

        env = { pkgs ? defaultpkgs }: {
          rust = {
            # Certain Rust tools won't work without this
            # This can also be fixed by using oxalica/rust-overlay and specifying the rust-src extension
            # See https://discourse.nixos.org/t/rust-src-not-found-and-other-misadventures-of-developing-rust-on-nixos/11570/3?u=samuela. for more details.
            RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
            RUST_BACKTRACE = "1";
            # error from rust build: ld: library not found for -liconv
            # https://stackoverflow.com/questions/70313347/note-ld-library-not-found-for-lpq-when-build-rust-in-macos
            RUSTFLAGS = if pkgs.stdenv.isDarwin then "-L /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib" else "";
          };
        };
      });
}
