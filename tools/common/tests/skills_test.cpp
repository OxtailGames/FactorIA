// Agent Skills (fa/tooling/skills.h): the SKILL.md frontmatter and its teaching errors, the check of a skill folder, the skills that
// ship inside the binary, and what `factoria validate` reports about a project's skills/ folder.
#include <doctest.h>

#include <algorithm>
#include <filesystem>

#include "fa/core/strings.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/skills.h"
#include "fa/tooling/validate.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

bool has(const std::string& text, const std::string& part) { return text.find(part) != std::string::npos; }

std::string messages(const std::vector<SkillProblem>& problems) {
    std::string out;
    for (const SkillProblem& p : problems) out += p.file + ":" + std::to_string(p.line) + ": " + p.message + " | " + p.hint + "\n";
    return out;
}

}  // namespace

TEST_CASE("skills: names follow the Agent Skills rules and a fix is suggested") {
    CHECK(skill_name_problem("pdf-tools").empty());
    CHECK(skill_name_problem("a").empty());
    CHECK(has(skill_name_problem(""), "empty"));
    CHECK(has(skill_name_problem("PDF Tools"), "pdf-tools"));
    CHECK(has(skill_name_problem("-lead"), "hyphen"));
    CHECK(has(skill_name_problem("two--hyphens"), "two hyphens"));
    CHECK(has(skill_name_problem(std::string(65, 'a')), "65 characters"));
    CHECK(skill_name_from("My Shader Notes") == "my-shader-notes");
    CHECK(skill_name_from("---") == "");
}

TEST_CASE("skills: frontmatter is parsed, block scalars and quotes included") {
    auto r = parse_skill_md("---\nname: gdd\ndescription: \"Game design: read first\"\nlicense: MIT\n---\n# Body\ntext\n", "skills/gdd/SKILL.md");
    REQUIRE(r.ok());
    CHECK(r->name == "gdd");
    CHECK(r->description == "Game design: read first");
    CHECK(r->body.find("# Body") != std::string::npos);
    CHECK(r->bodyLine == 6);
    REQUIRE(r->other.size() == 1);
    CHECK(r->other[0].first == "license");

    auto folded = parse_skill_md("---\nname: x\ndescription: >\n  first line\n  second line\n---\nbody", "SKILL.md");
    REQUIRE(folded.ok());
    CHECK(folded->description == "first line second line");

    auto crlf = parse_skill_md("---\r\nname: x\r\ndescription: d\r\n---\r\nbody\r\n", "SKILL.md");
    REQUIRE(crlf.ok());
    CHECK(crlf->name == "x");
}

TEST_CASE("skills: a SKILL.md that cannot be used says where, what and how to fix it") {
    auto none = parse_skill_md("# Just a heading\n", "skills/a/SKILL.md");
    REQUIRE_FALSE(none.ok());
    CHECK(has(none.error().message, "skills/a/SKILL.md:1"));
    CHECK(has(none.error().message, "frontmatter"));
    CHECK_FALSE(none.error().hint.empty());

    auto noName = parse_skill_md("---\ndescription: d\n---\nbody", "skills/a/SKILL.md");
    REQUIRE_FALSE(noName.ok());
    CHECK(has(noName.error().message, "name"));

    auto typo = parse_skill_md("---\nname: a\ndescripton: d\n---\nbody", "skills/a/SKILL.md");
    REQUIRE_FALSE(typo.ok());
    CHECK(has(typo.error().message + typo.error().hint, "description"));  // "did you mean"

    auto bad = parse_skill_md("---\nname: Bad Name\ndescription: d\n---\nbody", "skills/a/SKILL.md");
    REQUIRE_FALSE(bad.ok());
    CHECK(has(bad.error().message + bad.error().hint, "bad-name"));

    auto longDesc = parse_skill_md("---\nname: a\ndescription: " + std::string(1025, 'x') + "\n---\nbody", "skills/a/SKILL.md");
    REQUIRE_FALSE(longDesc.ok());
    CHECK(has(longDesc.error().message, "1025"));

    auto unclosed = parse_skill_md("---\nname: a\ndescription: d\nbody", "skills/a/SKILL.md");
    REQUIRE_FALSE(unclosed.ok());
    CHECK(has(unclosed.error().message, "---"));
}

