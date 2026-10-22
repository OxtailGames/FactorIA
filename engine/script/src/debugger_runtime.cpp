// The script debugger at run time: the natives behind `globalThis.__fa_dbg` (m h p e c x k b) that instrumented code
// calls, the shadow stack, stopping (breakpoints, steps, pause, exceptions) and the inspection of a paused game.
// See docs/design/SCRIPT_DEBUGGER.md, "The runtime".
#include <algorithm>
#include <cstring>
#include <chrono>
#include <format>

#include "fa_script_js.h"
#include "debugger_internal.h"

namespace fa {

using Dbg = ScriptDebugger::Impl;

namespace {

JSClassID g_frameClass = 0;

Dbg* dbg_of(JSContext* ctx) {
    auto* s = static_cast<ScriptSystem::Impl*>(JS_GetContextOpaque(ctx));
    return s && s->debugger ? &s->debugger->impl() : nullptr;
}

void frame_finalizer(JSRuntime* rt, JSValue val) {
    auto* r = static_cast<DebugFrameRec*>(JS_GetOpaque(val, g_frameClass));
    if (!r) return;
    auto* d = static_cast<Dbg*>(r->dbg);
    if (d && r->mid > 0 && static_cast<size_t>(r->mid) < d->modules.size() &&
        d->modules[static_cast<size_t>(r->mid)].moduleFrame == r)
        d->modules[static_cast<size_t>(r->mid)].moduleFrame = nullptr;
    JS_FreeValueRT(rt, r->closure);
    JS_FreeValueRT(rt, r->modClosure);
    delete r;
}

void frame_mark(JSRuntime* rt, JSValueConst val, JS_MarkFunc* mark) {
    auto* r = static_cast<DebugFrameRec*>(JS_GetOpaque(val, g_frameClass));
    if (!r) return;
    JS_MarkValue(rt, r->closure, mark);
    JS_MarkValue(rt, r->modClosure, mark);
}

std::string str_prop(JSContext* ctx, JSValueConst obj, const char* name) {
    JSValue v = JS_GetPropertyStr(ctx, obj, name);
    std::string out;
    if (!JS_IsUndefined(v) && !JS_IsNull(v)) {
        const char* s = JS_ToCString(ctx, v);
        if (s) {
            out = s;
            JS_FreeCString(ctx, s);
        }
    }
    JS_FreeValue(ctx, v);
    return out;
}

int int_arg(JSContext* ctx, JSValueConst v) {
    if (JS_VALUE_GET_TAG(v) == JS_TAG_INT) return JS_VALUE_GET_INT(v);
    int32_t i = 0;
    JS_ToInt32(ctx, &i, v);
    return i;
}

std::string trim(const std::string& s) {
    size_t a = s.find_first_not_of(" \t"), b = s.find_last_not_of(" \t");
    return a == std::string::npos ? std::string() : s.substr(a, b - a + 1);
}

// "5", "== 5", ">= 5", "> 5", "<= 5", "< 5", "% 5": does the n-th hit count?
bool hit_condition_met(const std::string& condition, int n) {
    std::string c = trim(condition);
    if (c.empty()) return true;
    std::string op = "==";
    for (const char* o : {"==", ">=", "<=", ">", "<", "%", "="})
        if (c.rfind(o, 0) == 0) {
            op = o;
            c = trim(c.substr(std::strlen(o)));
            break;
        }
    char* end = nullptr;
    long v = std::strtol(c.c_str(), &end, 10);
    if (end == c.c_str()) return true;  // not a number: do not hide the stop
    if (op == ">=") return n >= v;
    if (op == "<=") return n <= v;
    if (op == ">") return n > v;
    if (op == "<") return n < v;
    if (op == "%") return v > 0 && n % v == 0;
    return n == v;
}

bool is_identifier(const std::string& s) {
    if (s.empty() || std::isdigit(static_cast<unsigned char>(s[0]))) return false;
    for (char ch : s)
        if (!(std::isalnum(static_cast<unsigned char>(ch)) || ch == '_' || ch == '$')) return false;
    return true;
}

const char kEvalWrapper[] = "(function(__fa_code){ with (globalThis.factoria) { return eval(__fa_code); } })";

}  // namespace

DebugFrameRec* debug_frame_of(JSValueConst v) {
    if (g_frameClass == 0 || !JS_IsObject(v)) return nullptr;
    return static_cast<DebugFrameRec*>(JS_GetOpaque(v, g_frameClass));
}

// ---------------------------------------------------------------------------------------------------------------------
// The shadow stack
// ---------------------------------------------------------------------------------------------------------------------
void Dbg::truncate(size_t size) {
    while (stack.size() > size) {
        JSValue v = stack.back();
        stack.pop_back();
        JS_FreeValue(ctx, v);
    }
}

void Dbg::reset_stack() { truncate(0); }

// Makes `frame` the top of the stack: drops what is above it when it is on the stack, else pushes it (an async function
// or a generator that resumes).
void Dbg::heal(JSValueConst frame) {
    void* fp = JS_VALUE_GET_PTR(frame);
    if (!stack.empty() && JS_VALUE_GET_PTR(stack.back()) == fp) return;
    for (size_t i = stack.size(); i-- > 0;)
        if (JS_VALUE_GET_PTR(stack[i]) == fp) {
            truncate(i + 1);
            return;
        }
    stack.push_back(JS_DupValue(ctx, frame));
}

Dbg::Entry::Entry(Dbg& dbg, bool atTop) : d(&dbg) {
    if (atTop) d->reset_stack();
    saved = d->stack.size();
    savedBase = d->entryBase;
    d->entryBase = saved;
}

Dbg::Entry::~Entry() {
    if (!d) return;
    d->truncate(saved);
    d->entryBase = savedBase;
}

int Dbg::module_of_caller() {
    JSAtom a = JS_GetScriptOrModuleName(ctx, 1);  // level 0 is the native itself
    if (a == 0) return 0;                          // JS_ATOM_NULL
    auto it = atomMid.find(a);
    if (it != atomMid.end()) {
        JS_FreeAtom(ctx, a);
        return it->second;
    }
    int mid = 0;
    if (const char* s = JS_AtomToCString(ctx, a)) {
        auto n = nameToMid.find(s);
        if (n != nameToMid.end()) mid = n->second;
        JS_FreeCString(ctx, s);
    }
    atomMid[a] = mid;  // keeps the atom reference
    return mid;
}

// ---------------------------------------------------------------------------------------------------------------------
// Natives
// ---------------------------------------------------------------------------------------------------------------------
namespace {

JSValue new_frame(JSContext* ctx, DebugFrameRec* r) {
    JSValue obj = JS_NewObjectClass(ctx, static_cast<int>(g_frameClass));
    if (JS_IsException(obj)) {
        JS_FreeValue(ctx, r->closure);
        JS_FreeValue(ctx, r->modClosure);
        delete r;
        return obj;
    }
    JS_SetOpaque(obj, r);
    return obj;
}

// m(MID, closure): the module's own frame.
JSValue n_m(JSContext* ctx, JSValueConst, int argc, JSValueConst* argv) {
    Dbg* D = dbg_of(ctx);
    if (!D || argc < 2) return JS_UNDEFINED;
    int mid = int_arg(ctx, argv[0]);
    if (mid <= 0) mid = 0;
    if (static_cast<size_t>(mid) >= D->modules.size()) D->modules.resize(static_cast<size_t>(mid) + 1);
    auto* r = new DebugFrameRec;
    r->dbg = D;
    r->mid = mid;
    r->isModule = true;
    r->closure = JS_DupValue(ctx, argv[1]);
    JSValue obj = new_frame(ctx, r);
    if (JS_IsException(obj)) return obj;
    D->modules[static_cast<size_t>(mid)].moduleFrame = r;
    D->stack.push_back(JS_DupValue(ctx, obj));
    return obj;
}

// e(FID, closure): a function frame.
JSValue n_e(JSContext* ctx, JSValueConst, int argc, JSValueConst* argv) {
    Dbg* D = dbg_of(ctx);
    if (!D || argc < 2) return JS_UNDEFINED;
    auto* r = new DebugFrameRec;
    r->dbg = D;
    r->fid = int_arg(ctx, argv[0]);
    r->mid = D->module_of_caller();
    r->closure = JS_DupValue(ctx, argv[1]);
    if (r->mid > 0) {
        DebugFrameRec* mf = D->modules[static_cast<size_t>(r->mid)].moduleFrame;
        if (mf) r->modClosure = JS_DupValue(ctx, mf->closure);
    }
    JSValue obj = new_frame(ctx, r);
    if (JS_IsException(obj)) return obj;
    D->stack.push_back(JS_DupValue(ctx, obj));
    return obj;
}

// x(f): the frame ends; it and anything stale above it leave the stack.
JSValue n_x(JSContext* ctx, JSValueConst, int argc, JSValueConst* argv) {
    Dbg* D = dbg_of(ctx);
    if (!D || argc < 1) return JS_UNDEFINED;
    void* fp = JS_VALUE_GET_PTR(argv[0]);
    for (size_t i = D->stack.size(); i-- > 0;)
        if (JS_VALUE_GET_PTR(D->stack[i]) == fp) {
            D->truncate(i);
            break;
        }
    return JS_UNDEFINED;
}

JSValue n_h(JSContext* ctx, JSValueConst, int argc, JSValueConst* argv) {
    Dbg* D = dbg_of(ctx);
    if (!D || argc < 2) return JS_FALSE;
    return D->hook_h(argv[0], int_arg(ctx, argv[1])) ? JS_TRUE : JS_FALSE;
}

JSValue n_p(JSContext* ctx, JSValueConst, int argc, JSValueConst* argv) {
    Dbg* D = dbg_of(ctx);
    if (D && argc >= 3) D->hook_p(argv[0], int_arg(ctx, argv[1]), argv[2], false);
    return JS_UNDEFINED;
}

JSValue n_b(JSContext* ctx, JSValueConst, int argc, JSValueConst* argv) {
    Dbg* D = dbg_of(ctx);
    if (D && argc >= 3) D->hook_p(argv[0], int_arg(ctx, argv[1]), argv[2], true);
    return JS_UNDEFINED;
}

JSValue n_c(JSContext* ctx, JSValueConst, int argc, JSValueConst* argv) {
    Dbg* D = dbg_of(ctx);
    if (argc < 2) return JS_UNDEFINED;
    if (D) D->hook_c(argv[0], argv[1]);
    return JS_DupValue(ctx, argv[1]);  // the same value, rethrown by the caller
}

JSValue n_k(JSContext* ctx, JSValueConst, int argc, JSValueConst* argv) {
    Dbg* D = dbg_of(ctx);
    if (D && argc >= 2) D->hook_k(argv[0], argv[1]);
    return JS_UNDEFINED;
}

}  // namespace

// ---------------------------------------------------------------------------------------------------------------------
// attach / detach
// ---------------------------------------------------------------------------------------------------------------------
void Dbg::attach(ScriptSystem::Impl& system) {
    sys = &system;
    ctx = system.ctx;
    JSRuntime* rt = JS_GetRuntime(ctx);
    JS_NewClassID(rt, &g_frameClass);
    if (!JS_IsRegisteredClass(rt, g_frameClass)) {
        JSClassDef def{};
        def.class_name = "FaDebugFrame";
        def.finalizer = frame_finalizer;
        def.gc_mark = frame_mark;
        JS_NewClass(rt, g_frameClass, &def);
    }
    JSValue obj = JS_NewObject(ctx);
    struct Reg {
        const char* name;
        JSCFunction* fn;
        int argc;
    };
    for (const Reg& r : {Reg{"m", n_m, 2}, Reg{"h", n_h, 2}, Reg{"p", n_p, 3}, Reg{"e", n_e, 2}, Reg{"c", n_c, 2},
                         Reg{"x", n_x, 1}, Reg{"k", n_k, 2}, Reg{"b", n_b, 3}})
        JS_SetPropertyStr(ctx, obj, r.name, JS_NewCFunction(ctx, r.fn, r.name, r.argc));
    std::string_view src = embedded_script("debugger.js");
    JSValue helpers = JS_Eval(ctx, src.data(), src.size(), "<debugger>", JS_EVAL_TYPE_GLOBAL);
    if (JS_IsException(helpers)) {
        JSValue exc = JS_GetException(ctx);
        JS_FreeValue(ctx, exc);
    } else {
        fnDescribe = JS_GetPropertyStr(ctx, helpers, "describe");
        fnEntries = JS_GetPropertyStr(ctx, helpers, "entries");
        JS_FreeValue(ctx, helpers);
    }
    JSValue global = JS_GetGlobalObject(ctx);
    JS_SetPropertyStr(ctx, global, "__fa_dbg", obj);
    JS_FreeValue(ctx, global);
}

void Dbg::release_js() {
    if (!ctx) return;
    truncate(0);
    for (JSValue v : throwStack) JS_FreeValue(ctx, v);
    throwStack.clear();
    JS_FreeValue(ctx, lastExc);
    lastExc = JS_UNDEFINED;
    JS_FreeValue(ctx, fnDescribe);
    JS_FreeValue(ctx, fnEntries);
    fnDescribe = fnEntries = JS_UNDEFINED;
    for (auto& [atom, mid] : atomMid) JS_FreeAtom(ctx, atom);
    atomMid.clear();
    modules.assign(1, DebugModule{});
    nameToMid.clear();
    justStopped = nullptr;
}

void Dbg::detach() {
    release_js();
    sys = nullptr;
    ctx = nullptr;
}

// ---------------------------------------------------------------------------------------------------------------------
// Stopping
// ---------------------------------------------------------------------------------------------------------------------
bool Dbg::hook_h(JSValueConst frame, int k) {
    justStopped = nullptr;
    if (inPause || suppress) return false;
    DebugFrameRec* r = debug_frame_of(frame);
    if (!r) return false;
    if (stack.empty() || JS_VALUE_GET_PTR(stack.back()) != JS_VALUE_GET_PTR(frame)) heal(frame);
    r->stmt = k;
    if (terminating.load(std::memory_order_relaxed)) return false;
    if (r->mid <= 0 || static_cast<size_t>(r->mid) >= modules.size()) return false;
    DebugModule& m = modules[static_cast<size_t>(r->mid)];
    if (k < 0 || static_cast<size_t>(k) >= m.stmtLine.size()) return false;
    if (r->bpLine && m.stmtLine[static_cast<size_t>(k)] != r->bpLine) r->bpLine = 0;
    if (pauseReq.load(std::memory_order_relaxed) || entryPending.load(std::memory_order_relaxed)) return true;
    switch (step) {
        case StepMode::In: return true;
        case StepMode::Over:
            if (stack.size() <= stepDepth) return true;
            break;
        case StepMode::Out:
            if (stack.size() < stepDepth) return true;
            break;
        case StepMode::None: break;
    }
    if (m.gen != bpGen.load(std::memory_order_relaxed)) refresh(m);
    return m.stmtBp[static_cast<size_t>(k)] != 0;
}

void Dbg::hook_p(JSValueConst frame, int k, JSValueConst closure, bool forced) {
    if (inPause || suppress) return;
    DebugFrameRec* r = debug_frame_of(frame);
    if (!r) return;
    heal(frame);
    r->stmt = k;
    if (terminating.load()) return;
    if (r->mid <= 0 || static_cast<size_t>(r->mid) >= modules.size()) return;
    DebugModule& m = modules[static_cast<size_t>(r->mid)];
    if (k < 0 || static_cast<size_t>(k) >= m.stmtLine.size()) return;
    if (forced && justStopped == r && justStoppedK == k) return;  // the step already stopped on this statement
    if (m.gen != bpGen.load()) refresh(m);
    const int line = m.stmtLine[static_cast<size_t>(k)];

    DebugStop stop;
    if (!(r->bpLine == line && r->bpK != k)) {  // another statement of a line that already stopped does not stop again
        // Copy: evaluating a condition runs script code, which may reload nothing here but keep it simple.
        const std::vector<DebugBpRec> bps = m.bps;
        const std::string file = m.file;
        for (const DebugBpRec& bp : bps) {
            if (bp.line != line) continue;
            if (!bp.condition.empty()) {
                std::string err;
                bool truthy = eval_condition(closure, bp.condition, err);
                if (!err.empty()) {
                    client.output("stderr", "Breakpoint condition '" + bp.condition + "' failed: " + err, file, line);
                    stop.description = "Breakpoint condition failed: " + err;
                } else if (!truthy) {
                    continue;
                }
            }
            int n = ++hitCounts[bp.id];
            if (!hit_condition_met(bp.hitCondition, n)) continue;
            if (!bp.logMessage.empty()) {
                client.output("console", interpolate(closure, bp.logMessage), file, line);
                continue;
            }
            stop.hitBreakpointIds.push_back(bp.id);
        }
        if (!stop.hitBreakpointIds.empty() || !stop.description.empty()) {
            stop.reason = "breakpoint";
            if (stop.description.empty()) stop.description = "Paused on breakpoint";
            r->bpLine = line;
            r->bpK = k;
        }
    }
    if (stop.reason.empty() && forced) {
        stop.reason = "debugger";
        stop.description = "Paused on debugger statement";
    }
    if (stop.reason.empty()) {
        bool stepHit = (step == StepMode::In) || (step == StepMode::Over && stack.size() <= stepDepth) ||
                       (step == StepMode::Out && stack.size() < stepDepth);
        if (stepHit) {
            stop.reason = "step";
            stop.description = "Paused on step";
        }
    }
    if (stop.reason.empty() && pauseReq.load()) {
        stop.reason = "pause";
        stop.description = "Paused";
    }
    if (stop.reason.empty() && entryPending.load()) {
        stop.reason = "entry";
        stop.description = "Paused on entry";
    }
    if (stop.reason.empty()) return;
    pauseReq = false;
    entryPending = false;
    justStopped = r;
    justStoppedK = k;
    std::vector<JSValue> recs(stack.begin(), stack.end());
    pause_at(std::move(stop), recs, closure);
    justStopped = r;
    justStoppedK = k;
}

namespace {

bool same_value(JSContext* ctx, JSValueConst a, JSValueConst b) { return JS_IsStrictEqual(ctx, a, b); }

std::string exception_text(JSContext* ctx, JSValueConst exc, const Dbg& d) {
    if (JS_IsObject(exc)) {
        std::string name = str_prop(ctx, exc, "name"), msg = str_prop(ctx, exc, "message");
        std::string text = name.empty() ? msg : (msg.empty() ? name : name + ": " + msg);
        std::string st = d.map_stack(str_prop(ctx, exc, "stack"));
        if (!st.empty()) text += "\n" + st;
        return text;
    }
    const char* s = JS_ToCString(ctx, exc);
    std::string out = s ? std::string("uncaught ") + s : "uncaught exception";
    if (s) JS_FreeCString(ctx, s);
    return out;
}

std::string exception_summary(JSContext* ctx, JSValueConst exc) {
    if (JS_IsObject(exc)) {
        std::string name = str_prop(ctx, exc, "name"), msg = str_prop(ctx, exc, "message");
        return name.empty() ? msg : (msg.empty() ? name : name + ": " + msg);
    }
    const char* s = JS_ToCString(ctx, exc);
    std::string out = s ? s : "exception";
    if (s) JS_FreeCString(ctx, s);
    return out;
}

}  // namespace

// c(f, exc): an exception leaves the function that owns frame f.
void Dbg::hook_c(JSValueConst frame, JSValueConst exc) {
    if (inPause || suppress || terminating.load()) return;
    DebugFrameRec* r = debug_frame_of(frame);
    if (!r) return;
    const bool all = excAll.load(), uncaught = excUncaught.load();
    if (!all && !uncaught) return;
    heal(frame);
    const bool first = JS_IsUndefined(lastExc) || !same_value(ctx, lastExc, exc);
    if (first) {
        for (JSValue v : throwStack) JS_FreeValue(ctx, v);
        throwStack.clear();
        for (JSValue v : stack) throwStack.push_back(JS_DupValue(ctx, v));
        JS_FreeValue(ctx, lastExc);
        lastExc = JS_DupValue(ctx, exc);
        lastExcStopped = false;
    }
    const bool outermost = stack.size() > entryBase && JS_VALUE_GET_PTR(stack[entryBase]) == JS_VALUE_GET_PTR(frame);
    const bool stopNow = !lastExcStopped && ((first && all) || (outermost && uncaught));
    if (!stopNow) return;
    lastExcStopped = true;
    DebugStop stop;
    stop.reason = "exception";
    stop.description = exception_summary(ctx, exc);
    stop.exceptionText = exception_text(ctx, exc, *this);
    JSValue none = JS_UNDEFINED;
    std::vector<JSValue> recs = throwStack;  // borrowed: the session dups what it keeps
    pause_at(std::move(stop), recs, none);
}

// k(f, exc): a user `catch` clause caught an exception.
void Dbg::hook_k(JSValueConst frame, JSValueConst exc) {
    if (inPause || suppress || terminating.load() || !excAll.load()) return;
    if (!debug_frame_of(frame)) return;
    heal(frame);
    if (!JS_IsUndefined(lastExc) && same_value(ctx, lastExc, exc)) return;  // `c` of an inner frame already saw it
    for (JSValue v : throwStack) JS_FreeValue(ctx, v);
    throwStack.clear();
    for (JSValue v : stack) throwStack.push_back(JS_DupValue(ctx, v));
    JS_FreeValue(ctx, lastExc);
    lastExc = JS_DupValue(ctx, exc);
    lastExcStopped = true;
    DebugStop stop;
    stop.reason = "exception";
    stop.description = exception_summary(ctx, exc);
    stop.exceptionText = exception_text(ctx, exc, *this);
    JSValue none = JS_UNDEFINED;
    std::vector<JSValue> recs = throwStack;
    pause_at(std::move(stop), recs, none);
}

// ---------------------------------------------------------------------------------------------------------------------
// Evaluating
// ---------------------------------------------------------------------------------------------------------------------
Dbg::EvalOutcome Dbg::run_in(JSValueConst closure, const std::string& code) {
    EvalOutcome out;
    const bool savedTimedOut = sys->timedOut;
    sys->push_guard("debugger evaluate", sys->callbackLimit);
    sys->timedOut = false;
    JSValue arg = JS_NewStringLen(ctx, code.data(), code.size());
    JSValue r;
    if (JS_IsUndefined(closure)) {
        JSValue fn = JS_Eval(ctx, kEvalWrapper, sizeof(kEvalWrapper) - 1, "<debugger>", JS_EVAL_TYPE_GLOBAL);
        r = JS_IsException(fn) ? fn : JS_Call(ctx, fn, JS_UNDEFINED, 1, &arg);
        if (!JS_IsException(fn)) JS_FreeValue(ctx, fn);
    } else {
        r = JS_Call(ctx, closure, JS_UNDEFINED, 1, &arg);
    }
    JS_FreeValue(ctx, arg);
    sys->pop_guard();
    const bool timedOut = sys->timedOut;
    sys->timedOut = savedTimedOut;
    if (JS_IsException(r)) {
        JSValue exc = JS_GetException(ctx);
        if (timedOut) {
            out.errorName = "InternalError";
            out.error = std::format("the expression took too long (> {:g} s) and was stopped", sys->callbackLimit);
        } else {
            out.errorName = JS_IsObject(exc) ? str_prop(ctx, exc, "name") : std::string();
            out.error = exception_summary(ctx, exc);
        }
        JS_FreeValue(ctx, exc);
        return out;
    }
    out.ok = true;
    out.value = r;
    return out;
}

bool Dbg::eval_condition(JSValueConst closure, const std::string& expr, std::string& error) {
    ++suppress;
    EvalOutcome o = run_in(closure, "(" + expr + ")");
    --suppress;
    if (!o.ok) {
        error = o.error;
        return false;
    }
    bool truthy = JS_ToBool(ctx, o.value) > 0;
    JS_FreeValue(ctx, o.value);
    return truthy;
}

Dbg::Described Dbg::describe(JSValueConst v) {
    Described d;
    d.type = JS_IsNull(v) ? "null" : "object";
    if (JS_IsUndefined(fnDescribe)) return d;
    JSValue r = JS_Call(ctx, fnDescribe, JS_UNDEFINED, 1, &v);
    if (JS_IsException(r)) {
        JSValue exc = JS_GetException(ctx);
        JS_FreeValue(ctx, exc);
        d.preview = "<unprintable>";
        return d;
    }
    auto at = [&](uint32_t i) { return JS_GetPropertyUint32(ctx, r, i); };
    JSValue t = at(0), p = at(1), e = at(2), n = at(3);
    auto text = [&](JSValue s) {
        const char* c = JS_ToCString(ctx, s);
        std::string out = c ? c : "";
        if (c) JS_FreeCString(ctx, c);
        return out;
    };
    d.type = text(t);
    d.preview = text(p);
    d.expandable = JS_ToBool(ctx, e) > 0;
    d.indexed = int_arg(ctx, n);
    JS_FreeValue(ctx, t);
    JS_FreeValue(ctx, p);
    JS_FreeValue(ctx, e);
    JS_FreeValue(ctx, n);
    JS_FreeValue(ctx, r);
    return d;
}

std::string Dbg::value_text(JSValueConst v) {
    if (JS_IsString(v)) {
        const char* c = JS_ToCString(ctx, v);
        std::string out = c ? c : "";
        if (c) JS_FreeCString(ctx, c);
        return out;
    }
    return describe(v).preview;
}

// "x is {x}, y is {a + b}": every {expression} is evaluated in the frame's scope.
std::string Dbg::interpolate(JSValueConst closure, const std::string& message) {
    std::string out;
    for (size_t i = 0; i < message.size(); ++i) {
        if (message[i] != '{') {
            out += message[i];
            continue;
        }
        int depth = 1;
        size_t j = i + 1;
        for (; j < message.size() && depth > 0; ++j) {
            if (message[j] == '{') ++depth;
            else if (message[j] == '}') --depth;
        }
        if (depth != 0) {  // no closing brace: literal text
            out += message.substr(i);
            break;
        }
        std::string expr = message.substr(i + 1, j - i - 2);
        ++suppress;
        EvalOutcome o = run_in(closure, "(" + expr + ")");
        --suppress;
        if (o.ok) {
            out += value_text(o.value);
            JS_FreeValue(ctx, o.value);
        } else {
            out += "<error: " + o.error + ">";
        }
        i = j - 1;
    }
    return out;
}

// ---------------------------------------------------------------------------------------------------------------------
// A pause: what the client can ask
// ---------------------------------------------------------------------------------------------------------------------
namespace {

class PauseSession final : public PausedScripts {
public:
    // recs: frame objects, innermost first (borrowed). topClosure: the closure of the innermost frame's statement, or
    // undefined (then its entry closure is used).
    PauseSession(Dbg& dbg, const std::vector<JSValue>& recs, JSValueConst topClosure) : d_(dbg), ctx_(dbg.ctx) {
        for (size_t i = 0; i < recs.size(); ++i) {
            DebugFrameRec* r = debug_frame_of(recs[i]);
            if (!r) continue;
            Fr f;
            f.rec = JS_DupValue(ctx_, recs[i]);
            const bool stmtClosure = frames_.empty() && !JS_IsUndefined(topClosure);
            f.hasStmtClosure = stmtClosure;
            f.closure = JS_DupValue(ctx_, stmtClosure ? topClosure : r->closure);
            f.modClosure = JS_DupValue(ctx_, r->isModule ? r->closure : r->modClosure);
            f.mid = r->mid;
            f.fid = r->fid;
            f.stmt = r->stmt;
            f.isModule = r->isModule;
            f.df.id = static_cast<int>(frames_.size()) + 1;
            d_.frame_position(*r, f.df.file, f.df.name, f.df.line, f.df.column);
            frames_.push_back(std::move(f));
        }
    }
    ~PauseSession() override {
        for (Fr& f : frames_) {
            JS_FreeValue(ctx_, f.rec);
            JS_FreeValue(ctx_, f.closure);
            JS_FreeValue(ctx_, f.modClosure);
        }
        for (Ref& r : refs_) JS_FreeValue(ctx_, r.obj);
    }

