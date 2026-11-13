// The `skin` section of a rig document (docs/RIGGING.md, "Skin weights"): how the vertices of the model are bound to the bones. It is part of the
// recipe: the method per part, the knobs of the automatic weights and the list of edits the `skin3d.*` commands append. The weights themselves are
// never stored, they are computed from the document and the model every time (rig_skin.h), so a re-bake gives the same bytes.
//
//   "skin": {
//     "method": "auto",            // auto | heat | voxel | rigid: the default for every part
//     "maxInfluences": 4,          // bones per vertex, 1..4
//     "smooth": 1,                 // smoothing passes over the automatic weights
//     "maxHops": 2,                // a vertex is not weighted to bones further than this many bones from its strongest one
//     "locality": 1,               // heat diffusion: higher = weights hug each bone, shorter blends
//     "parts": {"sleeve": {"method": "rigid", "bone": "arm_upper_l"}},
//     "edits": [{"op": "set", "bone": "hand_l", "weight": 1, "part": "glove"}]
//   }
//
// GPU-free, in fa_scene. The parser and the check of bone names are declared in rig_doc.h (they use RigIssue).
#pragma once

#include <string>
#include <utility>
#include <vector>

#include "fa/core/json.h"

namespace fa {

// One edit of the weights, applied in order after the automatic weights (and so surviving a re-bake). The vertices it works on are those of
// `parts` and of the faces `select` matches (both given: the vertices in both; neither: every vertex).
struct RigSkinEdit {
    std::string op;           // set, add, smooth, normalize, limit, mirror
    std::string bone;         // set, add: the bone whose weight changes
    std::string from;         // mirror: "l" or "r", the side that is copied to the other
    float weight = 1;         // set: the weight the bone gets, 0..1 (the others share the rest in their proportions)
    float amount = 0;         // add: added to the bone's weight (negative takes weight away), -1..1
    float strength = 0.5f;    // smooth: how far each pass moves a vertex to the average of its neighbours, 0..1
    float threshold = 0.01f;  // normalize: influences under this weight are dropped, 0..0.5
    int iterations = 1;       // smooth: passes, 1..50
    int max = 4;              // limit: influences kept per vertex, 1..4
    std::vector<std::string> parts;  // model parts the edit works on
    Json
        select;  // a face query of the model document (model_select.h), evaluated on the model the rig fits; null = none
    std::string pointer;  // "/skin/edits/2"
};

struct RigSkinPart {
    std::string method;  // "" = the document's default; auto, heat, voxel or rigid
    std::string
        bone;  // the bone this part follows ("" = the part's own bones from the fit); rigid: the one bone, heat and voxel: the bone the part is centred on
};

struct RigSkinSettings {
    std::string method = "auto";
    int maxInfluences = 4;
    int smooth = 1;
    int maxHops = 2;
    float locality = 1;
    std::vector<std::pair<std::string, RigSkinPart>> parts;  // model part -> how it is bound
    std::vector<RigSkinEdit> edits;
    bool is_default() const;  // nothing to write
};

// What each op and method is, for the commands, the schema and the docs.
struct RigSkinOpInfo {
    std::string op, doc;
};
const std::vector<RigSkinOpInfo>& rig_skin_ops();
const std::vector<RigSkinOpInfo>& rig_skin_methods();

// The document's form; null when everything is at its default.
Json rig_skin_to_json(const RigSkinSettings& skin);
// One edit as it is written in the document.
Json rig_skin_edit_to_json(const RigSkinEdit& edit);
// The JSON schema of the `skin` section.
Json rig_skin_schema();

}  // namespace fa
