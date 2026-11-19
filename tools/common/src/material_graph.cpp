// Checking the graph of a material and generating its snippet (fa/tooling/material_graph.h). The checks come first and say where
// (a JSON pointer into the material file), what is wrong and how to fix it; a graph that passes them always generates GLSL.
#include <algorithm>
#include <cctype>
#include <cmath>
#include <functional>
#include <map>
#include <set>

#include "fa/core/hash.h"
#include "fa/core/strings.h"
#include "fa/tooling/material_graph.h"
#include "material_graph_internal.h"
#include "shaders_internal.h"
#include "util.h"

namespace fa {

using tooling_detail::escape_token;

namespace {

using graph_detail::Helper;

int comps_of(const std::string& type) {
    if (type == "float") return 1;
    if (type == "vec2") return 2;
    if (type == "vec3") return 3;
    if (type == "vec4") return 4;
    return 0;
}

std::string vec_type(int comps) { return comps <= 1 ? "float" : "vec" + std::to_string(comps); }

// The values of the surface a default can name ("$uv"): their size, and whether they exist in vertex().
struct SurfaceValue {
    const char* name;
    int comps;
    const char* fragment;
    const char* vertex;  // nullptr: not in vertex()
};
const SurfaceValue kSurfaceValues[] = {
    {"uv", 2, "i.uv", "v.uv"},
    {"world_pos", 3, "i.world_pos", "v.world_pos"},
    {"world_normal", 3, "i.world_normal", "v.world_normal"},
    {"world_tangent", 4, "i.world_tangent", "v.world_tangent"},
    {"vertex_color", 4, "i.vertex_color", "v.color"},
    {"view_dir", 3, "i.view_dir", nullptr},
    {"camera_pos", 3, "fa_camera_pos.xyz", nullptr},
    {"time", 1, "fa_time.x", "fa_time.x"},
};

// The same for a sprite material (QuadInput, QuadSurface and QuadVertex of the sprite template). "sprite_color" is what the engine drew
// before fragment() ran (QuadSurface.color on arrival); the output node writes it last, so a node reads it before it is replaced.
const SurfaceValue kSpriteSurfaceValues[] = {
    {"uv", 2, "i.uv", "v.uv"},
    {"time", 1, "fa_time.x", "fa_time.x"},
    {"tint", 4, "i.color", "v.color"},
    {"sprite_color", 4, "s.color", nullptr},
    {"life", 1, "i.life", nullptr},
    {"custom", 4, "i.custom", nullptr},
    {"sprite_pos", 2, "i.world_pos", nullptr},
    {"screen_uv", 2, "i.screen_uv", nullptr},
};

// How the generator writes the snippet of one material kind: the entry points of its template and the surface values its nodes read.
struct KindProfile {
    const char* kind;
    const char* fragmentHeader;  // the line that opens fragment() (surface() in a mesh material)
    const char* vertexHeader;
    const SurfaceValue* values;
    std::size_t valueCount;
};
const KindProfile kProfiles[] = {
    {"mesh", "void surface(in SurfaceInput i, inout Surface s) {\n", "void vertex(inout VertexData v) {\n",
     kSurfaceValues, std::size(kSurfaceValues)},
    {"sprite", "void fragment(in QuadInput i, inout QuadSurface s) {\n", "void vertex(inout QuadVertex v) {\n",
     kSpriteSurfaceValues, std::size(kSpriteSurfaceValues)},
};

const KindProfile& profile_of(const std::string& kind) {
    for (const KindProfile& p : kProfiles)
        if (kind == p.kind) return p;
    return kProfiles[0];  // only reached for a kind the graph check refused already
}

const SurfaceValue* surface_value(const KindProfile& profile, std::string_view name) {
    for (std::size_t i = 0; i < profile.valueCount; ++i)
        if (name == profile.values[i].name) return &profile.values[i];
    return nullptr;
}

// A GLSL float literal of a JSON number: always with a decimal point or an exponent, a negative one in parentheses.
std::string glsl_float(double v) {
    std::string s = Json(v).dump();
    if (s.find_first_of(".eE") == std::string::npos) s += ".0";
    return v < 0 ? "(" + s + ")" : s;
}

std::string glsl_literal(const Json& v, int comps) {
    if (v.is_number()) {
        const std::string f = glsl_float(v.get<double>());
        return comps > 1 ? vec_type(comps) + "(" + f + ")" : f;
    }
    std::string out = vec_type(int(v.size())) + "(";
    for (std::size_t i = 0; i < v.size(); ++i) out += (i ? ", " : "") + glsl_float(v[i].get<double>());
    return out + ")";
}

bool valid_node_id(const std::string& id) {
    if (id.empty() || !std::isalpha(static_cast<unsigned char>(id[0]))) return false;
    if (!std::all_of(id.begin(), id.end(), shaders_detail::ident_char)) return false;
    return id.find("__") == std::string::npos && id.back() != '_';
}

struct Link {
    int index = 0;  // in the JSON array
    int from = -1, fromPort = -1, to = -1, toPort = -1;
};

struct Node {
    int index = 0;
    std::string id;
    const GraphNodeType* type = nullptr;
    const Json* json = nullptr;
    std::string ref;  // the param or texture the node names
    int refComps = 0;
    std::vector<int> inLink;      // per input: index into the links, or -1
    std::vector<int> constComps;  // per input: size of the constant written in "inputs", 0 = none
    int genN = 1;
    std::vector<int> outComps;
    int state = 0;  // 0 new, 1 being resolved, 2 resolved
    bool set(std::size_t port) const { return inLink[port] >= 0 || constComps[port] > 0; }
    // A param or texture node whose param or texture was not found: its own error is reported, and it has no type, so the
    // links that leave it are not checked (they would only repeat the error as a "type mismatch").
    bool failed() const { return type && !type->ref.empty() && ref.empty(); }
};

// What the checks learn and the generator uses.
struct Analysis {
    std::vector<Node> nodes;
    std::vector<Link> links;
    int output = -1;
    std::vector<int> fragmentOrder;  // nodes surface() draws, dependencies first
    std::vector<int> vertexOrder;    // nodes vertex() draws
};

struct Analyser {
    const Json& graph;
    const MaterialDef& material;
    const std::string& kind;
    GraphCheck& check;
    Analysis a;
    std::map<std::string, int> byId;
    std::vector<int> stack;

