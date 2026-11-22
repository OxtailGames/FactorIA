// M75.2: occlusion culling on the CPU, the rasterizer (src/occlusion.h; docs/BIG_WORLDS.md, "Occlusion"). No GPU: these run where
// `ctest -LE gpu` does. The buffer must never hide what can be seen (checked against a brute-force ray test on hundreds of random
// boxes), must handle the near plane and a camera inside an occluder, must give the same buffer with any number of job threads, and its
// caps count triangles and say what they cut.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <memory>
#include <string>
#include <vector>

#include "fa/core/jobs.h"

#include "occlusion.h"

using namespace fa;
using namespace fa::render;

namespace {

struct Cam {
    OcclusionCamera cam;
    int w = 0, h = 0;
};

// A perspective camera at `eye` looking at `target`, 60 degrees, 16:9, near 0.1.
Cam persp(Vec3 eye, Vec3 target, bool z01, float nearPlane = 0.1f) {
    Cam c;
    const Mat4 proj = Mat4::perspective(60.0f, 16.0f / 9.0f, nearPlane, 500.0f, z01);
    c.cam.viewProj = proj * Mat4::look_at(eye, target);
    c.cam.position = eye;
    c.cam.forward = normalize(target - eye);
    c.cam.perspective = true;
    c.cam.zeroToOne = z01;
    occlusion_size_for(16.0f / 9.0f, c.w, c.h);
    return c;
}

Cam ortho_cam(Vec3 eye, Vec3 target, bool z01) {
    Cam c;
    const Mat4 proj = Mat4::ortho(-16.0f, 16.0f, -9.0f, 9.0f, 0.1f, 500.0f, z01);
    c.cam.viewProj = proj * Mat4::look_at(eye, target);
    c.cam.position = eye;
    c.cam.forward = normalize(target - eye);
    c.cam.perspective = false;
    c.cam.zeroToOne = z01;
    occlusion_size_for(16.0f / 9.0f, c.w, c.h);
    return c;
}

OccluderSource box_at(Vec3 center, Vec3 size, std::uint64_t entity = 1) {
    OccluderSource s;
    s.model = Mat4::translate(center);
    s.boxMin = size * -0.5f;
    s.boxMax = size * 0.5f;
    s.entity = entity;
    return s;
}

bool hidden_box(const OcclusionBuffer& b, Vec3 center, Vec3 size) {
    return b.hidden(size * -0.5f, size * 0.5f, Mat4::translate(center));
}

OcclusionBuffer make_buffer(const Cam& c, const std::vector<OccluderSource>& occluders,
                            OcclusionRasterStats* out = nullptr, const OcclusionLimits& limits = {}) {
    OcclusionBuffer b;
    b.reset(c.cam, c.w, c.h);
    const OcclusionRasterStats st = b.rasterize(occluders, limits);
    if (out) *out = st;
    return b;
}

// A quad in the XY plane, 1 m * 1 m, counter-clockwise seen from +Z (the side the default camera sees).
std::shared_ptr<const MeshGeometry> quad_mesh() {
    auto m = std::make_shared<MeshGeometry>();
    m->positions = {{-0.5f, -0.5f, 0}, {0.5f, -0.5f, 0}, {0.5f, 0.5f, 0}, {-0.5f, 0.5f, 0}};
    m->indices = {0, 1, 2, 0, 2, 3};
    m->bmin = {-0.5f, -0.5f, 0};
    m->bmax = {0.5f, 0.5f, 0};
    return m;
}

// A strip of n quads (2n triangles), 1 m tall and n m wide, in the XY plane.
std::shared_ptr<const MeshGeometry> strip_mesh(int n) {
    auto m = std::make_shared<MeshGeometry>();
    for (int i = 0; i <= n; ++i) {
        m->positions.push_back({float(i), 0, 0});
        m->positions.push_back({float(i), 1, 0});
    }
    for (int i = 0; i < n; ++i) {
        const std::uint32_t a = std::uint32_t(2 * i);
        for (std::uint32_t k : {a, a + 2, a + 3, a, a + 3, a + 1}) m->indices.push_back(k);
    }
    m->bmin = {0, 0, 0};
    m->bmax = {float(n), 1, 0};
    return m;
}

// A deterministic spread of numbers: item i, salt s, in [0, 1).
float frac(int i, int salt) {
    const unsigned h = unsigned(i) * 2654435761u + unsigned(salt) * 40503u + 12345u;
    return float((h >> 8) & 0xffff) / 65536.0f;
}

// True when the ray from `from` to `to` crosses the axis-aligned box `lo..hi` before it reaches `to`.
bool segment_hits_box(Vec3 from, Vec3 to, Vec3 lo, Vec3 hi) {
    const Vec3 d = to - from;
    float t0 = 0.0f, t1 = 1.0f;
    const float o[3] = {from.x, from.y, from.z}, dir[3] = {d.x, d.y, d.z}, l[3] = {lo.x, lo.y, lo.z},
                h[3] = {hi.x, hi.y, hi.z};
    for (int a = 0; a < 3; ++a) {
        if (std::fabs(dir[a]) < 1e-9f) {
            if (o[a] < l[a] || o[a] > h[a]) return false;
            continue;
        }
        float ta = (l[a] - o[a]) / dir[a], tb = (h[a] - o[a]) / dir[a];
        if (ta > tb) std::swap(ta, tb);
        t0 = std::max(t0, ta);
        t1 = std::min(t1, tb);
        if (t0 > t1) return false;
    }
    return true;
}

}  // namespace

