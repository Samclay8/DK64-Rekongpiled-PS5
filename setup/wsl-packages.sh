#!/usr/bin/env bash
# Installs the build environment into the dk64-ps5 WSL distro. Run as root.
# Same packages as Marice's wave-race-64-ps5 docker/packages.txt (Ubuntu 26.04, LLVM 18 and 21,
# MIPS binutils) and the same clang links as its docker/Dockerfile, without Docker.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

packages=(
    ca-certificates git curl wget unzip zip xz-utils file make build-essential pkgconf
    bsdextrautils patch cmake ninja-build ccache nasm meson rsync bison flex glslang-tools
    spirv-tools python3 python3-venv python3-pip python3-mako python3-yaml python3-packaging
    python3-ply clang-18 lld-18 llvm-18 libclang-rt-18-dev clang-21 lld-21 llvm-21
    libclang-rt-21-dev llvm-21-dev libclang-21-dev libclang-cpp21-dev libclc-21 libclc-21-dev
    libllvmspirvlib-21-dev spirv-tools-dev spirv-headers libexpat1-dev zlib1g-dev
    binutils-mips-linux-gnu python3-pil
)

apt-get update
apt-get install -y --no-install-recommends "${packages[@]}"

# Upstream's scripts call plain clang and clang++.
ln -sfn /usr/bin/clang-21 /usr/local/bin/clang
ln -sfn /usr/bin/clang++-21 /usr/local/bin/clang++

echo "packages installed"
