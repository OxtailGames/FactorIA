// Commands that write scene and prefab FILES (as opposed to scene.spawn & co., which change the running world):
//   prefab.save   saves an entity of the running world, with its children, as a prefab file;
//   scene.format  rewrites scene and prefab files in the canonical compact layout without loading them.
// Both write through dump_scene_json / save_scene_json_file, so the layout is the one scene.save produces.
#include <algorithm>
#include <charconv>
#include <filesystem>
#include <set>

#include "engine_impl.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/scene/serialize.h"

namespace fa {

namespace {

namespace sfs = std::filesystem;

constexpr const char* kPrefabExt = ".prefab.json";
constexpr const char* kSceneExt = ".scene.json";
// scene.import_ascii tags the objects it places with "tilemap:<tilemap id>" (see level_commands.cpp).
constexpr const char* kTilemapTagPrefix = "tilemap:";

[[noreturn]] void bad_arg(const std::string& message, const std::string& hint = {}) {
    throw CommandError("invalid_argument", message, hint);
}

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

// Project-relative, normalized form of `raw` (absolute paths inside the project are converted). Throws when the path
// leaves the project, also through a symbolic link. "" is the project root.
std::string project_relative(const std::string& raw, const std::string& what) {
    if (raw.empty()) bad_arg(what + " is empty.", "Use a project-relative path such as prefabs/enemy.prefab.json.");
    auto norm = fs::normalize_checked(raw);
    if (!norm.ok()) bad_arg(what + ": " + norm.error().message, norm.error().hint);
    std::error_code ec;
    const sfs::path root = sfs::weakly_canonical(fs::project_root(), ec);
    const sfs::path full = ec ? sfs::path() : sfs::weakly_canonical(fs::resolve(norm.value()), ec);
    const sfs::path rel = ec ? sfs::path() : full.lexically_relative(root);
    if (ec || rel.empty() || *rel.begin() == "..")
        bad_arg(what + " '" + raw + "' is outside the project (" + root.generic_string() + ").",
                "These commands only touch files inside the project; use a project-relative path such as "
                "prefabs/enemy.prefab.json.");
    if (!fs::is_absolute(norm.value())) return norm.value();
    std::string out = rel.generic_string();
    return out == "." ? std::string() : out;
}

// ------------------------------------------------------------------------------------------------- prefab.save
// Calls fn(component type, field, target) for every non-null Entity-typed field of the entity's components.
template <class Fn>
void each_entity_ref(const World& w, Entity e, Fn&& fn) {
    for (const TypeInfo* t : w.components_of(e)) {
        const void* obj = w.get(e, *t);
        if (!obj) continue;
        for (const FieldInfo& f : t->fields) {
            if (f.kind != FieldKind::Entity || !f.serialized) continue;
            const Entity target = *static_cast<const Entity*>(f.ptr(obj));
            if (w.alive(target)) fn(*t, f, target);
        }
    }
}

void collect_tree(const World& w, Entity e, std::vector<Entity>& out) {
    out.push_back(e);
    for (Entity c : w.children(e)) collect_tree(w, c, out);
}

void add_note(std::vector<std::string>& notes, std::string note) {
    if (std::find(notes.begin(), notes.end(), note) == notes.end()) notes.push_back(std::move(note));
}

// Removes from the entity JSON (make_prefab output) what belongs to this running instance and not to the reusable
// thing. `j` mirrors the world tree below `e` (same children, same order).
void strip_instance_state(const World& w, Entity e, Json& j, bool isRoot, const std::set<std::string>& treeIds,
                          const std::set<std::string>& keepIds, std::vector<std::string>& notes) {
    // Ids: every instantiation gets fresh ones. Only ids another entity of the tree points at stay.
    if (!keepIds.count(w.id_of(e))) j.erase("id");

    // Tags set by scene.import_ascii: kept, a re-import of that map would destroy every instance of the prefab.
    if (j.contains("tags") && j["tags"].is_array()) {
        Json kept = Json::array();
        for (const Json& tag : j["tags"]) {
            if (tag.is_string() && starts_with(tag.get<std::string>(), kTilemapTagPrefix)) {
                add_note(notes, "Tag '" + tag.get<std::string>() +
                                    "' was not saved: scene.import_ascii adds it to the objects it places, and a prefab "
                                    "carrying it would be destroyed when that map is re-imported.");
                continue;
            }
            kept.push_back(tag);
        }
        if (kept.empty()) j.erase("tags");
        else j["tags"] = kept;
    }

    // Entity fields pointing outside the saved tree would dangle in every instance.
    if (j.contains("components") && j["components"].is_object()) {
        each_entity_ref(w, e, [&](const TypeInfo& type, const FieldInfo& field, Entity target) {
            if (treeIds.count(w.id_of(target))) return;
            Json& comps = j["components"];
            if (!comps.contains(type.name) || !comps[type.name].is_object()) return;
            if (!comps[type.name].contains(field.name)) return;
            comps[type.name].erase(field.name);
            add_note(notes, type.name + "." + field.name + " of '" + w.id_of(e) + "' points at '" + w.id_of(target) +
                                "', which is outside the saved entity, so it was left empty.");
        });
    }

    if (isRoot) {
        if (!w.info(e).active)
            add_note(notes, "The entity is inactive (active: false), so every instance of the prefab starts inactive.");
        if (j.contains("components") && j["components"].is_object() && j["components"].contains("Transform")) {
            Json& tf = j["components"]["Transform"];
            if (tf.is_object() && tf.contains("position")) {
                add_note(notes, "Transform.position " + tf["position"].dump() +
                                    " of the root was not saved: it is where this instance stands, not part of the prefab "
                                    "(children keep their positions relative to the root).");
                tf.erase("position");
                if (tf.empty()) j["components"].erase("Transform");
            }
            if (j["components"].empty()) j.erase("components");
        }
    }

    if (j.contains("children") && j["children"].is_array()) {
        const auto& kids = w.children(e);
        for (std::size_t i = 0; i < kids.size() && i < j["children"].size(); ++i)
            strip_instance_state(w, kids[i], j["children"][i], false, treeIds, keepIds, notes);
    }
}

// "prefabs/enemy.prefab.json" for whatever the caller wrote as a path.
std::string suggest_prefab_path(const std::string& path, const std::string& fallbackName) {
    std::string name = fs::filename(path);
    for (const char* ext : {".json", ".prefab", ".scene"})
        if (ends_with(to_lower(name), ext)) name.resize(name.size() - std::string(ext).size());
    if (name.empty() || name == ".") name = fallbackName;
    std::string dir = fs::parent(path);
    return fs::join(dir.empty() || dir == "scenes" ? "prefabs" : dir, name + kPrefabExt);
}

Json prefab_save(Engine::Impl& I, const Json& a) {
    World& W = I.world;
    const Entity e = need_entity(W, a, "id");
    const std::string rawPath = a.value("path", std::string());
    std::string path = project_relative(rawPath, "'path'");
    if (!ends_with(to_lower(path), kPrefabExt) || fs::filename(path).size() <= std::string(kPrefabExt).size()) {
        std::string fallback = W.id_of(e);
        const std::string suggestion = suggest_prefab_path(path, fallback);
        if (ends_with(to_lower(path), kSceneExt))
            bad_arg("'path' is '" + rawPath + "', a scene file name, but prefab.save writes prefabs.",
                    "Use scene.save to save the whole running world as a scene, or name the prefab '" + suggestion + "'.");
        bad_arg("'path' must end in " + std::string(kPrefabExt) + ", got '" + rawPath + "'.",
                "Use '" + suggestion + "'. Prefabs live in prefabs/ so that project.info and project.validate find them.");
    }
    const bool overwrite = a.value("overwrite", false);
    const bool existed = fs::exists(path);
    if (existed && fs::is_directory(path))
        bad_arg("'" + path + "' is a folder, not a file.", "Give a file name, e.g. " + path + "/enemy.prefab.json.");
    if (existed && !overwrite)
        throw CommandError("already_exists", "'" + path + "' already exists, so it was not overwritten.",
                           "Pass {\"overwrite\": true} to replace it, or choose another name, e.g. '" +
                               path.substr(0, path.size() - std::string(kPrefabExt).size()) + "_2" + kPrefabExt + "'.");

    std::vector<Entity> tree;
    collect_tree(W, e, tree);
    std::set<std::string> treeIds, keepIds;
    for (Entity x : tree) treeIds.insert(W.id_of(x));
    for (Entity x : tree)
        each_entity_ref(W, x, [&](const TypeInfo&, const FieldInfo&, Entity target) {
            if (treeIds.count(W.id_of(target))) keepIds.insert(W.id_of(target));
        });

    Json prefab = make_prefab(W, e);
    std::vector<std::string> notes;
    strip_instance_state(W, e, prefab["entity"], true, treeIds, keepIds, notes);
    if (!starts_with(path, "prefabs/"))
        add_note(notes, "Saved outside prefabs/: project.info and project.validate only look for prefabs in prefabs/.");

    auto saved = save_scene_json_file(path, prefab);
    if (!saved.ok()) throw CommandError("failed", saved.error().message, saved.error().hint);

    Json out = Json::object();
    out["path"] = path;
    out["entity"] = W.id_of(e);
    out["children"] = tree.size() - 1;
    out["overwritten"] = existed;
    if (!notes.empty()) out["notes"] = notes;
    return out;
}

// ------------------------------------------------------------------------------------------------ scene.format
// "path:LINE:COL: invalid JSON: ..." (parse_json) -> line and column; false when the message has another shape.
bool parse_location(const std::string& message, const std::string& file, int& line, int& column) {
    if (!starts_with(message, file + ":")) return false;
    const char* p = message.data() + file.size() + 1;
    const char* end = message.data() + message.size();
    auto [p1, ec1] = std::from_chars(p, end, line);
    if (ec1 != std::errc() || p1 == end || *p1 != ':') return false;
    auto [p2, ec2] = std::from_chars(p1 + 1, end, column);
    return ec2 == std::errc();
}

Json file_error(const std::string& file, const Error& err) {
    Json j = Json::object();
    j["file"] = file;
    int line = 0, column = 0;
    if (parse_location(err.message, file, line, column)) {
        j["line"] = line;
        j["column"] = column;
    }
    j["message"] = err.message;
    j["hint"] = (err.hint.empty() ? "" : err.hint + " ") + "The file was left unchanged.";
    return j;
}

// The scene/prefab files `paths` selects (all of the project when absent), sorted and without duplicates. Every problem
// with the arguments is thrown here, before any file is touched. `searched` gets the folders that were searched.
std::set<std::string> select_files(const Json& a, std::vector<std::string>& searched) {
    std::set<std::string> files;
    if (!a.contains("paths")) {
        searched.push_back("");
        for (const std::string& f : project_scene_files("")) files.insert(f);
        return files;
    }
    const Json& paths = a["paths"];
    if (!paths.is_array() || paths.empty())
        bad_arg("'paths' must be a non-empty array of project-relative files or folders.",
                "Omit 'paths' to format every scene and prefab of the project, or pass e.g. "
                "[\"scenes\", \"prefabs/enemy.prefab.json\"].");
    for (std::size_t i = 0; i < paths.size(); ++i) {
        const std::string what = "paths[" + std::to_string(i) + "]";
        if (!paths[i].is_string())
            bad_arg(what + " must be a string, got " + describe_json_value(paths[i]), "Example: \"paths\": [\"scenes\"].");
        const std::string rel = project_relative(paths[i].get<std::string>(), what);
        if (fs::is_directory(rel)) {
            searched.push_back(rel);
            for (const std::string& f : project_scene_files(rel)) files.insert(f);
        } else if (fs::exists(rel)) {
            if (!is_scene_or_prefab_file(rel))
                bad_arg(what + " '" + rel + "' is not a scene or prefab file.",
                        "Scene files end in " + std::string(kSceneExt) + " and prefab files in " + kPrefabExt +
                            "; to format all of them pass a folder instead.");
            files.insert(rel);
        } else {
            throw CommandError("not_found", what + " '" + rel + "' does not exist. " + did_you_mean(rel, project_scene_files("")),
                               "Pass scene/prefab files or folders of the project; project.info lists the scenes and prefabs.");
        }
    }
    return files;
}

Json scene_format(Engine::Impl& I, const Json& a) {
    const bool check = a.value("check", false);
    const bool strict = a.value("strict", false);  // only meaningful with `check`: without it the files are fixed, not listed
    std::vector<std::string> searched;  // folders searched, for the note when nothing was found
    const std::set<std::string> files = select_files(a, searched);

    Json formatted = Json::array(), notCanonical = Json::array(), errors = Json::array();
    std::size_t unchanged = 0;
    for (const std::string& f : files) {
        auto layout = canonical_scene_layout(f);
        if (!layout.ok()) {
            errors.push_back(file_error(f, layout.error()));
        } else if (layout->same) {
            ++unchanged;
        } else if (check) {
            notCanonical.push_back(f);
        } else if (auto written = fs::write_text(f, layout->text); !written.ok()) {
            errors.push_back(file_error(f, written.error()));
        } else {
            // The data is the same, so a running game has no reason to hot-reload the scene it is playing.
            if (I.watchSeeded && I.watched.count(f)) I.watched[f] = fs::modified_time(f);
            formatted.push_back(f);
        }
    }

    if (check && strict && !notCanonical.empty()) {
        constexpr std::size_t kListed = 10;
        std::string list;
        for (std::size_t i = 0; i < notCanonical.size() && i < kListed; ++i)
            list += (i ? ", " : "") + notCanonical[i].get<std::string>();
        if (notCanonical.size() > kListed) list += ", and " + std::to_string(notCanonical.size() - kListed) + " more";
        throw CommandError("not_canonical",
                           std::to_string(notCanonical.size()) + " scene/prefab file(s) are not in the canonical layout: " + list + ".",
                           "Run scene.format without 'check' (factoria call scene.format '{}') to rewrite them; only whitespace changes.");
    }

    Json out = Json::object();
    if (check) out["notCanonical"] = notCanonical;
    else out["formatted"] = formatted;
    out["unchanged"] = unchanged;
    out["errors"] = errors;
    if (files.empty()) {
        std::string where;
        for (const std::string& s : searched) {
            if (!where.empty()) where += ", ";
            where += s.empty() ? std::string("the project") : "'" + s + "'";
        }
        out["notes"] = Json::array({"No " + std::string(kSceneExt) + " or " + kPrefabExt + " files found in " + where + "."});
    }
    return out;
}

}  // namespace

void register_scene_file_commands(Engine& engine, Engine::Impl& I) {
    (void)engine;
    I.commands.add(
        {"prefab.save", "Save an entity of the running world, with its children, as a prefab file.",
         "Writes {\"format\":\"factoria.prefab/1\",\"entity\":{...}} in the canonical compact layout (the one scene.save and "
         "scene.format write), ready to commit and to instantiate with scene.spawn {\"prefab\":path}, a scene entity "
         "{\"prefab\":path} or a scene.import_ascii legend. `id` is the id (or name) of an entity of the running world; the whole "
         "tree below it is saved with every component's non-default serialized fields (runtime state such as velocities and "
         "animation time is not). A prefab describes the reusable thing, not this instance, so the file does NOT carry: the ids "
         "(every instantiation gets fresh ones; an id stays only where another entity of the saved tree points at it through an "
         "Entity field, so those references survive); the root's Transform.position (where the instance happens to stand: the "
         "spawn call, the scene entity or the legend places each new instance; children keep their positions relative to the "
         "root; rotation and scale are kept); tags starting with 'tilemap:' (scene.import_ascii adds them to the objects it "
         "places, and a prefab carrying one would be destroyed when that map is re-imported); Entity fields pointing at an entity "
         "outside the saved tree (they would dangle). An entity created from a prefab saves fully expanded (no `prefab` key). "
         "To keep the exact position, save the whole world with scene.save instead. `path` is project-relative (or absolute "
         "inside the project), must end in .prefab.json and normally lives in prefabs/. An existing file is NOT replaced unless "
         "`overwrite` is true. Returns {path, entity (id of the saved entity in the running world), children (number of saved "
         "descendants), overwritten, notes?}; `notes` lists what was left out of the file when something noteworthy was. Errors "
         "name the id with did-you-mean suggestions or the path rule with a corrected name. Example: "
         "prefab.save {\"id\":\"enemy_3\",\"path\":\"prefabs/enemy.prefab.json\"}",
         parse_schema(R"({"type":"object","required":["id","path"],"properties":{
               "id":{"type":"string","description":"Id (or name) of the entity to save; its children are saved with it."},
               "path":{"type":"string","description":"Project-relative output path ending in .prefab.json, e.g. prefabs/enemy.prefab.json."},
               "overwrite":{"type":"boolean","default":false,"description":"Replace the file when it already exists. Without it an existing file is an error."}}})"),
         false, "scene"},
        [&I](const Json& a) { return prefab_save(I, a); });

    I.commands.add(
        {"scene.format", "Rewrite scene and prefab files in the canonical compact layout, without loading them.",
         "Parses every *.scene.json and *.prefab.json file and writes it back exactly as the engine writes scenes (2-space "
         "indent, short arrays of numbers and strings on one line, long ones wrapped at about 100 columns, a Tilemap's `tiles` "
         "one map row per line). Run it after editing scenes or prefabs by hand so diffs stay small and the maps stay readable. "
         "Only whitespace changes: values and key order are kept, and every file is read back and compared with the original "
         "data before it is written. Nothing is loaded into the running world, so nothing else changes (files that already "
         "have the canonical layout are not touched). `paths` lists files (names ending in .scene.json or .prefab.json) or "
         "folders (searched recursively), project-relative; default: the whole project, skipping folders that start with '.', "
         "node_modules and a top-level build/. With `check` true nothing is written: the files that are not canonical are "
         "listed (use it in CI or to review). A file that is not valid JSON is reported in `errors` with its file, line and "
         "column and skipped; the other files are still processed. Returns {formatted: [paths], unchanged: n, errors: "
         "[{file, line?, column?, message, hint?}], notes?}, or with `check`: {notCanonical: [paths], unchanged: n, errors, "
         "notes?}. With `check` and `strict` the command FAILS (error code not_canonical, the message lists the files, the hint "
         "says to run scene.format without `check`) when any file is not canonical: `factoria call` exits non-zero, so a CI "
         "step can gate on it. project.validate lists the non-canonical ones in one informational note (not a warning). Example: "
         "scene.format {\"paths\":[\"prefabs\"],\"check\":true}",
         parse_schema(R"({"type":"object","properties":{
               "paths":{"type":"array","minItems":1,"items":{"type":"string"},
                        "description":"Scene/prefab files or folders (recursive), project-relative. Default: every *.scene.json and *.prefab.json in the project."},
               "check":{"type":"boolean","default":false,
                        "description":"true = write nothing, only list (notCanonical) the files whose layout differs from the canonical one."},
               "strict":{"type":"boolean","default":false,
                         "description":"With check: fail with error code not_canonical when any file is not canonical, instead of only listing it. Ignored without check."}}})"),
         false, "scene"},
        [&I](const Json& a) { return scene_format(I, a); });
}

}  // namespace fa