TEST_CASE("occlusion: the buffer is 256 cells across and 256 / aspect down, clamped") {
    int w = 0, h = 0;
    occlusion_size_for(16.0f / 9.0f, w, h);
    CHECK(w == 256);
    CHECK(h == 144);
    occlusion_size_for(1.0f, w, h);
    CHECK(h == 256);
    occlusion_size_for(100.0f, w, h);
    CHECK(h == kOcclusionMinHeight);
    occlusion_size_for(0.05f, w, h);
    CHECK(h == kOcclusionMaxHeight);
    occlusion_size_for(std::nanf(""), w, h);
    CHECK(h == 256);
}

TEST_CASE("occlusion: a box behind a wall is hidden, one beside it, in front of it or partly behind it is not") {
    for (bool z01 : {false, true}) {
        CAPTURE(z01);
        const Cam c = persp({0, 2, 10}, {0, 2, 0}, z01);
        OcclusionRasterStats st;
        const OcclusionBuffer b = make_buffer(c, {box_at({0, 2, 0}, {6, 6, 1})}, &st);
        CHECK(st.occluders == 1);
        CHECK(st.sourceTriangles == 12);
        CHECK(st.frontTriangles == 2);  // only the face that looks at the camera is drawn
        CHECK(st.coveredCells > 500);
        CHECK(hidden_box(b, {0, 2, -20}, {2, 2, 2}));           // straight behind
        CHECK(hidden_box(b, {5, 1, -20}, {3, 3, 2}));           // inside the cone of the wall's edges
        CHECK_FALSE(hidden_box(b, {0, 2, 5}, {1, 1, 1}));       // in front of the wall
        CHECK_FALSE(hidden_box(b, {40, 2, -20}, {2, 2, 2}));    // far to the side
        CHECK_FALSE(hidden_box(b, {9.5f, 2, -20}, {5, 2, 2}));  // half in, half out of the wall's shadow
        CHECK_FALSE(hidden_box(b, {0, 30, -20}, {2, 2, 2}));    // above it
        // A box whose near face is nearer than the wall is not behind it, however much of it is covered.
        CHECK_FALSE(hidden_box(b, {0, 2, 0.3f}, {2, 2, 1.2f}));
    }
}