    std::vector<DebugFrame> stack() override {
        std::vector<DebugFrame> out;
        for (const Fr& f : frames_) out.push_back(f.df);
        return out;
    }

    std::vector<DebugScope> scopes(int frameId) override {
        std::vector<DebugScope> out;
        Fr* f = frame(frameId);
        if (!f) return out;
        const ScriptDebugInfo* info = info_of(*f);
        if (!info || info->scopes.empty()) return out;
        auto scope_at = [&](int s) { return s >= 0 && static_cast<size_t>(s) < info->scopes.size(); };
        int start = 0;
        if (f->isModule) {
            if (f->hasStmtClosure && f->stmt >= 0 && static_cast<size_t>(f->stmt) < info->statements.size())
                start = info->statements[static_cast<size_t>(f->stmt)].scope;
        } else if (f->hasStmtClosure && f->stmt >= 0 && static_cast<size_t>(f->stmt) < info->statements.size()) {
            start = info->statements[static_cast<size_t>(f->stmt)].scope;
        } else if (f->fid >= 0 && static_cast<size_t>(f->fid) < info->functions.size()) {
            start = info->functions[static_cast<size_t>(f->fid)].scope;
        }
        if (!scope_at(start)) start = 0;

        std::vector<std::string> seen;
        // Collects the names from scope `from` up to and including the next function (or module) scope.
        auto group = [&](int from, int& reached) {
            std::vector<std::string> names;
            int s = from;
            reached = -1;
            while (scope_at(s)) {
                for (const std::string& n : info->scopes[static_cast<size_t>(s)].names) {
                    if (n.rfind("__fa_", 0) == 0) continue;
                    if (std::find(seen.begin(), seen.end(), n) != seen.end()) continue;
                    seen.push_back(n);
                    names.push_back(n);
                }
                const std::string& kind = info->scopes[static_cast<size_t>(s)].kind;
                if (kind == "function" || kind == "module") {
                    reached = s;
                    break;
                }
                s = info->scopes[static_cast<size_t>(s)].parent;
            }
            return names;
        };
        auto add = [&](const std::string& name, std::vector<std::string> names, bool moduleScope) {
            Ref r;
            r.frame = frameId - 1;
            r.names = std::move(names);
            r.moduleScope = moduleScope;
            DebugScope s;
            s.name = name;
            s.variablesReference = new_ref(std::move(r));
            out.push_back(std::move(s));
        };
        int reached = -1;
        add("Locals", group(start, reached), false);
        bool reachedModule = reached >= 0 && info->scopes[static_cast<size_t>(reached)].kind == "module";
        int p = reached >= 0 ? info->scopes[static_cast<size_t>(reached)].parent : -1;
        while (!reachedModule && scope_at(p) && info->scopes[static_cast<size_t>(p)].kind != "module") {
            int fnScope = -1;
            std::vector<std::string> names = group(p, fnScope);
            std::string owner = "(anonymous)";
            for (const auto& fn : info->functions)
                if (fn.scope == fnScope) {
                    owner = fn.name;
                    break;
                }
            if (!names.empty()) add("Closure (" + owner + ")", std::move(names), false);
            p = fnScope >= 0 ? info->scopes[static_cast<size_t>(fnScope)].parent : -1;
        }
        if (!reachedModule) {
            std::vector<std::string> names;
            for (const std::string& n : info->scopes[0].names)
                if (n.rfind("__fa_", 0) != 0) names.push_back(n);
            add("Module", std::move(names), true);
        }
        return out;
    }

