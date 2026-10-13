// Software mixer: decoded clips -> voices -> buses -> master -> (device | null sink | recorder).
//
// Threading: in device mode sokol_audio calls render() on its own thread; every piece of state shared with the
// game thread (voices, bus volumes, recorder, clip cache) is protected by Impl::mu. The callback does no
// allocation except when the recorder grows, and decoding happens OUTSIDE the lock.
#include "fa/audio/audio.h"

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <cstring>
#include <map>
#include <mutex>
#include <set>

#include "dr_mp3.h"
#include "dr_wav.h"
#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "sokol_audio.h"

extern "C" int stb_vorbis_decode_memory(const unsigned char* mem, int len, int* channels, int* sample_rate,
                                        short** output);

namespace fa {

namespace {

constexpr int kRate = 44100;
constexpr std::size_t kMaxVoices = 64;
constexpr std::size_t kMaxRecordFrames = std::size_t(kRate) * 600;  // 10 minutes
constexpr int kBlock = 512;

enum Bus { BusSfx = 0, BusMusic = 1, BusUi = 2, BusCount = 3 };
const char* const kBusNames[BusCount] = {"sfx", "music", "ui"};

struct Clip {
    std::string path;
    std::vector<float> data;  // interleaved stereo, 44100 Hz
    std::size_t frames = 0;
    int srcChannels = 0;
    int srcRate = 0;
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
    bool dead = false;
};

struct EntityAudio {
    Entity e;
    std::string id;
    std::string clip;
    VoiceId voice = 0;
    bool started = false;
    std::uint64_t seen = 0;
};

std::string audio_extensions_hint() { return "supported formats: .wav, .ogg, .mp3"; }

bool is_audio_ext(const std::string& ext) { return ext == ".wav" || ext == ".ogg" || ext == ".mp3"; }

void resample_to_stereo(const float* in, std::size_t frames, int channels, int rate, std::vector<float>& out) {
    // 1. to stereo at source rate
    std::vector<float> st(frames * 2);
    for (std::size_t i = 0; i < frames; ++i) {
        if (channels == 1) {
            st[2 * i] = st[2 * i + 1] = in[i];
        } else {
            st[2 * i] = in[i * std::size_t(channels)];
            st[2 * i + 1] = in[i * std::size_t(channels) + 1];
        }
    }
    if (rate == kRate || rate <= 0 || frames == 0) {
        out = std::move(st);
        return;
    }
    // 2. linear resample to 44100
    double ratio = double(rate) / double(kRate);
    std::size_t n = std::size_t(std::ceil(double(frames) / ratio));
    out.assign(n * 2, 0.0f);
    for (std::size_t i = 0; i < n; ++i) {
        double p = double(i) * ratio;
        std::size_t i0 = std::min(std::size_t(p), frames - 1);
        std::size_t i1 = std::min(i0 + 1, frames - 1);
        float t = float(p - double(i0));
        out[2 * i] = st[2 * i0] + (st[2 * i1] - st[2 * i0]) * t;
        out[2 * i + 1] = st[2 * i0 + 1] + (st[2 * i1 + 1] - st[2 * i0 + 1]) * t;
    }
}

void write_le16(std::vector<std::uint8_t>& b, std::uint16_t v) {
    b.push_back(std::uint8_t(v & 0xff));
    b.push_back(std::uint8_t(v >> 8));
}
void write_le32(std::vector<std::uint8_t>& b, std::uint32_t v) {
    for (int i = 0; i < 4; ++i) b.push_back(std::uint8_t((v >> (8 * i)) & 0xff));
}

}  // namespace

struct Audio::Impl {
    mutable std::mutex mu;
    bool inited = false;
    bool device = false;
    bool autoAdvance = false;  // device requested but unavailable -> run as null device driven by update()
    int deviceRate = kRate;
    int deviceChannels = 2;

    std::map<std::string, std::shared_ptr<const Clip>> clips;
    std::set<std::string> failedLogged;

