// The Particle panel's preview, with no ImGui and no GPU: the effect document played by the engine's own timeline (update_vfx on a scratch
// World that holds one Vfx entity) with every emitter stepped by its own fa::ParticleSim, the code a game runs. It draws nothing; it hands the
// panel the dots and lights of the moment as plain numbers.
//
// Repeatable: the world is built again for every seek, the step is a fixed 1/60 s and the seeds come from the part number and the preview seed,
// so the same time shows the same particles however it was reached (playing, dragging the scrubber back and forth, a redo). The document is
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

inline constexpr double kPreviewStep = 1.0 / 60.0;   // seconds per simulation step
inline constexpr double kPreviewMaxTime = 30.0;      // the scrubber never goes past this

struct PreviewDot {
    float x = 0, y = 0;      // world units, +y DOWN (screen orientation); the emitter's matrix is applied
    float size = 0;          // world units
    Color color;             // alpha included
    bool additive = false;
    float rotation = 0;      // degrees
};

struct PreviewLight {
    float x = 0, y = 0;
    float radius = 0;        // world units (a 3D light: its range in metres times 32)
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

    // Builds the world again and steps to `t` seconds (0..timeline_length()). Deterministic.
    void seek(double t);
    // Steps forward by `dt` seconds of playing (a whole number of fixed steps; the remainder waits for the next call).
    void advance(double dt);
    double time() const { return time_; }

    // Seconds the scrubber covers: the document's duration plus the time its longest-lived particles need to die, at least 0.25 and at most
    // kPreviewMaxTime.
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
    void step_once();
    void snapshot();

    std::shared_ptr<const VfxDoc> doc_;
    std::unique_ptr<World> world_;
    Entity vfx_ = kNullEntity;
    std::map<std::uint64_t, ParticleSim> sims_;   // by entity bits
    std::uint32_t seed_ = 1;
    double time_ = 0.0;
    double carry_ = 0.0;
    int steps_ = 0;
    int emitters_ = 0;
    std::vector<PreviewDot> dots_;
    std::vector<PreviewLight> lights_;
    std::vector<int> fired_;
};

}  // namespace fa::editor
