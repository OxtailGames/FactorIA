// Fitting a rig template to a model (docs/RIGGING.md, "How the fit works"). The input is the document (rig_doc.h) and the evaluated model
// (a MeshData with its named parts); the output is the skeleton at rest: every bone with the position of its head and tail, where each
// number came from, and what the fit noticed.
//
// A joint comes from, in this order:
//   override    the document's `landmarks` (an explicit position)
//   part        a model part the fit recognised by its name (or that the document's `parts` named): the joint sits at a place along the part's
//               bounds, e.g. the shoulder at the end of an "arm_l" part that is nearer to the body
//   geometry    something measured from the mesh: the bounds' extremes (top of the head, tip of a beak, tip of a tail), the height of the
//               underside at the symmetry plane (the crotch of a humanoid), the ends of the model along a chain's axis
//   proportion  the template's default proportions of the model's bounds: an ESTIMATE. `strict` turns every estimate into an error.
//
// All bones rest with identity rotation: a bone is its head position, the local translation of a joint is head - parent head. Deterministic:
// only + - * / sqrt and ordered iteration.
#pragma once

#include <string>
#include <vector>

#include "fa/core/math.h"
#include "fa/core/types.h"
#include "fa/scene/mesh_store.h"
#include "fa/scene/rig_doc.h"

namespace fa {

enum class RigSource { Override, Part, Geometry, Proportion };
const char* rig_source_name(RigSource s);  // "override", "part", "geometry", "proportion"

struct RigBoneFit {
    std::string name;       // canonical: role[_index][_side]
    std::string role;
    int index = 0;          // 1-based among the bones of the same role and side; 0 when the template has only one
    std::string side;       // "", "l" or "r"
    std::string parent;     // "" for root
    int parentIndex = -1;   // index into RigFit::bones, always smaller than this bone's
    Vec3 head{};            // the joint, in the model's space
    Vec3 tail{};            // where the bone ends: its main child's head, or for a leaf the landmark "<name>.tail"
    bool leaf = true;
    RigSource headSource = RigSource::Proportion;
    RigSource tailSource = RigSource::Proportion;
    std::vector<std::string> parts;  // the model parts that placed it (part source) or that move with it (rigid binding)
};

struct RigFit {
    std::string templateName;
    std::vector<RigBoneFit> bones;  // parents before children; this order is the joint order of the .glb
    Vec3 bmin{}, bmax{};            // the model's bounds
    float symmetryX = 0;
    std::string symmetrySource;     // "document", "bounds"
    std::vector<std::string> unusedParts;  // model parts no bone looked at
    std::vector<std::string> warnings;     // each says what was noticed and what to do
    // How many landmarks (heads and leaf tails) came from each source.
    int overrides = 0, fromParts = 0, fromGeometry = 0, estimated = 0;
    int find(std::string_view bone) const;  // index of a bone by name, -1 when absent
};

// What the template's bones are for these options, without a model (names, roles, parents): rig.templates, the checks of `parts` and
// `landmarks`, and the editor's list. Parents come before children.
struct RigBoneInfo {
    std::string name, role, side, parent;
    int index = 0;
    bool leaf = true;
};
std::vector<RigBoneInfo> rig_template_bones(const RigDoc& doc);

// Checks what needs the template: the names in `parts` and `landmarks` (did you mean...), "<bone>.tail" only on leaf bones, the bones of a
// generic rig (parents, names, at most 64 bones in all).
std::vector<RigIssue> rig_check_doc(const RigDoc& doc);

// Fits the template. Fails, with a message that says what to add, when the document is wrong for the template, a part named in `parts` is not in
// the model, the rig needs more than 64 bones, or `strict` is set and a landmark could only be estimated.
Result<RigFit> fit_rig(const RigDoc& doc, const MeshData& model);

// The rest skeleton as JSON, for the commands and the editor: bones with role, index, side, parent, head, tail, sources and parts.
Json rig_fit_to_json(const RigFit& fit);

// Which bone every vertex of the mesh follows in the rigid binding (the "rigid" binding of the document; M59.2 replaces it with weights): the
// nearest bone, measured from the vertex to the bone's segment (head to tail), among the bones the vertex's part is bound to; vertices of a part
// no bone claims use every bone.
std::vector<std::uint16_t> rig_rigid_binding(const RigFit& fit, const MeshData& model);

}  // namespace fa
