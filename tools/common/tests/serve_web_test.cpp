// project.serve_web: the HTTP server of the web build. Everything binds 127.0.0.1 on a port the system picks, waits for a state (never
// a fixed sleep) with a generous cap, and uses a fake web player, so no browser and no emsdk are involved.
#include <doctest.h>

#include <algorithm>
#include <chrono>
#include <cstdlib>
#include <filesystem>
#include <functional>
#include <string>
#include <thread>

#include "fa/core/build_info.h"
#include "fa/core/log.h"
#include "fa/tooling/export.h"
#include "fa/tooling/net.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/serve_web.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

std::string fake_wasm() {
    std::string bytes = std::string("\0asm\1\0\0\0", 8) + "FA-BUILD-FINGERPRINT:" + build_fingerprint() + ";";
    return bytes + std::string(1008 - bytes.size(), 'w');
}

std::string fake_player(const testing::TempDir& tmp) {
    const stdfs::path dir = tmp.path / "web-player";
    testing::write_all(dir / "factoria_player.js", "// fake emscripten glue\n");
    testing::write_all(dir / "factoria_player.wasm", fake_wasm());
    return dir.string();
}

std::string make_project(const testing::TempDir& tmp) {
    const std::string dir = tmp.sub("proj");
    ScaffoldOptions so;
    so.name = "Serve Test";
    so.id = "com.example.servetest";
    auto r = create_project(dir, "2d-platformer", so);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    return dir;
}

// Polls `done` until true; a cap of 120 s is a safety net (an export takes about a second, a loaded VM a few).
bool wait_for(const std::function<bool()>& done, int capMs = 120000) {
    const auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(capMs);
    while (!done()) {
        if (std::chrono::steady_clock::now() > deadline) return false;
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
    return true;
}

struct Reply {
    int status = 0;
    std::string head, body;
    bool connected = false;
    std::string header(const std::string& name) const {  // case-insensitive, "" when absent
        std::string lowerHead = head, lowerName = name + ":";
        for (char& c : lowerHead) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
        for (char& c : lowerName) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
        const std::size_t at = lowerHead.find("\r\n" + lowerName);
        if (at == std::string::npos) return {};
        const std::size_t start = at + 2 + lowerName.size(), end = head.find("\r\n", start);
        std::string v = head.substr(start, end == std::string::npos ? std::string::npos : end - start);
        while (!v.empty() && v.front() == ' ') v.erase(v.begin());
        return v;
    }
};

// Sends `request` as is and reads until the server closes the connection.
Reply raw(int port, const std::string& request) {
    Reply r;
    net::Socket s = net::connect_loopback(static_cast<std::uint16_t>(port));
    if (s == net::kNoSocket) return r;
    r.connected = true;
    net::set_io_timeouts(s, 30000, 30000);
    net::send_all(s, request);
    std::string all;
    char buf[8192];
    std::ptrdiff_t n;
    while ((n = net::recv_some(s, buf, sizeof(buf))) > 0) all.append(buf, static_cast<std::size_t>(n));
    net::close_socket(s);
    const std::size_t split = all.find("\r\n\r\n");
    if (split == std::string::npos) return r;
    r.head = all.substr(0, split);
    r.body = all.substr(split + 4);
    if (r.head.size() > 12) r.status = std::atoi(r.head.c_str() + 9);
    return r;
}

Reply get(int port, const std::string& path) { return raw(port, "GET " + path + " HTTP/1.1\r\nHost: localhost\r\n\r\n"); }

// The token of a status url: http://127.0.0.1:<port>/<token>/
std::string token_of(const ServeWebStatus& st) {
    const std::size_t slash = st.localUrl.find('/', 8);
    return st.localUrl.substr(slash + 1, st.localUrl.size() - slash - 2);
}

struct Fixture {
    testing::TempDir tmp;
    net::SocketRuntime sockets;
    std::string proj = make_project(tmp);
    WebServer server;
    ServeWebStatus st;
    std::string token, base;
    int port = 0;
    void start(bool lan = false) {
        ServeWebOptions o;
        o.projectDir = proj;
        o.lan = lan;
        o.playerBinary = fake_player(tmp);
        o.pollMs = 50;
        auto r = server.start(o);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        st = server.wait_ready();
        REQUIRE_MESSAGE(st.state == "ready", st.error);
        token = token_of(st);
        port = st.port;
        base = "/" + token + "/";
    }
};

}  // namespace

