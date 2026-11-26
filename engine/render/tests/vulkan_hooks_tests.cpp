// Device hooks for vendor SDKs on the engine's Vulkan backend (M78-P2b, gpu/device_hooks.h,
// docs/design/ARCHITECTURE_RENDERING_HOOKS.md): fake hooks ask for instance and device extensions, feature bits and
// queues, take the made handles and wrap a device function. What the device lacks makes that hook unavailable with a
// reason and never fails the device. Runs on this machine's Vulkan driver (MoltenVK on macOS, lavapipe on the Linux CI
// job) with the validation layer, and says so and passes where there is no Vulkan, unless FA_VULKAN_REQUIRE=1. The
// swapchain hooks need a window: vulkan_device_tests.cpp.
#include <doctest.h>

#include <atomic>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "gpu/vulkan_device.h"

using namespace fa::gpu;

#if defined(FA_VULKAN_BACKEND)

using fa::gpu::vk::VulkanDevice;

namespace {

bool contains(const std::string& s, const std::string& part) { return s.find(part) != std::string::npos; }

bool vulkan_required() {
    const char* v = std::getenv("FA_VULKAN_REQUIRE");
    return v && std::strcmp(v, "1") == 0;
}

bool cannot_run_here(const std::string& e) {
    return contains(e, "no Vulkan loader") || contains(e, "no Vulkan device") || contains(e, "needs 1.2") ||
           contains(e, "VK_ERROR_INITIALIZATION_FAILED");
}

std::unique_ptr<VulkanDevice> make_vk(VulkanOptions o) {
    o.validation = true;
    o.synchronizationValidation = true;
    auto d = make_vulkan_device(o);
    if (!d) {
        const std::string e = d.error().to_string();
        if (cannot_run_here(e) && !vulkan_required()) {
            MESSAGE("vulkan: skipped, " << e);
            return nullptr;
        }
        FAIL("vulkan: make_vulkan_device failed: " << e);
        return nullptr;
    }
    return std::unique_ptr<VulkanDevice>(static_cast<VulkanDevice*>(d.value().release()));
}

std::string layer_errors(VulkanDevice& dev) {
    std::string s;
    for (const std::string& e : dev.errors())
        if (contains(e, "gpu vulkan validation:")) s += e + "\n";
    return s;
}

std::string all_warnings(VulkanDevice& dev) {
    std::string s;
    for (const std::string& w : dev.warnings()) s += w + "\n";
    return s;
}

// vkQueueSubmit as a hook wraps it (DeviceHook::vulkan_resolve): counts, then calls what the loader gave.
PFN_vkQueueSubmit gRealSubmit = nullptr;
std::atomic<int> gSubmits{0};
VKAPI_ATTR VkResult VKAPI_CALL counting_submit(VkQueue queue, std::uint32_t count, const VkSubmitInfo* submits,
                                               VkFence fence) {
    ++gSubmits;
    return gRealSubmit(queue, count, submits, fence);
}

// vkCreateDevice as a hook wraps it (an instance function: `device` is null): what Streamline's interposer does.
PFN_vkCreateDevice gRealCreateDevice = nullptr;
std::atomic<int> gCreateDevices{0};
VKAPI_ATTR VkResult VKAPI_CALL counting_create_device(VkPhysicalDevice gpu, const VkDeviceCreateInfo* ci,
                                                      const VkAllocationCallbacks* a, VkDevice* out) {
    ++gCreateDevices;
    return gRealCreateDevice(gpu, ci, a, out);
}

// vkCreateBuffer as a hook makes it fail (an instance of the device's own failure after vkCreateDevice: the upload ring is
// the first buffer the engine makes).
std::atomic<int> gFailedBuffers{0};
VKAPI_ATTR VkResult VKAPI_CALL failing_create_buffer(VkDevice, const VkBufferCreateInfo*, const VkAllocationCallbacks*,
                                                     VkBuffer*) {
    ++gFailedBuffers;
    return VK_ERROR_OUT_OF_DEVICE_MEMORY;
}

// A hook that asks for what its fields say and records what it is given.
struct FakeHook : DeviceHook {
    std::string id;
    std::vector<std::string> instanceExtensions, optionalInstanceExtensions;
    std::vector<std::string> deviceExtensions, optionalDeviceExtensions;
    std::vector<std::vector<std::uint8_t>> features;
    std::vector<std::uint32_t> featureMembers;
    std::vector<VulkanQueueRequest> queues;
    bool wrapSubmit = false, wrapCreateDevice = false, failCreateBuffer = false;

