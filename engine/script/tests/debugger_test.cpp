// The script debugger runtime (docs/design/SCRIPT_DEBUGGER.md). The modules below are INSTRUMENTED BY HAND in the
// format the design fixes (package A's acorn instrumenter produces the same shape), so these tests need no parser: a
// ScriptInstrumenter looks the file up and returns its hand-written code and debug info.
#include <doctest.h>

#include <atomic>
#include <chrono>
#include <map>
#include <thread>

#include "test_host.h"
#include "fa/script/debugger.h"

using namespace fa;
using namespace fa::test;

namespace {

// ---------------------------------------------------------------------------------------------------- the pieces
std::string H(int k) {  // the statement hook
    const std::string n = std::to_string(k);
    return "if (__fa_h(__fa_f, " + n + ")) __fa_d.p(__fa_f, " + n + ", (__fa_x) => eval(__fa_x)); ";
}
std::string B(int k) {  // before `debugger;`
    return "__fa_d.b(__fa_f, " + std::to_string(k) + ", (__fa_x) => eval(__fa_x)); ";
}
std::string FO(int fid) {  // after the `{` of a function body
    return " let __fa_f; try { __fa_f = __fa_d.e(" + std::to_string(fid) + ", (__fa_x) => eval(__fa_x)); ";
}
const std::string FC = " } catch (__fa_c) { throw __fa_d.c(__fa_f, __fa_c); } finally { __fa_d.x(__fa_f); } ";  // before the `}`
const std::string PRO =
    "const __fa_d = globalThis.__fa_dbg, __fa_h = __fa_d.h, __fa_f = __fa_d.m(@MID@, (__fa_x) => eval(__fa_x)); ";

std::string join(const std::vector<std::string>& lines) {
    std::string out;
    for (const std::string& l : lines) out += l + "\n";
    return out;
}

struct Fixture {
    std::string orig, instr;
    ScriptDebugInfo info;
};

using Sc = ScriptDebugInfo::Scope;
using St = ScriptDebugInfo::Statement;
using Fn = ScriptDebugInfo::Function;

// scripts/calc.js: add(a, b) and run(n) = sum of add over 0..n-1, plus 6. run(5) is 16. Line 5 is blank.
Fixture calc_fixture() {
    Fixture f;
    f.orig = join({"export function add(a, b) {",
                   "    const s = a + b;",
                   "    return s;",
                   "}",
                   "",
                   "export function run(n) {",
                   "    let total = 0;",
                   "    for (let i = 0; i < n; i++) {",
                   "        total = add(total, i);",
                   "    }",
                   "    return total + 6;",
                   "}"});
    f.instr = join({PRO + "export function add(a, b) {" + FO(0),
                    "    " + H(0) + "const s = a + b;",
                    "    " + H(1) + "return s;",
                    FC + "}",
                    "",
                    "export function run(n) {" + FO(1),
                    "    " + H(2) + "let total = 0;",
                    "    " + H(3) + "for (let i = 0; i < n; i++) {",
                    "        " + H(4) + "total = add(total, i);",
                    "    }",
                    "    " + H(5) + "return total + 6;",
                    FC + "}"});
    f.info.statements = {St{2, 5, 1}, St{3, 5, 1}, St{7, 5, 2}, St{8, 5, 2}, St{9, 9, 4}, St{11, 5, 2}};
    f.info.functions = {Fn{"add", 1, 17, 4, 1}, Fn{"run", 6, 17, 12, 2}};
    f.info.scopes = {Sc{-1, "module", {"add", "run"}}, Sc{0, "function", {"this", "a", "b", "s"}},
                     Sc{0, "function", {"this", "n", "total"}}, Sc{2, "block", {"i"}}, Sc{3, "block", {}}};
    return f;
}

// scripts/loop.js: module state, an endless loop that ends when `done` is set, and a function with `debugger;`.
Fixture loop_fixture() {
    Fixture f;
    f.orig = join({"let done = false;",
                   "export let n = 0;",
                   "export function spin() {",
                   "    while (true) {",
                   "        if (done) { break; }",
                   "        n++;",
                   "    }",
                   "    return n;",
                   "}",
                   "export function tick() {",
                   "    n = n + 1;",
                   "    debugger;",
                   "    return n;",
                   "}"});
    f.instr = join({PRO + H(0) + "let done = false;",
                    H(1) + "export let n = 0;",
                    "export function spin() {" + FO(0),
                    "    " + H(2) + "while (true) {",
                    "        " + H(3) + "if (done) { " + H(4) + "break; }",
                    "        " + H(5) + "n++;",
                    "    }",
                    "    " + H(6) + "return n;",
                    FC + "}",
                    "export function tick() {" + FO(1),
                    "    " + H(7) + "n = n + 1;",
                    "    " + H(8) + B(8) + "debugger;",
                    "    " + H(9) + "return n;",
                    FC + "}"});
    f.info.statements = {St{1, 1, 0}, St{2, 1, 0}, St{4, 5, 1}, St{5, 9, 2}, St{5, 22, 3},
                         St{6, 9, 2}, St{8, 5, 1}, St{11, 5, 4}, St{12, 5, 4}, St{13, 5, 4}};
    f.info.functions = {Fn{"spin", 3, 17, 9, 1}, Fn{"tick", 10, 17, 14, 4}};
    f.info.scopes = {Sc{-1, "module", {"done", "n", "spin", "tick"}}, Sc{0, "function", {"this"}},
                     Sc{1, "block", {}}, Sc{2, "block", {}}, Sc{0, "function", {"this"}}};
    return f;
}

// scripts/boom.js: inner() throws; outer() lets it through; guarded() catches it.
Fixture boom_fixture() {
    Fixture f;
    f.orig = join({"export function inner() {",
                   "    throw new Error(\"boom\");",
                   "}",
                   "export function outer() {",
                   "    inner();",
                   "}",
                   "export function guarded() {",
                   "    try {",
                   "        inner();",
                   "    } catch (e) {",
                   "        return \"caught\";",
                   "    }",
                   "}"});
    f.instr = join({PRO + "export function inner() {" + FO(0),
                    "    " + H(0) + "throw new Error(\"boom\");",
                    FC + "}",
                    "export function outer() {" + FO(1),
                    "    " + H(1) + "inner();",
                    FC + "}",
                    "export function guarded() {" + FO(2),
                    "    " + H(2) + "try {",
                    "        " + H(3) + "inner();",
                    "    } catch (e) { __fa_d.k(__fa_f, e);",
                    "        " + H(4) + "return \"caught\";",
                    "    }",
                    FC + "}"});
    f.info.statements = {St{2, 5, 1}, St{5, 5, 2}, St{8, 5, 3}, St{9, 9, 4}, St{11, 9, 5}};
    f.info.functions = {Fn{"inner", 1, 17, 3, 1}, Fn{"outer", 4, 17, 6, 2}, Fn{"guarded", 7, 17, 13, 3}};
    f.info.scopes = {Sc{-1, "module", {"inner", "outer", "guarded"}}, Sc{0, "function", {"this"}},
                     Sc{0, "function", {"this"}}, Sc{0, "function", {"this"}}, Sc{3, "block", {}}, Sc{3, "catch", {"e"}}};
    return f;
}

// A behaviour: onUpdate(dt) with a statement on line 4. `fail` makes line 5 throw (the column test).
Fixture behaviour_fixture(const std::string& cls, bool fail) {
    Fixture f;
    const std::string body = fail ? "this.nothing.x = k;" : "globalThis.ticks = (globalThis.ticks || 0) + 1;";
    const std::string first = fail ? "const k = 2;" : "globalThis.last = 1;";
    f.orig = join({"import { Behaviour } from \"factoria\";",
                   "export default class " + cls + " extends Behaviour {",
                   "  onUpdate(dt) {",
                   "    " + first,
                   "    " + body,
                   "  }",
                   "}"});
    f.instr = join({PRO + "import { Behaviour } from \"factoria\";",
                    "export default class " + cls + " extends Behaviour {",
                    "  onUpdate(dt) {" + FO(0),
                    "    " + H(0) + first,
                    "    " + H(1) + body,
                    "  " + FC + "}",
                    "}"});
    f.info.statements = {St{4, 5, 1}, St{5, 5, 1}};
    f.info.functions = {Fn{cls + ".onUpdate", 3, 3, 6, 1}};
    f.info.scopes = {Sc{-1, "module", {"Behaviour", cls}}, Sc{0, "function", {"this", "dt"}}};
    f.info.shifts = {{3, 17, static_cast<int>(FO(0).size())},
                     {4, 5, static_cast<int>(H(0).size())},
                     {5, 5, static_cast<int>(H(1).size())},
                     {6, 3, static_cast<int>(FC.size())}};
    return f;
}

// The same fixture one line lower (a blank first line), as if the author had edited the file: a hot reload.
Fixture shifted_down(Fixture f) {
    f.orig = "\n" + f.orig;
    f.instr = "\n" + f.instr;
    for (auto& s : f.info.statements) ++s.line;
    for (auto& fn : f.info.functions) {
        ++fn.line;
        ++fn.endLine;
    }
    for (auto& s : f.info.shifts) ++s.line;
    return f;
}

// ------------------------------------------------------------------------------------------------------ the client
struct FakeClient : DebugClient {
    std::function<DebugResume(const DebugStop&, PausedScripts&)> onPause;
    std::function<void(ScriptSystem&)> onPoll;
    struct Out {
        std::string category, text, file;
        int line;
    };
    std::vector<Out> outputs;
    int polls = 0;

