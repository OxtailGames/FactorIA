// model.info, model.create, model.edit and model.bake: model documents (`*.model.json`, docs/MODELING.md) as project files. The format, the
// kernel and the evaluator are fa_scene's (fa/scene/model_doc.h); baking and its recipe are model_doc_bake.cpp.
#include <algorithm>
#include <cmath>
#include <format>
#include <set>

#include "assets_internal.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/strings.h"
#include "fa/tooling/model_bake.h"
#include "fa/tooling/project_fs.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

double round_to(double v, int decimals) {
    const double k = std::pow(10.0, decimals);
    return std::round(v * k) / k;
}

Json obj(std::initializer_list<std::pair<const char*, Json>> props) {
    Json p = Json::object();
    for (const auto& [k, v] : props) p[k] = v;
    return p;
}
Json str(const char* what) { return Json::object({{"type", "string"}, {"description", what}}); }
Json boolean(const char* what, bool def) { return Json::object({{"type", "boolean"}, {"default", def}, {"description", what}}); }
Json object_arg(const char* what) { return Json::object({{"type", "object"}, {"description", what}}); }
Json vec3_json(Vec3 v) { return Json::array({round_to(v.x, 4), round_to(v.y, 4), round_to(v.z, 4)}); }

std::string doc_path(const std::string& arg, const char* what = "path") {
    auto norm = fs::normalize_checked(arg);
    if (!norm.ok() || norm->empty() || !starts_with(*norm, "assets/"))
        fail("invalid_argument", std::string("`") + what + "` '" + arg + "' is not a model document under assets/.", "Model documents live in assets/, e.g. \"assets/models/door.model.json\" (model.create writes one).");
    if (!ends_with(to_lower(*norm), kModelDocSuffix))
        fail("invalid_argument", "'" + *norm + "' does not end in .model.json.", "Name model documents <name>.model.json, e.g. \"assets/models/door.model.json\".");
    return *norm;
}

Json issues_json(const std::vector<ModelIssue>& issues) {
    Json list = Json::array();
    for (const ModelIssue& i : issues) list.push_back(Json::object({{"pointer", i.pointer}, {"message", i.message}, {"hint", i.hint}}));
    return list;
}

struct Loaded {
    std::string rel;
    Json json;
    ModelDoc doc;
};

[[noreturn]] void invalid_document(const std::string& rel, const Error& error, const std::vector<ModelIssue>& issues) {
    throw CommandError("invalid_document", error.message, error.hint.empty() ? "schemas/model.schema.json describes the format; model.info {} lists the operations." : error.hint,
                       Json::object({{"path", rel}, {"issues", issues_json(issues)}}));
}

Json read_json_file(const std::string& projectDir, const std::string& rel) {
    auto text = tooling_detail::read_file(project_file(projectDir, rel));
    if (!text) {
        const std::vector<std::string> all = list_model_documents(projectDir);
        fail("not_found", "'" + rel + "' does not exist.", all.empty() ? "Make one with model.create {\"path\":\"" + rel + "\"}." : did_you_mean(rel, all) + " Model documents: " + join(all, ", ") + ".");
    }
    auto json = parse_json(*text, rel);
    if (!json.ok()) fail("invalid_document", json.error().message, json.error().hint.empty() ? "Fix the JSON syntax; schemas/model.schema.json describes the format." : json.error().hint);
    return std::move(*json);
}

Loaded load_document(const std::string& projectDir, const std::string& rel) {
    Loaded out;
    out.rel = rel;
    out.json = read_json_file(projectDir, rel);
    std::vector<ModelIssue> issues;
    auto doc = parse_model_doc(out.json, rel, &issues);
    if (!doc.ok()) invalid_document(rel, doc.error(), issues);
    out.doc = std::move(*doc);
    return out;
}

// The document as the arguments give it: a file (`path`) or an inline `document` to check before writing.
Loaded document_arg(const char* command, const std::string& projectDir, const Json& a, bool& inlineDoc) {
    inlineDoc = false;
    const bool hasPath = a.contains("path"), hasDoc = a.contains("document");
    if (hasPath == hasDoc)
        fail("invalid_argument", std::string(command) + (hasPath ? ": give `path` or `document`, not both." : ": give `path` (a .model.json file) or `document` (the JSON itself)."), "Example: {\"path\":\"assets/models/door.model.json\"}.");
    if (hasPath) return load_document(projectDir, doc_path(tooling_detail::arg_string(a, "path", true)));
    Loaded out;
    if (!a["document"].is_object())
        fail("invalid_argument", std::string(command) + ": `document` must be an object.", "Start from {\"format\":\"factoria.model/1\",\"nodes\":[{\"op\":\"box\"}]}.");
    out.json = a["document"];
    if (!out.json.contains("format")) out.json["format"] = kModelDocFormat;
    std::vector<ModelIssue> issues;
    auto doc = parse_model_doc(out.json, "document", &issues);
    if (!doc.ok()) invalid_document("", doc.error(), issues);
    out.doc = std::move(*doc);
    inlineDoc = true;
    return out;
}

