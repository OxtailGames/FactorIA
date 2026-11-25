// The XeSS Super Resolution provider of M78 (render_upscale_xess.h): the probe, the context of the SDK, and the frame.
#include "render_upscale_xess.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <mutex>
#include <span>
#include <utility>

#include "fa/core/fs.h"
#include "fa/core/log.h"

namespace fa::render {

namespace {

namespace abi = xess_abi;

// The structures are the SDK's: a size that differs from the library's own is a crash, so the build says so. (Both Windows ABIs of XeSS are
// 64-bit; on a 32-bit build the provider reports itself unavailable and none of these is read.)
#if UINTPTR_MAX == 0xFFFFFFFFFFFFFFFFu
static_assert(sizeof(abi::D3d12ExecuteParams) == 136, "xess_d3d12_execute_params_t");
static_assert(sizeof(abi::D3d11ExecuteParams) == 120, "xess_d3d11_execute_params_t");
static_assert(sizeof(abi::VkImageViewInfo) == 48, "xess_vk_image_view_info");
static_assert(sizeof(abi::VkExecuteParams) == 360, "xess_vk_execute_params_t");
static_assert(sizeof(abi::D3d12InitParams) == 64, "xess_d3d12_init_params_t");
static_assert(sizeof(abi::D3d11InitParams) == 16, "xess_d3d11_init_params_t");
static_assert(sizeof(abi::VkInitParams) == 64, "xess_vk_init_params_t");
#endif

constexpr unsigned bit(gpu::Backend b) { return 1u << unsigned(b); }

struct QualityRow {
    std::int32_t setting;
    float ratio;
};
constexpr QualityRow kQualities[] = {
    {abi::kQualityAa, 1.0f},
    {abi::kQualityUltraQualityPlus, 1.3f},
    {abi::kQualityUltraQuality, 1.5f},
    {abi::kQualityQuality, 1.7f},
    {abi::kQualityBalanced, 2.0f},
    {abi::kQualityPerformance, 2.3f},
    {abi::kQualityUltraPerformance, 3.0f},
};
constexpr float kQualityHysteresis =
    0.15f;  // the settings are 0.2 apart: a band of 0.15 leaves 0.05 either side of a boundary

std::string version_text(const abi::Version& v) {
    return std::to_string(v.major) + "." + std::to_string(v.minor) + "." + std::to_string(v.patch);
}

// Takes `name` from the library into `fn`; the first one that is missing is remembered in `missing`.
template <class Fn>
void bind(VendorLibrary& lib, const char* name, Fn& fn, std::string& missing) {
    void* address = lib.symbol(name);
    if (!address) {
        if (missing.empty()) missing = name;
        return;
    }
    fn = reinterpret_cast<Fn>(address);  // NOLINT: the export's address
}

bool contains(const std::vector<std::string>& list, const std::string& name) {
    return std::find(list.begin(), list.end(), name) != list.end();
}

std::string join(const std::vector<std::string>& names) {
    std::string out;
    for (const std::string& n : names) out += (out.empty() ? "" : ", ") + n;
    return out;
}

std::string vulkan_version_text(std::uint32_t v) {
    return std::to_string((v >> 22) & 0x7F) + "." + std::to_string((v >> 12) & 0x3FF);
}

// What the library said to a call that went wrong, as the sentence of an error.
std::string call_failed(const char* function, std::int32_t result) {
    std::string text =
        std::string(function) + " answered \"" + xess_result_text(result) + "\" (" + std::to_string(result) + ")";
    if (result == -1)
        text += ": this GPU cannot run XeSS (it needs Shader Model 6.4)";
    else if (result == -2)
        text += ": the installed GPU driver is too old for XeSS; update it";
    else if (result == -5)
        text += ": the GPU is out of memory";
    return text;
}

class XessProvider final : public VendorUpscaler {
public:
    std::string_view name() const override { return "XeSS"; }
    std::string_view mode() const override { return "xess"; }
    std::string_view setup_id() const override { return "xess"; }
    unsigned backends() const override {
        return bit(gpu::Backend::D3d12) | bit(gpu::Backend::Vulkan) | bit(gpu::Backend::D3d11);
    }
    // XeSS writes the output image from a compute shader.
    bool needs_output_storage() const override { return true; }

