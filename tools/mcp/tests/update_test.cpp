// An MCP server that notices it was updated on disk or that its client started with an older .mcp.json
// (fa/mcp/update_monitor.h, fa/mcp/stdio.h; docs/MCP.md "After an update").
#include <doctest.h>

#include <chrono>
#include <fstream>
#include <mutex>
#include <sstream>
#include <thread>

#include "fa/core/fs.h"
#include "fa/mcp/server.h"
#include "fa/mcp/stdio.h"
#include "fa/mcp/update_monitor.h"
#include "fa/tooling/mcp_config.h"
#include "fa/tooling/tooling.h"
#if !defined(_WIN32)
#include <unistd.h>
#endif

using namespace fa;
namespace stdfs = std::filesystem;
using namespace std::chrono_literals;

namespace {

struct Dir {
    stdfs::path path;
    Dir() { path = fa::fs::make_temp_dir("fa_mcp_update_test"); }
    ~Dir() {
        std::error_code ec;
        stdfs::remove_all(ec ? path : path, ec);
    }
};

void write_bytes(const stdfs::path& p, const std::string& bytes) {
    std::ofstream out(p, std::ios::binary | std::ios::trunc);
    out << bytes;
}

// The marker texts are joined here so that this test program carries no complete marker of its own.
std::string fake_program(const std::string& version, const std::string& fingerprint, std::size_t pad = 64) {
    return "fake " + std::string(pad, '.') + std::string("FA-BUILD-") + "FINGERPRINT:" + fingerprint + ";" + std::string("FA-ENGINE-") +
           "VERSION:" + version + ";";
}

struct Rig {
    Dir dir;
    CommandRegistry registry;
    SimpleMcpHost host;
    McpServer server;
    stdfs::path exe;
    std::vector<std::string> sent;
    std::mutex mu;
    int nextId = 1;

    Rig() : host(registry, dir.path.string()), server(host) {
        register_tooling_commands(registry, dir.path.string());
        exe = dir.path / "factoria";
        write_bytes(exe, fake_program("0.4.0", "aaaaaaaaaaaa"));
        server.set_notification_sink([this](const std::string& m) {
            std::lock_guard<std::mutex> lock(mu);
            sent.push_back(m);
        });
    }
    Json rpc(const std::string& method, Json params = Json::object()) {
        Json req = Json::object({{"jsonrpc", "2.0"}, {"id", nextId++}, {"method", method}, {"params", std::move(params)}});
        auto resp = server.handle_message(req.dump());
        REQUIRE(resp.has_value());
        return Json::parse(*resp);
    }
    Json initialize(const std::string& client = "test") {
        return rpc("initialize", {{"protocolVersion", "2025-06-18"}, {"capabilities", Json::object({{"roots", Json::object()}})},
                                  {"clientInfo", {{"name", client}, {"version", "1"}}}});
    }
    Json call(const std::string& tool) { return rpc("tools/call", {{"name", tool}, {"arguments", Json::object()}}); }
    std::size_t count(const std::string& method) {
        std::lock_guard<std::mutex> lock(mu);
        std::size_t n = 0;
        for (const std::string& m : sent)
            if (Json::parse(m).value("method", "") == method) ++n;
        return n;
    }
    static std::string last_text(const Json& response) {
        const Json& content = response["result"]["content"];
        return content.empty() ? std::string() : content.back().value("text", "");
    }
};

McpUpdateOptions quick(const Rig& rig, bool inPlace = true) {
    McpUpdateOptions o;
    o.projectDir = rig.dir.path.string();
    o.restartInPlace = inPlace;
    o.checkEvery = 0ms;
    return o;
}

}  // namespace

