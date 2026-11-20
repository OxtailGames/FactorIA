// The sky environment (SceneSettings.skyMaterial, M72 P15; SceneSettings.skyModel physical, M73-P3d): the sky a sky material
// or the physical sky draws is also what lights the meshes. The physical sky's sun moves all the time, so it also bakes in
// slices (bake_slice, below; the rule that picks whole or sliced is in plan_env, renderer_draw.cpp). It is baked into ONE cube
// image the mesh programs sample (mesh_common.glsl: fa_environment(), fa_ambient_light()), which holds both:
//
//   prefiltered   mips 0..kEnvLevels-1 of kEnvSize x kEnvSize faces; mip k holds the sky convolved with the GGX lobe of roughness
//                 k / (kEnvLevels - 1), so a surface of roughness r reads it at lod r * (kEnvLevels - 1) (the reflection, image
//                 based lighting)
//   sh            mip kEnvShMip (4 x 4 texels per face, which no reflection reads): the sky's nine spherical-harmonics
//                 coefficients (L2, RGB; ShL2 of fa/scene/lightmap_bake.h), one per texel of the face +X, the rest zero. The diffuse
//                 ambient light (what a surface facing n receives from the sky, divided by pi: a sky of one colour gives that
//                 colour; SceneSettings.ambientLight is not added to it) is their convolution with the clamped cosine, evaluated
//                 by fa_sh_eval in the mesh shader.
//
// Why the SH is a mip of the cube: it must exist for every sky, including a sky material that only exists as a GPU program, and
// sokol has no GPU readback, so the coefficients are computed by a GPU pass (env.glsl, fs_sh) and stay on the GPU. The mesh
// fragment shader has no free texture unit (docs/design/ARCHITECTURE_RENDERING_LIGHTING.md, "The texture slots of the mesh
// fragment shader"), and the cube is bound already: its mip 5 is free storage, read with textureLod at the exact
// centre of a texel (a fetch with no filtering error). The old irradiance cube (8x8 faces convolved by importance
// sampling, a texture unit of its own) is retired.
//
// One bake = 60 small passes (measured on Metal, Apple M-series: the frame takes about 3.4 ms longer on the frame that
// bakes, 0.6 ms of it CPU time recording the passes; the test "what one bake of the environment costs" reports the
// numbers, and docs/shaders/SHADERS_LIGHTING.md says what they mean):
//   sky       the sky material's own program draws each of the 6 faces of the pyramid's first image S0 (kEnvSize)
//   pyramid   S1..S3 (kEnvSize/2, /4, /8) by bilinear down-sampling: 18 passes. They are separate 1-mip images, never
//   mips of the cube
//             that is being drawn: a pass that draws into a mip while sampling another mip of the same texture is a
//             feedback loop that OpenGL ES 3 and WebGL 2 leave undefined (they cannot restrict a texture view to a mip
//             range), so nothing is ever read from an image that is attached
//   prefilter mip 0 copies S0; mips 1..4 convolve the pyramid image of about their own size with the GGX lobe: 30
//   passes sh S3 projected onto the nine SH coefficients: 6 passes (mip kEnvShMip of the prefiltered cube, one pass per face)
// The cubes are RGBA16F when the GPU can render to it and filter it (every desktop GPU, GLES 3 with
// EXT_color_buffer_half_float, which WebGL 2 exposes as EXT_color_buffer_float or _half_float), else RGBA8 (the sky is
// clamped to 0..1 and the dark end bands: documented). The orientation of a face is a table (renderer_env.cpp): the
// cube map specification's, the same on every backend; OpenGL stores a render target bottom-up, so its `up` axis is
// negated (the shaders' `env_vs_params`).
//
// The environment owns its shaders, images and pipelines (made on first use, destroyed by release()). It draws nothing
// by itself: the renderer decides when (a key that changes with everything the sky depends on) and hands over a
// function that draws the sky into a face.
#pragma once

#include <cstdint>
#include <functional>

