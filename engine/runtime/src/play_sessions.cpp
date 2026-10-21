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
    j["perf"] = Json::object({{"frames", s.perf.count}, {"avgMs", round1(s.perf.avgMs)}, {"p95Ms", round1(s.perf.p95Ms)},
                              {"maxMs", round1(s.perf.maxMs)}, {"over16ms", s.perf.over16}, {"over33ms", s.perf.over33}});
    Json spikes = Json::array();
    for (const PlaySpike& k : s.spikes)
        spikes.push_back(Json::object({{"frame", k.frame}, {"ms", round1(k.ms)}, {"entities", k.entities}, {"renderStats", k.renderStats}}));
    j["spikes"] = spikes;
    j["logs"] = s.logs;
    Json marks = Json::array();
    int n = 0;
    for (const PlayMark& m : s.marks)
        marks.push_back(Json::object({{"n", ++n}, {"frame", m.frame}, {"time", round1(m.time)}, {"note", m.note}, {"screenshot", m.screenshot}}));
    j["marks"] = marks;
    if (s.profile.is_object()) j["profile"] = s.profile;
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
    return std::format("{:04}{:02}{:02}-{:02}{:02}{:02}", tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday, tm.tm_hour, tm.tm_min, tm.tm_sec);
}

std::string play_session_summary(const Json& j) {
    const Json perf = j.contains("perf") ? j["perf"] : Json::object();
    std::string out = std::format("Play session {} (scene {}, {:.0f}s, {} frames). Frame time avg {:.1f} ms, p95 {:.1f} ms, max {:.1f} ms; "
                                  "{} frames over 16.7 ms, {} over 33 ms.",
                                  j.value("name", std::string("?")), j.value("scene", std::string("?")), j.value("durationSec", 0.0),
                                  j.value("frames", 0), perf.value("avgMs", 0.0), perf.value("p95Ms", 0.0), perf.value("maxMs", 0.0),
                                  perf.value("over16ms", 0), perf.value("over33ms", 0));
    if (j.contains("spikes") && j["spikes"].is_array() && !j["spikes"].empty()) {
        const Json& k = j["spikes"][0];
        out += std::format(" Worst frame: #{} at {:.1f} ms ({} entities).", k.value("frame", 0), k.value("ms", 0.0), k.value("entities", 0));
    }
    const std::size_t nlogs = j.contains("logs") && j["logs"].is_array() ? j["logs"].size() : 0;
    out += std::format(" {} warnings/errors logged", nlogs);
    if (nlogs) {
        out += ":";
        for (std::size_t i = 0; i < std::min<std::size_t>(nlogs, 5); ++i) {
            const Json& l = j["logs"][i];
            out += std::format(" [{}] {}", l.value("level", std::string()), l.value("message", std::string()));
        }
    }
    out += ".";
    if (j.contains("profile") && j["profile"].is_object() && j["profile"].contains("behaviours") && !j["profile"]["behaviours"].empty()) {
        const Json& b = j["profile"]["behaviours"][0];
        out += std::format(" Costliest behaviour: {} ({:.2f} ms per frame).", b.value("class", std::string("?")), b.value("avgMs", 0.0));
    }
    if (j.contains("marks") && j["marks"].is_array() && !j["marks"].empty()) {
        out += " The player marked problems:";
        for (const Json& m : j["marks"]) out += std::format(" #{} (frame {}) \"{}\";", m.value("n", 0), m.value("frame", 0), m.value("note", std::string()));
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
        if (e.is_directory(ec) && std::filesystem::exists(e.path() / "session.json", ec)) names.push_back(e.path().filename().string());
    std::sort(names.rbegin(), names.rend());
    return names;
}

void register_play_session_commands(Engine&, Engine::Impl& I) {
    I.commands.add({"play.sessions", "List the recent play sessions recorded by the editor (Play .. Stop), newest first.",
           "Each session is a folder .factoria/sessions/<yyyymmdd-hhmmss>/ written when the user pressed Stop in the editor. Rows have "
           "a short summary: scene, duration, frame time p95/max, number of warnings/errors and the user's marks (notes). Call play.report "
           "{session} for the details and screenshots. Example: play.sessions {\"max\":5}",
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
                  rows.push_back(Json::object({{"session", n}, {"scene", j.value("scene", std::string())}, {"durationSec", j.value("durationSec", 0.0)},
                                               {"p95Ms", perf.value("p95Ms", 0.0)}, {"maxMs", perf.value("maxMs", 0.0)},
                                               {"logs", j.contains("logs") ? j["logs"].size() : 0},
                                               {"marks", j.contains("marks") ? j["marks"].size() : 0}}));
              }
              Json out = Json::object({{"count", rows.size()}, {"total", names.size()}, {"sessions", rows}});
              if (names.empty()) out["hint"] = "No session yet: the user has to press Play and then Stop in the editor.";
              return out;
          });

    I.commands.add({"play.report", "What happened while the user played: perf, spikes, warnings/errors, their problem marks and screenshots.",
           "Call it when the user says they played the game and saw problems (slow, ugly UI, bugs). Returns the session.json content "
           "(perf: avg/p95/max frame ms and frames over 16.7/33 ms; profile: where the time went, per engine system, per script behaviour class (ms and calls per frame, slowest first), GPU ms or null + reason, memory; spikes: slowest frames with entity count and render stats; logs: "
           "warnings and errors; marks: frame, time, note and screenshot path, 1-based `n`), `replay` (the input file, absolute path) "
           "and `replayHow`. The result carries ONE picture ($image): the screenshot of mark `mark` (default 1); call again with mark 2, "
           "3... to see the others. `session` defaults to the latest (see play.sessions). Example: play.report {\"mark\":2}",
           parse_schema(R"({"type":"object","properties":{
               "session":{"type":"string","description":"Session folder name from play.sessions. Default: the latest."},
               "mark":{"type":"integer","default":1,"minimum":1,"description":"Which mark's screenshot to attach as the picture."}}})"),
           true, "play"},
          [](const Json& a) {
              std::vector<std::string> names = play_session_names();
              std::string name = a.value("session", std::string());
              if (name.empty()) {
                  if (names.empty())
                      throw CommandError("not_found", "No play session found under " + std::string(kPlaySessionsDir) + ".",
                                         "The user has to press Play and then Stop in the editor first.");
                  name = names.front();
              } else if (std::find(names.begin(), names.end(), name) == names.end()) {
                  throw CommandError("not_found", "No play session named '" + name + "'. " + did_you_mean(name, names),
                                     "Use play.sessions to list them.");
              }
              const std::string rel = std::string(kPlaySessionsDir) + "/" + name;
              auto r = load_json_file(rel + "/session.json");
              if (!r.ok()) throw CommandError("failed", r.error().message, r.error().hint);
              Json out = r.value();
              const std::string absDir = fs::resolve(rel).generic_string();
              out["session"] = name;
              out["replay"] = absDir + "/input.json";
              out["replayHow"] = "Deterministic replay of the same input: factoria run --headless --frames " + std::to_string(out.value("frames", 0)) +
                                 " --input " + rel + "/input.json (add --screenshot <frame> to look at a frame). Frame numbers match the marks and spikes.";
              if (out.contains("marks") && out["marks"].is_array()) {
                  for (Json& m : out["marks"])
                      if (m.contains("screenshot") && m["screenshot"].is_string() && !m["screenshot"].get<std::string>().empty())
                          m["screenshot"] = absDir + "/" + m["screenshot"].get<std::string>();
                  const std::size_t want = std::size_t(std::max<std::int64_t>(1, a.value("mark", std::int64_t(1))));
                  if (want <= out["marks"].size()) {
                      const std::string shot = out["marks"][want - 1].value("screenshot", std::string());
                      std::error_code ec;
                      if (!shot.empty() && std::filesystem::exists(shot, ec)) out["$image"] = Json::object({{"path", shot}, {"mimeType", "image/png"}});
                  }
              }
              return out;
          });
}

}  // namespace fa
