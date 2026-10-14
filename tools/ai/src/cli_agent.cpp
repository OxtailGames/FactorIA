#include "fa/ai/cli_agent.h"

#include <algorithm>
#include <ctime>
#include <filesystem>
#include <fstream>

#include "fa/core/strings.h"
#include "util.h"

namespace fa::ai {

using namespace util;
namespace fsys = std::filesystem;

std::string cli_install_hint(const ProviderConfig& cfg) {
    switch (cfg.kind) {
        case ProviderKind::ClaudeCode:
            return "Install Claude Code: npm i -g @anthropic-ai/claude-code, then run `claude` once to log in.";
        case ProviderKind::Codex:
            return "Install Codex: npm i -g @openai/codex, then run `codex` once (or `codex login`) to sign in with ChatGPT.";
        default:
            return "Install the CLI '" + cfg.command + "' and make sure it is on PATH (see \"command\" for provider '" +
                   cfg.name + "' in ~/.factoria/ai.json).";
    }
}

bool looks_like_auth_failure(std::string_view text) {
    std::string t = lower(std::string(text));
    for (const char* p : {"not logged in", "please run /login", "run `claude` to log in", "invalid api key",
                          "authentication_error", "authentication failed", "not authenticated", "please log in",
                          "please login", "codex login", "401 unauthorized", "unauthorized", "log in to continue",
                          "sign in", "token expired", "credentials"}) {
        if (t.find(p) != std::string::npos) return true;
    }
    return false;
}

Json make_mcp_config(const std::string& projectDir, const std::string& factoriaCommand) {
    return Json::object(
        {{"mcpServers",
          Json::object({{"factoria", Json::object({{"command", factoriaCommand},
                                                   {"args", Json::array({"mcp", "--project", projectDir})}})}})}});
}

std::vector<std::string> expand_cli_argv(const std::vector<std::string>& tmpl, const CliRunRequest& req,
                                         const std::string& mcpConfigPath, const std::string& factoriaCommand) {
    struct Sub {
        const char* key;
        std::string value;
    };
    const Sub subs[] = {{"{prompt}", req.prompt},
                        {"{model}", req.model},
                        {"{project}", req.projectDir},
                        {"{mcp_config}", mcpConfigPath},
                        {"{session}", req.sessionId},
                        {"{project_json}", dump(Json(req.projectDir))},
                        {"{factoria_json}", dump(Json(factoriaCommand))},
                        {"{factoria}", factoriaCommand}};
    std::vector<std::string> out;
    for (const auto& el : tmpl) {
        std::string s = el;
        bool emptyPlaceholder = false;
        bool hadPlaceholder = false;
        for (const auto& sub : subs) {
            std::string key = sub.key;
            if (s.find(key) == std::string::npos) continue;
            hadPlaceholder = true;
            if (sub.value.empty() && (key == "{model}" || key == "{mcp_config}" || key == "{session}")) emptyPlaceholder = true;
            s = fa::replace_all(std::move(s), key, sub.value);
        }
        if (emptyPlaceholder) {
            if (!out.empty() && out.back().size() > 1 && out.back()[0] == '-' && out.back().find('{') == std::string::npos &&
                out.back().find('=') == std::string::npos) {
                out.pop_back();
            }
            continue;
        }
        (void)hadPlaceholder;
        out.push_back(std::move(s));
    }
    return out;
}

bool cli_supports_resume(const ProviderConfig& cfg) {
    const std::vector<std::string> tmpl = cfg.argv.empty() ? default_cli_argv(cfg.kind) : cfg.argv;
    return std::any_of(tmpl.begin(), tmpl.end(), [](const std::string& a) { return a.find("{session}") != std::string::npos; });
}

bool argv_wants_stream_json_input(const std::vector<std::string>& argv) {
    for (std::size_t i = 0; i < argv.size(); ++i) {
        if (argv[i] == "--input-format" && i + 1 < argv.size() && argv[i + 1] == "stream-json") return true;
        if (argv[i] == "--input-format=stream-json") return true;
    }
    return false;
}

std::string make_stream_json_input(const std::string& text, const std::vector<ImageData>& images) {
    Json content = Json::array();
    content.push_back(Json::object({{"type", "text"}, {"text", text}}));
    for (const auto& img : images) {
        content.push_back(Json::object(
            {{"type", "image"},
             {"source", Json::object({{"type", "base64"}, {"media_type", img.mediaType}, {"data", img.base64}})}}));
    }
    Json msg = Json::object({{"type", "user"}, {"message", Json::object({{"role", "user"}, {"content", content}})}});
    return dump(msg);  // compact: exactly one line
}

std::string prompt_with_image_paths(const std::string& prompt, const std::vector<std::string>& paths) {
    if (paths.empty()) return prompt;
    std::string out = prompt + "\n\nAttached images (read them): ";
    for (std::size_t i = 0; i < paths.size(); ++i) out += (i ? ", " : "") + paths[i];
    return out;
}

static std::string limit_name_for_minutes(double minutes, const std::string& fallback) {
    const long m = static_cast<long>(minutes + 0.5);
    if (m <= 0) return fallback;
    if (m == 300) return "five_hour";
    if (m == 10080) return "seven_day";
    if (m % 1440 == 0) return std::to_string(m / 1440) + "_day";
    if (m % 60 == 0) return std::to_string(m / 60) + "_hour";
    return std::to_string(m) + "_minute";
}

std::vector<LimitWindow> parse_codex_rate_limits(const Json& rateLimits, i64 now) {
    std::vector<LimitWindow> out;
    if (!rateLimits.is_object()) return out;
    for (const auto& [key, w] : rateLimits.items()) {
        if (!w.is_object()) continue;
        LimitWindow lw;
        lw.name = limit_name_for_minutes(num(w, "window_minutes"), key);
        if (w.contains("used_percent") && w["used_percent"].is_number()) {
            lw.usedFraction = std::clamp(num(w, "used_percent") / 100.0, 0.0, 1.0);
        }
        if (w.contains("resets_at") && w["resets_at"].is_number()) lw.resetsAt = static_cast<i64>(num(w, "resets_at"));
        else if (w.contains("resets_in_seconds") && w["resets_in_seconds"].is_number())
            lw.resetsAt = now + static_cast<i64>(num(w, "resets_in_seconds"));
        out.push_back(std::move(lw));
    }
    return out;
}

// ---------------------------------------------------------------------------
// Stream parsing

static std::string summarize_content(const Json& c) {
    if (c.is_string()) return c.get<std::string>();
    if (c.is_array()) {
        std::string out;
        for (const auto& b : c) {
            if (b.is_object() && str(b, "type") == "text") out += str(b, "text");
            else if (b.is_object() && str(b, "type") == "image") out += "[image]";
        }
        return out;
    }
    return c.is_null() ? std::string() : dump(c);
}

static std::string clip(std::string s, std::size_t n = 2000) {
    if (s.size() > n) { s.resize(n); s += "..."; }
    return s;
}

void CliStreamParser::feed_line(std::string_view line, std::vector<AgentEvent>& out) {
    if (fa::trim(line).empty()) return;
    Json j;
    if (kind_ != ProviderKind::GenericCli || line.front() == '{') j = parse(line);
    else j = Json::value_t::discarded;
    if (j.is_discarded() || !j.is_object()) {
        // Unknown lines pass through as text.
        AgentEvent e;
        e.type = AgentEvent::Type::TextDelta;
        e.text = std::string(line) + "\n";
        out.push_back(e);
        if (kind_ == ProviderKind::GenericCli) finalText_ += e.text;
        return;
    }
    if (kind_ == ProviderKind::ClaudeCode) feed_claude(j, out);
    else if (kind_ == ProviderKind::Codex) feed_codex(j, out);
    else {
        // generic: best effort on common field names
        std::string text;
        for (const char* k : {"text", "result", "message", "content"}) {
            text = str(j, k);
            if (!text.empty()) break;
        }
        AgentEvent e;
        e.type = AgentEvent::Type::TextDelta;
        e.text = (text.empty() ? std::string(line) : text) + "\n";
        out.push_back(e);
        finalText_ += e.text;
    }
}

// The UI-facing snapshot: cumulative usage + cost, the context numbers known so far, and `limits` when the CLI just
// reported some. (A consumer applies what is non-empty.)
void CliStreamParser::usage_event(std::vector<AgentEvent>& out, std::vector<LimitWindow> limits) const {
    AgentEvent e;
    e.type = AgentEvent::Type::Usage;
    e.usage = usage_;
    e.costUsd = costUsd_;
    e.limits = std::move(limits);
    e.contextTokens = contextTokens_;
    e.contextWindow = contextWindow_;
    out.push_back(std::move(e));
}

void merge_limit_windows(std::vector<LimitWindow>& into, const std::vector<LimitWindow>& from) {
    for (const auto& w : from) {
        auto it = std::find_if(into.begin(), into.end(), [&](const LimitWindow& l) { return l.name == w.name; });
        if (it == into.end()) into.push_back(w);
        else *it = w;
    }
}

// Claude Code: {"rate_limit_info": {"unifiedWindows": {"five_hour": {"utilization": 0.06, "resetsAt": 1792021800}, ...}}}.
// Every entry is taken (the CLI may add windows); without unifiedWindows the top-level window is used.
static std::vector<LimitWindow> parse_claude_rate_limits(const Json& info) {
    std::vector<LimitWindow> out;
    auto window = [](const std::string& name, const Json& w) {
        LimitWindow lw;
        lw.name = name;
        if (w.contains("utilization") && w["utilization"].is_number()) lw.usedFraction = std::clamp(num(w, "utilization"), 0.0, 1.0);
        lw.resetsAt = static_cast<i64>(num(w, "resetsAt"));
        return lw;
    };
    if (const Json* uw = child(info, "unifiedWindows"); uw && uw->is_object()) {
        for (const auto& [name, w] : uw->items()) {
            if (w.is_object()) out.push_back(window(name, w));
        }
    }
    if (out.empty() && !str(info, "rateLimitType").empty()) out.push_back(window(str(info, "rateLimitType"), info));
    return out;
}

void CliStreamParser::feed_claude(const Json& j, std::vector<AgentEvent>& out) {
    const std::string type = str(j, "type");
    if (type == "rate_limit_event") {
        const Json* info = child(j, "rate_limit_info");
        std::vector<LimitWindow> windows = info ? parse_claude_rate_limits(*info) : std::vector<LimitWindow>{};
        if (windows.empty()) return;
        merge_limit_windows(limits_, windows);
        usage_event(out, std::move(windows));
        return;
    }
    if (type == "system") {
        if (str(j, "subtype") == "init") {
            sessionId_ = str(j, "session_id");
            AgentEvent e;
            e.type = AgentEvent::Type::Info;
            e.text = "Claude Code started" + (str(j, "model").empty() ? std::string() : " (model " + str(j, "model") + ")");
            if (const Json* mcp = child(j, "mcp_servers"); mcp && mcp->is_array()) {
                for (const auto& s : *mcp) {
                    std::string status = str(s, "status");
                    if (!status.empty() && status != "connected") {
                        e.text += "; MCP server '" + str(s, "name") + "' is " + status + " (is `factoria` on PATH?)";
                    }
                }
            }
            out.push_back(e);
        }
    } else if (type == "assistant") {
        const Json* msg = child(j, "message");
        // Context in use = the prompt of the model's last call (input + cache). A sub-agent's calls have their own context.
        const Json* parent = child(j, "parent_tool_use_id");
        const bool fromSubAgent = parent && parent->is_string() && !parent->get<std::string>().empty();
        if (const Json* u = msg ? child(*msg, "usage") : nullptr; u && u->is_object() && !fromSubAgent) {
            const u64 ctx = static_cast<u64>(num(*u, "input_tokens")) + static_cast<u64>(num(*u, "cache_creation_input_tokens")) +
                            static_cast<u64>(num(*u, "cache_read_input_tokens"));
            if (ctx > 0 && ctx != contextTokens_) {
                contextTokens_ = ctx;
                usage_event(out);
            }
        }
        const Json* content = msg ? child(*msg, "content") : nullptr;
        if (!content || !content->is_array()) return;
        for (const auto& b : *content) {
            std::string bt = str(b, "type");
            if (bt == "text") {
                AgentEvent e;
                e.type = AgentEvent::Type::TextDelta;
                e.text = str(b, "text");
                out.push_back(e);
            } else if (bt == "tool_use") {
                AgentEvent e;
                e.type = AgentEvent::Type::ToolStart;
                e.toolName = str(b, "name");
                if (const Json* in = child(b, "input")) e.toolInput = *in;
                toolNames_[str(b, "id")] = e.toolName;
                out.push_back(e);
            } else if (bt == "thinking") {
                AgentEvent e;
                e.type = AgentEvent::Type::ThinkingDelta;
                e.text = str(b, "thinking");
                out.push_back(e);
            }
        }
    } else if (type == "user") {
        const Json* msg = child(j, "message");
        const Json* content = msg ? child(*msg, "content") : nullptr;
        if (!content || !content->is_array()) return;
        for (const auto& b : *content) {
            if (str(b, "type") != "tool_result") continue;
            AgentEvent e;
            e.type = AgentEvent::Type::ToolEnd;
            e.toolName = toolNames_[str(b, "tool_use_id")];
            e.isError = flag(b, "is_error");
            if (const Json* c = child(b, "content")) e.toolResult = clip(summarize_content(*c));
            out.push_back(e);
        }
    } else if (type == "result") {
        sawResult_ = true;
        resultIsError_ = flag(j, "is_error") || (str(j, "subtype") != "success" && !str(j, "subtype").empty());
        std::string result = str(j, "result");
        if (resultIsError_ && result.empty()) {
            // error_during_execution has no `result`; its reasons are in `errors` ("No conversation found with session ID: ...").
            if (const Json* errs = child(j, "errors"); errs && errs->is_array()) {
                for (const auto& er : *errs) result += (result.empty() ? "" : "; ") + (er.is_string() ? er.get<std::string>() : dump(er));
            }
        }
        if (resultIsError_) errorText_ = result.empty() ? str(j, "subtype") : result;
        else finalText_ = result;
        costUsd_ = num(j, "total_cost_usd", num(j, "cost_usd"));
        // The context window comes with the totals per model; the main model is the one that used the most tokens.
        if (const Json* mu = child(j, "modelUsage"); mu && mu->is_object()) {
            double best = -1;
            for (const auto& [model, m] : mu->items()) {
                if (!m.is_object() || num(m, "contextWindow") <= 0) continue;
                const double used = num(m, "inputTokens") + num(m, "outputTokens") + num(m, "cacheReadInputTokens") +
                                    num(m, "cacheCreationInputTokens");
                if (used > best) {
                    best = used;
                    contextWindow_ = static_cast<u64>(num(m, "contextWindow"));
                }
            }
        }
        turns_ = static_cast<int>(num(j, "num_turns"));
        if (std::string sid = str(j, "session_id"); !sid.empty()) sessionId_ = sid;
        if (const Json* u = child(j, "usage")) {
            usage_.inputTokens = static_cast<u64>(num(*u, "input_tokens"));
            usage_.outputTokens = static_cast<u64>(num(*u, "output_tokens"));
            usage_.cacheCreationTokens = static_cast<u64>(num(*u, "cache_creation_input_tokens"));
            usage_.cacheReadTokens = static_cast<u64>(num(*u, "cache_read_input_tokens"));
        }
        usage_event(out);
    }
}

void CliStreamParser::feed_codex(const Json& j, std::vector<AgentEvent>& out) {
    // Plan windows: legacy events carry them in msg.rate_limits (token_count), newer ones may carry the same object at the
    // top level or in `payload`, on any event.
    for (const char* holder : {"", "msg", "payload"}) {
        const Json* h = *holder ? child(j, holder) : &j;
        const Json* rl = h ? child(*h, "rate_limits") : nullptr;
        if (!rl || !rl->is_object()) continue;
        std::vector<LimitWindow> windows = parse_codex_rate_limits(*rl, static_cast<i64>(std::time(nullptr)));
        if (windows.empty()) continue;
        merge_limit_windows(limits_, windows);
        usage_event(out, std::move(windows));
        break;
    }
    std::string type = str(j, "type");
    // Older format wraps events as {"id": "..", "msg": {"type": ..}}.
    const Json* legacy = child(j, "msg");
    if (type.empty() && legacy && legacy->is_object()) {
        const Json& m = *legacy;
        std::string mt = str(m, "type");
        if (mt == "agent_message") {
            finalText_ = str(m, "message");
            AgentEvent e; e.type = AgentEvent::Type::TextDelta; e.text = finalText_; out.push_back(e);
        } else if (mt == "task_complete") {
            sawResult_ = true;
            if (std::string t = str(m, "last_agent_message"); !t.empty()) finalText_ = t;
        } else if (mt == "error") {
            errorText_ = str(m, "message");
            AgentEvent e; e.type = AgentEvent::Type::Error; e.text = errorText_; e.isError = true; out.push_back(e);
        } else if (mt == "mcp_tool_call_begin") {
            AgentEvent e; e.type = AgentEvent::Type::ToolStart;
            if (const Json* inv = child(m, "invocation")) {
                e.toolName = str(*inv, "tool");
                if (const Json* a = child(*inv, "arguments")) e.toolInput = *a;
            }
            out.push_back(e);
        } else if (mt == "mcp_tool_call_end") {
            AgentEvent e; e.type = AgentEvent::Type::ToolEnd;
            if (const Json* inv = child(m, "invocation")) e.toolName = str(*inv, "tool");
            out.push_back(e);
        } else if (mt == "token_count") {
            usage_.inputTokens = static_cast<u64>(num(m, "input_tokens", static_cast<double>(usage_.inputTokens)));
            usage_.outputTokens = static_cast<u64>(num(m, "output_tokens", static_cast<double>(usage_.outputTokens)));
        }
        return;
    }
    if (type == "thread.started") {
        sessionId_ = str(j, "thread_id");
        AgentEvent e; e.type = AgentEvent::Type::Info; e.text = "Codex started"; out.push_back(e);
    } else if (type == "item.started" || type == "item.completed") {
        const Json* item = child(j, "item");
        if (!item) return;
        const bool completed = type == "item.completed";
        std::string it = str(*item, "type");
        if (it == "agent_message" && completed) {
            finalText_ = str(*item, "text");
            AgentEvent e; e.type = AgentEvent::Type::TextDelta; e.text = finalText_; out.push_back(e);
        } else if (it == "reasoning" && completed) {
            AgentEvent e; e.type = AgentEvent::Type::ThinkingDelta; e.text = str(*item, "text"); out.push_back(e);
        } else if (it == "mcp_tool_call") {
            AgentEvent e;
            e.type = completed ? AgentEvent::Type::ToolEnd : AgentEvent::Type::ToolStart;
            e.toolName = str(*item, "tool");
            if (const Json* a = child(*item, "arguments")) e.toolInput = *a;
            if (completed) {
                e.isError = str(*item, "status") == "failed";
                if (const Json* r = child(*item, "result")) e.toolResult = clip(dump(*r));
            }
            out.push_back(e);
        } else if (it == "command_execution") {
            AgentEvent e;
            e.type = completed ? AgentEvent::Type::ToolEnd : AgentEvent::Type::ToolStart;
            e.toolName = "shell";
            e.toolInput = Json::object({{"command", str(*item, "command")}});
            if (completed) {
                e.isError = num(*item, "exit_code") != 0;
                e.toolResult = clip(str(*item, "aggregated_output"));
            }
            out.push_back(e);
        } else if (it == "file_change" && completed) {
            AgentEvent e; e.type = AgentEvent::Type::Info; e.text = "Codex changed files"; out.push_back(e);
        }
    } else if (type == "turn.completed") {
        sawResult_ = true;
        ++turns_;
        if (const Json* u = child(j, "usage")) {
            u64 in = static_cast<u64>(num(*u, "input_tokens"));
            u64 cached = static_cast<u64>(num(*u, "cached_input_tokens"));
            usage_.cacheReadTokens += cached;
            usage_.inputTokens += in > cached ? in - cached : 0;
            usage_.outputTokens += static_cast<u64>(num(*u, "output_tokens"));
        }
        AgentEvent e; e.type = AgentEvent::Type::Usage; e.usage = usage_; out.push_back(e);
    } else if (type == "turn.failed" || type == "error") {
        std::string msg = str(j, "message");
        if (const Json* er = child(j, "error")) msg = str(*er, "message", msg);
        errorText_ = msg;
        resultIsError_ = true;
        AgentEvent e; e.type = AgentEvent::Type::Error; e.text = msg; e.isError = true; out.push_back(e);
    }
}

// ---------------------------------------------------------------------------

static std::string tail(const std::string& s, std::size_t n = 800) {
    return s.size() <= n ? s : "..." + s.substr(s.size() - n);
}

Result<CliRunResult> CliAgent::run(const CliRunRequest& req, const EventHandler& onEvent, const CancelFlag* cancel) const {
    std::string command = cfg_.command.empty() ? default_cli_command(cfg_.kind) : cfg_.command;
    if (command.empty()) {
        return make_error("CLI provider '" + cfg_.name + "' has no \"command\"",
                          "Set \"command\" and \"argv\" for it in ~/.factoria/ai.json.");
    }
    std::string exe = which(command);
    if (exe.empty()) {
        return make_error("'" + command + "' was not found in PATH (provider '" + cfg_.name + "')", cli_install_hint(cfg_));
    }
    std::vector<std::string> tmpl = cfg_.argv.empty() ? default_cli_argv(cfg_.kind) : cfg_.argv;
    if (tmpl.empty()) {
        return make_error("Provider '" + cfg_.name + "' has no \"argv\" template",
                          "Add e.g. \"argv\": [\"--ask\", \"{prompt}\"] (placeholders {prompt} {model} {project} {mcp_config}).");
    }
    std::string projectDir = req.projectDir.empty() ? fsys::current_path().string() : fsys::absolute(req.projectDir).string();

    // MCP config file for CLIs that take one (Claude Code). It contains no secrets.
    std::string mcpPath;
    bool needsMcp = cfg_.kind == ProviderKind::ClaudeCode;
    for (const auto& a : tmpl) needsMcp = needsMcp || a.find("{mcp_config}") != std::string::npos;
    if (needsMcp) {
        std::error_code ec;
        fsys::path dir = fsys::path(projectDir) / ".factoria" / "ai";
        fsys::create_directories(dir, ec);
        fsys::path file = dir / ("mcp-" + cfg_.name + ".json");
        std::ofstream f(file, std::ios::binary | std::ios::trunc);
        if (!f) return make_error("Cannot write " + file.string(), "Is the project directory writable?");
        f << dump_pretty(make_mcp_config(projectDir, cfg_.factoriaCommand)) << "\n";
        mcpPath = file.string();
    }
    CliRunRequest effective = req;
    effective.projectDir = projectDir;

    ProcessOptions po;
    std::vector<std::string> expanded = expand_cli_argv(tmpl, effective, mcpPath, cfg_.factoriaCommand);
    // Pictures: inline in the stdin JSON when the CLI reads stream-json, else the prompt names their files.
    const bool jsonInput = argv_wants_stream_json_input(expanded);
    if (!jsonInput && !req.imagePaths.empty()) {
        effective.prompt = prompt_with_image_paths(req.prompt, req.imagePaths);
        expanded = expand_cli_argv(tmpl, effective, mcpPath, cfg_.factoriaCommand);  // {prompt} carries the paths too
    }
    po.argv.push_back(exe);
    for (auto& a : expanded) po.argv.push_back(std::move(a));
    po.workingDir = projectDir;
    po.env = cfg_.env;
    po.unsetEnv = cfg_.unsetEnv;
    // A template without {prompt} gets the prompt on standard input (one stream-json line when the CLI asks for that).
    if (jsonInput) po.stdinText = make_stream_json_input(req.prompt, req.images);
    else if (std::none_of(tmpl.begin(), tmpl.end(), [](const std::string& a) { return a.find("{prompt}") != std::string::npos; }))
        po.stdinText = effective.prompt;
    po.cancel = cancel;
    po.captureStdout = false;
    CliStreamParser parser(cfg_.kind);
    std::vector<AgentEvent> events;
    po.onStdoutLine = [&](std::string_view line) {
        events.clear();
        parser.feed_line(line, events);
        if (onEvent) for (auto& e : events) onEvent(e);
    };
    auto pr = run_process(po);
    if (!pr) return make_error(pr.error().message, pr.error().hint.empty() ? cli_install_hint(cfg_) : pr.error().hint);

    CliRunResult res;
    res.exitCode = pr->exitCode;
    res.cancelled = pr->cancelled;
    res.finalText = parser.final_text();
    res.usage = parser.usage();
    res.costUsd = parser.cost_usd();
    res.turns = parser.turns();
    res.sessionId = parser.session_id();
    if (pr->cancelled) {
        res.error = "cancelled";
        return res;
    }
    const std::string stderrText = pr->stderrText;
    const bool failed = pr->exitCode != 0 || parser.result_is_error() ||
                        (cfg_.kind != ProviderKind::GenericCli && !parser.saw_result());
    if (!failed) {
        res.ok = true;
        return res;
    }
    std::string detail = !parser.error_text().empty() ? parser.error_text() : std::string(fa::trim(stderrText));
    if (detail.empty()) detail = res.finalText;
    if (looks_like_auth_failure(detail) || looks_like_auth_failure(stderrText)) {
        res.error = "'" + command + "' is not logged in or its credentials were rejected: " + clip(detail, 400);
        res.hint = cfg_.kind == ProviderKind::ClaudeCode
                       ? "Run `claude` once in a terminal and log in (or `claude setup-token`), then retry. " + cli_install_hint(cfg_)
                   : cfg_.kind == ProviderKind::Codex ? "Run `codex login` in a terminal, then retry."
                                                      : "Log in with the CLI in a terminal, then retry.";
    } else {
        res.error = "'" + command + "' failed (exit code " + std::to_string(pr->exitCode) + ")" +
                    (detail.empty() ? std::string() : ": " + tail(detail));
        res.hint = stderrText.empty() ? "Run the same command in a terminal to see what it prints." : "";
        if (parser.saw_result() == false && pr->exitCode == 0) res.hint = "The CLI exited without a result. Check the argv template for provider '" + cfg_.name + "' (CLI flags change between versions).";
    }
    return res;
}

}  // namespace fa::ai
