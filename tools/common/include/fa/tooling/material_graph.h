// The node graph of a material (docs/SHADERS.md, "Node graphs"; docs/design/CUSTOM_SHADERS.md, "Node graphs"): the `"graph"` object
// of a `*.material.json`, the library of nodes it is made of, and the generator that turns it into the GLSL snippet of the
// material. The graph and the code stay one document: the snippet file is GENERATED from the graph (the same graph gives the same
// bytes) and the material file keeps `"graphHash"`, the SHA-256 of the generated text, so a snippet someone edited by hand is
// found and never overwritten without `force`. Params and textures a node uses are the material's own `params` and `textures`.
// Commands: material.graph.nodes (the library), material.graph.validate, material.graph.generate (tools/common/src/
// material_graph_commands.cpp).
#pragma once

#include <string>
#include <string_view>
#include <utility>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/tooling/shaders.h"

namespace fa {

inline constexpr const char* kGraphOutputNode = "output";
// The `"version"` of the graph format this build reads and writes (a graph without one is version 1).
inline constexpr int kGraphVersion = 1;

// One input or output of a node type. `type` is "float", "vec2", "vec3", "vec4" or "gen" (a float or a vector of the size the
// linked and constant inputs of the node agree on; the other `gen` ports of the node take that size, a float is widened).
struct GraphPort {
    std::string name;
    std::string type;
    // Input default: a number, an array, a string naming a value of the surface ("$uv", "$world_pos", "$world_normal", "$view_dir"...:
    // the node reads it when nothing is linked), or null (an output node field left alone, the standard surface stays).
    Json defaultValue;
    std::string doc;
};

// One kind of node of the library.
struct GraphNodeType {
    std::string type;  // "noise.fbm"
    std::string category;
    std::string doc;
    std::vector<GraphPort> inputs;
    std::vector<GraphPort> outputs;  // an output of type "param" has the type of the param the node names
    std::vector<std::string> kinds;  // the material kinds the node works in ("mesh", later "sprite", "sky", "post")
    bool fragmentOnly =
        false;        // runs in surface() only (samples a texture, reads the view direction...), not in vertex()
    std::string ref;  // "param" or "texture": the node names one of the material's params or textures
    // How the generator writes the node (see material_graph_lib.cpp): one GLSL expression per output, written as
    // `type n_<id>_<output> = <expr>;` on one line. {input} is an input, {ref} the param or texture, {self} the node's variable
    // prefix, $uv/$world_pos/... the surface values.
    std::vector<std::string> expr;
    std::vector<std::string> helpers;  // functions of the library the expressions call; pasted once, only when used
};

// Every node type, in the order the docs list them (categories together).
const std::vector<GraphNodeType>& graph_node_library();
const GraphNodeType* find_graph_node_type(std::string_view type);
// The material kinds a graph can be generated for today ("mesh").
const std::vector<std::string>& graph_supported_kinds();
// The name of every helper function of the library and its GLSL (for the tests and the docs).
std::vector<std::pair<std::string, std::string>> graph_helper_functions();

struct GraphCheck {
    std::vector<MaterialIssue> errors;    // pointer into the material file ("/graph/links/2/to")
    std::vector<MaterialIssue> warnings;  // the graph works, but something is probably not what was meant
    bool ok() const { return errors.empty(); }
};

// Checks the `"graph"` object of a material of kind `kind`: node ids and types, constants, params and textures named, links
// (unknown node or port, a second link into one input, types), cycles, the output node, nodes that need the fragment stage on the
// vertex offset's path, and the kind. Pointers are into the material file. `material` supplies the params and textures.
GraphCheck check_material_graph(const Json& graph, const MaterialDef& material, const std::string& kind = "mesh");

struct GeneratedGraph {
    std::string snippet;  // empty when `check` has errors
    std::string hash;     // graph_snippet_hash(snippet)
    GraphCheck check;
    std::vector<std::string> usedNodes;  // ids of the nodes the snippet draws (reachable from the output), sorted
    bool hasVertex = false;              // the snippet defines vertex()
    // Which node wrote each line of the snippet: lineNodes[n - 1] is the id of the node whose code is line n ("" for the header, the
    // helper functions and the braces). The output node's lines name the output node. A compiler error on line n belongs to that node.
    std::vector<std::string> lineNodes;
};

// The snippet of a graph: deterministic (the same graph gives the same bytes; positions in the editor and the order of the arrays
// do not change it), readable (one line per node with a comment naming its id) and checked first (check_material_graph).
GeneratedGraph generate_graph_snippet(const Json& graph, const MaterialDef& material, const std::string& kind = "mesh");

// The whole check of a material document held in memory (what the editor's canvas runs after every edit): the errors of the
// material (the graph's among them, as `parse_material` reports them), the warnings of the graph, and the generated snippet when
// there are no errors. `doc` is the material as JSON, `"graph"` included (replace the graph in it to try another one);
// `projectDir` and `path` are as for parse_material (an empty `projectDir` skips the checks that look at files).
struct MaterialGraphReport {
    MaterialDef material;
    std::string kind = "mesh";
    bool hasGraph = false;
    std::vector<MaterialIssue> errors;
    std::vector<MaterialIssue> warnings;
    std::string snippet;                 // empty when `errors` is not
    std::string hash;                    // graph_snippet_hash(snippet)
    std::vector<std::string> usedNodes;  // ids of the nodes the snippet draws, sorted
    bool hasVertex = false;
    std::vector<std::string> lineNodes;  // as GeneratedGraph::lineNodes
    bool ok() const { return errors.empty() && hasGraph; }
};
MaterialGraphReport check_material_document(const Json& doc, const std::string& projectDir = {},
                                            const std::string& path = {});

// The id of the node that wrote line `line` (1-based) of a generated snippet; "" when none did or the line is out of range.
std::string graph_node_at_line(const std::vector<std::string>& lineNodes, int line);

// SHA-256 (hex) of a snippet's text with the CRs removed, so a file saved with CRLF on Windows hashes like the text generated.
std::string graph_snippet_hash(std::string_view snippet);

// The library as the JSON material.graph.nodes returns (filtered by kind, category and type; empty strings match all).
Json graph_library_json(const std::string& kind, const std::string& category, const std::string& type);

// "material.graph.nodes", "material.graph.validate" and "material.graph.generate" (category "material").
void register_material_graph_commands(CommandRegistry& registry, const std::string& projectDir);

}  // namespace fa
