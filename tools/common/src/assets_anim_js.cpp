// The JavaScript of assets.animate_svg: a project module (an `.anim.js`) whose default export is
// `frame({t, frame, frames, fps, progress, params, rng}) => string`, the SVG of that frame.
//
// It runs in a QuickJS runtime of its own, made for the call and thrown away after it, with
//   - no engine bindings: nothing but the language itself (no `factoria`, no DOM, no Node, no timers, no files);
//   - a deterministic Math.random (a seeded stream, restarted for every frame) and a deterministic Date (a fixed day, moved
//     to the frame's time), so the same module draws the same frames on every run;
//   - a time limit per call (loading the module, and each frame) and a memory limit for the whole runtime;
//   - imports only of project files with relative paths ("./shapes.js"); the files it loaded become inputs of the recipe.
// An error names the module's file, line and column and the frame that was being drawn.
#include "assets_anim_js.h"

#include <quickjs.h>

#include <chrono>
#include <cstring>
#include <format>
#include <set>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

constexpr const char* kPrelude = R"JS((function (native) {
  "use strict";
  const BASE_MS = Date.UTC(2026, 0, 1);
  const RealDate = Date;
  let nowMs = BASE_MS;
  class SandboxDate extends RealDate {
    constructor(...args) { if (args.length === 0) super(nowMs); else super(...args); }
    static now() { return nowMs; }
  }
  Object.defineProperty(globalThis, "Date", { value: SandboxDate, writable: true, configurable: true });

  // mulberry32: a small seeded stream; the same seed gives the same numbers everywhere.
  function stream(seed) {
    let s = seed | 0;
    return function () {
      s = (s + 0x6D2B79F5) | 0;
      let t = Math.imul(s ^ (s >>> 15), 1 | s);
      t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }
  let mathStream = stream(0);
  Object.defineProperty(Math, "random", { value: function random() { return mathStream(); }, writable: true, configurable: true });

  // Array find/findIndex/findLast/findLastIndex of this QuickJS poll for the time limit in a way that can leave a reference
  // short (see engine/script/src/quickjs_fixes.cpp); these have the same behaviour without that poll.
  for (const [name, fromEnd, wantIndex] of [["find", false, false], ["findIndex", false, true], ["findLast", true, false], ["findLastIndex", true, true]]) {
    const fn = { [name](callback, thisArg) {
      const o = Object(this);
      const len = o.length >>> 0;
      if (typeof callback !== "function") throw new TypeError("not a function");
      for (let k = 0; k < len; k++) {
        const i = fromEnd ? len - 1 - k : k;
        const v = o[i];
        if (callback.call(thisArg, v, i, o)) return wantIndex ? i : v;
      }
      return wantIndex ? -1 : undefined;
    } }[name];
    Object.defineProperty(Array.prototype, name, { value: fn, writable: true, configurable: true });
  }

  function makeRng(seed) {
    const next = stream(seed);
    const rng = () => next();
    rng.range = (a, b) => a + (b - a) * next();
    rng.int = (n) => Math.floor(next() * n);
    rng.pick = (list) => list[Math.floor(next() * list.length)];
    rng.chance = (p) => next() < p;
    rng.gauss = () => { let u = 0, v = 0; while (u === 0) u = next(); while (v === 0) v = next(); return Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * v); };
    return rng;
  }

  const show = (v) => { if (typeof v === "string") return v; try { return JSON.stringify(v); } catch (e) { return String(v); } };
  const logger = (level) => (...args) => native.log(level, args.map(show).join(" "));
  Object.defineProperty(globalThis, "console", { value: { log: logger("log"), info: logger("log"), debug: logger("log"), warn: logger("warn"), error: logger("error") }, writable: true, configurable: true });

  return {
    run(fn, args, seed, ms) {
      mathStream = stream(seed ^ 0x5bd1e995);
      nowMs = BASE_MS + ms;
      args.rng = makeRng(seed);
      // the same stream on every frame for one key: what a sparkle or a crack keeps from frame to frame
      args.rngFor = (key) => {
        let h = 2166136261 ^ (args.seed | 0);
        for (const ch of String(key)) { h ^= ch.codePointAt(0); h = Math.imul(h, 16777619); }
        return makeRng(h);
      };
      return fn(args);
    },
  };
}))JS";

constexpr std::size_t kMaxLogLines = 200;

struct JsError {
    std::string name, message, stack, file;
    int line = 0, column = 0;
};

}  // namespace