    DebugResume paused(const DebugStop& stop, PausedScripts& scripts) override {
        return onPause ? onPause(stop, scripts) : DebugResume::Continue;
    }
    void output(std::string_view category, std::string_view text, const std::string& file, int line) override {
        outputs.push_back({std::string(category), std::string(text), file, line});
    }
    void poll(ScriptSystem& scripts) override {
        ++polls;
        if (onPoll) onPoll(scripts);
    }
};

struct Rig {
    FakeClient client;
    TestHost h;
    std::map<std::string, Fixture> fixtures;
    std::shared_ptr<ScriptDebugger> dbg;

    explicit Rig(const std::string& tag) : h("dbg_" + tag) {
        dbg = std::make_shared<ScriptDebugger>(
            client,
            [this](const std::string& file, std::string_view, int moduleId) -> Result<InstrumentedScript> {
                auto it = fixtures.find(file);
                if (it == fixtures.end()) return Error{"no fixture for " + file, "Register it with Rig::use."};
                InstrumentedScript s;
                s.code = it->second.instr;
                const std::string mid = std::to_string(moduleId);
                for (size_t pos; (pos = s.code.find("@MID@")) != std::string::npos;) s.code.replace(pos, 5, mid);
                s.info = it->second.info;
                return s;
            },
            h.root.string());
        h.scripts.set_debugger(dbg);
    }
    void use(const std::string& file, Fixture f) {
        h.file(file, f.orig);
        fixtures[file] = std::move(f);
    }
    // eval that must work
    Json ev(const std::string& code) {
        auto r = h.scripts.eval(code);
        if (!r.ok()) FAIL(r.error().to_string());
        return r.ok() ? *r : Json();
    }
    void load(const std::string& file, const std::string& global) {
        ev("import('" + file + "').then(m => { globalThis." + global + " = m; return 1; })");
    }
};

DebugBreakpoint bp(int line, std::string condition = "", std::string hit = "", std::string log = "") {
    DebugBreakpoint b;
    b.line = line;
    b.condition = std::move(condition);
    b.hitCondition = std::move(hit);
    b.logMessage = std::move(log);
    return b;
}

const DebugValue* find_value(const std::vector<DebugValue>& vs, const std::string& name) {
    for (const DebugValue& v : vs)
        if (v.name == name) return &v;
    return nullptr;
}

int scope_ref(PausedScripts& p, int frame, const std::string& name) {
    for (const DebugScope& s : p.scopes(frame))
        if (s.name == name) return s.variablesReference;
    return 0;
}

Json scene_of(const std::string& path) {
    Json c = Json::object({{"Script", Json::object({{"path", path}})}});
    Json e = Json::object({{"id", "a"}, {"components", c}});
    return Json::object({{"format", "factoria.scene/1"}, {"entities", Json::array({e})}});
}

}  // namespace

