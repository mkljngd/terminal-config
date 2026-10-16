"""Turn a small flat PNG icon into a one-glyph COLRv0 color font.

Each opaque pixel is snapped to the nearest palette color and becomes a
square in that color's layer; horizontal runs are merged to keep it small.
"""
import sys
from PIL import Image
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.colorLib.builder import buildCOLR, buildCPAL

SRC, OUT, CODEPOINT = sys.argv[1], sys.argv[2], int(sys.argv[3], 16)
FAMILY = "Custom Prompt Icons"
UPM, ASCENT, DESCENT = 1000, 800, -200
ALPHA_CUTOFF = 128

im = Image.open(SRC).convert("RGBA")
im = im.crop(im.getbbox())
w, h = im.size
px = (ASCENT - DESCENT) / h            # font units per pixel
advance = round(w * px)

# Palette: k-means-lite over opaque pixels, seeded with the dominant colors.
opaque = [(x, y, p[:3]) for y in range(h) for x in range(w)
          if (p := im.getpixel((x, y)))[3] >= ALPHA_CUTOFF]
def dist(a, b): return sum((i - j) ** 2 for i, j in zip(a, b))
palette = []
for _, _, c in sorted(opaque, key=lambda t: -sum(dist(t[2], o[2]) < 900 for o in opaque[::7])):
    if all(dist(c, p) > 3000 for p in palette):
        palette.append(c)
    if len(palette) == 6:
        break

layers = {i: [] for i in range(len(palette))}
for x, y, c in opaque:
    layers[min(range(len(palette)), key=lambda i: dist(c, palette[i]))].append((x, y))

def layer_glyph(pixels):
    pen = TTGlyphPen(None)
    rows = {}
    for x, y in pixels:
        rows.setdefault(y, []).append(x)
    for y, xs in rows.items():
        xs.sort()
        start = prev = xs[0]
        for x in xs[1:] + [None]:
            if x is not None and x == prev + 1:
                prev = x
                continue
            x0, x1 = round(start * px), round((prev + 1) * px)
            y1 = round(ASCENT - y * px); y0 = round(ASCENT - (y + 1) * px)
            pen.moveTo((x0, y0)); pen.lineTo((x0, y1)); pen.lineTo((x1, y1)); pen.lineTo((x1, y0)); pen.closePath()
            if x is not None:
                start = prev = x
    return pen.glyph()

names = [".notdef", "icon"] + [f"icon.layer{i}" for i in layers]
glyphs = {".notdef": TTGlyphPen(None).glyph(), "icon": layer_glyph([p for ps in layers.values() for p in ps])}
for i, ps in layers.items():
    glyphs[f"icon.layer{i}"] = layer_glyph(ps)

fb = FontBuilder(UPM, isTTF=True)
fb.setupGlyphOrder(names)
fb.setupCharacterMap({CODEPOINT: "icon"})
fb.setupGlyf(glyphs)
# lsb must equal each glyph's xMin, or rasterizers shift layers out of register.
glyf = fb.font["glyf"]
for n in names:
    glyf[n].recalcBounds(glyf)
fb.setupHorizontalMetrics({n: (advance if n != ".notdef" else 500, getattr(glyf[n], "xMin", 0)) for n in names})
fb.setupHorizontalHeader(ascent=ASCENT, descent=DESCENT)
fb.setupNameTable({"familyName": FAMILY, "styleName": "Regular"})
fb.setupOS2(sTypoAscender=ASCENT, sTypoDescender=DESCENT, usWinAscent=ASCENT, usWinDescent=-DESCENT)
fb.setupPost()
fb.font["CPAL"] = buildCPAL([[(r / 255, g / 255, b / 255, 1.0) for r, g, b in palette]])
fb.font["COLR"] = buildCOLR({"icon": [(f"icon.layer{i}", i) for i in layers]}, version=0)
fb.save(OUT)
print(f"{OUT}: U+{CODEPOINT:X}, {w}x{h}px, palette", ["#%02x%02x%02x" % c for c in palette],
      "pixels/layer", [len(v) for v in layers.values()])
