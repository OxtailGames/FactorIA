// The song renderer (fa/audio/song_preview.h): instruments, the track chains, the buses and the master.
#include "fa/audio/song_preview.h"

#include <algorithm>
#include <cmath>
#include <deque>
#include <format>
#include <map>
#include <memory>
#include <unordered_map>

#include "fa/audio/sfx.h"
#include "fa/audio/song_instruments.h"
#include "fa/audio/song_theory.h"
#include "fa/audio/soundfont.h"
#include "fa/core/strings.h"
#include "sfx_math.h"

namespace fa {

namespace {

constexpr std::size_t kMaxCacheBytes = 256u * 1024u * 1024u;
constexpr double kReferenceDb = -12.0;     // a calibrated instrument's C4 note at velocity 100 peaks here
constexpr double kVelocityCurve = 1.25;    // amplitude = (velocity / 100) ^ kVelocityCurve
constexpr double kCutFadeSeconds = 0.008;  // a note cut by a newer one (voice limit, same key, hat choke) fades over this
constexpr double kLimiterLookahead = 0.005;
constexpr double kMaxNormalizeBoostDb = 18.0;
constexpr double kMaxEffectTail = 8.0;
constexpr std::size_t kBlock = 64;
constexpr double kSqrt2 = 1.4142135623730951;

// General MIDI percussion keys of the drum lanes, for a SoundFont's kit (bank 128).
int gm_drum_key(const std::string& lane) {
    static const std::map<std::string, int> keys = {{"kick", 36}, {"snare", 38}, {"clap", 39}, {"rim", 37}, {"hat", 42}, {"openhat", 46}, {"hat_pedal", 44}, {"shaker", 70},
                                                    {"tambourine", 54}, {"tom_low", 45}, {"tom_mid", 47}, {"tom_high", 50}, {"ride", 51}, {"crash", 49}, {"cowbell", 56}};
    auto it = keys.find(lane);
    return it != keys.end() ? it->second : 38;
}

bool is_hat_lane(const std::string& lane) { return lane == "hat" || lane == "hat_pedal" || lane == "openhat"; }

struct Voice {
    SfxPatch patch;
    double calibration = 1.0;     // linear gain that makes the instrument's reference note peak at kReferenceDb
    bool drum = false;
    bool velocityTone = true;     // a harder note is brighter (the brightness macro follows the velocity)
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

const SongAutomation* find_lane(const std::vector<SongAutomation>& lanes, const std::string& param) {
    for (const SongAutomation& a : lanes)
        if (a.param == param) return &a;
    return nullptr;
}

bool contains(const std::vector<std::string>& v, const std::string& s) { return std::find(v.begin(), v.end(), s) != v.end(); }

// A state-variable low-pass (trapezoidal), cutoff changed every block.
struct Lowpass {
    double ic1 = 0, ic2 = 0;
    double a1 = 0, a2 = 0, a3 = 0, k = kSqrt2;
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

// The gain each side gets: constant-power placement of a mono signal, balance of a stereo one.
void pan_gains(double pan, bool mono, double& gl, double& gr) {
    pan = std::clamp(pan, -1.0, 1.0);
    if (mono) {
        gl = std::sqrt(0.5 * (1.0 - pan)) * kSqrt2;
        gr = std::sqrt(0.5 * (1.0 + pan)) * kSqrt2;
    } else {
        gl = pan > 0.0 ? sfx_math::cos_turns(pan * 0.25) : 1.0;
        gr = pan < 0.0 ? sfx_math::cos_turns(-pan * 0.25) : 1.0;
    }
}

// Seconds the tail of an effect step rings after its input ends.
double effect_tail(const AudioStep& st) {
    if (st.params.value("enabled", true) == false) return 0.0;
    if (st.type == "reverb") {
        const double decay = st.params.value("decay", 1.5);
        return std::min(kMaxEffectTail, st.params.value("tail", std::min(decay, 5.0)) + st.params.value("preDelay", 0.0));
    }
    if (st.type == "delay") {
        const double time = st.params.value("time", 0.25);
        return std::min(kMaxEffectTail, st.params.value("tail", std::min(kMaxEffectTail, time * 8.0)));
    }
    return 0.0;
}

double chain_tail(const std::vector<AudioStep>& steps) {
    double t = 0.0;
    for (const AudioStep& s : steps) t += effect_tail(s);
    return std::min(t, kMaxEffectTail);
}

// Runs a chain of effects over the channels in place. On a bus a reverb or a delay returns only the effect (the dry sound is the track).
void run_chain(std::vector<std::vector<double>>& ch, int rate, const std::vector<AudioStep>& steps, bool wetOnly) {
    for (const AudioStep& st : steps) {
        if (wetOnly && (st.type == "reverb" || st.type == "delay") && st.params.value("enabled", true) != false) {
            const std::vector<std::vector<double>> dry = ch;
            audio_apply_effect(ch, rate, st);
            for (std::size_t c = 0; c < ch.size(); ++c)
                for (std::size_t i = 0; i < ch[c].size(); ++i) ch[c][i] -= dry[c][i];
        } else {
            audio_apply_effect(ch, rate, st);
        }
    }
}

double measure_peak_db(const std::vector<std::vector<double>>& ch) {
    double p = 0.0;
    for (const auto& c : ch)
        for (double v : c) p = std::max(p, std::abs(v));
    return p > 0.0 ? sfx_math::gain_to_db(p) : -200.0;
}

// A lookahead peak limiter on a stereo pair, linked: no sample ends above `ceiling` (linear). The gain a sample needs is the ceiling
// over its peak; the gain looks `lookahead` frames ahead (a sliding minimum), recovers with a one-pole release, and is averaged over the
// lookahead so it glides down before the peak arrives instead of clicking. The average of values that are all at most the gain the
// sample needs, over the window the sample sits in, is itself at most that gain, so the ceiling holds by construction; a final clamp
// only absorbs rounding. Returns the deepest gain reduction in dB (0 = it never acted).
double run_limiter(std::vector<double>& l, std::vector<double>& r, double ceiling, double releaseSeconds, int rate) {
    const std::size_t n = l.size();
    if (n == 0) return 0.0;
    const std::size_t look = std::max<std::size_t>(1, std::size_t(kLimiterLookahead * double(rate)));
    std::vector<double> need(n);
    bool acts = false;
    for (std::size_t i = 0; i < n; ++i) {
        const double p = std::max(std::abs(l[i]), std::abs(r[i]));
        need[i] = p > ceiling ? ceiling / p : 1.0;
        if (p > ceiling) acts = true;
    }
    if (!acts) return 0.0;
    const double alpha = 1.0 - 1.0 / (1.0 + releaseSeconds * double(rate));  // share of the way back to 1 per sample
    std::deque<std::size_t> window;     // indices whose `need` increases: the front is the sliding minimum
    std::vector<double> ring(look + 1, 1.0);
    double sum = double(look + 1), released = 1.0, deepest = 1.0;
    std::size_t pushed = 0;
    for (std::size_t j = 0; j < n; ++j) {
        while (pushed < n && pushed <= j + look) {
            while (!window.empty() && need[window.back()] >= need[pushed]) window.pop_back();
            window.push_back(pushed);
            ++pushed;
        }
        while (window.front() < j) window.pop_front();
        const double env = need[window.front()];
        released = std::min(env, released + (1.0 - released) * alpha);
        double& slot = ring[j % (look + 1)];
        sum += released - slot;
        slot = released;
        const double gain = std::min(1.0, sum / double(look + 1));
        deepest = std::min(deepest, gain);
        l[j] = std::clamp(l[j] * gain, -ceiling, ceiling);
        r[j] = std::clamp(r[j] * gain, -ceiling, ceiling);
    }
    return deepest < 1.0 ? -sfx_math::gain_to_db(deepest) : 0.0;
}

// One note of a track on its way to the buffer.
struct NoteEv {
    std::int64_t tick = 0;
    std::int64_t endTick = 0;         // tick the gate ends (the note is held until then)
    std::size_t start = 0;            // frame the note starts at
    std::size_t gate = 0;             // frames held
    std::size_t cut = SIZE_MAX;       // frame a newer note cuts this one at (SIZE_MAX: not cut)
    int pitch = 60;
    int velocity = 90;
    const SongNote* note = nullptr;
    std::size_t end() const { return start + gate; }
};

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

