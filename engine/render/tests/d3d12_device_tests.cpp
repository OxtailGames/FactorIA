// The engine's own D3D12 backend (src/gpu/d3d12_*: resources M77-P7a, shaders, pipelines and drawing M77-P7c1, GPU
// timers and asynchronous reads M77-P7c2, the swapchain on a window M77-P9c). On Windows every case makes a WARP device
// with the debug layer and checks that the layer reported no error; the drawing cases read their targets back and
// check them per texel; the swapchain cases present into a hidden Win32 window; a Windows without WARP or D3D12 says
// so (MESSAGE) and passes.
// Elsewhere one case checks the factory's teaching error.
#include <doctest.h>

#include <algorithm>
#include <array>
#include <atomic>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <memory>
#include <string>
#include <thread>
#include <vector>

#include "fa/core/fs.h"
#include "gpu/d3d12_device.h"
#include "gpu/sokol_device.h"
#include "shaders/blit.glsl.h"

using namespace fa::gpu;

namespace {

bool contains(const std::string& s, const std::string& part) { return s.find(part) != std::string::npos; }

}  // namespace

#if !defined(_WIN32)

TEST_CASE("d3d12: make_d3d12_device off Windows is a teaching error") {
    auto d = make_d3d12_device();
    REQUIRE(!d);
    CHECK(contains(d.error().message, "runs on Windows only"));
    CHECK(contains(d.error().message, backend_name(built_sokol_backend())));
    CHECK(contains(d.error().hint, "make_device(built_sokol_backend())"));
}

#else

using fa::gpu::d3d12::D3d12Device;

namespace {

// A WARP device with the debug layer, or null (with a MESSAGE) when this Windows has no D3D12 WARP device.
std::unique_ptr<D3d12Device> make_warp(D3d12Options o = {}) {
    o.warp = true;
    o.debugLayer = true;
    auto d = D3d12Device::create(o);
    if (!d) {
        MESSAGE("d3d12: skipped, no WARP device: " << d.error().to_string());
        return nullptr;
    }
    if (!d.value()->debug_layer_active())
        MESSAGE("d3d12: the debug layer is not installed (Graphics Tools): the case runs without its checks");
    return std::move(d.value());
}

// The debug layer's errors (the backend's own reports, which some cases provoke, are not counted).
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

std::vector<std::uint8_t> pattern(std::size_t n, std::uint32_t seed) {
    std::vector<std::uint8_t> v(n);
    std::uint32_t x = seed * 2654435761u + 1u;
    for (std::size_t i = 0; i < n; ++i) {
        x = x * 1664525u + 1013904223u;
        v[i] = std::uint8_t(x >> 24);
    }
    return v;
}

Range range_of(const std::vector<std::uint8_t>& v) { return Range{v.data(), v.size()}; }

// Rows of a tightly packed `width`-texel-wide image, the rectangle (x, y, w, h), `bpp` bytes per texel.
std::vector<std::uint8_t> crop(const std::vector<std::uint8_t>& img, int width, int bpp, int x, int y, int w, int h) {
    std::vector<std::uint8_t> out;
    for (int row = y; row < y + h; ++row) {
        const std::uint8_t* p =
            img.data() + (std::size_t(row) * std::size_t(width) + std::size_t(x)) * std::size_t(bpp);
        out.insert(out.end(), p, p + std::size_t(w) * std::size_t(bpp));
    }
    return out;
}

void submit_and_finish(D3d12Device& dev, CommandList& list) {
    dev.submit(list);
    dev.commit();
    auto r = dev.wait_idle();
    REQUIRE_MESSAGE(r, r.error().to_string());
}

}  // namespace

TEST_CASE("d3d12: D3d12Options contradictions are errors before any D3D12 work") {
    D3d12Options o;
    o.framesInFlight = 0;
    auto a = make_d3d12_device(o);
    REQUIRE(!a);
    CHECK(contains(a.error().message, "framesInFlight"));
    o = {};
    o.gpuValidation = true;
    auto b = make_d3d12_device(o);
    REQUIRE(!b);
    CHECK(contains(b.error().hint, "debugLayer"));
    o = {};
    o.uploadRingBytes = 1024;
    auto c = make_d3d12_device(o);
    REQUIRE(!c);
    CHECK(contains(c.error().message, "uploadRingBytes"));
    o = {};
    o.frameSamplerDescriptors = 2048;
    auto e = make_d3d12_device(o);
    REQUIRE(!e);
    CHECK(contains(e.error().message, "2048"));
}

TEST_CASE("d3d12: a WARP device answers what it can do") {
    auto dev = make_warp();
    if (!dev) return;
    std::string step = "info";
    INFO("step: " << step);
    CHECK(dev->backend() == Backend::D3d12);
    CHECK(std::string(dev->info().name) == backend_name(Backend::D3d12));
    CHECK(dev->warp());
    CHECK(!dev->adapter_name().empty());
    CHECK(dev->frames_in_flight() == kInflightFrames);
    CHECK(dev->features().compute);
    CHECK(dev->features().originTopLeft);
    CHECK(dev->limits().maxImageSize2d >= 16384);
    step = "pixel formats";
    const PixelFormatCaps rgba8 = dev->pixel_format_caps(PixelFormat::Rgba8);
    CHECK(rgba8.sample);
    CHECK(rgba8.filter);
    CHECK(rgba8.render);
    CHECK(rgba8.blend);
    CHECK(rgba8.bytesPerPixel == 4);
    const PixelFormatCaps depth = dev->pixel_format_caps(PixelFormat::Depth);
    CHECK(depth.depth);
    CHECK(depth.render);
    CHECK(!depth.filter);
    CHECK(dev->pixel_format_caps(PixelFormat::Bc7Rgba).sample);
    CHECK(dev->pixel_format_caps(PixelFormat::Bc7Rgba).compressed);
    CHECK(!dev->pixel_format_caps(PixelFormat::Etc2Rgb8).sample);
    CHECK(dev->pixel_format_caps(PixelFormat::R32F).write);
    step = "natives";
    CHECK(dev->native().device == dev->d3d_device());
    CHECK(dev->native().context == dev->queue());
    CHECK(dev->environment_defaults().colorFormat == PixelFormat::Bgra8);
    CHECK(dev->environment_defaults().depthFormat == PixelFormat::DepthStencil);
    step = "timers and async reads";
    std::string why;
    CHECK_MESSAGE(dev->timer_supported(&why), why);  // WARP's direct queue has timestamps
    CHECK(dev->timestamp_frequency() > 0);
    CHECK(dev->async_read_supported());
    step = "resource binding tier";
    CHECK(dev->resource_binding_tier() >= 1);
    CHECK(dev->resource_binding_tier() <= 3);
    if (dev->resource_binding_tier() >= 2)
        CHECK(dev->bindless_descriptors() == std::uint32_t(D3d12Options{}.bindlessDescriptors));
    else
        CHECK(dev->bindless_descriptors() == 0);  // tier 1 has no unbounded ranges: no bindless table
    step = "the debug layer said nothing";
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
}

