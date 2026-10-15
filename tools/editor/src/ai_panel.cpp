// AI Assistant panel.
//
// THREADING MODEL (important): the agent loop (ai::AgentSession) runs on a background
// thread. The engine, world, renderer and GPU are NOT thread-safe, so the agent is given a
// PROXY CommandRegistry (make_proxy_registry) that mirrors engine.commands(). Each proxy
// handler does not run the command itself; it pushes {name,args} into MainThreadQueue and
// blocks until Editor::on_frame() (main thread, before engine.frame()) executes it on the
// real registry and fulfils the promise. Events from the agent (text deltas, tool calls,
// usage) are appended to aiPending_ under aiMu_ and drained on the main thread each frame.
//
// CLI AGENTS (Claude Code) run their own loop in a child process and call tools over MCP. The editor serves MCP itself
// (aiMcp_, a loopback HTTP endpoint with a secret path) on the same proxy registry, and the CLI's MCP config points
// there. Their edits therefore land in the live world, show in the viewport as they happen, take undo snapshots, and
// the play guards (ai_start, ai_blocks_play) cover them like an API provider's.
//
// CONVERSATIONS: the panel holds several chats as tabs (chat_, ai_chat.h). Each chat keeps its own transcript, the
// ai::Conversation that carries it from one message to the next (Claude Code session id / API message history), token
// totals, the unsent text and the pending pictures. aiRunChat_ names the chat the agent thread works for; the events are
// applied to that chat even when another tab is in front.
#include <algorithm>
#include <cstdio>
#include <ctime>

#include "editor_internal.h"
#include "fa/ai/commands.h"
#include "fa/mcp/server.h"
#include "sokol_app.h"
#include "ui_backend.h"

