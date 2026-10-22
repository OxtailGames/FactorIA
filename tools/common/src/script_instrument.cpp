#include "fa/tooling/script_instrument.h"

#include <quickjs.h>

#include <condition_variable>
#include <deque>
#include <mutex>

#include "fa/core/json.h"
#include "fa/tooling/bundle.h"
#include "script_instrument_thread.h"

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

// One worker thread owns the runtime and does all QuickJS work, so callers need no particular stack size. It is created on
// first use with an explicit big stack, never joined, and the state below is leaked so process exit never waits for it.
struct Job {
    const std::string* file;
    std::string_view source;
    int moduleId;
    bool done = false;
    bool failed = false;
    std::string result;  // the JSON, or the error text when failed
};

struct Worker {
    std::mutex mutex;
    std::condition_variable wake;      // a job was queued
    std::condition_variable finished;  // a job completed
    std::deque<Job*> queue;
    bool started = false;
    std::string startFailure;
};

Worker& worker() {
    static Worker* w = new Worker();
    return *w;
}

constexpr std::size_t kWorkerStack = 8u * 1024 * 1024;
constexpr std::size_t kJsStack = 4u * 1024 * 1024;

void run_job(InstrumentRuntime& runtime, Job& job) {
    if (!runtime.failure.empty()) {
        job.failed = true;
        job.result = runtime.failure;
        return;
    }
    JSContext* ctx = runtime.ctx;
    JSValue args[3] = {JS_NewString(ctx, job.file->c_str()), JS_NewStringLen(ctx, job.source.data(), job.source.size()),
                       JS_NewInt32(ctx, job.moduleId)};
    JSValue res = JS_Call(ctx, runtime.fn, JS_UNDEFINED, 3, args);
    for (JSValue& a : args) JS_FreeValue(ctx, a);
    if (JS_IsException(res)) {
        job.failed = true;
        job.result = runtime.take_exception();
        return;
    }
    size_t len = 0;
    if (const char* s = JS_ToCStringLen(ctx, &len, res)) {
        job.result.assign(s, len);
        JS_FreeCString(ctx, s);
    }
    JS_FreeValue(ctx, res);
}

void worker_main(void*) {
    Worker& w = worker();
    auto* runtime = new InstrumentRuntime();  // leaked with the thread
    if (runtime->rt) {
        JS_UpdateStackTop(runtime->rt);  // once: this thread never changes
        JS_SetMaxStackSize(runtime->rt, kJsStack);
    }
    for (;;) {
        Job* job;
        {
            std::unique_lock<std::mutex> lock(w.mutex);
            w.wake.wait(lock, [&] { return !w.queue.empty(); });
            job = w.queue.front();
            w.queue.pop_front();
        }
        run_job(*runtime, *job);
        {
            std::lock_guard<std::mutex> lock(w.mutex);
            job->done = true;
        }
        w.finished.notify_all();
    }
}

}  // namespace

Result<InstrumentedScript> instrument_script(const std::string& file, std::string_view source, int moduleId) {
    Job job{&file, source, moduleId};
    {
        Worker& w = worker();
        std::unique_lock<std::mutex> lock(w.mutex);
        if (!w.started) {
            if (!start_big_stack_thread(&worker_main, nullptr, kWorkerStack))
                return Error{"cannot instrument " + file + ": the instrumenter thread could not be created", ""};
            w.started = true;
        }
        w.queue.push_back(&job);
        w.wake.notify_one();
        w.finished.wait(lock, [&] { return job.done; });
    }
    if (job.failed) {
        if (job.result.rfind("loading ", 0) == 0 || job.result.find("not bundled") != std::string::npos)
            return Error{"cannot instrument " + file + ": " + job.result, ""};
        return Error{file + ": the script instrumenter failed: " + job.result,
                     "A very deeply nested expression can overflow its stack; the module is compiled as written."};
    }
    const std::string& json = job.result;

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