TEST_CASE("d3d12: buffers round-trip through make_buffer, write_buffer and copy_buffer_to_buffer") {
    auto dev = make_warp();
    if (!dev) return;
    std::string step = "make_buffer with data, read_buffer";
    INFO("step: " << step);
    const std::vector<std::uint8_t> data = pattern(1000, 1);
    BufferDesc bd;
    bd.size = data.size();
    bd.usage.storageBuffer = true;
    bd.usage.copySrc = true;
    bd.usage.writeTransient = true;
    bd.data = range_of(data);
    bd.label = "round-trip";
    const Buffer a = dev->make_buffer(bd);
    REQUIRE(dev->state(a) == ResourceState::Valid);
    CHECK(dev->native_buffer(a).buffer != nullptr);
    std::vector<std::uint8_t> out;
    auto r = dev->read_buffer(a, 0, data.size(), out);
    REQUIRE_MESSAGE(r, r.error().to_string());
    CHECK(out == data);

    step = "write_buffer in a list";
    const std::vector<std::uint8_t> patch = pattern(100, 2);
    CommandList& list = dev->begin_commands("write");
    BufferWrite w;
    w.data = range_of(patch);
    w.buffer = a;
    w.dstOffset = 200;
    list.write_buffer(w);
    submit_and_finish(*dev, list);
    std::vector<std::uint8_t> expected = data;
    std::memcpy(expected.data() + 200, patch.data(), patch.size());
    r = dev->read_buffer(a, 0, data.size(), out);
    REQUIRE_MESSAGE(r, r.error().to_string());
    CHECK(out == expected);
    r = dev->read_buffer(a, 196, 8, out);
    REQUIRE(r);
    CHECK(out == std::vector<std::uint8_t>(expected.begin() + 196, expected.begin() + 204));

    step = "copy_buffer_to_buffer";
    BufferDesc cd;
    cd.size = 512;
    cd.usage.copyDst = true;
    cd.label = "copy-dst";
    const Buffer b = dev->make_buffer(cd);
    REQUIRE(dev->state(b) == ResourceState::Valid);
    CommandList& copy = dev->begin_commands("copy");
    BufferCopy c;
    c.src = a;
    c.srcOffset = 100;
    c.dst = b;
    c.dstOffset = 8;
    c.size = 400;
    copy.copy_buffer_to_buffer(c);
    submit_and_finish(*dev, copy);
    r = dev->read_buffer(b, 8, 400, out);
    REQUIRE_MESSAGE(r, r.error().to_string());
    CHECK(out == std::vector<std::uint8_t>(expected.begin() + 100, expected.begin() + 500));

    step = "a write past the end is a teaching error, nothing is recorded";
    CommandList& bad = dev->begin_commands("bad");
    w.dstOffset = 950;
    bad.write_buffer(w);
    submit_and_finish(*dev, bad);
    CHECK(contains(all_errors(*dev), "go past buffer 'round-trip'"));

    step = "two lists of one frame: the second, recorded first, copies what the first writes";
    // The fix-up barriers move `a` from COPY_DEST (list 1's end) to COPY_SOURCE (list 2's start).
    CommandList& second = dev->begin_commands("second");
    CommandList& first = dev->begin_commands("first");
    c.srcOffset = 0;
    c.dstOffset = 0;
    c.size = 100;
    second.copy_buffer_to_buffer(c);
    w.dstOffset = 0;
    first.write_buffer(w);
    dev->submit(first);
    dev->submit(second);
    dev->commit();
    REQUIRE(dev->wait_idle());
    r = dev->read_buffer(b, 0, 100, out);
    REQUIRE(r);
    CHECK(out == patch);
    dev->destroy_buffer(a);
    dev->destroy_buffer(b);
    CHECK(dev->state(a) == ResourceState::Invalid);
    step = "the debug layer said nothing";
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

TEST_CASE("d3d12: RGBA8 and RGBA16F images with mips round-trip, and write_image lands in one mip") {
    auto dev = make_warp();
    if (!dev) return;
    std::string step = "RGBA8 16x8, 4 mips, initial data";
    INFO("step: " << step);
    ImageDesc id;
    id.width = 16;
    id.height = 8;
    id.numMipmaps = 4;
    id.pixelFormat = PixelFormat::Rgba8;
    id.usage.writeTransient = true;
    id.label = "rgba8-mips";
    std::vector<std::vector<std::uint8_t>> mips;
    for (int m = 0; m < 4; ++m) {
        mips.push_back(pattern(std::size_t(16 >> m) * std::size_t(std::max(8 >> m, 1)) * 4, 10u + std::uint32_t(m)));
        id.data.mipLevels[m] = range_of(mips.back());
    }
    const Image img = dev->make_image(id);
    REQUIRE(dev->state(img) == ResourceState::Valid);
    CHECK(dev->native_image(img).resource != nullptr);
    std::vector<std::uint8_t> out;
    for (int m = 0; m < 4; ++m) {
        const int w = 16 >> m, h = std::max(8 >> m, 1);
        auto r = dev->read_image_region(img, m, 0, 0, 0, w, h, out);
        REQUIRE_MESSAGE(r, r.error().to_string());
        CHECK_MESSAGE(out == mips[std::size_t(m)], "mip " << m);
    }
    auto r8 = dev->read_image_rgba8(img, 16, 8, out);
    REQUIRE(r8);
    CHECK(out == mips[0]);

    step = "write_image into a 3x2 region of mip 1";
    const std::vector<std::uint8_t> patch = pattern(3 * 2 * 4, 20);
    CommandList& list = dev->begin_commands("write-image");
    ImageWrite w;
    w.data = range_of(patch);
    w.bytesPerRow = 3 * 4;
    w.dst.image = img;
    w.dst.mipLevel = 1;
    w.dst.x = 4;
    w.dst.y = 1;
    w.size.width = 3;
    w.size.height = 2;
    list.write_image(w);
    submit_and_finish(*dev, list);
    std::vector<std::uint8_t> expected = mips[1];
    for (int row = 0; row < 2; ++row)
        std::memcpy(expected.data() + (std::size_t(row + 1) * 8 + 4) * 4, patch.data() + std::size_t(row) * 12, 12);
    auto r = dev->read_image_region(img, 1, 0, 0, 0, 8, 4, out);
    REQUIRE_MESSAGE(r, r.error().to_string());
    CHECK(out == expected);
    r = dev->read_image_region(img, 1, 0, 4, 1, 3, 2, out);
    REQUIRE(r);
    CHECK(out == patch);

    step = "RGBA16F 8x8, 2 mips";
    ImageDesc hd;
    hd.width = 8;
    hd.height = 8;
    hd.numMipmaps = 2;
    hd.pixelFormat = PixelFormat::Rgba16F;
    hd.label = "rgba16f-mips";
    std::vector<std::uint8_t> h0(8 * 8 * 8), h1(4 * 4 * 8);
    auto fill_half = [](std::vector<std::uint8_t>& v, float base) {
        for (std::size_t i = 0; i < v.size() / 2; ++i) {
            // halves of small integers + 0.5: exact in half precision
            const float f = base + float(i % 64) * 0.5f;
            const auto bits = std::uint32_t(f * 2.0f);  // f = bits / 2, bits < 2048
            std::uint16_t h = 0;
            if (bits != 0) {
                int e = 0;
                while ((bits >> (e + 1)) != 0) ++e;  // 2^e <= bits
                const std::uint32_t mant = (bits << (10 - e)) & 0x3FFu;
                h = std::uint16_t(((e - 1 + 15) << 10) | int(mant));
            }
            std::memcpy(v.data() + i * 2, &h, 2);
        }
    };
    fill_half(h0, 0.0f);
    fill_half(h1, 1.0f);
    hd.data.mipLevels[0] = range_of(h0);
    hd.data.mipLevels[1] = range_of(h1);
    const Image himg = dev->make_image(hd);
    REQUIRE(dev->state(himg) == ResourceState::Valid);
    std::vector<float> floats;
    auto rh = dev->read_image_rgba16f(himg, 8, 8, floats);
    REQUIRE_MESSAGE(rh, rh.error().to_string());
    REQUIRE(floats.size() == 8 * 8 * 4);
    for (std::size_t i = 0; i < floats.size(); ++i) {
        CHECK_MESSAGE(floats[i] == doctest::Approx(float(i % 64) * 0.5f), "texel value " << i);
        if (floats[i] != doctest::Approx(float(i % 64) * 0.5f)) break;
    }
    r = dev->read_image_region(himg, 1, 0, 0, 0, 4, 4, out);
    REQUIRE_MESSAGE(r, r.error().to_string());
    CHECK(out == h1);

    step = "BGRA8 comes back as RGBA";
    ImageDesc bd;
    bd.width = 2;
    bd.height = 1;
    bd.pixelFormat = PixelFormat::Bgra8;
    const std::vector<std::uint8_t> bgra = {1, 2, 3, 4, 5, 6, 7, 8};
    bd.data.mipLevels[0] = range_of(bgra);
    const Image bimg = dev->make_image(bd);
    REQUIRE(dev->state(bimg) == ResourceState::Valid);
    r8 = dev->read_image_rgba8(bimg, 2, 1, out);
    REQUIRE(r8);
    CHECK(out == std::vector<std::uint8_t>{3, 2, 1, 4, 7, 6, 5, 8});

    step = "an array image: each layer keeps its own data";
    ImageDesc ad;
    ad.type = ImageType::Array;
    ad.width = 4;
    ad.height = 4;
    ad.numSlices = 3;
    ad.pixelFormat = PixelFormat::R32F;
    ad.usage.storageImage = true;
    const std::vector<std::uint8_t> layers = pattern(4 * 4 * 4 * 3, 30);
    ad.data.mipLevels[0] = range_of(layers);
    const Image aimg = dev->make_image(ad);
    REQUIRE(dev->state(aimg) == ResourceState::Valid);
    r = dev->read_image_region(aimg, 0, 2, 0, 0, 4, 4, out);
    REQUIRE_MESSAGE(r, r.error().to_string());
    CHECK(out == std::vector<std::uint8_t>(layers.begin() + 128, layers.end()));
    r = dev->read_storage_image(aimg, PixelFormat::R32F, 1, 1, 2, 2, out);
    REQUIRE(r);
    CHECK(out == crop(std::vector<std::uint8_t>(layers.begin(), layers.begin() + 64), 4, 4, 1, 1, 2, 2));
    auto wrong = dev->read_storage_image(aimg, PixelFormat::Rgba8, 0, 0, 1, 1, out);
    REQUIRE(!wrong);
    CHECK(contains(wrong.error().message, "asked for"));

    step = "views of every kind";
    ViewDesc vd;
    vd.texture.image = img;
    vd.texture.mipLevels = {1, 2};
    CHECK(dev->state(dev->make_view(vd)) == ResourceState::Valid);
    ViewDesc sv;
    sv.storageImage.image = aimg;
    sv.storageImage.slice = 1;
    CHECK(dev->state(dev->make_view(sv)) == ResourceState::Valid);
    ImageDesc rt;
    rt.width = 8;
    rt.height = 8;
    rt.usage.colorAttachment = true;
    const Image rimg = dev->make_image(rt);
    REQUIRE(dev->state(rimg) == ResourceState::Valid);
    ViewDesc cv;
    cv.colorAttachment.image = rimg;
    CHECK(dev->state(dev->make_view(cv)) == ResourceState::Valid);
    ImageDesc dd;
    dd.width = 8;
    dd.height = 8;
    dd.usage.depthStencilAttachment = true;
    dd.sampleCount = 4;
    const Image dimg = dev->make_image(dd);
    REQUIRE(dev->state(dimg) == ResourceState::Valid);
    ViewDesc dv;
    dv.depthStencilAttachment.image = dimg;
    CHECK(dev->state(dev->make_view(dv)) == ResourceState::Valid);
    ViewDesc bad;
    bad.storageImage.image = img;  // not a storage image
    CHECK(dev->state(dev->make_view(bad)) == ResourceState::Failed);
    CHECK(contains(all_errors(*dev), "was not made with ImageUsage::storageImage"));
    SamplerDesc sd;
    sd.minFilter = sd.magFilter = Filter::Linear;
    sd.compare = CompareFunc::LessEqual;
    sd.wrapU = Wrap::ClampToBorder;
    CHECK(dev->state(dev->make_sampler(sd)) == ResourceState::Valid);
    sd.maxAnisotropy = 8;
    sd.compare = CompareFunc::Default;
    CHECK(dev->state(dev->make_sampler(sd)) == ResourceState::Valid);

    step = "the debug layer said nothing";
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

TEST_CASE("d3d12: copy_buffer_to_image with aligned rows and with rows that need repacking") {
    auto dev = make_warp();
    if (!dev) return;
    std::string step = "aligned: 64 texels = 256-byte rows from offset 512";
    INFO("step: " << step);
    const std::vector<std::uint8_t> src = pattern(512 + 256 * 4, 40);
    BufferDesc bd;
    bd.size = src.size();
    bd.usage.copySrc = true;
    bd.data = range_of(src);
    const Buffer buf = dev->make_buffer(bd);
    REQUIRE(dev->state(buf) == ResourceState::Valid);
    ImageDesc id;
    id.width = 64;
    id.height = 4;
    id.usage.copyDst = true;
    const Image img = dev->make_image(id);
    REQUIRE(dev->state(img) == ResourceState::Valid);
    CommandList& list = dev->begin_commands("aligned");
    BufferImageCopy c;
    c.src = buf;
    c.srcOffset = 512;
    c.bytesPerRow = 256;
    c.dst.image = img;
    list.copy_buffer_to_image(c);
    submit_and_finish(*dev, list);
    std::vector<std::uint8_t> out;
    auto r = dev->read_image_rgba8(img, 64, 4, out);
    REQUIRE_MESSAGE(r, r.error().to_string());
    CHECK(out == std::vector<std::uint8_t>(src.begin() + 512, src.end()));

    step = "unaligned: a 5x3 region of 28-byte rows from offset 4, into (2, 1) of mip 0";
    ImageDesc sd;
    sd.width = 8;
    sd.height = 4;
    sd.usage.copyDst = true;
    const Image small = dev->make_image(sd);
    REQUIRE(dev->state(small) == ResourceState::Valid);
    CommandList& list2 = dev->begin_commands("unaligned");
    BufferImageCopy u;
    u.src = buf;
    u.srcOffset = 4;
    u.bytesPerRow = 28;
    u.dst.image = small;
    u.dst.x = 2;
    u.dst.y = 1;
    u.size.width = 5;
    u.size.height = 3;
    list2.copy_buffer_to_image(u);
    submit_and_finish(*dev, list2);
    r = dev->read_image_region(small, 0, 0, 2, 1, 5, 3, out);
    REQUIRE_MESSAGE(r, r.error().to_string());
    std::vector<std::uint8_t> expected;
    for (int row = 0; row < 3; ++row)
        expected.insert(expected.end(), src.begin() + 4 + row * 28, src.begin() + 4 + row * 28 + 20);
    CHECK(out == expected);

    step = "a region past the buffer's end is a teaching error";
    CommandList& list3 = dev->begin_commands("past-end");
    u.srcOffset = src.size() - 8;
    list3.copy_buffer_to_image(u);
    submit_and_finish(*dev, list3);
    CHECK(contains(all_errors(*dev), "copy_buffer_to_image"));

    step = "the debug layer said nothing";
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

TEST_CASE("d3d12: a resource destroyed while the GPU may use it is released once its frame is done") {
    auto dev = make_warp();
    if (!dev) return;
    std::string step = "make and use a buffer";
    INFO("step: " << step);
    BufferDesc bd;
    bd.size = 4096;
    bd.usage.writeTransient = true;
    const Buffer b = dev->make_buffer(bd);
    REQUIRE(dev->state(b) == ResourceState::Valid);
    auto* raw = static_cast<ID3D12Resource*>(const_cast<void*>(dev->native_buffer(b).buffer));
    REQUIRE(raw != nullptr);
    raw->AddRef();  // our own reference, to watch the device's go

    CommandList& list = dev->begin_commands("use");
    const std::vector<std::uint8_t> data = pattern(4096, 50);
    BufferWrite w;
    w.data = range_of(data);
    w.buffer = b;
    list.write_buffer(w);
    dev->submit(list);

    step = "destroyed before commit: the handle is gone, the resource is not";
    dev->destroy_buffer(b);
    CHECK(dev->state(b) == ResourceState::Invalid);
    CHECK(dev->counters().pendingReleases >= 1);
    raw->AddRef();
    CHECK(raw->Release() >= 2);  // ours and the device's

    step = "destroying it again is reported";
    dev->destroy_buffer(b);
    CHECK(contains(all_errors(*dev), "names nothing"));

    step = "after the frame's fence the device let go";
    dev->commit();
    REQUIRE(dev->wait_idle());
    CHECK(dev->counters().pendingReleases == 0);
    CHECK(raw->Release() == 0);  // ours was the last reference

    step = "the debug layer said nothing";
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

TEST_CASE("d3d12: the upload ring wraps, and an upload that does not fit takes a buffer of its own") {
    D3d12Options o;
    o.uploadRingBytes = 64 * 1024;
    auto dev = make_warp(o);
    if (!dev) return;
    std::string step = "frames of 40 KiB writes through a 64 KiB ring";
    INFO("step: " << step);
    BufferDesc bd;
    bd.size = 128 * 1024;
    bd.usage.writeTransient = true;
    bd.label = "ring-target";
    const Buffer b = dev->make_buffer(bd);
    REQUIRE(dev->state(b) == ResourceState::Valid);
    std::vector<std::uint8_t> out;
    for (std::uint32_t frame = 0; frame < 4; ++frame) {
        const std::vector<std::uint8_t> data = pattern(40 * 1024, 60 + frame);
        CommandList& list = dev->begin_commands("ring");
        BufferWrite w;
        w.data = range_of(data);
        w.buffer = b;
        list.write_buffer(w);
        submit_and_finish(*dev, list);
        auto r = dev->read_buffer(b, 0, data.size(), out);
        REQUIRE_MESSAGE(r, r.error().to_string());
        CHECK_MESSAGE(out == data, "frame " << frame);
    }
    CHECK(dev->counters().uploadRingWraps >= 1);
    CHECK(dev->counters().dedicatedUploads == 0);

    step = "two 40 KiB writes in one frame: the second does not fit";
    const std::vector<std::uint8_t> one = pattern(40 * 1024, 70), two = pattern(40 * 1024, 71);
    CommandList& list = dev->begin_commands("ring-full");
    BufferWrite w;
    w.data = range_of(one);
    w.buffer = b;
    list.write_buffer(w);
    w.data = range_of(two);
    w.dstOffset = 64 * 1024;
    list.write_buffer(w);
    submit_and_finish(*dev, list);
    CHECK(dev->counters().dedicatedUploads == 1);
    auto r = dev->read_buffer(b, 0, bd.size, out);
    REQUIRE(r);
    CHECK(std::vector<std::uint8_t>(out.begin(), out.begin() + 40 * 1024) == one);
    CHECK(std::vector<std::uint8_t>(out.begin() + 64 * 1024, out.begin() + 104 * 1024) == two);

    step = "a 100 KiB write is bigger than the ring";
    const std::vector<std::uint8_t> big = pattern(100 * 1024, 72);
    CommandList& list2 = dev->begin_commands("ring-big");
    w.data = range_of(big);
    w.dstOffset = 0;
    list2.write_buffer(w);
    submit_and_finish(*dev, list2);
    CHECK(dev->counters().dedicatedUploads == 2);
    r = dev->read_buffer(b, 0, big.size(), out);
    REQUIRE(r);
    CHECK(out == big);
    CHECK(dev->counters().pendingReleases == 0);  // the dedicated upload buffers went with their frames

    step = "the debug layer said nothing";
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

TEST_CASE("d3d12: a full descriptor heap fails a view with a teaching error, and a freed descriptor is reused") {
    D3d12Options o;
    o.cpuViewDescriptors = 4;
    o.cpuSamplerDescriptors = 2;
    o.frameViewDescriptors = 8;
    o.bindlessDescriptors = 16;
    auto dev = make_warp(o);
    if (!dev) return;
    std::string step = "four texture views fill the CPU view heap";
    INFO("step: " << step);
    ImageDesc id;
    id.width = 4;
    id.height = 4;
    const Image img = dev->make_image(id);
    REQUIRE(dev->state(img) == ResourceState::Valid);
    ViewDesc vd;
    vd.texture.image = img;
    std::vector<View> views;
    for (int i = 0; i < 4; ++i) {
        views.push_back(dev->make_view(vd));
        CHECK(dev->state(views.back()) == ResourceState::Valid);
    }
    CHECK(dev->counters().cpuViewDescriptors == 4);

    step = "the fifth fails";
    const View fifth = dev->make_view(vd);
    CHECK(dev->state(fifth) == ResourceState::Failed);
    CHECK(contains(all_errors(*dev), "descriptor heap is full (4 descriptors)"));
    CHECK(contains(all_errors(*dev), "cpuViewDescriptors"));
    dev->destroy_view(fifth);  // a failed view is destroyed like any other

    step = "a destroyed view's descriptor comes back once its frame is done";
    dev->destroy_view(views[1]);
    CHECK(dev->counters().cpuViewDescriptors == 4);  // the GPU may still copy it this frame
    dev->commit();
    REQUIRE(dev->wait_idle());
    CHECK(dev->counters().cpuViewDescriptors == 3);
    views[1] = dev->make_view(vd);
    CHECK(dev->state(views[1]) == ResourceState::Valid);

    step = "samplers";
    SamplerDesc sd;
    CHECK(dev->state(dev->make_sampler(sd)) == ResourceState::Valid);
    CHECK(dev->state(dev->make_sampler(sd)) == ResourceState::Valid);
    CHECK(dev->state(dev->make_sampler(sd)) == ResourceState::Failed);
    CHECK(contains(all_errors(*dev), "cpuSamplerDescriptors"));

    step = "the shader-visible heap: a bindless range and 8 descriptors per frame";
    d3d12::ShaderVisibleHeap& heap = dev->view_heap();
    CHECK(heap.reserved().count == 16);
    CHECK(heap.alloc(8).ok());
    CHECK(!heap.alloc(1).ok());
    dev->commit();
    const d3d12::ShaderVisibleHeap::Span next = heap.alloc(8);
    CHECK(next.ok());
    CHECK(next.index >= 16);  // never inside the bindless range

    step = "the debug layer said nothing";
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

namespace {

// The test shaders' HLSL: make_shader compiles it to shader model 5.1 with d3dcompiler_47.dll.

// A fullscreen triangle at depth vs_params.depth.x, filled with fs_params.color.
constexpr const char* kFillVs = R"(
cbuffer vs_params : register(b0) { float4 depth; };
float4 main(uint id : SV_VertexID) : SV_Position {
    float2 p = float2(float((id << 1) & 2), float(id & 2));
    return float4(p * float2(2.0, -2.0) + float2(-1.0, 1.0), depth.x, 1.0);
}
)";
constexpr const char* kFillFs = R"(
cbuffer fs_params : register(b0) { float4 color; };
float4 main() : SV_Target0 { return color; }
)";

// The same triangle at depth 0, no uniforms.
constexpr const char* kPlainVs = R"(
float4 main(uint id : SV_VertexID) : SV_Position {
    float2 p = float2(float((id << 1) & 2), float(id & 2));
    return float4(p * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}
)";

// The sum of two textures, each sampled at its centre with its own sampler, times fs_params.scale.
constexpr const char* kTwoViewsFs = R"(
Texture2D<float4> texA : register(t0);
Texture2D<float4> texB : register(t1);
SamplerState smpA : register(s0);
SamplerState smpB : register(s1);
cbuffer fs_params : register(b0) { float4 scale; };
float4 main(float4 pos : SV_Position) : SV_Target0 {
    return (texA.Sample(smpA, float2(0.5, 0.5)) + texB.Sample(smpB, float2(0.5, 0.5))) * scale;
}
)";

// Positions from vertex buffer 0, moved right by the instance id; instance 0 is red, the others green.
constexpr const char* kInstanceVs = R"(
struct VsOut { float4 pos : SV_Position; nointerpolation uint inst : INSTANCE; };
VsOut main(float2 pos : TEXCOORD0, uint inst : SV_InstanceID) {
    VsOut o;
    o.pos = float4(pos.x + float(inst), pos.y, 0.0, 1.0);
    o.inst = inst;
    return o;
}
)";
constexpr const char* kInstanceFs = R"(
float4 main(float4 pos : SV_Position, nointerpolation uint inst : INSTANCE) : SV_Target0 {
    return inst == 0 ? float4(1.0, 0.0, 0.0, 1.0) : float4(0.0, 1.0, 0.0, 1.0);
}
)";

// Mode 0 writes texel (x, y) of an 8x8 image and word x + 8y of a buffer; mode 1 doubles each word plus one, so it
// reads what mode 0 wrote.
constexpr const char* kComputeCs = R"(
RWTexture2D<float4> img : register(u0);
RWByteAddressBuffer words : register(u1);
cbuffer cs_params : register(b0) { uint4 mode; };
[numthreads(8, 8, 1)]
void main(uint3 id : SV_DispatchThreadID) {
    uint i = id.x + id.y * 8;
    if (mode.x == 0) {
        img[id.xy] = float4(float(id.x * 32) / 255.0, float(id.y * 32) / 255.0, 0.0, 1.0);
        words.Store(i * 4, i);
    } else {
        words.Store(i * 4, words.Load(i * 4) * 2 + 1);
    }
}
)";

using Vec4 = std::array<float, 4>;

Range bytes_of(const Vec4& v) { return Range{v.data(), sizeof(float) * v.size()}; }

ShaderDesc fill_shader_desc() {
    ShaderDesc sd;
    sd.vertexFunc.source = kFillVs;
    sd.fragmentFunc.source = kFillFs;
    sd.uniformBlocks[0].stage = ShaderStage::Vertex;
    sd.uniformBlocks[0].size = 16;
    sd.uniformBlocks[1].stage = ShaderStage::Fragment;
    sd.uniformBlocks[1].size = 16;  // b0 of the fragment stage: each stage numbers its registers on its own
    sd.label = "fill";
    return sd;
}

ShaderDesc instance_shader_desc() {
    ShaderDesc sd;
    sd.vertexFunc.source = kInstanceVs;
    sd.fragmentFunc.source = kInstanceFs;
    sd.attrs[0].baseType = ShaderAttrBaseType::Float;
    sd.attrs[0].hlslSemName = "TEXCOORD";
    sd.attrs[0].hlslSemIndex = 0;
    sd.label = "instance";
    return sd;
}

// One uniform block, two texture views and two samplers, all in the fragment stage.
ShaderDesc two_views_shader_desc() {
    ShaderDesc sd;
    sd.vertexFunc.source = kPlainVs;
    sd.fragmentFunc.source = kTwoViewsFs;
    sd.uniformBlocks[0].stage = ShaderStage::Fragment;
    sd.uniformBlocks[0].size = 16;
    for (int i = 0; i < 2; ++i) {
        ShaderTextureView& t = sd.views[i].texture;
        t.stage = ShaderStage::Fragment;
        t.imageType = ImageType::Tex2d;
        t.sampleType = ImageSampleType::Float;
        t.binding.hlslRegister = std::uint8_t(i);
        sd.samplers[i].stage = ShaderStage::Fragment;
        sd.samplers[i].samplerType = SamplerType::Filtering;
        sd.samplers[i].binding.hlslRegister = std::uint8_t(i);
    }
    sd.label = "two-views";
    return sd;
}

// A render pipeline of `shader` drawing into one `color` target (plus `depth`) with `samples` samples.
PipelineDesc render_desc(Shader shader, PixelFormat color, PixelFormat depth = PixelFormat::None, int samples = 1) {
    PipelineDesc pd;
    pd.shader = shader;
    pd.colors[0].pixelFormat = color;
    pd.depth.pixelFormat = depth;
    pd.sampleCount = samples;
    pd.label = "test-pipeline";
    return pd;
}

enum class Attach { Color, Resolve, Depth };

struct Target {
    Image image{};
    View view{};
};

// An image a pass draws into and its attachment view.
Target make_target(D3d12Device& dev, Attach kind, int width, int height, PixelFormat format, int samples = 1) {
    ImageDesc id;
    id.width = width;
    id.height = height;
    id.pixelFormat = format;
    id.sampleCount = samples;
    id.usage.colorAttachment = kind == Attach::Color;
    id.usage.resolveAttachment = kind == Attach::Resolve;
    id.usage.depthStencilAttachment = kind == Attach::Depth;
    id.label = "target";
    Target t;
    t.image = dev.make_image(id);
    ViewDesc vd;
    if (kind == Attach::Color)
        vd.colorAttachment.image = t.image;
    else if (kind == Attach::Resolve)
        vd.resolveAttachment.image = t.image;
    else
        vd.depthStencilAttachment.image = t.image;
    t.view = dev.make_view(vd);
    return t;
}

// An immutable RGBA8 texture with `texels` and a texture view of it.
View make_texture(D3d12Device& dev, int width, int height, const std::vector<std::uint8_t>& texels) {
    ImageDesc id;
    id.width = width;
    id.height = height;
    id.pixelFormat = PixelFormat::Rgba8;
    id.data.mipLevels[0] = range_of(texels);
    id.label = "texture";
    ViewDesc vd;
    vd.texture.image = dev.make_image(id);
    return dev.make_view(vd);
}

Sampler make_clamped_sampler(D3d12Device& dev, Filter filter) {
    SamplerDesc sd;
    sd.minFilter = sd.magFilter = filter;
    sd.wrapU = sd.wrapV = Wrap::ClampToEdge;
    return dev.make_sampler(sd);
}

Buffer make_vertex_buffer(D3d12Device& dev, const std::vector<float>& v, bool index = false) {
    BufferDesc bd;
    bd.size = v.size() * sizeof(float);
    bd.usage.vertexBuffer = !index;
    bd.usage.indexBuffer = index;
    bd.data = Range{v.data(), bd.size};
    bd.label = index ? "indices" : "vertices";
    return dev.make_buffer(bd);
}

// A pass into one colour attachment, cleared to `clear`.
PassDesc color_pass(const Target& color, PixelFormat format, Color clear, int samples = 1) {
    PassDesc p;
    p.label = "test-pass";
    p.color = color.view;
    p.format.color = format;
    p.format.samples = samples;
    p.colorLoad = LoadAction::Clear;
    p.clearColor = clear;
    return p;
}

std::string rgba_text(const int* c) {
    return "(" + std::to_string(c[0]) + ", " + std::to_string(c[1]) + ", " + std::to_string(c[2]) + ", " +
           std::to_string(c[3]) + ")";
}

// The first texel of a tightly packed RGBA8 image that differs from want(x, y) by more than `tolerance` in a channel,
// as text; empty when every texel matches.
template <class Want>
std::string first_mismatch(const std::vector<std::uint8_t>& px, int width, int height, int tolerance, Want want) {
    if (px.size() != std::size_t(width) * std::size_t(height) * 4)
        return "the readback has " + std::to_string(px.size()) + " bytes";
    for (int y = 0; y < height; ++y)
        for (int x = 0; x < width; ++x) {
            const std::array<int, 4> e = want(x, y);
            const std::uint8_t* p = px.data() + (std::size_t(y) * std::size_t(width) + std::size_t(x)) * 4;
            const int got[4] = {p[0], p[1], p[2], p[3]};
            for (std::size_t c = 0; c < 4; ++c)
                if (std::abs(got[c] - e[c]) > tolerance)
                    return "texel (" + std::to_string(x) + ", " + std::to_string(y) + ") is " + rgba_text(got) +
                           " and should be " + rgba_text(e.data());
        }
    return {};
}

std::vector<std::uint8_t> read_rgba8(D3d12Device& dev, Image image, int width, int height) {
    std::vector<std::uint8_t> out;
    auto r = dev.read_image_rgba8(image, width, height, out);
    REQUIRE_MESSAGE(r, r.error().to_string());
    return out;
}

// The last error the device reported (each failing call below reports one).
std::string last_error(D3d12Device& dev) {
    const std::vector<std::string> e = dev.errors();
    return e.empty() ? std::string() : e.back();
}

}  // namespace

