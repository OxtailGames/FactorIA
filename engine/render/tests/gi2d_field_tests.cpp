// M74-P3a: the 2D GI field (engine/render/src/gi2d.h, docs/design/ARCHITECTURE_RENDERING_GI2D.md). Pure tests of the geometry (sizes, snapping,
// caps) and of the polygon cutting, then tests that draw a scene on the host's GPU and read the field's images back:
//   - the emission image holds what glows (an emissive sprite, a Light2D disc) and nothing elsewhere;
//   - the occluder image holds the shadow casters and the solid tiles, and its alpha is the occupancy;
//   - the distance image (jump flooding) agrees with a brute-force search of the occupied texels, within 1.5 texels;
//   - a camera that moves by less than a texel leaves the field where it was, and a larger move shifts it by whole texels;
//   - without GlobalIllumination2D (or with enabled = false) the frame has no gi pass and no field keeps an image.
// The tolerances hold on llvmpipe and WARP as well as on a real GPU; no golden image is compared.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <limits>
#include <string>
#include <vector>

#include "fa/core/fs.h"
#include "fa/scene/tilemap.h"
#include "frame_graph.h"
#include "gi2d.h"
#include "render_internal.h"
#include "renderer_test_access.h"

using namespace fa;
using namespace fa::test;
using namespace fa::render;

namespace {

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
    }
    ~Own() { r.shutdown(); }
    Own(const Own&) = delete;
    Own& operator=(const Own&) = delete;
    void frame(World& w) {
        r.begin_frame();
        r.render_world(w, 0.0f);
        r.end_frame();
        g.gpu.end_frame();
    }
    bool gi_ready() { return Gi2dSystem::float_targets_ok(); }
};

int gi_passes(Own& o) {
    const FrameGraph* graph = renderer_frame_graph(o.r);
    int n = 0;
    if (!graph) return 0;
    for (const std::string& name : graph->order_names())
        if (name.find("/gi-") != std::string::npos) ++n;
    return n;
}

// Passes a field of `w` x `h` texels draws: emission, occluders, the seed, the step of 1 and one step for each power of two below the size.
int expected_passes(int w, int h) {
    const int n = std::max(w, h);
    int p = 1;
    while (p * 2 < n) p *= 2;
    int steps = 1;
    for (int s = p; s >= 1; s /= 2) ++steps;
    return 3 + steps;
}

Entity camera_at(World& w, Vec3 pos) {
    Entity e = make(w, "cam", pos);
    w.add<Camera>(e).clearColor = Color{0, 0, 0, 1};
    return e;
}

void add_gi2d(World& w, float range, float scale) {
    Entity e = make(w, "gi", {0, 0, 0});
    auto& gi = w.add<GlobalIllumination2D>(e);
    gi.range = range;
    gi.resolutionScale = scale;
}

void write_white() {
    Image white;
    white.width = white.height = 16;
    white.rgba.assign(16 * 16 * 4, 255);
    REQUIRE(save_png(white, "assets/white16.png").ok());
}

// The scene of the content tests, seen by the default camera (320 x 180 world units around the origin, one unit a pixel): a red glowing
// sprite 20 x 20 at (-60, 20), a blue Light2D at (60.5, 20.5), a shadow-casting box 30 x 10 at (0, -40) and a wall of three solid tiles.
void content_world(World& w, float range = 32.0f, float scale = 1.0f) {
    write_white();
    camera_at(w, {0, 0, 0});
    add_gi2d(w, range, scale);
    Entity glow = make(w, "glow", {-60, 20, 0});
    auto& s = w.add<Sprite>(glow);
    s.texture = "assets/white16.png";
    s.size = {20, 20};
    s.lit = true;
    s.emissive = Color{1, 0, 0, 1};
    s.emissiveIntensity = 2.0f;
    Entity lamp = make(w, "lamp", {60.5f, 20.5f, 0});
    auto& l = w.add<Light2D>(lamp);
    l.color = Color{0, 0, 1, 1};
    l.intensity = 3.0f;
    Entity box = make(w, "box", {0, -40, 0});
    auto& sc = w.add<ShadowCaster2D>(box);
    sc.shape = ShadowCaster2DShape::Box;
    sc.size = {30, 10};
    Entity map = make(w, "wall", {-110, -50, 0});
    auto& tm = w.add<Tilemap>(map);
    tm.tileset = "assets/white16.png";
    tm.tileSize = {16, 16};
    Json rows = Json::array();
    for (int r = 0; r < 3; ++r) rows.push_back(Json::array({0}));
    set_tilemap_tiles(tm, rows);
    tm.solidTiles = Json::array({0});
    tm.occludesLight = true;
}

