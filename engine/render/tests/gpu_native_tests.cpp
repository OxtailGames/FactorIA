// Native access for vendor SDKs (M78, docs/design/ARCHITECTURE_RENDERING_VULKAN.md and ARCHITECTURE_RENDERING_D3D12.md,
// "Native access for vendor SDKs"): the backend-neutral checks of CommandList::begin_native / end_native, the PCI vendor
// table, the RecordingDevice's refusal, and the SokolDevice of the test GPU (D3D11 hands out its immediate context, GL
// and Metal refuse; every backend names its GPU). The D3D12 and Vulkan recording is in d3d12_native_tests.cpp and
// vulkan_native_tests.cpp.
#include <doctest.h>

#include <array>
#include <ios>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "gpu/device.h"
#include "gpu/sokol_device.h"
#include "test_util.h"

using namespace fa::gpu;

namespace {

bool contains(const std::string& s, const std::string& part) { return s.find(part) != std::string::npos; }

NativeTarget image_target(ImageUsage usage, PixelFormat format = PixelFormat::Rgba8, int mips = 4, int layers = 2) {
    NativeTarget t;
    t.label = "img";
    t.imageUsage = usage;
    t.format = format;
    t.mips = mips;
    t.layers = layers;
    return t;
}

NativeUse image_use(NativeState state, int mip = 0, int mipCount = 0, int layer = 0, int layerCount = 0) {
    NativeUse u;
    u.image.id = 7;
    u.state = state;
    u.mip = mip;
    u.mipCount = mipCount;
    u.layer = layer;
    u.layerCount = layerCount;
    return u;
}

}  // namespace

TEST_CASE("native access: PCI vendor ids name the vendor") {
    CHECK(gpu_vendor_from_pci(0x10DE) == GpuVendor::Nvidia);
    CHECK(gpu_vendor_from_pci(0x1002) == GpuVendor::Amd);
    CHECK(gpu_vendor_from_pci(0x8086) == GpuVendor::Intel);
    CHECK(gpu_vendor_from_pci(0x106B) == GpuVendor::Apple);
    CHECK(gpu_vendor_from_pci(0x1414) == GpuVendor::Microsoft);
    CHECK(gpu_vendor_from_pci(0x10005) == GpuVendor::Other);  // Mesa's Vulkan vendor id (lavapipe)
    CHECK(gpu_vendor_from_pci(0) == GpuVendor::Unknown);
    CHECK(std::string(gpu_vendor_name(GpuVendor::Nvidia)) == "nvidia");
    CHECK(std::string(gpu_vendor_name(GpuVendor::Unknown)) == "unknown");
    CHECK(std::string(native_state_name(NativeState::CopyDest)) == "CopyDest");
}