    VendorProbe probe(const VendorEnv& env) override;
    bool upscale(const UpscaleInput& in, VendorFrame& frame) override;
    void release(gpu::Device& device) override;

private:
    // What a context was initialised for, and the GPU objects that go with it.
    struct Context {
        const gpu::Device* device = nullptr;
        gpu::Backend backend = gpu::Backend::Recording;
        abi::Context handle = nullptr;
        bool initialized = false;
        bool needReset = true;  // the next frame starts the history again (a new init, or an execute that failed)
        int renderW = 0, renderH = 0, outW = 0, outH = 0;
        std::int32_t quality = 0;
        std::uint32_t flags = 0;
        bool warnedDriver = false;
        // The responsive pixel mask is always on, and a frame without one gets this all-zero image of the render size.
        gpu::Image emptyMask{};
        gpu::View emptyMaskView{};
        // Vulkan: the storage view of the output image (a view per output image, made when the image changes).
        gpu::Image outputImage{};
        gpu::View outputView{};
    };

    std::string ensure_context(gpu::Device& device, const UpscaleInput& in, std::int32_t quality, std::uint32_t flags);
    std::string ensure_helpers(gpu::Device& device, const VendorFrame& frame, const UpscaleInput& in);
    void free_helpers(gpu::Device& device);
    bool execute(gpu::Device& device, const UpscaleInput& in, VendorFrame& frame);

