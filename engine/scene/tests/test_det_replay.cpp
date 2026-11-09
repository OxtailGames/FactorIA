// M91.3: replay hashes of the parts of the simulation scripts cannot reach: particles (ParticleSim) and the feel effects (shake,
// flash, squash, knockback). Each is run for a few hundred steps, every number is fed to a SHA-256 by its exact bits, and the first
// 16 hex digits are compared with a COMMITTED value on every CI platform. The line "FA_DET_HASH ..." is printed by every run
// (`ctest -R det_replay_hashes -V`), so a platform that differs shows its value next to the expected one.
//
// The scripts', 2D and 3D physics' and nav's hashes are in engine/runtime/tests/det_probe_tests.cpp (they need an engine around
// them, and the same script runs in the Android, iOS and web CI jobs). The physics replay of test_determinism.cpp stays.
//
// These sims use only + - * / sqrt and fa::det trigonometry, so ONE value must hold on x86-64, arm64 and wasm:
//   * only this platform differs -> a determinism bug (a libm call, an unordered iteration, floating-point contraction);
//   * every platform differs the same way -> the simulation changed on purpose: copy the printed value into kExpected*.
// M91.1a moves the SpriteAnimator and particle SIMULATION STEP into the engine's step; when its test files exist, add their scenes
// here the same way (and their directories to the source scan, engine/core/tests/test_det_scan.cpp).
#include <doctest.h>

#include <cstdint>
#include <cstdio>
#include <cstring>
#include <string>

#include "fa/core/hash.h"
#include "fa/scene/feel.h"
#include "fa/scene/particles.h"
#include "fa/scene/world.h"

using namespace fa;

