// project.validate and the "network" section of factoria.json (the hosts http.fetch may call): wrong values with their JSON
// pointer and a fix, the warning for a missing purpose, and the warning for a script that calls http.fetch with no hosts declared.
#include <doctest.h>

#include "fa/core/json.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"
#include "test_helpers.h"

using namespace fa;

namespace {

struct NetProject {
    testing::TempDir tmp;
    std::string dir;
    explicit NetProject(const char* network) {
        REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
        dir = tmp.sub("game");
        if (!network) return;
        auto j = load_json_file(dir + "/factoria.json");
        REQUIRE(j.ok());
        (*j)["network"] = *parse_json(network);
        REQUIRE(save_json_file(dir + "/factoria.json", *j).ok());
    }
    ValidationReport validate() const { return validate_project(dir); }
};

std::vector<const ValidationIssue*> at(const std::vector<ValidationIssue>& list, const std::string& file, const std::string& pointer = "*") {
    std::vector<const ValidationIssue*> found;
    for (const auto& i : list)
        if (i.file == file && (pointer == "*" || i.pointer == pointer)) found.push_back(&i);
    return found;
}

bool has(const std::string& text, const char* part) { return text.find(part) != std::string::npos; }

}  // namespace

TEST_CASE("validate: a good network section adds nothing") {
    NetProject p(R"({"hosts": ["api.example.com", "*.cdn.example.com", "localhost"], "purpose": "Daily challenge."})");
    const ValidationReport r = p.validate();
    for (const auto& e : r.errors) CHECK_MESSAGE(false, e.to_string());
    CHECK(at(r.warnings, "factoria.json").empty());
}

TEST_CASE("validate: network mistakes are reported once each, at their pointer, with a fix") {
    NetProject p(R"({"hosts": ["https://api.example.com/v1", "api.example.com", "API.example.com", 7], "purpse": "x"})");
    const ValidationReport r = p.validate();
    CHECK_FALSE(r.ok);

    const auto url = at(r.errors, "factoria.json", "/network/hosts/0");
    REQUIRE(url.size() == 1);  // the schema's own message is dropped in favour of this one
    CHECK_FALSE(url[0]->hint.empty());
    const auto number = at(r.errors, "factoria.json", "/network/hosts/3");
    REQUIRE(number.size() == 1);
    CHECK(has(number[0]->message, "must be a host name string"));
    const auto twice = at(r.warnings, "factoria.json", "/network/hosts/2");
    REQUIRE(twice.size() == 1);
    CHECK(has(twice[0]->message, "listed twice"));
    const auto typo = at(r.warnings, "factoria.json", "/network/purpse");
    REQUIRE(typo.size() == 1);
    CHECK(has(typo[0]->hint, "purpose"));  // did you mean
}

TEST_CASE("validate: an empty or missing host list is an error that says what to write") {
    NetProject empty(R"({"hosts": [], "purpose": "x"})");
    auto r = empty.validate();
    const auto none = at(r.errors, "factoria.json", "/network/hosts");
    REQUIRE(none.size() == 1);
    CHECK(has(none[0]->message, "is empty"));

    NetProject missing(R"({"purpose": "x"})");
    r = missing.validate();
    const auto absent = at(r.errors, "factoria.json", "/network/hosts");
    REQUIRE(absent.size() == 1);
    CHECK(has(absent[0]->message, "missing"));
    CHECK(has(absent[0]->hint, "api.example.com"));
}

TEST_CASE("validate: hosts without a purpose warn, because the privacy notice needs one") {
    NetProject p(R"({"hosts": ["api.example.com"]})");
    const ValidationReport r = p.validate();
    CHECK(r.ok);
    const auto purpose = at(r.warnings, "factoria.json", "/network/purpose");
    REQUIRE(purpose.size() == 1);
    CHECK(has(purpose[0]->message, "say what the game sends over the network"));
}

TEST_CASE("validate: a script that calls http.fetch in a game with no declared hosts is warned about, once") {
    NetProject p(nullptr);
    testing::write_all(p.dir + "/scripts/net.js", "import { http } from \"factoria\";\nexport function ask() { return http.fetch(\"https://api.example.com/x\"); }\n");
    testing::write_all(p.dir + "/scripts/net2.js", "import { http } from \"factoria\";\nexport function ask2() { return http.fetch(\"https://api.example.com/y\"); }\n");
    ValidationReport r = p.validate();
    std::size_t warned = 0;
    for (const auto& w : r.warnings)
        if (has(w.message, "calls http.fetch, but factoria.json declares no \"network\" hosts")) {
            ++warned;
            CHECK(has(w.hint, "docs/NETWORKING.md"));
        }
    CHECK(warned == 1);

    // Declaring a host silences it.
    auto j = load_json_file(p.dir + "/factoria.json");
    REQUIRE(j.ok());
    (*j)["network"] = *parse_json(R"({"hosts": ["api.example.com"], "purpose": "Daily challenge."})");
    REQUIRE(save_json_file(p.dir + "/factoria.json", *j).ok());
    r = p.validate();
    for (const auto& w : r.warnings) CHECK_FALSE(has(w.message, "calls http.fetch"));
}

TEST_CASE("validate: analytics and remoteConfig need https URLs whose host is in network.hosts") {
    auto with = [](const char* extra) {
        NetProject p(R"({"hosts": ["stats.example.com"], "purpose": "Stats."})");
        auto j = load_json_file(p.dir + "/factoria.json");
        REQUIRE(j.ok());
        const Json add = *parse_json(extra);
        for (const auto& [k, v] : add.items()) (*j)[k] = v;
        REQUIRE(save_json_file(p.dir + "/factoria.json", *j).ok());
        return p.validate();
    };
    auto good = with(R"({"analytics": {"endpoint": "https://stats.example.com/e"}, "remoteConfig": {"url": "https://stats.example.com/c.json"}})");
    for (const auto& e : good.errors) CHECK_MESSAGE(false, e.to_string());

    auto bad = with(R"({"analytics": {"endpoint": "https://other.example.com/e", "batch": 500}, "remoteConfig": {"url": "http://stats.example.com/c.json"}})");
    CHECK_FALSE(bad.ok);
    const auto host = at(bad.errors, "factoria.json", "/analytics/endpoint");
    REQUIRE(host.size() == 1);  // once: the section parser's message replaces the schema's
    CHECK(has(host[0]->message, "network"));
    CHECK(at(bad.errors, "factoria.json", "/analytics/batch").size() == 1);
    CHECK(at(bad.errors, "factoria.json", "/remoteConfig/url").size() == 1);
}
