// M75.2: the Hi-Z pyramid and the test of a box against it (src/hiz.h; docs/BIG_WORLDS_LOD.md, "Occlusion"). Pure code, no GPU: a wall hides a
// box behind it, the camera's move widens the footprint, a cut or a zoom culls nothing, a hole in a cell proves nothing, and a brute-force
// ray test over hundreds of random boxes and moves finds no box hidden that a ray from the new camera can reach.
#include <doctest.h>

#include <cmath>
#include <cstdint>
#include <vector>

#include "hiz.h"

using namespace fa;
using namespace fa::render;

namespace {

constexpr float kAspect = 16.0f / 9.0f;

HizPose pose_at(Vec3 eye, Vec3 target, float fov = 60.0f) {
    const Mat4 proj = Mat4::perspective(fov, kAspect, 0.1f, 500.0f, false);
    return hiz_pose(proj, proj * Mat4::look_at(eye, target), eye);
}

// The wall: the rectangle |x| < 5, |y| < 3 on the plane z = -10, seen from the origin. A cell is covered when its four corners and its
// centre are inside the wall's picture (a convex shape: then the whole cell is), else it shows no mesh in some pixel.
struct Scene {
    HizPyramid pyr;
    HizPose hist;
    int w = 0, h = 0;
};

Scene wall_scene(Vec3 eye = {0, 0, 0}, float holeX = -1, float holeY = -1) {
    Scene s;
    hiz_size_for(kAspect, s.w, s.h);
    s.hist = pose_at(eye, eye + Vec3{0, 0, -1});
    std::vector<float> cells(std::size_t(s.w) * std::size_t(s.h) * 2, kHizNoDepth);
    auto covered = [&](float cx, float cy) {  // a point of the picture in cells -> is the wall there
        const float nx = cx / float(s.w) * 2.0f - 1.0f, ny = 1.0f - cy / float(s.h) * 2.0f;
        const float tanY = 1.0f / s.hist.p11, tanX = 1.0f / s.hist.p00;
        const float wx = nx * tanX * 10.0f + eye.x,
                    wy = ny * tanY * 10.0f + eye.y;  // where the ray from the eye meets the wall plane
        return std::fabs(wx) < 5.0f && std::fabs(wy) < 3.0f;
    };
    for (int y = 0; y < s.h; ++y)
        for (int x = 0; x < s.w; ++x) {
            bool all = true;
            for (float oy : {0.0f, 0.5f, 1.0f})
                for (float ox : {0.0f, 0.5f, 1.0f}) all = all && covered(float(x) + ox, float(y) + oy);
            if (all && !(float(x) == holeX && float(y) == holeY)) {
                float* c = &cells[(std::size_t(y) * std::size_t(s.w) + std::size_t(x)) * 2];
                c[0] = c[1] = 10.0f - eye.z;
            }
        }
    REQUIRE(s.pyr.build(s.w, s.h, cells.data(), cells.size()));
    return s;
}

Mat4 at(Vec3 c) { return Mat4::translate(c); }
const Vec3 kUnit{-0.5f, -0.5f, -0.5f}, kUnit2{0.5f, 0.5f, 0.5f};

}  // namespace

TEST_CASE("hiz: the size follows the aspect, like the CPU buffer") {
    int w = 0, h = 0;
    hiz_size_for(16.0f / 9.0f, w, h);
    CHECK(w == 256);
    CHECK(h == 144);
    hiz_size_for(1.0f, w, h);
    CHECK(h == 256);
    hiz_size_for(0.001f, w, h);  // a nonsense aspect
    CHECK(h == 256);
    hiz_size_for(100.0f, w, h);
    CHECK(h == kHizMinHeight);
    hiz_size_for(0.25f, w, h);
    CHECK(h == kHizMaxHeight);
}

TEST_CASE("hiz: the chain takes the nearest and the farthest, and a cell with no mesh proves nothing") {
    // 5 x 3 cells (odd sizes): nearest 1..15, farthest 2..16; one cell shows no mesh.
    std::vector<float> cells;
    for (int i = 0; i < 15; ++i) {
        cells.push_back(float(i + 1));
        cells.push_back(float(i + 2));
    }
    HizPyramid p;
    CHECK_FALSE(p.build(5, 3, cells.data(), cells.size() - 1));  // the wrong count
    CHECK_FALSE(p.ready());
    REQUIRE(p.build(5, 3, cells.data(), cells.size()));
    REQUIRE(p.levels() == 4);  // 5x3, 3x2, 2x1, 1x1
    CHECK(p.width(1) == 3);
    CHECK(p.height(1) == 2);
    CHECK(p.width(3) == 1);
    CHECK(p.cell(3, 0, 0).nearest == 1.0f);
    CHECK(p.cell(3, 0, 0).farthest == 16.0f);
    CHECK(p.cell(1, 0, 0).nearest == 1.0f);   // cells (0,0) (1,0) (0,1) (1,1)
    CHECK(p.cell(1, 0, 0).farthest == 8.0f);  // the children 2, 3, 7 and 8
    cells[3] = kHizNoDepth;                   // cell 1: no mesh
    REQUIRE(p.build(5, 3, cells.data(), cells.size()));
    CHECK(p.cell(3, 0, 0).farthest >= kHizNoDepth);  // the hole reaches the top: never "all covered"
    CHECK(p.covered_cells() == 14);
    const std::vector<std::uint8_t> g = p.grey(0);
    REQUIRE(g.size() == 15);
    CHECK(g[1] == 0);
    CHECK(g[0] > 55);
    CHECK(p.grey(9).empty());
    cells[0] = std::nanf("");
    REQUIRE(p.build(5, 3, cells.data(), cells.size()));
    CHECK(p.cell(0, 0, 0).nearest >= kHizNoDepth);  // a NaN is "no mesh"
}

