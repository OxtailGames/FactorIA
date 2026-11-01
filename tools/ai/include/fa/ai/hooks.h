// Hooks for every provider: Claude Code's hook events (SessionStart, UserPromptSubmit, PreToolUse, PostToolUse,
// PostToolUseFailure, Stop, SessionEnd) run by FactorIA's own loop with the same JSON on stdin and the same decisions on
// stdout, so one script serves Claude Code and the API providers, plus two events of the engine itself, beforeCommand and
// afterCommand, that fire around every command of the registry for every caller (docs/HOOKS.md).
//
// The configuration is M45.1's: "hooks" entries of `extensions` (extensions.h). A handler is a program ("command", user level
// or a trusted project) or a JavaScript module of the project's hooks/ folder ("js", run by hook_js.h in a sandbox, no trust
// needed). This header is the events, the matching, the run of the handlers and the reading of what they answer; session.cpp
// and command_hooks.cpp decide what to do with the answer.
#pragma once

#include <functional>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/process.h"
#include "fa/core/types.h"

namespace fa::ai {

enum class HookEvent {
    SessionStart,
    UserPromptSubmit,
    PreToolUse,
    PostToolUse,
    PostToolUseFailure,
    Stop,
    SessionEnd,
    BeforeCommand,  // engine event: before a registry command runs (matcher: the command name)
    AfterCommand,   // engine event: after it ran, whatever the outcome
};
const char* hook_event_name(HookEvent e);                       // "PreToolUse", "beforeCommand"...
std::optional<HookEvent> parse_hook_event(std::string_view s);  // the exact name, else nullopt
std::vector<std::string> engine_hook_event_names();             // every name parse_hook_event accepts
// beforeCommand and afterCommand exist in FactorIA only: Claude Code is never given them.
bool is_command_hook_event(HookEvent e);
// What the matcher of a group is compared with: the tool name (PreToolUse, PostToolUse, PostToolUseFailure), the command name
// (beforeCommand, afterCommand), SessionStart's source, SessionEnd's reason. UserPromptSubmit and Stop have no matcher.
bool hook_event_has_matcher(HookEvent e);
// Whether the event can refuse what is about to happen: PreToolUse, UserPromptSubmit, Stop, beforeCommand.
bool hook_event_can_block(HookEvent e);

inline constexpr double kDefaultHookTimeoutSeconds = 60;
inline constexpr double kMaxHookTimeoutSeconds = 3600;
inline constexpr const char* kProjectHooksFolder = "hooks";

// Claude Code's matcher: "", "*" or none = everything; letters, digits, _ - space , | = a list of exact names; anything else
// is a regular expression, tested unanchored. For command events (names such as "scene.spawn") the dot is part of the name:
// a matcher of letters, digits, _ - . , | * is a list of names where * stands for any text ("scene.*", "assets.generate_*").
bool hook_matches(HookEvent event, std::string_view matcher, std::string_view value);
// "" when the matcher is usable, else what is wrong (a regular expression that does not compile).
std::string hook_matcher_problem(std::string_view matcher);

// "" when `module` is a usable "module" of a js handler: a project-relative .js file inside the hooks/ folder (no "..", no
// absolute path, no backslash), else what is wrong and what to write.
std::string hook_module_problem(std::string_view module);

struct HookHandler {
    std::string type;        // "command", "js"; "http", "prompt" and "agent" are Claude Code's and not run here
    std::string command;     // command: run by the shell, in the project folder
    std::string module;      // js: a .js file inside the project's hooks/ folder
    double timeoutSeconds = 0;  // 0 = kDefaultHookTimeoutSeconds
    std::string extension;   // the entry of `extensions` it came from
    std::string source;      // "user" or "project"
    std::string label() const;  // "<extension>: <command or module>", at most ~100 characters
    bool runs_here() const { return type == "command" || type == "js"; }
};
struct HookGroup {
    HookEvent event = HookEvent::PreToolUse;
    std::string matcher;
    std::vector<HookHandler> handlers;
};

// Where a part of the configuration came from.
struct HookSource {
    std::string extension;
    std::string source;  // "user" or "project"
    Json hooks;          // the entry's events object
};

struct HookSet {
    std::vector<HookGroup> groups;
    // Handlers of a type FactorIA's loop does not run (http, prompt, agent), once each: "<extension>: <Event> hook of type
    // http runs only in Claude Code".
    std::vector<std::string> notRun;
    bool empty() const { return groups.empty(); }
    bool has_event(HookEvent e) const;
    // Groups of `event` whose matcher fits `value`.
    std::vector<const HookGroup*> matching(HookEvent event, std::string_view value) const;
    // The same hooks for the events `keep` accepts.
    HookSet only(const std::function<bool(HookEvent)>& keep) const;
};
// Reads the events FactorIA runs out of the entries' hooks objects (a validated Claude Code hooks object, plus beforeCommand and
// afterCommand). Events it does not run itself are left alone: they are Claude Code's.
HookSet make_hook_set(const std::vector<HookSource>& sources);

// What Claude Code receives of a hooks object: the engine events (beforeCommand, afterCommand) are taken out, and a "js" handler
// becomes the program that runs it, `<factoria> hooks run <module> --project <dir>`, which reads the event on stdin and answers
// as a hook program does. {} when nothing is left.
Json hooks_for_claude_code(const Json& hooks, const std::string& factoriaCommand, const std::string& projectDir);

// One run of one handler, as the session log and the editor show it.
struct HookRunRecord {
    HookEvent event = HookEvent::PreToolUse;
    std::string matched;     // what the matcher saw: the tool or command name, the source...
    std::string extension;
    std::string source;
    std::string type;        // command | js
    std::string target;      // the command line or the module
    std::int64_t startedMs = 0;  // Unix ms
    double ms = 0;           // how long it took
    int exitCode = -1;       // command: its exit code (-1 = it did not exit: timed out, could not start)
    bool timedOut = false;
    bool failed = false;     // could not start, timed out, crashed, exit code other than 0 and 2, output it should not give
    std::string error;       // why it failed, one sentence that also says what to do
    std::string decision;    // what it decided: "block", "allow", "ask", "stop", "context", "" (nothing)
    std::string reason;      // block / stop reason
    std::string output;      // stdout, clipped
    std::string stderrText;  // clipped
    Json to_json() const;    // the "hook" line of a session log (without "kind" and "t")
};

struct HookOutcome {
    bool blocked = false;       // the action must not happen (exit 2, decision "block", permissionDecision "deny")
    std::string reason;         // why, as the hook said (several are joined)
    std::string blockedBy;      // label of the first handler that blocked
    bool stop = false;          // `continue: false`
    std::string stopReason;
    std::vector<std::string> context;   // additionalContext, and the plain stdout of SessionStart / UserPromptSubmit
    std::vector<std::string> feedback;  // PostToolUse / PostToolUseFailure `decision: "block"` reasons: shown next to the result
    std::vector<std::string> systemMessages;
    std::optional<Json> updatedInput;       // PreToolUse: replaces the tool's arguments
    std::optional<Json> updatedToolOutput;  // PostToolUse: replaces the result the model sees
    bool allowed = false;                   // PreToolUse: a hook answered permissionDecision "allow"
    std::vector<HookRunRecord> runs;
    bool anyFailed() const;
    std::string failures() const;  // "label: error" per failed run, one line each
};

struct HookRunContext {
    std::string projectDir;      // the hooks run here; CLAUDE_PROJECT_DIR; where hooks/ is
    std::string sessionId;
    std::string transcriptPath;
    std::string permissionMode = "default";
    std::string agentType;       // a delegated run: its role
    const CancelFlag* cancel = nullptr;
    // Called after each handler ran (also when it failed), on the calling thread: the session log, the editor.
    std::function<void(const HookRunRecord&)> onRun;
    // Replaces the default timeout of handlers that name none (tests).
    double defaultTimeoutSeconds = 0;
};

// Runs, in order, the handlers of the groups of `set` that match `event` and `matchValue`, with `input` (the event-specific fields)
// plus the common ones (session_id, transcript_path, cwd, hook_event_name, permission_mode) on stdin, and gathers what they decided.
// Never throws: a handler that cannot run is a failed HookRunRecord.
HookOutcome run_hooks(const HookSet& set, HookEvent event, std::string_view matchValue, const Json& input, const HookRunContext& ctx);

// How a handler's answer is read (exposed for tests and for the JS hooks, whose return value is the stdout JSON): adds what
// `answer` decides for `event` to `out` and fills `rec` (decision, reason). `answer` is the parsed JSON stdout.
void apply_hook_answer(HookEvent event, const Json& answer, const std::string& label, HookOutcome& out, HookRunRecord& rec);

// What a run of hooks decided, as JSON ({blocked, reason, blockedBy, stop, stopReason, context, feedback, systemMessages, allowed,
// updatedInput?, updatedToolOutput?, failed, runs:[...]}): ai.hooks_test and the editor.
Json hook_outcome_json(const HookOutcome& o);

// The last runs of every handler in this process (an AI session, a command hook, `ai.hooks_test`), newest last, up to 300: what
// the editor's Extensions tab and `ai.hooks` show. run_hooks records each run here.
void note_hook_run(const HookRunRecord& rec);
std::vector<HookRunRecord> recent_hook_runs(std::size_t max = 100);
void clear_recent_hook_runs();

// A JSON object for the common fields of an event's stdin.
Json hook_common_input(HookEvent event, const HookRunContext& ctx);

}  // namespace fa::ai
