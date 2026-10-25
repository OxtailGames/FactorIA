#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <cstring>
#include <fstream>
#include <iterator>

#include "fa/core/video.h"
#include "fa_test_paths.h"

using namespace fa;

namespace {

// engine/core/tests/data/colors.mpg: 64x64, 25 fps, 1.2 s of MPEG-1 video (red 0 - 0.4 s, green 0.4 - 0.8 s, blue
// 0.8 - 1.2 s; the top 8 rows are noise, which makes the stream big enough to be cut into several packets, as a real
// video is, so seeking has something to find) and 1.2 s of a 440 Hz mono MP2 tone at 44100 Hz (amplitude 0.125). Made with
//   ffmpeg -f lavfi -i color=c=red:s=64x64:r=25:d=0.4 (green, blue the same) -f lavfi -i sine=frequency=440:sample_rate=44100:duration=1.2
//          -filter_complex "[0:v][1:v][2:v]concat=n=3:v=1:a=0,format=yuv420p,split[a][b];[b]crop=64:8:0:0,noise=alls=90:allf=t+u:all_seed=7[n];[a][n]overlay=0:0[v]"
//          -map "[v]" -map 3:a -c:v mpeg1video -q:v 2 -g 5 -bf 0 -c:a mp2 -b:a 64k -ac 1 -f mpeg colors.mpg
std::shared_ptr<const std::vector<std::uint8_t>> fixture_bytes() {
    std::ifstream in(FA_VIDEO_FIXTURE, std::ios::binary);
    REQUIRE_MESSAGE(in.good(), "missing fixture " FA_VIDEO_FIXTURE);
    return std::make_shared<const std::vector<std::uint8_t>>((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
}

std::unique_ptr<VideoDecoder> open_fixture() {
    auto r = VideoDecoder::open(fixture_bytes(), "colors.mpg");
    if (!r.ok()) FAIL(r.error().to_string());
    return std::move(r.value());
}

// The middle pixel as 0xRRGGBB, each channel rounded to the nearest 32 (MPEG-1 is lossy, a solid colour is off by a few).
struct Rgb {
    int r, g, b;
};
Rgb centre(const VideoDecoder& v) {
    const std::uint8_t* p = v.picture() + (std::size_t(v.info().height / 2) * v.info().width + v.info().width / 2) * 4;
    CHECK(p[3] == 255);
    return {p[0], p[1], p[2]};
}
bool is_red(Rgb c) { return c.r > 200 && c.g < 60 && c.b < 60; }
bool is_green(Rgb c) { return c.g > 100 && c.r < 60 && c.b < 60; }
bool is_blue(Rgb c) { return c.b > 200 && c.r < 60 && c.g < 60; }

}  // namespace

TEST_CASE("video: the file header gives the size, rate, length and audio") {
    auto v = open_fixture();
    const VideoInfo& i = v->info();
    CHECK(i.width == 64);
    CHECK(i.height == 64);
    CHECK(i.fps == doctest::Approx(25.0));
    CHECK(i.duration == doctest::Approx(1.2).epsilon(0.05));
    CHECK(i.hasAudio);
    CHECK(i.sampleRate == 44100);
    CHECK(v->time() == 0);
    CHECK_FALSE(v->ended());
    CHECK(is_red(centre(*v)));  // the first picture is there before any advance
}

TEST_CASE("video: advancing by the clock shows the colour that covers the time") {
    auto v = open_fixture();
    v->advance(0.2);
    CHECK(v->time() == doctest::Approx(0.2));
    CHECK(is_red(centre(*v)));
    v->advance(0.4);  // 0.6 s
    CHECK(is_green(centre(*v)));
    v->advance(0.4);  // 1.0 s
    CHECK(is_blue(centre(*v)));
    CHECK_FALSE(v->ended());
    v->advance(0.5);  // past the end
    CHECK(v->ended());
    CHECK(v->time() == doctest::Approx(v->info().duration));
    CHECK(is_blue(centre(*v)));  // the last picture stays
}

TEST_CASE("video: the same step sequence gives the same pictures and samples") {
    auto a = open_fixture();
    auto b = open_fixture();
    std::vector<float> sa, sb;
    for (int i = 0; i < 30; ++i) {
        a->advance(1.0 / 60.0);
        b->advance(1.0 / 60.0);
        a->take_audio(0.05, sa);
        b->take_audio(0.05, sb);
        REQUIRE(std::memcmp(a->picture(), b->picture(), 64 * 64 * 4) == 0);
    }
    CHECK(sa == sb);
    CHECK(sa.size() > 0);
}

TEST_CASE("video: seek shows the picture that covers the time and restarts the audio") {
    auto v = open_fixture();
    const auto epoch = v->audio_epoch();
    CHECK(v->seek(0.9));
    CHECK(v->time() == doctest::Approx(0.9));
    CHECK(is_blue(centre(*v)));
    CHECK(v->audio_epoch() != epoch);
    CHECK(v->seek(0.5));
    CHECK(is_green(centre(*v)));
    CHECK(v->seek(0.0));
    CHECK(is_red(centre(*v)));
    CHECK(v->seek(99.0));  // clamped to the end
    CHECK(v->ended());
    CHECK(v->seek(0.1));  // seeking back un-ends it
    CHECK_FALSE(v->ended());
    v->advance(0.5);
    CHECK(is_green(centre(*v)));
}

TEST_CASE("video: the audio follows the video position, one second of it is one second of samples") {
    auto v = open_fixture();
    std::vector<float> out;
    v->take_audio(0.0, out);
    CHECK(out.empty());  // nothing is released before the position
    for (int i = 0; i < 60; ++i) v->advance(1.0 / 120.0);  // 0.5 s
    const std::size_t frames = v->take_audio(0.0, out);
    CHECK(out.size() == 2 * frames);  // interleaved stereo
    CHECK(frames == doctest::Approx(0.5 * 44100).epsilon(0.02));
    // The tone is a 440 Hz sine: it swings between about -1 and 1 and both channels carry it (mono is duplicated).
    float peak = 0;
    for (std::size_t i = 0; i < frames; ++i) {
        CHECK(out[2 * i] == doctest::Approx(out[2 * i + 1]));
        peak = std::max(peak, std::fabs(out[2 * i]));
    }
    CHECK(peak > 0.1f);
    // Asking again with a lead releases that much more.
    const std::size_t more = v->take_audio(0.1, out);
    CHECK(more == doctest::Approx(0.1 * 44100).epsilon(0.02));
}

TEST_CASE("video: the audio of a whole play is as long as the video") {
    auto v = open_fixture();
    std::vector<float> out;
    std::size_t frames = 0;
    for (int i = 0; i < 240 && !v->ended(); ++i) {
        v->advance(1.0 / 120.0);
        frames += v->take_audio(0.05, out);
    }
    CHECK(v->ended());
    frames += v->take_audio(1.0, out);
    CHECK(double(frames) / 44100.0 == doctest::Approx(v->info().duration).epsilon(0.1));
}

TEST_CASE("video: a loop wraps to the first picture and keeps the audio in step") {
    auto v = open_fixture();
    v->set_loop(true);
    const double dur = v->info().duration;
    v->advance(dur + 0.2);  // once round and 0.2 s into the second pass
    CHECK_FALSE(v->ended());
    CHECK(v->loops() == 1);
    CHECK(v->time() == doctest::Approx(0.2));
    CHECK(is_red(centre(*v)));
    v->advance(dur * 3 + 0.01);  // several wraps in one step
    CHECK(v->loops() == 4);
    CHECK_FALSE(v->ended());
    // The audio timeline is exactly as long as the time played, however often the file was wrapped.
    auto w = open_fixture();
    w->set_loop(true);
    std::vector<float> out;
    std::size_t frames = 0;
    const int steps = 600;  // 5 s at 120 Hz
    for (int i = 0; i < steps; ++i) {
        w->advance(1.0 / 120.0);
        frames += w->take_audio(0.0, out);
    }
    CHECK(w->loops() >= 3);
    CHECK(double(frames) / 44100.0 == doctest::Approx(5.0).epsilon(0.01));
}

TEST_CASE("video: not-a-video bytes are refused with a teaching error") {
    auto junk = std::make_shared<const std::vector<std::uint8_t>>(std::vector<std::uint8_t>(4096, 0x41));
    auto r = VideoDecoder::open(junk, "intro.mp4");
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("intro.mp4") != std::string::npos);
    CHECK(r.error().hint.find("factoria setup ffmpeg") != std::string::npos);

    auto empty = VideoDecoder::open(std::make_shared<const std::vector<std::uint8_t>>(), "none.mpg");
    CHECK_FALSE(empty.ok());

    // A cut-off file is either refused or plays what is there; it must not crash.
    auto bytes = fixture_bytes();
    auto cut = std::make_shared<const std::vector<std::uint8_t>>(bytes->begin(), bytes->begin() + bytes->size() / 3);
    auto c = VideoDecoder::open(cut, "cut.mpg");
    if (c.ok()) {
        c.value()->advance(2.0);
        c.value()->picture();
    }
}
