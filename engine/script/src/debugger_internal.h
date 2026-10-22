// Private implementation of ScriptDebugger (docs/design/SCRIPT_DEBUGGER.md, "The runtime").
//
// Two kinds of state live here:
//   - shared, guarded by `mutex` or atomic: breakpoints, exception filters, pause/terminate requests (any thread);
//   - script thread only: the shadow stack, the module table, the step state, the JavaScript objects.
#pragma once

#include <atomic>
#include <chrono>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

#include <quickjs.h>

#include "fa/script/debugger.h"
#include "script_internal.h"

namespace fa {

// A breakpoint as stored (shared state).
struct DebugBpRec {
    int id = 0;
    int requestedLine = 0;
    int line = 0;  // where it really is (a breakable line); 0 = not verified
    std::string condition, hitCondition, logMessage;
};

// The record behind a frame object (`__fa_f`): a JS object of a private class owns it, its finalizer deletes it, and its
// gc_mark keeps the closures alive (they are part of reference cycles with the frame object).
struct DebugFrameRec {
    void* dbg = nullptr;  // ScriptDebugger::Impl*
    int mid = 0;          // module id, 0 = unknown
    int fid = -1;         // index into info->functions, -1 for a module frame
    int stmt = -1;        // the last statement hook this frame passed (index into info->statements), -1 none yet
    int bpLine = 0;       // line of a breakpoint that already stopped here (another statement of that line does not stop again)
    int bpK = -1;         // the statement it stopped at
    bool isModule = false;
    JSValue closure = JS_UNDEFINED;     // `(x) => eval(x)` made when the frame was entered (the module scope for a module frame)
    JSValue modClosure = JS_UNDEFINED;  // the module's closure, for the Module scope
};
DebugFrameRec* debug_frame_of(JSValueConst v);  // nullptr when v is not a frame object

// What the script thread knows about one loaded (instrumented) module.
struct DebugModule {
    std::string file;  // project-relative, no ?v=
    std::string name;  // as QuickJS knows it (with ?v=N after a reload)
    std::shared_ptr<const ScriptDebugInfo> info;
    DebugFrameRec* moduleFrame = nullptr;  // the record `m` made (not owned: its JS object is)
    std::uint64_t gen = 0;                 // breakpoint generation `stmtBp`/`bps` were built for
    std::vector<std::uint8_t> stmtBp;      // per statement: a breakpoint sits on its line
    std::vector<int> stmtLine;             // per statement: its line (copy of info->statements, hot)
    std::vector<DebugBpRec> bps;           // this file's verified breakpoints
};

struct ScriptDebugger::Impl {
    Impl(DebugClient& client, ScriptInstrumenter instrumenter, std::string projectDir);
    ~Impl();

    DebugClient& client;
    ScriptInstrumenter instrumenter;
    std::string projectDir;

    // ---------------------------------------------------------------------------------------- shared state
    std::mutex mutex;  // breakpoints, fileInfo
    std::map<std::string, std::vector<DebugBpRec>> breakpoints;
    std::map<std::string, std::shared_ptr<const ScriptDebugInfo>> fileInfo;  // latest loaded info of each file
    int nextBpId = 1;
    std::mutex instrumenterMutex;  // the instrumenter is called from the script thread and from set_breakpoints
    std::atomic<std::uint64_t> bpGen{1};
    std::atomic<bool> excAll{false}, excUncaught{false};
    std::atomic<bool> pauseReq{false}, terminating{false}, entryPending{false};

    std::vector<DebugBreakpointState> set_breakpoints(const std::string& file, const std::vector<DebugBreakpoint>& bps);
    Result<InstrumentedScript> instrument(const std::string& file, std::string_view source, int moduleId);
    void refresh(DebugModule& m);  // script thread: rebuild a module's breakpoint view

    // ---------------------------------------------------------------------------------------- attach to a runtime
    ScriptSystem::Impl* sys = nullptr;
    JSContext* ctx = nullptr;
    JSValue fnDescribe = JS_UNDEFINED, fnEntries = JS_UNDEFINED;
    void attach(ScriptSystem::Impl& system);  // installs globalThis.__fa_dbg
    void release_js();                        // before the context is freed
    void detach();

