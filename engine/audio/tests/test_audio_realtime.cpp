// The mixer behind the audio callback allocates nothing once it is built: the per-block scratch (used / live / ducking flags,
// bus buffers, ducking gains) is made when the bus table is, on the game thread, and handed over in a command. The null
// device applies the commands and mixes with the same functions the device callback calls (Mixer::apply_commands,
// mix_block), on the calling thread, so the allocations of this thread while it runs are the callback's plus the game
// side's, which must make none either while voices play and end. test_audio_threads.cpp counts the device callback alone.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <vector>

#include "alloc_counter.h"
#include "audio_test_helpers.h"
#include "fa/audio/audio.h"

using namespace fa;
using namespace audio_test;

namespace {

PlayParams on(const char* bus, bool loop = true, bool notify = false) {
    PlayParams p;
    p.bus = bus;
    p.loop = loop;
    p.notifyEnd = notify;
    return p;
}

// Mixes `seconds` in 1/60 s steps and returns the allocations this thread made meanwhile.
std::size_t allocations_while_mixing(Fixture& fx, double seconds) {
    AllocCounter::Scope scope;
    fx.run(seconds);
    return scope.count();
}

}  // namespace

TEST_CASE("audio callback: the counter sees this thread's allocations and only while a scope is alive") {
    {
        AllocCounter::Scope scope;
        void* p = AllocCounter::allocate_for_test(16);
        CHECK(scope.count() == 1);
        {
            AllocCounter::Scope inner;
            AllocCounter::release_for_test(AllocCounter::allocate_for_test(8));
            CHECK(inner.count() == 1);
        }
        CHECK(scope.count() == 2);  // the inner scope's allocation is also the outer one's
        AllocCounter::release_for_test(p);
    }
    AllocCounter::release_for_test(AllocCounter::allocate_for_test(8));  // outside a scope: not counted
    AllocCounter::Scope scope;
    CHECK(scope.count() == 0);
}

TEST_CASE("audio callback: mixing voices on several buses with effects and ducking allocates nothing") {
    Fixture fx;
    fx.write_assets(
        R"({"format": "factoria.assets/1", "assets": {"sounds/streamed.wav": {"import": {"stream": "always"}}}})");
    std::vector<float> st;  // 22050 Hz stereo, 1.5 s: the resampler works while it streams
    for (int i = 0; i < 33075; ++i) {
        st.push_back(0.3f * std::sin(0.05f * float(i)));
        st.push_back(0.3f * std::sin(0.031f * float(i)));
    }
    write_file(fx.dir / "sounds/streamed.wav", wav_bytes(st, 2, 22050));
    write_sine_wav(fx.dir / "sounds/short.wav", 0.6, 600.0, 0.5);
    write_sine_wav(fx.dir / "sounds/hi.wav", 1.0, 3000.0, 0.4);

    fx.audio.set_buses({{"ambience", "sfx"}, {"birds", "ambience"}, {"voiceover", "master"}});
    REQUIRE(fx.audio.set_bus_lowpass("sfx", 2000.0f, 0.5f).ok());  // the cutoff slides while the blocks are mixed
    REQUIRE(fx.audio.set_bus_reverb("ambience", 0.3f).ok());
    DuckSettings duck;
    duck.by = "voiceover";
    duck.amount = 0.8f;
    duck.attack = 0.01f;
    duck.release = 0.05f;
    REQUIRE(fx.audio.set_bus_duck("music", duck).ok());
    REQUIRE(fx.audio.set_bus_duck("ui", duck).ok());
    fx.audio.set_bus_volume("birds", 0.5f, 0.5f);

    fx.audio.play("sounds/sine.wav", on("sfx"));
    fx.audio.play("sounds/hi.wav", on("birds"));
    fx.audio.play("sounds/streamed.wav", on("ambience"));
    fx.audio.play("sounds/sine.wav", on("music"));
    fx.audio.play("sounds/hi.wav", on("ui"));
    const VoiceId ended = fx.audio.play("sounds/short.wav", on("ui", false, true));
    REQUIRE(ended != 0);
    const VoiceId pcm = fx.audio.open_pcm_voice(22050, on("sfx"), "video.mp4", "1");
    REQUIRE(pcm != 0);
    fx.audio.push_pcm(pcm, st.data(), 22050);

    fx.run(0.2);  // warm-up: whatever the first blocks set up lazily
    CHECK(fx.audio.take_ended_voices()
              .empty());  // a game takes them every frame: it must not cost the mixer its capacity

    // The voiceover starts after the warm-up, so the ducking attacks, holds and releases inside the counted blocks.
    const VoiceId vo = fx.audio.play("sounds/short.wav", on("voiceover", false, true));
    REQUIRE(vo != 0);
    const std::size_t n = allocations_while_mixing(fx, 1.5);
    CHECK_MESSAGE(n == 0, "the mixer allocated " << n << " times while mixing 90 steps");

    std::vector<VoiceId> done = fx.audio.take_ended_voices();  // both short voices ended inside the counted blocks
    CHECK(std::find(done.begin(), done.end(), ended) != done.end());
    CHECK(std::find(done.begin(), done.end(), vo) != done.end());
}

TEST_CASE("audio callback: a changed bus table is ready before the next block") {
    Fixture fx;
    fx.audio.set_buses({{"ambience", "sfx"}});
    REQUIRE(fx.audio.set_bus_reverb("ambience", 0.3f).ok());
    fx.audio.play("sounds/sine.wav", on("ambience"));
    fx.audio.play("sounds/sine.wav", on("music"));
    fx.run(0.2);
    // More buses, one of them ducked by another: the scratch for the new table is made by set_buses, not by the next block.
    fx.audio.set_buses({{"ambience", "sfx"}, {"birds", "ambience"}, {"voiceover", "master"}, {"fx2", "birds"}});
    DuckSettings duck;
    duck.by = "voiceover";
    duck.amount = 0.5f;
    REQUIRE(fx.audio.set_bus_duck("music", duck).ok());
    fx.audio.play("sounds/sine.wav", on("voiceover"));
    fx.audio.play("sounds/sine.wav", on("fx2"));
    const std::size_t n = allocations_while_mixing(fx, 0.5);
    CHECK_MESSAGE(n == 0, "the mixer allocated " << n << " times after the bus table changed");
}
