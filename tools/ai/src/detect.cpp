#include "fa/ai/detect.h"

#include "fa/ai/process.h"
#include "fa/core/strings.h"
#include "fa/ai/cli_agent.h"
#include "util.h"

namespace fa::ai {

Json ProviderStatus::to_json() const {
    return Json::object({{"name", name}, {"kind", kind}, {"cli", isCli}, {"available", available}, {"detail", detail},
                         {"version", version}, {"path", path}, {"keySource", keySource}, {"hint", hint}});
}

static std::string probe_version(const std::string& exe) {
    ProcessOptions po;
    po.argv = {exe, "--version"};
    po.timeoutSeconds = 5;
    auto r = run_process(po);
    if (!r || r->exitCode != 0) return {};
    std::string out(fa::trim(r->stdoutText));
    if (out.empty()) out = std::string(fa::trim(r->stderrText));
    auto nl = out.find('\n');
    return nl == std::string::npos ? out : out.substr(0, nl);
}

std::vector<ProviderStatus> detect_providers(const AiConfig& cfg, const DetectOptions& opt) {
    auto which_fn = opt.which ? opt.which : [](const std::string& n) { return which(n); };
    auto version_fn = opt.version ? opt.version : [](const std::string& e) { return probe_version(e); };
    std::vector<ProviderStatus> out;
    const bool antInstalled = !which_fn("ant").empty();
    for (const auto& [name, p] : cfg.providers) {
        ProviderStatus s;
        s.name = name;
        s.kind = provider_kind_name(p.kind);
        s.isCli = is_cli_kind(p.kind);
        if (s.isCli) {
            std::string command = p.command.empty() ? default_cli_command(p.kind) : p.command;
            s.path = which_fn(command);
            s.available = !s.path.empty();
            if (s.available) {
                if (opt.probeVersions) s.version = version_fn(s.path);
                s.detail = "'" + command + "' found at " + s.path + (s.version.empty() ? "" : " (" + s.version + ")") +
                           "; uses your own subscription login";
            } else {
                s.detail = "'" + command + "' not found in PATH";
                s.hint = cli_install_hint(p);
            }
        } else {
            auto key = resolve_api_key(p, opt.env);
            s.keySource = key.source;
            const bool local = p.preset == "ollama" || p.preset == "lmstudio" || (p.preset.empty() && p.kind == ProviderKind::OpenAICompatible && default_key_env(p).empty());
            if (key.found()) {
                s.available = true;
                s.detail = "API key found (" + key.source + ")";
            } else if (p.kind == ProviderKind::Anthropic && p.useAntCli && antInstalled) {
                s.available = true;
                s.keySource = "ant-cli";
                s.detail = "no ANTHROPIC_API_KEY, but the `ant` CLI is installed (uses `ant auth print-credentials`)";
                s.hint = "If requests fail with 401, run `ant auth login`.";
            } else if (local) {
                s.available = true;
                s.detail = "local server at " + p.baseUrl + " (no key needed; start it and load a model)";
            } else {
                std::string env = default_key_env(p);
                s.detail = "no API key";
                s.hint = "Set " + (env.empty() ? std::string("the key variable") : env) +
                         " or \"apiKeyEnv\"/\"apiKey\" in ~/.factoria/ai.json" +
                         (p.kind == ProviderKind::Anthropic ? "; or install the `ant` CLI and run `ant auth login`." : ".");
            }
        }
        out.push_back(std::move(s));
    }
    return out;
}

std::string format_doctor_report(const AiConfig& cfg, const std::vector<ProviderStatus>& status) {
    std::string out = "FactorIA AI providers";
    out += cfg.sourcePath.empty() ? " (no config file: built-in defaults)\n" : " (config: " + cfg.sourcePath + ")\n";
    for (const auto& s : status) {
        out += std::string(s.available ? "  [ok]   " : "  [--]   ") + s.name + " (" + s.kind + "): " + s.detail + "\n";
        if (!s.available && !s.hint.empty()) out += "         -> " + s.hint + "\n";
        else if (!s.hint.empty()) out += "         note: " + s.hint + "\n";
    }
    out += "Roles:\n";
    for (const auto& [role, r] : cfg.roles) {
        out += "  " + role + ": " + r.provider + " / " + r.model + (r.effort.empty() ? "" : " (effort " + r.effort + ")") + "\n";
    }
    for (const auto& w : cfg.warnings) out += "WARNING: " + w + "\n";
    return out;
}

}  // namespace fa::ai
