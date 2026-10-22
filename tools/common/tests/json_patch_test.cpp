// patch_json_text / patch_json_file (fa/tooling/json_patch.h): the one patcher behind save_export_settings,
// project.new_plugin and platform.add_backend. It must change the keys asked for and nothing else.
#include <doctest.h>

#include "fa/tooling/json_patch.h"
#include "test_helpers.h"

using namespace fa;

namespace {

std::string patch_ok(const std::string& text, const std::vector<JsonPatchOp>& ops) {
    auto r = patch_json_text(text, ops, "test.json");
    if (!r.ok()) MESSAGE(r.error().message);
    REQUIRE(r.ok());
    return *r;
}

}  // namespace

TEST_CASE("json patch: a new key goes last, the other lines are byte for byte as they were") {
    const std::string text =
        "{\n"
        "    \"zeta\":   1,\n"
        "    \"alpha\" : [1,2,   3],   \n"
        "    \"mid\": { \"b\": 2, \"a\": 1 }\n"
        "}\n";
    const std::string out = patch_ok(text, {{{"added"}, Json("x")}});
    CHECK(out ==
          "{\n"
          "    \"zeta\":   1,\n"
          "    \"alpha\" : [1,2,   3],   \n"
          "    \"mid\": { \"b\": 2, \"a\": 1 },\n"
          "    \"added\": \"x\"\n"
          "}\n");
}

TEST_CASE("json patch: replacing a value keeps the order of the keys and the layout around it") {
    const std::string text = "{ \"b\": 1, \"a\": {\"k\": [1, 2]},\n  \"c\": 3 }";
    CHECK(patch_ok(text, {{{"a"}, Json(5)}}) == "{ \"b\": 1, \"a\": 5,\n  \"c\": 3 }");
    CHECK(patch_ok(text, {{{"b"}, Json("s")}, {{"c"}, Json(true)}}) == "{ \"b\": \"s\", \"a\": {\"k\": [1, 2]},\n  \"c\": true }");
}

TEST_CASE("json patch: nested keys change only the key asked for, and parents are created when missing") {
    const std::string text =
        "{\n"
        "  \"name\": \"g\",\n"
        "  \"plugins\": {\n"
        "    \"one\": { \"path\": \"plugins/one\" }\n"
        "  },\n"
        "  \"tail\": [1]\n"
        "}\n";
    // A key inside an existing object: appended there, with that object's own indentation.
    const std::string added = patch_ok(text, {{{"plugins", "two"}, Json::parse(R"({"path": "plugins/two", "platforms": ["macos"]})")}});
    CHECK(added ==
          "{\n"
          "  \"name\": \"g\",\n"
          "  \"plugins\": {\n"
          "    \"one\": { \"path\": \"plugins/one\" },\n"
          "    \"two\": {\n"
          "      \"path\": \"plugins/two\",\n"
          "      \"platforms\": [\"macos\"]\n"
          "    }\n"
          "  },\n"
          "  \"tail\": [1]\n"
          "}\n");
    // A nested value replaced in place.
    CHECK(patch_ok(text, {{{"plugins", "one", "path"}, Json("elsewhere")}}) ==
          "{\n  \"name\": \"g\",\n  \"plugins\": {\n    \"one\": { \"path\": \"elsewhere\" }\n  },\n  \"tail\": [1]\n}\n");
    // A parent that does not exist yet is created with the whole path.
    const std::string made = patch_ok("{\n  \"name\": \"g\"\n}\n", {{{"a", "b", "c"}, Json(1)}});
    auto parsed = parse_json(made, "made");
    REQUIRE(parsed.ok());
    CHECK((*parsed)["a"]["b"]["c"] == 1);
    CHECK(made.rfind("{\n  \"name\": \"g\",\n  \"a\": {", 0) == 0);
}

TEST_CASE("json patch: removing a key closes the gap and a key that is not there is a no-op") {
    const std::string text = "{\n  \"a\": 1,\n  \"b\": 2,\n  \"c\": 3\n}\n";
    CHECK(patch_ok(text, {{{"b"}, std::nullopt}}) == "{\n  \"a\": 1,\n  \"c\": 3\n}\n");
    CHECK(patch_ok(text, {{{"c"}, std::nullopt}}) == "{\n  \"a\": 1,\n  \"b\": 2\n}\n");
    CHECK(patch_ok(text, {{{"nope"}, std::nullopt}, {{"x", "y"}, std::nullopt}}) == text);
}

TEST_CASE("json patch: CRLF files and tab indents keep their style; an empty object gets a member") {
    CHECK(patch_ok("{\r\n\t\"a\": 1\r\n}\r\n", {{{"b"}, Json(2)}}) == "{\r\n\t\"a\": 1,\r\n\t\"b\": 2\r\n}\r\n");
    CHECK(patch_ok("{}", {{{"a"}, Json(1)}}) == "{\n  \"a\": 1\n}");
}

TEST_CASE("json patch: errors say what is wrong") {
    auto notObject = patch_json_text("[1]", {{{"a"}, Json(1)}}, "f.json");
    REQUIRE_FALSE(notObject.ok());
    CHECK(notObject.error().message.find("f.json") != std::string::npos);
    auto broken = patch_json_text("{\"a\": }", {{{"a"}, Json(1)}}, "f.json");
    REQUIRE_FALSE(broken.ok());
    CHECK_FALSE(broken.error().hint.empty());
    auto through = patch_json_text("{\"a\": 1}", {{{"a", "b"}, Json(1)}}, "f.json");
    REQUIRE_FALSE(through.ok());
    CHECK(through.error().message.find("/a") != std::string::npos);
}

TEST_CASE("json patch: the file version writes only when the text changed") {
    testing::TempDir tmp;
    const std::string path = tmp.sub("p.json");
    testing::write_all(path, "{\n  \"a\": 1\n}\n");
    REQUIRE(patch_json_file(path, {{{"a"}, Json(1)}}).ok());
    CHECK(testing::read_all(path) == "{\n  \"a\": 1\n}\n");
    REQUIRE(patch_json_file(path, {{{"b"}, Json(true)}}).ok());
    CHECK(testing::read_all(path) == "{\n  \"a\": 1,\n  \"b\": true\n}\n");
    CHECK_FALSE(patch_json_file(tmp.sub("missing.json"), {{{"a"}, Json(1)}}).ok());
}
