// The engine and the job system (fa/core/jobs.h): where the thread count comes from, jobs.info, and the determinism
// rule checked with game.state_hash (the same game with 0, 1, N job threads or inline mode gives the same hash).
#include <doctest.h>

#include <atomic>
#include <chrono>
#include <cmath>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <string>
#include <thread>
#include <vector>

#include "fa/core/fs.h"
#include "fa/core/jobs.h"
#include "fa/physics/physics.h"
#include "fa/runtime/engine.h"
#include "fa/runtime/project.h"
#include "fa/scene/components.h"
#include "fa/scene/state_hash.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

// Sets (or, with nullptr, removes) an environment variable for the length of a test, and restores what was there.
struct ScopedEnv {
    std::string name;
    std::string old;
    bool had = false;
    ScopedEnv(const char* n, const char* value) : name(n) {
        if (const char* v = std::getenv(n)) {
            had = true;
            old = v;
        }
        set(value);
    }
    ~ScopedEnv() { set(had ? old.c_str() : nullptr); }
    void set(const char* value) const {
#ifdef _WIN32
        _putenv_s(name.c_str(), value ? value : "");
#else
        if (value) setenv(name.c_str(), value, 1);
        else unsetenv(name.c_str());
#endif
    }
};

const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "name": "Camera", "components": { "Camera": {} } },
    { "id": "ball", "name": "Ball",
      "components": { "Transform": { "position": [0, 60, 0] },
                      "Shape2D": { "shape": "circle", "size": [20, 20] },
                      "RigidBody2D": {},
                      "Collider2D": { "shape": "circle", "radius": 10 } } },
    { "id": "ground", "name": "Ground",
      "components": { "Transform": { "position": [0, -70, 0] },
                      "RigidBody2D": { "type": "static" },
                      "Collider2D": { "size": [300, 20] } } }
  ]
})";

std::string project_json(const std::string& runtime) {
    std::string s = R"({
  "format": "factoria.project/1", "name": "Jobs Test", "id": "com.example.jobstest",
  "mainScene": "scenes/main.scene.json", "display": { "width": 320, "height": 180 })";
    if (!runtime.empty()) s += ",\n  \"runtime\": " + runtime;
    return s + "\n}";
}

struct TempProject {
    stdfs::path dir;
    explicit TempProject(const std::string& name, const std::string& runtime = {}) {
        dir = fs::make_temp_dir("fa_jobs_engine_test_" + name).value();
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json", std::ios::binary) << project_json(runtime);
        std::ofstream(dir / "scenes" / "main.scene.json", std::ios::binary) << kScene;
    }
    ~TempProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
};

EngineConfig headless_cfg(const TempProject& p, const std::string& jobThreads = {}) {
    EngineConfig c;
    c.projectDir = p.dir.generic_string();
    c.headless = true;
    c.graphics = false;
    c.hotReload = false;
    c.jobThreads = jobThreads;
    return c;
}

// One game step that uses the job system the way a system should: the main thread draws the seed from world.rng,
// the chunks write only their own entities with their own chunk RNG, the results land in fixed order.
void spread_step(World& world, const std::vector<Entity>& cells) {
    const std::uint64_t seed = world.rng().next_u32();
    std::vector<Vec3> next(cells.size());
    for (std::size_t i = 0; i < cells.size(); ++i) next[i] = world.get<Transform>(cells[i])->position;
    auto r = jobs::parallel_for("test.spread", cells.size(), 16, [&](const jobs::Chunk& c) {
        Rng rng = c.rng();
        for (std::size_t i = c.begin; i < c.end; ++i) {
            Vec3& p = next[i];
            p.x = p.x * 0.99f + rng.range(-1.0f, 1.0f);
            p.y = p.y * 0.98f + rng.range(-0.5f, 0.5f) + float(i % 7) * 0.01f;
        }
    }, seed);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? std::string() : r.error().to_string()));
    // Partial sums per chunk, combined in chunk order: the float result does not depend on who ran which chunk.
    auto sum = jobs::parallel_reduce<float>(
        "test.sum", cells.size(), 16, 0.0f,
        [&](const jobs::Chunk& c) {
            float s = 0;
            for (std::size_t i = c.begin; i < c.end; ++i) s += next[i].x * 0.001f;
            return s;
        },
        [](float a, float b) { return a + b; });
    REQUIRE(sum.ok());
    for (std::size_t i = 0; i < cells.size(); ++i) {
        Transform* t = world.get<Transform>(cells[i]);
        t->position = next[i];
        t->rotation.z = sum.value();
    }
}

