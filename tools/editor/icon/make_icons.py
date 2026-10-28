#!/usr/bin/env python3
"""Regenerates the FactorIA program icon files from the sources in tools/editor/icon/src/ (needs Pillow).

  src/factoria_art.png    the artwork, 1024x1024 on its dark background (the factory with the AI brain)
  src/factoria_small.svg  a simplified drawing for 16 and 24 px, where the artwork turns into a blur;
  src/factoria_small.png  its 256x256 render (any SVG renderer; Chrome headless works), which is what this script reads

Writes, next to this script:
  factoria_<size>.png     16..256: the window icon (Windows, Linux), embedded in the editor
  factoria_dock.png       512: the macOS Dock icon, with the margin of Apple's icon grid, embedded in the editor
and tools/cli/windows/factoria.ico (the same sizes) for factoria.exe and FactorIA-Editor.exe.

Run it after changing a source:  python3 tools/editor/icon/make_icons.py
"""
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

HERE = Path(__file__).resolve().parent
ICO = HERE.parent.parent / "cli" / "windows" / "factoria.ico"
WINDOW_SIZES = [16, 24, 32, 48, 64, 128, 256]
SMALL_SIZES = {16, 24}       # drawn from the simplified source
ART_CROP = (119, 69, 919, 869)  # the square of the artwork around the factory, the brain and the smoke
SS = 4                       # supersampling of the rounded-square mask


def rounded_mask(size, inset, radius):
    m = Image.new("L", (size * SS, size * SS), 0)
    ImageDraw.Draw(m).rounded_rectangle(
        [inset * SS, inset * SS, (size - inset) * SS - 1, (size - inset) * SS - 1], radius * SS, fill=255)
    return m.resize((size, size), Image.LANCZOS)


def tile(art, inset, radius):
    """The artwork in a rounded square of 1024 with `inset` px of margin and a thin blue rim, so the dark tile still
    stands out on a dark Dock or taskbar."""
    side = 1024 - 2 * inset
    canvas = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    canvas.paste(art.crop(ART_CROP).resize((side, side), Image.LANCZOS), (inset, inset))
    mask = rounded_mask(1024, inset, radius)
    rim = ImageChops.subtract(mask, rounded_mask(1024, inset + 5, radius - 5))
    rim_layer = Image.new("RGBA", (1024, 1024), (90, 130, 255, 0))
    rim_layer.putalpha(rim.point(lambda v: v * 70 // 255))
    canvas = Image.alpha_composite(canvas, rim_layer)
    canvas.putalpha(ImageChops.multiply(canvas.getchannel("A"), mask))
    return canvas


def main():
    art = Image.open(HERE / "src" / "factoria_art.png").convert("RGB")
    small = Image.open(HERE / "src" / "factoria_small.png").convert("RGBA")
    square = tile(art, 16, 200)   # Windows and Linux: nearly full bleed
    mac = tile(art, 100, 185)     # macOS icon grid: an 824 px tile inside 1024

    images = []
    for size in WINDOW_SIZES:
        img = (small if size in SMALL_SIZES else square).resize((size, size), Image.LANCZOS)
        img.save(HERE / f"factoria_{size}.png", optimize=True)
        images.append(img)
    mac.resize((512, 512), Image.LANCZOS).save(HERE / "factoria_dock.png", optimize=True)

    ICO.parent.mkdir(parents=True, exist_ok=True)
    images[-1].save(ICO, sizes=[(s, s) for s in WINDOW_SIZES], append_images=images[:-1])
    print("wrote", len(WINDOW_SIZES), "window sizes, factoria_dock.png and", ICO)


if __name__ == "__main__":
    main()