    std::mutex mutex_;
    std::unique_ptr<VendorLibrary> lib_;
    XessApi api_{};
    gpu::Backend apiBackend_ = gpu::Backend::Recording;
    Context ctx_{};
};

VendorProbe XessProvider::probe(const VendorEnv& env) {
    VendorProbe p;
    // What the machine decides first: the backend and the system, then the GPU's maker (D3D11). A missing library is last: installing it is
    // of no use where the backend or the GPU cannot run XeSS.
    p.reason = vendor_environment_problem(*this, env);
    if (p.reason.empty() && sizeof(void*) != 8) p.reason = "XeSS's libraries are 64-bit; this build is not.";
    if (p.reason.empty() && env.backend == gpu::Backend::D3d11 && env.vendor != GpuVendor::Intel)
        p.reason = "XeSS on Direct3D 11 runs on Intel Arc GPUs only (its Direct3D 11 library needs the Intel driver); "
                   "this GPU is " +
                   vendor_describe_gpu(env.vendor) +
                   ". Run the game on Direct3D 12 or Vulkan, where XeSS runs on any GPU.";
    if (!p.reason.empty()) return p;

    std::string why;
    const VendorLibrarySpec spec = xess_library_spec(env.backend);
    const std::filesystem::path found = vendor_loader().find(spec, &why);
    if (found.empty()) {
        p.reason = "XeSS is not installed: run `factoria setup xess` (" + why + ").";
        return p;
    }
    std::unique_ptr<VendorLibrary> lib = vendor_loader().load(found, &why);
    if (!lib) {
        p.reason = "XeSS's library " + fa::fs::path_to_utf8(found) + " could not be loaded: " + why +
                   ". Run `factoria setup xess` to install it again.";
        return p;
    }
    XessApi api;
    if (const std::string missing = xess_load_api(*lib, env.backend, api); !missing.empty()) {
        p.reason = "XeSS's library " + lib->path() + " has no export " + missing +
                   " (it is not XeSS 3.x for this backend): run `factoria setup xess` to install the version FactorIA "
                   "was tested with.";
        return p;
    }
    abi::Version version{};
    if (const std::int32_t rc = api.getVersion(&version); rc < 0) {
        p.reason = "XeSS's library " + lib->path() +
                   " did not answer its version: " + call_failed("xessGetVersion", rc) +
                   ". Run `factoria setup xess` to install it again.";
        return p;
    }
    if (version.major < 3) {
        p.reason = "XeSS " + version_text(version) + " (" + lib->path() +
                   ") is too old: FactorIA needs XeSS 3.0 or newer (the scale factors and the API of 3.x). Run "
                   "`factoria setup xess`.";
        return p;
    }
    if (env.backend == gpu::Backend::Vulkan) {
        const gpu::NativeDevice nd = env.device ? env.device->native() : gpu::NativeDevice{};
        const Result<XessVulkanRequirements> req =
            xess_vulkan_requirements(api, const_cast<void*>(nd.instance), const_cast<void*>(nd.physicalDevice));
        if (!req) {
            p.reason = "XeSS could not say what it needs of Vulkan: " + req.error().message +
                       ". Run the game on Direct3D 12, or `factoria setup xess` to install the library again.";
            return p;
        }
        std::vector<std::string> missing;
        for (const std::string& e : req->instanceExtensions)
            if (!contains(env.vulkanInstanceExtensions, e)) missing.push_back(e + " (instance)");
        for (const std::string& e : req->deviceExtensions)
            if (!contains(env.vulkanDeviceExtensions, e)) missing.push_back(e + " (device)");
        if (!missing.empty()) {
            p.reason =
                "XeSS on Vulkan needs these extensions enabled, and the engine's Vulkan device does not enable them: " +
                join(missing) + ". Run the game on Direct3D 12, where XeSS needs none.";
            return p;
        }
        if (nd.apiVersion != 0 && req->minApiVersion != 0 && nd.apiVersion < req->minApiVersion) {
            p.reason = "XeSS on Vulkan needs Vulkan " + vulkan_version_text(req->minApiVersion) +
                       " or newer; the device runs " + vulkan_version_text(nd.apiVersion) +
                       ". Update the GPU driver, or run the game on Direct3D 12.";
            return p;
        }
    }
    // The library is kept for the frames; one that a live context uses stays (its functions are the ones the context was made with).
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (!ctx_.handle) {
            lib_ = std::move(lib);
            api_ = api;
            apiBackend_ = env.backend;
        }
    }
    p.available = true;
    return p;
}

// Makes (or keeps) the context of `device` for this frame's sizes, quality and flags. "" or the sentence of what failed.
std::string XessProvider::ensure_context(gpu::Device& device, const UpscaleInput& in, std::int32_t quality,
                                         std::uint32_t flags) {
    const gpu::Backend backend = device.backend();
    if (ctx_.handle && ctx_.device != &device) {
        // A context of another device: that device was destroyed without release(), and the context with it.
        api_.destroyContext(ctx_.handle);
        ctx_ = Context{};
    }
    const gpu::NativeDevice nd = device.native();
    if (!ctx_.handle) {
        abi::Context handle = nullptr;
        std::int32_t rc = abi::kResultSuccess;
        const char* fn = "xessD3D12CreateContext";
        switch (backend) {
            case gpu::Backend::D3d12: rc = api_.d3d12Create(const_cast<void*>(nd.device), &handle); break;
            case gpu::Backend::D3d11:
                fn = "xessD3D11CreateContext";
                rc = api_.d3d11Create(const_cast<void*>(nd.device), &handle);
                break;
            case gpu::Backend::Vulkan:
                fn = "xessVKCreateContext";
                rc = api_.vkCreate(const_cast<void*>(nd.instance), const_cast<void*>(nd.physicalDevice),
                                   const_cast<void*>(nd.device), &handle);
                break;
            default:
                return "XeSS runs on D3D12, Vulkan and D3D11; this device is " +
                       std::string(vendor_backend_label(backend)) + ".";
        }
        if (rc < 0 || !handle) return "XeSS could not make its context: " + call_failed(fn, rc) + ".";
        ctx_ = Context{};
        ctx_.handle = handle;
        ctx_.device = &device;
        ctx_.backend = backend;
        if (rc == abi::kResultWarningOldDriver) {
            ctx_.warnedDriver = true;
            FA_WARN("render", "XeSS: the installed GPU driver is older than XeSS likes: the picture may be slower or "
                              "worse than it can be. "
                              "Hint: update the GPU driver.");
        }
    }
    const bool same = ctx_.initialized && ctx_.renderW == in.renderW && ctx_.renderH == in.renderH &&
                      ctx_.outW == in.outW && ctx_.outH == in.outH && ctx_.quality == quality && ctx_.flags == flags;
    if (same) return {};
    // The GPU must be done with the context before it is initialised again (the frames in flight use its resources).
    if (ctx_.initialized) {
        if (const Result<void> idle = device.wait_idle(); !idle)
            return "the GPU did not go idle before XeSS was initialised again: " + idle.error().message + ".";
    }
    std::int32_t rc = abi::kResultSuccess;
    const char* fn = "xessD3D12Init";
    const abi::Coord output{std::uint32_t(in.outW), std::uint32_t(in.outH)};
    switch (backend) {
        case gpu::Backend::D3d12: {
            abi::D3d12InitParams p{};
            p.outputResolution = output;
            p.quality = quality;
            p.initFlags = flags;
            rc = api_.d3d12Init(ctx_.handle, &p);
            break;
        }
        case gpu::Backend::D3d11: {
            abi::D3d11InitParams p{};
            p.outputResolution = output;
            p.quality = quality;
            p.initFlags = flags;
            fn = "xessD3D11Init";
            rc = api_.d3d11Init(ctx_.handle, &p);
            break;
        }
        default: {
            abi::VkInitParams p{};
            p.outputResolution = output;
            p.quality = quality;
            p.initFlags = flags;
            fn = "xessVKInit";
            rc = api_.vkInit(ctx_.handle, &p);
            break;
        }
    }
    if (rc < 0) {
        ctx_.initialized = false;
        return "XeSS could not initialise for " + std::to_string(in.renderW) + "x" + std::to_string(in.renderH) +
               " -> " + std::to_string(in.outW) + "x" + std::to_string(in.outH) + ": " + call_failed(fn, rc) + ".";
    }
    if (rc == abi::kResultWarningOldDriver && !ctx_.warnedDriver) {
        ctx_.warnedDriver = true;
        FA_WARN("render", "XeSS: the installed GPU driver is older than XeSS likes: the picture may be slower or worse "
                          "than it can be. "
                          "Hint: update the GPU driver.");
    }
    // The motion image is in UV units (the picture is 1 wide): XeSS reads pixels.
    api_.setVelocityScale(ctx_.handle, float(in.renderW), float(in.renderH));
    if (ctx_.renderW != in.renderW || ctx_.renderH != in.renderH) free_helpers(device);
    ctx_.initialized = true;
    ctx_.needReset = true;
    ctx_.renderW = in.renderW;
    ctx_.renderH = in.renderH;
    ctx_.outW = in.outW;
    ctx_.outH = in.outH;
    ctx_.quality = quality;
    ctx_.flags = flags;
    return {};
}

// The images XeSS needs besides the frame's: the empty responsive mask (every frame without one), and on Vulkan the output's storage view.
std::string XessProvider::ensure_helpers(gpu::Device& device, const VendorFrame& frame, const UpscaleInput& in) {
    if (!frame.reactive.valid() && !ctx_.emptyMask.valid()) {
        const std::vector<std::uint8_t> zeros(std::size_t(in.renderW) * std::size_t(in.renderH), 0);
        gpu::ImageDesc d;
        d.width = in.renderW;
        d.height = in.renderH;
        d.pixelFormat = gpu::PixelFormat::R8;
        d.label = "xess-empty-responsive-mask";
        d.data.mipLevels[0] = gpu::Range{zeros.data(), zeros.size()};
        ctx_.emptyMask = device.make_image(d);
        if (!ctx_.emptyMask.valid() || device.state(ctx_.emptyMask) != gpu::ResourceState::Valid) {
            if (ctx_.emptyMask.valid()) device.destroy_image(ctx_.emptyMask);
            ctx_.emptyMask = {};
            return "the GPU could not make the empty responsive mask image XeSS reads on a frame without one.";
        }
    }
    if (device.backend() != gpu::Backend::Vulkan)
        return {};  // D3D12 and D3D11 take the resources; XeSS makes its own descriptors
    if (!frame.reactive.valid() && !ctx_.emptyMaskView.valid()) {
        gpu::ViewDesc v;
        v.texture.image = ctx_.emptyMask;
        v.label = "xess-empty-responsive-mask";
        ctx_.emptyMaskView = device.make_view(v);
        if (!ctx_.emptyMaskView.valid()) return "the GPU could not make a view of the empty responsive mask image.";
    }
    if (ctx_.outputView.valid() && ctx_.outputImage != frame.output) {
        device.destroy_view(ctx_.outputView);
        ctx_.outputView = {};
    }
    if (!ctx_.outputView.valid()) {
        gpu::ViewDesc v;
        v.storageImage.image = frame.output;
        v.label = "xess-output";
        ctx_.outputView = device.make_view(v);
        ctx_.outputImage = frame.output;
        if (!ctx_.outputView.valid())
            return "the GPU could not make the storage view of the output image (the image was not made with storage "
                   "usage).";
    }
    return {};
}

void XessProvider::free_helpers(gpu::Device& device) {
    if (ctx_.emptyMaskView.valid()) device.destroy_view(ctx_.emptyMaskView);
    if (ctx_.emptyMask.valid()) device.destroy_image(ctx_.emptyMask);
    if (ctx_.outputView.valid()) device.destroy_view(ctx_.outputView);
    ctx_.emptyMaskView = {};
    ctx_.emptyMask = {};
    ctx_.outputView = {};
    ctx_.outputImage = {};
}

bool XessProvider::upscale(const UpscaleInput& in, VendorFrame& frame) {
    std::lock_guard<std::mutex> lock(mutex_);
    frame.error.clear();
    if (!lib_ || !api_.getVersion) {
        frame.error = "XeSS was not found by its probe (its library is not loaded).";
        return false;
    }
    if (!frame.device || !frame.list) {
        frame.error = "XeSS was given no device or no command list.";
        return false;
    }
    gpu::Device& device = *frame.device;
    if (device.backend() != apiBackend_) {
        frame.error = "XeSS was loaded for " + std::string(vendor_backend_label(apiBackend_)) + " and this device is " +
                      vendor_backend_label(device.backend()) + ".";
        return false;
    }
    if (!frame.color.valid() || !frame.output.valid() || !frame.depth.valid() || !frame.velocity.valid()) {
        frame.error = "XeSS needs the colour, depth, velocity and output images of the frame (the frame has no " +
                      std::string(!frame.color.valid()      ? "colour"
                                  : !frame.depth.valid()    ? "depth"
                                  : !frame.velocity.valid() ? "velocity"
                                                            : "output") +
                      " image).";
        return false;
    }
    if (in.renderW <= 0 || in.renderH <= 0 || in.outW <= 0 || in.outH <= 0) {
        frame.error = "XeSS was given an empty picture (" + std::to_string(in.renderW) + "x" +
                      std::to_string(in.renderH) + " -> " + std::to_string(in.outW) + "x" + std::to_string(in.outH) +
                      ").";
        return false;
    }
    const float ratio = std::max(float(in.outW) / float(in.renderW), float(in.outH) / float(in.renderH));
    const bool sameDevice = ctx_.handle && ctx_.device == &device;
    const std::int32_t quality = xess_quality_for_ratio(ratio, sameDevice ? ctx_.quality : 0);
    // Linear light above 1 (a float scene without a final pass) is XeSS's own tone-mapped input; display values are its LDR input.
    const std::uint32_t flags = abi::kInitResponsivePixelMask | (in.linear ? 0u : abi::kInitLdrInputColor);
    if (std::string e = ensure_context(device, in, quality, flags); !e.empty()) {
        frame.error = std::move(e);
        return false;
    }
    if (std::string e = ensure_helpers(device, frame, in); !e.empty()) {
        frame.error = std::move(e);
        return false;
    }
    return execute(device, in, frame);
}

bool XessProvider::execute(gpu::Device& device, const UpscaleInput& in, VendorFrame& frame) {
    const gpu::Backend backend = device.backend();
    const gpu::Image mask = frame.reactive.valid() ? frame.reactive : ctx_.emptyMask;
    // Every image the SDK touches, in the state it reads or writes it in; the engine puts them there before the native section.
    gpu::NativeUse uses[5];
    uses[0].image = frame.color;
    uses[0].state = gpu::NativeState::ShaderRead;
    uses[1].image = frame.depth;
    uses[1].state = gpu::NativeState::ShaderRead;
    uses[2].image = frame.velocity;
    uses[2].state = gpu::NativeState::ShaderRead;
    uses[3].image = mask;
    uses[3].state = gpu::NativeState::ShaderRead;
    uses[4].image = frame.output;
    uses[4].state = gpu::NativeState::UnorderedAccess;

    // The handles come before the section opens: a failure here leaves the list as it was.
    const auto finite = [](float v, float limit) { return std::isfinite(v) ? std::clamp(v, -limit, limit) : 0.0f; };
    const bool reset = in.resetHistory || ctx_.needReset;
    abi::D3d12ExecuteParams d3d12{};
    abi::D3d11ExecuteParams d3d11{};
    abi::VkExecuteParams vk{};
    if (backend == gpu::Backend::Vulkan) {
        const auto info = [&](gpu::View view, int w, int h, abi::VkImageViewInfo& out,
                              const char* what) -> std::string {
            const gpu::NativeView nv = device.native_view(view);
            if (!nv.vkImageView)
                return std::string("the Vulkan image view of the ") + what + " image is not known to the device.";
            const gpu::NativeImage ni = device.native_image(nv.image);
            out.imageView = nv.vkImageView;
            out.image = ni.vkImage;
            out.aspectMask = 1;  // VK_IMAGE_ASPECT_COLOR_BIT: every image XeSS reads is a colour format here
            out.baseMipLevel = std::uint32_t(nv.mip);
            out.levelCount = std::uint32_t(std::max(nv.mipCount, 1));
            out.baseArrayLayer = std::uint32_t(nv.slice);
            out.layerCount = std::uint32_t(std::max(nv.sliceCount, 1));
            out.format = nv.nativeFormat;
            out.width = std::uint32_t(w);
            out.height = std::uint32_t(h);
            return {};
        };
        std::string e = info(in.color, in.renderW, in.renderH, vk.color, "colour");
        if (e.empty()) e = info(in.depth, in.renderW, in.renderH, vk.depth, "depth");
        if (e.empty()) e = info(in.velocity, in.renderW, in.renderH, vk.velocity, "velocity");
        if (e.empty())
            e = info(in.reactive.valid() ? in.reactive : ctx_.emptyMaskView, in.renderW, in.renderH, vk.responsiveMask,
                     "mask");
        if (e.empty()) e = info(ctx_.outputView, in.outW, in.outH, vk.output, "output");
        if (!e.empty()) {
            frame.error = "XeSS: " + e;
            return false;
        }
        vk.jitterX = finite(in.jitter[0], 0.5f);
        vk.jitterY = finite(in.jitter[1], 0.5f);
        vk.exposureScale = in.exposure > 0.0f ? in.exposure : 1.0f;
        vk.resetHistory = reset ? 1u : 0u;
        vk.inputWidth = std::uint32_t(in.renderW);
        vk.inputHeight = std::uint32_t(in.renderH);
    } else {
        const auto resource = [&](gpu::Image image) { return const_cast<void*>(device.native_image(image).resource); };
        void* const color = resource(frame.color);
        void* const depth = resource(frame.depth);
        void* const velocity = resource(frame.velocity);
        void* const maskRes = resource(mask);
        void* const output = resource(frame.output);
        if (!color || !depth || !velocity || !maskRes || !output) {
            frame.error = "XeSS: the device gave no native resource for the " +
                          std::string(!color      ? "colour"
                                      : !depth    ? "depth"
                                      : !velocity ? "velocity"
                                      : !maskRes  ? "responsive mask"
                                                  : "output") +
                          " image.";
            return false;
        }
        const auto fill = [&](auto& p) {
            p.color = color;
            p.depth = depth;
            p.velocity = velocity;
            p.responsiveMask = maskRes;
            p.output = output;
            p.jitterX = finite(in.jitter[0], 0.5f);
            p.jitterY = finite(in.jitter[1], 0.5f);
            p.exposureScale = in.exposure > 0.0f ? in.exposure : 1.0f;
            p.resetHistory = reset ? 1u : 0u;
            p.inputWidth = std::uint32_t(in.renderW);
            p.inputHeight = std::uint32_t(in.renderH);
        };
        if (backend == gpu::Backend::D3d12)
            fill(d3d12);
        else
            fill(d3d11);
    }

    const Result<gpu::NativeCommands> native = frame.list->begin_native(std::span<const gpu::NativeUse>(uses, 5));
    if (!native) {
        frame.error = "XeSS could not open a native command section: " + native.error().message;
        return false;
    }
    std::int32_t rc = abi::kResultSuccess;
    const char* fn = "xessD3D12Execute";
    void* const list = const_cast<void*>(native->list);
    switch (backend) {
        case gpu::Backend::D3d12: rc = api_.d3d12Execute(ctx_.handle, list, &d3d12); break;
        case gpu::Backend::D3d11:
            fn = "xessD3D11Execute";
            rc = api_.d3d11Execute(ctx_.handle, &d3d11);
            break;
        default:
            fn = "xessVKExecute";
            rc = api_.vkExecute(ctx_.handle, list, &vk);
            break;
    }
    // The section is closed whatever XeSS answered: the images are left in the states they were declared in.
    const Result<void> closed = frame.list->end_native();
    if (rc < 0) {
        ctx_.needReset = true;
        frame.error = "XeSS failed to draw a frame: " + call_failed(fn, rc) + ".";
        return false;
    }
    if (!closed) {
        ctx_.needReset = true;
        frame.error = "XeSS drew, but its native command section could not be closed: " + closed.error().message;
        return false;
    }
    ctx_.needReset = false;
    return true;
}

void XessProvider::release(gpu::Device& device) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (ctx_.device != &device) return;  // it never drew on this device
    if (ctx_.handle) {
        // The GPU may still be running the last frame with the context: wait, then destroy.
        if (const Result<void> idle = device.wait_idle(); !idle) FA_WARN("render", "XeSS: {}", idle.error().message);
        if (api_.destroyContext) api_.destroyContext(ctx_.handle);
    }
    free_helpers(device);
    ctx_ = Context{};
}

}  // namespace

