// run_headless --record-video: the AVI a replay is written to.
#include <doctest.h>

#include <cmath>
#include <filesystem>
#include <fstream>

#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/core/perf.h"
#include "fa/runtime/engine.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1", "name": "Video Test", "id": "com.example.videotest",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

const char* kSilentScene = R"({"format":"factoria.scene/1","entities":[
  {"id":"cam","components":{"Camera":{"clearColor":"#203040"}}},
  {"id":"box","components":{"Transform":{"position":[0,0,0]},"Shape2D":{"size":[100,60],"color":"#ff0000"}}}]})";

const char* kSoundScene = R"({"format":"factoria.scene/1","entities":[
  {"id":"cam","components":{"Camera":{"clearColor":"#203040"}}},
  {"id":"box","components":{"Transform":{"position":[0,0,0]},"Shape2D":{"size":[100,60],"color":"#ff0000"}}},
  {"id":"snd","components":{"AudioSource":{"clip":"sounds/tone.wav","playOnStart":true}}}]})";

struct Project {
    stdfs::path dir;
    Project(const std::string& name, const char* scene) {
        dir = fs::make_temp_dir("fa_video_test_" + name);
        write("factoria.json", kProject);
        write("scenes/main.scene.json", scene);
    }
    ~Project() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    void write(const std::string& rel, const std::string& text) const {
        stdfs::create_directories((dir / rel).parent_path());
        std::ofstream(dir / rel, std::ios::binary) << text;
    }
    EngineConfig config() const {
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.hotReload = false;
        return c;
    }
};

struct AviInfo {
    int width = 0, height = 0, videoFrames = 0, audioChunks = 0, streams = 0;
    std::uint32_t usPerFrame = 0, audioRate = 0;
    std::vector<std::vector<std::uint8_t>> jpegs;
    bool ok = false;
};

std::uint32_t le32(const std::vector<std::uint8_t>& b, std::size_t at) {
    return b[at] | (b[at + 1] << 8) | (b[at + 2] << 16) | (std::uint32_t(b[at + 3]) << 24);
}