    std::vector<DebugValue> variables(int ref, int start, int count) override {
        std::vector<DebugValue> out;
        if (ref <= 0 || static_cast<size_t>(ref) > refs_.size()) return out;
        // Copy what we need: reading values can create new references, which may reallocate refs_.
        const Ref r = refs_[static_cast<size_t>(ref) - 1].copy(ctx_);
        struct Free {
            JSContext* c;
            const Ref& r;
            ~Free() { JS_FreeValue(c, r.obj); }
        } freeObj{ctx_, r};
        start = std::max(start, 0);
        if (r.isObject) {
            if (JS_IsUndefined(d_.fnEntries)) return out;
            JSValue args[3] = {r.obj, JS_NewInt32(ctx_, start), JS_NewInt32(ctx_, std::max(count, 0))};
            JSValue list = JS_Call(ctx_, d_.fnEntries, JS_UNDEFINED, 3, args);
            if (JS_IsException(list)) {
                JSValue exc = JS_GetException(ctx_);
                JS_FreeValue(ctx_, exc);
                return out;
            }
            JSValue lenv = JS_GetPropertyStr(ctx_, list, "length");
            int n = int_arg(ctx_, lenv);
            JS_FreeValue(ctx_, lenv);
            for (int i = 0; i < n; ++i) {
                JSValue item = JS_GetPropertyUint32(ctx_, list, static_cast<uint32_t>(i));
                JSValue nameV = JS_GetPropertyUint32(ctx_, item, 0), val = JS_GetPropertyUint32(ctx_, item, 1),
                        flagV = JS_GetPropertyUint32(ctx_, item, 2);
                std::string name = to_string(nameV);
                int flag = int_arg(ctx_, flagV);
                if (flag != 0) {
                    DebugValue dv;
                    dv.name = name;
                    dv.value = flag == 1 ? "(getter)" : "(setter)";
                    dv.type = "accessor";
                    out.push_back(std::move(dv));
                } else {
                    out.push_back(make_value(name, val));
                }
                JS_FreeValue(ctx_, nameV);
                JS_FreeValue(ctx_, val);
                JS_FreeValue(ctx_, flagV);
                JS_FreeValue(ctx_, item);
            }
            JS_FreeValue(ctx_, list);
            JS_FreeValue(ctx_, args[1]);
            JS_FreeValue(ctx_, args[2]);
            return out;
        }
        // A scope: read each name through the frame's closure.
        Fr* f = r.frame >= 0 && static_cast<size_t>(r.frame) < frames_.size() ? &frames_[static_cast<size_t>(r.frame)] : nullptr;
        if (!f) return out;
        JSValue closure = r.moduleScope ? f->modClosure : f->closure;
        const size_t end = count > 0 ? std::min(r.names.size(), static_cast<size_t>(start) + static_cast<size_t>(count)) : r.names.size();
        for (size_t i = static_cast<size_t>(start); i < end; ++i) {
            const std::string& name = r.names[i];
            if (JS_IsUndefined(closure)) {
                DebugValue dv;
                dv.name = name;
                dv.value = "<unavailable>";
                out.push_back(std::move(dv));
                continue;
            }
            ++d_.suppress;
            Dbg::EvalOutcome o = d_.run_in(closure, name);
            --d_.suppress;
            if (o.ok) {
                out.push_back(make_value(name, o.value));
                JS_FreeValue(ctx_, o.value);
            } else {
                DebugValue dv;
                dv.name = name;
                dv.value = o.errorName == "ReferenceError" ? "<uninitialized>" : "<error: " + o.error + ">";
                out.push_back(std::move(dv));
            }
        }
        return out;
    }

