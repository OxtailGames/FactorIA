// M75.2: area and portal culling, the pure part (src/portal_graph.h; docs/BIG_WORLDS_LOD.md, "Areas and portals"). No GPU. Two rooms and
// a corridor along -Z, a closed door, a cycle, overlapping areas, a camera outside looking in, and the frustum narrowing through a door.
#include <doctest.h>

#include <algorithm>
#include <cstdint>
#include <vector>

#include "portal_graph.h"

using namespace fa;
using namespace fa::render;

namespace {

// Room 1 (z -5..5), corridor 2 (z -15..-5), room 3 (z -25..-15), 4 m high, rooms 10 m wide, the corridor 4 m wide.
std::vector<PortalAreaBox> three_areas() {
    return {make_portal_area(1, Mat4::translate({0, 2, 0}), {10, 4, 10}, 1),
            make_portal_area(2, Mat4::translate({0, 2, -10}), {4, 4, 10}, 2),
            make_portal_area(3, Mat4::translate({0, 2, -20}), {10, 4, 10}, 3)};
}

PortalBox door(std::int32_t a, std::int32_t b, Vec3 pos, bool open = true, Vec3 size = {2, 3, 0.2f}) {
    return make_portal_box(a, b, Mat4::translate(pos), size, open, 0);
}

Mat4 view(Vec3 eye, Vec3 target) {
    return Mat4::perspective(60.0f, 16.0f / 9.0f, 0.1f, 500.0f, false) * Mat4::look_at(eye, target);
}

std::vector<PortalBox> chain(bool firstOpen = true) {
    return {door(1, 2, {0, 1.5f, -5}, firstOpen), door(2, 3, {0, 1.5f, -15})};
}

bool has(const PortalWalk& w, std::int32_t id) { return std::binary_search(w.reached.begin(), w.reached.end(), id); }

}  // namespace

TEST_CASE("portal graph: the camera starts in every area whose box holds it, 0 outside every area") {
    const auto areas = three_areas();
    const std::vector<PortalBox> none;
    using Ids = std::vector<std::int32_t>;
    CHECK(portal_start_areas(areas, none, {0, 1.6f, 0}) == Ids{1});
    CHECK(portal_start_areas(areas, none, {0, 1.6f, -10}) == Ids{2});
    CHECK(portal_start_areas(areas, none, {0, 1.6f, -20}) == Ids{3});
    CHECK(portal_start_areas(areas, none, {0, 1.6f, 20}) == Ids{0});
    CHECK(portal_start_areas(areas, none, {0, 9.0f, 0}) == Ids{0});  // above the ceiling
    CHECK(portal_start_areas({}, none, {0, 0, 0}) == Ids{0});
}

TEST_CASE("portal graph: an area follows its matrix (rotation and scale), size is before the scale") {
    // 4 x 4 x 20 box turned 90 degrees about Y: long along X; then scaled by 2 along its local Z (the long side): 40 m along X.
    const Mat4 m = Mat4::translate({0, 2, 0}) * Mat4::rotate_y_deg(90) * Mat4::scale({1, 1, 2});
    const std::vector<PortalAreaBox> areas{make_portal_area(9, m, {4, 4, 20}, 1)};
    const std::vector<PortalBox> none;
    using Ids = std::vector<std::int32_t>;
    CHECK(portal_start_areas(areas, none, {18, 2, 0}) == Ids{9});
    CHECK(portal_start_areas(areas, none, {22, 2, 0}) == Ids{0});
    CHECK(portal_start_areas(areas, none, {0, 2, 3}) == Ids{0});
    // A zero-scale matrix holds nothing and does not crash.
    const std::vector<PortalAreaBox> flat{make_portal_area(4, Mat4::scale({0, 1, 1}), {4, 4, 4}, 1)};
    CHECK(portal_start_areas(flat, none, {0, 0, 0}) == Ids{0});
    CHECK_FALSE(
        portal_mesh_seen(flat, {}, Mat4::identity(), {-1, -1, -1}, {1, 1, 1}));  // in no area: area 0, not reached
}

