// The mesh kernel of model documents (*.model.json, docs/MODELING.md): parametric primitives, transforms and the helpers a
// document is evaluated with. GPU-free and deterministic: the same parameters give the same bits on every platform (the
// trigonometry is fa::det, the arithmetic is + - * / and sqrt on floats, the engine builds without FP contraction).
//
// Why fa_scene: the kernel's product is a mesh in the form MeshStore and `mesh.save` already take (MeshInput / MeshData, a .glb
// by mesh_to_glb), and it needs nothing above core. Tools, the runtime and the editor can all evaluate a model; the only
// thing the kernel cannot do alone is read a font, so the `text` primitive takes the glyph outlines from its caller
// (ModelTextOutline, which fa_render's outline_text fills).
//
// Conventions are the engine's and glTF's: 3D units are meters, right-handed, +Y up, counter-clockwise triangles face front,
// uv (0, 0) is the top-left of the image (v grows downwards). Every primitive is built CENTRED on the origin (its bounding
// box is symmetric; `text` starts at its baseline) and every builder takes parameters that are already valid: the document
// layer (model_doc.h) checks them and says what is wrong; a builder only clamps what would make it crash.
#pragma once

#include <cstdint>
#include <string>
#include <vector>

#include "fa/core/math.h"
#include "fa/core/types.h"

namespace fa {

// An indexed triangle mesh with the attributes the kernel makes. `triParts` says which part of the model each triangle belongs
// to (an index into the evaluator's part list); a primitive leaves it at 0 and the evaluator sets it.
struct ModelMesh {
    std::vector<Vec3> positions;
    std::vector<Vec3> normals;  // unit length, pointing out of the solid
    std::vector<Vec2> uvs;
    std::vector<Vec4> colors;             // empty, or one RGBA per vertex
    std::vector<std::uint32_t> indices;   // three per triangle, counter-clockwise seen from outside
    std::vector<std::uint32_t> triParts;  // one per triangle

    std::size_t vertex_count() const { return positions.size(); }
    std::size_t triangle_count() const { return indices.size() / 3; }
    bool empty() const { return indices.empty(); }

