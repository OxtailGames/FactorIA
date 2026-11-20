// M73-P3c: the lit meshes sample the reflection probes (docs/design/ARCHITECTURE_PROBES.md, "What the meshes read").
//   - pick_probes() (probe_select.h) is a pure function: which two probes a mesh reflects and with what shares, on the CPU, no GPU needed;
//   - a mirror sphere inside a probe's box reflects the probe, outside every box it reflects the sky, in the blend band a mix of both;
//   - the box projection moves the reflection, the roughness blurs it, and a scene with no probe in reach is the sky-only frame, byte for byte;
//   - meshes that reflect the same probes still share a draw.
// The room the probes capture is made of unlit walls tagged "room" that the main camera hides, so the picture holds the sphere only.
#include "test_util.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

#include "fa/core/image.h"
#include "probe_select.h"
#include "render_internal.h"
#include "renderer_test_access.h"

using namespace fa;
using namespace fa::test;
using namespace fa::render;

namespace {

// ---------------------------------------------------------------------------------------------------- CPU

ProbeVolume volume(std::uint64_t id, Vec3 center, Vec3 half, float blend, int importance = 0, Vec3 position = {0, 0, 0},
                   bool rotated = false) {
    ProbeVolume v;
    v.id = id;
    v.center = center;
    v.position = position;
    v.half = half;
    v.blend = blend;
    v.importance = importance;
    if (rotated) {  // 45 degrees about +Y
        const float c = std::sqrt(0.5f);
        v.axis[0] = Vec3{c, 0, -c};
        v.axis[1] = Vec3{0, 1, 0};
        v.axis[2] = Vec3{c, 0, c};
    } else {
        v.axis[0] = Vec3{1, 0, 0};
        v.axis[1] = Vec3{0, 1, 0};
        v.axis[2] = Vec3{0, 0, 1};
    }
    probe_volume_finish(v);
    return v;
}

// ---------------------------------------------------------------------------------------------------- GPU

struct Own {
    Gfx& g;
    Renderer r;
    bool ok = false;
    std::string error;
    explicit Own(Gfx& gx) : g(gx) {
        RendererDesc d;
        d.designWidth = 320;
        d.designHeight = 180;
        d.sampleCount = 1;
        d.headless = true;
        d.adoptContext = true;
        ok = r.init(d, g.gpu.environment(), &error);
        r.probe_set_budget(12);  // every probe is complete in one frame
    }
    ~Own() { r.shutdown(); }
    Own(const Own&) = delete;
    Own& operator=(const Own&) = delete;
    Image frame(World& w) {
        r.begin_frame();
        r.render_world(w, 0.0f);
        r.end_frame();
        g.gpu.end_frame();
        Image img;
        std::string err;
        const bool captured = r.capture(img, &err);
        INFO("capture error: " << err);
        REQUIRE(captured);
        return img;
    }
    // The picture after the probes captured (the first frame captures, the next ones upload the filtered levels and read the atlas).
    Image settled(World& w, int frames = 4) {
        Image img;
        for (int i = 0; i < frames; ++i) img = frame(w);
        return img;
    }
};

// The next renderers made are RGBA8 ones until this goes out of scope.
struct ForceRgba8 {
    ForceRgba8() { renderer_probe_force_rgba8(true); }
    ~ForceRgba8() { renderer_probe_force_rgba8(false); }
};

using Walls = std::array<Color, 6>;  // +X, -X, +Y, -Y, +Z, -Z

Walls all_walls(Color c) { return {c, c, c, c, c, c}; }
const Walls kRainbow = {Color{1, 0, 0, 1}, Color{0, 1, 1, 1}, Color{0, 1, 0, 1},
                        Color{1, 0, 1, 1}, Color{0, 0, 1, 1}, Color{1, 1, 0, 1}};

void add_wall(World& w, const char* name, Vec3 pos, Vec3 scale, Color emissive) {
    Entity e = make(w, name, pos);
    w.get<Transform>(e)->scale = scale;
    w.get<EntityInfo>(e)->tags.push_back("room");
    auto& m = w.add<MeshRenderer>(e);
    m.mesh = "cube";
    m.color = Color{0, 0, 0, 1};
    m.unlit = true;
    m.emissive = emissive;
    m.castShadows = false;
}

struct Setup {
    Vec3 spherePos{0, 0, 0};
    float sphereScale = 1.6f;
    float roughness = 0.05f;
    Walls walls = all_walls(Color{1, 0, 0, 1});
    bool probe = true;
    Vec3 probePos{0, 0, 0};  // where the probe captures
    Vec3 boxOffset{0, 0, 0};
    float blend = 1.0f;
    bool boxProjection = true;
    ProbeUpdate update = ProbeUpdate::EveryFrame;
    int spheres = 1;  // more copies of the sphere, in a row along +X from spherePos
    float spacing = 0.9f;
};

// A room of 6 m around the origin, a probe, a grey sky and a mirror sphere seen from 6 m away on +Z (the room is hidden from the camera).
void build(World& w, const Setup& s) {
    Entity cam = make(w, "cam", {s.spherePos.x, s.spherePos.y, s.spherePos.z + 6.0f});
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    c.hideTags = Json::array({"room"});
    w.settings().ambientLight = Color{0, 0, 0, 1};
    w.settings().skyColor = Color{0.2f, 0.2f, 0.2f, 1};
    w.settings().horizonColor = Color{0.2f, 0.2f, 0.2f, 1};
    add_wall(w, "px", {3, 0, 0}, {0.2f, 6.4f, 6.4f}, s.walls[0]);
    add_wall(w, "nx", {-3, 0, 0}, {0.2f, 6.4f, 6.4f}, s.walls[1]);
    add_wall(w, "py", {0, 3, 0}, {6.4f, 0.2f, 6.4f}, s.walls[2]);
    add_wall(w, "ny", {0, -3, 0}, {6.4f, 0.2f, 6.4f}, s.walls[3]);
    add_wall(w, "pz", {0, 0, 3}, {6.4f, 6.4f, 0.2f}, s.walls[4]);
    add_wall(w, "nz", {0, 0, -3}, {6.4f, 6.4f, 0.2f}, s.walls[5]);
    if (s.probe) {
        Entity probe = make(w, "probe", s.probePos);
        auto& rp = w.add<ReflectionProbe>(probe);
        rp.mode = ProbeMode::Realtime;
        rp.update = s.update;
        rp.resolution = 128;
        rp.boxSize = {6, 6, 6};
        rp.boxOffset = s.boxOffset;
        rp.blendDistance = s.blend;
        rp.boxProjection = s.boxProjection;
        rp.clear = ProbeClear::Color;
        rp.clearColor = Color{0, 0, 0, 1};
        rp.showTags = Json::array({"room"});  // the spheres are not in the capture
    }
    for (int i = 0; i < s.spheres; ++i) {
        Entity sph = make(w, "sphere", {s.spherePos.x + s.spacing * float(i), s.spherePos.y, s.spherePos.z});
        w.get<Transform>(sph)->scale = {s.sphereScale, s.sphereScale, s.sphereScale};
        auto& m = w.add<MeshRenderer>(sph);
        m.mesh = "sphere";
        m.color = Color{1, 1, 1, 1};
        m.metallic = 1.0f;
        m.roughness = s.roughness;
        m.castShadows = false;
    }
}

Entity first_sphere(World& w) { return w.find("sphere"); }

// The pixels of the middle of the sphere: its centre and a few around it, averaged (a probe's map is bilinear, so one pixel is enough but a
// mean is steadier).
Color middle(const Image& img) {
    float r = 0, g = 0, b = 0;
    int n = 0;
    for (int dy = -3; dy <= 3; dy += 3)
        for (int dx = -3; dx <= 3; dx += 3) {
            const Color c = img.pixel(img.width / 2 + dx, img.height / 2 + dy);
            r += c.r;
            g += c.g;
            b += c.b;
            ++n;
        }
    return Color{r / float(n), g / float(n), b / float(n), 1};
}

// How much the colour varies over the disc of the sphere (the sum of the standard deviations of the three channels).
float spread(const Image& img) {
    std::vector<Color> px;
    for (int dy = -16; dy <= 16; dy += 2)
        for (int dx = -16; dx <= 16; dx += 2)
            if (dx * dx + dy * dy <= 16 * 16) px.push_back(img.pixel(img.width / 2 + dx, img.height / 2 + dy));
    double mean[3] = {0, 0, 0};
    for (const Color& c : px) {
        mean[0] += c.r;
        mean[1] += c.g;
        mean[2] += c.b;
    }
    for (double& m : mean) m /= double(px.size());
    double var[3] = {0, 0, 0};
    for (const Color& c : px) {
        var[0] += (c.r - mean[0]) * (c.r - mean[0]);
        var[1] += (c.g - mean[1]) * (c.g - mean[1]);
        var[2] += (c.b - mean[2]) * (c.b - mean[2]);
    }
    double s = 0;
    for (double v : var) s += std::sqrt(v / double(px.size()));
    return float(s);
}

}  // namespace

