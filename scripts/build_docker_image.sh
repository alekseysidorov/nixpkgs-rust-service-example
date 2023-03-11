#! /usr/bin/env bash
set -eo pipefail

NIX_CROSS_SYSTEM=${NIX_CROSS_SYSTEM:-'{ config = "x86_64-unknown-linux-musl"; isStatic = false; useLLVM = true; }'}

# Compile service
nix-shell --pure --arg crossSystem "${NIX_CROSS_SYSTEM}" --run "cargo build --release"
image_archive=$(nix-build ./shell.nix -A dockerImage --arg crossSystem "$NIX_CROSS_SYSTEM")
echo $image_archive
