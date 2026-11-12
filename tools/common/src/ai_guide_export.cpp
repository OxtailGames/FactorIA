// The generated tools table of docs/AI_GUIDE.md section 4 (see api_export.h).
#include <algorithm>
#include <map>
#include <string>
#include <vector>

#include "fa/tooling/api_export.h"

namespace fa {

namespace {

constexpr const char* kBegin = "<!-- generated: tools table, factoria call docs.write_reference '{\"out\":\"docs\"}' -->";
constexpr const char* kEnd = "<!-- end generated -->";

struct CategoryPurpose {
    const char* category;
    const char* purpose;
};

// What a CommandInfo::category is for, in one line. The registry describes single commands only, so the line of a
// category lives here; the test ai_guide_tools_table fails on a category that has none.
constexpr CategoryPurpose kPurposes[] = {
    {"ai", "AI roles, hooks, extensions and the cost of the AI runs that made a game."},
    {"anim", "2D and 3D animation (clips, tracks, events, state machines, rigs) and 3D inverse kinematics, with their checks."},
    {"api", "Machine-readable lists of the components, commands and scripting API."},
    {"assets", "Make, import, check and preview art, sounds, music, models, vectors and images (`image_*`, `model_*`, `sfx_*`, `music_*`...)."},
    {"audio", "Drive and inspect buses, music players and the sounds played."},
    {"docs", "Read the built-in docs, search them, and read the component and command reference."},
    {"engine", "Engine version, platform, graphics backend, and whether FactorIA was updated while it runs."},
    {"feedback", "File, list, check and close engine feedback (the feedback rule, section 3)."},
    {"feel", "Game feel effects: flash, hit-stop, knockback, shake, squash."},
    {"fs", "Read, list, edit and delete the project's files (always inside the project). A write replaces the file atomically (a temporary file is renamed over it), so hot reload never sees a half-written scene."},
    {"game", "Run the headless game: step, pause, input, clicks, screenshots, state, logs; render and VFX probes."},
    {"i18n", "Translations: export and import string tables, switch language, see missing strings."},
    {"jobs", "The job system: worker threads and what ran."},
    {"material", "Describe custom materials."},
    {"physics", "Physics queries (raycasts, sweeps, overlaps) and navigation (NavMesh and tile paths)."},
    {"platform", "Fake store platform: set up a store backend, send store events, Remote Play."},
    {"play", "Let the game play itself (`play.auto`) and read the reports of play sessions."},
    {"project", "Validate, test, export and measure the project; checkpoints and the CI workflow."},
    {"publish", "Upload exports to Steam, itch, Epic, GOG, the App Store and Google Play."},
    {"render", "Procedural meshes: create, inspect and free them."},
    {"review", "Review sheets: the choices a person makes by number, listed and recorded."},
    {"scene", "Edit the running world: entities, components, parents, prefabs, tilemaps, skins, scene load and background loads."},
    {"screen", "Pretend device screen features (safe area, notch)."},
    {"script", "Scripts: evaluate JavaScript, reload modules, list errors, trace."},
    {"setup", "Check and install what an export needs on this computer."},
    {"shader", "Compile custom material shaders for several platforms."},
    {"sign", "Sign the exported macOS app and Windows package."},
    {"skills", "List, read and create skills (topic guides)."},
    {"ui", "UI checks and helpers: layout overflow, captions, touch interface, focus."},
};

const char* purpose_of(const std::string& category) {
    for (const CategoryPurpose& p : kPurposes)
        if (category == p.category) return p.purpose;
    return nullptr;
}

std::string category_of(const CommandInfo& c) { return c.category.empty() ? "general" : c.category; }

std::string tool_name(std::string command) {
    std::replace(command.begin(), command.end(), '.', '_');
    return command;
}

}  // namespace

std::vector<std::string> ai_guide_categories_without_purpose(const CommandRegistry& registry) {
    std::vector<std::string> missing;
    for (const CommandInfo* c : registry.list()) {
        const std::string cat = category_of(*c);
        if (!purpose_of(cat) && std::find(missing.begin(), missing.end(), cat) == missing.end()) missing.push_back(cat);
    }
    std::sort(missing.begin(), missing.end());
    return missing;
}

std::string export_ai_guide_tools_table(const CommandRegistry& registry) {
    std::map<std::string, std::vector<std::string>> byCategory;
    for (const CommandInfo* c : registry.list()) byCategory[category_of(*c)].push_back(tool_name(c->name));
    std::string out = std::string(kBegin) + "\n";
    out += "| Category | Tools (the command name with `.` as `_`) | What they do |\n|---|---|---|\n";
    for (auto& [cat, names] : byCategory) {
        std::sort(names.begin(), names.end());
        std::string list;
        for (const std::string& n : names) list += (list.empty() ? "`" : ", `") + n + "`";
        const char* purpose = purpose_of(cat);
        out += "| " + cat + " | " + list + " | " + (purpose ? purpose : "(no description yet)") + " |\n";
    }
    out += "\n`docs_commands {\"name\":\"scene.spawn\"}` gives one command in full (arguments, defaults, examples) and "
           "`docs_commands {\"filter\":\"words\"}` searches names, categories and summaries. Tools of plugins and of the "
           "project's `tools/*.js` are not in this table: `docs_commands` in the running project lists them.\n";
    out += std::string(kEnd) + "\n";
    return out;
}

bool splice_ai_guide_tools_table(std::string& guide, const CommandRegistry& registry, std::string* error) {
    const size_t b = guide.find(kBegin);
    const size_t e = b == std::string::npos ? std::string::npos : guide.find(kEnd, b);
    if (e == std::string::npos) {
        if (error)
            *error = std::string("AI_GUIDE.md section 4 has no `") + kBegin + "` ... `" + kEnd + "` block to fill.";
        return false;
    }
    size_t end = e + std::string(kEnd).size();
    if (end < guide.size() && guide[end] == '\n') ++end;
    guide.replace(b, end - b, export_ai_guide_tools_table(registry));
    return true;
}

}  // namespace fa
