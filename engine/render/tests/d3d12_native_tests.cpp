// Native access for vendor SDKs on the engine's D3D12 backend (M78, docs/design/ARCHITECTURE_RENDERING_D3D12.md, "Native
// access for vendor SDKs"): the device names its adapter (vendor, device, LUID) and a command list records raw D3D12
// commands between begin_native and end_native, with the engine's barriers around them. On Windows every case makes a
// WARP device with the debug layer and checks that the layer reported no error; a Windows without WARP says so and
// passes, unless FA_D3D12_REQUIRE=1 (the Windows CI job); a Windows without the debug layer (Graphics Tools) runs them
// without its checks, unless FA_D3D12_REQUIRE_DEBUG_LAYER=1. Nothing runs elsewhere (gpu_native_tests.cpp checks the
// backend-neutral part).
#include <doctest.h>

#if defined(_WIN32)

#include <array>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "gpu/d3d12_device.h"

using namespace fa::gpu;
using fa::gpu::d3d12::D3d12Device;

namespace {

bool contains(const std::string& s, const std::string& part) { return s.find(part) != std::string::npos; }

// A WARP device with the debug layer, or null (with a MESSAGE) where this Windows has none; FA_D3D12_REQUIRE=1 fails
// instead.
std::unique_ptr<D3d12Device> make_warp() {
    D3d12Options o;
    o.warp = true;
    o.debugLayer = true;
    auto d = D3d12Device::create(o);
    if (!d) {
        const char* req = std::getenv("FA_D3D12_REQUIRE");
        if (req && std::strcmp(req, "1") == 0) {
            FAIL("d3d12: FA_D3D12_REQUIRE=1 but there is no WARP device: " << d.error().to_string());
            return nullptr;
        }
        MESSAGE("d3d12: skipped, no WARP device: " << d.error().to_string());
        return nullptr;
    }
    if (!d.value()->debug_layer_active()) {
        // Without the layer the cases below only check pixels: a CI job that installed Graphics Tools sets
        // FA_D3D12_REQUIRE_DEBUG_LAYER=1 so that a runner image that lost it fails here instead of passing blind.
        const char* layer = std::getenv("FA_D3D12_REQUIRE_DEBUG_LAYER");
        if (layer && std::strcmp(layer, "1") == 0) {
            FAIL("d3d12: FA_D3D12_REQUIRE_DEBUG_LAYER=1 but the debug layer is not installed (Graphics Tools): the "
                 "native cases would only check pixels");
            return nullptr;
        }
        MESSAGE("d3d12: the debug layer is not installed (Graphics Tools): the case runs without its checks");
    }
    return std::move(d.value());
}

std::string layer_errors(D3d12Device& dev) {
    std::string s;
    for (const std::string& e : dev.errors())
        if (contains(e, "debug layer")) s += e + "\n";
    return s;
}

std::string all_errors(D3d12Device& dev) {
    std::string s;
    for (const std::string& e : dev.errors()) s += e + "\n";
    return s;
}

void submit_and_finish(D3d12Device& dev, CommandList& list) {
    dev.submit(list);
    dev.commit();
    auto r = dev.wait_idle();
    REQUIRE_MESSAGE(r, r.error().to_string());
}

Image make_target(Device& dev, const char* label) {
    ImageDesc d;
    d.width = 4;
    d.height = 4;
    d.pixelFormat = PixelFormat::Rgba8;
    d.usage.writeTransient = true;
    d.usage.colorAttachment = true;
    d.label = label;
    return dev.make_image(d);
}

View make_rtv(Device& dev, Image image) {
    ViewDesc vd;
    vd.colorAttachment.image = image;
    vd.label = "native-rtv";
    return dev.make_view(vd);
}

D3D12_CPU_DESCRIPTOR_HANDLE rtv_handle(Device& dev, View view) {
    D3D12_CPU_DESCRIPTOR_HANDLE h{};
    h.ptr = static_cast<SIZE_T>(dev.native_view(view).d3d12Descriptor);
    return h;
}

ID3D12GraphicsCommandList* native_list(const NativeCommands& n) {
    return static_cast<ID3D12GraphicsCommandList*>(const_cast<void*>(n.list));
}

std::vector<std::uint8_t> solid(int texels, std::uint8_t r, std::uint8_t g, std::uint8_t b) {
    std::vector<std::uint8_t> v;
    for (int i = 0; i < texels; ++i) v.insert(v.end(), {r, g, b, 255});
    return v;
}

}  // namespace

