// The mixer side of fa_audio: what runs on the thread that mixes (audio_mixer.h says which threads touch what). Nothing
// here takes a lock, allocates or frees: every buffer was sized by the game side before it was handed over.
#include "audio_mixer.h"

#include <algorithm>
#include <cmath>
#include <cstring>

#include "fa/core/math.h"

namespace fa::audio_detail {

// ------------------------------------------------------------------------------------------------------------ rings

std::size_t StreamRing::fill(std::size_t most) {
    if (end_.load(std::memory_order_relaxed) != kNoEnd) return 0;  // only the claim holder stores end_
    // write_ is ours (the claim's acquire made the last holder's store visible). Acquire on read_: the mixer released the
    // frames before it after reading them, so they may be overwritten.
    const std::uint64_t w = write_.load(std::memory_order_relaxed);
    const std::uint64_t r = read_.load(std::memory_order_acquire);
    const std::size_t room = cap_ - std::size_t(w - r);
    if (most > room) most = room;
    std::size_t made = 0;
    while (made < most) {
        const std::size_t at = std::size_t((w + made) % cap_);
        const std::size_t chunk = std::min(most - made, cap_ - at);
        const std::size_t got = source_.pull(&buf_[2 * at], chunk);
        made += got;
        if (got < chunk) {
            // The clip ended. end_ is stored before write_ is released, so a reader that sees the last frames sees the
            // end with them (at() loads write_ first).
            end_.store(w + made, std::memory_order_release);
            break;
        }
    }
    write_.store(w + made, std::memory_order_release);  // the frames above happen-before the mixer's acquire in at()
    return made;
}

void PcmRing::push(const float* stereo, std::size_t frames) {
    if (!stereo || frames == 0) return;
    const std::uint64_t w = write_.load(std::memory_order_relaxed);  // only this thread stores write_
    // Acquire on read_: the mixer is done with the frames before it (released in consumed()), so they may be overwritten.
    // The storage never takes more than it has room for: what does not fit is dropped (the newest samples).
    const std::uint64_t r = read_.load(std::memory_order_acquire);
    const std::size_t room = cap_ - std::size_t(w - r);
    if (frames > room) frames = room;
    for (std::size_t i = 0; i < frames; ++i) {
        float* d = &buf_[2 * std::size_t((w + i) % cap_)];
        d[0] = stereo[2 * i];
        d[1] = stereo[2 * i + 1];
    }
    const std::uint64_t now = w + frames;
    write_.store(now, std::memory_order_release);  // the samples above happen-before the mixer's acquire in written()
    // Two seconds wait at most: the frames before `now - 2 s` are skipped. Release pairs with the acquire in skip().
    const std::uint64_t limit = std::uint64_t(rate_) * 2;
    const std::uint64_t played = pos_.load(std::memory_order_acquire) >> 24;
    const std::uint64_t from = std::max(played, skip_.load(std::memory_order_relaxed));
    if (now > from && now - from > limit) skip_.store(now - limit, std::memory_order_release);
}

double PcmRing::queued() const {
    const std::uint64_t w = write_.load(std::memory_order_relaxed);  // the producer's own index
    // Acquire on pos_: pairs with the release in consumed() (a statistic: any recent value would do).
    const double pos = double(pos_.load(std::memory_order_acquire)) / double(1 << 24);
    const double from = std::max(pos, double(skip_.load(std::memory_order_relaxed)));
    return std::max(0.0, double(w) - from);
}

// ------------------------------------------------------------------------------------------------------------ table

void MixTable::build() {
    const std::size_t n = bus.size();
    mixOrder.clear();
    for (std::size_t i = 0; i < n; ++i) {
        int d = 1;
        for (int at = int(i); at != kMasterBus && at >= 0 && d <= int(n); at = bus[std::size_t(at)].parent) ++d;
        bus[i].depth = int(i) == kMasterBus ? 0 : d - 1;
        if (int(i) != kMasterBus) mixOrder.push_back(int(i));
    }
    std::stable_sort(mixOrder.begin(), mixOrder.end(),
                     [&](int a, int b) { return bus[std::size_t(a)].depth > bus[std::size_t(b)].depth; });
    busBuf.assign(n, std::vector<float>(kScratchFrames * 2, 0.0f));
    duckGains.assign(n, std::vector<float>(kScratchFrames, 1.0f));
    used.assign(n, 0);
    live.assign(n, 0);
    ducking.assign(n, 0);
    fromOld.resize(n, -1);
    duckBy.resize(n, -1);
}

// ------------------------------------------------------------------------------------------------------------ mixer

Mixer::Mixer() : table(std::make_unique<MixTable>()), tmp_(kScratchFrames * 2, 0.0f) {
    table->bus.resize(std::size_t(kFirstProjectBus));
    table->build();
}

Mixer::~Mixer() = default;

MixVoice* Mixer::find_voice(VoiceIdT id) {
    if (id == 0) return nullptr;
    for (std::size_t i = 0; i < voiceCount; ++i)
        if (voices[i].id == id && !voices[i].dead) return &voices[i];
    return nullptr;
}

bool Mixer::add_voice(const MixVoice& v) {
    if (voiceCount >= kMaxVoices) return false;
    voices[voiceCount++] = v;
    return true;
}

void Mixer::end_voice(VoiceIdT id) {
    for (std::size_t i = 0; i < voiceCount; ++i) {
        if (voices[i].id != id) continue;
        voices[i].dead = true;  // a zombie that already ended (no room to say so) is said now
        break;
    }
    sweep_dead();
}

void Mixer::end_all_voices() {
    for (std::size_t i = 0; i < voiceCount; ++i) voices[i].dead = true;
    sweep_dead();
}

// Removes the dead voices (keeping the order of the rest: the sum into a bus is made in that order) and tells the game
// each one ended. A voice that finds no room in `returns` stays as a silent zombie until the next block.
void Mixer::sweep_dead() {
    std::size_t keep = 0;
    bool any = false;
    for (std::size_t i = 0; i < voiceCount; ++i) {
        MixVoice& v = voices[i];
        if (v.dead && returns.push(Ret{Ret::Ended, nullptr, v.id})) {
            any = true;
            continue;
        }
        if (keep != i) voices[keep] = v;
        ++keep;
    }
    voiceCount = keep;
    if (any) returns.commit();
}

void Mixer::add_player(MusicChannel* ch) {
    if (!ch || playerCount >= kMaxPlayers) return;  // the game side keeps at most kMaxPlayers
    for (std::size_t i = 0; i < playerCount; ++i)
        if (players[i] == ch) return;
    ch->tr.set_rate_ratio(double(kRate) / double(deviceRate_));
    players[playerCount++] = ch;
}

void Mixer::remove_player(MusicChannel* ch) {
    for (std::size_t i = 0; i < playerCount; ++i) {
        if (players[i] != ch) continue;
        for (std::size_t j = i + 1; j < playerCount; ++j) players[j - 1] = players[j];
        players[--playerCount] = nullptr;
        return;
    }
}

void Mixer::swap_table(Cmd& cmd) {
    if (!cmd.table) return;
    MixTable& nt = *cmd.table;
    MixTable& ot = *table;
    for (std::size_t b = 0; b < nt.bus.size(); ++b) {
        const int from = b < nt.fromOld.size() ? nt.fromOld[b] : -1;
        // A move: the reverb's pointer changes hands (the new table's slot is empty, so nothing is freed here).
        if (from >= 0 && std::size_t(from) < ot.bus.size()) nt.bus[b].rt = std::move(ot.bus[std::size_t(from)].rt);
        BusRuntime& rt = nt.bus[b].rt;
        rt.duckBy = b < nt.duckBy.size() ? nt.duckBy[b] : -1;
        if (rt.duckBy < 0) rt.duckAmount = 0.0f;
    }
    for (std::size_t i = 0; i < voiceCount; ++i) {
        MixVoice& v = voices[i];
        const int to = v.bus >= 0 && std::size_t(v.bus) < nt.voiceRemap.size() ? nt.voiceRemap[std::size_t(v.bus)] : BusSfx;
        v.bus = to >= 0 && std::size_t(to) < nt.bus.size() && to != kMasterBus ? to : int(BusSfx);
    }
    for (std::size_t i = 0; i < playerCount; ++i) {
        MusicChannel& ch = *players[i];
        if (ch.bus < 0 || std::size_t(ch.bus) >= nt.bus.size() || ch.bus == kMasterBus) ch.bus = BusMusic;
    }
    table.swap(cmd.table);  // the old table goes back to the game with the command, to be freed there
}

long Mixer::ramp_frames(float seconds, bool declick) const {
    if (seconds > 0.0f) return std::max(1L, long(std::lround(double(seconds) * deviceRate_)));
    return declick ? std::max(1L, long(deviceRate_ / 100)) : 0L;
}

void Mixer::start_fade(MixVoice& v, float target, float seconds, bool stopAtEnd) const {
    const long frames = std::max(1L, long(std::lround(double(seconds) * deviceRate_)));
    v.fadeTarget = target;
    v.fadeFrames = frames;
    v.fadeStep = (target - v.fade) / float(frames);
    v.stopAtFadeEnd = stopAtEnd;
}

void Mixer::start_volume_ramp(MixVoice& v, float target, float seconds) const {
    target = std::max(target, 0.0f);
    if (seconds <= 0.0f) {
        v.volume = target;
        v.volFrames = 0;
        return;
    }
    const long frames = std::max(1L, long(std::lround(double(seconds) * deviceRate_)));
    v.volTarget = target;
    v.volFrames = frames;
    v.volStep = (target - v.volume) / float(frames);
}

void Mixer::set_lowpass(BusRuntime& fx, float hz, float fadeSeconds) const {
    const long frames = ramp_frames(fadeSeconds, false);
    if (hz <= 0.0f) {
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
    const float top = std::min(kLowpassOpen, 0.49f * float(deviceRate_));
    hz = clamp(hz, 20.0f, top);
    if (!fx.lpOn) {
        fx.lpOn = true;
        fx.lp.clear();
        fx.lpLog.set(std::log2(top), 0);  // a new filter starts open
    }
    fx.lpOffAtEnd = false;
    fx.lpLog.set(std::log2(hz), frames);
    fx.lpDirty = true;
}

void Mixer::set_reverb(BusRuntime& fx, float mix, float fadeSeconds, std::unique_ptr<Reverb>& spare) const {
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
    if (!fx.rv) fx.rv = std::move(spare);  // the game side sent one along the first time (a move: nothing allocated here)
    if (!fx.rvOn) {
        fx.rvOn = true;
        if (fx.rv) fx.rv->clear();
        fx.rvQuiet = 0;
        fx.rvMix.set(0.0f, 0);
    }
    fx.rvOffAtEnd = false;
    fx.rvMix.set(mix, frames);
}

void Mixer::set_duck(BusRuntime& fx, int by, float amount, float attack, float release) const {
    fx.duckBy = by;
    if (by < 0) {
        fx.duckAmount = 0.0f;
        return;  // the gain and the detector keep where they are; nothing reads them while the bus does not duck
    }
    fx.duckAmount = amount;
    const auto coef = [&](float seconds) { return seconds <= 0.0f ? 0.0f : std::exp(-1.0f / (seconds * float(deviceRate_))); };
    fx.duckAttack = coef(attack);
    fx.duckRelease = coef(release);
}

void Mixer::apply_commands() {
    sweep_dead();  // a zombie left by a full `returns` is said first, so its room counts below
    // A command may end every voice (stop_all) and is handed back itself: it runs only while `returns` has room for that.
    while (returns.free_space() >= kMaxVoices + 2) {
        Cmd* const* front = commands.front();
        if (!front) break;
        Cmd* cmd = *front;
        commands.pop();
        if (cmd->run) cmd->run(*this, *cmd);
        // Relaxed is enough for the counter itself: the game reads it from the music snapshots (published with release
        // below) or after it took the command back from `returns` (released by commit()).
        appliedSeq.store(cmd->seq, std::memory_order_relaxed);
        returns.push(Ret{Ret::Done, cmd, 0});
        returns.commit();
    }
    publish_music();
}

void Mixer::publish_music() {
    const std::uint64_t seq = appliedSeq.load(std::memory_order_relaxed);
    for (std::size_t i = 0; i < playerCount; ++i) {
        MusicChannel& ch = *players[i];
        // The events first, then the state: a game that sees this state has the events made before it (both are
        // released, the ring by commit() and the state by publish(); the game acquires the state first).
        MusicEvent ev;
        while (ch.events.free_space() > 0 && ch.tr.pop_event(ev)) ch.events.push(ev);
        ch.events.commit();
        MusicSnap& s = ch.snap.back();
        ch.tr.capture(s.state);
        s.appliedSeq = seq;
        s.backlog = ch.tr.event_count();
        ch.snap.publish();
    }
}

void Mixer::render(float* out, int frames, int channels) {
    if (!out || frames <= 0 || channels <= 0) return;
    if (!armed.load(std::memory_order_acquire)) {  // see `armed`: silence, and nothing else is touched
        std::memset(out, 0, sizeof(float) * std::size_t(frames) * std::size_t(channels));
        return;
    }
    if (callbacks.load(std::memory_order_relaxed) == 0) {
        firstCallbackFrames.store(frames, std::memory_order_relaxed);
        firstCallbackChannels.store(channels, std::memory_order_relaxed);
    }
    // Release: the game that reads callbacks > 0 (acquire) reads the first callback's size above.
    callbacks.fetch_add(1, std::memory_order_release);
    apply_commands();
    float peak = 0.0f;
    for (int done = 0; done < frames;) {
        const int n = std::min(frames - done, int(kScratchFrames));
        if (channels == 2) {
            mix_block(out + std::size_t(done) * 2, n);
        } else {
            mix_block(tmp_.data(), n);
            float* dst = out + std::size_t(done) * std::size_t(channels);
            for (int f = 0; f < n; ++f) {
                if (channels == 1) {
                    dst[f] = 0.5f * (tmp_[std::size_t(2 * f)] + tmp_[std::size_t(2 * f + 1)]);
                } else {
                    for (int c = 0; c < channels; ++c)
                        dst[std::size_t(f) * std::size_t(channels) + std::size_t(c)] = c < 2 ? tmp_[std::size_t(2 * f + c)] : 0.0f;
                }
            }
        }
        peak = std::max(peak, blockPeak_);
        done += n;
    }
    std::uint32_t bits = 0;
    static_assert(sizeof(bits) == sizeof(peak));
    std::memcpy(&bits, &peak, sizeof(bits));
    peakBits.store(bits, std::memory_order_relaxed);  // a statistic
    publish_music();
}

// Advances a voice's own volume ramp by one frame.
static inline void step_volume(MixVoice& v) {
    if (v.volFrames > 0) {
        v.volume += v.volStep;
        if (--v.volFrames == 0) v.volume = v.volTarget;
    }
}

// Advances a voice's fade by one frame; true when the voice ends with it (a fade out that stops it).
static inline bool step_fade(MixVoice& v) {
    if (v.fadeFrames > 0) {
        v.fade += v.fadeStep;
        if (--v.fadeFrames == 0) {
            v.fade = v.fadeTarget;
            if (v.stopAtFadeEnd) return true;
        }
    }
    return false;
}

void Mixer::mix_pcm(MixVoice& v, float* out, int frames) {
    PcmRing& p = *v.pcm;
    const std::uint64_t skip = p.skip();
    if (v.pos < double(skip)) v.pos = double(skip);  // the game dropped what was before (clear_pcm, or over two seconds)
    const std::uint64_t written = p.written();
    const double step = double(p.rate()) / double(deviceRate_);
    const float theta = (v.pan + 1.0f) * (kPi * 0.25f);
    const float gl = std::min(1.0f, std::cos(theta) * 1.41421356f);
    const float gr = std::min(1.0f, std::sin(theta) * 1.41421356f);
    for (int f = 0; f < frames; ++f) {
        const std::uint64_t i0 = std::uint64_t(v.pos);
        if (i0 + 1 >= written) break;  // the queue ran dry: silence until the game pushes more (not an underrun)
        const float* a = p.frame(i0);
        const float* b = p.frame(i0 + 1);
        const float t = float(v.pos - double(i0));
        const float l = a[0] + (b[0] - a[0]) * t;
        const float r = a[1] + (b[1] - a[1]) * t;
        const float g = v.volume * v.fade;
        out[2 * f] += l * gl * g;
        out[2 * f + 1] += r * gr * g;
        v.pos += step;
        step_volume(v);
        if (step_fade(v)) {
            v.dead = true;
            break;
        }
    }
    p.consumed(v.pos);
}

void Mixer::mix_stream(MixVoice& v, float* out, int frames, float gl, float gr, int first) {
    StreamRing& s = *v.stream;
    const double step = double(v.pitch) * (double(kRate) / double(deviceRate_));
    const float base = v.clip ? v.clip->gain : 1.0f;
    for (int f = first; f < frames; ++f) {
        float l = 0.0f, r = 0.0f;
        int got = s.at(v.pos, l, r);
        if (got == 0) {
            // Nothing decoded at this position yet. Hand back what is behind it so the producer has all the room.
            s.release_before(std::uint64_t(v.pos));
            if (syncFill_ && s.claim()) {  // the null device: decode right here, on the thread that mixes
                s.fill(s.room());
                s.unclaim();
                got = s.at(v.pos, l, r);
            }
            if (got == 0) {
                // An underrun: the rest of the block is silent, the voice waits where it is (no frame is skipped).
                underrunEvents.fetch_add(1, std::memory_order_relaxed);
                underrunFrames.fetch_add(std::uint64_t(frames - f), std::memory_order_relaxed);
                break;
            }
        }
        if (got < 0) {
            v.dead = true;
            break;
        }
        const float g = base * v.volume * v.fade;
        out[2 * f] += l * gl * g;
        out[2 * f + 1] += r * gr * g;
        v.pos += step;
        step_volume(v);
        if (step_fade(v)) {
            v.dead = true;
            break;
        }
    }
    s.release_before(std::uint64_t(v.pos));
}

void Mixer::mix_voices(int frames) {
    MixTable& t = *table;
    const double rateRatio = double(kRate) / double(deviceRate_);
    for (std::size_t i = 0; i < voiceCount; ++i) {
        MixVoice& v = voices[i];
        if (v.dead) continue;
        float* const dst = t.busBuf[std::size_t(v.bus)].data();
        if (v.pcm) {
            t.used[std::size_t(v.bus)] = 1;
            mix_pcm(v, dst, frames);
            continue;
        }
        if (!v.clip || v.clip->frames == 0) {
            v.dead = true;
            continue;
        }
        t.used[std::size_t(v.bus)] = 1;
        const Clip& c = *v.clip;
        const float theta = (v.pan + 1.0f) * (kPi * 0.25f);
        // Equal-power pan law normalised to unity at the centre (gain capped at 1 on the loud side).
        const float gl = std::min(1.0f, std::cos(theta) * 1.41421356f);
        const float gr = std::min(1.0f, std::sin(theta) * 1.41421356f);
        int first = 0;
        if (v.delay > 0) {  // a voice that waits for its beat: silent, not advancing
            first = int(std::min<long>(v.delay, frames));
            v.delay -= first;
        }
        if (v.stream) {
            mix_stream(v, dst, frames, gl, gr, first);
            continue;
        }
        const double n = double(c.frames);
        const double step = double(v.pitch) * rateRatio;
        const float base = c.gain;  // the bus and master volumes are applied to the sum of the bus
        const float* d = c.data.data();
        for (int f = first; f < frames; ++f) {
            // With loop points the first pass runs to loopEnd and every later one wraps inside loopStart..loopEnd.
            const double loopEnd = c.loopEnd > 0 ? double(c.loopEnd) : n, loopStart = double(c.loopStart);
            if (v.pos >= loopEnd) {
                if (v.loop) {
                    v.pos = loopStart + std::fmod(v.pos - loopStart, loopEnd - loopStart);
                } else if (v.pos >= n) {
                    v.dead = true;
                    break;
                }
            }
            std::size_t i0 = std::size_t(v.pos);
            if (i0 >= c.frames) i0 = c.frames - 1;
            std::size_t i1 = i0 + 1;
            if (v.loop && i1 >= std::size_t(loopEnd)) i1 = c.loopStart;
            else if (i1 >= c.frames) i1 = i0;
            const float tt = float(v.pos - double(i0));
            const float l = d[2 * i0] + (d[2 * i1] - d[2 * i0]) * tt;
            const float r = d[2 * i0 + 1] + (d[2 * i1 + 1] - d[2 * i0 + 1]) * tt;
            const float g = base * v.volume * v.fade;
            dst[2 * f] += l * gl * g;
            dst[2 * f + 1] += r * gr * g;
            v.pos += step;
            step_volume(v);
            if (step_fade(v)) {
                v.dead = true;
                break;
            }
        }
    }
}

bool Mixer::run_effects(BusRuntime& fx, float* buf, int frames, bool used) {
    if (fx.lpOn) {
        if (fx.lpLog.moving()) {
            fx.lpLog.skip(frames);
            fx.lpDirty = true;
        }
        if (fx.lpDirty) {
            fx.lp.set_cutoff(std::exp2(fx.lpLog.cur), float(deviceRate_));
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
        fx.rvQuiet = used ? 0 : std::min(fx.rvQuiet + frames, long(1) << 30);
        if (used || double(fx.rvQuiet) <= kReverbTail * deviceRate_) {
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

void Mixer::apply_bus_gain(BusRuntime& fx, float* buf, int frames, bool live) {
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
void Mixer::compute_duck(int d, int frames) {
    MixTable& t = *table;
    BusRuntime& fx = t.bus[std::size_t(d)].rt;
    const float* src = t.busBuf[std::size_t(fx.duckBy)].data();
    float* g = t.duckGains[std::size_t(d)].data();
    const float detRelease = std::exp(-1.0f / (0.010f * float(deviceRate_)));
    const float low = 1.0f - fx.duckAmount;
    float env = fx.duckEnv, gain = fx.duckGain;
    for (int f = 0; f < frames; ++f) {
        env = std::max(std::max(std::fabs(src[2 * f]), std::fabs(src[2 * f + 1])), env * detRelease);
        const float target = env > kDuckThreshold ? low : 1.0f;
        const float k = target < gain ? fx.duckAttack : fx.duckRelease;
        gain = target + (gain - target) * k;
        g[f] = gain;
    }
    // Settle the tails so a bus that is back at full volume stops costing anything.
    if (env < kDuckThreshold * 1e-3f) env = 0.0f;
    if (gain > 0.99999f) gain = 1.0f;
    fx.duckEnv = env;
    fx.duckGain = gain;
}

// Every voice is summed into the buffer of its bus; each bus gets its effects, volume and ducking; the buses are summed
// into `out`, which gets the master's.
void Mixer::mix_block(float* out, int frames) {
    MixTable& t = *table;
    const std::size_t n = std::size_t(frames) * 2;
    std::memset(out, 0, sizeof(float) * n);
    std::fill(t.used.begin(), t.used.end(), char(0));
    for (std::vector<float>& b : t.busBuf) std::memset(b.data(), 0, sizeof(float) * n);
    if (!paused) mix_voices(frames);
    mixedTotal.fetch_add(std::uint64_t(frames), std::memory_order_relaxed);  // a counter: no ordering needed
    if (!paused) {
        const double rateRatio = double(kRate) / double(deviceRate_);
        for (std::size_t i = 0; i < playerCount; ++i) {
            MusicChannel& ch = *players[i];
            float* const dst = t.busBuf[std::size_t(ch.bus)].data();
            const bool was = ch.tr.active();
            ch.tr.set_rate_ratio(rateRatio);
            ch.tr.mix(dst, frames);
            if (was || ch.tr.active()) t.used[std::size_t(ch.bus)] = 1;
        }
    }
    sweep_dead();
    if (!paused) {
        // The buses go deepest first, a whole depth at a time: effects and volume of each, then the ducking (which reads
        // the buses of that depth, or deeper, before any ducking; a bus nearer the master than the one that ducks is read as
        // its own voices and the buses under it, before its effects), then each bus is summed into its parent.
        std::fill(t.live.begin(), t.live.end(), char(0));
        std::fill(t.ducking.begin(), t.ducking.end(), char(0));
        bool anyLive = false;
        for (std::size_t from = 0; from < t.mixOrder.size();) {
            std::size_t to = from;
            const int depth = t.bus[std::size_t(t.mixOrder[from])].depth;
            while (to < t.mixOrder.size() && t.bus[std::size_t(t.mixOrder[to])].depth == depth) ++to;
            for (std::size_t k = from; k < to; ++k) {
                const std::size_t b = std::size_t(t.mixOrder[k]);
                t.live[b] = run_effects(t.bus[b].rt, t.busBuf[b].data(), frames, t.used[b] != 0);
                apply_bus_gain(t.bus[b].rt, t.busBuf[b].data(), frames, t.live[b] != 0);
            }
            for (std::size_t k = from; k < to; ++k) {
                const std::size_t b = std::size_t(t.mixOrder[k]);
                const BusRuntime& fx = t.bus[b].rt;
                t.ducking[b] = fx.duckBy >= 0 && (t.live[b] || t.live[std::size_t(fx.duckBy)] || t.used[std::size_t(fx.duckBy)] ||
                                                  fx.duckGain != 1.0f || fx.duckEnv != 0.0f);
                if (t.ducking[b]) compute_duck(int(b), frames);
            }
            for (std::size_t k = from; k < to; ++k) {
                const std::size_t b = std::size_t(t.mixOrder[k]);
                if (t.ducking[b] && t.live[b]) {
                    float* buf = t.busBuf[b].data();
                    const float* g = t.duckGains[b].data();
                    for (int f = 0; f < frames; ++f) {
                        buf[2 * f] *= g[f];
                        buf[2 * f + 1] *= g[f];
                    }
                }
                if (t.live[b]) {
                    const int parent = t.bus[b].parent;
                    float* dst = parent == kMasterBus ? out : t.busBuf[std::size_t(parent)].data();
                    const float* buf = t.busBuf[b].data();
                    for (std::size_t i = 0; i < n; ++i) dst[i] += buf[i];
                    if (parent == kMasterBus) anyLive = true;
                    else t.used[std::size_t(parent)] = 1;
                }
            }
            from = to;
        }
        BusRuntime& master = t.bus[std::size_t(kMasterBus)].rt;
        const bool masterLive = run_effects(master, out, frames, anyLive);
        apply_bus_gain(master, out, frames, masterLive);
    }
    float peak = 0.0f;
    for (std::size_t i = 0; i < n; ++i) {
        float s = out[i];
        s = s > 1.0f ? 1.0f : (s < -1.0f ? -1.0f : s);
        out[i] = s;
        peak = std::max(peak, std::fabs(s));
    }
    blockPeak_ = peak;
    if (rec) {
        const std::size_t wrote = rec->write(out, n);
        if (wrote < n) rec->add_lost(n - wrote);
    }
}

}  // namespace fa::audio_detail
