#include "fa/ai/detect.h"

#include "fa/ai/process.h"
#include "fa/core/strings.h"
#include "fa/ai/cli_agent.h"
#include "util.h"

namespace fa::ai {

Json ProviderStatus::to_json() const {
    return Json::object({{"name", name}, {"kind", kind}, {"cli", isCli}, {"available", available}, {"detail", detail},
                         {"version", version}, {"path", path}, {"keySource", keySource}, {"hint", hint},
                         {"makes", makes}});
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
    auto which_fn = opt.which ? opt.which : [&opt](const std::string& n) { return find_cli(n, opt.env); };
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
        } else if (p.kind == ProviderKind::Fake) {
            s.available = true;
            s.detail = "offline placeholders for tests and for trying the asset pipeline (costs nothing)";
        } else if (p.kind == ProviderKind::AssetCommand) {
            s.path = which_fn(p.command);
            s.available = !s.path.empty();
            s.detail = s.available ? "'" + p.command + "' found at " + s.path : "'" + p.command + "' not found in PATH";
            if (!s.available) s.hint = cli_install_hint(p);
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
        if (is_asset_only_kind(p.kind) || p.preset == "openai") {
            for (MediaKind k : kMediaKinds) {
                if (provider_makes(p.kind, k)) s.makes.push_back(media_kind_name(k));
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
        out += std::string(s.available ? "  [ok]   " : "  [--]   ") + s.name + " (" + s.kind + "): " + s.detail +
               (s.makes.empty() ? "" : " [makes " + fa::join(s.makes, ", ") + "]") + "\n";
        if (!s.available && !s.hint.empty()) out += "         -> " + s.hint + "\n";
        else if (!s.hint.empty()) out += "         note: " + s.hint + "\n";
    }
    out += "Roles:\n";
    for (const auto& [role, r] : cfg.roles) {
        out += "  " + role + ": " + r.provider + " / " + r.model + (r.effort.empty() ? "" : " (effort " + r.effort + ")") + "\n";
    }
    out += "Asset providers:\n";
    for (MediaKind k : kMediaKinds) {
        const auto r = cfg.assets.find(media_kind_name(k));
        if (r == cfg.assets.end()) continue;
        out += std::string("  ") + media_kind_name(k) + ": " + r->second.provider +
               (r->second.model.empty() ? "" : " / " + r->second.model) + "\n";
    }
    if (cfg.assets.empty()) out += "  none configured: add \"assets\" to ai.json (docs/AI_PROVIDERS.md, Asset providers)\n";
    for (const auto& w : cfg.warnings) out += "WARNING: " + w + "\n";
    return out;
}

}  // namespace fa::ai
