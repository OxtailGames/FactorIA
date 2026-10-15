// License notices for what FactorIA binaries contain: FactorIA's own MIT license (LICENSE), then every third-party
// library and font with its license text (external/*/LICENSE*, engine/render/assets/fonts/*). The texts are embedded
// in the binary like the docs.
//
//   - `factoria export` writes the game notices (NoticeScope::Game) next to every exported game as FACTORIA_NOTICES.txt.
//   - `factoria docs licenses` (docs.read {"name":"licenses"}) prints everything (NoticeScope::All); the release
//     packages ship it as THIRD_PARTY_NOTICES.txt.
//
// Adding a library to external/ means adding it to third_party_components() (a tooling test fails otherwise).
#pragma once

#include <string>
#include <vector>

namespace fa {

enum class NoticeScope {
    Game,  // what an exported game contains: the engine runtime (factoria_player)
    All,   // also the developer tools (factoria, the editor)
};

struct ThirdPartyComponent {
    std::string name;         // "sokol"
    std::string url;          // home page / repository
    std::string license;      // SPDX-style id: "zlib", "MIT", "OFL-1.1"
    std::string licenseFile;  // repository-relative, bundled: "external/sokol/LICENSE"
    std::string usedFor;      // one line for the reader
    bool inGames = true;      // false: only in the developer tools (the editor's UI library)
};

// FactorIA itself first, then the third-party parts, in a fixed order.
const std::vector<ThirdPartyComponent>& third_party_components();

// Plain-text notices: a header, then each component with its license text. Missing texts are named in the output
// (never silently dropped).
std::string third_party_notices(NoticeScope scope);

// File name the export writes next to the game.
inline constexpr const char* kExportNoticesFile = "FACTORIA_NOTICES.txt";

}  // namespace fa