    std::vector<Voice> voices;
    VoiceId nextVoice = 1;
    float busVol[BusCount] = {1, 1, 1};
    float master = 1.0f;
    VoiceId musicVoice = 0;
    std::string musicPath;

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
    std::uint64_t stamp = 0;
    std::string sceneMusic;
    float sceneMusicVolume = -1.0f;

    // ------------------------------------------------------------ decode
    std::shared_ptr<const Clip> decode(const std::string& path, std::string* err) {
        auto bytes = fs::read_bytes(path);
        if (!bytes) {
            std::vector<std::string> cands;
            for (const std::string& f : fs::list("", true)) {
                if (is_audio_ext(fs::extension(f))) cands.push_back(f);
            }
            std::string msg = "Audio clip '" + path + "' could not be loaded: " + bytes.error().message;
            std::string hint = cands.empty() ? "put .wav/.ogg/.mp3 files under the project (e.g. assets/sounds/) and use a project-relative path"
                                              : did_you_mean(path, cands);
            *err = msg + " (hint: " + hint + ")";
            return nullptr;
        }
        const std::string ext = fs::extension(path);
        const auto& data = *bytes;
        std::vector<float> pcm;  // interleaved at source layout
        std::size_t frames = 0;
        int channels = 0, rate = 0;
        if (ext == ".wav") {
            unsigned ch = 0, sr = 0;
            drwav_uint64 total = 0;
            float* p = drwav_open_memory_and_read_pcm_frames_f32(data.data(), data.size(), &ch, &sr, &total, nullptr);
            if (!p) { *err = "Audio clip '" + path + "' is not a valid WAV file (hint: use 8/16/24/32-bit PCM or float WAV)"; return nullptr; }
            pcm.assign(p, p + total * ch);
            drwav_free(p, nullptr);
            frames = std::size_t(total); channels = int(ch); rate = int(sr);
        } else if (ext == ".mp3") {
            drmp3_config cfg{};
            drmp3_uint64 total = 0;
            float* p = drmp3_open_memory_and_read_pcm_frames_f32(data.data(), data.size(), &cfg, &total, nullptr);
            if (!p) { *err = "Audio clip '" + path + "' is not a valid MP3 file"; return nullptr; }
            pcm.assign(p, p + total * cfg.channels);
            drmp3_free(p, nullptr);
            frames = std::size_t(total); channels = int(cfg.channels); rate = int(cfg.sampleRate);
        } else if (ext == ".ogg") {
            int ch = 0, sr = 0;
            short* p = nullptr;
            int n = stb_vorbis_decode_memory(data.data(), int(data.size()), &ch, &sr, &p);
            if (n <= 0 || !p) { *err = "Audio clip '" + path + "' is not a valid OGG Vorbis file"; if (p) std::free(p); return nullptr; }
            pcm.resize(std::size_t(n) * std::size_t(ch));
            for (std::size_t i = 0; i < pcm.size(); ++i) pcm[i] = float(p[i]) / 32768.0f;
            std::free(p);
            frames = std::size_t(n); channels = ch; rate = sr;
        } else {
            *err = "Audio clip '" + path + "' has unsupported extension '" + ext + "' (hint: " + audio_extensions_hint() + ")";
            return nullptr;
        }
        if (channels < 1 || frames == 0) {
            *err = "Audio clip '" + path + "' contains no audio samples";
            return nullptr;
        }
        auto clip = std::make_shared<Clip>();
        clip->path = path;
        clip->srcChannels = channels;
        clip->srcRate = rate;
        resample_to_stereo(pcm.data(), frames, channels, rate, clip->data);
        clip->frames = clip->data.size() / 2;
        return clip;
    }

