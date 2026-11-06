// The Play sessions window's data (play_sessions_model.h).
#include "play_sessions_model.h"

#include <algorithm>
#include <format>

#include "fa/runtime/play_session.h"

namespace fa::editor {

PlaySessionRow play_session_row(const std::string& name, const Json& j) {
    PlaySessionRow r;
    r.name = name;
    if (!j.is_object()) {
        r.error = "session.json is not an object";
        return r;
    }
    r.isAuto = j.value("source", std::string()) == "auto";
    r.scene = j.value("scene", std::string());
    r.durationSec = j.value("durationSec", 0.0);
    r.ended = j.value("ended", std::string());
    const Json marks = j.value("marks", Json::array());
    const Json logs = j.value("logs", Json::array());
    r.marks = marks.is_array() ? int(std::min<std::size_t>(marks.size(), 100000)) : 0;
    r.logs = logs.is_array() ? int(std::min<std::size_t>(logs.size(), 100000)) : 0;
    return r;
}

std::vector<PlaySessionRow> read_play_sessions(std::size_t max) {
    std::vector<PlaySessionRow> rows;
    for (const std::string& name : play_session_names()) {
        if (rows.size() >= max) break;
        auto r = load_json_file(std::string(kPlaySessionsDir) + "/" + name + "/session.json");
        if (!r.ok()) {
            PlaySessionRow bad;
            bad.name = name;
            bad.error = r.error().to_string();
            rows.push_back(std::move(bad));
            continue;
        }
        rows.push_back(play_session_row(name, r.value()));
    }
    return rows;
}

const PlaySessionRow* session_to_attach(const std::vector<PlaySessionRow>& rows, bool& fellBack) {
    fellBack = false;
    for (const PlaySessionRow& r : rows)
        if (!r.isAuto) return &r;
    if (rows.empty()) return nullptr;
    fellBack = true;
    return &rows.front();
}

std::string play_session_ended_words(const std::string& ended) {
    if (ended == "won") return "the bot finished the game";
    if (ended == "lost") return "the bot lost";
    if (ended == "timeout") return "it played all the time it had, with no problem";
    if (ended == "stuck") return "it got stuck";
    if (ended == "broken") return "it found something broken";
    if (ended == "quit") return "the game quit";
    if (ended == "aborted") return "it was aborted";
    return ended.empty() ? std::string("(not said)") : ended;
}

std::string play_session_label(const PlaySessionRow& r) {
    if (!r.error.empty()) return r.name + "  (unreadable)";
    std::string out = r.name + (r.isAuto ? "  AI  " : "  you  ");
    if (r.isAuto) {
        out += r.ended.empty() ? "?" : r.ended;
        if (r.marks > 0) out += std::format(", {} problem{}", r.marks, r.marks == 1 ? "" : "s");
    } else {
        out += std::format("{:.0f} s", r.durationSec);
        if (r.marks > 0) out += std::format(", {} mark{}", r.marks, r.marks == 1 ? "" : "s");
    }
    return out;
}

}  // namespace fa::editor