struct AnimModule::Impl {
    std::string projectDir;
    std::string moduleRel;
    Limits limits;
    JSRuntime* rt = nullptr;
    JSContext* ctx = nullptr;
    JSValue hooks = JS_UNDEFINED;
    JSValue fn = JS_UNDEFINED;
    std::vector<std::string> files;
    std::set<std::string> fileSet;
    std::vector<std::string> logLines;
    std::chrono::steady_clock::time_point deadline;
    bool timedOut = false;
    std::string loaderError;  // why a project file could not be read (the JS error only says it failed)

    ~Impl() {
        if (ctx) {
            JS_FreeValue(ctx, fn);
            JS_FreeValue(ctx, hooks);
            JS_FreeContext(ctx);
        }
        if (rt) JS_FreeRuntime(rt);
    }

    static int interrupt(JSRuntime*, void* opaque) {
        auto* self = static_cast<Impl*>(opaque);
        if (std::chrono::steady_clock::now() > self->deadline) {
            self->timedOut = true;
            return 1;
        }
        return 0;
    }

    static char* normalize(JSContext* ctx, const char* base, const char* name, void* opaque) {
        auto* self = static_cast<Impl*>(opaque);
        const std::string spec = name;
        std::string joined;
        if (spec.rfind("./", 0) == 0 || spec.rfind("../", 0) == 0) {
            const std::string b = base ? base : "";
            const std::size_t slash = b.rfind('/');
            joined = (slash == std::string::npos ? std::string() : b.substr(0, slash + 1)) + spec;
        } else if (!spec.empty() && spec[0] == '/') {
            joined = spec.substr(1);
        } else {
            JS_ThrowReferenceError(ctx, "cannot import '%s' from %s: an animation module has no packages and no engine modules; import project files with a relative path such as './shapes.js'",
                                   name, base && *base ? base : self->moduleRel.c_str());
            return nullptr;
        }
        auto norm = fs::normalize_checked(joined);
        if (!norm.ok() || norm->empty()) {
            JS_ThrowReferenceError(ctx, "cannot import '%s' from %s: the path leaves the project folder", name, base ? base : "");
            return nullptr;
        }
        char* out = static_cast<char*>(js_malloc(ctx, norm->size() + 1));
        if (!out) return nullptr;
        std::memcpy(out, norm->c_str(), norm->size() + 1);
        return out;
    }

    static JSModuleDef* loader(JSContext* ctx, const char* name, void* opaque) {
        auto* self = static_cast<Impl*>(opaque);
        return self->compile(name);
    }

    JSModuleDef* compile(const std::string& rel) {
        std::optional<std::string> text;
        try {
            text = tooling_detail::read_file(project_file(projectDir, rel));
        } catch (const CommandError& e) {
            JS_ThrowReferenceError(ctx, "cannot load module '%s': %s", rel.c_str(), e.what());
            return nullptr;
        }
        if (!text) {
            JS_ThrowReferenceError(ctx, "cannot load module '%s': the file does not exist or cannot be read (it is imported by the animation module)", rel.c_str());
            return nullptr;
        }
        // listed before it is compiled: the files it imports are loaded during the compile, and come after it
        if (fileSet.insert(rel).second) files.push_back(rel);
        JSValue func = JS_Eval(ctx, text->c_str(), text->size(), rel.c_str(), JS_EVAL_TYPE_MODULE | JS_EVAL_FLAG_COMPILE_ONLY);
        if (JS_IsException(func)) return nullptr;
        auto* def = static_cast<JSModuleDef*>(JS_VALUE_GET_PTR(func));
        JS_FreeValue(ctx, func);
        return def;
    }

    static JSValue native_log(JSContext* ctx, JSValueConst, int argc, JSValueConst* argv) {
        auto* self = static_cast<Impl*>(JS_GetContextOpaque(ctx));
        if (argc >= 2 && self->logLines.size() < kMaxLogLines) {
            const char* level = JS_ToCString(ctx, argv[0]);
            const char* text = JS_ToCString(ctx, argv[1]);
            if (level && text) self->logLines.push_back(std::string(level) + ": " + text);
            if (level) JS_FreeCString(ctx, level);
            if (text) JS_FreeCString(ctx, text);
        }
        return JS_UNDEFINED;
    }

    void arm() {
        deadline = std::chrono::steady_clock::now() + std::chrono::microseconds(std::int64_t(limits.seconds * 1e6));
        timedOut = false;
        JS_UpdateStackTop(rt);
    }

    static std::string get_string(JSContext* ctx, JSValueConst obj, const char* prop) {
        JSValue v = JS_GetPropertyStr(ctx, obj, prop);
        std::string out;
        if (!JS_IsUndefined(v) && !JS_IsNull(v))
            if (const char* s = JS_ToCString(ctx, v)) {
                out = s;
                JS_FreeCString(ctx, s);
            }
        JS_FreeValue(ctx, v);
        return out;
    }

