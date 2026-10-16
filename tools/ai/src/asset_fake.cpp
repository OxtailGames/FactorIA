// The `fake` asset provider: offline, free and deterministic (the same request always gives the same bytes), for tests,
// CI and for trying the asset pipeline before spending credits. Everything is derived from a hash of the request, with no
// rand() and no clock. The results are placeholders, not art: a patterned PNG, tones and noise as WAV, a glTF cube.
#include <algorithm>
#include <cmath>
#include <numbers>

#include "asset_providers.h"
#include "fa/core/hash.h"
#include "fa/core/image.h"
#include "fa/core/math.h"
#include "fa/core/strings.h"
#include "util.h"

namespace fa::ai {

namespace {

constexpr int kSampleRate = 22050;
constexpr double kMaxSoundSeconds = 30, kMaxMusicSeconds = 60;

std::uint64_t request_hash(const AssetRequest& req) {
    Sha256 h;
    h.update(media_kind_name(req.kind));
    h.update(req.prompt);
    h.update(req.voice);
    if (req.seed) h.update(std::to_string(*req.seed));
    for (const ReferenceImage& r : req.references) h.update(r.bytes);
    return std::stoull(h.finish_hex().substr(0, 16), nullptr, 16);
}

// ---- images -------------------------------------------------------------------------------------------------

struct Rgb {
    double r, g, b;
};

// A colour of a hue (0..1) at a fixed saturation and value.
Rgb hue_colour(double hue, double value) {
    const double h = hue * 6, f = h - std::floor(h), s = 0.65;
    const double p = value * (1 - s), q = value * (1 - s * f), t = value * (1 - s * (1 - f));
    switch (static_cast<int>(h) % 6) {
        case 0: return {value, t, p};
        case 1: return {q, value, p};
        case 2: return {p, value, t};
        case 3: return {p, q, value};
        case 4: return {t, p, value};
        default: return {value, p, q};
    }
}

std::uint8_t byte(double v) { return static_cast<std::uint8_t>(std::clamp(v, 0.0, 1.0) * 255 + 0.5); }

// A background gradient with diagonal stripes (or nothing, when transparent) and one shape per frame: a sheet's frames each
// draw a different shape, in a different place, so an animation of the sheet visibly changes.
Image fake_image(const AssetRequest& req, std::uint64_t seed) {
    Rng rng{seed};
    Image img;
    img.width = std::max(1, req.width);
    img.height = std::max(1, req.height);
    img.rgba.assign(static_cast<std::size_t>(img.width) * img.height * 4, 0);
    const int cols = std::max(1, req.columns), rows = std::max(1, req.rows);
    const double hue = rng.next_float();
    const Rgb bgA = hue_colour(hue, 0.55), bgB = hue_colour(std::fmod(hue + 0.15, 1.0), 0.8);
    const Rgb fg = hue_colour(std::fmod(hue + 0.5, 1.0), 1.0);
    const int shapeBase = static_cast<int>(rng.next_u32() % 4);
    const double wobble = 0.5 + rng.next_float();
    for (int y = 0; y < img.height; ++y) {
        for (int x = 0; x < img.width; ++x) {
            const int cx = std::min(cols - 1, x * cols / img.width), cy = std::min(rows - 1, y * rows / img.height);
            const int frame = cy * cols + cx;
            const double u = static_cast<double>(x) * cols / img.width - cx, v = static_cast<double>(y) * rows / img.height - cy;
            // shape centre moves around a small circle from frame to frame
            const double dx = u - (0.5 + 0.18 * std::sin(frame * wobble)), dy = v - (0.5 + 0.18 * std::cos(frame * wobble));
            const double size = 0.22 + 0.04 * (frame % 3);
            bool inside = false;
            switch ((shapeBase + frame) % 4) {
                case 0: inside = std::hypot(dx, dy) < size; break;                                  // disc
                case 1: inside = std::max(std::abs(dx), std::abs(dy)) < size * 0.85; break;         // square
                case 2: inside = std::abs(dx) + std::abs(dy) < size * 1.2; break;                   // diamond
                default: inside = std::hypot(dx, dy) < size && std::hypot(dx, dy) > size * 0.55; break;  // ring
            }
            Rgb c{};
            double a = 0;
            if (inside) {
                c = fg;
                a = 1;
            } else if (!req.transparent) {
                const double t = (u + v) / 2, stripe = ((x + y) / 8) % 2 ? 0.92 : 1.0;
                c = {(bgA.r + (bgB.r - bgA.r) * t) * stripe, (bgA.g + (bgB.g - bgA.g) * t) * stripe,
                     (bgA.b + (bgB.b - bgA.b) * t) * stripe};
                a = 1;
            }
            std::uint8_t* px = &img.rgba[(static_cast<std::size_t>(y) * img.width + x) * 4];
            px[0] = byte(c.r);
            px[1] = byte(c.g);
            px[2] = byte(c.b);
            px[3] = byte(a);
        }
    }
    return img;
}

// ---- audio --------------------------------------------------------------------------------------------------

std::string wav_file(const std::vector<std::int16_t>& samples) {
    const std::uint32_t dataBytes = static_cast<std::uint32_t>(samples.size() * 2);
    std::string out;
    auto u32 = [&](std::uint32_t v) { for (int i = 0; i < 4; ++i) out.push_back(static_cast<char>((v >> (8 * i)) & 0xFF)); };
    auto u16 = [&](std::uint16_t v) { for (int i = 0; i < 2; ++i) out.push_back(static_cast<char>((v >> (8 * i)) & 0xFF)); };
    out += "RIFF";
    u32(36 + dataBytes);
    out += "WAVEfmt ";
    u32(16);
    u16(1);  // PCM
    u16(1);  // mono
    u32(kSampleRate);
    u32(kSampleRate * 2);
    u16(2);
    u16(16);
    out += "data";
    u32(dataBytes);
    for (std::int16_t s : samples) u16(static_cast<std::uint16_t>(s));
    return out;
}

// A sound effect: a falling tone with a burst of noise at the start.
void synth_sound(std::vector<std::int16_t>& out, Rng& rng, double seconds) {
    const double f0 = 400 + rng.next_float() * 800;
    double phase = 0;
    for (std::size_t i = 0; i < out.size(); ++i) {
        const double t = static_cast<double>(i) / kSampleRate;
        phase += 2 * std::numbers::pi * f0 * std::exp(-t * 2.0 / seconds) / kSampleRate;
        const double noise = rng.next_float() * 2 - 1;
        out[i] = static_cast<std::int16_t>(32767 * 0.6 * (std::sin(phase) * std::exp(-t * 4.0 / seconds) + 0.3 * noise * std::exp(-t * 30)));
    }
}

// Notes of `noteLen` samples one after the other: a sine at the pitch `pitch()` returns for each note, shaped by `env(x)`
// (x runs 0..1 over the note).
template <class Pitch, class Env>
void synth_notes(std::vector<std::int16_t>& out, std::size_t noteLen, double gain, Pitch pitch, Env env) {
    for (std::size_t n = 0; n * noteLen < out.size(); ++n) {
        const double f = pitch();
        for (std::size_t i = 0; i < noteLen && n * noteLen + i < out.size(); ++i) {
            const double t = static_cast<double>(i) / kSampleRate;
            out[n * noteLen + i] = static_cast<std::int16_t>(32767 * gain * std::sin(2 * std::numbers::pi * f * t) * env(static_cast<double>(i) / noteLen));
        }
    }
}

// Music: an arpeggio on a minor pentatonic scale, four notes a second.
void synth_music(std::vector<std::int16_t>& out, Rng& rng) {
    static constexpr int scale[] = {0, 3, 5, 7, 10};
    const double root = 110 * std::pow(2.0, static_cast<int>(rng.next_u32() % 12) / 12.0);
    synth_notes(out, kSampleRate / 4, 0.4,
                [&] {
                    const int degree = scale[rng.next_u32() % 5];  // separate statements: the order of the draws is fixed
                    const int octave = static_cast<int>(rng.next_u32() % 3);
                    return root * std::pow(2.0, (degree + 12 * octave) / 12.0);
                },
                [](double x) { return std::exp(-x * 1.5); });
}

// Voice: a buzz of syllables of about 60 ms, each with its own pitch.
void synth_voice(std::vector<std::int16_t>& out, Rng& rng) {
    synth_notes(out, kSampleRate * 6 / 100, 0.3, [&] { return 110 + rng.next_float() * 90.0; },
                [](double x) { return std::sin(std::numbers::pi * x); });
}

std::string fake_audio(const AssetRequest& req, std::uint64_t seed) {
    Rng rng{seed};
    double seconds = req.seconds;
    switch (req.kind) {
        case MediaKind::Sound: seconds = std::clamp(seconds > 0 ? seconds : 1.0, 0.1, kMaxSoundSeconds); break;
        case MediaKind::Music: seconds = std::clamp(seconds > 0 ? seconds : 4.0, 0.5, kMaxMusicSeconds); break;
        default: seconds = std::clamp(0.06 * static_cast<double>(req.prompt.size()), 0.4, 20.0); break;  // voice: text-driven
    }
    std::vector<std::int16_t> samples(static_cast<std::size_t>(seconds * kSampleRate));
    if (req.kind == MediaKind::Sound) synth_sound(samples, rng, seconds);
    else if (req.kind == MediaKind::Music) synth_music(samples, rng);
    else synth_voice(samples, rng);
    return wav_file(samples);
}

// ---- 3D -----------------------------------------------------------------------------------------------------

// A unit cube as a single self-contained glTF 2.0 file: 24 vertices (position + normal) and 36 indices in an embedded
// buffer, one material whose colour comes from the hash.
std::string fake_model(std::uint64_t seed) {
    struct Face {
        float n[3], r[3], u[3];
    };
    static constexpr Face faces[6] = {{{0, 0, 1}, {1, 0, 0}, {0, 1, 0}},   {{0, 0, -1}, {-1, 0, 0}, {0, 1, 0}},
                                      {{1, 0, 0}, {0, 0, -1}, {0, 1, 0}},  {{-1, 0, 0}, {0, 0, 1}, {0, 1, 0}},
                                      {{0, 1, 0}, {1, 0, 0}, {0, 0, -1}},  {{0, -1, 0}, {1, 0, 0}, {0, 0, 1}}};
    static constexpr float corner[4][2] = {{-1, -1}, {1, -1}, {1, 1}, {-1, 1}};
    std::string buffer;
    auto put = [&buffer](const void* p, std::size_t n) { buffer.append(static_cast<const char*>(p), n); };  // little-endian hosts
    for (const Face& f : faces) {
        for (const auto& c : corner) {
            for (int k = 0; k < 3; ++k) {
                const float pos = 0.5f * (f.n[k] + c[0] * f.r[k] + c[1] * f.u[k]);
                put(&pos, 4);
            }
            put(f.n, 12);
        }
    }
    for (std::uint16_t face = 0; face < 6; ++face) {
        const std::uint16_t b = static_cast<std::uint16_t>(face * 4), tri[6] = {b, static_cast<std::uint16_t>(b + 1), static_cast<std::uint16_t>(b + 2),
                                                                                 b, static_cast<std::uint16_t>(b + 2), static_cast<std::uint16_t>(b + 3)};
        put(tri, sizeof tri);
    }
    const Rgb colour = hue_colour(Rng{seed}.next_float(), 0.9);
    Json gltf = Json::object({
        {"asset", Json::object({{"version", "2.0"}, {"generator", "FactorIA fake asset provider"}})},
        {"scene", 0},
        {"scenes", Json::array({Json::object({{"nodes", Json::array({0})}})})},
        {"nodes", Json::array({Json::object({{"mesh", 0}, {"name", "FakeCube"}})})},
        {"meshes", Json::array({Json::object({{"primitives", Json::array({Json::object({{"attributes", Json::object({{"POSITION", 0}, {"NORMAL", 1}})},
                                                                                         {"indices", 2},
                                                                                         {"material", 0}})})}})})},
        {"materials", Json::array({Json::object({{"pbrMetallicRoughness",
                                                  Json::object({{"baseColorFactor", Json::array({colour.r, colour.g, colour.b, 1.0})},
                                                                {"metallicFactor", 0.0}})},
                                                 {"doubleSided", true}})})},
        {"buffers", Json::array({Json::object({{"byteLength", buffer.size()},
                                               {"uri", "data:application/octet-stream;base64," + base64_encode(buffer.data(), buffer.size())}})})},
        {"bufferViews", Json::array({Json::object({{"buffer", 0}, {"byteOffset", 0}, {"byteLength", 24 * 24}, {"byteStride", 24}, {"target", 34962}}),
                                     Json::object({{"buffer", 0}, {"byteOffset", 24 * 24}, {"byteLength", 36 * 2}, {"target", 34963}})})},
        {"accessors", Json::array({Json::object({{"bufferView", 0}, {"byteOffset", 0}, {"componentType", 5126}, {"count", 24}, {"type", "VEC3"},
                                                 {"min", Json::array({-0.5, -0.5, -0.5})}, {"max", Json::array({0.5, 0.5, 0.5})}}),
                                   Json::object({{"bufferView", 0}, {"byteOffset", 12}, {"componentType", 5126}, {"count", 24}, {"type", "VEC3"}}),
                                   Json::object({{"bufferView", 1}, {"componentType", 5123}, {"count", 36}, {"type", "SCALAR"}})})},
    });
    return gltf.dump();
}

}  // namespace

Result<AssetResult> fake_asset(const AssetRequest& req) {
    const std::uint64_t seed = request_hash(req);
    AssetResult out;
    out.usedReferences = !req.references.empty();
    out.seed = req.seed;
    if (req.kind == MediaKind::Voice) out.voice = req.voice;
    switch (req.kind) {
        case MediaKind::Image: {
            const std::vector<std::uint8_t> png = encode_png(fake_image(req, seed));
            out.bytes.assign(png.begin(), png.end());
            break;
        }
        case MediaKind::Model3d: out.bytes = fake_model(seed); break;
        default: out.bytes = fake_audio(req, seed); break;
    }
    return out;
}

}  // namespace fa::ai