TEST_CASE("native access: a use's range, state and queue are checked against the resource") {
    ImageUsage plain;
    ImageUsage storage;
    storage.storageImage = true;
    ImageUsage color;
    color.colorAttachment = true;
    ImageUsage depth;
    depth.depthStencilAttachment = true;
    NativeRange r;

    // 0 counts run to the end.
    CHECK(check_native_use(image_use(NativeState::CopyDest, 1, 0, 1, 0), image_target(plain), QueueKind::Graphics, r)
              .empty());
    CHECK(r.mip == 1);
    CHECK(r.mipCount == 3);
    CHECK(r.layer == 1);
    CHECK(r.layerCount == 1);
    CHECK(
        check_native_use(image_use(NativeState::ShaderRead, 2, 2), image_target(plain), QueueKind::Compute, r).empty());
    CHECK(r.mipCount == 2);

    std::string e =
        check_native_use(image_use(NativeState::CopyDest, 3, 2), image_target(plain), QueueKind::Graphics, r);
    CHECK(contains(e, "mips 3 + 2 are not inside the 4 mip(s) of image 'img'"));
    e = check_native_use(image_use(NativeState::CopyDest, 0, 0, 2), image_target(plain), QueueKind::Graphics, r);
    CHECK(contains(e, "layers 2 + 0 are not inside the 2 layer(s)"));
    e = check_native_use(image_use(NativeState::CopyDest, -1), image_target(plain), QueueKind::Graphics, r);
    CHECK(contains(e, "are not inside"));

    e = check_native_use(image_use(NativeState::UnorderedAccess), image_target(plain), QueueKind::Compute, r);
    CHECK(contains(e, "was not made with ImageUsage::storageImage"));
    CHECK(check_native_use(image_use(NativeState::UnorderedAccess), image_target(storage), QueueKind::Compute, r)
              .empty());
    e = check_native_use(image_use(NativeState::RenderTarget), image_target(plain), QueueKind::Graphics, r);
    CHECK(contains(e, "was not made with ImageUsage::colorAttachment"));
    CHECK(check_native_use(image_use(NativeState::RenderTarget), image_target(color), QueueKind::Graphics, r).empty());
    e = check_native_use(image_use(NativeState::RenderTarget), image_target(color), QueueKind::Compute, r);
    CHECK(contains(e, "RenderTarget on a compute list"));
    e = check_native_use(image_use(NativeState::DepthWrite), image_target(color), QueueKind::Graphics, r);
    CHECK(contains(e, "is not a depth image made with ImageUsage::depthStencilAttachment"));
    CHECK(check_native_use(image_use(NativeState::DepthRead), image_target(depth, PixelFormat::DepthStencil, 1, 1),
                           QueueKind::Graphics, r)
              .empty());
    e = check_native_use(image_use(NativeState::RenderTarget), image_target(depth, PixelFormat::DepthStencil, 1, 1),
                         QueueKind::Graphics, r);
    CHECK(contains(e, "has a depth format"));
    e = check_native_use(image_use(NativeState(99)), image_target(plain), QueueKind::Graphics, r);
    CHECK(contains(e, "is not a NativeState"));

    // Buffers are whole and take no attachment state.
    NativeTarget buf;
    buf.buffer = true;
    NativeUse bu;
    bu.buffer.id = 3;
    bu.state = NativeState::CopySource;
    CHECK(check_native_use(bu, buf, QueueKind::Compute, r).empty());
    bu.mipCount = 1;
    CHECK(contains(check_native_use(bu, buf, QueueKind::Compute, r), "an unnamed buffer has a mip or layer range"));
    bu.mipCount = 0;
    bu.state = NativeState::UnorderedAccess;
    CHECK(contains(check_native_use(bu, buf, QueueKind::Compute, r), "BufferUsage::storageBuffer"));
    buf.bufferUsage.storageBuffer = true;
    CHECK(check_native_use(bu, buf, QueueKind::Compute, r).empty());
    bu.state = NativeState::DepthRead;
    CHECK(contains(check_native_use(bu, buf, QueueKind::Graphics, r), "cannot be in DepthRead"));
}

TEST_CASE("native access: one subresource in two states is an error; disjoint ranges and one state are not") {
    std::array<NativeUse, 2> uses = {image_use(NativeState::ShaderRead, 0, 1), image_use(NativeState::CopyDest, 1, 1)};
    std::array<NativeRange, 2> ranges = {NativeRange{0, 1, 0, 1}, NativeRange{1, 1, 0, 1}};
    CHECK(check_native_overlaps(uses, ranges).empty());
    ranges[1] = NativeRange{0, 2, 0, 1};
    CHECK(contains(check_native_overlaps(uses, ranges), "uses[0] (ShaderRead) and uses[1] (CopyDest)"));
    uses[1].state = NativeState::ShaderRead;
    CHECK(check_native_overlaps(uses, ranges).empty());  // the same state twice
    uses[1].image.id = 8;
    uses[1].state = NativeState::CopyDest;
    CHECK(check_native_overlaps(uses, ranges).empty());  // another image

    // check_native_uses: the entry, a dead resource, both handles.
    std::vector<NativeRange> got;
    NativeUse none;
    std::array<NativeUse, 1> one = {none};
    auto alive = [](const NativeUse&, NativeTarget& t) {
        t.label = "img";
        t.mips = 4;
        t.layers = 2;
        return true;
    };
    CHECK(
        contains(check_native_uses(one, QueueKind::Graphics, "uses", true, got, alive), "uses[0]: names no resource"));
    one[0].image.id = 1;
    one[0].buffer.id = 1;
    CHECK(contains(check_native_uses(one, QueueKind::Graphics, "leftIn", true, got, alive),
                   "leftIn[0]: names an image and a buffer"));
    one[0].buffer.id = 0;
    auto dead = [](const NativeUse&, NativeTarget&) { return false; };
    CHECK(contains(check_native_uses(one, QueueKind::Graphics, "uses", true, got, dead),
                   "uses[0]: the image is not alive"));
    CHECK(check_native_uses(one, QueueKind::Graphics, "uses", true, got, alive).empty());
    REQUIRE(got.size() == 1);
    CHECK(got[0].mipCount == 4);
    CHECK(got[0].layerCount == 2);
}

