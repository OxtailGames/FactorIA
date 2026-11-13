// Which characters of a text no font can draw. No GPU or renderer needed: `factoria validate` uses it to catch a missing
// glyph in a string table or a scene before the game draws it as nothing.
//
// The chain is the one Text drawing uses (Renderer::set_fallback_fonts): the Text's own font, the project's fallback
// fonts, and the built-in DejaVu Sans last. A character is covered when ANY font of the chain has a glyph for it.
#pragma once

#include <cstdint>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/types.h"

namespace fa {

class FontCoverage {
public:
    // Loads the fonts of a chain: "" (DejaVu Sans), "builtin:pixel" (Press Start 2P) or a project-relative .ttf / .otf path,
    // read through fa::fs (so it works in a packed game too). The built-in DejaVu Sans is appended as the last font, like
    // Text drawing does; list the Text's own font first, then the fallback fonts. A font that is missing or cannot be
    // parsed is an error (message and hint say which file and what to do), never "missing glyphs".
    static Result<FontCoverage> load(const std::vector<std::string>& fontChain);

    // The distinct code points of `utf8` that no font of the chain has a glyph for, in order of first appearance.
    // Characters that draw nothing anyway never count: spaces, controls, zero-width joiners and direction marks,
    // variation selectors, the BOM. Malformed UTF-8 counts as U+FFFD.
    std::vector<std::uint32_t> missing(std::string_view utf8) const;

private:
    struct Impl;
    std::shared_ptr<const Impl> impl_;
};

// One-shot form of FontCoverage::load(fontChain)->missing(text). Loading the fonts takes a while, so check many texts
// with one FontCoverage.
Result<std::vector<std::uint32_t>> missing_glyphs(std::string_view utf8, const std::vector<std::string>& fontChain);

// One line of text drawn on the CPU as an 8-bit coverage bitmap (0 = nothing, 255 = full ink), cropped to the ink.
// No GPU or renderer needed (assets.draw_icon draws store icons with it).
struct TextBitmap {
    int width = 0, height = 0;
    std::vector<std::uint8_t> coverage;  // width * height, row 0 = top
    // Where the pen starts, in pixels of this bitmap: the baseline origin is at (originX, originY) of the cropped bitmap
    // (originY counts down from its top row, so the ink above the baseline is originY rows tall). Lets a caller place the text
    // by its baseline instead of by its ink. Zero for a text with no ink.
    int originX = 0, originY = 0;
    // Metrics of the first font at the requested size, also set when there is no ink: the pen advance of the whole text, and
    // the distances from the baseline up to the top of the line (ascent, positive) and down to its bottom (descent, positive).
    float advance = 0, ascent = 0, descent = 0;
};

// Draws `utf8` on one line at `pixelSize` px per em with `font` ("" = DejaVu Sans, "builtin:pixel", or a project .ttf),
// then the built-in DejaVu Sans for characters the font lacks. Plain left-to-right advance: no kerning, shaping or line
// breaks (a '\n' is dropped). Text with no ink (empty, spaces) gives an empty bitmap. An unreadable font is an error.
Result<TextBitmap> rasterize_text(std::string_view utf8, const std::string& font, float pixelSize);
// The same with the font file (.ttf / .otf) already in memory instead of a key: a damaged or truncated file is an error that says what
// is wrong, never a crash. For tools and tests, and what the fuzz target `font` calls.
Result<TextBitmap> rasterize_text(std::string_view utf8, const std::vector<std::uint8_t>& fontBytes, float pixelSize);

// One line or more of text as vector outlines, for turning text into paths (vector.text_to_path): the glyphs the engine itself
// would draw (HarfBuzz shaping: kerning, ligatures, joining scripts, right-to-left text), taken from the font and then the
// built-in DejaVu Sans for the characters it lacks. Coordinates are in units of `size` (the em), y DOWN, the origin at the
// start of the first line's baseline; a '\n' starts a new line below.
struct TextOutlineCmd {
    enum Kind : std::uint8_t { Move, Line, Quad, Cubic, Close } kind = Move;
    float x = 0, y = 0;    // the end point (Move, Line, Quad, Cubic)
    float cx = 0, cy = 0;  // Quad: its control point; Cubic: the first control point
    float dx = 0, dy = 0;  // Cubic: the second control point
};
enum class TextAnchor { Start, Middle, End };
struct TextOutline {
    std::vector<TextOutlineCmd> cmds;
    std::vector<float> lineWidths;  // the advance of each line, in the same units (letter spacing included)
    float advance = 0;              // the widest line
    float ascent = 0, descent = 0;  // of the first font: baseline up to the top, down to the bottom (positive)
    float lineHeight =
        0;           // the distance between two baselines (ascent + descent + the font's line gap) times lineSpacing
    int glyphs = 0;  // glyphs drawn (spaces and glyphs without ink included)
    std::vector<char32_t> missing;  // visible characters no font has (at most 8)
};
// `font`: "" / "builtin", "builtin:pixel", the other built-in names, or a project .ttf / .otf read through fa::fs. `anchor`
// places each line against the origin: its start, middle or end. `letterSpacing` is added after every glyph, in ems.
// An unreadable font is an error.
Result<TextOutline> outline_text(std::string_view utf8, const std::string& font, float size,
                                 TextAnchor anchor = TextAnchor::Start, float letterSpacing = 0.0f,
                                 float lineSpacing = 1.0f);

}  // namespace fa
