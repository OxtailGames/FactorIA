"""How the NotoSans*-Regular-subset.ttf files next to this script were made (they are test fixtures, not run by CMake).

Source: the variable fonts NotoSansJP[wght].ttf, NotoSansKR[wght].ttf and NotoSansArabic[wdth,wght].ttf from
https://github.com/google/fonts (ofl/notosansjp, ofl/notosanskr, ofl/notosansarabic), SIL Open Font License 1.1 (OFL.txt).
Each is instanced to Regular and cut down to the characters the text tests draw, keeping the GSUB/GPOS shaping tables
(Arabic joining and marks, kerning, ligatures) so the tests exercise real shaping. Needs fontTools (pip install fonttools).
Save the three downloads as NotoSansJP-VF.ttf, NotoSansKR-VF.ttf and NotoSansArabic-VF.ttf, then:
    python make_subsets.py <download dir> <output dir>"""
import os
import sys

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

src_dir, out_dir = sys.argv[1], sys.argv[2]
os.makedirs(out_dir, exist_ok=True)


def rng(a, b):
    return "".join(chr(c) for c in range(a, b + 1))


COMMON = " 0123456789"
# Strings the tests draw (engine/render/tests/text_tests.cpp). Keep this in step with them.
JP = (
    COMMON
    + "日本語 中文"
    + "　、。「」『』（）〜・！？，：；"   # CJK punctuation: the closing and opening ones the kinsoku test needs
    + rng(0x3041, 0x3096)   # hiragana
    + rng(0x30A1, 0x30FA) + "ー"  # katakana
    + "吾輩猫名前無生見当吾輩は猫である。名前はまだ無い。どこで生れたかとんと見当がつかぬ"
    + "中文沒有空格也可以自動換行這是一段沒有空格的中文文本需要自動換行"
    + "日本語の長い文章はスペースがなくても折り返されます"
    + "テスト折返確認設定言語文字"
)
KR = COMMON + "한국어 日本語 中文" + "한국어도 글자 사이에서 줄이 바뀝니다 안녕하세요 세계 한글 텍스트" + "한국어는띄어쓰기없이도줄바꿈됩니다"
AR = (
    COMMON
    + rng(0x0621, 0x063A) + rng(0x0640, 0x0652)   # letters, tatweel, harakat
    + rng(0x0660, 0x0669)                          # Arabic-Indic digits
    + "،؛؟"
    + "العربية مرحبا بالعالم"
    + "‌‍‎‏"
    + "abc "
)

JOBS = [
    ("NotoSansJP-VF.ttf", "NotoSansJP-Regular-subset.ttf", {"wght": 400}, JP),
    ("NotoSansKR-VF.ttf", "NotoSansKR-Regular-subset.ttf", {"wght": 400}, KR),
    ("NotoSansArabic-VF.ttf", "NotoSansArabic-Regular-subset.ttf", {"wght": 400, "wdth": 100}, AR),
]

for src, dst, axes, text in JOBS:
    font = TTFont(os.path.join(src_dir, src))
    cmap = font.getBestCmap()
    missing = sorted({c for c in text if ord(c) not in cmap and not c.isspace()})
    if missing:
        print(src, "has no glyph for:", " ".join(f"U+{ord(c):04X}" for c in missing))
    font = instancer.instantiateVariableFont(font, axes)
    opts = subset.Options()
    if "Arabic" in src:
        opts.layout_features = ["*"]   # every GSUB/GPOS feature of the kept glyphs: Arabic joining, marks, kerning, ligatures
    # CJK: the default feature set (kern, liga, calt, ccmp, locl, mark, mkmk...), without the vertical and width variants
    opts.hinting = False
    opts.notdef_outline = True
    opts.name_IDs = [0, 1, 2, 3, 4, 5, 6, 13, 14]
    opts.drop_tables += ["DSIG"]
    opts.glyph_names = False
    opts.legacy_kern = True
    sub = subset.Subsetter(opts)
    sub.populate(text=text)
    sub.subset(font)
    path = os.path.join(out_dir, dst)
    font.save(path)
    kept = font.getBestCmap()
    print(dst, os.path.getsize(path), "bytes,", len(font.getGlyphOrder()), "glyphs,", len(kept), "code points,",
          "GSUB" in font, "GPOS" in font)
