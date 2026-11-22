// Level authoring commands of the editor, the CLI and MCP (not of an exported game): scene.import_ascii (ASCII map -> Tilemap + the
// objects standing on it, in the running world or written to a scene file) and scene.ascii_edit (edit the rows of a level file).
// The parts a running game needs too (scene.place_ascii, read_ascii_sample, the parsing and the import itself) stay in
// engine/runtime/src/level_commands.cpp and are declared in fa/runtime/internal/ascii_level.h, which this file uses.
//
// Two targets share the import code (ascii_level::apply_import): the RUNNING world (no `path`), or, with `path`, a scratch World
// loaded from the scene file and written back to it (import_into_scene_file), which leaves the running engine untouched.
#include <algorithm>
#include <array>
#include <functional>
#include <map>
#include <set>

#include "authoring_internal.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/runtime/internal/ascii_level.h"
#include "fa/scene/serialize.h"
#include "fa/scene/tilemap.h"

namespace fa {

namespace {

using namespace ascii_level;

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

// Every *.scene.json of the project (scenes/, but also e.g. a levels/base.scene.json), for "did you mean" suggestions.
std::vector<std::string> scene_files() {
    std::vector<std::string> out;
    for (const std::string& f : fs::list("", true, ".json"))
        if (ends_with(f, ".scene.json") && !starts_with(f, ".factoria/") && !starts_with(f, ".git/")) out.push_back(f);
    return out;
}

// `path` / `from` / `file`: a project-relative file (`kind` says which: a scene file, or the level file that scene.ascii_edit
// rewrites). A file that is only READ (`from`, and `path` of a dry run) refuses an absolute path (the project folder is the
// sandbox of the file mode). A file that is WRITTEN goes through resolve_caller_project_path (writeProject, inside the project,
// not .git or .factoria/ except .factoria/tmp/; an absolute path only for a caller that may write anywhere). `command` is the
// command whose argument it is: its errors name it.
// `predictWrite` (a dry run's `path`): nothing is written, so no writeProject is needed, but the path is judged by the same rules
// as the real call would (resolve_for_write with the caller's right to write anywhere: inside the project, not .git or
// .factoria/ except .factoria/tmp/, an absolute path only for the command line), so the dry run predicts it.
std::string scene_file_arg(const Json& v, const char* key, bool forWrite, const char* command,
                           bool predictWrite = false, const char* kind = "scene file",
                           const char* example = "scenes/level1.scene.json") {
    const std::string k = key;
    if (!v.is_string() || v.get<std::string>().empty())
        bad_arg("'" + k + "' of " + command + " must be a project-relative " + kind + " path, got " +
                    describe_json_value(v),
                "Example: \"" + k + "\": \"" + example + "\".");
    const std::string raw = v.get<std::string>();
    std::string path;
    if (forWrite) {
        path = resolve_caller_project_path(raw, command);
    } else if (predictWrite) {
        auto judged =
            fs::resolve_for_write(raw, fs::WriteRoot::Project, caller_capabilities().has(Capability::WriteAnywhere));
        if (!judged.ok()) {
            const std::string code(fs::path_error_code(judged.error()));
            throw CommandError(code.empty() ? "invalid_argument" : code, judged.error().message, judged.error().hint);
        }
        path = fs::project_spelling(judged.value());
    } else {
        if (fs::is_absolute(raw))
            bad_arg("'" + k + "' of " + command + " must be project-relative, but '" + raw + "' is an absolute path",
                    "Use the path inside the project, e.g. \"" + k + "\": \"" + example + "\".");
        auto norm = fs::normalize_checked(raw);
        if (!norm.ok()) bad_arg("'" + k + "': " + norm.error().message, norm.error().hint);
        path = norm.value();
    }
    if (path.empty() || fs::is_directory(path))
        bad_arg("'" + k + "' of " + command + " is '" + raw + "', which is a folder, not a " + kind,
                "Name the file, e.g. \"" + k + "\": \"" + example + "\".");
    return path;
}

// The arguments of scene.import_ascii: what the running world needs (ascii_level::parse_request) plus `save` and the file mode
// (`path`, `from`, `edits`, `dryRun`).
Request parse_import_request(const Engine::Impl& I, const Json& a) {
    Request q = parse_request(I, a);
    q.save = a.value("save", false);
    q.dryRun = a.value("dryRun", false);
    // A dry run writes nothing, so it needs no writeProject: its `path` is only read (and judged like `from`).
    if (a.contains("path")) q.path = scene_file_arg(a["path"], "path", !q.dryRun, "scene.import_ascii", q.dryRun);
    if (a.contains("from")) q.from = scene_file_arg(a["from"], "from", false, "scene.import_ascii");
    if (a.contains("edits"))
        q.edits = a["edits"];  // {entity: {Component: {fields}}}: the input schema checked the shape
    if (q.path.empty()) {
        if (!q.edits.empty())
            bad_arg("'edits' needs 'path': it patches entities of the scene file 'path' before it is written",
                    "Add \"path\": \"scenes/<name>.scene.json\". To change the RUNNING world use scene.set_component.");
        if (!q.from.empty())
            bad_arg("'from' needs 'path': it is the scene file to start from when building the scene file 'path'",
                    "Add \"path\": \"scenes/<name>.scene.json\" (the file to write), or drop 'from'.");
        if (q.dryRun)
            bad_arg("'dryRun' needs 'path': it previews the scene file 'path' without writing it",
                    "Add \"path\": \"scenes/<name>.scene.json\". Without 'path' the import changes the RUNNING scene, "
                    "which a dry run cannot undo.");
    }
    if (q.path.empty() && q.save) {
        require_capability(Capability::WriteProject, "scene.import_ascii", "`save` writing the current scene file");
        if (I.currentScene.empty())
            bad_arg("'save' needs a current scene file but none is loaded",
                    "Pass \"path\": \"scenes/x.scene.json\" to build that scene file directly (the running world is "
                    "not touched), "
                    "or load a scene with scene.load first.");
        // `factoria call` without --scene (or a fresh MCP session) runs the project's mainScene because nobody chose a scene.
        // A map file that says "save": true would overwrite it with a map meant for another level.
        if (I.implicitStartScene && !I.cfg.editorMode)
            throw CommandError("unsafe_save",
                               "'save' would overwrite '" + I.currentScene +
                                   "', the project's main scene, which is only running because no scene was chosen "
                                   "(no --scene, no scene.load); nothing was changed",
                               "To build a scene file without touching the running game add \"path\": "
                               "\"scenes/<name>.scene.json\" (and optionally "
                               "\"from\": a base scene). To update the running scene on purpose, choose it first: "
                               "factoria call ... --scene " +
                                   I.currentScene + " (or scene.load), then repeat this call.");
    }
    return q;
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
                set_component(
                    scratch,
                    Json::object({{"id", e.key()}, {"component", c.key()}, {"fields", fields}, {"merge", merge}}));
            } catch (const CommandError& err) {
                throw CommandError(err.code, "edits[\"" + e.key() + "\"][\"" + c.key() + "\"]: " + err.what(),
                                   (err.hint.empty() ? std::string() : err.hint + " ") + "Nothing was written.",
                                   err.data);
            }
        }
}

