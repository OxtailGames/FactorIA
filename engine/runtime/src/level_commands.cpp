// Level authoring commands. Today: scene.import_ascii (ASCII map -> Tilemap + the objects standing on it).
//
// Conventions (kept in sync with fa_render's tilemap drawing and fa_physics' tilemap collision, see
// fa/scene/tilemap.h): the Tilemap entity's position is the map's TOP-LEFT corner, +Y up, row 0 = top row, so the centre of
// cell (col, row) is ((col + 0.5) * tw, -(row + 0.5) * th) in the Tilemap's local space; the Tilemap's world matrix maps it
// to the world. Objects are ordinary top-level entities tagged "tilemap:<tilemap id>" so a re-import can replace them.
//
// Flow of the command: everything that can be checked from the arguments alone is checked first (rows, legend, glyphs,
// prefab files, ids), then the world is changed; failures after that point (a bad `tilemap` value, a prefab that does not
// load, a tile outside the tileset) restore the tilemap and remove what was spawned, so a failed call changes nothing.
//
// Two targets share that code (apply_import): the RUNNING world (no `path`), or, with `path`, a scratch World loaded from
// the scene file and written back to it (import_into_scene_file), which leaves the running engine untouched.
#include <algorithm>
#include <array>
#include <functional>
#include <cctype>
#include <cmath>
#include <map>
#include <set>

#include "engine_impl.h"
#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/core/strings.h"
#include "fa/core/utf8.h"
#include "fa/scene/serialize.h"
#include "fa/scene/tilemap.h"

