// ScriptSystem: public API + runtime/module/error plumbing. Behaviours live in script_behaviours.cpp, natives in
// script_natives.cpp, tools/tests/eval in script_tools.cpp, API description in script_api.cpp.
#include <algorithm>
#include <cstring>
#include <format>

#include "fa_script_js.h"
#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "fa/scene/components.h"
#include "script_internal.h"

namespace fa {

std::string_view embedded_script(std::string_view name) {
    for (const auto& f : script_js::files())
        if (f.path == name) return f.data;
    return {};
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

void rejection_cb(JSContext* ctx, JSValueConst, JSValueConst reason, bool is_handled, void* opaque) {
    if (is_handled) return;
    auto* I = static_cast<ScriptSystem::Impl*>(opaque);
    ScriptError e = I->error_from_exception(reason, "", "unhandled promise rejection");
    e.message = "unhandled promise rejection: " + e.message;
    I->record_error(std::move(e), "promise");
    (void)ctx;
}

}  // namespace

// ---------------------------------------------------------------------------------------------------------------------
// Guard / interrupt
// ---------------------------------------------------------------------------------------------------------------------
void ScriptSystem::Impl::push_guard(const std::string& label, double seconds) {
    guards.push_back({label, std::chrono::steady_clock::now() +
                                 std::chrono::microseconds(static_cast<long long>(seconds * 1e6))});
}

void ScriptSystem::Impl::pop_guard() {
    if (!guards.empty()) guards.pop_back();
}

bool ScriptSystem::Impl::check_interrupt() {
    if (guards.empty()) return false;
    auto now = std::chrono::steady_clock::now();
    for (size_t i = guards.size(); i-- > 0;) {
        if (now > guards[i].deadline) {
            timedOut = true;
            timedOutLabel = guards[i].label;
            return true;
        }
    }
    return false;
}

void ScriptSystem::Impl::run_jobs() {
    if (!rt) return;
    for (int guardCount = 0; guardCount < 100000; ++guardCount) {
        JSContext* jctx = nullptr;
        int r = JS_ExecutePendingJob(rt, &jctx);
        if (r == 0) break;
        if (r < 0) {
            report_pending_exception("", "promise job");
        }
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
    if (has("is not a function"))
        return "Check the method name against `factoria api` / types/factoria.d.ts, and that the object is not null "
               "(entity.get(name) returns null when the component is missing).";
    if (has("cannot read property") || has("null") || has("undefined"))
        return "A value was null/undefined. world.find(id) and entity.get(name) return null when nothing matches; "
               "check before using the result.";
    if (has("not defined")) return "Import it first: import { world, input, vec2 } from \"factoria\";";
    return "";
}

}  // namespace

ScriptError ScriptSystem::Impl::error_from_exception(JSValueConst exc, const std::string& entityId,
                                                     const std::string& where) {
    ScriptError e;
    e.entityId = entityId;
    if (JS_IsObject(exc)) {
        std::string name = get_str_prop(ctx, exc, "name");
        std::string msg = get_str_prop(ctx, exc, "message");
        e.stack = strip_versions(get_str_prop(ctx, exc, "stack"));
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
        }
    } else {
        const char* s = JS_ToCString(ctx, exc);
        e.message = s ? std::string("uncaught ") + s : "uncaught exception";
        if (s) JS_FreeCString(ctx, s);
    }
    if (e.file.empty()) e.file = where;
    e.message = strip_versions(e.message);
    return e;
}