TEST_CASE("occlusion: an occluder never hides a box that touches it from the front, and a thin gap shows") {
    const Cam c = persp({0, 2, 10}, {0, 2, 0}, false);
    // Two walls with a gap of 3 m between them: what is seen through the gap is visible.
    const OcclusionBuffer b = make_buffer(c, {box_at({-4.5f, 2, 0}, {6, 6, 1}, 1), box_at({4.5f, 2, 0}, {6, 6, 1}, 2)});
    CHECK_FALSE(hidden_box(b, {0, 2, -10}, {1, 1, 1}));
    CHECK(hidden_box(b, {-12, 2, -20}, {2, 2, 2}));
    CHECK(hidden_box(b, {12, 2, -20}, {2, 2, 2}));
}

TEST_CASE("occlusion: a box that crosses the near plane, holds the camera or is behind it is visible") {
    for (bool z01 : {false, true}) {
        CAPTURE(z01);
        const Cam c = persp({0, 2, 10}, {0, 2, 0}, z01);
        // A huge wall further down: it covers the whole picture, so only the rules of the near plane keep these visible.
        const OcclusionBuffer b = make_buffer(c, {box_at({0, 2, 0}, {200, 200, 1})});
        CHECK(hidden_box(b, {0, 2, -30}, {2, 2, 2}));
        CHECK_FALSE(hidden_box(b, {0, 2, 10}, {2, 2, 2}));        // holds the camera
        CHECK_FALSE(hidden_box(b, {3, 2, 9.9f}, {2, 2, 2}));      // crosses the near plane (z = 9.9)
        CHECK_FALSE(hidden_box(b, {0, 2, 20}, {2, 2, 2}));        // behind the camera
        CHECK_FALSE(hidden_box(b, {0, 2, 10.2f}, {0.2f, 2, 3}));  // behind, reaching to the near plane
        // An occluder that crosses the near plane is drawn clipped, and still hides what lies behind it.
        // (x from 0.5 to 4, z from 9 to 11: the camera, at x = 0, is outside it.)
        const OcclusionBuffer c2 = make_buffer(c, {box_at({2.25f, 2, 10}, {3.5f, 4, 2})});
        CHECK(hidden_box(c2, {14, 2, -10}, {2, 2, 2}));
    }
}

TEST_CASE("occlusion: a camera inside an occluder gets no occlusion from it") {
    const Cam c = persp({0, 2, 10}, {0, 2, 0}, false);
    OcclusionRasterStats st;
    const OcclusionBuffer b = make_buffer(c, {box_at({0, 2, 10}, {30, 30, 30})}, &st);
    CHECK(st.frontTriangles == 0);  // every face looks away from the camera
    CHECK(st.coveredCells == 0);
    CHECK_FALSE(hidden_box(b, {0, 2, -20}, {2, 2, 2}));
    CHECK_FALSE(hidden_box(b, {0, 2, 5}, {2, 2, 2}));
}

TEST_CASE("occlusion: a mesh occluder hides by its front faces, also mirrored, and a back face hides nothing") {
    const Cam c = persp({0, 2, 10}, {0, 2, 0}, false);
    const Vec3 behind{0, 2, -10};
    OccluderSource front;
    front.model = Mat4::translate({0, 2, 0}) * Mat4::scale({12, 12, 1});
    front.mesh = quad_mesh();
    front.boxMin = front.mesh->bmin;
    front.boxMax = front.mesh->bmax;
    OcclusionRasterStats st;
    OcclusionBuffer b = make_buffer(c, {front}, &st);
    CHECK(st.sourceTriangles == 2);
    CHECK(st.frontTriangles == 2);
    CHECK(hidden_box(b, behind, {2, 2, 2}));
    CHECK_FALSE(hidden_box(b, {30, 2, -10}, {2, 2, 2}));
    // Turned around: the quad shows its back to the camera.
    OccluderSource back = front;
    back.model = Mat4::translate({0, 2, 0}) * Mat4::rotate_y_deg(180.0f) * Mat4::scale({12, 12, 1});
    b = make_buffer(c, {back}, &st);
    CHECK(st.frontTriangles == 0);
    CHECK_FALSE(hidden_box(b, behind, {2, 2, 2}));
    // Mirrored (a negative scale flips the winding, the face still looks at the camera).
    OccluderSource mirrored = front;
    mirrored.model = Mat4::translate({0, 2, 0}) * Mat4::scale({-12, 12, 1});
    b = make_buffer(c, {mirrored}, &st);
    CHECK(st.frontTriangles == 2);
    CHECK(hidden_box(b, behind, {2, 2, 2}));
    // Rotated 180 degrees and mirrored: the front of the mirrored quad looks away from the camera.
    OccluderSource both = back;
    both.model = Mat4::translate({0, 2, 0}) * Mat4::rotate_y_deg(180.0f) * Mat4::scale({-12, 12, 1});
    b = make_buffer(c, {both}, &st);
    CHECK(st.frontTriangles == 0);
    CHECK_FALSE(hidden_box(b, behind, {2, 2, 2}));
}