    void error(std::string pointer, std::string message, std::string hint = {}) {
        check.errors.push_back({std::move(pointer), std::move(message), std::move(hint)});
    }
    void warn(std::string pointer, std::string message, std::string hint = {}) {
        check.warnings.push_back({std::move(pointer), std::move(message), std::move(hint)});
    }

    static std::string node_pointer(int i) { return "/graph/nodes/" + std::to_string(i); }
    static std::string link_pointer(int i) { return "/graph/links/" + std::to_string(i); }

    std::string ids_list() const {
        std::vector<std::string> ids;
        for (const Node& n : a.nodes)
            if (!n.id.empty()) ids.push_back(n.id);
        return join(ids, ", ");
    }
    static std::vector<std::string> port_names(const std::vector<GraphPort>& ports) {
        std::vector<std::string> names;
        for (const GraphPort& p : ports) names.push_back(p.name);
        return names;
    }

    // ---- reading ----

    bool run() {
        if (!graph.is_object()) {
            error("/graph", "expected an object, got " + describe_json_value(graph),
                  "Write \"graph\": {\"nodes\": [{\"id\": \"out\", \"type\": \"output\"}], \"links\": []}. "
                  "`material.graph.nodes` lists the node types.");
            return false;
        }
        static const std::vector<std::string> known = {"version", "nodes", "links", "editor"};
        for (auto it = graph.begin(); it != graph.end(); ++it)
            if (std::find(known.begin(), known.end(), it.key()) == known.end())
                error("/graph/" + escape_token(it.key()), "unknown key \"" + it.key() + "\"",
                      did_you_mean(it.key(), known));
        if (auto v = graph.find("version");
            v != graph.end() && !(v->is_number_integer() && v->get<long long>() == kGraphVersion))
            error("/graph/version",
                  "this build reads graph version " + std::to_string(kGraphVersion) + ", got " +
                      describe_json_value(*v),
                  "Write \"version\": " + std::to_string(kGraphVersion) +
                      " (or leave it out); a newer graph needs a newer FactorIA.");
        check_editor_object(graph, "/graph");
        const auto& supported = graph_supported_kinds();
        if (std::find(supported.begin(), supported.end(), kind) == supported.end())
            error("/kind",
                  "node graphs are generated for materials of kind " + join(supported, ", ") + " only, this one is \"" +
                      kind + "\"",
                  "Remove \"graph\" and write the snippet by hand, or wait for graph support of this kind.");
        read_nodes();
        read_links();
        for (std::size_t i = 0; i < a.nodes.size(); ++i) resolve(int(i));
        check_output();
        check_names();
        order_stages();
        return check.ok();
    }

    // The constant written in "inputs" for `port`: its size, or 0 after an error.
    int read_constant(const Json& v, const GraphPort& port, const std::string& pointer) {
        auto numbers_ok = [&](const Json& x) { return x.is_number() && std::isfinite(x.get<double>()); };
        const std::string example = port.type == "float"  ? "0.5"
                                    : port.type == "vec2" ? "[0.5, 1.0]"
                                    : port.type == "vec3" ? "[1.0, 0.5, 0.0]"
                                    : port.type == "vec4" ? "[1.0, 0.5, 0.0, 1.0]"
                                                          : "0.5 or [0.5, 1.0, 0.0]";
        const std::string what = port.type == "gen" ? "a number or an array of 2 to 4 numbers"
                                 : port.type == "float"
                                     ? "a number"
                                     : "an array of " + std::to_string(comps_of(port.type)) + " numbers";
        if (v.is_number() && numbers_ok(v) && (port.type == "float" || port.type == "gen")) return 1;
        if (v.is_array() && port.type != "float" &&
            (port.type == "gen" ? v.size() >= 2 && v.size() <= 4 : int(v.size()) == comps_of(port.type)) &&
            std::all_of(v.begin(), v.end(), numbers_ok))
            return int(v.size());
        error(pointer,
              "expected " + what + " for input '" + port.name + "' (" + port.type + "), got " + describe_json_value(v),
              "Write it like " + example + ", or link an output into the input.");
        return 0;
    }

    // "editor" (graph and nodes): free-form data of the editor (canvas zoom and pan, collapsed nodes, comments, groups). Nothing
    // reads it but the editor: the snippet does not depend on it, and it only has to be an object.
    void check_editor_object(const Json& j, const std::string& base) {
        auto e = j.find("editor");
        if (e != j.end() && !e->is_object())
            error(base + "/editor", "expected an object, got " + describe_json_value(*e),
                  "\"editor\" is free-form data for the node editor (zoom, pan, comments): write an object, or remove "
                  "it.");
    }