TEST_CASE("serve web: the MIME type comes from the extension, wasm is application/wasm") {
    using serve_web_detail::mime_type;
    CHECK(mime_type("factoria_player.wasm") == "application/wasm");
    CHECK(mime_type("FACTORIA_PLAYER.WASM") == "application/wasm");
    CHECK(mime_type("index.html") == "text/html; charset=utf-8");
    CHECK(mime_type("factoria_player.js") == "text/javascript; charset=utf-8");
    CHECK(mime_type("a/b/pic.png") == "image/png");
    CHECK(mime_type("game.pak") == "application/octet-stream");
    CHECK(mime_type("noextension") == "application/octet-stream");
    CHECK(mime_type("dir.d/file") == "application/octet-stream");
}

TEST_CASE("serve web: only plain relative paths are files") {
    using serve_web_detail::safe_relative_path;
    CHECK(safe_relative_path("index.html") == std::optional<std::string>("index.html"));
    CHECK(safe_relative_path("a/b.js") == std::optional<std::string>("a/b.js"));
    CHECK(safe_relative_path("a%20b.js") == std::optional<std::string>("a b.js"));
    for (const char* bad : {"", "..", "../x", "a/../x", "a/..", "%2e%2e/x", "%2E%2E%2Fx", "..%2fx", "a%2f..%2fx", ".hidden", "a/.hidden", "a//b", "/etc/passwd",
                            "a\\b", "..\\x", "%5c", "C:/x", "a%3Ab", "a%00b", "a%0Ab", "%", "%4", "%zz", "a%252e", "x%25", "con.", "name ", "a/", "a*b", "a?b", "%2fetc"})
        CHECK_MESSAGE(!safe_relative_path(bad).has_value(), bad);
}

TEST_CASE("serve web: the net layer listens on localhost only unless asked and reports a port") {
    net::SocketRuntime runtime;
    REQUIRE(runtime.ok());
    auto l = net::listen_tcp(false);
    REQUIRE_MESSAGE(l.ok(), (l.ok() ? "" : l.error().to_string()));
    CHECK(l->port != 0);
    net::Socket c = net::connect_loopback(l->port);
    CHECK(c != net::kNoSocket);
    net::Socket accepted = net::accept_connection(l->socket);
    CHECK(accepted != net::kNoSocket);
    CHECK(net::send_all(c, "hello"));
    char buf[16];
    net::set_io_timeouts(accepted, 30000, 30000);
    CHECK(net::recv_some(accepted, buf, sizeof(buf)) == 5);
    net::close_socket(c);
    net::close_socket(accepted);
    net::close_socket(l->socket);
}

TEST_CASE("serve web: the first export is served under a random token and nothing else answers") {
    Fixture f;
    f.start();
    CHECK(f.st.localUrl.rfind("http://127.0.0.1:", 0) == 0);
    CHECK(f.token.size() == 32);
    CHECK(f.st.version == 1);
    CHECK(f.st.lanUrls.empty());
    // The export folder is below the project's build/ and the real export folder is untouched.
    CHECK(f.st.outputDir.find("build/serve-web/") != std::string::npos);

    Reply page = get(f.port, f.base);
    REQUIRE(page.status == 200);
    CHECK(page.header("Content-Type") == "text/html; charset=utf-8");
    CHECK(page.body.find("window.__faServe={version:1}") != std::string::npos);
    CHECK(page.body.find("__fa/client.js") != std::string::npos);
    CHECK(page.body.find("<title>Serve Test</title>") != std::string::npos);
    CHECK(std::stoul(page.header("Content-Length")) == page.body.size());

    Reply wasm = get(f.port, f.base + "factoria_player.wasm");
    CHECK(wasm.status == 200);
    CHECK(wasm.header("Content-Type") == "application/wasm");
    CHECK(wasm.body == fake_wasm());
    Reply js = get(f.port, f.base + "factoria_player.js");
    CHECK(js.status == 200);
    CHECK(js.body == "// fake emscripten glue\n");
    Reply pak = get(f.port, f.base + "game.pak");
    CHECK(pak.status == 200);
    CHECK(pak.header("Content-Type") == "application/octet-stream");
    CHECK(pak.body.size() > 0);
    Reply head = raw(f.port, "HEAD " + f.base + "factoria_player.wasm HTTP/1.1\r\nHost: x\r\n\r\n");
    CHECK(head.status == 200);
    CHECK(head.header("Content-Length") == "1008");
    CHECK(head.body.empty());
    CHECK(get(f.port, f.base + "missing.png").status == 404);
    CHECK(get(f.port, "/" + f.token).status == 301);  // without the closing slash the page's relative URLs would break
    CHECK(get(f.port, "/" + f.token).header("Location") == f.base);

    // No token, a wrong token, a prefix of the token, the token with something appended: the same 404.
    CHECK(get(f.port, "/").status == 404);
    CHECK(get(f.port, "/index.html").status == 404);
    CHECK(get(f.port, "/" + std::string(32, '0') + "/").status == 404);
    CHECK(get(f.port, "/" + f.token.substr(0, 31) + "/").status == 404);
    CHECK(get(f.port, "/" + f.token + "x/").status == 404);
    CHECK(get(f.port, "/" + f.token + "x").status == 404);
    CHECK(get(f.port, "/__fa/version").status == 404);
    CHECK(get(f.port, f.base + "__fa/version").status == 200);
    CHECK(get(f.port, "/" + f.token.substr(0, 31) + "/__fa/version").status == 404);
    CHECK(raw(f.port, "POST /__fa/log HTTP/1.1\r\nContent-Length: 2\r\n\r\n[]").status == 404);
    CHECK(raw(f.port, "DELETE " + f.base + " HTTP/1.1\r\n\r\n").status == 405);
    CHECK(raw(f.port, "GET HTTP/1.1\r\n\r\n").status == 400);
    CHECK(raw(f.port, "GET " + f.base + " SMTP/1.0\r\n\r\n").status == 400);
}