// ------------------------------------------------------------------------------------------------------------ cases
TEST_CASE("debugger: a breakpoint stops with stack, scopes, variables and evaluate") {
    Rig r("bp");
    r.use("scripts/calc.js", calc_fixture());
    auto states = r.dbg->set_breakpoints("scripts/calc.js", {bp(9)});  // before the module is loaded
    REQUIRE(states.size() == 1);
    CHECK(states[0].verified);
    CHECK(states[0].line == 9);
    REQUIRE(r.h.start());
    r.load("scripts/calc.js", "calc");

    int stops = 0;
    r.client.onPause = [&](const DebugStop& s, PausedScripts& p) {
        if (++stops == 1) {
            CHECK(s.reason == "breakpoint");
            REQUIRE(s.hitBreakpointIds.size() == 1);
            CHECK(s.hitBreakpointIds[0] == states[0].id);
            auto frames = p.stack();
            REQUIRE(frames.size() == 1);
            CHECK(frames[0].name == "run");
            CHECK(frames[0].file == "scripts/calc.js");
            CHECK(frames[0].line == 9);
            CHECK(frames[0].column == 9);
            auto scopes = p.scopes(frames[0].id);
            REQUIRE(scopes.size() == 2);
            CHECK(scopes[0].name == "Locals");
            CHECK(scopes[1].name == "Module");
            auto locals = p.variables(scopes[0].variablesReference, 0, 0);
            REQUIRE(find_value(locals, "i"));
            CHECK(find_value(locals, "i")->value == "0");
            CHECK(find_value(locals, "n")->value == "5");
            CHECK(find_value(locals, "total")->value == "0");
            auto module = p.variables(scopes[1].variablesReference, 0, 0);
            REQUIRE(find_value(module, "add"));
            CHECK(find_value(module, "add")->value.rfind("\xc6\x92 add(", 0) == 0);  // "ƒ add(a, b)"
            CHECK(find_value(module, "add")->type == "function");
            auto v = p.evaluate(frames[0].id, "n * 2");
            REQUIRE(v.ok());
            CHECK(v->value == "10");
            auto obj = p.evaluate(frames[0].id, "{a: 1, b: [1, 2, 3]}");  // an object, not a block
            REQUIRE(obj.ok());
            CHECK(obj->value == "{a: 1, b: Array(3)}");
            REQUIRE(obj->variablesReference > 0);
            auto kids = p.variables(obj->variablesReference, 0, 0);
            REQUIRE(find_value(kids, "b"));
            CHECK(find_value(kids, "b")->value == "Array(3) [1, 2, 3]");
            CHECK(find_value(kids, "[[Prototype]]"));
            auto g = p.evaluate(0, "1 + 1");  // frame 0 = global
            REQUIRE(g.ok());
            CHECK(g->value == "2");
            auto bad = p.evaluate(frames[0].id, "nope.x");
            CHECK_FALSE(bad.ok());
            CHECK(bad.error().message.find("nope") != std::string::npos);
        }
        return DebugResume::Continue;
    };
    CHECK(r.ev("calc.run(5)") == 16);
    CHECK(stops == 5);  // once per loop iteration
}

