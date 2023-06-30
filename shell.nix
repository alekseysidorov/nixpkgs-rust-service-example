# A simplest nix shell file with the project dependencies and 
# a cross-compilation support.
{ localSystem ? builtins.currentSystem
, crossSystem ? null
}:
let
  pkgs = import ./nix {
    inherit localSystem crossSystem;
  };
in
pkgs.mkShell {
  # Native project dependencies like build utilities and additional routines 
  # like container building, linters, etc.
  nativeBuildInputs = with pkgs.pkgsBuildHost; [
    git
    # Linters
    dprint
    nixpkgs-fmt
    # Rust
    (rust-bin.fromRustupToolchainFile ./rust-toolchain.toml)
    sccache
    # Will add some dependencies like libiconv
    rustBuildHostDependencies
    # Manipulations with containers
    skopeo
    docker
    # Add crate dependencies
    pkgs.cargoDeps.rocksdb-sys
    pkgs.cargoDeps.rdkafka-sys
    pkgs.cargoDeps.openssl-sys
  ];
  # Libraries essential to build the service binaries
  buildInputs = with pkgs; [
    # Enable Rust cross-compilation support
    rustCrossHook
  ];

  # Prettify shell prompt
  shellHook = "${pkgs.crossBashPrompt}";
  # Use sscache to improve rebuilding performance
  env.RUSTC_WRAPPER = "sccache";

  /* Service docker image definition
  
    To compile docker image run the following commands:
  
    ```shell
    # Setup the Nix cross compilation 
    export NIX_CROSS_SYSTEM='{ config = "x86_64-unknown-linux-musl"; isStatic = false; useLLVM = true; }'
    # Compile cargo binary
    nix-shell --pure --arg crossSystem "$NIX_CROSS_SYSTEM" --run "cargo build --release"
    # Build docker image from the compiled service
    docker load <$(nix-build ./shell.nix -A dockerImage --arg crossSystem "$NIX_CROSS_SYSTEM")
    ```
  */
  passthru.dockerImage =
    {
      # Cargo workspace member name
      name ? "axum_example_service"
    , tag ? "latest"
    }:
    pkgs.pkgsBuildHost.dockerTools.buildLayeredImage {
      inherit tag name;

      contents = with pkgs; [
        # Actual service binary compiled by Cargo
        (copyBinaryFromCargoBuild {
          inherit name;
          targetDir = ./target;
          # Use the shell native build inputs as runtime dependencies on which the compiled 
          # Rust binary depends.
          derivationArgs.buildInputs = [
            openssl
            rdkafka
            rocksdb
          ];
        })
        dockerTools.caCertificates
        # Utilites like ldd and bash to help image debugging
        stdenv.cc.libc_bin
        coreutils
        bashInteractive
      ];

      config = {
        Cmd = [ name ];
        WorkingDir = "/";
        Expose = 8080;
      };
    };
}