TEST_CASE("d3d12: a clear-only pass fills its colour attachment") {
    auto dev = make_warp();
    if (!dev) return;
    const Target t = make_target(*dev, Attach::Color, 4, 4, PixelFormat::Rgba8);
    REQUIRE_MESSAGE(dev->state(t.view) == ResourceState::Valid, all_errors(*dev));
    CommandList& list = dev->begin_commands("clear");
    list.begin_pass(color_pass(t, PixelFormat::Rgba8, Color{1.0f, 0.25f, 0.0f, 1.0f}));
    list.end_pass();
    submit_and_finish(*dev, list);
    const std::string bad = first_mismatch(read_rgba8(*dev, t.image, 4, 4), 4, 4, 1,
                                           [](int, int) { return std::array<int, 4>{255, 64, 0, 255}; });
    CHECK_MESSAGE(bad.empty(), bad);
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
}

TEST_CASE("d3d12: a uniform-colour fullscreen triangle fills RGBA8 and RGBA16F targets") {
    auto dev = make_warp();
    if (!dev) return;
    const Shader shader = dev->make_shader(fill_shader_desc());
    REQUIRE_MESSAGE(dev->state(shader) == ResourceState::Valid, all_errors(*dev));
    const Vec4 depth{0.0f, 0.0f, 0.0f, 0.0f};
    const Vec4 colour{0.25f, 0.5f, 0.75f, 1.0f};
    for (PixelFormat f : {PixelFormat::Rgba8, PixelFormat::Rgba16F}) {
        INFO("format " << pixel_format_name(f));
        const Pipeline pip = dev->make_pipeline(render_desc(shader, f));
        REQUIRE_MESSAGE(dev->state(pip) == ResourceState::Valid, all_errors(*dev));
        const Target t = make_target(*dev, Attach::Color, 8, 8, f);
        REQUIRE_MESSAGE(dev->state(t.view) == ResourceState::Valid, all_errors(*dev));
        CommandList& list = dev->begin_commands("fill");
        list.begin_pass(color_pass(t, f, Color{}));
        list.set_pipeline(pip);
        list.set_uniforms(0, bytes_of(depth));
        list.set_uniforms(1, bytes_of(colour));
        list.draw(0, 3);
        list.end_pass();
        submit_and_finish(*dev, list);
        if (f == PixelFormat::Rgba8) {
            const std::string bad = first_mismatch(read_rgba8(*dev, t.image, 8, 8), 8, 8, 1,
                                                   [](int, int) { return std::array<int, 4>{64, 128, 191, 255}; });
            CHECK_MESSAGE(bad.empty(), bad);
        } else {
            std::vector<float> out;
            auto r = dev->read_image_rgba16f(t.image, 8, 8, out);
            REQUIRE_MESSAGE(r, r.error().to_string());
            REQUIRE(out.size() == 8 * 8 * 4);
            int wrong = 0;
            for (std::size_t i = 0; i < out.size(); ++i)
                if (out[i] != colour[i % 4]) ++wrong;  // 0.25, 0.5, 0.75 and 1 are exact in half floats
            CHECK_MESSAGE(wrong == 0, wrong << " channels differ, the first texel is (" << out[0] << ", " << out[1]
                                            << ", " << out[2] << ", " << out[3] << ")");
        }
    }
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
}

TEST_CASE("d3d12: the engine's blit shader (sokol-shdc HLSL) copies a texture with a nearest and a linear sampler") {
    auto dev = make_warp();
    if (!dev) return;
    const sg_shader_desc* blitDesc = blit_blit_keep_shader_desc(SG_BACKEND_D3D11);
    REQUIRE_MESSAGE(blitDesc, "the blit shader header has no D3D11 (HLSL) variant: regenerate it with D3D11 in");
    const Shader shader = dev->make_shader(from_sg(*blitDesc));
    REQUIRE_MESSAGE(dev->state(shader) == ResourceState::Valid, all_errors(*dev));
    PipelineDesc pd = render_desc(shader, PixelFormat::Rgba8);
    pd.layout.attrs[0].format = VertexFormat::Float2;
    const Pipeline pip = dev->make_pipeline(pd);
    REQUIRE_MESSAGE(dev->state(pip) == ResourceState::Valid, all_errors(*dev));
    const Buffer tri = make_vertex_buffer(*dev, {-1.0f, -1.0f, 3.0f, -1.0f, -1.0f, 3.0f});
    const std::vector<std::uint8_t> texels = pattern(4 * 4 * 4, 11);
    const View square = make_texture(*dev, 4, 4, texels);
    const View ramp = make_texture(*dev, 2, 1, {0, 0, 0, 255, 255, 255, 255, 255});
    const Sampler nearest = make_clamped_sampler(*dev, Filter::Nearest);
    const Sampler linear = make_clamped_sampler(*dev, Filter::Linear);
    REQUIRE_MESSAGE(dev->state(linear) == ResourceState::Valid, all_errors(*dev));
    // vs: flip.x 0 (a top-down source), region zw 0 (the whole source); fs: encode.x 0 (the texel as it is).
    const std::array<float, 8> vsParams{};
    const std::array<float, 8> fsParams{};
    auto blit = [&](View src, Sampler smp, int width, int height) {
        const Target dst = make_target(*dev, Attach::Color, width, height, PixelFormat::Rgba8);
        CommandList& list = dev->begin_commands("blit");
        list.begin_pass(color_pass(dst, PixelFormat::Rgba8, Color{}));
        list.set_pipeline(pip);
        Bindings b;
        b.vertexBuffers[0] = tri;
        b.views[0] = src;
        b.samplers[0] = smp;
        list.set_bindings(b);
        list.set_uniforms(0, Range{vsParams.data(), sizeof vsParams});
        list.set_uniforms(1, Range{fsParams.data(), sizeof fsParams});
        list.draw(0, 3);
        list.end_pass();
        submit_and_finish(*dev, list);
        return read_rgba8(*dev, dst.image, width, height);
    };
    std::string step = "nearest, 4x4 into 4x4: every texel as it is";
    INFO("step: " << step);
    CHECK(blit(square, nearest, 4, 4) == texels);
    step = "nearest, 2x1 into 4x1";
    const int nearestRamp[4] = {0, 0, 255, 255};
    std::string bad = first_mismatch(blit(ramp, nearest, 4, 1), 4, 1, 0, [&](int x, int) {
        const int v = nearestRamp[x];
        return std::array<int, 4>{v, v, v, 255};
    });
    CHECK_MESSAGE(bad.empty(), bad);
    step = "linear, 2x1 into 4x1: the inner texels are a quarter and three quarters of the way";
    const int linearRamp[4] = {0, 64, 191, 255};  // u 0.125 clamps to the first texel's centre, 0.375 is 1/4 on
    bad = first_mismatch(blit(ramp, linear, 4, 1), 4, 1, 2, [&](int x, int) {
        const int v = linearRamp[x];
        return std::array<int, 4>{v, v, v, 255};
    });
    CHECK_MESSAGE(bad.empty(), bad);
    step = "the debug layer said nothing";
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
}

TEST_CASE("d3d12: an indexed instanced draw with a base vertex") {
    auto dev = make_warp();
    if (!dev) return;
    const Shader shader = dev->make_shader(instance_shader_desc());
    REQUIRE_MESSAGE(dev->state(shader) == ResourceState::Valid, all_errors(*dev));
    PipelineDesc pd = render_desc(shader, PixelFormat::Rgba8);
    pd.layout.attrs[0].format = VertexFormat::Float2;
    pd.indexType = IndexType::Uint16;
    const Pipeline pip = dev->make_pipeline(pd);
    REQUIRE_MESSAGE(dev->state(pip) == ResourceState::Valid, all_errors(*dev));
    // Vertices 0-3: the right half (what a draw that ignored baseVertex would draw); 4-7: the left half.
    const Buffer vertices = make_vertex_buffer(*dev, {0.0f, -1.0f, 1.0f, -1.0f, 1.0f, 1.0f, 0.0f, 1.0f,  //
                                                      -1.0f, -1.0f, 0.0f, -1.0f, 0.0f, 1.0f, -1.0f, 1.0f});
    const std::uint16_t idx[6] = {0, 1, 2, 0, 2, 3};
    BufferDesc ib;
    ib.size = sizeof idx;
    ib.usage.indexBuffer = true;
    ib.data = Range{idx, sizeof idx};
    ib.label = "indices";
    const Buffer indices = dev->make_buffer(ib);
    REQUIRE_MESSAGE(dev->state(indices) == ResourceState::Valid, all_errors(*dev));
    const Target t = make_target(*dev, Attach::Color, 8, 4, PixelFormat::Rgba8);
    CommandList& list = dev->begin_commands("instanced");
    list.begin_pass(color_pass(t, PixelFormat::Rgba8, Color{0.0f, 0.0f, 1.0f, 1.0f}));
    list.set_pipeline(pip);
    Bindings b;
    b.vertexBuffers[0] = vertices;
    b.indexBuffer = indices;
    list.set_bindings(b);
    list.draw_ex(0, 6, 2, 4, 0);  // instance 0 on the left half (red), instance 1 moved right by 1 (green)
    list.end_pass();
    submit_and_finish(*dev, list);
    const std::string bad = first_mismatch(read_rgba8(*dev, t.image, 8, 4), 8, 4, 0, [](int x, int) {
        return x < 4 ? std::array<int, 4>{255, 0, 0, 255} : std::array<int, 4>{0, 255, 0, 255};
    });
    CHECK_MESSAGE(bad.empty(), bad);
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
}

TEST_CASE("d3d12: the depth test keeps the nearer draw, and a viewport limits a draw") {
    auto dev = make_warp();
    if (!dev) return;
    const Shader shader = dev->make_shader(fill_shader_desc());
    REQUIRE_MESSAGE(dev->state(shader) == ResourceState::Valid, all_errors(*dev));
    PipelineDesc pd = render_desc(shader, PixelFormat::Rgba8, PixelFormat::Depth);
    pd.depth.compare = CompareFunc::Less;
    pd.depth.writeEnabled = true;
    const Pipeline pip = dev->make_pipeline(pd);
    REQUIRE_MESSAGE(dev->state(pip) == ResourceState::Valid, all_errors(*dev));
    const Target color = make_target(*dev, Attach::Color, 8, 8, PixelFormat::Rgba8);
    const Target depth = make_target(*dev, Attach::Depth, 8, 8, PixelFormat::Depth);
    REQUIRE_MESSAGE(dev->state(depth.view) == ResourceState::Valid, all_errors(*dev));
    PassDesc pass = color_pass(color, PixelFormat::Rgba8, Color{0.0f, 0.0f, 0.0f, 1.0f});
    pass.depth = depth.view;
    pass.format.depth = PixelFormat::Depth;
    pass.depthLoad = LoadAction::Clear;
    pass.clearDepth = 1.0f;
    CommandList& list = dev->begin_commands("depth");
    list.begin_pass(pass);
    list.set_pipeline(pip);
    auto fill = [&](float z, const Vec4& c) {
        list.set_uniforms(0, bytes_of(Vec4{z, 0.0f, 0.0f, 0.0f}));
        list.set_uniforms(1, bytes_of(c));
        list.draw(0, 3);
    };
    fill(0.5f, Vec4{1.0f, 0.0f, 0.0f, 1.0f});  // red everywhere
    fill(0.7f, Vec4{0.0f, 1.0f, 0.0f, 1.0f});  // green behind it: hidden
    list.set_viewport(0, 0, 4, 8);
    fill(0.3f, Vec4{0.0f, 0.0f, 1.0f, 1.0f});  // blue in front, in the left half only
    list.end_pass();
    submit_and_finish(*dev, list);
    const std::string bad = first_mismatch(read_rgba8(*dev, color.image, 8, 8), 8, 8, 0, [](int x, int) {
        return x < 4 ? std::array<int, 4>{0, 0, 255, 255} : std::array<int, 4>{255, 0, 0, 255};
    });
    CHECK_MESSAGE(bad.empty(), bad);
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
}

