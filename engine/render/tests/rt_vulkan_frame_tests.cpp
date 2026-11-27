// M79 POLISH-RK-2: the renderer on the engine's own Vulkan backend with ray traced shadows of a point light, drawn at
// the full render scale and at the low ones a dynamic resolution picks. The lit shader reads the traced mask of a
// local light through fa_shadow_local_rt (mesh_common.glsl): the texel of the fragment first, then the darkest of the
// 3 x 3 block around it that shows the same surface. At a low render scale the mask is smaller than the design size, so
// that block covers a larger part of the picture; the shadow must stay and nothing may appear in the lit part. Runs
// where the machine's Vulkan device traces rays (lavapipe of Mesa 24.1 or later on the Linux CI job); a machine without
// Vulkan or without ray tracing says so and passes, unless FA_VULKAN_REQUIRE=1 / FA_VULKAN_REQUIRE_RT=1 (the CI job)
// turn the skip into a failure.
// Time (M79 POLISH-RK-3; Mesa 25.2.8 lavapipe, validation layer, Release build, xvfb-run, FA_VULKAN_REQUIRE=1
// FA_VULKAN_REQUIRE_RT=1): about 2 s with every core and about 2 s limited to one (`taskset -c 0`), for the three scales
// with a renderer of its own for each picture. Far below the 20 s that would ask for a ctest entry of its own, so it
// stays in `render`.
#include "test_util.h"

#include <cstdlib>
#include <cstring>
#include <string>

#include "fa/render/raytracing.h"
#include "gpu/recording_device.h"
#include "render_internal.h"
#if defined(FA_RENDER_VULKAN)
#include "gpu/vulkan_device.h"
#endif

using namespace fa;
using namespace fa::test;

#if defined(FA_RENDER_VULKAN)

namespace {

constexpr int kW = 160;
constexpr int kH = 96;

bool env_is_one(const char* name) {
    const char* v = std::getenv(name);
    return v && std::strcmp(v, "1") == 0;
}

bool has(const std::string& s, const std::string& part) { return s.find(part) != std::string::npos; }

// What a machine that cannot run Vulkan answers (vulkan_device_tests.cpp's cannot_run_here).
bool cannot_run_vulkan_here(const std::string& e) {
    return has(e, "no Vulkan loader") || has(e, "no Vulkan device") || has(e, "needs 1.2") ||
           has(e, "VK_ERROR_INITIALIZATION_FAILED");
}

// A camera above a floor with a box in the middle and one point light that casts shadows, to the side and above it.
void make_scene(World& w, bool lightCasts) {
    Entity cam = make(w, "cam", {0, 3, 12});
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    Entity floor = make(w, "floor", {0, 0, 0});
    w.get<Transform>(floor)->scale = {16, 1, 16};
    w.add<MeshRenderer>(floor).mesh = "plane";
    Entity box = make(w, "box", {0, 1.5f, 0});
    w.get<Transform>(box)->scale = {3, 3, 3};
    w.add<MeshRenderer>(box).mesh = "cube";
    Entity lamp = make(w, "lamp", {-6.0f, 7.0f, 1.0f});
    auto& l = w.add<Light>(lamp);
    l.type = LightType::Point;
    l.range = 30.0f;
    l.intensity = 8.0f;
    l.castShadows = lightCasts;
}

float luma(const fa::Image& img, int i) {
    const std::uint8_t* p = &img.rgba[std::size_t(i) * 4];
    return (0.2126f * float(p[0]) + 0.7152f * float(p[1]) + 0.0722f * float(p[2])) / 255.0f;
}

struct VkRig {
    Renderer renderer;
    bool ok = false;
    std::string error;
    VkRig() {
        RendererDesc d;
        d.designWidth = kW;
        d.designHeight = kH;
        d.headless = true;
        d.backend = GpuBackend::Vulkan;
        ok = renderer.init(d, gfx().gpu.environment(), &error);
    }
    ~VkRig() { renderer.shutdown(); }
    VkRig(const VkRig&) = delete;
    VkRig& operator=(const VkRig&) = delete;

