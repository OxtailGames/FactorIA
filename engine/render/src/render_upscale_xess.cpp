// The XeSS Super Resolution provider of M78 (render_upscale_xess.h): the probe, the context of the SDK, and the frame.
#include "render_upscale_xess.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
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

// Takes `name` from the library into `fn` when it is there; a library without it is not an error (the call is optional).
template <class Fn>
void bind_optional(VendorLibrary& lib, const char* name, Fn& fn) {
    if (void* address = lib.symbol(name)) fn = reinterpret_cast<Fn>(address);  // NOLINT: the export's address
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

// Vulkan structure types of the feature structs the engine's device chains (VkStructureType values), and the bytes of each one that hold
// features: the 16-byte header (sType, pNext) and the VkBool32 members. The sizes are those of gpu/device_hooks.h's VulkanDeviceRequest.
struct FeatureStruct {
    std::int32_t type;
    std::size_t bytes;
};
constexpr FeatureStruct kFeatureStructs[] = {
    {1000059000, 16 + 55 * 4},  // VkPhysicalDeviceFeatures2
    {49, 16 + 12 * 4},          // VkPhysicalDeviceVulkan11Features
    {51, 16 + 47 * 4},          // VkPhysicalDeviceVulkan12Features
    {53, 16 + 15 * 4},          // VkPhysicalDeviceVulkan13Features
};
constexpr int kMaxFeatureStructs = 16;  // a sanity bound on a chain: a longer one (or a loop) is not XeSS's

// The chain the library answered (each struct begins with an int32 sType and a pointer to the next), copied struct by struct into `out`, which
// takes the bytes of whole feature structs. A struct of a type the engine cannot copy is an error: enabling less than XeSS asked for would
// crash it later, with no word of why.
Result<void> copy_feature_chain(const void* chain, std::vector<std::vector<std::uint8_t>>& out) {
    const std::uint8_t* at = static_cast<const std::uint8_t*>(chain);
    for (int i = 0; at; ++i) {
        if (i >= kMaxFeatureStructs)
            return make_error("XeSS's list of required device features has more than " +
                                  std::to_string(kMaxFeatureStructs) + " structs",
                              "run `factoria setup xess` to install the library again");
        struct BaseOut {  // VkBaseOutStructure
            std::int32_t sType;
            const void* pNext;
        } header{};
        std::memcpy(&header, at, sizeof header);
        const std::int32_t type = header.sType;
        const void* next = header.pNext;
        const FeatureStruct* known = nullptr;
        for (const FeatureStruct& f : kFeatureStructs)
            if (f.type == type) known = &f;
        if (!known)
            return make_error("XeSS requires the Vulkan feature struct of type " + std::to_string(type) +
                                  ", which the engine's device cannot enable yet",
                              "run the game on Direct3D 12, or tell the engine's authors which XeSS version this is");
        out.emplace_back(at, at + known->bytes);
        at = static_cast<const std::uint8_t*>(next);
    }
    return {};
}

// The name of a quality setting for a sentence.
const char* xess_quality_name(std::int32_t quality) {
    switch (quality) {
        case abi::kQualityUltraPerformance: return "ultra performance";
        case abi::kQualityPerformance: return "performance";
        case abi::kQualityBalanced: return "balanced";
        case abi::kQualityQuality: return "quality";
        case abi::kQualityUltraQuality: return "ultra quality";
        case abi::kQualityUltraQualityPlus: return "ultra quality plus";
        case abi::kQualityAa: return "AA";
        default: return "(unknown)";
    }
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
    // The library the last probe loaded: what a context made after it uses. Written by probe() and read by upscale(), under their own small
    // lock, so a probe (render.supports from the editor or MCP) never waits for a frame that is initialising a context.
    struct Loaded {
        std::shared_ptr<VendorLibrary> lib;
        XessApi api{};
        gpu::Backend backend = gpu::Backend::Recording;
    };

    // What a context was initialised for, and the GPU objects that go with it.
    struct Context {
        // gpu::Device::generation(): the address of a device made later can be the same.
        std::uint64_t deviceGeneration = 0;
        gpu::Backend backend = gpu::Backend::Recording;
        Loaded loaded;  // the library and functions this context was made with: a later probe does not change them
        abi::Context handle = nullptr;
        bool initialized = false;
        bool needReset = true;  // the next frame starts the history again (a new init, or an execute that failed)
        int renderW = 0, renderH = 0, outW = 0, outH = 0;  // renderW/H: the size the last frame was drawn at
        std::int32_t quality = 0;
        std::uint32_t flags = 0;
        // The render sizes XeSS accepts for outW x outH at `quality` (xessGetOptimalInputResolution); rangeKnown false = the library cannot say,
        // and then only the size of the init is known to work.
        bool rangeKnown = false;
        abi::Size2d inputMin{0, 0}, inputMax{0, 0};
        bool warnedDriver = false;
        // The responsive pixel mask is always on, and a frame without one gets this all-zero image of the render size.
        gpu::Image emptyMask{};
        gpu::View emptyMaskView{};
        int maskW = 0, maskH = 0;  // the size of emptyMask
        // Vulkan: the storage view of the output image (a view per output image, made when the image changes).
        gpu::Image outputImage{};
        gpu::View outputView{};
    };

    std::string ensure_context(gpu::Device& device, const UpscaleInput& in, std::int32_t quality, std::uint32_t flags);
    std::string ensure_helpers(gpu::Device& device, const VendorFrame& frame, const UpscaleInput& in);
    void free_helpers(gpu::Device& device);
    bool execute(gpu::Device& device, const UpscaleInput& in, VendorFrame& frame);

    bool in_range(const UpscaleInput& in) const;
    bool owns(const gpu::Device& device) const { return ctx_.handle && ctx_.deviceGeneration == device.generation(); }

    std::mutex
        mutex_;  // the context and the frames: held for a whole upscale() (the wait for the GPU and xessInit included)
    std::mutex loadedMutex_;  // `loaded_` only, never held across a call into the library or the device
    Loaded loaded_;
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
            const std::string hookWhy = xess_vulkan_grant().unavailableReason;
            p.reason =
                "XeSS on Vulkan needs these extensions enabled, and the engine's Vulkan device does not enable them: " +
                join(missing) + (hookWhy.empty() ? std::string() : " (" + hookWhy + ")") +
                ". Run the game on Direct3D 12, where XeSS needs none.";
            return p;
        }
        if (nd.apiVersion != 0 && req->minApiVersion != 0 && nd.apiVersion < req->minApiVersion) {
            p.reason = "XeSS on Vulkan needs Vulkan " + vulkan_version_text(req->minApiVersion) +
                       " or newer; the device runs " + vulkan_version_text(nd.apiVersion) +
                       ". Update the GPU driver, or run the game on Direct3D 12.";
            return p;
        }
    }
    // The library is kept for the contexts made after this probe (one a live context uses keeps the one it was made with). Only the small
    // lock of the library is taken: a frame that is initialising a context holds the other one, and a probe never waits for it.
    {
        std::lock_guard<std::mutex> lock(loadedMutex_);
        loaded_.lib = std::move(lib);
        loaded_.api = api;
        loaded_.backend = env.backend;
    }
    FA_DEBUG("render", "XeSS {} is available on {} ({}).", version_text(version), vendor_backend_label(env.backend),
             fa::fs::path_to_utf8(found));
    p.available = true;
    return p;
}

