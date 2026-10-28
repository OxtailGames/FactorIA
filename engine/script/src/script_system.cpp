// ScriptSystem: public API + runtime/module/error plumbing. Behaviours live in script_behaviours.cpp, natives in
// script_natives.cpp, tools/tests/eval in script_tools.cpp, API description in script_api.cpp.
#include <algorithm>
#include <cctype>
#include <cstring>
#include <format>
#include <sstream>

#include "fa_script_js.h"
#include "fa/audio/audio.h"
#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "fa/platform/input.h"
#include "fa/scene/components.h"
#include "fa/script/bytecode.h"
#include "fa/ui/ui.h"
#include "debugger_internal.h"
#include "script_internal.h"

namespace fa {

std::string_view embedded_script(std::string_view name) {
    for (const auto& f : script_js::files())
        if (f.path == name) return f.data;
    return {};
}

std::string source_caret(const std::string& file, int line, int column) {
    if (file.empty() || line <= 0 || file[0] == '<') return {};
    auto text = fs::read_text(file);
    if (!text) return {};
    std::istringstream in(*text);
    std::string src;
    for (int i = 0; i < line; ++i)
        if (!std::getline(in, src)) return {};
    if (!src.empty() && src.back() == '\r') src.pop_back();
    std::string pad;
    for (int i = 0; i + 1 < column && i < static_cast<int>(src.size()); ++i) pad += src[i] == '\t' ? '\t' : ' ';
    return "\n  " + src + "\n  " + pad + "^";
}

std::string ScriptError::to_string() const {
    std::string s = file.empty() ? "<script>" : file;
    if (line > 0) s += ":" + std::to_string(line) + (column > 0 ? ":" + std::to_string(column) : "");
    s += ": " + message;
    if (!entityId.empty()) s += " (entity '" + entityId + "')";
    return s;
}

static Json logs_json(const std::vector<TestLogLine>& logs) {
    Json a = Json::array();
    for (const auto& l : logs) a.push_back(Json::object({{"level", log_level_name(l.level)}, {"message", l.message}}));
    return a;
}

Json TestReport::to_json() const {
    Json j = Json::object();
    j["ok"] = ok();
    j["passed"] = passed;
    j["failed"] = failed;
    Json arr = Json::array();
    for (const auto& c : cases) {
        Json o = Json::object();
        o["file"] = c.file;
        o["name"] = c.name;
        o["passed"] = c.passed;
        if (!c.message.empty()) o["message"] = c.message;
        o["ms"] = std::round(c.milliseconds * 100.0) / 100.0;
        if (!c.logs.empty()) o["logs"] = logs_json(c.logs);
        arr.push_back(std::move(o));
    }
    j["cases"] = std::move(arr);
    if (!otherLogs.empty()) j["logs"] = logs_json(otherLogs);
    Json errs = Json::array();
    for (const auto& e : loadErrors) {
        errs.push_back(Json::object({{"file", e.file}, {"line", e.line}, {"column", e.column},
                                     {"message", e.message}, {"stack", e.stack}}));
    }
    j["loadErrors"] = std::move(errs);
    j["summary"] = summary();
    return j;
}

std::string TestReport::summary() const {
    std::string s;
    for (const auto& c : cases) {
        s += c.passed ? "  PASS " : "  FAIL ";
        s += c.file + " > " + c.name;
        if (!c.passed && !c.message.empty()) s += "\n       " + replace_all(c.message, "\n", "\n       ");
        s += "\n";
    }
    for (const auto& e : loadErrors) s += "  ERROR " + e.to_string() + "\n";
    s += std::format("{} passed, {} failed", passed, failed);
    if (!loadErrors.empty()) s += std::format(", {} file(s) failed to load", loadErrors.size());
    return s;
}

// ---------------------------------------------------------------------------------------------------------------------
// Runtime callbacks
// ---------------------------------------------------------------------------------------------------------------------
namespace {

ScriptSystem::Impl* impl_of(JSContext* ctx) { return static_cast<ScriptSystem::Impl*>(JS_GetContextOpaque(ctx)); }

char* dup_js_string(JSContext* ctx, const std::string& s) {
    char* p = static_cast<char*>(js_malloc(ctx, s.size() + 1));
    if (!p) return nullptr;
    std::memcpy(p, s.c_str(), s.size() + 1);
    return p;
}

char* normalize_cb(JSContext* ctx, const char* base, const char* name, void* opaque) {
    auto* I = static_cast<ScriptSystem::Impl*>(opaque);
    std::string err;
    std::string r = I->normalize_module(base ? base : "", name, &err);
    if (r.empty()) {
        JS_ThrowPlainError(ctx, "%s", err.c_str());
        return nullptr;
    }
    return dup_js_string(ctx, r);
}

JSModuleDef* loader_cb(JSContext* ctx, const char* name, void* opaque) {
    auto* I = static_cast<ScriptSystem::Impl*>(opaque);
    (void)ctx;
    return I->load_module(name);
}

int interrupt_cb(JSRuntime*, void* opaque) { return static_cast<ScriptSystem::Impl*>(opaque)->check_interrupt() ? 1 : 0; }

// Like Node: a rejection counts as unhandled only if still unhandled once the job queue has drained (run_jobs), so
// `p.then(() => store.call()).catch(...)` is fine: the store promise gets its handler one microtask later.
void rejection_cb(JSContext* ctx, JSValueConst promise, JSValueConst reason, bool is_handled, void* opaque) {
    auto* I = static_cast<ScriptSystem::Impl*>(opaque);
    auto& list = I->pendingRejections;
    if (!is_handled) {
        list.push_back({JS_DupValue(ctx, promise), JS_DupValue(ctx, reason)});
        return;
    }
    for (size_t i = 0; i < list.size(); ++i)
        if (JS_VALUE_GET_PTR(list[i].promise) == JS_VALUE_GET_PTR(promise)) {
            JS_FreeValue(ctx, list[i].promise);
            JS_FreeValue(ctx, list[i].reason);
            list.erase(list.begin() + static_cast<std::ptrdiff_t>(i));
            return;
        }
}

}  // namespace

// ---------------------------------------------------------------------------------------------------------------------
// Guard / interrupt
// ---------------------------------------------------------------------------------------------------------------------
size_t ScriptSystem::Impl::push_guard(const std::string& label, double seconds) {
    const size_t depth = guards.size();
    guards.push_back({label, seconds, std::chrono::steady_clock::now() +
                                 std::chrono::microseconds(static_cast<long long>(seconds * 1e6))});
    return depth;
}

void ScriptSystem::Impl::pop_guard(size_t depth) {
    if (guards.size() > depth) guards.erase(guards.begin() + static_cast<std::ptrdiff_t>(depth), guards.end());
}

bool ScriptSystem::Impl::debug_session_ended() const { return debugger && debugger->impl().interrupt_requested(); }

bool ScriptSystem::Impl::check_interrupt() {
    if (debug_session_ended()) {  // stop running scripts
        timedOut = true;
        timedOutLabel = "debugger terminate";
        return true;
    }
    if (guards.empty()) return false;
    auto now = std::chrono::steady_clock::now();
    for (size_t i = guards.size(); i-- > 0;) {
        if (now > guards[i].deadline) {
            timedOut = true;
            timedOutLabel = guards[i].label;
            timedOutSeconds = guards[i].seconds;
            timedOutDepth = i;
            return true;
        }
    }
    return false;
}

void ScriptSystem::Impl::run_jobs() {
    if (!rt) return;
    ProfBehaviourScope prof(kProfOtherName, kProfNoPath);  // promise jobs (and flushing their rejections) belong to no behaviour
    for (int guardCount = 0; guardCount < 100000; ++guardCount) {
        JSContext* jctx = nullptr;
        auto entry = debug_entry(*this);
        const size_t depth = guards.size();
        timedOut = false;
        int r = JS_ExecutePendingJob(rt, &jctx);
        pop_guard(depth);  // a job the watchdog stopped inside a JS guard (an async world.on listener) left its frame
        if (r == 0) break;
        if (r < 0) {
            if (timedOut && (debug_session_ended() || timedOutDepth < depth)) {
                // Stopped by terminate, or the caller's time ran out (an async test pumping its jobs): the caller
                // reports it.
                JS_FreeValue(ctx, JS_GetException(ctx));
                break;
            }
            if (timedOut) {  // a JS guard inside the job ran out (an async world.on listener)
                timedOut = false;
                JS_FreeValue(ctx, JS_GetException(ctx));
                ScriptError e;
                e.message = std::format("script took too long (> {:g} s) in {}", timedOutSeconds, timedOutLabel);
                record_error(std::move(e), "promise job");
                continue;
            }
            report_pending_exception("", "promise job");
        }
    }
    flush_rejections();
}

void ScriptSystem::Impl::flush_rejections() {
    auto list = std::move(pendingRejections);
    pendingRejections.clear();
    for (auto& r : list) {
        ScriptError e = error_from_exception(r.reason, "", "promise");
        e.message = "unhandled promise rejection: " + e.message;
        record_error(std::move(e), "promise");
        JS_FreeValue(ctx, r.promise);
        JS_FreeValue(ctx, r.reason);
    }
}

// ---------------------------------------------------------------------------------------------------------------------
// Errors
// ---------------------------------------------------------------------------------------------------------------------
std::string ScriptSystem::Impl::strip_versions(std::string s) const {
    size_t pos = 0;
    while ((pos = s.find("?v=", pos)) != std::string::npos) {
        size_t end = pos + 3;
        while (end < s.size() && std::isdigit(static_cast<unsigned char>(s[end]))) ++end;
        s.erase(pos, end - pos);
    }
    return s;
}

namespace {

std::string get_str_prop(JSContext* ctx, JSValueConst obj, const char* name) {
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

// Finds the first stack frame that is user code ("    at fn (file:line:col)" or "    at file:line:col").
bool parse_first_user_frame(const std::string& stack, std::string& file, int& line, int& col) {
    size_t pos = 0;
    while (pos < stack.size()) {
        size_t eol = stack.find('\n', pos);
        std::string ln = stack.substr(pos, eol == std::string::npos ? std::string::npos : eol - pos);
        pos = eol == std::string::npos ? stack.size() : eol + 1;
        size_t at = ln.find("at ");
        if (at == std::string::npos) continue;
        std::string rest = ln.substr(at + 3);
        size_t lp = rest.rfind('(');
        if (lp != std::string::npos) {
            size_t rp = rest.rfind(')');
            rest = rest.substr(lp + 1, rp == std::string::npos ? std::string::npos : rp - lp - 1);
        }
        if (rest.empty() || rest[0] == '<' || rest.find("native") != std::string::npos) continue;
        // file:line:col
        size_t c2 = rest.rfind(':');
        if (c2 == std::string::npos) continue;
        size_t c1 = rest.rfind(':', c2 - 1);
        if (c1 == std::string::npos) continue;
        try {
            line = std::stoi(rest.substr(c1 + 1, c2 - c1 - 1));
            col = std::stoi(rest.substr(c2 + 1));
        } catch (...) {
            continue;
        }
        file = rest.substr(0, c1);
        return true;
    }
    return false;
}

std::string hint_for(const std::string& msg) {
    auto has = [&](const char* s) { return msg.find(s) != std::string::npos; };
    if (has("was destroyed")) return "Check entity.alive before using an entity that may have been destroyed.";
    if (has("took too long")) return "Avoid long or infinite loops inside callbacks; spread the work over several frames.";
    if (has("older than the game's engine"))
        return "The game was made with a newer FactorIA than the player running it. Run `factoria setup players` and export again, "
               "or build the player from the same checkout as factoria (docs/EXPORTING.md, \"The player must come from the same build\"); "
               "for the web, `cmake --build --preset web-release` and export: it prefers build/web-release.";
    if (has("not a function"))
        return "Check the method name against `factoria api` / types/factoria.d.ts, and that the object is not null "
               "(entity.get(name) returns null when the component is missing).";
    if (has("cannot read property") || has("null") || has("undefined"))
        return "A value was null/undefined. world.find(id) and entity.get(name) return null when nothing matches; "
               "check before using the result.";
    if (has("not defined")) return "Import it first: import { world, input, vec2 } from \"factoria\";";
    return "";
}

}  // namespace

// A script that needs something the player lacks (the player is older than the engine the game was made with) fails with
// QuickJS's generic message. Names the module and the missing export, or the object and method of the call, and says why.
void ScriptSystem::Impl::explain_missing_api(ScriptError& e) {
    std::string& message = e.message;
    const std::string tail = "; this player may be older than the game's engine";
    // SyntaxError: Could not find export 'x' in module 'factoria'
    static const std::string find = "ould not find export '";
    if (const size_t at = message.find(find); at != std::string::npos) {
        const size_t end = message.find('\'', at + find.size());
        const size_t mod = message.find(" in module '", end == std::string::npos ? at : end);
        if (end != std::string::npos && mod != std::string::npos) {
            const size_t modEnd = message.find('\'', mod + 12);
            if (modEnd != std::string::npos) {
                const std::string name = message.substr(at + find.size(), end - at - find.size());
                const std::string module = message.substr(mod + 12, modEnd - mod - 12);
                if (module == "factoria" || module.rfind("factoria:", 0) == 0)
                    message += " (module '" + module + "' has no export '" + name + "'" + tail + ")";
            }
        }
        return;
    }
    // TypeError: not a function, at `scene.preload(...)` where `scene` is one of the engine's objects without that member.
    // QuickJS does not name the callee: it is read from the source line, at the column of the property access.
    if (message.find("not a function") == std::string::npos || e.line <= 0 || e.column <= 0 || e.file.empty() || e.file[0] == '<' ||
        !JS_IsObject(factoria.get()))
        return;
    auto text = fs::read_text(e.file);
    if (!text) return;
    std::istringstream in(*text);
    std::string src;
    for (int i = 0; i < e.line; ++i)
        if (!std::getline(in, src)) return;
    const auto ident = [](char c) { return std::isalnum(static_cast<unsigned char>(c)) || c == '_' || c == '$'; };
    size_t dot = static_cast<size_t>(e.column - 1);  // the column is the method's name, or the dot before it
    if (dot < src.size() && src[dot] != '.' && dot > 0) --dot;
    if (dot == 0 || dot >= src.size() || src[dot] != '.') return;
    size_t objStart = dot, methodEnd = dot + 1;
    while (objStart > 0 && ident(src[objStart - 1])) --objStart;
    while (methodEnd < src.size() && ident(src[methodEnd])) ++methodEnd;
    const std::string object = src.substr(objStart, dot - objStart), method = src.substr(dot + 1, methodEnd - dot - 1);
    if (object.empty() || method.empty()) return;
    JSValue api = JS_GetPropertyStr(ctx, factoria.get(), object.c_str());
    if (JS_IsObject(api)) {
        JSAtom atom = JS_NewAtom(ctx, method.c_str());
        const int has = JS_HasProperty(ctx, api, atom);
        JS_FreeAtom(ctx, atom);
        if (has == 0)
            message += " (the engine's '" + object + "' from \"factoria\" has no '" + method + "'" + tail + ", if " + object +
                       " is that object)";
    }
    JS_FreeValue(ctx, api);
}

ScriptError ScriptSystem::Impl::error_from_exception(JSValueConst exc, const std::string& entityId,
                                                     const std::string& where) {
    ScriptError e;
    e.entityId = entityId;
    if (JS_IsObject(exc)) {
        std::string name = get_str_prop(ctx, exc, "name");
        std::string msg = get_str_prop(ctx, exc, "message");
        std::string rawStack = get_str_prop(ctx, exc, "stack");
        if (debugger) rawStack = debugger->impl().map_stack(rawStack);  // instrumented columns -> the author's columns
        e.stack = strip_versions(rawStack);
        e.message = (name.empty() || name == "Error") ? msg : (msg.empty() ? name : name + ": " + msg);
        std::string file;
        int line = 0, col = 0;
        if (parse_first_user_frame(e.stack, file, line, col)) {
            e.file = file;
            e.line = line;
            e.column = col;
        } else {
            e.file = strip_versions(get_str_prop(ctx, exc, "fileName"));
            std::string ln = get_str_prop(ctx, exc, "lineNumber");
            std::string cl = get_str_prop(ctx, exc, "columnNumber");
            if (!ln.empty()) e.line = std::atoi(ln.c_str());
            if (!cl.empty()) e.column = std::atoi(cl.c_str());
            if (debugger && e.line > 0) {
                std::string raw = get_str_prop(ctx, exc, "fileName");
                debugger->impl().map_location(raw, e.line, e.column);
            }
        }
    } else {
        const char* s = JS_ToCString(ctx, exc);
        e.message = s ? std::string("uncaught ") + s : "uncaught exception";
        if (s) JS_FreeCString(ctx, s);
    }
    if (e.file.empty()) e.file = where;
    e.message = strip_versions(e.message);
    explain_missing_api(e);
    return e;
}

void ScriptSystem::Impl::record_error(ScriptError e, const std::string& where) {
    std::string key = e.file + ":" + std::to_string(e.line) + ":" + e.message;
    bool fresh = loggedKeys.insert(key).second;
    if (!fresh) return;
    std::string hint = hint_for(e.message);
    std::string text = e.to_string();
    if (!where.empty() && where != e.file) text += " [in " + where + "]";
    if (e.message.find("not a function") != std::string::npos) text += source_caret(e.file, e.line, e.column);
    if (!hint.empty()) text += "\n  hint: " + hint;
    if (!e.stack.empty()) text += "\n" + e.stack;
    log(LogLevel::Error, "script", text);
    if (debugger) debugger->impl().on_error(e);
    if (errors.size() < 500) errors.push_back(std::move(e));
}

void ScriptSystem::Impl::report_pending_exception(const std::string& entityId, const std::string& where) {
    JSValue exc = JS_GetException(ctx);
    ScriptError e = error_from_exception(exc, entityId, where);
    JS_FreeValue(ctx, exc);
    record_error(std::move(e), where);
}

// ---------------------------------------------------------------------------------------------------------------------
// Calling JS from C++
// ---------------------------------------------------------------------------------------------------------------------
JSValue ScriptSystem::Impl::call(const std::string& label, const std::string& entityId, JSValueConst fn,
                                 JSValueConst thisVal, std::initializer_list<JSValue> args, bool* failed,
                                 double limitSeconds, bool quiet) {
    if (failed) *failed = false;
    double limit = limitSeconds < 0 ? callbackLimit : limitSeconds;
    auto debugEntry = debug_entry(*this);
    const size_t depth = push_guard(label, limit);
    std::vector<JSValueConst> av(args.begin(), args.end());
    timedOut = false;
    lastCallTimedOut = false;
    JSValue r = JS_Call(ctx, fn, thisVal, static_cast<int>(av.size()), av.data());
    pop_guard(depth);
    if (JS_IsException(r)) {
        if (failed) *failed = true;
        if (timedOut && timedOutDepth < depth && !debug_session_ended()) {
            // The caller's time ran out (a test calling game.step), not this callback's: the caller reports it.
            JS_FreeValue(ctx, JS_GetException(ctx));
            return JS_UNDEFINED;
        }
        if (timedOut) {
            timedOut = false;
            lastCallTimedOut = true;
            JSValue exc = JS_GetException(ctx);
            JS_FreeValue(ctx, exc);
            if (debug_session_ended()) return JS_UNDEFINED;  // stopped by terminate, not slow
            ScriptError e;
            // A JS guard inside this call ran out first (a timer callback, a world.on listener): name that one.
            const bool inner = timedOutDepth > depth && !timedOutLabel.empty();
            e.message = std::format("script took too long (> {:g} s) in {}", inner ? timedOutSeconds : limit,
                                    inner ? timedOutLabel : label);
            e.file = label;
            e.entityId = entityId;
            // Use the behaviour's file when the label is "path#method".
            size_t hash = label.find('#');
            if (hash != std::string::npos) e.file = label.substr(0, hash);
            if (!quiet) record_error(std::move(e), label);
        } else if (quiet) {
            // caller inspects the pending exception itself
            return JS_EXCEPTION;
        } else {
            report_pending_exception(entityId, label);
        }
        return JS_UNDEFINED;
    }
    return r;
}

// `profile`: the behaviour the method belongs to; when the profiler is on, the call (only if the method exists) is charged to its class.
JSValue ScriptSystem::Impl::call_method(const std::string& label, const std::string& entityId, JSValueConst obj,
                                        const char* method, std::initializer_list<JSValue> args, bool* failed,
                                        const Behaviour* profile) {
    if (failed) *failed = false;
    JSValue fn = JS_GetPropertyStr(ctx, obj, method);
    if (JS_IsException(fn)) {
        if (failed) *failed = true;
        report_pending_exception(entityId, label);
        return JS_UNDEFINED;
    }
    if (!JS_IsFunction(ctx, fn)) {
        JS_FreeValue(ctx, fn);
        if (failed) *failed = false;
        return JS_UNDEFINED;
    }
    std::optional<ProfBehaviourScope> prof;
    if (profile) prof.emplace(profile->className, profile->path);
    JSValue r = call(label, entityId, fn, obj, args, failed);
    JS_FreeValue(ctx, fn);
    return r;
}

// ---------------------------------------------------------------------------------------------------------------------
// JSON conversion
// ---------------------------------------------------------------------------------------------------------------------
Json ScriptSystem::Impl::to_json(JSValueConst v) {
    if (JS_IsUndefined(v) || JS_IsNull(v)) return Json(nullptr);
    if (JS_IsBool(v)) return Json(JS_ToBool(ctx, v) != 0);
    if (JS_IsNumber(v)) {
        double d = 0;
        JS_ToFloat64(ctx, &d, v);
        if (std::floor(d) == d && std::fabs(d) < 9e15) return Json(static_cast<long long>(d));
        return Json(d);
    }
    if (JS_IsString(v)) {
        size_t len = 0;
        const char* s = JS_ToCStringLen(ctx, &len, v);
        Json j(std::string(s ? s : "", len));
        if (s) JS_FreeCString(ctx, s);
        return j;
    }
    JSValue s = JS_JSONStringify(ctx, v, JS_UNDEFINED, JS_UNDEFINED);
    if (JS_IsException(s)) {
        JSValue exc = JS_GetException(ctx);
        JS_FreeValue(ctx, exc);
        return Json(nullptr);
    }
    if (JS_IsUndefined(s)) return Json(nullptr);
    size_t len = 0;
    const char* text = JS_ToCStringLen(ctx, &len, s);
    Json j = Json::parse(std::string_view(text ? text : "null", text ? len : 4), nullptr, false);
    if (text) JS_FreeCString(ctx, text);
    JS_FreeValue(ctx, s);
    if (j.is_discarded()) return Json(nullptr);
    return j;
}

JSValue ScriptSystem::Impl::from_json(const Json& j) {
    switch (j.type()) {
        case Json::value_t::null: return JS_NULL;
        case Json::value_t::boolean: return JS_NewBool(ctx, j.get<bool>());
        case Json::value_t::number_integer: return JS_NewInt64(ctx, j.get<long long>());
        case Json::value_t::number_unsigned: return JS_NewInt64(ctx, static_cast<long long>(j.get<unsigned long long>()));
        case Json::value_t::number_float: return JS_NewFloat64(ctx, j.get<double>());
        case Json::value_t::string: {
            const std::string& s = j.get_ref<const std::string&>();
            return JS_NewStringLen(ctx, s.data(), s.size());
        }
        default: break;
    }
    std::string text = j.dump();
    return JS_ParseJSON(ctx, text.c_str(), text.size(), "<json>");
}

// ---------------------------------------------------------------------------------------------------------------------
// Modules
// ---------------------------------------------------------------------------------------------------------------------
std::string ScriptSystem::Impl::module_file(const std::string& normalized) const {
    size_t q = normalized.find("?v=");
    return q == std::string::npos ? normalized : normalized.substr(0, q);
}

std::string ScriptSystem::Impl::module_name_for(const std::string& path) const {
    auto it = versions.find(path);
    if (it == versions.end() || it->second == 0) return path;
    return path + "?v=" + std::to_string(it->second);
}

std::string ScriptSystem::Impl::normalize_module(const std::string& base, const std::string& spec, std::string* err) {
    if (spec == "factoria" || spec == "factoria:test") return spec;
    std::string basePath = module_file(base);
    // check_syntax compiles under the name "<syntax>/<project path>": resolve imports as for the real module.
    const bool syntaxBase = basePath.rfind("<syntax>/", 0) == 0;
    if (syntaxBase) basePath = basePath.substr(9);
    bool baseIsProject = !basePath.empty() && basePath[0] != '<' && basePath != "factoria" && basePath != "factoria:test";
    std::string joined;
    if (spec.rfind("./", 0) == 0 || spec.rfind("../", 0) == 0) {
        if (!baseIsProject) {
            joined = spec;  // no importing module (REPL, entry): relative to the project root
        } else {
            std::string dir = fs::parent(basePath);
            joined = dir.empty() ? spec : dir + "/" + spec;
        }
    } else {
        joined = spec;
        if (!joined.empty() && joined[0] == '/' && !fs::is_absolute(joined)) joined.erase(0, 1);
    }
    auto norm = fs::normalize_checked(joined);
    if (!norm) {
        if (err)
            *err = std::format("cannot resolve import \"{}\"{}: {}", spec,
                               baseIsProject ? " in '" + basePath + "'" : std::string(), norm.error().to_string());
        return {};
    }
    std::string path = *norm;
    if (path.find('*') != std::string::npos) {
        // A glob import of JSON data: `import tables from "../data/dialogue/*.json"`. Only the file name may hold `*`.
        const std::string dir = fs::parent(path), pattern = fs::filename(path);
        if (dir.find('*') != std::string::npos || pattern.find("**") != std::string::npos ||
            fs::extension(pattern) != ".json") {
            if (err)
                *err = std::format("cannot resolve import \"{}\"{}: a glob import takes `*` in the file name only and names "
                                   "JSON data, like \"../data/dialogue/*.json\" (no `**`, no `*` in a folder, no other extension)",
                                   spec, baseIsProject ? " in '" + basePath + "'" : std::string());
            return {};
        }
    } else if (!fs::exists(path) && fs::extension(path).empty() && fs::exists(path + ".js")) path += ".js";
    if (baseIsProject && !syntaxBase) {
        importers[path].insert(basePath);
    }
    std::string name = module_name_for(path);
    if (!firstImporter.count(name)) firstImporter[name] = baseIsProject ? basePath : std::string();
    return name;
}

JSModuleDef* ScriptSystem::Impl::load_module(const char* cname) {
    std::string name = cname;
    if (name == "factoria" || name == "factoria:test") return make_builtin_module(name);
    std::string file = module_file(name);
    if (file.find('*') != std::string::npos) return load_glob_module(name, file);
    auto text = fs::read_text(file);
    if (!text) {
        std::string from = firstImporter.count(name) && !firstImporter[name].empty()
                               ? " (imported from '" + firstImporter[name] + "')"
                               : "";
        JS_ThrowReferenceError(ctx, "Cannot load module '%s'%s: %s", file.c_str(), from.c_str(),
                               text.error().to_string().c_str());
        return nullptr;
    }
    if (fs::extension(file) == ".json") {
        // JSON data module: `import levels from "./levels.json"` -> default export = the parsed data.
        auto parsed = parse_json(*text, file);  // "file:LINE:COL: invalid JSON: ..." + hint
        if (!parsed.ok()) {
            brokenData = BrokenData{file, parsed.error()};
            JS_ThrowSyntaxError(ctx, "%s", parsed.error().to_string().c_str());
            return nullptr;
        }
        std::string src = "export default " + *text + ";";
        JSValue jf = JS_Eval(ctx, src.c_str(), src.size(), name.c_str(), JS_EVAL_TYPE_MODULE | JS_EVAL_FLAG_COMPILE_ONLY);
        if (JS_IsException(jf)) return nullptr;
        auto* jm = static_cast<JSModuleDef*>(JS_VALUE_GET_PTR(jf));
        JS_FreeValue(ctx, jf);
        everLoaded.insert(file);
        moduleMtime[file] = fs::modified_time(file);
        return jm;
    }
    JSValue func;
    if (is_script_bytecode(*text)) {
        // A script a `--release` export compiled (fa/script/bytecode.h): same module, no parsing. Whatever is wrong with it
        // (another FactorIA or QuickJS version, a damaged file) is a teaching error, never a crash.
        auto fail = [&](const std::string& why, const std::string& hint) -> JSModuleDef* {
            // JS_ThrowReferenceError formats into a 256 byte buffer, which would cut the hint, the part that matters: set the
            // message of the error whole.
            JS_ThrowReferenceError(ctx, "Cannot load module '%s'", file.c_str());
            JSValue exc = JS_GetException(ctx);
            const std::string message = why + " (hint: " + hint + ")";
            JS_DefinePropertyValueStr(ctx, exc, "message", JS_NewString(ctx, message.c_str()), JS_PROP_WRITABLE | JS_PROP_CONFIGURABLE);
            JS_Throw(ctx, exc);
            return nullptr;
        };
        auto payload = script_bytecode_payload(*text, file);
        if (!payload.ok()) return fail(payload.error().message, payload.error().hint);
        func = JS_ReadObject(ctx, reinterpret_cast<const uint8_t*>(payload->data()), payload->size(), JS_READ_OBJ_BYTECODE);
        if (JS_IsException(func)) {
            JSValue exc = JS_GetException(ctx);
            const char* what = JS_ToCString(ctx, exc);
            std::string why = what ? what : "unreadable";
            if (what) JS_FreeCString(ctx, what);
            JS_FreeValue(ctx, exc);
            return fail("Cannot load module '" + file + "': its compiled code cannot be read (" + why +
                            "); it is damaged or was compiled by another QuickJS",
                        "Export the game again with this FactorIA version (`factoria export --release`).");
        }
        if (JS_VALUE_GET_TAG(func) != JS_TAG_MODULE) {
            JS_FreeValue(ctx, func);
            return fail("Cannot load module '" + file + "': it is compiled code but not a module",
                        "Export the game again with this FactorIA version.");
        }
    } else {
        // Debug mode: the debugger's instrumenter rewrites the module (statement hooks, frames); when it cannot, the original
        // source runs (and its breakpoints stay unverified).
        std::string instrumented;
        int mid = 0;
        std::shared_ptr<const ScriptDebugInfo> info;
        if (debugger && fs::extension(file) == ".js") {
            ScriptDebugger::Impl& D = debugger->impl();
            std::string project = strip_versions(name);
            mid = D.register_module(project, name);
            auto r = D.instrument(project, *text, mid);
            if (r.ok()) {
                instrumented = std::move(r.value().code);
                info = std::make_shared<const ScriptDebugInfo>(std::move(r.value().info));
            } else {
                mid = 0;
                D.client.output("stderr", "debugger: cannot instrument " + project + ": " + r.error().message +
                                              "; running it without breakpoints",
                                project, 0);
            }
        }
        const std::string& code = info ? instrumented : *text;
        func = JS_Eval(ctx, code.c_str(), code.size(), name.c_str(), JS_EVAL_TYPE_MODULE | JS_EVAL_FLAG_COMPILE_ONLY);
        if (info && !JS_IsException(func)) debugger->impl().module_loaded(mid, info);
    }
    if (JS_IsException(func)) return nullptr;
    auto* m = static_cast<JSModuleDef*>(JS_VALUE_GET_PTR(func));
    JS_FreeValue(ctx, func);
    everLoaded.insert(file);
    moduleMtime[file] = fs::modified_time(file);
    return m;
}

// `import tables from "../data/dialogue/*.json"`: the default export is an object keyed by file name ("ch1.json"), in sorted
// order, of the parsed files directly in that folder. The module is "imported" by every matched file, so editing one reloads it
// (a file added later is seen on the next start). In an exported game the folder listing comes from game.pak.
JSModuleDef* ScriptSystem::Impl::load_glob_module(const std::string& name, const std::string& file) {
    auto matches = [](std::string_view pat, std::string_view str) {  // `*` = any run of characters (greedy with backtracking)
        size_t p = 0, s = 0, star = std::string_view::npos, mark = 0;
        while (s < str.size()) {
            if (p < pat.size() && pat[p] == '*') { star = p++; mark = s; }
            else if (p < pat.size() && pat[p] == str[s]) { ++p; ++s; }
            else if (star != std::string_view::npos) { p = star + 1; s = ++mark; }
            else return false;
        }
        while (p < pat.size() && pat[p] == '*') ++p;
        return p == pat.size();
    };
    const std::string dir = fs::parent(file), pattern = fs::filename(file);
    std::string src = "export default {";
    bool first = true;
    std::vector<std::string> used;
    for (const std::string& f : fs::list(dir, false, ".json")) {
        const std::string base = fs::filename(f);
        if (!matches(pattern, base)) continue;
        auto text = fs::read_text(f);
        if (!text) {
            JS_ThrowReferenceError(ctx, "Cannot load module '%s': %s", f.c_str(), text.error().to_string().c_str());
            return nullptr;
        }
        auto parsed = parse_json(*text, f);
        if (!parsed.ok()) {
            brokenData = BrokenData{f, parsed.error()};
            JS_ThrowSyntaxError(ctx, "%s", parsed.error().to_string().c_str());
            return nullptr;
        }
        src += (first ? "" : ",") + Json(base).dump() + ":" + *text;
        first = false;
        used.push_back(f);
    }
    src += "};";
    JSValue jf = JS_Eval(ctx, src.c_str(), src.size(), name.c_str(), JS_EVAL_TYPE_MODULE | JS_EVAL_FLAG_COMPILE_ONLY);
    if (JS_IsException(jf)) return nullptr;
    auto* jm = static_cast<JSModuleDef*>(JS_VALUE_GET_PTR(jf));
    JS_FreeValue(ctx, jf);
    everLoaded.insert(file);
    moduleMtime[file] = fs::modified_time(file);
    for (const std::string& f : used) {
        importers[f].insert(file);
        everLoaded.insert(f);
        moduleMtime[f] = fs::modified_time(f);
    }
    return jm;
}

namespace {
int builtin_init(JSContext* ctx, JSModuleDef* m) {
    auto* I = impl_of(ctx);
    const char* name = JS_AtomToCString(ctx, JS_GetModuleName(ctx, m));
    bool isTest = name && std::string_view(name) == "factoria:test";
    if (name) JS_FreeCString(ctx, name);
    JSValueConst ns = isTest ? I->testApi.get() : I->factoria.get();
    JSPropertyEnum* tab = nullptr;
    uint32_t n = 0;
    if (JS_GetOwnPropertyNames(ctx, &tab, &n, ns, JS_GPN_STRING_MASK | JS_GPN_ENUM_ONLY) < 0) return -1;
    for (uint32_t i = 0; i < n; ++i) {
        const char* key = JS_AtomToCString(ctx, tab[i].atom);
        JSValue v = JS_GetProperty(ctx, ns, tab[i].atom);
        JS_SetModuleExport(ctx, m, key, v);
        JS_FreeCString(ctx, key);
    }
    JS_SetModuleExport(ctx, m, "default", JS_DupValue(ctx, ns));
    JS_FreePropertyEnum(ctx, tab, n);
    return 0;
}
}  // namespace

JSModuleDef* ScriptSystem::Impl::make_builtin_module(const std::string& name) {
    JSModuleDef* m = JS_NewCModule(ctx, name.c_str(), builtin_init);
    if (!m) return nullptr;
    JSValueConst ns = name == "factoria:test" ? testApi.get() : factoria.get();
    JSPropertyEnum* tab = nullptr;
    uint32_t n = 0;
    if (JS_GetOwnPropertyNames(ctx, &tab, &n, ns, JS_GPN_STRING_MASK | JS_GPN_ENUM_ONLY) < 0) return nullptr;
    for (uint32_t i = 0; i < n; ++i) {
        const char* key = JS_AtomToCString(ctx, tab[i].atom);
        JS_AddModuleExport(ctx, m, key);
        JS_FreeCString(ctx, key);
    }
    JS_AddModuleExport(ctx, m, "default");
    JS_FreePropertyEnum(ctx, tab, n);
    return m;
}

Result<JSValue> ScriptSystem::Impl::import_module(const std::string& path, ScriptError* detail) {
    std::string err;
    std::string name = normalize_module("<import>", path, &err);
    if (name.empty()) return Error{err, "Use project-relative paths such as \"scripts/player.js\"."};
    auto cached = namespaces.find(name);
    if (cached != namespaces.end()) return JS_DupValue(ctx, cached->second.get());

    Json quoted = name;
    std::string src = "import * as m from " + quoted.dump() + "; globalThis.__fa_import = m;";
    auto debugEntry = debug_entry(*this);
    const size_t depth = push_guard("loading " + path, 10.0);
    timedOut = false;
    JSValue r = JS_Eval(ctx, src.c_str(), src.size(), "<import>", JS_EVAL_TYPE_MODULE);
    pop_guard(depth);
    auto fail = [&](JSValue exc) -> Result<JSValue> {
        ScriptError e = error_from_exception(exc, "", path);
        JS_FreeValue(ctx, exc);
        if (timedOut) {
            timedOut = false;
            e.message = debug_session_ended() ? "loading " + path + " was stopped because the debug session ended"
                                              : "script took too long (> 10 s) while loading " + path;
            e.file = path;
        }
        std::string where = e.file.empty() || e.file == "<import>" ? path : e.file;
        if (detail) {
            *detail = e;
            detail->file = where;
        }
        std::string msg = where;
        if (e.line > 0) msg += ":" + std::to_string(e.line) + (e.column > 0 ? ":" + std::to_string(e.column) : "");
        msg += ": " + e.message;
        return Error{msg, hint_for(e.message)};
    };
    if (JS_IsException(r)) return fail(JS_GetException(ctx));
    if (JS_PromiseState(ctx, r) != JS_PROMISE_NOT_A_PROMISE) {
        run_jobs();
        switch (JS_PromiseState(ctx, r)) {
            case JS_PROMISE_REJECTED: {
                JSValue reason = JS_PromiseResult(ctx, r);
                JS_FreeValue(ctx, r);
                return fail(reason);
            }
            case JS_PROMISE_PENDING:
                JS_FreeValue(ctx, r);
                return Error{"module '" + path + "' uses top-level await on something that never resolves",
                             "Remove top-level await from gameplay modules."};
            default: break;
        }
    }
    JS_FreeValue(ctx, r);
    JSValue global = JS_GetGlobalObject(ctx);
    JSValue ns = JS_GetPropertyStr(ctx, global, "__fa_import");
    JSAtom atom = JS_NewAtom(ctx, "__fa_import");
    JS_DeleteProperty(ctx, global, atom, 0);
    JS_FreeAtom(ctx, atom);
    JS_FreeValue(ctx, global);
    if (!JS_IsObject(ns)) {
        JS_FreeValue(ctx, ns);
        return Error{"module '" + path + "' did not produce a namespace", ""};
    }
    namespaces[name] = JsVal(ctx, JS_DupValue(ctx, ns));
    everLoaded.insert(module_file(name));
    return ns;
}

std::vector<std::string> ScriptSystem::Impl::bump_module_versions(const std::string& path) {
    std::set<std::string> affected;
    std::vector<std::string> work{path};
    while (!work.empty()) {
        std::string p = work.back();
        work.pop_back();
        if (!affected.insert(p).second) continue;
        auto it = importers.find(p);
        if (it != importers.end())
            for (const auto& imp : it->second) work.push_back(imp);
    }
    for (const auto& p : affected) {
        namespaces.erase(module_name_for(p));
        versions[p] += 1;
    }
    return {affected.begin(), affected.end()};
}

JSClassID g_navHandleClass = 0;
JSClassID g_debugFrameClass = 0;

void reserve_class_ids(JSRuntime* rt) {
    JSClassID nav = 0, frame = 0;
    JS_NewClassID(rt, &nav);
    JS_NewClassID(rt, &frame);
    g_navHandleClass = nav;
    g_debugFrameClass = frame;
}

// ---------------------------------------------------------------------------------------------------------------------
// init / shutdown
// ---------------------------------------------------------------------------------------------------------------------
bool ScriptSystem::Impl::init(ScriptHost& h, std::string* error) {
    host = &h;
    ensure_builtin_components();
    rt = JS_NewRuntime();
    if (!rt) {
        if (error) *error = "failed to create the JavaScript runtime";
        return false;
    }
    reserve_class_ids(rt);
    JS_SetMemoryLimit(rt, size_t(768) * 1024 * 1024);
    JS_SetMaxStackSize(rt, size_t(2) * 1024 * 1024);
    JS_SetInterruptHandler(rt, interrupt_cb, this);
    JS_SetModuleLoaderFunc(rt, normalize_cb, loader_cb, this);
    JS_SetHostPromiseRejectionTracker(rt, rejection_cb, this);
    ctx = JS_NewContext(rt);
    if (!ctx) {
        if (error) *error = "failed to create the JavaScript context";
        return false;
    }
    JS_SetContextOpaque(ctx, this);
    install_quickjs_fixes(ctx);

    Json proj = h.project_settings();
    if (proj.is_object() && proj.contains("seed") && proj["seed"].is_number()) seed = proj["seed"].get<std::uint64_t>();

    JSValue N = JS_NewObject(ctx);
    install_natives(N);
    native = JsVal(ctx, N);

    std::string_view src = embedded_script("factoria.js");
    if (src.empty()) {
        if (error) *error = "internal error: factoria.js prelude is missing from the binary";
        return false;
    }
    JSValue fnv = JS_Eval(ctx, src.data(), src.size(), "<factoria>", JS_EVAL_TYPE_GLOBAL);
    if (JS_IsException(fnv)) {
        JSValue exc = JS_GetException(ctx);
        ScriptError e = error_from_exception(exc, "", "<factoria>");
        JS_FreeValue(ctx, exc);
        if (error) *error = "script prelude failed to compile: " + e.to_string();
        return false;
    }
    JSValue hv = JS_Call(ctx, fnv, JS_UNDEFINED, 1, &N);
    JS_FreeValue(ctx, fnv);
    if (JS_IsException(hv)) {
        JSValue exc = JS_GetException(ctx);
        ScriptError e = error_from_exception(exc, "", "<factoria>");
        JS_FreeValue(ctx, exc);
        if (error) *error = "script prelude failed to run: " + e.to_string() + "\n" + e.stack;
        return false;
    }
    hooks = JsVal(ctx, hv);
    factoria = JsVal(ctx, JS_GetPropertyStr(ctx, hooks.get(), "factoria"));
    testApi = JsVal(ctx, JS_GetPropertyStr(ctx, hooks.get(), "test"));

    // Global conveniences.
    JSValue global = JS_GetGlobalObject(ctx);
    JS_DefinePropertyValueStr(ctx, global, "factoria", JS_DupValue(ctx, factoria.get()), JS_PROP_CONFIGURABLE | JS_PROP_WRITABLE);
    JS_FreeValue(ctx, global);

    if (debugger) debugger->impl().attach(*this);

    observerId = h.world().on_destroy([this](Entity e) { on_entity_destroyed(e); });
    initialized = true;
    // Tooltips that are functions (ui.setTooltip, ui.setWorldTooltip): the UI asks while the pointer rests, from update().
    if (UiSystem* ui = h.ui()) {
        auto ask = [this](const char* label, const char* method, JSValue arg0, JSValue arg1) {
            if (!initialized) {
                JS_FreeValue(ctx, arg0);
                JS_FreeValue(ctx, arg1);
                return Json(nullptr);
            }
            ProfBehaviourScope prof(kProfOtherName, kProfNoPath);
            JSValue r = call_method(label, "", hooks.get(), method, {arg0, arg1});
            Json out = to_json(r);
            JS_FreeValue(ctx, r);
            return out;
        };
        UiTooltipHooks th;
        th.widget = [this, ask](Entity e) {
            return ask("ui.setTooltip function", "tooltipFor", JS_NewFloat64(ctx, static_cast<double>(e.bits())), JS_UNDEFINED);
        };
        th.world = [this, ask](Vec2 p) { return ask("ui.setWorldTooltip function", "worldTooltip", JS_NewFloat64(ctx, p.x), JS_NewFloat64(ctx, p.y)); };
        ui->set_tooltip_hooks(std::move(th));
        // Drop targets that are functions (ui.setDropTarget(widget, fn)): asked while a drag is over them.
        UiDropHooks dh;
        dh.widget = [this](Entity e, const Json& drag) {
            if (!initialized) return false;
            ProfBehaviourScope prof(kProfOtherName, kProfNoPath);
            JSValue info = from_json(drag);
            JSValue r = call_method("ui.setDropTarget function", "", hooks.get(), "dropAccepts", {JS_NewFloat64(ctx, static_cast<double>(e.bits())), info});
            const bool ok = JS_ToBool(ctx, r) > 0;
            JS_FreeValue(ctx, r);
            JS_FreeValue(ctx, info);
            return ok;
        };
        dh.world = [this](const Json& drag) {
            if (!initialized) return false;
            ProfBehaviourScope prof(kProfOtherName, kProfNoPath);
            JSValue info = from_json(drag);
            JSValue r = call_method("ui.setWorldDropTarget function", "", hooks.get(), "worldDropAccepts", {info, JS_UNDEFINED});
            const bool ok = JS_ToBool(ctx, r) > 0;
            JS_FreeValue(ctx, r);
            JS_FreeValue(ctx, info);
            return ok;
        };
        ui->set_drop_hooks(std::move(dh));
    }
    reload_tools();
    return true;
}

void ScriptSystem::Impl::shutdown() {
    if (!initialized && !rt) return;
    storage_drain();  // a setAsync write still running finishes before the process can end
    unregister_tools();
    if (host && observerId >= 0) host->world().remove_observer(observerId);
    observerId = -1;
    if (host)
        if (UiSystem* ui = host->ui()) {
            ui->set_tooltip_hooks({});
            ui->set_drop_hooks({});
        }
    runtimeTextures.clear();  // the handles die with the context; the renderer frees its copies with its own asset cache
    behaviours.clear();  // JsVal destructors free values
    byEntity.clear();
    namespaces.clear();
    tools.clear();
    for (auto& r : pendingRejections) { JS_FreeValue(ctx, r.promise); JS_FreeValue(ctx, r.reason); }
    pendingRejections.clear();
    guards.clear();
    hooks.reset();
    factoria.reset();
    testApi.reset();
    native.reset();
    if (debugger) debugger->impl().detach();
    if (ctx) JS_FreeContext(ctx);
    ctx = nullptr;
    if (rt) JS_FreeRuntime(rt);
    rt = nullptr;
    initialized = false;
}

// ---------------------------------------------------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------------------------------------------------
ScriptSystem::ScriptSystem() : impl_(std::make_unique<Impl>()) { impl_->owner = this; }
ScriptSystem::~ScriptSystem() {
    if (impl_) impl_->shutdown();
}

void ScriptSystem::set_debugger(std::shared_ptr<ScriptDebugger> debugger) { impl_->debugger = std::move(debugger); }
void ScriptSystem::set_callback_limit(double seconds) { impl_->callbackLimit = seconds; }
void ScriptSystem::set_plugins(std::vector<ScriptPlugin> plugins) { impl_->plugins = std::move(plugins); }
bool ScriptSystem::init(ScriptHost& host, std::string* error) { return impl_->init(host, error); }
void ScriptSystem::shutdown() { impl_->shutdown(); }

void ScriptSystem::on_scene_loaded() {
    if (impl_->host) impl_->host->world().bump_scene_generation();  // every load, also a reload of the same scene
    if (!impl_->initialized) return;
    impl_->drop_all_behaviours();
    impl_->call_method("scene reset", "", impl_->hooks.get(), "resetScene", {});
    impl_->run_jobs();
    // entity.behaviour exists right after a scene load; onStart runs before the first update.
    impl_->construct_all();
    impl_->run_jobs();
    impl_->preload.scene_loaded();
}

Json platform_answer_json(const PlatformAnswer& a) {
    Json j = Json::object({{"id", a.id}, {"method", a.method}, {"ok", a.ok}});
    if (a.ok) j["result"] = a.result;
    else j["error"] = Json::object({{"code", a.error.code}, {"message", a.error.message}, {"hint", a.error.hint}});
    return j;
}

void ScriptSystem::dispatch_platform() {
    Impl& I = *impl_;
    if (!I.initialized || !I.host) return;
    if (I.debugger) I.debugger->impl().frame_start();  // terminate request, then the client's poll
    I.storageWriter.pump();  // storage.setAsync without a worker thread (the web, memory storage): its writes run here, between frames
    if (std::vector<storage_files::Job> done = I.storageWriter.take_done(); !done.empty()) {
        Json list = Json::array();
        for (const storage_files::Job& j : done) {
            auto m = I.storageMeta.find(j.key);
            if (m != I.storageMeta.end() && m->second.compressed == j.compress && m->second.bytes < 0) m->second.bytes = static_cast<std::int64_t>(j.bytes);
            if (j.persist) {
                if (j.ok) fs::user_dir_changed();
                else log(LogLevel::Warn, "script", "storage.setAsync could not write " + j.file.string() + " for key '" + j.key + "': " + j.error);
            }
            list.push_back(Json::object({{"id", j.id}, {"ok", j.ok}, {"error", j.error}, {"bytes", j.bytes}}));
        }
        JSValue lv = I.from_json(list);
        JSValue fn = JS_GetPropertyStr(I.ctx, I.hooks.get(), "storageDeliver");
        JSValue r = I.call("storage.setAsync", "", fn, I.hooks.get(), {lv});
        JS_FreeValue(I.ctx, r);
        JS_FreeValue(I.ctx, fn);
        JS_FreeValue(I.ctx, lv);
        I.run_jobs();
    }
    if (I.preload.active()) {  // scene.preload / assets.preload: this frame's share of the work
        const std::vector<Preloader::Update> updates = I.preload.tick(I.host->preload_time_budget_ms());
        if (!updates.empty()) {
            Json list = Json::array();
            for (const Preloader::Update& u : updates)
                list.push_back(Json::object({{"id", u.id}, {"done", u.done}, {"total", u.total}, {"bytes", u.bytes},
                                             {"finished", u.finished}, {"error", u.error}, {"hint", u.hint}}));
            JSValue lv = I.from_json(list);
            JSValue fn = JS_GetPropertyStr(I.ctx, I.hooks.get(), "preloadDeliver");
            JSValue r = I.call("preload progress", "", fn, I.hooks.get(), {lv});
            JS_FreeValue(I.ctx, r);
            JS_FreeValue(I.ctx, fn);
            JS_FreeValue(I.ctx, lv);
            I.run_jobs();
        }
    }
    PlatformServices* services = I.host->platform_services();
    if (!services) return;
    const std::vector<PlatformAnswer> answers = services->take_answers();
    const std::vector<PlatformEvent> events = services->take_events();
    if (answers.empty() && events.empty()) return;
    Json answersJson = Json::array(), eventsJson = Json::array();
    for (const PlatformAnswer& a : answers) answersJson.push_back(platform_answer_json(a));
    for (const PlatformEvent& e : events) eventsJson.push_back(Json::object({{"name", e.name}, {"data", e.data}}));
    JSValue av = I.from_json(answersJson), ev = I.from_json(eventsJson);
    JSValue fn = JS_GetPropertyStr(I.ctx, I.hooks.get(), "platformDeliver");
    JSValue r = I.call("platform answers", "", fn, I.hooks.get(), {av, ev});
    JS_FreeValue(I.ctx, r);
    JS_FreeValue(I.ctx, fn);
    JS_FreeValue(I.ctx, av);
    JS_FreeValue(I.ctx, ev);
    I.run_jobs();
}

void ScriptSystem::dispatch_back() {
    Impl& I = *impl_;
    if (!I.host || !I.host->input().back_pressed()) return;
    bool consumed = false;
    if (I.initialized) {
        JSValue fn = JS_GetPropertyStr(I.ctx, I.hooks.get(), "back");
        ProfBehaviourScope prof(kProfOtherName, kProfNoPath);
        JSValue r = I.call("input.onBack", "", fn, I.hooks.get(), {});
        consumed = JS_ToBool(I.ctx, r) > 0;
        JS_FreeValue(I.ctx, r);
        JS_FreeValue(I.ctx, fn);
        I.run_jobs();
    }
    if (!consumed) I.request_quit();
}

void ScriptSystem::dispatch_gamepads() {
    Impl& I = *impl_;
    if (!I.host) return;
    const std::vector<GamepadEvent> events = I.host->input().take_gamepad_events();
    if (!I.initialized || events.empty()) return;
    for (const GamepadEvent& e : events) {
        Json data = Json::object({{"slot", e.slot}, {"id", e.info.id}, {"name", e.info.name}, {"type", gamepad_type_name(e.info.type)}});
        I.host->world().events().game.push_back(
            GameEvent{e.connected ? "app.gamepadConnected" : "app.gamepadDisconnected", std::move(data), kNullEntity});
    }
    dispatch_events();
}

void ScriptSystem::update(float dt) {
    if (!impl_->initialized) return;
    impl_->lastDt = dt;
    impl_->host->speech().update();
    impl_->sync();
    float scaled = static_cast<float>(dt * impl_->timeScale);
    impl_->service_call("serviceTick", {JS_NewFloat64(impl_->ctx, dt)});  // analytics and remote config: the engine clock, never scaled
    if (impl_->quitDeferred) impl_->update_quit_wait(dt);
    if (impl_->timeScale > 0.0) {
        {
            ProfBehaviourScope prof(kProfOtherName, kProfNoPath);
            impl_->call_method("timers", "", impl_->hooks.get(), "tick", {JS_NewFloat64(impl_->ctx, scaled)});
        }
        impl_->run_callbacks("onUpdate", scaled, false);
    } else {
        impl_->run_callbacks("onUpdate", dt, true);  // paused: only runWhilePaused behaviours, with the real dt
    }
    impl_->run_jobs();
}

void ScriptSystem::fixed_update(float dt) {
    if (!impl_->initialized) return;
    impl_->sync();
    if (impl_->timeScale > 0.0) impl_->run_callbacks("onFixedUpdate", static_cast<float>(dt * impl_->timeScale), false);
    impl_->run_jobs();
}

void ScriptSystem::late_update(float dt) {
    if (!impl_->initialized) return;
    if (impl_->timeScale > 0.0) impl_->run_callbacks("onLateUpdate", static_cast<float>(dt * impl_->timeScale), false);
    else impl_->run_callbacks("onLateUpdate", dt, true);
    impl_->run_jobs();
}

void ScriptSystem::settle_activation() {
    if (!impl_->initialized) return;
    impl_->sync();
    impl_->run_jobs();
}

Result<Json> ScriptSystem::eval(std::string_view code) {
    if (!impl_->initialized) return Error{"script system is not initialized", ""};
    return impl_->eval(code);
}
Result<void> ScriptSystem::check_syntax(std::string_view modulePath, std::string* brokenImport) {
    if (!impl_->initialized) return Error{"script system is not initialized", ""};
    return impl_->check_syntax(modulePath, brokenImport);
}
TestReport ScriptSystem::run_tests(const std::vector<std::string>& files, std::string_view nameFilter) {
    if (!impl_->initialized) {
        TestReport r;
        r.loadErrors.push_back({"", 0, 0, "script system is not initialized", "", ""});
        return r;
    }
    return impl_->run_tests(files, nameFilter);
}
const std::vector<ScriptError>& ScriptSystem::errors() const { return impl_->errors; }
void ScriptSystem::clear_errors() {
    impl_->errors.clear();
    impl_->loggedKeys.clear();
}
std::vector<std::string> ScriptSystem::refresh_modules(bool force) {
    Impl& I = *impl_;
    std::vector<std::string> stale;
    if (!I.initialized) return stale;
    for (const std::string& f : I.everLoaded) {
        auto it = I.moduleMtime.find(f);
        if (force || it == I.moduleMtime.end() || it->second != fs::modified_time(f)) stale.push_back(f);
    }
    bool toolsAffected = false;
    for (const std::string& f : stale)
        for (const std::string& p : I.bump_module_versions(f)) {
            I.moduleMtime[p] = fs::modified_time(p);
            if (p.rfind("tools/", 0) == 0) toolsAffected = true;
        }
    clear_errors();  // before reload_tools, which may record fresh errors
    if (toolsAffected) I.reload_tools();
    return stale;
}
void ScriptSystem::reload_module(std::string_view modulePath) {
    if (impl_->initialized) impl_->reload_module(modulePath);
}
void ScriptSystem::reload_tools() {
    if (impl_->initialized) impl_->reload_tools();
}
void ScriptSystem::set_tools_changed_callback(std::function<void()> cb) { impl_->toolsChanged = std::move(cb); }

void ScriptSystem::set_storage_mode(StorageMode mode) {
    impl_->storage_drain();
    impl_->storageMeta.clear();
    impl_->storageMode = mode;
    impl_->storage = Json::object();
    impl_->storageLoaded = false;
    impl_->storageCorrupt = false;
}
StorageMode ScriptSystem::storage_mode() const { return impl_->storageMode; }

std::vector<std::string> ScriptSystem::check_props(std::string_view modulePath, const Json& props) {
    if (!impl_->initialized) return {"script system is not initialized"};
    return impl_->check_props(std::string(modulePath), props);
}
std::vector<std::string> ScriptSystem::check_hooks(std::string_view modulePath) {
    if (!impl_->initialized) return {};
    return impl_->check_hooks(std::string(modulePath));
}

Json ScriptSystem::api_manifest() const { return impl_->api_manifest(); }
std::string ScriptSystem::typescript_declarations(const SinceFn& since) const { return impl_->typescript_declarations(since); }
std::vector<std::string> ScriptSystem::script_api_keys() const { return impl_->script_api_keys(); }

double ScriptSystem::time_scale() const { return impl_->timeScale; }

CalendarDate ScriptSystem::today() const { return impl_->date; }

void ScriptSystem::set_start_date(const CalendarDate& date) { impl_->startDate = impl_->date = date; }

std::string ScriptSystem::set_date(std::string_view iso, std::optional<int> utcOffsetMinutes) {
    auto parsed = parse_calendar_date(iso, "game.setDate:");
    if (!parsed.ok()) return parsed.error().message + ". " + parsed.error().hint;
    CalendarDate d = parsed.value();
    d.utcOffsetMinutes = utcOffsetMinutes ? *utcOffsetMinutes : impl_->date.utcOffsetMinutes;
    set_clock_date(d);
    return {};
}

void ScriptSystem::set_clock_date(const CalendarDate& now) {
    Impl& I = *impl_;
    const bool newDay = now.year != I.date.year || now.month != I.date.month || now.day != I.date.day;  // not a change of offset or time
    I.date = now;
    if (!newDay || !I.initialized) return;
    I.host->world().events().game.push_back(GameEvent{"app.dayChanged", Json::object(), kNullEntity});
    dispatch_events();
}

bool ScriptSystem::app_focused() const { return impl_->appFocused; }
bool ScriptSystem::app_suspended() const { return impl_->appSuspended; }

void ScriptSystem::app_event(AppLifecycle event) {
    Impl& I = *impl_;
    if (!I.initialized) return;
    auto send = [&](const char* name) {
        I.host->world().events().game.push_back(GameEvent{name, Json::object(), kNullEntity});
        dispatch_events();
    };
    // Suspending twice, or resuming a running app, changes nothing and sends nothing (platforms repeat these events).
    switch (event) {
        case AppLifecycle::Focus:
            if (I.appFocused) return;
            I.appFocused = true;
            send("app.focus");
            break;
        case AppLifecycle::Blur:
            if (!I.appFocused) return;
            I.appFocused = false;
            send("app.blur");
            break;
        case AppLifecycle::Suspend: {
            if (I.appSuspended) return;
            I.appSuspended = true;
            send("app.suspend");  // first, so a script can open its own pause menu: that pause is then the one that stays
            I.storage_drain();  // a storage.setAsync still waiting is on disk before the app can be killed (or the web page hidden)
            I.service_call("serviceSuspend", {});  // sends the analytics events that wait
            const Json settings = I.host->project_settings();
            const bool pauseOnSuspend = !settings.is_object() || !settings.contains("pauseOnSuspend") ||
                                        !settings["pauseOnSuspend"].is_boolean() || settings["pauseOnSuspend"].get<bool>();
            if (pauseOnSuspend) {
                if (I.timeScale > 0.0) {
                    I.scaleBeforeSuspend = I.timeScale;
                    I.timeScale = 0.0;
                    I.pausedBySuspend = true;
                }
                I.host->audio().set_paused(true);
            }
            break;
        }
        case AppLifecycle::Resume:
            if (!I.appSuspended) return;
            I.appSuspended = false;
            if (I.pausedBySuspend && I.timeScale == 0.0) I.timeScale = I.scaleBeforeSuspend;
            I.pausedBySuspend = false;
            I.host->audio().set_paused(false);
            send("app.resume");
            break;
    }
}

bool ScriptSystem::close_requested() {
    Impl& I = *impl_;
    if (!I.initialized) return true;
    I.quitCancelled = false;
    I.host->world().events().game.push_back(GameEvent{"app.quit", Json::object(), kNullEntity});
    dispatch_events();
    I.storage_drain();  // the quit handlers' storage.setAsync writes land before the web flushes the save folder
    const bool cancelled = I.quitCancelled;
    I.quitCancelled = false;
    if (cancelled) return false;
    // Not cancelled: the window closes, after the analytics events that wait were sent (a request in flight holds it, 3 s at most).
    if (I.quitDeferred) return false;
    if (I.begin_quit_flush()) {
        I.quitDeferred = true;
        I.quitWaited = 0.0;
        return false;
    }
    return true;
}

void ScriptSystem::reset_app_state() {
    Impl& I = *impl_;
    I.appFocused = true;
    I.appSuspended = false;
    I.pausedBySuspend = false;
    if (I.initialized) I.host->audio().set_paused(false);
    I.date = I.startDate;
}

Json ScriptSystem::stats() const {
    const auto& I = *impl_;
    Json j = Json::object();
    int alive = 0;
    for (const auto& b : I.behaviours)
        if (!b->dead && !JS_IsUndefined(b->instance.get())) ++alive;
    j["behaviours"] = alive;
    j["modulesLoaded"] = static_cast<int>(I.everLoaded.size());
    j["tools"] = static_cast<int>(I.tools.size());
    j["errors"] = static_cast<int>(I.errors.size());
    if (I.rt) {
        JSMemoryUsage mu;
        JS_ComputeMemoryUsage(I.rt, &mu);
        j["memoryBytes"] = static_cast<long long>(mu.memory_used_size);
        j["objects"] = static_cast<long long>(mu.obj_count);
        j["strings"] = static_cast<long long>(mu.str_count);
    }
    j["timeScale"] = I.timeScale;
    return j;
}

}  // namespace fa
