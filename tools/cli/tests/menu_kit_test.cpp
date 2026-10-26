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

TEST_CASE("project.add_menu_kit: the ageGate part comes alone with its test, and the main menu does not bring it") {
    const stdfs::path oldRoot = fa::fs::project_root();
    const std::string dir = new_game("agegate");
    const fa::Json r = add(dir, {"ageGate"});
    CAPTURE(r.dump(2));
    CHECK(r["parts"] == fa::Json::parse(R"(["core","ageGate"])"));
    CHECK(has(r["added"], "prefabs/ui/age_gate.prefab.json"));
    CHECK(has(r["added"], "scripts/ui/age_gate.js"));
    CHECK(has(r["added"], "tests/age_gate.test.js"));
    CHECK_FALSE(stdfs::exists(stdfs::path(dir) / "scenes" / "menu.scene.json"));
    CHECK_FALSE(stdfs::exists(stdfs::path(dir) / "prefabs" / "ui" / "options.prefab.json"));
    for (const char* language : {"en"}) {
        const fa::Json en = read_json(stdfs::path(dir) / "locales" / (std::string(language) + ".json"));
        CHECK(en.contains("ageGate"));
        CHECK(en["ageGate"].contains("skip"));
        CHECK_FALSE(en.contains("options"));
    }
    bool mentionsAudience = false;
    for (const fa::Json& step : r["nextSteps"]) mentionsAudience = mentionsAudience || step.get<std::string>().find("\"mixed\"") != std::string::npos;
    CHECK(mentionsAudience);

    // Its own test passes in a game that has nothing else of the kit.
    fa::cli::SessionOptions so;
    so.gfx = fa::cli::Gfx::None;
    auto session = fa::cli::Session::open(dir, so);
    fa::TestReport rep = fa::cli::run_project_tests(session->engine(), "");
    CHECK_MESSAGE(rep.ok(), rep.summary());
    CHECK(rep.passed >= 6);
    session.reset();
    fa::fs::set_project_root(oldRoot);

    // The main menu does not need it: the age gate is only there when asked for.
    const std::string dir2 = new_game("mainmenu");
    CHECK_FALSE(has(add(dir2, {"main-menu"})["parts"], "ageGate"));
}