    struct Font {
        Soundfont font;
    };
    std::map<std::string, std::unique_ptr<Font>> fonts;
    std::map<std::string, double> fontCalibration;  // by "<path>#<preset index>"

    void input(const std::string& path) {
        if (std::find(result.inputs.begin(), result.inputs.end(), path) == result.inputs.end()) result.inputs.push_back(path);
    }

    Result<Voice*> voice(const SongTrack& track, const std::string& what, bool drumLane) {
        auto found = voices.find(what);
        if (found != voices.end()) return found->second.get();
        auto v = std::make_unique<Voice>();
        v->drum = drumLane;
        v->label = what;
        std::vector<SfxIssue> issues;
        Result<SfxPatch> patch = make_error("", "");
        const bool isFile = what.size() > 9 && what.compare(what.size() - 9, 9, ".sfx.json") == 0;
        const bool builtin = !isFile && song_instrument_patch(what).has_value();
        if (isFile) {
            patch = load_sfx(what, &issues);
            input(what);
        } else if (auto j = song_instrument_patch(what)) {
            patch = parse_sfx(*j, what, &issues);
        } else if (auto j2 = sfx_preset_patch(what)) {
            patch = parse_sfx(*j2, what, &issues);
        } else {
            return make_error("the track `" + track.name + "` uses the instrument `" + what + "`, which is not an instrument",
                              "Use a built-in instrument (music.instrument lists them), a preset, an .sfx.json file or a SoundFont.");
        }
        if (!patch) return make_error("the instrument of the track `" + track.name + "`: " + patch.error().message, patch.error().hint);
        v->patch = std::move(*patch);
        if (drumLane) v->velocityTone = false;
        if (builtin) {
            for (const SongInstrumentInfo& i : song_instruments())
                if (i.name == what && i.family == "chiptune") v->velocityTone = false;
        } else {
            // Level an outside patch like the built-in ones: its reference note peaks at kReferenceDb at velocity 100.
            SfxRenderOptions ro;
            ro.normalize = SfxNormalize{SfxNormalizeMode::None, 0.0, 0.0};
            if (!drumLane) { ro.length = 0.5; ro.freqHz = song_midi_hz(60); }
            auto rendered = render_sfx(v->patch, ro);
            if (!rendered) return make_error("the instrument `" + what + "`: " + rendered.error().message, rendered.error().hint);
            if (rendered->peakDb > -90.0) v->calibration = sfx_math::db_to_gain(kReferenceDb - rendered->peakDb);
        }
        Voice* raw = v.get();
        voices[what] = std::move(v);
        return raw;
    }

