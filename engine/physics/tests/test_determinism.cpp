// Physics determinism across platforms (M26.21, CC/FB-0055). A replay of a chaotic scene (a rope bridge, tumbling boxes, a
// 2D pile) is hashed bit for bit, and the hash is compared with a COMMITTED expected value on every CI platform: each job
// runs this test, prints its hash ("FA_PHYSICS_REPLAY_HASH ..."), and a mismatch fails naming the platforms that are known
// to agree and what to do. The same build on the same platform always gives the same hash (the first test case); another
// compiler or CPU may not, mostly through the C library's sin / cos / atan2 / asin (physics3d.cpp, shape3d.cpp,
// physics3d_joints.cpp, scene/world.cpp: see docs/AI_GUIDE.md, "Physics and platforms").
//
// When this test fails on a platform you did not expect to differ:
//   1. Run `ctest -R physics_determinism -V` there and read the printed hash.
//   2. If a code change moved ALL platforms together (same new hash everywhere), update kReferenceHash.
//   3. If only this platform differs, add a kPlatformHashes entry for it and list the platform in docs/AI_GUIDE.md.
#include <doctest.h>

#include <array>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <string>

#include "fa/core/hash.h"
#include "fa/physics/physics.h"

using namespace fa;

namespace {

constexpr float kDt = 1.0f / 60.0f;

// The hash every platform is expected to produce (SHA-256 of the replay, first 16 hex digits).
constexpr const char* kReferenceHash = "9221e6b395dd3232";

struct PlatformHash {
    const char* key;   // "<platform>-<arch>", see platform_key()
    const char* hash;  // what that platform produces when it differs from kReferenceHash
};
// Platforms that are known NOT to match the reference. Empty while every platform matches.
constexpr std::array<PlatformHash, 0> kPlatformHashes{};

// Platforms whose result is known to equal kReferenceHash (updated from CI logs; the failure message lists them).
constexpr const char* kKnownMatching = "macos-arm64";

std::string platform_key() {
#if defined(__aarch64__) || defined(_M_ARM64)
    const char* arch = "arm64";
#elif defined(__x86_64__) || defined(_M_X64)
    const char* arch = "x86_64";
#elif defined(__wasm__)
    const char* arch = "wasm";
#else
    const char* arch = "other";
#endif
    return std::string(FA_PLATFORM_NAME) + "-" + arch;
}

void feed(Sha256& h, float v) {
    std::uint32_t bits;
    std::memcpy(&bits, &v, sizeof bits);
    h.update(&bits, sizeof bits);
}
void feed(Sha256& h, Vec3 v) { feed(h, v.x); feed(h, v.y); feed(h, v.z); }

void add_slab(World& w, const char* id, Vec3 pos, Vec3 size, Vec3 rot = {0, 0, 0}) {
    Entity e = w.create(id, id);
    Transform* t = w.get<Transform>(e);
    t->position = pos;
    t->rotation = rot;
    w.add<Collider3D>(e).size = size;
    w.add<RigidBody3D>(e).type = BodyType::Static;
}

// Everything is built from literals and + - * /, never from the C library, so every platform starts from the same bits.
struct Replay {
    std::string all, d3, d2;  // first 16 hex digits: everything, the 3D bodies only, the 2D bodies only
};
Replay replay_hash() {
    World world;
    Physics physics;
    physics.init(PhysicsSettings{});

    add_slab(world, "ground", {0, -0.5f, 0}, {40, 1, 20});
    add_slab(world, "ramp", {6, 0.6f, 0}, {5, 0.3f, 4}, {0, 0, 20});

    // A rope bridge of 8 planks hinged to each other, ends on static posts (like the Clockwork Courier's).
    const int n = 8;
    std::vector<Entity> planks;
    for (int i = 0; i < n; ++i) {
        Entity e = world.create("plank" + std::to_string(i), "plank" + std::to_string(i));
        Transform* t = world.get<Transform>(e);
        t->position = {-8.0f + float(i) + 0.5f, 3.0f - 0.1f * float(i < n / 2 ? i : n - 1 - i), -3};
        t->rotation = {0, 0, (float(i) - 3.5f) * 1.25f};
        world.add<Collider3D>(e).size = {0.94f, 0.14f, 0.6f};
        world.add<RigidBody3D>(e).mass = 6.0f;
        planks.push_back(e);
    }
    for (int i = 0; i < n; ++i) {
        Joint3D& j = world.add<Joint3D>(planks[std::size_t(i)]);
        j.axis = {0, 0, 1};
        j.anchor = {0.47f, 0, 0};
        if (i + 1 < n) j.connected = planks[std::size_t(i + 1)];
    }
    add_slab(world, "post", {-8.5f, 3.0f, -3}, {0.05f, 0.05f, 0.05f});
    Entity post = world.find("post");
    Joint3D& pj = world.add<Joint3D>(post);
    pj.axis = {0, 0, 1};
    pj.connected = planks[0];

    // Boxes and balls dropped tumbling onto the ramp and the ground.
    for (int i = 0; i < 10; ++i) {
        Entity e = world.create("box" + std::to_string(i), "box" + std::to_string(i));
        Transform* t = world.get<Transform>(e);
        t->position = {4.0f + 0.35f * float(i % 4), 3.0f + 1.1f * float(i), 0.2f * float(i % 3)};
        t->rotation = {7.0f * float(i), 11.0f * float(i), 5.0f * float(i)};
        Collider3D& c = world.add<Collider3D>(e);
        if (i % 3 == 0) { c.shape = ColliderShape3D::Sphere; c.radius = 0.4f; }
        else c.size = {0.7f, 0.5f + 0.05f * float(i), 0.6f};
        c.restitution = 0.2f;
        RigidBody3D& b = world.add<RigidBody3D>(e);
        b.angularVelocity = {90.0f + 13.0f * float(i), 40.0f, -55.0f + 9.0f * float(i)};
        b.velocity = {-0.5f, 0, 0};
    }

    // A 2D pile (Box2D).
    {
        Entity floor = world.create("floor2d", "floor2d");
        world.get<Transform>(floor)->position = {0, 0, 0};
        world.add<Collider2D>(floor).size = {800, 20};
        world.add<RigidBody2D>(floor).type = BodyType::Static;
        for (int i = 0; i < 12; ++i) {
            Entity e = world.create("c" + std::to_string(i), "c" + std::to_string(i));
            world.get<Transform>(e)->position = {float(i % 3) * 9.0f - 9.0f, 40.0f + 30.0f * float(i), 0};
            Collider2D& c = world.add<Collider2D>(e);
            if (i % 2) { c.shape = ColliderShape::Circle; c.radius = 12.0f; }
            else c.size = {24, 20};
            world.add<RigidBody2D>(e);
        }
    }

    Sha256 h, h3, h2;
    const std::vector<Entity> all = world.entities();
    for (int step = 0; step < 360; ++step) {
        world.events().clear();
        physics.step(world, kDt);
        world.advance_clock(kDt);
        world.flush();
        if (step % 6 == 5) {
            for (Entity e : all) {
                if (!world.get<RigidBody3D>(e) && !world.get<RigidBody2D>(e)) continue;
                const Transform* t = world.get<Transform>(e);
                Sha256& part = world.get<RigidBody3D>(e) ? h3 : h2;
                for (Sha256* x : {&h, &part}) {
                    feed(*x, t->position);
                    feed(*x, t->rotation);
                }
            }
        }
    }
    return {h.finish_hex().substr(0, 16), h3.finish_hex().substr(0, 16), h2.finish_hex().substr(0, 16)};
}

}  // namespace