TEST_CASE("project.add_menu_kit: the analyticsConsent part asks once, and the Options switch and the main menu follow the game's analytics section") {
    const stdfs::path oldRoot = fa::fs::project_root();
    const std::string dir = new_game("analytics");
    const fa::Json r = add(dir, {"analyticsConsent"});
    CAPTURE(r.dump(2));
    CHECK(r["parts"] == fa::Json::parse(R"(["core","analyticsConsent"])"));
    CHECK(has(r["added"], "prefabs/ui/analytics_consent.prefab.json"));
    CHECK(has(r["added"], "scripts/ui/analytics_consent.js"));
    CHECK(has(r["added"], "tests/analytics_consent.test.js"));
    CHECK(read_json(stdfs::path(dir) / "locales" / "en.json")["analyticsConsent"].contains("deny"));
    bool mentionsSection = false;
    for (const fa::Json& step : r["nextSteps"]) mentionsSection = mentionsSection || step.get<std::string>().find("\"analytics\" section") != std::string::npos;
    CHECK(mentionsSection);

    // Without an "analytics" section there is nothing to ask: its test passes and says so.
    {
        fa::cli::SessionOptions so;
        so.gfx = fa::cli::Gfx::None;
        auto session = fa::cli::Session::open(dir, so);
        fa::TestReport rep = fa::cli::run_project_tests(session->engine(), "");
        CHECK_MESSAGE(rep.ok(), rep.summary());
        CHECK(rep.passed == 4);
        session.reset();
        fa::fs::set_project_root(oldRoot);
    }

    // With the section (and its host declared) the question is real: the same test now checks the answers, and the game validates.
    fa::Json project = read_json(stdfs::path(dir) / "factoria.json");
    project["network"] = fa::Json::parse(R"({"hosts": ["stats.example.com"], "purpose": "Anonymous usage counts the player agreed to."})");
    project["analytics"] = fa::Json::parse(R"({"endpoint": "https://stats.example.com/events"})");
    {
        std::ofstream out(stdfs::path(dir) / "factoria.json", std::ios::binary);
        out << project.dump(2) << "\n";
    }
    fa::cli::SessionOptions so;
    so.gfx = fa::cli::Gfx::None;
    auto session = fa::cli::Session::open(dir, so);
    const fa::Json v = fa::cli::run_command_json(session->registry(), fa::Json::parse(R"({"command":"project.validate","args":{}})"));
    REQUIRE(v["ok"] == true);
    CAPTURE(v["result"].dump(2));
    CHECK(v["result"]["errors"].empty());
    fa::TestReport rep = fa::cli::run_project_tests(session->engine(), "");
    CHECK_MESSAGE(rep.ok(), rep.summary());
    CHECK(rep.passed == 4);
    session.reset();
    fa::fs::set_project_root(oldRoot);
}

namespace {

// Opens the game as `factoria validate` and `factoria test` do: no validation error, every test passes.
void validate_and_test(const std::string& dir, int minPassed) {
    const stdfs::path oldRoot = fa::fs::project_root();
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
    CHECK(rep.passed >= minPassed);
    CHECK(rep.failed == 0);
    session.reset();
    fa::fs::set_project_root(oldRoot);
}

bool has_entity(const fa::Json& node, const std::string& id) {
    if (node.is_object() && node.contains("id") && node["id"] == id) return true;
    for (const char* key : {"entities", "children"})
        if (node.is_object() && node.contains(key))
            for (const fa::Json& e : node[key])
                if (has_entity(e, id)) return true;
    return false;
}

}  // namespace

TEST_CASE("project.add_menu_kit: a main menu without the shop and the age gate validates and runs") {
    const std::string dir = new_game("noshop");
    const fa::Json r = add(dir, {"main-menu"});
    CAPTURE(r.dump(2));
    CHECK(r["parts"] == fa::Json::parse(R"(["core","options","credits","main-menu"])"));
    CHECK_FALSE(stdfs::exists(stdfs::path(dir) / "scripts" / "ui" / "shop.js"));
    CHECK_FALSE(stdfs::exists(stdfs::path(dir) / "scripts" / "ui" / "age_gate.js"));
    CHECK_FALSE(stdfs::exists(stdfs::path(dir) / "prefabs" / "ui" / "age_gate.prefab.json"));
    const fa::Json scene = read_json(stdfs::path(dir) / "scenes" / "menu.scene.json");
    CHECK(has_entity(scene, "play"));
    CHECK(has_entity(scene, "options"));
    CHECK(has_entity(scene, "credits"));
    CHECK_FALSE(has_entity(scene, "shop"));
    CHECK_FALSE(has_entity(scene, "shop_button"));
    CHECK_FALSE(has_entity(scene, "age_gate"));
    const std::string script = read_text(stdfs::path(dir) / "scripts" / "main_menu.js");
    CHECK(script.find("age_gate") == std::string::npos);
    CHECK(script.find("openAgeGate") == std::string::npos);
    CHECK(script.find("shop_button") == std::string::npos);
    CHECK(script.find("@kit") == std::string::npos);
    CHECK(script.find("ui.on(\"click\", \"quit\"") != std::string::npos);
    // The shop is not in the game's strings either, and running the command again changes nothing.
    CHECK_FALSE(read_json(stdfs::path(dir) / "locales" / "en.json").contains("shop"));
    const fa::Json again = add(dir, {"main-menu"});
    CHECK(again["added"].empty());
    CHECK(again["skipped"].empty());
    validate_and_test(dir, 1);

    // Asked for, the shop comes with its button, panel and script; the age gate still stays out.
    const std::string dir2 = new_game("withshop");
    const fa::Json s = add(dir2, {"main-menu", "shop"});
    CHECK(has(s["parts"], "shop"));
    CHECK_FALSE(has(s["parts"], "ageGate"));
    const fa::Json scene2 = read_json(stdfs::path(dir2) / "scenes" / "menu.scene.json");
    CHECK(has_entity(scene2, "shop_button"));
    CHECK(has_entity(scene2, "shop"));
    CHECK_FALSE(has_entity(scene2, "age_gate"));
    const std::string script2 = read_text(stdfs::path(dir2) / "scripts" / "main_menu.js");
    CHECK(script2.find("shop_button") != std::string::npos);
    CHECK(script2.find("openAgeGate") == std::string::npos);
    CHECK(script2.find("@kit") == std::string::npos);
    validate_and_test(dir2, 1);

    // Every part (the default) keeps both, with the markers gone.
    const std::string dir3 = new_game("all");
    add(dir3);
    const std::string full = read_text(stdfs::path(dir3) / "scripts" / "main_menu.js");
    CHECK(full.find("import { openAgeGate } from \"./ui/age_gate.js\";\n") != std::string::npos);
    CHECK(full.find("@kit") == std::string::npos);
}

TEST_CASE("project.add_menu_kit: the Controls tab lists the game's own actions and rebinds them") {
    const std::string dir = new_game("controls");
    fa::Json project = read_json(stdfs::path(dir) / "factoria.json");
    project["input"]["actions"]["dig"] = fa::Json::parse(R"(["Z", "GamepadX"])");
    project["input"]["actions"]["jump"] = fa::Json::parse(R"(["Space"])");
    project["input"]["actions"]["place"] = fa::Json::parse(R"(["X", "GamepadY"])");
    write_text(stdfs::path(dir) / "factoria.json", project.dump(2));
    add(dir, {"main-menu"});
    write_text(stdfs::path(dir) / "tests" / "controls.test.js", R"(import { test, expect, game } from "factoria:test";
import { ui, input, storage, scene } from "factoria";
const pad = game.gamepad(0);
test("the Controls tab lists the game's actions, not the ui_* ones, and rebinds them", () => {
  scene.load("scenes/menu.scene.json");
  game.step(2);
  pad.tap("DpadDown");
  pad.tap("A"); // Options
  pad.tap("DpadRight");
  pad.tap("DpadRight");
  pad.tap("A"); // the Controls tab
  expect(game.find("bind_dig")).toBeTruthy();
  expect(game.find("bind_place")).toBeTruthy();
  expect(game.find("bind_ui_up")).toBeFalsy();
  expect(game.find("bind_dig").get("Button").text).toContain("dig"); // no options.action.dig string: the action's name
  expect(game.find("bind_dig").get("Button").text).not.toContain("options.action");
  expect(game.find("bind_jump").get("Button").text).toContain("Jump"); // the kit's own string
  ui.focus(game.find("bind_dig"));
  pad.tap("A");
  pad.tap("B"); // captured as the new binding
  expect(input.bindings("dig")[0]).toBe("GamepadB");
  expect(input.bindings("dig")).toContain("Z"); // the keyboard's binding stays
  expect(storage.get("settings").bindings.dig[0]).toBe("GamepadB");
  expect(input.bindings("place")).toEqual(["X", "GamepadY"]);
});
)");
    validate_and_test(dir, 2);

    // Options.actions picks and orders the rows: the prefab's Script props.
    const std::string dir2 = new_game("controlsprops");
    fa::Json project2 = read_json(stdfs::path(dir2) / "factoria.json");
    project2["input"]["actions"]["dig"] = fa::Json::parse(R"(["Z"])");
    project2["input"]["actions"]["jump"] = fa::Json::parse(R"(["Space"])");
    project2["input"]["actions"]["place"] = fa::Json::parse(R"(["X"])");
    write_text(stdfs::path(dir2) / "factoria.json", project2.dump(2));
    add(dir2, {"main-menu"});
    const stdfs::path prefab = stdfs::path(dir2) / "prefabs" / "ui" / "options.prefab.json";
    fa::Json options = read_json(prefab);
    options["entity"]["components"]["Script"]["props"] = fa::Json::parse(R"({"actions": ["place", "nothing", "jump"]})");
    write_text(prefab, options.dump(2));
    write_text(stdfs::path(dir2) / "tests" / "controls.test.js", R"(import { test, expect, game } from "factoria:test";
import { scene } from "factoria";
const pad = game.gamepad(0);
test("Options.actions picks and orders the rows", () => {
  scene.load("scenes/menu.scene.json");
  game.step(2);
  pad.tap("DpadDown");
  pad.tap("A");
  pad.tap("DpadRight");
  pad.tap("DpadRight");
  pad.tap("A");
  expect(game.find("bind_place")).toBeTruthy();
  expect(game.find("bind_jump")).toBeTruthy();
  expect(game.find("bind_dig")).toBeFalsy();
  expect(game.find("bind_nothing")).toBeFalsy();
  expect(game.find("bindings").children.map((e) => e.id)).toEqual(["bind_place", "bind_jump"]);
});
)");
    validate_and_test(dir2, 2);
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
