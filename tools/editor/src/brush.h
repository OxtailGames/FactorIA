// The brush that the editor's viewport tools share (terrain sculpt, paint and holes, and foliage paint): its settings, the
// collection of a stroke's points while the mouse is down, the geometry of the cursor ring and the ray that finds the ground under
// the mouse. Plain functions and a small class of (floats, vectors): no ImGui, no renderer, no Editor, so the maths is tested in
// brush_tests.cpp and a tool only adds what is its own (which command a stamp is sent to, and with which arguments).
//
// A tool uses it like this: on the mouse press `stroke.begin(hitXZ, settings.radius)`; every frame while the button is down
// `stroke.add(hitXZ)` and `stroke.take_pending(...)` (the new stamps, spacing apart along the path, in the order the mouse drew
// them); on the release `stroke.end()`. The points are in the tool's ground plane, x and z of the world, in the metres the
// commands use (the same origin-relative numbers `terrain.sculpt` takes).
#pragma once

#include <cstddef>
#include <functional>
#include <vector>

#include "fa/core/math.h"

namespace fa::editor {

// What the user dials in for a brush. The tool owns the other parameters of its mode (a height to flatten to, a layer, cut or fill).
struct BrushSettings {
    float radius = 8.0f;    // world metres
    float strength = 0.5f;  // 0..1: how much of the effect one stamp applies
    float falloff =
        1.0f;  // 0..1: the share of the radius the effect fades over (1 = from the middle to the edge, 0 = hard edge)
};

inline constexpr float kBrushMinRadius = 0.05f;
inline constexpr float kBrushMaxRadius = 4096.0f;
// A stamp every radius / kBrushStampsPerRadius along the path of the mouse.
inline constexpr float kBrushStampsPerRadius = 4.0f;
// The most stamps of one stroke (a stroke is one undo step; a hand holds the button for seconds, not for a thousand metres).
inline constexpr std::size_t kBrushMaxStrokePoints = 20000;

// Puts every field in its range (`maxRadius` caps the radius: a tool passes what its target allows).
void brush_clamp(BrushSettings& b, float maxRadius = kBrushMaxRadius);
// The distance between two stamps of a radius.
float brush_spacing(float radius, float stampsPerRadius = kBrushStampsPerRadius);
// The radius inside which the effect is at full strength: radius * (1 - falloff).
float brush_inner_radius(const BrushSettings& b);
// One press of `[` (steps < 0, smaller) or `]` (steps > 0, bigger): the radius times 1.25 per step (and 0.8 for a step down),
// within [kBrushMinRadius, maxRadius]. Strength moves 0.05 per step, within [0, 1].
void brush_step_radius(BrushSettings& b, int steps, float maxRadius = kBrushMaxRadius);
void brush_step_strength(BrushSettings& b, int steps);

// The points of one stroke. begin() stamps the first point where the mouse went down; add() stamps a point every `spacing` metres
// along the straight lines between the mouse positions it is given (the same path however the frames fall: a fast and a slow mouse
// over the same line give the same stamps up to the last partial step).
class BrushStroke {
public:
    // Starts a stroke at `p` with stamps radius / `stampsPerRadius` apart (4 unless a tool needs fewer, bigger stamps: the foliage
    // brush uses 2). Drops the points of any stroke before it.
    void begin(Vec2 p, float radius, float stampsPerRadius = kBrushStampsPerRadius);
    // The mouse is now at `p`: appends the stamps between the last stamp and `p`. Returns how many were added (0 while the mouse has
    // moved less than the spacing). Nothing happens outside a stroke, and once kBrushMaxStrokePoints are collected (`full()`).
    int add(Vec2 p);
    // Moves up to `max` points that were not taken yet into `out` (appended), in order; returns how many.
    std::size_t take_pending(std::vector<Vec2>& out, std::size_t max = 512);
    std::size_t pending() const { return points_.size() - taken_; }
    void end();
    bool active() const { return active_; }
    bool full() const { return points_.size() >= kBrushMaxStrokePoints; }
    float spacing() const { return spacing_; }
    // Every point of the stroke so far (taken or not), and how many were taken.
    const std::vector<Vec2>& points() const { return points_; }
    std::size_t taken() const { return taken_; }

private:
    std::vector<Vec2> points_;
    std::size_t taken_ = 0;
    Vec2 last_{};
    float spacing_ = 1.0f;
    bool active_ = false;
};

// The ring of the cursor: `segments` points (at least 8) of the circle of `radius` around `center`, first point on +x, going
// round once (not repeated at the end). A tool lifts each onto its ground and draws a closed polyline.
std::vector<Vec2> brush_ring(Vec2 center, float radius, int segments = 48);

// The ground under a ray. `surface(x, z, y)` gives the height of the ground at (x, z) and false where there is none. The ray
// `origin + t * dir` is walked from t0 to t1 in `steps` equal steps (a count, never a time: the same ray finds the same point on
// any machine); the first step that goes from above the ground to below it is refined by bisection. False when the ray never
// crosses the ground between t0 and t1 (or starts under it).
using BrushSurface = std::function<bool(float x, float z, float& y)>;
bool brush_ray_ground(Vec3 origin, Vec3 dir, float t0, float t1, int steps, const BrushSurface& surface, Vec3& hit);
// The part of the ray inside the box [lo, hi]: t0 <= t1, within [0, +inf). False when it misses the box.
bool brush_ray_box(Vec3 origin, Vec3 dir, Vec3 lo, Vec3 hi, float& t0, float& t1);

}  // namespace fa::editor
