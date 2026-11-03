// Modifiers and generators of the model kernel (model_kernel.h; docs/MODELING.md, "Modifiers"): functions from a mesh to a mesh
// (mirror, array, bevel, subdivision, solidify, boolean, deformers, smoothing, weld, shading) and from profiles to a mesh (lathe, sweep,
// loft). GPU-free and deterministic like the rest of the kernel: + - * / and sqrt on floats, fa::det trigonometry, integer hashing for
// noise, no containers whose order depends on addresses. The same input gives the same bits on every platform.
//
// What a modifier keeps. Every triangle keeps the part (`triParts`) of the triangle it came from, so a model document's parts survive
// mirror, array, bevel, subdivision, solidify and boolean (a new triangle takes the part of its neighbour or of the operand it cuts);
// uv coordinates and vertex colours are carried the same way. Normals are recomputed where the shape changed (smoothing groups by angle,
// see ModelShadeMode) and moved with the surface where a deformer only bends it.
//
// Limits. A result with more than kModelMaxTriangles triangles is refused with a message that says what to lower: every modifier checks
// its output size BEFORE building it, so a typo (count 100000) fails at once instead of eating memory.
#pragma once

#include <string>
#include <vector>

#include "fa/scene/model_kernel.h"

namespace fa {

inline constexpr std::size_t kModelMaxTriangles = 1000000;  // in the result of any one node
inline constexpr std::size_t kModelMaxBooleanTriangles = 400000;  // in all the operands of one boolean together

// ---- placement and repetition ----------------------------------------------------------------------------------------------

struct ModelMirrorParams {
    int axis = 0;                // 0 = X, 1 = Y, 2 = Z: the plane is perpendicular to it
    float offset = 0;            // where the plane cuts the axis
    bool merge = true;           // vertices within `mergeDistance` of the plane are put ON it, with a normal that lies in it
    float mergeDistance = 0.001f;
};
// The mesh plus its mirror image. The mirrored triangles are turned so they still face out; the parts and colours are copied.
ModelMesh model_mirror(const ModelMesh& m, const ModelMirrorParams& p);

struct ModelArrayParams {
    int count = 2;                    // copies including the original
    Vec3 offset{1, 0, 0};             // step of the translation between one copy and the next
    bool relative = false;            // offset is in sizes of the mesh's bounding box
    Vec3 stepRotation{0, 0, 0};       // degrees added per copy ([x, y, z], the node rotation's order), about the origin
    Vec3 stepScale{1, 1, 1};          // factor applied per copy, about the origin
    bool merge = false;               // join vertices of neighbouring copies that are within `mergeDistance`
    float mergeDistance = 0.001f;
};
// Copy k is the mesh moved by the k-th power of (offset, stepRotation, stepScale). count * triangles must stay within kModelMaxTriangles
// (the caller checks, with the node's name in the message).
ModelMesh model_array(const ModelMesh& m, const ModelArrayParams& p);

struct ModelRadialArrayParams {
    int count = 6;
    int axis = 1;                     // axis the copies turn about
    float angle = 360;                // 360 = a full circle (the copies are evenly spaced, the last is not on the first); less: first at 0, last at `angle`
    Vec3 center{0, 0, 0};             // a point the axis passes through
    bool faceCenter = true;           // false: copies are moved around the circle but keep their orientation
    bool merge = false;
    float mergeDistance = 0.001f;
};
ModelMesh model_radial_array(const ModelMesh& m, const ModelRadialArrayParams& p);

// ---- surface modifiers -----------------------------------------------------------------------------------------------------

struct ModelBevelParams {
    float width = 0.05f;        // how far the bevel reaches from the edge, along each face
    int segments = 2;           // rows of the strip that replaces the edge (1 = a flat chamfer)
    float angle = 30;           // edges whose faces turn by more than this many degrees are bevelled
    float roundness = 1;        // 0 = straight chamfer rows with flat shading, 1 = a rounded profile with the normals blending between the faces
};
// Rounds or chamfers the sharp edges of a mesh: each face next to a sharp edge is pulled back from it by `width` and a strip of `segments`
// rows takes the edge's place. Where three or more bevelled edges meet, a corner patch fills the gap. The big faces keep their own normals
// (so they stay flat); only the strips and patches blend. An edge that ends inside a smooth surface, or touches a vertex the bevel
// cannot be built at (a non-manifold one), is left sharp. Fails when `width` is more than the faces can give (a face would turn inside
// out): the message says how wide it can be. `bevelledEdges` (optional) receives how many edges were bevelled.
Result<ModelMesh> model_bevel(const ModelMesh& m, const ModelBevelParams& p, std::size_t* bevelledEdges = nullptr);

struct ModelSubdivideParams {
    int levels = 1;
    float creaseAngle = 180;    // edges whose faces turn by more than this many degrees (and open boundaries) stay sharp; 180 = none
};
// Catmull-Clark subdivision. Triangles that were a quad (coplanar neighbours of one part) are merged back into quads first, so a box
// subdivides like a box. uv and colours are interpolated linearly over each face. Output is triangles.
ModelMesh model_subdivide(const ModelMesh& m, const ModelSubdivideParams& p);
// The number of triangles `levels` of subdivision of `m` would give, at most (an upper bound, used for the size check).
std::size_t model_subdivide_triangle_bound(const ModelMesh& m, int levels);

struct ModelSolidifyParams {
    float thickness = 0.05f;
    float offset = -1;          // -1: the original surface is the outside and the thickness grows against its normals; 1: it grows along them; 0: centred
    bool even = true;           // stretch the offset at sharp corners so the wall keeps its thickness
};
// Gives a surface thickness: a second, inverted surface offset along the vertex normals, and walls along open boundaries. A closed mesh
// becomes a hollow shell.
ModelMesh model_solidify(const ModelMesh& m, const ModelSolidifyParams& p);

enum class ModelBooleanMode { Union, Difference, Intersection };
// The first operand combined with the others: union of all, the first MINUS all the others, or what all have in common. Operands must be
// closed solids (no holes, no edge shared by more than two faces); the error says which one is not. Part, uv, colour and normals come
// from the operand each triangle was cut from (the faces a difference leaves inside the first operand get the normals of the operand
// that was subtracted, turned around). Backed by Manifold (Apache-2.0, external/manifold), exact for coplanar and touching faces.
// `names` (optional, one per operand) is how the messages call each operand, e.g. "/nodes/0/children/1"; by default "operand 2".
// An operand with no triangles is left out (the intersection with it is empty, which returns an empty mesh).
Result<ModelMesh> model_boolean(const std::vector<ModelMesh>& operands, ModelBooleanMode mode, const std::vector<std::string>& names = {});

// ---- deformers -------------------------------------------------------------------------------------------------------------

struct ModelBendParams {
    int axis = 1;               // the length axis the model bends along
    float angle = 90;           // degrees over [from, to]
    float direction = 0;        // degrees: which way it bends, 0 = towards the first of the two other axes (see docs)
    bool hasFrom = false, hasTo = false;
    float from = 0, to = 0;     // the stretch of the axis that bends; the model's own extent when not given
};
ModelMesh model_bend(const ModelMesh& m, const ModelBendParams& p);

struct ModelTwistParams {
    int axis = 1;
    float angle = 90;           // degrees over [from, to]; beyond `to` the model stays turned by all of it
    bool hasFrom = false, hasTo = false;
    float from = 0, to = 0;
};
ModelMesh model_twist(const ModelMesh& m, const ModelTwistParams& p);

struct ModelTaperParams {
    int axis = 1;
    float startScale = 1, endScale = 0.5f;  // the cross-section scale at `from` and at `to`
    bool hasFrom = false, hasTo = false;
    float from = 0, to = 0;
};
ModelMesh model_taper(const ModelMesh& m, const ModelTaperParams& p);

struct ModelNoiseParams {
    float amplitude = 0.05f;    // metres, the largest displacement of one octave
    float frequency = 3;        // noise features per metre
    int octaves = 1;            // each octave doubles the frequency and halves the amplitude
    int seed = 0;
    bool alongNormal = true;    // displace along the (averaged) surface normal; false: a 3D vector noise
};
// Value noise on an integer lattice (hash of the cell and the seed). The same position always gets the same displacement, so seams stay
// closed.
ModelMesh model_noise(const ModelMesh& m, const ModelNoiseParams& p);
// The lattice noise itself, in -1..1: the same function `noise` displaces with, for kernel code (the sdf's noise) that needs a field of it.
float model_value_noise(Vec3 p, std::uint32_t seed);

// ---- smoothing, welding and shading ------------------------------------------------------------------------------------------

struct ModelSmoothParams {
    int iterations = 4;
    float factor = 0.5f;        // 0..1 how far each vertex moves towards the average of its neighbours per step
    bool taubin = true;         // a second, opposite step per iteration so the model does not shrink
    bool lockBoundary = true;   // vertices on an open boundary stay
    float sharpAngle = 180;     // vertices on an edge turning more than this many degrees stay; 180 = none
};
ModelMesh model_smooth(const ModelMesh& m, const ModelSmoothParams& p);

struct ModelWeldParams {
    float distance = 0.001f;
};
// Moves vertices closer than `distance` to their common centre, merges those that are then identical (position, normal, uv, colour) and
// drops the triangles that collapsed.
ModelMesh model_weld(const ModelMesh& m, const ModelWeldParams& p);

enum class ModelShadeMode { Flat, Smooth, Auto };
struct ModelShadeParams {
    ModelShadeMode mode = ModelShadeMode::Auto;
    float angle = 30;           // Auto: corners of faces turning less than this share a normal
};
ModelMesh model_shade(const ModelMesh& m, const ModelShadeParams& p);

// ---- generators from profiles ------------------------------------------------------------------------------------------------

struct ModelLatheParams {
    std::vector<Vec2> profile;  // (radius, height); radius >= 0
    int segments = 24;
    float angle = 360;          // degrees swept about the Y axis, from +Z towards +X (as the primitives' seam)
    bool cap = true;            // close an end of the profile that is off the axis with a flat disc
    float creaseAngle = 40;     // corners of the profile turning more than this stay hard
};
// The profile is walked so its front is on the right-hand side (radius to the right, height up); a profile given the other way round is
// reversed. Where a profile point is on the axis it is one vertex.
ModelMesh model_lathe(const ModelLatheParams& p);

struct ModelSweepParams {
    std::vector<Vec2> profile;  // a closed polygon, at least 3 points
    std::vector<Vec3> path;     // at least 2 points
    bool smooth = true;         // Catmull-Rom through the path points (else straight pieces with mitred corners)
    int pathSegments = 8;       // pieces per span of a smooth path
    bool closed = false;        // the path comes back to its first point
    float scaleStart = 1, scaleEnd = 1;
    float twist = 0;            // degrees over the whole path
    bool cap = true;
    float creaseAngle = 50;
};
Result<ModelMesh> model_sweep(const ModelSweepParams& p);

struct ModelLoftParams {
    std::vector<std::vector<Vec3>> sections;  // every section has the same number of points
    bool closed = true;         // each section is a loop
    bool smooth = true;         // Catmull-Rom through the sections (needs three or more)
    int steps = 4;              // rows between two sections
    bool cap = true;
    float creaseAngle = 50;
};
Result<ModelMesh> model_loft(const ModelLoftParams& p);

}  // namespace fa
