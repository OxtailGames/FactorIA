#include "fa/ai/cli_agent.h"

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
            if (sub.value.empty() && (key == "{model}" || key == "{mcp_config}")) emptyPlaceholder = true;
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

void CliStreamParser::feed_claude(const Json& j, std::vector<AgentEvent>& out) {
    const std::string type = str(j, "type");
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
        if (resultIsError_) errorText_ = result.empty() ? str(j, "subtype") : result;
        else finalText_ = result;
        if (result.empty() && !resultIsError_) {
            // keep whatever text we streamed
        }
        costUsd_ = num(j, "total_cost_usd", num(j, "cost_usd"));
        turns_ = static_cast<int>(num(j, "num_turns"));
        if (std::string sid = str(j, "session_id"); !sid.empty()) sessionId_ = sid;
        if (const Json* u = child(j, "usage")) {
            usage_.inputTokens = static_cast<u64>(num(*u, "input_tokens"));
            usage_.outputTokens = static_cast<u64>(num(*u, "output_tokens"));
            usage_.cacheCreationTokens = static_cast<u64>(num(*u, "cache_creation_input_tokens"));
            usage_.cacheReadTokens = static_cast<u64>(num(*u, "cache_read_input_tokens"));
        }
        AgentEvent e;
        e.type = AgentEvent::Type::Usage;
        e.usage = usage_;
        e.costUsd = costUsd_;
        out.push_back(e);
    }
}

void CliStreamParser::feed_codex(const Json& j, std::vector<AgentEvent>& out) {
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
    po.argv.push_back(exe);
    for (auto& a : expand_cli_argv(tmpl, effective, mcpPath, cfg_.factoriaCommand)) po.argv.push_back(std::move(a));
    po.workingDir = projectDir;
    po.env = cfg_.env;
    po.unsetEnv = cfg_.unsetEnv;
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
