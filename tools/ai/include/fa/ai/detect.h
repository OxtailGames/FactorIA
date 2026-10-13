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
// Text report for the terminal.
std::string format_doctor_report(const AiConfig& cfg, const std::vector<ProviderStatus>& status);

}  // namespace fa::ai
