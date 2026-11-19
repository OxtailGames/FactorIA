// "material.graph.nodes", "material.graph.validate" and "material.graph.generate" (fa/tooling/material_graph.h).
#include <algorithm>
#include <filesystem>
#include <optional>

#include "assets_internal.h"
#include "fa/core/strings.h"
#include "fa/tooling/material_graph.h"
#include "shaders_internal.h"
#include "util.h"

namespace fa {

namespace stdfs = std::filesystem;

namespace {

// The project-relative path a command argument names: as written, or with ".material.json" added.
std::string resolve_material(const std::string& projectDir, const std::string& arg) {
    if (arg.empty())
        throw CommandError(
            "invalid_argument", "material is empty",
            "Pass the project-relative path of a *.material.json, e.g. \"materials/dissolve.material.json\".");
    const stdfs::path p = stdfs::path(arg).lexically_normal();
    if (p.is_absolute() || p.generic_string().rfind("..", 0) == 0)
        throw CommandError("invalid_argument", "material '" + arg + "' is not inside the project",
                           "Pass a path relative to the project root, e.g. \"materials/dissolve.material.json\".");
    std::error_code ec;
    for (const std::string& candidate : {p.generic_string(), p.generic_string() + ".material.json"})
        if (stdfs::is_regular_file(stdfs::path(projectDir) / candidate, ec)) return candidate;
    const std::vector<std::string> all = find_material_files(projectDir);
    throw CommandError("not_found", "no material '" + arg + "' in the project",
                       all.empty()
                           ? "The project has no *.material.json yet: create one (schemas/material.schema.json) with a "
                             "\"graph\" (`material.graph.nodes` lists the nodes)."
                           : did_you_mean(arg, all),
                       Json::object({{"materials", Json(all)}}));
}

Json issues_json(const std::vector<MaterialIssue>& issues) {
    Json arr = Json::array();
    for (const MaterialIssue& e : issues)
        arr.push_back(Json::object({{"pointer", e.pointer}, {"message", e.message}, {"hint", e.hint}}));
    return arr;
}

// The material file as written: its JSON, and the checked definition. Errors of the file (graph ones too) are a CommandError.
struct LoadedMaterial {
    std::string path;
    Json doc;
    MaterialDef def;
    std::string kind = "mesh";
    Json fileGraph;  // the "graph" of the file as it was read (null: none), before an override
};

// `graphOverride`: a graph to use instead of the file's (material.graph.generate with `graph`: the editor saves through it).
LoadedMaterial load_material(const std::string& projectDir, const Json& args, bool needGraph,
                             const Json* graphOverride = nullptr) {
    LoadedMaterial m;
    m.path = resolve_material(projectDir, tooling_detail::arg_string(args, "material", true));
    auto text = tooling_detail::read_file(stdfs::path(projectDir) / m.path);
    if (!text) throw CommandError("not_found", "cannot read " + m.path, "Check that the file is not open elsewhere.");
    auto parsed = parse_json(*text, m.path);
    if (!parsed.ok()) throw CommandError("invalid_material", parsed.error().message, "Fix the JSON syntax.");
    m.doc = parsed.value();
    if (auto g = m.doc.find("graph"); g != m.doc.end()) m.fileGraph = *g;
    if (graphOverride) m.doc["graph"] = *graphOverride;
    MaterialParse mp = parse_material(m.doc, projectDir, m.path);
    if (!mp.ok())
        throw CommandError(
            "invalid_material",
            m.path + " has " + std::to_string(mp.errors.size()) + " error(s): " + mp.errors.front().to_string(),
            "Fix them (schemas/material.schema.json; `material.graph.nodes` lists the nodes) and run the command "
            "again.",
            Json::object({{"errors", issues_json(mp.errors)}}));
    m.def = std::move(mp.material);
    if (auto k = m.doc.find("kind"); k != m.doc.end() && k->is_string()) m.kind = k->get<std::string>();
    if (needGraph && m.def.graph.is_null())
        throw CommandError(
            "no_graph", m.path + " has no \"graph\": its snippet is hand-written",
            "Add a \"graph\" ({\"nodes\": [...], \"links\": [...]}; `material.graph.nodes` shows the format and an "
            "example) to generate the snippet from nodes.");
    return m;
}

// How the snippet file stands against the graph (the states are listed in the command descriptions).
struct SnippetState {
    std::string state;
    std::optional<std::string> existing;  // the file's text, CRs removed; nullopt = no file
};

SnippetState snippet_state(const std::string& projectDir, const MaterialDef& def, const std::string& hash) {
    SnippetState s;
    if (auto raw = tooling_detail::read_file(stdfs::path(projectDir) / def.shader))
        s.existing = shaders_detail::normalize_snippet(*raw);
    const std::string& recorded = def.graphHash;
    if (!s.existing)
        s.state = "missing";
    else if (graph_snippet_hash(*s.existing) == hash && recorded == hash)
        s.state = "in_sync";
    else if (graph_snippet_hash(*s.existing) == hash)
        s.state = "hash_missing";  // the code is what the graph makes, the file does not say so
    else if (recorded.empty())
        s.state = "unmanaged";  // code that no generator wrote, next to a graph
    else if (graph_snippet_hash(*s.existing) == recorded)
        s.state = "graph_changed";  // the snippet is what the old graph made: generating updates it
    else
        s.state = "hand_edited";
    return s;
}

Json example_material() {
    return Json::parse(R"({
      "format": "factoria.material/1",
      "doc": "Dissolve: noise burns the surface away with a glowing edge.",
      "shader": "shaders/dissolve.surface.glsl",
      "alphaMode": "clip",
      "params": {
        "dissolve": { "type": "float", "default": 0.0, "min": 0.0, "max": 1.0, "doc": "0 shows the surface, 1 dissolves it all." }
      },
      "graph": {
        "nodes": [
          { "id": "noise", "type": "noise.fbm", "pos": [0, 0], "inputs": { "scale": 6.0 } },
          { "id": "amount", "type": "param", "pos": [0, 120], "param": "dissolve" },
          { "id": "burn", "type": "dissolve", "pos": [220, 60], "inputs": { "edgeWidth": 0.06, "edgeColor": [1.0, 0.4, 0.1] } },
          { "id": "out", "type": "output", "pos": [440, 60], "inputs": { "albedo": [0.6, 0.6, 0.65], "roughness": 0.7 } }
        ],
        "links": [
          { "from": "noise.value", "to": "burn.noise" },
          { "from": "amount.value", "to": "burn.threshold" },
          { "from": "burn.alpha", "to": "out.alpha" },
          { "from": "burn.emission", "to": "out.emission" }
        ]
      }
    })");
}

const char* const kFormatText =
    "A *.material.json may hold \"graph\": {\"nodes\": [{\"id\", \"type\", \"pos\": [x, y], \"inputs\": {input: "
    "constant}, "
    "\"param\"|\"texture\": name}], \"links\": [{\"from\": \"nodeId.output\", \"to\": \"nodeId.input\"}]}. Exactly one "
    "node has "
    "type \"output\". An input takes a constant (a number, or an array of 2 to 4 numbers) or one link; an input with "
    "neither "
    "reads its default (listed by this command). A float widens to any vector; other size changes need math.split and "
    "math.combine. Params and textures a node names are the material's own \"params\" and \"textures\". "
    "material.graph.generate writes the snippet named by \"shader\" and \"graphHash\" into the material file.";

// ---- params and textures of the material file (material.param.create|rename|delete, material.texture.create|rename|delete) ----

// One of the two lists of a material file that nodes read from.
struct Section {
    const char* key;   // "params" | "textures": the key in the material file
    const char* what;  // "param" | "texture": the word of the messages, and the key a node names it with
};
constexpr Section kParams{"params", "param"};
constexpr Section kTextures{"textures", "texture"};

std::string str_member(const Json& o, const char* key) {
    if (!o.is_object()) return {};
    auto it = o.find(key);
    return it != o.end() && it->is_string() ? it->get<std::string>() : std::string();
}

// The `graph` argument: the graph the editor holds in memory. Null when it is not passed.
Json graph_argument(const Json& args) {
    auto g = args.find("graph");
    if (g == args.end()) return Json();
    auto nodes = g->is_object() ? g->find("nodes") : g->end();
    if (!g->is_object() || nodes == g->end() || !nodes->is_array())
        throw CommandError("invalid_argument", "graph is not a graph: it needs a \"nodes\" array",
                           "Pass the graph object of the material ({\"nodes\": [...], \"links\": [...]}), or leave the "
                           "argument out to use the one in the file.");
    return *g;
}

// The ids of the nodes of `graph` that read the param or texture `name`.
std::vector<std::string> readers_of(const Json& graph, const Section& sec, const std::string& name) {
    std::vector<std::string> ids;
    auto nodes = graph.is_object() ? graph.find("nodes") : graph.end();
    if (nodes == graph.end() || !nodes->is_array()) return ids;
    for (const Json& n : *nodes) {
        const GraphNodeType* t = find_graph_node_type(str_member(n, "type"));
        if (t && t->ref == sec.what && str_member(n, sec.what) == name) ids.push_back(str_member(n, "id"));
    }
    return ids;
}

// Points the nodes that read `from` at `to`; the ids of the nodes changed.
std::vector<std::string> rename_readers(Json& graph, const Section& sec, const std::string& from,
                                        const std::string& to) {
    std::vector<std::string> ids;
    auto nodes = graph.is_object() ? graph.find("nodes") : graph.end();
    if (nodes == graph.end() || !nodes->is_array()) return ids;
    for (Json& n : *nodes) {
        const GraphNodeType* t = find_graph_node_type(str_member(n, "type"));
        if (t && t->ref == sec.what && str_member(n, sec.what) == from) {
            n[sec.what] = to;
            ids.push_back(str_member(n, "id"));
        }
    }
    return ids;
}

// Removes the nodes that read `name` and the links that touch them; the ids removed.
std::vector<std::string> remove_readers(Json& graph, const Section& sec, const std::string& name) {
    const std::vector<std::string> ids = readers_of(graph, sec, name);
    if (ids.empty()) return ids;
    Json kept = Json::array();
    for (const Json& n : graph["nodes"])
        if (std::find(ids.begin(), ids.end(), str_member(n, "id")) == ids.end()) kept.push_back(n);
    graph["nodes"] = kept;
    auto links = graph.find("links");
    if (links != graph.end() && links->is_array()) {
        auto touches = [&](const std::string& end) {
            return std::find(ids.begin(), ids.end(), end.substr(0, end.find('.'))) != ids.end();
        };
        Json keptLinks = Json::array();
        for (const Json& l : *links)
            if (!touches(str_member(l, "from")) && !touches(str_member(l, "to"))) keptLinks.push_back(l);
        graph["links"] = keptLinks;
    }
    return ids;
}

std::vector<std::string> names_of(const Json& doc, const char* key) {
    std::vector<std::string> names;
    auto it = doc.find(key);
    if (it != doc.end() && it->is_object())
        for (auto e = it->begin(); e != it->end(); ++e) names.push_back(e.key());
    return names;
}

// A name for a new param or texture (create, or the new name of a rename): refused with the fix when it is empty, taken or reserved by the
// graph. What the file checker finds (identifier rules, GLSL words, the engine's names) is found by parse_material on the patched file.
void check_new_name(const LoadedMaterial& m, const Section& sec, const std::string& name) {
    if (name.empty())
        throw CommandError("invalid_argument", std::string(sec.what) + " name is empty",
                           "Name it for what it does, e.g. \"waveHeight\": it becomes a GLSL variable of the snippet.");
    for (const Section* other : {&kParams, &kTextures}) {
        const std::vector<std::string> taken = names_of(m.doc, other->key);
        if (std::find(taken.begin(), taken.end(), name) == taken.end()) continue;
        throw CommandError(
            "already_exists", m.path + " already has a " + other->what + " named \"" + name + "\"",
            "Params and textures share one namespace: pick another name" +
                std::string(std::string(other->what) == "param" && std::string(sec.what) == "param"
                                ? ", or change the existing one (material.param.set_default sets its default)."
                                : "."),
            Json::object({{"existing", Json(taken)}}));
    }
    if (name.rfind("gn_", 0) == 0)
        throw CommandError("reserved_name",
                           std::string(sec.what) + " name \"" + name +
                               "\" starts with gn_, which the node graph keeps for its GLSL helper functions",
                           "Pick a name without the prefix, e.g. \"" +
                               (name.size() > 3 ? name.substr(3) : std::string("waveHeight")) + "\".");
}

// The patched file must be a valid material: its first error becomes the command's error (JSON pointer, what is wrong, the fix).
void require_valid(const Json& patched, const std::string& projectDir, const std::string& path) {
    const MaterialParse mp = parse_material(patched, projectDir, path);
    if (mp.ok()) return;
    const MaterialIssue& e = mp.errors.front();
    throw CommandError("invalid_value", path + e.pointer + ": " + e.message, e.hint,
                       Json::object({{"pointer", e.pointer}, {"errors", issues_json(mp.errors)}}));
}

// Writes the patched material file. With `syncSnippet`, and when the snippet on disk is the one the file's graph makes (state "in_sync"), the
// snippet is made again right after: a rename or a delete changes the GLSL names the snippet uses, and one that names a param the file no
// longer has would not compile. out["snippet"] = {state, regenerated[, error]}.
void write_patched(const CommandRegistry& registry, const std::string& projectDir, const LoadedMaterial& m,
                   const Json& patched, bool dryRun, bool syncSnippet, Json& out) {
    std::string state = "none";
    if (syncSnippet && m.def.graph.is_object()) {
        const GeneratedGraph g = generate_graph_snippet(m.def.graph, m.def, m.kind);
        state = g.check.ok() ? snippet_state(projectDir, m.def, g.hash).state : "unchecked";
    }
    Json snippet = Json::object({{"state", state}, {"regenerated", false}});
    out["written"] = !dryRun;
    if (dryRun) {
        snippet["regenerated"] = state == "in_sync";  // what a real call would do
    } else {
        const stdfs::path materialPath = assets_detail::project_write_file(projectDir, m.path);
        std::string err;
        if (!tooling_detail::write_file(materialPath, dump_json(patched, JsonFormat{}) + "\n", &err))
            throw CommandError("failed", "cannot write " + m.path + ": " + err,
                               "Check that the file is not open elsewhere or read-only. Nothing was changed.");
        if (state == "in_sync") {
            const CommandResult r = registry.call("material.graph.generate", Json::object({{"material", m.path}}));
            snippet["regenerated"] = r.ok;
            if (!r.ok)
                snippet["error"] = r.error.value("message", std::string("material.graph.generate failed")) + " " +
                                   r.error.value("hint", std::string());
        }
    }
    out["snippet"] = snippet;
}

// The same list with the key `from` called `to`, in the same place.
Json renamed_key(const Json& list, const std::string& from, const std::string& to) {
    Json out = Json::object();
    for (auto it = list.begin(); it != list.end(); ++it) out[it.key() == from ? to : it.key()] = it.value();
    return out;
}

const char* const kGraphArgText = "The graph the editor holds in memory (same format as \"graph\" of the material). "
                                  "The nodes in it that read the name are followed "
                                  "as well, and the result's `graph` is that graph changed; it is never written.";

void add_entry_commands(CommandRegistry& registry, const std::string& projectDir, const Section& sec) {
    const bool isParam = std::string(sec.what) == "param";
    const std::string word = sec.what;
    const std::string prefix = "material." + word + ".";
    const Json materialProp = Json::parse(
        R"({"type":"string","description":"Project-relative path of the material, e.g. materials/dissolve.material.json."})");
    const Json dryRunProp = Json::parse(
        R"({"type":"boolean","default":false,"description":"Check and report what would be written, and write nothing."})");
    const std::string exampleName = isParam ? "glow" : "maskMap";

    // ---- create
    {
        CommandInfo info;
        info.name = prefix + "create";
        info.category = "material";
        info.readOnly = false;
        info.summary = "Add a " + word + " to a material file (the Graph panel's \"+\").";
        info.description =
            "Adds the " + word + " `name` to \"" + sec.key + "\" of the material file and changes nothing else. " +
            (isParam ? "`type` is float, vec2, vec3, vec4 or color; without `default` the value is 0 in every "
                       "component (1 for a "
                       "color), moved into min..max when they are given. "
                     : "`default` is the project-relative texture used when an entity gives none; `sampler` is linear, "
                       "linearRepeat, nearest or nearestRepeat. ") +
            "Without `doc` a placeholder is written (the file format requires one: AIs read it through material.info), "
            "so write "
            "one. The result is checked as the file is: a name that is taken (params and textures share one "
            "namespace), starts "
            "with gn_ or fa_, is a GLSL word or a name of the snippet contract is refused with the fix, and nothing is "
            "written. "
            "With dryRun true nothing is written. Writing the material file formats it again (2-space JSON). Returns "
            "{material, "
            "kind, name, entry, written}; `entry` is what was added. " +
            prefix + "delete takes it back. Example: " +
            (isParam
                 ? "{\"material\":\"materials/dissolve.material.json\",\"name\":\"glow\",\"type\":\"float\",\"min\":0,"
                   "\"max\":1}"
                 : "{\"material\":\"materials/"
                   "dissolve.material.json\",\"name\":\"maskMap\",\"sampler\":\"linearRepeat\"}");
        Json props = Json::object(
            {{"material", materialProp},
             {"name", Json::object({{"type", "string"},
                                    {"description",
                                     "The new " + word +
                                         "'s name: a GLSL identifier (it is a variable of the snippet), unique among "
                                         "the params and textures, without the prefix gn_ or fa_."}})}});
        Json required = Json::array({"material", "name"});
        if (isParam) {
            required.push_back("type");
            props["type"] = Json::parse(
                R"({"type":"string","description":"float, vec2, vec3, vec4, or color (a vec4 the editor shows as a color picker)."})");
            props["default"] = Json::parse(
                R"({"description":"A number for float, an array of 2, 3 or 4 numbers for the others. Default: zeros (a color: white).","oneOf":[{"type":"number"},{"type":"array","items":{"type":"number"},"minItems":2,"maxItems":4}]})");
            props["min"] = Json::parse(
                R"({"type":"number","description":"Smallest sensible value (the editor slider's start); the default is checked against it."})");
            props["max"] = Json::parse(
                R"({"type":"number","description":"Largest sensible value (the editor slider's end); the default is checked against it."})");
            props["instanced"] = Json::parse(
                R"({"type":"boolean","description":"true: every entity's value travels in the instance data (docs/SHADERS.md, params)."})");
        } else {
            props["default"] = Json::parse(
                R"({"type":"string","description":"Project-relative texture used when an entity gives none."})");
            props["sampler"] = Json::parse(
                R"({"type":"string","description":"linear (default), linearRepeat, nearest or nearestRepeat: filtering and wrapping of the sampler."})");
        }
        props["doc"] = Json::parse(
            R"({"type":"string","description":"What it holds or does, with its unit. Default: a placeholder to replace."})");
        props["dryRun"] = dryRunProp;
        info.inputSchema = Json::object(
            {{"type", "object"}, {"required", required}, {"additionalProperties", false}, {"properties", props}});
        assets_detail::mark_paths(info.inputSchema, "write", {"material"});
        registry.add(info, [&registry, projectDir, sec, isParam, word](const Json& args) {
            const bool dryRun = tooling_detail::arg_bool(args, "dryRun", false);
            LoadedMaterial m = load_material(projectDir, args, false);
            const std::string name = tooling_detail::arg_string(args, "name", true);
            check_new_name(m, sec, name);
            Json entry = Json::object();
            if (isParam) {
                const std::string type = tooling_detail::arg_string(args, "type", true);
                entry["type"] = type;
                auto def = args.find("default");
                if (def != args.end()) {
                    entry["default"] = *def;
                } else {
                    const int n = type == "float" ? 1 : type == "vec2" ? 2 : type == "vec3" ? 3 : 4;
                    double v = type == "color" ? 1.0 : 0.0;
                    auto lo = args.find("min");
                    auto hi = args.find("max");
                    if (lo != args.end() && lo->is_number()) v = std::max(v, lo->get<double>());
                    if (hi != args.end() && hi->is_number()) v = std::min(v, hi->get<double>());
                    if (n == 1) {
                        entry["default"] = v;
                    } else {
                        Json a = Json::array();
                        for (int i = 0; i < n; ++i) a.push_back(v);
                        entry["default"] = a;
                    }
                }
                for (const char* key : {"min", "max", "instanced"})
                    if (auto it = args.find(key); it != args.end()) entry[key] = *it;
            } else {
                for (const char* key : {"default", "sampler"})
                    if (auto it = args.find(key); it != args.end()) entry[key] = *it;
            }
            entry["doc"] = args.contains("doc")
                               ? args["doc"]
                               : Json(word + " " + name + ": describe what it does (replace this text).");
            Json patched = m.doc;
            if (!patched.contains(sec.key) || !patched[sec.key].is_object()) patched[sec.key] = Json::object();
            patched[sec.key][name] = entry;
            require_valid(patched, projectDir, m.path);
            Json out = Json::object({{"material", m.path}, {"kind", word}, {"name", name}, {"entry", entry}});
            write_patched(registry, projectDir, m, patched, dryRun, false, out);
            return out;
        });
    }

    // ---- rename
    {
        CommandInfo info;
        info.name = prefix + "rename";
        info.category = "material";
        info.readOnly = false;
        info.summary = "Rename a " + word + " of a material file and the graph nodes that read it.";
        info.description =
            "Renames the " + word + " `name` to `newName` in \"" + sec.key +
            "\" of the material file and points every node of the file's graph that reads it at the new name "
            "(`renamedNodes`). "
            "With `graph` the nodes of that graph are followed too (the Graph panel passes the graph it holds, unsaved "
            "edits "
            "included) and the result's `graph` is that graph changed; it is never written. The new name is checked as "
            "a new one "
            "is (taken, gn_ or fa_ prefix, GLSL words...): refused with the fix, nothing is written. When the shader "
            "snippet is "
            "the one the graph generated (state in_sync) it is generated again, so the file and its snippet stay in "
            "step "
            "(`snippet.regenerated`); a hand-edited snippet is left alone. Scenes and prefabs that set the old name in "
            "MeshRenderer.materialParams are NOT changed. With dryRun true nothing is written. Returns {material, "
            "kind, name, "
            "newName, renamedNodes, written, snippet[, graph]}: call it again with the names swapped to take it back. "
            "Example: "
            "{\"material\":\"materials/dissolve.material.json\",\"name\":\"" +
            exampleName + "\",\"newName\":\"" + exampleName + "2\"}";
        info.inputSchema = Json::object(
            {{"type", "object"},
             {"required", Json::array({"material", "name", "newName"})},
             {"additionalProperties", false},
             {"properties",
              Json::object(
                  {{"material", materialProp},
                   {"name", Json::object({{"type", "string"},
                                          {"description", "The " + word + " to rename (material.info lists them)."}})},
                   {"newName", Json::object({{"type", "string"},
                                             {"description", "Its new name, a GLSL identifier unique among the params "
                                                             "and textures, without the prefix gn_ or fa_."}})},
                   {"graph", Json::object({{"type", "object"}, {"description", kGraphArgText}})},
                   {"dryRun", dryRunProp}})}});
        assets_detail::mark_paths(info.inputSchema, "write", {"material"});
        registry.add(info, [&registry, projectDir, sec, word](const Json& args) {
            const bool dryRun = tooling_detail::arg_bool(args, "dryRun", false);
            LoadedMaterial m = load_material(projectDir, args, false);
            Json graph = graph_argument(args);
            const std::string name = tooling_detail::arg_string(args, "name", true);
            const std::string newName = tooling_detail::arg_string(args, "newName", true);
            const std::vector<std::string> names = names_of(m.doc, sec.key);
            if (std::find(names.begin(), names.end(), name) == names.end())
                throw CommandError(
                    "not_found", m.path + " has no " + word + " \"" + name + "\" in its \"" + sec.key + "\"",
                    names.empty() ? "The material declares no " + word + "s." : did_you_mean(name, names),
                    Json::object({{sec.key, Json(names)}}));
            Json out = Json::object({{"material", m.path}, {"kind", word}, {"name", name}, {"newName", newName}});
            if (name == newName) {  // nothing to do
                out["renamedNodes"] = Json::array();
                out["written"] = false;
                out["snippet"] = Json::object({{"state", "none"}, {"regenerated", false}});
                if (!graph.is_null()) out["graph"] = graph;
                return out;
            }
            check_new_name(m, sec, newName);
            Json patched = m.doc;
            patched[sec.key] = renamed_key(m.doc[sec.key], name, newName);
            Json renamed = Json::array();
            if (patched.contains("graph") && patched["graph"].is_object())
                for (const std::string& id : rename_readers(patched["graph"], sec, name, newName))
                    renamed.push_back(id);
            if (!graph.is_null()) {
                Json nodes = Json::array();
                for (const std::string& id : rename_readers(graph, sec, name, newName)) nodes.push_back(id);
                if (patched.contains("graph") && patched["graph"].is_object()) {
                    // the ids in the memory graph that the file's graph does not have (an unsaved node) are reported too
                    for (const Json& id : nodes)
                        if (std::find(renamed.begin(), renamed.end(), id) == renamed.end()) renamed.push_back(id);
                } else {
                    renamed = nodes;
                }
                out["graph"] = graph;
            }
            require_valid(patched, projectDir, m.path);
            out["renamedNodes"] = renamed;
            write_patched(registry, projectDir, m, patched, dryRun, true, out);
            return out;
        });
    }

    // ---- delete
    {
        CommandInfo info;
        info.name = prefix + "delete";
        info.category = "material";
        info.readOnly = false;
        info.summary = "Remove a " + word + " from a material file; refused while graph nodes read it unless forced.";
        info.description =
            "Removes the " + word + " `name` from \"" + sec.key +
            "\" of the material file. When nodes of the graph read it (the file's, and `graph` when passed) the call "
            "is refused "
            "with error code in_use and the node ids in data.nodes: point or delete those nodes first, or pass force "
            "true, which "
            "removes those nodes and the links that touch them too (the nodes' own inputs fall back to their "
            "defaults). `graph` is "
            "the graph the editor holds in memory: it, not the file's graph, says which nodes read the " +
            word +
            "; the result's `graph` is that graph changed, and it is never written. When the "
            "shader snippet is the one the graph generated (state in_sync) it is generated again "
            "(`snippet.regenerated`); a "
            "hand-edited snippet is left alone. Scenes and prefabs that set the name in MeshRenderer.materialParams "
            "are NOT "
            "changed. With dryRun true nothing is written. Returns {material, kind, name, entry, removedNodes, "
            "written, "
            "snippet[, graph]}; `entry` is the definition removed: " +
            prefix +
            "create with it takes it back. Example: {\"material\":\"materials/dissolve.material.json\",\"name\":\"" +
            exampleName + "\"}";
        info.inputSchema = Json::object(
            {{"type", "object"},
             {"required", Json::array({"material", "name"})},
             {"additionalProperties", false},
             {"properties",
              Json::object(
                  {{"material", materialProp},
                   {"name", Json::object({{"type", "string"}, {"description", "The " + word + " to remove."}})},
                   {"force", Json::object({{"type", "boolean"},
                                           {"default", false},
                                           {"description", "Also remove the nodes that read it (and their links)."}})},
                   {"graph", Json::object({{"type", "object"}, {"description", kGraphArgText}})},
                   {"dryRun", dryRunProp}})}});
        assets_detail::mark_paths(info.inputSchema, "write", {"material"});
        registry.add(info, [&registry, projectDir, sec, word](const Json& args) {
            const bool dryRun = tooling_detail::arg_bool(args, "dryRun", false);
            const bool force = tooling_detail::arg_bool(args, "force", false);
            LoadedMaterial m = load_material(projectDir, args, false);
            Json graph = graph_argument(args);
            const std::string name = tooling_detail::arg_string(args, "name", true);
            const std::vector<std::string> names = names_of(m.doc, sec.key);
            if (std::find(names.begin(), names.end(), name) == names.end())
                throw CommandError(
                    "not_found", m.path + " has no " + word + " \"" + name + "\" in its \"" + sec.key + "\"",
                    names.empty() ? "The material declares no " + word + "s." : did_you_mean(name, names),
                    Json::object({{sec.key, Json(names)}}));
            // The graph the caller holds in memory is the one that counts (a node it already removed does not keep the param); the
            // file's own graph is the judge when no `graph` is passed.
            std::vector<std::string> readers;
            if (!graph.is_null())
                readers = readers_of(graph, sec, name);
            else if (m.doc.contains("graph"))
                readers = readers_of(m.doc["graph"], sec, name);
            if (!readers.empty() && !force)
                throw CommandError("in_use",
                                   word + " \"" + name + "\" is read by " + std::to_string(readers.size()) +
                                       " node(s): " + join(readers, ", "),
                                   "Point those nodes at another " + word + " (the \"" + word +
                                       "\" field of the node) or delete them, then delete the " + word +
                                       "; or pass force true to remove the " + word + " and those nodes.",
                                   Json::object({{"nodes", Json(readers)}}));
            Json patched = m.doc;
            const Json entry = m.doc[sec.key][name];
            patched[sec.key].erase(name);
            if (patched[sec.key].empty()) patched.erase(sec.key);
            Json removed = Json::array();
            if (patched.contains("graph") && patched["graph"].is_object())
                for (const std::string& id : remove_readers(patched["graph"], sec, name)) removed.push_back(id);
            if (!graph.is_null()) {
                for (const std::string& id : remove_readers(graph, sec, name))
                    if (std::find(removed.begin(), removed.end(), id) == removed.end()) removed.push_back(id);
            }
            require_valid(patched, projectDir, m.path);
            Json out = Json::object(
                {{"material", m.path}, {"kind", word}, {"name", name}, {"entry", entry}, {"removedNodes", removed}});
            if (!graph.is_null()) out["graph"] = graph;
            write_patched(registry, projectDir, m, patched, dryRun, true, out);
            return out;
        });
    }
}

}  // namespace

void register_material_graph_commands(CommandRegistry& registry, const std::string& projectDir) {
    {
        CommandInfo info;
        info.name = "material.graph.nodes";
        info.category = "material";
        info.readOnly = true;
        info.summary =
            "List the node types of the material graph library, with their inputs, outputs and the kinds they work in.";
        info.description = "Returns {format, kinds, categories, nodes: [{type, category, doc, kinds, stage, needs?, "
                           "inputs: [{name, type, "
                           "default?, doc}], outputs: [{name, type, doc}]}], example}. `format` says how the \"graph\" "
                           "of a *.material.json is "
                           "written; `example` is a complete material (a dissolve) whose graph passes "
                           "material.graph.validate. An input "
                           "type \"gen\" is a float or a vector; a float widens by itself. `stage` is \"fragment\" for "
                           "nodes that sample "
                           "textures or read the view direction (not allowed in the path of the output's "
                           "vertexOffset). Filters: `kind` "
                           "(\"mesh\"), `category`, `type`. Example: {\"category\":\"noise\"}";
        info.inputSchema = Json::parse(R"({
          "type":"object","additionalProperties":false,
          "properties":{
            "kind":{"type":"string","description":"Only nodes that work in this material kind (\"mesh\")."},
            "category":{"type":"string","description":"Only this category: constant, input, texture, math, noise, effect or output."},
            "type":{"type":"string","description":"Only this node type, e.g. \"noise.fbm\"."}}})");
        registry.add(info, [](const Json& args) {
            const std::string kind = tooling_detail::arg_string(args, "kind", false);
            const std::string category = tooling_detail::arg_string(args, "category", false);
            const std::string type = tooling_detail::arg_string(args, "type", false);
            Json out = graph_library_json(kind, category, type);
            if (out["nodes"].empty()) {
                std::vector<std::string> names, categories;
                for (const GraphNodeType& t : graph_node_library()) {
                    names.push_back(t.type);
                    if (std::find(categories.begin(), categories.end(), t.category) == categories.end())
                        categories.push_back(t.category);
                }
                throw CommandError("not_found", "no node type matches the filters",
                                   !type.empty() ? did_you_mean(type, names)
                                   : !category.empty()
                                       ? did_you_mean(category, categories)
                                       : "Kinds with graphs: " + join(graph_supported_kinds(), ", ") + ".");
            }
            Json result = Json::object({{"format", kFormatText}, {"kinds", Json(graph_supported_kinds())}});
            for (auto it = out.begin(); it != out.end(); ++it) result[it.key()] = it.value();
            result["example"] = example_material();
            return result;
        });
    }
    {
        CommandInfo info;
        info.name = "material.graph.validate";
        info.category = "material";
        info.readOnly = true;
        info.summary = "Check the node graph of a material and say whether its snippet is in sync with it.";
        info.description =
            "Checks the \"graph\" of a *.material.json: node ids and types, constants, the params and textures nodes "
            "name, "
            "links (unknown node or port, a second link into an input, type mismatches), cycles, the output node, "
            "nodes that "
            "need the fragment stage on the path of vertexOffset and the material kind. Every error has a JSON pointer "
            "into the "
            "material file, what is wrong and how to fix it. Returns {material, ok, errors: [{pointer, message, "
            "hint}], warnings, "
            "snippet: {path, state}}. state: \"in_sync\", \"graph_changed\" (the snippet is what the previous graph "
            "made: "
            "generate updates it), \"hand_edited\" (the snippet no longer matches graphHash: generate refuses without "
            "force), \"unmanaged\" (a snippet that no generator wrote), \"hash_missing\", \"missing\" or \"unchecked\" "
            "(the graph "
            "has errors). With `graph` (an object like the one in the file) that graph is checked instead of the "
            "file's: the "
            "editor's canvas validates the graph it holds in memory this way, against the params, textures and kind of "
            "the "
            "saved material. Example: {\"material\":\"materials/dissolve.material.json\"}";
        info.inputSchema = Json::parse(R"({
          "type":"object","required":["material"],"additionalProperties":false,
          "properties":{
            "material":{"type":"string","description":"Project-relative path of the material, e.g. materials/dissolve.material.json."},
            "graph":{"type":"object","description":"A graph to check instead of the one in the file (same format as \"graph\" of the material). Pointers still start at /graph."}}})");
        assets_detail::mark_paths(info.inputSchema, "read", {"material"});
        registry.add(info, [projectDir](const Json& args) {
            const std::string path = resolve_material(projectDir, tooling_detail::arg_string(args, "material", true));
            auto text = tooling_detail::read_file(stdfs::path(projectDir) / path);
            if (!text)
                throw CommandError("not_found", "cannot read " + path, "Check that the file is not open elsewhere.");
            auto parsed = parse_json(*text, path);
            if (!parsed.ok()) throw CommandError("invalid_material", parsed.error().message, "Fix the JSON syntax.");
            Json doc = parsed.value();
            // A graph passed in the call replaces the one in the file: the canvas of the editor checks what it holds in memory
            // against the params, textures and kind of the saved material.
            if (auto g = args.find("graph"); g != args.end()) doc["graph"] = *g;
            const MaterialGraphReport r = check_material_document(doc, projectDir, path);
            Json out = Json::object({{"material", path}, {"ok", r.errors.empty()}});
            if (!r.hasGraph) {
                out["ok"] = false;
                out["errors"] = Json::array({Json::object(
                    {{"pointer", "/graph"},
                     {"message", "the material has no \"graph\""},
                     {"hint",
                      "Add one ({\"nodes\": [...], \"links\": [...]}); `material.graph.nodes` shows the format."}})});
                out["warnings"] = Json::array();
                return out;
            }
            out["errors"] = issues_json(r.errors);
            out["warnings"] = issues_json(r.warnings);
            Json snippet = Json::object({{"path", r.material.shader}});
            if (r.errors.empty()) {
                snippet["state"] = snippet_state(projectDir, r.material, r.hash).state;
                snippet["hash"] = r.hash;
            } else {
                snippet["state"] = "unchecked";
            }
            out["snippet"] = snippet;
            return out;
        });
    }
    {
        CommandInfo info;
        info.name = "material.graph.generate";
        info.category = "material";
        info.readOnly = false;
        info.summary =
            "Generate the GLSL snippet of a material from its node graph and record its hash in the material file.";
        info.description =
            "Checks the \"graph\" of the material (as material.graph.validate), generates the snippet (readable GLSL, "
            "one line "
            "per node with a comment naming the node id; the same graph gives the same bytes) into the file named by "
            "\"shader\" and writes \"graphHash\" (SHA-256 of the snippet) into the material file. With `graph` the "
            "command checks, stores and generates that graph instead of the one in the file (the node editor saves "
            "through it, so the snippet and the hash have one writer). A snippet that does "
            "not "
            "match the recorded hash was edited by hand (or was written without a graph): the command refuses and "
            "changes "
            "nothing, because the edit would be lost. Then either pass force true to overwrite it, or delete \"graph\" "
            "from the material to keep the hand-written code. With dryRun true nothing is written. Writing the "
            "material file "
            "formats it again (2-space JSON). Returns {material, shader, state, written, hash, usedNodes, warnings}; "
            "state is the "
            "one material.graph.validate reports before the write. Run shader.compile afterwards. Example: "
            "{\"material\":\"materials/dissolve.material.json\"}";
        info.inputSchema = Json::parse(R"({
          "type":"object","required":["material"],"additionalProperties":false,
          "properties":{
            "material":{"type":"string","description":"Project-relative path of the material, e.g. materials/dissolve.material.json."},
            "force":{"type":"boolean","default":false,"description":"Overwrite a snippet that was edited by hand (or never generated)."},
            "graph":{"type":"object","description":"A graph to store in the material and generate the snippet from, instead of the one the file holds (the node editor saves this way)."},
            "dryRun":{"type":"boolean","default":false,"description":"Check and report what would be written, and write nothing."}}})");
        assets_detail::mark_paths(info.inputSchema, "write", {"material"});
        registry.add(info, [projectDir](const Json& args) {
            const bool force = tooling_detail::arg_bool(args, "force", false);
            const bool dryRun = tooling_detail::arg_bool(args, "dryRun", false);
            const Json* graphArg = nullptr;
            if (auto g = args.find("graph"); g != args.end()) graphArg = &*g;
            LoadedMaterial m = load_material(projectDir, args, true, graphArg);
            GeneratedGraph g = generate_graph_snippet(m.def.graph, m.def, m.kind);
            if (!g.check.ok())  // load_material found these already; kept for a graph that only fails for the kind
                throw CommandError("invalid_graph",
                                   m.path + ": " + g.check.errors.front().pointer + ": " +
                                       g.check.errors.front().message,
                                   "Fix the graph (`material.graph.validate` lists every error).",
                                   Json::object({{"errors", issues_json(g.check.errors)}}));
            const SnippetState st = snippet_state(projectDir, m.def, g.hash);
            if ((st.state == "hand_edited" || st.state == "unmanaged") && !force)
                throw CommandError(
                    "hand_edited",
                    st.state == "hand_edited"
                        ? m.def.shader +
                              " was edited by hand since the graph generated it (its hash is not graphHash in " +
                              m.path + "); generating would overwrite those edits"
                        : m.def.shader + " exists but no generator wrote it (" + m.path +
                              " has no graphHash for it); generating would "
                              "overwrite it",
                    "Pass force true to overwrite the snippet with the graph's code, or delete the \"graph\" (and "
                    "graphHash) from " +
                        m.path + " to keep the hand-written code.",
                    Json::object({{"state", st.state}, {"shader", m.def.shader}}));
            const bool snippetChanges = !st.existing || *st.existing != g.snippet;
            // the material file changes when the hash does, or when `graph` is not what the file holds
            const bool hashChanges = m.def.graphHash != g.hash || (graphArg && m.fileGraph != *graphArg);
            Json out = Json::object({{"material", m.path},
                                     {"shader", m.def.shader},
                                     {"state", st.state},
                                     {"hash", g.hash},
                                     {"usedNodes", Json(g.usedNodes)},
                                     {"warnings", issues_json(g.check.warnings)},
                                     {"dryRun", dryRun}});
            out["written"] = !dryRun && (snippetChanges || hashChanges);
            if (dryRun || (!snippetChanges && !hashChanges)) return out;
            // Both paths are checked (inside the project, not .git or .factoria) before anything is written.
            const stdfs::path snippetPath = assets_detail::project_write_file(projectDir, m.def.shader);
            const stdfs::path materialPath = assets_detail::project_write_file(projectDir, m.path);
            const std::optional<std::string> oldSnippet = tooling_detail::read_file(snippetPath);
            std::string err;
            if (snippetChanges && !tooling_detail::write_file(snippetPath, g.snippet, &err))
                throw CommandError("failed", "cannot write " + m.def.shader + ": " + err,
                                   "Check that the file is not open elsewhere or read-only. Nothing was changed.");
            if (hashChanges) {
                m.doc["graphHash"] = g.hash;
                if (!tooling_detail::write_file(materialPath, dump_json(m.doc, JsonFormat{}) + "\n", &err)) {
                    // Put the snippet back: a snippet that no hash covers would look hand-edited.
                    bool restored = true;
                    if (snippetChanges) {
                        std::error_code ec;
                        if (oldSnippet)
                            restored = tooling_detail::write_file(snippetPath, *oldSnippet);
                        else
                            stdfs::remove(snippetPath, ec), restored = !ec;
                    }
                    throw CommandError(
                        "failed", "cannot write " + m.path + ": " + err,
                        restored ? "Check that the file is not open elsewhere or read-only. Nothing was changed."
                                 : "The snippet " + m.def.shader +
                                       " was already rewritten and could not be put back: "
                                       "run the command again once " +
                                       m.path + " can be written.");
                }
            }
            return out;
        });
    }
    {
        CommandInfo info;
        info.name = "material.param.set_default";
        info.category = "material";
        info.readOnly = false;
        info.summary = "Set the default value of one param of a material file (the Graph panel's \"Set as default\").";
        info.description =
            "Writes `value` as the \"default\" of the param `param` in the material file and changes nothing else (the "
            "shader snippet and the graph stay as they are: a default is read at run time, so no snippet needs to be "
            "generated again). The value is checked as the file is: a float param takes a number, vec2, vec3, vec4 and "
            "color take an array of 2, 3 or 4 numbers, and the value must be inside min and max when the param has "
            "them. Nothing is written when the value is already the default. With dryRun true nothing is written. "
            "Writing the material file formats it again (2-space JSON). Returns {material, param, previous, value, "
            "written}: call it again with `previous` to take the change back. Example: "
            "{\"material\":\"materials/dissolve.material.json\",\"param\":\"dissolve\",\"value\":0.4}";
        info.inputSchema = Json::parse(R"({
          "type":"object","required":["material","param","value"],"additionalProperties":false,
          "properties":{
            "material":{"type":"string","description":"Project-relative path of the material, e.g. materials/dissolve.material.json."},
            "param":{"type":"string","description":"The name of a param written in the material file's \"params\" (material.info lists them)."},
            "value":{"description":"The new default: a number for a float param, an array of 2 to 4 numbers for the others.","oneOf":[{"type":"number"},{"type":"array","items":{"type":"number"},"minItems":2,"maxItems":4}]},
            "dryRun":{"type":"boolean","default":false,"description":"Check and report what would be written, and write nothing."}}})");
        assets_detail::mark_paths(info.inputSchema, "write", {"material"});
        registry.add(info, [projectDir](const Json& args) {
            const bool dryRun = tooling_detail::arg_bool(args, "dryRun", false);
            LoadedMaterial m = load_material(projectDir, args, false);
            const std::string param = tooling_detail::arg_string(args, "param", true);
            auto value = args.find("value");
            if (value == args.end())
                throw CommandError(
                    "invalid_argument", "value is missing",
                    "Pass a number, or an array of 2 to 4 numbers for a vec2, vec3, vec4 or color param.");
            auto params = m.doc.find("params");
            std::vector<std::string> names;
            if (params != m.doc.end() && params->is_object())
                for (auto it = params->begin(); it != params->end(); ++it) names.push_back(it.key());
            if (std::find(names.begin(), names.end(), param) == names.end())
                throw CommandError("not_found", m.path + " has no param \"" + param + "\" in its \"params\"",
                                   names.empty() ? "The material declares no params." : did_you_mean(param, names),
                                   Json::object({{"params", Json(names)}}));
            const Json& entry = (*params)[param];
            if (!entry.is_object())
                throw CommandError("invalid_value",
                                   m.path + "/params/" + tooling_detail::escape_token(param) +
                                       ": a param is an object ({\"type\": ..., \"default\": ...}), not " +
                                       std::string(entry.type_name()),
                                   "Write the param as {\"type\":\"float\",\"default\":0.5}, then set its default.",
                                   Json::object({{"pointer", "/params/" + tooling_detail::escape_token(param)}}));
            Json previous = entry.value("default", Json());
            Json patched = m.doc;
            patched["params"][param]["default"] = *value;
            const MaterialParse mp = parse_material(patched, projectDir, m.path);
            const std::string prefix = "/params/" + tooling_detail::escape_token(param);
            for (const MaterialIssue& e : mp.errors)
                if (e.pointer.rfind(prefix, 0) == 0)
                    throw CommandError("invalid_value", m.path + e.pointer + ": " + e.message, e.hint,
                                       Json::object({{"pointer", e.pointer}}));
            const bool changes = previous != *value;
            Json out = Json::object({{"material", m.path},
                                     {"param", param},
                                     {"previous", previous},
                                     {"value", *value},
                                     {"written", !dryRun && changes}});
            if (dryRun || !changes) return out;
            const stdfs::path materialPath = assets_detail::project_write_file(projectDir, m.path);
            std::string err;
            if (!tooling_detail::write_file(materialPath, dump_json(patched, JsonFormat{}) + "\n", &err))
                throw CommandError("failed", "cannot write " + m.path + ": " + err,
                                   "Check that the file is not open elsewhere or read-only. Nothing was changed.");
            return out;
        });
    }
    for (const Section* sec : {&kParams, &kTextures}) add_entry_commands(registry, projectDir, *sec);
    declare_command_capabilities(registry, {{"material.param.create", capability_sets::writes_project()},
                                            {"material.param.rename", capability_sets::writes_project()},
                                            {"material.param.delete", capability_sets::writes_project()},
                                            {"material.texture.create", capability_sets::writes_project()},
                                            {"material.texture.rename", capability_sets::writes_project()},
                                            {"material.texture.delete", capability_sets::writes_project()}});
    declare_command_capabilities(registry, {{"material.graph.nodes", capability_sets::reads()},
                                            {"material.param.set_default", capability_sets::writes_project()},
                                            {"material.graph.validate", capability_sets::reads()},
                                            {"material.graph.generate", capability_sets::writes_project()}});
}

}  // namespace fa
