#include "render_framegen_dlss.h"

#include <algorithm>
#include <cfloat>
#include <cmath>
#include <cstring>
#include <initializer_list>
#include <span>
#include <string>
#include <type_traits>
#include <utility>

#include "fa/core/log.h"

#include "render_latency_reflex.h"
#include "streamline_runtime.h"

namespace fa::render {

namespace {

namespace abi = sl_abi;
using SlResult = abi::Result;

constexpr unsigned bit(gpu::Backend b) { return 1u << unsigned(b); }

// The reasons the setup is to blame for end with the command that fixes it.
constexpr const char* kSetupHint = "run `factoria setup streamline` to install it";

// The Direct3D 12 and Vulkan states the images are in inside the native section (CommandList::begin_native declares them).
constexpr std::uint32_t kD3d12ShaderReadGraphics = 0xC0;  // PIXEL_SHADER_RESOURCE | NON_PIXEL_SHADER_RESOURCE
constexpr std::uint32_t kD3d12ShaderReadCompute = 0x40;   // NON_PIXEL_SHADER_RESOURCE
constexpr std::uint32_t kVkLayoutShaderRead = 5;

// The bits of sl::DLSSGStatus that mean generation does not run.
constexpr std::uint32_t kFailMask = abi::kDlssgFailResolutionTooLow | abi::kDlssgFailReflexNotDetectedAtRuntime |
                                    abi::kDlssgFailHdrFormatNotSupported | abi::kDlssgFailCommonConstantsInvalid |
                                    abi::kDlssgFailGetCurrentBackBufferIndexNotCalled;

static_assert(sizeof(abi::Float4x4) == 16 * sizeof(float), "a Mat4 is copied into a Float4x4");

void* handle_of(std::uint64_t v) {
    return reinterpret_cast<void*>(static_cast<std::uintptr_t>(v));  // NOLINT: a Vulkan handle
}

struct DlssgApi {
    abi::DlssgSetOptionsFn setOptions = nullptr;
    abi::DlssgGetStateFn getState = nullptr;
};

// The two functions of the DLSS-G plugin, from slGetFeatureFunction. "" when both are there, else the sentence of the first that is not.
std::string load_dlssg_api(const StreamlineApi& sl, DlssgApi& api) {
    if (!sl.getFeatureFunction)
        return "NVIDIA Streamline has no slGetFeatureFunction (it is not Streamline 2.x): " + std::string(kSetupHint) +
               ".";
    DlssgApi a;
    const auto get = [&](const char* name, auto& fn) -> std::string {
        void* address = nullptr;
        const SlResult r = sl.getFeatureFunction(abi::kFeatureDlssG, name, &address);
        if (r != abi::kOk || !address)
            return streamline_refusal((std::string("slGetFeatureFunction(") + name + ")").c_str(),
                                      r == abi::kOk ? abi::kErrorFeatureMissing : r);
        fn = reinterpret_cast<std::remove_reference_t<decltype(fn)>>(address);  // NOLINT: the function's address
        return {};
    };
    for (const std::string& why : {get("slDLSSGSetOptions", a.setOptions), get("slDLSSGGetState", a.getState)})
        if (!why.empty()) return why;
    api = a;
    return {};
}

// What a machine that cannot run DLSS-G is told, after Streamline's own words.
std::string unsupported_text(const std::string& why) {
    return "DLSS frame generation is not available on this machine: " + why +
           " It needs an NVIDIA GeForce RTX 40 series GPU or newer, Windows 10 or 11 with \"Hardware-accelerated GPU "
           "scheduling\" "
           "turned on, and a recent NVIDIA graphics driver.";
}

bool finite_all(const float* v, int n) {
    for (int i = 0; i < n; ++i)
        if (!std::isfinite(v[i])) return false;
    return true;
}

abi::Float4x4 to_float4x4(const Mat4& m) {
    abi::Float4x4 out;
    // Streamline's matrices are row-major and take row vectors (DirectXMath); a Mat4 is column-major and takes column vectors. The memory of
    // M is read the other way round as the memory of the transpose of M, which is what Streamline wants of the same transform.
    std::memcpy(&out, m.m, sizeof out);
    return out;
}

abi::Float3 to_float3(const Vec3& v) { return {v.x, v.y, v.z}; }

// The projection of the frame, with the reversed infinite depth the provider asked for: the clip z of a view-space point is the near plane (the
// perspective division by the distance then gives near / d).
Mat4 projection_of(const FrameGenFrame& f) {
    Mat4 p;
    for (float& v : p.m) v = 0.0f;
    p.at(0, 0) = f.proj[0];
    p.at(1, 1) = f.proj[1];
    p.at(2, 0) = f.proj[2];
    p.at(2, 1) = f.proj[3];
    p.at(3, 0) = f.proj[4];
    p.at(3, 1) = f.proj[5];
    p.at(3, 2) = f.cameraNear;  // clip z = near
    p.at(2, 3) = f.proj[6];
    p.at(3, 3) = f.proj[7];
    return p;
}

const char* status_sentence(std::uint32_t bitValue) {
    switch (bitValue) {
        case abi::kDlssgFailReflexNotDetectedAtRuntime:
            return "Streamline did not see NVIDIA Reflex's markers at the last present (frame generation needs Reflex "
                   "on and its "
                   "simulation, render submit and present markers of every frame).";
        case abi::kDlssgFailHdrFormatNotSupported:
            return "the swapchain's HDR format is not one DLSS frame generation supports (it takes the 10-bit HDR10 "
                   "and the 16-bit scRGB "
                   "formats): use an SDR display mode or another HDR output.";
        case abi::kDlssgFailCommonConstantsInvalid:
            return "Streamline rejected the camera constants of the last frame (a matrix, a plane or the motion vector "
                   "scale it cannot "
                   "use).";
        case abi::kDlssgFailGetCurrentBackBufferIndexNotCalled:
            return "Streamline's swapchain was not asked for the current back buffer (the window's swapchain is not "
                   "the one Streamline "
                   "hooked): this is a bug in the engine's integration, please report it.";
        default: return "";
    }
}

class DlssFrameGenProvider final : public FrameGenProvider {
public:
    std::string_view name() const override { return "DLSS frame generation"; }
    FrameGenSlot slot() const override { return FrameGenSlot::Dlss; }
    std::string_view setup_id() const override { return "streamline"; }
    unsigned backends() const override { return bit(gpu::Backend::D3d12) | bit(gpu::Backend::Vulkan); }
    bool wants_reversed_depth() const override { return true; }
    bool requires_reflex() const override { return true; }

