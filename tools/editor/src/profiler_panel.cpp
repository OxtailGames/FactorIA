// Profiler panel (View > Profiler): where the time of a frame goes while the game plays. Milliseconds per engine system and per
// script behaviour class (smoothed over a few frames), the frame-time graph, GPU time where the backend has timer queries,
// memory, and a Threads tab with one row per thread of the job pool. The numbers come from the engine's profiler
// (fa/core/profiler.h), which runs only while this panel is open or a play session records; ProfilerView (editor_tools.h)
// holds them and is unit-tested without a window.
#include <algorithm>
#include <cfloat>
#include <cstdint>
#include <cstdio>
#include <string>

#include "editor_internal.h"
#include "fa/core/jobs.h"
#include "fa/render/renderer.h"
#include "imgui_internal.h"

namespace fa::editor {

namespace {

// The tables fill the rest of the panel, but keep room for a few rows when the panel is short (a 1024x642 screen): the
// panel scrolls to them instead of squeezing them to nothing.
float table_height() {
    return std::max(ImGui::GetContentRegionAvail().y, ImGui::GetTextLineHeightWithSpacing() * 6.0f);
}

// The Threads tab: one row per thread of the job pool (main, worker 1.., other) with the time it spent in jobs, its share
// of the frame and its slowest jobs by name.
void draw_profiler_threads(const ProfilerView& v, ImGuiTableFlags flags) {
    if (v.lanes.empty()) {
        ImGui::TextDisabled("No frame measured yet.");
        return;
    }
    ImGui::TextDisabled("%d worker thread(s)%s; jobs run where a thread is free, the results do not depend on it",
                        jobs::worker_count(),
                        jobs::inline_mode() ? " (inline mode: every job runs on the main thread)" : "");
    if (!ImGui::BeginChild("##profthreads", ImVec2(0, table_height()))) {
        ImGui::EndChild();
        return;
    }
    if (ImGui::BeginTable("##profthreadtable", 5, flags)) {
        ImGui::TableSetupScrollFreeze(0, 1);
        ImGui::TableSetupColumn("thread", ImGuiTableColumnFlags_WidthFixed, 70);
        ImGui::TableSetupColumn("job ms", ImGuiTableColumnFlags_WidthFixed, 52);
        ImGui::TableSetupColumn("jobs", ImGuiTableColumnFlags_WidthFixed, 44);
        ImGui::TableSetupColumn("busy", ImGuiTableColumnFlags_WidthStretch, 0.5f);
        ImGui::TableSetupColumn("slowest jobs", ImGuiTableColumnFlags_WidthStretch, 1.0f);
        ImGui::TableHeadersRow();
        const double frameMs = std::max(v.smoothFrameMs, 0.001);
        for (std::size_t i = 0; i < v.lanes.size(); ++i) {
            const ProfilerView::LaneRow& l = v.lanes[i];
            ImGui::PushID(int(i));
            ImGui::TableNextRow();
            ImGui::TableSetColumnIndex(0);
            ImGui::TextUnformatted(l.name.c_str());
            ImGui::TableSetColumnIndex(1);
            ImGui::Text("%.3f", l.jobMs);
            ImGui::TableSetColumnIndex(2);
            ImGui::Text("%.1f", l.jobs);
            ImGui::TableSetColumnIndex(3);
            const double share = std::clamp(l.jobMs / frameMs, 0.0, 1.0);
            char pct[16];
            std::snprintf(pct, sizeof pct, "%.0f%%", share * 100.0);
            ImGui::ProgressBar(float(share), ImVec2(-FLT_MIN, 0), pct);
            ImGui::SetItemTooltip("Share of the frame (%.2f ms) this thread spent in jobs", v.smoothFrameMs);
            ImGui::TableSetColumnIndex(4);
            if (l.top.empty()) {
                ImGui::TextDisabled(i == 0 ? "no jobs on the main thread" : "idle");
            } else {
                std::string text;
                for (std::size_t k = 0; k < l.top.size() && k < 3; ++k) {
                    char part[96];
                    std::snprintf(part, sizeof part, "%s%s %.3f", k ? ", " : "", l.top[k].name.c_str(), l.top[k].ms);
                    text += part;
                }
                ImGui::TextUnformatted(text.c_str());
                if (ImGui::BeginItemTooltip()) {
                    for (const ProfilerView::JobRow& j : l.top)
                        ImGui::Text("%-28s %7.3f ms  %5.1f per frame", j.name.c_str(), j.ms, j.count);
                    ImGui::EndTooltip();
                }
            }
            ImGui::PopID();
        }
        ImGui::EndTable();
    }
    ImGui::EndChild();
}

}  // namespace

// The post-processing passes of the renderer's last frame, into the profiler view (every tenth frame: it builds the pass names).
void Editor::sample_post_passes() {
    ProfilerView& v = profView_;
    v.post.clear();
    v.postCpuMs = 0;
    v.postGpuMs = -1;
    Renderer* r = engine_ ? engine_->renderer() : nullptr;
    if (!r || !r->initialized()) {
        v.postGpuReason = "no graphics in this run";
        return;
    }
    const PostPassTimes t = post_pass_times(r->stats());
    for (const RenderStats::PassTime& p : t.passes) v.post.push_back({p.name, p.cpuMs, p.gpuMs});
    v.postCpuMs = t.cpuMs;
    v.postGpuMs = t.gpuMs;
    std::string why;
    if (t.gpuMs >= 0.0)
        v.postGpuReason.clear();
    else if (t.passes.empty())
        v.postGpuReason = "the last frame has no post-processing pass";
    else if (!r->gpu_timing_supported(&why))
        v.postGpuReason = why;
    else
        v.postGpuReason = "no GPU time has arrived yet (the timer answers a few frames late)";
}

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
    engine_->profile_latency(&profView_.latencyDriver, &profView_.latencyReason);
    run_.profile.set_latency_status(profView_.latencyDriver, profView_.latencyReason);
    profView_.frameGeneration = engine_->profile_frame_generation();
    run_.profile.set_frame_generation(profView_.frameGeneration);
    for (double ms : gpu) {
        profView_.add_gpu_ms(ms);
        if (run_.active) run_.profile.add_gpu_ms(ms);
    }
    if (showProfiler_ && engine_->frame_index() > frameBefore && engine_->frame_index() % 10 == 0) sample_post_passes();
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
        ImGui::TextDisabled(
            "Press Play: the profiler measures the frames the game runs (nothing is measured while editing).");
    } else {
        ImGui::Text("Frame %.2f ms (%.0f fps)", v.smoothFrameMs, v.smoothFrameMs > 0 ? 1000.0 / v.smoothFrameMs : 0.0);
        ImGui::SameLine();
        if (play_ == PlayState::Playing)
            ImGui::TextColored(ImVec4(0.4f, 0.9f, 0.5f, 1), "live");
        else
            ImGui::TextDisabled("(not running)");
        ImGui::SameLine();
        ImGui::TextDisabled("engine time per frame, wall clock; the editor's own drawing is not included");
        float top = 16.7f;
        for (float f : v.frameMs) top = std::max(top, f);
        ImGui::PlotLines("##frames", v.frameMs.data(), int(v.frameMs.size()), 0, nullptr, 0.0f, top * 1.1f,
                         ImVec2(-1, 56));
        ImGui::SetItemTooltip("Milliseconds of the last %zu frames", ProfilerView::kHistory);
    }
    if (v.framesOverScriptBudget > 0) {
        ImGui::TextColored(
            ImVec4(1.0f, 0.75f, 0.3f, 1), "Scripts over budget in %llu frame(s), worst %.2f ms (limit %.2f ms)",
            static_cast<unsigned long long>(v.framesOverScriptBudget), v.worstOverScriptBudgetMs, v.scriptBudgetMs);
        ImGui::SetItemTooltip(
            "The script time of a frame went over runtime.scriptFrameBudgetMs in factoria.json (per platform, 0 turns "
            "it off). "
            "The Console has the warning (category script.budget, not script) that names the slowest callbacks. Frames "
            "that load a scene are not counted.");
    }
    if (v.haveGpu)
        ImGui::Text("GPU %.2f ms", v.gpuMs);
    else
        ImGui::TextDisabled("GPU: n/a (%s)", v.gpuReason.c_str());
    if (v.haveLatency) {
        ImGui::Text("Input to present %.2f ms (%s)", v.latencyMs, v.latencyDriver.c_str());
        ImGui::SetItemTooltip("From the input sample to the end of the present call, as the CPU sees it (the display "
                              "still shows the frame later). "
                              "Set render.latency in factoria.json (docs/LATENCY.md).");
    } else {
        ImGui::TextDisabled("Input to present: n/a (%s)", v.latencyReason.c_str());
    }
    {
        // Frame generation (M78, docs/FRAME_GENERATION.md): the engine's own readout; the editor's loop never generates, so it says why.
        const Json& fg = v.frameGeneration;
        const std::string state = fg.is_object() ? fg.value("state", std::string("off")) : std::string("off");
        const std::string provider = fg.is_object() ? fg.value("provider", std::string("none")) : std::string("none");
        const std::string why = fg.is_object() ? fg.value("reason", std::string()) : std::string();
        if (state == "active" || state == "paused" || state == "measuring") {
            ImGui::Text("Frame generation (%s): base %.1f fps, presented %.1f fps, %llu generated", provider.c_str(),
                        fg.value("baseFps", 0.0), fg.value("presentedFps", 0.0),
                        static_cast<unsigned long long>(fg.value("generatedFrames", std::uint64_t(0))));
            if (!why.empty()) ImGui::SetItemTooltip("%s", why.c_str());
        } else {
            const std::string line = "Frame generation: " + state + (why.empty() ? std::string() : " (" + why + ")");
            ImGui::TextDisabled("%s", line.c_str());
        }
    }
    if (v.haveMemory) {
        auto mb = [](std::uint64_t b) { return double(b) / (1024.0 * 1024.0); };
        ImGui::Text("Memory %.0f MB (peak %.0f)   JS heap %.1f MB", mb(v.memory.processBytes),
                    mb(v.memory.peakProcessBytes), mb(v.memory.jsHeapBytes));
        ImGui::Text("Textures %.1f MB   audio %.1f MB (music %.1f)   entities %d", mb(v.memory.textureBytes),
                    mb(v.memory.audioDecodedBytes), mb(v.memory.musicBytes), v.memory.entities);
    }

    constexpr ImGuiTableFlags flags = ImGuiTableFlags_RowBg | ImGuiTableFlags_ScrollY | ImGuiTableFlags_Resizable |
                                      ImGuiTableFlags_BordersInnerV | ImGuiTableFlags_SizingStretchProp |
                                      ImGuiTableFlags_NoSavedSettings;
    if (ImGui::BeginTabBar("##proftabs")) {
        if (ImGui::BeginTabItem("Systems and scripts")) {
            const float half = ImGui::GetContentRegionAvail().x * 0.4f;
            const float tableH = table_height();
            if (ImGui::BeginChild("##profsys", ImVec2(half, tableH))) {
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
            if (ImGui::BeginChild("##profcls", ImVec2(0, tableH))) {
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
            ImGui::EndTabItem();
        }
        const bool threadsOpen = ImGui::BeginTabItem(
            "Threads", nullptr, profShowThreads_ ? ImGuiTabItemFlags_SetSelected : ImGuiTabItemFlags_None);
        ImGui::SetItemTooltip(
            "Time each thread of the job system spent in jobs (runtime.jobThreads in factoria.json; jobs.info)");
        profShowThreads_ = false;
        if (threadsOpen) {
            draw_profiler_threads(v, flags);
            ImGui::EndTabItem();
        }
        if (ImGui::BeginTabItem("Post-processing")) {
            ImGui::SetItemTooltip(
                "What the passes of the screen effects (bloom, exposure, post...) cost, in the last sampled frame");
            if (v.post.empty()) {
                ImGui::TextDisabled("No post-processing pass in the last frame (%s).", v.postGpuReason.c_str());
            } else {
                if (v.postGpuMs >= 0.0)
                    ImGui::Text("Post-processing total: GPU %.3f ms, CPU %.3f ms", v.postGpuMs, v.postCpuMs);
                else
                    ImGui::TextWrapped("Post-processing total: GPU unavailable (%s), CPU %.3f ms",
                                       v.postGpuReason.c_str(), v.postCpuMs);
                if (ImGui::BeginTable("##profpost", 3, flags)) {
                    ImGui::TableSetupScrollFreeze(0, 1);
                    ImGui::TableSetupColumn("pass", ImGuiTableColumnFlags_WidthStretch, 1.0f);
                    ImGui::TableSetupColumn("GPU ms", ImGuiTableColumnFlags_WidthFixed, 80);
                    ImGui::TableSetupColumn("CPU ms", ImGuiTableColumnFlags_WidthFixed, 80);
                    ImGui::TableHeadersRow();
                    for (const ProfilerView::PostRow& p : v.post) {
                        ImGui::TableNextRow();
                        ImGui::TableSetColumnIndex(0);
                        ImGui::TextUnformatted(p.name.c_str());
                        ImGui::TableSetColumnIndex(1);
                        if (p.gpuMs >= 0.0)
                            ImGui::Text("%.3f", p.gpuMs);
                        else
                            ImGui::TextDisabled("unavailable");
                        ImGui::TableSetColumnIndex(2);
                        ImGui::Text("%.3f", p.cpuMs);
                    }
                    ImGui::EndTable();
                }
                ImGui::TextDisabled("Effects in the single \"post\" pass (vignette, grain, grading, sharpen, "
                                    "outline...) are not timed one by one: "
                                    "that pass is their total.");
            }
            ImGui::EndTabItem();
        }
        ImGui::EndTabBar();
    }
    ImGui::End();
}

}  // namespace fa::editor
