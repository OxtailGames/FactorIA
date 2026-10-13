// In-process tests of the argument parser and command dispatch (no engine needed).
#include <doctest/doctest.h>

#include <sstream>

#include "fa/cli/cli.h"

namespace {
struct Result {
    int code;
    std::string out, err;
};
Result run(std::vector<std::string> args, const std::string& input = {}) {
    std::ostringstream out, err;
    std::istringstream in(input);
    int code = fa::cli::cli_main(args, out, err, in);
    return {code, out.str(), err.str()};
}
}  // namespace

TEST_CASE("version and help") {
    auto v = run({"--version"});
    CHECK(v.code == 0);
    CHECK(v.out.rfind("factoria ", 0) == 0);
    auto h = run({"help"});
    CHECK(h.code == 0);
    CHECK(h.out.find("mcp") != std::string::npos);
    auto none = run({});
    CHECK(none.code == 0);
}

TEST_CASE("usage errors exit with 2 and teach") {
    auto u = run({"tset"});
    CHECK(u.code == 2);
    CHECK(u.err.find("test") != std::string::npos);
    auto f = run({"run", "--hedless"});
    CHECK(f.code == 2);
    CHECK(f.err.find("--headless") != std::string::npos);
    auto m = run({"new"});
    CHECK(m.code == 2);
    auto n = run({"run", "--frames"});
    CHECK(n.code == 2);
    auto i = run({"run", "--frames", "abc", "--headless", "--project", "."});
    CHECK(i.code == 2);
    auto sub = run({"feedback", "ad"});
    CHECK(sub.code == 2);
    CHECK(sub.err.find("add") != std::string::npos);
    auto group = run({"ai"});
    CHECK(group.code == 2);
}

TEST_CASE("every command has help with examples") {
    for (const char* c : {"new", "templates", "run", "screenshot", "test", "validate", "call", "commands", "api", "mcp", "export", "version"}) {
        auto r = run({c, "--help"});
        CHECK_MESSAGE(r.code == 0, c);
        CHECK_MESSAGE(r.out.find("Examples:") != std::string::npos, c);
    }
    for (auto sub : std::vector<std::vector<std::string>>{{"ai", "run"}, {"ai", "doctor"}, {"feedback", "add"}, {"feedback", "collect"}, {"docs", "search"}}) {
        auto args = sub;
        args.push_back("--help");
        auto r = run(args);
        CHECK(r.code == 0);
        CHECK(r.out.find("Examples:") != std::string::npos);
    }
}

TEST_CASE("templates and docs work without a project") {
    auto t = run({"templates", "--json"});
    CHECK(t.code == 0);
    CHECK(t.out.find("2d-platformer") != std::string::npos);
    auto d = run({"docs", "list", "--json"});
    CHECK(d.code == 0);
    auto bad = run({"docs", "scriptin"});
    CHECK(bad.code == 1);
    CHECK(bad.err.find("scripting") != std::string::npos);
}
