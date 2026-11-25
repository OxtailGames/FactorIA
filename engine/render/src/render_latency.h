// The low-latency seam of M78 (docs/design/ARCHITECTURE_RENDERING_HOOKS.md, "Low latency (M78)"; docs/LATENCY.md). Private to fa_render.
//
// One LatencyController per renderer. The engine calls frame_begin() before it samples the player's input and the renderer calls mark() at
// the other points of a frame; the controller sends them to the provider of the path that runs (AMD Anti-Lag 2, Intel XeLL, NVIDIA Reflex)
// or, when no SDK is usable, paces the loop itself. With the mode off every one of these calls is one branch.
//
// A provider is one vendor SDK, reached the way the upscalers' are (render_upscale_vendor.h): the engine's own declarations of its C ABI and
// a function table taken from the loaded library. NVIDIA Reflex is Streamline's (render_latency_reflex.h): its provider reaches the SDK
// through the Streamline runtime (streamline_runtime.h), so it can run only where that runtime started with the device.
#pragma once

#include <cstdint>
#include <memory>
#include <string>
#include <string_view>
#include <thread>

#include "fa/core/json.h"
#include "fa/render/latency.h"

#include "gpu/device.h"
#include "gpu/device_hooks.h"
#include "render_upscale_vendor.h"

namespace fa::render {

class XellShare;  // render_latency_xell.h

// ---- the clock --------------------------------------------------------------------------------------------------------------------

// Where the controller reads the time and sleeps. A test puts a fake in with set_latency_clock_for_test, so the pacing and the readout do not
// depend on the speed of the machine.
class LatencyClock {
public:
    virtual ~LatencyClock() = default;
    virtual double now_ms() = 0;  // a monotonic clock, in milliseconds
    // Returns when now_ms() >= `target` (at most a little late: it sleeps most of the wait and spins the last of it).
    virtual void sleep_until_ms(double target) = 0;
};
LatencyClock& latency_clock();                        // the fake of a test, else the steady clock
void set_latency_clock_for_test(LatencyClock* fake);  // null puts the steady clock back

// A thread's id as text, for a message that says which thread asked what (the providers' report is for the thread that draws).
std::string latency_thread_text(std::thread::id id);

// ---- the providers ----------------------------------------------------------------------------------------------------------------

// One low-latency SDK. A provider is a process-wide object that serves the device that started it last (the way VendorUpscaler does).
class LatencyProvider {
public:
    virtual ~LatencyProvider() = default;
    virtual std::string_view name() const = 0;      // "AMD Anti-Lag 2", "Intel XeLL", "NVIDIA Reflex"
    virtual LatencyDriver driver() const = 0;       // the slot it fills: Reflex, AntiLag2 or Xell
    virtual std::string_view setup_id() const = 0;  // "streamline", "xess"; "" when nothing is to install
    virtual unsigned backends() const = 0;          // the bits (1 << gpu::Backend) it can run on
    // Whether this provider can run on `env` (backend, GPU maker, library installed and usable). Asked once per renderer.
    virtual VendorProbe probe(const VendorEnv& env) = 0;
    // Makes the SDK's context on `device`; "" or the SDK's reason (the renderer then runs the engine's own pacing and does not ask again).
    virtual std::string start(gpu::Device& device) = 0;
    // The sleep mode: `enabled` false is the SDK asleep (the controller turns it off when the mode changes to something else). `boost` is the
    // vendor's boost; `minIntervalUs` the shortest frame time the SDK may enforce (0 = none).
    virtual void configure(bool enabled, bool boost, std::uint32_t minIntervalUs) = 0;
    // Blocks until the SDK wants the frame to start: called once per frame, before the input is sampled.
    virtual void sleep(std::uint64_t frameId) = 0;
    // One marker of frame `frameId` (the id of the present that will show it: gpu::PresentEvent::frame).
    virtual void marker(LatencyMarker marker, std::uint64_t frameId) = 0;
    // What the SDK reports about the frames it measured ("null" when it reports nothing); never blocks.
    virtual Json vendor_report() { return Json(); }
    // Gives back what start() made on `device` (the context), before the device goes or the mode changes.
    virtual void stop(gpu::Device& device) = 0;
    // The XeLL context the provider shares with XeSS frame generation (render_latency_xell.h); null for every other provider.
    virtual XellShare* xell_share() { return nullptr; }
};

// The provider of slot `driver` (Reflex, AntiLag2, Xell), or null for a driver that has no slot (none, the engine's pacing).
LatencyProvider* latency_provider(LatencyDriver driver);
void set_latency_provider_for_test(LatencyDriver driver, LatencyProvider* fake);  // null puts the registered one back
// Fills the slot of provider->driver() with `provider` in place of the one the build has (the three of M78 are there from the start).
void register_latency_provider(std::shared_ptr<LatencyProvider> provider);
// Puts the slot of `driver` back to the provider the build has (a test that registered another one calls it when it is done).
void restore_latency_provider_for_test(LatencyDriver driver);

std::unique_ptr<LatencyProvider> make_reflex_provider();
std::unique_ptr<LatencyProvider> make_antilag2_provider();
std::unique_ptr<LatencyProvider> make_xell_provider();

// ---- the controller ---------------------------------------------------------------------------------------------------------------

// What the readout of the profiler shows (docs/LATENCY.md, "What the number is").
struct LatencyReport {
    LatencyDriver driver = LatencyDriver::None;
    double lastMs = 0;  // input to the end of the present call, of the last frame measured
    double avgMs = 0;   // over the last window (kWindow frames)
    double maxMs = 0;
    double p95Ms = 0;
    int samples = 0;  // frames measured since the controller started or was reset (all of them, not only the window)
    Json vendor;      // the SDK's own report (null when it gives none)
};

class LatencyController {
public:
    static constexpr int kWindow = 120;

