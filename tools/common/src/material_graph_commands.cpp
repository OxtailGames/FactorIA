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
    declare_command_capabilities(registry, {{"material.graph.nodes", capability_sets::reads()},
                                            {"material.param.set_default", capability_sets::writes_project()},
                                            {"material.graph.validate", capability_sets::reads()},
                                            {"material.graph.generate", capability_sets::writes_project()}});
}

}  // namespace fa
