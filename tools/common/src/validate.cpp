#include "fa/tooling/validate.h"

#include <algorithm>
#include <filesystem>
#include <set>
#include <sstream>

#include "fa/core/asset_manifest.h"
#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/core/reflect.h"
#include "fa/core/strings.h"
#include "fa/platform/input.h"
#include "fa/runtime/project.h"
#include "fa/scene/serialize.h"
#include "fa/scene/tilemap.h"
#include "fa/scene/world.h"
#include "fa/tooling/audio_analysis.h"
#include "fa/tooling/export_settings.h"
#include "fa/tooling/feedback.h"
#include "fa/tooling/icons.h"
#include "assets_internal.h"
#include "util.h"

namespace fa {

namespace stdfs = std::filesystem;

namespace {
struct PropsCheck {
    std::string file, pointer, module;
    Json props;
};

struct Ctx {
    std::string dir;
    std::vector<PropsCheck> propChecks;
    std::set<std::string> spriteTextures;  // what Sprites draw, for the asset checks
    ValidationReport report;
    void error(std::string file, std::string pointer, std::string msg, std::string hint = {}) {
        report.errors.push_back({std::move(file), std::move(pointer), std::move(msg), std::move(hint)});
    }
    void warn(std::string file, std::string pointer, std::string msg, std::string hint = {}) {
        report.warnings.push_back({std::move(file), std::move(pointer), std::move(msg), std::move(hint)});
    }
};

bool is_builtin_mesh(const std::string& m) {
    static const std::set<std::string> v = {"cube", "sphere", "plane", "cylinder", "capsule", "cone", "quad"};
    return v.count(m) > 0;
}

// Restores the global VFS root on scope exit.
struct RootGuard {
    stdfs::path saved;
    explicit RootGuard(const stdfs::path& root) : saved(fs::project_root()) { fs::set_project_root(root); }
    ~RootGuard() { fs::set_project_root(saved); }
};

void check_asset_value(Ctx& c, const std::string& file, const std::string& pointer, const FieldInfo& f,
                       const Json& value) {
    if (!value.is_string()) return;
    std::string path = value.get<std::string>();
    if (path.empty()) return;
    if (f.assetType == "mesh" && is_builtin_mesh(path)) return;
    if (!stdfs::exists(stdfs::path(c.dir) / path)) {
        // Suggest a similar file in the same folder.
        std::string hint = "Create the file or fix the path (project-relative, forward slashes).";
        stdfs::path parent = (stdfs::path(c.dir) / path).parent_path();
        std::error_code ec;
        if (stdfs::is_directory(parent, ec)) {
            std::vector<std::string> names;
            for (const auto& e : stdfs::directory_iterator(parent, ec)) names.push_back(e.path().filename().string());
            std::string m = closest_match(stdfs::path(path).filename().string(), names);
            if (!m.empty()) hint = "Did you mean '" + (stdfs::path(path).parent_path() / m).generic_string() + "'?";
        }
        c.error(file, pointer, "Asset '" + path + "' (" + f.assetType + ") does not exist.", hint);
    }
}

void check_component_assets(Ctx& c, const std::string& file, const std::string& pointer, const std::string& typeName,
                            const Json& fields) {
    const TypeInfo* t = TypeRegistry::global().find(typeName);
    if (!t || !fields.is_object()) return;
    for (const FieldInfo& f : t->fields) {
        if (f.kind != FieldKind::Asset || !fields.contains(f.name)) continue;
        check_asset_value(c, file, pointer + "/" + f.name, f, fields[f.name]);
    }
}

// The structure of Tilemap data (tiles vs width*height, rows, solidTiles) is checked by the scene loader; here the tile
// indices are compared with the tileset image, which needs the file. `fields` is the Tilemap object as written.
void check_tilemap_tileset(Ctx& c, const std::string& file, const std::string& pointer, const Json& fields) {
    if (!fields.is_object() || !fields.contains("tileset") || !fields["tileset"].is_string() || !fields.contains("tiles") ||
        !fields["tiles"].is_array())
        return;
    const std::string path = fields["tileset"].get<std::string>();
    if (path.empty() || !stdfs::exists(stdfs::path(c.dir) / path)) return;  // a missing file is reported as a missing asset
    auto img = load_image(path);
    if (!img.ok()) return;
    Tilemap tm;
    if (fields.contains("tileSize") && fields["tileSize"].is_array() && fields["tileSize"].size() == 2 &&
        fields["tileSize"][0].is_number() && fields["tileSize"][1].is_number())
        tm.tileSize = {fields["tileSize"][0].get<float>(), fields["tileSize"][1].get<float>()};
    if (fields.contains("columns") && fields["columns"].is_number_integer()) tm.columns = fields["columns"].get<int>();
    const int count = tileset_tile_count(tm, img->width, img->height);
    if (count <= 0) return;
    // First offending tile (flat or rows form) and how many there are.
    std::string firstPointer;
    long long firstValue = 0, offenders = 0;
    auto visit = [&](const Json& v, const std::string& ptr) {
        if (!v.is_number() || v.get<double>() < count) return;
        if (offenders++ == 0) {
            firstPointer = ptr;
            firstValue = static_cast<long long>(v.get<double>());
        }
    };
    const Json& tiles = fields["tiles"];
    for (std::size_t i = 0; i < tiles.size(); ++i) {
        if (tiles[i].is_array())
            for (std::size_t k = 0; k < tiles[i].size(); ++k) visit(tiles[i][k], "/tiles/" + std::to_string(i) + "/" + std::to_string(k));
        else
            visit(tiles[i], "/tiles/" + std::to_string(i));
    }
    if (offenders == 0) return;
    // `columns` unset (0) is derived from the image, so a mismatch can only come from an explicit value.
    const int tilesX = std::max(0, int(float(img->width) / tm.tileSize.x));
    const int columns = tileset_columns(tm, img->width);
    std::string hint = "Tile indices count from 0, left-to-right then top-to-bottom, so valid indices are 0.." + std::to_string(count - 1) + ".";
    if (tm.columns > 0 && tm.columns != tilesX && tilesX > 0)
        hint += " The image has " + std::to_string(tilesX) + " tile columns but columns is " + std::to_string(tm.columns) +
                ": remove \"columns\" (it is derived from the image) or set \"columns\": " + std::to_string(tilesX) + ".";
    c.error(file, pointer + firstPointer,
            "Tile index " + std::to_string(firstValue) + " is outside the tileset '" + path + "' (" + std::to_string(img->width) + "x" + std::to_string(img->height) +
                " px, tileSize [" + std::to_string(int(tm.tileSize.x)) + ", " + std::to_string(int(tm.tileSize.y)) + "], columns " + std::to_string(columns) +
                " = " + std::to_string(count) + " tiles)" + (offenders > 1 ? "; " + std::to_string(offenders - 1) + " more tile(s) are outside too" : ""),
            hint);
}

// A texture of an atlas group (import setting `atlas`) is drawn from the packed atlas once the game is exported, which
// only 2D sprites and particles do: any other texture field (a tileset, a mesh texture) would show the whole atlas.
// The VFS root is the project (its assets.json is the one asked).
void check_atlas_use(Ctx& c, const std::string& file, const std::string& pointer, const std::string& typeName, const Json& fields) {
    if (typeName != "Tilemap" && typeName != "MeshRenderer") return;  // the others draw through the atlas rectangle
    const TypeInfo* t = TypeRegistry::global().find(typeName);
    if (!t || !fields.is_object()) return;
    for (const FieldInfo& f : t->fields) {
        if (f.kind != FieldKind::Asset || f.assetType != "texture" || !fields.contains(f.name) || !fields[f.name].is_string()) continue;
        const std::string path = fields[f.name].get<std::string>();
        if (path.empty()) continue;
        const Json settings = assets::import_settings(path);
        const auto group = settings.find("atlas");
        if (group == settings.end() || !group->is_string() || group->get<std::string>().empty()) continue;
        c.warn(file, pointer + "/" + f.name,
               "Texture '" + path + "' is in atlas group \"" + group->get<std::string>() + "\" (assets.json), but " + typeName + "." + f.name +
                   " cannot draw from an atlas: an exported game would show the whole atlas image here.",
               "Set the \"atlas\" import setting of '" + path + "' to \"\" in assets.json, or point " + f.name +
                   " at a copy of the image that is not in a group. Tilemap tilesets and MeshRenderer textures cannot be packed.");
    }
}

void check_entity_assets(Ctx& c, const std::string& file, const std::string& pointer, const Json& entity,
                         std::set<std::string>& scripts) {
    if (!entity.is_object()) return;
    if (entity.contains("prefab") && entity["prefab"].is_string()) {
        std::string pf = entity["prefab"].get<std::string>();
        if (!stdfs::exists(stdfs::path(c.dir) / pf))
            c.error(file, pointer + "/prefab", "Prefab '" + pf + "' does not exist.", "Create it under prefabs/ or fix the path.");
    }
    if (entity.contains("components") && entity["components"].is_object()) {
        for (auto it = entity["components"].begin(); it != entity["components"].end(); ++it) {
            check_component_assets(c, file, pointer + "/components/" + it.key(), it.key(), it.value());
            check_atlas_use(c, file, pointer + "/components/" + it.key(), it.key(), it.value());
            if (it.key() == "Sprite" && it.value().is_object() && it.value().contains("texture") && it.value()["texture"].is_string() &&
                !it.value()["texture"].get<std::string>().empty())
                c.spriteTextures.insert(it.value()["texture"].get<std::string>());
            if (it.key() == "Tilemap") check_tilemap_tileset(c, file, pointer + "/components/Tilemap", it.value());
            if (it.key() == "Script" && it.value().is_object() && it.value().contains("path") && it.value()["path"].is_string()) {
                scripts.insert(it.value()["path"].get<std::string>());
                if (it.value().contains("props") && it.value()["props"].is_object() && !it.value()["props"].empty())
                    c.propChecks.push_back({file, pointer + "/components/Script/props", it.value()["path"].get<std::string>(),
                                            it.value()["props"]});
            }
        }
    }
    if (entity.contains("children") && entity["children"].is_array()) {
        int i = 0;
        for (const auto& ch : entity["children"]) check_entity_assets(c, file, pointer + "/children/" + std::to_string(i++), ch, scripts);
    }
}

// A scene or prefab file whose text differs from the layout the engine writes (scene.format's, shared through
// canonical_scene_layout). A file that cannot be read or parsed is reported elsewhere. The VFS root is the project.
void warn_if_not_canonical(Ctx& c, const std::string& rel) {
    auto layout = canonical_scene_layout(rel);
    if (layout.ok() && !layout->same)
        c.warn(rel, "", "The file is not in the canonical layout (only whitespace differs from what the engine writes).",
               "Run `factoria call scene.format` (command scene.format) to rewrite it; it changes whitespace only, and keeps diffs small.");
}

// A prefab file loaded on its own into a scratch world, so that what the scene loader rejects (an unknown component or
// field, a value outside a field's range...) is reported even when no scene places the prefab. A scene that does place
// it reports the same problem at its own entity; this report names the prefab file, where it is fixed. An Entity field
// pointing at an id outside the prefab is not a problem here: the scene that places the prefab supplies the target.
void check_prefab_loads(Ctx& c, const std::string& rel) {
    World world;
    LoadReport lr;
    instantiate_prefab(world, rel, kNullEntity, lr);
    const std::string note = " (entity expanded from prefab '" + rel + "')";  // the loader adds it to hints; here it is the file itself
    for (const auto& m : lr.messages) {
        if (starts_with(m.message, "No entity with id")) continue;
        ValidationIssue issue{rel, m.pointer == "/prefab" ? std::string() : "/entity" + m.pointer, m.message, m.hint};
        if (ends_with(issue.hint, note)) issue.hint.resize(issue.hint.size() - note.size());
        (m.severity == LoadMessage::Severity::Error ? c.report.errors : c.report.warnings).push_back(std::move(issue));
    }
}

void check_binding(Ctx& c, const std::string& pointer, const std::string& binding) {
    if (Input::is_binding_name(binding)) return;
    c.error(kProjectFileName, pointer, "Unknown input binding '" + binding + "'.", did_you_mean(binding, Input::binding_names()));
}

// An icon file named by factoria.json (`pointer` says which setting): it must exist and decode; a size or shape that
// will look bad is a warning. `path` is "" when the setting is absent (or was rejected by parse_export_settings).
void check_icon_file(Ctx& c, const std::string& pointer, const std::string& path, int recommendedSize = kRecommendedIconSize) {
    if (path.empty()) return;
    std::vector<ExportSettingsIssue> warnings;
    auto img = load_icon_image(c.dir, path, pointer, &warnings, recommendedSize);
    if (!img.ok()) {
        std::string message = img.error().message;
        const std::string prefix = std::string(kProjectFileName) + "#" + pointer + ": ";  // the report prints the location itself
        if (starts_with(message, prefix)) message = message.substr(prefix.size());
        c.error(kProjectFileName, pointer, message, img.error().hint);
        return;
    }
    for (const auto& w : warnings) c.warn(kProjectFileName, w.pointer, w.message, w.hint);
}

// `icon` and `export` of factoria.json: wrong types and values (errors), unknown keys (warnings), icon files that are
// missing or unreadable. The schema reports the same wrong types, so schema errors at these pointers are dropped in
// favour of the settings' own messages (see check_project_file).
void check_export_settings(Ctx& c, const ExportSettingsParse& parsed) {
    for (const auto& e : parsed.errors) c.error(kProjectFileName, e.pointer, e.message, e.hint);
    for (const auto& w : parsed.warnings) c.warn(kProjectFileName, w.pointer, w.message, w.hint);
    const ProjectExportSettings& s = parsed.settings;
    check_icon_file(c, "/icon", s.icon);
    check_icon_file(c, "/export/windows/icon", s.windows.icon);
    check_icon_file(c, "/export/macos/icon", s.macos.icon);
    check_icon_file(c, "/export/linux/icon", s.linux.icon);
    check_icon_file(c, "/export/android/icon", s.android.icon);
    check_icon_file(c, "/export/ios/icon", s.ios.icon);
    constexpr int kLayerSize = 432;  // the xxxhdpi size of an adaptive icon layer
    check_icon_file(c, "/export/android/adaptiveIcon/foreground", s.android.adaptiveIcon.foreground, kLayerSize);
    const std::string& background = s.android.adaptiveIcon.background;
    if (!background.empty() && background[0] != '#') check_icon_file(c, "/export/android/adaptiveIcon/background", background, kLayerSize);
    check_icon_file(c, "/export/android/adaptiveIcon/monochrome", s.android.adaptiveIcon.monochrome, kLayerSize);
}

void check_project_file(Ctx& c, std::string& mainScene, std::string& feedbackFile) {
    auto text = tooling_detail::read_file(stdfs::path(c.dir) / kProjectFileName);
    if (!text) {
        c.error(kProjectFileName, "", "factoria.json not found in " + c.dir + ".",
                "Run from the project folder, or create a project with `factoria new <dir>`.");
        return;
    }
    auto parsed = parse_json(*text, kProjectFileName);
    if (!parsed.ok()) {
        c.error(kProjectFileName, "", parsed.error().message, parsed.error().hint.empty() ? "Fix the JSON syntax." : parsed.error().hint);
        return;
    }
    const Json& pj = parsed.value();
    const ExportSettingsParse exportSettings = parse_export_settings(pj);
    Json schema = tooling_detail::load_schema("schemas/project.schema.json");
    if (!schema.is_null())
        for (const auto& e : validate_json(schema, pj)) {
            // `icon` / `export` problems are reported once, by check_export_settings, with a fix that names the setting.
            const bool reportedBySettings = std::any_of(exportSettings.errors.begin(), exportSettings.errors.end(),
                                                        [&](const ExportSettingsIssue& i) { return i.pointer == e.pointer; });
            if (!reportedBySettings) c.error(kProjectFileName, e.pointer, e.message, e.hint);
        }
    if (!pj.is_object()) return;
    check_export_settings(c, exportSettings);
    mainScene = pj.value("mainScene", std::string("scenes/main.scene.json"));
    feedbackFile = pj.value("feedbackFile", std::string(kFeedbackFileName));
    if (!stdfs::exists(stdfs::path(c.dir) / mainScene))
        c.error(kProjectFileName, "/mainScene", "Main scene '" + mainScene + "' does not exist.",
                "Create it or point mainScene at an existing scene (see scenes/).");
    if (pj.contains("input") && pj["input"].is_object() && pj["input"].contains("actions") && pj["input"]["actions"].is_object()) {
        for (auto it = pj["input"]["actions"].begin(); it != pj["input"]["actions"].end(); ++it) {
            if (!it.value().is_array()) continue;
            int i = 0;
            for (const auto& b : it.value()) {
                if (b.is_string()) check_binding(c, "/input/actions/" + it.key() + "/" + std::to_string(i), b.get<std::string>());
                ++i;
            }
            if (it.value().empty())
                c.warn(kProjectFileName, "/input/actions/" + it.key(), "Action '" + it.key() + "' has no bindings.", "Add at least one key, e.g. [\"Space\"].");
        }
    }
}

void check_feedback_file(Ctx& c, const std::string& file) {
    stdfs::path p = stdfs::path(c.dir) / file;
    if (!stdfs::exists(p)) {
        c.error(file, "", file + " is missing.",
                "Run `factoria feedback init` (or call feedback.report) to create it; every project must keep one.");
        return;
    }
    auto doc = load_feedback(p.string());
    if (!doc.ok()) {
        c.error(file, "", doc.error().message, "Fix the JSON syntax or recreate with `factoria feedback init`.");
        return;
    }
    for (const auto& e : validate_feedback(doc.value())) c.error(file, e.pointer, e.message, e.hint);
}

// assets.json (optional): the schema, and entries whose file no longer exists (renamed or deleted asset).
void check_assets_manifest(Ctx& c) {
    const char* file = assets::kManifestFile;
    auto text = tooling_detail::read_file(stdfs::path(c.dir) / file);
    if (!text) return;
    auto parsed = parse_json(*text, file);
    if (!parsed.ok()) {
        c.error(file, "", parsed.error().message, "Fix the JSON syntax (schemas/assets.schema.json).");
        return;
    }
    const Json& doc = parsed.value();
    Json schema = tooling_detail::load_schema("schemas/assets.schema.json");
    if (!schema.is_null())
        for (const auto& e : validate_json(schema, doc)) c.error(file, e.pointer, e.message, e.hint);
    if (!doc.is_object() || !doc.contains("assets") || !doc["assets"].is_object()) return;
    for (auto it = doc["assets"].begin(); it != doc["assets"].end(); ++it) {
        const stdfs::path path = stdfs::path(c.dir) / it.key();
        if (stdfs::exists(path)) continue;
        std::vector<std::string> siblings;  // a renamed file usually stays in its folder
        std::error_code ec;
        for (const auto& d : stdfs::directory_iterator(path.parent_path(), ec))
            if (d.is_regular_file(ec)) siblings.push_back(stdfs::relative(d.path(), c.dir, ec).generic_string());
        std::string m = closest_match(it.key(), siblings);
        c.warn(file, (Json::json_pointer("/assets") / it.key()).to_string(),
               "Entry for '" + it.key() + "', which does not exist (renamed or deleted?).",
               m.empty() ? "Remove the entry, or restore the file." : "Did you mean '" + m + "'? Rename the key, or remove the entry.");
    }
}

}  // namespace

Json ValidationIssue::to_json() const {
    Json j = Json::object({{"file", file}});
    if (!pointer.empty()) j["pointer"] = pointer;
    j["message"] = message;
    if (!hint.empty()) j["hint"] = hint;
    return j;
}

std::string ValidationIssue::to_string() const {
    std::string s = file;
    if (!pointer.empty()) s += "#" + pointer;
    s += ": " + message;
    if (!hint.empty()) s += " (hint: " + hint + ")";
    return s;
}

Json ValidationReport::to_json() const {
    Json e = Json::array(), w = Json::array();
    for (const auto& i : errors) e.push_back(i.to_json());
    for (const auto& i : warnings) w.push_back(i.to_json());
    return Json::object({{"ok", ok}, {"errors", e}, {"warnings", w}, {"scenesChecked", scenesChecked}, {"scriptsChecked", scriptsChecked}});
}

std::string ValidationReport::to_text() const {
    std::ostringstream o;
    for (const auto& i : errors) o << "error: " << i.to_string() << "\n";
    for (const auto& i : warnings) o << "warning: " << i.to_string() << "\n";
    o << (ok ? "OK" : "FAILED") << ": " << errors.size() << " error(s), " << warnings.size() << " warning(s), "
      << scenesChecked << " scene(s), " << scriptsChecked << " script(s) checked.\n";
    return o.str();
}

ValidationReport validate_project(const std::string& projectDir, const ValidateOptions& options) {
    Ctx c;
    std::error_code ec;
    c.dir = stdfs::absolute(projectDir, ec).lexically_normal().string();
    if (!c.dir.empty() && (c.dir.back() == '/' || c.dir.back() == '\\')) c.dir.pop_back();
    if (!stdfs::is_directory(c.dir, ec)) {
        c.error("", "", "Project directory '" + projectDir + "' does not exist.", "Pass the folder that contains factoria.json.");
        c.report.ok = false;
        return std::move(c.report);
    }

    std::string mainScene, feedbackFile = kFeedbackFileName;
    check_project_file(c, mainScene, feedbackFile);
    check_feedback_file(c, feedbackFile);
    check_assets_manifest(c);
    for (ValidationIssue& w : check_audio_loudness(c.dir)) c.report.warnings.push_back(std::move(w));
    assets_detail::check_shipped_assets(c.dir, c.report.warnings);

    std::set<std::string> scripts;
    if (options.checkScenes) {
        RootGuard guard(c.dir);
        // Every scene and prefab of the project, wherever it lives (scenes/, prefabs/, levels/...): the same files
        // scene.format formats (hidden folders, node_modules and a top-level build/ are skipped).
        std::vector<std::string> sceneFiles, prefabFiles;
        for (const std::string& rel : project_scene_files())
            (ends_with(to_lower(rel), ".scene.json") ? sceneFiles : prefabFiles).push_back(rel);
        for (const auto& rel : sceneFiles) {
            ++c.report.scenesChecked;
            World world;  // registers built-in components
            LoadReport lr = load_scene_file(world, rel);
            for (const auto& m : lr.messages) {
                ValidationIssue issue{m.source.empty() ? rel : m.source, m.pointer, m.message, m.hint};
                // Normalize absolute sources to project-relative.
                if (stdfs::path(issue.file).is_absolute()) issue.file = stdfs::relative(issue.file, c.dir, ec).generic_string();
                (m.severity == LoadMessage::Severity::Error ? c.report.errors : c.report.warnings).push_back(std::move(issue));
            }
            warn_if_not_canonical(c, rel);
            auto text = tooling_detail::read_file(stdfs::path(c.dir) / rel);
            if (!text) continue;
            auto parsed = parse_json(*text, rel);
            if (!parsed.ok()) continue;  // load_scene_file already reported it
            const Json& j = parsed.value();
            if (j.is_object() && j.contains("settings"))
                check_component_assets(c, rel, "/settings", "SceneSettings", j["settings"]);
            if (j.is_object() && j.contains("entities") && j["entities"].is_array()) {
                int i = 0;
                for (const auto& e : j["entities"]) check_entity_assets(c, rel, "/entities/" + std::to_string(i++), e, scripts);
            }
        }
        for (const auto& rel : prefabFiles) {
            auto text = tooling_detail::read_file(stdfs::path(c.dir) / rel);
            auto parsed = text ? parse_json(*text, rel) : Result<Json>(make_error("cannot read " + rel));
            if (!parsed.ok()) { c.error(rel, "", parsed.error().message, "Fix the JSON syntax."); continue; }
            warn_if_not_canonical(c, rel);
            check_prefab_loads(c, rel);
            if (parsed.value().is_object() && parsed.value().contains("entity"))
                check_entity_assets(c, rel, "/entity", parsed.value()["entity"], scripts);
        }
        assets_detail::check_sprite_textures(c.dir, c.spriteTextures, c.report.warnings);
        if (sceneFiles.empty())
            c.warn("scenes", "", "No scenes found (scenes/*.scene.json).", "Create scenes/main.scene.json.");
        else if (!mainScene.empty() && std::find(sceneFiles.begin(), sceneFiles.end(), mainScene) == sceneFiles.end() &&
                 stdfs::exists(stdfs::path(c.dir) / mainScene))
            c.warn(kProjectFileName, "/mainScene",
                   "mainScene '" + mainScene + "' is not named *.scene.json (or is in a hidden or build folder), so it is not validated.",
                   "Name it <something>.scene.json, e.g. scenes/main.scene.json.");
    }

    // Scripts: everything under scripts/ and tools/ plus referenced paths.
    for (const char* folder : {"scripts", "tools"}) {
        stdfs::path base = stdfs::path(c.dir) / folder;
        if (!stdfs::is_directory(base, ec)) continue;
        for (stdfs::recursive_directory_iterator it(base, ec), end; !ec && it != end; it.increment(ec))
            if (it->is_regular_file(ec) && it->path().extension() == ".js")
                scripts.insert(stdfs::relative(it->path(), c.dir, ec).generic_string());
    }
    std::set<std::string> failedScripts;  // scripts the check reported on: their Script.props are not checked on top
    for (const auto& s : scripts) {
        if (!stdfs::exists(stdfs::path(c.dir) / s)) continue;  // missing referenced scripts were reported as assets
        ++c.report.scriptsChecked;
        if (!options.scriptCheck) continue;
        for (auto& issue : options.scriptCheck(c.dir, s)) {
            failedScripts.insert(s);
            // A broken file that several scripts import (a .json) is the same problem each time: report it once.
            auto same = [&](const ValidationIssue& o) {
                return o.file == issue.file && o.pointer == issue.pointer && o.message == issue.message;
            };
            if (std::none_of(c.report.errors.begin(), c.report.errors.end(), same)) c.report.errors.push_back(std::move(issue));
        }
    }
    if (options.propsCheck) {
        for (const PropsCheck& pc : c.propChecks) {
            if (!stdfs::exists(stdfs::path(c.dir) / pc.module) || failedScripts.count(pc.module)) continue;
            for (const std::string& msg : options.propsCheck(pc.module, pc.props))
                c.warn(pc.file, pc.pointer, msg, "Fix the prop name, or declare the field in " + pc.module + " (props only set existing fields).");
        }
    }
    if (options.hooksCheck) {
        for (const auto& s : scripts) {
            // tools/*.js export command objects, not behaviours
            if (s.rfind("tools/", 0) == 0 || failedScripts.count(s)) continue;
            for (const std::string& msg : options.hooksCheck(s))
                c.warn(s, "", msg, "Rename the method to the suggested hook (all hooks: docs SCRIPTING.md, \"Lifecycle\").");
        }
    }
    if (auto dts = tooling_detail::read_file(stdfs::path(c.dir) / "types" / "factoria.d.ts");
        dts && dts->find("(placeholder)") != std::string::npos)
        c.warn("types/factoria.d.ts", "", "The script typings are a placeholder (everything is `any`).",
               "Run `factoria validate --fix-types` (or `factoria api --dts --project .`) to write the real typings.");
    if (!stdfs::exists(stdfs::path(c.dir) / "AGENTS.md"))
        c.warn("AGENTS.md", "", "AGENTS.md is missing.", "AI agents rely on it; create it with `factoria new` or copy from templates/common/AGENTS.md.");
    if (!stdfs::is_directory(stdfs::path(c.dir) / "tests", ec))
        c.warn("tests", "", "No tests/ folder.", "Add tests/*.test.js so `factoria test` can verify behaviour.");

    c.report.ok = c.report.errors.empty();
    return std::move(c.report);
}

void register_validate_commands(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = "project.validate";
    info.category = "project";
    info.readOnly = true;
    info.summary = "Check the whole project for errors: project file, scenes, assets, input bindings, scripts, feedback file.";
    info.description = "Run after every batch of edits. Returns {ok, errors[], warnings[]}; each issue has file, JSON pointer, "
                       "message and a fix hint. Checks every *.scene.json and *.prefab.json of the project, wherever it is kept "
                       "(scenes/, prefabs/, levels/...; folders starting with '.', node_modules and a top-level build/ are skipped, "
                       "like scene.format). Loads every scene, and every prefab on its own, into a temporary world, so it does not "
                       "disturb a running game; anything the loader refuses is an error with the JSON pointer, e.g. an unknown "
                       "field or a value outside a field's range (\"Field 'sides': value 200 is outside the allowed range 3..64\"; "
                       "the offending field keeps its default, nothing is clamped). "
                       "Warns once per scene or prefab file that is not in the canonical layout (fix: scene.format), and reports "
                       "a .json that a script imports and that is not valid JSON once, as that file with line and column. "
                       "Example: {}";
    registry.add(info, [projectDir](const Json&) { return validate_project(projectDir).to_json(); });
}

}  // namespace fa
