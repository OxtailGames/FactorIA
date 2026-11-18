// The display-space effects of the final pass (M71-C1, C2): colour grading, vignette, chromatic aberration, lens distortion, sharpen,
// outline, pixelate, posterize and film grain. The numbers a pass needs (`PostFx`, made from the PostStack by make_post_fx: every value sanitised and clamped to the range the
// effect supports) and the CPU form of the maths post.glsl runs, which the tests compare the GPU's picture with.
//
// Where each one runs, in the final pass (post.glsl), after the bloom pass has added the glow to the scene:
//
//   texel read      lens distortion (the picture is sampled at a bent position), then chromatic aberration (red and blue are sampled
//                   a little further out and in)   [a bilinear sample of the scene; black outside it with a lens, else the edge]
//   scene colour    sane, decode of a gamma scene, exposure, tonemap, the sRGB encode          [as before; only with a conversion]
//   display colour  colour grading (white balance, gain, lift, gamma, contrast, saturation, hue, then the LUT), vignette
//   neighbours      sharpen reads the four neighbours of the pixel, each taken through the steps above
//   outline         over the sharpened picture: depth mode reads the prepass image (postprocess.h, PrepassRef), sprite mode the coverage
//                   image of the 2D world; both read it by integer texel, never filtered
//   pixelate        no step of its own: it moves the position every step above reads to the centre of its block, so what a block shows
//                   is the full-resolution picture (lens, grade, sharpen, outline) sampled at one point
//   posterize       the encoded colour cut to a number of levels per channel
//   last            film grain (on the block-free pixel), the flash / fade overlay, the dither (not with posterize), the colour filter
//
// M71-C3b adds the radial blur and the transient screen effects of the camera (shockwave and heat haze move the position the whole pass
// reads, after the lens; the radial blur averages taps toward its centre; the flash and fade are one colour laid over the end): see
// "the transient screen effects" below and fa/scene/screen_fx.h.
//
// The effects after the tonemap work on the ENCODED picture (what the screen shows: sRGB values, 1.0 = paper white), in a linear scene
// too, so a grade or a LUT made for a screen picture means the same here. None of them clips: on an HDR output a value above 1 keeps its
// excess (the grade and the LUT are applied to the part up to 1 and the rest is carried over).
#pragma once

#include <array>
#include <cstdint>
#include <vector>

#include "fa/core/math.h"
#include "fa/scene/screen_fx.h"
#include "postprocess_resolve.h"

namespace fa {
struct CubeLut;
}