TEST_CASE("portal graph: nested areas start the walk in both, so what only the outer one holds is seen") {
    using Ids = std::vector<std::int32_t>;
    const std::vector<PortalAreaBox> areas{make_portal_area(1, Mat4::translate({0, 2, 0}), {10, 4, 10}, 5),
                                           make_portal_area(8, Mat4::translate({0, 0, 0}), {200, 50, 200}, 4)};
    const std::vector<PortalBox> none;
    CHECK(portal_start_areas(areas, none, {0, 1, 0}) == Ids{1, 8});
    CHECK(portal_start_areas(areas, none, {50, 1, 0}) == Ids{8});
    CHECK(portal_start_areas(areas, none, {500, 1, 0}) == Ids{0});
    // The order of the list changes nothing.
    CHECK(portal_start_areas({areas[1], areas[0]}, none, {0, 1, 0}) == Ids{1, 8});
    const PortalWalk w = portal_walk(none, view({0, 1.6f, 0}, {0, 1.6f, -10}), {1, 8});
    CHECK(w.reached == Ids{1, 8});
    // A mesh only the outer area holds is drawn, one in the inner room too.
    CHECK(portal_mesh_seen(areas, w.reached, Mat4::translate({40, 1, 0}), {-1, -1, -1}, {1, 1, 1}));
    CHECK(portal_mesh_seen(areas, w.reached, Mat4::translate({0, 1, 0}), {-1, -1, -1}, {1, 1, 1}));
}

TEST_CASE("portal graph: a camera in a doorway, in the gap of the wall between two rooms, is in both rooms") {
    using Ids = std::vector<std::int32_t>;
    // Room 1 is z -5..5 (after a wall 1 m thick) and room 2 is z -16..-6: the gap z -6..-5 is in no room.
    const std::vector<PortalAreaBox> areas{make_portal_area(1, Mat4::translate({0, 2, 0}), {10, 4, 10}, 1),
                                           make_portal_area(2, Mat4::translate({0, 2, -11}), {10, 4, 10}, 2)};
    std::vector<PortalBox> p{door(1, 2, {0, 1.5f, -5.5f}, true, {2, 3, 1})};
    const Vec3 inGap{0, 1.6f, -5.5f};
    CHECK(portal_start_areas(areas, p, inGap) == Ids{1, 2});
    const PortalWalk w = portal_walk(p, view(inGap, {0, 1.6f, -20}), portal_start_areas(areas, p, inGap));
    CHECK(w.reached == Ids{1, 2});
    CHECK(portal_mesh_seen(areas, w.reached, Mat4::translate({0, 1, 2}), {-1, -1, -1}, {1, 1, 1}));
    CHECK(portal_mesh_seen(areas, w.reached, Mat4::translate({0, 1, -10}), {-1, -1, -1}, {1, 1, 1}));
    // The same doorway shut: the camera is in no room, and it sees area 0 only.
    p[0] = door(1, 2, {0, 1.5f, -5.5f}, false, {2, 3, 1});
    CHECK(portal_start_areas(areas, p, inGap) == Ids{0});
}

TEST_CASE("portal graph: a mesh belongs to every area its bounds touch, and to outside unless wholly inside one") {
    const auto areas = three_areas();  // room 1 z -5..5, corridor 2 z -15..-5, room 3 z -25..-15
    const Vec3 lo{-1, -1, -1}, hi{1, 1, 1};
    auto seen = [&](std::vector<std::int32_t> reached, Mat4 model, Vec3 a = {-1, -1, -1}, Vec3 b = {1, 1, 1}) {
        return portal_mesh_seen(areas, reached, model, a, b);
    };
    // A cube wholly inside room 1: seen with room 1 reached, not with only room 3 or 0.
    CHECK(seen({1}, Mat4::translate({0, 2, 0})));
    CHECK_FALSE(seen({0, 2, 3}, Mat4::translate({0, 2, 0})));
    // A wall on the border of rooms 1 and 2 (centre in 2, half in 1): seen from either side.
    CHECK(seen({1}, Mat4::translate({0, 2, -5.2f})));
    CHECK(seen({2}, Mat4::translate({0, 2, -5.2f})));
    CHECK_FALSE(seen({3}, Mat4::translate({0, 2, -5.2f})));
    // A floor 100 m wide under room 1, centre inside it: sticks out of every box, so it is outside too (seen from 0).
    CHECK(seen({0}, Mat4::translate({0, -0.5f, 0}), {-50, -0.5f, -50}, {50, 0.5f, 50}));
    CHECK(seen({1}, Mat4::translate({0, -0.5f, 0}), {-50, -0.5f, -50}, {50, 0.5f, 50}));
    // A cube far away in no area is outside only.
    CHECK(seen({0}, Mat4::translate({100, 1, 0})));
    CHECK_FALSE(seen({1, 2, 3}, Mat4::translate({100, 1, 0})));
    (void)lo;
    (void)hi;
}

