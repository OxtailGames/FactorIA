#include "editor_tools.h"

#include <algorithm>

#include "fa/core/strings.h"

namespace fa::editor {

namespace {

std::string str(const Json& j, const char* key, const std::string& fallback = {}) {
    return j.is_object() && j.contains(key) && j[key].is_string() ? j[key].get<std::string>() : fallback;
}

}  // namespace

std::size_t poll_audio_log(const CommandRegistry& commands, AudioLogState& state) {
    const CommandResult r = commands.call("audio.log", Json::object({{"after", state.after}, {"max", 1000}}));
    if (!r.ok) {
        state.error = str(r.error, "message", "audio.log failed");
        return 0;
    }
    state.error.clear();
    state.dropped = r.result.value("dropped", std::uint64_t(0));
    std::size_t added = 0;
    if (r.result.contains("plays") && r.result["plays"].is_array()) {
        for (const Json& p : r.result["plays"]) {
            AudioPlay a;
            a.seq = p.value("seq", std::uint64_t(0));
            if (a.seq <= state.after) continue;
            a.frame = p.value("frame", std::uint64_t(0));
            a.time = p.value("time", 0.0);
            a.path = str(p, "path");
            a.bus = str(p, "bus", "sfx");
            a.source = str(p, "source");
            a.volume = p.value("volume", 1.0f);
            a.pitch = p.value("pitch", 1.0f);
            a.pan = p.value("pan", 0.0f);
            a.loop = p.value("loop", false);
            a.music = p.value("music", false);
            a.ok = p.value("ok", true);
            state.plays.push_back(std::move(a));
            ++added;
        }
    }
    state.after = std::max<std::uint64_t>(state.after, r.result.value("lastSeq", std::uint64_t(0)));
    if (state.plays.size() > AudioLogState::kMax)
        state.plays.erase(state.plays.begin(), state.plays.begin() + static_cast<std::ptrdiff_t>(state.plays.size() - AudioLogState::kMax));
    return added;
}

void clear_audio_log(AudioLogState& state) {
    state.plays.clear();
}

void reset_audio_log(AudioLogState& state) {
    state.plays.clear();
    state.after = 0;
    state.scrolledTo = 0;
    state.dropped = 0;
    state.error.clear();
}

bool audio_play_visible(const AudioPlay& play, const AudioLogState& state) {
    if (state.onlyFailed && play.ok) return false;
    if (state.filter.empty()) return true;
    return to_lower(play.path).find(to_lower(state.filter)) != std::string::npos;
}

}  // namespace fa::editor