bool XessProvider::in_range(const UpscaleInput& in) const {
    if (!ctx_.initialized) return false;
    if (!ctx_.rangeKnown) return in.renderW == ctx_.renderW && in.renderH == ctx_.renderH;
    return std::uint32_t(in.renderW) >= ctx_.inputMin.x && std::uint32_t(in.renderW) <= ctx_.inputMax.x &&
           std::uint32_t(in.renderH) >= ctx_.inputMin.y && std::uint32_t(in.renderH) <= ctx_.inputMax.y;
}

// Makes (or keeps) the context of `device` for this frame's output, quality and flags. The context is initialised again only when one of
// those changes, or when the render size is out of what it accepts (a dynamic resolution that moves inside the range costs nothing).
// "" or the sentence of what failed.
std::string XessProvider::ensure_context(gpu::Device& device, const UpscaleInput& in, std::int32_t quality,
                                         std::uint32_t flags) {
    const gpu::Backend backend = device.backend();
    if (ctx_.handle && !owns(device)) {
        // A context of another device: that device was destroyed without release(), and the context with it.
        if (ctx_.loaded.api.destroyContext) ctx_.loaded.api.destroyContext(ctx_.handle);
        ctx_ = Context{};
    }
    const gpu::NativeDevice nd = device.native();
    if (!ctx_.handle) {
        Loaded loaded;
        {
            std::lock_guard<std::mutex> lock(loadedMutex_);
            loaded = loaded_;
        }
        if (!loaded.lib || !loaded.api.getVersion)
            return "XeSS was not found by its probe (its library is not loaded).";
        if (backend != loaded.backend)
            return "XeSS was loaded for " + std::string(vendor_backend_label(loaded.backend)) + " and this device is " +
                   vendor_backend_label(backend) + ".";
        const XessApi& api = loaded.api;
        abi::Context handle = nullptr;
        std::int32_t rc = abi::kResultSuccess;
        const char* fn = "xessD3D12CreateContext";
        switch (backend) {
            case gpu::Backend::D3d12: rc = api.d3d12Create(const_cast<void*>(nd.device), &handle); break;
            case gpu::Backend::D3d11:
                fn = "xessD3D11CreateContext";
                rc = api.d3d11Create(const_cast<void*>(nd.device), &handle);
                break;
            case gpu::Backend::Vulkan:
                fn = "xessVKCreateContext";
                rc = api.vkCreate(const_cast<void*>(nd.instance), const_cast<void*>(nd.physicalDevice),
                                  const_cast<void*>(nd.device), &handle);
                break;
            default:
                return "XeSS runs on D3D12, Vulkan and D3D11; this device is " +
                       std::string(vendor_backend_label(backend)) + ".";
        }
        if (rc < 0 || !handle) return "XeSS could not make its context: " + call_failed(fn, rc) + ".";
        ctx_ = Context{};
        ctx_.handle = handle;
        ctx_.deviceGeneration = device.generation();
        ctx_.backend = backend;
        ctx_.loaded = std::move(loaded);
        if (rc == abi::kResultWarningOldDriver) {
            ctx_.warnedDriver = true;
            FA_WARN("render", "XeSS: the installed GPU driver is older than XeSS likes: the picture may be slower or "
                              "worse than it can be. "
                              "Hint: update the GPU driver.");
        }
    }
    const XessApi& api = ctx_.loaded.api;
    const bool sameSettings = ctx_.initialized && ctx_.outW == in.outW && ctx_.outH == in.outH &&
                              ctx_.quality == quality && ctx_.flags == flags;
    // Without a range from the library, only the size of the init is known to work. With one, a size outside it cannot be helped by
    // initialising again at the same quality (the range depends on the output and the quality only), and XeSS would refuse the frame
    // without saying why: the refusal says it. Like every failure of the provider it turns XeSS off for the rest of the run (vendor_fail),
    // so the message says that and what to change for the next start. The picture is not cut or stretched to fit.
    if (sameSettings && ctx_.rangeKnown && !in_range(in))
        return "the render size " + std::to_string(in.renderW) + "x" + std::to_string(in.renderH) +
               " is outside XeSS's input range " + std::to_string(ctx_.inputMin.x) + "x" +
               std::to_string(ctx_.inputMin.y) + ".." + std::to_string(ctx_.inputMax.x) + "x" +
               std::to_string(ctx_.inputMax.y) + " for quality " + xess_quality_name(quality) + " at an output of " +
               std::to_string(in.outW) + "x" + std::to_string(in.outH) +
               ". XeSS is off for the rest of this run and the usual fallback draws; to use it, change "
               "render.upscaler.quality in "
               "factoria.json and restart.";
    if (sameSettings && (ctx_.rangeKnown || (in.renderW == ctx_.renderW && in.renderH == ctx_.renderH))) {
        if (in.renderW != ctx_.renderW || in.renderH != ctx_.renderH) {
            // A step of the dynamic resolution: the motion scale follows the render size, the history is kept.
            api.setVelocityScale(ctx_.handle, float(in.renderW), float(in.renderH));
            ctx_.renderW = in.renderW;
            ctx_.renderH = in.renderH;
            // The empty mask is as large as the first render size it served: a larger one needs a larger mask.
            if (ctx_.emptyMask.valid() && (in.renderW > ctx_.maskW || in.renderH > ctx_.maskH)) free_helpers(device);
        }
        return {};
    }
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
            rc = api.d3d12Init(ctx_.handle, &p);
            break;
        }
        case gpu::Backend::D3d11: {
            abi::D3d11InitParams p{};
            p.outputResolution = output;
            p.quality = quality;
            p.initFlags = flags;
            fn = "xessD3D11Init";
            rc = api.d3d11Init(ctx_.handle, &p);
            break;
        }
        default: {
            abi::VkInitParams p{};
            p.outputResolution = output;
            p.quality = quality;
            p.initFlags = flags;
            fn = "xessVKInit";
            rc = api.vkInit(ctx_.handle, &p);
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
    // The motion image is in UV units (the picture is 1 wide): XeSS reads pixels. The sign of the motion (previous minus current, the way
    // the temporal upscaler and MetalFX read it) and the jitter (render pixels, the engine's own sign) are passed as they are: whether
    // XeSS wants the opposite is for a run on a GPU to show (docs/UPSCALING_VENDORS.md, "Hardware check list").
    api.setVelocityScale(ctx_.handle, float(in.renderW), float(in.renderH));
    free_helpers(device);  // the empty mask is of the render size
    // The render sizes this output and quality accept: a dynamic resolution inside them does not initialise the context again.
    ctx_.rangeKnown = false;
    ctx_.inputMin = ctx_.inputMax = abi::Size2d{0, 0};
    if (api.getOptimalInputResolution) {
        abi::Size2d optimal{0, 0}, lo{0, 0}, hi{0, 0};
        if (api.getOptimalInputResolution(ctx_.handle, &output, quality, &optimal, &lo, &hi) >= 0 && lo.x > 0 &&
            lo.y > 0 && hi.x >= lo.x && hi.y >= lo.y) {
            ctx_.rangeKnown = true;
            ctx_.inputMin = lo;
            ctx_.inputMax = hi;
        }
    }
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
        ctx_.maskW = in.renderW;
        ctx_.maskH = in.renderH;
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
    ctx_.maskW = ctx_.maskH = 0;
    ctx_.outputView = {};
    ctx_.outputImage = {};
}

