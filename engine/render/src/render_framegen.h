// The frame-generation seam of M78 (docs/design/ARCHITECTURE_RENDERING_HOOKS.md, "Frame generation (M78)"; docs/FRAME_GENERATION.md).
// Private to fa_render.
//
// One FrameGenController per renderer. A provider is one vendor SDK that puts a generated frame between two rendered ones: NVIDIA DLSS
// frame generation (through Streamline), AMD FSR 3 frame generation (FidelityFX, ffx_api framegeneration) and Intel XeSS frame generation
// (libxess_fg). Each takes part in making the window's swapchain (it makes it itself or wraps it: DeviceHook::d3d12_create_swapchain /
// vulkan_create_swapchain, then the present hooks), so its hook is registered before the device exists (register_framegen_device_hooks, called
// by Renderer::init when RendererDesc::frameGeneration is on) and the controller starts the provider on that device and swapchain.
// The hooks are handed to the device of THAT renderer only (gpu::DeviceInit::hooks, framegen_device_hooks), never registered process-wide:
// a second renderer in the same process that did not ask for frame generation makes its device and swapchain untouched.
//
// What a frame hands the provider (FrameGenFrame): the picture BEFORE the screen-space items ("hudless": generation sees the game, not the
// menus, whose text would smear between two frames), the finished picture with the items, the depth and the motion the temporal upscaler
// uses, the camera's matrices and the jitter. The items are composited on every presented frame by the SDK from the final picture's own
// items (it is told the picture has them: `hudDrawn`). Generation therefore needs the upscale stage with a temporal frame (the jitter, the
// depth and the motion exist only there): without it the controller refuses, and says what to switch on.
//
// Each slot is filled by its package (register_framegen_provider, the one call a provider makes; the Dlss and Xess slots by
// render_framegen_dlss.h and render_framegen_xess.h); an empty slot says which package fills it. The tests put fakes in with
// set_framegen_provider_for_test.
#pragma once

#include <array>
#include <cstdint>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/render/framegen.h"

#include "gpu/device.h"
#include "gpu/device_hooks.h"
#include "hdr_encode.h"
#include "render_upscale_vendor.h"