Json bake_json(const ModelBakeStatus& s) { return Json::object({{"state", model_bake_state_name(s.state)}, {"output", s.output}, {"reason", s.reason}}); }

// What an evaluation measured.
Json build_json(const ModelBuild& b) {
    Json parts = Json::array();
    for (const ModelPartInfo& p : b.parts) {
        Json item = Json::object({{"part", p.part}, {"material", p.material}, {"triangles", p.triangles}, {"min", vec3_json(p.bmin)}, {"max", vec3_json(p.bmax)}});
        parts.push_back(item);
    }
    const ModelMeshStats& s = b.stats;
    Json out = Json::object({{"vertices", s.vertices},
                             {"triangles", s.triangles},
                             {"bounds", Json::object({{"min", vec3_json(s.bmin)}, {"max", vec3_json(s.bmax)}, {"size", vec3_json(s.bmax - s.bmin)}})},
                             {"closed", s.closed()},
                             {"boundaryEdges", s.boundaryEdges},
                             {"nonManifoldEdges", s.nonManifoldEdges},
                             {"degenerateTriangles", s.degenerateTriangles},
                             {"volume", round_to(s.volume, 4)},
                             {"area", round_to(s.area, 4)},
                             {"parts", parts}});
    if (b.uv) out["uv"] = model_uv_report_json(*b.uv);
    if (!b.warnings.empty()) out["warnings"] = b.warnings;
    return out;
}

// The tree as a compact outline: one entry per node with its pointer, op, id, part and material.
Json tree_json(const std::vector<ModelNode>& nodes) {
    Json list = Json::array();
    for (const ModelNode& n : nodes) {
        Json item = Json::object({{"pointer", n.pointer}, {"op", n.op}});
        if (!n.id.empty()) item["id"] = n.id;
        if (!n.enabled) item["enabled"] = false;
        if (n.part) item["part"] = *n.part;
        if (n.material) item["material"] = *n.material;
        if (!n.children.empty()) item["children"] = tree_json(n.children);
        list.push_back(item);
    }
    return list;
}

std::size_t count_nodes(const std::vector<ModelNode>& nodes) {
    std::size_t n = nodes.size();
    for (const ModelNode& c : nodes) n += count_nodes(c.children);
    return n;
}

Json field_json(const ModelFieldInfo& f) {
    Json item = Json::object({{"key", f.key}, {"type", f.type}, {"doc", f.doc}});
    if (f.required) item["required"] = true;
    if (f.min) item["min"] = *f.min;
    if (f.max) item["max"] = *f.max;
    if (f.def) item["default"] = *f.def;
    if (!f.choices.empty()) item["choices"] = f.choices;
    if (f.minItems) item["minItems"] = *f.minItems;
    if (f.maxItems) item["maxItems"] = *f.maxItems;
    if (f.innerMinItems) item["innerMinItems"] = *f.innerMinItems;
    if (f.innerMaxItems) item["innerMaxItems"] = *f.innerMaxItems;
    return item;
}

Json op_catalog() {
    Json list = Json::array();
    for (const ModelOpInfo& op : model_ops()) {
        Json fields = Json::array();
        for (const ModelFieldInfo& f : op.fields) fields.push_back(field_json(f));
        list.push_back(Json::object({{"op", op.op}, {"kind", op.kind}, {"doc", op.doc}, {"fields", fields}}));
    }
    return list;
}

Json common_catalog() {
    Json list = Json::array();
    for (const ModelFieldInfo& f : model_common_fields()) list.push_back(field_json(f));
    for (const ModelFieldInfo& f : model_align_fields()) {
        Json item = field_json(f);
        item["doc"] = f.doc + " Primitives only.";
        list.push_back(item);
    }
    return list;
}

// Evaluates a loaded document, turning an error into a command failure.
ModelBuild evaluate_or_fail(const std::string& projectDir, const ModelDoc& doc, const std::string& rel) {
    ProjectRootGuard root(projectDir);
    auto build = evaluate_model(doc, model_project_eval_options(projectDir));
    if (!build.ok()) fail("failed", (rel.empty() ? std::string() : rel + ": ") + build.error().message, build.error().hint);
    return std::move(*build);
}