    void read_nodes() {
        auto it = graph.find("nodes");
        if (it == graph.end() || !it->is_array() || it->empty()) {
            error("/graph/nodes",
                  it == graph.end() ? "missing \"nodes\""
                                    : "expected a non-empty array of nodes, got " + describe_json_value(*it),
                  "A graph needs at least the output node: \"nodes\": [{\"id\": \"out\", \"type\": \"output\", "
                  "\"inputs\": "
                  "{\"albedo\": [1, 0, 0]}}].");
            return;
        }
        for (std::size_t i = 0; i < it->size(); ++i) {
            Node n;
            n.index = int(i);
            n.json = &(*it)[i];
            read_node(n);
            a.nodes.push_back(std::move(n));
        }
    }

    void read_node(Node& n) {
        const std::string base = node_pointer(n.index);
        const Json& j = *n.json;
        if (!j.is_object()) {
            error(
                base, "expected an object, got " + describe_json_value(j),
                "Write {\"id\": \"noise1\", \"type\": \"noise.fbm\", \"pos\": [0, 0], \"inputs\": {\"scale\": 6.0}}.");
            return;
        }
        static const std::vector<std::string> known = {"id", "type", "pos", "inputs", "param", "texture", "editor"};
        for (auto it = j.begin(); it != j.end(); ++it)
            if (std::find(known.begin(), known.end(), it.key()) == known.end())
                error(base + "/" + escape_token(it.key()), "unknown key \"" + it.key() + "\"",
                      did_you_mean(it.key(), known));
        // id
        auto idIt = j.find("id");
        if (idIt == j.end() || !idIt->is_string()) {
            error(base + "/id",
                  idIt == j.end() ? "missing \"id\"" : "expected a string, got " + describe_json_value(*idIt),
                  "Every node has an id that links name, e.g. \"id\": \"noise1\".");
        } else {
            const std::string id = idIt->get<std::string>();
            if (!valid_node_id(id)) {
                error(base + "/id",
                      "node id \"" + id +
                          "\" is not usable: it becomes part of a GLSL name, so it starts with a letter, uses letters, "
                          "digits and "
                          "_, has no double or trailing underscore",
                      "Rename it, e.g. \"noise1\".");
            } else if (!byId.emplace(id, n.index).second) {
                error(base + "/id", "node id \"" + id + "\" is used twice", "Ids are unique in a graph: rename one.");
            } else {
                n.id = id;
            }
        }
        check_editor_object(j, base);
        // pos
        if (auto p = j.find("pos"); p != j.end()) {
            if (!p->is_array() || p->size() != 2 || !(*p)[0].is_number() || !(*p)[1].is_number())
                error(base + "/pos", "expected [x, y], got " + describe_json_value(*p),
                      "pos is where the editor draws the node: [x, y] in canvas units. The snippet does not depend on "
                      "it.");
        }
        // type
        auto tIt = j.find("type");
        if (tIt == j.end() || !tIt->is_string()) {
            error(base + "/type",
                  tIt == j.end() ? "missing \"type\"" : "expected a string, got " + describe_json_value(*tIt),
                  "Use one of the node types `material.graph.nodes` lists, e.g. \"noise.fbm\".");
            return;
        }
        const std::string typeName = tIt->get<std::string>();
        n.type = find_graph_node_type(typeName, kind);
        if (!n.type)
            n.type = find_graph_node_type(typeName);  // a node of another kind: refused below, with what to use instead
        if (!n.type) {
            std::vector<std::string> names;
            for (const GraphNodeType& t : graph_node_library()) names.push_back(t.type);
            error(base + "/type", "unknown node type \"" + typeName + "\"",
                  did_you_mean(typeName, names) + " `material.graph.nodes` lists every type.");
            return;
        }
        if (std::find(n.type->kinds.begin(), n.type->kinds.end(), kind) == n.type->kinds.end()) {
            std::string hint = "Use another node (`material.graph.nodes` with kind \"" + kind +
                               "\" lists the ones that work here), or move the material to a kind the node supports.";
            for (const auto& [k, text] : n.type->instead)
                if (k == kind)
                    hint = text + " `material.graph.nodes` with kind \"" + kind + "\" lists every node of the kind.";
            error(base + "/type",
                  "node type \"" + typeName + "\" does not work in a material of kind \"" + kind + "\" (it works in " +
                      join(n.type->kinds, ", ") + ")",
                  hint);
        }
        n.inLink.assign(n.type->inputs.size(), -1);
        n.constComps.assign(n.type->inputs.size(), 0);
        n.outComps.assign(n.type->outputs.size(), 0);
        read_ref(n, base);
        // inputs
        if (auto in = j.find("inputs"); in != j.end()) {
            if (!in->is_object()) {
                error(base + "/inputs", "expected an object, got " + describe_json_value(*in),
                      "Write \"inputs\": {\"scale\": 6.0}: the constants of the inputs that have no link.");
            } else {
                const std::vector<std::string> names = port_names(n.type->inputs);
                for (auto it = in->begin(); it != in->end(); ++it) {
                    const std::string ptr = base + "/inputs/" + escape_token(it.key());
                    std::size_t port = 0;
                    while (port < names.size() && names[port] != it.key()) ++port;
                    if (port == names.size()) {
                        error(ptr, "node type \"" + typeName + "\" has no input \"" + it.key() + "\"",
                              names.empty()
                                  ? "This node type has no inputs."
                                  : did_you_mean(it.key(), names) + " Its inputs: " + join(names, ", ") + ".");
                        continue;
                    }
                    n.constComps[port] = read_constant(it.value(), n.type->inputs[port], ptr);
                }
            }
        }
    }