    // The exception in flight: its message, and the first frame of the stack that is in one of the project's modules.
    JsError take_exception() {
        JsError e;
        JSValue ex = JS_GetException(ctx);
        if (JS_IsObject(ex)) {
            e.name = get_string(ctx, ex, "name");
            e.message = get_string(ctx, ex, "message");
            e.stack = get_string(ctx, ex, "stack");
            std::size_t pos = 0;
            while (pos < e.stack.size() && e.file.empty()) {
                std::size_t eol = e.stack.find('\n', pos);
                std::string ln = e.stack.substr(pos, eol == std::string::npos ? std::string::npos : eol - pos);
                pos = eol == std::string::npos ? e.stack.size() : eol + 1;
                const std::size_t at = ln.find("at ");
                if (at == std::string::npos) continue;
                std::string rest = ln.substr(at + 3);
                const std::size_t lp = rest.rfind('(');
                if (lp != std::string::npos) rest = rest.substr(lp + 1, rest.rfind(')') == std::string::npos ? std::string::npos : rest.rfind(')') - lp - 1);
                const std::size_t c2 = rest.rfind(':');
                if (c2 == std::string::npos || c2 == 0) continue;
                const std::size_t c1 = rest.rfind(':', c2 - 1);
                std::string file = c1 == std::string::npos ? rest.substr(0, c2) : rest.substr(0, c1);
                if (!fileSet.count(file)) continue;
                e.file = file;
                e.line = std::atoi(rest.substr(c1 == std::string::npos ? c2 + 1 : c1 + 1).c_str());
                if (c1 != std::string::npos) {
                    e.line = std::atoi(rest.substr(c1 + 1, c2 - c1 - 1).c_str());
                    e.column = std::atoi(rest.substr(c2 + 1).c_str());
                }
            }
            if (e.file.empty()) {
                const std::string file = get_string(ctx, ex, "fileName");
                if (fileSet.count(file)) {
                    e.file = file;
                    e.line = std::atoi(get_string(ctx, ex, "lineNumber").c_str());
                    e.column = std::atoi(get_string(ctx, ex, "columnNumber").c_str());
                }
            }
        } else if (const char* s = JS_ToCString(ctx, ex)) {
            e.name = "Error";
            e.message = std::string("threw ") + s;
            JS_FreeCString(ctx, s);
        }
        JS_FreeValue(ctx, ex);
        return e;
    }

    // "art/coin.anim.js:12:7: TypeError: x is not a function (<doing>)", with the source line and a caret.
    [[noreturn]] void raise(const JsError& e, const std::string& doing) {
        std::string file = e.file.empty() ? moduleRel : e.file;
        std::string msg = file;
        if (e.line > 0) msg += ":" + std::to_string(e.line) + (e.column > 0 ? ":" + std::to_string(e.column) : "");
        std::string what = e.message;
        if (!e.name.empty() && e.name != "Error") what = e.message.empty() ? e.name : e.name + ": " + e.message;
        std::string hint = "Fix the line named; the module sees only the JavaScript language and the argument {t, frame, frames, fps, progress, params, rng}.";
        if (timedOut) {
            what = std::format("took longer than {} s (an endless loop, or too much work for one frame)", limits.seconds);
            hint = "Look for a loop that never ends; or raise `timeLimitMs` if the frame really needs the time. Frames are drawn one after another, so a slow frame is slow for all of them.";
        } else if (e.message.find("out of memory") != std::string::npos) {
            what = std::format("ran out of memory (the limit is {} MB for the whole module)", limits.memoryBytes / (1024 * 1024));
            hint = "Do not build huge arrays or strings; draw fewer shapes per frame.";
        } else if (e.name == "ReferenceError" && e.message.find("is not defined") != std::string::npos) {
            hint = "An animation module has no engine bindings, no DOM, no Node and no timers: only the language itself (Math, JSON, Array...). Take data from `params` and the frame argument, and import helpers from project files with a relative path.";
        } else if (e.name == "RangeError" && e.message.find("call stack") != std::string::npos) {
            hint = "A function calls itself without end: check the recursion.";
        }
        msg += ": " + what;
        if (!doing.empty()) msg += " (" + doing + ")";
        if (e.line > 0) {
            auto src = tooling_detail::read_file(project_file(projectDir, file));
            if (src) {
                std::size_t start = 0;
                for (int ln = 1; ln < e.line && start != std::string::npos; ++ln) {
                    start = src->find('\n', start);
                    if (start != std::string::npos) ++start;
                }
                if (start != std::string::npos) {
                    std::size_t end = src->find('\n', start);
                    std::string text = src->substr(start, end == std::string::npos ? std::string::npos : end - start);
                    if (!text.empty() && text.back() == '\r') text.pop_back();
                    if (text.size() > 160) text = text.substr(0, 160) + "...";
                    msg += "\n  " + text;
                    if (e.column > 0) {
                        std::string pad;
                        for (int i = 0; i + 1 < e.column && i < int(text.size()); ++i) pad += text[i] == '\t' ? '\t' : ' ';
                        msg += "\n  " + pad + "^";
                    }
                }
            }
        }
        fail("script_error", msg, hint);
    }
};

