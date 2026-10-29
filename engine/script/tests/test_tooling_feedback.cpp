// M38.3: storage.list / storage.clear, script.eval {module} seeing edited files, and the mouse reset between tests.
#include <doctest.h>

#include <chrono>

#include "test_host.h"

using namespace fa;
using namespace fa::test;

namespace {

Json row(const Json& listing, const std::string& key) {
    for (const Json& k : listing["keys"])
        if (k["key"] == key) return k;
    return Json();
}

}  // namespace

TEST_CASE("storage: storage_list shows memory and disk keys, storage_clear removes them from both") {
    TestHost h("storage_list");
    REQUIRE(h.start());
    h.scripts.set_storage_mode(StorageMode::Persistent);
    REQUIRE(h.scripts.eval("storage.set('slot', {a: 1}); storage.set('run.current', {floor: 3})").ok());
    // A key file the editor left, which this session never read (the engine loaded the folder before it existed).
    write_file(h.root, "save/storage/old%2Ekey.json", R"({"key": "old.key", "value": 7})");
    write_file(h.root, "save/storage/broken.json", "{not json");

    Json l = h.scripts.storage_list();
    CHECK(l["mode"] == "persistent");
    CHECK(row(l, "slot")["inMemory"] == true);
    CHECK(row(l, "slot")["onDisk"] == true);
    CHECK(row(l, "old.key")["onDisk"] == true);
    CHECK(row(l, "old.key")["inMemory"] == false);
    CHECK(l["damaged"].size() == 1);

    Json r = h.scripts.storage_clear("run.current", false);
    CHECK(r["removed"] == Json::array({"run.current"}));
    CHECK_FALSE(std::filesystem::exists(h.root / "save" / "storage" / "run%2Ecurrent.json"));
    CHECK(h.scripts.eval("storage.get('run.current') === undefined")->get<bool>());
    CHECK(h.scripts.eval("storage.get('slot').a")->get<int>() == 1);

    // A key that is only on disk goes too.
    r = h.scripts.storage_clear("old.key", false);
    CHECK(r["removed"] == Json::array({"old.key"}));
    CHECK_FALSE(std::filesystem::exists(h.root / "save" / "storage" / "old%2Ekey.json"));

    r = h.scripts.storage_clear("", true);
    CHECK(row(h.scripts.storage_list(), "slot").is_null());
    CHECK(h.scripts.storage_list()["damaged"].empty());
    CHECK(h.scripts.eval("storage.keys().length")->get<int>() == 0);
}

TEST_CASE("storage: in memory mode storage_list and storage_clear still reach the save folder") {
    TestHost h("storage_mem");
    REQUIRE(h.start());
    h.scripts.set_storage_mode(StorageMode::Memory);
    write_file(h.root, "save/storage/run%2Ecurrent.json", R"({"key": "run.current", "value": 1})");
    Json l = h.scripts.storage_list();
    CHECK(l["mode"] == "memory");
    CHECK(row(l, "run.current")["onDisk"] == true);
    CHECK(row(l, "run.current")["inMemory"] == false);
    h.scripts.storage_clear("run.current", false);
    CHECK_FALSE(std::filesystem::exists(h.root / "save" / "storage" / "run%2Ecurrent.json"));
}

TEST_CASE("script.eval module: an edited module is re-imported, a new tool is registered") {
    TestHost h("reload_changed");
    h.file("scripts/rules.js", "export function v() { return 1; }\n");
    h.file("scripts/user.js", "import { v } from './rules.js';\nexport function w() { return v() * 10; }\n");
    REQUIRE(h.start());
    CHECK(h.scripts.eval("import('scripts/user.js').then((m) => m.w())")->get<int>() == 10);
    CHECK(h.scripts.reload_changed_modules().empty());

    h.file("scripts/rules.js", "export function v() { return 2; }\n");
    const auto path = h.root / "scripts" / "rules.js";
    std::filesystem::last_write_time(path, std::filesystem::last_write_time(path) + std::chrono::seconds(5));
    auto changed = h.scripts.reload_changed_modules();
    REQUIRE(changed.size() == 1);
    CHECK(changed[0] == "scripts/rules.js");
    CHECK(h.scripts.eval("import('scripts/user.js').then((m) => m.w())")->get<int>() == 20);
    CHECK(h.scripts.reload_changed_modules().empty());  // seen once, not again
}

TEST_CASE("tests: the mouse starts every test at (0, 0), whatever the session left") {
    TestHost h("mouse_reset");
    h.file("tests/a.test.js", R"JS(
import { test, expect, game } from "factoria:test";
import { input } from "factoria";
test("moves the mouse and holds a button", () => {
  game.mouseMove([300, 200]);
  game.mouseDown();
  game.wheel(2);
  expect(input.mouse.position.x).toBe(300);
});
test("the next test starts clean", () => {
  expect(input.mouse.position.x).toBe(0);
  expect(input.mouse.position.y).toBe(0);
  expect(input.mouse.down("left")).toBe(false);
  expect(input.mouse.wheel).toBe(0);
});
)JS");
    h.file("tests/b.test.js", R"JS(
import { test, expect } from "factoria:test";
import { input } from "factoria";
test("a later file also starts clean", () => {
  expect(input.mouse.position.x).toBe(0);
});
)JS");
    REQUIRE(h.start());
    h.in.on_mouse_move({640, 360});  // what an earlier game.click left in the live session
    TestReport rep = h.scripts.run_tests({"tests/a.test.js", "tests/b.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 3);
    CHECK(h.in.mouse_position().x == 0);  // the run leaves the session input clean too
}
