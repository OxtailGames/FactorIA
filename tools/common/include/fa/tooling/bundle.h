// Access to files that ship with the engine: docs/, templates/, schemas/.
//
// When the build embedded them (FA_HAS_EMBEDDED_FILES) they come from the
// binary, so `factoria` works offline from any directory. Otherwise they are
// read from FA_SOURCE_ROOT (development builds without embedding).
// Paths are repository-relative with forward slashes: "docs/SCRIPTING.md".
#pragma once

#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace fa {

// All bundled file paths starting with `prefix` ("docs/", "templates/2d-empty/"), sorted.
std::vector<std::string> bundled_list(std::string_view prefix);
std::optional<std::string> bundled_read(std::string_view path);
bool bundled_embedded();  // true when served from the binary

}  // namespace fa