AnimModule::AnimModule(std::unique_ptr<Impl> impl) : impl_(std::move(impl)) {}
AnimModule::~AnimModule() = default;
const std::vector<std::string>& AnimModule::files() const { return impl_->files; }
const std::vector<std::string>& AnimModule::logs() const { return impl_->logLines; }

std::unique_ptr<AnimModule> AnimModule::load(const std::string& projectDir, const std::string& moduleRel, const Limits& limits) {
    auto impl = std::make_unique<Impl>();
    Impl& I = *impl;
    I.projectDir = projectDir;
    I.moduleRel = moduleRel;
    I.limits = limits;
    I.rt = JS_NewRuntime();
    if (!I.rt) fail("failed", "The JavaScript runtime could not be created.");
    JS_SetMemoryLimit(I.rt, limits.memoryBytes);
    JS_SetMaxStackSize(I.rt, limits.stackBytes);
    JS_SetInterruptHandler(I.rt, Impl::interrupt, &I);
    JS_SetModuleLoaderFunc(I.rt, Impl::normalize, Impl::loader, &I);
    I.ctx = JS_NewContext(I.rt);
    if (!I.ctx) fail("failed", "The JavaScript context could not be created.");
    JS_SetContextOpaque(I.ctx, &I);

    // the prelude: deterministic Math.random and Date, console, rng
    I.arm();
    JSValue prelude = JS_Eval(I.ctx, kPrelude, std::strlen(kPrelude), "<animate_svg prelude>", JS_EVAL_TYPE_GLOBAL);
    if (JS_IsException(prelude)) {
        const JsError e = I.take_exception();
        fail("failed", "The sandbox of assets.animate_svg could not start: " + e.message);
    }
    JSValue native = JS_NewObject(I.ctx);
    JS_SetPropertyStr(I.ctx, native, "log", JS_NewCFunction(I.ctx, Impl::native_log, "log", 2));
    I.hooks = JS_Call(I.ctx, prelude, JS_UNDEFINED, 1, &native);
    JS_FreeValue(I.ctx, native);
    JS_FreeValue(I.ctx, prelude);
    if (JS_IsException(I.hooks)) {
        const JsError e = I.take_exception();
        I.hooks = JS_UNDEFINED;
        fail("failed", "The sandbox of assets.animate_svg could not start: " + e.message);
    }

    // the module
    const std::string doing = "while loading the module";
    I.arm();
    JSModuleDef* def = I.compile(moduleRel);
    if (!def) I.raise(I.take_exception(), doing);
    // compile() freed the function value (the module stays alive in the context); evaluate it through a tiny importer
    const std::string importer = "import * as m from " + Json("/" + moduleRel).dump() + "; globalThis.__animModule = m;";
    JSValue evaluated = JS_Eval(I.ctx, importer.c_str(), importer.size(), "<animate_svg>", JS_EVAL_TYPE_MODULE);
    if (JS_IsException(evaluated)) I.raise(I.take_exception(), doing);
    if (JS_PromiseState(I.ctx, evaluated) != JS_PROMISE_NOT_A_PROMISE) {
        JSContext* jobCtx = nullptr;
        while (JS_IsJobPending(I.rt)) {
            if (JS_ExecutePendingJob(I.rt, &jobCtx) < 0) break;
        }
        const auto state = JS_PromiseState(I.ctx, evaluated);
        if (state == JS_PROMISE_REJECTED) {
            JSValue reason = JS_PromiseResult(I.ctx, evaluated);
            JS_Throw(I.ctx, reason);
            JS_FreeValue(I.ctx, evaluated);
            I.raise(I.take_exception(), doing);
        }
        if (state == JS_PROMISE_PENDING) {
            JS_FreeValue(I.ctx, evaluated);
            fail("script_error", moduleRel + ": the module uses top-level await on something that never settles.", "Draw synchronously: `frame` must return the SVG string.");
        }
    }
    JS_FreeValue(I.ctx, evaluated);
    JSValue global = JS_GetGlobalObject(I.ctx);
    JSValue ns = JS_GetPropertyStr(I.ctx, global, "__animModule");
    JS_FreeValue(I.ctx, global);
    if (!JS_IsObject(ns)) {
        JS_FreeValue(I.ctx, ns);
        fail("script_error", moduleRel + ": the module did not produce exports.", "Use `export default function frame({t, frame, frames, params, rng}) { return \"<svg ...>\"; }`.");
    }
    JSValue def_export = JS_GetPropertyStr(I.ctx, ns, "default");
    if (!JS_IsFunction(I.ctx, def_export)) {
        JS_FreeValue(I.ctx, def_export);
        def_export = JS_GetPropertyStr(I.ctx, ns, "frame");
    }
    if (!JS_IsFunction(I.ctx, def_export)) {
        std::vector<std::string> names;
        JSPropertyEnum* tab = nullptr;
        uint32_t n = 0;
        if (JS_GetOwnPropertyNames(I.ctx, &tab, &n, ns, JS_GPN_STRING_MASK | JS_GPN_ENUM_ONLY) == 0) {
            for (uint32_t i = 0; i < n; ++i)
                if (const char* k = JS_AtomToCString(I.ctx, tab[i].atom)) {
                    names.push_back(k);
                    JS_FreeCString(I.ctx, k);
                }
            JS_FreePropertyEnum(I.ctx, tab, n);
        }
        JS_FreeValue(I.ctx, def_export);
        JS_FreeValue(I.ctx, ns);
        fail("script_error",
             moduleRel + ": the module has no default export that is a function" + (names.empty() ? " (it exports nothing)" : " (it exports: " + join(names, ", ") + ")") + ".",
             "Write `export default function frame({t, frame, frames, fps, progress, params, rng}) { return \"<svg ...>...</svg>\"; }`.");
    }
    JS_FreeValue(I.ctx, ns);
    I.fn = def_export;
    (void)def;
    return std::unique_ptr<AnimModule>(new AnimModule(std::move(impl)));
}

