// Floating origin helpers (M75.4, docs/BIG_WORLDS.md "Floating origin"): the arithmetic of a rebase. World::rebase does the shift;
// these decide WHEN and BY HOW MUCH, in one place the engine, the commands and the tests share.
//
// Why the offset is a whole multiple of `step` per axis, and `step` a power of two: a float position p far from 0 is a multiple of
// ulp(p) (a power of two), so p - k * step with a power-of-two `step` >= ulp(p) is a float again with no rounding, whatever k is. The
// origin (a double) then only ever holds sums of multiples of `step`: exact up to 2^53 steps, and a rebase by +offset followed by
// -offset gives back every position and the origin bit for bit. An arbitrary offset (say 1234.567) would round every shifted
// position, and each shift would add its own error to the origin.
#pragma once

#include <string>
#include <vector>

#include "fa/core/math.h"
#include "fa/core/types.h"

namespace fa {

class World;

// True when the TRANSFORM of root entity `e` is a position of the world (it shifts with the origin): false for a root with a UI widget
// (any UI widget: Panel, Button, ...) or with a screen-space Sprite, Shape2D, Text or ParticleEmitter, whose position is an offset on the screen.
bool follows_floating_origin(const World& world, Entity e);

// How far the TRANSFORM of root `root` moves (position -= result) when the origin shifts by `offset`: `offset` itself, except
// for a Parallax layer, which is drawn at position + camera * (1 - factor) and so moves by offset * factor on x and y (z by
// the whole offset) to keep (drawn - camera), what the player sees, unchanged when the camera moves by -offset.
Vec3 root_shift(const World& world, Entity root, Vec3 offset);

// Places entities that were just loaded ADDITIVELY at their absolute positions: every root among `entities` (and every
// world-anchored Joint2D/Joint3D, NavLink3D.end and LightProbeGroup point among them) moves by `delta` = file origin - world
// origin, the same things and the same arithmetic as World::rebase(-delta). `parented`: the load put the roots under an
// entity, so their positions are relative to it and nothing moves.
void place_loaded_entities(World& world, const std::vector<Entity>& entities, Vec3 delta, bool parented);

// The largest |offset| / step a float can hold exactly (2^24): beyond it `offset` is not a whole number of steps in float.
inline constexpr double kMaxRebaseSteps = 16777216.0;

// `v` rounded to the nearest whole multiple of `step` on every axis (ties away from 0). step must be > 0.
Vec3 snap_to_step(Vec3 v, double step);

// The offset a rebase by the anchor does: anchor (a LOCAL position) snapped to `step`; (0, 0, 0) when the anchor is within
// `threshold` of the local origin on every axis (3D: a flight or space game moves up as well; a ground game never has a large y).
Vec3 auto_rebase_offset(Vec3 anchorLocal, double threshold, double step);

// Teaches why `offset` cannot be a rebase offset (not finite, not a whole multiple of `step` on an axis, or more than kMaxRebaseSteps
// steps), with `pointer` ("/offset") in the message; ok when it is fine.
Result<void> check_rebase_offset(const DVec3& offset, double step, const std::string& pointer);

}  // namespace fa
