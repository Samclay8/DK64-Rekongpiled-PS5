#!/usr/bin/env bash
# Prepares src-upstream/ for the PS5 build, once the sources are downloaded
# (/mnt/dk64/setup/fetch-sources.sh: DK64 Recompiled v1.0.3, N64Recomp, Mihawk's RADV port):
#   1. applies this port's patches/: dk64.patch to DK64 Recompiled's own tree, and
#      <submodule path>.patch (slashes as "__") to each submodule
#   2. given the ROM, generates the recompiled game code from it (tools/generate-game.sh)
#   tools/setup-source.sh "/mnt/dk64/rom/Donkey Kong 64.z64"
#   tools/setup-source.sh            patches only, no game code
# Changes are made in src-upstream/ and written back to patches/ by tools/make-patches.sh.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
src="$root/src-upstream"
rom=${1:-}

[[ -d $src/.git ]] || { echo "setup-source.sh: no $src; run setup/fetch-sources.sh first" >&2; exit 2; }

if [[ ! -f $src/.port-setup ]]; then
    for patch in "$root"/patches/*.patch; do
        [[ -e $patch ]] || continue
        name=$(basename "$patch" .patch)
        if [[ $name == dk64 ]]; then dir=$src; else dir="$src/${name//__//}"; fi
        git -C "$dir" apply --whitespace=nowarn "$patch"
        echo "applied $name"
    done
    touch "$src/.port-setup"
fi

[[ -z $rom ]] || "$root/tools/generate-game.sh" "$rom"
echo "setup-source.sh: sources ready; next: ./build.sh radv (once), ./build.sh configure, ./build.sh"