TEST_CASE("serve web: a path cannot leave the export folder") {
    Fixture f;
    f.start();
    // The marker file the export keeps, a file of the project, and a file next to the export folder: none is served by any spelling.
    testing::write_all(stdfs::path(f.st.outputDir).parent_path() / "secret.txt", "secret");
    for (const char* target : {"factoria.json", "../factoria.json", "../../factoria.json", "../../../factoria.json", "..%2ffactoria.json", "%2e%2e/factoria.json",
                               "%2E%2E%2Ffactoria.json", "..%5cfactoria.json", "%2e%2e%5cfactoria.json", "....//factoria.json", "..;/factoria.json",
                               "%252e%252e/factoria.json", "/etc/passwd", "%2fetc%2fpasswd", "C:/Windows/win.ini", "C%3A/Windows/win.ini",
                               ".factoria-export", "./index.html", "a/./index.html", "index.html/..", "../secret.txt", "..\\secret.txt", "%00", "index.html%00.png",
                               "index.html.", "index.html%20", "INDEX.HTML::$DATA"}) {
        Reply r = get(f.port, f.base + target);
        CHECK_MESSAGE(r.status != 200, target);
        CHECK_MESSAGE(r.body.find("secret") == std::string::npos, target);
        CHECK_MESSAGE(r.body.find("\"name\"") == std::string::npos, target);
    }
    // An absolute-form request target and a target without the leading slash are not paths below the token either.
    CHECK(raw(f.port, "GET http://127.0.0.1/" + f.token + "/ HTTP/1.1\r\n\r\n").status == 400);
    CHECK(raw(f.port, "GET " + f.token + "/ HTTP/1.1\r\n\r\n").status == 400);
    CHECK(raw(f.port, "GET " + f.base + "../../factoria.json HTTP/1.1\r\nHost: x\r\n\r\n").status == 404);
}

TEST_CASE("serve web: the request is bounded") {
    Fixture f;
    f.start();
    // A head over 8 KB.
    CHECK(raw(f.port, "GET " + f.base + " HTTP/1.1\r\nX-Pad: " + std::string(20000, 'a') + "\r\n\r\n").status == 431);
    // A log body announced over 16 KB is refused before it is read.
    CHECK(raw(f.port, "POST " + f.base + "__fa/log HTTP/1.1\r\nContent-Length: 100000\r\n\r\n").status == 413);
    CHECK(raw(f.port, "POST " + f.base + "__fa/log HTTP/1.1\r\nContent-Length: abc\r\n\r\n").status == 400);
    CHECK(raw(f.port, "POST " + f.base + "__fa/log HTTP/1.1\r\nContent-Length: 99999999999999999999\r\n\r\n").status == 400);
    CHECK(raw(f.port, "POST " + f.base + "__fa/log HTTP/1.1\r\nContent-Length: 5\r\n\r\nnojson").status == 400);
    CHECK(raw(f.port, "POST " + f.base + "__fa/log HTTP/1.1\r\nContent-Length: 2\r\n\r\n{}").status == 400);
    CHECK(raw(f.port, "POST " + f.base + "index.html HTTP/1.1\r\nContent-Length: 0\r\n\r\n").status == 405);
    // Idle connections hold a worker each, but fewer than the pool: a request is still answered.
    std::vector<net::Socket> idle;
    for (int i = 0; i < 4; ++i) idle.push_back(net::connect_loopback(static_cast<std::uint16_t>(f.port)));
    CHECK(get(f.port, f.base).status == 200);
    for (net::Socket s : idle) net::close_socket(s);
}

