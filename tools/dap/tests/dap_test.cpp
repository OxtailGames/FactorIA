#include <doctest.h>

#include <filesystem>
#include <fstream>

#include "fa/dap/framing.h"
#include "fa/dap/server.h"
#include "fa/tooling/script_instrument.h"

using namespace fa;
namespace fsys = std::filesystem;

namespace {

struct TempProject {
    fsys::path dir;
    TempProject() {
        dir = fsys::temp_directory_path() / ("fa_dap_doctest_" + std::to_string(reinterpret_cast<std::uintptr_t>(this)));
        fsys::remove_all(dir);
        fsys::create_directories(dir / "scripts");
        std::ofstream(dir / "factoria.json") << "{}";
        std::ofstream(dir / "scripts" / "a.js") << "export function f(x) {\n  let y = x + 1;\n  return y;\n}\n";
        std::ofstream(dir / "notes.txt") << "hi";
    }
    ~TempProject() {
        std::error_code ec;
        fsys::remove_all(dir, ec);
    }
};

struct Capture {
    std::vector<Json> out;
    DapServer::Sink sink() {
        return [this](const Json& m) { out.push_back(m); };
    }
    const Json* response(int seq) const {
        for (const Json& m : out)
            if (m.value("type", "") == "response" && m.value("request_seq", 0) == seq) return &m;
        return nullptr;
    }
    bool has_event(const std::string& name) const {
        for (const Json& m : out)
            if (m.value("event", "") == name) return true;
        return false;
    }
};

Json request(int seq, const std::string& command, Json args = Json::object()) {
    return Json::object({{"seq", seq}, {"type", "request"}, {"command", command}, {"arguments", std::move(args)}});
}

}  // namespace

TEST_CASE("dap framing: one message round-trips") {
    Json m = Json::object({{"seq", 1}, {"type", "request"}, {"command", "threads"}});
    std::string wire = dap_encode(m);
    CHECK(wire.rfind("Content-Length: ", 0) == 0);
    DapFrameReader r;
    auto items = r.feed(wire);
    REQUIRE(items.size() == 1);
    CHECK(items[0].error.empty());
    CHECK(items[0].message == m);
}

TEST_CASE("dap framing: partial reads, one byte at a time") {
    Json a = Json::object({{"seq", 1}, {"text", "h\xC3\xA9llo"}});  // multi-byte UTF-8: length is in bytes
    std::string wire = dap_encode(a);
    DapFrameReader r;
    std::vector<DapFrameReader::Item> all;
    for (char c : wire)
        for (auto& it : r.feed(std::string_view(&c, 1))) all.push_back(it);
    REQUIRE(all.size() == 1);
    CHECK(all[0].message == a);
    CHECK(r.pending() == 0);
}

TEST_CASE("dap framing: several messages in one buffer, then a split header") {
    std::string wire = dap_encode(Json::object({{"n", 1}})) + dap_encode(Json::object({{"n", 2}})) + dap_encode(Json::object({{"n", 3}}));
    DapFrameReader r;
    std::size_t cut = wire.size() - 5;
    auto first = r.feed(std::string_view(wire).substr(0, cut));
    CHECK(first.size() == 2);
    auto second = r.feed(std::string_view(wire).substr(cut));
    REQUIRE(second.size() == 1);
    CHECK(second[0].message["n"] == 3);
}

TEST_CASE("dap framing: bad headers and bodies are reported and skipped") {
    DapFrameReader r;
    std::string good = dap_encode(Json::object({{"ok", true}}));
    auto items = r.feed("Content-Length: abc\r\n\r\n" + good);
    REQUIRE(items.size() == 2);
    CHECK(items[0].error.find("not a whole number") != std::string::npos);
    CHECK(items[1].message["ok"] == true);

    items = r.feed("X-Other: 1\r\n\r\n" + good);
    REQUIRE(items.size() == 2);
    CHECK(items[0].error.find("no Content-Length") != std::string::npos);
    CHECK(items[1].error.empty());

    items = r.feed("Content-Length: 5\r\n\r\n{nope" + good);
    REQUIRE(items.size() == 2);
    CHECK(items[0].error.find("not valid JSON") != std::string::npos);
    CHECK(items[1].error.empty());

    items = r.feed("content-length: 999999999999\r\n\r\n");
    REQUIRE(items.size() == 1);
    CHECK(items[0].error.find("larger than") != std::string::npos);

    items = r.feed("garbage line without colon\r\n\r\n");
    REQUIRE(items.size() == 1);
    CHECK(items[0].error.find("has no ':'") != std::string::npos);
}

TEST_CASE("dap launch: defaults, VS Code keys and every declared attribute are accepted") {
    TempProject p;
    Json a = Json::object({{"type", "factoria"}, {"request", "launch"}, {"name", "x"}, {"mode", "headless"}, {"project", p.dir.string()},
                           {"frames", 12}, {"stopOnEntry", true}, {"factoriaPath", "/x/factoria"}, {"noDebug", false},
                           {"__sessionId", "1"}, {"__configurationTarget", 5}, {"presentation", Json::object()}, {"preLaunchTask", "b"},
                           {"postDebugTask", "c"}, {"internalConsoleOptions", "neverOpen"}, {"debugServer", 4711},
                           {"suppressMultipleSessionWarning", true}});
    auto r = parse_dap_launch(a, ".");
    REQUIRE(r.ok());
    CHECK(r->mode == "headless");
    CHECK(r->frames == 12);
    CHECK(r->stopOnEntry);

    auto d = parse_dap_launch(Json::object({{"project", p.dir.string()}}), ".");
    REQUIRE(d.ok());
    CHECK(d->mode == "play");
    CHECK(d->frames == 600);
}

