// style.ignore and style.set_role: scope the style rules of assets.json to the assets they are meant for (docs/ASSETS.md,
// "Scoping the style rules"). They edit the `style.ignore` list and the `style.roles` object; the style checks
// (assets.check_art, project.validate) read them through fa/tooling/style_guide.h and report what they skipped.
#include <algorithm>
#include <format>

#include "assets_internal.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/tooling/style_guide.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

using tooling_detail::arg_bool;
using tooling_detail::arg_string;

// A project-relative file, folder ending in "/" or glob, normalized like the style parser does.
std::string pattern_arg(const char* command, const Json& a, const char* key) {
    const std::string raw = arg_string(a, key, true);
    const std::string norm = fs::normalize(raw);
    // Only a `..` path segment climbs out (a name such as "a..b.png" is fine).
    bool climbs = false;
    for (const std::string& seg : split(replace_all(raw, "\\", "/"), '/')) climbs = climbs || seg == "..";
    if (norm.empty() || climbs || norm.front() == '/' || (norm.size() > 1 && norm[1] == ':'))
        arg_error(command, std::string("/") + key, "'" + raw + "' is not a path inside the project.",
                  "Use a project-relative file (\"assets/art/flame.png\"), a folder ending in a slash (\"assets/ui/\") or a glob (\"assets/ui/**\").");
    return norm + (raw.back() == '/' && norm.back() != '/' ? "/" : "");
}

std::vector<std::string> rule_list(const char* command, const Json& a) {
    std::vector<std::string> out;
    if (!a.contains("rules") || a["rules"].is_null()) return out;
    if (!a["rules"].is_array()) arg_error(command, "/rules", "expected a list of rule names, got " + describe_json_value(a["rules"]) + ".", "Example: [\"texelsPerUnit\", \"lightDirection\"]; leave it out for every rule.");
    for (std::size_t i = 0; i < a["rules"].size(); ++i) {
        const Json& r = a["rules"][i];
        const std::string at = "/rules/" + std::to_string(i);
        if (!r.is_string()) arg_error(command, at, "a rule name must be a string, got " + describe_json_value(r) + ".", "Example: \"texelsPerUnit\".");
        const std::string name = r.get<std::string>();
        const auto& known = style_rule_names();
        if (std::find(known.begin(), known.end(), name) == known.end()) arg_error(command, at, "unknown style rule '" + name + "'. " + did_you_mean(name, known, 16), "A name also covers the rules under it: \"outline\" is outline.color and outline.width.");
        if (std::find(out.begin(), out.end(), name) == out.end()) out.push_back(name);
    }
    return out;
}

std::string entry_path(const Json& e) {
    const std::string text = e.is_string() ? e.get<std::string>() : e.is_object() && e.contains("path") && e["path"].is_string() ? e["path"].get<std::string>() : std::string();
    return text.empty() ? text : fs::normalize(text) + (text.back() == '/' && fs::normalize(text).back() != '/' ? "/" : "");
}

