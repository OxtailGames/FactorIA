// project.validate: the world indexes (*.world.json, docs/BIG_WORLDS.md "Streaming") of the project: every one is read with
// load_world_index and EVERY cell's scene file is checked (the runtime streamer skips that check on a very big index).
#include <algorithm>
#include <cmath>
#include <filesystem>

#include "assets_internal.h"
#include "fa/core/fs.h"
#include "fa/scene/tilemap.h"
#include "fa/scene/world_index.h"
#include "fa/tooling/validate.h"

namespace fa::assets_detail {

namespace {

constexpr const char* kWorldIndexSuffix = ".world.json";

bool ends_with_suffix(const std::string& name) {
    const std::string suffix = kWorldIndexSuffix;
    return name.size() > suffix.size() && name.compare(name.size() - suffix.size(), suffix.size(), suffix) == 0;
}

std::vector<std::string> list_world_indexes(const std::string& projectDir) {
    std::vector<std::string> out;
    const stdfs::path root = fs::path_from_utf8(projectDir);
    std::error_code ec;
    for (stdfs::recursive_directory_iterator it(root, stdfs::directory_options::skip_permission_denied, ec), end;
         !ec && it != end; it.increment(ec)) {
        const std::string name = fs::path_to_utf8(it->path().filename());
        const std::string rel = fs::path_to_utf8(it->path().lexically_relative(root));
        std::error_code e2;
        if (it->is_directory(e2)) {
            if ((!name.empty() && name[0] == '.') || name == "node_modules" || rel == "build")
                it.disable_recursion_pending();
            continue;
        }
        if (ends_with_suffix(name)) out.push_back(rel);
    }
    std::sort(out.begin(), out.end());
    return out;
}

// The chunks of a 2D index (docs/BIG_WORLDS.md, "Tilemap chunks"): the Tilemap entities of the cell scenes must be one map cut in
// pieces: the same tileset, tile size and tile layout, and positions on one tile grid. A chunk that sticks out of its cell is a
// warning (it would draw over its neighbour's tiles). At most this many cells are read (a deterministic cap, never a time limit).
constexpr std::size_t kMaxChunkChecks = 4096;

struct ChunkSeed {
    bool have = false;
    std::string file;
    Json tileset, columns, margin, spacing, projection;
    double tileW = 0, tileH = 0, x = 0, y = 0;
};

double num_at(const Json& v, std::size_t i, double fallback) {
    return v.is_array() && i < v.size() && v[i].is_number() ? v[i].get<double>() : fallback;
}

void check_tilemap_chunks(const std::string& rel, const WorldIndex& index, std::vector<ValidationIssue>& errors,
                          std::vector<ValidationIssue>& warnings) {
    auto raw = load_json_file(rel);
    if (!raw.ok() || !raw.value().contains("cells") || !raw.value()["cells"].is_array()) return;
    const Json& cells = raw.value()["cells"];
    if (cells.size() > kMaxChunkChecks) {
        warnings.push_back({rel, "/cells",
                            "The tilemap chunks of this index were not compared: it has " +
                                std::to_string(cells.size()) + " cells and only the first " +
                                std::to_string(kMaxChunkChecks) + " are read.",
                            "Split the world into several indexes, or check a few cells by hand."});
    }
    ChunkSeed seed;
    const std::size_t count = std::min(cells.size(), kMaxChunkChecks);
    for (std::size_t k = 0; k < count; ++k) {
        const Json& c = cells[k];
        if (!c.is_object() || !c.contains("scene") || !c["scene"].is_string() || !c.contains("coord") ||
            !c["coord"].is_array() || c["coord"].size() != 2 || !c["coord"][0].is_number_integer() ||
            !c["coord"][1].is_number_integer())
            continue;
        const std::string scenePath = c["scene"].get<std::string>();
        const std::string ptr = "/cells/" + std::to_string(k) + "/scene";
        auto scene = load_json_file(scenePath);
        if (!scene.ok() || !scene.value().is_object() || !scene.value().contains("entities") ||
            !scene.value()["entities"].is_array())
            continue;  // a missing or broken file is reported by the index check and by the scene check
        const double cellMinX = index.originA + double(c["coord"][0].get<std::int64_t>()) * index.cellSize;
        const double cellMinY = index.originB + double(c["coord"][1].get<std::int64_t>()) * index.cellSize;
        for (const Json& e : scene.value()["entities"]) {
            if (!e.is_object() || !e.contains("components") || !e["components"].is_object() ||
                !e["components"].contains("Tilemap") || !e["components"]["Tilemap"].is_object())
                continue;
            Json f = e["components"]["Tilemap"];
            const Json empty = Json::object();
            const Json& tr = e["components"].contains("Transform") && e["components"]["Transform"].is_object()
                                 ? e["components"]["Transform"]
                                 : empty;
            const double x = num_at(tr.contains("position") ? tr["position"] : Json(), 0, 0);
            const double y = num_at(tr.contains("position") ? tr["position"] : Json(), 1, 0);
            const double tw = num_at(f.contains("tileSize") ? f["tileSize"] : Json(), 0, 16);
            const double th = num_at(f.contains("tileSize") ? f["tileSize"] : Json(), 1, 16);
            auto get = [&f](const char* key) { return f.contains(key) ? f[key] : Json(); };
            if (!seed.have) {
                seed = {true,
                        scenePath,
                        get("tileset"),
                        get("columns"),
                        get("margin"),
                        get("spacing"),
                        get("projection"),
                        tw,
                        th,
                        x,
                        y};
            } else {
                auto differs = [&](const char* what, const Json& a, const Json& b) {
                    if (a == b) return false;
                    errors.push_back({rel, ptr,
                                      std::string("The tilemap chunk in '") + scenePath + "' has a different " + what +
                                          " (" + b.dump() + ") than the chunk in '" + seed.file + "' (" + a.dump() +
                                          "): the chunks of one world must look the same.",
                                      std::string("Make Tilemap.") + what +
                                          " the same in every chunk; tilemap.split_cells writes them equal."});
                    return true;
                };
                bool bad = differs("tileset", seed.tileset, get("tileset"));
                bad = differs("columns", seed.columns, get("columns")) || bad;
                bad = differs("margin", seed.margin, get("margin")) || bad;
                bad = differs("spacing", seed.spacing, get("spacing")) || bad;
                bad = differs("projection", seed.projection, get("projection")) || bad;
                if (std::abs(tw - seed.tileW) > 1e-6 || std::abs(th - seed.tileH) > 1e-6) {
                    errors.push_back({rel, ptr,
                                      "The tilemap chunk in '" + scenePath + "' has tileSize [" + std::to_string(tw) +
                                          ", " + std::to_string(th) + "] but the chunk in '" + seed.file + "' has [" +
                                          std::to_string(seed.tileW) + ", " + std::to_string(seed.tileH) +
                                          "]: the chunks would not line up.",
                                      "Use one tileSize in every chunk."});
                    bad = true;
                }
                if (!bad && seed.tileW > 0 && seed.tileH > 0) {
                    const double gx = (x - seed.x) / seed.tileW, gy = (y - seed.y) / seed.tileH;
                    if (std::abs(gx - std::round(gx)) > 1e-3 || std::abs(gy - std::round(gy)) > 1e-3)
                        errors.push_back({rel, ptr,
                                          "The tilemap chunk in '" + scenePath + "' is at [" + std::to_string(x) +
                                              ", " + std::to_string(y) + "], not on the tile grid of the chunk in '" +
                                              seed.file + "' (at [" + std::to_string(seed.x) + ", " +
                                              std::to_string(seed.y) + "], tiles of " + std::to_string(seed.tileW) +
                                              "): a seam or an overlap would show.",
                                          "Place every chunk at a whole number of tiles from the others "
                                          "(Transform.position); tilemap.split_cells does."});
                }
            }
            // Does it stay inside its cell?
            Tilemap tm;
            if (flatten_tilemap_rows(f).empty() && f.contains("tiles")) {
                tm.width = f.value("width", 0);
                tm.height = f.value("height", 0);
                set_tilemap_tiles(tm, f["tiles"]);
            }
            const TilemapSize size = tilemap_size(tm);
            const double eps = 1e-3 * std::max(tw, th);
            if (!size.empty() && (x < cellMinX - eps || y > cellMinY + index.cellSize + eps ||
                                  x + double(size.width) * tw > cellMinX + index.cellSize + eps ||
                                  y - double(size.height) * th < cellMinY - eps))
                warnings.push_back({rel, ptr,
                                    "The tilemap chunk in '" + scenePath + "' covers x " + std::to_string(x) + " to " +
                                        std::to_string(x + double(size.width) * tw) + ", y " +
                                        std::to_string(y - double(size.height) * th) + " to " + std::to_string(y) +
                                        ", which sticks out of its cell (" + std::to_string(cellMinX) + ", " +
                                        std::to_string(cellMinY) + ", " + std::to_string(index.cellSize) + " wide).",
                                    "Cut the map on the cell borders (tilemap.split_cells), or the chunk draws and "
                                    "collides over its neighbour."});
        }
    }
}

}  // namespace

void check_world_indexes(const std::string& projectDir, std::vector<ValidationIssue>& errors,
                         std::vector<ValidationIssue>& warnings) {
    const std::vector<std::string> files = list_world_indexes(projectDir);
    if (files.empty()) return;
    ProjectRootGuard root(projectDir);
    for (const std::string& rel : files) {
        std::vector<WorldIndexIssue> issues;
        WorldIndexOptions options;  // checkFiles on, no cap
        auto index = load_world_index(rel, options, &issues);
        if (issues.empty() && !index.ok()) {  // not readable or not JSON: the one message
            errors.push_back({rel, "", index.error().message,
                              index.error().hint.empty() ? "Fix the file (docs/BIG_WORLDS.md \"Streaming\", "
                                                           "schemas/world.schema.json)."
                                                         : index.error().hint});
            continue;
        }
        if (index.ok() && index.value().dimension == WorldDimension::D2)
            check_tilemap_chunks(rel, index.value(), errors, warnings);
        for (const WorldIndexIssue& issue : issues) {
            ValidationIssue v{rel, issue.pointer, issue.message,
                              issue.hint.empty() ? "See docs/BIG_WORLDS.md \"Streaming\" and schemas/world.schema.json."
                                                 : issue.hint};
            (issue.error ? errors : warnings).push_back(std::move(v));
        }
    }
}

}  // namespace fa::assets_detail
