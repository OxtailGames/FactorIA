// Private implementation of ScriptSystem (QuickJS glue).
#pragma once

#include <chrono>
#include <functional>
#include <map>
#include <memory>
#include <optional>
#include <set>
#include <string>
#include <unordered_map>
#include <vector>

#include <quickjs.h>

#include "fa/script/script.h"

namespace fa {

// RAII holder for a JSValue (strict ownership).
class JsVal {
public:
    JsVal() = default;
    JsVal(JSContext* ctx, JSValue v) : ctx_(ctx), v_(v) {}
    JsVal(const JsVal&) = delete;
    JsVal& operator=(const JsVal&) = delete;
    JsVal(JsVal&& o) noexcept : ctx_(o.ctx_), v_(o.v_) { o.ctx_ = nullptr; o.v_ = JS_UNDEFINED; }
    JsVal& operator=(JsVal&& o) noexcept {
        if (this != &o) { reset(); ctx_ = o.ctx_; v_ = o.v_; o.ctx_ = nullptr; o.v_ = JS_UNDEFINED; }
        return *this;
    }
    ~JsVal() { reset(); }
    void reset() {
        if (ctx_) JS_FreeValue(ctx_, v_);
        ctx_ = nullptr;
        v_ = JS_UNDEFINED;
    }
    JSValue get() const { return v_; }
    JSValue release() { JSValue v = v_; v_ = JS_UNDEFINED; ctx_ = nullptr; return v; }
    bool valid() const { return ctx_ != nullptr; }

private:
    JSContext* ctx_ = nullptr;
    JSValue v_ = JS_UNDEFINED;
};

struct Behaviour {
    Entity entity;
    std::string path;
    JsVal instance;
    std::string className;
    bool started = false;
    bool loadFailed = false;
    bool faulted = false;  // timed out; skipped until reloaded
    bool dead = false;
};

struct ToolEntry {
    std::string commandName;
    std::string file;
    JsVal fn;
};

struct ScriptSystem::Impl {
    ScriptHost* host = nullptr;
    JSRuntime* rt = nullptr;
    JSContext* ctx = nullptr;
    int observerId = -1;
    bool initialized = false;

    JsVal native;    // N: native API object (passed to the prelude)
    JsVal factoria;  // public namespace object of module "factoria"
    JsVal testApi;   // namespace object of module "factoria:test"
    JsVal hooks;     // H: hooks the prelude gives to C++

    // ---- errors
    std::vector<ScriptError> errors;
    std::set<std::string> loggedKeys;

    // ---- guard (timeouts)
    struct GuardFrame {
        std::string label;
        std::chrono::steady_clock::time_point deadline;
    };
    std::vector<GuardFrame> guards;
    bool timedOut = false;
    bool lastCallTimedOut = false;
    std::string timedOutLabel;
    double timedOutSeconds = 0;
    double callbackLimit = 2.0;

    // ---- modules
    std::map<std::string, int> versions;  // project path -> reload counter (0 = pristine)
    std::map<std::string, std::set<std::string>> importers;  // path -> modules that import it
    std::map<std::string, std::string> firstImporter;        // normalized name -> importer (for error text)
    std::map<std::string, JsVal> namespaces;                 // normalized name -> module namespace
    std::set<std::string> everLoaded;
    // The last data module (.json) load_module could not parse: check_syntax reports THAT file (with line and column)
    // instead of the script that imports it.
    struct BrokenData {
        std::string file;
        Error error;
    };
    std::optional<BrokenData> brokenData;

    // ---- behaviours
    std::vector<std::unique_ptr<Behaviour>> behaviours;
    std::unordered_map<std::uint64_t, Behaviour*> byEntity;
    bool inSync = false;

    // ---- time
    double timeScale = 1.0;
    float lastDt = 0.0f;
    std::uint64_t seed = 1;

    // ---- destroyed entity ids (for friendly errors)
    std::unordered_map<std::uint64_t, std::string> destroyedIds;
    std::vector<std::uint64_t> destroyedOrder;

    // ---- entity.bounds(): pixel sizes of texture files (normalized path -> size + file time), so sprites without a `size` are cheap
    struct TexSize {
        int w = 0, h = 0;
        std::int64_t mtime = 0;
    };
    std::unordered_map<std::string, TexSize> texSizes;

