// The particle simulation without a GPU (fa/scene/particles.h): shapes, flipbook, collision, sub-emitters, determinism.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <filesystem>

#include "fa/core/fs.h"
#include "fa/scene/particles.h"
#include "fa/scene/serialize.h"

using namespace fa;

namespace {

ParticleEmitter quiet() {
    ParticleEmitter e;
    e.rate = 0.0f;
    e.burst = 0;
    e.speed = 0.0f;
    e.speedVariance = 0.0f;
    e.lifetime = 10.0f;
    e.lifetimeVariance = 0.0f;
    e.gravity = {0, 0, 0};
    e.maxParticles = 5000;
    return e;
}

// A tolerant fingerprint: the count and sums, compared with a margin (the same run gives the same numbers; another platform may
// differ in the last bits of a float).
struct Print {
    int count = 0;
    double px = 0, py = 0, pz = 0, vx = 0, vy = 0, age = 0;
};
Print print_of(const ParticleSim& s) {
    Print p;
    p.count = int(s.particles.size());
    for (const Particle& q : s.particles) {
        p.px += q.pos.x; p.py += q.pos.y; p.pz += q.pos.z;
        p.vx += q.vel.x; p.vy += q.vel.y;
        p.age += q.age;
    }
    return p;
}
void expect_same(const Print& a, const Print& b, double tol = 1e-3) {
    CHECK(a.count == b.count);
    CHECK(a.px == doctest::Approx(b.px).epsilon(tol));
    CHECK(a.py == doctest::Approx(b.py).epsilon(tol));
    CHECK(a.pz == doctest::Approx(b.pz).epsilon(tol));
    CHECK(a.vx == doctest::Approx(b.vx).epsilon(tol));
    CHECK(a.vy == doctest::Approx(b.vy).epsilon(tol));
    CHECK(a.age == doctest::Approx(b.age).epsilon(tol));
}

ParticleSim born(const ParticleEmitter& em, int n, std::uint64_t seed = 7, Mat4 at = Mat4::identity()) {
    ParticleSim s;
    s.seed(seed);
    ParticleEnv env;
    env.emitter = at;
    env.is3D = em.is3D;
    s.spawn(em, env, n);
    return s;
}

}  // namespace

// ----------------------------------------------------------- old emitters --

TEST_CASE("particles: an emitter with none of the new fields behaves as before") {
    ParticleEmitter em;  // all defaults
    em.rate = 0;
    em.burst = 200;
    ParticleSim s;
    s.seed(3);
    ParticleEnv env;
    env.emitter = Mat4::translate({10, 20, 0});
    s.step(em, env, 0.0f);
    REQUIRE(s.particles.size() == 200);
    for (const Particle& p : s.particles) {
        CHECK(p.pos.x == doctest::Approx(10.0f));
        CHECK(p.pos.y == doctest::Approx(20.0f));
        CHECK(p.life >= 0.8f - 1e-4f);
        CHECK(p.life <= 1.2f + 1e-4f);
        const float sp = length(p.vel);
        CHECK(sp >= 70.0f - 1e-2f);
        CHECK(sp <= 130.0f + 1e-2f);
        const float ang = degrees(std::atan2(p.vel.y, p.vel.x));
        CHECK(ang >= 60.0f - 1e-2f);
        CHECK(ang <= 120.0f + 1e-2f);
        CHECK(p.rotation == 0.0f);
        CHECK(p.sizeScale == 1.0f);
    }
    // One step: gravity then position (semi-implicit Euler, like before).
    const Vec3 v0 = s.particles[0].vel;
    s.step(em, env, 0.1f);
    CHECK(s.particles[0].vel.y == doctest::Approx(v0.y - 20.0f));
    CHECK(s.particles[0].pos.y == doctest::Approx(20.0f + (v0.y - 20.0f) * 0.1f));
}

TEST_CASE("particles: continuous emission follows the rate, a burst fires once, autoDestroy guard is set") {
    ParticleEmitter em;
    em.rate = 30;
    em.burst = 5;
    em.lifetime = 100.0f;
    em.maxParticles = 1000;
    ParticleSim s;
    s.seed(1);
    ParticleEnv env;
    CHECK_FALSE(s.everSpawned);
    for (int i = 0; i < 60; ++i) s.step(em, env, 1.0f / 60.0f);
    CHECK(s.everSpawned);
    CHECK(int(s.particles.size()) == 5 + 30);
    em.emitting = false;
    s.step(em, env, 0.5f);
    CHECK(int(s.particles.size()) == 35);
    em.emitting = true;  // false -> true fires the burst again
    s.step(em, env, 0.0f);
    CHECK(int(s.particles.size()) == 40);
    s.queue_burst(7);
    s.step(em, env, 0.0f);
    CHECK(int(s.particles.size()) == 47);
}

// ------------------------------------------------------------- determinism --

TEST_CASE("particles: the same seed gives the same particles, another seed another") {
    ParticleEmitter em;
    em.rate = 120;
    em.burst = 20;
    em.spread = 180;
    em.noiseStrength = 80;
    em.drag = 0.5f;
    em.sizeVariance = 0.4f;
    em.startRotation = {0, 360};
    em.spin = {-90, 90};
    em.shape = ParticleShape::Circle;
    em.shapeSize = {30, 30, 30};
    em.collision = ParticleCollision::Plane;
    em.collisionPlane = {0, 1, 0, -50};
    em.subEmitters = Json::parse(R"({"death": {"count": 2, "emitter": {"lifetime": 0.2, "speed": 20}}})");
    auto run = [&](std::uint64_t seed) {
        ParticleSim s;
        s.seed(seed);
        ParticleEnv env;
        for (int i = 0; i < 90; ++i) s.step(em, env, 1.0f / 60.0f);
        return print_of(s);
    };
    const Print a = run(11), b = run(11), c = run(12);
    expect_same(a, b, 1e-9);
    CHECK(a.count > 50);
    CHECK((a.count != c.count || a.px != doctest::Approx(c.px).epsilon(1e-4)));
}

