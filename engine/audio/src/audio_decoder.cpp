#include "audio_decoder.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <vector>

#include "dr_mp3.h"
#include "dr_wav.h"
#include "qoa.h"

extern "C" {  // audio_vorbis.c
void* fa_vorbis_open(const unsigned char* data, int size, int* channels, int* rate, unsigned int* frames);
int fa_vorbis_read(void* v, int channels, float* out, int frames);
int fa_vorbis_rewind(void* v);
int fa_vorbis_seek(void* v, unsigned int frame);
void fa_vorbis_close(void* v);
}

namespace fa::audio_detail {

namespace {

constexpr std::size_t kSrcFrames = 2048;  // decoded source frames a Resampler holds

class WavDecoder final : public Decoder {
public:
    ~WavDecoder() override {
        if (open_) drwav_uninit(&wav_);
    }
    bool open(const std::uint8_t* data, std::size_t size) {
        open_ = drwav_init_memory(&wav_, data, size, nullptr) != 0;
        if (!open_) return false;
        channels_ = int(wav_.channels);
        rate_ = int(wav_.sampleRate);
        frames_ = wav_.totalPCMFrameCount;
        return channels_ > 0 && rate_ > 0;
    }
    std::size_t read(float* out, std::size_t frames) override {
        return std::size_t(drwav_read_pcm_frames_f32(&wav_, frames, out));
    }
    bool rewind() override { return drwav_seek_to_pcm_frame(&wav_, 0) != 0; }

private:
    drwav wav_{};  // points at itself once opened: never moves
    bool open_ = false;
};

class Mp3Decoder final : public Decoder {
public:
    ~Mp3Decoder() override {
        if (open_) drmp3_uninit(&mp3_);
    }
    bool open(const std::uint8_t* data, std::size_t size) {
        open_ = drmp3_init_memory(&mp3_, data, size, nullptr) != 0;
        if (!open_) return false;
        channels_ = int(mp3_.channels);
        rate_ = int(mp3_.sampleRate);
        return channels_ > 0 && rate_ > 0;
    }
    std::uint64_t frames() override {
        if (frames_ == 0) frames_ = drmp3_get_pcm_frame_count(&mp3_);  // walks the frame headers, decodes nothing
        return frames_;
    }
    std::size_t read(float* out, std::size_t frames) override {
        return std::size_t(drmp3_read_pcm_frames_f32(&mp3_, frames, out));
    }
    bool rewind() override { return drmp3_seek_to_pcm_frame(&mp3_, 0) != 0; }

private:
    drmp3 mp3_{};
    bool open_ = false;
};

// stb_vorbis reads the lengths in the comment header (the second packet of the stream: vendor string, then the comments) as
// signed ints and sizes a buffer from each: a length of -1 allocates nothing and is then written to at index -1, a huge one
// loops for billions of steps. So the comment packet is assembled from its Ogg pages and every length is checked against what
// the packet holds before stb_vorbis sees the file.
bool comments_fit(const std::vector<std::uint8_t>& packet) {
    auto u32 = [&](std::size_t from) {
        return std::uint64_t(packet[from]) | std::uint64_t(packet[from + 1]) << 8 |
               std::uint64_t(packet[from + 2]) << 16 | std::uint64_t(packet[from + 3]) << 24;
    };
    if (packet.size() < 7 || packet[0] != 3 || std::memcmp(packet.data() + 1, "vorbis", 6) != 0)
        return true;  // stb_vorbis refuses it
    std::size_t p = 7;
    if (p + 4 > packet.size()) return false;
    const std::uint64_t vendor = u32(p);
    p += 4;
    if (vendor > packet.size() - p || packet.size() - p - vendor < 4) return false;
    p += std::size_t(vendor);
    const std::uint64_t comments = u32(p);
    p += 4;
    for (std::uint64_t i = 0; i < comments; ++i) {
        if (packet.size() - p < 4) return false;
        const std::uint64_t len = u32(p);
        p += 4;
        if (len > packet.size() - p) return false;
        p += std::size_t(len);
    }
    return true;
}

// The bits of a Vorbis packet, least significant first (Vorbis I spec, 2.1.4), the way stb_vorbis reads them; reading past the
// end sets `eof` instead of returning zeros the way stb_vorbis does.
struct VorbisBits {
    const std::vector<std::uint8_t>& packet;
    std::uint64_t bit = 0;
    bool eof = false;
    std::uint32_t get(int n) {
        if (eof || bit + std::uint64_t(n) > std::uint64_t(packet.size()) * 8) {
            eof = true;
            return 0;
        }
        std::uint32_t v = 0;
        for (int i = 0; i < n; ++i, ++bit) v |= std::uint32_t((packet[bit >> 3] >> (bit & 7)) & 1) << i;
        return v;
    }
    bool skip(std::uint64_t n) {
        if (eof || bit + n > std::uint64_t(packet.size()) * 8) return !(eof = true);
        bit += n;
        return true;
    }
};

int vorbis_ilog(std::uint32_t v) {  // the number of bits of v (Vorbis I spec, 9.2.1): 0 -> 0, 1 -> 1, 7 -> 3
    int bits = 0;
    for (; v; v >>= 1) ++bits;
    return bits;
}

// stb_vorbis's lookup1_values (C, so log, exp and pow take and return double), step for step, so the walk below skips the same
// number of bits stb_vorbis reads. stb_vorbis casts r^dim and (r + 1)^dim to int: past the int range that cast is undefined and
// its result differs between x86 and ARM, so such a codebook is refused (-1) instead of guessed. The spec keeps r^dim at most the
// entry count (under 2^24); (r + 1)^dim past 2^31 takes 30-odd dimensions, which no encoder writes.
int vorbis_lookup1_values(int entries, int dim) {
    constexpr double kIntRange = 2147483648.0;
    auto power = [&](float base) { return std::pow(double(base), double(dim)); };
    int r = int(std::floor(std::exp(double(float(std::log(double(float(entries)))) / float(dim)))));
    const double first = power(float(r) + 1.0f);
    if (!(first < kIntRange)) return -1;
    if (int(std::floor(first)) <= entries) ++r;
    if (power(float(r) + 1.0f) <= double(entries)) return -1;
    const double last = power(float(r));
    if (!(last < kIntRange) || int(std::floor(last)) > entries) return -1;
    return r;
}

// stb_vorbis sizes the tables of every codebook in the setup header (the third packet) from its entry and dimension counts
// with int arithmetic and no limit: entries * dimensions overflows into a negative size that becomes a 16-exabyte request, and
// its bit reader returns zeros past the end of the packet, so a tiny file can make it allocate and fill gigabytes. The walk
// follows the codebooks the way stb_vorbis reads them and refuses what libvorbis refuses (ilog(dimensions) + ilog(entries) over
// 24 bits, a lookup type over 2, a packet that ends inside its codebooks), plus more codebook entries than any encoder writes.
bool codebooks_fit(const std::vector<std::uint8_t>& packet) {
    if (packet.size() < 7 || packet[0] != 5 || std::memcmp(packet.data() + 1, "vorbis", 6) != 0)
        return true;  // stb_vorbis refuses it
    constexpr std::uint64_t kMaxEntries = std::uint64_t(1)
                                          << 22;  // over all codebooks; libvorbis encodes under 100 000
    VorbisBits bits{packet, 7 * 8};
    std::uint64_t entriesInAll = 0, valuesInAll = 0;
    const std::uint32_t count = bits.get(8) + 1;
    for (std::uint32_t i = 0; i < count; ++i) {
        if (bits.get(24) != 0x564342) return false;  // "BCV"
        const std::uint32_t dimensions = bits.get(16), entries = bits.get(24);
        const bool ordered = bits.get(1) != 0;
        const bool sparse = !ordered && bits.get(1) != 0;
        if (bits.eof || (dimensions == 0 && entries != 0)) return false;
        if (vorbis_ilog(dimensions) + vorbis_ilog(entries) > 24) return false;
        entriesInAll += entries;
        if (entriesInAll > kMaxEntries) return false;
        if (ordered) {
            std::uint32_t current = 0, length = bits.get(5) + 1;
            while (current < entries) {
                const std::uint32_t run = bits.get(vorbis_ilog(entries - current));
                if (bits.eof || length >= 32 || run > entries - current) return false;
                current += run;
                ++length;
            }
        } else {
            for (std::uint32_t e = 0; e < entries; ++e)
                if ((!sparse || bits.get(1)) && bits.get(5) + 1 == 32) return false;
        }
        const std::uint32_t lookup = bits.get(4);
        if (bits.eof || lookup > 2) return false;
        if (lookup == 0) continue;
        bits.get(32);  // minimum value
        bits.get(32);  // delta value
        const std::uint32_t valueBits = bits.get(4) + 1;
        bits.get(1);  // sequence_p
        std::uint64_t values = 0;
        if (lookup == 1) {
            const int v = entries ? vorbis_lookup1_values(int(entries), int(dimensions)) : -1;
            if (v <= 0) return false;
            values = std::uint64_t(v);
        } else {
            values = std::uint64_t(entries) * dimensions;  // under 2^24: the ilog check above
        }
        valuesInAll += values;
        if (values == 0 || valuesInAll > kMaxEntries || !bits.skip(values * valueBits)) return false;
    }
    return !bits.eof;
}

// Assembles the comment and setup packets (the second and third of the stream) from their Ogg pages and checks both before
// stb_vorbis sees the file. Anything else stb_vorbis finds wrong with the file it reports itself.
bool vorbis_headers_fit(const std::uint8_t* d, std::size_t n, bool* tooBig) {
    constexpr std::size_t kMaxPacket = std::size_t(16) << 20;
    std::vector<std::uint8_t> packets[3];  // identification (not kept), comment, setup
    std::size_t pos = 0;
    int index = 0;
    while (index < 3) {
        if (pos + 27 > n || std::memcmp(d + pos, "OggS", 4) != 0)
            return index == 0;  // not Ogg at all: stb_vorbis says so; the file ends before the setup header: damaged
        const std::size_t segments = d[pos + 26];
        if (pos + 27 + segments > n) return false;
        std::size_t at = pos + 27 + segments;
        for (std::size_t i = 0; i < segments && index < 3; ++i) {
            const std::size_t lace = d[pos + 27 + i];
            if (at + lace > n) return false;  // the file ends inside the packet
            if (index > 0) {
                std::vector<std::uint8_t>& packet = packets[index];
                packet.insert(packet.end(), d + at, d + at + lace);
                if (packet.size() > kMaxPacket) {
                    *tooBig = index == 1;  // big comments are not damage: more than the engine reads
                    return false;
                }
            }
            at += lace;
            if (lace < 255) {
                if (index == 1 && !comments_fit(packets[1])) return false;
                ++index;
            }
        }
        pos = at;
    }
    return codebooks_fit(packets[2]);
}

class OggDecoder final : public Decoder {
public:
    ~OggDecoder() override {
        if (v_) fa_vorbis_close(v_);
    }
    bool open(const std::uint8_t* data, std::size_t size) {
        if (size > 0x7fffffff || !vorbis_headers_fit(data, size, &commentsTooBig_)) return false;
        unsigned int frames = 0;
        v_ = fa_vorbis_open(data, int(size), &channels_, &rate_, &frames);
        frames_ = frames;
        return v_ && channels_ > 0 && rate_ > 0;
    }
    std::size_t read(float* out, std::size_t frames) override {
        const int n = fa_vorbis_read(v_, channels_, out, int(std::min<std::size_t>(frames, 0x7fffffff / 16)));
        return n > 0 ? std::size_t(n) : 0;
    }
    bool rewind() override { return fa_vorbis_rewind(v_) != 0; }
    bool seek(std::uint64_t frame) override { return frame <= 0x7fffffffu && fa_vorbis_seek(v_, unsigned(frame)) != 0; }