namespace fa::editor {

namespace {

constexpr const char* kRoleNames[] = {"orchestrator", "worker", "fast"};
constexpr const char* kEfforts[] = {"", "low", "medium", "high", "xhigh", "max"};  // "" = the role's default
constexpr u64 kContextLimits[] = {0, 100000, 200000, 300000, 400000, 500000, 600000, 800000};  // 0 = the model's window
constexpr const char* kRolesBlurb = "Your messages go to the orchestrator. It answers and plans, and hands implementation work to\n"
                                    "the worker and small mechanical edits to fast by itself.";
constexpr std::size_t kMaxPendingImages = 10;  // per message (the API providers take 20 and the CLIs read each one)
constexpr float kThumb = 56.0f;                // pending pictures
constexpr float kThumbSent = 48.0f;            // pictures in the transcript

i64 now_epoch() { return static_cast<i64>(std::time(nullptr)); }

std::string clip(std::string s, size_t n) {
    if (s.size() > n) {
        s.resize(n);
        s += "\n... (truncated)";
    }
    return s;
}

// Lays small groups out left to right and starts a new row when the next one does not fit. Call place(width) right
// before submitting each group.
struct Flow {
    float avail = ImGui::GetContentRegionAvail().x;
    float spacing = ImGui::GetStyle().ItemSpacing.x;
    float used = 0;
    void place(float width) {
        if (used > 0 && used + spacing + width <= avail + 1.0f) {
            ImGui::SameLine();
            used += spacing + width;
        } else {
            used = width;
        }
    }
};

ImVec4 bar_color(double used) {
    if (used >= 0.9) return ImVec4(0.85f, 0.32f, 0.28f, 1);
    if (used >= 0.7) return ImVec4(0.88f, 0.68f, 0.22f, 1);
    return ImVec4(0.30f, 0.62f, 0.42f, 1);
}

// A picture of the project (project-relative path) fitted in a size x size box; a grey button when the engine cannot
// read it (gif, webp) or the file is gone: the AI still gets the file either way.
void draw_thumb(Editor& ed, const std::string& path, float size) {
    const TextureEntry* t = ed.texture_for(path);
    if (t && t->w > 0 && t->h > 0) {
        const float scale = std::min(size / static_cast<float>(t->w), size / static_cast<float>(t->h));
        ImGui::Image(ImTextureRef(ImTextureID(ui::texture_from_view(t->view, true))),
                     ImVec2(static_cast<float>(t->w) * scale, static_cast<float>(t->h) * scale));
    } else {
        ImGui::BeginDisabled();
        ImGui::Button("image", ImVec2(size, size));
        ImGui::EndDisabled();
    }
    if (ImGui::IsItemHovered()) ImGui::SetTooltip("%s", path.c_str());
}

std::string reset_text(const LimitView& v, i64 now) {
    if (v.resetsAt <= 0) return "reset time unknown";
    if (v.wasReset) return "reset at " + format_clock(v.resetsAt, now);
    return "resets " + format_clock(v.resetsAt, now);
}

// Plan windows, context, tokens and cost of the active chat. Nothing here is a guess: every number comes from what the
// CLI or the API reported; what has not arrived yet is not drawn.
void draw_usage_area(const AiChat& chat, const ProviderLimits* limits, const std::string& provider, bool limitsExpected) {
    const i64 now = now_epoch();
    Flow flow;  // items wrap: a narrow panel gets one per row, a wide one several
    const float barW = std::min(180.0f, flow.avail);
    bool anyWindow = false;
    if (limits) {
        for (const ai::LimitWindow& w : sorted_limits(limits->windows)) {
            const LimitView v = limit_view(w, now);
            anyWindow = true;
            const std::string reset = reset_text(v, now);
            flow.place(barW + flow.spacing + ImGui::CalcTextSize(reset.c_str()).x);
            ImGui::BeginGroup();
            const std::string overlay = v.label + (v.known ? "  " + format_percent(v.used) + " used" : std::string());
            ImGui::PushStyleColor(ImGuiCol_PlotHistogram, bar_color(v.used));
            ImGui::ProgressBar(static_cast<float>(v.used), ImVec2(barW, 0), overlay.c_str());
            ImGui::PopStyleColor();
            ImGui::SameLine();
            ImGui::AlignTextToFramePadding();
            ImGui::TextDisabled("%s", reset.c_str());
            ImGui::EndGroup();
            if (ImGui::IsItemHovered()) {
                std::string tip = v.label + ": " + (v.known ? format_percent(v.used) + " of this window used." : "usage not reported.");
                if (v.wasReset) tip += "\nThe window has reset since the last report (shown as 0% until " + provider + " reports again).";
                else if (v.resetsAt > 0) tip += "\nResets " + format_date_time(v.resetsAt) + ".";
                if (limits->updated > 0) tip += "\nLast reported by " + provider + " at " + format_date_time(limits->updated) + ".";
                ImGui::SetTooltip("%s", tip.c_str());
            }
        }
    }
    if (chat.contextTokens > 0) {
        const bool known = chat.contextWindow > 0;
        const std::string text = "Context " + format_tokens(chat.contextTokens) + (known ? " / " + format_tokens(chat.contextWindow) : "");
        const float w = known ? barW : ImGui::CalcTextSize(text.c_str()).x;
        flow.place(w);
        ImGui::BeginGroup();
        if (known) {
            const double frac = std::min(1.0, static_cast<double>(chat.contextTokens) / static_cast<double>(chat.contextWindow));
            ImGui::PushStyleColor(ImGuiCol_PlotHistogram, bar_color(frac));
            ImGui::ProgressBar(static_cast<float>(frac), ImVec2(barW, 0), text.c_str());
            ImGui::PopStyleColor();
        } else {
            ImGui::AlignTextToFramePadding();
            ImGui::TextUnformatted(text.c_str());
        }
        ImGui::EndGroup();
        if (ImGui::IsItemHovered()) {
            ImGui::SetTooltip("How much the model reads on every message: the whole conversation so far (input and cached\n"
                              "tokens of the last model call)%s.",
                              known ? ", against the size of its context window" : "");
        }
    }
    ai::Usage u = chat.usage;
    u += chat.runUsage;
    const double cost = chat.costUsd + chat.runCostUsd;
    if (cost > 0) {
        char text[64];
        std::snprintf(text, sizeof text, "Cost est. $%.4f", cost);
        flow.place(ImGui::CalcTextSize(text).x);
        ImGui::AlignTextToFramePadding();  // same height as the bar next to it
        ImGui::TextUnformatted(text);
        if (ImGui::IsItemHovered()) {
            ImGui::SetTooltip("Estimated cost of this conversation in USD, from the price the CLI reports or the engine's price table.\n"
                              "A subscription (Claude Code / Codex sign-in) is not billed per token: the plan windows above matter there.");
        }
    }
    if (u.inputTokens || u.outputTokens || u.cacheReadTokens || u.cacheCreationTokens) {
        char text[160];
        std::snprintf(text, sizeof text, "Tokens in %s  out %s  cache %s", format_tokens(u.inputTokens).c_str(),
                      format_tokens(u.outputTokens).c_str(), format_tokens(u.cacheReadTokens + u.cacheCreationTokens).c_str());
        flow.place(ImGui::CalcTextSize(text).x);
        ImGui::AlignTextToFramePadding();
        ImGui::TextUnformatted(text);
        if (ImGui::IsItemHovered()) {
            ImGui::SetTooltip("Tokens used by this conversation so far.\nin = new input, out = what the model wrote,\ncache = input read from or written to the prompt cache.");
        }
    }
    if (limitsExpected && !anyWindow) {
        const char* note = "Plan usage updates after the first message.";
        flow.place(ImGui::CalcTextSize(note).x);
        ImGui::AlignTextToFramePadding();
        ImGui::TextDisabled("%s", note);
    }
}

// "Opus 5.5  (opus)", or just the id when the provider gives no name.
std::string model_label(const ai::ModelInfo& m) { return m.name.empty() ? m.id : m.name + "  (" + m.id + ")"; }

// What a model's tooltip says: its description, and the model an alias stands for.
std::string model_tip(const ai::ModelInfo& m) {
    std::string tip = m.description;
    if (!m.resolved.empty()) tip += (tip.empty() ? "= " : "\n= ") + m.resolved;
    return tip;
}

}  // namespace

// ---------------------------------------------------------------------------------------------------------------------

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
            aiConfig_ = cfg;
            aiStatus_ = st;
            aiConfigError_ = err;
        }
        aiDetected_ = true;
        // The models each available provider offers (the Roles window's lists): asked of the providers themselves, so new
        // releases show up. Claude Code starts its CLI for this, a local server may be down: hence after the detection.
        std::map<std::string, ProviderModels> models;
        for (const ai::ProviderStatus& s : st) {
            if (!s.available) continue;
            ProviderModels& pm = models[s.name];
            if (auto listed = ai::list_models(cfg.providers.at(s.name))) pm.models = std::move(*listed);
            else pm.error = listed.error().to_string();
        }
        {
            std::lock_guard<std::mutex> lock(aiMu_);
            aiModels_ = std::move(models);
        }
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
    // ai.run: a CLI orchestrator delegates with it over MCP. It runs on the caller's thread (an MCP connection), not
    // through the queue: the sub-agent's own commands come back through this proxy, so the main thread stays free.
    ai::AiCommandOptions ao;
    ao.loadConfig = [this]() -> Result<ai::AiConfig> {
        std::lock_guard<std::mutex> lock(aiMu_);
        return aiConfig_.providers.empty() ? ai::default_config() : aiConfig_;
    };
    ao.projectDir = [dir = projectDir_] { return dir; };
    ao.providerFactory = aiFactory_;
    ao.cancel = &aiCancel_;
    ao.mcpUrl = aiMcp_.url();
    ai::register_ai_commands(*reg, ao);
    return reg;
}

