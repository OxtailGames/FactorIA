// Audio: the game side of the mixer. Decoded clips -> voices -> buses -> master -> (device | null sink | recorder).
//
// Threads (docs/SOUND.md, "The audio callback"). Every public call runs on the game thread side under Impl::apiMu, a
// mutex the audio callback never takes: the mixer (audio_mixer.h) owns what it mixes and the two sides talk through
// lock-free single-producer single-consumer rings. The game keeps a mirror of what it asked for (the voices, the buses,
// the music players) and answers every question from it; it sends what changes as commands, and reads back the commands
// the mixer is done with, the voices that ended, the music state and its events. So the simulation never reads state the
// audio thread writes, the callback never waits for the game, and the mixer never allocates or frees.
//
// Modes. With a device the commands of one API call are staged and committed to the mixer together when the call returns
// (the callback applies them at the start of its next block). On the null device (headless, tests, a device that failed)
// there is no other thread: a command is applied the moment it is sent and advance_null_device() mixes on the calling
// thread, so a run is deterministic. The web's device calls back on the main thread too.
#include "fa/audio/audio.h"
#include "fa/audio/sfx.h"

#include <algorithm>
#include <atomic>
#include <cmath>
#include <cstdlib>
#include <cstring>
#include <deque>
#include <limits>
#include <map>
#include <mutex>
#include <optional>
#include <set>

#include "audio_decoder.h"
#include "audio_mixer.h"
#include "audio_testing.h"
#include "bus_fx.h"
#include "fa/audio/analysis.h"
#include "fa/audio/music_transport.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/fs.h"
#include "fa/core/jobs.h"
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

using audio_detail::BusMusic;
using audio_detail::BusSfx;
using audio_detail::BusUi;
using audio_detail::BusBuiltin;
using audio_detail::BusRuntime;
using audio_detail::Clip;
using audio_detail::Cmd;
using audio_detail::CmdKind;
using audio_detail::kFirstProjectBus;
using audio_detail::kMasterBus;
using audio_detail::kMaxPlayers;
using audio_detail::kMaxVoices;
using audio_detail::kMusicStreamFrames;
using audio_detail::kNullBlock;
using audio_detail::kRate;
using audio_detail::kStreamFrames;
using audio_detail::kStreamPrefill;
using audio_detail::kStreamRefill;
using audio_detail::MixTable;
using audio_detail::Mixer;
using audio_detail::MixVoice;
using audio_detail::MusicChannel;
using audio_detail::MusicSnap;
using audio_detail::PcmRing;
using audio_detail::Ret;
using audio_detail::SampleRing;
using audio_detail::StreamRing;

constexpr std::size_t kMaxRecordFrames = std::size_t(kRate) * 600;  // 10 minutes
constexpr std::size_t kMaxPlayLog = 4096;
const char* const kBusNames[BusBuiltin] = {"sfx", "music", "ui"};
constexpr std::size_t kMaxEnded = 1024;   // endings waiting for take_ended_voices()
constexpr float kMaxBusVolume = 4.0f;
// Commands staged for a device that has not taken them yet (its callback stalls, or the game sends faster than it mixes).
// Past this many the oldest play or voice setting is dropped, then the oldest bus or music setting; stops and other Keep
// commands are never dropped (audio_mixer.h, CmdKind). Counted in stats() as commandsDropped / settingsDropped.
constexpr std::size_t kMaxStaged = 8192;
constexpr int kMusicPriority = 256;   // play_music and its layers: above every priority a game can give (0..255)
constexpr int kVideoPriority = 192;   // a Video's sound
constexpr std::size_t kRecordRingFloats = std::size_t(1) << 20;  // about 12 s of 44.1 kHz stereo between two drains

// A voice as the game side knows it: what it asked for. The mixer has its own copy (MixVoice) and says when it ended.
struct GameVoice {
    std::shared_ptr<const Clip> clip;   // kept alive here while the mixer may read it
    std::shared_ptr<StreamRing> stream; // a streamed clip's ring (a decode job may hold it too)
    std::shared_ptr<PcmRing> pcm;       // a voice the game feeds
    std::string path, source;
    int bus = BusSfx;
    float volume = 1.0f, pitch = 1.0f, pan = 0.0f;  // as last set (the target of a ramp)
    bool loop = false, notify = false, music = false;
    bool stopped = false;    // stopped by the game: gone for every query, erased once the mixer confirms the end
    bool fadingOut = false;  // fading out to its end: still playing, the first a full mixer steals
    int priority = 128;
    std::size_t streamBytes = 0;  // the ring and the decoder's buffer, measured when it started
};

// A bus as the game side knows it (the mixer's MixBus has the runtime: ramps, filters, the reverb).
struct GameBus {
    std::string name;
    int parent = kMasterBus;
    float vol = 1.0f, snap = 1.0f;  // targets
    float lpHz = 0.0f;              // 0 = off
    float reverb = 0.0f;            // the wet mix asked for, 0 = off
    bool rvMade = false;            // a reverb was handed to the mixer for this bus
    int duckBy = -1;
    DuckSettings duck;
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

// ---- adaptive music (MusicPlayer components): the game's side of one player -------------------------------------------------------
constexpr std::size_t kMusicCacheBytes = std::size_t(128) << 20;  // sources nobody plays are dropped above this, least recently used first

// A song being rendered or read. With a device it runs as a job (fa::jobs); the null device (tests, headless) and the web run it
// right in the call, so a headless run is deterministic and has the music from the frame it asked.
struct MusicLoad {
    std::string key, path, note;
    MusicMode mode = MusicMode::Live;
    MusicStemPlan plan;
    jobs::Handle job;
    std::atomic<bool> done{false};
    std::shared_ptr<MusicSource> source;
    std::string error;
    LoadTrace::Owner owner = LoadTrace::current_owner();  // the engine that asked: its load trace gets the reads
    void run() {
        LoadTrace::ReadingFor reading(owner);  // on the job's thread too (fa/core/load_trace.h)
        auto r = music_load_source(path, mode, plan, &note);
        if (r) source = std::move(*r);
        else error = r.error().to_string();
        // Release: `source`, `error` and `note` are written before the game thread sees done (acquire in music_poll).
        done.store(true, std::memory_order_release);
    }
};

// A source the mixer may read because a command named it: kept alive until the mixer's state shows it applied that command
// and no playhead or pending change reads the source any more.
struct HeldSource {
    std::shared_ptr<const MusicSource> src;
    std::uint64_t seq = 0;
};

struct MusicRt {
    Entity e;
    std::string id;
    const World* world = nullptr;
    std::unique_ptr<MusicChannel> ch;         // the transport in the mixer (null when every channel is taken)
    std::vector<HeldSource> held;
    std::uint64_t lastSeq = 0;                // the last command sent to the channel
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

// What the game reads of a player's transport: the mixer's latest copy once it has applied the last command sent to it
// (`fresh`); before that, what that command will make of it.
struct MusicView {
    bool fresh = true, playing = false, ended = false, active = false;
    const MusicSource* src = nullptr;
    const MusicTransportState* state = nullptr;  // the mixer's copy (null without a channel)
};

struct CachedSong {
    std::shared_ptr<const MusicSource> src;
    std::uint64_t lastUse = 0;
};

}  // namespace

struct Audio::Impl {
    Mixer mixer;

    // ---- the game side (every field below): touched only under apiMu, by the game thread or whoever calls the API
    // Recursive: a public call may call another one (update() calls stop(), play_music() ...). The callback never takes it.
    std::recursive_mutex apiMu;
    int depth = 0;                    // nesting of public calls: the outermost one commits what they sent (flush())
    std::uint64_t batchSeq = 0, curBatch = 0, cmdSeq = 0;
    std::deque<Cmd*> staged;          // sent with a device and not in the mixer's ring yet (kMaxStaged)
    std::vector<VoiceId> pendingEnds; // voices the mixer ended (or plays that never reached it): process_ends() forgets them
    std::uint64_t commandsDropped = 0, settingsDropped = 0, voicesStolen = 0, voicesRejected = 0;
    bool dropWarned = false;
    std::set<std::string> rejectWarned;  // clips whose play a full mixer refused (warned once each; at most 256 names)

    bool inited = false;
    bool device = false;       // a device's callback mixes (on another thread, or on the web's main thread between frames)
    bool autoAdvance = false;  // device requested but unavailable -> run as null device driven by update()
    bool manual = false;       // a test drives the mixer as a device (AudioTestAccess::use_manual_device)
    bool web = false;
    bool streamLogged = false;
    bool streamService = true; // decode jobs refill the streamed voices (tests switch it off to make underruns)
    int deviceRate = kRate;
    int deviceChannels = 2;

    std::map<std::string, std::shared_ptr<const Clip>> clips;
    std::map<std::string, std::vector<std::string>> untraced;  // adopt_clip: the files of a clip not used yet (load trace)
    std::set<std::string> failedLogged;

    std::map<VoiceId, GameVoice> voices;  // by id: ids only grow, so this is also the order they started in
    VoiceId nextVoice = 1;
    std::vector<GameBus> bus;             // the bus table (see kMasterBus), as the mixer's MixTable has it
    std::vector<VoiceId> ended;           // voices with notify that ended (take_ended_voices)
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
    bool recWarned = false, recLostWarned = false;
    std::shared_ptr<SampleRing> recRing;  // what the mixer writes the output into while recording

    float lastPeak = 0.0f;  // the null device's last advance
    double carry = 0.0;
    std::vector<float> nullBuf;
    std::vector<jobs::Handle> jobsInFlight;  // stream refills and song loads: shutdown() waits for them

    // gameplay-side state
    const World* lastWorld = nullptr;
    std::map<std::uint64_t, EntityAudio> ents;
    std::map<std::uint64_t, EntityVideo> videos;
    std::vector<float> videoScratch;
    std::uint64_t stamp = 0;
    std::string sceneMusic;
    float sceneMusicVolume = -1.0f;

    // adaptive music (MusicPlayer components)
    std::map<std::uint64_t, std::unique_ptr<MusicRt>> musicEnts;
    std::vector<std::unique_ptr<MusicRt>> musicOrphans;   // players whose entity is gone: they fade out (or a new player adopts them)
    std::map<std::string, CachedSong> musicCache;         // by "song|mode"
    std::uint64_t musicUse = 0;                           // the clock of the cache's least-recently-used order
    std::size_t musicCacheBudget = kMusicCacheBytes;
    std::map<std::string, std::shared_ptr<MusicLoad>> musicLoads;
    std::map<std::string, std::string> musicErrors;       // why a load failed, by key
    MusicDeviceProfile musicDevice;
    std::uint64_t musicEpoch = 1;                         // raised when the device profile changes (players re-resolve `auto`)
    bool channelWarned = false;

    MusicRt* music_find(const World& world, Entity e);
    MusicRt& music_get(World& world, Entity e);
    void music_request(MusicRt& rt, const MusicPlayer& mp);
    void music_poll();
    void music_trim(const std::string& keepKey);
    void music_drive(World& world, Entity e, MusicPlayer& mp, MusicRt& rt);
    void music_update(World& world);
    void music_resolve(MusicRt& rt);
    void music_orphan(MusicRt* rt);
    void music_events(World* world, MusicRt& rt);
    void music_shutdown();
    void music_invalidate(const std::string& song);
    void make_channel(MusicRt& rt);
    void retire(std::unique_ptr<MusicRt> rt);
    MusicView view(MusicRt& rt);
    void chan_stop(MusicRt& rt, MusicQuantize q, float fade);

    // play log (game thread)
    const World* clockWorld = nullptr;
    std::deque<AudioEvent> playLog;
    std::uint64_t playSeq = 0;
    std::uint64_t playDropped = 0;

    Impl() {
        reset_bus_table();
        // Made once: on the null device the mixing thread is the game's, and voices ending mid-game cost no allocation.
        pendingEnds.reserve(kMaxVoices * 4);
        ended.reserve(kMaxEnded);
    }
    ~Impl() {
        // shutdown() settled the mixer; whatever is left was never sent to it or has come back.
        for (Cmd* c : staged) delete c;
        Cmd* const* c = nullptr;
        while ((c = mixer.commands.front()) != nullptr) {
            delete *c;
            mixer.commands.pop();
        }
        Ret r;
        while (mixer.returns.pop(r)) delete r.cmd;
    }

    // ---------------------------------------------------------------------------------------------------- the API lock
    // Every public call holds one: the lock, and on the way out of the outermost one the commit of what it sent (so the
    // commands of one call reach the mixer together and land in the same block).
    struct Call {
        Impl& im;
        explicit Call(Impl& i) : im(i) {
            im.apiMu.lock();
            if (im.depth++ == 0) im.curBatch = ++im.batchSeq;
        }
        ~Call() {
            if (--im.depth == 0) im.flush();
            im.apiMu.unlock();
        }
        Call(const Call&) = delete;
        Call& operator=(const Call&) = delete;
    };