    // open() failed because the comment header is over 16 MB (big embedded cover art), not because the file is damaged
    bool comments_too_big() const { return commentsTooBig_; }

private:
    void* v_ = nullptr;
    bool commentsTooBig_ = false;
};

class QoaDecoder final : public Decoder {
public:
    bool open(const std::uint8_t* data, std::size_t size) {
        if (size > 0x7fffffff || !qoa_decode_header(data, int(size), &desc_)) return false;
        data_ = data;
        size_ = size;
        channels_ = int(desc_.channels);
        rate_ = int(desc_.samplerate);
        frames_ = desc_.samples;
        pcm_.resize(std::size_t(QOA_FRAME_LEN) * desc_.channels);
        return true;
    }
    std::size_t read(float* out, std::size_t frames) override {
        const std::size_t ch = std::size_t(channels_);
        std::size_t done = 0;
        while (done < frames) {
            if (pos_ == len_ && !next_frame()) break;
            const std::size_t n = std::min(frames - done, len_ - pos_);
            const short* s = &pcm_[pos_ * ch];
            for (std::size_t i = 0; i < n * ch; ++i) out[done * ch + i] = float(s[i]) / 32768.0f;
            pos_ += n;
            done += n;
        }
        return done;
    }
    bool rewind() override {
        offset_ = 8;  // the file header
        pos_ = len_ = 0;
        return true;
    }

private:
    bool next_frame() {
        unsigned int frameLen = 0;
        const unsigned int used =
            qoa_decode_frame(data_ + offset_, unsigned(size_ - offset_), &desc_, pcm_.data(), &frameLen);
        if (!used || !frameLen) return false;
        offset_ += used;
        len_ = frameLen;
        pos_ = 0;
        return true;
    }