struct FieldImage {
    std::vector<float> px;  // RGBA floats, row 0 = the smallest world y
    int w = 0, h = 0;
    double texel = 1.0, ox = 0.0, oy = 0.0;
    const float* at(int i, int j) const { return &px[(std::size_t(j) * std::size_t(w) + std::size_t(i)) * 4]; }
    // The texel that holds the world point.
    int tx(double wx) const { return int(std::floor((wx - ox) / texel)); }
    int ty(double wy) const { return int(std::floor((wy - oy) / texel)); }
};

bool read_field(Own& o, int which, FieldImage& out) {
    const Gi2dFieldInfo info = renderer_gi2d_info(o.r, 0);
    if (!info.ready) return false;
    out.w = info.width;
    out.h = info.height;
    out.texel = info.texel;
    out.ox = info.originX;
    out.oy = info.originY;
    std::string error;
    const bool ok = renderer_gi2d_read(o.r, 0, which, out.px, &error);
    INFO("read error: " << error);
    return ok && out.px.size() == std::size_t(out.w) * std::size_t(out.h) * 4;
}

}  // namespace

TEST_CASE("gi2d geometry: the size depends on the view and the settings, never on where the camera is") {
    Gi2dSettings s;
    s.on = true;
    s.range = 32.0f;
    s.resolutionScale = 1.0f;
    const Gi2dGeometry a = gi2d_geometry(Rect{-160, -90, 320, 180}, 1.0f, s);
    REQUIRE(a.valid);
    CHECK(a.width == 386);  // ceil((320 + 64) / 1) + 2
    CHECK(a.height == 246);
    CHECK(a.texel == 1.0);
    CHECK(a.originX == -192.0);
    CHECK(a.originY == -122.0);
    CHECK_FALSE(a.capped);
    for (double dx : {0.0, 0.3, 17.77, -250.123, 1.0e5}) {
        const Gi2dGeometry b = gi2d_geometry(Rect{float(-160 + dx), -90, 320, 180}, 1.0f, s);
        CHECK(b.width == a.width);
        CHECK(b.height == a.height);
        CHECK(b.texel == a.texel);
        // The origin is a whole number of texels, so a camera that moves by less than one never makes the content swim.
        CHECK(std::fmod(std::fabs(b.originX), b.texel) == doctest::Approx(0.0).epsilon(1e-9));
        CHECK(b.originX <= double(float(-160 + dx)) - double(s.range) + 1e-3);
        CHECK(b.originX + b.world_w() >= double(float(-160 + dx)) + 320.0 + double(s.range) - 1e-3);
    }
    s.resolutionScale = 0.5f;
    const Gi2dGeometry half = gi2d_geometry(Rect{-160, -90, 320, 180}, 1.0f, s);
    CHECK(half.texel == 2.0);
    CHECK(half.width == 194);
    CHECK(half.height == 124);
    // The same input gives the same answer.
    const Gi2dGeometry again = gi2d_geometry(Rect{-160, -90, 320, 180}, 1.0f, s);
    CHECK(again.width == half.width);
    CHECK(again.originY == half.originY);
}

TEST_CASE("gi2d geometry: a huge range is capped at 2048 texels, a view without a size has no field") {
    Gi2dSettings s;
    s.on = true;
    s.range = 100000.0f;
    s.resolutionScale = 1.0f;
    const Gi2dGeometry g = gi2d_geometry(Rect{-160, -90, 320, 180}, 1.0f, s);
    REQUIRE(g.valid);
    CHECK(g.capped);
    CHECK(g.width <= kGi2dMaxSize);
    CHECK(g.height <= kGi2dMaxSize);
    CHECK(g.texel > 1.0);
    CHECK(g.bytes <= kGi2dMaxBytes);
    CHECK_FALSE(gi2d_geometry(Rect{0, 0, 0, 180}, 1.0f, s).valid);
    CHECK_FALSE(gi2d_geometry(Rect{0, 0, 320, 180}, 0.0f, s).valid);
    CHECK_FALSE(gi2d_geometry(Rect{0, 0, std::numeric_limits<float>::quiet_NaN(), 180}, 1.0f, s).valid);
    // A tiny view still gets the smallest field.
    s.range = 1.0f;
    const Gi2dGeometry tiny = gi2d_geometry(Rect{0, 0, 1, 1}, 1.0f, s);
    REQUIRE(tiny.valid);
    CHECK(tiny.width >= kGi2dMinSize);
}

