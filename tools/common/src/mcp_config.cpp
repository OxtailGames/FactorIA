#include "fa/tooling/mcp_config.h"

#include <filesystem>
#include <sstream>

#include "fa/core/strings.h"
#include "fa/tooling/self_update.h"
#include "util.h"

namespace fa {

namespace {
std::string toml_quote(std::string_view s) {
    std::string out = "\"";
    for (char c : s) {
        if (c == '"' || c == '\\') out += '\\';
        out += c;
    }
    return out + "\"";
}

// The key of the entry of `servers` that runs `factoria mcp`: `preferred` when it exists, else the first entry whose command is
// factoria and whose args name `mcp`. "" when there is none.
std::string factoria_server_key(const Json& servers, const std::string& preferred) {
    if (!servers.is_object()) return {};
    auto runs_mcp = [](const Json& e) {
        if (!e.is_object() || !e.contains("args") || !e["args"].is_array()) return false;
        for (const Json& a : e["args"])
            if (a.is_string() && a.get<std::string>() == "mcp") return true;
        return false;
    };
    auto it = servers.find(preferred);
    if (it != servers.end() && it->is_object()) return preferred;
    for (auto e = servers.begin(); e != servers.end(); ++e) {
        if (!e.value().is_object() || !e.value().contains("command") || !e.value()["command"].is_string()) continue;
        const std::string stem = std::filesystem::path(e.value()["command"].get<std::string>()).stem().string();
        if (stem == "factoria" && runs_mcp(e.value())) return e.key();
    }
    return {};
}

}  // namespace

Json ClaudeCodeMcpState::to_json() const {
    Json j = Json::object();
    j["path"] = path;
    j["exists"] = exists;
    j["hasServer"] = hasServer;
    j["serverName"] = serverName;
    j["hasTimeout"] = hasTimeout;
    j["timeoutMs"] = timeoutMs;
    return j;
}

ClaudeCodeMcpState read_claude_code_mcp_state(const std::string& projectDir, const std::string& serverName) {
    ClaudeCodeMcpState st;
    const std::filesystem::path file = std::filesystem::path(projectDir) / ".mcp.json";
    st.path = file.generic_string();
    auto text = tooling_detail::read_file(file);
    if (!text) return st;
    st.exists = true;
    st.modifiedMs = file_mtime_ms(file);
    auto parsed = parse_json(*text, st.path);
    if (!parsed.ok() || !parsed.value().is_object() || !parsed.value().contains("mcpServers")) return st;
    const Json& servers = parsed.value()["mcpServers"];
    const std::string key = factoria_server_key(servers, serverName);
    if (key.empty()) return st;
    st.hasServer = true;
    st.serverName = key;
    const Json& entry = servers[key];
    if (entry.contains("timeout") && entry["timeout"].is_number()) {
        st.hasTimeout = true;
        st.timeoutMs = entry["timeout"].get<long long>();
    }
    return st;
}

Result<bool> ensure_claude_code_mcp_timeout(const std::string& projectDir, const std::string& serverName) {
    const std::string path = (std::filesystem::path(projectDir) / ".mcp.json").string();
    auto text = tooling_detail::read_file(path);
    if (!text) return false;
    auto parsed = parse_json(*text, path);
    if (!parsed.ok()) return make_error(parsed.error().message, "Fix or delete " + path + " and retry.");
    Json doc = parsed.value();
    if (!doc.is_object() || !doc.contains("mcpServers")) return false;
    const std::string key = factoria_server_key(doc["mcpServers"], serverName);
    if (key.empty() || doc["mcpServers"][key].contains("timeout")) return false;
    doc["mcpServers"][key]["timeout"] = kClaudeCodeMcpToolTimeoutMs;
    std::string err;
    if (!tooling_detail::write_file(path, dump_json(doc), &err)) return make_error(err);
    return true;
}

Json claude_code_mcp_config(const McpClientOptions& o) {
    Json server = Json::object();
    server["command"] = o.command;
    server["args"] = Json::array({"mcp", "--project", o.projectDir});
    server["timeout"] = kClaudeCodeMcpToolTimeoutMs;
    return Json::object({{"mcpServers", Json::object({{o.serverName, server}})}});
}

std::string codex_mcp_toml(const McpClientOptions& o) {
    std::ostringstream s;
    s << "[mcp_servers." << o.serverName << "]\n";
    s << "command = " << toml_quote(o.command) << "\n";
    s << "args = [\"mcp\", \"--project\", " << toml_quote(o.projectDir) << "]\n";
    s << "tool_timeout_sec = " << kCodexMcpToolTimeoutSec << "\n";
    return s.str();
}

Result<void> write_claude_code_mcp_config(const std::string& path, const McpClientOptions& o) {
    Json doc = Json::object();
    if (auto text = tooling_detail::read_file(path)) {
        auto parsed = parse_json(*text, path);
        if (!parsed.ok()) return make_error(parsed.error().message, "Fix or delete " + path + " and retry.");
        if (parsed.value().is_object()) doc = parsed.value();
    }
    if (!doc.contains("mcpServers") || !doc["mcpServers"].is_object()) doc["mcpServers"] = Json::object();
    doc["mcpServers"][o.serverName] = claude_code_mcp_config(o)["mcpServers"][o.serverName];
    std::string err;
    if (!tooling_detail::write_file(path, dump_json(doc), &err)) return make_error(err);
    return {};
}

Result<void> write_codex_mcp_config(const std::string& path, const McpClientOptions& o) {
    std::string existing = tooling_detail::read_file(path).value_or("");
    // Drop an existing [mcp_servers.<name>] table (until the next table header).
    const std::string header = "[mcp_servers." + o.serverName + "]";
    std::ostringstream kept;
    bool skipping = false;
    std::istringstream in(existing);
    std::string line;
    while (std::getline(in, line)) {
        std::string_view t = trim(line);
        if (!t.empty() && t[0] == '[') skipping = (t == header) || starts_with(t, "[mcp_servers." + o.serverName + ".");
        if (!skipping) kept << line << "\n";
    }
    std::string out = kept.str();
    if (!out.empty() && out.back() != '\n') out += '\n';
    if (!out.empty() && out.size() > 1 && out[out.size() - 2] != '\n') out += '\n';
    out += codex_mcp_toml(o);
    std::string err;
    if (!tooling_detail::write_file(path, out, &err)) return make_error(err);
    return {};
}

}  // namespace fa