    // The device the controller serves (null = none, every call below does nothing), the probe environment, and whether the engine's own pacing
    // may run (a window that is presented to: not a headless run, not the editor).
    void attach(gpu::Device* device, const VendorEnv& env, bool pacing);
    // Stops the provider that runs and forgets the device.
    void detach();
    bool attached() const { return device_ != nullptr; }

    // The setting. Decides the driver (effective_latency_driver on caps()), starts its provider (or stops the previous one), and applies the
    // sleep mode. A provider whose start() failed is not tried again (the engine's pacing runs).
    void set_settings(const LatencySettings& s);
    const LatencySettings& settings() const { return settings_; }
    // A feature that cannot run without one low-latency SDK asks for it here: DLSS frame generation needs NVIDIA Reflex (it reads the markers of
    // every frame), XeSS frame generation needs Intel XeLL; no feature asks for Anti-Lag 2 yet, but it has a slot like the others and is
    // accepted. While `d` (Reflex, Xell or AntiLag2) is required, that driver runs whatever the player's mode
    // says, even `off`: a mode that would not start it is replaced by the mode of `d` (Reflex without boost). A mode that already starts it
    // (the one that names it, or `auto` on that GPU maker) is kept with its own boost. The player's setting itself is not changed and comes back
    // when the requirement ends. None (or a driver with no provider slot) = no requirement; it lasts across attach and detach. (The requirer
    // checks the driver is usable first: a required one that cannot start falls to the engine's own pacing like any other, and forced() says
    // so.)
    void require_driver(LatencyDriver d);
    LatencyDriver required_driver() const { return required_; }
    // Whether the required driver is on only because of require_driver: it is the one that runs (driver()) and the player's mode would not
    // have started it. False while nothing is required, while the required driver failed to start, and while the player's own mode runs it.
    bool forced() const;
    LatencyDriver driver() const { return driver_; }
    // What the machine can run, asking each provider once; `reasons[i]` (0 reflex, 1 antilag2, 2 xell) says why one cannot ("" when usable).
    LatencyCaps caps();
    std::string provider_reason(LatencyDriver d);  // "" when `d`'s provider is usable here, else why not
    // The probe answers are asked again (the device changed).
    void reset_probes();

    // Called once per frame by the engine, before the player's input is sampled. `refreshHz` is the display's refresh rate when the loop
    // runs at it (vsync on; the engine's own pacing aims at it), 0 when not.
    void frame_begin(double refreshHz);
    // One point of the frame. The frame id is the present counter + 1 until PresentEnd.
    void mark(LatencyMarker m);

    // The frame id of the frame in progress (the id the present that shows it will have).
    std::uint64_t frame_id() const { return presented_ + 1; }
    // Input to present, of the last frame measured, once: negative when no frame ended since the last call.
    double take_last_frame_ms();
    LatencyReport report();
    void reset_stats();

    // The engine's own pacing, exposed for the tests: the sleep (ms) the next frame_begin would take now.
    double pacing_sleep_ms(double refreshHz) const;

private:
    struct Slot {
        bool probed = false;
        VendorProbe probe;
        bool failed = false;  // start() failed: stay off this provider
        std::string failure;
    };
    Slot& slot(LatencyDriver d);
    void stop_provider();
    void apply();
    LatencySettings effective_settings() const;  // settings_ with the requirement of require_driver applied
    bool mode_starts(LatencyMode mode, LatencyDriver d) const;  // would `mode` (on env_'s GPU maker) run provider `d`

    gpu::Device* device_ = nullptr;
    VendorEnv env_{};
    bool pacingAllowed_ = false;
    LatencySettings settings_{};
    LatencyDriver driver_ = LatencyDriver::None;
    LatencyDriver required_ = LatencyDriver::None;
    LatencyProvider* running_ = nullptr;  // the provider started on device_
    Slot slots_[3];                       // reflex, antilag2, xell

    std::uint64_t presented_ = 0;  // presents completed
    bool haveInput_ = false;
    double inputMs_ = 0;
    double frameStartMs_ = 0;    // the end of the sleep (the frame's start)
    bool frameStarted_ = false;  // frame_begin ran and the frame has not presented yet
    double presentEndMs_ = -1;   // the end of the last present
    double busyMs_ =
        0;  // the engine's own pacing: the work of a frame, sleep end to present start (follows a rise at once)
    bool haveBusy_ = false;
    double lastFrameMs_ = -1;  // input to present of the last frame, until taken
    double lastShownMs_ = 0;
    double ring_[kWindow]{};
    int ringCount_ = 0, ringHead_ = 0;
    double maxMs_ = 0;
    int samples_ = 0;
};

}  // namespace fa::render