    qoa_desc desc_{};
    const std::uint8_t* data_ = nullptr;
    std::size_t size_ = 0, offset_ = 8;
    std::vector<short> pcm_;  // the current frame, interleaved
    std::size_t pos_ = 0, len_ = 0;
};

template <class D>
std::unique_ptr<Decoder> opened(const std::uint8_t* data, std::size_t size, const char* problem, std::string* error) {
    auto d = std::make_unique<D>();
    if (d->open(data, size)) return d;
    *error = problem;
    return nullptr;
}

}  // namespace

bool is_audio_extension(std::string_view ext) {
    return ext == ".wav" || ext == ".ogg" || ext == ".mp3" || ext == ".qoa";
}

std::unique_ptr<Decoder> open_decoder(const std::uint8_t* data, std::size_t size, std::string_view ext,
                                      std::string* error) {
    std::unique_ptr<Decoder> d;
    if (ext == ".wav")
        d = opened<WavDecoder>(data, size, "is not a valid WAV file (hint: use 8/16/24/32-bit PCM or float WAV)",
                               error);
    else if (ext == ".ogg") {
        auto ogg = std::make_unique<OggDecoder>();
        if (ogg->open(data, size))
            d = std::move(ogg);
        else if (ogg->comments_too_big())
            *error =
                "has a comment header over 16 MB, more than the engine reads (a very large embedded cover picture); "
                "remove the metadata, e.g. `ffmpeg -i in.ogg -map_metadata -1 -c:a copy out.ogg`";
        else
            *error = "is not a valid OGG Vorbis file";
    } else if (ext == ".mp3")
        d = opened<Mp3Decoder>(data, size, "is not a valid MP3 file", error);
    else if (ext == ".qoa")
        d = opened<QoaDecoder>(data, size, "is not a valid QOA file", error);
    else {
        *error =
            "has unsupported extension '" + std::string(ext) + "' (hint: supported formats: .wav, .ogg, .mp3, .qoa)";
        return nullptr;
    }
    // A header can claim 65535 channels, and a reader allocates a block of frames for every channel: refuse what no game plays.
    if (d && d->channels() > kMaxChannels) {
        *error = "has " + std::to_string(d->channels()) + " channels, more than the " + std::to_string(kMaxChannels) +
                 " the engine reads (hint: mix it down to mono or stereo in an audio editor)";
        return nullptr;
    }
    return d;
}

// ------------------------------------------------------------------------------------------------ Resampler

Resampler::Resampler(std::shared_ptr<const Bytes> bytes, std::unique_ptr<Decoder> decoder, bool loop)
    : bytes_(std::move(bytes)), dec_(std::move(decoder)), loop_(loop) {
    channels_ = std::max(dec_->channels(), 1);
    ratio_ = dec_->rate() > 0 ? double(dec_->rate()) / double(kMixRate) : 1.0;
    src_.resize(kSrcFrames * std::size_t(channels_));
}

// Drops the source frames before `used` (they are behind the output) and reads more after the rest.
void Resampler::refill(std::size_t used) {
    const std::size_t ch = std::size_t(channels_);
    const std::size_t drop = std::min(used, count_);
    const std::size_t keep = count_ - drop;
    if (drop && keep) std::memmove(src_.data(), src_.data() + drop * ch, keep * ch * sizeof(float));
    phase_ -= double(drop);
    count_ = keep;
    float* at = src_.data() + count_ * ch;
    std::size_t got = dec_->read(at, kSrcFrames - count_);
    if (got == 0 && loop_ && dec_->rewind()) got = dec_->read(at, kSrcFrames - count_);
    count_ += got;
    if (got == 0) done_ = true;
}

std::size_t Resampler::pull(float* out, std::size_t frames) {
    const std::size_t ch = std::size_t(channels_);
    std::size_t made = 0;
    while (made < frames) {
        const std::size_t i0 = std::size_t(phase_);
        if (i0 + 1 >= count_ && !done_) {
            refill(i0);
            continue;
        }
        if (i0 >= count_) break;  // the clip is over
        const float* a = &src_[i0 * ch];
        const float* b = &src_[std::min(i0 + 1, count_ - 1) * ch];
        const float t = float(phase_ - double(i0));
        const float l = a[0] + (b[0] - a[0]) * t;
        out[2 * made] = l;
        out[2 * made + 1] = ch == 1 ? l : a[1] + (b[1] - a[1]) * t;
        phase_ += ratio_;
        ++made;
    }
    return made;
}

}  // namespace fa::audio_detail
