#include "fa/tooling/audio_analysis.h"

#include <algorithm>
#include <cmath>
#include <format>
#include <set>

#include "fa/core/asset_manifest.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/scene/serialize.h"
#include "util.h"

namespace fa {

namespace {

// Every string of `j` that names a sound.
void collect_audio_strings(const Json& j, std::set<std::string>& out) {
    if (j.is_string()) {
        if (tooling_detail::is_audio_file(j.get<std::string>())) out.insert(fs::normalize(j.get<std::string>()));
    } else if (j.is_array() || j.is_object()) {
        for (const Json& v : j) collect_audio_strings(v, out);
    }
}

}  // namespace

std::vector<std::string> project_audio_files(const std::string& projectDir) {
    tooling_detail::ProjectRootScope root(projectDir);
    std::set<std::string> found;
    for (const std::string& f : fs::list("assets", true))
        if (tooling_detail::is_audio_file(f)) found.insert(f);
    for (const std::string& scene : project_scene_files()) {
        auto text = fs::read_text(scene);
        auto parsed = text ? parse_json(*text, scene) : Result<Json>(text.error());
        if (parsed) collect_audio_strings(*parsed, found);
    }
    std::vector<std::string> out;
    for (const std::string& f : found)
        if (!f.empty() && fs::exists(f)) out.push_back(f);
    return out;
}

Result<AudioAnalysis> analyze_audio_file(const std::string& projectDir, const std::string& path) {
    tooling_detail::ProjectRootScope root(projectDir);
    AudioAnalysis a;
    a.path = fs::normalize(path);
    if (a.path.empty()) return make_error("'" + path + "' is outside the project", "Use a project-relative path such as assets/music.ogg.");
    auto file = read_audio_file(a.path);
    if (!file) return file.error();
    a.file = file->path;
    a.settings = assets::import_settings(a.path);
    const Json entry = assets::entry(a.path);
    const Json* stored = entry.contains("analysis") ? &entry["analysis"] : nullptr;
    if (auto fresh = stored ? cached_loudness(*stored, file->bytes) : std::nullopt) {
        a.loudness = *fresh;
        a.cached = true;
    } else {
        auto measured = measure_loudness(file->bytes, fs::extension(file->path));
        if (!measured) return make_error(a.file + ": " + measured.error().message, measured.error().hint);
        a.loudness = *measured;
    }
    a.record = loudness_analysis(a.loudness, file->bytes);
    return a;
}

std::vector<ValidationIssue> check_audio_loudness(const std::string& projectDir) {
    // ponytail: decodes every sound whose assets.json entry has no fresh `analysis` on each validate run, so a project
    // with hours of audio validates slowly until `assets.analyze_audio` has stored the measurements. Upgrade path: a
    // cache under .factoria/ keyed by the file's sha256 (as the export does for conversions), which validate may write.
    constexpr double kClippedDb = -0.1, kLoudLufs = -9.0, kQuietLufs = -35.0, kEffectSpreadLu = 12.0;
    const char* normalizeHint = "Set import \"normalize\": true for it (or under defaults.audio) in assets.json to play it at "
                                "a target loudness, or level the source file. See docs/ASSETS.md, \"Import settings > Audio\".";
    std::vector<ValidationIssue> out;
    struct Effect {
        std::string path;
        double lufs;  // as it plays: with the gain normalization adds
    };
    std::vector<Effect> effects;
    auto num = [](double v) { return std::format("{:.1f}", v); };
    for (const std::string& path : project_audio_files(projectDir)) {
        auto a = analyze_audio_file(projectDir, path);
        if (!a) {
            out.push_back({path, "", "Cannot measure the loudness of this sound: " + a.error().message, a.error().hint});
            continue;
        }
        const Loudness& l = a->loudness;
        const bool normalize = tooling_detail::bool_setting(a->settings, "normalize");
        const double gain = normalize ? normalization_gain_db(l, tooling_detail::number_setting(a->settings, "targetLufs", -16.0)) : 0.0;
        if (l.peakDb > kClippedDb)
            out.push_back({path, "", "Peaks at " + num(l.peakDb) + " dBFS: the waveform reaches full scale and is probably clipped.",
                           "Export the sound again at a lower level (the engine has no limiter), or set import \"normalize\": true "
                           "so it plays with its peak under -1 dBFS."});
        if (l.integratedLufs <= kSilentLufs)
            out.push_back({path, "", "Has no audible content (nothing above " + num(kSilentLufs) + " LUFS).",
                           "Replace the placeholder with the real sound."});
        else if (l.integratedLufs > kLoudLufs)
            out.push_back({path, "", "Very loud: " + num(l.integratedLufs) + " LUFS (music is mastered around -14 to -16).", normalizeHint});
        else if (l.integratedLufs < kQuietLufs)
            out.push_back({path, "", "Very quiet: " + num(l.integratedLufs) + " LUFS (music is mastered around -14 to -16).", normalizeHint});
        if (l.integratedLufs > kSilentLufs && !clip_streams("auto", l.seconds)) effects.push_back({path, l.integratedLufs + gain});
    }
    if (effects.size() >= 2) {
        auto [quiet, loud] = std::minmax_element(effects.begin(), effects.end(),
                                                 [](const Effect& x, const Effect& y) { return x.lufs < y.lufs; });
        if (loud->lufs - quiet->lufs > kEffectSpreadLu)
            out.push_back({loud->path, "", "Sound effects differ by " + num(loud->lufs - quiet->lufs) + " LU in loudness: this one plays at " +
                                               num(loud->lufs) + " LUFS and '" + quiet->path + "' at " + num(quiet->lufs) + " LUFS.",
                           normalizeHint});
    }
    return out;
}

void register_audio_commands(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = "assets.analyze_audio";
    info.category = "assets";
    info.readOnly = false;
    info.summary = "Measure the loudness of a sound (or of every sound) and keep the result in assets.json.";
    info.description =
        "Measures integrated loudness (LUFS, ITU-R BS.1770-4 / EBU R128) and sample peak (dBFS) of .wav, .ogg, .mp3 and .qoa "
        "files, and stores them under the sound's `analysis` in assets.json together with the size and SHA-256 of the file, "
        "so editing the sound later makes the record stale instead of wrong. Sounds with import \"normalize\": true play at "
        "`targetLufs` using that record; without one the desktop engine measures the sound when it loads it, and mobile "
        "builds cannot, so run this (or export, which stores it) before shipping. A sound whose record is still fresh is not "
        "measured again. Without `path` every sound under assets/ and every sound a scene or prefab names is analyzed. "
        "Returns {files: [{path, loudnessLufs, peakDb, seconds, streams, normalize, gainDb, cached, stored}], measured, "
        "cached, failed}: `streams` says whether the sound is decoded while it plays (import stream), `gainDb` is the gain "
        "normalize would apply (only when normalize is on). A sound that cannot be decoded is listed with `error` and `hint` "
        "when no path is given. Example: {\"path\": \"assets/music/theme.ogg\"}";
    info.inputSchema = Json::object(
        {{"type", "object"},
         {"properties", Json::object({{"path", Json::object({{"type", "string"},
                                                              {"description", "Project-relative sound file, e.g. assets/sfx/jump.wav. "
                                                                              "Omit to analyze every sound of the project."}})}})}});
    registry.add(info, [projectDir](const Json& args) {
        const std::string asked = tooling_detail::arg_string(args, "path", false);
        std::vector<std::string> paths;
        if (asked.empty()) {
            paths = project_audio_files(projectDir);
        } else {
            if (!tooling_detail::is_audio_file(asked))
                throw CommandError("invalid_argument", "'" + asked + "' is not a sound file.", "Sounds are .wav, .ogg, .mp3 or .qoa files.");
            paths.push_back(asked);
        }
        Json files = Json::array();
        int measured = 0, cached = 0, failed = 0;
        for (const std::string& path : paths) {
            auto a = analyze_audio_file(projectDir, path);
            if (!a) {
                if (!asked.empty()) throw CommandError("failed", a.error().message, a.error().hint);
                ++failed;
                files.push_back(Json::object({{"path", path}, {"error", a.error().message}, {"hint", a.error().hint}}));
                continue;
            }
            bool stored = false;
            if (a->cached) {
                ++cached;
            } else {
                ++measured;
                tooling_detail::ProjectRootScope root(projectDir);
                auto written = assets::update_entry(a->path, [&](Json& entry) {
                    if (!entry["analysis"].is_object()) entry["analysis"] = Json::object();
                    entry["analysis"].update(a->record);  // other kinds of measurement stay
                });
                if (!written) throw CommandError("failed", written.error().message, written.error().hint);
                stored = true;
            }
            const bool normalize = tooling_detail::bool_setting(a->settings, "normalize");
            Json item = Json::object({{"path", a->path},
                                      {"loudnessLufs", a->record["loudnessLufs"]},
                                      {"peakDb", a->record["peakDb"]},
                                      {"seconds", a->record["seconds"]},
                                      {"streams", clip_streams(tooling_detail::string_setting(a->settings, "stream", "auto"), a->loudness.seconds)},
                                      {"normalize", normalize},
                                      {"cached", a->cached},
                                      {"stored", stored}});
            if (normalize)
                item["gainDb"] = std::round(normalization_gain_db(a->loudness, tooling_detail::number_setting(a->settings, "targetLufs", -16.0)) * 100.0) / 100.0;
            files.push_back(std::move(item));
        }
        Json result = Json::object({{"files", files}, {"measured", measured}, {"cached", cached}, {"failed", failed}});
        if (paths.empty()) result["note"] = "No sounds found: put .wav, .ogg or .mp3 files under assets/.";
        return result;
    });
}

}  // namespace fa
