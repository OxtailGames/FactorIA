// Software mixer: decoded clips -> voices -> buses -> master -> (device | null sink | recorder).
//
// Threading: in device mode sokol_audio calls render() on its own thread; every piece of state shared with the
// game thread (voices, bus volumes, recorder, clip cache) is protected by Impl::mu. The callback does no
// allocation except when the recorder grows. Clips are decoded OUTSIDE the lock; a streamed clip is decoded inside it,
// a few thousand frames at a time, into buffers its voice allocated when it started.
#include "fa/audio/audio.h"
#include "fa/audio/sfx.h"

#include <algorithm>
#include <atomic>
#include <cmath>
#include <cstdlib>
#include <cstring>
#include <deque>
#include <map>
#include <mutex>
#include <optional>
#include <set>
#include <thread>

#include "audio_decoder.h"
#include "bus_fx.h"
#include "fa/audio/analysis.h"
#include "fa/audio/music_transport.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/fs.h"
#include "fa/core/load_trace.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "fa/core/video.h"
#include "fa/scene/feel.h"
#include "sokol_audio.h"

#if defined(__APPLE__)
#include <TargetConditionals.h>
#endif

#if defined(__EMSCRIPTEN__)
#include "audio_web.h"
#endif

namespace fa {

namespace {

using audio_detail::Stream;
using audio_detail::Ramp;

constexpr int kRate = audio_detail::kMixRate;
constexpr std::size_t kMaxVoices = 64;
constexpr std::size_t kMaxRecordFrames = std::size_t(kRate) * 600;  // 10 minutes
constexpr int kBlock = 512;
constexpr std::size_t kMaxPlayLog = 4096;

// The bus table: 0..2 are the built-in buses, kMasterBus the master (its "buffer" is the output), and the project's buses
// (factoria.json "audio.buses") follow from kFirstProjectBus.
enum Bus { BusSfx = 0, BusMusic = 1, BusUi = 2, BusBuiltin = 3 };
const char* const kBusNames[BusBuiltin] = {"sfx", "music", "ui"};
constexpr int kMasterBus = BusBuiltin;
constexpr int kFirstProjectBus = BusBuiltin + 1;
constexpr std::size_t kMaxEnded = 1024;   // endings waiting for take_ended_voices()
constexpr float kDuckThreshold = 0.01f;   // -40 dBFS: a bus that peaks above this ducks the buses that listen to it
constexpr float kLowpassOpen = 20000.0f;  // where a cutoff slides from or to when the filter is switched on or off
constexpr float kMaxBusVolume = 4.0f;
constexpr double kReverbTail = 4.0;       // seconds the reverb keeps running after its bus went silent (it decays to -100 dB)

// The state of one bus: its gain, its effects and its ducking. [kMasterBus] is the master.
struct BusFx {
    std::string name;
    int parent = kMasterBus;  // the bus this one is summed into
    int depth = 1;            // 1 = under the master; a bus is mixed after the buses under it
    Ramp vol;   // the volume (the player's options; audio.setVolume)
    Ramp snap;  // the scale a snapshot sets
    // Low-pass: the cutoff moves in octaves (log2 of Hz); lpHz is the target in Hz (0 = off).
    bool lpOn = false, lpOffAtEnd = false, lpDirty = false;
    Ramp lpLog;
    float lpHz = 0.0f;
    audio_detail::Lowpass lp;
    // Reverb: allocated the first time it is switched on (never on the audio thread).
    bool rvOn = false, rvOffAtEnd = false;
    Ramp rvMix{0.0f, 0.0f, 0.0f, 0};
    std::unique_ptr<audio_detail::Reverb> rv;
    long rvQuiet = 0;  // frames since the bus last had a voice
    // Ducking.
    int duckBy = -1;
    DuckSettings duck;
    float duckAttack = 0.0f, duckRelease = 0.0f;  // one-pole coefficients
    float duckGain = 1.0f, duckEnv = 0.0f;
};

struct Clip {
    std::string path;
    std::vector<float> data;  // interleaved stereo, 44100 Hz; empty for a streamed clip
    std::shared_ptr<const audio_detail::Bytes> encoded;  // a streamed clip keeps its file: each voice decodes it as it plays
    std::string ext;           // of `encoded`
    std::size_t frames = 0;    // 44100 Hz frames (counted from the header for a streamed clip)
    int srcChannels = 0;
    int srcRate = 0;
    float gain = 1.0f;         // loudness normalization (the `normalize` import setting)
    // Loop points (the `loopStart` / `loopEnd` import settings, in seconds): a looping voice plays loopStart..loopEnd over and over
    // after the first pass. In 44100 Hz frames; loopEnd 0 = no loop points (the whole clip loops).
    std::size_t loopStart = 0, loopEnd = 0;
};

// A voice fed by the game instead of reading a clip: a video's sound (open_pcm_voice / push_pcm). Interleaved stereo float
// at `rate`, read with linear interpolation; when the queue runs dry the voice is silent and stays open.
struct PcmFeed {
    int rate = kRate;
    std::vector<float> queue;
    std::size_t head = 0;  // index (in floats) of the first frame not yet consumed
    double pos = 0.0;      // fractional frame position relative to `head`
    std::size_t frames() const { return (queue.size() - head) / 2; }
};

struct Voice {
    VoiceId id = 0;
    std::shared_ptr<const Clip> clip;
    double pos = 0.0;  // in clip frames (fractional for pitch)
    float volume = 1.0f, pitch = 1.0f, pan = 0.0f;
    bool loop = false;
    int bus = BusSfx;
    float fade = 1.0f, fadeTarget = 1.0f, fadeStep = 0.0f;
    long fadeFrames = 0;
    bool stopAtFadeEnd = false;
    // A ramp of `volume` itself (set_voice_volume with a fade): per frame `volume += volStep` for volFrames frames.
    float volTarget = 1.0f, volStep = 0.0f;
    long volFrames = 0;
    bool protect = false;  // music and its layers: never the voice a full mixer evicts
    bool notify = false;   // its end goes to Impl::ended (PlayParams::notifyEnd)
    std::string path;      // the clip (or the video file) it plays
    std::string source;    // the entity id of the AudioSource / Video that started it
    long delay = 0;        // output frames of silence left before it sounds (PlayParams::delayFrames)
    bool dead = false;
    std::unique_ptr<Stream> stream;  // set for a streamed clip: `pos` then counts frames of the whole timeline
    std::unique_ptr<PcmFeed> pcm;    // set for a voice the game feeds (no clip)
};

// A video's voice (Video components, Audio::update).
struct EntityVideo {
    std::string id;
    std::shared_ptr<VideoDecoder> decoder;  // the decoder this voice carries; a new one (path changed) is a new voice
    VoiceId voice = 0;
    std::uint64_t epoch = 0;
    std::string bus;
    std::uint64_t seen = 0;
};

struct EntityAudio {
    Entity e;
    std::string id;
    std::string clip;
    VoiceId voice = 0;
    bool started = false;
    std::uint64_t seen = 0;
    int lastVariant = 0;       // AudioSource.variants: the variant played last (1-based), never picked twice in a row
    std::uint32_t plays = 0;   // how many plays picked a variant: part of the pick's seed
};

// Import settings come from a file people edit: read them without assuming their types.
std::string setting_string(const Json& settings, const char* key, const char* fallback) {
    auto it = settings.find(key);
    return it != settings.end() && it->is_string() ? it->get<std::string>() : fallback;
}
bool setting_bool(const Json& settings, const char* key, bool fallback) {
    auto it = settings.find(key);
    return it != settings.end() && it->is_boolean() ? it->get<bool>() : fallback;
}
double setting_number(const Json& settings, const char* key, double fallback) {
    auto it = settings.find(key);
    return it != settings.end() && it->is_number() ? it->get<double>() : fallback;
}

#if defined(__ANDROID__) || (defined(__APPLE__) && TARGET_OS_IPHONE)
constexpr bool kMeasuresAtLoad = false;  // phones play what the export measured (convert_audio)
#else
constexpr bool kMeasuresAtLoad = true;
#endif

void write_le16(std::vector<std::uint8_t>& b, std::uint16_t v) {
    b.push_back(std::uint8_t(v & 0xff));
    b.push_back(std::uint8_t(v >> 8));
}
void write_le32(std::vector<std::uint8_t>& b, std::uint32_t v) {
    for (int i = 0; i < 4; ++i) b.push_back(std::uint8_t((v >> (8 * i)) & 0xff));
}

// ---- adaptive music (MusicPlayer components): the mixer's side of one player -------------------------------------------------------
constexpr std::size_t kMusicCacheBytes = std::size_t(128) << 20;  // sources nobody plays are dropped above this

// A song being rendered or read. A windowed player runs it on a worker thread; the null device (tests, headless) and the web run it
// right in the call, so a headless run is deterministic and has the music from the frame it asked.
struct MusicLoad {
    std::string key, path, note;
    MusicMode mode = MusicMode::Live;
    MusicStemPlan plan;
    std::thread worker;
    std::atomic<bool> done{false};
    std::shared_ptr<MusicSource> source;
    std::string error;
    LoadTrace::Owner owner = LoadTrace::current_owner();  // the engine that asked: its load trace gets the reads
    void run() {
        LoadTrace::ReadingFor reading(owner);  // on the loader thread too (fa/core/load_trace.h)
        auto r = music_load_source(path, mode, plan, &note);
        if (r) source = std::move(*r);
        else error = r.error().to_string();
        done = true;
    }
};

struct MusicRt {
    Entity e;
    std::string id;
    const World* world = nullptr;
    std::unique_ptr<MusicTransport> tr = std::make_unique<MusicTransport>();
    std::string song;                         // the song asked for (normalized path; "" = none)
    std::shared_ptr<const MusicSource> src;   // its source (null while it loads, or when it failed)
    std::shared_ptr<const MusicSource> sent;  // the source the transport was last given
    std::string waitKey;                      // the load src is waiting for
    std::string error;                        // why the song could not play
    std::string busName = "music";
    int bus = BusMusic;
    float volume = -1.0f, intensity = -1.0f;
    bool loop = true, playing = false, stopIssued = false, first = true;
    float layerFade = -1.0f, layerRange = -1.0f;
    struct Entry {                            // how the source that arrives enters the transport
        bool set = false, hard = false;
        std::string section;
        std::optional<MusicQuantize> quantize;
        float bars = -1.0f;
        bool lenient = false;                 // a reload or a device change: a section the new source lacks starts it at the beginning
    } entry;
    std::uint64_t seen = 0;
    bool announcedReady = false;
    bool reload = false;                      // its song changed on disk: fetch it again and crossfade to it
    std::uint64_t epoch = 0;                  // the Impl::musicEpoch its mode was resolved at
    MusicMode resolved = MusicMode::Live;     // the mode of the source it asked for
};

}  // namespace

struct Audio::Impl {
    mutable std::mutex mu;
    bool inited = false;
    bool device = false;
    bool autoAdvance = false;  // device requested but unavailable -> run as null device driven by update()
    int deviceRate = kRate;
    int deviceChannels = 2;
    std::atomic<bool> streamLogged{false};  // the first stream callback is logged once

    std::map<std::string, std::shared_ptr<const Clip>> clips;
    std::map<std::string, std::vector<std::string>> untraced;  // adopt_clip: the files of a clip not used yet (load trace)
    std::set<std::string> failedLogged;

    std::vector<Voice> voices;
    VoiceId nextVoice = 1;
    std::vector<BusFx> bus;                  // the bus table (see kMasterBus)
    std::vector<int> mixOrder;               // the buses but the master, deepest first: a bus is summed into its parent
    std::vector<std::vector<float>> busBuf;  // the sum of each bus's voices and child buses, before its parent
    std::vector<std::vector<float>> duckGains;  // the ducking gain of each bus for the block being mixed
    std::vector<VoiceId> ended;              // voices with notify that ended (take_ended_voices)
    AudioSnapshots snapshots;
    std::string snapshotName;
    VoiceId musicVoice = 0;
    std::string musicPath;
    float layerVolume = 0.6f;   // the `volume` musicLayers got: a layer plays at layerVolume * its level
    bool musicPersist = false;  // the music (or its layers) survives scene loads
    struct Layer {
        std::string name;
        VoiceId voice = 0;
        float level = 1.0f;
    };
    std::vector<Layer> layers;  // audio.musicLayers: voices that started on the same sample

    bool paused = false;  // set_paused: the mix is silent and no voice advances
    bool recording = false;
    std::vector<float> rec;
    int recRate = kRate;
    bool recWarned = false;

    float lastPeak = 0.0f;
    double carry = 0.0;
    std::vector<float> tmp;
    std::vector<float> nullBuf;

    // gameplay-side state (only touched from the game thread)
    const World* lastWorld = nullptr;
    std::map<std::uint64_t, EntityAudio> ents;
    std::map<std::uint64_t, EntityVideo> videos;
    std::vector<float> videoScratch;
    std::uint64_t stamp = 0;
    std::string sceneMusic;
    float sceneMusicVolume = -1.0f;


    // adaptive music (MusicPlayer components): the players are touched by the game thread and by the mixer, under `mu`; the rest
    // of the state (sources, loads) by the game thread alone.
    std::map<std::uint64_t, std::unique_ptr<MusicRt>> musicEnts;
    std::vector<std::unique_ptr<MusicRt>> musicOrphans;   // players whose entity is gone: they fade out (or a new player adopts them)
    std::map<std::string, std::shared_ptr<const MusicSource>> musicCache;   // by "song|mode"
    std::map<std::string, std::shared_ptr<MusicLoad>> musicLoads;
    std::map<std::string, std::string> musicErrors;       // why a load failed, by key
    std::vector<std::shared_ptr<MusicLoad>> musicStale;   // loads of a song that changed while they ran: joined, then dropped
    MusicDeviceProfile musicDevice;
    std::uint64_t musicEpoch = 1;                         // raised when the device profile changes (players re-resolve `auto`)
    std::uint64_t mixedTotal = 0;
    std::vector<MusicEvent> musicScratch;
    std::vector<GameEvent> musicOut;

    MusicRt* music_find(const World& world, Entity e);
    MusicRt& music_get(World& world, Entity e);
    void music_request(MusicRt& rt, const MusicPlayer& mp);
    void music_poll();
    void music_drive(World& world, Entity e, MusicPlayer& mp, MusicRt& rt);
    void music_update(World& world);
    void music_resolve(MusicRt& rt);
    void music_orphan(MusicRt* rt);
    void music_events(World& world, MusicRt& rt);
    void music_shutdown();
    void music_invalidate(const std::string& song);

    // play log (game thread)
    const World* clockWorld = nullptr;
    std::deque<AudioEvent> playLog;
    std::uint64_t playSeq = 0;
    std::uint64_t playDropped = 0;

    Impl() { reset_bus_table(); }

    // The built-in buses alone, all neutral.
    void reset_bus_table() {
        bus.clear();
        bus.resize(std::size_t(kFirstProjectBus));
        for (int i = 0; i < BusBuiltin; ++i) bus[std::size_t(i)].name = kBusNames[i];
        bus[std::size_t(kMasterBus)].name = "master";
        build_mix_order();
    }

