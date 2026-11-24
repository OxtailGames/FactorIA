// MetalFX (M76.3): Apple's own spatial and temporal upscalers behind one small wrapper. Private to fa_render.
//
// MetalFX is an OS framework (macOS 13+, iOS 16+, a real GPU: not the iOS simulator, not the OpenGL backend). It is loaded at run time
// (NSBundle), so a player built with it still starts on an OS without it, and `support()` says why a scaler is not there. Every
// platform that is not Metal builds the stubs of metalfx.cpp: `support()` answers "no" with the reason, `Scaler::configure` fails.
//
// ORDER IN THE FRAME. A Scaler encodes into its own MTLCommandBuffer, because sokol does not hand out the frame's one (it makes it at
// the frame's first pass and commits it in sg_commit). `Scaler::encode` therefore SPLITS the frame: it calls sg_commit() (the sokol
// passes recorded so far, which write the scene colour, are submitted), commits the MetalFX buffer on the same queue behind them, and
// the passes recorded after it (HUD, present) start a new sokol command buffer that the queue runs behind the MetalFX one. The queue
// is in-order, so the upscaler reads this frame's colour and the later passes read this frame's output. Cost: one more sg_commit
// per frame (one more command buffer) and one command buffer of the scaler. docs/design/ARCHITECTURE_RENDERING_POST.md, "MetalFX (M76)".
// After the split Gpu::committed() still says false (the renderer's own note of "this frame was submitted" is made at the end of the
// frame, not by the commit of encode): a read-back that follows commits once more, which is harmless (an empty commit).
//
// No MetalFX on the machine that runs the CI (a VM with a paravirtual GPU): the tests that need a scaler say so with a MESSAGE and
// return, they never pass silently (the skip is in the test output and in the doctest report as a message).
#pragma once

#include <memory>
#include <string>

#include "sokol_gfx.h"

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
// True when the open sokol context draws with Metal (macOS, iOS or the iOS simulator). Needs sg_isvalid().
inline bool on_metal() {
    const sg_backend b = sg_query_backend();
    return b == SG_BACKEND_METAL_MACOS || b == SG_BACKEND_METAL_IOS || b == SG_BACKEND_METAL_SIMULATOR;
}
// Cheap (a class lookup and two device questions); call it once graphics is up (the Metal device exists).
Support support();
// What the system's default Metal GPU can do, asked without a renderer or a sokol device (a headless run reports what a GPU here would
// draw: Engine::upscaler_caps). The same answer as support() on a window drawn on that GPU; none on every backend that is not Metal.
Support support_default_device();

struct Desc {
    Kind kind = Kind::Spatial;
    int inputWidth = 0, inputHeight = 0;    // the render resolution
    int outputWidth = 0, outputHeight = 0;  // the display resolution; at least the input's
    sg_pixel_format colorFormat = SG_PIXELFORMAT_RGBA16F;
    sg_pixel_format outputFormat = SG_PIXELFORMAT_RGBA16F;
    ColorSpace colorSpace = ColorSpace::Linear;  // spatial only
    // Temporal only: the depth image (R32F, or a 32-bit float depth) and the motion image (RG16F or RG32F) are the same size as
    // the colour.
    sg_pixel_format depthFormat = SG_PIXELFORMAT_R32F;
    sg_pixel_format motionFormat = SG_PIXELFORMAT_RG16F;
    bool autoExposure = false;   // temporal: MetalFX measures the exposure itself (else Frame::preExposure is used)
    bool depthReversed = false;  // temporal: 1 is near
    bool operator==(const Desc&) const = default;
};

// One frame's images. All are sokol images of the sizes and formats of the Desc; `color`, `depth` and `motion` need only to be sampled
// (any image). `output` is written by MetalFX, so it is made with usage.color_attachment AND usage.storage_image (the spatial scaler
// needs the first, the temporal one both: MTLTextureUsageRenderTarget | ShaderWrite), and the passes that follow read it through an
// ordinary texture view of the same image (compute.cpp makes that kind of image).
struct Frame {
    sg_image color{};
    sg_image output{};
    sg_image depth{};   // temporal only
    sg_image motion{};  // temporal only
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
    // available here or refuses the sizes. Call it outside a pass.
    bool configure(const Desc& desc, std::string* error);
    // Upscales `frame` now, in order with the sokol passes around it (see the top of the file). Call it OUTSIDE a pass, after the
    // pass that drew `color` ended and before the first pass that reads `output`. It commits the sokol frame so far (sg_commit):
    // Gpu counts that commit through its listener; do not call Gpu::note_commit for it (the frame still has passes to come). Checks the images against the desc BEFORE it commits anything:
    // false with `error` and no work done when an image is missing, of another size or format, or MetalFX could not write the output.
    bool encode(const Frame& frame, std::string* error);

    bool valid() const;
    const Desc& desc() const;
    // How many scalers were made: configure with a changed desc raises it by one, with the same desc leaves it.
    int generation() const;
    // The frames encoded since configure (the first one resets the temporal history).
    int encoded() const;
    void release();

private:
    struct Impl;
    std::unique_ptr<Impl> impl_;
};

}  // namespace fa::render::metalfx
