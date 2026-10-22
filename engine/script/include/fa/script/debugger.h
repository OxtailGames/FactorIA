// Script debugger: breakpoints, stepping and inspection of a project's JavaScript (docs/design/SCRIPT_DEBUGGER.md).
//
// QuickJS-ng has no debug API, so a debugged run compiles every project module from an INSTRUMENTED copy of its source:
// a hook before each statement, a frame record per function call, one closure per frame that evaluates expressions in
// the frame's scope (direct eval). The instrumenter is developer tooling (fa/tooling/script_instrument.h: it embeds the
// acorn parser); the script runtime only consumes what it returns. Exported games (bytecode) are never instrumented.
//
// Who does what:
//   - `factoria dap` (the Debug Adapter Protocol server for VS Code) and the `script.trace` command create a
//     ScriptDebugger with their DebugClient and pass it in EngineConfig::scriptDebugger.
//   - The ScriptSystem of that engine instruments the project's modules, runs the hooks, and calls
//     DebugClient::paused on the script thread when execution stops. The game is blocked until paused returns.
//   - Everything else on ScriptDebugger may be called from any thread (the DAP reader thread sets breakpoints and
//     requests a pause while the game runs).
#pragma once

#include <algorithm>
#include <functional>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/types.h"

namespace fa {

class ScriptSystem;

// ---------------------------------------------------------------------------------------------------------- instrumenting
// What the instrumenter learnt about one module. Lines are 1-based. Columns are 1-based UTF-8 byte columns (the unit
// QuickJS reports in errors and stacks), always in the ORIGINAL source.
struct ScriptDebugInfo {
    // A statement with a hook in front of it; its index is the `K` of `__fa_h(__fa_f, K)`.
    struct Statement {
        int line = 0;
        int column = 0;
        int scope = 0;  // innermost scope that contains the statement (index into `scopes`)
    };
    // A function with a frame record; its index is the `FID` of `__fa_d.e(FID, ...)`.
    struct Function {
        std::string name;  // "Player.onUpdate", "spawn", "(anonymous)"; see SCRIPT_DEBUGGER.md for the naming rules
        int line = 0;      // where the function starts (its name, or its first token)
        int column = 0;
        int endLine = 0;
        int scope = 0;     // the scope of its body (holds the parameters and `this`)
    };
    // A lexical scope and the names it declares, so the Variables view knows what to ask the frame's closure for.
    struct Scope {
        int parent = -1;   // -1 for the module scope (always scope 0)
        std::string kind;  // "module", "function", "block" or "catch"
        std::vector<std::string> names;  // declaration order; a function scope lists "this" first when it has its own
    };
    // `length` bytes were inserted on `line` just before original column `column`.
    struct Shift {
        int line = 0;
        int column = 0;
        int length = 0;
    };
    std::vector<Statement> statements;
    std::vector<Function> functions;
    std::vector<Scope> scopes;
    std::vector<Shift> shifts;  // sorted by line, then column

    // Lines that have at least one statement hook, ascending, without duplicates.
    std::vector<int> breakable_lines() const {
        std::vector<int> lines;
        for (const Statement& s : statements) lines.push_back(s.line);
        std::sort(lines.begin(), lines.end());
        lines.erase(std::unique(lines.begin(), lines.end()), lines.end());
        return lines;
    }

