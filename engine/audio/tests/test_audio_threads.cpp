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
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

#include "../src/audio_rings.h"
#include "../src/audio_testing.h"
#include "alloc_counter.h"
#include "audio_test_helpers.h"
#include "fa/audio/audio.h"
#include "fa/core/jobs.h"
#include "fa/core/json.h"
#include "fa/core/log.h"
#include "fa/scene/components.h"
#include "fa/scene/world.h"

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
    JobPool pool(jobs::Settings::threads(2));  // the stream refills run on workers; stopped when the test ends, however it ends
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
        // Let the callback take the stops and hand back the ended voices. active_voices() skips a voice the game already
        // stopped, so it is zero at once and proves nothing: the mirror empties only when the mixer says each voice ended
        // (a safety net of 30 s, far above the few blocks needed, so a slow CI machine does not fail).
        const auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(30);
        while (std::chrono::steady_clock::now() < deadline) {
            fx.audio.service();
            if (AudioTestAccess::mirror_voices(fx.audio) == 0) break;
            std::this_thread::sleep_for(std::chrono::milliseconds(2));
        }
        stopMixing.store(true, std::memory_order_release);
        callback.join();
        CHECK_MESSAGE(AudioTestAccess::mirror_voices(fx.audio) == 0, "the mixer did not acknowledge the end of every voice");

        const Json st = fx.audio.stats();
        CHECK(stat(st, "activeVoices") == 0);
        CHECK(stat(st, "commandsDropped") == 0);
        CHECK(stat(st, "settingsDropped") == 0);
        CHECK(fx.audio.active_voices().size() == 0);
        // The pool held at most 64 voices all along: the plays past that stole or were refused, and every one is counted.
        CHECK(stat(st, "voicesStolen") + stat(st, "voicesRejected") > 0);
    }
}

namespace {

// Settings of the "ui" bus: junk that fills the mixer's ring (2048) and then the staging queue while a test's device stalls.
void send_settings(Audio& audio, int count) {
    for (int i = 0; i < count; ++i) audio.set_bus_volume("ui", 0.5f + 0.0001f * float(i % 100), 0.0f);
}

// The device is back: render and pump until the staging queue is empty and the mixer has taken everything (a count of
// blocks, never a time).
void resume_device(Audio& audio, int extraBlocks = 8) {
    for (int i = 0; i < 200; ++i) {
        render_blocks(audio, 1);
        AudioTestAccess::pump(audio);
        if (i > 8 && AudioTestAccess::staged_commands(audio) == 0) break;
    }
    render_blocks(audio, extraBlocks);
    AudioTestAccess::pump(audio);
    render_blocks(audio, 2);
}

}  // namespace

TEST_CASE("audio callback: settings dropped while the device stalls are sent again and the mixer converges") {
    // The same final state reached without a stall: what the mixer must end up with.
    float expected = 0.0f;
    {
        Fixture ref;
        AudioTestAccess::use_manual_device(ref.audio, 48000);
        const VoiceId v = ref.audio.play("sounds/sine.wav", on("sfx"));
        ref.audio.set_bus_volume("sfx", 0.25f, 0.0f);
        ref.audio.set_voice_volume(v, 0.5f, 0.0f);
        render_blocks(ref.audio, 4);
        expected = render_blocks(ref.audio, 8);
        REQUIRE(expected > 0.01f);
    }

    Fixture fx;
    AudioTestAccess::use_manual_device(fx.audio, 48000);
    const VoiceId v = fx.audio.play("sounds/sine.wav", on("sfx"));
    REQUIRE(v != 0);
    render_blocks(fx.audio, 2);
    AudioTestAccess::pump(fx.audio);
    // The device stops taking commands. The ring fills, then the two settings wait in the staging queue, and 9000 more
    // settings of another bus push them out of it (8192 staged): the voice's volume goes first (a Droppable), then the
    // oldest bus settings.
    send_settings(fx.audio, 2100);
    fx.audio.set_bus_volume("sfx", 0.25f, 0.0f);
    fx.audio.set_voice_volume(v, 0.5f, 0.0f);
    send_settings(fx.audio, 9000);
    const Json stalled = fx.audio.stats();
    CHECK(stat(stalled, "commandsDropped") >= 1);  // the voice's volume
    CHECK(stat(stalled, "settingsDropped") >= 1);  // the bus volume
    CHECK(AudioTestAccess::staged_commands(fx.audio) <= 8192);

    resume_device(fx.audio);
    CHECK(AudioTestAccess::staged_commands(fx.audio) == 0);
    // Without the resend the bus would sit at 1.0 and the voice at 1.0: four times as loud.
    CHECK(render_blocks(fx.audio, 8) == doctest::Approx(expected).epsilon(0.02));
    CHECK(fx.audio.is_playing(v));
}

