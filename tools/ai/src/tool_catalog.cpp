#include "fa/ai/tool_catalog.h"

#include <algorithm>
#include <map>
#include <set>

#include "fa/ai/session.h"
#include "fa/core/strings.h"
#include "util.h"

namespace fa::ai {

using namespace util;

namespace {

// Commands offered in full whatever the role asks for. The test: nearly every task needs them, or the model needs them to find
// out how to use the rest (docs_*). Grouped by what they do; each group is one line of the table below.
const char* const kCore[] = {
    // files and docs
    "fs.read", "fs.write", "fs.edit", "fs.list", "fs.search", "fs.delete", "docs.list", "docs.read", "docs.search",
    "docs.commands", "docs.components",
    // the scene
    "scene.spawn", "scene.set_component", "scene.remove_component", "scene.get_entity", "scene.list_entities",
    "scene.destroy", "scene.set_parent", "scene.save", "scene.load", "scene.reload",
    // running and looking at the game
    "game.step", "game.input", "game.click", "game.pause", "game.resume", "game.state", "game.logs", "game.screenshot",
    // checking the project, scripts, engine gaps
    "project.validate", "project.info", "project.test", "script.eval", "script.errors", "script.reload",
    "feedback.report", "assets.list", "assets.import",
};

bool in_core(std::string_view name) {
    for (const char* c : kCore) {
        if (name == c) return true;
    }
    return false;
}

// 60: the JSON around a definition (keys, quotes, braces). The same figure estimate_context uses.
u64 def_bytes(const ToolDef& t) { return t.name.size() + t.description.size() + dump(t.inputSchema).size() + 60; }

std::string first_line(const std::string& s, std::size_t maxChars) {
    std::string line = s.substr(0, s.find('\n'));
    while (!line.empty() && (line.back() == ' ' || line.back() == '\r')) line.pop_back();
    if (line.size() > maxChars) {
        line.resize(maxChars);
        const std::size_t sp = line.find_last_of(' ');
        if (sp != std::string::npos && sp > maxChars / 2) line.resize(sp);
        line += "...";
    }
    return line;
}

bool eligible(const CommandInfo& info, bool readOnly) {
    if (is_agent_tool_excluded(info.name)) return false;
    return !readOnly || is_read_only_tool(info);
}

ToolDef describe_tool_def() {
    ToolDef d;
    d.name = kToolDescribe;
    d.description =
        "Get the full definition (description and input schema) of commands that are only listed in the system prompt's "
        "catalog. Describe a command before you call it for the first time, several at once when you need more than one. "
        "Names are the catalog's (assets.slice_sheet; assets_slice_sheet works too).";
    d.inputSchema = Json::parse(R"({"type":"object","properties":{"commands":{"type":"array","items":{"type":"string"},
        "minItems":1,"description":"Command names from the catalog."}},"required":["commands"],"additionalProperties":false})");
    return d;
}

ToolDef call_tool_def() {
    ToolDef d;
    d.name = kToolCall;
    d.description =
        "Run a command from the catalog. Same arguments and result as if it were a tool of its own; wrong arguments come "
        "back with the command's input schema. Commands that are tools already are called directly, not through this one.";
    d.inputSchema = Json::parse(R"({"type":"object","properties":{"command":{"type":"string","description":
        "Command name from the catalog, e.g. assets.slice_sheet."},"arguments":{"type":"object","description":
        "The command's arguments (see tool_describe). {} when it takes none."}},"required":["command"],"additionalProperties":false})");
    return d;
}

std::string catalog_text(const std::vector<CatalogEntry>& entries, bool readOnly) {
    std::string out = "# Tools\n";
    out += "The tools of this request are the ones you use most. FactorIA has " + std::to_string(entries.size()) +
           " more commands" + (readOnly ? " that you may use (they only look and play)" : "") +
           ", listed below as `command: what it does`. They are not tools of their own:\n"
           "- `tool_describe` {\"commands\": [\"name\", ...]} returns the full definition (description and input schema) of "
           "those commands. Describe a command before you call it for the first time; ask for every command you need in one "
           "call.\n"
           "- `tool_call` {\"command\": \"name\", \"arguments\": {...}} runs one. It does what the command's own tool would "
           "do, with the same result.\n"
           "Tools of this request are called directly. Look in the list before you say a capability does not exist.\n";
    std::string cat;
    for (const CatalogEntry& e : entries) {
        if (e.category != cat) {
            cat = e.category;
            out += "\n## " + (cat.empty() ? std::string("other") : cat) + "\n";
        }
        out += "- " + e.command + ": " + e.summary + "\n";
    }
    return out;
}

}  // namespace

bool is_core_tool(std::string_view commandName) { return in_core(commandName); }

std::vector<std::string> core_tool_names() { return std::vector<std::string>(std::begin(kCore), std::end(kCore)); }

std::vector<std::string> default_tool_groups(std::string_view role) {
    if (role == kRoleArtist) return {"assets"};
    if (role == kRoleAudio) return {"assets", "audio"};
    return {};
}

ToolDef tool_def_for_command(const CommandInfo& info) {
    ToolDef t;
    t.name = tool_name_for_command(info.name);
    t.description = info.description.empty() ? info.summary : info.summary + "\n\n" + info.description;
    t.inputSchema = info.inputSchema;
    return t;
}