TEST_CASE("mcp update: the handshake is handed over and restored, and a restored server needs no initialize") {
    Rig a;
    a.initialize("claude-code");
    a.rpc("logging/setLevel", {{"level", "warning"}});
    const Json state = a.server.session_state();
    CHECK(state["clientInfo"]["name"] == "claude-code");
    CHECK(state["protocolVersion"] == "2025-06-18");

    Rig b;
    CHECK_FALSE(b.server.initialized());
    CHECK_FALSE(b.server.restore_session(Json::array()));
    CHECK_FALSE(b.server.restore_session(Json::object()));
    CHECK_FALSE(b.server.initialized());
    REQUIRE(b.server.restore_session(state));
    CHECK(b.server.initialized());
    CHECK(b.server.client_name() == "claude-code");
    CHECK(b.server.protocol_version() == "2025-06-18");
    CHECK(b.server.log_level() == "warning");
    CHECK(b.server.client_capabilities().contains("roots"));
    CHECK_FALSE(b.call("engine_update_status").contains("error"));  // the client's next request works as it did
}

TEST_CASE("mcp update: a notice is added once to the next tool result, after the result") {
    Rig rig;
    rig.initialize();
    rig.server.add_tool_notice("a", "first note");
    rig.server.add_tool_notice("b", "second note");
    rig.server.add_tool_notice("a", "first note again");  // the same key replaces
    CHECK(rig.server.pending_tool_notices().size() == 2);
    const Json r = rig.call("engine_update_status");
    const Json& content = r["result"]["content"];
    REQUIRE(content.size() >= 2);
    const std::string notice = Rig::last_text(r);
    CHECK(notice.find("[FactorIA notice]") != std::string::npos);
    CHECK(notice.find("first note again") != std::string::npos);
    CHECK(notice.find("second note") != std::string::npos);
    CHECK(notice.find("first note\n") == std::string::npos);
    INFO(content.dump());
    CHECK(content[0]["text"].get<std::string>().find("state") != std::string::npos);  // the result stays the first block
    CHECK(rig.server.pending_tool_notices().empty());
    CHECK(Rig::last_text(rig.call("engine_update_status")).find("[FactorIA notice]") == std::string::npos);  // once
}

TEST_CASE("mcp update: McpResume survives its trip through the command line") {
    McpResume r;
    r.session = Json::object({{"protocolVersion", "2025-06-18"}});
    r.startedMs = 1234567890123;
    r.previousBuild = "0.4.0 build aaaaaaaaaaaa";
    r.lost = "the game at frame 12";
    r.executable = "/opt/factoria/factoria";
    r.notices = {"one", "two"};
    r.restarts = 2;
    r.configReportedMs = 99;
    auto back = McpResume::parse(r.to_string());
    REQUIRE(back.ok());
    CHECK(back->session == r.session);
    CHECK(back->startedMs == r.startedMs);
    CHECK(back->previousBuild == r.previousBuild);
    CHECK(back->lost == r.lost);
    CHECK(back->executable == r.executable);
    CHECK(back->notices == r.notices);
    CHECK(back->restarts == 2);
    CHECK(back->configReportedMs == 99);
    CHECK_FALSE(McpResume::parse("not json").ok());
    CHECK_FALSE(McpResume::parse("[1]").ok());
}

TEST_CASE("mcp update: a replaced executable makes a restart due, unless something is busy") {
    Rig rig;
    rig.initialize();
    UpdateWatch watch(rig.exe, BuildId{"0.4.0", "aaaaaaaaaaaa"});
    bool busy = false;
    McpUpdateOptions o = quick(rig);
    o.busy = [&] { return busy ? std::string("an ai_run is working") : std::string(); };
    o.lost_on_restart = [] { return std::string("the game at frame 40"); };
    McpUpdateMonitor monitor(rig.server, watch, o);
    monitor.poll();
    CHECK_FALSE(monitor.restart_due());

    write_bytes(rig.exe, fake_program("0.5.0", "bbbbbbbbbbbb", 300));
    monitor.poll();  // seen once: it may still be being written
    CHECK_FALSE(monitor.restart_due());
    monitor.poll();
    if (!can_restart_in_place()) {
        CHECK_FALSE(monitor.restart_due());
        return;
    }
    busy = true;
    CHECK_FALSE(monitor.restart_due());
    CHECK(monitor.status()["deferredBy"] == "an ai_run is working");
    CHECK(monitor.status()["restartPending"] == true);
    busy = false;
    CHECK(monitor.restart_due());
    rig.server.add_tool_notice("x", "waiting");
    const McpResume r = monitor.resume_state();
    CHECK(r.previousBuild == "0.4.0 build aaaaaaaaaaaa");
    CHECK(r.lost == "the game at frame 40");
    CHECK(r.restarts == 1);
    CHECK(r.session["clientInfo"]["name"] == "test");
    CHECK(r.notices.size() == 1);
    CHECK(r.executable == rig.exe.string());
    // No tool notice about staleness: the restart takes care of it.
    CHECK(rig.server.pending_tool_notices().size() == 1);
}

