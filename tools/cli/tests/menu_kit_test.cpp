// project.add_menu_kit (templates/menus/, docs/MENUS.md): the kit added to a new project validates and passes its own test,
// adding it twice changes nothing, one part brings what it needs, a file the game edited is not touched without `overwrite`,
// the strings merge into the game's locales without replacing a key, an unknown part teaches. And the menus fixture, which
// ctest runs, holds exactly the kit's files (one source of truth: the template).
#include <doctest.h>

#include <filesystem>
#include <fstream>
#include <sstream>
#include <string>

#include "common.h"  // tools/cli/src: Session, run_project_tests
#include "fa/core/fs.h"
#include "fa/core/json.h"
#include "fa/tooling/menu_kit.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"
#include "fa_test_paths.h"  // FA_REPO_ROOT

namespace stdfs = std::filesystem;

namespace {

std::string read_text(const stdfs::path& p) {
    std::ifstream f(p, std::ios::binary);
    std::string s((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
    std::erase(s, '\r');
    return s;
}

void write_text(const stdfs::path& p, const std::string& s) {
    stdfs::create_directories(p.parent_path());
    std::ofstream(p, std::ios::binary) << s;
}

fa::Json read_json(const stdfs::path& p) {
    auto j = fa::Json::parse(read_text(p), nullptr, false);
    REQUIRE_FALSE(j.is_discarded());
    return j;
}

std::string new_game(const char* tag) {
    const stdfs::path root = fa::fs::make_temp_dir(std::string("fa_menu_kit_") + tag);
    fa::ScaffoldOptions opt;
    opt.writeTypings = false;
    const std::string dir = (root / "game").string();
    auto made = fa::create_project(dir, "2d-empty", opt);
    REQUIRE_MESSAGE(made.ok(), made.error().to_string());
    return dir;
}

fa::Json add(const std::string& dir, std::vector<std::string> parts = {}, bool overwrite = false) {
    fa::MenuKitOptions o;
    o.projectDir = dir;
    o.parts = std::move(parts);
    o.overwrite = overwrite;
    auto r = fa::add_menu_kit(o);
    REQUIRE_MESSAGE(r.ok(), r.error().to_string());
    return *r;
}

bool has(const fa::Json& list, const std::string& value) {
    for (const fa::Json& v : list)
        if (v == value) return true;
    return false;
}

bool skipped_file(const fa::Json& skipped, const std::string& file) {
    for (const fa::Json& s : skipped)
        if (s["file"] == file) return true;
    return false;
}

}  // namespace

TEST_CASE("project.add_menu_kit: a new project gets the whole kit, validates and passes the kit's test; a second run changes nothing") {
    const stdfs::path oldRoot = fa::fs::project_root();
    const std::string dir = new_game("all");
    const fa::Json first = add(dir);
    CAPTURE(first.dump(2));
    CHECK(first["skipped"].empty());
    CHECK(first["unchanged"].empty());
    CHECK(has(first["added"], "scenes/menu.scene.json"));
    CHECK(has(first["added"], "scripts/ui/keyboard.js"));
    CHECK(has(first["added"], "tests/recipe.test.js"));
    REQUIRE(first["locales"].size() == 1);
    CHECK(first["locales"][0]["file"] == "locales/en.json");
    CHECK(first["locales"][0]["created"] == true);
    CHECK(first["locales"][0]["merged"].size() > 50);
    // factoria.json got what the kit needs: a localization section and the pause action.
    const fa::Json project = read_json(stdfs::path(dir) / "factoria.json");
    CHECK(project["localization"]["languages"][0] == "en");
    CHECK(project["input"]["actions"].contains("pause"));

    // Everything on disk, then a second run.
    std::map<std::string, std::string> before;
    for (const auto& e : stdfs::recursive_directory_iterator(dir))
        if (e.is_regular_file()) before[stdfs::relative(e.path(), dir).generic_string()] = read_text(e.path());
    const fa::Json second = add(dir);
    CAPTURE(second.dump(2));
    CHECK(second["added"].empty());
    CHECK(second["overwritten"].empty());
    CHECK(second["skipped"].empty());
    CHECK(second["unchanged"].size() == first["added"].size());
    CHECK(second["locales"][0]["merged"].empty());
    CHECK(second["locales"][0]["created"] == false);
    CHECK(second["settings"].empty());
    std::map<std::string, std::string> after;
    for (const auto& e : stdfs::recursive_directory_iterator(dir))
        if (e.is_regular_file()) after[stdfs::relative(e.path(), dir).generic_string()] = read_text(e.path());
    CHECK(before == after);

    // The game validates (no errors, no warnings from the kit) and the kit's own test passes.
    fa::cli::SessionOptions so;
    so.gfx = fa::cli::Gfx::None;
    auto session = fa::cli::Session::open(dir, so);
    const fa::Json v = fa::cli::run_command_json(session->registry(), fa::Json::parse(R"({"command":"project.validate","args":{}})"));
    REQUIRE(v["ok"] == true);
    CAPTURE(v["result"].dump(2));
    CHECK(v["result"]["ok"] == true);
    CHECK(v["result"]["errors"].empty());
    fa::TestReport rep = fa::cli::run_project_tests(session->engine(), "");
    CHECK_MESSAGE(rep.ok(), rep.summary());
    CHECK(rep.passed >= 1);
    CHECK(rep.failed == 0);
    session.reset();
    fa::fs::set_project_root(oldRoot);
}

TEST_CASE("project.add_menu_kit: one part brings what it needs, and nothing else") {
    const std::string dir = new_game("one");
    const fa::Json r = add(dir, {"pause"});
    CAPTURE(r.dump(2));
    CHECK(r["parts"] == fa::Json::parse(R"(["core","options","pause"])"));
    CHECK(r["requiredBy"].contains("core"));
    CHECK(r["requiredBy"].contains("options"));
    CHECK(has(r["added"], "prefabs/ui/pause.prefab.json"));
    CHECK(has(r["added"], "scripts/pause_menu.js"));
    CHECK(has(r["added"], "scripts/settings.js"));
    CHECK_FALSE(stdfs::exists(stdfs::path(dir) / "scenes" / "menu.scene.json"));
    CHECK_FALSE(stdfs::exists(stdfs::path(dir) / "scripts" / "ui" / "shop.js"));
    const fa::Json en = read_json(stdfs::path(dir) / "locales" / "en.json");
    CHECK(en.contains("pause"));
    CHECK(en.contains("options"));
    CHECK_FALSE(en.contains("shop"));
    CHECK_FALSE(en.contains("keyboard"));

    // A part that needs nothing: only its own files and keys.
    const std::string dir2 = new_game("loading");
    const fa::Json l = add(dir2, {"loading"});
    CHECK(l["parts"] == fa::Json::parse(R"(["loading"])"));
    CHECK(l["requiredBy"].empty());
    CHECK(l["added"].size() == 2);
    CHECK(read_json(stdfs::path(dir2) / "locales" / "en.json").size() == 2);  // $name and loading
}

TEST_CASE("project.add_menu_kit: a file the game edited stays unless overwrite is true; keys the game has are never replaced") {
    const std::string dir = new_game("edit");
    add(dir, {"credits"});
    const stdfs::path script = stdfs::path(dir) / "scripts" / "ui" / "credits.js";
    const std::string kit = read_text(script);
    write_text(script, kit + "// my change\n");
    // The game's own string for one of the kit's keys, and one more language the kit has no texts for.
    fa::Json en = read_json(stdfs::path(dir) / "locales" / "en.json");
    en["credits"]["madeWith"] = "Built with love";
    write_text(stdfs::path(dir) / "locales" / "en.json", en.dump(2));
    fa::Json project = read_json(stdfs::path(dir) / "factoria.json");
    project["localization"]["languages"] = fa::Json::array({"en", "de"});
    write_text(stdfs::path(dir) / "factoria.json", project.dump(2));
    write_text(stdfs::path(dir) / "locales" / "de.json", R"({"$name":"Deutsch","menu":{"play":"Spielen"}})");

    const fa::Json r = add(dir, {"credits"});
    CAPTURE(r.dump(2));
    CHECK(skipped_file(r["skipped"], "scripts/ui/credits.js"));
    CHECK(read_text(script) == kit + "// my change\n");  // not touched
    CHECK(r["added"].empty());
    CHECK(read_json(stdfs::path(dir) / "locales" / "en.json")["credits"]["madeWith"] == "Built with love");
    const fa::Json de = read_json(stdfs::path(dir) / "locales" / "de.json");
    CHECK(de["menu"]["play"] == "Spielen");  // the game's key
    CHECK(de["menu"]["back"] == "Back");     // the kit's key, in English: no German text in the kit
    CHECK(de["credits"]["madeWith"] == "Made with FactorIA");

    const fa::Json o = add(dir, {"credits"}, true);
    CHECK(has(o["overwritten"], "scripts/ui/credits.js"));
    CHECK(read_text(script) == kit);
    CHECK(read_json(stdfs::path(dir) / "locales" / "en.json")["credits"]["madeWith"] == "Built with love");  // still the game's
}

TEST_CASE("project.add_menu_kit: an unknown part says which parts exist; the command is registered with documented arguments") {
    const std::string dir = new_game("unknown");
    fa::cli::SessionOptions so;
    so.gfx = fa::cli::Gfx::None;
    const stdfs::path oldRoot = fa::fs::project_root();
    auto session = fa::cli::Session::open(dir, so);
    const fa::Json bad = fa::cli::run_command_json(session->registry(), fa::Json::parse(R"({"command":"project.add_menu_kit","args":{"parts":["pauze"]}})"));
    CHECK(bad["ok"] == false);
    const std::string message = bad["error"]["message"].get<std::string>();
    CHECK(message.find("pauze") != std::string::npos);
    CHECK(message.find("pause") != std::string::npos);  // did you mean
    CHECK(bad["error"]["hint"].get<std::string>().find("main-menu") != std::string::npos);
    CHECK_FALSE(stdfs::exists(stdfs::path(dir) / "scripts" / "settings.js"));  // nothing was written
    const fa::Json typo = fa::cli::run_command_json(session->registry(), fa::Json::parse(R"({"command":"project.add_menu_kit","args":{"overwite":true}})"));
    CHECK(typo["ok"] == false);
    CHECK(typo["error"]["message"].get<std::string>().find("overwrite") != std::string::npos);
    const fa::Json good = fa::cli::run_command_json(session->registry(), fa::Json::parse(R"({"command":"project.add_menu_kit","args":{"parts":["loading"]}})"));
    CHECK(good["ok"] == true);
    CHECK(has(good["result"]["added"], "scripts/loading.js"));
    session.reset();
    fa::fs::set_project_root(oldRoot);
    // The kit is not a project template.
    for (const auto& t : fa::list_templates()) CHECK(t.name != "menus");
}

// One source of truth: templates/menus/ is the kit; tools/cli/tests/fixtures/menus (the project ctest runs and docs/MENUS.md
// quotes) holds a copy of every kit file that this test keeps identical, plus what only the fixture has.
TEST_CASE("the menus fixture holds exactly the kit's files") {
    const stdfs::path repo = FA_REPO_ROOT;
    const stdfs::path kit = repo / "templates" / "menus";
    const stdfs::path fixture = repo / "tools" / "cli" / "tests" / "fixtures" / "menus";
    const fa::Json manifest = read_json(kit / "kit.json");
    int files = 0;
    for (const fa::Json& part : manifest["parts"])
        for (const fa::Json& f : part["files"]) {
            const std::string rel = f.get<std::string>();
            CAPTURE(rel);
            REQUIRE(stdfs::exists(kit / rel));
            CHECK(read_text(kit / rel) == read_text(fixture / rel));
            ++files;
        }
    CHECK(files > 15);
    // No kit file outside kit.json, and the tables: every key of the kit's is in the fixture's with the same text.
    for (const auto& e : stdfs::recursive_directory_iterator(kit)) {
        if (!e.is_regular_file()) continue;
        const std::string rel = stdfs::relative(e.path(), kit).generic_string();
        if (rel == "kit.json" || rel.rfind("locales/", 0) == 0) continue;
        bool listed = false;
        for (const fa::Json& part : manifest["parts"])
            for (const fa::Json& f : part["files"]) listed = listed || f == rel;
        CHECK_MESSAGE(listed, rel << " is in templates/menus/ but in no part of kit.json");
    }
    for (const char* language : {"en", "es", "ar"}) {
        const fa::Json k = read_json(kit / "locales" / (std::string(language) + ".json"));
        const fa::Json f = read_json(fixture / "locales" / (std::string(language) + ".json"));
        for (auto it = k.begin(); it != k.end(); ++it) {
            CAPTURE(language);
            CAPTURE(it.key());
            REQUIRE(f.contains(it.key()));
            CHECK(f[it.key()] == *it);
        }
    }
}