// ---- model.info ----

Json model_info_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("model.info", a, "", {"path", "document", "evaluate"});
    if (!a.contains("path") && !a.contains("document")) {
        return Json::object(
            {{"operations", op_catalog()},
             {"commonFields", common_catalog()},
             {"document", Json::object({{"format", kModelDocFormat}, {"fields", Json::array({"format", "doc", "output", "materials", "uv", "nodes"})}, {"maxNodes", kModelDocMaxNodes}, {"maxDepth", kModelDocMaxDepth}})},
             {"nextSteps", Json::array({"model.create {\"path\":\"assets/models/crate.model.json\",\"nodes\":[{\"op\":\"rounded_box\",\"size\":[1,1,1],\"radius\":0.08,\"part\":\"body\"}]} writes a document and bakes it to a .glb.",
                                        "model.info {\"path\":...} checks a document and measures what it builds."})}});
    }
    bool inlineDoc = false;
    Loaded loaded;
    try {
        loaded = document_arg("model.info", projectDir, a, inlineDoc);
    } catch (const CommandError& e) {
        if (e.code != "invalid_document") throw;
        Json r = Json::object({{"valid", false}, {"issues", e.data.value("issues", Json::array())}});
        if (e.data.contains("path") && !e.data["path"].get<std::string>().empty()) r["path"] = e.data["path"];
        r["nextSteps"] = Json::array({"Fix every issue (each has its JSON pointer and a hint), then call model.info again. model.info {} lists the operations and their fields."});
        return r;
    }
    Json result = Json::object({{"valid", true}});
    if (!inlineDoc) result["path"] = loaded.rel;
    result["output"] = model_document_output(loaded.doc, loaded.rel.empty() ? "document.model.json" : loaded.rel);
    result["nodeCount"] = count_nodes(loaded.doc.nodes);
    result["tree"] = tree_json(loaded.doc.nodes);
    Json materials = Json::array();
    for (const auto& [name, m] : loaded.doc.materials) materials.push_back(name);
    result["materials"] = materials;
    if (!inlineDoc) result["bake"] = bake_json(model_bake_status(projectDir, loaded.rel));
    if (tooling_detail::arg_bool(a, "evaluate", true)) {
        const ModelBuild build = evaluate_or_fail(projectDir, loaded.doc, loaded.rel);
        result["measurements"] = build_json(build);
        Json inputs = Json::array();
        for (const std::string& i : build.inputs) inputs.push_back(i);
        result["inputs"] = inputs;
    }
    result["nextSteps"] = Json::array({"model.edit adds, changes, moves or removes a node by its id; model.bake writes the .glb (" + result["output"].get<std::string>() + ")."});
    return result;
}

// ---- model.bake ----

Json baked_item(const ModelBakeResult& b, const std::string& reason) {
    Json item = Json::object({{"document", b.document}, {"out", b.output}, {"reason", reason}, {"bytes", b.bytes}});
    if (b.written) item["measurements"] = build_json(b.build);
    return item;
}

Json model_bake_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("model.bake", a, "", {"path", "force", "dryRun", "overwrite"});
    const bool force = tooling_detail::arg_bool(a, "force", false), dryRun = tooling_detail::arg_bool(a, "dryRun", false), overwrite = tooling_detail::arg_bool(a, "overwrite", false);
    std::vector<std::string> docs;
    const bool single = a.contains("path");
    if (single) docs.push_back(doc_path(tooling_detail::arg_string(a, "path", true)));
    else docs = list_model_documents(projectDir);
    Json baked = Json::array(), unchanged = Json::array(), failed = Json::array();
    for (const std::string& rel : docs) {
        const ModelBakeStatus status = model_bake_status(projectDir, rel);
        std::string reason = model_bake_state_name(status.state);
        if (status.state == ModelBakeState::Fresh) {
            if (!force && !single) {
                unchanged.push_back(status.output);
                continue;
            }
            reason = "forced";
        }
        if (status.state == ModelBakeState::Broken) {
            if (single) {
                std::vector<ModelIssue> issues;
                {
                    ProjectRootGuard root(projectDir);
                    (void)load_model_doc(rel, &issues);
                }
                throw CommandError("invalid_document", status.reason, status.hint, Json::object({{"path", rel}, {"issues", issues_json(issues)}}));
            }
            failed.push_back(Json::object({{"document", rel}, {"error", Json::object({{"message", status.reason}, {"hint", status.hint}})}}));
            continue;
        }
        if (dryRun) {
            baked.push_back(Json::object({{"document", rel}, {"out", status.output}, {"reason", reason}}));
            continue;
        }
        // `overwrite` is for one named document: a project-wide bake never replaces a file nothing made.
        auto b = bake_model_document(projectDir, rel, {false, overwrite});
        if (!b.ok()) {
            if (single) fail("failed", b.error().message, b.error().hint);
            failed.push_back(Json::object({{"document", rel}, {"out", status.output}, {"error", Json::object({{"message", b.error().message}, {"hint", b.error().hint}})}}));
            continue;
        }
        baked.push_back(baked_item(*b, reason));
    }
    Json result = Json::object({{dryRun ? "wouldBake" : "baked", baked}, {"count", baked.size()}, {"unchanged", unchanged}});
    if (dryRun) result["dryRun"] = true;
    if (!failed.empty()) result["failed"] = failed;
    Json steps = Json::array();
    if (docs.empty()) steps.push_back("There are no model documents yet: model.create {\"path\":\"assets/models/crate.model.json\"} writes one.");
    if (!failed.empty()) steps.push_back("Fix the documents in `failed` (model.info {\"path\":...} lists every issue with its JSON pointer) and call model.bake again.");
    if (!baked.empty() && !dryRun) steps.push_back("Use a baked model as the `mesh` of a MeshRenderer: its parts are the submeshes of the .glb (named in each primitive's extras.part).");
    result["nextSteps"] = steps;
    return result;
}