// Walks the RIFF tree of an AVI the way a player does: hdrl (avih, then strh per stream), then the movi chunks.
AviInfo parse_avi(const stdfs::path& file) {
    AviInfo a;
    std::ifstream in(file, std::ios::binary);
    std::vector<std::uint8_t> b((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    if (b.size() < 12 || std::string(b.begin(), b.begin() + 4) != "RIFF" || std::string(b.begin() + 8, b.begin() + 12) != "AVI ") return a;
    if (le32(b, 4) + 8 != b.size()) return a;  // the RIFF size is the file size
    auto id = [&](std::size_t at) { return std::string(b.begin() + at, b.begin() + at + 4); };
    std::size_t at = 12;
    while (at + 8 <= b.size()) {
        const std::string tag = id(at);
        const std::uint32_t size = le32(b, at + 4);
        if (tag == "LIST") {
            const std::string type = id(at + 8);
            if (type == "hdrl") {
                for (std::size_t q = at + 12; q + 8 <= at + 8 + size;) {
                    const std::string t = id(q);
                    const std::uint32_t s = le32(b, q + 4);
                    if (t == "avih") {
                        a.usPerFrame = le32(b, q + 8);
                        a.streams = int(le32(b, q + 8 + 24));
                        a.width = int(le32(b, q + 8 + 32));
                        a.height = int(le32(b, q + 8 + 36));
                    } else if (t == "LIST") {  // strl: LIST, size, "strl", "strh", size, fccType...
                        const std::size_t strh = q + 20;
                        if (id(q + 12) == "strh" && id(strh) == "auds") a.audioRate = le32(b, strh + 24) / 4;  // dwRate / block align
                    }
                    q += 8 + s + (s & 1);
                }
            } else if (type == "movi") {
                for (std::size_t q = at + 12; q + 8 <= at + 8 + size;) {
                    const std::string t = id(q);
                    const std::uint32_t s = le32(b, q + 4);
                    if (t == "00dc") {
                        ++a.videoFrames;
                        a.jpegs.emplace_back(b.begin() + q + 8, b.begin() + q + 8 + s);
                    }
                    if (t == "01wb") ++a.audioChunks;
                    q += 8 + s + (s & 1);
                }
            }
        }
        at += 8 + size + (size & 1);
    }
    a.ok = true;
    return a;
}

std::string tone_wav() {  // 0.4 s of a 440 Hz sine, 16-bit mono 44.1 kHz
    const int n = 17640;
    std::string d;
    auto le = [&](std::uint32_t v, int bytes) {
        for (int i = 0; i < bytes; ++i) d.push_back(char(v >> (8 * i)));
    };
    d += "RIFF"; le(36 + n * 2, 4); d += "WAVEfmt "; le(16, 4); le(1, 2); le(1, 2); le(44100, 4); le(88200, 4); le(2, 2); le(16, 2);
    d += "data"; le(n * 2, 4);
    for (int i = 0; i < n; ++i) le(std::uint16_t(std::int16_t(12000 * std::sin(i * 6.2831853 * 440 / 44100))), 2);
    return d;
}

std::string slurp(const stdfs::path& f) {
    std::ifstream in(f, std::ios::binary);
    return std::string((std::istreambuf_iterator<char>(in)), {});
}

}  // namespace

TEST_CASE("run_headless: --record-video writes an AVI with every frame, the render size and the audio") {
    Project p("sound", kSoundScene);
    p.write("sounds/tone.wav", tone_wav());
    EngineConfig c = p.config();
    HeadlessRunOptions o;
    o.frames = 5;
    o.renderScale = 1.5;
    o.videoOutPath = (p.dir / "out" / "run.avi").generic_string();
    std::vector<std::pair<int, int>> progress;
    o.videoProgress = [&](int written, int total) { progress.push_back({written, total}); };
    Json report;
    REQUIRE_MESSAGE(run_headless(c, o, &report) == 0, report.dump());
    REQUIRE(progress.size() == 5);  // one call per frame written, against the 5 asked for
    CHECK(progress.front() == std::make_pair(1, 5));
    CHECK(progress.back() == std::make_pair(5, 5));
    o.videoProgress = nullptr;
    CHECK(report["videoFrames"] == 5);
    CHECK(report["videoAudio"] == true);
    AviInfo a = parse_avi(p.dir / "out" / "run.avi");
    REQUIRE(a.ok);
    CHECK(a.videoFrames == 5);
    CHECK(a.width == 480);  // 320x180 design * 1.5
    CHECK(a.height == 270);
    CHECK(a.streams == 2);
    CHECK(a.audioChunks == 5);
    CHECK(a.audioRate == 44100);
    CHECK(a.usPerFrame == 16667);  // fixedHz 60
    CHECK_FALSE(stdfs::exists(p.dir / "out" / "run.avi.frames.tmp"));
    auto img = decode_image(a.jpegs[0].data(), a.jpegs[0].size());
    REQUIRE(img.ok());
    CHECK(img->width == 480);
    CHECK(img->height == 270);
    const Color mid = img->pixel(240, 135);  // the red box is at the centre
    CHECK(mid.r > 0.85f);
    CHECK(mid.g < 0.2f);
    const Color corner = img->pixel(5, 5);  // the clear colour
    CHECK(corner.b > corner.r);

    // Deterministic: the same run gives the same file.
    o.videoOutPath = (p.dir / "out" / "again.avi").generic_string();
    REQUIRE(run_headless(c, o, &report) == 0);
    CHECK(slurp(p.dir / "out" / "run.avi") == slurp(p.dir / "out" / "again.avi"));
}

TEST_CASE("run_headless: --record-video of a silent run has no audio stream; bad requests fail before the run") {
    Project q("silent", kSilentScene);
    EngineConfig c = q.config();
    HeadlessRunOptions o;
    o.frames = 3;
    o.videoOutPath = (q.dir / "silent.avi").generic_string();
    Json report;
    REQUIRE_MESSAGE(run_headless(c, o, &report) == 0, report.dump());
    AviInfo s = parse_avi(q.dir / "silent.avi");
    REQUIRE(s.ok);
    CHECK(s.streams == 1);
    CHECK(s.audioChunks == 0);
    CHECK(s.videoFrames == 3);
    CHECK(s.width == 320);
    CHECK(report["videoAudio"] == false);

    o.videoOutPath = (q.dir / "x.mp4").generic_string();  // no ffmpegPath
    CHECK(run_headless(c, o, &report) == 2);
    CHECK(report["error"].get<std::string>().find("ffmpeg") != std::string::npos);
    CHECK(report["error"].get<std::string>().find(".avi") != std::string::npos);
    o.videoOutPath = (q.dir / "x.mov").generic_string();
    CHECK(run_headless(c, o, &report) == 2);
    CHECK(report["error"].get<std::string>().find(".mov") != std::string::npos);
    o.videoOutPath = (q.dir / "silent.avi").generic_string();
    o.renderScale = 9;
    CHECK(run_headless(c, o, &report) == 2);
    CHECK(report["error"].get<std::string>().find("scale") != std::string::npos);
}

TEST_CASE("run_headless: --record-video keeps memory flat (every frame goes to the spool file, none stays in memory)") {
    // LL/FB-0802: a recording of 1480 frames at 1080p took 4.4 GB, because on macOS every read-back kept its command buffer
    // (one frame of pixels) alive. 150 frames at 1280x720 are 3.7 MB each: kept, they would add more than 500 MB.
    Project p("flat", kSilentScene);
    EngineConfig c = p.config();
    HeadlessRunOptions o;
    o.frames = 150;
    o.renderScale = 4;
    o.videoOutPath = (p.dir / "flat.avi").generic_string();
    Json report;
    // The first frames create the engine's own buffers: measure the growth from the 20th frame on.
    std::uint64_t at20 = 0, atEnd = 0;
    o.videoProgress = [&](int written, int) {
        if (written == 20) at20 = current_memory_bytes();
        if (written == 150) atEnd = current_memory_bytes();
    };
    REQUIRE_MESSAGE(run_headless(c, o, &report) == 0, report.dump());
    REQUIRE(report["videoFrames"] == 150);
    if (at20 > 0 && atEnd > 0) CHECK_MESSAGE(atEnd < at20 + 150ull * 1024 * 1024, "memory grew from " << at20 / 1048576 << " to " << atEnd / 1048576 << " MB");
}
