#!/usr/bin/env bash
# Runs a build command directly in the dk64-ps5 WSL distro. Replaces the template's
# docker/run.sh: same working directory (WORKDIR, default the repo root), HOME and ccache
# directory, no container.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
mkdir -p "$root/.home/ccache"
cd "${WORKDIR:-$root}"
exec env HOME="$root/.home" CCACHE_DIR="$root/.home/ccache" bash -lc "$*"
