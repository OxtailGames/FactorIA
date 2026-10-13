// In-process tests of the argument parser, command dispatch and the path options of run/call.
#include <doctest.h>

#include <chrono>
#include <filesystem>
#include <fstream>
#include <sstream>

#include "fa/cli/cli.h"
#include "fa/core/json.h"

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
    auto i = run({"api", "--schema", "bogus"});
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

// ---- path options: inputs are found in the current directory, then in the project; outputs follow the current directory
namespace {
namespace stdfs = std::filesystem;

struct PathsFixture {
    stdfs::path root, project, elsewhere, oldCwd;
    PathsFixture() {
        std::error_code ec;
        oldCwd = stdfs::current_path(ec);
        root = stdfs::temp_directory_path() / ("fa_cli_paths_" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
        stdfs::create_directories(root);
        root = stdfs::canonical(root);
        project = root / "game";
        elsewhere = root / "elsewhere";  // the current directory of the "shell": NOT inside the project
        stdfs::create_directories(elsewhere);
        auto made = run({"new", project.string(), "--template", "2d-empty", "--json"});
        REQUIRE_MESSAGE(made.code == 0, made.err);
        write(project / "replays/jump.json", R"({"frames": {"0": {}, "2": {}}})");
        stdfs::current_path(elsewhere, ec);
    }
    ~PathsFixture() {
        std::error_code ec;
        stdfs::current_path(oldCwd, ec);
        stdfs::remove_all(root, ec);
    }
    static void write(const stdfs::path& p, const std::string& text) {
        stdfs::create_directories(p.parent_path());
        std::ofstream(p, std::ios::binary) << text;
    }
};
// A path the way the CLI prints it in messages: normalized, with '/' separators on every platform.
std::string shown(const stdfs::path& p) { return p.lexically_normal().generic_string(); }
}  // namespace

TEST_CASE("run --input: an existing path relative to the current directory wins, else the project's") {
    PathsFixture f;
    // From outside the project, "replays/jump.json" is only in the project: it is found there.
    auto r = run({"run", f.project.string(), "--headless", "--frames", "3", "--input", "replays/jump.json", "--json"});
    CHECK_MESSAGE(r.code == 0, (r.out + r.err));

    // A file of that name in the current directory wins over the project's (here it is a broken replay).
    PathsFixture::write(f.elsewhere / "replays/jump.json", R"({"nope": 1})");
    r = run({"run", f.project.string(), "--headless", "--frames", "3", "--input", "replays/jump.json", "--json"});
    CHECK(r.code != 0);
    CHECK(r.out.find("Input replay must look like") != std::string::npos);
    stdfs::remove(f.elsewhere / "replays/jump.json");

    // An absolute path is used as it is.
    r = run({"run", f.project.string(), "--headless", "--frames", "3", "--input", (f.project / "replays/jump.json").string(), "--json"});
    CHECK_MESSAGE(r.code == 0, (r.out + r.err));
}

TEST_CASE("run --input: a missing file lists the places tried and suggests a close name") {
    PathsFixture f;
    auto r = run({"run", f.project.string(), "--headless", "--frames", "3", "--input", "replays/jmp.json"});
    CHECK(r.code == 2);
    CHECK(r.err.find("the --input file 'replays/jmp.json'") != std::string::npos);
    CHECK(r.err.find(shown(f.elsewhere / "replays/jmp.json")) != std::string::npos);
    CHECK(r.err.find("relative to the current directory") != std::string::npos);
    CHECK(r.err.find(shown(f.project / "replays/jmp.json")) != std::string::npos);
    CHECK(r.err.find("relative to the project folder") != std::string::npos);
    CHECK(r.err.find("Did you mean 'replays/jump.json'") != std::string::npos);
    // The old, wrong claim ("relative to the project root") is gone from the hint.
    CHECK(r.err.find("relative to the project root") == std::string::npos);

    // From inside the project both places are the same file: it is listed once.
    std::error_code ec;
    stdfs::current_path(f.project, ec);
    r = run({"run", "--headless", "--frames", "3", "--input", "replays/jmp.json"});
    CHECK(r.code == 2);
    CHECK(r.err.find("relative to the current directory") != std::string::npos);
    CHECK(r.err.find("relative to the project folder") == std::string::npos);

    // A folder is not a replay.
    r = run({"run", "--headless", "--frames", "3", "--input", "replays"});
    CHECK(r.code == 2);
    CHECK(r.err.find("a folder of that name exists") != std::string::npos);
}

TEST_CASE("run output options are relative to the current directory and the report prints the absolute path") {
    PathsFixture f;
    auto r = run({"run", f.project.string(), "--headless", "--frames", "3", "--state-out", "out/state.json", "--json"});
    REQUIRE_MESSAGE(r.code == 0, (r.out + r.err));
    CHECK(stdfs::exists(f.elsewhere / "out/state.json"));
    CHECK_FALSE(stdfs::exists(f.project / "out/state.json"));
    // The report names the file it wrote (an absolute path; compare the files, not the spellings).
    const fa::Json report = fa::Json::parse(r.out, nullptr, false);
    REQUIRE(report.is_object());
    REQUIRE(report.contains("stateOut"));
    std::error_code ec;
    CHECK(stdfs::equivalent(stdfs::path(report["stateOut"].get<std::string>()), f.elsewhere / "out/state.json", ec));
}

TEST_CASE("call: @args.json, --batch-file and --input are found in the current directory, then in the project") {
    PathsFixture f;
    PathsFixture::write(f.project / "levels/args.json", R"({})");
    PathsFixture::write(f.project / "levels/batch.json", R"([{"command":"game.step","args":{"frames":2}}])");
    auto r = run({"call", "project.info", "@levels/args.json", "--project", f.project.string()});
    CHECK_MESSAGE(r.code == 0, (r.out + r.err));
    r = run({"call", "--batch-file", "levels/batch.json", "--project", f.project.string()});
    CHECK_MESSAGE(r.code == 0, (r.out + r.err));
    r = run({"call", "game.state", "--input", "replays/jump.json", "--project", f.project.string()});
    CHECK_MESSAGE(r.code == 0, (r.out + r.err));
    r = run({"call", "project.info", "@levels/nope.json", "--project", f.project.string()});
    CHECK(r.code == 2);
    CHECK(r.err.find(shown(f.project / "levels/nope.json")) != std::string::npos);
}