VendorLibrarySpec xess_library_spec(gpu::Backend backend) {
    return {"xess", "FA_XESS_DIR", backend == gpu::Backend::D3d11 ? "libxess_dx11.dll" : "libxess.dll"};
}

std::string xess_load_api(VendorLibrary& lib, gpu::Backend backend, XessApi& api) {
    XessApi a;
    std::string missing;
    bind(lib, "xessGetVersion", a.getVersion, missing);
    bind(lib, "xessDestroyContext", a.destroyContext, missing);
    bind(lib, "xessSetVelocityScale", a.setVelocityScale, missing);
    switch (backend) {
        case gpu::Backend::D3d12:
            bind(lib, "xessD3D12CreateContext", a.d3d12Create, missing);
            bind(lib, "xessD3D12Init", a.d3d12Init, missing);
            bind(lib, "xessD3D12Execute", a.d3d12Execute, missing);
            break;
        case gpu::Backend::D3d11:
            bind(lib, "xessD3D11CreateContext", a.d3d11Create, missing);
            bind(lib, "xessD3D11Init", a.d3d11Init, missing);
            bind(lib, "xessD3D11Execute", a.d3d11Execute, missing);
            break;
        case gpu::Backend::Vulkan:
            bind(lib, "xessVKGetRequiredInstanceExtensions", a.vkInstanceExtensions, missing);
            bind(lib, "xessVKGetRequiredDeviceExtensions", a.vkDeviceExtensions, missing);
            bind(lib, "xessVKCreateContext", a.vkCreate, missing);
            bind(lib, "xessVKInit", a.vkInit, missing);
            bind(lib, "xessVKExecute", a.vkExecute, missing);
            break;
        default: return std::string("XeSS has no library for ") + vendor_backend_label(backend);
    }
    if (!missing.empty()) return missing;
    api = a;
    return {};
}