// ---- model.create and model.edit ----

void write_document(const std::string& projectDir, const std::string& rel, const Json& json) {
    std::string err;
    if (!tooling_detail::write_file(project_file(projectDir, rel), dump_json(json), &err)) fail("failed", "Cannot write '" + rel + "': " + err, "Check that the folder is writable.");
}

// Checks the whole document; throws invalid_document with every issue (and writes nothing).
void checked(const Json& json, const std::string& rel) {
    std::vector<ModelIssue> issues;
    auto doc = parse_model_doc(json, rel, &issues);
    if (!doc.ok()) {
        Error e = doc.error();
        e.message += " Nothing was written.";
        invalid_document(rel, e, issues);
    }
}

void collect_used_ids(const Json& nodes, std::set<std::string>& used) {
    if (!nodes.is_array()) return;
    for (const Json& n : nodes) {
        if (!n.is_object()) continue;
        if (n.contains("id") && n["id"].is_string()) used.insert(n["id"].get<std::string>());
        if (n.contains("children")) collect_used_ids(n["children"], used);
    }
}

// Gives every node without an id one ("box_1", "box_2"...), unique in the document, so that model.edit can address it later.
void assign_ids(Json& nodes, std::set<std::string>& used) {
    if (!nodes.is_array()) return;
    for (Json& n : nodes) {
        if (!n.is_object()) continue;
        if (!n.contains("id") && n.contains("op") && n["op"].is_string()) {
            const std::string op = n["op"].get<std::string>();
            for (int k = 1;; ++k) {
                const std::string id = op + "_" + std::to_string(k);
                if (used.insert(id).second) {
                    n["id"] = id;
                    break;
                }
            }
        }
        if (n.contains("children")) assign_ids(n["children"], used);
    }
}

Json written_result(const std::string& projectDir, const std::string& rel, const Json& json, bool bake, const Json& a) {
    const ModelDoc doc = *parse_model_doc(json, rel);
    Json result = Json::object({{"path", rel}, {"output", model_document_output(doc, rel)}, {"nodeCount", count_nodes(doc.nodes)}, {"tree", tree_json(doc.nodes)}});
    if (bake) {
        auto b = bake_model_document(projectDir, rel, {false, tooling_detail::arg_bool(a, "overwrite", false)});
        if (!b.ok()) {
            result["bake"] = Json::object({{"state", "failed"}, {"message", b.error().message}, {"hint", b.error().hint}});
            result["nextSteps"] = Json::array({"The document was written but could not be baked: " + b.error().message + " " + b.error().hint});
            return result;
        }
        result["bytes"] = b->bytes;
        result["measurements"] = build_json(b->build);
        result["provenance"] = b->provenance;
    } else {
        result["bake"] = bake_json(model_bake_status(projectDir, rel));
    }
    result["nextSteps"] = Json::array({"model.info {\"path\":\"" + rel + "\"} measures the model; model.edit changes one node by its id; the baked .glb is rebuilt by model.bake or factoria export."});
    return result;
}