TEST_CASE("audio callback: a stall does not pile up repeated fades, pauses and effect resets, and no stop is lost") {
    Fixture fx;
    AudioTestAccess::use_manual_device(fx.audio, 48000);
    const VoiceId kept = fx.audio.play("sounds/sine.wav", on("sfx"));
    const VoiceId stopped = fx.audio.play("sounds/sine.wav", on("sfx"));
    fx.audio.play_music("sounds/sine.wav", 1.0f, 0.0f);
    REQUIRE(kept != 0);
    REQUIRE(stopped != 0);
    render_blocks(fx.audio, 2);
    AudioTestAccess::pump(fx.audio);
    REQUIRE(AudioTestAccess::mirror_voices(fx.audio) == 3);
    send_settings(fx.audio, 2048 + 1500);  // the ring is full and 1500 settings wait: past the point where Keeps are merged
    const std::size_t before = AudioTestAccess::staged_commands(fx.audio);
    REQUIRE(before >= 1024);
    fx.audio.stop(stopped);  // a stop: never dropped, never merged
    // What a game that keeps calling these every frame sends: 3 x 2000 commands that each make the one before useless.
    for (int i = 0; i < 2000; ++i) {
        fx.audio.play_music("sounds/sine.wav", 1.0f, 0.0f);  // the same track again: a retune of the playing voice
        fx.audio.set_paused(i % 2 == 0);
        fx.audio.reset_bus_effects();
    }
    fx.audio.set_paused(false);
    fx.audio.stop_music(1.0f);
    const Json st = fx.audio.stats();
    CHECK(AudioTestAccess::staged_commands(fx.audio) <= before + 8);  // the stop and one of each
    CHECK(stat(st, "commandsCoalesced") >= 5900);
    CHECK(stat(st, "commandsDropped") == 0);
    CHECK(stat(st, "settingsDropped") == 0);

    // The device is back: the stop arrived, the last pause state (not paused) too, so the music fades out in one second.
    resume_device(fx.audio, 120);
    CHECK(AudioTestAccess::mirror_voices(fx.audio) == 1);
    CHECK(fx.audio.is_playing(kept));
    CHECK(render_blocks(fx.audio, 2) > 0.01f);
}

TEST_CASE("audio callback: a stall merges repeated stops of everything") {
    Fixture fx;
    AudioTestAccess::use_manual_device(fx.audio, 48000);
    const VoiceId v = fx.audio.play("sounds/sine.wav", on("sfx"));
    REQUIRE(v != 0);
    render_blocks(fx.audio, 2);
    AudioTestAccess::pump(fx.audio);
    send_settings(fx.audio, 2048 + 1500);
    const std::size_t before = AudioTestAccess::staged_commands(fx.audio);
    for (int i = 0; i < 1000; ++i) fx.audio.stop_all();
    CHECK(AudioTestAccess::staged_commands(fx.audio) <= before + 1);
    CHECK(stat(fx.audio.stats(), "commandsCoalesced") >= 990);
    resume_device(fx.audio);
    CHECK(AudioTestAccess::mirror_voices(fx.audio) == 0);  // the one that stays still ends everything
}

// ---- a dropped setting is sent again, whatever it was (counted blocks and commands, never a time) ------------------------------

namespace {

// The loudest sample of a voice that plays at the volume the reference got without any stall.
template <class Setup>
float reference_peak(Setup setup) {
    Fixture ref;
    AudioTestAccess::use_manual_device(ref.audio, 48000);
    setup(ref.audio);
    render_blocks(ref.audio, 4);
    const float peak = render_blocks(ref.audio, 8);
    REQUIRE(peak > 0.01f);
    return peak;
}

// Fills the mixer's ring and the staging queue past its limit with settings of the "ui" bus, so the commands sent after the
// first 2100 of them (and before the 9000 more) are the oldest of their kind when the queue overflows.
struct Stall {
    Audio& audio;
    explicit Stall(Audio& a) : audio(a) { send_settings(audio, 2100); }
    void overflow() {
        send_settings(audio, 9000);
        const Json st = audio.stats();
        CHECK(stat(st, "commandsDropped") + stat(st, "settingsDropped") >= 1);
        CHECK(AudioTestAccess::staged_commands(audio) <= 8192);
    }
};

}  // namespace

