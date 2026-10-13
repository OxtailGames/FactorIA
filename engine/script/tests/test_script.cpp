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

namespace {
void copy_template(TestHost& h, const char* name) {
    namespace sfs = std::filesystem;
    sfs::path src = sfs::path(FA_REPO_ROOT) / "templates" / name;
    for (auto& e : sfs::recursive_directory_iterator(src)) {
        if (!e.is_regular_file()) continue;
        auto rel = sfs::relative(e.path(), src);
        if (rel == "template.json" || rel == "README.md") continue;
        sfs::create_directories((h.root / rel).parent_path());
        sfs::copy_file(e.path(), h.root / rel, sfs::copy_options::overwrite_existing);
    }
    auto pj = load_json_file((h.root / "factoria.json").string());
    REQUIRE(pj.ok());
    h.proj = *pj;
    h.in.set_actions(h.proj["input"]["actions"]);
    if (name == std::string("3d-empty")) {
        // 3D template declares its own actions
    }
}
}  // namespace

TEST_CASE("templates: scripts, tools and tests run against the host") {
    for (const char* name : {"2d-empty", "2d-platformer", "3d-empty"}) {
        CAPTURE(name);
        TestHost h(std::string("tpl_") + name);
        copy_template(h, name);
        REQUIRE(h.start());
        CHECK(h.scripts.errors().empty());
        std::vector<std::string> files = fs::list("tests", true, ".js");
        REQUIRE(!files.empty());
        TestReport rep = h.scripts.run_tests(files);
        MESSAGE(rep.summary());
        CHECK(rep.ok());
        for (const auto& e : h.scripts.errors()) MESSAGE(e.to_string());
        CHECK(h.scripts.errors().empty());
        CHECK(h.cmds.has("project.spawn_" + std::string(name == std::string("2d-empty") ? "box" : name == std::string("3d-empty") ? "cube" : "coin")));
    }
}

TEST_CASE("events, timers, collisions, input, raycast") {
    TestHost h("events");
    h.file("scripts/b.js", R"(
import { Behaviour, world, input, physics, vec2 } from "factoria";
globalThis.L = [];
export default class B extends Behaviour {
  onStart() {
    this.unsub = world.on("ping", (d, s) => L.push("on:" + d.n));
    this.after(0.05, () => L.push("after"));
    this.t = this.every(0.1, () => L.push("every"));
  }
  onEvent(name, data) { L.push("ev:" + name + data.n); }
  onCollisionEnter(o, info) { L.push("hit:" + o.id + ":" + (info.normal.y !== 0)); }
  onTriggerEnter(o) { L.push("trig:" + o.id); }
  onUpdate(dt) { if (input.pressed("jump")) L.push("jump"); }
  onDestroy() { L.push("bye"); }
}
)");
    Json ents = Json::array();
    ents.push_back(Json::parse(R"({"id":"ground","components":{"Transform":{"position":[0,-100,0]},"Collider2D":{"size":[1000,20]}}})"));
    ents.push_back(Json::parse(R"({"id":"ball","components":{"Transform":{"position":[0,0,0]},"RigidBody2D":{},"Collider2D":{"size":[20,20]},"Script":{"path":"scripts/b.js"}}})"));
    ents.push_back(Json::parse(R"({"id":"zone","components":{"Transform":{"position":[0,-60,0]},"Collider2D":{"size":[100,10],"isTrigger":true}}})"));
    h.file("scenes/main.scene.json", scene_with(ents).dump());
    REQUIRE(h.start());
    REQUIRE(h.load_scene_now("scenes/main.scene.json").empty());
    h.step_frames(1);
    h.scripts.eval("world.emit('ping', {n: 7})");
    h.in.set_action_override("jump", true);
    h.step_frames(40);
    h.in.set_action_override("jump", false);
    h.step_frames(10);
    std::string log = h.scripts.eval("L.join(',')")->get<std::string>();
    CAPTURE(log);
    CHECK(log.find("on:7") != std::string::npos);
    CHECK(log.find("ev:ping7") != std::string::npos);
    CHECK(log.find("after") != std::string::npos);
    CHECK(log.find("every") != std::string::npos);
    CHECK(log.find("hit:ground:true") != std::string::npos);
    CHECK(log.find("trig:zone") != std::string::npos);
    CHECK(log.find("jump") != std::string::npos);
    auto hit = h.scripts.eval("const r = physics.raycast(vec2(0, 200), vec2(0, -300)); r ? r.entity.id : null");
    REQUIRE(hit.ok());
    CHECK(hit->get<std::string>() == "ball");
    h.w.destroy(h.w.find("ball"));
    h.w.flush();
    CHECK(h.scripts.eval("L.slice(-1)[0]")->get<std::string>() == "bye");
}