namespace fa {

namespace {

constexpr const char* kTagPrefix = "tilemap:";

[[noreturn]] void bad_arg(const std::string& message, const std::string& hint = {}) {
    throw CommandError("invalid_argument", message, hint);
}

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

bool as_int(const Json& j, int& out) {
    if (j.is_number_integer() || j.is_number_unsigned()) {
        long long v = j.get<long long>();
        if (v < -1000000000LL || v > 2147483647LL) return false;
        out = int(v);
        return true;
    }
    if (j.is_number_float()) {
        double d = j.get<double>();
        if (d == std::floor(d) && d >= -1e9 && d <= 2147483647.0) {
            out = int(d);
            return true;
        }
    }
    return false;
}

// One map character = one Unicode code point (so "█" or "é" work as glyphs). Returns the UTF-8 bytes of each.
std::vector<std::string> split_glyphs(const std::string& s) {
    std::vector<std::string> out;
    for (std::size_t i = 0; i < s.size();) {
        const std::size_t start = i;
        utf8_next(s, i);
        out.push_back(s.substr(start, i - start));
    }
    return out;
}

std::string show_glyph(const std::string& g) {
    if (g == " ") return "' ' (space)";
    if (g == "\t") return "'\\t' (tab)";
    return "'" + g + "'";
}

std::string show_glyph_list(const std::vector<std::string>& glyphs) {
    std::string s;
    for (std::size_t i = 0; i < glyphs.size(); ++i) s += (i ? ", " : "") + show_glyph(glyphs[i]);
    return s;
}

std::string cell_text(int col, int row) { return "row " + std::to_string(row) + ", column " + std::to_string(col); }

bool is_default_empty(const std::string& g) { return g == "." || g == " "; }

std::vector<std::string> project_prefabs() {
    std::vector<std::string> out;
    for (const std::string& f : fs::list("prefabs", true, ".json"))
        if (ends_with(f, ".prefab.json")) out.push_back(f);
    return out;
}

// "prefabs/enemies/Spiky-Crawler.prefab.json" -> "spiky_crawler" (prefix of generated ids).
std::string id_base_for(const std::string& prefabPath) {
    std::string name = fs::filename(prefabPath);
    for (const char* ext : {".prefab.json", ".json"})
        if (ends_with(name, ext)) {
            name.resize(name.size() - std::string(ext).size());
            break;
        }
    std::string out;
    for (char ch : to_lower(name)) out += (std::isalnum(static_cast<unsigned char>(ch)) || ch == '_') ? ch : '_';
    return out.empty() ? "object" : out;
}

// ----------------------------------------------------------------------------------------------------------- rows
struct Grid {
    std::size_t width = 0, height = 0;
    std::vector<std::vector<std::string>> glyphs;  // [row][col]
};

Grid parse_rows(const Json& a) {
    if (!a.contains("rows") || !a["rows"].is_array() || a["rows"].empty())
        bad_arg("'rows' must be a non-empty array of strings (row 0 is the TOP row)",
                "Example: \"rows\": [\"..o..\", \"P...#\", \"#####\"] with a legend like {\"#\": 0, \"o\": "
                "{\"prefab\": \"prefabs/coin.prefab.json\"}, \"P\": {\"prefab\": \"prefabs/player.prefab.json\", \"id\": \"player\"}}.");
    Grid g;
    for (std::size_t r = 0; r < a["rows"].size(); ++r) {
        if (!a["rows"][r].is_string())
            bad_arg("rows[" + std::to_string(r) + "] must be a string, got " + describe_json_value(a["rows"][r]),
                    "Each row is one string with one character per tile, e.g. \"#..o..#\".");
        g.glyphs.push_back(split_glyphs(a["rows"][r].get<std::string>()));
    }
    g.width = g.glyphs[0].size();
    g.height = g.glyphs.size();

    std::vector<std::size_t> ragged;
    for (std::size_t r = 1; r < g.height; ++r)
        if (g.glyphs[r].size() != g.width) ragged.push_back(r);
    if (!ragged.empty()) {
        std::string msg = "rows must all have the same length, but row 0 has " + std::to_string(g.width) + " columns and ";
        for (std::size_t i = 0; i < ragged.size() && i < 5; ++i)
            msg += (i ? ", row " : "row ") + std::to_string(ragged[i]) + " has " + std::to_string(g.glyphs[ragged[i]].size());
        if (ragged.size() > 5) msg += ", ... (" + std::to_string(ragged.size() - 5) + " more rows)";
        bad_arg(msg + " (rows are numbered from 0 at the top)",
                "Pad short rows with '.' (empty) so every row has " + std::to_string(g.width) +
                    " characters; check that no editor trimmed trailing spaces.");
    }
    if (g.width == 0) bad_arg("row 0 is empty, so the map has no columns", "Each row needs at least one character, e.g. \".\" for an empty tile.");
    if (g.width > 65536 || g.height > 65536)
        bad_arg("the map is " + std::to_string(g.width) + " x " + std::to_string(g.height) +
                    " tiles but a Tilemap holds at most 65536 per side",
                "Split the level into several Tilemaps (call scene.import_ascii with another 'entity' id).");
    return g;
}

// ----------------------------------------------------------------------------------------------------------- legend
struct LegendEntry {
    std::string glyph;
    bool hasTile = false;
    int tile = -1;
    std::string prefab;  // "" = no object
    std::string id;      // fixed id ("" = generated)
    Json overrides = Json::object();
    Vec2 offset{0, 0};
    std::string idBase;  // prefix of generated ids
    int uses = 0;        // cells in rows using this entry
    bool shared = false; // comes from `legendFrom` only (its unused entries are not warned about)
};

void parse_tile(LegendEntry& e, const Json& v, const std::string& what) {
    int t = 0;
    if (!as_int(v, t) || t < -1)
        bad_arg(what + " must be an integer tile index >= -1, got " + describe_json_value(v),
                "Tile indices count from 0 in the tileset (left-to-right, top-to-bottom); -1 means empty. To flip or rotate a tile "
                "use the object form: {\"tile\": 3, \"rotate\": 90, \"flipX\": true}.");
    e.hasTile = true;
    e.tile = t;
}

void parse_prefab(LegendEntry& e, const Json& v, const std::string& where) {
    if (!v.is_string() || v.get<std::string>().empty())
        bad_arg(where + ".prefab must be a project-relative path string, got " + describe_json_value(v),
                "Example: \"prefab\": \"prefabs/coin.prefab.json\".");
    auto norm = fs::normalize_checked(v.get<std::string>());
    if (!norm.ok()) bad_arg(where + ".prefab: " + norm.error().message, norm.error().hint);
    const std::string& path = norm.value();
    if (!fs::exists(path)) {
        std::vector<std::string> prefabs = project_prefabs();
        throw CommandError(
            "not_found", where + ".prefab '" + path + "' does not exist. " + did_you_mean(path, prefabs),
            prefabs.empty() ? "There are no prefabs yet: create prefabs/<name>.prefab.json "
                              "({\"format\":\"factoria.prefab/1\",\"entity\":{...}}) first."
                            : "Prefabs live in prefabs/*.prefab.json; use project.info to list them.");
    }
    e.prefab = path;
    e.idBase = id_base_for(path);
}

void parse_object_entry(LegendEntry& e, const Json& v, const std::string& where) {
    static const std::vector<std::string> kKeys = {"tile", "flipX", "flipY", "rotate", "prefab", "id", "overrides", "offset"};
    for (auto k = v.begin(); k != v.end(); ++k)
        if (std::find(kKeys.begin(), kKeys.end(), k.key()) == kKeys.end())
            bad_arg(where + " has the unknown key '" + k.key() + "'. " + did_you_mean(k.key(), kKeys),
                    "A legend object looks like {\"tile\": 0}, {\"tile\": 3, \"rotate\": 90, \"flipX\": true} or {\"prefab\": \"prefabs/coin.prefab.json\", "
                    "\"id\": \"player\", \"overrides\": {...}, \"offset\": [0, 4]}.");
    if (v.contains("tile")) parse_tile(e, v["tile"], where + ".tile");
    // Flip and rotate flags of the tile (fa/scene/tilemap.h): the tile is turned `rotate` degrees clockwise, then mirrored.
    if (v.contains("flipX") || v.contains("flipY") || v.contains("rotate")) {
        if (!e.hasTile || e.tile < 0)
            bad_arg(where + " has flipX / flipY / rotate but no tile to turn", "Add \"tile\": <index>, e.g. {\"tile\": 3, \"rotate\": 90}.");
        for (const char* k : {"flipX", "flipY"})
            if (v.contains(k) && !v[k].is_boolean())
                bad_arg(where + "." + k + " must be true or false, got " + describe_json_value(v[k]), "Example: \"" + std::string(k) + "\": true.");
        int turns = 0;
        if (v.contains("rotate")) {
            int deg = 0;
            if (!as_int(v["rotate"], deg) || deg % 90 != 0)
                bad_arg(where + ".rotate must be 0, 90, 180 or 270 (degrees clockwise), got " + describe_json_value(v["rotate"]),
                        "Example: \"rotate\": 90. Any multiple of 90 is accepted, negative turns counter-clockwise.");
            turns = deg / 90;
        }
        e.tile = make_tile(tile_index(e.tile), turns, v.value("flipX", false), v.value("flipY", false));
    }
    if (v.contains("prefab")) parse_prefab(e, v["prefab"], where);
    if (e.prefab.empty()) {
        for (const char* k : {"id", "overrides", "offset"})
            if (v.contains(k))
                bad_arg(where + " has '" + k + "' but no 'prefab'; '" + k + "' only applies to a spawned object",
                        "Add \"prefab\": \"prefabs/x.prefab.json\", or remove '" + std::string(k) + "'.");
        if (!e.hasTile)
            bad_arg(where + " has neither \"tile\" nor \"prefab\", so it would do nothing",
                    "Add \"tile\": <index> to draw a tile and/or \"prefab\": \"prefabs/x.prefab.json\" to spawn an object.");
    }
    if (v.contains("id")) {
        if (!v["id"].is_string() || v["id"].get<std::string>().empty())
            bad_arg(where + ".id must be a non-empty string, got " + describe_json_value(v["id"]),
                    "Example: \"id\": \"player\". Omit it to get generated ids (coin_1, coin_2...).");
        e.id = v["id"].get<std::string>();
    }
    if (v.contains("overrides")) {
        const Json& ov = v["overrides"];
        if (!ov.is_object())
            bad_arg(where + ".overrides must be an object of component patches, got " + describe_json_value(ov),
                    "Example: \"overrides\": {\"Script\": {\"props\": {\"speed\": 60}}, \"Sprite\": {\"color\": \"red\"}}.");
        for (auto o = ov.begin(); o != ov.end(); ++o)
            if (!o.value().is_object())
                bad_arg(where + ".overrides." + o.key() + " must be an object of field values, got " + describe_json_value(o.value()),
                        "Example: \"overrides\": {\"" + o.key() + "\": {\"fieldName\": value}}. Use api.components for the fields.");
        e.overrides = ov;
    }
    if (v.contains("offset")) {
        const Json& o = v["offset"];
        if (!o.is_array() || o.size() != 2 || !o[0].is_number() || !o[1].is_number())
            bad_arg(where + ".offset must be [dx, dy] in world units, got " + describe_json_value(o),
                    "Example: \"offset\": [0, -4] moves the object 4 units down from the cell centre.");
        e.offset = {o[0].get<float>(), o[1].get<float>()};
    }
}

std::vector<LegendEntry> parse_legend(const Json& legend) {
    if (!legend.is_object())
        bad_arg("'legend' must be an object mapping one-character glyphs to a tile index or an object, got " +
                    describe_json_value(legend),
                "Example: {\"#\": 0, \"o\": {\"prefab\": \"prefabs/coin.prefab.json\"}, "
                "\"P\": {\"prefab\": \"prefabs/player.prefab.json\", \"id\": \"player\"}}");
    std::vector<LegendEntry> out;
    for (auto it = legend.begin(); it != legend.end(); ++it) {
        LegendEntry e;
        std::vector<std::string> glyphs = split_glyphs(it.key());
        if (glyphs.size() != 1)
            bad_arg("legend key '" + it.key() + "' must be exactly one character, but it has " + std::to_string(glyphs.size()),
                    "The map has one character per tile, so legend keys are single characters such as \"#\", \"o\" or \"P\".");
        e.glyph = glyphs[0];
        const std::string where = "legend['" + e.glyph + "']";
        const Json& v = it.value();
        if (int t = 0; as_int(v, t)) {
            parse_tile(e, v, where);
        } else if (v.is_object()) {
            parse_object_entry(e, v, where);
        } else {
            bad_arg(where + " must be a tile index (integer) or an object "
                            "{\"tile\"?, \"prefab\"?, \"id\"?, \"overrides\"?, \"offset\"?}, got " + describe_json_value(v),
                    v.is_string() ? "For an object write {\"prefab\": \"" + v.get<std::string>() +
                                        "\"}; for a tile write its number, e.g. \"" + e.glyph + "\": 0."
                                  : "Examples: \"#\": 0   or   \"o\": {\"prefab\": \"prefabs/coin.prefab.json\"}.");
        }
        out.push_back(std::move(e));
    }
    return out;
}

// ----------------------------------------------------------------------------------------------------------- cells
struct Cell {
    int col = 0, row = 0;
    const LegendEntry* entry = nullptr;  // null = empty cell
    int tile = -1;
    std::string id;  // final id of the spawned object (cells with a prefab)
    bool has_object() const { return entry && !entry->prefab.empty(); }
};

// Row-major cells. Every glyph must be in the legend (or be '.' / ' '); all unknown glyphs are reported together.
std::vector<Cell> resolve_cells(const Grid& grid, std::vector<LegendEntry>& legend) {
    std::map<std::string, LegendEntry*> byGlyph;
    for (LegendEntry& e : legend) byGlyph[e.glyph] = &e;

    struct Unknown {
        int row = 0, col = 0, count = 0;
    };
    std::map<std::string, Unknown> unknown;
    std::vector<std::string> unknownOrder;
    std::vector<Cell> cells(grid.width * grid.height);
    for (std::size_t r = 0; r < grid.height; ++r) {
        for (std::size_t c = 0; c < grid.width; ++c) {
            Cell& cell = cells[r * grid.width + c];
            cell.col = int(c);
            cell.row = int(r);
            const std::string& g = grid.glyphs[r][c];
            auto it = byGlyph.find(g);
            if (it == byGlyph.end()) {
                if (is_default_empty(g)) continue;
                auto [u, fresh] = unknown.try_emplace(g);
                if (fresh) {
                    u->second.row = int(r);
                    u->second.col = int(c);
                    unknownOrder.push_back(g);
                }
                ++u->second.count;
                continue;
            }
            ++it->second->uses;
            cell.entry = it->second;
            cell.tile = it->second->hasTile ? it->second->tile : -1;
        }
    }
    if (unknown.empty()) return cells;

    std::vector<std::string> known;
    for (const LegendEntry& e : legend) known.push_back(e.glyph);
    std::string msg = unknownOrder.size() == 1 ? "Unknown glyph " : "Unknown glyphs ";
    for (std::size_t i = 0; i < unknownOrder.size() && i < 5; ++i) {
        const std::string& g = unknownOrder[i];
        const Unknown& u = unknown[g];
        msg += (i ? "; " : "") + show_glyph(g) + " first at " + cell_text(u.col, u.row) +
               (u.count > 1 ? " (" + std::to_string(u.count) + " times)" : "");
        // The same letter in another case is the usual typo.
        for (const std::string& k : known)
            if (iequals(k, g)) msg += " (Did you mean " + show_glyph(k) + "?)";
    }
    if (unknownOrder.size() > 5) msg += "; ... (" + std::to_string(unknownOrder.size() - 5) + " more)";
    msg += ". The legend defines " + (known.empty() ? std::string("nothing") : show_glyph_list(known)) +
           "; '.' and ' ' are empty unless the legend says otherwise (rows are numbered from 0 at the top, columns from 0 at the left)";
    const std::string& g0 = unknownOrder[0];
    bad_arg(msg, "Add the glyph to the legend, e.g. \"" + g0 + "\": 0 (a tile index) or \"" + g0 +
                     "\": {\"prefab\": \"prefabs/<name>.prefab.json\"}, or fix the character in rows.");
}

// --------------------------------------------------------------------------------------------------------- request
struct Request {
    std::string mapId;
    bool replace = true;
    bool save = false;
    // File mode: edit the scene FILE `path` in a scratch World instead of the running world (see import_into_scene_file).
    std::string path;        // normalized, project-relative; "" = edit the running world
    std::string from;        // scene file to start from instead of `path` ("" = `path` itself)
    bool dryRun = false;     // file mode: write nothing, return the scene JSON
    Json edits = Json::object();     // file mode: {entity id: {Component: {field: value}}}, applied like scene.set_component
    Json tilemap = Json::object();  // Tilemap fields to apply
    bool place = false;             // position and/or anchor given
    Vec3 position{0, 0, 0};
    bool hasZ = false;
    std::string anchor = "top-left";
};

// Every *.scene.json of the project (scenes/, but also e.g. a levels/base.scene.json), for "did you mean" suggestions.
std::vector<std::string> scene_files() {
    std::vector<std::string> out;
    for (const std::string& f : fs::list("", true, ".json"))
        if (ends_with(f, ".scene.json") && !starts_with(f, ".factoria/") && !starts_with(f, ".git/")) out.push_back(f);
    return out;
}

// `path` / `from`: a project-relative scene file. Absolute paths are refused (the project folder is the sandbox of the
// file mode); the file that is WRITTEN also has to be somewhere commands may write (fs::check_writable).
std::string scene_file_arg(const Json& v, const char* key, bool forWrite) {
    const std::string k = key;
    if (!v.is_string() || v.get<std::string>().empty())
        bad_arg("'" + k + "' must be a project-relative scene file path, got " + describe_json_value(v),
                "Example: \"" + k + "\": \"scenes/level1.scene.json\".");
    const std::string raw = v.get<std::string>();
    if (fs::is_absolute(raw))
        bad_arg("'" + k + "' must be project-relative, but '" + raw + "' is an absolute path",
                "Use the path inside the project, e.g. \"" + k + "\": \"scenes/level1.scene.json\".");
    auto norm = fs::normalize_checked(raw);
    if (!norm.ok()) bad_arg("'" + k + "': " + norm.error().message, norm.error().hint);
    const std::string& path = norm.value();
    if (path.empty() || fs::is_directory(path))
        bad_arg("'" + k + "' is '" + raw + "', which is a folder, not a scene file", "Name the file, e.g. \"scenes/level1.scene.json\".");
    if (forWrite)
        if (auto w = fs::check_writable(path); !w.ok()) bad_arg("'" + k + "': " + w.error().message, w.error().hint);
    return path;
}

Request parse_request(const Engine::Impl& I, const Json& a) {
    Request q;
    q.mapId = a.value("entity", std::string("tilemap"));
    if (q.mapId.empty()) bad_arg("'entity' must be a non-empty entity id", "Default: \"tilemap\".");
    q.replace = a.value("replace", true);
    q.save = a.value("save", false);
    if (a.contains("tilemap") && a["tilemap"].is_object()) q.tilemap = a["tilemap"];
    for (const char* k : {"tiles", "width", "height"})
        if (q.tilemap.contains(k))
            bad_arg(std::string("'tilemap.") + k + "' cannot be set: the grid (tiles, width, height) comes from 'rows' and 'legend'",
                    "Remove it from 'tilemap'; pass only tileset, tileSize, projection, groundHeight, groundOffset, margin, spacing, columns, solidTiles, color, layer there.");
    if (a.contains("path")) q.path = scene_file_arg(a["path"], "path", true);
    if (a.contains("from")) q.from = scene_file_arg(a["from"], "from", false);
    q.dryRun = a.value("dryRun", false);
    if (a.contains("edits")) q.edits = a["edits"];  // {entity: {Component: {fields}}}: the input schema checked the shape
    if (q.path.empty()) {
        if (!q.edits.empty())
            bad_arg("'edits' needs 'path': it patches entities of the scene file 'path' before it is written",
                    "Add \"path\": \"scenes/<name>.scene.json\". To change the RUNNING world use scene.set_component.");
        if (!q.from.empty())
            bad_arg("'from' needs 'path': it is the scene file to start from when building the scene file 'path'",
                    "Add \"path\": \"scenes/<name>.scene.json\" (the file to write), or drop 'from'.");
        if (q.dryRun)
            bad_arg("'dryRun' needs 'path': it previews the scene file 'path' without writing it",
                    "Add \"path\": \"scenes/<name>.scene.json\". Without 'path' the import changes the RUNNING scene, which a dry run cannot undo.");
    }
    if (q.path.empty() && q.save) {
        if (I.currentScene.empty())
            bad_arg("'save' needs a current scene file but none is loaded",
                    "Pass \"path\": \"scenes/x.scene.json\" to build that scene file directly (the running world is not touched), "
                    "or load a scene with scene.load first.");
        // `factoria call` without --scene (or a fresh MCP session) runs the project's mainScene because nobody chose a scene.
        // A map file that says "save": true would overwrite it with a map meant for another level.
        if (I.implicitStartScene && !I.cfg.editorMode)
            throw CommandError(
                "unsafe_save",
                "'save' would overwrite '" + I.currentScene + "', the project's main scene, which is only running because no scene was chosen "
                "(no --scene, no scene.load); nothing was changed",
                "To build a scene file without touching the running game add \"path\": \"scenes/<name>.scene.json\" (and optionally "
                "\"from\": a base scene). To update the running scene on purpose, choose it first: factoria call ... --scene " +
                    I.currentScene + " (or scene.load), then repeat this call.");
    }
    if (a.contains("position")) {
        const Json& p = a["position"];
        bool ok = p.is_array() && (p.size() == 2 || p.size() == 3);
        for (std::size_t i = 0; ok && i < p.size(); ++i) ok = p[i].is_number();
        if (!ok) bad_arg("'position' must be [x, y] or [x, y, z] numbers, got " + describe_json_value(p), "Example: \"position\": [0, 0].");
        q.position = {p[0].get<float>(), p[1].get<float>(), p.size() == 3 ? p[2].get<float>() : 0.0f};
        q.hasZ = p.size() == 3;
    }
    q.anchor = a.value("anchor", std::string("top-left"));
    static const std::vector<std::string> kAnchors = {"top-left", "bottom-left", "center"};
    if (std::find(kAnchors.begin(), kAnchors.end(), q.anchor) == kAnchors.end())
        bad_arg("Unknown anchor '" + q.anchor + "'. " + did_you_mean(q.anchor, kAnchors),
                "anchor says which point of the map sits at 'position'.");
    q.place = a.contains("position") || a.contains("anchor");
    return q;
}

// Fixed ids first (unique among the cells, free in the world), then generated ones: <prefab name>_<n> in row-major
// order, skipping ids that are taken. `removable` = objects of this tilemap that the import is about to replace.
void assign_ids(World& W, std::vector<Cell>& cells, const std::string& mapId, const std::set<std::uint64_t>& removable) {
    auto taken_by_other = [&](const std::string& id) {
        Entity e = W.find_by_id(id);
        return e && !removable.count(e.bits());
    };
    std::map<std::string, const Cell*> fixedAt;
    for (Cell& cell : cells) {
        if (!cell.has_object() || cell.entry->id.empty()) continue;
        const LegendEntry& le = *cell.entry;
        if (auto f = fixedAt.find(le.id); f != fixedAt.end())
            bad_arg("id '" + le.id + "' is used by two cells: " + cell_text(f->second->col, f->second->row) + " and " +
                        cell_text(cell.col, cell.row) + " (glyph " + show_glyph(le.glyph) + ")",
                    "An \"id\" in the legend names ONE object (e.g. the player). For many objects drop the \"id\" (ids are "
                    "generated: " + le.idBase + "_1, " + le.idBase + "_2...), or use a separate glyph per object.");
        fixedAt[le.id] = &cell;
        if (le.id == mapId)
            bad_arg("id '" + le.id + "' (glyph " + show_glyph(le.glyph) + ") is the id of the tilemap entity itself",
                    "Choose another id for the object.");
        if (taken_by_other(le.id))
            bad_arg("id '" + le.id + "' (glyph " + show_glyph(le.glyph) + ", " + cell_text(cell.col, cell.row) +
                        ") is already used by another entity in the scene",
                    "Entity ids are unique. Destroy that entity (scene.destroy), use another id, or drop the \"id\" for a generated one.");
        cell.id = le.id;
    }
    std::map<std::string, int> counter;
    std::set<std::string> used;
    for (const auto& [id, cell] : fixedAt) used.insert(id);
    for (Cell& cell : cells) {
        if (!cell.has_object() || !cell.entry->id.empty()) continue;
        int& n = counter[cell.entry->idBase];
        if (n == 0) n = 1;
        std::string id;
        do id = cell.entry->idBase + "_" + std::to_string(n++);
        while (used.count(id) || id == mapId || taken_by_other(id));
        used.insert(id);
        cell.id = id;
    }
}

// ------------------------------------------------------------------------------------------------------- the world
struct Diagnostics {
    Json warnings = Json::array();
    Json notes = Json::array();
    std::set<std::string> seen;
    void warn(const std::string& w) {
        if (seen.insert(w).second) warnings.push_back(w);
    }
};

// `columns` 0 (the default) already follows the tileset image, so a new or updated tilemap needs nothing here, except
// that an explicit value left over from an earlier tileset/tileSize no longer describes the new image: it goes back to 0.
// Then range-checks the tile indices against the image.
void check_tileset(Tilemap& tm, const Request& q, const std::vector<LegendEntry>& legend, int tileCount, int maxTile,
                   Diagnostics& diag) {
    int staleColumns = 0;
    if (tm.columns != 0 && !q.tilemap.contains("columns") && (q.tilemap.contains("tileset") || q.tilemap.contains("tileSize"))) {
        staleColumns = tm.columns;
        tm.columns = 0;
    }
    if (tm.tileset.empty()) {
        if (tileCount > 0)
            diag.warn("Tilemap.tileset is empty, so the tiles are drawn without a tileset image. Pass \"tilemap\": "
                      "{\"tileset\": \"assets/tiles.png\", \"tileSize\": [32, 32]}.");
        return;
    }
    auto img = texture_size(tm.tileset);  // the size only: the file may be an export's .ktx2 twin
    if (!img.ok()) {
        diag.warn("Tilemap.tileset '" + tm.tileset + "' could not be loaded (" + img.error().message +
                  "), so tile indices were not range-checked.");
        return;
    }
    if (staleColumns != 0 && tileset_columns(tm, img->width) != staleColumns)
        diag.notes.push_back("Tilemap.columns was " + std::to_string(staleColumns) + " for the previous tileset or tileSize; it is now 0, so it is "
                             "derived from the tileset width (" + std::to_string(img->width) + " px / tileSize.x " +
                             std::to_string(int(tm.tileSize.x)) + " = " + std::to_string(tileset_columns(tm, img->width)) +
                             "). Pass tilemap.columns to override.");
    const int count = tileset_tile_count(tm, img->width, img->height);
    if (count <= 0 || maxTile < count) return;
    for (const LegendEntry& e : legend) {
        if (!e.hasTile || tile_index(e.tile) < count || e.uses == 0) continue;
        throw CommandError(
            "invalid_argument",
            "legend['" + e.glyph + "'] uses tile " + std::to_string(tile_index(e.tile)) + " but the tileset '" + tm.tileset + "' (" +
                std::to_string(img->width) + "x" + std::to_string(img->height) + " px) holds only " + std::to_string(count) +
                " tiles (indices 0.." + std::to_string(count - 1) + ") with tileSize [" + std::to_string(int(tm.tileSize.x)) +
                ", " + std::to_string(int(tm.tileSize.y)) + "] and columns " + std::to_string(tileset_columns(tm, img->width)),
            "Use an index in 0.." + std::to_string(count - 1) + ", or pass tilemap.tileSize / margin / spacing / columns that match the image.");
    }
}

// `position` is where the chosen `anchor` point of the map goes; the entity's own origin is the top-left corner (the top
// corner of an isometric map, whose anchors name the corners of the box around all its diamonds).
void place_tilemap(World& W, Entity mapE, const Tilemap& tm, const Request& q, std::size_t width, std::size_t height) {
    Vec3 pos = q.position;
    if (!q.hasZ) pos.z = W.world_position(mapE).z;
    const Mat4 m = W.world_matrix(mapE);
    const float sx = length(m.transform_dir({1, 0, 0})), sy = length(m.transform_dir({0, 1, 0}));
    const Rect box = tilemap_local_bounds(tm, TilemapSize{int(width), int(height)});
    Vec2 at{box.x, box.y + box.h};  // top-left of the box, in the entity's local space (y up)
    if (q.anchor == "bottom-left") at = {box.x, box.y};
    else if (q.anchor == "center") at = {box.x + box.w * 0.5f, box.y + box.h * 0.5f};
    pos.x -= at.x * sx;
    pos.y -= at.y * sy;
    W.set_world_position(mapE, pos);
}

// Imports the (already validated) map into `W`: the running world or a scratch World. `flushNow`: destroyed entities are
// removed at once (false only while the running game is inside a frame, where the engine flushes at the end of it).
// Returns the result object without the `saved`/`path` keys, which depend on where the world comes from.
Json apply_import(World& W, bool flushNow, const Request& q, const Grid& grid, std::vector<LegendEntry>& legend,
                  std::vector<Cell>& cells) {
    Entity mapE = W.find_by_id(q.mapId);
    if (mapE && !W.get<Tilemap>(mapE))
        bad_arg("Entity '" + q.mapId + "' exists but has no Tilemap component, so it cannot hold the level",
                "Pick another 'entity' id (the default is \"tilemap\"), or add the component first (scene.set_component).");

    // Objects of earlier imports into this tilemap: replaced when `replace` is true.
    const std::string tag = kTagPrefix + q.mapId;
    std::vector<Entity> previous;
    std::set<std::uint64_t> removable;
    if (q.replace)
        for (Entity e : W.find_by_tag(tag)) {
            previous.push_back(e);
            removable.insert(e.bits());
        }
    assign_ids(W, cells, q.mapId, removable);

    int tileCount = 0, maxTile = -1;
    for (const Cell& cell : cells)
        if (cell.tile >= 0) {
            ++tileCount;
            maxTile = std::max(maxTile, tile_index(cell.tile));
        }

    // ---- 2. Change the world. Any failure from here restores the tilemap and removes the new objects.
    bool created = false;
    Tilemap backupTm;
    Transform backupTf;
    if (!mapE) {
        mapE = W.create("Tilemap", q.mapId);
        W.add<Tilemap>(mapE);
        created = true;
    } else {
        backupTm = *W.get<Tilemap>(mapE);
        backupTf = *W.get<Transform>(mapE);
    }
    std::vector<Entity> spawnedEntities;
    auto rollback = [&]() {
        for (Entity e : spawnedEntities)
            if (W.alive(e)) W.destroy(e);
        if (created) {
            if (W.alive(mapE)) W.destroy(mapE);
        } else if (W.alive(mapE)) {
            *W.get<Tilemap>(mapE) = backupTm;
            *W.get<Transform>(mapE) = backupTf;
        }
        if (flushNow) W.flush();
    };

    Diagnostics diag;
    Json spawnedJson = Json::array(), removedJson = Json::array();
    try {
        // Tilemap fields (tileset, tileSize, solidTiles...): patch_component is all-or-nothing and its errors teach.
        if (!q.tilemap.empty()) {
            auto r = patch_component(W, mapE, World::type_of<Tilemap>(), q.tilemap);
            if (!r.ok())
                throw CommandError("invalid_argument", "'tilemap': " + r.error().message,
                                   r.error().hint.empty() ? "Valid fields: see api.components (Tilemap)." : r.error().hint);
        }
        Tilemap& tm = *W.get<Tilemap>(mapE);
        check_tileset(tm, q, legend, tileCount, maxTile, diag);
        if (created && tileCount > 0 && (!tm.solidTiles.is_array() || tm.solidTiles.empty()) && !q.tilemap.contains("solidTiles"))
            diag.warn("Tilemap.solidTiles is empty, so no tile collides. Pass \"tilemap\": {\"solidTiles\": [0, 1]} "
                      "for the tile indices that block movement.");

        std::vector<int> tiles(cells.size());
        for (std::size_t i = 0; i < cells.size(); ++i) tiles[i] = cells[i].tile;
        set_tilemap_grid(tm, int(grid.width), int(grid.height), tiles);
        if (q.place) place_tilemap(W, mapE, tm, q, grid.width, grid.height);

        // Spawn the objects in row-major order. They get provisional ids: the final ones may belong to the objects of the
        // previous import until those are destroyed below.
        const Mat4 m = W.world_matrix(mapE);
        std::vector<std::pair<Entity, const Cell*>> fresh;
        for (const Cell& cell : cells) {
            if (!cell.has_object()) continue;
            const LegendEntry& le = *cell.entry;
            const Vec2 local = tilemap_cell_center(tm, cell.col, cell.row);
            Vec3 pos = m.transform_point({local.x, local.y, 0.0f});
            pos.x += le.offset.x;
            pos.y += le.offset.y;
            Json overrides = Json::object();
            if (!le.overrides.empty()) overrides["components"] = le.overrides;
            overrides["components"]["Transform"]["position"] = Json::array({pos.x, pos.y, pos.z});

            LoadReport report;
            Entity e = instantiate_prefab(W, le.prefab, kNullEntity, report, overrides);
            if (!e || !W.alive(e) || report.error_count() > 0) {
                for (Entity c : report.created)
                    if (W.alive(c)) W.destroy(c);
                std::string detail;
                for (const LoadMessage& msg : report.messages)
                    if (msg.severity == LoadMessage::Severity::Error) detail += "\n  " + msg.to_string();
                throw CommandError(
                    "invalid_argument",
                    "Cannot spawn legend['" + le.glyph + "'] (prefab '" + le.prefab + "') at " + cell_text(cell.col, cell.row) + ":" +
                        (detail.empty() ? " the prefab did not load" : detail),
                    "Fix the prefab file or legend['" + le.glyph +
                        "'].overrides (the messages above name the field and valid names). Nothing was changed.");
            }
            spawnedEntities.push_back(e);
            for (const LoadMessage& msg : report.messages)
                if (msg.severity == LoadMessage::Severity::Warning) diag.warn(msg.to_string());
            std::vector<std::string>& tags = W.info(e).tags;
            if (std::find(tags.begin(), tags.end(), tag) == tags.end()) tags.push_back(tag);
            fresh.emplace_back(e, &cell);
        }

        // Replace: the previous objects of this tilemap go away, then the new ones get their final ids.
        for (Entity e : previous)
            if (W.alive(e)) {
                removedJson.push_back(W.id_of(e));
                W.destroy(e);
            }
        if (flushNow) W.flush();
        for (auto& [e, cell] : fresh) {
            if (W.id_of(e) != cell->id)
                if (auto r = W.set_id(e, cell->id); !r.ok())
                    throw CommandError("failed", "Cannot give the id '" + cell->id + "' to the object at " +
                                                     cell_text(cell->col, cell->row) + ": " + r.error().message, r.error().hint);
            const Vec3 p = W.world_position(e);
            spawnedJson.push_back(Json::object({{"id", cell->id},
                                                {"prefab", cell->entry->prefab},
                                                {"glyph", cell->entry->glyph},
                                                {"cell", Json::array({cell->col, cell->row})},
                                                {"position", Json::array({to_json(p.x), to_json(p.y)})}}));
        }
    } catch (...) {
        rollback();
        throw;
    }

    for (const LegendEntry& e : legend)
        if (e.uses == 0 && !e.shared) diag.warn("legend['" + e.glyph + "'] is not used in rows.");

    Json out = Json::object();
    out["tilemap"] = q.mapId;
    out["created"] = created;
    out["width"] = grid.width;
    out["height"] = grid.height;
    out["tileCount"] = tileCount;
    out["spawned"] = spawnedJson;
    out["removed"] = removedJson;
    out["tag"] = tag;
    if (!diag.notes.empty()) out["notes"] = diag.notes;
    out["warnings"] = diag.warnings;
    return out;
}

void add_note(Json& out, const std::string& note) {
    if (!out.contains("notes")) out["notes"] = Json::array();
    out["notes"].push_back(note);
}

// `edits` ({entity id: {Component: {fields}}}) on the scratch World, one scene.set_component each (same code: components
// are added when missing, fields patched, errors name the field with did-you-mean). The error says which edit it was.
// An edit may carry the key "$merge": true next to its fields: that edit is a scene.set_component with `merge` (RFC 7386:
// Script.props merges into the current props, null deletes a key). It is a key no field is called, so it cannot be
// mistaken for one.
void apply_edits(World& scratch, const Json& edits) {
    for (auto e = edits.begin(); e != edits.end(); ++e)
        for (auto c = e->begin(); c != e->end(); ++c) {
            try {
                Json fields = *c;
                bool merge = false;
                if (fields.contains("$merge")) {
                    if (!fields["$merge"].is_boolean())
                        bad_arg("\"$merge\" must be true or false, got " + describe_json_value(fields["$merge"]),
                                "Example: {\"Script\": {\"$merge\": true, \"props\": {\"levelIndex\": 3}}}.");
                    merge = fields["$merge"].get<bool>();
                    fields.erase("$merge");
                }
                set_component(scratch, Json::object({{"id", e.key()}, {"component", c.key()}, {"fields", fields}, {"merge", merge}}));
            } catch (const CommandError& err) {
                throw CommandError(err.code, "edits[\"" + e.key() + "\"][\"" + c.key() + "\"]: " + err.what(),
                                   (err.hint.empty() ? std::string() : err.hint + " ") + "Nothing was written.", err.data);
            }
        }
}

// ---- prefab references in the written file
// The scratch World holds every entity expanded, so save_scene writes the prefabs' contents into each level. The file is
// better as it was authored: legend objects as {"id", "prefab", "tags", "components": {overrides + position}} and the base
// scene's prefab entries as they were, so editing a prefab changes every level without importing again. Only entities
// that no `edits` entry touches are turned back into references (an edit changes the expanded entity, which a reference
// cannot express); the rest stay expanded. Entries without an id also stay expanded (nothing identifies them).
struct PrefabRef {
    Json ref;
    bool fromLegend = false;  // the position comes from the written (expanded) entity
};

void collect_base_refs(const Json& entities, const std::string& skipId, std::map<std::string, PrefabRef>& out) {
    if (!entities.is_array()) return;
    for (const Json& ent : entities) {
        if (!ent.is_object()) continue;
        if (ent.contains("prefab") && ent.contains("id") && ent["id"].is_string() && ent["id"].get<std::string>() != skipId) {
            out[ent["id"].get<std::string>()] = PrefabRef{ent, false};
            continue;  // its children belong to the reference
        }
        if (ent.contains("children")) collect_base_refs(ent["children"], skipId, out);
    }
}

bool subtree_edited(const Json& ent, const Json& edits) {
    if (ent.contains("id") && ent["id"].is_string() && edits.contains(ent["id"].get<std::string>())) return true;
    if (ent.contains("children") && ent["children"].is_array())
        for (const Json& c : ent["children"])
            if (c.is_object() && subtree_edited(c, edits)) return true;
    return false;
}

void rewrite_prefab_refs(Json& entities, const std::map<std::string, PrefabRef>& refs, const Json& edits) {
    if (!entities.is_array()) return;
    for (Json& ent : entities) {
        if (!ent.is_object()) continue;
        if (ent.contains("id") && ent["id"].is_string()) {
            auto it = refs.find(ent["id"].get<std::string>());
            if (it != refs.end() && !subtree_edited(ent, edits)) {
                Json ref = it->second.ref;
                if (it->second.fromLegend && ent.contains("components") && ent["components"].contains("Transform") &&
                    ent["components"]["Transform"].contains("position"))
                    ref["components"]["Transform"]["position"] = ent["components"]["Transform"]["position"];
                ent = std::move(ref);
                continue;
            }
        }
        if (ent.contains("children")) rewrite_prefab_refs(ent["children"], refs, edits);
    }
}

std::map<std::string, PrefabRef> prefab_refs(const Request& q, const std::string& source, bool sourceExists,
                                             const std::vector<Cell>& cells) {
    std::map<std::string, PrefabRef> refs;
    if (sourceExists)
        if (auto raw = load_json_file(source); raw.ok() && raw.value().is_object() && raw.value().contains("entities"))
            collect_base_refs(raw.value()["entities"], q.mapId, refs);
    std::map<std::string, Json> tagsOf;  // prefab path -> its tags plus the map's tag, read once per prefab
    for (const Cell& cell : cells) {
        if (!cell.has_object()) continue;
        const LegendEntry& le = *cell.entry;
        auto [slot, isNew] = tagsOf.try_emplace(le.prefab, Json::array());
        Json& tags = slot->second;
        if (isNew) {
            if (auto pf = load_json_file(le.prefab); pf.ok() && pf.value().contains("entity") && pf.value()["entity"].contains("tags") &&
                                                      pf.value()["entity"]["tags"].is_array())
                tags = pf.value()["entity"]["tags"];
            const std::string tag = kTagPrefix + q.mapId;
            if (std::find(tags.begin(), tags.end(), Json(tag)) == tags.end()) tags.push_back(tag);
        }
        Json ref = Json::object({{"id", cell.id}, {"prefab", le.prefab}, {"tags", tags}});
        ref["components"] = le.overrides;
        refs[cell.id] = PrefabRef{ref, true};
    }
    return refs;
}

// File mode (`path`): the scene FILE is loaded into a scratch World, the map is imported into it and the result is
// written back with the canonical writer (the same layout as scene.save). Nothing of the running engine is involved:
// not its World, scenes, physics, audio or scripts; a scratch World is plain data. The reads go through the VFS (prefab
// files, the tileset image for the range check), which has no per-engine state either. Any failure happens before the
// write, so the file is either replaced completely or left exactly as it was.
//
// Start state: `from` if given, else `path` itself. When that file does not exist: an error for `from`, an empty scene for
// `path` (creating a new level is the normal first call; a typo is reported as a warning with a "did you mean").
Json import_into_scene_file(const Request& q, const Grid& grid, std::vector<LegendEntry>& legend, std::vector<Cell>& cells) {
    const std::string source = q.from.empty() ? q.path : q.from;
    World scratch;
    Json startWarnings = Json::array();
    bool startedEmpty = false;
    if (fs::exists(source)) {
        LoadReport report = load_scene_file(scratch, source);
        if (report.error_count() > 0) {
            std::string detail;
            std::size_t shown = 0;
            for (const LoadMessage& m : report.messages)
                if (m.severity == LoadMessage::Severity::Error && ++shown <= 5) detail += "\n  " + m.to_string();
            if (report.error_count() > shown) detail += "\n  ... (" + std::to_string(report.error_count() - shown) + " more)";
            throw CommandError(
                "invalid_argument",
                "Cannot edit '" + source + "': it has " + std::to_string(report.error_count()) +
                    " load error(s), and writing the scene back would silently drop the entries that failed to load:" + detail,
                "Fix the file first (project.validate lists every problem with its JSON pointer), or start from another scene with "
                "\"from\": \"<base scene>\". Nothing was written.");
        }
        for (const LoadMessage& m : report.messages) startWarnings.push_back(m.to_string());
    } else if (!q.from.empty()) {
        std::vector<std::string> scenes = scene_files();
        throw CommandError("not_found", "'from' scene '" + q.from + "' does not exist. " + did_you_mean(q.from, scenes),
                           "'from' is the scene file to start from (e.g. a base scene with the camera and HUD). Use project.info to list scenes. "
                           "Nothing was written.");
    } else {
        startedEmpty = true;
    }

    Json out = apply_import(scratch, true, q, grid, legend, cells);
    apply_edits(scratch, q.edits);  // after the import, so they can also reach what it placed; before the write, so a wrong one writes nothing

    Json scene = save_scene(scratch);
    if (scene.contains("entities"))
        rewrite_prefab_refs(scene["entities"], prefab_refs(q, source, !startedEmpty, cells), q.edits);
    out["path"] = q.path;
    out["from"] = startedEmpty ? Json(nullptr) : Json(source);
    out["entityCount"] = scratch.entity_count();
    if (!startWarnings.empty()) {
        Json merged = startWarnings;
        for (const Json& w : out["warnings"]) merged.push_back(w);
        out["warnings"] = merged;
    }
    if (startedEmpty) {
        std::string msg = "'" + q.path + "' does not exist, so it " + (q.dryRun ? "would start" : "starts") +
                          " as an empty scene (default settings, no camera, no scripts).";
        const std::string near = closest_match(q.path, scene_files());
        if (!near.empty()) {
            out["warnings"].push_back(msg + " Did you mean '" + near + "'? Fix 'path', or pass \"from\": \"" + near + "\" to build on it.");
        } else {
            add_note(out, msg + " Pass \"from\": \"<base scene>\" to start from an existing scene (camera, HUD, settings).");
        }
    } else if (!q.from.empty() && fs::exists(q.path)) {
        add_note(out, "'" + q.path + "' " + (q.dryRun ? "would be replaced" : "was replaced") + " by the result of importing into '" + q.from + "'.");
    }
    if (!ends_with(q.path, ".scene.json"))
        out["warnings"].push_back("'" + q.path + "' does not end in .scene.json, so project.info, validate and the editor will not list it as a scene.");

    out["dryRun"] = q.dryRun;
    if (q.dryRun) {
        out["scene"] = std::move(scene);
        return out;
    }
    if (auto r = save_scene_json_file(q.path, scene); !r.ok())
        throw CommandError("failed", "The level was imported but writing '" + q.path + "' failed: " + r.error().message, r.error().hint);
    // The running engine is deliberately not told: its World is unchanged. If `path` is the running scene and hot reload
    // is on (windowed play), the file watcher reloads it from disk like after any other edit of the file.
    out["saved"] = q.path;
    return out;
}

// `legendFrom` (a project-relative JSON file holding a legend, or {"legend": {...}}) merged UNDER the map's own `legend`.
Json merged_legend(const Json& a) {
    Json own = a.contains("legend") ? a["legend"] : Json::object();
    if (!a.contains("legendFrom")) return own;
    const Json& lf = a["legendFrom"];
    if (!lf.is_string() || lf.get<std::string>().empty())
        bad_arg("'legendFrom' must be a project-relative JSON file path, got " + describe_json_value(lf),
                "Example: \"legendFrom\": \"levels/legend.json\" (a file with the legend object: {\"#\": 0, \"o\": {...}}).");
    auto norm = fs::normalize_checked(lf.get<std::string>());
    if (!norm.ok()) bad_arg("'legendFrom': " + norm.error().message, norm.error().hint);
    const std::string& file = norm.value();
    if (!fs::exists(file)) {
        std::vector<std::string> jsons = fs::list("", true, ".json");
        bad_arg("'legendFrom' file '" + file + "' does not exist. " + did_you_mean(file, jsons),
                "It is a JSON file with the shared legend, e.g. levels/legend.json: {\"#\": 0, \"o\": {\"prefab\": \"prefabs/coin.prefab.json\"}}.");
    }
    auto shared = load_json_file(file);
    if (!shared.ok()) bad_arg("'legendFrom': " + shared.error().message, shared.error().hint);
    Json base = shared.value();
    if (base.is_object() && base.contains("legend") && base["legend"].is_object()) base = base["legend"];
    if (!base.is_object())
        bad_arg("'legendFrom' file '" + file + "' must hold a legend object, got " + describe_json_value(base),
                "Example: {\"#\": 0, \"o\": {\"prefab\": \"prefabs/coin.prefab.json\"}}.");
    if (!own.is_object()) return own;  // parse_legend reports it
    for (auto it = own.begin(); it != own.end(); ++it) base[it.key()] = it.value();
    return base;
}

Json import_ascii(Engine::Impl& I, const Json& a) {
    // ---- 1. Everything that can be checked from the arguments alone.
    const Grid grid = parse_rows(a);
    if (!a.contains("legend") && !a.contains("legendFrom"))
        bad_arg("Missing 'legend'", "Example: \"legend\": {\"#\": 0, \"o\": {\"prefab\": \"prefabs/coin.prefab.json\"}}, "
                                    "or \"legendFrom\": \"levels/legend.json\" for a legend shared by several maps.");
    std::vector<LegendEntry> legend = parse_legend(merged_legend(a));
    if (a.contains("legendFrom"))
        for (LegendEntry& e : legend) e.shared = !(a.contains("legend") && a["legend"].is_object() && a["legend"].contains(e.glyph));
    std::vector<Cell> cells = resolve_cells(grid, legend);
    const Request q = parse_request(I, a);

    if (!q.path.empty()) return import_into_scene_file(q, grid, legend, cells);

    // ---- 2. The running world (and, with `save`, the current scene file).
    Json out = apply_import(I.world, !I.inFrame, q, grid, legend, cells);
    if (q.save) {
        auto r = save_scene_file(I.world, I.currentScene);
        if (!r.ok())
            throw CommandError("failed", "The level was imported but writing '" + I.currentScene + "' failed: " + r.error().message,
                               r.error().hint);
        if (I.watchSeeded) I.watched[I.currentScene] = fs::modified_time(I.currentScene);
        out["saved"] = I.currentScene;
        add_note(out, "SAVED '" + I.currentScene + "': that is the RUNNING scene, so everything in the running world went into the file. "
                      "To change a scene file without touching the running game, pass \"path\" (and optionally \"from\").");
    }
    return out;
}

// ------------------------------------------------------------------------------------------------ scene.ascii_edit
// Edits the `rows` of an import_ascii args file in place (see register_level_commands for the contract).
struct AsciiEditCtx {
    Grid grid;
    std::vector<LegendEntry> legend;
    Json args;
    int changed = 0;
    bool solidLoaded = false;
    std::set<int> solid;

