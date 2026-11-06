// project.validate and effect documents (*.vfx.json, docs/PARTICLES.md "Effect documents"): every problem at its JSON pointer, a sound clip
// that is not in the project, warnings that do not fail the project.
#include <doctest.h>

#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"
#include "test_helpers.h"

using namespace fa;

namespace {

struct Project {
    testing::TempDir tmp;
    std::string dir;
    Project() {
        REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
        dir = tmp.sub("game");
    }
    void effect(const std::string& rel, const std::string& text) const { REQUIRE(fs::write_text(dir + "/" + rel, text).ok()); }
};

const ValidationIssue* find(const std::vector<ValidationIssue>& list, const std::string& file, const std::string& pointer) {
    for (const auto& i : list)
        if (i.file == file && i.pointer == pointer) return &i;
    return nullptr;
}

}  // namespace

TEST_CASE("validate: a good effect adds nothing, and a missing clip, a command that is not allowed and a typo are errors at their pointer") {
    Project p;
    p.effect("assets/sfx/hit.wav", "RIFF");
    p.effect("assets/vfx/good.vfx.json", R"({"format":"factoria.vfx/1","parts":[
        {"type":"emitter","emitter":{"burst":6}},{"type":"sound","clip":"assets/sfx/hit.wav"},{"type":"command","command":"feel.shake"}]})");
    p.effect("assets/vfx/bad.vfx.json", R"({"format":"factoria.vfx/1","durration":1,"parts":[
        {"type":"sound","clip":"assets/sfx/absent.wav"},{"type":"command","command":"fs.delete"}]})");
    const ValidationReport r = validate_project(p.dir);
    CHECK_FALSE(r.ok);
    for (const auto& e : r.errors) CHECK_MESSAGE(e.file != "assets/vfx/good.vfx.json", e.to_string());
    const ValidationIssue* typo = find(r.errors, "assets/vfx/bad.vfx.json", "/durration");
    REQUIRE(typo);
    CHECK(typo->hint.find("duration") != std::string::npos);
    CHECK(find(r.errors, "assets/vfx/bad.vfx.json", "/parts/1/command"));
}

TEST_CASE("validate: a missing sound clip of an effect is an error with the fix") {
    Project p;
    p.effect("assets/vfx/gone.vfx.json", R"({"format":"factoria.vfx/1","parts":[{"type":"sound","clip":"assets/sfx/absent.wav"}]})");
    const ValidationReport r = validate_project(p.dir);
    const ValidationIssue* clip = find(r.errors, "assets/vfx/gone.vfx.json", "/parts/0/clip");
    REQUIRE(clip);
    CHECK_FALSE(clip->hint.empty());
}

TEST_CASE("validate: an effect that is not JSON is an error that names the file") {
    Project p;
    p.effect("assets/vfx/broken.vfx.json", "{ nope");
    const ValidationReport r = validate_project(p.dir);
    CHECK(find(r.errors, "assets/vfx/broken.vfx.json", ""));
}

TEST_CASE("validate: an effect warning does not fail the project") {
    Project p;
    p.effect("assets/vfx/warm.vfx.json", R"({"format":"factoria.vfx/1","parts":[{"type":"emitter","emitter":{"burst":4,"rate":30}}]})");
    const ValidationReport r = validate_project(p.dir);
    for (const auto& e : r.errors) CHECK_MESSAGE(e.file != "assets/vfx/warm.vfx.json", e.to_string());
    CHECK(find(r.warnings, "assets/vfx/warm.vfx.json", "/parts/0/emitter/rate"));
}

TEST_CASE("validate: an effect in any folder of the project is checked, not only under assets/") {
    Project p;
    p.effect("fx/oops.vfx.json", R"({"format":"factoria.vfx/1","parts":[{"type":"command","command":"fs.delete"}]})");
    p.effect("build/skipped.vfx.json", R"({"format":"factoria.vfx/1","parts":[{"type":"command","command":"fs.delete"}]})");
    const ValidationReport r = validate_project(p.dir);
    CHECK(find(r.errors, "fx/oops.vfx.json", "/parts/0/command"));
    CHECK_FALSE(find(r.errors, "build/skipped.vfx.json", "/parts/0/command"));  // a top-level build/ holds exports, not sources
}

TEST_CASE("validate: the document a scene's Vfx.effect names is validated, even when its file name is not *.vfx.json") {
    Project p;
    p.effect("assets/vfx/torch.fx.json", R"({"format":"factoria.vfx/1","parts":[{"type":"emitter","emitter":{"burts":6}}]})");
    p.effect("assets/vfx/unused.fx.json", R"({"format":"factoria.vfx/1","parts":[{"type":"emitter","emitter":{"burts":6}}]})");
    p.effect("scenes/fire.scene.json", R"({"format":"factoria.scene/1","entities":[
        {"name":"torch","components":{"Transform":{},"Vfx":{"effect":"assets/vfx/torch.fx.json"}}}]})");
    const ValidationReport r = validate_project(p.dir);
    const ValidationIssue* typo = find(r.errors, "assets/vfx/torch.fx.json", "/parts/0/emitter");
    REQUIRE(typo);
    CHECK(typo->message.find("burts") != std::string::npos);
    CHECK_FALSE(find(r.errors, "assets/vfx/unused.fx.json", "/parts/0/emitter"));  // nothing names it, and its name is not an effect's
}
