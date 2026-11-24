// Dynamic resolution (M76-P6c, docs/UPSCALING.md, "Dynamic resolution"): the render scale follows the frame time so
// the game holds a target.
//
// Two pieces, both pure CPU and deterministic (the renderer and the engine feed them numbers; neither reads a clock):
//  - DynamicResolutionSettings: what the game asks for (`render.dynamicResolution` of factoria.json, the command
//    render.dynamic_resolution, `window.dynamicResolution`), validated with errors that teach.
//  - DynamicResolutionController: the scale it picks. It is a factor that multiplies into the render scale
//    (Engine::Impl::apply_render_scale is the one place that does), in the range minScale..maxScale, on a grid of
//    kDynamicResolutionSteps steps.
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
// What "follow the display" is when the refresh rate is not known: no window (headless), vsync off or a frame cap
// (the time between frames is not the display's then), or while the estimate is still measuring.
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

// Reads the keys of `j` that are present over `base` (a partial object changes only those). An error names the place
// (`where` + "/key"), what is wrong and how to fix it; a misspelt key gets a "did you mean"; a minScale above the
// maxScale is named with both numbers.
Result<DynamicResolutionSettings> parse_dynamic_resolution_settings(const Json& j, std::string_view where,
                                                                    const DynamicResolutionSettings& base);

// The frame time the controller holds, in ms: `targetMs`, or one refresh of a display of `refreshHz` (outside
// 20..1000 Hz, 0 included: kDynamicDefaultRefreshHz).
double dynamic_target_ms(const DynamicResolutionSettings& s, double refreshHz);

// What the controller reports (read-only: render stats, window.upscaler, window.dynamicResolution).
struct DynamicResolutionState {
    float scale = 1.0f;     // the factor in force (1 while off)
    double frameMs = 0.0;   // the smoothed measured frame time, ms (0 until one was measured)
    double targetMs = 0.0;  // the frame time held, ms (0 while off)
    const char* source =
        "none";  // what is measured: "gpu" (timer queries), "interval" (the time between frames), "injected" (a test), "none"
    // The display refresh rate a targetMs of 0 follows, in Hz, and where it comes from (reported while off too):
    // "platform" (the OS said: fa/platform/app.h, app_display_refresh_hz), "estimated" (the median time between
    // presented frames, where the OS does not say), "default" (kDynamicDefaultRefreshHz: no window, vsync off, a
    // frame cap, or the estimate is still measuring or found no steady rate).
    double refreshHz = kDynamicDefaultRefreshHz;
    const char* refreshSource = "default";
};

// The estimate of the display's refresh rate where the platform cannot tell it (the web; a driver that does not say).
// It is fed the time between presented frames, one call per frame, and takes the median of kSamples of them after
// skipping the first kSkipFrames (the start, a resize) and every interval over kMaxSampleMs (a hitch, a load). With
// vsync on and no frame cap the presents follow the display, so the median is one refresh; a game that cannot keep up
// while it measures reads its own rate (a whole multiple of the refresh). Intervals that do not form a steady beat
// (kMaxSpread) give no rate. It never reads a clock: the same intervals give the same rate.
class RefreshRateEstimator {
public:
    static constexpr int kSkipFrames = 10;
    static constexpr int kSamples = 60;
    static constexpr double kMaxSampleMs = 50.0;  // 20 Hz: anything slower is not a display refresh
    // The median absolute deviation of the intervals may be this share of the median, else the beat is not a
    // display's (a driver that ignores the swap interval, a game that never settles): no rate. Vsync'd presents
    // deviate by a few percent.
    static constexpr double kMaxSpread = 0.15;
    // It gives up (done, rate 0) after this many frames without kSamples usable ones: a deterministic count, not a
    // time.
    static constexpr int kMaxFrames = kSkipFrames + 4 * kSamples;

    void reset();
    // One presented frame: the time since the previous one, in ms. Returns true on the call that finished the estimate.
    bool add(double intervalMs);
    bool done() const { return done_; }
    double hz() const { return hz_; }  // 0 until done(), and when no steady rate in 20..1000 Hz was found
    int samples() const { return count_; }

private:
    double samples_[kSamples] = {};
    int count_ = 0;
    int frames_ = 0;
    bool done_ = false;
    double hz_ = 0.0;
};

// The controller. Every call of update() is one frame: the measured time and the time that passed. It never reads a
// clock, so the same numbers give the same scales on every machine (the tests feed it).
//
// How it holds the target (docs/UPSCALING.md has the reasoning):
//  - the frame time is smoothed (an exponential average over about a third of a second, seeded by the first sample);
//  - the scale lives on a grid of kDynamicResolutionSteps steps between minScale and maxScale: the picture's cost
//    follows the area, so
//    a change aims at the scale whose predicted time is the middle of a dead band, never at the edge of it;
//  - a dead band around the target holds the scale; outside it a change needs the smoothed time to stay outside (down
//    0.3 s, up 1 s, so a
//    one-frame hitch changes nothing) and a hold time since the last change (down 0.5 s, up 1.5 s). A change
//    moves at most a quarter of the range down or an eighth up per change, so the scale changes at most twice per
//    second and the renderer (which makes its images again at each change) is never asked for it every frame;
//  - with a GPU time (`exact`) the headroom is visible, so it moves by prediction in both directions. With only the
//    time between frames
//    (vsync pins it at the refresh rate while the game is fast enough) it cannot see headroom: it goes down by
//    prediction and tries one step up after a quiet time; a try that fails (the frame time goes over again within 3
//    s) makes the next wait twice as long (3 s up to 48 s) and the step that failed is not tried again for a minute
//    (two, four, ... after repeated failures), so the scale settles under it.
class DynamicResolutionController {
public:
    static constexpr int kSteps = kDynamicResolutionSteps;

    void configure(const DynamicResolutionSettings& s);  // a change of the range starts again at the largest scale
    void reset();                                        // starts again at the largest scale with nothing measured

    // One frame. `sampleMs` is the measured frame time (< 0: none this frame), `elapsedMs` the time since the last
    // call (smoothing and holds count it), `targetMs` the frame time to hold, `exact` true when sampleMs is a GPU
    // time. Returns true when the scale changed.
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
