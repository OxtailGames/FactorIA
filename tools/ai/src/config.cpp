#include "fa/ai/config.h"

#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <utility>

#ifndef _WIN32
#include <sys/stat.h>
#include <unistd.h>
#endif

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/tooling/mcp_config.h"
#include "fa/tooling/user_config.h"
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
        case ProviderKind::ElevenLabs: return "elevenlabs";
        case ProviderKind::Meshy: return "meshy";
        case ProviderKind::Fake: return "fake";
        case ProviderKind::AssetCommand: return "asset-command";
    }
    return "?";
}

bool is_cli_kind(ProviderKind k) {
    return k == ProviderKind::ClaudeCode || k == ProviderKind::Codex || k == ProviderKind::GenericCli;
}

bool is_asset_only_kind(ProviderKind k) {
    return k == ProviderKind::ElevenLabs || k == ProviderKind::Meshy || k == ProviderKind::Fake ||
           k == ProviderKind::AssetCommand;
}

const char* media_kind_name(MediaKind k) {
    switch (k) {
        case MediaKind::Image: return "image";
        case MediaKind::Sound: return "sound";
        case MediaKind::Music: return "music";
        case MediaKind::Voice: return "voice";
        case MediaKind::Model3d: return "model3d";
    }
    return "?";
}

std::string providers_that_make(const AiConfig& cfg, MediaKind m) {
    std::vector<std::string> names;
    for (const auto& [name, p] : cfg.providers) {
        if (provider_makes(p.kind, m)) names.push_back(name);
    }
    return fa::join(names, ", ");
}

const char* site_category_key(SiteCategory c) {
    switch (c) {
        case SiteCategory::Images: return "images";
        case SiteCategory::Models: return "models";
        case SiteCategory::Audio: return "audio";
        case SiteCategory::Fonts: return "fonts";
        case SiteCategory::Other: return "other";
    }
    return "?";
}

const char* site_category_title(SiteCategory c) {
    switch (c) {
        case SiteCategory::Images: return "Images and textures";
        case SiteCategory::Models: return "3D models";
        case SiteCategory::Audio: return "Audio (sounds and music)";
        case SiteCategory::Fonts: return "Fonts";
        case SiteCategory::Other: return "Other";
    }
    return "?";
}

std::vector<AssetSite>& AssetSources::list(SiteCategory c) {
    switch (c) {
        case SiteCategory::Images: return images;
        case SiteCategory::Models: return models;
        case SiteCategory::Audio: return audio;
        case SiteCategory::Fonts: return fonts;
        default: return other;
    }
}

const std::vector<AssetSite>& AssetSources::list(SiteCategory c) const { return const_cast<AssetSources*>(this)->list(c); }

bool AssetSources::empty() const {
    return images.empty() && models.empty() && audio.empty() && fonts.empty() && other.empty();
}

std::string asset_site_host(std::string_view in) {
    std::string s(fa::trim(in));
    if (s.empty()) return {};
    for (char c : s) {
        if (std::isspace(static_cast<unsigned char>(c)) || std::iscntrl(static_cast<unsigned char>(c))) return {};
    }
    if (const auto scheme = s.find("://"); scheme != std::string::npos) {
        for (std::size_t i = 0; i < scheme; ++i) {
            const char c = s[i];
            if (!std::isalnum(static_cast<unsigned char>(c)) && c != '+' && c != '-' && c != '.') return {};
        }
        if (scheme == 0) return {};
        s.erase(0, scheme + 3);
    }
    s = s.substr(0, s.find_first_of("/?#"));
    if (const auto at = s.rfind('@'); at != std::string::npos) s.erase(0, at + 1);
    if (const auto colon = s.rfind(':'); colon != std::string::npos) {
        const std::string port = s.substr(colon + 1);
        if (!port.empty() && !std::all_of(port.begin(), port.end(), [](char c) { return std::isdigit(static_cast<unsigned char>(c)); })) return {};
        s.erase(colon);
    }
    while (!s.empty() && s.back() == '.') s.pop_back();
    s = util::lower(std::move(s));
    if (s.empty()) return {};
    // Labels of letters, digits, '-' and '_' separated by single dots; a name needs a dot (or is "localhost").
    std::size_t labelStart = 0;
    for (std::size_t i = 0; i <= s.size(); ++i) {
        if (i < s.size() && s[i] != '.') {
            const char c = s[i];
            if (!std::isalnum(static_cast<unsigned char>(c)) && c != '-' && c != '_') return {};
            continue;
        }
        if (i == labelStart || s[labelStart] == '-' || s[i - 1] == '-') return {};
        labelStart = i + 1;
    }
    if (s.find('.') == std::string::npos && s != "localhost") return {};
    return s;
}

std::vector<std::string> asset_source_hosts(const AssetSources& sources) {
    std::vector<std::string> out;
    for (SiteCategory c : kSiteCategories) {
        for (const AssetSite& site : sources.list(c)) {
            const std::string host = asset_site_host(site.url);
            if (!host.empty() && std::find(out.begin(), out.end(), host) == out.end()) out.push_back(host);
        }
    }
    return out;
}

