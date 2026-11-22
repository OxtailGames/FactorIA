#include "fa/scene/world_index.h"

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <format>
#include <map>
#include <utility>

#include "fa/core/fs.h"
#include "fa/core/strings.h"

namespace fa {

namespace {

constexpr std::size_t kMaxListedIssues = 8;
constexpr std::size_t kMaxFileHints =
    20;  // "did you mean" is computed for this many missing files, the rest only say it is missing

std::string num(double v) { return std::format("{:g}", v); }

void add(std::vector<WorldIndexIssue>& out, bool error, std::string pointer, std::string message, std::string hint) {
    out.push_back({error, std::move(pointer), std::move(message), std::move(hint)});
}

bool finite_number(const Json& v) { return v.is_number() && std::isfinite(v.get<double>()); }

// [a, b] or [a, b, c]: reads `n` finite numbers or reports why not.
bool read_numbers(std::vector<WorldIndexIssue>& out, const Json& v, const std::string& pointer, std::size_t n,
                  const std::string& what, const std::string& example, double* dst) {
    if (!v.is_array() || v.size() != n) {
        add(out, true, pointer,
            what + " must be an array of " + std::to_string(n) + " numbers, got " + describe_json_value(v),
            "Example: " + example + ".");
        return false;
    }
    for (std::size_t k = 0; k < n; ++k) {
        if (!finite_number(v[k])) {
            add(out, true, pointer + "/" + std::to_string(k),
                what + " has " + describe_json_value(v[k]) + " where a number belongs", "Example: " + example + ".");
            return false;
        }
        dst[k] = v[k].get<double>();
    }
    return true;
}

}  // namespace

const WorldCell* WorldIndex::find(std::int32_t i, std::int32_t j) const {
    auto it = std::lower_bound(cells.begin(), cells.end(), std::make_pair(j, i),
                               [](const WorldCell& c, const std::pair<std::int32_t, std::int32_t>& key) {
                                   return std::make_pair(c.j, c.i) < key;
                               });
    return it != cells.end() && it->i == i && it->j == j ? &*it : nullptr;
}

double WorldIndex::distance_to(const WorldCell& cell, double a, double b) const {
    const double minA = cell.boundsMin.x, maxA = cell.boundsMax.x;
    const double minB = dimension == WorldDimension::D3 ? cell.boundsMin.z : cell.boundsMin.y;
    const double maxB = dimension == WorldDimension::D3 ? cell.boundsMax.z : cell.boundsMax.y;
    const double da = std::max({minA - a, 0.0, a - maxA});
    const double db = std::max({minB - b, 0.0, b - maxB});
    return std::sqrt(da * da + db * db);
}

void WorldIndex::cell_of(double a, double b, std::int64_t& i, std::int64_t& j) const {
    auto clamp_floor = [&](double v, double origin) {
        const double f = std::floor((v - origin) / cellSize);
        return std::int64_t(std::clamp(f, -double(kMaxWorldCoord), double(kMaxWorldCoord)));
    };
    i = clamp_floor(a, originA);
    j = clamp_floor(b, originB);
}

Result<WorldIndex> parse_world_index(const Json& json, std::string_view sourceName, const WorldIndexOptions& options,
                                     std::vector<WorldIndexIssue>* issuesOut) {
    std::vector<WorldIndexIssue> issues;
    WorldIndex index;
    const std::string source(sourceName);
    auto finish = [&]() -> Result<WorldIndex> {
        std::size_t errors = 0;
        for (const WorldIndexIssue& is : issues) errors += is.error ? 1 : 0;
        if (issuesOut) *issuesOut = issues;
        if (errors == 0) return index;
        std::string message =
            "World index '" + source + "' has " + std::to_string(errors) + (errors == 1 ? " error:" : " errors:");
        std::size_t listed = 0;
        std::string hint;
        for (const WorldIndexIssue& is : issues) {
            if (!is.error) continue;
            if (hint.empty()) hint = is.hint;
            if (listed++ >= kMaxListedIssues) continue;
            message += "\n  " + source + "#" + is.pointer + ": " + is.message;
        }
        if (errors > kMaxListedIssues) message += "\n  ... and " + std::to_string(errors - kMaxListedIssues) + " more";
        return make_error(std::move(message), std::move(hint));
    };
    index.path = source;
    if (!json.is_object()) {
        add(issues, true, "", "A world index must be a JSON object, got " + describe_json_value(json),
            std::string("Start from {\"format\": \"") + kWorldIndexFormat +
                "\", \"version\": 1, \"dimension\": \"3d\", \"cellSize\": 128, \"origin\": [0, 0], \"cells\": []}.");
        return finish();
    }
    static const std::vector<std::string> topKeys = {"format", "version", "dimension", "cellSize",
                                                     "origin", "cells",   "persistent"};
    for (auto it = json.begin(); it != json.end(); ++it) {
        const std::string& k = it.key();
        if (std::find(topKeys.begin(), topKeys.end(), k) != topKeys.end()) continue;
        if (k == "$schema" || k == "name" || k == "description" || k == "_comment") continue;
        add(issues, false, "/" + k, "Unknown top-level key '" + k + "' (ignored)", did_you_mean(k, topKeys));
    }
    if (!json.contains("format") || !json["format"].is_string())
        add(issues, false, "/format", "Missing \"format\"",
            std::string("Add \"format\": \"") + kWorldIndexFormat + "\" as the first key.");
    else if (json["format"].get<std::string>() != kWorldIndexFormat)
        add(issues, false, "/format",
            "Unknown world format '" + json["format"].get<std::string>() + "'; expected '" + kWorldIndexFormat + "'",
            "Loading continues, but a newer file may use features this engine does not know.");
    if (json.contains("version")) {
        const Json& v = json["version"];
        if (!v.is_number_integer() || v.get<std::int64_t>() != 1)
            add(issues, true, "/version",
                "\"version\" is " + describe_json_value(v) + ", but this engine reads version 1",
                "Write \"version\": 1.");
    } else {
        add(issues, false, "/version", "Missing \"version\" (version 1 assumed)", "Add \"version\": 1.");
    }
    if (json.contains("dimension")) {
        const Json& d = json["dimension"];
        if (d.is_string() && d.get<std::string>() == "3d")
            index.dimension = WorldDimension::D3;
        else if (d.is_string() && d.get<std::string>() == "2d")
            index.dimension = WorldDimension::D2;
        else
            add(issues, true, "/dimension", "\"dimension\" must be \"3d\" or \"2d\", got " + describe_json_value(d),
                "\"3d\": the cells are laid out on the XZ plane; \"2d\": on the XY plane.");
    } else {
        add(issues, false, "/dimension", "Missing \"dimension\" (\"3d\" assumed)",
            "Add \"dimension\": \"3d\" (cells on XZ) or \"2d\" (cells on XY).");
    }
    if (!json.contains("cellSize")) {
        add(issues, true, "/cellSize", "Missing \"cellSize\"",
            "Add the side of a cell in metres, for example \"cellSize\": 128.");
    } else if (!finite_number(json["cellSize"]) || json["cellSize"].get<double>() < kMinWorldCellSize ||
               json["cellSize"].get<double>() > kMaxWorldCellSize) {
        add(issues, true, "/cellSize",
            "\"cellSize\" is " + describe_json_value(json["cellSize"]) + ", but it must be a number from " +
                num(kMinWorldCellSize) + " to " + num(kMaxWorldCellSize) + " metres",
            "A cell is usually 64 to 512 metres wide: small enough to load in a few frames, large enough that an "
            "anchor sees few cells.");
    } else {
        index.cellSize = json["cellSize"].get<double>();
    }
    if (json.contains("origin")) {
        double o[2] = {0, 0};
        if (read_numbers(issues, json["origin"], "/origin", 2, "\"origin\"", "\"origin\": [-512, -512]", o)) {
            if (std::fabs(o[0]) > 1.0e9 || std::fabs(o[1]) > 1.0e9)
                add(issues, true, "/origin", "\"origin\" is [" + num(o[0]) + ", " + num(o[1]) + "], beyond 1e9 metres",
                    "Place the world's [0, 0] cell within a billion metres of the world origin.");
            else {
                index.originA = o[0];
                index.originB = o[1];
            }
        }
    }
    if (json.contains("persistent")) {
        const Json& p = json["persistent"];
        auto norm = p.is_string() ? fs::normalize_checked(p.get<std::string>()) : Result<std::string>(std::string());
        if (!p.is_string() || p.get<std::string>().empty())
            add(issues, true, "/persistent",
                "\"persistent\" must be a project-relative scene path, got " + describe_json_value(p),
                "Example: \"persistent\": \"worlds/town_main.scene.json\", the scene that holds what stays loaded; or "
                "leave it out.");
        else if (!norm)
            add(issues, true, "/persistent", norm.error().message, norm.error().hint);
        else
            index.persistent = norm.value();
    }
    if (!json.contains("cells") || !json["cells"].is_array()) {
        add(issues, true, "/cells",
            json.contains("cells")
                ? "\"cells\" must be an array of cell objects, got " + describe_json_value(json["cells"])
                : std::string("Missing \"cells\""),
            "Example: \"cells\": [{\"coord\": [0, 0], \"scene\": \"cells/0_0.scene.json\", \"bounds\": {\"min\": [0, "
            "0, 0], \"max\": [128, 10, 128]}}].");
        return finish();
    }
    const Json& cells = json["cells"];
    if (std::int64_t(cells.size()) > kMaxWorldCells) {  // checked before anything per cell is allocated
        add(issues, true, "/cells",
            "The index lists " + std::to_string(cells.size()) + " cells, but a streamed world has at most " +
                std::to_string(kMaxWorldCells),
            "Use a larger cellSize, or split the world into several indexes (one StreamedWorld each).");
        return finish();
    }
    const bool d3 = index.dimension == WorldDimension::D3;
    const std::size_t boundsLen = d3 ? 3 : 2;
    const double eps = std::max(1.0e-3, index.cellSize * 1.0e-6);
    index.cells.reserve(cells.size());
    std::map<std::pair<std::int32_t, std::int32_t>, std::size_t> seen;  // coord -> position in the array
    std::map<std::string, std::size_t> scenes;
    for (std::size_t n = 0; n < cells.size(); ++n) {
        const Json& c = cells[n];
        const std::string ptr = "/cells/" + std::to_string(n);
        if (!c.is_object()) {
            add(issues, true, ptr, "A cell must be an object, got " + describe_json_value(c),
                "Example: {\"coord\": [0, 0], \"scene\": \"cells/0_0.scene.json\", \"bounds\": {\"min\": [0, 0, 0], "
                "\"max\": [128, 10, 128]}}.");
            continue;
        }
        static const std::vector<std::string> cellKeys = {"coord", "scene", "bounds", "sizeBytes"};
        for (auto it = c.begin(); it != c.end(); ++it)
            if (std::find(cellKeys.begin(), cellKeys.end(), it.key()) == cellKeys.end())
                add(issues, false, ptr + "/" + it.key(), "Unknown cell key '" + it.key() + "' (ignored)",
                    did_you_mean(it.key(), cellKeys));
        WorldCell cell;
        bool ok = true;
        // coord
        if (!c.contains("coord") || !c["coord"].is_array() || c["coord"].size() != 2 ||
            !c["coord"][0].is_number_integer() || !c["coord"][1].is_number_integer()) {
            add(issues, true, ptr + "/coord",
                c.contains("coord")
                    ? "\"coord\" must be [i, j], two whole numbers, got " + describe_json_value(c["coord"])
                    : std::string("The cell has no \"coord\""),
                "Write the cell's grid coordinate, for example \"coord\": [3, -2]: i counts cells along " +
                    std::string("X") + ", j along " + (d3 ? "Z" : "Y") + ".");
            ok = false;
        } else {
            const std::int64_t i = c["coord"][0].get<std::int64_t>(), j = c["coord"][1].get<std::int64_t>();
            if (std::llabs(i) > kMaxWorldCoord || std::llabs(j) > kMaxWorldCoord) {
                add(issues, true, ptr + "/coord",
                    "\"coord\" [" + std::to_string(i) + ", " + std::to_string(j) +
                        "] is out of range: i and j are at most " + std::to_string(kMaxWorldCoord) +
                        " in absolute value",
                    "Move \"origin\" so the world's cells have small coordinates.");
                ok = false;
            } else {
                cell.i = std::int32_t(i);
                cell.j = std::int32_t(j);
            }
        }
        // scene
        if (!c.contains("scene") || !c["scene"].is_string() || c["scene"].get<std::string>().empty()) {
            add(issues, true, ptr + "/scene",
                c.contains("scene")
                    ? "\"scene\" must be a project-relative path, got " + describe_json_value(c["scene"])
                    : std::string("The cell has no \"scene\""),
                "Example: \"scene\": \"cells/" + std::to_string(cell.i) + "_" + std::to_string(cell.j) +
                    ".scene.json\".");
            ok = false;
        } else {
            auto norm = fs::normalize_checked(c["scene"].get<std::string>());
            if (!norm) {
                add(issues, true, ptr + "/scene", norm.error().message, norm.error().hint);
                ok = false;
            } else {
                cell.scene = norm.value();
            }
        }
        // bounds
        if (!c.contains("bounds") || !c["bounds"].is_object()) {
            add(issues, true, ptr + "/bounds",
                c.contains("bounds")
                    ? "\"bounds\" must be {\"min\": [...], \"max\": [...]}, got " + describe_json_value(c["bounds"])
                    : std::string("The cell has no \"bounds\""),
                d3 ? "Example: \"bounds\": {\"min\": [0, 0, 0], \"max\": [128, 20, 128]} (x, y, z; the distance to a "
                     "cell is taken on x and z)."
                   : "Example: \"bounds\": {\"min\": [0, 0], \"max\": [128, 128]} (x, y).");
            ok = false;
        } else {
            const Json& b = c["bounds"];
            double lo[3] = {0, 0, 0}, hi[3] = {0, 0, 0};
            const std::string example = d3 ? "[0, 0, 0]" : "[0, 0]";
            const bool haveMin = b.contains("min") && read_numbers(issues, b["min"], ptr + "/bounds/min", boundsLen,
                                                                   "\"bounds.min\"", example, lo);
            const bool haveMax = b.contains("max") && read_numbers(issues, b["max"], ptr + "/bounds/max", boundsLen,
                                                                   "\"bounds.max\"", example, hi);
            if (!b.contains("min"))
                add(issues, true, ptr + "/bounds/min", "\"bounds\" has no \"min\"",
                    "Example: \"min\": " + example + ".");
            if (!b.contains("max"))
                add(issues, true, ptr + "/bounds/max", "\"bounds\" has no \"max\"",
                    "Example: \"max\": " + example + ".");
            if (!haveMin || !haveMax) {
                ok = false;
            } else {
                bool ordered = true;
                for (std::size_t k = 0; k < boundsLen; ++k)
                    if (lo[k] > hi[k]) {
                        add(issues, true, ptr + "/bounds/min/" + std::to_string(k),
                            "bounds.min[" + std::to_string(k) + "] is " + num(lo[k]) + ", above bounds.max[" +
                                std::to_string(k) + "] (" + num(hi[k]) + ")",
                            "Swap them: min is the corner with the smallest numbers.");
                        ordered = false;
                    }
                if (!ordered) {
                    ok = false;
                } else {
                    cell.boundsMin = Vec3{float(lo[0]), float(lo[1]), d3 ? float(lo[2]) : 0.0f};
                    cell.boundsMax = Vec3{float(hi[0]), float(hi[1]), d3 ? float(hi[2]) : 0.0f};
                    // On the plane the bounds must lie inside the cell [i, j] (the rectangle origin + (i, j) * cellSize).
                    const double cellMinA = index.originA + double(cell.i) * index.cellSize;
                    const double cellMinB = index.originB + double(cell.j) * index.cellSize;
                    const double bMin[2] = {lo[0], d3 ? lo[2] : lo[1]}, bMax[2] = {hi[0], d3 ? hi[2] : hi[1]};
                    const double cMin[2] = {cellMinA, cellMinB},
                                 cMax[2] = {cellMinA + index.cellSize, cellMinB + index.cellSize};
                    const char* axisName[2] = {"x", d3 ? "z" : "y"};
                    for (int a = 0; a < 2; ++a) {
                        if (bMin[a] < cMin[a] - eps || bMax[a] > cMax[a] + eps) {
                            add(issues, true, ptr + "/bounds",
                                "bounds are [" + num(bMin[a]) + ", " + num(bMax[a]) + "] on " + axisName[a] +
                                    ", outside the cell [" + std::to_string(cell.i) + ", " + std::to_string(cell.j) +
                                    "] which covers [" + num(cMin[a]) + ", " + num(cMax[a]) +
                                    "] (origin + coord * cellSize)",
                                "Either the coord is wrong, or the cell file's entities lie outside it: move them into "
                                "the cell (a streamed cell holds only what is inside it) or fix \"coord\", \"origin\" "
                                "and \"cellSize\".");
                            ok = false;
                            break;
                        }
                    }
                }
            }
        }
        if (c.contains("sizeBytes")) {
            if (!c["sizeBytes"].is_number_integer() || c["sizeBytes"].get<std::int64_t>() < 0)
                add(issues, false, ptr + "/sizeBytes",
                    "\"sizeBytes\" must be a whole number of bytes, got " + describe_json_value(c["sizeBytes"]) +
                        " (ignored)",
                    "Example: \"sizeBytes\": 18234, or leave it out.");
            else
                cell.sizeBytes = c["sizeBytes"].get<std::int64_t>();
        }
        if (!ok) continue;
        auto dup = seen.find({cell.i, cell.j});
        if (dup != seen.end()) {
            add(issues, true, ptr + "/coord",
                "Cell [" + std::to_string(cell.i) + ", " + std::to_string(cell.j) +
                    "] is listed twice (also at /cells/" + std::to_string(dup->second) + ")",
                "Each coordinate names one cell file: remove one entry or change its coord.");
            continue;
        }
        seen[{cell.i, cell.j}] = n;
        auto same = scenes.find(cell.scene);
        if (same != scenes.end())
            add(issues, false, ptr + "/scene",
                "'" + cell.scene + "' is also the scene of /cells/" + std::to_string(same->second) +
                    ": its entities would load twice, with their ids renamed",
                "Give each cell its own scene file.");
        else
            scenes[cell.scene] = n;
        index.cells.push_back(std::move(cell));
    }
    std::sort(index.cells.begin(), index.cells.end(), [](const WorldCell& a, const WorldCell& b) {
        return std::make_pair(a.j, a.i) < std::make_pair(b.j, b.i);
    });
    // The files: every missing one listed, each with the files that exist near it.
    if (options.checkFiles) {
        if (options.maxFileChecks >= 0 && std::int64_t(index.cells.size()) > options.maxFileChecks) {
            add(issues, false, "/cells",
                "The scene files of the " + std::to_string(index.cells.size()) + " cells were not checked (more than " +
                    std::to_string(options.maxFileChecks) + ")",
                "A missing file is reported when its cell is first wanted. `project.validate` checks them all.");
        } else {
            std::map<std::string, std::vector<std::string>> byDir;
            std::size_t hints = 0;
            for (const WorldCell& cell : index.cells) {
                if (fs::exists(cell.scene) && !fs::is_directory(cell.scene)) continue;
                const std::string ptr = "/cells/" + std::to_string(seen.at({cell.i, cell.j}));
                std::string hint = "Write the cell's file there, or fix the path.";
                if (hints++ < kMaxFileHints) {
                    const std::string dir = fs::parent(cell.scene);
                    auto it = byDir.find(dir);
                    if (it == byDir.end())
                        it = byDir.emplace(dir, fs::list(dir.empty() ? "." : dir, true, ".json")).first;
                    hint = did_you_mean(cell.scene, it->second);
                }
                add(issues, true, ptr + "/scene",
                    "Cell [" + cell.id() + "]: the scene file '" + cell.scene + "' does not exist", std::move(hint));
            }
        }
    }
    return finish();
}

Result<WorldIndex> load_world_index(std::string_view path, const WorldIndexOptions& options,
                                    std::vector<WorldIndexIssue>* issues) {
    auto json = load_json_file(path);
    if (!json) return json.error();
    return parse_world_index(json.value(), path, options, issues);
}

Json world_index_to_json(const WorldIndex& index) {
    const bool d3 = index.dimension == WorldDimension::D3;
    Json cells = Json::array();
    for (const WorldCell& c : index.cells) {
        Json lo = d3 ? Json::array({c.boundsMin.x, c.boundsMin.y, c.boundsMin.z})
                     : Json::array({c.boundsMin.x, c.boundsMin.y});
        Json hi = d3 ? Json::array({c.boundsMax.x, c.boundsMax.y, c.boundsMax.z})
                     : Json::array({c.boundsMax.x, c.boundsMax.y});
        Json entry = Json::object({{"coord", Json::array({c.i, c.j})},
                                   {"scene", c.scene},
                                   {"bounds", Json::object({{"min", lo}, {"max", hi}})}});
        if (c.sizeBytes >= 0) entry["sizeBytes"] = c.sizeBytes;
        cells.push_back(std::move(entry));
    }
    Json out = Json::object({{"format", kWorldIndexFormat},
                             {"version", index.version},
                             {"dimension", d3 ? "3d" : "2d"},
                             {"cellSize", index.cellSize},
                             {"origin", Json::array({index.originA, index.originB})}});
    if (!index.persistent.empty()) out["persistent"] = index.persistent;
    out["cells"] = std::move(cells);
    return out;
}

}  // namespace fa
