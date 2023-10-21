{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-cross-overlay = {
      url = "github:alekseysidorov/nixpkgs-cross-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    treefmt-nix.url = "github:numtide/treefmt-nix";
    flake-root.url = "github:srid/flake-root";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.flake-root.flakeModule
      ];

      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];

      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.
      };

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        # Per-system attributes can be defined here. The self' and inputs'
        # module parameters provide easy access to attributes of the same
        # system.

        devShells = let localSystem = system; in {
          default = import ./shell.nix { inherit localSystem; };
          cross = import ./shell.nix {
            inherit localSystem;
            crossSystem = { config = "x86_64-unknown-linux-musl"; useLLVM = true; };
          };
        };

        treefmt.config = {
          inherit (config.flake-root) projectRootFile;

          programs.nixpkgs-fmt.enable = true;
          programs.rustfmt.enable = true;
          programs.beautysh.enable = true;
          programs.deno.enable = true;
          programs.taplo.enable = true;
        };

        formatter = config.treefmt.build.wrapper;
      };
    };
}
