#include "fa/tooling/script_instrument.h"

#include <quickjs.h>

#include <mutex>

#include "fa/core/json.h"
#include "fa/tooling/bundle.h"

namespace fa {
namespace {

// The runtime that runs acorn and instrument.js. Created on first use, kept for the life of the process.
struct InstrumentRuntime {
    JSRuntime* rt = nullptr;
    JSContext* ctx = nullptr;
    JSValue fn = JS_UNDEFINED;
    std::string failure;  // why it could not be created (every call then fails with this)

    InstrumentRuntime() {
        auto acorn = bundled_read("external/acorn/dist/acorn.js");
        auto script = bundled_read("tools/common/src/js/instrument.js");
        if (!acorn || !script) {
            failure = "the script instrumenter's JavaScript (external/acorn/dist/acorn.js, tools/common/src/js/instrument.js) "
                      "is not bundled in this build";
            return;
        }
        rt = JS_NewRuntime();
        // QuickJS default size; deeply nested sources fail with an error instead of crashing. Callers on threads with a
        // smaller stack than this (the DAP reader thread) must create them with at least 1 MB.
        JS_SetMaxStackSize(rt, 1024 * 1024);
        ctx = JS_NewContext(rt);
        if (!run("external/acorn/dist/acorn.js", *acorn) || !run("tools/common/src/js/instrument.js", *script)) return;
        JSValue global = JS_GetGlobalObject(ctx);
        fn = JS_GetPropertyStr(ctx, global, "__faInstrument");
        JS_FreeValue(ctx, global);
        if (!JS_IsFunction(ctx, fn)) failure = "instrument.js did not define __faInstrument";
    }

    ~InstrumentRuntime() {
        if (ctx) {
            JS_FreeValue(ctx, fn);
            JS_FreeContext(ctx);
        }
        if (rt) JS_FreeRuntime(rt);
    }

    bool run(const char* name, const std::string& code) {
        JSValue v = JS_Eval(ctx, code.c_str(), code.size(), name, JS_EVAL_TYPE_GLOBAL);
        if (JS_IsException(v)) {
            failure = std::string("loading ") + name + " failed: " + take_exception();
            return false;
        }
        JS_FreeValue(ctx, v);
        return true;
    }

    std::string take_exception() {
        JSValue ex = JS_GetException(ctx);
        std::string text;
        if (const char* s = JS_ToCString(ctx, ex)) {
            text = s;
            JS_FreeCString(ctx, s);
        }
        JSValue stack = JS_GetPropertyStr(ctx, ex, "stack");
        if (JS_IsString(stack))
            if (const char* s = JS_ToCString(ctx, stack)) {
                text += std::string("\n") + s;
                JS_FreeCString(ctx, s);
            }
        JS_FreeValue(ctx, stack);
        JS_FreeValue(ctx, ex);
        return text;
    }
};

std::mutex g_mutex;

}  // namespace

Result<InstrumentedScript> instrument_script(const std::string& file, std::string_view source, int moduleId) {
    std::string json;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        static InstrumentRuntime* runtime = new InstrumentRuntime();  // never destroyed: threads may still call at exit
        if (!runtime->failure.empty()) return Error{"cannot instrument " + file + ": " + runtime->failure, ""};
        JSContext* ctx = runtime->ctx;
        JS_UpdateStackTop(runtime->rt);  // the calling thread changes between calls
        JSValue args[3] = {JS_NewString(ctx, file.c_str()), JS_NewStringLen(ctx, source.data(), source.size()),
                           JS_NewInt32(ctx, moduleId)};
        JSValue res = JS_Call(ctx, runtime->fn, JS_UNDEFINED, 3, args);
        for (JSValue& a : args) JS_FreeValue(ctx, a);
        if (JS_IsException(res)) {
            std::string why = runtime->take_exception();
            return Error{file + ": the script instrumenter failed: " + why,
                         "A very deeply nested expression can overflow its stack; the module is compiled as written."};
        }
        size_t len = 0;
        if (const char* s = JS_ToCStringLen(ctx, &len, res)) {
            json.assign(s, len);
            JS_FreeCString(ctx, s);
        }
        JS_FreeValue(ctx, res);
    }

    Json j = Json::parse(json, nullptr, false);
    if (j.is_discarded()) return Error{file + ": the script instrumenter returned unreadable output", ""};
    if (j.contains("error")) {
        const Json& e = j["error"];
        return Error{file + ":" + std::to_string(e.value("line", 1)) + ":" + std::to_string(e.value("column", 1)) + ": " +
                         e.value("message", std::string("syntax error")),
                     "Fix the syntax error; the module is compiled as written so QuickJS reports it too."};
    }

    InstrumentedScript out;
    out.code = j.value("code", std::string());
    const Json& info = j["info"];
    ScriptDebugInfo& d = out.info;
    for (const Json& s : info["statements"])
        d.statements.push_back({s.value("line", 0), s.value("column", 0), s.value("scope", 0)});
    for (const Json& f : info["functions"])
        d.functions.push_back({f.value("name", std::string()), f.value("line", 0), f.value("column", 0),
                               f.value("endLine", 0), f.value("scope", 0)});
    for (const Json& s : info["scopes"]) {
        ScriptDebugInfo::Scope sc;
        sc.parent = s.value("parent", -1);
        sc.kind = s.value("kind", std::string());
        for (const Json& n : s["names"]) sc.names.push_back(n.get<std::string>());
        d.scopes.push_back(std::move(sc));
    }
    for (const Json& s : info["shifts"]) d.shifts.push_back({s.value("line", 0), s.value("column", 0), s.value("length", 0)});
    return out;
}

ScriptInstrumenter script_instrumenter() {
    return [](const std::string& file, std::string_view source, int moduleId) {
        return instrument_script(file, source, moduleId);
    };
}

}  // namespace fa