bool XessProvider::upscale(const UpscaleInput& in, VendorFrame& frame) {
    std::lock_guard<std::mutex> lock(mutex_);
    frame.error.clear();
    if (!frame.device || !frame.list) {
        frame.error = "XeSS was given no device or no command list.";
        return false;
    }
    gpu::Device& device = *frame.device;
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
    // Linear light above 1 (a float scene without a final pass) is XeSS's own tone-mapped input; display values are its LDR input.
    const std::uint32_t flags = abi::kInitResponsivePixelMask | (in.linear ? 0u : abi::kInitLdrInputColor);
    // The setting in use is kept while the render size is inside what XeSS accepts at that setting (a dynamic resolution moves inside the
    // range at no cost, whatever the ratio says); outside it, or with no range from the library, it is kept while the ratio stays near it,
    // and else the nearest setting is taken.
    const bool sameContext = owns(device) && ctx_.initialized;
    const bool sameOutput = sameContext && ctx_.outW == in.outW && ctx_.outH == in.outH && ctx_.flags == flags;
    std::int32_t quality;
    if (sameOutput && ctx_.rangeKnown)
        quality = in_range(in) ? ctx_.quality : xess_quality_for_ratio(ratio, 0);
    else
        quality = xess_quality_for_ratio(ratio, sameContext ? ctx_.quality : 0);
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
    const XessApi& api = ctx_.loaded.api;
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
        case gpu::Backend::D3d12: rc = api.d3d12Execute(ctx_.handle, list, &d3d12); break;
        case gpu::Backend::D3d11:
            fn = "xessD3D11Execute";
            rc = api.d3d11Execute(ctx_.handle, &d3d11);
            break;
        default:
            fn = "xessVKExecute";
            rc = api.vkExecute(ctx_.handle, list, &vk);
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
    if (!owns(device)) return;  // it never drew on this device
    if (ctx_.handle) {
        // The GPU may still be running the last frame with the context: wait, then destroy.
        if (const Result<void> idle = device.wait_idle(); !idle) FA_WARN("render", "XeSS: {}", idle.error().message);
        if (ctx_.loaded.api.destroyContext) ctx_.loaded.api.destroyContext(ctx_.handle);
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
    bind_optional(lib, "xessGetOptimalInputResolution", a.getOptimalInputResolution);
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
            bind_optional(lib, "xessVKGetRequiredDeviceFeatures", a.vkDeviceFeatures);
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
        if (api.vkDeviceFeatures) {
            void* chain = nullptr;
            if (const std::int32_t rc = api.vkDeviceFeatures(instance, physicalDevice, &chain); rc < 0)
                return make_error(call_failed("xessVKGetRequiredDeviceFeatures", rc),
                                  "run `factoria setup xess` to install the library again");
            if (Result<void> copied = copy_feature_chain(chain, out.features); !copied) return copied.error();
        }
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

namespace {
std::mutex g_hook_mutex;
std::shared_ptr<XessDeviceHook> g_process_hook;
}  // namespace

void XessDeviceHook::vulkan_instance_request(gpu::VulkanInstanceRequest& request) {
    std::lock_guard<std::mutex> lock(mutex_);
    granted_ = XessVulkanGrant{};
    askedInstance_.clear();
    askedDevice_.clear();
    installed_ = false;
    // The library is looked for here, before the instance exists: where XeSS is not installed nothing is asked and the probe says so.
    const Result<XessVulkanRequirements> req = xess_vulkan_requirements();
    if (!req) return;
    installed_ = true;
    request.extensions = req->instanceExtensions;
    askedInstance_ = req->instanceExtensions;
}

void XessDeviceHook::vulkan_device_request(const gpu::VulkanPhysicalDevice& physical,
                                           gpu::VulkanDeviceRequest& request) {
    std::lock_guard<std::mutex> lock(mutex_);
    const Result<XessVulkanRequirements> req =
        xess_vulkan_requirements(const_cast<void*>(physical.instance), const_cast<void*>(physical.physicalDevice));
    if (!req) {
        // Not installed (nothing was asked of the instance either): the probe says so. Installed but unreadable: this hook is off here.
        if (installed_)
            mark_unavailable("XeSS could not say what it needs of " + physical.name + ": " + req.error().message);
        return;
    }
    request.extensions = req->deviceExtensions;
    askedDevice_ = req->deviceExtensions;
    for (const std::vector<std::uint8_t>& f : req->features) {
        request.featureMembers.resize(request.features.size(), 0);
        request.features.push_back(f);  // a struct the engine knows is read member by member: no member count
        request.featureMembers.push_back(0);
    }
}

void XessDeviceHook::vulkan_device_created(const gpu::VulkanDeviceCreated&) {
    std::lock_guard<std::mutex> lock(mutex_);
    granted_.instanceExtensions = askedInstance_;
    granted_.deviceExtensions = askedDevice_;
}

void XessDeviceHook::device_destroying() {
    // The hook serves one live device (gpu::HookAttachment gives a second one no callbacks), so the device that goes is the one the grant is for.
    std::lock_guard<std::mutex> lock(mutex_);
    granted_ = XessVulkanGrant{};
}

XessVulkanGrant XessDeviceHook::grant() const {
    XessVulkanGrant out;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        out = granted_;
    }
    if (!available()) {
        out.instanceExtensions.clear();
        out.deviceExtensions.clear();
        out.unavailableReason = unavailable_reason();
    }
    return out;
}

std::shared_ptr<XessDeviceHook> make_xess_device_hook() { return std::make_shared<XessDeviceHook>(); }

void register_xess_device_hook() {
    std::lock_guard<std::mutex> lock(g_hook_mutex);
    if (g_process_hook) return;
    g_process_hook = make_xess_device_hook();
    gpu::register_device_hook(g_process_hook);
}

XessVulkanGrant xess_vulkan_grant() {
    std::shared_ptr<XessDeviceHook> hook;
    {
        std::lock_guard<std::mutex> lock(g_hook_mutex);
        hook = g_process_hook;
    }
    return hook ? hook->grant() : XessVulkanGrant{};
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