#include "render_internal.h"

namespace fa::render {

inline constexpr int kEnvSize = 128;  // the faces of the prefiltered cube (mip 0)
inline constexpr int kEnvLevels = 5;  // its mips: 128, 64, 32, 16, 8
inline constexpr int kEnvShMip =
    kEnvLevels;  // the mip of the cube that holds the sky's spherical harmonics (4 x 4 texels per face)
inline constexpr int kEnvShCoefficients = 9;  // L2: bands 0..2, one texel each (x + 4 * y of the face +X)
inline constexpr int kEnvPyramid = 4;         // images S0..S3 (128, 64, 32, 16)
inline constexpr double kEnvTimeStep = 0.1;   // seconds of game time between two bakes of an animated sky
inline constexpr int kEnvPasses = 6 * (1 + (kEnvPyramid - 1) + 1 + (kEnvLevels - 1) + 1);  // 60
inline constexpr int kEnvSlices = 3;  // bake_slice: calls per bake (24 + 18 + 18 passes)

// The direction a pixel looks at is fwd + x * right + y * up (x, y: the clip position). `up` is already negated for
// OpenGL.
struct EnvFace {
    float fwd[3], right[3], up[3];
};
// The basis of cube face `face` (0..5: +X -X +Y -Y +Z -Z) as the cube map specification lays the faces out; `gl`: the
// backend stores render targets bottom-up (its `up` is negated, so that row 0 of the image is the top of the face on
// every backend).
EnvFace env_face(int face, bool gl);

// A column-major mat4 (as the sky program's `inv_view_proj` uniform reads it) that maps the clip position (x, y, 1, 1)
// of the sky's full-screen triangle to the direction of the pixel (w = 1): the sky program draws a face of the cube
// with it and a camera at the origin.
void env_face_matrix(const EnvFace& face, float out[16]);

class Environment {
public:
    Environment() = default;
    Environment(const Environment&) = delete;
    Environment& operator=(const Environment&) = delete;

    // Draws the sky into the face the open pass shows: `invViewProj` (see env_face_matrix) and the format of the pass's
    // colour image.
    using SkyDraw = std::function<void(const float* invViewProj, const TargetFormat& format)>;

    // Makes the shaders, pipelines and images on first use. False (logged once) when this GPU cannot: the meshes then
    // keep the gradient.
    bool ready(Gpu& gpu);
    // True when the cubes hold a baked sky, and the key it was baked with.
    bool baked() const { return baked_; }
    std::uint64_t key() const { return key_; }
    // How the next bake (a whole one, or a sequence of slices from its first call) treats the sky it is given: `gain` multiplies
    // what the meshes read (SceneSettings.environmentIntensity; the sky itself is drawn once, so a change of it is a new key and a
    // new bake), `tapLimit` (0 = none) limits the brightest channel of one sample of the roughness convolutions and of the SH projection
    // (an HDRI's sun, renderer_hdri.h; the mirror level and the sky material's bake have no limit). Defaults: 1 and 0.
    void set_look(float gain, float tapLimit) {
        look_.gain = gain;
        look_.tapLimit = tapLimit;
    }
    // Bakes the sky: runs kEnvPasses passes (adds them to *drawCalls). `key` is remembered as what the cubes now show.
    // A pass that cannot be made leaves baked() false.
    void bake(Gpu& gpu, std::uint64_t key, const SkyDraw& sky, int* drawCalls);