// ---------------------------------------------------------------------------------------------------- CPU tests

TEST_CASE("pick_probes: a point is reflected by the probes whose box holds it, best first, at most two") {
    const std::vector<ProbeVolume> none;
    CHECK_FALSE(pick_probes(none, {0, 0, 0}).any());
    CHECK(pick_probes(none, {0, 0, 0}).key() == 0);

    // One box of 6 m with a band of 2 m.
    const std::vector<ProbeVolume> one = {volume(1, {0, 0, 0}, {3, 3, 3}, 2.0f)};
    ProbePick deep = pick_probes(one, {0, 0, 0});
    REQUIRE(deep.any());
    CHECK(deep.index[0] == 1);
    CHECK(deep.index[1] == 0);
    CHECK(deep.steps[0] == kProbeShareSteps);
    float shares[2];
    deep.shares(shares);
    CHECK(shares[0] == doctest::Approx(1.0f));
    CHECK(shares[1] == 0.0f);

    CHECK_FALSE(pick_probes(one, {3.5f, 0, 0}).any());  // outside
    CHECK_FALSE(pick_probes(one, {0, -3.01f, 0}).any());
    // 1 m from the +X face of a band of 2 m: half the weight, quantised to 1/32.
    const ProbePick half = pick_probes(one, {2.0f, 0, 0});
    REQUIRE(half.any());
    CHECK(half.steps[0] == 16);
    half.shares(shares);
    CHECK(shares[0] == doctest::Approx(0.5f));
    // On the face: weight 0 does not reach the point.
    CHECK_FALSE(pick_probes(one, {3.0f, 0, 0}).any());
    // The nearest face counts, along any axis.
    CHECK(pick_probes(one, {0, 2.0f, 0}).steps[0] == 16);
    CHECK(pick_probes(one, {0, 0, -2.0f}).steps[0] == 16);

    // Quantised: a point a hair deeper gives the same pick, so the meshes of a row of crates share one draw.
    CHECK(pick_probes(one, {2.0f, 0, 0}).key() == pick_probes(one, {2.004f, 0, 0}).key());
    CHECK(pick_probes(one, {2.0f, 0, 0}).key() != pick_probes(one, {1.5f, 0, 0}).key());
    // A zero band is a hard edge.
    const std::vector<ProbeVolume> hard = {volume(1, {0, 0, 0}, {3, 3, 3}, 0.0f)};
    CHECK(pick_probes(hard, {2.99f, 0, 0}).steps[0] == kProbeShareSteps);
}

