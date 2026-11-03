// Model documents (`*.model.json`, format "factoria.model/1", schemas/model.schema.json, docs/MODELING.md): a 3D model written as a tree of
// operations instead of a mesh file. The tree is parametric primitives (box, rounded_box, cylinder, cone, sphere, capsule, torus,
// grid, stairs, arch, pipe, text, and the generators lathe, sweep and loft), groups, MODIFIERS (a node that wraps the nodes below it and
// changes their combined mesh: mirror, array, bevel, subdivide, boolean... model_modifiers.h), and a transform on any node; a node may name a PART (a labelled piece of the model that
// ends up as its own submesh) and a MATERIAL (an entry of the document's `materials`) and give VERTEX COLOURS, all inherited by
// the nodes below it. Evaluating the document gives a mesh in the form MeshStore and `mesh.save` take, so a model can be baked to
// a .glb (tools/common: model.bake), used as a procedural mesh, or checked.
//
// Determinism. The same document gives the same bytes on every platform: the kernel (model_kernel.h) uses only + - * / sqrt and fa::det
// trigonometry, nodes are evaluated in document order and the only outside input is the font of a `text` node, which is data the
// engine ships (or a project file the recipe records).
//
// This file is the document: the catalog of operations, reading and checking (every problem listed with its JSON pointer and the fix),
// editing helpers and evaluation. GPU-free, in fa_scene.
#pragma once

#include <functional>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/types.h"
#include "fa/scene/mesh_store.h"
#include "fa/scene/model_kernel.h"

