// The engine's own Vulkan backend (src/gpu/vulkan_*: resources M77-P8a, shaders, pipelines and drawing M77-P8c, GPU
// timers, asynchronous reads and synchronization fixes M77-P8b1). Where the backend is built every case makes a device
// on this machine's Vulkan driver (MoltenVK on macOS; Mesa's lavapipe on the Linux CI job, which installs it with the
// validation layers) with the validation layer and its synchronization validation, and checks that the layer reported
// no error; the drawing cases draw with the SPIR-V of tests/shaders/vulkan_test.glsl (the twins of
// d3d12_device_tests.cpp's HLSL) and check their targets per texel. A machine without a Vulkan loader or device, or with
// a loader older than 1.2, says so (MESSAGE) and passes, unless FA_VULKAN_REQUIRE=1 (the Linux CI job): then a skip and
// a missing validation layer fail. Where the backend is not built (web, iOS) one case checks the factory's teaching
// error.
#include <doctest.h>

#include <algorithm>
#include <array>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <memory>
#include <string>
#include <vector>

#include "gpu/sokol_device.h"
#include "gpu/vulkan_device.h"
// The SPIR-V of the generated shader headers (sokol-shdc's spirv_vk output, compiled in where FA_SHADERS_SPIRV is set).
#define FA_SHADERS_SPIRV
#include "shaders/blit.glsl.h"
#include "shaders/vulkan_test.glsl.h"

using namespace fa::gpu;

namespace {

bool contains(const std::string& s, const std::string& part) { return s.find(part) != std::string::npos; }

}  // namespace

#if !defined(FA_VULKAN_BACKEND)

TEST_CASE("vulkan: make_vulkan_device where the backend is not built is a teaching error") {
    auto d = make_vulkan_device();
    REQUIRE(!d);
    CHECK(contains(d.error().message, "not built into this binary"));
}

#else

using fa::gpu::vk::VulkanDevice;

namespace {

// FA_VULKAN_REQUIRE=1 (the Linux CI job, which installs lavapipe and the validation layers): a machine that cannot run
// the cases fails them instead of skipping.
bool vulkan_required() {
    const char* v = std::getenv("FA_VULKAN_REQUIRE");
    return v && std::strcmp(v, "1") == 0;
}

// What a machine that cannot run the cases answers: no loader, no device, a loader older than 1.2, or a driver that
// does not start.
bool cannot_run_here(const std::string& e) {
    return contains(e, "no Vulkan loader") || contains(e, "no Vulkan device") || contains(e, "needs 1.2") ||
           contains(e, "VK_ERROR_INITIALIZATION_FAILED");
}

// A device with the validation layer and its synchronization validation, or null (with a MESSAGE) when this machine
// cannot run Vulkan (cannot_run_here). Any other failure fails the case, and so does a skip or a missing layer under
// FA_VULKAN_REQUIRE=1.
std::unique_ptr<VulkanDevice> make_vk(VulkanOptions o = {}) {
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
            FAIL("vulkan: FA_VULKAN_REQUIRE=1 but the validation layer is not installed (apt install "
                 "vulkan-validationlayers)");
            return nullptr;
        }
        MESSAGE("vulkan: the validation layer is not installed: the case runs without its checks");
    } else if (!dev->synchronization_validation_active()) {
        MESSAGE("vulkan: the validation layer has no synchronization validation: the case runs without it");
    }
    return dev;
}

// The validation layer's errors (the backend's own reports, which some cases provoke, are not counted).
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

void submit_and_finish(VulkanDevice& dev, CommandList& list) {
    dev.submit(list);
    dev.commit();
    auto r = dev.wait_idle();
    REQUIRE_MESSAGE(r, r.error().to_string());
}

// Buffers and images through a device: what the synchronization2 and the Vulkan 1.0 barrier paths must both do.
void round_trips(VulkanDevice& dev) {
    const std::vector<std::uint8_t> data = pattern(1000, 1);
    BufferDesc bd;
    bd.size = data.size();
    bd.usage.storageBuffer = true;
    bd.usage.writeTransient = true;
    bd.data = range_of(data);
    bd.label = "round-trip";
    const Buffer a = dev.make_buffer(bd);
    REQUIRE(dev.state(a) == ResourceState::Valid);
    std::vector<std::uint8_t> out;
    auto r = dev.read_buffer(a, 0, data.size(), out);
    REQUIRE_MESSAGE(r, r.error().to_string());
    CHECK(out == data);
    const std::vector<std::uint8_t> patch = pattern(100, 2);
    CommandList& list = dev.begin_commands("write");
    BufferWrite w;
    w.data = range_of(patch);
    w.buffer = a;
    w.dstOffset = 200;
    list.write_buffer(w);
    submit_and_finish(dev, list);
    std::vector<std::uint8_t> expected = data;
    std::memcpy(expected.data() + 200, patch.data(), patch.size());
    r = dev.read_buffer(a, 0, data.size(), out);
    REQUIRE_MESSAGE(r, r.error().to_string());
    CHECK(out == expected);

    ImageDesc id;
    id.width = 8;
    id.height = 4;
    id.numMipmaps = 2;
    id.pixelFormat = PixelFormat::Rgba8;
    id.usage.writeTransient = true;
    const std::vector<std::uint8_t> m0 = pattern(8 * 4 * 4, 3), m1 = pattern(4 * 2 * 4, 4);
    id.data.mipLevels[0] = range_of(m0);
    id.data.mipLevels[1] = range_of(m1);
    const Image img = dev.make_image(id);
    REQUIRE(dev.state(img) == ResourceState::Valid);
    r = dev.read_image_region(img, 1, 0, 0, 0, 4, 2, out);
    REQUIRE_MESSAGE(r, r.error().to_string());
    CHECK(out == m1);
    const std::vector<std::uint8_t> texels = pattern(2 * 2 * 4, 5);
    CommandList& wl = dev.begin_commands("write-image");
    ImageWrite iw;
    iw.data = range_of(texels);
    iw.dst.image = img;
    iw.dst.x = 3;
    iw.dst.y = 1;
    iw.size.width = 2;
    iw.size.height = 2;
    iw.bytesPerRow = 8;
    wl.write_image(iw);
    submit_and_finish(dev, wl);
    r = dev.read_image_region(img, 0, 0, 3, 1, 2, 2, out);
    REQUIRE_MESSAGE(r, r.error().to_string());
    CHECK(out == texels);
    r = dev.read_image_rgba8(img, 8, 4, out);
    REQUIRE(r);
    std::vector<std::uint8_t> whole = m0;
    for (int row = 0; row < 2; ++row)
        std::memcpy(whole.data() + (std::size_t(row + 1) * 8 + 3) * 4, texels.data() + std::size_t(row) * 8, 8);
    CHECK(out == whole);
    dev.destroy_buffer(a);
    dev.destroy_image(img);
}

}  // namespace

