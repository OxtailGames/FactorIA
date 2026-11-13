#include "fa/tooling/tool_groups.h"

#include <algorithm>

#include "fa/core/strings.h"

namespace fa {

namespace {

// Commands offered in full whatever the role asks for. The test: nearly every task needs them, or the model needs them to find
// out how to use the rest (docs_*). Grouped by what they do.
const std::vector<std::string> kCore = {
    // files and docs
    "fs.read",
    "fs.write",
    "fs.edit",
    "fs.list",
    "fs.search",
    "fs.delete",
    "docs.list",
    "docs.read",
    "docs.search",
    "docs.commands",
    "docs.components",
    // the scene
    "scene.spawn",
    "scene.set_component",
    "scene.remove_component",
    "scene.get_entity",
    "scene.list_entities",
    "scene.destroy",
    "scene.set_parent",
    "scene.save",
    "scene.load",
    "scene.reload",
    // running and looking at the game
    "game.step",
    "game.input",
    "game.click",
    "game.pause",
    "game.resume",
    "game.state",
    "game.logs",
    "game.screenshot",
    // checking the project, scripts, engine gaps
    "project.validate",
    "project.info",
    "project.test",
    "script.eval",
    "script.errors",
    "script.reload",
    "feedback.report",
    "assets.list",
    "assets.import",
    // topic guides read on demand (skills.list and skills.new stay in the catalog)
    "skills.read",
};

}  // namespace

const std::vector<std::string>& core_command_names() { return kCore; }

bool is_core_command(std::string_view commandName) {
    return std::find(kCore.begin(), kCore.end(), commandName) != kCore.end();
}

bool command_in_tool_group(const CommandInfo& info, std::string_view group) {
    if (group == "all") return true;
    if (group == "core") return is_core_command(info.name);
    return group == info.category || group == info.name;
}

std::string tool_group_hint(std::string_view group, const std::vector<const CommandInfo*>& commands) {
    std::vector<std::string> candidates = {"core", "all"};
    for (const CommandInfo* c : commands)
        if (std::find(candidates.begin(), candidates.end(), c->category) == candidates.end())
            candidates.push_back(c->category);
    for (const CommandInfo* c : commands) candidates.push_back(c->name);
    return fa::did_you_mean(std::string(group), candidates);
}

std::vector<std::string> split_tool_groups(std::string_view list) {
    std::vector<std::string> out;
    std::size_t pos = 0;
    while (pos <= list.size()) {
        std::size_t end = list.find(',', pos);
        if (end == std::string_view::npos) end = list.size();
        std::string_view item = list.substr(pos, end - pos);
        while (!item.empty() && (item.front() == ' ' || item.front() == '\t')) item.remove_prefix(1);
        while (!item.empty() && (item.back() == ' ' || item.back() == '\t')) item.remove_suffix(1);
        if (!item.empty() && std::find(out.begin(), out.end(), item) == out.end()) out.emplace_back(item);
        pos = end + 1;
    }
    return out;
}

}  // namespace fa
