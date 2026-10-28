// What FactorIA binaries contain besides FactorIA's own code: every third-party library and font, with its license.
// The game runtime lists the parts it ships (`inGames`) to scripts (game.notices(), for a credits screen); the
// developer tools assemble the full license texts from the same list (fa/tooling/notices.h: FACTORIA_NOTICES.txt).
//
// Adding a library to external/ means adding it here (a tooling test fails otherwise).
#pragma once

#include <string>
#include <vector>

namespace fa {

struct ThirdPartyComponent {
    std::string name;         // "sokol"
    std::string url;          // home page / repository
    std::string license;      // SPDX-style id: "zlib", "MIT", "OFL-1.1"
    std::string licenseFile;  // repository-relative, bundled: "external/sokol/LICENSE"
    std::string usedFor;      // one line for the reader
    bool inGames = true;      // false: only in the developer tools (the editor's UI library)
    std::string fontKey = {};  // a built-in font that is not inside the player ("builtin:serif"): an export ships it, and so lists
                              // this component, only in games that name it (inGames is false)
};

// FactorIA itself first, then the third-party parts, in a fixed order.
const std::vector<ThirdPartyComponent>& third_party_components();

}  // namespace fa