TEST_CASE("errors are recorded once, runaway scripts are stopped") {
    TestHost h("errs");
    h.file("scripts/e.js", "import { Behaviour } from 'factoria';\nexport default class E extends Behaviour {\n  onUpdate() { this.nothing.x = 1; }\n}\n");
    h.file("scripts/loop.js", "import { Behaviour } from 'factoria';\nexport default class L extends Behaviour {\n  onUpdate() { while (true) {} }\n}\n");
    Json ents = Json::array();
    ents.push_back(Json::parse(R"({"id":"a","components":{"Script":{"path":"scripts/e.js"}}})"));
    ents.push_back(Json::parse(R"({"id":"b","components":{"Script":{"path":"scripts/loop.js"}}})"));
    h.file("scenes/main.scene.json", scene_with(ents).dump());
    REQUIRE(h.start());
    h.load_scene_now("scenes/main.scene.json");
    h.step_frames(3);
    int tooLong = 0, typeErr = 0;
    for (auto& e : h.scripts.errors()) {
        if (e.message.find("took too long") != std::string::npos) { ++tooLong; CHECK(e.file == "scripts/loop.js"); }
        if (e.message.find("TypeError") != std::string::npos) { ++typeErr; CHECK(e.file == "scripts/e.js"); CHECK(e.line == 3); CHECK(e.entityId == "a"); }
    }
    CHECK(tooLong == 1);
    CHECK(typeErr == 1);
}

TEST_CASE("JS tools, hot reload, rng determinism, eval, runner failures") {
    TestHost h("tools");
    h.cmds.add({"project.test", "builtin", "", Json::object({{"type", "object"}, {"properties", Json::object()}}), true, "project"},
               [](const Json&) { return Json::object(); });
    h.file("tools/hello.js", "export default { name: 'hello', summary: 's', input: {type:'object', properties:{n:{type:'integer', default: 2}}}, run({n}) { return { twice: n * 2 }; } };");
    h.file("tools/test.js", "export default { name: 'test', summary: 's', run() { return 1; } };");
    h.file("scripts/c.js", "import { Behaviour } from 'factoria';\nexport default class C extends Behaviour { v = 1; onStart() { globalThis.V = this.v; } }\n");
    h.file("scenes/main.scene.json", scene_with(Json::array({Json::parse(R"({"id":"c","components":{"Script":{"path":"scripts/c.js"}}})")})).dump());
    h.file("tests/t.test.js", "import { test, expect } from 'factoria:test';\ntest('ok', () => { expect(1).toBe(1); });\ntest('bad', () => {\n  expect(2).toBe(3);\n});\ntest.skip('s', () => {});\n");
    int notified = 0;
    h.scripts.set_tools_changed_callback([&] { ++notified; });
    REQUIRE(h.start());
    auto r = h.cmds.call("project.hello", Json::object());
    REQUIRE(r.ok);
    CHECK(r.result["twice"] == 4);
    CHECK(h.cmds.info("project.test")->summary == "builtin");  // builtin not replaced
    bool collided = false;
    for (auto& e : h.scripts.errors()) if (e.message.find("collides") != std::string::npos) collided = true;
    CHECK(collided);
    h.file("tools/hello.js", "export default { name: 'hello', summary: 's', run() { return { v: 'new' }; } };");
    h.scripts.reload_module("tools/hello.js");
    CHECK(h.cmds.call("project.hello").result["v"] == "new");
    // behaviour hot reload
    h.load_scene_now("scenes/main.scene.json");
    h.step_frames(1);
    CHECK(h.scripts.eval("V")->get<int>() == 1);
    h.file("scripts/c.js", "import { Behaviour } from 'factoria';\nexport default class C extends Behaviour { v = 5; onStart() { globalThis.V = this.v; } }\n");
    h.scripts.reload_module("scripts/c.js");
    CHECK(h.scripts.eval("V")->get<int>() == 5);
    // runner
    TestReport rep = h.scripts.run_tests({"tests/t.test.js"});
    CHECK(rep.passed == 1);
    CHECK(rep.failed == 1);
    REQUIRE(rep.cases.size() == 2);
    CHECK(rep.cases[1].message.find("expected: 3") != std::string::npos);
    CHECK(rep.cases[1].message.find("tests/t.test.js:4") != std::string::npos);
    // determinism
    auto a = h.scripts.eval("[rng.float(), rng.int(0, 100), Math.random()]");
    h.w.rng().reseed(1);
    h.scripts.eval("rng.float()");  // advance
    h.w.rng().reseed(1);
    auto b = h.scripts.eval("[rng.float(), rng.int(0, 100), Math.random()]");
    h.w.rng().reseed(1);
    auto c = h.scripts.eval("[rng.float(), rng.int(0, 100), Math.random()]");
    CHECK(*b == *c);
    // storage
    h.scripts.eval("storage.set('hs', {a: 1})");
    CHECK(h.scripts.eval("storage.get('hs').a")->get<int>() == 1);
    CHECK(h.scripts.eval("storage.get('zz', 'fb')")->get<std::string>() == "fb");
    CHECK(notified >= 1);
}

TEST_CASE("api manifest and typescript declarations") {
    TestHost h("api");
    REQUIRE(h.start());
    std::string dts = h.scripts.typescript_declarations();
    CHECK(dts.find("declare module \"factoria\"") != std::string::npos);
    CHECK(dts.find("declare module \"factoria:test\"") != std::string::npos);
    CHECK(dts.find("get<K extends keyof Components>(name: K): Components[K] | null;") != std::string::npos);
    CHECK(dts.find("\"kinematic\"") != std::string::npos);
    Json m = h.scripts.api_manifest();
    CHECK(m["modules"].size() == 2);
    CHECK(m["components"].size() > 5);
    if (const char* out = std::getenv("FA_DTS_OUT")) std::ofstream(out) << dts;
}
