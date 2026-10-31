// Noticing that the running program was replaced on disk (fa/tooling/self_update.h) and what .mcp.json says.
#include <doctest.h>

#include <chrono>
#include <fstream>

#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/tooling/mcp_config.h"
#include "fa/tooling/self_update.h"
#include "test_helpers.h"

using namespace fa;
using fa::testing::TempDir;

namespace {

// A fake program: junk, then the markers a real build carries. The marker texts are joined here so that this test program
// does not carry a complete marker of its own.
std::string fake_program(const std::string& version, const std::string& fingerprint, std::size_t pad = 64) {
    std::string bytes = "\x7f" "ELF fake " + std::string(pad, '.');
    if (!fingerprint.empty()) bytes += std::string("FA-BUILD-") + "FINGERPRINT:" + fingerprint + ";";
    if (!version.empty()) bytes += std::string("FA-ENGINE-") + "VERSION:" + version + ";";
    return bytes + " end";
}

void write_bytes(const std::filesystem::path& p, const std::string& bytes) {
    std::ofstream out(p, std::ios::binary | std::ios::trunc);
    out << bytes;
}

}  // namespace

TEST_CASE("self update: read_build_id reads the version and fingerprint written in a file") {
    TempDir dir;
    const auto exe = dir.path / "factoria";
    write_bytes(exe, fake_program("0.4.0", "0123456789ab"));
    const BuildId id = read_build_id(exe);
    CHECK(id.version == "0.4.0");
    CHECK(id.fingerprint == "0123456789ab");
    CHECK(id.comparable());
    CHECK(id.label() == "0.4.0 build 0123456789ab");
    CHECK(read_build_id(dir.path / "missing").empty());
    write_bytes(exe, "no markers in here");
    CHECK(read_build_id(exe).empty());
    CHECK(BuildId{"0.4.0", "unknown"}.label() == "0.4.0");
    CHECK_FALSE(BuildId{"0.4.0", "unknown"}.comparable());
}

TEST_CASE("self update: a marker cut by the end of a read block is still found") {
    TempDir dir;
    const auto exe = dir.path / "big";
    // The markers sit across the 4 MB block boundary.
    std::string bytes(4 * 1024 * 1024 - 20, 'x');
    bytes += fake_program("1.2.3", "abcdefabcdef", 0);
    bytes += std::string(1000, 'y');
    write_bytes(exe, bytes);
    const BuildId id = read_build_id(exe);
    CHECK(id.fingerprint == "abcdefabcdef");
    CHECK(id.version == "1.2.3");
}

TEST_CASE("self update: UpdateWatch tells an update from a rebuild of the same commit") {
    TempDir dir;
    const auto exe = dir.path / "factoria";
    write_bytes(exe, fake_program("0.4.0", "aaaaaaaaaaaa"));
    UpdateWatch watch(exe, BuildId{"0.4.0", "aaaaaaaaaaaa"});
    CHECK(watch.check() == UpdateCheck::Unchanged);
    CHECK_FALSE(watch.updated());

    // The same commit written again (a different size): identified, but not an update.
    write_bytes(exe, fake_program("0.4.0", "aaaaaaaaaaaa", 300));
    CHECK(watch.check() == UpdateCheck::Settling);  // seen once: it may still be being written
    CHECK(watch.check() == UpdateCheck::Same);
    CHECK_FALSE(watch.updated());
    CHECK(watch.check() == UpdateCheck::Unchanged);

    // Another commit.
    write_bytes(exe, fake_program("0.5.0", "bbbbbbbbbbbb", 500));
    CHECK(watch.check() == UpdateCheck::Settling);
    CHECK(watch.check() == UpdateCheck::Updated);
    CHECK(watch.updated());
    CHECK(watch.on_disk().version == "0.5.0");
    CHECK(watch.on_disk().fingerprint == "bbbbbbbbbbbb");
    CHECK(watch.running().fingerprint == "aaaaaaaaaaaa");
    CHECK(watch.check() == UpdateCheck::Updated);  // as long as it stays so
    const FileStamp first = watch.examined_stamp();

    // A third one: the stamp moves, which is how "Not now" is told from a new update.
    write_bytes(exe, fake_program("0.6.0", "cccccccccccc", 700));
    CHECK(watch.check(true) == UpdateCheck::Updated);  // settled: read at once
    CHECK(watch.examined_stamp() != first);
    CHECK(watch.on_disk().version == "0.6.0");

    // Back to the running build (a rollback): no longer an update.
    write_bytes(exe, fake_program("0.4.0", "aaaaaaaaaaaa", 900));
    CHECK(watch.check(true) == UpdateCheck::Same);
    CHECK_FALSE(watch.updated());
}

