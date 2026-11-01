// JavaScript hooks. See hook_js.h.
#include "fa/ai/hook_js.h"

#include <quickjs.h>

#include <chrono>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <set>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "util.h"

namespace fa::ai {

namespace fsys = std::filesystem;

namespace {

constexpr std::size_t kMemoryLimit = std::size_t(64) * 1024 * 1024;
constexpr std::size_t kStackLimit = std::size_t(256) * 1024;
constexpr std::size_t kMaxLogLines = 100;

// console, and the Array.prototype.find family without the interrupt poll that QuickJS-ng's own has (a use after free when the time
// limit stops a script inside find(); engine/script/src/quickjs_fixes.cpp).
constexpr const char* kPrelude = R"JS((function (native) {
  "use strict";
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
  const show = (v) => { if (typeof v === "string") return v; try { return JSON.stringify(v); } catch (e) { return String(v); } };
  const logger = (level) => (...args) => native.log(level, args.map(show).join(" "));
  Object.defineProperty(globalThis, "console", { value: { log: logger("log"), info: logger("log"), debug: logger("log"), warn: logger("warn"), error: logger("error") }, writable: true, configurable: true });
  return {
    call(fn, input) { return fn(input); },
  };
}))JS";

struct JsError {
    std::string name, message, stack, file;
    int line = 0, column = 0;
};

struct Runtime {
    std::string projectDir, moduleRel;
    double seconds = 5;
    JSRuntime* rt = nullptr;
    JSContext* ctx = nullptr;
    JSValue helper = JS_UNDEFINED;
    std::chrono::steady_clock::time_point deadline;
    bool timedOut = false;
    std::set<std::string> files;
    std::vector<std::string> logs;
    std::string loaderError;

    ~Runtime() {
        if (ctx) {
            JS_FreeValue(ctx, helper);
            JS_FreeContext(ctx);
        }
        if (rt) JS_FreeRuntime(rt);
    }

    static int interrupt(JSRuntime*, void* opaque) {
        auto* self = static_cast<Runtime*>(opaque);
        if (std::chrono::steady_clock::now() > self->deadline) {
            self->timedOut = true;
            return 1;
        }
        return 0;
    }

    void arm() {
        deadline = std::chrono::steady_clock::now() + std::chrono::microseconds(std::int64_t(seconds * 1e6));
        timedOut = false;
        JS_UpdateStackTop(rt);
    }

