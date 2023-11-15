{
  inputs = {
    nixpkgs-cross-overlay = {
      url = "github:alekseysidorov/nixpkgs-cross-overlay";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    treefmt-nix.url = "github:numtide/treefmt-nix";
    flake-root.url = "github:srid/flake-root";
  };

  outputs = inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.flake-root.flakeModule
      ];

      systems = nixpkgs.lib.systems.flakeExposed;

      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.
      };

      perSystem = { config, self', inputs', system, nixpkgs, pkgs, ... }: {
        # Manual packages initialization, because the flake parts does not
        # yet come with an endoursed module.
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            inputs.nixpkgs-cross-overlay.overlays.default
          ];
        };
        _module.args.nixpkgs = inputs.nixpkgs;

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

        # Docker service image example using the native `nix build` approach without an
        # additional magical shell scripts.
        packages.dockerImage =
          let
            # pkgsCross = import inputs.nixpkgs {
            pkgsCross = pkgs.mkCrossPkgs {
              # inherit nixpkgs;
              localSystem = system;
              src = nixpkgs;
              crossSystem = {
                config = "x86_64-unknown-linux-musl";
                useLLVM = true;
              };

              overlays = [
                inputs.rust-overlay.overlays.default
                inputs.nixpkgs-cross-overlay.overlays.default
              ];
            };

            rustToolchain = pkgsCross.pkgsBuildHost.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;

            rustPlatform = pkgsCross.makeRustPlatform {
              cargo = rustToolchain;
              rustc = rustToolchain;
            };

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
