// The Particle panel's preview, with no ImGui and no GPU: the effect document played by the engine's own timeline (update_vfx on a scratch
// World that holds one Vfx entity) with every emitter stepped by its own fa::ParticleSim, the code a game runs. It draws nothing; it hands the
// panel the dots and lights of the moment as plain numbers.
//
// Repeatable: a seek to an earlier moment (or after the document or the seed changed) builds the world again, the step is a fixed 1/60 s and
// the seeds come from the part number and the preview seed, so the same time shows the same particles however it was reached (playing,
// dragging the scrubber back and forth, a redo). A seek to a later moment goes on from where the preview is. A seek never blocks the UI thread:
// each call (and each catch_up) does a bounded amount of work, counted in steps and live particles, never in seconds, so the same seek takes the
// same number of calls on every machine; the preview shows the moment it has reached (time()) until it has caught up with the one asked for
// (target_time()). The document is
// played from memory (VfxHost::load), so an edit shows at once without waiting for a file's modification time. Sounds and commands of the
// document are NOT run (a preview must not shake the editor or play a clip); they are listed in `fired()` for the timeline's markers.
#pragma once

#include <cstdint>
#include <map>
#include <memory>
#include <vector>

#include "fa/core/math.h"
#include "fa/scene/particles.h"
#include "fa/scene/vfx.h"
#include "fa/scene/world.h"

namespace fa::editor {

inline constexpr double kPreviewStep = 1.0 / 60.0;  // seconds per simulation step
inline constexpr double kPreviewMaxTime = 30.0;     // the scrubber never goes past this
// Work one call of seek/catch_up may do: at most kPreviewStepBudget steps, and fewer when the particles are many (a step costs
// kPreviewStepCost + the live particles of all the emitters; the call stops once the sum reaches kPreviewWorkBudget). One step is always done.
inline constexpr int kPreviewStepBudget = 240;
inline constexpr int kPreviewStepCost = 16;
inline constexpr long kPreviewWorkBudget = 30000;

struct PreviewDot {
    float x = 0, y = 0;  // world units, +y DOWN (screen orientation); the emitter's matrix is applied
    float size = 0;      // world units
    Color color;         // alpha included
    bool additive = false;
    float rotation = 0;  // degrees
};

struct PreviewLight {
    float x = 0, y = 0;
    float radius = 0;  // world units (a 3D light: its range in metres times 32)
    Color color;
    float intensity = 1;
};

class ParticlePreview {
public:
    ParticlePreview();
    ~ParticlePreview();

    // The document to play (null: nothing). The time stays where it is and the preview is built again up to it, so an edit shows how the
    // effect looks NOW at the same moment.
    void set_document(std::shared_ptr<const VfxDoc> doc);
    void set_seed(std::uint32_t seed);
    std::uint32_t seed() const { return seed_; }

    // Asks for the moment `t` seconds (0..kPreviewMaxTime) and does the first bounded share of the work to get there. Deterministic.
    void seek(double t);
    // Does the next bounded share of a seek that has not finished. Nothing to do when caught up. After begin_frame() the first call of a frame
    // (this, a seek, or advance while a seek is on its way) does the share and the others of that frame do nothing, so a frame costs one share.
    void catch_up();
    // Marks the start of a UI frame (see catch_up). Tests and tools that never call it get a share from every call.
    void begin_frame();
    // Runs catch_up() until the asked-for moment is reached. NOT bounded: for tests and tools, never for the UI thread.
    void settle();
    // The seek has not reached target_time() yet.
    bool catching_up() const { return steps_ < targetSteps_; }
    // Steps forward by `dt` seconds of playing (a whole number of fixed steps; the remainder waits for the next call). While a seek is
    // catching up this continues the seek instead.
    void advance(double dt);
    // The moment the shown particles are at, and the moment the last seek asked for (the same when caught up).
    double time() const { return time_; }
    double target_time() const { return double(targetSteps_) * kPreviewStep; }

    // Seconds the scrubber covers: the document's duration plus the time its longest-lived particles need to die (lifetime with variance, the
    // trail and the sub-emitters, as the effect system counts it), at least 0.25 and at most kPreviewMaxTime.
    double timeline_length() const;
    // The effect has ended and every particle is gone.
    bool finished() const;

    const std::vector<PreviewDot>& dots() const { return dots_; }
    const std::vector<PreviewLight>& lights() const { return lights_; }
    int live_particles() const { return int(dots_.size()); }
    int live_emitters() const { return emitters_; }
    // Indices of the parts of kind sound or command that have started by now (the timeline marks them).
    const std::vector<int>& fired() const { return fired_; }

private:
    void rebuild();
    void run_slice();  // one bounded share of the steps a seek still owes
    long step_once();  // returns the work it cost (see kPreviewStepCost)
    void snapshot();

    std::shared_ptr<const VfxDoc> doc_;
    std::unique_ptr<World> world_;
    Entity vfx_ = kNullEntity;
    std::map<std::uint64_t, ParticleSim> sims_;  // by entity bits
    std::uint32_t seed_ = 1;
    double time_ = 0.0;
    double carry_ = 0.0;
    int steps_ = 0;
    int targetSteps_ = 0;  // the step the last seek asked for
    bool stale_ = true;    // the world does not belong to the current document and seed: the next seek builds it again
    int emitters_ = 0;
    std::vector<PreviewDot> dots_;
    std::vector<PreviewLight> lights_;
    std::vector<int> fired_;
    bool framed_ = false;  // begin_frame() was called at least once: the work of one frame is one share
    bool slicedThisFrame_ = false;
    mutable double length_ = 1.0;  // timeline_length(), worked out once per document
    mutable bool lengthValid_ = false;
};

}  // namespace fa::editor