TEST_CASE("pick_probes: importance, then the smaller box, then the nearer capture, then the id; the first at full "
          "weight drops the second") {
    // Two boxes that overlap around the origin: A is bigger and more important than B; C is a second B-sized box.
    const ProbeVolume big = volume(10, {0, 0, 0}, {4, 4, 4}, 1.0f, 5);
    const ProbeVolume small = volume(11, {0, 0, 0}, {2, 2, 2}, 1.0f, 0);
    {
        const std::vector<ProbeVolume> v = {small, big};
        const ProbePick p = pick_probes(v, {0, 0, 0});
        CHECK(p.index[0] == 2);  // importance wins over the smaller box
        CHECK(p.steps[0] == kProbeShareSteps);
        CHECK(p.index[1] == 0);  // the first holds the whole light
    }
    {
        // Same importance: the smaller box first. At 0.5 m inside the small box's face the small one has weight 0.5, the big one the rest.
        const ProbeVolume a = volume(10, {0, 0, 0}, {4, 4, 4}, 1.0f, 0);
        const ProbeVolume b = volume(11, {0, 0, 0}, {2, 2, 2}, 1.0f, 0);
        const std::vector<ProbeVolume> v = {a, b};
        const ProbePick p = pick_probes(v, {1.5f, 0, 0});
        CHECK(p.index[0] == 2);
        CHECK(p.steps[0] == 16);
        CHECK(p.index[1] == 1);
        CHECK(p.steps[1] == kProbeShareSteps);
        float s[2];
        p.shares(s);
        CHECK(s[0] == doctest::Approx(0.5f));
        CHECK(s[1] == doctest::Approx(0.5f));  // the shares and the sky's (0 here) add up to 1
        CHECK(s[0] + s[1] <= 1.0f + 1.0e-6f);
        // The order of the list does not change the pick.
        const std::vector<ProbeVolume> rev = {b, a};
        const ProbePick q = pick_probes(rev, {1.5f, 0, 0});
        CHECK(q.index[0] == 1);  // the same probe (b), at its new index
        CHECK(q.index[1] == 2);
        CHECK(q.steps[0] == p.steps[0]);
        CHECK(q.steps[1] == p.steps[1]);
    }
    {
        // Same importance and size: the nearer capture position, then the smaller id.
        const ProbeVolume a = volume(20, {0, 0, 0}, {3, 3, 3}, 1.0f, 0, {2, 0, 0});
        const ProbeVolume b = volume(21, {0, 0, 0}, {3, 3, 3}, 1.0f, 0, {-0.5f, 0, 0});
        const std::vector<ProbeVolume> v = {a, b};
        CHECK(pick_probes(v, {0, 0, 0}).index[0] == 2);
        const ProbeVolume c = volume(5, {0, 0, 0}, {3, 3, 3}, 1.0f, 0, {0.5f, 0, 0});
        const ProbeVolume d = volume(4, {0, 0, 0}, {3, 3, 3}, 1.0f, 0, {-0.5f, 0, 0});
        const std::vector<ProbeVolume> w = {c, d};
        CHECK(pick_probes(w, {0, 0, 0}).index[0] == 2);  // the same distance: id 4 before id 5
    }
    {
        // More than two reach the point: the best two are kept.
        std::vector<ProbeVolume> v;
        for (int i = 0; i < 5; ++i) v.push_back(volume(std::uint64_t(30 + i), {0, 0, 0}, {3, 3, 3}, 6.0f, i));
        const ProbePick p = pick_probes(v, {0, 0, 0});
        CHECK(p.index[0] == 5);   // importance 4
        CHECK(p.steps[0] == 16);  // 3 m deep over a band of 6 m
        CHECK(p.index[1] == 4);
    }
}

