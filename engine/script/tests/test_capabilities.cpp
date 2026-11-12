// M92.1d1: the commands a script calls run with a capability set: a game script gets {read, state} (the player and the editor's
// Play), a test gets {read, state} plus what its `capabilities` option asks for (never more than whoever runs it has), and a
// project tool keeps the set of whoever called the tool.
#include <doctest.h>

#include <string>
#include <vector>

#include "fa/core/log.h"
#include "test_host.h"

using namespace fa;
using namespace fa::test;

namespace {

bool contains(const std::string& s, const char* part) { return s.find(part) != std::string::npos; }

// Stand-ins for commands of every kind, each declaring what the real ones of its kind declare.
void add_fake_commands(TestHost& h, int& counter) {
    const Json anyObject = Json::object({{"type", "object"}, {"properties", Json::object()}, {"additionalProperties", true}});
    auto add = [&](const char* name, CapabilitySet caps) {
        h.cmds.add({name, "builtin", "", anyObject, false, "fake"}, [&counter](const Json&) {
            ++counter;
            return Json::object({{"ran", true}});
        });
        REQUIRE(h.cmds.declare_capabilities(name, caps));
    };
    add("fake.state", capability_sets::changes_state());
    add("fake.write", CapabilitySet{Capability::Read, Capability::State, Capability::WriteProject});
    add("fake.anywhere", CapabilitySet{Capability::Read, Capability::State, Capability::WriteAnywhere});
    add("fake.net", CapabilitySet{Capability::Read, Capability::Network});
}

// A behaviour that records what each command answers: globalThis.R[name] = "ok" or {code, hint}.
const char* kProbe = R"JS(
import { Behaviour, fa } from "factoria";
export default class Probe extends Behaviour {
  onStart() {
    globalThis.R = {};
    for (const name of ["fake.state", "fake.write", "fake.anywhere", "fake.net", "project.mem"]) {
      try { fa.call(name, {}); globalThis.R[name] = "ok"; }
      catch (e) { globalThis.R[name] = { code: e.code, hint: e.hint }; }
    }
  }
}
)JS";

const char* kScene = R"({ "format": "factoria.scene/1", "entities": [
  { "id": "p", "components": { "Script": { "path": "scripts/probe.js" } } } ] })";

Json probe_results(TestHost& h) {
    auto r = h.scripts.eval("globalThis.R");
    REQUIRE(r.ok());
    return *r;
}

void run_probe(TestHost& h, std::optional<ScriptSystem::GameRole> role = std::nullopt) {
    h.file("scripts/probe.js", kProbe);
    h.file("scenes/main.scene.json", kScene);
    h.file("tools/mem.js", "export default { name: 'mem', summary: 's', capabilities: ['read', 'state'], run() { return 1; } };");
    if (role) h.scripts.set_game_role(*role);
    REQUIRE(h.start());
    REQUIRE(h.load_scene_now("scenes/main.scene.json").empty());
    h.step_frames(1);
}

}  // namespace

TEST_CASE("capabilities: a game script gets {read, state}; the denial names where to do the rest") {
    TestHost h("cap_game");
    int ran = 0;
    add_fake_commands(h, ran);
    run_probe(h);
    CHECK(h.scripts.game_capabilities() == capability_sets::game_player());
    Json r = probe_results(h);
    CHECK(r["fake.state"] == "ok");
    CHECK(r["project.mem"] == "ok");
    for (const char* denied : {"fake.write", "fake.anywhere", "fake.net"}) {
        CAPTURE(denied);
        REQUIRE(r[denied].is_object());
        CHECK(r[denied]["code"] == "capability_denied");
        const std::string hint = r[denied]["hint"].get<std::string>();
        CHECK(contains(hint, "Game scripts get {read, state}"));
        CHECK(contains(hint, "factoria call"));
        CHECK(contains(hint, "capabilities"));  // a test of the game can ask for it
    }
    CHECK(ran == 1);  // only fake.state ran
    CHECK(h.scripts.errors().empty());
}

TEST_CASE("capabilities: the editor's Play gets the same set as the player, and says so") {
    TestHost h("cap_play");
    int ran = 0;
    add_fake_commands(h, ran);
    run_probe(h, ScriptSystem::GameRole::EditorPlay);
    CHECK(h.scripts.game_capabilities() == capability_sets::editor_play());
    CHECK(capability_sets::editor_play() == capability_sets::game_player());
    Json r = probe_results(h);
    CHECK(r["fake.state"] == "ok");
    REQUIRE(r["fake.write"].is_object());
    CHECK(r["fake.write"]["code"] == "capability_denied");
    CHECK(contains(r["fake.write"]["hint"].get<std::string>(), "Play"));
    CHECK(ran == 1);
}