    const LegendEntry* find(const std::string& g) const {
        for (const LegendEntry& e : legend)
            if (e.glyph == g) return &e;
        return nullptr;
    }
    std::string glyph_arg(const Json& op, const char* key) const {
        if (!op.contains(key)) bad_arg(std::string("missing '") + key + "'", std::string("Example: \"") + key + "\": \"#\".");
        std::vector<std::string> g = op[key].is_string() ? split_glyphs(op[key].get<std::string>()) : std::vector<std::string>();
        if (g.size() != 1)
            bad_arg(std::string("'") + key + "' must be a string of exactly one character, got " + describe_json_value(op[key]),
                    "One map cell is one character, e.g. \"#\" or \"o\".");
        if (!is_default_empty(g[0]) && !find(g[0])) {
            std::vector<std::string> known;
            for (const LegendEntry& e : legend) known.push_back(e.glyph);
            bad_arg("glyph " + show_glyph(g[0]) + " is neither '.' / ' ' (empty) nor in the legend. " + did_you_mean(g[0], known),
                    "The legend defines " + (known.empty() ? std::string("nothing") : show_glyph_list(known)) +
                        ". Add the glyph to the file's `legend` (or legendFrom file) first.");
        }
        return g[0];
    }
    int int_arg(const Json& op, const char* key, int minValue) const {
        int v = 0;
        if (!op.contains(key) || !as_int(op[key], v))
            bad_arg(std::string("'") + key + "' must be an integer" +
                        (op.contains(key) ? ", got " + describe_json_value(op[key]) : ", but it is missing"),
                    "Columns and rows count from 0 (row 0 = top).");
        if (v < minValue) bad_arg(std::string("'") + key + "' must be >= " + std::to_string(minValue) + ", got " + std::to_string(v));
        return v;
    }
    std::string size_text() const {
        return "the map is " + std::to_string(grid.width) + " columns x " + std::to_string(grid.height) +
               " rows (0-based, row 0 = top)";
    }
    void column_in_range(int col) const {
        if (col < 0 || std::size_t(col) >= grid.width)
            bad_arg("column " + std::to_string(col) + " is outside the map: " + size_text(),
                    "Use a column from 0 to " + std::to_string(grid.width - 1) + ".");
    }
    std::array<int, 4> rect_arg(const Json& op) const {
        std::array<int, 4> r{};
        if (!op.contains("rect") || !op["rect"].is_array() || op["rect"].size() != 4)
            bad_arg("'rect' must be [col, row, w, h], got " +
                        (op.contains("rect") ? describe_json_value(op["rect"]) : std::string("nothing")),
                    "Example: \"rect\": [10, 3, 4, 2] = 4 columns x 2 rows starting at column 10, row 3.");
        for (int i = 0; i < 4; ++i)
            if (!as_int(op["rect"][i], r[i]) || r[i] < (i < 2 ? 0 : 1))
                bad_arg("'rect' must hold integers [col >= 0, row >= 0, w >= 1, h >= 1], got " + op["rect"].dump(),
                        "Example: [10, 3, 4, 2].");
        if (std::size_t(r[0] + r[2]) > grid.width || std::size_t(r[1] + r[3]) > grid.height)
            bad_arg("rect " + op["rect"].dump() + " reaches outside the map: " + size_text(),
                    "col + w must be <= " + std::to_string(grid.width) + " and row + h <= " + std::to_string(grid.height) + ".");
        return r;
    }
    void set(int col, int row, const std::string& g) {
        std::string& c = grid.glyphs[row][col];
        if (c != g) ++changed;
        c = g;
    }
    bool is_solid(const std::string& g) const {
        const LegendEntry* e = find(g);
        return e && e->hasTile && e->tile >= 0 && solid.count(tile_index(e->tile));
    }
    // Reads the solid tile indices once: the file's tilemap.solidTiles, else the Tilemap of the scene it builds.
    void load_solid() {
        if (solidLoaded) return;
        solidLoaded = true;
        auto take = [&](const Json& tiles) {
            for (const Json& t : tiles)
                if (int v = 0; as_int(t, v)) solid.insert(v);
        };
        if (args.contains("tilemap") && args["tilemap"].is_object() && args["tilemap"].contains("solidTiles") &&
            args["tilemap"]["solidTiles"].is_array()) {
            take(args["tilemap"]["solidTiles"]);
            return;
        }
        const std::string scene = args.value("from", args.value("path", std::string()));
        if (scene.empty() || !fs::exists(scene)) return;
        auto raw = load_json_file(scene);
        if (!raw.ok() || !raw.value().is_object() || !raw.value().contains("entities")) return;
        const std::string mapId = args.value("entity", std::string("tilemap"));
        std::function<bool(const Json&)> walk = [&](const Json& ents) {
            if (!ents.is_array()) return false;
            for (const Json& e : ents) {
                if (!e.is_object()) continue;
                if (e.value("id", std::string()) == mapId && e.contains("components") && e["components"].contains("Tilemap") &&
                    e["components"]["Tilemap"].contains("solidTiles") && e["components"]["Tilemap"]["solidTiles"].is_array()) {
                    take(e["components"]["Tilemap"]["solidTiles"]);
                    return true;
                }
                if (e.contains("children") && walk(e["children"])) return true;
            }
            return false;
        };
        walk(raw.value()["entities"]);
    }
    int ground_row(int col) {
        load_solid();
        if (solid.empty())
            bad_arg("'above' needs to know which tiles are ground, but the file has no tilemap.solidTiles and the scene it builds has "
                    "no Tilemap with solidTiles",
                    "Pass \"row\": <n> instead, or add \"tilemap\": {\"solidTiles\": [...]} to the file.");
        for (std::size_t r = 0; r < grid.height; ++r)
            if (is_solid(grid.glyphs[r][col])) return int(r);
        bad_arg("column " + std::to_string(col) + " has no ground (no solid tile in any row)",
                "Pass \"row\": <n> to put the glyph at an exact row instead of \"above\".");
    }

