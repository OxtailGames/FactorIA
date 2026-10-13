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
#include "fa/scene/world.h"

namespace fa {

class Input;
class Audio;
class Physics;
class Renderer;

// Implemented by fa_runtime's Engine. Everything scripts can reach.
class ScriptHost {
public:
    virtual ~ScriptHost() = default;
    virtual World& world() = 0;
    virtual Input& input() = 0;
    virtual Audio& audio() = 0;
    virtual Physics& physics() = 0;
    virtual Renderer* renderer() = 0;  // nullptr when running without graphics
    virtual CommandRegistry& commands() = 0;
    virtual Json project_settings() const = 0;
    virtual double fixed_dt() const = 0;
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

struct TestCaseResult {
    std::string file;
    std::string name;
    bool passed = false;
    std::string message;  // failure message with expected/actual
    double milliseconds = 0.0;
};

struct TestReport {
    std::vector<TestCaseResult> cases;
    int passed = 0;
    int failed = 0;
    std::vector<ScriptError> loadErrors;  // files that failed to load/compile
    bool ok() const { return failed == 0 && loadErrors.empty(); }
    Json to_json() const;
    std::string summary() const;
};

class ScriptSystem {
public:
    ScriptSystem();
    ~ScriptSystem();

    bool init(ScriptHost& host, std::string* error);
    void shutdown();

    // Lifecycle (driven by the engine).
    void on_scene_loaded();          // drop old behaviours; new ones are created lazily
    void update(float dt);           // create behaviours for new Script components (onStart), then onUpdate
    void fixed_update(float dt);     // onFixedUpdate
    void late_update(float dt);      // onLateUpdate
    void dispatch_events();          // world.events() -> onCollision*/onTrigger*/world.on(...) handlers, then clear

    // Developer tools.
    Result<Json> eval(std::string_view code);  // REPL in the game context; returns the value as JSON
    Result<void> check_syntax(std::string_view modulePath);  // compile only, no execution
    TestReport run_tests(const std::vector<std::string>& files, std::string_view nameFilter = {});
    const std::vector<ScriptError>& errors() const;
    void clear_errors();
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

    Json api_manifest() const;               // machine-readable API (modules, classes, functions, docs)
    std::string typescript_declarations() const;  // contents of types/factoria.d.ts
    Json stats() const;                      // behaviours alive, modules loaded, memory

    struct Impl;

private:
    std::unique_ptr<Impl> impl_;
};

}  // namespace fa
