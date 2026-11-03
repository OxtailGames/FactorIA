// The offline song renderer (fa/audio/song_preview.h).
#include "fa/audio/song_preview.h"

#include <algorithm>
#include <cmath>
#include <format>
#include <memory>
#include <unordered_map>

#include "fa/audio/sfx.h"
#include "fa/audio/song_instruments.h"
#include "fa/audio/song_theory.h"
#include "fa/core/strings.h"
#include "sfx_math.h"

namespace fa {

namespace {

constexpr std::size_t kMaxCacheBytes = 256u * 1024u * 1024u;
constexpr double kReferenceDb = -12.0;  // an external instrument's C4 note (0.5 s) peaks here at velocity 100

struct Voice {
    SfxPatch patch;
    double calibration = 1.0;     // linear gain that makes the instrument's reference note peak at kReferenceDb
    bool drum = false;
    std::string label;
};

std::vector<float> resample(const std::vector<float>& in, int from, int to) {
    if (from == to || in.empty()) return in;
    const double ratio = double(from) / double(to);
    const std::size_t n = std::size_t(double(in.size()) / ratio);
    std::vector<float> out(n);
    for (std::size_t i = 0; i < n; ++i) {
        const double pos = double(i) * ratio;
        const std::size_t a = std::size_t(pos);
        const double f = pos - double(a);
        const float x = in[a];
        const float y = a + 1 < in.size() ? in[a + 1] : 0.0f;
        out[i] = float(double(x) + (double(y) - double(x)) * f);
    }
    return out;
}

struct Renderer {
    const SongDoc& song;
    const SongTimeline& timeline;
    SongRenderOptions opt;
    SongRender result;

    std::map<std::string, std::unique_ptr<Voice>> voices;  // by key ("pluck", "kit:kick", a path)
    struct Cached {
        std::vector<float> samples;
    };
    std::unordered_map<std::string, std::shared_ptr<Cached>> cache;
    std::size_t cacheBytes = 0;

    Result<Voice*> voice(const SongTrack& track, const std::string& what, bool drumLane) {
        auto found = voices.find(what);
        if (found != voices.end()) return found->second.get();
        auto v = std::make_unique<Voice>();
        v->drum = drumLane;
        v->label = what;
        std::vector<SfxIssue> issues;
        Result<SfxPatch> patch = make_error("", "");
        const bool isFile = what.size() > 9 && what.compare(what.size() - 9, 9, ".sfx.json") == 0;
        if (isFile) {
            patch = load_sfx(what, &issues);
            result.inputs.push_back(what);
        } else if (auto j = song_instrument_patch(what)) {
            patch = parse_sfx(*j, what, &issues);
        } else if (auto j2 = sfx_preset_patch(what)) {
            patch = parse_sfx(*j2, what, &issues);
        } else {
            return make_error("the track `" + track.name + "` uses the instrument `" + what + "`, which is not an instrument", "Use a built-in instrument, a preset or an .sfx.json file.");
        }
        if (!patch) return make_error("the instrument of the track `" + track.name + "`: " + patch.error().message, patch.error().hint);
        v->patch = std::move(*patch);
        const bool builtin = !isFile && song_instrument_patch(what).has_value();
        if (!builtin) {
            // Level an outside patch like the built-in ones: its reference note peaks at kReferenceDb at velocity 100.
            SfxRenderOptions ro;
            ro.normalize = SfxNormalize{SfxNormalizeMode::None, 0.0, 0.0};
            if (!drumLane) { ro.length = 0.5; ro.freqHz = song_midi_hz(60); }
            auto r = render_sfx(v->patch, ro);
            if (!r) return make_error("the instrument `" + what + "`: " + r.error().message, r.error().hint);
            if (r->peakDb > -90.0) v->calibration = sfx_math::db_to_gain(kReferenceDb - r->peakDb);
        }
        Voice* raw = v.get();
        voices[what] = std::move(v);
        return raw;
    }

