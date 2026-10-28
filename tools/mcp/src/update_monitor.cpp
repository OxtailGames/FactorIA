#include "fa/mcp/update_monitor.h"

#include <algorithm>
#include <cctype>

#include "fa/tooling/mcp_config.h"

namespace fa {

namespace {

std::int64_t now_ms() {
    return std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now().time_since_epoch()).count();
}

}  // namespace

// ---- McpResume -------------------------------------------------------------------------------------------------------

std::string McpResume::to_string() const {
    Json j = Json::object();
    j["session"] = session;
    j["startedMs"] = startedMs;
    j["previousBuild"] = previousBuild;
    j["lost"] = lost;
    j["executable"] = executable;
    j["notices"] = notices;
    j["restarts"] = restarts;
    j["configReportedMs"] = configReportedMs;
    return j.dump();
}

Result<McpResume> McpResume::parse(std::string_view text) {
    Json j;
    try {
        j = Json::parse(text.begin(), text.end());
    } catch (const std::exception& e) {
        return make_error(std::string("--resume-session is not JSON: ") + e.what(),
                          "this option is the hidden hand-over of a server that restarted itself; do not pass it by hand");
    }
    if (!j.is_object()) return make_error("--resume-session must be a JSON object");
    McpResume r;
    r.session = j.value("session", Json(nullptr));
    r.startedMs = j.value("startedMs", std::int64_t(0));
    r.previousBuild = j.value("previousBuild", std::string());
    r.lost = j.value("lost", std::string());
    r.executable = j.value("executable", std::string());
    r.restarts = j.value("restarts", 0);
    r.configReportedMs = j.value("configReportedMs", std::int64_t(0));
    if (j.contains("notices") && j["notices"].is_array())
        for (const Json& n : j["notices"])
            if (n.is_string()) r.notices.push_back(n.get<std::string>());
    return r;
}

// ---- McpUpdateMonitor ------------------------------------------------------------------------------------------------

McpUpdateMonitor::McpUpdateMonitor(McpServer& server, UpdateWatch& watch, McpUpdateOptions options, const McpResume* resume)
    : server_(server), watch_(watch), opt_(std::move(options)), startedMs_(now_ms()) {
    if (!resume) return;
    resumed_ = true;
    resume_ = *resume;
    if (resume->startedMs > 0) startedMs_ = resume->startedMs;  // the client's start, not ours
    restarts_ = resume->restarts;
    configReportedMs_ = resume->configReportedMs;
    if (resume->session.is_object()) server_.restore_session(resume->session);
}

void McpUpdateMonitor::announce_resume() {
    if (!resumed_ || !server_.initialized()) return;
    int i = 0;
    for (const std::string& n : resume_.notices) server_.add_tool_notice("carried" + std::to_string(i++), n);
    std::string text = "FactorIA was updated to " + watch_.running().label();
    if (!resume_.previousBuild.empty()) text += " (the server was running " + resume_.previousBuild + ")";
    text += "; the MCP server restarted itself in place, so the connection to the client was kept and the tools are those of "
            "the new version (tools/list may differ).";
    if (!resume_.lost.empty()) text += " Lost in the restart: " + resume_.lost;
    else text += " Nothing the client may count on was lost.";
    server_.add_tool_notice("restarted", text);
    server_.notify_tools_changed();
    server_.notify_resources_changed();
    server_.log("notice", "factoria.update", text);
}

bool McpUpdateMonitor::client_reads_mcp_json() const {
    std::string name = server_.client_name();
    std::transform(name.begin(), name.end(), name.begin(), [](unsigned char c) { return char(std::tolower(c)); });
    return name.find("claude") != std::string::npos;  // Claude Code reads the project's .mcp.json; Codex has its own config.toml
}

void McpUpdateMonitor::poll() {
    const auto now = std::chrono::steady_clock::now();
    // The first look after the client initialized is not made to wait: that is when the project's .mcp.json is compared.
    const bool firstWithClient = !lookedWithClient_ && server_.initialized();
    if (checked_ && !firstWithClient && now - lastCheck_ < opt_.checkEvery) return;
    checked_ = true;
    if (server_.initialized()) lookedWithClient_ = true;
    lastCheck_ = now;
    check_executable();
    check_client_config();
}

void McpUpdateMonitor::notice_stale_server(const std::string& detail) {
    const std::string text =
        "FactorIA was updated on disk (" + watch_.running().label() + " -> " + watch_.on_disk().label() +
        ") but this MCP server still runs the old code" + (detail.empty() ? std::string() : " and " + detail) +
        ". Ask the user to reconnect the factoria server (in Claude Code: /mcp) or to restart the AI client; until then the "
        "tools behave as in " + watch_.running().label() + ".";
    server_.add_tool_notice("update", text);
    server_.log("warning", "factoria.update", text);
}