TEST_CASE("mcp update: the new process says it restarted, sends list_changed, and carries what was waiting") {
    Rig old;
    old.initialize("claude-code");
    McpResume resume;
    resume.session = old.server.session_state();
    resume.previousBuild = "0.4.0 build aaaaaaaaaaaa";
    resume.lost = "the game at frame 40";
    resume.notices = {"carried note"};
    resume.restarts = 1;
    resume.startedMs = 1000;

    Rig rig;
    write_bytes(rig.exe, fake_program("0.5.0", "bbbbbbbbbbbb"));
    UpdateWatch watch(rig.exe, BuildId{"0.5.0", "bbbbbbbbbbbb"});
    McpUpdateOptions o = quick(rig);
    o.projectDir.clear();
    McpUpdateMonitor monitor(rig.server, watch, o, &resume);
    CHECK(rig.server.initialized());
    monitor.announce_resume();
    CHECK(rig.count("notifications/tools/list_changed") == 1);
    CHECK(rig.count("notifications/resources/list_changed") == 1);
    const std::string text = Rig::last_text(rig.call("engine_update_status"));
    CHECK(text.find("carried note") != std::string::npos);
    CHECK(text.find("restarted itself in place") != std::string::npos);
    CHECK(text.find("0.5.0 build bbbbbbbbbbbb") != std::string::npos);
    CHECK(text.find("0.4.0 build aaaaaaaaaaaa") != std::string::npos);
    CHECK(text.find("the game at frame 40") != std::string::npos);  // what the restart cost is said
}

TEST_CASE("mcp update: where a process cannot restart in place the AI is told to reconnect, once") {
    Rig rig;
    rig.initialize();
    UpdateWatch watch(rig.exe, BuildId{"0.4.0", "aaaaaaaaaaaa"});
    McpUpdateMonitor monitor(rig.server, watch, quick(rig, false));
    write_bytes(rig.exe, fake_program("0.5.0", "bbbbbbbbbbbb", 300));
    monitor.poll();
    monitor.poll();
    CHECK_FALSE(monitor.restart_due());
    CHECK(rig.count("notifications/message") == 1);
    const std::string text = Rig::last_text(rig.call("engine_update_status"));
    CHECK(text.find("updated on disk") != std::string::npos);
    CHECK(text.find("/mcp") != std::string::npos);
    monitor.poll();
    monitor.poll();
    CHECK(rig.server.pending_tool_notices().empty());  // not repeated for the same update
    CHECK(rig.count("notifications/message") == 1);
    write_bytes(rig.exe, fake_program("0.6.0", "cccccccccccc", 500));  // a newer one is news again
    monitor.poll();
    monitor.poll();
    CHECK(rig.server.pending_tool_notices().size() == 1);
}

TEST_CASE("mcp update: a client that started before .mcp.json changed is told once, and the missing timeout is added") {
    Rig rig;
    const std::string mcpJson = (rig.dir.path / ".mcp.json").string();
    write_bytes(mcpJson, R"({"mcpServers":{"factoria":{"command":"factoria","args":["mcp","--project","."]}}})");
    rig.initialize("claude-code");
    UpdateWatch watch(rig.exe, BuildId{"0.4.0", "aaaaaaaaaaaa"});
    McpUpdateMonitor monitor(rig.server, watch, quick(rig));
    std::this_thread::sleep_for(30ms);
    monitor.poll();  // the file has no timeout: FactorIA adds it (the write is after the server's start) and says so
    const Json after = read_claude_code_mcp_state(rig.dir.path.string()).to_json();
    CHECK(after["hasTimeout"] == true);  // added by FactorIA
    const std::string text = Rig::last_text(rig.call("engine_update_status"));
    CHECK(text.find("\"timeout\"") != std::string::npos);
    CHECK(text.find("/mcp") != std::string::npos);
    CHECK(text.find("added") != std::string::npos);
    monitor.poll();
    CHECK(rig.server.pending_tool_notices().empty());  // once
    const Json status = monitor.status();
    CHECK(status["projectConfig"]["timeoutAddedByFactoria"] == true);
    CHECK(status["projectConfig"]["clientReadsIt"] == true);
}