TEST_CASE("d3d12: an MSAA 4x pass resolves into a single-sample image at end_pass") {
    auto dev = make_warp();
    if (!dev) return;
    const Shader shader = dev->make_shader(instance_shader_desc());
    REQUIRE_MESSAGE(dev->state(shader) == ResourceState::Valid, all_errors(*dev));
    PipelineDesc pd = render_desc(shader, PixelFormat::Rgba8, PixelFormat::None, 4);
    pd.layout.attrs[0].format = VertexFormat::Float2;
    const Pipeline pip = dev->make_pipeline(pd);
    REQUIRE_MESSAGE(dev->state(pip) == ResourceState::Valid, all_errors(*dev));
    // The lower left half of the target, cut by its diagonal: the texels on it are partly covered.
    const Buffer tri = make_vertex_buffer(*dev, {-1.0f, -1.0f, 1.0f, -1.0f, -1.0f, 1.0f});
    const Target msaa = make_target(*dev, Attach::Color, 8, 8, PixelFormat::Rgba8, 4);
    const Target resolved = make_target(*dev, Attach::Resolve, 8, 8, PixelFormat::Rgba8);
    REQUIRE_MESSAGE(dev->state(msaa.view) == ResourceState::Valid, all_errors(*dev));
    REQUIRE_MESSAGE(dev->state(resolved.view) == ResourceState::Valid, all_errors(*dev));
    PassDesc pass = color_pass(msaa, PixelFormat::Rgba8, Color{0.0f, 0.0f, 0.0f, 1.0f}, 4);
    pass.resolve = resolved.view;
    CommandList& list = dev->begin_commands("msaa");
    list.begin_pass(pass);
    list.set_pipeline(pip);
    Bindings b;
    b.vertexBuffers[0] = tri;
    list.set_bindings(b);
    list.draw(0, 3);
    list.end_pass();
    submit_and_finish(*dev, list);
    const std::vector<std::uint8_t> px = read_rgba8(*dev, resolved.image, 8, 8);
    REQUIRE(px.size() == 8 * 8 * 4);
    auto red = [&](int x, int y) { return int(px[(std::size_t(y) * 8 + std::size_t(x)) * 4]); };
    CHECK(red(0, 7) == 255);  // inside
    CHECK(red(2, 6) == 255);
    CHECK(red(7, 0) == 0);  // outside
    CHECK(red(6, 2) == 0);
    std::vector<int> diagonal;
    for (int i = 0; i < 8; ++i) diagonal.push_back(red(i, i));
    const auto partial = std::count_if(diagonal.begin(), diagonal.end(), [](int v) { return v > 32 && v < 224; });
    CHECK_MESSAGE(partial == 8, "the diagonal's red values: " << diagonal[0] << " " << diagonal[1] << " " << diagonal[2]
                                                              << " " << diagonal[7]);
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
}

TEST_CASE("d3d12: a compute pass writes a storage image and a storage buffer, and a second dispatch reads them") {
    auto dev = make_warp();
    if (!dev) return;
    ShaderDesc sd;
    sd.computeFunc.source = kComputeCs;
    sd.uniformBlocks[0].stage = ShaderStage::Compute;
    sd.uniformBlocks[0].size = 16;
    sd.views[0].storageImage.stage = ShaderStage::Compute;
    sd.views[0].storageImage.imageType = ImageType::Tex2d;
    sd.views[0].storageImage.accessFormat = PixelFormat::Rgba8;
    sd.views[1].storageBuffer.stage = ShaderStage::Compute;
    sd.views[1].storageBuffer.hlslRegisterU = 1;
    sd.label = "compute";
    const Shader shader = dev->make_shader(sd);
    REQUIRE_MESSAGE(dev->state(shader) == ResourceState::Valid, all_errors(*dev));
    PipelineDesc pd;
    pd.compute = true;
    pd.shader = shader;
    pd.label = "compute";
    const Pipeline pip = dev->make_pipeline(pd);
    REQUIRE_MESSAGE(dev->state(pip) == ResourceState::Valid, all_errors(*dev));
    ImageDesc id;
    id.width = 8;
    id.height = 8;
    id.pixelFormat = PixelFormat::Rgba8;
    id.usage.storageImage = true;
    id.label = "storage-image";
    const Image img = dev->make_image(id);
    BufferDesc bd;
    bd.size = 64 * 4;
    bd.usage.storageBuffer = true;
    bd.label = "storage-buffer";
    const Buffer buf = dev->make_buffer(bd);
    ViewDesc iv;
    iv.storageImage.image = img;
    ViewDesc bv;
    bv.storageBuffer.buffer = buf;
    Bindings b;
    b.views[0] = dev->make_view(iv);
    b.views[1] = dev->make_view(bv);
    REQUIRE_MESSAGE(dev->state(b.views[1]) == ResourceState::Valid, all_errors(*dev));
    const std::uint32_t write[4] = {0, 0, 0, 0};
    const std::uint32_t update[4] = {1, 0, 0, 0};
    CommandList& list = dev->begin_commands("compute");
    list.begin_compute_pass("compute");
    list.set_pipeline(pip);
    list.set_bindings(b);
    list.set_uniforms(0, Range{write, sizeof write});
    list.dispatch(1, 1, 1);
    list.set_uniforms(0, Range{update, sizeof update});
    list.dispatch(1, 1, 1);  // after a UAV barrier: it reads the words the first one wrote
    list.end_pass();
    submit_and_finish(*dev, list);
    const std::string bad = first_mismatch(read_rgba8(*dev, img, 8, 8), 8, 8, 0,
                                           [](int x, int y) { return std::array<int, 4>{x * 32, y * 32, 0, 255}; });
    CHECK_MESSAGE(bad.empty(), bad);
    std::vector<std::uint8_t> raw;
    auto r = dev->read_buffer(buf, 0, bd.size, raw);
    REQUIRE_MESSAGE(r, r.error().to_string());
    REQUIRE(raw.size() == bd.size);
    std::vector<std::uint32_t> words(64), expected(64);
    std::memcpy(words.data(), raw.data(), raw.size());
    for (std::uint32_t i = 0; i < 64; ++i) expected[i] = i * 2 + 1;
    CHECK(words == expected);
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
}

TEST_CASE("d3d12: equal descs share a PSO and a root signature; a root signature lays its slots out per stage") {
    auto dev = make_warp();
    if (!dev) return;
    std::string step = "two equal shaders, one root signature";
    INFO("step: " << step);
    const d3d12::D3d12Counters start = dev->counters();
    const Shader a = dev->make_shader(fill_shader_desc());
    const Shader b = dev->make_shader(fill_shader_desc());
    REQUIRE_MESSAGE(dev->state(b) == ResourceState::Valid, all_errors(*dev));
    CHECK(a.id != b.id);
    d3d12::D3d12Counters c = dev->counters();
    CHECK(c.rootSignatures == start.rootSignatures + 1);
    CHECK(c.rootSignatureCacheHits == start.rootSignatureCacheHits + 1);
    CHECK(dev->shader_root_layout(a) == dev->shader_root_layout(b));

    step = "equal pipeline descs, one PSO (a shader with the same bytecode and slots too)";
    const Pipeline p1 = dev->make_pipeline(render_desc(a, PixelFormat::Rgba8));
    const Pipeline p2 = dev->make_pipeline(render_desc(a, PixelFormat::Rgba8));
    const Pipeline p3 = dev->make_pipeline(render_desc(b, PixelFormat::Rgba8));
    REQUIRE_MESSAGE(dev->state(p3) == ResourceState::Valid, all_errors(*dev));
    CHECK(p1.id != p2.id);
    c = dev->counters();
    CHECK(c.psoCacheMisses == start.psoCacheMisses + 1);
    CHECK(c.psoCacheHits == start.psoCacheHits + 2);
    CHECK(c.psos == start.psos + 1);

    step = "another format is another PSO";
    CHECK(dev->state(dev->make_pipeline(render_desc(a, PixelFormat::Rgba16F))) == ResourceState::Valid);
    c = dev->counters();
    CHECK(c.psoCacheMisses == start.psoCacheMisses + 2);
    CHECK(c.psos == start.psos + 2);

    step = "one block, two views, two samplers: a root CBV, then the fragment stage's view and sampler tables";
    const Shader two = dev->make_shader(two_views_shader_desc());
    REQUIRE_MESSAGE(dev->state(two) == ResourceState::Valid, all_errors(*dev));
    const std::shared_ptr<const d3d12::RootLayout> lay = dev->shader_root_layout(two);
    REQUIRE(lay);
    CHECK(lay->cbvParam[0] == 0);
    CHECK(lay->cbvParam[1] == -1);
    CHECK(lay->viewTable[0] == -1);
    CHECK(lay->viewTable[1] == 1);
    CHECK(lay->samplerTable[0] == -1);
    CHECK(lay->samplerTable[1] == 2);
    CHECK(lay->bindlessTable == 3);  // D3d12Options::bindlessDescriptors > 0: every root signature sees the table
    CHECK(lay->viewCount[1] == 2);
    CHECK(lay->samplerCount[1] == 2);
    CHECK(lay->viewStage[1] == 1);
    CHECK(lay->viewOffset[0] == 0);
    CHECK(lay->viewOffset[1] == 1);
    CHECK(lay->samplerOffset[1] == 1);
    CHECK(lay->samplerUsed == 3u);

    step = "drawing with it: each view through its own sampler";
    const Pipeline pip = dev->make_pipeline(render_desc(two, PixelFormat::Rgba8));
    REQUIRE_MESSAGE(dev->state(pip) == ResourceState::Valid, all_errors(*dev));
    const Target t = make_target(*dev, Attach::Color, 4, 4, PixelFormat::Rgba8);
    CommandList& list = dev->begin_commands("two-views");
    list.begin_pass(color_pass(t, PixelFormat::Rgba8, Color{}));
    list.set_pipeline(pip);
    Bindings bind;
    bind.views[0] = make_texture(*dev, 1, 1, {255, 0, 0, 255});
    bind.views[1] = make_texture(*dev, 1, 1, {0, 255, 0, 255});
    bind.samplers[0] = make_clamped_sampler(*dev, Filter::Nearest);
    bind.samplers[1] = make_clamped_sampler(*dev, Filter::Linear);
    list.set_bindings(bind);
    list.set_uniforms(0, bytes_of(Vec4{1.0f, 1.0f, 1.0f, 1.0f}));
    list.draw(0, 3);
    list.end_pass();
    submit_and_finish(*dev, list);
    const std::string bad = first_mismatch(read_rgba8(*dev, t.image, 4, 4), 4, 4, 0,
                                           [](int, int) { return std::array<int, 4>{255, 255, 0, 255}; });
    CHECK_MESSAGE(bad.empty(), bad);
    step = "the debug layer said nothing";
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
}