void McpUpdateMonitor::check_executable() {
    watch_.check();
    if (!watch_.updated()) {  // nothing changed, or the file went back to the running build
        restartPending_ = false;
        deferredBy_.clear();
        return;
    }
    if (opt_.restartInPlace && can_restart_in_place() && failedReason_.empty() && restarts_ < opt_.maxRestarts) {
        restartPending_ = true;
        return;
    }
    const FileStamp stamp = watch_.examined_stamp();
    if (stamp == reportedStamp_) return;  // said once per update
    reportedStamp_ = stamp;
    std::string why;
    if (!failedReason_.empty()) why = "the restart in place failed (" + failedReason_ + ")";
    else if (restarts_ >= opt_.maxRestarts) why = "it already restarted itself " + std::to_string(restarts_) + " times in a row";
    else if (!can_restart_in_place()) why = "Windows cannot replace a running program, and the client owns its stdio";
    else why = "restarting in place is off";
    notice_stale_server(why);
}

bool McpUpdateMonitor::restart_due() {
    if (!restartPending_) return false;
    if (opt_.busy) {
        deferredBy_ = opt_.busy();
        if (!deferredBy_.empty()) return false;
    }
    return true;
}

McpResume McpUpdateMonitor::resume_state() const {
    McpResume r;
    r.session = server_.initialized() ? server_.session_state() : Json(nullptr);
    r.startedMs = startedMs_;
    r.previousBuild = watch_.running().label();
    r.lost = opt_.lost_on_restart ? opt_.lost_on_restart() : std::string();
    r.executable = watch_.executable().string();
    r.notices = server_.pending_tool_notices();
    r.restarts = restarts_ + 1;
    r.configReportedMs = configReportedMs_;
    return r;
}

void McpUpdateMonitor::restart_failed(const std::string& reason) {
    failedReason_ = reason;
    restartPending_ = false;
    reportedStamp_ = FileStamp{};
    check_executable();  // says it (once) now that the restart is off
}

void McpUpdateMonitor::check_client_config() {
    if (opt_.projectDir.empty() || !server_.initialized() || !client_reads_mcp_json()) return;
    ClaudeCodeMcpState st = read_claude_code_mcp_state(opt_.projectDir);
    if (!st.exists) return;
    if (!configChecked_) {
        configChecked_ = true;
        // Only the first process of a client's session fixes the file: a restarted one inherits what the first one did.
        if (!resumed_ && opt_.fixMcpTimeout && st.hasServer && !st.hasTimeout) {
            auto r = ensure_claude_code_mcp_timeout(opt_.projectDir, st.serverName);
            if (r.ok() && *r) {
                addedTimeout_ = true;
                st = read_claude_code_mcp_state(opt_.projectDir);
            } else if (!r.ok()) {
                timeoutError_ = r.error().message;
            }
        }
    }
    if (!timeoutError_.empty() && !timeoutErrorReported_) {
        timeoutErrorReported_ = true;
        server_.add_tool_notice("config-timeout",
                                "The factoria server of the project's .mcp.json has no \"timeout\" and FactorIA could not add it (" +
                                    timeoutError_ + "). Add \"timeout\": " + std::to_string(kClaudeCodeMcpToolTimeoutMs) +
                                    " to it by hand, or long tool calls such as ai_run are aborted by Claude Code after minutes.");
    }
    if (st.modifiedMs <= startedMs_ || st.modifiedMs == configReportedMs_) return;  // the client read the file as it is
    configReportedMs_ = st.modifiedMs;
    std::string text = "The project's .mcp.json (" + st.path + ") changed after the AI client started this factoria server, so "
                       "the client may still run with the old settings";
    if (addedTimeout_)
        text += ": it had no \"timeout\" for the factoria server, which Claude Code needs to let long tool calls such as ai_run "
                "run for hours instead of aborting them after minutes; FactorIA added \"timeout\": " +
                std::to_string(kClaudeCodeMcpToolTimeoutMs) + " to it just now";
    text += ". Ask the user to restart the client, or to reconnect the factoria server (in Claude Code: /mcp), so that it reads "
            "the file again.";
    server_.add_tool_notice("config", text);
}

Json McpUpdateMonitor::status() const {
    Json j = Json::object();
    j["canRestartInPlace"] = opt_.restartInPlace && can_restart_in_place();
    j["restartPending"] = restartPending_;
    j["deferredBy"] = deferredBy_;
    j["restartsInARow"] = restarts_;
    j["restartFailed"] = failedReason_;
    j["client"] = server_.client_name();
    j["startedMs"] = startedMs_;
    if (!opt_.projectDir.empty()) {
        const ClaudeCodeMcpState st = read_claude_code_mcp_state(opt_.projectDir);
        Json cfg = st.to_json();
        cfg["clientReadsIt"] = client_reads_mcp_json();
        cfg["changedAfterClientStarted"] = st.exists && st.modifiedMs > startedMs_;
        cfg["timeoutAddedByFactoria"] = addedTimeout_;
        cfg["timeoutError"] = timeoutError_;
        cfg["advice"] = st.exists && st.modifiedMs > startedMs_ && client_reads_mcp_json()
                            ? "the client may run with an older .mcp.json: ask the user to restart it or reconnect (Claude Code: /mcp)"
                            : "the client started with the .mcp.json on disk";
        j["projectConfig"] = cfg;
    }
    return j;
}

}  // namespace fa
