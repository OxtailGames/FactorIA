#include "render_upscale_dlss.h"

#include <algorithm>
#include <cfloat>
#include <cmath>
#include <cstring>
#include <mutex>
#include <span>
#include <utility>

#include "fa/core/log.h"

#include "streamline_runtime.h"

namespace fa::render {

namespace {

using namespace sl_abi;
using SlResult = sl_abi::Result;

constexpr float kModeBand = 0.13f;  // the closest two modes are 0.2 apart: a band of 0.13 keeps a wobbling ratio on one mode near a boundary
constexpr std::uint32_t kRenderSizeSlack = 2;  // pixels of difference to DLSS's own render size the frame may have

struct ModeRow {
    std::uint32_t mode;
    float ratio;
    const char* name;
};
constexpr ModeRow kModes[] = {
    {kDlssDlaa, 1.0f, "DLAA"},
    {kDlssUltraQuality, 1.3f, "Ultra Quality"},
    {kDlssMaxQuality, 1.5f, "Quality"},
    {kDlssBalanced, 1.72f, "Balanced"},
    {kDlssMaxPerformance, 2.0f, "Performance"},
    {kDlssUltraPerformance, 3.0f, "Ultra Performance"},
};

constexpr unsigned bit(gpu::Backend b) { return 1u << unsigned(b); }

// The Direct3D 12 and Vulkan states the images are in inside the native section (CommandList::begin_native declares them: a shader reads
// color, depth and velocity; DLSS writes the output).
constexpr std::uint32_t kD3d12ShaderReadGraphics = 0xC0;  // PIXEL_SHADER_RESOURCE | NON_PIXEL_SHADER_RESOURCE
constexpr std::uint32_t kD3d12ShaderReadCompute = 0x40;   // NON_PIXEL_SHADER_RESOURCE
constexpr std::uint32_t kD3d12UnorderedAccess = 0x8;
constexpr std::uint32_t kVkLayoutGeneral = 1, kVkLayoutShaderRead = 5;

void* handle_of(std::uint64_t v) {
    return reinterpret_cast<void*>(static_cast<std::uintptr_t>(v));  // NOLINT: a Vulkan handle
}

class DlssProvider final : public VendorUpscaler {
public:
    std::string_view name() const override { return "DLSS"; }
    std::string_view mode() const override { return "dlss"; }
    std::string_view setup_id() const override { return "streamline"; }
    // The Streamline runtime hooks the D3D12 and Vulkan devices only: a Direct3D 11 device is made without it.
    unsigned backends() const override { return bit(gpu::Backend::D3d12) | bit(gpu::Backend::Vulkan); }
    // DLSS writes the output image from a compute shader.
    bool needs_output_storage() const override { return true; }

    VendorProbe probe(const VendorEnv& env) override;
    bool upscale(const UpscaleInput& in, VendorFrame& frame) override;
    void release(gpu::Device& device) override;

private:
    // What DLSS was last told, and the functions of this set-up of Streamline.
    struct State {
        const gpu::Device* device = nullptr;
        std::uint64_t generation = 0;  // StreamlineStatus::generation the functions and options are for
        DlssSetOptionsFn setOptions = nullptr;
        DlssGetOptimalSettingsFn getOptimal = nullptr;
        bool optionsSet = false;
        std::uint32_t mode = 0;
        int outW = 0, outH = 0;
        float preExposure = 1.0f;
        bool hdr = false;
        bool needReset = true;  // the next frame starts the history again (new options, or an evaluate that failed)
        bool sizeChecked = false;
        int renderW = 0, renderH = 0;
        // Vulkan: the storage view of the output image DLSS writes (made when the image changes).
        gpu::Image outputImage{};
        gpu::View outputView{};
    };

    std::string ensure_options(StreamlineRuntime& runtime, const StreamlineApi& api, gpu::Device& device, const UpscaleInput& in,
                               std::uint64_t generation);
    std::string ensure_output_view(gpu::Device& device, gpu::Image output);
    void drop_output_view(gpu::Device& device) {
        if (state_.outputView.valid()) device.destroy_view(state_.outputView);
        state_.outputView = {};
        state_.outputImage = {};
    }
    bool fail(VendorFrame& frame, std::string why) {
        state_.needReset = true;
        frame.error = std::move(why);
        return false;
    }

