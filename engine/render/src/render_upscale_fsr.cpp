// The FidelityFX Super Resolution 3.1 provider of M78 (render_upscale_fsr.h): the probe, the context of the SDK, and the frame.
#include "render_upscale_fsr.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <limits>
#include <mutex>
#include <span>
#include <utility>

#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/core/types.h"

namespace fa::render {

namespace {

namespace abi = ffx_abi;

// The structures are the SDK's: a size that differs from the library's own is a crash, so the build says so. (FidelityFX is 64-bit on every
// platform the engine runs it on; on a 32-bit build the provider reports itself unavailable and none of these is read.)
#if UINTPTR_MAX == 0xFFFFFFFFFFFFFFFFu
static_assert(sizeof(abi::Header) == 16, "ffxApiHeader");
static_assert(sizeof(abi::CreateUpscaleDesc) == 48, "ffxCreateContextDescUpscale");
static_assert(sizeof(abi::DispatchUpscaleDesc) == 432, "ffxDispatchDescUpscale");
static_assert(sizeof(abi::ResourceDescription) == 32, "FfxApiResourceDescription");
static_assert(sizeof(abi::Resource) == 48, "FfxApiResource");
static_assert(sizeof(abi::QueryGetVersions) == 56, "ffxQueryDescGetVersions");
static_assert(sizeof(abi::CreateBackendVkDesc) == 40, "ffxCreateBackendVKDesc");
static_assert(sizeof(abi::CreateBackendDx12Desc) == 24, "ffxCreateBackendDX12Desc");
#endif

constexpr unsigned bit(gpu::Backend b) { return 1u << unsigned(b); }

// The FidelityFX versions the engine was written against: 3.1 is the first with the API (ffxCreateContext...) the provider speaks.
constexpr int kMinMajor = 3, kMinMinor = 1;
constexpr std::uint64_t kMaxVersions = 64;  // a sanity bound on what GET_VERSIONS answers

struct QualityRow {
    std::int32_t mode;
    float ratio;
};
constexpr QualityRow kQualities[] = {{0, 1.0f}, {1, 1.5f}, {2, 1.7f}, {3, 2.0f}, {4, 3.0f}};

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

// The last message the library sent through the context's message callback (an error or a warning, as text), kept to explain the next failure.
// The callback has no user data, so the text lives here, under its own lock (the library may call it from its own thread).
std::mutex g_message_mutex;
std::string g_last_message;

void fsr_message(std::uint32_t /*type*/, const wchar_t* message) {
    std::string text;
    for (const wchar_t* c = message; c && *c && text.size() < 400; ++c) text += (*c > 0 && *c < 128) ? char(*c) : '?';
    std::lock_guard<std::mutex> lock(g_message_mutex);
    g_last_message = std::move(text);
}

// The message of the library since the last call, as the tail of an error sentence ("" when it said nothing).
std::string take_message() {
    std::lock_guard<std::mutex> lock(g_message_mutex);
    std::string text = std::move(g_last_message);
    g_last_message.clear();
    return text.empty() ? std::string() : " (FidelityFX said: " + text + ")";
}

// What the library said to a call that went wrong, as the sentence of an error.
std::string call_failed(const char* function, std::uint32_t code) {
    std::string text =
        std::string(function) + " answered \"" + fsr_result_text(code) + "\" (" + std::to_string(code) + ")";
    if (code == abi::kNoProvider)
        text += ": the library has no FSR provider for this GPU or driver";
    else if (code == abi::kParameterError)
        text += ": it refused a parameter (an image whose format or usage FSR does not accept, or a size over what the "
                "context was made for)";
    else if (code == abi::kMemoryError)
        text += ": the GPU is out of memory";
    text += take_message();
    return text;
}

// The newest version GET_VERSIONS names, from the library for `device`.
struct VersionAnswer {
    std::string error;        // the sentence when the query itself failed
    std::uint64_t count = 0;  // how many providers the library has for this GPU
    bool known = false;       // at least one name had a number
    int major = 0, minor = 0;
    std::string newest;  // the name of the newest provider
};

VersionAnswer query_versions(const FsrApi& api, void* device) {
    VersionAnswer answer;
    abi::QueryGetVersions q{};
    q.header.type = abi::kQueryGetVersions;
    q.createDescType = abi::kCreateUpscale;
    q.device = device;
    std::uint64_t count = 0;
    q.outputCount = &count;
    if (const abi::ReturnCode rc = api.query(nullptr, &q.header); rc != abi::kOk) {
        answer.error = call_failed("ffxQuery(get versions)", rc);
        return answer;
    }
    answer.count = count;
    if (count == 0) return answer;
    const std::uint64_t n = std::min(count, kMaxVersions);
    std::vector<std::uint64_t> ids(std::size_t(n), 0);
    std::vector<const char*> names(std::size_t(n), nullptr);
    count = n;
    q.outputCount = &count;
    q.versionIds = ids.data();
    q.versionNames = names.data();
    if (const abi::ReturnCode rc = api.query(nullptr, &q.header); rc != abi::kOk) {
        answer.error = call_failed("ffxQuery(get versions)", rc);
        return answer;
    }
    for (std::uint64_t i = 0; i < std::min(count, n); ++i) {
        int major = 0, minor = 0;
        if (!names[std::size_t(i)] || !fsr_parse_version(names[std::size_t(i)], major, minor)) continue;
        if (!answer.known || major > answer.major || (major == answer.major && minor > answer.minor)) {
            answer.known = true;
            answer.major = major;
            answer.minor = minor;
            answer.newest = names[std::size_t(i)];
        }
    }
    return answer;
}

class FsrProvider final : public VendorUpscaler {
public:
    ~FsrProvider() override {
        // The renderer calls release() before its device goes; a context still here belongs to a device nobody released.
        if (ctx_.handle && api_.destroyContext) api_.destroyContext(&ctx_.handle, nullptr);
    }
    std::string_view name() const override { return "FSR 3.1+"; }
    std::string_view mode() const override { return "fsr"; }
    std::string_view setup_id() const override { return "fidelityfx"; }
    unsigned backends() const override { return bit(gpu::Backend::D3d12) | bit(gpu::Backend::Vulkan); }
    // FSR writes the output image from a compute shader.
    bool needs_output_storage() const override { return true; }
    // FSR's depth is the inverted, infinite one (the create flags say so).
    bool wants_reversed_depth() const override { return true; }

