// Native access for vendor SDKs on the engine's D3D12 backend (M78, docs/design/ARCHITECTURE_RENDERING_D3D12.md, "Native
// access for vendor SDKs"): the device names its adapter (vendor, device, LUID) and a command list records raw D3D12
// commands between begin_native and end_native, with the engine's barriers around them. On Windows every case makes a
// WARP device with the debug layer and checks that the layer reported no error; a Windows without WARP says so and
// passes, unless FA_D3D12_REQUIRE=1 (the Windows CI job). Nothing runs elsewhere (gpu_native_tests.cpp checks the
// backend-neutral part).
#include <doctest.h>

#if defined(_WIN32)

#include <array>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <memory>
#include <string>
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
    if (!d.value()->debug_layer_active())
        MESSAGE("d3d12: the debug layer is not installed (Graphics Tools): the case runs without its checks");
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
    submit_and_finish(*dev, list);
    const std::string errors = all_errors(*dev);
    CHECK(contains(errors, "a native section is open (hint: end_native() first"));
    CHECK(contains(errors, "still has a native section open"));

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

    dev->destroy_view(rtv);
    dev->destroy_image(img);
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

#endif  // _WIN32