    static char* normalize(JSContext* ctx, const char* base, const char* name, void* opaque) {
        auto* self = static_cast<Runtime*>(opaque);
        const std::string spec = name;
        std::string joined;
        if (spec.rfind("./", 0) == 0 || spec.rfind("../", 0) == 0) {
            const std::string b = base ? base : "";
            const std::size_t slash = b.rfind('/');
            joined = (slash == std::string::npos ? std::string() : b.substr(0, slash + 1)) + spec;
        } else if (!spec.empty() && spec[0] == '/') {
            joined = spec.substr(1);
        } else {
            JS_ThrowReferenceError(ctx, "cannot import '%s' from %s: a hook module has no packages and no engine modules; import project files with a relative path such as './helpers.js'",
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
        auto* self = static_cast<Runtime*>(opaque);
        const std::string rel = name;
        std::ifstream in(fsys::path(self->projectDir) / rel, std::ios::binary);
        if (!in) {
            JS_ThrowReferenceError(ctx, "cannot load module '%s': the file does not exist or cannot be read", rel.c_str());
            return nullptr;
        }
        std::string text((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
        self->files.insert(rel);
        JSValue func = JS_Eval(ctx, text.c_str(), text.size(), rel.c_str(), JS_EVAL_TYPE_MODULE | JS_EVAL_FLAG_COMPILE_ONLY);
        if (JS_IsException(func)) return nullptr;
        auto* def = static_cast<JSModuleDef*>(JS_VALUE_GET_PTR(func));
        JS_FreeValue(ctx, func);
        return def;
    }

    static JSValue native_log(JSContext* ctx, JSValueConst, int argc, JSValueConst* argv) {
        auto* self = static_cast<Runtime*>(JS_GetContextOpaque(ctx));
        if (argc >= 2 && self->logs.size() < kMaxLogLines) {
            const char* level = JS_ToCString(ctx, argv[0]);
            const char* text = JS_ToCString(ctx, argv[1]);
            if (level && text) self->logs.push_back(std::string(level) + ": " + text);
            if (level) JS_FreeCString(ctx, level);
            if (text) JS_FreeCString(ctx, text);
        }
        return JS_UNDEFINED;
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

    JsError take_exception() {
        JsError e;
        JSValue ex = JS_GetException(ctx);
        if (JS_IsObject(ex)) {
            e.name = get_string(ctx, ex, "name");
            e.message = get_string(ctx, ex, "message");
            e.stack = get_string(ctx, ex, "stack");
            std::size_t pos = 0;
            while (pos < e.stack.size() && e.file.empty()) {
                const std::size_t eol = e.stack.find('\n', pos);
                const std::string ln = e.stack.substr(pos, eol == std::string::npos ? std::string::npos : eol - pos);
                pos = eol == std::string::npos ? e.stack.size() : eol + 1;
                const std::size_t at = ln.find("at ");
                if (at == std::string::npos) continue;
                std::string rest = ln.substr(at + 3);
                const std::size_t lp = rest.rfind('(');
                if (lp != std::string::npos) rest = rest.substr(lp + 1, rest.rfind(')') == std::string::npos ? std::string::npos : rest.rfind(')') - lp - 1);
                const std::size_t c2 = rest.rfind(':');
                if (c2 == std::string::npos || c2 == 0) continue;
                const std::size_t c1 = rest.rfind(':', c2 - 1);
                const std::string file = c1 == std::string::npos ? rest.substr(0, c2) : rest.substr(0, c1);
                if (!files.count(file)) continue;
                e.file = file;
                if (c1 != std::string::npos) {
                    e.line = std::atoi(rest.substr(c1 + 1, c2 - c1 - 1).c_str());
                    e.column = std::atoi(rest.substr(c2 + 1).c_str());
                } else {
                    e.line = std::atoi(rest.substr(c2 + 1).c_str());
                }
            }
            if (e.file.empty()) {
                const std::string file = get_string(ctx, ex, "fileName");
                if (files.count(file)) {
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

    std::string describe(const JsError& e, const std::string& doing) const {
        std::string msg = e.file.empty() ? moduleRel : e.file;
        if (e.line > 0) msg += ":" + std::to_string(e.line) + (e.column > 0 ? ":" + std::to_string(e.column) : "");
        std::string what = e.message;
        if (!e.name.empty() && e.name != "Error") what = e.message.empty() ? e.name : e.name + ": " + e.message;
        std::string hint;
        if (timedOut) {
            what = "took longer than " + std::to_string(int(seconds)) + " s (an endless loop, or too much work)";
            hint = "Look for a loop that never ends, or give the hook a longer \"timeout\".";
        } else if (e.message.find("out of memory") != std::string::npos) {
            what = "ran out of memory (the limit is " + std::to_string(kMemoryLimit / (1024 * 1024)) + " MB)";
            hint = "Do not build huge arrays or strings.";
        } else if (e.name == "ReferenceError" && e.message.find("is not defined") != std::string::npos) {
            hint = "A hook module sees only the language itself (Math, JSON, Array...) and console: no engine bindings, files, network or timers. Take everything from the `input` argument.";
        } else {
            hint = "Fix the line named; the module sees only the language and console, and gets the event's JSON as its argument.";
        }
        msg += ": " + what + " (" + doing + "). " + hint;
        return msg;
    }
};

std::string names_of(JSContext* ctx, JSValueConst obj) {
    std::string out;
    JSPropertyEnum* tab = nullptr;
    uint32_t n = 0;
    if (JS_GetOwnPropertyNames(ctx, &tab, &n, obj, JS_GPN_STRING_MASK | JS_GPN_ENUM_ONLY) == 0) {
        for (uint32_t i = 0; i < n; ++i)
            if (const char* k = JS_AtomToCString(ctx, tab[i].atom)) {
                out += (out.empty() ? "" : ", ") + std::string(k);
                JS_FreeCString(ctx, k);
            }
        JS_FreePropertyEnum(ctx, tab, n);
    }
    return out;
}

}  // namespace

JsHookResult run_js_hook(const std::string& projectDir, const std::string& moduleRel, HookEvent event, const Json& input,
                         double timeoutSeconds) {
    JsHookResult res;
    auto fail = [&](std::string message) {
        res.ok = false;
        res.error = std::move(message);
        return res;
    };
    if (const std::string problem = hook_module_problem(moduleRel); !problem.empty()) return fail(problem);
    {
        std::error_code ec;
        if (!fsys::is_regular_file(fsys::path(projectDir) / moduleRel, ec)) {
            return fail(moduleRel + " does not exist in the project. Create it, or fix \"module\" in the hook; the module is a file in the hooks/ folder, for example hooks/guard.js.");
        }
    }
    Runtime R;
    R.projectDir = projectDir;
    R.moduleRel = moduleRel;
    R.seconds = timeoutSeconds > 0 ? timeoutSeconds : kDefaultHookTimeoutSeconds;
    R.rt = JS_NewRuntime();
    if (!R.rt) return fail("The JavaScript runtime for the hook could not be created.");
    JS_SetMemoryLimit(R.rt, kMemoryLimit);
    JS_SetMaxStackSize(R.rt, kStackLimit);
    JS_SetInterruptHandler(R.rt, Runtime::interrupt, &R);
    JS_SetModuleLoaderFunc(R.rt, Runtime::normalize, Runtime::loader, &R);
    R.ctx = JS_NewContext(R.rt);
    if (!R.ctx) return fail("The JavaScript context for the hook could not be created.");
    JS_SetContextOpaque(R.ctx, &R);
    R.arm();

    JSValue prelude = JS_Eval(R.ctx, kPrelude, std::strlen(kPrelude), "<hook prelude>", JS_EVAL_TYPE_GLOBAL);
    if (JS_IsException(prelude)) return fail("The sandbox of JavaScript hooks could not start: " + R.take_exception().message);
    JSValue native = JS_NewObject(R.ctx);
    JS_SetPropertyStr(R.ctx, native, "log", JS_NewCFunction(R.ctx, Runtime::native_log, "log", 2));
    R.helper = JS_Call(R.ctx, prelude, JS_UNDEFINED, 1, &native);
    JS_FreeValue(R.ctx, native);
    JS_FreeValue(R.ctx, prelude);
    if (JS_IsException(R.helper)) {
        R.helper = JS_UNDEFINED;
        return fail("The sandbox of JavaScript hooks could not start: " + R.take_exception().message);
    }

    const std::string doingLoad = "while loading the module";
    const std::string importer = "import * as m from " + Json("/" + moduleRel).dump() + "; globalThis.__hookModule = m;";
    JSValue evaluated = JS_Eval(R.ctx, importer.c_str(), importer.size(), "<hook>", JS_EVAL_TYPE_MODULE);
    if (JS_IsException(evaluated)) {
        std::string msg = R.describe(R.take_exception(), doingLoad);
        res.timedOut = R.timedOut;
        res.logs = R.logs;
        return fail(msg);
    }
    if (JS_PromiseState(R.ctx, evaluated) != JS_PROMISE_NOT_A_PROMISE) {
        JSContext* jobCtx = nullptr;
        while (JS_IsJobPending(R.rt)) {
            if (JS_ExecutePendingJob(R.rt, &jobCtx) < 0) break;
        }
        const auto state = JS_PromiseState(R.ctx, evaluated);
        if (state == JS_PROMISE_REJECTED) {
            JSValue reason = JS_PromiseResult(R.ctx, evaluated);
            JS_Throw(R.ctx, reason);
            JS_FreeValue(R.ctx, evaluated);
            std::string msg = R.describe(R.take_exception(), doingLoad);
            res.timedOut = R.timedOut;
            return fail(msg);
        }
        if (state == JS_PROMISE_PENDING) {
            JS_FreeValue(R.ctx, evaluated);
            return fail(moduleRel + ": the module uses top-level await on something that never settles. A hook answers synchronously.");
        }
    }
    JS_FreeValue(R.ctx, evaluated);

    JSValue global = JS_GetGlobalObject(R.ctx);
    JSValue ns = JS_GetPropertyStr(R.ctx, global, "__hookModule");
    JS_FreeValue(R.ctx, global);
    if (!JS_IsObject(ns)) {
        JS_FreeValue(R.ctx, ns);
        return fail(moduleRel + ": the module did not produce exports. Use `export default function (input) { ... }`.");
    }
    const char* eventName = hook_event_name(event);
    // The function for this event: a named export (`export function PreToolUse(input)`), the same name on the default export
    // (`export default { PreToolUse(input) {} }`), or a default export that is a function (called for every event it is given).
    JSValue fn = JS_GetPropertyStr(R.ctx, ns, eventName);
    JSValue defaultExport = JS_GetPropertyStr(R.ctx, ns, "default");
    if (!JS_IsFunction(R.ctx, fn)) {
        JS_FreeValue(R.ctx, fn);
        fn = JS_UNDEFINED;
        if (JS_IsFunction(R.ctx, defaultExport)) {
            fn = JS_DupValue(R.ctx, defaultExport);
        } else if (JS_IsObject(defaultExport)) {
            fn = JS_GetPropertyStr(R.ctx, defaultExport, eventName);
            if (!JS_IsFunction(R.ctx, fn)) {
                JS_FreeValue(R.ctx, fn);
                fn = JS_UNDEFINED;
            }
        }
    }
    if (!JS_IsFunction(R.ctx, fn)) {
        std::string exported = names_of(R.ctx, ns);
        if (JS_IsObject(defaultExport) && !JS_IsFunction(R.ctx, defaultExport)) {
            const std::string inner = names_of(R.ctx, defaultExport);
            if (!inner.empty()) exported += (exported.empty() ? "" : "; ") + std::string("default has: ") + inner;
        }
        JS_FreeValue(R.ctx, fn);
        JS_FreeValue(R.ctx, defaultExport);
        JS_FreeValue(R.ctx, ns);
        res.handled = false;
        res.logs = R.logs;
        return fail(moduleRel + " has no function for " + eventName + " (it exports: " + (exported.empty() ? "nothing" : exported) +
                    "). Export `default function (input) {...}` for every event it is given, or `export default { " + eventName +
                    "(input) {...} }`.");
    }
    JS_FreeValue(R.ctx, defaultExport);
    JS_FreeValue(R.ctx, ns);

    const std::string text = util::dump(input);
    R.arm();
    JSValue arg = JS_ParseJSON(R.ctx, text.c_str(), text.size(), "<hook input>");
    if (JS_IsException(arg)) {
        JS_FreeValue(R.ctx, fn);
        return fail(R.describe(R.take_exception(), "while reading the event"));
    }
    JSValue callArgs[2] = {fn, arg};
    JSValue call = JS_GetPropertyStr(R.ctx, R.helper, "call");
    JSValue result = JS_Call(R.ctx, call, R.helper, 2, callArgs);
    JS_FreeValue(R.ctx, call);
    JS_FreeValue(R.ctx, fn);
    JS_FreeValue(R.ctx, arg);
    // An async function: settle what it awaited (nothing outside the module can resolve, so only plain awaits finish).
    if (!JS_IsException(result) && JS_PromiseState(R.ctx, result) != JS_PROMISE_NOT_A_PROMISE) {
        JSContext* jobCtx = nullptr;
        while (JS_IsJobPending(R.rt)) {
            if (JS_ExecutePendingJob(R.rt, &jobCtx) < 0) break;
        }
        const auto state = JS_PromiseState(R.ctx, result);
        if (state == JS_PROMISE_PENDING) {
            JS_FreeValue(R.ctx, result);
            return fail(moduleRel + ": the " + eventName + " function awaits something that never settles. A hook has no timers and no network: answer synchronously.");
        }
        JSValue inner = JS_PromiseResult(R.ctx, result);
        const bool rejected = state == JS_PROMISE_REJECTED;
        JS_FreeValue(R.ctx, result);
        if (rejected) {
            JS_Throw(R.ctx, inner);
            result = JS_EXCEPTION;
        } else {
            result = inner;
        }
    }
    res.logs = R.logs;
    if (JS_IsException(result)) {
        const std::string msg = R.describe(R.take_exception(), "in the " + std::string(eventName) + " hook");
        res.timedOut = R.timedOut;
        res.logs = R.logs;
        return fail(msg);
    }
    if (JS_IsUndefined(result) || JS_IsNull(result)) {
        res.value = Json();
    } else if (JS_IsString(result)) {
        std::size_t len = 0;
        const char* s = JS_ToCStringLen(R.ctx, &len, result);
        res.value = s ? Json(std::string(s, len)) : Json();
        if (s) JS_FreeCString(R.ctx, s);
    } else {
        JSValue json = JS_JSONStringify(R.ctx, result, JS_UNDEFINED, JS_UNDEFINED);
        if (JS_IsException(json)) {
            const std::string msg = R.describe(R.take_exception(), "while reading what the hook returned");
            JS_FreeValue(R.ctx, result);
            return fail(msg);
        }
        std::size_t len = 0;
        const char* s = JS_IsString(json) ? JS_ToCStringLen(R.ctx, &len, json) : nullptr;
        res.value = s ? util::parse(std::string_view(s, len)) : Json();
        if (res.value.is_discarded()) res.value = Json();
        if (s) JS_FreeCString(R.ctx, s);
        JS_FreeValue(R.ctx, json);
    }
    JS_FreeValue(R.ctx, result);
    res.logs = R.logs;
    return res;
}

}  // namespace fa::ai