// The chat tabs belong to the open project (<project>/.factoria/ai/chats): when the project changed (boot() stopped the
// agent first, which saved its chat), load the new project's tabs. Called by everything that touches chat_, so boot()
// needs no knowledge of the chats.
void Editor::ai_sync_chats() {
    if (!aiLimitsLoaded_) {
        aiLimitsLoaded_ = true;
        if (!autotest_) aiLimits_ = load_limits(limits_path(home_dir()));  // the autotest must not depend on this machine's plan
    }
    const std::string want =
        projectDir_.empty() ? std::string() : utf8_string(utf8_path(projectDir_) / ".factoria" / "ai" / "chats");
    if (chat_.dir == want) return;
    chat_.open_dir(want);
    aiHistory_.clear();
    aiHistoryDelete_.clear();
    aiTabForce_ = 2;
}

// Adds a copied picture to the active chat's pending strip, or tells the user why not.
void Editor::ai_add_pending(Result<ChatAttachment> attached) {
    if (attached) chat_.current().pending.push_back(*attached);
    else notify(attached.error().to_string(), 1);
}

void Editor::ai_attach_path(const std::string& path) {
    ai_sync_chats();
    if (!engine_) {
        notify("Open a project first: attached pictures are kept in the project's .factoria/ai/attachments folder.", 1);
        return;
    }
    if (chat_.current().pending.size() >= kMaxPendingImages) {
        notify("At most " + std::to_string(kMaxPendingImages) + " pictures per message. Send this one first, then attach more.", 1);
        return;
    }
    ai_add_pending(attach_file(projectDir_, path));
}

void Editor::ai_paste_image() {
    ai_sync_chats();
    if (!engine_) return;
    const std::vector<std::uint8_t> png = clipboard_image_png();
    if (png.empty()) return;  // no picture on the clipboard: nothing to attach
    if (chat_.current().pending.size() >= kMaxPendingImages) {
        notify("At most " + std::to_string(kMaxPendingImages) + " pictures per message. Send this one first, then paste more.", 1);
        return;
    }
    ai_add_pending(attach_bytes(projectDir_, "paste.png", png));
}

void Editor::ai_on_files_dropped() {
    const int n = sapp_get_num_dropped_files();
    if (n <= 0) return;
    showAi_ = true;
    focus_window("AI Assistant");
    for (int i = 0; i < n; ++i) ai_attach_path(sapp_get_dropped_file_path(i));
}