TEST_CASE("serve web: what the page logs comes back as log lines of category phone") {
    Fixture f;
    f.start();
    const std::uint64_t before = f.server.status().phoneLogLines;
    const auto after = recent_logs(1, LogLevel::Trace);
    const std::uint64_t seq = after.empty() ? 0 : after.back().seq;
    const std::string body = R"([{"l":"error","t":"boom from the phone"},{"l":"warn","t":"careful"},{"l":"log","t":"line\u0001with control"},{"l":"info"}])";
    Reply r = raw(f.port, "POST " + f.base + "__fa/log HTTP/1.1\r\nContent-Length: " + std::to_string(body.size()) + "\r\n\r\n" + body);
    CHECK(r.status == 204);
    CHECK(f.server.status().phoneLogLines == before + 3);  // the entry without text is skipped
    bool error = false, warn = false, control = false;
    for (const LogEntry& e : recent_logs(200, LogLevel::Trace, seq)) {
        if (e.category != "phone") continue;
        if (e.message == "boom from the phone") error = e.level == LogLevel::Error;
        if (e.message == "careful") warn = e.level == LogLevel::Warn;
        if (e.message == "line with control") control = true;
    }
    CHECK(error);
    CHECK(warn);
    CHECK(control);  // control characters cannot forge a second log line
    Reply js = get(f.port, f.base + "__fa/client.js");
    CHECK(js.status == 200);
    CHECK(js.header("Content-Type") == "text/javascript; charset=utf-8");
    CHECK(js.body.find("__fa/log") != std::string::npos);
    CHECK(js.body.find("__fa/version") != std::string::npos);
}

TEST_CASE("serve web: a changed file exports again and the version moves, which is what reloads the page") {
    Fixture f;
    f.start();
    Reply v1 = get(f.port, f.base + "__fa/version");
    REQUIRE(v1.status == 200);
    auto j1 = Json::parse(v1.body);
    CHECK(j1["version"].get<int>() == 1);
    CHECK(j1["state"].get<std::string>() == "ready");

    testing::write_all(stdfs::path(f.proj) / "assets" / "live.txt", "first version of the file");
    REQUIRE(wait_for([&] { return f.server.status().version >= 2; }));
    REQUIRE(wait_for([&] { return f.server.status().state == "ready"; }));
    auto j2 = Json::parse(get(f.port, f.base + "__fa/version").body);
    CHECK(j2["version"].get<int>() >= 2);
    CHECK(get(f.port, f.base).body.find("window.__faServe={version:" + std::to_string(j2["version"].get<int>()) + "}") != std::string::npos);
    CHECK(get(f.port, f.base + "factoria_player.wasm").status == 200);  // the other folder serves just as well after the switch

    // Nothing changed: the version stays.
    const std::uint64_t stable = f.server.status().version;
    f.server.refresh();
    std::this_thread::sleep_for(std::chrono::milliseconds(400));
    CHECK(f.server.status().version == stable);

    // A project that cannot be exported keeps the last good build and says why.
    testing::write_all(stdfs::path(f.proj) / "factoria.json", "{ not json");
    REQUIRE(wait_for([&] { return f.server.status().state == "failed"; }));
    CHECK_FALSE(f.server.status().error.empty());
    CHECK(get(f.port, f.base + "factoria_player.wasm").status == 200);
    CHECK(Json::parse(get(f.port, f.base + "__fa/version").body)["state"].get<std::string>() == "failed");
}

TEST_CASE("serve web: stop closes the listener and the pages, and a second stop is harmless") {
    Fixture f;
    f.start();
    const int port = f.port;
    CHECK(f.server.running());
    f.server.stop();
    CHECK_FALSE(f.server.running());
    CHECK_FALSE(f.server.status().running);
    CHECK(f.server.status().state == "stopped");
    CHECK_FALSE(raw(port, "GET / HTTP/1.1\r\n\r\n").connected);
    f.server.stop();
    // And it can start again, with another port and token.
    f.start();
    CHECK(f.server.running());
    CHECK(f.token.size() == 32);
}

