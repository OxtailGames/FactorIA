// External tool servers (MCP) in ai.json: parse, validate, resolve {key} and ${ENV}, serialize.
// The connection itself is in mcp_client.cpp; docs/AI_PROVIDERS.md, "External tools (MCP servers)".
#include <algorithm>
#include <cctype>

#include "fa/ai/config.h"
#include "fa/core/strings.h"
#include "util.h"

namespace fa::ai {

using util::child;
using util::flag;
using util::num;
using util::str;

bool ToolServer::serves_role(std::string_view role) const {
    if (!enabled) return false;
    if (roles.empty()) {
        for (const char* r : kDefaultToolServerRoles)
            if (role == r) return true;
        return false;
    }
    return std::find(roles.begin(), roles.end(), role) != roles.end();
}

std::vector<const ToolServer*> AiConfig::tool_servers_for(std::string_view role) const {
    std::vector<const ToolServer*> out;
    for (const ToolServer& s : toolServers)
        if (s.serves_role(role)) out.push_back(&s);
    return out;
}

std::vector<const Extension*> AiConfig::extensions_for(std::string_view role) const {
    std::vector<const Extension*> out;
    for (const Extension& e : extensions.entries)
        if (e.serves_role(role)) out.push_back(&e);
    return out;
}

std::string tool_server_name_problem(std::string_view name) {
    if (name.empty()) return "the name is empty";
    if (name.size() > kMaxToolServerName)
        return "the name is longer than " + std::to_string(kMaxToolServerName) + " characters";
    for (char c : name) {
        const bool ok = std::isalnum(static_cast<unsigned char>(c)) || c == '_' || c == '-';
        if (!ok) return std::string("the name has the character '") + c + "', only letters, digits, _ and - are allowed";
    }
    if (name == kToolServerFactoria) return "\"factoria\" is the name of the engine's own tool server";
    return {};
}

namespace {

constexpr const char* kServerKeys[] = {"type",   "url",  "headers", "command", "args",    "env",
                                       "apiKeyEnv", "apiKey", "note", "roles", "enabled", "timeoutSeconds"};

std::string join_names(const std::vector<std::string>& v) {
    std::string out;
    for (const auto& s : v) out += (out.empty() ? "" : ", ") + s;
    return out;
}

bool valid_header_name(const std::string& n) {
    if (n.empty()) return false;
    for (char c : n)
        if (!(std::isalnum(static_cast<unsigned char>(c)) || c == '-' || c == '_')) return false;
    return true;
}

// Replaces {key} and ${NAME} / ${NAME:-default} in `text`. `key` null = no key available. `problem` gets what is missing.
std::string substitute(const std::string& text, const std::string* key, bool& usedKey, const EnvLookup& env,
                       std::string& problem) {
    std::string out;
    for (std::size_t i = 0; i < text.size();) {
        if (text.compare(i, 5, "{key}") == 0) {
            usedKey = true;
            if (key) out += *key;
            else if (problem.empty()) problem = "{key}";
            i += 5;
        } else if (text.compare(i, 2, "${") == 0) {
            auto close = text.find('}', i + 2);
            if (close == std::string::npos) { out += text.substr(i); break; }
            std::string inner = text.substr(i + 2, close - i - 2);
            std::string dflt;
            bool hasDefault = false;
            if (auto sep = inner.find(":-"); sep != std::string::npos) {
                dflt = inner.substr(sep + 2);
                inner.resize(sep);
                hasDefault = true;
            }
            std::string value = env ? env(inner) : std::string();
            if (value.empty() && hasDefault) value = dflt;
            if (value.empty() && !hasDefault && problem.empty()) problem = "${" + inner + "}";
            out += value;
            i = close + 1;
        } else {
            out += text[i++];
        }
    }
    return out;
}

}  // namespace

Result<ResolvedToolServer> resolve_tool_server(const ToolServer& s, const EnvLookup& env) {
    ResolvedToolServer r;
    r.name = s.name;
    r.type = s.type;
    r.url = s.url;
    r.command = s.command;
    r.timeoutSeconds = s.timeoutSeconds;

    std::string key;
    if (!s.apiKeyEnv.empty() && env) {
        key = env(s.apiKeyEnv);
        if (!key.empty()) r.keySource = "env:" + s.apiKeyEnv;
    }
    if (key.empty() && !s.apiKey.empty()) {
        key = s.apiKey;
        r.keySource = "config";
    }
    const std::string* keyPtr = key.empty() ? nullptr : &key;

    auto fail = [&](const std::string& where, const std::string& what) -> Error {
        std::string message = "Tool server '" + s.name + "': " + where + " uses " + what + ", which has no value";
        std::string hint;
        if (what == "{key}") {
            hint = s.apiKeyEnv.empty()
                       ? "Set \"apiKeyEnv\" to the name of an environment variable that holds the key, or put the key in "
                         "\"apiKey\" (AI settings > External tools)."
                       : "Set the environment variable " + s.apiKeyEnv + " (restart the editor or the shell after setting "
                         "it), or put the key in \"apiKey\" (AI settings > External tools).";
        } else {
            hint = "Set that environment variable (restart the editor or the shell after setting it), or write "
                   "${NAME:-default} to give it a default.";
        }
        return Error{message, hint};
    };

    for (const auto& [name, value] : s.headers) {
        std::string problem;
        std::string v = substitute(value, keyPtr, r.usesKey, env, problem);
        if (!problem.empty()) return fail("header '" + name + "'", problem);
        r.headers.emplace_back(name, std::move(v));
    }
    for (std::size_t i = 0; i < s.args.size(); ++i) {
        std::string problem;
        std::string v = substitute(s.args[i], keyPtr, r.usesKey, env, problem);
        if (!problem.empty()) return fail("argument " + std::to_string(i + 1), problem);
        r.args.push_back(std::move(v));
    }
    for (const auto& [name, value] : s.env) {
        std::string problem;
        std::string v = substitute(value, keyPtr, r.usesKey, env, problem);
        if (!problem.empty()) return fail("environment variable " + name, problem);
        r.env[name] = std::move(v);
    }
    if (!r.usesKey) r.keySource.clear();
    return r;
}

Result<ToolServer> parse_tool_server(const Json& entry, std::string name, std::string_view atIn,
                                     std::vector<std::string>* ignored) {
    const std::string at(atIn);
    if (auto problem = tool_server_name_problem(name); !problem.empty()) {
        return make_error(at + ": '" + name + "' cannot be a tool server name: " + problem,
                          "Use a short name such as scenario or filesystem (letters, digits, _ and -).");
    }
    if (!entry.is_object()) {
        return make_error(at + ": a tool server is an object, for example {\"type\": \"http\", \"url\": \"https://...\"}",
                          "See docs/AI_PROVIDERS.md, \"External tools (MCP servers)\".");
    }
    std::vector<std::string> known(std::begin(kServerKeys), std::end(kServerKeys));
    for (auto it = entry.begin(); it != entry.end(); ++it) {
        if (std::find(known.begin(), known.end(), it.key()) != known.end()) continue;
        if (ignored) { ignored->push_back(it.key()); continue; }
        return make_error(at + "/" + it.key() + ": unknown property '" + it.key() + "'", fa::did_you_mean(it.key(), known));
    }

    ToolServer s;
    s.name = std::move(name);
    s.type = str(entry, "type");
    s.url = str(entry, "url");
    s.command = str(entry, "command");
    s.apiKeyEnv = str(entry, "apiKeyEnv");
    s.apiKey = str(entry, "apiKey");
    s.note = str(entry, "note");
    s.enabled = flag(entry, "enabled", true);
    s.timeoutSeconds = num(entry, "timeoutSeconds", s.timeoutSeconds);
    if (s.timeoutSeconds <= 0) {
        return make_error(at + "/timeoutSeconds: must be above 0", "Use the seconds one tool call may take, for example 120.");
    }
    if (const Json* a = child(entry, "args"); a && a->is_array()) {
        for (const Json& v : *a) {
            if (!v.is_string()) return make_error(at + "/args: every argument is a string", "Quote numbers: \"8080\".");
            s.args.push_back(v.get<std::string>());
        }
    }
    auto read_map = [&](const char* key, auto&& add) -> Result<void> {
        if (const Json* m = child(entry, key); m && m->is_object()) {
            for (auto it = m->begin(); it != m->end(); ++it) {
                if (!it.value().is_string())
                    return make_error(at + "/" + key + "/" + it.key() + ": the value is a string",
                                      "Write it between quotes; numbers too: \"8080\".");
                add(it.key(), it.value().get<std::string>());
            }
        }
        return {};
    };
    if (auto ok = read_map("headers", [&](const std::string& k, std::string v) { s.headers.emplace_back(k, std::move(v)); }); !ok)
        return ok.error();
    if (auto ok = read_map("env", [&](const std::string& k, std::string v) { s.env[k] = std::move(v); }); !ok) return ok.error();
    for (const auto& [h, v] : s.headers) {
        if (!valid_header_name(h))
            return make_error(at + "/headers/" + h + ": '" + h + "' is not a header name",
                              "Header names are letters, digits and -, for example Authorization or X-Api-Key.");
    }
    if (const Json* r = child(entry, "roles"); r && r->is_array()) {
        std::vector<std::string> roleNames(std::begin(kAllRoles), std::end(kAllRoles));
        std::size_t index = 0;
        for (const Json& v : *r) {
            const std::string role = v.is_string() ? v.get<std::string>() : std::string();
            if (!is_known_role(role)) {
                return make_error(at + "/roles/" + std::to_string(index) + ": unknown role '" + role + "'",
                                  fa::did_you_mean(role, roleNames) + " Roles: " + join_names(roleNames) + ".");
            }
            if (std::find(s.roles.begin(), s.roles.end(), role) == s.roles.end()) s.roles.push_back(role);
            ++index;
        }
    }

    // The transport: explicit, or inferred from command / url.
    if (s.type.empty()) s.type = !s.command.empty() ? "stdio" : (!s.url.empty() ? "http" : "");
    if (s.type == "streamable-http" || s.type == "streamableHttp") s.type = "http";
    if (s.type == "sse") {
        return make_error(at + "/type: the SSE transport (type \"sse\") is not supported",
                          "Use the server's Streamable HTTP address with type \"http\" (often the same host with /mcp "
                          "instead of /sse), or ask its documentation for the \"streamable http\" URL.");
    }
    if (s.type.empty()) {
        return make_error(at + ": a tool server needs a \"url\" (a remote server) or a \"command\" (a local program)",
                          "Remote: {\"url\": \"https://mcp.example.com/mcp\"}. Local: {\"command\": \"npx\", \"args\": [\"-y\", "
                          "\"some-mcp-server\"]}.");
    }
    if (s.type != "http" && s.type != "stdio") {
        return make_error(at + "/type: unknown transport '" + s.type + "'", fa::did_you_mean(s.type, std::vector<std::string>{"http", "stdio"}));
    }
    if (s.type == "http") {
        if (s.url.empty())
            return make_error(at + "/url: a server of type \"http\" needs its address",
                              "Add \"url\": \"https://...\" (the Streamable HTTP endpoint, usually ending in /mcp).");
        if (s.url.rfind("http://", 0) != 0 && s.url.rfind("https://", 0) != 0)
            return make_error(at + "/url: '" + s.url + "' is not a web address",
                              "Start it with https:// (or http:// for a server on this computer).");
        if (!s.command.empty())
            return make_error(at + "/command: \"command\" starts a local program, but the type is \"http\"",
                              "Remove \"command\", or set \"type\": \"stdio\" and remove \"url\".");
    } else {
        if (s.command.empty())
            return make_error(at + "/command: a server of type \"stdio\" needs the program to start",
                              "Add \"command\": \"npx\" (or uvx, node, python, a path) and its \"args\".");
        if (!s.url.empty())
            return make_error(at + "/url: \"url\" is for a remote server, but the type is \"stdio\"",
                              "Remove \"url\", or set \"type\": \"http\" and remove \"command\".");
    }
    return s;
}

Result<std::vector<ToolServer>> parse_tool_servers(const Json& objectIn, std::string_view at,
                                                   std::vector<std::string>* ignored) {
    const Json* object = &objectIn;
    std::string where(at);
    if (objectIn.is_object() && objectIn.size() == 1 && objectIn.contains("mcpServers")) {  // Claude Code's wrapper
        object = &objectIn["mcpServers"];
        where += "/mcpServers";
    }
    if (!object->is_object()) {
        return make_error(where + ": \"mcpServers\" is an object with one entry per server",
                          "For example {\"scenario\": {\"type\": \"http\", \"url\": \"https://mcp.scenario.com/mcp\"}}.");
    }
    std::vector<ToolServer> out;
    for (auto it = object->begin(); it != object->end(); ++it) {
        auto s = parse_tool_server(it.value(), it.key(), where + "/" + it.key(), ignored);
        if (!s) return s.error();
        out.push_back(std::move(*s));
    }
    return out;  // in the order of the file
}

namespace {

// A header or env value that holds a secret written out in full (not a {key} / ${ENV} reference) under a name that says so.
bool is_literal_secret(const std::string& name, const std::string& value) {
    if (value.find("{key}") != std::string::npos || value.find("${") != std::string::npos) return false;
    std::string n = util::lower(name);
    for (const char* word : {"authorization", "key", "token", "secret", "password", "credential"})
        if (n.find(word) != std::string::npos) return true;
    return false;
}

}  // namespace

Json tool_server_to_json(const ToolServer& s, bool redactKeys) {
    Json j = Json::object();
    j["type"] = s.type;
    if (!s.url.empty()) j["url"] = s.url;
    if (!s.headers.empty()) {
        Json h = Json::object();
        for (const auto& [k, v] : s.headers) h[k] = redactKeys && is_literal_secret(k, v) ? "***" : v;
        j["headers"] = std::move(h);
    }
    if (!s.command.empty()) j["command"] = s.command;
    if (!s.args.empty()) j["args"] = s.args;
    if (!s.env.empty()) {
        Json e = Json::object();
        for (const auto& [k, v] : s.env) e[k] = redactKeys && is_literal_secret(k, v) ? "***" : v;
        j["env"] = std::move(e);
    }
    if (!s.apiKeyEnv.empty()) j["apiKeyEnv"] = s.apiKeyEnv;
    if (!s.apiKey.empty()) j["apiKey"] = redactKeys ? "***" : s.apiKey;
    if (!s.note.empty()) j["note"] = s.note;
    if (!s.roles.empty()) j["roles"] = s.roles;
    if (!s.enabled) j["enabled"] = false;
    if (s.timeoutSeconds != 120) j["timeoutSeconds"] = s.timeoutSeconds;
    return j;
}

}  // namespace fa::ai