    std::shared_ptr<const Clip> get_clip(std::string_view pathIn) {
        std::string path = fs::normalize(pathIn);
        {
            std::lock_guard<std::mutex> lk(mu);
            auto it = clips.find(path);
            if (it != clips.end()) return it->second;
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

    // ------------------------------------------------------------- voices
    static int bus_index(std::string_view name) {
        for (int i = 0; i < BusCount; ++i) if (name == kBusNames[i]) return i;
        return -1;
    }

    Voice* find_voice(VoiceId id) {
        if (id == 0) return nullptr;
        for (Voice& v : voices) if (v.id == id && !v.dead) return &v;
        return nullptr;
    }

    VoiceId add_voice_locked(std::shared_ptr<const Clip> clip, const PlayParams& p) {
        if (voices.size() >= kMaxVoices) {
            auto it = std::find_if(voices.begin(), voices.end(), [&](const Voice& v) { return !v.loop && v.id != musicVoice; });
            if (it == voices.end()) it = voices.begin();
            if (it->id == musicVoice) musicVoice = 0;
            voices.erase(it);
        }
        Voice v;
        v.id = nextVoice++;
        if (nextVoice == 0) nextVoice = 1;
        v.clip = std::move(clip);
        v.volume = std::max(p.volume, 0.0f);
        v.pitch = std::max(p.pitch, 0.001f);
        v.pan = clamp(p.pan, -1.0f, 1.0f);
        v.loop = p.loop;
        int b = bus_index(p.bus);
        if (b < 0) {
            std::vector<std::string> names(kBusNames, kBusNames + BusCount);
            FA_ERROR("audio", "Unknown audio bus '{}'. {} (using 'sfx')", p.bus, did_you_mean(p.bus, names));
            b = BusSfx;
        }
        v.bus = b;
        voices.push_back(std::move(v));
        return voices.back().id;
    }

    void start_fade(Voice& v, float target, float seconds, bool stopAtEnd) {
        long frames = std::max(1L, long(std::lround(double(seconds) * deviceRate)));
        v.fadeTarget = target;
        v.fadeFrames = frames;
        v.fadeStep = (target - v.fade) / float(frames);
        v.stopAtFadeEnd = stopAtEnd;
    }

    // ------------------------------------------------------------- mixing
    // Mixes `frames` stereo frames into `out` (overwrites). Caller holds mu.
    void mix_locked(float* out, int frames) {
        std::memset(out, 0, sizeof(float) * std::size_t(frames) * 2);
        const double rateRatio = double(kRate) / double(deviceRate);
        for (Voice& v : voices) {
            if (v.dead || !v.clip || v.clip->frames == 0) { v.dead = true; continue; }
            const Clip& c = *v.clip;
            const double n = double(c.frames);
            const double step = double(v.pitch) * rateRatio;
            const float theta = (v.pan + 1.0f) * (kPi * 0.25f);
            // Equal-power pan law normalised to unity at the centre (gain capped at 1 on the loud side).
            const float gl = std::min(1.0f, std::cos(theta) * 1.41421356f);
            const float gr = std::min(1.0f, std::sin(theta) * 1.41421356f);
            const float base = v.volume * busVol[v.bus] * master;
            for (int f = 0; f < frames; ++f) {
                if (v.pos >= n) {
                    if (v.loop) v.pos = std::fmod(v.pos, n);
                    else { v.dead = true; break; }
                }
                std::size_t i0 = std::size_t(v.pos);
                if (i0 >= c.frames) i0 = c.frames - 1;
                std::size_t i1 = i0 + 1;
                if (i1 >= c.frames) i1 = v.loop ? 0 : i0;
                const float t = float(v.pos - double(i0));
                const float* d = c.data.data();
                float l = d[2 * i0] + (d[2 * i1] - d[2 * i0]) * t;
                float r = d[2 * i0 + 1] + (d[2 * i1 + 1] - d[2 * i0 + 1]) * t;
                float g = base * v.fade;
                out[2 * f] += l * gl * g;
                out[2 * f + 1] += r * gr * g;
                v.pos += step;
                if (v.fadeFrames > 0) {
                    v.fade += v.fadeStep;
                    if (--v.fadeFrames == 0) {
                        v.fade = v.fadeTarget;
                        if (v.stopAtFadeEnd) { v.dead = true; break; }
                    }
                }
            }
        }
        voices.erase(std::remove_if(voices.begin(), voices.end(), [](const Voice& v) { return v.dead; }), voices.end());
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
    if (device) {
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
        } else {
            saudio_shutdown();
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
    if (impl_->device) saudio_shutdown();  // joins the audio thread before we touch state
    std::lock_guard<std::mutex> lk(impl_->mu);
    impl_->voices.clear();
    impl_->clips.clear();
    impl_->ents.clear();
    impl_->musicVoice = 0;
    impl_->musicPath.clear();
    impl_->recording = false;
    impl_->rec.clear();
    impl_->device = false;
    impl_->inited = false;
    impl_->lastWorld = nullptr;
    impl_->sceneMusic.clear();
    impl_->sceneMusicVolume = -1.0f;
}

bool Audio::load(std::string_view clipPath) { return impl_->get_clip(clipPath) != nullptr; }

VoiceId Audio::play(std::string_view clipPath, const PlayParams& params) {
    if (!impl_->inited) {
        FA_ERROR("audio", "Audio::play('{}') called before Audio::init()", clipPath);
        return 0;
    }
    auto clip = impl_->get_clip(clipPath);
    if (!clip) return 0;
    std::lock_guard<std::mutex> lk(impl_->mu);
    return impl_->add_voice_locked(std::move(clip), params);
}

void Audio::stop(VoiceId voice) {
    std::lock_guard<std::mutex> lk(impl_->mu);
    auto& vs = impl_->voices;
    vs.erase(std::remove_if(vs.begin(), vs.end(), [&](const Voice& v) { return v.id == voice; }), vs.end());
    if (impl_->musicVoice == voice) impl_->musicVoice = 0;
}

void Audio::stop_all() {
    std::lock_guard<std::mutex> lk(impl_->mu);
    impl_->voices.clear();
    impl_->musicVoice = 0;
}

bool Audio::is_playing(VoiceId voice) const {
    std::lock_guard<std::mutex> lk(impl_->mu);
    return impl_->find_voice(voice) != nullptr;
}

void Audio::set_voice_volume(VoiceId voice, float volume) {
    std::lock_guard<std::mutex> lk(impl_->mu);
    if (Voice* v = impl_->find_voice(voice)) v->volume = std::max(volume, 0.0f);
}

void Audio::set_bus_volume(std::string_view bus, float volume) {
    volume = std::max(volume, 0.0f);
    std::lock_guard<std::mutex> lk(impl_->mu);
    if (bus == "master") { impl_->master = volume; return; }
    int b = Impl::bus_index(bus);
    if (b < 0) {
        std::vector<std::string> names = {"sfx", "music", "ui", "master"};
        FA_ERROR("audio", "Unknown audio bus '{}'. {}", bus, did_you_mean(bus, names));
        return;
    }
    impl_->busVol[b] = volume;
}

void Audio::set_master_volume(float volume) {
    std::lock_guard<std::mutex> lk(impl_->mu);
    impl_->master = std::max(volume, 0.0f);
}

void Audio::play_music(std::string_view clipPath, float volume, float fadeSeconds) {
    auto clip = impl_->get_clip(clipPath);
    if (!clip) return;
    std::lock_guard<std::mutex> lk(impl_->mu);
    Impl& im = *impl_;
    if (Voice* cur = im.find_voice(im.musicVoice)) {
        if (im.musicPath == clip->path) {  // already playing this track: just retune
            cur->volume = std::max(volume, 0.0f);
            if (cur->fadeTarget < 1.0f) im.start_fade(*cur, 1.0f, std::max(fadeSeconds, 0.0f), false);
            return;
        }
        if (fadeSeconds > 0.0f) {
            im.start_fade(*cur, 0.0f, fadeSeconds, true);
        } else {
            const VoiceId oldId = cur->id;
            auto& vs = im.voices;
            vs.erase(std::remove_if(vs.begin(), vs.end(), [&](const Voice& v) { return v.id == oldId; }), vs.end());
        }
    }
    PlayParams p;
    p.volume = volume;
    p.loop = true;
    p.bus = "music";
    VoiceId id = im.add_voice_locked(clip, p);
    if (Voice* v = im.find_voice(id)) {
        if (fadeSeconds > 0.0f) {
            v->fade = 0.0f;
            im.start_fade(*v, 1.0f, fadeSeconds, false);
        }
    }
    im.musicVoice = id;
    im.musicPath = clip->path;
}

void Audio::stop_music(float fadeSeconds) {
    std::lock_guard<std::mutex> lk(impl_->mu);
    Impl& im = *impl_;
    if (Voice* cur = im.find_voice(im.musicVoice)) {
        if (fadeSeconds > 0.0f) {
            im.start_fade(*cur, 0.0f, fadeSeconds, true);
        } else {
            VoiceId id = cur->id;
            im.voices.erase(std::remove_if(im.voices.begin(), im.voices.end(), [&](const Voice& v) { return v.id == id; }),
                            im.voices.end());
        }
    }
    im.musicVoice = 0;
    im.musicPath.clear();
}

void Audio::advance_null_device(double seconds) { impl_->advance(seconds); }

void Audio::start_recording() {
    std::lock_guard<std::mutex> lk(impl_->mu);
    impl_->rec.clear();
    impl_->recording = true;
    impl_->recWarned = false;
    impl_->recRate = impl_->deviceRate;
}

bool Audio::stop_recording(std::string_view wavPath, std::string* error) {
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
    j["peak"] = im.lastPeak;
    j["master"] = im.master;
    Json buses = Json::object();
    for (int i = 0; i < BusCount; ++i) buses[kBusNames[i]] = im.busVol[i];
    j["buses"] = buses;
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
        if (v.clip && v.clip->path == path) {
            v.clip = clip;
            if (v.pos >= double(clip->frames)) v.pos = v.loop ? std::fmod(v.pos, double(clip->frames)) : double(clip->frames);
        }
    }
}

// ============================================================ world driving ==

void Audio::update(World& world, float dt) {
    Impl& im = *impl_;
    if (!im.inited) return;
    if (im.autoAdvance) im.advance(dt);

    if (im.lastWorld != &world) {
        for (auto& [k, ea] : im.ents) if (ea.voice) stop(ea.voice);
        im.ents.clear();
        im.lastWorld = &world;
    }
    ++im.stamp;

    // ---- listener: AudioListener entity, else the primary (or first) camera
    bool haveListener = false;
    Vec3 lpos{}, lright{1, 0, 0};
    float lvol = 1.0f;
    auto take = [&](Entity e, float vol) {
        Mat4 m = world.world_matrix(e);
        lpos = {m.at(3, 0), m.at(3, 1), m.at(3, 2)};
        Vec3 r{m.at(0, 0), m.at(0, 1), m.at(0, 2)};
        lright = length_sq(r) > 1e-8f ? normalize(r) : Vec3{1, 0, 0};
        lvol = vol;
        haveListener = true;
    };
    world.each<AudioListener>([&](Entity e, AudioListener& l) {
        if (!haveListener && world.active_in_hierarchy(e)) take(e, l.volume);
    });
    if (!haveListener) {
        Entity first = kNullEntity;
        world.each<Camera>([&](Entity e, Camera& c) {
            if (!world.active_in_hierarchy(e)) return;
            if (c.primary && !haveListener) take(e, 1.0f);
            else if (first.is_null()) first = e;
        });
        if (!haveListener && !first.is_null()) take(first, 1.0f);
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
            float range = std::max(src->range, 1e-3f);
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
                ea.voice = play(src->clip, p);
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

    // ---- scene music (only reacts to changes, so scripts may still call play_music themselves)
    const SceneSettings& ss = world.settings();
    if (ss.music != im.sceneMusic) {
        im.sceneMusic = ss.music;
        im.sceneMusicVolume = ss.musicVolume;
        if (ss.music.empty()) stop_music(0.5f);
        else play_music(ss.music, ss.musicVolume, 0.5f);
    } else if (!ss.music.empty() && ss.musicVolume != im.sceneMusicVolume) {
        im.sceneMusicVolume = ss.musicVolume;
        std::lock_guard<std::mutex> lk(im.mu);
        if (Voice* v = im.find_voice(im.musicVoice)) v->volume = std::max(ss.musicVolume, 0.0f);
    }
}

}  // namespace fa