TEST_CASE("hiz: a wall hides the box behind it, not the one in front or beside it") {
    const Scene s = wall_scene();
    HizTestInfo info;
    // Behind the wall and inside its shadow.
    CHECK(hiz_hidden(s.pyr, s.hist, s.hist, kUnit, kUnit2, at({0, 0, -20}), &info));
    CHECK(info.why == HizTestInfo::Why::Hidden);
    CHECK(info.boxNear > 19.0f);
    CHECK(info.occluderFar == doctest::Approx(10.0f));
    // In front of it.
    CHECK_FALSE(hiz_hidden(s.pyr, s.hist, s.hist, kUnit, kUnit2, at({0, 0, -5}), &info));
    CHECK(info.why == HizTestInfo::Why::Visible);
    // Beside the wall (outside its picture).
    CHECK_FALSE(hiz_hidden(s.pyr, s.hist, s.hist, kUnit, kUnit2, at({12, 0, -20}), &info));
    CHECK(info.why == HizTestInfo::Why::NoOccluder);
    // Half behind the wall: a cell of the picture of the box shows no mesh.
    CHECK_FALSE(hiz_hidden(s.pyr, s.hist, s.hist, kUnit, kUnit2, at({5.5f, 0, -10.5f}), &info));
    // A box inside the wall's plane is not behind it (the nearest corner is at 9.5).
    CHECK_FALSE(hiz_hidden(s.pyr, s.hist, s.hist, kUnit, kUnit2, at({0, 0, -10}), &info));
}

TEST_CASE("hiz: a hole in one cell of the wall's picture lets the box behind it show") {
    // The box at depth 20 covers the cells around the middle of the picture; one of them shows no mesh.
    Scene probe = wall_scene();
    HizTestInfo info;
    REQUIRE(hiz_hidden(probe.pyr, probe.hist, probe.hist, kUnit, kUnit2, at({0, 0, -20}), &info));
    const Scene holed = wall_scene({0, 0, 0}, float((info.x0 + info.x1) / 2), float((info.y0 + info.y1) / 2));
    CHECK_FALSE(hiz_hidden(holed.pyr, holed.hist, holed.hist, kUnit, kUnit2, at({0, 0, -20}), &info));
    CHECK(info.why == HizTestInfo::Why::NoOccluder);
}

TEST_CASE("hiz: the camera's move widens the footprint, a cut and a zoom cull nothing") {
    const Scene s = wall_scene();
    // The box is hidden with no move, with a small one, and visible once the camera could see around the wall's edge.
    const Mat4 nearEdge = at({4.2f, 0, -20});  // the wall's edge at x = 5 is at x = 10 at depth 20
    HizTestInfo still, small;
    CHECK(hiz_hidden(s.pyr, s.hist, s.hist, kUnit, kUnit2, nearEdge, &still));
    CHECK(still.dilate == 0);
    const HizPose moved = pose_at({0.05f, 0, 0}, {0.05f, 0, -1});
    CHECK(hiz_hidden(s.pyr, s.hist, moved, kUnit, kUnit2, at({0, 0, -20}), &small));
    CHECK(small.dilate >= 1);
    CHECK(small.dilate > still.dilate);
    // A move of a few metres: the footprint would need more than kHizMaxDilate cells.
    HizTestInfo far;
    const HizPose jumped = pose_at({30, 0, 0}, {30, 0, -1});
    CHECK_FALSE(hiz_hidden(s.pyr, s.hist, jumped, kUnit, kUnit2, at({0, 0, -20}), &far));
    CHECK(far.why == HizTestInfo::Why::TooMuchMotion);
    // A zoom is a cut.
    const HizPose zoom = pose_at({0, 0, 0}, {0, 0, -1}, 40.0f);
    CHECK_FALSE(hiz_hidden(s.pyr, s.hist, zoom, kUnit, kUnit2, at({0, 0, -20}), &far));
    CHECK(far.why == HizTestInfo::Why::Cut);
    // No pose, no pyramid.
    CHECK_FALSE(hiz_hidden(s.pyr, HizPose{}, s.hist, kUnit, kUnit2, at({0, 0, -20}), &far));
    CHECK_FALSE(hiz_hidden(HizPyramid{}, s.hist, s.hist, kUnit, kUnit2, at({0, 0, -20}), &far));
    CHECK(far.why == HizTestInfo::Why::NoPyramid);
}

