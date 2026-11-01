// Skills for every provider: the Agent Skills format (a folder with a SKILL.md and files beside it, fa/tooling/skills.h) found in
// four places and offered to a role. The built-in loop gets one prompt line per skill and reads a skill with `skills.read`;
// Claude Code receives the same skills natively (the plugin FactorIA writes for the run, extension_plan.h); Codex finds them in the
// project's .agents/skills for the run and also gets the prompt lines; the generic CLIs get the prompt lines and `skills.read`
// through the MCP server. docs/SKILLS.md.
//
// Where skills come from, in the order that decides which one wins when two have the same name:
//   1. the project: <project>/skills/<name>/, and skill entries of .factoria/extensions.json
//   2. the user:    ~/.factoria/skills/<name>/, and skill entries of ai.json "extensions"
//   3. the engine:  skills/<name>/ of the repository, embedded in the binary
// A skill entry of the extensions (extensions.h) is the one config for roles and on/off: it names a skill folder, a folder of
// skill folders, or "engine:<name>". A skill found in a skills folder with no entry is on for kDefaultExtensionRoles.
#pragma once

#include <string>
#include <string_view>
#include <vector>

#include "fa/ai/config.h"
#include "fa/ai/extensions.h"
#include "fa/core/command.h"
#include "fa/core/json.h"

namespace fa::ai {

struct SkillInfo {
    std::string name;
    std::string description;
    std::string source;       // "engine", "user" or "project": where the folder lives
    std::string dir;          // absolute folder; "engine:<name>" for a skill inside the binary; "" when the entry did not resolve
    std::string entry;        // the extension entry that lists it ("" = found in a skills folder)
    std::string entryScope;   // "user" or "project": which file holds `entry`
    bool enabled = true;
    std::vector<std::string> roles;  // the entry's roles; empty = defaultRoles
    std::vector<std::string> defaultRoles;  // who gets it when `roles` is empty: kDefaultExtensionRoles, or the engine skill's own list
    std::string shadowedBy;   // "project skill" / "user skill" / "engine skill" when another skill of this name wins; else ""
    std::string problem;      // why it cannot be used (SKILL.md missing or invalid, folder missing); such a skill is not offered
    std::string fix;

    bool is_engine() const { return source == "engine"; }
    // Enabled and `role` is one of its roles (defaultRoles when `roles` is empty).
    bool serves_role(std::string_view role) const;
    // Usable and visible to `role`: no problem, not shadowed, on, and the role is one of its roles.
    bool offered_to(std::string_view role) const;
    // The roles it serves, resolved (`roles`, else defaultRoles); lists them even when `enabled` is false.
    std::vector<std::string> effective_roles() const;
};

// Who gets an engine skill that no entry lists: the roles whose work it is about (make-art: the artist, and the orchestrator that
// does the art itself), not every role. Unknown names (user and project skills) get kDefaultExtensionRoles.
std::vector<std::string> engine_skill_default_roles(std::string_view name);

struct SkillsContext {
    std::string projectDir;   // "" = no project
    ExtensionEnv env;         // HOME lookup; null = the process environment
};

std::string user_skills_dir(const SkillsContext& ctx);       // ~/.factoria/skills expanded; "" when there is no home folder
std::string project_skills_dir(const SkillsContext& ctx);    // <project>/skills; "" without a project

// Every skill of every source, in precedence order (project, user, engine; entries before skills folders; then by name),
// including the shadowed ones and those with a problem. `userEntries` / `projectEntries`: the extension entries of kind Skill
// (others are ignored). The editor passes its unsaved lists to preview a change.
std::vector<SkillInfo> scan_skills(const std::vector<Extension>& userEntries, const std::vector<Extension>& projectEntries,
                                   const SkillsContext& ctx);
// The same with the entries of `cfg` (ai.json) and the project's .factoria/extensions.json (read from disk).
std::vector<SkillInfo> scan_skills(const AiConfig& cfg, const SkillsContext& ctx);
// The skills `role` is offered, sorted by name.
std::vector<const SkillInfo*> skills_for_role(const std::vector<SkillInfo>& all, std::string_view role);

// What the prompt knows of a skill the role is offered.
struct SkillBrief {
    std::string name, description;
};
// The skills the system prompt of `role` is about: those it is offered, except that an orchestrator whose artist (audio) role
// is on does not need make-art (make-audio): it hands that work over. `disabledRoles`: AiConfig::disabled_delegable_roles().
std::vector<SkillBrief> skills_for_prompt(const std::vector<SkillInfo>& all, std::string_view role,
                                          const std::vector<std::string>& disabledRoles);
// The "# Skills" section of the system prompt: how to read a skill and one `name: description` line per skill. "" for no skills.
// `toolName` is how the model calls the reader ("skills_read").
std::string skills_prompt(const std::vector<SkillBrief>& skills, std::string_view toolName = "skills_read");

// The files of a skill (relative, forward slashes, SKILL.md first), at most `max`; `total` gets the real count.
struct SkillFile {
    std::string path;
    u64 bytes = 0;
};
std::vector<SkillFile> skill_files(const SkillInfo& skill, std::size_t max, std::size_t* total = nullptr);

// What skills.read answers. `file` empty = SKILL.md (its body: the frontmatter is name and description already). Errors teach
// (unknown file: the files there are; binary file; outside the folder). `offset`/`limit` are bytes of the text.
struct SkillRead {
    std::string name, source, file;
    std::string description;       // when `file` is SKILL.md
    std::string content;
    bool truncated = false;
    u64 nextOffset = 0;
    u64 totalBytes = 0;
    std::vector<SkillFile> files;  // the other files of the skill
    Json to_json() const;
};
Result<SkillRead> read_skill(const SkillInfo& skill, std::string_view file, u64 offset = 0, u64 limit = 0);

// Writes <dir>/<name>/SKILL.md from the template (never over an existing skill). Returns the path of the SKILL.md.
Result<std::string> create_skill(const std::string& skillsDir, std::string_view name, std::string_view description);

struct SkillsCommandOptions {
    std::function<Result<AiConfig>()> loadConfig;   // null = load_config()
    std::function<std::string()> projectDir;        // null = fa::fs::project_root()
    EnvLookup env;                                  // null = the process environment
};
// Registers skills.list, skills.read and skills.new. Called by register_ai_commands.
void register_skills_commands(CommandRegistry& registry, SkillsCommandOptions options);

}  // namespace fa::ai
