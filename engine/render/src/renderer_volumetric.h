// Volumetric fog and light shafts (SceneSettings.volumetricFog, Light.volumetric; M73.5): a medium between the camera and the surfaces, lit by the
// ambient light, the directional lights and the point and spot lights that ask for it, with the shadows of the shadow atlas cutting shafts into it.
// docs/design/ARCHITECTURE_VOLUMETRIC.md; docs/rendering/RENDERING_LIGHTING.md, "Volumetric fog and light shafts".
//
//   vol-march   (the camera's own job, after its shadow and prepass passes)  prepass + shadow atlas + light data texture -> RGBA16F image at 1/2 or
//               1/4 of the camera's rectangle: rgb = the light the medium scatters toward the camera, a = the transmittance. A raymarch with a
//               bounded cost: `steps` samples for the ambient light and the directional lights, `samples` per point or spot light inside its
//               range, at most 4 + 16 lights (shaders/volumetric.glsl).
//   vol-apply   (the post section, before the reflections and the sun shafts)  the image + the prepass -> the camera's rectangle of the picture, blended as
//               picture * a + rgb after a depth-aware upsample. No copy of the picture: a blend, as the fog and the shafts.
//
// No mesh shader changes: the mesh fragment units are full (16 images) and the result is a blend over the finished picture. A camera that draws the
// volumetric fog does not also draw the analytic fog (SceneSettings.fogDensity, PostProcess fog): the two would fog twice.
//
// The plan (make_vol_plan) is pure CPU, so the quality table, the choice of lights and the maths the shader mirrors are tested without a GPU. There
// is no temporal reprojection: the jitter is a function of the pixel alone, so a still picture is the same on every frame and every run, and
// nothing ghosts. VolumetricFx owns the shaders and pipelines (made on first use, destroyed by release()), so a scene that never turns the fog on
// compiles nothing.
#pragma once

#include <cstdint>
#include <string>
#include <vector>

#include "fa/core/math.h"
#include "fa/scene/camera_geometry.h"
#include "fa/scene/components.h"

#include "bloom.h"
#include "frame_graph.h"
#include "render_internal.h"
#include "transient_targets.h"

struct mesh_fa_shadows_t;  // the shadow block of the mesh shaders (shaders/mesh.glsl.h)

namespace fa::render {

struct LightData;
struct PostRect;
struct PrepassRef;

// The shader's loop bounds (volumetric.glsl): the arrays of the light block and the loops are this big, whatever the quality asks.
inline constexpr int kVolMaxDirectional = 4;
inline constexpr int kVolMaxLocal = 16;
inline constexpr int kVolMaxSteps = 64;
inline constexpr int kVolMaxSamples = 24;

// What a quality setting costs: the march image is `divisor` times smaller than the camera's rectangle on each side, a ray takes `steps` samples
// for the ambient light and the directional lights, at most `maxLights` point and spot lights shine in it and each takes `samples` along its
// part of the ray. The number of lights in the scene never changes it.
struct VolQuality {
    int divisor = 2;
    int steps = 32;
    int maxLights = 8;
    int samples = 10;
};
VolQuality vol_quality(VolumetricQuality q);

// The size of the march image for a camera's rectangle: the rectangle divided by `divisor`, rounded up (at least 1 x 1).
void vol_grid_size(int rectW, int rectH, int divisor, int* w, int* h);

// The Henyey-Greenstein phase function times 4 pi (1 for g = 0, the same in every direction), as the shader's vol_phase: `cosTheta` is the cosine of
// the angle between the direction to the light and the direction the camera looks along the ray; g (-0.99 .. 0.99) > 0 scatters forward.
float vol_phase(float g, float cosTheta);

// The jitter of the pixel (x, y) of the march image: interleaved gradient noise in [0, 1), the shader's `ign(floor(s * size))`. Deterministic: it
// depends on the pixel only, never on the frame, a random number or the clock.
float vol_jitter(int x, int y);

// The density at height y and the optical depth along a ray: sigma(y) = density * exp(-falloff * max(y - base, 0)); falloff 0 = the same
// density at every height. `vol_optical_depth` is the integral of the density from the camera at height y0 to the point t metres along a ray
// that rises ry per metre (the closed form the shader uses); the transmittance is exp(-optical depth).
float vol_density(float density, float base, float falloff, float y);
float vol_optical_depth(float density, float base, float falloff, float y0, float ry, float t);

// The lights that shine in the fog: the table indices of the directional lights (at most kVolMaxDirectional) and of the point and spot lights
// (at most `maxLocal`, the most important first by score * Light.volumetric, ties by index, then listed in table order), and how many asked and
// were left out. Lights that are off (volumetric 0, no colour, a local light with no range) never count.
struct VolLightPick {
    std::vector<int> directional;
    std::vector<int> local;
    int dropped = 0;
};
VolLightPick pick_volumetric_lights(const std::vector<LightData>& lights, int maxLocal);

// What a camera's passes draw: the settings after clamping and the lights, laid out as the shader's uniform blocks read them.
struct VolPlan {
    bool on = false;
    VolQuality quality;
    int rectW = 0, rectH = 0;   // the camera's rectangle in pixels
    int width = 0, height = 0;  // the march image
    float distance = 100.0f, density = 0.0f, heightBase = 0.0f, heightFalloff = 0.0f, anisotropy = 0.0f;
    float albedo[3]{0.5f, 0.6f, 0.7f};   // the colour of the medium, in the scene's colour space
    float ambient[3]{0.0f, 0.0f, 0.0f};  // ambientLight * volumetricAmbient, in the scene's colour space
    int directionalCount = 0, localCount = 0;
    float directional[kVolMaxDirectional * 2]
                     [4]{};  // per light: direction to it + 1 when the sun's shadow applies; colour * strength
    float local
        [kVolMaxLocal * 4]
        [4]{};  // per light: position + range; colour * strength + cos(inner); axis + cos(outer) (-2: a point); table index and 1 when its shadow tiles are read
    int lightsUsed = 0, lightsDropped = 0;
    float proj[8]{};  // P00, P11, P02, P12, P03, P13, P32, P33
    Vec3 eye{0, 0, 0}, right{1, 0, 0}, up{0, 1, 0}, forward{0, 0, -1};
};

// The plan of one camera. `lights` are the camera's lights as collect_lights left them (the table the shader's indices name); `shadowsDrawn`: the
// job draws its shadow atlas this frame (the sun's shadow applies to the light of slot 0 when it is the caster, `sunCasts`; a local light's when
// it casts); `linear`: the scene computes in linear light. Off (plan.on false) for an orthographic camera, an empty rectangle, a density of 0 or
// less, or settings that are not finite.
VolPlan make_vol_plan(const SceneSettings& ss, const CameraGeometry& cam, const std::vector<LightData>& lights,
                      bool linear, int rectW, int rectH, bool shadowsDrawn, bool sunCasts);

class VolumetricFx {
public:
    VolumetricFx() = default;
    VolumetricFx(const VolumetricFx&) = delete;
    VolumetricFx& operator=(const VolumetricFx&) = delete;