    void read_ref(Node& n, const std::string& base) {
        const Json& j = *n.json;
        const std::string& want = n.type->ref;
        for (const char* key : {"param", "texture"}) {
            auto it = j.find(key);
            if (it == j.end()) continue;
            if (want != key)
                error(base + "/" + key,
                      std::string("node type \"") + n.type->type + "\" has no \"" + key + "\" field" +
                          (want.empty() ? "" : " (it takes \"" + want + "\")"),
                      "Remove it.");
        }
        if (want.empty()) return;
        auto it = j.find(want);
        const bool isParam = want == "param";
        std::vector<std::string> names;
        if (isParam)
            for (const MaterialParam& p : material.params) names.push_back(p.name);
        else
            for (const MaterialTexture& t : material.textures) names.push_back(t.name);
        const std::string noun = isParam ? "param" : "texture";
        const std::string declare =
            isParam ? "Declare it under \"params\" of the material (type, default, doc)."
                    : "Declare it under \"textures\" of the material (default path, sampler, doc; at most 4).";
        if (it == j.end() || !it->is_string()) {
            error(base + "/" + want,
                  it == j.end() ? "missing \"" + want + "\"" : "expected a string, got " + describe_json_value(*it),
                  "Name one of the material's " + noun + "s" +
                      (names.empty() ? ". " + declare : ": " + join(names, ", ") + "."));
            return;
        }
        const std::string name = it->get<std::string>();
        auto found = std::find(names.begin(), names.end(), name);
        if (found == names.end()) {
            error(base + "/" + want, "the material has no " + noun + " \"" + name + "\"",
                  names.empty() ? declare : did_you_mean(name, names) + " " + declare);
            return;
        }
        n.ref = name;
        if (isParam) {
            for (const MaterialParam& p : material.params)
                if (p.name == name) n.refComps = p.type == "color" ? 4 : p.components();
        }
    }

    void read_links() {
        auto it = graph.find("links");
        if (it == graph.end()) return;
        if (!it->is_array()) {
            error("/graph/links", "expected an array, got " + describe_json_value(*it),
                  "Write \"links\": [{\"from\": \"noise1.value\", \"to\": \"out.alpha\"}].");
            return;
        }
        for (std::size_t i = 0; i < it->size(); ++i) read_link(int(i), (*it)[i]);
    }

    // "node.port" of a link end: the node and the port index among `outputs` (from) or `inputs` (to); false after an error.
    bool read_end(const Json& link, const char* key, int index, bool isOutput, int& node, int& port) {
        const std::string ptr = link_pointer(index) + "/" + key;
        auto it = link.find(key);
        if (it == link.end() || !it->is_string()) {
            error(ptr,
                  it == link.end() ? std::string("missing \"") + key + "\""
                                   : "expected a string, got " + describe_json_value(*it),
                  "Write {\"from\": \"noise1.value\", \"to\": \"out.alpha\"}: node id, a dot, the port name.");
            return false;
        }
        const std::string text = it->get<std::string>();
        const std::size_t dot = text.find('.');
        if (dot == std::string::npos || dot == 0 || dot + 1 == text.size()) {
            error(ptr, "\"" + text + "\" is not \"nodeId.port\"",
                  std::string("Write the node id, a dot and the ") + (isOutput ? "output" : "input") +
                      " name, e.g. \"noise1." + (isOutput ? "value" : "scale") + "\".");
            return false;
        }
        const std::string id = text.substr(0, dot), portName = text.substr(dot + 1);
        auto found = byId.find(id);
        if (found == byId.end()) {
            std::vector<std::string> ids;
            for (const auto& [k, v] : byId) ids.push_back(k);
            error(ptr, "no node with id \"" + id + "\"",
                  ids.empty() ? "The graph has no usable node ids."
                              : did_you_mean(id, ids) + " Nodes: " + join(ids, ", ") + ".");
            return false;
        }
        const Node& n = a.nodes[found->second];
        if (!n.type) return false;  // its own error is reported
        const std::vector<GraphPort>& ports = isOutput ? n.type->outputs : n.type->inputs;
        const std::vector<std::string> names = port_names(ports);
        auto p = std::find(names.begin(), names.end(), portName);
        if (p == names.end()) {
            error(ptr,
                  "node \"" + id + "\" (" + n.type->type + ") has no " + (isOutput ? "output" : "input") + " \"" +
                      portName + "\"",
                  names.empty() ? "This node type has no " + std::string(isOutput ? "outputs" : "inputs") + "."
                                : did_you_mean(portName, names) + " Its " + (isOutput ? "outputs: " : "inputs: ") +
                                      join(names, ", ") + ".");
            return false;
        }
        node = found->second;
        port = int(p - names.begin());
        return true;
    }

    void read_link(int index, const Json& j) {
        if (!j.is_object()) {
            error(link_pointer(index), "expected an object, got " + describe_json_value(j),
                  "Write {\"from\": \"noise1.value\", \"to\": \"out.alpha\"}.");
            return;
        }
        static const std::vector<std::string> known = {"from", "to"};
        for (auto it = j.begin(); it != j.end(); ++it)
            if (std::find(known.begin(), known.end(), it.key()) == known.end())
                error(link_pointer(index) + "/" + escape_token(it.key()), "unknown key \"" + it.key() + "\"",
                      did_you_mean(it.key(), known));
        Link l;
        l.index = index;
        const bool fromOk = read_end(j, "from", index, true, l.from, l.fromPort);
        const bool toOk = read_end(j, "to", index, false, l.to, l.toPort);
        if (!fromOk || !toOk) return;
        Node& target = a.nodes[l.to];
        if (target.inLink[l.toPort] >= 0) {
            error(link_pointer(index) + "/to",
                  "input \"" + target.id + "." + target.type->inputs[l.toPort].name +
                      "\" already has the link /graph/links/" + std::to_string(a.links[target.inLink[l.toPort]].index),
                  "An input takes one link: remove one of them, or combine the two outputs with a math node first.");
            return;
        }
        if (target.constComps[l.toPort] > 0)
            warn("/graph/nodes/" + std::to_string(l.to) + "/inputs/" + escape_token(target.type->inputs[l.toPort].name),
                 "the constant is ignored: the input \"" + target.id + "." + target.type->inputs[l.toPort].name +
                     "\" is linked (/graph/links/" + std::to_string(index) + ")",
                 "Remove the constant.");
        target.inLink[l.toPort] = int(a.links.size());
        a.links.push_back(l);
    }