    // ---- tools
    std::map<std::string, ToolEntry> tools;  // by command name
    std::function<void()> toolsChanged;
    bool suppressToolNotify = false;

    // ---- storage
    Json storage = Json::object();
    bool storageLoaded = false;
    StorageMode storageMode = StorageMode::Persistent;

    // ---- test runner state
    bool inTestRun = false;

    // ================= lifecycle
    bool init(ScriptHost& h, std::string* error);
    void shutdown();

    // ================= errors
    ScriptError error_from_exception(JSValueConst exc, const std::string& entityId, const std::string& where);
    void record_error(ScriptError e, const std::string& where);
    void report_pending_exception(const std::string& entityId, const std::string& where);

    // ================= calling JS
    // Calls fn under a timeout guard. On exception records a ScriptError (unless quiet) and returns JS_UNDEFINED and
    // sets *failed. Result must be freed by the caller.
    JSValue call(const std::string& label, const std::string& entityId, JSValueConst fn, JSValueConst thisVal,
                 std::initializer_list<JSValue> args, bool* failed = nullptr, double limitSeconds = -1,
                 bool quiet = false);
    JSValue call_method(const std::string& label, const std::string& entityId, JSValueConst obj, const char* method,
                        std::initializer_list<JSValue> args, bool* failed = nullptr);
    void push_guard(const std::string& label, double seconds);
    void pop_guard();
    bool check_interrupt();
    void run_jobs();

    // ================= modules
    std::string normalize_module(const std::string& base, const std::string& spec, std::string* err);
    JSModuleDef* load_module(const char* name);
    JSModuleDef* make_builtin_module(const std::string& name);
    std::string module_file(const std::string& normalized) const;  // strips ?v=
    std::string module_name_for(const std::string& path) const;    // adds ?v= when reloaded
    // Imports a project module (project-relative path). Returns namespace (valid until module cache is cleared).
    Result<JSValue> import_module(const std::string& path, ScriptError* detail = nullptr);  // returned value is DUPLICATED, caller frees
    std::vector<std::string> bump_module_versions(const std::string& path);  // returns affected paths

    // ================= conversion
    Json to_json(JSValueConst v);
    JSValue from_json(const Json& j);
    std::string strip_versions(std::string s) const;

    // ================= behaviours (script_behaviours.cpp)
    void sync();
    // Constructs the behaviour (props applied) but does NOT run onStart; sync()/start_behaviour() do that.
    void create_behaviour(Entity e, const std::string& path, const Json& props);
    void start_behaviour(Behaviour& b);
    // Constructs behaviours for Script components of these entities that have none yet (spawn, scene load).
    void construct_for(const std::vector<Entity>& entities);
    void construct_all();
    std::vector<std::string> check_props(const std::string& modulePath, const Json& props);
    void destroy_behaviour(Behaviour& b, bool callOnDestroy);
    void compact();
    void drop_all_behaviours();
    void on_entity_destroyed(Entity e);
    void run_callbacks(const char* method, float dt, bool scaled);
    void dispatch(const char* method, Entity self, std::initializer_list<JSValue> args);
    Behaviour* find_behaviour(Entity e);
    JSValue entity_object(Entity e);  // JS Entity wrapper (owned)

    // ================= tools & tests (script_tools.cpp)
    void reload_tools();
    void unregister_tools();
    TestReport run_tests(const std::vector<std::string>& files, std::string_view nameFilter);
    void reset_for_test_file();
    void reset_modules();  // every project module gets a fresh instance on its next import
    void after_test_load();
    Result<Json> eval(std::string_view code);
    Result<void> check_syntax(std::string_view path, std::string* brokenImport);
    void reload_module(std::string_view path);

    // ================= api (script_api.cpp)
    Json api_manifest() const;
    std::string typescript_declarations() const;

    // ================= natives (script_natives.cpp)
    void install_natives(JSValue N);
    void load_storage();
    void save_storage();
    void remember_destroyed(Entity e, const std::string& id);
    std::string destroyed_id(Entity e) const;
};

// Embedded prelude sources.
std::string_view embedded_script(std::string_view name);

}  // namespace fa
