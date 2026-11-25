// Native access for vendor SDKs on the engine's Vulkan backend (M78, docs/design/ARCHITECTURE_RENDERING_VULKAN.md,
// "Native access for vendor SDKs"): the device names its GPU and hands out what an SDK loads its functions with, and a
// command list records raw Vulkan commands between begin_native and end_native, with the engine's barriers around them.
// Every case runs on this machine's Vulkan driver (MoltenVK on macOS, lavapipe on the Linux CI job) with the validation
// layer and its synchronization validation, and checks that the layer reported no error; it says so and passes where
// there is no Vulkan, unless FA_VULKAN_REQUIRE=1 (vulkan_device_tests.cpp).
#include <doctest.h>

#include <array>
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

// A device with the validation layer and its synchronization validation, or null (with a MESSAGE) where this machine
// cannot run Vulkan; FA_VULKAN_REQUIRE=1 turns a skip and a missing layer into failures.
std::unique_ptr<VulkanDevice> make_vk() {
    VulkanOptions o;
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
    std::unique_ptr<VulkanDevice> dev(static_cast<VulkanDevice*>(d.value().release()));
    if (!dev->validation_active()) {
        if (vulkan_required()) {
            FAIL("vulkan: FA_VULKAN_REQUIRE=1 but the validation layer is not installed");
            return nullptr;
        }
        MESSAGE("vulkan: the validation layer is not installed: the case runs without its checks");
    }
    return dev;
}

std::string layer_errors(VulkanDevice& dev) {
    std::string s;
    for (const std::string& e : dev.errors())
        if (contains(e, "gpu vulkan validation:")) s += e + "\n";
    return s;
}

std::string all_errors(VulkanDevice& dev) {
    std::string s;
    for (const std::string& e : dev.errors()) s += e + "\n";
    return s;
}

void submit_and_finish(VulkanDevice& dev, CommandList& list) {
    dev.submit(list);
    dev.commit();
    auto r = dev.wait_idle();
    REQUIRE_MESSAGE(r, r.error().to_string());
}

// A non-dispatchable handle from its 64-bit value (a pointer on 64-bit targets, the number itself on 32-bit ones).
template <class Handle>
Handle handle_from_bits(std::uint64_t bits) {
#if VK_USE_64_BIT_PTR_DEFINES == 1
    return reinterpret_cast<Handle>(static_cast<std::uintptr_t>(bits));
#else
    return bits;
#endif
}

// The device-level Vulkan functions the cases record with, loaded the way an SDK loads them: through
// NativeDevice::getDeviceProcAddr.
struct VkFns {
    PFN_vkCmdClearColorImage clearColorImage = nullptr;
    PFN_vkCmdCopyBuffer copyBuffer = nullptr;
    PFN_vkCmdPipelineBarrier pipelineBarrier = nullptr;
};

VkFns load_fns(const NativeDevice& nd) {
    auto gdpa = reinterpret_cast<PFN_vkGetDeviceProcAddr>(nd.getDeviceProcAddr);
    REQUIRE(gdpa != nullptr);
    VkDevice device = static_cast<VkDevice>(const_cast<void*>(nd.device));
    VkFns f;
    f.clearColorImage = reinterpret_cast<PFN_vkCmdClearColorImage>(gdpa(device, "vkCmdClearColorImage"));
    f.copyBuffer = reinterpret_cast<PFN_vkCmdCopyBuffer>(gdpa(device, "vkCmdCopyBuffer"));
    f.pipelineBarrier = reinterpret_cast<PFN_vkCmdPipelineBarrier>(gdpa(device, "vkCmdPipelineBarrier"));
    REQUIRE(f.clearColorImage != nullptr);
    REQUIRE(f.copyBuffer != nullptr);
    REQUIRE(f.pipelineBarrier != nullptr);
    return f;
}