TEST_CASE("skills: check_skill_folder finds the problems of a folder") {
    testing::TempDir tmp;
    testing::write_all(tmp.path / "good" / "SKILL.md", "---\nname: good\ndescription: d\n---\nbody\n");
    CHECK(check_skill_folder(tmp.sub("good"), "skills/good").empty());

    testing::write_all(tmp.path / "empty" / "skill.md", "x");
    auto missing = check_skill_folder(tmp.sub("empty"), "skills/empty");
    REQUIRE(missing.size() == 1);
    CHECK(has(missing[0].message, "no SKILL.md"));
    CHECK(has(missing[0].hint, "Rename 'skill.md' to SKILL.md"));  // wrong capitalisation

    testing::write_all(tmp.path / "renamed" / "SKILL.md", "---\nname: other\ndescription: d\n---\nbody\n");
    auto mismatch = check_skill_folder(tmp.sub("renamed"), "skills/renamed");
    REQUIRE(mismatch.size() == 1);
    CHECK_FALSE(mismatch[0].warning);
    CHECK(has(mismatch[0].message, "does not match the folder name 'renamed'"));

    testing::write_all(tmp.path / "bare" / "SKILL.md", "---\nname: bare\ndescription: d\n---\n\n");
    auto bare = check_skill_folder(tmp.sub("bare"), "skills/bare");
    REQUIRE(bare.size() == 1);
    CHECK(bare[0].warning);

    testing::write_all(tmp.path / "keys" / "SKILL.md", "---\nname: keys\ndescription: d\nallowed-tool: Read\n---\nbody\n");
    auto keys = check_skill_folder(tmp.sub("keys"), "skills/keys");
    REQUIRE(keys.size() == 1);
    CHECK(keys[0].warning);
    CHECK(has(keys[0].hint, "allowed-tools"));
}

TEST_CASE("skills: the template parses back and quotes a description YAML would misread") {
    for (const char* description : {"", "Plain words.", "Has: a colon", "Starts # a comment", "A \"quoted\" word"}) {
        CAPTURE(description);
        auto r = parse_skill_md(skill_template("my-skill", description), "SKILL.md");
        REQUIRE(r.ok());
        CHECK(r->name == "my-skill");
        if (std::string(description).size()) CHECK(r->description == description);
        else CHECK_FALSE(r->description.empty());
    }
}

TEST_CASE("skills: every engine skill is a valid skill whose folder is its name") {
    const std::vector<std::string> names = engine_skill_names();
    REQUIRE(names.size() >= 11);
    CHECK(std::is_sorted(names.begin(), names.end()));
    for (const char* expected : {"make-art", "make-audio", "review-ready", "custom-shaders", "tile-levels"})
        CHECK(std::find(names.begin(), names.end(), expected) != names.end());
    for (const std::string& name : names) {
        CAPTURE(name);
        const auto files = engine_skill_files(name);
        REQUIRE_FALSE(files.empty());
        CHECK(files.front() == "SKILL.md");
        auto text = engine_skill_read(name);
        REQUIRE(text.has_value());
        auto fm = parse_skill_md(*text, name);
        REQUIRE(fm.ok());
        CHECK(fm->name == name);
        CHECK(fm->description.size() <= 160);  // one line of every prompt
        CHECK_FALSE(trim(fm->body).empty());
    }
    CHECK(engine_skill_files("no-such-skill").empty());
    CHECK_FALSE(engine_skill_read("no-such-skill").has_value());
    CHECK(engine_skill_read("review-ready", "review-md-template.md").has_value());
    CHECK_FALSE(engine_skill_read("review-ready", "../make-art/SKILL.md").has_value());
}

TEST_CASE("validate: a project's skills are checked with teaching errors") {
    testing::TempDir tmp;
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    const std::string dir = tmp.sub("game");
    auto count = [&](const std::string& part, bool errors) {
        ValidateOptions opt;
        opt.checkScenes = false;
        const ValidationReport report = validate_project(dir, opt);
        int n = 0;
        for (const auto& i : errors ? report.errors : report.warnings)
            if (i.to_string().find(part) != std::string::npos) ++n;
        return n;
    };
    CHECK(count("skills/", true) == 0);  // no skills folder is fine

    testing::write_all(tmp.path / "game" / "skills" / "enemies" / "SKILL.md", "---\nname: enemies\ndescription: How enemies work. Read before adding one.\n---\nbody\n");
    CHECK(count("skills/", true) == 0);
    CHECK(count("skills/", false) == 0);

    testing::write_all(tmp.path / "game" / "skills" / "broken" / "SKILL.md", "no frontmatter\n");
    CHECK(count("skills/broken/SKILL.md:1", true) == 1);

    testing::write_all(tmp.path / "game" / "skills" / "loose" / "notes.md", "x");
    CHECK(count("skills/loose", true) == 1);

    testing::write_all(tmp.path / "game" / "skills" / "SKILL.md", "---\nname: x\ndescription: d\n---\nb");
    CHECK(count("outside a skill folder", true) == 1);

    // A skill folder named by the project's extensions file is checked too.
    testing::write_all(tmp.path / "game" / "guides" / "tone" / "SKILL.md", "---\nname: wrong\ndescription: d\n---\nbody\n");
    testing::write_all(tmp.path / "game" / ".factoria" / "extensions.json", R"({"skills":{"guides":{"path":"guides"}}})");
    CHECK(count("does not match the folder name 'tone'", true) == 1);
}