namespace {

std::string default_asset_base_url(ProviderKind k) {
    return k == ProviderKind::ElevenLabs ? "https://api.elevenlabs.io" : k == ProviderKind::Meshy ? "https://api.meshy.ai" : std::string();
}

}  // namespace

bool provider_makes(ProviderKind k, MediaKind m) {
    switch (k) {
        case ProviderKind::OpenAICompatible: return m == MediaKind::Image || m == MediaKind::Voice;
        case ProviderKind::ElevenLabs: return m == MediaKind::Sound || m == MediaKind::Music || m == MediaKind::Voice;
        case ProviderKind::Meshy: return m == MediaKind::Model3d;
        case ProviderKind::Fake:
        case ProviderKind::AssetCommand: return true;
        default: return false;
    }
}

static bool parse_kind(std::string_view s, ProviderKind& out) {
    for (auto k : {ProviderKind::Anthropic, ProviderKind::OpenAICompatible, ProviderKind::ClaudeCode,
                   ProviderKind::Codex, ProviderKind::GenericCli, ProviderKind::ElevenLabs, ProviderKind::Meshy,
                   ProviderKind::Fake, ProviderKind::AssetCommand}) {
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

bool is_known_role(std::string_view role) {
    for (const char* r : kAllRoles) if (role == r) return true;
    return false;
}
bool is_review_role(std::string_view role) { return role == kRoleArtCritic || role == kRoleReviewer; }
bool is_delegable_role(std::string_view role) {
    return role == kRoleWorker || role == kRoleFast || role == kRoleArtist || role == kRoleAudio;
}
const char* role_summary(std::string_view role) {
    if (role == kRoleOrchestrator) return "plans, reviews and delegates to the other roles";
    if (role == kRoleWorker) return "implements features and fixes";
    if (role == kRoleFast) return "small mechanical edits, quickly";
    if (role == kRoleArtist) return "makes the game's art: images, textures, sprites, models, UI skins, the look";
    if (role == kRoleAudio) return "makes the game's audio: sound effects, music, voice, mixing";
    if (role == kRoleArtCritic) return "art critics: look at the game and judge its art (read-only, asked by you)";
    if (role == kRoleReviewer) return "game reviewers: play the game, review it and score it (read-only, asked by you)";
    return "";
}

const ProviderConfig* AiConfig::provider(std::string_view name) const {
    auto it = providers.find(std::string(name));
    return it == providers.end() ? nullptr : &it->second;
}

const char* role_display_name(std::string_view role) {
    if (role == kRoleOrchestrator) return "Orchestrator";
    if (role == kRoleWorker) return "Worker";
    if (role == kRoleFast) return "Fast";
    if (role == kRoleArtist) return "Artist";
    if (role == kRoleAudio) return "Audio";
    if (role == kRoleArtCritic) return "Art critic";
    if (role == kRoleReviewer) return "Reviewer";
    static thread_local std::string unknown;
    unknown = std::string(role);
    return unknown.c_str();
}
int role_group(std::string_view role) {
    if (role == kRoleOrchestrator || role == kRoleWorker || role == kRoleFast) return 0;
    if (role == kRoleArtist || role == kRoleAudio) return 1;
    if (is_review_role(role)) return 2;
    return -1;
}
const char* role_group_title(int group) {
    switch (group) {
        case 0: return "Orchestration and code";
        case 1: return "Art and audio";
        case 2: return "Critics and reviewers";
        default: return "";
    }
}
std::string role_off_message(std::string_view role) {
    const std::string name = role_display_name(role);
    if (is_review_role(role)) {
        return "The " + name + " role is off, so its reviews run on the orchestrator's model";
    }
    return "The " + name + " role is off: the orchestrator does that work itself";
}
std::string role_off_hint(std::string_view role) {
    return "Do the work yourself (as the orchestrator) or ask the user to tick \"Enabled\" for " +
           std::string(role_display_name(role)) + " in the editor (AI > Roles...), or set roles." + std::string(role) +
           ".enabled to true in ~/.factoria/ai.json.";
}

bool AiConfig::role_enabled(std::string_view name) const {
    if (name == kRoleOrchestrator) return true;
    auto it = roles.find(std::string(name));
    return it == roles.end() || it->second.enabled;
}
RoleConfig AiConfig::effective_role(std::string_view name) const {
    if (is_review_role(name) && !role_enabled(name)) {
        RoleConfig rc = role(kRoleOrchestrator);
        rc.enabled = false;
        return rc;
    }
    return role(name);
}
std::vector<std::string> AiConfig::disabled_delegable_roles() const {
    std::vector<std::string> out;
    for (const char* r : kAllRoles) if (is_delegable_role(r) && !role_enabled(r)) out.push_back(r);
    return out;
}
bool AiConfig::can_delegate_to_anyone() const {
    for (const char* r : kAllRoles) if (is_delegable_role(r) && role_enabled(r)) return true;
    return false;
}

RoleConfig AiConfig::role(std::string_view name) const {
    auto it = roles.find(std::string(name));
    if (it != roles.end()) return it->second;
    it = roles.find(kRoleWorker);
    return it != roles.end() ? it->second : RoleConfig{};
}

std::string default_config_path(const EnvLookup& env) {
    if (auto o = env("FACTORIA_AI_CONFIG"); !o.empty()) return o;
    // The folder rule is shared with the other user-level files (feedback-sharing.json...): fa/tooling/user_config.h.
    return (fsys::path(user_config_dir(env)) / "ai.json").string();
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
    const char* model;   // Anthropic API
    const char* effort;  // Anthropic API and Claude Code
    const char* base;    // "" for the three original roles; else the role whose provider and model this one follows
};
constexpr RoleDefault kAnthropicRoles[] = {
    {kRoleOrchestrator, "claude-opus-5-5", "xhigh", ""},
    {kRoleWorker, "claude-sonnet-5-5", "medium", ""},
    {kRoleFast, "claude-haiku-5-5", "max", ""},
    {kRoleArtist, "claude-opus-5-5", "high", kRoleOrchestrator},
    {kRoleAudio, "claude-sonnet-5-5", "medium", kRoleWorker},
    {kRoleArtCritic, "claude-opus-5-5", "high", kRoleOrchestrator},
    {kRoleReviewer, "claude-opus-5-5", "high", kRoleOrchestrator},
};

const RoleDefault* find_role_default(std::string_view role) {
    for (const auto& d : kAnthropicRoles) if (role == d.role) return &d;
    return nullptr;
}

// artist, audio, artCritic and reviewer follow the roles the user already configured (`roles` holds the final
// orchestrator and worker): same provider and model, the role's own effort when the provider takes one.
void derive_extra_role(std::map<std::string, RoleConfig>& roles, const AiConfig& cfg, const RoleDefault& d) {
    auto it = roles.find(d.base);
    if (it == roles.end()) return;
    RoleConfig r = it->second;
    const ProviderConfig* p = cfg.provider(r.provider);
    if (!p || p->kind == ProviderKind::Anthropic || p->kind == ProviderKind::ClaudeCode) r.effort = d.effort;
    roles[d.role] = std::move(r);
}

}  // namespace

std::string default_key_env(const ProviderConfig& p) {
    if (!p.apiKeyEnv.empty()) return p.apiKeyEnv;
    if (p.kind == ProviderKind::Anthropic) return "ANTHROPIC_API_KEY";
    if (p.kind == ProviderKind::ElevenLabs) return "ELEVENLABS_API_KEY";
    if (p.kind == ProviderKind::Meshy) return "MESHY_API_KEY";
    if (auto* pr = find_preset(p.preset)) return pr->keyEnv;
    return {};
}

std::vector<std::string> default_cli_argv(ProviderKind kind) {
    switch (kind) {
        case ProviderKind::ClaudeCode:
            // No {prompt}: the prompt goes to standard input (npm installs these CLIs as .cmd files on Windows, and
            // cmd.exe cannot pass a multi-line argument). In -p mode Claude Code asks before every MCP tool, so the
            // engine's own tools are allowed up front. `--input-format stream-json` makes stdin one JSON message, which can
            // carry images; `--resume {session}` continues the chat's session (the argument disappears for the first message).
            return {"-p", "--output-format", "stream-json", "--input-format", "stream-json", "--verbose", "--model",
                    "{model}", "--resume", "{session}", "--mcp-config", "{mcp_config}", "--allowedTools", "mcp__factoria",
                    "--permission-mode", "acceptEdits"};
        case ProviderKind::Codex:
            return {"exec", "--json", "-m", "{model}", "-c", "mcp_servers.factoria.command={factoria_json}",
                    "-c", "mcp_servers.factoria.args=[\"mcp\",\"--project\",{project_json}]",
                    // Codex gives up on an MCP tool call after 60 s by default; an ai_run call runs for minutes.
                    "-c", "mcp_servers.factoria.tool_timeout_sec=" + std::to_string(kCodexMcpToolTimeoutSec), "-"};
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
        if (*d.base) continue;
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
    for (const auto& d : kAnthropicRoles) if (*d.base) derive_extra_role(roles, cfg, d);
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
    // Asset providers (docs/AI_PROVIDERS.md, "Asset providers"); `openai` above makes images and voice too.
    {
        ProviderConfig e;
        e.name = "elevenlabs";
        e.kind = ProviderKind::ElevenLabs;
        e.baseUrl = default_asset_base_url(e.kind);
        cfg.providers[e.name] = e;
        ProviderConfig m;
        m.name = "meshy";
        m.kind = ProviderKind::Meshy;
        m.baseUrl = default_asset_base_url(m.kind);
        cfg.providers[m.name] = m;
        ProviderConfig f;
        f.name = "fake";
        f.kind = ProviderKind::Fake;
        cfg.providers[f.name] = f;
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
            if (pj.contains("apiKey")) {
                c.apiKey = str(pj, "apiKey");
                anyApiKey = anyApiKey || !c.apiKey.empty();
                // A key written in the file beats the preset's conventional env var (unless apiKeyEnv is also given).
                if (!pj.contains("apiKeyEnv")) c.apiKeyEnv.clear();
            }
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
            if (pj.contains("license")) c.license = str(pj, "license");
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
            if (c.kind == ProviderKind::AssetCommand && c.command.empty()) {
                return make_error(std::string(sourceName) + ": /providers/" + name + "/command: required for asset-command",
                                  "Set \"command\" and \"argv\" (placeholders {prompt} {output} {width} {height} {seconds} "
                                  "{kind} {model} {seed}).");
            }
            if (c.baseUrl.empty()) c.baseUrl = default_asset_base_url(c.kind);
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

    if (is_asset_only_kind(cfg.provider(cfg.defaultProvider)->kind)) {
        return make_error(std::string(sourceName) + ": /defaultProvider: '" + cfg.defaultProvider + "' only generates assets",
                          "defaultProvider runs the agent roles: use a chat provider (anthropic, claude-code, openai...). "
                          "Asset providers go under \"assets\".");
    }
    if (const Json* assets = child(j, "assets")) {
        for (auto it = assets->begin(); it != assets->end(); ++it) {
            const MediaKind* kind = nullptr;
            for (const MediaKind& k : kMediaKinds) {
                if (it.key() == media_kind_name(k)) kind = &k;
            }
            if (!kind) continue;  // the schema already rejected other keys
            AssetRoute r;
            r.provider = str(it.value(), "provider");
            r.model = str(it.value(), "model");
            r.voice = str(it.value(), "voice");
            const std::string at = std::string(sourceName) + ": /assets/" + it.key() + "/provider: ";
            const ProviderConfig* p = cfg.provider(r.provider);
            std::vector<std::string> names;
            for (const auto& [n, pc] : cfg.providers) names.push_back(n);
            if (!p) return make_error(at + "unknown provider '" + r.provider + "'", fa::did_you_mean(r.provider, names));
            if (!provider_makes(p->kind, *kind)) {
                return make_error(at + "'" + r.provider + "' (" + provider_kind_name(p->kind) + ") cannot generate " + it.key(),
                                  "Providers that can: " + providers_that_make(cfg, *kind) + ".");
            }
            cfg.assets[it.key()] = std::move(r);
        }
    }

    if (const Json* sources = child(j, "assetSources")) {
        cfg.assetSources.onlyListed = flag(*sources, "onlyListed");
        for (SiteCategory c : kSiteCategories) {
            const Json* list = child(*sources, site_category_key(c));
            if (!list || !list->is_array()) continue;
            std::size_t index = 0;
            for (const Json& entry : *list) {
                AssetSite site;
                site.url = entry.is_string() ? entry.get<std::string>() : str(entry, "url");
                site.note = entry.is_object() ? str(entry, "note") : std::string();
                if (asset_site_host(site.url).empty()) {
                    return make_error(std::string(sourceName) + ": /assetSources/" + site_category_key(c) + "/" + std::to_string(index) +
                                          (entry.is_string() ? "" : "/url") + ": '" + site.url + "' is not a web address",
                                      "Write a domain such as opengameart.org, or an address such as https://kenney.nl/assets "
                                      "(no spaces; put a comment in \"note\").");
                }
                cfg.assetSources.list(c).push_back(std::move(site));
                ++index;
            }
        }
    }

    if (const Json* servers = child(j, "mcpServers")) {
        auto parsed = parse_tool_servers(*servers, "/mcpServers");
        if (!parsed) return make_error(std::string(sourceName) + ": " + parsed.error().message, parsed.error().hint);
        cfg.toolServers = std::move(*parsed);
        for (const ToolServer& s : cfg.toolServers) {
            const bool secret = !s.apiKey.empty() || !s.apiKeyEnv.empty() || !s.headers.empty();
            if (s.enabled && s.type == "http" && s.url.rfind("http://", 0) == 0 && secret) {
                const std::string host = asset_site_host(s.url);
                if (host != "localhost" && host != "127.0.0.1" && host != "[::1]" && host != "::1") {
                    cfg.warnings.push_back(std::string(sourceName) + ": /mcpServers/" + s.name + "/url uses plain http://, so " +
                                           "its headers and key travel unencrypted. Use https:// if the server offers it.");
                }
            }
        }
    }

    if (const Json* ext = child(j, "extensions")) {
        auto parsed = parse_extensions(*ext, "/extensions", "user");
        if (!parsed) return make_error(std::string(sourceName) + ": " + parsed.error().message, parsed.error().hint);
        cfg.extensions = std::move(*parsed);
    }

    // Roles: defaults first, then overrides. The three original roles come first: artist, audio, artCritic and reviewer that
    // the file does not set follow what it says about them (same provider, model of the matching tier).
    cfg.roles = default_roles_for(cfg);
    const Json* roles = child(j, "roles");
    auto apply_role = [&](const std::string& name, const Json& rj) -> Result<void> {
        RoleConfig r = cfg.roles[name];
        const bool setProvider = rj.contains("provider");
        if (setProvider) r.provider = str(rj, "provider");
        if (r.provider.empty()) r.provider = cfg.defaultProvider;
        const ProviderConfig* p = cfg.provider(r.provider);
        if (!p) {
            std::vector<std::string> names;
            for (const auto& [n, _] : cfg.providers) names.push_back(n);
            return make_error(std::string(sourceName) + ": /roles/" + name + "/provider: unknown provider '" + r.provider + "'",
                              fa::did_you_mean(r.provider, names));
        }
        if (is_asset_only_kind(p->kind)) {
            return make_error(std::string(sourceName) + ": /roles/" + name + "/provider: '" + r.provider +
                                  "' only generates assets, it cannot play a role",
                              "Roles need a chat provider (anthropic, claude-code, openai...). Asset providers go under "
                              "\"assets\".");
        }
        // Provider changed => model/effort defaults come from the new provider.
        if (setProvider) {
            r.model.clear();
            r.effort.clear();
        }
        const RoleDefault* rd = find_role_default(name);
        if (rj.contains("model")) r.model = str(rj, "model");
        else if (r.model.empty()) r.model = p->kind == ProviderKind::Anthropic && rd ? rd->model : p->defaultModel;
        if (rj.contains("effort")) r.effort = str(rj, "effort");
        else if (r.effort.empty() && p->kind == ProviderKind::Anthropic && rd) r.effort = rd->effort;
        if (rj.contains("maxTokens")) r.maxTokens = static_cast<int>(num(rj, "maxTokens"));
        if (rj.contains("maxContextTokens")) r.maxContextTokens = static_cast<u64>(num(rj, "maxContextTokens"));
        if (rj.contains("enabled")) r.enabled = flag(rj, "enabled", true);
        if (const Json* groups = child(rj, "toolGroups")) {
            if (!groups->is_array()) {
                return make_error(std::string(sourceName) + ": /roles/" + name + "/toolGroups: must be an array of strings",
                                  "Name command categories or commands, e.g. \"toolGroups\": [\"assets\", \"anim\"]; [] loads none "
                                  "and [\"all\"] loads every command in full.");
            }
            std::vector<std::string> list;
            for (std::size_t i = 0; i < groups->size(); ++i) {
                const Json& g = (*groups)[i];
                if (!g.is_string() || g.get<std::string>().empty()) {
                    return make_error(std::string(sourceName) + ": /roles/" + name + "/toolGroups/" + std::to_string(i) +
                                          ": must be a non-empty string",
                                      "Name a command category (assets, anim, ui, publish...), a command (assets.draw_icon) or \"all\".");
                }
                list.push_back(g.get<std::string>());
            }
            r.toolGroups = std::move(list);
        }
        if (name == kRoleOrchestrator && !r.enabled) {
            return make_error(std::string(sourceName) + ": /roles/orchestrator/enabled: the orchestrator cannot be turned off",
                              "The orchestrator is the agent that talks to you and does the work of every role that is off. "
                              "Remove \"enabled\" from roles.orchestrator, or turn off worker, fast, artist or audio instead.");
        }
        cfg.roles[name] = std::move(r);
        return {};
    };
    if (roles && roles->is_object()) {
        for (auto it = roles->begin(); it != roles->end(); ++it) {
            if (const RoleDefault* d = find_role_default(it.key()); d && *d->base) continue;
            if (auto ok = apply_role(it.key(), it.value()); !ok) return ok.error();
        }
        for (const auto& d : kAnthropicRoles) {
            if (!*d.base) continue;
            derive_extra_role(cfg.roles, cfg, d);
            if (roles->contains(d.role)) {
                if (auto ok = apply_role(d.role, (*roles)[d.role]); !ok) return ok.error();
            }
        }
    } else {
        for (const auto& d : kAnthropicRoles) if (*d.base) derive_extra_role(cfg.roles, cfg, d);
    }
    if (const Json* l = child(j, "limits")) {
        cfg.limits.maxTurns = static_cast<int>(num(*l, "maxTurns", cfg.limits.maxTurns));
        cfg.limits.maxCostUsd = num(*l, "maxCostUsd", cfg.limits.maxCostUsd);
        cfg.limits.maxTotalTokens = static_cast<u64>(num(*l, "maxTotalTokens", 0));
        cfg.limits.stuckAfterSeconds = static_cast<int>(num(*l, "stuckAfterSeconds", cfg.limits.stuckAfterSeconds));
        cfg.limits.maxConcurrentRuns = static_cast<int>(num(*l, "maxConcurrentRuns", cfg.limits.maxConcurrentRuns));
        if (cfg.limits.maxConcurrentRuns < 1 || cfg.limits.maxConcurrentRuns > kMaxConcurrentRunsCap) {
            cfg.warnings.push_back(std::string(sourceName) + ": limits.maxConcurrentRuns is " + std::to_string(cfg.limits.maxConcurrentRuns) +
                                   "; the editor runs between 1 and " + std::to_string(kMaxConcurrentRunsCap) +
                                   " chats at once, so " +
                                   std::to_string(std::clamp(cfg.limits.maxConcurrentRuns, 1, kMaxConcurrentRunsCap)) + " is used.");
            cfg.limits.maxConcurrentRuns = std::clamp(cfg.limits.maxConcurrentRuns, 1, kMaxConcurrentRunsCap);
        }
    }
    if (const Json* sv = child(j, "savers")) {
        if (sv->is_object()) {
            auto flag = [&](const char* key, bool& out) {
                if (const Json* v = child(*sv, key); v && v->is_boolean()) out = v->get<bool>();
            };
            flag("loopGuard", cfg.savers.loopGuard);
            flag("learnedToolGroups", cfg.savers.learnedToolGroups);
            flag("projectFacts", cfg.savers.projectFacts);
            cfg.savers.loopGuardJudge = str(*sv, "loopGuardJudge");
            if (!cfg.savers.loopGuardJudge.empty() && !is_known_role(cfg.savers.loopGuardJudge)) {
                const std::vector<std::string> names(std::begin(kAllRoles), std::end(kAllRoles));
                return make_error(std::string(sourceName) + ": /savers/loopGuardJudge: no role named '" + cfg.savers.loopGuardJudge + "'",
                                  fa::did_you_mean(cfg.savers.loopGuardJudge, names));
            }
        }
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
    for (const ToolServer& s : cfg->toolServers) hasKey = hasKey || !s.apiKey.empty();
    struct stat st{};
    if (hasKey && stat(path.c_str(), &st) == 0 && (st.st_mode & (S_IRWXG | S_IRWXO)) != 0) {
        cfg->warnings.push_back(path + " contains an API key but is readable by other users. Run: chmod 600 " + path);
    }
#endif
    return cfg;
}

Json savers_to_json(const Savers& savers) {
    Json out = Json::object();
    const Savers def;
    if (savers.loopGuard != def.loopGuard) out["loopGuard"] = savers.loopGuard;
    if (!savers.loopGuardJudge.empty()) out["loopGuardJudge"] = savers.loopGuardJudge;
    if (savers.learnedToolGroups != def.learnedToolGroups) out["learnedToolGroups"] = savers.learnedToolGroups;
    if (savers.projectFacts != def.projectFacts) out["projectFacts"] = savers.projectFacts;
    return out;
}

Result<void> save_savers(const Savers& savers, std::string_view path) {
    Json j = Json::object();
    std::error_code ec;
    if (fsys::exists(fsys::path(path), ec)) {
        auto text = fs::read_text(path);
        if (!text) return text.error();
        auto parsed = fa::parse_json(*text, path);
        if (!parsed) return parsed.error();
        if (!parsed->is_object()) {
            return make_error("AI config '" + std::string(path) + "' is not a JSON object", "Fix or delete the file, then save the settings again.");
        }
        j = std::move(*parsed);
    }
    if (!savers.loopGuardJudge.empty() && !is_known_role(savers.loopGuardJudge)) {
        const std::vector<std::string> names(std::begin(kAllRoles), std::end(kAllRoles));
        return make_error("No role named '" + savers.loopGuardJudge + "' for the loop guard's judge", fa::did_you_mean(savers.loopGuardJudge, names));
    }
    if (Json sj = savers_to_json(savers); sj.empty()) j.erase("savers");
    else j["savers"] = std::move(sj);
    return write_private_file(path, dump_json(j));
}

// The "assetSources" object ({} when there is nothing to say: no site and onlyListed off).
static Json asset_sources_to_json(const AssetSources& sources) {
    Json out = Json::object();
    for (SiteCategory c : kSiteCategories) {
        if (sources.list(c).empty()) continue;
        Json list = Json::array();
        for (const AssetSite& site : sources.list(c)) {
            Json e = Json::object({{"url", site.url}});
            if (!site.note.empty()) e["note"] = site.note;
            list.push_back(std::move(e));
        }
        out[site_category_key(c)] = std::move(list);
    }
    if (sources.onlyListed) out["onlyListed"] = true;
    return out;
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
        if (!p.license.empty()) pj["license"] = p.license;
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
    if (!cfg.assets.empty()) {
        Json assets = Json::object();
        for (const auto& [kind, r] : cfg.assets) {
            Json rj = Json::object({{"provider", r.provider}});
            if (!r.model.empty()) rj["model"] = r.model;
            if (!r.voice.empty()) rj["voice"] = r.voice;
            assets[kind] = rj;
        }
        out["assets"] = assets;
    }
    if (Json sources = asset_sources_to_json(cfg.assetSources); !sources.empty()) out["assetSources"] = std::move(sources);
    if (!cfg.toolServers.empty()) {
        Json servers = Json::object();
        for (const ToolServer& s : cfg.toolServers) servers[s.name] = tool_server_to_json(s, redactKeys);
        out["mcpServers"] = std::move(servers);
    }
    if (Json ext = extensions_to_json(cfg.extensions, true); !ext.empty()) out["extensions"] = std::move(ext);
    if (!cfg.savers.is_default()) out["savers"] = savers_to_json(cfg.savers);
    Json roles = Json::object();
    for (const auto& [name, r] : cfg.roles) {
        Json rj = Json::object();
        rj["provider"] = r.provider;
        rj["model"] = r.model;
        if (!r.effort.empty()) rj["effort"] = r.effort;
        if (r.maxTokens > 0) rj["maxTokens"] = r.maxTokens;
        if (r.maxContextTokens > 0) rj["maxContextTokens"] = r.maxContextTokens;
        if (!r.enabled) rj["enabled"] = false;
        if (r.toolGroups) rj["toolGroups"] = *r.toolGroups;
        roles[name] = rj;
    }
    out["roles"] = roles;
    out["limits"] = Json::object({{"maxTurns", cfg.limits.maxTurns},
                                  {"maxCostUsd", cfg.limits.maxCostUsd},
                                  {"maxTotalTokens", cfg.limits.maxTotalTokens},
                                  {"stuckAfterSeconds", cfg.limits.stuckAfterSeconds},
                                  {"maxConcurrentRuns", cfg.limits.maxConcurrentRuns}});
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

Result<void> save_roles(const std::map<std::string, RoleConfig>& roles, std::string_view path) {
    Json j = Json::object();
    std::error_code ec;
    if (fsys::exists(fsys::path(path), ec)) {
        auto text = fs::read_text(path);
        if (!text) return text.error();
        auto parsed = fa::parse_json(*text, path);
        if (!parsed) return parsed.error();
        if (!parsed->is_object()) {
            return make_error("AI config '" + std::string(path) + "' is not a JSON object", "Fix or delete the file, then save the roles again.");
        }
        j = std::move(*parsed);
    }
    Json& out = j["roles"];
    if (!out.is_object()) out = Json::object();
    for (const auto& [name, r] : roles) {
        Json& rj = out[name];
        if (!rj.is_object()) rj = Json::object();
        rj["provider"] = r.provider;
        for (const auto& [key, value] : {std::pair<const char*, const std::string&>{"model", r.model}, {"effort", r.effort}}) {
            if (value.empty()) rj.erase(key);
            else rj[key] = value;
        }
        if (r.maxContextTokens > 0) rj["maxContextTokens"] = r.maxContextTokens;
        else rj.erase("maxContextTokens");
        if (r.enabled || name == kRoleOrchestrator) rj.erase("enabled");
        else rj["enabled"] = false;
        if (r.toolGroups) rj["toolGroups"] = *r.toolGroups;  // unset: whatever the file says stays
    }
    return fs::write_text(path, dump_json(j));
}

namespace {

// Writes text where only the owner can read it, from the first byte: a temporary file made private BEFORE the key goes in,
// then renamed over the target (fs::write_text makes its temporary file with the default permissions).
Result<void> write_private(std::string_view path, const std::string& text) {
#ifdef _WIN32
    return fs::write_text(path, text);
#else
    fsys::path target(path);
    std::error_code ec;
    if (target.has_parent_path()) fsys::create_directories(target.parent_path(), ec);
    fsys::path tmp = target;
    tmp += ".fa-tmp" + std::to_string(static_cast<long long>(::getpid()));
    {
        std::ofstream create(tmp, std::ios::binary | std::ios::trunc);
        if (!create) return make_error("Cannot write '" + std::string(path) + "'", "Check the directory exists and is writable.");
    }
    fsys::permissions(tmp, fsys::perms::owner_read | fsys::perms::owner_write, fsys::perm_options::replace, ec);
    {
        std::ofstream out(tmp, std::ios::binary | std::ios::trunc);
        out << text;
        if (!out) {
            out.close();
            fsys::remove(tmp, ec);
            return make_error("Cannot write '" + std::string(path) + "'", "Is the disk full?");
        }
    }
    fsys::rename(tmp, target, ec);
    if (ec) {
        fsys::remove(tmp, ec);
        return make_error("Cannot replace '" + std::string(path) + "'", "Check the file is writable.");
    }
    return {};
#endif
}

}  // namespace

Result<void> write_private_file(std::string_view path, const std::string& text) { return write_private(path, text); }

std::vector<std::string> split_args(std::string_view line) {
    std::vector<std::string> out;
    std::string cur;
    bool inWord = false, quoted = false;
    for (std::size_t i = 0; i < line.size(); ++i) {
        const char c = line[i];
        if (quoted) {
            if (c == '\\' && i + 1 < line.size() && (line[i + 1] == '"' || line[i + 1] == '\\')) cur += line[++i];
            else if (c == '"') quoted = false;
            else cur += c;
        } else if (c == '"') {
            quoted = inWord = true;
        } else if (std::isspace(static_cast<unsigned char>(c))) {
            if (inWord) out.push_back(std::exchange(cur, {}));
            inWord = false;
        } else {
            cur += c;
            inWord = true;
        }
    }
    if (inWord) out.push_back(std::move(cur));
    return out;
}

std::string join_args(const std::vector<std::string>& args) {
    std::string out;
    for (const std::string& a : args) {
        if (!out.empty()) out += ' ';
        const bool plain = !a.empty() && a.find_first_of(" \t\"\\") == std::string::npos;
        if (plain) {
            out += a;
            continue;
        }
        out += '"';
        for (char c : a) {
            if (c == '"' || c == '\\') out += '\\';
            out += c;
        }
        out += '"';
    }
    return out;
}

Result<void> save_asset_settings(const AssetSettings& settings, std::string_view path) {
    Json j = Json::object();
    std::error_code ec;
    if (fsys::exists(fsys::path(path), ec)) {
        auto text = fs::read_text(path);
        if (!text) return text.error();
        auto parsed = fa::parse_json(*text, path);
        if (!parsed) return parsed.error();
        if (!parsed->is_object()) {
            return make_error("AI config '" + std::string(path) + "' is not a JSON object",
                              "Fix or delete the file, then save the asset settings again.");
        }
        j = std::move(*parsed);
    }
    // "assets": exactly the routes given.
    if (settings.routes.empty()) {
        j.erase("assets");
    } else {
        Json assets = Json::object();
        for (MediaKind k : kMediaKinds) {
            const auto it = settings.routes.find(media_kind_name(k));
            if (it == settings.routes.end() || it->second.provider.empty()) continue;
            Json rj = Json::object({{"provider", it->second.provider}});
            if (!it->second.model.empty()) rj["model"] = it->second.model;
            if (!it->second.voice.empty()) rj["voice"] = it->second.voice;
            assets[media_kind_name(k)] = std::move(rj);
        }
        if (assets.empty()) j.erase("assets");
        else j["assets"] = std::move(assets);
    }
    if (Json sources = asset_sources_to_json(settings.sources); sources.empty()) j.erase("assetSources");
    else j["assetSources"] = std::move(sources);
    // The providers the routes use: only the fields the caller names.
    for (const auto& [name, edit] : settings.providers) {
        if (!j.contains("providers") || !j["providers"].is_object()) j["providers"] = Json::object();
        Json& provs = j["providers"];
        Json& pj = provs[name];
        if (!pj.is_object()) pj = Json::object();
        if (!edit.type.empty() && !pj.contains("type")) pj["type"] = edit.type;
        if (edit.apiKey) {
            if (edit.apiKey->empty()) pj.erase("apiKey");
            else pj["apiKey"] = *edit.apiKey;
        }
        if (edit.command) {
            if (edit.command->empty()) pj.erase("command");
            else pj["command"] = *edit.command;
        }
        if (edit.argv) {
            if (edit.argv->empty()) pj.erase("argv");
            else pj["argv"] = *edit.argv;
        }
        if (pj.empty()) provs.erase(name);
        if (provs.empty()) j.erase("providers");
    }
    return write_private(path, dump_json(j));
}

Result<void> save_tool_servers(const std::vector<ToolServer>& servers, std::string_view path) {
    Json j = Json::object();
    std::error_code ec;
    if (fsys::exists(fsys::path(path), ec)) {
        auto text = fs::read_text(path);
        if (!text) return text.error();
        auto parsed = fa::parse_json(*text, path);
        if (!parsed) return parsed.error();
        if (!parsed->is_object()) {
            return make_error("AI config '" + std::string(path) + "' is not a JSON object",
                              "Fix or delete the file, then save the tool servers again.");
        }
        j = std::move(*parsed);
    }
    if (servers.empty()) {
        j.erase("mcpServers");
    } else {
        Json out = Json::object();
        for (const ToolServer& s : servers) {
            if (auto problem = tool_server_name_problem(s.name); !problem.empty())
                return make_error("Cannot save the tool server '" + s.name + "': " + problem,
                                  "Use a short name such as scenario (letters, digits, _ and -).");
            if (out.contains(s.name))
                return make_error("Two tool servers are called '" + s.name + "'", "Give each server its own name.");
            out[s.name] = tool_server_to_json(s, false);
        }
        j["mcpServers"] = std::move(out);
    }
    return write_private(path, dump_json(j));
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
