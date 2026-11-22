// M75-P4a: the floating origin in a running engine (docs/BIG_WORLDS.md "Floating origin"): the automatic rebase after a fixed tick, the
// `originShifted` event (once per rebase), the commands world.origin / world.rebase / world.absolute_position, tweens that follow, and
// that two identical runs rebase identically.
#include <doctest.h>

#include <cmath>
#include <filesystem>
#include <string>
#include <utility>

#include "fa/core/fs.h"
#include "fa/core/json.h"
#include "fa/runtime/engine.h"
#include "fa/scene/serialize.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

constexpr double kFixedDt = 1.0 / 60.0;

// A project whose camera is the anchor. `counter` is a Panel (a screen-space root: a rebase never moves it) whose script writes what it
// heard into its position: x = how many originShifted events, y = the last offset.x, z = the last origin.x. `mover` has a tween.
struct OriginProject {
    stdfs::path dir = fs::make_temp_dir("fa_floating_origin").value();
    explicit OriginProject(bool enabled) {
        write("factoria.json", std::string(R"({"format":"factoria.project/1","name":"Origin","id":"com.example.origin",
                "mainScene":"main.scene.json","display":{"width":64,"height":64},"physics":{"fixedHz":60},
                "world":{"floatingOrigin":{"enabled":)") +
                                   (enabled ? "true" : "false") + R"(,"threshold":128,"step":64}}})");
        write("counter.js", "import { Behaviour, game } from 'factoria';\n"
                            "export default class C extends Behaviour {\n"
                            "  onStart() {\n"
                            "    game.on('originShifted', (s) => {\n"
                            "      const p = this.entity.position;\n"
                            "      p.x += 1; p.y = s.offset[0]; p.z = s.origin[0];\n"
                            "    });\n"
                            "  }\n"
                            "}\n");
        write("mover.js", "import { Behaviour } from 'factoria';\n"
                          "export default class M extends Behaviour {\n"
                          "  onStart() { this.tween(this.entity.position, { x: 1000 }, { duration: 100 }); }\n"
                          "}\n");
        write("main.scene.json",
              R"({"format":"factoria.scene/1","entities":[
                {"id":"cam","components":{"Transform":{},"Camera":{}}},
                {"id":"counter","components":{"Transform":{},"Panel":{},"Script":{"path":"counter.js"}}},
                {"id":"mover","components":{"Transform":{},"Script":{"path":"mover.js"}}}]})");
    }
    ~OriginProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    void write(const char* rel, const std::string& text) const {
        stdfs::create_directories((dir / rel).parent_path());
        REQUIRE(fs::write_text((dir / rel).generic_string(), text).ok());
    }
    EngineConfig config() const {
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.hotReload = false;
        c.memoryStorage = true;
        return c;
    }
};

struct Session {
    OriginProject project;
    Engine e;
    explicit Session(bool enabled = true) : project(enabled) {
        std::string err;
        REQUIRE_MESSAGE(e.init(project.config(), nullptr, &err), err);
        frame(1);  // onStart
    }
    ~Session() { e.shutdown(); }
    void frame(int steps) {
        for (int i = 0; i < steps; ++i) e.frame(kFixedDt + kFixedDt * 1e-3);
    }
    Vec3 pos(const char* id) {
        const Entity ent = e.world().find(id);
        REQUIRE_MESSAGE(!ent.is_null(), "no entity " << id);
        return e.world().get<Transform>(ent)->position;
    }
    void move_camera_to(float x) { e.world().get<Transform>(e.world().find("cam"))->position.x = x; }
    CommandResult call(const char* name, const char* args) { return e.commands().call(name, Json::parse(args)); }
};

}  // namespace

TEST_CASE("floating origin engine: the camera past the threshold rebases once, the script hears one originShifted") {
    Session s;
    CHECK(s.e.world().origin() == DVec3{});
    s.frame(5);
    CHECK(s.pos("counter").x == 0.0f);  // inside the threshold: nothing happens
    s.move_camera_to(300.0f);           // threshold 128, step 64: 300 rounds to 320 (5 steps)
    s.frame(1);
    CHECK(s.e.world().origin() == DVec3{320, 0, 0});
    CHECK(s.pos("cam").x == doctest::Approx(-20.0f));
    CHECK(s.e.world().absolute_position(s.e.world().find("cam")).x == doctest::Approx(300.0));
    const Vec3 heard = s.pos("counter");  // a screen-space root: not shifted, and it counted
    CHECK(heard.x == 1.0f);
    CHECK(heard.y == 320.0f);
    CHECK(heard.z == 320.0f);
    s.frame(30);
    CHECK(s.pos("counter").x == 1.0f);  // still near the origin: no second rebase, no second event
    CHECK(s.e.world().rebase_count() == 1);
    s.move_camera_to(200.0f);  // 200 from the local origin: another rebase, by 192
    s.frame(1);
    CHECK(s.e.world().origin() == DVec3{512, 0, 0});
    CHECK(s.pos("counter").x == 2.0f);
    CHECK(s.pos("counter").y == 192.0f);
    CHECK(s.pos("counter").z == 512.0f);
}

TEST_CASE("floating origin engine: off, nothing rebases however far the camera goes") {
    Session s(false);
    s.move_camera_to(100000.0f);
    s.frame(10);
    CHECK(s.e.world().origin() == DVec3{});
    CHECK(s.e.world().rebase_count() == 0);
    CHECK(s.pos("cam").x == 100000.0f);
    CHECK(s.pos("counter").x == 0.0f);
}

