// 2D bones, skinned sprites and IK (docs/ANIMATION.md, "Bones and IK"). No GPU: the renderer (render/scene2d.cpp), the bounds
// of an entity (bounds.h) and the editor all ask the same functions, so what is drawn is what is measured and picked.
//
//   * Bone2D     an entity of the hierarchy. The bone starts at the entity's origin and runs `length` along its local +X axis.
//                Clips, scripts and IK2D pose it through its Transform.
//   * SpriteSkin deforms the 2D mesh of the Sprite on the same entity: the `Sprite.meshColumns` x `meshRows` grid, or with
//                `outline` a grid cut to the opaque pixels of the texture. A vertex follows up to 4 bones. The skin keeps the
//                pose the bones had when it was bound (`bindPose`, in the sprite's local space); a bone that moved from it drags
//                its vertices by the difference. Order of the maths per vertex: grid place, Sprite.vertexOffsets, bones,
//                Sprite.skew, the entity's matrix.
//   * IK2D       turns the bones of a chain that ends at its entity so the tip reaches a target, within the bones' angle limits.
//
// Everything here is a pure function of the World (and, for an outline, of the texture file): the same scene gives the same bits
// on every platform. The IK uses fa::det trigonometry; the skin uses only + - * /.
#pragma once

#include <array>
#include <cstdint>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/math.h"
#include "fa/core/types.h"
#include "fa/scene/components.h"
#include "fa/scene/world.h"