    // ---------------------------------------------------------------------------------------------------- commands
    static Cmd* make(CmdKind kind, std::function<void(Mixer&, Cmd&)> run) {
        Cmd* c = new Cmd;
        c->kind = kind;
        c->run = std::move(run);
        return c;
    }

    // Sends a command; returns its sequence number. Without a device nothing else mixes, so it is applied right here; with
    // one it is staged and committed by the outermost call (flush). `c` belongs to the queue from here on.
    std::uint64_t send(Cmd* c) {
        const std::uint64_t seq = ++cmdSeq;
        c->seq = seq;
        c->batch = curBatch;
        if (!device) {
            drain_returns();
            if (!mixer.commands.push(c)) {  // cannot happen: the ring is emptied after every command here
                delete c;
                return seq;
            }
            mixer.commands.commit();
            mixer.apply_commands();
            drain_returns();
            return seq;
        }
        staged.push_back(c);
        if (staged.size() > kMaxStaged) drop_one();
        return seq;
    }

    // The staging queue is full: the oldest play or voice setting goes, else the oldest bus or music setting. Keep commands
    // (stops, removals, starts of music, table swaps, the recorder) are never dropped.
    void drop_one() {
        auto oldest = [&](CmdKind k) {
            return std::find_if(staged.begin(), staged.end(), [&](const Cmd* c) { return c->kind == k; });
        };
        auto it = oldest(CmdKind::Droppable);
        const bool lossy = it == staged.end();
        if (lossy) it = oldest(CmdKind::Lossy);
        if (it == staged.end()) return;
        Cmd* c = *it;
        staged.erase(it);
        if (c->play) pendingEnds.push_back(c->play);  // the voice never starts: it ends on the game side
        delete c;
        if (lossy) ++settingsDropped;
        else ++commandsDropped;
        if (!dropWarned) {
            dropWarned = true;
            FA_WARN("audio", "the audio device takes no commands (its callback stalls): more than {} wait, so the oldest plays "
                             "and settings are dropped (stats(): commandsDropped, settingsDropped)", kMaxStaged);
        }
    }

    // Hands the staged commands to the mixer, whole calls at a time while they fit (a call bigger than the ring goes in
    // parts, each when the ring is empty), then takes back what the mixer is done with.
    void flush() {
        if (device) {
            bool any = false;
            while (!staged.empty()) {
                const std::uint64_t b = staged.front()->batch;
                std::size_t n = 0;
                while (n < staged.size() && staged[n]->batch == b) ++n;
                const std::size_t room = mixer.commands.free_space();
                if (n > room && room < mixer.commands.capacity()) break;
                const std::size_t take = std::min(n, room);
                for (std::size_t i = 0; i < take; ++i) {
                    mixer.commands.push(staged.front());
                    staged.pop_front();
                }
                any = any || take > 0;
                if (take < n || take == 0) break;
            }
            if (any) mixer.commands.commit();
            service_streams();
        }
        drain_returns();
        process_ends();
    }

    // Takes back the commands the mixer applied (and frees them with what they carry) and the voices that ended.
    void drain_returns() {
        Ret r;
        while (mixer.returns.pop(r)) {
            if (r.kind == Ret::Ended) {
                pendingEnds.push_back(r.voice);
                continue;
            }
            delete r.cmd;
        }
    }

    // The only place voices leave the mirror (never while something iterates it).
    void process_ends() {
        for (VoiceId id : pendingEnds) {
            auto it = voices.find(id);
            if (it == voices.end()) continue;
            if (!it->second.stopped && it->second.notify) note_ended(id);
            if (id == musicVoice) musicVoice = 0;
            voices.erase(it);
        }
        pendingEnds.clear();
    }

    void note_ended(VoiceId id) {
        if (ended.size() >= kMaxEnded) ended.erase(ended.begin());
        ended.push_back(id);
    }

    // What the mixer said since the last call, before a query reads the mirror.
    void sync_in() {
        drain_returns();
        process_ends();
    }

    // Commits, refills the streams and drains the recorder: what a frame does with a device (update(), service()).
    void pump() {
        flush();
        drain_recorder();
        // Acquire pairs with the callback's release on `callbacks`: the first callback's size is visible.
        if (device && !streamLogged && mixer.callbacks.load(std::memory_order_acquire) > 0) {
            streamLogged = true;
            FA_INFO("audio", "stream running: first callback of {} frames, {} channels",
                    mixer.firstCallbackFrames.load(std::memory_order_relaxed),
                    mixer.firstCallbackChannels.load(std::memory_order_relaxed));
        }
    }

    // Nothing mixes any more (shutdown): runs every command still staged or in the ring.
    void settle() {
        for (int guard = 0; guard < 1 << 20 && (!staged.empty() || !mixer.commands.empty()); ++guard) {
            while (!staged.empty() && mixer.commands.free_space() > 0) {
                mixer.commands.push(staged.front());
                staged.pop_front();
            }
            mixer.commands.commit();
            mixer.apply_commands();
            drain_returns();
        }
        drain_returns();
    }

    // ---------------------------------------------------------------------------------------------------- buses
    // The built-in buses alone, all neutral.
    void reset_bus_table() {
        bus.clear();
        bus.resize(std::size_t(kFirstProjectBus));
        for (int i = 0; i < BusBuiltin; ++i) bus[std::size_t(i)].name = kBusNames[i];
        bus[std::size_t(kMasterBus)].name = "master";
    }
    // The index of a bus by name (master included); -1 for an unknown name.
    int fx_index(std::string_view name) const {
        for (std::size_t i = 0; i < bus.size(); ++i)
            if (bus[i].name == name) return int(i);
        return -1;
    }
    // The buses a voice can play on (not the master).
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
    float lowpass_top() const { return std::min(audio_detail::kLowpassOpen, 0.49f * float(deviceRate)); }
    Json bus_state_json(const GameBus& fx) const;

    // A bus command: runs on the mixer's bus `b` (the table at the time it is applied is the one it was sent for: a table
    // swap is a command too, in the same order).
    template <class F>
    void bus_cmd(int b, CmdKind kind, F fn) {
        send(make(kind, [b, fn](Mixer& m, Cmd& c) {
            if (b >= 0 && std::size_t(b) < m.table->bus.size()) fn(m, m.table->bus[std::size_t(b)].rt, c);
        }));
    }
    // The bus gets the reverb it needs the first time one is switched on (made here: the mixer allocates nothing).
    void give_reverb(int b) {
        GameBus& g = bus[std::size_t(b)];
        if (g.rvMade) return;
        g.rvMade = true;
        Cmd* c = make(CmdKind::Keep, [b](Mixer& m, Cmd& cmd) {
            if (b < 0 || std::size_t(b) >= m.table->bus.size()) return;
            BusRuntime& rt = m.table->bus[std::size_t(b)].rt;
            if (!rt.rv) rt.rv = std::move(cmd.reverb);  // a move; one it has already goes back with the command
        });
        c->reverb = std::make_unique<audio_detail::Reverb>(float(deviceRate));
        send(c);
    }
    void send_lowpass(int b, float hz, float fade) {
        GameBus& g = bus[std::size_t(b)];
        g.lpHz = hz <= 0.0f ? 0.0f : clamp(hz, 20.0f, lowpass_top());
        bus_cmd(b, CmdKind::Lossy, [hz, fade](Mixer& m, BusRuntime& rt, Cmd&) { m.set_lowpass(rt, hz, fade); });
    }
    void send_reverb(int b, float mix, float fade) {
        bus[std::size_t(b)].reverb = std::max(mix, 0.0f);
        if (mix > 0.0f) give_reverb(b);
        bus_cmd(b, CmdKind::Lossy, [mix, fade](Mixer& m, BusRuntime& rt, Cmd&) {
            std::unique_ptr<audio_detail::Reverb> none;  // the reverb came with give_reverb()
            m.set_reverb(rt, mix, fade, none);
        });
    }
    void send_duck(int b, int by, const DuckSettings& duck) {
        GameBus& g = bus[std::size_t(b)];
        g.duckBy = by;
        g.duck = by < 0 ? DuckSettings{} : duck;
        const float amount = duck.amount, attack = duck.attack, release = duck.release;
        bus_cmd(b, CmdKind::Lossy, [by, amount, attack, release](Mixer& m, BusRuntime& rt, Cmd&) {
            m.set_duck(rt, by, amount, attack, release);
        });
    }

    // ---------------------------------------------------------------------------------------------------- play log
    void log_play(std::string_view path, const PlayParams& p, bool music, std::string_view source, bool ok,
                  std::string_view layer = {}, VoiceId voice = 0) {
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
        push_log(std::move(ev));
    }
    void push_log(AudioEvent ev) {
        playLog.push_back(std::move(ev));
        if (playLog.size() > kMaxPlayLog) {
            playLog.pop_front();
            ++playDropped;
        }
    }

    // ---------------------------------------------------------------------------------------------------- voices
    // How loud a voice is for voice stealing: its own volume, its clip's normalization and its bus chain's volumes and
    // snapshot scales (the targets the game set; the master is the same for every voice). A voice fading out to its end
    // counts as silent.
    float loudness(const GameVoice& v) const {
        if (v.fadingOut) return 0.0f;
        float g = v.volume * (v.clip ? v.clip->gain : 1.0f);
        int b = v.bus;
        for (std::size_t n = 0; b >= 0 && b != kMasterBus && std::size_t(b) < bus.size() && n < bus.size(); ++n) {
            g *= bus[std::size_t(b)].vol * bus[std::size_t(b)].snap;
            b = bus[std::size_t(b)].parent;
        }
        return g;
    }

    // Voice stealing (docs/SOUND.md, "Voice stealing"). With every voice taken, the new voice replaces the voice with the
    // lowest priority, the quietest of those (ties: the one started first), when it has a higher priority, or the same
    // priority and is louder; otherwise the new one is refused. Age never decides. True when there is room now.
    bool make_room(int priority, float loud) {
        std::size_t live = 0;
        for (const auto& [id, v] : voices)
            if (!v.stopped) ++live;
        if (live < kMaxVoices) return true;
        VoiceId victim = 0;
        int vp = 0;
        float vl = 0.0f;
        for (const auto& [id, v] : voices) {
            if (v.stopped) continue;
            const float l = loudness(v);
            if (victim == 0 || v.priority < vp || (v.priority == vp && l < vl)) {
                victim = id;
                vp = v.priority;
                vl = l;
            }
        }
        if (victim == 0) return true;
        if (priority > vp || (priority == vp && loud > vl)) {
            hard_stop(victim, true);
            ++voicesStolen;
            return true;
        }
        ++voicesRejected;
        return false;
    }

    VoiceId next_id() {
        for (;;) {
            const VoiceId id = nextVoice++;
            if (nextVoice == 0) nextVoice = 1;
            if (id != 0 && voices.find(id) == voices.end()) return id;
        }
    }

    // Takes a new voice into the mirror and fills the mixer's copy of it; 0 when the pool refuses it (`*rejected` set). The
    // caller sends the play.
    VoiceId new_voice(GameVoice gv, const PlayParams& p, MixVoice& mv, bool* rejected) {
        int b = bus_index(p.bus);
        if (b < 0) {
            FA_ERROR("audio", "Unknown audio bus '{}'. {} (using 'sfx')", p.bus, did_you_mean(p.bus, bus_names_locked(false)));
            b = BusSfx;
        }
        gv.bus = b;
        gv.volume = std::max(p.volume, 0.0f);
        gv.pitch = std::max(p.pitch, 0.001f);
        gv.pan = clamp(p.pan, -1.0f, 1.0f);
        gv.loop = p.loop;
        gv.notify = p.notifyEnd;
        if (!make_room(gv.priority, loudness(gv))) {
            if (rejected) *rejected = true;
            const std::string& key = gv.path;
            if (rejectWarned.size() < 256 && rejectWarned.insert(key).second)
                FA_WARN("audio", "'{}' did not play: all {} voices play sounds of a higher priority, or as high and louder "
                                 "(hint: PlayOptions.priority / AudioSource.priority 0..255, default 128; stats().voicesRejected)",
                        key, kMaxVoices);
            return 0;
        }
        const VoiceId id = next_id();
        mv = MixVoice{};
        mv.id = id;
        mv.clip = gv.pcm ? nullptr : gv.clip.get();
        mv.stream = gv.stream.get();
        mv.pcm = gv.pcm.get();
        mv.volume = gv.volume;
        mv.pitch = gv.pitch;
        mv.pan = gv.pan;
        mv.loop = gv.loop;
        mv.bus = gv.bus;
        mv.delay = long(std::clamp<std::int64_t>(p.delayFrames, 0, std::numeric_limits<std::int32_t>::max()));
        if (gv.pcm) mv.pos = double(gv.pcm->skip());
        voices.emplace(id, std::move(gv));
        return id;
    }