TEST_CASE("serve web: lan listens on every interface and lists the private addresses") {
    Fixture f;
    f.start(true);
    CHECK(f.st.lan);
    for (const std::string& u : f.st.lanUrls) {
        CHECK(u.rfind("http://", 0) == 0);
        CHECK(u.find("/" + f.token + "/") != std::string::npos);
        CHECK(u.find("127.0.0.1") == std::string::npos);
    }
    if (f.st.lanUrls.empty()) CHECK_FALSE(f.st.warnings.empty());  // it says so instead of showing a URL that cannot work
    CHECK(get(f.port, f.base).status == 200);
    auto j = f.st.to_json();
    CHECK(j["lan"].get<bool>());
    CHECK(j.contains("urls"));
}

TEST_CASE("serve web: without the web player the error says how to get it, and nothing listens") {
    testing::TempDir tmp;
    net::SocketRuntime sockets;
    const std::string proj = make_project(tmp);
    WebServer server;
    ServeWebOptions o;
    o.projectDir = proj;
    o.playerBinary = tmp.sub("no-player-here");
    auto r = server.start(o);
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("not found") != std::string::npos);
    CHECK_FALSE(server.running());

    ServeWebOptions notAProject;
    notAProject.projectDir = tmp.sub("empty");
    auto r2 = server.start(notAProject);
    REQUIRE_FALSE(r2.ok());
    CHECK(r2.error().message.find("factoria.json") != std::string::npos);
}

TEST_CASE("serve web: the command starts, reuses, restarts and stops the process's server") {
    testing::TempDir tmp;
    const std::string proj = make_project(tmp);
    const std::string player = fake_player(tmp);
    CommandRegistry reg;
    register_serve_web_commands(reg, proj);
    const CommandInfo* info = reg.info("project.serve_web");
    REQUIRE(info != nullptr);
    for (const char* arg : {"lan", "stop", "player", "allowPlayerMismatch"}) {
        REQUIRE(info->inputSchema["properties"].contains(arg));
        CHECK_FALSE(info->inputSchema["properties"][arg]["description"].get<std::string>().empty());
    }
    web_server().stop();

    auto started = reg.call("project.serve_web", Json::object({{"player", player}}));
    REQUIRE_MESSAGE(started.ok, started.error.dump());
    CHECK(started.result["running"].get<bool>());
    CHECK(started.result["state"].get<std::string>() == "ready");
    const std::string url = started.result["url"].get<std::string>();
    CHECK(url.rfind("http://127.0.0.1:", 0) == 0);
    CHECK_FALSE(started.result["lan"].get<bool>());

    auto again = reg.call("project.serve_web", Json::object({{"player", player}}));
    REQUIRE_MESSAGE(again.ok, again.error.dump());
    CHECK(again.result["url"].get<std::string>() == url);  // same project, same lan: the same server

    auto lan = reg.call("project.serve_web", Json::object({{"lan", true}, {"player", player}}));
    REQUIRE_MESSAGE(lan.ok, lan.error.dump());
    CHECK(lan.result["lan"].get<bool>());
    CHECK(lan.result["url"].get<std::string>() != url);  // another lan: restarted, new port and token

    auto both = reg.call("project.serve_web", Json::object({{"stop", true}, {"lan", true}}));
    REQUIRE_FALSE(both.ok);
    CHECK(both.error.dump().find("/stop") != std::string::npos);
    CHECK(web_server().running());  // refused before it did anything

    auto stopped = reg.call("project.serve_web", Json::object({{"stop", true}}));
    REQUIRE_MESSAGE(stopped.ok, stopped.error.dump());
    CHECK_FALSE(stopped.result["running"].get<bool>());
    CHECK(stopped.result["stopped"].get<bool>());
    CHECK_FALSE(web_server().running());
    auto stoppedAgain = reg.call("project.serve_web", Json::object({{"stop", true}}));
    REQUIRE(stoppedAgain.ok);
    CHECK_FALSE(stoppedAgain.result["stopped"].get<bool>());

    auto unknown = reg.call("project.serve_web", Json::object({{"port", 80}}));
    CHECK_FALSE(unknown.ok);  // closed schema: no way to pick the port
    auto noPlayer = reg.call("project.serve_web", Json::object({{"player", tmp.sub("nowhere")}}));
    REQUIRE_FALSE(noPlayer.ok);
    CHECK_FALSE(web_server().running());
}
