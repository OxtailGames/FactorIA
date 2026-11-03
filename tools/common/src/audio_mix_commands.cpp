// assets.spectrogram and assets.check_mix: the AI's ears. A sound is seen as a picture (waveform, spectrogram, loudness
// curve) and the sounds of a project are measured together (loudness per bus, music masking effects, clicks, loop seams,
// clipping, true peak). The numbers come from audio_mix.h; the loudness from the `analysis` record of assets.json when it is
// fresh. Nothing here writes assets.json or plays a sound.
#include <algorithm>
#include <atomic>
#include <cmath>
#include <format>
#include <map>
#include <set>

#include "assets_internal.h"
#include "audio_mix.h"
#include "fa/audio/analysis.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/core/screenshot_files.h"
#include "fa/core/strings.h"
#include "fa/render/fonts.h"
#include "fa/scene/serialize.h"
#include "fa/tooling/audio_analysis.h"
#include "fa/tooling/style_guide.h"
#include "util.h"

namespace fa {

namespace {

using audio_mix::Metrics;
namespace am = audio_mix;

double round_to(double v, int decimals) {
    const double k = std::pow(10.0, decimals);
    return std::round(v * k) / k;
}
Json num(double v, int decimals = 2) { return Json(round_to(v, decimals)); }
std::string db_text(double v) { return v <= -199.0 ? std::string("-inf") : std::format("{:.1f}", v); }

// ---------------------------------------------------------------- how the project plays its sounds ---

struct Play {
    std::set<std::string> buses;  // "sfx", "music", ... as scenes, prefabs and scripts play the sound
    bool loops = false;
};
using PlayMap = std::map<std::string, Play>;

void scan_json(const Json& j, PlayMap& out) {
    if (j.is_object()) {
        if (auto comps = j.find("components"); comps != j.end() && comps->is_object()) {
            if (auto src = comps->find("AudioSource"); src != comps->end() && src->is_object()) {
                auto clip = src->find("clip");
                if (clip != src->end() && clip->is_string() && !clip->get<std::string>().empty()) {
                    Play& p = out[fs::normalize(clip->get<std::string>())];
                    p.buses.insert("sfx");  // an AudioSource plays on the sfx bus
                    auto loop = src->find("loop");
                    if (loop != src->end() && loop->is_boolean() && loop->get<bool>()) p.loops = true;
                }
            }
        }
        if (auto settings = j.find("settings"); settings != j.end() && settings->is_object()) {
            auto music = settings->find("music");
            if (music != settings->end() && music->is_string() && !music->get<std::string>().empty()) {
                Play& p = out[fs::normalize(music->get<std::string>())];
                p.buses.insert("music");  // SceneSettings.music loops on the music bus
                p.loops = true;
            }
        }
        for (const Json& v : j) scan_json(v, out);
    } else if (j.is_array()) {
        for (const Json& v : j) scan_json(v, out);
    }
}

// audio.play("path", {...}) and audio.music("path") with a literal path: the bus and loop of the options object.
void scan_script(const std::string& text, PlayMap& out) {
    for (const char* call : {"audio.play(", "audio.music("}) {
        const bool music = call[6] == 'm';
        for (std::size_t at = text.find(call); at != std::string::npos; at = text.find(call, at + 1)) {
            std::size_t p = at + std::string(call).size();
            while (p < text.size() && text[p] == ' ') ++p;
            if (p >= text.size() || (text[p] != '"' && text[p] != '\'' && text[p] != '`')) continue;
            const char quote = text[p];
            const std::size_t end = text.find(quote, p + 1);
            if (end == std::string::npos) continue;
            const std::string path = text.substr(p + 1, end - p - 1);
            if (!tooling_detail::is_audio_file(path)) continue;
            int depth = 1;
            std::size_t q = end + 1;
            for (; q < text.size() && q < end + 600 && depth > 0; ++q) depth += text[q] == '(' ? 1 : text[q] == ')' ? -1 : 0;
            const std::string args = text.substr(end + 1, q - end - 1);
            Play& play = out[fs::normalize(path)];
            std::string bus = music ? "music" : "sfx";
            if (!music)
                if (std::size_t b = args.find("bus"); b != std::string::npos) {
                    std::size_t c = args.find(':', b);
                    if (c != std::string::npos) {
                        ++c;
                        while (c < args.size() && args[c] == ' ') ++c;
                        if (c < args.size() && (args[c] == '"' || args[c] == '\'')) {
                            const std::size_t e = args.find(args[c], c + 1);
                            if (e != std::string::npos) bus = args.substr(c + 1, e - c - 1);
                        }
                    }
                }
            play.buses.insert(bus);
            if (music) play.loops = true;
            else if (std::size_t l = args.find("loop"); l != std::string::npos) {
                const std::size_t c = args.find(':', l);
                if (c != std::string::npos && args.compare(args.find_first_not_of(' ', c + 1), 4, "true") == 0) play.loops = true;
            }
        }
    }
}

PlayMap scan_project(const std::string& projectDir) {
    tooling_detail::ProjectRootScope root(projectDir);
    PlayMap out;
    for (const std::string& scene : project_scene_files()) {
        auto text = fs::read_text(scene);
        auto parsed = text ? parse_json(*text, scene) : Result<Json>(text.error());
        if (parsed) scan_json(*parsed, out);
    }
    for (const char* folder : {"scripts", "tools"})
        for (const std::string& f : fs::list(folder, true, ".js"))
            if (auto text = fs::read_text(f)) scan_script(*text, out);
    return out;
}

// bus -> the built-in bus it ends in (sfx, music, ui, master), through the "parent" of factoria.json audio.buses.
std::map<std::string, std::string> bus_roots(const std::string& projectDir) {
    tooling_detail::ProjectRootScope root(projectDir);
    std::map<std::string, std::string> parent;
    if (auto text = fs::read_text("factoria.json"))
        if (auto j = parse_json(*text, "factoria.json"); j && j->is_object()) {
            auto audio = j->find("audio");
            auto buses = audio != j->end() && audio->is_object() ? audio->find("buses") : j->end();
            if (audio != j->end() && audio->is_object() && buses != audio->end() && buses->is_object())
                for (auto it = buses->begin(); it != buses->end(); ++it) {
                    auto par = it->is_object() ? it->find("parent") : it->end();
                    parent[it.key()] = it->is_object() && par != it->end() && par->is_string() ? par->get<std::string>() : "master";
                }
        }
    std::map<std::string, std::string> roots;
    for (const char* b : {"sfx", "music", "ui", "master"}) roots[b] = b;
    for (const auto& [name, unused] : parent) {
        std::string cur = name;
        for (int i = 0; i < 16 && parent.count(cur); ++i) cur = parent[cur];
        roots[name] = cur;
    }
    return roots;
}

// ---------------------------------------------------------------- loudness targets ---

struct Target {
    double lufs = 0.0, toleranceLu = 3.0;
    std::string source;  // "targets argument", "style.audio in assets.json"
};

// Reads {"<bus>": lufs | {"lufs", "toleranceLu"}, "default": ...}. `toleranceDefault` applies when the entry has none.
void read_targets(const Json& j, double toleranceDefault, const std::string& source, std::map<std::string, Target>& out) {
    if (!j.is_object()) return;
    for (auto it = j.begin(); it != j.end(); ++it) {
        Target t;
        t.toleranceLu = toleranceDefault;
        t.source = source;
        if (it->is_number()) {
            t.lufs = it->get<double>();
        } else if (it->is_object() && it->contains("lufs") && (*it)["lufs"].is_number()) {
            t.lufs = (*it)["lufs"].get<double>();
            if (it->contains("toleranceLu") && (*it)["toleranceLu"].is_number()) t.toleranceLu = (*it)["toleranceLu"].get<double>();
        } else {
            continue;
        }
        out[it.key()] = t;
    }
}

// style.audio of assets.json, through the shared style parser (a rule with a mistake is left out; validate reports it).
std::map<std::string, Target> style_targets(const std::string& projectDir) {
    std::map<std::string, Target> out;
    StyleParse style = load_style_guide(projectDir);
    if (!style.guide.audio) return out;
    for (const auto& [bus, lufs] : style.guide.audio->loudnessLufs) {
        Target t;
        t.lufs = lufs;
        t.toleranceLu = style.guide.audio->toleranceLu;
        t.source = "style.audio in assets.json";
        out[bus] = t;
    }
    return out;
}

// ---------------------------------------------------------------- the sounds ---

struct Sound {
    std::string path;
    AudioAnalysis analysis;
    Metrics metrics;
    double gainDb = 0.0;
    bool normalize = false;
    double playedLufs = kSilentLufs, playedTruePeakDb = -200.0;
    std::vector<std::string> buses;  // empty: unknown
    std::string role = "unknown";    // "music", "effect" or "unknown"
    bool loops = false;
    double targetLufs = -16.0;  // the import targetLufs
};

struct Finding {
    std::string sound, rule, verdict, unit, message, hint, bus;
    double value = 0.0, threshold = 0.0;
    Json detail;
};

Json finding_json(const Finding& f) {
    Json j = Json::object({{"sound", f.sound}, {"rule", f.rule}, {"value", num(f.value)}, {"threshold", num(f.threshold)}, {"unit", f.unit},
                           {"verdict", f.verdict}, {"message", f.message}, {"hint", f.hint}});
    if (!f.bus.empty()) j["bus"] = f.bus;
    if (!f.detail.is_null()) j["detail"] = f.detail;
    return j;
}

const char* kImportHint = "in assets.json, under the sound's \"import\" (or defaults.audio)";

std::string normalize_fix(const Sound& s, double target) {
    return std::format("Set {} {{\"normalize\": true, \"targetLufs\": {:.0f}}} so it plays at {:.0f} LUFS (assets.json {}), or level the source file.",
                       "\"import\":", target, target, kImportHint);
}

Result<Sound> measure_sound(const std::string& projectDir, const std::string& path, const PlayMap& plays, const std::map<std::string, std::string>& roots) {
    auto analysis = analyze_audio_file(projectDir, path);
    if (!analysis) return analysis.error();
    Sound s;
    s.path = analysis->path;
    s.analysis = std::move(*analysis);
    {
        tooling_detail::ProjectRootScope root(projectDir);
        auto file = read_audio_file(s.analysis.file);
        if (!file) return file.error();
        auto decoded = decode_audio(file->bytes, fs::extension(file->path));
        if (!decoded) return make_error(s.path + ": " + decoded.error().message, decoded.error().hint);
        s.metrics = am::measure(*decoded);
    }
    const Loudness& l = s.analysis.loudness;
    s.normalize = tooling_detail::bool_setting(s.analysis.settings, "normalize");
    s.targetLufs = tooling_detail::number_setting(s.analysis.settings, "targetLufs", -16.0);
    s.gainDb = s.normalize ? normalization_gain_db(l, s.targetLufs) : 0.0;
    s.playedLufs = l.integratedLufs + s.gainDb;
    s.playedTruePeakDb = s.metrics.truePeakDb + s.gainDb;
    if (auto it = plays.find(s.path); it != plays.end()) {
        s.buses.assign(it->second.buses.begin(), it->second.buses.end());
        s.loops = it->second.loops;
    }
    bool music = false, effect = false;
    for (const std::string& b : s.buses) {
        auto r = roots.find(b);
        const std::string root = r != roots.end() ? r->second : b;
        (root == "music" ? music : effect) = true;
    }
    if (music) s.role = "music";
    else if (effect) s.role = "effect";
    return s;
}

std::string bus_label(const Sound& s) {
    if (s.buses.empty()) return "unknown bus";
    std::string out;
    for (const std::string& b : s.buses) out += (out.empty() ? "" : ", ") + b;
    return out;
}

const char* verdict_of(double v, double warn, double fail) { return v > fail ? "fail" : v > warn ? "warn" : "ok"; }

void add(std::vector<Finding>& out, Finding f) { out.push_back(std::move(f)); }

// ---------------------------------------------------------------- the checks ---

void check_clipping(const Sound& s, std::vector<Finding>& out) {
    const std::size_t frames = std::size_t(s.metrics.seconds * s.metrics.rate);
    const double n = double(s.metrics.clippedSamples);
    Finding f{s.path, "clipping", verdict_of(n, 0, std::max(32.0, double(frames) / 2000.0)), "samples", {}, {}, bus_label(s), n, 0};
    f.message = n == 0 ? "No clipped samples."
                       : std::format("{} samples sit at full scale in runs of two or more (the wave is flattened{}).", s.metrics.clippedSamples,
                                     s.metrics.clippedSamples > 1000 ? ", audibly" : "");
    f.hint = n == 0 ? "" : "Export the source again with its peak under -1 dBFS (the engine has no limiter, and import normalize only lowers the "
                           "gain: it cannot restore a flattened wave). If it was generated, generate it again at a lower level.";
    f.detail = Json::object({{"fullScaleSamples", s.metrics.fullScaleSamples}});
    add(out, std::move(f));
}

void check_true_peak(const Sound& s, std::vector<Finding>& out) {
    const double tp = s.playedTruePeakDb;
    Finding f{s.path, "true_peak", verdict_of(tp, -1.0, 0.0), "dBTP", {}, {}, bus_label(s), tp, -1.0};
    const std::string played = s.normalize ? std::format(" (with the normalize gain of {:+.1f} dB)", s.gainDb) : "";
    if (tp > -1.0) {
        const double cut = tp + 1.0;
        f.message = std::format("True peak {} dBTP{} is above -1 dBTP: between samples the wave reaches higher than the samples say, and lossy codecs and DACs can clip it.", db_text(tp), played);
        f.hint = s.normalize ? std::format("Lower \"targetLufs\" of its import by {:.1f} dB (now {:.0f}), or level the source file down.", std::ceil(cut * 10) / 10, s.targetLufs)
                             : std::format("Level the source file down by {:.1f} dB, or set import \"normalize\": true with a \"targetLufs\" about {:.1f} dB under its loudness "
                                           "(the engine has no limiter; normalize keeps the sample peak under -1 dBFS).",
                                           std::ceil(cut * 10) / 10, std::ceil(cut * 10) / 10);
    } else {
        f.message = std::format("True peak {} dBTP{}.", db_text(tp), played);
    }
    add(out, std::move(f));
}

void check_edges(const Sound& s, std::vector<Finding>& out) {
    if (s.loops) return;  // a loop's ends are judged by the seam
    const Metrics& m = s.metrics;
    auto edge = [&](const char* rule, const char* where, double sample, double step) {
        const double stepValue = step >= 0.05 && step / std::max(m.typicalStep, 1e-4) >= 8.0 ? step : 0.0;
        const double level = std::max(sample, stepValue);
        const double db = level > 1e-10 ? 20.0 * std::log10(level) : -200.0;
        Finding f{s.path, rule, verdict_of(db, -40.0, -26.0), "dBFS", {}, {}, bus_label(s), db, -40.0};
        if (f.verdict == "ok") {
            f.message = std::format("The {} of the sound starts from {} dBFS: no click.", where, db_text(db));
        } else {
            f.message = stepValue > sample
                            ? std::format("The {} of the sound jumps {} dBFS in one sample ({:.0f}x its usual step): it clicks.", where, db_text(db), step / std::max(m.typicalStep, 1e-4))
                            : std::format("The {} sample is {} dBFS, not zero: the sound starts or stops abruptly and clicks.", where, db_text(db));
            f.hint = std::format("Fade the {} of the source over 5 to 10 ms (about {} samples at {} Hz), or cut it at a zero crossing; sounds made with assets.synth_sound "
                                 "start and end at zero.",
                                 where, std::lround(0.0075 * m.rate), m.rate);
        }
        add(out, std::move(f));
    };
    edge("click_start", "start", m.firstSample, m.firstStep);
    edge("click_end", "end", m.lastSample, m.lastStep);
}

void check_seam(const Sound& s, std::vector<Finding>& out) {
    if (!s.loops) return;
    const Metrics& m = s.metrics;
    const double jumpDb = m.seamJump > 1e-10 ? 20.0 * std::log10(m.seamJump) : -200.0;
    const bool negligible = m.seamJump < 0.005;  // under -46 dBFS no seam is audible whatever the ratio
    const char* jumpVerdict = negligible ? "ok" : verdict_of(m.seamJumpRatio, 5.0, 10.0);
    Finding j{s.path, "loop_seam_jump", jumpVerdict, "x typical step", {}, {}, bus_label(s), m.seamJumpRatio, 5.0};
    j.detail = Json::object({{"jumpDbfs", num(jumpDb)}, {"jump", num(m.seamJump, 4)}});
    j.message = j.verdict == "ok" ? std::format("The loop's last sample joins its first with a step of {:.1f}x the usual one: no seam.", m.seamJumpRatio)
                                  : std::format("The loop jumps {} dBFS from its last sample to its first ({:.1f}x the sound's usual sample step): it ticks once per repetition.",
                                                db_text(jumpDb), m.seamJumpRatio);
    if (j.verdict != "ok")
        j.hint = "Make the loop seamless: assets.generate_loop writes noise and drone loops with an inaudible seam; for another sound, cut it at points where "
                 "the wave and its slope match (a zero crossing going the same way), or crossfade the end into the start in the source.";
    add(out, std::move(j));
    const bool flat = m.seamSlope < 0.002;
    Finding k{s.path, "loop_seam_slope", flat ? "ok" : verdict_of(m.seamSlopeRatio, 8.0, 16.0), "x typical curvature", {}, {}, bus_label(s), m.seamSlopeRatio, 8.0};
    k.detail = Json::object({{"slopeChange", num(m.seamSlope, 4)}});
    k.message = k.verdict == "ok" ? std::format("The loop's slope continues across the seam ({:.1f}x the usual curvature).", m.seamSlopeRatio)
                                  : std::format("The wave bends {:.1f}x more at the loop point than anywhere else: the slope does not continue, which is heard as a tick.", m.seamSlopeRatio);
    if (k.verdict != "ok") k.hint = j.hint.empty() ? "Cut the loop where the wave goes the same way at both ends, or use assets.generate_loop." : j.hint;
    add(out, std::move(k));
}

void check_loudness(std::vector<Sound*>& sounds, const std::map<std::string, Target>& targets, std::vector<Finding>& out) {
    std::map<std::string, std::vector<Sound*>> byBus;
    for (Sound* s : sounds) {
        if (s->analysis.loudness.integratedLufs <= kSilentLufs) continue;
        if (s->buses.empty()) byBus["unknown bus"].push_back(s);
        for (const std::string& b : s->buses) byBus[b].push_back(s);
    }
    for (auto& [bus, group] : byBus) {
        const Target* target = nullptr;
        if (auto t = targets.find(bus); t != targets.end()) target = &t->second;
        else if (auto d = targets.find("default"); d != targets.end()) target = &d->second;
        const std::string where = bus == "unknown bus" ? "unknown bus (no scene, prefab or script plays it with a literal path)" : "bus \"" + bus + "\"";
        if (target) {
            for (Sound* s : group) {
                const double dev = s->playedLufs - target->lufs;
                Finding f{s->path, "loudness_target", verdict_of(std::fabs(dev), target->toleranceLu, 2 * target->toleranceLu), "LU", {}, {}, bus, dev, target->toleranceLu};
                f.detail = Json::object({{"lufs", num(s->playedLufs)}, {"targetLufs", num(target->lufs)}, {"source", target->source}});
                if (f.verdict == "ok") {
                    f.message = std::format("{:.1f} LUFS as played on {}: {:+.1f} LU from the target of {:.0f} ({}).", s->playedLufs, where, dev, target->lufs, target->source);
                } else {
                    f.message = std::format("{:.1f} LUFS as played on {}: {:+.1f} LU {} the target of {:.0f} LUFS ({}), more than the {:.1f} LU allowed.", s->playedLufs, where,
                                            dev, dev > 0 ? "above" : "below", target->lufs, target->source, target->toleranceLu);
                    f.hint = normalize_fix(*s, target->lufs);
                    if (dev < 0 && s->normalize && s->gainDb >= 23.9) f.hint += " (Its gain is already at the 24 dB cap: level the source file up.)";
                }
                add(out, std::move(f));
            }
        } else if (group.size() >= 2) {
            std::vector<double> levels;
            for (Sound* s : group) levels.push_back(s->playedLufs);
            std::sort(levels.begin(), levels.end());
            const double median = levels.size() % 2 ? levels[levels.size() / 2] : (levels[levels.size() / 2 - 1] + levels[levels.size() / 2]) / 2;
            for (Sound* s : group) {
                const double dev = s->playedLufs - median;
                Finding f{s->path, "loudness_spread", verdict_of(std::fabs(dev), 6.0, 12.0), "LU", {}, {}, bus, dev, 6.0};
                f.detail = Json::object({{"lufs", num(s->playedLufs)}, {"medianLufs", num(median)}, {"sounds", int(group.size())}});
                f.message = std::format("{:.1f} LUFS as played on {}: {:+.1f} LU from the median of its {} sounds ({:.1f} LUFS).", s->playedLufs, where, dev, group.size(), median);
                if (f.verdict != "ok") f.hint = normalize_fix(*s, std::round(median)) + " Or set a loudness target per bus (style.audio.loudnessLufs in assets.json, or the `targets` argument).";
                add(out, std::move(f));
            }
        }
    }
}

void check_masking(const std::vector<Sound*>& sounds, std::vector<Finding>& out) {
    std::vector<const Sound*> music;
    for (const Sound* s : sounds)
        if (s->role == "music" && !s->metrics.silent) music.push_back(s);
    if (music.empty()) return;
    for (const Sound* e : sounds) {
        if (e->role != "effect" || e->metrics.silent || e->metrics.dominantBand < 0) continue;
        const int top = e->metrics.dominantBand;
        const double topLevel = e->metrics.bandDb[std::size_t(top)] + e->gainDb;
        std::vector<int> main;  // the bands within 6 dB of the loudest
        for (int b = 0; b < am::kBands; ++b)
            if (e->metrics.bandDb[std::size_t(b)] > am::kBandAbsent + 1 && e->metrics.bandDb[std::size_t(b)] + e->gainDb >= topLevel - 6.0) main.push_back(b);
        // The music that covers the effect's loudest band the most is the one that masks it.
        const Sound* culprit = music.front();
        for (const Sound* m : music)
            if (m->metrics.bandDb[std::size_t(top)] + m->gainDb > culprit->metrics.bandDb[std::size_t(top)] + culprit->gainDb) culprit = m;
        std::vector<std::string> masked;
        Json bands = Json::array();
        for (int b : main) {
            const double eff = e->metrics.bandDb[std::size_t(b)] + e->gainDb, mus = culprit->metrics.bandDb[std::size_t(b)] + culprit->gainDb;
            if (mus >= eff) masked.push_back(am::kBandNames[b]);
            bands.push_back(Json::object({{"band", am::kBandNames[b]}, {"effectDb", num(eff, 1)}, {"musicDb", num(mus, 1)}}));
        }
        const double headroom = topLevel - (culprit->metrics.bandDb[std::size_t(top)] + culprit->gainDb);
        const bool topMasked = headroom <= 0.0;
        const char* verdict = headroom <= -6.0 ? "fail" : (topMasked || masked.size() * 2 >= main.size()) ? "warn" : "ok";
        Finding f{e->path, "music_masking", verdict, "dB over the music in the effect's loudest band", {}, {}, bus_label(*e), headroom, 0.0};
        f.detail = Json::object({{"music", culprit->path}, {"loudestBand", am::kBandNames[top]}, {"mainBands", bands}});
        std::string list;
        for (const std::string& b : masked) list += (list.empty() ? "" : ", ") + b;
        if (f.verdict == "ok") {
            f.message = std::format("Its main energy ({}) stays {:+.1f} dB over '{}' there: it is heard over the music.", am::kBandNames[top], headroom, culprit->path);
        } else {
            f.message = std::format("Its main energy sits in {}, where '{}' is {} ({:+.1f} dB for the effect); masked bands: {}.", am::kBandNames[top], culprit->path,
                                    topMasked ? "as loud or louder" : "close", headroom, list.empty() ? "none" : list);
            f.hint = std::format("Duck the music while it plays (audio.bus(\"music\").duck(\"sfx\", 0.5), docs/SCRIPTING.md \"Audio buses\"), raise its \"targetLufs\" (assets.json import), "
                                 "or make the effect with its energy outside {} (assets.synth_sound with another preset, or the music with less there).", am::kBandNames[top]);
        }
        add(out, std::move(f));
    }
}

// ---------------------------------------------------------------- assets.check_mix ---

Json check_mix(const std::string& projectDir, const Json& args) {
    assets_detail::check_arg_keys("assets.check_mix", args, "", {"paths", "targets", "includeOk"});
    std::vector<std::string> paths;
    bool asked = false;
    if (args.contains("paths") && !args["paths"].is_null()) {
        asked = true;
        if (!args["paths"].is_array()) throw CommandError("invalid_argument", "'paths' must be an array of project-relative sound files.", "Example: {\"paths\": [\"assets/sfx/jump.wav\"]}");
        for (const Json& p : args["paths"]) {
            if (!p.is_string() || !tooling_detail::is_audio_file(p.get<std::string>()))
                throw CommandError("invalid_argument", "'paths' must hold sound files (.wav, .ogg, .mp3, .qoa); got " + p.dump() + ".", "Use assets.list to see the sounds of the project.");
            paths.push_back(fs::normalize(p.get<std::string>()));
        }
    } else {
        paths = project_audio_files(projectDir);
    }
    std::map<std::string, Target> targets = style_targets(projectDir);
    std::string targetSource = targets.empty() ? "none: loudness is judged by the spread inside each bus" : "style.audio in assets.json";
    if (args.contains("targets") && !args["targets"].is_null()) {
        if (!args["targets"].is_object())
            throw CommandError("invalid_argument", "'targets' must be an object of bus -> LUFS.", "Example: {\"targets\": {\"music\": -16, \"sfx\": {\"lufs\": -14, \"toleranceLu\": 2}}}");
        targets.clear();
        read_targets(args["targets"], 3.0, "targets argument", targets);
        targetSource = "targets argument";
    }

    const PlayMap plays = scan_project(projectDir);
    const auto roots = bus_roots(projectDir);
    std::vector<Sound> sounds;
    sounds.reserve(paths.size());
    Json unreadable = Json::array();
    for (const std::string& p : paths) {
        auto s = measure_sound(projectDir, p, plays, roots);
        if (!s) {
            if (asked && paths.size() == 1) throw CommandError("failed", s.error().message, s.error().hint);
            unreadable.push_back(Json::object({{"path", p}, {"error", s.error().message}, {"hint", s.error().hint}}));
            continue;
        }
        sounds.push_back(std::move(*s));
    }
    std::vector<Sound*> ptrs;
    for (Sound& s : sounds) ptrs.push_back(&s);

    std::vector<Finding> findings;
    for (Sound& s : sounds) {
        if (s.metrics.silent) continue;
        check_clipping(s, findings);
        check_true_peak(s, findings);
        check_edges(s, findings);
        check_seam(s, findings);
    }
    check_loudness(ptrs, targets, findings);
    check_masking(ptrs, findings);

    // Worst first, then by sound and rule: the same project always lists the same way.
    auto rank = [](const std::string& v) { return v == "fail" ? 0 : v == "warn" ? 1 : 2; };
    std::stable_sort(findings.begin(), findings.end(), [&](const Finding& a, const Finding& b) {
        return std::tuple(rank(a.verdict), a.sound, a.rule, a.bus) < std::tuple(rank(b.verdict), b.sound, b.rule, b.bus);
    });
    const bool includeOk = tooling_detail::arg_bool(args, "includeOk", false);
    int ok = 0, warn = 0, fail = 0;
    Json list = Json::array();
    for (const Finding& f : findings) {
        (f.verdict == "ok" ? ok : f.verdict == "warn" ? warn : fail)++;
        if (f.verdict != "ok" || includeOk) list.push_back(finding_json(f));
    }
    Json soundRows = Json::array();
    for (const Sound& s : sounds) {
        Json row = Json::object({{"path", s.path},
                                 {"bus", s.buses.empty() ? Json("unknown bus") : Json(s.buses.size() == 1 ? s.buses[0] : bus_label(s))},
                                 {"role", s.role},
                                 {"loops", s.loops},
                                 {"seconds", num(s.metrics.seconds, 3)},
                                 {"loudnessLufs", num(s.analysis.loudness.integratedLufs)},
                                 {"playedLufs", num(s.playedLufs)},
                                 {"gainDb", num(s.gainDb)},
                                 {"samplePeakDb", num(s.metrics.samplePeakDb)},
                                 {"truePeakDb", num(s.playedTruePeakDb)},
                                 {"clippedSamples", s.metrics.clippedSamples},
                                 {"cachedAnalysis", s.analysis.cached}});
        if (s.metrics.dominantBand >= 0) row["dominantBand"] = am::kBandNames[s.metrics.dominantBand];
        if (s.metrics.silent) row["silent"] = true;
        soundRows.push_back(std::move(row));
    }
    Json targetJson = Json::object();
    for (const auto& [bus, t] : targets) targetJson[bus] = Json::object({{"lufs", t.lufs}, {"toleranceLu", t.toleranceLu}});
    Json result = Json::object({{"verdict", fail ? "fail" : warn ? "warn" : "ok"},
                                {"summary", Json::object({{"sounds", int(sounds.size())}, {"checks", ok + warn + fail}, {"ok", ok}, {"warn", warn}, {"fail", fail}, {"unreadable", int(unreadable.size())}})},
                                {"findings", list},
                                {"sounds", soundRows},
                                {"targets", targetJson},
                                {"targetSource", targetSource}});
    if (!unreadable.empty()) result["unreadable"] = unreadable;
    if (sounds.empty()) result["note"] = "No sounds found: put .wav, .ogg, .mp3 or .qoa files under assets/, or pass `paths`.";
    Json steps = Json::array();
    if (fail || warn) steps.push_back("Fix the findings from the top (each has a `hint`), then run assets.check_mix again; assets.spectrogram shows a single sound.");
    if (std::any_of(sounds.begin(), sounds.end(), [](const Sound& s) { return s.buses.empty(); }))
        steps.push_back("Sounds on an unknown bus are not played with a literal path by any scene, prefab or script: play them with audio.play(\"assets/...\", {bus: \"sfx\"}) or an AudioSource so the check can place them.");
    if (!ok && !warn && !fail && !sounds.empty()) steps.push_back("Nothing to check: every sound is silent.");
    result["nextSteps"] = steps;
    return result;
}

// ---------------------------------------------------------------- the picture ---

struct Rgb {
    std::uint8_t r, g, b;
};

class Canvas {
public:
    Canvas(int w, int h, Rgb bg) {
        img.width = w;
        img.height = h;
        img.rgba.resize(std::size_t(w) * std::size_t(h) * 4);
        for (std::size_t i = 0; i < img.rgba.size(); i += 4) {
            img.rgba[i] = bg.r;
            img.rgba[i + 1] = bg.g;
            img.rgba[i + 2] = bg.b;
            img.rgba[i + 3] = 255;
        }
    }
    void blend(int x, int y, Rgb c, double a) {
        if (x < 0 || y < 0 || x >= img.width || y >= img.height || a <= 0) return;
        std::uint8_t* p = &img.rgba[(std::size_t(y) * std::size_t(img.width) + std::size_t(x)) * 4];
        p[0] = std::uint8_t(p[0] + (c.r - p[0]) * a);
        p[1] = std::uint8_t(p[1] + (c.g - p[1]) * a);
        p[2] = std::uint8_t(p[2] + (c.b - p[2]) * a);
    }
    void rect(int x0, int y0, int x1, int y1, Rgb c, double a = 1.0) {
        for (int y = y0; y <= y1; ++y)
            for (int x = x0; x <= x1; ++x) blend(x, y, c, a);
    }
    void vline(int x, int y0, int y1, Rgb c, double a = 1.0, int dash = 0) {
        for (int y = y0; y <= y1; ++y)
            if (!dash || (y / dash) % 2 == 0) blend(x, y, c, a);
    }
    void hline(int x0, int x1, int y, Rgb c, double a = 1.0, int dash = 0) {
        for (int x = x0; x <= x1; ++x)
            if (!dash || (x / dash) % 2 == 0) blend(x, y, c, a);
    }
    void line(double x0, double y0, double x1, double y1, Rgb c, int thickness) {
        const int steps = std::max(1, int(std::ceil(std::max(std::fabs(x1 - x0), std::fabs(y1 - y0)))));
        const int half = thickness / 2;
        for (int i = 0; i <= steps; ++i) {
            const double t = double(i) / steps;
            const int x = int(std::lround(x0 + (x1 - x0) * t)), y = int(std::lround(y0 + (y1 - y0) * t));
            rect(x - half, y - half, x - half + thickness - 1, y - half + thickness - 1, c);
        }
    }
    // Text with the engine's built-in font (DejaVu Sans). `anchor`: 0 = x is the left edge, 1 = centre, 2 = right edge; the
    // text is centred on y when `middle`, else y is its top.
    void text(const std::string& s, int x, int y, int size, Rgb c, int anchor = 0, bool middle = false) {
        if (s.empty()) return;
        const auto key = std::make_pair(s, size);
        auto it = cache.find(key);
        if (it == cache.end()) {
            auto bmp = rasterize_text(s, "", float(size));
            it = cache.emplace(key, bmp ? std::move(*bmp) : TextBitmap{}).first;
        }
        const TextBitmap& bmp = it->second;
        const int left = anchor == 0 ? x : anchor == 1 ? x - bmp.width / 2 : x - bmp.width;
        const int top = middle ? y - bmp.height / 2 : y;
        for (int yy = 0; yy < bmp.height; ++yy)
            for (int xx = 0; xx < bmp.width; ++xx)
                blend(left + xx, top + yy, c, bmp.coverage[std::size_t(yy) * std::size_t(bmp.width) + std::size_t(xx)] / 255.0);
    }
    Image img;
    std::map<std::pair<std::string, int>, TextBitmap> cache;
};

Rgb magma(double t) {
    static const Rgb stops[] = {{0, 0, 4}, {40, 11, 84}, {101, 21, 110}, {159, 42, 99}, {212, 72, 66}, {245, 125, 21}, {250, 193, 39}, {252, 255, 164}};
    t = std::clamp(t, 0.0, 1.0) * 7.0;
    const int i = std::min(6, int(t));
    const double f = t - i;
    auto mix = [&](std::uint8_t a, std::uint8_t b) { return std::uint8_t(a + (b - a) * f); };
    return {mix(stops[i].r, stops[i + 1].r), mix(stops[i].g, stops[i + 1].g), mix(stops[i].b, stops[i + 1].b)};
}

std::filesystem::path next_picture_file(const std::string& projectDir) {
    static std::atomic<int> counter{0};
    const std::filesystem::path dir = assets_detail::project_file(projectDir, kScreenshotDir);
    std::error_code ec;
    for (;;) {
        const std::filesystem::path file = dir / std::format("frame_{}_spectrogram.png", ++counter);
        if (!std::filesystem::exists(file, ec)) return file;
    }
}

std::string time_text(double t, double step) { return step < 1.0 ? std::format("{:.2f}s", t) : step < 10.0 ? std::format("{:.1f}s", t) : std::format("{:.0f}s", t); }

Json spectrogram_command(const std::string& projectDir, const Json& args) {
    assets_detail::check_arg_keys("assets.spectrogram", args, "", {"path", "width", "height", "out", "loop", "channels"});
    const std::string rel = tooling_detail::arg_string(args, "path", true);
    if (!tooling_detail::is_audio_file(rel)) throw CommandError("invalid_argument", "'" + rel + "' is not a sound file.", "Sounds are .wav, .ogg, .mp3 or .qoa files.");
    const int width = int(std::clamp<long>(tooling_detail::arg_int(args, "width", 1000), 400, 2400));
    const int height = int(std::clamp<long>(tooling_detail::arg_int(args, "height", 640), 280, 1600));
    const std::string channelsMode = tooling_detail::arg_string(args, "channels", false, "mid");
    if (channelsMode != "mid" && channelsMode != "each")
        throw CommandError("invalid_argument", "'channels' is \"" + channelsMode + "\".", "Use \"mid\" (one waveform) or \"each\" (one waveform per channel).");
    const std::string outRel = tooling_detail::arg_string(args, "out", false);
    std::filesystem::path outFile;
    if (!outRel.empty()) {
        if (to_lower(fs::extension(outRel)) != ".png") throw CommandError("invalid_argument", "'out' must end in .png.", "Example: \"out\": \"assets/src/sound/jump.png\".");
        outFile = assets_detail::project_file(projectDir, outRel);
    }

    auto analysis = analyze_audio_file(projectDir, rel);
    if (!analysis) throw CommandError(analysis.error().message.find("not found") != std::string::npos ? "not_found" : "failed", analysis.error().message, analysis.error().hint);
    DecodedAudio audio;
    {
        tooling_detail::ProjectRootScope root(projectDir);
        auto file = read_audio_file(analysis->file);
        if (!file) throw CommandError("failed", file.error().message, file.error().hint);
        auto decoded = decode_audio(file->bytes, fs::extension(file->path));
        if (!decoded) throw CommandError("failed", rel + ": " + decoded.error().message, decoded.error().hint);
        audio = std::move(*decoded);
    }
    const Metrics m = am::measure(audio);
    const LoudnessCurve curve = loudness_curve(audio);
    const double lufs = analysis->loudness.integratedLufs;
    bool loops = false;
    if (args.contains("loop") && args["loop"].is_boolean()) {
        loops = args["loop"].get<bool>();
    } else {
        const PlayMap plays = scan_project(projectDir);
        if (auto it = plays.find(analysis->path); it != plays.end()) loops = it->second.loops;
    }

    // ---- layout ----
    const Rgb bg{18, 18, 24}, axis{150, 150, 165}, grid{255, 255, 255}, wave{80, 200, 190}, red{255, 70, 70}, seam{255, 60, 200};
    const int left = 62, right = 64, top = 26, bottom = 30, gap = 20;
    const int plotW = width - left - right;
    const int usable = height - top - bottom - 2 * gap;
    const int waveH = usable * 22 / 100, specH = usable * 50 / 100, loudH = usable - waveH - specH;
    const int waveY = top, specY = waveY + waveH + gap, loudY = specY + specH + gap;
    Canvas cv(width, height, bg);

    // ---- title ----
    cv.text(std::format("{}   {:.1f} kHz {}   {:.2f} s   {:.1f} LUFS   TP {} dBTP   clipped {}", analysis->path, m.rate / 1000.0, m.channels == 1 ? "mono" : "stereo", m.seconds,
                        lufs, db_text(m.truePeakDb), m.clippedSamples),
            left, 6, 12, {235, 235, 240});

    // ---- time grid ----
    double timeStep = 0.01;
    for (double s : {0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 30.0, 60.0, 120.0, 300.0}) {
        timeStep = s;
        if (m.seconds / s <= 10.0) break;
    }
    auto time_x = [&](double t) { return left + int(std::lround(t / m.seconds * (plotW - 1))); };
    for (double t = 0; t <= m.seconds + 1e-9; t += timeStep) {
        const int x = time_x(t);
        for (int y0 : {waveY, specY, loudY}) cv.vline(x, y0, y0 + (y0 == waveY ? waveH : y0 == specY ? specH : loudH) - 1, grid, 0.10);
        cv.text(time_text(t, timeStep), x, loudY + loudH + 6, 11, axis, t == 0 ? 0 : 1);
    }

    // ---- waveform ----
    const std::size_t frames = audio.frames(), ch = std::size_t(audio.channels);
    const int lanes = channelsMode == "each" && ch == 2 ? 2 : 1;
    const int laneH = waveH / lanes;
    cv.rect(left, waveY, left + plotW - 1, waveY + waveH - 1, {10, 10, 14});
    std::vector<bool> clippedColumn(std::size_t(plotW), false);
    for (int lane = 0; lane < lanes; ++lane) {
        const int cy = waveY + lane * laneH + laneH / 2;
        const double half = laneH / 2.0 - 1.0;
        cv.hline(left, left + plotW - 1, cy, axis, 0.35);
        for (int c = 0; c < plotW; ++c) {
            const std::size_t a = std::size_t(double(c) * double(frames) / plotW), b = std::max(a + 1, std::min(frames, std::size_t(double(c + 1) * double(frames) / plotW)));
            float lo = 0, hi = 0;
            for (std::size_t i = a; i < b; ++i) {
                float v;
                if (lanes == 2) v = audio.samples[i * ch + std::size_t(lane)];
                else {
                    v = 0;
                    for (std::size_t k = 0; k < ch; ++k) v += audio.samples[i * ch + k];
                    v /= float(ch);
                }
                lo = std::min(lo, v);
                hi = std::max(hi, v);
            }
            for (std::size_t i = a; i < b; ++i)
                for (std::size_t k = 0; k < ch; ++k)
                    if (std::fabs(audio.samples[i * ch + k]) >= am::kFullScale) clippedColumn[std::size_t(c)] = true;
            const int y0 = cy - int(std::lround(std::min(1.0f, hi) * half)), y1 = cy - int(std::lround(std::max(-1.0f, lo) * half));
            cv.vline(left + c, y0, std::max(y0, y1), clippedColumn[std::size_t(c)] ? red : wave);
        }
        const char* tag = lanes == 2 ? (lane == 0 ? "L" : "R") : "";
        cv.text("1.0", left - 6, cy - int(half), 11, axis, 2, true);
        cv.text("0", left - 6, cy, 11, axis, 2, true);
        cv.text("-1.0", left - 6, cy + int(half), 11, axis, 2, true);
        if (*tag) cv.text(tag, left + 4, cy - int(half), 11, axis);
    }
    for (int c = 0; c < plotW; ++c)
        if (clippedColumn[std::size_t(c)]) cv.rect(left + c, waveY, left + c, waveY + 3, red);

    // ---- spectrogram ----
    const am::Spectrogram sp = am::spectrogram(audio, plotW, specH);
    const double ceiling = std::max<double>(sp.maxDb, -30.0), range = 80.0;
    for (int r = 0; r < specH; ++r)
        for (int c = 0; c < plotW; ++c) cv.blend(left + c, specY + r, magma((sp.db[std::size_t(r) * std::size_t(plotW) + std::size_t(c)] - (ceiling - range)) / range), 1.0);
    const double logSpan = std::log(sp.maxHz / sp.minHz);
    for (double f : {20.0, 50.0, 100.0, 200.0, 500.0, 1000.0, 2000.0, 5000.0, 10000.0, 20000.0}) {
        if (f < sp.minHz * 0.999 || f > sp.maxHz * 1.001) continue;
        const int y = specY + int(std::lround((1.0 - std::log(f / sp.minHz) / logSpan) * (specH - 1)));
        cv.hline(left, left + plotW - 1, y, grid, 0.18);
        cv.text(f >= 1000 ? std::format("{:g} kHz", f / 1000.0) : std::format("{:g} Hz", f), left - 6, y, 11, axis, 2, true);
    }
    for (int i = 0; i < specH; ++i) {  // colour bar with its dB scale
        const double t = 1.0 - double(i) / std::max(1, specH - 1);
        cv.rect(left + plotW + 10, specY + i, left + plotW + 18, specY + i, magma(t));
    }
    for (int k = 0; k <= 4; ++k)
        cv.text(std::format("{:.0f} dB", ceiling - range * k / 4.0), left + plotW + 22, specY + int(double(k) / 4.0 * (specH - 1)), 10, axis, 0, true);

    // ---- loudness curve ----
    cv.rect(left, loudY, left + plotW - 1, loudY + loudH - 1, {10, 10, 14});
    auto lufs_y = [&](double v) { return loudY + int(std::lround((1.0 - (std::clamp(v, -60.0, 0.0) + 60.0) / 60.0) * (loudH - 1))); };
    for (int v = 0; v >= -60; v -= 10) {
        cv.hline(left, left + plotW - 1, lufs_y(v), grid, 0.12);
        cv.text(std::to_string(v), left - 6, lufs_y(v), 11, axis, 2, true);
    }
    cv.text("LUFS", left - 6, loudY - 12, 10, axis, 2);
    double momentaryMax = -80.0, momentaryAt = 0.0, shortMax = -80.0;
    for (std::size_t i = 0; i < curve.momentary.size(); ++i) {
        const double t = std::min(m.seconds, (double(i) + 1.0) * curve.hopSeconds);
        if (curve.momentary[i] > momentaryMax) {
            momentaryMax = curve.momentary[i];
            momentaryAt = t;
        }
        shortMax = std::max<double>(shortMax, curve.shortTerm[i]);
        if (i == 0) continue;
        const double t0 = std::min(m.seconds, double(i) * curve.hopSeconds);
        cv.line(time_x(t0), lufs_y(curve.momentary[i - 1]), time_x(t), lufs_y(curve.momentary[i]), {110, 140, 220}, 1);
        cv.line(time_x(t0), lufs_y(curve.shortTerm[i - 1]), time_x(t), lufs_y(curve.shortTerm[i]), {255, 170, 60}, 2);
    }
    if (lufs > kSilentLufs) {
        cv.hline(left, left + plotW - 1, lufs_y(lufs), {255, 255, 255}, 0.8, 6);
        cv.text(std::format("integrated {:.1f}", lufs), left + plotW - 4, lufs_y(lufs) - 13, 11, {255, 255, 255}, 2);
    }
    if (momentaryMax > -80.0) {
        cv.rect(time_x(momentaryAt) - 3, lufs_y(momentaryMax) - 3, time_x(momentaryAt) + 3, lufs_y(momentaryMax) + 3, {255, 230, 90});
        cv.text(std::format("M max {:.1f}", momentaryMax), time_x(momentaryAt) + (momentaryAt > m.seconds * 0.8 ? -8 : 8), lufs_y(momentaryMax) - 14, 11, {255, 230, 90}, momentaryAt > m.seconds * 0.8 ? 2 : 0);
    }
    cv.text("momentary", left + 6, loudY + 4, 11, {110, 140, 220});
    cv.text("short-term", left + 76, loudY + 4, 11, {255, 170, 60});

    // ---- loop seam ----
    if (loops) {
        for (int x : {left, left + plotW - 1})
            for (int y0 : {waveY, specY, loudY}) cv.vline(x, y0, y0 + (y0 == waveY ? waveH : y0 == specY ? specH : loudH) - 1, seam, 0.9, 4);
        cv.text(std::format("loop seam: jump {:.1f}x, slope {:.1f}x", m.seamJumpRatio, m.seamSlopeRatio), left + plotW - 4, 6, 12, seam, 2);
    }
    if (m.clippedSamples > 0) cv.text("red = clipped", left + 330 > width ? left : left + plotW / 2, waveY + waveH - 14, 11, red, 1);

    // ---- write ----
    const std::vector<std::uint8_t> png = encode_png(cv.img);
    const bool keep = !outRel.empty();
    const std::filesystem::path file = keep ? outFile : next_picture_file(projectDir);
    std::string err;
    if (!tooling_detail::write_file(file, std::string_view(reinterpret_cast<const char*>(png.data()), png.size()), &err)) throw CommandError("failed", err);

    Json result = Json::object({{"path", analysis->path},
                                {"seconds", num(m.seconds, 3)},
                                {"sampleRate", m.rate},
                                {"channels", m.channels},
                                {"integratedLufs", num(lufs)},
                                {"truePeakDb", num(m.truePeakDb)},
                                {"samplePeakDb", num(m.samplePeakDb)},
                                {"momentaryMaxLufs", num(momentaryMax)},
                                {"shortTermMaxLufs", num(shortMax)},
                                {"clippedSamples", m.clippedSamples},
                                {"fullScaleSamples", m.fullScaleSamples},
                                {"loops", loops},
                                {"cachedAnalysis", analysis->cached},
                                {"picture", Json::object({{"width", width}, {"height", height}, {"spectrogramDbRange", Json::array({num(ceiling - range, 0), num(ceiling, 0)})}})}});
    if (m.dominantBand >= 0)
        result["dominantBand"] = Json::object({{"band", am::kBandNames[m.dominantBand]}, {"centreHz", am::kBandCentreHz[m.dominantBand]}, {"levelDb", num(m.bandDb[std::size_t(m.dominantBand)], 1)}});
    if (loops) result["loopSeam"] = Json::object({{"jumpRatio", num(m.seamJumpRatio)}, {"slopeRatio", num(m.seamSlopeRatio)}, {"jumpDbfs", num(m.seamJump > 1e-10 ? 20.0 * std::log10(m.seamJump) : -200.0)}});
    if (keep) result["out"] = outRel;
    Json steps = Json::array({"Read the picture: top = waveform (red columns are clipped samples), middle = spectrogram (log frequency, brighter = louder, scale on the right), bottom = loudness "
                              "(blue momentary, orange short-term, dashed white integrated, yellow square the loudest momentary value)."});
    if (m.clippedSamples > 0 || m.truePeakDb > -1.0) steps.push_back("It clips or peaks above -1 dBTP: assets.check_mix says how to fix it.");
    steps.push_back("assets.check_mix measures every sound of the project together (loudness per bus, masking, clicks, loop seams).");
    result["nextSteps"] = steps;
    Json image = Json::object({{"path", file.string()}, {"mimeType", "image/png"}});
    if (!keep) image["temporary"] = true;
    result["$image"] = image;
    return result;
}

}  // namespace

Json audio_mix::spectrogram_picture(const std::string& projectDir, const Json& args) { return spectrogram_command(projectDir, args); }

void register_audio_mix_commands(CommandRegistry& registry, const std::string& projectDir) {
    {
        CommandInfo info;
        info.name = "assets.spectrogram";
        info.category = "assets";
        info.readOnly = true;
        info.summary = "See a sound: a picture of its waveform, spectrogram (log frequency) and loudness curve, with the clipped samples and the loop seam marked.";
        info.description =
            "Decodes the sound at `path` (.wav, .ogg, .mp3, .qoa) and returns one picture, like assets.preview_sheet does for a sprite sheet: the waveform on top (mid, or each channel; red columns are samples at full "
            "scale), a spectrogram in the middle (short-time Fourier transform of the mid channel, 20 Hz to 20 kHz on a logarithmic axis, brighter = louder, with a dB scale) and the loudness curve at the bottom "
            "(momentary 400 ms in blue, short-term 3 s in orange, the integrated value dashed, the loudest momentary value marked). When the sound is played looping (an AudioSource with loop, SceneSettings.music, "
            "audio.music, or audio.play with loop: true; or `loop: true` here) magenta dashed lines mark the loop seam and the title gives its jump and slope. Axes are labelled with the engine's built-in font. "
            "The result carries the numbers: integratedLufs, truePeakDb (4x oversampled), samplePeakDb, momentaryMaxLufs, shortTermMaxLufs, seconds, clippedSamples (samples flattened at full scale), "
            "dominantBand (the loudest octave band) and loopSeam. It reuses the sound's fresh `analysis` record for the integrated loudness and writes nothing unless `out` is given. "
            "The picture is a temporary screenshot in .factoria/screenshots; with `out` the PNG is kept at that project path. Example: {\"path\":\"assets/music/theme.ogg\",\"width\":1200}";
        auto integer = [](const char* what, int minimum, int maximum, int def) {
            return Json::object({{"type", "integer"}, {"minimum", minimum}, {"maximum", maximum}, {"default", def}, {"description", what}});
        };
        info.inputSchema = Json::object(
            {{"type", "object"},
             {"required", Json::array({"path"})},
             {"additionalProperties", false},
             {"properties",
              Json::object({{"path", Json::object({{"type", "string"}, {"description", "Project-relative sound file, e.g. assets/sfx/jump.wav."}})},
                            {"width", integer("Width of the picture in pixels.", 400, 2400, 1000)},
                            {"height", integer("Height of the picture in pixels.", 280, 1600, 640)},
                            {"out", Json::object({{"type", "string"}, {"description", "Also keep the PNG at this project-relative path (must end in .png). Without it the picture is a temporary screenshot."}})},
                            {"loop", Json::object({{"type", "boolean"}, {"description", "Mark the loop seam. Default: whether the project plays the sound looping (scenes, prefabs and scripts)."}})},
                            {"channels", Json::object({{"type", "string"}, {"enum", Json::array({"mid", "each"})}, {"default", "mid"}, {"description", "\"mid\": one waveform of the average of the channels; \"each\": one lane per channel of a stereo sound."}})}})}});
        registry.add(info, [projectDir](const Json& args) { return spectrogram_command(projectDir, args.is_null() ? Json::object() : args); });
    }
    {
        CommandInfo info;
        info.name = "assets.check_mix";
        info.category = "assets";
        info.readOnly = true;
        info.summary = "Measure every sound of the project together: loudness per bus, music masking effects, clicks, loop seams, clipping, true peak; each finding has a fix.";
        info.description =
            "Listens for what a game's mix gets wrong. Measures the sounds of the project (the set assets.analyze_audio uses without `path`: everything under assets/ and every sound a scene or prefab names), or `paths`, "
            "as they play (with the gain import \"normalize\" applies). Each finding has `sound`, `rule`, `value`, `threshold`, `unit`, `verdict` (ok, warn, fail), a `message` and a `hint` that names the fix; ok findings are "
            "left out unless `includeOk` is true. Rules: loudness_target / loudness_spread (loudness of each sound against the target of its bus, or, with no target, against the median of the sounds of its bus: warn "
            "beyond 6 LU, fail beyond 12; the bus comes from AudioSource (sfx), SceneSettings.music and audio.music (music) and audio.play(\"path\", {bus}) in scripts, with the parents of factoria.json audio.buses; "
            "a sound no scene or script plays with a literal path is on the \"unknown bus\"); music_masking (the octave bands where an effect has its main energy, against the loudest music there: warn when the music "
            "is as loud or louder, fail 6 dB louder); click_start and click_end (the first/last sample or a jump of the first/last step: warn above -40 dBFS, fail above -26); loop_seam_jump and loop_seam_slope (for sounds "
            "played looping: the step and the change of slope from the last sample to the first, as multiples of the sound's usual step and curvature); clipping (samples flattened at full scale, counted); true_peak "
            "(4x oversampled, as played: warn above -1 dBTP, fail above 0). Loudness targets: the `targets` argument ({\"music\": -16, \"sfx\": {\"lufs\": -14, \"toleranceLu\": 2}, \"default\": -16}), else style.audio.loudnessLufs and "
            "toleranceLu in assets.json, else the spread rule. Returns {verdict, summary, findings, sounds (one row of numbers per sound), targets, nextSteps}. Deterministic and read-only: it writes nothing (run "
            "assets.analyze_audio first to keep the loudness records, so later runs do not measure again). Example: {\"targets\":{\"music\":-16,\"sfx\":-14}}";
        info.inputSchema = Json::object(
            {{"type", "object"},
             {"additionalProperties", false},
             {"properties",
              Json::object({{"paths", Json::object({{"type", "array"}, {"items", Json::object({{"type", "string"}})}, {"description", "Project-relative sound files to check. Omit for every sound of the project."}})},
                            {"targets", Json::object({{"type", "object"},
                                                      {"description", "Loudness targets in LUFS per bus: {\"music\": -16, \"sfx\": {\"lufs\": -14, \"toleranceLu\": 2}, \"default\": -16}. A number uses a tolerance of 3 LU. Omit to use style.audio in assets.json."}})},
                            {"includeOk", Json::object({{"type", "boolean"}, {"default", false}, {"description", "Also list the checks that passed."}})}})}});
        registry.add(info, [projectDir](const Json& args) { return check_mix(projectDir, args.is_null() ? Json::object() : args); });
    }
}

}  // namespace fa
