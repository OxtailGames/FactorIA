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
// Command lists the device keeps for reuse; past this many a new one waits for the oldest to finish first.
constexpr std::size_t kMaxLists = 64;
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

    std::vector<const char*> layers;
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
    VkInstanceCreateInfo ci{};
    ci.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    ci.pNext = (validation_ && debugUtils_) ? &messenger : nullptr;  // messages of vkCreateInstance itself
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
        ci.pNext = nullptr;
        ci.enabledLayerCount = 0;
        ci.ppEnabledLayerNames = nullptr;
        r = fn_.vkCreateInstance(&ci, nullptr, &instance_);
    }
    if (r == VK_ERROR_INCOMPATIBLE_DRIVER)
        return make_error("gpu vulkan: no Vulkan device: the loader " + library_.path +
                              " found no driver (vkCreateInstance: " + result_text(r) + ")",
                          "install a Vulkan driver (Linux: mesa-vulkan-drivers, which has the CPU driver lavapipe; "
                          "macOS: brew install molten-vk)");
    if (r != VK_SUCCESS || !instance_)
        return vk_error("vkCreateInstance (Vulkan " + version_text(requested) + ")", r,
                        "update the Vulkan loader and the GPU driver");

#define FA_VK_LOAD_INSTANCE(name) fn_.name = reinterpret_cast<PFN_##name>(gipa(instance_, #name));
    FA_VK_INSTANCE_FUNCTIONS(FA_VK_LOAD_INSTANCE)
    if (debugUtils_) {
        FA_VK_DEBUG_FUNCTIONS(FA_VK_LOAD_INSTANCE)
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
    queueFamily_ = chosenFamily;
    fn_.vkGetPhysicalDeviceProperties(physical_, &props_);
    deviceName_ = props_.deviceName;
    cpuDevice_ = props_.deviceType == VK_PHYSICAL_DEVICE_TYPE_CPU;
    apiVersion_ = std::min(apiVersion_, major_minor(props_.apiVersion));

    std::uint32_t qn = 0;
    fn_.vkGetPhysicalDeviceQueueFamilyProperties(physical_, &qn, nullptr);
    std::vector<VkQueueFamilyProperties> families(qn);
    if (qn) fn_.vkGetPhysicalDeviceQueueFamilyProperties(physical_, &qn, families.data());
    std::uint32_t transfer = UINT32_MAX;
    for (std::uint32_t i = 0; i < qn; ++i) {
        const VkQueueFlags f = families[i].queueFlags;
        if ((f & VK_QUEUE_TRANSFER_BIT) && !(f & (VK_QUEUE_GRAPHICS_BIT | VK_QUEUE_COMPUTE_BIT)) &&
            families[i].queueCount > 0) {
            transfer = i;
            break;
        }
    }

    n = 0;
    fn_.vkEnumerateDeviceExtensionProperties(physical_, nullptr, &n, nullptr);
    std::vector<VkExtensionProperties> extensions(n);
    if (n) fn_.vkEnumerateDeviceExtensionProperties(physical_, nullptr, &n, extensions.data());
    extensions.resize(n);
    std::vector<const char*> enabled;
    portability_ = has_extension(extensions, VK_KHR_PORTABILITY_SUBSET_EXTENSION_NAME);
    if (portability_) enabled.push_back(VK_KHR_PORTABILITY_SUBSET_EXTENSION_NAME);
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
    features_.mrtIndependentBlendState = q.independentBlend == VK_TRUE;
    features_.mrtIndependentWriteMask = q.independentBlend == VK_TRUE;
    features_.dualSourceBlending = q.dualSrcBlend == VK_TRUE;

    const float priority = 1.0f;
    VkDeviceQueueCreateInfo queues[2]{};
    queues[0].sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
    queues[0].queueFamilyIndex = queueFamily_;
    queues[0].queueCount = 1;
    queues[0].pQueuePriorities = &priority;
    queues[1] = queues[0];
    queues[1].queueFamilyIndex = transfer;
    VkDeviceCreateInfo dci{};
    dci.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
    dci.pNext = &e2;
    dci.queueCreateInfoCount = transfer != UINT32_MAX ? 2u : 1u;
    dci.pQueueCreateInfos = queues;
    dci.enabledExtensionCount = std::uint32_t(enabled.size());
    dci.ppEnabledExtensionNames = enabled.data();
    r = fn_.vkCreateDevice(physical_, &dci, nullptr, &device_);
    if (r != VK_SUCCESS || !device_) return vk_error("vkCreateDevice on " + deviceName_, r, "update the GPU driver");

#define FA_VK_LOAD_DEVICE(name)                                                                                        \
    fn_.name = reinterpret_cast<PFN_##name>(fn_.vkGetDeviceProcAddr(device_, #name));                                  \
    if (!fn_.name)                                                                                                     \
        return make_error("gpu vulkan: the driver of " + deviceName_ + " gives no " #name,                             \
                          "update the GPU driver (Vulkan 1.2 or later)");
    FA_VK_DEVICE_FUNCTIONS(FA_VK_LOAD_DEVICE)
#undef FA_VK_LOAD_DEVICE
    if (sync2)
        fn_.vkCmdPipelineBarrier2 = reinterpret_cast<PFN_vkCmdPipelineBarrier2>(
            fn_.vkGetDeviceProcAddr(device_, core13 ? "vkCmdPipelineBarrier2" : "vkCmdPipelineBarrier2KHR"));

    fn_.vkGetDeviceQueue(device_, queueFamily_, 0, &queue_);
    if (transfer != UINT32_MAX) {
        transferFamily_ = transfer;
        fn_.vkGetDeviceQueue(device_, transfer, 0, &transferQueue_);
    }
    set_name(VK_OBJECT_TYPE_QUEUE, handle_bits(queue_), "fa-vulkan-queue");

    VkSemaphoreTypeCreateInfo type{};
    type.sType = VK_STRUCTURE_TYPE_SEMAPHORE_TYPE_CREATE_INFO;
    type.semaphoreType = VK_SEMAPHORE_TYPE_TIMELINE;
    type.initialValue = 0;
    VkSemaphoreCreateInfo sci{};
    sci.sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;
    sci.pNext = &type;
    r = fn_.vkCreateSemaphore(device_, &sci, nullptr, &timeline_);
    if (r != VK_SUCCESS) return vk_error("vkCreateSemaphore (timeline)", r, "the device was lost or is out of memory");
    set_name(VK_OBJECT_TYPE_SEMAPHORE, handle_bits(timeline_), "fa-vulkan-timeline");
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
        VkPipelineCacheCreateInfo ci{};
        ci.sType = VK_STRUCTURE_TYPE_PIPELINE_CACHE_CREATE_INFO;
        const VkResult r = fn_.vkCreatePipelineCache(device_, &ci, nullptr, &pipelineCache_);
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
                                   std::uint32_t(options.frameDescriptors), bindless);
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