    // One note of a voice at velocity 1.0 (sample rate = the render's), cached.
    Result<std::shared_ptr<Cached>> note(Voice& v, int pitch, double gateSeconds, const std::map<std::string, double>& macros) {
        const int gateMs = v.drum ? 0 : std::max(10, int(std::ceil(gateSeconds * 100.0)) * 10);
        std::string key = v.label + "|" + std::to_string(pitch) + "|" + std::to_string(gateMs);
        for (const auto& m : macros) key += "|" + m.first + "=" + std::to_string(int(std::lround(m.second * 20.0)));
        if (auto it = cache.find(key); it != cache.end()) return it->second;
        SfxRenderOptions ro;
        ro.seed = opt.seed;
        ro.normalize = SfxNormalize{SfxNormalizeMode::None, 0.0, 0.0};
        ro.macros = macros;
        if (!v.drum) {
            ro.freqHz = song_midi_hz(pitch);
            ro.length = std::min(double(gateMs) / 1000.0, kSfxMaxSeconds - 2.0);
        }
        // An outside patch with its own normalization is levelled by `calibration` instead.
        auto r = render_sfx(v.patch, ro);
        if (!r) return make_error("the instrument `" + v.label + "` at " + song_pitch_name(pitch) + ": " + r.error().message, r.error().hint);
        auto c = std::make_shared<Cached>();
        c->samples = resample(r->samples, r->sampleRate, opt.sampleRate);
        if (v.calibration != 1.0)
            for (float& s : c->samples) s = float(double(s) * v.calibration);
        if (cacheBytes + c->samples.size() * sizeof(float) > kMaxCacheBytes) { cache.clear(); cacheBytes = 0; }
        cacheBytes += c->samples.size() * sizeof(float);
        cache[key] = c;
        ++result.renders;
        return c;
    }
};

const SongAutomation* find_lane(const std::vector<SongAutomation>& lanes, const std::string& param) {
    for (const SongAutomation& a : lanes)
        if (a.param == param) return &a;
    return nullptr;
}

bool contains(const std::vector<std::string>& v, const std::string& s) { return std::find(v.begin(), v.end(), s) != v.end(); }

// A state-variable low-pass (trapezoidal), cutoff changed every block.
struct Lowpass {
    double ic1 = 0, ic2 = 0;
    double a1 = 0, a2 = 0, a3 = 0, k = 1.4142135623730951;
    void set(double cutoff, int rate) {
        const double c = std::clamp(cutoff, 40.0, double(rate) * 0.45);
        const double g = sfx_math::tan_pi(c / double(rate));
        a1 = 1.0 / (1.0 + g * (g + k));
        a2 = g * a1;
        a3 = g * a2;
    }
    double run(double v0) {
        const double v3 = v0 - ic2;
        const double v1 = a1 * ic1 + a2 * v3;
        const double v2 = ic2 + a2 * ic1 + a3 * v3;
        ic1 = 2.0 * v1 - ic1;
        ic2 = 2.0 * v2 - ic2;
        return v2;
    }
};

}  // namespace

Result<SongRender> render_song(const SongDoc& song, const SongTimeline& timeline, const SongRenderOptions& options) {
    if (options.sampleRate < 8000 || options.sampleRate > 96000) return make_error("sampleRate must be 8000 to 96000, got " + std::to_string(options.sampleRate), "44100 is the default.");
    if (options.fromBar < 1) return make_error("fromBar must be 1 or more", "Bars are counted from 1.");
    if (options.fromBar > timeline.bars && timeline.bars > 0)
        return make_error(std::format("fromBar {} is past the end of the song, which has {} bars", options.fromBar, timeline.bars), "Use a bar from 1 to " + std::to_string(timeline.bars) + ".");
    for (const std::string& n : options.solo)
        if (!song.find_track(n)) { std::vector<std::string> names; for (const SongTrack& t : song.tracks) names.push_back(t.name); return make_error("no track named `" + n + "` to solo", did_you_mean(n, names)); }
    for (const std::string& n : options.mute)
        if (!song.find_track(n)) { std::vector<std::string> names; for (const SongTrack& t : song.tracks) names.push_back(t.name); return make_error("no track named `" + n + "` to mute", did_you_mean(n, names)); }

    Renderer r{song, timeline, options};
    const int sr = options.sampleRate;
    const std::int64_t barTicks = song.meter.barTicks();
    const std::int64_t fromTick = std::int64_t(options.fromBar - 1) * barTicks;
    std::int64_t toTick = timeline.totalTicks;
    if (options.bars > 0) toTick = std::min(toTick, fromTick + std::int64_t(options.bars) * barTicks);
    if (toTick <= fromTick) return make_error("the song has nothing to render", "Add notes to a section.");
    const double musicSeconds = song.ticks_to_seconds(toTick - fromTick);
    if (musicSeconds > options.maxSeconds)
        return make_error(std::format("the song lasts {:.1f} seconds, more than the {:.0f} a preview renders", musicSeconds, options.maxSeconds),
                          "Render a part with fromBar and bars, or raise maxSeconds (memory grows with the length).");
    const double secondsPerTick = 60.0 / (song.tempo * double(kSongPpq));
    const std::size_t musicFrames = std::size_t(std::ceil(musicSeconds * double(sr)));
    const std::size_t frames = musicFrames + std::size_t(options.tailSeconds * double(sr));

    std::vector<float> left(frames, 0.0f), right(frames, 0.0f);
    std::vector<float> mono(frames, 0.0f);
    const double fromBeat = double(fromTick) / double(kSongPpq);
    const double beatsPerSecond = song.tempo / 60.0;
    constexpr std::size_t kBlock = 64;

    for (std::size_t ti = 0; ti < song.tracks.size(); ++ti) {
        const SongTrack& track = song.tracks[ti];
        if (!options.solo.empty() && !contains(options.solo, track.name)) continue;
        if (contains(options.mute, track.name)) continue;
        std::fill(mono.begin(), mono.end(), 0.0f);
        bool any = false;
        std::string macroParam;
        for (const SongAutomation& a : track.automation)
            if (a.param.rfind("macro.", 0) == 0) macroParam = a.param;
        for (const SongNote& n : timeline.notes) {
            if (n.track != int(ti)) continue;
            if (n.tick < fromTick || n.tick >= toTick) continue;
            std::string what;
            bool drumLane = false;
            if (track.drums) {
                auto k = track.kit.find(n.drum);
                what = k != track.kit.end() ? k->second : "kit:" + n.drum;
                drumLane = true;
            } else {
                what = track.instrument;
            }
            auto v = r.voice(track, what, drumLane);
            if (!v) return v.error();
            const double beat = double(n.tick) / double(kSongPpq);
            std::map<std::string, double> macros;
            for (const SongAutomation& a : track.automation)
                if (a.param.rfind("macro.", 0) == 0) macros[a.param.substr(6)] = a.value_at(beat, 0.0);
            const int pitch = track.drums ? 60 : std::clamp(n.pitch, 0, 127);
            const double gate = double(n.gateTicks()) * secondsPerTick;
            auto c = r.note(**v, pitch, gate, macros);
            if (!c) return c.error();
            const std::size_t start = std::size_t(double(n.tick - fromTick) * secondsPerTick * double(sr) + 0.5);
            const double g = double(n.velocity) / 100.0;
            const std::vector<float>& s = (*c)->samples;
            const std::size_t len = std::min(s.size(), start < frames ? frames - start : 0);
            for (std::size_t i = 0; i < len; ++i) mono[start + i] += float(double(s[i]) * g);
            any = true;
            ++r.result.notes;
        }
        if (!any) continue;
        // The track chain: filter lane, volume lane, pan lane, into the stereo mix.
        const SongAutomation* filterLane = find_lane(track.automation, "filter");
        const SongAutomation* volumeLane = find_lane(track.automation, "volume");
        const SongAutomation* panLane = find_lane(track.automation, "pan");
        Lowpass lp;
        auto beat_at = [&](std::size_t frame) { return fromBeat + double(frame) / double(sr) * beatsPerSecond; };
        for (std::size_t b = 0; b < frames; b += kBlock) {
            const std::size_t e = std::min(frames, b + kBlock);
            if (filterLane) lp.set(filterLane->value_at(beat_at(b), 20000.0), sr);
            const double vol0 = track.volume * (volumeLane ? volumeLane->value_at(beat_at(b), 1.0) : 1.0);
            const double vol1 = track.volume * (volumeLane ? volumeLane->value_at(beat_at(e), 1.0) : 1.0);
            const double pan0 = std::clamp(panLane ? panLane->value_at(beat_at(b), track.pan) : track.pan, -1.0, 1.0);
            const double pan1 = std::clamp(panLane ? panLane->value_at(beat_at(e), track.pan) : track.pan, -1.0, 1.0);
            for (std::size_t i = b; i < e; ++i) {
                const double f = double(i - b) / double(e - b);
                const double vol = vol0 + (vol1 - vol0) * f;
                const double pan = pan0 + (pan1 - pan0) * f;
                double x = double(mono[i]);
                if (filterLane) x = lp.run(x);
                x *= vol;
                left[i] += float(x * std::sqrt(0.5 * (1.0 - pan)) * 1.4142135623730951);
                right[i] += float(x * std::sqrt(0.5 * (1.0 + pan)) * 1.4142135623730951);
            }
        }
    }

    // Master: volume, lanes, filter.
    const SongAutomation* mvol = find_lane(song.automation, "volume");
    const SongAutomation* mfilter = find_lane(song.automation, "filter");
    Lowpass lpl, lpr;
    for (std::size_t b = 0; b < frames; b += kBlock) {
        const std::size_t e = std::min(frames, b + kBlock);
        const double beat0 = fromBeat + double(b) / double(sr) * beatsPerSecond;
        const double beat1 = fromBeat + double(e) / double(sr) * beatsPerSecond;
        if (mfilter) { const double c = mfilter->value_at(beat0, 20000.0); lpl.set(c, sr); lpr.set(c, sr); }
        const double v0 = song.volume * (mvol ? mvol->value_at(beat0, 1.0) : 1.0);
        const double v1 = song.volume * (mvol ? mvol->value_at(beat1, 1.0) : 1.0);
        for (std::size_t i = b; i < e; ++i) {
            const double vol = v0 + (v1 - v0) * (double(i - b) / double(e - b));
            double l = double(left[i]), rr = double(right[i]);
            if (mfilter) { l = lpl.run(l); rr = lpr.run(rr); }
            left[i] = float(l * vol);
            right[i] = float(rr * vol);
        }
    }

    // A fade over the last 20 ms so the file never ends on a click.
    const std::size_t fade = std::min<std::size_t>(frames, std::size_t(sr / 50));
    for (std::size_t i = 0; i < fade; ++i) {
        const double g = double(i) / double(fade);
        left[frames - 1 - i] = float(double(left[frames - 1 - i]) * g);
        right[frames - 1 - i] = float(double(right[frames - 1 - i]) * g);
    }

    r.result.clip.sampleRate = sr;
    r.result.clip.channels = 2;
    r.result.clip.samples.resize(frames * 2);
    std::vector<std::vector<double>> ch(2, std::vector<double>(frames));
    for (std::size_t i = 0; i < frames; ++i) {
        r.result.clip.samples[2 * i] = left[i];
        r.result.clip.samples[2 * i + 1] = right[i];
        ch[0][i] = double(left[i]);
        ch[1][i] = double(right[i]);
    }
    double lufs = -70.0, peak = 0.0;
    sfx_measure_loudness(ch, sr, lufs, peak);
    r.result.clip.lufs = lufs;
    r.result.clip.peakDb = peak > 0.0 ? sfx_math::gain_to_db(peak) : -200.0;
    r.result.clip.inputs = r.result.inputs;
    r.result.seconds = musicSeconds;
    return std::move(r.result);
}

}  // namespace fa
