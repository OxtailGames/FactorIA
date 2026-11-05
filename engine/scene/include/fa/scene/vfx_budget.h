// What an effect document costs on a phone, worked out without a renderer (docs/PARTICLES.md, "Reviewing an effect"): vfx_measure plays
// the document in a scratch World, step by step, with the same update_vfx and ParticleSim a game runs, and counts the live particles
// and the screen they cover at every step. The numbers depend only on the document, the seed and the view size: the same call gives
// the same result on every machine.
//
// It measures the particles the sim keeps alive. The renderer may drop some further (a camera that does not see them) or draw more
// (ribbon trails, a glow pass), so read the numbers as the cost of the effect on the screen it is played in, not as a frame time.
#pragma once

#include <cstdint>
#include <string>
#include <vector>

#include "fa/core/json.h"
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

struct VfxBudgetOptions {
    std::uint32_t seed = 1;          // the sim's seed (an emitter's own seed is mixed from it and its part)
    double viewWidth = 1280;         // the view in design pixels: overdraw is measured against its area
    double viewHeight = 720;
    std::string preset = "phone";    // which VfxBudgetLimits the findings use
};

struct VfxEmitterBudget {
    int part = 0;                // index in the document's `parts`
    std::string name;
    int peakParticles = 0;       // most live particles at one step (its sub-emitters' particles included)
    double peakAt = 0.0;         // seconds into the effect
    double peakOverdraw = 0.0;   // largest quad area of this emitter at one step, in screens
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
};

// Plays `doc` from its start until it is over and its particles are gone (at most kVfxMaxDuration + 30 s of effect time) and returns
// the numbers and the findings against `options.preset`. Sounds and commands are not run. Never throws.
VfxBudget vfx_measure(const VfxDoc& doc, const VfxBudgetOptions& options = {});

}  // namespace fa
