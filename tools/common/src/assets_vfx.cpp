// vfx.create and vfx.edit: effect documents (`*.vfx.json`, docs/PARTICLES.md "Effect documents") as project files. The format and its checks are
// fa_scene's (fa/scene/vfx.h, parse_vfx); the commands read and write the file in the project and write nothing that would not load. The editor's
// Particle panel makes every kept change through vfx.edit, so the file is what a hand edit or an AI would have written.
#include <algorithm>

#include "assets_internal.h"
#include "fa/core/strings.h"
#include "fa/scene/vfx.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

constexpr const char* kSuffix = ".vfx.json";

Json obj(std::initializer_list<std::pair<const char*, Json>> props) {
    Json p = Json::object();
    for (const auto& [k, v] : props) p[k] = v;
    return p;
}

std::string effect_path(const std::string& arg, const char* what = "path") {
    auto norm = fs::normalize_checked(arg);
    if (!norm.ok() || norm->empty() || !starts_with(*norm, "assets/"))
        fail("invalid_argument", std::string("`") + what + "` '" + arg + "' is not an effect document under assets/.",
             "Effect documents live in assets/, e.g. \"assets/vfx/hit.vfx.json\" (vfx.create writes a starting point).");
    if (!ends_with(to_lower(*norm), kSuffix))
        fail("invalid_argument", "'" + *norm + "' does not end in .vfx.json.", "Name effect documents <name>.vfx.json, e.g. \"assets/vfx/hit.vfx.json\".");
    return *norm;
}

Json issues_json(const std::vector<VfxIssue>& issues, bool errors) {
    Json list = Json::array();
    for (const VfxIssue& i : issues)
        if (i.error == errors) list.push_back(obj({{"pointer", i.pointer}, {"message", i.message}, {"hint", i.hint}}));
    return list;
}

// The document every new effect starts as: one burst of soft dots that fall a little. Enough to see something play and to edit from.
Json starter_document(const std::string& description) {
    Json emitter = obj({{"burst", 16}, {"lifetime", 0.6}, {"speed", 120}, {"spread", 180}, {"startSize", 8}, {"endSize", 2},
                        {"colorGradient", Json::array({Json::array({0, "#ffe9a0"}), Json::array({1, "#ff5a1f00"})})}});
    Json part = obj({{"type", "emitter"}, {"name", "burst"}, {"emitter", emitter}});
    Json doc = Json::object();
    doc["format"] = "factoria.vfx/1";
    doc["doc"] = description;
    doc["parts"] = Json::array({part});
    return doc;
}

Json vfx_create_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("vfx.create", a, "", {"path", "doc", "overwrite"});
    const std::string rel = effect_path(tooling_detail::arg_string(a, "path", true));
    const stdfs::path file = project_write_file(projectDir, rel);
    std::error_code ec;
    if (stdfs::exists(file, ec) && !tooling_detail::arg_bool(a, "overwrite", false))
        fail("exists", "vfx.create: '" + rel + "' exists already.", "Pass \"overwrite\": true to replace it, or edit it with vfx.edit.");
    const std::string description = a.contains("doc") && a["doc"].is_string() ? a["doc"].get<std::string>() : std::string("A new effect.");
    const Json json = starter_document(description);
    std::vector<VfxIssue> issues;
    auto parsed = parse_vfx(json, rel, &issues);
    if (!parsed.ok()) fail("failed", "vfx.create: the starting document does not parse: " + parsed.error().message);
    std::string err;
    if (!tooling_detail::write_file(file, json.dump(2) + "\n", &err)) fail("failed", err);
    return obj({{"effect", rel},
                {"nextSteps", Json::array({"vfx.edit {\"path\":\"" + rel + "\",\"op\":\"set\",\"pointer\":\"/parts/0/emitter/burst\",\"value\":24} changes it; vfx.play plays it in the running game; vfx.check lists every problem."})}});
}