    // Adds `other` after this mesh (its indices are shifted). Colours: when only one of the two has them, the other's vertices are white.
    void append(const ModelMesh& other);
    // Applies `m` (a rigid, scaling or mirroring matrix) to the positions and the matching normal matrix to the normals; a mirror
    // (negative determinant) reverses the winding so the triangles keep facing out.
    void transform(const Mat4& m);
    void set_part(std::uint32_t part);
    void set_color(Vec4 rgba);                  // every vertex
    void bounds(Vec3& bmin, Vec3& bmax) const;  // (0,0,0) twice when empty
};

// ---- primitives (docs/MODELING.md has the picture of each) -------------------------------------------------------------

struct ModelBoxParams {
    Vec3 size{1, 1, 1};
    int segX = 1, segY = 1, segZ = 1;  // subdivisions per axis (each face is a grid)
};
struct ModelRoundedBoxParams {
    Vec3 size{1, 1, 1};
    float radius = 0.1f;  // of the edges; at most half the smallest side
    int segments = 4;     // quads in each rounded corner arc
};
struct ModelCylinderParams {
    float radius = 0.5f;
    float radiusTop = -1;  // < 0: the same as `radius`
    float height = 1;
    int segments = 24;
    int heightSegments = 1;
    bool capBottom = true, capTop = true;
};
struct ModelConeParams {
    float radius = 0.5f;
    float radiusTop = 0;  // 0 = a point; above 0 cuts the tip off (a frustum)
    float height = 1;
    int segments = 24;
    int heightSegments = 1;
    bool cap = true;  // the disc closing the base
};
struct ModelSphereParams {
    float radius = 0.5f;
    int segments = 24;  // around the vertical axis
    int rings = 0;      // pole to pole; 0 = segments / 2
};
struct ModelCapsuleParams {
    float radius = 0.5f;
    float height = 2;  // tip to tip, hemispheres included (at least 2 * radius)
    int segments = 24;
    int rings = 8;  // per hemisphere
    int heightSegments = 1;
};
// The ranges of the torus' `segments` and `sides`: the model.* schema (model_doc.cpp) and the builder clamp use these.
inline constexpr int kTorusMinSegments = 3, kTorusMaxSegments = 256;
inline constexpr int kTorusMinSides = 3, kTorusMaxSides = 128;
struct ModelTorusParams {
    float radius = 0.5f;  // of the ring (the circle through the middle of the tube)
    float tube = 0.15f;   // radius of the tube
    int segments = 32;    // around the ring
    int sides = 16;       // around the tube
};
struct ModelGridParams {
    float width = 1, depth = 1;  // along X and Z
    int segX = 1, segZ = 1;
};
struct ModelStairsParams {
    int steps = 6;
    float width = 1;     // along X
    float height = 1;    // top of the last step above the bottom
    float depth = 1.5f;  // along Z; the stairs climb towards -Z
};
struct ModelArchParams {
    float width = 2, height = 2.5f, depth = 0.4f;  // the wall: X, Y, Z
    float openingWidth = 1,
          openingHeight = 1.8f;  // the doorway through it, from the bottom edge, its top a half circle
    int segments = 12;           // in the half circle
};
struct ModelPipeParams {
    float radius = 0.5f;       // outer
    float innerRadius = 0.4f;  // the hole's
    float height = 1;
    int segments = 24;
};

ModelMesh model_box(const ModelBoxParams& p);
ModelMesh model_rounded_box(const ModelRoundedBoxParams& p);
ModelMesh model_cylinder(const ModelCylinderParams& p);
ModelMesh model_cone(const ModelConeParams& p);
ModelMesh model_sphere(const ModelSphereParams& p);
ModelMesh model_capsule(const ModelCapsuleParams& p);
ModelMesh model_torus(const ModelTorusParams& p);
ModelMesh model_grid(const ModelGridParams& p);
ModelMesh model_stairs(const ModelStairsParams& p);
ModelMesh model_arch(const ModelArchParams& p);
ModelMesh model_pipe(const ModelPipeParams& p);

// ---- text --------------------------------------------------------------------------------------------------------------

// Glyph outlines as fa_render's outline_text gives them: commands in units of the em, y DOWN, the origin on the first
// baseline. The kernel flattens the curves, finds which contours are holes and extrudes.
struct ModelGlyphCmd {
    enum Kind : std::uint8_t { Move, Line, Quad, Cubic, Close } kind = Move;
    float x = 0, y = 0;    // the end point (Move, Line, Quad, Cubic)
    float cx = 0, cy = 0;  // Quad: its control point; Cubic: the first control point
    float dx = 0, dy = 0;  // Cubic: the second control point
};
struct ModelTextOutline {
    std::vector<ModelGlyphCmd> cmds;
    int glyphs = 0;
    std::vector<char32_t> missing;  // visible characters no font has
};
struct ModelTextParams {
    float size = 1;         // meters per em
    float depth = 0.2f;     // thickness along Z
    int curveSegments = 6;  // lines per curve of a glyph
};
// The text of `outline` as a solid: front face towards +Z (it reads left to right along +X), baseline at y = 0, centred in Z.
// Empty when the outline has no ink.
ModelMesh model_text(const ModelTextOutline& outline, const ModelTextParams& p);

// ---- extrusion and triangulation (also used by stairs-like and arch-like shapes of later modifiers) ------------------------

// Fills the polygon `outer` (counter-clockwise) minus `holes` (clockwise) with triangles: indices into the concatenation
// outer, hole 0, hole 1, ... Ear clipping with the holes bridged to the outline; a polygon that is not simple still ends, with
// the triangles that could be made. Empty when there are fewer than 3 points.
std::vector<std::uint32_t> triangulate_polygon(const std::vector<Vec2>& outer,
                                               const std::vector<std::vector<Vec2>>& holes);

struct ModelPolygon {
    std::vector<Vec2> outer;               // counter-clockwise
    std::vector<std::vector<Vec2>> holes;  // clockwise
};
// Pushes the polygons (in the XY plane, y up) along Z from -depth/2 to +depth/2: a front cap facing +Z, a back cap facing -Z and the
// side walls. A wall corner whose two edges turn less than `creaseDeg` shares one smooth normal; sharper corners stay hard.
// Cap uvs are the planar projection onto the polygons' bounding box; wall uvs are (distance along the contour / its length, z).
ModelMesh extrude_polygons(const std::vector<ModelPolygon>& polygons, float depth, float creaseDeg);

// ---- measuring ---------------------------------------------------------------------------------------------------------

struct ModelMeshStats {
    std::size_t vertices = 0, triangles = 0;
    std::size_t weldedVertices = 0;       // distinct positions (to 1e-5), what the surface really has
    std::size_t boundaryEdges = 0;        // edges used by one triangle (a hole in the surface)
    std::size_t nonManifoldEdges = 0;     // edges used by more than two triangles, or twice in the same direction
    std::size_t degenerateTriangles = 0;  // zero area
    double volume = 0;                    // signed: positive when the triangles face outward
    double area = 0;
    Vec3 bmin{}, bmax{};
    bool closed() const { return triangles > 0 && boundaryEdges == 0 && nonManifoldEdges == 0; }
};
ModelMeshStats model_mesh_stats(const ModelMesh& m);

}  // namespace fa
