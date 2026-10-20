// JavaScript gameplay scripting (QuickJS-ng, ES2023 modules).
//
// A behaviour is an ES module in the project whose default export extends
// Behaviour (provided by the built-in "factoria" module):
//
//   import { Behaviour, input, vec2 } from "factoria";
//   export default class Player extends Behaviour {
//     speed = 300;                         // overridable from Script.props in the scene
//     onStart() { this.body = this.entity.get("RigidBody2D"); }
//     onUpdate(dt) {
//       const dir = input.axis("move_left", "move_right");
//       this.body.velocity = vec2(dir * this.speed, this.body.velocity.y);
//       if (input.pressed("jump") && this.entity.isGrounded()) this.body.velocity.y = 600;
//     }
//     onCollisionEnter(other, info) { if (other.hasTag("coin")) other.destroy(); }
//   }
//
// The full API is described by api_manifest(); `factoria api --dts` writes the
// TypeScript declarations that projects keep in types/factoria.d.ts so AIs (and
// editors) can type-check scripts with `tsc --noEmit`.
//
// Tests: tests/*.test.js use the built-in "factoria:test" module
// (test/expect/game.step/game.input...) and run headless via run_tests().
#pragma once

#include <functional>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/core/log.h"
#include "fa/scene/world.h"

namespace fa {

class Input;
class Audio;
class Physics;
class Renderer;
class UiSystem;
class PlatformServices;
class I18n;

// The game's own window, as `window.*` in scripts reaches it. Only a game that owns a real window has one (factoria run,
// an exported game, a phone or tablet player); headless runs, tests, the MCP server and the editor's game view have none,
// and ScriptHost::window() is nullptr there. Sizes are logical pixels (see fa/platform/app.h).
class WindowControl {
public:
    virtual ~WindowControl() = default;
    virtual bool fullscreen() const = 0;
    virtual void size(int& width, int& height) const = 0;          // client size now
    virtual void display_size(int& width, int& height) const = 0;  // the monitor the window is on (the window size if unknown)
    virtual bool vsync() const = 0;
    virtual int frame_cap() const = 0;  // frames per second, 0 = unlimited
    // The setters return "" when done, else a sentence that says why not and what to do instead (the script layer puts
    // `window.<function>: ` in front and throws it).
    virtual std::string set_fullscreen(bool on) = 0;
    virtual std::string set_size(int width, int height) = 0;
    virtual std::string set_vsync(bool on) = 0;
    virtual std::string set_frame_cap(int fps) = 0;  // 0 or 15..1000, already checked by the script layer
};

// Implemented by fa_runtime's Engine. Everything scripts can reach.
class ScriptHost {
public:
    virtual ~ScriptHost() = default;
    virtual World& world() = 0;
    virtual Input& input() = 0;
    virtual Audio& audio() = 0;
    virtual Physics& physics() = 0;
    virtual Renderer* renderer() = 0;  // nullptr when running without graphics
    virtual UiSystem* ui() { return nullptr; }  // the game UI (ui.focus, ui.focused, ui.hovered); nullptr without one
    virtual CommandRegistry& commands() = 0;
    virtual Json project_settings() const = 0;
    virtual double fixed_dt() const = 0;
    // The renderer's target size in pixels (what `game.screenSize` reads on every call: cheap, no settings copy); without a
    // renderer, the project's display size. Hosts that keep that size at hand override it.
    virtual Vec2 design_size() const {
        Json p = project_settings();
        Vec2 s{1280.0f, 720.0f};
        if (p.is_object() && p.contains("display") && p["display"].is_object()) {
            s.x = p["display"].value("width", 1280.0f);
            s.y = p["display"].value("height", 720.0f);
        }
        return s;
    }
    // The game window, or nullptr when this run has none (the default): `window.available` in scripts.
    virtual WindowControl* window() { return nullptr; }
    // The store services behind `platform.*` in scripts (fa/services/platform.h); nullptr when the host has none, and
    // `platform` then reports the "none" backend.
    virtual PlatformServices* platform_services() { return nullptr; }
    // The string tables and the current language behind `i18n.*` in scripts (fa/core/i18n.h); nullptr when the host has none.
    virtual const I18n* i18n() { return nullptr; }
    // Switches the language of the game now: every Text and widget with a `key` is rewritten at once and an "i18n.change" game
    // event is sent. Returns "" when done (also when it already was that language), else a sentence saying why not.
    virtual std::string set_language(std::string_view language) {
        (void)language;
        return "this host has no localization (set_language is not implemented)";
    }
    // Deferred to the end of the current frame.
    virtual void request_scene_change(std::string_view scenePath) = 0;
    virtual void request_quit() = 0;
    // Test runner only: synchronously simulate n frames (input -> fixed -> update -> render).
    virtual void step_frames(int n) = 0;
    // Load a scene immediately (test runner only), returns error text or "".
    virtual std::string load_scene_now(std::string_view scenePath) = 0;
    // Load a scene given as JSON (test runner: game.loadJson). Returns error text or "". Hosts that cannot do it keep
    // the default, which returns an explanatory error.
    virtual std::string load_scene_json_now(const Json& scene, std::string_view sourceName) {
        (void)scene;
        (void)sourceName;
        return "not supported by this host (load_scene_json_now is not implemented)";
    }
    virtual bool screenshot(std::string_view path, std::string* error) = 0;
    // Same at `scale` times the design size (render scale: the same frame drawn sharper, 1.5 on 1280x720 = 1920x1080 PNG).
    // Hosts without a renderer keep the default, which only accepts scale 1.
    virtual bool screenshot_scaled(std::string_view path, double scale, std::string* error) {
        if (scale == 1.0) return screenshot(path, error);
        if (error) *error = "this host cannot render at a scale other than 1";
        return false;
    }
    // Same, then converts the saved picture to what a colour-blind viewer sees (`simulate`: greyscale, protanopia,
    // deuteranopia, tritanopia; "" or "none" = unchanged; see simulate_color_vision in fa/core/image.h). The player's
    // view is not changed, only the file. Hosts without a renderer keep the default, which refuses a simulation.
    virtual bool screenshot_simulated(std::string_view path, double scale, std::string_view simulate, std::string* error) {
        if (!simulate.empty() && simulate != "none") {
            if (error) *error = "this host cannot simulate colour vision (no renderer)";
            return false;
        }
        return screenshot_scaled(path, scale, error);
    }
    // The player's "text size" option (`ui.textScale`, the `ui.set_text_scale` command): screen-space Text and UI labels
    // are drawn and measured at their font size times this (Renderer::set_text_scale, 0.5 .. 3, 1 = normal). The default
    // implementation only remembers it, for hosts without a renderer; Engine hands it to the renderer too. It is not saved:
    // the game stores its options.
    float text_scale() const { return textScale_; }
    virtual void set_text_scale(float scale) { textScale_ = scale; }

private:
    float textScale_ = 1.0f;
};

// Where `storage.*` keeps its data. Persistent: <user dir>/storage.json (default). Memory: never touches disk
// (headless runs, tests). Test runs always use a fresh in-memory storage per test file, whatever the mode.
enum class StorageMode { Persistent, Memory };

struct ScriptError {
    std::string file;     // project-relative module path
    int line = 0;
    int column = 0;
    std::string message;
    std::string stack;
    std::string entityId;  // behaviour's entity, if any
    std::string to_string() const;
};

// A console.log/warn/error line (category "script", info and above) produced while a test ran.
struct TestLogLine {
    LogLevel level = LogLevel::Info;
    std::string message;
};

struct TestCaseResult {
    std::string file;
    std::string name;
    bool passed = false;
    std::string message;  // failure message with expected/actual
    double milliseconds = 0.0;
    std::vector<TestLogLine> logs;  // script output produced while this test ran (also by behaviours)
};

struct TestReport {
    std::vector<TestCaseResult> cases;
    int passed = 0;
    int failed = 0;
    std::vector<ScriptError> loadErrors;  // files that failed to load/compile
    std::vector<TestLogLine> otherLogs;   // script output outside any test (file top level, load)
    bool ok() const { return failed == 0 && loadErrors.empty(); }
    Json to_json() const;
    std::string summary() const;
};

// A namespace of native functions that scripts call as plugins.<name>.<function>(...args): the functions of one native
// plugin (fa_runtime loads them: fa/runtime/plugins.h).
struct ScriptPlugin {
    struct Function {
        std::string name;
        std::string doc;
        // The JS arguments as a JSON array -> the result. Failures throw CommandError (message + hint); scripts get them
        // as exceptions.
        std::function<Json(const Json& args)> call;
    };
    std::string name;
    std::string error;  // why the plugin is not loaded ("" = loaded): every use of plugins.<name> throws it
    std::vector<Function> functions;
};

class ScriptSystem {
public:
    ScriptSystem();
    ~ScriptSystem();