Json style_ignore(const std::string& projectDir, const Json& a) {
    const char* cmd = "style.ignore";
    check_arg_keys(cmd, a, "", {"path", "rules", "remove"});
    const std::string path = pattern_arg(cmd, a, "path");
    const std::vector<std::string> rules = rule_list(cmd, a);
    const bool remove = arg_bool(a, "remove", false);
    ProjectRootGuard root(projectDir);
    require_usable_manifest(projectDir);
    std::vector<std::string> notes;
    if (path.find_first_of("*?") == std::string::npos && path.back() != '/' && !fs::exists(path))
        notes.push_back("'" + path + "' does not exist yet; the entry applies when the file does.");
    Json result;
    bool changed = false;
    std::string failure;
    auto r = assets::update_manifest([&](Json& doc) {
        if (!doc.contains("style") || !doc["style"].is_object()) doc["style"] = Json::object();
        Json& style = doc["style"];
        if (!style.contains("ignore") || !style["ignore"].is_array()) style["ignore"] = Json::array();
        Json& list = style["ignore"];
        std::size_t at = list.size();
        for (std::size_t i = 0; i < list.size(); ++i)
            if (entry_path(list[i]) == path) at = i;
        // "whole": every rule is skipped (a plain string, or an object with no `rules`, which the style parser reads the same way)
        const bool whole = at < list.size() && (list[at].is_string() || !list[at].contains("rules") || !list[at]["rules"].is_array() || list[at]["rules"].empty());
        const Json before = at < list.size() ? list[at] : Json();
        if (remove) {
            if (at == list.size()) {
                notes.push_back("Nothing to remove: no style.ignore entry names '" + path + "'.");
            } else if (rules.empty()) {
                list.erase(list.begin() + at);
                changed = true;
            } else if (whole) {
                failure = "'" + path + "' is ignored for every rule, so single rules cannot be taken back. Remove the entry (no `rules`), then ignore the rules you want.";
            } else {
                Json left = Json::array();
                for (const Json& n : list[at]["rules"]) {
                    const bool drop = std::find(rules.begin(), rules.end(), n.get<std::string>()) != rules.end();
                    if (!drop) left.push_back(n);
                    changed = changed || drop;
                }
                if (left.empty()) list.erase(list.begin() + at);
                else list[at]["rules"] = left;
            }
        } else if (rules.empty()) {
            if (whole) {
                notes.push_back("'" + path + "' was already ignored for every rule.");
            } else {
                if (at < list.size()) {
                    notes.push_back("'" + path + "' was ignored only for " + before["rules"].dump() + "; it is now ignored for every rule.");
                    list[at] = path;
                }
                else list.push_back(path);
                changed = true;
            }
        } else if (whole) {
            notes.push_back("'" + path + "' is already ignored for every rule, which includes " + join(rules, ", ") + ".");
        } else if (at == list.size()) {
            list.push_back(Json::object({{"path", path}, {"rules", rules}}));
            changed = true;
        } else {
            Json merged = list[at]["rules"].is_array() ? list[at]["rules"] : Json::array();
            for (const std::string& n : rules)
                if (std::find(merged.begin(), merged.end(), Json(n)) == merged.end()) {
                    merged.push_back(n);
                    changed = true;
                }
            list[at]["rules"] = merged;
        }
        result = Json::object({{"ignore", list}});
        if (list.empty()) style.erase("ignore");
        if (style.empty()) doc.erase("style");
    });
    if (!failure.empty()) arg_error(cmd, "/rules", failure, "Nothing was changed.");
    if (!r) fail("manifest_failed", r.error().message, r.error().hint);
    if (!result.contains("ignore")) result["ignore"] = Json::array();
    result["path"] = path;
    result["changed"] = changed;
    if (!notes.empty()) result["notes"] = notes;
    result["next"] = remove ? "assets.check_art lists the rules again for this file." : "assets.check_art and project.validate skip these rules for the file; assets.check_art lists them under `styleSkipped` with the reason.";
    return result;
}

Json style_set_role(const std::string& projectDir, const Json& a) {
    const char* cmd = "style.set_role";
    check_arg_keys(cmd, a, "", {"path", "role", "remove"});
    const std::string path = pattern_arg(cmd, a, "path");
    const bool remove = arg_bool(a, "remove", false);
    std::string role;
    if (!remove) {
        role = arg_string(a, "role", true);
        const auto& known = style_roles();
        if (std::find(known.begin(), known.end(), role) == known.end()) arg_error(cmd, "/role", "unknown role '" + role + "'. " + did_you_mean(role, known) + " Valid: ui, icon, effect.", "A role is ui, icon or effect.");
    }
    ProjectRootGuard root(projectDir);
    require_usable_manifest(projectDir);
    bool changed = false;
    Json roles;
    auto r = assets::update_manifest([&](Json& doc) {
        if (!doc.contains("style") || !doc["style"].is_object()) doc["style"] = Json::object();
        Json& style = doc["style"];
        if (!style.contains("roles") || !style["roles"].is_object()) style["roles"] = Json::object();
        Json& map = style["roles"];
        // the key as written may differ from the normalized one: find it by its normalized form
        std::string key;
        for (auto it = map.begin(); it != map.end(); ++it)
            if (entry_path(Json(it.key())) == path) key = it.key();
        if (remove) {
            if (!key.empty()) {
                map.erase(key);
                changed = true;
            }
        } else if (key.empty() || map[key] != role) {
            if (!key.empty()) map.erase(key);
            map[path] = role;
            changed = true;
        }
        roles = map;
        if (map.empty()) style.erase("roles");
        if (style.empty()) doc.erase("style");
    });
    if (!r) fail("manifest_failed", r.error().message, r.error().hint);
    Json out = Json::object({{"path", path}, {"changed", changed}, {"roles", roles}});
    out["next"] = "The rules this role turns off are listed in docs.read ASSETS (\"Scoping the style rules\"); assets.check_art reports each skipped rule with its reason.";
    return out;
}

}  // namespace

