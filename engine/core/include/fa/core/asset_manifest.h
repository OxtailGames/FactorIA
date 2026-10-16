// Per-asset import settings and provenance: the optional `assets.json` at the project root
// (schemas/assets.schema.json).
//
//   {"format": "factoria.assets/1",
//    "style":    {"prompt": "...", "palette": [...], "references": [...]},      // assets.generate_image house style
//    "defaults": {"texture": {...}, "audio": {...}},                           // import settings per kind
//    "assets":   {"assets/hero.png": {"import": {...}, "provenance": {...}, "sheet": {...}, "analysis": {...}}}}
//
// The runtime reads import settings (audio streaming and loudness); the tools write provenance and settings through the
// assets.* commands. Paths are project-relative with forward slashes ("assets/hero.png").
#pragma once

#include <functional>
#include <string>
#include <string_view>

#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa::assets {

inline constexpr const char* kManifestFile = "assets.json";
inline constexpr const char* kManifestFormat = "factoria.assets/1";

enum class AssetKind { Texture, Audio, Model, Font, Video, Other };
AssetKind kind_of(std::string_view path);  // by extension: .png/.jpg/... texture, .wav/.ogg/.mp3/.qoa audio, ...
const char* kind_name(AssetKind kind);     // "texture" | "audio" | "model" | "font" | "video" | "other"

// The manifest as loaded through fa::fs, re-read when the file changes on disk (cheap to call every frame). A missing
// file gives {"format": kManifestFormat}; an unreadable or invalid one logs one warning and gives the same.
Json manifest();

// The entry of `path` (normalized), or an empty object.
Json entry(std::string_view path);

// Built-in import settings of a kind: texture {compression "auto", atlas ""}; audio {stream "auto", normalize false,
// targetLufs -16, convert "none"}; {} for the other kinds.
Json builtin_import_defaults(AssetKind kind);

// Effective import settings of `path`: the built-in defaults of its kind, then manifest "defaults.<kind>", then the
// entry's "import" (each later one overrides keys of the earlier).
Json import_settings(std::string_view path);

// Edits (tools; the manifest must be writable, so desktop only). Loads the file from disk (a missing one starts as
// {"format": ...}), runs `edit` on the entry of `path` (an object, created when missing; an entry left empty is
// removed), and writes the file back with 2-space indent and the entries sorted by path. Fails on an unreadable or
// invalid file instead of overwriting it.
Result<void> update_entry(std::string_view path, const std::function<void(Json& entry)>& edit);
// The same for the whole document (style, defaults); `edit` receives the parsed object.
Result<void> update_manifest(const std::function<void(Json& doc)>& edit);

// Today's date as YYYY-MM-DD (local time), for provenance records. Tools only: never call it from simulation code.
std::string today();

}  // namespace fa::assets