    // The `plugins` object of scripts (call before init; the typings and api_manifest list them too).
    void set_plugins(std::vector<ScriptPlugin> plugins);
    bool init(ScriptHost& host, std::string* error);
    void shutdown();

    // Lifecycle (driven by the engine).
    void on_scene_loaded();          // drop old behaviours; new ones are created lazily
    void update(float dt);           // create behaviours for new Script components (onStart), then onUpdate
    void fixed_update(float dt);     // onFixedUpdate
    void late_update(float dt);      // onLateUpdate
    void settle_activation();        // onStart/onEnable/onDisable for entities (de)activated this frame, before drawing
    void dispatch_events();          // world.events() -> onCollision*/onTrigger*/world.on(...) handlers, then clear
    // Start of every engine frame, before the fixed steps: settles the promises of platform requests that were answered
    // since the last frame, then calls the platform.on listeners for the events that came in, then runs pending jobs.
    void dispatch_platform();
    // The system Back button (Android; Input::on_back): when it arrived since the last frame, calls the input.onBack handlers
    // and, when none consumes it (or there are none), asks the host to quit, which is what Back did before the event
    // existed. Once per frame, with dispatch_platform().
    void dispatch_back();

    // Developer tools.
    Result<Json> eval(std::string_view code);  // REPL in the game context; returns the value as JSON
    // Compiles a module and resolves its imports, without running it. When the failure is an imported data file
    // (`import levels from "./levels.json"`) that is not valid JSON, the error is THAT file's ("file:line:column: invalid
    // JSON: ...") and *brokenImport (if given) gets its project-relative path; otherwise *brokenImport is left empty.
    Result<void> check_syntax(std::string_view modulePath, std::string* brokenImport = nullptr);
    TestReport run_tests(const std::vector<std::string>& files, std::string_view nameFilter = {});
    const std::vector<ScriptError>& errors() const;
    void clear_errors();
    // Scene-load refresh: marks every loaded module whose file changed on disk (all of them with `force`), and the modules
    // importing them, for re-import on next use; reloads tools if affected; clears script errors. Behaviours are NOT
    // touched (the caller recreates them, e.g. on_scene_loaded). Returns the stale files.
    std::vector<std::string> refresh_modules(bool force = false);
    void reload_module(std::string_view modulePath);  // hot reload: re-import + recreate affected behaviours
    // (Re)loads every tools/*.js of the project and registers them as "project.<name>" commands (also done by init()).
    void reload_tools();
    // Called after the set of JS tools changed (so MCP can send tools/list_changed).
    void set_tools_changed_callback(std::function<void()> cb);
    // Switches `storage.*` between the real save file and a throwaway in-memory object (switching clears what
    // was loaded in memory; Memory never writes to disk).
    void set_storage_mode(StorageMode mode);
    StorageMode storage_mode() const;
    // Validates Script.props against a behaviour module WITHOUT side effects on the scene: constructs a throw-away
    // instance and returns one message per prop that is not an own field of it (with "did you mean"). Returns an
    // error entry too when the module cannot be loaded. Empty = all good. Used by `factoria validate`.
    std::vector<std::string> check_props(std::string_view modulePath, const Json& props);
    // Methods of a behaviour module's class that look like misspelled lifecycle hooks (`update()`, `onupdate()`,
    // `onStrat()`), which the engine never calls: one message per method with "did you mean". Empty when all is fine,
    // or when the module is not a behaviour or does not load (check_syntax reports that). Used by `factoria validate`;
    // a running game logs the same warning once per class when the first behaviour of it is created.
    std::vector<std::string> check_hooks(std::string_view modulePath);

    Json api_manifest() const;               // machine-readable API (modules, classes, functions, docs)
    // Contents of types/factoria.d.ts. `since` (optional) maps "Component" or "Component.field" to the version that
    // added it ("0.1.3", "unreleased", or "" for nothing to say); non-empty answers become a JSDoc @since tag.
    using SinceFn = std::function<std::string(const std::string&)>;
    std::string typescript_declarations(const SinceFn& since = {}) const;
    Json stats() const;                      // behaviours alive, modules loaded, memory
    // time.scale as scripts set it (game.paused sets 0): the engine scales physics steps, particles and sprite
    // animators by it, so 0 freezes gameplay while the UI and runWhilePaused behaviours keep running.
    double time_scale() const;

    struct Impl;

private:
    std::unique_ptr<Impl> impl_;
};

}  // namespace fa