    // `frames` frames of `world` at render scale `scale` (the denoiser needs a few to settle), the last one read back at
    // the design size.
    fa::Image draw(World& world, float scale, int frames) {
        renderer.set_upscale_stage(true);  // the picture is drawn small and brought back to the design size
        renderer.set_render_scale(scale, 1.0f);
        fa::Image img;
        for (int i = 0; i < frames; ++i) {
            renderer.update(world);
            renderer.begin_frame();
            renderer.render_world(world, 0.0f);
            renderer.end_frame();
        }
        std::string err;
        const bool captured = renderer.capture(img, &err);
        INFO("capture error: " << err);
        REQUIRE(captured);
        return img;
    }
};

}  // namespace

// Starts `rig` on Vulkan with the ray traced hard shadows of a point light. Returns its device, or null when this machine
// cannot run the test (said, and a pass) or the renderer did not start (a failure already reported).
static gpu::vk::VulkanDevice* start_rig(VkRig& rig) {
    if (!rig.ok) {
        if (cannot_run_vulkan_here(rig.error) && !env_is_one("FA_VULKAN_REQUIRE")) {
            MESSAGE("vulkan: skipped, " << rig.error);
            return nullptr;
        }
        FAIL("the renderer did not start on Vulkan: " << rig.error);
        return nullptr;
    }
    auto* vulkan = dynamic_cast<gpu::vk::VulkanDevice*>(RendererDeviceAccess::device(rig.renderer));
    REQUIRE(vulkan != nullptr);
    std::string why;
    if (!vulkan->ray_tracing_status(&why)) {
        if (env_is_one("FA_VULKAN_REQUIRE_RT")) FAIL("vulkan ray tracing: FA_VULKAN_REQUIRE_RT=1, but " << why);
        MESSAGE("vulkan ray tracing: skipped, " << why);
        return nullptr;
    }
    render::RayTracingSettings rt;
    rt.enabled = true;
    rt.shadows = render::RtShadows::Hard;
    rt.ao = false;
    rig.renderer.set_ray_tracing(rt);
    return vulkan;
}

TEST_CASE("vulkan renderer: the shadow of a ray traced point light stays at low render scales") {
    if (!gfx().ok) {  // the window environment of the fixture
        if (env_is_one("FA_VULKAN_REQUIRE")) FAIL("no GPU here (" << gfx().error << ") but FA_VULKAN_REQUIRE=1");
        MESSAGE("no GPU here (" << gfx().error << "): the Vulkan frame test is skipped");
        return;
    }
    World lit, shadowed;
    make_scene(lit, false);  // the light does not cast: nothing darkens the floor
    make_scene(shadowed, true);
    for (float scale : {1.0f, 0.5f, 0.25f}) {
        INFO("render scale " << scale);
        // A renderer of its own for each picture: the denoiser's history of the previous scale (and of the other world)
        // must not decide this one. One lives at a time.
        std::string errors;
        fa::Image ref, got;
        int candidates = 0, traced = 0;
        {
            VkRig rig;
            gpu::vk::VulkanDevice* vulkan = start_rig(rig);
            if (!vulkan) return;
            ref = rig.draw(lit, scale, 4);
            for (const std::string& e : vulkan->errors()) errors += e + "\n";
        }
        {
            VkRig rig;
            gpu::vk::VulkanDevice* vulkan = start_rig(rig);
            if (!vulkan) return;
            got = rig.draw(shadowed, scale, 6);
            rig.renderer.ray_tracing_local_shadows(candidates, traced);
            INFO("ray tracing failure: " << rig.renderer.ray_tracing_failure());
            CHECK(candidates == 1);
            CHECK(traced == 1);
            for (const std::string& e : vulkan->errors()) errors += e + "\n";
        }
        REQUIRE(got.width == ref.width);
        REQUIRE(got.height == ref.height);
        // The traced shadow darkens part of the picture and brightens none of it beyond the noise of the trace.
        const int n = got.width * got.height;
        int darker = 0, brighter = 0;
        for (int i = 0; i < n; ++i) {
            const float d = luma(got, i) - luma(ref, i);
            darker += d < -0.08f ? 1 : 0;
            brighter += d > 0.08f ? 1 : 0;
        }
        INFO("pixels darker " << darker << ", brighter " << brighter << " of " << n);
        CHECK(darker > n / 100);
        CHECK(brighter <= n / 100);
        INFO(errors);
        CHECK(errors.empty());
    }
}

#else

TEST_CASE("vulkan renderer: the shadow of a ray traced point light stays at low render scales") {
    MESSAGE("this build's renderer has no Vulkan (FA_RENDER_VULKAN off): nothing to check");
}

#endif
