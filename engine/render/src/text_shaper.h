// Text shaping and line layout without a GPU: font fallback per character, HarfBuzz shaping, the Unicode bidirectional
// algorithm (SheenBidi) and line breaking. fonts.cpp turns the result into quads of the glyph atlas.
#pragma once

#include <functional>
#include <string>
#include <string_view>
#include <vector>

#include "font_internal.h"

namespace fa::render {

struct ShapedGlyph {
    FontFace* face = nullptr;
    std::uint32_t gid = 0;      // glyph index in `face`; 0 is the font's .notdef, which is never drawn
    std::uint32_t cluster = 0;  // index of the first code point it draws, in the decoded text (decode_text)
    float x = 0, y = 0;         // origin in pixels: x from the left end of the line, y up from the baseline
    float advance = 0;
};

struct ShapedLine {
    std::vector<ShapedGlyph> glyphs;  // left to right on screen, whatever the direction of the text
    std::u32string text;              // the line's code points in logical order (a wrapped line has no trailing spaces)
    float width = 0;                  // pixels
};

struct ShapedText {
    std::vector<ShapedLine> lines;  // at least one (an empty text is one empty line)
    std::vector<char32_t> missing;  // visible code points no font of the chain has, in order of appearance (at most 8)
};

// Lays `text` out at `px` pixels per em, wrapping at `maxWidth` pixels (0 = never). The font of each character is the
// first of the chain that has it (a combining mark or joiner stays with its base character): `chain(i)` returns the
// i-th font of `chainSize`, or nullptr to skip one (a font that failed to load); chain(0) must not be null. Fonts are
// asked for only when a character needs them, so a fallback font nobody needs is never loaded.
ShapedText shape_text(std::string_view text, int px, float maxWidth, std::size_t chainSize,
                      const std::function<FontFace*(std::size_t)>& chain);

}  // namespace fa::render