    enum class Prog { March, Apply, Count };

    // Does this GPU render RGBA16F targets that blend and filter (the march image holds light above 1)? The same rule as render.supports.
    static bool gpu_supported(gpu::Device& device);
    // Can the camera's passes be drawn: the GPU supports it, both programs build and the march image of `plan` can be made (probed once per
    // size and given back to the pool). False (logged once) draws no fog: the camera keeps its analytic one.
    bool can_draw(TransientTargets& targets, Gpu& gpu, const VolPlan& plan);
    // The description of the march image of `plan` (a transient of the graph), labelled `job`/vol-image.
    static TransientDesc image_desc(const VolPlan& plan, const std::string& job);

    // The march: draws the whole of `dst` (the march image). `prepass`: the camera's prepass; `shadowTex`, `lightTex`: the shadow atlas and the light
    // data texture (any image where there is no shadow: they are not read); `shadows`: the block of the mesh shaders, of which only the filter mode
    // is changed (one tap).
    void march(Gpu& gpu, const VolPlan& plan, const Target& dst, gpu::bridged::View prepass,
               gpu::bridged::View shadowTex, gpu::bridged::View lightTex, const mesh_fa_shadows_t& shadows,
               int* drawCalls);

    // Declares the pass that blends the march image `vol` over the camera's rectangle `rect` of the picture (`game`, drawn into `dst`). Returns 1
    // when the pass was declared (0: nothing to draw).
    int add_apply(FrameGraph& graph, TransientTargets& targets, Gpu& gpu, const VolPlan& plan, ResourceId vol,
                  const PostRect& rect, int picW, int picH, ResourceId game, const BloomTarget& dst,
                  const PrepassRef& prepass, int* drawCalls, const std::string& job);

    // Destroys the shaders and the pipelines; call while the graphics context is open.
    void release();
    // Forgets that creating the march image failed (the game target was resized or recreated).
    void forget_targets();

    bool ready(Gpu& gpu, Prog prog);
    gpu::Pipeline pipeline(gpu::Device& device, Prog prog, const TargetFormat& format);

private:
    struct PipelineEntry {
        Prog prog;
        TargetFormat format;
        gpu::Pipeline pipeline;
    };
    bool can_draw(TransientTargets& targets, gpu::Device& device, const VolPlan& plan);
    bool ready(gpu::Device& device, Prog prog);
    gpu::Device* device_ = nullptr;  // what ready() made the shaders on: release() has no Gpu at hand
    gpu::Shader shaders_[int(Prog::Count)]{};
    int state_[int(Prog::Count)]{};  // 0 = not made yet, 1 = ready, -1 = failed (logged)
    std::vector<PipelineEntry> pipelines_;
    bool warnedTargets_ = false;
    bool warnedGpu_ = false;
    std::vector<std::uint64_t> failed_;  // sizes whose march image could not be made
    std::vector<std::uint64_t> probed_;  // sizes whose image was made once: the pool is not probed again every frame
};

}  // namespace fa::render
