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

void ProfilerView::add_frame(const ProfFrame& f) {
    const double a = frames == 0 ? 1.0 : kSmooth;
    ++frames;
    frameMs.push_back(float(f.totalMs));
    if (frameMs.size() > kHistory) frameMs.erase(frameMs.begin());
    smoothFrameMs += (f.totalMs - smoothFrameMs) * a;
    for (std::size_t i = 0; i < systemMs.size(); ++i) systemMs[i] += (f.systemMs[i] - systemMs[i]) * a;
    // A class that did not run this frame decays towards 0 and disappears when it is negligible.
    for (Row& r : rows) {
        r.ms *= 1.0 - a;
        r.calls *= 1.0 - a;
    }
    for (const ProfClassSample& c : f.classes) {
        auto it = std::find_if(rows.begin(), rows.end(), [&](const Row& r) { return r.className == c.className && r.path == c.path; });
        if (it == rows.end()) {
            rows.push_back(Row{c.className, c.path, 0, 0});
            it = rows.end() - 1;
        }
        it->ms += c.ms * a;
        it->calls += double(c.calls) * a;
    }
    rows.erase(std::remove_if(rows.begin(), rows.end(), [](const Row& r) { return r.ms < 1e-4 && r.calls < 0.01; }), rows.end());
    std::sort(rows.begin(), rows.end(), [](const Row& x, const Row& y) { return x.ms != y.ms ? x.ms > y.ms : x.className < y.className; });
}

void ProfilerView::add_gpu_ms(double ms) {
    gpuMs = haveGpu ? gpuMs + (ms - gpuMs) * kSmooth : ms;
    haveGpu = true;
}

}  // namespace fa::editor
