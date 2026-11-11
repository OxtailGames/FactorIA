#include "fa/tooling/efficiency.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <functional>
#include <istream>
#include <map>
#include <set>
#include <sstream>
#include <string_view>

#include "fa/core/date.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/tooling/docs.h"

namespace fa {

namespace stdfs = std::filesystem;

namespace {

constexpr double kBytesPerTokenEstimate = 3.75;  // the estimate of ai.session_timeline and AI_COSTS.md (fa_ai: kBytesPerToken)

std::string jstr(const Json& j, const char* key) {
    if (!j.is_object()) return {};
    auto it = j.find(key);
    return it != j.end() && it->is_string() ? it->get<std::string>() : std::string();
}
const Json* jchild(const Json& j, const char* key) {
    if (!j.is_object()) return nullptr;
    auto it = j.find(key);
    return it == j.end() ? nullptr : &*it;
}
// A whole number a transcript line holds (tokens, milliseconds, bytes): 0 for a missing key, a negative, NaN or a non-number, and never
// more than kMaxJsonCount, so that the cast below stays inside the range of the type (a double past it is undefined behaviour) and
// the sums of many of them cannot wrap.
constexpr double kMaxJsonCount = 1e15;
std::uint64_t juint(const Json& j, const char* key) {
    if (const Json* c = jchild(j, key); c && c->is_number()) {
        const double v = c->get<double>();
        if (v >= 1.0) return static_cast<std::uint64_t>(std::min(v, kMaxJsonCount));  // false for NaN and for anything below 1
    }
    return 0;
}
// A non-negative amount (minutes, dollars): 0 for a missing key, a negative, NaN or a non-number, at most kMaxJsonCount.
double jamount(const Json& j, const char* key) {
    if (const Json* c = jchild(j, key); c && c->is_number()) {
        const double v = c->get<double>();
        if (v > 0.0) return std::min(v, kMaxJsonCount);
    }
    return 0.0;
}
// The same for a count held in an int (a step number...).
int jint(const Json& j, const char* key) { return static_cast<int>(std::min<std::uint64_t>(juint(j, key), 2'000'000'000u)); }

// A path as UTF-8 text and back, whatever the platform: string() on Windows is the ANSI code page, which turns an accented letter of a
// session name into '?' or another byte sequence.
std::string u8text(const stdfs::path& p) {
    const std::u8string u = p.u8string();
    return std::string(reinterpret_cast<const char*>(u.data()), u.size());
}
stdfs::path path_of_text(const std::string& text) { return stdfs::path(std::u8string(reinterpret_cast<const char8_t*>(text.data()), text.size())); }
double round_to(double v, double scale) { return std::round(v * scale) / scale; }
bool contains_string(const std::vector<std::string>& v, const std::string& s) { return std::find(v.begin(), v.end(), s) != v.end(); }
bool jbool(const Json& j, const char* key) {
    const Json* c = jchild(j, key);
    return c && c->is_boolean() && c->get<bool>();
}

std::uint64_t tokens_from_bytes(std::uint64_t bytes) {
    return static_cast<std::uint64_t>(static_cast<double>(bytes) / kBytesPerTokenEstimate + 0.5);
}

// The error code of a failed call: "code":"..." in the result text (the text may be clipped, so it is searched for, not parsed).
std::string code_of_text(const std::string& text) {
    static const char kKey[] = "\"code\":";
    std::size_t at = text.find(kKey);
    if (at == std::string::npos) return {};
    at += sizeof(kKey) - 1;
    while (at < text.size() && text[at] == ' ') ++at;
    if (at >= text.size() || text[at] != '"') return {};
    const std::size_t end = text.find('"', at + 1);
    if (end == std::string::npos || end - at > 64) return {};
    return text.substr(at + 1, end - at - 1);
}

// What a call acted on: the first of the usual argument names that is a string, cut to 200 bytes (never inside a UTF-8 sequence).
std::string ref_of(const Json& args) {
    static const char* const kKeys[] = {"path",  "file_path", "filePath", "file",   "topic",     "page", "doc", "name",
                                        "query", "component", "entity",   "scene",  "pattern",   "id"};
    if (!args.is_object()) return {};
    for (const char* k : kKeys) {
        if (const Json* c = jchild(args, k); c && c->is_string() && !c->get<std::string>().empty()) {
            std::string s = c->get<std::string>();
            if (s.size() > 200) {
                std::size_t cut = 200;
                while (cut > 0 && (static_cast<unsigned char>(s[cut]) & 0xC0) == 0x80) --cut;
                s.resize(cut);
            }
            return s;
        }
    }
    return {};
}

// "scene_inspect" -> "scene.inspect": the provider-safe tool name back to the command (categories have no underscore).
std::string command_from_tool_name(std::string name) {
    if (starts_with(name, "mcp__")) {
        const std::size_t p = name.rfind("__");
        if (p != std::string::npos && p + 2 < name.size()) name = name.substr(p + 2);
    }
    const std::size_t us = name.find('_');
    if (us != std::string::npos && us > 0 && std::islower(static_cast<unsigned char>(name[0])) && name.find('.') == std::string::npos &&
        name.find(' ') == std::string::npos)
        name[us] = '.';
    return name;
}

// The built-in agent's tool_call wrapper runs a command under its own name.
void resolve_builtin_call(EfficiencyToolCall& c, const Json& input) {
    Json args = input;
    if (c.name == "tool_call") {
        const std::string cmd = jstr(input, "command");
        if (!cmd.empty()) c.command = cmd;
        if (const Json* a = jchild(input, "arguments"); a && a->is_object()) args = *a;
    } else if (c.name == "tool_describe" || c.name == "tool_search") {
        c.command = c.name;
    } else {
        c.command = command_from_tool_name(c.name);
    }
    c.ref = ref_of(args);
}

// A CLI agent's call: `factoria call <command> ...`, `factoria docs read|search <x>` inside a shell tool, or an MCP tool of the
// engine. Anything else keeps its tool name (Read, Edit, Bash...), with the file or the shell command as what it acted on.
void resolve_cli_call(EfficiencyToolCall& c, const Json& input) {
    c.command = command_from_tool_name(c.name);
    c.ref = ref_of(input);
    const std::string cmdline = jstr(input, "command");
    if (cmdline.empty()) return;
    c.shell = cmdline.substr(0, 200);
    while (!c.shell.empty() && c.shell.size() < cmdline.size() && (static_cast<unsigned char>(cmdline[c.shell.size()]) & 0xC0) == 0x80) c.shell.pop_back();
    auto words = [](std::string_view s) {
        std::vector<std::string> out;
        std::string cur;
        for (char ch : s) {
            if (ch == ' ' || ch == '\t' || ch == '\n' || ch == '"' || ch == '\'') {
                if (!cur.empty()) out.push_back(std::move(cur));
                cur.clear();
            } else {
                cur += ch;
            }
        }
        if (!cur.empty()) out.push_back(std::move(cur));
        return out;
    };
    const std::vector<std::string> w = words(cmdline);
    for (std::size_t i = 0; i < w.size(); ++i) {
        const std::string bin = u8text(path_of_text(w[i]).stem());
        if (bin != "factoria" || i + 1 >= w.size()) continue;
        if (w[i + 1] == "call" && i + 2 < w.size()) {
            std::size_t cmdAt = i + 2;  // `factoria call --project . play.auto`: the options come before the command
            while (cmdAt + 1 < w.size() && w[cmdAt].size() > 1 && w[cmdAt][0] == '-') cmdAt += w[cmdAt] == "--project" ? 2 : 1;
            if (cmdAt >= w.size()) cmdAt = i + 2;
            c.command = w[cmdAt];
            c.ref.clear();
            // the first plain word after the command is what it acted on
            for (std::size_t k = cmdAt + 1; k < w.size() && k < cmdAt + 4; ++k) {
                if (!w[k].empty() && w[k][0] != '-' && w[k][0] != '{' && w[k] != "--project") { c.ref = w[k]; break; }
                if (w[k] == "--project") ++k;
            }
        } else if (w[i + 1] == "docs" && i + 2 < w.size()) {
            c.command = "docs." + w[i + 2];
            c.ref = i + 3 < w.size() ? w[i + 3] : std::string();
        }
        break;
    }
}

// A failed result of a CLI tool: an engine error is a JSON object with a string "code" and a "message".
void judge_cli_result(EfficiencyToolCall& c, const std::string& result) {
    c.resultBytes = result.size();
    if (result.size() < 12 || result.front() != '{') return;
    const std::string code = code_of_text(result);
    if (!code.empty() && result.find("\"message\"") != std::string::npos && result.find("\"ok\":true") == std::string::npos) {
        c.failed = true;
        c.code = code;
    }
}

std::uint64_t json_bytes(const Json& j) {
    if (j.is_null()) return 0;
    if (j.is_string()) return j.get_ref<const std::string&>().size();
    return j.dump().size();
}

}  // namespace

// ---------------------------------------------------------------------------------------------------------- transcripts --
namespace {

// Where the lines of a transcript come from: `next` gives the following line (without its newline) and says when it was too long to
// keep (then `line` is empty); false at the end.
using LineSource = std::function<bool(std::string_view& line, bool& tooLong)>;

EfficiencySession read_session_lines(const LineSource& next, const std::string& id) {
    EfficiencySession s;
    s.id = id;
    std::map<std::string, std::pair<std::size_t, std::size_t>> pending;  // tool call id -> (step index, call index)
    std::vector<std::uint64_t> cliBytes;                                  // per step, CLI agents
    bool cliLastWasEnd = true;
    std::int64_t lastMs = 0;
    std::string_view raw;
    bool tooLong = false;
    while (next(raw, tooLong)) {
        if (tooLong) { ++s.skippedLines; continue; }
        if (raw.empty()) continue;
        if (raw.size() > kEfficiencyMaxLine) { ++s.skippedLines; continue; }
        const Json j = Json::parse(raw.begin(), raw.end(), nullptr, false);
        if (!j.is_object()) { ++s.skippedLines; continue; }
        std::int64_t t = 0;
        if (parse_iso_utc_ms(jstr(j, "t"), t) && t > 0) {
            if (s.startMs == 0) s.startMs = t;
            lastMs = t;
            s.hasTimes = true;
        }
        const std::string kind = jstr(j, "kind");
        auto stamp = [&](EfficiencyStep& st) { if (t > 0) st.endMs = t; };

        if (kind == "assistant") {
            if (static_cast<int>(s.steps.size()) >= kEfficiencyMaxSteps) { s.truncated = true; break; }
            s.agent = "builtin";
            EfficiencyStep st;
            st.number = static_cast<int>(s.steps.size()) + 1;
            st.endMs = t > 0 ? t : (s.steps.empty() ? lastMs : s.steps.back().endMs);
            if (const Json* u = jchild(j, "usage"); u && u->is_object())
                st.tokens = juint(*u, "inputTokens") + juint(*u, "outputTokens") + juint(*u, "cacheCreationTokens") + juint(*u, "cacheReadTokens");
            st.costUsd = jamount(j, "costUsd");
            const Json* content = jchild(j, "content");
            auto add_call = [&](const std::string& callId, const std::string& name, const Json& input) {
                EfficiencyToolCall call;
                call.id = callId;
                call.name = name;
                resolve_builtin_call(call, input);
                st.calls.push_back(std::move(call));
                if (!callId.empty()) pending[callId] = {s.steps.size(), st.calls.size() - 1};
            };
            if (content && content->is_array()) {  // Anthropic: [{type:"tool_use", id, name, input}]
                for (const Json& b : *content)
                    if (jstr(b, "type") == "tool_use") add_call(jstr(b, "id"), jstr(b, "name"), b.contains("input") ? b["input"] : Json::object());
            } else if (content && content->is_object()) {  // OpenAI-style: {tool_calls:[{id, function:{name, arguments}}]}
                if (const Json* calls = jchild(*content, "tool_calls"); calls && calls->is_array()) {
                    for (const Json& c : *calls) {
                        const Json* fn = jchild(c, "function");
                        if (!fn) continue;
                        Json input = Json::object();
                        if (const Json* a = jchild(*fn, "arguments"); a && a->is_string()) {
                            Json parsed = Json::parse(a->get<std::string>(), nullptr, false);
                            if (parsed.is_object()) input = std::move(parsed);
                        } else if (a && a->is_object()) {
                            input = *a;
                        }
                        add_call(jstr(c, "id"), jstr(*fn, "name"), input);
                    }
                }
            }
            s.steps.push_back(std::move(st));
        } else if (kind == "tool_results") {
            const Json* rs = jchild(j, "results");
            if (rs && rs->is_array()) {
                for (const Json& r : *rs) {
                    auto it = pending.find(jstr(r, "toolUseId"));
                    if (it == pending.end() || it->second.first >= s.steps.size()) continue;
                    EfficiencyToolCall& call = s.steps[it->second.first].calls[it->second.second];
                    const std::string content = jstr(r, "content");
                    call.failed = jbool(r, "isError");
                    call.ms = static_cast<std::int64_t>(juint(r, "ms"));
                    call.resultBytes = juint(r, "bytes") ? juint(r, "bytes") : content.size();
                    if (const std::string cmd = jstr(r, "command"); !cmd.empty()) call.command = cmd;
                    if (call.failed) {
                        call.code = jstr(r, "code");
                        if (call.code.empty()) call.code = code_of_text(content);
                    }
                }
            }
            if (!s.steps.empty()) stamp(s.steps.back());
        } else if (kind == "thinking" || kind == "text" || kind == "tool_start") {
            s.agent = s.agent.empty() ? "cli" : s.agent;
            if (s.agent != "cli") continue;
            if (s.steps.empty() || cliLastWasEnd) {
                if (static_cast<int>(s.steps.size()) >= kEfficiencyMaxSteps) { s.truncated = true; break; }
                EfficiencyStep st;
                st.number = static_cast<int>(s.steps.size()) + 1;
                st.endMs = t > 0 ? t : (s.steps.empty() ? lastMs : s.steps.back().endMs);
                s.steps.push_back(std::move(st));
                cliBytes.push_back(0);
            }
            cliLastWasEnd = false;
            EfficiencyStep& st = s.steps.back();
            stamp(st);
            cliBytes.back() += jstr(j, "text").size();
            if (kind == "tool_start") {
                EfficiencyToolCall call;
                call.id = jstr(j, "id");
                call.name = jstr(j, "tool");
                const Json* input = jchild(j, "input");
                resolve_cli_call(call, input ? *input : Json::object());
                cliBytes.back() += input ? json_bytes(*input) : 0;
                st.calls.push_back(std::move(call));
            }
        } else if (kind == "tool_end" && s.agent == "cli" && !s.steps.empty()) {
            cliLastWasEnd = true;
            const std::string callId = jstr(j, "id");
            const std::string name = jstr(j, "tool");
            // The call it ends: by id, else the oldest running call of that name, searching the last few steps.
            EfficiencyToolCall* match = nullptr;
            for (std::size_t k = s.steps.size(); k-- > 0 && !match && s.steps.size() - k <= 8;) {
                for (EfficiencyToolCall& c : s.steps[k].calls) {
                    if (c.resultBytes == 0 && !c.failed && c.ms == 0 && (callId.empty() ? c.name == name : c.id == callId)) {
                        match = &c;
                        break;
                    }
                }
            }
            const Json* res = jchild(j, "result");
            const std::string resultText = res && res->is_string() ? res->get<std::string>() : (res && !res->is_null() ? res->dump() : std::string());
            if (match) {
                match->ms = static_cast<std::int64_t>(juint(j, "ms"));
                judge_cli_result(*match, resultText);
                if (match->resultBytes == 0) match->resultBytes = 1;  // marks the call as ended
            }
            cliBytes.back() += resultText.size();
            stamp(s.steps.back());
        }
    }
    if (s.agent == "cli") {
        s.estimated = true;
        for (std::size_t i = 0; i < s.steps.size() && i < cliBytes.size(); ++i) s.steps[i].tokens = tokens_from_bytes(cliBytes[i]);
    }
    // A step without a time keeps the time of the one before it, so a span's minutes never go backwards.
    std::int64_t prev = s.startMs;
    for (EfficiencyStep& st : s.steps) {
        if (st.endMs < prev) st.endMs = prev;
        prev = st.endMs;
    }
    return s;
}

// Lines out of a stream, read in chunks: never more than one line (at most kEfficiencyMaxLine bytes) and one chunk in memory, and no more
// than `limit` bytes of the stream. A longer line is dropped as it is read (reported as too long); `cut` says the limit stopped the read.
class StreamLines {
public:
    StreamLines(std::istream& in, std::uint64_t limit) : in_(in), limit_(limit) {}
    bool next(std::string_view& line, bool& tooLong) {
        line_.clear();
        tooLong = false;
        bool any = false;
        for (;;) {
            if (pos_ == len_ && !fill()) break;
            const char* begin = chunk_.data() + pos_;
            const std::size_t avail = len_ - pos_;
            const void* nl = std::memchr(begin, '\n', avail);
            const std::size_t take = nl ? static_cast<std::size_t>(static_cast<const char*>(nl) - begin) : avail;
            any = true;
            if (!tooLong) {
                if (line_.size() + take > kEfficiencyMaxLine) { tooLong = true; line_.clear(); }
                else line_.append(begin, take);
            }
            pos_ += take + (nl ? 1 : 0);
            if (nl) break;
        }
        if (!any) return false;
        line = tooLong ? std::string_view() : std::string_view(line_);
        return true;
    }
    bool cut() const { return cut_; }

private:
    bool fill() {
        if (read_ >= limit_) {
            // Anything left past the limit is not read.
            char probe;
            if (in_.read(&probe, 1)) cut_ = true;
            return false;
        }
        chunk_.resize(65536);
        const std::uint64_t room = limit_ - read_;
        in_.read(chunk_.data(), static_cast<std::streamsize>(std::min<std::uint64_t>(chunk_.size(), room)));
        len_ = static_cast<std::size_t>(in_.gcount());
        pos_ = 0;
        read_ += len_;
        return len_ > 0;
    }
    std::istream& in_;
    std::uint64_t limit_;
    std::uint64_t read_ = 0;
    std::string chunk_, line_;
    std::size_t pos_ = 0, len_ = 0;
    bool cut_ = false;
};

}  // namespace

EfficiencySession read_efficiency_session(const std::string& text, const std::string& id) {
    std::size_t pos = 0;
    return read_session_lines(
        [&](std::string_view& line, bool& tooLong) {
            if (pos >= text.size()) return false;
            std::size_t eol = text.find('\n', pos);
            if (eol == std::string::npos) eol = text.size();
            line = std::string_view(text.data() + pos, eol - pos);
            tooLong = false;
            pos = eol + 1;
            return true;
        },
        id);
}

EfficiencySession read_efficiency_session(std::istream& in, const std::string& id, std::uint64_t maxBytes) {
    StreamLines lines(in, maxBytes);
    EfficiencySession s = read_session_lines([&](std::string_view& line, bool& tooLong) { return lines.next(line, tooLong); }, id);
    if (lines.cut()) s.truncated = true;
    return s;
}

std::string efficiency_sessions_dir(const std::string& projectDir) {
    // Text only: the bytes of the project folder stay as the caller gave them (a round trip through a path changes them on Windows).
    std::string dir = projectDir;
#ifdef _WIN32
    std::replace(dir.begin(), dir.end(), '\\', '/');
#endif
    while (dir.size() > 1 && dir.back() == '/') dir.pop_back();
    return (dir.empty() ? std::string() : dir + "/") + ".factoria/ai/sessions";
}

std::vector<std::string> list_efficiency_sessions(const std::string& projectDir) {
    std::vector<std::string> names;
    std::error_code ec;
    for (const auto& e : stdfs::directory_iterator(fs::os_path(path_of_text(efficiency_sessions_dir(projectDir))), ec)) {
        std::error_code ec2;
        if (e.is_regular_file(ec2) && e.path().extension() == ".jsonl") names.push_back(u8text(e.path().stem()));
    }
    std::sort(names.begin(), names.end());
    return names;
}

Result<EfficiencySession> load_efficiency_session(const std::string& projectDir, const std::string& session, EfficiencyLoadBudget* budget) {
    std::string id = u8text(path_of_text(session).filename());
    if (ends_with(id, ".jsonl")) id.resize(id.size() - 6);
    const stdfs::path file = path_of_text(efficiency_sessions_dir(projectDir)) / path_of_text(id + ".jsonl");
    std::error_code ec;
    if (id.empty() || !stdfs::is_regular_file(fs::os_path(file), ec)) {
        const std::vector<std::string> names = list_efficiency_sessions(projectDir);
        return make_error("No session named '" + session + "' in " + efficiency_sessions_dir(projectDir) + ".",
                          names.empty() ? "No AI session was recorded in this project: sessions are written there while an agent runs (ai.run or the AI panel)."
                                        : did_you_mean(id, names) + " ai.session_timeline lists the newest one.");
    }
    const std::uintmax_t size = stdfs::file_size(fs::os_path(file), ec);
    const std::uint64_t maxFile = budget ? budget->maxFile : kEfficiencyMaxBytes;
    if (!ec && size > maxFile)
        return make_error("The session '" + id + "' is " + std::to_string(size / (1024 * 1024)) + " MB, more than the " +
                              std::to_string(maxFile / (1024 * 1024)) + " MB that are read for a measurement.",
                          "Point at a shorter session (the sessions of one request each), or delete the oldest ones in " + efficiency_sessions_dir(projectDir) + ".");
    // The budget is checked before the file is opened: a call that reads many sessions stays within kEfficiencyMaxTotalBytes in all.
    if (budget && !ec) {
        if (size > budget->bytesLeft)
            return make_error("The session '" + id + "' (" + std::to_string(size / (1024 * 1024)) + " MB) was not read: this call already read " +
                                  std::to_string((budget->total - budget->bytesLeft) / (1024 * 1024)) + " of the " +
                                  std::to_string(budget->total / (1024 * 1024)) + " MB it may read in all.",
                              "Name fewer or shorter sessions, or delete the oldest ones in " + efficiency_sessions_dir(projectDir) + ".");
        budget->bytesLeft -= size;
    }
    fs::ReadStream in(fs::os_path(file), std::ios::binary);
    if (!in) return make_error("Cannot read " + u8text(file) + ".", "Check that the file exists and that no other program has it locked.");
    return read_efficiency_session(in, id, maxFile);
}

// ------------------------------------------------------------------------------------------------------------- measuring --
EfficiencyMeasure& EfficiencyMeasure::operator+=(const EfficiencyMeasure& o) {
    steps += o.steps;
    toolCalls += o.toolCalls;
    minutes = round_to(minutes + o.minutes, 10);
    tokens += o.tokens;
    costUsd = round_to(costUsd + o.costUsd, 10000);
    estimated = estimated || o.estimated;
    return *this;
}

Json EfficiencyMeasure::to_json() const {
    return Json::object({{"steps", steps}, {"toolCalls", toolCalls}, {"minutes", round_to(minutes, 10)}, {"tokens", tokens},
                         {"costUsd", round_to(costUsd, 10000)}, {"estimated", estimated}});
}

EfficiencyMeasure EfficiencyMeasure::from_json(const Json& j) {
    EfficiencyMeasure m;
    if (!j.is_object()) return m;
    m.steps = jint(j, "steps");
    m.toolCalls = jint(j, "toolCalls");
    m.minutes = jamount(j, "minutes");
    m.tokens = juint(j, "tokens");
    m.costUsd = jamount(j, "costUsd");
    m.estimated = jbool(j, "estimated");
    return m;
}

Json EfficiencySpan::to_json() const {
    return Json::object({{"session", session}, {"fromStep", fromStep}, {"toStep", toStep}});
}

EfficiencyMeasure measure_span(const EfficiencySession& s, int fromStep, int toStep) {
    EfficiencyMeasure m;
    m.estimated = s.estimated;
    const int n = static_cast<int>(s.steps.size());
    fromStep = std::max(1, fromStep);
    toStep = std::min(toStep, n);
    if (n == 0 || fromStep > toStep) return m;
    for (int i = fromStep; i <= toStep; ++i) {
        const EfficiencyStep& st = s.steps[static_cast<std::size_t>(i - 1)];
        ++m.steps;
        m.toolCalls += static_cast<int>(st.calls.size());
        m.tokens += st.tokens;
        m.costUsd += st.costUsd;
    }
    const std::int64_t base = fromStep > 1 ? s.steps[static_cast<std::size_t>(fromStep - 2)].endMs : s.startMs;
    const std::int64_t end = s.steps[static_cast<std::size_t>(toStep - 1)].endMs;
    if (base > 0 && end >= base) m.minutes = std::round(static_cast<double>(end - base) / 6000.0) / 10.0;
    m.costUsd = round_to(m.costUsd, 10000);
    return m;
}

EfficiencyMeasure scale_measure(const EfficiencyMeasure& m, double share) {
    share = std::clamp(share, 0.0, 1.0);
    EfficiencyMeasure out;
    out.steps = static_cast<int>(std::lround(m.steps * share));
    out.toolCalls = static_cast<int>(std::lround(m.toolCalls * share));
    out.minutes = round_to(m.minutes * share, 10);
    out.tokens = static_cast<std::uint64_t>(std::llround(static_cast<double>(m.tokens) * share));
    out.costUsd = round_to(m.costUsd * share, 10000);
    out.estimated = m.estimated;
    return out;
}

// ---------------------------------------------------------------------------------------------------------------- tables --
const std::vector<std::string>& efficiency_fix_types() {
    static const std::vector<std::string> v = {"doc", "guide", "example", "commandOption", "newCommand", "engineChange"};
    return v;
}

const std::vector<std::string>& efficiency_applies_to() {
    static const std::vector<std::string> v = {"every-game", "genre", "feature", "this-game"};
    return v;
}

const std::vector<EfficiencyThreshold>& efficiency_thresholds() {
    static const std::vector<EfficiencyThreshold> v = {
        {"doc", 10, 100000, 0, false, false, "a section in an existing doc, or its title and keywords"},
        {"guide", 10, 100000, 0, false, false, "an on-demand topic guide (a skill), not text loaded on every step"},
        {"example", 15, 200000, 0, false, false, "an example project or scene to copy"},
        {"commandOption", 30, 500000, 0, true, false, "an option on a command that exists"},
        {"newCommand", 30, 500000, 0, true, false, "a command that does in one call what takes several"},
        {"engineChange", 60, 0, 5.0, true, true, "a change to the engine"},
    };
    return v;
}

namespace {

std::string number_text(double v) {
    char buf[32];
    std::snprintf(buf, sizeof buf, "%g", v);
    return buf;
}
std::string tokens_text(std::uint64_t t) {
    if (t >= 1000000 && t % 1000000 == 0) return number_text(static_cast<double>(t) / 1000000.0) + "M tokens";
    if (t >= 1000 && t % 1000 == 0) return number_text(static_cast<double>(t) / 1000.0) + "k tokens";
    return std::to_string(t) + " tokens";
}
std::string threshold_text(const EfficiencyThreshold& t) {
    std::vector<std::string> parts;
    if (t.minutes > 0) parts.push_back(number_text(t.minutes) + " minutes");
    if (t.tokens > 0) parts.push_back(tokens_text(t.tokens));
    if (t.costUsd > 0) parts.push_back("$" + number_text(t.costUsd));
    std::string out;
    for (std::size_t i = 0; i < parts.size(); ++i) out += (i ? " or " : "") + parts[i];
    return out;
}

}  // namespace

std::string efficiency_threshold_table() {
    std::string out = "| Fix type | Saving per game where it applies | Applies to | What the fix is |\n|---|---|---|---|\n";
    for (const EfficiencyThreshold& t : efficiency_thresholds()) {
        out += "| `" + t.fixType + "` | " + threshold_text(t) + " | " +
               (t.widerThanFeature ? "every game or a genre (wider than one feature)" : "any engine feature") + " | " + t.cost +
               (t.candidateOnly ? " (a candidate for triage)" : "") + " |\n";
    }
    return out;
}

// ------------------------------------------------------------------------------------------------------------------ gate --
namespace {

EfficiencyRefusal refuse(std::string code, std::string message, std::string hint) {
    return EfficiencyRefusal{std::move(code), std::move(message), std::move(hint)};
}

std::string lower_text(const std::string& s) { return to_lower(s); }

bool mentions(const std::string& lowerText, std::initializer_list<const char*> phrases) {
    for (const char* p : phrases)
        if (lowerText.find(p) != std::string::npos) return true;
    return false;
}

// The meets/misses of a saving against a fix type's threshold.
bool meets(const EfficiencyThreshold& t, const EfficiencyMeasure& saving) {
    if (t.minutes > 0 && saving.minutes >= t.minutes) return true;
    if (t.tokens > 0 && saving.tokens >= t.tokens) return true;
    if (t.costUsd > 0 && saving.costUsd >= t.costUsd) return true;
    return false;
}

const EfficiencyThreshold* threshold_of(const std::string& fixType) {
    for (const EfficiencyThreshold& t : efficiency_thresholds())
        if (t.fixType == fixType) return &t;
    return nullptr;
}

bool wider_than_feature(const std::string& appliesTo) { return appliesTo == "every-game" || appliesTo == "genre"; }

std::vector<std::string> significant_words(const std::string& text) {
    static const std::set<std::string> skip = {
        "the",  "and",   "for",  "with",  "guide", "docs", "doc",   "missing", "step",  "steps", "how",   "use",    "using", "takes", "took",
        "long", "many",  "tool", "tools", "call",  "calls", "read", "again",  "time",  "times", "every", "each",   "from",  "into",  "that",
        "this", "are",   "was",  "were",  "has",   "have", "need",  "needs",  "slow",  "too",   "new",   "add",    "fix",   "engine", "when",
        "than", "more",  "less", "which", "about", "does", "not",   "all",    "per",   "without", "wasted", "waste", "minutes", "tokens", "section"};
    std::vector<std::string> out;
    std::string cur;
    auto flush = [&] {
        if (cur.size() >= 3 && !skip.count(cur) && !std::all_of(cur.begin(), cur.end(), [](unsigned char c) { return std::isdigit(c) != 0; }) &&
            std::find(out.begin(), out.end(), cur) == out.end())
            out.push_back(cur);
        cur.clear();
    };
    for (char c : text) {
        const unsigned char u = static_cast<unsigned char>(c);
        if (std::isalnum(u)) cur += static_cast<char>(std::tolower(u));
        else flush();
    }
    flush();
    return out;
}

bool about_feedback(const DocHit& h) {
    return h.path.find("FEEDBACK") != std::string::npos || h.doc.find("feedback") != std::string::npos;
}

// A section whose heading (or document name) carries the report's own words: the report says there is no guide for it.
const DocHit* section_named_by(const std::vector<DocHit>& hits, const std::vector<std::string>& words) {
    if (words.empty()) return nullptr;
    for (const DocHit& h : hits) {
        if (about_feedback(h)) continue;
        const std::string heading = lower_text(h.heading + " " + h.doc);
        std::size_t matched = 0;
        for (const std::string& w : words) {
            // a plural or a longer form of the same word counts ("collision" ~ "collisions"); stems of 5+ characters only
            const std::string stem = w.size() > 5 ? w.substr(0, w.size() - 1) : w;
            if (heading.find(stem) != std::string::npos) ++matched;
        }
        const std::size_t need = std::max<std::size_t>(words.size() == 1 ? 1 : 2, (words.size() + 1) / 2);
        if (matched >= need) return &h;
    }
    return nullptr;
}

std::string describe_hit(const DocHit& h) {
    return h.path + ":" + std::to_string(h.line) + (h.heading.empty() ? std::string() : " (" + h.heading + ")");
}

// "a doc", "an engineChange": the fix type with its article.
std::string a_fix(const std::string& fixType, bool capital = false) {
    const bool vowel = !fixType.empty() && std::string("aeiou").find(fixType[0]) != std::string::npos;
    return std::string(capital ? (vowel ? "An " : "A ") : (vowel ? "an " : "a ")) + fixType;
}

std::string fix_types_text() {
    std::string out;
    for (const std::string& f : efficiency_fix_types()) out += (out.empty() ? "" : ", ") + f;
    return out;
}

}  // namespace

std::optional<EfficiencyRefusal> efficiency_input_from_json(const Json& args, EfficiencyInput& out) {
    auto text = [&](const char* key) { return std::string(trim(jstr(args, key))); };
    out.category = text("category");
    out.title = text("title");
    out.suggestion = text("suggestion");
    out.waste = text("waste");
    out.fixType = text("fixType");
    out.appliesTo = text("appliesTo");
    out.whyNotCheaper = text("whyNotCheaper");
    if (const Json* c = jchild(args, "everyStepTokens")) {
        if (!c->is_number() || !(c->get<double>() >= 0))
            return refuse("invalid_argument", "/everyStepTokens must be a number of tokens (0 or more).",
                          "It is the size, in tokens, of the text the fix adds to EVERY step of every run (AGENTS.md, the system prompt). Leave it out for a fix read only on demand.");
        out.everyStepTokens = static_cast<std::uint64_t>(std::min(c->get<double>(), 1e12));  // times the steps of a run below: stays far from the 64-bit limit
    }
    if (const Json* c = jchild(args, "searched")) {
        if (c->is_string()) {
            out.searched.push_back(std::string(trim(c->get<std::string>())));
        } else if (c->is_array()) {
            for (std::size_t i = 0; i < c->size(); ++i) {
                if (!(*c)[i].is_string())
                    return refuse("invalid_argument", "/searched/" + std::to_string(i) + " must be a string.",
                                  "List the words you gave docs.search, one string each.");
                out.searched.push_back(std::string(trim((*c)[i].get<std::string>())));
            }
        } else {
            return refuse("invalid_argument", "/searched must be a list of strings.", "List the words you gave docs.search, one string each.");
        }
        out.searched.erase(std::remove_if(out.searched.begin(), out.searched.end(), [](const std::string& s) { return s.empty(); }),
                           out.searched.end());
    }
    if (const Json* e = jchild(args, "expectedSaving")) {
        if (!e->is_object() || !jchild(*e, "share") || !jchild(*e, "share")->is_number())
            return refuse("invalid_argument", "/expectedSaving must be {share, why}: share a number from 0.01 to 1.",
                          "Example: {\"share\":0.7,\"why\":\"the guide gives the three calls that took the other 30 steps to find\"}.");
        out.saveShare = (*e)["share"].get<double>();
        out.saveWhy = std::string(trim(jstr(*e, "why")));
    }
    const Json* ev = jchild(args, "evidence");
    if (ev) {
        if (!ev->is_array())
            return refuse("invalid_argument", "/evidence must be a list of spans [{session, fromStep, toStep}].",
                          "Name the steps where the waste happened, from ai.session_timeline or the transcript in .factoria/ai/sessions.");
        for (std::size_t i = 0; i < ev->size(); ++i) {
            const Json& span = (*ev)[i];
            const std::string at = "/evidence/" + std::to_string(i);
            if (!span.is_object())
                return refuse("invalid_argument", at + " must be {session, fromStep, toStep}.", "Example: {\"session\":\"20261014-153012-main\",\"fromStep\":12,\"toStep\":52}.");
            EfficiencySpan sp;
            sp.session = std::string(trim(jstr(span, "session")));
            for (const char* key : {"fromStep", "toStep"}) {
                const Json* n = jchild(span, key);
                if (!n || !n->is_number_integer())
                    return refuse("invalid_argument", at + "/" + key + " must be a whole number (steps count from 1).",
                                  "Steps are the model calls of the transcript, numbered from 1 (the `steps` of ai.session_timeline's `context`).");
                (std::string(key) == "fromStep" ? sp.fromStep : sp.toStep) = n->get<int>();
            }
            out.evidence.push_back(std::move(sp));
        }
    }
    return std::nullopt;
}

std::optional<EfficiencyRefusal> check_efficiency_report(const std::string& projectDir, const EfficiencyInput& in, EfficiencyVerdict& verdict) {
    // ---- the words of the report
    if (!contains_string(efficiency_fix_types(), in.fixType))
        return refuse("invalid_argument",
                      "/fixType '" + in.fixType + "' is not a fix type. " + did_you_mean(in.fixType, efficiency_fix_types()),
                      "Pick the cheapest fix that removes the waste: " + fix_types_text() + " (cheapest first).");
    if (std::count_if(in.waste.begin(), in.waste.end(), [](unsigned char c) { return std::isspace(c) != 0; }) < 3)
        return refuse("invalid_argument", "/waste is missing or too short: say in engine terms what took the time.",
                      "Example: \"Understanding how Tilemap layers map to collision took 40 steps of reading components and trying values.\"");
    if (std::count_if(in.suggestion.begin(), in.suggestion.end(), [](unsigned char c) { return std::isspace(c) != 0; }) < 2)
        return refuse("invalid_argument", "/suggestion is missing: the fix is part of the report.",
                      "Say the doc section, guide, example, command option or command that would have removed the waste, in a sentence.");
    if (!contains_string(efficiency_applies_to(), in.appliesTo))
        return refuse("invalid_argument", "/appliesTo '" + in.appliesTo + "' is not one of every-game, genre, feature, this-game. " +
                                              did_you_mean(in.appliesTo, efficiency_applies_to()),
                      "every-game: any game would hit it; genre: games of one kind (say which in the waste); feature: one engine feature; this-game: only this project.");
    if (in.appliesTo == "this-game")
        return refuse("project_fact",
                      "/appliesTo is this-game: a lesson that is true only for this game is not engine feedback.",
                      "Record it as a project fact instead (the retrospective proposes them; `ai.savers` shows savers.projectFacts, and AGENTS.md \"Project facts\" is where they live), so every later run of this game starts knowing it.");
    const std::string lowered = lower_text(in.title + " . " + in.waste + " . " + in.suggestion);
    if (mentions(lowered, {"cheaper model", "smaller model", "faster model", "different model", "switch model", "switch to haiku", "use haiku",
                           "use sonnet", "use opus", "lower effort", "reduce effort", "less effort", "effort level", "reasoning effort",
                           "thinking budget", "turn limit", "token limit", "cost limit", "token budget", "cost budget", "run budget",
                           "raise the limit", "raise limits", "lower the limit", "max tokens", "max turns"}))
        return refuse("user_setting",
                      "The report asks for a different model, effort or limit: those are the user's settings, not engine feedback.",
                      "The retrospective can suggest them to the user (ai.settings, the AI panel); an efficiency entry is about what the ENGINE could do so that any model needs fewer steps.");
    if (in.saveShare < 0.01 || in.saveShare > 1)
        return refuse("invalid_argument", "/expectedSaving/share must be between 0.01 and 1: the share of the measured span that the fix removes.",
                      "0.5 means half of the measured steps, minutes and tokens would not have been needed.");
    if (std::count_if(in.saveWhy.begin(), in.saveWhy.end(), [](unsigned char c) { return std::isspace(c) != 0; }) < 2)
        return refuse("invalid_argument", "/expectedSaving/why is missing: one line on why the fix removes that share.",
                      "Say what the AI would have read or called once instead of what it did in the span.");
    const bool beyondDocs = in.fixType == "commandOption" || in.fixType == "newCommand" || in.fixType == "engineChange";
    if (beyondDocs && std::count_if(in.whyNotCheaper.begin(), in.whyNotCheaper.end(), [](unsigned char c) { return std::isspace(c) != 0; }) < 4)
        return refuse("not_cheapest",
                      "/whyNotCheaper is missing: the cheapest fix that removes the waste wins, and " + a_fix(in.fixType) + " is not the cheapest.",
                      "Say why a doc section, a topic guide and an example would not have removed the waste (the order is " + fix_types_text() + ").");

    // ---- the evidence: measured, not guessed
    if (in.evidence.empty())
        return refuse("no_evidence", "/evidence is missing: the engine measures the waste from the transcript, so name the span.",
                      "Give [{session, fromStep, toStep}] for the steps where the waste happened. ai.session_timeline shows the steps of a session; the transcripts are in " +
                          efficiency_sessions_dir(projectDir) + ".");
    if (in.evidence.size() > 10)
        return refuse("invalid_argument", "/evidence has " + std::to_string(in.evidence.size()) + " spans; at most 10.",
                      "Name the 10 longest ones, or join consecutive steps into one span.");
    std::map<std::string, EfficiencySession> sessions;
    std::map<std::string, std::vector<std::pair<int, int>>> taken;
    EfficiencyLoadBudget budget;  // the spans name at most 10 sessions: together they are read within the total limit
    verdict = EfficiencyVerdict{};
    for (std::size_t i = 0; i < in.evidence.size(); ++i) {
        const EfficiencySpan& sp = in.evidence[i];
        const std::string at = "/evidence/" + std::to_string(i);
        std::string id = u8text(path_of_text(sp.session).filename());
        if (ends_with(id, ".jsonl")) id.resize(id.size() - 6);
        auto found = sessions.find(id);
        if (found == sessions.end()) {
            auto loaded = load_efficiency_session(projectDir, id, &budget);
            if (!loaded.ok()) return refuse("no_evidence", at + "/session: " + loaded.error().message, loaded.error().hint);
            found = sessions.emplace(id, std::move(loaded.value())).first;
        }
        const EfficiencySession& s = found->second;
        const int n = static_cast<int>(s.steps.size());
        if (sp.fromStep < 1 || sp.toStep < sp.fromStep || sp.toStep > n)
            return refuse("no_evidence",
                          at + " asks for steps " + std::to_string(sp.fromStep) + ".." + std::to_string(sp.toStep) + " but session '" + id + "' has " +
                              std::to_string(n) + " steps" + (s.agent == "cli" ? " (a step of a CLI agent is one model turn)" : "") + ".",
                          n == 0 ? "That transcript has no model steps; point at another session."
                                 : "fromStep is at least 1, toStep at least fromStep and at most " + std::to_string(n) + ".");
        for (const auto& [a, b] : taken[id])
            if (sp.fromStep <= b && sp.toStep >= a)
                return refuse("invalid_argument",
                              at + " overlaps another span of session '" + id + "' (steps " + std::to_string(a) + ".." + std::to_string(b) +
                                  "): the same steps would be counted twice.",
                              "Join them into one span, or make them not overlap.");
        taken[id].push_back({sp.fromStep, sp.toStep});
        verdict.evidence.push_back({id, sp.fromStep, sp.toStep});
        verdict.spanMeasures.push_back(measure_span(s, sp.fromStep, sp.toStep));
        verdict.measured += verdict.spanMeasures.back();
    }
    verdict.saving = scale_measure(verdict.measured, in.saveShare);

    // ---- text loaded on every step costs on every step
    const std::string suggestionLower = lower_text(in.suggestion + " " + in.waste);
    if (in.everyStepTokens == 0 &&
        mentions(suggestionLower, {"agents.md", "claude.md", "system prompt", "every step", "every run", "always loaded", "always load"})) {
        return refuse("costs_every_step",
                      "/suggestion puts text where it is loaded on every step of every run (AGENTS.md or the system prompt), and /everyStepTokens does not say how much.",
                      "Give everyStepTokens (the size of that text in tokens): the fix must save more than it adds on every step. Most fixes belong in an on-demand topic guide (a skill) instead: fixType guide.");
    }
    if (in.everyStepTokens > 0) {
        std::uint64_t allSteps = 0;
        for (const auto& [id, s] : sessions) allSteps += s.steps.size();
        const std::uint64_t added = in.everyStepTokens * allSteps;
        if (verdict.saving.tokens <= added)
            return refuse("costs_every_step",
                          "The fix adds " + std::to_string(in.everyStepTokens) + " tokens to every step: over the " + std::to_string(allSteps) +
                              " steps of the named sessions that is " + std::to_string(added) + " tokens, and it saves " +
                              std::to_string(verdict.saving.tokens) + ".",
                          "Text loaded on every step must save more than it adds. Make it an on-demand topic guide (fixType guide, everyStepTokens 0) or shorten it.");
    }

    // ---- "a guide is missing" for a doc that docs.search finds
    if (in.fixType == "doc" || in.fixType == "guide") {
        std::vector<DocHit> hits;
        std::vector<std::string> words = significant_words(in.title);
        const std::vector<std::string> sw = significant_words(in.suggestion);
        for (const std::string& w : sw)
            if (words.size() < 8 && std::find(words.begin(), words.end(), w) == words.end()) words.push_back(w);
        std::string query;
        for (const std::string& w : words) query += (query.empty() ? "" : " ") + w;
        if (!query.empty()) hits = search_docs(query, 12);
        const DocHit* existing = section_named_by(hits, significant_words(in.title));
        if (!existing) existing = section_named_by(hits, sw);
        if (existing) {
            const std::string where = describe_hit(*existing);
            if (in.searched.empty())
                return refuse("exists_in_docs",
                              "The docs already have a section that carries the words of this report: " + where + ". A \"missing guide\" for something docs.search finds is not a missing guide.",
                              "Read it. If you did and it did not help, say what is missing from it. If you could not FIND it, this is a findability report: list in /searched the words you gave docs.search (they must not find this section), and make the fix the title and keywords of " +
                                  where + ".");
            for (std::size_t i = 0; i < in.searched.size(); ++i) {
                const std::vector<DocHit> top = search_docs(in.searched[i], 5);
                for (std::size_t k = 0; k < top.size(); ++k)
                    if (top[k].path == existing->path && top[k].heading == existing->heading)
                        return refuse("exists_in_docs",
                                      "/searched/" + std::to_string(i) + " ('" + in.searched[i] + "') finds " + where + " as result " + std::to_string(k + 1) +
                                          " of docs.search: the section is findable with those words.",
                                      "Read the section. A findability report needs words that docs.search does not answer with it.");
            }
            verdict.existingDoc = where;
        }
    }

    // ---- the saving against the threshold of the fix
    const EfficiencyThreshold* th = threshold_of(in.fixType);
    verdict.candidateOnly = th && th->candidateOnly;
    if (th && th->widerThanFeature && !wider_than_feature(in.appliesTo))
        return refuse("below_threshold",
                      a_fix(in.fixType, true) + " is justified only for waste that every game or a genre meets; /appliesTo is " + in.appliesTo + ".",
                      "Say appliesTo every-game or genre if it is true, else use a doc section or an example for this one feature (" +
                          threshold_text(*threshold_of("doc")) + " per game).");
    if (th && !meets(*th, verdict.saving)) {
        std::string ok;
        for (const EfficiencyThreshold& t : efficiency_thresholds())
            if (meets(t, verdict.saving) && (!t.widerThanFeature || wider_than_feature(in.appliesTo))) ok += (ok.empty() ? "" : ", ") + t.fixType;
        char saved[160];
        std::snprintf(saved, sizeof saved, "%.1f minutes, %llu tokens, $%.2f", verdict.saving.minutes,
                      static_cast<unsigned long long>(verdict.saving.tokens), verdict.saving.costUsd);
        return refuse("below_threshold",
                      std::string("The saving is ") + saved + " per game (the measured span times /expectedSaving/share" +
                          (verdict.measured.estimated ? "; tokens are estimated from bytes, the cost of a CLI agent is not known" : "") +
                          "); " + a_fix(in.fixType) + " is justified from " + threshold_text(*th) + ".",
                      ok.empty() ? "Not worth filing. Waste this small is part of how the work goes; it is not engine feedback. (An engine change goes on the roadmap only when the reports add up to $" +
                                       number_text(kEfficiencyRoadmapUsd) + " or " + number_text(kEfficiencyRoadmapHours) + " hours across games.)"
                                 : "This saving justifies: " + ok + ". Would one of those remove the waste? If so report that fix; if not, it is not worth filing.");
    }
    return std::nullopt;
}

// ---------------------------------------------------------------------------------------------- Claude Code stream-json --
namespace {
// "error: unknown_command: Unknown command 'x'" (what `factoria` prints on exit 1, alone or after other output): the code word, or "".
std::string cli_error_code(const std::string& text) {
    std::size_t at = 0;
    if (text.rfind("error: ", 0) == 0) {
        at = 7;
    } else {
        at = text.find("\nerror: ");
        if (at == std::string::npos) return {};
        at += 8;
    }
    std::size_t end = at;
    while (end < text.size() && (std::islower(static_cast<unsigned char>(text[end])) || text[end] == '_' || std::isdigit(static_cast<unsigned char>(text[end])))) ++end;
    if (end == at || end >= text.size() || text[end] != ':') return {};
    return text.substr(at, end - at);
}
// The text of a tool_result block's content (a string, or [{type:"text", text}]).
std::string stream_result_text(const Json& block) {
    const Json* c = jchild(block, "content");
    if (!c) return {};
    if (c->is_string()) return c->get<std::string>();
    std::string out;
    if (c->is_array())
        for (const Json& p : *c) out += jstr(p, "text");
    return out;
}
}  // namespace

EfficiencySession read_claude_stream_session(const std::string& text, const std::string& id) {
    EfficiencySession s;
    s.id = id;
    s.agent = "cli";
    std::map<std::string, std::pair<std::size_t, std::size_t>> pending;  // tool_use id -> (step, call)
    std::string lastMessage;
    std::uint64_t in = 0, out = 0, cw = 0, cr = 0;  // the usage of the step being read: the largest each field reached
    auto close_step = [&]() {
        if (!s.steps.empty()) s.steps.back().tokens = in + out + cw + cr;
        in = out = cw = cr = 0;
    };
    std::size_t pos = 0;
    while (pos < text.size()) {
        std::size_t eol = text.find('\n', pos);
        if (eol == std::string::npos) eol = text.size();
        const std::size_t len = eol - pos;
        const Json j = len > kEfficiencyMaxLine ? Json() : Json::parse(text.begin() + static_cast<std::ptrdiff_t>(pos), text.begin() + static_cast<std::ptrdiff_t>(eol), nullptr, false);
        pos = eol + 1;
        if (!j.is_object()) { if (len > 0) ++s.skippedLines; continue; }
        std::int64_t t = 0;
        if (parse_iso_utc_ms(jstr(j, "timestamp"), t) && t > 0) {
            if (s.startMs == 0) s.startMs = t;
            s.hasTimes = true;
        }
        const std::string type = jstr(j, "type");
        const Json* msg = jchild(j, "message");
        if (type == "assistant" && msg) {
            const std::string mid = jstr(*msg, "id");
            if (s.steps.empty() || mid.empty() || mid != lastMessage) {
                if (static_cast<int>(s.steps.size()) >= kEfficiencyMaxSteps) { s.truncated = true; break; }
                close_step();
                EfficiencyStep st;
                st.number = static_cast<int>(s.steps.size()) + 1;
                st.endMs = t > 0 ? t : (s.steps.empty() ? 0 : s.steps.back().endMs);
                s.steps.push_back(std::move(st));
                lastMessage = mid;
            }
            EfficiencyStep& st = s.steps.back();
            if (t > 0) st.endMs = t;
            if (const Json* u = jchild(*msg, "usage"); u && u->is_object()) {
                in = std::max(in, juint(*u, "input_tokens"));
                out = std::max(out, juint(*u, "output_tokens"));
                cw = std::max(cw, juint(*u, "cache_creation_input_tokens"));
                cr = std::max(cr, juint(*u, "cache_read_input_tokens"));
            }
            const Json* content = jchild(*msg, "content");
            if (content && content->is_array()) {
                for (const Json& b : *content) {
                    if (jstr(b, "type") != "tool_use") continue;
                    EfficiencyToolCall call;
                    call.id = jstr(b, "id");
                    call.name = jstr(b, "name");
                    resolve_cli_call(call, b.contains("input") ? b["input"] : Json::object());
                    st.calls.push_back(std::move(call));
                    if (!st.calls.back().id.empty()) pending[st.calls.back().id] = {s.steps.size() - 1, st.calls.size() - 1};
                }
            }
        } else if (type == "user" && msg) {
            const Json* content = jchild(*msg, "content");
            if (!content || !content->is_array()) continue;
            for (const Json& b : *content) {
                if (jstr(b, "type") != "tool_result") continue;
                auto it = pending.find(jstr(b, "tool_use_id"));
                if (it == pending.end() || it->second.first >= s.steps.size()) continue;
                EfficiencyStep& st = s.steps[it->second.first];
                EfficiencyToolCall& call = st.calls[it->second.second];
                const std::string result = stream_result_text(b);
                call.resultBytes = result.size();
                const Json* err = jchild(b, "is_error");
                call.failed = err && err->is_boolean() && err->get<bool>();
                if (call.failed) {
                    call.code = cli_error_code(result);
                    if (call.code.empty()) call.code = code_of_text(result);
                }
                if (t > 0) st.endMs = std::max(st.endMs, t);
            }
        }
    }
    close_step();
    std::int64_t prev = s.startMs;
    for (EfficiencyStep& st : s.steps) {
        if (st.endMs < prev) st.endMs = prev;
        prev = st.endMs;
    }
    return s;
}

}  // namespace fa