std::vector<std::string> run_hashes(const TempProject& p, const std::string& jobThreads, int expectWorkers) {
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(headless_cfg(p, jobThreads), nullptr, &err), err);
    if (expectWorkers >= 0) CHECK(jobs::worker_count() == expectWorkers);
    CHECK(jobs::inline_mode() == (jobThreads == "inline"));
    std::vector<Entity> cells;
    for (int i = 0; i < 300; ++i) {
        Entity c = e.world().create("cell", "cell" + std::to_string(i));
        e.world().add<Transform>(c).position = Vec3{float(i), float(i % 13), 0};
        cells.push_back(c);
    }
    std::vector<std::string> hashes;
    for (int frame = 0; frame < 40; ++frame) {
        spread_step(e.world(), cells);
        e.step(1);
        auto r = e.commands().call("game.state_hash", Json::object());
        REQUIRE(r.ok);
        hashes.push_back(r.result["hash"].get<std::string>());
    }
    e.shutdown();
    CHECK_FALSE(jobs::running());
    return hashes;
}

// A scene like a physics-heavy example: a 2D basin (Box2D) of 300 bodies and a 3D yard of 150, hinged pairs in both, a trigger, and
// a static floor. Both are above the sizes at which a step goes to the job pool (docs/ARCHITECTURE.md, "Physics on jobs").
void build_physics_scene(World& w) {
    auto wall2 = [&](const char* id, Vec3 pos, Vec2 size) {
        Entity e = w.create(id, id);
        w.add<Transform>(e).position = pos;
        w.add<Collider2D>(e).size = size;
        w.add<RigidBody2D>(e).type = BodyType::Static;
    };
    wall2("floor2", {0, -20, 0}, {900, 40});
    wall2("wallL2", {-450, 300, 0}, {40, 700});
    wall2("wallR2", {450, 300, 0}, {40, 700});
    for (int i = 0; i < 300; ++i) {
        Entity e = w.create("b2_" + std::to_string(i), "b2_" + std::to_string(i));
        w.add<Transform>(e).position = {-360.0f + 29.0f * float(i % 25) + (i / 25 % 2 ? 6.0f : 0.0f), 80.0f + 27.0f * float(i / 25), 0};
        Collider2D& c = w.add<Collider2D>(e);
        if (i % 2) { c.shape = ColliderShape::Circle; c.radius = 11.0f; }
        else c.size = {22, 18};
        w.add<RigidBody2D>(e);
    }
    for (int i = 0; i < 20; i += 2) {
        Joint2D& j = w.add<Joint2D>(w.find("b2_" + std::to_string(i)));
        j.connected = w.find("b2_" + std::to_string(i + 1));
        j.anchor = {14, 0};
        j.connectedAnchor = {-14, 0};
    }
    auto wall3 = [&](const char* id, Vec3 pos, Vec3 size) {
        Entity e = w.create(id, id);
        w.add<Transform>(e).position = pos;
        w.add<Collider3D>(e).size = size;
        w.add<RigidBody3D>(e).type = BodyType::Static;
    };
    wall3("floor3", {0, -0.5f, 2000}, {60, 1, 60});
    wall3("wallN3", {0, 3, 1970}, {60, 6, 1});
    wall3("wallS3", {0, 3, 2030}, {60, 6, 1});
    wall3("wallE3", {30, 3, 2000}, {1, 6, 60});
    wall3("wallW3", {-30, 3, 2000}, {1, 6, 60});
    for (int i = 0; i < 150; ++i) {
        Entity e = w.create("b3_" + std::to_string(i), "b3_" + std::to_string(i));
        Transform& t = w.add<Transform>(e);
        t.position = {-14.0f + 2.4f * float(i % 12), 1.0f + 1.3f * float(i / 48 * 3 + i / 12 % 3), 1986.0f + 2.4f * float(i / 12 % 12)};
        t.rotation = {float((i * 29) % 90), float((i * 53) % 90), float((i * 11) % 90)};
        Collider3D& c = w.add<Collider3D>(e);
        if (i % 3 == 0) { c.shape = ColliderShape3D::Sphere; c.radius = 0.5f; }
        else c.size = {0.9f, 0.7f, 0.8f};
        w.add<RigidBody3D>(e).angularVelocity = {float(i % 5) * 20.0f, 10.0f, -float(i % 4) * 15.0f};
    }
}