    // Maps a column of the instrumented code (from an error or a stack) back to the original source. A column inside
    // inserted text maps to the original column the text was inserted before.
    int original_column(int line, int column) const {
        int inserted = 0;
        for (const Shift& s : shifts) {
            if (s.line < line) continue;
            if (s.line > line) break;
            int start = s.column + inserted;  // where this insertion begins in the instrumented line
            if (column < start) break;
            if (column < start + s.length) return s.column;
            inserted += s.length;
        }
        return column - inserted;
    }
};

struct InstrumentedScript {
    std::string code;  // same number of lines as the original: text is only ever inserted, never a newline
    ScriptDebugInfo info;
};

// file: project-relative module path ("scripts/player.js"), for error messages. moduleId: written into the code as
// `__fa_d.m(moduleId, ...)` so the runtime can find `info` again. An error means the source does not parse: the module
// is then compiled as written, so QuickJS reports the syntax error the way it always does.
using ScriptInstrumenter =
    std::function<Result<InstrumentedScript>(const std::string& file, std::string_view source, int moduleId)>;

// ---------------------------------------------------------------------------------------------------------- client side
enum class DebugResume { Continue, StepIn, StepOver, StepOut };

// One source breakpoint, as DAP setBreakpoints sends it.
struct DebugBreakpoint {
    int line = 0;              // 1-based; moved to the next breakable line of the file
    std::string condition;     // JS expression evaluated in the frame: stop only when it is truthy
    std::string hitCondition;  // "5" or "== 5" (only the 5th hit), ">= 5", "> 5", "% 5" (every 5th)
    std::string logMessage;    // a logpoint: print it ({expression} parts interpolated) instead of stopping
};

struct DebugBreakpointState {
    int id = 0;             // unique for the whole session
    bool verified = false;  // false: no breakable line at or after `line` in the file, or the file does not parse
    int line = 0;           // where it really is
    std::string message;    // why it is not verified
};

struct DebugStop {
    std::string reason;       // "breakpoint", "step", "pause", "exception", "debugger" (statement), "entry"
    std::string description;  // shown by VS Code: "Paused on breakpoint", the exception's message
    std::string exceptionText;           // exception stops: "TypeError: x is undefined" and its stack
    std::vector<int> hitBreakpointIds;   // breakpoint stops
};

struct DebugFrame {
    int id = 0;        // valid until the debugger resumes
    std::string name;  // ScriptDebugInfo::Function::name, or "(module)" for module top-level code
    std::string file;  // project-relative
    int line = 0;
    int column = 0;
};

struct DebugScope {
    std::string name;            // "Locals", "Closure (outerName)", "Module"
    int variablesReference = 0;  // for variables()
    bool expensive = false;
};

struct DebugValue {
    std::string name;
    std::string value;           // a short preview: 300, "hi", Player {speed: 300, jumpSpeed: 620, …}, ƒ onUpdate(dt)
    std::string type;            // "number", "string", "object", "function", "undefined"...
    int variablesReference = 0;  // > 0: expandable with variables()
    int namedVariables = 0;      // hints for VS Code paging
    int indexedVariables = 0;
};

// What a client may ask while the scripts are paused. Only valid inside DebugClient::paused, on the script thread.
class PausedScripts {
public:
    virtual ~PausedScripts() = default;
    virtual std::vector<DebugFrame> stack() = 0;  // innermost first
    virtual std::vector<DebugScope> scopes(int frameId) = 0;
    // count 0 = all. Objects list their own properties, then [[Prototype]]; arrays page by index.
    virtual std::vector<DebugValue> variables(int variablesReference, int start, int count) = 0;
    // Evaluates in the frame's scope (frameId 0: the global scope). Runs real code: it can change the game.
    virtual Result<DebugValue> evaluate(int frameId, std::string_view expression) = 0;
    // `name` is a variable of a scope or a property of an object; `valueExpression` is evaluated in the top frame.
    virtual Result<DebugValue> set_variable(int variablesReference, std::string_view name,
                                            std::string_view valueExpression) = 0;
};

class DebugClient {
public:
    virtual ~DebugClient() = default;
    // Script thread. The game is blocked until this returns how to go on.
    virtual DebugResume paused(const DebugStop& stop, PausedScripts& scripts) = 0;
    // Script thread. Logpoint messages ("console"), console.log while debugging ("stdout"), script errors ("stderr").
    // `file`/`line`: where it comes from, project-relative ("" and 0 when unknown).
    virtual void output(std::string_view category, std::string_view text, const std::string& file, int line) {
        (void)category, (void)text, (void)file, (void)line;
    }
    // Script thread, once at the start of every frame while the game runs: the moment to use the ScriptSystem
    // (ScriptSystem::eval for a REPL line typed while the game is not paused).
    virtual void poll(ScriptSystem& scripts) { (void)scripts; }
};

class ScriptDebugger {
public:
    // projectDir: where files named in set_breakpoints are read from when their module is not loaded yet.
    ScriptDebugger(DebugClient& client, ScriptInstrumenter instrumenter, std::string projectDir);
    ~ScriptDebugger();
    ScriptDebugger(const ScriptDebugger&) = delete;
    ScriptDebugger& operator=(const ScriptDebugger&) = delete;

    // Any thread. Replaces every breakpoint of `file` (project-relative); the result has one state per breakpoint, in order.
    std::vector<DebugBreakpointState> set_breakpoints(const std::string& file, const std::vector<DebugBreakpoint>& breakpoints);
    // Any thread. all: stop at every exception where it is first seen. uncaught: stop where an exception leaves the
    // scripts (the engine would report it as a script error).
    void set_exception_filters(bool all, bool uncaught);
    // Any thread. Stop at the next statement that runs, even inside an endless loop.
    void request_pause();
    // Any thread. Resumes the scripts if they are paused and asks the engine to quit at the start of the next frame.
    void request_terminate();
    // Before the engine starts: stop at the first statement of the first project module that runs.
    void set_stop_on_entry(bool stop);

    DebugClient& client();
    const ScriptInstrumenter& instrumenter() const;

    struct Impl;
    Impl& impl() { return *impl_; }

private:
    std::unique_ptr<Impl> impl_;
};

}  // namespace fa