std::string AnimModule::draw(const AnimFrame& f) {
    Impl& I = *impl_;
    const std::string doing = std::format("while drawing frame {} of {}{}, t = {:.4g} s", f.frame, f.frames,
                                          f.clip.empty() ? std::string() : ", clip \"" + f.clip + "\"", f.t);
    Json args = Json::object({{"t", f.t}, {"frame", f.frame}, {"frames", f.frames}, {"fps", f.fps}, {"progress", f.progress},
                              {"sheetFrame", f.sheetFrame}, {"seed", f.baseSeed}, {"width", f.width}, {"height", f.height}, {"params", f.params}});
    if (!f.clip.empty()) args["clip"] = f.clip;
    const std::string text = args.dump();
    I.arm();
    JSValue arg = JS_ParseJSON(I.ctx, text.c_str(), text.size(), "<frame argument>");
    if (JS_IsException(arg)) I.raise(I.take_exception(), doing);
    JSValue callArgs[4] = {JS_DupValue(I.ctx, I.fn), arg, JS_NewUint32(I.ctx, f.seed), JS_NewFloat64(I.ctx, f.t * 1000.0)};
    JSValue run = JS_GetPropertyStr(I.ctx, I.hooks, "run");
    JSValue result = JS_Call(I.ctx, run, I.hooks, 4, callArgs);
    JS_FreeValue(I.ctx, run);
    for (JSValue& v : callArgs) JS_FreeValue(I.ctx, v);
    if (JS_IsException(result)) I.raise(I.take_exception(), doing);
    if (!JS_IsString(result)) {
        const char* kind = JS_IsUndefined(result) ? "undefined" : JS_IsNull(result) ? "null" : JS_IsObject(result) ? "an object" : "a non-string value";
        JS_FreeValue(I.ctx, result);
        fail("script_error", std::format("{}: `frame` returned {} instead of an SVG string ({}).", I.moduleRel, kind, doing),
             "Return the SVG text: `return `<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\">...</svg>`;` (a missing return is the usual cause).");
    }
    std::size_t len = 0;
    const char* s = JS_ToCStringLen(I.ctx, &len, result);
    std::string svg = s ? std::string(s, len) : std::string();
    if (s) JS_FreeCString(I.ctx, s);
    JS_FreeValue(I.ctx, result);
    return svg;
}

}  // namespace fa::assets_detail