TEST_CASE("floating origin engine: a running tween of a root's position keeps its way across a rebase") {
    Session s;
    s.frame(59);  // about one second of a 100 s tween over 1000 m: about 10 m
    const float before = s.pos("mover").x;
    REQUIRE(before > 5.0f);
    REQUIRE(before < 15.0f);
    s.move_camera_to(300.0f);
    s.frame(1);
    REQUIRE(s.e.world().origin().x == 320.0);
    // Absolute position keeps climbing from where it was: the tween was shifted with the entity, not restarted.
    const double abs = s.e.world().absolute_position(s.e.world().find("mover")).x;
    CHECK(abs == doctest::Approx(double(before) + 10.0 / 60.0).epsilon(0.05));
    s.frame(60);
    const double later = s.e.world().absolute_position(s.e.world().find("mover")).x;
    CHECK(later > abs + 9.0);
    CHECK(later < abs + 11.0);
}

TEST_CASE("floating origin engine: world.origin, world.rebase and world.absolute_position") {
    Session s;
    auto o = s.call("world.origin", "{}");
    REQUIRE(o.ok);
    CHECK(o.result["enabled"].get<bool>());
    CHECK(o.result["origin"] == Json::parse("[0,0,0]"));
    CHECK(o.result["rebases"] == 0);
    CHECK(o.result["threshold"] == 128.0);
    CHECK(o.result["step"] == 64.0);
    CHECK(o.result["anchor"] == "camera");

    s.move_camera_to(10.0f);
    auto rebase = s.call("world.rebase", R"({"offset":[1000,0,0]})");  // 1000 is 15.6 steps: it rounds to 16 (1024)
    REQUIRE_MESSAGE(rebase.ok, rebase.error.dump());
    CHECK(rebase.result["origin"] == Json::parse("[1024.0,0.0,0.0]"));
    CHECK(rebase.result["shift"] == Json::parse("[1024.0,0.0,0.0]"));
    CHECK(rebase.result["rebases"] == 1);
    CHECK(rebase.result["shifted"].get<int>() >= 2);  // the camera and the mover (the Panel stays)
    // The camera (the anchor) is now 1014 m from the local origin: the next fixed step rebases it back, and the script hears both.
    auto abs = s.call("world.absolute_position", R"({"entity":"cam"})");
    REQUIRE(abs.ok);
    CHECK(abs.result["entity"] == "cam");
    CHECK(abs.result["position"][0].get<double>() == doctest::Approx(10.0));
    CHECK(abs.result["origin"][0].get<double>() == 1024.0);
    CHECK(abs.result["local"][0].get<double>() == doctest::Approx(10.0 - 1024.0));
    s.frame(1);
    CHECK(s.e.world().origin() == DVec3{});
    CHECK(s.pos("counter").x == 2.0f);  // the command's rebase and the automatic one back, each heard once

    auto centred = s.call("world.rebase", R"({"entity":"cam"})");
    REQUIRE(centred.ok);
    CHECK(centred.result["origin"][0].get<double>() ==
          0.0);  // the camera is at 10 (absolute): the nearest multiple of 64 is 0
    CHECK(centred.result["shift"][0].get<double>() == 0.0);  // already centred: nothing moved

    auto both = s.call("world.rebase", R"({"offset":[0,0,0],"entity":"cam"})");
    REQUIRE_FALSE(both.ok);
    CHECK(both.error.dump().find("/offset") != std::string::npos);
    auto bad = s.call("world.rebase", R"({"offset":[1,2]})");
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error.dump().find("/offset") != std::string::npos);
    auto huge = s.call("world.rebase", R"({"offset":[1e15,0,0]})");
    REQUIRE_FALSE(huge.ok);
    CHECK(huge.error.dump().find("precision") != std::string::npos);
    auto missing = s.call("world.absolute_position", R"({"entity":"nobody"})");
    REQUIRE_FALSE(missing.ok);
}

TEST_CASE("floating origin engine: world.rebase fails with a hint when the project does not enable it") {
    Session s(false);
    auto r = s.call("world.rebase", R"({"offset":[64,0,0]})");
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "not_enabled");
    CHECK(r.error.dump().find("floatingOrigin") != std::string::npos);
    CHECK(s.e.world().origin() == DVec3{});
    auto o = s.call("world.origin", "{}");
    REQUIRE(o.ok);
    CHECK_FALSE(o.result["enabled"].get<bool>());
    CHECK(o.result["origin"] == Json::parse("[0,0,0]"));
}

TEST_CASE("floating origin engine: two identical runs rebase identically") {
    auto run = []() {
        Session s;
        for (int i = 0; i < 4; ++i) {
            s.move_camera_to(s.pos("cam").x + 400.0f);
            s.frame(7);
        }
        return std::make_pair(s.e.world().origin(), s.pos("cam"));
    };
    const auto a = run();
    const auto b = run();
    CHECK(a.first == b.first);
    CHECK(a.second == b.second);
    CHECK(a.first.x > 0.0);
    CHECK(std::fmod(a.first.x, 64.0) == 0.0);
}

TEST_CASE("floating origin engine: the running scene saves its origin and loads it back") {
    Session s;
    s.move_camera_to(300.0f);
    s.frame(1);
    const Json saved = save_scene(s.e.world());
    REQUIRE(saved.contains("origin"));
    CHECK(saved["origin"][0].get<double>() == 320.0);
    World w;
    REQUIRE(load_scene(w, saved, "saved.scene.json").ok());
    CHECK(w.origin() == DVec3{320, 0, 0});
    CHECK(w.absolute_position(w.find("cam")).x == doctest::Approx(300.0));
}