// Changes one field of an effect by its JSON pointer and writes it back when the result still parses (the Particle panel's inspector).
Json vfx_edit_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("vfx.edit", a, "", {"path", "op", "pointer", "value", "index", "to"});
    const std::string rel = effect_path(tooling_detail::arg_string(a, "path", true));
    const std::string op = tooling_detail::arg_string(a, "op", true);
    if (op != "set" && op != "remove" && op != "add" && op != "move")
        fail("invalid_argument", "vfx.edit: unknown op '" + op + "'.", "op is set, remove, add (insert into an array) or move (reorder an array).");
    const std::string pointer = tooling_detail::arg_string(a, "pointer", true);
    if (!pointer.empty() && pointer[0] != '/')
        fail("invalid_argument", "vfx.edit: `pointer` must be a JSON pointer such as /parts/0/emitter/burst.", "It starts with a slash; /parts is the list of parts.");
    const stdfs::path file = project_write_file(projectDir, rel);
    auto text = tooling_detail::read_file(file);
    if (!text) fail("not_found", "vfx.edit: '" + rel + "' does not exist.", "Make one with vfx.create {\"path\":\"" + rel + "\"} and edit it.");
    auto loaded = parse_json(*text, rel);
    if (!loaded.ok()) fail("invalid_effect", loaded.error().message, loaded.error().hint.empty() ? "Fix the JSON syntax; schemas/vfx.schema.json describes the format." : loaded.error().hint);
    Json json = std::move(*loaded);
    Json::json_pointer ptr;
    try {
        ptr = Json::json_pointer(pointer);
    } catch (const std::exception& e) {
        fail("invalid_argument", std::string("vfx.edit: bad pointer: ") + e.what(), "Use a JSON pointer such as /parts/0/emitter/burst.");
    }
    auto need_array = [&]() -> Json& {
        if (!json.contains(ptr) || !json.at(ptr).is_array())
            fail("invalid_argument", "vfx.edit: " + pointer + " is not an array in " + rel + ".", "Point at the array itself, e.g. /parts or /parts/0/emitter/colorGradient.");
        return json.at(ptr);
    };
    try {
        if (op == "set") {
            if (!a.contains("value")) fail("invalid_argument", "vfx.edit: `set` needs a `value`.", "Use op remove to delete a field.");
            if (pointer.empty()) fail("invalid_argument", "vfx.edit: set needs a pointer to a field.", "Example: /parts/0/at.");
            const Json::json_pointer parent = ptr.parent_pointer();
            if (!json.contains(parent)) fail("invalid_argument", "vfx.edit: " + parent.to_string() + " does not exist in " + rel + ".", "Set the parent first, or point at an existing object.");
            json[ptr] = a["value"];
        } else if (op == "remove") {
            if (pointer.empty() || !json.contains(ptr)) fail("not_found", "vfx.edit: " + pointer + " is not in " + rel + ".", "Nothing to remove there.");
            Json& holder = json.at(ptr.parent_pointer());
            if (holder.is_array()) holder.erase(holder.begin() + static_cast<std::ptrdiff_t>(std::stoul(ptr.back())));
            else holder.erase(ptr.back());
        } else if (op == "add") {
            Json& arr = need_array();
            if (!a.contains("value")) fail("invalid_argument", "vfx.edit: `add` needs a `value` to insert.", "Example: a part {\"type\":\"light\",\"duration\":0.1} into /parts.");
            const long long wanted = a.contains("index") && a["index"].is_number_integer() ? a["index"].get<long long>() : static_cast<long long>(arr.size());
            const std::size_t at = static_cast<std::size_t>(std::clamp<long long>(wanted, 0, static_cast<long long>(arr.size())));
            arr.insert(arr.begin() + static_cast<std::ptrdiff_t>(at), a["value"]);
        } else {
            Json& arr = need_array();
            if (!a.contains("index") || !a.contains("to") || !a["index"].is_number_integer() || !a["to"].is_number_integer())
                fail("invalid_argument", "vfx.edit: `move` needs integer `index` and `to`.", "index is the element to move, to its new place.");
            const long long from = a["index"].get<long long>(), to = a["to"].get<long long>(), n = static_cast<long long>(arr.size());
            if (from < 0 || from >= n || to < 0 || to >= n)
                fail("invalid_argument", "vfx.edit: index/to must be 0.." + std::to_string(n - 1) + ".", "The array has " + std::to_string(n) + " elements.");
            Json item = arr[static_cast<std::size_t>(from)];
            arr.erase(arr.begin() + from);
            arr.insert(arr.begin() + to, item);
        }
    } catch (const CommandError&) {
        throw;
    } catch (const std::exception& e) {
        fail("invalid_argument", std::string("vfx.edit: ") + e.what(), "Check the pointer and the value against schemas/vfx.schema.json.");
    }
    std::vector<VfxIssue> issues;
    auto doc = parse_vfx(json, rel, &issues);
    if (!doc.ok())
        throw CommandError("invalid_effect", "vfx.edit: the effect would no longer be valid, so nothing was written. " + doc.error().message, doc.error().hint,
                           obj({{"errors", issues_json(issues, true)}, {"warnings", issues_json(issues, false)}}));
    std::string err;
    if (!tooling_detail::write_file(file, json.dump(2) + "\n", &err)) fail("failed", err);
    return obj({{"effect", rel}, {"duration", (*doc)->duration}, {"parts", (*doc)->parts.size()}, {"warnings", issues_json(issues, false)},
                {"nextSteps", Json::array({"vfx.check {\"path\":\"" + rel + "\"} lists every problem, including a sound clip that is not in the project; vfx.play plays it."})}});
}

}  // namespace