TEST_CASE("debugger: a variable in its temporal dead zone shows as uninitialized, closures are listed") {
    Rig r("tdz");
    r.use("scripts/calc.js", calc_fixture());
    r.dbg->set_breakpoints("scripts/calc.js", {bp(2)});
    REQUIRE(r.h.start());
    r.load("scripts/calc.js", "calc");
    int stops = 0;
    r.client.onPause = [&](const DebugStop&, PausedScripts& p) {
        ++stops;
        auto frames = p.stack();
        REQUIRE(frames.size() == 2);
        CHECK(frames[0].name == "add");
        CHECK(frames[1].name == "run");
        CHECK(frames[1].line == 9);  // the line it is executing
        auto locals = p.variables(scope_ref(p, frames[0].id, "Locals"), 0, 0);
        REQUIRE(find_value(locals, "s"));
        CHECK(find_value(locals, "s")->value == "<uninitialized>");
        CHECK(find_value(locals, "a")->value == "0");
        // The caller's locals are read through its entry closure.
        auto caller = p.variables(scope_ref(p, frames[1].id, "Locals"), 0, 0);
        REQUIRE(find_value(caller, "n"));
        CHECK(find_value(caller, "n")->value == "2");
        return DebugResume::Continue;
    };
    CHECK(r.ev("calc.run(2)") == 7);
    CHECK(stops == 2);
}

TEST_CASE("debugger: a breakpoint on a line without code moves to the next line that has code") {
    Rig r("move");
    r.use("scripts/calc.js", calc_fixture());
    auto states = r.dbg->set_breakpoints("scripts/calc.js", {bp(5), bp(100)});
    REQUIRE(states.size() == 2);
    CHECK(states[0].verified);
    CHECK(states[0].line == 7);  // the blank line 5 and the declaration on 6 have no statement
    CHECK_FALSE(states[1].verified);
    CHECK_FALSE(states[1].message.empty());
    REQUIRE(r.h.start());
    r.load("scripts/calc.js", "calc");
    std::vector<int> lines;
    r.client.onPause = [&](const DebugStop&, PausedScripts& p) {
        lines.push_back(p.stack()[0].line);
        return DebugResume::Continue;
    };
    r.ev("calc.run(1)");
    REQUIRE(lines.size() == 1);
    CHECK(lines[0] == 7);
}

