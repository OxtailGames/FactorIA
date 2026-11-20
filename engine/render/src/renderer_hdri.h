// The GPU half of the HDRI environment (SceneSettings.environmentMap, M73-P3a-2; the file side is include/fa/render/hdri.h, the shader
// shaders/hdri.glsl): one full-screen program that draws an equirectangular picture, as the background of the main pass (the engine's
// sky camera) and into the six faces of the cube the environment bake starts from (renderer_env.h). The prefilter and the irradiance of
// the bake are the ones every sky already uses, so there is exactly one bake and one set of cubes whatever the environment comes from.
//
// Who decides what is seen and what lights (the one place this is written down; docs/rendering/RENDERING_LIGHTING.md repeats it):
//   background   SceneSettings.skyMaterial, else the HDRI when environmentBackground is on, else the physical sky or the gradient
//   lighting     the HDRI when environmentMap is set (whatever the background is), else the sky material or the physical sky,
//                else the gradient colours
// The brightness environmentIntensity multiplies the background and the lighting of whichever sky gives them.
//
// Looking after the highlights: the picture holds at most kHdriMaxValue per channel (hdri.h). The mirror level of the prefiltered cube
// and the background show it as it is (after the gain environmentIntensity the brightest channel is limited to 65000, the colour kept, in
// env.glsl and hdri.glsl, so a half float never overflows to infinity); the rougher levels and the irradiance limit one sample to kHdriTapLimit (the brightest channel,
// the colour kept) so a sun a thousand times brighter than the sky does not leave a speckle of fireflies in 32 samples a pixel. The
// number of samples is the sky's own (32 / 64 and 128), so the cost of a bake does not depend on the picture.
#pragma once

#include "render_internal.h"

namespace fa::render {

inline constexpr float kHdriTapLimit = 64.0f;

class HdriSky {
public:
    // Makes the program on first use; false (logged once) when this GPU cannot: the HDRI is then not used.
    bool ready(Gpu& gpu);
    // Draws `hdri` as a full-screen triangle into the open pass. `rotationDegrees`: SceneSettings.environmentRotation. `gain`: the
    // brightness. `gamma`: encode as sRGB (a gamma scene). `invViewProj` (column-major) and `camPos` place the rays; `format`: the
    // pass's colour image when it is not the scene's (the bake's cube faces).
    void draw(Gpu& gpu, const HdriAsset& hdri, float rotationDegrees, float gain, bool gamma, const float* invViewProj,
              const float camPos[3], const TargetFormat* format);
    void release();

private:
    int state_ = 0;  // 0 = not made, 1 = ready, -1 = failed (logged)
    sg_shader shader_{};
    sg_sampler sampler_{};
};

}  // namespace fa::render
