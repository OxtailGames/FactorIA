// The real-time path with a device (docs/SOUND.md, "The audio callback"): the game thread hands commands to the mixer
// through a bounded lock-free ring and the device callback applies them, mixes and hands back what it is done with. These
// tests drive the mixer as a device would (AudioTestAccess::use_manual_device + render) so they can count the callback's
// allocations, hold the API lock while it runs, starve its streams and hammer it from several threads.
#include <doctest.h>

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <mutex>
#include <thread>
#include <vector>

#include "../src/audio_rings.h"
#include "../src/audio_testing.h"
#include "alloc_counter.h"
#include "audio_test_helpers.h"
#include "fa/audio/audio.h"
#include "fa/core/jobs.h"
#include "fa/core/json.h"

using namespace fa;
using namespace audio_test;

namespace {

constexpr int kBlock = 512;  // frames per callback, as a typical device asks

PlayParams on(const char* bus, bool loop = true, bool notify = false, float volume = 1.0f) {
    PlayParams p;
    p.bus = bus;
    p.loop = loop;
    p.notifyEnd = notify;
    p.volume = volume;
    return p;
}

// `blocks` callbacks of kBlock stereo frames; the loudest sample they produced. The output buffer is the device's: made
// once, outside the counted allocations.
float render_blocks(Audio& audio, int blocks) {
    thread_local std::vector<float> buf(std::size_t(kBlock) * 2);
    float peak = 0.0f;
    for (int i = 0; i < blocks; ++i) {
        AudioTestAccess::render(audio, buf.data(), kBlock, 2);
        for (float s : buf) peak = std::max(peak, std::fabs(s));
    }
    return peak;
}

std::uint64_t stat(const Json& j, const char* key) { return j.at(key).get<std::uint64_t>(); }

}  // namespace

TEST_CASE("audio rings: the command ring hands values over in order, whole batches at a time, and refuses past its size") {
    audio_detail::SpscRing<int> ring(5);
    CHECK(ring.capacity() == 8);  // rounded up to a power of two
    for (int i = 0; i < 8; ++i) CHECK(ring.push(i));
    CHECK_FALSE(ring.push(8));  // full: the producer is told, nothing is overwritten
    CHECK(ring.empty());        // staged, not committed: the consumer sees none of the batch yet
    ring.commit();
    CHECK(ring.size() == 8);
    int v = -1;
    for (int i = 0; i < 8; ++i) {
        REQUIRE(ring.pop(v));
        CHECK(v == i);
    }
    CHECK_FALSE(ring.pop(v));
    CHECK(ring.free_space() == 8);
    // Indexes keep growing across the wrap.
    for (int round = 0; round < 3; ++round) {
        for (int i = 0; i < 6; ++i) CHECK(ring.push(round * 10 + i));
        ring.commit();
        for (int i = 0; i < 6; ++i) {
            REQUIRE(ring.pop(v));
            CHECK(v == round * 10 + i);
        }
    }
}

TEST_CASE("audio rings: the triple buffer gives the reader the newest whole value, and nothing new when nothing was published") {
    audio_detail::TripleBuffer<int> tb;
    CHECK_FALSE(tb.update());
    tb.back() = 1;
    tb.publish();
    tb.back() = 2;
    tb.publish();  // the reader missed 1: it gets the newest
    CHECK(tb.update());
    CHECK(tb.front() == 2);
    CHECK_FALSE(tb.update());
    CHECK(tb.front() == 2);
    tb.back() = 3;
    tb.publish();
    CHECK(tb.update());
    CHECK(tb.front() == 3);
}

TEST_CASE("audio rings: one producer and one consumer thread pass 200000 values through a small ring in order") {
    audio_detail::SpscRing<std::uint32_t> ring(64);
    constexpr std::uint32_t kCount = 200000;
    std::atomic<bool> ok{true};
    std::thread consumer([&] {
        std::uint32_t expect = 0, v = 0;
        while (expect < kCount) {
            if (!ring.pop(v)) {
                std::this_thread::yield();
                continue;
            }
            if (v != expect) ok.store(false, std::memory_order_relaxed);
            ++expect;
        }
    });
    for (std::uint32_t i = 0; i < kCount;) {
        if (ring.push(i)) {
            ++i;
            if (i % 7 == 0) ring.commit();  // batches of several values
        } else {
            ring.commit();
            std::this_thread::yield();
        }
    }
    ring.commit();
    consumer.join();
    CHECK(ok.load());
}

