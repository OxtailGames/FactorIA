// The renderer on the device RendererDesc::backend names (gpu/device.h, make_device): a frame drawn offscreen on the
// engine's Vulkan backend matches the same frame on the platform's sokol backend (MoltenVK on macOS, Mesa's lavapipe on
// the Linux CI job, the GPU's driver on Windows), a renderer on a RecordingDevice draws without a GPU and lends its
// device to a UiPainter, and the backends a renderer cannot draw through fail init() with a teaching error.
//
// A machine without a Vulkan loader or device says so (MESSAGE) and passes, unless FA_VULKAN_REQUIRE=1 (the Linux CI
// job): then a skip fails, as in vulkan_device_tests.cpp.
#include "test_util.h"

#include <cstdlib>
#include <cstring>
#include <memory>
#include <string>
#include <vector>

#include "fa/render/ui_painter.h"
#include "gpu/recording_device.h"
#include "gpu/sokol_context.h"
#include "render_internal.h"
#include "ui_painter_internal.h"
#if defined(FA_RENDER_VULKAN)
#include "gpu/vulkan_device.h"
#endif

using namespace fa;
using namespace fa::test;

namespace {

bool has(const std::string& s, const std::string& part) { return s.find(part) != std::string::npos; }

constexpr int kW = 160;
constexpr int kH = 96;

// A 2D world: a clear colour, three shapes (one additive, one circle) and a sprite of the built-in white texture.
struct Scene2D {
    World world;
    Scene2D() {
        world.add<Camera>(make(world, "cam")).clearColor = Color{0.05f, 0.08f, 0.12f, 1.0f};
        auto shape = [&](const char* name, Vec3 at, ShapeType type, Vec2 size, Color color, BlendMode blend) {
            auto& s = world.add<Shape2D>(make(world, name, at));
            s.shape = type;
            s.size = size;
            s.color = color;
            s.blend = blend;
        };
        shape("box", {-40, 10, 0}, ShapeType::Rectangle, {50, 30}, Color{0.9f, 0.3f, 0.2f, 1.0f}, BlendMode::Alpha);
        shape("disc", {30, -10, 0}, ShapeType::Circle, {40, 40}, Color{0.2f, 0.7f, 0.9f, 1.0f}, BlendMode::Alpha);
        shape("glow", {0, 0, 0}, ShapeType::Rectangle, {30, 60}, Color{0.3f, 0.3f, 0.1f, 1.0f}, BlendMode::Additive);
    }
};

// A 3D world: a lit floor and a cube under a point light and the directional sun, seen in perspective.
struct Scene3D {
    World world;
    Scene3D() {
        Entity cam = make(world, "cam", {0, 4, 6});
        world.get<Transform>(cam)->rotation = {-30, 0, 0};
        auto& c = world.add<Camera>(cam);
        c.projection = Projection::Perspective;
        c.fov = 55;
        Entity floor = make(world, "floor");
        world.get<Transform>(floor)->scale = {8, 1, 8};
        auto& f = world.add<MeshRenderer>(floor);
        f.mesh = "plane";
        f.color = Color{0.7f, 0.7f, 0.7f, 1};
        auto& cube = world.add<MeshRenderer>(make(world, "cube", {0, 0.5f, 0}));
        cube.mesh = "cube";
        cube.color = Color{0.8f, 0.4f, 0.2f, 1};
        Entity lamp = make(world, "lamp", {1.5f, 2.0f, 1.0f});
        Light& l = world.add<Light>(lamp);
        l.type = LightType::Point;
        l.castShadows = false;
    }
};

#if defined(FA_RENDER_VULKAN)
bool vulkan_required() {
    const char* v = std::getenv("FA_VULKAN_REQUIRE");
    return v && std::strcmp(v, "1") == 0;
}

// What a machine that cannot run Vulkan answers (vulkan_device_tests.cpp's cannot_run_here).
bool cannot_run_vulkan_here(const std::string& e) {
    return has(e, "no Vulkan loader") || has(e, "no Vulkan device") || has(e, "needs 1.2") ||
           has(e, "VK_ERROR_INITIALIZATION_FAILED");
}
#endif

// A headless renderer of kW x kH on `backend`, on the fixture's window environment (the default formats).
struct BackendRenderer {
    Renderer renderer;
    bool ok = false;
    std::string error;
    explicit BackendRenderer(GpuBackend backend, bool headless = true) {
        RendererDesc d;
        d.designWidth = kW;
        d.designHeight = kH;
        d.headless = headless;
        d.backend = backend;
        ok = renderer.init(d, gfx().gpu.environment(), &error);
    }
    ~BackendRenderer() { renderer.shutdown(); }
    BackendRenderer(const BackendRenderer&) = delete;
    BackendRenderer& operator=(const BackendRenderer&) = delete;

