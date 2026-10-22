// The script debugger's source instrumenter (fa/tooling/script_instrument.h): the instrumented code of every template and
// example compiles, a tricky corpus keeps its meaning when run in a raw QuickJS runtime with a stub debugger, closures
// created by the hooks see the right scopes, and the debug info is what docs/design/SCRIPT_DEBUGGER.md promises.
#include <doctest.h>

#include <quickjs.h>

#include <algorithm>
#include <chrono>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <map>
#include <sstream>
#include <thread>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/tooling/script_instrument.h"
#include "fa_test_paths.h"  // FA_REPO_ROOT

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

// ---------------------------------------------------------------------------------------------------- a raw QuickJS VM
struct Vm {
    JSRuntime* rt = nullptr;
    JSContext* ctx = nullptr;
    std::map<std::string, std::string> sources;  // modules the loader serves; anything else is an empty module

    Vm() {
        rt = JS_NewRuntime();
        ctx = JS_NewContext(rt);
        JS_SetModuleLoaderFunc(rt, nullptr, &Vm::load, this);
    }
    ~Vm() {
        JS_FreeContext(ctx);
        JS_FreeRuntime(rt);
    }
    Vm(const Vm&) = delete;
    Vm& operator=(const Vm&) = delete;

    static JSModuleDef* load(JSContext* ctx, const char* name, void* opaque) {
        auto* vm = static_cast<Vm*>(opaque);
        auto it = vm->sources.find(name);
        std::string src = it != vm->sources.end() ? it->second : "export {};";
        JSValue v = JS_Eval(ctx, src.c_str(), src.size(), name, JS_EVAL_TYPE_MODULE | JS_EVAL_FLAG_COMPILE_ONLY);
        if (JS_IsException(v)) return nullptr;
        auto* m = static_cast<JSModuleDef*>(JS_VALUE_GET_PTR(v));
        JS_FreeValue(ctx, v);
        return m;
    }

    std::string exception_text() {
        JSValue ex = JS_GetException(ctx);
        std::string text;
        if (const char* s = JS_ToCString(ctx, ex)) {
            text = s;
            JS_FreeCString(ctx, s);
        }
        JSValue stack = JS_GetPropertyStr(ctx, ex, "stack");
        if (const char* s = JS_ToCString(ctx, stack)) {
            if (!JS_IsUndefined(stack)) text += std::string("\n") + s;
            JS_FreeCString(ctx, s);
        }
        JS_FreeValue(ctx, stack);
        JS_FreeValue(ctx, ex);
        return text;
    }

    // "" when it compiles, else the error.
    std::string compile_error(const std::string& code, const char* name = "main.js") {
        JSValue v = JS_Eval(ctx, code.c_str(), code.size(), name, JS_EVAL_TYPE_MODULE | JS_EVAL_FLAG_COMPILE_ONLY);
        if (JS_IsException(v)) return exception_text();
        JS_FreeValue(ctx, v);
        return "";
    }

    std::string global_string(const char* name) {
        JSValue g = JS_GetGlobalObject(ctx);
        JSValue v = JS_GetPropertyStr(ctx, g, name);
        std::string out;
        if (JS_IsString(v)) {
            const char* s = JS_ToCString(ctx, v);
            out = s;
            JS_FreeCString(ctx, s);
        }
        JS_FreeValue(ctx, v);
        JS_FreeValue(ctx, g);
        return out;
    }

    // Runs `stub` (a script) then `main` as the module "main.js"; returns globalThis.__result, or "ERR: ...".
    std::string run(const std::string& stub, const std::string& main) {
        if (!stub.empty()) {
            JSValue s = JS_Eval(ctx, stub.c_str(), stub.size(), "stub.js", JS_EVAL_TYPE_GLOBAL);
            if (JS_IsException(s)) return "ERR: stub: " + exception_text();
            JS_FreeValue(ctx, s);
        }
        JSValue v = JS_Eval(ctx, main.c_str(), main.size(), "main.js", JS_EVAL_TYPE_MODULE);
        if (JS_IsException(v)) return "ERR: " + exception_text();
        JSContext* c = nullptr;
        while (JS_ExecutePendingJob(rt, &c) > 0) {
        }
        std::string err;
        if (JS_PromiseState(ctx, v) == JS_PROMISE_REJECTED) {
            JSValue r = JS_PromiseResult(ctx, v);
            JS_Throw(ctx, r);
            err = "ERR: rejected: " + exception_text();
        }
        JS_FreeValue(ctx, v);
        if (!err.empty()) return err;
        return global_string("__result");
    }
};

