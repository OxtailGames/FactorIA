// Command registry: the single list of operations that tools and AIs can run.
//
// A command is a named function JSON -> JSON with documentation and a JSON
// Schema for its arguments. The SAME registry is exposed through:
//   * MCP tools            (`factoria mcp`, names with '.' replaced by '_')
//   * the built-in AI agent (API-key providers call them as tools)
//   * the CLI              (`factoria call scene.spawn '{"name":"Enemy"}'`)
//   * the editor console and JavaScript (`fa.call("scene.spawn", {...})`)
// so a capability added once is immediately usable by every AI client.
//
// Naming: "<area>.<verb_object>" in snake_case, e.g. "scene.list_entities",
// "game.step", "game.screenshot", "feedback.report".
//
// Handlers report failures by throwing fa::CommandError (code + message + hint);
// the registry converts any exception into a structured error result.
#pragma once

#include <atomic>
#include <functional>
#include <map>
#include <memory>
#include <optional>
#include <stdexcept>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/capability.h"
#include "fa/core/json.h"
#include "fa/core/json_schema.h"

namespace fa::jobs {
class Owner;
}

namespace fa {

struct CommandError : std::runtime_error {
    std::string code;  // "not_found", "invalid_argument", "failed", "unavailable"...
    std::string hint;  // how to fix, e.g. "Use scene.list_entities to see valid ids."
    Json data;         // optional structured details (e.g. the problems a check tool found)
    CommandError(std::string code_, const std::string& message, std::string hint_ = {}, Json data_ = nullptr)
        : std::runtime_error(message), code(std::move(code_)), hint(std::move(hint_)), data(std::move(data_)) {}
};

// A description may carry its details itself, for commands that a helper builds from a summary and a description:
// CommandRegistry::add moves everything after this one character (a literal of its own: "short text" FA_COMMAND_DETAILS "the rest")
// into CommandInfo::details.
inline constexpr char kCommandDetailsMark = '\x1e';
#define FA_COMMAND_DETAILS "\x1e"

struct CommandInfo {
    std::string name;         // "scene.spawn"
    std::string summary;      // one line, imperative ("Create an entity from JSON.")
    std::string description;  // details, caveats and at least one example call
    Json inputSchema = Json::object({{"type", "object"}, {"properties", Json::object()}});
    bool readOnly = true;  // false if it mutates game/project state
    std::string category;  // "scene", "game", "project", "assets", "feedback", "docs", "fs"...
    // What does not fit in `description`. MCP's tools/list sends summary + description with every request, so a description
    // stays under 1.5 KB (a test holds every command to it) and the rest goes here. It is in the docs reference
    // (docs/reference/commands, docs.commands {"name": ...}, `factoria commands <name>`); the description MCP sends ends by
    // saying where to read it (command_details_pointer).
    std::string details;

    // (After `details`, so the positional initialisers of CommandInfo{name, summary, ...} keep working.)
    // What the command can do outside the engine's memory (capability.h). The registry refuses a call whose caller is not
    // granted every one of them (code "capability_denied"). Set it (a non-empty set) to declare it; CommandRegistry::add
    // fills in a command that declares nothing from readOnly: {read} when readOnly, {read, state, writeProject} otherwise
    // (conservative: it never includes writeAnywhere, network, process, spend or publish, so a command that needs one of
    // those must declare it) and leaves capabilitiesDeclared false.
    CapabilitySet capabilities;
    bool capabilitiesDeclared = false;  // true once the command declared `capabilities` itself (set by add())

