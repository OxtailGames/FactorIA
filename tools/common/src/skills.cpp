#include "fa/tooling/skills.h"

#include <algorithm>
#include <cctype>
#include <filesystem>
#include <set>

#include "fa/core/strings.h"
#include "fa/tooling/bundle.h"
#include "util.h"

namespace fa {

namespace fsys = std::filesystem;

namespace {

// Keys the Agent Skills format and Claude Code know. Anything else is kept and ignored, unless it is a near miss of one of these.
const char* const kKnownKeys[] = {"name",         "description",    "license",           "compatibility", "metadata",
                                  "allowed-tools", "argument-hint",  "disable-model-invocation", "user-invocable",
                                  "model",        "context",        "agent",             "hooks",         "when_to_use",
                                  "version",      "effort",         "paths",             "shell"};

std::string trim_copy(std::string_view s) { return std::string(trim(s)); }

std::vector<std::string> split_lines(std::string_view text) {
    std::vector<std::string> lines;
    std::size_t at = 0;
    while (at <= text.size()) {
        const std::size_t nl = text.find('\n', at);
        std::string_view line = text.substr(at, nl == std::string_view::npos ? std::string_view::npos : nl - at);
        if (!line.empty() && line.back() == '\r') line.remove_suffix(1);
        lines.emplace_back(line);
        if (nl == std::string_view::npos) break;
        at = nl + 1;
    }
    return lines;
}

bool is_fence(const std::string& line) {
    if (line.rfind("---", 0) != 0) return false;
    return trim(std::string_view(line).substr(3)).empty();
}

bool indented(const std::string& line) { return !line.empty() && (line[0] == ' ' || line[0] == '\t'); }

std::string unquote(std::string v) {
    if (v.size() >= 2 && v.front() == '"' && v.back() == '"') {
        std::string out;
        for (std::size_t i = 1; i + 1 < v.size(); ++i) {
            if (v[i] == '\\' && i + 2 < v.size()) {
                const char n = v[++i];
                out += n == 'n' ? '\n' : n == 't' ? '\t' : n;
            } else {
                out += v[i];
            }
        }
        return out;
    }
    if (v.size() >= 2 && v.front() == '\'' && v.back() == '\'') {
        std::string out;
        for (std::size_t i = 1; i + 1 < v.size(); ++i) {
            out += v[i];
            if (v[i] == '\'' && v[i + 1] == '\'') ++i;
        }
        return out;
    }
    return v;
}

struct RawKey {
    std::string key;
    std::string inlineValue;
    std::vector<std::string> continuation;  // the indented lines after it (blank ones included)
    int line = 0;                           // 1-based line of the file
};

std::string block_text(const std::vector<std::string>& cont, bool folded) {
    std::size_t common = std::string::npos;
    for (const std::string& l : cont) {
        if (trim(l).empty()) continue;
        std::size_t n = 0;
        while (n < l.size() && (l[n] == ' ' || l[n] == '\t')) ++n;
        common = std::min(common, n);
    }
    if (common == std::string::npos) return {};
    std::string out;
    bool pendingBreak = false;
    for (const std::string& l : cont) {
        if (trim(l).empty()) {
            if (!out.empty()) pendingBreak = true;
            continue;
        }
        const std::string text = l.substr(std::min(common, l.size()));
        if (!out.empty()) out += folded ? (pendingBreak ? "\n" : " ") : "\n";
        else if (pendingBreak) out += "\n";
        pendingBreak = false;
        out += text;
    }
    // Trailing blanks of a literal block are not part of the text.
    while (!out.empty() && (out.back() == '\n' || out.back() == ' ')) out.pop_back();
    return out;
}

std::string value_of(const RawKey& k) {
    const std::string inl = trim_copy(k.inlineValue);
    if (!inl.empty() && (inl[0] == '>' || inl[0] == '|')) return block_text(k.continuation, inl[0] == '>');
    if (inl.empty()) {
        // Nested map or list: kept as written.
        std::string out;
        for (const std::string& l : k.continuation) {
            if (trim(l).empty()) continue;
            out += (out.empty() ? "" : "\n") + trim_copy(l);
        }
        return out;
    }
    std::string joined = inl;
    for (const std::string& l : k.continuation) {
        const std::string t = trim_copy(l);
        if (!t.empty()) joined += " " + t;
    }
    return unquote(joined);
}

}  // namespace

std::string skill_name_problem(std::string_view name) {
    if (name.empty()) return "the name is empty. Use 1 to 64 characters: lowercase letters, digits and hyphens, for example my-skill.";
    if (name.size() > kMaxSkillName)
        return "the name has " + std::to_string(name.size()) + " characters; the limit is " + std::to_string(kMaxSkillName) + ". Shorten it.";
    for (char c : name) {
        const unsigned char u = static_cast<unsigned char>(c);
        if (std::isupper(u)) return "'" + std::string(name) + "' has an uppercase letter. Use lowercase only: '" + skill_name_from(name) + "'.";
        if (!(std::islower(u) || std::isdigit(u) || c == '-')) {
            const std::string fixed = skill_name_from(name);
            return "'" + std::string(name) + "' has the character '" + std::string(1, c) + "'. Use lowercase letters, digits and hyphens" +
                   (fixed.empty() ? "." : ": '" + fixed + "'.");
        }
    }
    if (name.front() == '-' || name.back() == '-') return "'" + std::string(name) + "' starts or ends with a hyphen. Remove it: '" + skill_name_from(name) + "'.";
    if (name.find("--") != std::string_view::npos) return "'" + std::string(name) + "' has two hyphens in a row. Use one: '" + skill_name_from(name) + "'.";
    return {};
}

std::string skill_name_from(std::string_view text) {
    std::string out;
    bool dash = false;
    for (char c : text) {
        const unsigned char u = static_cast<unsigned char>(c);
        if (std::isalnum(u)) {
            if (dash && !out.empty()) out += '-';
            dash = false;
            out += static_cast<char>(std::tolower(u));
        } else {
            dash = true;
        }
    }
    if (out.size() > kMaxSkillName) out.resize(kMaxSkillName);
    while (!out.empty() && out.back() == '-') out.pop_back();
    return out;
}

Result<SkillFrontmatter> parse_skill_md(std::string_view textIn, std::string_view fileIn) {
    const std::string file(fileIn);
    std::string_view text = textIn;
    if (text.size() >= 3 && text.substr(0, 3) == "\xEF\xBB\xBF") text.remove_prefix(3);
    const std::vector<std::string> lines = split_lines(text);
    auto fail = [&](int line, const std::string& message, const std::string& hint) {
        return Error{file + (line > 0 ? ":" + std::to_string(line) : std::string()) + ": " + message, hint};
    };
    static const char* const kExample = "Start the file with:\n---\nname: my-skill\ndescription: What it does and when to use it.\n---\nThen the instructions.";
    if (lines.empty() || !is_fence(lines[0])) {
        return fail(1, "a SKILL.md starts with a --- line, then the frontmatter (name and description), then another ---", kExample);
    }
    std::size_t close = 0;
    for (std::size_t i = 1; i < lines.size(); ++i) {
        if (is_fence(lines[i]) || trim(lines[i]) == "...") {
            close = i;
            break;
        }
    }
    if (close == 0) return fail(1, "the frontmatter is not closed: no second --- line", "Add a --- line after the description.");

    std::vector<RawKey> keys;
    for (std::size_t i = 1; i < close; ++i) {
        const std::string& l = lines[i];
        if (trim(l).empty() || trim(l)[0] == '#') continue;
        if (indented(l)) {
            if (keys.empty()) return fail(static_cast<int>(i) + 1, "an indented line before any key", "Write `key: value` lines at the start of the line.");
            keys.back().continuation.push_back(l);
            continue;
        }
        const std::size_t colon = l.find(':');
        if (colon == std::string::npos || colon == 0) {
            return fail(static_cast<int>(i) + 1, "'" + trim_copy(l) + "' is not `key: value`",
                        "Frontmatter lines look like `name: my-skill`. A long text goes on indented lines after `description: >`.");
        }
        RawKey k;
        k.key = trim_copy(l.substr(0, colon));
        k.inlineValue = l.substr(colon + 1);
        k.line = static_cast<int>(i) + 1;
        keys.push_back(std::move(k));
    }

    SkillFrontmatter out;
    int nameLine = 0, descLine = 0;
    bool hasName = false, hasDesc = false;
    for (const RawKey& k : keys) {
        const std::string v = value_of(k);
        if (k.key == "name") {
            out.name = v;
            nameLine = k.line;
            hasName = true;
        } else if (k.key == "description") {
            out.description = v;
            descLine = k.line;
            hasDesc = true;
        } else {
            out.other.emplace_back(k.key, v);
        }
    }
    std::vector<std::string> known(std::begin(kKnownKeys), std::end(kKnownKeys));
    auto misspelled = [&](const char* want) -> const RawKey* {
        for (const RawKey& k : keys) {
            if (k.key == want) continue;
            if (std::find(known.begin(), known.end(), k.key) != known.end()) continue;
            if (fa::closest_match(k.key, std::vector<std::string>{want}) == want) return &k;
        }
        return nullptr;
    };
    if (!hasName) {
        if (const RawKey* typo = misspelled("name"))
            return fail(typo->line, "'" + typo->key + "' is not a frontmatter key", "Did you mean 'name'? The skill's name is `name: my-skill`.");
        return fail(1, "the frontmatter has no `name`", "Add `name: my-skill` (lowercase letters, digits and hyphens; the same as the folder's name).");
    }
    if (!hasDesc) {
        if (const RawKey* typo = misspelled("description"))
            return fail(typo->line, "'" + typo->key + "' is not a frontmatter key", "Did you mean 'description'? It says what the skill does and when to use it.");
        return fail(1, "the frontmatter has no `description`",
                    "Add `description: ...`: what the skill does and when an agent should use it. Agents choose skills by this line.");
    }
    if (const std::string problem = skill_name_problem(out.name); !problem.empty()) return fail(nameLine, "`name`: " + problem, "");
    out.description = trim_copy(out.description);
    if (out.description.empty()) return fail(descLine, "`description` is empty", "Say what the skill does and when to use it: agents choose skills by this line.");
    if (out.description.size() > kMaxSkillDescription) {
        return fail(descLine, "`description` has " + std::to_string(out.description.size()) + " characters; the limit is " +
                                  std::to_string(kMaxSkillDescription),
                    "Shorten it to what the skill is for and when to use it; the details belong in the body.");
    }
    std::string body;
    for (std::size_t i = close + 1; i < lines.size(); ++i) {
        body += lines[i];
        if (i + 1 < lines.size()) body += '\n';
    }
    out.body = std::move(body);
    out.bodyLine = static_cast<int>(close) + 2;
    return out;
}

std::vector<SkillProblem> check_skill_folder(const std::string& dir, std::string_view shown) {
    std::vector<SkillProblem> out;
    const std::string folder(shown);
    const fsys::path md = fsys::path(dir) / "SKILL.md";
    std::error_code ec;
    // Exactly SKILL.md: a case-insensitive disk (macOS, Windows) finds skill.md too, and the same folder fails on Linux.
    bool exact = false;
    for (const auto& e : fsys::directory_iterator(dir, ec))
        if (e.path().filename().string() == "SKILL.md" && e.is_regular_file(ec)) exact = true;
    if (!exact) {
        // A different capitalisation is the usual cause on Linux and macOS (case-sensitive checkouts).
        std::string hint = "A skill is a folder with a file named exactly SKILL.md in it (capitals).";
        for (const auto& e : fsys::directory_iterator(dir, ec)) {
            std::string n = e.path().filename().string();
            std::string low = n;
            std::transform(low.begin(), low.end(), low.begin(), [](unsigned char c) { return std::tolower(c); });
            if (low == "skill.md") hint = "Rename '" + n + "' to SKILL.md.";
        }
        out.push_back({folder + "/SKILL.md", 0, "the folder '" + folder + "' has no SKILL.md", hint, false});
        return out;
    }
    auto text = tooling_detail::read_file(md);
    if (!text) {
        out.push_back({folder + "/SKILL.md", 0, "cannot read " + folder + "/SKILL.md", "Check that the file is readable.", false});
        return out;
    }
    auto fm = parse_skill_md(*text, folder + "/SKILL.md");
    if (!fm) {
        // parse_skill_md put the file and the line in the message already.
        int line = 0;
        const std::string prefix = folder + "/SKILL.md:";
        if (fm.error().message.rfind(prefix, 0) == 0) line = std::atoi(fm.error().message.c_str() + prefix.size());
        out.push_back({folder + "/SKILL.md", line, fm.error().message, fm.error().hint, false});
        return out;
    }
    const std::string folderName = fsys::path(dir).filename().string();
    if (fm->name != folderName) {
        std::string hint = "Rename the folder to '" + fm->name + "', or set `name: " + folderName + "` in the frontmatter";
        if (skill_name_problem(folderName).empty()) {
            if (fa::closest_match(fm->name, std::vector<std::string>{folderName}) == folderName)
                hint = "Did you mean '" + folderName + "'? " + hint + ".";
            else
                hint += ".";
        } else {
            hint = "Rename the folder to '" + fm->name + "' (a skill's folder and its `name` are the same).";
        }
        out.push_back({folder + "/SKILL.md", 0, "`name: " + fm->name + "` does not match the folder name '" + folderName + "'", hint, false});
    }
    if (trim(fm->body).empty()) {
        out.push_back({folder + "/SKILL.md", fm->bodyLine, "the skill has no instructions after the frontmatter",
                       "Write what the agent should do after reading it.", true});
    }
    std::vector<std::string> known(std::begin(kKnownKeys), std::end(kKnownKeys));
    for (const auto& [key, value] : fm->other) {
        (void)value;
        if (std::find(known.begin(), known.end(), key) != known.end()) continue;
        const std::string best = fa::closest_match(key, known);
        if (best.empty()) continue;
        out.push_back({folder + "/SKILL.md", 0, "the frontmatter key '" + key + "' is not one agents know",
                       "Did you mean '" + best + "'? Keys they do not know are ignored.", true});
    }
    return out;
}

std::string skill_template(std::string_view name, std::string_view description) {
    std::string d = description.empty() ? "What this skill does and when an agent should use it (agents choose skills by this line)." : std::string(description);
    // A description YAML would read as something else (a "key: value", a comment, a list) is written in double quotes.
    const bool plain = d.find(": ") == std::string::npos && d.find(" #") == std::string::npos && d.find_first_of("\"\n\r\t\\") == std::string::npos &&
                       d.find_first_of("-?[]{}!&*|>'%@`#") != 0 && d.back() != ':';
    if (!plain) {
        std::string q = "\"";
        for (char c : d) {
            if (c == '"' || c == '\\') q += '\\';
            q += c == '\n' ? ' ' : c == '\r' ? ' ' : c == '\t' ? ' ' : c;
        }
        d = q + "\"";
    }
    return "---\nname: " + std::string(name) + "\ndescription: " + d + "\n---\n\n# " + std::string(name) +
           "\n\nWrite here what the agent should do once it has chosen this skill: the steps, the commands to run, the traps.\n"
           "Keep this file short; put long references in files beside it (for example `reference.md`) and name them here so the\n"
           "agent reads them only when needed (`skills.read {\"name\": \"" + std::string(name) + "\", \"file\": \"reference.md\"}`).\n";
}

namespace {
const std::string kSkillsPrefix = "skills/";
}

std::vector<std::string> engine_skill_names() {
    std::set<std::string> names;
    for (const std::string& p : bundled_list(kSkillsPrefix)) {
        const std::string rest = p.substr(kSkillsPrefix.size());
        const std::size_t slash = rest.find('/');
        if (slash == std::string::npos) continue;
        if (rest.substr(slash + 1) == "SKILL.md") names.insert(rest.substr(0, slash));
    }
    return {names.begin(), names.end()};
}

std::vector<std::string> engine_skill_files(std::string_view name) {
    std::vector<std::string> out;
    const std::string prefix = kSkillsPrefix + std::string(name) + "/";
    for (const std::string& p : bundled_list(prefix)) {
        if (p.rfind(prefix, 0) == 0) out.push_back(p.substr(prefix.size()));
    }
    std::sort(out.begin(), out.end(), [](const std::string& a, const std::string& b) {
        if ((a == "SKILL.md") != (b == "SKILL.md")) return a == "SKILL.md";
        return a < b;
    });
    return out;
}

std::optional<std::string> engine_skill_read(std::string_view name, std::string_view file) {
    if (name.empty() || file.empty() || file.find("..") != std::string_view::npos || name.find('/') != std::string_view::npos) return std::nullopt;
    return bundled_read(kSkillsPrefix + std::string(name) + "/" + std::string(file));
}

}  // namespace fa
