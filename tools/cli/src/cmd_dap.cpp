// dap: the script debugger as a Debug Adapter Protocol server on stdio (docs/DEBUGGING.md).
#include <chrono>
#include <filesystem>
#include <iostream>
#include <mutex>
#include <thread>

#if defined(_WIN32)
#include <fcntl.h>
#include <io.h>
#else
#include <unistd.h>
#endif

#include "common.h"
#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/dap/framing.h"
#include "fa/dap/server.h"
#include "fa/runtime/project.h"
#include "fa/tooling/script_instrument.h"

namespace fa::cli {

namespace {

#if defined(_WIN32)
int fd_dup(int fd) { return ::_dup(fd); }
int fd_dup2(int a, int b) { return ::_dup2(a, b); }
int fd_read(int fd, void* buf, unsigned n) { return ::_read(fd, buf, n); }
int fd_write(int fd, const void* buf, unsigned n) { return ::_write(fd, buf, n); }
void fd_binary(int fd) { ::_setmode(fd, _O_BINARY); }
#else
int fd_dup(int fd) { return ::dup(fd); }
int fd_dup2(int a, int b) { return ::dup2(a, b); }
int fd_read(int fd, void* buf, unsigned n) { return static_cast<int>(::read(fd, buf, n)); }
int fd_write(int fd, const void* buf, unsigned n) { return static_cast<int>(::write(fd, buf, n)); }
void fd_binary(int) {}
#endif

void write_all(int fd, const std::string& data) {
    std::size_t done = 0;
    while (done < data.size()) {
        int n = fd_write(fd, data.data() + done, static_cast<unsigned>(data.size() - done));
        if (n <= 0) return;  // the client went away
        done += static_cast<std::size_t>(n);
    }
}

// Runs the game the launch asked for, on the calling (main) thread. Returns the exit code.
int run_game(DapServer& server) {
    const DapLaunchArgs& L = server.launch();
    fs::set_project_root(L.projectDir);
    EngineConfig cfg = project_engine_config(L.projectDir, L.scene);
    cfg.scriptDebugger = server.debugger();
    try {
        if (L.mode == "play") {
            cfg.headless = false;
            return run_windowed(cfg);
        }
        if (L.mode == "headless") {
            apply_headless_config(cfg, false, false);
            HeadlessRunOptions ho;
            ho.frames = L.frames;
            ho.inputReplayPath = L.inputPath;
            ho.failOnScriptError = true;
            Json report = Json::object();
            int code = run_headless(cfg, ho, &report);
            if (report.is_object() && report.contains("error") && report["error"].is_string())
                server.send_output("stderr", "error: " + report["error"].get<std::string>() + "\n");
            server.send_output("console", "Ran " + std::to_string(report.value("frames", 0)) + " frames headless (exit code " +
                                              std::to_string(code) + ").\n");
            return code;
        }
        // test
        SessionOptions so;
        so.gfx = Gfx::Auto;
        so.scriptDebugger = server.debugger();
        auto session = Session::open(L.projectDir, so);
        TestReport rep = run_project_tests(session->engine(), L.filter, L.tests);
        server.send_output("console", rep.summary() + "\n");
        for (const auto& e : rep.loadErrors) server.send_output("stderr", "ERROR " + e.to_string() + "\n");
        return rep.ok() ? 0 : 1;
    } catch (const CliError& e) {
        server.send_output("stderr", std::string("error: ") + e.what() + (e.hint.empty() ? "" : "\n  hint: " + e.hint) + "\n");
        return 2;
    } catch (const std::exception& e) {
        server.send_output("stderr", std::string("error: ") + e.what() + "\n");
        return 2;
    }
}

}  // namespace

Command make_dap_command() {
    Command c;
    c.name = "dap";
    c.summary = "Run the script debugger as a Debug Adapter Protocol server on stdio (VS Code starts it).";
    c.usage = "";
    c.details =
        "stdout carries only protocol messages (Content-Length framed JSON); logs go to stderr and, as output events,\n"
        "to the client's debug console. The launch request chooses what runs: mode play | headless | test, project,\n"
        "scene, frames, input, tests, filter, stopOnEntry. See docs/DEBUGGING.md.";
    c.maxPositional = 0;
    c.examples = {"factoria dap"};
    c.run = [](Context&) {
        // The protocol gets a private copy of stdout; fd 1 itself now leads to stderr, so nothing the engine, a plugin or a
        // library prints can corrupt the stream.
        const int protoOut = fd_dup(1);
        fd_dup2(2, 1);
        fd_binary(0);
        fd_binary(protoOut);

        // Intentionally leaked: the reader thread may still be blocked in read() when the process exits.
        auto* server = new DapServer([protoOut](const Json& m) { write_all(protoOut, dap_encode(m)); }, script_instrumenter());

        add_log_sink([server](const LogEntry& e) {
            if (e.level < LogLevel::Warn || e.category == "script") return;  // script output comes through the debugger
            server->send_output("stderr", format_log_line(e) + "\n");
        });

        std::thread reader([server] {
            DapFrameReader frames;
            char buf[65536];
            for (;;) {
                int n = fd_read(0, buf, sizeof buf);
                if (n <= 0) break;
                for (auto& item : frames.feed(std::string_view(buf, static_cast<std::size_t>(n)))) {
                    if (!item.error.empty()) server->handle_protocol_error(item.error);
                    else server->handle_message(item.message);
                }
            }
            server->handle_eof();
        });
        reader.detach();

        if (!server->wait_for_start()) return 0;  // the client left (or terminated) before the game started
        const int code = run_game(*server);
        server->finish(code);
        server->wait_for_disconnect(std::chrono::seconds(3));
        return code;
    };
    return c;
}

}  // namespace fa::cli
