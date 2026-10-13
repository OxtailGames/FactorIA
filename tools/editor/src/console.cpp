// Console panel: log viewer (fa::recent_logs) + command line.
//   name {json}   runs a registered command through engine.commands()   e.g.  scene.list_entities {}
//   > code        evaluates JavaScript through script.eval              e.g.  > world.entities().length
//   help          lists commands          clear   clears the log
#include <algorithm>
#include <cstring>

#include "editor_internal.h"

namespace fa::editor {

void Editor::run_console_line(const std::string& raw) {
    std::string line = raw;
    size_t a = line.find_first_not_of(" \t");
    if (a == std::string::npos) return;
    line = line.substr(a);
    while (!line.empty() && (line.back() == ' ' || line.back() == '\t')) line.pop_back();
    FA_INFO("console", "> {}", line);
    if (!engine_) {
        FA_WARN("console", "no project open");
        return;
    }
    if (line == "clear") { clear_recent_logs(); return; }
    if (line == "help" || line == "?") {
        std::string names;
        for (const CommandInfo* c : engine_->commands().list()) names += c->name + "  ";
        FA_INFO("console", "commands: {}", names);
        FA_INFO("console", "usage: <command> {{json args}}   |   > <javascript>   |   clear");
        return;
    }
    CommandResult r;
    if (line[0] == '>') {
        std::string code = line.substr(1);
        // Pick the argument name from the command's own schema ("code", "source", "expression"...).
        std::string argName = "code";
        if (const CommandInfo* ci = engine_->commands().info("script.eval")) {
            if (ci->inputSchema.contains("properties") && ci->inputSchema["properties"].is_object()) {
                for (auto it = ci->inputSchema["properties"].begin(); it != ci->inputSchema["properties"].end(); ++it)
                    if (it.value().value("type", "") == "string") { argName = it.key(); break; }
            }
        }
        if (play_ == PlayState::Edit) begin_edit("console:" + std::to_string(uiFrame_));
        r = engine_->commands().call("script.eval", Json::object({{argName, code}}));
    } else {
        size_t sp = line.find_first_of(" \t");
        std::string name = line.substr(0, sp);
        std::string rest = sp == std::string::npos ? "{}" : line.substr(sp + 1);
        auto args = parse_json(rest, "console");
        if (!args) {
            FA_ERROR("console", "arguments are not valid JSON: {}", args.error().to_string());
            return;
        }
        const CommandInfo* ci = engine_->commands().info(name);
        if (ci && !ci->readOnly && play_ == PlayState::Edit) begin_edit("console:" + std::to_string(uiFrame_));
        r = engine_->commands().call(name, *args);
    }
    if (r.ok) FA_INFO("console", "{}", r.result.dump(2));
    else FA_ERROR("console", "{}", r.error.dump(2));
}

namespace {
int history_cb(ImGuiInputTextCallbackData* d) {
    Editor* ed = static_cast<Editor*>(d->UserData);
    if (d->EventFlag == ImGuiInputTextFlags_CallbackHistory) {
        const int n = int(ed->consoleHistory_.size());
        if (n == 0) return 0;
        if (d->EventKey == ImGuiKey_UpArrow) ed->consoleHistoryPos_ = ed->consoleHistoryPos_ < 0 ? n - 1 : std::max(0, ed->consoleHistoryPos_ - 1);
        else if (d->EventKey == ImGuiKey_DownArrow) ed->consoleHistoryPos_ = ed->consoleHistoryPos_ < 0 ? -1 : (ed->consoleHistoryPos_ + 1 >= n ? -1 : ed->consoleHistoryPos_ + 1);
        const char* s = ed->consoleHistoryPos_ >= 0 ? ed->consoleHistory_[size_t(ed->consoleHistoryPos_)].c_str() : "";
        d->DeleteChars(0, d->BufTextLen);
        d->InsertChars(0, s);
    }
    return 0;
}
}  // namespace

void Editor::draw_console() {
    if (!ImGui::Begin("Console")) { ImGui::End(); return; }
    static const char* levels[] = {"trace", "debug", "info", "warn", "error"};
    ImGui::SetNextItemWidth(90);
    ImGui::Combo("##lvl", &consoleLevel_, levels, 5);
    ImGui::SetItemTooltip("Minimum log level to show");
    ImGui::SameLine();
    ImGui::SetNextItemWidth(220);
    ImGui::InputTextWithHint("##cf", "Filter...", &consoleFilter_);
    ImGui::SameLine();
    if (ImGui::Button("Clear")) clear_recent_logs();
    ImGui::SameLine();
    ImGui::Checkbox("Auto-scroll", &consoleAutoScroll_);
    ImGui::SameLine();
    ImGui::TextDisabled("%zu errors logged", error_count());

    const float inputH = ImGui::GetFrameHeightWithSpacing() + 2;
    ImGui::BeginChild("##logs", ImVec2(0, -inputH), ImGuiChildFlags_Borders);
    auto logs = recent_logs(1000, LogLevel(consoleLevel_));
    ImGui::PushStyleVar(ImGuiStyleVar_ItemSpacing, ImVec2(4, 1));
    for (const LogEntry& l : logs) {
        if (!consoleFilter_.empty() && !contains_ci(l.message, consoleFilter_) && !contains_ci(l.category, consoleFilter_)) continue;
        ImGui::PushStyleColor(ImGuiCol_Text, level_color(l.level));
        ImGui::TextDisabled("%7.2f", l.time);
        ImGui::SameLine();
        ImGui::TextColored(ImVec4(0.45f, 0.62f, 0.9f, 1), "[%s]", l.category.c_str());
        ImGui::SameLine();
        ImGui::PushTextWrapPos(0.0f);
        ImGui::TextUnformatted(l.message.c_str());
        ImGui::PopTextWrapPos();
        ImGui::PopStyleColor();
    }
    ImGui::PopStyleVar();
    static std::uint64_t lastSeq = 0;
    const std::uint64_t seq = logs.empty() ? 0 : logs.back().seq;
    if (consoleAutoScroll_ && seq != lastSeq) ImGui::SetScrollHereY(1.0f);
    lastSeq = seq;
    ImGui::EndChild();

    ImGui::SetNextItemWidth(-FLT_MIN);
    if (consoleFocusInput_) { ImGui::SetKeyboardFocusHere(); consoleFocusInput_ = false; }
    if (ImGui::InputTextWithHint("##cmd", "command {json}   |   > javascript   |   help", &consoleInput_,
                                 ImGuiInputTextFlags_EnterReturnsTrue | ImGuiInputTextFlags_CallbackHistory, history_cb, this)) {
        std::string line = consoleInput_;
        consoleInput_.clear();
        if (!line.empty()) {
            consoleHistory_.push_back(line);
            consoleHistoryPos_ = -1;
            run_console_line(line);
        }
        consoleFocusInput_ = true;
    }
    ImGui::End();
}

}  // namespace fa::editor