    void apply(const Json& op) {
        if (!op.is_object() || !op.contains("op") || !op["op"].is_string())
            bad_arg("each op must be an object with an \"op\" string, got " + describe_json_value(op),
                    "Example: {\"op\": \"fill\", \"rect\": [0, 5, 3, 1], \"glyph\": \"#\"}.");
        const std::string name = op["op"].get<std::string>();
        static const std::vector<std::string> kOps = {"fill", "replace", "insertColumns", "deleteColumns", "put"};
        if (std::find(kOps.begin(), kOps.end(), name) == kOps.end())
            bad_arg("unknown op '" + name + "'. " + did_you_mean(name, kOps), "Ops: fill, replace, insertColumns, deleteColumns, put.");
        if (name == "fill") {
            auto r = rect_arg(op);
            const std::string g = glyph_arg(op, "glyph");
            for (int y = r[1]; y < r[1] + r[3]; ++y)
                for (int x = r[0]; x < r[0] + r[2]; ++x) set(x, y, g);
        } else if (name == "replace") {
            const std::string from = glyph_arg(op, "from"), to = glyph_arg(op, "to");
            std::array<int, 4> r{0, 0, int(grid.width), int(grid.height)};
            if (op.contains("rect")) r = rect_arg(op);
            for (int y = r[1]; y < r[1] + r[3]; ++y)
                for (int x = r[0]; x < r[0] + r[2]; ++x)
                    if (grid.glyphs[y][x] == from) set(x, y, to);
        } else if (name == "insertColumns") {
            const int at = int_arg(op, "at", 0), count = int_arg(op, "count", 1);
            if (std::size_t(at) > grid.width)
                bad_arg("'at' " + std::to_string(at) + " is outside the map: " + size_text(),
                        "Use 0.." + std::to_string(grid.width) + " (the width appends at the right edge).");
            if (grid.width + std::size_t(count) > 65536) bad_arg("the map would be wider than 65536 columns");
            const std::string fixed = op.contains("glyph") ? glyph_arg(op, "glyph") : std::string();
            for (auto& row : grid.glyphs) {
                std::string g = fixed;
                if (!op.contains("glyph")) {
                    g = row[at > 0 ? at - 1 : 0];
                    const LegendEntry* e = find(g);
                    if (e && !e->prefab.empty()) g = ".";
                }
                row.insert(row.begin() + at, std::size_t(count), g);
            }
            grid.width += count;
            changed += count * int(grid.height);
        } else if (name == "deleteColumns") {
            const int at = int_arg(op, "at", 0), count = int_arg(op, "count", 1);
            column_in_range(at);
            if (std::size_t(at + count) > grid.width)
                bad_arg("columns " + std::to_string(at) + ".." + std::to_string(at + count - 1) + " reach outside the map: " + size_text());
            if (std::size_t(count) == grid.width) bad_arg("this would delete every column of the map", "A map needs at least one column.");
            for (auto& row : grid.glyphs) row.erase(row.begin() + at, row.begin() + at + count);
            grid.width -= count;
            changed += count * int(grid.height);
        } else {  // put
            const int col = int_arg(op, "col", 0);
            column_in_range(col);
            const std::string g = glyph_arg(op, "glyph");
            if (op.contains("row") == op.contains("above"))
                bad_arg("give exactly one of 'row' (absolute, 0 = top) or 'above' (cells above the ground, 1 = standing on it)",
                        "Example: {\"op\": \"put\", \"col\": 12, \"glyph\": \"o\", \"above\": 1}.");
            const int row = op.contains("row") ? int_arg(op, "row", 0) : ground_row(col) - int_arg(op, "above", 1);
            if (row < 0 || std::size_t(row) >= grid.height)
                bad_arg("row " + std::to_string(row) + " is outside the map: " + size_text(),
                        "Use a row from 0 to " + std::to_string(grid.height - 1) + ".");
            set(col, row, g);
        }
    }
};

Json ascii_edit(Engine::Impl& I, const Json& a) {
    if (!a.contains("file") || !a["file"].is_string())
        bad_arg("Missing 'file'", "Example: {\"file\": \"levels/1-1.json\", \"ops\": [{\"op\": \"put\", \"col\": 12, \"glyph\": \"o\", \"above\": 1}]}.");
    if (!a.contains("ops") || !a["ops"].is_array() || a["ops"].empty())
        bad_arg("'ops' must be a non-empty array of operations",
                "Example: \"ops\": [{\"op\": \"fill\", \"rect\": [0, 5, 3, 1], \"glyph\": \"#\"}]. Ops: fill, replace, insertColumns, deleteColumns, put.");
    auto norm = fs::normalize_checked(a["file"].get<std::string>());
    if (!norm.ok()) bad_arg("'file': " + norm.error().message, norm.error().hint);
    const std::string file = norm.value();
    if (!fs::exists(file)) {
        std::vector<std::string> jsons = fs::list("", true, ".json");
        throw CommandError("not_found", "'file' '" + file + "' does not exist. " + did_you_mean(file, jsons),
                           "It is a JSON file with the arguments of scene.import_ascii (at least `rows`).");
    }
    auto loaded = load_json_file(file);
    if (!loaded.ok()) bad_arg("'file': " + loaded.error().message, loaded.error().hint);
    if (!loaded.value().is_object()) bad_arg("'" + file + "' must hold an object with the arguments of scene.import_ascii");

    AsciiEditCtx ctx;
    ctx.args = loaded.value();
    ctx.grid = parse_rows(ctx.args);
    ctx.legend = parse_legend(merged_legend(ctx.args));
    const bool dryRun = a.value("dryRun", false), rebuild = a.value("rebuild", true);

    for (std::size_t i = 0; i < a["ops"].size(); ++i) {
        try {
            ctx.apply(a["ops"][i]);
        } catch (const CommandError& err) {
            throw CommandError(err.code, "ops[" + std::to_string(i) + "]: " + err.what(),
                               (err.hint.empty() ? std::string() : err.hint + " ") + "Nothing was written.", err.data);
        }
    }
    Json rows = Json::array();
    for (const auto& row : ctx.grid.glyphs) {
        std::string s;
        for (const std::string& g : row) s += g;
        rows.push_back(s);
    }
    Json edited = ctx.args;
    edited["rows"] = rows;

    Json out = Json::object();
    if (rebuild && edited.contains("path")) {
        Json importArgs = edited;
        if (dryRun) importArgs["dryRun"] = true;
        out = import_ascii(I, importArgs);  // `file` is not written yet: a failing import leaves everything as it was
    }
    out["file"] = file;
    out["width"] = ctx.grid.width;
    out["height"] = ctx.grid.height;
    out["ops"] = a["ops"].size();
    out["changedCells"] = ctx.changed;
    out["dryRun"] = dryRun;
    if (dryRun) {
        out["rows"] = rows;
        return out;
    }
    const std::string text = dump_json(edited);
    if (auto r = fs::write_bytes(file, text.data(), text.size()); !r.ok())
        throw CommandError("failed", "Writing '" + file + "' failed: " + r.error().message, r.error().hint);
    return out;
}

}  // namespace

void register_level_commands(Engine& engine, Engine::Impl& I) {
    I.commands.add(
        {"scene.import_ascii",
         "Build a Tilemap level and the objects standing on it (coins, enemies, spawn points) from ASCII rows and a legend.",
         "Author a tile level as text. `rows` is the map, one string per row, ONE CHARACTER PER TILE, row 0 = the TOP row (all "
         "rows the same length). `legend` maps each character to a tile index (integer) or to an object: {\"tile\"?: int, "
         "\"prefab\"?: \"prefabs/x.prefab.json\", \"id\"?: \"player\", \"overrides\"?: {component patches}, \"offset\"?: [dx, dy]}. "
         "'.' and ' ' are empty tiles unless the legend defines them. A glyph with a `tile` draws that tile; with a `prefab` it "
         "also spawns the prefab at the CENTRE of its cell (a glyph may have both; a prefab-only glyph leaves the tile empty). "
         "`overrides` patch the prefab's components per glyph; `offset` shifts the object (world units) from the cell centre. "
         "The tilemap is the entity `entity` (default \"tilemap\"): created when missing, updated when it exists; `tilemap` sets "
         "its Tilemap fields (tileset, tileSize, projection, groundHeight, groundOffset, margin, spacing, columns, solidTiles, color, layer; columns is optional: left at 0 it is "
         "derived from the tileset width, tileSize.x, margin and spacing). Its position is the map's TOP-LEFT corner (+Y up, like "
         "Tilemap everywhere; an isometric map's position is its TOP corner, and objects stand at the centres of its diamonds); pass `position` (+ `anchor`: top-left, bottom-left or center) to place it, e.g. anchor "
         "bottom-left at [0,0] puts the level's floor at y=0. Objects are ordinary top-level entities that save with the scene; "
         "ids are `id` from the legend (unique objects such as \"player\") or generated in row-major order as <prefab name>_<n> "
         "(coin_1, coin_2...); every object is tagged \"tilemap:<entity>\". With `replace` (default true) the objects of earlier "
         "imports into the same tilemap are destroyed first, so re-importing an edited map does not duplicate them. "
         "`legendFrom` names a JSON file with a legend shared by several maps (e.g. \"levels/legend.json\"); it is merged under "
         "`legend` (the map's own entry wins for a glyph) and its unused entries are not warned about. "
         "TWO WAYS TO USE IT. (1) With `path` it edits that scene FILE and nothing else: the file (or `from`, a base scene to "
         "start from; a missing `path` without `from` starts as an empty scene) is loaded into a scratch world, the map is "
         "imported into it and the result is written to `path` in the canonical layout of scene.save. The running world, "
         "audio, physics and scripts are not touched, so it is safe to call from a tool or a one-shot `factoria call` and the "
         "file can be rebuilt as often as needed. The file keeps PREFAB REFERENCES instead of expanding prefabs: each legend "
         "object is written as {\"id\", \"prefab\", \"tags\", \"components\": {the legend overrides + Transform.position}} and the "
         "prefab entries of the base scene stay as they are, so editing a prefab file changes every level without importing "
         "again and level files stay small (a scene loaded into the world still expands them). An entity that `edits` "
         "touches, or a base prefab entry without an `id`, is written expanded. `dryRun` writes nothing and returns the scene JSON in `scene`. `edits` "
         "(file mode only) patches components of that scene's entities right after the map is imported and before the write, "
         "e.g. the camera and sky colour of a base scene: {\"<entity id>\": {\"<Component>\": {field: value}}}, each entry "
         "exactly scene.set_component (a missing component is added, only the given fields change, and a value outside a field's "
         "range is refused; Script.props is replaced as a whole unless the edit has \"$merge\": true next to its fields, "
         "e.g. {\"level\": {\"Script\": {\"$merge\": true, \"props\": {\"levelIndex\": 3}}}}, which merges the given props "
         "into the current ones as an RFC 7386 JSON merge-patch: other props stay, null deletes one); a wrong entity, "
         "component or field fails the call naming it, with suggestions, and writes nothing. If the "
         "file has load errors the call fails instead of dropping them. (2) Without `path` it changes the RUNNING world (like "
         "scene.spawn); `save` then also writes the current scene file like scene.save, so it needs a scene you chose "
         "(--scene or scene.load): when the running scene is only the project's mainScene loaded by default, `save` is "
         "refused (error unsafe_save) instead of overwriting it. With `path`, `save` is ignored: the file is always written. "
         "Nothing is changed when an argument is wrong: errors name the row/column, the glyph, the legend and suggestions. "
         "Returns {tilemap, created, width, height, tileCount, spawned:[{id, prefab, glyph, cell:[col,row], "
         "position:[x,y]}], removed, tag, warnings, notes?, saved?} plus, with `path`, {path, from (the file it started "
         "from, null = empty scene), entityCount, dryRun, scene? (dryRun)}. Example: "
         "scene.import_ascii {\"rows\":[\"..........\",\"...o..o...\",\".P......o.\",\"##########\"],"
         "\"legend\":{\"#\":0,\"o\":{\"prefab\":\"prefabs/coin.prefab.json\"},"
         "\"P\":{\"prefab\":\"prefabs/player.prefab.json\",\"id\":\"player\"}},"
         "\"tilemap\":{\"tileset\":\"assets/tiles.png\",\"tileSize\":[32,32],\"solidTiles\":[0]},"
         "\"anchor\":\"bottom-left\",\"position\":[0,0],\"path\":\"scenes/level1.scene.json\","
         "\"from\":\"levels/base.scene.json\"}",
         parse_schema(R"json({"type":"object","required":["rows"],"properties":{
               "rows":{"type":"array","minItems":1,"items":{"type":"string"},
                       "description":"The map: one string per row, one character per tile, row 0 = TOP row, all rows the same length."},
               "legend":{"type":"object",
                         "description":"Glyph -> tile index (integer, -1 = empty) or {tile?: int, rotate?: 0|90|180|270 (clockwise), flipX?: bool, flipY?: bool, prefab?: 'prefabs/x.prefab.json', id?: 'player', overrides?: {Component: {fields}}, offset?: [dx, dy]}. '.' and ' ' mean empty unless defined here."},
               "legendFrom":{"type":"string",
                             "description":"Project-relative JSON file with a SHARED legend (e.g. levels/legend.json: {\"#\": 0, \"o\": {\"prefab\": \"prefabs/coin.prefab.json\"}}), merged UNDER `legend`: the map's own entries win for the same glyph. Entries only the shared file defines are not warned about when unused. `legend` may then be omitted."},
               "tilemap":{"type":"object",
                          "description":"Tilemap field values (tileset, tileSize, projection, groundHeight, groundOffset, margin, spacing, columns, solidTiles, color, layer) applied to the new or existing tilemap. The grid itself comes from rows/legend."},
               "entity":{"type":"string","default":"tilemap","description":"Id of the tilemap entity: created if missing, updated if it exists."},
               "replace":{"type":"boolean","default":true,
                          "description":"Destroy the objects spawned by earlier imports into this tilemap (tag tilemap:<entity>) first, so re-importing does not duplicate them. false keeps them."},
               "path":{"type":"string","description":"File mode: project-relative scene file (e.g. scenes/level1.scene.json) to edit. It is loaded into a scratch world, the map is imported into it and it is written back; the running world is not touched. Does not exist yet (and no `from`): starts as an empty scene. Writable places only (not .factoria/ except .factoria/tmp/)."},
               "from":{"type":"string","description":"File mode (needs `path`): scene file to start from instead of `path`, e.g. a base scene with settings, camera and HUD but no map. `path` is then replaced by the result. Must exist."},
               "dryRun":{"type":"boolean","default":false,"description":"File mode (needs `path`): write nothing and return the resulting scene JSON in `scene`."},
               "edits":{"type":"object",
                        "description":"File mode (needs `path`): {entity id: {Component: {field: value}}} applied to the scene after the map is imported and before it is written, each entry like scene.set_component (e.g. {\"camera\": {\"Camera\": {\"clearColor\": [0.5, 0.7, 0.9, 1]}}}). Add \"$merge\": true inside a component's entry to MERGE Script.props (RFC 7386: other props stay, null deletes a key) instead of replacing it: {\"level\": {\"Script\": {\"$merge\": true, \"props\": {\"levelIndex\": 3}}}}. A wrong entity/component/field fails and nothing is written.",
                        "additionalProperties":{"type":"object","additionalProperties":{"type":"object"}}},
               "save":{"type":"boolean","default":false,"description":"Running-world mode: also write the current scene file (like scene.save). Refused when the running scene is only the default mainScene (no --scene, no scene.load): pass `path` instead. Ignored when `path` is given."},
               "position":{"type":"array","items":{"type":"number"},"minItems":2,"maxItems":3,
                           "description":"[x, y] (or [x, y, z]) world position of the map's anchor point. Default: a new tilemap sits at [0,0] (its top-left corner); an existing one stays where it is."},
               "anchor":{"type":"string","enum":["top-left","bottom-left","center"],
                         "description":"Which point of the map is placed at `position` (assumes an unrotated map). Default top-left, the Tilemap entity's own origin."}}})json"),
         false, "scene"},
        [&engine, &I](const Json& a) { return import_ascii(I, a); });

    I.commands.add(
        {"scene.ascii_edit",
         "Edit the ASCII map of a level file (a scene.import_ascii args file) with operations instead of rewriting rows, then rebuild the level.",
         "`file` is a project-relative JSON file holding scene.import_ascii arguments (at least `rows`; its legend is `legend` merged "
         "over `legendFrom`). `ops` run in order, all-or-nothing (an error names the op, e.g. ops[2], and nothing is written). "
         "Columns and rows are 0-based, row 0 = TOP, like import_ascii. Ops: {op:'fill', rect:[col,row,w,h], glyph}; "
         "{op:'replace', from, to, rect?} (whole map without rect); {op:'insertColumns', at, count, glyph?} (without glyph the new "
         "columns repeat the column left of `at` (column 0 when at = 0) with every glyph that spawns an object turned into '.', so "
         "the ground continues and nothing is duplicated); {op:'deleteColumns', at, count}; {op:'put', col, glyph, row} or "
         "{op:'put', col, glyph, above:h} = h rows above the ground of that column (1 = standing on it; ground = the topmost cell "
         "whose glyph is a tile in the file's tilemap.solidTiles, else the Tilemap of the scene the file builds). A glyph that is "
         "not '.', ' ' or in the legend is refused with suggestions. The edited `rows` are written back to `file` (one row per "
         "line, every other key and the key order kept). With `rebuild` (default true) and a `path` in the file, the level is then "
         "rebuilt exactly like `factoria call scene.import_ascii @file` and its result is merged into this one (`spawned` lists id, "
         "glyph and cell [col,row] of every object). `dryRun` writes nothing and returns the edited `rows` (and the import's dry run). "
         "Returns {file (written unless dryRun), width, height, ops (applied), changedCells (cells whose glyph changed; "
         "inserted/deleted columns count all their cells), dryRun, rows? (dryRun)} plus the import result when it ran (its "
         "`path` and `saved` name the scene file). Example: scene.ascii_edit "
         "{\"file\":\"levels/1-1.json\",\"ops\":[{\"op\":\"put\",\"col\":40,\"glyph\":\"o\",\"above\":1},"
         "{\"op\":\"insertColumns\",\"at\":60,\"count\":5}]}",
         parse_schema(R"json({"type":"object","required":["file","ops"],"properties":{
               "file":{"type":"string","description":"Project-relative JSON file with scene.import_ascii arguments (rows, legend/legendFrom, tilemap, path...)."},
               "ops":{"type":"array","minItems":1,"description":"Operations applied in order, all-or-nothing. fill {rect:[col,row,w,h], glyph}; replace {from, to, rect?}; insertColumns {at, count, glyph?}; deleteColumns {at, count}; put {col, glyph, row | above}. 0-based, row 0 = top.",
                      "items":{"type":"object","required":["op"],"properties":{
                          "op":{"type":"string","enum":["fill","replace","insertColumns","deleteColumns","put"],"description":"Which operation."},
                          "rect":{"type":"array","items":{"type":"integer"},"minItems":4,"maxItems":4,"description":"[col, row, w, h] (fill: required; replace: optional)."},
                          "glyph":{"type":"string","description":"One map character: fill/put glyph, or insertColumns filler (default: repeat the column left of `at` without objects)."},
                          "from":{"type":"string","description":"replace: glyph to find."},
                          "to":{"type":"string","description":"replace: glyph to write."},
                          "at":{"type":"integer","description":"insertColumns/deleteColumns: first column."},
                          "count":{"type":"integer","description":"insertColumns/deleteColumns: how many columns."},
                          "col":{"type":"integer","description":"put: column."},
                          "row":{"type":"integer","description":"put: absolute row (0 = top)."},
                          "above":{"type":"integer","description":"put: cells above the ground of `col` (1 = standing on it). Instead of `row`."}}}},
               "rebuild":{"type":"boolean","default":true,"description":"Rebuild the level with scene.import_ascii on the edited file when it has a `path`."},
               "dryRun":{"type":"boolean","default":false,"description":"Write nothing; return the edited rows (and the import's dry run)."}}})json"),
         false, "scene"},
        [&I](const Json& a) { return ascii_edit(I, a); });

    I.commands.add(
        {"tilemap.set_tile",
         "Change one tile of a Tilemap in the running scene, in place.",
         "Writes tile `tile` (a tileset index plus optional flip flags, or -1 for empty) at column `col`, row `row` of the "
         "Tilemap on entity `id` (0-based, row 0 = TOP row). Only that element of `tiles` changes: the array is not "
         "rewritten, the renderer reads it directly and 2D physics rebuilds only the colliders of the changed tiles on the "
         "next step. This is the command form of `entity.tilemap.setTile(col, row, tile)` in scripts. It changes the RUNNING "
         "world only (not the scene file; use scene.save to keep it, scene.import_ascii to rebuild a level file). A cell "
         "outside the map or a value that is not a tile is refused and nothing changes. Returns {id, col, row, tile, "
         "previous}. Example: tilemap.set_tile {\"id\":\"map\",\"col\":12,\"row\":7,\"tile\":-1}",
         parse_schema(R"json({"type":"object","required":["id","col","row","tile"],"properties":{
               "id":{"type":"string","description":"Id (or name) of the entity that has the Tilemap."},
               "col":{"type":"integer","minimum":0,"description":"Tile column, 0 = leftmost."},
               "row":{"type":"integer","minimum":0,"description":"Tile row, 0 = TOP row."},
               "tile":{"type":"integer","minimum":-1,"description":"Tileset index (plus optional flip flags, see Tilemap.tiles), or -1 to empty the cell."}}})json"),
         false, "scene"},
        [&I](const Json& a) {
            Entity e = need_entity(I.world, a);
            Tilemap* tm = I.world.get<Tilemap>(e);
            if (!tm)
                throw CommandError("invalid_argument", "Entity '" + I.world.id_of(e) + "' has no Tilemap component",
                                   "Pass the id of the entity that holds the Tilemap (scene.import_ascii names it 'tilemap' by default).");
            const int col = a["col"].get<int>(), row = a["row"].get<int>(), tile = a["tile"].get<int>();
            const TilemapSize size = tilemap_size(*tm);
            const int previous = tilemap_tile_at(*tm, size, col, row);
            if (!set_tilemap_tile(*tm, col, row, tile))
                throw CommandError("invalid_argument",
                                   "Cell (" + std::to_string(col) + ", " + std::to_string(row) + ") or tile " + std::to_string(tile) +
                                       " is not valid for the " + std::to_string(size.width) + " x " + std::to_string(size.height) + " map",
                                   "col is 0.." + std::to_string(std::max(size.width - 1, 0)) + ", row is 0.." +
                                       std::to_string(std::max(size.height - 1, 0)) + " (row 0 = top); tile is -1 or a tileset index.");
            return Json::object({{"id", I.world.id_of(e)}, {"col", col}, {"row", row}, {"tile", tile}, {"previous", previous}});
        });

    I.commands.add(
        {"tilemap.cell_at",
         "The cell of a Tilemap under a world point (orthogonal squares or isometric diamonds).",
         "Returns {id, col, row, inside, tile} for the Tilemap on entity `id`: the cell that contains the world point "
         "(`x`, `y`), by the entity's world transform (position, rotation, scale) and the map's `projection`. `inside` is "
         "false when the cell lies outside the map (col and row are then still the cell numbers the point falls in, so "
         "negative or past the edge) and `tile` is -1. Pair it with `camera.screenToWorld` to pick the cell under the mouse; "
         "the script form is `entity.tilemap.cellAt(point)`. Example: tilemap.cell_at {\"id\":\"ground\",\"x\":120,\"y\":-80}",
         parse_schema(R"json({"type":"object","required":["id","x","y"],"properties":{
               "id":{"type":"string","description":"Id (or name) of the entity that has the Tilemap."},
               "x":{"type":"number","description":"World x."},
               "y":{"type":"number","description":"World y (+Y up)."}}})json"),
         true, "scene"},
        [&I](const Json& a) {
            Entity e = need_entity(I.world, a);
            const Tilemap* tm = I.world.get<Tilemap>(e);
            if (!tm)
                throw CommandError("invalid_argument", "Entity '" + I.world.id_of(e) + "' has no Tilemap component",
                                   "Pass the id of the entity that holds the Tilemap (scene.import_ascii names it 'tilemap' by default).");
            const Vec3 local = I.world.world_matrix(e).inverse().transform_point({a["x"].get<float>(), a["y"].get<float>(), 0.0f});
            int col = 0, row = 0;
            if (!tilemap_cell_at_local(*tm, {local.x, local.y}, col, row))
                throw CommandError("invalid_argument", "The Tilemap on '" + I.world.id_of(e) + "' has no positive tileSize, so it has no cells",
                                   "Set Tilemap.tileSize to [width, height] in world units.");
            const TilemapSize size = tilemap_size(*tm);
            const bool inside = col >= 0 && row >= 0 && col < size.width && row < size.height;
            return Json::object({{"id", I.world.id_of(e)}, {"col", col}, {"row", row}, {"inside", inside},
                                 {"tile", inside ? tilemap_tile_at(*tm, size, col, row) : -1}});
        });

    I.commands.add(
        {"tilemap.cell_to_world",
         "The world position of the centre of a Tilemap cell (orthogonal squares or isometric diamonds).",
         "Returns {id, col, row, x, y} for the Tilemap on entity `id`: the world position of the centre of cell (`col`, `row`) "
         "(0-based, row 0 = TOP row), by the entity's world transform and the map's `projection`. The cell may lie outside the "
         "map. It is the inverse of tilemap.cell_at for the cell's centre; the script form is "
         "`entity.tilemap.cellToWorld(col, row)`. Example: tilemap.cell_to_world {\"id\":\"ground\",\"col\":3,\"row\":4}",
         parse_schema(R"json({"type":"object","required":["id","col","row"],"properties":{
               "id":{"type":"string","description":"Id (or name) of the entity that has the Tilemap."},
               "col":{"type":"integer","description":"Tile column, 0 = leftmost."},
               "row":{"type":"integer","description":"Tile row, 0 = TOP row."}}})json"),
         true, "scene"},
        [&I](const Json& a) {
            Entity e = need_entity(I.world, a);
            const Tilemap* tm = I.world.get<Tilemap>(e);
            if (!tm)
                throw CommandError("invalid_argument", "Entity '" + I.world.id_of(e) + "' has no Tilemap component",
                                   "Pass the id of the entity that holds the Tilemap (scene.import_ascii names it 'tilemap' by default).");
            const int col = a["col"].get<int>(), row = a["row"].get<int>();
            const Vec2 local = tilemap_cell_center(*tm, col, row);
            const Vec3 w = I.world.world_matrix(e).transform_point({local.x, local.y, 0.0f});
            return Json::object({{"id", I.world.id_of(e)}, {"col", col}, {"row", row}, {"x", w.x}, {"y", w.y}});
        });
}

}  // namespace fa
