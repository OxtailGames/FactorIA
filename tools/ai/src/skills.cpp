#include "fa/ai/skills.h"

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <map>
#include <memory>
#include <set>

#include "fa/ai/config.h"
#include "fa/ai/extension_plan.h"
#include "fa/ai/session.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/tooling/skills.h"
#include "util.h"

namespace fa::ai {

namespace fsys = std::filesystem;
using util::flag;
using util::num;
using util::str;

namespace {

constexpr std::size_t kMaxSkillsPerFolder = 300;
constexpr u64 kDefaultReadBytes = 60000;

EnvLookup env_of(const SkillsContext& ctx) { return ctx.env ? ctx.env : system_env(); }

std::string canonical_key(const std::string& dir) {
    if (is_engine_skill_path(dir)) return dir;
    std::error_code ec;
    return fsys::weakly_canonical(dir, ec).string();
}

bool inside_dir(const fsys::path& root, const fsys::path& p) {
    std::error_code ec;
    const fsys::path r = fsys::weakly_canonical(root, ec);
    const fsys::path c = fsys::weakly_canonical(p, ec);
    auto rit = r.begin();
    auto cit = c.begin();
    for (; rit != r.end(); ++rit, ++cit)
        if (cit == c.end() || *rit != *cit) return false;
    return true;
}

std::optional<std::string> read_whole(const fsys::path& p) {
    std::ifstream f(p, std::ios::binary);
    if (!f) return std::nullopt;
    return std::string((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
}

int source_rank(const std::string& s) { return s == "project" ? 0 : s == "user" ? 1 : 2; }

std::string source_of(const std::string& dir, const SkillsContext& ctx) {
    if (is_engine_skill_path(dir)) return "engine";
    if (!ctx.projectDir.empty() && inside_dir(fsys::path(ctx.projectDir), fsys::path(dir))) return "project";
    return "user";
}

// Name, description and problem of one skill folder (on disk or inside the binary).
void load_meta(SkillInfo& info) {
    const bool engine = is_engine_skill_path(info.dir);
    const std::string folderName = engine ? info.dir.substr(kEngineSkillPrefix.size()) : fsys::path(info.dir).filename().string();
    info.name = folderName;
    std::optional<std::string> text;
    if (engine) text = fa::engine_skill_read(folderName);
    else text = read_whole(fsys::path(info.dir) / "SKILL.md");
    if (!text) {
        info.problem = engine ? "the engine skill '" + folderName + "' has no SKILL.md" : "'" + info.dir + "' has no SKILL.md";
        info.fix = "A skill is a folder with a SKILL.md in it (capitals) that starts with the frontmatter `name:` and `description:`.";
        return;
    }
    auto fm = fa::parse_skill_md(*text, engine ? "skills/" + folderName + "/SKILL.md" : info.dir + "/SKILL.md");
    if (!fm) {
        info.problem = fm.error().message;
        info.fix = fm.error().hint;
        return;
    }
    info.name = fm->name;
    info.description = fm->description;
}

void add_folder_candidates(const std::string& root, std::vector<SkillInfo>& out) {
    std::error_code ec;
    if (root.empty() || !fsys::is_directory(root, ec)) return;
    std::vector<std::string> dirs;
    for (const auto& entry : fsys::directory_iterator(root, ec)) {
        std::error_code e2;
        if (!entry.is_directory(e2)) continue;
        if (!fsys::is_regular_file(entry.path() / "SKILL.md", e2)) continue;
        dirs.push_back(entry.path().string());
    }
    std::sort(dirs.begin(), dirs.end());
    if (dirs.size() > kMaxSkillsPerFolder) dirs.resize(kMaxSkillsPerFolder);
    for (const std::string& d : dirs) {
        SkillInfo info;
        info.dir = d;
        out.push_back(std::move(info));
    }
}

std::string one_line(const std::string& s, std::size_t maxChars) {
    std::string out;
    bool space = false;
    for (char c : s) {
        if (c == '\n' || c == '\r' || c == '\t' || c == ' ') {
            space = !out.empty();
            continue;
        }
        if (space) out += ' ';
        space = false;
        out += c;
    }
    if (out.size() > maxChars) {
        out.resize(maxChars);
        const std::size_t sp = out.find_last_of(' ');
        if (sp != std::string::npos && sp > maxChars / 2) out.resize(sp);
        out += "...";
    }
    return out;
}

}  // namespace

bool SkillInfo::serves_role(std::string_view role) const {
    if (!enabled) return false;
    const std::vector<std::string>& list = roles.empty() ? defaultRoles : roles;
    return std::find(list.begin(), list.end(), role) != list.end();
}

bool SkillInfo::offered_to(std::string_view role) const { return problem.empty() && shadowedBy.empty() && serves_role(role); }

std::vector<std::string> SkillInfo::effective_roles() const {
    return roles.empty() ? defaultRoles : roles;
}

std::vector<std::string> engine_skill_default_roles(std::string_view name) {
    // The roles that build the game. Reading order of the table: who does the work the skill is about.
    static const std::map<std::string, std::vector<std::string>, std::less<>> table = {
        {"review-ready", {"orchestrator", "worker", "artist", "audio"}},
        {"make-art", {"orchestrator", "artist"}},
        {"make-audio", {"orchestrator", "audio"}},
        {"custom-shaders", {"orchestrator", "worker", "artist"}},
        {"glow-and-effects", {"orchestrator", "worker", "artist"}},
        {"inspect-the-picture", {"orchestrator", "worker", "artist"}},
        {"tile-levels", {"orchestrator", "worker"}},
        {"physics-3d", {"orchestrator", "worker"}},
        {"web-requests", {"orchestrator", "worker"}},
        {"menus-and-finishing", {"orchestrator", "worker"}},
        {"publishing-and-exporting", {"orchestrator", "worker"}},
    };
    const auto it = table.find(name);
    if (it != table.end()) return it->second;
    return std::vector<std::string>(std::begin(kDefaultExtensionRoles), std::end(kDefaultExtensionRoles));
}

std::string user_skills_dir(const SkillsContext& ctx) {
    const std::string home = expand_home("~", env_of(ctx));
    if (home == "~" || home.empty()) return {};
    return (fsys::path(home) / ".factoria" / "skills").string();
}

std::string project_skills_dir(const SkillsContext& ctx) {
    if (ctx.projectDir.empty()) return {};
    return (fsys::path(ctx.projectDir) / "skills").string();
}

std::vector<SkillInfo> scan_skills(const std::vector<Extension>& userEntries, const std::vector<Extension>& projectEntries,
                                   const SkillsContext& ctx) {
    ExtensionContext ext;
    ext.projectDir = ctx.projectDir;
    ext.env = env_of(ctx);
    std::vector<SkillInfo> found;  // insertion order: project entries, user entries, project folder, user folder, engine
    auto from_entries = [&](const std::vector<Extension>& entries, const char* scope) {
        for (const Extension& e : entries) {
            if (e.kind != ExtensionKind::Skill) continue;
            const ExtensionItem item = resolve_extension(e, ext, true);
            auto fill = [&](SkillInfo& s) {
                s.entry = e.name;
                s.entryScope = scope;
                s.enabled = e.enabled;
                s.roles = e.roles;
            };
            if (!item.problem.empty()) {
                SkillInfo s;
                s.name = e.name;
                s.defaultRoles.assign(std::begin(kDefaultExtensionRoles), std::end(kDefaultExtensionRoles));
                s.source = e.from_project() ? "project" : "user";
                s.problem = item.problem;
                s.fix = item.fix;
                fill(s);
                found.push_back(std::move(s));
                continue;
            }
            for (const std::string& d : item.dirs) {
                SkillInfo s;
                s.dir = d;
                fill(s);
                found.push_back(std::move(s));
            }
        }
    };
    from_entries(projectEntries, "project");
    from_entries(userEntries, "user");
    add_folder_candidates(project_skills_dir(ctx), found);
    add_folder_candidates(user_skills_dir(ctx), found);
    for (const std::string& n : fa::engine_skill_names()) {
        SkillInfo s;
        s.dir = kEngineSkillPrefix + n;
        found.push_back(std::move(s));
    }

    // One skill per folder: the first candidate for a folder (an entry, before the folder scan) is the one that counts.
    std::vector<SkillInfo> out;
    std::set<std::string> seen;
    for (SkillInfo& s : found) {
        if (!s.dir.empty() && !seen.insert(canonical_key(s.dir)).second) continue;
        if (!s.dir.empty()) {
            s.source = source_of(s.dir, ctx);
            load_meta(s);
            s.defaultRoles = s.source == "engine" ? engine_skill_default_roles(s.name)
                                                  : std::vector<std::string>(std::begin(kDefaultExtensionRoles), std::end(kDefaultExtensionRoles));
        }
        out.push_back(std::move(s));
    }
    std::stable_sort(out.begin(), out.end(), [](const SkillInfo& a, const SkillInfo& b) {
        if (source_rank(a.source) != source_rank(b.source)) return source_rank(a.source) < source_rank(b.source);
        if (a.entry.empty() != b.entry.empty()) return !a.entry.empty();
        return a.name < b.name;
    });
    std::map<std::string, std::string> winner;  // name -> source of the skill that has it
    for (SkillInfo& s : out) {
        if (!s.problem.empty()) continue;
        auto [it, fresh] = winner.emplace(s.name, s.source);
        if (!fresh) s.shadowedBy = it->second + " skill";
    }
    return out;
}

std::vector<SkillInfo> scan_skills(const AiConfig& cfg, const SkillsContext& ctx) {
    std::vector<Extension> project;
    if (!ctx.projectDir.empty()) project = load_project_extensions(ctx.projectDir).entries;
    return scan_skills(cfg.extensions.entries, project, ctx);
}

std::vector<const SkillInfo*> skills_for_role(const std::vector<SkillInfo>& all, std::string_view role) {
    std::vector<const SkillInfo*> out;
    for (const SkillInfo& s : all)
        if (s.offered_to(role)) out.push_back(&s);
    std::sort(out.begin(), out.end(), [](const SkillInfo* a, const SkillInfo* b) { return a->name < b->name; });
    return out;
}

std::vector<SkillBrief> skills_for_prompt(const std::vector<SkillInfo>& all, std::string_view role,
                                          const std::vector<std::string>& disabledRoles) {
    auto off = [&](const char* r) { return std::find(disabledRoles.begin(), disabledRoles.end(), r) != disabledRoles.end(); };
    std::vector<SkillBrief> out;
    for (const SkillInfo* s : skills_for_role(all, role)) {
        if (role == "orchestrator" && s->is_engine() && s->name == "make-art" && !off("artist")) continue;
        if (role == "orchestrator" && s->is_engine() && s->name == "make-audio" && !off("audio")) continue;
        out.push_back({s->name, s->description});
    }
    return out;
}

std::string skills_prompt(const std::vector<SkillBrief>& skills, std::string_view toolName) {
    if (skills.empty()) return {};
    std::string out = "# Skills\nTopic guides. Read one with " + std::string(toolName) + " {\"name\"} before that kind of work; it lists its other files (" +
                      std::string(toolName) + " {\"name\", \"file\"}).\n";
    for (const SkillBrief& s : skills) out += "- " + s.name + ": " + one_line(s.description, 160) + "\n";
    return out;
}

std::vector<SkillFile> skill_files(const SkillInfo& skill, std::size_t max, std::size_t* total) {
    std::vector<SkillFile> out;
    std::size_t count = 0;
    auto add = [&](std::string path, u64 bytes) {
        ++count;
        if (out.size() < max) out.push_back({std::move(path), bytes});
    };
    if (is_engine_skill_path(skill.dir)) {
        const std::string name = skill.dir.substr(kEngineSkillPrefix.size());
        for (const std::string& f : fa::engine_skill_files(name)) {
            const auto text = fa::engine_skill_read(name, f);
            add(f, text ? text->size() : 0);
        }
    } else if (!skill.dir.empty()) {
        std::vector<SkillFile> all;
        std::error_code ec;
        for (auto it = fsys::recursive_directory_iterator(skill.dir, fsys::directory_options::skip_permission_denied, ec);
             it != fsys::recursive_directory_iterator(); it.increment(ec)) {
            if (ec) break;
            const std::string fname = it->path().filename().string();
            std::error_code e2;
            if (it->is_symlink(e2)) {
                it.disable_recursion_pending();
                continue;
            }
            if (it->is_directory(e2)) {
                if (!fname.empty() && fname[0] == '.') it.disable_recursion_pending();
                continue;
            }
            if (!it->is_regular_file(e2) || (!fname.empty() && fname[0] == '.')) continue;
            all.push_back({fsys::relative(it->path(), skill.dir, e2).generic_string(), static_cast<u64>(it->file_size(e2))});
            if (all.size() > 2000) break;
        }
        std::sort(all.begin(), all.end(), [](const SkillFile& a, const SkillFile& b) {
            if ((a.path == "SKILL.md") != (b.path == "SKILL.md")) return a.path == "SKILL.md";
            return a.path < b.path;
        });
        for (SkillFile& f : all) add(std::move(f.path), f.bytes);
    }
    if (total) *total = count;
    return out;
}

Json SkillRead::to_json() const {
    Json files_json = Json::array();
    for (const SkillFile& f : files) files_json.push_back(Json::object({{"path", f.path}, {"bytes", f.bytes}}));
    Json j = Json::object({{"name", name}, {"source", source}, {"file", file}, {"content", content}, {"totalBytes", totalBytes}});
    if (!description.empty()) j["description"] = description;
    if (truncated) {
        j["truncated"] = true;
        j["nextOffset"] = nextOffset;
    }
    if (!files.empty()) j["files"] = files_json;
    return j;
}

Result<SkillRead> read_skill(const SkillInfo& skill, std::string_view fileIn, u64 offset, u64 limit) {
    if (!skill.problem.empty()) return make_error("The skill '" + skill.name + "' cannot be read: " + skill.problem, skill.fix);
    std::string file(fileIn);
    std::replace(file.begin(), file.end(), '\\', '/');
    const bool main = file.empty() || file == "SKILL.md";
    if (main) file = "SKILL.md";
    SkillRead out;
    out.name = skill.name;
    out.source = skill.source;
    out.file = file;
    std::size_t total = 0;
    out.files = skill_files(skill, 60, &total);
    out.files.erase(std::remove_if(out.files.begin(), out.files.end(), [](const SkillFile& f) { return f.path == "SKILL.md"; }), out.files.end());

    std::optional<std::string> text;
    if (is_engine_skill_path(skill.dir)) {
        const std::string name = skill.dir.substr(kEngineSkillPrefix.size());
        const std::vector<std::string> files = fa::engine_skill_files(name);
        if (std::find(files.begin(), files.end(), file) == files.end()) {
            return make_error("The skill '" + skill.name + "' has no file '" + file + "'",
                              fa::did_you_mean(file, files));
        }
        text = fa::engine_skill_read(name, file);
    } else {
        const fsys::path rel(file);
        if (rel.is_absolute() || rel.has_root_name() || file.find("..") != std::string::npos) {
            return make_error("'" + file + "' is not inside the skill's folder",
                              "Name a file beside SKILL.md by its path relative to the skill, for example \"reference.md\".");
        }
        const fsys::path full = fsys::path(skill.dir) / rel;
        std::error_code ec;
        if (!fsys::is_regular_file(full, ec)) {
            std::vector<std::string> names;
            for (const SkillFile& f : skill_files(skill, 200)) names.push_back(f.path);
            return make_error("The skill '" + skill.name + "' has no file '" + file + "'", fa::did_you_mean(file, names));
        }
        if (!inside_dir(fsys::path(skill.dir), full)) {
            return make_error("'" + file + "' leaves the skill's folder (a link points outside it)", "Only files that really live in the skill's folder can be read.");
        }
        text = read_whole(full);
        if (!text) return make_error("Cannot read '" + file + "' of the skill '" + skill.name + "'", "Check that the file is readable.");
    }
    // A file that is not text (an image, a program) is not read into the conversation.
    if (text->find('\0') != std::string::npos) {
        return make_error("'" + file + "' of the skill '" + skill.name + "' is not a text file", "Skills are read as text; open a binary file with the tool that handles it.");
    }
    std::string body = *text;
    if (main) {
        if (auto fm = fa::parse_skill_md(*text, "SKILL.md")) {
            body = fm->body;
            out.description = fm->description;
        }
        while (!body.empty() && (body.front() == '\n' || body.front() == '\r')) body.erase(body.begin());
    }
    out.totalBytes = body.size();
    const u64 maxBytes = limit ? limit : kDefaultReadBytes;
    if (offset > body.size()) {
        return make_error("offset " + std::to_string(offset) + " is past the end of '" + file + "' (" + std::to_string(body.size()) + " bytes)",
                          "Read from offset 0, or from a smaller offset.");
    }
    u64 end = std::min<u64>(body.size(), offset + maxBytes);
    if (end < body.size()) {  // do not cut a UTF-8 character in two
        while (end > offset && (static_cast<unsigned char>(body[end]) & 0xC0) == 0x80) --end;
        out.truncated = true;
        out.nextOffset = end;
    }
    out.content = body.substr(offset, end - offset);
    return out;
}

Result<std::string> create_skill(const std::string& skillsDir, std::string_view name, std::string_view description) {
    if (const std::string problem = fa::skill_name_problem(name); !problem.empty()) {
        return make_error("Cannot create the skill: " + problem, "A skill's name is also its folder: lowercase letters, digits and hyphens.");
    }
    const fsys::path folder = fsys::path(skillsDir) / std::string(name);
    std::error_code ec;
    if (fsys::exists(folder, ec)) {
        return make_error("The skill '" + std::string(name) + "' already exists at " + folder.string(), "Edit its SKILL.md, or choose another name.");
    }
    const fsys::path md = folder / "SKILL.md";
    if (auto ok = fs::write_text(md.string(), fa::skill_template(name, description)); !ok) return ok.error();
    return md.string();
}


namespace {

Json skill_json(const SkillInfo& s, bool withFiles) {
    Json j = Json::object({{"name", s.name}, {"description", s.description}, {"source", s.source}, {"enabled", s.enabled},
                           {"roles", s.effective_roles()}});
    if (!s.dir.empty()) j["dir"] = s.dir;
    if (!s.entry.empty()) {
        j["entry"] = s.entry;
        j["entryScope"] = s.entryScope;
    }
    if (!s.shadowedBy.empty()) j["shadowedBy"] = s.shadowedBy;
    if (!s.problem.empty()) {
        j["problem"] = s.problem;
        j["fix"] = s.fix;
    }
    if (withFiles) {
        Json files = Json::array();
        for (const SkillFile& f : skill_files(s, 40)) files.push_back(Json::object({{"path", f.path}, {"bytes", f.bytes}}));
        j["files"] = files;
    }
    return j;
}

}  // namespace

void register_skills_commands(CommandRegistry& registry, SkillsCommandOptions options) {
    auto opts = std::make_shared<SkillsCommandOptions>(std::move(options));
    auto load = [opts]() -> Result<AiConfig> {
        if (opts->loadConfig) return opts->loadConfig();
        return load_config();
    };
    auto context = [opts]() {
        SkillsContext ctx;
        ctx.projectDir = opts->projectDir ? opts->projectDir() : fs::project_root().string();
        ctx.env = opts->env;
        return ctx;
    };
    auto check_role = [](const std::string& role) {
        if (!role.empty() && !is_known_role(role)) {
            const std::vector<std::string> names(std::begin(kAllRoles), std::end(kAllRoles));
            throw CommandError("unknown_role", "No role named '" + role + "'", fa::did_you_mean(role, names));
        }
    };

    {
        CommandInfo info;
        info.name = "skills.list";
        info.category = "skills";
        info.summary = "List the skills (topic guides) available to a role: name, description, where each lives.";
        info.description =
            "Skills are folders with a SKILL.md (Agent Skills format) that you read only when a task needs them: the engine's own "
            "(make-art, make-audio, custom-shaders...), the user's (~/.factoria/skills) and the project's (skills/). Returns "
            "{skills:[{name, description, source engine|user|project, enabled, roles, dir, entry?, shadowedBy? (another skill of "
            "the same name wins), problem + fix? (SKILL.md invalid: not offered)}], count}. With `role`, only the skills that "
            "role is offered; without it, every skill with its settings. Read one with skills.read. docs/SKILLS.md. "
            "Example: {\"role\":\"worker\"}";
        info.inputSchema = Json::parse(R"({"type":"object","properties":{
            "role":{"type":"string","description":"Only the skills this role is offered (orchestrator, worker, fast, artist, audio, artCritic, reviewer). Omit for all."}},
            "additionalProperties":false})");
        info.readOnly = true;
        registry.add(std::move(info), [load, context, check_role](const Json& args) -> Json {
            auto cfg = load();
            if (!cfg) throw CommandError("invalid_config", cfg.error().message, cfg.error().hint);
            const std::string role = str(args, "role");
            check_role(role);
            const std::vector<SkillInfo> all = scan_skills(*cfg, context());
            Json list = Json::array();
            for (const SkillInfo& s : all) {
                if (!role.empty() && !s.offered_to(role)) continue;
                list.push_back(skill_json(s, false));
            }
            const std::size_t n = list.size();
            return Json::object({{"skills", std::move(list)}, {"count", n}});
        });
    }
    {
        CommandInfo info;
        info.name = "skills.read";
        info.category = "skills";
        info.summary = "Read a skill: its SKILL.md instructions, or another file of the skill.";
        info.description =
            "Loads the instructions of the skill `name` (see the Skills list in your prompt, or skills.list) before you start the "
            "kind of work it covers. Without `file` it returns the body of SKILL.md and lists the other files beside it; read one "
            "with `file` (a path relative to the skill, \"reference.md\"). Long files come in pieces: `truncated` and `nextOffset` "
            "say where the next call continues (`offset`, `limit` are bytes). Returns {name, source, file, description?, content, "
            "totalBytes, truncated?, nextOffset?, files?}. Unknown names and files answer with the ones that exist. docs/SKILLS.md. "
            "Example: {\"name\":\"make-art\"} or {\"name\":\"make-art\",\"file\":\"reference.md\"}";
        info.inputSchema = Json::parse(R"({"type":"object","properties":{
            "name":{"type":"string","description":"Skill name, as in the Skills list."},
            "file":{"type":"string","description":"File of the skill, relative to its folder. Default SKILL.md."},
            "offset":{"type":"integer","minimum":0,"description":"Byte to start at (continue a truncated read with nextOffset)."},
            "limit":{"type":"integer","minimum":1,"description":"Most bytes to return. Default 60000."},
            "role":{"type":"string","description":"The role asking: only the skills it is offered can be read. FactorIA fills it in for you."}},
            "required":["name"],"additionalProperties":false})");
        info.readOnly = true;
        registry.add(std::move(info), [load, context, check_role](const Json& args) -> Json {
            auto cfg = load();
            if (!cfg) throw CommandError("invalid_config", cfg.error().message, cfg.error().hint);
            const std::string name = str(args, "name");
            if (name.empty()) throw CommandError("missing_name", "skills.read needs a `name`", "Call skills.list for the names.");
            const std::string role = str(args, "role");
            check_role(role);
            const std::vector<SkillInfo> all = scan_skills(*cfg, context());
            const SkillInfo* hit = nullptr;
            bool hiddenFromRole = false;
            std::vector<std::string> names;
            for (const SkillInfo& s : all) {
                if (!s.problem.empty() && s.dir.empty()) continue;
                if (!s.shadowedBy.empty()) continue;
                if (!role.empty() && !s.offered_to(role)) {
                    if (s.name == name) hiddenFromRole = true;
                    continue;
                }
                names.push_back(s.name);
                if (s.name == name && !hit) hit = &s;
            }
            if (!hit) {
                if (hiddenFromRole)
                    throw CommandError("skill_not_offered", "The skill '" + name + "' is not offered to the role '" + role + "'",
                                       "It is switched off for that role (AI settings > Extensions, or the skill's entry in the extensions). "
                                       "Skills you can read: " + (names.empty() ? std::string("none") : join(names, ", ")) + ".");
                throw CommandError("unknown_skill", "No skill named '" + name + "'",
                                   names.empty() ? "There are no skills yet; skills.new creates one." : fa::did_you_mean(name, names));
            }
            auto r = read_skill(*hit, str(args, "file"), static_cast<u64>(num(args, "offset", 0)), static_cast<u64>(num(args, "limit", 0)));
            if (!r) throw CommandError("skill_read_failed", r.error().message, r.error().hint);
            return r->to_json();
        });
    }
    {
        CommandInfo info;
        info.name = "skills.new";
        info.category = "skills";
        info.summary = "Create a skill: skills/<name>/SKILL.md in the project (or in ~/.factoria/skills).";
        info.description =
            "Writes a SKILL.md from the Agent Skills template: frontmatter with `name` (lowercase letters, digits and hyphens, up "
            "to 64, the folder's name) and `description` (what the skill is for and WHEN to read it, up to 1024 characters), then a "
            "body to fill in. Add other files beside it and name them in the body. Never overwrites an existing skill. scope "
            "\"project\" (default) writes into the project's skills/ folder, which the game's other AIs and `factoria validate` see; "
            "\"user\" writes into ~/.factoria/skills for every project. Returns {path, name, scope}. docs/SKILLS.md. "
            "Example: {\"name\":\"enemy-design\",\"description\":\"How enemies are built in this game. Read before adding an enemy.\"}";
        info.inputSchema = Json::parse(R"({"type":"object","properties":{
            "name":{"type":"string","description":"Skill name and folder: lowercase letters, digits, single hyphens."},
            "description":{"type":"string","description":"What the skill covers and when to read it (up to 1024 characters)."},
            "scope":{"type":"string","enum":["project","user"],"default":"project","description":"Where to create it."}},
            "required":["name"],"additionalProperties":false})");
        info.readOnly = false;
        registry.add(std::move(info), [context](const Json& args) -> Json {
            const std::string name = str(args, "name");
            const std::string scope = str(args, "scope", "project");
            if (scope != "project" && scope != "user")
                throw CommandError("invalid_scope", "scope '" + scope + "' is not known", "Use \"project\" or \"user\".");
            const SkillsContext ctx = context();
            const std::string dir = scope == "project" ? project_skills_dir(ctx) : user_skills_dir(ctx);
            if (dir.empty())
                throw CommandError("no_folder", scope == "project" ? "There is no project folder to put the skill in" : "There is no home folder",
                                   scope == "project" ? "Run this from a game project, or use scope \"user\"." : "Set HOME, or use scope \"project\".");
            std::string description = str(args, "description");
            if (description.size() > fa::kMaxSkillDescription)
                throw CommandError("description_too_long", "The description has " + std::to_string(description.size()) + " characters; the limit is " +
                                                               std::to_string(fa::kMaxSkillDescription),
                                   "Say what the skill is for and when to read it; put the details in the body.");
            auto path = create_skill(dir, name, description);
            if (!path) throw CommandError("skill_not_created", path.error().message, path.error().hint);
            return Json::object({{"path", *path}, {"name", name}, {"scope", scope}});
        });
    }
}

}  // namespace fa::ai