void register_style_commands(CommandRegistry& registry, const std::string& projectDir) {
    {
        CommandInfo info;
        info.name = "style.ignore";
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Skip style rules for a file, folder or glob (all rules, or only the rules you name); recorded in assets.json style.ignore.";
        info.description =
            "Adds {path, rules} to `style.ignore` of assets.json, so the style checks (assets.check_art, project.validate) do not judge those rules for the asset. `path` is a "
            "project-relative file, a folder ending in a slash (\"assets/ui/\") or a glob (\"assets/fx/**\"). `rules` names the rules to skip: outline (outline.color, outline.width), value "
            "(value.min, value.max), saturation, lightDirection, texelsPerUnit, pixelArt (pixelArt.edges, pixelArt.colours), palette (palette.offShare); without `rules` every rule is skipped "
            "for the path (the old plain-path entry). Naming only the rules that do not fit keeps the others checking, so a real problem is not hidden. assets.check_art still checks a file "
            "you name, and lists what it left out under `styleSkipped` with the reason. To skip by kind of asset instead, give it a role: style.set_role or assets.set_provenance `role`. "
            "`remove: true` takes an entry (or, with `rules`, those rules of it) back. Example: {\"path\":\"assets/art/flame.png\",\"rules\":[\"texelsPerUnit\",\"lightDirection\"]}";
        info.inputSchema = Json::parse(R"({"type":"object","required":["path"],"additionalProperties":false,"properties":{
          "path":{"type":"string","description":"Project-relative file, folder ending in a slash, or glob (* and ? stay inside a folder, ** crosses folders)."},
          "rules":{"type":"array","items":{"type":"string"},"description":"Rules to skip: outline, outline.color, outline.width, value, value.min, value.max, saturation, saturation.min, saturation.max, lightDirection, texelsPerUnit, pixelArt, pixelArt.edges, pixelArt.colours, palette, palette.offShare. Omit for every rule."},
          "remove":{"type":"boolean","default":false,"description":"Take the entry back (with `rules`: only those rules)."}}})");
        registry.add(info, [projectDir](const Json& args) { return style_ignore(projectDir, args); });
    }
    {
        CommandInfo info;
        info.name = "style.set_role";
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Give every asset that matches a path or glob a role (ui, icon, effect); the style rules that do not apply to the role are turned off for them.";
        info.description =
            "Writes `style.roles[path] = role` in assets.json. A role names what the picture is for, so the style checks leave out the rules that do not apply to it: ui and icon turn "
            "off texelsPerUnit and lightDirection (an interface picture is not on a mesh and is shaded as drawn); effect (a flame, a spark: lit by itself) also turns off outline, value "
            "and saturation. The rules that are not turned off keep checking. A role set in an asset's provenance (assets.set_provenance `role`) wins over a glob. assets.check_art "
            "lists every skipped rule under `styleSkipped` with the role and where it came from. `remove: true` deletes the glob; a role in an asset's provenance is taken back "
            "with assets.set_provenance `role` \"\". "
            "Example: {\"path\":\"assets/ui/**\",\"role\":\"ui\"}";
        info.inputSchema = Json::parse(R"({"type":"object","required":["path"],"additionalProperties":false,"properties":{
          "path":{"type":"string","description":"Project-relative file, folder ending in a slash, or glob (\"assets/ui/**\")."},
          "role":{"type":"string","enum":["ui","icon","effect"],"description":"What the pictures are for. Required unless `remove`."},
          "remove":{"type":"boolean","default":false,"description":"Delete the role of this path."}}})");
        registry.add(info, [projectDir](const Json& args) { return style_set_role(projectDir, args); });
    }
    declare_command_capabilities(registry, {
        {"style.ignore", capability_sets::writes_project()},
        {"style.set_role", capability_sets::writes_project()}});
}

}  // namespace fa::assets_detail
