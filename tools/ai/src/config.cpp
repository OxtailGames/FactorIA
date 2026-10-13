#include "fa/ai/config.h"

#include <algorithm>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <sstream>

#ifndef _WIN32
#include <sys/stat.h>
#endif

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "util.h"

namespace fa::ai {

namespace fsys = std::filesystem;
using namespace util;

const char* provider_kind_name(ProviderKind k) {
    switch (k) {
        case ProviderKind::Anthropic: return "anthropic";
        case ProviderKind::OpenAICompatible: return "openai-compatible";
        case ProviderKind::ClaudeCode: return "claude-code";
        case ProviderKind::Codex: return "codex";
        case ProviderKind::GenericCli: return "generic-cli";
    }
    return "?";
}

bool is_cli_kind(ProviderKind k) {
    return k == ProviderKind::ClaudeCode || k == ProviderKind::Codex || k == ProviderKind::GenericCli;
}

static bool parse_kind(std::string_view s, ProviderKind& out) {
    for (auto k : {ProviderKind::Anthropic, ProviderKind::OpenAICompatible, ProviderKind::ClaudeCode,
                   ProviderKind::Codex, ProviderKind::GenericCli}) {
        if (s == provider_kind_name(k)) { out = k; return true; }
    }
    return false;
}

EnvLookup system_env() {
    return [](const std::string& name) -> std::string {
        const char* v = std::getenv(name.c_str());
        return v ? v : "";
    };
}

const ProviderConfig* AiConfig::provider(std::string_view name) const {
    auto it = providers.find(std::string(name));
    return it == providers.end() ? nullptr : &it->second;
}

RoleConfig AiConfig::role(std::string_view name) const {
    auto it = roles.find(std::string(name));
    if (it != roles.end()) return it->second;
    it = roles.find(kRoleWorker);
    return it != roles.end() ? it->second : RoleConfig{};
}

std::string default_config_path(const EnvLookup& env) {
    if (auto o = env("FACTORIA_AI_CONFIG"); !o.empty()) return o;
#ifdef _WIN32
    if (auto a = env("APPDATA"); !a.empty()) return (fsys::path(a) / "factoria" / "ai.json").string();
    if (auto h = env("USERPROFILE"); !h.empty()) return (fsys::path(h) / ".factoria" / "ai.json").string();
#else
    if (auto h = env("HOME"); !h.empty()) return (fsys::path(h) / ".factoria" / "ai.json").string();
#endif
    return ".factoria/ai.json";
}

// ---------------------------------------------------------------------------
// Presets and built-in providers

namespace {

struct Preset {
    const char* name;
    const char* baseUrl;
    const char* keyEnv;
};
constexpr Preset kPresets[] = {
    {"openai", "https://api.openai.com/v1", "OPENAI_API_KEY"},
    {"openrouter", "https://openrouter.ai/api/v1", "OPENROUTER_API_KEY"},
    {"gemini", "https://generativelanguage.googleapis.com/v1beta/openai", "GEMINI_API_KEY"},
    {"groq", "https://api.groq.com/openai/v1", "GROQ_API_KEY"},
    {"deepseek", "https://api.deepseek.com/v1", "DEEPSEEK_API_KEY"},
    {"ollama", "http://localhost:11434/v1", ""},
    {"lmstudio", "http://localhost:1234/v1", ""},
};

const Preset* find_preset(std::string_view n) {
    for (const auto& p : kPresets) if (n == p.name) return &p;
    return nullptr;
}

constexpr const char* kPlaceholderModel = "CHANGE_ME";

ProviderConfig make_preset_provider(const Preset& p) {
    ProviderConfig c;
    c.name = p.name;
    c.kind = ProviderKind::OpenAICompatible;
    c.preset = p.name;
    c.baseUrl = p.baseUrl;
    c.apiKeyEnv = p.keyEnv;
    c.defaultModel = kPlaceholderModel;
    return c;
}

struct RoleDefault {
    const char* role;
    const char* model;
    const char* effort;
};
constexpr RoleDefault kAnthropicRoles[] = {
    {kRoleOrchestrator, "claude-opus-5-5", "xhigh"},
    {kRoleWorker, "claude-sonnet-5-5", "medium"},
    {kRoleFast, "claude-haiku-5-5", "max"},
};

}  // namespace

std::string default_key_env(const ProviderConfig& p) {
    if (!p.apiKeyEnv.empty()) return p.apiKeyEnv;
    if (p.kind == ProviderKind::Anthropic) return "ANTHROPIC_API_KEY";
    if (auto* pr = find_preset(p.preset)) return pr->keyEnv;
    return {};
}

std::vector<std::string> default_cli_argv(ProviderKind kind) {
    switch (kind) {
        case ProviderKind::ClaudeCode:
            return {"-p", "{prompt}", "--output-format", "stream-json", "--verbose", "--model", "{model}",
                    "--mcp-config", "{mcp_config}", "--permission-mode", "acceptEdits"};
        case ProviderKind::Codex:
            return {"exec", "--json", "-m", "{model}", "-c", "mcp_servers.factoria.command={factoria_json}",
                    "-c", "mcp_servers.factoria.args=[\"mcp\",\"--project\",{project_json}]", "{prompt}"};
        default: return {};
    }
}

std::string default_cli_command(ProviderKind kind) {
    switch (kind) {
        case ProviderKind::ClaudeCode: return "claude";
        case ProviderKind::Codex: return "codex";
        default: return {};
    }
}

std::map<std::string, RoleConfig> default_roles_for(const AiConfig& cfg) {
    std::map<std::string, RoleConfig> roles;
    const ProviderConfig* dp = cfg.provider(cfg.defaultProvider);
    for (const auto& d : kAnthropicRoles) {
        RoleConfig r;
        r.provider = cfg.defaultProvider;
        if (!dp || dp->kind == ProviderKind::Anthropic) {
            r.model = d.model;
            r.effort = d.effort;
        } else {
            r.model = dp->defaultModel;
        }
        roles[d.role] = r;
    }
    return roles;
}

AiConfig default_config() {
    AiConfig cfg;
    {
        ProviderConfig a;
        a.name = "anthropic";
        a.kind = ProviderKind::Anthropic;
        a.baseUrl = "https://api.anthropic.com";
        a.apiKeyEnv = "ANTHROPIC_API_KEY";
        a.defaultModel = "claude-sonnet-5-5";
        cfg.providers["anthropic"] = a;
    }
    for (const auto& p : kPresets) cfg.providers[p.name] = make_preset_provider(p);
    for (auto kind : {ProviderKind::ClaudeCode, ProviderKind::Codex}) {
        ProviderConfig c;
        c.name = provider_kind_name(kind);
        c.kind = kind;
        c.command = default_cli_command(kind);
        c.defaultModel = kind == ProviderKind::ClaudeCode ? "sonnet" : "";
        cfg.providers[c.name] = c;
    }
    cfg.roles = default_roles_for(cfg);
    return cfg;
}

// ---------------------------------------------------------------------------
// Validation / parsing

std::vector<SchemaError> validate_config_json(const Json& j) {
    Json schema = util::parse(config_schema_text());
    if (schema.is_discarded()) {
        return {SchemaError{"", "internal error: embedded ai-config schema is not valid JSON", ""}};
    }
    return validate_json(schema, j);
}

static std::string errors_to_string(const std::vector<SchemaError>& errs) {
    std::string out;
    for (const auto& e : errs) {
        if (!out.empty()) out += "\n";
        out += e.to_string();
    }
    return out;
}

static void read_pricing(const Json& j, Pricing& p) {
    p.input = num(j, "inputPerMTok");
    p.output = num(j, "outputPerMTok");
    p.cacheRead = num(j, "cacheReadPerMTok", p.input * 0.1);
    p.cacheWrite = num(j, "cacheWritePerMTok", p.input * 1.25);
    p.known = true;
}

Result<AiConfig> parse_config(const Json& j, std::string_view sourceName) {
    auto errs = validate_config_json(j);
    if (!errs.empty()) {
        return make_error(std::string(sourceName) + " is not a valid FactorIA AI config:\n" + errors_to_string(errs),
                          "See docs/AI_PROVIDERS.md for the format, or schemas/ai-config.schema.json.");
    }
    AiConfig cfg = default_config();
    cfg.sourcePath = std::string(sourceName);
    cfg.defaultProvider = str(j, "defaultProvider", cfg.defaultProvider);

    bool anyApiKey = false;
    if (const Json* provs = child(j, "providers")) {
        for (auto it = provs->begin(); it != provs->end(); ++it) {
            const std::string name = it.key();
            const Json& pj = it.value();
            ProviderConfig c;
            bool existing = false;
            if (auto f = cfg.providers.find(name); f != cfg.providers.end()) { c = f->second; existing = true; }
            c.name = name;
            if (auto t = str(pj, "type"); !t.empty()) {
                ProviderKind k;
                if (!parse_kind(t, k)) {
                    return make_error(std::string(sourceName) + ": /providers/" + name + "/type: unknown type '" + t + "'");
                }
                if (existing && k != c.kind) {
                    // Re-typing a built-in: start from a clean provider.
                    ProviderConfig fresh;
                    fresh.name = name;
                    c = fresh;
                }
                c.kind = k;
            } else if (!existing) {
                return make_error(
                    std::string(sourceName) + ": /providers/" + name + ": custom provider needs a \"type\"",
                    "Add \"type\": \"openai-compatible\" (APIs), \"claude-code\", \"codex\" or \"generic-cli\" (CLI agents).");
            }
            if (auto p = str(pj, "preset"); !p.empty()) {
                c.preset = p;
                if (auto* pr = find_preset(p)) {
                    if (c.baseUrl.empty() || !pj.contains("baseUrl")) c.baseUrl = pr->baseUrl;
                    if (!pj.contains("apiKeyEnv")) c.apiKeyEnv = pr->keyEnv;
                    if (c.defaultModel.empty()) c.defaultModel = kPlaceholderModel;
                }
            }
            if (c.kind == ProviderKind::OpenAICompatible && c.defaultModel.empty()) c.defaultModel = kPlaceholderModel;
            if (pj.contains("baseUrl")) c.baseUrl = str(pj, "baseUrl");
            if (pj.contains("apiKeyEnv")) c.apiKeyEnv = str(pj, "apiKeyEnv");
            if (pj.contains("apiKey")) { c.apiKey = str(pj, "apiKey"); anyApiKey = anyApiKey || !c.apiKey.empty(); }
            if (const Json* h = child(pj, "headers")) {
                c.headers.clear();
                for (auto hi = h->begin(); hi != h->end(); ++hi) {
                    if (hi.value().is_string()) c.headers.emplace_back(hi.key(), hi.value().get<std::string>());
                }
            }
            if (pj.contains("defaultModel")) c.defaultModel = str(pj, "defaultModel");
            c.useAntCli = flag(pj, "useAntCli", c.useAntCli);
            c.sendReasoningEffort = flag(pj, "sendReasoningEffort", c.sendReasoningEffort);
            if (pj.contains("command")) c.command = str(pj, "command");
            if (const Json* a = child(pj, "argv")) {
                c.argv.clear();
                for (const auto& e : *a) c.argv.push_back(e.get<std::string>());
            }
            if (const Json* e = child(pj, "env")) {
                for (auto ei = e->begin(); ei != e->end(); ++ei) c.env[ei.key()] = ei.value().get<std::string>();
            }
            if (const Json* u = child(pj, "unsetEnv")) {
                c.unsetEnv.clear();
                for (const auto& e : *u) c.unsetEnv.push_back(e.get<std::string>());
            }
            if (pj.contains("factoriaCommand")) c.factoriaCommand = str(pj, "factoriaCommand");
            if (const Json* pr = child(pj, "pricing")) read_pricing(*pr, c.pricing);
            c.maxRetries = static_cast<int>(num(pj, "maxRetries", c.maxRetries));
            c.timeoutSeconds = num(pj, "timeoutSeconds", c.timeoutSeconds);
            if (is_cli_kind(c.kind) && c.command.empty()) {
                c.command = default_cli_command(c.kind);
                if (c.command.empty()) {
                    return make_error(std::string(sourceName) + ": /providers/" + name + "/command: required for generic-cli",
                                      "Set \"command\" and \"argv\" (placeholders {prompt} {model} {project} {mcp_config}).");
                }
            }
            if (c.kind == ProviderKind::OpenAICompatible && c.baseUrl.empty()) {
                return make_error(std::string(sourceName) + ": /providers/" + name + "/baseUrl: missing",
                                  "Set \"baseUrl\" (e.g. https://openrouter.ai/api/v1) or a \"preset\".");
            }
            cfg.providers[name] = std::move(c);
        }
    }
    if (!cfg.provider(cfg.defaultProvider)) {
        std::vector<std::string> names;
        for (const auto& [n, _] : cfg.providers) names.push_back(n);
        return make_error(std::string(sourceName) + ": /defaultProvider: unknown provider '" + cfg.defaultProvider + "'",
                          fa::did_you_mean(cfg.defaultProvider, names));
    }

    // Roles: defaults first, then overrides.
    cfg.roles = default_roles_for(cfg);
    if (const Json* roles = child(j, "roles")) {
        for (auto it = roles->begin(); it != roles->end(); ++it) {
            RoleConfig r = cfg.roles[it.key()];
            const Json& rj = it.value();
            const bool setProvider = rj.contains("provider");
            if (setProvider) r.provider = str(rj, "provider");
            if (r.provider.empty()) r.provider = cfg.defaultProvider;
            const ProviderConfig* p = cfg.provider(r.provider);
            if (!p) {
                std::vector<std::string> names;
                for (const auto& [n, _] : cfg.providers) names.push_back(n);
                return make_error(std::string(sourceName) + ": /roles/" + it.key() + "/provider: unknown provider '" +
                                      r.provider + "'",
                                  fa::did_you_mean(r.provider, names));
            }
            // Provider changed => model/effort defaults come from the new provider.
            if (setProvider) {
                r.model.clear();
                r.effort.clear();
            }
            RoleDefault rd{};
            for (const auto& d : kAnthropicRoles) if (it.key() == d.role) rd = d;
            if (rj.contains("model")) r.model = str(rj, "model");
            else if (r.model.empty()) r.model = p->kind == ProviderKind::Anthropic && rd.model ? rd.model : p->defaultModel;
            if (rj.contains("effort")) r.effort = str(rj, "effort");
            else if (r.effort.empty() && p->kind == ProviderKind::Anthropic && rd.effort) r.effort = rd.effort;
            if (rj.contains("maxTokens")) r.maxTokens = static_cast<int>(num(rj, "maxTokens"));
            cfg.roles[it.key()] = std::move(r);
        }
    }
    if (const Json* l = child(j, "limits")) {
        cfg.limits.maxTurns = static_cast<int>(num(*l, "maxTurns", cfg.limits.maxTurns));
        cfg.limits.maxCostUsd = num(*l, "maxCostUsd", cfg.limits.maxCostUsd);
        cfg.limits.maxTotalTokens = static_cast<u64>(num(*l, "maxTotalTokens", 0));
    }
    (void)anyApiKey;
    return cfg;
}

Result<AiConfig> load_config(std::string_view pathIn, const EnvLookup& env) {
    std::string path = pathIn.empty() ? default_config_path(env) : std::string(pathIn);
    std::error_code ec;
    if (!fsys::exists(fsys::path(path), ec)) {
        AiConfig cfg = default_config();
        return cfg;
    }
    std::ifstream f(path, std::ios::binary);
    if (!f) return make_error("Cannot read AI config '" + path + "'", "Check file permissions.");
    std::stringstream ss;
    ss << f.rdbuf();
    auto parsed = fa::parse_json(ss.str(), path);
    if (!parsed) return parsed.error();
    auto cfg = parse_config(*parsed, path);
    if (!cfg) return cfg;
#ifndef _WIN32
    bool hasKey = false;
    for (const auto& [n, p] : cfg->providers) hasKey = hasKey || !p.apiKey.empty();
    struct stat st{};
    if (hasKey && stat(path.c_str(), &st) == 0 && (st.st_mode & (S_IRWXG | S_IRWXO)) != 0) {
        cfg->warnings.push_back(path + " contains an API key but is readable by other users. Run: chmod 600 " + path);
    }
#endif
    return cfg;
}

Json config_to_json(const AiConfig& cfg, bool redactKeys) {
    Json out = Json::object();
    out["defaultProvider"] = cfg.defaultProvider;
    Json provs = Json::object();
    for (const auto& [name, p] : cfg.providers) {
        Json pj = Json::object();
        pj["type"] = provider_kind_name(p.kind);
        if (!p.preset.empty()) pj["preset"] = p.preset;
        if (!p.baseUrl.empty()) pj["baseUrl"] = p.baseUrl;
        if (!p.apiKeyEnv.empty()) pj["apiKeyEnv"] = p.apiKeyEnv;
        if (!p.apiKey.empty()) pj["apiKey"] = redactKeys ? "***" : p.apiKey;
        if (!p.headers.empty()) {
            Json h = Json::object();
            for (const auto& [k, v] : p.headers) h[k] = v;
            pj["headers"] = h;
        }
        if (!p.defaultModel.empty()) pj["defaultModel"] = p.defaultModel;
        if (!p.command.empty()) pj["command"] = p.command;
        if (!p.argv.empty()) pj["argv"] = p.argv;
        if (!p.env.empty()) {
            Json e = Json::object();
            for (const auto& [k, v] : p.env) e[k] = v;
            pj["env"] = e;
        }
        provs[name] = pj;
    }
    out["providers"] = provs;
    Json roles = Json::object();
    for (const auto& [name, r] : cfg.roles) {
        Json rj = Json::object();
        rj["provider"] = r.provider;
        rj["model"] = r.model;
        if (!r.effort.empty()) rj["effort"] = r.effort;
        if (r.maxTokens > 0) rj["maxTokens"] = r.maxTokens;
        roles[name] = rj;
    }
    out["roles"] = roles;
    out["limits"] = Json::object({{"maxTurns", cfg.limits.maxTurns},
                                  {"maxCostUsd", cfg.limits.maxCostUsd},
                                  {"maxTotalTokens", cfg.limits.maxTotalTokens}});
    return out;
}

Result<void> save_config(const AiConfig& cfg, std::string_view path) {
    fsys::path p(path);
    std::error_code ec;
    if (p.has_parent_path()) fsys::create_directories(p.parent_path(), ec);
    std::ofstream f(p, std::ios::binary | std::ios::trunc);
    if (!f) return make_error("Cannot write AI config '" + std::string(path) + "'", "Check the directory exists and is writable.");
    f << dump_json(config_to_json(cfg, false));
#ifndef _WIN32
    fsys::permissions(p, fsys::perms::owner_read | fsys::perms::owner_write, ec);
#endif
    return {};
}

ResolvedKey resolve_api_key(const ProviderConfig& p, const EnvLookup& env) {
    ResolvedKey r;
    if (!p.apiKeyEnv.empty()) {
        if (auto v = env(p.apiKeyEnv); !v.empty()) return {v, "env:" + p.apiKeyEnv};
    }
    if (!p.apiKey.empty()) return {p.apiKey, "config"};
    std::string def = default_key_env(p);
    if (!def.empty() && def != p.apiKeyEnv) {
        if (auto v = env(def); !v.empty()) return {v, "env:" + def};
    }
    return r;
}

// ---------------------------------------------------------------------------
// Key scanning

namespace {
bool is_key_char(char c) {
    return std::isalnum(static_cast<unsigned char>(c)) || c == '_' || c == '-';
}
struct KeyPrefix {
    const char* prefix;
    std::size_t minTail;
};
constexpr KeyPrefix kKeyPrefixes[] = {
    {"sk-ant-", 16}, {"sk-or-", 16}, {"sk-proj-", 16}, {"sk-", 32}, {"AIza", 30}, {"gsk_", 24}, {"xai-", 24},
};
}  // namespace

bool looks_like_api_key(std::string_view text) {
    for (const auto& kp : kKeyPrefixes) {
        std::string_view pre = kp.prefix;
        std::size_t pos = 0;
        while ((pos = text.find(pre, pos)) != std::string_view::npos) {
            bool boundary = pos == 0 || !is_key_char(text[pos - 1]);
            std::size_t tail = 0;
            std::size_t i = pos + pre.size();
            while (i < text.size() && is_key_char(text[i])) { ++i; ++tail; }
            if (boundary && tail >= kp.minTail) return true;
            pos += pre.size();
        }
    }
    return false;
}

std::vector<std::string> scan_project_for_keys(const std::string& projectDir, std::size_t maxFiles) {
    std::vector<std::string> out;
    std::error_code ec;
    fsys::path root(projectDir);
    if (!fsys::is_directory(root, ec)) return out;
    std::size_t files = 0;
    for (auto it = fsys::recursive_directory_iterator(root, fsys::directory_options::skip_permission_denied, ec);
         it != fsys::recursive_directory_iterator(); it.increment(ec)) {
        if (ec) break;
        const auto& entry = *it;
        const std::string name = entry.path().filename().string();
        if (entry.is_directory(ec)) {
            if (name == ".git" || name == "build" || name == ".factoria" || name == "node_modules" || name == ".cache")
                it.disable_recursion_pending();
            continue;
        }
        if (!entry.is_regular_file(ec)) continue;
        auto size = entry.file_size(ec);
        if (ec || size == 0 || size > (1u << 20)) continue;
        if (++files > maxFiles) break;
        std::ifstream f(entry.path(), std::ios::binary);
        std::string line;
        std::size_t lineNo = 0;
        while (std::getline(f, line)) {
            ++lineNo;
            if (line.find('\0') != std::string::npos) break;  // binary
            if (looks_like_api_key(line)) {
                out.push_back(fsys::relative(entry.path(), root, ec).generic_string() + ":" + std::to_string(lineNo) +
                              ": looks like an API key. Keys must live in ~/.factoria/ai.json or environment variables, "
                              "never in the project.");
                break;
            }
        }
    }
    return out;
}

}  // namespace fa::ai
