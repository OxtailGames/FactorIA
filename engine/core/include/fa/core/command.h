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

#include <functional>
#include <map>
#include <stdexcept>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"

namespace fa {

struct CommandError : std::runtime_error {
    std::string code;  // "not_found", "invalid_argument", "failed", "unavailable"...
    std::string hint;  // how to fix, e.g. "Use scene.list_entities to see valid ids."
    CommandError(std::string code_, const std::string& message, std::string hint_ = {})
        : std::runtime_error(message), code(std::move(code_)), hint(std::move(hint_)) {}
};

struct CommandInfo {
    std::string name;         // "scene.spawn"
    std::string summary;      // one line, imperative ("Create an entity from JSON.")
    std::string description;  // details, caveats and at least one example call
    Json inputSchema = Json::object({{"type", "object"}, {"properties", Json::object()}});
    bool readOnly = true;     // false if it mutates game/project state
    std::string category;     // "scene", "game", "project", "assets", "feedback", "docs", "fs"...
};

using CommandHandler = std::function<Json(const Json& args)>;

// Outcome of a call. `result` is the handler's JSON on success; on failure
// `error` = {"code": .., "message": .., "hint": ..}.
struct CommandResult {
    bool ok = false;
    Json result;
    Json error;
};

class CommandRegistry {
public:
    // Replaces an existing command with the same name.
    void add(CommandInfo info, CommandHandler handler);
    void remove(std::string_view name);
    bool has(std::string_view name) const;
    const CommandInfo* info(std::string_view name) const;
    std::vector<const CommandInfo*> list(std::string_view category = {}) const;  // sorted by name

    // Validates `args` against inputSchema (fills defaults for missing optional
    // properties that declare "default"), runs the handler, never throws.
    // Unknown command -> code "unknown_command" with a "did you mean" hint.
    CommandResult call(std::string_view name, const Json& args = Json::object()) const;

    // [{name, summary, description, inputSchema, readOnly, category}, ...]
    Json describe() const;

private:
    struct Entry {
        CommandInfo info;
        CommandHandler handler;
    };
    std::map<std::string, Entry, std::less<>> commands_;
};

}  // namespace fa
