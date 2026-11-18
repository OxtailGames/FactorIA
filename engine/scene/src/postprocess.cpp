// The PostProcess component: reflection (the doc strings are the documentation AIs read), the neutral values and the field-to-effect
// mapping. The data is in fa/scene/postprocess.h.
#include "fa/scene/postprocess.h"

#include "fa/core/reflect.h"

namespace fa {

PostEffect post_effect_from_name(std::string_view name) {
    for (int i = 0; i < kPostEffectCount; ++i)
        if (kPostEffectOrder[std::size_t(i)] == name) return PostEffect(i);
    return PostEffect::Count;
}

int post_field_effect(std::string_view fieldName) {
    for (int i = 0; i < kPostEffectCount; ++i) {
        const std::string_view e = kPostEffectOrder[std::size_t(i)];
        if (fieldName.size() >= e.size() && fieldName.substr(0, e.size()) == e) return i;
    }
    return -1;
}

const PostProcess& postprocess_neutral() {
    static const PostProcess neutral = [] {
        PostProcess p;
        p.tonemapMode = TonemapMode::None;
        p.bloomIntensity = 0.0f;
        p.bloomLensDirtIntensity = 0.0f;
        p.colorGradingLutContribution = 0.0f;
        p.vignetteIntensity = 0.0f;
        p.chromaticAberrationIntensity = 0.0f;
        p.filmGrainIntensity = 0.0f;
        p.lensDistortionIntensity = 0.0f;
        p.sharpenIntensity = 0.0f;
        p.outlineWidth = 0.0f;
        p.pixelateSize = 1.0f;
        p.posterizeLevels = 256;
        p.ssaoIntensity = 0.0f;
        p.depthOfFieldNearBlur = 0.0f;
        p.depthOfFieldFarBlur = 0.0f;
        p.motionBlurIntensity = 0.0f;
        p.ssrIntensity = 0.0f;
        p.fogDensity = 0.0f;
        p.fogHeightDensity = 0.0f;
        p.sunShaftsIntensity = 0.0f;
        p.radialBlurIntensity = 0.0f;
        return p;
    }();
    return neutral;
}

void register_postprocess_component(TypeRegistry& r) {
    r.add<PostProcess>(
         "PostProcess",
         "A stack of screen effects (tonemap, exposure, bloom, colour grading, vignette, chromatic aberration, film "
         "grain, lens "
         "distortion, sharpen, outline, pixelate, posterize, ambient occlusion, depth of field, motion blur, "
         "reflections, fog, sun "
         "shafts, radial blur, colour filter), every one off by default. On the entity of a Camera it is that camera's "
         "own stack. "
         "On any other entity it is a VOLUME: shape \"global\" applies to every camera, \"box\", \"circle\" (2D, x and "
         "y) and "
         "\"sphere\" to the cameras whose position is inside it or within blendDistance of it, blended into the "
         "camera's stack by "
         "priority (a higher one wins) and by weight. Numbers and colours are interpolated by the volume's influence; "
         "switches, "
         "modes, textures and curves switch over when the influence reaches 0.5. A volume only adds to or changes the "
         "effects it "
         "switches on: to remove an effect inside a volume switch it on with its neutral values (bloomIntensity 0, "
         "vignetteIntensity 0, ...). Each effect has a `<effect>Enabled` switch and parameters named "
         "`<effect><Parameter>`. "
         "The effects run in a fixed order: ssao, ssr, fog, sunShafts, exposure, depthOfField, motionBlur, radialBlur, "
         "lensDistortion, chromaticAberration, bloom (all on HDR colour), tonemap, colorGrading, vignette, sharpen, "
         "outline, "
         "pixelate, posterize, filmGrain, colorFilter (the last pass). M71 is in progress: the component, the volumes, "
         "the postprocess.* commands and render.supports exist, and each effect is drawn as its M71 package lands: "
         "render.supports {\"feature\": \"<effect>\"} says which ones this build draws on this GPU (ssao, exposure, "
         "bloom, "
         "tonemap, colorFilter, lensDistortion, chromaticAberration, colorGrading, vignette, sharpen, outline, "
         "pixelate, posterize, filmGrain, radialBlur, depthOfField, motionBlur and ssr today), until then the fields "
         "only store "
         "the values. The lens distortion, "
         "the chromatic aberration, the colour grading, the vignette, the sharpen, the outline, the pixelation, the "
         "posterization and the film grain are drawn in the final pass, after the bloom: "
         "the lens and the aberration bend how the scene is read (in scene colour, before the exposure), the rest work "
         "on the display picture (what the screen shows, paper white = 1, the same on an SDR and an HDR output) and "
         "none of them clips above white. The depth of field and the motion blur read the depth prepass and are "
         "drawn on the scene colour, before the bloom and the final pass. Every camera draws its own stack over its "
         "own part of the picture (a "
         "split screen: each half has its own); the bloom and the colour filter are one per frame, the ones of the "
         "camera that draws first. Camera.bloom* and Camera.colorFilter are deprecated and keep working unchanged: "
         "they "
         "stand in for a PostProcess with bloom and the colour filter. A frame without any stack costs nothing: no "
         "pass, no "
         "target. Screen-space items (the HUD) are drawn over the finished picture, so exposure, tonemap and the "
         "output "
         "encode never touch them; the colour filter does. The ambient occlusion (ssao) darkens the 3D meshes where "
         "they "
         "meet, in place before the bloom, so the interface drawn before the post passes is darkened where it covers "
         "meshes.",
         "Camera")
        .field("enabled", &PostProcess::enabled,
               "false: this component contributes nothing (all its effects are ignored), without losing its values.")
        .enum_field("shape", &PostProcess::shape, {"global", "box", "circle", "sphere"},
                    "Volume shape (an entity without a Camera). global: every camera, size and blendDistance are "
                    "ignored. box: the "
                    "cameras inside the box (an orthographic camera is tested in x and y only; a perspective one in x, "
                    "y and z), "
                    "turned and scaled with the entity. circle: a disc in x and y, radius size.x. sphere: a ball, "
                    "radius size.x. "
                    "On an entity with a Camera the shape is ignored: it is that camera's own stack.")
        .field("size", &PostProcess::size,
               "Box: full width, height and depth in world units (before the entity's scale). circle and sphere: "
               "size.x is the "
               "radius. Pixels in a 2D game, metres in 3D.")
        .field("blendDistance", &PostProcess::blendDistance,
               "World units outside the shape over which the influence fades from 1 (at the edge) to 0. 0 = a hard "
               "edge. A camera "
               "inside the shape always has influence 1.")
        .range(0, 100000)
        .field("priority", &PostProcess::priority,
               "Order of the volumes: a volume with a higher priority is applied later, so it wins where two disagree. "
               "Equal "
               "priorities are applied in the order of the entity ids, so a result never changes between runs.")
        .field("weight", &PostProcess::weight,
               "0..1: the overall strength of this component, multiplied with its distance influence. 0 = as if it "
               "were disabled.")
        .range(0, 1)

        // tonemap
        .field("tonemapEnabled", &PostProcess::tonemapEnabled,
               "Switches the tonemap on: it brings the HDR colour of a linear scene (SceneSettings.colorSpace "
               "\"linear\") to the "
               "range of the display. Cost: none of its own: it is folded into the one final pass that also does the "
               "exposure, "
               "the colour filter and the encode for the display (one full-screen pass).")
        .enum_field(
            "tonemapMode", &PostProcess::tonemapMode, {"none", "neutral", "aces", "agx", "reinhard"},
            "Only used when tonemapEnabled. none: clamp at white. neutral (default): keeps colours close to the scene "
            "and "
            "rolls the highlights off gently. aces: the filmic curve with high contrast and saturated highlights. agx: "
            "a "
            "filmic curve that desaturates very bright colours toward white. reinhard: the simplest, flattest curve.")

        // exposure
        .field("exposureEnabled", &PostProcess::exposureEnabled,
               "Switches the exposure on: the brightness the picture is scaled to before the tonemap. Cost: manual "
               "exposure is "
               "folded into the one final pass (free); auto exposure adds two tiny passes (a 32x32 brightness "
               "reduction and a "
               "1x1 adaptation, no read back to the CPU) and needs float render targets, else it stays at exposureEv.")
        .enum_field(
            "exposureMode", &PostProcess::exposureMode, {"manual", "auto"},
            "manual: the picture is scaled by exposureEv. auto: the exposure follows the measured brightness of the "
            "scene (adaptation speed exposureAdaptationSpeed, between exposureMinEv and exposureMaxEv), plus "
            "exposureEv.")
        .field("exposureEv", &PostProcess::exposureEv,
               "Exposure in stops (each +1 doubles the brightness). In auto mode it is a compensation added to what is "
               "measured.")
        .range(-10, 10)
        .field("exposureMinEv", &PostProcess::exposureMinEv,
               "Auto exposure only: the lowest exposure the adaptation may choose, in stops.")
        .range(-10, 10)
        .field("exposureMaxEv", &PostProcess::exposureMaxEv,
               "Auto exposure only: the highest exposure the adaptation may choose, in stops.")
        .range(-10, 10)
        .field("exposureAdaptationSpeed", &PostProcess::exposureAdaptationSpeed,
               "Auto exposure only: how fast the exposure follows the scene, per second (2 = most of the way in a "
               "second); "
               "higher adapts faster.")
        .range(0, 20)

        // bloom
        .field("bloomEnabled", &PostProcess::bloomEnabled,
               "Switches the bloom on: a glow around bright pixels. The same effect as Camera.bloom, moved into the "
               "stack. Cost: "
               "a bright pass, a few down-sampling and blur passes at reduced resolution (lower for a wider "
               "bloomRadius) and one "
               "composite pass over the frame; see docs/RENDERING.md for the measured cost.")
        .field("bloomIntensity", &PostProcess::bloomIntensity,
               "Only used when bloomEnabled. Strength of the glow added back, 0..10 (0 = none).")
        .range(0, 10)
        .field("bloomThreshold", &PostProcess::bloomThreshold,
               "Only used when bloomEnabled. Brightness (the largest of r, g, b) where the glow starts; the glow "
               "reaches full "
               "strength at 1 (or 0.01 above the threshold when that is higher). In a linear scene it can be above 1.")
        .range(0, 20)
        .field("bloomKnee", &PostProcess::bloomKnee,
               "Only used when bloomEnabled. 0..1: how softly the glow starts above the threshold (0 = a hard cut, 1 = "
               "a wide "
               "ramp).")
        .range(0, 1)
        .field("bloomRadius", &PostProcess::bloomRadius,
               "Only used when bloomEnabled. How far the glow reaches, in design pixels (1..128).")
        .range(1, 128)
        .field(
            "bloomScreenSpace", &PostProcess::bloomScreenSpace,
            "Only used when bloomEnabled. true: the HUD glows too. false: screen-space items are drawn after the bloom "
            "and "
            "stay crisp. When the final pass runs (exposure, tonemap, or a colour filter in a linear scene) the HUD is "
            "drawn after it and "
            "never glows, whatever this says.")
        .asset_field(
            "bloomLensDirt", &PostProcess::bloomLensDirt, "texture",
            "Only used when bloomEnabled. A texture that dirties the glow like smudges on a lens (the glow shows it "
            "where the texture is bright). Empty = none.")
        .field("bloomLensDirtIntensity", &PostProcess::bloomLensDirtIntensity,
               "Only used with a bloomLensDirt texture. How much the dirt shows in the glow, 0..10.")
        .range(0, 10)

        // colorGrading
        .field("colorGradingEnabled", &PostProcess::colorGradingEnabled,
               "Switches the colour grading on: white balance, lift/gamma/gain, contrast, saturation, hue shift and a "
               ".cube LUT, applied to the display picture (what the screen shows) in that order, without clipping "
               "above white. Cost: part of the final pass.")
        .field("colorGradingLift", &PostProcess::colorGradingLift,
               "Only used when colorGradingEnabled. Colour added to the shadows (rgb, -1..1; alpha ignored): full in "
               "black, fading to nothing at white. [0, 0, 0] = unchanged; a blue tint here gives cold shadows.")
        .field("colorGradingGamma", &PostProcess::colorGradingGamma,
               "Only used when colorGradingEnabled. Midtones per channel (rgb, 0.1..10; alpha ignored). [1, 1, 1] = "
               "unchanged; above 1 lightens that channel's midtones (black and white stay).")
        .field("colorGradingGain", &PostProcess::colorGradingGain,
               "Only used when colorGradingEnabled. Multiplies the highlights per channel (rgb, 0..8; alpha ignored). "
               "[1, 1, 1] = unchanged.")
        .field("colorGradingTemperature", &PostProcess::colorGradingTemperature,
               "Only used when colorGradingEnabled. White balance, -100 (cooler, blue) to 100 (warmer, orange): at "
               "+-100 red and blue gain 20% against each other, the brightness is kept. 0 = unchanged.")
        .range(-100, 100)
        .field("colorGradingTint", &PostProcess::colorGradingTint,
               "Only used when colorGradingEnabled. White balance, -100 (green) to 100 (magenta), the same strength "
               "as the temperature. 0 = unchanged.")
        .range(-100, 100)
        .field("colorGradingSaturation", &PostProcess::colorGradingSaturation,
               "Only used when colorGradingEnabled. 0 = greyscale, 1 = unchanged, above 1 more vivid.")
        .range(0, 3)
        .field("colorGradingContrast", &PostProcess::colorGradingContrast,
               "Only used when colorGradingEnabled. 1 = unchanged, above 1 more contrast around mid grey (display "
               "value 0.5), below 1 flatter.")
        .range(0, 3)
        .field("colorGradingHueShift", &PostProcess::colorGradingHueShift,
               "Only used when colorGradingEnabled. Degrees, -180..180: turns every hue around the grey axis (red "
               "toward green for a positive shift). 0 = unchanged.")
        .range(-180, 180)
        .field("colorGradingCurveMaster", &PostProcess::colorGradingCurveMaster,
               "NOT DRAWN YET (the values are stored; render.supports colorGrading lists what is drawn). A tone curve "
               "on all channels as a flat list of points [x0, y0, x1, y1, ...], x and y in 0..1 with x ascending "
               "(input brightness to output brightness). Empty = the straight line. Example: [0, 0, 0.5, 0.4, 1, 1] "
               "darkens the midtones. For a tone curve today use a colorGradingLut.")
        .field("colorGradingCurveRed", &PostProcess::colorGradingCurveRed,
               "NOT DRAWN YET. A curve on the red channel only (same format as colorGradingCurveMaster), applied "
               "after the master curve. Empty = unchanged.")
        .field("colorGradingCurveGreen", &PostProcess::colorGradingCurveGreen,
               "NOT DRAWN YET. A curve on the green channel only (same format as colorGradingCurveMaster). Empty = "
               "unchanged.")
        .field("colorGradingCurveBlue", &PostProcess::colorGradingCurveBlue,
               "NOT DRAWN YET. A curve on the blue channel only (same format as colorGradingCurveMaster). Empty = "
               "unchanged.")
        .asset_field(
            "colorGradingLut", &PostProcess::colorGradingLut, "any",
            "Only used when colorGradingEnabled. Project path of a .cube 3D lookup table (the file a colour grading "
            "tool exports: LUT_3D_SIZE 2 to 65, 16, 32 and 64 are the usual ones, DOMAIN 0..1) applied last, on the "
            "display picture; import it with assets.import. A file that is missing or malformed is logged once with "
            "its line and the LUT is skipped. Empty = none.")
        .field("colorGradingLutContribution", &PostProcess::colorGradingLutContribution,
               "Only used with a colorGradingLut. 0..1: how much of the LUT is mixed in (1 = fully, 0 = the LUT is "
               "skipped).")
        .range(0, 1)

        // colorFilter
        .field("colorFilterEnabled", &PostProcess::colorFilterEnabled,
               "Switches the accessibility colour filter on. The same filters as Camera.colorFilter, in the stack; it "
               "is the "
               "last pass of the frame and covers the HUD. Cost: one full-screen pass; none of its own when the final "
               "pass "
               "runs and there is no HUD (it is fused into it).")
        .enum_field("colorFilterMode", &PostProcess::colorFilterMode,
                    {"none", "greyscale", "highContrast", "protanopia", "deuteranopia", "tritanopia"},
                    "Only used when colorFilterEnabled. The filter, with the meaning of Camera.colorFilter.")

        // vignette
        .field("vignetteEnabled", &PostProcess::vignetteEnabled,
               "Switches the vignette on: the edges darken toward a colour. Drawn on the display picture, so it looks "
               "the same on an SDR and an HDR output. Cost: part of the final pass.")
        .field("vignetteIntensity", &PostProcess::vignetteIntensity,
               "Only used when vignetteEnabled. 0..1: how far the edge is pulled to vignetteColor (0 = none, 1 = "
               "fully).")
        .range(0, 1)
        .field("vignetteSmoothness", &PostProcess::vignetteSmoothness,
               "Only used when vignetteEnabled. 0..1: how soft the transition from the clear centre to the edge is "
               "(0 = a sharp ring, 1 = it starts at the centre).")
        .range(0, 1)
        .field("vignetteRoundness", &PostProcess::vignetteRoundness,
               "Only used when vignetteEnabled. 0..1: 1 = a circle, 0 = an ellipse that follows the shape of the "
               "screen.")
        .range(0, 1)
        .field("vignetteCenter", &PostProcess::vignetteCenter,
               "Only used when vignetteEnabled. The clear centre [x, y] as fractions of the picture, (0, 0) the "
               "top-left corner and (0.5, 0.5) the middle. Use it to follow the player or an impact.")
        .field("vignetteColor", &PostProcess::vignetteColor,
               "Only used when vignetteEnabled. Colour of the darkened edge (rgb; alpha ignored), as the screen shows "
               "it. Black by default; red gives a damage flash.")

        // chromaticAberration
        .field(
            "chromaticAberrationEnabled", &PostProcess::chromaticAberrationEnabled,
            "Switches the chromatic aberration on: red and blue are read from a little further out and in than green, "
            "radially from the middle of the picture, like a cheap lens. Made in scene colour (before the exposure "
            "and the tonemap); beyond the picture the edge colour is repeated. Cost: two more reads of the scene in "
            "the final pass.")
        .field("chromaticAberrationIntensity", &PostProcess::chromaticAberrationIntensity,
               "Only used when chromaticAberrationEnabled. 0..1: how far the channels separate at the screen's edge "
               "(0 = none; 1 = red and blue sit 2% of the width each side of green at the edge).")
        .range(0, 1)

        // filmGrain
        .field("filmGrainEnabled", &PostProcess::filmGrainEnabled,
               "Switches the film grain on: monochrome noise over the display picture (after the sharpen, before the "
               "colour filter), the same on an SDR and an HDR output. Cost: part of the final pass.")
        .field("filmGrainIntensity", &PostProcess::filmGrainIntensity,
               "Only used when filmGrainEnabled. 0..1: how strong the noise is (0 = none; 1 moves a midtone by up to "
               "a quarter of white).")
        .range(0, 1)
        .field("filmGrainSize", &PostProcess::filmGrainSize,
               "Only used when filmGrainEnabled. Grain size in pixels of the picture, 0.5 to 4 (a grain below 1 is a "
               "pixel).")
        .range(0.5f, 4)
        .field("filmGrainAnimated", &PostProcess::filmGrainAnimated,
               "Only used when filmGrainEnabled. true: the pattern changes every frame (from the world's frame "
               "number, never the clock, so a recorded run is the same every time). false: a still pattern.")
        .field("filmGrainLuminanceResponse", &PostProcess::filmGrainLuminanceResponse,
               "Only used when filmGrainEnabled. 0..1: 0 = the grain is as strong in black and white as in the "
               "midtones, 1 = none in pure black and pure white, strongest at mid grey (like film).")
        .range(0, 1)

        // lensDistortion
        .field(
            "lensDistortionEnabled", &PostProcess::lensDistortionEnabled,
            "Switches the lens distortion on: the picture bulges (barrel) or pinches (pincushion) like a lens. Drawn "
            "in the final pass, after the bloom (the glow is bent with the picture). Where the lens reads beyond the "
            "picture (the corners of a barrel, the edges of a zoom below 1) the result is BLACK: raise "
            "lensDistortionScale to hide it. Cost: one bilinear read of the scene in the final pass.")
        .field("lensDistortionIntensity", &PostProcess::lensDistortionIntensity,
               "Only used when lensDistortionEnabled. -1 (pincushion) to 1 (barrel). 0 = none (a scale other than 1 "
               "still zooms).")
        .range(-1, 1)
        .field("lensDistortionScale", &PostProcess::lensDistortionScale,
               "Only used when lensDistortionEnabled. 0.5..2: zooms the picture (above 1 in); raise it to hide the "
               "black edges a barrel distortion leaves (about 1.3 at intensity 1).")
        .range(0.5f, 2)
        .field("lensDistortionCenter", &PostProcess::lensDistortionCenter,
               "Only used when lensDistortionEnabled. The lens axis [x, y] as fractions of the picture, (0, 0) the "
               "top-left corner and (0.5, 0.5) the middle.")

        // sharpen
        .field("sharpenEnabled", &PostProcess::sharpenEnabled,
               "Switches the sharpening on: it brings out the detail the picture lost to scaling or antialiasing. "
               "Contrast adaptive (flat areas and edges already at black or white are left alone, so it makes no "
               "halos) and drawn on the display picture. Cost: five reads of the scene per pixel in the final pass.")
        .field("sharpenIntensity", &PostProcess::sharpenIntensity,
               "Only used when sharpenEnabled. 0..2: strength (0 = none; 2 is the strongest, harsh on noisy "
               "pictures).")
        .range(0, 2)

        // outline
        .field("outlineEnabled", &PostProcess::outlineEnabled,
               "Switches the outline on: lines drawn at the edges of things, over the finished picture. Depth mode "
               "needs the depth and normal prepass (3D); sprite mode draws the 2D world once more as coverage. Both "
               "draw their own outline per camera, over its own viewport: it works in split screen too, and a line "
               "never crosses into the camera next to it.")
        .enum_field(
            "outlineMode", &PostProcess::outlineMode, {"depth", "sprite"},
            "Only used when outlineEnabled. depth: edges found where depth or surface direction jump (3D models, the "
            "line straddles the edge). sprite: a line outside the border of the 2D world (sprites, tiles, shapes, "
            "text, particles), found from how much each pixel is covered; 3D models and the clear colour do not "
            "count.")
        .field("outlineColor", &PostProcess::outlineColor,
               "Only used when outlineEnabled. Colour of the lines (alpha = opacity; alpha 0 draws nothing).")
        .field("outlineWidth", &PostProcess::outlineWidth,
               "Only used when outlineEnabled. Line width in design pixels, 0.5 to 8 (0 = none), so the line has the "
               "same look at any render scale.")
        .range(0, 8)
        .field("outlineDepthThreshold", &PostProcess::outlineDepthThreshold,
               "Only used in depth mode. The relative jump of depth that makes an edge; smaller finds more edges.")
        .range(0, 1)
        .field("outlineNormalThreshold", &PostProcess::outlineNormalThreshold,
               "Only used in depth mode. The change of surface direction (0..1) that makes an edge; smaller finds more "
               "edges.")
        .range(0, 1)
        .field("outlineAlphaThreshold", &PostProcess::outlineAlphaThreshold,
               "Only used in sprite mode. The alpha level (0..1) that counts as the sprite's border.")
        .range(0, 1)

        // pixelate, posterize
        .field("pixelateEnabled", &PostProcess::pixelateEnabled,
               "Switches the pixelation on: the picture is drawn in blocks of one colour (read at the block's centre). "
               "Cost: folded into the final pass.")
        .field(
            "pixelateSize", &PostProcess::pixelateSize,
            "Only used when pixelateEnabled. Size of a block in design pixels, 1 to 64 (1 = unchanged), so the blocks "
            "look the same at any render scale.")
        .range(1, 64)
        .field("posterizeEnabled", &PostProcess::posterizeEnabled,
               "Switches the posterization on: each colour channel of the display picture is cut to a few levels, "
               "after the grading. Cost: folded into the final pass.")
        .field("posterizeLevels", &PostProcess::posterizeLevels,
               "Only used when posterizeEnabled. Levels per colour channel, 2 to 256 (256 = unchanged).")
        .range(2, 256)

        // ssao
        .field("ssaoEnabled", &PostProcess::ssaoEnabled,
               "Switches the ambient occlusion on: creases and contact points of 3D models get darker. Needs the depth "
               "buffer "
               "(3D) and a GPU with RGBA16F targets that blend; it costs the most of the effects at high quality.")
        .enum_field(
            "ssaoQuality", &PostProcess::ssaoQuality, {"low", "medium", "high", "ultra"},
            "Only used when ssaoEnabled. The number of directions and steps (GTAO): low is for phones and the "
            "web; each "
            "level costs about twice the one before. low and medium work at half the resolution of the camera's "
            "rectangle, high and ultra at full resolution.")
        .field("ssaoIntensity", &PostProcess::ssaoIntensity,
               "Only used when ssaoEnabled. 0..4: how dark the occlusion is.")
        .range(0, 4)
        .field("ssaoRadius", &PostProcess::ssaoRadius,
               "Only used when ssaoEnabled. World units: how far from a point an occluder still darkens it.")
        .range(0.01f, 20)

        // depthOfField
        .field("depthOfFieldEnabled", &PostProcess::depthOfFieldEnabled,
               "Switches the depth of field on: opaque 3D meshes away from the focus distance are blurred, "
               "those in front of it and those behind it each by their own largest blur. It reads the depth prepass, "
               "so it needs opaque meshes in view (a frame without any is drawn without it); where no mesh was "
               "drawn (the sky, sprites, shapes) the depth is taken as infinite and the far blur applies. It runs "
               "before the bloom and the final pass, and the HUD is not blurred.")
        .field("depthOfFieldFocusDistance", &PostProcess::depthOfFieldFocusDistance,
               "Only used when depthOfFieldEnabled. World units from the camera that are in focus (ignored while "
               "depthOfFieldTarget is set).")
        .range(0.01f, 100000)
        .field("depthOfFieldTarget", &PostProcess::depthOfFieldTarget,
               "Only used when depthOfFieldEnabled. Autofocus: the focus follows the view depth of this entity (its "
               "distance along the camera's axis), moving by depthOfFieldFocusSpeed. Empty, a destroyed entity or one "
               "behind the camera = use depthOfFieldFocusDistance.")
        .field("depthOfFieldFocusSpeed", &PostProcess::depthOfFieldFocusSpeed,
               "Only used with an autofocus target. How fast the focus moves to it, per second: each frame covers "
               "1 - exp(-speed * dt) of the way (engine clock, the same on every machine); higher is quicker, 0 stays "
               "where it is.")
        .range(0, 100)
        .field("depthOfFieldFocusRange", &PostProcess::depthOfFieldFocusRange,
               "Only used when depthOfFieldEnabled. World units of the band that stays fully sharp, centred on the "
               "focus distance (half of it on each side); the blur then grows smoothly to its largest in front of the "
               "band over the distance to the camera, and behind it over the focus distance.")
        .range(0, 100000)
        .field("depthOfFieldNearBlur", &PostProcess::depthOfFieldNearBlur,
               "Only used when depthOfFieldEnabled. The largest blur, in design pixels (times the render scale), in "
               "front of the focus (0..32). It spreads past the silhouette of the near object.")
        .range(0, 32)
        .field("depthOfFieldFarBlur", &PostProcess::depthOfFieldFarBlur,
               "Only used when depthOfFieldEnabled. The largest blur, in design pixels (times the render scale), "
               "behind the focus (0..32). A sharper object never takes colour from a blurred one behind it.")
        .range(0, 32)
        .field("depthOfFieldBokeh", &PostProcess::depthOfFieldBokeh,
               "Only used when depthOfFieldEnabled. true: a disc-shaped blur where bright points become discs (more "
               "expensive). "
               "false: a smooth blur.")

        // motionBlur
        .field("motionBlurEnabled", &PostProcess::motionBlurEnabled,
               "Switches the camera motion blur on: the picture smears along the way the camera moved since the frame "
               "before, computed from the depth prepass (opaque 3D meshes; the sky only smears when the camera "
               "turns). Objects that move on their own are not blurred. There is no blur on the first frame or "
               "after the camera did not draw the frame before (a cut); a camera that jumps to another place in "
               "one frame blurs up to a longest streak. It runs before the bloom and the final pass.")
        .field(
            "motionBlurIntensity", &PostProcess::motionBlurIntensity,
            "Only used when motionBlurEnabled. 0..1: the fraction of the frame the shutter stays open (1 = the whole "
            "movement).")
        .range(0, 1)
        .field("motionBlurSamples", &PostProcess::motionBlurSamples,
               "Only used when motionBlurEnabled. 4..32 taps along the movement; more is smoother and costs more. A "
               "streak is at most 8% of the picture's larger side.")
        .range(4, 32)

        // ssr
        .field(
            "ssrEnabled", &PostProcess::ssrEnabled,
            "Switches the screen-space reflections on: shiny surfaces reflect what is on the screen. Needs the depth "
            "buffer (3D); it only reflects what is visible, so the edges of the screen fade out.")
        .field("ssrIntensity", &PostProcess::ssrIntensity,
               "Only used when ssrEnabled. 0..1: how much reflection is mixed in; surfaces reflect by a fresnel term "
               "(more at a "
               "grazing angle), there is no per-material roughness (docs/RENDERING_EFFECTS.md).")
        .range(0, 1)
        .field("ssrMaxDistance", &PostProcess::ssrMaxDistance,
               "Only used when ssrEnabled. World units a reflected ray travels before it gives up.")
        .range(1, 1000)
        .field("ssrThickness", &PostProcess::ssrThickness,
               "Only used when ssrEnabled. World units behind a surface that still count as a hit.")
        .range(0.01f, 10)
        .field("ssrSteps", &PostProcess::ssrSteps,
               "Only used when ssrEnabled. 8..128 steps along the ray; more is more accurate and costs more.")
        .range(8, 128)

        // fog
        .field("fogEnabled", &PostProcess::fogEnabled,
               "Switches the stack's fog on: distance and height fog drawn from the depth buffer (3D). It replaces "
               "SceneSettings.fogColor and fogDensity where it is on.")
        .field("fogColor", &PostProcess::fogColor, "Only used when fogEnabled. Colour distant things fade to.")
        .field("fogDensity", &PostProcess::fogDensity,
               "Only used when fogEnabled. Fog thickness with distance (the same scale as SceneSettings.fogDensity); 0 "
               "= none.")
        .range(0, 10)
        .field("fogStart", &PostProcess::fogStart,
               "Only used when fogEnabled. World units from the camera before the fog begins.")
        .range(0, 100000)
        .field("fogHeightDensity", &PostProcess::fogHeightDensity,
               "Only used when fogEnabled. Extra fog thickness near fogHeightBase (a ground mist); 0 = no height fog.")
        .range(0, 10)
        .field("fogHeightBase", &PostProcess::fogHeightBase,
               "Only used when fogEnabled. World y where the height fog is thickest.")
        .field("fogHeightFalloff", &PostProcess::fogHeightFalloff,
               "Only used when fogEnabled. How fast the height fog thins going up, per world unit (larger = a thinner "
               "layer).")
        .range(0, 10)

        // sunShafts
        .field(
            "sunShaftsEnabled", &PostProcess::sunShaftsEnabled,
            "Switches the sun shafts on: rays of light spreading from the sun through gaps in the scene (3D, needs the "
            "depth buffer).")
        .field("sunShaftsIntensity", &PostProcess::sunShaftsIntensity,
               "Only used when sunShaftsEnabled. 0..2: strength.")
        .range(0, 2)
        .field("sunShaftsThreshold", &PostProcess::sunShaftsThreshold,
               "Only used when sunShaftsEnabled. Brightness the sky needs to cast rays.")
        .range(0, 20)
        .field("sunShaftsLength", &PostProcess::sunShaftsLength,
               "Only used when sunShaftsEnabled. 0..1: how far the rays reach, as a fraction of the screen.")
        .range(0, 1)
        .field("sunShaftsColor", &PostProcess::sunShaftsColor,
               "Only used when sunShaftsEnabled. Tint of the rays (rgb).")

        // radialBlur
        .field("radialBlurEnabled", &PostProcess::radialBlurEnabled,
               "Switches the radial blur on: the picture streaks away from a point (speed, impact, a dash).")
        .field("radialBlurIntensity", &PostProcess::radialBlurIntensity,
               "Only used when radialBlurEnabled. 0..1: how far the streaks reach.")
        .range(0, 1)
        .field(
            "radialBlurCenter", &PostProcess::radialBlurCenter,
            "Only used when radialBlurEnabled. The centre of the blur [x, y] as fractions of the picture, (0, 0) the "
            "top-left corner and (0.5, 0.5) the middle.")
        .field("radialBlurSamples", &PostProcess::radialBlurSamples,
               "Only used when radialBlurEnabled. 4..32 taps; more is smoother and costs more.")
        .range(4, 32);
}

}  // namespace fa
