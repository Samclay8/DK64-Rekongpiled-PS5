#!/usr/bin/env bash
# Writes the PS5 changes in src-upstream to patches/: dk64.patch for upstream's own tree (tracked
# files) and one patch per changed submodule, named by its path with "/" as "__". Submodule patches
# are against the submodule with upstream's tools/patch_*.py applied (committed as its HEAD by
# tools/setup-source.sh).
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
src="$root/src-upstream"
mkdir -p "$root/patches"
rm -f "$root"/patches/*.patch
git -C "$src" diff --ignore-submodules=all > "$root/patches/dk64.patch"
# Tracked files only, as for the top level: build output (the recompiler's build-linux) stays out.
# A new file goes in after `git add -N` on it.
while read -r path; do
    diff=$(git -C "$src/$path" diff --binary --ignore-submodules=all HEAD)
    [[ -z $diff ]] || printf '%s\n' "$diff" > "$root/patches/${path//\//__}.patch"
done < <(git -C "$src" submodule foreach --quiet --recursive 'echo "$displaypath"')
[[ -s $root/patches/dk64.patch ]] || rm "$root/patches/dk64.patch"
ls -la "$root/patches"