// ---- prefab references in the written file
// The scratch World remembers which entities a prefab made, so save_scene (PrefabSave::Keep) writes each as {"id",
// "prefab", only the differences}; an entity that an `edits` entry touched keeps its edit as such a difference. The file is
// better as it was authored for the entities nothing touched: legend objects as {"id", "prefab", "tags", "components":
// {overrides + position}} and the base scene's prefab entries exactly as they were, so these two replace what the
// writer produced.
struct PrefabRef {
    Json ref;
    bool fromLegend = false;  // the position comes from the written (expanded) entity
};

void collect_base_refs(const Json& entities, const std::string& skipId, std::map<std::string, PrefabRef>& out) {
    if (!entities.is_array()) return;
    for (const Json& ent : entities) {
        if (!ent.is_object()) continue;
        if (ent.contains("prefab") && ent.contains("id") && ent["id"].is_string() &&
            ent["id"].get<std::string>() != skipId) {
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
            if (auto pf = load_json_file(le.prefab); pf.ok() && pf.value().contains("entity") &&
                                                     pf.value()["entity"].contains("tags") &&
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
Json import_into_scene_file(const Request& q, const Grid& grid, std::vector<LegendEntry>& legend,
                            std::vector<Cell>& cells) {
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
            if (report.error_count() > shown)
                detail += "\n  ... (" + std::to_string(report.error_count() - shown) + " more)";
            throw CommandError(
                "invalid_argument",
                "Cannot edit '" + source + "': it has " + std::to_string(report.error_count()) +
                    " load error(s), and writing the scene back would silently drop the entries that failed to load:" +
                    detail,
                "Fix the file first (project.validate lists every problem with its JSON pointer), or start from "
                "another scene with "
                "\"from\": \"<base scene>\". Nothing was written.");
        }
        for (const LoadMessage& m : report.messages) startWarnings.push_back(m.to_string());
    } else if (!q.from.empty()) {
        std::vector<std::string> scenes = scene_files();
        throw CommandError("not_found", "'from' scene '" + q.from + "' does not exist. " + did_you_mean(q.from, scenes),
                           "'from' is the scene file to start from (e.g. a base scene with the camera and HUD). Use "
                           "project.info to list scenes. "
                           "Nothing was written.");
    } else {
        startedEmpty = true;
    }

    Json out = apply_import(scratch, true, q, grid, legend, cells);
    apply_edits(
        scratch,
        q.edits);  // after the import, so they can also reach what it placed; before the write, so a wrong one writes nothing

    SaveSceneOptions saveOptions;
    saveOptions.prefabs =
        PrefabSave::Keep;  // the instances of the scene stay instances (an edited one keeps its differences)
    Json scene = save_scene(scratch, saveOptions);
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
            out["warnings"].push_back(msg + " Did you mean '" + near + "'? Fix 'path', or pass \"from\": \"" + near +
                                      "\" to build on it.");
        } else {
            add_note(out,
                     msg + " Pass \"from\": \"<base scene>\" to start from an existing scene (camera, HUD, settings).");
        }
    } else if (!q.from.empty() && fs::exists(q.path)) {
        add_note(out, "'" + q.path + "' " + (q.dryRun ? "would be replaced" : "was replaced") +
                          " by the result of importing into '" + q.from + "'.");
    }
    if (!ends_with(q.path, ".scene.json"))
        out["warnings"].push_back(
            "'" + q.path +
            "' does not end in .scene.json, so project.info, validate and the editor will not list it as a scene.");

    out["dryRun"] = q.dryRun;
    if (q.dryRun) {
        out["scene"] = std::move(scene);
        return out;
    }
    if (auto r = save_scene_json_file(q.path, scene); !r.ok())
        throw CommandError("failed", "The level was imported but writing '" + q.path + "' failed: " + r.error().message,
                           r.error().hint);
    // The running engine is deliberately not told: its World is unchanged. If `path` is the running scene and hot reload
    // is on (windowed play), the file watcher reloads it from disk like after any other edit of the file.
    out["saved"] = q.path;
    return out;
}