    // One note of a voice at velocity 100 (sample rate = the render's), cached.
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
        auto rendered = render_sfx(v.patch, ro);
        if (!rendered) return make_error("the instrument `" + v.label + "` at " + song_pitch_name(pitch) + ": " + rendered.error().message, rendered.error().hint);
        auto c = std::make_shared<Cached>();
        c->samples = resample(rendered->samples, rendered->sampleRate, opt.sampleRate);
        if (v.calibration != 1.0)
            for (float& s : c->samples) s = float(double(s) * v.calibration);
        if (cacheBytes + c->samples.size() * sizeof(float) > kMaxCacheBytes) { cache.clear(); cacheBytes = 0; }
        cacheBytes += c->samples.size() * sizeof(float);
        cache[key] = c;
        ++result.renders;
        return c;
    }

    // The SoundFont of a track and the index of its preset; the errors name the track and say how to fix them.
    Result<std::pair<const Soundfont*, int>> soundfont(const SongTrack& track) {
        const SongSoundfont& sf = track.soundfont;
        auto found = fonts.find(sf.path);
        if (found == fonts.end()) {
            input(sf.path);
            auto loaded = Soundfont::load(sf.path);
            if (!loaded)
                return make_error("the SoundFont of the track `" + track.name + "`: " + loaded.error().message,
                                  loaded.error().hint.empty() ? "Put the .sf2 file at " + sf.path + " in the project (an asset the project brings), or pick a built-in instrument." : loaded.error().hint);
            auto f = std::make_unique<Font>(Font{std::move(*loaded)});
            found = fonts.emplace(sf.path, std::move(f)).first;
        }
        const Soundfont& font = found->second->font;
        Result<int> index = sf.presetName.empty() ? font.find_preset(sf.bank, sf.program) : font.find_preset(sf.presetName);
        if (!index) return make_error("the SoundFont of the track `" + track.name + "`: " + index.error().message, index.error().hint);
        return std::pair<const Soundfont*, int>{&font, *index};
    }

