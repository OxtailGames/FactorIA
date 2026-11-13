// Play sessions (see fa/runtime/play_session.h): stats, session.json, and the commands play.sessions / play.report.
#include "fa/runtime/play_session.h"

#include <algorithm>
#include <cmath>
#include <filesystem>
#include <format>

#include "engine_impl.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"

namespace fa {

FrameStats compute_frame_stats(const std::vector<double>& frameMs) {
    FrameStats s;
    s.count = int(frameMs.size());
    if (frameMs.empty()) return s;
    std::vector<double> v = frameMs;
    std::sort(v.begin(), v.end());
    double sum = 0;
    for (double x : v) {
        sum += x;
        if (x > 16.7) ++s.over16;
        if (x > 33.3) ++s.over33;
    }
    s.avgMs = sum / double(v.size());
    s.p95Ms = v[std::size_t(std::ceil(0.95 * double(v.size()))) - 1];
    s.maxMs = v.back();
    return s;
}

void keep_worst_spike(std::vector<PlaySpike>& spikes, PlaySpike spike, std::size_t keep) {
    auto pos = std::find_if(spikes.begin(), spikes.end(), [&](const PlaySpike& s) { return s.ms < spike.ms; });
    spikes.insert(pos, std::move(spike));
    if (spikes.size() > keep) spikes.resize(keep);
}

static double round1(double v) { return std::round(v * 10.0) / 10.0; }

Json play_session_json(const PlaySession& s) {
    Json j = Json::object();
    j["format"] = "factoria.playsession/1";
    j["name"] = s.name;
    j["scene"] = s.scene;
    j["durationSec"] = round1(s.durationSec);
    j["frames"] = s.frames;
    j["fixedHz"] = s.fixedHz;
    j["perf"] = Json::object({{"frames", s.perf.count},
                              {"avgMs", round1(s.perf.avgMs)},
                              {"p95Ms", round1(s.perf.p95Ms)},
                              {"maxMs", round1(s.perf.maxMs)},
                              {"over16ms", s.perf.over16},
                              {"over33ms", s.perf.over33}});
    Json spikes = Json::array();
    for (const PlaySpike& k : s.spikes)
        spikes.push_back(Json::object(
            {{"frame", k.frame}, {"ms", round1(k.ms)}, {"entities", k.entities}, {"renderStats", k.renderStats}}));
    j["spikes"] = spikes;
    j["logs"] = s.logs;
    Json marks = Json::array();
    int n = 0;
    for (const PlayMark& m : s.marks) {
        Json mark = Json::object(
            {{"n", ++n}, {"frame", m.frame}, {"time", round1(m.time)}, {"note", m.note}, {"screenshot", m.screenshot}});
        if (!m.kind.empty()) mark["kind"] = m.kind;
        if (m.step >= 0) mark["step"] = m.step;
        marks.push_back(std::move(mark));
    }
    j["marks"] = marks;
    if (!s.source.empty()) {
        j["source"] = s.source;
        Json phases = Json::array();
        for (const PlayPhase& p : s.phases)
            phases.push_back(Json::object({{"name", p.name},
                                           {"kind", p.kind},
                                           {"scene", p.scene},
                                           {"frame", p.frame},
                                           {"time", round1(p.time)},
                                           {"screenshot", p.screenshot}}));
        j["phases"] = phases;
        j["score"] = s.score;
        j["ended"] = s.ended;
        j["endedWhy"] = s.endedWhy;
        j["endScreenshot"] = s.endScreenshot;
        j["notes"] = s.notes;
        j["scriptErrors"] = s.scriptErrors;
        if (s.autoInfo.is_object()) j["auto"] = s.autoInfo;
    }
    if (s.profile.is_object()) j["profile"] = s.profile;
    if (s.loading.is_object()) j["loading"] = s.loading;
    j["inputFile"] = "input.json";
    j["inputFrames"] = s.input.contains("frames") ? s.input["frames"].size() : 0;
    return j;
}

Result<void> write_play_session(const std::string& dir, const PlaySession& s) {
    if (auto w = fs::write_text(dir + "/session.json", dump_json(play_session_json(s))); !w.ok()) return w.error();
    return fs::write_text(dir + "/input.json", dump_json(s.input));
}

std::string play_session_name(std::time_t t) {
    std::tm tm{};
#ifdef _WIN32
    localtime_s(&tm, &t);
#else
    localtime_r(&t, &tm);
#endif
    return std::format("{:04}{:02}{:02}-{:02}{:02}{:02}", tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday, tm.tm_hour,
                       tm.tm_min, tm.tm_sec);
}

std::string session_text(const Json& o, const char* key, const std::string& def) {
    if (!o.is_object()) return def;
    const auto it = o.find(key);
    return it != o.end() && it->is_string() ? it->get<std::string>() : def;
}

double session_number(const Json& o, const char* key, double def) {
    if (!o.is_object()) return def;
    const auto it = o.find(key);
    return it != o.end() && it->is_number() ? it->get<double>() : def;
}

std::string play_session_summary(const Json& j) {
    if (!j.is_object()) return "Play session (its session.json is not an object).";
    const auto member = [&j](const char* key, bool (Json::*is)() const) -> const Json* {
        const auto it = j.find(key);
        return it != j.end() && ((*it).*is)() ? &*it : nullptr;
    };
    const Json* perfNode = member("perf", &Json::is_object);
    const Json perf = perfNode ? *perfNode : Json::object();
    const bool autoRun = session_text(j, "source") == "auto";
    std::string out =
        std::format("{} {} (scene {}, {:.0f}s, {} frames). ", autoRun ? "Automatic play session" : "Play session",
                    session_text(j, "name", "?"), session_text(j, "scene", "?"), session_number(j, "durationSec"),
                    std::int64_t(session_number(j, "frames")));
    if (autoRun) {
        const Json* autoNode = member("auto", &Json::is_object);
        const std::string why = session_text(j, "endedWhy");
        out += std::format("The bot ({}) ended it: {}{}. ",
                           autoNode ? session_text(*autoNode, "bot", "?") : std::string("?"),
                           session_text(j, "ended", "?"), why.empty() ? std::string() : " (" + why + ")");
        if (const Json* score = member("score", &Json::is_number)) out += std::format("Score {}. ", score->dump());
        if (const Json* phases = member("phases", &Json::is_array)) out += std::format("{} phase(s). ", phases->size());
    }
    out += std::format("Frame time avg {:.1f} ms, p95 {:.1f} ms, max {:.1f} ms; {} frames over 16.7 ms, {} over 33 ms.",
                       session_number(perf, "avgMs"), session_number(perf, "p95Ms"), session_number(perf, "maxMs"),
                       std::int64_t(session_number(perf, "over16ms")), std::int64_t(session_number(perf, "over33ms")));
    if (const Json* spikes = member("spikes", &Json::is_array); spikes && !spikes->empty()) {
        const Json& k = (*spikes)[0];
        out += std::format(" Worst frame: #{} at {:.1f} ms ({} entities).", std::int64_t(session_number(k, "frame")),
                           session_number(k, "ms"), std::int64_t(session_number(k, "entities")));
    }
    const Json* logs = member("logs", &Json::is_array);
    const std::size_t nlogs = logs ? logs->size() : 0;
    out += std::format(" {} warnings/errors logged", nlogs);
    if (nlogs) {
        out += ":";
        for (std::size_t i = 0; i < std::min<std::size_t>(nlogs, 5); ++i) {
            const Json& l = (*logs)[i];
            out += std::format(" [{}] {}", session_text(l, "level"), session_text(l, "message"));
        }
    }
    out += ".";
    if (const Json* profile = member("profile", &Json::is_object)) {
        const auto it = profile->find("behaviours");
        if (it != profile->end() && it->is_array() && !it->empty())
            out += std::format(" Costliest behaviour: {} ({:.2f} ms per frame).", session_text((*it)[0], "class", "?"),
                               session_number((*it)[0], "avgMs"));
    }
    if (const Json* marks = member("marks", &Json::is_array); marks && !marks->empty()) {
        out += autoRun ? " The bot found problems:" : " The player marked problems:";
        for (const Json& m : *marks)
            out += std::format(" #{} (frame {}) \"{}\";", std::int64_t(session_number(m, "n")),
                               std::int64_t(session_number(m, "frame")), session_text(m, "note"));
    }
    return out;
}

// ------------------------------------------------------------------------------------------------ commands
namespace {

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid play session command schema");
    return r.value();
}

}  // namespace

