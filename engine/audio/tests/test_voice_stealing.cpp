// Voice stealing (docs/SOUND.md, "Voice stealing"): with all 64 voices taken, a new sound replaces the voice of the lowest
// priority, the quietest of those, when its own priority is higher or the same and it is louder; otherwise it does not
// play. How long a voice has played never decides.
#include <doctest.h>

#include <algorithm>
#include <cstdint>
#include <vector>

#include "audio_test_helpers.h"
#include "fa/audio/audio.h"
#include "fa/core/json.h"

using namespace fa;
using namespace audio_test;

namespace {

constexpr int kPool = 64;

PlayParams looped(float volume, int priority = 128, const char* bus = "sfx") {
    PlayParams p;
    p.loop = true;
    p.notifyEnd = true;
    p.volume = volume;
    p.priority = priority;
    p.bus = bus;
    return p;
}

std::uint64_t stat(Audio& audio, const char* key) { return audio.stats().at(key).get<std::uint64_t>(); }

bool ended(Audio& audio, VoiceId v) {
    const std::vector<VoiceId> done = audio.take_ended_voices();
    return std::find(done.begin(), done.end(), v) != done.end();
}

}  // namespace

TEST_CASE("voice stealing: a full pool gives up its lowest priority, quietest voice, never the oldest one") {
    Fixture fx;
    std::vector<VoiceId> ids;
    for (int i = 0; i < kPool; ++i) {
        ids.push_back(fx.audio.play("sounds/sine.wav", looped(i == 10 ? 0.1f : 0.5f)));
        REQUIRE(ids.back() != 0);
    }
    fx.run(0.1);
    CHECK(stat(fx.audio, "activeVoices") == kPool);
    CHECK(stat(fx.audio, "voicesStolen") == 0);

    // A higher priority wins even when it is quieter: it takes the quietest voice of priority 128, not the first started.
    const VoiceId alarm = fx.audio.play("sounds/sine.wav", looped(0.05f, 200));
    CHECK(alarm != 0);
    CHECK_FALSE(fx.audio.is_playing(ids[10]));
    CHECK(fx.audio.is_playing(ids[0]));
    CHECK(ended(fx.audio, ids[10]));  // a stolen voice ends like any other: take_ended_voices reports it
    CHECK(stat(fx.audio, "voicesStolen") == 1);
    CHECK(stat(fx.audio, "activeVoices") == kPool);

    // The same priority and louder: it takes the quietest voice of the lowest priority; between equals, the first started.
    const VoiceId loud = fx.audio.play("sounds/sine.wav", looped(0.9f));
    CHECK(loud != 0);
    CHECK_FALSE(fx.audio.is_playing(ids[0]));
    CHECK(fx.audio.is_playing(alarm));  // the quietest voice of all, but its priority keeps it
    CHECK(stat(fx.audio, "voicesStolen") == 2);

    // The same priority and no louder: the new sound does not play, and nothing is stopped.
    CHECK(fx.audio.play("sounds/sine.wav", looped(0.5f)) == 0);
    CHECK(fx.audio.is_playing(ids[1]));
    CHECK(stat(fx.audio, "voicesRejected") == 1);
    // A lower priority never takes a voice, however loud.
    CHECK(fx.audio.play("sounds/sine.wav", looped(2.0f, 10)) == 0);
    CHECK(stat(fx.audio, "voicesRejected") == 2);
    CHECK(stat(fx.audio, "voicesStolen") == 2);
    CHECK(stat(fx.audio, "activeVoices") == kPool);

    // The play log keeps the refused plays: ok (the clip is fine) with voice 0.
    std::size_t refused = 0;
    for (const AudioEvent& ev : fx.audio.play_log())
        if (ev.kind == "play" && ev.ok && ev.voice == 0) ++refused;
    CHECK(refused == 2);

    // A voice that is stopped frees its place: the next sound needs no stealing.
    fx.audio.stop(ids[5]);
    CHECK(fx.audio.play("sounds/sine.wav", looped(0.01f, 0)) != 0);
    CHECK(stat(fx.audio, "voicesStolen") == 2);
    fx.run(0.1);
    CHECK(stat(fx.audio, "activeVoices") == kPool);
}

TEST_CASE("voice stealing: loudness counts the clip's bus chain, so a voice turned down by its bus goes first") {
    Fixture fx;
    fx.audio.set_buses({{"ambience", "sfx"}});
    std::vector<VoiceId> ids;
    for (int i = 0; i < kPool; ++i) {
        ids.push_back(fx.audio.play("sounds/sine.wav", looped(0.5f, 128, i == 30 ? "ambience" : "sfx")));
        REQUIRE(ids.back() != 0);
    }
    fx.audio.set_bus_volume("ambience", 0.1f);  // 0.5 x 0.1 x the sfx bus: the quietest voice now
    const VoiceId v = fx.audio.play("sounds/sine.wav", looped(0.5f));
    CHECK(v != 0);
    CHECK_FALSE(fx.audio.is_playing(ids[30]));
    CHECK(fx.audio.is_playing(ids[0]));
    fx.run(0.1);
    CHECK(stat(fx.audio, "activeVoices") == kPool);
}

TEST_CASE("voice stealing: music outranks every sound a game can play") {
    Fixture fx;
    for (int i = 0; i < kPool; ++i) REQUIRE(fx.audio.play("sounds/sine.wav", looped(1.0f, 255)) != 0);
    auto music_plays = [&] {
        for (const Json& v : fx.audio.active_voices())
            if (v.at("music").get<bool>()) return true;
        return false;
    };
    fx.audio.play_music("sounds/sine.wav", 0.6f, 0.0f);
    fx.run(0.1);
    CHECK(music_plays());
    CHECK(stat(fx.audio, "voicesStolen") == 1);
    // A louder sound of the highest priority takes a sound's voice, never the music's.
    CHECK(fx.audio.play("sounds/sine.wav", looped(4.0f, 255)) != 0);
    CHECK(stat(fx.audio, "voicesStolen") == 2);
    fx.run(0.1);
    CHECK(music_plays());
    CHECK(stat(fx.audio, "activeVoices") == kPool);
}