Image make_rgba8(Device& dev, const char* label, bool colorAttachment = false) {
    ImageDesc d;
    d.width = 4;
    d.height = 4;
    d.pixelFormat = PixelFormat::Rgba8;
    d.usage.writeTransient = true;
    d.usage.colorAttachment = colorAttachment;
    d.label = label;
    return dev.make_image(d);
}

void clear_whole(const VkFns& f, VkCommandBuffer cmd, VkImage image, VkImageLayout layout, float r, float g, float b) {
    VkClearColorValue c{};
    c.float32[0] = r;
    c.float32[1] = g;
    c.float32[2] = b;
    c.float32[3] = 1.0f;
    VkImageSubresourceRange range{};
    range.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
    range.levelCount = 1;
    range.layerCount = 1;
    f.clearColorImage(cmd, image, layout, &c, 1, &range);
}

std::vector<std::uint8_t> solid(int texels, std::uint8_t r, std::uint8_t g, std::uint8_t b) {
    std::vector<std::uint8_t> v;
    for (int i = 0; i < texels; ++i) v.insert(v.end(), {r, g, b, 255});
    return v;
}

}  // namespace

TEST_CASE("vulkan native: the device names its GPU and hands out its instance, physical device and loader") {
    auto dev = make_vk();
    if (!dev) return;
    const GpuIdentity& id = dev->info().gpu;
    INFO("vendor 0x" << std::hex << id.vendorId << " device 0x" << id.deviceId);
    CHECK(id.vendorId != 0);
    CHECK(id.vendor == gpu_vendor_from_pci(id.vendorId));
#if defined(__APPLE__)
    CHECK(id.vendor == GpuVendor::Apple);  // MoltenVK on an Apple GPU
    CHECK(id.vendorId == kPciVendorApple);
#endif

    const NativeDevice nd = dev->native();
    CHECK(nd.device != nullptr);
    CHECK(nd.context != nullptr);  // the graphics VkQueue
    CHECK(nd.instance != nullptr);
    CHECK(nd.physicalDevice != nullptr);
    CHECK(nd.adapter == nullptr);
    CHECK(nd.apiVersion >= VK_API_VERSION_1_2);
    REQUIRE(nd.getInstanceProcAddr != nullptr);
    REQUIRE(nd.getDeviceProcAddr != nullptr);
    if (nd.computeQueue)
        CHECK(nd.computeQueue != nd.context);
    else
        CHECK((nd.computeFamily == nd.graphicsFamily && nd.computeQueueIndex == nd.graphicsQueueIndex));

    // The loader the SDK gets answers for this instance and names the same GPU.
    auto gipa = reinterpret_cast<PFN_vkGetInstanceProcAddr>(nd.getInstanceProcAddr);
    VkInstance instance = static_cast<VkInstance>(const_cast<void*>(nd.instance));
    auto props = reinterpret_cast<PFN_vkGetPhysicalDeviceProperties>(gipa(instance, "vkGetPhysicalDeviceProperties"));
    REQUIRE(props != nullptr);
    VkPhysicalDeviceProperties p{};
    props(static_cast<VkPhysicalDevice>(const_cast<void*>(nd.physicalDevice)), &p);
    CHECK(p.vendorID == id.vendorId);
    CHECK(p.deviceID == id.deviceId);

    // An image and a view: the handles and formats an SDK's resource descriptions take.
    const Image img = make_rgba8(*dev, "native-ids");
    REQUIRE(dev->state(img) == ResourceState::Valid);
    const NativeImage ni = dev->native_image(img);
    CHECK(ni.vkImage != 0);
    CHECK(ni.nativeFormat == std::uint32_t(VK_FORMAT_R8G8B8A8_UNORM));
    CHECK((ni.vkUsage & VK_IMAGE_USAGE_TRANSFER_DST_BIT) != 0);
    CHECK(ni.vkAspects == std::uint32_t(VK_IMAGE_ASPECT_COLOR_BIT));
    ViewDesc vd;
    vd.texture.image = img;
    vd.label = "native-ids-view";
    const View view = dev->make_view(vd);
    const NativeView nv = dev->native_view(view);
    CHECK(nv.vkImageView != 0);
    CHECK(nv.nativeFormat == std::uint32_t(VK_FORMAT_R8G8B8A8_UNORM));
    CHECK(nv.image.id == img.id);
    CHECK(nv.d3d12Descriptor == 0);
    CHECK(dev->native_view(View{}).vkImageView == 0);

    BufferDesc bd;
    bd.size = 64;
    bd.usage.storageBuffer = true;
    bd.label = "native-ids-buffer";
    const Buffer buf = dev->make_buffer(bd);
    CHECK(dev->native_buffer(buf).vkBuffer != 0);

    dev->destroy_view(view);
    dev->destroy_image(img);
    dev->destroy_buffer(buf);
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

TEST_CASE("vulkan native: a native clear and copy between engine commands, with the engine's barriers around them") {
    auto dev = make_vk();
    if (!dev) return;
    const VkFns f = load_fns(dev->native());
    const Image img = make_rgba8(*dev, "native-clear");
    REQUIRE(dev->state(img) == ResourceState::Valid);
    const VkImage vkImage = handle_from_bits<VkImage>(dev->native_image(img).vkImage);

    std::vector<std::uint8_t> data(64);
    for (std::size_t i = 0; i < data.size(); ++i) data[i] = std::uint8_t(i * 3 + 1);
    BufferDesc bd;
    bd.size = data.size();
    bd.usage.storageBuffer = true;
    bd.usage.copySrc = true;
    bd.usage.copyDst = true;
    bd.label = "native-src";
    const Buffer src = dev->make_buffer(bd);
    bd.label = "native-dst";
    const Buffer dst = dev->make_buffer(bd);
    bd.label = "native-out";
    const Buffer out = dev->make_buffer(bd);

    CommandList& list = dev->begin_commands("native-clear");
    // The engine writes first: the native commands must see its writes (a barrier before the section) ...
    BufferWrite bw;
    bw.buffer = src;
    bw.data = Range{data.data(), data.size()};
    list.write_buffer(bw);
    const std::vector<std::uint8_t> blue = solid(16, 0, 0, 255);
    ImageWrite iw;
    iw.data = Range{blue.data(), blue.size()};
    iw.bytesPerRow = 16;
    iw.dst.image = img;
    iw.size.width = 4;
    iw.size.height = 4;
    list.write_image(iw);

    std::array<NativeUse, 3> uses{};
    uses[0].image = img;
    uses[0].state = NativeState::CopyDest;
    uses[1].buffer = src;
    uses[1].state = NativeState::CopySource;
    uses[2].buffer = dst;
    uses[2].state = NativeState::CopyDest;
    auto n = list.begin_native(uses);
    REQUIRE_MESSAGE(n, n.error().to_string());
    CHECK(n.value().backend == Backend::Vulkan);
    CHECK(n.value().queue == QueueKind::Graphics);
    VkCommandBuffer cmd = static_cast<VkCommandBuffer>(const_cast<void*>(n.value().list));
    clear_whole(f, cmd, vkImage, VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1.0f, 0.0f, 1.0f);
    VkBufferCopy region{};
    region.size = data.size();
    f.copyBuffer(cmd, handle_from_bits<VkBuffer>(dev->native_buffer(src).vkBuffer),
                 handle_from_bits<VkBuffer>(dev->native_buffer(dst).vkBuffer), 1, &region);
    auto e = list.end_native();
    REQUIRE_MESSAGE(e, e.error().to_string());

    // ... and the engine's next commands see the native writes (a barrier after it): a patch over the cleared image,
    // and a copy of the copied buffer.
    const std::vector<std::uint8_t> green = solid(1, 0, 255, 0);
    iw.data = Range{green.data(), green.size()};
    iw.bytesPerRow = 4;
    iw.dst.x = 2;
    iw.dst.y = 1;
    iw.size.width = 1;
    iw.size.height = 1;
    list.write_image(iw);
    BufferCopy bc;
    bc.src = dst;
    bc.dst = out;
    bc.size = data.size();
    list.copy_buffer_to_buffer(bc);
    submit_and_finish(*dev, list);

    std::vector<std::uint8_t> pixels;
    auto r = dev->read_image_rgba8(img, 4, 4, pixels);
    REQUIRE_MESSAGE(r, r.error().to_string());
    std::vector<std::uint8_t> expected = solid(16, 255, 0, 255);
    std::memcpy(expected.data() + (1 * 4 + 2) * 4, green.data(), 4);
    CHECK(pixels == expected);
    std::vector<std::uint8_t> bytes;
    auto rb = dev->read_buffer(out, 0, data.size(), bytes);
    REQUIRE_MESSAGE(rb, rb.error().to_string());
    CHECK(bytes == data);

    dev->destroy_image(img);
    dev->destroy_buffer(src);
    dev->destroy_buffer(dst);
    dev->destroy_buffer(out);
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
}

TEST_CASE("vulkan native: a layout the native commands leave is declared in end_native's leftIn") {
    auto dev = make_vk();
    if (!dev) return;
    const VkFns f = load_fns(dev->native());
    const Image img = make_rgba8(*dev, "native-left");
    REQUIRE(dev->state(img) == ResourceState::Valid);
    const VkImage vkImage = handle_from_bits<VkImage>(dev->native_image(img).vkImage);

    CommandList& list = dev->begin_commands("native-left");
    std::array<NativeUse, 1> uses{};
    uses[0].image = img;
    uses[0].state = NativeState::CopyDest;
    auto n = list.begin_native(uses);
    REQUIRE_MESSAGE(n, n.error().to_string());
    VkCommandBuffer cmd = static_cast<VkCommandBuffer>(const_cast<void*>(n.value().list));
    clear_whole(f, cmd, vkImage, VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 0.0f, 1.0f, 1.0f);
    // The SDK's own barrier: TRANSFER_DST -> SHADER_READ_ONLY, which leftIn then tells the engine.
    VkImageMemoryBarrier b{};
    b.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
    b.srcAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
    b.dstAccessMask = VK_ACCESS_SHADER_READ_BIT;
    b.oldLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
    b.newLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
    b.srcQueueFamilyIndex = b.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
    b.image = vkImage;
    b.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
    b.subresourceRange.levelCount = 1;
    b.subresourceRange.layerCount = 1;
    f.pipelineBarrier(cmd, VK_PIPELINE_STAGE_TRANSFER_BIT, VK_PIPELINE_STAGE_ALL_COMMANDS_BIT, 0, 0, nullptr, 0,
                      nullptr, 1, &b);

    // A leftIn entry outside what begin_native declared is refused and the section stays open.
    BufferDesc bd;
    bd.size = 16;
    bd.label = "undeclared";
    const Buffer other = dev->make_buffer(bd);
    std::array<NativeUse, 1> wrong{};
    wrong[0].buffer = other;
    wrong[0].state = NativeState::CopySource;
    auto bad = list.end_native(wrong);
    REQUIRE(!bad);
    CHECK(contains(bad.error().message, "leftIn[0]"));
    CHECK(contains(bad.error().message, "was not declared by begin_native"));

    std::array<NativeUse, 1> left{};
    left[0].image = img;
    left[0].state = NativeState::ShaderRead;
    auto e = list.end_native(left);
    REQUIRE_MESSAGE(e, e.error().to_string());
    submit_and_finish(*dev, list);

    // The engine's readback moves it from SHADER_READ_ONLY: the validation layer names any other layout it assumed.
    std::vector<std::uint8_t> pixels;
    auto r = dev->read_image_rgba8(img, 4, 4, pixels);
    REQUIRE_MESSAGE(r, r.error().to_string());
    CHECK(pixels == solid(16, 0, 255, 255));
    dev->destroy_image(img);
    dev->destroy_buffer(other);
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
}

TEST_CASE(
    "vulkan native: misuses are refused with the entry, record nothing, and an open section is closed at submit") {
    auto dev = make_vk();
    if (!dev) return;
    const Image img = make_rgba8(*dev, "native-misuse");
    const Image target = make_rgba8(*dev, "native-target", true);
    REQUIRE(dev->state(img) == ResourceState::Valid);
    REQUIRE(dev->state(target) == ResourceState::Valid);

    CommandList& list = dev->begin_commands("native-misuse");
    std::array<NativeUse, 1> one{};
    one[0].image = img;
    one[0].state = NativeState::RenderTarget;
    auto r = list.begin_native(one);
    REQUIRE(!r);
    CHECK(contains(r.error().message, "uses[0]: image 'native-misuse' was not made with ImageUsage::colorAttachment"));
    CHECK(contains(r.error().message, "list 'native-misuse'"));

    one[0].state = NativeState::CopyDest;
    one[0].mip = 1;
    r = list.begin_native(one);
    REQUIRE(!r);
    CHECK(contains(r.error().message, "uses[0]: mips 1 + 0 are not inside the 1 mip(s)"));

    std::array<NativeUse, 2> two{};
    two[0].image = img;
    two[0].state = NativeState::CopyDest;
    two[1].image = img;
    two[1].state = NativeState::ShaderRead;
    r = list.begin_native(two);
    REQUIRE(!r);
    CHECK(contains(r.error().message, "put the same subresource in two states"));

    const Image dead = make_rgba8(*dev, "native-dead");
    dev->destroy_image(dead);
    one[0] = NativeUse{};
    one[0].image = dead;
    one[0].state = NativeState::CopySource;
    r = list.begin_native(one);
    REQUIRE(!r);
    CHECK(contains(r.error().message, "uses[0]: the image is not alive"));

    auto e = list.end_native();
    REQUIRE(!e);
    CHECK(contains(e.error().message, "no native section is open"));

    // Inside a pass: refused.
    ViewDesc vd;
    vd.colorAttachment.image = target;
    const View rtv = dev->make_view(vd);
    PassDesc pass;
    pass.color = rtv;
    pass.format.color = PixelFormat::Rgba8;
    pass.colorLoad = LoadAction::Clear;
    list.begin_pass(pass);
    r = list.begin_native({});
    REQUIRE(!r);
    CHECK(contains(r.error().message, "inside a pass"));
    list.end_pass();

    // Nested: refused; a pass inside a section fails; a section left open is closed at submit.
    one[0] = NativeUse{};
    one[0].image = img;
    one[0].state = NativeState::CopySource;
    auto n = list.begin_native(one);
    REQUIRE_MESSAGE(n, n.error().to_string());
    auto nested = list.begin_native({});
    REQUIRE(!nested);
    CHECK(contains(nested.error().message, "open already"));
    list.begin_pass(pass);
    list.end_pass();
    submit_and_finish(*dev, list);
    const std::string errors = all_errors(*dev);
    CHECK(contains(errors, "a native section is open (hint: end_native() first"));
    CHECK(contains(errors, "still has a native section open"));
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));

    // A list on the transfer queue takes no native section (a device without one runs the list on another queue,
    // which takes it).
    CommandList& copy = dev->begin_commands("native-transfer", QueueKind::Transfer);
    r = copy.begin_native({});
    if (copy.queue() == QueueKind::Transfer) {
        REQUIRE(!r);
        CHECK(contains(r.error().message, "transfer queue"));
    } else {
        REQUIRE_MESSAGE(r, r.error().to_string());
        CHECK(copy.end_native());
    }
    dev->submit(copy);
    dev->commit();
    REQUIRE(dev->wait_idle());

    dev->destroy_view(rtv);
    dev->destroy_image(img);
    dev->destroy_image(target);
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

#endif  // FA_VULKAN_BACKEND
