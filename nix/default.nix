# Definition of Nix packages compatible with flakes and traditional workflow.
let
  lockFile = import ./flake-lock.nix { src = ./..; };
in
{ localSystem ? builtins.currentSystem
, crossSystem ? null
, src ? lockFile.nixpkgs
, config ? { }
, overlays ? [ ]
}:
let
  # Use the exact nixpkgs revision as the one used by nixpkgs-cross-overlay itself.
  nixpkgs = "${lockFile.nixpkgs-cross-overlay}/utils/nixpkgs.nix";

  pkgs = import nixpkgs {
    inherit localSystem crossSystem;
    overlays = [
      # Setup Rust toolchain for this project.
      (final: prev:
        let
          rustToolchain = prev.rust-bin.fromRustupToolchainFile ./../rust-toolchain.toml;
        in
        {
          inherit rustToolchain;
          rustc = rustToolchain;
          cargo = rustToolchain;
          clippy = rustToolchain;
          rustfmt = rustToolchain;
        })
    ] ++ overlays;
  };
in
pkgs
