#!/usr/bin/env bash
# Generates DK64's recompiled game code from the user's ROM, as upstream's BUILDING.md does it:
#   1. decompress the ROM with the decompilation's tools/generate_decompressed_rom.py
#   2. build N64Recomp and RSPRecomp (n64recomp/, at the commit DK64's CI uses)
#   3. run them in src-upstream/: RecompiledFuncs/ and rsp/n_aspMain.cpp
#   tools/generate-game.sh "/mnt/dk64/rom/Donkey Kong 64.z64"
# Nothing generated here is ever published: it is code derived from the ROM.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
src="$root/src-upstream"
rom=${1:?usage: tools/generate-game.sh <US 1.0 DK64 ROM .z64>}
expected_sha1=cf806ff2603640a748fca5026ded28802f1f4a50

actual_sha1=$(sha1sum "$rom" | cut -d' ' -f1)
[[ $actual_sha1 == "$expected_sha1" ]] || {
    echo "generate-game.sh: $rom is not the US 1.0 ROM (sha1 $actual_sha1)" >&2; exit 2; }

# 1. Decompressed ROM. The script reads baserom.us.z64 from its working directory.
if [[ ! -f $src/donkeykong64.decompressed.us.z64 ]]; then
    work=$(mktemp -d)
    trap 'rm -rf -- "$work"' EXIT
    cp "$rom" "$work/baserom.us.z64"
    (cd "$work" && python3 "$src/lib/dk64_decomp/tools/generate_decompressed_rom.py")
    mv "$work/baserom.us.decompressed.z64" "$src/donkeykong64.decompressed.us.z64"
fi

# 2. The recompilers, built for this machine.
if [[ ! -x $root/n64recomp/build/N64Recomp || ! -x $root/n64recomp/build/RSPRecomp ]]; then
    cmake -S "$root/n64recomp" -B "$root/n64recomp/build" -G Ninja -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ >/dev/null
    cmake --build "$root/n64recomp/build" --target N64RecompCLI RSPRecomp
fi
cp "$root/n64recomp/build/N64Recomp" "$root/n64recomp/build/RSPRecomp" "$src/"

# 3. The game code.
cd "$src"
./N64Recomp us.toml
./RSPRecomp n_aspMain.toml

echo "generate-game.sh: $(ls RecompiledFuncs | wc -l) files in RecompiledFuncs/, $(du -sh RecompiledFuncs | cut -f1)"