TEST_CASE("d3d12: make_shader and make_pipeline say what is wrong with a desc") {
    auto dev = make_warp();
    if (!dev) return;
    auto shader_error = [&](const ShaderDesc& sd) {
        const Shader s = dev->make_shader(sd);
        CHECK(dev->state(s) == ResourceState::Failed);
        return last_error(*dev);
    };
    std::string step = "make_shader";
    INFO("step: " << step);
    ShaderDesc empty;
    empty.label = "a-shader";
    CHECK(contains(shader_error(empty), "make_shader 'a-shader': the vertex stage has neither source nor bytecode"));
    ShaderDesc sd = fill_shader_desc();
    const char spirv[8] = {0x03, 0x02, 0x23, 0x07, 0, 0, 1, 0};
    sd.vertexFunc.source = nullptr;
    sd.vertexFunc.bytecode = Range{spirv, sizeof spirv};
    CHECK(contains(shader_error(sd), "the vertex stage's bytecode is not DXBC"));
    sd = fill_shader_desc();
    sd.fragmentFunc.source = "float4 main() : SV_Target0 { return undeclared; }";
    std::string e = shader_error(sd);
    CHECK(contains(e, "the fragment stage does not compile as ps_5_1 (entry 'main')"));
    CHECK(contains(e, "undeclared"));  // the compiler's own message
    sd = fill_shader_desc();
    sd.computeFunc.source = kComputeCs;
    CHECK(contains(shader_error(sd), "it has a compute stage and a vertex or fragment stage"));
    sd = fill_shader_desc();
    sd.uniformBlocks[2] = sd.uniformBlocks[1];
    CHECK(
        contains(shader_error(sd), "uniform block 2 is on register b0, space0, which another slot of the same stage"));
    sd = fill_shader_desc();
    sd.views[0].texture.stage = ShaderStage::Fragment;
    sd.views[0].texture.binding.hlslSpace = 1;
    CHECK(contains(shader_error(sd), "space1's t registers are the bindless table's"));
    sd = fill_shader_desc();
    sd.samplers[0].stage = ShaderStage::Compute;
    CHECK(contains(shader_error(sd), "sampler 0 belongs to the compute stage, which a render shader does not have"));
    sd = fill_shader_desc();
    sd.uniformBlocks[1].size = 0;
    CHECK(contains(shader_error(sd), "uniform block 1 has 0 bytes"));

    step = "make_pipeline";
    auto pipeline_error = [&](const PipelineDesc& pd) {
        const Pipeline p = dev->make_pipeline(pd);
        CHECK(dev->state(p) == ResourceState::Failed);
        return last_error(*dev);
    };
    const Shader failed = dev->make_shader(empty);
    PipelineDesc pd = render_desc(failed, PixelFormat::Rgba8);
    pd.label = "a-pipeline";
    CHECK(contains(pipeline_error(pd), "make_pipeline 'a-pipeline': its shader failed"));
    const Shader fill = dev->make_shader(fill_shader_desc());
    const Shader inst = dev->make_shader(instance_shader_desc());
    REQUIRE_MESSAGE(dev->state(inst) == ResourceState::Valid, all_errors(*dev));
    pd = render_desc(fill, PixelFormat::Rgba8);
    pd.compute = true;
    CHECK(contains(pipeline_error(pd), "it is a compute pipeline and shader 'fill' is a render shader"));
    pd = render_desc(inst, PixelFormat::Rgba8);
    pd.layout.attrs[0].format = VertexFormat::Int10N2;
    CHECK(contains(pipeline_error(pd), "vertex attribute 0 has format Int10N2"));
    pd = render_desc(fill, PixelFormat::Rgba8);
    pd.layout.attrs[0].format = VertexFormat::Float2;
    CHECK(contains(pipeline_error(pd), "vertex attribute 0 has no HLSL semantic in shader 'fill'"));
    pd = render_desc(fill, PixelFormat::Bc7Rgba);
    CHECK(contains(pipeline_error(pd), "colour target 0 ("));
    CHECK(contains(last_error(*dev), "is not a colour format this GPU renders to"));
    pd = render_desc(fill, PixelFormat::Rgba8, PixelFormat::None, 3);
    CHECK(contains(pipeline_error(pd), "sampleCount 3 is not 1, 2, 4 or 8"));

    step = "the debug layer said nothing";
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

TEST_CASE("d3d12: the command list says what is wrong, skips what depends on it and records nothing broken") {
    auto dev = make_warp();
    if (!dev) return;
    const Shader fill = dev->make_shader(fill_shader_desc());
    const sg_shader_desc* blitDesc = blit_blit_keep_shader_desc(SG_BACKEND_D3D11);
    REQUIRE_MESSAGE(blitDesc, "the blit shader header has no D3D11 (HLSL) variant: regenerate it with D3D11 in");
    const Shader blitShader = dev->make_shader(from_sg(*blitDesc));
    const Pipeline rgba8 = dev->make_pipeline(render_desc(fill, PixelFormat::Rgba8));
    const Pipeline rgba16 = dev->make_pipeline(render_desc(fill, PixelFormat::Rgba16F));
    PipelineDesc bd = render_desc(blitShader, PixelFormat::Rgba8);
    bd.layout.attrs[0].format = VertexFormat::Float2;
    const Pipeline blit = dev->make_pipeline(bd);
    REQUIRE_MESSAGE(dev->state(blit) == ResourceState::Valid, all_errors(*dev));
    const Target t = make_target(*dev, Attach::Color, 4, 4, PixelFormat::Rgba8);
    const Buffer tri = make_vertex_buffer(*dev, {-1.0f, -1.0f, 3.0f, -1.0f, -1.0f, 3.0f});
    const Vec4 zero{};
    dev->clear_messages();
    CommandList& list = dev->begin_commands("mistakes");
    std::string step = "outside a pass";
    INFO("step: " << step);
    list.set_pipeline(rgba8);
    CHECK(contains(last_error(*dev), "CommandList::set_pipeline in list 'mistakes': outside a pass"));
    list.end_pass();
    CHECK(contains(last_error(*dev), "end_pass in list 'mistakes': no pass is open"));

    step = "a pass into the window without a swapchain";
    const Swapchain sc{};
    PassDesc window = PassDesc::for_swapchain(sc, dev->environment_defaults());
    window.label = "window";
    list.begin_pass(window);
    CHECK(
        contains(last_error(*dev), "pass 'window': a pass into the window (PassDesc::swapchain) without a swapchain"));
    CHECK(contains(last_error(*dev), "create_swapchain()"));
    CHECK(!contains(last_error(*dev), "M77"));
    std::size_t before = dev->errors().size();
    list.set_pipeline(rgba8);  // inside a failed pass: skipped without another error
    list.draw(0, 3);
    list.end_pass();
    CHECK(dev->errors().size() == before);

    step = "a pass whose format is not its attachments'";
    PassDesc wrong = color_pass(t, PixelFormat::Rgba16F, Color{});
    list.begin_pass(wrong);
    CHECK(contains(last_error(*dev), "is not what its attachments are"));
    list.end_pass();

    step = "a pipeline of another format";
    list.begin_pass(color_pass(t, PixelFormat::Rgba8, Color{}));
    list.set_pipeline(rgba16);
    CHECK(contains(last_error(*dev), "draws into"));
    before = dev->errors().size();
    list.draw(0, 3);  // skipped until the next set_pipeline
    CHECK(dev->errors().size() == before);

    step = "uniforms";
    list.set_pipeline(rgba8);
    list.draw(0, 3);
    CHECK(contains(last_error(*dev), "uniform block slot 0 of shader 'fill' was not set since set_pipeline"));
    list.set_uniforms(0, Range{zero.data(), 8});
    CHECK(contains(last_error(*dev), "uniform block slot 0 of shader 'fill' has 16 bytes and the data has 8"));
    list.set_pipeline(rgba8);
    list.set_uniforms(3, bytes_of(zero));
    CHECK(contains(last_error(*dev), "uniform block slot 3 is not one shader 'fill' declares"));

    step = "bindings";
    const std::array<float, 8> blitParams{};
    list.set_pipeline(blit);
    list.set_uniforms(0, Range{blitParams.data(), sizeof blitParams});
    list.set_uniforms(1, Range{blitParams.data(), sizeof blitParams});
    list.draw(0, 3);
    CHECK(contains(last_error(*dev), "reads buffers, views or samplers and set_bindings was not called since"));
    Bindings b;
    list.set_bindings(b);
    CHECK(contains(last_error(*dev), "vertex buffer slot 0 is empty and pipeline 'test-pipeline' reads it"));
    list.set_pipeline(blit);
    b.vertexBuffers[0] = tri;
    list.set_bindings(b);
    CHECK(contains(last_error(*dev), "view slot 0 is empty and shader '"));
    list.end_pass();

    step = "dispatch";
    list.begin_compute_pass("compute");
    list.set_pipeline(rgba8);
    CHECK(contains(last_error(*dev), "is a render pipeline inside a compute pass"));
    list.dispatch(70000, 1, 1);
    CHECK(contains(last_error(*dev), "each count is 0 to 65535"));
    list.end_pass();
    submit_and_finish(*dev, list);

    step = "the debug layer said nothing";
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
    step = "an async read of no buffer is a teaching error";
    auto ticket = dev->request_buffer_read(Buffer{}, 0, 4);
    REQUIRE(!ticket);
    CHECK(contains(ticket.error().message, "is not a live buffer"));
}

TEST_CASE("d3d12: commit listeners and frame counting") {
    auto dev = make_warp();
    if (!dev) return;
    int calls = 0;
    auto listener = [](void* user) { ++*static_cast<int*>(user); };
    CHECK(dev->add_commit_listener(listener, &calls));
    CHECK(!dev->add_commit_listener(listener, &calls));
    const std::uint64_t before = dev->frame_index();
    for (int i = 0; i < 5; ++i) dev->commit();  // more frames than are in flight: commit waits for the oldest
    CHECK(dev->frame_index() == before + 5);
    CHECK(calls == 5);
    CHECK(dev->remove_commit_listener(listener, &calls));
    dev->commit();
    CHECK(calls == 5);
    dev->enable_stats(true);
    BufferDesc bd;
    bd.size = 16;
    dev->destroy_buffer(dev->make_buffer(bd));
    CHECK(dev->total_stats().buffers.allocated == 1);
    CHECK(dev->total_stats().buffers.deallocated == 1);
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
}

// ---------------------------------------------------------------------------------------------------------------------
// GPU timers and asynchronous reads (M77-P7c2)
// ---------------------------------------------------------------------------------------------------------------------

TEST_CASE("d3d12: a timed frame with two scopes resolves to frame and scope times a few frames later") {
    auto dev = make_warp();
    if (!dev) return;
    std::string why;
    if (!dev->timer_supported(&why)) {
        MESSAGE("d3d12: skipped, this queue cannot time: " << why);
        return;
    }
    const Shader shader = dev->make_shader(fill_shader_desc());
    const Pipeline pipeline = dev->make_pipeline(render_desc(shader, PixelFormat::Rgba8));
    const Target t = make_target(*dev, Attach::Color, 64, 64, PixelFormat::Rgba8);
    REQUIRE_MESSAGE(dev->state(pipeline) == ResourceState::Valid, all_errors(*dev));
    REQUIRE_MESSAGE(dev->state(t.view) == ResourceState::Valid, all_errors(*dev));
    std::string step = "timed frames";
    INFO("step: " << step);
    std::vector<double> frames;
    for (int i = 0; i < 4; ++i) {
        dev->timer_begin_frame();
        CommandList& list = dev->begin_commands("timed");
        list.begin_timed_scope("clear");
        list.begin_pass(color_pass(t, PixelFormat::Rgba8, Color{0.0f, 0.0f, 0.0f, 1.0f}));
        list.end_pass();
        list.end_timed_scope();
        list.begin_timed_scope("fill");  // left open: submit ends it
        list.begin_pass(color_pass(t, PixelFormat::Rgba8, Color{0.0f, 0.0f, 0.0f, 1.0f}));
        list.set_pipeline(pipeline);
        const Vec4 depth{0.0f, 0.0f, 0.0f, 0.0f};
        const Vec4 colour{0.5f, 0.25f, 1.0f, 1.0f};
        list.set_uniforms(0, bytes_of(depth));
        list.set_uniforms(1, bytes_of(colour));
        list.draw(0, 3);
        list.end_pass();
        dev->submit(list);
        dev->timer_end_frame();
        dev->commit();
        dev->timer_poll(frames);  // never waits: whatever has arrived
    }
    auto r = dev->wait_idle();
    REQUIRE_MESSAGE(r, r.error().to_string());
    dev->timer_poll(frames);
    CHECK(frames.size() == 4);  // every timed frame arrives once, in order
    for (double ms : frames) CHECK(ms >= 0.0);
    const std::vector<Device::ScopeTime> scopes = dev->timer_last_scopes();
    REQUIRE(scopes.size() == 2);
    CHECK(scopes[0].name == "clear");
    CHECK(scopes[1].name == "fill");
    CHECK(scopes[0].ms >= 0.0);
    CHECK(scopes[1].ms >= 0.0);

    step = "a scope outside a timed frame records nothing";
    CommandList& untimed = dev->begin_commands("untimed");
    untimed.begin_timed_scope("ignored");
    untimed.begin_pass(color_pass(t, PixelFormat::Rgba8, Color{0.0f, 0.0f, 0.0f, 1.0f}));
    untimed.end_pass();
    untimed.end_timed_scope();
    submit_and_finish(*dev, untimed);
    frames.clear();
    dev->timer_poll(frames);
    CHECK(frames.empty());
    CHECK(dev->timer_last_scopes().size() == 2);  // still the last timed frame's

    step = "a scope whose list is not submitted before the frame ends is not reported";
    dev->timer_begin_frame();
    CommandList& late = dev->begin_commands("late");
    late.begin_timed_scope("late");
    late.end_timed_scope();
    dev->timer_end_frame();
    submit_and_finish(*dev, late);
    dev->timer_poll(frames);
    CHECK(frames.size() == 1);
    CHECK(dev->timer_last_scopes().empty());

    step = "timer_forget drops the results in flight";
    dev->timer_begin_frame();
    CommandList& forgotten = dev->begin_commands("forgotten");
    forgotten.begin_timed_scope("forgotten");
    forgotten.end_timed_scope();
    dev->submit(forgotten);
    dev->timer_end_frame();
    dev->timer_forget();
    r = dev->wait_idle();
    REQUIRE_MESSAGE(r, r.error().to_string());
    frames.clear();
    dev->timer_poll(frames);
    CHECK(frames.empty());
    CHECK(dev->timer_last_scopes().empty());

    step = "a full ring skips frames instead of waiting";
    for (int i = 0; i < 10; ++i) {  // never polled: six frames fill the ring, the rest are not timed
        dev->timer_begin_frame();
        dev->timer_end_frame();
    }
    r = dev->wait_idle();
    REQUIRE_MESSAGE(r, r.error().to_string());
    dev->timer_poll(frames);
    CHECK(frames.size() == 6);
    step = "the debug layer said nothing";
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
}

namespace {

Buffer make_storage_buffer(D3d12Device& dev, const std::vector<std::uint8_t>& data, const char* label) {
    BufferDesc bd;
    bd.size = data.size();
    bd.usage.storageBuffer = true;
    bd.usage.copySrc = true;
    bd.data = range_of(data);
    bd.label = label;
    return dev.make_buffer(bd);
}

}  // namespace

TEST_CASE("d3d12: async reads of a buffer and of a texture region whose rows are not 256-byte multiples") {
    auto dev = make_warp();
    if (!dev) return;
    std::string step = "buffer";
    INFO("step: " << step);
    const std::vector<std::uint8_t> data = pattern(5000, 7);
    const Buffer buf = make_storage_buffer(*dev, data, "async-src");
    REQUIRE(dev->state(buf) == ResourceState::Valid);
    auto t = dev->request_buffer_read(buf, 100, 3000);
    REQUIRE_MESSAGE(t, t.error().to_string());
    REQUIRE(t.value().valid());
    std::vector<std::uint8_t> out;
    REQUIRE(dev->poll_buffer_read(t.value(), out, true));
    CHECK(out == std::vector<std::uint8_t>(data.begin() + 100, data.begin() + 3100));

    step = "a write in a submitted list comes before the read";
    const std::vector<std::uint8_t> patch = pattern(64, 8);
    CommandList& list = dev->begin_commands("patch");
    BufferWrite w;
    w.data = range_of(patch);
    w.buffer = buf;
    w.dstOffset = 0;
    list.write_buffer(w);
    dev->submit(list);
    t = dev->request_buffer_read(buf, 0, 64);
    REQUIRE_MESSAGE(t, t.error().to_string());
    bool done = false;
    for (int i = 0; i < 100000 && !done; ++i) done = dev->poll_buffer_read(t.value(), out, false);  // no stall
    if (!done) done = dev->poll_buffer_read(t.value(), out, true);
    REQUIRE(done);
    CHECK(out == patch);
    dev->commit();

    step = "texture: a 33x3 region of a 37x5 RGBA8 image (132-byte rows, 256-byte aligned in the copy)";
    const std::vector<std::uint8_t> texels = pattern(std::size_t(37) * 5 * 4, 9);
    ImageDesc id;
    id.width = 37;
    id.height = 5;
    id.pixelFormat = PixelFormat::Rgba8;
    id.data.mipLevels[0] = range_of(texels);
    id.label = "async-image";
    const Image img = dev->make_image(id);
    REQUIRE(dev->state(img) == ResourceState::Valid);
    auto ti = dev->request_image_read(img, 0, 0, 3, 1, 33, 3);
    REQUIRE_MESSAGE(ti, ti.error().to_string());
    REQUIRE(ti.value().valid());
    REQUIRE(dev->poll_buffer_read(ti.value(), out, true));
    CHECK(out == crop(texels, 37, 4, 3, 1, 33, 3));
    ti = dev->request_image_read(img, 0, 0, 0, 0, 37, 5);
    REQUIRE_MESSAGE(ti, ti.error().to_string());
    REQUIRE(dev->poll_buffer_read(ti.value(), out, true));
    CHECK(out == texels);

    step = "bad requests are teaching errors";
    auto bad = dev->request_buffer_read(buf, 4000, 2000);
    REQUIRE(!bad);
    CHECK(contains(bad.error().message, "go past its 5000 bytes"));
    bad = dev->request_buffer_read(buf, 0, 0);
    REQUIRE(!bad);
    CHECK(contains(bad.error().message, "is no read"));
    bad = dev->request_image_read(img, 0, 0, 30, 0, 8, 1);
    REQUIRE(!bad);
    CHECK(contains(bad.error().message, "outside its 37x5 mip 0"));
    bad = dev->request_image_read(img, 1, 0, 0, 0, 1, 1);
    REQUIRE(!bad);
    CHECK(contains(bad.error().message, "mip 1 is outside"));

    step = "a read survives destroy_buffer";
    t = dev->request_buffer_read(buf, 0, 5000);
    REQUIRE_MESSAGE(t, t.error().to_string());
    dev->destroy_buffer(buf);
    dev->commit();
    REQUIRE(dev->poll_buffer_read(t.value(), out, true));
    std::vector<std::uint8_t> expected = data;
    std::memcpy(expected.data(), patch.data(), patch.size());
    CHECK(out == expected);
    step = "the debug layer said nothing";
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

TEST_CASE("d3d12: async read tickets are generation-checked, and every slot can be in flight at once") {
    auto dev = make_warp();
    if (!dev) return;
    const std::vector<std::uint8_t> data = pattern(1024, 11);
    const Buffer buf = make_storage_buffer(*dev, data, "tickets");
    REQUIRE(dev->state(buf) == ResourceState::Valid);
    std::string step = "a ticket is read once";
    INFO("step: " << step);
    std::vector<std::uint8_t> out;
    auto a = dev->request_buffer_read(buf, 0, 16);
    REQUIRE_MESSAGE(a, a.error().to_string());
    REQUIRE(dev->poll_buffer_read(a.value(), out, true));
    CHECK(out == std::vector<std::uint8_t>(data.begin(), data.begin() + 16));
    out.clear();
    CHECK(!dev->poll_buffer_read(a.value(), out, true));  // stale: already read
    CHECK(out.empty());
    CHECK(!dev->poll_buffer_read(ReadTicket{}, out, true));
    CHECK(!dev->poll_buffer_read(ReadTicket{1000, 1}, out, true));

    step = "a released ticket is stale, and a stale ticket does not touch the slot's next request";
    auto b = dev->request_buffer_read(buf, 16, 16);
    REQUIRE_MESSAGE(b, b.error().to_string());
    dev->release_buffer_read(b.value());
    CHECK(!dev->poll_buffer_read(b.value(), out, true));
    auto r = dev->wait_idle();
    REQUIRE_MESSAGE(r, r.error().to_string());
    auto c = dev->request_buffer_read(buf, 32, 16);
    REQUIRE_MESSAGE(c, c.error().to_string());
    CHECK(c.value().slot == b.value().slot);  // the slot came back once its copy finished
    CHECK(c.value().generation != b.value().generation);
    dev->release_buffer_read(b.value());  // stale: ignored
    dev->release_buffer_read(a.value());
    CHECK(!dev->poll_buffer_read(b.value(), out, true));
    REQUIRE(dev->poll_buffer_read(c.value(), out, true));
    CHECK(out == std::vector<std::uint8_t>(data.begin() + 32, data.begin() + 48));

    step = "32 reads in flight; the 33rd gets an invalid ticket with ok";
    std::vector<ReadTicket> tickets;
    for (int i = 0; i < 32; ++i) {
        auto t = dev->request_buffer_read(buf, std::size_t(i) * 32, 32);
        REQUIRE_MESSAGE(t, t.error().to_string());
        REQUIRE_MESSAGE(t.value().valid(), "read " << i);
        tickets.push_back(t.value());
    }
    auto full = dev->request_buffer_read(buf, 0, 4);
    REQUIRE_MESSAGE(full, full.error().to_string());
    CHECK(!full.value().valid());
    for (std::size_t i = tickets.size(); i-- > 0;) {  // in reverse: no order between slots
        REQUIRE_MESSAGE(dev->poll_buffer_read(tickets[i], out, true), "read " << i);
        CHECK_MESSAGE(out == std::vector<std::uint8_t>(data.begin() + std::ptrdiff_t(i * 32),
                                                       data.begin() + std::ptrdiff_t(i * 32 + 32)),
                      "read " << i);
    }
    auto again = dev->request_buffer_read(buf, 0, 4);
    REQUIRE_MESSAGE(again, again.error().to_string());
    CHECK(again.value().valid());
    dev->release_buffer_read(again.value());

    step = "a read bigger than the slot's buffer grows it";
    std::vector<std::uint8_t> big = pattern(200000, 12);
    const Buffer large = make_storage_buffer(*dev, big, "large");
    REQUIRE(dev->state(large) == ResourceState::Valid);
    auto l = dev->request_buffer_read(large, 0, big.size());
    REQUIRE_MESSAGE(l, l.error().to_string());
    REQUIRE(dev->poll_buffer_read(l.value(), out, true));
    CHECK(out == big);
    step = "the debug layer said nothing";
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
}

// ---- the PSO cache on disk (M77-P7b) -------------------------------------------------------------------------------

namespace {

using fa::gpu::d3d12::PipelineCacheFile;

// A folder of its own for a case's cache file, removed at the end. The accent: the path never goes through the ANSI
// code page.
struct CacheDir {
    std::filesystem::path path;
    explicit CacheDir(const char* name) {
        path = std::filesystem::temp_directory_path() / std::filesystem::path(u8"fa-d3d12-pso-caché");
        path += std::filesystem::path(std::string("-") + name + "-" + std::to_string(GetCurrentProcessId()));
        std::error_code ec;
        std::filesystem::remove_all(path, ec);
        std::filesystem::create_directories(path, ec);
    }
    ~CacheDir() {
        std::error_code ec;
        std::filesystem::remove_all(path, ec);
    }
    CacheDir(const CacheDir&) = delete;
    CacheDir& operator=(const CacheDir&) = delete;
    std::filesystem::path file() const { return path / "d3d12-pipelines.bin"; }
};

// A WARP device that caches its PSOs in `file`, or null (with a MESSAGE) when it has no pipeline library.
std::unique_ptr<D3d12Device> make_cached_warp(const std::filesystem::path& file) {
    D3d12Options o;
    o.pipelineCacheFile = file;
    auto dev = make_warp(o);
    if (dev && !dev->counters().pipelineLibrary) {
        MESSAGE("d3d12: skipped, this device has no pipeline library: " << all_errors(*dev));
        return nullptr;
    }
    return dev;
}

// Three PSOs: the fill shader into RGBA8 and into RGBA16F, and the compute shader. Returns the RGBA8 one.
Pipeline make_cache_pipelines(D3d12Device& dev) {
    const Shader fill = dev.make_shader(fill_shader_desc());
    const Pipeline rgba8 = dev.make_pipeline(render_desc(fill, PixelFormat::Rgba8));
    const Pipeline rgba16 = dev.make_pipeline(render_desc(fill, PixelFormat::Rgba16F));
    ShaderDesc sd;
    sd.computeFunc.source = kComputeCs;
    sd.uniformBlocks[0].stage = ShaderStage::Compute;
    sd.uniformBlocks[0].size = 16;
    sd.views[0].storageImage.stage = ShaderStage::Compute;
    sd.views[0].storageImage.imageType = ImageType::Tex2d;
    sd.views[0].storageImage.accessFormat = PixelFormat::Rgba8;
    sd.views[1].storageBuffer.stage = ShaderStage::Compute;
    sd.views[1].storageBuffer.hlslRegisterU = 1;
    sd.label = "compute";
    PipelineDesc pd;
    pd.compute = true;
    pd.shader = dev.make_shader(sd);
    pd.label = "compute";
    const Pipeline compute = dev.make_pipeline(pd);
    CHECK_MESSAGE(dev.state(rgba8) == ResourceState::Valid, all_errors(dev));
    CHECK_MESSAGE(dev.state(rgba16) == ResourceState::Valid, all_errors(dev));
    CHECK_MESSAGE(dev.state(compute) == ResourceState::Valid, all_errors(dev));
    return rgba8;
}

// The fill pipeline draws (64, 128, 191, 255) over a 4x4 RGBA8 target.
void check_fill_draws(D3d12Device& dev, Pipeline pip) {
    const Target t = make_target(dev, Attach::Color, 4, 4, PixelFormat::Rgba8);
    const Vec4 depth{0.0f, 0.0f, 0.0f, 0.0f};
    const Vec4 colour{0.25f, 0.5f, 0.75f, 1.0f};
    CommandList& list = dev.begin_commands("cached");
    list.begin_pass(color_pass(t, PixelFormat::Rgba8, Color{}));
    list.set_pipeline(pip);
    list.set_uniforms(0, bytes_of(depth));
    list.set_uniforms(1, bytes_of(colour));
    list.draw(0, 3);
    list.end_pass();
    submit_and_finish(dev, list);
    const std::string bad = first_mismatch(read_rgba8(dev, t.image, 4, 4), 4, 4, 1,
                                           [](int, int) { return std::array<int, 4>{64, 128, 191, 255}; });
    CHECK_MESSAGE(bad.empty(), bad);
}

// The device's warnings about its pipeline cache file.
std::vector<std::string> cache_warnings(D3d12Device& dev) {
    std::vector<std::string> out;
    for (const std::string& w : dev.warnings())
        if (contains(w, "pipeline cache")) out.push_back(w);
    return out;
}

std::vector<std::uint8_t> file_bytes(const std::filesystem::path& file) {
    auto r = fa::fs::read_bytes(fa::fs::path_to_utf8(file));
    REQUIRE_MESSAGE(r, r.error().to_string());
    return r.value();
}

void put_file(const std::filesystem::path& file, const std::vector<std::uint8_t>& bytes) {
    auto r = fa::fs::write_bytes(fa::fs::path_to_utf8(file), bytes.data(), bytes.size());
    REQUIRE_MESSAGE(r, r.error().to_string());
}

}  // namespace

TEST_CASE("d3d12: a second device loads its PSOs from the pipeline cache file the first one wrote") {
    const CacheDir dir("hits");
    const fa::gpu::D3d12PipelineCacheTotals before = fa::gpu::d3d12_pipeline_cache_totals();
    {
        auto dev = make_cached_warp(dir.file());
        if (!dev) return;
        CHECK(dev->pipeline_cache_file() == dir.file());
        make_cache_pipelines(*dev);
        d3d12::D3d12Counters c = dev->counters();
        CHECK(c.psoLibraryMisses == 3);  // compiled and stored
        CHECK(c.psoLibraryHits == 0);
        CHECK(c.pipelineCacheDiscarded == 0);
        auto saved = dev->save_pipeline_cache();
        REQUIRE_MESSAGE(saved, saved.error().to_string());
        CHECK(dev->counters().pipelineCacheStored == 1);
        REQUIRE(std::filesystem::exists(dir.file()));
        CHECK(std::filesystem::file_size(dir.file()) > PipelineCacheFile::kHeaderBytes);
        saved = dev->save_pipeline_cache();  // nothing new: the file is not written again
        REQUIRE_MESSAGE(saved, saved.error().to_string());
        CHECK(dev->counters().pipelineCacheStored == 1);
        CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
    }
    auto dev = make_cached_warp(dir.file());
    REQUIRE(dev);
    const Pipeline pip = make_cache_pipelines(*dev);
    const d3d12::D3d12Counters c = dev->counters();
    CHECK(c.psoLibraryHits == 3);  // loaded from the library, none compiled
    CHECK(c.psoLibraryMisses == 0);
    CHECK(c.pipelineCacheDiscarded == 0);
    check_fill_draws(*dev, pip);
    CHECK(cache_warnings(*dev).empty());
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
    const fa::gpu::D3d12PipelineCacheTotals after = fa::gpu::d3d12_pipeline_cache_totals();
    CHECK(after.libraryHits >= before.libraryHits + 3);
    CHECK(after.libraryMisses >= before.libraryMisses + 3);
    CHECK(after.filesLoaded >= before.filesLoaded + 1);
    CHECK(after.filesStored >= before.filesStored + 1);
}

TEST_CASE(
    "d3d12: a damaged or foreign pipeline cache file is thrown away with one warning, and pipelines still build") {
    const CacheDir dir("discard");
    std::vector<std::uint8_t> good;
    {
        auto dev = make_cached_warp(dir.file());
        if (!dev) return;
        make_cache_pipelines(*dev);
        auto saved = dev->save_pipeline_cache();
        REQUIRE_MESSAGE(saved, saved.error().to_string());
        good = file_bytes(dir.file());
    }
    REQUIRE(good.size() > PipelineCacheFile::kHeaderBytes);
    struct Variant {
        const char* name;
        const char* why;  // in the warning
        std::vector<std::uint8_t> bytes;
    };
    std::vector<Variant> variants;
    variants.push_back({"a flipped payload byte", "checksum does not match", good});
    variants.back().bytes.back() = std::uint8_t(good.back() ^ 0x5au);
    variants.push_back({"another GPU's vendor id", "made on another GPU", good});
    variants.back().bytes[PipelineCacheFile::kVendorAt] = std::uint8_t(good[PipelineCacheFile::kVendorAt] ^ 1u);
    variants.push_back({"another driver version", "made by driver", good});
    variants.back().bytes[PipelineCacheFile::kDriverAt] = std::uint8_t(good[PipelineCacheFile::kDriverAt] ^ 1u);
    variants.push_back({"not a cache file", "not a FactorIA pipeline cache", pattern(4096, 7)});
    variants.push_back(
        {"a cut header", "fewer than its header", std::vector<std::uint8_t>(good.begin(), good.begin() + 40)});
    for (const Variant& v : variants) {
        INFO("file: " << v.name);
        put_file(dir.file(), v.bytes);
        auto dev = make_cached_warp(dir.file());
        REQUIRE(dev);
        const std::vector<std::string> warned = cache_warnings(*dev);
        REQUIRE(warned.size() == 1);
        CHECK(contains(warned[0], "was thrown away"));
        CHECK(contains(warned[0], v.why));
        CHECK(contains(warned[0], "deleting the file clears the cache"));
        CHECK(dev->counters().pipelineCacheDiscarded == 1);
        const Pipeline pip = make_cache_pipelines(*dev);  // compiled again
        CHECK(dev->counters().psoLibraryMisses == 3);
        check_fill_draws(*dev, pip);
        auto saved = dev->save_pipeline_cache();  // the file is written anew
        REQUIRE_MESSAGE(saved, saved.error().to_string());
        CHECK(dev->counters().pipelineCacheStored == 1);
        CHECK(cache_warnings(*dev).size() == 1);  // once, not per pipeline
        CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
    }
    auto dev = make_cached_warp(dir.file());  // the rewritten file is good again
    REQUIRE(dev);
    make_cache_pipelines(*dev);
    CHECK(dev->counters().pipelineCacheDiscarded == 0);
    CHECK(dev->counters().psoLibraryHits == 3);
    CHECK(cache_warnings(*dev).empty());

    // A reader holds the file (Windows replaces no open file): the write fails, warns and keeps the old file.
    const std::vector<std::uint8_t> old = file_bytes(dir.file());
    const Shader fill = dev->make_shader(fill_shader_desc());
    const Pipeline extra = dev->make_pipeline(render_desc(fill, PixelFormat::R32F));  // something new to store
    REQUIRE_MESSAGE(dev->state(extra) == ResourceState::Valid, all_errors(*dev));
    {
        fa::fs::ReadStream reader(dir.file(), std::ios::binary);
        REQUIRE(reader.is_open());
        auto saved = dev->save_pipeline_cache();
        CHECK_FALSE(saved);
        if (!saved) CHECK(contains(saved.error().message, "the old file was kept"));
        const std::vector<std::string> warned = cache_warnings(*dev);
        REQUIRE(warned.size() == 1);
        CHECK(contains(warned[0], "the old file was kept"));
    }
    CHECK(file_bytes(dir.file()) == old);
    auto saved = dev->save_pipeline_cache();  // the reader is gone: the PSO is still to store
    REQUIRE_MESSAGE(saved, saved.error().to_string());
    CHECK(file_bytes(dir.file()) != old);
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
}

TEST_CASE("d3d12: storage_image_loadable answers from the device's typed UAV load support, with a why") {
    auto dev = make_warp();
    if (!dev) return;
    std::string why;
    CHECK_MESSAGE(dev->storage_image_loadable(PixelFormat::R32F, &why), why);  // every D3D12 GPU loads r32f
    why.clear();
    const bool rgba8 = dev->storage_image_loadable(PixelFormat::Rgba8, &why);
    if (dev->warp()) CHECK_MESSAGE(rgba8, why);  // WARP has TypedUAVLoadAdditionalFormats
    if (!rgba8) CHECK((contains(why, "TypedUAVLoadAdditionalFormats") || contains(why, "UAV_TYPED_LOAD")));
    why.clear();
    CHECK_FALSE(dev->storage_image_loadable(PixelFormat::Rg16F, &why));
    CHECK(contains(why, "rgba8, rgba16f, r32f or rgba32f"));
    CHECK_FALSE(dev->storage_image_loadable(PixelFormat::Rg16F, nullptr));  // no why wanted
}

TEST_CASE("d3d12: binding an image the pass draws into for reading is an error; after end_pass it is a texture") {
    auto dev = make_warp();
    if (!dev) return;
    const sg_shader_desc* blitDesc = blit_blit_keep_shader_desc(SG_BACKEND_D3D11);
    REQUIRE_MESSAGE(blitDesc, "the blit shader header has no D3D11 (HLSL) variant: regenerate it with D3D11 in");
    const Shader shader = dev->make_shader(from_sg(*blitDesc));
    PipelineDesc pd = render_desc(shader, PixelFormat::Rgba8);
    pd.layout.attrs[0].format = VertexFormat::Float2;
    const Pipeline blit = dev->make_pipeline(pd);
    REQUIRE_MESSAGE(dev->state(blit) == ResourceState::Valid, all_errors(*dev));
    const Buffer tri = make_vertex_buffer(*dev, {-1.0f, -1.0f, 3.0f, -1.0f, -1.0f, 3.0f});
    const Sampler nearest = make_clamped_sampler(*dev, Filter::Nearest);
    const Target a = make_target(*dev, Attach::Color, 4, 4, PixelFormat::Rgba8);
    const Target b = make_target(*dev, Attach::Color, 4, 4, PixelFormat::Rgba8);
    ViewDesc vd;
    vd.texture.image = a.image;
    const View aTexture = dev->make_view(vd);
    REQUIRE_MESSAGE(dev->state(aTexture) == ResourceState::Valid, all_errors(*dev));
    const Color red{1.0f, 0.0f, 0.0f, 1.0f};
    CommandList& first = dev->begin_commands("fill-a");
    first.begin_pass(color_pass(a, PixelFormat::Rgba8, red));
    first.end_pass();
    submit_and_finish(*dev, first);
    dev->clear_messages();

    const std::array<float, 8> vsParams{};
    const std::array<float, 8> fsParams{};
    Bindings bind;
    bind.vertexBuffers[0] = tri;
    bind.views[0] = aTexture;
    bind.samplers[0] = nearest;
    CommandList& list = dev->begin_commands("feedback");
    list.begin_pass(color_pass(a, PixelFormat::Rgba8, red));
    list.set_pipeline(blit);
    list.set_bindings(bind);
    const std::string e = last_error(*dev);
    CHECK_MESSAGE(contains(e, "view slot 0"), e);
    CHECK_MESSAGE(contains(e, "of an image the pass draws into as its colour attachment (PassDesc::color)"), e);
    CHECK_MESSAGE(contains(e, "end_pass() before reading what a pass drew"), e);
    list.end_pass();
    const std::size_t before = dev->errors().size();
    list.begin_pass(color_pass(b, PixelFormat::Rgba8, Color{}));  // a is a texture again
    list.set_pipeline(blit);
    list.set_bindings(bind);
    list.set_uniforms(0, Range{vsParams.data(), sizeof vsParams});
    list.set_uniforms(1, Range{fsParams.data(), sizeof fsParams});
    list.draw(0, 3);
    list.end_pass();
    submit_and_finish(*dev, list);
    CHECK_MESSAGE(dev->errors().size() == before, all_errors(*dev));
    const std::string bad = first_mismatch(read_rgba8(*dev, b.image, 4, 4), 4, 4, 0,
                                           [](int, int) { return std::array<int, 4>{255, 0, 0, 255}; });
    CHECK_MESSAGE(bad.empty(), bad);
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

TEST_CASE("d3d12: a dropped timed frame gives its timer slot back") {
    auto dev = make_warp();
    if (!dev) return;
    std::string why;
    if (!dev->timer_supported(&why)) {
        MESSAGE("d3d12: skipped, this queue cannot time: " << why);
        return;
    }
    dev->timer_begin_frame();
    dev->timer_end_frame();
    CHECK(dev->timer_slots_busy() == 1);
    dev->drop_next_timed_frame();
    dev->timer_begin_frame();
    CHECK(dev->timer_slots_busy() == 2);  // open
    dev->timer_end_frame();
    CHECK(dev->timer_slots_busy() == 1);  // dropped: its slot is free again
    for (int i = 0; i < 5; ++i) {
        dev->timer_begin_frame();
        dev->timer_end_frame();
    }
    CHECK(dev->timer_slots_busy() == 6);  // the whole ring, none lost to the dropped frame
    dev->timer_begin_frame();             // a full ring: not timed
    dev->timer_end_frame();
    CHECK(dev->timer_slots_busy() == 6);
    auto r = dev->wait_idle();
    REQUIRE_MESSAGE(r, r.error().to_string());
    std::vector<double> frames;
    dev->timer_poll(frames);
    CHECK(frames.size() == 6);
    CHECK(dev->timer_slots_busy() == 0);
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
}

TEST_CASE("d3d12: a list open over the whole timer ring keeps its slot; its late scope is not reported") {
    auto dev = make_warp();
    if (!dev) return;
    std::string why;
    if (!dev->timer_supported(&why)) {
        MESSAGE("d3d12: skipped, this queue cannot time: " << why);
        return;
    }
    const Target t = make_target(*dev, Attach::Color, 4, 4, PixelFormat::Rgba8);
    std::vector<double> frames;
    dev->timer_begin_frame();
    const int staleSlot = dev->timer_current_slot();
    REQUIRE(staleSlot >= 0);
    CommandList& stale = dev->begin_commands("stale");
    stale.begin_timed_scope("stale");
    dev->timer_end_frame();
    for (int i = 0; i < 7; ++i) {  // more frames than the ring has slots: the open list's slot is never taken again
        dev->timer_begin_frame();
        CHECK(dev->timer_current_slot() >= 0);
        CHECK(dev->timer_current_slot() != staleSlot);
        dev->timer_end_frame();
        auto r = dev->wait_idle();
        REQUIRE_MESSAGE(r, r.error().to_string());
        dev->timer_poll(frames);
    }
    stale.end_timed_scope();
    stale.begin_pass(color_pass(t, PixelFormat::Rgba8, Color{0.0f, 0.0f, 0.0f, 1.0f}));
    stale.end_pass();
    dev->submit(stale);
    dev->timer_begin_frame();
    CommandList& fresh = dev->begin_commands("fresh");
    fresh.begin_timed_scope("fresh");
    fresh.begin_pass(color_pass(t, PixelFormat::Rgba8, Color{0.0f, 0.0f, 0.0f, 1.0f}));
    fresh.end_pass();
    fresh.end_timed_scope();
    dev->submit(fresh);
    dev->timer_end_frame();
    dev->commit();
    auto r = dev->wait_idle();
    REQUIRE_MESSAGE(r, r.error().to_string());
    frames.clear();
    dev->timer_poll(frames);
    CHECK(frames.size() == 1);
    const std::vector<Device::ScopeTime> scopes = dev->timer_last_scopes();
    REQUIRE(scopes.size() == 1);
    CHECK(scopes[0].name == "fresh");
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

namespace {

// words[i] = words[i] * 2 + 1, for 64 words.
constexpr const char* kTwiceCs = R"(
RWByteAddressBuffer words : register(u0);
[numthreads(64, 1, 1)]
void main(uint3 id : SV_DispatchThreadID) {
    words.Store(id.x * 4, words.Load(id.x * 4) * 2 + 1);
}
)";

// img[x, y] = (x * 32, y * 32, 0, 255) / 255, for 8x8 texels.
constexpr const char* kGradientCs = R"(
RWTexture2D<float4> img : register(u0);
[numthreads(8, 8, 1)]
void main(uint3 id : SV_DispatchThreadID) {
    img[id.xy] = float4(float(id.x * 32) / 255.0, float(id.y * 32) / 255.0, 0.0, 1.0);
}
)";

// The texel under each pixel of t0.
constexpr const char* kLoadFs = R"(
Texture2D<float4> tex : register(t0);
float4 main(float4 pos : SV_Position) : SV_Target0 { return tex.Load(int3(int2(pos.xy), 0)); }
)";

// Texel (0, 0) of the bindless table's entry fs_params.pick.x.
constexpr const char* kBindlessFs = R"(
Texture2D<float4> table[] : register(t0, space1);
cbuffer fs_params : register(b0) { uint4 pick; };
float4 main(float4 pos : SV_Position) : SV_Target0 { return table[pick.x].Load(int3(0, 0, 0)); }
)";

Pipeline make_compute_pipeline(D3d12Device& dev, const char* source, bool image, const char* label) {
    ShaderDesc sd;
    sd.computeFunc.source = source;
    if (image) {
        sd.views[0].storageImage.stage = ShaderStage::Compute;
        sd.views[0].storageImage.imageType = ImageType::Tex2d;
        sd.views[0].storageImage.accessFormat = PixelFormat::Rgba8;
    } else {
        sd.views[0].storageBuffer.stage = ShaderStage::Compute;
        sd.views[0].storageBuffer.hlslRegisterU = 0;
    }
    sd.label = label;
    const Shader shader = dev.make_shader(sd);
    PipelineDesc pd;
    pd.compute = true;
    pd.shader = shader;
    pd.label = label;
    return dev.make_pipeline(pd);
}

// A storage buffer of 64 zero words that lists copy from, and its storage view.
struct Words {
    Buffer buffer{};
    View view{};
};

Words make_words(D3d12Device& dev, const char* label) {
    Words w;
    w.buffer = make_storage_buffer(dev, std::vector<std::uint8_t>(64 * 4, 0), label);
    ViewDesc vd;
    vd.storageBuffer.buffer = w.buffer;
    w.view = dev.make_view(vd);
    return w;
}

void twice(CommandList& list, Pipeline pip, const Words& w) {
    Bindings b;
    b.views[0] = w.view;
    list.begin_compute_pass("twice");
    list.set_pipeline(pip);
    list.set_bindings(b);
    list.dispatch(1, 1, 1);
    list.end_pass();
}

std::vector<std::uint32_t> read_words(D3d12Device& dev, Buffer b) {
    std::vector<std::uint8_t> raw;
    auto r = dev.read_buffer(b, 0, 64 * 4, raw);
    REQUIRE_MESSAGE(r, r.error().to_string());
    std::vector<std::uint32_t> words(raw.size() / 4);
    std::memcpy(words.data(), raw.data(), words.size() * 4);
    return words;
}

QueueHandoff hand_buffer(Buffer b, QueueKind to) {
    QueueHandoff h;
    h.buffer = b;
    h.to = to;
    return h;
}

QueueHandoff hand_image(Image i, QueueKind to) {
    QueueHandoff h;
    h.image = i;
    h.to = to;
    return h;
}

}  // namespace

