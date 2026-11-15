// The ASCII level import shared by the runtime and fa_authoring: engine tools only, not a public API (like engine_impl.h).
//
// The runtime keeps what a running game needs: scene.place_ascii (tilemap.generate's `place`), read_ascii_sample (WFC) and the
// import itself (apply_import). fa_authoring's scene.import_ascii (which can also write a scene file) and scene.ascii_edit are
// built on the same rows/legend parsing, declared here, so the two never drift apart.
//
// Conventions (kept in sync with fa_render's tilemap drawing and fa_physics' tilemap collision, see fa/scene/tilemap.h): the
// Tilemap entity's position is the map's TOP-LEFT corner, +Y up, row 0 = top row. Objects are ordinary top-level entities tagged
// "tilemap:<tilemap id>" so a re-import can replace them.
#pragma once

#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/runtime/internal/engine_impl.h"
#include "fa/scene/world.h"

namespace fa::ascii_level {

constexpr const char* kTagPrefix = "tilemap:";

// Throws CommandError("invalid_argument", message, hint).
[[noreturn]] void bad_arg(const std::string& message, const std::string& hint = {});

// `v` as an int when it is an integral number (not a string, not 1.5).
bool as_int(const Json& v, int& out);
// One UTF-8 character per entry.
std::vector<std::string> split_glyphs(const std::string& s);
std::string show_glyph(const std::string& g);
std::string show_glyph_list(const std::vector<std::string>& glyphs);
bool is_default_empty(const std::string& g);  // "." and " " are empty cells unless the legend defines them

// ------------------------------------------------------------------------------------------------------------ rows
struct Grid {
    std::size_t width = 0, height = 0;
    std::vector<std::vector<std::string>> glyphs;  // [row][col]
};

// `rows` of the arguments: a non-empty array of strings of the same length. Throws CommandError naming the row.
Grid parse_rows(const Json& a);

// ---------------------------------------------------------------------------------------------------------- legend
struct LegendEntry {
    std::string glyph;
    bool hasTile = false;
    int tile = -1;
    std::string prefab;  // "" = no object
    std::string id;      // fixed id ("" = generated)
    Json overrides = Json::object();
    Vec2 offset{0, 0};
    std::string idBase;   // prefix of generated ids
    int uses = 0;         // cells in rows using this entry
    bool shared = false;  // comes from `legendFrom` only (its unused entries are not warned about)
};

std::vector<LegendEntry> parse_legend(const Json& legend);
// `legend` merged over the file named by `legendFrom` (a project-relative JSON file with a legend, or {"legend": {...}}).
Json merged_legend(const Json& a);

// ---------------------------------------------------------------------------------------------------------- cells
struct Cell {
    int col = 0, row = 0;
    const LegendEntry* entry = nullptr;  // null = empty cell
    int tile = -1;
    std::string id;  // final id of the spawned object (cells with a prefab)
    bool has_object() const { return entry && !entry->prefab.empty(); }
};

// Row-major cells. Every glyph must be in the legend (or be '.' / ' '); all unknown glyphs are reported together.
std::vector<Cell> resolve_cells(const Grid& grid, std::vector<LegendEntry>& legend);

// ------------------------------------------------------------------------------------------------------- request
struct Request {
    std::string mapId;
    bool replace = true;
    // Of scene.import_ascii only (fa_authoring fills them; scene.place_ascii never does):
    bool save = false;
    // File mode: edit the scene FILE `path` in a scratch World instead of the running world.
    std::string path;               // normalized, project-relative; "" = edit the running world
    std::string from;               // scene file to start from instead of `path` ("" = `path` itself)
    bool dryRun = false;            // file mode: write nothing, return the scene JSON
    Json edits = Json::object();    // file mode: {entity id: {Component: {field: value}}}
    Json tilemap = Json::object();  // Tilemap fields to apply
    bool place = false;             // position and/or anchor given
    Vec3 position{0, 0, 0};
    bool hasZ = false;
    std::string anchor = "top-left";
};

// entity, replace, tilemap, position, anchor. Does not read `save`, `path`, `from`, `edits` or `dryRun`.
Request parse_request(const Engine::Impl& I, const Json& a);

// Imports the (already validated) map into `W`: the running world or a scratch World. `flushNow`: destroyed entities are
// removed at once (false only while the running game is inside a frame, where the engine flushes at the end of it).
// Returns the result object without the `saved`/`path` keys, which depend on where the world comes from.
Json apply_import(World& W, bool flushNow, const Request& q, const Grid& grid, std::vector<LegendEntry>& legend,
                  std::vector<Cell>& cells);

// The input schema of scene.import_ascii (scene.place_ascii derives its own from it).
Json import_ascii_schema();

}  // namespace fa::ascii_level