TEST_CASE("vulkan: VulkanOptions contradictions are errors before any Vulkan work") {
    VulkanOptions o;
    o.framesInFlight = 0;
    auto a = make_vulkan_device(o);
    REQUIRE(!a);
    CHECK(contains(a.error().message, "framesInFlight"));
    o = {};
    o.uploadRingBytes = 1024;
    auto b = make_vulkan_device(o);
    REQUIRE(!b);
    CHECK(contains(b.error().message, "uploadRingBytes"));
    o = {};
    o.dedicatedThreshold = o.memoryBlockBytes + 1;
    auto c = make_vulkan_device(o);
    REQUIRE(!c);
    CHECK(contains(c.error().message, "dedicatedThreshold"));
    o = {};
    o.bindlessDescriptors = -1;
    auto e = make_vulkan_device(o);
    REQUIRE(!e);
    CHECK(contains(e.error().message, "bindlessDescriptors is -1"));
    o = {};
    o.frameDescriptors = 2000000;
    auto f = make_vulkan_device(o);
    REQUIRE(!f);
    CHECK(contains(f.error().message, "frameDescriptors"));
}

TEST_CASE("vulkan: a loaderPath that names no loader is a teaching error") {
    VulkanOptions o;
    o.loaderPath = "no-such-dir/not-a-vulkan-loader.lib";
    auto d = make_vulkan_device(o);
    REQUIRE(!d);
    CHECK(contains(d.error().message, "no Vulkan loader found"));
    CHECK(contains(d.error().message, "not-a-vulkan-loader.lib"));
    CHECK(contains(d.error().hint, "loaderPath"));
}

TEST_CASE("vulkan: a device answers what it can do") {
    auto dev = make_vk();
    if (!dev) return;
    std::string step = "info";
    INFO("step: " << step);
    MESSAGE(
        "vulkan: " << dev->device_name() << ", loader " << dev->loader_path()
                   << std::string(dev->synchronization2_active() ? ", synchronization2" : "")
                   << std::string(dev->portability_subset() ? ", portability subset" : "")
                   << std::string(dev->validation_active() ? ", validation layer" : "")
                   << std::string(dev->synchronization_validation_active() ? " with synchronization validation" : ""));
    CHECK(dev->backend() == Backend::Vulkan);
    CHECK(std::string(dev->info().name) == backend_name(Backend::Vulkan));
    CHECK(!dev->device_name().empty());
    CHECK(!dev->loader_path().empty());
    CHECK(dev->api_version() >= VK_API_VERSION_1_2);
    CHECK(dev->frames_in_flight() == kInflightFrames);
    CHECK(dev->features().compute);
    CHECK(dev->features().originTopLeft);
    CHECK(dev->limits().maxImageSize2d >= 4096);
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
    CHECK(dev->pixel_format_caps(PixelFormat::Rgba16F).sample);
    CHECK(dev->pixel_format_caps(PixelFormat::R32F).write);
    CHECK(!dev->pixel_format_caps(PixelFormat::Count).sample);
    step = "natives";
    CHECK(dev->native().device == static_cast<const void*>(dev->vk_device()));
    CHECK(dev->native().context == static_cast<const void*>(dev->queue()));
    CHECK(dev->native_metal() == nullptr);
    CHECK(dev->environment_defaults().colorFormat == PixelFormat::Bgra8);
    CHECK(dev->environment_defaults().depthFormat == PixelFormat::DepthStencil);
    CHECK(dev->vk_format(PixelFormat::DepthStencil) != VK_FORMAT_UNDEFINED);
    step = "timers (where the queue has timestamps, or a reason) and async reads";
    std::string why;
    if (!dev->timer_supported(&why)) CHECK_MESSAGE(contains(why, "timestamp"), why);
    CHECK(dev->async_read_supported());
    step = "the validation layer said nothing";
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
}