TEST_CASE("particle_noise is deterministic, bounded and smooth") {
    const Vec3 a = particle_noise({12.5f, -3.0f, 7.0f}, 0.4f, 64.0f, 0.5f, 99);
    const Vec3 b = particle_noise({12.5f, -3.0f, 7.0f}, 0.4f, 64.0f, 0.5f, 99);
    CHECK(a.x == b.x);
    CHECK(a.y == b.y);
    CHECK(a.z == b.z);
    const Vec3 other = particle_noise({12.5f, -3.0f, 7.0f}, 0.4f, 64.0f, 0.5f, 100);
    CHECK((a.x != other.x || a.y != other.y));
    float maxStep = 0.0f;
    for (int i = 0; i < 400; ++i) {
        const Vec3 n = particle_noise({float(i) * 3.7f, float(i) * -1.3f, 0.0f}, float(i) * 0.05f, 40.0f, 1.0f, 5);
        CHECK(std::fabs(n.x) <= 1.0f);
        CHECK(std::fabs(n.y) <= 1.0f);
        CHECK(std::fabs(n.z) <= 1.0f);
        const Vec3 m = particle_noise({float(i) * 3.7f + 0.1f, float(i) * -1.3f, 0.0f}, float(i) * 0.05f, 40.0f, 1.0f, 5);
        maxStep = std::max(maxStep, std::fabs(n.x - m.x));
    }
    CHECK(maxStep < 0.05f);  // a tenth of a unit apart in an eddy 40 units wide: nearly the same
    CHECK(length(particle_noise({1, 2, 3}, 0, 0.0f, 1, 1)) == 0.0f);  // scale 0 = off, not a division by zero
}

TEST_CASE("particles: turbulence moves particles, and is off by default") {
    ParticleEmitter still = quiet();
    still.lifetime = 100;
    ParticleEmitter wind = still;
    wind.noiseStrength = 200.0f;
    ParticleSim a = born(still, 20), b = born(wind, 20);
    ParticleEnv env;
    for (int i = 0; i < 30; ++i) {
        a.step(still, env, 1.0f / 30.0f);
        b.step(wind, env, 1.0f / 30.0f);
    }
    float da = 0, db = 0;
    for (const Particle& p : a.particles) da += length(p.pos);
    for (const Particle& p : b.particles) db += length(p.pos);
    CHECK(da == 0.0f);
    CHECK(db > 10.0f);
    for (const Particle& p : b.particles) CHECK(p.pos.z == 0.0f);  // 2D: no motion in depth
}

TEST_CASE("particles: drag fades the velocity and spin turns the particle") {
    ParticleEmitter em = quiet();
    em.speed = 100;
    em.direction = 0;
    em.spread = 0;
    em.drag = 4.0f;
    em.spin = {90, 90};
    em.startRotation = {10, 10};
    ParticleSim s = born(em, 1);
    ParticleEnv env;
    CHECK(s.particles[0].rotation == doctest::Approx(10.0f));
    for (int i = 0; i < 60; ++i) s.step(em, env, 1.0f / 60.0f);
    CHECK(s.particles[0].vel.x < 100.0f * 0.25f);
    CHECK(s.particles[0].vel.x > 0.0f);
    CHECK(s.particles[0].rotation == doctest::Approx(100.0f).epsilon(1e-3));
}

// ------------------------------------------------------------------ shapes --

TEST_CASE("particle shapes: circle volume and edge stay inside the radius") {
    ParticleEmitter em = quiet();
    em.shape = ParticleShape::Circle;
    em.shapeSize = {40, 0, 0};
    float far = 0.0f;
    ParticleSim v = born(em, 500, 5, Mat4::translate({100, -50, 0}));
    for (const Particle& p : v.particles) {
        const float r = length(Vec3{p.pos.x - 100.0f, p.pos.y + 50.0f, 0.0f});
        CHECK(r <= 40.0f + 1e-3f);
        far = std::max(far, r);
        CHECK(p.pos.z == 0.0f);
    }
    CHECK(far > 35.0f);  // it fills the disc, not only its centre
    em.shapeFrom = ParticleShapeFrom::Edge;
    ParticleSim e = born(em, 200);
    for (const Particle& p : e.particles) CHECK(length(p.pos) == doctest::Approx(40.0f).epsilon(1e-3));
}

TEST_CASE("particle shapes: a 3D circle is a ball, or its surface") {
    ParticleEmitter em = quiet();
    em.is3D = true;
    em.shape = ParticleShape::Circle;
    em.shapeSize = {25, 0, 0};
    ParticleSim v = born(em, 400);
    float maxZ = 0.0f;
    for (const Particle& p : v.particles) {
        CHECK(length(p.pos) <= 25.0f + 1e-3f);
        maxZ = std::max(maxZ, std::fabs(p.pos.z));
    }
    CHECK(maxZ > 10.0f);
    em.shapeFrom = ParticleShapeFrom::Edge;
    ParticleSim e = born(em, 200);
    for (const Particle& p : e.particles) CHECK(length(p.pos) == doctest::Approx(25.0f).epsilon(1e-3));
}

