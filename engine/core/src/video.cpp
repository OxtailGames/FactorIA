// This translation unit owns the pl_mpeg implementation for the whole engine. Other modules must not include pl_mpeg.h.
#define PL_MPEG_IMPLEMENTATION
#define PLM_NO_STDIO
#include <stddef.h>  // pl_mpeg.h only includes these itself when it uses stdio
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <pl_mpeg.h>

#include "fa/core/video.h"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <string>

namespace fa {

namespace {
constexpr double kAudioLeadTime = 0.1;    // seconds of audio pl_mpeg decodes ahead of the video
constexpr double kMaxPendingAudio = 2.0;  // seconds of decoded audio kept waiting for take_audio()
constexpr int kMaxDimension = 8192;

// The number of pictures in the video stream: a pass over the demuxed video packets counting picture start codes
// (00 00 01 00), no decoding. pl_mpeg's own duration is the time stamp of the last packet that has one, which for a file
// whose pictures are small is long before the end.
std::uint64_t count_pictures(std::uint8_t* data, std::size_t size) {
    plm_demux_t* demux = plm_demux_create(plm_buffer_create_with_memory(data, size, FALSE), TRUE);
    std::uint64_t count = 0;
    std::uint32_t window = 0xffffffffu;
    while (plm_packet_t* packet = plm_demux_decode(demux)) {
        if (packet->type != PLM_DEMUX_PACKET_VIDEO_1) continue;
        for (std::size_t i = 0; i < packet->length; ++i) {
            window = (window << 8) | packet->data[i];
            if (window == 0x00000100u) ++count;
        }
    }
    plm_demux_destroy(demux);
    return count;
}
}  // namespace

struct VideoDecoder::Impl {
    std::shared_ptr<const std::vector<std::uint8_t>> bytes;  // pl_mpeg reads these without copying them
    plm_t* plm = nullptr;
    plm_frame_t* frame = nullptr;  // the last decoded picture (YCrCb), converted on demand
    mutable std::vector<std::uint8_t> rgba;
    mutable bool dirty = false;
    ~Impl() {
        if (plm) plm_destroy(plm);
    }
};

VideoDecoder::~VideoDecoder() = default;

Result<std::unique_ptr<VideoDecoder>> VideoDecoder::open(std::shared_ptr<const std::vector<std::uint8_t>> bytes,
                                                         std::string_view name) {
    const std::string label(name);
    const std::string convert =
        "the engine plays MPEG-1 video with MP2 audio in an .mpg; convert any other video with `factoria call assets.import "
        "'{\"source\":\"movie.mp4\"}'` (needs ffmpeg: `factoria setup ffmpeg`), or by hand: `ffmpeg -i in.mp4 -c:v mpeg1video "
        "-c:a mp2 -f mpeg out.mpg`";
    if (!bytes || bytes->size() < 16)
        return Error{"Video '" + label + "' is empty or too short to be a video file.", convert};

    std::unique_ptr<VideoDecoder> d(new VideoDecoder());
    d->impl_ = std::make_unique<Impl>();
    Impl& im = *d->impl_;
    im.bytes = std::move(bytes);
    im.plm = plm_create_with_memory(const_cast<std::uint8_t*>(im.bytes->data()), im.bytes->size(), FALSE);
    if (!im.plm) return Error{"Video '" + label + "': the decoder could not be created (out of memory).", ""};
    if (!plm_has_headers(im.plm) || plm_get_num_video_streams(im.plm) < 1)
        return Error{"Video '" + label + "' is not an MPEG-1 video in an MPEG program stream (.mpg): no video header was found.",
                     convert};

    VideoInfo& in = d->info_;
    in.width = plm_get_width(im.plm);
    in.height = plm_get_height(im.plm);
    in.fps = plm_get_framerate(im.plm);
    if (in.width <= 0 || in.height <= 0 || in.width > kMaxDimension || in.height > kMaxDimension || !(in.fps > 0))
        return Error{"Video '" + label + "' has an unusable picture size or frame rate (" + std::to_string(in.width) + "x" +
                         std::to_string(in.height) + ", " + std::to_string(in.fps) + " fps).",
                     "keep videos between 1x1 and 8192x8192 pixels"};
    const std::uint64_t pictures = count_pictures(const_cast<std::uint8_t*>(im.bytes->data()), im.bytes->size());
    if (pictures == 0) return Error{"Video '" + label + "' has no pictures in its video stream.", convert};
    in.duration = double(pictures) / in.fps;
    in.hasAudio = plm_get_num_audio_streams(im.plm) > 0 && plm_get_samplerate(im.plm) > 0;
    in.sampleRate = in.hasAudio ? plm_get_samplerate(im.plm) : 0;

    im.rgba.assign(std::size_t(in.width) * in.height * 4, 0);
    for (std::size_t i = 3; i < im.rgba.size(); i += 4) im.rgba[i] = 255;

    plm_set_loop(im.plm, FALSE);  // looping is done by advance(), which keeps the audio and the clock in step
    plm_set_audio_lead_time(im.plm, kAudioLeadTime);
    plm_set_video_decode_callback(
        im.plm,
        [](plm_t*, plm_frame_t* f, void* user) {
            auto* self = static_cast<VideoDecoder*>(user);
            self->impl_->frame = f;
            self->impl_->dirty = true;
            ++self->pictureSerial_;
        },
        d.get());
    if (in.hasAudio)
        plm_set_audio_decode_callback(
            im.plm,
            [](plm_t*, plm_samples_t* s, void* user) {
                static_cast<VideoDecoder*>(user)->on_audio(s->interleaved, s->count, s->time);
            },
            d.get());
    if (!d->seek(0))
        return Error{"Video '" + label + "': no picture could be decoded from it (corrupt or truncated file).", convert};
    return d;
}

bool VideoDecoder::seek(double t) {
    Impl& im = *impl_;
    const double dur = info_.duration, frameLen = 1.0 / info_.fps;
    t = std::clamp(std::isfinite(t) ? t : 0.0, 0.0, dur);
    // plm_seek shows the first picture that starts at or after its target; the one that covers `t` starts up to one
    // picture earlier, so aim just under that (the pictures lie a whole frame apart).
    double target = t <= 0 ? 0.0 : std::max(0.0, t - 0.75 * frameLen);
    target = std::min(target, std::max(0.0, dur - frameLen));

    audio_.clear();
    audioProduced_ = audioSkip_ = 0;
    audioFresh_ = true;
    epochStart_ = t;
    played_ = 0;
    ++audioEpoch_;
    if (!plm_seek(im.plm, target, TRUE)) return false;
    time_ = t;
    ended_ = t >= dur;
    return true;
}

void VideoDecoder::decode_to(double target) {
    const double pt = plm_get_time(impl_->plm);
    if (target > pt) plm_decode(impl_->plm, target - pt);
}

void VideoDecoder::advance(double dt) {
    if (!(dt > 0) || !impl_ || ended_) return;
    const double dur = info_.duration;
    double remaining = dt;
    for (int pass = 0; remaining > 0 && pass < 64; ++pass) {
        const double room = std::max(0.0, dur - time_);
        const double seg = std::min(remaining, room);
        decode_to(time_ + seg);
        time_ = seg >= room ? dur : time_ + seg;
        played_ += seg;
        remaining -= seg;
        const bool exhausted = plm_has_ended(impl_->plm) != 0;
        if (time_ < dur && !exhausted) break;
        if (time_ < dur) {  // the stream ended before the length its time stamps promised
            played_ += dur - time_;
            remaining = std::max(0.0, remaining - (dur - time_));
            time_ = dur;
        }
        if (!loop_) {
            ended_ = true;
            break;
        }
        // Wrap: the audio of the pass is made exactly as long as the video of the pass, so it cannot drift per loop.
        if (info_.hasAudio) pad_audio_to(std::uint64_t(std::llround(played_ * info_.sampleRate)));
        ++loops_;
        plm_rewind(impl_->plm);
        time_ = 0;
    }
}

void VideoDecoder::pad_audio_to(std::uint64_t frames) {
    if (audioProduced_ < frames) {
        audio_.resize(audio_.size() + 2 * std::size_t(frames - audioProduced_), 0.0f);
        audioProduced_ = frames;
    } else if (audioProduced_ > frames) {
        // The audio ran past the video. Cut what still waits; what was handed out already is made up for by dropping
        // as much from the head of the next pass (audioProduced_ keeps counting it, so the timeline stays true).
        std::uint64_t excess = audioProduced_ - frames;
        const std::uint64_t cut = std::min<std::uint64_t>(excess, audio_.size() / 2);
        audio_.resize(audio_.size() - 2 * std::size_t(cut));
        audioProduced_ -= cut;
        audioSkip_ = excess - cut;
    }
}

void VideoDecoder::on_audio(const float* interleaved, std::size_t frames, double blockTime) {
    if (audioFresh_) {
        audioFresh_ = false;
        // The first block of an epoch need not start exactly where the epoch does: pad a late start, drop an early one.
        const double offset = blockTime - epochStart_;
        const auto n = std::uint64_t(std::llround(std::fabs(offset) * info_.sampleRate));
        if (offset > 0) pad_audio_to(n);
        else audioSkip_ = n;
    }
    if (audioSkip_ > 0) {
        const std::uint64_t drop = std::min<std::uint64_t>(audioSkip_, frames);
        audioSkip_ -= drop;
        interleaved += 2 * drop;
        frames -= std::size_t(drop);
    }
    audio_.insert(audio_.end(), interleaved, interleaved + 2 * frames);
    audioProduced_ += frames;
    const auto cap = std::size_t(kMaxPendingAudio * info_.sampleRate);
    if (audio_.size() / 2 > cap) audio_.erase(audio_.begin(), audio_.begin() + 2 * (audio_.size() / 2 - cap));
}

std::size_t VideoDecoder::take_audio(double lead, std::vector<float>& out) {
    if (!info_.hasAudio || audio_.empty()) return 0;
    const std::uint64_t waiting = audio_.size() / 2;
    const std::uint64_t taken = audioProduced_ - waiting;  // timeline index of audio_[0]
    const auto limit = std::uint64_t(std::max(0.0, (played_ + lead) * info_.sampleRate));
    if (limit <= taken) return 0;
    const std::size_t n = std::size_t(std::min<std::uint64_t>(waiting, limit - taken));
    out.insert(out.end(), audio_.begin(), audio_.begin() + 2 * n);
    audio_.erase(audio_.begin(), audio_.begin() + 2 * n);
    return n;
}

const std::uint8_t* VideoDecoder::picture() const {
    Impl& im = *impl_;
    if (im.dirty && im.frame) {
        plm_frame_to_rgba(im.frame, im.rgba.data(), info_.width * 4);
        im.dirty = false;
    }
    return im.rgba.data();
}

}  // namespace fa
