// MetalFX (metalfx.h) on the Metal backend: MTLFXSpatialScaler and MTLFXTemporalScaler over sokol images.
// The framework is loaded at run time and its classes are looked up by name, so nothing links against it: the player starts on an OS
// without MetalFX (the Metal device is asked, the answer is "not here" with the reason) and an SDK without its headers builds the
// "unavailable" answer. Frame order: see metalfx.h; the cost is the sg_commit() in Scaler::encode.
#include "metalfx.h"

#if defined(SOKOL_METAL)

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#if __has_include(<MetalFX/MetalFX.h>)
#import <MetalFX/MetalFX.h>
#define FA_HAVE_METALFX_SDK 1
#endif
#include <TargetConditionals.h>

#include <atomic>
#include <format>
#include <memory>
#include <mutex>

// engine/platform/src/sokol_impl_apple.m: sokol's command buffer for the passes recorded from now on (it makes one when there is none yet).
// sokol hands out only the encoder of a pass, and the event waits below belong to a command buffer.
extern "C" const void* fa_sg_mtl_command_buffer(void);

namespace fa::render::metalfx {

namespace {

struct FormatInfo {
    sg_pixel_format sg;
    MTLPixelFormat mtl;
    const char* name;
};
// The formats a MetalFX image can have here (the rest of sokol's list is not something a scene, a depth or a motion image is).
constexpr FormatInfo kFormats[] = {
    {SG_PIXELFORMAT_RGBA8, MTLPixelFormatRGBA8Unorm, "rgba8"},
    {SG_PIXELFORMAT_BGRA8, MTLPixelFormatBGRA8Unorm, "bgra8"},
    {SG_PIXELFORMAT_RGBA16F, MTLPixelFormatRGBA16Float, "rgba16f"},
    {SG_PIXELFORMAT_RG16F, MTLPixelFormatRG16Float, "rg16f"},
    {SG_PIXELFORMAT_RG32F, MTLPixelFormatRG32Float, "rg32f"},
    {SG_PIXELFORMAT_R32F, MTLPixelFormatR32Float, "r32f"},
    {SG_PIXELFORMAT_R16F, MTLPixelFormatR16Float, "r16f"},
    {SG_PIXELFORMAT_RGB10A2, MTLPixelFormatRGB10A2Unorm, "rgb10a2"},
    {SG_PIXELFORMAT_DEPTH, MTLPixelFormatDepth32Float, "depth32f"},
};

const FormatInfo* format_info(sg_pixel_format f) {
    for (const FormatInfo& i : kFormats)
        if (i.sg == f) return &i;
    return nullptr;
}

[[maybe_unused]] const char* mtl_format_name(MTLPixelFormat f) {
    for (const FormatInfo& i : kFormats)
        if (i.mtl == f) return i.name;
    return "another format";
}

std::string formats_list() {
    std::string s;
    for (const FormatInfo& i : kFormats) {
        if (!s.empty()) s += ", ";
        s += i.name;
    }
    return s;
}

[[maybe_unused]] std::string os_version() {
    NSString* v = [[NSProcessInfo processInfo] operatingSystemVersionString];
    return v ? std::string([v UTF8String]) : std::string("this OS version");
}

// MetalFX is a system framework; this loads it (a no-op when it is loaded) and says whether it is there.
[[maybe_unused]] bool framework_loaded() {
    if (NSClassFromString(@"MTLFXSpatialScalerDescriptor") != nil) return true;
    NSBundle* bundle = [NSBundle bundleWithPath:@"/System/Library/Frameworks/MetalFX.framework"];
    if (bundle == nil || ![bundle load]) return false;
    return NSClassFromString(@"MTLFXSpatialScalerDescriptor") != nil;
}

[[maybe_unused]] id<MTLDevice> metal_device() { return (__bridge id<MTLDevice>)sg_mtl_device(); }

[[maybe_unused]] id<MTLTexture> texture_of(sg_image image) {
    if (image.id == SG_INVALID_ID || sg_query_image_state(image) != SG_RESOURCESTATE_VALID) return nil;
    const sg_mtl_image_info info = sg_mtl_query_image_info(image);
    return (__bridge id<MTLTexture>)info.tex[info.active_slot];
}

// "" when MetalFX can be used for `kind` on `device`; else why not and what to do. `spatialOk` and `temporalOk` say what the device can do
// (both false when MetalFX is not there at all).
std::string unavailable(Kind kind, id<MTLDevice> device, bool* spatialOk, bool* temporalOk) {
    *spatialOk = *temporalOk = false;
#if !defined(FA_HAVE_METALFX_SDK)
    (void)kind;
    (void)device;
    return "this build was made with an SDK that has no MetalFX (Xcode 14 or later has it): build with a newer Xcode to use the "
           "MetalFX upscaler";
#else
    if (device == nil)
        return "MetalFX was asked before the graphics device exists: call it after the renderer is initialised";
#if TARGET_OS_SIMULATOR
    // Said before the framework is loaded: the simulator's GPU never has it, whatever the OS.
    return "the iOS simulator has no MetalFX (it needs a real Apple GPU): test on a device, or use the engine's own spatial or "
           "temporal upscaler";
#else
    if (@available(macOS 13.0, iOS 16.0, *)) {
        if (!framework_loaded())
            return std::format("MetalFX is not on this system ({}): it comes with macOS 13 and iOS 16; update the OS or use the "
                               "engine's own spatial or temporal upscaler",
                               os_version());
        Class sc = NSClassFromString(@"MTLFXSpatialScalerDescriptor");
        Class tc = NSClassFromString(@"MTLFXTemporalScalerDescriptor");
        *spatialOk = sc != nil && [sc supportsDevice:device];
        *temporalOk = tc != nil && [tc supportsDevice:device];
        if ((kind == Kind::Spatial && *spatialOk) || (kind == Kind::Temporal && *temporalOk)) return {};
        return std::format("the GPU \"{}\" does not support the {} MetalFX scaler (it needs an Apple silicon GPU, a recent AMD GPU or an "
                           "Intel Mac with a supported GPU): use the engine's own spatial or temporal upscaler",
                           std::string([[device name] UTF8String]), kind == Kind::Spatial ? "spatial" : "temporal");
    }
    return std::format("MetalFX needs macOS 13 or iOS 16 or later, this is {}: update the OS or use the engine's own spatial or "
                       "temporal upscaler",
                       os_version());
#endif
#endif
}

std::string size_text(int w, int h) { return std::format("{}x{}", w, h); }

// What `device` can do, with the reason of what it cannot (a spatial scaler without a temporal one says so).
Support support_of(id<MTLDevice> device) {
    Support s;
    bool spatialOk = false, temporalOk = false;
    @autoreleasepool {
        s.reason = unavailable(Kind::Spatial, device, &spatialOk, &temporalOk);
        if (s.reason.empty() && !temporalOk) s.reason = unavailable(Kind::Temporal, device, &spatialOk, &temporalOk);
    }
    s.spatial = spatialOk;
    s.temporal = temporalOk;
    if (s.spatial && s.temporal) s.reason.clear();
    return s;
}

}  // namespace

// What the completion handler of a command buffer (Metal's thread) tells the renderer's thread. Shared with every block in flight, so the
// scaler can be gone when a buffer finishes.
struct CommandStatus {
    std::atomic<bool> failed{false};
    std::mutex mutex;  // guards `why` and the one store of `failed`
    std::string why;
};

struct Scaler::Impl {
    std::shared_ptr<CommandStatus> status;  // made by the first encode (a scaler that never encodes allocates none)
    Desc desc;
    bool valid = false;
    int generation = 0;
    int encoded = 0;
    // The order between the passes that draw the inputs, MetalFX and the passes that read its output (Scaler::encode). Values only grow.
    id<MTLSharedEvent> event = nil;
    uint64_t eventValue = 0;
    // id<MTLFXSpatialScaler> / id<MTLFXTemporalScaler>: typed `id` so that the members need no availability guard.
    id spatial = nil;
    id temporal = nil;
};

Support support() { return support_of(metal_device()); }

Support support_default_device() {
    Support s;
    @autoreleasepool {
#if defined(FA_HAVE_METALFX_SDK)
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        s = support_of(device);
        if (device == nil) s.reason = "this Mac has no Metal GPU: use the engine's own spatial or temporal upscaler";
#else
        s = support_of(nil);
#endif
    }
    return s;
}

Scaler::Scaler() : impl_(std::make_unique<Impl>()) {}
Scaler::~Scaler() { release(); }

void Scaler::release() {
    impl_->status.reset();  // a buffer still in flight reports to the old one (it holds its own reference); the next encode makes a new one
    impl_->event = nil;     // the buffers in flight keep it alive
    impl_->eventValue = 0;
    impl_->spatial = nil;
    impl_->temporal = nil;
    impl_->valid = false;
    impl_->encoded = 0;
    impl_->desc = Desc{};
}

bool Scaler::valid() const { return impl_->valid; }
const Desc& Scaler::desc() const { return impl_->desc; }
int Scaler::generation() const { return impl_->generation; }
int Scaler::encoded() const { return impl_->encoded; }

bool Scaler::command_failed(std::string* why) const {
    if (!impl_->status) return false;
    CommandStatus& st = *impl_->status;
    if (!st.failed.load(std::memory_order_acquire)) return false;
    if (why) {
        std::lock_guard<std::mutex> lock(st.mutex);
        *why = st.why;
    }
    return true;
}

bool Scaler::configure(const Desc& desc, std::string* error) {
    if (impl_->valid && impl_->desc == desc) return true;
    release();
    auto fail = [&](std::string message) {
        if (error) *error = std::move(message);
        return false;
    };
    // The contradictions first, before MetalFX is asked anything.
    if (desc.inputWidth < 1 || desc.inputHeight < 1 || desc.outputWidth < 1 || desc.outputHeight < 1)
        return fail(std::format("metalfx: the sizes must be at least 1x1 (input {}, output {})",
                                size_text(desc.inputWidth, desc.inputHeight), size_text(desc.outputWidth, desc.outputHeight)));
    if (desc.outputWidth < desc.inputWidth || desc.outputHeight < desc.inputHeight)
        return fail(std::format("metalfx: the output {} is smaller than the input {}: an upscaler makes the image larger; draw it "
                                "straight at the output size",
                                size_text(desc.outputWidth, desc.outputHeight), size_text(desc.inputWidth, desc.inputHeight)));
    const FormatInfo* color = format_info(desc.colorFormat);
    const FormatInfo* output = format_info(desc.outputFormat);
    if (!color || !output)
        return fail(std::string("metalfx: the colour and output formats must be one of ") + formats_list());
    const FormatInfo* depth = nullptr;
    const FormatInfo* motion = nullptr;
    if (desc.kind == Kind::Temporal) {
        depth = format_info(desc.depthFormat);
        motion = format_info(desc.motionFormat);
        if (!depth || !motion)
            return fail(std::string("metalfx: the depth and motion formats must be one of ") + formats_list());
    }
    bool spatialOk = false, temporalOk = false;
    std::string why;
    @autoreleasepool {
        why = unavailable(desc.kind, metal_device(), &spatialOk, &temporalOk);
    }
    if (!why.empty()) return fail("metalfx: " + why);
#if defined(FA_HAVE_METALFX_SDK)
    bool made = false;
    std::string refusal;
    if (@available(macOS 13.0, iOS 16.0, *)) {
        @autoreleasepool {
            id<MTLDevice> device = metal_device();
            if (desc.kind == Kind::Spatial) {
                MTLFXSpatialScalerDescriptor* d = [[NSClassFromString(@"MTLFXSpatialScalerDescriptor") alloc] init];
                d.colorTextureFormat = color->mtl;
                d.outputTextureFormat = output->mtl;
                d.inputWidth = NSUInteger(desc.inputWidth);
                d.inputHeight = NSUInteger(desc.inputHeight);
                d.outputWidth = NSUInteger(desc.outputWidth);
                d.outputHeight = NSUInteger(desc.outputHeight);
                d.colorProcessingMode = desc.colorSpace == ColorSpace::Perceptual ? MTLFXSpatialScalerColorProcessingModePerceptual
                                        : desc.colorSpace == ColorSpace::Linear   ? MTLFXSpatialScalerColorProcessingModeLinear
                                                                                  : MTLFXSpatialScalerColorProcessingModeHDR;
                impl_->spatial = [d newSpatialScalerWithDevice:device];
                made = impl_->spatial != nil;
            } else {
                MTLFXTemporalScalerDescriptor* d = [[NSClassFromString(@"MTLFXTemporalScalerDescriptor") alloc] init];
                d.colorTextureFormat = color->mtl;
                d.depthTextureFormat = depth->mtl;
                d.motionTextureFormat = motion->mtl;
                d.outputTextureFormat = output->mtl;
                d.inputWidth = NSUInteger(desc.inputWidth);
                d.inputHeight = NSUInteger(desc.inputHeight);
                d.outputWidth = NSUInteger(desc.outputWidth);
                d.outputHeight = NSUInteger(desc.outputHeight);
                d.autoExposureEnabled = desc.autoExposure ? YES : NO;
                // The scaler is ready for the first frame it is asked to draw (else MetalFX finishes its set-up on another thread
                // and the first frames are unscaled): the cost is a hitch when it is made, at start and at a resize.
                d.requiresSynchronousInitialization = YES;
                impl_->temporal = [d newTemporalScalerWithDevice:device];
                made = impl_->temporal != nil;
            }
        }
    }
    if (!made)
        return fail(std::format("metalfx: MetalFX refused the {} scaler {} -> {} ({} -> {}); it limits the scale (about 1x to 3x, "
                                "less with the temporal one) and the formats: use a quality mode with a smaller ratio",
                                desc.kind == Kind::Spatial ? "spatial" : "temporal",
                                size_text(desc.inputWidth, desc.inputHeight), size_text(desc.outputWidth, desc.outputHeight),
                                color->name, output->name));
    impl_->desc = desc;
    impl_->valid = true;
    impl_->generation += 1;
    impl_->encoded = 0;
    return true;
#else
    return fail("metalfx: this build has no MetalFX SDK");
#endif
}

#if defined(FA_HAVE_METALFX_SDK)
namespace {

// The texture of `image`, checked against what the scaler asked for. nil with `error` when it does not fit.
id<MTLTexture> checked_texture(sg_image image, const char* what, int w, int h, const FormatInfo* format, MTLTextureUsage usage,
                               const char* usageHint, std::string* error) {
    id<MTLTexture> tex = texture_of(image);
    auto fail = [&](std::string message) -> id<MTLTexture> {
        if (error) *error = "metalfx: Frame." + std::string(what) + " " + message;
        return nil;
    };
    if (tex == nil) return fail("is not a valid image: make it before the frame and pass the sokol image");
    if (int(tex.width) != w || int(tex.height) != h)
        return fail(std::format("is {} but the scaler was configured for {}: configure again after a resize",
                                size_text(int(tex.width), int(tex.height)), size_text(w, h)));
    if (tex.pixelFormat != format->mtl)
        return fail(std::format("is {} but the scaler was configured for {}: make the image with that format",
                                mtl_format_name(tex.pixelFormat), format->name));
    if (tex.sampleCount != 1) return fail("is multisampled: resolve it first and pass the resolved image");
    if ((tex.usage & usage) != usage)
        return fail(std::format("{} (MetalFX needs texture usage 0x{:x}, this image has 0x{:x})", usageHint,
                                unsigned(usage), unsigned(tex.usage)));
    return tex;
}

// The value of `event` is at least `value` (the GPU may have signalled it already, and may be about to signal more: never lower it).
void signal_at_least(id<MTLSharedEvent> event, uint64_t value) {
    if (event.signaledValue < value) event.signaledValue = value;
}

}  // namespace
#endif

bool Scaler::encode(const Frame& frame, std::string* error) {
    Impl& im = *impl_;
    if (!im.valid) {
        if (error) *error = "metalfx: encode() before configure() succeeded: configure the scaler first";
        return false;
    }
#if defined(FA_HAVE_METALFX_SDK)
    if (@available(macOS 13.0, iOS 16.0, *)) {
        const Desc& d = im.desc;
        const FormatInfo* color = format_info(d.colorFormat);
        const FormatInfo* output = format_info(d.outputFormat);
        id<MTLTexture> colorTex = nil, outputTex = nil, depthTex = nil, motionTex = nil;
        // Everything is checked before the sokol frame is committed: a refused frame does no work at all.
        @autoreleasepool {
            if (d.kind == Kind::Spatial) {
                id<MTLFXSpatialScaler> s = im.spatial;
                colorTex = checked_texture(frame.color, "color", d.inputWidth, d.inputHeight, color, [s colorTextureUsage],
                                           "cannot be sampled", error);
                outputTex = colorTex ? checked_texture(frame.output, "output", d.outputWidth, d.outputHeight, output,
                                                       [s outputTextureUsage],
                                                       "cannot be written by MetalFX: make the image with usage.color_attachment "
                                                       "and usage.storage_image (and a texture view of it for the passes that "
                                                       "read it)",
                                                       error)
                                     : nil;
                if (!colorTex || !outputTex) return false;
            } else {
                id<MTLFXTemporalScaler> t = im.temporal;
                colorTex = checked_texture(frame.color, "color", d.inputWidth, d.inputHeight, color, [t colorTextureUsage],
                                           "cannot be sampled", error);
                if (colorTex)
                    depthTex = checked_texture(frame.depth, "depth", d.inputWidth, d.inputHeight, format_info(d.depthFormat),
                                               [t depthTextureUsage], "cannot be sampled", error);
                if (depthTex)
                    motionTex = checked_texture(frame.motion, "motion", d.inputWidth, d.inputHeight, format_info(d.motionFormat),
                                                [t motionTextureUsage], "cannot be sampled", error);
                if (motionTex)
                    outputTex = checked_texture(frame.output, "output", d.outputWidth, d.outputHeight, output,
                                                [t outputTextureUsage],
                                                "cannot be written by MetalFX: make the image with usage.color_attachment "
                                                "and usage.storage_image (and a texture view of it for the passes that read "
                                                "it)",
                                                error);
                if (!colorTex || !depthTex || !motionTex || !outputTex) return false;
            }
        }
        // The split: the sokol passes so far (they wrote `color`, `depth` and `motion`) are submitted; the buffer made below goes on
        // the queue behind them, and the sokol buffer of the passes after this call goes behind it. The order is made explicit on the
        // GPU with one shared event (the CPU never waits for the GPU here): the sokol buffer of the earlier passes signals it, the
        // MetalFX buffer waits for that and signals it again at its end, and the sokol buffer of the later passes waits for that.
        // Both ends are needed in the code, one of them is the one that matters in the tests: frames queued without any of this
        // hashed differently from run to run (the test "frames queued without waiting for the GPU", 8 runs of 8 failed), and taking
        // sokol's buffer of the later passes here, which sokol would otherwise take at their first pass, made them hash alike. Why
        // that one does it was not isolated (a CPU wait for either side, or a 30 ms sleep, also made them alike; draining the GPU at
        // the start of each frame did not), so the test, not this comment, is what keeps it true.
        if (im.event == nil) im.event = [metal_device() newSharedEvent];
        id<MTLSharedEvent> event = im.event;
        const uint64_t afterPasses = ++im.eventValue;
        const uint64_t afterScaler = ++im.eventValue;
        id<MTLCommandBuffer> before = (__bridge id<MTLCommandBuffer>)fa_sg_mtl_command_buffer();
        if (before == nil) {
            if (error) *error = "metalfx: sokol has no Metal command buffer (the device was lost?)";
            return false;
        }
        [before encodeSignalEvent:event value:afterPasses];
        // A buffer that fails does not signal: the handler does it for the buffers that wait, so a failed frame cannot stall the queue.
        [before addCompletedHandler:^(id<MTLCommandBuffer>) { signal_at_least(event, afterPasses); }];
        sg_commit();
        @autoreleasepool {
            id<MTLCommandQueue> queue = (__bridge id<MTLCommandQueue>)sg_mtl_command_queue();
            id<MTLCommandBuffer> cmd = [queue commandBuffer];
            if (cmd == nil) {
                if (error) *error = "metalfx: Metal gave no command buffer (the device was lost?)";
                return false;
            }
            cmd.label = @"metalfx";
            [cmd encodeWaitForEvent:event value:afterPasses];
            if (d.kind == Kind::Spatial) {
                id<MTLFXSpatialScaler> s = im.spatial;
                s.colorTexture = colorTex;
                s.outputTexture = outputTex;
                s.inputContentWidth = NSUInteger(d.inputWidth);
                s.inputContentHeight = NSUInteger(d.inputHeight);
                [s encodeToCommandBuffer:cmd];
                // The command buffer holds the textures now: the scaler lets go of them, so a frame's images are not kept alive (nor
                // a resized target's) until the next frame replaces them.
                s.colorTexture = nil;
                s.outputTexture = nil;
            } else {
                id<MTLFXTemporalScaler> t = im.temporal;
                t.colorTexture = colorTex;
                t.depthTexture = depthTex;
                t.motionTexture = motionTex;
                t.outputTexture = outputTex;
                t.inputContentWidth = NSUInteger(d.inputWidth);
                t.inputContentHeight = NSUInteger(d.inputHeight);
                t.jitterOffsetX = frame.jitterX;
                t.jitterOffsetY = frame.jitterY;
                t.motionVectorScaleX = frame.motionScaleX;
                t.motionVectorScaleY = frame.motionScaleY;
                t.preExposure = frame.preExposure;
                t.depthReversed = d.depthReversed ? YES : NO;
                t.reset = (frame.reset || im.encoded == 0) ? YES : NO;
                [t encodeToCommandBuffer:cmd];
                t.colorTexture = nil;
                t.depthTexture = nil;
                t.motionTexture = nil;
                t.outputTexture = nil;
            }
            if (!im.status) im.status = std::make_shared<CommandStatus>();
            std::shared_ptr<CommandStatus> status = im.status;
            [cmd addCompletedHandler:^(id<MTLCommandBuffer> done) {
                signal_at_least(event, afterScaler);  // a failed buffer does not signal: the later passes must not wait for ever
                // Another thread (Metal's completion queue). The block captures the shared status, not the scaler, which may be gone by
                // now. The first error is kept and flagged; Scaler::command_failed hands it to the renderer, which gives MetalFX up with
                // its one warning (every later buffer of a failed scaler would fail the same way, so the later ones say nothing). A scaler
                // that fails leaves its output as it was.
                if (done.status != MTLCommandBufferStatusError) return;
                std::lock_guard<std::mutex> lock(status->mutex);
                if (status->failed.load(std::memory_order_relaxed)) return;
                status->why = done.error ? std::string([[done.error localizedDescription] UTF8String]) : std::string("unknown error");
                status->failed.store(true, std::memory_order_release);  // after `why`: command_failed reads it when it sees the flag
            }];
            [cmd encodeSignalEvent:event value:afterScaler];
            [cmd commit];
        }
        // The sokol buffer of the passes after this call: it starts when MetalFX has written its output.
        id<MTLCommandBuffer> after = (__bridge id<MTLCommandBuffer>)fa_sg_mtl_command_buffer();
        if (after != nil) [after encodeWaitForEvent:event value:afterScaler];
        im.encoded += 1;
        return true;
    }
#endif
    if (error) *error = "metalfx: MetalFX needs macOS 13 or iOS 16 or later";
    return false;
}

}  // namespace fa::render::metalfx

#endif  // SOKOL_METAL