    // The command that starts it in the mixer (a fade-in of `fadeIn` seconds when > 0).
    void send_play(VoiceId id, const MixVoice& mv, float fadeIn, CmdKind kind) {
        Cmd* c = make(kind, [mv, fadeIn](Mixer& m, Cmd&) {
            MixVoice v = mv;
            if (fadeIn > 0.0f) {
                v.fade = 0.0f;
                m.start_fade(v, 1.0f, fadeIn, false);
            }
            if (!m.add_voice(v)) {  // every slot taken (the game side keeps at most kMaxVoices: only a bug gets here)
                m.returns.push(Ret{Ret::Ended, nullptr, v.id});
                m.returns.commit();
            }
        });
        c->play = id;
        send(c);
    }

    // Ends a voice now (stop(), stealing, a scene load). A play still staged is taken back instead of sent.
    void hard_stop(VoiceId id, bool noteEnd) {
        auto it = voices.find(id);
        if (it == voices.end() || it->second.stopped) return;
        GameVoice& gv = it->second;
        if (noteEnd && gv.notify) note_ended(id);
        gv.stopped = true;
        if (id == musicVoice) musicVoice = 0;
        for (auto s = staged.begin(); s != staged.end(); ++s) {
            if ((*s)->play != id) continue;
            delete *s;
            staged.erase(s);
            pendingEnds.push_back(id);
            return;
        }
        send(make(CmdKind::Keep, [id](Mixer& m, Cmd&) { m.end_voice(id); }));
    }

    // Fades a voice out over `seconds` and ends it there (0: at once).
    void fade_stop(VoiceId id, float seconds) {
        auto it = voices.find(id);
        if (it == voices.end() || it->second.stopped) return;
        if (seconds <= 0.0f) {
            hard_stop(id, false);
            return;
        }
        it->second.fadingOut = true;
        send(make(CmdKind::Keep, [id, seconds](Mixer& m, Cmd&) {
            if (MixVoice* v = m.find_voice(id)) m.start_fade(*v, 0.0f, seconds, true);
        }));
    }

    // A voice's volume, pitch and pan (an AudioSource every frame).
    void send_params(VoiceId id, float volume, float pitch, float pan) {
        send(make(CmdKind::Droppable, [id, volume, pitch, pan](Mixer& m, Cmd&) {
            if (MixVoice* v = m.find_voice(id)) {
                v->volume = volume;
                v->pitch = pitch;
                v->pan = pan;
            }
        }));
    }

    // A live (non-stopped) voice of the mirror, or null.
    GameVoice* live_voice(VoiceId id) {
        auto it = voices.find(id);
        return it == voices.end() || it->second.stopped ? nullptr : &it->second;
    }

    // Stops every layer of the current layered music, fading out over `fade` seconds (0 = at once).
    void drop_layers(float fade) {
        for (const Layer& l : layers) fade_stop(l.voice, fade);
        layers.clear();
    }

    // ---------------------------------------------------------------------------------------------------- streams
    // A new voice's decoding ring on a streamed clip, with its first frames decoded (null + *err when it cannot be opened).
    static std::shared_ptr<StreamRing> open_ring(const Clip& clip, bool loop, std::size_t frames, std::size_t* bytes,
                                                 std::string* err) {
        auto decoder = audio_detail::open_decoder(clip.encoded->data(), clip.encoded->size(), clip.ext, err);
        if (!decoder) return nullptr;
        auto ring = std::make_shared<StreamRing>(audio_detail::Resampler(clip.encoded, std::move(decoder), loop), frames);
        if (ring->claim()) {  // nobody else has it yet
            ring->fill(kStreamPrefill);
            *bytes = ring->resident_bytes();
            ring->unclaim();
        }
        return ring;
    }

    // With a device: a decode job for every streamed voice that has room for at least kStreamRefill frames (the claim
    // keeps it to one producer at a time; a voice whose job still runs is skipped).
    void service_streams() {
        if (!device || !streamService) return;
        for (auto& [id, v] : voices) {
            if (v.stopped || !v.stream) continue;
            StreamRing& r = *v.stream;
            if (r.room() < kStreamRefill || !r.claim()) continue;
            std::shared_ptr<StreamRing> ring = v.stream;
            jobsInFlight.push_back(jobs::submit("audio.stream", [ring] {
                ring->fill(ring->room());
                ring->unclaim();
            }));
        }
        prune_jobs();
    }
    void prune_jobs() {
        jobsInFlight.erase(std::remove_if(jobsInFlight.begin(), jobsInFlight.end(), [](const jobs::Handle& h) { return h.done(); }),
                           jobsInFlight.end());
    }

    // ---------------------------------------------------------------------------------------------------- recorder
    void drain_recorder() {
        if (!recRing || !recording) return;
        const std::size_t limit = kMaxRecordFrames * 2;
        if (rec.size() < limit) recRing->drain(rec, limit - rec.size());
        if (rec.size() >= limit && recRing->waiting() > 0) {
            recRing->skip_all();
            if (!recWarned) {
                recWarned = true;
                FA_WARN("audio", "audio recording reached the 10 minute limit; further audio is not recorded");
            }
        }
        if (!recLostWarned && recRing->lost() > 0) {
            recLostWarned = true;
            FA_WARN("audio", "audio recording lost {} samples: the game did not take the recorded audio for several seconds",
                    recRing->lost());
        }
    }
    // Points the mixer's recorder at `ring` (null: off). The ring it wrote before stays alive until the command is back.
    void send_rec(std::shared_ptr<SampleRing> ring) {
        SampleRing* p = ring.get();
        Cmd* c = make(CmdKind::Keep, [p](Mixer& m, Cmd&) { m.rec = p; });
        c->rec = std::move(ring);
        c->keep = recRing;
        send(c);
    }

    // ---------------------------------------------------------------------------------------------------- the null device
    void advance(double seconds) {
        if (seconds <= 0.0 || device) return;
        carry += seconds * kRate;
        long total = long(std::floor(carry));
        carry -= double(total);
        nullBuf.resize(std::size_t(kNullBlock) * 2);
        float peak = 0.0f;
        drain_returns();
        while (total > 0) {
            const int n = int(std::min<long>(total, kNullBlock));
            mixer.apply_commands();
            mixer.mix_block(nullBuf.data(), n);
            mixer.publish_music();
            peak = std::max(peak, mixer.block_peak());
            drain_returns();
            drain_recorder();
            total -= n;
        }
        lastPeak = peak;
        process_ends();
    }

    static void stream_cb(float* buffer, int frames, int channels, void* user) {
        static_cast<Impl*>(user)->mixer.render(buffer, frames, channels);
    }

    // play() with the AudioSource entity id that requested it ("" for scripts). `*rejected`: the pool refused it (the clip
    // itself is fine).
    VoiceId start(std::string_view clipPath, const PlayParams& params, std::string_view source, bool* rejected = nullptr) {
        if (!inited) {
            FA_ERROR("audio", "Audio::play('{}') called before Audio::init()", clipPath);
            return 0;
        }
        auto clip = get_clip(clipPath);
        if (!clip) {
            log_play(clipPath, params, false, source, false);
            return 0;
        }
        GameVoice gv;
        gv.path = clip->path;
        gv.source = std::string(source);
        gv.priority = std::clamp(params.priority, 0, 255);
        if (clip->encoded) {
            std::string err;
            gv.stream = open_ring(*clip, params.loop, kStreamFrames, &gv.streamBytes, &err);
            if (!gv.stream) {
                log_play(clipPath, params, false, source, true);
                FA_ERROR("audio", "Audio clip '{}' cannot be streamed: {}", clipPath, err);
                return 0;
            }
        }
        gv.clip = std::move(clip);
        MixVoice mv;
        const VoiceId id = new_voice(std::move(gv), params, mv, rejected);
        if (id) send_play(id, mv, 0.0f, CmdKind::Droppable);
        log_play(clipPath, params, false, source, true, {}, id);
        return id;
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
        std::string err;
        auto clip = decode(path, &err);
        if (!clip) {
            if (failedLogged.insert(path).second) FA_ERROR("audio", "{}", err);
            return nullptr;
        }
        failedLogged.erase(path);
        return clips.emplace(path, clip).first->second;
    }

