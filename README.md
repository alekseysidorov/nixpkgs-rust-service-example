# nixpkgs-rust-service-example

This example shows how to compile a docker image containing the Rust binary by using 
the [`nixpkgs-cross-overlay`] facilities.

## Prerequisites

- You should have installed [Nix Package Manager] and `Docker`.
- You should enable the [Nix Flakes] feature.

## Usage

```shell
# Compile docker image
docker load <$(./scripts/build_docker_image.sh)
# Run docker image
docker run -it axum_example_service:latest
```

## License

MIT licensed.

## Contribution

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion
by you, shall be licensed as MIT, without any additional terms or conditions.

[Nix Package Manager]: https://nixos.org/download.html
[Nix Flakes]: https://nixos.wiki/wiki/Flakes
[`nixpkgs-cross-overlay`]: https://github.com/alekseysidorov/nixpkgs-cross-overlay
