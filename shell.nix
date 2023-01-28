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
    # linters
    dprint
    # Rust
    rustToolchain
    sccache
    # Will add some dependencies like libiconv
    rustBuildHostDependencies
    # Manipulations with containers.
    skopeo
  ];
  # Libraries essential to build the service binaries.
  buildInputs = with pkgs; [
    # Enable cross-compilation support.
    rustCrossHook
    # Add crate dependencies
    cargoDeps.rocksdb-sys
  ];
  # Runtime dependencies that should be in the service container.
  propagatedBuildInputs = with pkgs; [
    openssl.dev
  ];
  # Prettify shell prompt.
  shellHook = "${pkgs.crossBashPrompt}";
  # Use sscache to improve rebuilding performance.
  RUSTC_WRAPPER = "sccache";
}