TEST_CASE("mcp update: a client that is not Claude Code is not told about .mcp.json") {
    Rig rig;
    write_bytes(rig.dir.path / ".mcp.json", R"({"mcpServers":{"factoria":{"command":"factoria","args":["mcp"],"timeout":1}}})");
    rig.initialize("some-other-client");
    UpdateWatch watch(rig.exe, BuildId{"0.4.0", "aaaaaaaaaaaa"});
    McpUpdateMonitor monitor(rig.server, watch, quick(rig));
    std::this_thread::sleep_for(30ms);
    write_bytes(rig.dir.path / ".mcp.json", R"({"mcpServers":{"factoria":{"command":"factoria","args":["mcp"],"timeout":2}}})");
    monitor.poll();
    CHECK(rig.server.pending_tool_notices().empty());
    CHECK(monitor.status()["projectConfig"]["clientReadsIt"] == false);
}

TEST_CASE("mcp update: .mcp.json edited after the client started is reported, an untouched one is not") {
    Rig rig;
    write_bytes(rig.dir.path / ".mcp.json", R"({"mcpServers":{"factoria":{"command":"factoria","args":["mcp"],"timeout":14400000}}})");
    rig.initialize("claude-code");
    UpdateWatch watch(rig.exe, BuildId{"0.4.0", "aaaaaaaaaaaa"});
    McpUpdateMonitor monitor(rig.server, watch, quick(rig));
    monitor.poll();
    CHECK(rig.server.pending_tool_notices().empty());  // the client read the file as it is
    std::this_thread::sleep_for(30ms);
    write_bytes(rig.dir.path / ".mcp.json", R"({"mcpServers":{"factoria":{"command":"factoria","args":["mcp"],"timeout":28800000}}})");
    monitor.poll();
    REQUIRE(rig.server.pending_tool_notices().size() == 1);
    CHECK(rig.server.pending_tool_notices()[0].find("changed after the AI client started") != std::string::npos);
    CHECK(monitor.status()["projectConfig"]["changedAfterClientStarted"] == true);
}

#if !defined(_WIN32)
namespace {
struct Pipe {
    int fds[2]{-1, -1};
    Pipe() { REQUIRE(::pipe(fds) == 0); }
    ~Pipe() {
        if (fds[0] >= 0) ::close(fds[0]);
        if (fds[1] >= 0) ::close(fds[1]);
    }
    void write(const std::string& s) { REQUIRE(::write(fds[1], s.data(), s.size()) == ssize_t(s.size())); }
    void close_write() {
        ::close(fds[1]);
        fds[1] = -1;
    }
};
std::string ping(int id) { return R"({"jsonrpc":"2.0","id":)" + std::to_string(id) + R"(,"method":"ping"})" + "\n"; }
}  // namespace

TEST_CASE("mcp stdio: the fd reader hands out lines, times out when idle and ends at the end of input") {
    Pipe p;
    auto reader = make_fd_reader(p.fds[0]);
    std::string line;
    CHECK(reader->next(line, 20ms) == LineReader::Status::Timeout);
    CHECK_FALSE(reader->holds_input());
    p.write("one\ntwo\npart");
    CHECK(reader->next(line, 1000ms) == LineReader::Status::Line);
    CHECK(line == "one");
    CHECK(reader->holds_input());  // "two" was read with it
    CHECK(reader->next(line, 1000ms) == LineReader::Status::Line);
    CHECK(line == "two");
    CHECK(reader->next(line, 20ms) == LineReader::Status::Timeout);  // "part" has no newline yet
    p.write("ial\n");
    CHECK(reader->next(line, 1000ms) == LineReader::Status::Line);
    CHECK(line == "partial");
    p.write("last without newline");
    p.close_write();
    CHECK(reader->next(line, 1000ms) == LineReader::Status::Line);
    CHECK(line == "last without newline");
    CHECK(reader->next(line, 1000ms) == LineReader::Status::Eof);
}