TEST_CASE("capabilities: two script hosts in one process do not mix their sets") {
    TestHost a("cap_two_a");
    int ranA = 0;
    add_fake_commands(a, ranA);
    run_probe(a, ScriptSystem::GameRole::EditorPlay);
    TestHost b("cap_two_b");
    int ranB = 0;
    add_fake_commands(b, ranB);
    run_probe(b, ScriptSystem::GameRole::Player);
    CHECK(contains(probe_results(a)["fake.write"]["hint"].get<std::string>(), "Play"));
    CHECK_FALSE(contains(probe_results(b)["fake.write"]["hint"].get<std::string>(), "Play"));
}

TEST_CASE("capabilities: a test asks for more with the `capabilities` option, and gets nothing the runner lacks") {
    TestHost h("cap_test");
    int ran = 0;
    add_fake_commands(h, ran);
    h.file("scripts/probe.js", kProbe);
    h.file("scenes/main.scene.json", kScene);
    h.file("tests/c.test.js", R"JS(
import { test, expect, game } from "factoria:test";
import { fa } from "factoria";
test("plain: write is denied, state is not", () => {
  fa.call("fake.state", {});
  let err = null;
  try { fa.call("fake.write", {}); } catch (e) { err = e; }
  expect(err.code).toBe("capability_denied");
  expect(err.hint).toContain("capabilities: ['writeProject']");
});
test("asked: write works, the others stay denied", () => {
  fa.call("fake.write", {});
  let err = null;
  try { fa.call("fake.net", {}); } catch (e) { err = e; }
  expect(err.code).toBe("capability_denied");
}, { capabilities: ["writeProject"] });
test("a string is one capability", () => { fa.call("fake.write", {}); }, { capabilities: "writeProject" });
test("the next test is back to the default", () => {
  let err = null;
  try { fa.call("fake.write", {}); } catch (e) { err = e; }
  expect(err.code).toBe("capability_denied");
});
test("game scripts the test runs keep {read, state}", () => {
  game.load("scenes/main.scene.json");
  game.step(1);
  expect(globalThis.R["fake.write"].code).toBe("capability_denied");
  expect(globalThis.R["fake.state"]).toBe("ok");
}, { capabilities: ["writeProject"] });
)JS");
    REQUIRE(h.start());
    {
        TestReport rep = h.scripts.run_tests({"tests/c.test.js"});
        for (auto& c : rep.cases) MESSAGE(c.name, ": ", c.passed ? "pass" : c.message);
        MESSAGE(rep.summary());
        CHECK(rep.ok());
        CHECK(rep.passed == 5);
    }
    // Under a runner with less (an MCP read-only run, a game's set), the option cannot widen it.
    {
        CommandCapabilityScope scope(capability_sets::game_player());
        TestReport rep = h.scripts.run_tests({"tests/c.test.js"});
        CHECK(rep.failed >= 1);
        bool writeRefused = false;
        for (auto& c : rep.cases)
            if (c.name == "asked: write works, the others stay denied" && !c.passed) writeRefused = true;
        CHECK(writeRefused);
    }
    // The set is back after the run: a later command call outside a test is not narrowed by the test's.
    CHECK(h.cmds.call("fake.write").ok);
}

TEST_CASE("capabilities: a typo in the `capabilities` option is a teaching error with the pointer") {
    TestHost h("cap_typo");
    int ran = 0;
    add_fake_commands(h, ran);
    h.file("tests/typo.test.js", R"JS(
import { test, expect } from "factoria:test";
test("typo", () => { expect(1).toBe(1); }, { capabilities: ["writeProjct"] });
)JS");
    h.file("tests/shape.test.js", R"JS(
import { test, expect } from "factoria:test";
test("shape", () => { expect(1).toBe(1); }, { capabilities: 3 });
)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/typo.test.js", "tests/shape.test.js"});
    CHECK_FALSE(rep.ok());
    REQUIRE(rep.loadErrors.size() == 2);
    const std::string typo = rep.loadErrors[0].message;
    CAPTURE(typo);
    CHECK(contains(typo, "/options/capabilities"));
    CHECK(contains(typo, "writeProjct"));
    CHECK(contains(typo, "writeProject"));  // did you mean
    CHECK(contains(typo, "tests/typo.test.js"));
    CHECK(contains(rep.loadErrors[1].message, "capabilities"));
}

