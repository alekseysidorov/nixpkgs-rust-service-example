{
  inputs = {
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    nixpkgs-cross-overlay = {
      url = "github:alekseysidorov/nixpkgs-cross-overlay";
      inputs = {
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = { self, flake-utils, nixpkgs-cross-overlay }: { } // flake-utils.lib.eachDefaultSystem
    (localSystem:
      {
        devShells = {
          default = import ./shell.nix { inherit localSystem; };
          cross = import ./shell.nix {
            inherit localSystem;
            crossSystem = { config = "x86_64-unknown-linux-musl"; useLLVM = true; };
          };
        };
      }
    );
}
