// Script errors that teach (M100.3): a member that an API object does not have throws with a "did you mean" in development runs
// (and costs nothing in an exported player), an import or a call the player lacks says so only in a player, and a component
// name with the wrong case warns once.
#include <doctest.h>

#include <memory>
#include <mutex>

#include "test_host.h"

using namespace fa;
using namespace fa::test;

namespace {
Json eval_ok(TestHost& h, const char* code) {
    auto r = h.scripts.eval(code);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    return r.value();
}
std::string eval_err(TestHost& h, const char* code) {
    auto r = h.scripts.eval(code);
    REQUIRE_MESSAGE(!r.ok(), code);
    return r.error().to_string();
}
bool has(const std::string& text, const char* part) { return text.find(part) != std::string::npos; }

// The messages of one level that are logged while this lives.
struct Capture {
    struct Lines {
        std::mutex mu;
        std::vector<std::string> lines;
    };
    std::shared_ptr<Lines> lines = std::make_shared<Lines>();
    int id = 0;
    explicit Capture(LogLevel level) {
        id = add_log_sink([l = lines, level](const LogEntry& e) {
            if (e.level != level) return;
            std::lock_guard<std::mutex> lk(l->mu);
            l->lines.push_back(e.message);
        });
    }
    ~Capture() { stop(); }
    Capture(const Capture&) = delete;
    Capture& operator=(const Capture&) = delete;
    void stop() {
        if (id) remove_log_sink(id);
        id = 0;
    }
    std::vector<std::string> take() {
        stop();
        std::lock_guard<std::mutex> lk(lines->mu);
        return lines->lines;
    }
};

void one_entity(TestHost& h) {
    h.file("scenes/main.scene.json",
           R"({"format":"factoria.scene/1","entities":[{"id":"p","components":{"Transform":{"position":[1,2,0]}}}]})");
    REQUIRE(h.start());
    REQUIRE(h.load_scene_now("scenes/main.scene.json").empty());
    h.step_frames(1);
}

const char* kSceneWithScript =
    R"({"format":"factoria.scene/1","entities":[{"id":"p","components":{"Script":{"path":"scripts/calls.js"}}}]})";
}  // namespace

TEST_CASE("a misspelt member of a namespace names the closest one and lists the members") {
    TestHost h("err_namespace");
    one_entity(h);
    const std::string text = eval_err(h, "input.axs('a', 'b')");
    MESSAGE(text);
    CHECK(has(text, "'input' has no 'axs'"));
    CHECK(has(text, "Did you mean 'axis'?"));
    CHECK(has(text, "Its members:"));
    CHECK(has(text, "pressed"));
    CHECK_FALSE(has(text, "older than"));
    // other namespaces get it too, and a member that exists still works
    CHECK(has(eval_err(h, "world.fnid('p')"), "Did you mean 'find'?"));
    CHECK(has(eval_err(h, "audio.playy('x')"), "'audio' has no 'playy'"));
    CHECK(has(eval_err(h, "ui.focusd"), "'ui' has no 'focusd'"));
    CHECK(eval_ok(h, "world.find('p').id") == "p");
}

TEST_CASE("a misspelt member of an entity names the closest one") {
    TestHost h("err_entity");
    one_entity(h);
    const std::string text = eval_err(h, "world.find('p').positon");
    MESSAGE(text);
    CHECK(has(text, "'entity' has no 'positon'"));
    CHECK(has(text, "Did you mean 'position'?"));
    CHECK(has(text, "Its members:"));
    CHECK(has(text, "assign one"));  // says how to keep a field of your own
    CHECK(has(eval_err(h, "world.find('p').setParnt(null)"), "Did you mean 'setParent'?"));
}

