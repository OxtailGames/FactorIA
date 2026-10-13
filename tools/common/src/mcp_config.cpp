#include "fa/tooling/mcp_config.h"

#include <sstream>

#include "fa/core/strings.h"
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
}  // namespace

Json claude_code_mcp_config(const McpClientOptions& o) {
    Json server = Json::object();
    server["command"] = o.command;
    server["args"] = Json::array({"mcp", "--project", o.projectDir});
    return Json::object({{"mcpServers", Json::object({{o.serverName, server}})}});
}

std::string codex_mcp_toml(const McpClientOptions& o) {
    std::ostringstream s;
    s << "[mcp_servers." << o.serverName << "]\n";
    s << "command = " << toml_quote(o.command) << "\n";
    s << "args = [\"mcp\", \"--project\", " << toml_quote(o.projectDir) << "]\n";
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