TEST_CASE("debugger: breakpoint conditions and hit conditions") {
    Rig r("cond");
    r.use("scripts/calc.js", calc_fixture());
    REQUIRE(r.h.start());
    r.load("scripts/calc.js", "calc");
    std::vector<std::string> seen;
    r.client.onPause = [&](const DebugStop&, PausedScripts& p) {
        seen.push_back(p.evaluate(1, "i")->value);
        return DebugResume::Continue;
    };
    r.dbg->set_breakpoints("scripts/calc.js", {bp(9, "i === 3")});
    r.ev("calc.run(6)");
    CHECK(seen == std::vector<std::string>{"3"});

    seen.clear();
    r.dbg->set_breakpoints("scripts/calc.js", {bp(9, "", "3")});  // the 3rd hit only
    r.ev("calc.run(6)");
    CHECK(seen == std::vector<std::string>{"2"});

    seen.clear();
    r.dbg->set_breakpoints("scripts/calc.js", {bp(9, "", "% 2")});  // every 2nd hit
    r.ev("calc.run(6)");
    CHECK(seen == std::vector<std::string>{"1", "3", "5"});

    seen.clear();
    r.dbg->set_breakpoints("scripts/calc.js", {bp(9, "i > ")});  // a broken condition stops and says why
    r.client.outputs.clear();
    r.client.onPause = [&](const DebugStop& s, PausedScripts&) {
        seen.push_back(s.description);
        return DebugResume::Continue;
    };
    r.ev("calc.run(1)");
    REQUIRE(seen.size() == 1);
    CHECK(seen[0].find("condition failed") != std::string::npos);
}

TEST_CASE("debugger: a logpoint prints instead of stopping") {
    Rig r("log");
    r.use("scripts/calc.js", calc_fixture());
    r.dbg->set_breakpoints("scripts/calc.js", {bp(9, "", "", "i={i} total={total} sum={total + i}")});
    REQUIRE(r.h.start());
    r.load("scripts/calc.js", "calc");
    int stops = 0;
    r.client.onPause = [&](const DebugStop&, PausedScripts&) {
        ++stops;
        return DebugResume::Continue;
    };
    CHECK(r.ev("calc.run(3)") == 9);
    CHECK(stops == 0);
    std::vector<std::string> texts;
    for (auto& o : r.client.outputs)
        if (o.category == "console") {
            texts.push_back(o.text);
            CHECK(o.file == "scripts/calc.js");
            CHECK(o.line == 9);
        }
    CHECK(texts == std::vector<std::string>{"i=0 total=0 sum=0", "i=1 total=0 sum=1", "i=2 total=1 sum=3"});
}

TEST_CASE("debugger: step in, over and out across two functions") {
    Rig r("step");
    r.use("scripts/calc.js", calc_fixture());
    r.dbg->set_breakpoints("scripts/calc.js", {bp(9)});
    REQUIRE(r.h.start());
    r.load("scripts/calc.js", "calc");
    struct Where {
        std::string reason, fn;
        int line;
        size_t depth;
    };
    std::vector<Where> trail;
    std::vector<DebugResume> script = {DebugResume::StepIn, DebugResume::StepOver, DebugResume::StepOut,
                                       DebugResume::StepOver, DebugResume::Continue};
    size_t next = 0;
    r.client.onPause = [&](const DebugStop& s, PausedScripts& p) {
        auto frames = p.stack();
        trail.push_back({s.reason, frames[0].name, frames[0].line, frames.size()});
        if (trail.size() == 1) r.dbg->set_breakpoints("scripts/calc.js", {});  // steps only from here
        return script[next++];
    };
    CHECK(r.ev("calc.run(3)") == 9);
    REQUIRE(trail.size() == 5);
    CHECK(trail[0].reason == "breakpoint");
    CHECK(trail[0].fn == "run");
    CHECK(trail[0].depth == 1);
    CHECK(trail[1].reason == "step");  // in: into add
    CHECK(trail[1].fn == "add");
    CHECK(trail[1].line == 2);
    CHECK(trail[1].depth == 2);
    CHECK(trail[2].fn == "add");  // over: the next line of add
    CHECK(trail[2].line == 3);
    CHECK(trail[3].fn == "run");  // out: back in run, the next iteration
    CHECK(trail[3].line == 9);
    CHECK(trail[3].depth == 1);
    CHECK(trail[4].fn == "run");  // over: add is not entered
    CHECK(trail[4].line == 9);
    CHECK(trail[4].depth == 1);
}