TEST_CASE("native access: the RecordingDevice records no native commands and names no GPU") {
    auto made = make_device(Backend::Recording);
    REQUIRE(made);
    Device& dev = *made.value();
    CHECK(dev.info().gpu.vendor == GpuVendor::Unknown);
    CHECK(dev.info().gpu.vendorId == 0);
    CommandList& list = dev.begin_commands("native");
    auto r = list.begin_native({});
    REQUIRE(!r);
    CHECK(contains(r.error().message, "records no native commands"));
    auto e = list.end_native();
    REQUIRE(!e);
    CHECK(contains(e.error().message, "without begin_native"));
    CHECK(dev.native_view(View{}).d3d12Descriptor == 0);
    dev.submit(list);
}

TEST_CASE("native access: the SokolDevice names its GPU; D3D11 hands out its context, GL and Metal refuse") {
    auto& g = fa::test::gfx();
    if (!g.ok) {
        MESSAGE("no GPU here (" << g.error << "): the SokolDevice native access is skipped");
        return;
    }
    auto made = make_device(built_sokol_backend());
    REQUIRE_MESSAGE(made, (made ? "" : made.error().message));
    Device& dev = *made.value();
    const GpuIdentity& id = dev.info().gpu;
    INFO("backend " << backend_name(dev.backend()) << ", vendor " << gpu_vendor_name(id.vendor) << " 0x" << std::hex
                    << id.vendorId);
    if (id.vendorId) CHECK(id.vendor == gpu_vendor_from_pci(id.vendorId));
    if (dev.backend() == Backend::D3d11) {
        CHECK(id.vendorId != 0);
        CHECK(id.luidValid);
        CHECK(dev.native().adapter != nullptr);
    } else {
        CHECK(!id.luidValid);
        CHECK(id.deviceId == 0);  // GL and Metal name the GPU, not its PCI ids
        CHECK(dev.native().adapter == nullptr);
    }
#if defined(__APPLE__)
    if (dev.backend() == Backend::Metal && !id.software) CHECK(id.vendor != GpuVendor::Unknown);
#endif

    ImageDesc d;
    d.width = 4;
    d.height = 4;
    d.pixelFormat = PixelFormat::Rgba8;
    d.usage.colorAttachment = true;
    d.label = "native-target";
    const Image img = dev.make_image(d);
    REQUIRE(dev.state(img) == ResourceState::Valid);
    CommandList& list = dev.begin_commands("native");
    NativeUse use;
    use.image = img;
    use.state = NativeState::RenderTarget;
    std::array<NativeUse, 1> uses = {use};
    auto r = list.begin_native(uses);
    if (dev.backend() == Backend::D3d11) {
        REQUIRE_MESSAGE(r, r.error().to_string());
        CHECK(r.value().backend == Backend::D3d11);
        CHECK(r.value().list == dev.native().context);
        auto nested = list.begin_native(uses);
        REQUIRE(!nested);
        CHECK(contains(nested.error().message, "open already"));
        CHECK(list.end_native());
        CHECK(!list.end_native());
        uses[0].mip = 1;  // one mip only
        auto bad = list.begin_native(uses);
        REQUIRE(!bad);
        CHECK(contains(bad.error().message, "uses[0]: mips 1 + 0 are not inside"));
    } else {
        REQUIRE(!r);
        CHECK(contains(r.error().message, "records no native commands"));
        CHECK(contains(r.error().message, backend_name(dev.backend())));
        CHECK(!list.end_native());
    }
    dev.submit(list);
    if (dev.backend() == Backend::D3d11) {
        // A submitted list is not recording (the one immediate list is reused: begin_commands() opens it again).
        auto stale = list.begin_native({});
        REQUIRE(!stale);
        CHECK(contains(stale.error().message, "the list is not recording"));
    }
    dev.destroy_image(img);
}

// ---- device hooks (M78-P2b, gpu/device_hooks.h) ----------------------------------------------------------------------

namespace {

struct NamedHook : DeviceHook {
    std::string id;
    explicit NamedHook(std::string n) : id(std::move(n)) {}
    std::string_view name() const override { return id; }
};

}  // namespace