Json model_create_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("model.create", a, "", {"path", "nodes", "materials", "uv", "output", "doc", "overwrite", "bake"});
    const std::string rel = doc_path(tooling_detail::arg_string(a, "path", true));
    std::error_code ec;
    if (!tooling_detail::arg_bool(a, "overwrite", false) && stdfs::exists(project_file(projectDir, rel), ec))
        fail("exists", "'" + rel + "' already exists.", "Pass overwrite: true to replace it, or change its nodes with model.edit.");
    Json json = Json::object({{"format", kModelDocFormat}});
    if (a.contains("doc")) json["doc"] = a["doc"];
    if (a.contains("output")) json["output"] = a["output"];
    if (a.contains("materials")) json["materials"] = a["materials"];
    if (a.contains("uv")) json["uv"] = a["uv"];
    json["nodes"] = a.contains("nodes") ? a["nodes"] : Json::array({Json::object({{"op", "box"}, {"size", Json::array({1, 1, 1})}})});
    std::set<std::string> used;
    collect_used_ids(json["nodes"], used);
    assign_ids(json["nodes"], used);
    checked(json, rel);
    require_usable_manifest(projectDir);
    write_document(projectDir, rel, json);
    return written_result(projectDir, rel, json, tooling_detail::arg_bool(a, "bake", true), a);
}

// True for the operations that hold `children`: groups and modifiers.
bool holds_children(const std::string& op) {
    for (const ModelOpInfo& o : model_ops())
        if (o.op == op) return o.kind == "group" || o.kind == "modifier" || o.kind == "sdf" || o.kind == "sdf_group";
    return false;
}

// The array a node list lives in: the document's `nodes` (ref empty), or the `children` of the group or modifier `ref`.
Json& list_of(Json& json, const std::string& ref, const char* what, std::string* pointer) {
    if (ref.empty()) {
        if (pointer) *pointer = "/nodes";
        return json["nodes"];
    }
    std::string at, why;
    Json* node = find_model_node(json, ref, &at, &why);
    if (!node) fail("not_found", std::string("model.edit: `") + what + "` '" + ref + "': " + why, "Nodes are named by their id (model.info lists them) or by a JSON pointer such as /nodes/0.");
    if (!holds_children(node->value("op", std::string())))
        fail("invalid_argument", std::string("model.edit: `") + what + "` '" + ref + "' is a " + node->value("op", std::string("node")) + ", not a group or a modifier: only those have children.", "Name a group or a modifier (boolean, mirror, array...), or leave it out to use the top level.");
    if (!node->contains("children") || !(*node)["children"].is_array()) (*node)["children"] = Json::array();
    if (pointer) *pointer = at + "/children";
    return (*node)["children"];
}

// Removes the node tagged with `tag` (anywhere in the tree). True when found.
bool erase_tagged(Json& nodes, const char* tag) {
    if (!nodes.is_array()) return false;
    for (std::size_t i = 0; i < nodes.size(); ++i) {
        if (nodes[i].is_object() && nodes[i].contains(tag)) {
            nodes.erase(nodes.begin() + static_cast<std::ptrdiff_t>(i));
            return true;
        }
        if (nodes[i].is_object() && nodes[i].contains("children") && erase_tagged(nodes[i]["children"], tag)) return true;
    }
    return false;
}