TEST_CASE("pick_probes: a turned box is tested along its own axes, and a NaN position picks nothing") {
    // A box of 2 m x 2 m (in x, z) turned 45 degrees about Y. Along its own axes (1, 0, 0) is 0.71 from the centre, (1.3, 0, 0) 0.92 (both
    // inside), (1.5, 0, 0) 1.06 and (1, 0, 1) 1.41 (outside); an unturned box of the same size would not hold (1.3, 0, 0).
    const std::vector<ProbeVolume> v = {volume(1, {0, 0, 0}, {1, 1, 1}, 0.0f, 0, {0, 0, 0}, true)};
    CHECK(pick_probes(v, {0.7f, 0, 0.7f}).any());
    CHECK(pick_probes(v, {1.0f, 0, 0}).any());
    CHECK(pick_probes(v, {1.3f, 0, 0}).any());
    CHECK(pick_probes(v, {0.0f, 0, 1.0f}).any());
    CHECK_FALSE(pick_probes(v, {1.5f, 0, 0}).any());
    CHECK_FALSE(pick_probes(v, {1.0f, 0, 1.0f}).any());
    const std::vector<ProbeVolume> straight = {volume(1, {0, 0, 0}, {1, 1, 1}, 0.0f)};
    CHECK_FALSE(pick_probes(straight, {1.3f, 0, 0}).any());
    CHECK_FALSE(pick_probes(v, {std::nanf(""), 0, 0}).any());
    CHECK_FALSE(pick_probes(v, {0, INFINITY, 0}).any());
}

TEST_CASE("pick_probes: at most 511 volumes are looked at") {
    std::vector<ProbeVolume> v;
    for (int i = 0; i < 600; ++i)
        v.push_back(volume(std::uint64_t(i + 1), {1000.0f * float(i), 0, 0}, {1, 1, 1}, 0.0f));
    CHECK(pick_probes(v, {1000.0f * 10, 0, 0}).index[0] == 11);
    CHECK_FALSE(pick_probes(v, {1000.0f * 550, 0, 0}).any());  // the 551st is past the cap
}