TEST_CASE("debugger: request_pause from another thread stops an endless loop") {
    Rig r("pause");
    r.use("scripts/loop.js", loop_fixture());
    REQUIRE(r.h.start());
    r.load("scripts/loop.js", "loop");
    int stops = 0;
    r.client.onPause = [&](const DebugStop& s, PausedScripts& p) {
        ++stops;
        CHECK(s.reason == "pause");
        auto frames = p.stack();
        REQUIRE_FALSE(frames.empty());
        CHECK(frames[0].name == "spin");
        auto ok = p.evaluate(frames[0].id, "done = true");  // ends the loop
        CHECK(ok.ok());
        return DebugResume::Continue;
    };
    std::thread pauser([&] {
        std::this_thread::sleep_for(std::chrono::milliseconds(150));
        r.dbg->request_pause();
    });
    auto result = r.h.scripts.eval("loop.spin()");
    pauser.join();
    REQUIRE(result.ok());
    CHECK(result->get<int>() > 0);
    CHECK(stops == 1);
}

TEST_CASE("debugger: exception filters, all and uncaught") {
    Rig r("exc");
    r.use("scripts/boom.js", boom_fixture());
    REQUIRE(r.h.start());
    r.load("scripts/boom.js", "boom");
    std::vector<DebugStop> stops;
    std::vector<std::vector<std::string>> stacks;
    r.client.onPause = [&](const DebugStop& s, PausedScripts& p) {
        stops.push_back(s);
        std::vector<std::string> names;
        for (auto& f : p.stack()) names.push_back(f.name);
        stacks.push_back(names);
        return DebugResume::Continue;
    };

    // Nothing selected: no stops.
    CHECK(r.h.scripts.eval("boom.outer()").ok() == false);
    CHECK(stops.empty());

    // Uncaught only: a caught exception does not stop, an escaping one does (once, at the throw point's stack).
    r.dbg->set_exception_filters(false, true);
    CHECK(r.ev("boom.guarded()") == "caught");
    CHECK(stops.empty());
    CHECK(r.h.scripts.eval("boom.outer()").ok() == false);
    REQUIRE(stops.size() == 1);
    CHECK(stops[0].reason == "exception");
    CHECK(stops[0].exceptionText.find("Error: boom") == 0);
    CHECK(stacks[0] == std::vector<std::string>{"inner", "outer"});  // the throw point first

    // All: the caught one stops too, once.
    stops.clear();
    stacks.clear();
    r.dbg->set_exception_filters(true, false);
    CHECK(r.ev("boom.guarded()") == "caught");
    REQUIRE(stops.size() == 1);
    CHECK(stops[0].description == "Error: boom");
    CHECK(stacks[0].front() == "inner");

    // All and uncaught together: still one stop per exception.
    stops.clear();
    r.dbg->set_exception_filters(true, true);
    CHECK(r.h.scripts.eval("boom.outer()").ok() == false);
    CHECK(stops.size() == 1);
}

TEST_CASE("debugger: a debugger statement stops, set_variable changes what the script computes") {
    Rig r("dbgstmt");
    r.use("scripts/loop.js", loop_fixture());
    r.use("scripts/calc.js", calc_fixture());
    REQUIRE(r.h.start());
    r.load("scripts/loop.js", "loop");
    r.load("scripts/calc.js", "calc");

    std::vector<DebugStop> stops;
    r.client.onPause = [&](const DebugStop& s, PausedScripts& p) {
        stops.push_back(s);
        auto frames = p.stack();
        CHECK(frames[0].name == "tick");
        CHECK(frames[0].line == 12);
        return DebugResume::Continue;
    };
    CHECK(r.ev("loop.tick()") == 1);
    REQUIRE(stops.size() == 1);
    CHECK(stops[0].reason == "debugger");

    // set_variable: a local, a property of an object, a const (refused).
    stops.clear();
    r.dbg->set_breakpoints("scripts/calc.js", {bp(11)});
    r.client.onPause = [&](const DebugStop& s, PausedScripts& p) {
        stops.push_back(s);
        auto frames = p.stack();
        int locals = scope_ref(p, frames[0].id, "Locals");
        auto set = p.set_variable(locals, "total", "100");
        REQUIRE(set.ok());
        CHECK(set->value == "100");
        auto obj = p.evaluate(frames[0].id, "globalThis.cfg = {speed: 1}");
        REQUIRE(obj.ok());
        auto prop = p.set_variable(obj->variablesReference, "speed", "n * 10");  // evaluated in the top frame
        REQUIRE(prop.ok());
        CHECK(prop->value == "50");
        auto bad = p.set_variable(locals, "this", "1");
        CHECK_FALSE(bad.ok());
        return DebugResume::Continue;
    };
    CHECK(r.ev("calc.run(5)") == 106);  // 100 + 6, instead of 10 + 6
    CHECK(r.ev("cfg.speed") == 50);
}

