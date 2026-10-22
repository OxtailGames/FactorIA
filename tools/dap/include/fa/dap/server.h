// The Debug Adapter Protocol server of the script debugger (docs/design/SCRIPT_DEBUGGER.md, "The DAP server").
//
// DapServer has no I/O of its own: requests go in through handle_message, responses and events come out through a
// sink, so doctests drive it and `factoria dap` wires it to stdin/stdout. It is also the DebugClient of the game's
// ScriptDebugger.
//
// Threads:
//   reader thread: handle_message for every request that needs no script thread (initialize, launch, setBreakpoints,
//                  setExceptionBreakpoints, configurationDone, threads, pause, source, disconnect, terminate), and it
//                  queues the requests that need the paused game (stackTrace, scopes, variables, evaluate, setVariable,
//                  continue, next, stepIn, stepOut).
//   main thread:   wait_for_start(), then runs the game with debugger() in its EngineConfig, then finish(). While the
//                  game is stopped, paused() runs the queued requests; continue/next/stepIn/stepOut return from it.
#pragma once

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <deque>
#include <functional>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/script/debugger.h"

namespace fa {

class ScriptSystem;

// What the `launch` request asked for, validated (docs/DEBUGGING.md, "Launch attributes").
struct DapLaunchArgs {
    std::string mode = "play";    // "play", "headless" or "test"
    std::string projectDir;       // absolute, the folder with factoria.json
    std::string scene;            // play, headless: project-relative scene ("" = the project's main scene)
    int frames = 600;             // headless
    std::string inputPath;        // headless: absolute path of the input replay ("" = none)
    std::vector<std::string> tests;  // test: project-relative files, folders or globs ("" entries removed; empty = all)
    std::string filter;           // test
    bool stopOnEntry = false;
    bool noDebug = false;         // "Run Without Debugging": no ScriptDebugger is attached
};

// Validates the `arguments` of a launch request. Unknown keys and bad values give an Error that names the key and
// suggests the closest valid one. `cwd`: where an empty `project` is looked for (the nearest folder with factoria.json).
Result<DapLaunchArgs> parse_dap_launch(const Json& arguments, const std::string& cwd);

class DapServer final : public DebugClient {
public:
    using Sink = std::function<void(const Json& message)>;  // called from any thread; must be thread-safe

    DapServer(Sink sink, ScriptInstrumenter instrumenter);
    ~DapServer() override;
    DapServer(const DapServer&) = delete;
    DapServer& operator=(const DapServer&) = delete;

    // ---- reader thread
    void handle_message(const Json& message);
    // A frame that could not be used (DapFrameReader::Item::error): shown in the debug console.
    void handle_protocol_error(const std::string& text);
    // The client closed its output without `disconnect`: same as disconnect.
    void handle_eof();

    // ---- main thread
    // Blocks until the client sent launch (valid) and configurationDone: true. False: the client went away first.
    bool wait_for_start();
    const DapLaunchArgs& launch() const { return launch_; }
    // The debugger to pass in EngineConfig::scriptDebugger; null for noDebug launches or before a launch.
    std::shared_ptr<ScriptDebugger> debugger() const;
    // The game ended: answers requests still waiting, then sends `exited` and `terminated` (unless the client already
    // disconnected).
    void finish(int exitCode);
    // Blocks until the client sent disconnect (or closed the stream), at most `timeout`. True when it did.
    bool wait_for_disconnect(std::chrono::milliseconds timeout);
    bool terminate_requested() const;

    // ---- any thread
    // An `output` event for the debug console. category: "console", "stdout", "stderr".
    void send_output(const std::string& category, const std::string& text, const std::string& file = {}, int line = 0);

    // ---- DebugClient (script thread)
    DebugResume paused(const DebugStop& stop, PausedScripts& scripts) override;
    void output(std::string_view category, std::string_view text, const std::string& file, int line) override;
    void poll(ScriptSystem& scripts) override;

    // ---- paths (public for tests)
    // The project-relative module name of an absolute path the client sent, or "" with `why` set.
    std::string module_name(const std::string& absolutePath, std::string& why) const;
    // The absolute path of a project-relative module, as the client should see it.
    std::string absolute_path(const std::string& moduleName) const;

private:
    struct Item {  // a request that needs the paused game
        Json request;
    };

    void send_event(const std::string& event, Json body = Json::object());
    void send_response(const Json& request, bool success, Json body = Json::object(), const std::string& message = {});
    void send_json(Json message);

    // Handlers of the reader thread: return the body or throw Failure.
    struct Failure {
        std::string message;
    };
    Json dispatch(const std::string& command, const Json& args, const Json& request, bool& answered);
    Json on_initialize(const Json& args);
    Json on_launch(const Json& args, const Json& request, bool& answered);
    Json on_set_breakpoints(const Json& args);
    Json on_set_exception_breakpoints(const Json& args);
    Json on_source(const Json& args);
    void apply_deferred(bool launched);
    Json set_breakpoints_now(const Json& args);

    // On the paused game (main thread).
    bool run_paused_request(const Item& item, PausedScripts& scripts, DebugResume& resume);
    Json stack_trace_body(const Json& args, PausedScripts& scripts);
    Json value_body(const DebugValue& v) const;
    int line_to_client(int line) const { return linesStartAt1_ ? line : line - 1; }
    int line_from_client(int line) const { return linesStartAt1_ ? line : line + 1; }
    int column_to_client(int column) const { return columnsStartAt1_ ? column : column - 1; }

    Sink sink_;
    ScriptInstrumenter instrumenter_;
    std::atomic<int> seq_{1};
    std::mutex sendMutex_;  // seq numbers and the sink call stay in order

    mutable std::mutex mutex_;
    std::condition_variable cv_;
    // state guarded by mutex_
    bool initialized_ = false;
    bool launched_ = false;
    bool launchFailed_ = false;
    bool configDone_ = false;
    bool disconnected_ = false;
    bool terminate_ = false;
    bool paused_ = false;
    bool finished_ = false;
    bool linesStartAt1_ = true;
    bool columnsStartAt1_ = true;
    std::deque<Item> queue_;
    std::vector<Json> evalPending_;  // evaluate requests received while the game runs; answered by poll()
    std::vector<Json> deferred_;     // setBreakpoints received before launch
    bool exceptionAll_ = false;
    bool exceptionUncaught_ = true;
    DapLaunchArgs launch_;
    std::string projectCanon_;  // normalised project folder, for comparing paths
    std::shared_ptr<ScriptDebugger> debugger_;
};

}  // namespace fa
