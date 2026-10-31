// Text shaping and line layout without a GPU: font fallback per character, HarfBuzz shaping, the Unicode bidirectional
// algorithm (SheenBidi) and line breaking. fonts.cpp turns the result into quads of the glyph atlas.
#pragma once

#include <functional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/scene/components.h"
#include "fa/scene/rich_text.h"
#include "font_internal.h"

namespace fa::render {

struct ShapedGlyph {
    FontFace* face = nullptr;
    std::uint32_t gid = 0;      // glyph index in `face`; 0 is the font's .notdef, which is never drawn
    std::uint32_t cluster = 0;  // index of the first code point it draws, in the decoded text (decode_text)
    float x = 0, y = 0;         // origin in pixels: x from the left end of the line, y up from the baseline
    float advance = 0;
    int icon = -1;       // >= 0: not a glyph but the picture icons[icon] of the rich text (face is null), `advance` wide
    bool synth = false;  // draw it emboldened by the engine (no bold face has this character)
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
// asked for only when a character needs them, so a fallback font nobody needs is never loaded. `wordBreak`: where a line
// may end between letters that have no space (Text.wordBreak). `direction`: the base direction of every paragraph (Text.direction):
// auto = the first strong character's, ltr / rtl = that way whatever the text starts with.
ShapedText shape_text(std::string_view text, int px, float maxWidth, std::size_t chainSize,
                      const std::function<FontFace*(std::size_t)>& chain, WordBreak wordBreak = WordBreak::Auto,
                      TextDirection direction = TextDirection::Auto);

// Rich text (Text.markup, Text.bold) for the shaper. `attrs` has one entry per code point of the text; a code point whose
// attr names an icon is shaped as a picture `iconAdvance[icon]` pixels wide (and as tall as the line).
struct RichShaping {
    const std::vector<MarkupAttr>* attrs = nullptr;
    std::vector<float> iconAdvance;                 // pixels, by attr.icon
    // The face of `font` for a bold and/or italic character, or null when there is none. `boldDrawn` is set when the face
    // returned is drawn bold (otherwise a bold character is emboldened by the engine).
    std::function<FontFace*(FontFace*, bool bold, bool italic, bool& boldDrawn)> variantFace;
    float syntheticExtra = 0.0f;                    // pixels a character emboldened by the engine is wider
};

// The same on code points already decoded (decode_text) and read as markup; `rich` may be null.
ShapedText shape_text(std::u32string_view text, int px, float maxWidth, std::size_t chainSize,
                      const std::function<FontFace*(std::size_t)>& chain, const RichShaping* rich, WordBreak wordBreak = WordBreak::Auto,
                      TextDirection direction = TextDirection::Auto);

// The grapheme cluster each code point of `text` belongs to, counted from 0: a base character with its combining marks,
// joiners, variation selectors and Hangul jamo, an emoji sequence, a flag and CR LF are one. What Text.visibleCharacters counts.
std::vector<std::uint32_t> grapheme_index(std::u32string_view text);

}  // namespace fa::render
