// vfx.create and vfx.edit: effect documents as project files (docs/PARTICLES.md, "Effect documents"). The format and the timeline are tested in
// fa_scene (engine/scene/tests/test_vfx.cpp); here: the files, the edit operations, and that a bad edit changes nothing on disk.
#include <doctest.h>

#include "asset_test_helpers.h"
#include "fa/scene/vfx.h"

using namespace fa;
using namespace fa::testing;

namespace {

Json read_json_file(const AssetsProject& p, const std::string& rel) { return Json::parse(read_all(p.file(rel))); }

}  // namespace

TEST_CASE("vfx.create: writes a starter effect that loads, and refuses to overwrite") {
    AssetsProject p;
    const Json r = p.ok("vfx.create", {{"path", "assets/vfx/hit.vfx.json"}});
    CHECK(r["effect"] == "assets/vfx/hit.vfx.json");
    CHECK(p.exists("assets/vfx/hit.vfx.json"));
    auto doc = parse_vfx(read_json_file(p, "assets/vfx/hit.vfx.json"), "hit.vfx.json", nullptr);
    REQUIRE_MESSAGE(doc.ok(), (doc.ok() ? "" : doc.error().message));
    CHECK((*doc)->parts.size() == 1);
    CHECK((*doc)->parts[0].kind == VfxPartKind::Emitter);

    const std::string before = read_all(p.file("assets/vfx/hit.vfx.json"));
    CommandResult again = p.call("vfx.create", {{"path", "assets/vfx/hit.vfx.json"}});
    CHECK_FALSE(again.ok);
    CHECK(read_all(p.file("assets/vfx/hit.vfx.json")) == before);
    CommandResult wrong = p.call("vfx.create", {{"path", "assets/vfx/hit.json"}});
    CHECK_FALSE(wrong.ok);
    CHECK(p.ok("vfx.create", {{"path", "assets/vfx/hit.vfx.json"}, {"overwrite", true}})["effect"] == "assets/vfx/hit.vfx.json");
}

TEST_CASE("vfx.edit: set, add, move and remove change the file, and a change that breaks the effect writes nothing") {
    AssetsProject p;
    p.ok("vfx.create", {{"path", "assets/fx/a.vfx.json"}});
    const std::string rel = "assets/fx/a.vfx.json";

    SUBCASE("set a field, add a part, move it, remove it") {
        const Json s = p.ok("vfx.edit", {{"path", rel}, {"op", "set"}, {"pointer", "/parts/0/emitter/burst"}, {"value", 33}});
        CHECK(s["parts"] == 1);
        CHECK(read_json_file(p, rel)["parts"][0]["emitter"]["burst"] == 33);
        p.ok("vfx.edit", {{"path", rel}, {"op", "add"}, {"pointer", "/parts"},
                          {"value", {{"type", "light"}, {"name", "flash"}, {"at", 0.1}}}});
        CHECK(read_json_file(p, rel)["parts"].size() == 2);
        CHECK(read_json_file(p, rel)["parts"][1]["name"] == "flash");
        p.ok("vfx.edit", {{"path", rel}, {"op", "move"}, {"pointer", "/parts"}, {"index", 1}, {"to", 0}});
        CHECK(read_json_file(p, rel)["parts"][0]["name"] == "flash");
        p.ok("vfx.edit", {{"path", rel}, {"op", "remove"}, {"pointer", "/parts/0"}});
        CHECK(read_json_file(p, rel)["parts"].size() == 1);
    }
    SUBCASE("an edit that makes the effect invalid is refused with the errors and the file is untouched") {
        const std::string before = read_all(p.file(rel));
        CommandResult r = p.call("vfx.edit", {{"path", rel}, {"op", "set"}, {"pointer", "/parts/0/at"}, {"value", "soon"}});
        CHECK_FALSE(r.ok);
        CHECK(r.error.dump().find("/parts/0/at") != std::string::npos);
        CHECK(read_all(p.file(rel)) == before);
        r = p.call("vfx.edit", {{"path", rel}, {"op", "add"}, {"pointer", "/parts"},
                                {"value", {{"type", "command"}, {"command", "fs.delete"}, {"args", Json::object()}}}});
        CHECK_FALSE(r.ok);
        CHECK(read_all(p.file(rel)) == before);
    }
    SUBCASE("a pointer that does not exist and an unknown op teach") {
        CommandResult r = p.call("vfx.edit", {{"path", rel}, {"op", "remove"}, {"pointer", "/parts/9"}});
        CHECK_FALSE(r.ok);
        r = p.call("vfx.edit", {{"path", rel}, {"op", "swap"}, {"pointer", "/parts"}});
        CHECK_FALSE(r.ok);
        CHECK(r.error.dump().find("set") != std::string::npos);
    }
}