Json import_ascii(Engine::Impl& I, const Json& a) {
    // ---- 1. Everything that can be checked from the arguments alone.
    const Grid grid = parse_rows(a);
    if (!a.contains("legend") && !a.contains("legendFrom"))
        bad_arg("Missing 'legend'",
                "Example: \"legend\": {\"#\": 0, \"o\": {\"prefab\": \"prefabs/coin.prefab.json\"}}, "
                "or \"legendFrom\": \"levels/legend.json\" for a legend shared by several maps.");
    std::vector<LegendEntry> legend = parse_legend(merged_legend(a));
    if (a.contains("legendFrom"))
        for (LegendEntry& e : legend)
            e.shared = !(a.contains("legend") && a["legend"].is_object() && a["legend"].contains(e.glyph));
    std::vector<Cell> cells = resolve_cells(grid, legend);
    const Request q = parse_import_request(I, a);

    if (!q.path.empty()) return import_into_scene_file(q, grid, legend, cells);

    // ---- 2. The running world (and, with `save`, the current scene file).
    Json out = apply_import(I.world, !I.inFrame, q, grid, legend, cells);
    if (q.save) {
        auto r = save_scene_file(I.world, I.currentScene, false, nullptr, nullptr,
                                 caller_capabilities().has(Capability::WriteAnywhere));
        if (!r.ok())
            throw CommandError(
                "failed", "The level was imported but writing '" + I.currentScene + "' failed: " + r.error().message,
                r.error().hint);
        if (I.watchSeeded) I.watched[I.currentScene] = fs::modified_time(I.currentScene);
        out["saved"] = I.currentScene;
        add_note(
            out,
            "SAVED '" + I.currentScene +
                "': that is the RUNNING scene, so everything in the running world went into the file (except entities "
                "scripts spawned at runtime). "
                "To change a scene file without touching the running game, pass \"path\" (and optionally \"from\").");
    }
    return out;
}