    // description + details: what a doc-facts test looks in, and what the docs reference prints.
    std::string full_description() const { return details.empty() ? description : description + "\n\n" + details; }
};

using CommandHandler = std::function<Json(const Json& args)>;

// Progress of a long-running command (ai.run...). The code that calls the registry (the MCP server answering a
// tools/call that carries a progressToken) installs a sink with a CommandProgressScope on the calling thread; the
// handler reports short human-readable messages ("worker: Bash cmake --build") through report_command_progress().
// The sink forwards them (MCP notifications/progress) and returns false when nobody listens any more. With no sink
// installed, reporting is a no-op, so handlers call it unconditionally. The scope is per thread: a handler that moves
// its work to another thread must report from the thread the registry called it on.
using CommandProgressSink = std::function<bool(std::string_view message)>;

class CommandProgressScope {
public:
    explicit CommandProgressScope(CommandProgressSink sink);
    ~CommandProgressScope();
    CommandProgressScope(const CommandProgressScope&) = delete;
    CommandProgressScope& operator=(const CommandProgressScope&) = delete;

private:
    CommandProgressSink previous_;
};

// True if the calling thread is inside a CommandProgressScope (someone listens).
bool command_progress_active();
// Sends `message` to the installed sink; returns false if there is none or it reported that nobody listens.
bool report_command_progress(std::string_view message);

// Cancellation of a running command. The code that calls the registry for someone who can take the request back (the MCP
// server, whose client sends notifications/cancelled) installs a flag with a CommandCancelScope on the calling thread and
// sets it when the request is cancelled. While the flag is set, CommandRegistry::call() refuses every call made on that
// thread (code "cancelled": a compound command or an agent stops at its next command), and a long handler polls
// command_cancelled() or hands command_cancel_flag() to what it waits on (an agent session, run_process) to stop early.
// Like the progress scope it is per thread and the flag must outlive the scope; a handler that moves its work to another
// thread hands the flag over. Without a scope nothing is ever cancelled.
class CommandCancelScope {
public:
    explicit CommandCancelScope(const std::atomic<bool>* flag);
    ~CommandCancelScope();
    CommandCancelScope(const CommandCancelScope&) = delete;
    CommandCancelScope& operator=(const CommandCancelScope&) = delete;

private:
    const std::atomic<bool>* previous_;
};

// The flag of the innermost CommandCancelScope of this thread; null outside any.
const std::atomic<bool>* command_cancel_flag();
// True once the request the running command belongs to was cancelled.
bool command_cancelled();

// Who is behind the call that is running on this thread. A handler that must not do something on an AI's say-so (ai.settings.set
// with scope "user" changes the user's own defaults) asks command_caller(). The code that hands a call to the registry on an AI's
// behalf installs a CommandCallerScope: the MCP server (every tools/call, so the editor's per-run endpoint and `factoria mcp`) and
// the agent session (each tool call of the in-engine agents and their delegates). Callers that install nothing are the user's own
// (`factoria call` run by the user, the editor's console, the AI settings window). The scope is per thread and only gets stricter: a scope inside
// another one that is not User keeps the outer one. A handler that moves work to another thread (the editor's main-thread queue
// does) hands command_caller() over and installs it there again.
enum class CommandCaller { User, Agent, Mcp };

class CommandCallerScope {
public:
    explicit CommandCallerScope(CommandCaller caller);
    ~CommandCallerScope();
    CommandCallerScope(const CommandCallerScope&) = delete;
    CommandCallerScope& operator=(const CommandCallerScope&) = delete;

private:
    CommandCaller previous_;
    CapabilitySet previousGranted_;
};

// A process whose own caller is not the user: the CLI agents (Claude Code, Codex) factoria starts get FACTORIA_CALLER in their
// environment (kCallerEnvVar), and a `factoria` they run (`factoria call ai.settings.set ...`) has no thread scope to read. While a
// CommandCallerFloor lives, command_caller() is never below `floor` on ANY thread of the process. Like the scope it only gets
// stricter: a floor inside another keeps the stricter one.
inline constexpr const char* kCallerEnvVar = "FACTORIA_CALLER";

class CommandCallerFloor {
public:
    explicit CommandCallerFloor(CommandCaller floor);
    ~CommandCallerFloor();
    CommandCallerFloor(const CommandCallerFloor&) = delete;
    CommandCallerFloor& operator=(const CommandCallerFloor&) = delete;

private:
    CommandCaller previous_;
};

// What FACTORIA_CALLER says: nullopt when the variable is unset or empty; "mcp" is Mcp; ANY other value (agent, or one this
// engine does not know) is Agent. Never User: a variable that is set can only restrict.
std::optional<CommandCaller> command_caller_from_env_value(const char* value);
std::optional<CommandCaller> command_caller_from_env();  // reads kCallerEnvVar

CommandCaller command_caller();  // the caller of the command running on this thread (User outside any scope)
const char* command_caller_name(CommandCaller caller);  // "the user", "an AI agent", "an MCP client"

// What the caller of the command running on this thread may do (capability.h). It is the set of the caller's kind
// (capability_sets::cli_user for the User, mcp for Mcp, agent for Agent; command_caller() includes the process-wide floor)
// narrowed by every CommandCapabilityScope and CommandCallerScope of this thread. CommandRegistry::call refuses a command
// whose CommandInfo::capabilities are not all inside it (code "capability_denied").
CapabilitySet caller_capabilities();
// The set a CommandCaller starts from.
CapabilitySet capabilities_for_caller(CommandCaller caller);

// For a handler that writes a file only when its caller passes a path (game.screenshot `path`): the command itself is
// declared with the capabilities of its default behaviour, and this checks the one the path needs. Throws CommandError
// "capability_denied" (same data shape as the dispatcher's refusal: command, missing, granted) when the caller lacks it.
void require_capability(Capability needed, std::string_view command, std::string_view reason);
// require_capability(WriteProject, ...) and then fs::resolve_for_write(path, WriteRoot::Project, <writeAnywhere granted>):
// returns the absolute UTF-8 path to write, or throws CommandError with the path error's code (path_outside_root,
// absolute_path_denied, managed_path_denied...), message and hint.
std::string resolve_caller_write_path(std::string_view path, std::string_view command);
// The same, returned in the form the project's file API takes (fs::project_spelling): relative to the project when the
// file lies inside it, else absolute. For a command that reads the file back, names it in its result or keeps it in a map.
std::string resolve_caller_project_path(std::string_view path, std::string_view command);

// What a "capability_denied" refusal is about, handed to a CapabilityHintProvider.
struct CapabilityDenial {
    const CommandInfo& command;  // the refused command (name, declared capabilities)
    CapabilitySet missing;       // what it needs and the caller lacks
    CapabilitySet granted;       // what the caller has
};

// Says where THIS caller gets what it lacks: the hint of the "capability_denied" error. The default hint (core) names the
// callers of the engine in general; a script host installs a provider (CommandCapabilityScope's second argument) so a game
// script, an editor Play script or a test is told what applies to it. An empty answer keeps the default.
class CapabilityHintProvider {
public:
    virtual ~CapabilityHintProvider() = default;
    virtual std::string hint(const CapabilityDenial& denial) const = 0;
};

// Narrows what the calls made on this thread inside the scope may do. Like CommandCallerScope it only ever narrows: the
// granted set becomes the intersection of the current one and `granted`, so a nested scope cannot widen what an outer
// one took away. That also means a nested call cannot say "this one legitimately runs with the tool's own set": a
// handler that needs more than its caller has is refused, by design. `factoria mcp --read-only` installs
// capability_sets::mcp_read_only(), a test run installs capability_sets::test_script() plus what the test asked for.
// The scope is per thread; code that hops threads takes a command_context() snapshot and installs it there.
class CommandCapabilityScope {
public:
    // `hint`: (optional) words the hint of a capability_denied error raised inside the scope; a nested scope without one keeps
    // the outer scope's, so a tool a game script calls is refused with the game script's hint.
    explicit CommandCapabilityScope(CapabilitySet granted,
                                    std::shared_ptr<const CapabilityHintProvider> hint = nullptr);
    ~CommandCapabilityScope();
    CommandCapabilityScope(const CommandCapabilityScope&) = delete;
    CommandCapabilityScope& operator=(const CommandCapabilityScope&) = delete;

private:
    CapabilitySet previous_;
    std::shared_ptr<const CapabilityHintProvider> previousHint_;
};

// A process whose capabilities are narrower than its caller kind's: the CLI agents factoria starts for a role get
// FACTORIA_CAPABILITIES (the role's set, names separated by commas; "none" = the empty set) and FACTORIA_ROLE (its name, for the
// words of a refusal) in their environment, and a `factoria mcp` or `factoria call` they run has no thread scope to read. While a
// CommandCapabilityFloor lives, caller_capabilities() is never wider than `granted` on ANY thread of the process. Like the
// scopes it only narrows (a floor inside another one keeps the intersection) and its optional `hint` words the refusals on threads
// whose own scope has no hint provider (the innermost floor with one wins). An unparsable variable is the empty set: a restriction
// that cannot be read is not dropped.
inline constexpr const char* kCapabilitiesEnvVar = "FACTORIA_CAPABILITIES";
inline constexpr const char* kRoleEnvVar = "FACTORIA_ROLE";

class CommandCapabilityFloor {
public:
    explicit CommandCapabilityFloor(CapabilitySet granted,
                                    std::shared_ptr<const CapabilityHintProvider> hint = nullptr);
    ~CommandCapabilityFloor();
    CommandCapabilityFloor(const CommandCapabilityFloor&) = delete;
    CommandCapabilityFloor& operator=(const CommandCapabilityFloor&) = delete;

private:
    CapabilitySet previous_;
    std::shared_ptr<const CapabilityHintProvider> previousHint_;
};

// What FACTORIA_CAPABILITIES says: nullopt when unset or empty; "none" is the empty set; otherwise CapabilitySet::parse_list, and a
// text that does not parse (an unknown name) is the EMPTY set (fail closed).
std::optional<CapabilitySet> command_capabilities_from_env_value(const char* value);
std::optional<CapabilitySet> command_capabilities_from_env();  // reads kCapabilitiesEnvVar
// The text to put in kCapabilitiesEnvVar for `set` ("read,state"; "none" for the empty set).
std::string capabilities_env_value(CapabilitySet set);

// Who is calling and what they may do, as one value a job queue or the editor's main-thread queue captures on the calling
// thread (command_context()) and installs again on the thread that runs the command (CommandContextScope), the way
// command_caller() is handed over today. The words of a refusal (the hint provider) travel with it.
struct CommandContext {
    CommandCaller caller = CommandCaller::User;
    CapabilitySet capabilities = CapabilitySet::all();
    std::shared_ptr<const CapabilityHintProvider> hint;  // the hint provider in force (null = the default hint)
};

CommandContext command_context();

class CommandContextScope {
public:
    explicit CommandContextScope(const CommandContext& context)
        : caller_(context.caller), capabilities_(context.capabilities, context.hint) {}
    CommandContextScope(const CommandContextScope&) = delete;
    CommandContextScope& operator=(const CommandContextScope&) = delete;

private:
    CommandCallerScope caller_;
    CommandCapabilityScope capabilities_;
};

// Outcome of a call. `result` is the handler's JSON on success; on failure
// `error` = {"code": .., "message": .., "hint": ..}.
struct CommandResult {
    bool ok = false;
    Json result;
    Json error;
};

// Sees every call() of a registry from outside the engine's own modules (beforeCommand / afterCommand hooks, fa_ai's
// command_hooks.h). Installed with CommandRegistry::set_interceptor; the registry stays free of any knowledge of what it does.
struct CommandInterceptor {
    // Asked at the start of every call() with the command name: false = this call is not intercepted. Must be cheap (a lookup in a
    // table that was already built): it runs on every call.
    std::function<bool(std::string_view name)> wants;
    // Before the arguments are validated and the handler runs; not reached for a call the caller's capabilities refuse
    // (capability_denied comes first; only a command that a beforeCall_ reload registers is checked after `before`). May change `args`. Returns a failed CommandResult to refuse the call
    // (the handler does not run, `after` is not called), nullopt to go ahead.
    std::function<std::optional<CommandResult>(std::string_view name, Json& args)> before;
    // After the handler ran, whatever the outcome, with the arguments it got and how long the call took. May add to `result`
    // (the hooks add "hookWarnings" to an object result when a hook failed).
    std::function<void(std::string_view name, const Json& args, CommandResult& result, double ms)> after;
};

class CommandRegistry {
public:
    // Replaces an existing command with the same name.
    void add(CommandInfo info, CommandHandler handler);
    // Declares (and flags as declared) the capabilities of an already added command and sets readOnly to match
    // (readOnly == the set holds nothing but "read"): readOnly is recomputed from the set, never kept from add(). False,
    // and nothing changed, if there is no such command or the set is empty (a command needs at least "read"; logged).
    // The modules that register many commands call declare_command_capabilities (below) once with a table, right after
    // their add() calls.
    bool declare_capabilities(std::string_view name, CapabilitySet capabilities);
    void remove(std::string_view name);
    bool has(std::string_view name) const;
    const CommandInfo* info(std::string_view name) const;
    // The handler of `name` (empty when there is none): a caller re-adds the command with a handler that wraps it.
    CommandHandler handler(std::string_view name) const;
    std::vector<const CommandInfo*> list(std::string_view category = {}) const;  // sorted by name

