// Skills for every provider (fa/ai/skills.h, docs/SKILLS.md): where they come from and which one wins, the roles that are offered
// each, the prompt lines and the craft guides that moved out of the prompt, skills.read / skills.list / skills.new, what Claude Code
// receives, and the built-in loop reading a skill.
#include <algorithm>
#include <fstream>

#include "fa/ai/commands.h"
#include "fa/ai/extension_plan.h"
#include "fa/ai/skills.h"
#include "fa/tooling/skills.h"
#include "test_common.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;
namespace fsys = std::filesystem;

namespace {

bool has(const std::string& text, const std::string& part) { return text.find(part) != std::string::npos; }

void write_file(const fsys::path& path, const std::string& text) {
    fsys::create_directories(path.parent_path());
    std::ofstream(path, std::ios::binary) << text;
}

std::string skill_md(const std::string& name, const std::string& description, const std::string& body = "Do the thing.") {
    return "---\nname: " + name + "\ndescription: " + description + "\n---\n\n" + body + "\n";
}

// A home folder and a project folder, each with a skills/ folder to fill.
struct World {
    TempDir home, project;
    SkillsContext ctx;
    World() {
        ctx.projectDir = project.str();
        ctx.env = fake_env({{"HOME", home.str()}});
    }
    void user(const std::string& name, const std::string& description, const std::string& body = "Do the thing.") {
        write_file(home.path / ".factoria" / "skills" / name / "SKILL.md", skill_md(name, description, body));
    }
    void proj(const std::string& name, const std::string& description, const std::string& body = "Do the thing.") {
        write_file(project.path / "skills" / name / "SKILL.md", skill_md(name, description, body));
    }
    std::vector<SkillInfo> scan(std::vector<Extension> userEntries = {}, std::vector<Extension> projectEntries = {}) const {
        return scan_skills(userEntries, projectEntries, ctx);
    }
};

const SkillInfo* find(const std::vector<SkillInfo>& all, const std::string& name, const std::string& source = {}) {
    for (const SkillInfo& s : all)
        if (s.name == name && (source.empty() || s.source == source)) return &s;
    return nullptr;
}

Extension skill_entry(const std::string& name, const std::string& path, std::vector<std::string> roles = {}, bool enabled = true) {
    Extension e;
    e.kind = ExtensionKind::Skill;
    e.name = name;
    e.path = path;
    e.roles = std::move(roles);
    e.enabled = enabled;
    return e;
}

std::vector<std::string> names_for(const std::vector<SkillInfo>& all, const std::string& role) {
    std::vector<std::string> out;
    for (const SkillInfo* s : skills_for_role(all, role)) out.push_back(s->name);
    return out;
}

std::string str_of(const Json& j, const char* key) { return j.is_object() && j.contains(key) && j[key].is_string() ? j[key].get<std::string>() : std::string(); }

bool contains(const std::vector<std::string>& v, const std::string& s) { return std::find(v.begin(), v.end(), s) != v.end(); }

}  // namespace

TEST_CASE("skills: found in the engine, the user's folder and the project's folder") {
    World w;
    w.user("tone", "The tone of the writing. Read before writing text.");
    w.proj("enemies", "How enemies work. Read before adding one.");
    const auto all = w.scan();
    const SkillInfo* tone = find(all, "tone");
    REQUIRE(tone);
    CHECK(tone->source == "user");
    CHECK(tone->description == "The tone of the writing. Read before writing text.");
    CHECK(tone->entry.empty());
    const SkillInfo* enemies = find(all, "enemies");
    REQUIRE(enemies);
    CHECK(enemies->source == "project");
    const SkillInfo* art = find(all, "make-art");
    REQUIRE(art);
    CHECK(art->source == "engine");
    CHECK(art->dir == "engine:make-art");
    CHECK(art->problem.empty());
    CHECK(art->shadowedBy.empty());
}

