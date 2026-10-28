// The fonts that come with the engine, selectable by name in Text.font, localization.fallbackFonts, text.fonts, ...:
//
//   ""                  DejaVu Sans, the default (inside every player)
//   "builtin:pixel"     Press Start 2P (inside every player)
//   "builtin:serif"     Crimson Text, a book serif with real bold, italic and bold italic faces
//   "builtin:hand"      Kalam, handwriting, with a real bold face
//   "builtin:blackletter"  UnifrakturMaguntia, a blackletter title face (Latin only)
//   "builtin:display"   IM Fell English, an old-print storybook face, with a real italic face
//
// DejaVu Sans and Press Start 2P are embedded in the player. The others are SIL OFL files that live in the repository
// (engine/render/assets/fonts/extra/) and ship with the developer tools (factoria, the editor): a game that does not use them
// does not grow. `factoria export` copies the files of the fonts a project names to builtin-fonts/ in the game (and their
// license texts into FACTORIA_NOTICES.txt); the player reads them from there.
#pragma once

#include <functional>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace fa {

// Project-relative folder where an export puts the files of the built-in fonts a game uses.
inline constexpr const char* kBuiltinFontDir = "builtin-fonts";

struct BuiltinFont {
    std::string name;         // "builtin:serif" ("" is DejaVu Sans, listed under "builtin")
    std::string family;       // "Crimson Text"
    std::string description;  // what it looks like and what it covers
    bool embedded = false;    // inside every player; false: a file of the engine, copied by the export when used
    bool hasBold = false;     // a real bold face: Text.bold and [b] draw it instead of thickening the regular glyphs
    bool hasItalic = false;   // a real italic face for [i]
    bool hasBoldItalic = false;
    std::vector<std::string> files;  // file names (without folder) of every face of the family; empty when embedded
};

// All of them, DejaVu Sans first ("builtin"), in a fixed order.
const std::vector<BuiltinFont>& builtin_fonts();
// The names as one sentence for error hints: "\"\" (DejaVu Sans), \"builtin:pixel\" (Press Start 2P), \"builtin:serif\" ...".
std::string builtin_font_list();
// The entry a Text.font names ("builtin" and "" are DejaVu Sans), or null.
const BuiltinFont* find_builtin_font(std::string_view name);
// The built-in fonts a text mentions by name, in catalog order: the export looks for them in scenes, prefabs, scripts and
// factoria.json. A name counts when it is not followed by a letter, a digit or '-' / '_'.
std::vector<const BuiltinFont*> builtin_fonts_named_in(std::string_view text);

// The file of one face of a family ("CrimsonText-Italic.ttf"), or "" when the family has no such face. Files are listed in the
// order regular, bold, italic, bold italic (the faces it has).
std::string builtin_variant_file(const BuiltinFont& font, bool bold, bool italic);

// Where the files of the non-embedded fonts come from when the game folder has no builtin-fonts/ (the developer tools set
// it at startup, from the files embedded in them). Returns the bytes of `file`, or nullopt. Not thread safe: set it once.
using BuiltinFontSource = std::function<std::optional<std::string>(std::string_view file)>;
void set_builtin_font_source(BuiltinFontSource source);
// The bytes of a built-in font file from that source, or nullopt when there is none.
std::optional<std::string> builtin_font_file(std::string_view file);

}  // namespace fa
