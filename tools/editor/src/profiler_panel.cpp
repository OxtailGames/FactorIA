// Profiler panel (View > Profiler): where the time of a frame goes while the game plays. Milliseconds per engine system and per
// script behaviour class (smoothed over a few frames), the frame-time graph, GPU time where the backend has timer queries, and
// memory. The numbers come from the engine's profiler (fa/core/profiler.h), which runs only while this panel is open or a play
// session records; ProfilerView (editor_tools.h) holds them and is unit-tested without a window.
#include <algorithm>
#include <cfloat>

#include "editor_internal.h"
#include "imgui_internal.h"

namespace fa::editor {

void Editor::profile_tick(std::uint64_t frameBefore) {
    if (!engine_) return;
    const bool want = run_.active || showProfiler_;
    Profiler::get().set_enabled(want);
    if (!want) return;
    std::vector<double> gpu;
    bool supported = false;
    std::string why;
    engine_->profile_gpu(gpu, &supported, &why);
    profView_.gpuSupported = supported;
    profView_.gpuReason = why;
    run_.profile.set_gpu_status(supported, why);
    for (double ms : gpu) {
        profView_.add_gpu_ms(ms);
        if (run_.active) run_.profile.add_gpu_ms(ms);
    }
    if (engine_->frame_index() > frameBefore && Profiler::get().frames() > 0) {
        profView_.add_frame(Profiler::get().last());
        if (--profMemoryIn_ <= 0) {
            profMemoryIn_ = 30;
            const ProfMemory m = engine_->profile_memory();
            profView_.memory = m;
            profView_.haveMemory = true;
            if (run_.active) run_.profile.add_memory(m);
        }
    }
}

void Editor::draw_profiler_panel() {
    // A newly shown panel joins the Console's tab bar instead of floating.
    if (ImGuiWindow* console = ImGui::FindWindowByName("Console"); console && console->DockId != 0)
        ImGui::SetNextWindowDockID(console->DockId, ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(640, 300), ImGuiCond_FirstUseEver);
    if (!ImGui::Begin("Profiler", &showProfiler_)) {
        ImGui::End();
        return;
    }
    const ProfilerView& v = profView_;
    if (v.frames == 0) {
        ImGui::TextDisabled("Press Play: the profiler measures the frames the game runs (nothing is measured while editing).");
    } else {
        ImGui::Text("Frame %.2f ms (%.0f fps)", v.smoothFrameMs, v.smoothFrameMs > 0 ? 1000.0 / v.smoothFrameMs : 0.0);
        ImGui::SameLine();
        if (play_ == PlayState::Playing) ImGui::TextColored(ImVec4(0.4f, 0.9f, 0.5f, 1), "live");
        else ImGui::TextDisabled("(not running)");
        ImGui::SameLine();
        ImGui::TextDisabled("engine time per frame, wall clock; the editor's own drawing is not included");
        float top = 16.7f;
        for (float f : v.frameMs) top = std::max(top, f);
        ImGui::PlotLines("##frames", v.frameMs.data(), int(v.frameMs.size()), 0, nullptr, 0.0f, top * 1.1f, ImVec2(-1, 56));
        ImGui::SetItemTooltip("Milliseconds of the last %zu frames", ProfilerView::kHistory);
    }
    if (v.haveGpu) ImGui::Text("GPU %.2f ms", v.gpuMs);
    else ImGui::TextDisabled("GPU: n/a (%s)", v.gpuReason.c_str());
    if (v.haveMemory) {
        auto mb = [](std::uint64_t b) { return double(b) / (1024.0 * 1024.0); };
        ImGui::Text("Memory %.0f MB (peak %.0f)   JS heap %.1f MB   textures %.1f MB   audio %.1f MB   entities %d", mb(v.memory.processBytes),
                    mb(v.memory.peakProcessBytes), mb(v.memory.jsHeapBytes), mb(v.memory.textureBytes), mb(v.memory.audioDecodedBytes),
                    v.memory.entities);
    }

    constexpr ImGuiTableFlags flags = ImGuiTableFlags_RowBg | ImGuiTableFlags_ScrollY | ImGuiTableFlags_Resizable |
                                      ImGuiTableFlags_BordersInnerV | ImGuiTableFlags_SizingStretchProp | ImGuiTableFlags_NoSavedSettings;
    const float half = ImGui::GetContentRegionAvail().x * 0.4f;
    if (ImGui::BeginChild("##profsys", ImVec2(half, 0))) {
        if (ImGui::BeginTable("##profsystems", 3, flags)) {
            ImGui::TableSetupScrollFreeze(0, 1);
            ImGui::TableSetupColumn("system", ImGuiTableColumnFlags_WidthStretch, 1.0f);
            ImGui::TableSetupColumn("ms", ImGuiTableColumnFlags_WidthFixed, 52);
            ImGui::TableSetupColumn("share", ImGuiTableColumnFlags_WidthStretch, 0.6f);
            ImGui::TableHeadersRow();
            double worst = 0.001;
            for (double ms : v.systemMs) worst = std::max(worst, ms);
            for (int i = 0; i < kProfSystemCount; ++i) {
                ImGui::TableNextRow();
                ImGui::TableSetColumnIndex(0);
                ImGui::TextUnformatted(prof_system_name(ProfSystem(i)));
                ImGui::TableSetColumnIndex(1);
                ImGui::Text("%.3f", v.systemMs[std::size_t(i)]);
                ImGui::TableSetColumnIndex(2);
                ImGui::ProgressBar(float(v.systemMs[std::size_t(i)] / worst), ImVec2(-FLT_MIN, 0), "");
            }
            ImGui::EndTable();
        }
    }
    ImGui::EndChild();
    ImGui::SameLine();
    if (ImGui::BeginChild("##profcls", ImVec2(0, 0))) {
        if (ImGui::BeginTable("##profbehaviours", 4, flags)) {
            ImGui::TableSetupScrollFreeze(0, 1);
            ImGui::TableSetupColumn("behaviour class", ImGuiTableColumnFlags_WidthStretch, 1.0f);
            ImGui::TableSetupColumn("script", ImGuiTableColumnFlags_WidthStretch, 1.0f);
            ImGui::TableSetupColumn("ms", ImGuiTableColumnFlags_WidthFixed, 52);
            ImGui::TableSetupColumn("calls", ImGuiTableColumnFlags_WidthFixed, 48);
            ImGui::TableHeadersRow();
            for (const ProfilerView::Row& r : v.rows) {
                ImGui::TableNextRow();
                ImGui::TableSetColumnIndex(0);
                ImGui::TextUnformatted(r.className.c_str());
                ImGui::TableSetColumnIndex(1);
                ImGui::TextUnformatted(r.path.c_str());
                ImGui::TableSetColumnIndex(2);
                ImGui::Text("%.3f", r.ms);
                ImGui::TableSetColumnIndex(3);
                ImGui::Text("%.1f", r.calls);
            }
            if (v.rows.empty()) {
                ImGui::TableNextRow();
                ImGui::TableSetColumnIndex(0);
                ImGui::TextDisabled("No script ran yet.");
            }
            ImGui::EndTable();
        }
    }
    ImGui::EndChild();
    ImGui::End();
}

}  // namespace fa::editor
