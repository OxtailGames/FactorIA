// The PostProcess component (milestone M71, "Linear HDR and a post-processing stack"): the data of the screen effects, on a Camera
// (that camera's own stack) or on a volume (global, box, circle or sphere) that blends into the cameras inside it. This file holds
// only DATA: the component, the canonical order of its effects and the neutral values a volume blends from. Merging the camera's
// stack and the volumes into the one stack a frame draws (`resolve_post_stack`) is in fa_render (src/postprocess_resolve.h): the
// scene module cannot include the renderer.
//
// Reflection has no nested structs, so the component is flat: each effect has a `<effect>Enabled` switch and its parameters,
// named `<effect><Parameter>` (the pattern of Camera.bloom*). `resolve_post_stack` finds the fields of an effect by that prefix
// (a test fails on a field that has none), so a new parameter only needs the right name.
#pragma once

#include <array>
#include <cstdint>
#include <string>
#include <string_view>

#include "fa/core/math.h"
#include "fa/core/typed_array.h"
#include "fa/core/types.h"
#include "fa/scene/components.h"

namespace fa {

// PostProcess.shape: where the component applies. Global = every camera; Box, Circle and Sphere = the cameras whose position is
// inside the shape (or within blendDistance of it) when the component is on an entity WITHOUT a Camera.
enum class PostShape : std::int32_t { Global, Box, Circle, Sphere };

// PostProcess.tonemapMode: how scene-linear HDR colour is brought to the display range.
enum class TonemapMode : std::int32_t { None, Neutral, Aces, Agx, Reinhard };

// PostProcess.exposureMode: manual = a fixed exposureEv; auto = the scene's brightness is measured and the exposure adapts to it.
enum class ExposureMode : std::int32_t { Manual, Auto };

// PostProcess.outlineMode: depth = edges found in the depth and normal buffers (3D); sprite = the outline of the alpha edge of 2D
// sprites (no depth needed).
enum class OutlineMode : std::int32_t { Depth, Sprite };

// PostProcess.ssaoQuality: the number of directions and steps of the ambient occlusion (GTAO), cost grows with each level.
enum class SsaoQuality : std::int32_t { Low, Medium, High, Ultra };

// The effects of the stack in the canonical ORDER they run in, written once. Everything up to Bloom works on scene-linear HDR
// colour (before the tonemap); Tonemap brings it to the display range; the rest work on the display-referred picture.
// Why this order: ambient occlusion, reflections, fog and sun shafts belong to the lighting of the scene; the exposure scales
// the lit scene before any effect that depends on how bright it is; depth of field and the blurs (motion, radial) act on the
// scene before the lens effects (distortion, chromatic aberration) and the bloom, which glows from what the lens shows; the
// tonemap and the colour grading make the picture; vignette, sharpen, outline, pixelate and posterize are then looks drawn on
// the finished picture; grain goes over everything but the colour filter, which stays the LAST pass (the accessibility filter
// of Camera.colorFilter is the last pass of the frame, HUD included).
enum class PostEffect : std::int32_t {
    Ssao,
    Ssr,
    Fog,
    SunShafts,
    Exposure,
    DepthOfField,
    MotionBlur,
    RadialBlur,
    LensDistortion,
    ChromaticAberration,
    Bloom,
    Tonemap,
    ColorGrading,
    Vignette,
    Sharpen,
    Outline,
    Pixelate,
    Posterize,
    FilmGrain,
    ColorFilter,
    Count
};
inline constexpr int kPostEffectCount = int(PostEffect::Count);

// The name of each effect, in canonical order: the prefix of its PostProcess fields and the name `render.supports` and the
// postprocess.* commands use.
inline constexpr std::array<std::string_view, kPostEffectCount> kPostEffectOrder = {
    "ssao",         "ssr",        "fog",          "sunShafts",      "exposure",
    "depthOfField", "motionBlur", "radialBlur",   "lensDistortion", "chromaticAberration",
    "bloom",        "tonemap",    "colorGrading", "vignette",       "sharpen",
    "outline",      "pixelate",   "posterize",    "filmGrain",      "colorFilter"};

constexpr std::string_view post_effect_name(PostEffect e) { return kPostEffectOrder[std::size_t(e)]; }
// True for the effects that run on scene-linear HDR colour (up to and including the bloom), false after the tonemap.
constexpr bool post_effect_is_hdr(PostEffect e) { return int(e) <= int(PostEffect::Bloom); }
// The effect called `name` ("bloom"), or PostEffect::Count when there is none.
PostEffect post_effect_from_name(std::string_view name);

// A stack of screen effects. On an entity WITH a Camera it is that camera's own stack (the shape, size, blendDistance and priority
// do nothing there). On an entity without one it is a VOLUME: global (every camera) or box / circle / sphere (the cameras inside it
// or within blendDistance), blended into each camera's stack by priority and weight. Every effect is off by default; a volume only
// ever adds to or changes the effects it switches on (to remove an effect inside a volume, switch it on there with its neutral values:
// bloomIntensity 0, vignetteIntensity 0, ...). The effects run in the canonical order of kPostEffectOrder.
struct PostProcess {
    // --- Where and how strongly it applies ---------------------------------------------------------------------------------
    bool enabled = true;  // false: this component contributes nothing (every effect of it is ignored)
    PostShape shape = PostShape::Global;
    // Box: full width, height, depth in world units (before the entity's scale); circle and sphere: x is the radius.
    Vec3 size{10, 10, 10};
    float blendDistance =
        0.0f;  // world units outside the shape over which the influence fades from 1 to 0; 0 = a hard edge
    std::int32_t priority =
        0;                // volumes with a higher priority are applied later and win over lower ones; ties by entity id
    float weight = 1.0f;  // 0..1: overall strength of this component, multiplied with its distance influence

