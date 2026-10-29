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

#include <array>
#include <functional>
#include <memory>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

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

// Effective import settings of `path`: the built-in defaults of its kind (texture {compression "auto", atlas ""}; audio
// {stream "auto", normalize false, targetLufs -16, convert "none"}; {} for the other kinds), then manifest
// "defaults.<kind>", then the entry's "import" (each later one overrides keys of the earlier).
Json import_settings(std::string_view path);
// The same, from a manifest document you hold (`factoria export` reads the project's file itself: the VFS root is not
// necessarily the project then).
Json import_settings(const Json& manifest, std::string_view path);

// Where `factoria export` packed a texture: the atlas image and the pixel rectangle of the texture in it (the entry's
// `packed`, written to the shipped manifest only). `atlas` is empty when the texture is not packed.
struct PackedTexture {
    std::string atlas;
    int x = 0, y = 0, w = 0, h = 0;
};
PackedTexture packed_texture(std::string_view path);

// The `sheet` entry of an image (a sprite sheet: grid, frames, named clips), parsed. Pivots are [x, y] in 0..1 measured from
// the TOP-LEFT of a frame (image coordinates, like Sprite.region); Sprite.pivot is measured from the bottom-left.
struct SheetClip {
    std::string name;
    int firstFrame = 0;
    int lastFrame = 0;
    float fps = 10.0f;
    bool loop = true;
    std::optional<std::array<float, 2>> pivot;  // this clip's own pivot (top-left based), else the sheet's
};
struct Sheet {
    int columns = 1;
    int rows = 1;
    int frameWidth = 0;   // 0 = not recorded: the cell is the image divided by the grid
    int frameHeight = 0;
    int frames = 0;       // 0 = not recorded: columns * rows
    int padding = 0;      // transparent gutter around every cell, in pixels
    std::optional<std::array<float, 2>> pivot;  // top-left based
    std::vector<SheetClip> clips;
    const SheetClip* find(std::string_view name) const;
    std::vector<std::string> clip_names() const;
};
// The parsed `sheet` entry of `path`, or null when the image has none (or it is malformed). Cached until assets.json changes;
// a stat of the file per call, so a caller that asks every frame keeps its own copy for the frame.
std::shared_ptr<const Sheet> sheet(std::string_view path);
// Parses one `sheet` object (what the tools write); null when it is not an object with integer columns and rows.
std::shared_ptr<const Sheet> parse_sheet(const Json& sheetEntry);

// Edits (tools; the manifest must be writable, so desktop only). Loads the file from disk (a missing one starts as
// {"format": ...}), runs `edit` on the entry of `path` (an object, created when missing; an entry left empty is
// removed), and writes the file back with 2-space indent. The entries stay in the order of the file; they are kept
// sorted by path only when they were sorted before the edit (new entries are appended to a hand-ordered file). Fails on
// an unreadable or invalid file instead of overwriting it.
Result<void> update_entry(std::string_view path, const std::function<void(Json& entry)>& edit);
// The same for the whole document (style, defaults); `edit` receives the parsed object.
Result<void> update_manifest(const std::function<void(Json& doc)>& edit);

// Today's date as YYYY-MM-DD (local time), for provenance records. Tools only: never call it from simulation code.
std::string today();

}  // namespace fa::assets
