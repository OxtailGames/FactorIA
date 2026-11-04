// assets.synth_sound: makes a short sound effect from a preset, offline: no provider, no key. The presets are sound patches
// (fa/audio/sfx.h, sfx.preset returns them); this renders one with the engine's synthesizer. The WAV is a pure function of
// (preset, seed, seconds): the noise comes from the patch's seeded generator, never from the clock.
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <format>

#include "assets_internal.h"
#include "fa/audio/sfx.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/strings.h"
#include "fa/tooling/asset_import.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

// A small integer generator for the take: the same on every platform.
struct Rng {
    std::uint64_t s;
    std::uint64_t next() {
        std::uint64_t z = (s += 0x9E3779B97F4A7C15ull);
        z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ull;
        z = (z ^ (z >> 27)) * 0x94D049BB133111EBull;
        return z ^ (z >> 31);
    }
    double unit() { return double(next() >> 11) / double(1ull << 53); }  // 0..1
    double range(double lo, double hi) { return lo + (hi - lo) * unit(); }
};

std::vector<std::string> preset_names() {
    std::vector<std::string> out;
    for (const SfxPresetInfo& p : sfx_presets()) out.push_back(p.name);
    return out;
}

// The preset as a patch (the same JSON sfx.preset returns), at `seconds` long when given. Every preset is checked by the
// tests, so a failure here is an engine bug.
SfxPatch preset_patch(const std::string& name, double seconds) {
    std::optional<Json> json = sfx_preset_patch(name);
    if (!json) fail("failed", "The preset '" + name + "' has no patch.", "This is an engine bug; report it.");
    auto patch = parse_sfx(*json, "preset " + name);
    if (!patch.ok()) fail("failed", "The preset '" + name + "' is not a valid patch: " + patch.error().message, patch.error().hint);
    if (seconds > 0.0) stretch_sfx(*patch, seconds / patch->length);
    return std::move(*patch);
}

Json synth_sound(const std::string& projectDir, const Json& a) {
    check_arg_keys("assets.synth_sound", a, "", {"path", "preset", "seed", "seconds", "overwrite"});
    const std::string path = tooling_detail::arg_string(a, "path", true);
    const std::string presetName = to_lower(tooling_detail::arg_string(a, "preset", true));
    if (!sfx_preset_patch(presetName)) {
        const auto names = preset_names();
        fail("invalid_argument", "Unknown preset '" + presetName + "'.", did_you_mean(presetName, names) + " Presets: " + join(names, ", ") + ".");
    }
    auto norm = fs::normalize_checked(path);
    if (!norm.ok() || norm->empty() || !starts_with(*norm, "assets/"))
        fail("invalid_argument", "The sound goes under assets/, and '" + path + "' is not there.", "Use a path such as \"assets/audio/" + presetName + ".wav\".");
    if (to_lower(fs::extension(*norm)) != ".wav")
        fail("invalid_argument", "assets.synth_sound writes WAV files, and '" + *norm + "' does not end in .wav.", "Use a path such as \"assets/audio/" + presetName + ".wav\".");
    const long seed = tooling_detail::arg_int(a, "seed", 0);
    double seconds = preset_patch(presetName, 0.0).length;
    const double presetSeconds = seconds;
    if (a.contains("seconds")) {
        if (!a["seconds"].is_number() || a["seconds"].get<double>() < 0.02 || a["seconds"].get<double>() > 10.0)
            fail("invalid_argument", "seconds must be a number from 0.02 to 10.", "Leave it out for the preset's own length (" + std::format("{:.2f}", presetSeconds) + " s for " + presetName + ").");
        seconds = a["seconds"].get<double>();
    }
    const bool overwrite = tooling_detail::arg_bool(a, "overwrite", false);
    const stdfs::path file = project_file(projectDir, *norm);
    std::error_code ec;
    if (!overwrite && stdfs::exists(file, ec)) fail("exists", "'" + *norm + "' already exists.", "Pass overwrite: true to replace it, or choose another `path`.");
    require_usable_manifest(projectDir);

    // The seed is another take: the noise changes and the pitch moves up to 10 percent either way.
    SfxPatch patch = preset_patch(presetName, a.contains("seconds") ? seconds : 0.0);
    Rng rng{std::uint64_t(seed) * 0x2545F4914F6CDD1Dull + 0x1234567ull};
    SfxRenderOptions options;
    options.seed = std::uint64_t(seed);
    options.freqHz = patch.root_hz() * rng.range(0.9, 1.1);
    auto audio = render_sfx(patch, options);
    if (!audio.ok()) fail("failed", "Cannot render the preset '" + presetName + "': " + audio.error().message, audio.error().hint);
    const std::vector<std::uint8_t> wav = sfx_wav_bytes(*audio);
    const std::string bytes(reinterpret_cast<const char*>(wav.data()), wav.size());
    std::string err;
    if (!tooling_detail::write_file(file, bytes, &err)) fail("failed", err);

    Json provenance = Json::object({{"origin", "original"},
                                    {"ai", false},
                                    {"kind", "sound"},
                                    {"provider", "factoria assets.synth_sound"},
                                    {"seed", seed},
                                    {"license", "CC0-1.0"},
                                    {"author", "factoria"},
                                    {"notes", "preset " + presetName + ", " + std::format("{:.2f}", seconds) + " s, seed " + std::to_string(seed)},
                                    {"date", assets::today()},
                                    {"recipe", make_recipe(projectDir, "assets.synth_sound", recipe_args(a, {{"path", *norm}, {"preset", presetName}, {"seed", seed}, {"seconds", seconds}}), {})}});
    {
        ProjectRootGuard root(projectDir);
        auto r = assets::update_entry(*norm, [&](Json& e) {
            e.erase("analysis");
            e["provenance"] = provenance;
        });
        if (!r.ok()) fail("failed", "The sound was written, but assets.json was not updated: " + r.error().message, r.error().hint);
    }
    return Json::object({{"path", *norm}, {"preset", presetName}, {"seed", seed}, {"seconds", seconds}, {"bytes", bytes.size()}, {"provenance", provenance},
                         {"nextSteps", Json::array({"Play it: audio.play(\"" + *norm + "\") in a script, or an AudioSource \"clip\".",
                                                    "Another take of the same sound: change `seed`. Same seed, same bytes."})}});
}

}  // namespace