TEST_CASE("particle shapes: box volume and edge") {
    ParticleEmitter em = quiet();
    em.shape = ParticleShape::Box;
    em.shapeSize = {60, 20, 40};
    ParticleSim v = born(em, 500);
    float maxX = 0, maxY = 0;
    for (const Particle& p : v.particles) {
        CHECK(std::fabs(p.pos.x) <= 30.0f + 1e-4f);
        CHECK(std::fabs(p.pos.y) <= 10.0f + 1e-4f);
        CHECK(p.pos.z == 0.0f);
        maxX = std::max(maxX, std::fabs(p.pos.x));
        maxY = std::max(maxY, std::fabs(p.pos.y));
    }
    CHECK(maxX > 25.0f);
    CHECK(maxY > 8.0f);
    em.shapeFrom = ParticleShapeFrom::Edge;
    ParticleSim e = born(em, 300);
    for (const Particle& p : e.particles) {
        const bool onX = std::fabs(std::fabs(p.pos.x) - 30.0f) < 1e-3f, onY = std::fabs(std::fabs(p.pos.y) - 10.0f) < 1e-3f;
        CHECK((onX || onY));
        CHECK(std::fabs(p.pos.x) <= 30.0f + 1e-3f);
        CHECK(std::fabs(p.pos.y) <= 10.0f + 1e-3f);
    }
    // 3D: a box with depth.
    em.is3D = true;
    em.shapeFrom = ParticleShapeFrom::Volume;
    ParticleSim b3 = born(em, 500);
    float maxZ = 0;
    for (const Particle& p : b3.particles) {
        CHECK(std::fabs(p.pos.x) <= 30.0f + 1e-4f);
        CHECK(std::fabs(p.pos.y) <= 10.0f + 1e-4f);
        CHECK(std::fabs(p.pos.z) <= 20.0f + 1e-4f);
        maxZ = std::max(maxZ, std::fabs(p.pos.z));
    }
    CHECK(maxZ > 15.0f);
    em.shapeFrom = ParticleShapeFrom::Edge;
    ParticleSim s3 = born(em, 300);
    for (const Particle& p : s3.particles) {
        const bool onFace = std::fabs(std::fabs(p.pos.x) - 30.0f) < 1e-3f || std::fabs(std::fabs(p.pos.y) - 10.0f) < 1e-3f ||
                            std::fabs(std::fabs(p.pos.z) - 20.0f) < 1e-3f;
        CHECK(onFace);
    }
}

TEST_CASE("particle shapes: edge is a line along x, cone is a base across its direction") {
    ParticleEmitter em = quiet();
    em.shape = ParticleShape::Edge;
    em.shapeSize = {80, 0, 0};
    ParticleSim l = born(em, 300);
    float minX = 0, maxX = 0;
    for (const Particle& p : l.particles) {
        CHECK(p.pos.y == 0.0f);
        minX = std::min(minX, p.pos.x);
        maxX = std::max(maxX, p.pos.x);
    }
    CHECK(minX >= -40.0f);
    CHECK(maxX <= 40.0f);
    CHECK(minX < -30.0f);
    CHECK(maxX > 30.0f);

    em.shape = ParticleShape::Cone;
    em.shapeSize = {20, 0, 0};
    em.direction = 90;  // up: the base runs along x
    ParticleSim c = born(em, 300);
    for (const Particle& p : c.particles) {
        CHECK(std::fabs(p.pos.y) < 1e-3f);
        CHECK(std::fabs(p.pos.x) <= 20.0f + 1e-3f);
    }
    // Outward: the particles leave along the cone's rim, spreading with the position on the base.
    em.shapeDirection = ParticleShapeDirection::Outward;
    em.spread = 30;
    em.speed = 100;
    ParticleSim o = born(em, 300);
    for (const Particle& p : o.particles) {
        CHECK(length(p.vel) == doctest::Approx(100.0f).epsilon(1e-3));
        const float ang = degrees(std::atan2(p.vel.y, p.vel.x));
        CHECK(ang >= 60.0f - 1e-2f);
        CHECK(ang <= 120.0f + 1e-2f);
        // The right side of the base leans right (angle under 90), the left side leans left.
        if (p.pos.x > 1.0f) CHECK(ang < 90.0f + 1e-2f);
        if (p.pos.x < -1.0f) CHECK(ang > 90.0f - 1e-2f);
    }
}

TEST_CASE("particle shapes: outward direction leaves along the radius") {
    ParticleEmitter em = quiet();
    em.shape = ParticleShape::Circle;
    em.shapeSize = {30, 0, 0};
    em.shapeFrom = ParticleShapeFrom::Edge;
    em.shapeDirection = ParticleShapeDirection::Outward;
    em.spread = 0;
    em.speed = 50;
    ParticleSim s = born(em, 100);
    for (const Particle& p : s.particles) {
        const Vec3 radial = normalize(p.pos);
        const Vec3 dir = normalize(p.vel);
        CHECK(dot(radial, dir) == doctest::Approx(1.0f).epsilon(1e-3));
    }
}

TEST_CASE("particle shapes: an emitter that is moved and turned carries its shape along") {
    ParticleEmitter em = quiet();
    em.shape = ParticleShape::Edge;
    em.shapeSize = {100, 0, 0};
    em.direction = 90;
    em.speed = 10;
    em.spread = 0;
    // Turned 90 degrees: the line along x becomes a line along y, and "up" becomes "left".
    ParticleSim s = born(em, 100, 4, Mat4::translate({5, 5, 0}) * Mat4::rotate_z_deg(90.0f));
    for (const Particle& p : s.particles) {
        CHECK(p.pos.x == doctest::Approx(5.0f).epsilon(1e-3));
        CHECK(std::fabs(p.pos.y - 5.0f) <= 50.0f + 1e-3f);
        CHECK(p.vel.x == doctest::Approx(-10.0f).epsilon(1e-3));
    }
}

