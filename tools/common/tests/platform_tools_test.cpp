// The tooling side of the platform API (docs/PLATFORM.md): `factoria validate` on the "platform" section of factoria.json,
// and the `template` argument of project.new_plugin.
#include <doctest.h>

#include <algorithm>
#include <filesystem>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/tooling.h"
#include "fa/tooling/validate.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

std::string make_game(const testing::TempDir& tmp, const Json& platform, const Json& plugins = Json()) {
    const std::string dir = tmp.sub("game");
    REQUIRE(create_project(dir, "2d-empty").ok());
    auto project = load_json_file(dir + "/factoria.json");
    REQUIRE(project.ok());
    (*project)["platform"] = platform;
    if (!plugins.is_null()) (*project)["plugins"] = plugins;
    REQUIRE(save_json_file(dir + "/factoria.json", *project).ok());
    return dir;
}

const ValidationIssue* find_issue(const std::vector<ValidationIssue>& issues, const std::string& pointerPrefix) {
    for (const ValidationIssue& i : issues)
        if (i.file == "factoria.json" && i.pointer.rfind(pointerPrefix, 0) == 0) return &i;
    return nullptr;
}

}  // namespace

TEST_CASE("validate: a good platform catalog passes") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp, Json::parse(R"({
      "achievements": [{"id": "first_win", "name": "First win", "ids": {"steam": "ACH_WIN"}}],
      "stats": [{"id": "wins"}],
      "leaderboards": [{"id": "high_score", "name": "High score", "order": "descending"}],
      "products": [{"id": "gems_100", "type": "consumable", "title": "100 gems", "price": 0.99}]
    })"));
    auto report = validate_project(dir);
    CHECK_MESSAGE(report.ok, report.to_text());
    CHECK(find_issue(report.errors, "/platform") == nullptr);
}

TEST_CASE("validate: every problem of the platform catalog is reported once, with how to fix it") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp, Json::parse(R"({
      "achievements": [{"id": "first win", "name": "First win"}],
      "stats": [{"id": "wins", "type": "integer"}],
      "products": [
        {"id": "gems_100", "type": "consumable ", "title": "100 gems"},
        {"id": "gems_100", "type": "consumable", "title": "Again"}
      ]
    })"));
    auto report = validate_project(dir);
    REQUIRE_FALSE(report.ok);

    const ValidationIssue* id = find_issue(report.errors, "/platform/achievements/0/id");
    REQUIRE(id != nullptr);
    CHECK(id->message.find("first win") != std::string::npos);

    const ValidationIssue* stat = find_issue(report.errors, "/platform/stats/0/type");
    REQUIRE(stat != nullptr);
    CHECK(stat->message.find("integer") != std::string::npos);
    CHECK((stat->message + stat->hint).find("int") != std::string::npos);  // "did you mean int"

    const ValidationIssue* type = find_issue(report.errors, "/platform/products/0/type");
    REQUIRE(type != nullptr);
    CHECK((type->message + type->hint).find("consumable") != std::string::npos);

    const ValidationIssue* dup = find_issue(report.errors, "/platform/products/1");
    REQUIRE(dup != nullptr);
    CHECK(dup->message.find("gems_100") != std::string::npos);

    // The schema's own complaints about the same fields are not repeated next to the catalog's.
    const int onType = static_cast<int>(std::count_if(report.errors.begin(), report.errors.end(), [](const ValidationIssue& i) {
        return i.pointer == "/platform/products/0/type";
    }));
    CHECK(onType == 1);
}

