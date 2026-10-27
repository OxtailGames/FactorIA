// project.add_menu_kit: copies parts of the menu kit (templates/menus/, described by kit.json) into a game. Behaviour:
// fa/tooling/menu_kit.h and docs/MENUS.md. Scenes and prefabs are written with dump_scene_json, string tables with dump_json
// (the same writers as scene.format and i18n.import); scripts and tests are copied as they are.
#include "fa/tooling/menu_kit.h"

#include <algorithm>
#include <cctype>
#include <filesystem>
#include <map>
#include <set>

#include "fa/core/strings.h"
#include "fa/scene/serialize.h"
#include "fa/tooling/bundle.h"
#include "fa/tooling/json_patch.h"
#include "util.h"

namespace fa {

namespace {

namespace stdfs = std::filesystem;

constexpr const char* kKitRoot = "templates/menus/";

Error err(std::string message, std::string hint = {}) { return Error{std::move(message), std::move(hint)}; }

struct Part {
    std::string name, description;
    std::vector<std::string> requires_, files, localeKeys;
    // Optional part -> ids of the scene entities (and their children) that only make sense with it; left out of this part's
    // scenes and prefabs when that part is not added. Scripts do the same with trailing "// @kit:<part>" comment markers.
    std::map<std::string, std::vector<std::string>> prunes;
};

std::vector<std::string> strings_of(const Json& j, const char* key) {
    std::vector<std::string> out;
    if (auto it = j.find(key); it != j.end() && it->is_array())
        for (const Json& s : *it)
            if (s.is_string()) out.push_back(s.get<std::string>());
    return out;
}

Result<std::vector<Part>> load_parts() {
    auto text = bundled_read(std::string(kKitRoot) + "kit.json");
    if (!text) return err("The menu kit is missing from this build of factoria (templates/menus/kit.json).", "Reinstall FactorIA; this is a packaging bug.");
    auto doc = parse_json(*text, "templates/menus/kit.json");
    if (!doc.ok()) return err(doc.error().message, doc.error().hint);
    std::vector<Part> parts;
    if (auto it = doc->find("parts"); it != doc->end() && it->is_array()) {
        for (const Json& p : *it) {
            Part part;
            part.name = p.value("name", std::string());
            part.description = p.value("description", std::string());
            part.requires_ = strings_of(p, "requires");
            part.files = strings_of(p, "files");
            part.localeKeys = strings_of(p, "localeKeys");
            if (auto pr = p.find("prunes"); pr != p.end() && pr->is_object())
                for (auto it = pr->begin(); it != pr->end(); ++it) part.prunes[it.key()] = strings_of(*pr, it.key().c_str());
            parts.push_back(std::move(part));
        }
    }
    if (parts.empty()) return err("templates/menus/kit.json lists no parts.", "This is a packaging bug.");
    return parts;
}

std::string without_cr(std::string s) {
    s.erase(std::remove(s.begin(), s.end(), '\r'), s.end());
    return s;
}

// Every leaf below `node` as {"menu.play", value}; `prefix` is the dotted path of node.
void leaves(const Json& node, const std::string& prefix, std::vector<std::pair<std::string, Json>>& out) {
    for (auto it = node.begin(); it != node.end(); ++it) {
        const std::string key = prefix.empty() ? it.key() : prefix + "." + it.key();
        if (it->is_object() && !it->empty()) leaves(*it, key, out);
        else out.emplace_back(key, *it);
    }
}

// Adds `value` at the dotted path inside `doc` unless the game has it. Returns "" (added), "exists" or the reason it cannot go there.
std::string merge_leaf(Json& doc, const std::string& dotted, const Json& value) {
    if (doc.contains(dotted)) return "exists";  // a flat key such as "menu.play" written as it is
    const std::vector<std::string> path = split(dotted, '.');
    Json* node = &doc;
    for (std::size_t i = 0; i + 1 < path.size(); ++i) {
        auto it = node->find(path[i]);
        if (it == node->end()) {
            (*node)[path[i]] = Json::object();
            it = node->find(path[i]);
        } else if (!it->is_object()) {
            return "the game's \"" + join(std::vector<std::string>(path.begin(), path.begin() + long(i) + 1), ".") + "\" is not an object";
        }
        node = &*it;
    }
    if (node->contains(path.back())) return "exists";
    (*node)[path.back()] = value;
    return "";
}

// Removes every entity whose "id" is in `ids`, at any depth of "entities" / "children".
void prune_entities(Json& node, const std::set<std::string>& ids) {
    for (const char* key : {"entities", "children"}) {
        auto it = node.find(key);
        if (it == node.end() || !it->is_array()) continue;
        Json kept = Json::array();
        for (Json& e : *it) {
            if (e.is_object() && e.contains("id") && e["id"].is_string() && ids.count(e["id"].get<std::string>())) continue;
            prune_entities(e, ids);
            kept.push_back(std::move(e));
        }
        *it = std::move(kept);
    }
}

// A script line that ends with "// @kit:<part>" belongs to that part: dropped when the part is not added, the marker
// removed when it is (the game's copy reads as if written for it).
std::string apply_kit_markers(const std::string& text, const std::set<std::string>& wanted) {
    std::string out;
    std::size_t pos = 0;
    while (pos < text.size()) {
        std::size_t end = text.find('\n', pos);
        const bool hasNewline = end != std::string::npos;
        if (!hasNewline) end = text.size();
        std::string line = text.substr(pos, end - pos);
        pos = end + (hasNewline ? 1 : 0);
        const std::size_t m = line.rfind("// @kit:");
        if (m != std::string::npos) {
            std::string part = line.substr(m + 8);
            while (!part.empty() && std::isspace(static_cast<unsigned char>(part.back()))) part.pop_back();
            if (!wanted.count(part)) continue;
            line.erase(m);
            while (!line.empty() && std::isspace(static_cast<unsigned char>(line.back()))) line.pop_back();
        }
        out += line;
        if (hasNewline) out += '\n';
    }
    return out;
}

std::string base_language(const std::string& tag) { return tag.substr(0, tag.find('-')); }

}  // namespace

std::vector<std::string> menu_kit_parts() {
    std::vector<std::string> names;
    if (auto parts = load_parts(); parts.ok())
        for (const Part& p : *parts) names.push_back(p.name);
    return names;
}

Result<Json> add_menu_kit(const MenuKitOptions& o) {
    const std::string who = "project.add_menu_kit: ";
    if (o.projectDir.empty()) return err(who + "no project directory given", "pass the folder that contains factoria.json");
    const stdfs::path dir = stdfs::path(o.projectDir);
    std::error_code ec;
    if (!stdfs::exists(dir / "factoria.json", ec))
        return err(who + (dir / "factoria.json").generic_string() + " not found", "Run it on a game folder (the one with factoria.json); create a game with `factoria new <dir>`.");
    auto project = parse_json(tooling_detail::read_file(dir / "factoria.json").value_or(""), "factoria.json");
    if (!project.ok() || !project->is_object())
        return err(who + "factoria.json is not a JSON object: " + (project.ok() ? "" : project.error().message), "Fix factoria.json first (`factoria validate` shows where).");

    auto kit = load_parts();
    if (!kit.ok()) return err(who + kit.error().message, kit.error().hint);
    std::vector<std::string> names;
    for (const Part& p : *kit) names.push_back(p.name);
    const auto find_part = [&](const std::string& n) -> const Part* {
        for (const Part& p : *kit)
            if (p.name == n) return &p;
        return nullptr;
    };

    // ---- which parts: the ones asked for (default all) and the ones they need
    std::set<std::string> wanted;
    for (const std::string& n : o.parts) {
        if (!find_part(n))
            return err(who + "unknown part '" + n + "'. " + did_you_mean(n, names), "The parts are: " + join(names, ", ") + ". Leave `parts` out to add them all.");
        wanted.insert(n);
    }
    if (o.parts.empty()) wanted.insert(names.begin(), names.end());
    Json requiredBy = Json::object();
    for (bool grew = true; grew;) {
        grew = false;
        for (const Part& p : *kit) {
            if (!wanted.count(p.name)) continue;
            for (const std::string& need : p.requires_) {
                if (!wanted.count(need)) {
                    wanted.insert(need);
                    grew = true;
                }
                if (!requiredBy.contains(need)) requiredBy[need] = Json::array();
                if (std::find(requiredBy[need].begin(), requiredBy[need].end(), p.name) == requiredBy[need].end()) requiredBy[need].push_back(p.name);
            }
        }
    }
    std::vector<const Part*> selected;
    for (const Part& p : *kit)
        if (wanted.count(p.name)) selected.push_back(&p);
    Json requiredOut = Json::object();  // only the parts the caller did not name
    for (auto it = requiredBy.begin(); it != requiredBy.end(); ++it)
        if (std::find(o.parts.begin(), o.parts.end(), it.key()) == o.parts.end() && !o.parts.empty()) requiredOut[it.key()] = *it;

    Json result = Json::object();
    Json partNames = Json::array(), added = Json::array(), unchanged = Json::array(), overwritten = Json::array(), skipped = Json::array();
    for (const Part* p : selected) partNames.push_back(p->name);

    // ---- files
    for (const Part* p : selected) {
        for (const std::string& rel : p->files) {
            auto source = bundled_read(std::string(kKitRoot) + rel);
            if (!source) return err(who + "the kit file " + rel + " is missing from this build of factoria", "This is a packaging bug.");
            std::string text = *source;
            const bool scene = is_scene_or_prefab_file(rel);
            if (!scene && rel.size() > 3 && rel.compare(rel.size() - 3, 3, ".js") == 0) text = apply_kit_markers(text, wanted);
            Json sourceDoc;
            if (scene) {
                auto doc = parse_json(*source, rel);
                if (!doc.ok()) return err(who + doc.error().message, "This is a bug in the kit.");
                sourceDoc = *doc;
                std::set<std::string> drop;
                for (const auto& [optional, ids] : p->prunes)
                    if (!wanted.count(optional)) drop.insert(ids.begin(), ids.end());
                if (!drop.empty()) prune_entities(sourceDoc, drop);
                text = dump_scene_json(sourceDoc);
            }
            const stdfs::path target = dir / rel;
            const bool exists = stdfs::exists(target, ec);
            if (exists) {
                const std::string current = tooling_detail::read_file(target).value_or("");
                bool same = without_cr(current) == without_cr(text);
                if (!same && scene) {
                    auto doc = parse_json(current, rel);
                    same = doc.ok() && *doc == sourceDoc;  // same data, another layout: the game's file is left alone
                }
                if (same) {
                    unchanged.push_back(rel);
                    continue;
                }
                if (!o.overwrite) {
                    skipped.push_back(Json::object({{"file", rel}, {"reason", "the game's file differs from the kit's; it was not touched (pass overwrite: true to replace it)"}}));
                    continue;
                }
            }
            std::string e;
            if (!tooling_detail::write_file(target, text, &e)) return err(who + e);
            (exists ? overwritten : added).push_back(rel);
        }
    }

    // ---- string tables
    std::set<std::string> keyRoots;
    for (const Part* p : selected) keyRoots.insert(p->localeKeys.begin(), p->localeKeys.end());
    Json locales = Json::array();
    Json settings = Json::array();
    if (!keyRoots.empty()) {
        std::vector<std::string> languages;
        std::string defaultLanguage = "en";
        const Json* loc = project->contains("localization") ? &(*project)["localization"] : nullptr;
        if (loc && loc->is_object()) {
            languages = strings_of(*loc, "languages");
            if (loc->contains("defaultLanguage") && (*loc)["defaultLanguage"].is_string()) defaultLanguage = (*loc)["defaultLanguage"].get<std::string>();
        }
        if (languages.empty()) {
            if (loc && loc->is_object() && loc->contains("defaultLanguage")) languages = {defaultLanguage};
            else languages = {"en"};
        }
        if (!loc || !loc->is_object() || strings_of(*loc, "languages").empty()) {
            Json section = loc && loc->is_object() ? *loc : Json::object();
            if (!section.contains("defaultLanguage")) section["defaultLanguage"] = defaultLanguage;
            section["languages"] = languages;
            auto patched = patch_json_file((dir / "factoria.json").string(), {{{"localization"}, section}});
            if (!patched.ok()) return err(who + patched.error().message, patched.error().hint);
            settings.push_back("factoria.json: \"localization\" added with the languages " + join(languages, ", ") + " (the kit's texts need a string table).");
        }
        std::map<std::string, Json> kitTables;
        for (const std::string& tag : {"en", "es", "ar"}) {
            auto text = bundled_read(std::string(kKitRoot) + "locales/" + tag + ".json");
            if (!text) continue;
            auto doc = parse_json(*text, "templates/menus/locales/" + tag + ".json");
            if (doc.ok() && doc->is_object()) kitTables[tag] = *doc;
        }
        for (const std::string& language : languages) {
            const std::string rel = "locales/" + language + ".json";
            // The kit's own translation when it has one (exact tag, then the language without region); else the English text, which
            // reads better than a key name until a translator replaces it (docs/LOCALIZATION.md).
            const Json* table = nullptr;
            bool translated = true;
            if (kitTables.count(language)) table = &kitTables[language];
            else if (kitTables.count(base_language(language))) table = &kitTables[base_language(language)];
            else {
                table = &kitTables["en"];
                translated = language == "en" || base_language(language) == "en";
            }
            const stdfs::path target = dir / rel;
            Json entry = Json::object({{"file", rel}, {"created", false}, {"merged", Json::array()}, {"skipped", Json::array()}});
            Json doc = Json::object();
            const bool existed = stdfs::exists(target, ec);
            if (existed) {
                auto parsed = parse_json(tooling_detail::read_file(target).value_or(""), rel);
                if (!parsed.ok() || !parsed->is_object()) {
                    entry["skipped"].push_back(Json::object({{"key", "*"}, {"reason", "the file is not a JSON object (" + (parsed.ok() ? std::string("it is not an object") : parsed.error().message) + "); fix it, then run the command again"}}));
                    locales.push_back(entry);
                    continue;
                }
                doc = *parsed;
            }
            if (!translated) entry["note"] = "the kit has no " + language + " texts yet: the English ones were added, ready to translate";
            bool changed = !existed;
            entry["created"] = !existed;
            if (translated && table->contains("$name") && !doc.contains("$name")) {
                doc["$name"] = (*table)["$name"];
                changed = true;
            }
            std::vector<std::pair<std::string, Json>> all;
            for (const std::string& root : keyRoots)
                if (table && table->contains(root)) {
                    if ((*table)[root].is_object()) leaves((*table)[root], root, all);
                    else all.emplace_back(root, (*table)[root]);
                }
            for (const auto& [key, value] : all) {
                const std::string why = merge_leaf(doc, key, value);
                if (why.empty()) {
                    entry["merged"].push_back(key);
                    changed = true;
                } else if (why != "exists") {
                    entry["skipped"].push_back(Json::object({{"key", key}, {"reason", why}}));
                }
            }
            if (changed) {
                const std::string text = dump_json(doc);
                std::string e;
                if (!tooling_detail::write_file(target, text, &e)) return err(who + e);
            }
            locales.push_back(entry);
        }
    }

    // ---- the input actions a part reads (only the ones the game does not have; a game's own binding is never replaced)
    struct KitAction { const char* part; const char* name; const char* bindings; const char* who; };
    static const KitAction kitActions[] = {
        {"pause", "pause", R"(["Escape", "P", "GamepadStart"])", "scripts/pause_menu.js"},
        {"cameraRig", "camera_drag", R"(["MouseMiddle"])", "scripts/camera_rig.js"},
        {"cameraRig", "camera_left", R"(["A", "Left"])", "scripts/camera_rig.js"},
        {"cameraRig", "camera_right", R"(["D", "Right"])", "scripts/camera_rig.js"},
        {"cameraRig", "camera_up", R"(["W", "Up"])", "scripts/camera_rig.js"},
        {"cameraRig", "camera_down", R"(["S", "Down"])", "scripts/camera_rig.js"},
        {"cameraRig", "camera_zoom_in", R"(["PageUp", "Equal"])", "scripts/camera_rig.js"},
        {"cameraRig", "camera_zoom_out", R"(["PageDown", "Minus"])", "scripts/camera_rig.js"},
    };
    for (const KitAction& a : kitActions) {
        if (!wanted.count(a.part)) continue;
        const Json* actions = project->contains("input") && (*project)["input"].is_object() && (*project)["input"].contains("actions")
                                  ? &(*project)["input"]["actions"] : nullptr;
        if (actions && actions->is_object() && actions->contains(a.name)) continue;
        auto patched = patch_json_file((dir / "factoria.json").string(), {{{"input", "actions", a.name}, Json::parse(a.bindings)}});
        if (!patched.ok()) return err(who + patched.error().message, patched.error().hint);
        settings.push_back(std::string("factoria.json: input action \"") + a.name + "\" added (" + Json::parse(a.bindings).dump() + "); " + a.who + " reads it.");
    }

    Json next = Json::array();
    if (wanted.count("main-menu"))
        next.push_back("Set \"mainScene\" in factoria.json to \"scenes/menu.scene.json\" and put the game's first level in MainMenu.firstScene (scripts/main_menu.js); put the game's name in the menu.title string.");
    if (wanted.count("pause"))
        next.push_back("Add one entity with the script scripts/pause_menu.js to every level scene: { \"id\": \"pause_menu\", \"components\": { \"Script\": { \"path\": \"scripts/pause_menu.js\" } } }.");
    if (wanted.count("options"))
        next.push_back("The Controls tab of the options lists every input action of the game except the ui_* ones, labelled with the action's name. Add a string options.action.<action> to every locales/<language>.json for a readable label, and to choose and order the actions set the \"actions\" property of the Script in prefabs/ui/options.prefab.json: \"props\": { \"actions\": [\"move\", \"jump\"] }.");
    if (wanted.count("ageGate"))
        next.push_back("Set platform.ads.audience to \"mixed\" in factoria.json when children and adults play: the main menu (when it is added too) then opens the age gate once, before any ad, and gives the answer to platform.ads.setUnderAge() (a game with another audience never shows it). A game without the main-menu part calls openAgeGate() of scripts/ui/age_gate.js from its first scene.");
    if (wanted.count("analyticsConsent"))
        next.push_back("Add an \"analytics\" section with the endpoint (and its host in \"network\".hosts) to factoria.json (docs/ANALYTICS.md): the main menu (when it is added too) then asks once whether the game may count usage, and the Options tab gets a switch. Edit analyticsConsent.what in locales/*.json to say what your game really sends, and list it in your privacy policy (docs/LEGAL.md). A game without the main-menu part calls openAnalyticsConsent() of scripts/ui/analytics_consent.js from its first scene.");
    if (wanted.count("keyboard"))
        next.push_back("Add one entity with scripts/ui/keyboard.js to every scene that has a TextField.");
    next.push_back("Run `factoria validate`, then `factoria test`" + std::string(wanted.count("main-menu") ? " (tests/recipe.test.js drives the main menu with a gamepad)." : "."));

    result["parts"] = partNames;
    result["requiredBy"] = requiredOut;
    result["added"] = added;
    result["unchanged"] = unchanged;
    result["overwritten"] = overwritten;
    result["skipped"] = skipped;
    result["locales"] = locales;
    result["settings"] = settings;
    result["nextSteps"] = next;
    return result;
}

void register_menu_kit_commands(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = "project.add_menu_kit";
    info.category = "project";
    info.readOnly = false;
    info.summary = "Copy the menu kit (main menu, options, pause, loading screen, ...) into the game and merge its strings into the locales.";
    info.description =
        "The menu kit of docs/MENUS.md (templates/menus/ in the FactorIA install): `parts` picks what to copy, the files go to the same paths in the game "
        "(scripts/, scenes/, prefabs/ui/, tests/recipe.test.js) and the kit's strings are merged into locales/<language>.json for every language of "
        "factoria.json \"localization\" (added when the game has none). Scenes and prefabs are written in the canonical layout of scene.format. Parts "
        "that others need come along (the main menu needs core, options and credits) and are listed in `requiredBy`. The shop, ageGate and analyticsConsent parts are optional for the main menu: its Shop button, shop panel, age gate call and analytics question call are written only when those parts are added (all parts by default). A kit file the game already "
        "has and has changed is NOT touched unless `overwrite` is true: it is listed in `skipped`; a file that is the same is listed in `unchanged`, so "
        "running the command twice changes nothing. String keys the game already has are never replaced, with or without `overwrite`; only missing "
        "ones are added. A language the kit has no texts for gets the English ones. The \"pause\" part also adds the input action \"pause\" to "
        "factoria.json when it is missing. Returns {parts[], requiredBy{}, added[], unchanged[], overwritten[], skipped[{file,reason}], "
        "locales[{file,created,merged[],skipped[]}], settings[], nextSteps[]}. Examples: {} (all parts), {\"parts\":[\"pause\"]}, {\"parts\":[\"main-menu\",\"loading\"],\"overwrite\":true}.";
    std::string partList;
    if (auto parts = load_parts(); parts.ok())
        for (const Part& p : *parts) partList += (partList.empty() ? "" : "; ") + p.name + ": " + p.description;
    Json parts = Json::object({{"type", "array"}, {"items", Json::object({{"type", "string"}})},
                               {"description", "Which parts to add; default all. Parts and what they copy: " + partList}});
    info.inputSchema = Json::object({{"type", "object"},
        {"properties", Json::object({
            {"parts", parts},
            {"overwrite", Json::object({{"type", "boolean"}, {"default", false},
                {"description", "Replace a kit file the game has changed (a file that is the same is left alone). Without it that file is left as it is and listed in `skipped`. String keys the game has are never replaced."}})}})}});
    registry.add(info, [projectDir](const Json& args) {
        MenuKitOptions o;
        o.projectDir = projectDir;
        for (auto it = args.begin(); it != args.end(); ++it)
            if (it.key() != "parts" && it.key() != "overwrite")
                throw CommandError("invalid_argument", "Unknown argument '" + it.key() + "'. " + did_you_mean(it.key(), std::vector<std::string>{"parts", "overwrite"}),
                                   "project.add_menu_kit takes `parts` (array of part names) and `overwrite` (boolean).");
        if (auto it = args.find("parts"); it != args.end()) {
            if (!it->is_array()) throw CommandError("invalid_argument", "`parts` must be an array of part names.", "Example: {\"parts\":[\"pause\",\"loading\"]}");
            for (const Json& p : *it) {
                if (!p.is_string()) throw CommandError("invalid_argument", "`parts` must hold strings.", "Example: {\"parts\":[\"pause\"]}");
                o.parts.push_back(p.get<std::string>());
            }
        }
        o.overwrite = tooling_detail::arg_bool(args, "overwrite", false);
        auto r = add_menu_kit(o);
        if (!r.ok()) throw CommandError("failed", r.error().message, r.error().hint);
        return *r;
    });
}

}  // namespace fa