    // ---- types ----

    std::string type_text(int comps, const Node& n, int outPort) const {
        const std::string t = n.type->outputs[outPort].type;
        return t == "gen" || t == "param" ? vec_type(comps) : t;
    }

    static std::string widen_hint(int srcComps, int dstComps) {
        if (srcComps > 1 && dstComps == 1) return "Pick one component with a math.split node (outputs x, y, z, w).";
        if (srcComps < dstComps)
            return "Build the vector you need with a math.combine node (outputs vec2, vec3, vec4).";
        return "Drop components with a math.split node and join the ones you want with math.combine (a colour's rgb is "
               "an "
               "output of the texture and vertex.color nodes).";
    }

    void resolve(int ni) {
        Node& n = a.nodes[ni];
        if (n.state == 2 || !n.type) return;
        n.state = 1;
        stack.push_back(ni);
        for (std::size_t p = 0; p < n.type->inputs.size(); ++p) {
            const int li = n.inLink[p];
            if (li < 0) continue;
            const Link& l = a.links[li];
            Node& s = a.nodes[l.from];
            if (s.state == 1) {
                // s is on the stack: the cycle is s, the nodes above it (its consumers' sources) and back
                // data flows s -> n -> (what n feeds, up the stack) -> s: list it from s
                std::vector<std::string> path = {s.id};
                auto at = std::find(stack.begin(), stack.end(), l.from);
                for (auto q = stack.end(); q != at + 1;) path.push_back(a.nodes[*--q].id);
                path.push_back(s.id);
                error(link_pointer(l.index) + "/to", "this link closes a cycle: " + join(path, " -> "),
                      "A graph flows from the inputs to the output and cannot loop back: remove this link.");
                n.inLink[p] = -1;
                continue;
            }
            resolve(l.from);
        }
        stack.pop_back();
        // the size of the `gen` ports: what the vectors linked or written into them agree on, else a float
        int genN = 1;
        for (std::size_t p = 0; p < n.type->inputs.size(); ++p) {
            if (n.type->inputs[p].type != "gen") continue;
            int c = 0;
            std::string where;
            if (n.inLink[p] >= 0) {
                const Link& l = a.links[n.inLink[p]];
                c = a.nodes[l.from].outComps[l.fromPort];
                where = link_pointer(l.index) + "/to";
            } else if (n.constComps[p] > 0) {
                c = n.constComps[p];
                where = node_pointer(ni) + "/inputs/" + escape_token(n.type->inputs[p].name);
            }
            if (c <= 1) continue;
            if (genN > 1 && genN != c)
                error(where,
                      "the inputs of node \"" + n.id + "\" (" + n.type->type + ") disagree: " + vec_type(genN) +
                          " and " + vec_type(c),
                      "A float widens to any size, but a vec2, vec3 and vec4 do not mix: bring them to one size with "
                      "math.split "
                      "and math.combine.");
            else
                genN = c;
        }
        n.genN = genN;
        for (std::size_t k = 0; k < n.type->outputs.size(); ++k) {
            const std::string& t = n.type->outputs[k].type;
            n.outComps[k] = t == "gen" ? genN : t == "param" ? n.refComps : comps_of(t);
        }
        // the linked types
        for (std::size_t p = 0; p < n.type->inputs.size(); ++p) {
            const int li = n.inLink[p];
            if (li < 0) continue;
            const Link& l = a.links[li];
            const Node& s = a.nodes[l.from];
            const GraphPort& port = n.type->inputs[p];
            if (s.failed()) continue;
            const int src = s.outComps[l.fromPort];
            if (s.type->type == "math.split" && l.fromPort >= s.genN)
                error(link_pointer(l.index) + "/from",
                      "output \"" + s.type->outputs[l.fromPort].name + "\" of node \"" + s.id +
                          "\" needs a vector of " + std::to_string(l.fromPort + 1) +
                          " components, but its input is a " + vec_type(s.genN),
                      "Link a vec" + std::to_string(l.fromPort + 1) +
                          " or larger into its \"value\" input, or use an earlier "
                          "output.");
            if (port.type == "gen") continue;  // agreed above
            const int dst = comps_of(port.type);
            if (src == dst || src == 1) continue;
            error(link_pointer(l.index) + "/to",
                  "type mismatch: cannot link " + vec_type(src) + " (output \"" + s.type->outputs[l.fromPort].name +
                      "\" of node \"" + s.id + "\") into " + port.type + " input \"" + port.name + "\" of node \"" +
                      n.id + "\"",
                  widen_hint(src, dst));
        }
        n.state = 2;
    }

    // ---- the output node ----

