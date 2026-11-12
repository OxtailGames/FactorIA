// Autotile commands of a Tilemap: tilemap.paint_terrain, tilemap.retile, tilemap.terrains, tilemap.set_terrains. The rules and
// the painting live in fa/scene/autotile.h; these are the command forms of entity.tilemap.paintTerrain / retile / terrains.
#include <algorithm>
#include <cmath>
#include <set>

#include "engine_impl.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/scene/autotile.h"

namespace fa {

namespace {

constexpr const char* kTerrainFormat = "factoria.terrains/1";
constexpr std::size_t kMaxCells = 4'000'000;
constexpr std::size_t kMaxChangesListed = 200;

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

[[noreturn]] void bad_arg(const std::string& message, const std::string& hint = {}) {
    throw CommandError("invalid_argument", message, hint);
}

Tilemap& need_tilemap(Engine::Impl& I, const Json& a, Entity& e) {
    e = need_entity(I.world, a);
    Tilemap* tm = I.world.get<Tilemap>(e);
    if (!tm)
        throw CommandError("invalid_argument", "Entity '" + I.world.id_of(e) + "' has no Tilemap component",
                           "Pass the id of the entity that holds the Tilemap (scene.import_ascii names it 'tilemap' by default).");
    return *tm;
}

bool cell_pair(const Json& j, int& col, int& row) {
    auto num = [](const Json& v, int& out) {
        if (!v.is_number() || v.get<double>() != std::floor(v.get<double>()) || std::fabs(v.get<double>()) > 1e9) return false;
        out = v.get<int>();
        return true;
    };
    if (j.is_array() && j.size() == 2) return num(j[0], col) && num(j[1], row);
    if (j.is_object() && j.contains("col") && j.contains("row")) return num(j["col"], col) && num(j["row"], row);
    return false;
}

// `cells` ([[col,row],...] or [{col,row},...]) and/or `rect` ({col,row,width,height}) of a call, in order.
std::vector<std::pair<int, int>> read_cells(const Json& a) {
    std::vector<std::pair<int, int>> cells;
    if (a.contains("cells")) {
        if (!a["cells"].is_array()) bad_arg("cells must be an array of [col, row] pairs", "Example: \"cells\": [[3, 4], [4, 4]].");
        for (std::size_t i = 0; i < a["cells"].size(); ++i) {
            int c = 0, r = 0;
            if (!cell_pair(a["cells"][i], c, r))
                bad_arg("cells[" + std::to_string(i) + "] is " + describe_json_value(a["cells"][i]) + ", not a [col, row] pair",
                        "Each cell is [col, row] (whole numbers, row 0 = TOP row) or {\"col\": 3, \"row\": 4}.");
            cells.push_back({c, r});
        }
    }
    if (a.contains("rect")) {
        const Json& rc = a["rect"];
        int c = 0, r = 0, w = 0, h = 0;
        auto num = [&](const char* key, int& out) {
            if (!rc.is_object() || !rc.contains(key) || !rc[key].is_number() || rc[key].get<double>() != std::floor(rc[key].get<double>()))
                bad_arg(std::string("rect needs a whole number \"") + key + "\"", "Example: \"rect\": {\"col\": 2, \"row\": 3, \"width\": 5, \"height\": 4}.");
            out = rc[key].get<int>();
        };
        num("col", c);
        num("row", r);
        num("width", w);
        num("height", h);
        if (w < 0 || h < 0) bad_arg("rect width and height cannot be negative", "Example: \"rect\": {\"col\": 2, \"row\": 3, \"width\": 5, \"height\": 4}.");
        if (std::size_t(w) * std::size_t(h) + cells.size() > kMaxCells)
            bad_arg("rect covers " + std::to_string(w) + " x " + std::to_string(h) + " cells, more than " + std::to_string(kMaxCells), "Paint a smaller rectangle.");
        for (int rr = r; rr < r + h; ++rr)
            for (int cc = c; cc < c + w; ++cc) cells.push_back({cc, rr});
    }
    if (cells.empty()) bad_arg("Give the cells to paint: \"cells\" (a list of [col, row]) and/or \"rect\"", "Example: tilemap.paint_terrain {\"id\":\"map\",\"terrain\":\"grass\",\"rect\":{\"col\":0,\"row\":0,\"width\":4,\"height\":3}}");
    return cells;
}

Json result_json(const std::string& id, const TerrainPaintResult& r) {
    Json changes = Json::array();
    for (std::size_t i = 0; i < r.changes.size() && i < kMaxChangesListed; ++i)
        changes.push_back(Json::object({{"col", r.changes[i].col}, {"row", r.changes[i].row}, {"from", r.changes[i].from}, {"to", r.changes[i].to}}));
    return Json::object({{"id", id}, {"painted", r.painted}, {"outside", r.outside}, {"changed", r.changes.size()}, {"changes", changes},
                         {"changesTruncated", r.changes.size() > kMaxChangesListed}});
}

[[noreturn]] void throw_error(const Error& e) { throw CommandError("invalid_argument", e.message, e.hint); }

}  // namespace

void register_terrain_commands(Engine&, Engine::Impl& I) {
    I.commands.add(
        {"tilemap.paint_terrain",
         "Paint (or erase) a terrain on a Tilemap's cells and re-tile the cells around them with its autotile rules.",
         "Sets the cells to the terrain `terrain` of the Tilemap on entity `id` (rules in Tilemap.terrains) and re-tiles them and "
         "the 8 cells around each one, so the edge, corner and inside tiles line up: paint a lake and the shore appears. Name the "
         "cells with `cells` ([[col, row], ...], row 0 = TOP row) and/or `rect` ({col, row, width, height}). `erase` true empties "
         "the cells instead (-1) and re-tiles what was next to them. Cells outside the map are skipped and counted in `outside`. "
         "Only cells that already belong to a terrain are re-tiled: tiles you placed by hand stay. A terrain cell's tile is "
         "picked from the terrain's variations by column, row and seed, so the same painting always looks the same. Changes the "
         "RUNNING world only (scene.save keeps it); the script form is `entity.tilemap.paintTerrain(terrain, cells)`. Returns "
         "{id, painted, outside, changed, changes: [{col, row, from, to}] (the first 200), changesTruncated}. "
         "Example: tilemap.paint_terrain {\"id\":\"map\",\"terrain\":\"grass\",\"rect\":{\"col\":2,\"row\":2,\"width\":5,\"height\":3}}",
         parse_schema(R"json({"type":"object","required":["id","terrain"],"properties":{
               "id":{"type":"string","description":"Id (or name) of the entity that has the Tilemap."},
               "terrain":{"type":"string","description":"Name of a terrain in Tilemap.terrains."},
               "cells":{"type":"array","description":"Cells to paint: [col, row] pairs (or {col, row} objects), row 0 = TOP row.","items":{}},
               "rect":{"type":"object","description":"A block of cells to paint: {col, row, width, height}.","properties":{
                   "col":{"type":"integer"},"row":{"type":"integer"},"width":{"type":"integer","minimum":0},"height":{"type":"integer","minimum":0}}},
               "erase":{"type":"boolean","default":false,"description":"Empty the cells (-1) instead of painting the terrain, and re-tile their neighbours."}}})json"),
         false, "scene"},
        [&I](const Json& a) {
            Entity e;
            Tilemap& tm = need_tilemap(I, a, e);
            if (!a.contains("terrain") || !a["terrain"].is_string()) bad_arg("terrain must be the name of a terrain", "See tilemap.terrains for the names of this map.");
            const auto cells = read_cells(a);
            auto r = paint_terrain(tm, a["terrain"].get<std::string>(), cells, a.value("erase", false));
            if (!r.ok()) throw_error(r.error());
            Json out = result_json(I.world.id_of(e), *r);
            out["terrain"] = a["terrain"];
            out["erase"] = a.value("erase", false);
            return out;
        });

    I.commands.add(
        {"tilemap.retile",
         "Re-tile every terrain cell of a Tilemap from its neighbours.",
         "Recomputes the tile of every cell that belongs to a terrain of the Tilemap on entity `id` from the cells around it, with "
         "the terrain's rules (Tilemap.terrains). Use it after writing `tiles` by hand, after tilemap.set_terrains with new rules, "
         "or after resizing the map. Cells that belong to no terrain are not touched. Changes the RUNNING world only. "
         "Returns {id, changed, changes (the first 200), changesTruncated}. Example: tilemap.retile {\"id\":\"map\"}",
         parse_schema(R"json({"type":"object","required":["id"],"properties":{
               "id":{"type":"string","description":"Id (or name) of the entity that has the Tilemap."}}})json"),
         false, "scene"},
        [&I](const Json& a) {
            Entity e;
            Tilemap& tm = need_tilemap(I, a, e);
            auto r = retile_terrains(tm);
            if (!r.ok()) throw_error(r.error());
            return result_json(I.world.id_of(e), *r);
        });

    I.commands.add(
        {"tilemap.terrains",
         "The autotile rules of a Tilemap: its terrains, their slots and how many cells belong to each.",
         "Reads Tilemap.terrains of the entity `id` and returns {id, valid, issues, terrains: [{name, mode, seed, tiles (the "
         "count), slots: [{slot, mask, tiles}], cells (how many map cells belong to it)}]}. `mask` is the neighbour mask the slot "
         "draws (N=1 NE=2 E=4 SE=8 S=16 SW=32 W=64 NW=128). `issues` lists every problem of the rules with its JSON pointer and "
         "the fix. Example: tilemap.terrains {\"id\":\"map\"}",
         parse_schema(R"json({"type":"object","required":["id"],"properties":{
               "id":{"type":"string","description":"Id (or name) of the entity that has the Tilemap."}}})json"),
         true, "scene"},
        [&I](const Json& a) {
            Entity e;
            Tilemap& tm = need_tilemap(I, a, e);
            Json issues = Json::array();
            for (const TilemapIssue& i : check_terrains(tm.terrains))
                issues.push_back(Json::object({{"pointer", i.pointer}, {"message", i.message}, {"hint", i.hint}}));
            Json list = Json::array();
            auto parsed = parse_terrains(tm.terrains);
            if (parsed.ok()) {
                const TilemapGrid grid = tilemap_grid(tm);
                for (const Terrain& t : *parsed) {
                    Json slots = Json::array();
                    const auto& masks = autotile_masks(t.mode);
                    int cells = 0;
                    for (std::size_t s = 0; s < t.slots.size(); ++s)
                        slots.push_back(Json::object({{"slot", s}, {"mask", masks[s]}, {"tiles", Json(t.slots[s])}}));
                    std::set<int> own;
                    for (const auto& slot : t.slots)
                        for (int v : slot) own.insert(tile_index(v));
                    for (int v : grid.tiles)
                        if (v >= 0 && own.count(tile_index(v))) ++cells;
                    list.push_back(Json::object({{"name", t.name}, {"mode", autotile_mode_name(t.mode)}, {"seed", t.seed}, {"tiles", t.slots.size()},
                                                 {"joins", Json(t.joins)}, {"outside", t.outsideIsTerrain ? "terrain" : "empty"}, {"slots", slots}, {"cells", cells}}));
                }
            }
            return Json::object({{"id", I.world.id_of(e)}, {"valid", issues.empty()}, {"issues", issues}, {"terrains", list}});
        });

    I.commands.add(
        {"tilemap.set_terrains",
         "Set a Tilemap's autotile rules from a list or a rules file (as image.tileset.build writes them).",
         "Replaces Tilemap.terrains of the entity `id` with `terrains` (an array of terrain objects) or with the `terrains` of the "
         "rules file `path` (a JSON file {\"format\": \"" + std::string(kTerrainFormat) + "\", \"terrains\": [...]}, such as the "
         ".terrains.json that image.tileset.build writes next to the tileset). The rules are checked first: a bad rule changes "
         "nothing and the error names its JSON pointer and the fix. `retile` true also re-tiles the map with the new rules. "
         "Changes the RUNNING world only (scene.save keeps it). Returns {id, terrains: [names], retiled}. "
         "Example: tilemap.set_terrains {\"id\":\"map\",\"path\":\"assets/art/ground.terrains.json\",\"retile\":true}",
         parse_schema(R"json({"type":"object","required":["id"],"properties":{
               "id":{"type":"string","description":"Id (or name) of the entity that has the Tilemap."},
               "terrains":{"type":"array","description":"Terrain objects: {name, mode: basic16|blob47, first | tiles, seed?, joins?, outside?}. See the Tilemap component's `terrains` field.","items":{"type":"object"}},
               "path":{"type":"string","description":"Project-relative path of a rules file ({format, terrains}). Instead of `terrains`."},
               "retile":{"type":"boolean","default":false,"description":"Re-tile every terrain cell with the new rules."}}})json"),
         false, "scene"},
        [&I](const Json& a) {
            Entity e;
            Tilemap& tm = need_tilemap(I, a, e);
            if (a.contains("terrains") == a.contains("path")) bad_arg("Give either `terrains` (an array) or `path` (a rules file), not both and not neither", "Example: tilemap.set_terrains {\"id\":\"map\",\"path\":\"assets/art/ground.terrains.json\"}");
            Json rules;
            if (a.contains("path")) {
                if (!a["path"].is_string()) bad_arg("path must be a project-relative file path");
                const std::string path = a["path"].get<std::string>();
                auto text = fs::read_text(path);
                if (!text.ok()) bad_arg("Cannot read the rules file '" + path + "': " + text.error().message, "Write it with image.tileset.build, or check the path.");
                auto doc = parse_json(*text, path);
                if (!doc.ok()) bad_arg(doc.error().message, doc.error().hint);
                if (!doc->is_object() || !doc->contains("terrains"))
                    bad_arg("'" + path + "' is not a rules file: it has no \"terrains\" array", "A rules file is {\"format\": \"" + std::string(kTerrainFormat) + "\", \"terrains\": [...]}.");
                rules = (*doc)["terrains"];
            } else {
                rules = a["terrains"];
            }
            auto parsed = parse_terrains(rules);
            if (!parsed.ok()) throw_error(parsed.error());
            tm.terrains = rules;
            bool retiled = false;
            if (a.value("retile", false) && !parsed->empty()) {
                auto r = retile_terrains(tm);
                if (!r.ok()) throw_error(r.error());
                retiled = true;
            }
            Json names = Json::array();
            for (const Terrain& t : *parsed) names.push_back(t.name);
            return Json::object({{"id", I.world.id_of(e)}, {"terrains", names}, {"retiled", retiled}});
        });

    // Capabilities (capability.h): what each command does outside the engine's memory.
    declare_command_capabilities(I.commands, {
        {"tilemap.paint_terrain", capability_sets::changes_state()},
        {"tilemap.retile", capability_sets::changes_state()},
        {"tilemap.set_terrains", capability_sets::changes_state()},
        {"tilemap.terrains", capability_sets::reads()},
    });
}

}  // namespace fa
