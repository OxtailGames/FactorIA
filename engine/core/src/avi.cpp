#include "fa/core/avi.h"

#include <algorithm>
#include <cmath>
#include <filesystem>

#include "fa/core/fs.h"

namespace fa {

namespace {

void put16(std::vector<std::uint8_t>& b, std::uint32_t v) {
    b.push_back(std::uint8_t(v));
    b.push_back(std::uint8_t(v >> 8));
}
void put32(std::vector<std::uint8_t>& b, std::uint32_t v) {
    put16(b, v & 0xffff);
    put16(b, v >> 16);
}
void tag(std::vector<std::uint8_t>& b, const char* s) {
    for (int i = 0; i < 4; ++i) b.push_back(std::uint8_t(s[i]));
}
// A chunk "<tag><size><data>", padded to an even size.
void chunk(std::vector<std::uint8_t>& b, const char* t, const std::vector<std::uint8_t>& data) {
    tag(b, t);
    put32(b, std::uint32_t(data.size()));
    b.insert(b.end(), data.begin(), data.end());
    if (data.size() & 1) b.push_back(0);
}
void list(std::vector<std::uint8_t>& b, const char* type, const std::vector<std::uint8_t>& body) {
    tag(b, "LIST");
    put32(b, std::uint32_t(body.size() + 4));
    tag(b, type);
    b.insert(b.end(), body.begin(), body.end());
}

// ponytail: a classic AVI keeps every size in 32 bits, so a file tops out near 2 GB (about 3 minutes of 1080p60 at the
// ~10 MB/s our JPEG frames take). Upgrade path: OpenDML (AVIX RIFF extensions, 64-bit super index), or for .mp4 let ffmpeg
// read a JPEG sequence instead of the AVI, which has no such limit.
constexpr std::uint64_t kMaxFileBytes = 0x7ff00000;

}  // namespace

AviWriter::~AviWriter() {
    if (open_) {
        spool_.close();
        std::error_code ec;
        std::filesystem::remove(fs::os_path(spoolPath_), ec);
    }
}

Result<void> AviWriter::begin(const std::string& path, int width, int height, double fps) {
    if (width < 1 || height < 1 || !(fps > 0)) return make_error("AVI: the size and the frame rate must be above 0.");
    path_ = fs::is_absolute(path) ? path : fs::resolve(path).generic_string();
    spoolPath_ = path_ + ".frames.tmp";
    width_ = width;
    height_ = height;
    fps_ = fps;
    std::error_code ec;
    std::filesystem::create_directories(fs::os_path(std::filesystem::path(path_).parent_path()), ec);
    spool_.open(fs::os_path(spoolPath_), std::ios::binary | std::ios::trunc);
    if (!spool_) return make_error("Cannot write " + spoolPath_ + ".", "Check that the folder exists and is writable.");
    open_ = true;
    sizes_.clear();
    spooled_ = 0;
    return {};
}

Result<void> AviWriter::add_frame(const std::vector<std::uint8_t>& jpeg) {
    if (!open_) return make_error("AVI: begin() was not called.");
    if (jpeg.empty()) return make_error("AVI: an empty JPEG frame.");
    // Stop as soon as the file could no longer be written (frames, 32 bytes of chunk header and index each, and the
    // audio of 48 kHz stereo 16-bit those frames last), not after the whole run.
    const std::uint64_t frames = sizes_.size() + 1;
    const std::uint64_t audioReserve = std::uint64_t(double(frames) / fps_ * 192000.0);
    if (spooled_ + 8 + jpeg.size() + 1 + 32 * frames + audioReserve + 4096 > kMaxFileBytes)
        return make_error("The video reached the 2 GB limit of an AVI file after " + std::to_string(sizes_.size()) + " frames (" +
                              std::to_string(std::uint64_t(double(sizes_.size()) / fps_)) + " s).",
                          "Record fewer frames or use a smaller --render-scale; about 3 minutes of 1080p at 60 fps fit.");
    spooled_ += 8 + jpeg.size() + (jpeg.size() & 1);
    spool_.write(reinterpret_cast<const char*>(jpeg.data()), std::streamsize(jpeg.size()));
    if (!spool_) return make_error("Cannot write " + spoolPath_ + ": the disk may be full.");
    sizes_.push_back(std::uint32_t(jpeg.size()));
    return {};
}

Result<void> AviWriter::finish(const std::int16_t* pcm, std::size_t sampleFrames, int sampleRate) {
    if (!open_) return make_error("AVI: begin() was not called.");
    spool_.close();
    open_ = false;
    struct Cleanup {
        std::string path;
        ~Cleanup() {
            std::error_code ec;
            std::filesystem::remove(fs::os_path(path), ec);
        }
    } cleanup{spoolPath_};

    const bool audio = pcm && sampleFrames > 0 && sampleRate > 0;
    const std::uint32_t n = std::uint32_t(sizes_.size());
    const std::uint32_t scale = 1000, rate = std::uint32_t(std::lround(fps_ * 1000));
    std::uint32_t maxFrame = 0;
    std::uint64_t total = 0;  // bytes of all chunks of the movi list
    for (std::uint32_t s : sizes_) {
        maxFrame = std::max(maxFrame, s);
        total += 8 + s + (s & 1);
    }
    // Audio of frame i: sample frames [N * i / n, N * (i + 1) / n); the last frame takes the rest.
    auto slice = [&](std::uint32_t i, std::size_t& from, std::size_t& to) {
        from = std::size_t(std::uint64_t(sampleFrames) * i / n);
        to = i + 1 == n ? sampleFrames : std::size_t(std::uint64_t(sampleFrames) * (i + 1) / n);
    };
    if (audio && n > 0)
        for (std::uint32_t i = 0; i < n; ++i) {
            std::size_t from, to;
            slice(i, from, to);
            total += 8 + (to - from) * 4;  // 4 bytes a sample frame: always even
        }
    if (total + 32ull * n + 4096 > kMaxFileBytes)
        return make_error("The video would be larger than 2 GB, the limit of an AVI file.", "Record fewer frames or use a smaller --render-scale.");

    std::vector<std::uint8_t> hdrl;
    {
        std::vector<std::uint8_t> avih;
        put32(avih, std::uint32_t(std::lround(1e6 / fps_)));  // microseconds per frame
        put32(avih, 0);                                       // max bytes per second (unknown)
        put32(avih, 0);                                       // padding granularity
        put32(avih, 0x10);                                    // AVIF_HASINDEX
        put32(avih, n);
        put32(avih, 0);                                       // initial frames
        put32(avih, audio ? 2 : 1);                           // streams
        put32(avih, maxFrame + (audio ? 65536 : 0));          // suggested buffer
        put32(avih, std::uint32_t(width_));
        put32(avih, std::uint32_t(height_));
        for (int i = 0; i < 4; ++i) put32(avih, 0);
        chunk(hdrl, "avih", avih);

        std::vector<std::uint8_t> strl, strh, strf;
        tag(strh, "vids");
        tag(strh, "MJPG");
        put32(strh, 0); put16(strh, 0); put16(strh, 0); put32(strh, 0);                   // flags, priority, language, initial
        put32(strh, scale); put32(strh, rate); put32(strh, 0); put32(strh, n);            // scale, rate, start, length
        put32(strh, maxFrame); put32(strh, 0xffffffffu); put32(strh, 0);                  // buffer, quality, sample size
        put16(strh, 0); put16(strh, 0); put16(strh, std::uint32_t(width_)); put16(strh, std::uint32_t(height_));
        chunk(strl, "strh", strh);
        put32(strf, 40); put32(strf, std::uint32_t(width_)); put32(strf, std::uint32_t(height_));
        put16(strf, 1); put16(strf, 24); tag(strf, "MJPG");
        put32(strf, std::uint32_t(width_) * std::uint32_t(height_) * 3);
        put32(strf, 0); put32(strf, 0); put32(strf, 0); put32(strf, 0);
        chunk(strl, "strf", strf);
        list(hdrl, "strl", strl);
    }
    if (audio) {
        std::vector<std::uint8_t> strl, strh, strf;
        tag(strh, "auds");
        put32(strh, 0);  // handler: none for PCM
        put32(strh, 0); put16(strh, 0); put16(strh, 0); put32(strh, 0);
        put32(strh, 4); put32(strh, std::uint32_t(sampleRate) * 4); put32(strh, 0); put32(strh, std::uint32_t(sampleFrames));
        put32(strh, 0); put32(strh, 0xffffffffu); put32(strh, 4);
        put16(strh, 0); put16(strh, 0); put16(strh, 0); put16(strh, 0);
        chunk(strl, "strh", strh);
        put16(strf, 1); put16(strf, 2); put32(strf, std::uint32_t(sampleRate));  // WAVEFORMATEX: PCM, stereo
        put32(strf, std::uint32_t(sampleRate) * 4); put16(strf, 4); put16(strf, 16);
        chunk(strl, "strf", strf);
        list(hdrl, "strl", strl);
    }

    std::ifstream in(fs::os_path(spoolPath_), std::ios::binary);
    std::ofstream out(fs::os_path(path_), std::ios::binary | std::ios::trunc);
    if (!out) return make_error("Cannot write " + path_ + ".", "Check that the folder is writable and the file is not open in a player.");
    const std::uint64_t moviBody = 4 + total;
    const std::uint64_t idxBytes = std::uint64_t(n) * 16 * (audio ? 2 : 1);
    const std::uint64_t riffSize = 4 + (8 + 4 + hdrl.size()) + (8 + moviBody) + (8 + idxBytes);
    std::vector<std::uint8_t> head;
    tag(head, "RIFF");
    put32(head, std::uint32_t(riffSize));
    tag(head, "AVI ");
    tag(head, "LIST");
    put32(head, std::uint32_t(hdrl.size() + 4));
    tag(head, "hdrl");
    head.insert(head.end(), hdrl.begin(), hdrl.end());
    tag(head, "LIST");
    put32(head, std::uint32_t(moviBody));
    tag(head, "movi");
    out.write(reinterpret_cast<const char*>(head.data()), std::streamsize(head.size()));

    std::vector<std::uint8_t> index;
    std::uint32_t offset = 4;  // from the 'movi' tag
    auto idx = [&](const char* id, std::uint32_t size) {
        tag(index, id);
        put32(index, 0x10);  // AVIIF_KEYFRAME: every JPEG is one (audio chunks too)
        put32(index, offset);
        put32(index, size);
        offset += 8 + size + (size & 1);
    };
    std::vector<std::uint8_t> buf;
    for (std::uint32_t i = 0; i < n; ++i) {
        buf.resize(sizes_[i]);
        in.read(reinterpret_cast<char*>(buf.data()), std::streamsize(buf.size()));
        if (!in) return make_error("Cannot read back " + spoolPath_ + ".");
        std::vector<std::uint8_t> c;
        chunk(c, "00dc", buf);
        out.write(reinterpret_cast<const char*>(c.data()), std::streamsize(c.size()));
        idx("00dc", sizes_[i]);
        if (audio) {
            std::size_t from, to;
            slice(i, from, to);
            std::vector<std::uint8_t> a;
            a.reserve((to - from) * 4);
            for (std::size_t k = from * 2; k < to * 2; ++k) put16(a, std::uint16_t(pcm[k]));
            std::vector<std::uint8_t> ac;
            chunk(ac, "01wb", a);
            out.write(reinterpret_cast<const char*>(ac.data()), std::streamsize(ac.size()));
            idx("01wb", std::uint32_t(a.size()));
        }
    }
    std::vector<std::uint8_t> tail;
    tag(tail, "idx1");
    put32(tail, std::uint32_t(index.size()));
    tail.insert(tail.end(), index.begin(), index.end());
    out.write(reinterpret_cast<const char*>(tail.data()), std::streamsize(tail.size()));
    out.close();
    if (!out) return make_error("Cannot write " + path_ + ": the disk may be full.");
    return {};
}

}  // namespace fa