TEST_CASE("debugger: a pause longer than the callback limit does not time the callback out") {
    Rig r("longpause");
    r.use("scripts/slow.js", behaviour_fixture("Slow", false));
    r.dbg->set_breakpoints("scripts/slow.js", {bp(4)});
    r.h.scripts.set_callback_limit(0.2);
    REQUIRE(r.h.start());
    r.h.file("scenes/main.scene.json", scene_of("scripts/slow.js").dump());
    int stops = 0;
    r.client.onPause = [&](const DebugStop&, PausedScripts&) {
        ++stops;
        std::this_thread::sleep_for(std::chrono::milliseconds(600));
        return DebugResume::Continue;
    };
    CHECK(r.h.load_scene_now("scenes/main.scene.json").empty());
    r.h.step_frames(1);
    CHECK(stops == 1);
    CHECK(r.ev("globalThis.ticks") == 1);  // the callback ran to its end
    for (auto& e : r.h.scripts.errors()) CHECK_MESSAGE(false, e.to_string());
    CHECK(r.h.scripts.errors().empty());
}

TEST_CASE("debugger: hot reload keeps the breakpoints") {
    Rig r("reload");
    r.use("scripts/slow.js", behaviour_fixture("Slow", false));
    r.dbg->set_breakpoints("scripts/slow.js", {bp(4)});
    REQUIRE(r.h.start());
    r.h.file("scenes/main.scene.json", scene_of("scripts/slow.js").dump());
    std::vector<int> lines;
    r.client.onPause = [&](const DebugStop&, PausedScripts& p) {
        lines.push_back(p.stack()[0].line);
        return DebugResume::Continue;
    };
    CHECK(r.h.load_scene_now("scenes/main.scene.json").empty());
    r.h.step_frames(1);
    REQUIRE(lines.size() == 1);
    CHECK(lines[0] == 4);

    r.use("scripts/slow.js", shifted_down(behaviour_fixture("Slow", false)));  // the author added a line on top
    r.h.scripts.reload_module("scripts/slow.js");
    r.h.step_frames(1);
    REQUIRE(lines.size() == 2);
    CHECK(lines[1] == 5);  // line 4 is now a blank-ish line: the breakpoint moved to the next statement
    CHECK(r.h.scripts.errors().empty());
}

TEST_CASE("debugger: error columns map back to the original source") {
    // The same behaviour, once plain and once debugged: the recorded error must point at the same place.
    ScriptError plain;
    {
        TestHost h("dbg_col_plain");
        h.file("scripts/pl.js", behaviour_fixture("Pl", true).orig);
        h.file("scenes/main.scene.json", scene_of("scripts/pl.js").dump());
        REQUIRE(h.start());
        h.load_scene_now("scenes/main.scene.json");
        h.step_frames(1);
        REQUIRE(h.scripts.errors().size() == 1);
        plain = h.scripts.errors()[0];
    }
    Rig r("col");
    r.use("scripts/pl.js", behaviour_fixture("Pl", true));
    REQUIRE(r.h.start());
    r.h.file("scenes/main.scene.json", scene_of("scripts/pl.js").dump());
    r.h.load_scene_now("scenes/main.scene.json");
    r.h.step_frames(1);
    REQUIRE(r.h.scripts.errors().size() == 1);
    const ScriptError& e = r.h.scripts.errors()[0];
    CHECK(e.file == "scripts/pl.js");
    CHECK(e.line == 5);
    CHECK(e.line == plain.line);
    CHECK(e.column == plain.column);
    CHECK(e.column > 0);
    CHECK(e.stack.substr(0, e.stack.find('\n')) == plain.stack.substr(0, plain.stack.find('\n')));
    // The debug console got it with the file and line.
    bool found = false;
    for (auto& o : r.client.outputs)
        if (o.category == "stderr" && o.file == "scripts/pl.js" && o.line == 5) found = true;
    CHECK(found);
}