TEST_CASE("capabilities: a project tool keeps the set of whoever called it") {
    TestHost h("cap_tool");
    int ran = 0;
    add_fake_commands(h, ran);
    // The tool needs writeProject itself (the default of a tool that is not readOnly) and tries each kind of command.
    h.file("tools/try.js", R"JS(
import { fa } from "factoria";
export default { name: 'try', summary: 's', run() {
  const out = {};
  for (const name of ["fake.state", "fake.write", "fake.anywhere", "fake.net"]) {
    try { fa.call(name, {}); out[name] = "ok"; } catch (e) { out[name] = e.code; }
  }
  return out;
} };
)JS");
    // A tool a game script may call (it declares {read, state}) that tries to do more.
    h.file("tools/sneak.js", R"JS(
import { fa } from "factoria";
export default { name: 'sneak', summary: 's', capabilities: ['read', 'state'], run() {
  const out = {};
  for (const name of ["fake.state", "fake.write"]) {
    try { fa.call(name, {}); out[name] = "ok"; } catch (e) { out[name] = e.code; }
  }
  return out;
} };
)JS");
    REQUIRE(h.start());
    // Never widened to the runtime's set: whoever has everything, the tool has everything.
    {
        CommandCallerScope user(CommandCaller::User);
        auto r = h.cmds.call("project.try");
        REQUIRE(r.ok);
        CHECK(r.result["fake.write"] == "ok");
        CHECK(r.result["fake.anywhere"] == "ok");
        CHECK(r.result["fake.net"] == "ok");
    }
    // Never narrowed to game_player: an MCP caller keeps writeProject and network, and still has no writeAnywhere.
    {
        CommandCallerScope mcp(CommandCaller::Mcp);
        auto r = h.cmds.call("project.try");
        REQUIRE(r.ok);
        CHECK(r.result["fake.state"] == "ok");
        CHECK(r.result["fake.write"] == "ok");
        CHECK(r.result["fake.net"] == "ok");
        CHECK(r.result["fake.anywhere"] == "capability_denied");
    }
    // A narrower caller narrows the tool's calls too.
    {
        CommandCapabilityScope projectOnly(CapabilitySet{Capability::Read, Capability::State, Capability::WriteProject});
        auto r = h.cmds.call("project.try");
        REQUIRE(r.ok);
        CHECK(r.result["fake.write"] == "ok");
        CHECK(r.result["fake.net"] == "capability_denied");
        CHECK(r.result["fake.anywhere"] == "capability_denied");
    }
    // A game script calls a tool through fa.call: the tool runs with the game's set, so it cannot widen it.
    h.file("scripts/sneaker.js", R"JS(
import { Behaviour, fa } from "factoria";
export default class Sneaker extends Behaviour {
  onStart() { globalThis.S = fa.call("project.sneak", {}); }
}
)JS");
    h.file("scenes/main.scene.json", R"({ "format": "factoria.scene/1", "entities": [
      { "id": "s", "components": { "Script": { "path": "scripts/sneaker.js" } } } ] })");
    REQUIRE(h.load_scene_now("scenes/main.scene.json").empty());
    h.step_frames(1);
    auto s = h.scripts.eval("globalThis.S");
    REQUIRE(s.ok());
    CHECK((*s)["fake.state"] == "ok");
    CHECK((*s)["fake.write"] == "capability_denied");
    // And the game's set did not leak into the next tool call from outside.
    {
        CommandCallerScope user(CommandCaller::User);
        auto r = h.cmds.call("project.sneak");
        REQUIRE(r.ok);
        CHECK(r.result["fake.write"] == "ok");
    }
}

TEST_CASE("capabilities: eval runs with the caller's set") {
    TestHost h("cap_eval");
    int ran = 0;
    add_fake_commands(h, ran);
    REQUIRE(h.start());
    auto ok = h.scripts.eval("fa.call('fake.write', {}).ran");
    REQUIRE(ok.ok());
    CHECK(*ok == true);
    CommandCapabilityScope narrow(capability_sets::game_player());
    auto denied = h.scripts.eval("fa.call('fake.write', {})");
    CHECK_FALSE(denied.ok());
}