TEST_CASE("self update: a file that is missing or has no identity is never counted as an update") {
    TempDir dir;
    const auto exe = dir.path / "factoria";
    write_bytes(exe, fake_program("0.4.0", "aaaaaaaaaaaa"));
    UpdateWatch watch(exe, BuildId{"0.4.0", "aaaaaaaaaaaa"});
    // Being replaced: the old file is gone for a moment.
    std::filesystem::remove(exe);
    CHECK(watch.check() == UpdateCheck::Settling);
    CHECK(watch.check(true) == UpdateCheck::Settling);
    CHECK_FALSE(watch.updated());
    // A build outside git has "unknown": nothing to compare.
    write_bytes(exe, fake_program("0.5.0", "unknown", 200));
    CHECK(watch.check(true) == UpdateCheck::Unidentified);
    CHECK_FALSE(watch.updated());
    write_bytes(exe, "something else entirely, no markers");
    CHECK(watch.check(true) == UpdateCheck::Unidentified);
    CHECK_FALSE(watch.updated());
    // A running build that cannot be compared never sees an update either.
    UpdateWatch unknown(exe, BuildId{"0.4.0", "unknown"});
    write_bytes(exe, fake_program("0.9.0", "dddddddddddd", 400));
    CHECK(unknown.check(true) == UpdateCheck::Unidentified);
    CHECK_FALSE(unknown.updated());
}

TEST_CASE("self update: this program watches itself and engine.update_status says it is current") {
    UpdateWatch& mine = process_update_watch();
    CHECK(mine.running().version == FA_ENGINE_VERSION);
    CHECK_FALSE(executable_path().empty());
    CommandRegistry registry;
    register_update_commands(registry);
    REQUIRE(registry.has("engine.update_status"));
    CHECK(registry.info("engine.update_status")->readOnly);
    const CommandResult r = registry.call("engine.update_status");
    REQUIRE(r.ok);
    CHECK(r.result["restartDue"] == false);
    CHECK(r.result["state"] == "current");
    CHECK(r.result["running"]["version"] == FA_ENGINE_VERSION);
    CHECK(r.result["summary"].is_string());
    // Whoever hosts the process can add its own part.
    set_update_status_extra("test", [] { return Json::object({{"hello", 1}}); });
    CHECK(registry.call("engine.update_status").result["test"]["hello"] == 1);
    set_update_status_extra("test", nullptr);
    CHECK_FALSE(registry.call("engine.update_status").result.contains("test"));
}

TEST_CASE("self update: update_status_json reports an update on disk with both builds") {
    TempDir dir;
    const auto exe = dir.path / "factoria";
    write_bytes(exe, fake_program("0.4.0", "aaaaaaaaaaaa"));
    UpdateWatch watch(exe, BuildId{"0.4.0", "aaaaaaaaaaaa"});
    CHECK(update_status_json(watch)["state"] == "current");
    write_bytes(exe, fake_program("0.5.0", "bbbbbbbbbbbb", 250));
    const Json j = update_status_json(watch);  // a command answers now: it does not wait for a second look
    CHECK(j["state"] == "updated_on_disk");
    CHECK(j["restartDue"] == true);
    CHECK(j["onDisk"]["version"] == "0.5.0");
    CHECK(j["running"]["fingerprint"] == "aaaaaaaaaaaa");
    CHECK(j["summary"].get<std::string>().find("updated on disk") != std::string::npos);
}

TEST_CASE("mcp config: read_claude_code_mcp_state and ensure_claude_code_mcp_timeout") {
    TempDir dir;
    ClaudeCodeMcpState none = read_claude_code_mcp_state(dir.str());
    CHECK_FALSE(none.exists);
    CHECK_FALSE(none.hasServer);
    CHECK(none.modifiedMs == 0);
    CHECK_FALSE(ensure_claude_code_mcp_timeout(dir.str()).value());  // no file: nothing to do

    // An older file: the server without a timeout, and another server that stays as it is.
    const std::string path = dir.sub(".mcp.json");
    write_bytes(path, R"({"mcpServers":{"other":{"command":"x"},"factoria":{"command":"factoria","args":["mcp","--project","."]}}})");
    ClaudeCodeMcpState old = read_claude_code_mcp_state(dir.str());
    CHECK(old.exists);
    CHECK(old.hasServer);
    CHECK_FALSE(old.hasTimeout);
    CHECK(old.modifiedMs > 0);
    auto fixed = ensure_claude_code_mcp_timeout(dir.str());
    REQUIRE(fixed.ok());
    CHECK(fixed.value());
    ClaudeCodeMcpState now = read_claude_code_mcp_state(dir.str());
    CHECK(now.hasTimeout);
    CHECK(now.timeoutMs == kClaudeCodeMcpToolTimeoutMs);
    const Json written = Json::parse(fa::testing::read_all(path));
    CHECK(written["mcpServers"]["other"]["command"] == "x");
    CHECK(written["mcpServers"]["factoria"]["args"][0] == "mcp");
    CHECK_FALSE(ensure_claude_code_mcp_timeout(dir.str()).value());  // already there: not written again

    // A timeout the user chose is theirs.
    write_bytes(path, R"({"mcpServers":{"factoria":{"command":"factoria","args":["mcp"],"timeout":60000}}})");
    CHECK_FALSE(ensure_claude_code_mcp_timeout(dir.str()).value());
    CHECK(read_claude_code_mcp_state(dir.str()).timeoutMs == 60000);
}