TEST_CASE("audio callback: a bus setting dropped before a bus table swap is sent to the same bus after it") {
    const std::vector<AudioBusDef> ab{{"a", "master"}, {"b", "master"}};
    const std::vector<AudioBusDef> ba{{"b", "master"}, {"a", "master"}};  // the indexes of the two buses trade places
    const float expected = reference_peak([&](Audio& audio) {
        audio.set_buses(ab);
        audio.play("sounds/sine.wav", on("b"));
        audio.set_bus_volume("b", 0.25f, 0.0f);
        audio.set_buses(ba);
    });

    Fixture fx;
    AudioTestAccess::use_manual_device(fx.audio, 48000);
    fx.audio.set_buses(ab);
    const VoiceId v = fx.audio.play("sounds/sine.wav", on("b"));
    REQUIRE(v != 0);
    render_blocks(fx.audio, 2);
    AudioTestAccess::pump(fx.audio);
    Stall stall(fx.audio);
    fx.audio.set_bus_volume("b", 0.25f, 0.0f);
    fx.audio.set_buses(ba);  // a table swap is never dropped
    stall.overflow();
    CHECK(stat(fx.audio.stats(), "settingsDropped") >= 1);

    resume_device(fx.audio);
    CHECK(AudioTestAccess::staged_commands(fx.audio) == 0);
    // Resent by index the volume would reach "a" (the bus that has that index now) and "b" would stay at 1.0.
    CHECK(render_blocks(fx.audio, 8) == doctest::Approx(expected).epsilon(0.02));
    CHECK(fx.audio.bus_state("b")["volume"].get<float>() == doctest::Approx(0.25f));
    CHECK(fx.audio.bus_state("a")["volume"].get<float>() == doctest::Approx(1.0f));
}

TEST_CASE("audio callback: a bus setting dropped for a bus that a table swap removed is skipped") {
    Fixture fx;
    AudioTestAccess::use_manual_device(fx.audio, 48000);
    fx.audio.set_buses({{"a", "master"}, {"b", "master"}});
    const VoiceId v = fx.audio.play("sounds/sine.wav", on("sfx"));
    REQUIRE(v != 0);
    render_blocks(fx.audio, 2);
    AudioTestAccess::pump(fx.audio);
    Stall stall(fx.audio);
    fx.audio.set_bus_volume("b", 0.25f, 0.0f);
    fx.audio.set_buses({{"a", "master"}});  // "b" is gone
    stall.overflow();
    resume_device(fx.audio);
    CHECK(AudioTestAccess::staged_commands(fx.audio) == 0);
    CHECK(fx.audio.bus_state("b").is_null());
    CHECK(fx.audio.is_playing(v));
    CHECK(render_blocks(fx.audio, 4) > 0.01f);
}

TEST_CASE("audio callback: a snapshot dropped while the device stalls is applied again to every bus") {
    AudioSnapshots catalog;
    AudioSnapshot quiet;
    quiet.fade = 0.0f;
    quiet.buses["sfx"].volume = 0.25f;
    catalog["quiet"] = quiet;
    const float expected = reference_peak([&](Audio& audio) {
        audio.set_snapshots(catalog);
        audio.play("sounds/sine.wav", on("sfx"));
        REQUIRE(audio.apply_snapshot("quiet", 0.0f).ok());
    });

    Fixture fx;
    AudioTestAccess::use_manual_device(fx.audio, 48000);
    fx.audio.set_snapshots(catalog);
    const VoiceId v = fx.audio.play("sounds/sine.wav", on("sfx"));
    REQUIRE(v != 0);
    render_blocks(fx.audio, 2);
    AudioTestAccess::pump(fx.audio);
    Stall stall(fx.audio);
    REQUIRE(fx.audio.apply_snapshot("quiet", 0.0f).ok());
    stall.overflow();
    CHECK(stat(fx.audio.stats(), "settingsDropped") >= 1);

    resume_device(fx.audio);
    CHECK(AudioTestAccess::staged_commands(fx.audio) == 0);
    CHECK(render_blocks(fx.audio, 8) == doctest::Approx(expected).epsilon(0.02));
    CHECK(fx.audio.current_snapshot() == "quiet");
}