ToolPlan plan_tools(const CommandRegistry& registry, const ToolPlanOptions& options) {
    ToolPlan plan;
    std::vector<const CommandInfo*> infos;
    std::vector<std::string> categories, names;
    for (const CommandInfo* info : registry.list()) {  // sorted by name
        if (!eligible(*info, options.readOnly)) continue;
        infos.push_back(info);
        names.push_back(info->name);
        if (std::find(categories.begin(), categories.end(), info->category) == categories.end()) categories.push_back(info->category);
    }
    // A group is a command category, the exact name of a command, or "all".
    std::set<std::string> matched;
    auto in_groups = [&](const CommandInfo& info) {
        for (const std::string& g : options.groups) {
            if (g == "all" || g == info.category || g == info.name) {
                matched.insert(g);
                return true;
            }
        }
        return false;
    };
    std::vector<ToolDef> full;     // offered in full when the catalog is used
    std::vector<ToolDef> all;      // every command in full
    std::vector<CatalogEntry> listed;
    u64 deferredBytes = 0;
    for (const CommandInfo* info : infos) {
        ToolDef def = tool_def_for_command(*info);
        const u64 bytes = def_bytes(def);
        plan.fullBytes += bytes;
        if (in_core(info->name) || in_groups(*info)) {
            full.push_back(def);
        } else {
            deferredBytes += bytes;
            CatalogEntry e;
            e.command = info->name;
            e.toolName = def.name;
            e.category = info->category;
            e.summary = first_line(info->summary, 110);
            e.readOnly = is_read_only_tool(*info);
            listed.push_back(std::move(e));
        }
        all.push_back(std::move(def));
    }
    for (const std::string& g : options.groups) {
        if (matched.count(g)) {
            plan.loadedGroups.push_back(g);
            continue;
        }
        std::vector<std::string> candidates = categories;
        candidates.insert(candidates.end(), names.begin(), names.end());
        plan.notes.push_back("Tool group '" + g + "' matches no command category and no command" +
                             (options.readOnly ? " this role may use" : "") + ". " + fa::did_you_mean(g, candidates));
    }
    plan.useCatalog = options.catalog && !listed.empty() && deferredBytes > options.minCatalogSavingBytes;
    if (plan.useCatalog) {
        plan.tools = std::move(full);
        plan.tools.push_back(describe_tool_def());
        plan.tools.push_back(call_tool_def());
        plan.catalog = std::move(listed);
        std::stable_sort(plan.catalog.begin(), plan.catalog.end(), [](const CatalogEntry& a, const CatalogEntry& b) {
            return a.category != b.category ? a.category < b.category : a.command < b.command;
        });
        plan.catalogText = catalog_text(plan.catalog, options.readOnly);
    } else {
        plan.tools = std::move(all);
    }
    if (options.withDelegate) plan.tools.push_back(delegate_tool_def());
    std::stable_sort(plan.tools.begin(), plan.tools.end(), [](const ToolDef& a, const ToolDef& b) { return a.name < b.name; });
    for (const ToolDef& t : plan.tools) plan.toolBytes += def_bytes(t);
    return plan;
}

const CommandInfo* resolve_command(const CommandRegistry& registry, std::string_view name, bool readOnly, std::string& why,
                                   std::string& hint) {
    why.clear();
    hint.clear();
    const CommandInfo* found = nullptr;
    std::vector<std::string> names;
    for (const CommandInfo* info : registry.list()) {
        if (info->name == name || tool_name_for_command(info->name) == name) found = info;
        if (!is_agent_tool_excluded(info->name)) names.push_back(info->name);
    }
    if (!found) {
        why = "No command named '" + std::string(name) + "'";
        hint = fa::did_you_mean(name, names);
        return nullptr;
    }
    if (is_agent_tool_excluded(found->name)) {
        why = "Command '" + found->name + "' is not available to agents: it would start another agent";
        hint = "Delegate with agent_delegate (when you have it) or do the work yourself.";
        return nullptr;
    }
    if (readOnly && !is_read_only_tool(*found)) {
        why = "Command '" + found->name + "' changes the project, so a read-only role (critic, reviewer) cannot use it";
        hint = "You only look and play. Say what should change in your report instead.";
        return nullptr;
    }
    return found;
}

Json describe_commands(const CommandRegistry& registry, const std::vector<std::string>& names, bool readOnly, bool& ok) {
    Json commands = Json::array();
    Json unknown = Json::array();
    std::set<std::string> done;
    for (const std::string& n : names) {
        std::string why, hint;
        const CommandInfo* info = resolve_command(registry, n, readOnly, why, hint);
        if (!info) {
            Json u = Json::object({{"name", n}, {"message", why}});
            if (!hint.empty()) u["hint"] = hint;
            unknown.push_back(std::move(u));
            continue;
        }
        if (!done.insert(info->name).second) continue;
        commands.push_back(Json::object({{"name", info->name},
                                         {"tool", tool_name_for_command(info->name)},
                                         {"category", info->category},
                                         {"summary", info->summary},
                                         {"description", info->description},
                                         {"readOnly", is_read_only_tool(*info)},
                                         {"inputSchema", info->inputSchema}}));
    }
    ok = !commands.empty();
    Json out = Json::object({{"commands", commands}});
    if (!unknown.empty()) out["unknown"] = unknown;
    return out;
}

}  // namespace fa::ai
