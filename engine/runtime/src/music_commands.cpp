// The commands that look at and drive the MusicPlayer components (M56.4): audio.music_state (what every player is doing: section,
// bar, beat, layers, pending changes) and audio.music (play, stop, setIntensity, goToSection, playStinger, crossfadeTo: what
// `entity.music` does in a script). The sound is the mixer's: these commands only ask.
#include <format>

#include "engine_impl.h"
#include "fa/core/strings.h"

namespace fa {

namespace {

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

Entity player_of(Engine::Impl& I, const Json& a, const char* command) {
    const Entity e = need_entity(I.world, a, "entity");
    if (!I.world.get<MusicPlayer>(e))
        throw CommandError("invalid_argument", std::format("{}: '{}' has no MusicPlayer.", command, I.world.id_of(e)),
                           "Add one: scene.set_component {id, component: \"MusicPlayer\", fields: {song: "
                           "\"music/theme.song.json\"}}.");
    return e;
}

std::optional<MusicQuantize> quantize_arg(const Json& a, const char* key = "quantize") {
    if (!a.contains(key) || a[key].is_null()) return std::nullopt;
    const std::string name = a[key].is_string() ? a[key].get<std::string>() : std::string();
    auto q = music_quantize_from_name(name);
    if (!q)
        throw CommandError("invalid_argument", std::format("Unknown quantize '{}'.", name),
                           "Use \"none\" (now), \"beat\", \"bar\" or \"section\" (when the section pass ends).");
    return q;
}

void need_ok(const Result<void>& r, const char* command) {
    if (!r.ok())
        throw CommandError("invalid_argument", std::format("{}: {}", command, r.error().message), r.error().hint);
}

template <class T>
const T& need_value(const Result<T>& r, const char* command) {
    if (!r.ok())
        throw CommandError("invalid_argument", std::format("{}: {}", command, r.error().message), r.error().hint);
    return *r;
}

}  // namespace

void register_music_commands(Engine&, Engine::Impl& I) {
    I.commands.add(
        {"audio.music_state",
         "What the MusicPlayer components are doing: song, section, bar, beat, layers and pending changes.",
         "Without `entity`: every player, including one still fading out after a scene change, as {mixedFrames, "
         "players: "
         "[{entity, song, mode, ready, playing, ended, section, bar, beat, positionSeconds, tempo, intensity, "
         "appliedIntensity, requestedIntensity, volume, bus, stems, stemGains, pending, pendingSong, pendingSection, "
         "pendingAt, heads, error}]}. With `entity`: that player only (`exists: false` when it has none). `song` and "
         "`section` are what is audible now; `pendingSong`, `pendingSection` and `pendingAt` (the audio frame, as in "
         "the "
         "events' `frame`) say where the next queued section change or crossfade lands (null when none waits). While a "
         "crossfade's song is still loading, `pendingSong` is set and `pendingAt` is null; a song that failed to load "
         "shows in `error`, not as pending. `intensity` = `appliedIntensity` is the value the layers follow (it "
         "changes "
         "on the layerQuantize boundary), `requestedIntensity` the last one asked for (the component's). Example: "
         "audio.music_state {\"entity\":\"music\"}. The other fields and the music's memory: docs/MUSIC.md, \"What the "
         "music costs in memory\"." FA_COMMAND_DETAILS
         "`stemGains` is the gain each layer has now (it follows the intensity with the layer fade); `pending` counts "
         "the quantized changes waiting for their beat; `heads` is more than 1 while a section jump or crossfade is "
         "under way; `mixedFrames` is the musical clock (the frames the mixer has mixed). "
         "`cache` lists the songs the music cache holds, {song, mode, bytes, streamed, underruns, stems: [{name, "
         "bytes, "
         "streamed}]}, and `cacheBytes` adds them up, plus the sources a player still plays after the cache let go of "
         "them and the loads that finished but are not cached yet: this is the memory of the music (also `musicBytes` "
         "in "
         "game.state's audio and `musicMB` in perf.profile / perf.measure). A stem with `streamed: true` plays from "
         "its "
         "encoded ogg (in memory) through a small window of decoded chunks, so its `bytes` are that window plus the "
         "encoded file, not the whole song decoded; `streamed` of a song says any of its stems is, and `underruns` "
         "(per "
         "song, all its stems together) counts the blocks in which a window was not ready (that stem played silence).",
         parse_schema(R"({"type":"object","properties":{
               "entity":{"type":"string","description":"Only this entity (id or name); it needs a MusicPlayer."}}})"),
         true, "audio"},
        [&I](const Json& a) {
            Json out = Json::object({{"mixedFrames", I.audio.mixed_frames()}});
            if (a.contains("entity")) {
                const Entity e = player_of(I, a, "audio.music_state");
                Json st = I.audio.music_status(I.world, e).to_json();
                st["entity"] = I.world.id_of(e);
                out["players"] = Json::array({st});
            } else {
                out["players"] = I.audio.music_players();
            }
            out["cache"] = I.audio.music_cache_json();
            out["cacheBytes"] = I.audio.music_bytes();
            return out;
        });

    I.commands.add(
        {"audio.music", "Drive a MusicPlayer: play, stop, setIntensity, goToSection, playStinger or crossfadeTo.",
         "The same calls as `entity.music` in a script, for trying the music while the game runs (game.step, then "
         "audio.music_state). `action` picks the call and the other fields are its arguments: play {song?, section?, "
         "intensity?} starts at once; stop {quantize?, fade?} fades out on the boundary; setIntensity {intensity, "
         "quantize?} moves the layers; goToSection {section, quantize?, fade?} jumps on the boundary with a crossfade; "
         "playStinger {clip | section, quantize?, volume?, tail?, bus?, duck?, duckAttack?, duckHold?, duckRelease?} "
         "plays "
         "a short piece over the music; crossfadeTo {song, section?, quantize?, bars?} changes song on the boundary "
         "(from "
         "its beginning unless `section` is given). `quantize` is none, beat, bar or section; without it the player's "
         "own "
         "settings apply. A change that waits for a boundary is queued in the mixer (audio.music_state shows "
         "`pending`, "
         "`pendingSong`, `pendingSection` and `pendingAt`); setIntensity, goToSection and crossfadeTo answer `change`: "
         "{frame, time, quantize}, the audio frame it lands on (null before the song plays or while it loads). "
         "Example: "
         "audio.music {\"entity\":\"music\",\"action\":\"goToSection\",\"section\":\"battle\",\"quantize\":\"bar\"}. "
         "More: docs/MUSIC.md, \"Playing a song in a game\"." FA_COMMAND_DETAILS
         "The frame of setIntensity is a prediction: a stuck device may drop an intensity change (the engine sends the "
         "player's intensity again when the device recovers, to the layerQuantize boundary of that moment), so read "
         "audio.music_state for what applied.",
         parse_schema(R"({"type":"object","required":["entity","action"],"properties":{
               "entity":{"type":"string","description":"Entity with the MusicPlayer (id or name)."},
               "action":{"type":"string","enum":["play","stop","setIntensity","goToSection","playStinger","crossfadeTo"],
                         "description":"The call to make."},
               "song":{"type":"string","description":"play, crossfadeTo: the song (*.song.json). play without it uses the player's own."},
               "section":{"type":"string","description":"play, crossfadeTo: the section to start at. goToSection, playStinger: the section to go to or to play as a stinger."},
               "intensity":{"type":"number","minimum":0,"maximum":1,"description":"play, setIntensity: 0..1."},
               "quantize":{"type":"string","enum":["none","beat","bar","section"],"description":"When the change lands. Default: the player's quantize (layerQuantize for setIntensity)."},
               "fade":{"type":"number","minimum":0,"maximum":60,"description":"stop, goToSection: seconds of the fade. Default 0.3 for stop, the player's transitionFade for goToSection."},
               "bars":{"type":"number","minimum":0,"maximum":64,"description":"crossfadeTo: bars of the old song the crossfade lasts. Default: the player's crossfadeBars."},
               "clip":{"type":"string","description":"playStinger: an audio clip to play on the boundary."},
               "volume":{"type":"number","minimum":0,"maximum":4,"default":1,"description":"playStinger: volume on top of the player's."},
               "tail":{"type":"number","minimum":0,"maximum":30,"default":1.5,"description":"playStinger with a section: seconds of what rings after it ends."},
               "bus":{"type":"string","description":"playStinger with a clip: the bus (default the player's)."},
               "duck":{"type":"number","minimum":0,"maximum":1,"default":0,"description":"playStinger: how much the music dips while it plays (0 = not at all)."},
               "duckAttack":{"type":"number","minimum":0,"maximum":10,"default":0.05,"description":"playStinger: seconds to dip."},
               "duckHold":{"type":"number","maximum":60,"description":"playStinger: seconds the dip lasts; omitted: the length of the clip or section."},
               "duckRelease":{"type":"number","minimum":0,"maximum":30,"default":0.5,"description":"playStinger: seconds to come back."}}})"),
         false, "audio"},
        [&I](const Json& a) {
            const Entity e = player_of(I, a, "audio.music");
            const std::string action = a.value("action", std::string());
            const std::optional<MusicQuantize> q = quantize_arg(a);
            const float fade = a.contains("fade") ? a["fade"].get<float>() : -1.0f;
            const std::string section = a.value("section", std::string());
            Json change;  // setIntensity, goToSection, crossfadeTo: where the change lands
            if (action == "play") {
                need_ok(I.audio.music_play(I.world, e, a.value("song", std::string()), section,
                                           a.contains("intensity") ? a["intensity"].get<float>() : -1.0f),
                        "audio.music");
            } else if (action == "stop") {
                I.audio.music_stop(I.world, e, q.value_or(MusicQuantize::None), fade);
            } else if (action == "setIntensity") {
                if (!a.contains("intensity"))
                    throw CommandError("invalid_argument", "setIntensity needs `intensity`.",
                                       "Pass a number from 0 (calm) to 1 (full).");
                change = I.audio.music_set_intensity(I.world, e, a["intensity"].get<float>(), q).to_json();
            } else if (action == "goToSection") {
                if (section.empty())
                    throw CommandError("invalid_argument", "goToSection needs `section`.",
                                       "Pass a section name of the song (audio.music_state lists them).");
                change = need_value(I.audio.music_go_to_section(I.world, e, section, q, fade), "audio.music").to_json();
            } else if (action == "playStinger") {
                MusicStingerSpec s;
                s.clip = a.value("clip", std::string());
                s.section = section;
                s.quantize = q;
                s.volume = a.value("volume", 1.0f);
                s.tail = a.value("tail", 1.5f);
                s.bus = a.value("bus", std::string());
                s.duck = a.value("duck", 0.0f);
                s.duckAttack = a.value("duckAttack", 0.05f);
                s.duckHold = a.value("duckHold", -1.0f);
                s.duckRelease = a.value("duckRelease", 0.5f);
                need_ok(I.audio.music_play_stinger(I.world, e, s), "audio.music");
            } else if (action == "crossfadeTo") {
                const std::string song = a.value("song", std::string());
                if (song.empty())
                    throw CommandError("invalid_argument", "crossfadeTo needs `song`.",
                                       "Pass the path of a *.song.json, e.g. \"music/battle.song.json\".");
                change = need_value(I.audio.music_crossfade_to(I.world, e, song, section, q,
                                                               a.contains("bars") ? a["bars"].get<float>() : -1.0f),
                                    "audio.music")
                             .to_json();
            } else {
                throw CommandError("invalid_argument", std::format("Unknown action '{}'.", action),
                                   "Use play, stop, setIntensity, goToSection, playStinger or crossfadeTo.");
            }
            Json st = I.audio.music_status(I.world, e).to_json();
            st["entity"] = I.world.id_of(e);
            Json out = Json::object({{"ok", true}, {"action", action}, {"player", st}});
            if (!change.is_null()) out["change"] = std::move(change);
            return out;
        });

    // Capabilities (capability.h): what each command does outside the engine's memory.
    declare_command_capabilities(I.commands, {
                                                 {"audio.music_state", capability_sets::reads()},
                                                 {"audio.music", capability_sets::changes_state()},
                                             });
}

}  // namespace fa