    gpu::Device* device() { return RendererDeviceAccess::device(renderer); }
};

// One frame of `world` on `r`, read back through the device.
fa::Image draw_on(Renderer& r, World& world) {
    r.update(world);
    r.begin_frame();
    r.render_world(world, 0.0f);
    r.end_frame();
    fa::Image img;
    std::string err;
    const bool captured = r.capture(img, &err);
    INFO("capture error: " << err);
    REQUIRE(captured);
    return img;
}

// A UI frame of one white triangle over the top-left half of a kSize x kSize display, with a 4x4 white texture of the
// painter, and an offscreen RGBA8 target to draw it into (no window here).
struct UiTriangle {
    static constexpr int kSize = 64;
    render::UiTexture tex;
    render::UiVertex vertices[3];
    std::uint16_t indices[3] = {0, 1, 2};
    render::UiDrawCommand command;
    render::UiDrawList list;
    render::UiFrame frame;
    gpu::Image target;
    gpu::View view;

    explicit UiTriangle(render::UiPainter& painter) {
        const std::vector<std::uint8_t> pixels(4 * 4 * 4, 255);
        tex = painter.make_texture(4, 4, pixels.data());
        vertices[1].x = float(kSize);
        vertices[2].y = float(kSize);
        command.view = tex.view;
        command.clipMaxX = float(kSize);
        command.clipMaxY = float(kSize);
        command.indexCount = 3;
        list.vertices = vertices;
        list.vertexCount = 3;
        list.indices = indices;
        list.indexCount = 3;
        list.commands = &command;
        list.commandCount = 1;
        frame.displayWidth = float(kSize);
        frame.displayHeight = float(kSize);
        frame.lists = &list;
        frame.listCount = 1;
    }

    // One list on `device`: a pass that clears the target, the painter's draw, the end of the pass.
    void draw_offscreen(gpu::Device& device, render::UiPainterImpl& impl) {
        gpu::ImageDesc id;
        id.usage.colorAttachment = true;
        id.width = kSize;
        id.height = kSize;
        id.pixelFormat = gpu::PixelFormat::Rgba8;
        id.label = "ui target";
        target = device.make_image(id);
        gpu::ViewDesc vd;
        vd.colorAttachment.image = target;
        vd.label = "ui target";
        view = device.make_view(vd);
        gpu::PassDesc pass;
        pass.label = "ui";
        pass.color = view;
        pass.colorLoad = gpu::LoadAction::Clear;
        pass.format.color = gpu::PixelFormat::Rgba8;
        gpu::CommandList& cl = device.begin_commands("ui");
        cl.begin_pass(pass);
        impl.draw(cl, pass.format, frame);
        cl.end_pass();
        device.submit(cl);
    }

    void release(gpu::Device& device, render::UiPainter& painter) {
        painter.destroy_texture(tex);
        if (view.valid()) device.destroy_view(view);
        if (target.valid()) device.destroy_image(target);
    }
};

// The fixture's renderer, at the size of the backend renderer's picture.
fa::Image draw_on_fixture(World& world) {
    Gfx& g = gfx();
    g.renderer.set_target_size(kW, kH);
    fa::Image img = g.draw(world);
    g.renderer.set_target_size(320, 180);
    return img;
}

}  // namespace

