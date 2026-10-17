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

    FontFace() = default;
    FontFace(const FontFace&) = delete;
    FontFace& operator=(const FontFace&) = delete;
    ~FontFace();

    // True when the font maps `cp` to a glyph of its own.
    bool has_glyph(std::uint32_t cp) const;
};

// Loads one font: "" / "builtin" (DejaVu Sans), "builtin:pixel" (Press Start 2P) or a project-relative .ttf / .otf read
// through fa::fs. Always returns a face; `ok` is false (with `error` and `hint`) when the file is missing or unusable.
std::unique_ptr<FontFace> load_font_face(const std::string& key);

// Text as it is laid out: UTF-8 to code points (malformed bytes become U+FFFD); '\n', U+0085, U+2028 and U+2029 are line
// breaks (all become '\n'), a tab is four spaces, and '\r' and the other control characters are dropped.
std::u32string decode_text(std::string_view utf8);
// Plain UTF-8 to code points, nothing normalized (for messages).
std::u32string decode_utf8(std::string_view utf8);
std::string encode_utf8(char32_t cp);

// A character that should draw something: not a control, a zero-width or direction mark, a variation selector or a BOM.
bool is_visible(char32_t cp);
bool is_cjk(char32_t cp);    // Chinese, Japanese, Korean (for hints)
bool is_emoji(char32_t cp);  // for hints

}  // namespace fa::render