    std::shared_ptr<gpu::DeviceHook> device_hook() override;
    VendorProbe probe(const VendorEnv& env) override;
    std::string start(gpu::Device& device, const FrameGenSwapchain& swapchain) override;
    void swapchain_changed(gpu::Device& device, const FrameGenSwapchain& swapchain) override;
    void configure(bool enabled) override;
    bool dispatch(FrameGenFrame& frame) override;
    std::uint64_t generated_frames() override;
    void stop(gpu::Device& device) override;

private:
    // The options last accepted by Streamline: what is sent again only when it changes.
    struct Sent {
        bool valid = false;
        std::uint32_t mode = 0, flags = 0, mvecW = 0, mvecH = 0, colorW = 0, colorH = 0;
        bool operator==(const Sent&) const = default;
    };
    struct ViewSlot {
        gpu::Image image{};
        gpu::View view{};
    };

    bool live(const StreamlineRuntime& runtime) const { return device_ && runtime.ready_generation() == generation_; }
    bool send_options();
    void read_state();
    void drop_views(gpu::Device& device);
    void forget();
    bool refuse(FrameGenFrame& frame, std::string why) {
        frame.error = std::move(why);
        return false;
    }
    std::string describe(FrameGenFrame& frame, int slotIndex, std::uint32_t type, gpu::Image image, int w, int h,
                         int& count, abi::Resource* resources, abi::ResourceTag* tags, gpu::NativeUse* uses);