    // Depths and the order buses are mixed in: the deepest first, so every bus has its children's sound when its turn comes.
    void build_mix_order() {
        mixOrder.clear();
        for (std::size_t i = 0; i < bus.size(); ++i) {
            int d = 1;
            for (int at = int(i); at != kMasterBus && at >= 0 && d <= int(bus.size()); at = bus[std::size_t(at)].parent) ++d;
            bus[i].depth = int(i) == kMasterBus ? 0 : d - 1;
            if (int(i) != kMasterBus) mixOrder.push_back(int(i));
        }
        std::stable_sort(mixOrder.begin(), mixOrder.end(),
                         [&](int a, int b) { return bus[std::size_t(a)].depth > bus[std::size_t(b)].depth; });
        busBuf.resize(bus.size());
        duckGains.resize(bus.size());
    }

    // The index of a bus by name (master included); -1 for an unknown name. Caller holds mu.
    int fx_index(std::string_view name) const {
        for (std::size_t i = 0; i < bus.size(); ++i)
            if (bus[i].name == name) return int(i);
        return -1;
    }
    // The buses a voice can play on (not the master). Caller holds mu.
    int bus_index(std::string_view name) const {
        const int b = fx_index(name);
        return b == kMasterBus ? -1 : b;
    }
    std::vector<std::string> bus_names_locked(bool withMaster) const {
        std::vector<std::string> names;
        for (std::size_t i = 0; i < bus.size(); ++i)
            if (withMaster || int(i) != kMasterBus) names.push_back(bus[i].name);
        return names;
    }

    void log_play(std::string_view path, const PlayParams& p, bool music, std::string_view source, bool ok,
                  std::string_view layer = {}, VoiceId voice = 0) {
        std::lock_guard<std::mutex> lk(mu);
        AudioEvent ev;
        ev.voice = voice;
        ev.seq = ++playSeq;
        if (const World* w = clockWorld ? clockWorld : lastWorld) {
            ev.frame = w->frame();
            ev.time = w->time();
        }
        ev.path = fs::normalize(path);
        ev.volume = p.volume;
        ev.pitch = p.pitch;
        ev.pan = p.pan;
        ev.bus = bus_index(p.bus) < 0 ? std::string(kBusNames[BusSfx]) : p.bus;
        ev.loop = p.loop;
        ev.music = music;
        ev.source = std::string(source);
        ev.layer = std::string(layer);
        ev.ok = ok;
        playLog.push_back(std::move(ev));
        if (playLog.size() > kMaxPlayLog) {
            playLog.pop_front();
            ++playDropped;
        }
    }

    // play() with the AudioSource entity id that requested it ("" for scripts).
    VoiceId start(std::string_view clipPath, const PlayParams& params, std::string_view source) {
        if (!inited) {
            FA_ERROR("audio", "Audio::play('{}') called before Audio::init()", clipPath);
            return 0;
        }
        auto clip = get_clip(clipPath);
        if (!clip) {
            log_play(clipPath, params, false, source, false);
            return 0;
        }
        std::string err;
        auto stream = open_stream(*clip, params.loop, &err);
        if (clip->encoded && !stream) {
            log_play(clipPath, params, false, source, true);
            FA_ERROR("audio", "Audio clip '{}' cannot be streamed: {}", clipPath, err);
            return 0;
        }
        VoiceId id = 0;
        {
            std::lock_guard<std::mutex> lk(mu);
            id = add_voice_locked(std::move(clip), params, std::move(stream));
            if (Voice* v = find_voice(id)) v->source = std::string(source);
        }
        log_play(clipPath, params, false, source, true, {}, id);
        return id;
    }

    // The decoding state of a new voice on a streamed clip (null for a clip decoded whole). Made outside the lock: it
    // opens a decoder and decodes the first few thousand frames.
    static std::unique_ptr<Stream> open_stream(const Clip& clip, bool loop, std::string* err) {
        if (!clip.encoded) return nullptr;
        auto decoder = audio_detail::open_decoder(clip.encoded->data(), clip.encoded->size(), clip.ext, err);
        if (!decoder) return nullptr;
        return std::make_unique<Stream>(audio_detail::Resampler(clip.encoded, std::move(decoder), loop));
    }

    // ------------------------------------------------------------ decode
    // Uses no state of the mixer: background loading runs it on a job (Audio::decode_clip).
    static std::shared_ptr<const Clip> decode(const std::string& path, std::string* err) {
        AssetLoadScope trace("sound", path);  // the load trace's read and decode time (fa/core/load_trace.h); free without one
        auto file = read_audio_file(path);
        if (!file) {
            std::vector<std::string> cands;
            for (const std::string& f : fs::list("", true)) {
                if (audio_detail::is_audio_extension(fs::extension(f))) cands.push_back(f);
            }
            std::string msg = "Audio clip '" + path + "' could not be loaded: " + file.error().message;
            std::string hint = cands.empty() ? "put .wav/.ogg/.mp3/.qoa files under the project (e.g. assets/sounds/) and use a project-relative path"
                                              : did_you_mean(path, cands);
            *err = msg + " (hint: " + hint + ")";
            return nullptr;
        }
        const std::string ext = fs::extension(file->path);
        auto bytes = std::make_shared<audio_detail::Bytes>(std::move(file->bytes));
        std::string problem;
        auto decoder = audio_detail::open_decoder(bytes->data(), bytes->size(), ext, &problem);
        if (!decoder) {
            *err = "Audio clip '" + path + "' " + problem;
            return nullptr;
        }
        const Json settings = assets::import_settings(path);
        const std::string mode = setting_string(settings, "stream", "auto");
        auto clip = std::make_shared<Clip>();
        clip->path = path;
        clip->srcChannels = decoder->channels();
        clip->srcRate = decoder->rate();
        const double toMixRate = double(kRate) / double(decoder->rate());
        const double loopStartSeconds = setting_number(settings, "loopStart", 0.0), loopEndSeconds = setting_number(settings, "loopEnd", 0.0);
        const bool loopPoints = loopEndSeconds > loopStartSeconds && loopStartSeconds >= 0.0;
        // Loop points need the whole clip in memory (a streamed clip rewinds to its start): they win over `stream`.
        const bool streams = !loopPoints && clip_streams(mode, mode == "auto" ? double(decoder->frames()) / double(decoder->rate()) : 0.0);
        if (streams && decoder->frames() > 0) {
            clip->encoded = bytes;
            clip->ext = ext;
            clip->frames = std::size_t(std::ceil(double(decoder->frames()) * toMixRate));
        } else {
            // Whole: through the same resampler a streamed clip plays through.
            const std::uint64_t expected = streams ? 0 : decoder->frames();
            audio_detail::Resampler source(bytes, std::move(decoder), false);
            clip->data.reserve(std::size_t(std::ceil(double(expected) * toMixRate)) * 2);
            for (;;) {
                const std::size_t at = clip->data.size();
                clip->data.resize(at + 2 * 16384);
                const std::size_t got = source.pull(clip->data.data() + at, 16384);
                clip->data.resize(at + 2 * got);
                if (got < 16384) break;
            }
            clip->frames = clip->data.size() / 2;
        }
        if (clip->frames == 0) {
            *err = "Audio clip '" + path + "' contains no audio samples";
            return nullptr;
        }
        if (loopPoints) {
            const std::size_t ls = std::size_t(std::llround(loopStartSeconds * double(kRate))), le = std::min(clip->frames, std::size_t(std::llround(loopEndSeconds * double(kRate))));
            if (le > ls + 1) {
                clip->loopStart = ls;
                clip->loopEnd = le;
            } else {
                FA_WARN("audio", "'{}': loopStart {} and loopEnd {} leave nothing to loop inside the {:.3f} s clip, so the whole clip loops", clip->path, loopStartSeconds, loopEndSeconds,
                        double(clip->frames) / double(kRate));
            }
        }
        normalize(*clip, settings, *bytes, ext);
        return clip;
    }

    // Sets clip.gain when the clip's `normalize` import setting is on: from the loudness assets.json holds for this very
    // file, else measured now (once per load, desktop only).
    static void normalize(Clip& clip, const Json& settings, const audio_detail::Bytes& bytes, const std::string& ext) {
        if (!setting_bool(settings, "normalize", false)) return;
        const Json entry = assets::entry(clip.path);
        auto analysis = entry.find("analysis");
        std::optional<Loudness> loudness = cached_loudness(analysis != entry.end() ? *analysis : Json(), bytes);
        const double target = setting_number(settings, "targetLufs", -16.0);
        if (!loudness) {
            if (!kMeasuresAtLoad) {
                FA_WARN("audio", "'{}' has normalize on but no loudness measured for this file in assets.json, so it plays unchanged "
                                 "(hint: `factoria export` measures it; on desktop run assets.analyze_audio)", clip.path);
                return;
            }
            auto measured = measure_loudness(bytes, ext);
            if (!measured) {
                FA_WARN("audio", "'{}' cannot be normalized: {}", clip.path, measured.error().message);
                return;
            }
            loudness = *measured;
            FA_INFO("audio", "measured '{}': {:.1f} LUFS, peak {:.1f} dBFS; playing it {:+.1f} dB to reach {:.0f} LUFS "
                             "(hint: assets.analyze_audio keeps the measurement in assets.json)", clip.path, loudness->integratedLufs,
                    loudness->peakDb, normalization_gain_db(*loudness, target), target);
        }
        clip.gain = float(std::pow(10.0, normalization_gain_db(*loudness, target) / 20.0));
    }

    std::shared_ptr<const Clip> get_clip(std::string_view pathIn) {
        std::string path = fs::normalize(pathIn);
        {
            std::lock_guard<std::mutex> lk(mu);
            auto it = clips.find(path);
            if (it != clips.end()) {
                // Loaded in the background (adopt_clip): its files enter the load order on this first use.
                if (!untraced.empty() && LoadTrace::current_ahead_tag() == 0)
                    if (auto u = untraced.find(path); u != untraced.end()) {
                        for (const std::string& f : u->second) LoadTrace::file_used(f);
                        untraced.erase(u);
                    }
                return it->second;
            }
        }
        std::string err;
        auto clip = decode(path, &err);
        std::lock_guard<std::mutex> lk(mu);
        if (!clip) {
            if (failedLogged.insert(path).second) FA_ERROR("audio", "{}", err);
            return nullptr;
        }
        failedLogged.erase(path);
        auto it = clips.emplace(path, clip).first;
        return it->second;
    }

    // ------------------------------------------------------------- bus effects
    long ramp_frames(float seconds, bool declick) const;
    void set_lowpass_locked(BusFx& fx, float hz, float fadeSeconds);
    void set_reverb_locked(BusFx& fx, float mix, float fadeSeconds);
    void set_duck_locked(BusFx& fx, int by, const DuckSettings& duck);
    Json bus_state_json(const BusFx& fx) const;

    // ------------------------------------------------------------- voices
    Voice* find_voice(VoiceId id) {
        if (id == 0) return nullptr;
        for (Voice& v : voices) if (v.id == id && !v.dead) return &v;
        return nullptr;
    }

    VoiceId add_voice_locked(std::shared_ptr<const Clip> clip, const PlayParams& p, std::unique_ptr<Stream> stream) {
        if (voices.size() >= kMaxVoices) {
            auto it = std::find_if(voices.begin(), voices.end(), [&](const Voice& v) { return !v.loop && !v.protect && v.id != musicVoice; });
            if (it == voices.end()) it = std::find_if(voices.begin(), voices.end(), [&](const Voice& v) { return !v.protect; });
            if (it == voices.end()) it = voices.begin();
            if (it->id == musicVoice) musicVoice = 0;
            note_ended_locked(*it);
            voices.erase(it);
        }
        Voice v;
        v.id = nextVoice++;
        if (nextVoice == 0) nextVoice = 1;
        v.clip = std::move(clip);
        v.stream = std::move(stream);
        v.volume = std::max(p.volume, 0.0f);
        v.pitch = std::max(p.pitch, 0.001f);
        v.pan = clamp(p.pan, -1.0f, 1.0f);
        v.loop = p.loop;
        int b = bus_index(p.bus);
        if (b < 0) {
            FA_ERROR("audio", "Unknown audio bus '{}'. {} (using 'sfx')", p.bus, did_you_mean(p.bus, bus_names_locked(false)));
            b = BusSfx;
        }
        v.bus = b;
        v.notify = p.notifyEnd;
        v.delay = long(std::max<std::int64_t>(p.delayFrames, 0));
        if (v.clip) v.path = v.clip->path;
        voices.push_back(std::move(v));
        return voices.back().id;
    }

    VoiceId open_pcm(int rate, const PlayParams& p) {
        auto feed = std::make_unique<PcmFeed>();
        feed->rate = std::max(rate, 1);
        std::lock_guard<std::mutex> lk(mu);
        VoiceId id = add_voice_locked(nullptr, p, nullptr);
        if (Voice* v = find_voice(id)) v->pcm = std::move(feed);
        return id;
    }

    void start_fade(Voice& v, float target, float seconds, bool stopAtEnd) {
        long frames = std::max(1L, long(std::lround(double(seconds) * deviceRate)));
        v.fadeTarget = target;
        v.fadeFrames = frames;
        v.fadeStep = (target - v.fade) / float(frames);
        v.stopAtFadeEnd = stopAtEnd;
    }

    void start_volume_ramp(Voice& v, float target, float seconds) {
        target = std::max(target, 0.0f);
        if (seconds <= 0.0f) {
            v.volume = target;
            v.volFrames = 0;
            return;
        }
        const long frames = std::max(1L, long(std::lround(double(seconds) * deviceRate)));
        v.volTarget = target;
        v.volFrames = frames;
        v.volStep = (target - v.volume) / float(frames);
    }

    // Advances the volume ramp by one frame (the mixers call it after each frame they mix).
    static void step_volume(Voice& v) {
        if (v.volFrames > 0) {
            v.volume += v.volStep;
            if (--v.volFrames == 0) v.volume = v.volTarget;
        }
    }

    // A voice that ends goes to `ended` when its play asked to be told.
    void note_ended_locked(const Voice& v) {
        if (!v.notify) return;
        if (ended.size() >= kMaxEnded) ended.erase(ended.begin());
        ended.push_back(v.id);
    }

    void erase_voice_locked(VoiceId id) {
        voices.erase(std::remove_if(voices.begin(), voices.end(), [&](const Voice& v) { return v.id == id; }), voices.end());
    }

    // Stops every layer of the current layered music, fading out over `fade` seconds (0 = at once).
    void drop_layers_locked(float fade) {
        for (const Layer& l : layers) {
            if (Voice* v = find_voice(l.voice)) {
                if (fade > 0.0f) start_fade(*v, 0.0f, fade, true);
                else erase_voice_locked(l.voice);
            }
        }
        layers.clear();
    }

