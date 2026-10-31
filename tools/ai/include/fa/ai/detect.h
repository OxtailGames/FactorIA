// Provider detection for `factoria ai doctor` and the editor's AI panel.
#pragma once

#include "fa/ai/config.h"

namespace fa::ai {

struct ProviderStatus {
    std::string name;
    std::string kind;          // provider_kind_name
    bool isCli = false;
    bool available = false;    // usable right now (CLI found / key present / local server preset)
    std::string detail;        // human-readable one-liner
    std::string version;       // CLI version when found
    std::string path;          // CLI path
    std::string keySource;     // "env:OPENAI_API_KEY" | "config" | "ant-cli" | ""
    std::string hint;          // what to do when !available
    std::vector<std::string> makes;  // asset providers (and openai): the media kinds it can generate ("image", "sound"...)
    Json to_json() const;
};

struct DetectOptions {
    bool probeVersions = true;           // run `<cli> --version` (5 s timeout)
    EnvLookup env = system_env();
    // Overridable for tests: returns "" when the CLI is not installed.
    std::function<std::string(const std::string&)> which;
    std::function<std::string(const std::string& exe)> version;
};

std::vector<ProviderStatus> detect_providers(const AiConfig& cfg, const DetectOptions& options = {});

// One external tool server (ai.json "mcpServers") as `factoria ai doctor`, ai.tool_servers and the editor show it. Never holds a key.
struct ToolServerStatus {
    std::string name;
    std::string type;                  // "http" | "stdio"
    std::string target;                // the URL without its query string, or the program
    bool enabled = true;
    std::vector<std::string> roles;    // the roles that get it (defaults filled in)
    bool usesKey = false;              // the server's headers/args/env use {key}
    std::string keySource;             // "env:SCENARIO_API_KEY" | "config" | "" (none found, or no key used)
    std::string problem;               // what stops the server from being used ("" = ready): a missing key or variable
    Json to_json() const;
};
std::vector<ToolServerStatus> tool_server_statuses(const AiConfig& cfg, const EnvLookup& env = system_env());

// Text report for the terminal. `env` is where the tool servers' keys are looked up. `projectDir` ("" = none) is the project whose
// extensions file and Claude Code deny rules (mcp__factoria) the Extensions section also checks.
std::string format_doctor_report(const AiConfig& cfg, const std::vector<ProviderStatus>& status,
                                 const EnvLookup& env = system_env(), std::string_view projectDir = {});

}  // namespace fa::ai
