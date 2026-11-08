// The Play sessions window's data (View > Play Sessions, Play > Let the AI Play): the sessions under .factoria/sessions/ as rows,
// which one "Attach last play session" picks for the AI chat, and the text lines of a report. Plain logic over session.json
// (fa/runtime/play_session.h): no ImGui, no Editor; tests call it directly.
#pragma once

#include <string>
#include <vector>

#include "fa/core/json.h"

namespace fa::editor {

// One session.json as a list row. `isAuto`: written by play.auto (the bot played), not by a person pressing Play .. Stop.
struct PlaySessionRow {
    std::string name;     // folder name under .factoria/sessions/
    bool isAuto = false;
    std::string scene;
    double durationSec = 0;
    std::string ended;    // auto sessions: won | lost | timeout | stuck | broken | quit | aborted
    int marks = 0;        // the player's F9 marks, or the problems the bot found
    int logs = 0;         // warnings and errors logged while it ran
    std::string error;    // session.json could not be read: why ("" = fine)
};
inline constexpr std::size_t kPlaySessionRows = 30;  // the window lists the newest ones (a cap on the work, not on the folder)

// The row of one session.json (`name` is its folder).
PlaySessionRow play_session_row(const std::string& name, const Json& sessionJson);
// The newest `max` sessions of the project, newest first (reads their session.json files).
std::vector<PlaySessionRow> read_play_sessions(std::size_t max = kPlaySessionRows);

// Which session "Attach last play session" puts in the AI chat. A person who presses it means their own play: the newest session
// they played, and only when there is none the newest automatic one, which `fellBack` marks so the caller says so. nullptr
// when there are no sessions. `rows` are newest first.
const PlaySessionRow* session_to_attach(const std::vector<PlaySessionRow>& rows, bool& fellBack);

// The row's one-line label: "20261107-001214-auto  AI  timeout, 2 problems" / "20261107-001200  you  3 marks".
std::string play_session_label(const PlaySessionRow& row);

// The words for a session's "ended": "reached the end of the level" ... for the report's header line.
std::string play_session_ended_words(const std::string& ended);

}  // namespace fa::editor