TEST_CASE("validate: platform.backend must name a plugin the game declares") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp, Json::parse(R"({"backend": "steem"})"),
                                      Json::parse(R"({"steam": {"path": "plugins/steam", "platforms": ["windows"]}})"));
    auto report = validate_project(dir);
    const ValidationIssue* backend = find_issue(report.errors, "/platform/backend");
    REQUIRE(backend != nullptr);
    CHECK(backend->message.find("steem") != std::string::npos);
    CHECK(backend->hint.find("steam") != std::string::npos);  // did you mean

    // Per platform: the pointer names the platform that is wrong.
    testing::TempDir tmp2;
    const std::string dir2 = make_game(tmp2, Json::parse(R"({"backend": {"windows": "steam", "ios": "appel"}})"),
                                       Json::parse(R"({"steam": {"path": "plugins/steam", "platforms": ["windows"]},
                                                       "apple": {"path": "plugins/apple", "platforms": ["ios"]}})"));
    auto report2 = validate_project(dir2);
    const ValidationIssue* ios = find_issue(report2.errors, "/platform/backend/ios");
    REQUIRE(ios != nullptr);
    CHECK(ios->hint.find("apple") != std::string::npos);
    CHECK(find_issue(report2.errors, "/platform/backend/windows") == nullptr);

    // "auto" needs no plugin.
    testing::TempDir tmp3;
    const std::string dir3 = make_game(tmp3, Json::parse(R"({"backend": "auto"})"));
    CHECK(find_issue(validate_project(dir3).errors, "/platform") == nullptr);
}

TEST_CASE("project.new_plugin: template picks a starting point, an unknown one lists the others") {
    testing::TempDir tmp;
    const std::string dir = tmp.sub("game");
    REQUIRE(create_project(dir, "2d-empty").ok());
    CommandRegistry reg;
    register_plugin_commands(reg, dir);

    const CommandInfo* info = reg.info("project.new_plugin");
    REQUIRE(info != nullptr);
    const Json& tmpl = info->inputSchema["properties"]["template"];
    CHECK(tmpl.value("default", std::string()) == "basic");
    CHECK_FALSE(tmpl.value("description", std::string()).empty());

    auto bad = reg.call("project.new_plugin", Json::parse(R"({"name": "store", "template": "basik"})"));
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error["message"].get<std::string>().find("basik") != std::string::npos);
    const std::string hint = bad.error["hint"].get<std::string>();
    CHECK(hint.find("basic") != std::string::npos);  // did you mean, and the list
    // Nothing was written or declared.
    CHECK_FALSE(stdfs::exists(stdfs::path(dir) / "plugins/store"));
    auto project = load_json_file(dir + "/factoria.json");
    REQUIRE(project.ok());
    CHECK_FALSE(project->contains("plugins"));

    // The default template is the plain example, and its header is the one with the platform backend API.
    auto ok = reg.call("project.new_plugin", Json::parse(R"({"name": "store"})"));
    REQUIRE_MESSAGE(ok.ok, ok.error.dump());
    const std::string header = testing::read_all(stdfs::path(dir) / "plugins/store/include/fa_plugin.h");
    CHECK(header.find("FA_PLUGIN_API_VERSION 2") != std::string::npos);
    CHECK(header.find("add_backend") != std::string::npos);
}

TEST_CASE("platform.add_backend: one command lists every store backend with the arguments each reads") {
    testing::TempDir tmp;
    const std::string dir = tmp.sub("game");
    REQUIRE(create_project(dir, "2d-empty").ok());
    CommandRegistry reg;
    register_plugin_commands(reg, dir);
    register_platform_setup_commands(reg, dir);

    const CommandInfo* info = reg.info("platform.add_backend");
    REQUIRE(info != nullptr);
    CHECK(info->category == "platform");
    CHECK_FALSE(info->readOnly);
    const Json& backend = info->inputSchema["properties"]["backend"];
    REQUIRE(backend["enum"].is_array());
    for (const char* name : {"steam", "apple"}) {
        bool listed = false;
        for (const Json& n : backend["enum"]) listed = listed || n == name;
        CHECK_MESSAGE(listed, name);
        CHECK(info->description.find(std::string(name) + ":") != std::string::npos);  // each backend's summary
    }

    // The schema refuses a backend that does not exist, before anything is written.
    auto bad = reg.call("platform.add_backend", Json::parse(R"({"backend": "stem"})"));
    REQUIRE_FALSE(bad.ok);
    auto project = load_json_file(dir + "/factoria.json");
    REQUIRE(project.ok());
    CHECK_FALSE(project->contains("plugins"));
}