TEST_CASE("skills: the project wins over the user, who wins over the engine, and the loser says why") {
    World w;
    w.user("shared", "The user's.");
    w.proj("shared", "The project's.");
    w.user("make-art", "My own art guide. Read first.");
    const auto all = w.scan();
    const SkillInfo* proj = find(all, "shared", "project");
    const SkillInfo* user = find(all, "shared", "user");
    REQUIRE(proj);
    REQUIRE(user);
    CHECK(proj->shadowedBy.empty());
    CHECK(user->shadowedBy == "project skill");
    const SkillInfo* mine = find(all, "make-art", "user");
    const SkillInfo* engine = find(all, "make-art", "engine");
    REQUIRE(mine);
    REQUIRE(engine);
    CHECK(mine->shadowedBy.empty());
    CHECK(engine->shadowedBy == "user skill");
    // only the winner is offered, and only once
    const auto workerNames = names_for(all, "worker");
    CHECK(std::count(workerNames.begin(), workerNames.end(), "shared") == 1);
    const auto forArtist = skills_for_role(all, "artist");
    for (const SkillInfo* s : forArtist)
        if (s->name == "make-art") CHECK(s->source == "user");
}

TEST_CASE("skills: a skill that cannot be used is listed with its problem and never offered") {
    World w;
    write_file(w.project.path / "skills" / "broken" / "SKILL.md", "no frontmatter here\n");
    write_file(w.project.path / "skills" / "renamed" / "SKILL.md", skill_md("other-name", "d"));
    const auto all = w.scan();
    const SkillInfo* broken = find(all, "broken");
    REQUIRE(broken);
    CHECK(has(broken->problem, "frontmatter"));
    CHECK_FALSE(broken->fix.empty());
    CHECK_FALSE(broken->offered_to("worker"));
    CHECK(find(all, "other-name"));  // the frontmatter's name is the skill's name
    CHECK_FALSE(contains(names_for(all, "worker"), "broken"));
}

TEST_CASE("skills: engine skills go to the roles whose work they are about") {
    World w;
    const auto all = w.scan();
    CHECK(contains(names_for(all, "artist"), "make-art"));
    CHECK_FALSE(contains(names_for(all, "audio"), "make-art"));
    CHECK(contains(names_for(all, "audio"), "make-audio"));
    CHECK(contains(names_for(all, "worker"), "tile-levels"));
    CHECK_FALSE(contains(names_for(all, "artist"), "tile-levels"));
    CHECK(contains(names_for(all, "worker"), "review-ready"));
    CHECK(names_for(all, "fast").empty());           // tiny edits need no guide
    CHECK(names_for(all, "reviewer").empty());       // the critics and reviewers only look
    CHECK(names_for(all, "artCritic").empty());
    for (const std::string& name : fa::engine_skill_names()) {
        CAPTURE(name);
        CHECK_FALSE(engine_skill_default_roles(name).empty());
    }
}

TEST_CASE("skills: an entry of the extensions sets the roles and the on/off of a skill") {
    World w;
    w.user("tone", "The tone.");
    write_file(w.home.path / "elsewhere" / "pacing" / "SKILL.md", skill_md("pacing", "Pacing. Read before levels."));
    // roles: only the worker; engine:make-art off; a folder of skill folders
    std::vector<Extension> entries = {
        skill_entry("tone", (w.home.path / ".factoria" / "skills" / "tone").string(), {"worker"}),
        skill_entry("art", "engine:make-art", {}, false),
        skill_entry("more", (w.home.path / "elsewhere").string()),
    };
    const auto all = w.scan(entries);
    const SkillInfo* tone = find(all, "tone");
    REQUIRE(tone);
    CHECK(tone->entry == "tone");
    CHECK(tone->entryScope == "user");
    CHECK(tone->roles == std::vector<std::string>{"worker"});
    CHECK(tone->offered_to("worker"));
    CHECK_FALSE(tone->offered_to("artist"));
    const SkillInfo* art = find(all, "make-art");
    REQUIRE(art);
    CHECK(art->entry == "art");
    CHECK_FALSE(art->enabled);
    CHECK_FALSE(art->offered_to("artist"));
    CHECK(std::count_if(all.begin(), all.end(), [](const SkillInfo& s) { return s.name == "make-art"; }) == 1);  // not twice
    const SkillInfo* pacing = find(all, "pacing");
    REQUIRE(pacing);
    CHECK(pacing->entry == "more");
    CHECK(pacing->offered_to("orchestrator"));
    CHECK_FALSE(pacing->offered_to("reviewer"));
}