Result<XessVulkanRequirements> xess_vulkan_requirements(const XessApi& api, void* instance, void* physicalDevice) {
    if (!api.vkInstanceExtensions || !api.vkDeviceExtensions)
        return make_error("XeSS's Vulkan functions are not loaded",
                          "load the library for the Vulkan backend (xess_load_api)");
    constexpr std::uint32_t kMaxNames = 256;  // a sanity bound: a library that answers more is not XeSS
    XessVulkanRequirements out;
    std::uint32_t count = 0;
    const char* const* names = nullptr;
    if (const std::int32_t rc = api.vkInstanceExtensions(&count, &names, &out.minApiVersion); rc < 0)
        return make_error(call_failed("xessVKGetRequiredInstanceExtensions", rc),
                          "run `factoria setup xess` to install the library again");
    for (std::uint32_t i = 0; names && i < std::min(count, kMaxNames); ++i)
        if (names[i]) out.instanceExtensions.emplace_back(names[i]);
    if (instance && physicalDevice) {
        count = 0;
        names = nullptr;
        if (const std::int32_t rc = api.vkDeviceExtensions(instance, physicalDevice, &count, &names); rc < 0)
            return make_error(call_failed("xessVKGetRequiredDeviceExtensions", rc),
                              "run `factoria setup xess` to install the library again");
        for (std::uint32_t i = 0; names && i < std::min(count, kMaxNames); ++i)
            if (names[i]) out.deviceExtensions.emplace_back(names[i]);
    }
    return out;
}