TEST_CASE("renderer: a frame on the Vulkan backend matches the frame on the platform's sokol backend") {
    Gfx& g = gfx();
    if (!g.ok) {
        MESSAGE("no GPU here (" << g.error << "): the backend comparison is skipped");
        return;
    }
#if !defined(FA_RENDER_VULKAN)
    BackendRenderer vk(GpuBackend::Vulkan);
    REQUIRE(!vk.ok);
    CHECK(has(vk.error, "FA_RENDER_VULKAN is off"));
    MESSAGE("this build's renderer has no Vulkan (FA_RENDER_VULKAN off): only its teaching error is checked");
#else
    BackendRenderer vk(GpuBackend::Vulkan);
    if (!vk.ok) {
        if (cannot_run_vulkan_here(vk.error) && !vulkan_required()) {
            MESSAGE("vulkan: skipped, " << vk.error);
            return;
        }
        FAIL("the renderer did not start on Vulkan: " << vk.error);
        return;
    }
    gpu::Device* dev = vk.device();
    REQUIRE(dev != nullptr);
    CHECK(dev->backend() == gpu::Backend::Vulkan);
    CHECK(vk.renderer.gpu_info().backend == "vulkan");
    auto* vulkan = dynamic_cast<gpu::vk::VulkanDevice*>(dev);
    REQUIRE(vulkan != nullptr);

    SUBCASE("2D: shapes, an additive blend, the clear colour") {
        Scene2D s;
        const fa::Image ref = draw_on_fixture(s.world);
        const fa::Image got = draw_on(vk.renderer, s.world);
        REQUIRE(got.width == ref.width);
        REQUIRE(got.height == ref.height);
        const ImageDiff d = diff_images(ref, got, 4.0f / 255.0f);
        const double share = double(d.differingPixels) / double(got.width * got.height);
        INFO("2D: mean " << d.meanError << ", share " << share << ", max " << d.maxError);
        CHECK(d.meanError < 0.004);
        CHECK(share < 0.08);
    }
    SUBCASE("3D: a lit floor and a cube") {
        Scene3D s;
        const fa::Image ref = draw_on_fixture(s.world);
        const fa::Image got = draw_on(vk.renderer, s.world);
        REQUIRE(got.width == ref.width);
        REQUIRE(got.height == ref.height);
        const ImageDiff d = diff_images(ref, got, 4.0f / 255.0f);
        const double share = double(d.differingPixels) / double(got.width * got.height);
        INFO("3D: mean " << d.meanError << ", share " << share << ", max " << d.maxError);
        CHECK(d.meanError < 0.004);
        CHECK(share < 0.08);
    }
    std::string errors;
    for (const std::string& e : vulkan->errors()) errors += e + "\n";
    INFO(errors);
    CHECK(vulkan->errors().empty());
#endif
}

TEST_CASE("renderer: on a RecordingDevice it draws without a GPU and lends the device to a UiPainter") {
    if (!gfx().ok) {
        MESSAGE("no GPU here (" << gfx().error
                                << "): skipped (the built-in shaders follow the open context's dialect)");
        return;
    }
    BackendRenderer rec(GpuBackend::Recording);
    REQUIRE_MESSAGE(rec.ok, rec.error);
    auto* dev = dynamic_cast<gpu::RecordingDevice*>(rec.device());
    REQUIRE(dev != nullptr);
    CHECK(rec.renderer.gpu_info().backend == "dummy");

    // A frame of the 2D world: recorded, never drawn, and every call passes the device's checks.
    Scene2D s;
    rec.renderer.update(s.world);
    rec.renderer.begin_frame();
    rec.renderer.render_world(s.world, 0.0f);
    rec.renderer.end_frame();
    std::size_t draws = 0;
    for (const gpu::RecordedCommand& c : dev->commands())
        if (c.kind == gpu::CommandKind::Draw) ++draws;
    CHECK(draws > 0);

    // The painter makes its pictures and its pipeline on the renderer's device, which it does not own.
    std::string error;
    std::unique_ptr<render::UiPainter> painter = render::UiPainter::create(rec.renderer, &error);
    REQUIRE_MESSAGE(painter != nullptr, error);
    render::UiPainterImpl& impl = render::UiPainterAccess::impl(*painter);
    CHECK(impl.device == dev);
    CHECK(impl.owned == nullptr);
    UiTriangle ui(*painter);
    REQUIRE(ui.tex.valid());
    REQUIRE_MESSAGE(painter->upload(ui.frame, &error), error);

    // Into an image of the renderer's device (a RecordingDevice has no window): one pipeline and one draw.
    const std::size_t before = dev->commands().size();
    ui.draw_offscreen(*dev, impl);
    std::size_t uiDraws = 0;
    for (std::size_t i = before; i < dev->commands().size(); ++i)
        if (dev->commands()[i].kind == gpu::CommandKind::Draw) ++uiDraws;
    CHECK(uiDraws == 1);
    std::string errors;
    for (const std::string& e : dev->errors()) errors += e + "\n";
    INFO(errors);
    CHECK(dev->errors().empty());
    ui.release(*dev, *painter);
    painter.reset();  // before the renderer's shutdown: the device is the renderer's
}