void ScriptSystem::Impl::record_error(ScriptError e, const std::string& where) {
    std::string key = e.file + ":" + std::to_string(e.line) + ":" + e.message;
    bool fresh = loggedKeys.insert(key).second;
    if (!fresh) return;
    std::string hint = hint_for(e.message);
    std::string text = e.to_string();
    if (!where.empty() && where != e.file) text += " [in " + where + "]";
    if (!hint.empty()) text += "\n  hint: " + hint;
    if (!e.stack.empty()) text += "\n" + e.stack;
    log(LogLevel::Error, "script", text);
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
    push_guard(label, limit);
    std::vector<JSValueConst> av(args.begin(), args.end());
    timedOut = false;
    lastCallTimedOut = false;
    JSValue r = JS_Call(ctx, fn, thisVal, static_cast<int>(av.size()), av.data());
    pop_guard();
    if (JS_IsException(r)) {
        if (failed) *failed = true;
        if (timedOut) {
            timedOut = false;
            lastCallTimedOut = true;
            JSValue exc = JS_GetException(ctx);
            JS_FreeValue(ctx, exc);
            ScriptError e;
            e.message = std::format("script took too long (> {:g} s) in {}", limit, label);
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

JSValue ScriptSystem::Impl::call_method(const std::string& label, const std::string& entityId, JSValueConst obj,
                                        const char* method, std::initializer_list<JSValue> args, bool* failed) {
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
    if (!fs::exists(path) && fs::extension(path).empty() && fs::exists(path + ".js")) path += ".js";
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
    JSValue func = JS_Eval(ctx, text->c_str(), text->size(), name.c_str(), JS_EVAL_TYPE_MODULE | JS_EVAL_FLAG_COMPILE_ONLY);
    if (JS_IsException(func)) return nullptr;
    auto* m = static_cast<JSModuleDef*>(JS_VALUE_GET_PTR(func));
    JS_FreeValue(ctx, func);
    everLoaded.insert(file);
    moduleMtime[file] = fs::modified_time(file);
    return m;
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
    push_guard("loading " + path, 10.0);
    timedOut = false;
    JSValue r = JS_Eval(ctx, src.c_str(), src.size(), "<import>", JS_EVAL_TYPE_MODULE);
    pop_guard();
    auto fail = [&](JSValue exc) -> Result<JSValue> {
        ScriptError e = error_from_exception(exc, "", path);
        JS_FreeValue(ctx, exc);
        if (timedOut) {
            timedOut = false;
            e.message = "script took too long (> 10 s) while loading " + path;
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

    observerId = h.world().on_destroy([this](Entity e) { on_entity_destroyed(e); });
    initialized = true;
    reload_tools();
    return true;
}

void ScriptSystem::Impl::shutdown() {
    if (!initialized && !rt) return;
    unregister_tools();
    if (host && observerId >= 0) host->world().remove_observer(observerId);
    observerId = -1;
    behaviours.clear();  // JsVal destructors free values
    byEntity.clear();
    namespaces.clear();
    tools.clear();
    hooks.reset();
    factoria.reset();
    testApi.reset();
    native.reset();
    if (ctx) JS_FreeContext(ctx);
    ctx = nullptr;
    if (rt) JS_FreeRuntime(rt);
    rt = nullptr;
    initialized = false;
}

// ---------------------------------------------------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------------------------------------------------
ScriptSystem::ScriptSystem() : impl_(std::make_unique<Impl>()) {}
ScriptSystem::~ScriptSystem() {
    if (impl_) impl_->shutdown();
}

bool ScriptSystem::init(ScriptHost& host, std::string* error) { return impl_->init(host, error); }
void ScriptSystem::shutdown() { impl_->shutdown(); }

void ScriptSystem::on_scene_loaded() {
    if (!impl_->initialized) return;
    impl_->drop_all_behaviours();
    impl_->call_method("scene reset", "", impl_->hooks.get(), "resetScene", {});
    impl_->run_jobs();
    // entity.behaviour exists right after a scene load; onStart runs before the first update.
    impl_->construct_all();
    impl_->run_jobs();
}

void ScriptSystem::update(float dt) {
    if (!impl_->initialized) return;
    impl_->lastDt = dt;
    impl_->sync();
    float scaled = static_cast<float>(dt * impl_->timeScale);
    if (impl_->timeScale > 0.0) {
        impl_->call_method("timers", "", impl_->hooks.get(), "tick", {JS_NewFloat64(impl_->ctx, scaled)});
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
    impl_->storageMode = mode;
    impl_->storage = Json::object();
    impl_->storageLoaded = false;
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
std::string ScriptSystem::typescript_declarations() const { return impl_->typescript_declarations(); }

double ScriptSystem::time_scale() const { return impl_->timeScale; }

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
