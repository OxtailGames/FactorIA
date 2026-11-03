// The skeleton templates of rig documents (rig_doc.h) as data: for each bone its canonical name, parent, default proportions and the words of the
// model part names it recognises. Private to fa_scene: rig_fit.cpp fits them to a model, rig_doc.cpp only lists them.
#pragma once

#include <limits>
#include <string>
#include <vector>

#include "fa/core/math.h"
#include "fa/scene/rig_doc.h"
#include "fa/scene/rig_fit.h"

namespace fa::rig_detail {

constexpr float kNone = std::numeric_limits<float>::quiet_NaN();
inline bool has(float v) { return v == v; }

// A way a model part decides where a bone is. `mode`:
//   'X' 'Y' 'Z'  along that axis of the part's bounds, 0 = the minimum end, 1 = the maximum end; the other two coordinates are the part's centre
//   'L'          along the part's longest axis from the end nearer to the bone's default head (0) to the farther one (1): arms, legs, tails
//   'A'          at `aHead` / `aTail`: -1..1 around the centre of the part's bounds (generic bones)
// `head` and `tail` are where the bone's head and tail are along it (kNone = this hint does not place that one).
struct Hint {
    std::vector<std::string> words;  // normalised tokens that must all be in the part's name; empty with `exact`
    std::string exact;               // the whole part name (generic bones)
    char mode = 'Y';
    float head = kNone, tail = kNone;
    Vec3 aHead{}, aTail{};
    std::string ref;  // 'L': the bone whose default head tells which end of the part is nearer to the body ("" = the bone itself)
};

struct TBone {
    std::string name, role, side, parent;
    int index = 0;
    Vec3 prop{};  // default head as proportions of the model's bounds: x = signed fraction of the width from the symmetry plane (+ = character-left),
                  // y = fraction of the height, z = fraction of the depth from the back (0) to the front (1)
    bool hasTailProp = false;
    Vec3 tailProp{};  // default tail of a leaf bone, same proportions
    Vec3 tailExt{};   // per axis -1 / 0 / +1: the tail takes that coordinate from the model's minimum / maximum (geometry)
    bool under = false;  // head.y = height of the underside of the model at the symmetry plane (the crotch) + underOffset * height
    float underOffset = 0;
    std::string lerpA, lerpB;  // head = lerp of two landmarks ("bone" or "bone.tail"); empty = not a lerp bone
    float lerpT = 0;
    std::vector<Hint> hints;
    // set by the fit for chains and generic rigs
    bool hasAbs = false;
    Vec3 absHead{};
    RigSource absSource = RigSource::Geometry;
    bool hasAbsTail = false;
    Vec3 absTail{};
    RigSource absTailSource = RigSource::Geometry;
    std::vector<std::string> absParts;
};

// The tokens of a name: lowercase words split at non-alphanumerics and camelCase, digits dropped, "s" plurals stemmed; side words (l, left, r,
// right) are removed and returned in `side` ('l', 'r' or 0).
std::vector<std::string> name_tokens(const std::string& name, char* side = nullptr);

// The bones of the template for the document's options. `armsOut` / `wingsSpread` pick the pose variants (the fit resolves "auto" from the model).
// For chain templates the bones have no positions (the fit sets `abs*`); for generic the bones are the document's.
std::vector<TBone> build_template(const RigDoc& doc, bool armsOut, bool wingsSpread);

}  // namespace fa::rig_detail