namespace fa::render {

// ---- the providers ----------------------------------------------------------------------------------------------------------------

// What the provider is told about the window's swapchain when it starts (the one the engine made, or the provider's own through its hook).
struct FrameGenSwapchain {
    gpu::Backend backend = gpu::Backend::Recording;
    int width = 0, height = 0;  // the swapchain's size in pixels (0: not known yet)
    bool vsync = true;
};

// One frame of generation: the images are the frame's, at the sizes below. The provider records into `list` (the frame's pass list) or
// into its own native one (gpu::Device::begin_native); it never keeps an image past the call.
struct FrameGenFrame {
    gpu::Device* device = nullptr;
    gpu::CommandList* list = nullptr;
    gpu::Image
        hudless{};  // the output-sized picture before the screen-space items (the same image as `presented` when there are none)
    gpu::Image presented{};  // the output-sized picture the swapchain shows (with the items when `hudDrawn`)
    bool hudDrawn =
        false;  // the screen-space items were drawn over `final` (the provider composites them on its generated frames)
    // The render-sized depth and motion (the images the temporal upscaler's preparation pass makes, shaders/upscale_mfx.glsl).
    //  depth: depthReversed false: d / (d + 1) of the linear view depth d in world units (0..1 growing with the distance, 1 for the sky and
    //    every pixel no mesh wrote); depthReversed true (the provider asked for it, wants_reversed_depth) with depthInfinite true: near / d (1 at
    //    the near plane, towards 0, 0 for the sky), the depth of an infinite far plane that FSR and the other SDKs read with their "inverted" and
    //    "infinite" flags. cameraNear and cameraFar are the camera's own planes for the SDK's constants (an orthographic camera: -1000 and 1000, the
    //    planes of its matrix, and a nominal field of view).
    //  motion: two channels, in fractions of the picture (u of its width, v of its height, v down), pointing from a pixel to where its surface
    //    was on the frame before (previous - current), without the jitter; motionScaleX / Y turn those values into the units an SDK asks for
    //    (1, 1: they are fractions already; an SDK of pixel units takes renderW and renderH).
    gpu::Image depth{}, motion{};
    bool depthReversed = false, depthInfinite = false;
    float motionScaleX = 1.0f, motionScaleY = 1.0f;
    bool motionJittered = false;  // false: the vectors are of the unjittered picture
    gpu::PixelFormat colorFormat = gpu::PixelFormat::None;
    int renderW = 0, renderH = 0, outW = 0, outH = 0;
    // The camera: the unjittered projection (P00, P11, P02, P12, P03, P13, P32, P33, as TaaPlan::proj), the matrix from a view-space position
    // of this frame to the clip position it had on the frame before, the jitter this frame was drawn with (render pixels, x right, y down), the
    // planes, the vertical field of view (radians), the camera's place (the world position and the right, up and forward axes of its view,
    // viewFromWorld the view matrix itself) and the milliseconds the frame took.
    float proj[8]{};
    Mat4 prevFromView;
    float jitterX = 0, jitterY = 0;
    float cameraNear = 0.1f, cameraFar = 1000.0f, cameraFovY = 1.0f;
    bool cameraPerspective = true;
    Vec3 cameraPosition{0, 0, 0}, cameraRight{1, 0, 0}, cameraUp{0, 1, 0}, cameraForward{0, 0, -1};
    Mat4 viewFromWorld;
    float frameTimeMs = 0;
    // The colour: the pictures are display-referred (the post stack's final pass tonemapped and exposed them: `exposure` is 1, an SDK that wants a
    // pre-exposure gets that). They are display-linear in `colorFormat`; the present pass encodes them for the window as `outputEncode` says
    // (sRGB, scRGB, HDR10 or EDR linear), with `hdrHeadroom` times paper white of room above 1.0 (1: within paper white) and paper white at
    // `paperWhiteNits`.
    float exposure = 1.0f;
    OutputEncode outputEncode = OutputEncode::Sdr;
    float hdrHeadroom = 1.0f, paperWhiteNits = 200.0f;
    std::uint64_t frameId =
        0;  // the game frame (Renderer's postSerial); a number that goes up by one per rendered frame
    // The history is not valid: the first frame, a camera cut (the temporal upscaler's own: a scene change, a floating-origin rebase, a
    // camera that did not draw the frame before), a change of the output size or of the swapchain, a pause that just ended, a frame the
    // provider refused: forget the frame before.
    bool reset = false;
    std::string error;  // set by a provider that returns false
};

// One frame-generation SDK. A provider is a process-wide object that serves the device that started it last (the way VendorUpscaler does).
class FrameGenProvider {
public:
    virtual ~FrameGenProvider() = default;
    virtual std::string_view
    name() const = 0;  // "DLSS frame generation", "FSR 3 frame generation", "XeSS frame generation"
    virtual FrameGenSlot slot() const = 0;  // the slot it fills: Dlss, Fsr or Xess
    virtual std::string_view
    setup_id() const = 0;                   // "streamline", "fidelityfx", "xess": what `factoria setup <id>` installs
    virtual unsigned backends() const = 0;  // the bits (1 << gpu::Backend) it can run on
    // Whether this provider can run on `env`: the backend (vendor_environment_problem), the GPU's maker, the SDK installed (the sentence names
    // `factoria setup <setup_id()>`), the generation hardware. Asked once per renderer, never per frame.
    virtual VendorProbe probe(const VendorEnv& env) = 0;
    // The hook that makes the window's swapchain (or wraps it) and counts the presents; null when the provider needs none. Renderer::init
    // hands it to the device of a renderer that asked for frame generation (RendererDesc::frameGeneration, a window on D3D12 or Vulkan),
    // before that device exists, through gpu::DeviceInit::hooks and nowhere else (framegen_device_hooks): it is never registered for the
    // process, so a renderer that did not ask is not seen by it. The same object serves each such device; it passes everything through once
    // stop() ran. The controller never calls it.
    virtual std::shared_ptr<gpu::DeviceHook> device_hook() { return nullptr; }
    // Makes the SDK's context on `device`'s swapchain; "" or the SDK's reason (the controller then stays off this provider, "fail once").
    virtual std::string start(gpu::Device& device, const FrameGenSwapchain& swapchain) = 0;
    // Whether the depth image is to be the reversed infinite one (near / d) instead of d / (d + 1) (FrameGenFrame::depthReversed).
    virtual bool wants_reversed_depth() const { return false; }
    // Whether the SDK cannot generate without NVIDIA Reflex running (DLSS frame generation reads Reflex's markers of every frame). The
    // renderer then turns Reflex on while this provider runs, whatever the player's latency mode (LatencyController::require_reflex).
    virtual bool requires_reflex() const { return false; }
    // The window's swapchain was made again, resized or lost (width and height 0): what start() was told is out of date. Called on the render
    // thread, between two frames; the next frame carries `reset`. The default does nothing.
    virtual void swapchain_changed(gpu::Device& /*device*/, const FrameGenSwapchain& /*swapchain*/) {}
    // Generation on or off for the frames that follow (the controller turns it off below minBaseFps and when the frame has no motion): off
    // is the SDK asleep, the swapchain presents the rendered frames only.
    virtual void configure(bool enabled) = 0;
    // One rendered frame: false (and frame.error) when this frame cannot be generated from; the controller then reports the error and the
    // next frame carries `reset`.
    virtual bool dispatch(FrameGenFrame& frame) = 0;
    // The frames the SDK has generated since start() (it reads its own counter); 0 when it reports none. Never blocks.
    virtual std::uint64_t generated_frames() { return 0; }
    // The reason this provider stays off for the rest of the run after the SDK failed while running (a frame it could not tag, a present it
    // could not generate): "" while it has not. The controller reads it after a refused frame and when it answers provider_reason; the
    // provider logs it once itself. The default is "never fails after start".
    virtual std::string failure() const { return {}; }
    // Gives back what start() made on `device`, before the device or the swapchain goes or the mode changes. It must tolerate a device
    // that was lost.
    virtual void stop(gpu::Device& device) = 0;
};

// The provider of `slot` (Dlss, Fsr, Xess), or null when none is there: the slots of the packages that have not landed.
FrameGenProvider* framegen_provider(FrameGenSlot slot);
void set_framegen_provider_for_test(FrameGenSlot slot, FrameGenProvider* fake);  // null puts the registered one back
// Fills the slot of provider->slot() (the DLSS-G, FSR 3 and XeSS packages call this once each, and nothing else changes).
void register_framegen_provider(std::shared_ptr<FrameGenProvider> provider);
// Empties the registered slot of `slot` (a test that registered a provider puts the slot back to what the build has: none).
void clear_registered_framegen_provider_for_test(FrameGenSlot slot);

// The reason an empty slot gives: it names what fills it.
const char* framegen_absent_reason(FrameGenSlot slot);
// The backends (bits of 1 << gpu::Backend) a slot's SDK can run on, whether or not a provider is registered: DLSS-G and FSR 3 on D3D12 and
// Vulkan, XeSS on D3D12 (render.supports lists them).
unsigned framegen_slot_backends(FrameGenSlot slot);
// The `factoria setup` id of a slot's SDK ("streamline", "fidelityfx", "xess").
const char* framegen_slot_setup_id(FrameGenSlot slot);
// The sentence of a provider refused by `env`'s backend or system ("" when none refuses it): what a provider's probe starts with.
std::string framegen_environment_problem(const FrameGenProvider& provider, const VendorEnv& env);

// The device hook of every provider that has one, each once (Renderer::init puts them in DeviceInit::hooks of the device it is about to make,
// when frame generation is on and the device has a window of D3D12 or Vulkan). Nothing is registered process-wide: a device made without
// them, by this or another renderer, calls none of them.
std::vector<std::shared_ptr<gpu::DeviceHook>> framegen_device_hooks();

// ---- the passes of the output ------------------------------------------------------------------------------------------------------

// What the output stage of a frame adds for generation (renderer_draw.cpp, finish_output). `dispatch`: the provider gets this frame. `copyHudless`:
// the picture is copied before the screen-space items are drawn over it, because they are drawn into the same image. Without items the
// picture is its own hudless one. With the colour filter on, the copy is drawn through the same filter as the picture shown (both images the
// provider gets are graded alike, `presented` is the filtered image the swapchain shows), and the dispatch comes after the filter pass.
struct FrameGenPassPlan {
    bool dispatch = false;
    bool copyHudless = false;
};
FrameGenPassPlan plan_framegen_passes(bool dispatchWanted, bool hudOverUpscale);

inline constexpr const char* kPassUpscale = "upscale";
inline constexpr const char* kPassFrameGenHudless = "framegen-hudless";
inline constexpr const char* kPassHudOverUpscale = "hud-over-upscale";
inline constexpr const char* kPassFrameGen = "framegen";
inline constexpr const char* kPassOutputColorFilter = "output-color-filter";
// The passes finish_output adds, in the order they run (RendererTestAccess::output_passes reads what a frame ran): upscale,
// [framegen-hudless], [hud-over-upscale], [output-color-filter], [framegen]. The hudless copy is before the screen-space items; the dispatch
// after them and after the colour filter.

// ---- the controller ---------------------------------------------------------------------------------------------------------------

enum class FrameGenState : std::int32_t {
    Off,      // the mode is off
    Refused,  // the mode is on but nothing can run (missing provider, setup, backend, GPU, the temporal upscaler ...): `reason` says what
    Measuring,  // a provider is ready and the frame rate has not been measured over a full window yet
    Paused,     // the base frame rate is below minBaseFps: generation is off until it recovers
    Active      // generation is on
};
std::string_view frame_gen_state_name(FrameGenState s);

// What the profiler shows.
struct FrameGenReport {
    FrameGenSlot provider = FrameGenSlot::None;  // the provider started (None when off or refused)
    FrameGenState state = FrameGenState::Off;
    bool generating = false;
    double baseFps = 0;                 // frames the game renders per second over the last window (0 until measured)
    double presentedFps = 0;            // the same plus the frames the SDK generated in that window
    std::uint64_t renderedFrames = 0;   // since the controller started or was reset
    std::uint64_t generatedFrames = 0;  // the SDK's, since the same
    std::string reason;                 // why nothing runs, or why generation is paused; "" while active
};

class FrameGenController {
public:
    // The frame rate window: the intervals of the last kWindowFrames rendered frames. kMinDwellFrames: frames between two switches of
    // generation, so a rate that hovers at the limit does not flap. kResumeMargin: after the rate paused generation, it must reach
    // minBaseFps * kResumeMargin to resume.
    static constexpr int kWindowFrames = 30;
    static constexpr int kMinDwellFrames = 90;
    static constexpr double kResumeMargin = 1.1;