TEST_CASE("skills: an entry that points nowhere is reported, not hidden") {
    World w;
    const auto all = w.scan({skill_entry("ghost", (w.home.path / "nope").string()), skill_entry("typo", "engine:make-ar")});
    const SkillInfo* ghost = find(all, "ghost");
    REQUIRE(ghost);
    CHECK_FALSE(ghost->problem.empty());
    CHECK_FALSE(ghost->offered_to("worker"));
    const SkillInfo* typo = find(all, "typo");
    REQUIRE(typo);
    CHECK(has(typo->problem, "make-ar"));
    CHECK(has(typo->fix, "make-art"));  // did you mean
}

TEST_CASE("skills: the prompt gets one line per skill, and a craft guide is read, not carried") {
    World w;
    w.proj("enemies", "How enemies work. Read before adding one.");
    const auto all = w.scan();

    PromptContext worker;
    worker.role = "worker";
    worker.skills = skills_for_prompt(all, "worker", {});
    worker.skillsKnown = true;
    const std::string prompt = build_system_prompt(worker);
    CHECK(has(prompt, "# Skills"));
    CHECK(has(prompt, "- enemies: How enemies work. Read before adding one."));
    CHECK(has(prompt, "- tile-levels: "));
    CHECK(has(prompt, "skills_read"));
    CHECK_FALSE(has(prompt, "# Build the game so it can be reviewed"));  // review-ready is a skill now

    PromptContext artist;
    artist.role = "artist";
    artist.skills = skills_for_prompt(all, "artist", {});
    artist.skillsKnown = true;
    const std::string artistPrompt = build_system_prompt(artist);
    CHECK(has(artistPrompt, "Your craft guide is the skill `make-art`"));
    CHECK_FALSE(has(artistPrompt, "Keep one art direction: palette, outline weight"));  // the guide's own text

    // A context that did not look for skills keeps the old, complete prompt.
    PromptContext legacy;
    legacy.role = "artist";
    const std::string old = build_system_prompt(legacy);
    CHECK(has(old, "Keep one art direction: palette, outline weight"));
    CHECK(has(old, "# Build the game so it can be reviewed"));
    CHECK_FALSE(has(old, "# Skills"));

    // The skills the user switched off for the role are not in its prompt and its guide is not asked for.
    PromptContext off;
    off.role = "artist";
    off.skills = {};
    off.skillsKnown = true;
    const std::string offPrompt = build_system_prompt(off);
    CHECK_FALSE(has(offPrompt, "# Skills"));
    CHECK_FALSE(has(offPrompt, "craft guide is the skill"));
    CHECK_FALSE(has(offPrompt, "Keep one art direction: palette, outline weight"));

    // A CLI that lists skills itself (Claude Code) does not get them twice.
    PromptContext native = worker;
    native.skillsNative = true;
    CHECK_FALSE(has(build_system_prompt(native), "# Skills"));
}

TEST_CASE("skills: an orchestrator reads the art and audio guides only when it makes the art or the audio itself") {
    World w;
    const auto all = w.scan();
    auto prompt_for = [&](std::vector<std::string> disabled) {
        PromptContext p;
        p.role = "orchestrator";
        p.canDelegate = true;
        p.disabledRoles = disabled;
        p.skills = skills_for_prompt(all, "orchestrator", disabled);
        p.skillsKnown = true;
        return build_system_prompt(p);
    };
    const std::string delegating = prompt_for({});
    CHECK_FALSE(has(delegating, "- make-art:"));
    CHECK_FALSE(has(delegating, "- make-audio:"));
    CHECK(has(delegating, "- review-ready:"));
    const std::string noArtist = prompt_for({"artist"});
    CHECK(has(noArtist, "- make-art:"));
    CHECK(has(noArtist, "Your craft guide is the skill `make-art`"));
    CHECK_FALSE(has(noArtist, "- make-audio:"));
    const std::string noAudio = prompt_for({"audio"});
    CHECK(has(noAudio, "Your craft guide is the skill `make-audio`"));
}