    // Linear gain that brings the preset's reference note (C4, or a snare for a kit) to kReferenceDb.
    Result<double> font_calibration(const Soundfont& font, int preset, const std::string& path, bool drums) {
        const std::string key = path + "#" + std::to_string(preset) + (drums ? "d" : "");
        if (auto it = fontCalibration.find(key); it != fontCalibration.end()) return it->second;
        const int rate = opt.sampleRate;
        const std::size_t frames = std::size_t(rate);
        SoundfontNote n;
        n.key = drums ? 38 : 60;
        n.velocity = 100.0f / 127.0f;
        n.heldFrames = std::int64_t(drums ? rate / 4 : rate / 2);
        std::vector<double> l, rr;
        auto ok = font.render(preset, rate, {n}, frames, l, rr);
        if (!ok) return make_error("the SoundFont `" + path + "`: " + ok.error().message, ok.error().hint);
        double peak = 0.0;
        for (std::size_t i = 0; i < frames; ++i) peak = std::max({peak, std::abs(l[i]), std::abs(rr[i])});
        double g = 1.0;
        if (peak > 1e-6) g = std::clamp(sfx_math::db_to_gain(kReferenceDb - sfx_math::gain_to_db(peak)), 0.03, 30.0);
        fontCalibration[key] = g;
        return g;
    }
};

}  // namespace

Result<SongRender> render_song(const SongDoc& song, const SongTimeline& timeline, const SongRenderOptions& options) {
    if (options.sampleRate < 8000 || options.sampleRate > 96000) return make_error("sampleRate must be 8000 to 96000, got " + std::to_string(options.sampleRate), "44100 is the default.");
    if (options.fromBar < 1) return make_error("fromBar must be 1 or more", "Bars are counted from 1.");
    if (options.fromBar > timeline.bars && timeline.bars > 0)
        return make_error(std::format("fromBar {} is past the end of the song, which has {} bars", options.fromBar, timeline.bars), "Use a bar from 1 to " + std::to_string(timeline.bars) + ".");
    std::vector<std::string> trackNames;
    for (const SongTrack& t : song.tracks) trackNames.push_back(t.name);
    for (const std::string& n : options.solo)
        if (!song.find_track(n)) return make_error("no track named `" + n + "` to solo", did_you_mean(n, trackNames));
    for (const std::string& n : options.mute)
        if (!song.find_track(n)) return make_error("no track named `" + n + "` to mute", did_you_mean(n, trackNames));

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

    // The tail: room for the releases and for the longest reverb or delay of any chain.
    const double masterTail = chain_tail(song.mixer.master.effects);
    double effectsTail = masterTail;
    for (const SongTrack& t : song.tracks) effectsTail = std::max(effectsTail, chain_tail(t.effects) + masterTail);
    for (const SongBus& b : song.mixer.buses) effectsTail = std::max(effectsTail, chain_tail(b.effects) + masterTail);
    const double tailSeconds = std::max(options.tailSeconds, std::min(effectsTail + 0.25, kMaxEffectTail + 1.0));
    const std::size_t frames = musicFrames + std::size_t(tailSeconds * double(sr));

    const double fromBeat = double(fromTick) / double(kSongPpq);
    const double beatsPerSecond = song.tempo / 60.0;
    auto beat_at = [&](std::size_t frame) { return fromBeat + double(frame) / double(sr) * beatsPerSecond; };
    auto frame_of = [&](std::int64_t tick) { return std::size_t(double(tick - fromTick) * secondsPerTick * double(sr) + 0.5); };
    const std::size_t cutFade = std::max<std::size_t>(1, std::size_t(kCutFadeSeconds * double(sr)));

    // Who plays: the solo buttons (the options' and the tracks') and the mutes.
    std::vector<std::string> soloed = options.solo;
    for (const SongTrack& t : song.tracks)
        if (t.solo && !contains(soloed, t.name)) soloed.push_back(t.name);

    // Master sum (double), and the buses' inputs (float: only the used ones are allocated).
    std::vector<std::vector<double>> master(2, std::vector<double>(frames, 0.0));
    struct BusInput {
        std::vector<float> l, r;
        bool used = false;
    };
    std::vector<BusInput> busInputs(song.mixer.buses.size());

    for (std::size_t ti = 0; ti < song.tracks.size(); ++ti) {
        const SongTrack& track = song.tracks[ti];
        if (track.mute || contains(options.mute, track.name)) continue;
        if (!soloed.empty() && !contains(soloed, track.name)) continue;

        // The track's notes: frames, then the voice limit and the chokes.
        std::vector<NoteEv> evs;
        for (const SongNote& n : timeline.notes) {
            if (n.track != int(ti)) continue;
            if (n.tick < fromTick || n.tick >= toTick) continue;
            NoteEv e;
            e.tick = n.tick;
            e.endTick = n.tick + n.gateTicks();
            e.start = frame_of(n.tick);
            e.gate = std::max<std::size_t>(1, std::size_t(double(n.gateTicks()) * secondsPerTick * double(sr) + 0.5));
            e.pitch = track.drums ? -1 : std::clamp(n.pitch, 0, 127);
            e.velocity = n.velocity;
            e.note = &n;
            evs.push_back(e);
        }
        if (evs.empty()) continue;

        // The voice limit. A note is a voice from its start until `ringEnd(i)` (its release included); a new note that finds the limit
        // reached cuts the oldest voice of an earlier moment, so a chord is never cut by its own notes. A key played again while it is still
        // held stops the earlier note (a piano key cannot sound twice).
        auto allocate_voices = [&](const std::vector<std::size_t>& ringEnd) {
            int limit = track.voices;
            if (limit <= 0) limit = song_instrument_voices(track.instrument).value_or(16);
            std::vector<std::size_t> active;  // indices into evs, oldest first
            for (std::size_t i = 0; i < evs.size(); ++i) {
                NoteEv& e = evs[i];
                std::erase_if(active, [&](std::size_t j) { return ringEnd[j] <= e.start || evs[j].cut != SIZE_MAX; });
                for (std::size_t j : active)
                    if (evs[j].tick < e.tick && evs[j].pitch == e.pitch && evs[j].endTick > e.tick) evs[j].cut = e.start;
                std::erase_if(active, [&](std::size_t j) { return evs[j].cut != SIZE_MAX; });
                while (active.size() >= std::size_t(limit)) {
                    auto oldest = std::find_if(active.begin(), active.end(), [&](std::size_t j) { return evs[j].tick < e.tick; });
                    if (oldest == active.end()) break;
                    evs[*oldest].cut = e.start;
                    active.erase(oldest);
                }
                active.push_back(i);
            }
        };

        if (track.drums) {
            // A closed or pedal hat chokes a ringing open hat.
            std::vector<std::int64_t> hatTicks;
            for (const NoteEv& e : evs)
                if (is_hat_lane(e.note->drum)) hatTicks.push_back(e.tick);
            for (NoteEv& e : evs) {
                if (e.note->drum != "openhat") continue;
                auto next = std::upper_bound(hatTicks.begin(), hatTicks.end(), e.tick);
                if (next != hatTicks.end()) e.cut = frame_of(*next);
            }
        }

        // The sound, into `ch`: one channel for a synthesized instrument, two for a SoundFont.
        std::vector<std::vector<double>> ch;
        if (track.soundfont.present()) {
            auto sf = r.soundfont(track);
            if (!sf) return sf.error();
            auto cal = r.font_calibration(*sf->first, sf->second, track.soundfont.path, track.drums);
            if (!cal) return cal.error();
            if (!track.drums) {
                std::vector<std::size_t> ringEnd;
                for (const NoteEv& e : evs) ringEnd.push_back(e.end());
                allocate_voices(ringEnd);
            }
            std::vector<SoundfontNote> notes;
            for (const NoteEv& e : evs) {
                SoundfontNote n;
                n.startFrame = std::int64_t(e.start);
                std::size_t held = e.gate;
                if (e.cut != SIZE_MAX && e.cut > e.start) held = std::min(held, e.cut - e.start);
                n.heldFrames = std::int64_t(std::max<std::size_t>(1, held));
                n.key = track.drums ? gm_drum_key(e.note->drum) : e.pitch;
                n.velocity = float(e.velocity) / 127.0f;
                notes.push_back(n);
            }
            ch.assign(2, {});
            auto ok = sf->first->render(sf->second, sr, notes, frames, ch[0], ch[1]);
            if (!ok) return make_error("the SoundFont of the track `" + track.name + "`: " + ok.error().message, ok.error().hint);
            for (auto& c : ch)
                for (double& v : c) v *= *cal;
            r.result.notes += int(evs.size());
        } else {
            ch.assign(1, std::vector<double>(frames, 0.0));
            std::vector<std::shared_ptr<Renderer::Cached>> clips;
            for (const NoteEv& e : evs) {
                const SongNote& n = *e.note;
                std::string what;
                if (track.drums) {
                    auto k = track.kit.find(n.drum);
                    if (k != track.kit.end()) {
                        what = k->second;
                    } else {
                        const std::string variant = song_kit_variant(track.instrument).value_or("acoustic");
                        what = variant == "acoustic" ? "kit:" + n.drum : "kit:" + variant + ":" + n.drum;
                    }
                } else {
                    what = track.instrument;
                }
                auto v = r.voice(track, what, track.drums);
                if (!v) return v.error();
                std::map<std::string, double> macros;
                const double beat = double(n.tick) / double(kSongPpq);
                for (const SongAutomation& a : track.automation)
                    if (a.param.rfind("macro.", 0) == 0) macros[a.param.substr(6)] = a.value_at(beat, 0.0);
                if ((*v)->velocityTone) macros["brightness"] += 0.008 * double(n.velocity - 100);
                for (auto& m : macros) m.second = std::clamp(std::round(m.second * 20.0) / 20.0, -1.0, 1.0);
                auto c = r.note(**v, track.drums ? 60 : e.pitch, double(e.gate) / double(sr), macros);
                if (!c) return c.error();
                clips.push_back(*c);
            }
            if (!track.drums) {
                std::vector<std::size_t> ringEnd;
                for (std::size_t i = 0; i < evs.size(); ++i) ringEnd.push_back(evs[i].start + clips[i]->samples.size());
                allocate_voices(ringEnd);
            }
            for (std::size_t k = 0; k < evs.size(); ++k) {
                const NoteEv& e = evs[k];
                const std::vector<float>& s = clips[k]->samples;
                const double g = sfx_math::pow(double(e.velocity) / 100.0, kVelocityCurve);
                std::size_t len = std::min(s.size(), e.start < frames ? frames - e.start : 0);
                std::size_t cutAt = SIZE_MAX;
                if (e.cut != SIZE_MAX && e.cut > e.start) {
                    cutAt = e.cut - e.start;
                    len = std::min(len, cutAt + cutFade);
                }
                std::vector<double>& out = ch[0];
                for (std::size_t i = 0; i < len; ++i) {
                    double gain = g;
                    if (cutAt != SIZE_MAX && i >= cutAt) gain *= 1.0 - double(i - cutAt) / double(cutFade);
                    out[e.start + i] += double(s[i]) * gain;
                }
                ++r.result.notes;
            }
        }

        // The track's chain: filter lane, inserts, fader and pan lanes, into a stereo track bus.
        const SongAutomation* filterLane = find_lane(track.automation, "filter");
        const SongAutomation* volumeLane = find_lane(track.automation, "volume");
        const SongAutomation* panLane = find_lane(track.automation, "pan");
        if (filterLane) {
            for (auto& c : ch) {
                Lowpass lp;
                for (std::size_t b = 0; b < frames; b += kBlock) {
                    const std::size_t e = std::min(frames, b + kBlock);
                    lp.set(filterLane->value_at(beat_at(b), 20000.0), sr);
                    for (std::size_t i = b; i < e; ++i) c[i] = lp.run(c[i]);
                }
            }
        }
        run_chain(ch, sr, track.effects, false);
        const bool mono = ch.size() == 1;
        std::vector<std::vector<double>> bus(2, std::vector<double>(frames, 0.0));
        for (std::size_t b = 0; b < frames; b += kBlock) {
            const std::size_t e = std::min(frames, b + kBlock);
            const double vol0 = track.volume * (volumeLane ? volumeLane->value_at(beat_at(b), 1.0) : 1.0);
            const double vol1 = track.volume * (volumeLane ? volumeLane->value_at(beat_at(e), 1.0) : 1.0);
            const double pan0 = panLane ? panLane->value_at(beat_at(b), track.pan) : track.pan;
            const double pan1 = panLane ? panLane->value_at(beat_at(e), track.pan) : track.pan;
            for (std::size_t i = b; i < e; ++i) {
                const double f = double(i - b) / double(e - b);
                const double vol = vol0 + (vol1 - vol0) * f;
                double gl, gr;
                pan_gains(pan0 + (pan1 - pan0) * f, mono, gl, gr);
                bus[0][i] = ch[0][i] * vol * gl;
                bus[1][i] = (mono ? ch[0][i] : ch[1][i]) * vol * gr;
            }
        }
        ch.clear();

        SongTrackStats stats;
        stats.name = track.name;
        stats.notes = int(evs.size());
        stats.peakDb = measure_peak_db(bus);
        double peakLin = 0.0;
        sfx_measure_loudness(bus, sr, stats.lufs, peakLin);
        r.result.tracks.push_back(stats);

        for (std::size_t i = 0; i < frames; ++i) {
            master[0][i] += bus[0][i];
            master[1][i] += bus[1][i];
        }
        for (const auto& send : track.sends) {
            if (!(send.second > 0.0)) continue;
            std::size_t index = 0;
            while (index < song.mixer.buses.size() && song.mixer.buses[index].name != send.first) ++index;
            if (index >= song.mixer.buses.size()) continue;
            BusInput& in = busInputs[index];
            if (!in.used) {
                in.l.assign(frames, 0.0f);
                in.r.assign(frames, 0.0f);
                in.used = true;
            }
            for (std::size_t i = 0; i < frames; ++i) {
                in.l[i] += float(bus[0][i] * send.second);
                in.r[i] += float(bus[1][i] * send.second);
            }
        }
    }

    // The buses: effects (a reverb or delay returns only its wet sound), volume, balance, into the master.
    for (std::size_t bi = 0; bi < song.mixer.buses.size(); ++bi) {
        BusInput& in = busInputs[bi];
        if (!in.used) continue;
        const SongBus& bus = song.mixer.buses[bi];
        if (bus.mute) continue;
        std::vector<std::vector<double>> ch(2, std::vector<double>(frames));
        for (std::size_t i = 0; i < frames; ++i) {
            ch[0][i] = double(in.l[i]);
            ch[1][i] = double(in.r[i]);
        }
        in = BusInput{};
        run_chain(ch, sr, bus.effects, true);
        double gl, gr;
        pan_gains(bus.pan, false, gl, gr);
        for (std::size_t i = 0; i < frames; ++i) {
            master[0][i] += ch[0][i] * bus.volume * gl;
            master[1][i] += ch[1][i] * bus.volume * gr;
        }
    }

    // Master: the song's volume and lanes, the master effects, a 20 ms fade at the end so the file never ends on a click.
    const SongAutomation* mvol = find_lane(song.automation, "volume");
    const SongAutomation* mfilter = find_lane(song.automation, "filter");
    {
        Lowpass lpl, lpr;
        for (std::size_t b = 0; b < frames; b += kBlock) {
            const std::size_t e = std::min(frames, b + kBlock);
            if (mfilter) { const double c = mfilter->value_at(beat_at(b), 20000.0); lpl.set(c, sr); lpr.set(c, sr); }
            const double v0 = song.volume * (mvol ? mvol->value_at(beat_at(b), 1.0) : 1.0);
            const double v1 = song.volume * (mvol ? mvol->value_at(beat_at(e), 1.0) : 1.0);
            for (std::size_t i = b; i < e; ++i) {
                const double vol = v0 + (v1 - v0) * (double(i - b) / double(e - b));
                double l = master[0][i], rr = master[1][i];
                if (mfilter) { l = lpl.run(l); rr = lpr.run(rr); }
                master[0][i] = l * vol;
                master[1][i] = rr * vol;
            }
        }
    }
    run_chain(master, sr, song.mixer.master.effects, false);
    {
        const std::size_t fade = std::min<std::size_t>(frames, std::size_t(sr / 50));
        for (std::size_t i = 0; i < fade; ++i) {
            const double g = double(i) / double(fade);
            master[0][frames - 1 - i] *= g;
            master[1][frames - 1 - i] *= g;
        }
    }

    // Loudness and limiter. The limiter lowers the level when peaks are in the way, so the normalization measures the limited render
    // and asks for what is missing (a few passes at most).
    const SongMaster& mm = song.mixer.master;
    SongMasterStats& ms = r.result.master;
    ms.limiter = mm.limiter;
    ms.ceilingDb = mm.ceilingDb;
    double peakBefore = 0.0;
    sfx_measure_loudness(master, sr, ms.lufsBefore, peakBefore);
    ms.peakBeforeDb = peakBefore > 0.0 ? sfx_math::gain_to_db(peakBefore) : -200.0;
    std::optional<double> target;
    if (mm.loudness == SongMaster::Loudness::Target) target = mm.loudnessLufs;
    else if (mm.loudness == SongMaster::Loudness::Style) target = options.targetLufs;
    const double ceiling = sfx_math::db_to_gain(mm.ceilingDb);
    double gainDb = 0.0;
    if (target && ms.lufsBefore > -60.0) {
        gainDb = std::min(*target - ms.lufsBefore, kMaxNormalizeBoostDb);
        ms.targetLufs = target;
        if (mm.limiter) {
            std::vector<std::vector<double>> probe(2);
            for (int pass = 0; pass < 4; ++pass) {
                const double g = sfx_math::db_to_gain(gainDb);
                for (std::size_t c = 0; c < 2; ++c) {
                    probe[c] = master[c];
                    for (double& v : probe[c]) v *= g;
                }
                run_limiter(probe[0], probe[1], ceiling, mm.limiterRelease, sr);
                double lufs = -70.0, pk = 0.0;
                sfx_measure_loudness(probe, sr, lufs, pk);
                const double miss = *target - lufs;
                if (std::abs(miss) < 0.05 || lufs <= -60.0) break;
                const double next = std::min(gainDb + miss, kMaxNormalizeBoostDb + 6.0);
                if (std::abs(next - gainDb) < 0.01) break;
                gainDb = next;
            }
        }
        ms.normalizeGainDb = gainDb;
    }
    const double gain = sfx_math::db_to_gain(gainDb);
    if (gain != 1.0)
        for (auto& c : master)
            for (double& v : c) v *= gain;
    if (mm.limiter) ms.limiterReductionDb = run_limiter(master[0], master[1], ceiling, mm.limiterRelease, sr);

    r.result.clip.sampleRate = sr;
    r.result.clip.channels = 2;
    r.result.clip.samples.resize(frames * 2);
    const float cap = float(ceiling);
    for (std::size_t i = 0; i < frames; ++i) {
        float l = float(master[0][i]), rr = float(master[1][i]);
        if (mm.limiter) {  // the float cast can round a sample a hair above the ceiling
            l = std::clamp(l, -cap, cap);
            rr = std::clamp(rr, -cap, cap);
        }
        r.result.clip.samples[2 * i] = l;
        r.result.clip.samples[2 * i + 1] = rr;
        master[0][i] = double(l);
        master[1][i] = double(rr);
    }
    double lufs = -70.0, peak = 0.0;
    sfx_measure_loudness(master, sr, lufs, peak);
    r.result.clip.lufs = lufs;
    r.result.clip.peakDb = peak > 0.0 ? sfx_math::gain_to_db(peak) : -200.0;
    r.result.clip.inputs = r.result.inputs;
    r.result.seconds = musicSeconds;
    return std::move(r.result);
}

}  // namespace fa
