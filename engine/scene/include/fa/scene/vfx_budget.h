// What an effect document costs on a phone, worked out without a renderer (docs/PARTICLES.md, "Reviewing an effect"): vfx_measure plays
// the document in a scratch World, step by step, with the same update_vfx and ParticleSim a game runs, and counts the live particles
// and the screen they cover at every step. The numbers depend only on the document, the seed and the view size: the same call gives
// the same result on every machine.
//
// Overdraw is the quad area of 2D and screen-space emitters, whose sizes are design pixels. A 3D emitter's size is in world units and
// the camera decides what it covers: when VfxBudgetOptions::camera is given, its quads (camera-facing squares) are projected through
// that camera with the effect placed `cameraDistance` metres in front of it, on its axis; without a camera the particles count but
// the overdraw is not measured (the result says so in `notes`).
//
// It measures the particles the sim keeps alive. The renderer may drop some further (a camera that does not see them) or draw more
// (ribbon trails, a glow pass), so read the numbers as the cost of the effect on the screen it is played in, not as a frame time.
#pragma once

#include <cstdint>
#include <optional>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/scene/vfx.h"

namespace fa {

// What one device class can afford of ONE effect (a game plays several at once, so these are shares of the frame, not the frame).
struct VfxBudgetLimits {
    std::string name;       // "phone" or "desktop"
    int maxParticles = 0;   // live particles at the same time, all emitters of the effect together
    double maxOverdraw = 0; // the sum of the particles' quads, in screens: 1.0 = as much quad area as the view has
    int maxEmitters = 0;    // emitters in the effect
};
const VfxBudgetLimits& vfx_budget_limits(std::string_view name);  // "phone" (the default for anything else) or "desktop"

// Distance, in world units, in front of the main 3D camera where vfx.filmstrip and vfx.review play an effect when they get no
// `position`, and where vfx.budget places the effect to project its 3D quads. A few metres: far enough to see the effect whole.
inline constexpr double kVfxDefaultCameraDistance = 5.0;

// The camera a 3D emitter's quads are projected through (the project's main camera: lowest depth, active, primary).
struct VfxBudgetCamera {
    bool perspective = true;          // false: orthographic
    double fovDegrees = 60.0;         // perspective: vertical field of view
    double orthoHalfHeight = 1.0;     // orthographic: half the visible height, in world units
    double nearPlane = 0.1;           // a particle closer than this (along the view axis) is not drawn
    Vec3 forward{0, 0, -1};           // the camera's axes in the world, unit length
    Vec3 right{1, 0, 0};
    Vec3 up{0, 1, 0};
};

struct VfxBudgetOptions {
    std::uint32_t seed = 1;          // the sim's seed (an emitter's own seed is mixed from it and its part)
    double viewWidth = 1280;         // the view in design pixels: overdraw is measured against its area
    double viewHeight = 720;
    std::string preset = "phone";    // which VfxBudgetLimits the findings use
    std::optional<VfxBudgetCamera> camera;           // set: 3D emitters' overdraw is measured through it; empty: it is not measured
    double cameraDistance = kVfxDefaultCameraDistance;  // where the effect plays in front of `camera`
    long long maxParticleUpdates = 20'000'000;   // particle updates (live particles summed over the steps) the measuring may spend; past it the result is truncated
};

struct VfxEmitterBudget {
    int part = 0;                // index in the document's `parts`
    std::string name;
    int peakParticles = 0;       // most live particles at one step (its sub-emitters' particles included)
    double peakAt = 0.0;         // seconds into the effect
    double peakOverdraw = 0.0;   // largest quad area of this emitter at one step, in screens (0 for a 3D emitter: not measured)
    int maxParticles = 0;        // the emitter's own cap (maxParticles, at most kParticleHardCap)
    float startSize = 0.0f;      // as written, for the size findings
    bool capped = false;         // reached its cap: the effect asked for more particles than it may hold
};

struct VfxSample {
    double t = 0.0;
    int particles = 0;
    double overdraw = 0.0;
};

// One thing to change. `pointer` is a JSON pointer in the document; `fix` is a command call that does it ({command, args}), or null.
struct VfxBudgetFinding {
    std::string kind;        // "particles", "overdraw", "emitters" or "lights"
    std::string severity;    // "warning"
    std::string pointer;
    std::string message;
    std::string hint;
    Json fix;
};

struct VfxBudget {
    std::string path;
    std::string preset;
    double duration = 0.0;        // the document's own length
    double settledAt = 0.0;       // seconds until the last particle died (the effect's real length on screen)
    bool truncated = false;       // the measuring hit its time limit before the particles died (a looping emitter that never stops)
    int emitters = 0;
    int lights = 0;
    int peakParticles = 0;        // all emitters together
    double peakAt = 0.0;
    double peakOverdraw = 0.0;
    double peakOverdrawAt = 0.0;
    double meanOverdraw = 0.0;    // over the steps that have particles
    int steps = 0;
    std::vector<VfxEmitterBudget> perEmitter;
    std::vector<VfxSample> timeline;  // at most 24 samples: the largest particle count and overdraw of each slice of the effect
    std::vector<VfxBudgetFinding> findings;
    bool camera3d = false;            // 3D emitters' overdraw was measured through options.camera (false: the camera was not given, or no emitter is 3D)
    std::vector<std::string> notes;   // what the numbers leave out (a 3D emitter's overdraw without a camera) or how it was measured
};

// Plays `doc` from its start until it is over and its particles are gone (at most kVfxMaxDuration + 30 s of effect time) and returns
// the numbers and the findings against `options.preset`. Sounds and commands are not run. Never throws.
VfxBudget vfx_measure(const VfxDoc& doc, const VfxBudgetOptions& options = {});

}  // namespace fa
