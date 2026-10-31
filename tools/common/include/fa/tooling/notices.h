// License notices for what FactorIA binaries contain: FactorIA's own MIT license (LICENSE), then every third-party
// library and font with its license text (external/*/LICENSE*, engine/render/assets/fonts/*). The texts are embedded
// in the binary like the docs.
//
//   - `factoria export` writes the game notices (NoticeScope::Game) next to every exported game as FACTORIA_NOTICES.txt.
//   - `factoria docs licenses` (docs.read {"name":"licenses"}) prints everything (NoticeScope::All); the release
//     packages ship it as THIRD_PARTY_NOTICES.txt.
//
// The list itself is fa/core/notices.h (the game runtime reads it too). Adding a library to external/ means adding it
// to third_party_components() (a tooling test fails otherwise).
#pragma once

#include <set>
#include <string>

#include "fa/core/notices.h"  // third_party_components()

namespace fa {

enum class NoticeScope {
    Game,  // what an exported game contains: the engine runtime (factoria_player)
    All,   // also the developer tools (factoria, the editor)
};

// Plain-text notices: a header, then each component with its license text. Missing texts are named in the output
// (never silently dropped).
// `builtinFonts`: the built-in fonts a game ships ("builtin:serif", fa/render/builtin_fonts.h); their licenses are in the Game
// notices only then. The All scope lists every one.
std::string third_party_notices(NoticeScope scope, const std::set<std::string>& builtinFonts = {});

// File name the export writes next to the game.
inline constexpr const char* kExportNoticesFile = "FACTORIA_NOTICES.txt";

}  // namespace fa
