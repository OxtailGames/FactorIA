// Play sessions: what the editor records while the user plays (Play .. Stop) so an AI can see what happened.
//
// A session is the folder .factoria/sessions/<yyyymmdd-hhmmss>/ with session.json (perf, spikes, warnings/errors, marks),
// input.json (the input replay: the format `factoria run --headless --input` reads) and the mark screenshots.
// Everything here is pure data + file reading; the editor (tools/editor) does the recording. The commands play.sessions
// and play.report are registered with the other built-in commands.
#pragma once

#include <cstdint>
#include <ctime>
#include <string>
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
    std::string note;        // the user's one-line description
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
};
Json play_session_json(const PlaySession& s);                                   // the content of session.json
Result<void> write_play_session(const std::string& dir, const PlaySession& s);  // session.json + input.json
std::string play_session_name(std::time_t t);                                   // "20260131-142500" (local time)
// Folder names of the sessions under kPlaySessionsDir that have a session.json, newest first.
std::vector<std::string> play_session_names();
// One short paragraph about a session.json: perf, errors, marks with notes. Used by the AI panel.
std::string play_session_summary(const Json& sessionJson);

}  // namespace fa
