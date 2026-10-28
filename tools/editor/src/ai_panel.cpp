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
#include <string_view>

#include "editor_internal.h"
#include "fa/ai/commands.h"
#include "fa/mcp/server.h"
#include "imgui_internal.h"
#include "sokol_app.h"
#include "ui_backend.h"

namespace fa::editor {

namespace {

constexpr const auto& kRoleNames = ai::kAllRoles;  // all seven, in the order of the Roles window
constexpr const char* kEfforts[] = {"", "low", "medium", "high", "xhigh", "max"};  // "" = the role's default
constexpr u64 kContextLimits[] = {0, 100000, 200000, 300000, 400000, 500000, 600000, 800000};  // 0 = the model's window
constexpr const char* kRolesBlurb = "Your messages go to the orchestrator. It answers and plans, and hands implementation work to\n"
                                    "the worker, small mechanical edits to fast, art to the artist and sound to audio by itself.\n"
                                    "artCritic and reviewer only run when you press Art critique or Game review; they cannot change anything.";
constexpr std::size_t kMaxPendingImages = 10;  // per message (the API providers take 20 and the CLIs read each one)
constexpr float kThumb = 56.0f;                // pending pictures
constexpr float kThumbSent = 48.0f;            // pictures in the transcript

i64 now_epoch() { return static_cast<i64>(std::time(nullptr)); }

// The editor's own clock for "how long since": steady, in milliseconds (never the simulation's clock).
long long now_ms() {
    return std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now().time_since_epoch()).count();
}
double now_seconds() { return static_cast<double>(now_ms()) / 1000.0; }

// One line of at most n bytes (cut at a UTF-8 character boundary), "..." when it was longer.
std::string short_line(std::string s, size_t n) {
    std::ranges::replace(s, '\n', ' ');
    if (s.size() <= n) return s;
    size_t cut = n;
    while (cut > 0 && (static_cast<unsigned char>(s[cut]) & 0xC0) == 0x80) --cut;
    s.resize(cut);
    return s + "...";
}

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

// Right-click menu of a text box: Cut, Copy, Paste, Select all (ImGui has none). Opening the menu takes the focus from the
// box, so Cut, Paste and Select all activate it again (ActivateItemByID) and text_menu_callback applies them on the next
// frame inside ImGui's own buffer: cursor, wrapping and Ctrl+Z stay right. Copy reads the selection directly.
enum class TextAction { None, Cut, Paste, SelectAll };
struct PendingTextAction {
    ImGuiID id = 0;
    TextAction action = TextAction::None;
    bool atEnd = false;  // the box has no cursor of its own (another box was used last): paste at the end
};
PendingTextAction pendingTextAction;  // one menu is open at a time

int text_menu_callback(ImGuiInputTextCallbackData* d) {
    PendingTextAction& p = pendingTextAction;
    if (p.id != d->ID || p.action == TextAction::None) return 0;
    if (p.atEnd) d->CursorPos = d->SelectionStart = d->SelectionEnd = d->BufTextLen;
    int a = std::clamp(std::min(d->SelectionStart, d->SelectionEnd), 0, d->BufTextLen);
    int b = std::clamp(std::max(d->SelectionStart, d->SelectionEnd), 0, d->BufTextLen);
    if (a == b) a = b = std::clamp(d->CursorPos, 0, d->BufTextLen);
    if (p.action == TextAction::Cut) {
        ImGui::SetClipboardText(std::string(d->Buf + a, d->Buf + b).c_str());
        d->DeleteChars(a, b - a);
    } else if (p.action == TextAction::Paste) {
        if (const char* clip = ImGui::GetClipboardText(); clip && *clip) {
            d->DeleteChars(a, b - a);
            d->InsertChars(a, clip);
        }
    } else {
        d->SelectAll();
    }
    p = {};
    return 0;
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

// The menu of the InputText just submitted on `text` (which must pass text_menu_callback with CallbackAlways).
void Editor::text_menu(const std::string& text, bool readOnly) {
    const ImGuiID id = ImGui::GetItemID();
    if (id == 0 || !ImGui::BeginPopupContextItem()) return;  // 0: the box is scrolled out of a small window (no menu to open)
    const ImGuiInputTextState* s = ImGui::GetInputTextState(id);
    // ImGui keeps a box's cursor only while its text is unchanged (an editable box) and no other box was used since.
    const bool fresh = !s || (!readOnly && std::string_view(s->TextA.Data ? s->TextA.Data : "", size_t(s->TextLen)) != text);
    size_t a = 0, b = 0;
    if (!fresh && s->HasSelection()) {
        a = std::min<size_t>(std::min(s->GetSelectionStart(), s->GetSelectionEnd()), text.size());
        b = std::min<size_t>(std::max(s->GetSelectionStart(), s->GetSelectionEnd()), text.size());
    }
    auto later = [&](TextAction action) {
        pendingTextAction = {id, action, fresh};
        ImGui::ActivateItemByID(id);
    };
    auto item = [&](const char* label, const char* keys, bool enabled) {
        const bool chosen = ImGui::MenuItem(label, keys, false, enabled);
        at_track(std::string("textmenu:") + label);
        return chosen;
    };
    if (!readOnly && item("Cut", "Ctrl+X", a < b)) later(TextAction::Cut);
    if (item("Copy", "Ctrl+C", a < b)) ImGui::SetClipboardText(text.substr(a, b - a).c_str());
    if (!readOnly) {
        const char* clip = ImGui::GetClipboardText();
        if (item("Paste", "Ctrl+V", clip && *clip)) later(TextAction::Paste);
    }
    ImGui::Separator();
    if (item("Select all", "Ctrl+A", !text.empty())) later(TextAction::SelectAll);
    ImGui::EndPopup();
}

// A transcript message as a read-only, word-wrapped text box sized to its text: drag to select, Ctrl+C or the right-click
// menu to copy. It looks like plain text and scrolls with the transcript.
void Editor::message_text(const char* id, std::string& text, const ImVec4* color) {
    const ImGuiStyle& st = ImGui::GetStyle();
    const float w = ImGui::GetContentRegionAvail().x;
    const float wrap = std::max(1.0f, w - st.FramePadding.x * 2 - st.ScrollbarSize);  // what ImGuiInputTextFlags_WordWrap uses
    // Its line count as InputTextLineIndexBuild counts it, so the box never needs a scrollbar of its own.
    const char* end = text.data() + text.size();
    int lines = 0;
    for (const char* p = text.data(); p < end; p = *p == '\n' ? p + 1 : p) {
        ++lines;
        p = ImFontCalcWordWrapPositionEx(ImGui::GetFont(), ImGui::GetFontSize(), p, end, wrap, ImDrawTextFlags_WrapKeepBlanks);
    }
    lines = std::max(lines, 1) + (!text.empty() && text.back() == '\n' ? 1 : 0);
    ImGui::PushStyleColor(ImGuiCol_FrameBg, ImVec4(0, 0, 0, 0));
    if (color) ImGui::PushStyleColor(ImGuiCol_Text, *color);
    ImGui::InputTextMultiline(id, &text, ImVec2(w, static_cast<float>(lines) * ImGui::GetFontSize() + st.FramePadding.y * 2),
                              ImGuiInputTextFlags_ReadOnly | ImGuiInputTextFlags_WordWrap | ImGuiInputTextFlags_CallbackAlways,
                              text_menu_callback);
    at_track("ai:message");
    ImGui::PopStyleColor(color ? 2 : 1);
    text_menu(text, true);
}

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
            if (!s.available || ai::is_asset_only_kind(cfg.providers.at(s.name).kind)) continue;
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
    // The worker's events reach the panel live: into aiPending_ (one lock, same queue as the orchestrator's own events,
    // so the order is the order they happened), drawn one level in. They are drained into aiRunChat_, the chat that
    // started the run, whichever tab is in front.
    ao.onRunStart = [this](const ai::AiRunInfo& info) {
        std::lock_guard<std::mutex> lock(aiMu_);
        AiDelegate d;
        d.info = info;
        aiDelegates_.push_back(std::move(d));
        aiLastActivityMs_ = now_ms();
        aiActivity_ = info.role + ": starting";
    };
    ao.onRunEvent = [this](const ai::AiRunInfo&, const ai::AgentEvent& ev) {
        ai::AgentEvent shown = ev;
        shown.depth += 1;
        ai_note_event(shown);
    };
    ao.onRunProcess = [this](const ai::AiRunInfo& info, long long pid) {
        std::lock_guard<std::mutex> lock(aiMu_);
        aiProcs_.push_back(AiProc{pid, info.id, info.role});
    };
    ao.onRunEnd = [this](const ai::AiRunInfo& info, bool ok, const std::string& report, const std::string& error) {
        std::lock_guard<std::mutex> lock(aiMu_);
        for (AiDelegate& d : aiDelegates_) {
            if (d.info.id != info.id) continue;
            d.ended = true;
            d.ok = ok;
            d.report = report;
            d.error = error;
        }
        std::erase_if(aiProcs_, [&](const AiProc& p) { return p.runId == info.id; });
        std::erase_if(aiTools_, [](const AiTool& t) { return t.depth >= 1; });
        aiLastActivityMs_ = now_ms();
    };
    ai::register_ai_commands(*reg, ao);
    return reg;
}

// The chat tabs belong to the open project (<project>/.factoria/ai/chats): when the project changed (boot() stopped the
// agent first, which saved its chat), load the new project's tabs. Called by everything that touches chat_, so boot()
// needs no knowledge of the chats.
void Editor::ai_sync_chats() {
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

// Starts the endpoint CLI agents attach (see the top of this file) when it is not up yet. False (with a notice) when it cannot.
bool Editor::ai_ensure_mcp() {
    if (aiMcp_.url().empty()) {  // the endpoint CLI agents attach (see the top of this file)
        // StreamHandler: a long ai.run call reports progress (what the worker does) as MCP notifications on its own request, so
        // Claude Code, which aborts a call that stays silent for 300 s, keeps waiting for as long as the worker really works.
        auto started = aiMcp_.start([this, dir = projectDir_](std::string_view message,
                                                              const McpHttpServer::Notify& emit) -> std::optional<std::string> {
            std::shared_ptr<CommandRegistry> proxy;
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                proxy = aiProxy_;
            }
            if (!proxy) return std::nullopt;  // not reached: the URL is handed out after the run's proxy exists
            SimpleMcpHost host(*proxy, dir);
            McpServer server(host);  // stateless: one server per message
            server.set_notification_sink([&emit](const std::string& n) { emit(n); });
            return server.handle_message(message);
        });
        if (!started) {
            notify(started.error().to_string(), 2);
            return false;
        }
    }
    return true;
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
    if (!ai_ensure_mcp()) return;
    AiChat& chat = chat_.current();
    ai::AiConfig cfg;
    {
        std::lock_guard<std::mutex> lock(aiMu_);
        cfg = aiConfig_;
        if (cfg.providers.empty()) cfg = ai::default_config();
    }

    ChatItem user;
    user.kind = ChatItem::Kind::User;
    user.text = task;
    std::vector<std::string> imageFiles;  // absolute paths for the agent
    for (const ChatAttachment& a : chat.pending) {
        user.images.push_back(a.path);
        imageFiles.push_back(utf8_string(utf8_path(projectDir_) / utf8_path(a.path)));
    }
    chat.pending.clear();
    const std::string revertNote = revert_line(chat.items);  // before this message: what the user reverted since the last one
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
    if (!revertNote.empty()) prompt = revertNote + "\n" + prompt;
    ai_run_checkpoint_begin(task);  // before the agent thread exists: it cannot touch a file first

    aiRunChat_ = chat.id;
    ai_reset_run_state();
    ai_launch(prompt, imageFiles);
}

// A fresh run: nothing is left of the previous one's cancel flag and liveness.
void Editor::ai_reset_run_state() {
    aiCancel_ = false;
    {  // a fresh run: nothing is left of the previous one's liveness
        std::lock_guard<std::mutex> lock(aiMu_);
        aiDelegates_.clear();
        aiProcs_.clear();
        aiTools_.clear();
        aiActivity_.clear();
    }
    aiDetachedOk_ = false;
    aiRunStartMs_ = aiLastActivityMs_ = now_ms();
    aiSnoozeUntil_ = 0;
    aiSampledAt_ = 0;
    aiCpu_.clear();
    aiLastTree_.clear();
}

void Editor::ai_launch(const std::string& prompt, const std::vector<std::string>& imageFiles) {
    AiChat* chat = chat_.find(aiRunChat_);
    if (!chat) {  // the chat is gone (the project changed): nothing to run for
        ai_end_run(nullptr);
        return;
    }
    if (aiThread_.joinable()) aiThread_.join();
    ai::AiConfig cfg;
    {
        std::lock_guard<std::mutex> lock(aiMu_);
        cfg = aiConfig_;
        if (cfg.providers.empty()) cfg = ai::default_config();
    }
    ai::SessionOptions opt;
    opt.projectDir = projectDir_;
    // The orchestrator hands the work to the other roles itself (the "AI roles" popup). A review (ai_review.cpp) runs a critic or
    // a reviewer instead, who cannot delegate.
    opt.role = aiRunRole_.empty() ? std::string(ai::kRoleOrchestrator) : aiRunRole_;
    opt.extraSystem = aiRunExtra_;
    opt.allowDelegation = !ai::is_review_role(opt.role);
    opt.conversation = chat->conversation;  // resumes the chat when the provider is the same one that produced it
    opt.mcpUrl = aiMcp_.url();
    opt.onProcessStart = [this](long long pid, const std::string& role) {
        std::lock_guard<std::mutex> lock(aiMu_);
        aiProcs_.push_back(AiProc{pid, std::string(), role});
    };
    aiRunProvider_ = cfg.role(opt.role).provider;
    queue_.reopen();
    auto proxy = make_proxy_registry();
    {
        std::lock_guard<std::mutex> lock(aiMu_);
        aiProxy_ = proxy;
    }
    aiRunning_ = true;
    aiLastActivityMs_ = now_ms();
    ai::ProviderFactory factory = aiFactory_;
    aiThread_ = std::thread([this, cfg, opt, prompt, imageFiles, proxy, factory] {
        ai::AgentSession session(*proxy, cfg, opt);
        if (factory) session.set_provider_factory(factory);
        session.set_event_handler([this](const ai::AgentEvent& ev) { ai_note_event(ev); });
        session.set_cancel_flag(&aiCancel_);
        ai::SessionResult r = session.run(prompt, imageFiles);
        {
            std::lock_guard<std::mutex> lock(aiMu_);
            aiResult_ = r;
            // The orchestrator's own process and tool calls are over. A delegated worker that still runs is an orphan:
            // its ai_run call will never return its result to anyone (Claude Code gave up on it, or its turn ended
            // without waiting). The run stays "running" until that worker ends (ai_drain_events).
            std::erase_if(aiProcs_, [](const AiProc& p) { return p.runId.empty(); });
            std::erase_if(aiTools_, [](const AiTool& t) { return t.depth == 0; });
            bool orphans = false;
            for (AiDelegate& d : aiDelegates_) {
                if (d.ended) continue;
                d.orphan = true;
                orphans = true;
            }
            if (orphans) aiDetached_ = true;  // before aiRunning_ goes false: ai_running() never flickers
        }
        aiRunning_ = false;
    });
}

// Bookkeeping of one agent event: queued for the main thread, and the liveness the watchdog and the activity line read.
void Editor::ai_note_event(const ai::AgentEvent& ev) {
    using T = ai::AgentEvent::Type;
    const std::string what = ai::describe_agent_event(ev);
    std::lock_guard<std::mutex> lock(aiMu_);
    aiPending_.push_back(ev);
    aiLastActivityMs_ = now_ms();
    if (!what.empty()) aiActivity_ = (ev.depth > 0 ? (ev.role.empty() ? std::string("worker") : ev.role) + " > " : std::string()) + what;
    if (ev.type == T::ToolStart) {
        aiTools_.push_back(AiTool{ev.toolName, what, ev.depth, now_ms()});
    } else if (ev.type == T::ToolEnd) {
        for (auto it = aiTools_.rbegin(); it != aiTools_.rend(); ++it) {
            if (it->name == ev.toolName && it->depth == ev.depth) {
                aiTools_.erase(std::next(it).base());
                break;
            }
        }
    }
}

void Editor::ai_stop() {
    aiCancel_ = true;
    queue_.close();
    if (aiThread_.joinable()) aiThread_.join();
    aiMcp_.stop();  // after the cancel and the closed queue: its requests (ai.run included) end instead of waiting
    aiRunning_ = false;
    ai_drain_events();  // the cancelled run's last events and result: its chat is saved here (cancel still set: no continuation)
    if (!aiRunChat_.empty() || aiDetached_.load()) ai_end_run(chat_.find(aiRunChat_));  // a worker that never reported back
    aiCancel_ = false;
    queue_.reopen();
    aiRunProvider_.clear();
}

void Editor::ai_end_run(AiChat* c) {
    if (c) {
        for (ChatItem& it : c->items) {  // a tool call whose end never came (the call was cut off)
            if (it.kind == ChatItem::Kind::Tool && !it.done) {
                it.done = true;
                it.isError = true;
                it.result = "no result: the run ended before this call returned";
            }
        }
        ai_run_checkpoint_finish(*c);
        chat_.save(*c);  // saved after every run (no timer): the chat survives a crash or a closed editor
        chat_.save_open_list();
    } else {
        aiRunCheckpoint_.clear();
    }
    aiRunChat_.clear();
    aiRunProvider_.clear();
    aiRunRole_.clear();
    aiRunExtra_.clear();
    aiDetached_ = false;
    aiDetachedOk_ = false;
    std::lock_guard<std::mutex> lock(aiMu_);
    aiDelegates_.clear();
    aiProcs_.clear();
    aiTools_.clear();
}

// What the orchestrator is told when a worker it started finished after its turn ended.
static std::string continuation_prompt(const std::vector<std::pair<ai::AiRunInfo, std::string>>& reports) {
    std::string out =
        "The worker you started with ai_run finished after your turn ended, so its result never reached you. "
        "Here is what it reported.\n";
    for (const auto& [info, text] : reports) {
        out += "\n--- " + info.role + " worker, task: " + clip(info.task, 300) + "\n" + text + "\n";
    }
    out += "\nCarry on from here: check the result against what the user asked, finish whatever is left, and tell the user "
           "what was done. Do not start the same work again.";
    return out;
}

// Called every frame while a run is on, from ai_drain_events. About every 5 s it samples the CPU use of the CLI agents'
// processes (what "Check activity" compares) and notices a process that is gone while its run is not over: a crashed
// CLI whose descendants keep the pipes open would otherwise leave the panel saying "running" for good.
void Editor::ai_watchdog_tick() {
    if (!ai_running()) return;
    const double now = now_seconds();
    if (now - aiSampledAt_ < 5) return;
    aiSampledAt_ = now;
    std::vector<AiProc> procs;
    {
        std::lock_guard<std::mutex> lock(aiMu_);
        procs = aiProcs_;
    }
    std::vector<ProcessEntry> all;
    const AiProc* dead = nullptr;
    for (const AiProc& p : procs) {
        std::vector<ProcessEntry> tree = process_tree(p.pid);
        if (tree.empty()) {
            double& since = aiDeadSince_[p.pid];
            if (since == 0) since = now;
            else if (now - since >= 10 && !dead) dead = &p;  // gone for two samples, and its run is still going
        } else {
            aiDeadSince_.erase(p.pid);
            all.insert(all.end(), tree.begin(), tree.end());
        }
    }
    aiLastTree_ = all;
    aiCpu_.add(now, all);
    if (dead && !aiCancel_.load()) {
        if (AiChat* chat = chat_.find(aiRunChat_)) {
            ChatItem it;
            it.kind = ChatItem::Kind::Error;
            it.text = "The " + dead->label + " agent's process (pid " + std::to_string(dead->pid) +
                      ") is gone but its run did not end: stopping the run. The agent probably crashed or was closed.";
            chat->items.push_back(std::move(it));
            chat->scrollDown = true;
        }
        aiCancel_ = true;
    }
}

// The "Check activity" button of the stuck warning: looks at the agents' processes, the tool in flight, the project's
// files and the last event, says in the chat whether the agent is working, and snoozes the warning for another period.
void Editor::ai_check_activity() {
    AiChat* chat = chat_.find(aiRunChat_);
    if (!chat) return;
    const long long nowM = now_ms();
    std::vector<AiProc> procs;
    std::string lastEvent;
    AiTool tool;
    bool hasTool = false;
    int stuckAfter = 180;
    {
        std::lock_guard<std::mutex> lock(aiMu_);
        procs = aiProcs_;
        lastEvent = aiActivity_;
        if (!aiTools_.empty()) {
            tool = aiTools_.back();  // the newest call: the innermost one (a worker's under the orchestrator's ai_run)
            hasTool = true;
        }
        if (aiConfig_.limits.stuckAfterSeconds > 0) stuckAfter = aiConfig_.limits.stuckAfterSeconds;
    }
    ai::ActivityInput in;
    in.runSeconds = static_cast<double>(nowM - aiRunStartMs_.load()) / 1000.0;
    in.idleSeconds = static_cast<double>(nowM - aiLastActivityMs_.load()) / 1000.0;
    in.lastEvent = lastEvent;
    if (hasTool) {
        in.tool = tool.text.empty() ? tool.name : tool.text;
        in.toolSeconds = static_cast<double>(nowM - tool.startMs) / 1000.0;
    }
    in.trackedProcess = !procs.empty();
    for (const AiProc& p : procs) {
        std::vector<ProcessEntry> tree = process_tree(p.pid);
        if (tree.empty()) continue;
        ++in.roots;
        in.processes.insert(in.processes.end(), tree.begin(), tree.end());
    }
    aiCpu_.add(now_seconds(), in.processes);
    in.cpuPercent = aiCpu_.percent();
    in.cpuWindowSeconds = aiCpu_.span();
    in.changesWithinSeconds = 120;
    in.changes = ai::recent_file_changes(projectDir_, in.changesWithinSeconds);
    const ai::ActivityVerdict v = ai::judge_activity(in);
    ChatItem it;
    it.kind = v.stuck ? ChatItem::Kind::Error : ChatItem::Kind::Info;
    it.text = "Activity check: " + v.summary;
    for (const std::string& d : v.details) it.text += "\n  " + d;
    chat->items.push_back(std::move(it));
    chat->scrollDown = true;
    aiSnoozeUntil_ = now_seconds() + stuckAfter;  // asked once: quiet until another period of silence has passed
    if (v.processGone && !aiCancel_.load()) {
        ChatItem stop;
        stop.kind = ChatItem::Kind::Info;
        stop.text = "stopping the run";
        chat->items.push_back(std::move(stop));
        aiCancel_ = true;
    }
}

void Editor::ai_drain_events() {
    std::vector<ai::AgentEvent> events;
    std::optional<ai::SessionResult> result;
    bool detached = false, orphansDone = false;
    std::vector<AiDelegate> finished;  // the orphaned workers, once all of them ended
    {
        // One lock for the events, the result and the workers' state: a worker's last events and its end are seen together.
        std::lock_guard<std::mutex> lock(aiMu_);
        events.swap(aiPending_);
        result.swap(aiResult_);
        detached = aiDetached_.load();
        if (detached) {
            orphansDone = std::ranges::all_of(aiDelegates_, [](const AiDelegate& d) { return !d.orphan || d.ended; });
            if (orphansDone) {
                for (AiDelegate& d : aiDelegates_)
                    if (d.orphan) finished.push_back(d);
            }
        }
    }
    if (!events.empty() || result || aiRunning_.load() || detached) ai_watchdog_tick();
    if (events.empty() && !result && !(detached && orphansDone)) return;
    AiChat orphan;  // the run's chat is gone (the project changed under it): its text is dropped, the plan limits are kept
    AiChat* found = chat_.find(aiRunChat_);
    AiChat& c = found ? *found : orphan;
    std::vector<ChatItem>& items = c.items;
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
        } else if (detached) {
            it.kind = ChatItem::Kind::Info;
            it.text = "The orchestrator's turn ended while its worker is still running. When the worker finishes, its report goes "
                      "back to the orchestrator and the work continues (Stop ends both).";
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
        if (detached) {
            aiDetachedOk_ = result->ok && !aiCancel_.load();
            for (ChatItem& t : items) {  // the orchestrator's ai_run call will never return
                if (t.kind == ChatItem::Kind::Tool && !t.done && t.depth == 0) {
                    t.done = true;
                    t.isError = true;
                    t.result = "no result: the orchestrator's turn ended while the worker still ran";
                }
            }
        } else {
            ai_end_run(found);
            return;
        }
    }
    if (detached && orphansDone) {
        // Every worker that outlived the orchestrator's turn is done. Its report is in the chat; the orchestrator, whose
        // session never saw it, is continued with it (the same Claude Code session) unless Stop was pressed.
        std::vector<std::pair<ai::AiRunInfo, std::string>> reports;
        for (const AiDelegate& d : finished) {
            ChatItem head;
            head.kind = d.ok ? ChatItem::Kind::Info : ChatItem::Kind::Error;
            head.depth = 1;
            head.text = d.ok ? d.info.role + " agent finished" : d.info.role + " agent failed: " + d.error;
            items.push_back(std::move(head));
            std::string streamed;  // the report is usually the worker's last streamed text: do not print it twice
            for (std::size_t k = items.size() > 40 ? items.size() - 40 : 0; k < items.size(); ++k)
                if (items[k].kind == ChatItem::Kind::Assistant && items[k].depth == 1) streamed += items[k].text;
            const bool shown = streamed.find(d.report) != std::string::npos;
            if (d.ok && !d.report.empty() && !shown) {
                ChatItem rep;
                rep.kind = ChatItem::Kind::Assistant;
                rep.depth = 1;
                rep.role = d.info.role;
                rep.text = d.report;
                items.push_back(std::move(rep));
            }
            reports.emplace_back(d.info, d.ok ? d.report : "The worker failed: " + d.error);
        }
        c.scrollDown = true;
        const bool cont = found && aiDetachedOk_ && !aiCancel_.load() && engine_ && play_ == PlayState::Edit;
        {
            std::lock_guard<std::mutex> lock(aiMu_);
            aiDelegates_.clear();
            aiProcs_.clear();
            aiTools_.clear();
        }
        if (cont) {
            ChatItem note;
            note.kind = ChatItem::Kind::Info;
            note.text = "continuing the orchestrator with the worker's report";
            items.push_back(std::move(note));
            aiDetachedOk_ = false;
            ai_launch(continuation_prompt(reports), {});  // aiRunning_ is true before the flag below drops
            aiDetached_ = false;
            c.updated = now_epoch();
        } else {
            if (aiCancel_.load()) {
                ChatItem note;
                note.kind = ChatItem::Kind::Info;
                note.text = "stopped";
                items.push_back(std::move(note));
            }
            ai_end_run(found);
        }
    }
}