TEST_CASE("skills: the prompt is smaller than the guides it replaced, and the size is stable") {
    World w;
    const auto all = w.scan();
    auto size = [&](const char* role, bool delegate, std::vector<std::string> disabled, bool withSkills) {
        PromptContext p;
        p.role = role;
        p.canDelegate = delegate;
        p.disabledRoles = disabled;
        if (withSkills) {
            p.skills = skills_for_prompt(all, role, disabled);
            p.skillsKnown = true;
        }
        return build_system_prompt(p).size();
    };
    // Before skills, a context without them carries the guides itself: the same text the old prompt had.
    CHECK(size("artist", false, {}, true) < size("artist", false, {}, false));
    CHECK(size("audio", false, {}, true) < size("audio", false, {}, false));
    CHECK(size("worker", false, {}, true) < size("worker", false, {}, false));
    CHECK(size("orchestrator", true, {"artist", "audio"}, true) < size("orchestrator", true, {"artist", "audio"}, false));
    CHECK(size("orchestrator", true, {}, true) < size("orchestrator", true, {}, false));
    // The skills section of the busiest role stays small: it is paid on every turn of every run.
    PromptContext p;
    p.role = "orchestrator";
    p.skills = skills_for_prompt(all, "orchestrator", {});
    CHECK(skills_prompt(p.skills).size() < 1500);
}

TEST_CASE("skills: read_skill gives the body, lists the other files and reads one by path") {
    World w;
    w.proj("enemies", "How enemies work.", "Enemies walk.\nSee reference.md.");
    write_file(w.project.path / "skills" / "enemies" / "reference.md", "REFERENCE TEXT\n");
    write_file(w.project.path / "skills" / "enemies" / "data" / "stats.json", "{}");
    const auto all = w.scan();
    const SkillInfo* s = find(all, "enemies");
    REQUIRE(s);

    auto body = read_skill(*s, "", 0, 0);
    REQUIRE(body.ok());
    CHECK(body->file == "SKILL.md");
    CHECK(body->content.find("Enemies walk.") != std::string::npos);
    CHECK(body->content.find("name: enemies") == std::string::npos);  // the frontmatter is name and description already
    CHECK(body->description == "How enemies work.");
    std::vector<std::string> files;
    for (const SkillFile& f : body->files) files.push_back(f.path);
    CHECK(files == std::vector<std::string>{"data/stats.json", "reference.md"});

    auto ref = read_skill(*s, "reference.md", 0, 0);
    REQUIRE(ref.ok());
    CHECK(ref->content == "REFERENCE TEXT\n");
    CHECK(ref->to_json()["totalBytes"] == 15);

    auto nested = read_skill(*s, "data\\stats.json", 0, 0);
    REQUIRE(nested.ok());
    CHECK(nested->content == "{}");
}

TEST_CASE("skills: read_skill teaches on a wrong file and refuses what leaves the folder or is not text") {
    World w;
    w.proj("enemies", "d");
    write_file(w.project.path / "skills" / "enemies" / "reference.md", "text");
    write_file(w.project.path / "skills" / "enemies" / "image.bin", std::string("a\0b", 3));
    write_file(w.project.path / "secret.txt", "secret");
    const auto all = w.scan();
    const SkillInfo* s = find(all, "enemies");
    REQUIRE(s);

    auto typo = read_skill(*s, "referense.md", 0, 0);
    REQUIRE_FALSE(typo.ok());
    CHECK(has(typo.error().message, "no file 'referense.md'"));
    CHECK(has(typo.error().hint, "reference.md"));

    for (const char* bad : {"../../secret.txt", "../enemies/reference.md", "/etc/hosts"}) {
        CAPTURE(bad);
        auto r = read_skill(*s, bad, 0, 0);
        REQUIRE_FALSE(r.ok());
        CHECK(has(r.error().message, "not inside the skill's folder"));
    }
    auto binary = read_skill(*s, "image.bin", 0, 0);
    REQUIRE_FALSE(binary.ok());
    CHECK(has(binary.error().message, "not a text file"));
}

