// The AMD Anti-Lag 2 provider of M78 (render_latency_antilag2.h).
#include "render_latency_antilag2.h"

#include <cstdint>
#include <mutex>

#include "fa/core/log.h"

namespace fa::render {

namespace {

namespace abi = antilag2_abi;

// The structures are the SDK's: a size that differs from the driver's own is a crash, so the build says so.
#if UINTPTR_MAX == 0xFFFFFFFFFFFFFFFFu
static_assert(sizeof(abi::Guid) == 16, "GUID");
static_assert(sizeof(abi::ApiDataV1) == 32, "AMD::AntiLag2DX12 APIData_v1");
static_assert(sizeof(abi::VkPresentationInfo) == 32, "VkAntiLagPresentationInfoAMD");
static_assert(sizeof(abi::VkData) == 32, "VkAntiLagDataAMD");
static_assert(sizeof(abi::VkFeatures) == 24, "VkPhysicalDeviceAntiLagFeaturesAMD");
#endif

constexpr unsigned bit(gpu::Backend b) { return 1u << unsigned(b); }

constexpr const char* kDriverModule = "amdxc64.dll";
constexpr const char* kCreateExport = "AmdExtD3DCreateInterface";

class AntiLag2Provider final : public LatencyProvider {
public:
    std::string_view name() const override { return "AMD Anti-Lag 2"; }
    LatencyDriver driver() const override { return LatencyDriver::AntiLag2; }
    std::string_view setup_id() const override { return ""; }
    unsigned backends() const override { return bit(gpu::Backend::D3d12) | bit(gpu::Backend::Vulkan); }

    VendorProbe probe(const VendorEnv& env) override;
    std::string start(gpu::Device& device) override;
    void configure(bool enabled, bool boost, std::uint32_t minIntervalUs) override;
    void sleep(std::uint64_t frameId) override;
    void marker(LatencyMarker marker, std::uint64_t frameId) override;
    void stop(gpu::Device& device) override;

private:
    // Makes the driver's interface on `nativeDevice` (an ID3D12Device*). "" or the reason.
    std::string create_interface(const void* nativeDevice, abi::Interface*& out);
    void send_state(bool on);
    void vk_update(bool on, const abi::VkPresentationInfo* info);

