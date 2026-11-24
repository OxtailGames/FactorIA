// MetalFX (M76.3): Apple's own spatial and temporal upscalers behind one small wrapper. Private to fa_render.
//
// MetalFX is an OS framework (macOS 13+, iOS 16+, a real GPU: not the iOS simulator, not the OpenGL backend). It is loaded at run time
// (NSBundle), so a player built with it still starts on an OS without it, and `support()` says why a scaler is not there. Every
// platform that is not Metal builds the stubs of metalfx.cpp: `support()` answers "no" with the reason, `Scaler::configure` fails.
//
// ORDER IN THE FRAME. A Scaler encodes into its own MTLCommandBuffer, because the frame's one is the device's (the passes record into it
// and the frame's commit submits it). `Scaler::encode` therefore SPLITS the frame, through gpu::Device::native_metal() (gpu/device.h,
// MetalNative): the device's buffer with the passes so far (they write the scene colour; MetalNative::current_command_buffer() hands it
// out) signals a shared event and is committed with MetalNative::split_commit(), the MetalFX buffer waits for that event, runs and signals
// a second one, and the device's buffer of the passes after it (HUD, present) is taken at once, right after the MetalFX commit, and waits
// for the second event. So the upscaler reads this frame's colour and the later passes read this frame's output, ordered on the GPU and
// without a wait of the CPU's own. Cost: one more commit (one more command buffer) per frame and one command buffer of the scaler.
// docs/design/ARCHITECTURE_RENDERING_POST.md, "MetalFX (M76)".
// After `encode` that later buffer is OPEN and not committed. Anything that reads back through a command buffer of its own
// (Device::read_image_rgba8, read_image_rgba16f) MUST commit first: its buffer is queued behind the open one and would wait for it for ever.
// Gpu::committed() still says false after the split (the renderer's own note of "this frame was submitted" is made at the end of the
// frame), so the renderer calls Gpu::note_work() after `encode` and a read back that asks Gpu::committed() commits for itself.
//
// No MetalFX on the machine that runs the CI (a VM with a paravirtual GPU): the tests that need a scaler say so with a MESSAGE and
// return, they never pass silently (the skip is in the test output and in the doctest report as a message).
#pragma once

#include <memory>
#include <string>

#include "gpu/device.h"
#include "gpu/types.h"

namespace fa::render::metalfx {

enum class Kind {
    Spatial,   // one image in, one larger image out; no history, no motion
    Temporal,  // jittered colour + depth + motion vectors, with its own history
};

// How the colour in the input is encoded (the spatial scaler's colorProcessingMode; the temporal one reads linear light in HDR).
enum class ColorSpace {
    Perceptual,  // 0..1, display encoded (sRGB-like)
    Linear,      // 0..1, linear light
    Hdr,         // linear light above 1
};

// What this device and OS can do, and why when something is missing.
struct Support {
    bool spatial = false;
    bool temporal = false;
    // Empty when both are available. Else a sentence that says what is missing and what to do ("needs macOS 13 or iOS 16",
    // "the iOS simulator has no MetalFX", "this build draws with OpenGL"). Also set when only one scaler is there: it names the other.
    std::string reason;
};
// True when `device` draws with Metal (macOS, iOS or the iOS simulator).
inline bool on_metal(const gpu::Device& device) { return device.backend() == gpu::Backend::Metal; }
// What the GPU `metalDevice` (the id<MTLDevice> of gpu::Device::native().device; null = none yet) can do. Cheap (a class lookup and two
// device questions); call it once graphics is up (the Metal device exists).
Support support(const void* metalDevice);
// What the system's default Metal GPU can do, asked without a renderer or a sokol device (a headless run reports what a GPU here would
// draw: Engine::upscaler_caps). The same answer as support() on a window drawn on that GPU; none on every backend that is not Metal.
Support support_default_device();

struct Desc {
    Kind kind = Kind::Spatial;
    int inputWidth = 0, inputHeight = 0;    // the render resolution
    int outputWidth = 0, outputHeight = 0;  // the display resolution; at least the input's
    gpu::PixelFormat colorFormat = gpu::PixelFormat::Rgba16F;
    gpu::PixelFormat outputFormat = gpu::PixelFormat::Rgba16F;
    ColorSpace colorSpace = ColorSpace::Linear;  // spatial only
    // Temporal only: the depth image (R32F, or a 32-bit float depth) and the motion image (RG16F or RG32F) are the same size as
    // the colour.
    gpu::PixelFormat depthFormat = gpu::PixelFormat::R32F;
    gpu::PixelFormat motionFormat = gpu::PixelFormat::Rg16F;
    bool autoExposure = false;   // temporal: MetalFX measures the exposure itself (else Frame::preExposure is used)
    bool depthReversed = false;  // temporal: 1 is near
    // Temporal: the scaler takes a reactive mask (an R8 image of the input's size: 0 = MetalFX's own judgement, 1 = ignore the history here)
    // through Frame::reactive. MetalFX knows the mask from macOS 14.4 and iOS 17.4: on an older OS the scaler is made without it and
    // Scaler::reactive_mask() says false (the pictures are what they were before the mask). The descriptor has to say so when the scaler
    // is made and cannot change afterwards, so a caller that may have a mask in some frames asks for it from the start: a frame without
    // one hands none and draws as a scaler made without the mask (tested), whereas making the scaler again when the first mask appears
    // would cost its synchronous start-up and drop the history in the very frame a particle shows up.
    bool reactiveMask = false;
    bool operator==(const Desc&) const = default;
};

// One frame's images. All are gpu::Image of the sizes and formats of the Desc; `color`, `depth` and `motion` need only to be sampled
// (any image). `output` is written by MetalFX, so it is made with usage.color_attachment AND usage.storage_image (the spatial scaler
// needs the first, the temporal one both: MTLTextureUsageRenderTarget | ShaderWrite), and the passes that follow read it through an
// ordinary texture view of the same image (compute.cpp makes that kind of image).
struct Frame {
    gpu::Image color{};
    gpu::Image output{};
    gpu::Image depth{};   // temporal only
    gpu::Image motion{};  // temporal only
    // Temporal, optional: the reactive mask of this frame (an R8 image of the input's size, read as sampled). Handed to MetalFX only when
    // the scaler has one (Desc::reactiveMask, `reactive_mask()`); else ignored. Invalid: this frame has none. A mask of another size or
    // format is refused like any other image.
    gpu::Image reactive{};
    // Temporal: the sub-pixel shift the picture was drawn with, in render pixels: how far the drawn picture is moved, right and DOWN
    // the image (a scene sampled at (x + jx, y + jy) is moved by (-jx, -jy), so those are -jx, -jy). Measured by the tests: the
    // opposite sign converges to a worse picture.
    float jitterX = 0.0f, jitterY = 0.0f;
    // Temporal: what multiplies a value of the motion image to give render pixels, and the sign MetalFX wants (the motion points
    // from the pixel to where it was).
    float motionScaleX = 1.0f, motionScaleY = 1.0f;
    float preExposure = 1.0f;  // temporal, without autoExposure: the exposure the colour was drawn with
    bool reset = false;        // temporal: forget the history (a camera cut, the first frame, a resize)
};

class Scaler {
public:
    Scaler();
    ~Scaler();
    Scaler(const Scaler&) = delete;
    Scaler& operator=(const Scaler&) = delete;

