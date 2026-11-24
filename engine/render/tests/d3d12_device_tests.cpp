// The engine's own D3D12 backend (src/gpu/d3d12_*, M77-P7a). On Windows every case makes a WARP device with the debug
// layer and checks that the layer reported no error; a Windows without WARP or D3D12 says so (MESSAGE) and passes.
// Elsewhere one case checks the factory's teaching error.
#include <doctest.h>

#include <cstdint>
#include <cstring>
#include <memory>
#include <string>
#include <vector>

#include "gpu/d3d12_device.h"

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
    step = "timers and async reads are M77-P7c's";
    std::string why;
    CHECK(!dev->timer_supported(&why));
    CHECK(contains(why, "M77-P7c"));
    CHECK(!dev->async_read_supported());
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

TEST_CASE("d3d12: what M77-P7c builds reports a clear 'not yet' error, a list method once per device") {
    auto dev = make_warp();
    if (!dev) return;
    ShaderDesc sd;
    sd.label = "a-shader";
    const Shader s = dev->make_shader(sd);
    CHECK(!s.valid());
    CHECK(contains(all_errors(*dev), "make_shader('a-shader') is not built yet (M77-P7c)"));
    dev->clear_messages();
    CommandList& list = dev->begin_commands("not-yet");
    list.push_debug_group("group");
    PassDesc pd;
    list.begin_pass(pd);
    list.begin_pass(pd);
    list.draw(0, 3);
    list.pop_debug_group();
    dev->submit(list);
    dev->commit();
    REQUIRE(dev->wait_idle());
    int passes = 0;
    for (const std::string& e : dev->errors())
        if (contains(e, "begin_pass is not built yet (M77-P7c)")) ++passes;
    CHECK(passes == 1);
    CHECK(contains(all_errors(*dev), "draw is not built yet"));
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
    auto ticket = dev->request_buffer_read(Buffer{}, 0, 4);
    REQUIRE(!ticket);
    CHECK(contains(ticket.error().message, "M77-P7c"));
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

#endif