    void check_output() {
        for (Node& n : a.nodes) {
            if (!n.type || n.type->type != kGraphOutputNode) continue;
            if (a.output >= 0) {
                error(node_pointer(n.index),
                      "a second output node (\"" + n.id + "\"; the first is \"" + a.nodes[a.output].id + "\")",
                      "A graph has exactly one output node: remove one.");
                continue;
            }
            a.output = n.index;
        }
        if (a.output < 0) {
            if (!a.nodes.empty())
                error("/graph/nodes", "the graph has no output node",
                      "Add {\"id\": \"out\", \"type\": \"output\", \"inputs\": {\"albedo\": [1, 0.4, 0.1]}}: it says "
                      "which fields of "
                      "the surface the graph sets.");
            return;
        }
        const Node& o = a.nodes[a.output];
        auto port_of = [&](const char* name) -> int {
            for (std::size_t p = 0; p < o.type->inputs.size(); ++p)
                if (o.type->inputs[p].name == name) return int(p);
            return -1;
        };
        const int normal = port_of("normal"), tangent = port_of("tangentNormal");
        if (normal >= 0 && tangent >= 0 && o.set(normal) && o.set(tangent))
            error(node_pointer(o.index) + "/inputs/tangentNormal",
                  "\"normal\" and \"tangentNormal\" of the output are both set: they both write Surface.normal",
                  "Keep one: tangentNormal for a normal map (texture.normal), normal for a world-space vector.");
        bool any = false;
        for (std::size_t p = 0; p < o.type->inputs.size(); ++p) any = any || o.set(p);
        if (!any)
            warn(node_pointer(o.index),
                 "nothing is linked into the output node or set in its \"inputs\": the material looks like a "
                 "plain " +
                     std::string(kind == "sprite" ? "sprite" : "MeshRenderer"),
                 kind == "sprite" ? "Link a node into color, rgb or alpha..."
                                  : "Link a node into albedo, emission, roughness...");
        const int alpha = port_of("alpha");
        if (kind == "mesh" && alpha >= 0 && o.set(alpha) && material.alphaMode == "opaque")
            warn(node_pointer(o.index) + "/inputs/alpha",
                 "alphaMode is \"opaque\", so the alpha of the graph is ignored",
                 "Set \"alphaMode\" to \"clip\" (holes, also in the shadow) or \"blend\" (translucent) in the material "
                 "file.");
    }

    // The variables of the nodes may not collide with the material's params and textures.
    void check_names() {
        std::set<std::string> taken;
        // gn_ names the helper functions the generator pastes (gn_hash22...): a param or texture of that name would clash with
        // one of them in a way that depends on which nodes the graph draws.
        auto reserved = [&](const std::string& name, const char* section, const char* noun) {
            if (name.rfind("gn_", 0) != 0) return;
            error(std::string("/") + section + "/" + escape_token(name),
                  std::string("the ") + noun + " name \"" + name +
                      "\" starts with gn_, which the node graph keeps for its GLSL helper functions",
                  "Rename the " + std::string(noun) + " (and the nodes that name it), e.g. \"" + name.substr(3) +
                      "\".");
        };
        for (const MaterialParam& p : material.params) {
            taken.insert(p.name);
            reserved(p.name, "params", "param");
        }
        for (const MaterialTexture& t : material.textures) {
            reserved(t.name, "textures", "texture");
            taken.insert(t.name);
            taken.insert(t.name + "_smp");
        }
        std::map<std::string, std::string> made;  // GLSL name -> "id.output"
        for (const Node& n : a.nodes) {
            if (!n.type || n.id.empty()) continue;
            for (const GraphPort& out : n.type->outputs) {
                const std::string name = "n_" + n.id + "_" + out.name;
                const std::string what = n.id + "." + out.name;
                if (taken.count(name)) {
                    error(node_pointer(n.index) + "/id",
                          "the GLSL name " + name + " of \"" + what + "\" is also a param or texture",
                          "Rename the node.");
                } else if (auto [it, inserted] = made.emplace(name, what); !inserted) {
                    error(node_pointer(n.index) + "/id",
                          "\"" + what + "\" and \"" + it->second + "\" are both the GLSL name " + name,
                          "Rename the node so that id and output do not run together.");
                }
            }
        }
    }

    // ---- which nodes each function draws ----

    void visit(int ni, std::vector<int>& order, std::set<int>& seen) {
        if (!seen.insert(ni).second) return;
        const Node& n = a.nodes[ni];
        for (std::size_t p = 0; p < n.type->inputs.size(); ++p)
            if (n.inLink[p] >= 0) visit(a.links[n.inLink[p]].from, order, seen);
        order.push_back(ni);
    }

    void order_stages() {
        if (a.output < 0 || !check.ok()) return;  // cycles and the like would not end
        const Node& o = a.nodes[a.output];
        std::set<int> seenF, seenV;
        for (std::size_t p = 0; p < o.type->inputs.size(); ++p) {
            if (o.inLink[p] < 0) continue;
            const bool vertex = o.type->inputs[p].name == "vertexOffset";
            visit(a.links[o.inLink[p]].from, vertex ? a.vertexOrder : a.fragmentOrder, vertex ? seenV : seenF);
        }
        for (int ni : a.vertexOrder) {
            const Node& n = a.nodes[ni];
            if (!n.type->fragmentOnly) continue;
            error(
                node_pointer(ni) + "/type",
                "node \"" + n.id + "\" (" + n.type->type +
                    ") feeds vertexOffset, but it needs the fragment stage (it samples a "
                    "texture or reads the view direction), which vertex() has not",
                std::string(kind == "sprite"
                                ? "vertexOffset can use math, noise, time, param, uv and sprite.tint nodes; sample "
                                  "textures in the colour fields only (docs/SHADERS.md)."
                                : "vertexOffset can use math, noise, time, param, uv, position.world, normal.world and "
                                  "vertex.color nodes; sample textures in the surface fields only (docs/SHADERS.md)."));
        }
        for (const Node& n : a.nodes) {
            if (!n.type || n.index == a.output || seenF.count(n.index) || seenV.count(n.index)) continue;
            warn(node_pointer(n.index),
                 "node \"" + n.id + "\" is not linked to the output, so the snippet leaves it out",
                 "Link it into the output (or into a node that is), or remove it.");
        }
    }
};

// ---------------------------------------------------------------------------------------------------------------
// The generator
// ---------------------------------------------------------------------------------------------------------------

struct Writer {
    const Analysis& a;
    const KindProfile& profile;

