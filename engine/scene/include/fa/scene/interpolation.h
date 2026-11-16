// Render interpolation: a 60 Hz simulation drawn smoothly on a 120-144 Hz display. docs/RENDERING.md, "Render interpolation".
//
// The simulation moves entities in fixed steps. A frame that runs 0 or 1 steps would draw the same pose twice and then jump;
// with interpolation the renderer draws the pose BETWEEN the last two fixed steps: the pose before the latest step blended
// with the pose after it by alpha = (time since the latest step) / (fixed step length). The picture is one step behind the
// simulation (at 60 Hz, 16.7 ms), which is what makes it smooth.
//
// THE BLEND NEVER REACHES THE SCENE. Like the visual poses of game feel (feel.h) it is applied at DRAW time by
// World::drawn_matrix(), per entity of the chain, on the LOCAL pose: a child of an interpolated parent follows the blended
// parent, and a camera's view is built from its blended pose. Transform, physics, scripts, commands, bounds, audio and saved
// scenes read the real (latest) pose; physics bodies are interpolated through their entity's Transform (physics writes it
// every step).
//
// WHO IS INTERPOLATED. `render.interpolation` of factoria.json (World::interp().enabled) is the default of every entity; the
// Interpolation component overrides it per entity ("on" / "off" / "inherit"). Only interpolated entities pay (a record each).
//
// NO SMEARING. A pose is blended only when the latest fixed step moved it. These snap to the real pose instead: an entity that
// appeared (a record starts with prev == current), a Transform written outside the fixed steps (a script's update or
// lateUpdate, a command, the editor: seen as "the Transform is not what the last step left"; such an entity is drawn at its
// real pose, which is smooth when it moves per frame), a jump larger than `snapDistance`, and an explicit
// World::interp_teleport (script: entity.teleport()).
//
// WHEN IT IS OFF. alpha = 1 (Engine::step, headless runs with --frames, a paused game and the editor's pause / step show the
// real pose), or no entity interpolated: drawn_matrix is exactly what it was.
#pragma once

#include <cstddef>
#include <cstdint>
#include <vector>

#include "fa/core/math.h"
#include "fa/core/types.h"
#include "fa/scene/components.h"

namespace fa {

class World;

// One interpolated entity. InterpState::records is a dense list (one record per interpolated entity, no more), found from
// the entity through InterpState::slots.
struct InterpRecord {
    std::uint64_t bits = 0;  // Entity::bits() it belongs to
    std::uint32_t seen = 0;  // InterpState::stamp of the last walk that met the entity (a record not met is dropped)
    bool hasPose = false;    // `pose` is what to draw this frame
    bool teleport = false;   // World::interp_teleport was called: the next step end snaps
    Transform prev;          // local pose before the latest fixed step
    Transform last;  // local pose the latest fixed step (or a snap) left: what the Transform must still be to blend
    Transform pose;  // the blend, rotation in euler degrees
};

class InterpState {
public:
    bool enabled = false;  // factoria.json render.interpolation: the default of entities whose component says "inherit"
    float snapDistance =
        0.0f;  // factoria.json render.interpolationSnapDistance: a step that moved farther snaps; 0 = off
    std::vector<InterpRecord> records;  // dense: one per interpolated entity
    std::vector<std::uint32_t> slots;  // Entity::index -> position in `records` + 1 (0 = none); 4 bytes per entity slot
    std::uint32_t stamp = 0;           // counts the update walks
    std::size_t poseCount = 0;         // records with hasPose: 0 = drawn_matrix has nothing to blend

    // The blended local pose of `e` for this frame, or null (not interpolated, not moving, snapped).
    const Transform* pose_of(Entity e) const {
        if (poseCount == 0 || e.index >= slots.size() || slots[e.index] == 0) return nullptr;
        const InterpRecord& r = records[slots[e.index] - 1];
        return r.hasPose && r.bits == e.bits() ? &r.pose : nullptr;
    }
    void clear_poses();  // no blending (a paused game, alpha 1)
    void clear_scene();  // World::clear(): forget every record, keep the settings
};

// alpha for a frame: the part of the fixed step the frame is past the latest step, in [0, 1].
inline double interp_alpha(double accumulator, double fixedDt) {
    if (!(fixedDt > 0.0)) return 1.0;
    const double a = accumulator / fixedDt;
    return a < 0.0 ? 0.0 : (a > 1.0 ? 1.0 : a);
}

// The blend of two local poses at `alpha` (position and scale lerp, rotation slerp of the quaternions; a rotation that did not
// change is kept as it is, bit for bit; a pure z rotation, the 2D case, blends the angle itself). A rotation that turned more than
// 180 degrees on some axis in one step cannot be told from a shorter turn the other way, so it is NOT blended: the blended pose
// has the latest rotation.
Transform interp_blend(const Transform& a, const Transform& b, float alpha);

// Called by the engine. begin_step: before each fixed step, the pose now is the "before" pose. update: after the steps of a
// frame (stepped = true: the poses the steps left become the "after" poses) and again before drawing (stepped = false: a
// Transform written since is snapped). alpha 1 = nothing is blended.
void interp_begin_step(World& w);
void interp_update(World& w, double alpha, bool stepped);

}  // namespace fa
