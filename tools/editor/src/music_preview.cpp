#include "music_preview.h"

#include <algorithm>
#include <cmath>

namespace fa::editor {

namespace {
constexpr double kAhead = 0.35;        // seconds kept queued
constexpr std::size_t kChunk = 1024;   // frames mixed at a time: the resolution of the audible playhead
constexpr float kLayerFade = 0.35f;    // seconds a layer takes to fade: quick enough to hear the slider move
constexpr float kLayerRange = 0.25f;
constexpr float kJumpFade = 0.12f;
}  // namespace

MusicPreview::MusicPreview(Audio* audio, std::function<bool()> engineMixes) : audio_(audio), engineMixes_(std::move(engineMixes)) {}

MusicPreview::~MusicPreview() { stop(); }

void MusicPreview::stop() {
    if (voice_ != 0 && audio_) audio_->stop(voice_);
    voice_ = 0;
    chunks_.clear();
    pushed_ = 0.0;
    transport_.reset();
}

bool MusicPreview::play(MusicSourcePtr src, int section, float intensity) {
    const double keepPos = lastPos_;
    stop();
    error_.clear();
    lastPos_ = keepPos;
    if (!audio_ || !src) {
        error_ = "There is nothing rendered to play yet.";
        return false;
    }
    transport_ = std::make_unique<MusicTransport>();
    transport_->set_rate_ratio(1.0);
    transport_->set_loop(true);
    transport_->set_layer_fade(kLayerFade, kLayerRange);
    if (!transport_->start(src, section, intensity, &error_)) {
        transport_.reset();
        return false;
    }
    src_ = std::move(src);
    intensity_ = intensity;
    sectionEvents_ = barEvents_ = 0;
    PlayParams params;
    params.bus = "music";
    voice_ = audio_->open_pcm_voice(kMusicRate, params, src_->path.empty() ? "music panel" : src_->path, "editor");
    if (voice_ == 0) {
        error_ = "The audio mixer could not open a voice.";
        transport_.reset();
        return false;
    }
    lastPos_ = 0.0;
    fill();
    return true;
}

void MusicPreview::set_intensity(float intensity) {
    intensity_ = std::clamp(intensity, 0.0f, 1.0f);
    if (transport_) transport_->set_intensity(intensity_, MusicQuantize::None);
}

bool MusicPreview::replace_source(MusicSourcePtr src) {
    if (!transport_ || voice_ == 0 || !src) return false;
    const Where w = where();
    const int section = (w.section >= 0 && std::size_t(w.section) < src->map.sections.size()) ? w.section : 0;
    std::string err;
    if (!transport_->crossfade_to(src, section, MusicQuantize::Bar, kJumpFade, &err)) {
        error_ = err;
        return false;
    }
    src_ = std::move(src);
    return true;
}

bool MusicPreview::go_to_section(int section) {
    if (!transport_ || voice_ == 0) return false;
    std::string err;
    if (!transport_->go_to_section(section, MusicQuantize::Bar, kJumpFade, &err)) {
        error_ = err;
        return false;
    }
    return true;
}

void MusicPreview::fill() {
    if (voice_ == 0 || !transport_) return;
    if (transport_->ended()) return;
    const double want = kAhead * double(kMusicRate);
    std::vector<float> buf(kChunk * 2);
    for (int guard = 0; guard < 64; ++guard) {
        if (transport_->ended()) return;
        const double queued = audio_->pcm_queued_frames(voice_);
        if (queued >= want) return;
        std::fill(buf.begin(), buf.end(), 0.0f);
        const double start = transport_->position();
        transport_->mix(buf.data(), int(kChunk));
        audio_->push_pcm(voice_, buf.data(), kChunk);
        chunks_.push_back({start, kChunk, pushed_, transport_->position()});
        pushed_ += double(kChunk);
    }
}

double MusicPreview::position_frames() const {
    if (voice_ == 0 || !transport_) return lastPos_;
    const double consumed = pushed_ - audio_->pcm_queued_frames(voice_);
    for (const Chunk& c : chunks_) {
        if (consumed >= c.cum + double(c.frames)) continue;
        const double offset = std::max(0.0, consumed - c.cum);
        const double linearEnd = c.songFrame + double(c.frames);
        if (std::fabs(c.endFrame - linearEnd) > 2.0 && src_) {
            // The transport jumped inside this chunk (a loop, a section change): at the end of the section pass it was in, the position
            // continues from where the jump landed.
            const int span = src_->map.span_at(c.songFrame);
            const double cut = span >= 0 ? src_->map.spans[std::size_t(span)].end - c.songFrame : double(c.frames);
            if (cut > 0.0 && cut < double(c.frames))
                return offset < cut ? c.songFrame + offset : c.endFrame - (double(c.frames) - offset);
        }
        return c.songFrame + offset;
    }
    return chunks_.empty() ? lastPos_ : chunks_.back().endFrame;
}

MusicPreview::Where MusicPreview::where() const {
    Where w;
    if (!src_) return w;
    const double pos = position_frames();
    src_->map.position(pos, w.bar, w.beat);
    w.span = src_->map.span_at(pos);
    if (w.span >= 0) w.section = src_->map.spans[std::size_t(w.span)].section;
    return w;
}

std::vector<float> MusicPreview::stem_gains() const { return transport_ ? transport_->stem_gains() : std::vector<float>{}; }

void MusicPreview::finish() {
    lastPos_ = position_frames();
    if (voice_ != 0) audio_->stop(voice_);
    voice_ = 0;
    chunks_.clear();
    pushed_ = 0.0;
    transport_.reset();
}

void MusicPreview::update(double dt) {
    if (voice_ == 0 || !transport_) return;
    fill();
    if (audio_->has_device() == false && !(engineMixes_ && engineMixes_())) audio_->advance_null_device(dt);
    const double consumed = pushed_ - audio_->pcm_queued_frames(voice_);
    while (chunks_.size() > 1 && consumed >= chunks_.front().cum + double(chunks_.front().frames)) chunks_.pop_front();
    fill();
    std::vector<MusicEvent> events;
    transport_->take_events(events);
    for (const MusicEvent& e : events) {
        if (e.kind == MusicEventKind::Section) ++sectionEvents_;
        else if (e.kind == MusicEventKind::Bar) ++barEvents_;
    }
    transport_->prune_sources();
    // A looped section: when nothing waits for a boundary and the transport (which mixes a third of a second ahead of what is heard) is inside
    // it, ask for the jump back to its start at the end of the pass.
    if (loopSection_ >= 0 && transport_->pending_count() == 0 && !transport_->ended()) {
        const int span = src_->map.span_at(transport_->position());
        if (span >= 0 && src_->map.spans[std::size_t(span)].section == loopSection_)
            transport_->go_to_section(loopSection_, MusicQuantize::Section, 0.02f, nullptr);
    }
    if (transport_->ended() && audio_->pcm_queued_frames(voice_) < 2.5) finish();   // the mixer keeps the last frame for its interpolation
}

}  // namespace fa::editor
