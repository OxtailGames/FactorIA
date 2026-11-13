// Selections and edits of model documents (docs/MODELING.md, "Selections and edits"): faces and edges chosen by MEANING, and the
// operations that work on them (extrude_faces, inset_faces, loop_cut, bevel_edges, delete_faces, assign_faces).
//
// A selection is a QUERY, never a list of indices. It is written in the document as a small object with a `by`
// ({"by": "normal", "direction": "top"}, {"by": "part", "part": "lid"}, {"by": "and", "of": [...]}) and evaluated on the mesh that reaches
// the edit node, at the moment the tree is evaluated. When an upstream parameter changes (a box gets more segments, a primitive grows, a
// boolean cuts something), the triangle indices change but the query still means the same thing, so the same faces are chosen. The catalog
// of queries below is the single source of truth for the reader (which checks them with a JSON pointer and a fix), the JSON schema,
// model.info and the docs.
//
// GPU-free and deterministic like the rest of the kernel: every choice is a comparison of floats computed with + - * / and sqrt (angles go
// through fa::det), elements are walked in index order and nothing depends on addresses.
#pragma once

#include <string>
#include <vector>

#include "fa/scene/model_doc.h"
#include "fa/scene/model_modifiers.h"

namespace fa {

enum class ModelSelectKind { Faces, Edges };

// One kind of query, as the reader checks it and as the docs list it. `fields` use the types of ModelFieldInfo plus "direction" (one of the
// names top, bottom, front, back, left, right, or [x, y, z]), "strings" (a list of text), "faces" / "edges" (a nested query),
// "faces_list" / "edges_list" (a list of nested queries).
struct ModelQueryInfo {
    ModelSelectKind kind;
    std::string by;
    std::string doc;
    std::vector<ModelFieldInfo> fields;
};
// Every query, face queries first, in the order the docs describe them. The `space` and `contain` fields are on the ones that have a place.
const std::vector<ModelQueryInfo>& model_queries();
// The names a `direction` can have, with the vector each one means (top = +Y, bottom = -Y, front = +Z, back = -Z, left = -X, right = +X).
const std::vector<std::pair<std::string, Vec3>>& model_named_directions();

// Checks a query written in a document: every problem is appended to `issues` with the JSON pointer of the field, what is wrong and the fix
// ("did you mean" for names). `pointer` is where the query is (e.g. "/nodes/0/faces").
void check_model_selection(const Json& query, ModelSelectKind kind, const std::string& pointer,
                           std::vector<ModelIssue>& issues);
// The JSON schema of a query (a `$defs` entry): an object with `by` and the union of the fields, documented.
Json model_selection_schema(ModelSelectKind kind);

// ---- evaluating ---------------------------------------------------------------------------------------------------------------

// Evaluates `query` on `mesh` (the mesh as it is at some point of the tree) and says what it matched, with a teaching warning for an empty
// result (what each part of the query matched, the parts that exist, how close the nearest face was). The query has been checked; an
// unknown part name is not an error, it is a warning that matches nothing.
ModelSelectionReport model_select_report(const ModelMesh& mesh, const Json& query, ModelSelectKind kind,
                                         const ModelEditContext& context);

// One flag per triangle of `mesh` (1: the face query chose it), for the code that works on a finished mesh (decals). Triangles the weld of
// the selector drops because they have no area are 0.
std::vector<char> model_select_triangles(const ModelMesh& mesh, const Json& query, const ModelEditContext& context);

// ---- the edit operations ------------------------------------------------------------------------------------------------------

// True for extrude_faces, inset_faces, loop_cut, bevel_edges, delete_faces and assign_faces.
bool model_is_edit_op(const std::string& op);

struct ModelEditResult {
    ModelMesh mesh;                     // the input mesh, edited
    ModelSelectionReport report;        // what the selection matched
    std::vector<std::string> warnings;  // includes the report's
};
// Applies the edit operation `node` (its params are checked) to `input`, the merged mesh of its children. Every triangle keeps its part;
// the new faces of an extrusion or an inset take `newPart` / `newMaterial` when given, else the part of the face they grew from. An empty
// selection is not an error: the mesh comes back unchanged and the warning says what to change. Fails when the edit cannot be built (an
// inset wider than the faces, a result with too many triangles), with the node's pointer-free message and the fix.
Result<ModelEditResult> model_apply_edit(const ModelNode& node, const ModelMesh& input,
                                         const ModelEditContext& context);

}  // namespace fa