namespace {
double polygon_area(const std::vector<Vec2>& pts, const std::vector<std::uint32_t>& tri) {
    double a = 0.0;
    for (std::size_t i = 0; i + 2 < tri.size(); i += 3) {
        const Vec2 p = pts[tri[i]], q = pts[tri[i + 1]], r = pts[tri[i + 2]];
        a += std::fabs(double(q.x - p.x) * double(r.y - p.y) - double(r.x - p.x) * double(q.y - p.y)) * 0.5;
    }
    return a;
}
}  // namespace

TEST_CASE("gi2d triangulation: either winding, a concave polygon and degenerate input") {
    const std::vector<Vec2> square = {{0, 0}, {2, 0}, {2, 2}, {0, 2}};
    std::vector<Vec2> reversed(square.rbegin(), square.rend());
    CHECK(gi2d_triangulate(square).size() == 6);
    CHECK(gi2d_triangulate(reversed).size() == 6);
    // An L: three unit squares, six corners, four triangles.
    const std::vector<Vec2> ell = {{0, 0}, {2, 0}, {2, 1}, {1, 1}, {1, 2}, {0, 2}};
    const std::vector<std::uint32_t> t = gi2d_triangulate(ell);
    CHECK(t.size() == 12);
    CHECK(polygon_area(ell, t) == doctest::Approx(3.0));
    std::vector<Vec2> ellReversed(ell.rbegin(), ell.rend());
    const std::vector<std::uint32_t> t2 = gi2d_triangulate(ellReversed);
    CHECK(t2.size() == 12);
    CHECK(polygon_area(ellReversed, t2) == doctest::Approx(3.0));
    CHECK(gi2d_triangulate({{0, 0}, {1, 1}}).empty());
    CHECK(gi2d_triangulate({{0, 0}, {1, 1}, {2, 2}}).empty());  // no area
    CHECK(gi2d_triangulate({{0, 0}, {1, 0}, {std::numeric_limits<float>::infinity(), 1}}).empty());
}

