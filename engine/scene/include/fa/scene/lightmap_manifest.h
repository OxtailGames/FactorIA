// The files of a baked lightmap (M73.4a, docs/design/ARCHITECTURE_RENDERING_LIGHTING.md, "Lightmaps"): one JSON manifest next to the scene
// (`SceneSettings.lightmaps` names it, e.g. "scenes/level.lightmap.json") and the Radiance .hdr page images it lists. The manifest says which
// entity is lit by which rectangle of which page; the renderer reads both with the scene and reloads them when a file changes, the
// `lightmap.bake` command writes them. GPU-free: parsing and checking only.
//
//   {
//     "version": 1,                         // the format (kLightmapManifestVersion)
//     "uvVersion": 1,                       // kLightmapUvVersion of the UVs the bake used
//     "settingsHash": "9f3a...",            // a hash of the bake settings and lights (the editor says "stale" when it changes)
//     "pages": [ { "file": "scenes/level.lightmap.0.hdr", "width": 512, "height": 512 } ],   // project-relative paths
//     "entities": [
//       { "id": "e7a1c2",                   // the entity's stable id (EntityInfo.id)
//         "mesh": "models/room.glb",        // MeshRenderer.mesh at bake time
//         "uv": "generated",                // "gltf" (TEXCOORD_1 of the file) or "generated" (generate_lightmap_uv)
//         "meshHash": "00ff...",            // a hash of the mesh's lightmap geometry: another one means the mesh changed since the bake
//         "page": 0,                        // the index in "pages"
//         "scaleOffset": [0.25, 0.25, 0.5, 0.0] }   // sx, sy, ox, oy: the page uv of a lightmap uv is uv * (sx, sy) + (ox, oy)
//     ]
//   }
//
// Orientation: a page is a Radiance .hdr whose first row is the top of the image, and page uv (0, 0) is the top-left, so the baker's row 0
// (v = 0) is the file's first row. Texel values are what a white diffuse surface shows (irradiance / pi, lightmap_bake.h), linear.
#pragma once

#include <cstdint>
#include <string>
#include <unordered_map>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

inline constexpr int kLightmapManifestVersion = 1;
inline constexpr int kLightmapMaxPages = 256;
inline constexpr int kLightmapMaxPageSize = 8192;  // texels per side of a page

struct LightmapPage {
    std::string file;  // project-relative path of the .hdr
    int width = 0, height = 0;
};

struct LightmapEntry {
    std::string id;    // EntityInfo.id
    std::string mesh;  // MeshRenderer.mesh when it was baked
    std::string uv;    // "gltf" or "generated"
    std::string meshHash;      // 16 hex digits; "" = not checked
    std::string settingsHash;  // of the bake that wrote it; informative
    int page = 0;
    float scaleOffset[4] = {1, 1, 0, 0};  // sx, sy, ox, oy
};

struct LightmapManifest {
    int version = kLightmapManifestVersion;
    int uvVersion = 0;
    std::string settingsHash;
    std::vector<LightmapPage> pages;
    std::vector<LightmapEntry> entities;
    // The entry of an entity, or nullptr. Built by parse_lightmap_manifest (a manifest made by hand calls index()).
    const LightmapEntry* find(const std::string& id) const;
    void index();

private:
    std::unordered_map<std::string, std::size_t> byId_;
};

// Reads and checks a manifest. `file` names it in the errors, which carry the JSON pointer ("/entities/3/page"), what is wrong, how to fix it,
// and a "did you mean" for a misspelled key. Checks: object, version, known keys, page list (sizes, a .hdr file), per entity the id (not
// empty, not twice), the page index, a finite scaleOffset that stays inside the page uv range 0..1 (+ a tiny tolerance), the uv kind and the
// hash spelling. A uvVersion other than kLightmapUvVersion is an error that says to bake again.
Result<LightmapManifest> parse_lightmap_manifest(const Json& json, const std::string& file);
// The canonical JSON (keys in the order above, floats rounded to 6 digits so the file is the same on every machine).
Json lightmap_manifest_to_json(const LightmapManifest& manifest);
// Reads `path` (a project path, through fa::fs) and parses it.
Result<LightmapManifest> load_lightmap_manifest(const std::string& path);

// The texel density of the bake for one MeshRenderer: `baseTexelsPerMeter` (the scene's density; kLightmapDefaultTexelsPerMeter) times
// MeshRenderer.lightmapScale. 0 when the scale is 0, negative or not finite: the mesh is not in the lightmap. The scale is capped at the
// field's own maximum (100).
inline constexpr double kLightmapDefaultTexelsPerMeter = 16.0;
double lightmap_texels_per_meter(double baseTexelsPerMeter, float lightmapScale);

// 16 lower-case hex digits.
std::string lightmap_hash_hex(std::uint64_t hash);
// FNV-1a 64 over bytes, to chain: start from kLightmapHashSeed.
inline constexpr std::uint64_t kLightmapHashSeed = 0xcbf29ce484222325ull;
std::uint64_t lightmap_hash_bytes(std::uint64_t h, const void* data, std::size_t size);

}  // namespace fa
