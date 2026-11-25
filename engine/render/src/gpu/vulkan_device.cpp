// The Vulkan device: the factory, the instance and the validation layer, the physical and logical device, the queue,
// the timeline semaphore and the frames in flight, the deferred releases, the capabilities, the statistics and the
// commit listeners (docs/design/ARCHITECTURE_RENDERING_VULKAN.md).
#include "gpu/vulkan_device.h"

#include <string>

#if !defined(FA_VULKAN_BACKEND)

namespace fa::gpu {

Result<std::unique_ptr<Device>> make_vulkan_device(const VulkanOptions&) {
    return make_error("gpu: the vulkan backend is not built into this binary (web and iOS builds have none)",
                      std::string("use make_device(built_sokol_backend()) here: its backend is ") +
                          backend_name(built_sokol_backend()));
}

}  // namespace fa::gpu

#else

#include <algorithm>
#include <climits>
#include <cstdio>
#include <cstring>
#include <utility>
#include <vector>

#include "fa/core/fs.h"
#include "fa/core/log.h"

namespace fa::gpu {

Result<std::unique_ptr<Device>> make_vulkan_device(const VulkanOptions& options) {
    auto device = vk::VulkanDevice::create(options);
    if (!device) return device.error();
    return std::unique_ptr<Device>(std::move(device.value()));
}

}  // namespace fa::gpu