void Editor::ai_start(const std::string& task) {
    if (!engine_ || task.empty()) return;
    if (play_ != PlayState::Edit) {  // its scene edits would be thrown away at Stop
        notify("Stop the game first (F5): changes made while it runs are thrown away at Stop.", 1);
        return;
    }
    ai_sync_chats();
    ai_drain_events();  // the result of the previous run may still be waiting
    // ponytail: one agent run at a time. The editor has one proxy registry, one command queue and one cancel flag, so
    // a second run (another tab) waits; per-chat threads and queues if parallel chats are ever wanted.
    if (aiRunning_.load() || !aiRunChat_.empty()) return;
    if (aiThread_.joinable()) aiThread_.join();
    if (aiMcp_.url().empty()) {  // the endpoint CLI agents attach (see the top of this file)
        auto started = aiMcp_.start([this, dir = projectDir_](std::string_view message) -> std::optional<std::string> {
            std::shared_ptr<CommandRegistry> proxy;
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                proxy = aiProxy_;
            }
            if (!proxy) return std::nullopt;  // not reached: the URL is handed out after the run's proxy exists
            SimpleMcpHost host(*proxy, dir);
            return McpServer(host).handle_message(message);  // stateless: one server per message
        });
        if (!started) {
            notify(started.error().to_string(), 2);
            return;
        }
    }
    AiChat& chat = chat_.current();
    ai::AiConfig cfg;
    {
        std::lock_guard<std::mutex> lock(aiMu_);
        cfg = aiConfig_;
        if (cfg.providers.empty()) cfg = ai::default_config();
    }
    ai::SessionOptions opt;
    opt.projectDir = projectDir_;
    opt.role = ai::kRoleOrchestrator;  // it hands the work to the worker and fast roles itself (the "AI roles" popup)
    opt.conversation = chat.conversation;  // resumes the chat when the provider is the same one that produced it
    opt.mcpUrl = aiMcp_.url();
    aiRunProvider_ = cfg.role(opt.role).provider;

    ChatItem user;
    user.kind = ChatItem::Kind::User;
    user.text = task;
    std::vector<std::string> imageFiles;  // absolute paths for the agent
    for (const ChatAttachment& a : chat.pending) {
        user.images.push_back(a.path);
        imageFiles.push_back(utf8_string(utf8_path(projectDir_) / utf8_path(a.path)));
    }
    chat.pending.clear();
    chat.items.push_back(std::move(user));
    if (chat.title.empty()) chat.title = chat_title_from(task);
    chat.updated = now_epoch();
    chat.scrollDown = true;
    chat.runUsage = {};
    chat.runCostUsd = 0;

    // The entity selected in the viewport is what "this" and "it" mean. The transcript shows only what was typed.
    std::string prompt = task;
    if (const Entity sel = selected(); !sel.is_null()) {
        prompt = selection_line(world().info(sel).name, world().id_of(sel)) + "\n" + task;
    }

    aiRunChat_ = chat.id;
    aiCancel_ = false;
    queue_.reopen();
    auto proxy = make_proxy_registry();
    {
        std::lock_guard<std::mutex> lock(aiMu_);
        aiProxy_ = proxy;
    }
    aiRunning_ = true;
    ai::ProviderFactory factory = aiFactory_;
    aiThread_ = std::thread([this, cfg, opt, prompt, imageFiles, proxy, factory] {
        ai::AgentSession session(*proxy, cfg, opt);
        if (factory) session.set_provider_factory(factory);
        session.set_event_handler([this](const ai::AgentEvent& ev) {
            std::lock_guard<std::mutex> lock(aiMu_);
            aiPending_.push_back(ev);
        });
        session.set_cancel_flag(&aiCancel_);
        ai::SessionResult r = session.run(prompt, imageFiles);
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
    aiMcp_.stop();  // after the cancel and the closed queue: its requests (ai.run included) end instead of waiting
    aiRunning_ = false;
    aiCancel_ = false;
    queue_.reopen();
    ai_drain_events();  // the cancelled run's last events and result: its chat is saved here
    aiRunChat_.clear();
    aiRunProvider_.clear();
}

void Editor::ai_drain_events() {
    std::vector<ai::AgentEvent> events;
    std::optional<ai::SessionResult> result;
    {
        std::lock_guard<std::mutex> lock(aiMu_);
        events.swap(aiPending_);
        result.swap(aiResult_);
    }
    if (events.empty() && !result) return;
    AiChat orphan;  // the run's chat is gone (the project changed under it): its text is dropped, the plan limits are kept
    AiChat* found = chat_.find(aiRunChat_);
    AiChat& c = found ? *found : orphan;
    std::vector<ChatItem>& items = c.items;
    bool limitsChanged = false;
    using T = ai::AgentEvent::Type;
    auto note = [&](ChatItem::Kind kind, const std::string& text, int depth) {
        ChatItem it;
        it.kind = kind;
        it.text = text;
        it.depth = depth;
        items.push_back(std::move(it));
    };
    for (const auto& ev : events) {
        c.scrollDown = true;
        switch (ev.type) {
            case T::SessionStart:
                note(ChatItem::Kind::Info, "session started (" + ev.role + ")", ev.depth);
                break;
            case T::TextDelta:
                if (items.empty() || items.back().kind != ChatItem::Kind::Assistant || items.back().depth != ev.depth) {
                    ChatItem it;
                    it.kind = ChatItem::Kind::Assistant;
                    it.depth = ev.depth;
                    it.role = ev.role;
                    items.push_back(std::move(it));
                }
                items.back().text += ev.text;
                break;
            case T::ThinkingDelta:
                if (items.empty() || items.back().kind != ChatItem::Kind::Thinking) {
                    ChatItem it;
                    it.kind = ChatItem::Kind::Thinking;
                    it.depth = ev.depth;
                    items.push_back(std::move(it));
                }
                items.back().text += ev.text;
                break;
            case T::ToolStart: {
                ChatItem it;
                it.kind = ChatItem::Kind::Tool;
                it.tool = ev.toolName;
                it.input = ev.toolInput;
                it.depth = ev.depth;
                items.push_back(std::move(it));
                break;
            }
            case T::ToolEnd:
                for (auto it = items.rbegin(); it != items.rend(); ++it) {
                    if (it->kind == ChatItem::Kind::Tool && it->tool == ev.toolName && !it->done) {
                        it->result = ev.toolResult;
                        it->isError = ev.isError;
                        it->done = true;
                        break;
                    }
                }
                break;
            case T::Usage:
                c.runUsage = ev.usage;
                c.runCostUsd = ev.costUsd;
                // Context and plan windows describe the chat's own provider; a delegated worker's (depth > 0) are not these.
                if (ev.depth == 0) {
                    if (ev.contextTokens) c.contextTokens = ev.contextTokens;
                    if (ev.contextWindow) c.contextWindow = ev.contextWindow;
                    if (!ev.limits.empty() && !aiRunProvider_.empty()) {
                        ProviderLimits& pl = aiLimits_[aiRunProvider_];
                        ai::merge_limit_windows(pl.windows, ev.limits);
                        pl.updated = now_epoch();
                        limitsChanged = true;
                    }
                }
                break;
            case T::Info:
                note(ChatItem::Kind::Info, ev.text, ev.depth);
                break;
            case T::Error:
                note(ChatItem::Kind::Error, ev.text, ev.depth);
                break;
            case T::Done:
                c.runCostUsd = ev.costUsd;
                break;
        }
    }
    if (result) {
        ChatItem it;
        if (!result->ok) {
            it.kind = ChatItem::Kind::Error;
            it.text = (result->error.empty() ? "run ended: " + result->stopReason : result->error) +
                      (result->hint.empty() ? "" : "\nHint: " + result->hint);
        } else {
            it.kind = ChatItem::Kind::Info;
            it.text = "done (" + result->stopReason + ", " + std::to_string(result->turns) + " turn(s))";
        }
        items.push_back(std::move(it));
        c.usage += result->usage;
        c.costUsd += result->costUsd;
        c.runUsage = {};
        c.runCostUsd = 0;
        if (!result->conversation.empty()) c.conversation = result->conversation;  // a failed first run keeps the old one
        c.updated = now_epoch();
        c.scrollDown = true;
        if (found) {  // saved after every run (no timer): the chat survives a crash or a closed editor
            chat_.save(c);
            chat_.save_open_list();
        }
        aiRunChat_.clear();
        aiRunProvider_.clear();
    }
    if (limitsChanged && !autotest_) save_limits(limits_path(home_dir()), aiLimits_);
}

// ---------------------------------------------------------------------------------------------------------------------

// "AI roles": the provider, model and effort of the orchestrator, worker and fast roles. Save writes them into ai.json
// (only its "roles"; everything else in the file stays) and reloads it, so the next message uses them.
void Editor::draw_ai_roles_popup(const ai::AiConfig& cfg, const std::vector<ai::ProviderStatus>& status) {
    if (aiRolesOpen_) {
        aiRolesEdit_.clear();
        aiRolesTyping_.clear();
        for (const char* name : kRoleNames) aiRolesEdit_[name] = cfg.role(name);
        ImGui::OpenPopup("AI roles");
        aiRolesOpen_ = false;
    }
    ImGui::SetNextWindowPos(ImGui::GetMainViewport()->GetCenter(), ImGuiCond_Appearing, ImVec2(0.5f, 0.5f));
    if (!ImGui::BeginPopupModal("AI roles", nullptr, ImGuiWindowFlags_AlwaysAutoResize)) return;
    ImGui::TextUnformatted(kRolesBlurb);
    ImGui::Spacing();
    std::map<std::string, ProviderModels> models;  // a copy: the detection thread replaces them
    {
        std::lock_guard<std::mutex> lock(aiMu_);
        models = aiModels_;
    }
    if (ImGui::BeginTable("##roles", 5, ImGuiTableFlags_SizingFixedFit)) {
        ImGui::TableSetupColumn("Role");
        ImGui::TableSetupColumn("Provider");
        ImGui::TableSetupColumn("Model");
        ImGui::TableSetupColumn("Effort");
        ImGui::TableSetupColumn("Context");
        ImGui::TableHeadersRow();
        for (const char* name : kRoleNames) {
            ai::RoleConfig& r = aiRolesEdit_[name];
            ImGui::PushID(name);
            ImGui::TableNextRow();
            ImGui::TableNextColumn();
            ImGui::AlignTextToFramePadding();
            ImGui::TextUnformatted(name);
            ImGui::TableNextColumn();
            ImGui::SetNextItemWidth(170);
            if (ImGui::BeginCombo("##provider", r.provider.c_str())) {
                for (const auto& [pname, pc] : cfg.providers) {
                    const auto found = std::ranges::find(status, pname, &ai::ProviderStatus::name);
                    const ai::ProviderStatus* st = found == status.end() ? nullptr : &*found;
                    const std::string label = pname + (st && !st->available ? "  (not available)" : "");
                    if (ImGui::Selectable(label.c_str(), r.provider == pname) && r.provider != pname) {
                        r = {pname, "", "", r.maxTokens, r.maxContextTokens};  // another provider: its default model and effort
                        aiRolesTyping_.erase(name);
                    }
                    if (st && ImGui::IsItemHovered()) ImGui::SetTooltip("%s\n%s", st->detail.c_str(), st->available ? "" : st->hint.c_str());
                }
                ImGui::EndCombo();
            }
            ImGui::TableNextColumn();
            ImGui::SetNextItemWidth(260);
            const auto listed = models.find(r.provider);
            if (listed != models.end() && listed->second.error.empty() && !aiRolesTyping_.contains(name)) {
                // The models the provider offers; "Other..." types one that is not in the list.
                const std::vector<ai::ModelInfo>& list = listed->second.models;
                const auto current = std::ranges::find(list, r.model, &ai::ModelInfo::id);
                const std::string preview = r.model.empty() ? "default" : current != list.end() ? model_label(*current) : r.model;
                if (ImGui::BeginCombo("##model", preview.c_str())) {
                    const auto def = std::ranges::find(list, "default", &ai::ModelInfo::id);  // Claude Code lists its default
                    if (ImGui::Selectable("default", r.model.empty())) r.model.clear();
                    if (ImGui::IsItemHovered()) {
                        ImGui::SetTooltip("The default of the role (Anthropic API) or of the CLI itself.%s%s", def == list.end() ? "" : "\n",
                                          def == list.end() ? "" : model_tip(*def).c_str());
                    }
                    for (const ai::ModelInfo& m : list) {
                        if (m.id == "default") continue;  // the item above is the same choice
                        if (ImGui::Selectable(model_label(m).c_str(), r.model == m.id)) r.model = m.id;
                        if (ImGui::IsItemHovered() && !model_tip(m).empty()) ImGui::SetTooltip("%s", model_tip(m).c_str());
                    }
                    if (ImGui::Selectable("Other...")) aiRolesTyping_.insert(name);
                    ImGui::SetItemTooltip("Type a model name that is not in the list.");
                    ImGui::EndCombo();
                }
            } else {
                ImGui::InputTextWithHint("##model", "default", &r.model);
                // Typed text that is empty or in the list sends the role back to the list.
                if (ImGui::IsItemDeactivated() && listed != models.end() && listed->second.error.empty() &&
                    (r.model.empty() || std::ranges::find(listed->second.models, r.model, &ai::ModelInfo::id) != listed->second.models.end())) {
                    aiRolesTyping_.erase(name);
                }
                ImGui::SetItemTooltip("Model name for this provider, e.g. opus / sonnet / haiku (Claude Code), claude-sonnet-5-5\n"
                                      "(Anthropic API). Empty = the default: Anthropic's for the role, or the CLI's own.%s%s",
                                      listed != models.end() && !listed->second.error.empty() ? "\nIts models could not be listed: " : "",
                                      listed != models.end() ? listed->second.error.c_str() : "");
            }
            ImGui::TableNextColumn();
            ImGui::SetNextItemWidth(90);
            if (ImGui::BeginCombo("##effort", r.effort.empty() ? "default" : r.effort.c_str())) {
                for (const char* e : kEfforts) {
                    if (ImGui::Selectable(*e ? e : "default", r.effort == e)) r.effort = e;
                }
                ImGui::EndCombo();
            }
            ImGui::SetItemTooltip("How hard the model thinks (API providers). CLI agents use their own setting.");
            ImGui::TableNextColumn();
            ImGui::SetNextItemWidth(80);
            const auto context_label = [](u64 n) { return n == 0 ? std::string("full") : format_tokens(n); };
            if (ImGui::BeginCombo("##context", context_label(r.maxContextTokens).c_str())) {
                for (const u64 n : kContextLimits) {
                    if (ImGui::Selectable(context_label(n).c_str(), r.maxContextTokens == n)) r.maxContextTokens = n;
                }
                ImGui::EndCombo();
            }
            ImGui::SetItemTooltip("Most context a session of this role keeps. When it gets there, the earlier part of the\n"
                                  "conversation is replaced by a summary, so each message reads (and costs) less.\n"
                                  "full = the model's whole window. Claude Code and the Anthropic API; other providers ignore it.");
            ImGui::PopID();
        }
        ImGui::EndTable();
    }
    const std::string path = cfg.sourcePath.empty() ? ai::default_config_path() : cfg.sourcePath;
    ImGui::TextDisabled("Saved in %s", path.c_str());
    ImGui::SameLine();
    const bool checking = aiDetecting_.load();
    ImGui::BeginDisabled(checking);
    if (ImGui::SmallButton("Refresh models")) ai_refresh_providers();
    ImGui::EndDisabled();
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) {
        ImGui::SetTooltip("Ask each provider again which models it offers (newly released ones show up here)");
    }
    if (checking) {
        ImGui::SameLine();
        ImGui::TextDisabled("Checking models...");
    }
    if (ImGui::Button("Save")) {
        if (auto saved = ai::save_roles(aiRolesEdit_, path); !saved) {
            notify(saved.error().to_string(), 2);
        } else {
            auto loaded = ai::load_config(path);  // the file now says what the roles are, with the defaults filled in
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                if (loaded) aiConfig_ = std::move(*loaded);
                aiConfigError_ = loaded ? std::string() : loaded.error().to_string();
            }
            notify("AI roles saved. The next message uses them.");
            ImGui::CloseCurrentPopup();
        }
    }
    ImGui::SameLine();
    if (ImGui::Button("Cancel")) ImGui::CloseCurrentPopup();
    ImGui::EndPopup();
}

