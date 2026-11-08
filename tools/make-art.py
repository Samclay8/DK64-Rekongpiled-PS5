#!/usr/bin/env python3
"""Makes the home screen art from one picture: background.png (the home screen's background, pic0) and
splash.png (the splash while the title starts, pic1: the picture with the DK64 Rekongpiled logo). Both are
3840x2160: the picture is cropped to 16:9 from the middle and scaled to that size. tools/make-backgrounds.py
turns them into the console's DDS files. The ROM screen shows pic0 too, under its own animated logo
(rom-screen.png), and icon0.png (512x512, the home screen icon) is the logo over the sky at the top middle
of the picture (a square 24% of its width, so the picture needs open sky there), with the jungle from its
bottom middle faded in below. logo.png is the logo alone, transparent, for making art elsewhere.

The logo is DK64 Recompiled's own (its launcher's SVGs), placed as its launcher places it
(src/main/launcher_animation.cpp, the end of its animation): sizes and offsets are in the launcher's dp units,
measured from the middle of a 1920x1080 screen, each part scaled about its own middle.

Needs Pillow and resvg-py (python3 -m venv .venv && .venv/bin/pip install pillow etcpak resvg-py):
    .venv/bin/python tools/make-art.py src-upstream/assets assets/background-source.webp build-art
"""
import io
import re
import sys
from pathlib import Path

import resvg_py
from PIL import Image, ImageFilter

WIDTH, HEIGHT = 3840, 2160
DP = WIDTH / 1920  # pixels per launcher dp
ICON = 512

# (svg, width, height, x offset, y offset, scale), drawn in order.
LOGO = [
    ("logo_64.svg", 336, 283, 160, -405, 0.75),
    ("logo_k.svg", 267, 304, -10, -405, 0.75),
    ("logo_d.svg", 292, 306, -160, -405, 0.75),
    ("logo_subtitle.svg", 1280, 747, 0, -365, 0.5),
]


def render(assets: Path, name: str, width: int, height: int) -> Image.Image:
    # The logo letters give their size in mm, which resvg-py refuses: size the root element directly.
    svg = (assets / name).read_text(encoding="utf-8")
    root = re.search(r"<svg\b[^>]*>", svg)
    tag = re.sub(r'\s(width|height)="[^"]*"', "", root.group(0))
    tag = tag.replace("<svg", f'<svg width="{width}" height="{height}"', 1)
    svg = svg[:root.start()] + tag + svg[root.end():]
    png = resvg_py.svg_to_bytes(svg_string=svg, width=width, height=height)
    return Image.open(io.BytesIO(bytes(png))).convert("RGBA")


def draw_logo(canvas: Image.Image, assets: Path) -> None:
    for name, w, h, x, y, scale in LOGO:
        pw, ph = round(w * scale * DP), round(h * scale * DP)
        cx, cy = WIDTH / 2 + x * DP, HEIGHT / 2 + y * DP
        canvas.alpha_composite(render(assets, name, pw, ph), (round(cx - pw / 2), round(cy - ph / 2)))


def picture_16_9(path: Path) -> Image.Image:
    image = Image.open(path).convert("RGBA")
    w, h = image.size
    if w * 9 > h * 16:      # too wide: trim the sides
        new_w = h * 16 // 9
        image = image.crop(((w - new_w) // 2, 0, (w - new_w) // 2 + new_w, h))
    else:                   # too tall: trim top and bottom
        new_h = w * 9 // 16
        image = image.crop((0, (h - new_h) // 2, w, (h - new_h) // 2 + new_h))
    return image.resize((WIDTH, HEIGHT), Image.LANCZOS)


def main() -> None:
    if len(sys.argv) != 4:
        raise SystemExit("usage: make-art.py <DK64 Recompiled assets directory> <picture> <output directory>")
    assets, picture, out = Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3])
    out.mkdir(parents=True, exist_ok=True)

    background = picture_16_9(picture)
    background.convert("RGB").save(out / "background.png")
    # The ROM screen's background (the game's UI loads PNG; tools/package.sh puts it in the title's assets).
    background.convert("RGB").resize((1920, 1080), Image.LANCZOS).save(out / "rom-screen.png", optimize=True)

    splash = background.copy()
    draw_logo(splash, assets)
    splash.convert("RGB").save(out / "splash.png")

    # The icon: the sky at the picture's top middle, the jungle from its bottom middle faded in below, and the
    # logo at 88% of the width a third of the way down.
    source = Image.open(picture).convert("RGBA")
    side = round(source.width * 0.24)
    left = (source.width - side) // 2
    icon = source.crop((left, 0, left + side, side)).resize((ICON, ICON), Image.LANCZOS)
    # The trees are opaque over the icon's sky: only the real sky between them (clearly blue) is cut out, and the
    # distant haze along the strip's top edge fades in over a short band. The strip (x 35% to 60% of the
    # picture, its bottom 24%) misses the barrels and bananas of the current picture.
    strip_left, strip_right = round(source.width * 0.353), round(source.width * 0.598)
    strip_top = round(source.height * 0.757)
    strip = source.crop((strip_left, strip_top, strip_right, source.height))
    strip = strip.resize((ICON, round(ICON * strip.height / strip.width)), Image.LANCZOS)
    pixels = strip.load()
    mask = Image.new("L", strip.size, 255)
    mask_pixels = mask.load()
    for y in range(strip.height):
        edge = min(1.0, y / (strip.height * 0.08))
        for x in range(strip.width):
            r, g, b, _ = pixels[x, y]
            sky = b > g + 12 and b > r + 50
            mask_pixels[x, y] = 0 if sky else round(255 * edge)
    strip.putalpha(mask.filter(ImageFilter.GaussianBlur(1)))
    icon.alpha_composite(strip, (0, ICON - strip.height))
    logo = Image.new("RGBA", (WIDTH, HEIGHT))
    draw_logo(logo, assets)
    logo = logo.crop(logo.getbbox())
    logo.save(out / "logo.png", optimize=True)
    width = round(ICON * 0.88)
    logo = logo.resize((width, round(logo.height * width / logo.width)), Image.LANCZOS)
    icon.alpha_composite(logo, ((ICON - logo.width) // 2, round(ICON * 0.34 - logo.height / 2)))
    icon.convert("RGB").save(out / "icon0.png", optimize=True)

    for name in ("background.png", "splash.png", "rom-screen.png", "icon0.png", "logo.png"):
        print(f"wrote {out / name}")


if __name__ == "__main__":
    main()