TEST_CASE("gi2d field: the emission image holds what glows, the occluder image what blocks light") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own o(g);
    REQUIRE(o.ok);
    if (!o.gi_ready()) {
        MESSAGE("no RGBA16F targets on this GPU: the field is not drawn here");
        return;
    }
    World w;
    content_world(w);
    o.frame(w);
    const Gi2dFieldInfo info = renderer_gi2d_info(o.r, 0);
    REQUIRE(info.exists);
    REQUIRE(info.ready);
    CHECK(info.width == 386);
    CHECK(info.height == 246);
    CHECK(info.emitters == 2);
    CHECK(info.occluders >= 4);  // the box and the three solid tiles
    CHECK(gi_passes(o) == expected_passes(info.width, info.height));
    CHECK(info.passes == expected_passes(info.width, info.height));

    FieldImage em;
    REQUIRE(read_field(o, 0, em));
    {
        const float* red = em.at(em.tx(-60.5), em.ty(20.5));
        CHECK(red[0] == doctest::Approx(2.0f).epsilon(0.02));
        CHECK(std::fabs(red[1]) < 0.01f);
        CHECK(std::fabs(red[2]) < 0.01f);
        const float* blue = em.at(em.tx(60.5), em.ty(20.5));
        CHECK(blue[2] == doctest::Approx(3.0f).epsilon(0.02));
        CHECK(std::fabs(blue[0]) < 0.01f);
        // Nothing glows at the centre of the view, outside the sprite and far from the lamp, nor in the margin.
        CHECK(std::fabs(em.at(em.tx(0.5), em.ty(0.5))[0]) < 0.001f);
        CHECK(std::fabs(em.at(em.tx(-180.5), em.ty(0.5))[0]) < 0.001f);
        // The sprite's square covers 20 x 20 texels (a texel is a world unit here), give or take the edge texels.
        int lit = 0;
        for (int j = 0; j < em.h; ++j)
            for (int i = 0; i < em.w; ++i) lit += em.at(i, j)[0] > 1.0f ? 1 : 0;
        CHECK(lit >= 18 * 18);
        CHECK(lit <= 22 * 22);
    }

    FieldImage occ;
    REQUIRE(read_field(o, 1, occ));
    {
        CHECK(occ.at(occ.tx(0.5), occ.ty(-40.5))[3] > 0.99f);    // inside the box
        CHECK(occ.at(occ.tx(-14.0), occ.ty(-40.5))[3] > 0.99f);  // near its left edge
        CHECK(occ.at(occ.tx(17.0), occ.ty(-40.5))[3] < 0.01f);   // right of it
        CHECK(occ.at(occ.tx(0.5), occ.ty(-30.0))[3] < 0.01f);    // above it
        int wall = 0;  // the wall of solid tiles is somewhere in x -140..-70, y -120..0
        for (int j = occ.ty(-120.0); j < occ.ty(0.0); ++j)
            for (int i = occ.tx(-140.0); i < occ.tx(-70.0); ++i) wall += occ.at(i, j)[3] > 0.5f ? 1 : 0;
        CHECK(wall >= 14 * 46);
        CHECK(occ.at(occ.tx(60.5), occ.ty(20.5))[3] < 0.01f);  // the light is not an occluder
        int occupied = 0;
        for (int j = 0; j < occ.h; ++j)
            for (int i = 0; i < occ.w; ++i) occupied += occ.at(i, j)[3] > 0.5f ? 1 : 0;
        // The box is 30 x 10 and the wall 16 x 48.
        CHECK(occupied >= 28 * 8 + 14 * 46);
        CHECK(occupied <= 32 * 12 + 18 * 50);
    }
}

TEST_CASE("gi2d field: the distance image agrees with a brute-force search") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own o(g);
    REQUIRE(o.ok);
    if (!o.gi_ready()) return;
    World w;
    content_world(w);
    o.frame(w);
    FieldImage occ, dist;
    REQUIRE(read_field(o, 1, occ));
    REQUIRE(read_field(o, 2, dist));
    std::vector<std::pair<int, int>> seeds;
    for (int j = 0; j < occ.h; ++j)
        for (int i = 0; i < occ.w; ++i)
            if (occ.at(i, j)[3] > 0.5f) seeds.emplace_back(i, j);
    REQUIRE(seeds.size() > 100);
    double worst = 0.0;
    int checked = 0, exact = 0;
    for (int j = 0; j < dist.h; j += 3) {
        for (int i = 0; i < dist.w; i += 3) {
            double best = 1e30;
            for (const auto& s : seeds) {
                const double dx = double(s.first - i), dy = double(s.second - j);
                best = std::min(best, dx * dx + dy * dy);
            }
            const float* d = dist.at(i, j);
            const double want = std::sqrt(best);
            CHECK(d[3] > 0.5f);
            worst = std::max(worst, std::fabs(double(d[2]) - want));
            ++checked;
            // The distance is stored in a half float: its step is want / 1024 at most.
            if (std::fabs(double(d[2]) - want) < 0.01 + want / 1024.0) ++exact;
            // The seed it names is a real occupied texel.
            const int sx = int(std::lround(d[0])), sy = int(std::lround(d[1]));
            REQUIRE(sx >= 0);
            REQUIRE(sy >= 0);
            REQUIRE(sx < occ.w);
            REQUIRE(sy < occ.h);
            CHECK(occ.at(sx, sy)[3] > 0.5f);
        }
    }
    INFO("worst error " << worst << " texels over " << checked << " texels");
    CHECK(worst <= 1.5);
    CHECK(exact * 100 >= checked * 95);  // jump flooding is exact at nearly every texel
    // Inside an occluder the distance is 0 and the nearest seed is the texel itself.
    const int bi = occ.tx(0.5), bj = occ.ty(-40.5);
    CHECK(std::fabs(dist.at(bi, bj)[2]) < 0.001f);
    CHECK(dist.at(bi, bj)[0] == doctest::Approx(float(bi)));
    CHECK(dist.at(bi, bj)[1] == doctest::Approx(float(bj)));
}