    Result<DebugValue> evaluate(int frameId, std::string_view expression) override {
        JSValue closure = JS_UNDEFINED;
        if (frameId != 0) {
            Fr* f = frame(frameId);
            if (!f) return Error{"no such frame: " + std::to_string(frameId), "Frame ids come from stack(); they are valid until the game resumes."};
            closure = f->closure;
        }
        Dbg::EvalOutcome o = eval_expression(closure, std::string(expression));
        if (!o.ok) return Error{o.error, "Names of the frame's scope (and \"factoria\" in the global scope) are in scope; `{a: 1}` is read as an object."};
        DebugValue dv = make_value("", o.value);
        JS_FreeValue(ctx_, o.value);
        return dv;
    }

    Result<DebugValue> set_variable(int ref, std::string_view name, std::string_view valueExpression) override {
        if (ref <= 0 || static_cast<size_t>(ref) > refs_.size())
            return Error{"no such variables reference: " + std::to_string(ref), "References are valid until the game resumes."};
        const Ref r = refs_[static_cast<size_t>(ref) - 1].copy(ctx_);
        struct Free {
            JSContext* c;
            const Ref& r;
            ~Free() { JS_FreeValue(c, r.obj); }
        } freeObj{ctx_, r};
        JSValue topClosure = frames_.empty() ? JS_UNDEFINED : frames_[0].closure;
        Dbg::EvalOutcome v = eval_expression(topClosure, std::string(valueExpression));
        if (!v.ok) return Error{"cannot evaluate the new value: " + v.error, "Write a JavaScript expression, e.g. 42 or \"text\" or this.speed * 2."};
        const std::string key(name);
        if (r.isObject) {
            if (key == "[[Prototype]]") {
                JS_FreeValue(ctx_, v.value);
                return Error{"cannot assign [[Prototype]]", "Set the properties of the object instead."};
            }
            d_.sys->push_guard("debugger set variable", d_.sys->callbackLimit);
            const bool savedTimedOut = d_.sys->timedOut;
            d_.sys->timedOut = false;
            int rc = JS_SetPropertyStr(ctx_, r.obj, key.c_str(), v.value);  // consumes v.value
            d_.sys->pop_guard();
            d_.sys->timedOut = savedTimedOut;
            if (rc < 0) {
                JSValue exc = JS_GetException(ctx_);
                std::string msg = exc_text(exc);
                JS_FreeValue(ctx_, exc);
                return Error{"cannot set '" + key + "': " + msg, "The property may be read-only or have a setter that threw."};
            }
            JSValue now = JS_GetPropertyStr(ctx_, r.obj, key.c_str());
            DebugValue dv = make_value(key, now);
            JS_FreeValue(ctx_, now);
            return dv;
        }
        Fr* f = r.frame >= 0 && static_cast<size_t>(r.frame) < frames_.size() ? &frames_[static_cast<size_t>(r.frame)] : nullptr;
        if (!f) {
            JS_FreeValue(ctx_, v.value);
            return Error{"the frame of this scope is gone", "Ask for the scopes again."};
        }
        if (!is_identifier(key)) {
            JS_FreeValue(ctx_, v.value);
            return Error{"cannot assign '" + key + "': not a variable name", "Only declared variables can be changed here."};
        }
        JSValue closure = r.moduleScope ? f->modClosure : f->closure;
        JSValue global = JS_GetGlobalObject(ctx_);
        JSValue dbgObj = JS_GetPropertyStr(ctx_, global, "__fa_dbg");
        JS_SetPropertyStr(ctx_, dbgObj, "v", v.value);  // consumes v.value
        ++d_.suppress;
        Dbg::EvalOutcome assigned = d_.run_in(closure, key + " = globalThis.__fa_dbg.v");
        JS_SetPropertyStr(ctx_, dbgObj, "v", JS_UNDEFINED);
        JS_FreeValue(ctx_, dbgObj);
        JS_FreeValue(ctx_, global);
        if (!assigned.ok) {
            --d_.suppress;
            return Error{"cannot assign '" + key + "': " + assigned.error,
                         assigned.errorName == "TypeError" ? "A const cannot be reassigned." : "The variable must be in scope."};
        }
        JS_FreeValue(ctx_, assigned.value);
        Dbg::EvalOutcome now = d_.run_in(closure, key);
        --d_.suppress;
        if (!now.ok) return Error{"assigned, but cannot read '" + key + "' back: " + now.error, ""};
        DebugValue dv = make_value(key, now.value);
        JS_FreeValue(ctx_, now.value);
        return dv;
    }

private:
    struct Fr {
        JSValue rec = JS_UNDEFINED, closure = JS_UNDEFINED, modClosure = JS_UNDEFINED;
        int mid = 0, fid = -1, stmt = -1;
        bool isModule = false, hasStmtClosure = false;
        DebugFrame df;
    };
    struct Ref {
        bool isObject = false;
        JSValue obj = JS_UNDEFINED;
        int frame = -1;
        std::vector<std::string> names;
        bool moduleScope = false;
        Ref copy(JSContext* c) const {
            Ref r = *this;
            r.obj = JS_DupValue(c, obj);
            return r;
        }
    };