TEST_CASE("occlusion: an orthographic camera culls by the same rules") {
    for (bool z01 : {false, true}) {
        CAPTURE(z01);
        const Cam c = ortho_cam({0, 2, 10}, {0, 2, 0}, z01);
        const OcclusionBuffer b = make_buffer(c, {box_at({0, 2, 0}, {10, 6, 1})});
        CHECK(hidden_box(b, {0, 2, -20}, {2, 2, 2}));
        CHECK(hidden_box(b, {3, 3, -20}, {2, 2, 2}));
        CHECK_FALSE(hidden_box(b, {12, 2, -20}, {2, 2, 2}));
        CHECK_FALSE(hidden_box(b, {4, 7, -20}, {2, 2, 2}));
        CHECK_FALSE(hidden_box(b, {0, 2, 5}, {2, 2, 2}));
    }
}

TEST_CASE("occlusion: soundness, nothing the brute-force ray test can see is ever reported hidden") {
    for (bool z01 : {false, true}) {
        CAPTURE(z01);
        const Vec3 eye{0, 3, 20};
        const Cam c = persp(eye, {0, 3, 0}, z01);
        // 6 random occluder boxes of 1 to 8 m, between 14 and 26 m from the camera.
        std::vector<OccluderSource> occ;
        std::vector<std::pair<Vec3, Vec3>> aabbs;
        for (int i = 0; i < 6; ++i) {
            const Vec3 size{1.0f + 7.0f * frac(i, 1), 1.0f + 7.0f * frac(i, 2), 1.0f + 3.0f * frac(i, 3)};
            const Vec3 center{-14.0f + 28.0f * frac(i, 4), 0.5f + 8.0f * frac(i, 5), 6.0f - 12.0f * frac(i, 6)};
            occ.push_back(box_at(center, size, std::uint64_t(i + 1)));
            aabbs.push_back({center - size * 0.5f, center + size * 0.5f});
        }
        const OcclusionBuffer b = make_buffer(c, occ);
        int hiddenCount = 0, tested = 0;
        for (int i = 0; i < 400; ++i) {
            const Vec3 size{0.3f + 4.0f * frac(i, 11), 0.3f + 4.0f * frac(i, 12), 0.3f + 4.0f * frac(i, 13)};
            const Vec3 center{-20.0f + 40.0f * frac(i, 14), 0.0f + 10.0f * frac(i, 15), 4.0f - 40.0f * frac(i, 16)};
            const Vec3 lo = center - size * 0.5f, hi = center + size * 0.5f;
            ++tested;
            if (!b.hidden(size * -0.5f, size * 0.5f, Mat4::translate(center))) continue;
            ++hiddenCount;
            // Every point of the box must lie behind an occluder: 9 x 9 x 9 samples of its volume.
            for (int x = 0; x < 9; ++x)
                for (int y = 0; y < 9; ++y)
                    for (int z = 0; z < 9; ++z) {
                        const Vec3 p{lo.x + (hi.x - lo.x) * float(x) / 8.0f, lo.y + (hi.y - lo.y) * float(y) / 8.0f,
                                     lo.z + (hi.z - lo.z) * float(z) / 8.0f};
                        bool covered = false;
                        for (const auto& a : aabbs)
                            if (segment_hits_box(eye, p, a.first, a.second)) covered = true;
                        INFO("box " << i << " point " << p.x << " " << p.y << " " << p.z);
                        REQUIRE(covered);
                    }
        }
        CHECK(tested == 400);
        CHECK(hiddenCount > 5);    // the test is meaningful: some boxes are hidden
        CHECK(hiddenCount < 380);  // and some are not
    }
}