TEST_CASE("debugger: console output reaches the client with the top frame's position") {
    Rig r("console");
    r.use("scripts/calc.js", calc_fixture());
    r.dbg->set_breakpoints("scripts/calc.js", {bp(11)});
    REQUIRE(r.h.start());
    r.load("scripts/calc.js", "calc");
    r.client.onPause = [&](const DebugStop&, PausedScripts& p) {
        auto v = p.evaluate(1, "console.log('total is', total)");  // runs real code while stopped
        CHECK(v.ok());
        return DebugResume::Continue;
    };
    r.ev("calc.run(2)");
    bool found = false;
    for (auto& o : r.client.outputs)
        if (o.category == "stdout" && o.text.find("total is") != std::string::npos) {
            found = true;
            CHECK(o.file == "scripts/calc.js");
            CHECK(o.line == 11);
        }
    CHECK(found);
}

TEST_CASE("debugger: request_terminate resumes, stops the scripts and quits the game") {
    Rig r("term");
    r.use("scripts/loop.js", loop_fixture());
    r.dbg->set_breakpoints("scripts/loop.js", {bp(6)});
    REQUIRE(r.h.start());
    r.load("scripts/loop.js", "loop");
    int stops = 0;
    r.client.onPause = [&](const DebugStop&, PausedScripts&) {
        ++stops;
        r.dbg->request_terminate();
        return DebugResume::Continue;
    };
    auto result = r.h.scripts.eval("loop.spin()");  // would never end: the interrupt handler stops it
    CHECK_FALSE(result.ok());
    CHECK(stops == 1);
    CHECK_FALSE(r.h.quitRequested);
    r.h.step_frames(1);  // the next frame asks the host to quit
    CHECK(r.h.quitRequested);
}

TEST_CASE("debugger: stop on entry stops at the first statement of the run") {
    Rig r("entry");
    r.use("scripts/loop.js", loop_fixture());
    REQUIRE(r.h.start());
    r.dbg->set_stop_on_entry(true);
    std::vector<DebugStop> stops;
    std::vector<DebugFrame> tops;
    r.client.onPause = [&](const DebugStop& s, PausedScripts& p) {
        stops.push_back(s);
        tops.push_back(p.stack()[0]);
        return DebugResume::Continue;
    };
    r.load("scripts/loop.js", "loop");
    REQUIRE(stops.size() == 1);
    CHECK(stops[0].reason == "entry");
    CHECK(tops[0].name == "(module)");
    CHECK(tops[0].file == "scripts/loop.js");
    CHECK(tops[0].line == 1);
    r.ev("loop.n");  // later statements do not stop again (no step, no breakpoint)
    CHECK(stops.size() == 1);
}

TEST_CASE("debugger: the client is polled once per frame") {
    Rig r("poll");
    REQUIRE(r.h.start());
    int calls = 0;
    r.client.onPoll = [&](ScriptSystem& scripts) {
        ++calls;
        auto v = scripts.eval("1 + 2");  // the REPL moment
        CHECK(v.ok());
    };
    r.h.step_frames(3);
    CHECK(calls == 3);
}

TEST_CASE("debugger: a module the instrumenter refuses runs as written") {
    Rig r("fallback");
    r.h.file("scripts/plain.js", "export function f() { return 7; }\n");
    REQUIRE(r.h.start());
    r.load("scripts/plain.js", "plain");
    CHECK(r.ev("plain.f()") == 7);
    bool told = false;
    for (auto& o : r.client.outputs)
        if (o.text.find("cannot instrument scripts/plain.js") != std::string::npos) told = true;
    CHECK(told);
    CHECK(r.ev("typeof __fa_dbg") == "object");
}

TEST_CASE("debugger: a run without a debugger is unaffected") {
    TestHost h("dbg_none");
    h.file("scripts/calc.js", calc_fixture().orig);
    REQUIRE(h.start());
    CHECK(h.scripts.eval("typeof globalThis.__fa_dbg")->get<std::string>() == "undefined");
    REQUIRE(h.scripts.eval("import('scripts/calc.js').then(m => { globalThis.calc = m; return 1; })").ok());
    CHECK(h.scripts.eval("calc.run(5)")->get<int>() == 16);
    h.step_frames(2);
    CHECK(h.scripts.errors().empty());
}
