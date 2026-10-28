// User-level AI configuration (~/.factoria/ai.json) and key resolution.
//
// Keys come ONLY from environment variables or this user file (never from a
// game project). See docs/AI_PROVIDERS.md and schemas/ai-config.schema.json.
#pragma once

#include <functional>
#include <map>
#include <string>
#include <string_view>
#include <vector>

#include "fa/ai/types.h"
#include "fa/core/json_schema.h"

namespace fa::ai {

// The last four only generate assets (images, sounds, 3D models; docs/AI_PROVIDERS.md, "Asset providers"): roles cannot use them.
enum class ProviderKind { Anthropic, OpenAICompatible, ClaudeCode, Codex, GenericCli, ElevenLabs, Meshy, Fake, AssetCommand };
const char* provider_kind_name(ProviderKind k);  // "anthropic", "openai-compatible", "claude-code", ...
bool is_cli_kind(ProviderKind k);
bool is_asset_only_kind(ProviderKind k);  // elevenlabs, meshy, fake, asset-command

// What an asset provider makes; the names are the keys of "assets" in ai.json.
enum class MediaKind { Image, Sound, Music, Voice, Model3d };
inline constexpr MediaKind kMediaKinds[] = {MediaKind::Image, MediaKind::Sound, MediaKind::Music, MediaKind::Voice,
                                            MediaKind::Model3d};
const char* media_kind_name(MediaKind k);  // "image", "sound", "music", "voice", "model3d"
// openai-compatible: image, voice. elevenlabs: sound, music, voice. meshy: model3d. fake and asset-command: all.
bool provider_makes(ProviderKind k, MediaKind m);

struct ProviderConfig {
    std::string name;
    ProviderKind kind = ProviderKind::OpenAICompatible;
    std::string preset;       // openai|openrouter|gemini|groq|deepseek|ollama|lmstudio or ""
    std::string baseUrl;
    std::string apiKeyEnv;    // explicit env var name
    std::string apiKey;       // from the user config file only
    std::vector<std::pair<std::string, std::string>> headers;
    std::string defaultModel;
    bool useAntCli = true;
    bool sendReasoningEffort = false;
    // CLI agents
    std::string command;                  // "claude", "codex" or user command
    std::vector<std::string> argv;        // template; empty = built-in default for the kind
    std::map<std::string, std::string> env;
    std::vector<std::string> unsetEnv;
    std::string factoriaCommand = "factoria";
    Pricing pricing;                      // known=false unless configured
    std::string license;                  // asset providers: the license note recorded for what they generate ("" = a built-in note)
    int maxRetries = 5;
    double timeoutSeconds = 600;
};

// Which provider (and model, voice) generates one kind of asset: an entry of "assets" in ai.json. There is no default:
// generation costs money, so a missing kind is an error that shows what to add.
struct AssetRoute {
    std::string provider;
    std::string model;  // "" = the provider's default for the kind
    std::string voice;  // voice: the provider's voice name or id
};

struct RoleConfig {
    std::string provider;
    std::string model;
    std::string effort;
    int maxTokens = 0;
    // Most context a session keeps (tokens; 0 = the model's whole window). Past it the earlier turns are summarized:
    // Claude Code compacts (CLAUDE_CODE_AUTO_COMPACT_WINDOW), the Anthropic API compacts on the server.
    u64 maxContextTokens = 0;
};

struct Limits {
    int maxTurns = 40;
    double maxCostUsd = 0;      // 0 = unlimited
    u64 maxTotalTokens = 0;     // 0 = unlimited
    // The editor warns "may be stuck" when a running agent (the orchestrator or a sub-agent) has produced no event for this
    // many seconds (it offers Stop and "Check activity"). 0 = never warn. Only the editor reads it.
    int stuckAfterSeconds = 180;
    // How many AI chats the editor lets run at the same time (each chat has its own agent, status and Stop). Values outside
    // 1..kMaxConcurrentRunsCap are brought into that range with a warning. Only the editor reads it.
    int maxConcurrentRuns = 3;
};
inline constexpr int kMaxConcurrentRunsCap = 8;

inline constexpr const char* kRoleOrchestrator = "orchestrator";
inline constexpr const char* kRoleWorker = "worker";
inline constexpr const char* kRoleFast = "fast";

struct AiConfig {
    std::string defaultProvider = "anthropic";
    std::map<std::string, ProviderConfig> providers;
    std::map<std::string, RoleConfig> roles;  // always has the three roles after load
    std::map<std::string, AssetRoute> assets; // by media_kind_name; empty unless the file sets "assets"
    Limits limits;
    std::string sourcePath;                   // "" when defaults only
    std::vector<std::string> warnings;

    const ProviderConfig* provider(std::string_view name) const;
    // Role with defaults filled in. Unknown role names return the worker role.
    RoleConfig role(std::string_view name) const;
};

std::string providers_that_make(const AiConfig& cfg, MediaKind m);  // the names of the providers that make `m`: "a, b"

using EnvLookup = std::function<std::string(const std::string& name)>;  // "" when unset
EnvLookup system_env();

// Linux/macOS: ~/.factoria/ai.json ; Windows: %APPDATA%/factoria/ai.json ;
// FACTORIA_AI_CONFIG overrides.
std::string default_config_path(const EnvLookup& env = system_env());

// Built-in providers and the default Anthropic role mapping.
AiConfig default_config();
// Default roles for a provider (Anthropic: opus/sonnet/haiku with xhigh/medium/max).
std::map<std::string, RoleConfig> default_roles_for(const AiConfig& cfg);

std::string_view config_schema_text();                           // schemas/ai-config.schema.json
std::vector<SchemaError> validate_config_json(const Json& j);    // [] when valid

Result<AiConfig> parse_config(const Json& j, std::string_view sourceName = "<memory>");
// Missing file => defaults (ok). Present but invalid => error with JSON pointers.
Result<AiConfig> load_config(std::string_view path = {}, const EnvLookup& env = system_env());
Result<void> save_config(const AiConfig& cfg, std::string_view path);  // writes user-editable JSON (no defaults noise)
// Writes only "roles" into the config file at `path` (created when missing) and keeps everything else in it: providers,
// limits, a role's maxTokens. An empty model or effort (or maxContextTokens 0) removes that key, so the role's default
// applies. A file that is not a JSON object is left alone (error).
Result<void> save_roles(const std::map<std::string, RoleConfig>& roles, std::string_view path);
Json config_to_json(const AiConfig& cfg, bool redactKeys = true);

struct ResolvedKey {
    std::string key;
    std::string source;  // "env:ANTHROPIC_API_KEY", "config", or "" when none
    bool found() const { return !key.empty(); }
};
// Order: apiKeyEnv -> apiKey (user config) -> the provider's conventional env var.
ResolvedKey resolve_api_key(const ProviderConfig& p, const EnvLookup& env = system_env());
// Conventional env var for a provider/preset ("ANTHROPIC_API_KEY", "OPENAI_API_KEY"...).
std::string default_key_env(const ProviderConfig& p);

// Built-in default argv templates (everything after the command).
std::vector<std::string> default_cli_argv(ProviderKind kind);
std::string default_cli_command(ProviderKind kind);  // "claude", "codex", ""

// Warn about key-looking strings in a game project (text files only, skips .git,
// build dirs and .factoria). Returns "path:line: looks like an API key (sk-ant-...)" lines.
std::vector<std::string> scan_project_for_keys(const std::string& projectDir, std::size_t maxFiles = 2000);
// Does this text contain something that looks like an API key?
bool looks_like_api_key(std::string_view text);

}  // namespace fa::ai
