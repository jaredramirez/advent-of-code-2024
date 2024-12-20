{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-util.url = "github:numtide/flake-utils";
    roc.url = "github:roc-lang/roc";
  };

  outputs = inputs@{ self, ... }:
    inputs.flake-util.lib.eachDefaultSystem (system:
      let pkgs = import inputs.nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            (inputs.roc.packages.${system}.cli)
            (inputs.roc.packages.${system}.lang-server)
            pkgs.entr
          ];
        };
      });
}

