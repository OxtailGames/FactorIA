// An MCP server that notices it is out of date (docs/MCP.md, "After an update").
//
// `factoria mcp` is started by an AI client from the project's `.mcp.json` and runs for as long as the client does. Two things
// can make it stale while it runs, and neither is the client's doing:
//  1. The `factoria` file was replaced (a new FactorIA copied over the old one). On Linux and macOS the server then restarts
//     itself in place, between two messages: it executes the new file with the same stdin and stdout, handing over what the
//     client negotiated (McpResume), so the client keeps talking to it as if nothing happened; it then sends
//     tools/list_changed and resources/list_changed, and the first tool result carries a notice that says it happened. On
//     Windows a process cannot be replaced in place and the client owns stdio: the server only says so, in the next tool result
//     and a notifications/message, and asks for a reconnect.
//  2. The client started with an older `.mcp.json` than the one now on disk (a `timeout` added after it started). The server
//     cannot make a client re-read its configuration: it tells the AI once, in a tool result, to ask the user to restart the
//     client or reconnect. It also adds the missing `timeout` to the file (ensure_claude_code_mcp_timeout).
#pragma once

#include <chrono>
#include <cstdint>
#include <filesystem>
#include <functional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/types.h"
#include "fa/mcp/server.h"
#include "fa/tooling/self_update.h"

namespace fa {

// What the old process hands the new one when it restarts itself (the hidden option --resume-session, a JSON object).
struct McpResume {
    Json session;                 // McpServer::session_state(); null = the client had not initialized yet
    std::int64_t startedMs = 0;   // when the first process of the chain started, ms since 1970: `.mcp.json` is compared with it
    std::string previousBuild;    // label of the build that ran before
    std::string lost;             // what the restart discarded ("" = nothing)
    std::string executable;       // the file executed again
    std::vector<std::string> notices;  // notices of the old process not yet delivered by a tool result
    int restarts = 0;             // restarts in a row since the client started the server
    std::int64_t configReportedMs = 0;  // modification time of the .mcp.json whose change was already reported
    std::string to_string() const;
    static Result<McpResume> parse(std::string_view text);
};

struct McpUpdateOptions {
    std::string projectDir;  // where `.mcp.json` is looked for; "" = no project: nothing to compare
    // Replace the process in place when the executable changed. Default: can_restart_in_place() (not on Windows).
    bool restartInPlace = true;
    bool fixMcpTimeout = true;  // add the missing `timeout` to the project's `.mcp.json`
    // Not empty while something runs that a restart would cut off (a background job): the restart waits, and the reason shows
    // in engine.update_status. Called on the loop's thread, between messages.
    std::function<std::string()> busy;
    // What a restart would discard that the client may count on ("the game at frame 120"), said in the notice that follows it.
    std::function<std::string()> lost_on_restart;
    // How often the executable and `.mcp.json` are looked at (a stat each).
    std::chrono::milliseconds checkEvery{2000};
    int maxRestarts = 5;  // in a row: a new file that cannot start must not loop
};

// True where a process can replace itself with exec (not on Windows).
bool can_restart_in_place();
// Replaces this process with `executable argv...`, keeping the open stdin and stdout. Returns only when it could not.
Result<void> restart_process(const std::filesystem::path& executable, const std::vector<std::string>& argv);

class McpUpdateMonitor {
public:
    // `resume` is set in a process that was started by a restart: its session is restored in `server`.
    McpUpdateMonitor(McpServer& server, UpdateWatch& watch, McpUpdateOptions options, const McpResume* resume = nullptr);

    // After a restart, once the server serves: notifications/tools/list_changed and resources/list_changed, a
    // notifications/message, and the notice for the first tool result. Does nothing in a first process.
    void announce_resume();
    // One look at the executable and `.mcp.json` (at most every checkEvery). Never blocks; sends the Windows warning and queues
    // the notices.
    void poll();
    // True when this process should replace itself now: the executable holds another build, restarting is possible and
    // nothing is busy. The caller leaves its loop, tidies up and calls restart_process with resume_state().
    bool restart_due();
    // What the new process needs; `lost` is what the restart discards (lost_on_restart()).
    McpResume resume_state() const;
    // A restart that failed (exec returned): the server stays, and tells the AI to reconnect instead.
    void restart_failed(const std::string& reason);

    // {canRestartInPlace, restartPending, deferredBy, restarts, projectConfig, client, ...}: engine.update_status's "mcp".
    Json status() const;

private:
    void check_executable();
    void check_client_config();
    bool client_reads_mcp_json() const;
    void notice_stale_server(const std::string& detail);

    McpServer& server_;
    UpdateWatch& watch_;
    McpUpdateOptions opt_;
    std::int64_t startedMs_ = 0;
    int restarts_ = 0;
    bool resumed_ = false;
    McpResume resume_;
    std::chrono::steady_clock::time_point lastCheck_{};
    bool checked_ = false;
    bool lookedWithClient_ = false;  // one look was made after the client initialized
    FileStamp reportedStamp_;      // the executable stamp already reported (Windows) or acted on
    bool restartPending_ = false;
    std::string deferredBy_;
    std::string failedReason_;     // a restart that failed
    bool configChecked_ = false;   // the missing-timeout fix was tried
    std::int64_t configReportedMs_ = 0;  // mtime of the .mcp.json already reported
    bool addedTimeout_ = false;
    std::string timeoutError_;
    bool timeoutErrorReported_ = false;
};

}  // namespace fa