TEST_CASE("hiz: a box the old picture does not show entirely is not culled") {
    const Scene s = wall_scene();
    HizTestInfo info;
    // Behind the old camera.
    CHECK_FALSE(hiz_hidden(s.pyr, s.hist, s.hist, kUnit, kUnit2, at({0, 0, 5}), &info));
    CHECK(info.why == HizTestInfo::Why::BehindNear);
    // The camera inside the box.
    CHECK_FALSE(hiz_hidden(s.pyr, s.hist, s.hist, {-1, -1, -1}, {1, 1, 1}, at({0, 0, 0}), &info));
    CHECK(info.why == HizTestInfo::Why::BehindNear);
    // Far off to the side: outside the old picture.
    CHECK_FALSE(hiz_hidden(s.pyr, s.hist, s.hist, kUnit, kUnit2, at({200, 0, -20}), &info));
    CHECK(info.why == HizTestInfo::Why::OutsideView);
    // Hugely wide: crosses the border of the picture.
    CHECK_FALSE(hiz_hidden(s.pyr, s.hist, s.hist, {-80, -1, -1}, {80, 1, 1}, at({0, 0, -20}), &info));
    CHECK(info.why == HizTestInfo::Why::OutsideView);
    // A NaN box.
    CHECK_FALSE(hiz_hidden(s.pyr, s.hist, s.hist, {std::nanf(""), 0, 0}, {1, 1, 1}, at({0, 0, -20}), &info));
}

TEST_CASE("hiz: the level read grows with the box, and at most 3 x 3 cells are read") {
    const Scene s = wall_scene();
    HizTestInfo small, big;
    CHECK(hiz_hidden(s.pyr, s.hist, s.hist, {-0.05f, -0.05f, -0.05f}, {0.05f, 0.05f, 0.05f}, at({0, 0, -30}), &small));
    CHECK(hiz_hidden(s.pyr, s.hist, s.hist, {-3, -2, -1}, {3, 2, 1}, at({0, 0, -30}), &big));
    CHECK(small.level <= 1);
    CHECK(big.level > small.level);
    for (const HizTestInfo* i : {&small, &big}) {
        const int cells = std::max(i->x1 - i->x0 + 1, i->y1 - i->y0 + 1);
        CHECK(((cells >> i->level) <= 2));
        CHECK((i->x1 >> i->level) - (i->x0 >> i->level) + 1 <= 3);
    }
}

// The proof: whatever the camera did within a small move, a box the test calls hidden cannot be reached by a ray from the new camera
// that misses the wall. The wall is the only thing in the scene, so "reached" is "the ray from the camera to the point passes outside
// the wall's rectangle".
TEST_CASE("hiz: no box is called hidden that a ray from the moved camera reaches") {
    const Scene s = wall_scene();
    std::uint32_t rng = 12345;
    auto rnd = [&](float lo, float hi) {
        rng = rng * 1664525u + 1013904223u;
        return lo + (hi - lo) * float(rng >> 8) / float(1u << 24);
    };
    int hiddenCount = 0, tested = 0;
    for (int n = 0; n < 4000; ++n) {
        const Vec3 move{rnd(-0.6f, 0.6f), rnd(-0.6f, 0.6f), rnd(-0.6f, 0.6f)};
        const Vec3 eye = move;
        const HizPose now = pose_at(eye, eye + Vec3{0, 0, -1});
        const Vec3 half{rnd(0.1f, 3.0f), rnd(0.1f, 3.0f), rnd(0.1f, 3.0f)};
        const Vec3 c{rnd(-9.0f, 9.0f), rnd(-6.0f, 6.0f), rnd(-40.0f, -10.5f)};
        ++tested;
        if (!hiz_hidden(s.pyr, s.hist, now, half * -1.0f, half, at(c))) continue;
        ++hiddenCount;
        for (int k = 0; k < 27; ++k) {
            const Vec3 p{c.x + half.x * float(k % 3 - 1), c.y + half.y * float((k / 3) % 3 - 1),
                         c.z + half.z * float(k / 9 - 1)};
            const float t = (-10.0f - eye.z) / (p.z - eye.z);
            const Vec3 hit = eye + (p - eye) * t;
            INFO("box " << c.x << " " << c.y << " " << c.z << " half " << half.x << " " << half.y << " " << half.z
                        << " move " << move.x << " " << move.y << " " << move.z);
            // The ray is blocked: it crosses the wall's plane inside the rectangle (the point is behind the plane: t < 1).
            CHECK(t < 1.0f);
            CHECK(std::fabs(hit.x) < 5.0f);
            CHECK(std::fabs(hit.y) < 3.0f);
        }
    }
    // The test is not vacuous: many of the boxes are hidden, and many are not.
    CHECK(hiddenCount > 100);
    CHECK(hiddenCount < tested);
}