VulkanDevice::~VulkanDevice() {
    if (device_ && timeline_) {
        if (auto r = wait_idle(); !r) FA_ERROR("render", "{}", r.error().to_string());
    }
    {
        std::lock_guard<std::mutex> lock(queueMutex_);
        prelude_ = nullptr;
        for (Deferred& d : deferred_) release(d);
        deferred_.clear();
        lists_.clear();
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
        std::lock_guard<std::mutex> lock(cacheMutex_);
        for (auto& [key, p] : pipelineObjects_) fn_.vkDestroyPipeline(device_, p, nullptr);
        pipelineObjects_.clear();
        for (auto& [key, l] : pipelineLayouts_) fn_.vkDestroyPipelineLayout(device_, l->layout, nullptr);
        pipelineLayouts_.clear();
        for (auto& [key, l] : setLayouts_) fn_.vkDestroyDescriptorSetLayout(device_, l, nullptr);
        setLayouts_.clear();
        for (auto& [key, rp] : renderPasses_) fn_.vkDestroyRenderPass(device_, rp, nullptr);
        renderPasses_.clear();
        if (pipelineCache_) fn_.vkDestroyPipelineCache(device_, pipelineCache_, nullptr);
        pipelineCache_ = VK_NULL_HANDLE;
    }
    if (device_) descriptors_.destroy();
    ringBuffer_.reset();
    if (device_) memory_.destroy();
    if (timeline_) fn_.vkDestroySemaphore(device_, timeline_, nullptr);
    if (device_) fn_.vkDestroyDevice(device_, nullptr);
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
    n.context = queue_;  // the VkQueue
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

bool VulkanDevice::timer_supported(std::string* why) const {
    if (why) *why = "the Vulkan backend measures GPU time from M77-P8b on (timestamp queries are not built yet)";
    return false;
}

Result<ReadTicket> VulkanDevice::request_buffer_read(Buffer, std::size_t, std::size_t) {
    return make_error("gpu vulkan: request_buffer_read is not built yet (M77-P8b)",
                      "async_read_supported() is false on this device: read with read_buffer(), which waits");
}

bool VulkanDevice::poll_buffer_read(ReadTicket, std::vector<std::uint8_t>&, bool) { return false; }

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
        c.timelineValue = timelineValue_;
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
    std::lock_guard<std::mutex> lock(cacheMutex_);
    c.pipelineCacheHits = pipelineHits_;
    c.pipelineCacheMisses = pipelineMisses_;
    c.layoutCacheHits = layoutHits_;
    c.layoutCacheMisses = layoutMisses_;
    c.renderPassCacheHits = renderPassHits_;
    c.renderPassCacheMisses = renderPassMisses_;
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

Result<std::uint32_t> VulkanDevice::bindless_add(View textureView) {
    if (descriptors_.bindless_capacity() == 0)
        return make_error("gpu vulkan: bindless_add: this device has no bindless table",
                          "VulkanOptions::bindlessDescriptors is 0, or the device has no descriptor indexing "
                          "(warnings() says so)");
    VkImageView view = VK_NULL_HANDLE;
    {
        std::lock_guard<std::mutex> lock(resMutex_);
        const ViewRecord* v = views_.get(textureView.id);
        if (!v || v->type != ViewType::Texture || !v->view)
            return make_error("gpu vulkan: bindless_add: view " + std::to_string(textureView.id) +
                                  " is not a live texture view",
                              "make it with ViewDesc::texture and keep it alive while the slot is used");
        view = v->view;
    }
    const std::uint32_t slot = descriptors_.bindless_alloc();
    if (slot == kNoSlot)
        return make_error("gpu vulkan: bindless_add: the bindless table is full (" +
                              std::to_string(descriptors_.bindless_capacity()) + " slots)",
                          "raise VulkanOptions::bindlessDescriptors, or bindless_remove() slots no longer drawn");
    descriptors_.bindless_write(slot, view, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);
    return slot;
}

void VulkanDevice::bindless_remove(std::uint32_t slot) {
    if (slot == kNoSlot || slot >= descriptors_.bindless_capacity()) {
        report("gpu vulkan: bindless_remove: slot " + std::to_string(slot) +
               " is not a slot of the bindless table (hint: pass what bindless_add() returned)");
        return;
    }
    Deferred d;
    d.bindlessSlot = slot;
    defer(std::move(d));
}

// ---------------------------------------------------------------------------------------------------------------------
// The frame: lists, submission, the timeline, deferred releases
// ---------------------------------------------------------------------------------------------------------------------

VulkanCommandList* VulkanDevice::acquire_list(const char* label, bool internal) {
    collect();
    for (;;) {
        const std::uint64_t completed = completed_value();
        for (auto& l : lists_)
            if (!l->open_ && l->fence_ <= completed) {
                if (auto r = l->open(label); !r) {
                    report(r.error().to_string());
                    return nullptr;
                }
                l->internal_ = internal;
                l->openFrame_ = frame_;
                return l.get();
            }
        if (lists_.size() < kMaxLists) break;
        // Every list is open or in flight: wait for the oldest submitted one.
        std::uint64_t oldest = 0;
        for (auto& l : lists_)
            if (!l->open_ && (oldest == 0 || l->fence_ < oldest)) oldest = l->fence_;
        if (oldest == 0) {
            report("gpu vulkan: begin_commands: " + std::to_string(kMaxLists) +
                   " command lists are open and none was submitted (hint: submit() each list begin_commands() "
                   "returned)");
            return nullptr;
        }
        if (auto r = wait_timeline(oldest, "begin_commands (every command list is in flight)"); !r) {
            report(r.error().to_string());
            return nullptr;
        }
    }
    auto l = std::make_unique<VulkanCommandList>(*this);
    if (auto r = l->create(label); !r) {
        report(r.error().to_string());
        return nullptr;
    }
    if (auto r = l->open(label); !r) {
        report(r.error().to_string());
        return nullptr;
    }
    l->internal_ = internal;
    l->openFrame_ = frame_;
    lists_.push_back(std::move(l));
    return lists_.back().get();
}

CommandList& VulkanDevice::begin_commands(const char* label) {
    std::lock_guard<std::mutex> lock(queueMutex_);
    if (VulkanCommandList* l = acquire_list(label ? label : "", false)) return *l;
    // Vulkan could not give a list (reported): hand out one that ignores everything, so the frame goes on.
    static thread_local std::unique_ptr<VulkanCommandList> dead;
    dead = std::make_unique<VulkanCommandList>(*this);
    return *dead;
}

VulkanCommandList& VulkanDevice::prelude() {
    if (!prelude_) prelude_ = acquire_list("fa-vulkan-uploads", true);
    if (prelude_) return *prelude_;
    static thread_local std::unique_ptr<VulkanCommandList> dead;
    dead = std::make_unique<VulkanCommandList>(*this);
    return *dead;
}

void VulkanDevice::flush_prelude() {
    if (prelude_ && !prelude_->empty_) {
        VulkanCommandList* p = prelude_;
        prelude_ = nullptr;
        execute(*p);
    }
}

void VulkanDevice::submit(CommandList& l) {
    auto* list = dynamic_cast<VulkanCommandList*>(&l);
    if (!list || &list->device_ != this) {
        report("gpu vulkan: submit: the list was not made by this device (hint: submit the list begin_commands() of "
               "this device returned)");
        return;
    }
    std::lock_guard<std::mutex> lock(queueMutex_);
    if (!list->open_) {
        if (list->cmd_)  // the dead list of a failed begin_commands() needs no second report
            report("gpu vulkan: submit: list '" + list->label_ +
                   "' is not open (hint: submit each list once; take a new one with begin_commands())");
        return;
    }
    // The pass first: ending it moves the debug groups still open inside it onto the list's own command buffer.
    if (list->passState_ != PassState::None) {
        report("gpu vulkan: submit: list '" + list->label_ +
               "' is still inside a pass (hint: end_pass() before submit(); it was ended here)");
        list->end_pass();
    }
    if (list->debugDepth_ != 0) {
        report("gpu vulkan: submit: list '" + list->label_ + "' still has " + std::to_string(list->debugDepth_) +
               " debug group(s) open (hint: pop_debug_group() once for each push_debug_group())");
        for (; list->debugDepth_ > 0; --list->debugDepth_)
            if (fn_.vkCmdEndDebugUtilsLabelEXT) fn_.vkCmdEndDebugUtilsLabelEXT(list->cmd_);
    }
    if (list->openFrame_ != frame_) {
        // Its uniforms and descriptor sets are in the ring room and the descriptor pool of the frame it was opened in,
        // which commit() handed back to the frames after it: running it could read what a later frame wrote there.
        report("gpu vulkan: submit: list '" + list->label_ + "' was begun in frame " +
               std::to_string(list->openFrame_) + " and submitted in frame " + std::to_string(frame_) +
               "; it was dropped (hint: submit() every list in the frame begin_commands() returned it, before "
               "commit())");
        fn_.vkEndCommandBuffer(list->cmd_);
        list->open_ = false;
        list->uses_.clear();
        list->useIndex_.clear();
        list->pending_.clear();
        for (std::shared_ptr<TrackedResource>& r : list->keep_) {
            Deferred d;
            d.frame = frame_;
            d.tracked = std::move(r);
            deferred_.push_back(std::move(d));
        }
        list->keep_.clear();
        return;
    }
    flush_prelude();  // the initial uploads of resources this list may use go first
    execute(*list);
}

bool VulkanDevice::submit_signal(const VkCommandBuffer* cmds, std::uint32_t count, const char* what) {
    const std::uint64_t value = timelineValue_ + 1;
    VkTimelineSemaphoreSubmitInfo ts{};
    ts.sType = VK_STRUCTURE_TYPE_TIMELINE_SEMAPHORE_SUBMIT_INFO;
    ts.signalSemaphoreValueCount = 1;
    ts.pSignalSemaphoreValues = &value;
    VkSubmitInfo si{};
    si.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
    si.pNext = &ts;
    si.commandBufferCount = count;
    si.pCommandBuffers = cmds;
    si.signalSemaphoreCount = 1;
    si.pSignalSemaphores = &timeline_;
    const VkResult r = fn_.vkQueueSubmit(queue_, 1, &si, VK_NULL_HANDLE);
    if (r != VK_SUCCESS) {
        report(vk_error(std::string("vkQueueSubmit (") + what + ")", r,
                        r == VK_ERROR_DEVICE_LOST ? "the device was lost: run with VulkanOptions::validation for "
                                                    "the cause"
                                                  : "the validation layer (VulkanOptions::validation) names the "
                                                    "command that was wrong")
                   .to_string());
        return false;
    }
    timelineValue_ = value;
    return true;
}

void VulkanDevice::execute(VulkanCommandList& list) {
    list.flush_barriers();
    list.open_ = false;
    VkResult r = fn_.vkEndCommandBuffer(list.cmd_);
    if (r != VK_SUCCESS) {
        report(vk_error("vkEndCommandBuffer of '" + list.label_ + "'", r,
                        "the validation layer's message before this one names the command that was wrong")
                   .to_string());
        list.uses_.clear();
        list.useIndex_.clear();
        list.keep_.clear();
        return;
    }
    // The fix-up barriers: from the state the queue leaves each resource in to the state the list starts with.
    std::vector<Barrier> fix;
    for (VulkanCommandList::Use& u : list.uses_) {
        TrackedResource& t = *u.res;
        for (std::uint32_t s = 0; s < std::uint32_t(u.first.size()); ++s) {
            const SubState& want = u.first[s];
            if (want.layout == kUnknownLayout) continue;
            const SubState& have = t.states[s];
            // read after read in the same layout needs nothing, as long as the list's first reads wait for no
            // stage the queue's reads ran in (a later write in the list only waits for the list's own stages)
            if (have.layout == want.layout && !access_writes(have.access) && !access_writes(want.access) &&
                (have.stages & ~want.stages) == 0)
                continue;
            Barrier b;
            b.buffer = t.buffer;
            b.image = t.image;
            b.aspects = t.aspects;
            b.mip = s % t.mips;
            b.layer = s / t.mips;
            b.from = have;
            b.to = want;
            fix.push_back(b);
        }
    }
    VkCommandBuffer cmds[2] = {};
    std::uint32_t n = 0;
    if (!fix.empty()) {
        VkCommandBufferBeginInfo bi{};
        bi.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
        bi.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
        r = fn_.vkBeginCommandBuffer(list.fixup_, &bi);
        if (r == VK_SUCCESS) {
            record_barriers(list.fixup_, fix);
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
    submit_signal(cmds, n, list.label_.c_str());
    for (VulkanCommandList::Use& u : list.uses_) {
        TrackedResource& t = *u.res;
        for (std::size_t s = 0; s < u.current.size(); ++s)
            if (u.current[s].layout != kUnknownLayout) t.states[s] = u.current[s];
    }
    list.uses_.clear();
    list.useIndex_.clear();
    for (std::shared_ptr<TrackedResource>& k : list.keep_) {
        Deferred d;
        d.frame = frame_;
        d.tracked = std::move(k);
        deferred_.push_back(std::move(d));
    }
    list.keep_.clear();
    list.fence_ = timelineValue_;
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
        submit_signal(nullptr, 0, "commit");
        frameValues_.emplace_back(frame_, timelineValue_);
        ring_.end_frame(frame_);
        ++frame_;
        // The frame that starts now reuses the slot (descriptor pool, ring room) of frame_ - framesInFlight_.
        if (frame_ >= std::uint64_t(framesInFlight_)) {
            const std::uint64_t old = frame_ - std::uint64_t(framesInFlight_);
            for (const auto& [frame, value] : frameValues_)
                if (frame == old) {
                    if (auto r = wait_timeline(value, "commit (frames in flight)"); !r) report(r.error().to_string());
                    break;
                }
        }
        collect();
        descriptors_.begin_frame(int(frame_ % std::uint64_t(framesInFlight_)));
        calls = listeners_;
    }
    for (const Listener& l : calls) l.func(l.user);
}

std::uint64_t VulkanDevice::completed_value() const {
    std::uint64_t v = 0;
    if (fn_.vkGetSemaphoreCounterValue(device_, timeline_, &v) != VK_SUCCESS) return 0;
    return v;
}

Result<void> VulkanDevice::wait_timeline(std::uint64_t value, const char* what) {
    if (completed_value() >= value) return {};
    VkSemaphoreWaitInfo wi{};
    wi.sType = VK_STRUCTURE_TYPE_SEMAPHORE_WAIT_INFO;
    wi.semaphoreCount = 1;
    wi.pSemaphores = &timeline_;
    wi.pValues = &value;
    const VkResult r = fn_.vkWaitSemaphores(device_, &wi, kFenceWaitNs);
    if (r == VK_SUCCESS) return {};
    if (r == VK_TIMEOUT)
        return make_error(std::string("gpu vulkan: ") + what + ": the GPU did not reach fence value " +
                              std::to_string(value) + " within " + std::to_string(kFenceWaitNs / 1000000000ull) +
                              " s (it is at " + std::to_string(completed_value()) + ")",
                          "the GPU hung or the device was lost: run with VulkanOptions::validation for the cause");
    return vk_error(std::string("vkWaitSemaphores (") + what + ")", r,
                    "the device was lost: run with VulkanOptions::validation for the cause");
}

Result<void> VulkanDevice::wait_idle() {
    std::lock_guard<std::mutex> lock(queueMutex_);
    flush_prelude();
    submit_signal(nullptr, 0, "wait_idle");
    auto r = wait_timeline(timelineValue_, "wait_idle");
    collect();
    // The GPU finished everything submitted, so what the open frame deferred (destroyed handles, the kept objects of
    // submitted lists) goes too. Its ring room stays held: lists still open may have written into it.
    if (r)
        while (!deferred_.empty()) {
            release(deferred_.front());
            deferred_.pop_front();
        }
    return r;
}

void VulkanDevice::collect() {
    const std::uint64_t completed = completed_value();
    while (!frameValues_.empty() && frameValues_.front().second <= completed) {
        completedFrames_ = frameValues_.front().first + 1;
        ring_.frame_done(frameValues_.front().first);
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
    d.view = VK_NULL_HANDLE;
    d.sampler = VK_NULL_HANDLE;
    d.bindlessSlot = kNoSlot;
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
