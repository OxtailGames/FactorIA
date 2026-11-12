#include "ai_env.h"

#include <algorithm>

namespace fa::ai {

namespace {

// What a program that talks to the network or keeps files under the user's folders needs. None is a secret of FactorIA's
// (a proxy address can carry a login, but the program is useless behind a proxy without it).
const char* const kNetworkAndConfig[] = {
    "XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_CACHE_HOME", "XDG_STATE_HOME",  // where CLIs keep settings, logins and caches
    "XDG_RUNTIME_DIR", "DBUS_SESSION_BUS_ADDRESS",                           // Linux: the keyring (libsecret) a login is kept in
    "HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY", "NO_PROXY",                    // proxies, both spellings
    "http_proxy", "https_proxy", "all_proxy", "no_proxy",
    "SSL_CERT_FILE", "SSL_CERT_DIR", "NODE_EXTRA_CA_CERTS",                  // company certificate authorities
    "REQUESTS_CA_BUNDLE", "CURL_CA_BUNDLE",
};
// NODE_OPTIONS is not here on purpose: it can make Node load any script (--require), so a hook or project cannot be allowed to
// inherit it by default. A user who needs it lists it in "inheritEnv".

void add(std::vector<std::string>& out, const std::string& name) {
    if (!name.empty() && std::find(out.begin(), out.end(), name) == out.end()) out.push_back(name);
}

void add_all(std::vector<std::string>& out, const std::vector<std::string>& names) {
    for (const std::string& n : names) add(out, n);
}

}  // namespace

std::vector<std::string> plain_inherit_env() {
    std::vector<std::string> out = fa::base_child_env();
    for (const char* n : kNetworkAndConfig) add(out, n);
    return out;
}

std::vector<std::string> provider_inherit_env(const ProviderConfig& cfg) {
    std::vector<std::string> out = plain_inherit_env();
    switch (cfg.kind) {
        case ProviderKind::ClaudeCode:
        case ProviderKind::Anthropic:  // the `ant` CLI, which shares Claude Code's login variables
            add(out, "CLAUDE_*");      // CLAUDE_CONFIG_DIR, CLAUDE_CODE_OAUTH_TOKEN, CLAUDE_CODE_USE_BEDROCK...
            add(out, "ANTHROPIC_*");   // ANTHROPIC_API_KEY, ANTHROPIC_AUTH_TOKEN, ANTHROPIC_BASE_URL...
            break;
        case ProviderKind::Codex:
            add(out, "CODEX_*");   // CODEX_HOME...
            add(out, "OPENAI_*");  // OPENAI_API_KEY, OPENAI_BASE_URL...
            break;
        default:
            break;
    }
    add(out, default_key_env(cfg));  // this provider's own key variable (apiKeyEnv, or its preset's)
    add_all(out, cfg.inheritEnvGlobal);
    add_all(out, cfg.inheritEnv);
    return out;
}

std::vector<std::string> tool_server_inherit_env(const ResolvedToolServer& server) {
    std::vector<std::string> out = plain_inherit_env();
    add_all(out, server.inheritEnv);
    return out;
}

}  // namespace fa::ai