namespace fa {

constexpr int kMaxSkinBones = 64;         // bones a SpriteSkin can name
constexpr int kMaxBonesPerVertex = 4;     // bones a vertex follows
constexpr int kIkMaxSweeps = 24;          // sweeps of the ccd solver per step

// ---------------------------------------------------------------------------------------------------------------- affine --
// A 2D affine map: x' = a x + c y + tx, y' = b x + d y + ty (columns (a, b) and (c, d), the same layout as Mat4's x and y axes).
struct Affine2 {
    float a = 1, b = 0, c = 0, d = 1, tx = 0, ty = 0;
    Vec2 apply(Vec2 p) const { return {a * p.x + c * p.y + tx, b * p.x + d * p.y + ty}; }
    Vec2 apply_dir(Vec2 v) const { return {a * v.x + c * v.y, b * v.x + d * v.y}; }
    float determinant() const { return a * d - b * c; }
    // `*this` applied after `o`: (m * o).apply(p) == m.apply(o.apply(p)).
    Affine2 operator*(const Affine2& o) const;
    // The inverse; the identity (and *invertible = false) when the map is singular.
    Affine2 inverse(bool* invertible = nullptr) const;
    static Affine2 from_mat4(const Mat4& m);
    bool operator==(const Affine2& o) const { return a == o.a && b == o.b && c == o.c && d == o.d && tx == o.tx && ty == o.ty; }
};

// ---------------------------------------------------------------------------------------------------------------- bones --
struct BoneSegment {
    Vec2 origin, tip;  // world positions: the entity's origin and origin + (length, 0) in its own frame
};
// The segment of a Bone2D entity in the world. An entity without a Bone2D gives a zero segment at its origin.
BoneSegment bone_world_segment(const World& w, Entity bone);
// The outline the editor and debug.bones() draw for a bone: a long thin kite, origin -> shoulder -> tip -> shoulder -> origin.
// Returned as {origin, shoulder left, tip, shoulder right}; the shoulders sit a fifth of the way along, a tenth of the length out.
std::array<Vec2, 4> bone_kite(const BoneSegment& segment);
// `z` (degrees) kept inside [minAngle, maxAngle] of the bone, the nearest limit when outside. A bone whose limits span 360 degrees
// or more is free. The result is the angle in the range's own turn, so a value may change by a multiple of 360.
float bone_clamp_angle(const Bone2D& bone, float z);

// ----------------------------------------------------------------------------------------------------------------- skin --
// The bones named by `skin.bones`, in order (kNullEntity where one is missing). `problems` gets one teaching sentence per name
// that finds no Bone2D, per entry that is not a string, and when there are more than kMaxSkinBones.
struct SkinBones {
    std::vector<Entity> entities;
    std::vector<std::string> problems;
};
SkinBones skin_resolve_bones(const World& w, Entity owner, const SpriteSkin& skin);

// The bind pose of a skin as matrices (bone in the sprite's local space); empty when `bindPose` does not hold exactly six finite
// numbers per bone of `boneCount`.
std::vector<Affine2> skin_bind_matrices(const SpriteSkin& skin, std::size_t boneCount);
// True when `e` has a SpriteSkin whose bindPose fits its bones.
bool skin_is_bound(const World& w, Entity e);
// Records the bind pose: where the bones are now relative to the sprite. Error (with a hint) when `e` has no SpriteSkin, no
// bone is found, or the sprite's matrix cannot be inverted (scale 0). Binding again overwrites.
Result<void> skin_bind(World& w, Entity e);
// Binds every SpriteSkin that has bones and no (valid) bindPose. The engine calls it when a scene loads and at the start of every
// fixed step, before the animators move any bone, and the renderer before it draws, so a skin binds at the pose the scene was
// authored in. Entities that cannot bind yet (a bone not found) are left for the next call.
void bind_pending_skins(World& w);

// The local rectangle a sprite covers, as the renderer lays it out: x0,y0 the bottom-left corner, x1,y1 the top-right
// (sprite size placed by the pivot).
struct SkinBox {
    float x0 = 0, y0 = 0, x1 = 0, y1 = 0;
};

// The deformed mesh of a skinned sprite, in the sprite's local space (before skew and the entity matrix).
struct SkinMesh {
    int columns = 0, rows = 0;                    // the grid the mesh was cut from
    std::vector<Vec2> position;                   // one per used vertex, after offsets and bones
    std::vector<Vec2> uv;                         // the same vertices: fraction of the region, x across, y DOWN (0 = top edge)
    std::vector<std::array<std::uint32_t, 4>> quads;  // vertex indices of each cell, in the winding the renderer draws
};

// Builds the mesh of the SpriteSkin on `e` for `sprite` laid out in `box`. False with `*problem` set when it cannot (no SpriteSkin
// leaves it empty; a sprite with neither a mesh grid nor `outline` says how to fix it). May return true and still set `*problem`
// (an outline that could not be traced draws the full grid; bones that were not found are left out): log it once.
// A skin that is not bound yet draws undeformed. `problem` may be null.
bool build_skin_mesh(const World& w, Entity e, const Sprite& sprite, const SkinBox& box, SkinMesh& out, std::string* problem);

// One vertex's bones: up to 4, weights summing to 1.
struct VertexWeights {
    std::array<std::uint8_t, kMaxBonesPerVertex> bone{};
    std::array<float, kMaxBonesPerVertex> weight{};
    int count = 0;
};
// Automatic weights: each vertex follows its nearest bones with weight 1 / (distance to the bone's segment^2 + 0.25), the top 4,
// dropping any under 2% of the total, normalised. `segments` are the bones' {origin, tip} in the vertices' space; a bone with a
// zero-size segment (origin == tip) acts as a point. Ties go to the lower bone index. Deterministic.
std::vector<VertexWeights> auto_skin_weights(const std::vector<Vec2>& vertices, const std::vector<std::pair<Vec2, Vec2>>& segments);
// The automatic weights of the skin on `e` written as explicit ones (the `weights` array format, one entry per vertex of the full
// grid): what to paint over. Error when `e` has no skin, mesh or bones.
Result<Json> skin_auto_weights(const World& w, Entity e, const SkinBox& box);

// The grid of an outline mesh: which cells of a columns x rows grid over `region` of the texture hold opaque pixels (alpha above
// 5%). `traced` false when the image could not be read: every cell is kept and `problem` says why. Cached per texture file and
// region; the first call reads the image.
struct OutlineGrid {
    int columns = 0, rows = 0;
    std::vector<std::uint8_t> keep;  // rows * columns, row 0 = top; 1 = keep
    bool traced = false;
    std::string problem;
};
std::shared_ptr<const OutlineGrid> sprite_outline_grid(const std::string& texture, Rect region, int columns, int rows);
// Forgets the traced outlines of a texture file ("" = all): the renderer calls it when a texture is reloaded.
void invalidate_sprite_outlines(std::string_view texture = {});
// The columns and rows of an outline grid of `detail` cells along the longer side of `box`.
void skin_outline_dimensions(const SkinBox& box, int detail, int& columns, int& rows);

// -------------------------------------------------------------------------------------------------------------------- IK --
// Solves the IK2D on `e` now: moves the tip of the chain to the target, within the angle limits, and writes the bones'
// Transform.rotation.z (blended by IK2D.weight). Returns the distance left between the tip and the target in world units
// (0 = reached), or an error that teaches (no Bone2D, no target, a chain that is shorter than it says).
Result<float> solve_ik2d(World& w, Entity e);
// Solves every active IK2D in the order the components were added. The engine calls it every fixed step right after the
// animators have posed the bones. Problems are logged once per component.
void update_ik2d(World& w);

}  // namespace fa
