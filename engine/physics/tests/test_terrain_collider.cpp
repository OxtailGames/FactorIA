// M75-P5a: the automatic collider of a Terrain (collision on) is the surface the renderer draws: the same heights, the same
// triangles. Rays and resting bodies agree with terrain_height_at, a sculpt (mark_dirty) moves the collider by the rectangle it
// names, and collision off or a broken terrain leaves no collider.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <filesystem>
#include <string>

#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/physics/physics.h"
#include "fa/scene/terrain.h"
#include "fa/scene/world.h"

using namespace fa;

namespace {

constexpr float kDt = 1.0f / 60.0f;

struct Sim {
    World world;
    Physics physics;
    Sim() { physics.init(PhysicsSettings{}); }
    void run(int steps) {
        for (int i = 0; i < steps; ++i) {
            world.events().clear();
            physics.step(world, kDt);
            world.advance_clock(kDt);
            world.flush();
        }
    }
};

// A 65 x 65 heightmap of hills (not a plane, not symmetric), written to a temp file.
std::string write_hills(const std::filesystem::path& dir) {
    GrayImage16 g;
    g.width = g.height = 65;
    g.sixteenBit = true;
    g.samples.resize(65 * 65);
    for (int r = 0; r < 65; ++r)
        for (int c = 0; c < 65; ++c) {
            const double v = 0.3 + 0.12 * std::sin(c * 0.31) * std::cos(r * 0.23) + 0.1 * std::sin((c + 2 * r) * 0.11);
            g.samples[std::size_t(r) * 65 + std::size_t(c)] = std::uint16_t(v * 65535.0);
        }
    const auto png = encode_png_gray16(g);
    const std::string file = fs::path_to_utf8(dir / "hills.png");
    REQUIRE(fs::write_bytes(file, png.data(), png.size()).ok());
    return file;
}

Entity add_terrain(World& w, const std::string& file, Vec3 pos, Vec3 scale, bool collision = true) {
    Entity e = w.create("ground", "ground");
    Transform& tr = *w.get<Transform>(e);
    tr.position = pos;
    tr.scale = scale;
    Terrain3D& t = w.add<Terrain3D>(e);
    t.heightmap = file;
    t.size = {64.0f, 96.0f};
    t.heightScale = 30.0f;
    t.heightOffset = -4.0f;
    t.collision = collision;
    return e;
}

}  // namespace

TEST_CASE("terrain collider: a ray down meets the surface terrain_height_at gives, under a transform with a scale") {
    const std::filesystem::path dir = fs::make_temp_dir("fa_terrain_collider").value();
    {
        Sim s;
        const std::string file = write_hills(dir);
        Entity ground = add_terrain(s.world, file, {10.0f, 3.0f, -20.0f}, {1.5f, 2.0f, 1.25f});
        s.physics.sync(s.world);
        int hits = 0;
        for (int i = 0; i < 400; ++i) {
            // inside the footprint (+-32 x 1.5 and +-48 x 1.25 around the position), a spread of points off the grid lines
            const float x = 10.0f + (float(i % 20) / 19.0f * 2.0f - 1.0f) * 46.0f + 0.137f;
            const float z = -20.0f + (float(i / 20) / 19.0f * 2.0f - 1.0f) * 57.0f + 0.071f;
            float h = 0.0f;
            REQUIRE(terrain_height_at(s.world, ground, x, z, h));
            const auto hit = s.physics.raycast3d(s.world, {x, 200.0f, z}, {0, -1, 0}, 400.0f);
            REQUIRE(hit.has_value());
            CHECK(hit->entity == ground);
            CHECK(hit->point.y == doctest::Approx(h).epsilon(1e-4).scale(10.0));
            CHECK(std::fabs(hit->point.y - h) < 2e-3f);
            ++hits;
        }
        CHECK(hits == 400);
        // outside the footprint there is nothing to hit
        CHECK_FALSE(s.physics.raycast3d(s.world, {200.0f, 200.0f, 0.0f}, {0, -1, 0}, 400.0f).has_value());
    }
    std::error_code ec;
    fs::remove_tree(dir, ec);
}