    Fr* frame(int id) { return id >= 1 && static_cast<size_t>(id) <= frames_.size() ? &frames_[static_cast<size_t>(id) - 1] : nullptr; }
    const ScriptDebugInfo* info_of(const Fr& f) const {
        return f.mid > 0 && static_cast<size_t>(f.mid) < d_.modules.size() ? d_.modules[static_cast<size_t>(f.mid)].info.get() : nullptr;
    }
    int new_ref(Ref r) {
        refs_.push_back(std::move(r));
        return static_cast<int>(refs_.size());
    }
    std::string to_string(JSValueConst v) {
        const char* c = JS_ToCString(ctx_, v);
        std::string out = c ? c : "";
        if (c) JS_FreeCString(ctx_, c);
        return out;
    }
    std::string exc_text(JSValueConst exc) {
        std::string name = JS_IsObject(exc) ? str_prop(ctx_, exc, "name") : "", msg = JS_IsObject(exc) ? str_prop(ctx_, exc, "message") : to_string(exc);
        return name.empty() ? msg : name + ": " + msg;
    }
    DebugValue make_value(const std::string& name, JSValueConst v) {
        Dbg::Described ds = d_.describe(v);
        DebugValue dv;
        dv.name = name;
        dv.value = ds.preview;
        dv.type = ds.type;
        dv.indexedVariables = ds.indexed;
        if (ds.expandable) {
            Ref r;
            r.isObject = true;
            r.obj = JS_DupValue(ctx_, v);
            dv.variablesReference = new_ref(std::move(r));
        }
        return dv;
    }
    // `(expr)` first, then expr as statements ({a: 1} is an object; `let y = 2; y * 3` works).
    Dbg::EvalOutcome eval_expression(JSValueConst closure, const std::string& expr) {
        ++d_.suppress;
        Dbg::EvalOutcome o = d_.run_in(closure, "(" + expr + ")");
        if (!o.ok && o.errorName == "SyntaxError") {
            Dbg::EvalOutcome second = d_.run_in(closure, expr);
            if (second.ok || second.errorName != "SyntaxError") o = std::move(second);
        }
        --d_.suppress;
        return o;
    }

