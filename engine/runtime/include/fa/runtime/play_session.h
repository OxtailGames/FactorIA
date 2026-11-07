// Play sessions: what the editor records while the user plays (Play .. Stop) so an AI can see what happened.
//
// A session is the folder .factoria/sessions/<yyyymmdd-hhmmss>/ with session.json (perf, spikes, warnings/errors, marks),
// input.json (the input replay: the format `factoria run --headless --input` reads) and the mark screenshots.
// Everything here is pure data + file reading; the recording itself is the engine's (Engine::start_input_recording / the input.record command). The commands play.sessions
// and play.report are registered with the other built-in commands.
//
// A session from play.auto (fa/runtime/play_auto.h) has the same files plus "source": "auto", the phases, the score, how it ended
// and the bot's settings; the viewer of an editor session reads it unchanged.
#pragma once

#include <cstdint>
#include <ctime>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

inline constexpr const char* kPlaySessionsDir = ".factoria/sessions";

struct FrameStats {
    int count = 0;
    double avgMs = 0, p95Ms = 0, maxMs = 0;  // p95: nearest rank
    int over16 = 0, over33 = 0;              // frames slower than 16.7 ms / 33.3 ms
};
FrameStats compute_frame_stats(const std::vector<double>& frameMs);

struct PlaySpike {
    std::uint64_t frame = 0;  // frame number inside the session (same numbering as input.json)
    double ms = 0;
    int entities = 0;
    Json renderStats;  // Renderer stats at that frame (null when unknown)
};
// Keeps `spikes` sorted slowest first and at most `keep` long.
void keep_worst_spike(std::vector<PlaySpike>& spikes, PlaySpike spike, std::size_t keep = 10);

struct PlayMark {
    std::uint64_t frame = 0;
    double time = 0;         // seconds of game time (frame / fixedHz)
    std::string note;        // the user's one-line description (play.auto: what the bot found)
    std::string screenshot;  // file name inside the session folder ("" = none)
    std::string kind;        // play.auto: "stuck", "menu", "fall", "exception loop", "not finite" or "hook"; "" for a mark of the player
    std::int64_t step = -1;  // play.auto: the fixed step the problem was found at (-1 = not recorded)
};

// A stage of an automatic run: the scene it started in, or a game.phase(name) mark.
struct PlayPhase {
    std::string name;        // the scene path, or the name given to game.phase
    std::string kind;        // "scene" or "mark"
    std::string scene;       // the scene that was running
    std::uint64_t frame = 0;
    double time = 0;         // game seconds from the start of the run
    std::string screenshot;  // file name inside the session folder ("" = none)
};

struct PlaySession {
    std::string name;   // folder name
    std::string scene;
    double durationSec = 0;
    std::uint64_t frames = 0;
    double fixedHz = 60;
    FrameStats perf;
    std::vector<PlaySpike> spikes;
    Json logs = Json::array();  // warnings and errors: {seq, frame, level, category, message}
    std::vector<PlayMark> marks;
    Json input = Json::object();  // {"frames": {"<n>": {...}}}
    Json profile;                 // the profiler's summary of the session (ProfileSummary::to_json); null = not measured
    // ---- play.auto only (source "auto"); an editor session leaves them empty and session.json does not carry them
    std::string source;                // "" = a person played in the editor; "auto" = play.auto
    std::vector<PlayPhase> phases;
    Json score;                        // the last score the bot reported (null = none)
    std::string ended;                 // "won", "lost", "timeout", "stuck", "broken", "quit" or "aborted"
    std::string endedWhy;              // one sentence: what ended the run
    std::string endScreenshot;         // file name of the picture taken when the run ended ("" = none)
    Json notes = Json::array();        // things the reader must know: no GPU so no pictures, a cap that was reached...
    Json scriptErrors = Json::array(); // the script errors of the run (distinct ones), as text
    Json autoInfo;                     // the bot's settings and the replay command: seed, speed, bot, stuckSeconds, replay...
};
Json play_session_json(const PlaySession& s);                                   // the content of session.json
Result<void> write_play_session(const std::string& dir, const PlaySession& s);  // session.json + input.json
std::string play_session_name(std::time_t t);                                   // "20260131-142500" (local time)
// Folder names of the sessions under kPlaySessionsDir that have a session.json, newest first.
std::vector<std::string> play_session_names();
// True for a name play.auto gave ("20260131-142500-auto", "...-auto-2"): the sessions a person recorded never end that way.
bool is_auto_play_session_name(std::string_view name);
// Deletes the oldest automatic sessions (folders and all) so that at most `keep` remain; the sessions a person recorded are never
// touched. A folder that cannot be deleted (a file open on Windows) stays and is not counted as deleted. `spare` is a session that
// is never deleted and is counted first among the `keep` that stay (the one just written, whatever its name sorts as): with a
// `spare`, `keep` - 1 others remain. Returns how many it deleted.
// play.auto calls it once its session is written, so a reviewer that plays again and again cannot fill the disk (kPlayAutoKeepSessions).
int prune_auto_play_sessions(std::size_t keep, std::string_view spare = {});
// Typed reads of a session.json that a person may have edited: the member when `o` is an object and the member has that type, `def`
// otherwise. (Json::value throws when the member is there with another type.) The editor reads sessions on its UI thread with these.
std::string session_text(const Json& o, const char* key, const std::string& def = {});
double session_number(const Json& o, const char* key, double def = 0);
// One short paragraph about a session.json: perf, errors, marks with notes. Used by the AI panel.
std::string play_session_summary(const Json& sessionJson);

}  // namespace fa