    VendorProbe probe(const VendorEnv& env) override;
    bool upscale(const UpscaleInput& in, VendorFrame& frame) override;
    void release(gpu::Device& device) override;

private:
    // What a context was made for, and the device it belongs to.
    struct Context {
        std::uint64_t deviceGeneration =
            0;  // gpu::Device::generation(): a device made later can have the address of a destroyed one
        abi::Context handle = nullptr;
        bool needReset = true;  // the next frame starts the history again (a new context, or a dispatch that failed)
        int maxRenderW = 0, maxRenderH = 0, outW = 0, outH = 0;
        std::int32_t quality = 0;
        std::uint32_t flags = 0;
    };

    std::string ensure_context(gpu::Device& device, const UpscaleInput& in, std::int32_t quality, std::uint32_t flags);
    bool execute(gpu::Device& device, const UpscaleInput& in, VendorFrame& frame);
    void destroy_context();

    std::mutex mutex_;
    std::unique_ptr<VendorLibrary> lib_;
    FsrApi api_{};
    gpu::Backend apiBackend_ = gpu::Backend::Recording;
    Context ctx_{};
};

VendorProbe FsrProvider::probe(const VendorEnv& env) {
    VendorProbe p;
    // What the machine decides first: the backend and the system. A missing library is last: installing it is of no use where the backend
    // cannot run FSR. FSR runs on any GPU, so there is no maker check.
    p.reason = vendor_environment_problem(*this, env);
    if (p.reason.empty() && sizeof(void*) != 8) p.reason = "FidelityFX's libraries are 64-bit; this build is not.";
    if (!p.reason.empty()) return p;

    std::string why;
    const VendorLibrarySpec spec = fsr_library_spec(env.backend);
    const std::filesystem::path found = vendor_loader().find(spec, &why);
    if (found.empty()) {
        p.reason = "FSR is not installed: run `factoria setup fidelityfx` (" + why + ").";
        return p;
    }
    std::unique_ptr<VendorLibrary> lib = vendor_loader().load(found, &why);
    if (!lib) {
        p.reason = "FidelityFX's library " + fa::fs::path_to_utf8(found) + " could not be loaded: " + why +
                   ". Run `factoria setup fidelityfx` to install it again.";
        return p;
    }
    FsrApi api;
    if (const std::string missing = fsr_load_api(*lib, api); !missing.empty()) {
        p.reason = "FidelityFX's library " + lib->path() + " has no export " + missing +
                   " (it is not the FidelityFX API loader of SDK 2.x): run `factoria setup fidelityfx` to install the "
                   "version FactorIA was tested with.";
        return p;
    }
    const gpu::NativeDevice nd = env.device ? env.device->native() : gpu::NativeDevice{};
    if (env.backend == gpu::Backend::Vulkan) {
        const FsrVulkanRequirements req = fsr_vulkan_requirements();
        std::vector<std::string> missing;
        for (const std::string& e : req.instanceExtensions)
            if (!contains(env.vulkanInstanceExtensions, e)) missing.push_back(e + " (instance)");
        for (const std::string& e : req.deviceExtensions)
            if (!contains(env.vulkanDeviceExtensions, e)) missing.push_back(e + " (device)");
        if (!missing.empty()) {
            p.reason =
                "FSR on Vulkan needs these extensions enabled, and the engine's Vulkan device does not enable them: " +
                join(missing) + ". Run the game on Direct3D 12.";
            return p;
        }
        if (nd.apiVersion != 0 && req.minApiVersion != 0 && nd.apiVersion < req.minApiVersion) {
            p.reason = "FSR on Vulkan needs Vulkan " + vulkan_version_text(req.minApiVersion) +
                       " or newer; the device runs " + vulkan_version_text(nd.apiVersion) +
                       ". Update the GPU driver, or run the game on Direct3D 12.";
            return p;
        }
    }
    // The version: ask the library which FSR providers it has for this GPU (a null context: the query is made before any).
    abi::VkDeviceContext vkContext{const_cast<void*>(nd.device), const_cast<void*>(nd.physicalDevice),
                                   nd.getDeviceProcAddr};
    void* const queryDevice =
        env.backend == gpu::Backend::Vulkan ? static_cast<void*>(&vkContext) : const_cast<void*>(nd.device);
    const VersionAnswer versions = query_versions(api, queryDevice);
    if (!versions.error.empty()) {
        p.reason = "FidelityFX's library " + lib->path() + " did not list its FSR versions: " + versions.error +
                   ". Run `factoria setup fidelityfx` to install it again.";
        return p;
    }
    if (versions.count == 0) {
        p.reason =
            "FidelityFX's library " + lib->path() + " has no FSR provider for this GPU on " +
            vendor_backend_label(env.backend) +
            " (its upscaler DLL is missing next to it, or the driver is too old): run `factoria setup fidelityfx` "
            "to install the whole SDK, or update the GPU driver.";
        return p;
    }
    if (versions.known && (versions.major < kMinMajor || (versions.major == kMinMajor && versions.minor < kMinMinor))) {
        p.reason = "FidelityFX's newest FSR in " + lib->path() + " is " + versions.newest +
                   ", too old: FactorIA needs FSR 3.1 or newer (the API of the SDK 2.x loader). Run `factoria setup "
                   "fidelityfx`.";
        return p;
    }
    FA_DEBUG("render", "FSR: FidelityFX offers FSR {} on {} ({} version(s) listed)", versions.newest,
             vendor_backend_label(env.backend), versions.count);
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

void FsrProvider::destroy_context() {
    if (ctx_.handle && api_.destroyContext) {
        if (const abi::ReturnCode rc = api_.destroyContext(&ctx_.handle, nullptr); rc != abi::kOk)
            FA_WARN("render", "FSR: {}", call_failed("ffxDestroyContext", rc));
    }
    ctx_ = Context{};
}

// Makes (or keeps) the context of `device` for this frame's sizes, quality and flags. "" or the sentence of what failed.
std::string FsrProvider::ensure_context(gpu::Device& device, const UpscaleInput& in, std::int32_t quality,
                                        std::uint32_t flags) {
    if (ctx_.handle && ctx_.deviceGeneration != device.generation()) {
        // A context of another device: that device was destroyed without release(), and the context with it.
        destroy_context();
    }
    const int maxW = std::max(in.maxRenderW, in.renderW), maxH = std::max(in.maxRenderH, in.renderH);
    if (ctx_.handle && ctx_.maxRenderW == maxW && ctx_.maxRenderH == maxH && ctx_.outW == in.outW &&
        ctx_.outH == in.outH && ctx_.quality == quality && ctx_.flags == flags)
        return {};
    // The GPU must be done with the context before it goes (the frames in flight use its resources).
    if (ctx_.handle) {
        if (const Result<void> idle = device.wait_idle(); !idle)
            return "the GPU did not go idle before FSR's context was made again: " + idle.error().message + ".";
        destroy_context();
    }
    const gpu::NativeDevice nd = device.native();
    abi::CreateUpscaleDesc desc{};
    desc.header.type = abi::kCreateUpscale;
    desc.flags = flags;
    desc.maxRenderSize = {std::uint32_t(maxW), std::uint32_t(maxH)};
    desc.maxUpscaleSize = {std::uint32_t(in.outW), std::uint32_t(in.outH)};
    desc.message = &fsr_message;
    abi::Context handle = nullptr;
    abi::ReturnCode rc = abi::kOk;
    const char* const fn = "ffxCreateContext";
    {
        std::lock_guard<std::mutex> lock(g_message_mutex);
        g_last_message.clear();
    }
    switch (device.backend()) {
        case gpu::Backend::D3d12: {
            abi::CreateBackendDx12Desc backend{};
            backend.header.type = abi::kCreateBackendDx12;
            backend.device = const_cast<void*>(nd.device);
            desc.header.next = &backend.header;
            rc = api_.createContext(&handle, &desc.header, nullptr);
            break;
        }
        case gpu::Backend::Vulkan: {
            abi::CreateBackendVkDesc backend{};
            backend.header.type = abi::kCreateBackendVk;
            backend.deviceContext = {const_cast<void*>(nd.device), const_cast<void*>(nd.physicalDevice),
                                     nd.getDeviceProcAddr};
            desc.header.next = &backend.header;
            rc = api_.createContext(&handle, &desc.header, nullptr);
            if (rc == abi::kUnknownDescType || rc == abi::kNoProvider || rc == abi::kNoSupportNewDescType) {
                // FSR 3.1.4's loader knows the older Vulkan backend descriptor only.
                abi::CreateBackendVkDeprecatedDesc old{};
                old.header.type = abi::kCreateBackendVkDeprecated;
                old.deviceContext = backend.deviceContext;
                desc.header.next = &old.header;
                handle = nullptr;
                rc = api_.createContext(&handle, &desc.header, nullptr);
            }
            break;
        }
        default:
            return "FSR runs on D3D12 and Vulkan; this device is " +
                   std::string(vendor_backend_label(device.backend())) + ".";
    }
    if (rc != abi::kOk || !handle) {
        if (handle && api_.destroyContext) api_.destroyContext(&handle, nullptr);
        return "FSR could not make its context for " + std::to_string(in.renderW) + "x" + std::to_string(in.renderH) +
               " -> " + std::to_string(in.outW) + "x" + std::to_string(in.outH) + ": " + call_failed(fn, rc) + ".";
    }
    ctx_ = Context{};
    ctx_.handle = handle;
    ctx_.deviceGeneration = device.generation();
    ctx_.needReset = true;
    ctx_.maxRenderW = maxW;
    ctx_.maxRenderH = maxH;
    ctx_.outW = in.outW;
    ctx_.outH = in.outH;
    ctx_.quality = quality;
    ctx_.flags = flags;
    return {};
}

bool FsrProvider::upscale(const UpscaleInput& in, VendorFrame& frame) {
    std::lock_guard<std::mutex> lock(mutex_);
    frame.error.clear();
    if (!lib_ || !api_.dispatch) {
        frame.error = "FSR was not found by its probe (its library is not loaded).";
        return false;
    }
    if (!frame.device || !frame.list) {
        frame.error = "FSR was given no device or no command list.";
        return false;
    }
    gpu::Device& device = *frame.device;
    if (device.backend() != apiBackend_) {
        frame.error = "FSR was loaded for " + std::string(vendor_backend_label(apiBackend_)) + " and this device is " +
                      vendor_backend_label(device.backend()) + ".";
        return false;
    }
    if (!frame.color.valid() || !frame.output.valid() || !frame.depth.valid() || !frame.velocity.valid()) {
        frame.error = "FSR needs the colour, depth, velocity and output images of the frame (the frame has no " +
                      std::string(!frame.color.valid()      ? "colour"
                                  : !frame.depth.valid()    ? "depth"
                                  : !frame.velocity.valid() ? "velocity"
                                                            : "output") +
                      " image).";
        return false;
    }
    if (in.renderW <= 0 || in.renderH <= 0 || in.outW <= 0 || in.outH <= 0) {
        frame.error = "FSR was given an empty picture (" + std::to_string(in.renderW) + "x" +
                      std::to_string(in.renderH) + " -> " + std::to_string(in.outW) + "x" + std::to_string(in.outH) +
                      ").";
        return false;
    }
    const std::int32_t quality = fsr_quality_mode(in.quality);
    const std::uint32_t flags = fsr_create_flags(in.linear, in.dynamicResolutionEnabled);
    if (std::string e = ensure_context(device, in, quality, flags); !e.empty()) {
        frame.error = std::move(e);
        return false;
    }
    return execute(device, in, frame);
}

bool FsrProvider::execute(gpu::Device& device, const UpscaleInput& in, VendorFrame& frame) {
    const gpu::Backend backend = device.backend();
    // Every image the SDK touches, in the state it reads or writes it in; the engine puts them there before the native section.
    gpu::NativeUse uses[5];
    std::size_t useCount = 0;
    const auto use = [&](gpu::Image image, gpu::NativeState state) {
        uses[useCount].image = image;
        uses[useCount].state = state;
        ++useCount;
    };
    use(frame.color, gpu::NativeState::ShaderRead);
    use(frame.depth, gpu::NativeState::ShaderRead);
    use(frame.velocity, gpu::NativeState::ShaderRead);
    if (frame.reactive.valid()) use(frame.reactive, gpu::NativeState::ShaderRead);
    use(frame.output, gpu::NativeState::UnorderedAccess);

    // The handles come before the section opens: a failure here leaves the list as it was.
    const auto finite = [](float v, float limit) { return std::isfinite(v) ? std::clamp(v, -limit, limit) : 0.0f; };
    std::string missing;  // the first image the device gave no native resource for
    const auto resource = [&](gpu::Image image, std::uint32_t format, int w, int h, bool storage, const char* what) {
        abi::Resource r{};
        const gpu::NativeImage ni = device.native_image(image);
        void* handle = backend == gpu::Backend::Vulkan ? reinterpret_cast<void*>(std::uintptr_t(ni.vkImage))  // NOLINT
                                                       : const_cast<void*>(ni.resource);
        if (!handle) {
            if (missing.empty()) missing = what;
            return r;
        }
        if (format == abi::kFormatUnknown && missing.empty())
            missing = std::string(what) + " (its pixel format has no FSR name)";
        r.resource = handle;
        r.description.type = abi::kResourceTexture2d;
        r.description.format = format;
        r.description.width = std::uint32_t(w);
        r.description.height = std::uint32_t(h);
        r.description.depth = 1;
        r.description.mipCount = 1;
        r.description.usage = storage ? abi::kUsageUav : abi::kUsageReadOnly;
        r.state = storage ? abi::kStateUnorderedAccess : abi::kStatePixelComputeRead;
        return r;
    };
    abi::DispatchUpscaleDesc d{};
    d.header.type = abi::kDispatchUpscale;
    // The depth, motion and mask are the preparation pass's: R32F reversed depth, Rg16F motion in pixels' UV (FSR's sign: previous minus
    // current), R8 mask.
    d.color = resource(frame.color, fsr_surface_format(frame.colorFormat), in.renderW, in.renderH, false, "colour");
    d.depth = resource(frame.depth, abi::kFormatR32Float, in.renderW, in.renderH, false, "depth");
    d.motionVectors = resource(frame.velocity, abi::kFormatR16G16Float, in.renderW, in.renderH, false, "velocity");
    if (frame.reactive.valid())
        d.reactive = resource(frame.reactive, abi::kFormatR8Unorm, in.renderW, in.renderH, false, "reactive mask");
    d.output = resource(frame.output, fsr_surface_format(frame.outputFormat), in.outW, in.outH, true, "output");
    if (!missing.empty()) {
        frame.error = "FSR: the device gave no native resource for the " + missing + " image.";
        return false;
    }
    d.jitterOffset = {finite(in.jitter[0], 1.0f), finite(in.jitter[1], 1.0f)};
    // The motion image is in UV units (the picture is 1 wide): FSR reads pixels of the render size.
    d.motionVectorScale = {float(in.renderW), float(in.renderH)};
    d.renderSize = {std::uint32_t(in.renderW), std::uint32_t(in.renderH)};
    d.upscaleSize = {std::uint32_t(in.outW), std::uint32_t(in.outH)};
    d.enableSharpening = false;  // the engine's own sharpen is the game's choice; the FSR one is never on
    d.sharpness = 0.0f;
    d.frameTimeDelta = std::isfinite(in.frameTimeMs) && in.frameTimeMs > 0.0f ? in.frameTimeMs : 1000.0f / 60.0f;
    d.preExposure = in.exposure > 0.0f ? in.exposure : 1.0f;
    d.reset = in.resetHistory || ctx_.needReset;
    d.cameraNear = std::isfinite(in.cameraNear) && in.cameraNear > 0.0f ? in.cameraNear : 0.1f;
    d.cameraFar = std::numeric_limits<float>::max();  // the depth is infinite (FFX_UPSCALE_ENABLE_DEPTH_INFINITE)
    d.cameraFovAngleVertical = std::isfinite(in.cameraFovY) && in.cameraFovY > 0.0f ? in.cameraFovY : 1.0f;
    d.viewSpaceToMetersFactor = 1.0f;
    d.flags = fsr_dispatch_flags(in.linear);

    const Result<gpu::NativeCommands> native =
        frame.list->begin_native(std::span<const gpu::NativeUse>(uses, useCount));
    if (!native) {
        frame.error = "FSR could not open a native command section: " + native.error().message;
        return false;
    }
    d.commandList = const_cast<void*>(native->list);
    (void)take_message();  // what the library said before this call is not the reason of a failure of this one
    const abi::ReturnCode rc = api_.dispatch(&ctx_.handle, &d.header);
    // The section is closed whatever FSR answered: the images are left in the states they were declared in.
    const Result<void> closed = frame.list->end_native();
    if (rc != abi::kOk) {
        ctx_.needReset = true;
        frame.error = "FSR failed to draw a frame: " + call_failed("ffxDispatch", rc) + ".";
        return false;
    }
    if (!closed) {
        ctx_.needReset = true;
        frame.error = "FSR drew, but its native command section could not be closed: " + closed.error().message;
        return false;
    }
    ctx_.needReset = false;
    return true;
}

void FsrProvider::release(gpu::Device& device) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (ctx_.deviceGeneration != device.generation()) return;  // it never drew on this device
    if (ctx_.handle) {
        // The GPU may still be running the last frame with the context: wait, then destroy.
        if (const Result<void> idle = device.wait_idle(); !idle) FA_WARN("render", "FSR: {}", idle.error().message);
        destroy_context();
    }
    ctx_ = Context{};
}

}  // namespace

VendorLibrarySpec fsr_library_spec(gpu::Backend backend) {
    return {"fidelityfx", "FA_FIDELITYFX_DIR",
            backend == gpu::Backend::Vulkan ? "amd_fidelityfx_loader_vk.dll" : "amd_fidelityfx_loader_dx12.dll"};
}

std::string fsr_load_api(VendorLibrary& lib, FsrApi& api) {
    FsrApi a;
    std::string missing;
    bind(lib, "ffxCreateContext", a.createContext, missing);
    bind(lib, "ffxDestroyContext", a.destroyContext, missing);
    bind(lib, "ffxQuery", a.query, missing);
    bind(lib, "ffxDispatch", a.dispatch, missing);
    if (!missing.empty()) return missing;
    api = a;
    return {};
}

FsrVulkanRequirements fsr_vulkan_requirements() {
    FsrVulkanRequirements r;
    // Nothing is required of the engine's instance or device (see the header). The extensions the SDK uses when they are there:
    r.optionalDeviceExtensions = {"VK_EXT_subgroup_size_control", "VK_KHR_shader_float16_int8", "VK_KHR_16bit_storage"};
    r.minApiVersion = (1u << 22) | (1u << 12);  // Vulkan 1.1
    return r;
}

std::int32_t fsr_quality_mode(UpscalerQuality quality) {
    const int i = int(quality);
    return i >= 0 && i < kUpscalerQualityCount ? std::int32_t(i) : 0;
}

float fsr_quality_ratio(std::int32_t mode) {
    for (const QualityRow& row : kQualities)
        if (row.mode == mode) return row.ratio;
    return 0.0f;
}

std::uint32_t fsr_create_flags(bool linear, bool dynamicResolution) {
    std::uint32_t flags = abi::kEnableDepthInverted | abi::kEnableDepthInfinite;
    flags |= linear ? abi::kEnableHdr : abi::kEnableNonLinearColorSpace;
    if (dynamicResolution) flags |= abi::kEnableDynamicResolution;
    return flags;
}

std::uint32_t fsr_dispatch_flags(bool linear) { return linear ? 0u : abi::kFlagNonLinearColorSrgb; }

std::uint32_t fsr_surface_format(gpu::PixelFormat format) {
    switch (format) {
        case gpu::PixelFormat::Rgba8: return abi::kFormatR8G8B8A8Unorm;
        case gpu::PixelFormat::Srgb8A8: return abi::kFormatR8G8B8A8Srgb;
        case gpu::PixelFormat::Bgra8: return abi::kFormatB8G8R8A8Unorm;
        case gpu::PixelFormat::Sbgr8A8: return abi::kFormatB8G8R8A8Srgb;
        case gpu::PixelFormat::Rg11B10F: return abi::kFormatR11G11B10Float;
        case gpu::PixelFormat::Rgb10A2: return abi::kFormatR10G10B10A2Unorm;
        case gpu::PixelFormat::Rgba16F: return abi::kFormatR16G16B16A16Float;
        case gpu::PixelFormat::Rgba32F: return abi::kFormatR32G32B32A32Float;
        case gpu::PixelFormat::R32F: return abi::kFormatR32Float;
        case gpu::PixelFormat::Rg16F: return abi::kFormatR16G16Float;
        case gpu::PixelFormat::R8: return abi::kFormatR8Unorm;
        case gpu::PixelFormat::Rgb9E5: return abi::kFormatR9G9B9E5SharedExp;
        default: return abi::kFormatUnknown;
    }
}

std::string fsr_result_text(std::uint32_t code) {
    switch (code) {
        case abi::kOk: return "ok";
        case abi::kError: return "error";
        case abi::kUnknownDescType: return "unknown descriptor type";
        case abi::kRuntimeError: return "runtime error";
        case abi::kNoProvider: return "no provider";
        case abi::kMemoryError: return "out of memory";
        case abi::kParameterError: return "bad parameter";
        case abi::kNoSupportNewDescType: return "descriptor type not supported by the provider";
        default: break;
    }
    return "code " + std::to_string(code);
}

bool fsr_parse_version(std::string_view name, int& major, int& minor) {
    const auto digit = [](char c) { return c >= '0' && c <= '9'; };
    const auto number = [&](std::size_t& i) {
        int v = 0;
        while (i < name.size() && digit(name[i])) {
            v = std::min(v * 10 + (name[i] - '0'), 9999);
            ++i;
        }
        return v;
    };
    std::size_t i = 0;
    while (i < name.size() && !digit(name[i])) ++i;
    if (i >= name.size()) return false;
    major = number(i);
    minor = 0;
    if (i + 1 < name.size() && name[i] == '.' && digit(name[i + 1])) {
        ++i;
        minor = number(i);
    }
    return true;
}

std::unique_ptr<VendorUpscaler> make_fsr_provider() { return std::make_unique<FsrProvider>(); }

}  // namespace fa::render