TEST_CASE("d3d12: the compute and copy queues run lists of their kind; without them their lists run on another") {
    auto dev = make_warp();
    if (!dev) return;
    CHECK(dev->features().multiThreadRecording);
    CHECK(dev->features().bindless == (dev->bindless_descriptors() > 0));
    CHECK(dev->features().asyncCompute);  // WARP makes compute and copy queues
    CommandList& c = dev->begin_commands("compute", QueueKind::Compute);
    CommandList& t = dev->begin_commands("transfer", QueueKind::Transfer);
    CommandList& g = dev->begin_commands("graphics");
    CHECK(c.queue() == QueueKind::Compute);
    CHECK(t.queue() == QueueKind::Transfer);
    CHECK(g.queue() == QueueKind::Graphics);
    const SyncToken tc = dev->submit_token(c);
    const SyncToken tt = dev->submit_token(t);
    CHECK(tc.queue == QueueKind::Compute);
    CHECK(tc.valid());
    CHECK(tt.queue == QueueKind::Transfer);
    dev->wait_list(g, tc);
    dev->wait_list(g, tt);
    dev->wait_queue(QueueKind::Graphics, tc);
    const SyncToken tg = dev->submit_token(g);
    CHECK(tg.queue == QueueKind::Graphics);
    CHECK(tg.valid());
    dev->commit();
    auto r = dev->wait_idle();
    REQUIRE_MESSAGE(r, r.error().to_string());
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));

    // A token no submit_token returned is an error, and ignored.
    CommandList& bad = dev->begin_commands("bad-wait");
    dev->wait_list(bad, SyncToken{QueueKind::Compute, tc.value + 1000});
    dev->submit(bad);
    const std::string e = last_error(*dev);
    CHECK_MESSAGE(contains(e, "which no submit_token() of this device returned"), e);
    dev->commit();
    r = dev->wait_idle();
    REQUIRE_MESSAGE(r, r.error().to_string());

    D3d12Options single;
    single.asyncQueues = false;
    auto one = make_warp(single);
    REQUIRE(one);
    CHECK(!one->features().asyncCompute);
    CommandList& c1 = one->begin_commands("compute", QueueKind::Compute);
    CommandList& t1 = one->begin_commands("transfer", QueueKind::Transfer);
    CHECK(c1.queue() == QueueKind::Graphics);
    CHECK(t1.queue() == QueueKind::Graphics);
    one->submit(c1);
    one->submit(t1);
    one->commit();
    r = one->wait_idle();
    REQUIRE_MESSAGE(r, r.error().to_string());
    CHECK_MESSAGE(all_errors(*one).empty(), all_errors(*one));
}