    // ------------------------------------------------------------- mixing
    // Adds a PCM voice into `out` (its bus's buffer): the same pan law and fade as a clip voice. A dry queue makes silence, not an end.
    void mix_pcm_locked(Voice& v, float* out, int frames) {
        PcmFeed& p = *v.pcm;
        const double step = double(p.rate) / double(deviceRate);
        const float theta = (v.pan + 1.0f) * (kPi * 0.25f);
        const float gl = std::min(1.0f, std::cos(theta) * 1.41421356f);
        const float gr = std::min(1.0f, std::sin(theta) * 1.41421356f);
        const float base = 1.0f;  // the bus and master volumes are applied to the sum of the bus
        const float* d = p.queue.data() + p.head;
        const std::size_t avail = p.frames();
        for (int f = 0; f < frames; ++f) {
            const std::size_t i0 = std::size_t(p.pos);
            if (i0 + 1 >= avail) break;  // underrun: wait for more samples
            const float t = float(p.pos - double(i0));
            const float l = d[2 * i0] + (d[2 * i0 + 2] - d[2 * i0]) * t;
            const float r = d[2 * i0 + 1] + (d[2 * i0 + 3] - d[2 * i0 + 1]) * t;
            const float g = base * v.volume * v.fade;
            out[2 * f] += l * gl * g;
            out[2 * f + 1] += r * gr * g;
            p.pos += step;
            step_volume(v);
            if (v.fadeFrames > 0) {
                v.fade += v.fadeStep;
                if (--v.fadeFrames == 0) {
                    v.fade = v.fadeTarget;
                    if (v.stopAtFadeEnd) { v.dead = true; break; }
                }
            }
        }
        const std::size_t used = std::min(std::size_t(p.pos), avail);
        p.pos -= double(used);
        p.head += 2 * used;
        if (p.head > 0 && p.head * 2 >= p.queue.size()) {  // compact
            p.queue.erase(p.queue.begin(), p.queue.begin() + std::ptrdiff_t(p.head));
            p.head = 0;
        }
    }

    // The effects of one bus on its buffer, in order: low-pass, reverb. `used` = a voice wrote into the buffer this block.
    // Returns whether the buffer can hold sound (a voice, or a reverb tail). A bus without an effect does no work here.
    bool run_effects(BusFx& fx, float* buf, int frames, bool used) {
        if (fx.lpOn) {
            if (fx.lpLog.moving()) {
                fx.lpLog.skip(frames);
                fx.lpDirty = true;
            }
            if (fx.lpDirty) {
                fx.lp.set_cutoff(std::exp2(fx.lpLog.cur), float(deviceRate));
                fx.lpDirty = false;
            }
            if (used) fx.lp.process(buf, frames);
            else fx.lp.clear();
            if (!fx.lpLog.moving() && fx.lpOffAtEnd) {
                fx.lpOn = false;
                fx.lpOffAtEnd = false;
                fx.lp.clear();
            }
        }
        bool live = used;
        if (fx.rvOn && fx.rv) {
            fx.rvMix.skip(frames);
            fx.rvQuiet = used ? 0 : std::min(fx.rvQuiet + frames, long(1) << 40);
            if (used || double(fx.rvQuiet) <= kReverbTail * deviceRate) {
                fx.rv->process(buf, frames, clamp(fx.rvMix.cur, 0.0f, 1.0f));
                live = true;
            }
            if (!fx.rvMix.moving() && fx.rvOffAtEnd) {
                fx.rvOn = false;
                fx.rvOffAtEnd = false;
                fx.rv->clear();
            }
        }
        return live;
    }

    // The volume of a bus (the player's setting times the snapshot's scale) on its buffer; the ramps keep time on a silent bus.
    static void apply_bus_gain(BusFx& fx, float* buf, int frames, bool live) {
        if (!live) {
            fx.vol.skip(frames);
            fx.snap.skip(frames);
            return;
        }
        if (!fx.vol.moving() && !fx.snap.moving()) {
            const float g = fx.vol.cur * fx.snap.cur;
            if (g != 1.0f)
                for (int i = 0; i < frames * 2; ++i) buf[i] *= g;
            return;
        }
        for (int f = 0; f < frames; ++f) {
            const float g = fx.vol.next() * fx.snap.next();
            buf[2 * f] *= g;
            buf[2 * f + 1] *= g;
        }
    }

    // The ducking gain of bus `d` for this block, from the loudness of the bus it listens to: a peak detector (instant attack,
    // 10 ms release) says whether that bus is above the threshold, and the gain follows the target with the attack and release
    // times. Writes the gain per frame into duckGains[d]; the detector and the gain keep their state across blocks.
    void compute_duck(int d, int frames) {
        BusFx& fx = bus[d];
        const float* src = busBuf[fx.duckBy].data();
        std::vector<float>& g = duckGains[d];
        g.resize(std::size_t(frames));
        const float detRelease = std::exp(-1.0f / (0.010f * float(deviceRate)));
        const float low = 1.0f - fx.duck.amount;
        float env = fx.duckEnv, gain = fx.duckGain;
        for (int f = 0; f < frames; ++f) {
            env = std::max(std::max(std::fabs(src[2 * f]), std::fabs(src[2 * f + 1])), env * detRelease);
            const float target = env > kDuckThreshold ? low : 1.0f;
            const float k = target < gain ? fx.duckAttack : fx.duckRelease;
            gain = target + (gain - target) * k;
            g[std::size_t(f)] = gain;
        }
        // Settle the tails so a bus that is back at full volume stops costing anything.
        if (env < kDuckThreshold * 1e-3f) env = 0.0f;
        if (gain > 0.99999f) gain = 1.0f;
        fx.duckEnv = env;
        fx.duckGain = gain;
    }

    // Mixes `frames` stereo frames into `out` (overwrites). Caller holds mu. Every voice is summed into the buffer of its bus;
    // each bus gets its effects, volume and ducking; the buses are summed into `out`, which gets the master's.
    void mix_locked(float* out, int frames) {
        const std::size_t n = std::size_t(frames) * 2;
        std::memset(out, 0, sizeof(float) * n);
        const double rateRatio = double(kRate) / double(deviceRate);
        std::vector<char> used(bus.size(), 0);
        for (std::size_t b = 0; b < bus.size(); ++b) {
            busBuf[b].resize(n);
            std::memset(busBuf[b].data(), 0, sizeof(float) * n);
        }
        for (Voice& v : voices) {
            if (paused) break;
            float* const dst = busBuf[std::size_t(v.bus)].data();
            if (v.pcm) {
                used[std::size_t(v.bus)] = 1;
                mix_pcm_locked(v, dst, frames);
                continue;
            }
            if (v.dead || !v.clip || v.clip->frames == 0) { v.dead = true; continue; }
            used[std::size_t(v.bus)] = 1;
            const Clip& c = *v.clip;
            Stream* const stream = v.stream.get();
            const double n = double(c.frames);
            const double step = double(v.pitch) * rateRatio;
            const float theta = (v.pan + 1.0f) * (kPi * 0.25f);
            // Equal-power pan law normalised to unity at the centre (gain capped at 1 on the loud side).
            const float gl = std::min(1.0f, std::cos(theta) * 1.41421356f);
            const float gr = std::min(1.0f, std::sin(theta) * 1.41421356f);
            const float base = c.gain;  // the bus and master volumes are applied to the sum of the bus
            int first = 0;
            if (v.delay > 0) {  // a voice that waits for its beat: silent, not advancing
                first = int(std::min<long>(v.delay, frames));
                v.delay -= first;
            }
            for (int f = first; f < frames; ++f) {
                float l, r;
                if (stream) {
                    if (!stream->at(v.pos, l, r)) { v.dead = true; break; }
                } else {
                    // With loop points the first pass runs to loopEnd and every later one wraps inside loopStart..loopEnd.
                    const double loopEnd = c.loopEnd > 0 ? double(c.loopEnd) : n, loopStart = double(c.loopStart);
                    if (v.pos >= loopEnd) {
                        if (v.loop) v.pos = loopStart + std::fmod(v.pos - loopStart, loopEnd - loopStart);
                        else if (v.pos >= n) { v.dead = true; break; }
                    }
                    std::size_t i0 = std::size_t(v.pos);
                    if (i0 >= c.frames) i0 = c.frames - 1;
                    std::size_t i1 = i0 + 1;
                    if (v.loop && i1 >= std::size_t(loopEnd)) i1 = c.loopStart;
                    else if (i1 >= c.frames) i1 = i0;
                    const float t = float(v.pos - double(i0));
                    const float* d = c.data.data();
                    l = d[2 * i0] + (d[2 * i1] - d[2 * i0]) * t;
                    r = d[2 * i0 + 1] + (d[2 * i1 + 1] - d[2 * i0 + 1]) * t;
                }
                float g = base * v.volume * v.fade;
                dst[2 * f] += l * gl * g;
                dst[2 * f + 1] += r * gr * g;
                v.pos += step;
                step_volume(v);
                if (v.fadeFrames > 0) {
                    v.fade += v.fadeStep;
                    if (--v.fadeFrames == 0) {
                        v.fade = v.fadeTarget;
                        if (v.stopAtFadeEnd) { v.dead = true; break; }
                    }
                }
            }
        }

        mixedTotal += std::uint64_t(frames);
        if (!paused) {
            auto mix_player = [&](MusicRt& rt) {
                float* const dst = busBuf[std::size_t(rt.bus)].data();
                const bool was = rt.tr->active();
                rt.tr->set_rate_ratio(rateRatio);
                rt.tr->mix(dst, frames);
                if (was || rt.tr->active()) used[std::size_t(rt.bus)] = 1;
            };
            for (auto& rt : musicOrphans) mix_player(*rt);
            for (auto& [key, rt] : musicEnts) mix_player(*rt);
        }
        for (const Voice& v : voices)
            if (v.dead) note_ended_locked(v);
        voices.erase(std::remove_if(voices.begin(), voices.end(), [](const Voice& v) { return v.dead; }), voices.end());
        if (!paused) {
            // The buses go deepest first, a whole depth at a time: effects and volume of each, then the ducking (which reads
            // the buses of that depth, or deeper, before any ducking; a bus nearer the master than the one that ducks is read as
            // its own voices and the buses under it, before its effects), then each bus is summed into its parent.
            std::vector<char> live(bus.size(), 0), ducking(bus.size(), 0);
            bool anyLive = false;
            for (std::size_t from = 0; from < mixOrder.size();) {
                std::size_t to = from;
                const int depth = bus[std::size_t(mixOrder[from])].depth;
                while (to < mixOrder.size() && bus[std::size_t(mixOrder[to])].depth == depth) ++to;
                for (std::size_t k = from; k < to; ++k) {
                    const std::size_t b = std::size_t(mixOrder[k]);
                    live[b] = run_effects(bus[b], busBuf[b].data(), frames, used[b] != 0);
                    apply_bus_gain(bus[b], busBuf[b].data(), frames, live[b] != 0);
                }
                for (std::size_t k = from; k < to; ++k) {
                    const std::size_t b = std::size_t(mixOrder[k]);
                    const BusFx& fx = bus[b];
                    ducking[b] = fx.duckBy >= 0 && (live[b] || live[std::size_t(fx.duckBy)] || used[std::size_t(fx.duckBy)] ||
                                                    fx.duckGain != 1.0f || fx.duckEnv != 0.0f);
                    if (ducking[b]) compute_duck(int(b), frames);
                }
                for (std::size_t k = from; k < to; ++k) {
                    const std::size_t b = std::size_t(mixOrder[k]);
                    if (ducking[b] && live[b]) {
                        float* buf = busBuf[b].data();
                        const float* g = duckGains[b].data();
                        for (int f = 0; f < frames; ++f) {
                            buf[2 * f] *= g[f];
                            buf[2 * f + 1] *= g[f];
                        }
                    }
                    if (live[b]) {
                        const int parent = bus[b].parent;
                        float* dst = parent == kMasterBus ? out : busBuf[std::size_t(parent)].data();
                        const float* buf = busBuf[b].data();
                        for (std::size_t i = 0; i < n; ++i) dst[i] += buf[i];
                        if (parent == kMasterBus) anyLive = true;
                        else used[std::size_t(parent)] = 1;
                    }
                }
                from = to;
            }
            BusFx& master = bus[kMasterBus];
            const bool masterLive = run_effects(master, out, frames, anyLive);
            apply_bus_gain(master, out, frames, masterLive);
        }
        float peak = 0.0f;
        for (int i = 0; i < frames * 2; ++i) {
            float s = out[i];
            s = s > 1.0f ? 1.0f : (s < -1.0f ? -1.0f : s);
            out[i] = s;
            peak = std::max(peak, std::fabs(s));
        }
        lastPeak = peak;
        if (recording) {
            if (rec.size() / 2 + std::size_t(frames) <= kMaxRecordFrames) {
                rec.insert(rec.end(), out, out + std::size_t(frames) * 2);
            } else if (!recWarned) {
                recWarned = true;
                FA_WARN("audio", "audio recording reached the 10 minute limit; further audio is not recorded");
            }
        }
    }

    // sokol_audio stream callback (audio thread).
    void render(float* buffer, int frames, int channels) {
        // Once per device start: proof that the platform really pulls samples (the mobile smoke tests wait for it).
        if (!streamLogged.exchange(true)) FA_INFO("audio", "stream running: first callback of {} frames, {} channels", frames, channels);
        std::lock_guard<std::mutex> lk(mu);
        if (channels == 2) {
            mix_locked(buffer, frames);
            return;
        }
        tmp.resize(std::size_t(frames) * 2);
        mix_locked(tmp.data(), frames);
        for (int f = 0; f < frames; ++f) {
            if (channels == 1) {
                buffer[f] = 0.5f * (tmp[std::size_t(2 * f)] + tmp[std::size_t(2 * f + 1)]);
            } else {
                for (int c = 0; c < channels; ++c) buffer[f * channels + c] = c < 2 ? tmp[std::size_t(2 * f + c)] : 0.0f;
            }
        }
    }

    static void stream_cb(float* buffer, int frames, int channels, void* user) {
        static_cast<Impl*>(user)->render(buffer, frames, channels);
    }

