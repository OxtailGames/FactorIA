// Model documents: the catalog of operations, reading and checking a document, finding nodes, and the JSON schema built from the catalog.
// Evaluation is model_eval.cpp.
#include <algorithm>
#include <cmath>
#include <format>
#include <map>
#include <set>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/scene/model_doc.h"

namespace fa {

namespace {

// ---- the catalog -------------------------------------------------------------------------------------------------------------

ModelFieldInfo field(std::string key, std::string type, std::string doc, std::optional<Json> def = std::nullopt, std::optional<double> mn = std::nullopt,
                     std::optional<double> mx = std::nullopt) {
    ModelFieldInfo f;
    f.key = std::move(key);
    f.type = std::move(type);
    f.doc = std::move(doc);
    f.def = std::move(def);
    f.min = mn;
    f.max = mx;
    return f;
}
ModelFieldInfo number(std::string key, std::string doc, double def, double mn, double mx) {
    return field(std::move(key), "number", std::move(doc), Json(def), mn, mx);
}
ModelFieldInfo number_opt(std::string key, std::string doc, double mn, double mx) {
    return field(std::move(key), "number", std::move(doc), std::nullopt, mn, mx);
}
ModelFieldInfo integer(std::string key, std::string doc, int def, int mn, int mx) {
    return field(std::move(key), "integer", std::move(doc), Json(def), mn, mx);
}
ModelFieldInfo integer_opt(std::string key, std::string doc, int mn, int mx) {
    return field(std::move(key), "integer", std::move(doc), std::nullopt, mn, mx);
}
ModelFieldInfo boolean(std::string key, std::string doc, bool def) { return field(std::move(key), "boolean", std::move(doc), Json(def)); }

ModelOpInfo prim(std::string op, std::string doc, std::vector<ModelFieldInfo> fields) {
    return {std::move(op), "primitive", std::move(doc), std::move(fields)};
}

// A list field: `points2` / `points3` of minItems..maxItems entries, or `rings` of minItems..maxItems sections of innerMin..innerMax points.
ModelFieldInfo list_field(std::string key, std::string type, std::string doc, int minItems, int maxItems, double mn, double mx, bool required = true) {
    ModelFieldInfo f = field(std::move(key), std::move(type), std::move(doc), std::nullopt, mn, mx);
    f.required = required;
    f.minItems = minItems;
    f.maxItems = maxItems;
    return f;
}
ModelFieldInfo choice(std::string key, std::string doc, std::vector<std::string> choices, const std::string& def) {
    ModelFieldInfo f = field(std::move(key), "choice", std::move(doc), Json(def));
    f.choices = std::move(choices);
    return f;
}
ModelFieldInfo axis_field(std::string key, std::string doc, const std::string& def) { return choice(std::move(key), std::move(doc), {"x", "y", "z"}, def); }

// A modifier wraps its `children`: they are evaluated and merged like a group's, then the operation changes that mesh.
ModelOpInfo modifier(std::string op, std::string doc, std::vector<ModelFieldInfo> fields, const std::string& childrenDoc) {
    ModelFieldInfo children = field("children", "nodes", childrenDoc);
    fields.push_back(std::move(children));
    return {std::move(op), "modifier", std::move(doc), std::move(fields)};
}

constexpr double kMaxSize = 1000.0;
constexpr double kMinSize = 0.001;

std::vector<ModelOpInfo> build_ops() {
    std::vector<ModelOpInfo> ops;
    ops.push_back(prim("box", "A box centred on its origin; its faces are grids when `segments` is above 1. The size is X (width), Y (height), Z (depth).",
                       {field("size", "size3", "Width, height and depth in metres: one number for a cube, or [x, y, z].", Json::array({1, 1, 1}), kMinSize, kMaxSize),
                        field("segments", "count3", "Subdivisions along X, Y and Z: one integer, or [x, y, z]. Raise it when a later step bends or deforms the box.",
                              Json::array({1, 1, 1}), 1, 64)}));
    ops.push_back(prim("rounded_box", "A box with rounded edges and corners, centred on its origin.",
                       {field("size", "size3", "Width, height and depth in metres: one number for a cube, or [x, y, z].", Json::array({1, 1, 1}), kMinSize, kMaxSize),
                        number("radius", "Radius of the edges and corners in metres. Above half of the smallest side it is cut down to half of it (a pill or a ball).", 0.1, kMinSize, kMaxSize),
                        integer("segments", "Quads in each rounded corner arc: 1 is a bevel, 4 is smooth.", 4, 1, 16)}));
    ops.push_back(prim("cylinder", "An upright cylinder (a frustum when `radiusTop` differs) centred on its origin, with flat caps, its axis along Y.",
                       {number("radius", "Radius of the bottom, in metres.", 0.5, 0, kMaxSize),
                        number_opt("radiusTop", "Radius of the top. Left out: the same as `radius` (a plain cylinder). 0 makes a point (prefer `cone`).", 0, kMaxSize),
                        number("height", "Height along Y in metres.", 1, kMinSize, kMaxSize),
                        integer("segments", "Sides around the axis.", 24, 3, 256),
                        integer("heightSegments", "Rings along the side.", 1, 1, 64),
                        boolean("capBottom", "Close the bottom with a disc.", true),
                        boolean("capTop", "Close the top with a disc.", true)}));
    ops.push_back(prim("cone", "A cone with its point up (a frustum when `radiusTop` is above 0), centred on its origin, its axis along Y.",
                       {number("radius", "Radius of the base, in metres.", 0.5, kMinSize, kMaxSize),
                        number("radiusTop", "Radius of the top: 0 is a sharp point, above 0 cuts the tip off.", 0, 0, kMaxSize),
                        number("height", "Height along Y in metres.", 1, kMinSize, kMaxSize),
                        integer("segments", "Sides around the axis.", 24, 3, 256),
                        integer("heightSegments", "Rings along the side.", 1, 1, 64),
                        boolean("cap", "Close the base with a disc.", true)}));
    ops.push_back(prim("sphere", "A UV sphere centred on its origin, poles on the Y axis.",
                       {number("radius", "Radius in metres.", 0.5, kMinSize, kMaxSize),
                        integer("segments", "Meridians: sides around the vertical axis.", 24, 3, 256),
                        integer_opt("rings", "Parallels from pole to pole. Left out: half of `segments`.", 2, 256)}));
    ops.push_back(prim("capsule", "A cylinder with a hemisphere at each end, upright, centred on its origin; `height` is tip to tip.",
                       {number("radius", "Radius of the cylinder and of the ends, in metres.", 0.5, kMinSize, kMaxSize),
                        number("height", "Tip to tip along Y, in metres. At least twice the radius (equal: a sphere).", 2, 2 * kMinSize, kMaxSize),
                        integer("segments", "Sides around the axis.", 24, 3, 256),
                        integer("rings", "Rings in each hemisphere.", 8, 1, 64),
                        integer("heightSegments", "Rings along the straight part.", 1, 1, 64)}));
    ops.push_back(prim("torus", "A ring (a doughnut) lying flat in the XZ plane, centred on its origin, its hole along Y.",
                       {number("radius", "Radius of the ring: from the centre to the middle of the tube, in metres.", 0.5, kMinSize, kMaxSize),
                        number("tube", "Radius of the tube, in metres. At most `radius`.", 0.15, kMinSize, kMaxSize),
                        integer("segments", "Steps around the ring.", 32, 3, 256),
                        integer("sides", "Sides around the tube.", 16, 3, 128)}));
    ops.push_back(prim("grid", "A flat rectangle in the XZ plane facing +Y, centred on its origin: a floor, a water surface, a cloth to bend. One-sided.",
                       {number("width", "Size along X in metres.", 1, kMinSize, kMaxSize),
                        number("depth", "Size along Z in metres.", 1, kMinSize, kMaxSize),
                        field("segments", "count2", "Cells along X and Z: one integer, or [x, z].", Json::array({1, 1}), 1, 256)}));
    ops.push_back(prim("stairs", "A solid staircase, centred on its bounding box. It climbs towards -Z: the lowest step is at +Z, the top at -Z.",
                       {integer("steps", "Number of steps.", 6, 1, 128),
                        number("width", "Size along X in metres.", 1, kMinSize, kMaxSize),
                        number("height", "Height of the top step above the bottom, in metres.", 1, kMinSize, kMaxSize),
                        number("depth", "Length along Z in metres.", 1.5, kMinSize, kMaxSize)}));
    ops.push_back(prim("arch", "A wall with an arched doorway through it (round top), centred on its bounding box (use `align: \"bottom\"` to stand it on y = 0). The wall is X wide, Y high and Z thick; the doorway goes through along Z.",
                       {number("width", "Width of the wall (X) in metres.", 2, kMinSize, kMaxSize),
                        number("height", "Height of the wall (Y) in metres.", 2.5, kMinSize, kMaxSize),
                        number("depth", "Thickness of the wall (Z) in metres.", 0.4, kMinSize, kMaxSize),
                        number("openingWidth", "Width of the doorway in metres. Less than `width`.", 1, kMinSize, kMaxSize),
                        number("openingHeight", "Height of the doorway from the bottom edge to the top of the arch, in metres. At least half of `openingWidth`, less than `height`.", 1.8, kMinSize, kMaxSize),
                        integer("segments", "Straight pieces in the half circle of the arch.", 12, 2, 64)}));
    ops.push_back(prim("pipe", "A tube: a cylinder with a round hole through it, upright, centred on its origin, open at both ends.",
                       {number("radius", "Outer radius in metres.", 0.5, 2 * kMinSize, kMaxSize),
                        number("innerRadius", "Radius of the hole in metres. Less than `radius`.", 0.4, kMinSize, kMaxSize),
                        number("height", "Height along Y in metres.", 1, kMinSize, kMaxSize),
                        integer("segments", "Sides around the axis.", 24, 3, 256)}));
    {
        ModelFieldInfo text = field("text", "string", "The text. Several lines with \"\\n\". At most 200 characters.");
        text.required = true;
        ModelFieldInfo anchor = field("anchor", "choice", "Where the text sits against the origin along X: \"start\" (it begins there), \"middle\" or \"end\".", Json("middle"));
        anchor.choices = {"start", "middle", "end"};
        ops.push_back(prim("text", "Text as a solid, made from the engine's own font data (no system fonts): the letters stand in the XY plane, readable from +Z, thickness along Z centred on 0, the baseline of the first line at y = 0. Holes (the inside of an O) are cut out.",
                           {text,
                            field("font", "string", "\"\" is the built-in DejaVu Sans; \"builtin:serif\", \"builtin:hand\", \"builtin:display\", \"builtin:blackletter\" and \"builtin:pixel\" are the other built-in faces; or a project .ttf / .otf.", Json("")),
                            number("size", "Height of an em in metres (a capital letter is about 0.7 of it).", 1, kMinSize, kMaxSize),
                            number("depth", "Thickness along Z in metres.", 0.2, kMinSize, kMaxSize),
                            integer("curveSegments", "Straight pieces per curve of a letter.", 6, 1, 32),
                            anchor,
                            number("letterSpacing", "Extra space after every letter, in ems.", 0, -1, 5),
                            number("lineSpacing", "Distance between lines, as a multiple of the font's own.", 1, 0.1, 5)}));
    }

    // ---- generators from profiles -------------------------------------------------------------------------------------------------
    ops.push_back(prim("lathe", "A profile turned about the Y axis: a vase, a chess piece, a column, a bottle. `profile` is a list of [radius, height] points walked from one end to the other (either way round); the turn goes from +Z towards +X like the round primitives, and a point on the axis (radius 0) is a single vertex. It is a primitive: `align` places it, and it can be wrapped in a modifier.",
                       {list_field("profile", "points2", "The outline as [radius, height] points in metres, at least 2, e.g. [[0,0],[0.4,0],[0.3,0.8],[0.1,1]]. Radius is 0 or more; height is along Y and may be negative. Corners of the outline stay sharp when they turn more than `creaseAngle`.", 2, 256, -kMaxSize, kMaxSize),
                        integer("segments", "Steps around the axis (the whole turn when `angle` is 360).", 24, 3, 256),
                        number("angle", "Degrees turned, from +Z towards +X. 360 closes the ring; less leaves an open wedge.", 360, 1, 360),
                        boolean("cap", "Close an end of the outline that is off the axis with a flat disc, and the two ends of a partial turn with a flat wall. false leaves a hole there (an open vase, a bowl).", true),
                        number("creaseAngle", "Degrees: corners of the outline that turn more than this stay hard, smaller ones are shaded smooth.", 40, 0, 180)}));
    ops.push_back(prim("sweep", "A closed profile moved along a path: a pipe, a rail, a rope, a road edge, a handle. The profile is drawn in a plane (x to the right of the direction of travel, y up) and kept perpendicular to the path; frames are rotation-minimising, so a path with no twist of its own gives a surface with none. It is a primitive: `align` places it.",
                       {list_field("profile", "points2", "The closed cross-section as [x, y] points in metres, at least 3, in either direction round: a square [[-0.1,-0.1],[0.1,-0.1],[0.1,0.1],[-0.1,0.1]], a circle of many points.", 3, 256, -kMaxSize, kMaxSize),
                        list_field("path", "points3", "The points to follow, [x, y, z] in metres, at least 2 and no two in a row in the same place.", 2, 256, -kMaxSize, kMaxSize),
                        boolean("smooth", "true: a smooth curve through the path points (Catmull-Rom); false: straight pieces with mitred corners.", true),
                        integer("pathSegments", "Pieces per span of a smooth path.", 8, 1, 64),
                        boolean("closed", "The path comes back to its first point (a ring): the ends are joined and there are no caps. Needs 3 or more path points.", false),
                        number("scaleStart", "Scale of the profile at the start of the path (the end gets `scaleEnd`, in between it changes steadily).", 1, 0.001, 1000),
                        number("scaleEnd", "Scale of the profile at the end of the path.", 1, 0.001, 1000),
                        number("twist", "Degrees the profile turns about the path over its whole length.", 0, -7200, 7200),
                        boolean("cap", "Close the two ends of an open path with a flat face.", true),
                        number("creaseAngle", "Degrees: edges turning more than this stay hard, smaller ones are shaded smooth.", 50, 0, 180)}));
    {
        ModelFieldInfo sections = list_field("sections", "rings", "The cross-sections in order, each a list of [x, y, z] points in metres; every section has the same number of points (point i of one is joined to point i of the next), in the same order round. e.g. a square at y = 0 and a smaller one at y = 1.", 2, 64, -kMaxSize, kMaxSize);
        sections.innerMinItems = 2;
        sections.innerMaxItems = 256;
        ops.push_back(prim("loft", "A skin through several cross-sections: a hull, a bottle that goes from a square base to a round neck, a wing. Section i is joined to section i+1 point by point; the surface passes through every section (a smooth curve through three or more, straight pieces between two). It is a primitive: `align` places it.",
                           {sections,
                            boolean("closed", "Each section is a loop (its last point joins its first). false: an open ribbon.", true),
                            boolean("smooth", "A smooth curve through the sections (Catmull-Rom; needs three or more). false: straight between sections.", true),
                            integer("steps", "Rows between two sections.", 4, 1, 64),
                            boolean("cap", "Close the first and last section with a flat face (loops only).", true),
                            number("creaseAngle", "Degrees: edges turning more than this stay hard, smaller ones are shaded smooth.", 50, 0, 180)}));
    }

    // ---- modifiers (they wrap their children) ---------------------------------------------------------------------------------------
    ops.push_back(modifier("boolean", "Combines the solids made by its children: union (all of them together), difference (the first enabled child minus all the others) or intersection (only what all have in common). Each child is one operand with its own transform; a child that is a group is merged into one solid first. Every operand must be a closed solid with its faces out (box, sphere, cylinder with caps, torus, lathe, another boolean...); the error names the operand that is not. Exact for faces that touch or lie in the same plane. Parts, uvs and colours stay with the surface they were on; the new faces cut inside the first operand by a difference take the part and material of the operand that cut them.",
                           {choice("mode", "\"union\", \"difference\" (the first child minus the rest) or \"intersection\".", {"union", "difference", "intersection"}, "union")},
                           "The operands, in order. For a difference the first is the solid that is cut and the others are the cutters. At most 400000 triangles together."));
    ops.push_back(modifier("mirror", "Adds the mirror image of its children across a plane: model half a face, a car or a column and mirror it. The mirrored copy is turned so its faces still point out and keeps the parts, uvs and colours.",
                           {axis_field("axis", "The plane is perpendicular to this axis: \"x\" mirrors left-right across x = `offset`.", "x"),
                            number("offset", "Where the plane cuts the axis, in metres.", 0, -kMaxSize, kMaxSize),
                            boolean("merge", "Vertices within `mergeDistance` of the plane are put exactly on it and joined to their copy, so the two halves become one surface with no seam. false keeps them apart.", true),
                            number("mergeDistance", "Metres from the plane within which `merge` acts.", 0.001, 0, 1)},
                           "The nodes to mirror; they are merged into one mesh first."));
    ops.push_back(modifier("array", "Repeats its children `count` times along a step: a fence, a row of windows, stairs of boxes, a colonnade. Copy k is the children moved by k steps; with a rotation or scale per step the copies spiral or shrink.",
                           {integer("count", "Copies including the original. count x the triangles of the children must stay under 1000000.", 2, 1, 4096),
                            field("offset", "vec3", "Step between one copy and the next, [x, y, z] in metres (or in sizes of the children's bounding box when `relative`).", Json::array({1, 0, 0}), -kMaxSize, kMaxSize),
                            boolean("relative", "true: `offset` is a multiple of the bounding box size of the children ([1, 0, 0] puts the copies edge to edge along X).", false),
                            field("stepRotation", "vec3", "Degrees added per copy, [pitch (X), yaw (Y), roll (Z)], about the origin of the children.", Json::array({0, 0, 0}), -3600, 3600),
                            field("stepScale", "size3", "Factor applied per copy, a number or [x, y, z]: 0.9 makes each copy 10% smaller than the one before.", Json::array({1, 1, 1}), 0.01, 100),
                            boolean("merge", "Join vertices of neighbouring copies that are within `mergeDistance` (copies that touch become one surface).", false),
                            number("mergeDistance", "Metres within which `merge` joins vertices.", 0.001, 0, 1)},
                           "The nodes to repeat; they are merged into one mesh first."));
    ops.push_back(modifier("radial_array", "Repeats its children around an axis: wheel spokes, columns round a fountain, gear teeth, petals. Copy k is turned by k steps of angle/count (360 degrees: the last copy is not on the first).",
                           {integer("count", "Copies including the original.", 6, 1, 1024),
                            axis_field("axis", "The axis the copies turn about.", "y"),
                            number("angle", "Degrees from the first copy to the last: 360 spreads them evenly round a full circle; less (90 with 4 copies) puts the first at 0 and the last at `angle`.", 360, 0.001, 360),
                            field("center", "vec3", "A point the axis passes through, [x, y, z] in metres.", Json::array({0, 0, 0}), -kMaxSize, kMaxSize),
                            boolean("faceCenter", "true: each copy turns with the circle (spokes). false: the copies are moved round the circle but keep their orientation (all the chairs face the same way).", true),
                            boolean("merge", "Join vertices of neighbouring copies within `mergeDistance`.", false),
                            number("mergeDistance", "Metres within which `merge` joins vertices.", 0.001, 0, 1)},
                           "The nodes to repeat; they are merged into one mesh first."));
    ops.push_back(modifier("bevel", "Rounds or chamfers the sharp edges of its children: edges whose two faces turn by more than `angle` are replaced by a strip of `segments` rows, so the edge catches light. Big faces stay flat; the strips are shaded smooth. An edge that ends inside a smooth surface is left sharp.",
                           {number("width", "How far the bevel reaches from the edge along each face, in metres. Too wide for the faces (a face would turn inside out) fails with a message that says how wide it can be.", 0.05, 0.0001, kMaxSize),
                            integer("segments", "Rows of the strip: 1 is a flat chamfer, 2 or 3 a soft round.", 2, 1, 16),
                            number("angle", "Degrees: only edges whose faces turn by more than this are bevelled. 30 leaves the gently curved parts of a rounded shape alone.", 30, 0, 180),
                            number("roundness", "0: straight chamfer rows with flat shading. 1: a round profile with the normals blending between the two faces.", 1, 0, 1)},
                           "The nodes to bevel; they are merged into one mesh first."));
    ops.push_back(modifier("subdivide", "Catmull-Clark subdivision: smooths its children into a rounder surface, `levels` times (each level multiplies the faces by 4). A box becomes a rounded blob; set `creaseAngle` to keep the sharp edges. Triangles that were a flat quad are treated as that quad, so a box subdivides like a box.",
                           {integer("levels", "Times to subdivide. 1 doubles the detail along each direction; 4 is the most allowed and the triangle limit (1000000) applies.", 1, 1, 4),
                            number("creaseAngle", "Degrees: edges whose faces turn by more than this (and open boundaries) stay sharp. 180 smooths everything.", 180, 0, 180)},
                           "The nodes to subdivide; they are merged into one mesh first."));
    ops.push_back(modifier("solidify", "Gives a surface thickness: adds a second, inverted surface offset along the vertex normals and walls along any open edge. A grid becomes a slab; a closed solid becomes a hollow shell (a helmet, a bowl).",
                           {number("thickness", "Wall thickness in metres.", 0.05, 0.0001, kMaxSize),
                            number("offset", "-1: the original surface is the outside and the wall grows against its normals (inwards). 1: it grows along the normals (outwards). 0: centred on the original surface.", -1, -1, 1),
                            boolean("even", "Stretch the offset at sharp corners so the wall keeps its thickness there.", true)},
                           "The nodes to thicken; they are merged into one mesh first."));
    ops.push_back(modifier("bend", "Bends its children along an axis into an arc: a curved pipe, a bent plank, a banana. The part between `from` and `to` curves through `angle` degrees; beyond them the model continues straight. Give it enough `segments` first (a box with 1 segment only tilts).",
                           {axis_field("axis", "The length axis the model bends along.", "y"),
                            number("angle", "Degrees of the arc over [from, to]; negative bends the other way.", 90, -360, 360),
                            number("direction", "Degrees: which way it bends, round the axis. 0 bends towards +Z when `axis` is y, towards +Y when it is x and towards +X when it is z (the next axis in the order x, y, z); 90 bends towards the one after that (+X for y).", 0, -360, 360),
                            number_opt("from", "Start of the stretch that bends, as a coordinate on `axis`. Left out: the bottom of the model along that axis.", -kMaxSize, kMaxSize),
                            number_opt("to", "End of the stretch that bends. Left out: the top of the model along that axis. Must be above `from`.", -kMaxSize, kMaxSize)},
                           "The nodes to bend; they are merged into one mesh first."));
    ops.push_back(modifier("twist", "Twists its children about an axis, more the further along it: a screw, a rope, a twisted column. Give the model enough `segments` along the axis first.",
                           {axis_field("axis", "The axis to twist about (through the origin of the children).", "y"),
                            number("angle", "Degrees turned over [from, to]; beyond `to` the model stays turned by all of it.", 90, -3600, 3600),
                            number_opt("from", "Where the twist starts, as a coordinate on `axis`. Left out: the bottom of the model.", -kMaxSize, kMaxSize),
                            number_opt("to", "Where the twist ends. Left out: the top of the model. Must be above `from`.", -kMaxSize, kMaxSize)},
                           "The nodes to twist; they are merged into one mesh first."));
    ops.push_back(modifier("taper", "Scales the cross-section of its children along an axis: a tower narrowing to the top, a flared leg, a horn. Give the model enough `segments` along the axis first.",
                           {axis_field("axis", "The axis along which the scale changes.", "y"),
                            number("startScale", "Scale of the cross-section at `from` (1 = unchanged).", 1, 0, 100),
                            number("endScale", "Scale of the cross-section at `to`; 0 pinches to a point.", 0.5, 0, 100),
                            number_opt("from", "Where `startScale` applies, as a coordinate on `axis`. Left out: the bottom of the model.", -kMaxSize, kMaxSize),
                            number_opt("to", "Where `endScale` applies. Left out: the top of the model. Must be above `from`.", -kMaxSize, kMaxSize)},
                           "The nodes to taper; they are merged into one mesh first."));
    ops.push_back(modifier("noise", "Roughens the surface of its children with seeded value noise: rock, terrain, hammered metal, a lumpy clay look. The same seed and position always give the same displacement, so seams stay closed and the result is identical on every run. Give the model enough `segments` for the bumps to show.",
                           {number("amplitude", "The largest displacement of the first octave, in metres.", 0.05, 0, kMaxSize),
                            number("frequency", "Noise features per metre (3 = a bump about every 0.3 m).", 3, 0.001, 1000),
                            integer("octaves", "Layers of noise: each doubles the frequency and halves the amplitude.", 1, 1, 6),
                            integer("seed", "Chooses the pattern; change it for another rock.", 0, 0, 2000000000),
                            boolean("alongNormal", "true: move vertices along the surface normal (bumps in and out). false: a free 3D offset.", true)},
                           "The nodes to roughen; they are merged into one mesh first."));
    ops.push_back(modifier("smooth", "Relaxes the shape of its children by moving each vertex towards the average of its neighbours (Laplacian smoothing, with Taubin's correction so the shape does not shrink): removes jaggedness left by noise, rounds a lumpy shape. It changes positions only; use `subdivide` to add detail.",
                           {integer("iterations", "Passes. More passes smooth further.", 4, 1, 100),
                            number("factor", "How far a vertex moves towards the average per pass (0 none, 1 all the way).", 0.5, 0, 1),
                            boolean("taubin", "A second, opposite pass per iteration so the model keeps its volume. false: plain Laplacian (it shrinks).", true),
                            boolean("lockBoundary", "Vertices on an open edge stay where they are.", true),
                            number("sharpAngle", "Degrees: vertices on an edge whose faces turn by more than this stay put, so box corners survive. 180 = nothing is locked.", 180, 0, 180)},
                           "The nodes to smooth; they are merged into one mesh first."));
    ops.push_back(modifier("weld", "Joins vertices that are closer than `distance`: closes the hairline gaps between pieces that were meant to touch and removes the triangles that collapse.",
                           {number("distance", "Metres: vertices closer than this are moved to their common centre.", 0.001, 0, 1)},
                           "The nodes to weld; they are merged into one mesh first."));
    ops.push_back(modifier("shade", "Chooses flat or smooth shading for its children: flat shows every face (a cut gem, low poly), smooth blends the normals over shared vertices (a ball), auto blends only where faces meet at less than `angle` (the usual choice: a box stays sharp, a rounded edge is smooth). It changes normals only, not the shape.",
                           {choice("mode", "\"auto\" (smooth below `angle`), \"flat\" or \"smooth\".", {"auto", "flat", "smooth"}, "auto"),
                            number("angle", "Degrees for \"auto\": corners of faces that turn by less than this share a normal.", 30, 0, 180)},
                           "The nodes to shade; they are merged into one mesh first."));
    // ---- signed-distance shapes (docs/MODELING.md, "Organic shapes: sdf") --------------------------------------------------------------
    {
        auto blend_fields = [](std::vector<ModelFieldInfo> fields) {
            fields.push_back(choice("blend", "How this joins the shapes before it in its sdf (the first shape of a group starts it and ignores this): \"union\" adds it, \"subtract\" cuts it out of what is there, \"intersect\" keeps only what both have.",
                                    {"union", "subtract", "intersect"}, "union"));
            fields.push_back(number("smooth", "Blend distance in metres: 0 is a hard edge; above 0 the two surfaces melt into each other over about this distance (a union fills the crease, a subtraction rounds the cut). The quadratic smooth min/max.", 0, 0, 100));
            return fields;
        };
        auto shape = [&](std::string op, std::string doc, std::vector<ModelFieldInfo> fields) {
            return ModelOpInfo{std::move(op), "sdf_shape", std::move(doc), blend_fields(std::move(fields))};
        };
        ops.push_back(shape("sdf_sphere", "A ball, as a shape of an `sdf` node. Its transform (`position`, `rotation`, `scale`) places it in the sdf; `part`, `material` and `color` give it its look and name the part its surface becomes.",
                            {number("radius", "Radius in metres.", 0.5, kMinSize, kMaxSize)}));
        ops.push_back(shape("sdf_capsule", "A capsule or, with a different `radiusTop`, a round cone (a ball at each end and the smooth hull between them): a limb, a tail, a horn, a trunk. Upright, centred between the two balls' centres; `height` is tip to tip.",
                            {number("radius", "Radius of the bottom ball, in metres.", 0.5, kMinSize, kMaxSize),
                             number_opt("radiusTop", "Radius of the top ball. Left out: the same as `radius`.", kMinSize, kMaxSize),
                             number("height", "Tip to tip along Y, in metres. At least twice the larger radius (equal: a ball).", 2, 2 * kMinSize, kMaxSize)}));
        ops.push_back(shape("sdf_ellipsoid", "A stretched ball with one radius per axis: a body, a head, a pebble. Its distance is an approximation (exact on the surface), which only matters for the width of a smooth blend next to it.",
                            {field("radii", "size3", "Radius along X, Y and Z in metres: one number for a ball, or [x, y, z].", Json::array({0.6, 0.4, 0.4}), kMinSize, kMaxSize)}));
        ops.push_back(shape("sdf_box", "A box with optionally rounded edges, centred on its origin.",
                            {field("size", "size3", "Width, height and depth in metres: one number for a cube, or [x, y, z].", Json::array({1, 1, 1}), kMinSize, kMaxSize),
                             number("round", "Radius of the rounded edges and corners in metres; at most half the smallest side (that is a pill or a ball).", 0, 0, kMaxSize)}));
        ops.push_back(shape("sdf_cylinder", "An upright cylinder with optionally rounded edges, centred on its origin: a trunk, a post, a mushroom stem.",
                            {number("radius", "Radius in metres.", 0.5, kMinSize, kMaxSize),
                             number("height", "Height along Y in metres.", 1, kMinSize, kMaxSize),
                             number("round", "Radius of the rounded rims in metres; at most the radius and half the height.", 0, 0, kMaxSize)}));
        ops.push_back(shape("sdf_cone", "A cone, point up (a frustum when `radiusTop` is above 0), centred on its origin: a spike, a roof, a conifer.",
                            {number("radius", "Radius of the base in metres.", 0.5, kMinSize, kMaxSize),
                             number("radiusTop", "Radius of the top: 0 is a sharp point, above 0 cuts the tip off.", 0, 0, kMaxSize),
                             number("height", "Height along Y in metres.", 1, kMinSize, kMaxSize)}));
        ops.push_back(shape("sdf_torus", "A ring lying flat in XZ with its hole along Y, centred on its origin: a handle, a loop, a rim.",
                            {number("radius", "Radius of the ring: from the centre to the middle of the tube, in metres.", 0.5, kMinSize, kMaxSize),
                             number("tube", "Radius of the tube, in metres. At most `radius`.", 0.15, kMinSize, kMaxSize)}));
        ModelFieldInfo groupChildren = field("children", "nodes", "The shapes (`sdf_sphere`, `sdf_capsule`... and more `sdf_group`s), joined in order: the first starts the shape, each next one is added to, cut from or intersected with what came before according to its own `blend` and `smooth`.");
        ops.push_back({"sdf_group", "sdf_group",
                       "Several shapes of an `sdf` node treated as one: they are joined in order, the group is placed by its own transform, and then it joins the shapes before it with its own `blend` and `smooth`, like a single shape. How a creature is built: a body group, a head group, subtract the eyes' sockets from the head only. `mirror` repeats it across a plane.",
                       blend_fields({choice("mirror", "Repeats what is on the positive side of a plane through the group's origin on the other side (a symmetric creature: model one side): \"x\", \"y\" or \"z\" is the axis the plane is perpendicular to. The shapes should sit on the positive side; \"none\" leaves them as they are.", {"none", "x", "y", "z"}, "none"), groupChildren})});
        ops.push_back({"sdf", "sdf",
                       "Organic shapes by signed distance fields instead of triangles: its `children` (`sdf_sphere`, `sdf_capsule`, `sdf_ellipsoid`, `sdf_box`, `sdf_cylinder`, `sdf_cone`, `sdf_torus`, `sdf_group`) describe a solid, joined in order with union, subtraction or intersection and a blend distance that melts them into each other (a creature, a rock, a tree, a mushroom, a prop that looks grown rather than assembled). The solid is meshed on a grid (marching tetrahedra: always a closed manifold surface), decimated with a quadric error metric that keeps the part boundaries, and given smooth normals from the field. The result is an ordinary mesh node: `align` and the transform place it, modifiers can wrap it and a boolean can take it as an operand. Each shape's `part`, `material` and `color` are kept: a triangle belongs to the part of the shape that owns the surface there, a vertex colour melts across a smooth blend.",
                       {number_opt("voxelSize", "Size of a sampling cell in metres: smaller is more detailed and slower; a feature thinner than a cell can vanish. Left out: `quality` decides.", 0.0005, 10),
                        choice("quality", "Cells along the longest side of the shape when `voxelSize` is left out: \"draft\" 40, \"normal\" 96, \"fine\" 160, \"ultra\" 200. A request that would sample too many points (12 million, or 300 million shape evaluations) is an error that says the voxel size that fits.",
                               {"draft", "normal", "fine", "ultra"}, "normal"),
                        integer_opt("targetTriangles", "Decimate down to about this many triangles. Left out: only `maxError` limits the decimation.", 8, 1000000),
                        number_opt("maxError", "Largest error decimation may introduce, in metres (root mean square distance of a merged vertex from the planes it replaced). 0: no decimation. Left out: a quarter of a cell when there is no `targetTriangles`, else no limit.", 0, 1),
                        number("noiseAmplitude", "Roughness: seeded value noise of about this size in metres moves the surface along its normal (rock, bark, hide). 0: smooth.", 0, 0, 10),
                        number("noiseFrequency", "Noise features per metre (3 = a bump about every 0.3 m).", 3, 0.001, 1000),
                        integer("noiseOctaves", "Layers of noise: each doubles the frequency and halves the amplitude.", 1, 1, 6),
                        integer("noiseSeed", "Chooses the noise pattern; change it for another rock.", 0, 0, 2000000000),
                        field("children", "nodes", "The shapes, joined in order (see `sdf_group`). At least one enabled shape; a shape's own transform, part, material and colour apply to it.")}});
    }
    {
        ModelFieldInfo children = field("children", "nodes", "The nodes in the group, evaluated in order and merged into one mesh. A group is also how a `part`, `material` or `color` is given to several nodes at once, and how one transform moves them together.");
        ops.push_back({"group", "group", "Several nodes treated as one: the group's transform applies to all of them, and its part, material and colour are inherited by the ones that do not name their own.", {children}});
    }
    return ops;
}

}  // namespace

const std::vector<ModelOpInfo>& model_ops() {
    static const std::vector<ModelOpInfo> ops = build_ops();
    return ops;
}

const std::vector<ModelFieldInfo>& model_common_fields() {
    static const std::vector<ModelFieldInfo> fields = [] {
        std::vector<ModelFieldInfo> f;
        ModelFieldInfo op = field("op", "string", "What the node is: one of the operations of the catalog (`model.info {}` lists them).");
        op.required = true;
        f.push_back(op);
        f.push_back(field("id", "string", "A name for this node that stays the same when the tree changes: model.edit finds nodes by it. Letters, digits, `_`, `-` and `.`, at most 64 characters, unique in the document."));
        f.push_back(field("note", "string", "A comment for the next person (or AI) reading the document; it has no effect."));
        f.push_back(boolean("enabled", "false leaves the node (and everything below it) out without deleting it.", true));
        f.push_back(field("part", "string", "The part of the model this node and the nodes below it belong to (\"door\", \"left_wheel\"). Parts become submeshes of the baked .glb, named in the primitive's extras, so tools and scripts can find them. Left out: the part of the group above, else none."));
        f.push_back(field("material", "string", "A key of the document's `materials`. Left out: the material of the group above, else the default (white). Nodes with the same part and material share a submesh."));
        f.push_back(field("color", "color", "Vertex colour, [r, g, b] or [r, g, b, a] in 0..1, or \"#rrggbb\" / \"#rrggbbaa\". Multiplies the material's colour when drawn. Left out: the colour of the group above, else none."));
        f.push_back(field("position", "vec3", "Where the node's origin goes, [x, y, z] in metres, relative to the group above.", Json::array({0, 0, 0})));
        f.push_back(field("rotation", "vec3", "Rotation in degrees, [pitch (X), yaw (Y), roll (Z)], applied roll first, then pitch, then yaw.", Json::array({0, 0, 0})));
        f.push_back(field("scale", "size3", "Scale: one number, or [x, y, z]. A negative entry mirrors the node (the triangles are turned so they still face out). Never 0.", Json::array({1, 1, 1})));
        return f;
    }();
    return fields;
}

const std::vector<ModelFieldInfo>& model_align_fields() {
    static const std::vector<ModelFieldInfo> fields = [] {
        ModelFieldInfo align = field("align", "choice", "Where the primitive sits against its origin, along Y, before `position` moves it: \"center\" (its bounding box is centred; text keeps its baseline at 0), \"bottom\" (it stands on y = 0) or \"top\" (it hangs from y = 0).", Json("center"));
        align.choices = {"center", "bottom", "top"};
        return std::vector<ModelFieldInfo>{align};
    }();
    return fields;
}

// ---- reading -----------------------------------------------------------------------------------------------------------------

namespace {

const ModelOpInfo* find_op(std::string_view op) {
    for (const ModelOpInfo& o : model_ops())
        if (o.op == op) return &o;
    return nullptr;
}

std::vector<std::string> op_names() {
    std::vector<std::string> names;
    for (const ModelOpInfo& o : model_ops()) names.push_back(o.op);
    return names;
}

std::string quoted_list(const std::vector<std::string>& names) {
    std::string s;
    for (std::size_t i = 0; i < names.size(); ++i) s += (i ? ", \"" : "\"") + names[i] + "\"";
    return s;
}

std::string num_text(double v) {
    if (v == std::floor(v) && std::fabs(v) < 1e9) return std::format("{}", static_cast<long long>(v));
    return std::format("{:g}", v);
}

std::string range_text(const ModelFieldInfo& f) {
    if (f.min && f.max) return "from " + num_text(*f.min) + " to " + num_text(*f.max);
    if (f.min) return "at least " + num_text(*f.min);
    if (f.max) return "at most " + num_text(*f.max);
    return "";
}

struct Reader {
    std::vector<ModelIssue> issues;
    std::vector<std::string> materialNames;
    std::map<std::string, std::string> ids;  // node id -> pointer
    std::size_t nodeCount = 0;