TEST_CASE("occlusion: the buffer is the same bytes with the pool stopped, inline and with 1, 2 and 8 workers") {
    const Cam c = persp({0, 6, 30}, {0, 3, 0}, false);
    // 150 boxes (1800 triangles, above the parallel threshold) and a mesh with 600 triangles.
    std::vector<OccluderSource> occ;
    for (int i = 0; i < 150; ++i) {
        const Vec3 size{1.0f + 5.0f * frac(i, 21), 1.0f + 5.0f * frac(i, 22), 1.0f + 2.0f * frac(i, 23)};
        const Vec3 center{-30.0f + 60.0f * frac(i, 24), 0.5f + 12.0f * frac(i, 25), 10.0f - 30.0f * frac(i, 26)};
        occ.push_back(box_at(center, size, std::uint64_t(i + 1)));
    }
    OccluderSource strip;
    strip.mesh = strip_mesh(300);
    strip.model = Mat4::translate({-20, 0, 12}) * Mat4::scale({0.12f, 4, 1});
    strip.entity = 999;
    occ.push_back(strip);
    CHECK(occ.size() * 12 > kParallelOcclusionTriangles);

    struct Mode {
        const char* name;
        bool start;
        jobs::Settings settings;
    };
    std::vector<Mode> modes{{"stopped", false, {}}, {"inline", true, jobs::Settings::inline_jobs()}};
    if (jobs::threads_supported()) {
        modes.push_back({"1 worker", true, jobs::Settings::threads(1)});
        modes.push_back({"2 workers", true, jobs::Settings::threads(2)});
        modes.push_back({"8 workers", true, jobs::Settings::threads(8)});
    }
    std::vector<float> reference;
    std::vector<std::uint8_t> referenceGrey;
    OcclusionRasterStats referenceStats;
    std::vector<char> referenceHidden;
    bool haveReference = false;
    for (const Mode& m : modes) {
        CAPTURE(m.name);
        if (m.start) {
            auto r = jobs::start(m.settings);
            REQUIRE_MESSAGE(r.ok(), (r.ok() ? std::string() : r.error().to_string()));
        }
        OcclusionRasterStats st;
        const OcclusionBuffer b = make_buffer(c, occ, &st);
        std::vector<float> cells;
        for (int y = 0; y < b.height(); ++y)
            for (int x = 0; x < b.width(); ++x) cells.push_back(b.nearness(x, y));
        std::vector<char> hid;
        for (int i = 0; i < 100; ++i)
            hid.push_back(b.hidden({-1, -1, -1}, {1, 1, 1},
                                   Mat4::translate({-30.0f + 60.0f * frac(i, 31), 12.0f * frac(i, 32),
                                                    -10.0f - 40.0f * frac(i, 33)}))
                              ? 1
                              : 0);
        const std::vector<std::uint8_t> grey = b.grey();
        if (m.start) jobs::stop();
        CHECK(st.coveredCells > 1000);
        CHECK(st.sourceTriangles == 150 * 12 + 600);
        if (!haveReference) {
            reference = cells;
            referenceGrey = grey;
            referenceStats = st;
            referenceHidden = hid;
            haveReference = true;
            continue;
        }
        REQUIRE(cells.size() == reference.size());
        CHECK(std::memcmp(cells.data(), reference.data(), cells.size() * sizeof(float)) == 0);
        CHECK(grey == referenceGrey);
        CHECK(hid == referenceHidden);
        CHECK(st.coveredCells == referenceStats.coveredCells);
        CHECK(st.frontTriangles == referenceStats.frontTriangles);
        CHECK(st.occluders == referenceStats.occluders);
    }
    CHECK(std::count(referenceHidden.begin(), referenceHidden.end(), char(1)) > 0);
}