TEST_CASE("portal graph: two rooms and a corridor, seen straight down the line of doors") {
    const PortalWalk w = portal_walk(chain(), view({0, 1.6f, 0}, {0, 1.6f, -10}), {1});
    CHECK(w.reached == std::vector<std::int32_t>{1, 2, 3});
    CHECK(w.portalsVisited == 2);
    CHECK_FALSE(w.capped);
}

TEST_CASE("portal graph: a closed door blocks the walk, the door behind it is not counted") {
    const PortalWalk w = portal_walk(chain(false), view({0, 1.6f, 0}, {0, 1.6f, -10}), {1});
    CHECK(w.reached == std::vector<std::int32_t>{1});
    CHECK(w.portalsVisited == 0);
    // Only the second door closed: the corridor is seen, the far room is not.
    std::vector<PortalBox> p = chain();
    p[1].open = false;
    const PortalWalk w2 = portal_walk(p, view({0, 1.6f, 0}, {0, 1.6f, -10}), {1});
    CHECK(w2.reached == std::vector<std::int32_t>{1, 2});
    CHECK(w2.portalsVisited == 1);
}

TEST_CASE("portal graph: a door out of the view, or behind the camera, leads nowhere") {
    std::vector<PortalBox> p = chain();
    const Mat4 away = view({0, 1.6f, 0}, {0, 1.6f, 10});  // looking +Z, away from the doors
    CHECK(portal_walk(p, away, {1}).reached == std::vector<std::int32_t>{1});
    const Mat4 up = view({0, 1.6f, 0}, {0, 20, 0.01f});  // looking at the ceiling
    CHECK(portal_walk(p, up, {1}).reached == std::vector<std::int32_t>{1});
    // A door at the side wall that the narrow look down the corridor misses.
    p.push_back(door(1, 7, {-4.9f, 1.5f, 3}, true, {0.2f, 3, 2}));
    const PortalWalk w = portal_walk(p, view({0, 1.6f, 0}, {0, 1.6f, -10}), {1});
    CHECK_FALSE(has(w, 7));
    // Turned toward it, it is seen.
    CHECK(has(portal_walk(p, view({0, 1.6f, 0}, {-4.9f, 1.5f, 3}), {1}), 7));
}

TEST_CASE("portal graph: a cycle of portals ends and counts each portal once") {
    std::vector<PortalBox> p = chain();
    p.push_back(door(3, 1, {0, 1.5f, -4.9f}));  // a shortcut from the far room back to the first: a cycle 1-2-3-1
    p.push_back(door(2, 1, {0, 1.5f, -5.1f}));  // a second door between 1 and 2
    const PortalWalk w = portal_walk(p, view({0, 1.6f, 0}, {0, 1.6f, -10}), {1});
    CHECK(w.reached == std::vector<std::int32_t>{1, 2, 3});
    CHECK_FALSE(w.capped);
    CHECK(w.portalsVisited <= 4);
    // The same result with the list in the other order.
    std::reverse(p.begin(), p.end());
    CHECK(portal_walk(p, view({0, 1.6f, 0}, {0, 1.6f, -10}), {1}).reached == w.reached);
}