namespace {

// Committed. Particles and feel are separate so a failure names the system.
constexpr const char* kExpectedParticles = "04f3b65a399adaf9";
constexpr const char* kExpectedFeel = "198e1130c22603ad";

void feed(Sha256& h, float v) {
    std::uint32_t bits;
    std::memcpy(&bits, &v, sizeof bits);
    h.update(&bits, sizeof bits);
}
void feed(Sha256& h, std::int64_t v) { h.update(&v, sizeof v); }
void feed(Sha256& h, Vec3 v) { feed(h, v.x); feed(h, v.y); feed(h, v.z); }

// `seen` counts what the hash covered, so a scene that stops doing anything cannot pass with a hash of nothing.
std::string particles_hash(std::int64_t* seen = nullptr) {
    Sha256 h;
    std::int64_t particlesSeen = 0, trailPoints = 0;
    // An emitter with most of what the sim does: a 3D cone, spread, spin, drag, turbulence, size variance, trails on the
    // particles, and a sub-emitter at death.
    ParticleEmitter em;
    em.rate = 90.0f;
    em.burst = 12;
    em.maxParticles = 400;
    em.lifetime = 1.4f;
    em.lifetimeVariance = 0.3f;
    em.speed = 160.0f;
    em.speedVariance = 0.4f;
    em.direction = 70.0f;
    em.spread = 35.0f;
    em.gravity = {0, -180, 20};
    em.is3D = true;
    em.startRotation = {0.0f, 90.0f};
    em.spin = {-120.0f, 240.0f};
    em.drag = 0.6f;
    em.noiseStrength = 140.0f;
    em.noiseScale = 48.0f;
    em.noiseSpeed = 0.7f;
    em.sizeVariance = 0.25f;
    em.shape = ParticleShape::Circle;
    em.shapeSize = {24.0f, 24.0f, 24.0f};
    em.trail = ParticleTrail::Particle;
    em.trailTime = 0.4f;
    em.subEmitters = Json::object({{"death", Json::object({{"count", 3},
                                                           {"emitter", Json::object({{"lifetime", 0.5}, {"speed", 60}, {"rate", 0}})}})}});

    ParticleSim sim;
    sim.seed(0x5eed1234u);
    ParticleEnv env;
    env.is3D = true;
    env.emitter = Mat4::translate({10, 20, 30});
    const float dt = 1.0f / 60.0f;
    for (int step = 0; step < 300; ++step) {
        if (step == 100) sim.queue_burst(25);
        env.emitter = Mat4::translate({10.0f + 0.5f * float(step), 20, 30});  // a moving emitter: inherited velocity, world space
        sim.step(em, env, dt);
        if (step % 5 == 4) {
            feed(h, std::int64_t(sim.particles.size()));
            particlesSeen += std::int64_t(sim.particles.size());
            for (const Particle& p : sim.particles) {
                feed(h, p.pos);
                feed(h, p.vel);
                feed(h, p.age);
                feed(h, p.rotation);
                feed(h, p.sizeScale);
                feed(h, std::int64_t(p.group));
                for (int i = 0; i < sim.trail_size(p); ++i) {
                    feed(h, sim.trail_point(p, i).pos);
                    ++trailPoints;
                }
            }
        }
    }
    if (seen) *seen = particlesSeen * 1000000 + trailPoints;
    return h.finish_hex().substr(0, 16);
}

std::string feel_hash(std::int64_t* seen = nullptr) {
    std::int64_t poses = 0, flashes = 0;
    ensure_builtin_components();
    World w;
    Entity cam = w.create("cam", "cam");
    w.add<Camera>(cam).orthoSize = 90.0f;
    Entity box = w.create("box", "box");
    w.get<Transform>(box)->position = {3, 4, 0};
    w.get<Transform>(box)->scale = {2, 3, 1};
    w.add<Sprite>(box);
    Entity ball = w.create("ball", "ball");
    w.get<Transform>(ball)->position = {-5, 1, 2};
    w.add<Sprite>(ball);

    Sha256 h;
    const double dt = 1.0 / 60.0;
    for (int frame = 0; frame < 240; ++frame) {
        if (frame == 0) {
            REQUIRE(feel_shake(w, cam, {0.9f, 0.8f}).ok());
            REQUIRE(feel_squash(w, box, {0.35f, 0.4f, 'y'}).ok());
        }
        if (frame == 20) {
            FlashOptions f;
            f.color = {1.0f, 0.2f, 0.1f, 1.0f};
            f.duration = 0.3f;
            REQUIRE(feel_flash(w, box, f).ok());
            KnockbackOptions k;
            k.direction = {1.0f, 0.5f, 0.0f};
            REQUIRE(feel_knockback(w, ball, k).ok());
        }
        if (frame == 60) REQUIRE(feel_shake(w, cam, {0.5f, 1.2f, 40.0f}).ok());
        if (frame == 90) REQUIRE(feel_hit_stop(w, {0.2f, 0.1f}).ok());
        feel_begin_frame(w, dt, false);
        feel_fixed_update(w, dt * w.feel().hit_stop_factor());
        feel_update(w, dt, dt * w.feel().hit_stop_factor());
        w.advance_clock(dt * w.feel().hit_stop_factor());
        feed(h, w.feel().hit_stop_factor());
        for (Entity e : {cam, box, ball}) {
            const FeelPose* p = w.feel().pose_of(e);
            feed(h, std::int64_t(p ? 1 : 0));
            if (p) {
                ++poses;
                feed(h, p->position);
                feed(h, p->rotation);
                feed(h, p->scale);
            }
            const auto flash = w.feel().flash_of(e);
            feed(h, std::int64_t(flash ? 1 : 0));
            if (flash) {
                ++flashes;
                feed(h, flash->r); feed(h, flash->g); feed(h, flash->b); feed(h, flash->a);
            }
            feed(h, w.get<Transform>(e)->position);
        }
    }
    if (seen) *seen = poses * 1000000 + flashes;
    return h.finish_hex().substr(0, 16);
}

void check(const char* name, const std::string& got, const char* expected) {
    std::printf("FA_DET_HASH platform=%s %s=%s expected=%s\n", FA_PLATFORM_NAME, name, got.c_str(), expected);
    std::fflush(stdout);
    INFO("The " << name << " replay hash on " << FA_PLATFORM_NAME << " is " << got << ", expected " << expected
                << ". Only this platform differs: a determinism bug (a libm call, an unordered iteration, floating-point contraction). "
                   "Every platform differs: the simulation changed on purpose, update kExpected in test_det_replay.cpp.");
    CHECK(got == expected);
}

}  // namespace

TEST_CASE("det replay: the same build gives the same particle and feel hashes twice") {
    CHECK(particles_hash() == particles_hash());
    CHECK(feel_hash() == feel_hash());
}

TEST_CASE("det replay: particles match the committed hash") {
    std::int64_t seen = 0;
    const std::string got = particles_hash(&seen);
    CHECK(seen / 1000000 > 1000);  // particles seen over the run (summed over the sampled steps)
    CHECK(seen % 1000000 > 1000);  // trail points
    check("particles", got, kExpectedParticles);
}

TEST_CASE("det replay: feel effects match the committed hash") {
    std::int64_t seen = 0;
    const std::string got = feel_hash(&seen);
    CHECK(seen / 1000000 > 100);  // frames with a visual pose (shake, squash, knockback)
    CHECK(seen % 1000000 > 10);   // frames with a flash
    check("feel", got, kExpectedFeel);
}