    static std::string var(const Node& n, std::size_t out) { return "n_" + n.id + "_" + n.type->outputs[out].name; }

    static std::string widen(const std::string& expr, int from, int to) {
        return from == to || from != 1 ? expr : vec_type(to) + "(" + expr + ")";
    }

    // The GLSL of input `port` of node `n` as a value of the size the port has (a `gen` port: the node's genN).
    std::string input(const Node& n, std::size_t port, bool vertex) const {
        const GraphPort& p = n.type->inputs[port];
        const int want = p.type == "gen" ? n.genN : comps_of(p.type);
        if (n.inLink[port] >= 0) {
            const Link& l = a.links[n.inLink[port]];
            const Node& s = a.nodes[l.from];
            return widen(var(s, l.fromPort), s.outComps[l.fromPort], want);
        }
        if (n.constComps[port] > 0) {
            const Json& v = (*n.json->find("inputs"))[p.name];
            return widen(glsl_literal(v, 1), n.constComps[port], want);
        }
        if (p.defaultValue.is_string()) {
            const SurfaceValue* s = surface_value(profile, p.defaultValue.get<std::string>().substr(1));
            return widen(vertex ? s->vertex : s->fragment, s->comps, want);
        }
        return widen(glsl_literal(p.defaultValue, 1), p.defaultValue.is_array() ? int(p.defaultValue.size()) : 1, want);
    }

    // The expression `tpl` of node `n`: {input}, {ref}, {self} and $surface-value substituted.
    std::string expression(const Node& n, const std::string& tpl, bool vertex) const {
        std::string out;
        for (std::size_t i = 0; i < tpl.size();) {
            if (tpl[i] == '{') {
                const std::size_t close = tpl.find('}', i);
                const std::string name = tpl.substr(i + 1, close - i - 1);
                i = close + 1;
                if (name == "ref") {
                    out += n.ref;
                } else if (name == "self") {
                    out += "n_" + n.id + "_";
                } else {
                    for (std::size_t p = 0; p < n.type->inputs.size(); ++p)
                        if (n.type->inputs[p].name == name) out += input(n, p, vertex);
                }
            } else if (tpl[i] == '$') {
                std::size_t end = i + 1;
                while (end < tpl.size() && (std::islower(static_cast<unsigned char>(tpl[end])) || tpl[end] == '_'))
                    ++end;
                const SurfaceValue* s = surface_value(profile, std::string_view(tpl).substr(i + 1, end - i - 1));
                out += vertex ? s->vertex : s->fragment;
                i = end;
            } else {
                out += tpl[i++];
            }
        }
        return out;
    }

    std::string node_line(const Node& n, bool vertex) const {
        std::string line = "    ";
        for (std::size_t k = 0; k < n.type->outputs.size(); ++k) {
            std::string tpl = n.type->expr[k];
            if (n.type->type == "math.split") {
                if (int(k) >= n.genN) continue;  // the vector has no such component (the checks refuse a link from it)
                if (n.genN == 1) tpl = "{value}";  // a float has no swizzle
            }
            line += vec_type(n.outComps[k]) + " " + var(n, k) + " = " + expression(n, tpl, vertex) + "; ";
        }
        line.back() = ' ';
        return line + " // " + n.id + " (" + n.type->type + ")\n";
    }

    // The statements of the output node's fields for one function.
    std::string output_lines(bool vertex) const {
        const Node& o = a.nodes[a.output];
        std::string out;
        for (std::size_t p = 0; p < o.type->inputs.size(); ++p) {
            const std::string& name = o.type->inputs[p].name;
            if (!o.set(p) || (name == "vertexOffset") != vertex) continue;
            const std::string value = input(o, p, vertex);
            std::string stmt;
            if (const std::string& assign = o.type->inputs[p].assign; !assign.empty()) {
                stmt = assign;
                stmt.replace(stmt.find("{}"), 2, value);
            } else if (name == "vertexOffset")
                stmt = "v.world_pos += " + value + ";";
            else if (name == "tangentNormal")
                stmt = "s.normal = fa_tangent_normal(i, " + value + ");";
            else
                stmt = "s." + name + " = " + value + ";";
            out += "    " + stmt + "  // " + o.id + " (output)\n";
        }
        return out;
    }

    // `owners`, when given, gets the id of the node that wrote each line of the text returned (one entry per line).
    std::string function(bool vertex, std::vector<std::string>* owners = nullptr) const {
        auto own = [&](const std::string& text, const std::string& id) {
            if (owners) owners->insert(owners->end(), std::size_t(std::count(text.begin(), text.end(), '\n')), id);
        };
        std::string out = vertex ? profile.vertexHeader : profile.fragmentHeader;
        own(out, "");
        for (int ni : vertex ? a.vertexOrder : a.fragmentOrder) {
            const std::string line = node_line(a.nodes[ni], vertex);
            own(line, a.nodes[ni].id);
            out += line;
        }
        const std::string outputs = output_lines(vertex);
        own(outputs, a.nodes[a.output].id);
        out += outputs;
        own("}\n", "");
        return out + "}\n";
    }

