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

// A hook that asks for what its fields say and records what it is given.
struct FakeHook : DeviceHook {
    std::string id;
    std::vector<std::string> instanceExtensions, optionalInstanceExtensions;
    std::vector<std::string> deviceExtensions, optionalDeviceExtensions;
    std::vector<std::vector<std::uint8_t>> features;
    std::vector<VulkanQueueRequest> queues;
    bool wrapSubmit = false;

    int instanceRequests = 0, deviceRequests = 0, instancesMade = 0, devicesMade = 0, destroying = 0, resolved = 0;
    const void* instance = nullptr;
    VulkanPhysicalDevice physical;
    VulkanDeviceCreated created;

    explicit FakeHook(std::string name) : id(std::move(name)) {}
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
        r.queues = queues;
    }
    HookProcAddr vulkan_resolve(const char* fn, const void* device, HookProcAddr p) override {
        ++resolved;
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

#endif  // FA_VULKAN_BACKEND
