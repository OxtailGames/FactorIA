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
std::string dump_json(const Json& j);
Result<void> save_json_file(std::string_view path, const Json& j);

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