TEST_CASE("mcp stdio: the loop answers every message, polls while idle and ends at the end of input") {
    Rig rig;
    Pipe p;
    p.write(ping(1) + ping(2));
    p.close_write();
    auto reader = make_fd_reader(p.fds[0]);
    std::ostringstream out;
    int polls = 0;
    StdioLoopOptions opt;
    opt.poll = [&] { ++polls; };
    opt.idle = 10ms;
    CHECK(run_stdio_loop(rig.server, *reader, out, opt) == StdioExit::Eof);
    const std::string text = out.str();
    CHECK(text.find("\"id\":1") != std::string::npos);
    CHECK(text.find("\"id\":2") != std::string::npos);
    CHECK(polls >= 2);
}

TEST_CASE("mcp stdio: with no message coming the loop still polls, so an update is noticed without a request") {
    Rig rig;
    Pipe p;
    auto reader = make_fd_reader(p.fds[0]);
    std::ostringstream out;
    StdioLoopOptions opt;
    int polls = 0;
    opt.idle = 10ms;
    opt.poll = [&] { ++polls; };
    opt.restart_due = [&] { return polls >= 5; };
    CHECK(run_stdio_loop(rig.server, *reader, out, opt) == StdioExit::Restart);
    CHECK(out.str().empty());
}

TEST_CASE("mcp stdio: a request that arrives while a restart is due is not lost: the next process reads it") {
    Rig rig;
    Pipe p;
    p.write(ping(1));
    auto reader = make_fd_reader(p.fds[0]);
    std::ostringstream out;
    StdioLoopOptions opt;
    opt.idle = 10ms;
    bool due = false;
    opt.poll = [&] { due = true; };  // the executable changed
    opt.restart_due = [&] { return due; };
    // The first message is answered; the restart then happens between messages. A second message written meanwhile is not
    // read by this loop once the restart is due and no input is held: it stays in the pipe.
    CHECK(run_stdio_loop(rig.server, *reader, out, opt) == StdioExit::Restart);
    CHECK(out.str().find("\"id\":1") != std::string::npos);
    p.write(ping(2));
    // "The new process": a fresh reader over the same descriptor.
    auto next = make_fd_reader(p.fds[0]);
    std::string line;
    REQUIRE(next->next(line, 1000ms) == LineReader::Status::Line);
    CHECK(line.find("\"id\":2") != std::string::npos);
}

TEST_CASE("mcp stdio: a restart waits while the reader holds input that was not handled yet") {
    Rig rig;
    Pipe p;
    p.write(ping(1) + ping(2) + ping(3));  // three messages arrive in one read
    p.close_write();
    auto reader = make_fd_reader(p.fds[0]);
    std::ostringstream out;
    StdioLoopOptions opt;
    opt.idle = 10ms;
    opt.restart_due = [] { return true; };
    CHECK(run_stdio_loop(rig.server, *reader, out, opt) == StdioExit::Restart);
    // All three were read from the pipe, so all three are answered before the loop leaves: nothing a restart would lose.
    const std::string text = out.str();
    CHECK(text.find("\"id\":1") != std::string::npos);
    CHECK(text.find("\"id\":2") != std::string::npos);
    CHECK(text.find("\"id\":3") != std::string::npos);
}
#endif

TEST_CASE("mcp stdio: the stream reader works on any platform") {
    std::istringstream in("a\nb\n");
    auto reader = make_stream_reader(in);
    std::string line;
    CHECK(reader->next(line, 2000ms) == LineReader::Status::Line);
    CHECK(line == "a");
    CHECK(reader->next(line, 2000ms) == LineReader::Status::Line);
    CHECK(line == "b");
    CHECK(reader->next(line, 2000ms) == LineReader::Status::Eof);
}
