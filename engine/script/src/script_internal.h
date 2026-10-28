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

#include "fa/core/profiler.h"

#include "fa/platform/accessibility.h"
#include "fa/scene/serialize.h"
#include "fa/script/script.h"
#include "fa/services/platform.h"
#include "preload.h"
#include "script_storage.h"

namespace fa {

// A platform answer as the prelude's platformDeliver and platformStart get it: {id, method, ok, result | error: {code, message, hint}}.
Json platform_answer_json(const PlatformAnswer& answer);

// RAII holder for a JSValue (strict ownership).
// The engine's JS object classes (nav.createGrid / nav.flowField handles, debugger frames). QuickJS hands class ids out
// from a per-runtime counter while these live in globals, so every runtime reserves all of them, in this order, right
// after JS_NewRuntime (reserve_class_ids): each runtime's counter starts at the same id, so the ids match everywhere.
extern JSClassID g_navHandleClass;
extern JSClassID g_debugFrameClass;
void reserve_class_ids(JSRuntime* rt);

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

inline const std::string kProfOtherName{kProfOtherClass}, kProfNoPath;  // profiler bucket for script time of no behaviour

struct Behaviour {
    Entity entity;
    std::string path;
    JsVal instance;
    std::string className;
    bool started = false;
    bool enabledState = false;  // onEnable has run and onDisable has not since
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
    ScriptSystem* owner = nullptr;
    std::shared_ptr<ScriptDebugger> debugger;  // debug mode (set_debugger); null for a normal run
    JSRuntime* rt = nullptr;
    JSContext* ctx = nullptr;
    int observerId = -1;
    bool initialized = false;

    JsVal native;    // N: native API object (passed to the prelude)
    JsVal factoria;  // public namespace object of module "factoria"
    JsVal testApi;   // namespace object of module "factoria:test"
    JsVal hooks;     // H: hooks the prelude gives to C++

    Preloader preload;  // scene.preload / assets.preload jobs (preload.h); ticked by dispatch_platform
    std::vector<ScriptPlugin> plugins;  // set_plugins: the `plugins` object of scripts
    Json plugins_json() const;          // [{name, error?, functions: [{name, doc}]}] (script_api.cpp)

    // ---- errors
    std::vector<ScriptError> errors;
    std::set<std::string> loggedKeys;
    struct Rejection { JSValue promise, reason; };  // rejected with no handler yet (owned); reported when the job queue drains
    std::vector<Rejection> pendingRejections;
    void flush_rejections();

    // ---- guard (timeouts)
    struct GuardFrame {
        std::string label;
        double seconds = 0;
        std::chrono::steady_clock::time_point deadline;
    };
    std::vector<GuardFrame> guards;
    bool timedOut = false;
    bool lastCallTimedOut = false;
    std::string timedOutLabel;
    size_t timedOutDepth = 0;  // index in `guards` of the frame that ran out (a caller's frame is below the callee's)
    double timedOutSeconds = 0;
    double callbackLimit = 2.0;

    // ---- modules
    std::map<std::string, int> versions;  // project path -> reload counter (0 = pristine)
    std::map<std::string, std::set<std::string>> importers;  // path -> modules that import it
    std::map<std::string, std::string> firstImporter;        // normalized name -> importer (for error text)
    std::map<std::string, JsVal> namespaces;                 // normalized name -> module namespace
    std::set<std::string> everLoaded;
    std::map<std::string, std::int64_t> moduleMtime;  // file mtime when each module was last read
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
    // Entity references that world.spawn could not resolve yet (a slider's knob spawned after the slider): retried after
    // every spawn and every sync, dropped with a warning after kDeferredRefTicks syncs.
    struct WaitingRef { DeferredRef ref; int ticks = 0; };
    std::vector<WaitingRef> waitingRefs;
    void resolve_waiting_refs(bool tick);

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

    // ---- render.captureTexture / render.textureFromPNG: the pixels of every live run-time texture by id ("runtime:N"), kept
    // here so toPNG() needs no GPU read-back and a run without a renderer still has them. The GPU copy (when there is a renderer)
    // is the renderer's, freed by destroy and by reset_for_test_file.
    std::map<std::string, Image> runtimeTextures;
    int nextPlainTexture = 1;  // ids of textures made without a renderer
    void drop_runtime_textures();

    // ---- tools
    std::map<std::string, ToolEntry> tools;  // by command name
    std::function<void()> toolsChanged;
    bool suppressToolNotify = false;

    // ---- storage
    Json storage = Json::object();
    bool storageLoaded = false;
    StorageMode storageMode = StorageMode::Persistent;
    bool storageCorrupt = false;                 // the save data did not parse at the last load (storage.corrupt)
    std::optional<std::string> storageTextHook;  // game.setStorageText: what the next load reads instead of the file
    // What is known of each key's file: whether it is compressed and its size in bytes (-1: not measured yet, storage.size does it).
    struct StorageMeta {
        bool compressed = false;
        std::int64_t bytes = -1;
    };
    std::map<std::string, StorageMeta> storageMeta;
    storage_files::Writer storageWriter;  // storage.setAsync
    int nextStorageJob = 1;
    void storage_write(const std::string& key, bool compress);      // writes one key's file now
    void storage_remove_file(const std::string& key);
    void storage_drain();                                            // waits for the setAsync writes still running