    void advance(double seconds) {
        if (seconds <= 0.0) return;
        std::lock_guard<std::mutex> lk(mu);
        carry += seconds * kRate;
        long total = long(std::floor(carry));
        carry -= double(total);
        nullBuf.resize(std::size_t(kBlock) * 2);
        float peak = 0.0f;
        while (total > 0) {
            int n = int(std::min<long>(total, kBlock));
            mix_locked(nullBuf.data(), n);
            peak = std::max(peak, lastPeak);
            total -= n;
        }
        lastPeak = peak;
    }
};

// ===================================================================== API ====

Audio::Audio() : impl_(std::make_unique<Impl>()) {}

Audio::~Audio() { shutdown(); }

bool Audio::init(bool device, std::string* error) {
    if (impl_->inited) shutdown();
    impl_->deviceRate = kRate;
    impl_->deviceChannels = 2;
    impl_->device = false;
    impl_->autoAdvance = false;
    impl_->streamLogged = false;
    if (device) {
#if defined(__EMSCRIPTEN__)
        // The web has its own device (audio_web.cpp): an AudioWorkletNode, a ScriptProcessorNode as the fallback.
        const int webRate = audio_web_open(kRate, 2, &Impl::stream_cb, impl_.get());
        if (webRate > 0) {
            impl_->device = true;
            impl_->deviceRate = std::max(webRate, 8000);
            impl_->deviceChannels = 2;
            FA_INFO("audio", "output device open: {} Hz, {} channels", impl_->deviceRate, impl_->deviceChannels);
            audio_web_unlock();  // the browser keeps the device silent until the player clicks, touches or presses a key
#else
        saudio_desc desc{};
        desc.sample_rate = kRate;
        desc.num_channels = 2;
        desc.stream_userdata_cb = &Impl::stream_cb;
        desc.user_data = impl_.get();
        saudio_setup(&desc);
        if (saudio_isvalid()) {
            impl_->device = true;
            impl_->deviceRate = std::max(saudio_sample_rate(), 8000);
            impl_->deviceChannels = std::max(saudio_channels(), 1);
            FA_INFO("audio", "output device open: {} Hz, {} channels", impl_->deviceRate, impl_->deviceChannels);
#endif
        } else {
#if !defined(__EMSCRIPTEN__)
            saudio_shutdown();
#endif
            FA_WARN("audio", "no audio output device available; running with a silent null device "
                             "(hint: pass --headless to silence this warning)");
            impl_->autoAdvance = true;
            if (error) error->clear();
        }
    }
    impl_->inited = true;
    return true;
}

void Audio::shutdown() {
    if (!impl_->inited) return;
#if defined(__EMSCRIPTEN__)
    if (impl_->device) audio_web_close();
#else
    if (impl_->device) saudio_shutdown();  // joins the audio thread before we touch state
#endif
    impl_->music_shutdown();
    std::lock_guard<std::mutex> lk(impl_->mu);
    impl_->voices.clear();
    impl_->clips.clear();
    impl_->untraced.clear();
    impl_->ents.clear();
    impl_->videos.clear();
    impl_->musicVoice = 0;
    impl_->musicPath.clear();
    impl_->musicPersist = false;
    impl_->layers.clear();
    impl_->recording = false;
    impl_->rec.clear();
    impl_->device = false;
    impl_->inited = false;
    impl_->lastWorld = nullptr;
    impl_->sceneMusic.clear();
    impl_->sceneMusicVolume = -1.0f;
    impl_->clockWorld = nullptr;
    impl_->playLog.clear();
    impl_->playDropped = 0;
}

bool Audio::load(std::string_view clipPath) { return impl_->get_clip(clipPath) != nullptr; }

std::shared_ptr<const void> Audio::decode_clip(std::string_view clipPath, std::string* error) {
    std::string err;
    auto clip = Impl::decode(fs::normalize(clipPath), &err);
    if (!clip && error) *error = err;
    return clip;
}

bool Audio::clip_loaded(std::string_view clipPath) const {
    const std::string path = fs::normalize(clipPath);
    std::lock_guard<std::mutex> lk(impl_->mu);
    return impl_->clips.count(path) > 0;
}

bool Audio::adopt_clip(std::string_view clipPath, std::shared_ptr<const void> decoded, std::vector<std::string> files) {
    if (!decoded) return false;
    const std::string path = fs::normalize(clipPath);
    std::lock_guard<std::mutex> lk(impl_->mu);
    if (impl_->clips.count(path)) return false;  // loaded on first use meanwhile: that one stays
    impl_->clips.emplace(path, std::static_pointer_cast<const Clip>(decoded));
    impl_->failedLogged.erase(path);
    if (!files.empty()) impl_->untraced[path] = std::move(files);
    return true;
}

VoiceId Audio::play(std::string_view clipPath, const PlayParams& params) { return impl_->start(clipPath, params, ""); }

VoiceId Audio::open_pcm_voice(int sampleRate, const PlayParams& params, std::string_view path, std::string_view source) {
    if (!impl_->inited) {
        FA_ERROR("audio", "Audio::open_pcm_voice('{}') called before Audio::init()", path);
        return 0;
    }
    const VoiceId id = impl_->open_pcm(sampleRate, params);
    {
        std::lock_guard<std::mutex> lk(impl_->mu);
        if (Voice* v = impl_->find_voice(id)) {
            v->path = fs::normalize(path);
            v->source = std::string(source);
        }
    }
    impl_->log_play(path, params, false, source, true, {}, id);
    return id;
}

void Audio::push_pcm(VoiceId voice, const float* stereo, std::size_t frames) {
    std::lock_guard<std::mutex> lk(impl_->mu);
    Voice* v = impl_->find_voice(voice);
    if (!v || !v->pcm || frames == 0) return;
    PcmFeed& p = *v->pcm;
    p.queue.insert(p.queue.end(), stereo, stereo + 2 * frames);
    const std::size_t cap = std::size_t(p.rate) * 2 * 2;  // two seconds; a game that never mixes must not grow it forever
    if (p.queue.size() - p.head > cap) {
        p.head = p.queue.size() - cap;
    }
}

double Audio::pcm_queued_frames(VoiceId voice) const {
    std::lock_guard<std::mutex> lk(impl_->mu);
    const Voice* v = impl_->find_voice(voice);
    if (!v || !v->pcm) return 0.0;
    return std::max(0.0, double(v->pcm->frames()) - v->pcm->pos);
}

bool Audio::has_device() const {
    std::lock_guard<std::mutex> lk(impl_->mu);
    return impl_->device;
}

void Audio::clear_pcm(VoiceId voice) {
    std::lock_guard<std::mutex> lk(impl_->mu);
    Voice* v = impl_->find_voice(voice);
    if (!v || !v->pcm) return;
    v->pcm->queue.clear();
    v->pcm->head = 0;
    v->pcm->pos = 0.0;
}

void Audio::set_voice_bus(VoiceId voice, std::string_view bus) {
    std::lock_guard<std::mutex> lk(impl_->mu);
    Voice* v = impl_->find_voice(voice);
    if (!v) return;
    int b = impl_->bus_index(bus);
    if (b < 0) {
        FA_ERROR("audio", "Unknown audio bus '{}'. {} (using 'sfx')", bus, did_you_mean(bus, impl_->bus_names_locked(false)));
        b = BusSfx;
    }
    v->bus = b;
}

void Audio::stop(VoiceId voice) {
    std::lock_guard<std::mutex> lk(impl_->mu);
    auto& vs = impl_->voices;
    for (const Voice& v : vs)
        if (v.id == voice) impl_->note_ended_locked(v);
    vs.erase(std::remove_if(vs.begin(), vs.end(), [&](const Voice& v) { return v.id == voice; }), vs.end());
    if (impl_->musicVoice == voice) impl_->musicVoice = 0;
}

void Audio::stop_all() {
    std::lock_guard<std::mutex> lk(impl_->mu);
    impl_->ended.clear();
    impl_->voices.clear();
    impl_->musicVoice = 0;
    impl_->musicPath.clear();
    impl_->musicPersist = false;
    impl_->layers.clear();
    // The MusicPlayer components' music too: it fades out over 50 ms and the components read the end (playing = false).
    for (auto& [bits, rt] : impl_->musicEnts) rt->tr->stop(MusicQuantize::None, 0.05f);
    for (auto& rt : impl_->musicOrphans) rt->tr->stop(MusicQuantize::None, 0.05f);
}

void Audio::on_scene_load() {
    Impl& im = *impl_;
    {
        std::lock_guard<std::mutex> lk(im.mu);
        im.ended.clear();  // the scene that asked to be told is gone
        if (im.musicPersist) {
            // The persisted track (or layers) plays on; everything else stops.
            std::vector<VoiceId> keep;
            if (im.musicVoice) keep.push_back(im.musicVoice);
            for (const Impl::Layer& l : im.layers) keep.push_back(l.voice);
            auto& vs = im.voices;
            vs.erase(std::remove_if(vs.begin(), vs.end(),
                                    [&](const Voice& v) { return std::find(keep.begin(), keep.end(), v.id) == keep.end(); }),
                     vs.end());
        } else {
            im.voices.clear();
            im.musicVoice = 0;
            im.musicPath.clear();
            im.layers.clear();
        }
    }
    // The new scene's SceneSettings.music starts from scratch: update() sees it as a change.
    im.sceneMusic.clear();
    im.sceneMusicVolume = -1.0f;
}

bool Audio::is_playing(VoiceId voice) const {
    std::lock_guard<std::mutex> lk(impl_->mu);
    return impl_->find_voice(voice) != nullptr;
}

void Audio::set_voice_volume(VoiceId voice, float volume, float fadeSeconds, bool log) {
    std::lock_guard<std::mutex> lk(impl_->mu);
    Impl& im = *impl_;
    Voice* v = im.find_voice(voice);
    if (!v) return;
    im.start_volume_ramp(*v, volume, fadeSeconds);
    if (!log) return;
    AudioEvent ev;
    ev.kind = "setVoiceVolume";
    ev.voice = voice;
    ev.seq = ++im.playSeq;
    if (const World* w = im.clockWorld ? im.clockWorld : im.lastWorld) {
        ev.frame = w->frame();
        ev.time = w->time();
    }
    ev.path = v->path;
    ev.volume = std::max(volume, 0.0f);
    ev.pitch = v->pitch;
    ev.pan = v->pan;
    ev.fade = std::max(fadeSeconds, 0.0f);
    ev.bus = im.bus[std::size_t(v->bus)].name;
    ev.loop = v->loop;
    ev.source = v->source;
    im.playLog.push_back(std::move(ev));
    if (im.playLog.size() > kMaxPlayLog) {
        im.playLog.pop_front();
        ++im.playDropped;
    }
}

Json Audio::active_voices() const {
    std::lock_guard<std::mutex> lk(impl_->mu);
    const Impl& im = *impl_;
    Json list = Json::array();
    for (const Voice& v : im.voices) {
        if (v.dead) continue;
        const bool music = v.id == im.musicVoice ||
                           std::any_of(im.layers.begin(), im.layers.end(), [&](const Impl::Layer& l) { return l.voice == v.id; });
        list.push_back(Json::object({{"id", v.id}, {"path", v.path}, {"bus", im.bus[std::size_t(v.bus)].name},
                                     {"volume", v.volFrames > 0 ? v.volTarget : v.volume}, {"pitch", v.pitch}, {"pan", v.pan},
                                     {"loop", v.loop}, {"music", music}, {"source", v.source}}));
    }
    return list;
}

std::vector<VoiceId> Audio::take_ended_voices() {
    std::lock_guard<std::mutex> lk(impl_->mu);
    std::vector<VoiceId> out;
    out.swap(impl_->ended);
    return out;
}

namespace {

// The error for a bus name no bus has: what to use, with a "did you mean". `names` are the buses that exist.
Error unknown_bus_error(std::string_view name, const std::vector<std::string>& names, bool allowMaster) {
    std::string list;
    for (const std::string& n : names)
        if (allowMaster || n != "master") list += (list.empty() ? "\"" : ", \"") + n + "\"";
    std::vector<std::string> candidates;
    for (const std::string& n : names)
        if (allowMaster || n != "master") candidates.push_back(n);
    return make_error("Unknown audio bus '" + std::string(name) + "'. " + did_you_mean(name, candidates),
                      "Use one of " + list + (allowMaster ? "" : " (the master has no ducking)") +
                          ". A project declares its own in factoria.json \"audio\".\"buses\".");
}

}  // namespace

// Frames of a fade of `seconds`; no fade (<= 0) is the short ramp that keeps a jump from clicking.
long Audio::Impl::ramp_frames(float seconds, bool declick) const {
    if (seconds > 0.0f) return std::max(1L, long(std::lround(double(seconds) * deviceRate)));
    return declick ? std::max(1L, long(deviceRate / 100)) : 0L;
}

void Audio::set_bus_volume(std::string_view bus, float volume, float fadeSeconds) {
    volume = clamp(volume, 0.0f, kMaxBusVolume);
    std::lock_guard<std::mutex> lk(impl_->mu);
    const int b = impl_->fx_index(bus);
    if (b < 0) {
        FA_ERROR("audio", "{}", unknown_bus_error(bus, impl_->bus_names_locked(true), true).message);
        return;
    }
    impl_->bus[b].vol.set(volume, impl_->ramp_frames(fadeSeconds, true));
}

float Audio::bus_volume(std::string_view bus) const {
    std::lock_guard<std::mutex> lk(impl_->mu);
    const int b = impl_->fx_index(bus);
    return b < 0 ? -1.0f : impl_->bus[b].vol.target;
}

void Audio::set_master_volume(float volume) { set_bus_volume("master", volume, 0.0f); }

Result<void> Audio::set_bus_lowpass(std::string_view bus, float hz, float fadeSeconds) {
    std::lock_guard<std::mutex> lk(impl_->mu);
    const int b = impl_->fx_index(bus);
    if (b < 0) return unknown_bus_error(bus, impl_->bus_names_locked(true), true);
    if (!std::isfinite(hz) || hz < 0.0f)
        return make_error("A low-pass cutoff is a frequency in Hz, got " + std::to_string(hz),
                          "Use 20..20000 Hz, or 0 (or null in a script) to switch the filter off.");
    impl_->set_lowpass_locked(impl_->bus[b], hz, fadeSeconds);
    return {};
}

void Audio::Impl::set_lowpass_locked(BusFx& fx, float hz, float fadeSeconds) {
    const long frames = ramp_frames(fadeSeconds, false);
    if (hz <= 0.0f) {
        fx.lpHz = 0.0f;
        if (!fx.lpOn) return;
        if (frames <= 0) {
            fx.lpOn = false;
            fx.lp.clear();
        } else {
            fx.lpLog.set(std::log2(kLowpassOpen), frames);
            fx.lpOffAtEnd = true;
        }
        return;
    }
    const float top = std::min(kLowpassOpen, 0.49f * float(deviceRate));
    hz = clamp(hz, 20.0f, top);
    if (!fx.lpOn) {
        fx.lpOn = true;
        fx.lp.clear();
        fx.lpLog.set(std::log2(top), 0);  // a new filter starts open
    }
    fx.lpHz = hz;
    fx.lpOffAtEnd = false;
    fx.lpLog.set(std::log2(hz), frames);
    fx.lpDirty = true;
}

Result<void> Audio::set_bus_reverb(std::string_view bus, float mix, float fadeSeconds) {
    std::lock_guard<std::mutex> lk(impl_->mu);
    const int b = impl_->fx_index(bus);
    if (b < 0) return unknown_bus_error(bus, impl_->bus_names_locked(true), true);
    if (!std::isfinite(mix) || mix < 0.0f || mix > 1.0f)
        return make_error("A reverb mix is a number from 0 to 1, got " + std::to_string(mix),
                          "0 is no reverb (and switches it off), 0.3 is a touch of room, 1 is all wet.");
    impl_->set_reverb_locked(impl_->bus[b], mix, fadeSeconds);
    return {};
}

void Audio::Impl::set_reverb_locked(BusFx& fx, float mix, float fadeSeconds) {
    const long frames = ramp_frames(fadeSeconds, false);
    if (mix <= 0.0f) {
        if (!fx.rvOn) return;
        if (frames <= 0) {
            fx.rvOn = false;
            fx.rvMix.set(0.0f, 0);
            if (fx.rv) fx.rv->clear();
        } else {
            fx.rvMix.set(0.0f, frames);
            fx.rvOffAtEnd = true;
        }
        return;
    }
    if (!fx.rv) fx.rv = std::make_unique<audio_detail::Reverb>(float(deviceRate));
    if (!fx.rvOn) {
        fx.rvOn = true;
        fx.rv->clear();
        fx.rvQuiet = 0;
        fx.rvMix.set(0.0f, 0);
    }
    fx.rvOffAtEnd = false;
    fx.rvMix.set(mix, frames);
}

Result<void> Audio::set_bus_duck(std::string_view bus, const DuckSettings& duck) {
    std::lock_guard<std::mutex> lk(impl_->mu);
    const int b = impl_->fx_index(bus);
    if (b < 0 || b == kMasterBus) return unknown_bus_error(bus, impl_->bus_names_locked(true), false);
    int by = -1;
    if (!std::isfinite(duck.amount) || duck.amount < 0.0f || duck.amount > 1.0f)
        return make_error("A duck amount is the fraction of the volume removed, 0..1, got " + std::to_string(duck.amount),
                          "0.5 halves the bus while the other one plays, 1 silences it, 0 turns ducking off.");
    if (!duck.by.empty() && duck.amount > 0.0f) {
        by = impl_->fx_index(duck.by);
        if (by < 0 || by == kMasterBus) return unknown_bus_error(duck.by, impl_->bus_names_locked(true), false);
        if (by == b)
            return make_error("The bus '" + std::string(bus) + "' cannot duck itself",
                              "Name the other bus, for example the voice-over bus that should push the music down.");
        if (!std::isfinite(duck.attack) || !std::isfinite(duck.release) || duck.attack < 0.0f || duck.release < 0.0f)
            return make_error("Duck attack and release are times in seconds, 0 or more",
                              "Typical values: attack 0.05, release 0.5.");
    }
    impl_->set_duck_locked(impl_->bus[std::size_t(b)], by, duck);
    return {};
}

void Audio::Impl::set_duck_locked(BusFx& fx, int by, const DuckSettings& duck) {
    fx.duckBy = by;
    if (by < 0) {
        fx.duck = DuckSettings{};
        return;  // the gain and the detector settle back to 1 and 0 by themselves
    }
    fx.duck = duck;
    const auto coef = [&](float seconds) { return seconds <= 0.0f ? 0.0f : std::exp(-1.0f / (seconds * float(deviceRate))); };
    fx.duckAttack = coef(duck.attack);
    fx.duckRelease = coef(duck.release);
}

void Audio::set_buses(const std::vector<AudioBusDef>& defs) {
    std::lock_guard<std::mutex> lk(impl_->mu);
    Impl& im = *impl_;
    std::vector<BusFx> old = std::move(im.bus);
    std::vector<std::string> oldDuckBy;  // by name: the indexes change with the table
    for (const BusFx& fx : old) oldDuckBy.push_back(fx.duckBy >= 0 ? old[std::size_t(fx.duckBy)].name : std::string());
    const std::vector<std::string> oldNames = [&] {
        std::vector<std::string> n;
        for (const BusFx& fx : old) n.push_back(fx.name);
        return n;
    }();
    im.reset_bus_table();
    for (int i = 0; i <= kMasterBus; ++i) im.bus[std::size_t(i)] = std::move(old[std::size_t(i)]);
    // Accept the buses whose parent is known, repeating until nothing more is placed (a parent may be declared after its child).
    std::vector<bool> placed(defs.size(), false);
    for (bool progress = true; progress;) {
        progress = false;
        for (std::size_t d = 0; d < defs.size(); ++d) {
            if (placed[d]) continue;
            const AudioBusDef& def = defs[d];
            const int parent = im.fx_index(def.parent.empty() ? "master" : def.parent);
            if (parent < 0 || im.fx_index(def.name) >= 0) continue;
            BusFx fx;
            for (std::size_t o = 0; o < oldNames.size(); ++o)
                if (oldNames[o] == def.name) { fx = std::move(old[o]); break; }
            fx.name = def.name;
            fx.parent = parent;
            im.bus.push_back(std::move(fx));
            placed[d] = true;
            progress = true;
        }
    }
    for (std::size_t d = 0; d < defs.size(); ++d)
        if (!placed[d])
            FA_ERROR("audio", "audio bus '{}' is skipped: its parent '{}' is not a bus, it loops, or the name is taken "
                              "(`factoria validate` checks \"audio\".\"buses\")", defs[d].name, defs[d].parent);
    for (std::size_t i = 0; i < im.bus.size(); ++i) {
        BusFx& fx = im.bus[i];
        const auto was = std::find(oldNames.begin(), oldNames.end(), fx.name);
        if (was == oldNames.end() || oldDuckBy[std::size_t(was - oldNames.begin())].empty()) continue;
        const int by = im.bus_index(oldDuckBy[std::size_t(was - oldNames.begin())]);
        if (by >= 0 && by != int(i)) fx.duckBy = by;
        else im.set_duck_locked(fx, -1, DuckSettings{});
    }
    im.build_mix_order();
    // Music players follow their bus by name; one whose bus is gone plays on "music".
    auto follow = [&](MusicRt& rt) {
        const int b = im.bus_index(rt.busName);
        rt.bus = b < 0 ? int(BusMusic) : b;
    };
    for (auto& [bits, rt] : im.musicEnts) follow(*rt);
    for (auto& rt : im.musicOrphans) follow(*rt);
    // Voices on a bus that no longer exists go to sfx.
    for (Voice& v : im.voices) {
        if (v.bus < kFirstProjectBus) continue;
        const std::string& was = v.bus < int(oldNames.size()) ? oldNames[std::size_t(v.bus)] : std::string();
        const int now = im.bus_index(was);
        v.bus = now < 0 ? int(BusSfx) : now;
    }
}

std::vector<std::string> Audio::bus_names() const {
    std::lock_guard<std::mutex> lk(impl_->mu);
    return impl_->bus_names_locked(true);
}

Json Audio::bus_state(std::string_view bus) const {
    std::lock_guard<std::mutex> lk(impl_->mu);
    const int b = impl_->fx_index(bus);
    if (b < 0) return Json();
    return impl_->bus_state_json(impl_->bus[std::size_t(b)]);
}

Json Audio::Impl::bus_state_json(const BusFx& fx) const {
    Json j = Json::object();
    j["volume"] = fx.vol.target;
    j["snapshotVolume"] = fx.snap.target;
    j["lowpass"] = fx.lpHz;
    j["reverb"] = fx.rvOn ? fx.rvMix.target : 0.0f;
    if (fx.duckBy >= 0) {
        j["duck"] = Json::object({{"by", bus[std::size_t(fx.duckBy)].name}, {"amount", fx.duck.amount}, {"attack", fx.duck.attack},
                                  {"release", fx.duck.release}});
    } else {
        j["duck"] = nullptr;
    }
    return j;
}

void Audio::set_snapshots(AudioSnapshots catalog) {
    std::lock_guard<std::mutex> lk(impl_->mu);
    impl_->snapshots = std::move(catalog);
}

std::vector<std::string> Audio::snapshot_names() const {
    std::lock_guard<std::mutex> lk(impl_->mu);
    std::vector<std::string> names;
    for (const auto& [name, snap] : impl_->snapshots) names.push_back(name);
    return names;
}

std::string Audio::current_snapshot() const {
    std::lock_guard<std::mutex> lk(impl_->mu);
    return impl_->snapshotName;
}

Result<void> Audio::apply_snapshot(std::string_view name, float fadeSeconds) {
    std::lock_guard<std::mutex> lk(impl_->mu);
    Impl& im = *impl_;
    auto it = im.snapshots.find(std::string(name));
    if (it == im.snapshots.end()) {
        std::vector<std::string> names;
        for (const auto& [n, snap] : im.snapshots) names.push_back(n);
        if (names.empty())
            return make_error("There is no audio snapshot '" + std::string(name) + "': the game declares none",
                              "Add \"audio\": {\"snapshots\": {\"" + std::string(name) +
                                  "\": {\"buses\": {\"music\": {\"lowpass\": 800}}}}} to factoria.json (docs/SCRIPTING.md, \"Audio buses\").");
        return make_error("Unknown audio snapshot '" + std::string(name) + "'. " + did_you_mean(name, names),
                          "The snapshots of factoria.json \"audio.snapshots\" are: " + join(names, ", ") + ".");
    }
    const AudioSnapshot& snap = it->second;
    const float fade = fadeSeconds >= 0.0f ? fadeSeconds : snap.fade;
    static const BusSnapshot neutral;
    for (int b = 0; b < int(im.bus.size()); ++b) {
        auto entry = snap.buses.find(im.bus[std::size_t(b)].name);
        const BusSnapshot& want = entry != snap.buses.end() ? entry->second : neutral;
        BusFx& fx = im.bus[std::size_t(b)];
        fx.snap.set(want.volume, im.ramp_frames(fade, true));
        im.set_lowpass_locked(fx, want.lowpass, fade);
        im.set_reverb_locked(fx, want.reverb, fade);
        int by = -1;
        if (want.duck && b != kMasterBus && want.duck->amount > 0.0f) by = im.bus_index(want.duck->by);
        if (by >= 0 && by != kMasterBus && by != b) im.set_duck_locked(fx, by, *want.duck);
        else im.set_duck_locked(fx, -1, DuckSettings{});
    }
    im.snapshotName = std::string(name);
    return {};
}

void Audio::reset_bus_effects() {
    std::lock_guard<std::mutex> lk(impl_->mu);
    for (BusFx& fx : impl_->bus) {
        fx.snap.set(1.0f, 0);
        impl_->set_lowpass_locked(fx, 0.0f, 0.0f);
        impl_->set_reverb_locked(fx, 0.0f, 0.0f);
        impl_->set_duck_locked(fx, -1, DuckSettings{});
        fx.duckGain = 1.0f;
        fx.duckEnv = 0.0f;
    }
    impl_->snapshotName.clear();
}

void Audio::play_music(std::string_view clipPath, float volume, float fadeSeconds, bool persist) {
    auto clip = impl_->get_clip(clipPath);
    PlayParams p;
    p.volume = volume;
    p.loop = true;
    p.bus = "music";
    bool retune = false;  // the track is already playing: not a new play, so not logged
    {
        std::lock_guard<std::mutex> lk(impl_->mu);
        retune = clip && impl_->find_voice(impl_->musicVoice) && impl_->musicPath == clip->path;
    }
    if (!retune) impl_->log_play(clipPath, p, true, "", clip != nullptr);
    if (!clip) return;
    std::string err;
    std::unique_ptr<Stream> stream = retune ? nullptr : Impl::open_stream(*clip, true, &err);
    if (clip->encoded && !retune && !stream) {
        FA_ERROR("audio", "Music '{}' cannot be streamed: {}", clipPath, err);
        return;
    }
    std::lock_guard<std::mutex> lk(impl_->mu);
    Impl& im = *impl_;
    im.drop_layers_locked(std::max(fadeSeconds, 0.0f));
    if (Voice* cur = im.find_voice(im.musicVoice)) {
        if (im.musicPath == clip->path) {  // already playing this track: just retune
            cur->volume = std::max(volume, 0.0f);
            cur->volFrames = 0;
            im.musicPersist = persist;
            if (cur->fadeTarget < 1.0f) im.start_fade(*cur, 1.0f, std::max(fadeSeconds, 0.0f), false);
            return;
        }
        if (fadeSeconds > 0.0f) {
            im.start_fade(*cur, 0.0f, fadeSeconds, true);
        } else {
            im.erase_voice_locked(cur->id);
        }
    }
    VoiceId id = im.add_voice_locked(clip, p, std::move(stream));
    if (Voice* v = im.find_voice(id)) {
        v->protect = true;
        if (fadeSeconds > 0.0f) {
            v->fade = 0.0f;
            im.start_fade(*v, 1.0f, fadeSeconds, false);
        }
    }
    im.musicVoice = id;
    im.musicPath = clip->path;
    im.musicPersist = persist;
}

bool Audio::play_music_layers(const std::vector<MusicLayer>& layers, float volume, float fadeSeconds, bool persist) {
    Impl& im = *impl_;
    if (layers.empty()) return false;
    struct Loaded {
        std::shared_ptr<const Clip> clip;
        std::unique_ptr<Stream> stream;
        const MusicLayer* spec;
    };
    PlayParams p;
    p.volume = volume;
    p.loop = true;
    p.bus = "music";
    std::vector<Loaded> loaded;
    bool ok = true;
    for (const MusicLayer& l : layers) {  // decode and open the streams outside the lock
        auto clip = im.get_clip(l.path);
        im.log_play(l.path, p, true, "", clip != nullptr, l.name);
        if (!clip) { ok = false; continue; }
        std::string err;
        std::unique_ptr<Stream> stream = Impl::open_stream(*clip, true, &err);
        if (clip->encoded && !stream) {
            FA_ERROR("audio", "Music layer '{}' ('{}') cannot be streamed: {}", l.name, l.path, err);
            ok = false;
            continue;
        }
        loaded.push_back({std::move(clip), std::move(stream), &l});
    }
    if (!ok || loaded.empty()) return false;  // all or nothing: a missing layer would drift out of the mix
    // One lock for every voice: the device callback takes the same mutex, so no block of audio holds some layers only.
    std::lock_guard<std::mutex> lk(im.mu);
    if (Voice* cur = im.find_voice(im.musicVoice)) {
        if (fadeSeconds > 0.0f) im.start_fade(*cur, 0.0f, fadeSeconds, true);
        else im.erase_voice_locked(cur->id);
    }
    im.musicVoice = 0;
    im.musicPath.clear();
    im.drop_layers_locked(std::max(fadeSeconds, 0.0f));
    for (Loaded& l : loaded) {
        const float level = std::max(l.spec->level, 0.0f);
        PlayParams lp = p;
        lp.volume = volume * level;
        const VoiceId id = im.add_voice_locked(l.clip, lp, std::move(l.stream));
        if (Voice* v = im.find_voice(id)) {
            v->protect = true;
            if (fadeSeconds > 0.0f) {
                v->fade = 0.0f;
                im.start_fade(*v, 1.0f, fadeSeconds, false);
            }
        }
        im.layers.push_back({l.spec->name, id, level});
    }
    im.layerVolume = volume;
    im.musicPersist = persist;
    return true;
}

bool Audio::set_layer(std::string_view name, float level, float fadeSeconds) {
    std::lock_guard<std::mutex> lk(impl_->mu);
    Impl& im = *impl_;
    for (Impl::Layer& l : im.layers) {
        if (l.name != name) continue;
        l.level = std::max(level, 0.0f);
        if (Voice* v = im.find_voice(l.voice)) im.start_volume_ramp(*v, im.layerVolume * l.level, fadeSeconds);
        return true;
    }
    return false;
}

std::vector<std::string> Audio::layer_names() const {
    std::lock_guard<std::mutex> lk(impl_->mu);
    std::vector<std::string> out;
    for (const Impl::Layer& l : impl_->layers) out.push_back(l.name);
    return out;
}

void Audio::stop_music(float fadeSeconds) {
    std::lock_guard<std::mutex> lk(impl_->mu);
    Impl& im = *impl_;
    if (Voice* cur = im.find_voice(im.musicVoice)) {
        if (fadeSeconds > 0.0f) im.start_fade(*cur, 0.0f, fadeSeconds, true);
        else im.erase_voice_locked(cur->id);
    }
    im.drop_layers_locked(std::max(fadeSeconds, 0.0f));
    im.musicVoice = 0;
    im.musicPath.clear();
    im.musicPersist = false;
}

void Audio::set_paused(bool paused) {
    std::lock_guard<std::mutex> lk(impl_->mu);
    impl_->paused = paused;
}

bool Audio::paused() const {
    std::lock_guard<std::mutex> lk(impl_->mu);
    return impl_->paused;
}

void Audio::advance_null_device(double seconds) { impl_->advance(seconds); }

void Audio::set_clock(const World* world) { impl_->clockWorld = world; }

std::vector<AudioEvent> Audio::play_log(std::uint64_t afterSeq) const {
    std::lock_guard<std::mutex> lk(impl_->mu);
    std::vector<AudioEvent> out;
    for (const AudioEvent& ev : impl_->playLog)
        if (ev.seq > afterSeq) out.push_back(ev);
    return out;
}

void Audio::clear_play_log() {
    std::lock_guard<std::mutex> lk(impl_->mu);
    impl_->playLog.clear();
    impl_->playDropped = 0;
}

std::uint64_t Audio::play_log_dropped() const {
    std::lock_guard<std::mutex> lk(impl_->mu);
    return impl_->playDropped;
}

Json AudioEvent::to_json() const {
    return Json::object({{"kind", kind}, {"voice", voice}, {"fade", fade}, {"seq", seq}, {"frame", frame}, {"time", time}, {"path", path}, {"volume", volume},
                         {"pitch", pitch}, {"pan", pan}, {"bus", bus}, {"loop", loop}, {"music", music},
                         {"source", source}, {"ok", ok}, {"layer", layer}});
}

void Audio::start_recording() {
    std::lock_guard<std::mutex> lk(impl_->mu);
    impl_->rec.clear();
    impl_->recording = true;
    impl_->recWarned = false;
    impl_->recRate = impl_->deviceRate;
}

bool Audio::stop_recording(std::string_view wavPath, std::string* error, std::vector<std::int16_t>* pcmOut, int* rateOut) {
    std::vector<float> rec;
    int rate;
    {
        std::lock_guard<std::mutex> lk(impl_->mu);
        if (!impl_->recording) {
            if (error) *error = "audio recording was not started (hint: call start_recording() first)";
            return false;
        }
        impl_->recording = false;
        rec = std::move(impl_->rec);
        impl_->rec.clear();
        rate = impl_->recRate;
    }
    if (pcmOut) {  // the mix as 16-bit stereo for a video file
        pcmOut->resize(rec.size());
        for (std::size_t i = 0; i < rec.size(); ++i) {
            const float s = rec[i] > 1.0f ? 1.0f : (rec[i] < -1.0f ? -1.0f : rec[i]);
            (*pcmOut)[i] = std::int16_t(std::lround(s * 32767.0f));
        }
        if (rateOut) *rateOut = rate;
    }
    if (wavPath.empty()) return true;
    const std::uint32_t dataBytes = std::uint32_t(rec.size() * 2);
    std::vector<std::uint8_t> out;
    out.reserve(44 + dataBytes);
    auto tag = [&](const char* s) { for (int i = 0; i < 4; ++i) out.push_back(std::uint8_t(s[i])); };
    tag("RIFF"); write_le32(out, 36 + dataBytes); tag("WAVE");
    tag("fmt "); write_le32(out, 16); write_le16(out, 1); write_le16(out, 2);
    write_le32(out, std::uint32_t(rate)); write_le32(out, std::uint32_t(rate) * 4); write_le16(out, 4); write_le16(out, 16);
    tag("data"); write_le32(out, dataBytes);
    for (float s : rec) {
        s = s > 1.0f ? 1.0f : (s < -1.0f ? -1.0f : s);
        write_le16(out, std::uint16_t(std::int16_t(std::lround(s * 32767.0f))));
    }
    auto r = fs::write_bytes(wavPath, out.data(), out.size());
    if (!r) {
        if (error) *error = r.error().to_string();
        return false;
    }
    return true;
}

Json Audio::stats() const {
    std::lock_guard<std::mutex> lk(impl_->mu);
    const Impl& im = *impl_;
    Json j = Json::object();
    j["device"] = im.device;
    j["sampleRate"] = im.deviceRate;
    j["activeVoices"] = im.voices.size();
    j["loadedClips"] = im.clips.size();
    Json names = Json::array();
    for (const auto& [path, clip] : im.clips) names.push_back(path);
    j["clips"] = names;
    std::size_t decoded = 0;  // PCM resident: clips decoded whole, plus the buffers of the voices that stream
    Json streamed = Json::array();
    for (const auto& [path, clip] : im.clips) {
        decoded += clip->data.size() * sizeof(float);
        if (clip->encoded) streamed.push_back(path);
    }
    for (const Voice& v : im.voices)
        if (v.stream) decoded += v.stream->resident_bytes();
    j["decodedBytes"] = decoded;
    j["streamedClips"] = streamed;
    j["peak"] = im.lastPeak;
    j["master"] = im.bus[kMasterBus].vol.target;
    Json buses = Json::object();
    Json effects = Json::object();
    Json parents = Json::object();
    for (std::size_t i = 0; i < im.bus.size(); ++i) {
        const BusFx& fx = im.bus[i];
        if (int(i) != kMasterBus) {
            buses[fx.name] = fx.vol.target;
            parents[fx.name] = im.bus[std::size_t(fx.parent)].name;
        }
        effects[fx.name] = im.bus_state_json(fx);
    }
    j["busParents"] = parents;
    j["buses"] = buses;
    j["busEffects"] = effects;
    j["snapshot"] = im.snapshotName;
    j["music"] = im.musicPath;
    j["recording"] = im.recording;
    j["recordedSeconds"] = double(im.rec.size() / 2) / double(im.recRate);
    return j;
}

void Audio::reload_clip(std::string_view pathIn) {
    std::string path = fs::normalize(pathIn);
    std::string err;
    auto clip = impl_->decode(path, &err);
    if (!clip) {
        FA_ERROR("audio", "reload failed, keeping the previous version: {}", err);
        return;
    }
    std::lock_guard<std::mutex> lk(impl_->mu);
    impl_->clips[path] = clip;
    impl_->failedLogged.erase(path);
    for (Voice& v : impl_->voices) {
        // A voice that streams goes on with the file it opened; so does one on a clip that now streams.
        if (v.clip && v.clip->path == path && !v.stream && !clip->encoded) {
            v.clip = clip;
            if (v.pos >= double(clip->frames)) v.pos = v.loop ? std::fmod(v.pos, double(clip->frames)) : double(clip->frames);
        }
    }
    // A song played from its rendered stems has them cached: a stem file that changed is a song that changed.
    std::vector<std::string> songs;
    for (const auto& [key, src] : impl_->musicCache)
        if (key.size() > 6 && key.compare(key.size() - 6, 6, "|stems") == 0) songs.push_back(key.substr(0, key.size() - 6));
    for (const std::string& song : songs) {
        const MusicStemPlan plan = music_stem_plan_of(song);
        bool uses = plan.mixPath == path;
        for (const MusicStemFile& f : plan.files) uses = uses || f.path == path;
        if (uses) impl_->music_invalidate(song);
    }
}

void Audio::reload_song(std::string_view songPath) {
    const std::string song = fs::normalize(songPath);
    if (song.empty()) return;
    impl_->music_invalidate(song);
}

// ============================================================ adaptive music ==

namespace {

std::string music_cache_key(const std::string& song, MusicMode mode) { return song + (mode == MusicMode::Stems ? "|stems" : "|live"); }

float music_unit(float v) { return std::isfinite(v) ? clamp(v, 0.0f, 1.0f) : 0.0f; }

const char* const kNoPlayer = "the entity has no MusicPlayer component";

}  // namespace

MusicRt* Audio::Impl::music_find(const World& world, Entity e) {
    auto it = musicEnts.find(e.bits());
    if (it == musicEnts.end() || it->second->world != &world || it->second->id != world.id_of(e)) return nullptr;
    return it->second.get();
}

MusicRt& Audio::Impl::music_get(World& world, Entity e) {
    if (MusicRt* rt = music_find(world, e)) return *rt;
    auto old = musicEnts.find(e.bits());
    if (old != musicEnts.end()) music_orphan(old->second.get());  // a slot reused after World::clear(), or another world
    auto rt = std::make_unique<MusicRt>();
    rt->e = e;
    rt->id = world.id_of(e);
    rt->world = &world;
    rt->seen = stamp;
    MusicRt& ref = *rt;
    std::lock_guard<std::mutex> lk(mu);
    musicEnts[e.bits()] = std::move(rt);
    return ref;
}

// The player of a gone entity keeps sounding in `musicOrphans` (a player of the next scene with the same song adopts it; update() fades
// the rest out).
void Audio::Impl::music_orphan(MusicRt* rt) {
    std::lock_guard<std::mutex> lk(mu);
    auto it = musicEnts.find(rt->e.bits());
    if (it == musicEnts.end() || it->second.get() != rt) return;
    musicOrphans.push_back(std::move(it->second));
    musicEnts.erase(it);
}

// Finds the source of rt.song for the mode its component asks: the cache, a load in flight, or a new load (on the game thread when the
// output is the null device or the web, so a headless run has the music at once; on a worker otherwise).
void Audio::Impl::music_request(MusicRt& rt, const MusicPlayer& mp) {
    rt.src.reset();
    rt.error.clear();
    rt.waitKey.clear();
    rt.announcedReady = false;
    if (rt.song.empty()) return;
    MusicStemPlan plan = music_stem_plan_of(rt.song);
    std::string why;
    const MusicMode mode = music_resolve_mode(mp.mode, musicDevice, !plan.files.empty(), &why);
    if (mp.mode == MusicMode::Stems && plan.files.empty())
        FA_WARN("audio", "MusicPlayer on '{}': mode is \"stems\" but '{}' has no stem files in assets.json; playing it live "
                         "(hint: run music.render on the song, or set mode to \"auto\" or \"live\")", rt.id, rt.song);
    const std::string key = music_cache_key(rt.song, mode);
    rt.waitKey = key;
    rt.resolved = mode;
    rt.epoch = musicEpoch;
    if (musicCache.find(key) == musicCache.end() && musicLoads.find(key) == musicLoads.end()) {
        auto load = std::make_shared<MusicLoad>();
        load->key = key;
        load->path = rt.song;
        load->mode = mode;
        load->plan = std::move(plan);
        musicLoads[key] = load;
        musicErrors.erase(key);
#if defined(__EMSCRIPTEN__)
        const bool async = false;
#else
        const bool async = device && !autoAdvance;
#endif
        if (async) load->worker = std::thread([load] { load->run(); });
        else load->run();
    }
    music_poll();
    music_resolve(rt);
}

// Moves the loads that finished into the cache; drops the sources nobody plays when the cache is over its size.
void Audio::Impl::music_poll() {
    for (auto it = musicStale.begin(); it != musicStale.end();) {
        if (!(*it)->done) {
            ++it;
            continue;
        }
        if ((*it)->worker.joinable()) (*it)->worker.join();
        it = musicStale.erase(it);
    }
    for (auto it = musicLoads.begin(); it != musicLoads.end();) {
        MusicLoad& l = *it->second;
        if (!l.done) {
            ++it;
            continue;
        }
        if (l.worker.joinable()) l.worker.join();
        if (l.source) {
            if (!l.note.empty()) FA_WARN("audio", "song '{}' plays live instead of from its stems: {}", l.path, l.note);
            musicCache[l.key] = l.source;
            std::size_t total = 0;
            for (auto& [k, v] : musicCache) total += v->bytes();
            for (auto c = musicCache.begin(); total > kMusicCacheBytes && c != musicCache.end();) {
                if (c->first != l.key && c->second.use_count() == 1) {
                    total -= c->second->bytes();
                    c = musicCache.erase(c);
                } else {
                    ++c;
                }
            }
        } else {
            musicErrors[l.key] = l.error;
            FA_ERROR("audio", "the song '{}' cannot be played: {}", l.path, l.error);
        }
        it = musicLoads.erase(it);
    }
}

void Audio::Impl::music_resolve(MusicRt& rt) {
    if (rt.waitKey.empty()) return;
    auto c = musicCache.find(rt.waitKey);
    if (c != musicCache.end()) {
        rt.src = c->second;
        rt.waitKey.clear();
    } else if (musicLoads.find(rt.waitKey) == musicLoads.end()) {
        auto err = musicErrors.find(rt.waitKey);
        rt.error = err != musicErrors.end() ? err->second : std::string("the song could not be loaded");
        rt.waitKey.clear();
    }
}

void Audio::Impl::music_events(World& world, MusicRt& rt) {
    musicScratch.clear();
    {
        std::lock_guard<std::mutex> lk(mu);
        rt.tr->take_events(musicScratch);
    }
    for (const MusicEvent& ev : musicScratch) {
        const MusicMap* map = ev.src ? &ev.src->map : nullptr;
        auto section = [&](int i) { return map && i >= 0 && std::size_t(i) < map->sections.size() ? map->sections[std::size_t(i)].name : std::string(); };
        Json d = Json::object({{"id", rt.id}, {"song", ev.src ? ev.src->path : rt.song}, {"frame", ev.frame},
                               {"time", double(ev.frame) / double(std::max(deviceRate, 1))}});
        const char* name = "music.beat";
        switch (ev.kind) {
            case MusicEventKind::Beat:
                name = "music.beat";
                d["bar"] = ev.a;
                d["beat"] = ev.b;
                d["section"] = section(ev.c);
                d["index"] = ev.d;
                break;
            case MusicEventKind::Bar:
                name = "music.bar";
                d["bar"] = ev.a;
                d["section"] = section(ev.b);
                d["count"] = ev.c;
                break;
            case MusicEventKind::Section:
                name = "music.section";
                d["section"] = section(ev.a);
                d["pass"] = ev.b;
                d["bar"] = ev.c;
                break;
            case MusicEventKind::Loop:
                name = "music.loop";
                d["count"] = ev.a;
                break;
            case MusicEventKind::Ended:
                name = "music.ended";
                d["stopped"] = ev.a == 1;
                break;
            case MusicEventKind::Stinger:
                name = "music.stinger";
                d["kind"] = ev.a == 0 ? "clip" : "section";
                d["section"] = ev.a == 0 ? Json(nullptr) : Json(section(ev.b));
                break;
            case MusicEventKind::Crossfade:
                name = "music.crossfade";
                break;
        }
        world.events().game.push_back(GameEvent{name, std::move(d), rt.e});
    }
    musicScratch.clear();
    std::lock_guard<std::mutex> lk(mu);
    rt.tr->prune_sources();
}

// One MusicPlayer component against its player in the mixer: starts, stops, changes of song, volume, bus and intensity.
void Audio::Impl::music_drive(World& world, Entity e, MusicPlayer& mp, MusicRt& rt) {
    (void)e;
    const std::string want = mp.song.empty() ? std::string() : fs::normalize(mp.song);
    bool adopted = false;
    if (rt.first) {
        rt.first = false;
        if (!want.empty() && mp.playOnStart) {
            for (auto o = musicOrphans.begin(); o != musicOrphans.end(); ++o) {
                MusicRt& old = **o;
                if (old.song != want || !old.src || old.sent != old.src || old.stopIssued || !old.tr->playing()) continue;
                {
                    std::lock_guard<std::mutex> lk(mu);
                    rt.tr = std::move(old.tr);
                    rt.busName = old.busName;
                    rt.bus = old.bus;
                    musicOrphans.erase(o);
                }
                // `old` is gone: what is left to do uses the player that took its place.
                break;
            }
            adopted = rt.tr->playing() && !rt.tr->ended();
        }
        if (adopted) {
            rt.song = want;
            rt.playing = true;
            mp.playing = true;
            // The source the adopted transport plays: ask the cache (it still holds it) so rt.src matches what is sounding.
            rt.waitKey.clear();
            std::string why;
            const MusicStemPlan plan = music_stem_plan_of(want);
            const MusicMode mode = music_resolve_mode(mp.mode, musicDevice, !plan.files.empty(), &why);
            auto c = musicCache.find(music_cache_key(want, mode));
            if (c != musicCache.end()) {
                rt.src = c->second;
                rt.sent = c->second;
                rt.resolved = mode;
                rt.epoch = musicEpoch;
            } else {
                adopted = false;
                std::lock_guard<std::mutex> lk(mu);
                rt.tr->stop(MusicQuantize::None, 0.05f);
            }
        } else if (mp.playOnStart && !mp.playing) {
            mp.playing = true;
        }
    }
    MusicTransport& tr = *rt.tr;

    if (mp.bus != rt.busName) {
        std::lock_guard<std::mutex> lk(mu);
        int b = bus_index(mp.bus);
        if (b < 0) {
            FA_ERROR("audio", "MusicPlayer on '{}': unknown audio bus '{}'. {} (using 'music')", rt.id, mp.bus,
                     did_you_mean(mp.bus, bus_names_locked(false)));
            b = BusMusic;
        }
        rt.busName = mp.bus;
        rt.bus = b;
    }

    if (want != rt.song) {
        rt.song = want;
        if (want.empty()) {
            rt.src.reset();
            rt.waitKey.clear();
            rt.error.clear();
            if (rt.sent) {
                std::lock_guard<std::mutex> lk(mu);
                tr.stop(MusicQuantize::None, 0.3f);
            }
            rt.sent.reset();
        } else {
            music_request(rt, mp);
        }
    } else if (!rt.waitKey.empty()) {
        music_poll();
        music_resolve(rt);
    }
    // Its song changed on disk, or the device it runs on is another one now and `auto` picks another mode: fetch the source again and
    // crossfade to it at the beat, in the section that sounds (a section the new version lacks starts it at the beginning).
    if (!rt.song.empty()) {
        bool refetch = rt.reload;
        if (!refetch && rt.epoch != musicEpoch && rt.src) {
            rt.epoch = musicEpoch;
            if (mp.mode == MusicMode::Auto) {
                const MusicStemPlan plan = music_stem_plan_of(rt.song);
                refetch = music_resolve_mode(mp.mode, musicDevice, !plan.files.empty()) != rt.resolved;
            }
        }
        if (refetch) {
            rt.reload = false;
            std::string current;
            if (mp.playing && rt.sent) {
                std::lock_guard<std::mutex> lk(mu);
                if (tr.playing()) current = tr.status().section;
            }
            if (!current.empty()) {
                rt.entry = MusicRt::Entry{};
                rt.entry.set = true;
                rt.entry.section = current;
                rt.entry.quantize = MusicQuantize::Beat;
                rt.entry.bars = 0.5f;
                rt.entry.lenient = true;
            }
            music_request(rt, mp);
        }
    }
    if (rt.src && !rt.announcedReady) {
        rt.announcedReady = true;
        world.events().game.push_back(GameEvent{"music.ready", Json::object({{"id", rt.id}, {"song", rt.song}, {"mode", rt.src->mode}}), rt.e});
    }

    // playing -> not playing
    if (mp.playing != rt.playing) {
        if (!mp.playing && !rt.stopIssued) {
            std::lock_guard<std::mutex> lk(mu);
            tr.stop(MusicQuantize::None, 0.3f);
        }
        if (!mp.playing) rt.sent.reset();
        rt.stopIssued = !mp.playing;
        rt.playing = mp.playing;
    }

    // hand the source to the transport
    if (mp.playing && rt.src && rt.sent != rt.src) {
        const MusicMap& map = rt.src->map;
        const std::string& wanted = rt.entry.section.empty() ? mp.startSection : rt.entry.section;
        int section = -1;
        if (!wanted.empty()) {
            section = map.section_index(wanted);
            if (section < 0 && !rt.entry.lenient)
                FA_ERROR("audio", "MusicPlayer on '{}': song '{}' has no section '{}'. {} (starting at the beginning)", rt.id, rt.song, wanted,
                         did_you_mean(wanted, map.section_names()));
        }
        const MusicQuantize q = rt.entry.quantize.value_or(mp.quantize);
        std::string err;
        bool ok;
        {
            std::lock_guard<std::mutex> lk(mu);
            if (tr.playing() && !rt.entry.hard) {
                const float bars = rt.entry.bars >= 0.0f ? rt.entry.bars : mp.crossfadeBars;
                const MusicSource* from = tr.source();
                const float seconds = float(double(bars) * from->map.barFrames / double(kMusicRate));
                ok = tr.crossfade_to(rt.src, section, q, seconds, &err);
            } else {
                ok = tr.start(rt.src, section, music_unit(mp.intensity), &err);
            }
        }
        rt.entry = MusicRt::Entry{};
        if (ok) {
            rt.sent = rt.src;
            rt.intensity = music_unit(mp.intensity);
            rt.error.clear();
        } else {
            rt.error = err;
            FA_ERROR("audio", "MusicPlayer on '{}' cannot play '{}': {}", rt.id, rt.song, err);
            mp.playing = false;
            rt.playing = false;
        }
    }

    // a song that played through to its end
    if (mp.playing && rt.sent && tr.ended()) {
        mp.playing = false;
        rt.playing = false;
        rt.sent.reset();
    }

    {
        std::lock_guard<std::mutex> lk(mu);
        const float vol = clamp(std::isfinite(mp.volume) ? mp.volume : 0.0f, 0.0f, 4.0f);
        if (vol != rt.volume) {
            tr.set_volume(vol, rt.volume < 0.0f ? 0.0f : 0.05f);
            rt.volume = vol;
        }
        if (mp.loop != rt.loop) {
            tr.set_loop(mp.loop);
            rt.loop = mp.loop;
        }
        if (mp.layerFade != rt.layerFade || mp.layerRange != rt.layerRange) {
            tr.set_layer_fade(std::max(mp.layerFade, 0.0f), std::max(mp.layerRange, 0.0f));
            rt.layerFade = mp.layerFade;
            rt.layerRange = mp.layerRange;
        }
        const float inten = music_unit(mp.intensity);
        if (rt.sent && inten != rt.intensity) {
            tr.set_intensity(inten, mp.layerQuantize);
            rt.intensity = inten;
        }
        // runtime fields
        const MusicStatus st = tr.status();
        mp.ready = rt.src != nullptr;
        mp.section = st.section;
        mp.bar = st.playing ? st.bar : 0;
        mp.beat = st.playing ? st.beat : 0;
        mp.tempo = st.playing ? float(st.tempo) : 0.0f;
        mp.activeMode = st.playing ? st.mode : (rt.src ? rt.src->mode : std::string());
    }
    music_events(world, rt);
}

void Audio::Impl::music_update(World& world) {
    // Players whose entity (or component) is gone, or that belong to another world, play on as orphans.
    {
        std::vector<MusicRt*> gone;
        for (auto& [bits, rt] : musicEnts)
            if (rt->world != &world || !world.alive(rt->e) || world.id_of(rt->e) != rt->id || !world.get<MusicPlayer>(rt->e)) gone.push_back(rt.get());
        for (MusicRt* rt : gone) music_orphan(rt);
    }
    for (Entity e : world.entities_with(&World::type_of<MusicPlayer>())) {
        if (!world.alive(e)) continue;
        MusicPlayer* mp = world.get<MusicPlayer>(e);
        if (!mp) continue;
        MusicRt& rt = music_get(world, e);
        rt.seen = stamp;
        if (!world.active_in_hierarchy(e)) {
            if (rt.playing || mp->playing) {
                if (!rt.stopIssued) {
                    std::lock_guard<std::mutex> lk(mu);
                    rt.tr->stop(MusicQuantize::None, 0.3f);
                }
                mp->playing = false;
                rt.playing = false;
                rt.stopIssued = true;
                rt.sent.reset();
            }
            rt.first = false;
            continue;
        }
        music_drive(world, e, *mp, rt);
    }
    // What nobody adopted fades out and goes.
    std::lock_guard<std::mutex> lk(mu);
    for (auto it = musicOrphans.begin(); it != musicOrphans.end();) {
        MusicRt& o = **it;
        if (!o.stopIssued) {
            o.tr->stop(MusicQuantize::None, 0.5f);
            o.stopIssued = true;
        }
        musicScratch.clear();
        o.tr->take_events(musicScratch);  // its entity is gone: nobody listens
        musicScratch.clear();
        o.tr->prune_sources();
        if (!o.tr->active()) it = musicOrphans.erase(it);
        else ++it;
    }
}

void Audio::Impl::music_shutdown() {
    for (auto& [k, l] : musicLoads)
        if (l->worker.joinable()) l->worker.join();
    for (auto& l : musicStale)
        if (l->worker.joinable()) l->worker.join();
    std::lock_guard<std::mutex> lk(mu);
    musicLoads.clear();
    musicStale.clear();
    musicCache.clear();
    musicErrors.clear();
    musicEnts.clear();
    musicOrphans.clear();
}

void Audio::set_music_device(const MusicDeviceProfile& device) {
    Impl& im = *impl_;
    const MusicDeviceProfile& old = im.musicDevice;
    if (old.formFactor != device.formFactor || old.tier != device.tier || old.web != device.web) ++im.musicEpoch;
    im.musicDevice = device;
}

// The song changed on disk: what was rendered of it is stale. The loads that run are given up, the cached sources dropped, and every
// player of the song fetches it again and crossfades into the new render (music_drive).
void Audio::Impl::music_invalidate(const std::string& song) {
    for (const char* mode : {"|live", "|stems"}) {
        const std::string key = song + mode;
        auto load = musicLoads.find(key);
        if (load != musicLoads.end()) {
            musicStale.push_back(std::move(load->second));
            musicLoads.erase(load);
        }
        musicCache.erase(key);
        musicErrors.erase(key);
    }
    for (auto& [bits, rt] : musicEnts)
        if (rt->song == song) rt->reload = true;
}

std::uint64_t Audio::mixed_frames() const {
    std::lock_guard<std::mutex> lk(impl_->mu);
    return impl_->mixedTotal;
}

namespace {
Error no_player_error(const char* call) {
    return Error{std::string(call) + ": " + kNoPlayer, "Add a MusicPlayer component to the entity (factoria add-component, or the scene JSON \"MusicPlayer\": {\"song\": \"music/theme.song.json\"})."};
}
// A song path that names no file fails now, in the call, instead of later in the load.
Result<void> need_song_file(const char* call, std::string_view song) {
    if (song.empty() || fs::exists(song)) return {};
    return make_error(std::string(call) + ": the song '" + std::string(song) + "' does not exist",
                      "Use the path of a *.song.json in the project, relative to its root, e.g. 'music/theme.song.json'.");
}
}  // namespace

Result<void> Audio::music_play(World& world, Entity e, std::string_view song, std::string_view section, float intensity) {
    Impl& im = *impl_;
    MusicPlayer* mp = world.alive(e) ? world.get<MusicPlayer>(e) : nullptr;
    if (!mp) return no_player_error("music.play");
    if (song.empty() && mp->song.empty())
        return make_error("music.play: there is no song to play", "Pass one, music.play('music/theme.song.json'), or set MusicPlayer.song.");
    if (auto ok = need_song_file("music.play", song); !ok) return ok;
    MusicRt& rt = im.music_get(world, e);
    const bool same = song.empty() || fs::normalize(song) == fs::normalize(mp->song);
    if (same && !section.empty() && rt.src && rt.src->map.section_index(section) < 0)
        return make_error("music.play: song '" + rt.song + "' has no section '" + std::string(section) + "'. " + did_you_mean(section, rt.src->map.section_names()),
                          "Pick one of the song's sections.");
    const bool already = mp->playing && same && section.empty() && rt.sent && rt.sent == rt.src;
    if (!song.empty()) mp->song = std::string(song);
    if (intensity >= 0.0f) mp->intensity = music_unit(intensity);
    if (already) return {};
    mp->playing = true;
    rt.entry = MusicRt::Entry{};
    rt.entry.hard = true;
    rt.entry.section = std::string(section);
    rt.sent.reset();
    return {};
}

void Audio::music_stop(World& world, Entity e, MusicQuantize quantize, float fadeSeconds) {
    Impl& im = *impl_;
    MusicPlayer* mp = world.alive(e) ? world.get<MusicPlayer>(e) : nullptr;
    if (!mp) return;
    mp->playing = false;
    MusicRt* rt = im.music_find(world, e);
    if (!rt) return;
    {
        std::lock_guard<std::mutex> lk(im.mu);
        rt->tr->stop(quantize, fadeSeconds < 0.0f ? 0.3f : fadeSeconds);
    }
    rt->sent.reset();
    rt->stopIssued = true;
    rt->playing = false;
}

void Audio::music_set_intensity(World& world, Entity e, float intensity, std::optional<MusicQuantize> quantize) {
    Impl& im = *impl_;
    MusicPlayer* mp = world.alive(e) ? world.get<MusicPlayer>(e) : nullptr;
    if (!mp) return;
    mp->intensity = music_unit(intensity);
    MusicRt* rt = im.music_find(world, e);
    if (!quantize || !rt || !rt->sent) return;
    std::lock_guard<std::mutex> lk(im.mu);
    rt->tr->set_intensity(mp->intensity, *quantize);
    rt->intensity = mp->intensity;
}

Result<void> Audio::music_go_to_section(World& world, Entity e, std::string_view section, std::optional<MusicQuantize> quantize, float fadeSeconds) {
    Impl& im = *impl_;
    MusicPlayer* mp = world.alive(e) ? world.get<MusicPlayer>(e) : nullptr;
    if (!mp) return no_player_error("music.goToSection");
    MusicRt& rt = im.music_get(world, e);
    const MusicSource* playing = rt.tr->source();
    const MusicSource* known = playing ? playing : rt.src.get();
    if (known) {
        if (known->map.section_index(section) < 0)
            return make_error("music.goToSection: song '" + known->path + "' has no section '" + std::string(section) + "'. " +
                                  did_you_mean(section, known->map.section_names()),
                              "Pick one of the song's sections (MusicAPI.sections lists them).");
    }
    if (!playing || !rt.sent) {  // not started: only where it will start
        mp->startSection = std::string(section);
        rt.entry.section = std::string(section);
        return {};
    }
    std::string err;
    std::lock_guard<std::mutex> lk(im.mu);
    const int index = playing->map.section_index(section);
    if (!rt.tr->go_to_section(index, quantize.value_or(mp->quantize), fadeSeconds < 0.0f ? mp->transitionFade : fadeSeconds, &err))
        return make_error("music.goToSection: " + err, "Check music.status for the song that plays.");
    return {};
}

Result<void> Audio::music_play_stinger(World& world, Entity e, const MusicStingerSpec& spec) {
    Impl& im = *impl_;
    MusicPlayer* mp = world.alive(e) ? world.get<MusicPlayer>(e) : nullptr;
    if (!mp) return no_player_error("music.playStinger");
    if (spec.clip.empty() == spec.section.empty())
        return make_error("music.playStinger: give exactly one of \"clip\" (an audio file) and \"section\" (a section of the song)",
                          "For example playStinger({clip: 'sfx/hit.wav', quantize: 'beat'}) or playStinger({section: 'victory'}).");
    MusicRt& rt = im.music_get(world, e);
    const MusicSource* playing = rt.tr->source();
    if (!playing || !rt.sent)
        return make_error("music.playStinger: nothing is playing, a stinger plays over the music",
                          "Start the music first (music.play), and wait for the 'music.ready' event when the song loads.");
    const MusicQuantize q = spec.quantize.value_or(mp->quantize);
    const float volume = std::isfinite(spec.volume) ? clamp(spec.volume, 0.0f, 4.0f) : 1.0f;
    if (!spec.section.empty()) {
        const int index = playing->map.section_index(spec.section);
        if (index < 0)
            return make_error("music.playStinger: song '" + playing->path + "' has no section '" + spec.section + "'. " +
                                  did_you_mean(spec.section, playing->map.section_names()),
                              "Pick one of the song's sections.");
        const MusicSpan& span = playing->map.spans[std::size_t(playing->map.sections[std::size_t(index)].firstSpan)];
        const float tail = std::max(spec.tail, 0.0f);
        const float length = float((span.end - span.start) / double(kMusicRate)) + tail;
        std::string err;
        std::lock_guard<std::mutex> lk(im.mu);
        if (!rt.tr->play_section_stinger(index, q, volume, tail, &err)) return make_error("music.playStinger: " + err, "");
        if (spec.duck > 0.0f)
            rt.tr->duck(q, clamp(spec.duck, 0.0f, 1.0f), spec.duckAttack, spec.duckHold < 0.0f ? length : spec.duckHold, spec.duckRelease);
        return {};
    }
    // A clip: loaded and opened outside the lock; its voice then starts on the boundary's frame.
    auto clip = im.get_clip(spec.clip);
    if (!clip) return make_error("music.playStinger: the clip '" + spec.clip + "' could not be loaded", "The error above says why; check the path (assets.list).");
    std::string err;
    auto stream = Impl::open_stream(*clip, false, &err);
    if (!err.empty()) return make_error("music.playStinger: " + err, "");
    PlayParams p;
    p.volume = volume;
    p.bus = spec.bus.empty() ? rt.busName : spec.bus;
    const float length = float(double(clip->frames) / double(kRate));
    VoiceId id = 0;
    {
        std::lock_guard<std::mutex> lk(im.mu);
        p.delayFrames = rt.tr->schedule_clip_stinger(q);
        id = im.add_voice_locked(clip, p, std::move(stream));
        if (spec.duck > 0.0f)
            rt.tr->duck(q, clamp(spec.duck, 0.0f, 1.0f), spec.duckAttack, spec.duckHold < 0.0f ? length : spec.duckHold, spec.duckRelease);
    }
    im.log_play(spec.clip, p, false, rt.id, true, {}, id);
    return {};
}

Result<void> Audio::music_crossfade_to(World& world, Entity e, std::string_view song, std::string_view section, std::optional<MusicQuantize> quantize,
                                       float bars) {
    Impl& im = *impl_;
    MusicPlayer* mp = world.alive(e) ? world.get<MusicPlayer>(e) : nullptr;
    if (!mp) return no_player_error("music.crossfadeTo");
    if (song.empty())
        return make_error("music.crossfadeTo: no song given", "Pass the asset path of a *.song.json, music.crossfadeTo('music/battle.song.json').");
    if (auto ok = need_song_file("music.crossfadeTo", song); !ok) return ok;
    MusicRt& rt = im.music_get(world, e);
    mp->song = std::string(song);
    mp->playing = true;
    rt.entry = MusicRt::Entry{};
    rt.entry.section = std::string(section);
    rt.entry.quantize = quantize;
    rt.entry.bars = bars;
    if (fs::normalize(song) == rt.song) rt.sent.reset();  // the same song again: a crossfade to its start (or section)
    return {};
}

MusicStatus Audio::music_status(World& world, Entity e) const {
    Impl& im = *impl_;
    MusicRt* rt = im.music_find(world, e);
    if (!rt) return MusicStatus{};
    std::lock_guard<std::mutex> lk(im.mu);
    MusicStatus st = rt->tr->status();
    st.exists = true;
    st.ready = rt->src != nullptr;
    if (rt->src) st.sections = rt->src->map.section_names();
    st.bus = rt->busName;
    st.error = rt->error;
    if (st.song.empty()) st.song = rt->song;
    return st;
}

Json Audio::music_players() const {
    Impl& im = *impl_;
    std::lock_guard<std::mutex> lk(im.mu);
    Json out = Json::array();
    auto add = [&](const MusicRt& rt, bool orphan) {
        MusicStatus st = rt.tr->status();
        st.exists = true;
        st.ready = rt.src != nullptr;
        if (rt.src) st.sections = rt.src->map.section_names();
        st.bus = rt.busName;
        st.error = rt.error;
        if (st.song.empty()) st.song = rt.song;
        Json j = st.to_json();
        j["entity"] = rt.id;
        j["orphan"] = orphan;
        out.push_back(std::move(j));
    };
    for (const auto& [bits, rt] : im.musicEnts) add(*rt, false);
    for (const auto& rt : im.musicOrphans) add(*rt, true);
    return out;
}

// ============================================================ world driving ==

void Audio::update(World& world, float dt) {
    Impl& im = *impl_;
    if (!im.inited) return;
    if (im.autoAdvance) im.advance(dt);

    if (im.lastWorld != &world) {
        for (auto& [k, ea] : im.ents) if (ea.voice) stop(ea.voice);
        im.ents.clear();
        for (auto& [k, ev] : im.videos) if (ev.voice) stop(ev.voice);
        im.videos.clear();
        im.lastWorld = &world;
    }
    ++im.stamp;

    // ---- sounds that game feel actions (clip events, feel.do) queued since the last frame: one-shots on their bus
    for (const FeelSound& fs : feel_take_sounds(world)) {
        FeelState& feel = world.feel();
        if (feel.failedSounds.count(fs.options.path)) continue;  // it failed before in this scene (said once): not decoded and searched for again
        PlayParams pp;
        pp.volume = fs.options.volume;
        pp.pitch = fs.options.pitch;
        pp.pan = fs.options.pan;
        pp.bus = fs.options.bus;
        if (im.start(fs.options.path, pp, fs.source) == 0 && feel.failedSounds.size() < 256) feel.failedSounds.insert(fs.options.path);
    }

    // ---- listener: AudioListener entity, else the primary (or first) camera
    bool haveListener = false;
    Vec3 lpos{}, lright{1, 0, 0};
    float lvol = 1.0f, lzoom = 1.0f;
    auto take = [&](Entity e, float vol, float zoom) {
        Mat4 m = world.world_matrix(e);
        lpos = {m.at(3, 0), m.at(3, 1), m.at(3, 2)};
        Vec3 r{m.at(0, 0), m.at(0, 1), m.at(0, 2)};
        lright = length_sq(r) > 1e-8f ? normalize(r) : Vec3{1, 0, 0};
        lvol = vol;
        lzoom = zoom > 1e-3f ? zoom : 1e-3f;
        haveListener = true;
    };
    world.each<AudioListener>([&](Entity e, AudioListener& l) {
        if (!haveListener && world.active_in_hierarchy(e)) take(e, l.volume, l.zoom);
    });
    if (!haveListener) {
        // The first camera drawn (the lowest depth of the primary ones; a split screen has several), else any camera.
        Entity first = kNullEntity, primary = kNullEntity;
        int primaryDepth = 0;
        world.each<Camera>([&](Entity e, Camera& c) {
            if (!world.active_in_hierarchy(e) || !c.renderTarget.empty()) return;  // a render-target camera is no listener
            if (c.primary) {
                if (primary.is_null() || c.depth < primaryDepth) { primary = e; primaryDepth = c.depth; }
            } else if (first.is_null()) {
                first = e;
            }
        });
        if (!primary.is_null()) take(primary, 1.0f, 1.0f);
        else if (!first.is_null()) take(first, 1.0f, 1.0f);
    }

    // ---- AudioSource components
    for (Entity e : world.entities_with(&World::type_of<AudioSource>())) {
        if (!world.alive(e)) continue;
        AudioSource* src = world.get<AudioSource>(e);
        if (!src) continue;
        auto it = im.ents.find(e.bits());
        if (it != im.ents.end() && it->second.id != world.id_of(e)) {  // slot reused after World::clear()
            if (it->second.voice) stop(it->second.voice);
            im.ents.erase(it);
            it = im.ents.end();
        }
        if (it == im.ents.end()) {
            EntityAudio ea;
            ea.e = e;
            ea.id = world.id_of(e);
            it = im.ents.emplace(e.bits(), std::move(ea)).first;
        }
        EntityAudio& ea = it->second;
        ea.seen = im.stamp;

        if (!world.active_in_hierarchy(e)) {
            if (ea.voice) { stop(ea.voice); ea.voice = 0; src->playing = false; }
            continue;
        }
        if (!ea.started) {
            ea.started = true;
            if (src->playOnStart) src->playing = true;
        }
        if (ea.voice != 0 && !is_playing(ea.voice)) {  // clip ended on its own
            ea.voice = 0;
            src->playing = false;
        }
        if (ea.voice != 0 && ea.clip != src->clip) {  // clip swapped by gameplay: restart with the new one
            stop(ea.voice);
            ea.voice = 0;
        }
        if (!src->playing && ea.voice != 0) {
            stop(ea.voice);
            ea.voice = 0;
        }

        float gain = 1.0f, pan = 0.0f;
        if (src->spatial && haveListener) {
            Vec3 d = world.world_position(e) - lpos;
            // The listener's zoom stretches the distance a sound is heard at: a zoom of 2 doubles the reach (and the pan's span).
            float range = std::max(src->range, 1e-3f) * lzoom;
            gain = saturate(1.0f - length(d) / range);
            pan = clamp(dot(d, lright) / (range * 0.5f), -1.0f, 1.0f);
        }
        const float volume = src->volume * gain * (haveListener ? lvol : 1.0f);

        if (src->playing && ea.voice == 0) {
            if (src->clip.empty()) {
                src->playing = false;
            } else {
                PlayParams p;
                p.volume = volume;
                p.pitch = src->pitch;
                p.pan = pan;
                p.loop = src->loop;
                std::string clip = src->clip;
                if (src->variants >= 2) {
                    // The world RNG's state (not a draw: gameplay's random numbers are untouched), the entity's id and the play
                    // count seed a private generator, so a run with the same seed hears the same takes.
                    std::uint64_t h = 1469598103934665603ull;
                    for (char c : ea.id) h = (h ^ std::uint8_t(c)) * 1099511628211ull;
                    Rng pick(world.rng().state() ^ h ^ (std::uint64_t(++ea.plays) * 0x9E3779B97F4A7C15ull));
                    const int count = std::min<int>(src->variants, 64);
                    int variant = ea.lastVariant >= 1 && ea.lastVariant <= count ? pick.range_int(1, count - 1) : pick.range_int(1, count);
                    if (ea.lastVariant >= 1 && ea.lastVariant <= count && variant >= ea.lastVariant) ++variant;
                    ea.lastVariant = variant;
                    clip = sfx_variant_path(src->clip, variant, count);
                }
                ea.voice = im.start(clip, p, ea.id);
                ea.clip = src->clip;
                if (ea.voice == 0) src->playing = false;  // load failed (already logged)
            }
        } else if (ea.voice != 0) {
            std::lock_guard<std::mutex> lk(im.mu);
            if (Voice* v = im.find_voice(ea.voice)) {
                v->volume = std::max(volume, 0.0f);
                v->pitch = std::max(src->pitch, 0.001f);
                v->pan = pan;
            }
        }
    }
    // sweep entities that disappeared (destroyed or component removed)
    for (auto it = im.ents.begin(); it != im.ents.end();) {
        if (it->second.seen != im.stamp) {
            if (it->second.voice) stop(it->second.voice);
            it = im.ents.erase(it);
        } else {
            ++it;
        }
    }

    // ---- Video components: their sound goes to a PCM voice on the Video's bus. The decoder (advanced by update_videos from
    // the game clock) releases samples up to a short lead after its position, so a paused game goes silent.
    for (Entity e : world.entities_with(&World::type_of<Video>())) {
        if (!world.alive(e)) continue;
        Video* vid = world.get<Video>(e);
        if (!vid) continue;
        auto it = im.videos.find(e.bits());
        if (it != im.videos.end() && it->second.id != world.id_of(e)) {  // slot reused after World::clear()
            if (it->second.voice) stop(it->second.voice);
            im.videos.erase(it);
            it = im.videos.end();
        }
        if (it == im.videos.end()) {
            EntityVideo ev;
            ev.id = world.id_of(e);
            it = im.videos.emplace(e.bits(), std::move(ev)).first;
        }
        EntityVideo& ev = it->second;
        ev.seen = im.stamp;
        const std::shared_ptr<VideoDecoder>& dec = vid->rt.decoder;
        const bool live = world.active_in_hierarchy(e) && dec && dec->info().hasAudio;
        if (ev.voice != 0 && (!live || ev.decoder != dec || !is_playing(ev.voice))) {
            stop(ev.voice);
            ev.voice = 0;
        }
        if (!live) {
            ev.decoder.reset();
            continue;
        }
        if (ev.voice == 0) {
            PlayParams p;
            p.volume = vid->volume;
            p.loop = true;  // never the first voice evicted when the mixer is full
            p.bus = vid->bus;
            ev.voice = open_pcm_voice(dec->info().sampleRate, p, vid->path, ev.id);
            ev.decoder = dec;
            ev.epoch = dec->audio_epoch();
            ev.bus = vid->bus;
            if (ev.voice == 0) continue;
        }
        if (ev.epoch != dec->audio_epoch()) {  // a seek or a loop restart: what waits belongs to the old position
            ev.epoch = dec->audio_epoch();
            clear_pcm(ev.voice);
        }
        if (ev.bus != vid->bus) {
            ev.bus = vid->bus;
            set_voice_bus(ev.voice, vid->bus);
        }
        set_voice_volume(ev.voice, vid->volume, 0.0f, false);  // the video's own per-frame level is not a script's call
        im.videoScratch.clear();
        const std::size_t frames = dec->take_audio(0.08, im.videoScratch);
        if (frames > 0) push_pcm(ev.voice, im.videoScratch.data(), frames);
    }
    for (auto it = im.videos.begin(); it != im.videos.end();) {  // destroyed entities or removed components
        if (it->second.seen != im.stamp) {
            if (it->second.voice) stop(it->second.voice);
            it = im.videos.erase(it);
        } else {
            ++it;
        }
    }

    // ---- MusicPlayer components
    im.music_update(world);

    // ---- scene music (only reacts to changes, so scripts may still call play_music themselves)
    const SceneSettings& ss = world.settings();
    if (ss.music != im.sceneMusic) {
        im.sceneMusic = ss.music;
        im.sceneMusicVolume = ss.musicVolume;
        if (ss.music.empty()) {
            stop_music(0.5f);
        } else {
            bool keep;  // a persisted track that is the scene's own music stays persisted
            {
                std::lock_guard<std::mutex> lk(im.mu);
                keep = im.musicPersist && im.musicPath == fs::normalize(ss.music);
            }
            play_music(ss.music, ss.musicVolume, 0.5f, keep);
        }
    } else if (!ss.music.empty() && ss.musicVolume != im.sceneMusicVolume) {
        im.sceneMusicVolume = ss.musicVolume;
        std::lock_guard<std::mutex> lk(im.mu);
        if (Voice* v = im.find_voice(im.musicVoice)) v->volume = std::max(ss.musicVolume, 0.0f);
    }
}

}  // namespace fa
