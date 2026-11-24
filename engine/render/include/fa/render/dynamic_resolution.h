// Dynamic resolution (M76-P6c, docs/UPSCALING.md, "Dynamic resolution"): the render scale follows the frame time so the game holds a target.
//
// Two pieces, both pure CPU and deterministic (the renderer and the engine feed them numbers; neither reads a clock):
//  - DynamicResolutionSettings: what the game asks for (`render.dynamicResolution` of factoria.json, the command
//    render.dynamic_resolution, `window.dynamicResolution`), validated with errors that teach.
//  - DynamicResolutionController: the scale it picks. It is a factor that multiplies into the render scale (Engine::Impl::apply_render_scale
//    is the one place that does), in the range minScale..maxScale, on a grid of kDynamicResolutionSteps steps.
//
// Off (the default) is no controller, no factor and the picture of a build without the feature.
#pragma once

#include <string>
#include <string_view>

#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa::render {

// The range the engine can draw at: the renderer's floor and the full size.
inline constexpr float kDynamicScaleFloor = 0.25f;
inline constexpr float kDynamicScaleCeiling = 1.0f;
// The scale grid: the range between minScale and maxScale is divided in this many steps.
inline constexpr int kDynamicResolutionSteps = 32;
// The frame-time targets that are accepted (ms): 4 ms is 250 fps, 100 ms is 10 fps. 0 means "follow the display".
inline constexpr double kDynamicTargetMinMs = 4.0;
inline constexpr double kDynamicTargetMaxMs = 100.0;
// What "follow the display" is where the platform cannot tell the refresh rate (Linux X11, Android, the web).
inline constexpr double kDynamicDefaultRefreshHz = 60.0;

struct DynamicResolutionSettings {
    bool enabled = false;
    double targetMs = 0.0;  // the frame time to hold; 0 = one display refresh (see dynamic_target_ms)
    float minScale = 0.5f;  // 0.25..1: the smallest share of the base render scale the controller may use
    float maxScale = 1.0f;  // minScale..1: the largest (and where it starts)
    bool operator==(const DynamicResolutionSettings&) const = default;
};

// {"enabled", "targetMs", "minScale", "maxScale"} (all four always present).
Json dynamic_resolution_to_json(const DynamicResolutionSettings& s);

// Reads the keys of `j` that are present over `base` (a partial object changes only those). An error names the place (`where` + "/key"),
// what is wrong and how to fix it; a misspelt key gets a "did you mean"; a minScale above the maxScale is named with both numbers.
Result<DynamicResolutionSettings> parse_dynamic_resolution_settings(const Json& j, std::string_view where,
                                                                    const DynamicResolutionSettings& base);

// The frame time the controller holds, in ms: `targetMs`, or one refresh of a display of `refreshHz` (0 or unknown: 60 Hz).
double dynamic_target_ms(const DynamicResolutionSettings& s, double refreshHz);

// What the controller reports (read-only: render stats, window.upscaler, window.dynamicResolution).
struct DynamicResolutionState {
    float scale = 1.0f;     // the factor in force (1 while off)
    double frameMs = 0.0;   // the smoothed measured frame time, ms (0 until one was measured)
    double targetMs = 0.0;  // the frame time held, ms (0 while off)
    const char* source =
        "none";  // what is measured: "gpu" (timer queries), "interval" (the time between frames), "injected" (a test), "none"
};

// The controller. Every call of update() is one frame: the measured time and the time that passed. It never reads a clock, so the same
// numbers give the same scales on every machine (the tests feed it).
//
// How it holds the target (docs/UPSCALING.md has the reasoning):
//  - the frame time is smoothed (an exponential average over about a third of a second, seeded by the first sample);
//  - the scale lives on a grid of kDynamicResolutionSteps steps between minScale and maxScale: the picture's cost follows the area, so
//    a change aims at the scale whose predicted time is the middle of a dead band, never at the edge of it;
//  - a dead band around the target holds the scale; outside it a change needs the smoothed time to stay outside (down 0.3 s, up 1 s, so a
//    one-frame hitch changes nothing) and a hold time since the last change (down 0.5 s, up 1.5 s). A change
//    moves at most a quarter of the range down or an eighth up per change, so the scale changes at most twice per second and the
//    renderer (which makes its images again at each change) is never asked for it every frame;
//  - with a GPU time (`exact`) the headroom is visible, so it moves by prediction in both directions. With only the time between frames
//    (vsync pins it at the refresh rate while the game is fast enough) it cannot see headroom: it goes down by prediction and tries one step
//    up after a quiet time; a try that fails (the frame time goes over again within 3 s) makes the next wait twice as long (3 s up to 48 s) and
//    the step that failed is not tried again for a minute (two, four, ... after repeated failures), so the scale settles under it.
class DynamicResolutionController {
public:
    static constexpr int kSteps = kDynamicResolutionSteps;

    void configure(const DynamicResolutionSettings& s);  // a change of the range starts again at the largest scale
    void reset();                                        // starts again at the largest scale with nothing measured

    // One frame. `sampleMs` is the measured frame time (< 0: none this frame), `elapsedMs` the time since the last call (smoothing and holds
    // count it), `targetMs` the frame time to hold, `exact` true when sampleMs is a GPU time. Returns true when the scale changed.
    bool update(double sampleMs, double elapsedMs, double targetMs, bool exact);

    float scale() const;
    int step() const { return step_; }
    double smoothedMs() const { return ema_; }
    int changes() const {
        return changes_;
    }  // how many times the scale changed since reset(): tests and a doc claim count it
    const DynamicResolutionSettings& settings() const { return s_; }

private:
    float scale_of(int step) const;
    DynamicResolutionSettings s_{};
    int step_ = kSteps;
    double ema_ = 0.0;
    bool seeded_ = false;
    double sinceChange_ = 0.0;   // seconds since the scale last changed
    double over_ = 0.0;          // seconds the smoothed time has been over the band (a change down needs it to last)
    double under_ = 0.0;         // ... and under it
    double quiet_ = 0.0;         // seconds spent inside the band since the last change (the wait of the next try up)
    double probeWait_ = 3.0;     // seconds of quiet before the next try up
    bool lastWasProbe_ = false;  // the last change was a try up
    int probeCeiling_ =
        kSteps + 1;  // a try up never reaches this step (the one a failed try went over), for a minute or more
    double ceilingAge_ = 0.0;
    double ceilingLife_ = 60.0;
    int changes_ = 0;
};

}  // namespace fa::render