TEST_CASE("capabilities: a tool with `capabilities: []` is refused, and readOnly next to more than read is warned about") {
    TestHost h("cap_tool_empty");
    h.file("tools/empty.js", "export default { name: 'empty', summary: 's', capabilities: [], run() { return 1; } };");
    h.file("tools/loud.js", "export default { name: 'loud', summary: 's', readOnly: true, capabilities: ['read', 'state'], run() { return 1; } };");
    h.file("tools/quiet.js", "export default { name: 'quiet', summary: 's', readOnly: true, capabilities: ['read'], run() { return 1; } };");
    std::vector<std::string> warnings;
    const int sink = add_log_sink([&](const LogEntry& e) {
        if (e.level == LogLevel::Warn && e.category == "script") warnings.push_back(e.message);
    });
    REQUIRE(h.start());
    remove_log_sink(sink);
    CHECK_FALSE(h.cmds.has("project.empty"));
    bool taught = false;
    for (const auto& e : h.scripts.errors())
        if (contains(e.message, "tool 'empty'") && contains(e.message, "at least \"read\"") && contains(e.message, "/capabilities")) taught = true;
    CHECK(taught);
    // readOnly is derived from the set: the loud tool is not read-only, and its warning names it.
    REQUIRE(h.cmds.has("project.loud"));
    CHECK_FALSE(h.cmds.info("project.loud")->readOnly);
    CHECK(h.cmds.info("project.quiet")->readOnly);
    int named = 0;
    for (const std::string& w : warnings) {
        if (contains(w.c_str(), "'loud'")) {
            ++named;
            CHECK(contains(w.c_str(), "readOnly"));
            CHECK(contains(w.c_str(), "derived"));
        }
        CHECK_FALSE(contains(w.c_str(), "'quiet'"));
    }
    CHECK(named == 1);
}

// Pins what docs/SCRIPTING.md says ("Promise continuations and listeners run with the set of whoever pumps the jobs"): the job
// queue does not remember who queued a job, so a game continuation that an eval (or a tool, or a test) pumps runs with the
// caller's set, while one pumped by the frame loop (game.step) runs with the game's.
TEST_CASE("capabilities: a game promise continuation runs with the set of whoever pumps the jobs") {
    TestHost h("cap_jobs");
    int ran = 0;
    add_fake_commands(h, ran);
    h.file("scripts/waiter.js", R"JS(
import { Behaviour, fa } from "factoria";
function attempt(key) { try { fa.call("fake.write", {}); globalThis.C[key] = "ok"; } catch (e) { globalThis.C[key] = e.code; } }
export default class Waiter extends Behaviour {
  onStart() {
    globalThis.C = {};
    new Promise((r) => { globalThis.byEval = r; }).then(() => attempt("eval"));
    new Promise((r) => { globalThis.byFrame = r; }).then(() => attempt("frame"));
  }
  onUpdate() { if (globalThis.releaseFrame) { globalThis.releaseFrame = false; globalThis.byFrame(); } }
}
)JS");
    h.file("scenes/main.scene.json", R"({ "format": "factoria.scene/1", "entities": [
      { "id": "w", "components": { "Script": { "path": "scripts/waiter.js" } } } ] })");
    REQUIRE(h.start());
    REQUIRE(h.load_scene_now("scenes/main.scene.json").empty());
    h.step_frames(1);
    // Released by an eval for the user (all capabilities): the eval pumps the continuation with ITS set.
    REQUIRE(h.scripts.eval("globalThis.byEval(); 1").ok());
    // Released from a behaviour callback: the frame loop pumps it with the game's set.
    REQUIRE(h.scripts.eval("globalThis.releaseFrame = true; 1").ok());
    h.step_frames(1);
    auto c = h.scripts.eval("globalThis.C");
    REQUIRE(c.ok());
    CHECK((*c)["eval"] == "ok");
    CHECK((*c)["frame"] == "capability_denied");
}

TEST_CASE("capabilities: a module first imported by a test keeps the game's set at its top level") {
    TestHost h("cap_import_in_test");
    int ran = 0;
    add_fake_commands(h, ran);
    h.file("scripts/top.js", R"JS(
import { Behaviour, fa } from "factoria";
let r = "ok";
try { fa.call("fake.write", {}); } catch (e) { r = e.code; }
globalThis.TOP = r;
export default class Top extends Behaviour {}
)JS");
    h.file("scenes/main.scene.json", R"({ "format": "factoria.scene/1", "entities": [
      { "id": "t", "components": { "Script": { "path": "scripts/top.js" } } } ] })");
    h.file("tests/top.test.js", R"JS(
import { test, expect, game } from "factoria:test";
import { fa } from "factoria";
test("the test itself may write", () => { fa.call("fake.write", {}); }, { capabilities: ["writeProject"] });
test("a behaviour module first loaded here runs its top level as game code", () => {
  game.load("scenes/main.scene.json");
  game.step(1);
  expect(globalThis.TOP).toBe("capability_denied");
}, { capabilities: ["writeProject"] });
)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/top.test.js"});
    for (auto& c : rep.cases) MESSAGE(c.name, ": ", c.passed ? "pass" : c.message);
    CHECK(rep.ok());
    CHECK(rep.passed == 2);
}