TEST_CASE("terrain collider: a sphere dropped on the terrain rests on its surface, and a sculpt lifts it") {
    const std::filesystem::path dir = fs::make_temp_dir("fa_terrain_collider2").value();
    {
        Sim s;
        const std::string file = write_hills(dir);
        Entity ground = add_terrain(s.world, file, {0, 0, 0}, {1, 1, 1});
        Entity ball = s.world.create("ball", "ball");
        s.world.get<Transform>(ball)->position = {5.3f, 40.0f, -7.1f};
        Collider3D& c = s.world.add<Collider3D>(ball);
        c.shape = ColliderShape3D::Sphere;
        c.radius = 0.5f;
        s.world.add<RigidBody3D>(ball);
        s.run(400);
        float h = 0;
        const Vec3 p = s.world.get<Transform>(ball)->position;
        REQUIRE(terrain_height_at(s.world, ground, p.x, p.z, h));
        // on a slope the centre of a resting sphere is a radius above the surface along the normal: at most radius / cos(slope)
        CHECK(p.y >= h + 0.45f);
        CHECK(p.y <= h + 1.0f);
        const float restedAt = p.y;
        // sculpt: raise a rectangle around the ball by 5 m of height (a sixth of the scale) through the shared heights
        std::string problem;
        auto heights = s.world.terrain().heights(s.world, ground, &problem);
        REQUIRE(heights);
        // The rectangle follows where the ball came to rest (a slope this steep can roll it a different way on another CPU or another
        // build of the solver), not a place chosen on one machine: cells are 1 m wide (x) and 1.5 m deep (z), the map starts at -32 / -48.
        const int col = std::clamp(int(std::lround(p.x + 32.0f)), 7, 57);
        const int row = std::clamp(int(std::lround((p.z + 48.0f) / 1.5f)), 7, 57);
        const TerrainRect rect{col - 6, row - 6, col + 6, row + 6};
        for (int r = rect.r0; r <= rect.r1; ++r)
            for (int c2 = rect.c0; c2 <= rect.c1; ++c2) heights->set(c2, r, std::uint16_t(heights->at(c2, r) + 10922));
        heights->mark_dirty(rect);
        s.run(240);
        const Vec3 q = s.world.get<Transform>(ball)->position;
        float h2 = 0;
        REQUIRE(terrain_height_at(s.world, ground, q.x, q.z, h2));
        CHECK(h2 > h + 3.0f);          // the surface moved
        CHECK(q.y > restedAt + 3.0f);  // and carried the ball with it
        CHECK(q.y >= h2 + 0.45f);
        CHECK(q.y <= h2 + 1.0f);
        // (a ray a few metres from the ball, so the ball is not what it meets)
        float h3 = 0;
        REQUIRE(terrain_height_at(s.world, ground, q.x + 4.0f, q.z, h3));
        const auto hit = s.physics.raycast3d(s.world, {q.x + 4.0f, 200.0f, q.z}, {0, -1, 0}, 400.0f);
        REQUIRE(hit.has_value());
        CHECK(hit->entity == ground);
        CHECK(std::fabs(hit->point.y - h3) < 2e-3f);
    }
    std::error_code ec;
    fs::remove_tree(dir, ec);
}

TEST_CASE("terrain collider: collision off, a RigidBody3D that moves, or an unreadable heightmap leave no collider") {
    const std::filesystem::path dir = fs::make_temp_dir("fa_terrain_collider3").value();
    {
        Sim s;
        const std::string file = write_hills(dir);
        Entity ground = add_terrain(s.world, file, {0, 0, 0}, {1, 1, 1}, false);
        s.physics.sync(s.world);
        CHECK_FALSE(s.physics.raycast3d(s.world, {1.0f, 200.0f, 1.0f}, {0, -1, 0}, 400.0f).has_value());
        s.world.get<Terrain3D>(ground)->collision = true;
        s.physics.sync(s.world);
        CHECK(s.physics.raycast3d(s.world, {1.0f, 200.0f, 1.0f}, {0, -1, 0}, 400.0f).has_value());
        s.world.get<Terrain3D>(ground)->collision = false;
        s.physics.sync(s.world);
        CHECK_FALSE(s.physics.raycast3d(s.world, {1.0f, 200.0f, 1.0f}, {0, -1, 0}, 400.0f).has_value());
        s.world.get<Terrain3D>(ground)->collision = true;
        s.world.get<Terrain3D>(ground)->heightmap = "nope/missing.png";
        s.physics.sync(s.world);
        CHECK_FALSE(s.physics.raycast3d(s.world, {1.0f, 200.0f, 1.0f}, {0, -1, 0}, 400.0f).has_value());
        // no heightmap at all: a flat terrain at heightOffset, which is solid too
        s.world.get<Terrain3D>(ground)->heightmap.clear();
        s.physics.sync(s.world);
        const auto flat = s.physics.raycast3d(s.world, {1.0f, 200.0f, 1.0f}, {0, -1, 0}, 400.0f);
        REQUIRE(flat.has_value());
        CHECK(flat->point.y == doctest::Approx(-4.0f).epsilon(1e-4));
    }
    std::error_code ec;
    fs::remove_tree(dir, ec);
}