TEST_CASE("dap launch: errors teach") {
    TempProject p;
    const std::string proj = p.dir.string();
    auto key = parse_dap_launch(Json::object({{"moed", "play"}, {"project", proj}}), ".");
    REQUIRE_FALSE(key.ok());
    CHECK(key.error().message.find("'moed'") != std::string::npos);
    CHECK(key.error().hint.find("Did you mean 'mode'") != std::string::npos);

    auto mode = parse_dap_launch(Json::object({{"mode", "headles"}, {"project", proj}}), ".");
    REQUIRE_FALSE(mode.ok());
    CHECK(mode.error().hint.find("Did you mean 'headless'") != std::string::npos);

    auto frames = parse_dap_launch(Json::object({{"mode", "headless"}, {"frames", "many"}, {"project", proj}}), ".");
    REQUIRE_FALSE(frames.ok());
    CHECK(frames.error().message.find("frames") != std::string::npos);

    auto wrongMode = parse_dap_launch(Json::object({{"mode", "play"}, {"frames", 5}, {"project", proj}}), ".");
    REQUIRE_FALSE(wrongMode.ok());
    CHECK(wrongMode.error().message.find("only applies to mode \"headless\"") != std::string::npos);

    auto notProject = parse_dap_launch(Json::object({{"project", (p.dir / "scripts").string()}}), ".");
    REQUIRE_FALSE(notProject.ok());
    CHECK(notProject.error().message.find("not a FactorIA project") != std::string::npos);

    auto input = parse_dap_launch(Json::object({{"mode", "headless"}, {"input", "missing.json"}, {"project", proj}}), ".");
    REQUIRE_FALSE(input.ok());
    CHECK(input.error().message.find("Looked in") != std::string::npos);
}

TEST_CASE("dap server: initialize, launch errors, requests before launch") {
    Capture cap;
    DapServer s(cap.sink(), script_instrumenter());
    s.handle_message(request(1, "initialize", Json::object({{"adapterID", "factoria"}})));
    const Json* r = cap.response(1);
    REQUIRE(r);
    CHECK((*r)["body"]["supportsLogPoints"] == true);
    CHECK((*r)["body"]["exceptionBreakpointFilters"].size() == 2);
    CHECK(cap.has_event("initialized"));

    s.handle_message(request(2, "threads"));
    CHECK((*cap.response(2))["body"]["threads"][0]["id"] == 1);

    s.handle_message(request(3, "bogusRequest"));
    CHECK((*cap.response(3))["success"] == false);
    CHECK((*cap.response(3))["message"].get<std::string>().find("does not support") != std::string::npos);

    s.handle_message(request(4, "stackTrace"));  // not stopped: an empty stack, not an error
    CHECK((*cap.response(4))["success"] == true);
    s.handle_message(request(5, "scopes", Json::object({{"frameId", 1}})));
    CHECK((*cap.response(5))["success"] == false);

    s.handle_message(request(6, "launch", Json::object({{"mode", "headles"}})));
    CHECK((*cap.response(6))["success"] == false);
    CHECK((*cap.response(6))["message"].get<std::string>().find("Did you mean 'headless'") != std::string::npos);

    s.handle_message(Json::object({{"type", "event"}}));  // not a request: reported, not fatal
    CHECK(cap.has_event("output"));
}

TEST_CASE("dap server: paths map to project-relative modules; outside the project is unverified") {
    TempProject p;
    Capture cap;
    DapServer s(cap.sink(), script_instrumenter());
    s.handle_message(request(1, "initialize"));
    // setBreakpoints before launch is answered when the launch is handled
    const std::string a = (p.dir / "scripts" / "a.js").string();
    s.handle_message(request(2, "setBreakpoints", Json::object({{"source", Json::object({{"path", a}})}, {"breakpoints", Json::array({Json::object({{"line", 3}})})}})));
    CHECK(cap.response(2) == nullptr);
    s.handle_message(request(3, "launch", Json::object({{"mode", "headless"}, {"project", p.dir.string()}})));
    REQUIRE(cap.response(3));
    CHECK((*cap.response(3))["success"] == true);
    const Json* bp = cap.response(2);
    REQUIRE(bp);
    CHECK((*bp)["body"]["breakpoints"][0]["verified"] == true);
    CHECK((*bp)["body"]["breakpoints"][0]["line"] == 3);

    std::string why;
    CHECK(s.module_name(a, why) == "scripts/a.js");
    CHECK(s.module_name((p.dir / "scripts" / ".." / "scripts" / "a.js").string(), why) == "scripts/a.js");
    CHECK(s.module_name((p.dir / "notes.txt").string(), why).empty());
    CHECK(why.find("not a JavaScript module") != std::string::npos);
    CHECK(s.module_name((fsys::temp_directory_path() / "elsewhere.js").string(), why).empty());
    CHECK(why.find("outside the project") != std::string::npos);
#if defined(_WIN32) || defined(__APPLE__)
    CHECK(s.module_name((p.dir / "SCRIPTS" / "A.JS").string(), why) == "scripts/a.js");
#endif
    CHECK(fsys::path(s.absolute_path("scripts/a.js")).filename() == "a.js");

    s.handle_message(request(4, "setBreakpoints", Json::object({{"source", Json::object({{"path", (p.dir / "notes.txt").string()}})},
                                                                 {"breakpoints", Json::array({Json::object({{"line", 1}})})}})));
    const Json* out = cap.response(4);
    REQUIRE(out);
    CHECK((*out)["body"]["breakpoints"][0]["verified"] == false);
    CHECK((*out)["body"]["breakpoints"][0]["message"].get<std::string>().size() > 10);
}