TEST_CASE("a misspelt matcher of expect names the closest one") {
    TestHost h("err_expect");
    h.file("tests/t.test.js", R"(
import { test, expect } from "factoria:test";

test("plain and negated matchers still work", () => {
  expect(2).toBe(2);
  expect(2).not.toBe(3);
  expect({ a: 1 }).toEqual({ a: 1 });
});
test("a misspelt matcher throws with a suggestion", () => {
  expect(() => expect(1).toEqul(1)).toThrow("'expect(...)' has no 'toEqul'");
  expect(() => expect(1).toEqul(1)).toThrow("Did you mean 'toEqual'?");
  expect(() => expect(1).not.toBee(1)).toThrow("Did you mean 'toBe'?");
});
)");
    REQUIRE(h.start());
    const TestReport rep = h.scripts.run_tests({"tests/t.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 2);
}

TEST_CASE("then, symbols, toJSON and the members of Object.prototype pass") {
    TestHost h("err_pass");
    one_entity(h);
    CHECK(eval_ok(h, "world.find('p').then === undefined").get<bool>());
    CHECK(eval_ok(h, "input.then === undefined && input.toJSON === undefined").get<bool>());
    CHECK(eval_ok(h, "world.find('p')[Symbol.iterator] === undefined && input[Symbol.toPrimitive] === undefined")
              .get<bool>());
    CHECK(eval_ok(h, "JSON.parse(JSON.stringify(world.find('p'))).id") == "p");
    CHECK(eval_ok(h, "world.find('p').hasOwnProperty('$h') && String(world.find('p')) === 'Entity(p)'").get<bool>());
    CHECK(eval_ok(h, "typeof input.hasOwnProperty === 'function' && input.constructor === Object").get<bool>());
    CHECK(eval_ok(h, "world.find('p') instanceof Entity").get<bool>());
    CHECK(eval_ok(h, "'nothing' in world.find('p') === false && 'axis' in input").get<bool>());
}

TEST_CASE("writes are untouched and an expando that was written reads back") {
    TestHost h("err_write");
    one_entity(h);
    CHECK(eval_ok(h, "const e = world.find('p'); e.hp = 3; e.hp").get<int>() == 3);
    CHECK(eval_ok(h, "world.find('p').hp").get<int>() == 3);  // the same Entity object for the same handle
    CHECK(eval_ok(h, "input.myExtra = 7; input.myExtra").get<int>() == 7);
    CHECK(eval_ok(h, "world.find('p').position = { x: 5, y: 6 }; world.find('p').position.x").get<int>() == 5);
    // an expando that was NOT written is the mistake
    const std::string text = eval_err(h, "world.find('p').score");
    CHECK(has(text, "'entity' has no 'score'"));
    CHECK(has(text, "Its members:"));
    CHECK(has(text, "hp"));  // the field the game wrote is among the members
}

TEST_CASE("a component name with the wrong case works and warns once per name") {
    TestHost h("err_case");
    one_entity(h);
    Capture warnings(LogLevel::Warn);
    CHECK(eval_ok(h, "world.find('p').get('transform') !== null").get<bool>());
    CHECK(eval_ok(h, "world.find('p').has('transform')").get<bool>());
    CHECK(eval_ok(h, "world.find('p').get('transform') !== null").get<bool>());
    CHECK(eval_ok(h, "world.find('p').get('TRANSFORM') !== null").get<bool>());
    CHECK(eval_ok(h, "world.find('p').get('Transform') !== null").get<bool>());  // the exact name never warns
    const std::vector<std::string> msgs = warnings.take();
    std::vector<std::string> mine;
    for (const std::string& m : msgs)
        if (has(m, "the component is called")) mine.push_back(m);
    REQUIRE(mine.size() == 2);  // 'transform' once, 'TRANSFORM' once
    CHECK(has(mine[0], "'Transform', not 'transform'"));
    CHECK(has(mine[0], "entity.get(\"Transform\")"));
    CHECK(has(mine[1], "not 'TRANSFORM'"));
}

TEST_CASE("an unknown component name lists the closest names and the count") {
    TestHost h("err_component");
    one_entity(h);
    const std::string text = eval_err(h, "world.find('p').get('NoSuchThing')");
    MESSAGE(text);
    CHECK(has(text, "unknown component 'NoSuchThing'"));
    CHECK(has(text, "The closest of the "));
    CHECK(has(text, " components: "));
    CHECK(has(text, "`factoria api components`"));
    CHECK(has(eval_err(h, "world.find('p').add('Sprit')"), "did you mean 'Sprite'?"));
    CHECK(has(eval_err(h, "world.find('p').has('RigidBdy2D')"), "did you mean 'RigidBody2D'?"));
}

TEST_CASE("an import the engine lacks suggests the closest export and blames the player only in a player") {
    for (const bool exported : {false, true}) {
        TestHost h(exported ? "err_import_player" : "err_import_dev");
        h.scripts.set_exported_player(exported);
        h.file("scripts/calls.js", "import { Behaviour, inptu } from \"factoria\";\n"
                                   "export default class Calls extends Behaviour {}\n");
        h.file("scenes/main.scene.json", kSceneWithScript);
        REQUIRE(h.start());
        h.load_scene_now("scenes/main.scene.json");
        h.step_frames(2);
        REQUIRE_FALSE(h.scripts.errors().empty());
        const std::string text = h.scripts.errors().front().to_string();
        MESSAGE(text);
        CHECK(has(text, "module 'factoria' has no export 'inptu'"));
        CHECK(has(text, "Did you mean 'input'?"));
        CHECK(has(text, "older than the game's engine") == exported);
    }
}

TEST_CASE("a call the player lacks: the hint is the method check, and the sentence about an old player is the player's "
          "only") {
    for (const bool exported : {false, true}) {
        TestHost h(exported ? "err_call_player" : "err_call_dev");
        h.scripts.set_exported_player(exported);
        // `session` is the game's open bag, so a missing member there is not stopped by the read check: QuickJS says "not a function".
        h.file("scripts/calls.js",
               "import { Behaviour, session } from \"factoria\";\n"
               "export default class Calls extends Behaviour { onStart() { session.method_from_the_future(); } }\n");
        h.file("scenes/main.scene.json", kSceneWithScript);
        REQUIRE(h.start());
        Capture errors(LogLevel::Error);
        h.load_scene_now("scenes/main.scene.json");
        h.step_frames(2);
        REQUIRE_FALSE(h.scripts.errors().empty());
        const std::string text = h.scripts.errors().front().to_string();
        MESSAGE(text);
        CHECK(has(text, "'session' from \"factoria\" has no 'method_from_the_future'"));
        CHECK(has(text, "older than the game's engine") == exported);
        const std::vector<std::string> logged = errors.take();
        REQUIRE_FALSE(logged.empty());
        CHECK(
            has(logged.front(), "hint: Check the method name"));  // "not a function" comes before the old-player advice
        CHECK_FALSE(has(logged.front(), "factoria setup players"));
    }
}

TEST_CASE("a script that misspells a member of a namespace fails with the teaching message in a development run") {
    TestHost h("err_script");
    h.file("scripts/calls.js",
           "import { Behaviour, scene } from \"factoria\";\n"
           "export default class Calls extends Behaviour { onStart() { scene.method_from_the_future(); } }\n");
    h.file("scenes/main.scene.json", kSceneWithScript);
    REQUIRE(h.start());
    h.load_scene_now("scenes/main.scene.json");
    h.step_frames(2);
    REQUIRE_FALSE(h.scripts.errors().empty());
    const ScriptError& e = h.scripts.errors().front();
    MESSAGE(e.to_string());
    CHECK(has(e.message, "'scene' has no 'method_from_the_future'"));
    CHECK(has(e.file, "scripts/calls.js"));  // the error points at the game's line, not at the engine's prelude
    CHECK(e.line == 2);
    CHECK_FALSE(has(e.message, "older than"));
}

TEST_CASE("an exported player has no read check at all") {
    TestHost h("err_player");
    h.scripts.set_exported_player(true);
    one_entity(h);
    // no Proxy anywhere: the prototype chain is the ordinary one and a missing member is undefined
    CHECK(eval_ok(h, "Object.getPrototypeOf(input) === Object.prototype").get<bool>());
    CHECK(eval_ok(h, "Object.getPrototypeOf(Object.getPrototypeOf(world.find('p'))) === Object.prototype").get<bool>());
    CHECK(eval_ok(h, "input.axs === undefined && world.find('p').positon === undefined").get<bool>());
    CHECK(eval_ok(h, "world.find('p').hp = 2; world.find('p').hp").get<int>() == 2);
    h.file("tests/t.test.js", R"(
import { test, expect } from "factoria:test";
test("no read check on the matchers", () => {
  expect(expect(1).toEqul).toBe(undefined);
});
)");
    const TestReport rep = h.scripts.run_tests({"tests/t.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
}

TEST_CASE("a development run: the read check sits behind the object, so members that exist are read as before") {
    TestHost h("err_chain");
    one_entity(h);
    CHECK(eval_ok(h, "Object.getPrototypeOf(input) !== Object.prototype").get<bool>());
    CHECK(eval_ok(h, "Object.getPrototypeOf(world.find('p')) === Entity.prototype").get<bool>());
    CHECK(eval_ok(h, "world.find('p').position.x").get<int>() == 1);
    // the objects the game keeps for itself are not checked
    CHECK(eval_ok(h, "session.lives === undefined && Object.getPrototypeOf(session) === Object.prototype").get<bool>());
}
