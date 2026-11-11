#include "fa/tooling/agent_cost.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <map>
#include <regex>
#include <set>

#include "fa/tooling/efficiency.h"
#include "util.h"

namespace fa {

namespace {

constexpr std::size_t kMaxResultText = 256 * 1024;  // of one tool result kept for the scans
constexpr int kMaxListed = 20;                      // errors and misses listed one by one (the counts are complete)

std::string lower(std::string s) {
    for (char& c : s) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return s;
}
bool contains_ci(const std::string& text, const char* needle) { return lower(text).find(needle) != std::string::npos; }

double round_to(double v, double scale) { return std::round(v * scale) / scale; }

std::string first_line(const std::string& text, std::size_t maxLen = 200) {
    std::size_t start = 0;
    while (start < text.size() && std::isspace(static_cast<unsigned char>(text[start]))) ++start;
    std::size_t end = text.find('\n', start);
    if (end == std::string::npos) end = text.size();
    std::string line = text.substr(start, std::min(end - start, maxLen));
    // never cut inside a UTF-8 sequence
    while (!line.empty() && (static_cast<unsigned char>(line.back()) & 0xC0) == 0x80 && line.size() > 1) line.pop_back();
    return line;
}

// The text of a tool_result content (a string, or [{type:"text", text}]).
std::string result_text(const Json& block) {
    if (!block.is_object() || !block.contains("content")) return {};
    const Json& c = block["content"];
    std::string out;
    if (c.is_string()) out = c.get<std::string>();
    else if (c.is_array())
        for (const Json& p : c)
            if (p.is_object() && p.contains("text") && p["text"].is_string()) out += p["text"].get<std::string>();
    if (out.size() > kMaxResultText) out.resize(kMaxResultText);
    return out;
}

// A test run passed when it says so and counts no failure.
bool says_all_passed(const std::string& text) {
    static const std::regex failed(R"((^|[^0-9])[1-9][0-9]* (failed|failing|failures?))", std::regex::icase);
    if (std::regex_search(text, failed)) return false;
    return contains_ci(text, "passed") || contains_ci(text, "all tests") || contains_ci(text, "0 failed");
}

bool shows_script_error(const std::string& text) {
    static const std::regex pat(R"(script errors?|uncaught|TypeError|ReferenceError|SyntaxError|"scriptErrors"\s*:\s*[1-9])", std::regex::icase);
    return std::regex_search(text, pat);
}

struct CallText {
    std::size_t step = 0;  // 1-based
    std::string command;   // engine command, or the tool name
    std::string ref;       // for a shell call: the command line
    bool failed = false;
    std::string code;
    std::string text;
};

bool is_factoria_call(const EfficiencyToolCall& c) {
    return (c.name == "Bash" && c.shell.find("factoria") != std::string::npos) || c.command.find('.') != std::string::npos;
}

}  // namespace

Json agent_cost_read_play_auto(const std::string& text) {
    Json out = Json::object({{"phases", 0}, {"ended", ""}, {"scriptErrors", 0}, {"parsed", false}});
    const std::size_t a = text.find('{');
    const std::size_t b = text.rfind('}');
    Json j;
    if (a != std::string::npos && b != std::string::npos && b > a) j = Json::parse(text.begin() + static_cast<std::ptrdiff_t>(a), text.begin() + static_cast<std::ptrdiff_t>(b) + 1, nullptr, false);
    std::set<std::string> phaseSet;
    if (j.is_object() && j.contains("phases") && j["phases"].is_array()) {
        out["parsed"] = true;
        for (const Json& p : j["phases"]) {
            if (!p.is_object()) continue;
            const std::string name = p.value("name", std::string());
            phaseSet.insert(p.value("kind", std::string()) + "|" + name);
        }
        if (j.contains("ended") && j["ended"].is_string()) out["ended"] = j["ended"];
        if (j.contains("scriptErrors")) {
            const Json& se = j["scriptErrors"];
            out["scriptErrors"] = se.is_number() ? static_cast<int>(std::min(se.get<double>(), 1e6)) : (se.is_array() ? static_cast<int>(se.size()) : 0);
        }
    } else if (const std::size_t at = text.find("\"phases\""); at != std::string::npos) {
        // The answer was cut or wrapped: count the distinct phase names in the part that follows "phases".
        static const std::regex name(R"re("name"\s*:\s*"([^"]*)")re");
        const std::size_t end = std::min(text.size(), at + 20000);
        const std::string part = text.substr(at, end - at);
        for (auto it = std::sregex_iterator(part.begin(), part.end(), name); it != std::sregex_iterator(); ++it) phaseSet.insert((*it)[1].str());
        static const std::regex ended(R"re("ended"\s*:\s*"([a-z]+)")re");
        std::smatch m;
        if (std::regex_search(text, m, ended)) out["ended"] = m[1].str();
    }
    out["phases"] = static_cast<int>(phaseSet.size());
    return out;
}

Json agent_cost_report(const AgentCostInput& in) {
    const EfficiencySession session = read_claude_stream_session(in.transcript, "run");

    // The text of every result of a call that ran the engine (one more pass over the lines, keyed by tool_use id).
    std::map<std::string, std::string> texts;
    std::set<std::string> wanted;
    for (const EfficiencyStep& st : session.steps)
        for (const EfficiencyToolCall& c : st.calls)
            if (is_factoria_call(c) && !c.id.empty()) wanted.insert(c.id);
    Json resultLine;
    {
        std::size_t pos = 0;
        while (pos < in.transcript.size()) {
            std::size_t eol = in.transcript.find('\n', pos);
            if (eol == std::string::npos) eol = in.transcript.size();
            const bool tooLong = eol - pos > kEfficiencyMaxLine;
            const Json j = tooLong ? Json() : Json::parse(in.transcript.begin() + static_cast<std::ptrdiff_t>(pos), in.transcript.begin() + static_cast<std::ptrdiff_t>(eol), nullptr, false);
            pos = eol + 1;
            if (!j.is_object()) continue;
            const std::string type = j.value("type", std::string());
            if (type == "result") { resultLine = j; continue; }
            if (type != "user" || !j.contains("message") || !j["message"].is_object() || !j["message"].contains("content")) continue;
            const Json& content = j["message"]["content"];
            if (!content.is_array()) continue;
            for (const Json& b : content) {
                if (!b.is_object() || b.value("type", std::string()) != "tool_result") continue;
                const std::string id = b.value("tool_use_id", std::string());
                if (wanted.count(id)) texts[id] = result_text(b);
            }
        }
    }

    const int levelsNeeded = std::max(1, in.levels);
    int firstPlayableStep = 0, playAutoCalls = 0, firstPlayAutoStep = 0;
    Json errors = Json::array();
    Json byCode = Json::object();
    int errorCount = 0;
    Json missed = Json::array();
    int missedCount = 0;
    bool testPassedBefore = false;
    for (const EfficiencyStep& st : session.steps) {
        for (const EfficiencyToolCall& c : st.calls) {
            if (!is_factoria_call(c)) continue;
            const std::string& text = texts[c.id];
            if (c.failed && !c.code.empty()) {
                ++errorCount;
                byCode[c.code] = (byCode.contains(c.code) ? byCode[c.code].get<int>() : 0) + 1;
                if (static_cast<int>(errors.size()) < kMaxListed)
                    errors.push_back(Json::object({{"step", st.number}, {"command", c.command == "Bash" ? c.shell.substr(0, 120) : c.command}, {"code", c.code}, {"message", first_line(text)}}));
            }
            const bool isTest = c.shell.find("factoria test") != std::string::npos || c.command == "test.run";
            const bool isPlay = c.command == "play.auto";
            const bool passed = isTest && !c.failed && says_all_passed(text);
            if (shows_script_error(text) && (passed || (!isTest && testPassedBefore))) {
                ++missedCount;
                if (static_cast<int>(missed.size()) < kMaxListed)
                    missed.push_back(Json::object({{"step", st.number}, {"command", isPlay ? "play.auto" : (isTest ? "test" : c.shell.substr(0, 120))},
                                                   {"line", first_line(text)}}));
            }
            if (passed) testPassedBefore = true;
            if (isPlay) { ++playAutoCalls; if (firstPlayAutoStep == 0) firstPlayAutoStep = st.number; }
            if (isPlay && firstPlayableStep == 0 && !c.failed) {
                const Json r = agent_cost_read_play_auto(text);
                if (r.value("ended", std::string()) == "won" && r.value("phases", 0) >= levelsNeeded) firstPlayableStep = st.number;
            }
        }
    }

    const int total = static_cast<int>(session.steps.size());
    Json report = Json::object();
    report["format"] = "factoria.agent-cost/1";
    report["cli"] = in.cli;
    report["model"] = in.model;
    report["brief"] = in.brief;
    report["factoriaVersion"] = in.factoriaVersion;
    report["exitStatus"] = in.exitStatus;
    report["elapsedSeconds"] = in.elapsedSeconds;
    Json notes = Json::array();

    const EfficiencyMeasure all = measure_span(session, 1, total);
    Json totalJson = Json::object({{"steps", all.steps}, {"toolCalls", all.toolCalls}, {"minutes", all.minutes}, {"tokens", all.tokens}});
    if (resultLine.is_object()) {
        const double cost = resultLine.value("total_cost_usd", 0.0);
        totalJson["costUsd"] = round_to(cost, 100.0);
        if (resultLine.contains("usage") && resultLine["usage"].is_object()) {
            const Json& u = resultLine["usage"];
            totalJson["inputTokens"] = u.value("input_tokens", 0);
            totalJson["outputTokens"] = u.value("output_tokens", 0);
            totalJson["cacheWriteTokens"] = u.value("cache_creation_input_tokens", 0);
            totalJson["cacheReadTokens"] = u.value("cache_read_input_tokens", 0);
        }
        totalJson["stopReason"] = resultLine.value("terminal_reason", resultLine.value("subtype", std::string()));
        totalJson["cliTurns"] = resultLine.value("num_turns", 0);
    } else {
        notes.push_back("The transcript has no final \"result\" line: the run was cut (time limit or crash); costUsd is unknown.");
    }
    report["total"] = totalJson;

    Json first = Json::object({{"reached", firstPlayableStep > 0}, {"playAutoCalls", playAutoCalls}});
    if (firstPlayAutoStep > 0) first["firstPlayAutoStep"] = firstPlayAutoStep;
    if (firstPlayableStep > 0) {
        const EfficiencyMeasure m = measure_span(session, 1, firstPlayableStep);
        first["step"] = firstPlayableStep;
        first["toolCalls"] = m.toolCalls;
        first["minutes"] = m.minutes;
        first["tokens"] = m.tokens;
    } else {
        notes.push_back("No play.auto in the run reached the last level (a play.auto run that ended \"won\" after at least " + std::to_string(levelsNeeded) +
                        " phases): there is no first playable build to measure.");
    }
    report["firstPlayable"] = first;

    Json fin = Json::object({{"reachedLastLevel", false}});
    if (in.finalPlay.is_object()) {
        const Json r = agent_cost_read_play_auto(in.finalPlay.dump());
        fin["phases"] = r["phases"];
        fin["ended"] = r["ended"];
        fin["scriptErrors"] = r["scriptErrors"];
        fin["reachedLastLevel"] = r.value("ended", std::string()) == "won" && r.value("phases", 0) >= levelsNeeded;
    } else {
        fin["note"] = "play.auto was not run or did not answer JSON";
    }
    report["finalGame"] = fin;
    report["engineErrors"] = Json::object({{"count", errorCount}, {"byCode", byCode}, {"first", errors}});
    report["notCaught"] = Json::object({{"count", missedCount}, {"items", missed}});
    report["notes"] = notes;
    return report;
}

void register_agent_cost_commands(CommandRegistry& registry) {
    CommandInfo info;
    info.name = "agent.cost";
    info.category = "ai";
    info.summary = "Read the transcript of one AI CLI run that made a game (scripts/agent-cost.sh): steps and tokens to the first playable build, engine errors met and missed.";
    info.description =
        "Reads `transcript` (the lines of `claude -p --output-format stream-json --verbose`) and returns {format, cli, model, brief, factoriaVersion, exitStatus, elapsedSeconds, "
        "total {steps, toolCalls, minutes, tokens, costUsd, inputTokens, outputTokens, cacheWriteTokens, cacheReadTokens, stopReason, cliTurns}, "
        "firstPlayable {reached, playAutoCalls, firstPlayAutoStep, step, toolCalls, minutes, tokens}, finalGame {reachedLastLevel, phases, ended, scriptErrors}, "
        "engineErrors {count, byCode, first[]}, notCaught {count, items[]}, notes[]}. A step is one model message and its tokens are input + cache + output. "
        "Example: {\"transcript\":\"/tmp/agent-cost.x/transcript.jsonl\",\"finalPlay\":\"/tmp/agent-cost.x/final-play.json\",\"cli\":\"claude\",\"model\":\"sonnet\"}."
        FA_COMMAND_DETAILS
        "firstPlayable is the first `factoria call play.auto` whose answer ended \"won\" after at least `levels` (default 3) phases, the scenes it loaded (named by their path) and the game.phase marks it made (what play.auto records; levels loaded inside one scene show only if the game calls game.phase, so a correct game can be missed); "
        "finalGame reads `finalPlay`, the answer of play.auto on the finished game. engineErrors are failed `factoria` calls that gave an error code; notCaught are "
        "outputs that show a script error (script error, uncaught, TypeError...) while a `factoria test` had passed.";
    info.inputSchema = Json::parse(R"({"type":"object","additionalProperties":false,"required":["transcript"],"properties":{
        "transcript":{"type":"string","description":"Absolute path of the stream-json transcript (at most 64 MB)."},
        "finalPlay":{"type":"string","description":"Absolute path of a file with the answer of play.auto on the final game."},
        "cli":{"type":"string","default":"claude"},"model":{"type":"string"},"brief":{"type":"string","description":"The id of the brief the run was given."},
        "factoriaVersion":{"type":"string"},"exitStatus":{"type":"integer"},"elapsedSeconds":{"type":"integer","minimum":0},
        "levels":{"type":"integer","minimum":1,"maximum":50,"default":3,"description":"How many levels the brief asks for."}}})");
    info.readOnly = true;
    registry.add(std::move(info), [](const Json& args) -> Json {
        const std::string tpath = args.value("transcript", std::string());
        if (tpath.empty()) throw CommandError("invalid_argument", "/transcript: required", "Give the absolute path of the stream-json transcript.");
        std::error_code ec;
        const std::filesystem::path tp = fs::path_from_utf8(tpath);
        const std::uintmax_t size = std::filesystem::file_size(tp, ec);
        if (ec) throw CommandError("not_found", "/transcript: cannot read " + tpath, "Pass the transcript.jsonl that scripts/agent-cost.sh wrote.");
        if (size > kEfficiencyMaxBytes) throw CommandError("too_large", "/transcript: the file is bigger than 64 MB", "A run this long was cut by its limits; report it by hand.");
        auto text = tooling_detail::read_file(tp);
        if (!text) throw CommandError("not_found", "/transcript: cannot read " + tpath, "Check the path and that nothing else holds the file.");
        AgentCostInput in;
        in.transcript = std::move(*text);
        const std::string fpath = args.value("finalPlay", std::string());
        if (!fpath.empty()) {
            if (auto f = tooling_detail::read_file(fs::path_from_utf8(fpath))) {
                const std::size_t a = f->find('{'), b = f->rfind('}');
                if (a != std::string::npos && b != std::string::npos && b > a) in.finalPlay = Json::parse(f->begin() + static_cast<std::ptrdiff_t>(a), f->begin() + static_cast<std::ptrdiff_t>(b) + 1, nullptr, false);
            }
        }
        in.cli = args.value("cli", std::string("claude"));
        in.model = args.value("model", std::string());
        in.brief = args.value("brief", std::string());
        in.factoriaVersion = args.value("factoriaVersion", std::string());
        in.exitStatus = args.value("exitStatus", 0);
        in.elapsedSeconds = std::clamp(args.value("elapsedSeconds", 0), 0, 1'000'000'000);
        in.levels = std::clamp(args.value("levels", 3), 1, 50);
        return agent_cost_report(in);
    });
}

}  // namespace fa