namespace fa::render {

// The bits of the effect mask the final pass reads (post.glsl: fm).
enum PostFxBit : int {
    kFxLens = 1,
    kFxAberration = 2,
    kFxGrade = 4,
    kFxLut = 8,
    kFxVignette = 16,
    kFxSharpen = 32,
    kFxGrain = 64,
    kFxOutline = 128,        // outline in depth mode: edges of the prepass image
    kFxOutlineSprite = 256,  // outline in sprite mode: the alpha edge of the coverage image
    kFxPixelate = 512,
    kFxPosterize = 1024,
    // 2048 is the camera's rectangle (postprocess.cpp, kFxRect)
    kFxShockwave = 4096,  // transient screen effects (fa/scene/screen_fx.h), added by add_screen_fx
    kFxHaze = 8192,
    kFxRadialBlur = 16384,  // the persistent PostProcess.radialBlur or the pulse of camera.radialBlur
    kFxOverlay = 32768,     // a flash or a fade
};

// One expanding ring (a shockwave): the picture near it is pushed outward. Distances are fractions of the picture's HEIGHT.
struct ShockRing {
    Vec2 center{0.5f, 0.5f};  // camera-local uv, top-left origin
    float radius = 0.0f;
    float halfWidth = 0.05f;
    float push = 0.0f;  // how far the picture moves at the ring's middle
};
// One heat haze: a ripple over a region that moves the picture sideways.
struct HazeBand {
    std::array<float, 4> region{0.0f, 0.0f, 1.0f, 1.0f};  // [x, y, w, h], camera-local uv
    float strength = 0.0f;                                // the sideways push, fraction of the picture's height
    float frequency = 10.0f;                              // ripples per picture height
    float phase = 0.0f;                                   // cycles: speed x seconds
};

struct PostFx {
    bool lens = false;
    float lensK =
        0.0f;  // PostProcess.lensDistortionIntensity * kLensStrength: the radius grows by 1 + k r^2 (r = 1 at a corner)
    float lensZoom = 1.0f;  // lensDistortionScale: above 1 the picture is zoomed in
    Vec2 lensCenter{0.5f, 0.5f};
    bool aberration = false;
    float aberrationAmount = 0.0f;  // the red and blue taps move by (uv - 0.5) * this: intensity * kAberrationStrength
    bool grade = false;
    Vec3 whiteBalance{1, 1, 1};  // per-channel gains from temperature and tint (luminance kept)
    Vec3 lift{0, 0, 0}, gain{1, 1, 1}, invGamma{1, 1, 1};
    float contrast = 1.0f, saturation = 1.0f;
    float hueA = 1.0f, hueB = 0.0f,
          hueC = 0.0f;  // the hue rotation about the grey axis: rows (a b c), (c a b), (b c a)
    bool lut = false;   // a table is bound (the renderer clears it when the file cannot be loaded)
    float lutContribution = 1.0f;
    bool vignette = false;
    float vignetteIntensity = 0.0f, vignetteSmoothness = 0.5f, vignetteRoundness = 1.0f;
    Vec2 vignetteCenter{0.5f, 0.5f};
    Vec3 vignetteColor{0, 0, 0};
    bool sharpen = false;
    float sharpenWeight =
        0.0f;  // the weight of each of the four neighbours: -0.1 * intensity (negative: it takes from them)
    bool grain = false;
    float grainIntensity = 0.0f, grainSize = 1.0f, grainResponse = 0.0f;
    std::uint32_t grainSeed = 0;  // the frame number (24 bits) when animated, else 0
    // Outline: `outline` is on when the line has a width and an opacity; `outlineSprite` is the mode (false: depth). The renderer clears
    // `outline` when the image the mode reads does not exist this frame (no prepass, no coverage pass).
    bool outline = false, outlineSprite = false;
    float outlineWidth = 0.0f;  // physical pixels: PostProcess.outlineWidth (design pixels) x the render scale
    Vec3 outlineColor{0, 0, 0};
    float outlineOpacity = 1.0f;
    float outlineDepthThreshold = 0.1f, outlineNormalThreshold = 0.4f, outlineAlphaThreshold = 0.5f;
    // Pixelate: the block in whole physical pixels (PostProcess.pixelateSize in design pixels x the render scale, rounded; at 1 the
    // effect is off). The block grid starts at the top left corner of the picture.
    bool pixelate = false;
    int pixelateBlock = 1;
    // Posterize: the number of distinct values of a channel (2 .. 255; at 256 the effect is off).
    bool posterize = false;
    int posterizeLevels = 256;
    // Transient screen effects of the camera (add_screen_fx): the newest rings and hazes, the radial blur (persistent or a pulse: the
    // stronger one) and one overlay colour (every flash and fade composited).
    std::array<ShockRing, kMaxScreenRings> rings;
    int ringCount = 0;
    std::array<HazeBand, kMaxScreenHaze> hazes;
    int hazeCount = 0;
    bool radialBlur = false;
    Vec2 radialCenter{0.5f, 0.5f};  // camera-local uv
    float radialLength = 0.0f;      // how far toward the centre the last tap reads: intensity * kRadialBlurStrength
    int radialSamples = 12;         // 4 .. 32
    bool overlay = false;
    Vec3 overlayColor{0, 0, 0};  // display space
    float overlayAlpha = 0.0f;

