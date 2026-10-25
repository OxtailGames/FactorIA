// project.validate and the "audio" section of factoria.json: the snapshot catalog (wrong values with their JSON pointer, a fix and a
// "did you mean", unknown keys as warnings).
#include <doctest.h>

#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"
#include "test_helpers.h"

using namespace fa;

namespace {

// A 2d-empty project with an "audio" section (when `audio` is not null).
struct Project {
    testing::TempDir tmp;
    std::string dir;

    explicit Project(const char* audio) {
        REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
        dir = tmp.sub("game");
        if (!audio) return;
        auto j = load_json_file(dir + "/factoria.json");
        REQUIRE(j.ok());
        (*j)["audio"] = *parse_json(audio);
        REQUIRE(save_json_file(dir + "/factoria.json", *j).ok());
    }
    ValidationReport validate() const { return validate_project(dir); }
};

std::vector<const ValidationIssue*> at(const std::vector<ValidationIssue>& list, const std::string& pointer) {
    std::vector<const ValidationIssue*> found;
    for (const auto& i : list)
        if (i.file == "factoria.json" && i.pointer == pointer) found.push_back(&i);
    return found;
}

}  // namespace

TEST_CASE("validate: a good audio section adds nothing") {
    Project p(R"({"snapshots": {
        "underwater": {"fade": 0.8, "buses": {"sfx": {"volume": 0.8, "lowpass": 600, "reverb": 0.3},
                                              "music": {"lowpass": null, "duck": {"by": "ui", "amount": 0.5, "attack": 0.05, "release": 0.5}}}},
        "normal": {}}})");
    const ValidationReport r = p.validate();
    for (const auto& e : r.errors) CHECK_MESSAGE(false, e.to_string());
    for (const auto& w : r.warnings) CHECK_MESSAGE((w.file == "AGENTS.md" || w.file == "tests"), w.to_string());
}

TEST_CASE("validate: audio snapshot mistakes are reported once each, at their pointer, with a fix") {
    Project p(R"({"snapshots": {
        "loud": {"fade": -1, "buses": {"sfxx": {"lowpass": 600},
                                       "music": {"volume": 9, "reverb": "lots", "lowpass": 5, "duck": {"by": "music"}},
                                       "master": {"duck": {"by": "sfx"}},
                                       "ui": {"duck": {"by": "sfxs"}}}},
        "typo": {"fades": 1}}})");
    const ValidationReport r = p.validate();
    CHECK_FALSE(r.ok);

    const auto bus = at(r.errors, "/audio/snapshots/loud/buses/sfxx");
    REQUIRE(bus.size() == 1);
    CHECK(bus[0]->message.find("Did you mean 'sfx'?") != std::string::npos);
    CHECK_FALSE(bus[0]->hint.empty());

    CHECK(at(r.errors, "/audio/snapshots/loud/fade").size() == 1);
    CHECK(at(r.errors, "/audio/snapshots/loud/buses/music/volume").size() == 1);
    CHECK(at(r.errors, "/audio/snapshots/loud/buses/music/reverb").size() == 1);
    const auto low = at(r.errors, "/audio/snapshots/loud/buses/music/lowpass");
    REQUIRE(low.size() == 1);
    CHECK(low[0]->message.find("below hearing") != std::string::npos);
    const auto self = at(r.errors, "/audio/snapshots/loud/buses/music/duck/by");
    REQUIRE(self.size() == 1);
    CHECK(self[0]->message.find("cannot duck itself") != std::string::npos);
    CHECK(at(r.errors, "/audio/snapshots/loud/buses/master/duck").size() == 1);
    const auto by = at(r.errors, "/audio/snapshots/loud/buses/ui/duck/by");
    REQUIRE(by.size() == 1);
    CHECK(by[0]->message.find("Did you mean 'sfx'?") != std::string::npos);

    const auto typo = at(r.warnings, "/audio/snapshots/typo/fades");
    REQUIRE(typo.size() == 1);
    CHECK(typo[0]->message.find("fade") != std::string::npos);  // did you mean
}

TEST_CASE("validate: an audio section that is not an object is one error at /audio") {
    Project p("[1, 2]");
    const ValidationReport r = p.validate();
    CHECK_FALSE(r.ok);
    CHECK(at(r.errors, "/audio").size() == 1);
}