TEST_CASE("skills: a long file comes in pieces with nextOffset, never cutting a character in two") {
    World w;
    std::string body;
    for (int i = 0; i < 100; ++i) body += "línea número " + std::to_string(i) + "\n";  // multi-byte characters
    w.proj("long", "d", body);
    const auto all = w.scan();
    const SkillInfo* s = find(all, "long");
    REQUIRE(s);
    std::string joined;
    u64 offset = 0;
    int pieces = 0;
    for (;;) {
        auto r = read_skill(*s, "", offset, 333);
        REQUIRE(r.ok());
        CHECK(r->content.size() <= 333);
        joined += r->content;
        ++pieces;
        if (!r->truncated) break;
        CHECK(r->nextOffset == offset + r->content.size());
        offset = r->nextOffset;
        REQUIRE(pieces < 100);
    }
    CHECK(pieces > 3);
    CHECK(has(joined, "línea número 99"));
    CHECK(joined.size() == body.size() + 1);  // the body's own trailing newline is kept
    auto past = read_skill(*s, "", 99999999, 0);
    REQUIRE_FALSE(past.ok());
    CHECK(has(past.error().message, "past the end"));
}

TEST_CASE("skills: engine skills are read from the binary, with their other files") {
    World w;
    const auto all = w.scan();
    const SkillInfo* review = find(all, "review-ready");
    REQUIRE(review);
    auto r = read_skill(*review, "", 0, 0);
    REQUIRE(r.ok());
    CHECK(has(r->content, "REVIEW.md"));
    REQUIRE(r->files.size() == 1);
    CHECK(r->files[0].path == "review-md-template.md");
    auto tpl = read_skill(*review, "review-md-template.md", 0, 0);
    REQUIRE(tpl.ok());
    CHECK(has(tpl->content, "How to play"));
    auto bad = read_skill(*review, "review-md-templte.md", 0, 0);
    REQUIRE_FALSE(bad.ok());
    CHECK(has(bad.error().hint, "review-md-template.md"));
}

TEST_CASE("skills: skills.list, skills.read and skills.new through the registry") {
    World w;
    w.proj("enemies", "How enemies work. Read before adding one.");
    CommandRegistry reg;
    SkillsCommandOptions so;
    so.loadConfig = [] { return Result<AiConfig>(default_config()); };
    so.projectDir = [&] { return w.project.str(); };
    so.env = w.ctx.env;
    register_skills_commands(reg, so);

    for (const char* name : {"skills.list", "skills.read", "skills.new"}) {
        CAPTURE(name);
        const CommandInfo* info = reg.info(name);
        REQUIRE(info);
        CHECK(info->category == "skills");
        CHECK(info->description.size() > 100);
        CHECK(has(info->description, "Example"));
    }
    CHECK(reg.info("skills.list")->readOnly);
    CHECK(reg.info("skills.read")->readOnly);
    CHECK_FALSE(reg.info("skills.new")->readOnly);

    auto list = reg.call("skills.list", Json::object());
    REQUIRE(list.ok);
    CHECK(list.result["count"].get<int>() >= 12);
    bool seen = false;
    for (const Json& s : list.result["skills"])
        if (s["name"] == "enemies") {
            seen = true;
            CHECK(s["source"] == "project");
            CHECK(s["enabled"] == true);
        }
    CHECK(seen);

    auto forArtist = reg.call("skills.list", Json::object({{"role", "artist"}}));
    REQUIRE(forArtist.ok);
    bool hasArt = false, hasTiles = false;
    for (const Json& s : forArtist.result["skills"]) {
        hasArt = hasArt || s["name"] == "make-art";
        hasTiles = hasTiles || s["name"] == "tile-levels";
    }
    CHECK(hasArt);
    CHECK_FALSE(hasTiles);
    CHECK_FALSE(reg.call("skills.list", Json::object({{"role", "wrker"}})).ok);

    auto read = reg.call("skills.read", Json::object({{"name", "enemies"}}));
    REQUIRE(read.ok);
    CHECK(has(read.result["content"].get<std::string>(), "Do the thing."));
    auto unknown = reg.call("skills.read", Json::object({{"name", "enemys"}}));
    REQUIRE_FALSE(unknown.ok);
    CHECK(str_of(unknown.error, "code") == "unknown_skill");
    CHECK(has(str_of(unknown.error, "hint"), "enemies"));
    // a role that is not offered the skill cannot read it
    auto refused = reg.call("skills.read", Json::object({{"name", "tile-levels"}, {"role", "artist"}}));
    REQUIRE_FALSE(refused.ok);
    CHECK(str_of(refused.error, "code") == "skill_not_offered");
    CHECK(reg.call("skills.read", Json::object({{"name", "tile-levels"}, {"role", "worker"}})).ok);

    auto made = reg.call("skills.new", Json::object({{"name", "pacing"}, {"description", "How levels are paced: read before levels."}}));
    REQUIRE(made.ok);
    CHECK(fsys::exists(w.project.path / "skills" / "pacing" / "SKILL.md"));
    auto again = reg.call("skills.new", Json::object({{"name", "pacing"}}));
    REQUIRE_FALSE(again.ok);
    CHECK(has(str_of(again.error, "message"), "already exists"));
    auto badName = reg.call("skills.new", Json::object({{"name", "Bad Name"}}));
    REQUIRE_FALSE(badName.ok);
    CHECK(has(str_of(badName.error, "message") + str_of(badName.error, "hint"), "bad-name"));
    auto user = reg.call("skills.new", Json::object({{"name", "mine"}, {"scope", "user"}}));
    REQUIRE(user.ok);
    CHECK(fsys::exists(w.home.path / ".factoria" / "skills" / "mine" / "SKILL.md"));
    // the new skill is found, and valid
    auto back = reg.call("skills.read", Json::object({{"name", "pacing"}}));
    REQUIRE(back.ok);
    CHECK(back.result["description"] == "How levels are paced: read before levels.");
}

