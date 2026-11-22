// world.split_cells and world.merge_cells (docs/BIG_WORLDS_STREAMING.md, "Editing a streamed world"): cut a scene into a streamed world (an
// index `<name>.world.json`, one scene per cell and one persistent scene) and put the cells back into one scene. They work on the
// files: the scene is loaded into a scratch World only to know where each root entity is, and the entities that are written are
// the JSON of the source scene itself, untouched, so a split followed by a merge gives back the same entities and components with
// the same ids. The source scene (split) and the cell files (merge) are never changed.
#include <algorithm>
#include <cmath>
#include <map>
#include <set>

#include "authoring_internal.h"
#include "fa/core/capability.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/scene/components.h"
#include "fa/scene/components_world.h"
#include "fa/scene/serialize.h"
#include "fa/scene/world.h"
#include "fa/scene/world_index.h"

namespace fa {

namespace {

constexpr const char* kIndexSuffix = ".world.json";
constexpr const char* kSceneSuffix = ".scene.json";
constexpr const char* kSceneFormat = "factoria.scene/1";
constexpr std::size_t kMaxWarnings = 20;

[[noreturn]] void fail(const std::string& message, const std::string& hint, const char* code = "invalid_argument") {
    throw CommandError(code, message, hint);
}

bool ends_with(const std::string& s, const std::string& suffix) {
    return s.size() >= suffix.size() && s.compare(s.size() - suffix.size(), suffix.size(), suffix) == 0;
}

std::string project_path(const std::string& raw, const char* what) {
    if (raw.empty())
        fail(std::string("`") + what + "` is empty.", "Use a project-relative path such as worlds/level.world.json.");
    auto norm = fs::normalize_checked(raw);
    if (!norm.ok()) fail(std::string("`") + what + "`: " + norm.error().message, norm.error().hint);
    if (fs::is_absolute(norm.value()))
        fail(std::string("`") + what + "` '" + raw + "' is an absolute path.",
             "Use a project-relative path such as worlds/level.world.json.");
    return norm.value();
}

// A file this command writes (or, in a dry run, would write): the caller's write rules decide (writeProject, inside the project,
// not .git/ or .factoria/, a symlinked folder that leaves the project, an absolute path only with WriteAnywhere). A dry run writes
// nothing, so it needs no writeProject but is judged by the same path rules.
std::string write_path(const std::string& raw, const char* what, bool dryRun, const char* command) {
    if (raw.empty())
        fail(std::string("`") + what + "` is empty.", "Use a project-relative path such as worlds/level.world.json.");
    if (!dryRun) return resolve_caller_project_path(raw, command);
    auto judged =
        fs::resolve_for_write(raw, fs::WriteRoot::Project, caller_capabilities().has(Capability::WriteAnywhere));
    if (!judged.ok()) {
        const std::string code(fs::path_error_code(judged.error()));
        throw CommandError(code.empty() ? "invalid_argument" : code, judged.error().message, judged.error().hint);
    }
    return fs::project_spelling(judged.value());
}

// What same_file needs to know about one project path, found once: the path resolved against the project folder, whether the file
// exists and its normalized spelling. A caller that compares one path with many (the `out` of a merge against every cell) builds
// the id of the one path a single time.
//
// The paths go to the file system through fs::os_path, so a long Windows path (248 characters or more) is judged by the file
// system, not by a refusal of the ANSI-limit calls (which would read as "does not exist"). os_path / weakly_canonical may give the
// \\?\ form for such a path: the spelling compared is always the plain one (prefix removed), so one file never has two keys.
struct FileId {
    std::filesystem::path path;
    bool exists = false;
    std::string key;
};

FileId file_id(const std::string& name) {
    FileId id;
    id.path = fs::resolve(name);
    std::error_code ec;
    id.exists = std::filesystem::exists(fs::os_path(id.path), ec);
    std::filesystem::path canon = std::filesystem::weakly_canonical(fs::os_path(id.path), ec);
    std::string text = fs::path_to_utf8(ec ? id.path.lexically_normal() : canon);
    if (text.rfind("//?/UNC/", 0) == 0)
        text = "//" + text.substr(8);
    else if (text.rfind("//?/", 0) == 0 && text.size() > 6 && text[5] == ':')
        text = text.substr(4);
#if defined(_WIN32) || defined(__APPLE__)
    for (char& c : text)
        if (c >= 'A' && c <= 'Z') c = char(c - 'A' + 'a');
#endif
    id.key = std::move(text);
    return id;
}

// True when two project paths name the same file. Both are resolved against the project folder first. When both files exist the
// file system decides (std::filesystem::equivalent: a symlink, "a/../b" and, on a case-insensitive volume, "Town.world.json" and
// "town.world.json" are one file). A file that does not exist yet (the `out` of a merge) is compared by its normalized path, with
// ASCII case folded on Windows and macOS, whose default volumes ignore case (as fs::resolve_for_write does), never on Linux.
bool same_file(const FileId& a, const FileId& b) {
    if (a.exists && b.exists) {
        std::error_code ec;
        const bool same = std::filesystem::equivalent(fs::os_path(a.path), fs::os_path(b.path), ec);
        if (!ec) return same;
    }
    return a.key == b.key;
}

bool same_file(const std::string& a, const std::string& b) { return same_file(file_id(a), file_id(b)); }

Json read_json_file(const std::string& path, const char* what) {
    auto text = fs::read_text(path);
    if (!text.ok())
        fail(std::string("Cannot read ") + what + " '" + path + "': " + text.error().message, text.error().hint,
             "not_found");
    auto parsed = parse_json(text.value(), path);
    if (!parsed.ok()) fail(parsed.error().message, parsed.error().hint);
    return parsed.value();
}

// Components that make a root entity global: it has to exist wherever the player is, so it cannot live in a cell that unloads.
template <class... Ts>
bool has_any(const World& w, Entity e) {
    return (w.has<Ts>(e) || ...);
}

// Why this subtree stays in the persistent scene; "" when it belongs to a cell.
std::string global_reason(const World& w, Entity root, const Json& entry) {
    if (entry.is_object() && entry.contains("tags") && entry["tags"].is_array())
        for (const Json& t : entry["tags"])
            if (t.is_string() && t.get<std::string>() == "global") return "it has the tag \"global\"";
    std::string reason;
    std::vector<Entity> stack{root};
    while (!stack.empty() && reason.empty()) {
        const Entity e = stack.back();
        stack.pop_back();
        if (w.has<Camera>(e))
            reason = "it has a Camera";
        else if (w.has<AudioListener>(e) || w.has<MusicPlayer>(e))
            reason = "it has an AudioListener or a MusicPlayer";
        else if (w.has<StreamedWorld>(e) || w.has<StreamingAnchor>(e))
            reason = "it has a StreamedWorld or a StreamingAnchor";
        else if (has_any<Panel, Button, Toggle, Slider, TextField, ScrollList, TouchStick, TouchButton, Captions,
                         Chart>(w, e))
            reason = "it is user interface (screen space)";
        else if (const Light* l = w.get<Light>(e); l && l->type == LightType::Directional)
            reason = "it is a directional light (a sun has no place)";
        else if (!w.has<Transform>(e) && e == root)
            reason = "it has no Transform (it has no place)";
        for (Entity c : w.children(e)) stack.push_back(c);
    }
    return reason;
}

// Every `id` of an entity list, with its children, to the place it is in (a file name): used to find an id that two files share.
void collect_ids(const Json& list, const std::string& pointer, const std::string& where,
                 std::map<std::string, std::pair<std::string, std::string>>& ids,
                 std::vector<std::string>& duplicates) {
    if (!list.is_array()) return;
    for (std::size_t i = 0; i < list.size(); ++i) {
        const Json& e = list[i];
        if (!e.is_object()) continue;
        const std::string ptr = pointer + "/" + std::to_string(i);
        if (e.contains("id") && e["id"].is_string()) {
            const std::string id = e["id"].get<std::string>();
            auto [it, inserted] = ids.emplace(id, std::make_pair(where, ptr));
            if (!inserted && duplicates.size() < 5)
                duplicates.push_back("'" + id + "' is at " + it->second.first + " " + it->second.second + " and at " +
                                     where + " " + ptr);
        }
        if (e.contains("children")) collect_ids(e["children"], ptr + "/children", where, ids, duplicates);
    }
}

// Every entity (with its children) that has a StreamedWorld component: a merged scene keeps it (the entities are written exactly as
// their files have them), so playing the merged scene would stream the cells it already holds, every entity twice.
void find_streamed_worlds(const Json& list, const std::string& pointer, const std::string& where,
                          std::vector<std::string>& found) {
    if (!list.is_array()) return;
    for (std::size_t i = 0; i < list.size(); ++i) {
        const Json& e = list[i];
        if (!e.is_object()) continue;
        const std::string ptr = pointer + "/" + std::to_string(i);
        if (e.contains("components") && e["components"].is_object() && e["components"].contains("StreamedWorld") &&
            found.size() < kMaxWarnings) {
            const std::string id = e.contains("id") && e["id"].is_string() ? e["id"].get<std::string>() : "(no id)";
            found.push_back(
                "Entity '" + id + "' (" + where + " " + ptr +
                ") has a StreamedWorld component and it stays in the merged scene: playing that scene would "
                "stream the cells it already contains, so every entity would exist twice. Remove it from the "
                "merged scene (open it and run scene.remove_component {\"id\":\"" +
                id + "\",\"component\":\"StreamedWorld\"}, or delete the entity if it only held that component).");
        }
        if (e.contains("children")) find_streamed_worlds(e["children"], ptr + "/children", where, found);
    }
}

// Every string in `components` of the entity (and its children) that is the id of an entity in `group` other than `mine`.
void scan_refs(const Json& v, const std::map<std::string, std::string>& groupOf, const std::string& mine,
               const std::string& pointer, const std::string& ownerId, std::vector<std::string>& warnings,
               std::size_t& total) {
    if (v.is_string()) {
        auto it = groupOf.find(v.get<std::string>());
        if (it != groupOf.end() && it->second != mine) {
            if (warnings.size() < kMaxWarnings)
                warnings.push_back("Entity '" + ownerId + "' (" + (mine.empty() ? "persistent" : "cell " + mine) +
                                   ") names the entity '" + it->first + "' at " + pointer + ", which is in " +
                                   (it->second.empty() ? std::string("the persistent scene") : "cell " + it->second) +
                                   ": that reference will be empty while the other one is not loaded.");
            ++total;
        }
    } else if (v.is_object()) {
        for (auto it = v.begin(); it != v.end(); ++it)
            scan_refs(*it, groupOf, mine, pointer + "/" + it.key(), ownerId, warnings, total);
    } else if (v.is_array()) {
        for (std::size_t i = 0; i < v.size(); ++i)
            scan_refs(v[i], groupOf, mine, pointer + "/" + std::to_string(i), ownerId, warnings, total);
    }
}

void walk_refs(const Json& entity, const std::string& pointer, const std::map<std::string, std::string>& groupOf,
               const std::string& mine, std::vector<std::string>& warnings, std::size_t& total) {
    if (!entity.is_object()) return;
    const std::string id = entity.value("id", std::string());
    if (entity.contains("components"))
        scan_refs(entity["components"], groupOf, mine, pointer + "/components", id, warnings, total);
    if (entity.contains("children") && entity["children"].is_array())
        for (std::size_t i = 0; i < entity["children"].size(); ++i)
            walk_refs(entity["children"][i], pointer + "/children/" + std::to_string(i), groupOf, mine, warnings,
                      total);
}

void collect_group_ids(const Json& entity, const std::string& group, std::map<std::string, std::string>& groupOf) {
    if (!entity.is_object()) return;
    if (entity.contains("id") && entity["id"].is_string()) groupOf.emplace(entity["id"].get<std::string>(), group);
    if (entity.contains("children") && entity["children"].is_array())
        for (const Json& c : entity["children"]) collect_group_ids(c, group, groupOf);
}

struct CellPlan {
    std::int32_t i = 0, j = 0;
    std::vector<std::size_t> roots;  // indices into the source's "entities"
    double minY = 0, maxY = 0;       // 3d: the heights of the entities of the cell
    bool haveY = false;
    std::string scene;
    Json file;
    std::int64_t sizeBytes = 0;
};

Json split_cells(Engine::Impl&, const Json& args) {
    const char* kCommand = "world.split_cells";
    const std::string scenePath = project_path(args.value("scene", std::string()), "scene");
    if (!args.contains("cellSize") || !args["cellSize"].is_number())
        fail("`cellSize` is " + (args.contains("cellSize") ? args["cellSize"].dump() : std::string("missing")) +
                 ": it must be a number of metres.",
             "Pass the width of a cell, for example 128 (a world of 1 km by 1 km then gives 8 x 8 cells).");
    const double cellSize = args["cellSize"].get<double>();
    if (!(cellSize >= kMinWorldCellSize && cellSize <= kMaxWorldCellSize))
        fail("cellSize is " + std::to_string(cellSize) + ": a cell is " + std::to_string(kMinWorldCellSize) + " to " +
                 std::to_string(kMaxWorldCellSize) + " metres wide.",
             "Pass the width of a cell in metres, for example 128.");
    const std::string dimension = args.value("dimension", std::string("3d"));
    if (dimension != "3d" && dimension != "2d")
        fail("`dimension` is \"" + dimension +
                 "\": it is \"3d\" (cells on the XZ plane) or \"2d\" (cells on the XY plane).",
             "Use \"3d\" for a 3D scene and \"2d\" for a side-view or top-down 2D scene.");
    const bool d3 = dimension == "3d";
    const bool dryRun = args.value("dryRun", false);
    const bool overwrite = args.value("overwrite", false);

    std::string indexPath;
    if (args.contains("out") && args["out"].is_string()) {
        indexPath = write_path(args["out"].get<std::string>(), "out", dryRun, kCommand);
        if (!ends_with(indexPath, kIndexSuffix))
            fail("out '" + indexPath + "' does not end in " + kIndexSuffix + ".",
                 "Name the index like worlds/level.world.json; the cell scenes go in a folder next to it "
                 "(worlds/level_cells/).");
    } else {
        indexPath =
            write_path(ends_with(scenePath, kSceneSuffix)
                           ? scenePath.substr(0, scenePath.size() - std::string(kSceneSuffix).size()) + kIndexSuffix
                           : scenePath + kIndexSuffix,
                       "out", dryRun, kCommand);
    }
    const std::string base = indexPath.substr(0, indexPath.size() - std::string(kIndexSuffix).size());
    const std::string cellDir = base + "_cells";
    const std::string persistentPath = write_path(base + "_persistent" + kSceneSuffix, "out", dryRun, kCommand);

    // The source scene, as JSON (what is written) and loaded into a scratch World (where each root is).
    const Json scene = read_json_file(scenePath, "scene");
    if (!scene.is_object() || !scene.contains("entities") || !scene["entities"].is_array())
        fail(scenePath + " has no \"entities\" array.", "Pass a *.scene.json file (a prefab has no scene to split).");
    if (scene.contains("origin")) {
        bool nonzero = false;
        if (scene["origin"].is_array())
            for (const Json& v : scene["origin"])
                if (v.is_number() && v.get<double>() != 0.0) nonzero = true;
        if (nonzero)
            fail(
                scenePath + "/origin is " + scene["origin"].dump() +
                    ": the scene is saved relative to a floating origin, so its positions are not absolute.",
                "Rebase it to the origin first (world.rebase to [0,0,0], then scene.save), then split: the cell scenes "
                "hold absolute positions.");
    }
    const Json& entities = scene["entities"];
    World scratch;
    {
        LoadReport report = load_scene(scratch, scene, scenePath);
        if (report.error_count() > 0) {
            std::string detail;
            std::size_t shown = 0;
            for (const LoadMessage& m : report.messages)
                if (m.severity == LoadMessage::Severity::Error && ++shown <= 5) detail += "\n  " + m.to_string();
            fail("Cannot split '" + scenePath + "': it has " + std::to_string(report.error_count()) +
                     " load error(s):" + detail,
                 "Fix the file first (project.validate lists every problem with its JSON pointer). Nothing was "
                 "written.");
        }
    }
    const std::vector<Entity> roots = scratch.roots();
    if (roots.size() != entities.size())
        fail(scenePath + " has " + std::to_string(entities.size()) + " entries in /entities but loads " +
                 std::to_string(roots.size()) + " root entities.",
             "Every entry of /entities must make exactly one root entity (an entry that failed to load or a prefab "
             "that makes several roots cannot be split). Nothing was written.");

    // Where each root goes.
    WorldIndex grid;
    grid.dimension = d3 ? WorldDimension::D3 : WorldDimension::D2;
    grid.cellSize = cellSize;
    std::map<std::pair<std::int32_t, std::int32_t>, CellPlan> plans;  // keyed (j, i): the order of an index
    std::vector<std::size_t> globalRoots;
    std::vector<std::string> globalList;
    for (std::size_t k = 0; k < roots.size(); ++k) {
        const std::string why = global_reason(scratch, roots[k], entities[k]);
        const std::string id = scratch.id_of(roots[k]);
        if (!why.empty()) {
            globalRoots.push_back(k);
            if (globalList.size() < 100) globalList.push_back(id + ": " + why);
            continue;
        }
        const Vec3 p = scratch.world_position(roots[k]);
        const std::string ptr = "/entities/" + std::to_string(k);
        if (!std::isfinite(p.x) || !std::isfinite(p.y) || !std::isfinite(p.z))
            fail(scenePath + ptr + ": the entity '" + id + "' has a position that is not a finite number.",
                 "Fix its Transform.position.");
        std::int64_t ci = 0, cj = 0;
        grid.cell_of(double(p.x), double(d3 ? p.z : p.y), ci, cj);
        if (ci <= -kMaxWorldCoord || ci >= kMaxWorldCoord || cj <= -kMaxWorldCoord || cj >= kMaxWorldCoord)
            fail(scenePath + ptr + ": the entity '" + id + "' is at (" + std::to_string(p.x) + ", " +
                     std::to_string(p.y) + ", " + std::to_string(p.z) + "), cell [" + std::to_string(ci) + ", " +
                     std::to_string(cj) + "] of " + std::to_string(cellSize) +
                     " metres: farther than a world index holds.",
                 "Use a bigger cellSize, or move the entity (or tag it \"global\" to keep it out of the cells).");
        CellPlan& c = plans[{std::int32_t(cj), std::int32_t(ci)}];
        c.i = std::int32_t(ci);
        c.j = std::int32_t(cj);
        c.roots.push_back(k);
        // the heights of every entity of the subtree
        std::vector<Entity> stack{roots[k]};
        while (!stack.empty()) {
            const Entity e = stack.back();
            stack.pop_back();
            const double y = double(scratch.world_position(e).y);
            if (std::isfinite(y)) {
                c.minY = c.haveY ? std::min(c.minY, y) : y;
                c.maxY = c.haveY ? std::max(c.maxY, y) : y;
                c.haveY = true;
            }
            for (Entity ch : scratch.children(e)) stack.push_back(ch);
        }
    }
    if (std::int64_t(plans.size()) > kMaxWorldCells)
        fail("The split would make " + std::to_string(plans.size()) + " cells, over the " +
                 std::to_string(kMaxWorldCells) + " an index holds.",
             "Use a bigger cellSize.");
    if (plans.empty())
        fail(scenePath + " has no entity to put in a cell (" + std::to_string(globalRoots.size()) + " of its " +
                 std::to_string(roots.size()) + " root entities are global).",
             "A scene whose entities are all cameras, lights and UI has nothing to stream. Place the level's entities "
             "in the scene, or tag fewer of them \"global\".");

    // Which group (cell "i,j" or "" for the persistent scene) every id belongs to, for the references that cross a border.
    std::map<std::string, std::string> groupOf;
    for (std::size_t k : globalRoots) collect_group_ids(entities[k], "", groupOf);
    for (auto& [key, c] : plans)
        for (std::size_t k : c.roots)
            collect_group_ids(entities[k], std::to_string(c.i) + "," + std::to_string(c.j), groupOf);
    std::vector<std::string> warnings;
    std::size_t crossRefs = 0;
    for (std::size_t k : globalRoots)
        walk_refs(entities[k], "/entities/" + std::to_string(k), groupOf, "", warnings, crossRefs);
    for (auto& [key, c] : plans)
        for (std::size_t k : c.roots)
            walk_refs(entities[k], "/entities/" + std::to_string(k), groupOf,
                      std::to_string(c.i) + "," + std::to_string(c.j), warnings, crossRefs);
    if (crossRefs > warnings.size())
        warnings.push_back("... and " + std::to_string(crossRefs - warnings.size()) +
                           " more references between cells.");

    // The files.
    WorldIndex index = grid;
    index.version = 1;
    index.persistent = persistentPath;
    for (auto& [key, c] : plans) {
        c.scene = write_path(cellDir + "/" + std::to_string(c.i) + "_" + std::to_string(c.j) + kSceneSuffix, "out",
                             dryRun, kCommand);
        Json list = Json::array();
        for (std::size_t k : c.roots) list.push_back(entities[k]);
        c.file = Json::object({{"format", kSceneFormat}, {"entities", std::move(list)}});
        c.sizeBytes = std::int64_t(dump_scene_json(c.file).size());
        WorldCell cell;
        cell.i = c.i;
        cell.j = c.j;
        cell.scene = c.scene;
        cell.sizeBytes = c.sizeBytes;
        const double a0 = index.originA + double(c.i) * cellSize, b0 = index.originB + double(c.j) * cellSize;
        if (d3) {
            cell.boundsMin = Vec3{float(a0), float(c.minY), float(b0)};
            cell.boundsMax = Vec3{float(a0 + cellSize), float(c.maxY), float(b0 + cellSize)};
        } else {
            cell.boundsMin = Vec3{float(a0), float(b0), 0.0f};
            cell.boundsMax = Vec3{float(a0 + cellSize), float(b0 + cellSize), 0.0f};
        }
        index.cells.push_back(std::move(cell));
    }
    Json persistentFile = Json::object({{"format", kSceneFormat}});
    if (scene.contains("settings")) persistentFile["settings"] = scene["settings"];
    {
        Json list = Json::array();
        for (std::size_t k : globalRoots) list.push_back(entities[k]);
        persistentFile["entities"] = std::move(list);
    }
    const Json indexJson = world_index_to_json(index);
    {  // what is written must be an index the engine accepts
        WorldIndexOptions options;
        options.checkFiles = false;
        auto check = parse_world_index(indexJson, indexPath, options);
        if (!check.ok())
            fail("The index this split would write is not valid: " + check.error().message, check.error().hint,
                 "internal");
    }

    {  // the command promises never to change the source scene, whatever `overwrite` says
        std::string clash;
        if (same_file(indexPath, scenePath)) clash = indexPath;
        if (clash.empty() && same_file(persistentPath, scenePath)) clash = persistentPath;
        for (auto& [key, c] : plans)
            if (clash.empty() && same_file(c.scene, scenePath)) clash = c.scene;
        if (!clash.empty())
            fail("'" + clash + "' is the scene being split: the split never changes it.",
                 "Pass another \"out\" (for example worlds/level.world.json) so the index and the cells go to new "
                 "files.");
    }
    std::vector<std::string> clashes;
    if (!overwrite) {
        if (fs::exists(indexPath)) clashes.push_back(indexPath);
        if (fs::exists(persistentPath)) clashes.push_back(persistentPath);
        for (auto& [key, c] : plans)
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
        auto put = [&](const std::string& path, const Json& file) {
            auto w = save_scene_json_file(path, file);
            if (!w.ok())
                fail("Cannot write '" + path + "': " + w.error().message + " (" + std::to_string(written.size()) +
                         " files were written before it).",
                     w.error().hint, "write_failed");
            written.push_back(path);
        };
        for (auto& [key, c] : plans) put(c.scene, c.file);
        put(persistentPath, persistentFile);
        auto w = fs::write_text(indexPath, dump_json(indexJson));
        if (!w.ok())
            fail("Cannot write '" + indexPath + "': " + w.error().message + " (" + std::to_string(written.size()) +
                     " files were written before it).",
                 w.error().hint, "write_failed");
        written.push_back(indexPath);
    }

    Json cellList = Json::array();
    for (auto& [key, c] : plans) {
        if (cellList.size() >= 1000) break;
        cellList.push_back(Json::object({{"coord", Json::array({c.i, c.j})},
                                         {"scene", c.scene},
                                         {"entities", std::int64_t(c.roots.size())},
                                         {"sizeBytes", c.sizeBytes}}));
    }
    Json notes = Json::array();
    notes.push_back("The source scene was not changed. Open '" + persistentPath +
                    "' (the settings and the global entities) and add an entity with StreamedWorld {\"world\": \"" +
                    indexPath + "\"} and a StreamingAnchor on the player (or StreamedWorld.cameraLoadRadius).");
    if (globalList.empty())
        notes.push_back("No entity is global: the persistent scene holds only the settings. Cameras, UI, directional "
                        "lights and anything tagged \"global\" would have stayed in it.");
    Json out = Json::object();
    out["world"] = indexPath;
    out["persistent"] = persistentPath;
    out["dryRun"] = dryRun;
    out["dimension"] = dimension;
    out["cellSize"] = cellSize;
    out["origin"] = Json::array({index.originA, index.originB});
    out["cells"] = std::int64_t(plans.size());
    out["entities"] = std::int64_t(roots.size());
    out["globalEntities"] = std::int64_t(globalRoots.size());
    out["globalList"] = globalList;
    out["files"] = std::int64_t(plans.size()) + 2;
    out["written"] = dryRun ? 0 : std::int64_t(written.size());
    out["cellList"] = std::move(cellList);
    out["warnings"] = warnings;
    out["notes"] = std::move(notes);
    return out;
}

Json merge_cells(Engine::Impl&, const Json& args) {
    const char* kCommand = "world.merge_cells";
    const std::string worldPath = project_path(args.value("world", std::string()), "world");
    const bool dryRun = args.value("dryRun", false);
    const bool overwrite = args.value("overwrite", false);
    if (!args.contains("out") || !args["out"].is_string() || args["out"].get<std::string>().empty())
        fail("`out` is missing: the scene file to write.",
             "Pass the merged scene, for example \"out\": \"scenes/level.scene.json\".");
    const std::string outPath = write_path(args["out"].get<std::string>(), "out", dryRun, kCommand);
    if (!ends_with(outPath, kSceneSuffix))
        fail("out '" + outPath + "' does not end in " + kSceneSuffix + ".",
             "Name the scene like scenes/level.scene.json.");

    auto loaded = load_world_index(worldPath);
    if (!loaded.ok()) fail("Cannot merge '" + worldPath + "': " + loaded.error().message, loaded.error().hint);
    const WorldIndex index = loaded.value();

    const FileId outId = file_id(outPath);  // once: the cells below are each compared with it
    const bool outIsPersistent = same_file(outId, file_id(index.persistent));
    for (const WorldCell& c : index.cells)
        if (outIsPersistent || same_file(outId, file_id(c.scene)))
            fail("out '" + outPath + "' is a file of the world being merged ('" +
                     (outIsPersistent ? index.persistent : c.scene) + "'): the merge never changes them.",
                 "Pass another \"out\" for the merged scene.");
    if (same_file(outId, file_id(worldPath)))
        fail("out '" + outPath + "' is the index itself.", "Pass another \"out\".");
    if (!overwrite && fs::exists(outPath))
        fail("'" + outPath + "' already exists.",
             "Pass \"overwrite\": true to replace it, or another \"out\". Nothing was written.", "exists");

    Json merged = Json::object({{"format", kSceneFormat}});
    Json list = Json::array();
    std::map<std::string, std::pair<std::string, std::string>> ids;
    std::vector<std::string> duplicates, streamedWorlds;
    std::int64_t persistentCount = 0, filesRead = 1;
    auto take = [&](const std::string& path, bool isPersistent) {
        const Json file = read_json_file(path, isPersistent ? "persistent scene" : "cell scene");
        ++filesRead;
        if (!file.is_object() || !file.contains("entities") || !file["entities"].is_array())
            fail(
                path + " has no \"entities\" array.",
                "A cell file looks like {\"format\": \"factoria.scene/1\", \"entities\": [...]}. Nothing was written.");
        if (isPersistent) {
            if (file.contains("settings")) merged["settings"] = file["settings"];
            if (file.contains("origin")) merged["origin"] = file["origin"];
        }
        collect_ids(file["entities"], "/entities", path, ids, duplicates);
        find_streamed_worlds(file["entities"], "/entities", path, streamedWorlds);
        for (const Json& e : file["entities"]) {
            list.push_back(e);
            if (isPersistent) ++persistentCount;
        }
    };
    if (!index.persistent.empty()) take(index.persistent, true);
    for (const WorldCell& c : index.cells) take(c.scene, false);
    if (!duplicates.empty())
        fail(
            "Two files of the world have the same entity id: " + duplicates[0] +
                (duplicates.size() > 1 ? " (and " + std::to_string(duplicates.size() - 1) + "+ more)" : "") + ".",
            "Ids are unique in a scene: rename one of the entities in its cell file, then merge. Nothing was written.");
    merged["entities"] = std::move(list);

    bool wrote = false;
    if (!dryRun) {
        auto w = save_scene_json_file(outPath, merged);
        if (!w.ok()) fail("Cannot write '" + outPath + "': " + w.error().message, w.error().hint, "write_failed");
        wrote = true;
    }
    Json out = Json::object();
    out["scene"] = outPath;
    out["dryRun"] = dryRun;
    out["world"] = worldPath;
    out["cells"] = std::int64_t(index.cells.size());
    out["persistent"] = index.persistent;
    out["entities"] = std::int64_t(merged["entities"].size());
    out["persistentEntities"] = persistentCount;
    out["filesRead"] = filesRead;
    out["written"] = wrote ? 1 : 0;
    out["warnings"] = streamedWorlds;
    out["notes"] = Json::array({"The world files were not changed. The entities are the persistent scene's first, then "
                                "each cell's in index order (by j, then i), each with its children, ids and "
                                "components exactly as in its cell file."});
    return out;
}

}  // namespace

void register_world_split_commands(Engine& engine, Engine::Impl& I) {
    (void)engine;
    I.commands.add(
        {"world.split_cells", "Cut a scene into a streamed world: an index, one scene per cell and a persistent scene.",
         "Reads a scene file and writes `<out>` (a world index, default: the scene's name with .world.json), one scene "
         "per "
         "non-empty cell in `<out without .world.json>_cells/<i>_<j>.scene.json`, and the persistent scene "
         "`<out without .world.json>_persistent.scene.json` (named in the index's `persistent` key). A ROOT entity "
         "goes whole, "
         "with all its children, to the cell its world position is in: cell [i, j] is floor((x - origin) / cellSize) "
         "on the "
         "plane (XZ for \"3d\", XY for \"2d\"), cell borders belong to the higher cell, the index origin is [0, 0]. "
         "Details: docs/BIG_WORLDS_STREAMING.md, \"Editing a streamed world\". " FA_COMMAND_DETAILS
         "GLOBAL entities stay in the persistent scene instead, together with the scene's `settings`: a root entity "
         "whose "
         "subtree has a Camera, an AudioListener, a MusicPlayer, a StreamedWorld, a StreamingAnchor, any "
         "user-interface "
         "component or a directional Light, that has no Transform, or whose tags include \"global\". The cells' bounds "
         "are "
         "the cell rectangle on the plane and the lowest and highest position of its entities in height (3d). The "
         "entities "
         "are written exactly as the source scene has them (same ids, components and children, in the source order), "
         "so "
         "world.merge_cells gives them back. A scene with a floating `origin` is refused (rebase it first). A string "
         "in an "
         "entity's components that is the id of an entity in another cell is reported in `warnings`: such a reference "
         "is "
         "empty while the other cell is not loaded. The output is deterministic (the same scene and cellSize give the "
         "same "
         "bytes). The source scene is never changed; existing files are only replaced with `overwrite`; `dryRun` "
         "reports "
         "without writing. "
         "Result: {world, persistent, cells, entities, globalEntities, globalList, files, written, cellList, warnings, "
         "notes}. Example: world.split_cells "
         "{\"scene\":\"scenes/town.scene.json\",\"cellSize\":128,\"out\":\"worlds/town.world.json\"}",
         parse_json(R"({"type":"object","properties":{
           "scene":{"type":"string","description":"The scene file to split (project-relative *.scene.json)."},
           "cellSize":{"type":"number","minimum":0.5,"maximum":1000000,"description":"Width of a cell in metres, on the plane of the world."},
           "out":{"type":"string","description":"The index file to write, ending in .world.json (default: next to the scene, named after it)."},
           "dimension":{"type":"string","enum":["3d","2d"],"default":"3d","description":"3d: the cells are on the XZ plane; 2d: on the XY plane."},
           "overwrite":{"type":"boolean","default":false,"description":"Replace files of an earlier split. Without it an existing file is an error and nothing is written."},
           "dryRun":{"type":"boolean","default":false,"description":"Only report what would be written."}},"required":["scene","cellSize"]})",
                    "command schema")
             .value(),
         false, "world"},
        [&I](const Json& a) { return split_cells(I, a); });
    I.commands.add(
        {"world.merge_cells", "Merge the cells of a streamed world back into one scene file.",
         "The inverse of world.split_cells: reads the index `world`, its persistent scene and every cell scene, and "
         "writes "
         "all their entities into the one scene `out`, with the persistent scene's `settings`: the persistent scene's "
         "entities first, then each cell's in index order (by j, then i), each entity with its children, ids and "
         "components "
         "exactly as in its file. So split then merge gives the same entities (the order of the roots follows the "
         "cells). "
         "Details: docs/BIG_WORLDS_STREAMING.md, \"Editing a streamed world\". " FA_COMMAND_DETAILS
         "Two files with the same entity id are an error (nothing is written). The world's files are never changed and "
         "`out` may not be one of them; an existing `out` is replaced only with `overwrite`; `dryRun` reports without "
         "writing. "
         "A StreamedWorld component in the files stays in the merged scene (the entities are written as they are), so "
         "playing "
         "that scene would stream the cells it already holds: `warnings` names each one and how to remove it. "
         "Result: {scene, world, cells, persistent, entities, persistentEntities, filesRead, written, warnings, "
         "notes}. "
         "Example: "
         "world.merge_cells {\"world\":\"worlds/town.world.json\",\"out\":\"scenes/town_merged.scene.json\"}",
         parse_json(R"({"type":"object","properties":{
           "world":{"type":"string","description":"The index file (project-relative *.world.json)."},
           "out":{"type":"string","description":"The scene file to write (project-relative *.scene.json)."},
           "overwrite":{"type":"boolean","default":false,"description":"Replace `out` when it exists."},
           "dryRun":{"type":"boolean","default":false,"description":"Only report what would be written."}},"required":["world","out"]})",
                    "command schema")
             .value(),
         false, "world"},
        [&I](const Json& a) { return merge_cells(I, a); });
    declare_command_capabilities(I.commands, {{"world.split_cells", capability_sets::edits_project()},
                                              {"world.merge_cells", capability_sets::edits_project()}});
}

}  // namespace fa
