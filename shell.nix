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
  nativeBuildInputs = with pkgs.pkgsBuildHost; [
    # linters
    dprint
    # Rust files
    sccache
    rustToolchain
    # Enable cross-compilation support.
    pkgs.rustCrossHook
  ];

  buildInputs = with pkgs; [
    # List of tested native libraries.

    # Will add some dependencies like libiconv
    rustBuildHostDependencies
  ];
  # Nice shell prompt.
  shellHook = "${pkgs.crossBashPrompt}";
}