TEST_CASE("skills: Claude Code receives the skills of the role as one generated plugin") {
    World w;
    w.proj("enemies", "How enemies work.");
    w.user("tone", "The tone.");
    AiConfig cfg = default_config();
    cfg.extensions.entries.push_back(skill_entry("art", "engine:make-art", {}, false));
    ExtensionContext ctx;
    ctx.projectDir = w.project.str();
    ctx.env = w.ctx.env;

    ProviderConfig claude;
    claude.name = "claude-code";
    claude.kind = ProviderKind::ClaudeCode;
    const ExtensionPlan worker = plan_extensions(cfg, claude, "worker", ctx);
    CHECK(worker.support.skills);
    CHECK(contains(worker.implicitSkillDirs, "engine:tile-levels"));
    CHECK(contains(worker.implicitSkillDirs, (w.project.path / "skills" / "enemies").string()));
    CHECK(contains(worker.implicitSkillDirs, (w.home.path / ".factoria" / "skills" / "tone").string()));
    CHECK_FALSE(contains(worker.implicitSkillDirs, "engine:make-art"));  // not a worker's skill
    CHECK(contains(worker.implicitSkillDirs, "engine:review-ready"));
    CHECK(worker.empty());  // nothing the user configured

    const ExtensionPlan artist = plan_extensions(cfg, claude, "artist", ctx);
    CHECK_FALSE(contains(artist.implicitSkillDirs, "engine:make-art"));  // switched off by the entry

    const ExtensionPlan reviewer = plan_extensions(cfg, claude, "reviewer", ctx);
    CHECK(reviewer.implicitSkillDirs.empty());

    // Codex reads skill folders too (from the project's .agents/skills, written for the run); the API providers read skills
    // through skills.read.
    ProviderConfig codex;
    codex.name = "codex";
    codex.kind = ProviderKind::Codex;
    const ExtensionPlan codexWorker = plan_extensions(cfg, codex, "worker", ctx);
    CHECK(codexWorker.support.skills);
    CHECK(contains(codexWorker.implicitSkillDirs, "engine:tile-levels"));
    CHECK(contains(codexWorker.implicitSkillDirs, (w.project.path / "skills" / "enemies").string()));
    CHECK_FALSE(contains(codexWorker.implicitSkillDirs, "engine:make-art"));
    ProviderConfig api;
    api.name = "anthropic";
    api.kind = ProviderKind::Anthropic;
    CHECK(plan_extensions(cfg, api, "worker", ctx).implicitSkillDirs.empty());

    // The plugin holds the engine skills' files and the folders as they are.
    TempDir out;
    REQUIRE(write_skills_plugin(out.str(), {"engine:review-ready", (w.project.path / "skills" / "enemies").string()}).ok());
    CHECK(fsys::exists(out.path / ".claude-plugin" / "plugin.json"));
    CHECK(fsys::exists(out.path / "skills" / "review-ready" / "SKILL.md"));
    CHECK(fsys::exists(out.path / "skills" / "review-ready" / "review-md-template.md"));
    CHECK(fsys::exists(out.path / "skills" / "enemies" / "SKILL.md"));
}