// ---------------------------------------------------------------------------------------------------------------------

// "AI roles": the provider, model and effort of the seven roles. Save writes them into ai.json
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
                    if (ai::is_asset_only_kind(pc.kind)) continue;  // they generate assets, they cannot play a role
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
            const auto rstatus = std::ranges::find(status, r.provider, &ai::ProviderStatus::name);
            const auto listed = models.find(r.provider);
            const bool listOk = listed != models.end() && listed->second.error.empty();
            // A provider that could not list its models (Claude Code not installed or not logged in yet) still offers
            // the ones it always accepts, so picking it never leaves a bare text box.
            const auto pcfg = cfg.providers.find(r.provider);
            const std::vector<ai::ModelInfo> fallback =
                listOk || pcfg == cfg.providers.end() ? std::vector<ai::ModelInfo>{} : ai::fallback_models(pcfg->second.kind);
            const std::string listError = listed != models.end() ? listed->second.error : std::string();
            if (rstatus != status.end() && !rstatus->available) {
                // Nothing to pick from: say why instead of a model box (the role keeps its model for when it is set up).
                ImGui::BeginDisabled();
                if (ImGui::BeginCombo("##model", "Provider not available")) ImGui::EndCombo();
                ImGui::EndDisabled();
                if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) {
                    ImGui::SetTooltip("%s\n%s", rstatus->detail.c_str(), rstatus->hint.c_str());
                }
            } else if ((listOk || !fallback.empty()) && !aiRolesTyping_.contains(name)) {
                // The models the provider offers; "Other..." types one that is not in the list.
                const std::vector<ai::ModelInfo>& list = listOk ? listed->second.models : fallback;
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
                if (!listOk) {
                    ImGui::SetItemTooltip("Its models could not be listed, so these are the aliases it always accepts.\n%s",
                                          listError.empty() ? "Still asking it (Refresh models)." : listError.c_str());
                }
            } else {
                ImGui::InputTextWithHint("##model", "default", &r.model);
                // Typed text that is empty or in the list sends the role back to the list.
                const std::vector<ai::ModelInfo>& back = listOk ? listed->second.models : fallback;
                if (ImGui::IsItemDeactivated() && (listOk || !fallback.empty()) &&
                    (r.model.empty() || std::ranges::find(back, r.model, &ai::ModelInfo::id) != back.end())) {
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
        // A role the user did not change is not written: artist, audio, artCritic and reviewer follow the orchestrator's and
        // the worker's provider until they are set here (docs/AI_PROVIDERS.md), and writing them would pin today's values.
        std::map<std::string, ai::RoleConfig> toSave = aiRolesEdit_;
        for (const char* extra : ai::kExtraRoles) {
            const ai::RoleConfig was = cfg.role(extra), now = toSave[extra];
            if (was.provider == now.provider && was.model == now.model && was.effort == now.effort &&
                was.maxContextTokens == now.maxContextTokens)
                toSave.erase(extra);
        }
        if (auto saved = ai::save_roles(toSave, path); !saved) {
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
    const bool running = ai_running();  // includes the wait for a worker that outlived the orchestrator's turn
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

    // The roles. Every message goes to the orchestrator; it hands the work to the worker, fast, artist and audio roles itself.
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
    const float noticeH = playNotice_.empty() ? 0.0f : ImGui::GetFrameHeightWithSpacing();
    // The run's status lines (below the transcript): the pulse, "worker still running", the stuck warning.
    const bool showDetached = isRunTab && aiDetached_.load();
    const bool showStuck = isRunTab && cfg.limits.stuckAfterSeconds > 0 &&
                           static_cast<double>(now_ms() - aiLastActivityMs_.load()) / 1000.0 >= cfg.limits.stuckAfterSeconds &&
                           now_seconds() >= aiSnoozeUntil_;
    const float statusH = !isRunTab ? 0.0f : ImGui::GetFrameHeightWithSpacing() * (1.0f + (showDetached ? 2.0f : 0.0f) + (showStuck ? 2.0f : 0.0f));
    const float footer = stripH + noticeH + statusH + inputH + ImGui::GetFrameHeightWithSpacing() * 3.4f;  // buttons + the two review rows
    ImGui::BeginChild("##chat", ImVec2(0, -footer), ImGuiChildFlags_Borders);
    ImGui::PushTextWrapPos(0.0f);
    if (chat.items.empty()) {
        ImGui::TextDisabled("Describe what you want built or changed. The assistant uses the same commands as the console (scene.*, fs.*, game.*...) and edits the open scene. Changes can be undone with Ctrl+Z.");
        ImGui::TextDisabled("To show it a picture: drop image files on this window, press Ctrl+V with a picture copied, or use Attach image.");
    }
    int idx = 0;
    for (ChatItem& c : chat.items) {
        ImGui::PushID(idx++);
        if (c.depth > 0) ImGui::Indent(12.0f * float(c.depth));
        switch (c.kind) {
            case ChatItem::Kind::User:
                ImGui::TextColored(ImVec4(0.55f, 0.78f, 1.0f, 1), "You");
                message_text("##text", c.text);
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
                message_text("##text", c.text);
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
            case ChatItem::Kind::Error: {
                const ImVec4 red(1, 0.45f, 0.4f, 1);
                message_text("##text", c.text, &red);
                break;
            }
            case ChatItem::Kind::Run:
            case ChatItem::Kind::Revert:
                draw_ai_run_item(c, chat, idx - 1);
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

    // After Stop: the play session had marks or errors, offer to show them to the assistant.
    if (!playNotice_.empty()) {
        ImGui::TextColored(ImVec4(1, 0.85f, 0.4f, 1), "%s", playNotice_.c_str());
        ImGui::SameLine();
        if (ImGui::SmallButton("Attach##playnotice")) ai_attach_last_session();
    }

    // The run's pulse: how long it has been going, how long since the agent last did anything, and what it did. Under
    // it the warning for an agent that has been silent for limits.stuckAfterSeconds (ai.json), with the way out.
    if (isRunTab) {
        const long long nowM = now_ms();
        const double idle = static_cast<double>(nowM - aiLastActivityMs_.load()) / 1000.0;
        const double elapsed = static_cast<double>(nowM - aiRunStartMs_.load()) / 1000.0;
        std::string activity;
        {
            std::lock_guard<std::mutex> lock(aiMu_);
            activity = aiActivity_;
        }
        if (showDetached) {
            ImGui::PushTextWrapPos(0.0f);
            ImGui::TextColored(ImVec4(1, 0.85f, 0.4f, 1), "Worker still running: the orchestrator's turn ended, its report will continue the chat.");
            ImGui::PopTextWrapPos();
            at_track("ai:detached");
        }
        ImGui::TextDisabled("running %s  |  last activity %s ago%s%s", ai::format_duration(elapsed).c_str(), ai::format_duration(idle).c_str(),
                            activity.empty() ? "" : "  |  ", short_line(activity, 60).c_str());
        at_track("ai:status");
        if (showStuck) {
            ImGui::TextColored(ImVec4(1, 0.6f, 0.35f, 1), "No activity for %s: the agent may be stuck.", ai::format_duration(idle).c_str());
            at_track("ai:stuck");
            if (ImGui::SmallButton("Stop##stuck")) aiCancel_ = true;
            at_track("ai:stuck:stop");
            ImGui::SetItemTooltip("Stops the agent (and a worker it started).");
            ImGui::SameLine();
            if (ImGui::SmallButton("Check activity##stuck")) ai_check_activity();
            at_track("ai:stuck:check");
            ImGui::SetItemTooltip("Looks at the agent's process (alive? using CPU?), the tool call it is waiting for, its child\n"
                                  "processes and the project's recent file changes, and says whether it is still working.\n"
                                  "The warning stays quiet for another period afterwards.");
        }
    }

    // Input.
    ImGui::BeginDisabled(isRunTab);
    bool submit = ImGui::InputTextMultiline("##ai_input", &chat.input, ImVec2(-FLT_MIN, inputH),
                                            ImGuiInputTextFlags_EnterReturnsTrue | ImGuiInputTextFlags_CtrlEnterForNewLine |
                                                ImGuiInputTextFlags_WordWrap | ImGuiInputTextFlags_CallbackAlways,
                                            text_menu_callback);
    const bool inputActive = ImGui::IsItemActive();
    at_track("ai:input");
    text_menu(chat.input, false);
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
    at_track("ai:stop");
    ImGui::EndDisabled();
    ImGui::SameLine();
    if (ImGui::Button("Attach image...")) {
        const std::string file = pick_file("Attach an image", projectDir_, "Images", {"png", "jpg", "jpeg", "gif", "webp"});
        if (!file.empty()) ai_attach_path(file);
    }
    ImGui::SetItemTooltip("Add a picture to your next message (png, jpg, gif, webp).\nYou can also drop image files on the window, or press Ctrl+V in the message box with a picture copied.");
    ImGui::SameLine();
    if (ImGui::Button("Attach last play session")) ai_attach_last_session();
    ImGui::SetItemTooltip("Adds a summary of your last Play .. Stop (frame times, errors, the problems you marked with F9) and the mark screenshots to your next message.");
    if (isRunTab) {
        ImGui::SameLine();
        ImGui::TextColored(ImVec4(1, 0.85f, 0.4f, 1), "running...");
    } else if (otherRunning) {
        ImGui::SameLine();
        ImGui::TextDisabled("busy in another chat");
    } else if (gameRuns) {
        ImGui::SameLine();
        ImGui::TextDisabled("game running: Stop it to send");
    }
    draw_ai_review_row(gameRuns);
    ImGui::PopID();
    ImGui::End();
    draw_ai_reviews_window();
}

}  // namespace fa::editor