TEST_CASE("particle shapes: a mesh surface, or its edges, in 3D") {
    MeshSurface quad;  // one square in the XZ plane at y = 2
    quad.positions = {{-5, 2, -5}, {5, 2, -5}, {5, 2, 5}, {-5, 2, 5}};
    quad.indices = {0, 1, 2, 0, 2, 3};
    ParticleEmitter em = quiet();
    em.is3D = true;
    em.shape = ParticleShape::Mesh;
    ParticleSim s;
    s.seed(2);
    ParticleEnv env;
    env.is3D = true;
    env.mesh = &quad;
    env.emitter = Mat4::translate({100, 0, 0});
    s.spawn(em, env, 300);
    REQUIRE(s.particles.size() == 300);
    float minX = 1e9f, maxX = -1e9f;
    for (const Particle& p : s.particles) {
        CHECK(p.pos.y == doctest::Approx(2.0f));
        CHECK(std::fabs(p.pos.x - 100.0f) <= 5.0f + 1e-3f);
        CHECK(std::fabs(p.pos.z) <= 5.0f + 1e-3f);
        minX = std::min(minX, p.pos.x);
        maxX = std::max(maxX, p.pos.x);
    }
    CHECK(maxX - minX > 8.0f);
    // Edge emission: on the triangles' edges, so on the square's boundary or the diagonal.
    em.shapeFrom = ParticleShapeFrom::Edge;
    ParticleSim e;
    e.seed(2);
    e.spawn(em, env, 200);
    for (const Particle& p : e.particles) {
        const float x = p.pos.x - 100.0f, z = p.pos.z;
        const bool boundary = std::fabs(std::fabs(x) - 5.0f) < 1e-3f || std::fabs(std::fabs(z) - 5.0f) < 1e-3f;
        const bool diagonal = std::fabs(x - z) < 1e-3f;  // the triangles share the edge (-5,-5)-(5,5)... indices 0 and 2
        CHECK((boundary || diagonal));
    }
    // No mesh given: particles are born at the point and nothing breaks.
    ParticleSim none;
    none.seed(2);
    ParticleEnv bare;
    bare.is3D = true;
    none.spawn(em, bare, 5);
    CHECK(none.particles.size() == 5);
}

// ---------------------------------------------------------------- flipbook --

TEST_CASE("flipbook: frames over life, at a frame rate, from a random start") {
    ParticleEmitter em;
    em.flipbookColumns = 4;
    em.flipbookRows = 2;
    CHECK(flipbook_frame_count(em) == 8);
    // Over life: eight frames across the life, row by row.
    auto f = flipbook_frame(em, 0.0f, 1.0f, 0.0f);
    CHECK(f.column == 0);
    CHECK(f.row == 0);
    f = flipbook_frame(em, 0.30f, 1.0f, 0.0f);  // frame 2
    CHECK(f.column == 2);
    CHECK(f.row == 0);
    f = flipbook_frame(em, 0.55f, 1.0f, 0.0f);  // frame 4
    CHECK(f.column == 0);
    CHECK(f.row == 1);
    f = flipbook_frame(em, 1.0f, 1.0f, 0.0f);  // the last frame, never past it
    CHECK(f.column == 3);
    CHECK(f.row == 1);
    f = flipbook_frame(em, 5.0f, 1.0f, 0.0f);
    CHECK(f.column == 3);
    CHECK(f.row == 1);

    // Fewer frames than cells.
    em.flipbookFrames = 6;
    CHECK(flipbook_frame_count(em) == 6);
    f = flipbook_frame(em, 1.0f, 1.0f, 0.0f);  // frame 5 = column 1, row 1
    CHECK(f.column == 1);
    CHECK(f.row == 1);
    em.flipbookFrames = 99;  // more than the grid: clamped
    CHECK(flipbook_frame_count(em) == 8);

    // A frame rate loops.
    em.flipbookFrames = 0;
    em.flipbookFps = 8.0f;
    f = flipbook_frame(em, 0.30f, 5.0f, 0.0f);  // floor(2.4) = 2
    CHECK(f.column == 2);
    f = flipbook_frame(em, 1.0f, 5.0f, 0.0f);  // 8 -> back to 0
    CHECK(f.column == 0);
    CHECK(f.row == 0);
    f = flipbook_frame(em, 1.125f, 5.0f, 0.0f);  // 9 -> 1
    CHECK(f.column == 1);

    // A random start: a fixed frame, or the start of a loop.
    em.flipbookRandomStart = true;
    em.flipbookFps = 0.0f;
    f = flipbook_frame(em, 0.0f, 1.0f, 0.5f);  // floor(0.5 * 8) = 4
    CHECK(f.column == 0);
    CHECK(f.row == 1);
    f = flipbook_frame(em, 0.9f, 1.0f, 0.5f);  // stays on its frame
    CHECK(f.row == 1);
    em.flipbookFps = 8.0f;
    f = flipbook_frame(em, 0.25f, 1.0f, 0.5f);  // 4 + 2 = 6 -> column 2, row 1
    CHECK(f.column == 2);
    CHECK(f.row == 1);

    // A texture that is not a flipbook has one frame.
    ParticleEmitter plain;
    CHECK(flipbook_frame_count(plain) == 1);
    f = flipbook_frame(plain, 0.7f, 1.0f, 0.9f);
    CHECK(f.column == 0);
    CHECK(f.row == 0);
}

TEST_CASE("particles: a flipbook start frame is drawn per particle, and only when asked") {
    ParticleEmitter em = quiet();
    ParticleSim a = born(em, 50);
    for (const Particle& p : a.particles) CHECK(p.random == 0.0f);
    em.flipbookRandomStart = true;
    ParticleSim b = born(em, 50);
    float lo = 1, hi = 0;
    for (const Particle& p : b.particles) {
        CHECK(p.random >= 0.0f);
        CHECK(p.random < 1.0f);
        lo = std::min(lo, p.random);
        hi = std::max(hi, p.random);
    }
    CHECK(hi - lo > 0.5f);
}

// --------------------------------------------------------------- over life --

