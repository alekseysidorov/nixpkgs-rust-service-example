{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-cross-overlay = {
      url = "github:alekseysidorov/nixpkgs-cross-overlay/dev";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , treefmt-nix
    , rust-overlay
    , nixpkgs-cross-overlay
    , ...
    }: flake-utils.lib.eachDefaultSystem (system:
    let
      localSystem = system;
      crossSystem = {
        config = "x86_64-unknown-linux-musl";
      };

      pkgs = import nixpkgs {
        inherit system;

        overlays = [
          rust-overlay.overlays.default
          nixpkgs-cross-overlay.overlays.default
        ];
      };
      # Eval the treefmt modules from ./treefmt.nix
      treefmt = (treefmt-nix.lib.evalModule pkgs ./treefmt.nix).config.build;
    in
    {
      # for `nix fmt`
      formatter = treefmt.wrapper;
      # for `nix flake check`
      checks.formatting = treefmt.check self;

      devShells = {
        default = import ./shell.nix { inherit localSystem; };
        cross = import ./shell.nix {
          inherit localSystem crossSystem;
        };
      };
      # Docker service image example using the native `nix build` approach without an
      # additional magical shell scripts.
      packages.dockerImage =
        let
          pkgsCross = import nixpkgs {
            inherit localSystem crossSystem;
            overlays = [
              rust-overlay.overlays.default
              nixpkgs-cross-overlay.overlays.default
            ];
          };

          rustPlatform = pkgsCross.rustPlatform;

          serviceName = "axum_example_service";
          servicePackage = rustPlatform.buildRustPackage {
            pname = serviceName;
            version = "0.1.0";
            src = ./.;
            cargoLock.lockFile = ./Cargo.lock;

            nativeBuildInputs = with pkgsCross; [
              # Will add some dependencies like libiconv
              pkgsBuildHost.libiconv
              # Cargo crate dependencies
              cargoDeps.rocksdb-sys
              cargoDeps.rdkafka-sys
              cargoDeps.openssl-sys
            ];
            # Libraries essential to build the service binaries
            buildInputs = with pkgsCross; [
              # Enable Rust cross-compilation support
              rustCrossHook
            ];
          };
        in
        pkgsCross.pkgsBuildHost.dockerTools.buildLayeredImage {
          name = serviceName;

          contents = with pkgsCross; [
            servicePackage
            dockerTools.caCertificates
            # Utilites like ldd and bash to help image debugging
            stdenv.cc.libc_bin
            coreutils
            bashInteractive
          ];

          config = {
            Cmd = [ serviceName ];
            WorkingDir = "/";
            Expose = 8080;
          };
        };
    });
}
