// M75-P1a: the pure selection of a level of detail (by distance or screen size, for a MeshRenderer and for a LodGroup) and the cross-fade
// state. No GPU: the renderer calls these functions per entity per frame (engine/render/src/renderer_draw.cpp, gather_meshes).
#include <doctest.h>

#include <cmath>
#include <limits>

#include "fa/core/json.h"
#include "fa/scene/lod.h"

using namespace fa;

namespace {
Json J(const char* text) { return Json::parse(text); }

MeshRenderer by_size() {
    MeshRenderer mr;
    mr.mesh = "tree.glb";
    mr.lodMode = LodMode::ScreenSize;
    mr.lods = J(R"([{"mesh":"tree.lod1.glb","screenSize":0.5},{"mesh":"tree.lod2.glb","screenSize":0.2},{"mesh":"tree.lod3.glb","screenSize":0.05}])");
    return mr;
}
}  // namespace

TEST_CASE("lod: the screen size of a sphere is its diameter over the height of the view") {
    LodView persp;
    persp.fovY = 90.0f;  // tan(45 deg) = 1: the view is 2 * distance tall
    CHECK(lod_view_height(persp, 10.0f) == doctest::Approx(20.0f));
    CHECK(lod_screen_size(10.0f, 10.0f, persp) == doctest::Approx(0.5f));
    CHECK(lod_screen_size(10.0f, 20.0f, persp) == doctest::Approx(0.25f));
    // orthographic: the distance does not matter
    LodView ortho;
    ortho.perspective = false;
    ortho.halfHeight = 5.0f;
    CHECK(lod_screen_size(2.0f, 1.0f, ortho) == doctest::Approx(0.2f));
    CHECK(lod_screen_size(2.0f, 500.0f, ortho) == doctest::Approx(0.2f));
    // a camera inside the sphere is clamped, never a division by zero; a bad diameter counts as 0
    CHECK(std::isfinite(lod_screen_size(1.0f, 0.0f, persp)));
    CHECK(lod_screen_size(1.0f, 0.0f, persp) > 100.0f);
    CHECK(lod_screen_size(-1.0f, 5.0f, persp) == 0.0f);
    CHECK(lod_screen_size(std::numeric_limits<float>::quiet_NaN(), 5.0f, persp) == 0.0f);
}

TEST_CASE("lod: MeshRenderer.lods by screen size, thresholds are strict and the smallest one reached wins") {
    const MeshRenderer mr = by_size();
    CHECK(lod_level_by_screen_size(mr, 0.9f) == 0);
    CHECK(lod_level_by_screen_size(mr, 0.5f) == 0);  // not BELOW 0.5
    CHECK(lod_level_by_screen_size(mr, 0.4999f) == 1);
    CHECK(lod_level_by_screen_size(mr, 0.2f) == 1);
    CHECK(lod_level_by_screen_size(mr, 0.1f) == 2);
    CHECK(lod_level_by_screen_size(mr, 0.049f) == 3);
    CHECK(lod_level_by_screen_size(mr, 0.0f) == 3);
    CHECK(lod_level_by_screen_size(mr, std::numeric_limits<float>::quiet_NaN()) == 0);
    CHECK(lod_level_mesh(mr, 0) == "tree.glb");
    CHECK(lod_level_mesh(mr, 2) == "tree.lod2.glb");
    CHECK(lod_level_mesh(mr, 9) == "tree.glb");  // no such entry
    CHECK(lod_level_mesh(mr, -1) == "tree.glb");
}

TEST_CASE("lod: lodMode chooses the metric, and an entry without the field of the mode is ignored") {
    MeshRenderer mr = by_size();
    CHECK(lod_level_of(mr, 1000.0f, 0.3f) == 1);  // screen size mode: the distance is not read
    mr.lodMode = LodMode::Distance;
    CHECK(lod_level_of(mr, 1000.0f, 0.3f) == 0);  // the entries have no `distance`
    mr.lods = J(R"([{"mesh":"a.glb","distance":10,"screenSize":0.4},{"mesh":"b.glb","distance":30},{"screenSize":0.1},7])");
    CHECK(lod_level_of(mr, 15.0f, 0.0f) == 1);
    CHECK(lod_level_of(mr, 40.0f, 0.0f) == 2);
    mr.lodMode = LodMode::ScreenSize;
    CHECK(lod_level_of(mr, 0.0f, 0.3f) == 1);
    CHECK(lod_level_of(mr, 0.0f, 0.9f) == 0);  // b.glb has no screenSize; the entry with only a screenSize has no mesh
    mr.lods = J(R"({"not":"a list"})");
    CHECK(lod_level_of(mr, 99.0f, 0.0f) == 0);
}

TEST_CASE("lod: distance mode picks the same mesh as lod_mesh, whatever the levels' order") {
    MeshRenderer mr;
    mr.mesh = "m0";
    mr.lods = J(R"([{"mesh":"m30","distance":30},{"mesh":"m10","distance":10},{"mesh":"mx","distance":"far"},{"mesh":"m20","distance":20}])");
    for (float d : {0.0f, 9.99f, 10.0f, 19.9f, 20.0f, 29.9f, 30.0f, 31.0f, 1e9f})
        CHECK(lod_level_mesh(mr, lod_level_by_distance(mr, d)) == lod_mesh(mr, d));
}