TEST_CASE("particle style: curves and gradients parse once and report what is wrong once") {
    ParticleEmitter em;
    em.colorGradient = Json::parse(R"([[0, "#ffffff"], [1, "#ff0000"]])");
    em.sizeCurve = Json::parse("[[0, 1], [0.5, 2], [1, 0]]");
    ParticleStyle st;
    st.refresh(em);
    CHECK(st.problems.empty());
    CHECK(st.color.keys.size() == 2);
    CHECK(st.size.eval(0.5f) == doctest::Approx(2.0f));
    CHECK(st.speed.empty());
    em.alphaCurve = Json::parse("[[0, 1], [1]]");
    st.refresh(em);
    REQUIRE(st.problems.size() == 1);
    CHECK(st.news.size() == 1);
    CHECK(st.problems[0].find("alphaCurve") != std::string::npos);
    st.refresh(em);  // nothing changed: nothing new
    CHECK(st.news.empty());
    CHECK(st.problems.size() == 1);
    CHECK(st.alpha.empty());  // a curve that does not parse is as if it was not set
}

TEST_CASE("particle_emitter_problems: errors teach, and a setting that does nothing is a warning") {
    ParticleEmitter ok;
    CHECK(particle_emitter_problems(ok).empty());

    ParticleEmitter em;
    em.sizeCurve = Json::parse("[[0]]");
    em.palette = Json::parse(R"(["#ff0000", "nope"])");
    em.subEmitters = Json::parse(R"({"deth": {"count": 2, "emitter": {}}})");
    em.collision = ParticleCollision::Plane;
    em.collisionPlane = {0, 0, 0, 0};
    const auto problems = particle_emitter_problems(em);
    auto find = [&](const std::string& ptr) -> const ParticleProblem* {
        for (const ParticleProblem& p : problems)
            if (p.pointer == ptr) return &p;
        return nullptr;
    };
    REQUIRE(find("/sizeCurve"));
    CHECK(find("/sizeCurve")->error);
    REQUIRE(find("/palette/1"));
    REQUIRE(find("/subEmitters/deth"));
    CHECK(find("/subEmitters/deth")->hint.find("death") != std::string::npos);  // did you mean
    REQUIRE(find("/collisionPlane"));

    ParticleEmitter warn;
    warn.collision = ParticleCollision::Plane;
    warn.worldSpace = false;
    warn.flipbookColumns = 4;  // but no texture
    warn.shape = ParticleShape::Mesh;
    const auto w = particle_emitter_problems(warn);
    int warnings = 0;
    for (const ParticleProblem& p : w) {
        CHECK_FALSE(p.error);
        ++warnings;
    }
    CHECK(warnings >= 3);
}

TEST_CASE("particles: speed, size and alpha curves are applied to velocity over life") {
    ParticleEmitter em = quiet();
    em.speed = 100;
    em.direction = 0;
    em.spread = 0;
    em.lifetime = 2.0f;
    em.speedCurve = Json::parse("[[0, 1], [0.5, 0], [1, 0]]");  // stops half way through its life
    ParticleSim s = born(em, 1);
    ParticleEnv env;
    for (int i = 0; i < 60; ++i) s.step(em, env, 1.0f / 60.0f);  // 1 s = half the life
    const float x = s.particles[0].pos.x;
    CHECK(x == doctest::Approx(50.0f).epsilon(0.05));  // linear fade from full to nothing over 1 s: 50 units
    for (int i = 0; i < 30; ++i) s.step(em, env, 1.0f / 60.0f);
    CHECK(s.particles[0].pos.x == doctest::Approx(x).epsilon(1e-4));
    CHECK(s.particles[0].vel.x == doctest::Approx(100.0f));  // the velocity itself is not changed
}

// --------------------------------------------------------------- collision --

TEST_CASE("particle collision: a plane stops, bounces and kills") {
    ParticleEmitter em = quiet();
    em.gravity = {0, -300, 0};
    em.collision = ParticleCollision::Plane;
    em.collisionPlane = {0, 1, 0, 0};
    em.collisionBounce = 0.5f;
    ParticleSim s = born(em, 1, 1, Mat4::translate({0, 100, 0}));
    ParticleEnv env;
    float minY = 1e9f;
    bool bounced = false;
    float lastVy = 0;
    for (int i = 0; i < 240; ++i) {
        s.step(em, env, 1.0f / 60.0f);
        const Particle& p = s.particles[0];
        minY = std::min(minY, p.pos.y);
        if (lastVy < -50.0f && p.vel.y > 0.0f) bounced = true;
        lastVy = p.vel.y;
    }
    CHECK(minY >= -1e-3f);  // never under the floor
    CHECK(bounced);
    CHECK(s.particles[0].pos.y < 5.0f);  // came to rest on it, not floating away

    em.collisionKill = true;
    ParticleSim k = born(em, 1, 1, Mat4::translate({0, 100, 0}));
    for (int i = 0; i < 120; ++i) k.step(em, env, 1.0f / 60.0f);
    CHECK(k.particles.empty());
}

TEST_CASE("particle collision: an inclined plane, friction and lifetime loss") {
    ParticleEmitter em = quiet();
    em.speed = 100;
    em.direction = 270;  // down
    em.spread = 0;
    em.gravity = {0, 0, 0};
    em.collision = ParticleCollision::Plane;
    em.collisionPlane = {0, 1, 0, -20};  // the floor is y = -20
    em.collisionBounce = 1.0f;
    em.collisionLifetimeLoss = 0.5f;
    em.lifetime = 4.0f;
    ParticleSim s = born(em, 1);
    ParticleEnv env;
    for (int i = 0; i < 30; ++i) s.step(em, env, 1.0f / 60.0f);  // hits at 0.2 s
    REQUIRE(s.particles.size() == 1);
    CHECK(s.particles[0].vel.y > 0.0f);                             // went back up
    CHECK(s.particles[0].age == doctest::Approx(0.5f + 2.0f).epsilon(0.1));  // lost half of its life on the hit
    for (int i = 0; i < 120; ++i) s.step(em, env, 1.0f / 60.0f);
    CHECK(s.particles.empty());  // the lifetime loss let it die early
}

TEST_CASE("particle collision: a tilemap floor holds particles, walls turn them back") {
    Tilemap tm;
    tm.width = 12;
    tm.height = 4;
    tm.tileSize = {16, 16};
    std::string tiles;
    for (int r = 0; r < 4; ++r)
        for (int c = 0; c < 12; ++c) {
            const bool solid = r == 0 || r == 3 || c == 0 || c == 11;
            tiles += std::string(tiles.empty() ? "" : ",") + (solid ? "0" : "-1");
        }
    tm.tiles = Json::parse("[" + tiles + "]");
    tm.solidTiles = Json::parse("[0]");
    // A room: row 0 is the ceiling (its underside is y = -16), row 3 the floor (its top is y = -48), column 0 is x in [0, 16] and
    // column 11 is x in [176, 192].
    ParticleEmitter em = quiet();
    em.collision = ParticleCollision::Tilemap;
    em.gravity = {0, -400, 0};
    em.collisionBounce = 0.3f;
    em.speed = 150;
    em.speedVariance = 0.5f;
    em.direction = 60;
    em.spread = 60;
    em.lifetime = 100.0f;
    ParticleSim s;
    s.seed(9);
    ParticleEnv env;
    env.emitter = Mat4::translate({96, -32, 0});
    env.tilemap = &tm;
    env.tilemapWorld = Mat4::identity();
    s.spawn(em, env, 60);
    for (int i = 0; i < 360; ++i) {
        s.step(em, env, 1.0f / 60.0f);
        for (const Particle& p : s.particles) {
            REQUIRE(p.pos.y >= -48.0f - 1e-2f);
            REQUIRE(p.pos.y <= -16.0f + 1e-2f);
            REQUIRE(p.pos.x >= 16.0f - 1e-2f);
            REQUIRE(p.pos.x <= 176.0f + 1e-2f);
        }
    }
    REQUIRE(s.particles.size() == 60);
    for (const Particle& p : s.particles) CHECK(p.pos.y < -40.0f);  // all of them came down to the floor
    // A tilemap with no solid tiles does nothing: particles fall through.
    Tilemap open = tm;
    open.solidTiles = Json::array();
    ParticleSim f;
    f.seed(9);
    env.tilemap = &open;
    f.spawn(em, env, 5);
    for (int i = 0; i < 120; ++i) f.step(em, env, 1.0f / 60.0f);
    for (const Particle& p : f.particles) CHECK(p.pos.y < -100.0f);
    // And a moved tilemap: the same floor, 500 units to the right.
    env.tilemap = &tm;
    env.tilemapWorld = Mat4::translate({500, 0, 0});
    env.emitter = Mat4::translate({596, -32, 0});
    ParticleSim m;
    m.seed(9);
    m.spawn(em, env, 20);
    for (int i = 0; i < 240; ++i) m.step(em, env, 1.0f / 60.0f);
    for (const Particle& p : m.particles) {
        CHECK(p.pos.y >= -48.0f - 1e-2f);
        CHECK(p.pos.x >= 516.0f - 1e-2f);
    }
}

TEST_CASE("particle collision: it needs worldSpace, and is off for a screen-space emitter") {
    ParticleEmitter em = quiet();
    em.gravity = {0, -300, 0};
    em.collision = ParticleCollision::Plane;
    em.collisionPlane = {0, 1, 0, 0};
    em.worldSpace = false;
    ParticleSim s = born(em, 1, 1, Mat4::translate({0, 10, 0}));
    ParticleEnv env;
    env.emitter = Mat4::translate({0, 10, 0});
    for (int i = 0; i < 60; ++i) s.step(em, env, 1.0f / 60.0f);
    CHECK(s.particles[0].pos.y < -50.0f);  // local to the emitter: the plane does not apply
}

// ------------------------------------------------------------- sub-emitters --

TEST_CASE("sub-emitters: death spawns children where the parent was, once") {
    ParticleEmitter em = quiet();
    em.lifetime = 0.1f;
    em.speed = 0;
    em.subEmitters = Json::parse(R"({"death": {"count": 4, "emitter": {"lifetime": 5, "lifetimeVariance": 0, "speed": 10, "spread": 180}}})");
    ParticleSim s = born(em, 3, 1, Mat4::translate({10, 20, 0}));
    ParticleEnv env;
    env.emitter = Mat4::translate({10, 20, 0});
    CHECK(s.particles.size() == 3);
    s.step(em, env, 0.2f);
    CHECK(s.particles.size() == 12);
    for (const Particle& p : s.particles) {
        CHECK(p.group == 1);
        CHECK(p.pos.x == doctest::Approx(10.0f));
        CHECK(p.pos.y == doctest::Approx(20.0f));
        CHECK(p.life == doctest::Approx(5.0f));
    }
    CHECK(s.live(0) == 0);
    CHECK(s.live(1) == 12);
    s.step(em, env, 0.2f);
    CHECK(s.particles.size() == 12);  // the children die much later: no second wave
}

TEST_CASE("sub-emitters: birth, chance and inherited velocity") {
    ParticleEmitter em = quiet();
    em.speed = 100;
    em.direction = 0;
    em.spread = 0;
    em.subEmitters = Json::parse(R"({"birth": {"count": 2, "inherit": 0.5, "emitter": {"speed": 0, "lifetime": 3}}})");
    ParticleSim s = born(em, 4);
    CHECK(s.particles.size() == 12);  // 4 parents + 8 children
    int children = 0;
    for (const Particle& p : s.particles)
        if (p.group == 1) {
            ++children;
            CHECK(p.vel.x == doctest::Approx(50.0f));
        }
    CHECK(children == 8);

    em.subEmitters = Json::parse(R"({"birth": {"count": 1, "chance": 0.5, "emitter": {"speed": 0}}})");
    ParticleSim c = born(em, 400);
    const int n = int(c.particles.size()) - 400;
    CHECK(n > 120);
    CHECK(n < 280);
}

TEST_CASE("sub-emitters: collision children are born along the surface normal") {
    ParticleEmitter em = quiet();
    em.gravity = {0, -300, 0};
    em.collision = ParticleCollision::Plane;
    em.collisionPlane = {0, 1, 0, 0};
    em.subEmitters = Json::parse(R"({"collision": {"count": 6, "emitter": {"speed": 50, "spread": 0, "direction": 90, "lifetime": 1, "gravity": [0, 0, 0], "speedVariance": 0}}})");
    ParticleSim s = born(em, 1, 1, Mat4::translate({0, 50, 0}));
    ParticleEnv env;
    for (int i = 0; i < 90; ++i) s.step(em, env, 1.0f / 60.0f);
    int kids = 0;
    for (const Particle& p : s.particles)
        if (p.group == 1) {
            ++kids;
            CHECK(p.vel.y > 0.0f);  // direction 90 = up = the floor's normal
            CHECK(std::fabs(p.vel.x) < 1e-2f);
        }
    CHECK(kids >= 6);
}

TEST_CASE("sub-emitters: bounded count, depth and groups") {
    ParticleEmitter em = quiet();
    // One event never spawns more than kParticleSubCount.
    em.subEmitters = Json::parse(R"({"birth": {"count": 500, "emitter": {"speed": 0}}})");
    ParticleSim a = born(em, 1);
    CHECK(int(a.particles.size()) == 1 + kParticleSubCount);

    // Three levels below the emitter: the third is not used.
    em.subEmitters = Json::parse(R"({"birth": {"count": 2, "emitter": {"speed": 0, "subEmitters":
        {"birth": {"count": 2, "emitter": {"speed": 0, "subEmitters":
            {"birth": {"count": 2, "emitter": {"speed": 0}}}}}}}}})");
    ParticleSim b = born(em, 1);
    CHECK(b.particles.size() == 1 + 2 + 4);
    for (const Particle& p : b.particles) CHECK(p.group <= 2);
    bool warned = false;
    for (const ParticleProblem& p : particle_emitter_problems(em)) warned = warned || (!p.error && p.message.find("deep") != std::string::npos);
    CHECK(warned);

    // Per step, sub-emitters stop at kParticleSubPerStep however many parents there are.
    em.subEmitters = Json::parse(R"({"birth": {"count": 32, "emitter": {"speed": 0}}})");
    ParticleSim c;
    c.seed(1);
    ParticleEnv env;
    c.spawn(em, env, 100);
    CHECK(int(c.particles.size()) == 100 + kParticleSubPerStep);

    // More sub-emitters than kParticleSubGroups: the rest are ignored (and said so once).
    Json many = Json::array();
    for (int i = 0; i < kParticleSubGroups + 4; ++i) many.push_back(Json::parse(R"({"count": 1, "emitter": {"speed": 0}})"));
    em.subEmitters = Json::object({{"birth", many}});
    ParticleSim d = born(em, 1);
    CHECK(int(d.particles.size()) <= 1 + kParticleSubGroups + 1);
    CHECK(d.particles.size() > 4);
    CHECK_FALSE(d.take_problems().empty());
    CHECK(d.take_problems().empty());  // each problem once
}