    // The same bake in kEnvSlices calls, one per frame (the physical sky, whose sun moves all the time: a whole bake is ~3.4 ms
    // on a frame, a slice a third of that). The first call of a sequence (busy() false) draws the sky with `sky` and remembers
    // `key`; the next two ignore both and finish the images from what the first made, so a sequence is the bake of ONE
    // moment of the sky (it never mixes two). baked() and the old images stay valid meanwhile: the meshes see the old cubes
    // until a slice replaces a part of them (the levels 0..2 on the second call, the rest and the SH on the third),
    // which is at most a quarter of a degree of sun at a time (the caller starts a whole bake when more has changed). Only
    // for an environment that baked once; the third call sets baked() and key().
    void bake_slice(Gpu& gpu, std::uint64_t key, const SkyDraw& sky, int* drawCalls);
    bool busy() const { return slice_ != 0; }
    // A number the caller keeps with the bake that is running or done (the physical sky stores the hash of what a slice
    // sequence must not span, and the sun's direction).
    void set_tag(std::uint64_t key, const float sun[3]) {
        tagKey_ = key;
        for (int i = 0; i < 3; ++i) tagSun_[i] = sun[i];
    }
    std::uint64_t tag_key() const { return tagKey_; }
    const float* tag_sun() const { return tagSun_; }

    // The view the mesh programs sample (mips 0..kEnvLevels-1 the reflection, mip kEnvShMip the SH) and its sampler; blank_view() is
    // a 1x1 black cube, bound while no environment is used (a program that declares the slot needs a valid view).
    sg_view prefiltered_view() const { return preTex_; }
    // The image id of the prefiltered cube: what the frame graph's resource for the environment imports
    // (frame_graph.h).
    std::uint64_t image_id() const { return pre_.id; }
    sg_view blank_view(Gpu& gpu);
    // (blank_view() makes the sampler too: ask for the view first.)
    sg_sampler sampler() const { return sampler_; }
    // The pixel format of the cubes (RGBA16F or RGBA8).
    // With RGBA8 the SH texels hold clamp(c / 4, -1, 1) * 0.5 + 0.5 (fa_env_sky.w = 2).
    sg_pixel_format format() const { return format_; }
    // Tests only: the next ready() makes the cubes RGBA8 as a GPU that cannot render to half floats gets them (call before ready()).
    static void force_rgba8_for_tests(bool force);

    // Destroys everything; call while the graphics context is open.
    void release();

    enum class Prog { Copy, Prefilter, Sh, Count };

private:
    sg_pipeline pipeline(Prog prog);
    void draw(Gpu& gpu, Prog prog, sg_view dst, sg_view srcTex, int face, float roughness, float samples,
              const char* label, int* drawCalls, bool lit = false);
    void destroy_images();
    void bake_sky(Gpu& gpu, const SkyDraw& sky, int* drawCalls);
    void bake_levels(Gpu& gpu, int first, int last, int* drawCalls);
    void bake_sh(Gpu& gpu, int* drawCalls);

    int state_ = 0;  // 0 = not made, 1 = ready, -1 = failed (logged)
    sg_pixel_format format_ = SG_PIXELFORMAT_NONE;
    sg_shader shaders_[int(Prog::Count)]{};
    sg_pipeline pipelines_[int(Prog::Count)]{};
    sg_sampler sampler_{};
    // S0..S3: 1 mip each; their texture views and, per face, attachment views.
    sg_image pyramid_[kEnvPyramid]{};
    sg_view pyramidTex_[kEnvPyramid]{};
    sg_view pyramidAtt_[kEnvPyramid][6]{};
    // The prefiltered cube: kEnvLevels mips and the SH mip; attachment views per level and face.
    sg_image pre_{};
    sg_view preTex_{};
    sg_view preAtt_[kEnvLevels][6]{};
    sg_view shAtt_[6]{};  // the faces of mip kEnvShMip
    sg_image blank_{};
    sg_view blankTex_{};
    bool baked_ = false;
    std::uint64_t key_ = 0;
    struct Look {
        float gain = 1.0f, tapLimit = 0.0f;
    };
    Look look_, active_;  // what the caller asked for, and what the bake that runs uses (taken when it starts)
    int slice_ = 0;       // bake_slice: the next call's part (0 = a new sequence, 1, 2)
    std::uint64_t pendingKey_ = 0, tagKey_ = 0;
    float tagSun_[3]{0.0f, 1.0f, 0.0f};
};

}  // namespace fa::render