TEST_CASE("terrain collider: the holes mask of the shared heights is honoured, cut and filled live, rays and bodies "
          "fall through") {
    const std::filesystem::path dir = fs::make_temp_dir("fa_terrain_collider_holes").value();
    {
        Sim s;
        const std::string file = write_hills(dir);
        Entity ground = add_terrain(s.world, file, {0, 0, 0}, {1, 1, 1});
        s.run(2);
        auto heights = s.world.terrain().heights(s.world, ground);
        REQUIRE(heights);
        const Vec3 origin{0.5f, 200.0f, -0.5f};  // cell column 32, row 31 (1 m x 1.5 m cells)
        REQUIRE(s.physics.raycast3d(s.world, origin, {0, -1, 0}, 400.0f).has_value());
        // cut a block of cells
        heights->holes.assign(std::size_t(heights->cells()) * std::size_t(heights->cells()), 0);
        for (int r = 30; r <= 33; ++r)
            for (int c = 30; c <= 33; ++c)
                heights->holes[std::size_t(r) * std::size_t(heights->cells()) + std::size_t(c)] = 1;
        ++heights->holesVersion;
        s.run(2);
        CHECK_FALSE(s.physics.raycast3d(s.world, origin, {0, -1, 0}, 400.0f).has_value());
        // the cells next to the block are still ground
        CHECK(s.physics.raycast3d(s.world, {6.5f, 200.0f, -0.5f}, {0, -1, 0}, 400.0f).has_value());
        // a ball over the hole falls through; one over ground rests
        Entity ball = s.world.create("ball", "ball");
        s.world.get<Transform>(ball)->position = {0.5f, 30.0f, -0.5f};
        Collider3D& cb = s.world.add<Collider3D>(ball);
        cb.shape = ColliderShape3D::Sphere;
        cb.radius = 0.3f;
        s.world.add<RigidBody3D>(ball);
        s.run(240);
        CHECK(s.world.get<Transform>(ball)->position.y < -10.0f);
        // fill the block again: the ground is back
        std::fill(heights->holes.begin(), heights->holes.end(), std::uint8_t(0));
        ++heights->holesVersion;
        s.run(2);
        CHECK(s.physics.raycast3d(s.world, origin, {0, -1, 0}, 400.0f).has_value());
    }
    std::error_code ec;
    fs::remove_tree(dir, ec);
}

TEST_CASE(
    "terrain collider: a Collider3D of the terrain's own entity decides, enabled or not (a disabled one disables it)") {
    const std::filesystem::path dir = fs::make_temp_dir("fa_terrain_collider_own").value();
    {
        Sim s;
        const std::string file = write_hills(dir);
        Entity ground = add_terrain(s.world, file, {0, 0, 0}, {1, 1, 1});
        const Vec3 origin{1.0f, 200.0f, 1.0f};
        s.physics.sync(s.world);
        const auto auto_hit = s.physics.raycast3d(s.world, origin, {0, -1, 0}, 400.0f);
        REQUIRE(auto_hit.has_value());
        // a disabled Collider3D on the entity: no collider at all, not the terrain's own standing in
        Collider3D& own = s.world.add<Collider3D>(ground);
        own.shape = ColliderShape3D::Box;
        own.enabled = false;
        s.physics.sync(s.world);
        CHECK_FALSE(s.physics.raycast3d(s.world, origin, {0, -1, 0}, 400.0f).has_value());
        // enabled again: it is that collider (a box here), not the heightfield
        s.world.get<Collider3D>(ground)->enabled = true;
        s.physics.sync(s.world);
        CHECK_FALSE(
            s.physics.raycast3d(s.world, origin, {0, -1, 0}, 400.0f).has_value());  // the box is small, 1 m away
        const auto box_hit = s.physics.raycast3d(s.world, {0.0f, 200.0f, 0.0f}, {0, -1, 0}, 400.0f);
        REQUIRE(box_hit.has_value());
        CHECK(box_hit->point.y < 2.0f);  // the unit box at the origin, not the hills (4 m and more up at the origin)
        // removed: the terrain collides by itself again
        s.world.remove<Collider3D>(ground);
        s.physics.sync(s.world);
        const auto back = s.physics.raycast3d(s.world, origin, {0, -1, 0}, 400.0f);
        REQUIRE(back.has_value());
        CHECK(back->point.y == doctest::Approx(auto_hit->point.y).epsilon(1e-4));
    }
    std::error_code ec;
    fs::remove_tree(dir, ec);
}