struct PhysicsRun {
    std::vector<std::string> hashes;  // game.state_hash every 10th frame
    int queued = 0;                   // jobs queued over the whole run
};

PhysicsRun run_physics(const TempProject& p, const std::string& jobThreads, int frames) {
    const ScopedPhysicsJobThresholds lowered({256, 512});  // the 300-body basin runs through the pool
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(headless_cfg(p, jobThreads), nullptr, &err), err);
    build_physics_scene(e.world());
    PhysicsRun run;
    for (int frame = 0; frame < frames; ++frame) {
        e.step(1);
        if (frame % 10 == 9) {
            auto r = e.commands().call("game.state_hash", Json::object());
            REQUIRE(r.ok);
            run.hashes.push_back(r.result["hash"].get<std::string>());
        }
        run.queued += jobs::info().submittedLastFrame;  // (the engine closes the job frame at the end of each step)
    }
    e.shutdown();
    return run;
}

}  // namespace

TEST_CASE("jobs engine: the same game gives the same state hash with 0, 1, N threads and inline") {
    ScopedEnv env("FA_JOB_THREADS", nullptr);
    TempProject p("determinism");
    const std::vector<std::string> base = run_hashes(p, "0", 0);
    REQUIRE(base.size() == 40);
    CHECK(base.front() != base.back());  // the state does change from frame to frame
    const int n1 = jobs::threads_supported() ? 1 : 0;
    const int n3 = jobs::threads_supported() ? 3 : 0;
    const int n7 = jobs::threads_supported() ? 7 : 0;
    CHECK(run_hashes(p, "1", n1) == base);
    CHECK(run_hashes(p, "3", n3) == base);
    CHECK(run_hashes(p, "7", n7) == base);
    CHECK(run_hashes(p, "inline", 0) == base);
    CHECK(run_hashes(p, "auto", -1) == base);
}

TEST_CASE("jobs engine: game.state_hash sees a one-bit change and lists entities") {
    ScopedEnv env("FA_JOB_THREADS", nullptr);
    TempProject p("hash");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(headless_cfg(p), nullptr, &err), err);
    e.step(3);
    auto a = e.commands().call("game.state_hash", Json::parse(R"({"perEntity":true})"));
    REQUIRE(a.ok);
    CHECK(a.result["hash"].get<std::string>().size() == 16);
    CHECK(a.result["entities"].get<int>() == 3);
    CHECK(a.result["perEntity"].size() == 3);
    CHECK(a.result["perEntity"][0]["entity"] == "cam");
    CHECK(a.result["truncated"] == false);
    CHECK(a.result["frame"].get<int>() >= 3);
    // The same state twice: the same hash.
    auto again = e.commands().call("game.state_hash", Json::object());
    REQUIRE(again.ok);
    CHECK(again.result["hash"] == a.result["hash"]);
    // One float off in its last bit changes the hash, and only that entity's hash.
    World& w = e.world();
    Entity ball = w.find_by_id("ball");
    REQUIRE(ball);
    Transform* t = w.get<Transform>(ball);
    t->position.x = std::nextafter(t->position.x, 1e9f);
    auto b = e.commands().call("game.state_hash", Json::parse(R"({"perEntity":true,"maxEntities":2})"));
    REQUIRE(b.ok);
    CHECK(b.result["hash"] != a.result["hash"]);
    CHECK(b.result["perEntity"].size() == 2);
    CHECK(b.result["truncated"] == true);
    CHECK(b.result["perEntity"][0]["hash"] == a.result["perEntity"][0]["hash"]);
    CHECK(b.result["perEntity"][1]["hash"] != a.result["perEntity"][1]["hash"]);
    // A random number drawn changes it too (the generator state is part of the hash).
    const std::string before = state_hash_hex(world_state_hash(w).hash);
    w.rng().next_u32();
    CHECK(state_hash_hex(world_state_hash(w).hash) != before);
    e.shutdown();
}