TEST_CASE("gi2d field: a scene with nothing that blocks light has no distance") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own o(g);
    REQUIRE(o.ok);
    if (!o.gi_ready()) return;
    World w;
    camera_at(w, {0, 0, 0});
    add_gi2d(w, 16.0f, 0.5f);
    o.frame(w);
    FieldImage dist;
    REQUIRE(read_field(o, 2, dist));
    for (int j = 0; j < dist.h; j += 7)
        for (int i = 0; i < dist.w; i += 7) {
            CHECK(dist.at(i, j)[3] == 0.0f);
            CHECK(dist.at(i, j)[2] == kGi2dNoDistance);
        }
}

TEST_CASE("gi2d field: a camera that moves less than a texel leaves the field where it was; a larger move shifts it by "
          "whole texels") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own o(g);
    REQUIRE(o.ok);
    if (!o.gi_ready()) return;
    World w;
    content_world(w);
    Entity cam = w.find("cam");
    REQUIRE(cam);
    o.frame(w);
    const Gi2dFieldInfo base = renderer_gi2d_info(o.r, 0);
    REQUIRE(base.ready);
    FieldImage emBase, occBase;
    REQUIRE(read_field(o, 0, emBase));
    REQUIRE(read_field(o, 1, occBase));
    for (Vec3 p : {Vec3{0.3f, 0.2f, 0}, Vec3{0.45f, -0.4f, 0}, Vec3{-0.1f, 0.7f, 0}}) {
        w.get<Transform>(cam)->position = p;
        o.frame(w);
        const Gi2dFieldInfo moved = renderer_gi2d_info(o.r, 0);
        INFO("camera at " << p.x << ", " << p.y);
        REQUIRE(moved.ready);
        CHECK(moved.width == base.width);
        CHECK(moved.height == base.height);
        CHECK(moved.texel == base.texel);
        // The origin stays within one texel of its first place and is a whole number of texels from it.
        const double sx = (moved.originX - base.originX) / base.texel;
        const double sy = (moved.originY - base.originY) / base.texel;
        CHECK(std::fabs(sx - std::round(sx)) < 1e-6);
        CHECK(std::fabs(sy - std::round(sy)) < 1e-6);
        CHECK(std::fabs(sx) <= 1.0);  // a move of less than a texel shifts the field by at most one texel
        CHECK(std::fabs(sy) <= 1.0);
        // The world is where it was in the field: the glow sits in the same texels whatever the camera did inside the texel.
        FieldImage em;
        REQUIRE(read_field(o, 0, em));
        const int di = int(std::lround(sx)), dj = int(std::lround(sy));
        int differing = 0;
        for (int j = 0; j < em.h; ++j)
            for (int i = 0; i < em.w; ++i) {
                const int bi = i + di, bj = j + dj;
                if (bi < 0 || bj < 0 || bi >= emBase.w || bj >= emBase.h) continue;
                if (std::fabs(em.at(i, j)[0] - emBase.at(bi, bj)[0]) > 1e-3f ||
                    std::fabs(em.at(i, j)[2] - emBase.at(bi, bj)[2]) > 1e-3f)
                    ++differing;
            }
        CHECK(differing == 0);
    }
    // A move of several texels shifts the field by that many.
    w.get<Transform>(cam)->position = {5.0f, -3.0f, 0};
    o.frame(w);
    const Gi2dFieldInfo far = renderer_gi2d_info(o.r, 0);
    REQUIRE(far.ready);
    CHECK(far.originX - base.originX == doctest::Approx(5.0).epsilon(0.25));
    CHECK(far.originY - base.originY == doctest::Approx(-3.0).epsilon(0.5));
}

