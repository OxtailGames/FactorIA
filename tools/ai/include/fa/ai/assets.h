// Asset providers: generate images, sounds, music, voice and 3D models (docs/AI_PROVIDERS.md, "Asset providers").
//
// Which provider makes which kind of asset is the "assets" section of ai.json (AiConfig::assets). The assets.generate_*
// commands (asset_commands.cpp) resolve it, call generate_asset() and write the file and its provenance into the project.
#pragma once

#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/ai/config.h"
#include "fa/ai/provider.h"

namespace fa::ai {

struct ReferenceImage {
    std::string name;       // file name ("hero.png")
    std::string mediaType;  // "image/png"
    std::string bytes;
};

struct AssetRequest {
    MediaKind kind = MediaKind::Image;
    std::string prompt;                       // what to make; for voice, the text to speak
    std::string model;                        // "" = the provider's default for the kind
    std::string voice;                        // voice: the voice to speak with
    int width = 0, height = 0;                // image: the size the caller ends up with (providers draw at their own sizes)
    int columns = 0, rows = 0;                // image: > 0 asks for a sprite sheet of this grid
    bool transparent = false;                 // image: transparent background
    double seconds = 0;                       // sound, music: length; 0 = the provider's choice
    std::optional<i64> seed;
    std::vector<ReferenceImage> references;   // image: pictures the result should follow
};

struct AssetResult {
    std::string bytes;                // the file as the provider made it (PNG, MP3, WAV, GLB...)
    std::string model;                // the model that made it; "" when the provider has none
    std::string voice;                // voice: the voice that spoke, when the provider chose or took one
    bool usedReferences = false;      // false: the provider has no way to take reference images
    std::optional<i64> seed;          // the seed the provider used, when it took one
};

// What assets.<kind> (or `providerOverride`) resolves to. Errors say what to add to ai.json; there is no default provider.
struct AssetTarget {
    const ProviderConfig* provider = nullptr;
    std::string model;  // "" = the provider's default for the kind
    std::string voice;
};
// When nothing is configured for `kind`, the error's hint carries asset_provider_report(cfg, kind, env).
Result<AssetTarget> resolve_asset_target(const AiConfig& cfg, MediaKind kind, const std::string& providerOverride = {},
                                         const std::string& modelOverride = {}, const std::string& voiceOverride = {},
                                         const EnvLookup& env = system_env());

// A plain-text answer to "why can I not make a `kind` asset, and what would let me": the providers that can make it (with
// whether their key is set in `env`), the ones that cannot and why, the keys that would enable a real provider, and the
// offline tools that need no provider (assets.generate_texture and assets.rasterize_svg for images). The names it prints
// are the providers of `cfg`, built-in ones included.
std::string asset_provider_report(const AiConfig& cfg, MediaKind kind, const EnvLookup& env = system_env());

// Makes one asset. HTTP and process failures are Errors that say what to check. rt.transport, rt.env and rt.sleep are the
// seams tests use.
Result<AssetResult> generate_asset(const ProviderConfig& provider, const AssetRequest& request, const ProviderRuntime& rt = {},
                                   const CancelFlag* cancel = nullptr);

// The extension of the file `provider` returns for `kind` (".png", ".mp3", ".wav", ".glb"), so a wrong path is refused
// before anything is paid for.
std::string asset_extension(const ProviderConfig& provider, MediaKind kind);
// The extension the first bytes of a file say it has (".png", ".jpg", ".wav", ".mp3", ".ogg", ".glb", ".gltf"); "" if unknown.
std::string sniff_extension(std::string_view bytes);
// The license note recorded for what `provider` generates: ProviderConfig::license, else where its terms are.
std::string asset_license(const ProviderConfig& provider);

}  // namespace fa::ai