TEST_CASE("vulkan: buffers round-trip through make_buffer, write_buffer and copy_buffer_to_buffer") {
    auto dev = make_vk();
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
#if VK_USE_64_BIT_PTR_DEFINES == 1
    CHECK(dev->native_buffer(a).buffer != nullptr);
#endif
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
    auto past = dev->read_buffer(a, 990, 20, out);
    REQUIRE(!past);
    CHECK(contains(past.error().message, "go past its 1000 bytes"));

    step = "two lists of one frame: the second, recorded first, copies what the first writes";
    // The fix-up barriers move `a` from the transfer write (list 1's end) to the transfer read (list 2's start).
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
    CHECK(dev->counters().barriers > 0);
    dev->destroy_buffer(a);
    dev->destroy_buffer(b);
    CHECK(dev->state(a) == ResourceState::Invalid);
    step = "the validation layer said nothing";
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

TEST_CASE("vulkan: RGBA8 and RGBA16F images with mips round-trip, and write_image lands in one mip") {
    auto dev = make_vk();
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
#if VK_USE_64_BIT_PTR_DEFINES == 1
    CHECK(dev->native_image(img).texture != nullptr);
#endif
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
    auto outside = dev->read_image_region(img, 1, 0, 6, 0, 4, 1, out);
    REQUIRE(!outside);
    CHECK(contains(outside.error().message, "is empty or outside its 8x4 mip 1"));

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
    auto wrongFormat = dev->read_image_rgba8(himg, 8, 8, out);
    REQUIRE(!wrongFormat);
    CHECK(contains(wrongFormat.error().hint, "read_image_rgba16f"));

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

    step = "a cube and a 3D image: faces and depth slices keep their own data";
    ImageDesc cube;
    cube.type = ImageType::Cube;
    cube.width = 4;
    cube.height = 4;
    cube.numSlices = 6;
    const std::vector<std::uint8_t> faces = pattern(4 * 4 * 4 * 6, 31);
    cube.data.mipLevels[0] = range_of(faces);
    const Image cimg = dev->make_image(cube);
    REQUIRE(dev->state(cimg) == ResourceState::Valid);
    r = dev->read_image_region(cimg, 0, 5, 0, 0, 4, 4, out);
    REQUIRE_MESSAGE(r, r.error().to_string());
    CHECK(out == std::vector<std::uint8_t>(faces.begin() + 64 * 5, faces.end()));
    ImageDesc vol;
    vol.type = ImageType::Tex3d;
    vol.width = 4;
    vol.height = 2;
    vol.numSlices = 3;
    vol.usage.writeTransient = true;
    const std::vector<std::uint8_t> slices = pattern(4 * 2 * 4 * 3, 32);
    vol.data.mipLevels[0] = range_of(slices);
    const Image vimg = dev->make_image(vol);
    REQUIRE(dev->state(vimg) == ResourceState::Valid);
    r = dev->read_image_region(vimg, 0, 1, 0, 0, 4, 2, out);
    REQUIRE_MESSAGE(r, r.error().to_string());
    CHECK(out == std::vector<std::uint8_t>(slices.begin() + 32, slices.begin() + 64));
    const std::vector<std::uint8_t> slice2 = pattern(4 * 2 * 4, 33);
    CommandList& vl = dev->begin_commands("write-3d");
    ImageWrite vw;
    vw.data = range_of(slice2);
    vw.dst.image = vimg;
    vw.dst.slice = 2;
    vw.size.numSlices = 1;
    vl.write_image(vw);
    submit_and_finish(*dev, vl);
    r = dev->read_image_region(vimg, 0, 2, 0, 0, 4, 2, out);
    REQUIRE_MESSAGE(r, r.error().to_string());
    CHECK(out == slice2);

    step = "views of every kind";
    ViewDesc vd;
    vd.texture.image = img;
    vd.texture.mipLevels = {1, 2};
    CHECK(dev->state(dev->make_view(vd)) == ResourceState::Valid);
    ViewDesc av;
    av.texture.image = aimg;
    av.texture.slices = {1, 2};
    CHECK(dev->state(dev->make_view(av)) == ResourceState::Valid);
    ViewDesc cuv;
    cuv.texture.image = cimg;
    CHECK(dev->state(dev->make_view(cuv)) == ResourceState::Valid);
    ViewDesc v3;
    v3.texture.image = vimg;
    CHECK(dev->state(dev->make_view(v3)) == ResourceState::Valid);
    ViewDesc sv;
    sv.storageImage.image = aimg;
    sv.storageImage.slice = 1;
    CHECK(dev->state(dev->make_view(sv)) == ResourceState::Valid);
    BufferDesc sbd;
    sbd.size = 1024;
    sbd.usage.storageBuffer = true;
    const Buffer sb = dev->make_buffer(sbd);
    REQUIRE(dev->state(sb) == ResourceState::Valid);
    ViewDesc bv;
    bv.storageBuffer.buffer = sb;
    bv.storageBuffer.offset = 256;
    CHECK(dev->state(dev->make_view(bv)) == ResourceState::Valid);
    ImageDesc rt;
    rt.width = 8;
    rt.height = 8;
    rt.usage.colorAttachment = true;
    rt.usage.resolveAttachment = true;
    const Image rimg = dev->make_image(rt);
    REQUIRE(dev->state(rimg) == ResourceState::Valid);
    ViewDesc cv;
    cv.colorAttachment.image = rimg;
    CHECK(dev->state(dev->make_view(cv)) == ResourceState::Valid);
    ViewDesc rv;
    rv.resolveAttachment.image = rimg;
    CHECK(dev->state(dev->make_view(rv)) == ResourceState::Valid);
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
    auto msaa = dev->read_image_region(dimg, 0, 0, 0, 0, 8, 8, out);
    REQUIRE(!msaa);
    CHECK(contains(msaa.error().message, "multisampled"));
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

    step = "the validation layer said nothing";
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

TEST_CASE("vulkan: copy_buffer_to_image with aligned rows and with rows that need repacking") {
    auto dev = make_vk();
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

    step = "unaligned: a 5x3 region of 30-byte rows from offset 2, into (2, 1) of mip 0";
    ImageDesc sd;
    sd.width = 8;
    sd.height = 4;
    sd.usage.copyDst = true;
    const Image small = dev->make_image(sd);
    REQUIRE(dev->state(small) == ResourceState::Valid);
    const std::uint32_t liveBefore = dev->counters().memory.liveAllocations;
    CommandList& list2 = dev->begin_commands("unaligned");
    BufferImageCopy u;
    u.src = buf;
    u.srcOffset = 2;
    u.bytesPerRow = 30;
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
        expected.insert(expected.end(), src.begin() + 2 + row * 30, src.begin() + 2 + row * 30 + 20);
    CHECK(out == expected);
    CHECK(dev->counters().memory.liveAllocations == liveBefore);  // the repack buffer went with its frame

    step = "a region past the buffer's end is a teaching error";
    CommandList& list3 = dev->begin_commands("past-end");
    u.srcOffset = src.size() - 8;
    list3.copy_buffer_to_image(u);
    submit_and_finish(*dev, list3);
    CHECK(contains(all_errors(*dev), "copy_buffer_to_image"));

    step = "the validation layer said nothing";
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

TEST_CASE("vulkan: a resource destroyed while the GPU may use it is released once its frame is done") {
    auto dev = make_vk();
    if (!dev) return;
    std::string step = "make and use a buffer";
    INFO("step: " << step);
    const std::uint32_t liveBefore = dev->counters().memory.liveAllocations;
    BufferDesc bd;
    bd.size = 4096;
    bd.usage.writeTransient = true;
    const Buffer b = dev->make_buffer(bd);
    REQUIRE(dev->state(b) == ResourceState::Valid);
    CHECK(dev->counters().memory.liveAllocations == liveBefore + 1);

    CommandList& list = dev->begin_commands("use");
    const std::vector<std::uint8_t> data = pattern(4096, 50);
    BufferWrite w;
    w.data = range_of(data);
    w.buffer = b;
    list.write_buffer(w);
    dev->submit(list);

    step = "destroyed before commit: the handle is gone, the memory is not";
    dev->destroy_buffer(b);
    CHECK(dev->state(b) == ResourceState::Invalid);
    CHECK(dev->counters().pendingReleases >= 1);
    CHECK(dev->counters().memory.liveAllocations == liveBefore + 1);

    step = "destroying it again is reported";
    dev->destroy_buffer(b);
    CHECK(contains(all_errors(*dev), "names nothing"));

    step = "after the frame's timeline value the device let go";
    dev->commit();
    REQUIRE(dev->wait_idle());
    CHECK(dev->counters().pendingReleases == 0);
    CHECK(dev->counters().memory.liveAllocations == liveBefore);

    step = "the validation layer said nothing";
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

TEST_CASE("vulkan: wait_idle releases what the current frame destroyed, without a commit") {
    auto dev = make_vk();
    if (!dev) return;
    std::string step = "make a buffer and an image with data";
    INFO("step: " << step);
    REQUIRE(dev->wait_idle());
    const std::uint32_t liveBefore = dev->counters().memory.liveAllocations;
    const std::vector<std::uint8_t> data = pattern(4096, 7);
    BufferDesc bd;
    bd.size = 4096;
    bd.data = range_of(data);
    const Buffer b = dev->make_buffer(bd);
    REQUIRE(dev->state(b) == ResourceState::Valid);
    ImageDesc id;
    id.width = 32;
    id.height = 32;
    id.pixelFormat = PixelFormat::Rgba8;
    id.data.mipLevels[0] = range_of(data);
    const Image im = dev->make_image(id);
    REQUIRE(dev->state(im) == ResourceState::Valid);
    CHECK(dev->counters().memory.liveAllocations > liveBefore);

    step = "destroyed in this frame, then wait_idle (no commit): nothing stays pending";
    dev->destroy_buffer(b);
    dev->destroy_image(im);
    CHECK(dev->counters().pendingReleases >= 2);
    REQUIRE(dev->wait_idle());
    CHECK(dev->counters().pendingReleases == 0);
    CHECK(dev->counters().memory.liveAllocations == liveBefore);

    step = "the device still works";
    round_trips(*dev);

    step = "the validation layer said nothing";
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

TEST_CASE("vulkan: the upload ring wraps, and an upload that does not fit takes a buffer of its own") {
    VulkanOptions o;
    o.uploadRingBytes = 64 * 1024;
    auto dev = make_vk(o);
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

    step = "the validation layer said nothing";
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

TEST_CASE("vulkan: a full frame descriptor pool fails with a teaching error and is empty again two frames later") {
    VulkanOptions o;
    o.frameDescriptorSets = 2;
    o.frameDescriptors = 3;
    o.bindlessDescriptors = 4;
    auto dev = make_vk(o);
    if (!dev) return;
    std::string step = "a layout of two sampled images";
    INFO("step: " << step);
    const vk::VkFunctions& f = dev->fn();
    VkDescriptorSetLayoutBinding binding{};
    binding.binding = 0;
    binding.descriptorType = VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE;
    binding.descriptorCount = 2;
    binding.stageFlags = VK_SHADER_STAGE_FRAGMENT_BIT;
    VkDescriptorSetLayoutCreateInfo li{};
    li.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
    li.bindingCount = 1;
    li.pBindings = &binding;
    VkDescriptorSetLayout layout = VK_NULL_HANDLE;
    REQUIRE(f.vkCreateDescriptorSetLayout(dev->vk_device(), &li, nullptr, &layout) == VK_SUCCESS);
    vk::DescriptorCounts two;
    two.n[vk::kDescSampledImage] = 2;

    step = "the first set fits, the second has no room for two more descriptors, an empty one takes the last set";
    auto a = dev->descriptors().alloc(layout, two);
    REQUIRE_MESSAGE(a, a.error().to_string());
    auto b = dev->descriptors().alloc(layout, two);
    REQUIRE(!b);
    CHECK(contains(b.error().message, "no room for 2 more"));
    CHECK(contains(b.error().hint, "frameDescriptors"));
    CHECK(dev->counters().frameDescriptors == 2);

    step = "the next frame has a pool of its own; the frame after reuses the first, empty again";
    dev->commit();
    auto c = dev->descriptors().alloc(layout, two);
    REQUIRE_MESSAGE(c, c.error().to_string());
    dev->commit();
    CHECK(dev->counters().frameDescriptorSets == 0);
    auto d = dev->descriptors().alloc(layout, two);
    REQUIRE_MESSAGE(d, d.error().to_string());
    CHECK(dev->counters().frameDescriptorSets == 1);
    REQUIRE(dev->wait_idle());
    f.vkDestroyDescriptorSetLayout(dev->vk_device(), layout, nullptr);

    step = "the bindless table";
    if (dev->counters().bindlessCapacity == 0) {
        MESSAGE("vulkan: " << dev->device_name() << " has no bindless table (no descriptor indexing)");
    } else {
        CHECK(dev->counters().bindlessCapacity == 4);
        ImageDesc id;
        id.width = 4;
        id.height = 4;
        const Image img = dev->make_image(id);
        REQUIRE(dev->state(img) == ResourceState::Valid);
        ViewDesc vd;
        vd.texture.image = img;
        const View view = dev->make_view(vd);
        REQUIRE(dev->state(view) == ResourceState::Valid);
        std::vector<std::uint32_t> slots;
        for (int i = 0; i < 4; ++i) {
            auto s = dev->bindless_add(view);
            REQUIRE_MESSAGE(s, s.error().to_string());
            slots.push_back(s.value());
        }
        auto full = dev->bindless_add(view);
        REQUIRE(!full);
        CHECK(contains(full.error().message, "the bindless table is full (4 slots)"));
        dev->bindless_remove(slots[2]);
        CHECK(!dev->bindless_add(view));  // the frame in flight may still read the slot
        dev->commit();
        REQUIRE(dev->wait_idle());
        auto again = dev->bindless_add(view);
        REQUIRE_MESSAGE(again, again.error().to_string());
        CHECK(again.value() == slots[2]);
        CHECK(!dev->bindless_add(View{}));  // not a live texture view
    }

    step = "the validation layer said nothing";
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

// ---------------------------------------------------------------------------------------------------------------------
// Shaders, pipelines and drawing (M77-P8c)
// ---------------------------------------------------------------------------------------------------------------------

namespace {

using Vec4 = std::array<float, 4>;

Range bytes_of(const Vec4& v) { return Range{v.data(), sizeof(float) * v.size()}; }

// The test shaders' SPIR-V (tests/shaders/vulkan_test.glsl through sokol-shdc).
ShaderDesc fill_shader_desc() { return from_sg(*vktest_fill_shader_desc(SG_BACKEND_VULKAN)); }
ShaderDesc instance_shader_desc() { return from_sg(*vktest_instance_shader_desc(SG_BACKEND_VULKAN)); }
ShaderDesc two_views_shader_desc() { return from_sg(*vktest_two_views_shader_desc(SG_BACKEND_VULKAN)); }
ShaderDesc compute_shader_desc() { return from_sg(*vktest_compute_shader_desc(SG_BACKEND_VULKAN)); }
ShaderDesc sample_shader_desc() { return from_sg(*vktest_sample_shader_desc(SG_BACKEND_VULKAN)); }

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
Target make_target(VulkanDevice& dev, Attach kind, int width, int height, PixelFormat format, int samples = 1) {
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
View make_texture(VulkanDevice& dev, int width, int height, const std::vector<std::uint8_t>& texels) {
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

Sampler make_clamped_sampler(VulkanDevice& dev, Filter filter) {
    SamplerDesc sd;
    sd.minFilter = sd.magFilter = filter;
    sd.wrapU = sd.wrapV = Wrap::ClampToEdge;
    return dev.make_sampler(sd);
}

Buffer make_vertex_buffer(VulkanDevice& dev, const std::vector<float>& v) {
    BufferDesc bd;
    bd.size = v.size() * sizeof(float);
    bd.usage.vertexBuffer = true;
    bd.data = Range{v.data(), bd.size};
    bd.label = "vertices";
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

std::vector<std::uint8_t> read_rgba8(VulkanDevice& dev, Image image, int width, int height) {
    std::vector<std::uint8_t> out;
    auto r = dev.read_image_rgba8(image, width, height, out);
    REQUIRE_MESSAGE(r, r.error().to_string());
    return out;
}

// The last error the device reported (each failing call below reports one).
std::string last_error(VulkanDevice& dev) {
    const std::vector<std::string> e = dev.errors();
    return e.empty() ? std::string() : e.back();
}

}  // namespace

TEST_CASE("vulkan: a clear-only pass fills its colour attachment") {
    auto dev = make_vk();
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

TEST_CASE("vulkan: a uniform-colour fullscreen triangle fills RGBA8 and RGBA16F targets") {
    auto dev = make_vk();
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

TEST_CASE("vulkan: the engine's blit shader (sokol-shdc SPIR-V) copies a texture with a nearest and a linear sampler") {
    auto dev = make_vk();
    if (!dev) return;
    const Shader shader = dev->make_shader(from_sg(*blit_blit_keep_shader_desc(SG_BACKEND_VULKAN)));
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
    step = "the validation layer said nothing";
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
}

TEST_CASE("vulkan: an indexed instanced draw with a base vertex") {
    auto dev = make_vk();
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

TEST_CASE("vulkan: the depth test keeps the nearer draw, and a viewport limits a draw") {
    auto dev = make_vk();
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
    list.set_viewport(0, 0, 0, 8);
    fill(0.1f, Vec4{1.0f, 1.0f, 1.0f, 1.0f});  // an empty viewport: nothing drawn, no error
    list.end_pass();
    submit_and_finish(*dev, list);
    const std::string bad = first_mismatch(read_rgba8(*dev, color.image, 8, 8), 8, 8, 0, [](int x, int) {
        return x < 4 ? std::array<int, 4>{0, 0, 255, 255} : std::array<int, 4>{255, 0, 0, 255};
    });
    CHECK_MESSAGE(bad.empty(), bad);
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
}

TEST_CASE("vulkan: a scissor limits a draw, and the y axis points up as on the other backends") {
    auto dev = make_vk();
    if (!dev) return;
    const Shader shader = dev->make_shader(instance_shader_desc());
    REQUIRE_MESSAGE(dev->state(shader) == ResourceState::Valid, all_errors(*dev));
    PipelineDesc pd = render_desc(shader, PixelFormat::Rgba8);
    pd.layout.attrs[0].format = VertexFormat::Float2;
    const Pipeline pip = dev->make_pipeline(pd);
    REQUIRE_MESSAGE(dev->state(pip) == ResourceState::Valid, all_errors(*dev));
    // The upper half of clip space (y 0 to 1): the top rows of the image, row 0 first.
    const Buffer top =
        make_vertex_buffer(*dev, {-1.0f, 0.0f, 1.0f, 0.0f, 1.0f, 1.0f, -1.0f, 0.0f, 1.0f, 1.0f, -1.0f, 1.0f});
    const Target t = make_target(*dev, Attach::Color, 8, 8, PixelFormat::Rgba8);
    CommandList& list = dev->begin_commands("scissor");
    list.begin_pass(color_pass(t, PixelFormat::Rgba8, Color{0.0f, 0.0f, 0.0f, 1.0f}));
    list.set_pipeline(pip);
    Bindings b;
    b.vertexBuffers[0] = top;
    list.set_bindings(b);
    list.set_scissor(0, 0, 2, 8);  // the two left columns
    list.draw(0, 6);
    list.end_pass();
    submit_and_finish(*dev, list);
    const std::string bad = first_mismatch(read_rgba8(*dev, t.image, 8, 8), 8, 8, 0, [](int x, int y) {
        return x < 2 && y < 4 ? std::array<int, 4>{255, 0, 0, 255} : std::array<int, 4>{0, 0, 0, 255};
    });
    CHECK_MESSAGE(bad.empty(), bad);
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
}

TEST_CASE("vulkan: an MSAA 4x pass resolves into a single-sample image at end_pass") {
    auto dev = make_vk();
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

TEST_CASE("vulkan: a compute pass writes a storage image and a storage buffer, and a second dispatch reads them") {
    auto dev = make_vk();
    if (!dev) return;
    const Shader shader = dev->make_shader(compute_shader_desc());
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
    const std::int32_t write[4] = {0, 0, 0, 0};
    const std::int32_t update[4] = {1, 0, 0, 0};
    CommandList& list = dev->begin_commands("compute");
    list.begin_compute_pass("compute");
    list.set_pipeline(pip);
    list.set_bindings(b);
    list.set_uniforms(0, Range{write, sizeof write});
    list.dispatch(1, 1, 1);
    list.set_uniforms(0, Range{update, sizeof update});
    list.dispatch(1, 1, 1);  // after a barrier: it reads the words the first one wrote
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

TEST_CASE("vulkan: equal descs share a pipeline and its layouts; a layout follows sokol-shdc's sets") {
    auto dev = make_vk();
    if (!dev) return;
    std::string step = "two equal shaders, one pipeline layout";
    INFO("step: " << step);
    CHECK(dev->pipeline_cache() != VK_NULL_HANDLE);
    const vk::VulkanCounters start = dev->counters();
    const Shader a = dev->make_shader(fill_shader_desc());
    vk::VulkanCounters c = dev->counters();
    CHECK(c.layoutCacheMisses > start.layoutCacheMisses);  // the pipeline layout and its set layouts
    const std::uint64_t layoutsMade = c.layoutCacheMisses;
    const Shader b = dev->make_shader(fill_shader_desc());
    REQUIRE_MESSAGE(dev->state(b) == ResourceState::Valid, all_errors(*dev));
    CHECK(a.id != b.id);
    c = dev->counters();
    CHECK(c.layoutCacheMisses == layoutsMade);
    CHECK(c.layoutCacheHits == start.layoutCacheHits + 1);

    step = "equal pipeline descs, one VkPipeline (a shader with the same SPIR-V and slots too)";
    const Pipeline p1 = dev->make_pipeline(render_desc(a, PixelFormat::Rgba8));
    const Pipeline p2 = dev->make_pipeline(render_desc(a, PixelFormat::Rgba8));
    const Pipeline p3 = dev->make_pipeline(render_desc(b, PixelFormat::Rgba8));
    REQUIRE_MESSAGE(dev->state(p3) == ResourceState::Valid, all_errors(*dev));
    CHECK(p1.id != p2.id);
    c = dev->counters();
    CHECK(c.pipelineCacheMisses == start.pipelineCacheMisses + 1);
    CHECK(c.pipelineCacheHits == start.pipelineCacheHits + 2);
    const auto s1 = dev->pipeline_state(p1);
    const auto s3 = dev->pipeline_state(p3);
    REQUIRE(s1);
    REQUIRE(s3);
    CHECK(s1->pipeline == s3->pipeline);
    CHECK(s1->layout == s3->layout);

    step = "another format is another VkPipeline";
    CHECK(dev->state(dev->make_pipeline(render_desc(a, PixelFormat::Rgba16F))) == ResourceState::Valid);
    c = dev->counters();
    CHECK(c.pipelineCacheMisses == start.pipelineCacheMisses + 2);

    step = "one block, two views, two samplers: set 0 holds the block, set 1 the views and samplers";
    const Shader two = dev->make_shader(two_views_shader_desc());
    REQUIRE_MESSAGE(dev->state(two) == ResourceState::Valid, all_errors(*dev));
    const Pipeline pip = dev->make_pipeline(render_desc(two, PixelFormat::Rgba8));
    REQUIRE_MESSAGE(dev->state(pip) == ResourceState::Valid, all_errors(*dev));
    const auto st = dev->pipeline_state(pip);
    REQUIRE(st);
    const vk::PipelineLayoutInfo& lay = *st->layout;
    CHECK(lay.hasSet[0]);
    CHECK(lay.hasSet[1]);
    CHECK(lay.uniformCount == 1);
    CHECK(lay.counts[0].n[vk::kDescUniformBufferDynamic] == 1);
    CHECK(lay.counts[1].n[vk::kDescSampledImage] == 2);
    CHECK(lay.counts[1].n[vk::kDescSampler] == 2);
    CHECK(lay.viewBinding[0] == 0);
    CHECK(lay.viewBinding[1] == 1);
    CHECK(lay.samplerBinding[0] == 32);  // sokol-shdc puts the samplers from binding 32 on
    CHECK(lay.samplerBinding[1] == 33);
    CHECK(lay.samplerUsed == 3u);
    CHECK(lay.bindless == (dev->counters().bindlessCapacity > 0));  // every layout sees the bindless table

    step = "drawing with it: each view through its own sampler; the second list's pass comes from the cache";
    const std::uint64_t passesMade = dev->counters().renderPassCacheMisses;
    const Target t = make_target(*dev, Attach::Color, 4, 4, PixelFormat::Rgba8);
    Bindings bind;
    bind.views[0] = make_texture(*dev, 1, 1, {255, 0, 0, 255});
    bind.views[1] = make_texture(*dev, 1, 1, {0, 255, 0, 255});
    bind.samplers[0] = make_clamped_sampler(*dev, Filter::Nearest);
    bind.samplers[1] = make_clamped_sampler(*dev, Filter::Linear);
    for (int i = 0; i < 2; ++i) {
        CommandList& list = dev->begin_commands("two-views");
        list.begin_pass(color_pass(t, PixelFormat::Rgba8, Color{}));
        list.set_pipeline(pip);
        list.set_bindings(bind);
        list.set_uniforms(0, bytes_of(Vec4{1.0f, 1.0f, 1.0f, 1.0f}));
        list.draw(0, 3);
        list.end_pass();
        submit_and_finish(*dev, list);
    }
    CHECK(dev->counters().renderPassCacheMisses <= passesMade + 1);
    const std::string bad = first_mismatch(read_rgba8(*dev, t.image, 4, 4), 4, 4, 0,
                                           [](int, int) { return std::array<int, 4>{255, 255, 0, 255}; });
    CHECK_MESSAGE(bad.empty(), bad);
    step = "the validation layer said nothing";
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
}

TEST_CASE("vulkan: make_shader and make_pipeline say what is wrong with a desc") {
    auto dev = make_vk();
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
    sd.vertexFunc.bytecode = Range{};
    sd.vertexFunc.source = "#version 450\nvoid main() {}";
    CHECK(contains(shader_error(sd), "the vertex stage is source text, and Vulkan takes SPIR-V"));
    sd = fill_shader_desc();
    const char dxbc[24] = {'D', 'X', 'B', 'C'};
    sd.fragmentFunc.bytecode = Range{dxbc, sizeof dxbc};
    CHECK(contains(shader_error(sd), "the fragment stage's bytecode (24 bytes) is not SPIR-V"));
    sd = fill_shader_desc();
    sd.computeFunc = compute_shader_desc().computeFunc;
    CHECK(contains(shader_error(sd), "it has a compute stage and a vertex or fragment stage"));
    sd = fill_shader_desc();
    sd.uniformBlocks[1].binding.spirvSet = 1;
    CHECK(contains(shader_error(sd), "uniform block 1 is in descriptor set 1"));
    sd = fill_shader_desc();
    sd.uniformBlocks[1].binding.spirvBinding = 0;
    CHECK(contains(shader_error(sd), "uniform block 1 is on binding 0 of set 0, which uniform block 0 is on already"));
    sd = fill_shader_desc();
    sd.samplers[0].stage = ShaderStage::Compute;
    sd.samplers[0].binding.spirvSet = 1;
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
    REQUIRE_MESSAGE(dev->state(fill) == ResourceState::Valid, all_errors(*dev));
    pd = render_desc(fill, PixelFormat::Rgba8);
    pd.compute = true;
    CHECK(contains(pipeline_error(pd), "is a render shader"));
    pd = render_desc(fill, PixelFormat::Bc7Rgba);
    CHECK(contains(pipeline_error(pd), "colour target 0 ("));
    CHECK(contains(last_error(*dev), "is not a colour format this GPU renders to"));
    pd = render_desc(fill, PixelFormat::Rgba8, PixelFormat::None, 3);
    CHECK(contains(pipeline_error(pd), "sampleCount 3 is not 1, 2, 4 or 8"));

    step = "the validation layer said nothing";
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

TEST_CASE("vulkan: the command list says what is wrong, skips what depends on it and records nothing broken") {
    auto dev = make_vk();
    if (!dev) return;
    const Shader fill = dev->make_shader(fill_shader_desc());
    const Shader blitShader = dev->make_shader(from_sg(*blit_blit_keep_shader_desc(SG_BACKEND_VULKAN)));
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
    list.push_debug_group("outer");  // opened before the passes, closed after them
    list.set_pipeline(rgba8);
    CHECK(contains(last_error(*dev), "CommandList::set_pipeline in list 'mistakes': outside a pass"));
    list.end_pass();
    CHECK(contains(last_error(*dev), "end_pass in list 'mistakes': no pass is open"));
    list.draw(0, 3);
    CHECK(contains(last_error(*dev), "outside a render pass"));

    step = "a pass into the window";
    const Swapchain sc{};
    PassDesc window = PassDesc::for_swapchain(sc, dev->environment_defaults());
    window.label = "window";
    list.begin_pass(window);
    CHECK(contains(last_error(*dev), "pass 'window': a pass into the window (PassDesc::swapchain) comes in M77-P9"));
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
    list.push_debug_group("in-pass");
    list.set_pipeline(rgba16);
    CHECK(contains(last_error(*dev), "draws into"));
    before = dev->errors().size();
    list.draw(0, 3);  // skipped until the next set_pipeline
    CHECK(dev->errors().size() == before);

    step = "uniforms";
    list.set_pipeline(rgba8);
    list.draw(0, 3);
    CHECK(contains(last_error(*dev), "uniform block slot 0 of shader '"));
    CHECK(contains(last_error(*dev), "was not set since set_pipeline"));
    list.set_uniforms(0, Range{zero.data(), 8});
    CHECK(contains(last_error(*dev), "has 16 bytes and the data has 8"));
    list.set_pipeline(rgba8);
    list.set_uniforms(3, bytes_of(zero));
    CHECK(contains(last_error(*dev), "uniform block slot 3 is not one shader '"));

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
    list.pop_debug_group();
    list.end_pass();

    step = "dispatch";
    list.begin_compute_pass("compute");
    list.set_pipeline(rgba8);
    CHECK(contains(last_error(*dev), "is a render pipeline inside a compute pass"));
    list.dispatch(70000, 1, 1);
    CHECK(contains(last_error(*dev), "thread groups: the counts are 0 to ("));
    list.end_pass();
    list.pop_debug_group();
    list.pop_debug_group();  // one too many
    CHECK(contains(last_error(*dev), "without an open group"));
    submit_and_finish(*dev, list);

    step = "the validation layer said nothing";
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
    step = "an async read of no buffer is a teaching error";
    auto ticket = dev->request_buffer_read(Buffer{}, 0, 4);
    REQUIRE(!ticket);
    CHECK(contains(ticket.error().message, "is not a live buffer"));
}

TEST_CASE("vulkan: commit listeners, frame counting and statistics") {
    auto dev = make_vk();
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
    CHECK(dev->counters().completedTimelineValue <= dev->counters().timelineValue);
    dev->enable_stats(true);
    BufferDesc bd;
    bd.size = 16;
    dev->destroy_buffer(dev->make_buffer(bd));
    CHECK(dev->total_stats().buffers.allocated == 1);
    CHECK(dev->total_stats().buffers.deallocated == 1);
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
}

TEST_CASE("vulkan: the Vulkan 1.0 barriers (synchronization2 off) move the same data") {
    VulkanOptions o;
    o.synchronization2 = false;
    auto dev = make_vk(o);
    if (!dev) return;
    CHECK(!dev->synchronization2_active());
    round_trips(*dev);
    CHECK(dev->counters().barriers > 0);
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

TEST_CASE("vulkan: a CPU device (lavapipe) on request, or a teaching error") {
    VulkanOptions o;
    o.cpuDevice = true;
    o.validation = true;
    auto d = make_vulkan_device(o);
    if (!d) {
        const std::string e = d.error().to_string();
        if (cannot_run_here(e) && !contains(e, "no CPU Vulkan device") && !vulkan_required()) {
            MESSAGE("vulkan: skipped, " << e);
            return;
        }
        CHECK(contains(e, "no CPU Vulkan device (VulkanOptions::cpuDevice)"));
        CHECK(contains(d.error().hint, "lavapipe"));
        MESSAGE("vulkan: no CPU device here: " << e);
        return;
    }
    auto& dev = static_cast<VulkanDevice&>(*d.value());
    CHECK(dev.cpu_device());
    round_trips(dev);
    CHECK_MESSAGE(layer_errors(dev).empty(), layer_errors(dev));
}

// ---------------------------------------------------------------------------------------------------------------------
// GPU timers, asynchronous reads, synchronization (M77-P8b1)
// ---------------------------------------------------------------------------------------------------------------------

TEST_CASE("vulkan: a timed frame with two scopes resolves to frame and scope times a few frames later") {
    auto dev = make_vk();
    if (!dev) return;
    std::string why;
    if (!dev->timer_supported(&why)) {
        MESSAGE("vulkan: skipped, this queue cannot time: " << why);
        CHECK(!why.empty());
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
    step = "the validation layer said nothing";
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
}

namespace {

Buffer make_storage_buffer(VulkanDevice& dev, const std::vector<std::uint8_t>& data, const char* label) {
    BufferDesc bd;
    bd.size = data.size();
    bd.usage.storageBuffer = true;
    bd.data = range_of(data);
    bd.label = label;
    return dev.make_buffer(bd);
}

}  // namespace

TEST_CASE("vulkan: async reads of a buffer and of an image region") {
    auto dev = make_vk();
    if (!dev) return;
    CHECK(dev->async_read_supported());
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

    step = "image: a 33x3 region of a 37x5 RGBA8 image, and the whole image";
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
    bad = dev->request_buffer_read(Buffer{}, 0, 4);
    REQUIRE(!bad);
    CHECK(contains(bad.error().message, "is not a live buffer"));
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
    step = "the validation layer said nothing";
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

TEST_CASE("vulkan: async read tickets are generation-checked, and every slot can be in flight at once") {
    auto dev = make_vk();
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
    step = "the validation layer said nothing";
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
}

namespace {

// A compute pass writes an 8x8 storage image; a second compute pipeline samples it as a texture (a compute read) and a
// fragment shader samples it after that (a read in another stage, which must still wait for the write); the
// synchronization validation checks every barrier.
void read_after_read(VulkanDevice& dev) {
    const Shader computeShader = dev.make_shader(compute_shader_desc());
    const Shader sampleShader = dev.make_shader(sample_shader_desc());
    const Shader twoShader = dev.make_shader(two_views_shader_desc());
    REQUIRE_MESSAGE(dev.state(sampleShader) == ResourceState::Valid, all_errors(dev));
    PipelineDesc pd;
    pd.compute = true;
    pd.shader = computeShader;
    pd.label = "write";
    const Pipeline write = dev.make_pipeline(pd);
    pd.shader = sampleShader;
    pd.label = "sample";
    const Pipeline sample = dev.make_pipeline(pd);
    const Pipeline draw = dev.make_pipeline(render_desc(twoShader, PixelFormat::Rgba8));
    REQUIRE_MESSAGE(dev.state(sample) == ResourceState::Valid, all_errors(dev));
    REQUIRE_MESSAGE(dev.state(draw) == ResourceState::Valid, all_errors(dev));
    ImageDesc id;
    id.width = 8;
    id.height = 8;
    id.pixelFormat = PixelFormat::Rgba8;
    id.usage.storageImage = true;
    id.label = "written";
    const Image written = dev.make_image(id);
    id.label = "copied";
    const Image copied = dev.make_image(id);
    BufferDesc bd;
    bd.size = 64 * 4;
    bd.usage.storageBuffer = true;
    bd.label = "words";
    const Buffer words = dev.make_buffer(bd);
    ViewDesc v;
    v.storageImage.image = written;
    const View writtenStorage = dev.make_view(v);
    v = {};
    v.texture.image = written;
    const View writtenTexture = dev.make_view(v);
    v = {};
    v.storageImage.image = copied;
    const View copiedStorage = dev.make_view(v);
    v = {};
    v.storageBuffer.buffer = words;
    const View wordsView = dev.make_view(v);
    const Sampler nearest = make_clamped_sampler(dev, Filter::Nearest);
    const Target t = make_target(dev, Attach::Color, 4, 4, PixelFormat::Rgba8);

    CommandList& list = dev.begin_commands("read-after-read");
    list.begin_compute_pass("write");
    list.set_pipeline(write);
    Bindings wb;
    wb.views[0] = writtenStorage;
    wb.views[1] = wordsView;
    list.set_bindings(wb);
    const std::int32_t mode[4] = {0, 0, 0, 0};
    list.set_uniforms(0, Range{mode, sizeof mode});
    list.dispatch(1, 1, 1);
    list.end_pass();
    list.begin_compute_pass("sample");
    list.set_pipeline(sample);
    Bindings sb;
    sb.views[0] = writtenTexture;
    sb.views[1] = copiedStorage;
    sb.samplers[0] = nearest;
    list.set_bindings(sb);
    list.dispatch(1, 1, 1);
    list.end_pass();
    list.begin_pass(color_pass(t, PixelFormat::Rgba8, Color{}));
    list.set_pipeline(draw);
    Bindings db;
    db.views[0] = writtenTexture;  // the read in a second stage
    db.views[1] = make_texture(dev, 1, 1, {0, 0, 0, 0});
    db.samplers[0] = nearest;
    db.samplers[1] = nearest;
    list.set_bindings(db);
    list.set_uniforms(0, bytes_of(Vec4{1.0f, 1.0f, 1.0f, 1.0f}));
    list.draw(0, 3);
    list.end_pass();
    submit_and_finish(dev, list);
    const auto pattern8 = [](int x, int y) { return std::array<int, 4>{x * 32, y * 32, 0, 255}; };
    std::string bad = first_mismatch(read_rgba8(dev, copied, 8, 8), 8, 8, 0, pattern8);
    CHECK_MESSAGE(bad.empty(), "the compute read: " << bad);
    // The centre of the 8x8 image with a nearest sampler: texel (4, 4).
    bad = first_mismatch(read_rgba8(dev, t.image, 4, 4), 4, 4, 1,
                         [](int, int) { return std::array<int, 4>{128, 128, 0, 255}; });
    CHECK_MESSAGE(bad.empty(), "the fragment read: " << bad);
    CHECK_MESSAGE(all_errors(dev).empty(), all_errors(dev));
}

}  // namespace

TEST_CASE("vulkan: a read in a second stage after a compute write waits for the write (synchronization validation)") {
    auto dev = make_vk();
    if (!dev) return;
    read_after_read(*dev);
}

TEST_CASE("vulkan: the Vulkan 1.0 barriers carry the storage and sampled bits of a compute write and its reads") {
    VulkanOptions o;
    o.synchronization2 = false;
    auto dev = make_vk(o);
    if (!dev) return;
    CHECK(!dev->synchronization2_active());
    read_after_read(
        *dev);  // VK_ACCESS_2_SHADER_STORAGE_WRITE_BIT is above bit 31: mapped to VK_ACCESS_SHADER_WRITE_BIT
}

TEST_CASE("vulkan: switching between pipelines with different set-0 layouts binds every set again") {
    auto dev = make_vk();
    if (!dev) return;
    const Shader fill = dev->make_shader(fill_shader_desc());      // set 0: two uniform blocks
    const Shader two = dev->make_shader(two_views_shader_desc());  // set 0: one block; set 1: views and samplers
    const Pipeline fillPip = dev->make_pipeline(render_desc(fill, PixelFormat::Rgba8));
    const Pipeline twoPip = dev->make_pipeline(render_desc(two, PixelFormat::Rgba8));
    REQUIRE_MESSAGE(dev->state(fillPip) == ResourceState::Valid, all_errors(*dev));
    REQUIRE_MESSAGE(dev->state(twoPip) == ResourceState::Valid, all_errors(*dev));
    const Target t = make_target(*dev, Attach::Color, 4, 4, PixelFormat::Rgba8);
    Bindings bind;
    bind.views[0] = make_texture(*dev, 1, 1, {255, 0, 0, 255});
    bind.views[1] = make_texture(*dev, 1, 1, {0, 255, 0, 255});
    bind.samplers[0] = make_clamped_sampler(*dev, Filter::Nearest);
    bind.samplers[1] = make_clamped_sampler(*dev, Filter::Linear);
    const auto draw_fill = [&](CommandList& list, const Vec4& colour) {
        list.set_pipeline(fillPip);
        list.set_uniforms(0, bytes_of(Vec4{0.0f, 0.0f, 0.0f, 0.0f}));
        list.set_uniforms(1, bytes_of(colour));
        list.draw(0, 3);
    };
    const auto draw_two = [&](CommandList& list, float scale) {
        list.set_pipeline(twoPip);
        list.set_bindings(bind);
        list.set_uniforms(0, bytes_of(Vec4{scale, scale, scale, 1.0f}));
        list.draw(0, 3);
    };
    std::string step = "fill, then two views: the views' set survives the new set 0";
    INFO("step: " << step);
    CommandList& a = dev->begin_commands("fill-then-two");
    a.begin_pass(color_pass(t, PixelFormat::Rgba8, Color{}));
    draw_fill(a, Vec4{0.0f, 0.0f, 1.0f, 1.0f});
    draw_two(a, 1.0f);
    a.end_pass();
    submit_and_finish(*dev, a);
    std::string bad = first_mismatch(read_rgba8(*dev, t.image, 4, 4), 4, 4, 0,
                                     [](int, int) { return std::array<int, 4>{255, 255, 0, 255}; });
    CHECK_MESSAGE(bad.empty(), bad);

    step = "two views, fill, two views: each draw binds what its layout needs";
    CommandList& b = dev->begin_commands("two-fill-two");
    b.begin_pass(color_pass(t, PixelFormat::Rgba8, Color{}));
    draw_two(b, 1.0f);
    draw_fill(b, Vec4{0.0f, 0.0f, 1.0f, 1.0f});
    draw_two(b, 0.0f);  // black with alpha 1: only a missing or stale binding would show
    b.end_pass();
    submit_and_finish(*dev, b);
    bad = first_mismatch(read_rgba8(*dev, t.image, 4, 4), 4, 4, 0,
                         [](int, int) { return std::array<int, 4>{0, 0, 0, 255}; });
    CHECK_MESSAGE(bad.empty(), bad);
    step = "the validation layer said nothing";
    CHECK_MESSAGE(all_errors(*dev).empty(), all_errors(*dev));
}

TEST_CASE("vulkan: a texture view and a storage image view of one subresource in one dispatch is a teaching error") {
    auto dev = make_vk();
    if (!dev) return;
    PipelineDesc pd;
    pd.compute = true;
    pd.shader = dev->make_shader(sample_shader_desc());
    pd.label = "sample";
    const Pipeline sample = dev->make_pipeline(pd);
    REQUIRE_MESSAGE(dev->state(sample) == ResourceState::Valid, all_errors(*dev));
    ImageDesc id;
    id.width = 8;
    id.height = 8;
    id.pixelFormat = PixelFormat::Rgba8;
    id.usage.storageImage = true;
    id.label = "both";
    const Image img = dev->make_image(id);
    ViewDesc v;
    v.texture.image = img;
    Bindings b;
    b.views[0] = dev->make_view(v);
    v = {};
    v.storageImage.image = img;
    b.views[1] = dev->make_view(v);
    b.samplers[0] = make_clamped_sampler(*dev, Filter::Nearest);
    CommandList& list = dev->begin_commands("conflict");
    list.begin_compute_pass("conflict");
    list.set_pipeline(sample);
    list.set_bindings(b);
    list.dispatch(1, 1, 1);
    list.end_pass();
    submit_and_finish(*dev, list);
    const std::string e = all_errors(*dev);
    CHECK_MESSAGE(contains(e, "in the same dispatch"), e);
    CHECK_MESSAGE(contains(e, "cannot be bound together"), e);
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));  // nothing broken was recorded
}

TEST_CASE("vulkan: storage_image_loadable answers per format, with a reason") {
    auto dev = make_vk();
    if (!dev) return;
    std::string why = "stale";
    for (PixelFormat f : {PixelFormat::Rgba8, PixelFormat::Rgba16F, PixelFormat::R32F, PixelFormat::Rgba32F}) {
        CHECK_MESSAGE(dev->storage_image_loadable(f, &why), pixel_format_name(f) << ": " << why);
        CHECK(why.empty());
    }
    CHECK(!dev->storage_image_loadable(PixelFormat::DepthStencil, &why));
    CHECK_MESSAGE(contains(why, "cannot use"), why);
    CHECK_MESSAGE(contains(why, "storage image"), why);
    CHECK(!dev->storage_image_loadable(PixelFormat::DepthStencil, nullptr));
}

#endif
