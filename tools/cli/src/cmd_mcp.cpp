// mcp: the Model Context Protocol server over stdio.
#include <chrono>
#include <filesystem>
#include <functional>
#include <iostream>
#include <map>
#include <mutex>

#include "common.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "fa/mcp/server.h"
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

    void poll() {
        using clock = std::chrono::steady_clock;
        auto now = clock::now();
        if (session_ && now - last_ >= std::chrono::milliseconds(200)) {
            last_ = now;
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
        "the server starts with documentation and project-creation tools only, so an AI can bootstrap a game.";
    c.maxPositional = 0;
    c.flags = {{"project", "DIR", "Project folder (default: the project containing the current directory)."},
               {"scene", "PATH", "Start scene override."},
               {"no-graphics", "", "Do not create a GPU context (game_screenshot is then unavailable)."},
               {"no-hot-reload", "", "Do not watch scripts/ and tools/ for edits."},
               {"seed", "N", "World RNG seed (default 1)."}};
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
        struct HookReset {
            ~HookReset() { set_script_check_hook(nullptr); }
        } hookReset;
        if (!dir.empty()) {
            SessionOptions so;
            so.gfx = ctx.args.has("no-graphics") ? Gfx::None : Gfx::Auto;
            so.scene = ctx.args.str("scene");
            so.seed = ctx.args.uinteger("seed", 1);
            so.hotReload = !ctx.args.has("no-hot-reload");
            session = Session::open(dir, so);
            registry = &session->registry();
            register_cli_commands(*registry, dir, &session->engine());
            install_script_check(session->engine());
            FA_INFO("mcp", "project {} ({} tools, graphics {})", dir, registry->list().size(), session->has_graphics() ? "on" : "off");
        } else {
            register_cli_commands(*registry, "", nullptr);
            FA_INFO("mcp", "no project found: serving documentation and project-creation tools only");
        }

        std::error_code ec;
        SimpleMcpHost host(*registry, dir.empty() ? fsys::current_path(ec).string() : dir);
        McpServer server(host);
        std::mutex writeMutex;
        auto write = [&](const std::string& line) {
            std::lock_guard<std::mutex> lock(writeMutex);
            ctx.out << line << '\n';
            ctx.out.flush();
        };
        server.set_notification_sink(write);
        HotReloadPoller poller(session.get(), *registry, server);

        std::string line;
        while (std::getline(ctx.in, line)) {
            if (!line.empty() && line.back() == '\r') line.pop_back();
            if (line.find_first_not_of(" \t") == std::string::npos) continue;
            poller.poll();
            if (auto response = server.handle_message(line)) write(*response);
            poller.poll();
        }
        server.set_notification_sink(nullptr);
        if (session) session->engine().scripts().set_tools_changed_callback(nullptr);
        return 0;
    };
    return c;
}

}  // namespace fa::cli