    std::string helpers_text() const {
        std::set<std::string> needed;
        const auto& list = graph_detail::helpers();
        std::function<void(const std::string&)> add = [&](const std::string& name) {
            if (!needed.insert(name).second) return;
            for (const Helper& h : list)
                if (name == h.name)
                    for (const char* dep : h.deps) add(dep);
        };
        for (const auto* order : {&a.fragmentOrder, &a.vertexOrder})
            for (int ni : *order)
                for (const std::string& h : a.nodes[ni].type->helpers) add(h);
        std::string out;
        for (const Helper& h : list)
            if (needed.count(h.name)) out += std::string(h.code) + "\n";
        return out;
    }
};

}  // namespace

GraphCheck check_material_graph(const Json& graph, const MaterialDef& material, const std::string& kind) {
    GraphCheck check;
    Analyser an{graph, material, kind, check, {}, {}, {}};
    an.run();
    return check;
}

MaterialGraphReport check_material_document(const Json& doc, const std::string& projectDir, const std::string& path) {
    MaterialGraphReport r;
    MaterialParse mp = parse_material(doc, projectDir, path);
    r.material = std::move(mp.material);
    r.errors = std::move(mp.errors);
    if (auto k = doc.find("kind"); k != doc.end() && k->is_string()) r.kind = k->get<std::string>();
    auto graph = doc.find("graph");
    r.hasGraph = graph != doc.end();
    if (!r.hasGraph) return r;
    // parse_material ran the graph check already (its errors are in r.errors); the second run gives the warnings and the snippet.
    GeneratedGraph g = generate_graph_snippet(*graph, r.material, r.kind);
    r.warnings = std::move(g.check.warnings);
    if (r.errors.empty() && g.check.ok()) {
        r.snippet = std::move(g.snippet);
        r.hash = std::move(g.hash);
        r.usedNodes = std::move(g.usedNodes);
        r.hasVertex = g.hasVertex;
        r.lineNodes = std::move(g.lineNodes);
    } else if (r.errors.empty()) {
        r.errors = std::move(g.check.errors);
    }
    return r;
}

GeneratedGraph generate_graph_snippet(const Json& graph, const MaterialDef& material, const std::string& kind) {
    GeneratedGraph out;
    Analyser an{graph, material, kind, out.check, {}, {}, {}};
    if (!an.run()) return out;
    const Analysis& a = an.a;
    const Writer w{a, profile_of(kind)};
    out.snippet =
        "// GENERATED by material.graph.generate from the \"graph\" of this material's .material.json. Do not edit "
        "this file:\n"
        "// change the graph and generate again. A hand-edited snippet is never overwritten without force.\n\n";
    out.snippet += w.helpers_text();
    out.lineNodes.assign(std::size_t(std::count(out.snippet.begin(), out.snippet.end(), '\n')), std::string());
    std::set<std::string> used;
    for (const auto* order : {&a.fragmentOrder, &a.vertexOrder})
        for (int ni : *order) used.insert(a.nodes[ni].id);
    out.usedNodes.assign(used.begin(), used.end());
    for (std::size_t p = 0; p < a.nodes[a.output].type->inputs.size(); ++p)
        if (a.nodes[a.output].type->inputs[p].name == "vertexOffset" && a.nodes[a.output].set(p)) out.hasVertex = true;
    if (out.hasVertex) {
        out.snippet += w.function(true, &out.lineNodes) + "\n";
        out.lineNodes.emplace_back();  // the blank line between the two functions
    }
    out.snippet += w.function(false, &out.lineNodes);
    out.hash = graph_snippet_hash(out.snippet);
    return out;
}

std::string graph_node_at_line(const std::vector<std::string>& lineNodes, int line) {
    return line >= 1 && std::size_t(line) <= lineNodes.size() ? lineNodes[std::size_t(line) - 1] : std::string();
}

std::string graph_snippet_hash(std::string_view snippet) {
    return sha256_hex(shaders_detail::normalize_snippet(snippet));
}

// ---------------------------------------------------------------------------------------------------------------
// The library as JSON
// ---------------------------------------------------------------------------------------------------------------

Json graph_library_json(const std::string& kind, const std::string& category, const std::string& type) {
    Json nodes = Json::array();
    std::set<std::string> categories;
    for (const GraphNodeType& t : graph_node_library()) {
        if (!type.empty() && t.type != type) continue;
        if (!category.empty() && t.category != category) continue;
        if (!kind.empty() && std::find(t.kinds.begin(), t.kinds.end(), kind) == t.kinds.end()) continue;
        categories.insert(t.category);
        Json inputs = Json::array(), outputs = Json::array();
        for (const GraphPort& p : t.inputs) {
            Json j = Json::object({{"name", p.name}, {"type", p.type}});
            if (!p.defaultValue.is_null()) j["default"] = p.defaultValue;
            j["doc"] = p.doc;
            inputs.push_back(std::move(j));
        }
        for (const GraphPort& p : t.outputs)
            outputs.push_back(Json::object(
                {{"name", p.name}, {"type", p.type == "param" ? "the param's type" : p.type}, {"doc", p.doc}}));
        Json j = Json::object({{"type", t.type},
                               {"category", t.category},
                               {"doc", t.doc},
                               {"kinds", Json(t.kinds)},
                               {"stage", t.fragmentOnly ? "fragment" : "any"}});
        if (!t.ref.empty()) j["needs"] = t.ref;
        j["inputs"] = std::move(inputs);
        j["outputs"] = std::move(outputs);
        nodes.push_back(std::move(j));
    }
    return Json::object(
        {{"nodes", nodes}, {"categories", Json(std::vector<std::string>(categories.begin(), categories.end()))}});
}

}  // namespace fa