    // ---------------------------------------------------------------------------------------------------- music players
    // A command to a player's transport. The channel lives until the command that removes it from the mixer comes back
    // (retire()), and that command is sent after this one, so the pointer is valid when it runs. Only Keep commands (start,
    // stop, add) change what view() derives from the state, so only they move `lastSeq` (a dropped setting never leaves
    // the view waiting for a command that will not come).
    template <class F>
    void chan_cmd(MusicRt& rt, CmdKind kind, F fn) {
        if (!rt.ch) return;
        MusicChannel* ch = rt.ch.get();
        const std::uint64_t seq = send(make(kind, [ch, fn](Mixer&, Cmd&) { fn(ch->tr); }));
        if (kind == CmdKind::Keep) rt.lastSeq = seq;
    }
    // Starts `src` on the player (a crossfade when the transport plays and `hard` is false), after checking what the
    // transport would refuse. The source stays held until the mixer's state shows nothing reads it.
    bool send_start(MusicRt& rt, const std::shared_ptr<const MusicSource>& src, int section, float intensity,
                    MusicQuantize q, float bars, bool hard, std::string* err) {
        if (!rt.ch) {
            *err = "every music channel is taken";
            return false;
        }
        if (!MusicTransport::check_start(src.get(), section, err)) return false;
        const MusicSource* raw = src.get();
        chan_cmd(rt, CmdKind::Keep, [raw, section, intensity, q, bars, hard](MusicTransport& tr) {
            const MusicSource* from = tr.source();
            if (tr.playing() && !hard && from) {
                const float seconds = float(double(bars) * from->map.barFrames / double(kMusicRate));
                tr.crossfade_to(raw, section, q, seconds, nullptr);
            } else {
                tr.start(raw, section, intensity, nullptr);
            }
        });
        rt.held.push_back({src, rt.lastSeq});
        return true;
    }
};

// ===================================================================== API ====

Audio::Audio() : impl_(std::make_unique<Impl>()) {}

Audio::~Audio() { shutdown(); }

bool Audio::init(bool device, std::string* error) {
    if (impl_->inited) shutdown();
    Impl& im = *impl_;
    Impl::Call call(im);
    // Nothing mixes until `armed` (the device's first callbacks may come before the rate is known: they output silence).
    im.mixer.armed.store(false, std::memory_order_release);
    im.deviceRate = kRate;
    im.deviceChannels = 2;
    im.device = false;
    im.autoAdvance = false;
    im.manual = false;
    im.web = false;
    im.streamLogged = false;
    if (device) {
#if defined(__EMSCRIPTEN__)
        // The web has its own device (audio_web.cpp): an AudioWorkletNode, a ScriptProcessorNode as the fallback.
        const int webRate = audio_web_open(kRate, 2, &Impl::stream_cb, &im);
        if (webRate > 0) {
            im.device = true;
            im.web = true;
            im.deviceRate = std::max(webRate, 8000);
            im.deviceChannels = 2;
            FA_INFO("audio", "output device open: {} Hz, {} channels", im.deviceRate, im.deviceChannels);
            audio_web_unlock();  // the browser keeps the device silent until the player clicks, touches or presses a key
#else
        saudio_desc desc{};
        desc.sample_rate = kRate;
        desc.num_channels = 2;
        desc.stream_userdata_cb = &Impl::stream_cb;
        desc.user_data = &im;
        saudio_setup(&desc);
        if (saudio_isvalid()) {
            im.device = true;
            im.deviceRate = std::max(saudio_sample_rate(), 8000);
            im.deviceChannels = std::max(saudio_channels(), 1);
            FA_INFO("audio", "output device open: {} Hz, {} channels", im.deviceRate, im.deviceChannels);
#endif
        } else {
#if !defined(__EMSCRIPTEN__)
            saudio_shutdown();
#endif
            FA_WARN("audio", "no audio output device available; running with a silent null device "
                             "(hint: pass --headless to silence this warning)");
            im.autoAdvance = true;
            if (error) error->clear();
        }
    }
    im.mixer.set_device_rate(im.deviceRate);
    // The null device mixes on the game thread and the web's device on the main thread between frames: a streamed voice
    // with nothing decoded decodes right there. A device thread never decodes (decode jobs keep its rings ahead).
    im.mixer.set_sync_fill(!im.device || im.web);
    im.inited = true;
    // Release: the rate and the fill mode above are written before the callback that sees `armed` reads them.
    im.mixer.armed.store(true, std::memory_order_release);
    return true;
}

void Audio::shutdown() {
    Impl& im = *impl_;
    Impl::Call call(im);
    if (!im.inited) return;
    if (im.device && !im.manual) {
#if defined(__EMSCRIPTEN__)
        audio_web_close();
#else
        saudio_shutdown();  // joins the audio thread: nothing mixes from here on
#endif
    }
    im.mixer.armed.store(false, std::memory_order_release);
    im.device = false;  // from here every command runs at once, on this thread
    im.manual = false;
    im.web = false;
    im.mixer.set_sync_fill(true);
    im.settle();
    for (auto& [id, v] : im.voices) v.stopped = true;
    im.send(Impl::make(CmdKind::Keep, [](Mixer& m, Cmd&) { m.end_all_voices(); }));
    im.music_shutdown();
    if (im.recRing) {
        im.send_rec(nullptr);
        im.recRing.reset();
    }
    im.settle();
    for (const jobs::Handle& h : im.jobsInFlight) (void)jobs::wait(h);  // a job still holds what it reads: only tidiness
    im.jobsInFlight.clear();
    im.process_ends();
    im.voices.clear();
    im.ended.clear();
    im.clips.clear();
    im.untraced.clear();
    im.ents.clear();
    im.videos.clear();
    im.musicVoice = 0;
    im.musicPath.clear();
    im.musicPersist = false;
    im.layers.clear();
    im.recording = false;
    im.rec.clear();
    im.inited = false;
    im.lastWorld = nullptr;
    im.sceneMusic.clear();
    im.sceneMusicVolume = -1.0f;
    im.clockWorld = nullptr;
    im.playLog.clear();
    im.playDropped = 0;
}

bool Audio::load(std::string_view clipPath) {
    Impl::Call call(*impl_);
    return impl_->get_clip(clipPath) != nullptr;
}

std::shared_ptr<const void> Audio::decode_clip(std::string_view clipPath, std::string* error) {
    std::string err;
    auto clip = Impl::decode(fs::normalize(clipPath), &err);
    if (!clip && error) *error = err;
    return clip;
}

bool Audio::clip_loaded(std::string_view clipPath) const {
    const std::string path = fs::normalize(clipPath);
    Impl::Call call(*impl_);
    return impl_->clips.count(path) > 0;
}

bool Audio::adopt_clip(std::string_view clipPath, std::shared_ptr<const void> decoded, std::vector<std::string> files) {
    if (!decoded) return false;
    const std::string path = fs::normalize(clipPath);
    Impl::Call call(*impl_);
    Impl& im = *impl_;
    if (im.clips.count(path)) return false;  // loaded on first use meanwhile: that one stays
    im.clips.emplace(path, std::static_pointer_cast<const Clip>(decoded));
    im.failedLogged.erase(path);
    if (!files.empty()) im.untraced[path] = std::move(files);
    return true;
}

VoiceId Audio::play(std::string_view clipPath, const PlayParams& params) {
    Impl::Call call(*impl_);
    return impl_->start(clipPath, params, "");
}

VoiceId Audio::open_pcm_voice(int sampleRate, const PlayParams& params, std::string_view path, std::string_view source) {
    Impl::Call call(*impl_);
    Impl& im = *impl_;
    if (!im.inited) {
        FA_ERROR("audio", "Audio::open_pcm_voice('{}') called before Audio::init()", path);
        return 0;
    }
    GameVoice gv;
    gv.pcm = std::make_shared<PcmRing>(std::max(sampleRate, 1));
    gv.path = fs::normalize(path);
    gv.source = std::string(source);
    gv.priority = std::clamp(params.priority, 0, 255);
    MixVoice mv;
    const VoiceId id = im.new_voice(std::move(gv), params, mv, nullptr);
    if (id) im.send_play(id, mv, 0.0f, CmdKind::Droppable);
    im.log_play(path, params, false, source, true, {}, id);
    return id;
}

void Audio::push_pcm(VoiceId voice, const float* stereo, std::size_t frames) {
    Impl::Call call(*impl_);
    GameVoice* v = impl_->live_voice(voice);
    if (!v || !v->pcm || frames == 0) return;
    v->pcm->push(stereo, frames);
}

double Audio::pcm_queued_frames(VoiceId voice) const {
    Impl::Call call(*impl_);
    GameVoice* v = impl_->live_voice(voice);
    if (!v || !v->pcm) return 0.0;
    return v->pcm->queued();
}

bool Audio::has_device() const {
    Impl::Call call(*impl_);
    return impl_->device;
}

void Audio::clear_pcm(VoiceId voice) {
    Impl::Call call(*impl_);
    GameVoice* v = impl_->live_voice(voice);
    if (!v || !v->pcm) return;
    v->pcm->clear();
}

void Audio::set_voice_bus(VoiceId voice, std::string_view bus) {
    Impl::Call call(*impl_);
    Impl& im = *impl_;
    GameVoice* v = im.live_voice(voice);
    if (!v) return;
    int b = im.bus_index(bus);
    if (b < 0) {
        FA_ERROR("audio", "Unknown audio bus '{}'. {} (using 'sfx')", bus, did_you_mean(bus, im.bus_names_locked(false)));
        b = BusSfx;
    }
    v->bus = b;
    im.send(Impl::make(CmdKind::Droppable, [voice, b](Mixer& m, Cmd&) {
        MixVoice* mv = m.find_voice(voice);
        if (mv && std::size_t(b) < m.table->bus.size()) mv->bus = b;
    }));
}

void Audio::stop(VoiceId voice) {
    Impl::Call call(*impl_);
    impl_->hard_stop(voice, true);
}

void Audio::stop_all() {
    Impl::Call call(*impl_);
    Impl& im = *impl_;
    im.ended.clear();
    for (auto& [id, v] : im.voices) v.stopped = true;
    // A play still staged reaches the mixer before this and is ended by it.
    im.send(Impl::make(CmdKind::Keep, [](Mixer& m, Cmd&) { m.end_all_voices(); }));
    im.musicVoice = 0;
    im.musicPath.clear();
    im.musicPersist = false;
    im.layers.clear();
    // The MusicPlayer components' music too: it fades out over 50 ms and the components read the end (playing = false).
    for (auto& [bits, rt] : im.musicEnts) im.chan_stop(*rt, MusicQuantize::None, 0.05f);
    for (auto& rt : im.musicOrphans) im.chan_stop(*rt, MusicQuantize::None, 0.05f);
}

void Audio::on_scene_load() {
    Impl::Call call(*impl_);
    Impl& im = *impl_;
    im.ended.clear();  // the scene that asked to be told is gone
    std::vector<VoiceId> keep;
    if (im.musicPersist) {
        // The persisted track (or layers) plays on; everything else stops.
        if (im.musicVoice) keep.push_back(im.musicVoice);
        for (const Impl::Layer& l : im.layers) keep.push_back(l.voice);
    } else {
        im.musicVoice = 0;
        im.musicPath.clear();
        im.layers.clear();
    }
    std::vector<VoiceId> stop;
    for (const auto& [id, v] : im.voices)
        if (!v.stopped && std::find(keep.begin(), keep.end(), id) == keep.end()) stop.push_back(id);
    for (VoiceId id : stop) im.hard_stop(id, false);
    // The new scene's SceneSettings.music starts from scratch: update() sees it as a change.
    im.sceneMusic.clear();
    im.sceneMusicVolume = -1.0f;
}

bool Audio::is_playing(VoiceId voice) const {
    Impl::Call call(*impl_);
    impl_->sync_in();
    return impl_->live_voice(voice) != nullptr;
}

void Audio::set_voice_volume(VoiceId voice, float volume, float fadeSeconds, bool log) {
    Impl::Call call(*impl_);
    Impl& im = *impl_;
    GameVoice* v = im.live_voice(voice);
    if (!v) return;
    const float target = std::max(volume, 0.0f);
    v->volume = target;
    im.send(Impl::make(CmdKind::Droppable, [voice, target, fadeSeconds](Mixer& m, Cmd&) {
        if (MixVoice* mv = m.find_voice(voice)) m.start_volume_ramp(*mv, target, fadeSeconds);
    }));
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
    ev.volume = target;
    ev.pitch = v->pitch;
    ev.pan = v->pan;
    ev.fade = std::max(fadeSeconds, 0.0f);
    ev.bus = im.bus[std::size_t(v->bus)].name;
    ev.loop = v->loop;
    ev.source = v->source;
    im.push_log(std::move(ev));
}

Json Audio::active_voices() const {
    Impl::Call call(*impl_);
    Impl& im = *impl_;
    im.sync_in();
    Json list = Json::array();
    for (const auto& [id, v] : im.voices) {
        if (v.stopped) continue;
        list.push_back(Json::object({{"id", id}, {"path", v.path}, {"bus", im.bus[std::size_t(v.bus)].name},
                                     {"volume", v.volume}, {"pitch", v.pitch}, {"pan", v.pan},
                                     {"loop", v.loop}, {"music", v.music}, {"source", v.source}}));
    }
    return list;
}

std::vector<VoiceId> Audio::take_ended_voices() {
    Impl::Call call(*impl_);
    impl_->sync_in();
    std::vector<VoiceId> out(impl_->ended.begin(), impl_->ended.end());
    impl_->ended.clear();  // keeps its capacity: the next endings cost no allocation
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

void Audio::set_bus_volume(std::string_view bus, float volume, float fadeSeconds) {
    volume = clamp(volume, 0.0f, kMaxBusVolume);
    Impl::Call call(*impl_);
    Impl& im = *impl_;
    const int b = im.fx_index(bus);
    if (b < 0) {
        FA_ERROR("audio", "{}", unknown_bus_error(bus, im.bus_names_locked(true), true).message);
        return;
    }
    im.bus[std::size_t(b)].vol = volume;
    im.bus_cmd(b, CmdKind::Lossy, [volume, fadeSeconds](Mixer& m, BusRuntime& rt, Cmd&) {
        rt.vol.set(volume, m.ramp_frames(fadeSeconds, true));
    });
}

float Audio::bus_volume(std::string_view bus) const {
    Impl::Call call(*impl_);
    const int b = impl_->fx_index(bus);
    return b < 0 ? -1.0f : impl_->bus[std::size_t(b)].vol;
}

void Audio::set_master_volume(float volume) { set_bus_volume("master", volume, 0.0f); }

Result<void> Audio::set_bus_lowpass(std::string_view bus, float hz, float fadeSeconds) {
    Impl::Call call(*impl_);
    Impl& im = *impl_;
    const int b = im.fx_index(bus);
    if (b < 0) return unknown_bus_error(bus, im.bus_names_locked(true), true);
    if (!std::isfinite(hz) || hz < 0.0f)
        return make_error("A low-pass cutoff is a frequency in Hz, got " + std::to_string(hz),
                          "Use 20..20000 Hz, or 0 (or null in a script) to switch the filter off.");
    im.send_lowpass(b, hz, fadeSeconds);
    return {};
}

Result<void> Audio::set_bus_reverb(std::string_view bus, float mix, float fadeSeconds) {
    Impl::Call call(*impl_);
    Impl& im = *impl_;
    const int b = im.fx_index(bus);
    if (b < 0) return unknown_bus_error(bus, im.bus_names_locked(true), true);
    if (!std::isfinite(mix) || mix < 0.0f || mix > 1.0f)
        return make_error("A reverb mix is a number from 0 to 1, got " + std::to_string(mix),
                          "0 is no reverb (and switches it off), 0.3 is a touch of room, 1 is all wet.");
    im.send_reverb(b, mix, fadeSeconds);
    return {};
}

Result<void> Audio::set_bus_duck(std::string_view bus, const DuckSettings& duck) {
    Impl::Call call(*impl_);
    Impl& im = *impl_;
    const int b = im.fx_index(bus);
    if (b < 0 || b == kMasterBus) return unknown_bus_error(bus, im.bus_names_locked(true), false);
    int by = -1;
    if (!std::isfinite(duck.amount) || duck.amount < 0.0f || duck.amount > 1.0f)
        return make_error("A duck amount is the fraction of the volume removed, 0..1, got " + std::to_string(duck.amount),
                          "0.5 halves the bus while the other one plays, 1 silences it, 0 turns ducking off.");
    if (!duck.by.empty() && duck.amount > 0.0f) {
        by = im.fx_index(duck.by);
        if (by < 0 || by == kMasterBus) return unknown_bus_error(duck.by, im.bus_names_locked(true), false);
        if (by == b)
            return make_error("The bus '" + std::string(bus) + "' cannot duck itself",
                              "Name the other bus, for example the voice-over bus that should push the music down.");
        if (!std::isfinite(duck.attack) || !std::isfinite(duck.release) || duck.attack < 0.0f || duck.release < 0.0f)
            return make_error("Duck attack and release are times in seconds, 0 or more",
                              "Typical values: attack 0.05, release 0.5.");
    }
    im.send_duck(b, by, duck);
    return {};
}

void Audio::set_buses(const std::vector<AudioBusDef>& defs) {
    Impl::Call call(*impl_);
    Impl& im = *impl_;
    std::vector<GameBus> old = std::move(im.bus);
    std::vector<std::string> oldDuckBy;  // by name: the indexes change with the table
    for (const GameBus& fx : old) oldDuckBy.push_back(fx.duckBy >= 0 ? old[std::size_t(fx.duckBy)].name : std::string());
    std::vector<std::string> oldNames;
    for (const GameBus& fx : old) oldNames.push_back(fx.name);
    im.reset_bus_table();
    for (int i = 0; i <= kMasterBus; ++i) im.bus[std::size_t(i)] = old[std::size_t(i)];
    std::vector<int> fromOld;
    for (int i = 0; i <= kMasterBus; ++i) fromOld.push_back(i);
    // Accept the buses whose parent is known, repeating until nothing more is placed (a parent may be declared after its child).
    std::vector<bool> placed(defs.size(), false);
    for (bool progress = true; progress;) {
        progress = false;
        for (std::size_t d = 0; d < defs.size(); ++d) {
            if (placed[d]) continue;
            const AudioBusDef& def = defs[d];
            const int parent = im.fx_index(def.parent.empty() ? "master" : def.parent);
            if (parent < 0 || im.fx_index(def.name) >= 0) continue;
            GameBus fx;
            int from = -1;
            for (std::size_t o = 0; o < oldNames.size(); ++o)
                if (oldNames[o] == def.name) {
                    fx = old[o];
                    from = int(o);
                    break;
                }
            fx.name = def.name;
            fx.parent = parent;
            im.bus.push_back(std::move(fx));
            fromOld.push_back(from);
            placed[d] = true;
            progress = true;
        }
    }
    for (std::size_t d = 0; d < defs.size(); ++d)
        if (!placed[d])
            FA_ERROR("audio", "audio bus '{}' is skipped: its parent '{}' is not a bus, it loops, or the name is taken "
                              "(`factoria validate` checks \"audio\".\"buses\")", defs[d].name, defs[d].parent);
    for (std::size_t i = 0; i < im.bus.size(); ++i) {
        GameBus& fx = im.bus[i];
        fx.duckBy = -1;
        const auto was = std::find(oldNames.begin(), oldNames.end(), fx.name);
        if (was == oldNames.end() || oldDuckBy[std::size_t(was - oldNames.begin())].empty()) {
            fx.duck = DuckSettings{};
            continue;
        }
        const int by = im.bus_index(oldDuckBy[std::size_t(was - oldNames.begin())]);
        if (by >= 0 && by != int(i)) fx.duckBy = by;
        else fx.duck = DuckSettings{};
    }
    // The mixer's table, built whole here: the runtimes (gains, filters, reverbs) move over by name, the voices of a bus
    // that is gone go to sfx.
    auto t = std::make_unique<MixTable>();
    t->bus.resize(im.bus.size());
    t->fromOld = fromOld;
    t->duckBy.assign(im.bus.size(), -1);
    for (std::size_t i = 0; i < im.bus.size(); ++i) {
        t->bus[i].parent = im.bus[i].parent;
        t->duckBy[i] = im.bus[i].duckBy;
    }
    t->voiceRemap.assign(old.size(), int(BusSfx));
    for (std::size_t o = 0; o < old.size(); ++o) {
        if (int(o) < BusBuiltin) t->voiceRemap[o] = int(o);
        else if (int(o) >= kFirstProjectBus) {
            const int now = im.bus_index(oldNames[o]);
            t->voiceRemap[o] = now < 0 ? int(BusSfx) : now;
        }
    }
    t->build();
    for (auto& [id, v] : im.voices) v.bus = v.bus >= 0 && std::size_t(v.bus) < t->voiceRemap.size() ? t->voiceRemap[std::size_t(v.bus)] : int(BusSfx);
    // Music players follow their bus by name; one whose bus is gone plays on "music".
    std::vector<std::pair<MusicChannel*, int>> players;
    auto follow = [&](MusicRt& rt) {
        const int b = im.bus_index(rt.busName);
        rt.bus = b < 0 ? int(BusMusic) : b;
        if (rt.ch) players.emplace_back(rt.ch.get(), rt.bus);
    };
    for (auto& [bits, rt] : im.musicEnts) follow(*rt);
    for (auto& rt : im.musicOrphans) follow(*rt);
    Cmd* c = Impl::make(CmdKind::Keep, [players](Mixer& m, Cmd& cmd) {
        m.swap_table(cmd);
        for (const auto& [ch, b] : players) ch->bus = b;
    });
    c->table = std::move(t);
    im.send(c);
}

std::vector<std::string> Audio::bus_names() const {
    Impl::Call call(*impl_);
    return impl_->bus_names_locked(true);
}

Json Audio::bus_state(std::string_view bus) const {
    Impl::Call call(*impl_);
    const int b = impl_->fx_index(bus);
    if (b < 0) return Json();
    return impl_->bus_state_json(impl_->bus[std::size_t(b)]);
}

Json Audio::Impl::bus_state_json(const GameBus& fx) const {
    Json j = Json::object();
    j["volume"] = fx.vol;
    j["snapshotVolume"] = fx.snap;
    j["lowpass"] = fx.lpHz;
    j["reverb"] = fx.reverb;
    if (fx.duckBy >= 0) {
        j["duck"] = Json::object({{"by", bus[std::size_t(fx.duckBy)].name}, {"amount", fx.duck.amount}, {"attack", fx.duck.attack},
                                  {"release", fx.duck.release}});
    } else {
        j["duck"] = nullptr;
    }
    return j;
}

void Audio::set_snapshots(AudioSnapshots catalog) {
    Impl::Call call(*impl_);
    impl_->snapshots = std::move(catalog);
}

std::vector<std::string> Audio::snapshot_names() const {
    Impl::Call call(*impl_);
    std::vector<std::string> names;
    for (const auto& [name, snap] : impl_->snapshots) names.push_back(name);
    return names;
}

std::string Audio::current_snapshot() const {
    Impl::Call call(*impl_);
    return impl_->snapshotName;
}

Result<void> Audio::apply_snapshot(std::string_view name, float fadeSeconds) {
    Impl::Call call(*impl_);
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
    // One command for every bus: the whole snapshot lands in the same block.
    struct BusWant {
        float volume, lowpass, reverb;
        int duckBy;
        float amount, attack, release;
    };
    std::vector<BusWant> wants;
    for (int b = 0; b < int(im.bus.size()); ++b) {
        GameBus& fx = im.bus[std::size_t(b)];
        auto entry = snap.buses.find(fx.name);
        const BusSnapshot& want = entry != snap.buses.end() ? entry->second : neutral;
        int by = -1;
        if (want.duck && b != kMasterBus && want.duck->amount > 0.0f) by = im.bus_index(want.duck->by);
        if (by == kMasterBus || by == b) by = -1;
        fx.snap = want.volume;
        fx.lpHz = want.lowpass <= 0.0f ? 0.0f : clamp(want.lowpass, 20.0f, im.lowpass_top());
        fx.reverb = std::max(want.reverb, 0.0f);
        if (want.reverb > 0.0f) im.give_reverb(b);
        fx.duckBy = by;
        fx.duck = by >= 0 ? *want.duck : DuckSettings{};
        wants.push_back({want.volume, want.lowpass, want.reverb, by, fx.duck.amount, fx.duck.attack, fx.duck.release});
    }
    im.send(Impl::make(CmdKind::Lossy, [busWants = std::move(wants), fade](Mixer& m, Cmd&) {
        const std::size_t n = std::min(busWants.size(), m.table->bus.size());
        for (std::size_t b = 0; b < n; ++b) {
            BusRuntime& rt = m.table->bus[b].rt;
            const BusWant& w = busWants[b];
            rt.snap.set(w.volume, m.ramp_frames(fade, true));
            m.set_lowpass(rt, w.lowpass, fade);
            std::unique_ptr<audio_detail::Reverb> none;  // the reverb came with give_reverb()
            m.set_reverb(rt, w.reverb, fade, none);
            m.set_duck(rt, w.duckBy, w.amount, w.attack, w.release);
        }
    }));
    im.snapshotName = std::string(name);
    return {};
}

void Audio::reset_bus_effects() {
    Impl::Call call(*impl_);
    Impl& im = *impl_;
    for (GameBus& fx : im.bus) {
        fx.snap = 1.0f;
        fx.lpHz = 0.0f;
        fx.reverb = 0.0f;
        fx.duckBy = -1;
        fx.duck = DuckSettings{};
    }
    im.send(Impl::make(CmdKind::Keep, [](Mixer& m, Cmd&) {
        std::unique_ptr<audio_detail::Reverb> none;
        for (audio_detail::MixBus& mb : m.table->bus) {
            BusRuntime& fx = mb.rt;
            fx.snap.set(1.0f, 0);
            m.set_lowpass(fx, 0.0f, 0.0f);
            m.set_reverb(fx, 0.0f, 0.0f, none);
            m.set_duck(fx, -1, 0.0f, 0.0f, 0.0f);
            fx.duckGain = 1.0f;
            fx.duckEnv = 0.0f;
        }
    }));
    im.snapshotName.clear();
}

void Audio::play_music(std::string_view clipPath, float volume, float fadeSeconds, bool persist) {
    Impl::Call call(*impl_);
    Impl& im = *impl_;
    auto clip = im.get_clip(clipPath);
    PlayParams p;
    p.volume = volume;
    p.loop = true;
    p.bus = "music";
    // The track is already playing: not a new play (not logged), only a retune.
    const bool retune = clip && im.live_voice(im.musicVoice) && im.musicPath == clip->path;
    if (!retune) im.log_play(clipPath, p, true, "", clip != nullptr);
    if (!clip) return;
    if (retune) {
        im.drop_layers(std::max(fadeSeconds, 0.0f));
        const VoiceId id = im.musicVoice;
        const float vol = std::max(volume, 0.0f), fade = std::max(fadeSeconds, 0.0f);
        im.live_voice(id)->volume = vol;
        im.musicPersist = persist;
        im.send(Impl::make(CmdKind::Keep, [id, vol, fade](Mixer& m, Cmd&) {
            MixVoice* v = m.find_voice(id);
            if (!v) return;
            v->volume = vol;
            v->volFrames = 0;
            if (v->fadeTarget < 1.0f) m.start_fade(*v, 1.0f, fade, false);
        }));
        return;
    }
    GameVoice gv;
    gv.path = clip->path;
    gv.music = true;
    gv.priority = kMusicPriority;
    if (clip->encoded) {
        std::string err;
        gv.stream = Impl::open_ring(*clip, true, kMusicStreamFrames, &gv.streamBytes, &err);
        if (!gv.stream) {
            FA_ERROR("audio", "Music '{}' cannot be streamed: {}", clipPath, err);
            return;
        }
    }
    gv.clip = clip;
    im.drop_layers(std::max(fadeSeconds, 0.0f));
    if (im.musicVoice) im.fade_stop(im.musicVoice, fadeSeconds);
    MixVoice mv;
    const VoiceId id = im.new_voice(std::move(gv), p, mv, nullptr);
    if (id) im.send_play(id, mv, fadeSeconds, CmdKind::Keep);
    im.musicVoice = id;
    im.musicPath = clip->path;
    im.musicPersist = persist;
}

bool Audio::play_music_layers(const std::vector<MusicLayer>& layers, float volume, float fadeSeconds, bool persist) {
    Impl::Call call(*impl_);
    Impl& im = *impl_;
    if (layers.empty()) return false;
    struct Loaded {
        std::shared_ptr<const Clip> clip;
        std::shared_ptr<StreamRing> stream;
        std::size_t bytes = 0;
        const MusicLayer* spec;
    };
    PlayParams p;
    p.volume = volume;
    p.loop = true;
    p.bus = "music";
    std::vector<Loaded> loaded;
    bool ok = true;
    for (const MusicLayer& l : layers) {
        auto clip = im.get_clip(l.path);
        im.log_play(l.path, p, true, "", clip != nullptr, l.name);
        if (!clip) {
            ok = false;
            continue;
        }
        Loaded ld{clip, nullptr, 0, &l};
        if (clip->encoded) {
            std::string err;
            ld.stream = Impl::open_ring(*clip, true, kMusicStreamFrames, &ld.bytes, &err);
            if (!ld.stream) {
                FA_ERROR("audio", "Music layer '{}' ('{}') cannot be streamed: {}", l.name, l.path, err);
                ok = false;
                continue;
            }
        }
        loaded.push_back(std::move(ld));
    }
    if (!ok || loaded.empty()) return false;  // all or nothing: a missing layer would drift out of the mix
    if (im.musicVoice) im.fade_stop(im.musicVoice, fadeSeconds);
    im.musicVoice = 0;
    im.musicPath.clear();
    im.drop_layers(std::max(fadeSeconds, 0.0f));
    // Every layer's play is in the commands of this one call: the mixer applies them together, so they start on the
    // same sample.
    for (Loaded& l : loaded) {
        const float level = std::max(l.spec->level, 0.0f);
        PlayParams lp = p;
        lp.volume = volume * level;
        GameVoice gv;
        gv.path = l.clip->path;
        gv.music = true;
        gv.priority = kMusicPriority;
        gv.clip = l.clip;
        gv.stream = l.stream;
        gv.streamBytes = l.bytes;
        MixVoice mv;
        const VoiceId id = im.new_voice(std::move(gv), lp, mv, nullptr);
        if (id) im.send_play(id, mv, fadeSeconds, CmdKind::Keep);
        im.layers.push_back({l.spec->name, id, level});
    }
    im.layerVolume = volume;
    im.musicPersist = persist;
    return true;
}

bool Audio::set_layer(std::string_view name, float level, float fadeSeconds) {
    Impl::Call call(*impl_);
    Impl& im = *impl_;
    for (Impl::Layer& l : im.layers) {
        if (l.name != name) continue;
        l.level = std::max(level, 0.0f);
        if (GameVoice* v = im.live_voice(l.voice)) {
            const float target = std::max(im.layerVolume * l.level, 0.0f);
            v->volume = target;
            const VoiceId id = l.voice;
            im.send(Impl::make(CmdKind::Lossy, [id, target, fadeSeconds](Mixer& m, Cmd&) {
                if (MixVoice* mv = m.find_voice(id)) m.start_volume_ramp(*mv, target, fadeSeconds);
            }));
        }
        return true;
    }
    return false;
}

std::vector<std::string> Audio::layer_names() const {
    Impl::Call call(*impl_);
    std::vector<std::string> out;
    for (const Impl::Layer& l : impl_->layers) out.push_back(l.name);
    return out;
}

void Audio::stop_music(float fadeSeconds) {
    Impl::Call call(*impl_);
    Impl& im = *impl_;
    if (im.musicVoice) im.fade_stop(im.musicVoice, fadeSeconds);
    im.drop_layers(std::max(fadeSeconds, 0.0f));
    im.musicVoice = 0;
    im.musicPath.clear();
    im.musicPersist = false;
}

void Audio::set_paused(bool paused) {
    Impl::Call call(*impl_);
    impl_->paused = paused;
    impl_->send(Impl::make(CmdKind::Keep, [paused](Mixer& m, Cmd&) { m.paused = paused; }));
}

bool Audio::paused() const {
    Impl::Call call(*impl_);
    return impl_->paused;
}

void Audio::advance_null_device(double seconds) {
    Impl::Call call(*impl_);
    if (impl_->device) impl_->pump();
    else impl_->advance(seconds);
}

void Audio::service() {
    Impl::Call call(*impl_);
    if (impl_->inited) impl_->pump();
}

void Audio::set_clock(const World* world) {
    Impl::Call call(*impl_);
    impl_->clockWorld = world;
}

std::vector<AudioEvent> Audio::play_log(std::uint64_t afterSeq) const {
    Impl::Call call(*impl_);
    std::vector<AudioEvent> out;
    for (const AudioEvent& ev : impl_->playLog)
        if (ev.seq > afterSeq) out.push_back(ev);
    return out;
}

void Audio::clear_play_log() {
    Impl::Call call(*impl_);
    impl_->playLog.clear();
    impl_->playDropped = 0;
}

std::uint64_t Audio::play_log_dropped() const {
    Impl::Call call(*impl_);
    return impl_->playDropped;
}

Json AudioEvent::to_json() const {
    return Json::object({{"kind", kind}, {"voice", voice}, {"fade", fade}, {"seq", seq}, {"frame", frame}, {"time", time}, {"path", path}, {"volume", volume},
                         {"pitch", pitch}, {"pan", pan}, {"bus", bus}, {"loop", loop}, {"music", music},
                         {"source", source}, {"ok", ok}, {"layer", layer}});
}

void Audio::start_recording() {
    Impl::Call call(*impl_);
    Impl& im = *impl_;
    im.rec.clear();
    im.recording = true;
    im.recWarned = false;
    im.recLostWarned = false;
    im.recRate = im.deviceRate;
    auto ring = std::make_shared<SampleRing>(kRecordRingFloats);
    im.send_rec(ring);
    im.recRing = std::move(ring);
}

bool Audio::stop_recording(std::string_view wavPath, std::string* error, std::vector<std::int16_t>* pcmOut, int* rateOut) {
    std::vector<float> rec;
    int rate;
    {
        Impl::Call call(*impl_);
        Impl& im = *impl_;
        if (!im.recording) {
            if (error) *error = "audio recording was not started (hint: call start_recording() first)";
            return false;
        }
        im.drain_recorder();
        im.recording = false;
        im.send_rec(nullptr);
        im.recRing.reset();
        rec = std::move(im.rec);
        im.rec.clear();
        rate = im.recRate;
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
    Impl::Call call(*impl_);
    Impl& im = *impl_;
    im.sync_in();
    im.drain_recorder();
    Json j = Json::object();
    j["device"] = im.device;
    j["sampleRate"] = im.deviceRate;
    std::size_t active = 0;
    std::size_t decoded = 0;  // PCM resident: clips decoded whole, plus the buffers of the voices that stream
    for (const auto& [id, v] : im.voices) {
        if (v.stopped) continue;
        ++active;
        if (v.stream) decoded += v.streamBytes;
    }
    j["activeVoices"] = active;
    j["loadedClips"] = im.clips.size();
    Json names = Json::array();
    for (const auto& [path, clip] : im.clips) names.push_back(path);
    j["clips"] = names;
    Json streamed = Json::array();
    for (const auto& [path, clip] : im.clips) {
        decoded += clip->data.size() * sizeof(float);
        if (clip->encoded) streamed.push_back(path);
    }
    j["decodedBytes"] = decoded;
    j["streamedClips"] = streamed;
    float peak = im.lastPeak;
    if (im.device) {
        // Relaxed: a statistic, one value the mixer writes alone; any recent block's peak will do.
        const std::uint32_t bits = im.mixer.peakBits.load(std::memory_order_relaxed);
        std::memcpy(&peak, &bits, sizeof(peak));
    }
    j["peak"] = peak;
    j["master"] = im.bus[std::size_t(kMasterBus)].vol;
    Json buses = Json::object();
    Json effects = Json::object();
    Json parents = Json::object();
    for (std::size_t i = 0; i < im.bus.size(); ++i) {
        const GameBus& fx = im.bus[i];
        if (int(i) != kMasterBus) {
            buses[fx.name] = fx.vol;
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
    // The real-time path (docs/SOUND.md, "The audio callback"). Relaxed loads: counters the mixer alone writes.
    j["underruns"] = im.mixer.underrunEvents.load(std::memory_order_relaxed);
    j["underrunFrames"] = im.mixer.underrunFrames.load(std::memory_order_relaxed);
    j["commandsDropped"] = im.commandsDropped;
    j["settingsDropped"] = im.settingsDropped;
    j["voicesStolen"] = im.voicesStolen;
    j["voicesRejected"] = im.voicesRejected;
    return j;
}

void Audio::reload_clip(std::string_view pathIn) {
    std::string path = fs::normalize(pathIn);
    std::string err;
    auto clip = Impl::decode(path, &err);  // outside the lock: decoding takes a while
    if (!clip) {
        FA_ERROR("audio", "reload failed, keeping the previous version: {}", err);
        return;
    }
    Impl::Call call(*impl_);
    Impl& im = *impl_;
    std::shared_ptr<const Clip> old;
    if (auto it = im.clips.find(path); it != im.clips.end()) old = it->second;
    im.clips[path] = clip;
    im.failedLogged.erase(path);
    // A voice that streams goes on with the file it opened; so does one on a clip that now streams.
    if (old && !clip->encoded) {
        bool any = false;
        for (auto& [id, v] : im.voices)
            if (v.clip == old && !v.stream && !v.pcm) {
                v.clip = clip;
                any = true;
            }
        if (any) {
            const Clip* from = old.get();
            const Clip* to = clip.get();
            Cmd* c = Impl::make(CmdKind::Keep, [from, to](Mixer& m, Cmd&) {
                for (std::size_t i = 0; i < m.voiceCount; ++i) {
                    MixVoice& v = m.voices[i];
                    if (v.clip != from || v.stream || v.pcm) continue;
                    v.clip = to;
                    const double frames = double(to->frames);
                    if (v.pos >= frames) v.pos = v.loop && frames > 0.0 ? std::fmod(v.pos, frames) : frames;
                }
            });
            c->keep = old;  // the mixer may read the old clip until this command has run
            im.send(c);
        }
    }
    // A song played from its rendered stems has them cached: a stem file that changed is a song that changed.
    std::vector<std::string> songs;
    for (const auto& [key, song] : im.musicCache)
        if (key.size() > 6 && key.compare(key.size() - 6, 6, "|stems") == 0) songs.push_back(key.substr(0, key.size() - 6));
    for (const std::string& song : songs) {
        const MusicStemPlan plan = music_stem_plan_of(song);
        bool uses = plan.mixPath == path;
        for (const MusicStemFile& f : plan.files) uses = uses || f.path == path;
        if (uses) im.music_invalidate(song);
    }
}

void Audio::reload_song(std::string_view songPath) {
    const std::string song = fs::normalize(songPath);
    if (song.empty()) return;
    Impl::Call call(*impl_);
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
    make_channel(ref);
    musicEnts[e.bits()] = std::move(rt);
    return ref;
}

// The player of a gone entity keeps sounding in `musicOrphans` (a player of the next scene with the same song adopts it; update() fades
// the rest out).
void Audio::Impl::music_orphan(MusicRt* rt) {
    auto it = musicEnts.find(rt->e.bits());
    if (it == musicEnts.end() || it->second.get() != rt) return;
    musicOrphans.push_back(std::move(it->second));
    musicEnts.erase(it);
}

// A transport in the mixer for the player. The mixer mixes at most kMaxPlayers: past that an orphan that has finished
// gives its channel up, else the oldest orphan; when every channel plays a live player, this one waits (music_drive asks
// again every frame).
void Audio::Impl::make_channel(MusicRt& rt) {
    if (rt.ch) return;
    std::size_t attached = 0;
    for (const auto& [bits, p] : musicEnts)
        if (p->ch) ++attached;
    for (const auto& p : musicOrphans)
        if (p->ch) ++attached;
    if (attached >= kMaxPlayers) {
        auto victim = musicOrphans.end();
        for (auto o = musicOrphans.begin(); o != musicOrphans.end(); ++o) {
            if (!(*o)->ch) continue;
            const MusicView v = view(**o);
            if (v.fresh && !v.active) {
                victim = o;
                break;
            }
            if (victim == musicOrphans.end()) victim = o;  // the oldest one, unless a finished one comes up
        }
        if (victim == musicOrphans.end()) {
            if (!channelWarned) {
                channelWarned = true;
                FA_WARN("audio", "more than {} MusicPlayers play at once: '{}' waits for one of them to stop", kMaxPlayers, rt.id);
            }
            return;
        }
        std::unique_ptr<MusicRt> gone = std::move(*victim);
        musicOrphans.erase(victim);
        retire(std::move(gone));
    }
    rt.ch = std::make_unique<MusicChannel>();
    rt.ch->bus = rt.bus;
    MusicChannel* ch = rt.ch.get();
    rt.lastSeq = send(make(CmdKind::Keep, [ch](Mixer& m, Cmd&) { m.add_player(ch); }));
}

// Takes the player's transport out of the mixer. The command carries the channel and the sources it may read: they are
// freed when it comes back (drain_returns), after the mixer has let go of them.
void Audio::Impl::retire(std::unique_ptr<MusicRt> rt) {
    if (!rt || !rt->ch) return;
    MusicChannel* ch = rt->ch.get();
    Cmd* c = make(CmdKind::Keep, [ch](Mixer& m, Cmd&) { m.remove_player(ch); });
    c->channel = std::move(rt->ch);
    for (HeldSource& h : rt->held) c->sources.push_back(std::move(h.src));
    rt->held.clear();
    send(c);
}

// Finds the source of rt.song for the mode its component asks: the cache, a load in flight, or a new load (a job when a
// device thread mixes; in the call on the null device and the web, so a headless run has the music at once).
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
        if (device && !web && !autoAdvance) {
            // The job holds the load: a load given up meanwhile (music_invalidate) finishes into nothing.
            load->job = jobs::submit("audio.music_load", [load] { load->run(); });
            jobsInFlight.push_back(load->job);
        } else {
            load->run();
        }
    }
    music_poll();
    music_resolve(rt);
}

// Moves the loads that finished into the cache.
void Audio::Impl::music_poll() {
    for (auto it = musicLoads.begin(); it != musicLoads.end();) {
        MusicLoad& l = *it->second;
        // Acquire pairs with the release in MusicLoad::run(): source, error and note are complete.
        if (!l.done.load(std::memory_order_acquire)) {
            ++it;
            continue;
        }
        if (l.source) {
            if (!l.note.empty()) FA_WARN("audio", "song '{}' plays live instead of from its stems: {}", l.path, l.note);
            musicCache[l.key] = CachedSong{l.source, ++musicUse};
            music_trim(l.key);
        } else {
            musicErrors[l.key] = l.error;
            FA_ERROR("audio", "the song '{}' cannot be played: {}", l.path, l.error);
        }
        it = musicLoads.erase(it);
    }
    prune_jobs();
}

// Over the cache's budget, the sources nobody holds go, the least recently used first (`keepKey`, just loaded, stays).
void Audio::Impl::music_trim(const std::string& keepKey) {
    std::size_t total = 0;
    for (const auto& [k, c] : musicCache) total += c.src->bytes();
    while (total > musicCacheBudget) {
        auto victim = musicCache.end();
        for (auto c = musicCache.begin(); c != musicCache.end(); ++c) {
            if (c->first == keepKey || c->second.src.use_count() != 1) continue;  // a player (or the mixer) holds it
            if (victim == musicCache.end() || c->second.lastUse < victim->second.lastUse) victim = c;
        }
        if (victim == musicCache.end()) break;
        total -= victim->second.src->bytes();
        musicCache.erase(victim);
    }
}

void Audio::Impl::music_resolve(MusicRt& rt) {
    if (rt.waitKey.empty()) return;
    auto c = musicCache.find(rt.waitKey);
    if (c != musicCache.end()) {
        c->second.lastUse = ++musicUse;
        rt.src = c->second.src;
        rt.waitKey.clear();
    } else if (musicLoads.find(rt.waitKey) == musicLoads.end()) {
        auto err = musicErrors.find(rt.waitKey);
        rt.error = err != musicErrors.end() ? err->second : std::string("the song could not be loaded");
        rt.waitKey.clear();
    }
}

MusicView Audio::Impl::view(MusicRt& rt) {
    MusicView v;
    if (!rt.ch) return v;  // no transport: nothing plays
    rt.ch->snap.update();
    const MusicSnap& s = rt.ch->snap.front();
    v.state = &s.state;
    v.fresh = s.appliedSeq >= rt.lastSeq;
    if (v.fresh) {
        v.playing = s.state.playing;
        v.ended = s.state.ended;
        v.active = s.state.active;
        v.src = s.state.src;
    } else {  // the last start or stop has not reached the mixer: what it will make of the transport
        v.playing = rt.sent != nullptr;
        v.active = true;
        v.src = rt.sent.get();
    }
    return v;
}

void Audio::Impl::chan_stop(MusicRt& rt, MusicQuantize q, float fade) {
    chan_cmd(rt, CmdKind::Keep, [q, fade](MusicTransport& tr) { tr.stop(q, fade); });
}

// The events the player's transport queued, as game events (a null `world`: dropped, nobody listens), then the sources
// nothing reads any more are let go.
void Audio::Impl::music_events(World* world, MusicRt& rt) {
    if (!rt.ch) return;
    MusicChannel& ch = *rt.ch;
    // The state first, then the events (the mixer pushes the events before it publishes the state): every event made before
    // this state is in the ring now, so the sources freed below are named by no event still to come.
    ch.snap.update();
    MusicEvent ev;
    while (ch.events.pop(ev)) {
        if (!world) continue;
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
        world->events().game.push_back(GameEvent{name, std::move(d), rt.e});
    }
    const MusicSnap& s = ch.snap.front();
    if (s.backlog != 0) return;  // events still in the transport may name any source it had
    rt.held.erase(std::remove_if(rt.held.begin(), rt.held.end(),
                                 [&](const HeldSource& h) {
                                     if (h.seq > s.appliedSeq) return false;  // its start has not run yet
                                     for (std::size_t i = 0; i < s.state.refCount && i < s.state.refs.size(); ++i)
                                         if (s.state.refs[i] == h.src.get()) return false;
                                     return true;
                                 }),
                  rt.held.end());
}

// One MusicPlayer component against its player in the mixer: starts, stops, changes of song, volume, bus and intensity.
void Audio::Impl::music_drive(World& world, Entity e, MusicPlayer& mp, MusicRt& rt) {
    (void)e;
    if (!rt.ch) make_channel(rt);
    const std::string want = mp.song.empty() ? std::string() : fs::normalize(mp.song);
    bool adopted = false;
    if (rt.first) {
        rt.first = false;
        if (!want.empty() && mp.playOnStart) {
            for (auto o = musicOrphans.begin(); o != musicOrphans.end(); ++o) {
                MusicRt& old = **o;
                if (old.song != want || !old.src || old.sent != old.src || old.stopIssued || !old.ch || !view(old).playing) continue;
                // The new player takes the old one's transport over, where it is in the song.
                std::unique_ptr<MusicChannel> spare = std::move(rt.ch);
                rt.ch = std::move(old.ch);
                rt.held = std::move(old.held);
                rt.lastSeq = old.lastSeq;
                rt.busName = old.busName;
                rt.bus = old.bus;
                old.ch = std::move(spare);  // the channel made for the new player goes with the orphan (retired below)
                old.held.clear();
                std::unique_ptr<MusicRt> gone = std::move(*o);
                musicOrphans.erase(o);
                retire(std::move(gone));
                // `old` is gone: what is left to do uses the player that took its place.
                break;
            }
            const MusicView v = view(rt);
            adopted = rt.ch && v.playing && !v.ended;
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
                c->second.lastUse = ++musicUse;
                rt.src = c->second.src;
                rt.sent = c->second.src;
                rt.resolved = mode;
                rt.epoch = musicEpoch;
            } else {
                adopted = false;
                chan_stop(rt, MusicQuantize::None, 0.05f);
            }
        } else if (mp.playOnStart && !mp.playing) {
            mp.playing = true;
        }
    }

    if (mp.bus != rt.busName) {
        int b = bus_index(mp.bus);
        if (b < 0) {
            FA_ERROR("audio", "MusicPlayer on '{}': unknown audio bus '{}'. {} (using 'music')", rt.id, mp.bus,
                     did_you_mean(mp.bus, bus_names_locked(false)));
            b = BusMusic;
        }
        rt.busName = mp.bus;
        rt.bus = b;
        if (rt.ch) {
            MusicChannel* ch = rt.ch.get();
            send(make(CmdKind::Lossy, [ch, b](Mixer& m, Cmd&) {
                if (b >= 0 && std::size_t(b) < m.table->bus.size()) ch->bus = b;
            }));
        }
    }

    if (want != rt.song) {
        rt.song = want;
        if (want.empty()) {
            rt.src.reset();
            rt.waitKey.clear();
            rt.error.clear();
            if (rt.sent) chan_stop(rt, MusicQuantize::None, 0.3f);
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
                const MusicView v = view(rt);
                if (v.playing && v.state) current = MusicTransport::status_of(*v.state).section;
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
        if (!mp.playing && !rt.stopIssued) chan_stop(rt, MusicQuantize::None, 0.3f);
        if (!mp.playing) rt.sent.reset();
        rt.stopIssued = !mp.playing;
        rt.playing = mp.playing;
    }

    // hand the source to the transport (not before it has a channel: it waits for one)
    if (mp.playing && rt.src && rt.sent != rt.src && rt.ch) {
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
        const float bars = rt.entry.bars >= 0.0f ? rt.entry.bars : mp.crossfadeBars;
        std::string err;
        const bool ok = send_start(rt, rt.src, section, music_unit(mp.intensity), q, bars, rt.entry.hard, &err);
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

    // a song that played through to its end (the mixer's state once it has the last start or stop)
    const MusicView v = view(rt);
    if (mp.playing && rt.sent && v.fresh && v.ended) {
        mp.playing = false;
        rt.playing = false;
        rt.sent.reset();
    }

    const float vol = clamp(std::isfinite(mp.volume) ? mp.volume : 0.0f, 0.0f, 4.0f);
    if (vol != rt.volume && rt.ch) {
        const float fade = rt.volume < 0.0f ? 0.0f : 0.05f;
        chan_cmd(rt, CmdKind::Lossy, [vol, fade](MusicTransport& tr) { tr.set_volume(vol, fade); });
        rt.volume = vol;
    }
    if (mp.loop != rt.loop && rt.ch) {
        const bool loop = mp.loop;
        chan_cmd(rt, CmdKind::Lossy, [loop](MusicTransport& tr) { tr.set_loop(loop); });
        rt.loop = mp.loop;
    }
    if ((mp.layerFade != rt.layerFade || mp.layerRange != rt.layerRange) && rt.ch) {
        const float fade = std::max(mp.layerFade, 0.0f), range = std::max(mp.layerRange, 0.0f);
        chan_cmd(rt, CmdKind::Lossy, [fade, range](MusicTransport& tr) { tr.set_layer_fade(fade, range); });
        rt.layerFade = mp.layerFade;
        rt.layerRange = mp.layerRange;
    }
    const float inten = music_unit(mp.intensity);
    if (rt.sent && inten != rt.intensity) {
        const MusicQuantize q = mp.layerQuantize;
        chan_cmd(rt, CmdKind::Lossy, [inten, q](MusicTransport& tr) { tr.set_intensity(inten, q); });
        rt.intensity = inten;
    }
    // runtime fields: the mixer's latest state (a block behind the commands of this frame with a device)
    const MusicStatus st = v.state ? MusicTransport::status_of(*v.state) : MusicStatus{};
    mp.ready = rt.src != nullptr;
    mp.section = st.section;
    mp.bar = st.playing ? st.bar : 0;
    mp.beat = st.playing ? st.beat : 0;
    mp.tempo = st.playing ? float(st.tempo) : 0.0f;
    mp.activeMode = st.playing ? st.mode : (rt.src ? rt.src->mode : std::string());
    music_events(&world, rt);
}

void Audio::Impl::music_update(World& world) {
    music_poll();
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
                if (!rt.stopIssued) chan_stop(rt, MusicQuantize::None, 0.3f);
                mp->playing = false;
                rt.playing = false;
                rt.stopIssued = true;
                rt.sent.reset();
            }
            rt.first = false;
            music_events(&world, rt);
            continue;
        }
        music_drive(world, e, *mp, rt);
    }
    // What nobody adopted fades out and goes once the mixer says it is silent.
    for (auto it = musicOrphans.begin(); it != musicOrphans.end();) {
        MusicRt& o = **it;
        if (!o.ch) {
            it = musicOrphans.erase(it);
            continue;
        }
        if (!o.stopIssued) {
            chan_stop(o, MusicQuantize::None, 0.5f);
            o.stopIssued = true;
        }
        music_events(nullptr, o);  // its entity is gone: nobody listens
        const MusicView v = view(o);
        if (v.fresh && !v.active) {
            std::unique_ptr<MusicRt> gone = std::move(*it);
            it = musicOrphans.erase(it);
            retire(std::move(gone));
        } else {
            ++it;
        }
    }
}

void Audio::Impl::music_shutdown() {
    for (auto& [bits, rt] : musicEnts) retire(std::move(rt));
    for (auto& rt : musicOrphans) retire(std::move(rt));
    musicEnts.clear();
    musicOrphans.clear();
    settle();
    musicLoads.clear();  // a load still running is held by its job (shutdown() waits for the jobs)
    musicCache.clear();
    musicErrors.clear();
}

void Audio::set_music_device(const MusicDeviceProfile& device) {
    Impl::Call call(*impl_);
    Impl& im = *impl_;
    const MusicDeviceProfile& old = im.musicDevice;
    if (old.formFactor != device.formFactor || old.tier != device.tier || old.web != device.web) ++im.musicEpoch;
    im.musicDevice = device;
}

// The song changed on disk: what was rendered of it is stale. The loads that run are given up (their jobs hold them until
// they finish), the cached sources dropped, and every player of the song fetches it again and crossfades into the new render
// (music_drive).
void Audio::Impl::music_invalidate(const std::string& song) {
    for (const char* mode : {"|live", "|stems"}) {
        const std::string key = song + mode;
        musicLoads.erase(key);
        musicCache.erase(key);
        musicErrors.erase(key);
    }
    for (auto& [bits, rt] : musicEnts)
        if (rt->song == song) rt->reload = true;
}

std::uint64_t Audio::mixed_frames() const {
    Impl::Call call(*impl_);
    impl_->sync_in();
    // Relaxed: a counter the mixer alone writes.
    return impl_->mixer.mixedTotal.load(std::memory_order_relaxed);
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
    Impl::Call call(*impl_);
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
    Impl::Call call(*impl_);
    Impl& im = *impl_;
    MusicPlayer* mp = world.alive(e) ? world.get<MusicPlayer>(e) : nullptr;
    if (!mp) return;
    mp->playing = false;
    MusicRt* rt = im.music_find(world, e);
    if (!rt) return;
    im.chan_stop(*rt, quantize, fadeSeconds < 0.0f ? 0.3f : fadeSeconds);
    rt->sent.reset();
    rt->stopIssued = true;
    rt->playing = false;
}

void Audio::music_set_intensity(World& world, Entity e, float intensity, std::optional<MusicQuantize> quantize) {
    Impl::Call call(*impl_);
    Impl& im = *impl_;
    MusicPlayer* mp = world.alive(e) ? world.get<MusicPlayer>(e) : nullptr;
    if (!mp) return;
    mp->intensity = music_unit(intensity);
    MusicRt* rt = im.music_find(world, e);
    if (!quantize || !rt || !rt->sent) return;
    const float inten = mp->intensity;
    const MusicQuantize q = *quantize;
    im.chan_cmd(*rt, CmdKind::Lossy, [inten, q](MusicTransport& tr) { tr.set_intensity(inten, q); });
    rt->intensity = inten;
}

Result<void> Audio::music_go_to_section(World& world, Entity e, std::string_view section, std::optional<MusicQuantize> quantize, float fadeSeconds) {
    Impl::Call call(*impl_);
    Impl& im = *impl_;
    MusicPlayer* mp = world.alive(e) ? world.get<MusicPlayer>(e) : nullptr;
    if (!mp) return no_player_error("music.goToSection");
    MusicRt& rt = im.music_get(world, e);
    const MusicSource* playing = im.view(rt).src;
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
    const int index = playing->map.section_index(section);
    const MusicQuantize q = quantize.value_or(mp->quantize);
    const float fade = fadeSeconds < 0.0f ? mp->transitionFade : fadeSeconds;
    // The transport checks again when the command runs (it may have stopped meanwhile): then the jump is not made.
    im.chan_cmd(rt, CmdKind::Droppable, [index, q, fade](MusicTransport& tr) { tr.go_to_section(index, q, fade, nullptr); });
    return {};
}

Result<void> Audio::music_play_stinger(World& world, Entity e, const MusicStingerSpec& spec) {
    Impl::Call call(*impl_);
    Impl& im = *impl_;
    MusicPlayer* mp = world.alive(e) ? world.get<MusicPlayer>(e) : nullptr;
    if (!mp) return no_player_error("music.playStinger");
    if (spec.clip.empty() == spec.section.empty())
        return make_error("music.playStinger: give exactly one of \"clip\" (an audio file) and \"section\" (a section of the song)",
                          "For example playStinger({clip: 'sfx/hit.wav', quantize: 'beat'}) or playStinger({section: 'victory'}).");
    MusicRt& rt = im.music_get(world, e);
    const MusicSource* playing = im.view(rt).src;
    if (!playing || !rt.sent || !rt.ch)
        return make_error("music.playStinger: nothing is playing, a stinger plays over the music",
                          "Start the music first (music.play), and wait for the 'music.ready' event when the song loads.");
    const MusicQuantize q = spec.quantize.value_or(mp->quantize);
    const float volume = std::isfinite(spec.volume) ? clamp(spec.volume, 0.0f, 4.0f) : 1.0f;
    const float duck = spec.duck > 0.0f ? clamp(spec.duck, 0.0f, 1.0f) : 0.0f;
    const float attack = spec.duckAttack, release = spec.duckRelease;
    if (!spec.section.empty()) {
        const int index = playing->map.section_index(spec.section);
        if (index < 0)
            return make_error("music.playStinger: song '" + playing->path + "' has no section '" + spec.section + "'. " +
                                  did_you_mean(spec.section, playing->map.section_names()),
                              "Pick one of the song's sections.");
        const MusicSpan& span = playing->map.spans[std::size_t(playing->map.sections[std::size_t(index)].firstSpan)];
        const float tail = std::max(spec.tail, 0.0f);
        const float length = float((span.end - span.start) / double(kMusicRate)) + tail;
        const float hold = spec.duckHold < 0.0f ? length : spec.duckHold;
        im.chan_cmd(rt, CmdKind::Droppable, [index, q, volume, tail, duck, attack, hold, release](MusicTransport& tr) {
            if (tr.play_section_stinger(index, q, volume, tail, nullptr) && duck > 0.0f) tr.duck(q, duck, attack, hold, release);
        });
        return {};
    }
    // A clip: its voice starts on the boundary's frame, which the mixer knows when the command runs.
    auto clip = im.get_clip(spec.clip);
    if (!clip) return make_error("music.playStinger: the clip '" + spec.clip + "' could not be loaded", "The error above says why; check the path (assets.list).");
    GameVoice gv;
    gv.path = clip->path;
    gv.source = rt.id;
    if (clip->encoded) {
        std::string err;
        gv.stream = Impl::open_ring(*clip, false, kStreamFrames, &gv.streamBytes, &err);
        if (!gv.stream) return make_error("music.playStinger: " + err, "");
    }
    gv.clip = clip;
    PlayParams p;
    p.volume = volume;
    p.bus = spec.bus.empty() ? rt.busName : spec.bus;
    gv.priority = std::clamp(p.priority, 0, 255);
    const float length = float(double(clip->frames) / double(kRate));
    const float hold = spec.duckHold < 0.0f ? length : spec.duckHold;
    MixVoice mv;
    const VoiceId id = im.new_voice(std::move(gv), p, mv, nullptr);
    if (id) {
        MusicChannel* ch = rt.ch.get();
        Cmd* c = Impl::make(CmdKind::Droppable, [mv, ch, q, duck, attack, hold, release](Mixer& m, Cmd&) {
            MixVoice v = mv;
            v.delay = long(std::clamp<std::int64_t>(ch->tr.schedule_clip_stinger(q), 0, std::numeric_limits<std::int32_t>::max()));
            if (duck > 0.0f) ch->tr.duck(q, duck, attack, hold, release);
            if (!m.add_voice(v)) {  // see send_play
                m.returns.push(Ret{Ret::Ended, nullptr, v.id});
                m.returns.commit();
            }
        });
        c->play = id;
        im.send(c);
    }
    im.log_play(spec.clip, p, false, rt.id, true, {}, id);
    return {};
}

Result<void> Audio::music_crossfade_to(World& world, Entity e, std::string_view song, std::string_view section, std::optional<MusicQuantize> quantize,
                                       float bars) {
    Impl::Call call(*impl_);
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

namespace {
MusicStatus status_with(const MusicTransportState* state, const MusicRt& rt) {
    MusicStatus st = state ? MusicTransport::status_of(*state) : MusicStatus{};
    st.exists = true;
    st.ready = rt.src != nullptr;
    if (rt.src) st.sections = rt.src->map.section_names();
    st.bus = rt.busName;
    st.error = rt.error;
    if (st.song.empty()) st.song = rt.song;
    return st;
}
}  // namespace

MusicStatus Audio::music_status(World& world, Entity e) const {
    Impl::Call call(*impl_);
    Impl& im = *impl_;
    MusicRt* rt = im.music_find(world, e);
    if (!rt) return MusicStatus{};
    return status_with(im.view(*rt).state, *rt);
}

Json Audio::music_players() const {
    Impl::Call call(*impl_);
    Impl& im = *impl_;
    Json out = Json::array();
    auto add = [&](MusicRt& rt, bool orphan) {
        Json j = status_with(im.view(rt).state, rt).to_json();
        j["entity"] = rt.id;
        j["orphan"] = orphan;
        out.push_back(std::move(j));
    };
    for (auto& [bits, rt] : im.musicEnts) add(*rt, false);
    for (auto& rt : im.musicOrphans) add(*rt, true);
    return out;
}

// ============================================================ world driving ==

void Audio::update(World& world, float dt) {
    Impl::Call call(*impl_);
    Impl& im = *impl_;
    if (!im.inited) return;
    if (im.autoAdvance) im.advance(dt);
    im.pump();

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
        bool rejected = false;  // a full mixer refusing it is no failure of the file
        if (im.start(fs.options.path, pp, fs.source, &rejected) == 0 && !rejected && feel.failedSounds.size() < 256)
            feel.failedSounds.insert(fs.options.path);
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
                p.priority = src->priority;
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
                if (ea.voice == 0) src->playing = false;  // load failed, or a full mixer refused it (both logged)
            }
        } else if (ea.voice != 0) {
            if (GameVoice* v = im.live_voice(ea.voice)) {
                const float vol = std::max(volume, 0.0f), pitch = std::max(src->pitch, 0.001f);
                if (vol != v->volume || pitch != v->pitch || pan != v->pan) {  // a command only for what changed
                    v->volume = vol;
                    v->pitch = pitch;
                    v->pan = pan;
                    im.send_params(ea.voice, vol, pitch, pan);
                }
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
            p.loop = true;
            p.priority = kVideoPriority;  // above a default sound when the mixer is full
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
            // a persisted track that is the scene's own music stays persisted
            const bool keep = im.musicPersist && im.musicPath == fs::normalize(ss.music);
            play_music(ss.music, ss.musicVolume, 0.5f, keep);
        }
    } else if (!ss.music.empty() && ss.musicVolume != im.sceneMusicVolume) {
        im.sceneMusicVolume = ss.musicVolume;
        if (GameVoice* v = im.live_voice(im.musicVoice)) {
            const float vol = std::max(ss.musicVolume, 0.0f);
            const VoiceId id = im.musicVoice;
            v->volume = vol;
            im.send(Impl::make(CmdKind::Keep, [id, vol](Mixer& m, Cmd&) {
                if (MixVoice* mv = m.find_voice(id)) {
                    mv->volume = vol;
                    mv->volFrames = 0;
                }
            }));
        }
    }
}

// ============================================================ test access ==

void AudioTestAccess::use_manual_device(Audio& audio, int rate) {
    Audio::Impl& im = *audio.impl_;
    Audio::Impl::Call call(im);
    im.settle();
    im.mixer.armed.store(false, std::memory_order_release);
    im.deviceRate = rate > 0 ? rate : kRate;
    im.mixer.set_device_rate(im.deviceRate);
    im.device = true;
    im.manual = true;
    im.autoAdvance = false;
    im.mixer.set_sync_fill(false);
    // Release: as in init(), the rate and the fill mode are visible to the render() that sees `armed`.
    im.mixer.armed.store(true, std::memory_order_release);
}

void AudioTestAccess::render(Audio& audio, float* out, int frames, int channels) {
    audio.impl_->mixer.render(out, frames, channels);
}

std::recursive_mutex& AudioTestAccess::api_mutex(Audio& audio) { return audio.impl_->apiMu; }

void AudioTestAccess::set_music_cache_budget(Audio& audio, std::size_t bytes) {
    Audio::Impl::Call call(*audio.impl_);
    audio.impl_->musicCacheBudget = bytes;
}

void AudioTestAccess::set_stream_service(Audio& audio, bool on) {
    Audio::Impl::Call call(*audio.impl_);
    audio.impl_->streamService = on;
}

void AudioTestAccess::pump(Audio& audio) {
    Audio::Impl::Call call(*audio.impl_);
    audio.impl_->pump();
}

std::vector<std::pair<std::string, std::size_t>> AudioTestAccess::music_cache(Audio& audio) {
    Audio::Impl::Call call(*audio.impl_);
    std::vector<std::pair<std::string, std::size_t>> out;
    for (const auto& [key, song] : audio.impl_->musicCache) out.emplace_back(key, song.src->bytes());
    return out;
}

}  // namespace fa