    bool warps() const { return lens || aberration; }
    bool outline_depth() const { return outline && !outlineSprite; }
    bool outline_sprite() const { return outline && outlineSprite; }
    bool any() const {
        return lens || aberration || grade || lut || vignette || sharpen || grain || outline || pixelate || posterize ||
               ringCount > 0 || hazeCount > 0 || radialBlur || overlay;
    }
    // The mask post.glsl reads.
    int mask() const {
        return (lens ? kFxLens : 0) | (aberration ? kFxAberration : 0) | (grade ? kFxGrade : 0) | (lut ? kFxLut : 0) |
               (vignette ? kFxVignette : 0) | (sharpen ? kFxSharpen : 0) | (grain ? kFxGrain : 0) |
               (outline ? (outlineSprite ? kFxOutlineSprite : kFxOutline) : 0) | (pixelate ? kFxPixelate : 0) |
               (posterize ? kFxPosterize : 0) | (ringCount > 0 ? kFxShockwave : 0) | (hazeCount > 0 ? kFxHaze : 0) |
               (radialBlur ? kFxRadialBlur : 0) | (overlay ? kFxOverlay : 0);
    }
};

// How far the intensities (0..1) go in picture terms. The component's docs say what they mean; these are the factors.
inline constexpr float kLensStrength =
    0.3f;  // intensity 1: a corner is sampled 1.3 times as far out (barrel); -1: 0.7 (pincushion)
inline constexpr float kAberrationStrength =
    0.04f;  // intensity 1: red and blue sit 2% of the picture's width from green at the edge
inline constexpr float kGrainStrength = 0.25f;  // intensity 1: the grain swings the display value by up to 0.25
inline constexpr float kRadialBlurStrength =
    0.25f;  // intensity 1: the farthest tap reads a quarter of the way to the centre

// The effects of `stack` (PostEffect::LensDistortion .. FilmGrain that this file draws), sanitised: NaN and out-of-range numbers are
// clamped to what the component documents. `frame`: the world's frame counter, the seed of an animated grain (never a clock). The LUT
// is only flagged when the stack names a table and the contribution is above 0; the renderer decides whether it could be loaded.
// `designScale`: physical pixels per design pixel (the renderer's render scale), the unit of the outline width and the pixelate block.
PostFx make_post_fx(const PostStack& stack, std::uint64_t frame, float designScale = 1.0f);

// ---- the CPU form of the shader (post.glsl) -------------------------------------------------------------------------------------

// Colour grading without the LUT, on an encoded picture value: white balance, gain, lift, gamma, contrast, saturation, hue. Not clamped
// above; never below 0.
Vec3 grade_color(const PostFx& fx, Vec3 c);
// The LUT step: the table is looked up at `c` clamped to 0..1, and what it changes is added to `c`, so the part above 1 is kept.
Vec3 apply_lut(const CubeLut& lut, float contribution, Vec3 c);
// How far the vignette pulls the pixel at `uv` (top-left origin, 0..1) toward vignetteColor, 0..1. `aspect` = width / height.
float vignette_amount(const PostFx& fx, Vec2 uv, float aspect);
// The position the lens samples for the output pixel at `uv` (top-left origin, 0..1). Outside 0..1 the picture is black.
Vec2 lens_source(const PostFx& fx, Vec2 uv, float aspect);
// The sharpened pixel from itself and its four neighbours (contrast-adaptive: flat areas and edges already at the limits are kept).
Vec3 sharpen_color(const PostFx& fx, Vec3 c, Vec3 up, Vec3 down, Vec3 left, Vec3 right);
// The grain of the pixel (x, y): -1..1, triangular, from an integer hash of the grain cell and the seed: the same on every GPU and run.
float grain_noise(int x, int y, const PostFx& fx);
// How much of the picture shows at the output pixel whose lens source is `source` (top-left origin, 0..1) on a `w` x `h` target: 1
// inside, 0 outside, a one-pixel smoothstep across the edge (the shader's `cover`), so a lens does not leave a stair-stepped border.
float lens_coverage(Vec2 source, int w, int h);
// The grain seed of the camera number `cameraIndex` (its place among the frame's cameras, 0 = the first) from the frame's seed
// (`PostFx::grainSeed`): the first camera keeps it, the others get an odd multiple of a large constant added (24 bits), so the
// halves of a split screen do not show the same grain.
std::uint32_t grain_seed_for_camera(std::uint32_t seed, int cameraIndex);
// The pixel after the grain: `c` plus the noise, scaled by the intensity and by how mid-toned the pixel is (grainResponse).
Vec3 grain_color(const PostFx& fx, Vec3 c, int x, int y);
// The pixel a block of the pixelation shows: the picture is read at (x, y) of `w` x `h` through this pixel (the centre of the block that
// holds (x, y), the last pixel when the block is cut by the edge). Integer maths, so the GPU and the CPU agree on every pixel.
void pixelate_pixel(const PostFx& fx, int x, int y, int w, int h, int& outX, int& outY);
// The colour cut to posterizeLevels values per channel on 0..1, rounded to the nearest; what is above 1 (an HDR output) is kept.
Vec3 posterize_color(const PostFx& fx, Vec3 c);

// ---- the transient screen effects (fa/scene/screen_fx.h) -------------------------------------------------------------------------

// Adds what `live` (the effects that belong to ONE camera: its own and those of every camera) draws now to `fx`: the newest
// kMaxScreenRings shockwaves and kMaxScreenHaze heat hazes, the strongest radial blur (against the persistent one `fx` may already have)
// and every flash and fade composited, oldest first, into one overlay colour. `viewProj`: the camera's query view-projection, which
// projects the effects that sit at a world point (one behind a perspective camera is not drawn). With nothing alive `fx` is unchanged.
void add_screen_fx(PostFx& fx, const std::vector<ScreenFx>& live, const Mat4& viewProj);
// Where a shockwave and a heat haze move the position the pixel at `uv` (camera-local, top-left origin) reads: the sum of their offsets,
// in uv units. `aspect` = width / height of the camera's rectangle.
Vec2 shockwave_offset(const PostFx& fx, Vec2 uv, float aspect);
Vec2 haze_offset(const PostFx& fx, Vec2 uv, float aspect);
// The positions the radial blur reads for the (already displaced) position `uv`: radialSamples of them from `uv` itself to the one pulled
// radialLength of the way toward the centre. Returns how many (0 without the blur, the first is `uv`).
int radial_blur_taps(const PostFx& fx, Vec2 uv, Vec2* out);
// `c` with the flash / fade colour laid over it.
Vec3 overlay_color(const PostFx& fx, Vec3 c);

}  // namespace fa::render