    // ---------------------------------------------------------------------------------------- script thread state
    enum class StepMode { None, In, Over, Out };
    std::vector<DebugModule> modules;  // index = module id (0 unused)
    std::map<std::string, int> nameToMid;
    std::unordered_map<JSAtom, int> atomMid;
    int nextMid = 1;
    std::vector<JSValue> stack;  // owned references to frame record objects, outermost first
    size_t entryBase = 0;        // stack size when the host entered JS the last time
    bool inPause = false;
    int suppress = 0;            // > 0: hooks do not stop (a condition or logpoint is being evaluated)
    StepMode step = StepMode::None;
    size_t stepDepth = 0;
    std::unordered_map<int, int> hitCounts;
    const DebugFrameRec* justStopped = nullptr;
    int justStoppedK = -1;
    JSValue lastExc = JS_UNDEFINED;
    bool lastExcStopped = false;
    std::vector<JSValue> throwStack;  // the stack where lastExc was first seen (owned)
    bool quitSent = false;

    int register_module(const std::string& file, const std::string& name);  // fresh module id
    void module_loaded(int mid, std::shared_ptr<const ScriptDebugInfo> info);
    int module_of_caller();  // the module whose code called the running native, 0 if unknown
    void heal(JSValueConst frame);
    void truncate(size_t size);
    void reset_stack();

    // Natives (script_debugger_runtime.cpp)
    bool hook_h(JSValueConst frame, int k);
    void hook_p(JSValueConst frame, int k, JSValueConst closure, bool forced);
    void hook_c(JSValueConst frame, JSValueConst exc);
    void hook_k(JSValueConst frame, JSValueConst exc);

    // Entry points of the host into JS and per-frame work (called by ScriptSystem)
    struct Entry {
        Impl* d = nullptr;
        size_t saved = 0, savedBase = 0;
        Entry() = default;
        Entry(Impl& dbg, bool atTop);
        Entry(const Entry&) = delete;
        Entry& operator=(const Entry&) = delete;
        Entry(Entry&& o) noexcept : d(o.d), saved(o.saved), savedBase(o.savedBase) { o.d = nullptr; }
        ~Entry();
    };
    void frame_start();                                       // dispatch_platform: terminate and poll
    bool interrupt_requested() const { return terminating.load(std::memory_order_relaxed); }
    std::string map_stack(const std::string& stack) const;    // instrumented columns -> original
    void map_location(const std::string& file, int line, int& column) const;
    void on_console(int level, const std::string& text);
    void on_error(const ScriptError& e);
    bool top_position(std::string& file, int& line) const;
    // Where a frame is: file, function name, line and column of its last hook.
    void frame_position(const DebugFrameRec& r, std::string& file, std::string& name, int& line, int& column) const;

    // Pausing
    bool paused_now() const { return inPause; }
    void pause_at(DebugStop stop, const std::vector<JSValue>& recs, JSValueConst topClosure);
    struct EvalOutcome {
        bool ok = false;
        JSValue value = JS_UNDEFINED;  // owned when ok
        std::string error;             // "TypeError: x is not a function"
        std::string errorName;
    };
    // Evaluates `code` with the closure (a frame's `(x) => eval(x)`), or globally when `closure` is undefined, under its
    // own guard.
    EvalOutcome run_in(JSValueConst closure, const std::string& code);
    bool eval_condition(JSValueConst closure, const std::string& expr, std::string& error);
    std::string interpolate(JSValueConst closure, const std::string& message);
    std::string value_text(JSValueConst v);  // for logpoints: strings raw, the rest as previews
    // describe(): {type, preview, expandable, indexed}
    struct Described {
        std::string type, preview;
        bool expandable = false;
        int indexed = 0;
    };
    Described describe(JSValueConst v);
};

// Marks the host entering JS (a callback, a job, an import, a REPL line): from an empty JS stack it resets the shadow
// stack. A no-op object without a debugger.
inline ScriptDebugger::Impl::Entry debug_entry(ScriptSystem::Impl& s) {
    if (!s.debugger) return ScriptDebugger::Impl::Entry();
    ScriptDebugger::Impl& d = s.debugger->impl();
    return ScriptDebugger::Impl::Entry(d, s.guards.empty() && !d.inPause);
}

}  // namespace fa
