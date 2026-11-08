#!/usr/bin/env bash
# Assembles the title folder dist/PPSA64064 from the build: eboot, home screen files, the system libc
# module, DK64 Recompiled's assets and controller database. No ROM: the player's own dump goes in by hand.
# The folder is then copied to the Windows project folder (/mnt/dk64/dist) for Sam to copy to the PS5.
#   tools/package.sh
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
title=PPSA64064
build="$root/build-ps5/dk64"
src="$root/src-upstream"
radv="$root/radv/mihawk-vulkan-review"
app="$root/dist/$title"

rm -rf -- "$app"
mkdir -p "$app/sce_sys" "$app/sce_module"
cp "$build/DK64Recompiled" "$app/eboot.bin"
cp "$root/sce_sys/param.json" "$app/sce_sys/"
# Home screen icon (512x512): the logo over the background picture's sky, made by tools/make-art.py; without
# it, DK64 Recompiled's own app icon.
if [[ -f $root/build-art/icon0.png ]]; then
    cp "$root/build-art/icon0.png" "$app/sce_sys/icon0.png"
else
    python3 -I - "$src/icons/app.png" "$app/sce_sys/icon0.png" <<'PY'
import sys
from PIL import Image
Image.open(sys.argv[1]).convert("RGB").resize((512, 512), Image.LANCZOS).save(sys.argv[2], optimize=True)
PY
fi
# Home screen background (pic0, also the ROM screen's) and start-up splash (pic1), when made: tools/make-art.py
# makes them from assets/background-source.webp, tools/make-backgrounds.py converts them (both need the .venv).
if [[ -f $root/sce_sys/pic0.dds && -f $root/sce_sys/pic1.dds ]]; then
    cp "$root"/sce_sys/{pic0.dds,pic1.dds} "$app/sce_sys/"
fi
cp "$radv/runtime/libc.prx" "$app/sce_module/libc.prx"
# RecompFrontend reads its assets from <program path>/assets and the controller database from the
# program path, both /app0 on the PS5.
cp -r "$src/assets" "$app/assets"
# The ROM screen's background (src/main/launcher_animation.cpp), made by tools/make-art.py with the others.
if [[ -f $root/build-art/rom-screen.png ]]; then
    cp "$root/build-art/rom-screen.png" "$app/assets/"
fi
cp "$src/recompcontrollerdb.txt" "$app/"

# Never ship anything derived from a ROM other than the compiled game code itself.
if find "$app" -iname '*.z64' -o -iname '*.n64' -o -iname '*.v64' | grep -q .; then
    echo "package.sh: a ROM file ended up in $app" >&2; exit 2
fi
echo "package.sh: $app ($(du -sh "$app" | cut -f1))"

if [[ -d /mnt/dk64/dist ]]; then
    rm -rf -- "/mnt/dk64/dist/$title"
    cp -r "$app" "/mnt/dk64/dist/$title"
    echo "package.sh: copied to the project folder: dist/$title"
fi
