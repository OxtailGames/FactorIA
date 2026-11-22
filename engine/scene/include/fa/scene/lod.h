// Level of detail of a MeshRenderer (MeshRenderer::lods) and of a LodGroup: which level to draw at a camera distance or a screen size,
// and how a cross-fade between two levels advances. Pure and stateless (the fade is a value the caller keeps), so the same input always
// picks the same level; the renderer calls these per entity per frame, and tests call them without a GPU.
//
// A LEVEL is a number: 0 is the most detailed (MeshRenderer.mesh, or the first child of a LodGroup), k is entry k - 1 of
// MeshRenderer.lods, or child k of the group.
#pragma once

#include <string>

#include "fa/scene/components.h"

namespace fa {

// The mesh of the entry of `mr.lods` with the greatest `distance` that is <= `distance`, or `mr.mesh` when none applies (nearer than the first entry,
// no entries, or entries that are malformed: not an object with a non-empty `mesh` string and a numeric `distance`). Entries are tried in the
// order given; the entry with the greatest distance among those reached wins (ties: the later one). Reads `distance` whatever lodMode says.
const std::string& lod_mesh(const MeshRenderer& mr, float distance);

// The camera as the screen size needs it: perspective (vertical field of view in degrees) or orthographic (half of the visible height in
// world units).
struct LodView {
    bool perspective = true;
    float fovY = 60.0f;
    float halfHeight = 5.0f;
};

// The height of the view in world units at `distance`: 2 * distance * tan(fovY / 2) in perspective, 2 * halfHeight in orthographic.
float lod_view_height(const LodView& view, float distance);

// The screen size of a sphere of `diameter` world units at `distance` from the camera: diameter / view height. 1 = as tall as the
// screen; a distance under 0.0001 counts as 0.0001 (the sphere is huge), a diameter that is not finite or is negative counts as 0.
float lod_screen_size(float diameter, float distance, const LodView& view);

// The level of `mr` for `distance` metres (the entry rule of lod_mesh, as a level: 0 = mr.mesh, k = lods[k - 1] counted among the
// entries as written, malformed ones included).
int lod_level_by_distance(const MeshRenderer& mr, float distance);
// The level for a screen size (lodMode screenSize): among the entries with a numeric `screenSize` and a non-empty `mesh` that the size
// is BELOW (strictly), the one with the smallest `screenSize` wins (ties: the later one); none = 0. A size that is NaN picks 0.
int lod_level_by_screen_size(const MeshRenderer& mr, float screenSize);
// The level by `mr.lodMode`: `distance` for Distance, `screenSize` for ScreenSize.
int lod_level_of(const MeshRenderer& mr, float distance, float screenSize);
// The mesh path of a level of `mr` (mr.mesh for 0 or a level with no entry).
const std::string& lod_level_mesh(const MeshRenderer& mr, int level);

// The level (child index) of a LodGroup of `childCount` children: in Distance mode the number of thresholds that `value` (metres)
// has reached (value >= threshold), in ScreenSize mode the number the `value` (a screen size) is below; at most childCount - 1 and
// at most the number of thresholds. -1 when the group has no children. A NaN value gives 0.
int lod_group_level(const LodGroup& g, int childCount, float value);

// A cross-fade between two levels, advanced one frame at a time (render-only state: never saved, never part of the simulation).
struct LodFadeState {
    int level = 0;   // the level drawn (fading in, or settled)
    int from = -1;   // the level fading out; -1 = no fade
    float t = 1.0f;  // 0..1: how far the fade is (1 = done)
    bool fading() const { return from >= 0 && t < 1.0f; }
};
// One frame of the fade: `target` is the level the metric picks now, `crossFade` the seconds a switch takes (<= 0 or NaN: a hard
// switch), `dt` the seconds since the previous frame (negative or NaN count as 0). A new target starts a fade of t = 0 that this
// call advances by dt / crossFade; switching back to the level that is fading out reverses the fade where it is (t becomes 1 - t, so
// the picture does not jump); a third level while fading drops the old one and starts from the level being faded in.
void lod_fade_step(LodFadeState& s, int target, float crossFade, float dt);
// The value the shader takes (mesh_common.glsl fa_lod_fade): 0 while not fading, else t kept within [1/256, 255/256] so a fade is never
// empty or full. The level fading in draws where the screen pattern is below it, the level fading out where it is not.
float lod_fade_amount(const LodFadeState& s);

}  // namespace fa