    std::mutex mutex_;
    State state_{};
};

VendorProbe DlssProvider::probe(const VendorEnv& env) {
    VendorProbe p;
    // What the machine decides first: the GPU's maker, the backend and the system. A library that is missing is last: installing it is of no
    // use where the GPU or the backend cannot run DLSS.
    if (env.vendor != GpuVendor::Nvidia) {
        p.reason = "DLSS needs an NVIDIA RTX GPU; this GPU is " + vendor_describe_gpu(env.vendor) + ".";
        return p;
    }
    p.reason = vendor_environment_problem(*this, env);
    if (!p.reason.empty()) return p;
    StreamlineRuntime& runtime = streamline_runtime();
    const StreamlineStatus status = runtime.status();
    if (status.ready) {
        if (status.backend != env.backend) {
            p.reason = std::string("NVIDIA Streamline was started for ") + vendor_backend_label(status.backend) +
                       " and this device is " + vendor_backend_label(env.backend) + ".";
            return p;
        }
        if (const std::string why = runtime.feature_reason(kFeatureDlss); !why.empty()) {
            p.reason = "DLSS is not available on this machine: " + why;
            return p;
        }
        p.available = true;
        return p;
    }
    if (status.tried) {
        p.reason = status.reason.empty() ? "NVIDIA Streamline did not start with the graphics device." : status.reason;
        return p;
    }
    // Streamline never saw this device: say whether the library is there, which is what the user can do something about.
    std::string why;
    const VendorLibrarySpec spec{"streamline", "FA_STREAMLINE_DIR", "sl.interposer.dll"};
    if (vendor_loader().find(spec, &why).empty()) {
        p.reason = "DLSS is not installed: run `factoria setup streamline` (" + why + ").";
        return p;
    }
    p.reason = "NVIDIA Streamline is installed, but it was not started when the graphics device was made (the renderer starts it before "
               "it makes a Direct3D 12 or Vulkan device): restart the game.";
    return p;
}

// Sets DLSS's options when the mode, the output size, the exposure or the colour space changed. "" or the sentence of what failed.
std::string DlssProvider::ensure_options(StreamlineRuntime& runtime, const StreamlineApi& api, gpu::Device& device,
                                         const UpscaleInput& in, std::uint64_t generation) {
    (void)runtime;
    if (state_.device != &device || state_.generation != generation) {
        // Another device or another set-up of Streamline: nothing of the earlier one is valid (the view of the same device is destroyed).
        if (state_.device == &device) drop_output_view(device);
        state_ = State{};
        state_.device = &device;
        state_.generation = generation;
    }
    if (!state_.setOptions || !state_.getOptimal) {
        void* setOptions = nullptr;
        void* getOptimal = nullptr;
        if (const SlResult r = api.getFeatureFunction(kFeatureDlss, "slDLSSSetOptions", &setOptions); r != kOk || !setOptions)
            return streamline_refusal("slGetFeatureFunction(slDLSSSetOptions)", r == kOk ? kErrorFeatureMissing : r);
        if (const SlResult r = api.getFeatureFunction(kFeatureDlss, "slDLSSGetOptimalSettings", &getOptimal); r != kOk || !getOptimal)
            return streamline_refusal("slGetFeatureFunction(slDLSSGetOptimalSettings)", r == kOk ? kErrorFeatureMissing : r);
        state_.setOptions = reinterpret_cast<DlssSetOptionsFn>(setOptions);        // NOLINT: the function's address
        state_.getOptimal = reinterpret_cast<DlssGetOptimalSettingsFn>(getOptimal);  // NOLINT
    }
    const float ratio = std::max(float(in.outW) / float(in.renderW), float(in.outH) / float(in.renderH));
    const std::uint32_t dlssMode = dlss_mode_for_ratio(ratio, state_.optionsSet ? state_.mode : 0);
    const float preExposure = in.exposure > 0.0f && std::isfinite(in.exposure) ? in.exposure : 1.0f;
    const bool hdr = in.linear;
    const bool sameSizes = state_.sizeChecked && state_.mode == dlssMode && state_.outW == in.outW && state_.outH == in.outH &&
                           state_.renderW == in.renderW && state_.renderH == in.renderH;
    DlssOptions options;
    init_dlss_options(options);
    options.mode = dlssMode;
    options.outputWidth = std::uint32_t(in.outW);
    options.outputHeight = std::uint32_t(in.outH);
    options.sharpness = 0.0f;  // the engine sharpens in its own pass
    options.preExposure = preExposure;
    options.exposureScale = 1.0f;
    options.colorBuffersHdr = hdr ? kTrue : kFalse;
    options.indicatorInvertAxisX = options.indicatorInvertAxisY = kFalse;
    options.useAutoExposure = kTrue;  // the frame's colour is exposed already: DLSS finds its own scene exposure
    options.alphaUpscalingEnabled = kFalse;
    if (!sameSizes) {
        // DLSS says what render size the mode asks for at this output: the frame must be drawn within its range.
        DlssOptimalSettings settings;
        init_dlss_optimal_settings(settings);
        if (const SlResult r = state_.getOptimal(&options, &settings); r != kOk)
            return streamline_refusal("slDLSSGetOptimalSettings", r);
        if (settings.optimalRenderWidth == 0 || settings.optimalRenderHeight == 0)
            return std::string("DLSS does not support its ") + dlss_mode_name(dlssMode) + " mode for an output of " + std::to_string(in.outW) +
                   "x" + std::to_string(in.outH) + ". Choose another quality (render.upscaler.quality) or a larger window.";
        const auto within = [](int value, std::uint32_t lo, std::uint32_t hi, std::uint32_t optimal) {
            const std::uint32_t low = std::min(lo == 0 ? optimal : lo, optimal);
            const std::uint32_t high = std::max(hi == 0 ? optimal : hi, optimal);
            return std::uint32_t(value) + kRenderSizeSlack >= low && std::uint32_t(value) <= high + kRenderSizeSlack;
        };
        if (!within(in.renderW, settings.renderWidthMin, settings.renderWidthMax, settings.optimalRenderWidth) ||
            !within(in.renderH, settings.renderHeightMin, settings.renderHeightMax, settings.optimalRenderHeight))
            return "DLSS's " + std::string(dlss_mode_name(dlssMode)) + " mode draws at " + std::to_string(settings.optimalRenderWidth) + "x" +
                   std::to_string(settings.optimalRenderHeight) + " for an output of " + std::to_string(in.outW) + "x" +
                   std::to_string(in.outH) + ", and the frame was drawn at " + std::to_string(in.renderW) + "x" +
                   std::to_string(in.renderH) + ". Choose another render.upscaler.quality.";
    }
    const bool changed = !state_.optionsSet || state_.mode != dlssMode || state_.outW != in.outW || state_.outH != in.outH ||
                         state_.preExposure != preExposure || state_.hdr != hdr;
    if (changed) {
        ViewportHandle viewport;
        init_viewport(viewport, 0);
        state_.optionsSet = false;
        if (const SlResult r = state_.setOptions(&viewport, &options); r != kOk) return streamline_refusal("slDLSSSetOptions", r);
        state_.optionsSet = true;
        state_.needReset = true;  // the history of the old mode means nothing to the new one
    }
    state_.mode = dlssMode;
    state_.outW = in.outW;
    state_.outH = in.outH;
    state_.renderW = in.renderW;
    state_.renderH = in.renderH;
    state_.preExposure = preExposure;
    state_.hdr = hdr;
    state_.sizeChecked = true;
    return {};
}

// Vulkan: DLSS wants the output as an image with a view (the storage view of the output image, made once per output image).
std::string DlssProvider::ensure_output_view(gpu::Device& device, gpu::Image output) {
    if (state_.outputView.valid() && state_.outputImage != output) drop_output_view(device);
    if (state_.outputView.valid()) return {};
    gpu::ViewDesc v;
    v.storageImage.image = output;
    v.label = "dlss-output";
    state_.outputView = device.make_view(v);
    state_.outputImage = output;
    if (!state_.outputView.valid())
        return "the GPU could not make the storage view of the output image (the image was not made with storage usage)";
    return {};
}

bool DlssProvider::upscale(const UpscaleInput& in, VendorFrame& frame) {
    std::lock_guard<std::mutex> lock(mutex_);
    frame.error.clear();
    if (!frame.device || !frame.list) {
        frame.error = "DLSS was given no device or no command list.";
        return false;
    }
    gpu::Device& device = *frame.device;
    StreamlineRuntime& runtime = streamline_runtime();
    const StreamlineStatus status = runtime.status();
    const StreamlineApi* api = status.ready ? runtime.api() : nullptr;
    if (!api) {
        frame.error = status.reason.empty() ? "NVIDIA Streamline is not running on this device." : status.reason;
        return false;
    }
    if (device.backend() != status.backend) {
        frame.error = "NVIDIA Streamline was started for " + std::string(vendor_backend_label(status.backend)) + " and this device is " +
                      vendor_backend_label(device.backend()) + ".";
        return false;
    }
    if (!frame.color.valid() || !frame.output.valid() || !frame.depth.valid() || !frame.velocity.valid()) {
        frame.error = "DLSS needs the colour, depth, velocity and output images of the frame (the frame has no " +
                      std::string(!frame.color.valid()      ? "colour"
                                  : !frame.depth.valid()    ? "depth"
                                  : !frame.velocity.valid() ? "velocity"
                                                            : "output") +
                      " image).";
        return false;
    }
    if (in.renderW <= 0 || in.renderH <= 0 || in.outW <= 0 || in.outH <= 0) {
        frame.error = "DLSS was given an empty picture (" + std::to_string(in.renderW) + "x" + std::to_string(in.renderH) + " -> " +
                      std::to_string(in.outW) + "x" + std::to_string(in.outH) + ").";
        return false;
    }
    if (std::string e = ensure_options(runtime, *api, device, in, status.generation); !e.empty()) return fail(frame, std::move(e));
    if (device.backend() == gpu::Backend::Vulkan) {
        if (std::string e = ensure_output_view(device, frame.output); !e.empty()) return fail(frame, "DLSS: " + e + ".");
    }

    // The frame's token: the same one tags the resources, sets the constants and evaluates (Streamline's frame based resource tagging).
    std::string why;
    void* const token = runtime.frame_token(nullptr, &why);
    if (!token) return fail(frame, why);

    ViewportHandle viewport;
    init_viewport(viewport, 0);
    const auto finite = [](float v, float limit) { return std::isfinite(v) ? std::clamp(v, -limit, limit) : 0.0f; };
    Constants constants;
    init_constants(constants);
    // The jitter is in render pixels, the way XeSS takes it; the motion vectors are in UV units (the picture is 1 wide) pointing to the
    // previous position, y down, so Streamline's scale is 1. The matrices are identity (Super Resolution reads none of them).
    constants.jitterOffset = {finite(in.jitter[0], 0.5f), finite(in.jitter[1], 0.5f)};
    constants.mvecScale = {1.0f, 1.0f};
    constants.cameraNear = 0.1f;
    constants.cameraFar = 1000.0f;
    constants.cameraFov = 1.0f;
    constants.cameraAspectRatio = float(in.outW) / float(in.outH);
    constants.motionVectorsInvalidValue = FLT_MIN;
    constants.depthInverted = kFalse;  // the prep pass writes 0..1 growing with the distance
    constants.cameraMotionIncluded = kTrue;
    constants.motionVectors3d = kFalse;
    constants.orthographicProjection = kFalse;
    constants.motionVectorsDilated = kFalse;
    constants.motionVectorsJittered = kFalse;
    constants.reset = (in.resetHistory || state_.needReset) ? kTrue : kFalse;
    if (const SlResult r = api->setConstants(&constants, token, &viewport); r != kOk)
        return fail(frame, streamline_refusal("slSetConstants", r));

    const gpu::Backend backend = device.backend();
    gpu::NativeUse uses[4];
    uses[0].image = frame.color;
    uses[0].state = gpu::NativeState::ShaderRead;
    uses[1].image = frame.depth;
    uses[1].state = gpu::NativeState::ShaderRead;
    uses[2].image = frame.velocity;
    uses[2].state = gpu::NativeState::ShaderRead;
    uses[3].image = frame.output;
    uses[3].state = gpu::NativeState::UnorderedAccess;

    // The resources, with their native objects, sizes and states; the handles are read before the section opens, so a failure leaves the
    // list as it was.
    struct Tagged {
        Resource resource;
        ResourceTag tag;
    };
    Tagged tagged[4];
    const auto describe = [&](Tagged& t, std::uint32_t type, gpu::Image image, gpu::View view, int w, int h, bool write,
                              gpu::QueueKind kind) -> std::string {
        init_resource(t.resource);
        const gpu::NativeImage ni = device.native_image(image);
        t.resource.width = std::uint32_t(w);
        t.resource.height = std::uint32_t(h);
        t.resource.mipLevels = 1;
        t.resource.arrayLayers = 1;
        if (backend == gpu::Backend::Vulkan) {
            const gpu::NativeView nv = device.native_view(view);
            if (!ni.vkImage || !nv.vkImageView) return "the Vulkan image or view of a DLSS input is not known to the device";
            t.resource.native = handle_of(ni.vkImage);
            t.resource.view = handle_of(nv.vkImageView);
            t.resource.nativeFormat = nv.nativeFormat;
            t.resource.mipLevels = std::uint32_t(std::max(nv.mipCount, 1));
            t.resource.arrayLayers = std::uint32_t(std::max(nv.sliceCount, 1));
            t.resource.usage = ni.vkUsage;
            t.resource.flags = 0;
            t.resource.state = write ? kVkLayoutGeneral : kVkLayoutShaderRead;
        } else {
            if (!ni.resource) return "the device gave no native resource for a DLSS input";
            t.resource.native = const_cast<void*>(ni.resource);
            t.resource.nativeFormat = ni.nativeFormat;
            t.resource.state = write ? kD3d12UnorderedAccess
                                     : (kind == gpu::QueueKind::Compute ? kD3d12ShaderReadCompute : kD3d12ShaderReadGraphics);
        }
        init_resource_tag(t.tag);
        t.tag.resource = &t.resource;
        t.tag.type = type;
        t.tag.lifecycle = kOnlyValidNow;
        t.tag.extent = Extent{0, 0, std::uint32_t(w), std::uint32_t(h)};
        return {};
    };
    const gpu::QueueKind queue = frame.list->queue();
    {
        std::string e = describe(tagged[0], kBufferScalingInputColor, frame.color, in.color, in.renderW, in.renderH, false, queue);
        if (e.empty()) e = describe(tagged[1], kBufferDepth, frame.depth, in.depth, in.renderW, in.renderH, false, queue);
        if (e.empty()) e = describe(tagged[2], kBufferMotionVectors, frame.velocity, in.velocity, in.renderW, in.renderH, false, queue);
        if (e.empty()) e = describe(tagged[3], kBufferScalingOutputColor, frame.output, state_.outputView, in.outW, in.outH, true, queue);
        if (!e.empty()) return fail(frame, "DLSS: " + e + ".");
    }
    ResourceTag tags[4];
    for (int i = 0; i < 4; ++i) tags[i] = tagged[i].tag;

    const fa::Result<gpu::NativeCommands> native = frame.list->begin_native(std::span<const gpu::NativeUse>(uses, 4));
    if (!native) return fail(frame, "DLSS could not open a native command section: " + native.error().message);
    void* const list = const_cast<void*>(native->list);
    SlResult r = api->setTagForFrame(token, &viewport, tags, 4, list);
    std::string what = "slSetTagForFrame";
    if (r == kOk) {
        const Base* inputs[] = {&viewport.base};
        r = api->evaluateFeature(kFeatureDlss, token, inputs, 1, list);
        what = "slEvaluateFeature";
    }
    // The section is closed whatever Streamline answered: the images are left in the states they were declared in.
    const fa::Result<void> closed = frame.list->end_native();
    if (r != kOk) return fail(frame, "DLSS failed to draw a frame: " + streamline_refusal(what.c_str(), r));
    if (!closed) return fail(frame, "DLSS drew, but its native command section could not be closed: " + closed.error().message);
    state_.needReset = false;
    return true;
}

void DlssProvider::release(gpu::Device& device) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (state_.device != &device) return;  // it never drew on this device
    StreamlineRuntime& runtime = streamline_runtime();
    const StreamlineStatus status = runtime.status();
    const StreamlineApi* api = status.ready && status.generation == state_.generation ? runtime.api() : nullptr;
    if (api) {
        // The GPU may still be running the last frame with DLSS's resources: wait, then give them back.
        if (const fa::Result<void> idle = device.wait_idle(); !idle) FA_WARN("render", "DLSS: {}", idle.error().message);
        ViewportHandle viewport;
        init_viewport(viewport, 0);
        if (state_.optionsSet && state_.setOptions) {
            DlssOptions off;
            init_dlss_options(off);
            off.mode = kDlssOff;
            state_.setOptions(&viewport, &off);
        }
        if (api->freeResources) api->freeResources(kFeatureDlss, &viewport);
    }
    drop_output_view(device);
    state_ = State{};
}

}  // namespace

std::uint32_t dlss_mode_for_ratio(float ratio, std::uint32_t current) {
    if (current != 0) {
        for (const ModeRow& m : kModes)
            if (m.mode == current && std::fabs(ratio - m.ratio) <= kModeBand) return current;
    }
    std::uint32_t best = kModes[0].mode;
    float bestDistance = FLT_MAX;
    for (const ModeRow& m : kModes) {
        const float d = std::fabs(ratio - m.ratio);
        if (d < bestDistance) {
            bestDistance = d;
            best = m.mode;
        }
    }
    return best;
}

float dlss_mode_ratio(std::uint32_t mode) {
    for (const ModeRow& m : kModes)
        if (m.mode == mode) return m.ratio;
    return 1.0f;
}

const char* dlss_mode_name(std::uint32_t mode) {
    for (const ModeRow& m : kModes)
        if (m.mode == mode) return m.name;
    return "unknown";
}

std::unique_ptr<VendorUpscaler> make_dlss_provider() {
    return std::make_unique<DlssProvider>();
}

}  // namespace fa::render