TEST_CASE("jobs engine: the state hash does not depend on the order components come in") {
    ensure_builtin_components();
    const TypeInfo* transform = TypeRegistry::global().of<Transform>();
    const TypeInfo* shape = TypeRegistry::global().of<Shape2D>();
    REQUIRE(transform);
    REQUIRE(shape);
    Transform t;
    t.position = Vec3{1, 2, 3};
    Shape2D s;
    const Entity e = Entity::from_bits(0x100000002ULL);
    const auto ab = entity_state_hash(e, "a", "", {{transform, &t}, {shape, &s}});
    const auto ba = entity_state_hash(e, "a", "", {{shape, &s}, {transform, &t}});
    CHECK(ab == ba);  // registration order (who registered a component first) does not change the hash
    t.position.x = 1.5f;
    CHECK(entity_state_hash(e, "a", "", {{shape, &s}, {transform, &t}}) != ab);
}

TEST_CASE("jobs engine: where the thread count comes from") {
    ScopedEnv env("FA_JOB_THREADS", nullptr);
    const int two = jobs::threads_supported() ? 2 : 0;
    SUBCASE("default is auto") {
        TempProject p("default");
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(headless_cfg(p), nullptr, &err), err);
        auto r = e.commands().call("jobs.info", Json::object());
        REQUIRE(r.ok);
        CHECK(r.result["source"] == "default");
        CHECK(r.result["setting"] == "auto");
        CHECK(r.result["running"] == true);
        CHECK(r.result["mode"] == "threads");
        CHECK(r.result["workers"].get<int>() == r.result["autoWorkers"].get<int>());
        CHECK(r.result["lanes"].size() == std::size_t(1 + r.result["workers"].get<int>()));
        CHECK(r.result["lanes"][0]["name"] == "main");
        e.shutdown();
        CHECK_FALSE(jobs::running());
    }
    SUBCASE("factoria.json runtime.jobThreads") {
        TempProject p("project", R"({ "jobThreads": 2 })");
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(headless_cfg(p), nullptr, &err), err);
        CHECK(jobs::worker_count() == two);
        auto r = e.commands().call("jobs.info", Json::object());
        REQUIRE(r.ok);
        CHECK(r.result["source"] == "factoria.json");
        CHECK(r.result["setting"] == 2);
        e.shutdown();
    }
    SUBCASE("FA_JOB_THREADS beats the project, EngineConfig beats both") {
        TempProject p("env", R"({ "jobThreads": 2 })");
        ScopedEnv inl("FA_JOB_THREADS", "inline");
        {
            Engine e;
            std::string err;
            REQUIRE_MESSAGE(e.init(headless_cfg(p), nullptr, &err), err);
            CHECK(jobs::inline_mode());
            auto r = e.commands().call("jobs.info", Json::object());
            REQUIRE(r.ok);
            CHECK(r.result["source"] == "FA_JOB_THREADS");
            CHECK(r.result["mode"] == "inline");
            e.shutdown();
        }
        {
            Engine e;
            std::string err;
            REQUIRE_MESSAGE(e.init(headless_cfg(p, "1"), nullptr, &err), err);
            CHECK_FALSE(jobs::inline_mode());
            CHECK(jobs::worker_count() == (jobs::threads_supported() ? 1 : 0));
            e.shutdown();
        }
    }
    SUBCASE("a bad FA_JOB_THREADS is reported and the project setting is used") {
        TempProject p("badenv", R"({ "jobThreads": 2 })");
        ScopedEnv bad("FA_JOB_THREADS", "lots");
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(headless_cfg(p), nullptr, &err), err);
        CHECK(jobs::worker_count() == two);
        e.shutdown();
    }
    SUBCASE("a bad project value fails init with its JSON pointer") {
        TempProject p("badproject", R"({ "jobThreads": "inlin" })");
        Engine e;
        std::string err;
        CHECK_FALSE(e.init(headless_cfg(p), nullptr, &err));
        CHECK(err.find("/runtime/jobThreads") != std::string::npos);
        CHECK(err.find("inline") != std::string::npos);  // did you mean
        CHECK_FALSE(jobs::running());
    }
    SUBCASE("a count written as a string fails init: the schema says it is a number") {
        TempProject p("stringcount", R"({ "jobThreads": "4" })");
        Engine e;
        std::string err;
        CHECK_FALSE(e.init(headless_cfg(p), nullptr, &err));
        CHECK(err.find("/runtime/jobThreads") != std::string::npos);
        CHECK(err.find("without quotes") != std::string::npos);
        CHECK_FALSE(jobs::running());
    }
    SUBCASE("a number out of range fails init") {
        TempProject p("badcount", R"({ "jobThreads": 99 })");
        Engine e;
        std::string err;
        CHECK_FALSE(e.init(headless_cfg(p), nullptr, &err));
        CHECK(err.find("/runtime/jobThreads") != std::string::npos);
        CHECK(err.find("32") != std::string::npos);
        CHECK_FALSE(jobs::running());
    }
    SUBCASE("a bad EngineConfig value fails init") {
        TempProject p("badconfig");
        Engine e;
        std::string err;
        CHECK_FALSE(e.init(headless_cfg(p, "-1"), nullptr, &err));
        CHECK(err.find("EngineConfig.jobThreads") != std::string::npos);
        CHECK(err.find("out of range") != std::string::npos);
        CHECK_FALSE(jobs::running());
    }
    SUBCASE("runtime must be an object") {
        TempProject p("badruntime", "3");
        Engine e;
        std::string err;
        CHECK_FALSE(e.init(headless_cfg(p), nullptr, &err));
        CHECK(err.find("/runtime") != std::string::npos);
    }
}