// ---------------------------------------------------------------------------------------------------- GPU tests

TEST_CASE(
    "probe sampling: a mirror sphere inside a red probe's box reflects it, outside every box it reflects the sky") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    for (const bool rgba8 : {false, true}) {
        INFO("atlas: " << (rgba8 ? "RGBA8" : "RGBA16F or the GPU's best"));
        std::unique_ptr<ForceRgba8> force;
        if (rgba8) force = std::make_unique<ForceRgba8>();
        Own o(g);
        REQUIRE(o.ok);
        Setup in;
        World wi;
        build(wi, in);
        const Image inside = o.settled(wi);
        const Color ci = middle(inside);
        INFO("inside: " << ci.r << " " << ci.g << " " << ci.b);
        CHECK(ci.r > 0.4f);
        CHECK(ci.g < 0.12f);
        CHECK(ci.b < 0.12f);
        CHECK(ci.r > 4.0f * ci.g);
        // The report says which probe the sphere reflected and that the sky has no share.
        const Json mine = o.r.probe_mesh_report(first_sphere(wi));
        INFO("report: " << mine.dump());
        REQUIRE(mine["probes"].size() == 1);
        CHECK(mine["probes"][0]["entity"] == wi.id_of(wi.find("probe")));
        CHECK(mine["probes"][0]["share"].get<double>() == doctest::Approx(1.0));
        CHECK(mine["sky"].get<double>() == doctest::Approx(0.0));

        // The same sphere 20 m away (the camera follows): the sky's grey, no red.
        Setup out = in;
        out.spherePos = {20, 0, 0};
        World wo;
        build(wo, out);
        const Image outside = o.settled(wo);
        const Color co = middle(outside);
        INFO("outside: " << co.r << " " << co.g << " " << co.b);
        CHECK(co.g > 0.04f);  // the sky, not black
        CHECK(std::fabs(co.r - co.g) < 0.04f);
        CHECK(std::fabs(co.b - co.g) < 0.04f);
        const Json away = o.r.probe_mesh_report(first_sphere(wo));
        CHECK(away["probes"].empty());
        CHECK(away["sky"].get<double>() == doctest::Approx(1.0));
    }
}

TEST_CASE(
    "probe sampling: in the blend band the probe and the sky mix, and the mix follows the distance to the box's face") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own o(g);
    REQUIRE(o.ok);
    auto red_at = [&](float x, Json* report) {
        Setup s;
        s.blend = 2.0f;
        s.spherePos = {x, 0, 0};
        World w;
        build(w, s);
        const Image img = o.settled(w);
        if (report) *report = o.r.probe_mesh_report(first_sphere(w));
        return middle(img);
    };
    Json deepReport, midReport, edgeReport;
    const Color deep = red_at(0.0f, &deepReport);   // 3 m from the face: all probe
    const Color mid = red_at(2.0f, &midReport);     // 1 m of a band of 2 m: half and half
    const Color edge = red_at(2.75f, &edgeReport);  // 0.25 m: an eighth probe
    INFO("deep " << deep.r << " " << deep.g << ", mid " << mid.r << " " << mid.g << ", edge " << edge.r << " "
                 << edge.g);
    CHECK(deepReport["probes"][0]["share"].get<double>() == doctest::Approx(1.0));
    REQUIRE(midReport["probes"].size() == 1);
    CHECK(midReport["probes"][0]["share"].get<double>() == doctest::Approx(0.5));
    CHECK(midReport["sky"].get<double>() == doctest::Approx(0.5));
    CHECK(edgeReport["probes"][0]["share"].get<double>() == doctest::Approx(0.125));
    // The red falls and the green (the sky's grey) rises as the sphere nears the face.
    CHECK(deep.r > mid.r + 0.03f);
    CHECK(mid.r > edge.r + 0.03f);
    CHECK(mid.g > deep.g + 0.02f);
    CHECK(edge.g > mid.g + 0.01f);
}