void register_synth_sound_command(CommandRegistry& registry, const std::string& projectDir) {
    std::string presets;
    for (const SfxPresetInfo& p : sfx_presets()) presets += "\n- " + p.name + ": " + p.what + ".";
    CommandInfo info;
    info.name = "assets.synth_sound";
    info.category = "assets";
    info.readOnly = false;
    info.summary = "Make a game sound (bark, growl, coin, jump, explosion...) offline from a preset: a deterministic WAV, no provider and no key.";
    info.description =
        "Synthesizes a short mono 16-bit 44.1 kHz WAV at `path` (under assets/, ending in .wav) from `preset`, with no AI provider and no "
        "key. The presets are sound patches rendered by the engine's synthesizer: sfx.preset returns one as an editable *.sfx.json (docs/SOUND.md), so to change a "
        "sound instead of taking it as it is, write the patch, edit it and call sfx.render. The same preset, seed and seconds always give the same bytes; another `seed` is "
        "another take of the same sound (the noise changes and the pitch moves up to 10 percent). `seconds` stretches the whole sound. Levelled to about -18 LUFS (peak under -1 dBFS), so no preset trips validate's loudness warning. Records provenance in assets.json (origin original, ai false, license "
        "CC0, the preset and the seed). Presets:" + presets +
        "\nGood for placeholders and simple effects; for richer sounds import a CC0 kit (docs/ASSETS.md) or use assets.generate_sound. "
        "Example: {\"path\":\"assets/audio/dog_bark.wav\",\"preset\":\"bark\",\"seed\":3}";
    info.inputSchema = Json::object(
        {{"type", "object"},
         {"required", Json::array({"path", "preset"})},
         {"additionalProperties", false},
         {"properties",
          Json::object(
              {{"path", Json::object({{"type", "string"}, {"description", "Where to write the WAV, project-relative, under assets/ and ending in .wav, e.g. \"assets/audio/bark.wav\"."}})},
               {"preset", Json::object({{"type", "string"}, {"enum", preset_names()}, {"description", "The kind of sound to make. See the list in the command description."}})},
               {"seed", Json::object({{"type", "integer"}, {"default", 0}, {"description", "Chooses the take: the same preset and seed always give the same file; change it for a variation (the noise changes and the pitch shifts up to 10 percent)."}})},
               {"seconds", Json::object({{"type", "number"}, {"minimum", 0.02}, {"maximum", 10}, {"description", "Length in seconds: the whole sound (envelopes, sweeps) is stretched to it. Default: the preset's own length."}})},
               {"overwrite", Json::object({{"type", "boolean"}, {"default", false}, {"description", "Replace the file when it already exists."}})}})}});
    registry.add(info, [projectDir](const Json& args) { return synth_sound(projectDir, args); });
}

}  // namespace fa::assets_detail