namespace fa {

inline constexpr const char* kModelDocFormat = "factoria.model/1";
inline constexpr const char* kModelDocSuffix = ".model.json";
inline constexpr std::size_t kModelDocMaxNodes = 2048;  // nodes in one document, groups included
inline constexpr int kModelDocMaxDepth = 16;            // levels of nested groups and modifiers

// One problem of a document: where (a JSON pointer such as "/nodes/2/radius"), what is wrong, and how to fix it.
struct ModelIssue {
    std::string pointer;
    std::string message;
    std::string hint;
};

// One field of an operation, as the catalog lists it and as the reader checks it. `type`:
//   "number", "integer", "boolean", "string", "choice" (one of `choices`), "vec3" ([x, y, z]), "size3" (a number for all three, or
//   [x, y, z]), "count3" (an integer for all three, or [x, y, z]), "count2" (an integer for both, or [x, z]), "color" ([r, g, b] or
//   [r, g, b, a] in 0..1, or "#rrggbb" / "#rrggbbaa"), "points2" (a list of [a, b] pairs), "points3" (a list of [x, y, z]), "rings" (a list
//   of lists of [x, y, z]: the sections of a loft), "nodes" (a list of nodes).
// `min` / `max` bound every number inside a vec / points field; `minItems` / `maxItems` bound the length of a points list or of the list of
// sections of "rings", and `innerMinItems` / `innerMaxItems` the points of each section.
struct ModelFieldInfo {
    std::string key;
    std::string type;
    std::string doc;
    bool required = false;
    std::optional<double> min, max;  // numbers and integers; for size3 / count3 / count2 / vec3 each entry
    std::optional<Json> def;         // the default; absent when the field has none (left out = the kernel's own rule, said in `doc`)
    std::vector<std::string> choices;
    std::optional<int> minItems, maxItems;            // points2, points3, rings: how many entries
    std::optional<int> innerMinItems, innerMaxItems;  // rings: how many points in each section
};
struct ModelOpInfo {
    std::string op;
    std::string kind;  // "primitive" (makes geometry; takes `align`), "modifier" (changes the mesh of its `children`), "group", "sdf" (meshes its signed-distance children; takes `align`), "sdf_group" or "sdf_shape" (the nodes inside an sdf)
    std::string doc;   // what it makes, with its orientation and size
    std::vector<ModelFieldInfo> fields;  // the fields of this operation (not the common ones)
};
// Every operation the format knows, primitives first, in the order the docs describe them.
const std::vector<ModelOpInfo>& model_ops();
// The fields every node takes (op, id, note, enabled, part, material, color, position, rotation, scale), then `align` which only the
// primitives take.
const std::vector<ModelFieldInfo>& model_common_fields();
const std::vector<ModelFieldInfo>& model_align_fields();
// The JSON schema of the whole format, built from the catalog; schemas/model.schema.json is this, written out (a test keeps them equal).
Json model_doc_schema();

// A node of the tree. `params` has every field of the operation with its default filled in and checked (an optional field with no default
// is present only when the document gave it); vec fields are normalised to arrays ([x, y, z]).
struct ModelNode {
    std::string op;
    std::string id;       // "" = none; unique in the document when given
    std::string note;
    bool enabled = true;
    std::optional<std::string> part;      // the part this node and the nodes below it belong to
    std::optional<std::string> material;  // a key of ModelDoc::materials
    std::optional<Vec4> color;            // vertex colours
    Vec3 position{0, 0, 0};
    Vec3 rotation{0, 0, 0};  // degrees, Euler (pitch x, yaw y, roll z), applied roll, pitch, then yaw
    Vec3 scale{1, 1, 1};
    std::string align = "center";         // primitives: "center", "bottom" or "top"
    Json params = Json::object();
    std::vector<ModelNode> children;      // groups and modifiers
    std::string pointer;                  // where it is in the document: "/nodes/0/children/1"
};

struct ModelDoc {
    std::string doc;
    std::string outputPath;  // where bake writes the .glb (project-relative); "" = next to the document
    Json gameReady;          // the "gameReady" object, checked and with its defaults filled in (null = the document has none); read it with parse_game_ready (model_game_ready.h)
    std::vector<std::pair<std::string, MeshMaterial>> materials;  // in document order; the key is the material's name
    std::vector<ModelNode> nodes;
};

// Reads a document. Every problem found is listed in `issues` (not only the first), each with its JSON pointer, what is wrong and the
// fix, and "did you mean" for names. `file` only names the document in the message of the error that is returned for the first.
Result<ModelDoc> parse_model_doc(const Json& json, std::string_view file = {}, std::vector<ModelIssue>* issues = nullptr);
// parse_model_doc of a file read through the VFS (project-relative).
Result<ModelDoc> load_model_doc(std::string_view path, std::vector<ModelIssue>* issues = nullptr);

// The node at `ref` in a document's JSON: a node id ("door_frame"), or a JSON pointer ("/nodes/0/children/1"). nullptr when nothing is
// there; `why` (optional) gets the teaching message, with the ids that exist.
Json* find_model_node(Json& documentJson, std::string_view ref, std::string* pointer = nullptr, std::string* why = nullptr);
// The ids of the nodes of a document's JSON, in document order, with their pointers.
std::vector<std::pair<std::string, std::string>> model_node_ids(const Json& documentJson);

// ---- evaluation ------------------------------------------------------------------------------------------------------------

// The glyph outlines of a `text` node, asked from the caller because fonts live above this module (fa_render): the text, the font name
// ("" = the built-in default, "builtin:serif", or a project .ttf), the anchor ("start", "middle", "end") and spacing.
struct ModelTextRequest {
    std::string text;
    std::string font;
    std::string anchor = "middle";
    float letterSpacing = 0, lineSpacing = 1;
};
using ModelTextSource = std::function<Result<ModelTextOutline>(const ModelTextRequest&)>;

struct ModelEvalOptions {
    ModelTextSource text;  // none: a `text` node fails with an error saying the evaluator has no font source
};

// One submesh of the result: a part with a material.
struct ModelPartInfo {
    std::string part;      // "" = the nodes that name no part
    std::string material;  // "" = the default material
    std::size_t triangles = 0;
    Vec3 bmin{}, bmax{};
};

struct ModelBuild {
    MeshData data;                    // ready for MeshStore / mesh_to_glb; one submesh per entry of `parts`, in the same order
    std::vector<ModelPartInfo> parts;
    ModelMeshStats stats;             // vertices, triangles, bounds, welded surface checks (closed, volume...)
    std::vector<std::string> warnings;
    std::vector<std::string> inputs;  // project files the evaluation read (fonts, material textures), sorted
};

// Evaluates the tree in document order. Fails (with the node's pointer in the message) when a text node cannot be made, or the mesh has
// no triangles or more than MeshStore allows.
Result<ModelBuild> evaluate_model(const ModelDoc& doc, const ModelEvalOptions& options = {});

}  // namespace fa