TEST_CASE("jobs engine: two engines share one pool; the first one's setting holds") {
    ScopedEnv env("FA_JOB_THREADS", nullptr);
    TempProject p("shared");
    Engine a;
    Engine b;
    std::string err;
    REQUIRE_MESSAGE(a.init(headless_cfg(p, "2"), nullptr, &err), err);
    REQUIRE_MESSAGE(b.init(headless_cfg(p, "5"), nullptr, &err), err);
    CHECK(jobs::worker_count() == (jobs::threads_supported() ? 2 : 0));
    a.shutdown();
    CHECK(jobs::running());  // b still holds it
    b.step(2);
    b.shutdown();
    CHECK_FALSE(jobs::running());
}

TEST_CASE("jobs engine: a second init fails and leaves the pool running") {
    ScopedEnv env("FA_JOB_THREADS", nullptr);
    TempProject p("twice");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(headless_cfg(p, "1"), nullptr, &err), err);
    CHECK_FALSE(e.init(headless_cfg(p, "1"), nullptr, &err));
    CHECK(err.find("called twice") != std::string::npos);
    CHECK(jobs::running());  // the first init's reference still holds it
    e.step(2);
    e.shutdown();
    CHECK_FALSE(jobs::running());
}

TEST_CASE("jobs engine: each engine owns its jobs; shutdown waits for them, a frame runs only its own tasks") {
    ScopedEnv env("FA_JOB_THREADS", nullptr);
    for (const char* threads : {"0", "2"}) {
        CAPTURE(threads);
        TempProject p(std::string("owners") + threads);
        Engine a;
        Engine b;
        std::string err;
        REQUIRE_MESSAGE(a.init(headless_cfg(p, threads), nullptr, &err), err);
        REQUIRE_MESSAGE(b.init(headless_cfg(p, threads), nullptr, &err), err);
        std::atomic<int> aTasks{0};
        std::atomic<bool> slowDone{false};
        std::atomic<bool> ownedByEngine{false};  // doctest checks are not thread-safe: the job records, the test checks
        jobs::Handle posted;
        // A command's handler runs with the engine as the current owner: the job and the task it posts are a's.
        a.commands().add({"test.post", "Queue a job that posts a main-thread task.", "Test only.", Json::object(), false,
                          "test"},
                         [&](const Json&) {
                             posted = jobs::submit("test.post", [&] {
                                 ownedByEngine.store(jobs::current_owner_name() == "engine");
                                 jobs::post_main("test.task", [&] { aTasks.fetch_add(1); });
                             });
                             return Json::object();
                         });
        a.commands().add({"test.slow", "Queue a job that takes a while.", "Test only.", Json::object(), false, "test"},
                         [&](const Json&) {
                             jobs::submit("test.slow", [&] {
                                 std::this_thread::sleep_for(std::chrono::milliseconds(30));
                                 slowDone.store(true);
                             });
                             return Json::object();
                         });
        REQUIRE(a.commands().call("test.post", Json::object()).ok);
        REQUIRE(jobs::wait(posted).ok());  // the task is queued for a now
        CHECK(ownedByEngine.load());
        b.step(2);
        CHECK(aTasks.load() == 0);  // b's frames never run a's tasks
        a.step(1);
        CHECK(aTasks.load() == 1);
        auto info = a.commands().call("jobs.info", Json::object());
        REQUIRE(info.ok);
        CHECK(info.result["enginePending"] == 0);
        REQUIRE(a.commands().call("test.slow", Json::object()).ok);
        a.shutdown();
        CHECK(slowDone.load());  // a's shutdown waited for a's job
        CHECK(jobs::running());  // b still holds the pool
        b.step(1);
        b.shutdown();
        CHECK_FALSE(jobs::running());
    }
}