// ------------------------------------------------------------------------------------------------ scene.ascii_edit
// Edits the `rows` of an import_ascii args file in place (see register_ascii_level_commands for the contract).
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
        if (!op.contains(key))
            bad_arg(std::string("missing '") + key + "'", std::string("Example: \"") + key + "\": \"#\".");
        std::vector<std::string> g =
            op[key].is_string() ? split_glyphs(op[key].get<std::string>()) : std::vector<std::string>();
        if (g.size() != 1)
            bad_arg(std::string("'") + key + "' must be a string of exactly one character, got " +
                        describe_json_value(op[key]),
                    "One map cell is one character, e.g. \"#\" or \"o\".");
        if (!is_default_empty(g[0]) && !find(g[0])) {
            std::vector<std::string> known;
            for (const LegendEntry& e : legend) known.push_back(e.glyph);
            bad_arg("glyph " + show_glyph(g[0]) + " is neither '.' / ' ' (empty) nor in the legend. " +
                        did_you_mean(g[0], known),
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
        if (v < minValue)
            bad_arg(std::string("'") + key + "' must be >= " + std::to_string(minValue) + ", got " + std::to_string(v));
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
                    "col + w must be <= " + std::to_string(grid.width) +
                        " and row + h <= " + std::to_string(grid.height) + ".");
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
                if (e.value("id", std::string()) == mapId && e.contains("components") &&
                    e["components"].contains("Tilemap") && e["components"]["Tilemap"].contains("solidTiles") &&
                    e["components"]["Tilemap"]["solidTiles"].is_array()) {
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
            bad_arg("'above' needs to know which tiles are ground, but the file has no tilemap.solidTiles and the "
                    "scene it builds has "
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
            bad_arg("unknown op '" + name + "'. " + did_you_mean(name, kOps),
                    "Ops: fill, replace, insertColumns, deleteColumns, put.");
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
                bad_arg("columns " + std::to_string(at) + ".." + std::to_string(at + count - 1) +
                        " reach outside the map: " + size_text());
            if (std::size_t(count) == grid.width)
                bad_arg("this would delete every column of the map", "A map needs at least one column.");
            for (auto& row : grid.glyphs) row.erase(row.begin() + at, row.begin() + at + count);
            grid.width -= count;
            changed += count * int(grid.height);
        } else {  // put
            const int col = int_arg(op, "col", 0);
            column_in_range(col);
            const std::string g = glyph_arg(op, "glyph");
            if (op.contains("row") == op.contains("above"))
                bad_arg("give exactly one of 'row' (absolute, 0 = top) or 'above' (cells above the ground, 1 = "
                        "standing on it)",
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
        bad_arg("Missing 'file'", "Example: {\"file\": \"levels/1-1.json\", \"ops\": [{\"op\": \"put\", \"col\": 12, "
                                  "\"glyph\": \"o\", \"above\": 1}]}.");
    if (!a.contains("ops") || !a["ops"].is_array() || a["ops"].empty())
        bad_arg("'ops' must be a non-empty array of operations",
                "Example: \"ops\": [{\"op\": \"fill\", \"rect\": [0, 5, 3, 1], \"glyph\": \"#\"}]. Ops: fill, replace, "
                "insertColumns, deleteColumns, put.");
    // `file` is rewritten (not by a dry run, which needs no writeProject): judged first, before it is read or anything is built.
    const bool dryRun = a.value("dryRun", false), rebuild = a.value("rebuild", true);
    const std::string file =
        scene_file_arg(a["file"], "file", !dryRun, "scene.ascii_edit", dryRun, "level file", "levels/1-1.json");
    if (!fs::exists(file)) {
        std::vector<std::string> jsons = fs::list("", true, ".json");
        throw CommandError("not_found", "'file' '" + file + "' does not exist. " + did_you_mean(file, jsons),
                           "It is a JSON file with the arguments of scene.import_ascii (at least `rows`).");
    }
    auto loaded = load_json_file(file);
    if (!loaded.ok()) bad_arg("'file': " + loaded.error().message, loaded.error().hint);
    if (!loaded.value().is_object())
        bad_arg("'" + file + "' must hold an object with the arguments of scene.import_ascii");

    AsciiEditCtx ctx;
    ctx.args = loaded.value();
    ctx.grid = parse_rows(ctx.args);
    ctx.legend = parse_legend(merged_legend(ctx.args));

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

void register_ascii_level_commands(Engine& engine, Engine::Impl& I) {
    I.commands.add(
        {"scene.import_ascii",
         "Build a Tilemap level and the objects standing on it (coins, enemies, spawn points) from ASCII rows and a "
         "legend.",
         "Author a tile level as text. `rows` is the map, one string per row, ONE CHARACTER PER TILE, row 0 "
         "= the TOP row (all rows the same length). `legend` maps each character to a tile index (integer) "
         "or to an object: {\"tile\"?: int, \"prefab\"?: \"prefabs/x.prefab.json\", \"id\"?: \"player\", "
         "\"overrides\"?: {component patches}, \"offset\"?: [dx, dy]}. '.' and ' ' are empty tiles unless "
         "the legend defines them. A glyph with a `tile` draws that tile; with a `prefab` it also spawns the "
         "prefab at the CENTRE of its cell (a glyph may have both; a prefab-only glyph leaves the tile "
         "empty). `overrides` patch the prefab's components per glyph; `offset` shifts the object (world "
         "units) from the cell centre. The tilemap is the entity `entity` (default \"tilemap\"): created "
         "when missing, updated when it exists; `tilemap` sets its Tilemap fields (tileset, tileSize, "
         "projection, groundHeight, groundOffset, margin, spacing, columns, solidTiles, color, layer; "
         "columns is optional: left at 0 it is derived from the tileset width, tileSize.x, margin and "
         "spacing)." FA_COMMAND_DETAILS
         "Its position is the map's TOP-LEFT corner (+Y up, like Tilemap everywhere; an isometric map's "
         "position is its TOP corner, and objects stand at the centres of its diamonds); pass `position` (+ "
         "`anchor`: top-left, bottom-left or center) to place it, e.g. anchor bottom-left at [0,0] puts the "
         "level's floor at y=0. Objects are ordinary top-level entities that save with the scene; ids are "
         "`id` from the legend (unique objects such as \"player\") or generated in row-major order as "
         "<prefab name>_<n> (coin_1, coin_2...); every object is tagged \"tilemap:<entity>\". With `replace` "
         "(default true) the objects of earlier imports into the same tilemap are destroyed first, so "
         "re-importing an edited map does not duplicate them. `legendFrom` names a JSON file with a legend "
         "shared by several maps (e.g. \"levels/legend.json\"); it is merged under `legend` (the map's own "
         "entry wins for a glyph) and its unused entries are not warned about. TWO WAYS TO USE IT. (1) With "
         "`path` it edits that scene FILE and nothing else: the file (or `from`, a base scene to start from; "
         "a missing `path` without `from` starts as an empty scene) is loaded into a scratch world, the map "
         "is imported into it and the result is written to `path` in the canonical layout of scene.save. The "
         "running world, audio, physics and scripts are not touched, so it is safe to call from a tool or a "
         "one-shot `factoria call` and the file can be rebuilt as often as needed. The file keeps PREFAB "
         "REFERENCES instead of expanding prefabs: each legend object is written as {\"id\", \"prefab\", "
         "\"tags\", \"components\": {the legend overrides + Transform.position}} and the prefab entries of "
         "the base scene stay as they are, so editing a prefab file changes every level without importing "
         "again and level files stay small (a scene loaded into the world still expands them). An entity "
         "that `edits` touches is written as its prefab plus the differences (the edit). `dryRun` writes "
         "nothing and returns the scene JSON in `scene`. `edits` (file mode only) patches components of that "
         "scene's entities right after the map is imported and before the write, e.g. the camera and sky "
         "colour of a base scene: {\"<entity id>\": {\"<Component>\": {field: value}}}, each entry exactly "
         "scene.set_component (a missing component is added, only the given fields change, and a value "
         "outside a field's range is refused; Script.props is replaced as a whole unless the edit has "
         "\"$merge\": true next to its fields, e.g. {\"level\": {\"Script\": {\"$merge\": true, \"props\": "
         "{\"levelIndex\": 3}}}}, which merges the given props into the current ones as an RFC 7386 JSON "
         "merge-patch: other props stay, null deletes one); a wrong entity, component or field fails the "
         "call naming it, with suggestions, and writes nothing. If the file has load errors the call fails "
         "instead of dropping them. (2) Without `path` it changes the RUNNING world (like scene.spawn); "
         "`save` then also writes the current scene file like scene.save, so it needs a scene you chose "
         "(--scene or scene.load): when the running scene is only the project's mainScene loaded by default, "
         "`save` is refused (error unsafe_save) instead of overwriting it. With `path`, `save` is ignored: "
         "the file is always written. Nothing is changed when an argument is wrong: errors name the "
         "row/column, the glyph, the legend and suggestions. Returns {tilemap, created, width, height, "
         "tileCount, spawned:[{id, prefab, glyph, cell:[col,row], position:[x,y]}], removed, tag, warnings, "
         "notes?, saved?} plus, with `path`, {path, from (the file it started from, null = empty scene), "
         "entityCount, dryRun, scene? (dryRun)}. Example: scene.import_ascii "
         "{\"rows\":[\"..........\",\"...o..o...\",\".P......o.\",\"##########\"],\"legend\":{\"#\":0,\"o\":{"
         "\"prefab\":\"prefabs/coin.prefab.json\"},\"P\":{\"prefab\":\"prefabs/"
         "player.prefab.json\",\"id\":\"player\"}},\"tilemap\":{\"tileset\":\"assets/"
         "tiles.png\",\"tileSize\":[32,32],\"solidTiles\":[0]},\"anchor\":\"bottom-left\",\"position\":[0,0],\"path\":"
         "\"scenes/level1.scene.json\",\"from\":\"levels/base.scene.json\"}",
         import_ascii_schema(), false, "scene"},
        [&I](const Json& a) { return import_ascii(I, a); });

    I.commands.add({"scene.ascii_edit",
                    "Edit the ASCII map of a level file (a scene.import_ascii args file) with operations instead of "
                    "rewriting rows, then rebuild the level.",
                    "`file` is a project-relative JSON file holding scene.import_ascii arguments (at least `rows`; its "
                    "legend is `legend` merged over `legendFrom`). `ops` run in order, all-or-nothing (an error names "
                    "the op, e.g. ops[2], and nothing is written). Columns and rows are 0-based, row 0 = TOP, like "
                    "import_ascii. Ops: {op:'fill', rect:[col,row,w,h], glyph}; {op:'replace', from, to, rect?} (whole "
                    "map without rect); {op:'insertColumns', at, count, glyph?} (without glyph the new columns repeat "
                    "the column left of `at` (column 0 when at = 0) with every glyph that spawns an object turned into "
                    "'.', so the ground continues and nothing is duplicated); {op:'deleteColumns', at, count}; "
                    "{op:'put', col, glyph, row} or {op:'put', col, glyph, above:h} = h rows above the ground of that "
                    "column (1 = standing on it; ground = the topmost cell whose glyph is a tile in the file's "
                    "tilemap.solidTiles, else the Tilemap of the scene the file builds). A glyph that is not '.', ' ' "
                    "or in the legend is refused with suggestions. Example: scene.ascii_edit "
                    "{\"file\":\"levels/"
                    "1-1.json\",\"ops\":[{\"op\":\"put\",\"col\":40,\"glyph\":\"o\",\"above\":1},{\"op\":"
                    "\"insertColumns\",\"at\":60,\"count\":5}]}" FA_COMMAND_DETAILS
                    "The edited `rows` are written back to `file` (one row per line, every other key and the key order "
                    "kept). With `rebuild` (default true) and a `path` in the file, the level is then rebuilt exactly "
                    "like `factoria call scene.import_ascii @file` and its result is merged into this one (`spawned` "
                    "lists id, glyph and cell [col,row] of every object). `dryRun` writes nothing and returns the "
                    "edited `rows` (and the import's dry run). Returns {file (written unless dryRun), width, height, "
                    "ops (applied), changedCells (cells whose glyph changed; inserted/deleted columns count all their "
                    "cells), dryRun, rows? (dryRun)} plus the import result when it ran (its `path` and `saved` name "
                    "the scene file).",
                    parse_schema(R"json({"type":"object","required":["file","ops"],"properties":{
               "file":{"type":"string","x-fa-path":"write","description":"Project-relative JSON file with scene.import_ascii arguments (rows, legend/legendFrom, tilemap, path...); the edited rows are written back to it, so it stays inside the project (absolute paths need writeAnywhere)."},
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
               "dryRun":{"type":"boolean","default":false,"description":"Write nothing; return the edited rows (and the import's dry run). Needs no writeProject: `file` is only read."}}})json"),
                    false, "scene"},
                   [&I](const Json& a) { return ascii_edit(I, a); });

    // Capabilities (capability.h): what each command does outside the engine's memory.
    declare_command_capabilities(
        I.commands,
        {
            // Declared for what they do by default (the running world, or a dry run); a call that writes a file asks for
            // writeProject itself (resolve_caller_project_path, require_capability), so `dryRun` needs none.
            {"scene.import_ascii", capability_sets::changes_state()},
            {"scene.ascii_edit", capability_sets::changes_state()},
        });
}

}  // namespace fa