TEST_CASE("occlusion: the caps count triangles, keep the first occluders and name what was cut") {
    const Cam c = persp({0, 2, 30}, {0, 2, 0}, false);
    // The defaults are far above a normal scene.
    CHECK(kMaxOccluderTriangles >= 4096);
    CHECK(kMaxOcclusionTriangles >= 65536);
    {
        // A mesh of 100 triangles with a cap of 10 per occluder: the first 10 go on, one occluder is reported capped.
        OccluderSource s;
        s.mesh = strip_mesh(50);
        s.entity = 7;
        s.model = Mat4::translate({-20, 0, 0});
        OcclusionLimits limits;
        limits.perOccluder = 10;
        OcclusionRasterStats st;
        make_buffer(c, {s}, &st, limits);
        CHECK(st.sourceTriangles == 10);
        CHECK(st.occludersCapped == 1);
        REQUIRE(st.cappedEntities.size() == 1);
        CHECK(st.cappedEntities[0] == 7);
        CHECK(st.occludersDropped == 0);
        // Under the cap nothing is reported.
        make_buffer(c, {s}, &st);
        CHECK(st.sourceTriangles == 100);
        CHECK(st.occludersCapped == 0);
    }
    {
        // Five boxes (60 triangles) with 30 for the whole camera: the first two go on whole, the third is cut, the rest are left out.
        std::vector<OccluderSource> occ;
        for (int i = 0; i < 5; ++i)
            occ.push_back(box_at({float(i) * 3.0f - 6.0f, 2, 0}, {2, 2, 2}, std::uint64_t(i + 1)));
        OcclusionLimits limits;
        limits.perFrame = 30;
        OcclusionRasterStats st;
        make_buffer(c, occ, &st, limits);
        CHECK(st.sourceTriangles == 30);
        CHECK(st.occluders == 3);
        CHECK(st.occludersDropped == 3);
        REQUIRE(st.droppedEntities.size() == 3);
        CHECK(st.droppedEntities[0] == 3);
        CHECK(st.droppedEntities[2] == 5);
    }
    {
        // What the caps leave out only ever hides less: the box behind the dropped occluder stays visible.
        std::vector<OccluderSource> occ{box_at({0, 2, 5}, {2, 2, 2}, 1), box_at({0, 2, 0}, {20, 20, 1}, 2)};
        OcclusionLimits limits;
        limits.perFrame = 12;
        OcclusionRasterStats st;
        const OcclusionBuffer b = make_buffer(c, occ, &st, limits);
        CHECK(st.occludersDropped == 1);
        CHECK_FALSE(hidden_box(b, {5, 2, -20}, {2, 2, 2}));
        const OcclusionBuffer full = make_buffer(c, occ, &st);
        CHECK(hidden_box(full, {5, 2, -20}, {2, 2, 2}));
    }
}

TEST_CASE("occlusion: degenerate input is safe") {
    const Cam c = persp({0, 2, 10}, {0, 2, 0}, false);
    OccluderSource flat = box_at({0, 2, 0}, {0, 0, 0});  // a zero box: nothing to draw, nothing to crash
    OccluderSource inverted = box_at({0, 2, 0}, {-4, -4, -4});
    OccluderSource empty;
    empty.mesh = std::make_shared<MeshGeometry>();
    OccluderSource bad;
    bad.mesh = quad_mesh();
    bad.model = Mat4::translate({0, 2, 0}) * Mat4::scale({1e30f, 1e30f, 1});  // huge but finite
    OcclusionRasterStats st;
    const OcclusionBuffer b = make_buffer(c, {flat, inverted, empty, bad}, &st);
    CHECK(b.ready());
    // A box with no extent is never a reason to hide anything; huge ones are clipped, not looped over.
    CHECK_FALSE(hidden_box(b, {0, 2, 5}, {1, 1, 1}));
    // A buffer that was never reset hides nothing.
    const OcclusionBuffer none;
    CHECK_FALSE(none.ready());
    CHECK_FALSE(none.hidden({-1, -1, -1}, {1, 1, 1}, Mat4::translate({0, 0, -5})));
}