TEST_CASE("sub-emitters: a bad specification is reported, not thrown, and does not stop the parent") {
    ParticleEmitter em = quiet();
    em.subEmitters = Json::parse(R"({"death": {"count": 2}, "birth": {"emitter": {"lifetime": "long"}}, "boom": {}})");
    ParticleSim s = born(em, 3);
    CHECK(s.particles.size() == 3);
    const auto problems = s.take_problems();
    CHECK(problems.size() >= 3);
    bool didYouMean = false;
    for (const std::string& p : problems) didYouMean = didYouMean || p.find("birth") != std::string::npos;
    CHECK(didYouMean);
}

TEST_CASE("sub-emitters: an inline emitter, a prefab file and another entity's emitter") {
    namespace stdfs = std::filesystem;
    const stdfs::path dir = stdfs::temp_directory_path() / "fa_particles_prefab_test";
    std::error_code ec;
    stdfs::remove_all(dir, ec);
    stdfs::create_directories(dir, ec);
    const std::string path = (dir / "spark.prefab.json").string();
    REQUIRE(fs::write_text(path, R"({"format": "factoria.prefab/1", "entity": {"id": "spark", "children": [{"id": "inner", "components":
        {"ParticleEmitter": {"lifetime": 7, "lifetimeVariance": 0, "speed": 0, "startSize": 3}}}]}})"));
    auto loaded = load_prefab_particle_emitter(path);
    REQUIRE(loaded);
    CHECK(loaded->lifetime == doctest::Approx(7.0f));
    CHECK(loaded->startSize == doctest::Approx(3.0f));
    auto missing = load_prefab_particle_emitter((dir / "none.prefab.json").string());
    REQUIRE_FALSE(missing);
    CHECK(missing.error().message.find("none.prefab.json") != std::string::npos);

    ParticleEmitter em = quiet();
    em.subEmitters = Json::object({{"birth", Json::object({{"count", 1}, {"prefab", path}})}});
    ParticleSim p = born(em, 2);
    REQUIRE(p.particles.size() == 4);
    CHECK(p.particles[1].life == doctest::Approx(7.0f));

    ParticleEmitter other = quiet();
    other.lifetime = 9.0f;
    em.subEmitters = Json::parse(R"({"birth": {"count": 1, "entity": "spark-source"}})");
    ParticleSim e;
    e.seed(1);
    ParticleEnv env;
    env.findEmitter = [&](std::string_view id) -> const ParticleEmitter* { return id == "spark-source" ? &other : nullptr; };
    e.spawn(em, env, 2);
    REQUIRE(e.particles.size() == 4);
    CHECK(e.particles[1].life == doctest::Approx(9.0f));
    other.lifetime = 4.0f;  // an edit of the source shows in the next particles
    e.spawn(em, env, 1);
    CHECK(e.particles.back().life == doctest::Approx(4.0f));
    // An entity that is not there: reported once, nothing born.
    ParticleSim none;
    none.seed(1);
    ParticleEnv noEnv;
    none.spawn(em, noEnv, 2);
    CHECK(none.particles.size() == 2);
    CHECK_FALSE(none.take_problems().empty());
    stdfs::remove_all(dir, ec);
}