    gpu::Device* device_ = nullptr;
    std::uint64_t generation_ = 0;  // the Streamline set-up the functions below belong to
    DlssgApi api_{};
    bool enabled_ = false;  // the controller wants generation on
    bool retain_ = true;    // keep the resources while generation is off (a pause below minBaseFps) until stop()
    Sent sent_{};
    int swapW_ = 0, swapH_ = 0;  // the swapchain's size (the colour size until a frame says better)
    int renderW_ = 0, renderH_ = 0, outW_ = 0, outH_ = 0;
    // What the last slDLSSGGetState said (status is trusted only when it was read with generation on).
    std::uint32_t status_ = 0, minSize_ = 0, maxFrames_ = 0;
    bool statusOn_ = false;
    std::uint64_t generated_ = 0;
    bool loggedVram_ = false, warnedOptions_ = false, warnedState_ = false, warnedConstants_ = false;
    std::string optionsError_;
    ViewSlot views_[3];  // Vulkan: the sampled views of the depth, the motion and the hudless image
};

std::shared_ptr<gpu::DeviceHook> DlssFrameGenProvider::device_hook() {
    // Streamline loads only the features slInit is told of, and DLSS-G asks for its own Vulkan queues and extensions: it is added to the list of
    // the process's runtime (already a hook of every D3D12 and Vulkan device, register_streamline_runtime) the moment a renderer asks for
    // frame generation, before its device is made. A game that never asks never pays for them.
    streamline_runtime().add_feature(abi::kFeatureDlssG);
    return nullptr;
}

VendorProbe DlssFrameGenProvider::probe(const VendorEnv& env) {
    VendorProbe p;
    if (env.vendor != GpuVendor::Nvidia) {
        p.reason = "DLSS frame generation needs an NVIDIA GeForce RTX 40 series GPU or newer; this GPU is " +
                   vendor_describe_gpu(env.vendor) +
                   ". Choose \"auto\" (the frame generation SDK of the GPU's maker) or the mode of that SDK.";
        return p;
    }
    p.reason = framegen_environment_problem(*this, env);
    if (!p.reason.empty()) return p;

    StreamlineRuntime& runtime = streamline_runtime();
    const StreamlineStatus status = runtime.status();
    if (!status.ready) {
        if (status.tried) {
            p.reason =
                status.reason.empty() ? "NVIDIA Streamline did not start with the graphics device." : status.reason;
            return p;
        }
        // Streamline never saw this device: say whether the library is there, which is what the user can do something about.
        std::string why;
        const VendorLibrarySpec spec{"streamline", "FA_STREAMLINE_DIR", "sl.interposer.dll"};
        if (vendor_loader().find(spec, &why).empty())
            p.reason = std::string("DLSS frame generation is not installed: ") + kSetupHint + " (" + why + ").";
        else
            p.reason = "NVIDIA Streamline is installed, but it was not started when the graphics device was made (the "
                       "renderer starts it "
                       "before it makes a Direct3D 12 or Vulkan device): restart the game.";
        return p;
    }
    if (status.backend != env.backend) {
        p.reason = std::string("NVIDIA Streamline was started for ") + vendor_backend_label(status.backend) +
                   " and this device is " + vendor_backend_label(env.backend) + ".";
        return p;
    }
    if (!runtime.feature_asked(abi::kFeatureDlssG)) {
        p.reason = "DLSS frame generation was not set up when the graphics device was made (Streamline loads its "
                   "plugin before the "
                   "device exists): set render.frameGeneration.mode in factoria.json (or turn it on in the settings) "
                   "and restart the game.";
        return p;
    }
    if (const std::string why = runtime.feature_reason(abi::kFeatureDlssG); !why.empty()) {
        p.reason = unsupported_text(why);
        return p;
    }
    // DLSS-G reads Reflex's markers: both plugins have to run.
    if (const std::string why = runtime.feature_reason(abi::kFeatureReflex); !why.empty()) {
        p.reason = "DLSS frame generation needs NVIDIA Reflex, which is not available on this machine: " + why;
        return p;
    }
    if (const std::string why = runtime.feature_reason(abi::kFeaturePcl); !why.empty()) {
        p.reason =
            "DLSS frame generation needs the PC latency markers of Streamline's PCL plugin, which is not available: " +
            why;
        return p;
    }
    const StreamlineApi* sl = runtime.api();
    if (!sl) {
        p.reason = "NVIDIA Streamline is not running on this device.";
        return p;
    }
    DlssgApi api;
    if (const std::string why = load_dlssg_api(*sl, api); !why.empty()) {
        p.reason = "DLSS frame generation's plugin did not load: " + why;
        return p;
    }
    p.available = true;
    return p;
}

std::string DlssFrameGenProvider::start(gpu::Device& device, const FrameGenSwapchain& swapchain) {
    forget();  // what an earlier device left (its Streamline is gone with it)
    StreamlineRuntime& runtime = streamline_runtime();
    const std::uint64_t generation = runtime.ready_generation();
    const StreamlineStatus status = runtime.status();
    if (generation == 0)
        return status.reason.empty()
                   ? std::string("NVIDIA Streamline is not running on this device (") + kSetupHint + ")"
                   : status.reason;
    if (device.backend() != gpu::Backend::D3d12 && device.backend() != gpu::Backend::Vulkan)
        return "DLSS frame generation runs on Direct3D 12 and Vulkan";
    if (status.backend != device.backend())
        return std::string("NVIDIA Streamline was started for ") + vendor_backend_label(status.backend) +
               ", not for this device";
    if (!runtime.feature_asked(abi::kFeatureDlssG))
        return "DLSS frame generation was not set up when the graphics device was made: set "
               "render.frameGeneration.mode in "
               "factoria.json and restart the game";
    if (const std::string why = runtime.feature_reason(abi::kFeatureDlssG); !why.empty()) return unsupported_text(why);
    if (const std::string why = runtime.feature_reason(abi::kFeatureReflex); !why.empty())
        return "DLSS frame generation needs NVIDIA Reflex: " + why;
    const StreamlineApi* sl = runtime.api();
    if (!sl) return "NVIDIA Streamline is not running on this device";
    DlssgApi api;
    if (std::string why = load_dlssg_api(*sl, api); !why.empty())
        return "DLSS frame generation's plugin did not load: " + why;

    api_ = api;
    device_ = &device;
    generation_ = generation;
    swapW_ = std::max(swapchain.width, 0);
    swapH_ = std::max(swapchain.height, 0);
    enabled_ = false;
    retain_ = true;
    // slDLSSGSetOptions has to be called once before slDLSSGGetState works: the options start at off.
    if (!send_options()) {
        const std::string why = optionsError_;
        forget();
        return why;
    }
    abi::DlssgState state;
    abi::init_dlssg_state(state);
    abi::ViewportHandle viewport;
    abi::init_viewport(viewport, 0);
    if (const SlResult r = api_.getState(&viewport, &state, nullptr); r != abi::kOk) {
        forget();
        return streamline_refusal("slDLSSGGetState", r);
    }
    maxFrames_ = state.numFramesToGenerateMax;
    minSize_ = state.minWidthOrHeight;
    FA_INFO("render", "DLSS frame generation is ready (it generates {} frame(s) between two rendered ones at most)",
            maxFrames_);
    return {};
}

// Sends the options the controller and the frame sizes call for, when they differ from the last accepted ones.
bool DlssFrameGenProvider::send_options() {
    Sent want;
    want.valid = true;
    want.mode = enabled_ ? abi::kDlssgOn : abi::kDlssgOff;
    want.flags = abi::kDlssgRequestVramEstimate | (retain_ ? abi::kDlssgRetainResourcesWhenOff : 0u);
    want.mvecW = std::uint32_t(std::max(renderW_, 0));
    want.mvecH = std::uint32_t(std::max(renderH_, 0));
    want.colorW = std::uint32_t(std::max(outW_ > 0 ? outW_ : swapW_, 0));
    want.colorH = std::uint32_t(std::max(outH_ > 0 ? outH_ : swapH_, 0));
    if (sent_ == want) return true;
    abi::DlssgOptions options;
    abi::init_dlssg_options(options);
    options.mode = want.mode;
    options.numFramesToGenerate =
        1;  // multi frame generation (RTX 50) is not used: one generated frame per rendered one
    options.flags = want.flags;
    options.mvecDepthWidth = want.mvecW;
    options.mvecDepthHeight = want.mvecH;
    options.colorWidth = want.colorW;
    options.colorHeight = want.colorH;
    // The buffer formats stay 0: Streamline reads them from the tagged resources. The engine's own UI is in the picture (hudless +
    // final): there is no UI colour and alpha buffer, so user interface recomposition stays off.
    abi::ViewportHandle viewport;
    abi::init_viewport(viewport, 0);
    if (const SlResult r = api_.setOptions(&viewport, &options); r != abi::kOk) {
        optionsError_ = streamline_refusal("slDLSSGSetOptions", r);
        if (!warnedOptions_) FA_WARN("render", "DLSS frame generation: {}", optionsError_);
        warnedOptions_ = true;
        return false;
    }
    optionsError_.clear();
    sent_ = want;
    return true;
}

void DlssFrameGenProvider::configure(bool enabled) {
    enabled_ = enabled;
    if (!live(streamline_runtime())) return;
    send_options();  // a refusal is kept in optionsError_ and reported by the next dispatch
}

void DlssFrameGenProvider::swapchain_changed(gpu::Device& device, const FrameGenSwapchain& swapchain) {
    if (device_ != &device) return;
    swapW_ = std::max(swapchain.width, 0);
    swapH_ = std::max(swapchain.height, 0);
    drop_views(device);  // the images of the old swapchain's size are gone with it
    outW_ = outH_ = 0;   // the next frame says the size again
    if (live(streamline_runtime())) send_options();
}

void DlssFrameGenProvider::drop_views(gpu::Device& device) {
    for (ViewSlot& s : views_) {
        if (s.view.valid()) device.destroy_view(s.view);
        s = ViewSlot{};
    }
}

// Describes one image for slSetTagForFrame: the native object, its size and the state the native section leaves it in. "" or the reason.
std::string DlssFrameGenProvider::describe(FrameGenFrame& frame, int slotIndex, std::uint32_t type, gpu::Image image,
                                           int w, int h, int& count, abi::Resource* resources, abi::ResourceTag* tags,
                                           gpu::NativeUse* uses) {
    gpu::Device& device = *frame.device;
    abi::Resource& resource = resources[count];
    abi::init_resource(resource);
    const gpu::NativeImage ni = device.native_image(image);
    resource.width = std::uint32_t(w);
    resource.height = std::uint32_t(h);
    resource.mipLevels = 1;
    resource.arrayLayers = 1;
    if (device.backend() == gpu::Backend::Vulkan) {
        ViewSlot& viewSlot = views_[slotIndex];
        if (viewSlot.view.valid() && viewSlot.image != image) {
            device.destroy_view(viewSlot.view);
            viewSlot = ViewSlot{};
        }
        if (!viewSlot.view.valid()) {
            gpu::ViewDesc v;
            v.texture.image = image;
            v.label = "dlssg-input";
            viewSlot.view = device.make_view(v);
            viewSlot.image = image;
            if (!viewSlot.view.valid())
                return "the GPU could not make a sampled view of an image DLSS frame generation reads";
        }
        const gpu::NativeView nv = device.native_view(viewSlot.view);
        if (!ni.vkImage || !nv.vkImageView)
            return "the Vulkan image or view of a DLSS frame generation input is not known to the device";
        resource.native = handle_of(ni.vkImage);
        resource.view = handle_of(nv.vkImageView);
        resource.nativeFormat = nv.nativeFormat;
        resource.mipLevels = std::uint32_t(std::max(nv.mipCount, 1));
        resource.arrayLayers = std::uint32_t(std::max(nv.sliceCount, 1));
        resource.usage = ni.vkUsage;
        resource.flags = 0;
        resource.state = kVkLayoutShaderRead;
    } else {
        if (!ni.resource) return "the device gave no native resource for a DLSS frame generation input";
        resource.native = const_cast<void*>(ni.resource);
        resource.nativeFormat = ni.nativeFormat;
        resource.state =
            frame.list->queue() == gpu::QueueKind::Compute ? kD3d12ShaderReadCompute : kD3d12ShaderReadGraphics;
    }
    abi::ResourceTag& tag = tags[count];
    abi::init_resource_tag(tag);
    tag.resource = &resource;
    tag.type = type;
    tag.lifecycle =
        abi::kValidUntilPresent;  // generation reads the images inside Present, after the frame's own passes
    tag.extent = abi::Extent{0, 0, std::uint32_t(w), std::uint32_t(h)};
    uses[count].image = image;
    uses[count].state = gpu::NativeState::ShaderRead;
    ++count;
    return {};
}

bool DlssFrameGenProvider::dispatch(FrameGenFrame& frame) {
    frame.error.clear();
    StreamlineRuntime& runtime = streamline_runtime();
    if (!frame.device || !frame.list)
        return refuse(frame, "DLSS frame generation was given no device or no command list.");
    if (!live(runtime) || frame.device != device_)
        return refuse(
            frame,
            "NVIDIA Streamline is not running on this device (the device was made again since DLSS frame generation "
            "started).");
    const StreamlineApi* sl = runtime.api();
    if (!sl) return refuse(frame, "NVIDIA Streamline is not running on this device.");
    if (!frame.depth.valid() || !frame.motion.valid())
        return refuse(frame, "DLSS frame generation needs the depth and motion images of the frame (the frame has no " +
                                 std::string(!frame.depth.valid() ? "depth" : "motion") + " image).");
    if (frame.renderW <= 0 || frame.renderH <= 0 || frame.outW <= 0 || frame.outH <= 0)
        return refuse(frame, "DLSS frame generation was given an empty picture (" + std::to_string(frame.renderW) +
                                 "x" + std::to_string(frame.renderH) + " -> " + std::to_string(frame.outW) + "x" +
                                 std::to_string(frame.outH) + ").");
    if (!frame.cameraPerspective)
        return refuse(
            frame,
            "DLSS frame generation needs a perspective camera: this frame is drawn with an orthographic one (its depth "
            "reprojection is built for a perspective lens). Use a perspective camera, or set "
            "render.frameGeneration.mode to \"off\".");
    if (!frame.depthReversed || !frame.depthInfinite)
        return refuse(
            frame,
            "DLSS frame generation was given a depth that is not the reversed infinite one it asked for (a bug in the "
            "engine's frame generation pass): please report it.");
    if (!finite_all(frame.proj, 8) || !finite_all(frame.prevFromView.m, 16) || !std::isfinite(frame.cameraNear) ||
        !std::isfinite(frame.cameraFar) || !std::isfinite(frame.cameraFovY) || std::fabs(frame.proj[0]) < 1e-6f ||
        std::fabs(frame.proj[1]) < 1e-6f || std::fabs(frame.proj[6]) < 1e-6f || !(frame.cameraNear > 0.0f))
        return refuse(
            frame,
            "the camera of this frame has a projection DLSS frame generation cannot use (a matrix with a value that is "
            "not a number, or a lens with no field of view or no near plane).");
    // Reflex: DLSS-G reports eFailReflexNotDetectedAtRuntime when the markers of the frame do not arrive. The renderer turns Reflex on while
    // this provider runs; when it cannot (its own refusal), generation is refused with the reason of that.
    if (!reflex_running())
        return refuse(
            frame,
            "DLSS frame generation needs NVIDIA Reflex running, and it is not: the engine turns Reflex on while frame "
            "generation runs, so its provider did not start. See render.supports for the reason Reflex gives, or "
            "set render.frameGeneration.mode to \"off\".");
    if (!optionsError_.empty()) return refuse(frame, optionsError_);

    // The sizes the options carry: sent again only when a size changed.
    renderW_ = frame.renderW;
    renderH_ = frame.renderH;
    outW_ = frame.outW;
    outH_ = frame.outH;
    if (!send_options()) return refuse(frame, optionsError_);

    std::string why;
    void* const token =
        runtime.frame_token(nullptr, &why);  // the same token Reflex's markers and the upscaler's evaluation use
    if (!token) return refuse(frame, why);

    abi::ViewportHandle viewport;
    abi::init_viewport(viewport, 0);

    // The constants. Streamline reads them at Present with the tags, so they are set for the frame's token.
    const auto clampf = [](float v, float limit) { return std::isfinite(v) ? std::clamp(v, -limit, limit) : 0.0f; };
    const Mat4 projection = projection_of(frame);
    const Mat4 clipToView = projection.inverse();
    // prevFromView goes from this frame's view space to the previous frame's clip space of the engine's own depth; the clip z of this
    // provider's depth is the near plane on every frame, so its row is replaced to match the depth that is tagged.
    Mat4 prevFromView = frame.prevFromView;
    prevFromView.at(0, 2) = prevFromView.at(1, 2) = prevFromView.at(2, 2) = 0.0f;
    prevFromView.at(3, 2) = frame.cameraNear;
    const Mat4 clipToPrevClip = prevFromView * clipToView;
    const Mat4 prevClipToClip = clipToPrevClip.inverse();

    abi::Constants constants;
    abi::init_constants(constants);
    constants.cameraViewToClip = to_float4x4(projection);
    constants.clipToCameraView = to_float4x4(clipToView);
    constants.clipToPrevClip = to_float4x4(clipToPrevClip);
    constants.prevClipToClip = to_float4x4(prevClipToClip);
    // The jitter is in render pixels; the motion vectors are in fractions of the picture pointing to the previous position (y down), so
    // Streamline's scale is 1.
    constants.jitterOffset = {clampf(frame.jitterX, 1.0f), clampf(frame.jitterY, 1.0f)};
    constants.mvecScale = {frame.motionScaleX, frame.motionScaleY};
    constants.cameraPos = to_float3(frame.cameraPosition);
    constants.cameraUp = to_float3(frame.cameraUp);
    constants.cameraRight = to_float3(frame.cameraRight);
    constants.cameraFwd = to_float3(frame.cameraForward);
    constants.cameraNear = frame.cameraNear;
    constants.cameraFar = frame.cameraFar;
    constants.cameraFov = frame.cameraFovY;
    constants.cameraAspectRatio = float(frame.renderW) / float(frame.renderH);
    constants.motionVectorsInvalidValue = FLT_MIN;
    constants.depthInverted = abi::kTrue;  // near / d: 1 at the near plane, towards 0 with the distance
    constants.cameraMotionIncluded = abi::kTrue;
    constants.motionVectors3d = abi::kFalse;
    constants.orthographicProjection = abi::kFalse;
    constants.motionVectorsDilated = abi::kFalse;
    constants.motionVectorsJittered = frame.motionJittered ? abi::kTrue : abi::kFalse;
    constants.reset = frame.reset ? abi::kTrue : abi::kFalse;
    if (const SlResult r = sl->setConstants(&constants, token, &viewport); r != abi::kOk) {
        // The temporal upscaler of a vendor (DLSS) sets the frame's constants too; Streamline may refuse a second set for the same frame. The
        // tags below still go out, and the frame generates from the constants that were set first.
        if (r != abi::kErrorDuplicatedConstants) return refuse(frame, streamline_refusal("slSetConstants", r));
        if (!warnedConstants_)
            FA_WARN("render",
                    "DLSS frame generation: Streamline kept the camera constants set earlier in the frame ({})",
                    streamline_result_text(r));
        warnedConstants_ = true;
    }

    // The tags: the depth and the motion of the render size, and the picture before the screen-space items when there are some.
    abi::Resource resources[3];
    abi::ResourceTag tags[3];
    gpu::NativeUse uses[3];
    int count = 0;
    {
        std::string e = describe(frame, 0, abi::kBufferDepth, frame.depth, frame.renderW, frame.renderH, count,
                                 resources, tags, uses);
        if (e.empty())
            e = describe(frame, 1, abi::kBufferMotionVectors, frame.motion, frame.renderW, frame.renderH, count,
                         resources, tags, uses);
        if (e.empty() && frame.hudDrawn && frame.hudless.valid())
            e = describe(frame, 2, abi::kBufferHudLessColor, frame.hudless, frame.outW, frame.outH, count, resources,
                         tags, uses);
        if (!e.empty()) return refuse(frame, "DLSS frame generation: " + e + ".");
    }
    const fa::Result<gpu::NativeCommands> native =
        frame.list->begin_native(std::span<const gpu::NativeUse>(uses, std::size_t(count)));
    if (!native)
        return refuse(frame,
                      "DLSS frame generation could not open a native command section: " + native.error().message);
    void* const list = const_cast<void*>(native->list);
    const SlResult tagged = sl->setTagForFrame(token, &viewport, tags, std::uint32_t(count), list);
    // The section is closed whatever Streamline answered: the images are left in the states they were declared in.
    const fa::Result<void> closed = frame.list->end_native();
    if (tagged != abi::kOk)
        return refuse(frame, "DLSS frame generation failed to tag the frame: " +
                                 streamline_refusal("slSetTagForFrame", tagged));
    if (!closed)
        return refuse(frame,
                      "DLSS frame generation tagged the frame, but its native command section could not be closed: " +
                          closed.error().message);

    // What Streamline said about the last present, read when the frame began: generation that is on and does not run says why. The frame's
    // constants and tags are sent either way, so the next present can recover without the history being lost.
    if (enabled_ && statusOn_ && (status_ & kFailMask) != 0) {
        std::string text = "DLSS frame generation is not running: ";
        if ((status_ & abi::kDlssgFailResolutionTooLow) != 0)
            text += "the picture is smaller than the SDK allows (its shorter side must be at least " +
                    std::to_string(minSize_) + " pixels): use a larger window or resolution. ";
        for (const std::uint32_t b :
             {abi::kDlssgFailReflexNotDetectedAtRuntime, abi::kDlssgFailHdrFormatNotSupported,
              abi::kDlssgFailCommonConstantsInvalid, abi::kDlssgFailGetCurrentBackBufferIndexNotCalled})
            if ((status_ & b) != 0) text += std::string(status_sentence(b)) + " ";
        text.pop_back();
        return refuse(frame, std::move(text));
    }
    return true;
}

// One slDLSSGGetState per rendered frame (the controller calls this once per frame): the status, the sizes, the estimate of the memory, and the
// frames Streamline presented since the last call. numFramesActuallyPresented counts every frame it presented, the rendered one included, so a
// frame that was generated from adds (presented - 1).
std::uint64_t DlssFrameGenProvider::generated_frames() {
    if (!live(streamline_runtime()) || !api_.getState) return generated_;
    abi::DlssgState state;
    abi::init_dlssg_state(state);
    abi::ViewportHandle viewport;
    abi::init_viewport(viewport, 0);
    if (const SlResult r = api_.getState(&viewport, &state, nullptr); r != abi::kOk) {
        if (!warnedState_) FA_WARN("render", "DLSS frame generation: {}", streamline_refusal("slDLSSGGetState", r));
        warnedState_ = true;
        return generated_;
    }
    status_ = state.status;
    statusOn_ = sent_.valid && sent_.mode == abi::kDlssgOn;
    minSize_ = state.minWidthOrHeight;
    maxFrames_ = state.numFramesToGenerateMax;
    if (state.numFramesActuallyPresented > 1) generated_ += state.numFramesActuallyPresented - 1;
    if (!loggedVram_ && state.estimatedVRAMUsageInBytes > 0) {
        loggedVram_ = true;
        FA_INFO("render", "DLSS frame generation: Streamline estimates {} MB of video memory",
                state.estimatedVRAMUsageInBytes >> 20);
    }
    return generated_;
}

void DlssFrameGenProvider::forget() {
    device_ = nullptr;
    generation_ = 0;
    api_ = DlssgApi{};
    enabled_ = false;
    retain_ = true;
    sent_ = Sent{};
    swapW_ = swapH_ = renderW_ = renderH_ = outW_ = outH_ = 0;
    status_ = minSize_ = maxFrames_ = 0;
    statusOn_ = false;
    generated_ = 0;
    loggedVram_ = warnedOptions_ = warnedState_ = warnedConstants_ = false;
    optionsError_.clear();
    for (ViewSlot& s : views_)
        s = ViewSlot{};  // the views went with their device (stop() destroys them while it is alive)
}

void DlssFrameGenProvider::stop(gpu::Device& device) {
    if (device_ != &device) return;  // it never started on this device
    StreamlineRuntime& runtime = streamline_runtime();
    // Generation off and the resources given back, only while the set-up that made the functions is still there (after the device went, the
    // library has shut down).
    if (live(runtime)) {
        // The GPU may still be running the last frame with the SDK's resources: wait, then give them back.
        if (const fa::Result<void> idle = device.wait_idle(); !idle)
            FA_WARN("render", "DLSS frame generation: {}", idle.error().message);
        enabled_ = false;
        retain_ = false;
        send_options();
        if (const StreamlineApi* sl = runtime.api(); sl && sl->freeResources) {
            abi::ViewportHandle viewport;
            abi::init_viewport(viewport, 0);
            sl->freeResources(abi::kFeatureDlssG, &viewport);
        }
    }
    drop_views(device);
    forget();
}

}  // namespace

std::unique_ptr<FrameGenProvider> make_dlss_framegen_provider() { return std::make_unique<DlssFrameGenProvider>(); }

}  // namespace fa::render
