// Agent Skills: a folder with a SKILL.md (YAML frontmatter with `name` and `description`, then the instructions) and any files
// beside it. The format Claude Code and Codex use, so a skill written for them works here unchanged. This header holds what
// does not depend on the AI configuration: parsing the frontmatter with teaching errors, checking a skill folder, the skills
// that ship inside the binary (skills/<name>/ of the repository) and the template `skills.new` writes. Which skills a role
// sees (engine, user, project, extension folders) is fa/ai/skills.h. docs/SKILLS.md.
#pragma once

#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

#include "fa/core/types.h"

namespace fa {

inline constexpr std::size_t kMaxSkillName = 64;
inline constexpr std::size_t kMaxSkillDescription = 1024;

struct SkillFrontmatter {
    std::string name;
    std::string description;
    // The other keys of the frontmatter (license, compatibility, allowed-tools...) as text; nested values are kept as written.
    std::vector<std::pair<std::string, std::string>> other;
    std::string body;      // the instructions: everything after the closing ---
    int bodyLine = 1;      // 1-based line of the file where `body` starts
};

// "" when `name` is a valid skill name (the Agent Skills rules: 1-64 characters, lowercase letters, digits and single hyphens,
// not starting or ending with a hyphen), else what is wrong and a fix.
std::string skill_name_problem(std::string_view name);
// A valid skill name made from any text ("My Shader Notes" -> "my-shader-notes"); "" when nothing is left.
std::string skill_name_from(std::string_view text);

// Parses the text of a SKILL.md. `file` is how errors name it ("skills/gdd/SKILL.md"). Errors say the line, what is wrong and
// how to fix it: no frontmatter, a missing name or description, a name that is not valid, a description that is too long.
// Keys of the frontmatter written like known ones but misspelled ("descripton") are reported with "did you mean".
Result<SkillFrontmatter> parse_skill_md(std::string_view text, std::string_view file);

// One problem found in a skill folder.
struct SkillProblem {
    std::string file;     // "skills/gdd/SKILL.md" (how the caller named the folder, then the file)
    int line = 0;         // 1-based, 0 when not about a line
    std::string message;
    std::string hint;
    bool warning = false;
};
// Everything wrong with the skill folder `dir`: no SKILL.md, frontmatter errors (parse_skill_md), a `name` that differs from
// the folder's name ("did you mean"), an empty body. `shown` names the folder in messages ("skills/gdd").
std::vector<SkillProblem> check_skill_folder(const std::string& dir, std::string_view shown);

// The text `skills.new` writes into skills/<name>/SKILL.md.
std::string skill_template(std::string_view name, std::string_view description);

// --- the skills inside the binary (skills/<name>/ of the repository; read from the source tree in a build without embedding) ---
std::vector<std::string> engine_skill_names();                      // sorted
// Files of an engine skill, relative to its folder with forward slashes, SKILL.md first, then sorted. Empty for an unknown name.
std::vector<std::string> engine_skill_files(std::string_view name);
std::optional<std::string> engine_skill_read(std::string_view name, std::string_view file = "SKILL.md");

}  // namespace fa
