// The sky environment (SceneSettings.skyMaterial, M72 P15): the sky a sky material draws is also what lights the meshes. It is baked into two
// cube images the mesh programs sample (mesh_common.glsl: fa_environment(), fa_ambient_light()):
//
//   prefiltered   a cube of kEnvSize x kEnvSize faces with kEnvLevels mips; mip k holds the sky convolved with the GGX lobe of roughness
//                 k / (kEnvLevels - 1), so a surface of roughness r reads it at lod r * (kEnvLevels - 1) (the reflection, image based lighting)
//   irradiance    a cube of kEnvIrrSize x kEnvIrrSize faces: what a diffuse surface facing each direction receives from the sky, divided by
//                 pi (the ambient light: a sky of one colour gives that colour). SceneSettings.ambientLight is not added to it
//
// Why not spherical harmonics or the lowest mip: the lowest mip is the GGX lobe of roughness 1 (not the cosine lobe a diffuse surface
// integrates), and nine SH coefficients need the sky read back to the CPU (a stall, and no GPU-only path on the web); a 8x8 cube convolved
// on the GPU is exact for the cosine lobe at 384 texels and is sampled with one fetch.
//
// One bake = 60 small passes (measured on Metal, Apple M-series: the frame takes about 3.4 ms longer on the frame that bakes, 0.6 ms of
// it CPU time recording the passes; the test "what one bake of the environment costs" reports the numbers, and
// docs/shaders/SHADERS_LIGHTING.md says what they mean):
//   sky       the sky material's own program draws each of the 6 faces of the pyramid's first image S0 (kEnvSize)
//   pyramid   S1..S3 (kEnvSize/2, /4, /8) by bilinear down-sampling: 18 passes. They are separate 1-mip images, never mips of the cube
//             that is being drawn: a pass that draws into a mip while sampling another mip of the same texture is a feedback loop that
//             OpenGL ES 3 and WebGL 2 leave undefined (they cannot restrict a texture view to a mip range), so nothing is ever read from
//             an image that is attached
//   prefilter mip 0 copies S0; mips 1..4 convolve the pyramid image of about their own size with the GGX lobe: 30 passes
//   irradiance S3 convolved with the cosine lobe: 6 passes
// The cubes are RGBA16F when the GPU can render to it and filter it (every desktop GPU, GLES 3 with EXT_color_buffer_half_float, which
// WebGL 2 exposes as EXT_color_buffer_float or _half_float), else RGBA8 (the sky is clamped to 0..1 and the dark end bands: documented).
// The orientation of a face is a table (renderer_env.cpp): the cube map specification's, the same on every backend; OpenGL stores a
// render target bottom-up, so its `up` axis is negated (the shaders' `env_vs_params`).
//
// The environment owns its shaders, images and pipelines (made on first use, destroyed by release()). It draws nothing by itself: the
// renderer decides when (a key that changes with everything the sky depends on) and hands over a function that draws the sky into a face.
#pragma once

#include <cstdint>
#include <functional>

#include "render_internal.h"

namespace fa::render {

inline constexpr int kEnvSize = 128;     // the faces of the prefiltered cube (mip 0)
inline constexpr int kEnvLevels = 5;     // its mips: 128, 64, 32, 16, 8
inline constexpr int kEnvIrrSize = 8;    // the faces of the irradiance cube
inline constexpr int kEnvPyramid = 4;    // images S0..S3 (128, 64, 32, 16)
inline constexpr double kEnvTimeStep = 0.1;  // seconds of game time between two bakes of an animated sky
inline constexpr int kEnvPasses =6 * (1 + (kEnvPyramid - 1) + 1 + (kEnvLevels - 1) + 1);  // 60

// The direction a pixel looks at is fwd + x * right + y * up (x, y: the clip position). `up` is already negated for OpenGL.
struct EnvFace {
    float fwd[3], right[3], up[3];
};
// The basis of cube face `face` (0..5: +X -X +Y -Y +Z -Z) as the cube map specification lays the faces out; `gl`: the backend stores
// render targets bottom-up (its `up` is negated, so that row 0 of the image is the top of the face on every backend).
EnvFace env_face(int face, bool gl);

// A column-major mat4 (as the sky program's `inv_view_proj` uniform reads it) that maps the clip position (x, y, 1, 1) of the sky's
// full-screen triangle to the direction of the pixel (w = 1): the sky program draws a face of the cube with it and a camera at the origin.
void env_face_matrix(const EnvFace& face, float out[16]);

class Environment {
public:
    Environment() = default;
    Environment(const Environment&) = delete;
    Environment& operator=(const Environment&) = delete;

    // Draws the sky into the face the open pass shows: `invViewProj` (see env_face_matrix) and the format of the pass's colour image.
    using SkyDraw = std::function<void(const float* invViewProj, const TargetFormat& format)>;

    // Makes the shaders, pipelines and images on first use. False (logged once) when this GPU cannot: the meshes then keep the gradient.
    bool ready(Gpu& gpu);
    // True when the cubes hold a baked sky, and the key it was baked with.
    bool baked() const { return baked_; }
    std::uint64_t key() const { return key_; }
    // Bakes the sky: runs kEnvPasses passes (adds them to *drawCalls). `key` is remembered as what the cubes now show. A pass that cannot be
    // made leaves baked() false.
    void bake(Gpu& gpu, std::uint64_t key, const SkyDraw& sky, int* drawCalls);

    // The views the mesh programs sample and their sampler; blank_view() is a 1x1 black cube, bound while no environment is used (a program
    // that declares the slot needs a valid view).
    sg_view prefiltered_view() const { return preTex_; }
    // The image id of the prefiltered cube: what the frame graph's resource for the environment imports (frame_graph.h).
    std::uint64_t image_id() const { return pre_.id; }
    sg_view irradiance_view() const { return irrTex_; }
    sg_view blank_view(Gpu& gpu);
    // (blank_view() makes the sampler too: ask for the view first.)
    sg_sampler sampler() const { return sampler_; }
    // The pixel format of the cubes (RGBA16F or RGBA8).
    sg_pixel_format format() const { return format_; }

    // Destroys everything; call while the graphics context is open.
    void release();

    enum class Prog { Copy, Prefilter, Irradiance, Count };

private:
    sg_pipeline pipeline(Prog prog);
    void draw(Gpu& gpu, Prog prog, sg_view dst, sg_view srcTex, int face, float roughness, float samples,
              const char* label, int* drawCalls);
    void destroy_images();

    int state_ = 0;  // 0 = not made, 1 = ready, -1 = failed (logged)
    sg_pixel_format format_ = SG_PIXELFORMAT_NONE;
    sg_shader shaders_[int(Prog::Count)]{};
    sg_pipeline pipelines_[int(Prog::Count)]{};
    sg_sampler sampler_{};
    // S0..S3: 1 mip each; their texture views and, per face, attachment views.
    sg_image pyramid_[kEnvPyramid]{};
    sg_view pyramidTex_[kEnvPyramid]{};
    sg_view pyramidAtt_[kEnvPyramid][6]{};
    // The prefiltered cube: kEnvLevels mips; attachment views per level and face.
    sg_image pre_{};
    sg_view preTex_{};
    sg_view preAtt_[kEnvLevels][6]{};
    // The irradiance cube.
    sg_image irr_{};
    sg_view irrTex_{};
    sg_view irrAtt_[6]{};
    sg_image blank_{};
    sg_view blankTex_{};
    bool baked_ = false;
    std::uint64_t key_ = 0;
};

}  // namespace fa::render
