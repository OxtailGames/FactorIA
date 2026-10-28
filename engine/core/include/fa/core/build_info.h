// The build fingerprint: which commit of the engine a program was built from. `factoria export` compares its own with the
// one inside the factoria_player it bundles (a player built from another commit may not know what the game uses).
#pragma once

#include <string>
#include <string_view>

namespace fa {

// The fingerprint of this program: the commit it was built from (12 hex digits), "-dirty" appended when tracked files had
// uncommitted changes, or "unknown" when the build was not made in a git checkout (an "unknown" is never compared).
const char* build_fingerprint();

// The fingerprint written in the bytes of a program file (any platform's executable that links fa_core), "" when it has none.
// Reading the bytes lets a factoria on one OS check the player of another.
std::string find_build_fingerprint(std::string_view fileBytes);

// The engine version (FA_ENGINE_VERSION, "0.3.0") written in the bytes of a program file next to its fingerprint, "" when
// it has none (a program built before the marker existed). The editor and the MCP server use it to name the release that
// replaced them on disk.
std::string find_build_version(std::string_view fileBytes);

}  // namespace fa
