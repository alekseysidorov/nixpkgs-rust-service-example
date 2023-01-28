#! /usr/bin/env sh
set -eo pipefail

NIX_CROSS_SYSTEM=${NIX_CROSS_SYSTEM:-'{ config = "x86_64-unknown-linux-musl"; isStatic = true; useLLVM = true; }'}
service_name=${1}

# Compile service
nix-shell --pure --arg crossSystem "${NIX_CROSS_SYSTEM}" --run "cargo build --release -p ${service_name}"
image_archive=$(nix-build ./dockerImages.nix --arg crossSystem "$NIX_CROSS_SYSTEM" -A $service_name)
echo $image_archive