// Newest first (the names are timestamps).
std::vector<std::string> play_session_names() {
    std::vector<std::string> names;
    std::error_code ec;
    for (const auto& e : std::filesystem::directory_iterator(fs::resolve(kPlaySessionsDir), ec))
        if (e.is_directory(ec) && std::filesystem::exists(e.path() / "session.json", ec))
            names.push_back(fs::path_to_utf8(e.path().filename()));
    std::sort(names.rbegin(), names.rend());
    return names;
}

bool is_auto_play_session_name(std::string_view name) {
    constexpr std::size_t kStamp = 15;  // yyyymmdd-hhmmss
    if (name.size() < kStamp + 5 || name.substr(kStamp, 5) != "-auto") return false;
    const std::string_view rest = name.substr(kStamp + 5);  // "" or "-<n>"
    if (rest.empty()) return true;
    return rest.size() >= 2 && rest[0] == '-' && rest.find_first_not_of("0123456789", 1) == std::string_view::npos;
}

int prune_auto_play_sessions(std::size_t keep, std::string_view spare) {
    int deleted = 0;
    const std::vector<std::string> names = play_session_names();  // newest first
    // The spared session is one of the `keep` that stay, wherever its name sorts: it is counted first.
    std::size_t seen = !spare.empty() && std::find(names.begin(), names.end(), spare) != names.end() ? 1 : 0;
    for (const std::string& name : names) {
        if (!is_auto_play_session_name(name) || name == spare) continue;
        if (++seen <= keep) continue;
        std::error_code ec;
        fs::remove_tree(fs::resolve(std::string(kPlaySessionsDir) + "/" + name), ec);
        if (!ec) ++deleted;
    }
    return deleted;
}