    int instanceRequests = 0, deviceRequests = 0, instancesMade = 0, devicesMade = 0, destroying = 0, resolved = 0;
    const void* instance = nullptr;
    VulkanPhysicalDevice physical;
    VulkanDeviceCreated created;

    explicit FakeHook(std::string label) : id(std::move(label)) {}
    std::string_view name() const override { return id; }
    void vulkan_instance_request(VulkanInstanceRequest& r) override {
        ++instanceRequests;
        r.extensions = instanceExtensions;
        r.optionalExtensions = optionalInstanceExtensions;
    }
    void vulkan_instance_created(const void* i, HookProcAddr gipa) override {
        ++instancesMade;
        instance = i;
        CHECK(gipa != nullptr);
    }
    void vulkan_device_request(const VulkanPhysicalDevice& pd, VulkanDeviceRequest& r) override {
        ++deviceRequests;
        physical = pd;
        r.extensions = deviceExtensions;
        r.optionalExtensions = optionalDeviceExtensions;
        r.features = features;
        r.featureMembers = featureMembers;
        r.queues = queues;
    }
    HookProcAddr vulkan_resolve(const char* fn, const void* device, HookProcAddr p) override {
        ++resolved;
        if (wrapCreateDevice && !device && std::strcmp(fn, "vkCreateDevice") == 0) {
            gRealCreateDevice = reinterpret_cast<PFN_vkCreateDevice>(p);
            return reinterpret_cast<HookProcAddr>(&counting_create_device);
        }
        if (failCreateBuffer && device && std::strcmp(fn, "vkCreateBuffer") == 0)
            return reinterpret_cast<HookProcAddr>(&failing_create_buffer);
        if (wrapSubmit && device && std::strcmp(fn, "vkQueueSubmit") == 0) {
            gRealSubmit = reinterpret_cast<PFN_vkQueueSubmit>(p);
            return reinterpret_cast<HookProcAddr>(&counting_submit);
        }
        return nullptr;
    }
    void vulkan_device_created(const VulkanDeviceCreated& c) override {
        ++devicesMade;
        created = c;
    }
    void device_destroying() override { ++destroying; }
};

}  // namespace