TEST_CASE("d3d12 native: a WARP device names its adapter and hands it out") {
    auto dev = make_warp();
    if (!dev) return;
    const GpuIdentity& id = dev->info().gpu;
    CHECK(id.vendor == GpuVendor::Microsoft);
    CHECK(id.vendorId == kPciVendorMicrosoft);
    CHECK(id.deviceId != 0);
    CHECK(id.software);
    CHECK(id.luidValid);

    const NativeDevice nd = dev->native();
    CHECK(nd.device != nullptr);
    CHECK(nd.context != nullptr);  // the direct queue
    REQUIRE(nd.adapter != nullptr);
    CHECK(nd.instance == nullptr);
    if (dev->features().asyncCompute) CHECK(nd.computeQueue != nullptr);
    DXGI_ADAPTER_DESC1 desc{};
    REQUIRE(SUCCEEDED(static_cast<IDXGIAdapter1*>(const_cast<void*>(nd.adapter))->GetDesc1(&desc)));
    CHECK(desc.VendorId == id.vendorId);
    CHECK(desc.DeviceId == id.deviceId);
    CHECK(desc.AdapterLuid.LowPart == id.luidLow);
    CHECK(desc.AdapterLuid.HighPart == id.luidHigh);

    const Image img = make_target(*dev, "native-ids");
    REQUIRE(dev->state(img) == ResourceState::Valid);
    CHECK(dev->native_image(img).resource != nullptr);
    CHECK(dev->native_image(img).nativeFormat == std::uint32_t(d3d12::format_info(PixelFormat::Rgba8).resource));
    const View rtv = make_rtv(*dev, img);
    const NativeView nv = dev->native_view(rtv);
    CHECK(nv.d3d12Descriptor != 0);
    CHECK(nv.nativeFormat == std::uint32_t(d3d12::format_info(PixelFormat::Rgba8).rtv));
    CHECK(nv.image.id == img.id);
    CHECK(nv.vkImageView == 0);
    CHECK(dev->native_view(View{}).d3d12Descriptor == 0);
    dev->destroy_view(rtv);
    dev->destroy_image(img);
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

TEST_CASE("d3d12 native: a native clear and copy between engine commands, with the engine's barriers around them") {
    auto dev = make_warp();
    if (!dev) return;
    const Image img = make_target(*dev, "native-clear");
    REQUIRE(dev->state(img) == ResourceState::Valid);
    const View rtv = make_rtv(*dev, img);

    std::vector<std::uint8_t> data(256);
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
    uses[0].state = NativeState::RenderTarget;
    uses[1].buffer = src;
    uses[1].state = NativeState::CopySource;
    uses[2].buffer = dst;
    uses[2].state = NativeState::CopyDest;
    auto n = list.begin_native(uses);
    REQUIRE_MESSAGE(n, n.error().to_string());
    CHECK(n.value().backend == Backend::D3d12);
    ID3D12GraphicsCommandList* cl = native_list(n.value());
    const float magenta[4] = {1.0f, 0.0f, 1.0f, 1.0f};
    cl->ClearRenderTargetView(rtv_handle(*dev, rtv), magenta, 0, nullptr);
    cl->CopyBufferRegion(static_cast<ID3D12Resource*>(const_cast<void*>(dev->native_buffer(dst).buffer)), 0,
                         static_cast<ID3D12Resource*>(const_cast<void*>(dev->native_buffer(src).buffer)), 0,
                         data.size());
    auto e = list.end_native();
    REQUIRE_MESSAGE(e, e.error().to_string());

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

    dev->destroy_view(rtv);
    dev->destroy_image(img);
    dev->destroy_buffer(src);
    dev->destroy_buffer(dst);
    dev->destroy_buffer(out);
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
}

TEST_CASE("d3d12 native: a state the native commands leave is declared in end_native's leftIn") {
    auto dev = make_warp();
    if (!dev) return;
    const Image img = make_target(*dev, "native-left");
    REQUIRE(dev->state(img) == ResourceState::Valid);
    const View rtv = make_rtv(*dev, img);

    CommandList& list = dev->begin_commands("native-left");
    std::array<NativeUse, 1> uses{};
    uses[0].image = img;
    uses[0].state = NativeState::RenderTarget;
    auto n = list.begin_native(uses);
    REQUIRE_MESSAGE(n, n.error().to_string());
    ID3D12GraphicsCommandList* cl = native_list(n.value());
    const float cyan[4] = {0.0f, 1.0f, 1.0f, 1.0f};
    cl->ClearRenderTargetView(rtv_handle(*dev, rtv), cyan, 0, nullptr);
    // The SDK's own barrier: RENDER_TARGET -> shader resource, which leftIn then tells the engine.
    D3D12_RESOURCE_BARRIER b{};
    b.Type = D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
    b.Transition.pResource = static_cast<ID3D12Resource*>(const_cast<void*>(dev->native_image(img).resource));
    b.Transition.Subresource = D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES;
    b.Transition.StateBefore = D3D12_RESOURCE_STATE_RENDER_TARGET;
    b.Transition.StateAfter =
        D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE | D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE;
    cl->ResourceBarrier(1, &b);

    std::array<NativeUse, 1> wrong{};
    wrong[0].image = img;
    wrong[0].state = NativeState::ShaderRead;
    wrong[0].mip = 0;
    wrong[0].mipCount = 1;
    wrong[0].layer = 0;
    wrong[0].layerCount = 1;
    std::array<NativeUse, 1> left = wrong;
    BufferDesc bd;
    bd.size = 16;
    bd.label = "undeclared";
    const Buffer other = dev->make_buffer(bd);
    wrong[0] = NativeUse{};
    wrong[0].buffer = other;
    wrong[0].state = NativeState::CopySource;
    auto bad = list.end_native(wrong);
    REQUIRE(!bad);
    CHECK(contains(bad.error().message, "was not declared by begin_native"));
    auto e = list.end_native(left);
    REQUIRE_MESSAGE(e, e.error().to_string());
    submit_and_finish(*dev, list);

    std::vector<std::uint8_t> pixels;
    auto r = dev->read_image_rgba8(img, 4, 4, pixels);
    REQUIRE_MESSAGE(r, r.error().to_string());
    CHECK(pixels == solid(16, 0, 255, 255));
    dev->destroy_view(rtv);
    dev->destroy_image(img);
    dev->destroy_buffer(other);
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
}

TEST_CASE("d3d12 native: misuses are refused, and an open section is closed at submit") {
    auto dev = make_warp();
    if (!dev) return;
    const Image img = make_target(*dev, "native-misuse");
    REQUIRE(dev->state(img) == ResourceState::Valid);
    const View rtv = make_rtv(*dev, img);

    std::array<NativeUse, 1> one{};
    one[0].image = img;
    one[0].state = NativeState::RenderTarget;
    CommandList& list = dev->begin_commands("native-misuse");
    std::array<NativeUse, 1> storage = one;
    storage[0].state = NativeState::UnorderedAccess;
    auto r = list.begin_native(storage);
    REQUIRE(!r);
    CHECK(contains(r.error().message, "uses[0]: image 'native-misuse' was not made with ImageUsage::storageImage"));

    PassDesc pass;
    pass.color = rtv;
    pass.format.color = PixelFormat::Rgba8;
    pass.colorLoad = LoadAction::Clear;
    list.begin_pass(pass);
    r = list.begin_native({});
    REQUIRE(!r);
    CHECK(contains(r.error().message, "inside a pass"));
    list.end_pass();

    auto n = list.begin_native(one);
    REQUIRE_MESSAGE(n, n.error().to_string());
    list.begin_pass(pass);  // refused: the pass fails
    list.end_pass();

    // Writes and copies inside a section are refused and skipped; the section stays open (the next call proves it).
    BufferDesc bufDesc;
    bufDesc.size = 64;
    bufDesc.usage.copySrc = true;
    bufDesc.usage.copyDst = true;
    bufDesc.label = "native-refused-a";
    const Buffer refusedA = dev->make_buffer(bufDesc);
    bufDesc.label = "native-refused-b";
    const Buffer refusedB = dev->make_buffer(bufDesc);
    const std::vector<std::uint8_t> bytes(64, 7);
    BufferWrite bw;
    bw.buffer = refusedA;
    bw.data = Range{bytes.data(), bytes.size()};
    list.write_buffer(bw);
    BufferCopy bc;
    bc.src = refusedA;
    bc.dst = refusedB;
    bc.size = 16;
    list.copy_buffer_to_buffer(bc);
    ImageWrite iw;
    iw.data = Range{bytes.data(), bytes.size()};
    iw.bytesPerRow = 16;
    iw.dst.image = img;
    iw.size.width = 4;
    iw.size.height = 4;
    list.write_image(iw);
    BufferImageCopy ic;
    ic.src = refusedA;
    ic.bytesPerRow = 16;
    ic.dst.image = img;
    ic.size.width = 4;
    ic.size.height = 4;
    list.copy_buffer_to_image(ic);
    const std::string refused = all_errors(*dev);
    for (const char* call : {"write_buffer", "copy_buffer_to_buffer", "write_image", "copy_buffer_to_image"})
        CHECK_MESSAGE(contains(refused, std::string("CommandList::") + call +
                                            " in list 'native-misuse': a native "
                                            "section is open (hint: end_native() "
                                            "first; the call is skipped)"),
                      call);
    auto closed = list.end_native();
    CHECK_MESSAGE(closed, closed.error().to_string());  // still open: the refused calls did not close it
    // The section left open here is closed at submit (see below).
    n = list.begin_native(one);
    REQUIRE_MESSAGE(n, n.error().to_string());
    submit_and_finish(*dev, list);
    const std::string errors = all_errors(*dev);
    CHECK(contains(errors, "a native section is open (hint: end_native() first"));
    CHECK(contains(errors, "still has a native section open"));

    // A submitted list records nothing: begin_native says so instead of opening a section on it.
    r = list.begin_native({});
    REQUIRE(!r);
    CHECK(contains(r.error().message, "the list is not recording"));

    // A list on the copy queue takes no native section (a device without one runs the list on another queue, which
    // takes it).
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

    dev->destroy_buffer(refusedA);
    dev->destroy_buffer(refusedB);
    dev->destroy_view(rtv);
    dev->destroy_image(img);
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

// ---- device hooks (M78-P2b, gpu/device_hooks.h) ----------------------------------------------------------------------

namespace {

// A hook that records what the device hands it and, when asked to, replaces the DXGI factory with a new one (as
// Streamline's slUpgradeInterface hands a proxy back) or fails and hands a new factory anyway (which the engine must
// release). It keeps a reference of its own to the factory it made, so the test can count what the engine holds.
struct D3d12Hook : DeviceHook {
    std::string id;
    bool replaceFactory = false, fail = false;
    int before = 0, created = 0, destroying = 0;
    bool sawWarp = false;
    const void* adapter = nullptr;
    const void* device = nullptr;
    const void* queue = nullptr;
    const void* factorySeen = nullptr;
    IDXGIFactory4* made = nullptr;

    explicit D3d12Hook(std::string n) : id(std::move(n)) {}
    std::string_view name() const override { return id; }
    void d3d12_before_device(const D3d12BeforeDevice& b) override {
        ++before;
        sawWarp = b.warp;
        CHECK(b.factory != nullptr);
        CHECK(b.adapter != nullptr);
    }
    void d3d12_device_created(D3d12DeviceCreated& c) override {
        ++created;
        adapter = c.adapter;
        device = c.device;
        queue = c.queue;
        factorySeen = c.factory;
        if (!replaceFactory && !fail) return;
        REQUIRE(SUCCEEDED(CreateDXGIFactory2(0, __uuidof(IDXGIFactory4), reinterpret_cast<void**>(&made))));
        made->AddRef();  // the hook's own reference; the one CreateDXGIFactory2 gave goes to the engine
        c.factory = made;
        if (fail) c.error = "the test hook fails on purpose";
    }
    void device_destroying() override { ++destroying; }
};

}  // namespace

TEST_CASE("d3d12 native: device hooks hear the adapter and the device, may replace the factory, and a failing one "
          "changes nothing") {
    auto first = std::make_shared<D3d12Hook>("replaces the factory (test)");
    first->replaceFactory = true;
    auto failing = std::make_shared<D3d12Hook>("fails (test)");
    failing->fail = true;
    auto last = std::make_shared<D3d12Hook>("sees the replacement (test)");
    D3d12Options o;
    o.warp = true;
    o.debugLayer = true;
    o.init.hooks = {first, failing, last};
    auto d = D3d12Device::create(o);
    if (!d) {
        const char* req = std::getenv("FA_D3D12_REQUIRE");
        if (req && std::strcmp(req, "1") == 0) FAIL("d3d12: FA_D3D12_REQUIRE=1 but there is no WARP device");
        MESSAGE("d3d12: skipped, no WARP device: " << d.error().to_string());
        return;
    }
    std::unique_ptr<D3d12Device> dev = std::move(d.value());
    const NativeDevice nd = dev->native();

    CHECK(first->before == 1);
    CHECK(first->sawWarp);
    CHECK(first->created == 1);
    CHECK(first->device == nd.device);
    CHECK(first->queue == nd.context);
    CHECK(first->adapter == nd.adapter);
    CHECK(first->available());

    // The failing hook is unavailable with its reason; the factory it handed was released at once.
    CHECK(!failing->available());
    CHECK(contains(failing->unavailable_reason(), "the test hook fails on purpose"));
    CHECK(contains(failing->unavailable_reason(), "on "));
    REQUIRE(failing->made != nullptr);
    CHECK(failing->made->Release() == 0);
    bool warned = false;
    for (const std::string& w : dev->warnings()) warned = warned || contains(w, "device hook 'fails (test)'");
    CHECK(warned);

    // The hook after them sees the first one's factory, not the engine's own nor the failing one's.
    CHECK(last->created == 1);
    REQUIRE(first->made != nullptr);
    CHECK(last->factorySeen == first->made);
    CHECK(last->device == nd.device);

    // A frame still works; the device goes, the available hooks hear it, and the replacement factory is released.
    const Image img = make_target(*dev, "hooked");
    CommandList& list = dev->begin_commands("hooked");
    PassDesc p;
    const View rtv = make_rtv(*dev, img);
    p.color = rtv;
    p.format.color = PixelFormat::Rgba8;
    p.colorLoad = LoadAction::Clear;
    p.label = "hooked";
    list.begin_pass(p);
    list.end_pass();
    submit_and_finish(*dev, list);
    dev->destroy_view(rtv);
    dev->destroy_image(img);
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
    dev.reset();
    CHECK(first->destroying == 1);
    CHECK(last->destroying == 1);
    CHECK(failing->destroying == 0);
    CHECK(first->made->Release() == 0);
}

#endif  // _WIN32