Json model_edit_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("model.edit", a, "", {"path", "op", "target", "node", "parent", "index", "values", "bake", "overwrite", "doc", "output", "materials", "uv"});
    const std::string rel = doc_path(tooling_detail::arg_string(a, "path", true));
    const std::string op = tooling_detail::arg_string(a, "op", false, "");
    const std::vector<std::string> ops = {"add", "set", "remove", "move", "document"};
    if (std::find(ops.begin(), ops.end(), op) == ops.end())
        fail("invalid_argument", "model.edit: `op` must be one of " + join(ops, ", ") + (op.empty() ? "." : ", got '" + op + "'. " + did_you_mean(op, ops)),
             "add inserts `node` into `parent` (a group or modifier id or pointer; default the top level) at `index` (default the end); set changes fields of `target` with `values` (a null value removes a field); remove deletes `target`; move takes `target` to `parent` at `index`; document changes `doc`, `output` or `materials`. A node is named by its id or a JSON pointer.");
    Json json = read_json_file(projectDir, rel);
    if (!json.is_object()) fail("invalid_document", rel + ": the document is not an object.", "Fix it by hand or write it again with model.create overwrite: true.");
    if (!json.contains("nodes") || !json["nodes"].is_array()) json["nodes"] = Json::array();
    const std::string target = tooling_detail::arg_string(a, "target", false, "");
    const std::string parent = tooling_detail::arg_string(a, "parent", false, "");
    auto need_target = [&]() -> Json& {
        if (target.empty()) fail("invalid_argument", "model.edit " + op + ": `target` (the node's id or JSON pointer) is required.", "model.info {\"path\":\"" + rel + "\"} lists the nodes with their ids and pointers.");
        std::string at, why;
        Json* node = find_model_node(json, target, &at, &why);
        if (!node) fail("not_found", "model.edit " + op + ": `target` '" + target + "': " + why, "Nodes are named by their id or by a JSON pointer such as /nodes/0.");
        return *node;
    };
    auto index_in = [&](const Json& list, bool allowEnd) -> std::size_t {
        if (!a.contains("index")) return list.size();
        if (!a["index"].is_number_integer()) fail("invalid_argument", "model.edit " + op + ": `index` must be a whole number.", "Positions count from 0 in the list the node goes into.");
        const long long i = a["index"].get<long long>();
        const long long max = static_cast<long long>(list.size()) - (allowEnd ? 0 : 1);
        if (i < 0 || i > max)
            fail("invalid_argument", "model.edit " + op + ": `index` " + std::to_string(i) + " is outside the " + std::to_string(list.size()) + " node" + (list.size() == 1 ? "" : "s") + " of that list.", "Use 0 to " + std::to_string(std::max<long long>(max, 0)) + ", or leave `index` out for the end.");
        return static_cast<std::size_t>(i);
    };
    Json what = Json::object({{"op", op}});
    std::set<std::string> used;
    if (op == "add") {
        if (!a.contains("node") || !a["node"].is_object())
            fail("invalid_argument", "model.edit add: `node` must be an object such as {\"op\":\"cylinder\",\"radius\":0.2,\"position\":[0,1,0]}.", "model.info {} lists the operations and their fields.");
        Json node = a["node"];
        collect_used_ids(json["nodes"], used);
        Json wrapper = Json::array({node});
        assign_ids(wrapper, used);
        node = wrapper[0];
        std::string listPointer;
        Json& list = list_of(json, parent, "parent", &listPointer);
        const std::size_t at = index_in(list, true);
        list.insert(list.begin() + static_cast<std::ptrdiff_t>(at), node);
        what["pointer"] = listPointer + "/" + std::to_string(at);
        if (node.contains("id")) what["id"] = node["id"];
    } else if (op == "set") {
        Json& node = need_target();
        if (!a.contains("values") || !a["values"].is_object() || a["values"].empty())
            fail("invalid_argument", "model.edit set: `values` must say what to change, e.g. {\"radius\": 0.3}.", "A null value removes the field (back to its default). The node's op cannot be changed: remove it and add another.");
        if (a["values"].contains("op") && a["values"]["op"] != node.value("op", Json()))
            fail("invalid_argument", "model.edit set: the op of a node cannot be changed.", "Remove the node and add the one you want at the same index.");
        for (auto it = a["values"].begin(); it != a["values"].end(); ++it) {
            if (it.value().is_null()) node.erase(it.key());
            else node[it.key()] = it.value();
        }
        what["target"] = target;
    } else if (op == "remove") {
        Json& node = need_target();
        what["removed"] = node.value("op", std::string());
        constexpr const char* tag = "__removing";
        node[tag] = true;
        erase_tagged(json["nodes"], tag);
        what["target"] = target;
    } else if (op == "move") {
        Json& node = need_target();
        std::string at, why;
        find_model_node(json, target, &at, &why);
        if (!parent.empty()) {
            std::string parentAt;
            find_model_node(json, parent, &parentAt, &why);
            if (!parentAt.empty() && (parentAt == at || starts_with(parentAt, at + "/")))
                fail("invalid_argument", "model.edit move: '" + target + "' cannot move into itself.", "Pick a group or modifier that is not inside the node you are moving.");
        }
        constexpr const char* tag = "__moving";
        Json copy = node;
        node[tag] = true;
        std::string listPointer;
        Json& list = list_of(json, parent, "parent", &listPointer);
        const std::size_t position = index_in(list, true);
        list.insert(list.begin() + static_cast<std::ptrdiff_t>(position), copy);
        erase_tagged(json["nodes"], tag);
        what["target"] = target;
        what["parent"] = parent;
    } else {
        bool any = false;
        for (const char* key : {"doc", "output", "materials", "uv"})
            if (a.contains(key)) {
                if (a[key].is_null()) json.erase(key);
                else json[key] = a[key];
                any = true;
            }
        if (!any) fail("invalid_argument", "model.edit document: give `doc`, `output`, `materials` or `uv`.", "Example: {\"op\":\"document\",\"materials\":{\"wood\":{\"color\":[0.6,0.4,0.2,1]}}}. `materials` replaces the whole table; send the ones to keep too. `uv` replaces the whole uv section (null removes it); model.uv merges single fields.");
    }
    checked(json, rel);
    require_usable_manifest(projectDir);
    write_document(projectDir, rel, json);
    Json result = written_result(projectDir, rel, json, tooling_detail::arg_bool(a, "bake", true), a);
    result["edit"] = what;
    return result;
}

}  // namespace