TEST_CASE("audio callback: with a device, applying commands and mixing allocate nothing") {
    Fixture fx;
    fx.write_assets(R"({"format": "factoria.assets/1", "assets": {"sounds/streamed.wav": {"import": {"stream": "always"}}}})");
    std::vector<float> st;  // 22050 Hz stereo, 3 s: the resampler works while it streams
    for (int i = 0; i < 66150; ++i) {
        st.push_back(0.3f * std::sin(0.05f * float(i)));
        st.push_back(0.3f * std::sin(0.031f * float(i)));
    }
    write_file(fx.dir / "sounds/streamed.wav", wav_bytes(st, 2, 22050));
    write_sine_wav(fx.dir / "sounds/short.wav", 0.3, 600.0, 0.5);
    write_sine_wav(fx.dir / "sounds/hi.wav", 1.0, 3000.0, 0.4);
    REQUIRE(fx.audio.load("sounds/short.wav"));  // decoding is the game's work, not the callback's
    REQUIRE(fx.audio.load("sounds/hi.wav"));

    AudioTestAccess::use_manual_device(fx.audio, 48000);  // from here every command goes through the ring
    // The bus table swap, the effects and the ducking reach the mixer as commands too.
    fx.audio.set_buses({{"ambience", "sfx"}, {"birds", "ambience"}, {"voiceover", "master"}});
    REQUIRE(fx.audio.set_bus_lowpass("sfx", 2000.0f, 0.5f).ok());
    REQUIRE(fx.audio.set_bus_reverb("ambience", 0.3f).ok());
    DuckSettings duck;
    duck.by = "voiceover";
    duck.amount = 0.8f;
    duck.attack = 0.01f;
    duck.release = 0.05f;
    REQUIRE(fx.audio.set_bus_duck("music", duck).ok());

    (void)render_blocks(fx.audio, 0);  // makes this thread's output buffer
    std::size_t allocs = 0;
    auto counted = [&](int blocks) {
        AllocCounter::Scope scope;
        const float peak = render_blocks(fx.audio, blocks);
        allocs += scope.count();
        AudioTestAccess::pump(fx.audio);  // the game's side of a frame: commit, refill the streams, take back
        return peak;
    };
    counted(2);

    const VoiceId amb = fx.audio.play("sounds/streamed.wav", on("ambience"));
    const VoiceId birds = fx.audio.play("sounds/hi.wav", on("birds", true, false, 0.5f));
    fx.audio.play("sounds/sine.wav", on("music"));
    const VoiceId pcm = fx.audio.open_pcm_voice(22050, on("sfx"), "video.mp4", "1");
    REQUIRE(amb != 0);
    REQUIRE(birds != 0);
    REQUIRE(pcm != 0);
    fx.audio.push_pcm(pcm, st.data(), 22050);
    CHECK(counted(8) > 0.05f);

    std::vector<VoiceId> shorts;
    for (int round = 0; round < 40; ++round) {
        // A frame's worth of everything a game sends: plays, settings, fades, stops, bus and master changes.
        shorts.push_back(fx.audio.play("sounds/short.wav", on(round % 2 ? "voiceover" : "ui", false, true)));
        fx.audio.set_voice_volume(birds, 0.2f + 0.02f * float(round), 0.1f);
        fx.audio.set_bus_volume("birds", round % 2 ? 0.4f : 0.8f, 0.2f);
        REQUIRE(fx.audio.set_bus_lowpass("sfx", round % 2 ? 800.0f : 4000.0f, 0.1f).ok());
        fx.audio.set_master_volume(round % 3 ? 1.0f : 0.9f);
        if (round == 20) fx.audio.stop(amb);
        counted(4);
    }
    CHECK_MESSAGE(allocs == 0, "the device callback allocated " << allocs << " times");
    counted(40);  // the last short voice ends

    const std::vector<VoiceId> done = fx.audio.take_ended_voices();
    for (VoiceId v : shorts) CHECK(std::find(done.begin(), done.end(), v) != done.end());
    CHECK(stat(fx.audio.stats(), "commandsDropped") == 0);
}

TEST_CASE("audio callback: it mixes while another thread holds the API lock") {
    Fixture fx;
    AudioTestAccess::use_manual_device(fx.audio, 48000);
    fx.audio.play("sounds/sine.wav", on("sfx"));  // committed when play() returns: the callback needs nothing else
    fx.audio.set_bus_volume("sfx", 0.5f, 0.2f);

    std::atomic<bool> done{false};
    float peak = 0.0f;
    std::thread callback;
    {
        // The lock every API call takes, held for the whole test: if the callback took it, it would wait here forever.
        std::lock_guard<std::recursive_mutex> hold(AudioTestAccess::api_mutex(fx.audio));
        callback = std::thread([&] {
            peak = render_blocks(fx.audio, 50);
            done.store(true, std::memory_order_release);  // release: `peak` is written before `done` reads true
        });
        // A safety net far above the few milliseconds the 50 blocks take, so a failing build reports instead of hanging.
        const auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(30);
        while (!done.load(std::memory_order_acquire) && std::chrono::steady_clock::now() < deadline)
            std::this_thread::sleep_for(std::chrono::milliseconds(1));
        CHECK_MESSAGE(done.load(std::memory_order_acquire), "the audio callback waited for the API lock");
    }
    callback.join();
    CHECK(peak > 0.05f);  // it mixed the voice that play() sent, while the lock was held
}