    Dbg& d_;
    JSContext* ctx_;
    std::vector<Fr> frames_;
    std::vector<Ref> refs_;
};

}  // namespace

void Dbg::pause_at(DebugStop stop, const std::vector<JSValue>& recs, JSValueConst topClosure) {
    if (inPause) return;
    std::vector<JSValue> inner(recs.rbegin(), recs.rend());  // recs are outermost first
    PauseSession session(*this, inner, topClosure);

    // The game is stopped, not slow: set the guards aside and give them back later by the length of the pause.
    std::vector<ScriptSystem::Impl::GuardFrame> savedGuards = std::move(sys->guards);
    sys->guards.clear();
    const bool savedTimedOut = sys->timedOut;
    sys->timedOut = false;
    const auto t0 = std::chrono::steady_clock::now();
    inPause = true;
    DebugResume resume = client.paused(stop, session);
    inPause = false;
    const auto paused = std::chrono::steady_clock::now() - t0;
    sys->guards = std::move(savedGuards);
    for (auto& g : sys->guards) g.deadline += paused;
    sys->timedOut = savedTimedOut;

    if (terminating.load()) resume = DebugResume::Continue;
    stepDepth = stack.size();
    switch (resume) {
        case DebugResume::Continue: step = StepMode::None; break;
        case DebugResume::StepIn: step = StepMode::In; break;
        case DebugResume::StepOver: step = StepMode::Over; break;
        case DebugResume::StepOut: step = StepMode::Out; break;
    }
}

}  // namespace fa