// ------------------------------------------------------------------ budgets --

TEST_CASE("particle budgets: maxParticles and the hard cap hold") {
    ParticleEmitter em = quiet();
    em.maxParticles = 50;
    ParticleSim a = born(em, 500);
    CHECK(a.particles.size() == 50);

    em.maxParticles = 1000000;  // more than the cap
    ParticleSim b = born(em, 20000);
    CHECK(int(b.particles.size()) == kParticleHardCap);

    em.rate = 1.0e6f;  // a runaway rate does not run away
    ParticleSim c;
    c.seed(1);
    ParticleEnv env;
    c.step(em, env, 1.0f);
    CHECK(int(c.particles.size()) == kParticleHardCap);
}

// --------------------------------------------------------------- trails ----

TEST_CASE("particle trails: a per-particle trail keeps at most kParticleTrailPoints and trailTime of path") {
    ParticleEmitter em = quiet();
    em.speed = 100;
    em.direction = 0;
    em.spread = 0;
    em.trail = ParticleTrail::Particle;
    em.trailTime = 0.5f;
    ParticleSim s = born(em, 1);
    ParticleEnv env;
    for (int i = 0; i < 300; ++i) s.step(em, env, 1.0f / 60.0f);
    const Particle& p = s.particles[0];
    CHECK(p.trail.size() >= 8);
    CHECK(int(p.trail.size()) <= kParticleTrailPoints);
    CHECK(p.trail.back().pos.x > p.trail.front().pos.x);  // newest last
    CHECK(float(s.clock()) - p.trail.front().time <= 0.5f + 1e-3f);
    // The head of the trail is where the particle is.
    CHECK(p.trail.back().pos.x == doctest::Approx(p.pos.x).epsilon(0.02));

    ParticleEmitter off = em;
    off.trail = ParticleTrail::None;
    ParticleSim n = born(off, 1);
    for (int i = 0; i < 30; ++i) n.step(off, env, 1.0f / 60.0f);
    CHECK(n.particles[0].trail.empty());
}

