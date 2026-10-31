// User-level AI configuration (~/.factoria/ai.json) and key resolution.
//
// Keys come ONLY from environment variables or this user file (never from a
// game project). See docs/AI_PROVIDERS.md and schemas/ai-config.schema.json.
#pragma once

#include <functional>
#include <map>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/ai/extensions.h"
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

// Websites the AI should look at when it searches for assets (the "assetSources" section of ai.json; the editor's AI settings
// window edits it). Empty lists mean "no preference": the AI searches the internet as it wishes.
struct AssetSite {
    std::string url;   // a web address or just a domain: "https://opengameart.org", "kenney.nl", "github.com/KhronosGroup"
    std::string note;  // optional: what the site is good for, or its license ("CC0 packs")
};
enum class SiteCategory { Images, Models, Audio, Fonts, Other };
inline constexpr SiteCategory kSiteCategories[] = {SiteCategory::Images, SiteCategory::Models, SiteCategory::Audio,
                                                   SiteCategory::Fonts, SiteCategory::Other};
const char* site_category_key(SiteCategory c);    // "images", "models", "audio", "fonts", "other": the keys of "assetSources"
const char* site_category_title(SiteCategory c);  // "Images and textures", "3D models", "Audio (sounds and music)", "Fonts", "Other"

struct AssetSources {
    std::vector<AssetSite> images, models, audio, fonts, other;
    // false: the AI looks at these sites first and may also search the internet. true: ONLY these sites.
    bool onlyListed = false;
    std::vector<AssetSite>& list(SiteCategory c);
    const std::vector<AssetSite>& list(SiteCategory c) const;
    bool empty() const;  // no site in any category (onlyListed alone does nothing)
};
// "https://OpenGameArt.org/content/x?a=1" -> "opengameart.org". Accepts a web address or a bare domain (with or without a path,
// a port, a "www."); "" when the text is not a usable address (spaces, no dot and not localhost, empty labels).
std::string asset_site_host(std::string_view urlOrDomain);
// The distinct hosts of every site, in the order they are listed.
std::vector<std::string> asset_source_hosts(const AssetSources& sources);

struct RoleConfig {
    std::string provider;
    std::string model;
    std::string effort;
    int maxTokens = 0;
    // Most context a session keeps (tokens; 0 = the model's whole window). Past it the earlier turns are summarized:
    // Claude Code compacts (CLAUDE_CODE_AUTO_COMPACT_WINDOW), the Anthropic API compacts on the server.
    u64 maxContextTokens = 0;
    // false = the user turned the role off (the Roles window's "Enabled" checkbox): the orchestrator does that work itself.
    // Always true for the orchestrator. For artCritic and reviewer, off means a review runs on the orchestrator's
    // provider, model and effort (AiConfig::effective_role).
    bool enabled = true;
    // Tool groups (command categories such as "assets", "anim", "ui", or exact command names) the built-in agent always gets
    // with their full definition, on top of its core commands; every other command is a line of the catalog it can describe
    // and call (tool_catalog.h). "all" = every command in full. Unset = default_tool_groups(role); {} = none. API providers only.
    std::optional<std::vector<std::string>> toolGroups;
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
inline constexpr const char* kRoleArtist = "artist";        // makes the game's art (images, textures, sprites, models, look)
inline constexpr const char* kRoleAudio = "audio";          // makes the game's audio (sound effects, music, voice, mixing)
inline constexpr const char* kRoleArtCritic = "artCritic";  // looks at the game and criticizes its art; read-only
inline constexpr const char* kRoleReviewer = "reviewer";    // plays the game like a press reviewer and scores it; read-only

// Every role, in the order UIs list them.
inline constexpr const char* kAllRoles[] = {kRoleOrchestrator, kRoleWorker, kRoleFast,      kRoleArtist,
                                            kRoleAudio,        kRoleArtCritic, kRoleReviewer};
inline constexpr const char* kExtraRoles[] = {kRoleArtist, kRoleAudio, kRoleArtCritic, kRoleReviewer};  // not in old ai.json files
bool is_known_role(std::string_view role);
// artCritic and reviewer: they look and play and give an opinion, they never change the project (SessionOptions::role
// enforces it: only read-only tools, no file edits).
bool is_review_role(std::string_view role);
// The roles the orchestrator may hand a task to (ai_run / agent_delegate): worker, fast, artist, audio. The critics and
// the reviewers run only when the USER asks (the editor's review buttons, `factoria ai review`, ai.review).
bool is_delegable_role(std::string_view role);
// One line: what the role does (Roles window, docs).
const char* role_summary(std::string_view role);
// What the user reads instead of the ai.json key: "Orchestrator", "Worker", "Fast", "Artist", "Audio", "Art critic",
// "Reviewer". An unknown name comes back unchanged.
const char* role_display_name(std::string_view role);
// The Roles window groups the roles: 0 = orchestrator, worker, fast; 1 = artist, audio; 2 = art critic, reviewer.
inline constexpr int kRoleGroupCount = 3;
int role_group(std::string_view role);  // -1 for an unknown role
const char* role_group_title(int group);  // "Orchestration and code", "Art and audio", "Critics and reviewers"
// The teaching error for a role that is off (message: what is off and what happens instead; hint: where to turn it on).
std::string role_off_message(std::string_view role);
std::string role_off_hint(std::string_view role);

using EnvLookup = std::function<std::string(const std::string& name)>;  // "" when unset

// An external tool server (MCP) the user configured in ai.json ("mcpServers"; docs/AI_PROVIDERS.md, "External tools (MCP
// servers)"): a service such as Scenario (AI game art) or a local program whose tools the AI may call when it helps. The shape
// follows Claude Code's .mcp.json (type, url, headers, command, args, env) plus FactorIA's own fields. Only the USER file has
// them: a game project can never add a server (it would run a program or send data to a host the user did not choose).
struct ToolServer {
    std::string name;                                          // [A-Za-z0-9_-], not "factoria": the key under "mcpServers"
    std::string type;                                          // "http" (Streamable HTTP) or "stdio" (a local program)
    std::string url;                                           // http
    std::vector<std::pair<std::string, std::string>> headers;  // http; values may use {key} and ${ENV}
    std::string command;                                       // stdio
    std::vector<std::string> args;                             // stdio; may use {key} and ${ENV}
    std::map<std::string, std::string> env;                    // stdio; values may use {key} and ${ENV}
    std::string apiKeyEnv;                                     // name of the env var that holds the key ({key})
    std::string apiKey;                                        // the key itself (user file only; an env var is better)
    std::string note;                                          // goes to the AI's prompt: what the server is good for
    std::vector<std::string> roles;                            // who may use it; empty = kDefaultToolServerRoles
    bool enabled = true;
    double timeoutSeconds = 120;                               // one tools/call (generating an image takes a while)