    // Validates `args` against inputSchema (fills defaults for missing optional
    // properties that declare "default"), runs the handler, never throws. The handler gets the caller's `args` itself, not a
    // copy, when the call does not change them (no default to fill, no `_meta` to strip): it must not keep a reference to it
    // past its return (a copy of the Json is fine).
    // Unknown command -> code "unknown_command" with a "did you mean" hint. A command whose capabilities the caller is
    // not granted (caller_capabilities()) -> code "capability_denied", before the arguments are looked at.
    CommandResult call(std::string_view name, const Json& args = Json::object()) const;

    // [{name, summary, description, details, inputSchema, readOnly, capabilities, capabilitiesDeclared, category}, ...]
    // `capabilities`: camelCase names of what the command may do (capability.h). `capabilitiesDeclared`: false while the command
    // has not declared them itself (the set is then derived from readOnly and is only a guess).
    Json describe() const;

    // Called at the start of every outermost call() (not for calls made from inside a running handler, nor from a job
    // worker thread; the nesting is tracked per thread), before the command is looked up, with the command name. The script system uses it to re-import project tools edited on disk,
    // which replaces commands: that is only safe while no handler is running. Empty = none.
    void set_before_call(std::function<void(std::string_view)> hook) { beforeCall_ = std::move(hook); }

