// tilemap.split_cells: cuts the Tilemap of a scene file into a 2D streamed world (docs/BIG_WORLDS.md, "Tilemap chunks"): one
// chunk scene per cell of a square grid of `cellSize` tiles, and the index `<name>.world.json` that lists them. It works on
// the files (the scene is not loaded into the running world) and writes only new files: the source scene is never changed.
#include <algorithm>
#include <cmath>
#include <set>

#include "authoring_internal.h"
#include "fa/core/capability.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/scene/serialize.h"
#include "fa/scene/tilemap.h"
#include "fa/scene/world_index.h"

namespace fa {

namespace {

constexpr const char* kIndexSuffix = ".world.json";
constexpr int kMaxCellTiles = 4096;

[[noreturn]] void fail(const std::string& message, const std::string& hint, const char* code = "invalid_argument") {
    throw CommandError(code, message, hint);
}

bool ends_with(const std::string& s, const std::string& suffix) {
    return s.size() >= suffix.size() && s.compare(s.size() - suffix.size(), suffix.size(), suffix) == 0;
}

std::string project_path(const std::string& raw, const char* what) {
    if (raw.empty())
        fail(std::string("`") + what + "` is empty.", "Use a project-relative path such as scenes/level.scene.json.");
    auto norm = fs::normalize_checked(raw);
    if (!norm.ok()) fail(std::string("`") + what + "`: " + norm.error().message, norm.error().hint);
    if (fs::is_absolute(norm.value()))
        fail(std::string("`") + what + "` '" + raw + "' is an absolute path.",
             "Use a project-relative path such as worlds/level.world.json.");
    return norm.value();
}

double number_at(const Json& v, std::size_t i, double fallback) {
    return v.is_array() && i < v.size() && v[i].is_number() ? v[i].get<double>() : fallback;
}

// The Tilemap entity of the scene JSON: its pointer, and the entity.
struct Found {
    std::string pointer;
    const Json* entity = nullptr;
    bool nested = false;
};

void collect_tilemaps(const Json& list, const std::string& pointer, bool nested, std::vector<Found>& out) {
    if (!list.is_array()) return;
    for (std::size_t i = 0; i < list.size(); ++i) {
        const Json& e = list[i];
        if (!e.is_object()) continue;
        const std::string ptr = pointer + "/" + std::to_string(i);
        if (e.contains("components") && e["components"].is_object() && e["components"].contains("Tilemap"))
            out.push_back({ptr, &e, nested});
        if (e.contains("children")) collect_tilemaps(e["children"], ptr + "/children", true, out);
    }
}

struct ChunkPlan {
    int i = 0, j = 0;
    int w = 0, h = 0;        // tiles
    int col0 = 0, row0 = 0;  // first column and first (top) row of the source map
    std::string scene;
    std::vector<int> tiles;
    double minX = 0, minY = 0, maxX = 0, maxY = 0;
};

Json split_cells(Engine::Impl&, const Json& args) {
    const std::string scenePath = project_path(args.value("scene", std::string()), "scene");
    const std::int64_t cellTiles = args.value("cellSize", std::int64_t(32));
    if (cellTiles < 1 || cellTiles > kMaxCellTiles)
        fail("cellSize is " + std::to_string(cellTiles) + ": a cell is 1 to " + std::to_string(kMaxCellTiles) +
                 " tiles wide.",
             "Pass the number of TILES along one side of a cell, for example 32 (a 100x60 map then gives 4x2 cells).");
    const bool dryRun = args.value("dryRun", false);
    const bool overwrite = args.value("overwrite", false);
    std::string indexPath;
    if (args.contains("out") && args["out"].is_string()) {
        indexPath = project_path(args["out"].get<std::string>(), "out");
        if (!ends_with(indexPath, kIndexSuffix))
            fail("out '" + indexPath + "' does not end in " + kIndexSuffix + ".",
                 "Name the index like worlds/level.world.json; the chunk scenes go in a folder next to it "
                 "(worlds/level_cells/).");
    } else {
        indexPath = ends_with(scenePath, ".scene.json") ? scenePath.substr(0, scenePath.size() - 11) + kIndexSuffix
                                                        : scenePath + kIndexSuffix;
    }
    const std::string cellDir = indexPath.substr(0, indexPath.size() - std::string(kIndexSuffix).size()) + "_cells";

    // The scene file.
    auto text = fs::read_text(scenePath);
    if (!text.ok())
        fail("Cannot read scene '" + scenePath + "': " + text.error().message, text.error().hint, "not_found");
    auto parsed = parse_json(text.value(), scenePath);
    if (!parsed.ok()) fail(parsed.error().message, parsed.error().hint);
    const Json& scene = parsed.value();
    if (!scene.is_object() || !scene.contains("entities") || !scene["entities"].is_array())
        fail(scenePath + " has no \"entities\" array.", "Pass a *.scene.json file (a prefab has no scene to split).");

    std::vector<Found> maps;
    collect_tilemaps(scene["entities"], "/entities", false, maps);
    if (maps.empty())
        fail(scenePath + " has no entity with a Tilemap component.",
             "Add one with scene.import_ascii first, or pass another scene.");
    const std::string wanted = args.value("tilemap", std::string());
    const Found* pick = nullptr;
    if (!wanted.empty()) {
        std::vector<std::string> ids;
        for (const Found& f : maps) {
            const std::string id = f.entity->value("id", std::string());
            ids.push_back(id);
            if (id == wanted) pick = &f;
        }
        if (!pick)
            fail("The scene has no Tilemap entity with id '" + wanted + "'." + did_you_mean(wanted, ids),
                 "The Tilemap entities of " + scenePath + " are: " + join(ids, ", ") + ".");
    } else if (maps.size() == 1) {
        pick = &maps[0];
    } else {
        std::vector<std::string> ids;
        for (const Found& f : maps) ids.push_back(f.entity->value("id", f.pointer));
        fail("The scene has " + std::to_string(maps.size()) + " Tilemap entities (" + join(ids, ", ") +
                 "): which one to split?",
             "Pass `tilemap` with the id of one of them. Each map becomes its own world index.");
    }
    const Json& entity = *pick->entity;
    const std::string baseId = entity.value("id", std::string());
    if (baseId.empty())
        fail("The Tilemap entity at " + pick->pointer + " has no \"id\".",
             "Give it an id (the chunks are named <id>_<i>_<j>).");
    if (pick->nested)
        fail("The Tilemap entity '" + baseId + "' is a child (" + pick->pointer +
                 "): its position is relative to its parent.",
             "Move it to the top level of the scene (no parent), then split: chunks are placed at absolute positions.");
    if (entity.contains("prefab"))
        fail("The Tilemap entity '" + baseId + "' comes from a prefab.",
             "Save the scene expanded (scene.save) or edit it to inline the Tilemap first.");
    if (entity.contains("children") && entity["children"].is_array() && !entity["children"].empty())
        fail("The Tilemap entity '" + baseId + "' has children, which a split would lose.",
             "Move the children out to the scene top level first.");

    Json fields = entity["components"]["Tilemap"];
    if (!fields.is_object())
        fail("Tilemap of '" + baseId + "' is not an object.", "Write Tilemap as {\"tileset\": ..., \"tiles\": ...}.");
    {
        const std::vector<TilemapIssue> issues = flatten_tilemap_rows(fields);
        if (!issues.empty())
            fail(pick->pointer + "/components/Tilemap" + issues[0].pointer + ": " + issues[0].message, issues[0].hint);
    }
    const bool isometric =
        fields.contains("projection") && ((fields["projection"].is_string() && fields["projection"] == "Isometric") ||
                                          (fields["projection"].is_number() && fields["projection"] == 1));
    if (isometric)
        fail("Tilemap '" + baseId +
                 "' is isometric: its cells are diamonds, which do not line up on a square grid of chunks.",
             "Split only orthogonal maps. Cut an isometric map by hand into several Tilemap entities.");
    Tilemap tm;
    tm.width = fields.value("width", 0);
    tm.height = fields.value("height", 0);
    if (fields.contains("tileSize")) {
        tm.tileSize.x = float(number_at(fields["tileSize"], 0, 16));
        tm.tileSize.y = float(number_at(fields["tileSize"], 1, 16));
    }
    if (fields.contains("tiles")) set_tilemap_tiles(tm, fields["tiles"]);
    const TilemapGrid grid = tilemap_grid(tm);
    if (grid.empty())
        fail("Tilemap '" + baseId + "' has no tiles.",
             "Fill Tilemap.tiles (with width and height), or draw the map with scene.import_ascii.");
    if (!(tm.tileSize.x > 0.0f) || tm.tileSize.x != tm.tileSize.y)
        fail("Tilemap '" + baseId + "' has tileSize [" + std::to_string(tm.tileSize.x) + ", " +
                 std::to_string(tm.tileSize.y) +
                 "]: a streamed world has one square cell size, so the tiles must be square.",
             "Use a square tileSize (for example [16, 16]).");

    const Json& transform =
        entity["components"].contains("Transform") ? entity["components"]["Transform"] : Json::object();
    for (const char* key : {"rotation", "scale"}) {
        if (!transform.contains(key)) continue;
        const double want = std::string(key) == "scale" ? 1.0 : 0.0;
        for (std::size_t k = 0; k < 3; ++k)
            if (number_at(transform[key], k, want) != want)
                fail("Tilemap '" + baseId + "' has a Transform." + key + " that is not the identity.",
                     "Bake the rotation and scale into the map (tileSize) first: a chunk grid is axis-aligned and "
                     "unscaled.");
    }
    const double px = number_at(transform.contains("position") ? transform["position"] : Json(), 0, 0);
    const double py = number_at(transform.contains("position") ? transform["position"] : Json(), 1, 0);
    const double pz = number_at(transform.contains("position") ? transform["position"] : Json(), 2, 0);

    const double tile = double(tm.tileSize.x);
    const double cellSize = double(cellTiles) * tile;
    if (cellSize < kMinWorldCellSize || cellSize > kMaxWorldCellSize)
        fail("cellSize " + std::to_string(cellTiles) + " tiles of " + std::to_string(tile) + " is " +
                 std::to_string(cellSize) + " units: a cell is " + std::to_string(kMinWorldCellSize) + " to " +
                 std::to_string(kMaxWorldCellSize) + " units.",
             "Change cellSize (in tiles).");
    const std::int64_t W = grid.width, H = grid.height;
    const std::int64_t cols = (W + cellTiles - 1) / cellTiles, rows = (H + cellTiles - 1) / cellTiles;
    if (cols * rows > kMaxWorldCells)
        fail("The split would make " + std::to_string(cols * rows) + " cells (" + std::to_string(cols) + " x " +
                 std::to_string(rows) + "), over the " + std::to_string(kMaxWorldCells) + " an index holds.",
             "Use a bigger cellSize.");

    // The grid: cell [i, j] holds columns [i*N, ...) and the rows counted from the BOTTOM of the map (j = 0 is the bottom row of
    // chunks), because a 2D world's second axis is y, up. The index origin is the bottom-left corner of the map.
    const double originX = px, originY = py - double(H) * tile;
    std::vector<ChunkPlan> plans;
    std::int64_t emptyCells = 0;
    for (std::int64_t j = 0; j < rows; ++j) {
        for (std::int64_t i = 0; i < cols; ++i) {
            ChunkPlan c;
            c.i = int(i);
            c.j = int(j);
            const std::int64_t colA = i * cellTiles, colB = std::min(W, colA + cellTiles);
            const std::int64_t rbA = j * cellTiles, rbB = std::min(H, rbA + cellTiles);  // from the bottom, [rbA, rbB)
            c.w = int(colB - colA);
            c.h = int(rbB - rbA);
            c.col0 = int(colA);
            c.row0 = int(H - rbB);  // the top row of the chunk in the source map
            c.tiles.resize(std::size_t(c.w) * std::size_t(c.h));
            bool any = false;
            for (int r = 0; r < c.h; ++r)
                for (int q = 0; q < c.w; ++q) {
                    const int v = grid.at(c.col0 + q, c.row0 + r);
                    c.tiles[std::size_t(r) * std::size_t(c.w) + std::size_t(q)] = v;
                    if (v >= 0) any = true;
                }
            if (!any) {
                ++emptyCells;
                continue;
            }
            const double cellMinX = originX + double(i) * cellSize, cellMinY = originY + double(j) * cellSize;
            c.minX = cellMinX;
            c.minY = cellMinY;
            c.maxX = std::min(cellMinX + double(c.w) * tile, cellMinX + cellSize);
            c.maxY = std::min(cellMinY + double(c.h) * tile, cellMinY + cellSize);
            c.scene = cellDir + "/" + std::to_string(i) + "_" + std::to_string(j) + ".scene.json";
            plans.push_back(std::move(c));
        }
    }
    if (plans.empty())
        fail("Every tile of '" + baseId + "' is empty: there is nothing to put in a cell.", "Paint some tiles first.");

    Json indexJson = Json::object();
    {
        indexJson["format"] = kWorldIndexFormat;
        indexJson["version"] = 1;
        indexJson["dimension"] = "2d";
        indexJson["cellSize"] = cellSize;
        indexJson["origin"] = Json::array({originX, originY});
        Json cells = Json::array();
        for (const ChunkPlan& c : plans) {
            Json cell = Json::object();
            cell["coord"] = Json::array({c.i, c.j});
            cell["scene"] = c.scene;
            cell["bounds"] =
                Json::object({{"min", Json::array({c.minX, c.minY})}, {"max", Json::array({c.maxX, c.maxY})}});
            cells.push_back(std::move(cell));
        }
        indexJson["cells"] = std::move(cells);
    }
    {  // what is written must be an index the engine accepts
        WorldIndexOptions options;
        options.checkFiles = false;
        auto check = parse_world_index(indexJson, indexPath, options);
        if (!check.ok())
            fail("The index this split would write is not valid: " + check.error().message, check.error().hint,
                 "internal");
    }

    std::vector<std::string> clashes;
    if (!overwrite) {
        if (fs::exists(indexPath)) clashes.push_back(indexPath);
        for (const ChunkPlan& c : plans)
            if (clashes.size() < 5 && fs::exists(c.scene)) clashes.push_back(c.scene);
    }
    if (!clashes.empty())
        fail("'" + clashes[0] + "' already exists" +
                 (clashes.size() > 1 ? " (and " + std::to_string(clashes.size() - 1) + "+ more)" : "") + ".",
             "Pass \"overwrite\": true to replace the files of an earlier split, or \"out\" with another index path. "
             "Nothing was written.",
             "exists");

    std::vector<std::string> written;
    if (!dryRun) {
        for (const ChunkPlan& c : plans) {
            Json chunk = entity;
            chunk["id"] = baseId + "_" + std::to_string(c.i) + "_" + std::to_string(c.j);
            Json& comps = chunk["components"];
            Json f = fields;
            f["width"] = c.w;
            f["height"] = c.h;
            f["tiles"] = c.tiles;
            comps["Tilemap"] = std::move(f);
            Json tr =
                comps.contains("Transform") && comps["Transform"].is_object() ? comps["Transform"] : Json::object();
            tr["position"] = Json::array({c.minX, c.maxY, pz});  // the TOP-left corner of the chunk
            comps["Transform"] = std::move(tr);
            Json file = Json::object({{"format", "factoria.scene/1"}, {"entities", Json::array({chunk})}});
            auto w = save_scene_json_file(c.scene, file);
            if (!w.ok())
                fail("Cannot write '" + c.scene + "': " + w.error().message + " (" + std::to_string(written.size()) +
                         " files were written before it).",
                     w.error().hint, "write_failed");
            written.push_back(c.scene);
        }
        auto w = fs::write_text(indexPath, dump_json(indexJson));
        if (!w.ok()) fail("Cannot write '" + indexPath + "': " + w.error().message, w.error().hint, "write_failed");
        written.push_back(indexPath);
    }

    Json cellList = Json::array();
    for (const ChunkPlan& c : plans) {
        if (cellList.size() >= 1000) break;
        cellList.push_back(
            Json::object({{"coord", Json::array({c.i, c.j})}, {"scene", c.scene}, {"width", c.w}, {"height", c.h}}));
    }
    Json notes = Json::array();
    notes.push_back("The source scene was not changed: remove the Tilemap entity '" + baseId +
                    "' from it and add an entity with StreamedWorld {\"world\": \"" + indexPath +
                    "\"} and a StreamingAnchor on the player.");
    if (fields.contains("terrains") && fields["terrains"].is_array() && !fields["terrains"].empty())
        notes.push_back("The autotile tiles are already in the chunks; painting a terrain with tilemap.paint_terrain "
                        "inside one chunk does not look at the neighbour chunk's tiles across the border.");
    Json out = Json::object();
    out["index"] = indexPath;
    out["dryRun"] = dryRun;
    out["dimension"] = "2d";
    out["cellSizeTiles"] = cellTiles;
    out["cellSize"] = cellSize;
    out["origin"] = Json::array({originX, originY});
    out["mapTiles"] = Json::array({W, H});
    out["cellGrid"] = Json::array({cols, rows});
    out["cells"] = std::int64_t(plans.size());
    out["emptyCellsSkipped"] = emptyCells;
    out["files"] = std::int64_t(plans.size()) + 1;
    out["written"] = dryRun ? 0 : std::int64_t(written.size());
    out["cellList"] = std::move(cellList);
    out["notes"] = std::move(notes);
    return out;
}

}  // namespace

void register_tilemap_split_commands(Engine& engine, Engine::Impl& I) {
    (void)engine;
    I.commands.add({"tilemap.split_cells",
                    "Cut the Tilemap of a scene into a streamed 2D world: one chunk scene per cell and an index.",
                    "Reads a scene file, takes its Tilemap entity (top level, orthogonal, square tiles, no rotation or "
                    "scale) and writes a 2D "
                    "world index `<out>` (`dimension` \"2d\") plus one scene per non-empty cell in `<out without "
                    ".world.json>_cells/<i>_<j>.scene.json`. "
                    "A cell is `cellSize` x `cellSize` TILES of the map: cell [i, j] holds the columns from i * "
                    "cellSize and the rows counted from the "
                    "BOTTOM of the map from j * cellSize (the last cell of a row or column is smaller when the map "
                    "does not divide). Details: docs/BIG_WORLDS.md, \"Tilemap chunks\". " FA_COMMAND_DETAILS
                    "Each chunk is "
                    "an entity `<id>_<i>_<j>` with the same Tilemap fields (tileset, tileSize, solidTiles, terrains, "
                    "layer, light fields...) and the "
                    "other components of the source entity, placed at its ABSOLUTE top-left corner, so neighbouring "
                    "chunks touch exactly; the index "
                    "`origin` is the map's bottom-left corner and the `bounds` of each cell are the chunk's rectangle. "
                    "Cells with only empty tiles are "
                    "not written. The output is deterministic (the same scene gives the same bytes) and the source "
                    "scene is never changed: remove "
                    "the Tilemap entity and add a StreamedWorld entity yourself (the result's `notes` say what). "
                    "Existing files are only replaced "
                    "with `overwrite`. `dryRun` reports without writing. Result: {index, cells, cellGrid, "
                    "emptyCellsSkipped, files, written, "
                    "cellList, notes}. "
                    "Example: tilemap.split_cells "
                    "{\"scene\":\"scenes/level.scene.json\",\"cellSize\":32,\"out\":\"worlds/level.world.json\"}",
                    parse_json(R"({"type":"object","properties":{
           "scene":{"type":"string","description":"The scene file with the Tilemap (project-relative *.scene.json)."},
           "tilemap":{"type":"string","description":"Id of the Tilemap entity; optional when the scene has only one."},
           "cellSize":{"type":"integer","minimum":1,"maximum":4096,"default":32,"description":"Tiles along one side of a cell."},
           "out":{"type":"string","description":"The index file to write, ending in .world.json (default: next to the scene, named after it)."},
           "overwrite":{"type":"boolean","default":false,"description":"Replace files of an earlier split. Without it an existing file is an error and nothing is written."},
           "dryRun":{"type":"boolean","default":false,"description":"Only report what would be written."}},"required":["scene"]})",
                               "command schema")
                        .value(),
                    false, "world"},
                   [&I](const Json& a) { return split_cells(I, a); });
    declare_command_capabilities(I.commands, {{"tilemap.split_cells", capability_sets::edits_project()}});
}

}  // namespace fa