TEST_CASE("lod: a LodGroup picks the child by its thresholds in either unit") {
    LodGroup g;
    g.thresholds.push_back(10.0f);
    g.thresholds.push_back(30.0f);
    CHECK(lod_group_level(g, 3, 0.0f) == 0);
    CHECK(lod_group_level(g, 3, 9.99f) == 0);
    CHECK(lod_group_level(g, 3, 10.0f) == 1);
    CHECK(lod_group_level(g, 3, 30.0f) == 2);
    CHECK(lod_group_level(g, 3, 1e9f) == 2);
    CHECK(lod_group_level(g, 2, 1e9f) == 1);  // fewer children than thresholds + 1
    CHECK(lod_group_level(g, 1, 1e9f) == 0);
    CHECK(lod_group_level(g, 0, 5.0f) == -1);
    CHECK(lod_group_level(g, 3, std::numeric_limits<float>::quiet_NaN()) == 0);
    LodGroup s;
    s.mode = LodMode::ScreenSize;
    s.thresholds.push_back(0.3f);
    s.thresholds.push_back(0.1f);
    CHECK(lod_group_level(s, 3, 0.9f) == 0);
    CHECK(lod_group_level(s, 3, 0.3f) == 0);
    CHECK(lod_group_level(s, 3, 0.29f) == 1);
    CHECK(lod_group_level(s, 3, 0.05f) == 2);
    LodGroup none;
    CHECK(lod_group_level(none, 4, 1e9f) == 0);  // no thresholds: the first child always
}

TEST_CASE("lod: a cross-fade of one second advances by dt and ends exactly once") {
    LodFadeState s;
    lod_fade_step(s, 0, 1.0f, 0.1f);
    CHECK_FALSE(s.fading());
    CHECK(lod_fade_amount(s) == 0.0f);
    lod_fade_step(s, 1, 1.0f, 0.25f);  // the level changes: the fade starts and this frame counts
    CHECK(s.level == 1);
    CHECK(s.from == 0);
    CHECK(s.fading());
    CHECK(s.t == doctest::Approx(0.25f));
    CHECK(lod_fade_amount(s) == doctest::Approx(0.25f));
    int frames = 1;
    while (s.fading() && frames < 100) {
        lod_fade_step(s, 1, 1.0f, 0.25f);
        ++frames;
    }
    CHECK(frames == 4);
    CHECK(s.level == 1);
    CHECK(s.from == -1);
    CHECK(lod_fade_amount(s) == 0.0f);
    lod_fade_step(s, 1, 1.0f, 0.25f);  // settled: nothing moves
    CHECK_FALSE(s.fading());
}

TEST_CASE("lod: no cross-fade time is a hard switch, and a bad dt or time never starts a runaway") {
    for (float crossFade : {0.0f, -1.0f, std::numeric_limits<float>::quiet_NaN()}) {
        LodFadeState s;
        lod_fade_step(s, 2, crossFade, 0.1f);
        CHECK(s.level == 2);
        CHECK_FALSE(s.fading());
    }
    LodFadeState s;
    lod_fade_step(s, 1, 0.5f, std::numeric_limits<float>::quiet_NaN());  // a NaN dt counts as 0: the fade waits at its start
    CHECK(s.fading());
    CHECK(s.t == 0.0f);
    CHECK(lod_fade_amount(s) == doctest::Approx(1.0f / 256.0f));  // never fully empty
    lod_fade_step(s, 1, 0.5f, -3.0f);
    CHECK(s.t == 0.0f);
    lod_fade_step(s, 1, 0.5f, 100.0f);  // a long frame finishes the fade, it does not overshoot
    CHECK_FALSE(s.fading());
    // turning the cross-fade off during a fade ends it
    lod_fade_step(s, 2, 1.0f, 0.1f);
    CHECK(s.fading());
    lod_fade_step(s, 2, 0.0f, 0.1f);
    CHECK_FALSE(s.fading());
    CHECK(s.level == 2);
}

TEST_CASE("lod: going back during a fade reverses it where it is, and a third level cuts it") {
    LodFadeState s;
    lod_fade_step(s, 0, 1.0f, 0.1f);
    lod_fade_step(s, 1, 1.0f, 0.3f);  // 0 -> 1 at t = 0.3
    REQUIRE(s.fading());
    lod_fade_step(s, 0, 1.0f, 0.1f);  // back to 0: level 0 is now fading in from where it stood (0.7), plus this frame
    CHECK(s.level == 0);
    CHECK(s.from == 1);
    CHECK(s.t == doctest::Approx(0.8f));
    LodFadeState c;
    lod_fade_step(c, 0, 1.0f, 0.1f);
    lod_fade_step(c, 1, 1.0f, 0.3f);
    lod_fade_step(c, 2, 1.0f, 0.1f);  // 1 -> 2: the fade from 0 is dropped, level 1 leaves
    CHECK(c.level == 2);
    CHECK(c.from == 1);
    CHECK(c.t == doctest::Approx(0.1f));
}
