// Font files and text decoding shared by the text layout (text_shaper.cpp), the glyph atlas (fonts.cpp) and the
// GPU-free glyph coverage check (font_coverage.cpp).
#pragma once

#include <cstdint>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

#include <hb.h>
#include <stb_truetype.h>

namespace fa::render {

// One font file, parsed twice: stb_truetype rasterizes its glyphs and measures its lines, HarfBuzz maps characters to
// glyphs and positions them (kerning, ligatures, Arabic joining...). Both use the same glyph indices.
struct FontFace {
    std::string key;                       // "builtin", "builtin:pixel" or the project path
    std::vector<unsigned char> ownedData;  // for project fonts
    const unsigned char* data = nullptr;
    std::size_t size = 0;
    stbtt_fontinfo info{};
    hb_blob_t* blob = nullptr;
    hb_face_t* hbFace = nullptr;
    hb_font_t* hbFont = nullptr;  // scale = units per em: positions come out in font units
    int unitsPerEm = 1000;
    bool ok = false;
    int id = 0;
    std::string error, hint;  // why !ok: what is wrong with the file and what to do (teaching text)
    std::vector<std::string> untraced;  // loaded in the background: its files, reported to the load trace on first use

    FontFace() = default;
    FontFace(const FontFace&) = delete;
    FontFace& operator=(const FontFace&) = delete;
    ~FontFace();

    // True when the font maps `cp` to a glyph of its own.
    bool has_glyph(std::uint32_t cp) const;

    // Glyphs check_font_bytes found stb_truetype cannot be asked for (empty when there are none); index = glyph, 1 = unsafe.
    std::vector<std::uint8_t> unsafeGlyphs;

    // `glyph` as an index stb_truetype may read: a glyph the font does not have (a 'cmap' may point past 'maxp's glyph count,
    // and HarfBuzz hands on what it finds there) or one that cannot be drawn safely (a last contour of one point off the curve,
    // parts placed by matching points...) is drawn as glyph 0, the .notdef box. check_font_bytes made sure that glyph is fine.
    int stb_glyph(std::uint32_t glyph) const {
        if (glyph >= std::uint32_t(info.numGlyphs)) return 0;
        return glyph < unsafeGlyphs.size() && unsafeGlyphs[glyph] ? 0 : int(glyph);
    }
};

// What check_font_bytes found: `problem` is set when the whole file is unusable.
struct FontCheck {
    std::string problem;
    std::vector<std::uint8_t> unsafeGlyphs;  // see FontFace::unsafeGlyphs
};

// Loads one font: "" / "builtin" (DejaVu Sans), "builtin:pixel" (Press Start 2P) or a project-relative .ttf / .otf read
// through fa::fs. Always returns a face; `ok` is false (with `error` and `hint`) when the file is missing or unusable.
std::unique_ptr<FontFace> load_font_face(const std::string& key);

// The same on font bytes already in memory (`key` names them in the errors); the file loaders above end in the same code, so
// what loads from a file loads from memory and the reverse. What the fuzz target `font` and rasterize_text(bytes) use.
std::unique_ptr<FontFace> load_font_face_from_memory(std::vector<unsigned char> bytes, const std::string& key);

// Walks the tables stb_truetype will follow (directory, head, hhea, hmtx, maxp, loca, glyf, cmap) with the file's length in hand.
// `problem` is "" when every table and offset lies inside the file; else what is wrong, as a sentence (font_check.cpp). A glyph
// that is wrong by itself does not make `problem`: it is listed in `unsafeGlyphs`. `offset` is the start of the font in the file
// (stbtt_GetFontOffsetForIndex).
FontCheck check_font_bytes(const unsigned char* data, std::size_t size, int offset);

// Text as it is laid out: UTF-8 to code points (malformed bytes become U+FFFD); '\n', U+0085, U+2028 and U+2029 are line
// breaks (all become '\n'), a tab is four spaces, and '\r' and the other control characters are dropped.
std::u32string decode_text(std::string_view utf8);

// A character that should draw something: not a control, a zero-width or direction mark, a variation selector or a BOM.
bool is_visible(char32_t cp);

// HarfBuzz always decomposes SARA AM (U+0E33 into U+0E4D U+0E32) and the Lao AM (U+0EB3 into U+0ECD U+0EB2), whether or
// not the font has the composed character, so the font needs the two parts. Returns the parts, or an empty view when `cp`
// is not a composed vowel.
std::u32string_view composed_parts(char32_t cp);
bool is_cjk(char32_t cp);    // Chinese, Japanese, Korean (for hints)
bool is_emoji(char32_t cp);  // for hints

}  // namespace fa::render
