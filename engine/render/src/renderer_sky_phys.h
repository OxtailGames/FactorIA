// The GPU half of the physical sky (SceneSettings.skyModel = physical, M73-P3d; the CPU half and the maths are in
// physical_sky.h, the shaders in shaders/sky_physical.glsl).
//
// Four small RGBA16F images are drawn with the sky's own shaders:
//
//   transmittance   128 x 64    the optical depth of the air towards the sun's way out of the atmosphere (the air's colour)
//   multiscatter    32 x 32     the light that scattered more than once, per unit of scattering
//   skyview[0]      128 x 128   the sky as the main camera sees it, drawn for the sun of the frame
//   skyview[1]      128 x 128   the same for the sun and the clock of the baked environment (quantised, physical_sky.h): the
//                               environment must not depend on the frame rate, so it never reads the first table
//
// The first two depend on the air and the ground only (SceneSettings.skyTurbidity, skyGroundAlbedo): they are drawn the
// first time and again when one of those changes. A skyview is drawn when the sun it was drawn for has changed (the
// background follows the sun smoothly; the environment's one only moves when a new bake starts). A table is 8 to 130 KB, one
// pass each: the cost of a whole build is in the test "the physical sky: what the tables and a bake cost".
//
// The class owns its shaders, images, pipelines and sampler (made on first use, destroyed by release()); it draws nothing by
// itself: the renderer calls update() in a frame graph pass before the passes that read the tables, and draw() inside the pass
// that shows the sky.
#pragma once

#include <cstdint>

#include "physical_sky.h"
#include "render_internal.h"

namespace fa::render {

class PhysicalSky {
public:
    PhysicalSky() = default;
    PhysicalSky(const PhysicalSky&) = delete;
    PhysicalSky& operator=(const PhysicalSky&) = delete;

    // Makes the shaders, images and pipelines on first use. False (logged once) when this GPU cannot render to RGBA16F and
    // filter it: the sky is then the gradient.
    bool ready(Gpu& gpu);
    bool failed() const { return state_ < 0; }

    // Draws the tables the state needs and `slot` (0 the picture, 1 the environment) is missing: the air tables when the air
    // changed, the sky view of the slot when its sun changed. Adds the passes it ran to *drawCalls. Call outside a pass.
    void update(Gpu& gpu, int slot, const PhysicalSkyState& st, int* drawCalls);

    // Draws the sky of `slot` as a full-screen triangle into the open pass (the picture of the main camera, or a face of the
    // environment: `format` is then the format of the pass's colour image, `invViewProj` the face's matrix and `camPos` 0).
    void draw(Gpu& gpu, int slot, const PhysicalSkyState& st, bool sunDisc, const float* invViewProj,
              const float camPos[3], const TargetFormat* format);

    // The image the picture's sky view is drawn into: what the frame graph's resource for it imports.
    std::uint64_t image_id() const { return view_[0].id; }
    sg_pixel_format format() const { return gpu::to_sg(format_); }

    // How many times each table was drawn (tests).
    int air_builds() const { return airBuilds_; }
    int view_builds(int slot) const { return viewBuilds_[slot & 1]; }

    void release();

private:
    enum Prog { Transmittance, MultiScatter, SkyView, Sky, ProgCount };
    void pass(Gpu& gpu, Prog prog, gpu::View target, const char* label, const PhysicalSkyState& st, int* drawCalls);
    void update_air(Gpu& gpu, const PhysicalSkyState& st, int* drawCalls);

    int state_ = 0;  // 0 = not made, 1 = ready, -1 = failed (logged)
    gpu::PixelFormat format_ = gpu::PixelFormat::None;
    gpu::Device* device_ = nullptr;  // what ready() made the resources on: release() has no Gpu at hand
    gpu::Shader shaders_[ProgCount]{};
    gpu::Pipeline lutPipelines_
        [ProgCount]{};  // the three that draw a table (the sky's own pipelines come from Gpu::sky_pipeline)
    gpu::Sampler sampler_{};
    gpu::Image trImage_{}, msImage_{}, view_[2]{};
    gpu::View trTex_{}, msTex_{}, viewTex_[2]{};
    gpu::View trAtt_{}, msAtt_{}, viewAtt_[2]{};
    std::uint64_t airKey_ = 0;
    bool airDrawn_ = false;
    std::uint64_t viewKey_[2]{};
    bool viewDrawn_[2]{};
    int airBuilds_ = 0;
    int viewBuilds_[2]{};
};

}  // namespace fa::render