    // The device the controller serves (null = none, every call below does nothing), the probe environment, the window's swapchain and whether
    // the device was made with the providers' hooks (Renderer::init: RendererDesc::frameGeneration).
    void attach(gpu::Device* device, const VendorEnv& env, const FrameGenSwapchain& swapchain, bool hooked);
    // Stops the provider that runs and forgets the device (a lost device too: stop() tolerates it).
    void detach();
    bool attached() const { return device_ != nullptr; }

    // The setting. Decides the provider (effective_frame_generation on caps()), starts it (or stops the previous one) and applies generation.
    void set_settings(const FrameGenSettings& s);
    const FrameGenSettings& settings() const { return settings_; }
    // What the frame can give the provider, decided by render() before the cameras are built: `upscaleStage` the upscale stage runs, `temporal`
    // the frame is jittered and has a depth and a motion (a temporal frame). Either missing refuses generation for that frame, with the reason.
    void set_inputs(bool upscaleStage, bool temporal);

    // What the machine can run, asking each provider once; the slot of the mode that runs (None when off or refused).
    FrameGenCaps caps();
    std::string provider_reason(FrameGenSlot slot);  // "" when `slot`'s provider is usable here, else why not
    void reset_probes();                             // the device changed: the answers are asked again
    FrameGenSlot provider() const { return running_ ? runningSlot_ : FrameGenSlot::None; }

