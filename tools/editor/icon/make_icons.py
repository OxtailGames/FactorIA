#!/usr/bin/env python3
"""Regenerates the FactorIA program icon files from the sources in tools/editor/icon/src/ (needs Pillow).

  src/factoria_art.png    the artwork, 1024x1024 on its dark background (the factory with the AI brain)
  src/factoria_small.svg  a simplified drawing for 16 and 24 px, where the artwork turns into a blur;
  src/factoria_small.png  its 256x256 render (any SVG renderer; Chrome headless works), which is what this script reads

Writes, next to this script:
  factoria_<size>.png     16..256: the window icon (Windows, Linux), embedded in the editor
  factoria_dock.png       512: the macOS Dock icon, with the margin of Apple's icon grid, embedded in the editor
  factoria.icns           the same tile from 16 to 1024, for a macOS .app bundle (Contents/Resources/AppIcon.icns),
                          which is what the Dock and Finder show while the editor is not running
and tools/cli/windows/factoria.ico (the same sizes) for factoria.exe and FactorIA-Editor.exe, and
platforms/linux/factoria.png (256) for the Linux AppImage.

Run it after changing a source:  python3 tools/editor/icon/make_icons.py
"""
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

HERE = Path(__file__).resolve().parent
ICO = HERE.parent.parent / "cli" / "windows" / "factoria.ico"
APPIMAGE_PNG = HERE.parent.parent.parent / "platforms" / "linux" / "factoria.png"
WINDOW_SIZES = [16, 24, 32, 48, 64, 128, 256]
SMALL_SIZES = {16, 24}       # drawn from the simplified source
PAD = 96                     # background added around the artwork, so a crop may reach past its edges
TILE_TOP, TILE_BOTTOM = (34, 50, 104), (12, 18, 48)  # the navy the tile background is lifted to (see lift)
SS = 4                       # supersampling of the rounded-square mask


def rounded_mask(size, inset, radius):
    m = Image.new("L", (size * SS, size * SS), 0)
    ImageDraw.Draw(m).rounded_rectangle(
        [inset * SS, inset * SS, (size - inset) * SS - 1, (size - inset) * SS - 1], radius * SS, fill=255)
    return m.resize((size, size), Image.LANCZOS)


def padded(art):
    """The artwork with PAD px more of its dark background on every side: a blurred stretch of it behind, the artwork
    on top with feathered edges, so there is no seam."""
    w, h = art.size
    out = art.resize((w + 2 * PAD, h + 2 * PAD), Image.LANCZOS).filter(ImageFilter.GaussianBlur(24))
    feather = Image.new("L", (w, h), 0)
    ImageDraw.Draw(feather).rectangle([PAD // 2, PAD // 2, w - PAD // 2, h - PAD // 2], fill=255)
    out.paste(art, (PAD, PAD), feather.filter(ImageFilter.GaussianBlur(PAD // 4)))
    return out


def content_box(art):
    """The bounding box of the drawing (the factory, the brain and the smoke) on the dark background."""
    return art.convert("L").point(lambda v: 255 if v > 40 else 0).getbbox()


def lift(img, top, bottom):
    """Screen-blends a vertical gradient from `top` to `bottom` over `img`: the near-black background turns navy, so the
    tile reads as a whole tile on a dark Dock or taskbar, while the white and the glows stay as they are."""
    w, h = img.size
    grad = Image.new("RGB", (1, h))
    for y in range(h):
        t = y / (h - 1)
        grad.putpixel((0, y), tuple(round(a + (b - a) * t) for a, b in zip(top, bottom)))
    return ImageChops.screen(img, grad.resize((w, h)))


def tile(art, inset, radius, fill):
    """The artwork in a rounded square of 1024 with `inset` px of margin and a thin blue rim, so the dark tile still
    stands out on a dark Dock or taskbar. The drawing is centred and its longer side takes `fill` of the tile."""
    side = 1024 - 2 * inset
    x0, y0, x1, y1 = content_box(art)
    crop = max(x1 - x0, y1 - y0) / fill
    cx, cy = (x0 + x1) / 2 + PAD, (y0 + y1) / 2 + PAD
    box = tuple(round(v) for v in (cx - crop / 2, cy - crop / 2, cx + crop / 2, cy + crop / 2))
    canvas = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    canvas.paste(lift(padded(art).crop(box).resize((side, side), Image.LANCZOS), TILE_TOP, TILE_BOTTOM), (inset, inset))
    mask = rounded_mask(1024, inset, radius)
    rim = ImageChops.subtract(mask, rounded_mask(1024, inset + 5, radius - 5))
    rim_layer = Image.new("RGBA", (1024, 1024), (90, 130, 255, 0))
    rim_layer.putalpha(rim.point(lambda v: v * 110 // 255))
    canvas = Image.alpha_composite(canvas, rim_layer)
    canvas.putalpha(ImageChops.multiply(canvas.getchannel("A"), mask))
    return canvas


def main():
    art = Image.open(HERE / "src" / "factoria_art.png").convert("RGB")
    small = Image.open(HERE / "src" / "factoria_small.png").convert("RGBA")
    square = tile(art, 16, 200, 0.74)  # Windows and Linux: nearly full bleed, the drawing large for small sizes
    mac = tile(art, 100, 185, 0.70)    # macOS icon grid: an 824 px tile inside 1024, with room around the drawing

    images = []
    for size in WINDOW_SIZES:
        img = (small if size in SMALL_SIZES else square).resize((size, size), Image.LANCZOS)
        img.save(HERE / f"factoria_{size}.png", optimize=True)
        images.append(img)
        if size == 256:
            img.save(APPIMAGE_PNG, optimize=True)
    mac.resize((512, 512), Image.LANCZOS).save(HERE / "factoria_dock.png", optimize=True)
    mac.save(HERE / "factoria.icns")

    ICO.parent.mkdir(parents=True, exist_ok=True)
    images[-1].save(ICO, sizes=[(s, s) for s in WINDOW_SIZES], append_images=images[:-1])
    print("wrote", len(WINDOW_SIZES), "window sizes, factoria_dock.png, factoria.icns,", ICO, "and", APPIMAGE_PNG)


if __name__ == "__main__":
    main()