Result<XessVulkanRequirements> xess_vulkan_requirements(void* instance, void* physicalDevice) {
    std::string why;
    const std::filesystem::path found = vendor_loader().find(xess_library_spec(gpu::Backend::Vulkan), &why);
    if (found.empty()) return make_error("XeSS is not installed (" + why + ")", "run `factoria setup xess`");
    std::unique_ptr<VendorLibrary> lib = vendor_loader().load(found, &why);
    if (!lib)
        return make_error("XeSS's library " + fa::fs::path_to_utf8(found) + " could not be loaded: " + why,
                          "run `factoria setup xess`");
    XessApi api;
    if (const std::string missing = xess_load_api(*lib, gpu::Backend::Vulkan, api); !missing.empty())
        return make_error("XeSS's library " + lib->path() + " has no export " + missing, "run `factoria setup xess`");
    return xess_vulkan_requirements(api, instance, physicalDevice);
}

float xess_quality_ratio(std::int32_t setting) {
    for (const QualityRow& row : kQualities)
        if (row.setting == setting) return row.ratio;
    return 0.0f;
}

std::int32_t xess_quality_for_ratio(float ratio, std::int32_t current) {
    if (!std::isfinite(ratio) || ratio <= 1.0f) return abi::kQualityAa;
    if (const float held = xess_quality_ratio(current); held > 0.0f && std::fabs(ratio - held) <= kQualityHysteresis)
        return current;
    std::int32_t best = kQualities[0].setting;
    float bestDistance = std::fabs(ratio - kQualities[0].ratio);
    for (const QualityRow& row : kQualities) {
        const float d = std::fabs(ratio - row.ratio);
        if (d < bestDistance) {
            best = row.setting;
            bestDistance = d;
        }
    }
    return best;
}

std::string xess_result_text(std::int32_t result) {
    switch (result) {
        case 1: return "folder does not exist";
        case 2: return "old driver";
        case 0: return "success";
        case -1: return "unsupported device";
        case -2: return "unsupported driver";
        case -3: return "uninitialized";
        case -4: return "invalid argument";
        case -5: return "device out of memory";
        case -6: return "device error";
        case -7: return "not implemented";
        case -8: return "invalid context";
        case -9: return "operation in progress";
        case -10: return "unsupported";
        case -11: return "cannot load library";
        case -12: return "wrong call order";
        case -1000: return "unknown error";
        default: break;
    }
    return "result " + std::to_string(result);
}

std::unique_ptr<VendorUpscaler> make_xess_provider() { return std::make_unique<XessProvider>(); }

}  // namespace fa::render