    bool is_stdio() const { return type == "stdio"; }
    // Whether `role` gets this server's tools: it is enabled and the role is in `roles` (in the defaults when `roles` is
    // empty). The review roles (artCritic, reviewer) get a server only when `roles` lists them.
    bool serves_role(std::string_view role) const;
};
inline constexpr const char* kToolServerFactoria = "factoria";  // reserved: the engine's own tool server
inline constexpr std::size_t kMaxToolServerName = 40;
// Who gets a server that lists no roles: the roles that build the game, not the ones that judge it.
inline constexpr const char* kDefaultToolServerRoles[] = {kRoleOrchestrator, kRoleWorker, kRoleFast, kRoleArtist, kRoleAudio};
// "" when `name` is a usable server name, else what is wrong with it (empty, characters outside [A-Za-z0-9_-], "factoria",
// longer than kMaxToolServerName characters).
std::string tool_server_name_problem(std::string_view name);

// A server with its {key} and ${ENV} references filled in, ready to connect or to hand to a CLI agent. Never logged or
// printed: it holds the key.
struct ResolvedToolServer {
    std::string name;
    std::string type;
    std::string url;
    std::vector<std::pair<std::string, std::string>> headers;
    std::string command;
    std::vector<std::string> args;
    std::map<std::string, std::string> env;
    double timeoutSeconds = 120;
    std::string keySource;  // "env:SCENARIO_API_KEY", "config" or "" (the server does not use {key}, or has none)
    bool usesKey = false;   // some header/arg/env value contains {key}
    bool is_stdio() const { return type == "stdio"; }
};
// Fills in {key} (the env var named by apiKeyEnv, else apiKey) and ${NAME} / ${NAME:-default} (environment variables) in
// header values, args and env values. Error (what is missing and where to put it) when a reference has nothing to fill it in.
Result<ResolvedToolServer> resolve_tool_server(const ToolServer& server, const EnvLookup& env);
// Parses one server (the value under its name in "mcpServers"). `at` is the JSON pointer used in errors
// ("/mcpServers/scenario"). With `ignored` set, keys this version does not know are listed there and skipped instead of an
// error (pasted .mcp.json entries often have a few).
Result<ToolServer> parse_tool_server(const Json& entry, std::string name, std::string_view at,
                                     std::vector<std::string>* ignored = nullptr);
// Parses the whole "mcpServers" object, or Claude Code's {"mcpServers": {...}} wrapper around it.
Result<std::vector<ToolServer>> parse_tool_servers(const Json& object, std::string_view at,
                                                   std::vector<std::string>* ignored = nullptr);
// One server as ai.json writes it; the key is replaced by "***" when redactKeys.
Json tool_server_to_json(const ToolServer& server, bool redactKeys);
// Writes ONLY "mcpServers" into the config file at `path` (created when missing) and keeps everything else in it, the way
// save_asset_settings does. An empty list removes the section. On Linux and macOS the file is written with owner-only
// permissions. A file that is not a JSON object is left alone (error).
Result<void> save_tool_servers(const std::vector<ToolServer>& servers, std::string_view path);
// Writes text where only the owner can read it, from the first byte (a temporary file made private before the text goes in,
// then renamed over `path`). Windows: a plain write (the profile folder is already private to the user).
Result<void> write_private_file(std::string_view path, const std::string& text);

struct AiConfig {
    std::string defaultProvider = "anthropic";
    std::map<std::string, ProviderConfig> providers;
    std::map<std::string, RoleConfig> roles;  // always has the seven roles after load
    std::map<std::string, AssetRoute> assets; // by media_kind_name; empty unless the file sets "assets"
    AssetSources assetSources;                // the sites to look at for assets; empty unless the file sets "assetSources"
    std::vector<ToolServer> toolServers;      // the external tool servers (MCP), in the file's order; empty unless the file sets "mcpServers"
    ExtensionsConfig extensions;              // plugins, skills and hooks the CLI agents load; empty unless the file sets "extensions"
    Limits limits;
    std::string sourcePath;                   // "" when defaults only
    std::vector<std::string> warnings;