void register_model_commands(CommandRegistry& registry, const std::string& projectDir) {
    auto pathArg = [] { return str("The model document, project-relative, under assets/, ending in .model.json."); };
    {
        CommandInfo info;
        info.name = "model.info";
        info.category = "assets";
        info.readOnly = true;
        info.summary = "Check a model document and measure what it builds; with no arguments, list the operations (primitives, modifiers, group) and their fields.";
        info.description =
            "A model document (`*.model.json`, docs/MODELING.md) is a 3D model written as a tree of operations: primitives (box, rounded_box, cylinder, cone, sphere, capsule, torus, grid, stairs, arch, pipe, text, lathe, sweep, loft), groups, "
            "modifiers that wrap their children and change the mesh they make (boolean, mirror, array, radial_array, bevel, subdivide, solidify, bend, twist, taper, noise, smooth, weld, shade), "
            "and a transform, a part name, a material and a vertex colour on any node. With `path` (or an inline `document`) this checks it: a document with mistakes returns valid false and ALL its issues, each with the JSON pointer, "
            "what is wrong and the fix; a valid one returns the tree (pointer, op, id, part, material per node), where it bakes to and whether that .glb is fresh or stale, and (unless evaluate is false) builds it in memory: "
            "vertices, triangles, bounds and size in metres, whether the surface is closed, volume, and the triangles and bounds of every part. With no argument it returns the catalog of operations with every field, its range, "
            "default and doc string. Example: {\"path\":\"assets/models/door.model.json\"}";
        info.inputSchema = Json::object({{"type", "object"}, {"additionalProperties", false},
                                         {"properties", obj({{"path", pathArg()}, {"document", object_arg("The document itself, as JSON, to check before writing it to a file (format is filled in).")},
                                                             {"evaluate", boolean("Build the mesh in memory for the measurements. Turn it off to only check the document.", true)}})}});
        registry.add(info, [projectDir](const Json& args) { return model_info_command(projectDir, args.is_null() ? Json::object() : args); });
    }
    {
        CommandInfo info;
        info.name = "model.bake";
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Build model documents into .glb files next to them (only the missing or stale ones unless forced), with their recipe in assets.json.";
        info.description =
            "Without `path` this bakes every *.model.json of the project whose .glb is missing or out of date (its document or a file it reads changed: the recipe's hashes), like audio.bake. With `path` it bakes that document. "
            "The .glb goes to `output.path` of the document, else next to it as <name>.glb, written the way mesh.save writes a mesh (one primitive per part and material, the part name in the primitive's extras, vertex colours as COLOR_0); "
            "the same document gives the same bytes. assets.json records provenance (a CC0 license, or the licenses of the fonts and textures it read) and the recipe, so assets.regenerate and project.validate know when it is stale. "
            "A file that nothing baked is never replaced unless overwrite is true. `factoria export` bakes the stale documents first. Example: {} or {\"path\":\"assets/models/door.model.json\"}";
        info.inputSchema = Json::object({{"type", "object"}, {"additionalProperties", false},
                                         {"properties", obj({{"path", str("Bake only this document (project-relative, ending in .model.json). Leave out for every document.")},
                                                             {"force", boolean("Bake documents that are fresh too.", false)},
                                                             {"dryRun", boolean("List what would be baked and why, and write nothing.", false)},
                                                             {"overwrite", boolean("Replace a file at the output that no model document baked.", false)}})}});
        registry.add(info, [projectDir](const Json& args) { return model_bake_command(projectDir, args.is_null() ? Json::object() : args); });
    }
    {
        CommandInfo info;
        info.name = "model.create";
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Write a new model document (a tree of primitives, modifiers, groups and transforms) and bake it to a .glb.";
        info.description =
            "Writes `path` (*.model.json under assets/) with the format, the `nodes` (a list of node objects; model.info {} lists the operations and fields; left out: one box named box_1 to start from), "
            "the optional `materials` ({name: {color, texture, metallic, roughness, emissive, doubleSided, blend}}), `output` ({path: where the .glb goes}) and `doc` note. Nodes without an `id` get one (box_1, cylinder_2...), so model.edit "
            "can address them later. The document is checked first: a mistake returns every issue (JSON pointer, what is wrong, how to fix it) and writes nothing. Then it is baked (unless bake is false) and the result holds "
            "the measurements. Example: {\"path\":\"assets/models/door.model.json\",\"materials\":{\"wood\":{\"color\":[0.55,0.35,0.2,1]},\"brass\":{\"color\":[0.8,0.65,0.3,1],\"metallic\":1}},"
            "\"nodes\":[{\"op\":\"box\",\"id\":\"panel\",\"size\":[1,2,0.08],\"part\":\"door\",\"material\":\"wood\"},{\"op\":\"sphere\",\"id\":\"knob\",\"radius\":0.05,\"position\":[0.4,0,0.07],\"part\":\"knob\",\"material\":\"brass\"}]}";
        info.inputSchema = Json::object({{"type", "object"}, {"required", Json::array({"path"})}, {"additionalProperties", false},
                                         {"properties", obj({{"path", pathArg()},
                                                             {"nodes", Json::object({{"type", "array"}, {"items", Json::object({{"type", "object"}})}, {"description", "The tree, in order. Each node is {\"op\": ..., fields}; groups and modifiers hold `children`."}})},
                                                             {"materials", object_arg("Named materials the nodes refer to with `material`: {name: {color, texture, metallic, roughness, emissive, doubleSided, blend}}.")},
                                                             {"uv", object_arg("The uv section: how the model gets its UVs ({method, layout, texelsPerUnit, ...}; docs/MODELING.md, \"UVs\"). model.uv changes it field by field.")},
                                                             {"output", object_arg("{path: where to bake, under assets/, ending in .glb}.")},
                                                             {"doc", str("A note on what the model is for.")},
                                                             {"overwrite", boolean("Replace the document when it exists (and the .glb when nothing baked it).", false)},
                                                             {"bake", boolean("Bake the .glb after writing.", true)}})}});
        registry.add(info, [projectDir](const Json& args) { return model_create_command(projectDir, args.is_null() ? Json::object() : args); });
    }
    {
        CommandInfo info;
        info.name = "model.edit";
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Add, change, remove or move one node of a model document by its id (or JSON pointer), or change its materials, output or note; then bake it.";
        info.description =
            "`op` is one of: add (insert `node`, an object, into the group or modifier `parent` at `index`, default the end of the top level; a node without an id gets one), set (change the fields of `target` with `values`; a null value removes a field, "
            "back to its default), remove (delete `target` and everything below it), move (take `target` to the group or modifier `parent`, or the top level, at `index`), document (change `materials`, `output` or `doc`; `materials` replaces the whole table). "
            "`target` and `parent` are a node id (stable when the tree changes) or a JSON pointer such as /nodes/1/children/0. The result document is checked as a whole before anything is written, so a bad value returns every issue with its "
            "JSON pointer and writes nothing; the file keeps the other nodes as written. Then the .glb is baked again (unless bake is false) and the measurements tell what the edit did. "
            "Example: {\"path\":\"assets/models/door.model.json\",\"op\":\"set\",\"target\":\"knob\",\"values\":{\"radius\":0.07}}";
        info.inputSchema = Json::object({{"type", "object"}, {"required", Json::array({"path", "op"})}, {"additionalProperties", false},
                                         {"properties", obj({{"path", pathArg()},
                                                             {"op", Json::object({{"type", "string"}, {"enum", Json::array({"add", "set", "remove", "move", "document"})}, {"description", "What to do."}})},
                                                             {"target", str("set, remove, move: the node to act on, by id or JSON pointer.")},
                                                             {"node", object_arg("add: the new node, {\"op\": ..., fields}.")},
                                                             {"parent", str("add, move: the group or modifier to put the node in, by id or JSON pointer. Left out: the top level.")},
                                                             {"index", Json::object({{"type", "integer"}, {"minimum", 0}, {"description", "add, move: the position in the list the node goes into. Left out: the end."}})},
                                                             {"values", object_arg("set: fields to change; null removes a field.")},
                                                             {"doc", str("document: the new note.")},
                                                             {"output", object_arg("document: the new output settings ({path}); null removes them.")},
                                                             {"materials", object_arg("document: the new materials table; null removes it.")},
                                                             {"uv", Json::object({{"type", Json::array({"object", "null"})}, {"description", "document: the new uv section, whole; null removes it. model.uv changes single fields."}})},
                                                             {"bake", boolean("Bake the .glb after writing.", true)},
                                                             {"overwrite", boolean("Replace a .glb that no model document baked.", false)}})}});
        registry.add(info, [projectDir](const Json& args) { return model_edit_command(projectDir, args.is_null() ? Json::object() : args); });
    }
    register_model_uv_command(registry, projectDir);
}

}  // namespace fa::assets_detail