    // --- tonemap: HDR colour to the display range ---------------------------------------------------------------------------
    bool tonemapEnabled = false;
    TonemapMode tonemapMode = TonemapMode::Neutral;

    // --- exposure: the brightness the picture is scaled to ------------------------------------------------------------------
    bool exposureEnabled = false;
    ExposureMode exposureMode = ExposureMode::Manual;
    float exposureEv = 0.0f;      // manual: the exposure in stops; auto: a compensation added to the measured exposure
    float exposureMinEv = -4.0f;  // auto: the darkest exposure the adaptation may choose, in stops
    float exposureMaxEv = 4.0f;   // auto: the brightest
    float exposureAdaptationSpeed =
        2.0f;  // auto: how fast the exposure follows the scene, per second (higher = faster)

    // --- bloom: glow around bright pixels (the fields mirror Camera.bloom*) -------------------------------------------------
    bool bloomEnabled = false;
    float bloomIntensity = 1.2f;
    float bloomThreshold = 0.7f;   // brightness where the glow starts
    float bloomKnee = 0.5f;        // 0..1: how softly the glow starts above the threshold (0 = hard)
    float bloomRadius = 20.0f;     // glow size in design pixels
    bool bloomScreenSpace = true;  // false: the HUD is drawn after the bloom and never glows
    std::string bloomLensDirt;     // texture dirtying the glow like a dirty lens ("" = none)
    float bloomLensDirtIntensity = 1.0f;

    // --- colorGrading: lift/gamma/gain, white balance, saturation, contrast, curves and a LUT ---------------------------------
    bool colorGradingEnabled = false;
    Color colorGradingLift{0, 0, 0, 1};    // added to the shadows per channel (rgb used, alpha ignored); 0 = unchanged
    Color colorGradingGamma{1, 1, 1, 1};   // the midtones per channel; 1 = unchanged, above 1 lighter
    Color colorGradingGain{1, 1, 1, 1};    // multiplies the highlights per channel; 1 = unchanged
    float colorGradingTemperature = 0.0f;  // white balance, -100 (cooler, blue) .. 100 (warmer, orange)
    float colorGradingTint = 0.0f;         // white balance, -100 (green) .. 100 (magenta)
    float colorGradingSaturation = 1.0f;   // 0 = grey, 1 = unchanged, above 1 more vivid
    float colorGradingContrast = 1.0f;     // 1 = unchanged, above 1 more contrast around mid grey
    float colorGradingHueShift = 0.0f;     // degrees, -180..180: rotates every hue around the grey axis; 0 = unchanged
    // Curves: flat lists of points [x0, y0, x1, y1, ...] with x and y in 0..1 and x ascending, the curve passing through them
    // (monotone interpolation). Empty = the straight line. Master first, then each channel on top of it.
    ArrayF32 colorGradingCurveMaster;
    ArrayF32 colorGradingCurveRed;
    ArrayF32 colorGradingCurveGreen;
    ArrayF32 colorGradingCurveBlue;
    std::string colorGradingLut;               // a .cube 3D lookup table ("" = none)
    float colorGradingLutContribution = 1.0f;  // 0..1: how much of the LUT is mixed in

