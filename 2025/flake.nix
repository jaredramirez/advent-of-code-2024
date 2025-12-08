{
  description = "Description for the project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell.url = "github:numtide/devshell";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devshell.flakeModule
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        { pkgs, ... }:
        {
          devshells.default = {
            packages = [
              pkgs.erlang
              pkgs.gleam
              pkgs.watchexec
            ];
            commands = [
              {
                help = "Run a command, restarting whenever a gleam file changes";
                name = "run-watch";
                command = "watchexec -e gleam -c \"$@\"";
              }
              {
                help = "Run the gleam project exe";
                name = "run-aoc";
                command = "gleam run \"$@\"";
              }
            ];
          };
        };
      flake = { };
    };
}
