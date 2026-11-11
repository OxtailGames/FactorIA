#include "fa/audio/music_transport.h"

#include <algorithm>
#include <cmath>

#include "fa/core/math.h"

namespace fa {

namespace {
constexpr double kEps = 1e-6;
constexpr int kMaxChunk = 512;   // frames the gain envelope is computed for at a time
}  // namespace

MusicTransport::MusicTransport() = default;

long MusicTransport::frames_of(float seconds) const {
    if (seconds <= 0.0f) return 0;
    return std::max(1L, long(std::lround(double(seconds) * double(kMusicRate) / ratio_)));
}

namespace {
std::uint64_t output_frame_at(std::uint64_t mixed, double ratio, double songPos, double fromPos) {
    const double d = (songPos - fromPos) / ratio - 1e-9;
    return mixed + (d > 0.0 ? std::uint64_t(std::ceil(d)) : 0);
}
}  // namespace

std::uint64_t MusicTransport::frame_at(double songPos, double fromPos) const { return output_frame_at(mixed_, ratio_, songPos, fromPos); }

std::optional<std::uint64_t> MusicTransport::schedule_of(const MusicTransportState& t, MusicQuantize q) {
    if (!t.playing || !t.src) return std::nullopt;
    if (q == MusicQuantize::None) return t.mixed;
    return output_frame_at(t.mixed, t.ratio, music_boundary(t.src->map, t.pos, q, t.limit), t.pos);
}

void MusicTransport::set_volume(float volume, float seconds) {
    volume_ = std::max(volume, 0.0f);
    const long over = frames_of(seconds);
    if (over <= 0) {
        volCur_ = volume_;
        volLeft_ = 0;
        return;
    }
    volLeft_ = over;
    volStep_ = (volume_ - volCur_) / float(over);
}

void MusicTransport::setup_wrap(Head& h) const {
    const MusicMap& m = h.src->map;
    h.armed = false;
    if (loop_ && !h.overlay) {
        if (m.hasLoop) {
            h.wrapStart = m.loopStart;
            h.wrapEnd = m.loopEnd;
            h.armed = h.pos < m.loopEnd;
        } else {
            h.wrapStart = 0.0;
            h.wrapEnd = m.playEnd;
            h.armed = true;
        }
    }
    h.endPos = m.playEnd;
    h.tailFade = m.endFade;
}

void MusicTransport::set_loop(bool loop) {
    loop_ = loop;
    if (main_ >= 0) setup_wrap(heads_[std::size_t(main_)]);
}

double MusicTransport::limit_of(const Head& h) const { return h.armed ? h.wrapEnd : h.endPos; }

void MusicTransport::seek_cursor(Head& h, double from) const {
    const auto& marks = h.src->map.marks;
    h.cursor = std::size_t(std::lower_bound(marks.begin(), marks.end(), from - kEps, [](const MusicMark& mk, double f) { return mk.frame < f; }) - marks.begin());
}

void MusicTransport::hold(const std::shared_ptr<const MusicSource>& src) {
    for (const auto& h : held_)
        if (h == src) return;
    held_.push_back(src);
}

bool MusicTransport::references(const MusicSource* src) const {
    for (const Head& h : heads_)
        if (h.active && h.src == src) return true;
    for (const Pending& p : pending_)
        if (p.used && p.src == src) return true;
    return false;
}

void MusicTransport::prune_sources() {
    held_.erase(std::remove_if(held_.begin(), held_.end(), [&](const std::shared_ptr<const MusicSource>& s) { return !references(s.get()); }), held_.end());
}

void MusicTransport::cancel_pending() {
    for (Pending& p : pending_) p.used = false;
}

void MusicTransport::drop_pending_changes() {
    for (Pending& p : pending_)
        if (p.used && (p.kind == Kind::Jump || p.kind == Kind::Intensity)) p.used = false;
}

MusicTransport::Pending* MusicTransport::add_pending(Kind kind, std::uint64_t at) {
    Pending* slot = nullptr;
    for (Pending& p : pending_)
        if (!p.used) { slot = &p; break; }
    if (!slot) {  // full: the oldest request is dropped
        slot = &pending_[0];
        for (Pending& p : pending_)
            if (p.seq < slot->seq) slot = &p;
    }
    *slot = Pending{};
    slot->used = true;
    slot->kind = kind;
    slot->at = at;
    slot->seq = ++seq_;
    return slot;
}

MusicTransport::Head* MusicTransport::free_head() {
    for (Head& h : heads_)
        if (!h.active) return &h;
    // Every slot is busy: the quietest ghost goes, else any head that is not the main one.
    Head* quiet = nullptr;
    for (std::size_t i = 0; i < heads_.size(); ++i) {
        Head& h = heads_[i];
        if (int(i) == main_ || h.overlay) continue;
        if (!quiet || h.x < quiet->x) quiet = &h;
    }
    for (std::size_t i = 0; !quiet && i < heads_.size(); ++i)
        if (int(i) != main_) quiet = &heads_[i];
    if (!quiet) quiet = &heads_[0];
    quiet->active = false;
    return quiet;
}

void MusicTransport::retarget(Head& h, float intensity, long over) {
    const std::size_t n = std::min(h.src->stems.size(), kMusicMaxStems);
    for (std::size_t s = 0; s < n; ++s) {
        const float t = music_layer_gain(intensity, h.src->stems[s].threshold, layerRange_);
        h.target[s] = t;
        if (over <= 0) {
            h.gain[s] = t;
            h.step[s] = 0.0f;
            h.left[s] = 0;
        } else {
            h.step[s] = (t - h.gain[s]) / float(over);
            h.left[s] = over;
        }
    }
}

void MusicTransport::emit(MusicEventKind kind, int a, int b, int c, int d, const MusicSource* src) {
    if (ringCount_ >= ring_.size()) {
        ++dropped_;
        return;
    }
    MusicEvent& e = ring_[(ringHead_ + ringCount_) % ring_.size()];
    e.kind = kind;
    e.a = a;
    e.b = b;
    e.c = c;
    e.d = d;
    e.frame = mixed_;
    e.src = src ? src : (main_ >= 0 ? heads_[std::size_t(main_)].src : nullptr);
    ++ringCount_;
}

void MusicTransport::take_events(std::vector<MusicEvent>& out) {
    for (std::size_t i = 0; i < ringCount_; ++i) out.push_back(ring_[(ringHead_ + i) % ring_.size()]);
    ringHead_ = 0;
    ringCount_ = 0;
}

bool MusicTransport::pop_event(MusicEvent& out) {
    if (ringCount_ == 0) return false;
    out = ring_[ringHead_];
    ringHead_ = (ringHead_ + 1) % ring_.size();
    --ringCount_;
    return true;
}

// ---- commands -----------------------------------------------------------------------------------------------------------------

namespace {
std::string section_list(const MusicMap& m) {
    std::string out;
    for (const MusicSection& s : m.sections) out += (out.empty() ? "" : ", ") + s.name;
    return out;
}
}  // namespace

bool MusicTransport::start(std::shared_ptr<const MusicSource> src, int section, float intensity, std::string* error) {
    const bool ok = start(src.get(), section, intensity, error);
    if (ok) hold(src);
    return ok;
}

bool MusicTransport::check_start(const MusicSource* src, int section, std::string* error) {
    if (!src || src->stems.empty()) {
        if (error) *error = "the song has no audio to play";
        return false;
    }
    if (src->stems.size() > kMusicMaxStems) {
        if (error) *error = "the song has more than " + std::to_string(kMusicMaxStems) + " stems";
        return false;
    }
    const MusicMap& m = src->map;
    if (section >= 0 && (section >= int(m.sections.size()) || m.sections[std::size_t(section)].firstSpan < 0)) {
        if (error) *error = "the section is not in the song; its sections are: " + section_list(m);
        return false;
    }
    return true;
}

bool MusicTransport::start(const MusicSource* src, int section, float intensity, std::string* error) {
    if (!src || src->stems.empty()) {
        if (error) *error = "the song has no audio to play";
        return false;
    }
    if (src->stems.size() > kMusicMaxStems) {
        if (error) *error = "the song has more than " + std::to_string(kMusicMaxStems) + " stems";
        return false;
    }
    const MusicMap& m = src->map;
    double pos = 0.0;
    if (section >= 0) {
        if (section >= int(m.sections.size()) || m.sections[std::size_t(section)].firstSpan < 0) {
            if (error) *error = "the section is not in the song";
            return false;
        }
        pos = m.spans[std::size_t(m.sections[std::size_t(section)].firstSpan)].start;
    }
    cancel_pending();
    intensity_ = clamp(intensity, 0.0f, 1.0f);
    beats_ = bars_ = loops_ = 0;
    duck_ = DuckState{};
    bool sounding = false;
    for (const Head& h : heads_) sounding = sounding || h.active;
    Pending p;
    p.src = src;
    p.pos = pos;
    p.fadeFrames = sounding ? frames_of(0.01f) : 0;
    do_jump(p);
    return true;
}

void MusicTransport::stop(MusicQuantize q, float fade) {
    if (main_ < 0) return;
    Head& h = heads_[std::size_t(main_)];
    const double at = music_boundary(h.src->map, h.pos, q, limit_of(h));
    Pending p;
    if (q == MusicQuantize::None) {
        p.fadeFrames = frames_of(fade);
        p.kind = Kind::Stop;
        fire(p);
        return;
    }
    Pending* slot = add_pending(Kind::Stop, frame_at(at, h.pos));
    slot->fadeFrames = frames_of(fade);
}

void MusicTransport::set_intensity(float intensity, MusicQuantize q) {
    intensity = clamp(intensity, 0.0f, 1.0f);
    if (main_ < 0 || q == MusicQuantize::None) {
        Pending p;
        p.kind = Kind::Intensity;
        p.f0 = intensity;
        fire(p);
        return;
    }
    Head& h = heads_[std::size_t(main_)];
    const std::uint64_t at = frame_at(music_boundary(h.src->map, h.pos, q, limit_of(h)), h.pos);
    // The same boundary again (a script that sets it every frame): the newest request wins, so the older one makes room.
    for (Pending& p : pending_)
        if (p.used && p.kind == Kind::Intensity && p.at == at) p.used = false;
    Pending* slot = add_pending(Kind::Intensity, at);
    slot->f0 = intensity;
}

bool MusicTransport::go_to_section(int section, MusicQuantize q, float fade, std::string* error) {
    if (main_ < 0) {
        if (error) *error = "the music is not playing";
        return false;
    }
    Head& h = heads_[std::size_t(main_)];
    const MusicMap& m = h.src->map;
    if (section < 0 || section >= int(m.sections.size()) || m.sections[std::size_t(section)].firstSpan < 0) {
        if (error) *error = "the section is not in the song; its sections are: " + section_list(m);
        return false;
    }
    const double target = m.spans[std::size_t(m.sections[std::size_t(section)].firstSpan)].start;
    Pending p;
    p.kind = Kind::Jump;
    p.src = h.src;
    p.pos = target;
    p.fadeFrames = frames_of(fade);
    if (q == MusicQuantize::None) {
        do_jump(p);
        return true;
    }
    Pending* slot = add_pending(Kind::Jump, frame_at(music_boundary(m, h.pos, q, limit_of(h)), h.pos));
    const std::uint64_t at = slot->at, seq = slot->seq;
    *slot = p;
    slot->used = true;
    slot->at = at;
    slot->seq = seq;
    return true;
}

bool MusicTransport::play_section_stinger(int section, MusicQuantize q, float volume, float tailSeconds, std::string* error) {
    if (main_ < 0) {
        if (error) *error = "the music is not playing, so there is nothing to play the stinger over";
        return false;
    }
    Head& h = heads_[std::size_t(main_)];
    const MusicMap& m = h.src->map;
    if (section < 0 || section >= int(m.sections.size()) || m.sections[std::size_t(section)].firstSpan < 0) {
        if (error) *error = "the section is not in the song; its sections are: " + section_list(m);
        return false;
    }
    const MusicSection& sec = m.sections[std::size_t(section)];
    // The section's first pass, to the end of its last consecutive pass.
    double end = m.spans[std::size_t(sec.firstSpan)].end;
    for (std::size_t i = std::size_t(sec.firstSpan) + 1; i < m.spans.size() && m.spans[i].section == section; ++i) end = m.spans[i].end;
    const double start = m.spans[std::size_t(sec.firstSpan)].start;
    Pending p;
    p.kind = Kind::Overlay;
    p.src = h.src;
    p.pos = start;
    p.end = end;
    p.f0 = std::max(volume, 0.0f);
    p.fadeFrames = frames_of(tailSeconds);
    p.i0 = 1;
    p.i1 = section;
    const double at = music_boundary(m, h.pos, q, limit_of(h));
    Pending* slot = add_pending(Kind::Overlay, q == MusicQuantize::None ? mixed_ : frame_at(at, h.pos));
    const std::uint64_t when = slot->at, seq = slot->seq;
    *slot = p;
    slot->used = true;
    slot->at = when;
    slot->seq = seq;
    return true;
}

std::int64_t MusicTransport::schedule_clip_stinger(MusicQuantize q) {
    std::uint64_t at = mixed_;
    if (main_ >= 0 && q != MusicQuantize::None) {
        const Head& h = heads_[std::size_t(main_)];
        at = frame_at(music_boundary(h.src->map, h.pos, q, limit_of(h)), h.pos);
    }
    Pending* slot = add_pending(Kind::Event, at);
    slot->i0 = 0;
    slot->i1 = -1;
    return std::int64_t(at - mixed_);
}

void MusicTransport::duck(MusicQuantize q, float amount, float attack, float hold, float release) {
    std::uint64_t at = mixed_;
    if (main_ >= 0 && q != MusicQuantize::None) {
        const Head& h = heads_[std::size_t(main_)];
        at = frame_at(music_boundary(h.src->map, h.pos, q, limit_of(h)), h.pos);
    }
    Pending* slot = add_pending(Kind::Duck, at);
    slot->f0 = clamp(amount, 0.0f, 1.0f);
    slot->fadeFrames = frames_of(attack);
    slot->i0 = int(std::min<long>(frames_of(hold), 1L << 30));
    slot->i1 = int(std::min<long>(frames_of(release), 1L << 30));
}

bool MusicTransport::crossfade_to(std::shared_ptr<const MusicSource> src, int section, MusicQuantize q, float fadeSeconds, std::string* error) {
    const bool ok = crossfade_to(src.get(), section, q, fadeSeconds, error);
    if (ok) hold(src);
    return ok;
}

bool MusicTransport::crossfade_to(const MusicSource* src, int section, MusicQuantize q, float fadeSeconds, std::string* error) {
    if (!src || src->stems.empty() || src->stems.size() > kMusicMaxStems) {
        if (error) *error = "the song has no audio to play";
        return false;
    }
    if (main_ < 0) return start(src, section, intensity_, error);
    const MusicMap& m = src->map;
    double pos = 0.0;
    if (section >= 0) {
        if (section >= int(m.sections.size()) || m.sections[std::size_t(section)].firstSpan < 0) {
            if (error) *error = "the section is not in the song; its sections are: " + section_list(m);
            return false;
        }
        pos = m.spans[std::size_t(m.sections[std::size_t(section)].firstSpan)].start;
    }
    Head& h = heads_[std::size_t(main_)];
    Pending p;
    p.kind = Kind::Jump;
    p.src = src;
    p.pos = pos;
    p.fadeFrames = frames_of(fadeSeconds);
    p.crossfade = true;
    if (q == MusicQuantize::None) {
        do_jump(p);
        return true;
    }
    Pending* slot = add_pending(Kind::Jump, frame_at(music_boundary(h.src->map, h.pos, q, limit_of(h)), h.pos));
    const std::uint64_t at = slot->at, seq = slot->seq;
    *slot = p;
    slot->used = true;
    slot->at = at;
    slot->seq = seq;
    return true;
}

// ---- the audio thread ------------------------------------------------------------------------------------------------------------

void MusicTransport::do_jump(const Pending& p) {
    if (main_ >= 0) {
        Head& old = heads_[std::size_t(main_)];
        if (p.fadeFrames <= 0) {
            old.active = false;
        } else {
            old.main = false;
            old.xTarget = 0.0f;
            old.xStep = -old.x / float(p.fadeFrames);
            old.xLeft = p.fadeFrames;
            old.killAtFade = true;
        }
        main_ = -1;
    }
    Head* h = free_head();
    *h = Head{};
    h->active = true;
    h->main = true;
    h->src = p.src;
    h->pos = p.pos;
    setup_wrap(*h);
    retarget(*h, intensity_, 0);
    if (p.fadeFrames > 0) {
        h->x = 0.0f;
        h->xTarget = 1.0f;
        h->xStep = 1.0f / float(p.fadeFrames);
        h->xLeft = p.fadeFrames;
    }
    seek_cursor(*h, p.pos);
    main_ = int(h - heads_.data());
    ended_ = false;
    if (p.crossfade) emit(MusicEventKind::Crossfade, 0, 0, 0);
}

void MusicTransport::fire(const Pending& p) {
    switch (p.kind) {
        case Kind::Jump: do_jump(p); break;
        case Kind::Intensity:
            intensity_ = p.f0;
            if (main_ >= 0) retarget(heads_[std::size_t(main_)], intensity_, frames_of(layerFade_));
            break;
        case Kind::Stop:
            if (main_ >= 0) {
                Head& h = heads_[std::size_t(main_)];
                if (p.fadeFrames <= 0) {
                    h.active = false;
                } else {
                    h.main = false;
                    h.xTarget = 0.0f;
                    h.xStep = -h.x / float(p.fadeFrames);
                    h.xLeft = p.fadeFrames;
                    h.killAtFade = true;
                }
                emit(MusicEventKind::Ended, 1, 0, 0);
                main_ = -1;
                ended_ = true;
            }
            cancel_pending();
            break;
        case Kind::Overlay: {
            Head* h = free_head();
            *h = Head{};
            h->active = true;
            h->overlay = true;
            h->src = p.src;
            h->pos = p.pos;
            h->endPos = p.end + double(p.fadeFrames) * ratio_;
            h->tailFade = double(p.fadeFrames) * ratio_;
            h->level = p.f0;
            for (std::size_t s = 0; s < std::min(p.src->stems.size(), kMusicMaxStems); ++s) h->gain[s] = h->target[s] = 1.0f;
            emit(MusicEventKind::Stinger, p.i0, p.i1, 0, 0, p.src);
            break;
        }
        case Kind::Duck:
            duck_.phase = DuckState::Attack;
            duck_.amount = p.f0;
            duck_.hold = p.i0;
            duck_.release = p.i1;
            duck_.left = std::max(1L, p.fadeFrames);
            duck_.step = ((1.0f - p.f0) - duck_.level) / float(duck_.left);
            break;
        case Kind::Event: emit(MusicEventKind::Stinger, p.i0, p.i1, 0); break;
    }
}

void MusicTransport::announce_marks(Head& h) {
    const MusicMap& m = h.src->map;
    const double lim = limit_of(h);
    while (h.cursor < m.marks.size()) {
        const MusicMark& mk = m.marks[h.cursor];
        if (mk.frame > h.pos + kEps || mk.frame >= lim - kEps) break;
        ++h.cursor;
        const MusicSpan& sp = m.spans[std::size_t(mk.span)];
        ++beats_;
        if (mk.sectionStart) emit(MusicEventKind::Section, sp.section, sp.pass, mk.bar);
        if (mk.beat == 1) {
            ++bars_;
            emit(MusicEventKind::Bar, mk.bar, sp.section, int(bars_));
        }
        emit(MusicEventKind::Beat, mk.bar, mk.beat, sp.section, int(beats_));
    }
}

bool MusicTransport::settle_main() {
    bool changed = false;
    for (int guard = 0; guard < 8 && main_ >= 0; ++guard) {
        Head& h = heads_[std::size_t(main_)];
        announce_marks(h);
        const double lim = limit_of(h);
        if (h.pos < lim - kEps) break;
        changed = true;
        if (h.armed) {
            const double len = h.wrapEnd - h.wrapStart;
            while (h.pos >= h.wrapEnd - kEps && len > 0.0) h.pos -= len;
            ++loops_;
            emit(MusicEventKind::Loop, int(loops_), 0, 0);
            seek_cursor(h, h.wrapStart);
        } else {
            emit(MusicEventKind::Ended, 0, 0, 0);
            h.active = false;
            main_ = -1;
            ended_ = true;
            break;
        }
    }
    return changed;
}

void MusicTransport::settle() {
    for (int guard = 0; guard < 64; ++guard) {
        Pending* best = nullptr;
        for (Pending& p : pending_)
            if (p.used && p.at <= mixed_ && (!best || p.at < best->at || (p.at == best->at && p.seq < best->seq))) best = &p;
        if (best) {
            const Pending p = *best;
            best->used = false;
            fire(p);
            continue;
        }
        if (main_ >= 0) settle_main();
        break;
    }
}

void MusicTransport::step_envelope(float* env, int n) {
    for (int f = 0; f < n; ++f) {
        if (volLeft_ > 0) {
            volCur_ += volStep_;
            if (--volLeft_ == 0) volCur_ = volume_;
        }
        switch (duck_.phase) {
            case DuckState::Idle: break;
            case DuckState::Attack:
                duck_.level += duck_.step;
                if (--duck_.left <= 0) {
                    duck_.level = 1.0f - duck_.amount;
                    duck_.phase = duck_.hold > 0 ? DuckState::Hold : DuckState::Release;
                    duck_.left = duck_.hold > 0 ? duck_.hold : std::max(1L, duck_.release);
                    duck_.step = (1.0f - duck_.level) / float(std::max(1L, duck_.release));
                }
                break;
            case DuckState::Hold:
                if (--duck_.left <= 0) {
                    duck_.phase = DuckState::Release;
                    duck_.left = std::max(1L, duck_.release);
                    duck_.step = (1.0f - duck_.level) / float(duck_.left);
                }
                break;
            case DuckState::Release:
                duck_.level += duck_.step;
                if (--duck_.left <= 0) {
                    duck_.level = 1.0f;
                    duck_.phase = DuckState::Idle;
                }
                break;
        }
        env[f] = volCur_ * duck_.level;
    }
}

void MusicTransport::mix_head(Head& h, float* out, const float* env, int n) {
    const MusicSource& src = *h.src;
    const std::size_t stems = std::min(src.stems.size(), kMusicMaxStems);
    const std::int64_t frames = std::int64_t(src.stems.empty() ? 0 : src.stems[0].frames());
    for (int f = 0; f < n; ++f) {
        if (!h.main) {  // a ghost or a stinger has no one to wrap or end it
            const double lim = limit_of(h);
            if (h.pos >= lim - kEps) {
                if (h.armed && h.wrapEnd > h.wrapStart) {
                    while (h.pos >= h.wrapEnd - kEps) h.pos -= h.wrapEnd - h.wrapStart;
                } else {
                    h.active = false;
                    return;
                }
            }
        }
        const float fx = h.x;
        if (h.xLeft > 0) {
            h.x += h.xStep;
            if (--h.xLeft == 0) h.x = h.xTarget;
        }
        float hg = std::sqrt(std::max(fx, 0.0f)) * h.level * env[f];
        if (h.tailFade > 0.0) {
            const double rem = h.endPos - h.pos;
            if (rem < h.tailFade) hg *= float(std::max(rem, 0.0) / h.tailFade);
        }
        const std::int64_t i0 = std::int64_t(h.pos);
        float l = 0.0f, r = 0.0f;
        const float frac = float(h.pos - double(i0));
        for (std::size_t s = 0; s < stems; ++s) {
            float g = h.gain[s];
            if (h.left[s] > 0) {
                h.gain[s] += h.step[s];
                if (--h.left[s] == 0) h.gain[s] = h.target[s];
            }
            if (g <= 0.0f || i0 >= frames) continue;
            const MusicStem& st = src.stems[s];
            const std::int16_t* d = st.pcm.data();
            float a = float(d[2 * i0]), b = float(d[2 * i0 + 1]);
            if (frac > 1e-6f && i0 + 1 < frames) {
                a += (float(d[2 * i0 + 2]) - a) * frac;
                b += (float(d[2 * i0 + 3]) - b) * frac;
            }
            const float k = g * st.scale;
            l += a * k;
            r += b * k;
        }
        out[2 * f] += l * hg;
        out[2 * f + 1] += r * hg;
        h.pos += ratio_;
        if (h.killAtFade && h.xLeft == 0 && h.x <= 0.0f) {
            h.active = false;
            return;
        }
    }
}

void MusicTransport::mix(float* out, int frames) {
    float env[kMaxChunk];
    while (frames > 0) {
        settle();
        int n = std::min(frames, kMaxChunk);
        for (const Pending& p : pending_)
            if (p.used && p.at > mixed_) n = int(std::min<std::uint64_t>(std::uint64_t(n), p.at - mixed_));
        if (main_ >= 0) {
            const Head& h = heads_[std::size_t(main_)];
            double next = limit_of(h);
            if (h.cursor < h.src->map.marks.size()) next = std::min(next, h.src->map.marks[h.cursor].frame);
            const long k = long(std::floor((next - h.pos) / ratio_ + 1e-9));
            n = std::min(n, int(std::max(1L, k)));
        }
        n = std::max(n, 1);
        step_envelope(env, n);
        for (Head& h : heads_)
            if (h.active) mix_head(h, out, env, n);
        // The main head can have passed its limit within the chunk only by less than one frame; settle() finds it at the next turn.
        mixed_ += std::uint64_t(n);
        out += 2 * n;
        frames -= n;
    }
    settle();
}

// ---- state ---------------------------------------------------------------------------------------------------------------------------

bool MusicTransport::active() const {
    for (const Pending& p : pending_)
        if (p.used) return true;
    return head_count() > 0;
}

int MusicTransport::pending_count() const {
    int n = 0;
    for (const Pending& p : pending_) n += p.used && p.kind != Kind::Event ? 1 : 0;
    return n;
}

int MusicTransport::head_count() const {
    int n = 0;
    for (const Head& h : heads_) n += h.active ? 1 : 0;
    return n;
}

const MusicSource* MusicTransport::source() const { return main_ >= 0 ? heads_[std::size_t(main_)].src : nullptr; }

double MusicTransport::position() const { return main_ >= 0 ? heads_[std::size_t(main_)].pos : 0.0; }

std::vector<float> MusicTransport::stem_gains() const {
    std::vector<float> out;
    if (main_ < 0) return out;
    const Head& h = heads_[std::size_t(main_)];
    for (std::size_t s = 0; s < std::min(h.src->stems.size(), kMusicMaxStems); ++s) out.push_back(h.gain[s]);
    return out;
}

void MusicTransport::capture(MusicTransportState& out) const {
    out.playing = main_ >= 0;
    out.ended = ended_;
    out.active = active();
    out.volume = volume_;
    out.intensity = intensity_;
    out.pending = pending_count();
    out.heads = head_count();
    out.mixed = mixed_;
    out.src = source();
    out.pos = position();
    out.ratio = ratio_;
    out.limit = main_ >= 0 ? limit_of(heads_[std::size_t(main_)]) : 0.0;
    out.pendingSrc = nullptr;
    out.hasPendingIntensity = false;
    {
        const Pending* jump = nullptr;
        const Pending* inten = nullptr;
        for (const Pending& p : pending_) {
            if (!p.used) continue;
            if (p.kind == Kind::Jump && p.src && (!jump || p.at < jump->at || (p.at == jump->at && p.seq < jump->seq))) jump = &p;
            if (p.kind == Kind::Intensity && (!inten || p.seq > inten->seq)) inten = &p;
        }
        if (jump) {
            out.pendingSrc = jump->src;
            out.pendingPos = jump->pos;
            out.pendingAt = jump->at;
        }
        if (inten) {
            out.hasPendingIntensity = true;
            out.pendingIntensity = inten->f0;
        }
    }
    out.stemCount = 0;
    if (main_ >= 0) {
        const Head& h = heads_[std::size_t(main_)];
        out.stemCount = std::min(h.src->stems.size(), kMusicMaxStems);
        for (std::size_t s = 0; s < out.stemCount; ++s) out.stemGains[s] = h.gain[s];
    }
    out.refCount = 0;
    auto add = [&](const MusicSource* src) {
        for (std::size_t i = 0; i < out.refCount; ++i)
            if (out.refs[i] == src) return;
        if (out.refCount < out.refs.size()) out.refs[out.refCount++] = src;  // heads + pendings: it always fits
    };
    for (const Head& h : heads_)
        if (h.active && h.src) add(h.src);
    for (const Pending& p : pending_)
        if (p.used && p.src) add(p.src);
}

MusicStatus MusicTransport::status_of(const MusicTransportState& t) {
    MusicStatus st;
    st.exists = true;
    st.playing = t.playing;
    st.ended = t.ended;
    st.volume = t.volume;
    st.intensity = t.intensity;
    st.appliedIntensity = t.intensity;
    st.requestedIntensity = t.hasPendingIntensity ? t.pendingIntensity : t.intensity;
    if (t.pendingSrc) {
        const MusicMap& pm = t.pendingSrc->map;
        st.pendingSong = t.pendingSrc->path;
        st.pendingAt = t.pendingAt;
        const int span = pm.span_at(t.pendingPos);
        if (span >= 0) st.pendingSection = pm.sections[std::size_t(pm.spans[std::size_t(span)].section)].name;
    }
    st.pending = t.pending;
    st.heads = t.heads;
    if (t.playing && t.src) {
        const MusicMap& m = t.src->map;
        st.song = t.src->path;
        st.mode = t.src->mode;
        st.tempo = m.tempo;
        st.positionSeconds = t.pos / double(kMusicRate);
        m.position(t.pos, st.bar, st.beat);
        const int span = m.span_at(t.pos);
        if (span >= 0) st.section = m.sections[std::size_t(m.spans[std::size_t(span)].section)].name;
        for (const MusicStem& s : t.src->stems) st.stems.push_back(s.name);
        st.stemGains.assign(t.stemGains.begin(), t.stemGains.begin() + std::ptrdiff_t(t.stemCount));
    }
    return st;
}

MusicStatus MusicTransport::status() const {
    MusicTransportState t;
    capture(t);
    return status_of(t);
}

}  // namespace fa
