// AI Assistant panel.
//
// THREADING MODEL (important): the agent loop (ai::AgentSession) runs on a background
// thread. The engine, world, renderer and GPU are NOT thread-safe, so the agent is given a
// PROXY CommandRegistry (make_proxy_registry) that mirrors engine.commands(). Each proxy
// handler does not run the command itself; it pushes {name,args} into MainThreadQueue and
// blocks until Editor::on_frame() (main thread, before engine.frame()) executes it on the
// real registry and fulfils the promise. Events from the agent (text deltas, tool calls,
// usage) are appended to aiPending_ under aiMu_ and drained on the main thread each frame.
#include <algorithm>

#include "editor_internal.h"

namespace fa::editor {

void Editor::ai_refresh_providers() {
    if (aiDetecting_.load()) return;
    if (aiDetectThread_.joinable()) aiDetectThread_.join();
    aiDetecting_ = true;
    aiDetectThread_ = std::thread([this] {
        ai::AiConfig cfg;
        std::string err;
        auto loaded = ai::load_config();
        if (loaded) cfg = *loaded;
        else {
            err = loaded.error().to_string();
            cfg = ai::default_config();
        }
        std::vector<ai::ProviderStatus> st = ai::detect_providers(cfg);
        {
            std::lock_guard<std::mutex> lock(aiMu_);
            aiConfig_ = std::move(cfg);
            aiStatus_ = std::move(st);
            aiConfigError_ = err;
        }
        aiDetected_ = true;
        aiDetecting_ = false;
    });
}

std::shared_ptr<CommandRegistry> Editor::make_proxy_registry() {
    auto reg = std::make_shared<CommandRegistry>();
    for (const CommandInfo* ci : engine_->commands().list()) {
        CommandInfo info = *ci;
        const std::string name = info.name;
        reg->add(info, [this, name](const Json& args) -> Json {
            CommandResult r = queue_.call(name, args, &aiCancel_);
            if (!r.ok) {
                throw CommandError(r.error.value("code", "failed"), r.error.value("message", "command failed"),
                                   r.error.value("hint", ""));
            }
            return r.result;
        });
    }
    return reg;
}

void Editor::ai_start(const std::string& task) {
    if (!engine_ || aiRunning_.load() || task.empty()) return;
    if (aiThread_.joinable()) aiThread_.join();
    ai::AiConfig cfg;
    std::string providerOverride;
    {
        std::lock_guard<std::mutex> lock(aiMu_);
        cfg = aiConfig_;
        if (cfg.providers.empty()) cfg = ai::default_config();
        if (aiProvider_ > 0 && size_t(aiProvider_ - 1) < aiStatus_.size()) providerOverride = aiStatus_[size_t(aiProvider_ - 1)].name;
    }
    static const char* roles[] = {ai::kRoleOrchestrator, ai::kRoleWorker, ai::kRoleFast};
    ai::SessionOptions opt;
    opt.projectDir = projectDir_;
    opt.role = roles[std::clamp(aiRole_, 0, 2)];
    opt.providerOverride = providerOverride;
    ChatItem user;
    user.kind = ChatItem::Kind::User;
    user.text = task;
    chat_.push_back(user);
    aiScrollDown_ = true;
    aiUsage_ = {};
    aiCost_ = 0;
    aiCancel_ = false;
    queue_.reopen();
    aiProxy_ = make_proxy_registry();
    auto proxy = aiProxy_;
    aiRunning_ = true;
    ai::ProviderFactory factory = aiFactory_;
    aiThread_ = std::thread([this, cfg, opt, task, proxy, factory] {
        ai::AgentSession session(*proxy, cfg, opt);
        if (factory) session.set_provider_factory(factory);
        session.set_event_handler([this](const ai::AgentEvent& ev) {
            std::lock_guard<std::mutex> lock(aiMu_);
            aiPending_.push_back(ev);
        });
        session.set_cancel_flag(&aiCancel_);
        ai::SessionResult r = session.run(task);
        {
            std::lock_guard<std::mutex> lock(aiMu_);
            aiResult_ = r;
        }
        aiRunning_ = false;
    });
}

void Editor::ai_stop() {
    aiCancel_ = true;
    queue_.close();
    if (aiThread_.joinable()) aiThread_.join();
    aiRunning_ = false;
    aiCancel_ = false;
    queue_.reopen();
}

void Editor::ai_drain_events() {
    std::vector<ai::AgentEvent> events;
    std::optional<ai::SessionResult> result;
    {
        std::lock_guard<std::mutex> lock(aiMu_);
        events.swap(aiPending_);
        result.swap(aiResult_);
    }
    using T = ai::AgentEvent::Type;
    for (const auto& ev : events) {
        aiScrollDown_ = true;
        switch (ev.type) {
            case T::SessionStart: {
                ChatItem c;
                c.kind = ChatItem::Kind::Info;
                c.text = "session started (" + ev.role + ")";
                c.depth = ev.depth;
                chat_.push_back(std::move(c));
                break;
            }
            case T::TextDelta:
                if (chat_.empty() || chat_.back().kind != ChatItem::Kind::Assistant || chat_.back().depth != ev.depth) {
                    ChatItem c;
                    c.kind = ChatItem::Kind::Assistant;
                    c.depth = ev.depth;
                    c.role = ev.role;
                    chat_.push_back(std::move(c));
                }
                chat_.back().text += ev.text;
                break;
            case T::ThinkingDelta:
                if (chat_.empty() || chat_.back().kind != ChatItem::Kind::Thinking) {
                    ChatItem c;
                    c.kind = ChatItem::Kind::Thinking;
                    c.depth = ev.depth;
                    chat_.push_back(std::move(c));
                }
                chat_.back().text += ev.text;
                break;
            case T::ToolStart: {
                ChatItem c;
                c.kind = ChatItem::Kind::Tool;
                c.tool = ev.toolName;
                c.input = ev.toolInput;
                c.depth = ev.depth;
                chat_.push_back(std::move(c));
                break;
            }
            case T::ToolEnd:
                for (auto it = chat_.rbegin(); it != chat_.rend(); ++it) {
                    if (it->kind == ChatItem::Kind::Tool && it->tool == ev.toolName && !it->done) {
                        it->result = ev.toolResult;
                        it->isError = ev.isError;
                        it->done = true;
                        break;
                    }
                }
                break;
            case T::Usage:
                aiUsage_ = ev.usage;
                aiCost_ = ev.costUsd;
                break;
            case T::Info: {
                ChatItem c;
                c.kind = ChatItem::Kind::Info;
                c.text = ev.text;
                c.depth = ev.depth;
                chat_.push_back(std::move(c));
                break;
            }
            case T::Error: {
                ChatItem c;
                c.kind = ChatItem::Kind::Error;
                c.text = ev.text;
                c.depth = ev.depth;
                chat_.push_back(std::move(c));
                break;
            }
            case T::Done:
                aiCost_ = ev.costUsd;
                break;
        }
    }
    if (result) {
        ChatItem c;
        if (!result->ok) {
            c.kind = ChatItem::Kind::Error;
            c.text = (result->error.empty() ? "run ended: " + result->stopReason : result->error) +
                     (result->hint.empty() ? "" : "\nHint: " + result->hint);
        } else {
            c.kind = ChatItem::Kind::Info;
            c.text = "done (" + result->stopReason + ", " + std::to_string(result->turns) + " turn(s))";
        }
        aiUsage_ = result->usage;
        aiCost_ = result->costUsd;
        chat_.push_back(std::move(c));
        aiScrollDown_ = true;
    }
}

namespace {
std::string clip(std::string s, size_t n) {
    if (s.size() > n) {
        s.resize(n);
        s += "\n... (truncated)";
    }
    return s;
}
}  // namespace

void Editor::draw_ai_panel() {
    if (!ImGui::Begin("AI Assistant")) { ImGui::End(); return; }
    std::vector<ai::ProviderStatus> status;
    ai::AiConfig cfg;
    std::string cfgErr;
    {
        std::lock_guard<std::mutex> lock(aiMu_);
        status = aiStatus_;
        cfg = aiConfig_;
        cfgErr = aiConfigError_;
    }
    const bool detected = aiDetected_.load();
    const bool running = aiRunning_.load();
    bool anyAvailable = false;
    // "Ready" = an API key or a CLI login was found; local-server presets (ollama...) are always listed
    // as available but are not verified, so they do not count as configured.
    for (auto& s : status) anyAvailable = anyAvailable || (s.available && (s.isCli || !s.keySource.empty()));
    bool anyListed = false;
    for (auto& s : status) anyListed = anyListed || s.available;

    // Provider / role selectors.
    static const char* roleNames[] = {"orchestrator", "worker", "fast"};
    const float half = (ImGui::GetContentRegionAvail().x - ImGui::GetStyle().ItemSpacing.x) * 0.5f;
    std::string preview = "Role default";
    if (aiProvider_ > 0 && size_t(aiProvider_ - 1) < status.size()) preview = status[size_t(aiProvider_ - 1)].name;
    ImGui::SetNextItemWidth(half);
    ImGui::BeginDisabled(running);
    if (ImGui::BeginCombo("##prov", preview.c_str())) {
        if (ImGui::Selectable("Role default", aiProvider_ == 0)) aiProvider_ = 0;
        for (size_t i = 0; i < status.size(); ++i) {
            std::string label = status[i].name + (status[i].available ? "" : "  (not available)");
            if (ImGui::Selectable(label.c_str(), aiProvider_ == int(i) + 1)) aiProvider_ = int(i) + 1;
            if (ImGui::IsItemHovered()) ImGui::SetTooltip("%s\n%s", status[i].detail.c_str(), status[i].available ? "" : status[i].hint.c_str());
        }
        ImGui::EndCombo();
    }
    ImGui::SetItemTooltip("Provider used for this run");
    ImGui::SameLine();
    ImGui::SetNextItemWidth(-FLT_MIN);
    ImGui::Combo("##role", &aiRole_, roleNames, 3);
    ImGui::SetItemTooltip("Role: orchestrator plans and delegates, worker implements, fast does small mechanical tasks");
    ImGui::EndDisabled();
    {
        ai::RoleConfig rc = cfg.role(roleNames[std::clamp(aiRole_, 0, 2)]);
        std::string prov = aiProvider_ > 0 && size_t(aiProvider_ - 1) < status.size() ? status[size_t(aiProvider_ - 1)].name : rc.provider;
        ImGui::TextDisabled("%s / %s%s%s", prov.c_str(), rc.model.empty() ? "default model" : rc.model.c_str(), rc.effort.empty() ? "" : " / effort ", rc.effort.c_str());
    }

    if (!detected) {
        ImGui::TextDisabled(aiDetecting_.load() ? "Detecting providers..." : "Provider detection not started.");
    } else if (!anyAvailable) {
        ImGui::PushStyleColor(ImGuiCol_ChildBg, ImVec4(0.30f, 0.22f, 0.08f, 1));
        ImGui::BeginChild("##noprov", ImVec2(0, ImGui::GetTextLineHeightWithSpacing() * 6.6f), ImGuiChildFlags_Borders);
        ImGui::TextColored(ImVec4(1, 0.82f, 0.4f, 1), "No AI provider is configured.");
        ImGui::TextWrapped("Set an API key (ANTHROPIC_API_KEY, OPENAI_API_KEY...), or install the Claude Code / Codex CLI and sign in.%s", anyListed ? " Local servers (ollama, lmstudio) can be selected above." : "");
        if (ImGui::SmallButton("Open AI_PROVIDERS.md")) {
            auto d = read_doc("ai-providers");
            docsTitle_ = "AI_PROVIDERS.md";
            docsText_ = d ? *d : d.error().to_string();
            showDocs_ = true;
        }
        ImGui::SameLine();
        if (ImGui::SmallButton("Re-detect")) ai_refresh_providers();
        ImGui::EndChild();
        ImGui::PopStyleColor();
    }
    if (!cfgErr.empty()) ImGui::TextColored(ImVec4(1, 0.5f, 0.45f, 1), "Config: %s", cfgErr.c_str());

    // Transcript.
    const float inputH = ImGui::GetTextLineHeight() * 3.4f + 8;
    const float footer = inputH + ImGui::GetFrameHeightWithSpacing() * 1.4f;
    ImGui::BeginChild("##chat", ImVec2(0, -footer), ImGuiChildFlags_Borders);
    ImGui::PushTextWrapPos(0.0f);
    if (chat_.empty())
        ImGui::TextDisabled("Describe what you want built or changed. The assistant uses the same commands as the console (scene.*, fs.*, game.*...) and edits the open scene. Changes can be undone with Ctrl+Z.");
    int idx = 0;
    for (const ChatItem& c : chat_) {
        ImGui::PushID(idx++);
        if (c.depth > 0) ImGui::Indent(12.0f * float(c.depth));
        switch (c.kind) {
            case ChatItem::Kind::User:
                ImGui::TextColored(ImVec4(0.55f, 0.78f, 1.0f, 1), "You");
                ImGui::TextUnformatted(c.text.c_str());
                break;
            case ChatItem::Kind::Assistant:
                ImGui::TextColored(ImVec4(0.6f, 0.9f, 0.6f, 1), "Assistant%s", c.role.empty() ? "" : (" (" + c.role + ")").c_str());
                ImGui::TextUnformatted(c.text.c_str());
                break;
            case ChatItem::Kind::Thinking:
                if (ImGui::TreeNodeEx("thinking", ImGuiTreeNodeFlags_SpanAvailWidth)) {
                    ImGui::TextDisabled("%s", clip(c.text, 3000).c_str());
                    ImGui::TreePop();
                }
                break;
            case ChatItem::Kind::Tool: {
                const ImVec4 col = !c.done ? ImVec4(1, 0.85f, 0.4f, 1) : c.isError ? ImVec4(1, 0.45f, 0.4f, 1) : ImVec4(0.5f, 0.85f, 0.95f, 1);
                ImGui::PushStyleColor(ImGuiCol_Text, col);
                const bool open = ImGui::TreeNodeEx("##tool", ImGuiTreeNodeFlags_SpanAvailWidth, "tool: %s %s", c.tool.c_str(),
                                                    !c.done ? "(running...)" : c.isError ? "(error)" : "(ok)");
                ImGui::PopStyleColor();
                if (open) {
                    ImGui::TextDisabled("arguments");
                    ImGui::TextUnformatted(clip(c.input.dump(2), 2000).c_str());
                    if (c.done) {
                        ImGui::TextDisabled("result");
                        ImGui::TextUnformatted(clip(c.result.is_string() ? c.result.get<std::string>() : c.result.dump(2), 3000).c_str());
                    }
                    ImGui::TreePop();
                }
                break;
            }
            case ChatItem::Kind::Info:
                ImGui::TextDisabled("%s", c.text.c_str());
                break;
            case ChatItem::Kind::Error:
                ImGui::TextColored(ImVec4(1, 0.45f, 0.4f, 1), "%s", c.text.c_str());
                break;
        }
        if (c.depth > 0) ImGui::Unindent(12.0f * float(c.depth));
        ImGui::Spacing();
        ImGui::PopID();
    }
    ImGui::PopTextWrapPos();
    if (aiScrollDown_) {
        ImGui::SetScrollHereY(1.0f);
        aiScrollDown_ = false;
    }
    ImGui::EndChild();

    // Input.
    ImGui::BeginDisabled(running);
    bool submit = ImGui::InputTextMultiline("##ai_input", &aiInput_, ImVec2(-FLT_MIN, inputH),
                                            ImGuiInputTextFlags_EnterReturnsTrue | ImGuiInputTextFlags_CtrlEnterForNewLine);
    ImGui::EndDisabled();
    if (!running && aiInput_.empty()) {
        // hint text drawn over the empty box
        ImVec2 p = ImGui::GetItemRectMin();
        ImGui::GetWindowDrawList()->AddText(ImVec2(p.x + 6, p.y + 4), IM_COL32(120, 125, 140, 255), "Ask the assistant...  (Enter sends, Ctrl+Enter newline)");
    }
    const bool canRun = anyListed || !detected;
    ImGui::BeginDisabled(running || aiInput_.empty() || !canRun);
    if (ImGui::Button("Run") || (submit && !aiInput_.empty() && canRun)) {
        std::string task = aiInput_;
        aiInput_.clear();
        ai_start(task);
    }
    ImGui::EndDisabled();
    ImGui::SameLine();
    ImGui::BeginDisabled(!running);
    if (ImGui::Button("Stop")) aiCancel_ = true;
    ImGui::EndDisabled();
    ImGui::SameLine();
    if (ImGui::Button("Clear")) chat_.clear();
    ImGui::SameLine();
    if (running) ImGui::TextColored(ImVec4(1, 0.85f, 0.4f, 1), "running...");
    ImGui::SameLine();
    ImGui::TextDisabled("in %llu / out %llu tok   $%.4f", (unsigned long long)aiUsage_.inputTokens, (unsigned long long)aiUsage_.outputTokens, aiCost_);
    ImGui::End();
}

}  // namespace fa::editor
