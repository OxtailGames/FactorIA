// Sound effects, music and voice from ElevenLabs. Every request carries the key in the xi-api-key header and answers with
// the audio file (MP3 here).
//   sound effects: POST /v1/sound-generation  https://elevenlabs.io/docs/api-reference/text-to-sound-effects/convert
//   music:         POST /v1/music             https://elevenlabs.io/docs/api-reference/music/compose
//   voice:         POST /v1/text-to-speech/{voice_id}  https://elevenlabs.io/docs/api-reference/text-to-speech/convert
#include <cmath>
#include <format>

#include "asset_providers.h"
#include "util.h"

namespace fa::ai {

using namespace util;

namespace {

constexpr const char* kFormat = "?output_format=mp3_44100_128";  // available on every plan

}  // namespace

Result<AssetResult> elevenlabs_asset(const ProviderConfig& cfg, const AssetRequest& req, const ProviderRuntime& rt, const CancelFlag* cancel) {
    auto key = asset_api_key(cfg, rt);
    if (!key) return key.error();

    std::string model = req.model;
    std::string path;
    Json body = Json::object();
    switch (req.kind) {
        case MediaKind::Sound:
            if (req.seconds != 0 && (req.seconds < 0.5 || req.seconds > 30)) {
                return make_error("ElevenLabs sound effects last 0.5 to 30 seconds, not " + std::format("{}", req.seconds),
                                  "Pass `seconds` between 0.5 and 30, or leave it out to let the model choose.");
            }
            if (model.empty()) model = "eleven_text_to_sound_v2";
            path = "/v1/sound-generation";
            body = Json::object({{"text", req.prompt}, {"model_id", model}});
            if (req.seconds > 0) body["duration_seconds"] = req.seconds;
            break;
        case MediaKind::Music:
            if (req.seconds != 0 && (req.seconds < 3 || req.seconds > 600)) {
                return make_error("ElevenLabs music lasts 3 to 600 seconds, not " + std::format("{}", req.seconds),
                                  "Pass `seconds` between 3 and 600, or leave it out to let the model choose.");
            }
            if (model.empty()) model = "music_v1";
            path = "/v1/music";
            // Game music is instrumental: vocals would fight the voice lines.
            body = Json::object({{"prompt", req.prompt}, {"model_id", model}, {"force_instrumental", true}});
            if (req.seconds > 0) body["music_length_ms"] = static_cast<long long>(std::llround(req.seconds * 1000));
            break;
        case MediaKind::Voice: {
            const bool idLooksRight = !req.voice.empty() && req.voice.find_first_not_of(
                "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-") == std::string::npos;
            if (!idLooksRight) {
                return make_error(req.voice.empty() ? "ElevenLabs needs a voice id to speak with" : "'" + req.voice + "' is not an ElevenLabs voice id",
                                  "Set assets.voice.voice in ai.json or pass `voice`: the id of a voice from your ElevenLabs voice library "
                                  "(elevenlabs.io/app/voice-library, or GET /v1/voices).");
            }
            if (model.empty()) model = "eleven_multilingual_v2";
            path = "/v1/text-to-speech/" + req.voice;
            body = Json::object({{"text", req.prompt}, {"model_id", model}});
            break;
        }
        default: return make_error("ElevenLabs does not generate " + std::string(media_kind_name(req.kind)));
    }

    HttpRequest hr;
    hr.url = trim_slashes(cfg.baseUrl) + path + kFormat;
    hr.headers.emplace_back("xi-api-key", *key);
    hr.headers.emplace_back("Content-Type", "application/json");
    hr.headers.emplace_back("Accept", "audio/mpeg");
    for (const auto& kv : cfg.headers) hr.headers.push_back(kv);
    hr.body = dump(body);
    auto resp = asset_request(cfg, std::move(hr), rt, cancel);
    if (!resp) return resp.error();
    AssetResult out;
    out.bytes = std::move(resp->body);
    out.model = model;
    if (req.kind == MediaKind::Voice) out.voice = req.voice;
    return out;
}

}  // namespace fa::ai