    // Used from the thread that draws (the engine's main thread) only.
    const gpu::Device* device_ = nullptr;
    gpu::Backend backend_ = gpu::Backend::Recording;
    abi::Interface* iface_ = nullptr;  // D3D12
    std::unique_ptr<VendorLibrary> module_;
    const void* vkDevice_ = nullptr;  // Vulkan
    abi::VkUpdateFn vkUpdate_ = nullptr;
    bool on_ = false;
};

std::string AntiLag2Provider::create_interface(const void* nativeDevice, abi::Interface*& out) {
    out = nullptr;
    std::string why;
    std::unique_ptr<VendorLibrary> lib = vendor_loader().open_loaded(kDriverModule, &why);
    if (!lib)
        return std::string("the AMD driver's ") + kDriverModule + " is not loaded (" + why +
               "): Anti-Lag 2 is part of the Radeon driver. Update the AMD Adrenalin driver, or choose another latency "
               "mode.";
    void* fn = lib->symbol(kCreateExport);
    if (!fn)
        return std::string("the AMD driver (") + lib->path() + ") has no " + kCreateExport +
               ": it is too old for Anti-Lag 2. Update the AMD Adrenalin driver, or choose another latency mode.";
    if (nativeDevice) {
        void* made = nullptr;
        const std::int32_t hr = reinterpret_cast<abi::CreateInterfaceFn>(fn)(const_cast<void*>(nativeDevice),  // NOLINT
                                                                             &abi::kAntiLagApiIid, &made);
        if (hr < 0 || !made)
            return "the AMD driver refused Anti-Lag 2 on this GPU (" + std::string(kCreateExport) + " answered " +
                   std::to_string(hr) +
                   "): it needs a Radeon RX 7000 series or newer with a recent Adrenalin driver. Update the driver, or "
                   "choose "
                   "another latency mode.";
        out = static_cast<abi::Interface*>(made);
    }
    module_ = std::move(lib);
    return {};
}

VendorProbe AntiLag2Provider::probe(const VendorEnv& env) {
    VendorProbe p;
    p.reason = vendor_environment_problem(name(), backends(), env);
    if (p.reason.empty() && env.vendor != GpuVendor::Amd)
        p.reason = "AMD Anti-Lag 2 needs an AMD Radeon GPU; this GPU is " + vendor_describe_gpu(env.vendor) +
                   ". Choose \"auto\", which uses the SDK of the GPU's maker, or another mode.";
    if (!p.reason.empty()) {
        if (env.backend == gpu::Backend::D3d11)  // the AMD interface of Direct3D 11 is not implemented
            p.reason += " Anti-Lag 2 on Direct3D 11 is not supported by FactorIA: run the game on Direct3D 12 or "
                        "Vulkan, or choose another latency mode.";
        return p;
    }

    if (env.backend == gpu::Backend::Vulkan) {
        const std::shared_ptr<AntiLag2Hook> hook = antilag2_hook();
        if (!hook->granted()) {
            p.reason = hook->requested() && !hook->available()
                           ? "the Vulkan device was made without VK_AMD_anti_lag: " + hook->unavailable_reason() +
                                 " Update the AMD Adrenalin driver, or run the game on Direct3D 12."
                           : "the Vulkan device was made without VK_AMD_anti_lag (it is asked for when the device is "
                             "made, on an AMD "
                             "GPU, on Windows). Restart the game, or run it on Direct3D 12.";
            return p;
        }
        p.available = true;
        return p;
    }
    // Direct3D 12: the driver's module and its interface on this device (made and given back: start() makes the one that is kept).
    const gpu::NativeDevice nd = env.device ? env.device->native() : gpu::NativeDevice{};
    abi::Interface* probeIface = nullptr;
    p.reason = create_interface(nd.device, probeIface);
    if (!p.reason.empty()) return p;
    if (probeIface) probeIface->vtbl->release(probeIface);
    p.available = true;
    return p;
}

std::string AntiLag2Provider::start(gpu::Device& device) {
    stop(device);
    const gpu::NativeDevice nd = device.native();
    backend_ = device.backend();
    if (backend_ == gpu::Backend::Vulkan) {
        const std::shared_ptr<AntiLag2Hook> hook = antilag2_hook();
        if (!hook->granted() || hook->vk_device() != nd.device)
            return "the Vulkan device was made without VK_AMD_anti_lag (restart the game, or run it on Direct3D 12)";
        vkDevice_ = hook->vk_device();
        vkUpdate_ = hook->update_function();
    } else if (backend_ == gpu::Backend::D3d12) {
        if (std::string why = create_interface(nd.device, iface_); !why.empty()) return why;
        if (!iface_) return "the AMD driver made no Anti-Lag 2 interface";
        // The SDK's Initialize: the state is set, to off, before the first frame.
        abi::ApiDataV1 data{sizeof(abi::ApiDataV1), abi::kApiVersion1, abi::kModeOff, nullptr, 0, 0};
        if (const std::int32_t hr = iface_->vtbl->updateAntiLagState(iface_, &data); hr < 0) {
            iface_->vtbl->release(iface_);
            iface_ = nullptr;
            return "the AMD driver's Anti-Lag 2 interface refused its first state (answered " + std::to_string(hr) +
                   ")";
        }
    } else {
        return "AMD Anti-Lag 2 runs on Direct3D 12 and Vulkan";
    }
    device_ = &device;
    on_ = false;
    return {};
}

void AntiLag2Provider::send_state(bool on) {
    if (!iface_) return;
    abi::ApiDataV1 data{sizeof(abi::ApiDataV1), abi::kApiVersion1, on ? abi::kModeOn : abi::kModeOff, nullptr, 0, 0};
    iface_->vtbl->updateAntiLagState(iface_, &data);
}

void AntiLag2Provider::vk_update(bool on, const abi::VkPresentationInfo* info) {
    if (!vkUpdate_ || !vkDevice_) return;
    abi::VkData data{abi::kStructData, nullptr, on ? abi::kVkModeOn : abi::kVkModeOff, 0, info};
    vkUpdate_(vkDevice_, &data);
}

// `boost` and the minimum interval have no meaning in Anti-Lag 2: the driver decides the delay.
void AntiLag2Provider::configure(bool enabled, bool, std::uint32_t) {
    if (enabled == on_) return;
    on_ = enabled;
    if (backend_ == gpu::Backend::Vulkan)
        vk_update(on_, nullptr);
    else
        send_state(on_);
}

void AntiLag2Provider::sleep(std::uint64_t frameId) {
    if (!on_) return;
    if (backend_ == gpu::Backend::Vulkan) {
        const abi::VkPresentationInfo info{abi::kStructPresentationInfo, nullptr, abi::kStageInput, frameId};
        vk_update(true, &info);
    } else if (iface_) {
        iface_->vtbl->updateAntiLagState(iface_, nullptr);  // the delay: returns when the driver wants the input read
    }
}

void AntiLag2Provider::marker(LatencyMarker m, std::uint64_t frameId) {
    // Direct3D 12 has no markers outside frame generation; Vulkan wants the present stage just before vkQueuePresentKHR, with the frame
    // index of the input stage.
    if (!on_ || backend_ != gpu::Backend::Vulkan || m != LatencyMarker::PresentStart) return;
    const abi::VkPresentationInfo info{abi::kStructPresentationInfo, nullptr, abi::kStagePresent, frameId};
    vk_update(true, &info);
}

void AntiLag2Provider::stop(gpu::Device& device) {
    if (device_ != &device) return;
    if (on_) configure(false, false, 0);
    if (iface_) {
        iface_->vtbl->release(iface_);
        iface_ = nullptr;
    }
    vkDevice_ = nullptr;
    vkUpdate_ = nullptr;
    module_.reset();
    device_ = nullptr;
}

}  // namespace

std::unique_ptr<LatencyProvider> make_antilag2_provider() { return std::make_unique<AntiLag2Provider>(); }

// ---- the hook ---------------------------------------------------------------------------------------------------------------------

void AntiLag2Hook::vulkan_device_request(const gpu::VulkanPhysicalDevice& gpu, gpu::VulkanDeviceRequest& request) {
    std::lock_guard<std::mutex> lock(mutex_);
    requested_ = false;
    granted_ = false;
    if (gpu.vendorId != abi::kAmdVendorId) return;
    requested_ = true;
    request.extensions.emplace_back(abi::kVulkanExtension);
    abi::VkFeatures f{abi::kStructPhysicalDeviceFeatures, nullptr, 1};
    request.add_features(f, 1);  // one VkBool32 member; the rest of the struct is padding
}

void AntiLag2Hook::vulkan_device_created(const gpu::VulkanDeviceCreated& created) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!requested_ || !created.native.getDeviceProcAddr) return;
    using GetDeviceProcAddr = gpu::HookProcAddr (*)(const void* device, const char* name);
    const auto get =
        reinterpret_cast<GetDeviceProcAddr>(created.native.getDeviceProcAddr);  // NOLINT: PFN_vkGetDeviceProcAddr
    const gpu::HookProcAddr fn = get(created.native.device, "vkAntiLagUpdateAMD");
    if (!fn) return;
    update_ = reinterpret_cast<abi::VkUpdateFn>(fn);  // NOLINT: PFN_vkAntiLagUpdateAMD
    device_ = created.native.device;
    granted_ = true;
}

void AntiLag2Hook::device_destroying() {
    std::lock_guard<std::mutex> lock(mutex_);
    granted_ = false;
    device_ = nullptr;
    update_ = nullptr;
}

bool AntiLag2Hook::granted() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return granted_;
}
const void* AntiLag2Hook::vk_device() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return device_;
}
abi::VkUpdateFn AntiLag2Hook::update_function() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return update_;
}
bool AntiLag2Hook::requested() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return requested_;
}

std::shared_ptr<AntiLag2Hook> antilag2_hook() {
    static auto* const hook = new std::shared_ptr<AntiLag2Hook>(std::make_shared<AntiLag2Hook>());
    return *hook;
}

void register_latency_device_hooks() {
#if defined(_WIN32)
    static std::once_flag once;
    std::call_once(once, [] { gpu::register_device_hook(antilag2_hook()); });
#endif
}

}  // namespace fa::render