    // --- colorFilter: the accessibility filter (the same filters as Camera.colorFilter) --------------------------------------
    bool colorFilterEnabled = false;
    ColorFilter colorFilterMode = ColorFilter::None;

    // --- vignette: darkened corners ------------------------------------------------------------------------------------------
    bool vignetteEnabled = false;
    float vignetteIntensity = 0.4f;   // 0..1: how dark the corners get
    float vignetteSmoothness = 0.5f;  // 0..1: how soft the transition is
    float vignetteRoundness = 1.0f;   // 0..1: 1 = round, 0 = follows the shape of the screen
    Vec2 vignetteCenter{0.5f,
                        0.5f};  // [x, y] of the clear centre as fractions of the picture, (0, 0) the top-left corner
    Color vignetteColor{0, 0, 0, 1};  // colour of the darkened edge (rgb)

    // --- chromaticAberration: colour fringes toward the edges ----------------------------------------------------------------
    bool chromaticAberrationEnabled = false;
    float chromaticAberrationIntensity = 0.3f;  // 0..1: how far red and blue separate at the edges

    // --- filmGrain: noise over the picture -----------------------------------------------------------------------------------
    bool filmGrainEnabled = false;
    float filmGrainIntensity = 0.2f;  // 0..1
    float filmGrainSize = 1.0f;       // grain size in design pixels (0.5 .. 4)
    bool filmGrainAnimated = true;    // a new pattern each frame (from the frame number, so a run is reproducible)
    float filmGrainLuminanceResponse =
        0.8f;  // 0..1: 0 = the same grain everywhere, 1 = none in pure black and pure white

    // --- lensDistortion: a barrel or pincushion lens ----------------------------------------------------------------------
    bool lensDistortionEnabled = false;
    float lensDistortionIntensity = 0.3f;  // -1 (pincushion) .. 1 (barrel)
    float lensDistortionScale = 1.0f;  // 0.5 .. 2: zooms the picture to hide or show the edges the distortion leaves
    Vec2 lensDistortionCenter{0.5f,
                              0.5f};  // [x, y] of the lens axis as fractions of the picture, (0, 0) the top-left corner

    // --- sharpen --------------------------------------------------------------------------------------------------------
    bool sharpenEnabled = false;
    float sharpenIntensity = 0.3f;  // 0..2

    // --- outline: edges drawn on the picture ----------------------------------------------------------------------------------
    bool outlineEnabled = false;
    OutlineMode outlineMode = OutlineMode::Depth;
    Color outlineColor{0, 0, 0, 1};
    float outlineWidth = 1.0f;  // line width in design pixels (0.5 .. 8)
    float outlineDepthThreshold =
        0.1f;  // depth mode: the relative depth jump that makes an edge (smaller = more edges)
    float outlineNormalThreshold = 0.4f;  // depth mode: the change of surface direction that makes an edge
    float outlineAlphaThreshold = 0.5f;   // sprite mode: the alpha level that counts as the sprite's border

    // --- pixelate and posterize -----------------------------------------------------------------------------------------------
    bool pixelateEnabled = false;
    float pixelateSize = 4.0f;  // size of a block in design pixels (1 = unchanged)
    bool posterizeEnabled = false;
    std::int32_t posterizeLevels = 8;  // distinct levels per colour channel (2 .. 256; 256 = unchanged)

    // --- ssao: ambient occlusion from the depth buffer (3D) ---------------------------------------------------------------------
    bool ssaoEnabled = false;
    SsaoQuality ssaoQuality = SsaoQuality::Medium;
    float ssaoIntensity = 1.0f;  // 0..4
    float ssaoRadius = 0.5f;     // world units: how far from a point occluders darken it