TEST_CASE("d3d12: a buffer goes from graphics to compute and back with handoffs; without one the list is dropped") {
    auto dev = make_warp();
    if (!dev) return;
    const Pipeline pip = make_compute_pipeline(*dev, kTwiceCs, false, "twice");
    REQUIRE_MESSAGE(dev->state(pip) == ResourceState::Valid, all_errors(*dev));
    const Words w = make_words(*dev, "handed-words");
    REQUIRE_MESSAGE(dev->state(w.view) == ResourceState::Valid, all_errors(*dev));

    std::string step = "graphics -> compute -> graphics";
    INFO("step: " << step);
    CommandList& g0 = dev->begin_commands("hand-to-compute");
    twice(g0, pip, w);  // 1
    const std::array<QueueHandoff, 1> toCompute{hand_buffer(w.buffer, QueueKind::Compute)};
    const SyncToken t0 = dev->submit_token(g0, toCompute);
    CommandList& c = dev->begin_commands("compute-twice", QueueKind::Compute);
    dev->wait_list(c, t0);
    twice(c, pip, w);  // 3
    twice(c, pip, w);  // 7
    const std::array<QueueHandoff, 1> toGraphics{hand_buffer(w.buffer, QueueKind::Graphics)};
    const SyncToken t1 = dev->submit_token(c, toGraphics);
    CHECK(t1.queue == QueueKind::Compute);
    CommandList& g1 = dev->begin_commands("graphics-again");
    dev->wait_list(g1, t1);
    twice(g1, pip, w);  // 15
    dev->submit(g1);
    dev->commit();
    auto r = dev->wait_idle();
    REQUIRE_MESSAGE(r, r.error().to_string());
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
    CHECK(read_words(*dev, w.buffer) == std::vector<std::uint32_t>(64, 15u));

    step = "a compute list that uses a graphics buffer is dropped, naming the buffer and the fix";
    CommandList& wrong = dev->begin_commands("no-handoff", QueueKind::Compute);
    twice(wrong, pip, w);
    dev->submit(wrong);
    const std::string e = last_error(*dev);
    CHECK_MESSAGE(contains(e, "buffer 'handed-words'"), e);
    CHECK_MESSAGE(contains(e, "which the graphics queue owns"), e);
    CHECK_MESSAGE(contains(e, "QueueHandoff{..., QueueKind::Compute}"), e);
    dev->commit();
    r = dev->wait_idle();
    REQUIRE_MESSAGE(r, r.error().to_string());
    CHECK(read_words(*dev, w.buffer) == std::vector<std::uint32_t>(64, 15u));  // it did not run

    step = "a handoff the consumer did not wait for is waited for, and reported";
    dev->clear_messages();
    CommandList& g2 = dev->begin_commands("hand-again");
    (void)dev->submit_token(g2, toCompute);
    CommandList& c2 = dev->begin_commands("forgot-to-wait", QueueKind::Compute);
    twice(c2, pip, w);  // 31
    dev->submit(c2);
    const std::string missed = last_error(*dev);
    CHECK_MESSAGE(contains(missed, "without waiting for that handoff's token"), missed);
    dev->commit();
    r = dev->wait_idle();
    REQUIRE_MESSAGE(r, r.error().to_string());
    // Read back while the compute queue owns it: the readback waits for that queue.
    CHECK(read_words(*dev, w.buffer) == std::vector<std::uint32_t>(64, 31u));
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

TEST_CASE("d3d12: a texture written by a compute list is sampled by a graphics list after its handoff") {
    auto dev = make_warp();
    if (!dev) return;
    const Pipeline gradient = make_compute_pipeline(*dev, kGradientCs, true, "gradient");
    REQUIRE_MESSAGE(dev->state(gradient) == ResourceState::Valid, all_errors(*dev));
    ShaderDesc sd;
    sd.vertexFunc.source = kPlainVs;
    sd.fragmentFunc.source = kLoadFs;
    sd.views[0].texture.stage = ShaderStage::Fragment;
    sd.views[0].texture.imageType = ImageType::Tex2d;
    sd.views[0].texture.sampleType = ImageSampleType::UnfilterableFloat;
    sd.label = "load";
    const Pipeline load = dev->make_pipeline(render_desc(dev->make_shader(sd), PixelFormat::Rgba8));
    REQUIRE_MESSAGE(dev->state(load) == ResourceState::Valid, all_errors(*dev));
    ImageDesc id;
    id.width = 8;
    id.height = 8;
    id.pixelFormat = PixelFormat::Rgba8;
    id.usage.storageImage = true;
    id.label = "compute-written";
    const Image img = dev->make_image(id);
    ViewDesc sv;
    sv.storageImage.image = img;
    ViewDesc tv;
    tv.texture.image = img;
    Bindings write;
    write.views[0] = dev->make_view(sv);
    Bindings read;
    read.views[0] = dev->make_view(tv);
    REQUIRE_MESSAGE(dev->state(read.views[0]) == ResourceState::Valid, all_errors(*dev));
    const Target out = make_target(*dev, Attach::Color, 8, 8, PixelFormat::Rgba8);

    for (int frame = 0; frame < 3; ++frame) {  // and back each frame, as a renderer's HiZ goes
        INFO("frame " << frame);
        CommandList& g0 = dev->begin_commands("hand-image-to-compute");
        const std::array<QueueHandoff, 1> toCompute{hand_image(img, QueueKind::Compute)};
        const SyncToken t0 = dev->submit_token(g0, toCompute);
        CommandList& c = dev->begin_commands("gradient", QueueKind::Compute);
        dev->wait_list(c, t0);
        c.begin_compute_pass("gradient");
        c.set_pipeline(gradient);
        c.set_bindings(write);
        c.dispatch(1, 1, 1);
        c.end_pass();
        const std::array<QueueHandoff, 1> toGraphics{hand_image(img, QueueKind::Graphics)};
        const SyncToken t1 = dev->submit_token(c, toGraphics);
        CommandList& g1 = dev->begin_commands("sample");
        dev->wait_list(g1, t1);
        g1.begin_pass(color_pass(out, PixelFormat::Rgba8, Color{0.0f, 0.0f, 1.0f, 1.0f}));
        g1.set_pipeline(load);
        g1.set_bindings(read);
        g1.draw(0, 3);
        g1.end_pass();
        dev->submit(g1);
        dev->commit();
    }
    auto r = dev->wait_idle();
    REQUIRE_MESSAGE(r, r.error().to_string());
    const std::string bad = first_mismatch(read_rgba8(*dev, out.image, 8, 8), 8, 8, 0,
                                           [](int x, int y) { return std::array<int, 4>{x * 32, y * 32, 0, 255}; });
    CHECK_MESSAGE(bad.empty(), bad);
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
}

TEST_CASE("d3d12: two threads record lists while the render thread destroys unrelated resources") {
    // Robustness, not allowed use: docs/design/ARCHITECTURE_THREADS.md keeps resource creation and destruction on the
    // render thread while other threads record. This checks that the deferred destruction of the backend (a resource
    // lives until its frame is done) and the locks around the shared state survive that misuse without an error.
    auto dev = make_warp();
    if (!dev) return;
    const Pipeline pip = make_compute_pipeline(*dev, kTwiceCs, false, "twice");
    REQUIRE_MESSAGE(dev->state(pip) == ResourceState::Valid, all_errors(*dev));
    const Words a = make_words(*dev, "graphics-words");
    const Words b = make_words(*dev, "compute-words");
    CommandList& hand = dev->begin_commands("hand-b-to-compute");
    const std::array<QueueHandoff, 1> toCompute{hand_buffer(b.buffer, QueueKind::Compute)};
    const SyncToken handed = dev->submit_token(hand, toCompute);
    // Unrelated resources (each a buffer, a texture and their views) the render thread destroys meanwhile.
    std::vector<Words> spare;
    std::vector<View> textures;
    for (int i = 0; i < 48; ++i) {
        spare.push_back(make_words(*dev, "spare"));
        textures.push_back(make_texture(*dev, 2, 2, pattern(16, std::uint32_t(i))));
    }
    REQUIRE_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
    constexpr int kLists = 8;  // per thread: words end at 2^8 - 1
    std::array<std::vector<CommandList*>, 2> lists;
    std::atomic<int> started{0};
    auto record = [&](int who) {
        started.fetch_add(1);
        const Words& w = who == 0 ? a : b;
        for (int i = 0; i < kLists; ++i) {
            CommandList& l = dev->begin_commands(who == 0 ? "graphics-worker" : "compute-worker",
                                                 who == 0 ? QueueKind::Graphics : QueueKind::Compute);
            if (who == 1 && i == 0) dev->wait_list(l, handed);
            twice(l, pip, w);
            lists[std::size_t(who)].push_back(&l);
        }
    };
    std::thread t0(record, 0);
    std::thread t1(record, 1);
    while (started.load() < 2) std::this_thread::yield();
    for (std::size_t i = 0; i < spare.size(); ++i) {
        dev->destroy_view(spare[i].view);
        dev->destroy_buffer(spare[i].buffer);
        dev->destroy_view(textures[i]);
    }
    t0.join();
    t1.join();
    for (const auto& per : lists)
        for (CommandList* l : per) dev->submit(*l);  // a fixed order after the join
    dev->commit();
    auto r = dev->wait_idle();
    REQUIRE_MESSAGE(r, r.error().to_string());
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
    CHECK(read_words(*dev, a.buffer) == std::vector<std::uint32_t>(64, 255u));
    CHECK(read_words(*dev, b.buffer) == std::vector<std::uint32_t>(64, 255u));
}

TEST_CASE("d3d12: every live texture view has its own bindless slot, which a shader reads and a new view reuses") {
    auto dev = make_warp();
    if (!dev) return;
    if (!dev->features().bindless) {
        MESSAGE("d3d12: skipped, resource binding tier 1 has no bindless table");
        return;
    }
    const View red = make_texture(*dev, 1, 1, {255, 0, 0, 255});
    const View green = make_texture(*dev, 1, 1, {0, 255, 0, 255});
    const View blue = make_texture(*dev, 1, 1, {0, 0, 255, 255});
    const std::uint32_t r = dev->bindless_index(red), g = dev->bindless_index(green), b = dev->bindless_index(blue);
    CHECK(r != kNoBindlessIndex);
    CHECK(g != kNoBindlessIndex);
    CHECK(b != kNoBindlessIndex);
    CHECK(r != g);
    CHECK(g != b);
    CHECK(r != b);
    CHECK(r < dev->bindless_descriptors());
    CHECK(dev->bindless_index(red) == r);  // never changes for a live view
    const Words words = make_words(*dev, "not-a-texture");
    CHECK(dev->bindless_index(words.view) == kNoBindlessIndex);
    CHECK(dev->bindless_index(View{}) == kNoBindlessIndex);

    ShaderDesc sd;
    sd.vertexFunc.source = kPlainVs;
    sd.fragmentFunc.source = kBindlessFs;
    sd.uniformBlocks[0].stage = ShaderStage::Fragment;
    sd.uniformBlocks[0].size = 16;
    sd.label = "bindless";
    const Pipeline pip = dev->make_pipeline(render_desc(dev->make_shader(sd), PixelFormat::Rgba8));
    REQUIRE_MESSAGE(dev->state(pip) == ResourceState::Valid, all_errors(*dev));
    const Target out = make_target(*dev, Attach::Color, 2, 2, PixelFormat::Rgba8);
    auto draw_pick = [&](std::uint32_t index) {
        const std::uint32_t pick[4] = {index, 0, 0, 0};
        CommandList& l = dev->begin_commands("bindless-draw");
        l.begin_pass(color_pass(out, PixelFormat::Rgba8, Color{}));
        l.set_pipeline(pip);
        l.set_uniforms(0, Range{pick, sizeof pick});
        l.draw(0, 3);
        l.end_pass();
        submit_and_finish(*dev, l);
        return read_rgba8(*dev, out.image, 2, 2);
    };
    auto all = [](int cr, int cg, int cb) { return [=](int, int) { return std::array<int, 4>{cr, cg, cb, 255}; }; };
    std::string bad = first_mismatch(draw_pick(g), 2, 2, 0, all(0, 255, 0));
    CHECK_MESSAGE(bad.empty(), bad);
    bad = first_mismatch(draw_pick(b), 2, 2, 0, all(0, 0, 255));
    CHECK_MESSAGE(bad.empty(), bad);

    dev->destroy_view(green);
    CHECK(dev->bindless_index(green) == kNoBindlessIndex);
    for (int i = 0; i < kInflightFrames + 1; ++i) dev->commit();  // the slot goes back once its frames are done
    auto w = dev->wait_idle();
    REQUIRE_MESSAGE(w, w.error().to_string());
    const View white = make_texture(*dev, 1, 1, {255, 255, 255, 255});
    CHECK(dev->bindless_index(white) == g);
    bad = first_mismatch(draw_pick(g), 2, 2, 0, all(255, 255, 255));
    CHECK_MESSAGE(bad.empty(), bad);
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
}

TEST_CASE("d3d12: a timed scope on a copy list is ignored; graphics and compute scopes are measured") {
    auto dev = make_warp();
    if (!dev) return;
    std::string why;
    if (!dev->timer_supported(&why)) {
        MESSAGE("d3d12: skipped, this queue cannot time: " << why);
        return;
    }
    const Pipeline pip = make_compute_pipeline(*dev, kTwiceCs, false, "twice");
    REQUIRE_MESSAGE(dev->state(pip) == ResourceState::Valid, all_errors(*dev));
    const Words w = make_words(*dev, "timed-words");
    const Target t = make_target(*dev, Attach::Color, 4, 4, PixelFormat::Rgba8);
    std::vector<double> frames;
    dev->timer_begin_frame();
    CommandList& g = dev->begin_commands("graphics");
    g.begin_timed_scope("graphics-scope");
    g.begin_pass(color_pass(t, PixelFormat::Rgba8, Color{0.0f, 0.0f, 0.0f, 1.0f}));
    g.end_pass();
    g.end_timed_scope();
    const std::array<QueueHandoff, 1> toTransfer{hand_buffer(w.buffer, QueueKind::Transfer)};
    const SyncToken t0 = dev->submit_token(g, toTransfer);
    CommandList& copy = dev->begin_commands("copy", QueueKind::Transfer);
    REQUIRE(copy.queue() == QueueKind::Transfer);  // WARP has a copy queue
    dev->wait_list(copy, t0);
    copy.begin_timed_scope("copy-scope");
    const std::vector<std::uint32_t> ones(64, 1u);
    BufferWrite bw;
    bw.buffer = w.buffer;
    bw.data = Range{ones.data(), ones.size() * 4};
    copy.write_buffer(bw);
    copy.end_timed_scope();
    const std::array<QueueHandoff, 1> toCompute{hand_buffer(w.buffer, QueueKind::Compute)};
    const SyncToken t1 = dev->submit_token(copy, toCompute);
    CommandList& c = dev->begin_commands("compute", QueueKind::Compute);
    dev->wait_list(c, t1);
    c.begin_timed_scope("compute-scope");
    twice(c, pip, w);  // 3
    c.end_timed_scope();
    dev->submit(c);
    dev->timer_end_frame();
    dev->commit();
    auto r = dev->wait_idle();
    REQUIRE_MESSAGE(r, r.error().to_string());
    dev->timer_poll(frames);
    CHECK(frames.size() == 1);
    std::vector<std::string> names;
    for (const Device::ScopeTime& s : dev->timer_last_scopes()) names.push_back(s.name);
    CHECK(std::find(names.begin(), names.end(), "copy-scope") == names.end());
    CHECK(std::find(names.begin(), names.end(), "graphics-scope") != names.end());
    if (dev->compute_timestamp_frequency() > 0)
        CHECK(std::find(names.begin(), names.end(), "compute-scope") != names.end());
    CHECK(read_words(*dev, w.buffer) == std::vector<std::uint32_t>(64, 3u));
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
}

// ---- the swapchain (M77-P9c) -----------------------------------------------------------------------------------------

namespace {

// A hidden top-level Win32 window of `width` x `height` client pixels (never shown: no taskbar entry, no focus),
// destroyed with the object. hwnd is null when Windows could not make it.
struct HiddenWindow {
    HWND hwnd = nullptr;
    HiddenWindow(int width, int height) {
        static const wchar_t* const kClass = L"FactoriaD3d12SwapchainTest";
        static const bool registered = [] {
            WNDCLASSEXW wc{};
            wc.cbSize = sizeof wc;
            wc.lpfnWndProc = DefWindowProcW;
            wc.hInstance = GetModuleHandleW(nullptr);
            wc.lpszClassName = kClass;
            return RegisterClassExW(&wc) != 0 || GetLastError() == ERROR_CLASS_ALREADY_EXISTS;
        }();
        if (!registered) return;
        RECT r{0, 0, width, height};
        AdjustWindowRect(&r, WS_OVERLAPPEDWINDOW, FALSE);
        hwnd =
            CreateWindowExW(0, kClass, L"fa d3d12 swapchain test", WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT,
                            r.right - r.left, r.bottom - r.top, nullptr, nullptr, GetModuleHandleW(nullptr), nullptr);
    }
    ~HiddenWindow() {
        if (hwnd) DestroyWindow(hwnd);
    }
    HiddenWindow(const HiddenWindow&) = delete;
    HiddenWindow& operator=(const HiddenWindow&) = delete;
};

// One frame into the window: acquire, a pass that clears colour and depth to `clear`, submit, commit; `px` gets the
// back buffer read back before present (RGBA order). Returns the acquired Swapchain.
Swapchain swapchain_frame(D3d12Device& dev, Color clear, std::vector<std::uint8_t>& px) {
    auto sc = dev.acquire_swapchain(Swapchain{});
    REQUIRE_MESSAGE(sc, sc.error().to_string());
    PassDesc p = PassDesc::for_swapchain(sc.value(), dev.environment_defaults());
    p.label = "window";
    p.colorLoad = LoadAction::Clear;
    p.clearColor = clear;
    p.depthLoad = LoadAction::Clear;
    p.stencilLoad = LoadAction::Clear;
    CommandList& list = dev.begin_commands("frame");
    list.begin_pass(p);
    list.end_pass();
    dev.submit(list);
    dev.commit();
    const Image back = dev.swapchain_image();
    REQUIRE(back.id != 0);
    px.clear();
    auto r = dev.read_image_rgba8(back, sc.value().width, sc.value().height, px);
    REQUIRE_MESSAGE(r, r.error().to_string());
    auto shown = dev.present();
    REQUIRE_MESSAGE(shown, shown.error().to_string());
    CHECK(dev.swapchain_image().id == 0);  // present ends the frame
    return sc.value();
}

}  // namespace

TEST_CASE("d3d12: a swapchain on a hidden window clears, presents, resizes and is destroyed") {
    auto dev = make_warp();
    if (!dev) return;
    HiddenWindow win(64, 48);
    if (!win.hwnd) {
        MESSAGE("d3d12: skipped, Windows made no window (error " << GetLastError() << ")");
        return;
    }
    CHECK(!dev->has_swapchain());
    SwapchainDesc d;
    d.nativeWindow = win.hwnd;
    d.vsync = false;  // a hidden window is never shown: no reason to wait for a refresh
    d.label = "test-window";
    auto made = dev->create_swapchain(d);
    REQUIRE_MESSAGE(made, made.error().to_string());
    CHECK(dev->has_swapchain());
    CHECK(dev->swapchain_buffer_count() >= 2);
    INFO("buffers " << dev->swapchain_buffer_count() << ", tearing " << dev->swapchain_tearing());

    SUBCASE("three frames, a resize, a frame") {
        std::vector<std::uint8_t> px;
        const Color colors[3] = {{1.0f, 0.25f, 0.0f, 1.0f}, {0.0f, 1.0f, 0.5f, 1.0f}, {0.0f, 0.0f, 1.0f, 1.0f}};
        const std::array<int, 4> want[3] = {{255, 64, 0, 255}, {0, 255, 128, 255}, {0, 0, 255, 255}};
        for (int f = 0; f < 3; ++f) {
            INFO("frame " << f);
            const Swapchain sc = swapchain_frame(*dev, colors[f], px);
            CHECK(sc.width == 64);  // 0 x 0 in the desc: the window's client size
            CHECK(sc.height == 48);
            CHECK(sc.colorFormat == PixelFormat::Bgra8);
            const std::string bad = first_mismatch(px, sc.width, sc.height, 1, [&](int, int) { return want[f]; });
            CHECK_MESSAGE(bad.empty(), bad);
        }
        auto resized = dev->resize_swapchain(96, 64);
        REQUIRE_MESSAGE(resized, resized.error().to_string());
        const Swapchain sc = swapchain_frame(*dev, colors[1], px);
        CHECK(sc.width == 96);
        CHECK(sc.height == 64);
        const std::string bad = first_mismatch(px, 96, 64, 1, [&](int, int) { return want[1]; });
        CHECK_MESSAGE(bad.empty(), bad);
        auto same = dev->resize_swapchain(96, 64);  // the same size: nothing to do
        CHECK_MESSAGE(same, same.error().to_string());
    }
    SUBCASE("mistakes are teaching errors") {
        auto early = dev->present();
        REQUIRE(!early);
        CHECK(contains(early.error().message, "without this frame's acquire_swapchain()"));
        auto twice = dev->create_swapchain(d);
        REQUIRE(!twice);
        CHECK(contains(twice.error().message, "has a swapchain already"));
        auto sc = dev->acquire_swapchain(Swapchain{});
        REQUIRE_MESSAGE(sc, sc.error().to_string());
        auto mid = dev->resize_swapchain(32, 32);
        REQUIRE(!mid);
        CHECK(contains(mid.error().message, "between acquire_swapchain() and present()"));
        Swapchain stale = sc.value();
        stale.width = 10;
        PassDesc p = PassDesc::for_swapchain(stale, dev->environment_defaults());
        p.label = "stale";
        p.colorLoad = LoadAction::Clear;
        CommandList& list = dev->begin_commands("stale");
        list.begin_pass(p);
        CHECK(contains(last_error(*dev), "pass 'stale': PassDesc::swapchain is 10x48"));
        list.end_pass();
        dev->submit(list);
        dev->commit();
        auto shown = dev->present();
        CHECK_MESSAGE(shown, shown.error().to_string());
    }

    dev->destroy_swapchain();
    CHECK(!dev->has_swapchain());
    CHECK(dev->swapchain_buffer_count() == 0);
    auto after = dev->acquire_swapchain(Swapchain{});
    REQUIRE(!after);
    CHECK(contains(after.error().message, "without a swapchain"));
    auto r = dev->wait_idle();
    CHECK_MESSAGE(r, r.error().to_string());
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

TEST_CASE("d3d12: create_swapchain checks its desc before any DXGI work; the format query answers HDR formats") {
    auto dev = make_warp();
    if (!dev) return;
    SwapchainDesc d;
    auto none = dev->create_swapchain(d);
    REQUIRE(!none);
    CHECK(contains(none.error().message, "SwapchainDesc::nativeWindow is null"));
    CHECK(contains(none.error().hint, "HWND"));
    CHECK(!dev->has_swapchain());

    std::string why;
    CHECK(dev->swapchain_format_supported(PixelFormat::Default, &why));
    CHECK(dev->swapchain_format_supported(PixelFormat::Bgra8, &why));
    for (const PixelFormat hdr : {PixelFormat::Rgba16F, PixelFormat::Rgb10A2}) {
        why.clear();
        const bool ok = dev->swapchain_format_supported(hdr, &why);
        INFO(pixel_format_name(hdr) << ": " << (ok ? "supported" : why));
        if (!ok) CHECK(!why.empty());
    }
    why.clear();
    CHECK(!dev->swapchain_format_supported(PixelFormat::R8, &why));
    CHECK(contains(why, "not R8"));

    HiddenWindow win(32, 32);
    if (!win.hwnd) return;
    d.nativeWindow = win.hwnd;
    d.sampleCount = 3;
    auto odd = dev->create_swapchain(d);
    REQUIRE(!odd);
    CHECK(contains(odd.error().message, "sampleCount 3"));
    d.sampleCount = 1;
    d.colorFormat = PixelFormat::R8;
    auto r8 = dev->create_swapchain(d);
    REQUIRE(!r8);
    CHECK(contains(r8.error().hint, "PixelFormat::Default"));
    CHECK(!dev->has_swapchain());

    // scRGB: a display without HDR (a CI VM) refuses the colour space (CheckColorSpaceSupport) with a teaching error;
    // either answer is fine.
    if (dev->swapchain_format_supported(PixelFormat::Rgba16F, nullptr)) {
        d.colorFormat = PixelFormat::Rgba16F;
        auto hdr = dev->create_swapchain(d);
        if (hdr) {
            CHECK(dev->has_swapchain());
            dev->destroy_swapchain();
        } else {
            MESSAGE("d3d12: scRGB swapchain refused: " << hdr.error().to_string());
            CHECK(!hdr.error().hint.empty());
            CHECK(!dev->has_swapchain());
        }
    }
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

#endif