TEST_CASE("portal graph: a chain deeper than the guard and a star wider than the step cap end the walk with capped") {
    // 40 rooms in a row, each door in the line of sight: past kPortalMaxDepth portals the walk gives up and says so (no crash, no loop).
    std::vector<PortalBox> p;
    for (int i = 1; i <= 40; ++i) p.push_back(door(i, i + 1, {0, 1.5f, -2.0f * float(i)}, true, {2, 3, 0.1f}));
    const PortalWalk w = portal_walk(p, view({0, 1.6f, 0}, {0, 1.6f, -80}), {1});
    CHECK(w.capped);
    CHECK(w.reached.size() <= std::size_t(kPortalMaxDepth) + 2);
    // A chain within the guard is complete.
    p.resize(20);
    const PortalWalk ok = portal_walk(p, view({0, 1.6f, 0}, {0, 1.6f, -80}), {1});
    CHECK_FALSE(ok.capped);
    CHECK(ok.reached.size() == 21);
    // One area with more doors than the step cap.
    std::vector<PortalBox> star;
    for (int i = 0; i < kPortalMaxSteps + 400; ++i) star.push_back(door(1, i + 2, {0, 1.5f, -5}));
    CHECK(portal_walk(star, view({0, 1.6f, 0}, {0, 1.6f, -10}), {1}).capped);
}

TEST_CASE("portal graph: outside looking in, and inside looking out, both work (area 0 is an area)") {
    std::vector<PortalBox> p = chain();
    p.push_back(door(0, 1, {0, 1.5f, 5}));  // the front door of room 1, to the outside
    // From outside, in front of the door, the whole line of rooms is in sight.
    const PortalWalk in = portal_walk(p, view({0, 1.6f, 12}, {0, 1.6f, 0}), {0});
    CHECK(in.reached == std::vector<std::int32_t>{0, 1, 2, 3});
    CHECK(in.portalsVisited == 3);
    // From outside, to the side of the door, looking along the wall: the door is not in view.
    CHECK(portal_walk(p, view({30, 1.6f, 12}, {30, 1.6f, 30}), {0}).reached == std::vector<std::int32_t>{0});
    // From inside, looking at the front door, the outside is seen; the door closed, it is not.
    CHECK(has(portal_walk(p, view({0, 1.6f, 0}, {0, 1.6f, 10}), {1}), 0));
    p.back().open = false;
    CHECK_FALSE(has(portal_walk(p, view({0, 1.6f, 0}, {0, 1.6f, 10}), {1}), 0));
}

TEST_CASE("portal graph: the view narrows to the door, so a side door seen only past the wall is not reached") {
    // Outside at z = 9 looking through the front door (z = 5, 2 m wide). A door in room 1's right wall at z = 0 is inside the camera's
    // whole frustum, but not inside the part of it that the front door lets through.
    std::vector<PortalBox> p;
    p.push_back(door(0, 1, {0, 1.5f, 5}));
    p.push_back(door(1, 4, {4.9f, 1.5f, 0}, true, {0.2f, 3, 2}));
    const Mat4 outside = view({0, 1.6f, 9}, {0, 1.6f, 0});
    const PortalWalk w = portal_walk(p, outside, {0});
    CHECK(has(w, 1));
    CHECK_FALSE(has(w, 4));
    // Control: from inside the room, aimed at the same side door, it is reached.
    CHECK(has(portal_walk(p, view({0, 1.6f, 3}, {4.9f, 1.5f, 0}), {1}), 4));
    // Control: the same door seen straight from the camera of the first walk is inside its frustum when nothing narrows it.
    CHECK(has(portal_walk({door(0, 4, {4.9f, 1.5f, 0}, true, {0.2f, 3, 2})}, outside, {0}), 4));
}

TEST_CASE("portal graph: a camera inside a portal's box (it crosses the near plane) still sees through it") {
    const std::vector<PortalBox> p{door(1, 2, {0, 1.5f, 0}, true, {4, 3, 2})};
    CHECK(has(portal_walk(p, view({0, 1.6f, 0.2f}, {0, 1.6f, -10}), {1}), 2));
}