void register_vfx_commands(CommandRegistry& registry, const std::string& projectDir) {
    {
        CommandInfo info;
        info.name = "vfx.create";
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Write a new effect document (*.vfx.json) with one burst emitter, as a starting point to edit.";
        info.description =
            "Writes `path` (under assets/, ending in .vfx.json; format factoria.vfx/1, docs/PARTICLES.md \"Effect documents\") with one emitter part that bursts 16 soft dots, so there is something to see and edit. "
            "An existing file is an error unless `overwrite` is true. Change it with vfx.edit, play it with vfx.play, list its problems with vfx.check. The editor's Particle panel (View > Particles) edits the same file. "
            "Example: {\"path\":\"assets/vfx/hit.vfx.json\",\"doc\":\"A hit: sparks.\"}";
        info.inputSchema = Json::object(
            {{"type", "object"},
             {"required", Json::array({"path"})},
             {"additionalProperties", false},
             {"properties", obj({{"path", Json::object({{"type", "string"}, {"description", "The effect document, project-relative, under assets/ and ending in .vfx.json."}})},
                                 {"doc", Json::object({{"type", "string"}, {"description", "The file's `doc` text: what the effect is and where the game plays it."}})},
                                 {"overwrite", Json::object({{"type", "boolean"}, {"default", false}, {"description", "Replace the file when it exists."}})}})}});
        mark_paths(info.inputSchema, "write", {"path"});
        registry.add(info, [projectDir](const Json& args) { return vfx_create_command(projectDir, args.is_null() ? Json::object() : args); });
    }
    {
        CommandInfo info;
        info.name = "vfx.edit";
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Change one field of an effect document by JSON pointer (set, remove, add to an array, move inside an array); the result must still be a valid effect.";
        info.description =
            "Edits `*.vfx.json` the way a hand edit would, but checked: the document is parsed again after the change (the same checks as vfx.check, without the files a sound names) and, when it would be invalid, nothing is written "
            "and the error lists the problems with their pointers. op `set` writes `value` at `pointer` (a field of an existing object, new or old); `remove` deletes the field or array element at `pointer`; `add` inserts `value` "
            "into the array at `pointer` (at `index`, default the end); `move` takes element `index` of the array at `pointer` to place `to`. The result has the effect's duration, its part count and the parser's warnings. "
            "Examples: {\"path\":\"assets/vfx/hit.vfx.json\",\"op\":\"set\",\"pointer\":\"/parts/0/emitter/burst\",\"value\":24} and "
            "{\"path\":\"assets/vfx/hit.vfx.json\",\"op\":\"add\",\"pointer\":\"/parts\",\"value\":{\"type\":\"light\",\"duration\":0.1,\"light\":{\"radius\":80}}}";
        info.inputSchema = Json::object(
            {{"type", "object"},
             {"required", Json::array({"path", "op", "pointer"})},
             {"additionalProperties", false},
             {"properties", obj({{"path", Json::object({{"type", "string"}, {"description", "The effect document, project-relative, ending in .vfx.json."}})},
                                 {"op", Json::object({{"type", "string"}, {"enum", Json::array({"set", "remove", "add", "move"})}, {"description", "What to do."}})},
                                 {"pointer", Json::object({{"type", "string"}, {"description", "JSON pointer into the document, e.g. /parts/0/emitter/burst or /parts."}})},
                                 {"value", Json::object({{"description", "The new value (set) or the element to insert (add). Any JSON."}})},
                                 {"index", Json::object({{"type", "integer"}, {"minimum", 0}, {"description", "add: where to insert; move: the element to move."}})},
                                 {"to", Json::object({{"type", "integer"}, {"minimum", 0}, {"description", "move: the element's new place."}})}})}});
        mark_paths(info.inputSchema, "write", {"path"});
        registry.add(info, [projectDir](const Json& args) { return vfx_edit_command(projectDir, args.is_null() ? Json::object() : args); });
    }
    // Capabilities (capability.h): the effect documents are project files.
    declare_command_capabilities(registry, {{"vfx.create", capability_sets::writes_project()}, {"vfx.edit", capability_sets::writes_project()}});
}

}  // namespace fa::assets_detail
