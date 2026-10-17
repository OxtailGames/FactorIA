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

}  // namespace fa