    void err(std::string pointer, std::string message, std::string hint) { issues.push_back({std::move(pointer), std::move(message), std::move(hint)}); }
};

bool is_integral(const Json& v) { return v.is_number_integer() || (v.is_number_float() && std::isfinite(v.get<double>()) && v.get<double>() == std::floor(v.get<double>())); }

std::optional<Vec4> parse_color(const Json& v) {
    if (v.is_string()) {
        const std::string s = v.get<std::string>();
        if ((s.size() != 7 && s.size() != 9) || s[0] != '#') return std::nullopt;
        float c[4] = {0, 0, 0, 1};
        for (std::size_t i = 0; i < (s.size() - 1) / 2; ++i) {
            int value = 0;
            for (std::size_t k = 0; k < 2; ++k) {
                const char ch = s[1 + i * 2 + k];
                int d;
                if (ch >= '0' && ch <= '9') d = ch - '0';
                else if (ch >= 'a' && ch <= 'f') d = 10 + ch - 'a';
                else if (ch >= 'A' && ch <= 'F') d = 10 + ch - 'A';
                else return std::nullopt;
                value = value * 16 + d;
            }
            c[i] = float(value) / 255.0f;
        }
        return Vec4{c[0], c[1], c[2], c[3]};
    }
    if (!v.is_array() || (v.size() != 3 && v.size() != 4)) return std::nullopt;
    float c[4] = {0, 0, 0, 1};
    for (std::size_t i = 0; i < v.size(); ++i) {
        if (!v[i].is_number()) return std::nullopt;
        const double d = v[i].get<double>();
        if (!std::isfinite(d) || d < 0 || d > 1) return std::nullopt;
        c[i] = float(d);
    }
    return Vec4{c[0], c[1], c[2], c[3]};
}

// Checks one number against the field's range; false (and an issue) when it is not a number or out of range.
bool check_number(Reader& r, const ModelFieldInfo& f, const Json& v, const std::string& pointer, const std::string& what, bool wholeNumber) {
    if (!v.is_number() || !std::isfinite(v.get<double>())) {
        r.err(pointer, what + " must be " + (wholeNumber ? "a whole number" : "a number") + ", got " + describe_json_value(v), f.doc);
        return false;
    }
    if (wholeNumber && !is_integral(v)) {
        r.err(pointer, what + " must be a whole number, got " + describe_json_value(v), f.doc);
        return false;
    }
    const double d = v.get<double>();
    if ((f.min && d < *f.min) || (f.max && d > *f.max)) {
        r.err(pointer, what + " must be " + range_text(f) + ", got " + num_text(d), f.doc);
        return false;
    }
    return true;
}

// A list of `dims`-number points, at least f.minItems and at most f.maxItems of them, every number within f.min..f.max.
bool read_points(Reader& r, const ModelFieldInfo& f, const Json& v, const std::string& pointer, std::size_t dims, Json& out) {
    const std::string shape = dims == 2 ? "a list of [a, b] points" : "a list of [x, y, z] points";
    const std::size_t lo = std::size_t(f.minItems.value_or(0)), hi = std::size_t(f.maxItems.value_or(1 << 20));
    if (!v.is_array() || v.size() < lo || v.size() > hi) {
        r.err(pointer, f.key + " must be " + shape + " (" + std::to_string(lo) + " to " + std::to_string(hi) + " of them), got " +
                           (v.is_array() ? std::to_string(v.size()) + " points" : describe_json_value(v)),
              f.doc);
        return false;
    }
    Json points = Json::array();
    bool ok = true;
    for (std::size_t i = 0; i < v.size(); ++i) {
        const std::string at = pointer + "/" + std::to_string(i);
        if (!v[i].is_array() || v[i].size() != dims) {
            r.err(at, "point " + std::to_string(i) + " of " + f.key + " must be " + (dims == 2 ? "[a, b]" : "[x, y, z]") + ", got " + describe_json_value(v[i]), f.doc);
            ok = false;
            continue;
        }
        Json point = Json::array();
        for (std::size_t k = 0; k < dims; ++k) {
            if (!check_number(r, f, v[i][k], at + "/" + std::to_string(k), f.key + "[" + std::to_string(i) + "][" + std::to_string(k) + "]", false)) ok = false;
            else point.push_back(v[i][k].get<double>());
        }
        if (point.size() == dims) points.push_back(point);
    }
    if (ok) out = points;
    return ok;
}

// Reads the value `v` of `f` into `out` (normalised). False when it had a problem (reported).
bool read_field(Reader& r, const ModelFieldInfo& f, const Json& v, const std::string& pointer, Json& out) {
    const std::string& t = f.type;
    if (t == "number" || t == "integer") {
        if (!check_number(r, f, v, pointer, f.key, t == "integer")) return false;
        out = t == "integer" ? Json(static_cast<long long>(std::llround(v.get<double>()))) : Json(v.get<double>());
        return true;
    }
    if (t == "boolean") {
        if (!v.is_boolean()) {
            r.err(pointer, f.key + " must be true or false, got " + describe_json_value(v), "Write true or false. " + f.doc);
            return false;
        }
        out = v;
        return true;
    }
    if (t == "string" || t == "choice") {
        if (!v.is_string()) {
            r.err(pointer, f.key + " must be " + (f.choices.empty() ? "text" : "one of " + quoted_list(f.choices)) + ", got " + describe_json_value(v), f.doc);
            return false;
        }
        const std::string s = v.get<std::string>();
        if (t == "choice" && std::find(f.choices.begin(), f.choices.end(), s) == f.choices.end()) {
            r.err(pointer, f.key + " must be one of " + quoted_list(f.choices) + ", got \"" + s + "\"", did_you_mean(s, f.choices) + " " + f.doc);
            return false;
        }
        out = v;
        return true;
    }
    if (t == "vec3" || t == "size3" || t == "count3" || t == "count2") {
        const bool counts = t == "count3" || t == "count2";
        const std::size_t n = t == "count2" ? 2 : 3;
        const bool scalarOk = t != "vec3";
        Json parts = Json::array();
        if (scalarOk && v.is_number()) {
            if (!check_number(r, f, v, pointer, f.key, counts)) return false;
            for (std::size_t i = 0; i < n; ++i) parts.push_back(counts ? Json(static_cast<long long>(std::llround(v.get<double>()))) : Json(v.get<double>()));
            out = parts;
            return true;
        }
        if (!v.is_array() || v.size() != n) {
            const std::string shape = n == 2 ? "[x, z]" : "[x, y, z]";
            r.err(pointer, f.key + " must be " + (scalarOk ? "a number or " : "") + "a list " + shape + ", got " + describe_json_value(v), f.doc);
            return false;
        }
        bool ok = true;
        for (std::size_t i = 0; i < n; ++i) {
            const std::string at = pointer + "/" + std::to_string(i);
            if (!check_number(r, f, v[i], at, f.key + "[" + std::to_string(i) + "]", counts)) ok = false;
            else parts.push_back(counts ? Json(static_cast<long long>(std::llround(v[i].get<double>()))) : Json(v[i].get<double>()));
        }
        if (ok) out = parts;
        return ok;
    }
    if (t == "points2" || t == "points3" || t == "rings") {
        const std::size_t dims = t == "points2" ? 2 : 3;
        if (t == "rings") {
            const std::string shape = "a list of sections, each a list of [x, y, z] points";
            if (!v.is_array() || v.size() < std::size_t(f.minItems.value_or(0)) || v.size() > std::size_t(f.maxItems.value_or(1 << 20))) {
                r.err(pointer, f.key + " must be " + shape + " (" + std::to_string(f.minItems.value_or(0)) + " to " + std::to_string(f.maxItems.value_or(0)) + " sections), got " +
                                   (v.is_array() ? std::to_string(v.size()) + " entries" : describe_json_value(v)),
                      f.doc);
                return false;
            }
            Json sections = Json::array();
            bool ok = true;
            for (std::size_t k = 0; k < v.size(); ++k) {
                Json one;
                ModelFieldInfo inner = f;
                inner.minItems = f.innerMinItems;
                inner.maxItems = f.innerMaxItems;
                if (read_points(r, inner, v[k], pointer + "/" + std::to_string(k), 3, one)) sections.push_back(one);
                else ok = false;
            }
            if (ok) out = sections;
            return ok;
        }
        return read_points(r, f, v, pointer, dims, out);
    }
    if (t == "color") {
        if (!parse_color(v)) {
            r.err(pointer, f.key + " must be [r, g, b] or [r, g, b, a] with numbers from 0 to 1, or \"#rrggbb\", got " + describe_json_value(v), "Example: [0.8, 0.2, 0.1] or \"#cc3319\".");
            return false;
        }
        out = v;
        return true;
    }
    r.err(pointer, "internal: unknown field type " + t, "");
    return false;
}

Vec3 to_vec3(const Json& a) { return {a[0].get<float>(), a[1].get<float>(), a[2].get<float>()}; }

std::vector<std::string> allowed_keys(const ModelOpInfo& op) {
    std::vector<std::string> keys;
    for (const ModelFieldInfo& f : model_common_fields()) keys.push_back(f.key);
    if (op.kind == "primitive" || op.op == "sdf") keys.push_back("align");
    for (const ModelFieldInfo& f : op.fields) keys.push_back(f.key);
    return keys;
}

// Rules that involve several fields of one operation.
void check_op(Reader& r, const ModelNode& n, const std::string& at) {
    const Json& p = n.params;
    auto num = [&](const char* k) { return p[k].get<double>(); };
    if (n.op == "capsule" && num("height") < 2 * num("radius") - 1e-9)
        r.err(at + "/height", std::format("capsule height {} is less than twice its radius ({}): the two hemispheres do not fit", num("height"), 2 * num("radius")),
              "`height` is tip to tip. Raise it to at least " + num_text(2 * num("radius")) + ", or lower `radius`; for a ball use a sphere.");
    if (n.op == "torus" && num("tube") > num("radius"))
        r.err(at + "/tube", std::format("torus tube {} is larger than its ring radius {}: the tube would cross itself", num("tube"), num("radius")),
              "Make `tube` at most `radius` (a ring radius of 0.5 and a tube of 0.15 is a doughnut).");
    if (n.op == "pipe" && num("innerRadius") >= num("radius"))
        r.err(at + "/innerRadius", std::format("pipe innerRadius {} is not smaller than its radius {}", num("innerRadius"), num("radius")),
              "The hole must be narrower than the outside: lower `innerRadius` or raise `radius`.");
    if (n.op == "arch") {
        if (num("openingWidth") >= num("width"))
            r.err(at + "/openingWidth", std::format("arch openingWidth {} is not smaller than the wall's width {}", num("openingWidth"), num("width")),
                  "The doorway must leave wall on both sides: lower `openingWidth` or raise `width`.");
        if (num("openingHeight") >= num("height"))
            r.err(at + "/openingHeight", std::format("arch openingHeight {} is not smaller than the wall's height {}", num("openingHeight"), num("height")),
                  "The doorway must leave wall above the arch: lower `openingHeight` or raise `height`.");
        if (num("openingHeight") < num("openingWidth") / 2)
            r.err(at + "/openingHeight", std::format("arch openingHeight {} is less than half the opening's width ({}): the half circle does not fit", num("openingHeight"), num("openingWidth") / 2),
                  "Raise `openingHeight` to at least " + num_text(num("openingWidth") / 2) + " or narrow the opening.");
    }
    if (n.op == "sdf_capsule") {
        const double top = p.contains("radiusTop") ? num("radiusTop") : num("radius");
        const double need = 2 * std::max(num("radius"), top);
        if (num("height") < need - 1e-9)
            r.err(at + "/height", std::format("sdf_capsule height {} is less than twice its larger radius ({}): the two balls do not fit", num("height"), need),
                  "`height` is tip to tip. Raise it to at least " + num_text(need) + ", or lower the radii; for a ball use sdf_sphere.");
    }
    if (n.op == "sdf_box" && num("round") > 0.5 * std::min({p["size"][0].get<double>(), p["size"][1].get<double>(), p["size"][2].get<double>()}) + 1e-9)
        r.err(at + "/round", std::format("sdf_box round {} is more than half its smallest side ({})", num("round"), 0.5 * std::min({p["size"][0].get<double>(), p["size"][1].get<double>(), p["size"][2].get<double>()})),
              "Lower `round`, or make the box bigger: half the smallest side rounds it into a pill or a ball.");
    if (n.op == "sdf_cylinder" && num("round") > std::min(num("radius"), 0.5 * num("height")) + 1e-9)
        r.err(at + "/round", std::format("sdf_cylinder round {} is more than its radius ({}) or half its height ({})", num("round"), num("radius"), 0.5 * num("height")),
              "Lower `round` to at most " + num_text(std::min(num("radius"), 0.5 * num("height"))) + ".");
    if (n.op == "sdf_torus" && num("tube") > num("radius"))
        r.err(at + "/tube", std::format("sdf_torus tube {} is larger than its ring radius {}: the tube would cross itself", num("tube"), num("radius")),
              "Make `tube` at most `radius`.");
    if (n.op == "cylinder" && p.contains("radiusTop") && num("radius") == 0 && num("radiusTop") == 0)
        r.err(at + "/radius", "a cylinder with both radii 0 has no volume", "Give `radius` or `radiusTop` a size above 0.");
    if (n.op == "lathe") {
        bool anyRadius = false;
        const Json& prof = p["profile"];
        for (std::size_t k = 0; k < prof.size(); ++k) {
            if (prof[k][0].get<double>() < 0)
                r.err(at + "/profile/" + std::to_string(k) + "/0", std::format("lathe profile point {} has a negative radius ({})", k, num_text(prof[k][0].get<double>())),
                      "Points are [radius, height] with radius 0 or more; to put something on the other side of the axis, the turn already does it.");
            if (prof[k][0].get<double>() > 0) anyRadius = true;
        }
        if (!anyRadius) r.err(at + "/profile", "every point of the lathe profile is on the axis (radius 0): it has no volume", "Give at least one point a radius above 0, e.g. [[0,0],[0.5,0],[0.5,1],[0,1]].");
    }
    if (n.op == "sweep") {
        const Json& prof = p["profile"];
        double area = 0;
        for (std::size_t k = 0; k < prof.size(); ++k) {
            const Json& a = prof[k];
            const Json& b = prof[(k + 1) % prof.size()];
            area += a[0].get<double>() * b[1].get<double>() - b[0].get<double>() * a[1].get<double>();
        }
        if (std::fabs(area) < 1e-12) r.err(at + "/profile", "the sweep profile has no area (its points are on a line)", "Give a closed shape with at least 3 points that are not in a straight line.");
        if (p["closed"].get<bool>() && p["path"].size() < 3)
            r.err(at + "/closed", "a closed sweep path needs at least 3 points, it has " + std::to_string(p["path"].size()), "Add path points, or set `closed` to false.");
    }
    if (n.op == "loft") {
        const Json& sec = p["sections"];
        for (std::size_t k = 1; k < sec.size(); ++k)
            if (sec[k].size() != sec[0].size())
                r.err(at + "/sections/" + std::to_string(k), std::format("loft section {} has {} points but section 0 has {}", k, sec[k].size(), sec[0].size()),
                      "Every section needs the same number of points: point i of a section is joined to point i of the next. Add or remove points so they match.");
        if (p["closed"].get<bool>() && !sec.empty() && sec[0].size() < 3)
            r.err(at + "/sections/0", "a closed loft section needs at least 3 points, it has " + std::to_string(sec[0].size()), "Add points, or set `closed` to false for an open ribbon.");
    }
    if ((n.op == "bend" || n.op == "twist" || n.op == "taper") && p.contains("from") && p.contains("to") && num("from") >= num("to"))
        r.err(at + "/to", std::format("{} `to` ({}) is not above `from` ({})", n.op, num_text(num("to")), num_text(num("from"))),
              "`from` and `to` are coordinates along the axis, with `from` the lower one. Swap them, or leave both out to use the model's own extent.");
    if (n.op == "text" && p["text"].get<std::string>().empty())
        r.err(at + "/text", "text is empty", "Write the text to build, e.g. \"EXIT\".");
    if (n.op == "text" && p["text"].get<std::string>().size() > 200)
        r.err(at + "/text", "text is longer than 200 characters", "Split it into several text nodes.");
}

bool valid_id(const std::string& id) {
    if (id.empty() || id.size() > 64) return false;
    for (char c : id)
        if (!(std::isalnum(static_cast<unsigned char>(c)) || c == '_' || c == '-' || c == '.')) return false;
    return true;
}

ModelNode read_node(Reader& r, const Json& j, const std::string& at, int depth, const ModelOpInfo* parent = nullptr) {
    ModelNode n;
    n.pointer = at;
    if (++r.nodeCount > kModelDocMaxNodes) {
        if (r.nodeCount == kModelDocMaxNodes + 1)
            r.err(at, std::format("the document has more than {} nodes", kModelDocMaxNodes), "Split the model into several documents, or use fewer, bigger primitives.");
        return n;
    }
    if (!j.is_object()) {
        r.err(at, "a node must be an object, got " + describe_json_value(j), "Write {\"op\": \"box\", \"size\": [1, 1, 1]}.");
        return n;
    }
    auto opIt = j.find("op");
    if (opIt == j.end()) {
        r.err(at, "a node needs \"op\"", "Name the operation: " + quoted_list(op_names()) + ".");
        return n;
    }
    if (!opIt->is_string()) {
        r.err(at + "/op", "op must be text, got " + describe_json_value(*opIt), "Name the operation: " + quoted_list(op_names()) + ".");
        return n;
    }
    n.op = opIt->get<std::string>();
    const ModelOpInfo* op = find_op(n.op);
    if (!op) {
        r.err(at + "/op", "unknown operation \"" + n.op + "\"", did_you_mean(n.op, op_names())); 
        return n;
    }
    // sdf shapes live inside an sdf and nothing else does
    {
        const bool inSdf = parent && (parent->kind == "sdf" || parent->kind == "sdf_group");
        const bool sdfPart = op->kind == "sdf_shape" || op->kind == "sdf_group";
        if (sdfPart && !inSdf)
            r.err(at + "/op", n.op + " is a shape of an `sdf` node and works only inside one",
                  "Wrap it: {\"op\": \"sdf\", \"children\": [{\"op\": \"" + n.op + "\"}]} makes a mesh of it.");
        else if (inSdf && !sdfPart)
            r.err(at + "/op", n.op + " cannot go inside " + parent->op + ": its children are signed-distance shapes",
                  "Use sdf_sphere, sdf_capsule, sdf_ellipsoid, sdf_box, sdf_cylinder, sdf_cone, sdf_torus or sdf_group here. To combine a mesh with an sdf, put both under a `boolean` (or a `group`) outside the sdf.");
    }
    const std::vector<std::string> keys = allowed_keys(*op);
    for (auto it = j.begin(); it != j.end(); ++it) {
        if (std::find(keys.begin(), keys.end(), it.key()) != keys.end()) continue;
        r.err(at + "/" + it.key(), "\"" + it.key() + "\" is not a field of " + n.op + " nodes", did_you_mean(it.key(), keys));
    }

    // the fields every node has
    if (auto it = j.find("id"); it != j.end()) {
        if (!it->is_string() || !valid_id(it->get<std::string>()))
            r.err(at + "/id", "id must be 1 to 64 letters, digits, '_', '-' or '.', got " + describe_json_value(*it), "Example: \"door_frame\".");
        else {
            n.id = it->get<std::string>();
            auto [pos, fresh] = r.ids.emplace(n.id, at);
            if (!fresh) r.err(at + "/id", "id \"" + n.id + "\" is already used by " + pos->second, "Ids are unique in a document: rename one, or leave the id out.");
        }
    }
    if (auto it = j.find("note"); it != j.end()) {
        if (!it->is_string()) r.err(at + "/note", "note must be text, got " + describe_json_value(*it), "Write a short comment, or remove it.");
        else n.note = it->get<std::string>();
    }
    if (auto it = j.find("enabled"); it != j.end()) {
        if (!it->is_boolean()) r.err(at + "/enabled", "enabled must be true or false, got " + describe_json_value(*it), "Write true or false.");
        else n.enabled = it->get<bool>();
    }
    for (const char* key : {"part", "material"}) {
        auto it = j.find(key);
        if (it == j.end()) continue;
        const std::string ptr = at + "/" + key;
        if (!it->is_string() || it->get<std::string>().empty() || it->get<std::string>().size() > 64) {
            r.err(ptr, std::string(key) + " must be a name of 1 to 64 characters, got " + describe_json_value(*it), std::string("Example: \"") + (std::string(key) == "part" ? "door" : "wood") + "\".");
            continue;
        }
        const std::string s = it->get<std::string>();
        if (std::string(key) == "part") n.part = s;
        else {
            if (std::find(r.materialNames.begin(), r.materialNames.end(), s) == r.materialNames.end())
                r.err(ptr, "material \"" + s + "\" is not in the document's `materials`",
                      (r.materialNames.empty() ? std::string("The document has no materials yet: add {\"materials\": {\"" + s + "\": {\"color\": [0.6, 0.4, 0.2, 1]}}}.")
                                               : did_you_mean(s, r.materialNames)));
            n.material = s;
        }
    }
    if (auto it = j.find("color"); it != j.end()) {
        Json dummy;
        if (read_field(r, *std::find_if(model_common_fields().begin(), model_common_fields().end(), [](const ModelFieldInfo& f) { return f.key == "color"; }), *it, at + "/color", dummy))
            n.color = parse_color(*it);
    }
    for (const ModelFieldInfo& f : model_common_fields()) {
        if (f.key != "position" && f.key != "rotation" && f.key != "scale") continue;
        auto it = j.find(f.key);
        if (it == j.end()) continue;
        Json out;
        if (!read_field(r, f, *it, at + "/" + f.key, out)) continue;
        if (f.key == "scale") {
            bool zero = false;
            for (std::size_t i = 0; i < 3; ++i)
                if (std::fabs(out[i].get<double>()) < 1e-4) zero = true;
            if (zero) {
                r.err(at + "/scale", "scale " + out.dump() + " has an entry of (almost) 0, which flattens the node to nothing", "Use a small non-zero value, or `enabled: false` to leave the node out.");
                continue;
            }
        }
        (f.key == "position" ? n.position : f.key == "rotation" ? n.rotation : n.scale) = to_vec3(out);
    }
    if (op->kind == "primitive" || op->op == "sdf") {
        if (auto it = j.find("align"); it != j.end()) {
            Json out;
            if (read_field(r, model_align_fields()[0], *it, at + "/align", out)) n.align = out.get<std::string>();
        }
    }

    // the fields of the operation
    for (const ModelFieldInfo& f : op->fields) {
        auto it = j.find(f.key);
        if (f.type == "nodes") {
            if (it == j.end()) continue;
            if (!it->is_array()) {
                r.err(at + "/" + f.key, "children must be a list of nodes, got " + describe_json_value(*it), "Write \"children\": [{\"op\": \"box\"}].");
                continue;
            }
            if (depth >= kModelDocMaxDepth) {
                r.err(at + "/children", std::format("groups and modifiers are nested more than {} levels deep", kModelDocMaxDepth), "Flatten the tree: a group inside a group inside... rarely needs to be that deep.");
                continue;
            }
            for (std::size_t i = 0; i < it->size(); ++i) n.children.push_back(read_node(r, (*it)[i], at + "/children/" + std::to_string(i), depth + 1, op));
            continue;
        }
        if (it == j.end()) {
            if (f.required) r.err(at, n.op + " nodes need \"" + f.key + "\"", f.doc);
            else if (f.def) n.params[f.key] = *f.def;
            continue;
        }
        Json out;
        if (read_field(r, f, *it, at + "/" + f.key, out)) n.params[f.key] = out;
        else if (f.def) n.params[f.key] = *f.def;  // keep going with something, to list the other problems
    }
    // check_op reads fields with defaults; skip when a field it needs failed
    bool complete = true;
    for (const ModelFieldInfo& f : op->fields)
        if (f.type != "nodes" && (f.def || f.required) && !n.params.contains(f.key)) complete = false;
    if (complete) check_op(r, n, at);
    return n;
}

}  // namespace

Result<ModelDoc> parse_model_doc(const Json& json, std::string_view file, std::vector<ModelIssue>* issuesOut) {
    Reader r;
    ModelDoc doc;
    auto finish = [&]() -> Result<ModelDoc> {
        if (issuesOut) *issuesOut = r.issues;
        if (r.issues.empty()) return doc;
        const ModelIssue& first = r.issues.front();
        std::string where = std::string(file);
        if (!first.pointer.empty()) where += (where.empty() ? "" : " ") + first.pointer;
        std::string message = (where.empty() ? "" : where + ": ") + first.message;
        if (r.issues.size() > 1) message += std::format(" (and {} more problem{})", r.issues.size() - 1, r.issues.size() == 2 ? "" : "s");
        return make_error(message, first.hint.empty() ? "docs/MODELING.md describes the format and schemas/model.schema.json lists every field." : first.hint);
    };
    if (!json.is_object()) {
        r.err("", "a model document must be a JSON object, got " + describe_json_value(json), "Start from `model.create`, or write {\"format\": \"factoria.model/1\", \"nodes\": [{\"op\": \"box\"}]}.");
        return finish();
    }
    static const std::vector<std::string> topKeys = {"$schema", "format", "doc", "output", "materials", "nodes"};
    for (auto it = json.begin(); it != json.end(); ++it)
        if (std::find(topKeys.begin(), topKeys.end(), it.key()) == topKeys.end())
            r.err("/" + it.key(), "\"" + it.key() + "\" is not a field of a model document", did_you_mean(it.key(), topKeys));
    if (auto it = json.find("format"); it == json.end())
        r.err("/format", "the document has no \"format\"", std::string("Add \"format\": \"") + kModelDocFormat + "\".");
    else if (!it->is_string() || it->get<std::string>() != kModelDocFormat)
        r.err("/format", "format must be \"" + std::string(kModelDocFormat) + "\", got " + describe_json_value(*it), "This reader only knows format 1.");
    if (auto it = json.find("doc"); it != json.end()) {
        if (!it->is_string()) r.err("/doc", "doc must be text, got " + describe_json_value(*it), "Say in a sentence what the model is and where the game uses it.");
        else doc.doc = it->get<std::string>();
    }
    if (auto it = json.find("output"); it != json.end()) {
        if (!it->is_object()) r.err("/output", "output must be an object like {\"path\": \"assets/models/door.glb\"}, got " + describe_json_value(*it), "Leave it out to bake next to the document.");
        else {
            for (auto o = it->begin(); o != it->end(); ++o)
                if (o.key() != "path") r.err("/output/" + o.key(), "\"" + o.key() + "\" is not a field of output", did_you_mean(o.key(), std::vector<std::string>{"path"}));
            if (auto p = it->find("path"); p != it->end()) {
                if (!p->is_string() || !ends_with(to_lower(p->get<std::string>()), ".glb")) r.err("/output/path", "output.path must be a project path ending in .glb, got " + describe_json_value(*p), "Example: \"assets/models/door.glb\".");
                else doc.outputPath = p->get<std::string>();
            }
        }
    }
    if (auto it = json.find("materials"); it != json.end()) {
        if (!it->is_object()) r.err("/materials", "materials must be an object of named materials, got " + describe_json_value(*it), "Example: {\"wood\": {\"color\": [0.6, 0.4, 0.2, 1], \"roughness\": 0.8}}.");
        else
            for (auto m = it->begin(); m != it->end(); ++m) {
                const std::string at = "/materials/" + m.key();
                if (m.key().empty() || m.key().size() > 64) {
                    r.err(at, "a material name must be 1 to 64 characters", "Example: \"wood\".");
                    continue;
                }
                if (!m->is_object()) {
                    r.err(at, "a material must be an object like {\"color\": [r, g, b, a]}, got " + describe_json_value(*m), "Fields: color, texture, metallic, roughness, emissive, doubleSided, blend.");
                    continue;
                }
                if (m->contains("name")) {
                    r.err(at + "/name", "a material is named by its key (\"" + m.key() + "\"), not by a `name` field", "Remove `name`.");
                    continue;
                }
                auto mat = mesh_material_from_json(*m, "material '" + m.key() + "'");
                if (!mat.ok()) {
                    r.err(at, mat.error().message, mat.error().hint);
                    continue;
                }
                for (const char* k : {"metallic", "roughness"})
                    if (m->contains(k) && (*m)[k].is_number() && ((*m)[k].get<double>() < 0 || (*m)[k].get<double>() > 1))
                        r.err(at + "/" + k, std::string(k) + " must be from 0 to 1, got " + describe_json_value((*m)[k]), "0 is none, 1 is full.");
                mat->name = m.key();
                r.materialNames.push_back(m.key());
                doc.materials.emplace_back(m.key(), std::move(*mat));
            }
    }
    if (auto it = json.find("nodes"); it == json.end())
        r.err("/nodes", "the document has no \"nodes\"", "Add the list of operations, e.g. \"nodes\": [{\"op\": \"box\", \"size\": [1, 2, 1]}].");
    else if (!it->is_array())
        r.err("/nodes", "nodes must be a list, got " + describe_json_value(*it), "Write \"nodes\": [{\"op\": \"box\"}].");
    else
        for (std::size_t i = 0; i < it->size(); ++i) doc.nodes.push_back(read_node(r, (*it)[i], "/nodes/" + std::to_string(i), 1));
    return finish();
}

Result<ModelDoc> load_model_doc(std::string_view path, std::vector<ModelIssue>* issues) {
    auto text = fs::read_text(path);
    if (!text)
        return make_error(std::string(path) + ": cannot read the model document: " + text.error().message,
                          text.error().hint.empty() ? "Model documents are *.model.json files; model.create writes a starting point." : text.error().hint);
    auto json = parse_json(*text, path);
    if (!json) return json.error();
    return parse_model_doc(*json, path, issues);
}

// ---- finding nodes -----------------------------------------------------------------------------------------------------------

namespace {

void collect_ids(const Json& list, const std::string& base, std::vector<std::pair<std::string, std::string>>& out) {
    if (!list.is_array()) return;
    for (std::size_t i = 0; i < list.size(); ++i) {
        const Json& n = list[i];
        if (!n.is_object()) continue;
        const std::string at = base + "/" + std::to_string(i);
        if (n.contains("id") && n["id"].is_string()) out.emplace_back(n["id"].get<std::string>(), at);
        if (n.contains("children")) collect_ids(n["children"], at + "/children", out);
    }
}

}  // namespace

std::vector<std::pair<std::string, std::string>> model_node_ids(const Json& documentJson) {
    std::vector<std::pair<std::string, std::string>> out;
    if (documentJson.is_object() && documentJson.contains("nodes")) collect_ids(documentJson["nodes"], "/nodes", out);
    return out;
}

Json* find_model_node(Json& doc, std::string_view ref, std::string* pointer, std::string* why) {
    auto fail = [&](std::string message) -> Json* {
        if (why) *why = std::move(message);
        return nullptr;
    };
    const auto ids = model_node_ids(doc);
    std::vector<std::string> names;
    for (const auto& [id, at] : ids) names.push_back(id);
    const std::string known = names.empty() ? "The document has no node ids yet (model.edit's `add` gives every new node one)." : "Ids in the document: " + quoted_list(names) + ".";
    if (ref.empty()) return fail("Empty node reference. " + known);
    std::string at;
    if (ref[0] == '/') {
        at = std::string(ref);
    } else {
        for (const auto& [id, p] : ids)
            if (id == ref) at = p;
        if (at.empty()) return fail("No node has the id \"" + std::string(ref) + "\". " + did_you_mean(ref, names));
    }
    // walk the pointer by hand: only /nodes/<i> and /children/<i> are nodes
    const std::vector<std::string> parts = split(at, '/');
    if (parts.size() < 2 || parts[0] != "nodes" || parts.size() % 2 != 0) return fail("'" + at + "' is not a node pointer. Node pointers look like /nodes/0 or /nodes/1/children/2. " + known);
    Json* cur = &doc;
    for (std::size_t i = 0; i < parts.size(); ++i) {
        if (i % 2 == 1) {
            const std::string& idx = parts[i];
            if (idx.empty() || !std::all_of(idx.begin(), idx.end(), [](char c) { return c >= '0' && c <= '9'; }) || idx.size() > 6)
                return fail("'" + at + "': '" + idx + "' is not a list position. " + known);
            const std::size_t k = std::stoul(idx);
            if (!cur->is_array() || k >= cur->size()) return fail("'" + at + "' is outside the document (position " + idx + " of " + std::to_string(cur->is_array() ? cur->size() : 0) + "). " + known);
            cur = &(*cur)[k];
        } else {
            if (parts[i] != (i == 0 ? "nodes" : "children") || !cur->is_object() || !cur->contains(parts[i])) return fail("'" + at + "' does not lead to a node. " + known);
            cur = &(*cur)[parts[i]];
        }
    }
    if (!cur->is_object()) return fail("'" + at + "' is not a node. " + known);
    if (pointer) *pointer = at;
    return cur;
}

// ---- schema ------------------------------------------------------------------------------------------------------------------

namespace {

Json number_schema(const ModelFieldInfo& f, bool whole) {
    Json s = Json::object({{"type", whole ? "integer" : "number"}});
    if (f.min) s["minimum"] = whole ? Json(static_cast<long long>(*f.min)) : Json(*f.min);
    if (f.max) s["maximum"] = whole ? Json(static_cast<long long>(*f.max)) : Json(*f.max);
    return s;
}

Json field_schema(const ModelFieldInfo& f) {
    Json s;
    const std::string& t = f.type;
    if (t == "number") s = number_schema(f, false);
    else if (t == "integer") s = number_schema(f, true);
    else if (t == "boolean") s = Json::object({{"type", "boolean"}});
    else if (t == "string") s = Json::object({{"type", "string"}});
    else if (t == "choice") s = Json::object({{"type", "string"}, {"enum", f.choices}});
    else if (t == "vec3" || t == "size3" || t == "count3" || t == "count2") {
        const bool counts = t == "count3" || t == "count2";
        const std::size_t n = t == "count2" ? 2 : 3;
        Json array = Json::object({{"type", "array"}, {"items", number_schema(f, counts)}, {"minItems", n}, {"maxItems", n}});
        if (t == "vec3") s = array;
        else s = Json::object({{"anyOf", Json::array({number_schema(f, counts), array})}});
    } else if (t == "color") {
        Json array = Json::object({{"type", "array"}, {"items", Json::object({{"type", "number"}, {"minimum", 0}, {"maximum", 1}})}, {"minItems", 3}, {"maxItems", 4}});
        s = Json::object({{"anyOf", Json::array({array, Json::object({{"type", "string"}, {"pattern", "^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$"}})})}});
    } else if (t == "points2" || t == "points3") {
        const std::size_t n = t == "points2" ? 2 : 3;
        s = Json::object({{"type", "array"}, {"items", Json::object({{"type", "array"}, {"items", number_schema(f, false)}, {"minItems", n}, {"maxItems", n}})}});
        if (f.minItems) s["minItems"] = std::size_t(*f.minItems);
        if (f.maxItems) s["maxItems"] = std::size_t(*f.maxItems);
    } else if (t == "rings") {
        Json section = Json::object({{"type", "array"}, {"items", Json::object({{"type", "array"}, {"items", number_schema(f, false)}, {"minItems", 3}, {"maxItems", 3}})}});
        if (f.innerMinItems) section["minItems"] = std::size_t(*f.innerMinItems);
        if (f.innerMaxItems) section["maxItems"] = std::size_t(*f.innerMaxItems);
        s = Json::object({{"type", "array"}, {"items", section}});
        if (f.minItems) s["minItems"] = std::size_t(*f.minItems);
        if (f.maxItems) s["maxItems"] = std::size_t(*f.maxItems);
    } else if (t == "nodes") {
        s = Json::object({{"type", "array"}, {"items", Json::object({{"$ref", "#/$defs/node"}})}});
    }
    s["description"] = f.doc;
    if (f.def) s["default"] = *f.def;
    return s;
}

}  // namespace

Json model_doc_schema() {
    Json defs = Json::object();
    Json alternatives = Json::array();
    for (const ModelOpInfo& op : model_ops()) {
        Json props = Json::object();
        Json required = Json::array({"op"});
        props["op"] = Json::object({{"const", op.op}, {"description", "Always \"" + op.op + "\" for this node."}});
        for (const ModelFieldInfo& f : model_common_fields()) {
            if (f.key == "op") continue;
            props[f.key] = field_schema(f);
        }
        if (op.kind == "primitive" || op.op == "sdf")
            for (const ModelFieldInfo& f : model_align_fields()) props[f.key] = field_schema(f);
        for (const ModelFieldInfo& f : op.fields) {
            props[f.key] = field_schema(f);
            if (f.required) required.push_back(f.key);
        }
        defs[op.op] = Json::object({{"type", "object"}, {"description", op.doc}, {"required", required}, {"additionalProperties", false}, {"properties", props}});
        alternatives.push_back(Json::object({{"$ref", "#/$defs/" + op.op}}));
    }
    defs["node"] = Json::object({{"description", "One operation of the tree: a primitive, a modifier (wraps its `children`) or a group. `op` says which."}, {"oneOf", alternatives}});
    Json material = Json::object(
        {{"type", "object"},
         {"additionalProperties", false},
         {"description", "A material, named by its key in `materials`. Written into the .glb as a glTF material."},
         {"properties",
          Json::object({{"color", Json::object({{"type", "array"}, {"items", Json::object({{"type", "number"}})}, {"minItems", 3}, {"maxItems", 4}, {"description", "Base colour [r, g, b, a], 0..1. Default white."}})},
                        {"texture", Json::object({{"type", "string"}, {"description", "A project image used as the base colour texture, e.g. \"assets/textures/wood.png\". The model's uvs are per primitive (docs/MODELING.md)."}})},
                        {"metallic", Json::object({{"type", "number"}, {"minimum", 0}, {"maximum", 1}, {"description", "0..1. Default 0."}})},
                        {"roughness", Json::object({{"type", "number"}, {"minimum", 0}, {"maximum", 1}, {"description", "0..1. Default 0.6."}})},
                        {"emissive", Json::object({{"type", "array"}, {"items", Json::object({{"type", "number"}})}, {"minItems", 3}, {"maxItems", 4}, {"description", "Light the surface gives off [r, g, b], 0..1. Default none."}})},
                        {"doubleSided", Json::object({{"type", "boolean"}, {"description", "Draw back faces too (flat leaves, cloth). Default false."}})},
                        {"blend", Json::object({{"type", "boolean"}, {"description", "Alpha-blended (glass); the alpha of `color` and of vertex colours shows. Default false."}})}})}});
    return Json::object(
        {{"$schema", "https://json-schema.org/draft/2020-12/schema"},
         {"$id", "https://factoria.dev/schemas/model.schema.json"},
         {"title", "FactorIA model document (*.model.json)"},
         {"description", "A 3D model as a tree of operations (primitives, modifiers, organic `sdf` shapes, groups, transforms) with named parts, materials and vertex colours. `model.bake` evaluates it and writes the .glb next to it; the same bytes on every platform. Errors name the file and the JSON pointer; docs/MODELING.md explains the format and `model.info {}` lists the operations."},
         {"type", "object"},
         {"required", Json::array({"format", "nodes"})},
         {"additionalProperties", false},
         {"properties",
          Json::object({{"$schema", Json::object({{"type", "string"}, {"description", "Optional schema reference for editors."}})},
                        {"format", Json::object({{"const", kModelDocFormat}, {"description", std::string("File format identifier. Always \"") + kModelDocFormat + "\"."}})},
                        {"doc", Json::object({{"type", "string"}, {"description", "What the model is and where the game uses it."}})},
                        {"output", Json::object({{"type", "object"}, {"additionalProperties", false}, {"description", "Where `model.bake` writes the .glb."},
                                                 {"properties", Json::object({{"path", Json::object({{"type", "string"}, {"pattern", "\\.[gG][lL][bB]$"}, {"description", "Project-relative file under assets/ ending in .glb. Left out: next to the document, with .glb instead of .model.json."}})}})}})},
                        {"materials", Json::object({{"type", "object"}, {"description", "Named materials the nodes refer to with `material`."}, {"additionalProperties", material}})},
                        {"nodes", Json::object({{"type", "array"}, {"description", "The tree: operations evaluated in order and merged into one mesh."}, {"items", Json::object({{"$ref", "#/$defs/node"}})}})}})},
         {"$defs", defs}});
}

}  // namespace fa