TEST_CASE("probe sampling: the box projection moves the reflection") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own o(g);
    REQUIRE(o.ok);
    // The probe captures from the -X end of the room while its box is the whole room; the sphere is 4.5 m from the capture, near the +X wall.
    // Without the projection a reflection is read in its own direction from the capture; with it, toward the point where the ray meets the box.
    auto picture = [&](bool projection) {
        Setup s;
        s.walls = kRainbow;
        s.probePos = {-2.5f, 0, 0};
        s.boxOffset = {2.5f, 0, 0};
        s.spherePos = {2.0f, 0, 0};
        s.boxProjection = projection;
        World w;
        build(w, s);
        return o.settled(w);
    };
    const Image with = picture(true);
    const Image without = picture(false);
    const ImageDiff d = diff_images(with, without, 0.15f);
    INFO("differing pixels " << d.differingPixels << ", max " << d.maxError);
    CHECK(d.differingPixels >= 12);
    CHECK(d.maxError > 0.4);
    // The picture is the same twice.
    CHECK(diff_images(with, picture(true), 0.0f).maxError == 0.0);
}

TEST_CASE("probe sampling: a rough sphere reflects a blurrier probe than a mirror") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own o(g);
    REQUIRE(o.ok);
    auto picture = [&](float roughness) {
        Setup s;
        s.walls = kRainbow;
        s.roughness = roughness;
        World w;
        build(w, s);
        return o.settled(w);
    };
    const Image mirror = picture(0.05f);
    const Image rough = picture(0.9f);
    const float sm = spread(mirror), sr = spread(rough);
    INFO("spread: mirror " << sm << ", rough " << sr);
    CHECK(sm > 0.15f);  // the room's colours show on the mirror
    CHECK(sr < 0.6f * sm);
}

TEST_CASE(
    "probe sampling: a probe out of reach changes nothing, a scene with no probe is the sky-only frame byte for byte") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own o(g);
    REQUIRE(o.ok);
    Setup plain;
    plain.probe = false;
    plain.walls = kRainbow;
    World a;
    build(a, plain);
    const Image none = o.settled(a);
    // The same scene with a probe whose box is 50 m away from the sphere: the sphere reflects the sky exactly as before.
    Setup far = plain;
    far.probe = true;
    far.probePos = {-50, 0, 0};
    far.boxOffset = {0, 0, 0};
    World b;
    build(b, far);
    const Image away = o.settled(b);
    const ImageDiff d = diff_images(none, away, 0.0f);
    INFO("differing pixels " << d.differingPixels << ", max " << d.maxError);
    CHECK(d.sameSize);
    CHECK(d.maxError == 0.0);
    // And a fresh renderer that has never seen a probe draws the same bytes as the one that has.
    Own fresh(g);
    REQUIRE(fresh.ok);
    World c;
    build(c, plain);
    CHECK(diff_images(none, fresh.settled(c), 0.0f).maxError == 0.0);
    // Its sky is not black.
    CHECK(middle(none).g > 0.04f);
}

TEST_CASE("probe sampling: the probe a sphere reflects does not split its batch, and a band of weights adds a few "
          "draws, not one per mesh") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own o(g);
    REQUIRE(o.ok);
    auto draws = [&](bool probe, float x0, int spheres, bool across = false) {
        Setup s;
        s.probe = probe;
        s.spheres = spheres;
        s.spherePos = {x0, 0, 0};
        s.sphereScale = 0.3f;
        s.spacing = across ? 0.9f : 0.4f;
        s.blend = 1.0f;
        s.update = ProbeUpdate::
            OnDemand;  // captured once: the capture faces are not in the draw calls of the frames that follow
        World w;
        build(w, s);
        o.settled(w, 3);
        return o.r.stats().drawCalls;
    };
    // Eight spheres deep inside the box (weight 1 for all) draw as many calls as with no probe at all.
    const int plain = draws(false, -1.4f, 8);
    const int withProbe = draws(true, -1.4f, 8);
    INFO("no probe " << plain << ", probe " << withProbe);
    CHECK(withProbe == plain);
    // Spheres across the blend band get one weight each (0.9 m apart over a band of 1 m): never more draws than meshes.
    const int across = draws(true, 1.0f, 8, true);
    CHECK(across <= plain + 8);
    // More spheres in the same weight do not add draws.
    CHECK(draws(true, -1.4f, 4) == draws(false, -1.4f, 4));
}
