// Audio panel (View > Audio): the live play log of the engine (command audio.log). Every audio.play / audio.music from scripts,
// AudioSource component and scene music shows up with the frame it was requested on, the clip, bus, volume and the entity that
// started it. A clip that failed to load (ok: false) is highlighted: a typo in a path is silent in the game but loud here.
// While the game runs the panel asks only for plays newer than the last one it saw (`after`).
#include <algorithm>
#include <cfloat>

#include "editor_internal.h"
#include "imgui_internal.h"

namespace fa::editor {

void Editor::poll_audio(bool force) {
    if (!engine_) return;
    const bool live = play_ != PlayState::Edit;
    // While the game runs (or is paused on a step) ask every frame; in edit mode nothing plays, so only now and then.
    if (!force && !live && time_ - audioPolled_ < 0.5) return;
    audioPolled_ = time_;
    poll_audio_log(engine_->commands(), audioLog_);
}

void Editor::draw_audio_panel() {
    // A newly shown panel joins the Console's tab bar instead of floating.
    if (ImGuiWindow* console = ImGui::FindWindowByName("Console"); console && console->DockId != 0)
        ImGui::SetNextWindowDockID(console->DockId, ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(640, 240), ImGuiCond_FirstUseEver);
    if (!ImGui::Begin("Audio", &showAudio_)) {
        ImGui::End();
        return;
    }
    poll_audio();
    AudioLogState& a = audioLog_;
    ImGui::SetNextItemWidth(220);
    ImGui::InputTextWithHint("##audiofilter", "Filter by path...", &a.filter);
    ImGui::SetItemTooltip("Show only plays whose clip path contains this text");
    ImGui::SameLine();
    ImGui::Checkbox("Failed only", &a.onlyFailed);
    ImGui::SetItemTooltip("Show only plays whose clip could not be loaded (ok: false)");
    ImGui::SameLine();
    if (ImGui::Button("Clear")) clear_audio_log(a);
    ImGui::SetItemTooltip("Forget the plays shown so far; new plays keep appearing");
    ImGui::SameLine();
    ImGui::Checkbox("Auto-scroll", &a.autoScroll);
    ImGui::SameLine();
    size_t failed = 0, shown = 0;
    for (const AudioPlay& p : a.plays) {
        failed += p.ok ? 0 : 1;
        shown += audio_play_visible(p, a) ? 1 : 0;
    }
    ImGui::TextDisabled("%zu play%s", a.plays.size(), a.plays.size() == 1 ? "" : "s");
    if (failed > 0) {
        ImGui::SameLine();
        ImGui::TextColored(ImVec4(1, 0.45f, 0.4f, 1), "%zu failed to load", failed);
    }
    if (play_ != PlayState::Edit) {
        ImGui::SameLine();
        ImGui::TextColored(ImVec4(0.4f, 0.9f, 0.5f, 1), "live");
    }
    if (a.dropped > 0) {
        ImGui::SameLine();
        ImGui::TextDisabled("(the engine log forgot the oldest %llu)", static_cast<unsigned long long>(a.dropped));
    }
    if (!a.error.empty()) ImGui::TextColored(ImVec4(1, 0.45f, 0.4f, 1), "audio.log: %s", a.error.c_str());

    constexpr ImGuiTableFlags flags = ImGuiTableFlags_RowBg | ImGuiTableFlags_ScrollY | ImGuiTableFlags_Resizable |
                                      ImGuiTableFlags_BordersInnerV | ImGuiTableFlags_SizingStretchProp | ImGuiTableFlags_NoSavedSettings;
    if (ImGui::BeginTable("##audiolog", 7, flags, ImVec2(0, 0))) {
        ImGui::TableSetupScrollFreeze(0, 1);
        ImGui::TableSetupColumn("seq", ImGuiTableColumnFlags_WidthFixed, 44);
        ImGui::TableSetupColumn("frame", ImGuiTableColumnFlags_WidthFixed, 56);
        ImGui::TableSetupColumn("path", ImGuiTableColumnFlags_WidthStretch, 1.0f);
        ImGui::TableSetupColumn("bus", ImGuiTableColumnFlags_WidthFixed, 56);
        ImGui::TableSetupColumn("volume", ImGuiTableColumnFlags_WidthFixed, 56);
        ImGui::TableSetupColumn("source", ImGuiTableColumnFlags_WidthStretch, 0.45f);
        ImGui::TableSetupColumn("ok", ImGuiTableColumnFlags_WidthFixed, 56);
        ImGui::TableHeadersRow();
        const ImVec4 bad(1.0f, 0.45f, 0.4f, 1.0f);
        for (const AudioPlay& p : a.plays) {
            if (!audio_play_visible(p, a)) continue;
            ImGui::TableNextRow();
            if (!p.ok) ImGui::TableSetBgColor(ImGuiTableBgTarget_RowBg1, IM_COL32(120, 30, 28, 110));
            if (!p.ok) ImGui::PushStyleColor(ImGuiCol_Text, bad);
            ImGui::TableSetColumnIndex(0);
            ImGui::Text("%llu", static_cast<unsigned long long>(p.seq));
            ImGui::TableSetColumnIndex(1);
            ImGui::Text("%llu", static_cast<unsigned long long>(p.frame));
            ImGui::TableSetColumnIndex(2);
            ImGui::TextUnformatted(p.path.c_str());
            if (p.music || p.loop) {
                ImGui::SameLine();
                ImGui::TextDisabled("%s", p.music && p.loop ? "music, loop" : p.music ? "music" : "loop");
            }
            if (ImGui::IsItemHovered())
                ImGui::SetTooltip("%s\ntime %.3f s   pitch %.2f   pan %.2f%s", p.path.c_str(), p.time, p.pitch, p.pan,
                                  p.ok ? "" : "\nThe clip could not be loaded (see the Console for the reason).");
            ImGui::TableSetColumnIndex(3);
            ImGui::TextUnformatted(p.bus.c_str());
            ImGui::TableSetColumnIndex(4);
            ImGui::Text("%.2f", p.volume);
            ImGui::TableSetColumnIndex(5);
            ImGui::TextUnformatted(p.source.empty() ? "-" : p.source.c_str());
            ImGui::TableSetColumnIndex(6);
            ImGui::TextUnformatted(p.ok ? "ok" : "FAILED");
            if (!p.ok) ImGui::PopStyleColor();
        }
        if (a.plays.empty()) {
            ImGui::TableNextRow();
            ImGui::TableSetColumnIndex(2);
            ImGui::TextDisabled("No sounds played yet. Press Play: every audio.play, AudioSource and music start shows up here.");
        } else if (shown == 0) {
            ImGui::TableNextRow();
            ImGui::TableSetColumnIndex(2);
            ImGui::TextDisabled("No play matches the filter.");
        }
        const std::uint64_t newest = a.plays.empty() ? 0 : a.plays.back().seq;
        if (a.autoScroll && newest != a.scrolledTo) ImGui::SetScrollHereY(1.0f);
        a.scrolledTo = newest;
        ImGui::EndTable();
    }
    ImGui::End();
}

}  // namespace fa::editor
