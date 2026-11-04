// Rig documents (`*.rig.json`, format "factoria.rig/1", schemas/rig.schema.json, docs/RIGGING.md): a skeleton for a model document, written as
// a template (humanoid, quadruped, bird, tail, chain or generic) plus the hints that fit it to the model: which model parts are which
// bone, where a landmark really is. The document holds the intent; the joint positions are computed from the model every time (rig_fit.h),
// so the same document and model give the same bytes on every platform. `rig.bake` turns them into a skinned .glb (rig_glb.h).
//
// CANONICAL BONE NAMES. Every template names its bones `<role>[_<index>][_<side>]`: the role says what the bone is (root, spine, neck, head,
// clavicle, arm_upper, arm_lower, hand, thigh, shin, foot, toe, tail, chain...), the index (1-based) is there only when the template has more
// than one bone of that role and side, the side is `l` or `r` (character-left is +X, the character looks towards +Z). The (role, index, side)
// triple is what retargeting between templates maps (docs/RIGGING.md, "Canonical bones"). Every template's top bone is `root`.
//
// This file is the document and the catalog of templates. GPU-free, in fa_scene.
#pragma once

#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/types.h"
#include "fa/scene/rig_skin_doc.h"

namespace fa {

inline constexpr const char* kRigDocFormat = "factoria.rig/1";
inline constexpr const char* kRigDocSuffix = ".rig.json";
inline constexpr std::size_t kRigMaxBones = 64;  // joints one glTF skin may have for the renderer (render3d skinning palette)

// One problem of a document: where (a JSON pointer such as "/options/spine"), what is wrong, and how to fix it.
struct RigIssue {
    std::string pointer;
    std::string message;
    std::string hint;
};

// One option of a template (`options` of the document).
struct RigOptionInfo {
    std::string key;
    std::string type;  // "integer", "choice" or "boolean"
    std::string doc;
    Json def;          // the default
    std::optional<int> min, max;       // integers
    std::vector<std::string> choices;  // choices
};

struct RigTemplateInfo {
    std::string name;
    std::string doc;                  // what it is for, the pose it assumes and which parts it looks for
    std::vector<RigOptionInfo> options;
    std::vector<std::string> partWords;  // the words in a part name the fit recognises (documented, one line per bone group)
};
// The templates, in the order the docs describe them: humanoid, quadruped, bird, tail, chain, generic.
const std::vector<RigTemplateInfo>& rig_templates();
const RigTemplateInfo* find_rig_template(std::string_view name);

// A bone of a `generic` rig. Parents come before their children; a bone with no `parent` hangs from `root`, which every rig has.
struct RigGenericBone {
    std::string name;    // canonical name: lowercase letters, digits and underscores
    std::string parent;  // "" = root
    std::string role;    // retargeting role; "" = the name
    std::string part;    // the model part this bone moves; its joint sits at `anchor` of the part's bounds
    Vec3 anchor{0, 0, 0};      // where in the part's bounds the joint is: -1..1 per axis around the centre (0,0,0 = centre; 0,-1,0 = bottom)
    std::optional<Vec3> tailAnchor;  // the same for the end of a bone with no children
    std::string pointer;       // "/bones/2"
};

struct RigDoc {
    std::string doc;          // what the rig is for
    std::string model;        // the model document it fits, project-relative (*.model.json)
    std::string templateName;
    Json options = Json::object();  // checked, defaults filled in for the template
    std::vector<std::pair<std::string, std::vector<std::string>>> parts;  // bone name -> the model parts that decide where it is
    std::vector<std::pair<std::string, Vec3>> landmarks;                 // explicit joint positions in the model's space; "<bone>.tail" is the end of a leaf bone
    std::optional<float> symmetryX;   // the x of the symmetry plane; left out: the centre of the model's bounds
    bool strict = false;              // a landmark that could only be estimated from proportions is an error
    RigSkinSettings skin;             // how the .glb binds vertices to bones (rig_skin_doc.h): the method per part and the edits
    std::string outputPath;           // where rig.bake writes the .glb; "" = next to the document
    std::vector<RigGenericBone> bones;  // generic only
    int optionInt(std::string_view key, int fallback) const;
    std::string optionString(std::string_view key, std::string_view fallback) const;
    bool optionBool(std::string_view key, bool fallback) const;
};

// Reads the `skin` section (rig_skin_doc.cpp): every problem is appended to `issues` with its pointer under "/skin".
void parse_rig_skin(const Json& json, RigSkinSettings& out, std::vector<RigIssue>& issues);
// Checks the bone names of the skin section against the template's bones ("did you mean").
std::vector<RigIssue> rig_check_skin(const RigDoc& doc, const std::vector<std::string>& boneNames);

// Reads a document. Every problem found is listed in `issues` (not only the first), each with its JSON pointer, what is wrong and the fix.
// `file` only names the document in the message of the error that is returned for the first. The bone and part names are checked against the
// template and the model by rig_check_doc / fit_rig (rig_fit.h), which know them.
Result<RigDoc> parse_rig_doc(const Json& json, std::string_view file = {}, std::vector<RigIssue>* issues = nullptr);
Result<RigDoc> load_rig_doc(std::string_view path, std::vector<RigIssue>* issues = nullptr);
// The JSON form of a document, ready to save (the fields in the order the docs show them; defaults of the options left in).
Json rig_doc_to_json(const RigDoc& doc);
// The JSON schema of the format; schemas/rig.schema.json is this, written out (a test keeps them equal).
Json rig_doc_schema();

// A fresh document for a template (the starting point rig.create writes). `generic` with `partNames` gets one bone per part under `root`.
RigDoc make_rig_doc(const std::string& model, const std::string& templateName, const std::vector<std::string>& partNames = {});

}  // namespace fa