    // Makes the scaler for `desc`, or keeps the one made for the same desc; a change of kind, size or format makes a new one (and the
    // temporal history starts again: the next encode resets). False with `error` (the reason and what to do) when MetalFX is not
    // available here or refuses the sizes (or `device` is not a Metal device). Call it outside a pass.
    bool configure(gpu::Device& device, const Desc& desc, std::string* error);
    // Upscales `frame` now, in order with the passes of `device` around it (see the top of the file). Call it OUTSIDE a pass, after the
    // pass that drew `color` ended and before the first pass that reads `output`. It commits the frame so far (MetalNative::split_commit):
    // Gpu counts that commit through its listener; do not call Gpu::note_commit for it (the frame still has passes to come). The buffer
    // of those passes is taken and left open (it waits for the scaler on the GPU): anything that reads back through a command
    // buffer of its own (Device::read_image_rgba8) must commit first or waits behind it for ever; Gpu::note_work() says so to the renderer.
    // Checks the images against the desc BEFORE it commits anything: false with `error` and no work done when an image is missing, of
    // another size or format, or MetalFX could not write the output.
    bool encode(gpu::Device& device, const Frame& frame, std::string* error);

    bool valid() const;
    const Desc& desc() const;
    // How many scalers were made: configure with a changed desc raises it by one, with the same desc leaves it.
    int generation() const;
    // The frames encoded since configure (the first one resets the temporal history).
    int encoded() const;
    // True once a command buffer of this scaler finished with an error (MetalFX or the GPU refused it; the completion handler runs on
    // another thread, so the answer comes a frame or two after the encode), with the error text in `why`. The scaler keeps drawing nothing
    // useful then: the caller gives MetalFX up. A new scaler (configure with another desc, release) starts clear.
    bool command_failed(std::string* why) const;
    void release();

    // True when the scaler was made with a reactive mask input (Desc::reactiveMask on an OS that has it).
    bool reactive_mask() const;
    // The frames encoded since configure that handed a reactive mask to MetalFX.
    int reactive_encoded() const;

    // Tests only. `emptyBuffers`: the next configure makes a scaler that draws nothing (MetalFX is not asked for one, so it works on a Metal
    // GPU without MetalFX): the frames are checked, ordered with the events and handed to command buffers that hold no MetalFX work, the
    // output is not written. `failBuffers`: the command buffer of every encode ends as a failed one would: its completion handler reports
    // an error and the buffer does not signal the event itself, so only the handler can release the passes that wait for it. Set before
    // configure; they stay across configure and release.
    struct TestHooks {
        bool emptyBuffers = false;
        bool failBuffers = false;
    };
    void set_test_hooks(const TestHooks& hooks);
    // Waits up to `timeoutMs` for the GPU to signal the event of the last encode (the one the passes after the scaler wait for). False
    // when it did not (a buffer that never released it): the event is then raised here so the queue goes on, and the caller fails.
    bool test_wait_signalled(int timeoutMs);

private:
    struct Impl;
    std::unique_ptr<Impl> impl_;
};

}  // namespace fa::render::metalfx