    // One rendered frame of the game, at `nowMs` (the engine clock: Renderer passes latency_clock().now_ms()): measures the base rate and
    // decides whether generation is on. A camera cut is not told here: the frame itself says it (FrameGenFrame::reset, the temporal upscaler's
    // history), and so does a change of the output size (dispatch compares it with the last frame's).
    void begin_frame(double nowMs);
    // The window's swapchain was made again, resized or lost (width and height 0): the provider is told (swapchain_changed) and the next frame
    // carries `reset`. The same size again does nothing.
    void set_swapchain(const FrameGenSwapchain& swapchain);
    // True while the provider is to be given this frame (started, nothing refuses, the rate allows).
    bool wants_dispatch() const { return running_ && generating_ && refusal_.empty(); }
    // Whether the started provider asks for the reversed infinite depth (FrameGenProvider::wants_reversed_depth).
    bool wants_reversed_depth() const { return running_ && running_->wants_reversed_depth(); }
    // Whether the started provider needs NVIDIA Reflex on (FrameGenProvider::requires_reflex): false while none runs.
    bool requires_reflex() const { return running_ && running_->requires_reflex(); }
    // Hands the frame to the provider (when wants_dispatch()); false when the provider refused it (its reason is then the report's).
    bool dispatch(FrameGenFrame& frame);
    // A frame the renderer could not hand over (the depth and motion images could not be made): the report says why, the next frame resets.
    void note_skipped(const std::string& why);