    // --- depthOfField: blur away from the focus (3D) -----------------------------------------------------------------------------
    bool depthOfFieldEnabled = false;
    float depthOfFieldFocusDistance = 10.0f;  // world units from the camera that are sharp
    Entity depthOfFieldTarget =
        kNullEntity;  // autofocus: the focus distance follows this entity (none = depthOfFieldFocusDistance)
    float depthOfFieldFocusSpeed = 5.0f;  // autofocus: how fast the focus follows the target, per second
    float depthOfFieldFocusRange = 5.0f;  // world units around the focus distance that stay fully sharp
    float depthOfFieldNearBlur = 6.0f;    // largest blur in design pixels in front of the focus
    float depthOfFieldFarBlur = 8.0f;     // largest blur in design pixels behind the focus
    bool depthOfFieldBokeh = true;        // true: a disc blur where bright points become discs; false: a smooth blur

    // --- motionBlur: smear from the camera's movement (from depth) ---------------------------------------------------------------
    bool motionBlurEnabled = false;
    float motionBlurIntensity = 0.5f;    // 0..1: the part of the frame the shutter is open
    std::int32_t motionBlurSamples = 8;  // 4 .. 32 taps along the movement

    // --- ssr: screen-space reflections (3D) --------------------------------------------------------------------------------------
    bool ssrEnabled = false;
    float ssrIntensity = 1.0f;     // 0..1: how much of the reflection is mixed in
    float ssrMaxDistance = 50.0f;  // world units a reflected ray travels
    float ssrThickness = 0.3f;     // world units behind a surface that still count as a hit
    std::int32_t ssrSteps = 32;    // 8 .. 128 steps along the ray

    // --- fog: distance and height fog (mirrors SceneSettings.fogColor and fogDensity) ----------------------------------------------
    bool fogEnabled = false;
    Color fogColor{0.5f, 0.6f, 0.7f, 1.0f};
    float fogDensity = 0.02f;       // fog thickness with distance; 0 = none
    float fogStart = 0.0f;          // world units from the camera before the fog begins
    float fogHeightDensity = 0.0f;  // extra thickness near the ground; 0 = no height fog
    float fogHeightBase = 0.0f;     // world y where the height fog is thickest
    float fogHeightFalloff = 0.1f;  // how fast the height fog thins going up (per world unit)

    // --- sunShafts: light rays from the sun through the scene ------------------------------------------------------------------------
    bool sunShaftsEnabled = false;
    float sunShaftsIntensity = 0.5f;  // 0..2
    float sunShaftsThreshold = 0.8f;  // brightness the sky needs to cast rays
    float sunShaftsLength = 0.5f;     // 0..1: how far the rays reach, as a fraction of the screen
    Color sunShaftsColor{1.0f, 0.95f, 0.8f, 1.0f};

    // --- radialBlur: a blur spreading from a point (speed lines, impact) ----------------------------------------------------------------
    bool radialBlurEnabled = false;
    float radialBlurIntensity = 0.3f;   // 0..1
    Vec2 radialBlurCenter{0.5f, 0.5f};  // [x, y] of the centre as fractions of the picture, (0, 0) the top-left corner
    std::int32_t radialBlurSamples = 12;  // 4 .. 32 taps
};

// The PostProcess a volume blends FROM when the stack it blends into has an effect off: every effect off, and the strength of each
// parameter at its neutral value (bloomIntensity 0, vignetteIntensity 0, colorGradingSaturation 1, posterizeLevels 256, ...),
// so a volume that switches an effect on fades it in instead of popping.
const PostProcess& postprocess_neutral();

// The index of the effect a PostProcess field belongs to (its name starts with the effect's name), -1 for a field that belongs to
// none (enabled, shape, size, blendDistance, priority, weight). `<effect>Enabled` is the effect's switch.
int post_field_effect(std::string_view fieldName);

// Registers the PostProcess component (called by register_builtin_components).
void register_postprocess_component(TypeRegistry& registry);

}  // namespace fa