TEST_CASE("skills: a skill entry can name an engine skill, and nothing else in the file changes") {
    auto ok = parse_extensions(Json::parse(R"({"skills":{"art":{"path":"engine:make-art","roles":["artist"]}}})"), "/extensions");
    REQUIRE(ok.ok());
    REQUIRE(ok->entries.size() == 1);
    CHECK(ok->entries[0].path == "engine:make-art");
    auto empty = parse_extensions(Json::parse(R"({"skills":{"art":{"path":"engine:"}}})"), "/extensions");
    REQUIRE_FALSE(empty.ok());
    CHECK(has(empty.error().message, "names no skill"));
    // a relative path is still refused in a user file
    CHECK_FALSE(parse_extensions(Json::parse(R"({"skills":{"x":{"path":"skills/x"}}})"), "/extensions").ok());
}

TEST_CASE("skills: the built-in loop reads a skill as the role that asks") {
    TempDir home, project;
    write_file(project.path / "skills" / "enemies" / "SKILL.md", skill_md("enemies", "How enemies work. Read before adding one.", "Enemies walk left."));
    const EnvLookup env = fake_env({{"HOME", home.str()}});

    CommandRegistry registry = make_registry();
    SkillsCommandOptions so;
    so.loadConfig = [] { return Result<AiConfig>(default_config()); };
    so.projectDir = [&] { return project.str(); };
    so.env = env;
    register_skills_commands(registry, so);

    auto provider = std::make_shared<FakeProvider>();
    provider->script = {
        tool_response({[] {
                           ToolCall c;
                           c.id = "t1";
                           c.name = "skills_read";
                           c.input = Json::object({{"name", "enemies"}, {"role", "reviewer"}});  // a role the model cannot choose
                           return c;
                       }(),
                       [] {
                           ToolCall c;
                           c.id = "t2";
                           c.name = "skills_read";
                           c.input = Json::object({{"name", "tile-levels"}});
                           return c;
                       }()}),
        text_response("Read them."),
    };
    AiConfig cfg = default_config();
    SessionOptions opt;
    opt.projectDir = project.str();
    opt.env = env;
    AgentSession session(registry, cfg, opt);
    session.set_provider_factory([&](const ProviderConfig&) -> Result<std::shared_ptr<ChatProvider>> {
        return std::static_pointer_cast<ChatProvider>(provider);
    });
    auto r = session.run("Add an enemy");
    REQUIRE(r.ok);
    REQUIRE(provider->requests.size() == 2);

    // the first request: the skills of the orchestrator in its prompt, skills_read among its tools
    const ChatRequest& first = provider->requests[0];
    CHECK(has(first.system, "# Skills"));
    CHECK(has(first.system, "- enemies: How enemies work. Read before adding one."));
    CHECK(std::any_of(first.tools.begin(), first.tools.end(), [](const ToolDef& t) { return t.name == "skills_read"; }));

    // the answers: the role is the session's (orchestrator), whatever the model wrote
    const Message& results = provider->requests[1].messages.back();
    REQUIRE(results.toolResults.size() == 2);
    CHECK_FALSE(results.toolResults[0].isError);
    CHECK(has(results.toolResults[0].content, "Enemies walk left."));
    CHECK_FALSE(results.toolResults[1].isError);
    CHECK(has(results.toolResults[1].content, "ASCII"));
}