    FrameGenState state() const;
    FrameGenReport report();
    // The reason nothing runs or generation is paused ("" when it runs or the mode is off).
    std::string reason() const;
    void reset_stats();

private:
    struct Slot {
        bool probed = false;
        VendorProbe probe;
        bool failed = false;  // start() failed: stay off this provider
        std::string failure;
    };
    Slot& slot(FrameGenSlot s);
    void stop_provider();
    void apply();  // decides provider and refusal from the settings, the inputs and the probes
    void set_generating(bool on);

    gpu::Device* device_ = nullptr;
    VendorEnv env_{};
    FrameGenSwapchain swapchain_{};
    bool hooked_ = false;
    FrameGenSettings settings_{};
    bool upscaleStage_ = true, temporal_ = true;  // the inputs (true until render() says otherwise)
    FrameGenProvider* running_ = nullptr;         // the provider started on device_
    FrameGenSlot runningSlot_ = FrameGenSlot::None;
    std::string refusal_;  // why nothing can run ("" when something can)
    Slot slots_[3];        // dlss, fsr, xess

    bool generating_ = false;
    bool pausedByRate_ = false;  // generation went off for the frame rate (the resume needs the margin)
    bool resetNext_ = true;      // the next dispatched frame carries `reset`
    int sinceSwitch_ = kMinDwellFrames;
    // The window: timestamps (ms) and the SDK's generated count at each rendered frame; kWindowFrames + 1 of them make kWindowFrames intervals.
    double stamps_[kWindowFrames + 1]{};
    std::uint64_t generated_[kWindowFrames + 1]{};
    int count_ = 0, head_ = 0;
    double baseFps_ = 0, presentedFps_ = 0;
    std::uint64_t rendered_ = 0;
    std::uint64_t generatedBase_ = 0;      // generatedNow_ when the stats were reset
    std::uint64_t generatedNow_ = 0;       // the frames the SDK generated over all its starts
    std::uint64_t lastProviderCount_ = 0;  // the SDK's own counter at the last frame
    std::string dispatchError_;            // the last frame the provider refused
    int lastOutW_ = 0, lastOutH_ = 0;      // the output size of the last frame handed over (a change resets)
};

}  // namespace fa::render