TEST_CASE("physics replay: the same build gives the same hash twice") {
    CHECK(replay_hash().all == replay_hash().all);
}

TEST_CASE("physics replay hash matches the committed value of this platform") {
    const std::string key = platform_key();
    const Replay replay = replay_hash();
    const std::string& got = replay.all;
    std::string expected = kReferenceHash;
    bool override_ = false;
    for (const PlatformHash& p : kPlatformHashes)
        if (key == p.key) { expected = p.hash; override_ = true; }
    std::printf("FA_PHYSICS_REPLAY_HASH platform=%s hash=%s expected=%s%s (3d=%s 2d=%s)\n", key.c_str(), got.c_str(),
                expected.c_str(), override_ ? " (platform-specific)" : " (reference)", replay.d3.c_str(), replay.d2.c_str());
    std::fflush(stdout);
    if (got != expected) {
        const std::string msg =
            "physics replay hash on " + key + " is " + got + ", expected " + expected +
            (override_ ? " (this platform's own value).\n" : " (the reference value).\n") +
            "Platforms known to produce the reference: " + kKnownMatching + ".\n" +
            "If " + key + " is a new platform or a compiler/CPU that rounds differently, this is expected drift: add {\"" + key +
            "\", \"" + got + "\"} to kPlatformHashes in engine/physics/tests/test_determinism.cpp and list " + key +
            " under \"Physics and platforms\" in docs/AI_GUIDE.md. If a physics change moved every platform, update " +
            "kReferenceHash instead (every job prints its hash: they should all print the same).";
        FAIL(msg);
    }
}