TEST_CASE("gi2d field: no GlobalIllumination2D (or enabled = false) means no pass and no image") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own o(g);
    REQUIRE(o.ok);
    World w;
    content_world(w);
    Entity gi = w.find("gi");
    REQUIRE(gi);
    w.get<GlobalIllumination2D>(gi)->enabled = false;
    o.frame(w);
    CHECK(gi_passes(o) == 0);
    CHECK(renderer_gi2d_slots_in_use(o.r) == 0);
    CHECK_FALSE(renderer_gi2d_info(o.r, 0).exists);
    {
        const Json report = o.r.gi2d_field();
        REQUIRE(report.contains("fields"));
        CHECK(report["fields"].empty());
        CHECK(report.value("enabled", true) == false);
    }
    if (!o.gi_ready()) return;
    // Switched on: the passes and the images appear.
    w.get<GlobalIllumination2D>(gi)->enabled = true;
    o.frame(w);
    CHECK(gi_passes(o) > 0);
    CHECK(renderer_gi2d_slots_in_use(o.r) == 1);
    // Switched off again: the images are freed in the same frame, not kept for later.
    w.get<GlobalIllumination2D>(gi)->enabled = false;
    o.frame(w);
    CHECK(gi_passes(o) == 0);
    CHECK(renderer_gi2d_slots_in_use(o.r) == 0);
    // Removed altogether.
    w.get<GlobalIllumination2D>(gi)->enabled = true;
    o.frame(w);
    CHECK(renderer_gi2d_slots_in_use(o.r) == 1);
    w.remove<GlobalIllumination2D>(gi);
    o.frame(w);
    CHECK(gi_passes(o) == 0);
    CHECK(renderer_gi2d_slots_in_use(o.r) == 0);
}

TEST_CASE("gi2d field: the sizes are the same on every run and the report says where the field is") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own o(g);
    REQUIRE(o.ok);
    if (!o.gi_ready()) return;
    World w;
    content_world(w, 40.0f, 0.5f);
    o.frame(w);
    const Json first = o.r.gi2d_field();
    o.frame(w);
    const Json second = o.r.gi2d_field();
    REQUIRE(first.contains("fields"));
    REQUIRE(first["fields"].size() == 1);
    CHECK(first["fields"][0].dump() == second["fields"][0].dump());
    const Json& f = first["fields"][0];
    CHECK(f.value("ready", false));
    CHECK(f.value("width", 0) == 202);   // ceil((320 + 80) / 2) + 2
    CHECK(f.value("height", 0) == 132);  // ceil((180 + 80) / 2) + 2
    CHECK(f.value("texelSize", 0.0) == doctest::Approx(2.0));
    CHECK(f["worldRect"].value("width", 0.0) == doctest::Approx(404.0));
    CHECK(f["worldRect"].value("x", 0.0) == doctest::Approx(-200.0));
    CHECK(first.value("supported", false));
}

TEST_CASE("gi2d field: the command's report writes the three images as PNG files") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own o(g);
    REQUIRE(o.ok);
    if (!o.gi_ready()) return;
    World w;
    content_world(w);
    o.frame(w);
    const std::filesystem::path dir = g.projectDir / "gi2d_out";
    std::filesystem::create_directories(dir);
    const std::string prefix = fs::path_to_utf8(dir / fs::path_from_utf8("field"));
    const Json report = o.r.gi2d_field(prefix);
    INFO("report: " << report.dump());
    CHECK_FALSE(report.contains("error"));
    REQUIRE(report.contains("files"));
    REQUIRE(report["files"].size() == 3);
    for (const char* name : {"emission", "occluders", "distance"}) {
        const std::string path = prefix + "-" + name + ".png";
        auto img = load_image(path);
        REQUIRE(img.ok());
        CHECK(img.value().width == 386);
        CHECK(img.value().height == 246);
    }
    // Row 0 of a PNG is the largest world y: the glowing sprite (y = 20) is above the box (y = -40).
    auto em = load_image(prefix + "-emission.png");
    auto oc = load_image(prefix + "-occluders.png");
    REQUIRE(em.ok());
    REQUIRE(oc.ok());
    const int cx = int(std::floor(-60.5 + 192.0)), glowRow = 246 - 1 - int(std::floor(20.5 + 122.0));
    CHECK(em.value().pixel(cx, glowRow).r > 0.9f);
    const int boxRow = 246 - 1 - int(std::floor(-40.5 + 122.0));
    CHECK(oc.value().pixel(int(std::floor(0.5 + 192.0)), boxRow).a > 0.9f);
    // A job that does not exist is an error that says so; nothing is written for it.
    const Json bad = o.r.gi2d_field(prefix + "-x", "camera:9");
    CHECK(bad.contains("error"));
    CHECK_FALSE(std::filesystem::exists(fs::path_from_utf8(prefix + "-x-emission.png")));
}