void register_play_session_commands(Engine&, Engine::Impl& I) {
    I.commands.add(
        {"play.sessions",
         "List the recent play sessions (recorded by the editor on Play .. Stop, or by play.auto), newest first.",
         "Each session is a folder .factoria/sessions/<yyyymmdd-hhmmss>/ written when the user pressed Stop in the "
         "editor, or "
         "<yyyymmdd-hhmmss>-auto/ by play.auto (`source` \"auto\"; those rows also carry `ended` and `score`). Rows "
         "have "
         "a short summary: source, scene, duration, frame time p95/max, number of warnings/errors and the marks (the "
         "user's notes, or the problems "
         "the bot found). Call play.report {session} for the details and screenshots. Example: play.sessions "
         "{\"max\":5}",
         parse_schema(R"({"type":"object","properties":{
               "max":{"type":"integer","default":10,"minimum":1,"description":"How many sessions to list."}}})"),
         true, "play"},
        [](const Json& a) {
            const std::size_t max = std::size_t(std::max<std::int64_t>(1, a.value("max", std::int64_t(10))));
            std::vector<std::string> names = play_session_names();
            Json rows = Json::array();
            for (const std::string& n : names) {
                if (rows.size() >= max) break;
                auto r = load_json_file(std::string(kPlaySessionsDir) + "/" + n + "/session.json");
                if (!r.ok()) {
                    rows.push_back(Json::object({{"session", n}, {"error", r.error().to_string()}}));
                    continue;
                }
                const Json& j = r.value();
                const Json perf = j.contains("perf") ? j["perf"] : Json::object();
                Json row = Json::object({{"session", n},
                                         {"source", j.value("source", std::string("editor"))},
                                         {"scene", j.value("scene", std::string())},
                                         {"durationSec", j.value("durationSec", 0.0)},
                                         {"p95Ms", perf.value("p95Ms", 0.0)},
                                         {"maxMs", perf.value("maxMs", 0.0)},
                                         {"logs", j.contains("logs") ? j["logs"].size() : 0},
                                         {"marks", j.contains("marks") ? j["marks"].size() : 0}});
                if (j.contains("ended")) row["ended"] = j["ended"];  // play.auto sessions say how the run ended
                if (j.contains("score")) row["score"] = j["score"];
                rows.push_back(std::move(row));
            }
            Json out = Json::object({{"count", rows.size()}, {"total", names.size()}, {"sessions", rows}});
            if (names.empty())
                out["hint"] =
                    "No session yet: the user has to press Play and then Stop in the editor, or you can run play.auto.";
            return out;
        });

    I.commands.add(
        {"play.report",
         "What happened while the game was played (by the user or by play.auto): perf, spikes, warnings/errors, the "
         "problem marks and screenshots.",
         "Call it when the user says they played the game and saw problems (slow, ugly UI, bugs), and "
         "after play.auto. Example: play.report {\"mark\":2}" FA_COMMAND_DETAILS
         "Returns the session.json content (perf: avg/p95/max frame ms and frames over 16.7/33 ms; "
         "profile: where the time went, per engine system, per script behaviour class (ms and calls per "
         "frame, slowest first), GPU ms or null + reason, memory; loading: timeToFirstFrameMs, each "
         "scene's loadMs (from the start of its load to the end of the first frame after it), files and "
         "bytes, slowestAssets (kind, path, bytes, readMs, decodeMs) and reads (count, bytes, fromPack, "
         "packStoredBytes): this machine's times, rounded, to compare runs, never a pass or a fail; "
         "spikes: slowest frames with entity count and render stats; logs: warnings and errors; marks: "
         "frame, time, note and screenshot path, 1-based `n`; for a play.auto session (`source` \"auto\") "
         "also `kind` and `step` of each problem the bot found, `phases` (scenes and game.phase marks with "
         "their time and screenshot), `score`, `ended` (won, lost, timeout, stuck, broken, quit, aborted) "
         "with `endedWhy`, `endScreenshot`, `notes` and `auto` (seed, speed, bot, stuckSeconds)), `replay` "
         "(the input file, absolute path) and `replayHow`. The result carries ONE picture ($image): the "
         "screenshot of mark `mark` (default 1) or, with `phase`, of that phase; a play.auto session "
         "without marks shows the picture taken when the run ended. Call again with mark 2, 3... or phase "
         "1, 2... to see the others. `session` defaults to the latest (see play.sessions).",
         parse_schema(R"({"type":"object","properties":{
               "session":{"type":"string","description":"Session folder name from play.sessions. Default: the latest."},
               "mark":{"type":"integer","minimum":1,"description":"Which mark's screenshot to attach as the picture. Default 1 (when the session has marks)."},
               "phase":{"type":"integer","minimum":1,"description":"Attach the screenshot of this phase (1-based, play.auto sessions) instead of a mark's. Cannot be combined with mark."}}})"),
         true, "play"},
        [](const Json& a) {
            if (a.contains("mark") && a.contains("phase"))
                throw CommandError(
                    "invalid_argument",
                    "/mark and /phase cannot be given together: each picks the one picture the result carries.",
                    "Pass mark for a problem's screenshot or phase for a stage's, in two calls.");
            std::vector<std::string> names = play_session_names();
            std::string name = a.value("session", std::string());
            if (name.empty()) {
                if (names.empty())
                    throw CommandError("not_found",
                                       "No play session found under " + std::string(kPlaySessionsDir) + ".",
                                       "The user has to press Play and then Stop in the editor first, or run play.auto "
                                       "to have the game play itself.");
                name = names.front();
            } else if (std::find(names.begin(), names.end(), name) == names.end()) {
                throw CommandError("not_found", "No play session named '" + name + "'. " + did_you_mean(name, names),
                                   "Use play.sessions to list them.");
            }
            const std::string rel = std::string(kPlaySessionsDir) + "/" + name;
            auto r = load_json_file(rel + "/session.json");
            if (!r.ok()) throw CommandError("failed", r.error().message, r.error().hint);
            Json out = r.value();
            const std::string absDir = fs::path_to_utf8(fs::resolve(rel));  // UTF-8: it goes into JSON
            out["session"] = name;
            out["replay"] = absDir + "/input.json";
            if (out.contains("auto") && out["auto"].is_object() && out["auto"].contains("replay") &&
                out["auto"]["replay"].is_string())
                out["replayHow"] =
                    "Deterministic replay of the bot's input: " + out["auto"]["replay"].get<std::string>() +
                    " (add --screenshot <frame> to look at a frame). Frame numbers match the marks and spikes.";
            else
                out["replayHow"] = "Deterministic replay of the same input: factoria run --headless --frames " +
                                   std::to_string(out.value("frames", 0)) + " --input " + rel +
                                   "/input.json (add --screenshot <frame> to look at a frame). Frame numbers match the "
                                   "marks and spikes.";
            auto absolute = [&](Json& holder, const char* key) {
                if (holder.contains(key) && holder[key].is_string() && !holder[key].get<std::string>().empty())
                    holder[key] = absDir + "/" + holder[key].get<std::string>();
            };
            std::string picture;
            auto exists = [](const std::string& path) {
                std::error_code ec;
                return !path.empty() && std::filesystem::exists(fs::os_path(fs::path_from_utf8(path)), ec);
            };
            if (out.contains("marks") && out["marks"].is_array()) {
                for (Json& m : out["marks"]) absolute(m, "screenshot");
                const std::size_t want = std::size_t(std::max<std::int64_t>(1, a.value("mark", std::int64_t(1))));
                if (!a.contains("phase") && want <= out["marks"].size())
                    picture = out["marks"][want - 1].value("screenshot", std::string());
            }
            if (out.contains("phases") && out["phases"].is_array()) {
                for (Json& p : out["phases"]) absolute(p, "screenshot");
                if (a.contains("phase")) {
                    const std::size_t want = std::size_t(std::max<std::int64_t>(1, a.value("phase", std::int64_t(1))));
                    if (want > out["phases"].size())
                        throw CommandError("invalid_argument",
                                           "/phase is " + std::to_string(want) + " but the session has " +
                                               std::to_string(out["phases"].size()) + " phase(s).",
                                           "Use a number from 1 to " + std::to_string(out["phases"].size()) + ".");
                    picture = out["phases"][want - 1].value("screenshot", std::string());
                }
            }
            absolute(out, "endScreenshot");
            if (picture.empty() && !a.contains("mark") && !a.contains("phase") && out.contains("endScreenshot") &&
                out["endScreenshot"].is_string())
                picture = out["endScreenshot"].get<std::string>();  // a bot session without problems: how it ended
            if (exists(picture)) out["$image"] = Json::object({{"path", picture}, {"mimeType", "image/png"}});
            return out;
        });

    // Capabilities (capability.h): what each command does outside the engine's memory.
    declare_command_capabilities(I.commands, {
                                                 {"play.sessions", capability_sets::reads()},
                                                 {"play.report", capability_sets::reads()},
                                             });
}

}  // namespace fa
