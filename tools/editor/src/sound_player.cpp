#include "sound_player.h"

#include <algorithm>
#include <cmath>

namespace fa::editor {

namespace {
constexpr double kAhead = 0.35;      // seconds kept queued
constexpr double kFade = 0.002;      // seconds of fade at a start and at the end of a one-shot: no click from a cut
}  // namespace

SoundPlayer::SoundPlayer(Audio* audio, std::function<bool()> engineMixes) : audio_(audio), engineMixes_(std::move(engineMixes)) {}

SoundPlayer::~SoundPlayer() { stop(); }

void SoundPlayer::stop() {
    if (voice_ != 0 && audio_) audio_->stop(voice_);
    voice_ = 0;
    chunks_.clear();
    pushed_ = 0.0;
    ended_ = false;
}

bool SoundPlayer::play(const SoundPlayRequest& request) {
    stop();
    if (!audio_ || !request.clip || request.clip->frames() == 0) return false;
    req_ = request;
    const SoundRender& c = *request.clip;
    const double rate = double(c.rate);
    const std::size_t n = c.frames();
    regionStart_ = std::min(n - 1, std::size_t(std::max(0.0, std::llround(request.from * rate) * 1.0)));
    regionEnd_ = request.to < 0 ? n : std::min(n, std::size_t(std::max(0.0, double(std::llround(request.to * rate)))));
    if (regionEnd_ <= regionStart_ + 1) regionEnd_ = std::min(n, regionStart_ + 2);
    loopFrom_ = request.loopFrom < 0 ? regionStart_ : std::min(regionEnd_ - 1, std::size_t(std::llround(request.loopFrom * rate)));
    cursor_ = regionStart_;
    gain_ = std::pow(10.0, request.gainDb / 20.0);
    pushed_ = 0.0;
    ended_ = false;
    firstChunk_ = true;
    wraps_ = 0;
    lastPos_ = request.from;
    PlayParams params;
    params.bus = "sfx";
    voice_ = audio_->open_pcm_voice(c.rate, params, request.name.empty() ? "sound panel" : request.name, "editor");
    if (voice_ == 0) return false;
    fill();
    return true;
}

void SoundPlayer::push_run(std::size_t from, std::size_t frames, bool fadeIn, bool fadeOut) {
    const SoundRender& c = *req_.clip;
    std::vector<float> buf(frames * 2);
    const std::size_t fadeN = std::max<std::size_t>(1, std::size_t(kFade * double(c.rate)));
    for (std::size_t i = 0; i < frames; ++i) {
        double g = gain_;
        if (fadeIn && i < fadeN) g *= double(i) / double(fadeN);
        if (fadeOut && i + fadeN >= frames) g *= double(frames - i) / double(fadeN);
        if (c.channels >= 2) {
            buf[i * 2] = float(double(c.samples[(from + i) * 2]) * g);
            buf[i * 2 + 1] = float(double(c.samples[(from + i) * 2 + 1]) * g);
        } else {
            buf[i * 2] = buf[i * 2 + 1] = float(double(c.samples[from + i]) * g);
        }
    }
    audio_->push_pcm(voice_, buf.data(), frames);
    chunks_.push_back({from, frames, pushed_});
    pushed_ += double(frames);
}

void SoundPlayer::fill() {
    if (voice_ == 0 || ended_ || !req_.clip) return;
    const double rate = double(req_.clip->rate);
    const double want = kAhead * rate;
    for (int guard = 0; guard < 64; ++guard) {
        const double queued = audio_->pcm_queued_frames(voice_);
        if (queued >= want) return;
        std::size_t room = std::size_t(std::min(want - queued, 4096.0));
        if (room < 64) return;
        if (cursor_ >= regionEnd_) {
            if (!req_.loop) {
                ended_ = true;
                return;
            }
            cursor_ = loopFrom_;
            ++wraps_;
        }
        const std::size_t left = regionEnd_ - cursor_;
        std::size_t take = std::min(room, left);
        const bool fadeOut = !req_.loop && take == left;
        push_run(cursor_, take, firstChunk_, fadeOut);
        firstChunk_ = false;
        cursor_ += take;
        if (!req_.loop && cursor_ >= regionEnd_) {
            ended_ = true;
            return;
        }
    }
}

double SoundPlayer::position() const {
    if (!req_.clip) return 0.0;
    const double rate = double(req_.clip->rate);
    if (voice_ == 0) return lastPos_;
    const double consumed = pushed_ - audio_->pcm_queued_frames(voice_);
    for (const Chunk& c : chunks_) {
        if (consumed < c.cum + double(c.frames)) return (double(c.src) + std::max(0.0, consumed - c.cum)) / rate;
    }
    return double(regionEnd_) / rate;
}

void SoundPlayer::update(double dt) {
    if (voice_ == 0) return;
    fill();
    if (audio_->has_device() == false && !(engineMixes_ && engineMixes_())) audio_->advance_null_device(dt);
    const double queued = audio_->pcm_queued_frames(voice_);
    const double consumed = pushed_ - queued;
    while (chunks_.size() > 1 && consumed >= chunks_.front().cum + double(chunks_.front().frames)) chunks_.pop_front();
    fill();
    lastPos_ = position();
    if (ended_ && audio_->pcm_queued_frames(voice_) < 2.5) {  // the mixer keeps the last frame for its interpolation
        lastPos_ = double(regionEnd_) / double(req_.clip->rate);
        audio_->stop(voice_);
        voice_ = 0;
        chunks_.clear();
    }
}

bool SoundPlayer::switch_to(SoundRenderPtr clip, double gainDb, const std::string& name) {
    if (!clip || voice_ == 0) return false;
    const double pos = position();
    SoundPlayRequest r = req_;
    const double oldRate = double(req_.clip->rate);
    r.clip = std::move(clip);
    r.name = name;
    r.gainDb = gainDb;
    // The region is in seconds, so a clip of another length keeps the same times; a position past its end restarts the region.
    (void)oldRate;
    if (pos >= r.clip->seconds) r.from = req_.from;
    else r.from = pos;
    const int wraps = wraps_;
    const bool ok = play(r);
    wraps_ = wraps;
    return ok;
}

void SoundPlayer::set_gain_db(double db) {
    req_.gainDb = db;
    gain_ = std::pow(10.0, db / 20.0);
}

void SoundPlayer::set_loop(double from, double to) {
    if (!req_.clip) return;
    const double rate = double(req_.clip->rate);
    const std::size_t n = req_.clip->frames();
    req_.loopFrom = from;
    req_.to = to;
    loopFrom_ = std::min(n - 1, std::size_t(std::max(0.0, double(std::llround(from * rate)))));
    regionEnd_ = std::min(n, std::size_t(std::max(0.0, double(std::llround(to * rate)))));
    if (regionEnd_ <= loopFrom_ + 1) regionEnd_ = std::min(n, loopFrom_ + 2);
}

}  // namespace fa::editor
