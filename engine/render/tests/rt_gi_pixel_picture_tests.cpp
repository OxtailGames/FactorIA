// M79-P4b-1: a picture of the whole renderer with `render.rayTracing.gi = "perPixel"` on the real device of this build. A grey floor beside a red wall,
// lit by the sun and nothing else (a black sky, no ambient): the floor near the wall can only turn red through the rays that leave the floor and hit
// the wall; the floor in the corner of the picture, farther from the wall, takes less of it. A machine without ray tracing says so and skips (the RecordingDevice cases of
// rt_gi_pixel_tests.cpp cover the frame there). No golden image is compared: the values hold on every GPU that traces.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <string>

#include "fa/render/raytracing.h"
#include "fa/render/renderer.h"

using namespace fa;
using namespace fa::test;

namespace {

void pixel_camera(World& w, Vec3 pos, Vec3 lookAt) {
    Entity cam = make(w, "cam", pos);
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    const Vec3 f = normalize(lookAt - pos);
    w.get<Transform>(cam)->rotation = {degrees(std::asin(f.y)), degrees(std::atan2(-f.x, -f.z)), 0};
}

Entity pixel_box(World& w, const char* name, Vec3 pos, Vec3 scale, Color color) {
    Entity e = make(w, name, pos);
    w.get<Transform>(e)->scale = scale;
    auto& m = w.add<MeshRenderer>(e);
    m.mesh = "cube";
    m.color = color;
    return e;
}

void red_room(World& w) {
    pixel_camera(w, {0.0f, 3.0f, 3.0f}, {2.0f, 0.0f, 0.0f});
    w.settings().ambientLight = Color{0, 0, 0, 1};
    w.settings().skyColor = Color{0, 0, 0, 1};
    w.settings().horizonColor = Color{0, 0, 0, 1};
    Entity sun = make(w, "sun", {0, 5, 0});
    w.get<Transform>(sun)->rotation = {-45, -60, 0};  // travels toward +x and down
    auto& l = w.add<Light>(sun);
    l.type = LightType::Directional;
    l.intensity = 0.5f;
    pixel_box(w, "floor", {0, -0.1f, 0}, {14, 0.2f, 14}, Color{0.6f, 0.6f, 0.6f, 1});
    pixel_box(w, "wall", {3.05f, 3, 0}, {0.2f, 6, 14}, Color{0.9f, 0.05f, 0.05f, 1});
}

Color patch(const Image& img, int cx, int cy, int radius = 3) {
    float r = 0, g = 0, b = 0;
    int n = 0;
    for (int dy = -radius; dy <= radius; ++dy)
        for (int dx = -radius; dx <= radius; ++dx) {
            const Color c = img.pixel(cx + dx, cy + dy);
            r += c.r;
            g += c.g;
            b += c.b;
            ++n;
        }
    return Color{r / float(n), g / float(n), b / float(n), 1};
}

Image frame_picture(Gfx& g, World& w) {
    g.renderer.update(w);
    g.renderer.begin_frame();
    g.renderer.render_world(w, 0.0f);
    g.renderer.end_frame();
    g.gpu.end_frame();
    Image img;
    std::string err;
    const bool captured = g.renderer.capture(img, &err);
    INFO("capture error: " << err);
    REQUIRE(captured);
    return img;
}

}  // namespace

TEST_CASE("rt gi pixel picture: a floor beside a red wall takes the wall's colour when the rays are per pixel, and the farther floor takes "
          "less") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    red_room(w);
    render::RayTracingSettings s;
    s.enabled = true;
    s.gi = render::RtGi::Off;
    g.renderer.set_ray_tracing(s);
    Image off;
    for (int i = 0; i < 3; ++i) off = frame_picture(g, w);
    const int mx = off.width / 2, my = off.height / 2;
    const Color near = patch(off, mx, my);
    const Color far = patch(off, off.width / 8, off.height * 7 / 8);
    INFO("gi off: near " << near.r << " " << near.g << " " << near.b << ", far " << far.r << " " << far.g << " " << far.b);
    CHECK(near.r > 0.05f);  // the sun lights the floor
    CHECK(std::fabs(near.r - near.g) < 0.01f);

    s.gi = render::RtGi::PerPixel;
    s.raysPerPixel = 4;
    g.renderer.set_ray_tracing(s);
    Image on;
    // The kernel needs the BLASes and the TLAS (a frame or two) and the denoiser a few frames of history.
    for (int i = 0; i < 12; ++i) on = frame_picture(g, w);
    const render::RtGiPixelStatus st = g.renderer.ray_tracing_gi_pixel_status();
    INFO("giPixel: wanted " << st.wanted << " active " << st.active << " reason " << st.reason);
    if (!st.active) {
        MESSAGE("this device does not trace rays (" << st.reason << "): the picture is not checked");
        g.renderer.set_ray_tracing(render::RayTracingSettings{});
        return;
    }
    const Color c = patch(on, mx, my);
    const Color f = patch(on, on.width / 8, on.height * 7 / 8);
    INFO("perPixel: near " << c.r << " " << c.g << " " << c.b << ", far " << f.r << " " << f.g << " " << f.b);
    // The wall's red light is on the floor next to it: red grew, green and blue hardly.
    CHECK(c.r > near.r + 0.02f);
    CHECK(c.r - c.g > near.r - near.g + 0.02f);
    CHECK(c.g < near.g + 0.5f * (c.r - near.r));
    // The farther floor takes less red than the floor beside the wall (about 0.07 against 0.03 on Metal).
    CHECK((c.r - near.r) > 1.5f * (f.r - far.r));

    // Turning the mode off gives the first picture back, bit for bit: the light of the rays is not kept.
    s.gi = render::RtGi::Off;
    g.renderer.set_ray_tracing(s);
    Image back;
    for (int i = 0; i < 3; ++i) back = frame_picture(g, w);
    CHECK(back.rgba == off.rgba);
    CHECK_FALSE(g.renderer.ray_tracing_gi_pixel_status().active);
    g.renderer.set_ray_tracing(render::RayTracingSettings{});
}
