#!/usr/bin/env bash
# Downloads every source the PS5 build needs into the Linux disk, at pinned commits.
# Run as the build user inside the dk64-ps5 distro. Safe to re-run: existing checkouts are kept.
#
#   ~/dk64-ps5/                 Marice's wave-race-64-ps5 (the template), branch dk64: our port
#   ~/dk64-ps5/src-upstream/    DK64 Recompiled v1.0.3 and its submodules (vcpkg skipped)
#   ~/dk64-ps5/n64recomp/       N64Recomp at the commit DK64's CI builds with
#   ~/dk64-ps5/radv/            Mihawk's PS5_Vulkan, PS5_Mesa (that one commit only), PS5_PayloadSDK
set -euo pipefail

root="$HOME/dk64-ps5"

template_url=https://github.com/Marice/wave-race-64-ps5
template_commit=016ce39d8026a114700771dae406e895b970799b    # 2026-11-03
dk64_url=https://github.com/Rainchus/Donkey-Kong-64-Recompiled
dk64_commit=3b0c36d3fbfeb0b5d2c47923f35cf84b31edcbf7        # v1.0.3, 2026-09-30
n64recomp_url=https://github.com/N64Recomp/N64Recomp
n64recomp_commit=2b6f05688de2abc7d86da5b4a89b84c2c6acbabe   # DK64's .github/workflows/validate.yml default

# Full clone at a commit, unless the directory is already there.
clone() { # url dir commit
    if [[ ! -d $2/.git ]]; then
        echo "clone: $1"
        git clone -q "$1" "$2"
    fi
    git -C "$2" checkout -q "$3"
}

# One commit only, no history (for Mesa, whose full history is about 650 MB).
fetch_commit() { # url dir commit
    if [[ ! -d $2/.git ]]; then
        echo "fetch: $1 @ ${3:0:12}"
        git init -q "$2"
        git -C "$2" remote add origin "$1"
    fi
    git -C "$2" cat-file -e "$3^{commit}" 2>/dev/null || git -C "$2" fetch -q --depth 1 origin "$3"
    git -C "$2" checkout -q "$3"
}

# The template becomes our port: branch dk64 from Marice's pinned commit. Skipped when ~/dk64-ps5 is
# already a checkout (this repository cloned there, or a setup from before).
if [[ ! -d $root/.git ]]; then
    clone "$template_url" "$root" "$template_commit"
    git -C "$root" checkout -q -b dk64
fi
# Rule 1: no FTP. The template's console upload script is removed from our copy.
rm -f "$root/tools/upload.sh"
# Downloaded trees are not part of our port's history.
for d in src-upstream n64recomp radv; do
    grep -qx "/$d/" "$root/.git/info/exclude" || echo "/$d/" >> "$root/.git/info/exclude"
done

# DK64 Recompiled and its submodules. vcpkg is for the Windows build only.
clone "$dk64_url" "$root/src-upstream" "$dk64_commit"
git -C "$root/src-upstream" -c submodule.lib/vcpkg.update=none submodule update -q --init --recursive --jobs 8

# The recompiler that generates DK64's C code from the ROM.
clone "$n64recomp_url" "$root/n64recomp" "$n64recomp_commit"
git -C "$root/n64recomp" submodule update -q --init --recursive --jobs 8

# Mihawk's RADV port at the commits Marice's ports pin (folder names as Marice's scripts expect).
mkdir -p "$root/radv"
clone https://github.com/mihawk-99/PS5_Vulkan "$root/radv/mihawk-vulkan-review" 5b5e4fc2d80fdb67a4f61ba9e6a8a424026bb8a5
clone https://github.com/mihawk-99/PS5_PayloadSDK "$root/radv/mihawk-sdk-review" b83202be73e930050e00de0f1b4d9ec46c0391bf
fetch_commit https://github.com/mihawk-99/PS5_Mesa "$root/radv/mihawk-mesa-review" 7b59ef27c1b09b9671bc4153c41940c3155c3af2
# PS5_Vulkan's scripts look for the Mesa and SDK checkouts under these names.
ln -sfn mihawk-sdk-review "$root/radv/PS5_PayloadSDK"
ln -sfn mihawk-mesa-review "$root/radv/PS5_Mesa"

echo "--- sources ready"
for d in "$root" "$root/src-upstream" "$root/n64recomp" "$root/radv/mihawk-vulkan-review" "$root/radv/mihawk-sdk-review" "$root/radv/mihawk-mesa-review"; do
    printf '%-40s %s\n' "${d#$HOME/}" "$(git -C "$d" log -1 --format='%h %cs %s' | cut -c1-70)"
done
git -C "$root/src-upstream" submodule status --recursive | cut -c1-90
du -sh "$root" | cut -f1 | sed 's/^/total size: /'
