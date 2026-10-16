#include <algorithm>

#include "asset_providers.h"
#include "fa/core/strings.h"
#include "provider_util.h"
#include "util.h"

namespace fa::ai {

using namespace util;

namespace {

constexpr int kAssetRetries = 2;

// The ai.json entry that makes a kind work, for the "not configured" error.
std::string example_route(MediaKind kind) {
    switch (kind) {
        case MediaKind::Image: return R"({"provider": "openai", "model": "gpt-image-1"})";
        case MediaKind::Voice: return R"({"provider": "elevenlabs", "voice": "<voice id>"})";
        case MediaKind::Model3d: return R"({"provider": "meshy"})";
        default: return R"({"provider": "elevenlabs"})";
    }
}

}  // namespace

Result<AssetTarget> resolve_asset_target(const AiConfig& cfg, MediaKind kind, const std::string& providerOverride,
                                         const std::string& modelOverride, const std::string& voiceOverride) {
    const std::string name = media_kind_name(kind);
    AssetRoute route;
    if (auto it = cfg.assets.find(name); it != cfg.assets.end()) route = it->second;
    if (!providerOverride.empty() && providerOverride != route.provider) route = {providerOverride, "", ""};  // its own model
    if (route.provider.empty()) {
        const std::string where = cfg.sourcePath.empty() ? default_config_path() : cfg.sourcePath;
        return make_error("No provider is configured for " + name + " generation",
                          "Generation costs money, so there is no default. Add this to " + where + ": {\"assets\": {\"" + name +
                              "\": " + example_route(kind) + "}}. To try the pipeline offline and for free, use the fake provider: "
                              "{\"assets\": {\"" + name + "\": {\"provider\": \"fake\"}}}. Or pass `provider` to the command.");
    }
    const ProviderConfig* p = cfg.provider(route.provider);
    if (!p) {
        std::vector<std::string> names;
        for (const auto& [n, _] : cfg.providers) names.push_back(n);
        return make_error("Unknown asset provider '" + route.provider + "' for " + name + " generation", fa::did_you_mean(route.provider, names));
    }
    if (!provider_makes(p->kind, kind)) {
        return make_error("Provider '" + route.provider + "' (" + provider_kind_name(p->kind) + ") cannot generate " + name,
                          "Providers that can: " + providers_that_make(cfg, kind) + ".");
    }
    if (!modelOverride.empty()) route.model = modelOverride;
    if (!voiceOverride.empty()) route.voice = voiceOverride;
    return AssetTarget{p, route.model, route.voice};
}

Result<AssetResult> generate_asset(const ProviderConfig& provider, const AssetRequest& request, const ProviderRuntime& rt,
                                   const CancelFlag* cancel) {
    if (!provider_makes(provider.kind, request.kind)) {
        return make_error("Provider '" + provider.name + "' (" + provider_kind_name(provider.kind) + ") cannot generate " +
                          media_kind_name(request.kind));
    }
    switch (provider.kind) {
        case ProviderKind::OpenAICompatible: return openai_asset(provider, request, rt, cancel);
        case ProviderKind::ElevenLabs: return elevenlabs_asset(provider, request, rt, cancel);
        case ProviderKind::Meshy: return meshy_asset(provider, request, rt, cancel);
        case ProviderKind::Fake: return fake_asset(request);
        case ProviderKind::AssetCommand: return command_asset(provider, request, cancel);
        default: return make_error("Provider '" + provider.name + "' does not generate assets");
    }
}

std::string asset_extension(const ProviderConfig& provider, MediaKind kind) {
    if (kind == MediaKind::Image) return ".png";
    switch (provider.kind) {
        case ProviderKind::OpenAICompatible:
        case ProviderKind::ElevenLabs: return ".mp3";
        case ProviderKind::Meshy:
        case ProviderKind::AssetCommand: return kind == MediaKind::Model3d ? ".glb" : ".wav";
        case ProviderKind::Fake: return kind == MediaKind::Model3d ? ".gltf" : ".wav";
        default: return {};
    }
}

std::string sniff_extension(std::string_view b) {
    auto has = [&](std::size_t at, std::string_view magic) { return b.size() >= at + magic.size() && b.substr(at, magic.size()) == magic; };
    auto starts = [&](std::string_view magic) { return has(0, magic); };
    if (starts("\x89PNG")) return ".png";
    if (starts("\xFF\xD8\xFF")) return ".jpg";
    if (starts("RIFF") && has(8, "WAVE")) return ".wav";
    if (starts("RIFF") && has(8, "WEBP")) return ".webp";
    if (starts("ID3") || (b.size() > 1 && static_cast<unsigned char>(b[0]) == 0xFF && (static_cast<unsigned char>(b[1]) & 0xE0) == 0xE0)) return ".mp3";
    if (starts("OggS")) return ".ogg";
    if (starts("glTF")) return ".glb";
    if (!b.empty() && b[0] == '{') return ".gltf";
    return {};
}

std::string asset_license(const ProviderConfig& p) {
    if (!p.license.empty()) return p.license;
    switch (p.kind) {
        case ProviderKind::ElevenLabs: return "Output of ElevenLabs. Commercial use depends on your plan: https://elevenlabs.io/terms-of-use";
        case ProviderKind::Meshy: return "Output of Meshy. Commercial use depends on your plan: https://www.meshy.ai/terms";
        case ProviderKind::Fake: return "Procedurally generated placeholder (no third-party rights). Replace it before release.";
        case ProviderKind::AssetCommand:
            return "Output of the local program '" + p.command + "'. Check the license of the program and of the model it ran.";
        default:
            return p.preset == "openai" ? "Output of the OpenAI API. Rights are set by OpenAI's terms: https://openai.com/policies/terms-of-use"
                                        : "Output of provider '" + p.name + "'. Check its terms of use before you release the game.";
    }
}

// ---------------------------------------------------------------------------
// Shared by the HTTP providers

Result<std::string> asset_api_key(const ProviderConfig& cfg, const ProviderRuntime& rt) {
    ResolvedKey key = resolve_api_key(cfg, rt.env);
    if (key.found()) return key.key;
    const std::string env = default_key_env(cfg);
    if (env.empty()) return std::string();
    return make_error("No API key for provider '" + cfg.name + "'",
                      "Set the " + env + " environment variable, or \"apiKeyEnv\"/\"apiKey\" for this provider in ~/.factoria/ai.json. "
                      "Keys never go in the game project.");
}

Result<HttpResponse> asset_request(const ProviderConfig& cfg, HttpRequest request, const ProviderRuntime& rt, const CancelFlag* cancel) {
    request.timeoutSeconds = cfg.timeoutSeconds;
    HttpResponse resp = send_with_retry(rt, std::move(request), std::min(cfg.maxRetries, kAssetRetries), cancel);
    if (resp.cancelled) return make_error("Cancelled");
    if (!resp.ok()) return make_error(describe_http_error(cfg.name, resp), http_error_hint(cfg.name, resp.status));
    return resp;
}

}  // namespace fa::ai