namespace fa::gpu::vk {

namespace {

// The longest a CPU wait for the GPU may take before it is reported as a hang: a safety net far above any frame or
// readback (a loaded CI machine running lavapipe included), never a budget.
constexpr std::uint64_t kFenceWaitNs = 120ull * 1000ull * 1000ull * 1000ull;
// Command lists the device keeps for reuse, per queue; past this many a new one of that queue waits for the queue's
// oldest to finish first.
constexpr std::size_t kMaxLists = 64;
// The state a queue family ownership acquire leaves a subresource in: every stage and access of the queue may follow
// (the fix-up barriers after it narrow that down to what the list needs).
constexpr VkPipelineStageFlags2 kAcquireStages = VK_PIPELINE_STAGE_2_ALL_COMMANDS_BIT;
constexpr VkAccessFlags2 kAcquireAccess = VK_ACCESS_2_MEMORY_READ_BIT | VK_ACCESS_2_MEMORY_WRITE_BIT;
constexpr int kMaxDescriptorOption = 1048576;
constexpr const char* kValidationLayer = "VK_LAYER_KHRONOS_validation";

// major.minor of a version (no variant, no patch): what the checks compare.
std::uint32_t major_minor(std::uint32_t v) {
    return VK_MAKE_API_VERSION(0, VK_API_VERSION_MAJOR(v), VK_API_VERSION_MINOR(v), 0);
}

std::string version_text(std::uint32_t v) {
    return std::to_string(VK_API_VERSION_MAJOR(v)) + "." + std::to_string(VK_API_VERSION_MINOR(v));
}

Error vk_error(const std::string& call, VkResult r, const std::string& hint) {
    return make_error("gpu vulkan: " + call + " failed with " + result_text(r), hint);
}

int clamp_int(std::uint64_t v) { return v > std::uint64_t(INT_MAX) ? INT_MAX : int(v); }

bool has_extension(const std::vector<VkExtensionProperties>& list, const char* name) {
    for (const VkExtensionProperties& e : list)
        if (std::strcmp(e.extensionName, name) == 0) return true;
    return false;
}

const char* device_type_name(VkPhysicalDeviceType t) {
    switch (t) {
        case VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU: return "discrete GPU";
        case VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU: return "integrated GPU";
        case VK_PHYSICAL_DEVICE_TYPE_VIRTUAL_GPU: return "virtual GPU";
        case VK_PHYSICAL_DEVICE_TYPE_CPU: return "CPU";
        default: return "other";
    }
}

// Higher = preferred: a discrete GPU first, a CPU device last.
int device_type_rank(VkPhysicalDeviceType t) {
    switch (t) {
        case VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU: return 4;
        case VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU: return 3;
        case VK_PHYSICAL_DEVICE_TYPE_VIRTUAL_GPU: return 2;
        case VK_PHYSICAL_DEVICE_TYPE_CPU: return 0;
        default: return 1;
    }
}

VKAPI_ATTR VkBool32 VKAPI_CALL debug_callback(VkDebugUtilsMessageSeverityFlagBitsEXT severity,
                                              VkDebugUtilsMessageTypeFlagsEXT,
                                              const VkDebugUtilsMessengerCallbackDataEXT* data, void* user) {
    if (user && data)
        static_cast<VulkanDevice*>(user)->on_validation_message(severity, data->pMessageIdName, data->pMessage);
    return VK_FALSE;
}

}  // namespace

// ---------------------------------------------------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------------------------------------------------

std::string result_text(VkResult r) {
    struct Name {
        VkResult r;
        const char* name;
    };
    static const Name kNames[] = {
        {VK_SUCCESS, "VK_SUCCESS"},
        {VK_NOT_READY, "VK_NOT_READY"},
        {VK_TIMEOUT, "VK_TIMEOUT"},
        {VK_INCOMPLETE, "VK_INCOMPLETE"},
        {VK_ERROR_OUT_OF_HOST_MEMORY, "VK_ERROR_OUT_OF_HOST_MEMORY"},
        {VK_ERROR_OUT_OF_DEVICE_MEMORY, "VK_ERROR_OUT_OF_DEVICE_MEMORY"},
        {VK_ERROR_INITIALIZATION_FAILED, "VK_ERROR_INITIALIZATION_FAILED"},
        {VK_ERROR_DEVICE_LOST, "VK_ERROR_DEVICE_LOST"},
        {VK_ERROR_MEMORY_MAP_FAILED, "VK_ERROR_MEMORY_MAP_FAILED"},
        {VK_ERROR_LAYER_NOT_PRESENT, "VK_ERROR_LAYER_NOT_PRESENT"},
        {VK_ERROR_EXTENSION_NOT_PRESENT, "VK_ERROR_EXTENSION_NOT_PRESENT"},
        {VK_ERROR_FEATURE_NOT_PRESENT, "VK_ERROR_FEATURE_NOT_PRESENT"},
        {VK_ERROR_INCOMPATIBLE_DRIVER, "VK_ERROR_INCOMPATIBLE_DRIVER"},
        {VK_ERROR_TOO_MANY_OBJECTS, "VK_ERROR_TOO_MANY_OBJECTS"},
        {VK_ERROR_FORMAT_NOT_SUPPORTED, "VK_ERROR_FORMAT_NOT_SUPPORTED"},
        {VK_ERROR_FRAGMENTED_POOL, "VK_ERROR_FRAGMENTED_POOL"},
        {VK_ERROR_OUT_OF_POOL_MEMORY, "VK_ERROR_OUT_OF_POOL_MEMORY"},
        {VK_ERROR_FRAGMENTATION, "VK_ERROR_FRAGMENTATION"},
        {VK_ERROR_UNKNOWN, "VK_ERROR_UNKNOWN"},
    };
    const char* name = "unknown VkResult";
    for (const Name& n : kNames)
        if (n.r == r) name = n.name;
    return std::string(name) + " (" + std::to_string(int(r)) + ")";
}

// ---------------------------------------------------------------------------------------------------------------------
// Creation
// ---------------------------------------------------------------------------------------------------------------------

Result<std::unique_ptr<VulkanDevice>> VulkanDevice::create(const VulkanOptions& options) {
    // Contradictions in the options first, before any Vulkan work.
    if (options.framesInFlight < 1 || options.framesInFlight > 3)
        return make_error("gpu vulkan: VulkanOptions::framesInFlight is " + std::to_string(options.framesInFlight) +
                              ", outside 1..3",
                          "use 2 (the engine's kInflightFrames) unless a test needs another count");
    if (options.uploadRingBytes < 64u * 1024u || options.uploadRingBytes > (std::size_t(1) << 30))
        return make_error("gpu vulkan: VulkanOptions::uploadRingBytes is " + std::to_string(options.uploadRingBytes) +
                              ", outside 64 KiB..1 GiB",
                          "the default (32 MiB) suits the renderer; a test of the ring's wrap uses 64 KiB");
    if (options.memoryBlockBytes < (std::size_t(1) << 20) || options.memoryBlockBytes > (std::size_t(1) << 30))
        return make_error("gpu vulkan: VulkanOptions::memoryBlockBytes is " + std::to_string(options.memoryBlockBytes) +
                              ", outside 1 MiB..1 GiB",
                          "the default (64 MiB) suits the renderer");
    if (options.dedicatedThreshold < 1024u || options.dedicatedThreshold > options.memoryBlockBytes)
        return make_error("gpu vulkan: VulkanOptions::dedicatedThreshold is " +
                              std::to_string(options.dedicatedThreshold) + ", outside 1 KiB..memoryBlockBytes (" +
                              std::to_string(options.memoryBlockBytes) + ")",
                          "a resource of this many bytes or more takes memory of its own: keep it at most one block");
    const struct {
        int value;
        int min;
        const char* name;
    } counts[] = {
        {options.frameDescriptorSets, 1, "frameDescriptorSets"},
        {options.frameDescriptors, 1, "frameDescriptors"},
        {options.bindlessDescriptors, 0, "bindlessDescriptors"},
    };
    for (const auto& c : counts)
        if (c.value < c.min || c.value > kMaxDescriptorOption)
            return make_error("gpu vulkan: VulkanOptions::" + std::string(c.name) + " is " + std::to_string(c.value) +
                                  ", outside " + std::to_string(c.min) + "..1048576",
                              "the defaults (4096 sets, 32768 descriptors of each kind, 32768 bindless slots) suit "
                              "the renderer");
    if (options.frameDescriptorPools < 1 || options.frameDescriptorPools > 64)
        return make_error("gpu vulkan: VulkanOptions::frameDescriptorPools is " +
                              std::to_string(options.frameDescriptorPools) + ", outside 1..64",
                          "the default (8) lets a frame take up to eight times frameDescriptorSets sets; 1 keeps a "
                          "frame to one pool (a test of the pool's limit)");

    std::unique_ptr<VulkanDevice> d(new VulkanDevice());
    if (auto r = d->init(options); !r) return r.error();
    return d;
}

Result<void> VulkanDevice::init_instance(const VulkanOptions& options) {
    auto lib = open_vulkan_library(options.loaderPath);
    if (!lib) return lib.error();
    library_ = std::move(lib.value());
    const PFN_vkGetInstanceProcAddr gipa = library_.getInstanceProcAddr;
#define FA_VK_LOAD_GLOBAL(name) fn_.name = reinterpret_cast<PFN_##name>(gipa(VK_NULL_HANDLE, #name));
    FA_VK_GLOBAL_FUNCTIONS(FA_VK_LOAD_GLOBAL)
#undef FA_VK_LOAD_GLOBAL
    if (!fn_.vkCreateInstance || !fn_.vkEnumerateInstanceExtensionProperties || !fn_.vkEnumerateInstanceLayerProperties)
        return make_error("gpu vulkan: " + library_.path + " gives no vkCreateInstance (not a working Vulkan loader)",
                          "install the system's Vulkan loader, or point VulkanOptions::loaderPath at it");
    std::uint32_t loaderVersion = VK_API_VERSION_1_0;
    if (fn_.vkEnumerateInstanceVersion) fn_.vkEnumerateInstanceVersion(&loaderVersion);
    if (major_minor(loaderVersion) < VK_API_VERSION_1_2)
        return make_error("gpu vulkan: the Vulkan loader " + library_.path + " is version " +
                              version_text(loaderVersion) + "; the Vulkan backend needs 1.2",
                          "update the Vulkan loader and the GPU driver");
    const std::uint32_t requested = std::min(major_minor(loaderVersion), std::uint32_t(VK_API_VERSION_1_3));

    std::uint32_t n = 0;
    fn_.vkEnumerateInstanceExtensionProperties(nullptr, &n, nullptr);
    std::vector<VkExtensionProperties> extensions(n);
    if (n) fn_.vkEnumerateInstanceExtensionProperties(nullptr, &n, extensions.data());
    extensions.resize(n);
    std::vector<const char*> enabled;
    debugUtils_ = has_extension(extensions, VK_EXT_DEBUG_UTILS_EXTENSION_NAME);
    if (debugUtils_) enabled.push_back(VK_EXT_DEBUG_UTILS_EXTENSION_NAME);
    const bool portabilityEnumeration = has_extension(extensions, VK_KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME);
    if (portabilityEnumeration) enabled.push_back(VK_KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME);
    // The window's extensions where the loader has them (a headless device needs none): the surface, this platform's
    // surfaces, the HDR colour spaces.
    const char* platformSurface = platform_surface_extension();
    surfaceExtension_ = platformSurface && has_extension(extensions, VK_KHR_SURFACE_EXTENSION_NAME) &&
                        has_extension(extensions, platformSurface);
    if (surfaceExtension_) {
        enabled.push_back(VK_KHR_SURFACE_EXTENSION_NAME);
        enabled.push_back(platformSurface);
        colorspaceExtension_ = has_extension(extensions, VK_EXT_SWAPCHAIN_COLOR_SPACE_EXTENSION_NAME);
        if (colorspaceExtension_) enabled.push_back(VK_EXT_SWAPCHAIN_COLOR_SPACE_EXTENSION_NAME);
    }

    std::vector<const char*> layers;
    bool syncValidation = false;  // VulkanOptions::synchronizationValidation, with a layer that has it
    if (options.validation) {
        const std::string prepared = prepare_validation_layer();
        if (!prepared.empty()) FA_INFO("render", "gpu vulkan: {}", prepared);
        n = 0;
        fn_.vkEnumerateInstanceLayerProperties(&n, nullptr);
        std::vector<VkLayerProperties> available(n);
        if (n) fn_.vkEnumerateInstanceLayerProperties(&n, available.data());
        available.resize(n);
        bool found = false;
        for (const VkLayerProperties& l : available)
            if (std::strcmp(l.layerName, kValidationLayer) == 0) found = true;
        if (found) {
            layers.push_back(kValidationLayer);
            validation_ = true;
            if (options.synchronizationValidation) {
                // VK_EXT_validation_features comes from the layer itself: ask the layer for its extensions.
                n = 0;
                fn_.vkEnumerateInstanceExtensionProperties(kValidationLayer, &n, nullptr);
                std::vector<VkExtensionProperties> layerExtensions(n);
                if (n) fn_.vkEnumerateInstanceExtensionProperties(kValidationLayer, &n, layerExtensions.data());
                layerExtensions.resize(n);
                if (has_extension(layerExtensions, VK_EXT_VALIDATION_FEATURES_EXTENSION_NAME)) {
                    enabled.push_back(VK_EXT_VALIDATION_FEATURES_EXTENSION_NAME);
                    syncValidation = true;
                } else {
                    const std::string w =
                        "gpu vulkan: the validation layer has no VK_EXT_validation_features: synchronization "
                        "validation is off (update the validation layers)";
                    FA_WARN("render", "{}", w);
                    std::lock_guard<std::mutex> lock(msgMutex_);
                    warnings_.push_back(w);
                }
            }
        } else {
            const std::string w =
                "gpu vulkan: the validation layer (VK_LAYER_KHRONOS_validation) is not installed: the device runs "
                "without it (Debian/Ubuntu: apt install vulkan-validationlayers; macOS: brew install "
                "vulkan-validationlayers; Windows: the Vulkan SDK)";
            FA_WARN("render", "{}", w);
            std::lock_guard<std::mutex> lock(msgMutex_);
            warnings_.push_back(w);
        }
    }

    VkApplicationInfo app{};
    app.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
    app.pApplicationName = "FactorIA";
    app.pEngineName = "FactorIA";
    app.apiVersion = requested;
    VkDebugUtilsMessengerCreateInfoEXT messenger{};
    messenger.sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT;
    messenger.messageSeverity =
        VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT | VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT;
    messenger.messageType = VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT |
                            VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT |
                            VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT;
    messenger.pfnUserCallback = debug_callback;
    messenger.pUserData = this;
    // Synchronization validation: hazards between commands (a read after a write without a barrier, a write after a
    // read) become validation errors too.
    const VkValidationFeatureEnableEXT syncFeature = VK_VALIDATION_FEATURE_ENABLE_SYNCHRONIZATION_VALIDATION_EXT;
    VkValidationFeaturesEXT features{};
    features.sType = VK_STRUCTURE_TYPE_VALIDATION_FEATURES_EXT;
    features.enabledValidationFeatureCount = 1;
    features.pEnabledValidationFeatures = &syncFeature;
    void* messengerChain = (validation_ && debugUtils_) ? &messenger : nullptr;  // messages of vkCreateInstance itself
    if (syncValidation) features.pNext = messengerChain;
    VkInstanceCreateInfo ci{};
    ci.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    ci.pNext = syncValidation ? static_cast<void*>(&features) : messengerChain;
    ci.flags = portabilityEnumeration ? VK_INSTANCE_CREATE_ENUMERATE_PORTABILITY_BIT_KHR : 0;
    ci.pApplicationInfo = &app;
    ci.enabledExtensionCount = std::uint32_t(enabled.size());
    ci.ppEnabledExtensionNames = enabled.data();
    ci.enabledLayerCount = std::uint32_t(layers.size());
    ci.ppEnabledLayerNames = layers.data();
    std::size_t errorsBefore = 0;
    {
        std::lock_guard<std::mutex> lock(msgMutex_);
        errorsBefore = errors_.size();
    }
    VkResult r = fn_.vkCreateInstance(&ci, nullptr, &instance_);
    if (r == VK_ERROR_LAYER_NOT_PRESENT && !layers.empty()) {
        // The loader lists the layer but cannot open its library (a manifest whose library path does not resolve):
        // run without it, as when it is not installed, and keep what the failed attempt reported as warnings.
        const std::string w =
            "gpu vulkan: the validation layer (VK_LAYER_KHRONOS_validation) is listed but its library "
            "could not be loaded: the device runs without it (reinstall the validation layers, or "
            "point VK_ADD_LAYER_PATH at a manifest whose library_path is absolute)";
        FA_WARN("render", "{}", w);
        {
            std::lock_guard<std::mutex> lock(msgMutex_);
            for (std::size_t i = errorsBefore; i < errors_.size(); ++i) warnings_.push_back(errors_[i]);
            errors_.resize(errorsBefore);
            warnings_.push_back(w);
        }
        layers.clear();
        validation_ = false;
        instance_ = VK_NULL_HANDLE;
        if (syncValidation) {  // the layer's own extension goes with it
            enabled.erase(std::remove_if(enabled.begin(), enabled.end(),
                                         [](const char* e) {
                                             return std::strcmp(e, VK_EXT_VALIDATION_FEATURES_EXTENSION_NAME) == 0;
                                         }),
                          enabled.end());
            syncValidation = false;
        }
        ci.pNext = nullptr;
        ci.enabledExtensionCount = std::uint32_t(enabled.size());
        ci.ppEnabledExtensionNames = enabled.data();
        ci.enabledLayerCount = 0;
        ci.ppEnabledLayerNames = nullptr;
        r = fn_.vkCreateInstance(&ci, nullptr, &instance_);
    }
    if (r == VK_ERROR_INCOMPATIBLE_DRIVER)
        return make_error("gpu vulkan: no Vulkan device: the loader " + library_.path +
                              " found no driver (vkCreateInstance: " + result_text(r) + ")",
                          "install a Vulkan driver (Linux: mesa-vulkan-drivers, which has the CPU driver lavapipe; "
                          "macOS: brew install molten-vk)");
    if (r == VK_ERROR_INITIALIZATION_FAILED)
        return make_error("gpu vulkan: no Vulkan device: vkCreateInstance failed with VK_ERROR_INITIALIZATION_FAILED "
                          "(the loader " +
                              library_.path + " found a driver it could not start)",
                          "install or repair the Vulkan driver (Linux: mesa-vulkan-drivers, which has the CPU driver "
                          "lavapipe), or point VK_DRIVER_FILES at a working driver manifest");
    if (r != VK_SUCCESS || !instance_)
        return vk_error("vkCreateInstance (Vulkan " + version_text(requested) + ")", r,
                        "update the Vulkan loader and the GPU driver");

#define FA_VK_LOAD_INSTANCE(name) fn_.name = reinterpret_cast<PFN_##name>(gipa(instance_, #name));
    FA_VK_INSTANCE_FUNCTIONS(FA_VK_LOAD_INSTANCE)
    if (debugUtils_) {
        FA_VK_DEBUG_FUNCTIONS(FA_VK_LOAD_INSTANCE)
    }
    if (surfaceExtension_) {
        FA_VK_SURFACE_FUNCTIONS(FA_VK_LOAD_INSTANCE)
        if (!fn_.vkDestroySurfaceKHR || !fn_.vkGetPhysicalDeviceSurfaceSupportKHR ||
            !fn_.vkGetPhysicalDeviceSurfaceCapabilitiesKHR || !fn_.vkGetPhysicalDeviceSurfaceFormatsKHR ||
            !fn_.vkGetPhysicalDeviceSurfacePresentModesKHR)
            surfaceExtension_ = false;  // create_swapchain says there is no window path
    }
#undef FA_VK_LOAD_INSTANCE
#define FA_VK_CHECK_INSTANCE(name)                                                                                     \
    if (!fn_.name)                                                                                                     \
        return make_error("gpu vulkan: the loader " + library_.path + " gives no " #name,                              \
                          "update the Vulkan loader (Vulkan 1.2 or later)");
    FA_VK_INSTANCE_FUNCTIONS(FA_VK_CHECK_INSTANCE)
#undef FA_VK_CHECK_INSTANCE

    if (validation_ && fn_.vkCreateDebugUtilsMessengerEXT) {
        r = fn_.vkCreateDebugUtilsMessengerEXT(instance_, &messenger, nullptr, &messenger_);
        if (r != VK_SUCCESS) {
            messenger_ = VK_NULL_HANDLE;
            FA_WARN("render",
                    "gpu vulkan: vkCreateDebugUtilsMessengerEXT failed with {}: validation messages go to "
                    "the console only",
                    result_text(r));
        }
    }
    apiVersion_ = requested;
    syncValidation_ = syncValidation;
    return {};
}

Result<void> VulkanDevice::init_device(const VulkanOptions& options) {
    std::uint32_t n = 0;
    VkResult r = fn_.vkEnumeratePhysicalDevices(instance_, &n, nullptr);
    std::vector<VkPhysicalDevice> devices(n);
    if (n) r = fn_.vkEnumeratePhysicalDevices(instance_, &n, devices.data());
    devices.resize(r == VK_SUCCESS || r == VK_INCOMPLETE ? n : 0);

    std::string tried;
    int best = -1;
    VkPhysicalDevice chosen = VK_NULL_HANDLE;
    std::uint32_t chosenFamily = 0;
    for (VkPhysicalDevice pd : devices) {
        VkPhysicalDeviceProperties p{};
        fn_.vkGetPhysicalDeviceProperties(pd, &p);
        const std::string name = std::string(p.deviceName) + " (" + device_type_name(p.deviceType) + ", Vulkan " +
                                 version_text(p.apiVersion) + ")";
        auto skip = [&](const std::string& why) { tried += (tried.empty() ? "" : "; ") + name + ": " + why; };
        if (major_minor(p.apiVersion) < VK_API_VERSION_1_2) {
            skip("Vulkan 1.2 is needed");
            continue;
        }
        if (options.cpuDevice && p.deviceType != VK_PHYSICAL_DEVICE_TYPE_CPU) {
            skip("not a CPU device");
            continue;
        }
        std::uint32_t qn = 0;
        fn_.vkGetPhysicalDeviceQueueFamilyProperties(pd, &qn, nullptr);
        std::vector<VkQueueFamilyProperties> families(qn);
        if (qn) fn_.vkGetPhysicalDeviceQueueFamilyProperties(pd, &qn, families.data());
        std::uint32_t family = UINT32_MAX;
        for (std::uint32_t i = 0; i < qn; ++i) {
            const VkQueueFlags want = VK_QUEUE_GRAPHICS_BIT | VK_QUEUE_COMPUTE_BIT;
            if ((families[i].queueFlags & want) == want && families[i].queueCount > 0) {
                family = i;
                break;
            }
        }
        if (family == UINT32_MAX) {
            skip("no queue does graphics and compute");
            continue;
        }
        VkPhysicalDeviceVulkan12Features f12{};
        f12.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES;
        VkPhysicalDeviceFeatures2 f2{};
        f2.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2;
        f2.pNext = &f12;
        fn_.vkGetPhysicalDeviceFeatures2(pd, &f2);
        if (!f12.timelineSemaphore) {
            skip("no timeline semaphores");
            continue;
        }
        const int rank = device_type_rank(p.deviceType);
        if (rank > best) {
            best = rank;
            chosen = pd;
            chosenFamily = family;
        }
    }
    if (!chosen) {
        if (options.cpuDevice)
            return make_error("gpu vulkan: no CPU Vulkan device (VulkanOptions::cpuDevice)" +
                                  (tried.empty() ? std::string(": the loader lists no device") : ": tried " + tried),
                              "install Mesa's lavapipe (Debian/Ubuntu: apt install mesa-vulkan-drivers), or ask for "
                              "a hardware GPU (cpuDevice = false)");
        return make_error("gpu vulkan: no Vulkan device has Vulkan 1.2, timeline semaphores and a graphics + compute "
                          "queue" +
                              (tried.empty() ? std::string(" (the loader lists no device)") : ": tried " + tried),
                          "update the GPU driver, or install Mesa's lavapipe for a CPU device (apt install "
                          "mesa-vulkan-drivers)");
    }
    physical_ = chosen;
    fn_.vkGetPhysicalDeviceProperties(physical_, &props_);
    deviceName_ = props_.deviceName;
    cpuDevice_ = props_.deviceType == VK_PHYSICAL_DEVICE_TYPE_CPU;
    apiVersion_ = std::min(apiVersion_, major_minor(props_.apiVersion));

    std::uint32_t qn = 0;
    fn_.vkGetPhysicalDeviceQueueFamilyProperties(physical_, &qn, nullptr);
    std::vector<VkQueueFamilyProperties> families(qn);
    if (qn) fn_.vkGetPhysicalDeviceQueueFamilyProperties(physical_, &qn, families.data());
    families.resize(qn);
    // The queues (VulkanOptions::queues). Async compute: a compute-only family, else a second queue of the graphics
    // family, else (OtherFamilies) another family that computes. Transfer, only next to an async compute queue: a
    // transfer-only family that copies single texels, else (OtherFamilies) a third family that does.
    const std::uint32_t gfx = chosenFamily;
    using Q = VulkanOptions::Queues;
    std::uint32_t computeFamily = UINT32_MAX, computeIndex = 0, transferFamily = UINT32_MAX;
    auto texel_copies = [&](std::uint32_t i) {
        const VkExtent3D g = families[i].minImageTransferGranularity;
        return g.width == 1 && g.height == 1 && g.depth == 1;
    };
    if (options.queues != Q::GraphicsOnly && gfx < qn) {
        for (std::uint32_t i = 0; i < qn && computeFamily == UINT32_MAX; ++i) {
            const VkQueueFlags f = families[i].queueFlags;
            if ((f & VK_QUEUE_COMPUTE_BIT) && !(f & VK_QUEUE_GRAPHICS_BIT) && families[i].queueCount > 0)
                computeFamily = i;
        }
        if (computeFamily == UINT32_MAX && families[gfx].queueCount >= 2) {
            computeFamily = gfx;
            computeIndex = 1;
        }
        for (std::uint32_t i = 0; i < qn && computeFamily == UINT32_MAX && options.queues == Q::OtherFamilies; ++i)
            if (i != gfx && (families[i].queueFlags & VK_QUEUE_COMPUTE_BIT) && families[i].queueCount > 0)
                computeFamily = i;
        for (std::uint32_t i = 0; i < qn && computeFamily != UINT32_MAX && transferFamily == UINT32_MAX; ++i) {
            const VkQueueFlags f = families[i].queueFlags;
            if ((f & VK_QUEUE_TRANSFER_BIT) && !(f & (VK_QUEUE_GRAPHICS_BIT | VK_QUEUE_COMPUTE_BIT)) &&
                families[i].queueCount > 0 && texel_copies(i))
                transferFamily = i;
        }
        // Every family that draws or computes also copies (the spec does not make it say so).
        constexpr VkQueueFlags kCopies = VK_QUEUE_TRANSFER_BIT | VK_QUEUE_GRAPHICS_BIT | VK_QUEUE_COMPUTE_BIT;
        for (std::uint32_t i = 0; i < qn && computeFamily != UINT32_MAX && transferFamily == UINT32_MAX &&
                                  options.queues == Q::OtherFamilies;
             ++i)
            if (i != gfx && i != computeFamily && (families[i].queueFlags & kCopies) && families[i].queueCount > 0 &&
                texel_copies(i))
                transferFamily = i;
    }
    auto set_queue = [&](QueueKind kind, std::uint32_t family, std::uint32_t index) {
        QueueRecord& q = queues_[int(kind)];
        q.own = true;
        q.family = family;
        q.index = index;
        q.timestampBits = family < qn ? families[family].timestampValidBits : 0u;
    };
    set_queue(QueueKind::Graphics, gfx, 0);
    if (computeFamily != UINT32_MAX) set_queue(QueueKind::Compute, computeFamily, computeIndex);
    if (transferFamily != UINT32_MAX) set_queue(QueueKind::Transfer, transferFamily, 0);
    resolved_[int(QueueKind::Graphics)] = QueueKind::Graphics;
    resolved_[int(QueueKind::Compute)] =
        queues_[int(QueueKind::Compute)].own ? QueueKind::Compute : QueueKind::Graphics;
    resolved_[int(QueueKind::Transfer)] =
        queues_[int(QueueKind::Transfer)].own ? QueueKind::Transfer : resolved_[int(QueueKind::Compute)];

    n = 0;
    fn_.vkEnumerateDeviceExtensionProperties(physical_, nullptr, &n, nullptr);
    std::vector<VkExtensionProperties> extensions(n);
    if (n) fn_.vkEnumerateDeviceExtensionProperties(physical_, nullptr, &n, extensions.data());
    extensions.resize(n);
    std::vector<const char*> enabled;
    portability_ = has_extension(extensions, VK_KHR_PORTABILITY_SUBSET_EXTENSION_NAME);
    if (portability_) enabled.push_back(VK_KHR_PORTABILITY_SUBSET_EXTENSION_NAME);
    swapchainExtension_ = surfaceExtension_ && has_extension(extensions, VK_KHR_SWAPCHAIN_EXTENSION_NAME);
    if (swapchainExtension_) enabled.push_back(VK_KHR_SWAPCHAIN_EXTENSION_NAME);
    hdrMetadataExtension_ =
        swapchainExtension_ && colorspaceExtension_ && has_extension(extensions, VK_EXT_HDR_METADATA_EXTENSION_NAME);
    if (hdrMetadataExtension_) enabled.push_back(VK_EXT_HDR_METADATA_EXTENSION_NAME);
    const bool core13 = apiVersion_ >= VK_API_VERSION_1_3;
    const bool sync2Extension = !core13 && has_extension(extensions, VK_KHR_SYNCHRONIZATION_2_EXTENSION_NAME);

    // What the device has.
    VkPhysicalDeviceVulkan12Features q12{};
    q12.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES;
    VkPhysicalDeviceVulkan13Features q13{};
    q13.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_3_FEATURES;
    VkPhysicalDeviceSynchronization2FeaturesKHR qSync2{};
    qSync2.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SYNCHRONIZATION_2_FEATURES_KHR;
    VkPhysicalDevicePortabilitySubsetFeaturesKHR qPort{};
    qPort.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PORTABILITY_SUBSET_FEATURES_KHR;
    VkPhysicalDeviceFeatures2 q2{};
    q2.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2;
    q2.pNext = &q12;
    void** tail = &q12.pNext;
    if (core13) {
        *tail = &q13;
        tail = &q13.pNext;
    } else if (sync2Extension) {
        *tail = &qSync2;
        tail = &qSync2.pNext;
    }
    if (portability_) *tail = &qPort;
    fn_.vkGetPhysicalDeviceFeatures2(physical_, &q2);

    // What the backend turns on.
    VkPhysicalDeviceVulkan12Features e12{};
    e12.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES;
    e12.timelineSemaphore = VK_TRUE;
    descriptorIndexing_ = q12.descriptorIndexing && q12.runtimeDescriptorArray && q12.descriptorBindingPartiallyBound &&
                          q12.descriptorBindingSampledImageUpdateAfterBind;
    if (descriptorIndexing_) {
        e12.descriptorIndexing = VK_TRUE;
        e12.runtimeDescriptorArray = VK_TRUE;
        e12.descriptorBindingPartiallyBound = VK_TRUE;
        e12.descriptorBindingSampledImageUpdateAfterBind = VK_TRUE;
    }
    VkPhysicalDeviceVulkan13Features e13{};
    e13.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_3_FEATURES;
    VkPhysicalDeviceSynchronization2FeaturesKHR eSync2{};
    eSync2.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SYNCHRONIZATION_2_FEATURES_KHR;
    bool sync2 = false;
    if (options.synchronization2) {
        if (core13 && q13.synchronization2) {
            e13.synchronization2 = VK_TRUE;
            sync2 = true;
        } else if (sync2Extension && qSync2.synchronization2) {
            eSync2.synchronization2 = VK_TRUE;
            enabled.push_back(VK_KHR_SYNCHRONIZATION_2_EXTENSION_NAME);
            sync2 = true;
        }
    }
    VkPhysicalDevicePortabilitySubsetFeaturesKHR ePort = qPort;  // everything the subset has
    ePort.pNext = nullptr;
    VkPhysicalDeviceFeatures2 e2{};
    e2.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2;
    e2.pNext = &e12;
    tail = &e12.pNext;
    if (core13) {
        *tail = &e13;
        tail = &e13.pNext;
    } else if (eSync2.synchronization2) {
        *tail = &eSync2;
        tail = &eSync2.pNext;
    }
    if (portability_) *tail = &ePort;
    const VkPhysicalDeviceFeatures& q = q2.features;
    VkPhysicalDeviceFeatures& e = e2.features;
    e.samplerAnisotropy = q.samplerAnisotropy;
    e.independentBlend = q.independentBlend;
    e.dualSrcBlend = q.dualSrcBlend;
    e.depthBiasClamp = q.depthBiasClamp;
    e.imageCubeArray = q.imageCubeArray;
    e.shaderStorageImageReadWithoutFormat = q.shaderStorageImageReadWithoutFormat;
    e.shaderStorageImageWriteWithoutFormat = q.shaderStorageImageWriteWithoutFormat;
    // the compressed families the device has (an image of a family whose feature is off is invalid usage)
    e.textureCompressionBC = q.textureCompressionBC;
    e.textureCompressionETC2 = q.textureCompressionETC2;
    e.textureCompressionASTC_LDR = q.textureCompressionASTC_LDR;
    anisotropy_ = q.samplerAnisotropy == VK_TRUE;
    depthBiasClamp_ = q.depthBiasClamp == VK_TRUE;
    imageView2DOn3D_ = !portability_ || qPort.imageView2DOn3DImage;
    imageView2DOn3DReal_ = imageView2DOn3D_;
    features_.mrtIndependentBlendState = q.independentBlend == VK_TRUE;
    features_.mrtIndependentWriteMask = q.independentBlend == VK_TRUE;
    features_.dualSourceBlending = q.dualSrcBlend == VK_TRUE;

    // One create info per family, with as many queues as its highest index needs (the async compute queue may be the
    // graphics family's second).
    const float priorities[2] = {1.0f, 1.0f};
    VkDeviceQueueCreateInfo queues[kQueueKinds]{};
    std::uint32_t queueInfos = 0;
    for (const QueueRecord& rec : queues_) {
        if (!rec.own) continue;
        VkDeviceQueueCreateInfo* info = nullptr;
        for (std::uint32_t i = 0; i < queueInfos; ++i)
            if (queues[i].queueFamilyIndex == rec.family) info = &queues[i];
        if (!info) {
            info = &queues[queueInfos++];
            info->sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
            info->queueFamilyIndex = rec.family;
            info->pQueuePriorities = priorities;
        }
        info->queueCount = std::max(info->queueCount, rec.index + 1);
    }
    VkDeviceCreateInfo dci{};
    dci.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
    dci.pNext = &e2;
    dci.queueCreateInfoCount = queueInfos;
    dci.pQueueCreateInfos = queues;
    dci.enabledExtensionCount = std::uint32_t(enabled.size());
    dci.ppEnabledExtensionNames = enabled.data();
    r = fn_.vkCreateDevice(physical_, &dci, nullptr, &device_);
    if (r != VK_SUCCESS || !device_) return vk_error("vkCreateDevice on " + deviceName_, r, "update the GPU driver");

    // A function the driver does not give: the device is destroyed here (the destructor may not have
    // vkDestroyDevice) and the error names the function.
    auto missing = [this](const char* name) {
        auto destroy = reinterpret_cast<PFN_vkDestroyDevice>(fn_.vkGetDeviceProcAddr(device_, "vkDestroyDevice"));
        if (destroy) destroy(device_, nullptr);
        device_ = VK_NULL_HANDLE;
        return make_error("gpu vulkan: the driver of " + deviceName_ + " gives no " + name,
                          "update the GPU driver (Vulkan 1.2 or later)");
    };
#define FA_VK_LOAD_DEVICE(name)                                                                                        \
    fn_.name = reinterpret_cast<PFN_##name>(fn_.vkGetDeviceProcAddr(device_, #name));                                  \
    if (!fn_.name) return missing(#name);
    FA_VK_DEVICE_FUNCTIONS(FA_VK_LOAD_DEVICE)
#undef FA_VK_LOAD_DEVICE
    if (swapchainExtension_) {
#define FA_VK_LOAD_SWAPCHAIN(name)                                                                                     \
    fn_.name = reinterpret_cast<PFN_##name>(fn_.vkGetDeviceProcAddr(device_, #name));                                  \
    if (!fn_.name) swapchainExtension_ = false;  // create_swapchain says there is no window path
        FA_VK_SWAPCHAIN_FUNCTIONS(FA_VK_LOAD_SWAPCHAIN)
#undef FA_VK_LOAD_SWAPCHAIN
    }
    if (hdrMetadataExtension_)
        fn_.vkSetHdrMetadataEXT =
            reinterpret_cast<PFN_vkSetHdrMetadataEXT>(fn_.vkGetDeviceProcAddr(device_, "vkSetHdrMetadataEXT"));
    if (sync2)
        fn_.vkCmdPipelineBarrier2 = reinterpret_cast<PFN_vkCmdPipelineBarrier2>(
            fn_.vkGetDeviceProcAddr(device_, core13 ? "vkCmdPipelineBarrier2" : "vkCmdPipelineBarrier2KHR"));

    // Each queue and its timeline semaphore.
    VkSemaphoreTypeCreateInfo type{};
    type.sType = VK_STRUCTURE_TYPE_SEMAPHORE_TYPE_CREATE_INFO;
    type.semaphoreType = VK_SEMAPHORE_TYPE_TIMELINE;
    type.initialValue = 0;
    VkSemaphoreCreateInfo sci{};
    sci.sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;
    sci.pNext = &type;
    for (int k = 0; k < kQueueKinds; ++k) {
        QueueRecord& rec = queues_[k];
        if (!rec.own) continue;
        const std::string name = std::string("fa-vulkan-") + queue_name(QueueKind(k));
        fn_.vkGetDeviceQueue(device_, rec.family, rec.index, &rec.queue);
        set_name(VK_OBJECT_TYPE_QUEUE, handle_bits(rec.queue), (name + "-queue").c_str());
        r = fn_.vkCreateSemaphore(device_, &sci, nullptr, &rec.timeline);
        if (r != VK_SUCCESS) {
            rec.timeline = VK_NULL_HANDLE;
            return vk_error("vkCreateSemaphore (the " + std::string(queue_name(QueueKind(k))) + " queue's timeline)", r,
                            "the device was lost or is out of memory");
        }
        set_name(VK_OBJECT_TYPE_SEMAPHORE, handle_bits(rec.timeline), (name + "-timeline").c_str());
    }
    return {};
}

Result<void> VulkanDevice::init(const VulkanOptions& options) {
    framesInFlight_ = options.framesInFlight;
    if (auto r = init_instance(options); !r) return r;
    if (auto r = init_device(options); !r) return r;

    VkPhysicalDeviceMemoryProperties mp{};
    fn_.vkGetPhysicalDeviceMemoryProperties(physical_, &mp);
    memory_.init(this, mp, VkDeviceSize(options.memoryBlockBytes), VkDeviceSize(options.dedicatedThreshold));

    const DeviceInit& in = options.init;
    buffers_.init(in.bufferPoolSize);
    images_.init(in.imagePoolSize);
    views_.init(in.viewPoolSize);
    samplers_.init(in.samplerPoolSize);
    shaders_.init(in.shaderPoolSize);
    pipelines_.init(in.pipelinePoolSize);
    {
        // The pipelines of an earlier run, from VulkanOptions::pipelineCacheFile (vulkan_pipeline_cache.cpp checks
        // every byte the driver would trust; a file that does not match this device is thrown away with a warning).
        cacheFile_ = options.pipelineCacheFile;
        const std::vector<std::uint8_t> initial = load_pipeline_cache_file();
        VkPipelineCacheCreateInfo ci{};
        ci.sType = VK_STRUCTURE_TYPE_PIPELINE_CACHE_CREATE_INFO;
        ci.initialDataSize = initial.size();
        ci.pInitialData = initial.empty() ? nullptr : initial.data();
        VkResult r = fn_.vkCreatePipelineCache(device_, &ci, nullptr, &pipelineCache_);
        if (r != VK_SUCCESS && !initial.empty()) {
            // The driver refused data that passed every check: start empty, and the next save replaces the file.
            cache_warning("gpu vulkan: the driver refused the pipeline cache " + fs::path_to_utf8(cacheFile_) +
                          " (vkCreatePipelineCache: " + result_text(r) +
                          "); its pipelines are compiled again and the file is written anew (hint: nothing to fix; "
                          "deleting the file clears the cache)");
            ++cacheDiscarded_;
            cacheDirty_ = true;
            cacheLoadedSha256_.clear();
            cacheFileBytes_ = 0;
            ci.initialDataSize = 0;
            ci.pInitialData = nullptr;
            r = fn_.vkCreatePipelineCache(device_, &ci, nullptr, &pipelineCache_);
        } else if (r == VK_SUCCESS && !initial.empty()) {
            cacheLoaded_ = true;
        }
        if (r != VK_SUCCESS) {
            pipelineCache_ = VK_NULL_HANDLE;
            return vk_error("vkCreatePipelineCache", r, "the device is out of memory");
        }
        set_name(VK_OBJECT_TYPE_PIPELINE_CACHE, handle_bits(pipelineCache_), "fa-vulkan-pipeline-cache");
    }

    std::uint32_t bindless = std::uint32_t(options.bindlessDescriptors);
    if (bindless > 0 && !descriptorIndexing_) {
        const std::string w = "gpu vulkan: " + deviceName_ +
                              " has no descriptor indexing (update-after-bind sampled images): the device has no "
                              "bindless table (VulkanOptions::bindlessDescriptors is ignored)";
        FA_WARN("render", "{}", w);
        std::lock_guard<std::mutex> lock(msgMutex_);
        warnings_.push_back(w);
        bindless = 0;
    }
    if (bindless > 0) {
        VkPhysicalDeviceVulkan11Properties p11{};
        p11.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_1_PROPERTIES;
        VkPhysicalDeviceVulkan12Properties p12{};
        p12.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_PROPERTIES;
        p12.pNext = &p11;
        VkPhysicalDeviceProperties2 p2{};
        p2.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2;
        p2.pNext = &p12;
        fn_.vkGetPhysicalDeviceProperties2(physical_, &p2);
        // Every pipeline layout has the bindless set next to its own sets 0 and 1: a stage keeps room for a shader's
        // own views, uniform blocks and colour attachments, which count against the same per-stage limits.
        auto less = [](std::uint32_t a, std::uint32_t b) { return a > b ? a - b : 0u; };
        const std::uint32_t own = std::uint32_t(kMaxViews + kMaxUniformBlocks + kMaxColorAttachments);
        const std::uint32_t most = std::min({less(std::min(p12.maxPerStageDescriptorUpdateAfterBindSampledImages,
                                                           p12.maxDescriptorSetUpdateAfterBindSampledImages),
                                                  std::uint32_t(kMaxViews)),
                                             less(p12.maxPerStageUpdateAfterBindResources, own)});
        if (bindless > most) {
            const std::string w = "gpu vulkan: VulkanOptions::bindlessDescriptors is " + std::to_string(bindless) +
                                  ", more than the " + std::to_string(most) + " sampled images " + deviceName_ +
                                  " binds in one stage next to a shader's own " + std::to_string(kMaxViews) +
                                  " views, uniform blocks and attachments: the bindless table holds " +
                                  std::to_string(most);
            FA_WARN("render", "{}", w);
            std::lock_guard<std::mutex> lock(msgMutex_);
            warnings_.push_back(w);
            bindless = most;
        }
        // Over maxPerSetDescriptors only the driver knows whether the set can be made (MoltenVK: 1212 on Apple GPUs).
        if (bindless > p11.maxPerSetDescriptors && !DescriptorPools::bindless_supported(*this, bindless)) {
            const std::uint32_t fits = std::max<std::uint32_t>(1u, p11.maxPerSetDescriptors);
            const std::string w = "gpu vulkan: VulkanOptions::bindlessDescriptors is " + std::to_string(bindless) +
                                  ", a set larger than " + deviceName_ + " supports (maxPerSetDescriptors " +
                                  std::to_string(p11.maxPerSetDescriptors) + "): the bindless table holds " +
                                  std::to_string(fits);
            FA_WARN("render", "{}", w);
            std::lock_guard<std::mutex> lock(msgMutex_);
            warnings_.push_back(w);
            bindless = fits;
        }
    }
    if (auto r = descriptors_.init(*this, framesInFlight_, std::uint32_t(options.frameDescriptorSets),
                                   std::uint32_t(options.frameDescriptors), std::uint32_t(options.frameDescriptorPools),
                                   bindless);
        !r)
        return r;

    // The ring hands out offsets aligned to at most 256 bytes: a size in whole 64 KiB blocks keeps every one inside it.
    const VkDeviceSize ringBytes = align_up(options.uploadRingBytes, 64u * 1024u);
    std::string error;
    ringBuffer_ = make_raw_buffer(ringBytes, VK_BUFFER_USAGE_TRANSFER_SRC_BIT | VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT,
                                  MemoryUse::Upload, true, "fa-vulkan-upload-ring", error);
    if (!ringBuffer_)
        return make_error("gpu vulkan: the upload ring (" + std::to_string(ringBytes) + " bytes): " + error,
                          "lower VulkanOptions::uploadRingBytes");
    ring_.init(ringBuffer_->buffer, ringBuffer_->memory.mapped, std::size_t(ringBytes));
    imageUploadAlign_ = std::size_t(
        std::clamp<VkDeviceSize>(std::max<VkDeviceSize>(16, props_.limits.optimalBufferCopyOffsetAlignment), 16, 256));

    const EnvironmentDefaults& env = in.environment.defaults;
    defaults_.colorFormat = env.colorFormat != PixelFormat::Default ? env.colorFormat : PixelFormat::Bgra8;
    defaults_.depthFormat = env.depthFormat != PixelFormat::Default ? env.depthFormat : PixelFormat::DepthStencil;
    defaults_.sampleCount = env.sampleCount > 0 ? env.sampleCount : 1;
    info_.backend = Backend::Vulkan;
    info_.metalTarget = MetalTarget::None;
    info_.name = backend_name(Backend::Vulkan);
    init_caps();
    FA_INFO("render", "gpu vulkan: {} ({}, Vulkan {}{}{}{}), {} frames in flight, loader {}", deviceName_,
            device_type_name(props_.deviceType), version_text(apiVersion_), validation_ ? ", validation layer" : "",
            synchronization2_active() ? ", synchronization2" : "", portability_ ? ", portability subset" : "",
            framesInFlight_, library_.path);
    init_timer();
    return {};
}

void VulkanDevice::init_caps() {
    Features& f = features_;  // the blend features were set by init_device
    f.originTopLeft = true;
    f.imageClampToBorder = true;
    f.compute = true;
    f.msaaTextureBindings = true;
    f.separateBufferTypes = false;
    f.drawBaseVertex = true;
    f.drawBaseInstance = true;
    VkFormatProperties vp{};
    fn_.vkGetPhysicalDeviceFormatProperties(physical_, VK_FORMAT_A2B10G10R10_SNORM_PACK32, &vp);
    f.vertexFormatInt10N2 = (vp.bufferFeatures & VK_FORMAT_FEATURE_VERTEX_BUFFER_BIT) != 0;
    f.copyBufferToImageRelaxedBufferType = true;
    f.copyBufferToImageRelaxedBytesPerRow = true;  // unaligned rows are repacked on the GPU (copy_buffer_to_image)
    f.glTextureViews = false;
    // M77-P10c: an async compute queue when init_device found one; recording on several threads (each list has a
    // command pool of its own, the shared state is under locks); the bindless table when it was made.
    f.asyncCompute = queues_[int(QueueKind::Compute)].own;
    f.multiThreadRecording = true;
    f.bindless = descriptors_.bindless_capacity() > 0;

    const VkPhysicalDeviceLimits& d = props_.limits;
    Limits& l = limits_;
    l.maxImageSize2d = clamp_int(d.maxImageDimension2D);
    l.maxImageSizeCube = clamp_int(d.maxImageDimensionCube);
    l.maxImageSize3d = clamp_int(d.maxImageDimension3D);
    l.maxImageSizeArray = clamp_int(d.maxImageDimension2D);
    l.maxImageArrayLayers = clamp_int(d.maxImageArrayLayers);
    l.maxVertexAttrs = std::min(clamp_int(d.maxVertexInputAttributes), kMaxVertexAttributes);
    l.maxColorAttachments = std::min(clamp_int(d.maxColorAttachments), kMaxColorAttachments);
    l.maxTextureBindingsPerStage = std::min(clamp_int(d.maxPerStageDescriptorSampledImages), kMaxViews);
    l.maxStorageBufferBindingsPerStage = std::min(clamp_int(d.maxPerStageDescriptorStorageBuffers), kMaxViews);
    l.maxStorageImageBindingsPerStage = std::min(clamp_int(d.maxPerStageDescriptorStorageImages), kMaxViews);
    l.vkMinUniformBufferOffsetAlignment = clamp_int(d.minUniformBufferOffsetAlignment);

    // DepthStencil: D24S8 where the device renders to it (most desktop GPUs), D32S8 elsewhere (Apple GPUs).
    VkFormatProperties ds{};
    fn_.vkGetPhysicalDeviceFormatProperties(physical_, VK_FORMAT_D24_UNORM_S8_UINT, &ds);
    depthStencilFormat_ = (ds.optimalTilingFeatures & VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT)
                              ? VK_FORMAT_D24_UNORM_S8_UINT
                              : VK_FORMAT_D32_SFLOAT_S8_UINT;

    for (std::uint32_t i = std::uint32_t(PixelFormat::R8); i < std::uint32_t(PixelFormat::Count); ++i) {
        const PixelFormat pf = PixelFormat(i);
        PixelFormatCaps c;
        c.depth = pixel_format_depth(pf);
        c.compressed = pixel_format_compressed(pf);
        c.bytesPerPixel = pixel_format_bytes(pf);
        const VkFormat vf = vk_format(pf);
        if (vf == VK_FORMAT_UNDEFINED) {
            caps_[i] = c;
            continue;
        }
        VkFormatProperties fp{};
        fn_.vkGetPhysicalDeviceFormatProperties(physical_, vf, &fp);
        const VkFormatFeatureFlags t = fp.optimalTilingFeatures;
        c.sample = (t & VK_FORMAT_FEATURE_SAMPLED_IMAGE_BIT) != 0;
        // as on sokol's backends: integer and depth formats are not filtered (a depth texture is compared)
        c.filter = c.sample && (t & VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_LINEAR_BIT) && !c.depth &&
                   !pixel_format_integer(pf);
        c.render = (t & (c.depth ? VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT
                                 : VK_FORMAT_FEATURE_COLOR_ATTACHMENT_BIT)) != 0;
        c.blend = !c.depth && (t & VK_FORMAT_FEATURE_COLOR_ATTACHMENT_BLEND_BIT) != 0;
        if (c.render) {
            VkImageFormatProperties ip{};
            const VkImageUsageFlags usage =
                c.depth ? VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT : VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
            c.msaa = fn_.vkGetPhysicalDeviceImageFormatProperties(
                         physical_, vf, VK_IMAGE_TYPE_2D, VK_IMAGE_TILING_OPTIMAL, usage, 0, &ip) == VK_SUCCESS &&
                     (ip.sampleCounts & VK_SAMPLE_COUNT_4_BIT) != 0;
        }
        if (!c.depth && (t & VK_FORMAT_FEATURE_STORAGE_IMAGE_BIT)) {
            c.read = true;
            c.write = true;
        }
        caps_[i] = c;
    }
}

bool VulkanDevice::storage_image_loadable(PixelFormat format, std::string* why) const {
    // The engine's shaders declare every storage image's format, so a load needs only VK_FORMAT_FEATURE_STORAGE_IMAGE_BIT
    // with optimal tiling (init_caps put it into caps_[].read); shaderStorageImageReadWithoutFormat is not needed.
    if (why) why->clear();
    if (format == PixelFormat::Bgra8) {
        // SPIR-V has no image format qualifier for BGRA, so no shader can declare (and load from) such an image.
        if (why)
            *why = "bgra8 has no SPIR-V image format qualifier, so a Vulkan shader cannot load from it as a storage "
                   "image; use rgba8 (the same bytes in RGBA order)";
        return false;
    }
    const auto i = std::size_t(format);
    if (i < caps_.size() && caps_[i].read && caps_[i].write) return true;
    if (why)
        *why = std::string("the Vulkan device ") + deviceName_ + " cannot use " + pixel_format_name(format) +
               " as a storage image (no VK_FORMAT_FEATURE_STORAGE_IMAGE_BIT with optimal tiling); rgba8, rgba16f, "
               "r32f and rgba32f are storage formats on every Vulkan GPU";
    return false;
}

VulkanDevice::~VulkanDevice() {
    // The window first: its images' records and semaphores go while the queues and the pools still work.
    if (device_ && queues_[0].timeline) destroy_swapchain();
    if (device_ && queues_[0].timeline) {
        if (auto r = wait_idle(); !r) FA_ERROR("render", "{}", r.error().to_string());
    }
    // Every queue's timeline reached its last value, but a driver may still be finishing the submissions behind it
    // (MoltenVK signals a timeline from a command buffer's completion handler): nothing is destroyed before they end.
    if (device_) (void)fn_.vkDeviceWaitIdle(device_);
    if (device_) destroy_timer();
    // The pipelines this run made, for the next one (a failure is a warning: the old file stays).
    if (device_ && pipelineCache_) (void)save_pipeline_cache();
    for (AsyncRead& a : asyncReads_) a.buffer.reset();  // their copies finished (wait_idle)
    {
        std::lock_guard<std::mutex> lock(queueMutex_);
        prelude_ = nullptr;
        for (Deferred& d : deferred_) release(d);
        deferred_.clear();
        lists_.clear();
        deadLists_.clear();
    }
    {
        std::lock_guard<std::mutex> lock(resMutex_);
        buffers_.clear();
        images_.clear();
        views_.for_each([this](ViewRecord& v) {
            if (v.view) fn_.vkDestroyImageView(device_, v.view, nullptr);
        });
        views_.clear();
        samplers_.for_each([this](SamplerRecord& s) {
            if (s.sampler) fn_.vkDestroySampler(device_, s.sampler, nullptr);
        });
        samplers_.clear();
        shaders_.clear();  // the ShaderInfo destructors destroy the modules
        pipelines_.clear();
    }
    if (device_) {
        // The cached pipelines go with the last holder (the records above were theirs): each hands its handle to
        // retired_, destroyed here, as the GPU is idle.
        std::unordered_map<std::string, std::shared_ptr<const PipelineObject>> objects;
        {
            std::lock_guard<std::mutex> lock(cacheMutex_);
            objects.swap(pipelineObjects_);
            pipelineLayouts_.clear();
            setLayouts_.clear();
            codeUsers_.clear();
        }
        objects.clear();
        std::vector<Deferred> retired;
        {
            std::lock_guard<std::mutex> lock(retireMutex_);
            retired.swap(retired_);
        }
        for (Deferred& d : retired) release(d);
        std::lock_guard<std::mutex> lock(cacheMutex_);
        for (auto& [key, f] : framebuffers_) fn_.vkDestroyFramebuffer(device_, f.framebuffer, nullptr);
        framebuffers_.clear();
        for (auto& [key, rp] : renderPasses_) fn_.vkDestroyRenderPass(device_, rp, nullptr);
        renderPasses_.clear();
        if (pipelineCache_) fn_.vkDestroyPipelineCache(device_, pipelineCache_, nullptr);
        pipelineCache_ = VK_NULL_HANDLE;
    }
    if (device_) descriptors_.destroy();
    ringBuffer_.reset();
    if (device_) memory_.destroy();
    for (QueueRecord& q : queues_)
        if (q.timeline) fn_.vkDestroySemaphore(device_, q.timeline, nullptr);
    if (device_ && fn_.vkDestroyDevice) fn_.vkDestroyDevice(device_, nullptr);
    if (messenger_ && fn_.vkDestroyDebugUtilsMessengerEXT)
        fn_.vkDestroyDebugUtilsMessengerEXT(instance_, messenger_, nullptr);
    if (instance_ && fn_.vkDestroyInstance) fn_.vkDestroyInstance(instance_, nullptr);
    close_vulkan_library(library_);
}

// ---------------------------------------------------------------------------------------------------------------------
// Capabilities, natives, statistics, messages
// ---------------------------------------------------------------------------------------------------------------------

PixelFormatCaps VulkanDevice::pixel_format_caps(PixelFormat format) const {
    const std::uint32_t i = std::uint32_t(format);
    if (i >= std::uint32_t(PixelFormat::Count)) return {};
    return caps_[i];
}

NativeDevice VulkanDevice::native() const {
    NativeDevice n;
    n.device = device_;
    n.context = queues_[0].queue;  // the graphics VkQueue
    return n;
}

bool VulkanDevice::add_commit_listener(void (*func)(void* user), void* user) {
    if (!func) return false;
    std::lock_guard<std::mutex> lock(queueMutex_);
    for (const Listener& l : listeners_)
        if (l.func == func && l.user == user) return false;
    if (listeners_.size() >= 1024) return false;  // sokol's default table size
    listeners_.push_back({func, user});
    return true;
}

bool VulkanDevice::remove_commit_listener(void (*func)(void* user), void* user) {
    std::lock_guard<std::mutex> lock(queueMutex_);
    for (auto it = listeners_.begin(); it != listeners_.end(); ++it)
        if (it->func == func && it->user == user) {
            listeners_.erase(it);
            return true;
        }
    return false;
}

void VulkanDevice::count_make(ResourceTotals& t, bool ok) {
    if (!statsEnabled_) return;
    ++t.allocated;
    if (ok) ++t.inited;
}

void VulkanDevice::count_destroy(ResourceTotals& t) {
    if (!statsEnabled_) return;
    ++t.uninited;
    ++t.deallocated;
}

TotalStats VulkanDevice::total_stats() const {
    std::lock_guard<std::mutex> lock(resMutex_);
    TotalStats s = stats_;
    auto pool = [](ResourceTotals& t, int alive, int capacity) {
        t.alive = std::uint32_t(alive);
        t.free = std::uint32_t(capacity - alive);
    };
    pool(s.buffers, buffers_.alive(), buffers_.capacity());
    pool(s.images, images_.alive(), images_.capacity());
    pool(s.views, views_.alive(), views_.capacity());
    pool(s.samplers, samplers_.alive(), samplers_.capacity());
    pool(s.shaders, shaders_.alive(), shaders_.capacity());
    pool(s.pipelines, pipelines_.alive(), pipelines_.capacity());
    return s;
}

void VulkanDevice::report(const std::string& message) {
    FA_ERROR("render", "{}", message);
    std::lock_guard<std::mutex> lock(msgMutex_);
    errors_.push_back(message);
}

void VulkanDevice::report_once(const std::string& what, const std::string& message) {
    {
        std::lock_guard<std::mutex> lock(msgMutex_);
        if (std::find(notYetReported_.begin(), notYetReported_.end(), what) != notYetReported_.end()) return;
        notYetReported_.push_back(what);
    }
    report(message);
}

void VulkanDevice::on_validation_message(VkDebugUtilsMessageSeverityFlagBitsEXT severity, const char* id,
                                         const char* text) {
    const bool error = (severity & VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT) != 0;
    std::string line = std::string("gpu vulkan validation: ") + (error ? "ERROR" : "WARNING");
    if (id && *id) line += std::string(" [") + id + "]";
    line += std::string(": ") + (text ? text : "");
    std::lock_guard<std::mutex> lock(msgMutex_);
    if (error) {
        FA_ERROR("render", "{}", line);
        errors_.push_back(std::move(line));
    } else {
        FA_WARN("render", "{}", line);
        warnings_.push_back(std::move(line));
    }
}

std::vector<std::string> VulkanDevice::errors() {
    std::lock_guard<std::mutex> lock(msgMutex_);
    return errors_;
}

std::vector<std::string> VulkanDevice::warnings() {
    std::lock_guard<std::mutex> lock(msgMutex_);
    return warnings_;
}

void VulkanDevice::clear_messages() {
    std::lock_guard<std::mutex> lock(msgMutex_);
    errors_.clear();
    warnings_.clear();
}

VulkanCounters VulkanDevice::counters() const {
    VulkanCounters c;
    {
        std::lock_guard<std::mutex> lock(queueMutex_);
        c.pendingReleases = deferred_.size();
        c.timelineValue = queues_[0].value;
    }
    c.completedTimelineValue = completed_value();
    c.uploadRingWraps = ring_.wraps();
    c.uploadRingBytes = ring_.size();
    c.uploadRingInUse = ring_.in_use();
    c.dedicatedUploads = dedicatedUploads_.load();
    c.barriers = barriers_.load();
    c.memory = memory_.counters();
    c.frameDescriptorSets = descriptors_.frame_sets_used();
    c.frameDescriptors = descriptors_.frame_descriptors_used();
    c.bindlessUsed = descriptors_.bindless_used();
    c.bindlessCapacity = descriptors_.bindless_capacity();
    c.frameDescriptorPools = descriptors_.frame_pools_used();
    c.descriptorSetBinds = descriptorSetBinds_.load();
    std::lock_guard<std::mutex> lock(cacheMutex_);
    c.pipelineCacheHits = pipelineHits_;
    c.pipelineCacheMisses = pipelineMisses_;
    c.layoutCacheHits = layoutHits_;
    c.layoutCacheMisses = layoutMisses_;
    c.renderPassCacheHits = renderPassHits_;
    c.renderPassCacheMisses = renderPassMisses_;
    c.framebufferCacheHits = framebufferHits_;
    c.framebufferCacheMisses = framebufferMisses_;
    c.pipelinesCached = pipelineObjects_.size();
    for (const auto& [key, l] : pipelineLayouts_) c.pipelineLayoutsCached += l.expired() ? 0 : 1;
    for (const auto& [key, l] : setLayouts_) c.setLayoutsCached += l.expired() ? 0 : 1;
    c.framebuffersCached = framebuffers_.size();
    c.pipelineCacheLoaded = cacheLoaded_;
    c.pipelineCacheFileBytes = cacheFileBytes_;
    c.pipelineCacheStored = cacheStored_;
    c.pipelineCacheDiscarded = cacheDiscarded_;
    c.pipelineCacheStoreFailed = cacheStoreFailed_;
    return c;
}

void VulkanDevice::set_name(VkObjectType type, std::uint64_t handle, const char* label) const {
    if (!fn_.vkSetDebugUtilsObjectNameEXT || !label || !*label || handle == 0) return;
    VkDebugUtilsObjectNameInfoEXT ni{};
    ni.sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_OBJECT_NAME_INFO_EXT;
    ni.objectType = type;
    ni.objectHandle = handle;
    ni.pObjectName = label;
    fn_.vkSetDebugUtilsObjectNameEXT(device_, &ni);
}

VkFormat VulkanDevice::vk_format(PixelFormat f) const {
    if (f == PixelFormat::DepthStencil) return depthStencilFormat_;
    return format_info(f).format;
}

// ---------------------------------------------------------------------------------------------------------------------
// Bindless
// ---------------------------------------------------------------------------------------------------------------------

std::uint32_t VulkanDevice::bindless_index(View view) const {
    std::lock_guard<std::mutex> lock(resMutex_);
    const ViewRecord* v = views_.get(view.id);
    if (!v || !v->tracked || v->bindlessSlot == kNoSlot) return kNoBindlessIndex;
    return v->bindlessSlot;
}

// ---------------------------------------------------------------------------------------------------------------------
// The frame: lists, submission, the timeline, deferred releases
// ---------------------------------------------------------------------------------------------------------------------

VulkanCommandList* VulkanDevice::acquire_list(const char* label, bool internal, QueueKind queue) {
    collect();
    auto opened = [&](VulkanCommandList* l) -> VulkanCommandList* {
        if (auto r = l->open(label); !r) {
            report(r.error().to_string());
            return nullptr;
        }
        l->internal_ = internal;
        l->openFrame_ = frame_;
        return l;
    };
    for (;;) {
        const std::uint64_t completed = completed_value(queue);
        std::size_t mine = 0;  // this queue's lists (a list keeps its queue: its command pool is of that family)
        for (auto& l : lists_) {
            if (l->queue_ != queue) continue;
            ++mine;
            if (!l->open_ && l->fence_ <= completed) return opened(l.get());
        }
        if (mine < kMaxLists) break;
        // Every list of the queue is open or in flight: wait for the oldest submitted one.
        std::uint64_t oldest = 0;
        for (auto& l : lists_)
            if (l->queue_ == queue && !l->open_ && (oldest == 0 || l->fence_ < oldest)) oldest = l->fence_;
        if (oldest == 0) {
            report("gpu vulkan: begin_commands: " + std::to_string(kMaxLists) + " command lists of the " +
                   queue_name(queue) +
                   " queue are open and none was submitted (hint: submit() each list begin_commands() returned)");
            return nullptr;
        }
        if (auto r = wait_timeline(oldest, "begin_commands (every command list is in flight)", queue); !r) {
            report(r.error().to_string());
            return nullptr;
        }
    }
    auto l = std::make_unique<VulkanCommandList>(*this);
    l->queue_ = queue;
    if (auto r = l->create(label); !r) {
        report(r.error().to_string());
        return nullptr;
    }
    lists_.push_back(std::move(l));
    return opened(lists_.back().get());
}

CommandList& VulkanDevice::begin_commands(const char* label) { return begin_commands(label, QueueKind::Graphics); }

CommandList& VulkanDevice::begin_commands(const char* label, QueueKind queue) {
    std::lock_guard<std::mutex> lock(queueMutex_);
    if (std::size_t(queue) >= std::size_t(kQueueKinds))
        report("gpu vulkan: begin_commands('" + std::string(label ? label : "") + "'): queue " +
               std::to_string(int(queue)) +
               " is not a QueueKind (hint: Graphics, Compute or Transfer); the list runs on the graphics queue");
    if (VulkanCommandList* l = acquire_list(label ? label : "", false, resolve_queue(queue))) return *l;
    // Vulkan could not give a list (reported): hand out one that ignores everything, so the frame goes on.
    return dead_list(resolve_queue(queue));
}

VulkanCommandList& VulkanDevice::dead_list(QueueKind queue) {
    // It lives as long as the device (a caller may still hold an earlier one); a dead list holds no state, so the ones
    // of earlier frames are handed out again (commit() starts the count anew) and a device lost does not grow them.
    if (deadUsed_ == deadLists_.size()) deadLists_.push_back(std::make_unique<VulkanCommandList>(*this));
    VulkanCommandList& l = *deadLists_[deadUsed_++];
    l.queue_ = queue;  // the queue the caller asked for, so queue() says it
    return l;
}

VulkanCommandList& VulkanDevice::prelude() {
    if (!prelude_) prelude_ = acquire_list("fa-vulkan-uploads", true);
    if (prelude_) return *prelude_;
    return dead_list();  // ignores everything (see begin_commands)
}

void VulkanDevice::flush_prelude() {
    if (prelude_ && !prelude_->empty_) {
        VulkanCommandList* p = prelude_;
        prelude_ = nullptr;
        const int timerSlot = p->timerSlot_;
        const std::uint64_t timerSerial = p->timerSerial_;
        // The timed frame's pool is reset and its start written once this list ran: its end timestamp may follow.
        if (execute(*p) && timerSlot >= 0 && timerSlots_[std::size_t(timerSlot)].serial == timerSerial)
            timerSlots_[std::size_t(timerSlot)].begun = true;
    }
}

bool VulkanDevice::submittable(VulkanCommandList& list, const char* call) {
    if (!list.open_) {
        if (list.cmd_)  // the dead list of a failed begin_commands() needs no second report
            report(std::string("gpu vulkan: ") + call + ": list '" + list.label_ +
                   "' is not open (hint: submit each list once; take a new one with begin_commands())");
        return false;
    }
    // The pass first: ending it moves the debug groups still open inside it onto the list's own command buffer.
    if (list.passState_ != PassState::None) {
        report(std::string("gpu vulkan: ") + call + ": list '" + list.label_ +
               "' is still inside a pass (hint: end_pass() before " + call + "(); it was ended here)");
        list.end_pass();
    }
    if (list.debugDepth_ != 0) {
        report(std::string("gpu vulkan: ") + call + ": list '" + list.label_ + "' still has " +
               std::to_string(list.debugDepth_) +
               " debug group(s) open (hint: pop_debug_group() once for each push_debug_group())");
        for (; list.debugDepth_ > 0; --list.debugDepth_)
            if (fn_.vkCmdEndDebugUtilsLabelEXT) fn_.vkCmdEndDebugUtilsLabelEXT(list.cmd_);
    }
    if (list.openFrame_ != frame_) {
        // Its uniforms and descriptor sets are in the ring room and the descriptor pool of the frame it was opened in,
        // which commit() handed back to the frames after it: running it could read what a later frame wrote there.
        report(std::string("gpu vulkan: ") + call + ": list '" + list.label_ + "' was begun in frame " +
               std::to_string(list.openFrame_) + " and submitted in frame " + std::to_string(frame_) +
               "; it was dropped (hint: submit() every list in the frame begin_commands() returned it, before "
               "commit())");
        fn_.vkEndCommandBuffer(list.cmd_);
        list.open_ = false;
        list.uses_.clear();
        list.useIndex_.clear();
        list.pending_.clear();
        list.boundPipelines_.clear();  // its command buffer never runs
        for (std::shared_ptr<TrackedResource>& r : list.keep_) {
            Deferred d;
            d.frame = frame_;
            d.tracked = std::move(r);
            deferred_.push_back(std::move(d));
        }
        list.keep_.clear();
        return false;
    }
    return true;
}

void VulkanDevice::submit(CommandList& l) {
    auto* list = dynamic_cast<VulkanCommandList*>(&l);
    if (!list || &list->device_ != this) {
        report("gpu vulkan: submit: the list was not made by this device (hint: submit the list begin_commands() of "
               "this device returned)");
        return;
    }
    std::lock_guard<std::mutex> lock(queueMutex_);
    if (!submittable(*list, "submit")) return;
    flush_prelude();  // the initial uploads of resources this list may use go first
    execute(*list);
}

SyncToken VulkanDevice::submit_token(CommandList& l, std::span<const QueueHandoff> handoffs) {
    auto* list = dynamic_cast<VulkanCommandList*>(&l);
    if (!list || &list->device_ != this) {
        report("gpu vulkan: submit_token: the list was not made by this device (hint: submit the list "
               "begin_commands() of this device returned)");
        return {};
    }
    std::lock_guard<std::mutex> lock(queueMutex_);
    if (!submittable(*list, "submit_token")) return {};
    // The handoffs, checked before anything is recorded: a wrong one is reported and left out, the others go on.
    std::vector<Handed> handed;
    {
        std::lock_guard<std::mutex> resLock(resMutex_);
        for (std::size_t i = 0; i < handoffs.size(); ++i) {
            const QueueHandoff& h = handoffs[i];
            const std::string at =
                "gpu vulkan: submit_token of list '" + list->label_ + "': handoffs[" + std::to_string(i) + "] ";
            if ((h.image.id != 0) == (h.buffer.id != 0)) {
                report(at + "must name exactly one image or one buffer (hint: set QueueHandoff::image or "
                            "QueueHandoff::buffer, not both and not neither)");
                continue;
            }
            if (std::size_t(h.to) >= std::size_t(kQueueKinds)) {
                report(at + "names a queue that does not exist (hint: set QueueHandoff::to to Graphics, Compute or "
                            "Transfer)");
                continue;
            }
            std::shared_ptr<TrackedResource> t;
            std::string what;
            if (h.image.id) {
                const ImageRecord* r = images_.get(h.image.id);
                if (r) t = r->tracked;
                what = r ? "image '" + r->label + "'" : "image " + std::to_string(h.image.id);
            } else {
                const BufferRecord* r = buffers_.get(h.buffer.id);
                if (r) t = r->tracked;
                what = r ? "buffer '" + r->label + "'" : "buffer " + std::to_string(h.buffer.id);
            }
            if (!t) {
                report(at + "names " + what +
                       ", which is not a live resource (hint: hand over a resource that was made and not destroyed)");
                continue;
            }
            if (t->owner == list->queue_ && t->handed.valid() && t->handed.queue != list->queue_ &&
                !list->useIndex_.count(t.get())) {
                // A handoff of a resource this list does not use is not checked by check_owners: the list must still
                // wait for the handoff that brought the resource here, or its release would race the producer.
                const std::uint64_t w = std::max(list->waits_[int(t->handed.queue)],
                                                 queues_[int(list->queue_)].waitFloor[int(t->handed.queue)]);
                if (w < t->handed.value) {
                    report(at + what + " was handed to the " + queue_name(t->owner) + " queue by token (" +
                           queue_name(t->handed.queue) + " " + std::to_string(t->handed.value) +
                           ") and this list did not wait for it (hint: wait_list(list, token) with the token "
                           "submit_token() returned for that handoff, or wait_queue() before this submit)");
                    continue;
                }
            }
            if (t->owner != list->queue_) {
                report(at + what + " belongs to the " + queue_name(t->owner) + " queue, not to the " +
                       queue_name(list->queue_) +
                       " queue of this list, so this list cannot hand it over (hint: submit the handoff from a list of "
                       "the queue that owns the resource)");
                continue;
            }
            const QueueKind to = resolve_queue(h.to);
            if (to == t->owner) continue;  // already there: nothing to hand over
            bool twice = false;
            for (const Handed& e : handed) twice = twice || e.res == t;
            if (twice) {
                report(at + what +
                       " is handed over a second time in this submission (hint: one QueueHandoff per "
                       "resource)");
                continue;
            }
            handed.push_back({std::move(t), to});
        }
    }
    flush_prelude();  // the initial uploads of resources this list may use go first
    if (!execute(*list, handed)) return {};
    return {list->queue_, list->fence_};
}

bool VulkanDevice::check_token(const char* call, const std::string& label, SyncToken token) {
    const std::string at = std::string("gpu vulkan: ") + call + (label.empty() ? "" : " on list '" + label + "'");
    if (std::size_t(token.queue) >= std::size_t(kQueueKinds)) {
        report(at + ": the sync token names a queue that does not exist (hint: pass the token submit_token() "
                    "returned, unchanged)");
        return false;
    }
    const std::uint64_t issued = queues_[int(token.queue)].value;
    if (token.value > issued) {
        report(at + ": the sync token (" + queue_name(token.queue) + " " + std::to_string(token.value) +
               ") was never returned by submit_token() (the " + queue_name(token.queue) + " queue is at " +
               std::to_string(issued) +
               ") (hint: a wait can only name work already submitted with submit_token(): submit the producer's "
               "list first, then record the wait)");
        return false;
    }
    return true;
}

void VulkanDevice::wait_list(CommandList& l, SyncToken token) {
    auto* list = dynamic_cast<VulkanCommandList*>(&l);
    if (!list || &list->device_ != this) {
        report("gpu vulkan: wait_list: the list was not made by this device (hint: wait on a list begin_commands() of "
               "this device returned)");
        return;
    }
    std::lock_guard<std::mutex> lock(queueMutex_);
    if (!list->open_) {
        if (list->cmd_)
            report("gpu vulkan: wait_list on list '" + list->label_ +
                   "': the list was submitted already (hint: wait before submit(), on a list begin_commands() "
                   "returned)");
        return;
    }
    if (!token.valid() || !check_token("wait_list", list->label_, token)) return;
    if (token.queue == list->queue_) return;  // the queue's own order
    std::uint64_t& w = list->waits_[int(token.queue)];
    w = std::max(w, token.value);
}

void VulkanDevice::wait_queue(QueueKind queue, SyncToken token) {
    std::lock_guard<std::mutex> lock(queueMutex_);
    if (std::size_t(queue) >= std::size_t(kQueueKinds)) {
        report("gpu vulkan: wait_queue: queue " + std::to_string(int(queue)) +
               " is not a QueueKind (hint: Graphics, Compute or Transfer)");
        return;
    }
    if (!token.valid() || !check_token("wait_queue", "", token)) return;
    const QueueKind q = resolve_queue(queue);
    if (token.queue == q) return;  // the queue's own order
    std::uint64_t& floor = queues_[int(q)].waitFloor[int(token.queue)];
    floor = std::max(floor, token.value);
}

std::string VulkanDevice::describe(const TrackedResource& t) {
    std::string s;
    {
        std::lock_guard<std::mutex> lock(resMutex_);
        if (t.image)
            images_.for_each([&](ImageRecord& r) {
                if (r.tracked.get() == &t) s = "image '" + r.label + "'";
            });
        else
            buffers_.for_each([&](BufferRecord& r) {
                if (r.tracked.get() == &t) s = "buffer '" + r.label + "'";
            });
    }
    if (s.empty()) s = t.image ? "an image destroyed since" : "a buffer destroyed since";
    return s;
}

void VulkanDevice::check_owners(const VulkanCommandList& list, const std::uint64_t* waits,
                                std::vector<TrackedResource*>& settled) {
    if (list.internal_) return;  // the device's own lists (uploads of new resources, readbacks) run on Graphics
    for (const VulkanCommandList::Use& u : list.uses_) {
        TrackedResource& t = *u.res;
        if (t.owner != list.queue_) {
            const std::string what = describe(t);
            const char* to = list.queue_ == QueueKind::Compute    ? "Compute"
                             : list.queue_ == QueueKind::Transfer ? "Transfer"
                                                                  : "Graphics";
            report("gpu vulkan: submit: list '" + list.label_ + "': " + what + " belongs to the " +
                   queue_name(t.owner) + " queue, but the list runs on the " + queue_name(list.queue_) +
                   " queue (hint: hand it over first: submit_token(<a list of the " + queue_name(t.owner) +
                   " queue>, {QueueHandoff{" + (t.image ? "image" : "buffer") + ", to = QueueKind::" + to +
                   "}}), then wait_list() for that token before this list uses it)");
            continue;
        }
        if (!t.handed.valid()) continue;
        if (waits[int(t.handed.queue)] >= t.handed.value) {
            // Settled once the list is submitted: the owner queue's order covers every later list.
            settled.push_back(&t);
            continue;
        }
        report("gpu vulkan: submit: list '" + list.label_ + "': " + describe(t) + " was handed to the " +
               queue_name(t.owner) + " queue by token (" + queue_name(t.handed.queue) + " " +
               std::to_string(t.handed.value) +
               ") and the list did not wait for it (hint: wait_list(list, token) with the token submit_token() "
               "returned for the handoff (or wait_queue() before this submit), then use the resource)");
    }
}

bool VulkanDevice::submit_signal(QueueKind queue, const VkCommandBuffer* cmds, std::uint32_t count, const char* what,
                                 const std::uint64_t* waits, VkSemaphore binaryWait, VkSemaphore binarySignal) {
    QueueRecord& q = queues_[int(queue)];
    // The other queues' timelines it waits for: the list's wait_list() values and the queue's wait_queue() floors; then
    // the swapchain's acquire semaphore (a binary one: its value is ignored).
    VkSemaphore waitSemaphores[kQueueKinds + 1] = {};
    std::uint64_t waitValues[kQueueKinds + 1] = {};
    VkPipelineStageFlags waitStages[kQueueKinds + 1] = {};
    std::uint32_t waitCount = 0;
    for (int k = 0; k < kQueueKinds; ++k) {
        if (k == int(queue) || !queues_[k].own) continue;
        std::uint64_t v = q.waitFloor[k];
        if (waits) v = std::max(v, waits[k]);
        if (v == 0) continue;
        if (v > queues_[k].value) {  // wait_list() and wait_queue() checked it: a value never signalled hangs the GPU
            report(std::string("gpu vulkan: ") + what + ": a wait for value " + std::to_string(v) + " of the " +
                   queue_name(QueueKind(k)) +
                   " queue, which never signalled it, was left out (hint: wait only for "
                   "tokens submit_token() returned)");
            continue;
        }
        waitSemaphores[waitCount] = queues_[k].timeline;
        waitValues[waitCount] = v;
        waitStages[waitCount] = VK_PIPELINE_STAGE_ALL_COMMANDS_BIT;
        ++waitCount;
    }
    if (binaryWait) {
        // The acquired image's first use chains with this stage: its tracked state after the acquire names it.
        waitSemaphores[waitCount] = binaryWait;
        waitStages[waitCount] = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
        ++waitCount;
    }
    const std::uint64_t value = q.value + 1;
    const VkSemaphore signals[2] = {q.timeline, binarySignal};
    const std::uint64_t signalValues[2] = {value, 0};
    const std::uint32_t signalCount = binarySignal ? 2u : 1u;
    VkTimelineSemaphoreSubmitInfo ts{};
    ts.sType = VK_STRUCTURE_TYPE_TIMELINE_SEMAPHORE_SUBMIT_INFO;
    ts.waitSemaphoreValueCount = waitCount;
    ts.pWaitSemaphoreValues = waitCount ? waitValues : nullptr;
    ts.signalSemaphoreValueCount = signalCount;
    ts.pSignalSemaphoreValues = signalValues;
    VkSubmitInfo si{};
    si.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
    si.pNext = &ts;
    si.waitSemaphoreCount = waitCount;
    si.pWaitSemaphores = waitCount ? waitSemaphores : nullptr;
    si.pWaitDstStageMask = waitCount ? waitStages : nullptr;
    si.commandBufferCount = count;
    si.pCommandBuffers = cmds;
    si.signalSemaphoreCount = signalCount;
    si.pSignalSemaphores = signals;
    const VkResult r = fn_.vkQueueSubmit(q.queue, 1, &si, VK_NULL_HANDLE);
    if (r != VK_SUCCESS) {
        report(vk_error(std::string("vkQueueSubmit (") + what + ", " + queue_name(queue) + " queue)", r,
                        r == VK_ERROR_DEVICE_LOST ? "the device was lost: run with VulkanOptions::validation for "
                                                    "the cause"
                                                  : "the validation layer (VulkanOptions::validation) names the "
                                                    "command that was wrong")
                   .to_string());
        return false;
    }
    q.value = value;
    return true;
}

bool VulkanDevice::execute(VulkanCommandList& list, std::span<const Handed> handoffs, VkSemaphore signal) {
    const QueueRecord& q = queues_[int(list.queue_)];
    list.flush_barriers();
    if (list.scopeOpen_) list.close_scope();  // a timed scope left open ends with its list
    list.open_ = false;
    // Nothing of a list that does not run changes the device: its resources keep their tracked states and owners, its
    // scopes are not reported, and what it kept goes with the frame.
    auto drop = [&] {
        list.uses_.clear();
        list.useIndex_.clear();
        list.scopes_.clear();
        list.boundPipelines_.clear();
        for (std::shared_ptr<TrackedResource>& k : list.keep_) {
            Deferred d;
            d.frame = frame_;
            d.tracked = std::move(k);
            deferred_.push_back(std::move(d));
        }
        list.keep_.clear();
        return false;
    };
    // A subresource takes part in a queue family ownership transfer when its contents matter: a buffer the GPU used, an
    // image subresource out of UNDEFINED (a barrier of a transfer cannot go to UNDEFINED, and nothing is kept there).
    auto kept = [](const TrackedResource& t, const SubState& s) {
        return t.image ? s.layout != VK_IMAGE_LAYOUT_UNDEFINED : s != SubState{};
    };
    auto barrier = [](const TrackedResource& t, std::uint32_t s, const SubState& from, const SubState& to) {
        Barrier b;
        b.buffer = t.buffer;
        b.image = t.image;
        b.aspects = t.aspects;
        b.mip = s % t.mips;
        b.layer = s / t.mips;
        b.from = from;
        b.to = to;
        return b;
    };
    // The handoffs to a queue of another family: the release at the end of this list, from the state the list leaves
    // each subresource in (Device: "RESOURCES BETWEEN QUEUES"; ARCHITECTURE_RENDERING_VULKAN.md, "Queues"). A
    // resource still waiting for its acquire on this queue, and not used by the list, takes it here first.
    std::vector<Barrier> lateAcquires, releases;
    std::vector<bool> released(handoffs.size(), false);
    for (std::size_t h = 0; h < handoffs.size(); ++h) {
        const TrackedResource& t = *handoffs[h].res;
        const std::uint32_t dstFamily = queues_[int(handoffs[h].to)].family;
        if (dstFamily == q.family) continue;  // one family: the timeline wait is the whole dependency
        auto it = list.useIndex_.find(handoffs[h].res.get());
        const VulkanCommandList::Use* u = it != list.useIndex_.end() ? &list.uses_[it->second] : nullptr;
        const bool acquire = t.acquireFrom != VK_QUEUE_FAMILY_IGNORED;
        for (std::uint32_t s = 0; s < t.subresource_count(); ++s) {
            SubState after = t.states[s];
            if (u && u->current[s].layout != kUnknownLayout) {
                after = u->current[s];
            } else if (acquire && (!t.image || t.states[s].layout != VK_IMAGE_LAYOUT_UNDEFINED)) {
                after = {t.states[s].layout, kAcquireStages, kAcquireAccess};
                if (!u) {  // the list did not use it: its acquire is recorded here (the fix-ups do it otherwise)
                    Barrier a = barrier(t, s, {t.states[s].layout, 0, 0}, after);
                    a.srcFamily = t.acquireFrom == q.family ? VK_QUEUE_FAMILY_IGNORED : t.acquireFrom;
                    a.dstFamily = t.acquireFrom == q.family ? VK_QUEUE_FAMILY_IGNORED : q.family;
                    lateAcquires.push_back(a);
                }
            }
            if (!kept(t, after)) continue;
            Barrier b = barrier(t, s, after, {after.layout, 0, 0});
            b.srcFamily = q.family;
            b.dstFamily = dstFamily;
            releases.push_back(b);
            released[h] = true;
        }
    }
    if (!lateAcquires.empty()) record_barriers(list.cmd_, lateAcquires);
    if (!releases.empty()) record_barriers(list.cmd_, releases);  // a call of its own: it follows those acquires
    VkResult r = fn_.vkEndCommandBuffer(list.cmd_);
    if (r != VK_SUCCESS) {
        report(vk_error("vkEndCommandBuffer of '" + list.label_ + "'", r,
                        "the validation layer's message before this one names the command that was wrong")
                   .to_string());
        return drop();
    }
    // The fix-up barriers: the acquires of resources handed to this queue from another family, then from the state
    // the queue leaves each resource in to the state the list starts with.
    std::vector<Barrier> acquires, fix;
    for (VulkanCommandList::Use& u : list.uses_) {
        TrackedResource& t = *u.res;
        const bool acquire = t.acquireFrom != VK_QUEUE_FAMILY_IGNORED;
        for (std::uint32_t s = 0; s < std::uint32_t(u.first.size()); ++s) {
            SubState have = t.states[s];
            if (acquire && (!t.image || have.layout != VK_IMAGE_LAYOUT_UNDEFINED)) {
                Barrier a = barrier(t, s, {have.layout, 0, 0}, {have.layout, kAcquireStages, kAcquireAccess});
                a.srcFamily = t.acquireFrom == q.family ? VK_QUEUE_FAMILY_IGNORED : t.acquireFrom;
                a.dstFamily = t.acquireFrom == q.family ? VK_QUEUE_FAMILY_IGNORED : q.family;
                acquires.push_back(a);
                // what the acquire leaves; a write access, so the fix-up below always narrows it with a barrier
                have = {have.layout, kAcquireStages, VK_ACCESS_2_MEMORY_WRITE_BIT};
            }
            const SubState& want = u.first[s];
            if (want.layout == kUnknownLayout) continue;
            // Read after read in the same layout needs nothing when the list reads in exactly the stages the queue's
            // state names, with no other access: a write before those reads was made visible to them (and to no
            // other stage), and a later write in the list waits for the same stages. Otherwise a barrier: one stage
            // more must see the earlier write, one stage less must still be waited for.
            if (have.layout == want.layout && !access_writes(have.access) && !access_writes(want.access) &&
                have.stages == want.stages && (want.access & ~have.access) == 0)
                continue;
            // Nothing used it yet (a new resource, in the layout the list wants): no earlier access to wait for and
            // no layout to change, so no barrier (an empty one would only stall the pipeline).
            if (have.layout == want.layout && have.stages == 0 && have.access == 0) continue;
            fix.push_back(barrier(t, s, have, want));
        }
    }
    VkCommandBuffer cmds[2] = {};
    std::uint32_t n = 0;
    if (!acquires.empty() || !fix.empty()) {
        VkCommandBufferBeginInfo bi{};
        bi.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
        bi.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
        r = fn_.vkBeginCommandBuffer(list.fixup_, &bi);
        if (r == VK_SUCCESS) {
            // Two calls: an acquire and the fix-up of the same subresource must not be in one barrier batch.
            if (!acquires.empty()) record_barriers(list.fixup_, acquires);
            if (!fix.empty()) record_barriers(list.fixup_, fix);
            r = fn_.vkEndCommandBuffer(list.fixup_);
        }
        if (r != VK_SUCCESS)
            report(vk_error("the fix-up command buffer of '" + list.label_ + "'", r,
                            "the GPU ran out of memory or the device was lost")
                       .to_string());
        else
            cmds[n++] = list.fixup_;
    }
    cmds[n++] = list.cmd_;
    // What the submission waits for: the list's wait_list() values and the queue's wait_queue() floors.
    std::uint64_t waits[kQueueKinds] = {};
    for (int k = 0; k < kQueueKinds; ++k)
        if (k != int(list.queue_)) waits[k] = std::max(list.waits_[k], q.waitFloor[k]);
    // The acquire wait is a binary semaphore of the Graphics queue: another queue's list cannot wait for it.
    if (swapWait_ && swapWaitImage_ && list.queue_ != QueueKind::Graphics && list.useIndex_.count(swapWaitImage_)) {
        report("gpu vulkan: submit: list '" + list.label_ + "' runs on the " + queue_name(list.queue_) +
               " queue but uses the swapchain image acquire_swapchain() took, which only a Graphics list can wait for "
               "(hint: draw into the swapchain image from a Graphics list; give the other queue the resources it "
               "produces by submit_token() and wait_list())");
        return drop();
    }
    std::vector<TrackedResource*> settled;
    check_owners(list, waits, settled);
    // The first graphics list that uses the image acquire_swapchain() took waits until the presentation engine let go
    // of it.
    const bool acquireWait =
        swapWait_ && list.queue_ == QueueKind::Graphics && swapWaitImage_ && list.useIndex_.count(swapWaitImage_);
    if (!submit_signal(list.queue_, cmds, n, list.label_.c_str(), waits, acquireWait ? swapWait_ : VK_NULL_HANDLE,
                       signal))
        return drop();  // reported
    list.fence_ = q.value;
    for (TrackedResource* t : settled) t->handed = {};
    if (acquireWait) {
        if (swapWaitSlot_ < acquireSemaphores_.size()) acquireSemaphores_[swapWaitSlot_].waitedAt = q.value;
        swapWait_ = VK_NULL_HANDLE;
        swapWaitImage_ = nullptr;
    }
    for (VulkanCommandList::Use& u : list.uses_) {
        TrackedResource& t = *u.res;
        const bool acquire = t.acquireFrom != VK_QUEUE_FAMILY_IGNORED;
        for (std::size_t s = 0; s < u.current.size(); ++s) {
            if (u.current[s].layout != kUnknownLayout)
                t.states[s] = u.current[s];
            else if (acquire && (!t.image || t.states[s].layout != VK_IMAGE_LAYOUT_UNDEFINED))
                t.states[s] = {t.states[s].layout, kAcquireStages, kAcquireAccess};
        }
        t.acquireFrom = VK_QUEUE_FAMILY_IGNORED;
    }
    for (std::size_t h = 0; h < handoffs.size(); ++h) {
        TrackedResource& t = *handoffs[h].res;
        if (released[h]) {
            // Released: the consumer's first list acquires it from this family, out of these layouts.
            for (std::uint32_t s = 0; s < t.subresource_count(); ++s) {
                const bool late = t.acquireFrom != VK_QUEUE_FAMILY_IGNORED && !list.useIndex_.count(&t) &&
                                  (!t.image || t.states[s].layout != VK_IMAGE_LAYOUT_UNDEFINED);
                const SubState after =
                    late ? SubState{t.states[s].layout, kAcquireStages, kAcquireAccess} : t.states[s];
                if (kept(t, after)) t.states[s] = {after.layout, 0, 0};
            }
            t.acquireFrom = q.family;
        } else if (!list.useIndex_.count(&t) && t.acquireFrom != VK_QUEUE_FAMILY_IGNORED &&
                   queues_[int(handoffs[h].to)].family != q.family) {
            // Waiting for an acquire and nothing kept to release (its subresources all UNDEFINED): nothing to acquire.
            t.acquireFrom = VK_QUEUE_FAMILY_IGNORED;
        }
        t.owner = handoffs[h].to;
        t.handed = {list.queue_, list.fence_};
    }
    list.uses_.clear();
    list.useIndex_.clear();
    list.boundPipelines_.clear();  // the frame's deferred releases keep what the submitted commands use
    for (std::shared_ptr<TrackedResource>& k : list.keep_) {
        Deferred d;
        d.frame = frame_;
        d.tracked = std::move(k);
        deferred_.push_back(std::move(d));
    }
    list.keep_.clear();
    if (!list.scopes_.empty()) {
        // The scopes of the timed frame still open ran before its end: timer_end_frame reports them.
        std::lock_guard<std::mutex> lock(timerMutex_);
        for (const VulkanCommandList::ScopeRef& sc : list.scopes_) {
            if (sc.slot != timerCurrent_ || sc.slot < 0) continue;
            TimerSlot& slot = timerSlots_[std::size_t(sc.slot)];
            if (!sc.lost && slot.serial == sc.serial && sc.scope < slot.submitted.size())
                slot.submitted[sc.scope] = true;
        }
        list.scopes_.clear();
    }
    return true;
}

void VulkanDevice::commit() {
    std::vector<Listener> calls;
    {
        std::lock_guard<std::mutex> lock(queueMutex_);
        flush_prelude();
        for (auto& l : lists_)
            if (l->open_ && !l->internal_)
                report("gpu vulkan: commit: list '" + l->label_ +
                       "' was not submitted (hint: submit() every list begin_commands() returned before commit())");
        submit_signal(QueueKind::Graphics, nullptr, 0, "commit");
        FrameValues f;
        f.frame = frame_;
        for (int k = 0; k < kQueueKinds; ++k) f.values[k] = queues_[k].value;
        frameValues_.push_back(f);
        ring_.end_frame(frame_);
        ++frame_;
        // The frame that starts now reuses the slot (descriptor pool, ring room) of frame_ - framesInFlight_.
        if (frame_ >= std::uint64_t(framesInFlight_)) {
            const std::uint64_t old = frame_ - std::uint64_t(framesInFlight_);
            for (const FrameValues& v : frameValues_)
                if (v.frame == old) {
                    if (auto r = wait_frame(v, "commit (frames in flight)"); !r) report(r.error().to_string());
                    break;
                }
        }
        collect();
        descriptors_.begin_frame(int(frame_ % std::uint64_t(framesInFlight_)));
        deadUsed_ = 0;
        calls = listeners_;
    }
    for (const Listener& l : calls) l.func(l.user);
}

std::uint64_t VulkanDevice::completed_value(QueueKind queue) const {
    const QueueRecord& q = queues_[int(queue)];
    std::uint64_t v = 0;
    if (!q.timeline || fn_.vkGetSemaphoreCounterValue(device_, q.timeline, &v) != VK_SUCCESS) return 0;
    return v;
}

Result<void> VulkanDevice::wait_timeline(std::uint64_t value, const char* what, QueueKind queue) {
    if (completed_value(queue) >= value) return {};
    VkSemaphore timeline = queues_[int(queue)].timeline;
    if (!timeline)
        return make_error(std::string("gpu vulkan: ") + what + ": the device has no " + queue_name(queue) + " queue",
                          "wait for a token of a queue the device has (CommandList::queue() names it)");
    VkSemaphoreWaitInfo wi{};
    wi.sType = VK_STRUCTURE_TYPE_SEMAPHORE_WAIT_INFO;
    wi.semaphoreCount = 1;
    wi.pSemaphores = &timeline;
    wi.pValues = &value;
    const VkResult r = fn_.vkWaitSemaphores(device_, &wi, kFenceWaitNs);
    if (r == VK_SUCCESS) return {};
    if (r == VK_TIMEOUT)
        return make_error(std::string("gpu vulkan: ") + what + ": the " + queue_name(queue) +
                              " queue did not reach fence value " + std::to_string(value) + " within " +
                              std::to_string(kFenceWaitNs / 1000000000ull) + " s (it is at " +
                              std::to_string(completed_value(queue)) + ")",
                          "the GPU hung or the device was lost: run with VulkanOptions::validation for the cause");
    return vk_error(std::string("vkWaitSemaphores (") + what + ")", r,
                    "the device was lost: run with VulkanOptions::validation for the cause");
}

bool VulkanDevice::frame_done(const FrameValues& f) const {
    for (int k = 0; k < kQueueKinds; ++k)
        if (queues_[k].own && f.values[k] > 0 && completed_value(QueueKind(k)) < f.values[k]) return false;
    return true;
}

Result<void> VulkanDevice::wait_frame(const FrameValues& f, const char* what) {
    for (int k = 0; k < kQueueKinds; ++k)
        if (queues_[k].own && f.values[k] > 0)
            if (auto r = wait_timeline(f.values[k], what, QueueKind(k)); !r) return r;
    return {};
}

Result<void> VulkanDevice::wait_idle() {
    std::lock_guard<std::mutex> lock(queueMutex_);
    flush_prelude();
    Result<void> r;
    for (int k = 0; k < kQueueKinds && r; ++k)
        if (queues_[k].own) r = wait_timeline(queues_[k].value, "wait_idle", QueueKind(k));
    collect();  // takes the retired objects too
    // The GPU finished everything submitted, so what the open frame deferred (destroyed handles, the kept objects of
    // submitted lists) goes too, unless a list is still open: its command buffer may name a view, sampler or
    // framebuffer destroyed since it recorded it (the pipelines it bound it holds itself), so those wait for the
    // frame. The ring room stays held either way: lists still open may have written into it.
    bool open = false;
    for (auto& l : lists_) open = open || (l->open_ && l.get() != prelude_);
    if (r && !open)
        while (!deferred_.empty()) {
            release(deferred_.front());
            deferred_.pop_front();
        }
    return r;
}

void VulkanDevice::collect() {
    take_retired();
    while (!frameValues_.empty() && frame_done(frameValues_.front())) {
        completedFrames_ = frameValues_.front().frame + 1;
        ring_.frame_done(frameValues_.front().frame);
        frameValues_.pop_front();
    }
    while (!deferred_.empty() && deferred_.front().frame < completedFrames_) {
        release(deferred_.front());
        deferred_.pop_front();
    }
}

void VulkanDevice::release(Deferred& d) {
    d.tracked.reset();
    if (d.view) fn_.vkDestroyImageView(device_, d.view, nullptr);
    if (d.sampler) fn_.vkDestroySampler(device_, d.sampler, nullptr);
    if (d.bindlessSlot != kNoSlot) descriptors_.bindless_free(d.bindlessSlot);
    if (d.pipeline) fn_.vkDestroyPipeline(device_, d.pipeline, nullptr);
    if (d.pipelineLayout) fn_.vkDestroyPipelineLayout(device_, d.pipelineLayout, nullptr);
    if (d.setLayout) fn_.vkDestroyDescriptorSetLayout(device_, d.setLayout, nullptr);
    if (d.framebuffer) fn_.vkDestroyFramebuffer(device_, d.framebuffer, nullptr);
    d = Deferred{};
}

void VulkanDevice::retire_pipeline(VkPipeline pipeline) {
    if (!pipeline) return;
    Deferred d;
    d.pipeline = pipeline;
    std::lock_guard<std::mutex> lock(retireMutex_);
    retired_.push_back(std::move(d));
}

void VulkanDevice::retire_pipeline_layout(VkPipelineLayout layout) {
    if (!layout) return;
    Deferred d;
    d.pipelineLayout = layout;
    std::lock_guard<std::mutex> lock(retireMutex_);
    retired_.push_back(std::move(d));
}

void VulkanDevice::retire_set_layout(VkDescriptorSetLayout layout) {
    if (!layout) return;
    Deferred d;
    d.setLayout = layout;
    std::lock_guard<std::mutex> lock(retireMutex_);
    retired_.push_back(std::move(d));
}

void VulkanDevice::take_retired() {
    // An object retired while a frame was recorded may be in that frame's lists: it waits for the frame like any
    // destroyed handle (the open frame, frame_, as defer() tags it).
    std::vector<Deferred> retired;
    {
        std::lock_guard<std::mutex> lock(retireMutex_);
        retired.swap(retired_);
    }
    for (Deferred& d : retired) {
        d.frame = frame_;
        deferred_.push_back(std::move(d));
    }
}

VkFramebuffer VulkanDevice::framebuffer(VkRenderPass renderPass, const std::vector<VkImageView>& views,
                                        const std::vector<std::uint64_t>& serials,
                                        const std::vector<std::uint64_t>& viewIds, std::uint32_t width,
                                        std::uint32_t height, std::string& error) {
    // By the views' serials, not their handles: a new view may get the handle of a destroyed one.
    std::string key =
        std::to_string(handle_bits(renderPass)) + "|" + std::to_string(width) + "x" + std::to_string(height);
    for (std::uint64_t s : serials) key += "|" + std::to_string(s);
    VkFramebuffer fb = VK_NULL_HANDLE;
    {
        std::lock_guard<std::mutex> lock(cacheMutex_);
        if (auto it = framebuffers_.find(key); it != framebuffers_.end()) {
            ++framebufferHits_;
            return it->second.framebuffer;
        }
        fb = make_framebuffer_locked(std::move(key), renderPass, views, serials, width, height, error);
    }
    if (!fb) return VK_NULL_HANDLE;
    // destroy_view removes the view first and takes the entries out of the cache after: a view that went between
    // begin_pass's lookup and the insert above left an entry that nothing would ever take out. Looked at after the
    // insert, so either the removal is seen here, or its forget_framebuffers runs after the insert.
    std::uint64_t deadSerial = 0;
    std::uint64_t deadId = 0;
    {
        std::lock_guard<std::mutex> lock(resMutex_);
        for (std::size_t i = 0; i < viewIds.size() && i < serials.size(); ++i) {
            const ViewRecord* v = views_.get(viewIds[i]);
            if (!v || v->serial != serials[i]) {
                deadSerial = serials[i];
                deadId = viewIds[i];
                break;
            }
        }
    }
    if (deadSerial == 0) return fb;
    forget_framebuffers(deadSerial);
    error = "view " + std::to_string(deadId) +
            " was destroyed while the pass began (hint: destroy_view only views no thread is still drawing into)";
    return VK_NULL_HANDLE;
}

VkFramebuffer VulkanDevice::make_framebuffer_locked(std::string key, VkRenderPass renderPass,
                                                    const std::vector<VkImageView>& views,
                                                    const std::vector<std::uint64_t>& serials, std::uint32_t width,
                                                    std::uint32_t height, std::string& error) {
    VkFramebufferCreateInfo fi{};
    fi.sType = VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO;
    fi.renderPass = renderPass;
    fi.attachmentCount = std::uint32_t(views.size());
    fi.pAttachments = views.data();
    fi.width = width;
    fi.height = height;
    fi.layers = 1;
    VkFramebuffer fb = VK_NULL_HANDLE;
    const VkResult r = fn_.vkCreateFramebuffer(device_, &fi, nullptr, &fb);
    if (r != VK_SUCCESS) {
        error = "vkCreateFramebuffer failed with " + result_text(r);
        return VK_NULL_HANDLE;
    }
    ++framebufferMisses_;
    framebuffers_.emplace(std::move(key), FramebufferEntry{fb, serials});
    return fb;
}

void VulkanDevice::forget_framebuffers(std::uint64_t viewSerial) {
    std::vector<Deferred> gone;
    {
        std::lock_guard<std::mutex> lock(cacheMutex_);
        for (auto it = framebuffers_.begin(); it != framebuffers_.end();) {
            const auto& s = it->second.serials;
            if (std::find(s.begin(), s.end(), viewSerial) != s.end()) {
                Deferred d;
                d.framebuffer = it->second.framebuffer;
                gone.push_back(std::move(d));
                it = framebuffers_.erase(it);
            } else {
                ++it;
            }
        }
    }
    for (Deferred& d : gone) defer(std::move(d));
}

void VulkanDevice::defer(Deferred d) {
    std::lock_guard<std::mutex> lock(queueMutex_);
    d.frame = frame_;
    deferred_.push_back(std::move(d));
}

UploadAlloc VulkanDevice::upload(std::size_t size, std::size_t align, VulkanCommandList* keeper) {
    UploadAlloc a;
    if (ring_.alloc(size, align, a)) return a;
    // Bigger than the ring, or the frames in flight hold it all: a buffer of its own, released with the frame.
    std::string error;
    std::shared_ptr<TrackedResource> t =
        make_raw_buffer(align_up(size, 256), VK_BUFFER_USAGE_TRANSFER_SRC_BIT | VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT,
                        MemoryUse::Upload, true, "fa-vulkan-upload", error);
    if (!t) {
        report("gpu vulkan: an upload of " + std::to_string(size) + " bytes that does not fit the ring: " + error);
        return {};
    }
    a.buffer = t->buffer;
    a.offset = 0;
    a.cpu = t->memory.mapped;
    ++dedicatedUploads_;
    if (keeper) {
        keeper->keep_until_done(std::move(t));
    } else {
        Deferred def;
        def.tracked = std::move(t);
        defer(std::move(def));
    }
    return a;
}

std::shared_ptr<TrackedResource> VulkanDevice::make_raw_buffer(VkDeviceSize size, VkBufferUsageFlags usage,
                                                               MemoryUse use, bool dedicated, const char* label,
                                                               std::string& error) {
    auto t = std::make_shared<TrackedResource>();
    t->device = this;
    VkBufferCreateInfo bi{};
    bi.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
    bi.size = size;
    bi.usage = usage;
    bi.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
    // The upload buffers (the ring, and an upload too big for it) are written by the CPU and read by the lists of
    // every queue, with no ownership transfers: CONCURRENT over the device's families when there are several (a
    // buffer loses nothing by it; ARCHITECTURE_RENDERING_VULKAN.md, "Queues").
    std::uint32_t families[kQueueKinds] = {};
    std::uint32_t familyCount = 0;
    if (use == MemoryUse::Upload)
        for (const QueueRecord& q : queues_) {
            if (!q.own) continue;
            bool known = false;
            for (std::uint32_t i = 0; i < familyCount; ++i) known = known || families[i] == q.family;
            if (!known) families[familyCount++] = q.family;
        }
    if (familyCount > 1) {
        bi.sharingMode = VK_SHARING_MODE_CONCURRENT;
        bi.queueFamilyIndexCount = familyCount;
        bi.pQueueFamilyIndices = families;
    }
    VkResult r = fn_.vkCreateBuffer(device_, &bi, nullptr, &t->buffer);
    if (r != VK_SUCCESS) {
        t->buffer = VK_NULL_HANDLE;
        error = vk_error("vkCreateBuffer (" + std::to_string(size) + " bytes)", r,
                         r == VK_ERROR_OUT_OF_DEVICE_MEMORY || r == VK_ERROR_OUT_OF_HOST_MEMORY
                             ? "the GPU is out of memory: free resources or make them smaller"
                             : "the validation layer (VulkanOptions::validation) says which field is wrong")
                    .to_string();
        return nullptr;
    }
    VkMemoryRequirements req{};
    fn_.vkGetBufferMemoryRequirements(device_, t->buffer, &req);
    auto mem = memory_.alloc(req, use, true, dedicated);
    if (!mem) {
        error = mem.error().to_string();
        return nullptr;
    }
    t->memory = mem.value();
    r = fn_.vkBindBufferMemory(device_, t->buffer, t->memory.memory, t->memory.offset);
    if (r != VK_SUCCESS) {
        error = vk_error("vkBindBufferMemory", r, "the device was lost or is out of memory").to_string();
        return nullptr;
    }
    t->states.assign(1, SubState{});
    set_name(VK_OBJECT_TYPE_BUFFER, handle_bits(t->buffer), label);
    return t;
}

}  // namespace fa::gpu::vk

#endif  // FA_VULKAN_BACKEND
