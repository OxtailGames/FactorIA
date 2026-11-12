#include "fa/core/command.h"

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cstdlib>
#include <mutex>
#include <optional>
#include <string_view>
#include <vector>

#include "fa/core/fs.h"
#include "fa/core/jobs.h"
#include "fa/core/json_schema.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"

namespace fa {
namespace {

Json error_json(std::string code, std::string message, std::string hint) {
    return Json::object({{"code", std::move(code)}, {"message", std::move(message)}, {"hint", std::move(hint)}});
}

CommandResult fail(std::string code, std::string message, std::string hint = {}) {
    CommandResult r;
    r.ok = false;
    r.error = error_json(std::move(code), std::move(message), std::move(hint));
    return r;
}

thread_local std::shared_ptr<const CapabilityHintProvider> t_hint;  // CommandCapabilityScope: who words capability_denied hints
std::atomic<std::uint32_t> g_capability_floor{CapabilitySet::all().bits()};  // CommandCapabilityFloor: the process-wide maximum
std::mutex g_floor_words_mutex;                                                // guards the hint below (read on a refusal only)
std::shared_ptr<const CapabilityHintProvider> g_floor_hint;                    // the floor's hint provider (null = none)

CapabilitySet set_from_bits(std::uint32_t bits) {
    CapabilitySet s = CapabilitySet::all();
    for (int i = 0; i < kCapabilityCount; ++i)
        if ((bits & (1u << i)) == 0) s = s.without(static_cast<Capability>(i));
    return s;
}

// The refusal of a call whose command needs capabilities the caller was not granted (code "capability_denied").
CommandResult capability_denied(const CommandInfo& info, CapabilitySet missing) {
    const CapabilitySet granted = caller_capabilities();
    std::string message = "'" + info.name + "' was not run: it needs ";
    bool first = true;
    for (const std::string& n : missing.names()) {
        if (!first) message += "; ";
        first = false;
        message += "capability '" + n + "' (" + capability_doc(*capability_from_name(n)) + ")";
    }
    message += ", which " + std::string(command_caller_name(command_caller())) + " is not granted here. Granted: " + granted.to_string() +
               "; the command needs " + info.capabilities.to_string() + ".";
    std::string hint;
    std::shared_ptr<const CapabilityHintProvider> provider = t_hint;
    if (!provider) {
        std::lock_guard<std::mutex> lock(g_floor_words_mutex);
        provider = g_floor_hint;
    }
    if (provider) hint = provider->hint(CapabilityDenial{info, missing, granted});
    if (hint.empty())
        hint = "Capabilities are granted by who calls: the CLI user has all of them; `factoria mcp` without `--read-only` grants all "
               "but writeAnywhere; a game script gets {read, state}; a test can ask for it with `capabilities` in its test options "
               "(docs/SCRIPTING.md). Ask the user to run `factoria call " + info.name +
                   "` in their own terminal, or to start the tool with that capability.";
    CommandResult r = fail("capability_denied", std::move(message), std::move(hint));
    r.error["data"] = Json::object({{"command", info.name},
                                    {"missing", missing.to_json()},
                                    {"needs", info.capabilities.to_json()},
                                    {"granted", granted.to_json()}});
    return r;
}

thread_local CommandProgressSink t_progress_sink;
// The registries this thread is inside a call() of, outermost first (see call_inner).
thread_local std::vector<const CommandRegistry*> t_active_calls;
thread_local CommandCaller t_caller = CommandCaller::User;
thread_local const std::atomic<bool>* t_cancel = nullptr;
thread_local CapabilitySet t_granted = CapabilitySet::all();  // narrowed by CommandCapabilityScope / CommandCallerScope
std::atomic<int> g_caller_floor{static_cast<int>(CommandCaller::User)};  // CommandCallerFloor: the process-wide minimum

}  // namespace

CommandProgressScope::CommandProgressScope(CommandProgressSink sink) : previous_(std::move(t_progress_sink)) {
    t_progress_sink = std::move(sink);
}

CommandProgressScope::~CommandProgressScope() { t_progress_sink = std::move(previous_); }

CommandCallerScope::CommandCallerScope(CommandCaller caller) : previous_(t_caller), previousGranted_(t_granted) {
    if (command_caller() == CommandCaller::User) t_caller = caller;  // never loosened: an agent inside an MCP call stays refused
    t_granted = t_granted.intersect(capabilities_for_caller(caller));  // nor are the capabilities
}

CommandCallerScope::~CommandCallerScope() {
    t_caller = previous_;
    t_granted = previousGranted_;
}

CapabilitySet capabilities_for_caller(CommandCaller caller) {
    switch (caller) {
        case CommandCaller::User: return capability_sets::cli_user();
        case CommandCaller::Agent: return capability_sets::agent();
        case CommandCaller::Mcp: return capability_sets::mcp();
    }
    return capability_sets::cli_user();
}

CommandCapabilityScope::CommandCapabilityScope(CapabilitySet granted, std::shared_ptr<const CapabilityHintProvider> hint)
    : previous_(t_granted), previousHint_(t_hint) {
    t_granted = t_granted.intersect(granted);
    if (hint) t_hint = std::move(hint);
}

CommandCapabilityScope::~CommandCapabilityScope() {
    t_granted = previous_;
    t_hint = std::move(previousHint_);
}

CapabilitySet caller_capabilities() {
    return t_granted.intersect(capabilities_for_caller(command_caller())).intersect(set_from_bits(g_capability_floor.load()));
}

CommandContext command_context() { return CommandContext{command_caller(), caller_capabilities(), t_hint}; }

CommandCapabilityFloor::CommandCapabilityFloor(CapabilitySet granted, std::shared_ptr<const CapabilityHintProvider> hint) {
    std::lock_guard<std::mutex> lock(g_floor_words_mutex);
    previous_ = set_from_bits(g_capability_floor.load());
    previousHint_ = g_floor_hint;
    g_capability_floor.store(previous_.intersect(granted).bits());
    if (hint) g_floor_hint = std::move(hint);
}

CommandCapabilityFloor::~CommandCapabilityFloor() {
    std::lock_guard<std::mutex> lock(g_floor_words_mutex);
    g_capability_floor.store(previous_.bits());
    g_floor_hint = std::move(previousHint_);
}

std::optional<CapabilitySet> command_capabilities_from_env_value(const char* value) {
    if (!value || !*value) return std::nullopt;
    if (std::string_view(value) == "none") return CapabilitySet::none();
    auto parsed = CapabilitySet::parse_list(value);
    if (!parsed) return CapabilitySet::none();  // a restriction nobody can read is kept as the strictest one
    return *parsed;
}

std::optional<CapabilitySet> command_capabilities_from_env() { return command_capabilities_from_env_value(std::getenv(kCapabilitiesEnvVar)); }

std::string capabilities_env_value(CapabilitySet set) {
    if (set.empty()) return "none";
    std::string out;
    for (const std::string& n : set.names()) out += (out.empty() ? "" : ",") + n;
    return out;
}

CommandCallerFloor::CommandCallerFloor(CommandCaller floor) : previous_(static_cast<CommandCaller>(g_caller_floor.load())) {
    if (static_cast<int>(floor) > static_cast<int>(previous_)) g_caller_floor.store(static_cast<int>(floor));
}

CommandCallerFloor::~CommandCallerFloor() { g_caller_floor.store(static_cast<int>(previous_)); }

std::optional<CommandCaller> command_caller_from_env_value(const char* value) {
    if (!value || !*value) return std::nullopt;
    if (std::string_view(value) == "mcp") return CommandCaller::Mcp;
    return CommandCaller::Agent;
}

std::optional<CommandCaller> command_caller_from_env() { return command_caller_from_env_value(std::getenv(kCallerEnvVar)); }

CommandCaller command_caller() {
    return static_cast<CommandCaller>(std::max(static_cast<int>(t_caller), g_caller_floor.load()));
}

const char* command_caller_name(CommandCaller caller) {
    switch (caller) {
        case CommandCaller::User: return "the user";
        case CommandCaller::Agent: return "an AI agent";
        case CommandCaller::Mcp: return "an MCP client";
    }
    return "the user";
}

CommandCancelScope::CommandCancelScope(const std::atomic<bool>* flag) : previous_(t_cancel) { t_cancel = flag; }

CommandCancelScope::~CommandCancelScope() { t_cancel = previous_; }

const std::atomic<bool>* command_cancel_flag() { return t_cancel; }

bool command_cancelled() { return t_cancel && t_cancel->load(std::memory_order_relaxed); }

bool command_progress_active() { return static_cast<bool>(t_progress_sink); }

bool report_command_progress(std::string_view message) {
    if (!t_progress_sink) return false;
    return t_progress_sink(message);
}

void CommandRegistry::add(CommandInfo info, CommandHandler handler) {
    std::string name = info.name;
    if (const std::size_t cut = info.description.find(kCommandDetailsMark); cut != std::string::npos) {
        if (info.details.empty()) {
            info.details = info.description.substr(cut + 1);
            info.description.resize(cut);
            while (!info.description.empty() && (info.description.back() == ' ' || info.description.back() == '\n')) info.description.pop_back();
        } else {
            // `details` is already set: the description keeps all its text (nothing is lost), without the control character
            // a client would send. Set one of the two, not both.
            FA_WARN("command", "{}: the description holds FA_COMMAND_DETAILS but `details` is set too; the marker was removed, so the "
                               "whole description is sent. Use one of the two.", name);
            info.description.erase(std::remove(info.description.begin(), info.description.end(), kCommandDetailsMark), info.description.end());
        }
    }
    // Closed by default: an argument the schema does not declare is an error, not something silently ignored. What
    // describe() and MCP show is the normalised schema, so clients see exactly what call() enforces.
    info.inputSchema = close_object_schemas(std::move(info.inputSchema));
    // Compiles the schema's `pattern`s now (the validator keeps them): a bad regex is reported when the command is added,
    // not on every call.
    for (const SchemaError& e : check_schema_patterns(info.inputSchema))
        FA_ERROR("command", "{}: inputSchema{}: {} ({})", name, e.pointer, e.message, e.hint);
    // A command declares by setting capabilitiesDeclared (declare_capabilities does). A set that differs from the one readOnly
    // implies counts as declared even without the flag (a hand-built info); a set equal to it is what add() derived itself
    // (the editor re-adds copies of registered infos), so the flag alone decides and the copy stays "not declared".
    const CapabilitySet derived = info.readOnly ? CapabilitySet{Capability::Read}
                                                : CapabilitySet{Capability::Read, Capability::State, Capability::WriteProject};
    if (!info.capabilitiesDeclared && !info.capabilities.empty() && info.capabilities != derived) info.capabilitiesDeclared = true;
    if (!info.capabilitiesDeclared) info.capabilities = derived;
    commands_[name] = Entry{std::move(info), std::move(handler)};
}

bool CommandRegistry::declare_capabilities(std::string_view name, CapabilitySet capabilities) {
    auto it = commands_.find(name);
    if (it == commands_.end()) return false;
    if (capabilities.empty()) {  // refused like a JS tool's `capabilities: []`: the command keeps what it had
        FA_ERROR("command", "capabilities declared for '{}' are empty, which is not allowed: a command needs at least \"read\" "
                            "(use capability_sets::reads() for a command that only reads)", name);
        return false;
    }
    it->second.info.capabilities = capabilities;
    it->second.info.capabilitiesDeclared = true;
    it->second.info.readOnly = capabilities.without(Capability::Read).empty();
    return true;
}

void declare_command_capabilities(CommandRegistry& registry, std::initializer_list<CommandCapabilityRow> rows) {
    for (const CommandCapabilityRow& r : rows) {
        if (registry.declare_capabilities(r.name, r.capabilities)) continue;
        // An empty set was already reported by declare_capabilities; only a missing command is left to say.
        if (!registry.has(r.name))
            FA_ERROR("command", "capabilities declared for '{}', which is not a registered command (renamed? conditional?)", r.name);
    }
}

void CommandRegistry::remove(std::string_view name) {
    auto it = commands_.find(name);
    if (it != commands_.end()) commands_.erase(it);
}

bool CommandRegistry::has(std::string_view name) const { return commands_.find(name) != commands_.end(); }

const CommandInfo* CommandRegistry::info(std::string_view name) const {
    auto it = commands_.find(name);
    return it == commands_.end() ? nullptr : &it->second.info;
}

CommandHandler CommandRegistry::handler(std::string_view name) const {
    auto it = commands_.find(name);
    return it == commands_.end() ? CommandHandler() : it->second.handler;
}

std::vector<const CommandInfo*> CommandRegistry::list(std::string_view category) const {
    std::vector<const CommandInfo*> out;
    for (const auto& [name, entry] : commands_)  // std::map: already sorted by name
        if (category.empty() || entry.info.category == category) out.push_back(&entry.info);
    return out;
}

CommandResult CommandRegistry::call(std::string_view name, const Json& argsIn) const {
    if (command_cancelled())
        return fail("cancelled", "'" + std::string(name) + "' was not run: the request it belongs to was cancelled.",
                    "Nothing to fix: whoever sent the request took it back (an MCP client's notifications/cancelled).");
    std::optional<jobs::OwnerScope> owner;  // jobs and main-thread tasks a handler queues belong to this registry
    if (jobOwner_) owner.emplace(jobOwner_);
    const std::shared_ptr<const CommandInterceptor> interceptor = interceptor_;  // one pointer test when there is none
    if (!interceptor || !interceptor->wants || !interceptor->wants(name)) return call_inner(name, argsIn);
    // The capability check comes before the interceptor: a call the caller may not make never reaches a hook (which could log
    // it, change its arguments or run a script of its own). call_inner checks again, after beforeCall_ may have reloaded the
    // command, so this one only has to catch the refusal early.
    if (auto it = commands_.find(name); it != commands_.end()) {
        if (const CapabilitySet missing = it->second.info.capabilities.missing_from(caller_capabilities()); !missing.empty())
            return capability_denied(it->second.info, missing);
    }
    Json args = argsIn.is_null() ? Json::object() : argsIn;
    if (interceptor->before) {
        if (std::optional<CommandResult> refused = interceptor->before(name, args)) return *refused;
    }
    const auto t0 = std::chrono::steady_clock::now();
    CommandResult result = call_inner(name, args);
    if (interceptor->after) {
        interceptor->after(name, args, result, std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count());
    }
    return result;
}

CommandResult CommandRegistry::call_inner(std::string_view name, const Json& argsIn) const {
    // The depth of nested call()s is per thread (a command can run on a job thread while the main thread runs another)
    // and per registry (a handler may call into a second registry, whose own outermost call still runs its hook).
    struct DepthGuard {
        const CommandRegistry* r;
        explicit DepthGuard(const CommandRegistry* reg) : r(reg) { t_active_calls.push_back(r); }
        ~DepthGuard() { t_active_calls.pop_back(); }
    };
    const bool outermost = std::find(t_active_calls.begin(), t_active_calls.end(), this) == t_active_calls.end();
    // The hook reloads the commands, which is only safe on the engine's own thread between commands: a command that
    // runs on a job worker never triggers it.
    if (beforeCall_ && outermost && !jobs::is_worker_thread()) {
        DepthGuard g(this);
        beforeCall_(name);
    }
    DepthGuard depth(this);
    auto it = commands_.find(name);
    if (it == commands_.end()) {
        std::vector<std::string> names;
        for (const auto& [n, e] : commands_) names.push_back(n);
        // MCP exposes names with '.' replaced by '_'; accept that spelling too.
        std::string alt(name);
        std::replace(alt.begin(), alt.end(), '_', '.');
        auto altIt = commands_.find(alt);
        std::string hint;
        if (altIt != commands_.end()) hint = "Did you mean '" + alt + "'? Command names use '.' between area and verb.";
        else hint = did_you_mean(name, names, 15) + " Use the command list (describe) to see all commands.";
        return fail("unknown_command", "Unknown command '" + std::string(name) + "'", hint);
    }
    const Entry& entry = it->second;

    if (const CapabilitySet missing = entry.info.capabilities.missing_from(caller_capabilities()); !missing.empty())
        return capability_denied(entry.info, missing);

    Json args = argsIn.is_null() ? Json::object() : argsIn;
    const Json& schema = entry.info.inputSchema;
    if (args.is_object()) {
        // MCP and other transports may add their own bookkeeping key to the arguments: it is not an argument.
        if (args.contains("_meta") && !(schema.contains("properties") && schema["properties"].contains("_meta"))) args.erase("_meta");
        apply_schema_defaults(schema, args);
    }
    std::vector<SchemaError> errors = validate_json(schema, args);
    if (!errors.empty()) {
        std::string message = "Invalid arguments for '" + entry.info.name + "': ";
        for (std::size_t i = 0; i < errors.size() && i < 5; ++i) {
            if (i) message += "; ";
            message += (errors[i].pointer.empty() ? std::string("(root)") : errors[i].pointer) + ": " + errors[i].message;
        }
        if (errors.size() > 5) message += "; ... (" + std::to_string(errors.size() - 5) + " more)";
        std::string hint = errors.front().hint;
        if (!hint.empty()) hint += " ";
        hint += "See the command's inputSchema (describe) for all arguments.";
        return fail("invalid_arguments", message, hint);
    }

    try {
        CommandResult r;
        r.result = entry.handler(args);
        r.ok = true;
        return r;
    } catch (const CommandError& e) {
        CommandResult r = fail(e.code, e.what(), e.hint);
        if (!e.data.is_null()) r.error["data"] = e.data;
        return r;
    } catch (const std::exception& e) {
        FA_ERROR("command", "'{}' threw: {}", entry.info.name, e.what());
        return fail("failed", std::string("Command '") + entry.info.name + "' failed: " + e.what(),
                    "This is likely an engine bug or bad state; check the logs, and report it with feedback.report.");
    } catch (...) {
        return fail("failed", "Command '" + entry.info.name + "' failed with an unknown exception");
    }
}

Json CommandRegistry::describe() const {
    Json arr = Json::array();
    for (const auto& [name, entry] : commands_) {
        const CommandInfo& i = entry.info;
        arr.push_back(Json::object({{"name", i.name},
                                    {"summary", i.summary},
                                    {"description", i.description},
                                    {"details", i.details},
                                    {"inputSchema", i.inputSchema},
                                    {"readOnly", i.readOnly},
                                    {"capabilities", i.capabilities.to_json()},
                                    {"capabilitiesDeclared", i.capabilitiesDeclared},
                                    {"category", i.category}}));
    }
    return arr;
}

void require_capability(Capability needed, std::string_view command, std::string_view reason) {
    const CapabilitySet granted = caller_capabilities();
    if (granted.has(needed)) return;
    const std::string name = capability_name(needed);
    throw CommandError("capability_denied",
                       "'" + std::string(command) + "' was not run: " + std::string(reason) + " needs capability '" + name + "' (" +
                           capability_doc(needed) + "), which " + command_caller_name(command_caller()) +
                           " is not granted here. Granted: " + granted.to_string() + ".",
                       "Call it without that argument, or ask the user to run `factoria call " + std::string(command) +
                           "` in their own terminal, or to start the tool with that capability.",
                       Json::object({{"command", std::string(command)},
                                     {"missing", CapabilitySet{needed}.to_json()},
                                     {"granted", granted.to_json()}}));
}

std::string resolve_caller_write_path(std::string_view path, std::string_view command) {
    require_capability(Capability::WriteProject, command, "writing to the `path` you gave");
    auto resolved = fs::resolve_for_write(path, fs::WriteRoot::Project, caller_capabilities().has(Capability::WriteAnywhere));
    if (!resolved.ok()) {
        const std::string code(fs::path_error_code(resolved.error()));
        throw CommandError(code.empty() ? "invalid_argument" : code, resolved.error().message, resolved.error().hint);
    }
    return fs::path_to_utf8(resolved.value());
}

std::string resolve_caller_project_path(std::string_view path, std::string_view command) {
    const std::string abs = resolve_caller_write_path(path, command);
    return fs::project_spelling(fs::path_from_utf8(abs));
}

}  // namespace fa