TEST_CASE("device hooks: the registry adds its hooks once to every device; a backend without hooks says why") {
    auto mine = std::make_shared<NamedHook>("caller's (test)");
    auto registered = std::make_shared<NamedHook>("registered (test)");
    register_device_hook(registered);
    register_device_hook(registered);  // once
    REQUIRE(registered_device_hooks().size() == 1);

    // The caller's first, then the registered ones; a hook in both lists is there once.
    const DeviceHooks all = with_registered_hooks({mine, registered, nullptr});
    REQUIRE(all.size() == 2);
    CHECK(all[0] == mine);
    CHECK(all[1] == registered);

    // The RecordingDevice calls no hook: each is unavailable, and the reason says which backends call them.
    DeviceInit init;
    init.hooks = {mine};
    auto dev = make_device(Backend::Recording, init);
    REQUIRE(dev);
    for (const auto& h : {std::shared_ptr<DeviceHook>(mine), std::shared_ptr<DeviceHook>(registered)}) {
        CHECK(!h->available());
        CHECK(contains(h->unavailable_reason(), "the recording backend calls no device hooks"));
        CHECK(contains(h->unavailable_reason(), "D3D12 or the Vulkan backend"));
    }
    CHECK(contains(device_hook_warning(Backend::Recording, *mine), "device hook 'caller's (test)' is unavailable"));

    // The first reason stays; a new device starts the hook available again.
    mine->mark_unavailable("a second reason");
    CHECK(!contains(mine->unavailable_reason(), "a second reason"));
    mine->mark_available();
    CHECK(mine->available());
    CHECK(mine->unavailable_reason().empty());

    unregister_device_hook(registered.get());
    CHECK(registered_device_hooks().empty());
}

TEST_CASE("device hooks: a hook a live D3D12 or Vulkan device holds is not marked unsupported by another device") {
    auto hook = std::make_shared<NamedHook>("shared (test)");
    DeviceInit init;
    init.hooks = {hook};

    // The first device that holds it starts it available; a RecordingDevice (or D3D11, GL, Metal) made meanwhile leaves
    // its state alone.
    HookAttachment first;
    std::vector<std::string> refused;
    const DeviceHooks took = first.attach({hook, hook, nullptr}, Backend::Vulkan, &refused);  // once each
    REQUIRE(took.size() == 1);
    CHECK(took[0].get() == hook.get());
    CHECK(refused.empty());
    CHECK(hook->in_use());
    CHECK(hook->available());
    auto recording = make_device(Backend::Recording, init);
    REQUIRE(recording);
    CHECK(hook->available());
    CHECK(hook->unavailable_reason().empty());

    // A second device cannot take it: it is left out, with a warning that says why, and the first device's state is
    // not touched (the hook is no more available than it was, no less).
    hook->mark_unavailable("the first device lost it");
    HookAttachment second;
    CHECK(second.attach({hook}, Backend::D3d12, &refused).empty());
    REQUIRE(refused.size() == 1);
    CHECK(contains(refused[0], "gpu d3d12: device hook 'shared (test)' is not used by this device"));
    CHECK(contains(refused[0], "another live D3D12 or Vulkan device holds it"));
    CHECK(!hook->available());
    CHECK(contains(hook->unavailable_reason(), "the first device lost it"));
    second.release();  // the second never held it: the first still does
    CHECK(hook->in_use());

    // mark_unsupported_if_unused is one step: refused while a device holds it, done when none does.
    CHECK(!hook->mark_unsupported_if_unused("no hooks here"));
    CHECK(contains(hook->unavailable_reason(), "the first device lost it"));

    // The last device that held it goes: a backend without hooks marks it, and the next device starts it available again.
    first.release();
    CHECK(!hook->in_use());
    auto after = make_device(Backend::Recording, init);
    REQUIRE(after);
    CHECK(!hook->available());
    CHECK(contains(hook->unavailable_reason(), "the recording backend calls no device hooks"));
    CHECK(hook->mark_unsupported_if_unused("replaced"));
    CHECK(hook->unavailable_reason() == "replaced");
    HookAttachment third;
    CHECK(third.attach({hook}, Backend::Vulkan).size() == 1);
    CHECK(hook->available());
    CHECK(hook->unavailable_reason().empty());
}