TEST_CASE("jobs engine: runtime.jobThreads round-trips through the project file") {
    TempProject p("roundtrip", R"({ "jobThreads": "inline" })");
    auto loaded = load_project(p.dir.generic_string());
    REQUIRE_MESSAGE(loaded.ok(), (loaded.ok() ? std::string() : loaded.error().to_string()));
    CHECK(loaded->jobThreadsSet);
    CHECK(loaded->jobThreads == jobs::Settings::inline_jobs());
    Json j = loaded->to_json();
    CHECK(j["runtime"]["jobThreads"] == "inline");
    ProjectSettings unset;
    Json none = unset.to_json();
    CHECK_FALSE(none.contains("runtime"));
}

TEST_CASE("jobs engine: a physics-heavy scene gives the same state hash for hundreds of frames, inline and on 1, 3 and 8 threads") {
    ScopedEnv env("FA_JOB_THREADS", nullptr);
    TempProject p("physics");
    const PhysicsRun base = run_physics(p, "inline", 200);
    REQUIRE(base.hashes.size() == 20);
    CHECK(base.hashes.front() != base.hashes.back());  // it moves
    CHECK(base.queued == 0);                            // inline mode queues nothing
    if (!jobs::threads_supported()) return;
    for (const char* threads : {"1", "3", "8"}) {
        const PhysicsRun run = run_physics(p, threads, 200);
        CHECK(run.hashes == base.hashes);
        CHECK(run.queued > 200);  // the physics steps really went to the pool
    }
}