    const ProviderConfig* provider(std::string_view name) const;
    // Role with defaults filled in. Unknown role names return the worker role.
    RoleConfig role(std::string_view name) const;
    // False only for a known role the user turned off. The orchestrator and unknown names are always "enabled".
    bool role_enabled(std::string_view name) const;
    // The role a run really uses: role(name), except that a review role (artCritic, reviewer) that is off runs on the
    // orchestrator's provider, model, effort and limits (it keeps its read-only prompt and tools).
    RoleConfig effective_role(std::string_view name) const;
    // The enabled tool servers `role` may use, in the file's order. Review roles get only the servers that list them.
    std::vector<const ToolServer*> tool_servers_for(std::string_view role) const;
    // The enabled extensions of the user file that `role` loads, in the file's order (plugins, skills, hooks). The project's
    // own are added by plan_extensions (extension_plan.h).
    std::vector<const Extension*> extensions_for(std::string_view role) const;
    // The delegable roles (worker, fast, artist, audio) that are off, in kAllRoles order.
    std::vector<std::string> disabled_delegable_roles() const;
    // True when at least one delegable role is on, so the orchestrator has someone to hand work to.
    bool can_delegate_to_anyone() const;
};

std::string providers_that_make(const AiConfig& cfg, MediaKind m);  // the names of the providers that make `m`: "a, b"

EnvLookup system_env();

// Linux/macOS: ~/.factoria/ai.json ; Windows: %APPDATA%/factoria/ai.json ;
// FACTORIA_AI_CONFIG overrides.
std::string default_config_path(const EnvLookup& env = system_env());

// Built-in providers and the default Anthropic role mapping.
AiConfig default_config();
// Default roles for a provider (Anthropic: opus/sonnet/haiku with xhigh/medium/max). The four newer roles (artist, audio,
// artCritic, reviewer) follow the provider the three older ones use (an ai.json that sets only those keeps working, on the
// same provider): artist, artCritic and reviewer copy the orchestrator's provider and model with effort "high", audio the
// worker's with effort "medium". Anthropic and Claude Code take the effort from the role; other providers keep the base's.
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

// What the editor's AI settings window changes in the file: the asset routes, the asset sites and a few fields of the providers
// those routes use. A field left out (nullopt) stays as it is in the file.
struct AssetProviderEdit {
    std::optional<std::string> apiKey;                 // "" removes the key from the file; set: written (the file is made private)
    std::optional<std::string> command;                // asset-command: the program
    std::optional<std::vector<std::string>> argv;      // asset-command: its arguments ({prompt} {output}...)
    std::string type;                                  // for a provider the file does not have yet ("asset-command")
};
struct AssetSettings {
    std::map<std::string, AssetRoute> routes;          // the whole "assets" section: a kind that is not here is removed
    AssetSources sources;                              // the whole "assetSources" section
    std::map<std::string, AssetProviderEdit> providers;
};
// Writes "assets" and "assetSources" (and the listed fields of providers) into the config file at `path` (created when missing)
// and keeps everything else in it, the way save_roles does. A provider entry that ends up empty is removed. On Linux and macOS
// the file is written with owner-only permissions (it may hold keys). A file that is not a JSON object is left alone (error).
Result<void> save_asset_settings(const AssetSettings& settings, std::string_view path);
// The arguments of an asset-command provider as one line of text and back (the editor's field): words are separated by spaces,
// a word with spaces is in double quotes ("my file.png"), \" is a quote inside them. split_args(join_args(v)) == v.
std::vector<std::string> split_args(std::string_view line);
std::string join_args(const std::vector<std::string>& args);
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
