"""Draws the Lantern Keep icon (a glowing lantern in front of a keep's arch) with Pillow.

Run from the project folder:  python tools/make_icon.py
Writes assets/icon.png (1024x1024, opaque) and assets/icon_fg.png (432x432, transparent, the Android adaptive-icon
foreground: the lantern sits inside the central 66/108 of the layer). Deterministic: no random numbers.
"""
from PIL import Image, ImageDraw, ImageFilter

S = 4  # supersampling


def lantern(size, scale):
    """The lantern on a transparent canvas of size x size px; scale 1.0 fills about 70 percent of the canvas."""
    n = size * S
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    u = n / 100.0 * scale
    cx = n / 2

    def X(v):
        return cx + v * u

    def Y(v):
        return n / 2 + v * u

    iron = (38, 30, 34, 255)
    # ring and hook
    d.ellipse([X(-7), Y(-47), X(7), Y(-33)], outline=iron, width=int(3 * u))
    # cap
    d.polygon([(X(-22), Y(-24)), (X(-9), Y(-36)), (X(9), Y(-36)), (X(22), Y(-24))], fill=iron)
    d.rectangle([X(-24), Y(-25), X(24), Y(-21)], fill=iron)
    # glass body
    d.rounded_rectangle([X(-19), Y(-21), X(19), Y(23)], radius=int(4 * u), fill=(255, 196, 70, 255))
    # inner glow
    d.ellipse([X(-13), Y(-14), X(13), Y(16)], fill=(255, 236, 160, 255))
    d.ellipse([X(-6), Y(-6), X(6), Y(10)], fill=(255, 252, 226, 255))
    # frame bars
    for bx in (-19, -6.5, 6.5, 19):
        d.rectangle([X(bx) - 1.2 * u, Y(-21), X(bx) + 1.2 * u, Y(23)], fill=iron)
    # base
    d.rectangle([X(-24), Y(23), X(24), Y(28)], fill=iron)
    d.polygon([(X(-20), Y(28)), (X(20), Y(28)), (X(14), Y(34)), (X(-14), Y(34))], fill=iron)
    return img


def glow(size, scale, radius, color):
    n = size * S
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    u = n / 100.0 * scale
    c = n / 2
    d.ellipse([c - radius * u, c - radius * u, c + radius * u, c + radius * u], fill=color)
    return img.filter(ImageFilter.GaussianBlur(radius * u * 0.55))


def background(size):
    n = size * S
    img = Image.new("RGBA", (n, n))
    px = img.load()
    for y in range(n):
        t = y / (n - 1)
        row = (int(16 + 20 * t), int(18 + 14 * t), int(40 + 30 * t), 255)
        for x in range(n):
            px[x, y] = row
    d = ImageDraw.Draw(img)
    u = n / 100.0
    stone = (30, 30, 58, 255)
    # an arch of the keep behind the lantern
    d.rounded_rectangle([n * 0.16, n * 0.14, n * 0.84, n * 1.2], radius=int(n * 0.34), fill=stone)
    d.rounded_rectangle([n * 0.24, n * 0.22, n * 0.76, n * 1.2], radius=int(n * 0.26), fill=(20, 21, 44, 255))
    # ground
    d.rectangle([0, n * 0.9, n, n], fill=(12, 12, 28, 255))
    return img


def main():
    bg = background(1024)
    bg.alpha_composite(glow(1024, 1.0, 46, (255, 170, 40, 150)))
    bg.alpha_composite(lantern(1024, 1.0))
    bg.resize((1024, 1024), Image.LANCZOS).convert("RGB").save("assets/icon.png", optimize=True)

    fg = Image.new("RGBA", (432 * S, 432 * S), (0, 0, 0, 0))
    fg.alpha_composite(glow(432, 0.62, 46, (255, 170, 40, 150)))
    fg.alpha_composite(lantern(432, 0.62))
    fg.resize((432, 432), Image.LANCZOS).save("assets/icon_fg.png", optimize=True)


main()