// The stub debugger: never stops; e and m return a token, c returns its exception, the rest do nothing.
const char* kQuietStub =
    "globalThis.__fa_dbg = { h: () => false, e: (id, c) => ({ id, c }), m: (id, c) => ({ id, c }),"
    " c: (f, ex) => ex, x() {}, k() {}, p() {}, b() {} };";

InstrumentedScript instr(const std::string& file, const std::string& src, int id = 1) {
    auto r = instrument_script(file, src, id);
    if (!r.ok()) FAIL_CHECK(r.error().to_string());
    return r.ok() ? r.value() : InstrumentedScript{};
}

int count_lines(const std::string& s) { return static_cast<int>(std::count(s.begin(), s.end(), '\n')); }

// ---------------------------------------------------------------------------------------------------- the corpus
struct Case {
    const char* name;
    std::map<std::string, std::string> files;  // "main.js" plus what it imports
};

const std::vector<Case>& corpus() {
    static const std::vector<Case> cases = {
        {"asi", {{"main.js", R"JS(
let a = 1
let b = 2
const f = () => a + b
function g(x) {
  if (x) return x * 2
  else return -1
}
let s = ''
for (let i = 0; i < 3; i++) s += i
const arr = [1, 2, 3]
arr.forEach(v => { s += v })
let c = 0
c++
++c
;[1, 2].forEach(v => c += v)
globalThis.__result = JSON.stringify([f(), g(4), g(0), s, c])
)JS"}}},
        {"labels", {{"main.js", R"JS(
let out = [];
outer: for (let i = 0; i < 3; i++) {
  inner: for (let j = 0; j < 3; j++) {
    if (j === 1) continue outer;
    if (i === 2) break outer;
    out.push(i * 10 + j);
  }
}
blk: { out.push(99); if (out.length) break blk; out.push(100); }
let n = 0;
loop: do { n++; if (n < 5) continue loop; break loop } while (true)
if (n) lbl: for (;;) { n++; break lbl; }
globalThis.__result = JSON.stringify([out, n]);
)JS"}}},
        {"single statement bodies", {{"main.js", R"JS(
let t = 0;
if (t) t = 1; else t = 2;
if (!t) t = 5; else if (t === 2) t = 7; else t = 9;
for (let i = 0; i < 3; i++) t += i;
for (const k in {a: 1, bb: 2}) t += k.length;
for (const v of [1, 2]) t += v;
let w = 0; while (w < 3) w++;
do w--; while (w > 0);
for (;;) break;
if (t) ;
if (t > 100) t = 0
else t++
if (t) if (!t) t = -1; else t += 100;
globalThis.__result = JSON.stringify([t, w]);
)JS"}}},
        {"expression arrows", {{"main.js", R"JS(
const mk = () => ({a: 1});
const add = (a, b) => a + b;
const nested = a => b => c => a + b + c;
const asy = async x => x * 2;
const obj = { f: () => ({ b: [1, 2] }), g: x => (x, 5), h: (...r) => r.length };
const seq = [1, 2, 3].map(v => v * 2).filter(v => v > 2);
const av = await asy(4);
const tpl = (n) => `n=${(m => m + 1)(n)}`;
const multi = (a) =>
    a
      .toString();
globalThis.__result = JSON.stringify([mk(), add(1, 2), nested(1)(2)(3), obj.f(), obj.g(1), obj.h(1, 2), seq, av, tpl(1), multi(7)]);
)JS"}}},
        {"generators and async", {{"main.js", R"JS(
function* gen(n) { for (let i = 0; i < n; i++) { const x = yield i; if (x) return x; } }
const it = gen(3);
const g1 = [it.next().value, it.next().value, it.next(7).value, it.next().done];
async function work(a) { await null; try { await Promise.reject(new Error('x')); } catch (e) { return a + e.message; } }
const w = await work('w-');
async function* ag() { yield 1; yield 2; }
const col = [];
for await (const v of ag()) col.push(v);
const delegated = [...(function* () { yield* gen(2); yield 'end'; })()];
globalThis.__result = JSON.stringify([g1, w, col, delegated]);
)JS"}}},
        {"classes", {{"main.js", R"JS(
class A {
  static count = 0;
  x = 1;
  y = () => this.x + 1;
  #p = 5;
  static #q = 7;
  static { A.count = 10; let z = 3; A.count += z; }
  constructor(v) { this.v = v; A.count++; }
  get val() { return this.v + this.#p; }
  set val(n) { this.v = n; }
  static make(v) { return new A(v); }
  static get q() { return A.#q; }
  ['comp' + 1]() { return 'c'; }
  #priv() { return 'pv'; }
  callPriv() { return this.#priv(); }
}
class B extends A {
  constructor() { super(5); this.w = 2; }
  get val() { return super.val * 2; }
  set val(n) { super.val = n; }
}
const b = new B();
b.val = 3;
const C = class { m() { return 'C'; } };
globalThis.__result = JSON.stringify([A.count, b.val, A.make(1).val, A.q, b.y(), b.comp1(), b.callPriv(), b instanceof A, new C().m()]);
)JS"}}},
        {"destructuring and catch", {{"main.js", R"JS(
function d({a, b: [c, d2 = 4], ...rest}, [e, , f = 9] = [1, 2], ...more) { return [a, c, d2, rest, e, f, more]; }
let r = '';
try { throw {code: 5, msg: 'm'}; } catch ({code, msg}) { r += code + msg; }
try { null.x } catch { r += 'nocatch' }
try { throw 1 } catch (e) { r += e } finally { r += 'f' }
const { p = 3, q: { s } = { s: 4 } } = { };
let [u, v = u + 1] = [10];
globalThis.__result = JSON.stringify([d({a: 1, b: [2], z: 9}, undefined, 'm1', 'm2'), r, p, s, u, v]);
)JS"}}},
        {"switch and directives", {{"main.js", R"JS(
function sw(x) { 'use strict'; "another"
  switch (x) { case 1: { let y = 1; return y; } case 2: let z = 2; return z; default: return 0; } }
function noSemi() { 'use strict'
  return 5 }
function onlyDirective() { 'use strict' }
function empty() {}
const o = { get a() { return 1; }, set a(v) { this._a = v; }, m() { return 'm'; }, async *ag() {}, [`k${1}`]: () => 'k1' };
o.a = 5;
globalThis.__result = JSON.stringify([sw(1), sw(2), sw(3), noSemi(), onlyDirective(), empty(), o.a, o._a, o.m(), o.k1()]);
)JS"}}},
        {"literals, debugger, non-ASCII", {{"main.js", R"JS(
const name = 'ñandú'; const t1 = `a${name}b${`n${1 + 1}`}`; const re = /a\/b[/]+/g; const m = 'xa/b/y'.match(re);
let uni = 'héllo wörld ✓'; if (uni) debugger;
const emoji = '😀'; const afterNon = ['é', () => 1][1](); const afterEmoji = emoji.length + (() => 2)();
const tag = (s, ...v) => s.raw.join('|') + v.join(',');
const tagged = tag`x${1}y${2}z`;
const division = 8 / 2 / 1; const rx = /=/.test('=');
globalThis.__result = JSON.stringify([name, t1, m, uni, afterNon, afterEmoji, tagged, division, rx]);
)JS"}}},
        {"closures in loops", {{"main.js", R"JS(
const fs = [];
for (let i = 0; i < 3; i++) { fs.push(() => i); }
for (const k of ['a', 'b']) fs.push(() => k);
for (var v = 0; v < 2; v++) fs.push(() => v);
function counter() { let n = 0; return { inc: () => ++n, get n() { return n; } }; }
const cn = counter(); cn.inc(); cn.inc();
globalThis.__result = JSON.stringify([fs.map(f => f()), cn.n, typeof arguments]);
)JS"}}},
        {"exports", {{"main.js", R"JS(
import Def, { a, b, c, d, fn, K, aa, bb, ns, z } from './exp.js';
import * as all from './exp.js';
import fnDefault from './expfn.js';
import value from './expval.js';
import { sum } from './exp2.js';
globalThis.__result = JSON.stringify([a, b, c, d, fn(), new K().m(), new Def().who(), aa, bb, ns.sum(1, 2), z, sum(2, 3),
    Object.keys(all).sort(), fnDefault(), value]);
)JS"},
                              {"exp.js", R"JS(
export const a = 1, b = 2;
export let c = 3;
export var d = 4;
export function fn() { return 'fn'; }
export class K { m() { return 'K'; } }
export { a as aa, b as bb };
export default class { who() { return 'anon'; } }
export * from './exp2.js';
export * as ns from './exp2.js';
export { z } from './exp2.js'
)JS"},
                              {"exp2.js", "export function sum(x, y) { return x + y; }\nexport const z = 'z';\n"},
                              {"expfn.js", "export default function () { return 'default fn'; }\n"},
                              {"expval.js", "const base = { n: 4 }\nexport default base.n * 10\n"}}},
        {"hashbang and bom", {{"main.js", "\xEF\xBB\xBF" "let h = 1;\nglobalThis.__result = String(h + 1);\n"}}},
        {"hashbang", {{"main.js", "#!/usr/bin/env node\nlet h = 1;\nglobalThis.__result = String(h + 2);\n"}}},
        {"crlf and comments", {{"main.js", "// c\r\nlet x = 1; /* a\r\n b */ let y = 2; // end\r\nif (x) y++\r\nglobalThis.__result = String(x + y);\r\n"}}},
    };
    return cases;
}

// Instruments every file of `files` (module ids 1, 2, ...).
std::map<std::string, std::string> instrument_all(const std::map<std::string, std::string>& files, bool& ok) {
    std::map<std::string, std::string> out;
    int id = 1;
    ok = true;
    for (const auto& [name, src] : files) {
        auto r = instrument_script(name, src, id++);
        if (!r.ok()) {
            ok = false;
            FAIL_CHECK(name << ": " << r.error().to_string());
            continue;
        }
        out[name] = r->code;
        CHECK_MESSAGE(count_lines(r->code) == count_lines(src), name << ": line count changed");
    }
    return out;
}

std::string read_file(const stdfs::path& p) {
    std::ifstream f(p, std::ios::binary);
    std::stringstream ss;
    ss << f.rdbuf();
    return ss.str();
}

// A stub debugger that stops (h returns true) at statement `target` and lets `p` read `names` through the closure.
std::string probe_stub(int target, const std::vector<std::string>& names) {
    Json n = names;
    return "globalThis.__seen = [];\n"
           "globalThis.__fa_dbg = { h: (f, k) => k === " + std::to_string(target) + ", e: (id, c) => ({ id, c }),"
           " m: (id, c) => ({ id, c }), c: (f, ex) => ex, x() {}, k() {}, b() {},"
           " p: (f, k, c) => { const o = {}; for (const n of " + n.dump() + ") { try { o[n] = c(n); } catch (e) { o[n] = '!' + e.name; } }"
           " __seen.push(o); } };\n";
}

}  // namespace

// ---------------------------------------------------------------------------------------------------- every project script
TEST_CASE("script_instrument: every template and example script instruments and compiles as a module") {
    int files = 0;
    for (const char* top : {"templates", "examples"}) {
        std::error_code ec;
        for (stdfs::recursive_directory_iterator it(stdfs::path(FA_REPO_ROOT) / top, ec), end; !ec && it != end; it.increment(ec)) {
            if (!it->is_regular_file() || it->path().extension() != ".js") continue;
            std::string rel = stdfs::relative(it->path(), stdfs::path(FA_REPO_ROOT)).generic_string();
            if (rel.find("node_modules") != std::string::npos) continue;
            if (rel.find("/scripts/") == std::string::npos && rel.find("/tests/") == std::string::npos &&
                rel.find("/tools/") == std::string::npos)
                continue;
            CAPTURE(rel);
            std::string src = read_file(it->path());
            Vm vm;
            if (!vm.compile_error(src).empty()) continue;  // not a plain module (never loaded by the engine as one)
            auto r = instrument_script(rel, src, 7);
            REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
            CHECK(count_lines(r->code) == count_lines(src));
            CHECK_MESSAGE(vm.compile_error(r->code).empty(), vm.compile_error(r->code));
            CHECK_FALSE(r->info.statements.empty());
            files++;
        }
    }
    CHECK(files > 20);
}

// ---------------------------------------------------------------------------------------------------- semantics
TEST_CASE("script_instrument: the corpus keeps its meaning under a quiet debugger") {
    for (const Case& c : corpus()) {
        CAPTURE(c.name);
        Vm plain;
        plain.sources = c.files;
        std::string expected = plain.run("", c.files.at("main.js"));
        INFO("original: " << expected);
        REQUIRE_FALSE(expected.empty());
        REQUIRE(expected.rfind("ERR", 0) != 0);

        bool ok = false;
        auto instrumented = instrument_all(c.files, ok);
        REQUIRE(ok);
        Vm dbg;
        dbg.sources = instrumented;
        std::string got = dbg.run(kQuietStub, instrumented.at("main.js"));
        CHECK(got == expected);
    }
}

TEST_CASE("script_instrument: exceptions pass through the frame epilogue unchanged") {
    const std::string src = R"JS(
function thrower() { throw new RangeError('boom'); }
function outer() { try { thrower(); } finally { globalThis.__fin = 1; } }
let msg = '';
try { outer(); } catch (e) { msg = e.name + ':' + e.message + ':' + globalThis.__fin; }
globalThis.__result = msg;
)JS";
    Vm dbg;
    auto r = instr("a.js", src);
    CHECK(dbg.run(kQuietStub, r.code) == "RangeError:boom:1");
}

TEST_CASE("script_instrument: the debugger functions are called with the documented shapes") {
    const std::string src = "function f(a) {\n  return a;\n}\nf(1);\ntry { throw 2; } catch (e) {}\ntry { throw 3; } catch {}\ndebugger;\n";
    auto r = instr("a.js", src, 42);
    const std::string stub =
        "globalThis.__log = [];\n"
        "globalThis.__fa_dbg = { h: (f, k) => { __log.push('h' + k); return false; },"
        " m: (id, c) => { __log.push('m' + id + typeof c); return 'MF'; },"
        " e: (id, c) => { __log.push('e' + id + typeof c); return 'EF' + id; },"
        " c: (f, ex) => { __log.push('c' + f); return ex; }, x: (f) => { __log.push('x' + f); },"
        " k: (f, ex) => { __log.push('k' + f + ':' + ex); }, p() {}, b: (f, k, c) => { __log.push('b' + f + k + typeof c); } };\n";
    Vm vm;
    std::string res = vm.run(stub + "", r.code + "\nglobalThis.__result = __log.join(' ');");
    INFO(res);
    CHECK(res.find("m42function") == 0);
    CHECK(res.find("e0function") != std::string::npos);
    CHECK(res.find("xEF0") != std::string::npos);
    CHECK(res.find("kMF:2") != std::string::npos);
    CHECK(res.find("kMF:3") != std::string::npos);
    CHECK(res.find("bMF") != std::string::npos);
}

// ---------------------------------------------------------------------------------------------------- closures
TEST_CASE("script_instrument: the hook closure sees the statement's scope") {
    struct Probe {
        const char* name;
        std::string source;
        int line;  // the statement to stop at
        std::vector<std::string> names;
        std::string expected;  // JSON of the array of {name: value} the stub collected
    };
    const std::vector<Probe> probes = {
        {"block let, param, module const",
         "const top = 'T';\nfunction probe() {}\nfunction f(p) {\n  let local = p + 1;\n  {\n    let inner = local * 2;\n    probe(inner);\n  }\n}\nf(1);\n",
         7, {"inner", "local", "p", "top"}, R"([{"inner":4,"local":2,"p":1,"top":"T"}])"},
        {"loop variable",
         "const out = [];\nfor (let i = 0; i < 3; i++) {\n  out.push(i);\n}\n",
         3, {"i", "out.length"}, R"([{"i":0,"out.length":0},{"i":1,"out.length":1},{"i":2,"out.length":2}])"},
        {"this in a method",
         "class C {\n  constructor() { this.n = 7; }\n  m(a) {\n    return this.n + a;\n  }\n}\nnew C().m(1);\n",
         4, {"this.n", "a", "this instanceof C"}, R"([{"this.n":7,"a":1,"this instanceof C":true}])"},
        {"TDZ and shadowing",
         "let x = 'outer';\nfunction f() {\n  const before = 'ok';\n  let late = 1;\n  { let x = 'inner'; before; }\n}\nf();\n",
         3, {"late", "x"}, R"([{"late":"!ReferenceError","x":"outer"}])"},
        {"catch parameter",
         "try {\n  throw new Error('e1');\n} catch (err) {\n  err.message;\n}\n",
         4, {"err.message"}, R"([{"err.message":"e1"}])"},
        {"destructured params and rest",
         "function f({a, b: [c]}, ...r) {\n  return a;\n}\nf({a: 1, b: [2]}, 3, 4);\n",
         2, {"a", "c", "r.length"}, R"([{"a":1,"c":2,"r.length":2}])"},
        {"expression arrow body",
         "const k = 10;\nconst g = (v) =>\n  v + k;\ng(5);\n",
         3, {"v", "k"}, R"([{"v":5,"k":10}])"},
    };
    for (const Probe& p : probes) {
        CAPTURE(p.name);
        auto r = instr("p.js", p.source);
        int target = -1;
        for (size_t i = 0; i < r.info.statements.size(); i++)
            if (r.info.statements[i].line == p.line) {
                target = static_cast<int>(i);
                break;
            }
        REQUIRE(target >= 0);
        Vm vm;
        std::string res = vm.run(probe_stub(target, p.names), r.code + "\nglobalThis.__result = JSON.stringify(__seen);");
        CHECK(res == p.expected);
    }
}

TEST_CASE("script_instrument: a closure sees an imported binding") {
    const std::string dep = "export const val = 5;\n";
    const std::string main = "import { val } from './dep.js';\nconst k = 3;\nfunction f() {\n  return val + k;\n}\nf();\n";
    auto r = instr("main.js", main, 1);
    int target = -1;
    for (size_t i = 0; i < r.info.statements.size(); i++)
        if (r.info.statements[i].line == 4) target = static_cast<int>(i);
    REQUIRE(target >= 0);
    Vm vm;
    vm.sources["dep.js"] = dep;
    CHECK(vm.run(probe_stub(target, {"val", "k"}), r.code + "\nglobalThis.__result = JSON.stringify(__seen);") ==
          R"([{"val":5,"k":3}])");
}

// ---------------------------------------------------------------------------------------------------- debug info
TEST_CASE("script_instrument: statements, breakable lines and functions") {
    const std::string src =
        "import { x } from './x.js';\n"                                           // 1
        "const f = () => 1;\n"                                                    // 2
        "function decl(a) {\n"                                                    // 3
        "  return a;\n"                                                           // 4
        "}\n"                                                                     // 5
        "class Player {\n"                                                        // 6
        "  static make() { return new Player(); }\n"                              // 7
        "  constructor() { this.n = 1; }\n"                                       // 8
        "  onUpdate(dt) {\n"                                                      // 9
        "    this.n += dt;\n"                                                     // 10
        "  }\n"                                                                   // 11
        "  get hp() { return 1; }\n"                                              // 12
        "  set hp(v) {}\n"                                                        // 13
        "}\n"                                                                     // 14
        "const o = { go: function () {}, run() {}, arrow: () => {}, 'quoted': () => 1 };\n"  // 15
        "o.late = function () {};\n"                                              // 16
        "[1].map((e) => e);\n"                                                    // 17
        "export default class { m() {} }\n";                                      // 18
    auto r = instr("scripts/player.js", src);
    const auto& info = r.info;

    std::vector<std::string> names;
    for (const auto& fn : info.functions) names.push_back(fn.name);
    CHECK(names == std::vector<std::string>{"f", "decl", "Player.make", "Player", "Player.onUpdate", "Player.hp", "Player.hp", "go",
                                            "run", "arrow", "quoted", "late", "(anonymous)", "default.m"});
    // class `default` is anonymous: its methods are named after it
    CHECK(info.breakable_lines() == std::vector<int>{2, 4, 6, 7, 8, 10, 12, 15, 16, 17, 18});
    // `decl` and `f` start where their name is
    CHECK(info.functions[1].line == 3);
    CHECK(info.functions[1].column == 10);
    CHECK(info.functions[1].endLine == 5);
    CHECK(info.functions[4].line == 9);
    CHECK(info.functions[4].column == 3);
    CHECK(info.functions[4].endLine == 11);
    // the first statement is `const f` at 2:1 in the module scope
    REQUIRE(info.statements.size() > 2);
    CHECK(info.statements[0].line == 2);
    CHECK(info.statements[0].column == 1);
    CHECK(info.statements[0].scope == 0);
    // the hook of `return a;` sits in decl's function scope
    int decl_scope = info.functions[1].scope;
    bool found = false;
    for (const auto& s : info.statements)
        if (s.line == 4) {
            found = true;
            CHECK(s.scope == decl_scope);
            CHECK(s.column == 3);
        }
    CHECK(found);
}

TEST_CASE("script_instrument: scope tables") {
    const std::string src =
        "import d, { e as f } from './m.js';\n"                // 1
        "const top = 1; let lt; var tv; class Cls {}\n"        // 2
        "function fn(p, { q, r: [s] }, ...rest) {\n"           // 3
        "  var hoisted = 1;\n"                                 // 4
        "  if (p) { var deep = 2; let blk = 3; function bf() {} }\n"  // 5
        "  const body = 4;\n"                                  // 6
        "  for (let i = 0; i < 1; i++) { const inLoop = i; }\n"      // 7
        "  try { x(); } catch (err) { const inCatch = err; }\n"      // 8
        "  const arrow = (z) => z;\n"                          // 9
        "}\n"
        "export const ex = 1;\n"
        "export function exf() {}\n";
    auto r = instr("a.js", src);
    const auto& sc = r.info.scopes;
    REQUIRE(!sc.empty());
    CHECK(sc[0].parent == -1);
    CHECK(sc[0].kind == "module");
    CHECK(sc[0].names == std::vector<std::string>{"d", "f", "top", "lt", "tv", "Cls", "fn", "ex", "exf"});

    auto find_kind = [&](const std::string& kind, const std::string& withName) {
        for (size_t i = 0; i < sc.size(); i++)
            if (sc[i].kind == kind && std::find(sc[i].names.begin(), sc[i].names.end(), withName) != sc[i].names.end())
                return static_cast<int>(i);
        return -1;
    };
    int fnScope = find_kind("function", "rest");
    REQUIRE(fnScope > 0);
    CHECK(sc[fnScope].parent == 0);
    CHECK(sc[fnScope].names ==
          std::vector<std::string>{"this", "p", "q", "s", "rest", "hoisted", "deep", "body", "arrow"});
    int blk = find_kind("block", "blk");
    REQUIRE(blk > 0);
    CHECK(sc[blk].parent == fnScope);
    CHECK(sc[blk].names == std::vector<std::string>{"blk", "bf"});
    int forHead = find_kind("block", "i");
    REQUIRE(forHead > 0);
    CHECK(sc[forHead].parent == fnScope);
    int inLoop = find_kind("block", "inLoop");
    REQUIRE(inLoop > 0);
    CHECK(sc[inLoop].parent == forHead);
    int catchScope = find_kind("catch", "err");
    REQUIRE(catchScope > 0);
    CHECK(sc[catchScope].names == std::vector<std::string>{"err", "inCatch"});
    CHECK(sc[catchScope].parent == fnScope);
    int arrowScope = find_kind("function", "z");
    REQUIRE(arrowScope > 0);
    CHECK(sc[arrowScope].names == std::vector<std::string>{"z"});  // an arrow has no `this` of its own
    CHECK(sc[arrowScope].parent == fnScope);
}

TEST_CASE("script_instrument: original_column maps instrumented columns back, also after non-ASCII text") {
    const std::string src =
        "const s = 'héllo ✓'; mark_one(); if (s) mark_two();\n"
        "function f(a) { return mark_three(a); }\n"
        "const e = '😀'; const g = () => mark_four(); /* ñ */ g();\n";
    auto r = instr("a.js", src);
    REQUIRE(count_lines(r.code) == count_lines(src));

    auto column_of = [](const std::string& text, const std::string& token, int line) {
        size_t pos = 0;
        for (int l = 1; l < line; l++) pos = text.find('\n', pos) + 1;
        size_t at = text.find(token, pos);
        REQUIRE(at != std::string::npos);
        return static_cast<int>(at - pos) + 1;  // bytes: the strings are UTF-8
    };
    struct Mark {
        const char* token;
        int line;
    };
    for (Mark m : {Mark{"mark_one", 1}, Mark{"mark_two", 1}, Mark{"mark_three", 2}, Mark{"mark_four", 3}, Mark{"g();", 3}}) {
        CAPTURE(m.token);
        int original = column_of(src, m.token, m.line);
        int instrumented = column_of(r.code, m.token, m.line);
        CHECK(instrumented > original);
        CHECK(r.info.original_column(m.line, instrumented) == original);
    }
    // a column inside inserted text maps to the column the text was inserted before
    CHECK(r.info.original_column(1, 1) == 1);
    CHECK(r.info.original_column(1, 3) == 1);
    // every shift is on a real line, sorted
    for (size_t i = 1; i < r.info.shifts.size(); i++) {
        const auto& a = r.info.shifts[i - 1];
        const auto& b = r.info.shifts[i];
        CHECK((a.line < b.line || (a.line == b.line && a.column <= b.column)));
    }
}

TEST_CASE("script_instrument: a source that does not parse gives file:line:column and the parser's message") {
    auto r = instrument_script("scripts/bad.js", "let ok = 1;\nlet s = 'é'; ) ;\n", 1);
    REQUIRE_FALSE(r.ok());
    const std::string msg = r.error().message;
    CHECK(msg.rfind("scripts/bad.js:2:", 0) == 0);
    CHECK(msg.find("Unexpected token") != std::string::npos);
    // column counts bytes: 'é' is two
    CHECK(msg.rfind("scripts/bad.js:2:15:", 0) == 0);
}

TEST_CASE("script_instrument: script_instrumenter wraps instrument_script and is thread safe") {
    ScriptInstrumenter inst = script_instrumenter();
    std::vector<std::thread> threads;
    std::vector<int> ok(4, 0);
    for (int t = 0; t < 4; t++)
        threads.emplace_back([&, t] {
            for (int i = 0; i < 20; i++) {
                auto r = inst("t.js", "function f() { return " + std::to_string(i) + "; }\nf();\n", t);
                if (r.ok() && r->info.functions.size() == 1 && r->code.find("__fa_d.m(" + std::to_string(t) + ",") != std::string::npos)
                    ok[t]++;
            }
        });
    for (auto& th : threads) th.join();
    for (int t = 0; t < 4; t++) CHECK(ok[t] == 20);
}

TEST_CASE("script_instrument: speed on a ~1000 line file") {
    std::string block;
    for (const Case& c : corpus())
        if (std::string(c.name) == "classes") block = c.files.at("main.js");
    std::string big;
    int n = 0;
    while (count_lines(big) < 1000) {
        // each copy in its own function so `const`s do not clash
        big += "function copy" + std::to_string(n++) + "() {\n" + block + "\n}\n";
    }
    (void)instr("big.js", big);  // warm up (creates the runtime, loads acorn)
    constexpr int kRuns = 5;
    auto t0 = std::chrono::steady_clock::now();
    for (int i = 0; i < kRuns; i++) (void)instr("big.js", big);
    double ms = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count() / kRuns;
    std::cout << "[script_instrument] " << count_lines(big) << " lines: " << ms << " ms per run after warm-up\n";
    CHECK(ms < 1000);  // generous: debug builds on loaded CI machines; the number is printed above
}