TEST_CASE("vulkan: device hooks ask for extensions, features and queues; what the device lacks makes a hook "
          "unavailable, never the device") {
    gSubmits = 0;
    // Asks for what every Vulkan 1.2 driver has: an instance and a device extension, a feature the engine turns on
    // already (merged into its struct) and a struct the engine does not chain (appended); wraps vkQueueSubmit.
    auto good = std::make_shared<FakeHook>("good (test)");
    good->instanceExtensions = {VK_KHR_GET_PHYSICAL_DEVICE_PROPERTIES_2_EXTENSION_NAME};
    good->optionalInstanceExtensions = {"VK_FA_absent_instance_extension_for_tests"};
    good->deviceExtensions = {VK_KHR_MAINTENANCE_1_EXTENSION_NAME};
    good->optionalDeviceExtensions = {"VK_FA_absent_optional_for_tests"};
    VkPhysicalDeviceVulkan12Features f12{};
    f12.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES;
    f12.timelineSemaphore = VK_TRUE;
    VkPhysicalDeviceVulkan11Features f11{};
    f11.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_1_FEATURES;
    VulkanDeviceRequest add;
    add.add_features(f12);
    add.add_features(f11);
    good->features = add.features;
    good->wrapSubmit = true;
    // A device extension no driver has.
    auto noDeviceExt = std::make_shared<FakeHook>("absent device extension (test)");
    noDeviceExt->deviceExtensions = {"VK_FA_absent_for_tests"};
    // An instance extension no loader has: unavailable before the device is asked for.
    auto noInstanceExt = std::make_shared<FakeHook>("absent instance extension (test)");
    noInstanceExt->instanceExtensions = {"VK_FA_absent_instance_for_tests"};
    // A feature struct that is not one.
    auto badStruct = std::make_shared<FakeHook>("bad feature struct (test)");
    badStruct->features = {std::vector<std::uint8_t>(6, 0)};
    // Queues of a kind no family has.
    auto noQueue = std::make_shared<FakeHook>("impossible queue (test)");
    noQueue->queues = {{0x40000000u, 1}};
    // A compute queue of its own: granted where a family has one left (MoltenVK), unavailable where the engine took
    // the only queue (lavapipe has one).
    auto compute = std::make_shared<FakeHook>("compute queue (test)");
    compute->queues = {{VK_QUEUE_COMPUTE_BIT, 1}};

    VulkanOptions o;
    o.init.hooks = {good, noDeviceExt, noInstanceExt, badStruct, noQueue, compute};
    auto dev = make_vk(o);
    if (!dev) return;
    const NativeDevice nd = dev->native();
    INFO(all_warnings(*dev));

    // The good hook: every callback, with the device's own handles.
    CHECK(good->available());
    CHECK(good->unavailable_reason().empty());
    CHECK(good->instanceRequests == 1);
    CHECK(good->instancesMade == 1);
    CHECK(good->instance == nd.instance);
    CHECK(good->deviceRequests == 1);
    CHECK(good->physical.physicalDevice == nd.physicalDevice);
    CHECK(good->physical.instance == nd.instance);
    CHECK(!good->physical.name.empty());
    CHECK(good->devicesMade == 1);
    CHECK(good->created.native.device == nd.device);
    CHECK(good->created.native.instance == nd.instance);
    CHECK(good->created.native.physicalDevice == nd.physicalDevice);
    CHECK(good->created.native.commandQueue == nd.commandQueue);
    CHECK(good->created.native.getDeviceProcAddr != nullptr);
    CHECK(good->created.queues.empty());
    CHECK(good->created.enabledOptionalExtensions.empty());  // the optional one is absent: skipped, no reason
    CHECK(good->resolved > 0);

    // The engine calls the wrapped vkQueueSubmit.
    CommandList& list = dev->begin_commands("hooked");
    dev->submit(list);
    dev->commit();
    auto idle = dev->wait_idle();
    REQUIRE_MESSAGE(idle, idle.error().to_string());
    CHECK(gSubmits.load() > 0);

    // What the device lacks: unavailable, with a reason that names it; no later callback.
    CHECK(!noDeviceExt->available());
    CHECK(contains(noDeviceExt->unavailable_reason(), "has no device extension VK_FA_absent_for_tests"));
    CHECK(noDeviceExt->devicesMade == 0);
    CHECK(!noInstanceExt->available());
    CHECK(contains(noInstanceExt->unavailable_reason(), "has no instance extension VK_FA_absent_instance_for_tests"));
    CHECK(noInstanceExt->instancesMade == 0);
    CHECK(noInstanceExt->deviceRequests == 0);
    CHECK(!badStruct->available());
    CHECK(contains(badStruct->unavailable_reason(), "not a Vk*Features struct"));
    CHECK(!noQueue->available());
    CHECK(contains(noQueue->unavailable_reason(), "no queue family with the flags 0x40000000"));
    if (compute->available()) {
        REQUIRE(compute->created.queues.size() == 1);
        CHECK(compute->created.queues[0].queue != nullptr);
        CHECK(compute->created.queues[0].queue != nd.commandQueue);
    } else {
        CHECK(contains(compute->unavailable_reason(), "no queue family"));
    }
    // Each reason is a warning of the device.
    CHECK(contains(all_warnings(*dev), "device hook 'absent device extension (test)' is unavailable"));
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));

    // The device goes: the available hooks hear it first.
    dev.reset();
    CHECK(good->destroying == 1);
    CHECK(noDeviceExt->destroying == 0);
}

