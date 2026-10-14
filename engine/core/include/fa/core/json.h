// JSON everywhere: scenes, prefabs, project files, commands, MCP, AI APIs.
//
// fa::Json is nlohmann::ordered_json so files we write keep a stable,
// human-friendly key order (good diffs, predictable for AIs).
//
// Lenient readers (AI-friendly): math types accept several spellings and
// report precise errors. Writers always emit the canonical form.
//   Vec2  : [x, y]            | {"x":..,"y":..}
//   Vec3  : [x, y, z]         | {"x","y","z"} | [x, y] (z = 0)
//   Vec4  : [x, y, z, w]      | {"x","y","z","w"}
//   Color : [r, g, b(, a)]    | "#rgb" "#rrggbb" "#rrggbbaa" | "red", "white", ... (see color_names())
//           components are 0..1 floats; if any component > 1 the array is
//           treated as 0..255 bytes (with a warning-free conversion).
//   Rect  : [x, y, w, h]      | {"x","y","w","h"}
#pragma once

#include <nlohmann/json.hpp>

#include <functional>
#include <span>
#include <string>
#include <string_view>

#include "fa/core/math.h"
#include "fa/core/types.h"

namespace fa {

using Json = nlohmann::ordered_json;

// Parse text; errors include line/column and the source name.
Result<Json> parse_json(std::string_view text, std::string_view sourceName = "<memory>");
// Read and parse a project-relative or absolute file through fa::fs.
Result<Json> load_json_file(std::string_view path);
// Pretty-print with 2-space indent and a trailing newline (canonical on-disk format).
// Every array element goes on its own line; use the JsonFormat overloads below for files people review and diff.
std::string dump_json(const Json& j);
Result<void> save_json_file(std::string_view path, const Json& j);

// Compact layout for files that people and AIs read and diff (scenes, prefabs). Still standard JSON: loading is
// unaffected. Same 2-space indent as dump_json, except for arrays of scalars (numbers, booleans, null, short strings):
//   - one line when the array fits in `maxWidth` columns:  "position": [0, 12.5, 0]
//   - otherwise wrapped over several lines of at most `maxWidth` columns, as many elements per line as fit
//   - or, when `rowLength` returns N > 0 for an array of numbers, N numbers per line with right-aligned columns
// Every other array keeps one element per line, and objects are laid out as in dump_json.
struct JsonFormat {
    // Soft limit in columns for the lines of a scalar array (an element longer than the limit still gets its own line).
    int maxWidth = 100;
    // Strings longer than this (as written, with quotes) keep their array in the one-element-per-line layout.
    int maxInlineString = 40;
    // Optional hook that asks for a row layout. `path` lists the object keys and array indices from the document root to
    // `array` (for example "entities", "0", "components", "Tilemap", "tiles"); `parent` is the object or array that
    // holds `array` (a null value for the root). Return the number of elements per line, or 0 for the default layout.
    std::function<int(std::span<const std::string> path, const Json& parent, const Json& array)> rowLength;
};
std::string dump_json(const Json& j, const JsonFormat& format);
Result<void> save_json_file(std::string_view path, const Json& j, const JsonFormat& format);

// Typed readers. On failure return false and write a message to *err
// (e.g. "expected [x, y] or {\"x\":..,\"y\":..}, got \"abc\"").
bool json_to(const Json& j, bool& out, std::string* err);
bool json_to(const Json& j, int& out, std::string* err);
bool json_to(const Json& j, float& out, std::string* err);
bool json_to(const Json& j, std::string& out, std::string* err);
bool json_to(const Json& j, Vec2& out, std::string* err);
bool json_to(const Json& j, Vec3& out, std::string* err);
bool json_to(const Json& j, Vec4& out, std::string* err);
bool json_to(const Json& j, Color& out, std::string* err);
bool json_to(const Json& j, Rect& out, std::string* err);

// Floats are rounded to 4 decimals so files stay clean (0.1f -> 0.1, not 0.10000000149).
Json to_json(float v);
Json to_json(Vec2 v);
Json to_json(Vec3 v);
Json to_json(Vec4 v);
Json to_json(Color c);  // [r, g, b, a] rounded to 4 decimals
Json to_json(const Rect& r);

// Short description of a JSON value for error messages: string "abc", number 3, array [..] (truncated).
std::string describe_json_value(const Json& j);

bool parse_color(std::string_view text, Color& out);  // "#..", names
std::span<const std::string_view> color_names();

// Value at a JSON pointer ("/entities/0/name") or nullptr.
const Json* json_at(const Json& root, std::string_view pointer);
// Deep merge `patch` into `target` (objects merge recursively; anything else replaces).
void json_merge(Json& target, const Json& patch);

}  // namespace fa