TEST_CASE("particle trails: an emitter trail follows the emitter, a still emitter leaves a short one") {
    ParticleEmitter em = quiet();
    em.trail = ParticleTrail::Emitter;
    em.trailTime = 1.0f;
    ParticleSim s;
    s.seed(1);
    ParticleEnv env;
    for (int i = 0; i < 120; ++i) {
        env.emitter = Mat4::translate({float(i), 0, 0});
        s.step(em, env, 1.0f / 60.0f);
    }
    REQUIRE(s.emitterTrail.size() > 5);
    CHECK(int(s.emitterTrail.size()) <= kParticleTrailPoints);
    CHECK(s.emitterTrail.back().pos.x > s.emitterTrail.front().pos.x);
    CHECK(s.emitterTrail.back().pos.x >= 117.0f);
    // It fades away after the emitter stops emitting.
    em.emitting = false;
    for (int i = 0; i < 120; ++i) s.step(em, env, 1.0f / 60.0f);
    CHECK(s.emitterTrail.empty());
}

// ------------------------------------------------------------ the scene loader --

TEST_CASE("particle emitters: old scenes load unchanged, new fields round trip, mistakes are reported with their pointer") {
    auto scene = [](const char* emitter) {
        return Json::parse(std::string(R"({"format": "factoria.scene/1", "entities": [{"id": "fx", "components": {"Transform": {}, "ParticleEmitter": )") +
                           emitter + "}}]}");
    };
    World w;
    LoadReport ok = load_scene(w, scene(R"({"rate": 5, "startColor": "#ff0000", "gravity": [0, -50, 0]})"), "old.scene.json");
    REQUIRE(ok.ok());
    CHECK(ok.messages.empty());
    const ParticleEmitter* pe = w.get<ParticleEmitter>(w.find_by_id("fx"));
    REQUIRE(pe);
    CHECK(pe->rate == doctest::Approx(5.0f));
    CHECK(pe->shape == ParticleShape::Point);
    CHECK(pe->trail == ParticleTrail::None);
    CHECK(pe->collision == ParticleCollision::None);
    CHECK(pe->sizeCurve.empty());
    CHECK(pe->seed == 0);
    CHECK(pe->pixelMode == false);

    World w2;
    LoadReport good = load_scene(w2, scene(R"({"shape": "circle", "shapeFrom": "edge", "trail": "particle", "collision": "plane",
        "colorGradient": [[0, "#ffffff"], [1, "#ff000000"]], "sizeCurve": [[0, 1], [1, 0]], "pixelMode": true, "seed": 5})"), "new.scene.json");
    REQUIRE(good.ok());
    pe = w2.get<ParticleEmitter>(w2.find_by_id("fx"));
    REQUIRE(pe);
    CHECK(pe->shape == ParticleShape::Circle);
    CHECK(pe->shapeFrom == ParticleShapeFrom::Edge);
    CHECK(pe->trail == ParticleTrail::Particle);
    CHECK(pe->collision == ParticleCollision::Plane);
    CHECK(pe->seed == 5);
    CHECK(pe->colorGradient.size() == 2);

    World w3;
    LoadReport bad = load_scene(w3, scene(R"({"sizeCurve": [[0]]})"), "bad.scene.json");
    CHECK_FALSE(bad.ok());
    const std::string text = bad.summary();
    CHECK(text.find("sizeCurve") != std::string::npos);
    CHECK(text.find("bad.scene.json") != std::string::npos);
    CHECK(text.find("/entities/0/components/ParticleEmitter/sizeCurve") != std::string::npos);

    World w4;
    LoadReport warn = load_scene(w4, scene(R"({"collision": "plane", "worldSpace": false})"), "warn.scene.json");
    CHECK(warn.ok());  // does nothing, but still loads
    CHECK(warn.summary().find("collision") != std::string::npos);

    World w5;
    LoadReport shape = load_scene(w5, scene(R"({"shape": "sphere"})"), "shape.scene.json");
    CHECK_FALSE(shape.ok());
    CHECK(shape.summary().find("circle") != std::string::npos);
}