    // ---- game.accessibility: game.setAccessibility() in tests (windowless runs otherwise give the defaults)
    AccessibilitySettings testAccessibility;

    // ---- tests: a quit request sets a flag instead of stopping the run; game.setSystemLanguages() fakes the device languages
    bool testQuitRequested = false;
    bool quitCancelled = false;  // a game.on("quit") handler called event.cancel() during close_requested()
    std::vector<std::string> testSystemLanguages;
    void request_quit();  // the host's quit, except in a test run, where it only sets testQuitRequested
    // Analytics and remote config (the prelude's serviceTick / serviceSuspend / serviceQuit / servicePending): a quit first
    // flushes the analytics queue and waits, at most kQuitFlushSeconds of engine time, for the request that carries it.
    bool quitDeferred = false;
    double quitWaited = 0.0;
    int service_call(const char* method, std::initializer_list<JSValue> args);  // the prelude's number answer, 0 on failure
    bool begin_quit_flush();   // flushes; true when a request is still in flight (the quit waits)
    void update_quit_wait(double dt);  // each frame while quitDeferred
    void do_request_quit();    // the host's quit itself, without the flush

    // ---- game.device: game.setDevice() in tests overrides some of the host's values
    Json testDevice = Json::object();

    // ---- the calendar date and the app's life (script_system.cpp: ScriptSystem::today / app_event)
    CalendarDate startDate;  // what the host set: EngineConfig::date
    CalendarDate date;       // game.today(): startDate, or what game.setDate set in a test
    bool appFocused = true;
    bool appSuspended = false;
    bool pausedBySuspend = false;  // the suspend froze the game (time.scale 0) and will unfreeze it on resume
    double scaleBeforeSuspend = 1.0;

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
                        std::initializer_list<JSValue> args, bool* failed = nullptr, const Behaviour* profile = nullptr);
    // push_guard returns the depth of the guard stack before the push; pop_guard(depth) drops every frame above it. A
    // script the watchdog stops skips the N.guardEnd() of each JS guard it was inside (the interrupt cannot be caught),
    // so every C++ entry into JS pops back to its own depth: popping one frame would leave the caller's expired frame on
    // the stack, and every later script would be stopped at its first instruction.
    size_t push_guard(const std::string& label, double seconds);
    void pop_guard(size_t depth);
    bool check_interrupt();
    // The debugger is being terminated (the user pressed Stop): an interrupted script was stopped, not slow.
    bool debug_session_ended() const;
    void run_jobs();

    // ================= modules
    std::string normalize_module(const std::string& base, const std::string& spec, std::string* err);
    JSModuleDef* load_module(const char* name);
    JSModuleDef* load_glob_module(const std::string& name, const std::string& file);  // import "dir/*.json"
    JSModuleDef* make_builtin_module(const std::string& name);
    std::string module_file(const std::string& normalized) const;  // strips ?v=
    std::string module_name_for(const std::string& path) const;    // adds ?v= when reloaded
    // Imports a project module (project-relative path). Returns namespace (valid until module cache is cleared).
    void explain_missing_api(ScriptError& e);  // adds which module/export or method the player lacks
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
    bool is_active(const Behaviour& b);
    bool update_activation(Behaviour& b);
    // Constructs behaviours for Script components of these entities that have none yet (spawn, scene load).
    void construct_for(const std::vector<Entity>& entities);
    void construct_all();
    std::vector<std::string> check_props(const std::string& modulePath, const Json& props);
    std::vector<std::string> check_hooks(const std::string& modulePath);
    void destroy_behaviour(Behaviour& b, bool callOnDestroy);
    void compact();
    void drop_all_behaviours();
    void on_entity_destroyed(Entity e);
    // pausedOnly: time.scale is 0, so only behaviours whose `runWhilePaused` is true are called.
    void run_callbacks(const char* method, float dt, bool pausedOnly);
    void dispatch(const char* method, Entity self, std::initializer_list<JSValue> args);
    Behaviour* find_behaviour(Entity e);
    JSValue entity_object(Entity e);  // JS Entity wrapper (owned)

    // ================= tools & tests (script_tools.cpp)
    void reload_tools();
    void unregister_tools();
    TestReport run_tests(const std::vector<std::string>& files, std::string_view nameFilter);
    void reset_for_test_file();
    void set_scales_quietly(float uiScale, float textScale);
    void reset_modules();  // every project module gets a fresh instance on its next import
    void after_test_load();
    Result<Json> eval(std::string_view code);
    Result<void> check_syntax(std::string_view path, std::string* brokenImport);
    void reload_module(std::string_view path);

    // ================= api (script_api.cpp)
    Json api_manifest() const;
    std::string typescript_declarations(const ScriptSystem::SinceFn& since) const;
    std::vector<std::string> script_api_keys() const;

    // ================= natives (script_natives.cpp)
    void install_natives(JSValue N);
    void load_storage();
    void save_storage();
    void remember_destroyed(Entity e, const std::string& id);
    std::string destroyed_id(Entity e) const;
};

// Replaces the QuickJS built-ins that have bugs (quickjs_fixes.cpp); called on a new context before any script runs.
void install_quickjs_fixes(JSContext* ctx);

// Embedded prelude sources.
std::string_view embedded_script(std::string_view name);
// "\n  <source line>\n  <spaces>^" for a project file position, or "" when the file or line cannot be read.
std::string source_caret(const std::string& file, int line, int column);

}  // namespace fa
