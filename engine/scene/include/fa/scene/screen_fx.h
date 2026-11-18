// Transient screen effects (milestone M71-C3b): the short effects a game fires for a moment and that are drawn by the camera's
// post-processing pass over the finished picture. Shockwave (an expanding ring that bends the picture), heat haze (a rippling
// distortion over a region), a radial blur pulse, a screen flash and a fade to or from a colour. docs/RENDERING.md ("Transient screen
// effects") is the guide; this header is the C++ side that `camera.shockwave / heatHaze / radialBlur / flash / fadeOut / fadeIn`
// in a script, the `feel.shockwave ...` commands and the "shockwave", "heatHaze", "radialBlur", "screenFlash" and "fade" actions of
// the feel system (feel.h; clip events too) all call: one implementation.
//
// WHERE THE STATE LIVES. Like every game feel effect it is not part of a scene file: FeelState::screenFx (World::feel()) holds the
// live effects, World::clear() drops them, and the renderer only READS them (it never writes the world). The clock is the feel clock
// (feel_update: real time times `time.scale`, no hit-stop), so an effect is a pure function of the frames the game ran and of the
// game's clock: no wall clock, the same run draws the same picture. A paused game (time.scale 0) holds them still.
//
// PER CAMERA. Each effect belongs to one camera (`camera` of the options: an entity) or to every camera (null, the default). Its
// points are fractions of THAT camera's rectangle (a split screen has an effect on one half only), or a world point that each camera
// projects itself.
//
// BOUNDED. At most kMaxScreenFx effects are alive: starting one more ends the oldest that is not a held fade first (a new call never
// fails and never grows the list); the renderer draws the newest kMaxScreenRings shockwaves and kMaxScreenHaze heat hazes of a camera
// and composites every flash and fade of it into one colour. With nothing alive a frame costs nothing (no pass, no uniform), and
// a frame with a PostProcess is drawn exactly as before.
#pragma once

#include <array>
#include <cstdint>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/types.h"

namespace fa {

class World;

// How many screen effects may be alive at once (all cameras together); the oldest goes when one more starts.
inline constexpr std::size_t kMaxScreenFx = 16;
// What one camera's final pass draws of them: the newest shockwaves and heat hazes (the shader's arrays), and one radial blur
// and one overlay colour made of all the rest.
inline constexpr int kMaxScreenRings = 4;
inline constexpr int kMaxScreenHaze = 2;

enum class ScreenFxKind : std::int32_t { Shockwave, HeatHaze, RadialBlur, Flash, Fade };
inline constexpr int kScreenFxKindCount = 5;

// The name of the feel action that starts the kind: "shockwave", "heatHaze", "radialBlur", "screenFlash", "fade".
std::string_view screen_fx_action_name(ScreenFxKind kind);
// The kind a feel action name starts; false when `name` is not one of the five.
bool screen_fx_kind_from_action(std::string_view name, ScreenFxKind& out);

// What an effect is asked for (the options of the actions, ranges in the doc strings of the commands). A field that does not
// belong to the kind is ignored by it.
struct ScreenFxOptions {
    ScreenFxKind kind = ScreenFxKind::Shockwave;
    float duration =
        0.6f;  // seconds on the feel clock; a fade out that ends holds its colour until a fade in or a cancel
    Vec2 screen{0.5f, 0.5f};  // shockwave, radialBlur: the centre, fractions of the camera's rectangle, (0, 0) top-left
    bool atWorld =
        false;  // true: the centre is `world`, projected by each camera (not drawn behind a perspective camera)
    Vec3 world{0, 0, 0};
    Color color{1, 1, 1, 1};  // flash, fade: the colour (alpha ignored)
    float strength =
        0.04f;  // shockwave, heatHaze: how far the picture is pushed, as a fraction of its height; flash: its opacity at the start, 0..1
    float intensity = 0.4f;  // radialBlur: 0..1, the same scale as PostProcess.radialBlurIntensity
    float radius = 0.6f;     // shockwave: the radius the ring reaches, as a fraction of the picture's height
    float width = 0.1f;      // shockwave: the width of the ring, same unit
    std::array<float, 4> region{0.0f, 0.0f, 1.0f, 1.0f};  // heatHaze: [x, y, w, h], fractions of the camera's rectangle
    float frequency = 10.0f;                              // heatHaze: ripples per picture height
    float speed = 1.0f;                                   // heatHaze: cycles per second the ripples travel
    std::int32_t samples = 12;                            // radialBlur: 4..32 taps
    bool fade = true;     // flash: true fades from `strength` to 0; false holds `strength` for the duration
    bool fadeIn = false;  // fade: false = to the colour (stays there), true = from the colour to the picture
};

// The options a kind starts with (its defaults).
ScreenFxOptions screen_fx_defaults(ScreenFxKind kind);
// Checks the ranges; the error says what to fix.
Result<void> screen_fx_check(const ScreenFxOptions& o);

// One live effect.
struct ScreenFx {
    ScreenFxOptions o;
    Entity camera = kNullEntity;  // the camera it belongs to; null = every camera
    float elapsed = 0.0f;         // seconds on the feel clock since it started
    float fromAlpha =
        0.0f;  // fade: the opacity it started from (a fade that interrupts another continues from where it was)
    float toAlpha = 1.0f;      // fade: the opacity it reaches (1: held; 0: the effect ends)
    std::uint32_t serial = 0;  // the order effects were started in
};

struct ScreenFxState {
    std::vector<ScreenFx> live;  // oldest first
    std::uint32_t started = 0;   // serial of the next effect
};

// 0..1, how far the effect is through its duration (1 when the duration is 0).
float screen_fx_progress(const ScreenFx& fx);
// The radius a shockwave has reached: it leaves the centre fast and slows down (ease-out), in picture heights.
float screen_fx_ring_radius(const ScreenFx& fx);
// How much of its strength a shockwave, heat haze or radial blur has now: shockwave and radial blur die out, a heat haze fades in and out
// over 0.15 s at its ends.
float screen_fx_envelope(const ScreenFx& fx);
// The opacity (0..1) of a flash or a fade now.
float screen_fx_alpha(const ScreenFx& fx);
// True when the effect is over and is removed (a fade that reached an opacity above 0 is held).
bool screen_fx_done(const ScreenFx& fx);

// Starts an effect on `camera` (null = every camera). The accessibility settings of the feel system apply: with reduce motion on
// shockwave, heat haze and radial blur are a quarter strength; with reduced effects a flash is capped at 0.35 and always fades.
// A fade replaces the fade the camera already has. Errors: an entity that is not a camera, options out of range.
Result<void> screen_fx_start(World& w, Entity camera, const ScreenFxOptions& o);
// Moves the live effects on by `dt` seconds (feel_update calls it).
void screen_fx_update(World& w, float dt);
// Ends the effects of `camera` at once (null = every effect, held fades included).
void screen_fx_cancel(World& w, Entity camera);
// The live effects as JSON (feel.state).
Json screen_fx_json(const World& w);

}  // namespace fa