// ---------------------------------------------------------------------------------------------------------------------

void Editor::draw_ai_panel() {
    if (!ImGui::Begin("AI Assistant")) { ImGui::End(); return; }
    ai_sync_chats();
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

    // ---- Chat tabs: one conversation each, "+" starts another, History reopens an old one.
    {
        int closeIndex = -1, pickIndex = -1;
        bool addTab = false, showHistory = false;
        const bool forcing = aiTabForce_ > 0;
        if (ImGui::BeginTabBar("##aichats", ImGuiTabBarFlags_None)) {  // tabs shrink when they do not fit, then scroll
            for (int i = 0; i < static_cast<int>(chat_.tabs.size()); ++i) {
                const AiChat& t = chat_.tabs[static_cast<std::size_t>(i)];
                const bool isRun = running && t.id == aiRunChat_;
                const std::string label = std::string(isRun ? "* " : "") + (t.title.empty() ? "New chat" : t.title) + "###" + t.id;
                bool open = true;
                const ImGuiTabItemFlags flags = (forcing && i == chat_.active) ? ImGuiTabItemFlags_SetSelected : ImGuiTabItemFlags_None;
                if (ImGui::BeginTabItem(label.c_str(), &open, flags)) {
                    // ImGui shows a tab selected by code one frame late: while forcing, the old tab still reports as visible.
                    if (!forcing && i != chat_.active) pickIndex = i;
                    ImGui::EndTabItem();
                }
                if (isRun) ImGui::SetItemTooltip("The assistant is working in this chat");
                if (!open) closeIndex = i;
            }
            addTab = ImGui::TabItemButton("+", ImGuiTabItemFlags_Trailing | ImGuiTabItemFlags_NoTooltip);
            ImGui::SetItemTooltip("Start a new chat in a new tab");
            showHistory = ImGui::TabItemButton("History", ImGuiTabItemFlags_Trailing | ImGuiTabItemFlags_NoTooltip);
            ImGui::SetItemTooltip("Earlier chats of this project: click one to reopen it");
            ImGui::EndTabBar();
        }
        if (forcing) --aiTabForce_;
        if (closeIndex >= 0) {
            if (running && chat_.tabs[static_cast<std::size_t>(closeIndex)].id == aiRunChat_) {
                notify("The assistant is still working in this chat. Press Stop first, then close it.", 1);
            } else {
                chat_.close(closeIndex);  // saves it first: it stays in History
                aiTabForce_ = 2;
            }
        } else if (addTab) {
            chat_.add(now_epoch());
            aiTabForce_ = 2;
        } else if (pickIndex >= 0) {
            chat_.select(pickIndex);
        }
        if (showHistory) aiHistoryOpen_ = true;
    }
    if (aiHistoryOpen_) {
        aiHistory_ = chat_.history();
        aiHistoryDelete_.clear();
        ImGui::OpenPopup("AI chat history");
        aiHistoryOpen_ = false;
    }
    ImGui::SetNextWindowSizeConstraints(ImVec2(0, 0), ImVec2(640, 380));
    if (ImGui::BeginPopup("AI chat history")) {
        std::string reopenId, eraseId;
        if (aiHistory_.empty()) ImGui::TextDisabled("No saved chats yet. A chat is saved after each answer.");
        // Three columns by hand (title, date, delete): the title column is as wide as the longest title.
        const auto title_of = [&](const ChatHistoryEntry& h) {
            return (h.title.empty() ? std::string("(untitled)") : h.title) + (chat_.index_of(h.id) >= 0 ? "  (open)" : "");
        };
        float titleW = 0;
        for (const ChatHistoryEntry& h : aiHistory_) titleW = std::max(titleW, ImGui::CalcTextSize(title_of(h).c_str()).x);
        for (const ChatHistoryEntry& h : aiHistory_) {
            ImGui::PushID(h.id.c_str());
            const bool isRun = running && h.id == aiRunChat_;
            if (ImGui::Selectable(title_of(h).c_str(), false, ImGuiSelectableFlags_None, ImVec2(titleW, 0))) reopenId = h.id;
            ImGui::SetItemTooltip("Open this chat in a tab; your next message continues it where it stopped");
            ImGui::SameLine();
            ImGui::TextDisabled("%s", format_date_time(h.updated).c_str());
            ImGui::SameLine();
            const bool confirm = aiHistoryDelete_ == h.id;
            ImGui::BeginDisabled(isRun);
            if (ImGui::SmallButton(confirm ? "Delete for good?" : "Delete")) {
                if (confirm) eraseId = h.id;
                else aiHistoryDelete_ = h.id;
            }
            ImGui::EndDisabled();
            ImGui::SetItemTooltip("%s", isRun ? "The assistant is working in this chat" : "Removes the saved chat. Click again to confirm.");
            ImGui::PopID();
        }
        if (!reopenId.empty()) {
            if (chat_.reopen(reopenId)) aiTabForce_ = 2;
            else notify("Cannot open that chat: its file is missing or damaged.", 2);
            ImGui::CloseCurrentPopup();
        } else if (!eraseId.empty()) {
            chat_.erase(eraseId);
            aiHistory_ = chat_.history();
            aiHistoryDelete_.clear();
            aiTabForce_ = 2;
        }
        ImGui::EndPopup();
    }

    draw_ai_roles_popup(cfg, status);

    AiChat& chat = chat_.current();  // (no chat_ change below this line: the reference stays valid)
    const bool isRunTab = running && chat.id == aiRunChat_;
    const bool otherRunning = running && !isRunTab;
    ImGui::PushID(chat.id.c_str());  // every widget below belongs to the tab: its own scroll position and input text

    // The roles. Every message goes to the orchestrator; it hands the work to the worker and fast roles itself.
    const std::string providerName = cfg.role(ai::kRoleOrchestrator).provider;
    ImGui::BeginDisabled(!detected);  // before the first detection aiConfig_ is empty: Save would write roles without providers
    if (ImGui::SmallButton("Roles...")) aiRolesOpen_ = true;
    ImGui::EndDisabled();
    if (!detected && ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("Reading ai.json...");
    else ImGui::SetItemTooltip("Choose the provider and model of each role. Takes effect with the next message.");
    std::string roles;
    for (const char* name : kRoleNames) {
        const ai::RoleConfig rc = cfg.role(name);
        roles += (roles.empty() ? "" : "   ") + std::string(name) + ": " + rc.provider + (rc.model.empty() ? "" : " / " + rc.model) +
                 (rc.maxContextTokens ? " (" + format_tokens(rc.maxContextTokens) + ")" : "");
    }
    ImGui::SameLine();
    ImGui::PushStyleColor(ImGuiCol_Text, ImGui::GetStyleColorVec4(ImGuiCol_TextDisabled));
    ImGui::TextWrapped("%s", roles.c_str());
    ImGui::PopStyleColor();
    ImGui::SetItemTooltip("%s", kRolesBlurb);

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

    // Usage: plan windows (only a CLI has them), context, tokens, cost.
    {
        bool limitsExpected = true;  // a CLI provider, or one not detected yet
        for (const auto& s : status) {
            if (s.name == providerName) limitsExpected = s.isCli;
        }
        const auto it = aiLimits_.find(providerName);
        draw_usage_area(chat, it == aiLimits_.end() ? nullptr : &it->second, providerName, limitsExpected);
    }

    // Pending pictures take room from the transcript.
    const float thumbCell = std::max(kThumb, ImGui::CalcTextSize("Remove").x + ImGui::GetStyle().FramePadding.x * 2);
    float stripH = 0;
    if (!chat.pending.empty()) {
        const float sp = ImGui::GetStyle().ItemSpacing.x;
        const int perRow = std::max(1, static_cast<int>((ImGui::GetContentRegionAvail().x + sp) / (thumbCell + sp)));
        const int rows = (static_cast<int>(chat.pending.size()) + perRow - 1) / perRow;
        stripH = static_cast<float>(rows) * (kThumb + ImGui::GetTextLineHeight() + 2 * ImGui::GetStyle().ItemSpacing.y);
    }

    // Transcript.
    const float inputH = ImGui::GetTextLineHeight() * 3.4f + 8;
    const float footer = stripH + inputH + ImGui::GetFrameHeightWithSpacing() * 1.4f;
    ImGui::BeginChild("##chat", ImVec2(0, -footer), ImGuiChildFlags_Borders);
    ImGui::PushTextWrapPos(0.0f);
    if (chat.items.empty()) {
        ImGui::TextDisabled("Describe what you want built or changed. The assistant uses the same commands as the console (scene.*, fs.*, game.*...) and edits the open scene. Changes can be undone with Ctrl+Z.");
        ImGui::TextDisabled("To show it a picture: drop image files on this window, press Ctrl+V with a picture copied, or use Attach image.");
    }
    int idx = 0;
    for (const ChatItem& c : chat.items) {
        ImGui::PushID(idx++);
        if (c.depth > 0) ImGui::Indent(12.0f * float(c.depth));
        switch (c.kind) {
            case ChatItem::Kind::User:
                ImGui::TextColored(ImVec4(0.55f, 0.78f, 1.0f, 1), "You");
                ImGui::TextUnformatted(c.text.c_str());
                if (!c.images.empty()) {
                    Flow flow;
                    for (std::size_t j = 0; j < c.images.size(); ++j) {
                        flow.place(kThumbSent);
                        ImGui::PushID(static_cast<int>(j));
                        draw_thumb(*this, c.images[j], kThumbSent);
                        ImGui::PopID();
                    }
                }
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
    if (chat.scrollDown) {
        ImGui::SetScrollHereY(1.0f);
        chat.scrollDown = false;
    }
    ImGui::EndChild();

    // Pictures waiting to be sent, each with a remove button.
    if (!chat.pending.empty()) {
        int removeAt = -1;
        Flow flow;
        for (std::size_t i = 0; i < chat.pending.size(); ++i) {
            flow.place(thumbCell);
            ImGui::PushID(static_cast<int>(i));
            ImGui::BeginGroup();
            draw_thumb(*this, chat.pending[i].path, kThumb);
            if (ImGui::SmallButton("Remove")) removeAt = static_cast<int>(i);
            ImGui::SetItemTooltip("Do not send %s", chat.pending[i].name.c_str());
            ImGui::EndGroup();
            ImGui::PopID();
        }
        if (removeAt >= 0) chat.pending.erase(chat.pending.begin() + removeAt);  // the copy in .factoria/ai/attachments stays
    }

    // Input.
    ImGui::BeginDisabled(isRunTab);
    bool submit = ImGui::InputTextMultiline("##ai_input", &chat.input, ImVec2(-FLT_MIN, inputH),
                                            ImGuiInputTextFlags_EnterReturnsTrue | ImGuiInputTextFlags_CtrlEnterForNewLine);
    const bool inputActive = ImGui::IsItemActive();
    ImGui::EndDisabled();
    const bool gameRuns = play_ != PlayState::Edit;  // the assistant edits in edit mode only (see ai_start)
    if (!isRunTab && chat.input.empty()) {
        // hint text drawn over the empty box
        ImVec2 p = ImGui::GetItemRectMin();
        ImGui::GetWindowDrawList()->AddText(ImVec2(p.x + 6, p.y + 4), IM_COL32(120, 125, 140, 255),
                                            gameRuns ? "The game is running: press Stop (F5) to talk to the assistant."
                                                     : "Ask the assistant...  (Enter sends, Ctrl+Enter newline)");
    }
    // Ctrl+V with a picture on the clipboard. ImGui pastes text by itself; a clipboard with text keeps doing just that.
    if (inputActive && ImGui::IsKeyChordPressed(ImGuiMod_Ctrl | ImGuiKey_V)) {
        const char* clipboardText = ImGui::GetClipboardText();
        if (!clipboardText || !*clipboardText) ai_paste_image();
    }
    const bool canRun = anyListed || !detected;
    ImGui::BeginDisabled(running || chat.input.empty() || !canRun || gameRuns);
    if (ImGui::Button("Run") || (submit && !running && !chat.input.empty() && canRun && !gameRuns)) {
        std::string task = chat.input;
        chat.input.clear();
        ai_start(task);
    }
    ImGui::EndDisabled();
    if (gameRuns && ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) {
        ImGui::SetTooltip("The game is running. Press Stop (F5) first: what the assistant changed while it runs\n"
                          "would be thrown away at Stop, which puts the scene back as it was before Play.");
    } else if (otherRunning && ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) {
        const AiChat* busy = chat_.find(aiRunChat_);
        ImGui::SetTooltip("The assistant is busy in another chat (%s).\nOne run at a time: wait for it, or press Stop in that tab.",
                          busy && !busy->title.empty() ? busy->title.c_str() : "New chat");
    }
    ImGui::SameLine();
    ImGui::BeginDisabled(!isRunTab);
    if (ImGui::Button("Stop")) aiCancel_ = true;
    ImGui::EndDisabled();
    ImGui::SameLine();
    if (ImGui::Button("Attach image...")) {
        const std::string file = pick_file("Attach an image", projectDir_, "Images", {"png", "jpg", "jpeg", "gif", "webp"});
        if (!file.empty()) ai_attach_path(file);
    }
    ImGui::SetItemTooltip("Add a picture to your next message (png, jpg, gif, webp).\nYou can also drop image files on the window, or press Ctrl+V in the message box with a picture copied.");
    ImGui::SameLine();
    if (isRunTab) ImGui::TextColored(ImVec4(1, 0.85f, 0.4f, 1), "running...");
    else if (otherRunning) ImGui::TextDisabled("busy in another chat");
    else if (gameRuns) ImGui::TextDisabled("game running: Stop it to send");
    ImGui::PopID();
    ImGui::End();
}

}  // namespace fa::editor
