# Service images definition
{ tag ? "latest"
, localSystem ? builtins.currentSystem
, crossSystem
}:
let
  pkgs = import ./nix {
    inherit localSystem crossSystem;
  };
  # Import shell to get propagated build inputs.
  shell = import ./shell.nix { };
  # Use proper dockerTools.
  dockerTools = pkgs.pkgsBuildHost.dockerTools;
in
{
  axum_example_service = dockerTools.buildLayeredImage {
    inherit tag;
    name = "axum_example_service";

    contents = [
      # Some additional content
      pkgs.coreutils
      pkgs.bashInteractive
      pkgs.dockerTools.caCertificates
      # Copy actual binary
      (pkgs.copyBinaryFromCargoBuild {
        name = "axum_example_service";
        targetDir = ./target;
        buildInputs = shell.propagatedBuildInputs;
      })
      # Make it possible to debug image content
      pkgs.stdenv.cc.libc_bin
    ];

    config = {
      Cmd = [ "axum_example_service" ];
      WorkingDir = "/";
      Expose = 8080;
    };
  };
}
