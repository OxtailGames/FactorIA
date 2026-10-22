// The one JSON patcher of the tooling: changes some keys of a JSON file's TEXT and leaves everything else as it was (the
// order of the keys, the indentation, line endings, comments in the whitespace, the other keys byte for byte). Commands that
// edit a hand-written file (factoria.json) use it instead of loading and dumping the whole document: save_export_settings,
// project.new_plugin, platform.add_backend.
#pragma once

#include <optional>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

// One change: set the value at `path` (object keys, outermost first, e.g. {"plugins", "steam"}) or, with no `value`,
// remove it. A key that does not exist yet is appended after the last key of its object, with the separator the file
// already uses; parents that do not exist are created. Arrays are not walked into: a path stops at the first key.
struct JsonPatchOp {
    std::vector<std::string> path;
    std::optional<Json> value;  // nullopt = remove the key (nothing happens when it is not there)
};

// The text with the changes applied in order. `file` names the file in error messages. Fails (and says how to fix it) when the
// text is not a JSON object, when a path goes through a value that is not an object, or when the result would not parse.
Result<std::string> patch_json_text(const std::string& text, const std::vector<JsonPatchOp>& ops, const std::string& file = "JSON");

// Reads `path`, patches it, writes it back only when the text changed. Returns the new text.
Result<std::string> patch_json_file(const std::string& path, const std::vector<JsonPatchOp>& ops);

}  // namespace fa
