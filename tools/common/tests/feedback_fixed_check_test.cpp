// The fixed list (feedback/fixed.json, fa/tooling/feedback_fixed.h): validation and the rule that closes matching local entries.
#include <doctest.h>

#include "fa/tooling/feedback.h"
#include "fa/tooling/feedback_fixed.h"
#include "test_helpers.h"

using namespace fa;

namespace {

Json list_with(const char* fixes) {
    return Json::parse(std::string(R"({"format":"factoria.feedback-fixed/1","fixes":)") + fixes + "}");
}

std::string file_with(testing::TempDir& dir, std::initializer_list<std::pair<const char*, const char*>> entries /* category, title */) {
    const std::string file = dir.sub("game") + "/ENGINE_FEEDBACK.json";
    Json doc = create_empty_feedback("g", "0.9.0");
    for (const auto& [category, title] : entries) {
        FeedbackInput in;
        in.category = category;
        in.severity = "major";
        in.title = title;
        in.missing = "the engine lacks it";
        in.workaround = "a script does it by hand";
        REQUIRE(add_feedback_entry(doc, in).ok());
    }
    REQUIRE(save_feedback(file, doc).ok());
    return file;
}

}  // namespace

TEST_CASE("fixed list: the embedded list is valid") {
    auto list = embedded_feedback_fixed();
    REQUIRE(list.ok());
    CHECK(parse_fixed_list(list.value()).ok());
}

TEST_CASE("fixed list: validation says where the problem is") {
    CHECK(parse_fixed_list(list_with(R"([{"category":"physics","titles":["One-way platforms"],"fixedIn":"0.11.0"}])")).ok());
    auto bad = parse_fixed_list(Json::parse(R"({"format":"x","fixes":[]})"));
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("format") != std::string::npos);
    bad = parse_fixed_list(list_with(R"([{"category":"physic","titles":["a"],"fixedIn":"1"}])"));
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("/fixes/0/category") != std::string::npos);
    CHECK(bad.error().hint.find("physics") != std::string::npos);
    CHECK_FALSE(parse_fixed_list(list_with(R"([{"category":"physics","titles":[],"fixedIn":"1"}])")).ok());
    CHECK_FALSE(parse_fixed_list(list_with(R"([{"category":"physics","titles":["a"]}])")).ok());
    CHECK_FALSE(parse_fixed_list(Json::array()).ok());
}

TEST_CASE("fixed list: a matching open entry is closed with the version; others are left alone") {
    testing::TempDir dir;
    const std::string file = file_with(dir, {{"physics", "No one-way platforms"}, {"audio", "No one-way platforms"}, {"ui", "Dropdown has no search box"}});
    const Json list = list_with(R"([{"category":"physics","titles":["No one-way platforms","One-way platform support"],"fixedIn":"0.11.0"}])");
    auto r = check_fixed_feedback(file, list);
    REQUIRE(r.ok());
    CHECK(r->checked == 3);
    REQUIRE(r->closed.size() == 1);
    CHECK(r->closed[0].id == "FB-0001");
    CHECK(r->closed[0].fixedIn == "0.11.0");
    const Json doc = load_feedback(file).value();
    CHECK(doc["entries"][0]["status"] == "fixed-in-engine");
    CHECK(doc["entries"][0]["engineIssue"] == "FactorIA 0.11.0");
    CHECK(doc["entries"][1]["status"] == "open");  // another area
    CHECK(doc["entries"][2]["status"] == "open");   // another gap
    CHECK(validate_feedback(doc).empty());
    // a second call finds nothing more to close
    auto again = check_fixed_feedback(file, list);
    REQUIRE(again.ok());
    CHECK(again->closed.empty());
    CHECK(again->checked == 2);
}

TEST_CASE("fixed list: the same family counts, and the share title is matched too") {
    testing::TempDir dir;
    const std::string file = dir.sub("game") + "/ENGINE_FEEDBACK.json";
    Json doc = create_empty_feedback("g");
    FeedbackInput in;
    in.category = "rendering-3d";
    in.severity = "minor";
    in.title = "Lantern keep torch glow missing";
    in.missing = "no bloom";
    in.workaround = "faked it";
    in.share = Json::object({{"title", "No bloom post effect"}, {"missing", "The renderer has no bloom post-processing effect for bright areas."}});
    REQUIRE(add_feedback_entry(doc, in).ok());
    REQUIRE(save_feedback(file, doc).ok());
    auto r = check_fixed_feedback(file, list_with(R"([{"category":"rendering-2d","titles":["No bloom post effect"],"fixedIn":"0.12.0"}])"));
    REQUIRE(r.ok());
    CHECK(r->closed.size() == 1);
}

TEST_CASE("fixed list: a missing file is not an error for the project check") {
    testing::TempDir dir;
    auto r = check_fixed_feedback_file(dir.sub("none") + "/ENGINE_FEEDBACK.json");
    REQUIRE(r.ok());
    CHECK(r->closed.empty());
}

TEST_CASE("fixed list: feedback.check_fixed is a registered command bound to the project") {
    testing::TempDir dir;
    file_with(dir, {{"ui", "Dropdown has no search box"}});
    CommandRegistry registry;
    register_feedback_commands(registry, dir.sub("game"));
    REQUIRE(registry.has("feedback.check_fixed"));
    auto r = registry.call("feedback.check_fixed", Json::object());
    REQUIRE(r.ok);
    CHECK(r.result.contains("checked"));  // the embedded list is empty until a release fixes something
    CHECK(r.result["closed"] == 0);
}
