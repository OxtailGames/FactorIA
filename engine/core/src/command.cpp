#include "fa/core/command.h"

#include <algorithm>

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

}  // namespace

void CommandRegistry::add(CommandInfo info, CommandHandler handler) {
    std::string name = info.name;
    commands_[name] = Entry{std::move(info), std::move(handler)};
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

std::vector<const CommandInfo*> CommandRegistry::list(std::string_view category) const {
    std::vector<const CommandInfo*> out;
    for (const auto& [name, entry] : commands_)  // std::map: already sorted by name
        if (category.empty() || entry.info.category == category) out.push_back(&entry.info);
    return out;
}

CommandResult CommandRegistry::call(std::string_view name, const Json& argsIn) const {
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

    Json args = argsIn.is_null() ? Json::object() : argsIn;
    const Json& schema = entry.info.inputSchema;
    if (args.is_object()) apply_schema_defaults(schema, args);
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
        return fail(e.code, e.what(), e.hint);
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
                                    {"inputSchema", i.inputSchema},
                                    {"readOnly", i.readOnly},
                                    {"category", i.category}}));
    }
    return arr;
}

}  // namespace fa