TEST_CASE("audio callback: a voice's bus dropped while the device stalls is sent again") {
    const float expected = reference_peak([&](Audio& audio) {
        audio.set_bus_volume("music", 0.25f, 0.0f);
        const VoiceId v = audio.play("sounds/sine.wav", on("sfx"));
        audio.set_voice_bus(v, "music");
    });

    Fixture fx;
    AudioTestAccess::use_manual_device(fx.audio, 48000);
    fx.audio.set_bus_volume("music", 0.25f, 0.0f);
    const VoiceId v = fx.audio.play("sounds/sine.wav", on("sfx"));
    REQUIRE(v != 0);
    render_blocks(fx.audio, 2);
    AudioTestAccess::pump(fx.audio);
    Stall stall(fx.audio);
    fx.audio.set_voice_bus(v, "music");
    stall.overflow();
    CHECK(stat(fx.audio.stats(), "commandsDropped") >= 1);

    resume_device(fx.audio);
    CHECK(AudioTestAccess::staged_commands(fx.audio) == 0);
    // Still on "sfx" in the mixer it would be four times as loud.
    CHECK(render_blocks(fx.audio, 8) == doctest::Approx(expected).epsilon(0.02));
}

TEST_CASE("audio callback: the parameters an AudioSource sent while the device stalled are sent again") {
    auto make_source = [](World& world, float volume) {
        Entity e = world.create("src", "src");
        AudioSource& s = world.add<AudioSource>(e);
        s.clip = "sounds/sine.wav";
        s.loop = true;
        s.playOnStart = true;
        s.volume = volume;
        return e;
    };
    float expected = 0.0f;
    {
        Fixture ref;
        AudioTestAccess::use_manual_device(ref.audio, 48000);
        World world;
        make_source(world, 0.25f);
        ref.audio.update(world, 1.0f / 60.0f);
        render_blocks(ref.audio, 4);
        expected = render_blocks(ref.audio, 8);
        REQUIRE(expected > 0.01f);
    }

    Fixture fx;
    AudioTestAccess::use_manual_device(fx.audio, 48000);
    World world;
    const Entity e = make_source(world, 1.0f);
    fx.audio.update(world, 1.0f / 60.0f);
    render_blocks(fx.audio, 2);
    AudioTestAccess::pump(fx.audio);
    REQUIRE(AudioTestAccess::mirror_voices(fx.audio) == 1);
    Stall stall(fx.audio);
    world.get<AudioSource>(e)->volume = 0.25f;
    fx.audio.update(world, 1.0f / 60.0f);  // send_params, a Droppable
    stall.overflow();
    CHECK(stat(fx.audio.stats(), "commandsDropped") >= 1);

    resume_device(fx.audio);
    CHECK(AudioTestAccess::staged_commands(fx.audio) == 0);
    CHECK(render_blocks(fx.audio, 8) == doctest::Approx(expected).epsilon(0.02));
    CHECK(world.get<AudioSource>(e)->playing);
}

TEST_CASE("audio callback: a queue of commands that must stay is kept whole, warns once and drains when the device is back") {
    struct Lines {
        std::mutex mu;
        std::vector<std::string> warnings;
    };
    auto lines = std::make_shared<Lines>();
    const int sink = add_log_sink([lines](const LogEntry& e) {
        if (e.level != LogLevel::Warn || e.category != "audio") return;
        std::lock_guard<std::mutex> lk(lines->mu);
        lines->warnings.push_back(e.message);
    });

    Fixture fx;
    AudioTestAccess::use_manual_device(fx.audio, 48000);
    // 36000 stops and removals: 2048 in the ring, the rest staged, past the 32768 where the game is told.
    AudioTestAccess::stage_keeps(fx.audio, 36000);
    AudioTestAccess::stage_keeps(fx.audio, 200);  // more of them: still one line
    const std::size_t staged = AudioTestAccess::staged_commands(fx.audio);
    CHECK(staged > 32768);
    const Json st = fx.audio.stats();
    CHECK(stat(st, "commandsDropped") == 0);  // none of them is droppable
    CHECK(stat(st, "settingsDropped") == 0);
    resume_device(fx.audio);
    remove_log_sink(sink);

    CHECK(AudioTestAccess::staged_commands(fx.audio) == 0);
    std::lock_guard<std::mutex> lk(lines->mu);
    int kept = 0;
    for (const std::string& w : lines->warnings)
        if (w.find("they are all kept") != std::string::npos) ++kept;
    CHECK(kept == 1);
}
