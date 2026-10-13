#include <doctest.h>

#include "test_host.h"
#include "fa/core/log.h"

using namespace fa;
using namespace fa::test;

namespace {
Json scene_with(const Json& entities) {
    return Json::object({{"format", "factoria.scene/1"}, {"entities", entities}});
}
}  // namespace

TEST_CASE("behaviour lifecycle order and props") {
    TestHost h("life");
    h.file("scripts/a.js", R"(
import { Behaviour } from "factoria";
export const log = [];
export default class A extends Behaviour {
  speed = 3;
  constructor() { super(); globalThis.__log = globalThis.__log || []; globalThis.__log.push("ctor"); }
  onStart() { globalThis.__log.push("start:" + this.speed); }
  onFixedUpdate(dt) { globalThis.__log.push("fixed"); }
  onUpdate(dt) { globalThis.__log.push("update"); }
  onLateUpdate(dt) { globalThis.__log.push("late"); }
  onDestroy() { globalThis.__log.push("destroy"); }
}
)");
    h.file("scenes/main.scene.json", scene_with(Json::array({Json::object({{"id", "p"}, {"components", Json::object({{"Script", Json::object({{"path", "scripts/a.js"}, {"props", Json::object({{"speed", 9}})}})}})}})})).dump());
    REQUIRE(h.start());
    CHECK(h.load_scene_now("scenes/main.scene.json").empty());
    h.step_frames(2);
    auto r = h.scripts.eval("globalThis.__log.join(',')");
    REQUIRE(r.ok());
    CHECK(r->get<std::string>() == "ctor,start:9,fixed,update,late,fixed,update,late");
    h.w.destroy(h.w.find("p"));
    h.w.flush();
    r = h.scripts.eval("globalThis.__log.slice(-1)[0]");
    CHECK(r->get<std::string>() == "destroy");
    CHECK(h.scripts.errors().empty());
}

TEST_CASE("component views, live vectors, enums, destroyed entities") {
    TestHost h("views");
    REQUIRE(h.start());
    Entity e = h.w.create("Thing", "thing");
    h.w.add<Sprite>(e);
    h.w.add<RigidBody2D>(e);
    auto ev = [&](const char* code) { auto r = h.scripts.eval(code); if (!r.ok()) { FAIL(r.error().to_string()); } return *r; };
    ev("world.find('thing').position.x = 5; world.find('thing').get('Sprite').color.a = 0.5");
    CHECK(h.w.get<Transform>(e)->position.x == 5.0f);
    CHECK(h.w.get<Sprite>(e)->color.a == 0.5f);
    ev("world.find('thing').get('RigidBody2D').type = 'kinematic'");
    CHECK(h.w.get<RigidBody2D>(e)->type == BodyType::Kinematic);
    ev("world.find('thing').get('RigidBody2D').velocity = {x: 3, y: 4}");
    CHECK(h.w.get<RigidBody2D>(e)->velocity.y == 4.0f);
    ev("world.find('thing').position = vec2(10, 20)");
    CHECK(h.w.get<Transform>(e)->position.y == 20.0f);
    CHECK(ev("world.find('thing').get('Sprite').color.a").get<double>() == 0.5);
    CHECK(ev("world.find('thing').get('Collider2D')").is_null());
    CHECK(ev("world.find('thing').get('RigidBody2D').type").get<std::string>() == "kinematic");
    // errors teach
    auto bad = h.scripts.eval("world.find('thing').get('RigidBody2D').type = 'kinematik'");
    CHECK(!bad.ok());
    CHECK(bad.error().message.find("kinematic") != std::string::npos);
    bad = h.scripts.eval("world.find('thing').get('Sprite').colour = 1");
    CHECK(!bad.ok());
    // id goes through set_id
    ev("world.find('thing').id = 'renamed'");
    CHECK(h.w.find_by_id("renamed") == e);
    CHECK(h.w.find_by_id("thing").is_null());
    ev("globalThis.t = world.find('renamed')");
    h.w.destroy_immediate(e);
    bad = h.scripts.eval("t.position.x");
    CHECK(!bad.ok());
    CHECK(bad.error().message.find("'renamed' was destroyed") != std::string::npos);
    CHECK(ev("t.alive").get<bool>() == false);
}

TEST_CASE("check_syntax reports line numbers") {
    TestHost h("syntax");
    h.file("scripts/bad.js", "export default class X {\n  onUpdate( {\n}\n");
    h.file("scripts/good.js", "export const a = 1;\n");
    REQUIRE(h.start());
    auto r = h.scripts.check_syntax("scripts/bad.js");
    REQUIRE(!r.ok());
    CHECK(r.error().message.find("scripts/bad.js:") != std::string::npos);
    CHECK(h.scripts.check_syntax("scripts/good.js").ok());
}
