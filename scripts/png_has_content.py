#!/usr/bin/env python3
"""Exit 0 when a PNG screenshot shows real content, 1 when it is (nearly) one flat colour.

    png_has_content.py <screenshot.png>

Used by ios-smoke.sh and android-smoke.sh: a game that runs but presents a black window must not pass. Standard
library only (8-bit RGB/RGBA PNGs, which is what `simctl io screenshot` and `screencap -p` write).
"""
import struct
import sys
import zlib

data = open(sys.argv[1], "rb").read()
need = 8  # distinct colours a real frame has; a black or flat window has 1
pos, idat = 8, b""
while pos < len(data):
    size, kind = struct.unpack(">I4s", data[pos:pos + 8])
    chunk = data[pos + 8:pos + 8 + size]
    if kind == b"IHDR":
        width, height, depth, ctype = struct.unpack(">IIBB", chunk[:10])
    elif kind == b"IDAT":
        idat += chunk
    pos += 12 + size
if depth != 8 or ctype not in (2, 6):
    sys.exit(f"unsupported PNG (bit depth {depth}, colour type {ctype}): {sys.argv[1]}")
bpp = 3 if ctype == 2 else 4
stride = width * bpp
raw = zlib.decompress(idat)
prev = bytearray(stride)
colours = set()
for y in range(height):
    start = y * (stride + 1)
    kind = raw[start]
    row = bytearray(raw[start + 1:start + 1 + stride])
    for i in range(stride):
        a = row[i - bpp] if i >= bpp else 0
        b = prev[i]
        c = prev[i - bpp] if i >= bpp else 0
        if kind == 1:
            row[i] = (row[i] + a) & 255
        elif kind == 2:
            row[i] = (row[i] + b) & 255
        elif kind == 3:
            row[i] = (row[i] + (a + b) // 2) & 255
        elif kind == 4:
            p = a + b - c
            pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
            row[i] = (row[i] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
    prev = row
    if len(colours) < need:
        colours.update(bytes(row[i:i + bpp]) for i in range(0, stride, bpp))
print(f"{sys.argv[1]}: {width}x{height}, {'at least ' if len(colours) >= need else ''}{len(colours)} distinct colours")
sys.exit(0 if len(colours) >= need else 1)
