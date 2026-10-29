// mcp: the Model Context Protocol server over stdio.
#include <chrono>
#include <filesystem>
#include <functional>
#include <iostream>
#include <map>
#include <mutex>

#include "common.h"
#include "fa/ai/session.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "fa/mcp/server.h"
#include "fa/mcp/stdio.h"
#include "fa/mcp/update_monitor.h"
#include "fa/tooling/self_update.h"
#include "fa/tooling/validate.h"

namespace fa::cli {

namespace fsys = std::filesystem;

namespace {

// Polls scripts/tools for edits (hot reload while the server is idle) and detects changes of the
// command list so clients get notifications/tools/list_changed.
class HotReloadPoller {
public:
    HotReloadPoller(Session* session, CommandRegistry& registry, McpServer& server)
        : session_(session), registry_(registry), server_(server) {
        if (session_) {
            scan(false);
            session_->engine().scripts().set_tools_changed_callback([this]() { toolsDirty_ = true; });
        }
        signature_ = tools_signature();
    }

    // `now`: look at the files right now (before a request: the client may have just written a tool); otherwise at most every 200 ms.
    void poll(bool now = false) {
        using clock = std::chrono::steady_clock;
        auto at = clock::now();
        if (session_ && (now || at - last_ >= std::chrono::milliseconds(200))) {
            last_ = at;
            scan(true);
        }
        std::string sig = tools_signature();
        if (sig != signature_ || toolsDirty_) {
            toolsDirty_ = false;
            signature_ = std::move(sig);
            if (server_.initialized()) server_.notify_tools_changed();
        }
    }

private:
    std::string tools_signature() const {
        std::string s;
        for (const CommandInfo* i : registry_.list()) {
            s += i->name;
            s += '|';
            s += i->summary;
            s += '|';
            s += i->readOnly ? 'r' : 'w';
            s += '|';
            s += std::to_string(std::hash<std::string>{}(i->inputSchema.dump()));
            s += '\n';
        }
        return s;
    }

    void scan(bool reload) {
        const fsys::path root = session_->project_dir();
        std::map<std::string, fsys::file_time_type> now;
        std::error_code ec;
        for (const char* sub : {"scripts", "tools"}) {
            fsys::path dir = root / sub;
            if (!fsys::is_directory(dir, ec)) continue;
            for (fsys::recursive_directory_iterator it(dir, fsys::directory_options::skip_permission_denied, ec), end; !ec && it != end;
                 it.increment(ec)) {
                if (!it->is_regular_file(ec) || it->path().extension() != ".js") continue;
                now[fsys::relative(it->path(), root, ec).generic_string()] = it->last_write_time(ec);
            }
        }
        if (reload) {
            for (const auto& [path, t] : now) {
                auto old = known_.find(path);
                if (old == known_.end() || old->second != t) reload_module(path);
            }
            for (const auto& [path, t] : known_)
                if (!now.count(path)) reload_module(path);
        }
        known_ = std::move(now);
    }

    void reload_module(const std::string& path) {
        try {
            FA_INFO("mcp", "reloading {}", path);
            if (starts_with(path, "tools/")) session_->engine().scripts().reload_tools();
            else session_->engine().scripts().reload_module(path);
        } catch (const std::exception& e) {
            FA_WARN("mcp", "reload of {} failed: {}", path, e.what());
        }
    }