TEST_CASE("vulkan: a hook used for a second device starts available again") {
    auto hook = std::make_shared<FakeHook>("reused (test)");
    hook->deviceExtensions = {"VK_FA_absent_for_tests"};
    VulkanOptions o;
    o.init.hooks = {hook};
    {
        auto dev = make_vk(o);
        if (!dev) return;
        CHECK(!hook->available());
    }
    hook->deviceExtensions.clear();
    auto dev = make_vk(o);
    if (!dev) return;
    CHECK(hook->available());
    CHECK(hook->devicesMade == 1);
}

TEST_CASE("vulkan: the feature structs of a hook are read member by member and must fit the device's chain") {
    // The Vulkan 1.2 struct is 204 bytes of members in 208: the 4 padding bytes are no feature, whatever they hold.
    auto padded = std::make_shared<FakeHook>("padded Vulkan12 struct (test)");
    {
        VkPhysicalDeviceVulkan12Features f12{};
        f12.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES;
        f12.timelineSemaphore = VK_TRUE;
        VulkanDeviceRequest add;
        add.add_features(f12);
        REQUIRE(add.features[0].size() == sizeof(f12));
        if constexpr (sizeof(f12) > 204) std::memset(add.features[0].data() + 204, 0xff, sizeof(f12) - 204);
        padded->features = add.features;
    }
    // A struct an older per-feature struct of Vulkan 1.2: the engine chains Vulkan12Features already.
    auto covered = std::make_shared<FakeHook>("per-feature struct (test)");
    {
        VkPhysicalDeviceTimelineSemaphoreFeatures f{};
        f.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TIMELINE_SEMAPHORE_FEATURES;
        f.timelineSemaphore = VK_TRUE;
        VulkanDeviceRequest add;
        add.add_features(f);
        covered->features = add.features;
    }
    // Synchronization2's own struct: invalid next to Vulkan13Features (Vulkan 1.3), and an extension's struct needs
    // its extension (Vulkan 1.2) -- either way this hook is unavailable and the message names the struct.
    auto sync2 = std::make_shared<FakeHook>("synchronization2 struct (test)");
    {
        VkPhysicalDeviceSynchronization2FeaturesKHR f{};
        f.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SYNCHRONIZATION_2_FEATURES_KHR;
        f.synchronization2 = VK_TRUE;
        VulkanDeviceRequest add;
        add.add_features(f);
        sync2->features = add.features;
    }
    // A struct of an extension, with no extension asked for.
    auto orphan = std::make_shared<FakeHook>("extension struct without its extension (test)");
    {
        VkBaseOutStructure unknown{};
        unknown.sType = VkStructureType(1000999000);
        std::vector<std::uint8_t> f(sizeof(VkBaseOutStructure) + sizeof(VkBool32), 0);
        std::memcpy(f.data(), &unknown, sizeof unknown);
        orphan->features = {f};
    }
    VulkanOptions o;
    o.init.hooks = {padded, covered, sync2, orphan};
    auto dev = make_vk(o);
    if (!dev) return;
    INFO(all_warnings(*dev));
    CHECK(padded->available());
    CHECK(padded->devicesMade == 1);
    CHECK(!covered->available());
    CHECK(contains(covered->unavailable_reason(), "VkPhysicalDeviceVulkan12Features covers"));
    // Vulkan 1.3: Vulkan13Features covers the struct, so it cannot join the chain. Vulkan 1.2: it is the extension's own
    // struct, which a device that has VK_KHR_synchronization2 (the engine enables it) serves: the hook may be available.
    REQUIRE(sync2->deviceRequests == 1);
    if (sync2->physical.apiVersion >= VK_API_VERSION_1_3) {
        CHECK(!sync2->available());
        CHECK(contains(sync2->unavailable_reason(), "VkPhysicalDeviceSynchronization2Features"));
    } else if (!sync2->available()) {
        CHECK(contains(sync2->unavailable_reason(), "VkPhysicalDeviceSynchronization2Features"));
    }
    CHECK(!orphan->available());
    CHECK(contains(orphan->unavailable_reason(), "without a required device extension"));
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

TEST_CASE("vulkan: a hook that becomes unavailable keeps none of the instance functions it replaced") {
    gCreateDevices = 0;
    // A control: available, its vkCreateDevice is the one the engine calls.
    {
        auto good = std::make_shared<FakeHook>("vkCreateDevice wrapper (test)");
        good->wrapCreateDevice = true;
        VulkanOptions o;
        o.init.hooks = {good};
        auto dev = make_vk(o);
        if (!dev) return;
        CHECK(good->available());
        CHECK(gCreateDevices.load() == 1);
    }
    // The same wrapper from a hook the device then lacks an extension for: the engine's own vkCreateDevice is called.
    gCreateDevices = 0;
    auto gone = std::make_shared<FakeHook>("vkCreateDevice wrapper without its extension (test)");
    gone->wrapCreateDevice = true;
    gone->deviceExtensions = {"VK_FA_absent_for_tests"};
    VulkanOptions o;
    o.init.hooks = {gone};
    auto dev = make_vk(o);
    if (!dev) return;
    CHECK(!gone->available());
    CHECK(gCreateDevices.load() == 0);
    CHECK(gone->devicesMade == 0);
}

TEST_CASE("vulkan: a hook hears device_destroying only for a device it heard vulkan_device_created for") {
    // The device fails after vkCreateDevice, deterministically: the hook's vkCreateBuffer fails for the upload ring.
    // The hook was asked about the device (vulkan_device_request, so vkCreateDevice ran) and never told it was made.
    gFailedBuffers = 0;
    auto hook = std::make_shared<FakeHook>("paired (test)");
    hook->failCreateBuffer = true;
    VulkanOptions o;
    o.init.hooks = {hook};
    o.validation = true;
    {
        auto d = make_vulkan_device(o);
        if (d) {
            FAIL("vulkan: the device was made although vkCreateBuffer failed");
        } else {
            const std::string e = d.error().to_string();
            if (cannot_run_here(e) && !vulkan_required()) {
                MESSAGE("vulkan: skipped, " << e);
                return;
            }
            CHECK_MESSAGE(contains(e, "vkCreateBuffer"), e);
        }
    }
    CHECK(gFailedBuffers.load() > 0);
    CHECK(hook->deviceRequests == 1);  // vkCreateDevice ran with the hook's request
    CHECK(hook->devicesMade == 0);
    CHECK(hook->destroying == 0);
    CHECK(!hook->in_use());  // the failed device let go of the hook

    // A device that is made: the two callbacks pair.
    hook->failCreateBuffer = false;
    {
        auto dev = make_vk(o);
        if (!dev) return;
        CHECK(hook->devicesMade == 1);
        CHECK(hook->in_use());
    }
    CHECK(hook->destroying == 1);
    CHECK(!hook->in_use());
}

TEST_CASE("vulkan: a hook serves one device at a time: a second device is made without it and leaves it alone") {
    auto hook = std::make_shared<FakeHook>("one device (test)");
    VulkanOptions o;
    o.init.hooks = {hook};
    auto first = make_vk(o);
    if (!first) return;
    REQUIRE(hook->available());
    REQUIRE(hook->devicesMade == 1);

    // The second device cannot take the hook: no request, no callback, a warning; the first device's hook stays as it was
    // (here a hook that would fail its extension check on the second device does not mark itself unavailable).
    hook->deviceExtensions = {"VK_FA_absent_for_tests"};
    auto second = make_vk(o);
    if (!second) return;
    CHECK(hook->available());
    CHECK(hook->deviceRequests == 1);
    CHECK(hook->devicesMade == 1);
    CHECK(contains(all_warnings(*second), "device hook 'one device (test)' is not used by this device"));
    CHECK(contains(all_warnings(*second), "another live D3D12 or Vulkan device holds it"));
    CHECK(!contains(all_warnings(*first), "is not used by this device"));
    second.reset();
    CHECK(hook->destroying == 0);  // the second device never held it
    CHECK(hook->available());

    // The first goes; a later device takes it again (and now fails its extension check).
    first.reset();
    CHECK(hook->destroying == 1);
    auto third = make_vk(o);
    if (!third) return;
    CHECK(hook->deviceRequests == 2);
    CHECK(!hook->available());
    CHECK(contains(hook->unavailable_reason(), "has no device extension VK_FA_absent_for_tests"));
}

TEST_CASE("vulkan: covered_by_core names every per-feature struct Vulkan12Features and Vulkan13Features cover") {
    using fa::gpu::vk::covered_by_core;
    const VkStructureType core12[] = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_8BIT_STORAGE_FEATURES,
                                      VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_ATOMIC_INT64_FEATURES,
                                      VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_FLOAT16_INT8_FEATURES,
                                      VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_INDEXING_FEATURES,
                                      VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SCALAR_BLOCK_LAYOUT_FEATURES,
                                      VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_MEMORY_MODEL_FEATURES,
                                      VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGELESS_FRAMEBUFFER_FEATURES,
                                      VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_UNIFORM_BUFFER_STANDARD_LAYOUT_FEATURES,
                                      VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_SUBGROUP_EXTENDED_TYPES_FEATURES,
                                      VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SEPARATE_DEPTH_STENCIL_LAYOUTS_FEATURES,
                                      VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_HOST_QUERY_RESET_FEATURES,
                                      VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TIMELINE_SEMAPHORE_FEATURES,
                                      VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_BUFFER_DEVICE_ADDRESS_FEATURES};
    // One per member group of VkPhysicalDeviceVulkan13Features (the spec's list of the structs it replaces).
    const VkStructureType core13[] = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_ROBUSTNESS_FEATURES,
                                      VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_INLINE_UNIFORM_BLOCK_FEATURES,
                                      VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PIPELINE_CREATION_CACHE_CONTROL_FEATURES,
                                      VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PRIVATE_DATA_FEATURES,
                                      VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_DEMOTE_TO_HELPER_INVOCATION_FEATURES,
                                      VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_TERMINATE_INVOCATION_FEATURES,
                                      VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SUBGROUP_SIZE_CONTROL_FEATURES,
                                      VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SYNCHRONIZATION_2_FEATURES,
                                      VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TEXTURE_COMPRESSION_ASTC_HDR_FEATURES,
                                      VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ZERO_INITIALIZE_WORKGROUP_MEMORY_FEATURES,
                                      VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DYNAMIC_RENDERING_FEATURES,
                                      VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_INTEGER_DOT_PRODUCT_FEATURES,
                                      VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MAINTENANCE_4_FEATURES};
    for (const VkStructureType t : core12) {
        INFO("sType " << int(t));
        CHECK(std::string(covered_by_core(t, false)) == "VkPhysicalDeviceVulkan12Features");
        CHECK(std::string(covered_by_core(t, true)) == "VkPhysicalDeviceVulkan12Features");
    }
    for (const VkStructureType t : core13) {
        INFO("sType " << int(t));
        CHECK(std::string(covered_by_core(t, true)) == "VkPhysicalDeviceVulkan13Features");
        CHECK(std::string(covered_by_core(t, false)).empty());  // a Vulkan 1.2 device chains no Vulkan13Features
    }
    // The core structs themselves and an unrelated one are not "covered".
    CHECK(std::string(covered_by_core(VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_3_FEATURES, true)).empty());
    CHECK(std::string(covered_by_core(VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2, true)).empty());
    CHECK(std::string(covered_by_core(VkStructureType(1000999000), true)).empty());
}

TEST_CASE("vulkan: handle_from_bits is the inverse of handle_bits for a pointer handle and for a 64-bit one") {
    struct Opaque;
    using PointerHandle = Opaque*;
    using IntegerHandle = std::uint64_t;  // a non-dispatchable handle on a 32-bit target
    const std::uint64_t bits = 0x1234abcdull;
    CHECK(fa::gpu::vk::handle_bits(fa::gpu::vk::handle_from_bits<PointerHandle>(bits)) == bits);
    CHECK(fa::gpu::vk::handle_from_bits<IntegerHandle>(0xfedcba9876543210ull) == 0xfedcba9876543210ull);
    CHECK(fa::gpu::vk::handle_bits(fa::gpu::vk::handle_from_bits<IntegerHandle>(bits)) == bits);
}

#endif  // FA_VULKAN_BACKEND