TEST_CASE("audio callback: a stream the decode jobs do not refill underruns into silence, is counted and resumes") {
    Fixture fx;
    fx.write_assets(R"({"format": "factoria.assets/1", "assets": {"sounds/long.wav": {"import": {"stream": "always"}}}})");
    write_sine_wav(fx.dir / "sounds/long.wav", 3.0, 440.0, 0.5);
    AudioTestAccess::use_manual_device(fx.audio, 44100);
    AudioTestAccess::set_stream_service(fx.audio, false);  // as if the jobs were late
    const VoiceId v = fx.audio.play("sounds/long.wav", on("sfx", false));
    REQUIRE(v != 0);

    CHECK(render_blocks(fx.audio, 4) > 0.1f);   // the frames decoded when it started
    render_blocks(fx.audio, 16);                // they run out: never waits for the decoder
    CHECK(render_blocks(fx.audio, 4) == 0.0f);  // silence, not noise or a repeat
    Json st = fx.audio.stats();
    CHECK(stat(st, "underruns") >= 4);
    CHECK(stat(st, "underrunFrames") >= std::uint64_t(4 * kBlock));
    CHECK(stat(st, "underrunFrames") <= std::uint64_t(24 * kBlock));
    CHECK(fx.audio.is_playing(v));  // the voice waits where it is

    AudioTestAccess::set_stream_service(fx.audio, true);
    AudioTestAccess::pump(fx.audio);  // the refill job (inline here: no job pool runs)
    CHECK(render_blocks(fx.audio, 4) > 0.1f);
    const std::uint64_t before = stat(fx.audio.stats(), "underruns");
    for (int i = 0; i < 20; ++i) {
        render_blocks(fx.audio, 2);
        AudioTestAccess::pump(fx.audio);
    }
    CHECK(stat(fx.audio.stats(), "underruns") == before);  // refilled every frame: no more
}

TEST_CASE("audio callback: several threads playing, changing and stopping voices while the callback mixes") {
    REQUIRE(jobs::start(jobs::Settings::threads(2)));  // the stream refills run on workers
    {
        Fixture fx;
        fx.write_assets(R"({"format": "factoria.assets/1", "assets": {"sounds/streamed.wav": {"import": {"stream": "always"}}}})");
        write_sine_wav(fx.dir / "sounds/streamed.wav", 2.0, 330.0, 0.3);
        write_sine_wav(fx.dir / "sounds/short.wav", 0.05, 600.0, 0.5);
        REQUIRE(fx.audio.load("sounds/short.wav"));
        AudioTestAccess::use_manual_device(fx.audio, 48000);

        std::atomic<bool> stopMixing{false};
        std::thread callback([&] {
            std::vector<float> buf(std::size_t(kBlock) * 2);
            while (!stopMixing.load(std::memory_order_acquire)) {
                AudioTestAccess::render(fx.audio, buf.data(), kBlock, 2);
                std::this_thread::yield();
            }
        });

        // 4 threads x 100 rounds x at most 4 commands: 1600 commands in all, 10x under what the ring plus the staging
        // queue hold (2048 + 8192), so none is dropped however late the callback runs.
        constexpr int kThreads = 4, kRounds = 100;
        std::vector<std::vector<VoiceId>> kept(kThreads);
        std::vector<std::thread> game;
        for (int t = 0; t < kThreads; ++t) {
            game.emplace_back([&, t] {
                for (int i = 0; i < kRounds; ++i) {
                    PlayParams p = on(i % 2 ? "sfx" : "ui", i % 4 != 0, true, 0.1f + 0.01f * float(i % 50));
                    p.priority = (t * 37 + i * 11) % 256;
                    const char* clip = i % 10 == 0 ? "sounds/streamed.wav" : (i % 3 == 0 ? "sounds/short.wav" : "sounds/sine.wav");
                    const VoiceId v = fx.audio.play(clip, p);
                    if (v != 0) {
                        fx.audio.set_voice_volume(v, 0.2f, 0.05f);
                        if (i % 3 == 1) fx.audio.stop(v);
                        else kept[std::size_t(t)].push_back(v);
                    }
                    if (i % 25 == 0) fx.audio.set_bus_volume(t % 2 ? "sfx" : "ui", 0.5f + 0.1f * float(t), 0.1f);
                    (void)fx.audio.is_playing(v);
                    if (i % 10 == 0) (void)fx.audio.take_ended_voices();
                }
            });
        }
        for (std::thread& g : game) g.join();
        for (const std::vector<VoiceId>& ids : kept)
            for (VoiceId v : ids) fx.audio.stop(v);
        // Let the callback take the stops and hand back the ended voices (a safety net far above the few blocks needed).
        const auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(30);
        while (std::chrono::steady_clock::now() < deadline) {
            fx.audio.service();
            if (fx.audio.active_voices().size() == 0) break;
            std::this_thread::sleep_for(std::chrono::milliseconds(2));
        }
        stopMixing.store(true, std::memory_order_release);
        callback.join();

        const Json st = fx.audio.stats();
        CHECK(stat(st, "activeVoices") == 0);
        CHECK(stat(st, "commandsDropped") == 0);
        CHECK(stat(st, "settingsDropped") == 0);
        CHECK(fx.audio.active_voices().size() == 0);
        // The pool held at most 64 voices all along: the plays past that stole or were refused, and every one is counted.
        CHECK(stat(st, "voicesStolen") + stat(st, "voicesRejected") > 0);
    }
    jobs::stop();
}