    // The job owner (fa/core/jobs.h) of everything a handler queues: call() makes it the thread's current owner while
    // the handler runs, so the jobs and main-thread tasks a command starts belong to the registry's engine. Null (the
    // default) leaves the caller's current owner as it is.
    void set_job_owner(jobs::Owner* owner) { jobOwner_ = owner; }

    // Installs (or, with null, removes) the interceptor. Not to be called while another thread is inside call(). A registry without
    // one pays a single pointer test per call.
    void set_interceptor(std::shared_ptr<const CommandInterceptor> interceptor) {
        interceptor_ = std::move(interceptor);
    }
    bool has_interceptor() const { return interceptor_ != nullptr; }

private:
    CommandResult call_inner(std::string_view name, const Json& args) const;

    struct Entry {
        CommandInfo info;
        CommandHandler handler;
        CompiledSchema schema;     // info.inputSchema compiled by add(): what call() validates against
        bool acceptsMeta = false;  // the schema declares a "_meta" property, so call() keeps that key
    };
    std::map<std::string, Entry, std::less<>> commands_;
    std::function<void(std::string_view)> beforeCall_;
    std::shared_ptr<const CommandInterceptor> interceptor_;
    jobs::Owner* jobOwner_ = nullptr;
};

// One row of a module's capability table: command name and what it can do (capability.h; named sets in capability_sets).
struct CommandCapabilityRow {
    std::string_view name;
    CapabilitySet capabilities;
};
// Declares every row on `registry` (CommandRegistry::declare_capabilities). A row naming a command that is not registered is a
// bug of the module (a renamed command): it is logged as an error, not ignored.
void declare_command_capabilities(CommandRegistry& registry, std::initializer_list<CommandCapabilityRow> rows);

}  // namespace fa