    Session* session_;
    CommandRegistry& registry_;
    McpServer& server_;
    std::map<std::string, fsys::file_time_type> known_;
    std::chrono::steady_clock::time_point last_{};
    std::string signature_;
    bool toolsDirty_ = false;
};

// The command line the restarted process runs: `factoria mcp` with the flags this one was given (as parsed, so the same
// meaning whatever the order) plus the hand-over.
std::vector<std::string> restart_argv(const Context& ctx, const std::string& exe, const McpResume& resume) {
    std::vector<std::string> argv = {exe, "mcp"};
    for (const auto& [name, values] : ctx.args.flags_) {
        if (name == "resume-session") continue;
        bool boolean = false;
        if (ctx.cmd)
            for (const FlagSpec& spec : ctx.cmd->flags)
                if (spec.name == name) boolean = spec.value.empty();
        for (const std::string& v : values) {
            argv.push_back("--" + name);
            if (!boolean) argv.push_back(v);
        }
    }
    argv.push_back("--resume-session");
    argv.push_back(resume.to_string());
    return argv;
}

}  // namespace

Command make_mcp_command() {
    Command c;
    c.name = "mcp";
    c.summary = "Run the MCP server on stdio so AI clients (Claude Code, Codex, ...) can drive the engine.";
    c.usage = "[--project DIR]";
    c.details =
        "stdout carries only protocol messages (newline-delimited JSON-RPC); logs go to stderr. Every engine\n"
        "command becomes a tool (scene.spawn -> scene_spawn); docs and project files are resources. Scripts and\n"
        "project tools hot-reload and clients are notified. Without a project (none in the current directory)\n"
        "the server starts with documentation and project-creation tools only, so an AI can bootstrap a game.\n"
        "When the factoria file is replaced by a newer one while the server runs, it restarts itself in place between two\n"
        "messages (Linux, macOS; on Windows it tells the AI to reconnect) and the first tool result says so (docs/MCP.md).";
    c.maxPositional = 0;
    c.flags = {{"project", "DIR", "Project folder (default: the project containing the current directory)."},
               {"scene", "PATH", "Start scene override."},
               {"no-graphics", "", "Do not create a GPU context (game_screenshot is then unavailable)."},
               {"no-hot-reload", "", "Do not watch scripts/ and tools/ for edits."},
               {"render-all", "", "Draw every frame (default: only when game_screenshot asks)."},
               {"persist-storage", "", "Let scripts' storage.* use the real save file (default: in memory)."},
               {"seed", "N", "World RNG seed (default 1)."},
               kDateFlag,
               {"read-only", "",
                "Serve only the commands that look and play (read-only ones plus game_step/input/click, scene_load, ...): "
                "the art critic and reviewer agents run this way."},
               {"resume-session", "JSON", "Internal: the hand-over from the server that restarted itself after an update.", false, true}};
    c.examples = {"factoria mcp --project games/my-game",
                  "claude mcp add factoria -- factoria mcp --project .",
                  "printf '%s\\n' '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/list\"}' | factoria mcp --project ."};
    c.run = [](Context& ctx) {
        std::string dir = find_project_dir_or_empty(ctx, 99);
        if (!dir.empty() && !fsys::exists(fsys::path(dir) / kProjectFileName))
            throw CliError("'" + dir + "' is not a FactorIA project: " + kProjectFileName + " not found.",
                           "Pass --project <folder containing factoria.json>, or create one with 'factoria new <dir>'.");
        std::unique_ptr<Session> session;
        CommandRegistry standalone;
        CommandRegistry* registry = &standalone;
        if (!dir.empty()) {
            SessionOptions so;
            so.gfx = ctx.args.has("no-graphics") ? Gfx::None : Gfx::Auto;
            so.scene = ctx.args.str("scene");
            so.seed = ctx.args.uinteger("seed", 1);
            so.date = date_flag(ctx.args);
            so.hotReload = !ctx.args.has("no-hot-reload");
            so.renderMode = ctx.args.has("render-all") ? RenderMode::Always : RenderMode::OnDemand;
            so.memoryStorage = !ctx.args.has("persist-storage");
            session = Session::open(dir, so);
            registry = &session->registry();
            register_cli_commands(*registry, dir, &session->engine());
            FA_INFO("mcp", "project {} ({} tools, graphics {})", dir, registry->list().size(), session->has_graphics() ? "on" : "off");
        } else {
            register_cli_commands(*registry, "", nullptr);
            FA_INFO("mcp", "no project found: serving documentation and project-creation tools only");
        }

        McpResume resume;
        const bool resumed = ctx.args.has("resume-session");
        if (resumed) {
            auto parsed = McpResume::parse(ctx.args.str("resume-session"));
            if (!parsed) throw UsageError(parsed.error().message, parsed.error().hint);
            resume = *parsed;
        }

        std::error_code ec;
        SimpleMcpHost host(*registry, dir.empty() ? fsys::current_path(ec).string() : dir);
        McpServer server(host);
        if (ctx.args.has("read-only"))
            server.set_command_filter([](const CommandInfo& info) { return ai::is_read_only_tool(info); });
        HotReloadPoller poller(session.get(), *registry, server);

        // Out of date? The executable replaced on disk, or an older .mcp.json than the client started with (docs/MCP.md).
        McpUpdateOptions uo;
        uo.projectDir = dir;
        Engine* engine = session ? &session->engine() : nullptr;
        uo.lost_on_restart = [engine]() -> std::string {
            if (!engine || engine->frame_index() == 0) return {};
            return "the game session (it had run " + std::to_string(engine->frame_index()) +
                   " frames) starts again from the project's start scene, so any scene edit that was not saved to disk "
                   "(scene_save) and the frames stepped are gone";
        };
        McpUpdateMonitor monitor(server, process_update_watch(), uo, resumed ? &resume : nullptr);
        set_update_status_extra("mcp", [&monitor] { return monitor.status(); });
        monitor.announce_resume();

        // POSIX reads fd 0 itself (exact: no message is read ahead of the one handled, which a restart in place needs);
        // the tests give the command their own streams.
        std::unique_ptr<LineReader> reader =
            &ctx.in == &std::cin ? make_stdin_reader() : make_stream_reader(ctx.in);
        StdioLoopOptions lo;
        lo.poll = [&] {
            poller.poll();
            monitor.poll();
        };
        lo.before_message = [&] {
            poller.poll(true);
            monitor.poll();
        };
        lo.restart_due = [&] { return monitor.restart_due(); };
        for (;;) {
            if (run_stdio_loop(server, *reader, ctx.out, lo) == StdioExit::Eof) break;
            // The executable on disk is another build and the server is idle: become it. stdin and stdout are the client's
            // and stay open; what is still unread in the pipe is read by the new process. No tidying up first: if the new
            // file cannot be started this process must still be able to serve, and the operating system frees the rest.
            const McpResume next = monitor.resume_state();
            const std::string exe = next.executable.empty() ? process_update_watch().executable().string() : next.executable;
            FA_INFO("mcp", "restarting in place: {} -> {}", process_update_watch().running().label(),
                    process_update_watch().on_disk().label());
            ctx.out.flush();
            auto r = restart_process(exe, restart_argv(ctx, exe, next));
            FA_WARN("mcp", "{}", r.error().to_string());  // only here when exec failed
            monitor.restart_failed(r.error().message);
        }
        set_update_status_extra("mcp", nullptr);
        if (session) session->engine().scripts().set_tools_changed_callback(nullptr);
        return 0;
    };
    return c;
}

}  // namespace fa::cli