TEST_CASE("renderer: a UiPainter made on a renderer of the sokol backend uploads and draws next to its frame") {
    Gfx& g = gfx();
    if (!g.ok) {
        MESSAGE("no GPU here (" << g.error << "): skipped");
        return;
    }
    // The fixture's renderer keeps its frame's command list open between frames: the painter has a device of its own
    // over the same sokol context (a second list on the renderer's device would trip its one-list-at-a-time check).
    Scene2D s;
    (void)g.draw(s.world);
    std::string error;
    std::unique_ptr<render::UiPainter> painter = render::UiPainter::create(g.renderer, &error);
    REQUIRE_MESSAGE(painter != nullptr, error);
    render::UiPainterImpl& impl = render::UiPainterAccess::impl(*painter);
    REQUIRE(impl.owned != nullptr);
    CHECK(impl.device != RendererDeviceAccess::device(g.renderer));
    CHECK(impl.device->backend() == gpu::built_sokol_backend());

    UiTriangle ui(*painter);
    REQUIRE(ui.tex.valid());
    REQUIRE_MESSAGE(painter->upload(ui.frame, &error), error);
    ui.draw_offscreen(*impl.device, impl);
    // The frame's work goes to the GPU before the read (Metal reads behind the context's command buffer, which only the
    // commit sends; Renderer::commit_context does the same for the editor).
    impl.device->commit();
    std::vector<std::uint8_t> rgba;
    auto read = impl.device->read_image_rgba8(ui.target, UiTriangle::kSize, UiTriangle::kSize, rgba);
    REQUIRE_MESSAGE(read.ok(), (read.ok() ? std::string() : read.error().to_string()));
    REQUIRE(rgba.size() == std::size_t(4 * UiTriangle::kSize * UiTriangle::kSize));
    // The triangle covers the left half of the middle row in white (whichever way the rows are read); its right end keeps
    // the clear colour, black. (The painter's blend keeps the target's alpha, so only the colour is read.)
    const auto at = [&](int x, int y) { return rgba.data() + 4 * (y * UiTriangle::kSize + x); };
    const int mid = UiTriangle::kSize / 2;
    for (int c = 0; c < 3; ++c) {
        CHECK(int(at(2, mid)[c]) > 200);
        CHECK(int(at(UiTriangle::kSize - 4, mid)[c]) == 0);
    }

    // The renderer's next frame still runs: its own list was never touched.
    const fa::Image after = g.draw(s.world);
    CHECK(after.width > 0);
    ui.release(*impl.device, *painter);
}

TEST_CASE("renderer: a backend it cannot draw through fails init with a teaching error") {
    if (!gfx().ok) {
        MESSAGE("no GPU here (" << gfx().error << "): skipped");
        return;
    }
    // Another sokol backend than the one this binary was built with: refused before any context is touched.
    const GpuBackend other = gpu::built_sokol_backend() == gpu::Backend::D3d11 ? GpuBackend::Metal : GpuBackend::D3d11;
    BackendRenderer wrong(other);
    REQUIRE(!wrong.ok);
    CHECK(has(wrong.error, "but this binary was built with"));
    CHECK(has(wrong.error, "GpuBackend::Default"));
    CHECK(gpu::context_open());  // the fixture's context is untouched

    // A device without a window path asked to draw into the window.
    BackendRenderer windowed(GpuBackend::Recording, false);
    REQUIRE(!windowed.ok);
    CHECK(has(windowed.error, "cannot draw into the window"));
    CHECK(has(windowed.error, "no window path yet"));
    CHECK(has(windowed.error, "RendererDesc::headless"));
    CHECK(!has(windowed.error, "M77"));

#if !defined(_WIN32)
    BackendRenderer d3d12(GpuBackend::D3d12);
    REQUIRE(!d3d12.ok);
    CHECK(has(d3d12.error, "Failed to create the GPU device"));
    CHECK(!has(d3d12.error, "M77"));
#endif
    // The fixture still draws.
    Scene2D s;
    const fa::Image img = draw_on_fixture(s.world);
    CHECK(img.width == kW);
}
