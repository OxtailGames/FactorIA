// JS tools (tools/*.js -> project.<name> commands), eval, syntax check, hot reload and the test runner.
#include <algorithm>
#include <format>

#include "fa/core/date.h"
#include "fa/core/fs.h"
#include "fa/core/hash.h"
#include "fa/core/i18n.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "fa/platform/input.h"
#include "fa/render/renderer.h"
#include "fa/script/bytecode.h"
#include <cstdio>
#include "debugger_internal.h"
#include "script_internal.h"

namespace fa {

using Impl = ScriptSystem::Impl;

namespace {

std::string sanitize_tool_name(std::string s) {
    for (char& c : s)
        if (!(std::isalnum(static_cast<unsigned char>(c)) || c == '_')) c = '_';
    return s;
}

std::string js_to_string(JSContext* ctx, JSValueConst v) {
    const char* s = JS_ToCString(ctx, v);
    std::string out = s ? s : "";
    if (s) JS_FreeCString(ctx, s);
    return out;
}

}  // namespace

// ---------------------------------------------------------------------------------------------------------------------
// Tools
// ---------------------------------------------------------------------------------------------------------------------
void Impl::unregister_tools() {
    if (!host) return;
    for (auto& [name, t] : tools) host->commands().remove(name);
    tools.clear();
}

void Impl::reload_tools() {
    if (!host || !ctx) return;
    std::set<std::string> before;
    for (auto& [name, t] : tools) before.insert(name);
    unregister_tools();

    std::vector<std::string> files = fs::list("tools", true, ".js");
    for (const std::string& file : files) {
        // Fresh evaluation every time.
        namespaces.erase(module_name_for(file));
        versions[file] += 1;
        ScriptError detail;
        auto ns = import_module(file, &detail);
        if (!ns) {
            if (detail.message.empty()) { detail.file = file; detail.message = ns.error().message; }
            record_error(detail, file);
            continue;
        }
        JSValue nsv = *ns;
        JsVal def(ctx, JS_GetPropertyStr(ctx, nsv, "default"));
        JS_FreeValue(ctx, nsv);
        auto bad = [&](const std::string& why) {
            ScriptError e;
            e.file = file;
            e.message = "tool " + why + ". A tool module must `export default { name, summary, run(args, ctx) { ... } }`";
            record_error(std::move(e), file);
        };
        if (!JS_IsObject(def.get())) { bad("has no default export object"); continue; }
        JsVal nameV(ctx, JS_GetPropertyStr(ctx, def.get(), "name"));
        JsVal runV(ctx, JS_GetPropertyStr(ctx, def.get(), "run"));
        if (!JS_IsString(nameV.get())) { bad("is missing a string `name`"); continue; }
        if (!JS_IsFunction(ctx, runV.get())) { bad("is missing a `run` function"); continue; }
        std::string name = sanitize_tool_name(js_to_string(ctx, nameV.get()));
        if (name.empty()) { bad("has an empty name"); continue; }
        std::string cname = "project." + name;
        if (host->commands().has(cname)) {
            ScriptError e;
            e.file = file;
            e.message = "tool name '" + name + "' collides with built-in command " + cname + "; rename the tool";
            record_error(std::move(e), file);
            continue;
        }
        if (tools.count(cname)) {
            ScriptError e;
            e.file = file;
            e.message = "tool name '" + name + "' is already used by " + tools[cname].file;
            record_error(std::move(e), file);
            continue;
        }
        auto str_prop = [&](const char* k) {
            JsVal v(ctx, JS_GetPropertyStr(ctx, def.get(), k));
            return JS_IsString(v.get()) ? js_to_string(ctx, v.get()) : std::string();
        };
        CommandInfo info;
        info.name = cname;
        info.summary = str_prop("summary");
        if (info.summary.empty()) info.summary = "Project tool from " + file;
        info.description = str_prop("description");
        info.category = "project";
        JsVal ro(ctx, JS_GetPropertyStr(ctx, def.get(), "readOnly"));
        info.readOnly = JS_IsUndefined(ro.get()) ? false : JS_ToBool(ctx, ro.get()) > 0;
        JsVal inputV(ctx, JS_GetPropertyStr(ctx, def.get(), "input"));
        if (JS_IsObject(inputV.get())) {
            Json schema = to_json(inputV.get());
            if (schema.is_object()) {
                if (!schema.contains("type")) schema["type"] = "object";
                if (!schema.contains("properties")) schema["properties"] = Json::object();
                info.inputSchema = std::move(schema);
            }
        }
        ToolEntry entry;
        entry.commandName = cname;
        entry.file = file;
        entry.fn = std::move(def);
        if (auto text = fs::read_text(file)) entry.hash = sha256_hex(*text).substr(0, 16);
        entry.loadedAt = iso_utc_ms(unix_time_ms_now());
        tools[cname] = std::move(entry);
        host->commands().add(std::move(info), [this, cname](const Json& args) -> Json {
            auto it = tools.find(cname);
            if (it == tools.end() || !ctx) throw CommandError("unavailable", "tool '" + cname + "' is no longer loaded", "Call project tools after the script system is initialized.");
            const std::string toolFile = it->second.file;
            // Which version of the tool file ran, so a stale tool is visible: added to an object result.
            const Json version = Json::object({{"file", toolFile}, {"hash", it->second.hash}, {"loadedAt", it->second.loadedAt}});
            auto stamp = [&version](Json j) {
                if (j.is_null()) j = Json::object();
                if (j.is_object() && !j.contains("toolVersion")) j["toolVersion"] = version;
                return j;
            };
            // Converts a thrown JS value into a CommandError. ToolError(message, hint, data) is an expected failure
            // (not a script bug): its hint and data reach the caller. Any other error is "failed".
            auto throw_js = [&](JSValueConst exc) {
                std::string kind;
                if (JS_IsObject(exc)) {
                    JsVal nm(ctx, JS_GetPropertyStr(ctx, exc, "name"));
                    if (JS_IsString(nm.get())) kind = js_to_string(ctx, nm.get());
                }
                if (kind == "ToolError") {
                    auto str = [&](const char* k) {
                        JsVal v(ctx, JS_GetPropertyStr(ctx, exc, k));
                        return JS_IsString(v.get()) ? js_to_string(ctx, v.get()) : std::string();
                    };
                    std::string msg = str("message"), hint = str("hint"), code = str("code");
                    JsVal dv(ctx, JS_GetPropertyStr(ctx, exc, "data"));
                    Json data = JS_IsUndefined(dv.get()) ? Json(nullptr) : to_json(dv.get());
                    throw CommandError(code.empty() ? "tool_error" : code, msg, hint, std::move(data));
                }
                ScriptError e = error_from_exception(exc, "", toolFile);
                record_error(e, cname);
                std::string loc = e.file + (e.line > 0 ? ":" + std::to_string(e.line) : "");
                throw CommandError("failed", e.message + (loc.empty() ? "" : " (at " + loc + ")"),
                                   "Fix the error in " + toolFile + " (see script errors), or throw new ToolError(message, hint) for expected failures.");
            };
            JSValueConst defv = it->second.fn.get();
            JsVal run(ctx, JS_GetPropertyStr(ctx, defv, "run"));
            JsVal a(ctx, from_json(args.is_null() ? Json::object() : args));
            bool failed = false;
            JSValue r = call(cname, "", run.get(), defv, {a.get(), factoria.get()}, &failed, 10.0, true);
            if (JS_IsException(r)) {
                JSValue exc = JS_GetException(ctx);
                JsVal guard(ctx, exc);
                throw_js(exc);
            }
            if (failed) {
                if (debug_session_ended())
                    throw CommandError("failed", "tool " + cname + " was stopped because the debug session ended", "");
                throw CommandError("failed", "script took too long (> 10 s) in tool " + cname, "Avoid infinite loops in tools.");
            }
            JsVal result(ctx, r);
            if (JS_PromiseState(ctx, result.get()) != JS_PROMISE_NOT_A_PROMISE) {
                run_jobs();
                auto st = JS_PromiseState(ctx, result.get());
                if (st == JS_PROMISE_REJECTED) {
                    JsVal reason(ctx, JS_PromiseResult(ctx, result.get()));
                    throw_js(reason.get());
                }
                if (st == JS_PROMISE_PENDING) throw CommandError("failed", "tool returned a promise that never resolved", "Tools must finish synchronously or await only already-resolved promises.");
                JsVal value(ctx, JS_PromiseResult(ctx, result.get()));
                run_jobs();
                return stamp(to_json(value.get()));
            }
            run_jobs();
            return stamp(to_json(result.get()));
        });
    }
    std::set<std::string> after;
    for (auto& [name, t] : tools) after.insert(name);
    if (toolsChanged && before != after) toolsChanged();
    else if (toolsChanged && !suppressToolNotify) toolsChanged();
}

// ---------------------------------------------------------------------------------------------------------------------
// eval
// ---------------------------------------------------------------------------------------------------------------------
Result<Json> Impl::eval(std::string_view code) {
    static const char kWrapper[] = "(function(__fa_code){ with (globalThis.factoria) { return eval(__fa_code); } })";
    JsVal fn(ctx, JS_Eval(ctx, kWrapper, sizeof(kWrapper) - 1, "<eval>", JS_EVAL_TYPE_GLOBAL));
    JsVal codeV(ctx, JS_NewStringLen(ctx, code.data(), code.size()));
    auto debugEntry = debug_entry(*this);
    const size_t depth = push_guard("eval", 5.0);
    timedOut = false;
    JSValue arg = codeV.get();
    JSValue r = JS_Call(ctx, fn.get(), JS_UNDEFINED, 1, &arg);
    pop_guard(depth);
    auto fail = [&](JSValue exc) -> Result<Json> {
        ScriptError e = error_from_exception(exc, "", "<eval>");
        JS_FreeValue(ctx, exc);
        if (timedOut) {
            timedOut = false;
            e.message = debug_session_ended() ? "eval was stopped because the debug session ended"
                                              : "script took too long (> 5 s) in eval";
        }
        std::string msg = e.message;
        if (e.line > 0 && e.file != "<eval>" && !e.file.empty()) msg += " (at " + e.file + ":" + std::to_string(e.line) + ")";
        std::string hint = "Names from \"factoria\" (world, input, vec2, ...) are in scope. Use `world.find(\"id\")` to get entities.";
        return Error{msg, hint};
    };
    if (JS_IsException(r)) return fail(JS_GetException(ctx));
    JsVal value(ctx, r);
    if (JS_PromiseState(ctx, value.get()) != JS_PROMISE_NOT_A_PROMISE) {
        run_jobs();
        auto st = JS_PromiseState(ctx, value.get());
        if (st == JS_PROMISE_REJECTED) return fail(JS_PromiseResult(ctx, value.get()));
        if (st == JS_PROMISE_PENDING) return Json("<pending promise>");
        value = JsVal(ctx, JS_PromiseResult(ctx, value.get()));
    }
    run_jobs();
    JsVal ser(ctx, JS_UNDEFINED);
    {
        JsVal sfn(ctx, JS_GetPropertyStr(ctx, hooks.get(), "serialize"));
        JSValue v = value.get();
        JSValue sr = JS_Call(ctx, sfn.get(), JS_UNDEFINED, 1, &v);
        if (JS_IsException(sr)) return fail(JS_GetException(ctx));
        ser = JsVal(ctx, sr);
    }
    if (!JS_IsString(ser.get())) return Json(nullptr);
    std::string text = js_to_string(ctx, ser.get());
    Json j = Json::parse(text, nullptr, false);
    if (j.is_discarded()) return Json(text);
    return j;
}

// ---------------------------------------------------------------------------------------------------------------------
// check_syntax
// ---------------------------------------------------------------------------------------------------------------------
Result<void> Impl::check_syntax(std::string_view modulePath, std::string* brokenImport) {
    auto norm = fs::normalize_checked(modulePath);
    if (!norm) return Error{norm.error().message, norm.error().hint};
    std::string path = *norm;
    auto text = fs::read_text(path);
    if (!text) {
        std::vector<std::string> candidates = fs::list("", true, ".js");
        return Error{"cannot read '" + path + "': " + text.error().message,
                     candidates.empty() ? text.error().hint : did_you_mean(path, candidates)};
    }
    if (is_script_bytecode(*text)) {  // compiled by a --release export: it compiled then, what can be wrong is the version
        if (auto payload = script_bytecode_payload(*text, path); !payload.ok()) return payload.error();
        return {};
    }
    std::string unique = "<syntax>/" + path;
    brokenData.reset();
    JSValue r = JS_Eval(ctx, text->c_str(), text->size(), unique.c_str(), JS_EVAL_TYPE_MODULE | JS_EVAL_FLAG_COMPILE_ONLY);
    if (JS_IsException(r)) {
        JSValue exc = JS_GetException(ctx);
        if (brokenData) {  // an imported .json that does not parse: report that file, not the importer
            JS_FreeValue(ctx, exc);
            if (brokenImport) *brokenImport = brokenData->file;
            return brokenData->error;
        }
        std::string name, msg;
        {
            JSValue n = JS_GetPropertyStr(ctx, exc, "name");
            JSValue m = JS_GetPropertyStr(ctx, exc, "message");
            name = js_to_string(ctx, n);
            msg = js_to_string(ctx, m);
            JS_FreeValue(ctx, n);
            JS_FreeValue(ctx, m);
        }
        ScriptError e = error_from_exception(exc, "", path);
        JS_FreeValue(ctx, exc);
        std::string loc = path;
        // The stack of a syntax error ends with "at <syntax>/path:line:col".
        int line = e.line, col = e.column;
        if (line <= 0) {
            size_t p = e.stack.find(unique + ":");
            if (p != std::string::npos) {
                std::sscanf(e.stack.c_str() + p + unique.size() + 1, "%d:%d", &line, &col);
            }
        }
        if (line > 0) loc += ":" + std::to_string(line) + (col > 0 ? ":" + std::to_string(col) : "");
        std::string full = loc + ": " + (name.empty() ? "SyntaxError" : name) + ": " + msg;
        full = replace_all(full, unique, path);
        return Error{full, "Fix the syntax error at that position; modules use ES2023 syntax (import/export, classes, async)."};
    }
    JS_FreeValue(ctx, r);
    return {};
}

// ---------------------------------------------------------------------------------------------------------------------
// hot reload
// ---------------------------------------------------------------------------------------------------------------------
void Impl::reload_module(std::string_view modulePath) {
    auto norm = fs::normalize_checked(modulePath);
    if (!norm) return;
    std::string path = *norm;
    loggedKeys.clear();
    std::vector<std::string> affected = bump_module_versions(path);
    bool toolsAffected = false;
    for (const auto& p : affected)
        if (p.rfind("tools/", 0) == 0) toolsAffected = true;
    // Recreate behaviours whose class came from an affected module (entity state is kept, props re-applied,
    // onStart runs again). Failed loads are retried.
    for (auto& b : behaviours) {
        if (b->dead) continue;
        bool hit = b->loadFailed || b->faulted || std::find(affected.begin(), affected.end(), b->path) != affected.end();
        if (hit) destroy_behaviour(*b, false);
    }
    compact();
    sync();
    run_jobs();
    if (toolsAffected) reload_tools();
    FA_INFO("script", "reloaded {} ({} module(s) affected)", path, affected.size());
}

// ---------------------------------------------------------------------------------------------------------------------
// tests
// ---------------------------------------------------------------------------------------------------------------------
void Impl::reset_modules() {
    // Every project module gets a fresh instance (module-level state does not leak between test files).
    std::vector<std::string> files(everLoaded.begin(), everLoaded.end());
    for (const std::string& p : files) {
        namespaces.erase(module_name_for(p));
        versions[p] += 1;
    }
    // Tools import modules too: re-evaluate them so they share the fresh instances. No MCP notification.
    auto cb = std::move(toolsChanged);
    toolsChanged = nullptr;
    reload_tools();
    toolsChanged = std::move(cb);
}

void Impl::after_test_load() {
    host->world().rng().reseed(seed);
    host->input().clear_action_overrides();
    drop_all_behaviours();
    call_method("scene reset", "", hooks.get(), "resetScene", {});
    run_jobs();
    construct_all();
    run_jobs();
}

namespace {
constexpr double kQuitFlushSeconds = 3.0;
}

int Impl::service_call(const char* method, std::initializer_list<JSValue> args) {
    if (!initialized) return 0;
    JSValue r = call_method("services", "", hooks.get(), method, args);
    int32_t v = 0;
    if (JS_IsNumber(r)) JS_ToInt32(ctx, &v, r);
    JS_FreeValue(ctx, r);
    return v;
}

bool Impl::begin_quit_flush() {
    service_call("serviceQuit", {});
    run_jobs();  // an answer the fake gave at once settles here
    return service_call("servicePending", {}) > 0;
}

void Impl::update_quit_wait(double dt) {
    quitWaited += dt;
    if (service_call("servicePending", {}) > 0 && quitWaited < kQuitFlushSeconds) return;
    quitDeferred = false;
    do_request_quit();
}

void Impl::do_request_quit() {
    if (inTestRun) testQuitRequested = true;  // a test observes the request (game.quitRequested); the run goes on
    else host->request_quit();
}

void Impl::request_quit() {
    if (quitDeferred) return;  // already waiting for the analytics request
    if (begin_quit_flush()) {
        quitDeferred = true;
        quitWaited = 0.0;
        return;
    }
    do_request_quit();
}

// The interface scale and the text size of a test file, set without the `ui.scale` / `ui.textScale` events a change sends: they
// describe the reset, not something the test did, and would reach the first listener of the next test.
void Impl::set_scales_quietly(float uiScale, float textScale) {
    host->set_ui_scale(uiScale);
    host->set_text_scale(textScale);
    auto& events = host->world().events().game;
    std::erase_if(events, [](const GameEvent& e) { return e.name == "ui.scale" || e.name == "ui.textScale"; });
}

void Impl::drop_runtime_textures() {
    if (Renderer* r = host->renderer())
        for (const auto& [id, img] : runtimeTextures) r->destroy_runtime_texture(id);
    runtimeTextures.clear();
}

void Impl::reset_for_test_file() {
    drop_runtime_textures();
    Json proj = host->project_settings();
    std::string scene = "scenes/main.scene.json";
    if (proj.is_object() && proj.contains("mainScene") && proj["mainScene"].is_string()) scene = proj["mainScene"].get<std::string>();
    drop_all_behaviours();
    reset_modules();
    storage = Json::object();
    storageLoaded = true;
    storageCorrupt = false;
    storageTextHook.reset();
    testQuitRequested = false;
    quitDeferred = false;
    testSystemLanguages.clear();
    preload.reset();  // no job and no warm file of the earlier test file
    owner->reset_app_state();  // focused, not suspended, the date the host started with (before the scene loads)
    if (PlatformServices* platform = host->platform_services()) platform->reset_session();  // a fresh fake store per test file
    // Every test file starts in the default language, like a headless run (before the scene loads, so it is translated).
    if (const I18n* loc = host->i18n(); loc && loc->enabled() && loc->language() != loc->default_language())
        host->set_language(loc->default_language());
    call_method("reset session", "", hooks.get(), "resetSession", {});
    if (fs::exists(scene)) {
        std::string err = host->load_scene_now(scene);
        if (!err.empty()) log(LogLevel::Warn, "script", "test reset: could not load start scene " + scene + ": " + err);
    } else {
        host->world().clear();
    }
    host->input().release_all();
    set_scales_quietly(host->default_ui_scale(), 1.0f);
    host->world().set_ui_mirror_rtl(host->default_ui_mirror_rtl());
    {  // the tooltip delay and look of factoria.json, whatever an earlier test file set (ui.tooltipDelay)
        Result<UiTooltipSettings> tip = parse_tooltip_settings(proj.is_object() && proj.contains("ui") ? proj["ui"] : Json(), "factoria.json#/ui");
        host->world().set_ui_tooltip_settings(tip.ok() ? tip.value() : UiTooltipSettings{});
    }
    timeScale = 1.0;
    call_method("reset session", "", hooks.get(), "resetSession", {});
    after_test_load();
}

TestReport Impl::run_tests(const std::vector<std::string>& files, std::string_view nameFilter) {
    TestReport rep;
    inTestRun = true;
    // console.log/warn/error (category "script", info and above) is captured into the report, per test. The global
    // level is lowered to info while tests run so --log-level warn does not hide console.log; stderr keeps showing
    // only what the caller's level allowed, minus script lines (they are in the report instead).
    const LogLevel savedLevel = log_level();
    std::vector<LogEntry> captured;
    int sinkId = add_log_sink([&captured](const LogEntry& e) {
        if (e.category == "script" && e.level >= LogLevel::Info) captured.push_back(e);
    });
    if (savedLevel > LogLevel::Info) set_log_level(LogLevel::Info);
    set_log_stderr_filter([savedLevel](const LogEntry& e) { return e.category != "script" && e.level >= savedLevel; });
    struct Restore {
        int sink;
        LogLevel level;
        ~Restore() {
            remove_log_sink(sink);
            set_log_level(level);
            set_log_stderr_filter({});
        }
    } restore{sinkId, savedLevel};
    std::vector<std::pair<std::uint64_t, std::uint64_t>> ranges;  // per rep.cases entry; {0,0} = none
    // Tests never touch the real save file: in-memory storage, fresh for every test file.
    const StorageMode savedMode = storageMode;
    storageMode = StorageMode::Memory;
    const float savedTextScale = host->text_scale(), savedUiScale = host->ui_scale();
    for (const std::string& f : files) {
        auto norm = fs::normalize_checked(f);
        std::string path = norm ? *norm : f;
        reset_for_test_file();
        bump_module_versions(path);
        {
            JSValue pv = JS_NewString(ctx, path.c_str());
            JSValue r = call_method("test setup", "", hooks.get(), "testBegin", {pv});
            JS_FreeValue(ctx, r);
            JS_FreeValue(ctx, pv);
        }
        ScriptError detail;
        auto ns = import_module(path, &detail);
        if (!ns) {
            if (detail.message.empty()) { detail.file = path; detail.message = ns.error().message; }
            if (detail.file.empty()) detail.file = path;
            rep.loadErrors.push_back(detail);
            record_error(detail, path);
            continue;
        }
        JS_FreeValue(ctx, *ns);
        JsVal filterV(ctx, JS_NewStringLen(ctx, nameFilter.data(), nameFilter.size()));
        JsVal fn(ctx, JS_GetPropertyStr(ctx, hooks.get(), "testRun"));
        JSValue farg = filterV.get();
        // No guard for the whole file: testRun gives each test its own (60 s), so a long file of quick tests (a Debug
        // build on a busy machine) is not cut short. A test over its limit ends the call and skips the rest of the file.
        timedOut = false;
        const size_t depth = guards.size();
        JSValue r = JS_Call(ctx, fn.get(), hooks.get(), 1, &farg);
        pop_guard(depth);  // the frame of the test the watchdog stopped (its N.guardEnd() never ran)
        if (JS_IsException(r)) {
            JSValue exc = JS_GetException(ctx);
            ScriptError e = error_from_exception(exc, "", path);
            JS_FreeValue(ctx, exc);
            if (timedOut) {
                timedOut = false;
                e.message = debug_session_ended()
                                ? "the tests were stopped because the debug session ended; the rest of " + path + " was skipped"
                                : "a test ran longer than 60 s and was stopped; the rest of " + path + " was skipped";
            }
            JsVal curV(ctx, JS_UNDEFINED);
            {
                JsVal cf(ctx, JS_GetPropertyStr(ctx, hooks.get(), "testCurrent"));
                JSValue cr = JS_Call(ctx, cf.get(), hooks.get(), 0, nullptr);
                if (!JS_IsException(cr)) curV = JsVal(ctx, cr);
                else JS_FreeValue(ctx, JS_GetException(ctx));
            }
            TestCaseResult c;
            c.file = path;
            c.name = JS_IsString(curV.get()) ? js_to_string(ctx, curV.get()) : "<runner>";
            c.passed = false;
            c.message = e.message;
            rep.cases.push_back(c);
            ranges.push_back({0, 0});
            ++rep.failed;
            continue;
        }
        JsVal results(ctx, r);
        run_jobs();
        int64_t n = 0;
        JS_GetLength(ctx, results.get(), &n);
        for (int64_t i = 0; i < n; ++i) {
            JsVal item(ctx, JS_GetPropertyUint32(ctx, results.get(), static_cast<uint32_t>(i)));
            Json j = to_json(item.get());
            TestCaseResult c;
            c.file = path;
            c.name = j.value("name", "");
            c.passed = j.value("passed", false);
            c.message = j.value("message", "");
            c.milliseconds = j.value("ms", 0.0);
            if (j.value("skipped", false)) continue;
            c.passed ? ++rep.passed : ++rep.failed;
            rep.cases.push_back(std::move(c));
            ranges.push_back({static_cast<std::uint64_t>(j.value("seq0", 0.0)), static_cast<std::uint64_t>(j.value("seq1", 0.0))});
        }
    }
    for (const LogEntry& e : captured) {
        TestLogLine line{e.level, e.message};
        bool placed = false;
        for (std::size_t i = 0; i < rep.cases.size() && !placed; ++i)
            if (ranges[i].second > ranges[i].first && e.seq > ranges[i].first && e.seq <= ranges[i].second) {
                rep.cases[i].logs.push_back(line);
                placed = true;
            }
        if (!placed) rep.otherLogs.push_back(line);
    }
    reset_for_test_file();
    set_scales_quietly(savedUiScale, savedTextScale);
    inTestRun = false;
    storageMode = savedMode;
    storage = Json::object();
    storageLoaded = false;
    storageCorrupt = false;
    storageTextHook.reset();
    return rep;
}

}  // namespace fa
