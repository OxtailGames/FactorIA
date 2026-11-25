// The Graphics settings window (View > Graphics): the project's graphics preset, upscaler, dynamic resolution, low latency and frame
// generation, the keys `render.graphicsPreset`, `render.upscaler` {mode, quality, sharpness}, `render.dynamicResolution` {enabled, targetMs,
// minScale, maxScale} (M76, docs/UPSCALING.md), `render.latency` {mode, boost} (M78, docs/LATENCY.md) and `render.frameGeneration` {mode,
// minBaseFps} (M78, docs/FRAME_GENERATION.md) of factoria.json. It
// edits a working copy: Save writes only those five keys (fa/tooling/graphics_settings.h, validated by the engine's own parsers),
// Revert reads the file again. It does not preview: the editor has no render-settings preview toggle, and what a mode or a
// preset looks like is seen by playing the project (Play) after Save, or by the player's own menu.
#include <algorithm>
#include <cmath>

#include "editor_internal.h"
#include "fa/tooling/graphics_settings.h"
#include "imgui_internal.h"

namespace fa::editor {

namespace {

// How often the window asks the renderer's render.supports table again while it is open.
constexpr double kGraphicsSupportRefreshS = 10.0;

void gfx_tip(const char* text) {
    if (!ImGui::BeginItemTooltip()) return;
    ImGui::PushTextWrapPos(ImGui::GetFontSize() * 28.0f);
    ImGui::TextUnformatted(text);
    ImGui::PopTextWrapPos();
    ImGui::EndTooltip();
}

// The tooltip of a widget that may be disabled (BeginItemTooltip stays silent on a disabled item).
void gfx_tip_always(const char* text) {
    if (!ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled | ImGuiHoveredFlags_ForTooltip) ||
        !ImGui::BeginTooltip())
        return;
    ImGui::PushTextWrapPos(ImGui::GetFontSize() * 28.0f);
    ImGui::TextUnformatted(text);
    ImGui::PopTextWrapPos();
    ImGui::EndTooltip();
}

// A combo over `values`; true when the choice changed.
bool gfx_combo(const char* label, std::string& value, const std::vector<std::string>& values, const char* tip,
               const std::string& trackId, const std::function<void(const std::string&)>& track) {
    bool changed = false;
    const bool open = ImGui::BeginCombo(label, value.c_str());
    track(trackId);
    if (open) {
        for (const std::string& v : values) {
            if (ImGui::Selectable(v.c_str(), v == value)) {
                value = v;
                changed = true;
            }
            track(trackId + ":" + v);
        }
        ImGui::EndCombo();
    }
    gfx_tip(tip);
    return changed;
}

// What the renderer says of one low-latency mode (the rows reflex, antilag2 and xell of render.supports): usable here, or the reason
// it is not. off and auto are always usable (auto falls back to the engine's own pacing). Without a report (no renderer to ask) the
// SDK modes are not usable, with that as the reason; a report without the row (an older engine) leaves the mode usable.
struct LatencyRow {
    bool usable = true;
    std::string why;
};

LatencyRow latency_row(const Json& report, const std::string& mode) {
    LatencyRow r;
    if (mode == "off" || mode == "auto") return r;
    const auto features = report.is_object() ? report.find("features") : report.end();
    if (features == report.end() || !features->is_array()) {
        r.usable = false;
        r.why = "The editor has no GPU to ask whether this mode can run here.";
        return r;
    }
    for (const Json& f : *features) {
        if (!f.is_object() || f.value("name", std::string()) != mode) continue;
        r.usable = f.value("supported", false);
        if (!r.usable) r.why = f.value("status", std::string("not available here"));
        return r;
    }
    return r;
}

// The line under the latency mode: what the chosen mode does on this machine (from the renderer's own table).
std::string latency_line(const std::string& mode, const Json& report) {
    if (mode == "off") return "Off: the loop is the one of a game without this setting; nothing is paced.";
    if (mode == "auto") {
        std::string usable;
        for (const char* sdk : {"reflex", "antilag2", "xell"})
            if (latency_row(report, sdk).usable) usable += (usable.empty() ? "" : ", ") + std::string(sdk);
        if (usable.empty())
            return "Auto: no vendor SDK can run on this machine, so a run uses the engine's own pacing (a game window, "
                   "vsync on).";
        return "Auto: the SDK of the GPU's maker when it can run (usable on this machine: " + usable +
               "), else the engine's own pacing.";
    }
    const LatencyRow row = latency_row(report, mode);
    if (row.usable) return "Usable on this machine: a run of the game uses " + mode + ".";
    return "Not usable on this machine: " + row.why + " A run of the game uses the engine's own pacing instead.";
}

// The "Low latency" group (render.latency, docs/LATENCY.md): the mode combo with each mode the renderer cannot run greyed out and its
// reason as the tooltip, the boost checkbox for the modes that have one, and the line that says what the mode does here. It edits `g`
// only; `support` is the renderer's render.supports report. Returns that line (the autotest reads it).
std::string draw_latency_group(GraphicsSettings& g, const Json& support,
                               const std::function<void(const std::string&, bool)>& track,
                               const std::function<void(const char*)>& show_problem) {
    ImGui::SeparatorText("Low latency");
    const bool open = ImGui::BeginCombo("Mode##latency", g.latencyMode.c_str());
    track("gfx:latMode", true);
    if (open) {
        for (const std::string& m : latency_modes()) {
            const LatencyRow row = latency_row(support, m);
            ImGui::BeginDisabled(!row.usable);
            if (ImGui::Selectable(m.c_str(), m == g.latencyMode)) {
                g.latencyMode = m;
                if (!latency_mode_has_boost(m)) g.latencyBoost = false;  // a switch the mode does not have is not kept
            }
            ImGui::EndDisabled();
            track("gfx:latMode:" + m, row.usable);
            if (!row.usable) gfx_tip_always(row.why.c_str());
        }
        ImGui::EndCombo();
    }
    gfx_tip(
        "render.latency.mode. off (the default) paces nothing. auto takes the SDK of the GPU's maker when it can run "
        "(AMD Anti-Lag 2, Intel XeLL, NVIDIA Reflex), else the engine's own pacing. reflex, antilag2 and xell name "
        "one SDK; a mode this machine cannot run is greyed out (hover it for the reason) and a run falls back to "
        "the engine's own pacing. Only a run of the game paces: the editor's own viewport never does.");
    show_problem("/render/latency/mode");
    const bool hasBoost = latency_mode_has_boost(g.latencyMode);
    ImGui::BeginDisabled(!hasBoost);
    ImGui::Checkbox("Boost", &g.latencyBoost);
    track("gfx:latBoost", hasBoost);
    ImGui::EndDisabled();
    gfx_tip("render.latency.boost. Keeps the GPU clocks up while the game waits, for less latency at more power "
            "(Reflex and "
            "XeLL). Anti-Lag 2, the engine's own pacing and off have no such switch, so it is greyed out for them.");
    show_problem("/render/latency/boost");
    const std::string line = latency_line(g.latencyMode, support);
    const bool warn = g.latencyMode != "off" && g.latencyMode != "auto" && !latency_row(support, g.latencyMode).usable;
    ImGui::PushStyleColor(ImGuiCol_Text, warn ? kStatusWarn : ImGui::GetStyleColorVec4(ImGuiCol_TextDisabled));
    ImGui::TextWrapped("%s", line.c_str());
    ImGui::PopStyleColor();
    return line;
}

// What the "Frame generation" group shows, for the autotest: the sentence under the mode, the latency advice (empty when none) and the
// line of the engine's own readout.
struct FrameGenLines {
    std::string describe, hint, state;
};

// The "Frame generation" group (render.frameGeneration, docs/FRAME_GENERATION.md): the mode combo with each SDK mode the renderer cannot
// run greyed out and its reason as the tooltip, the minimum base frame rate, the sentence that says what the mode does here, the advice for
// a low-latency mode when it is missing, and the one-line state of the engine's readout (`readout`: Engine::profile_frame_generation()). It
// edits `g` only; `support` is the renderer's render.supports report.
FrameGenLines draw_frame_gen_group(GraphicsSettings& g, const Json& support, const Json& readout,
                                   const std::function<void(const std::string&, bool)>& track,
                                   const std::function<void(const char*)>& show_problem) {
    FrameGenLines out;
    ImGui::SeparatorText("Frame generation");
    const bool open = ImGui::BeginCombo("Mode##framegen", g.frameGenMode.c_str());
    track("gfx:fgMode", true);
    if (open) {
        for (const std::string& m : frame_gen_modes()) {
            const FrameGenModeSupport row = frame_gen_mode_support(support, m);
            ImGui::BeginDisabled(!row.usable);
            if (ImGui::Selectable(m.c_str(), m == g.frameGenMode)) g.frameGenMode = m;
            ImGui::EndDisabled();
            track("gfx:fgMode:" + m, row.usable);
            if (!row.usable) gfx_tip_always(row.why.c_str());
        }
        ImGui::EndCombo();
    }
    gfx_tip(
        "render.frameGeneration.mode. off (the default) loads no SDK. auto takes the SDK of the GPU's maker when it can run "
        "(NVIDIA DLSS, AMD FSR 3, Intel XeSS). dlss, fsr and xess name one SDK; a mode this machine cannot run is greyed "
        "out (hover it for the reason) and a run shows the rendered frames only. A generated frame sits between two rendered "
        "ones, so the display shows more frames than the game renders. It runs only in a game window on Direct3D 12 or "
        "Vulkan with the temporal upscaler (a render scale below 1), and a provider takes part in making the window, so "
        "it is chosen when the game starts. The editor's own viewport never generates.");
    show_problem("/render/frameGeneration/mode");
    const bool on = g.frameGenMode != "off";
    ImGui::BeginDisabled(!on);
    int minFps = g.frameGenMinBaseFps;
    if (ImGui::SliderInt("Minimum base fps##framegen", &minFps, 0, 240, minFps == 0 ? "never switch off" : "%d fps"))
        g.frameGenMinBaseFps = minFps;
    track("gfx:fgMinFps", on);
    ImGui::EndDisabled();
    gfx_tip("render.frameGeneration.minBaseFps (0 to 1000; Ctrl+click types a number). The frame rate the game renders at, "
            "generated frames not counted, below which generation switches off: a generated frame between two slow ones "
            "adds delay and shows artefacts. It comes back at 10% above. 0 never switches off.");
    show_problem("/render/frameGeneration/minBaseFps");
    out.describe = frame_gen_describe(g, support);
    const bool warn = on && g.frameGenMode != "auto" && !frame_gen_mode_support(support, g.frameGenMode).usable;
    ImGui::PushStyleColor(ImGuiCol_Text, warn ? kStatusWarn : ImGui::GetStyleColorVec4(ImGuiCol_TextDisabled));
    ImGui::TextWrapped("%s", out.describe.c_str());
    ImGui::PopStyleColor();
    out.hint = frame_gen_latency_hint(g);
    if (!out.hint.empty()) {
        ImGui::PushStyleColor(ImGuiCol_Text, kStatusWarn);
        ImGui::TextWrapped("%s", out.hint.c_str());
        ImGui::PopStyleColor();
    }
    out.state = frame_gen_state_line(readout, g.frameGenMinBaseFps);
    ImGui::PushStyleColor(ImGuiCol_Text, ImGui::GetStyleColorVec4(ImGuiCol_TextDisabled));
    ImGui::TextWrapped("Now, in the editor: %s", out.state.c_str());
    ImGui::PopStyleColor();
    gfx_tip("The engine's own readout (the Profiler window shows the same line): base frame rate, presented frame rate and "
            "generated frames while a provider runs, or why none does. The editor's own loop never generates, so a game "
            "window (factoria run, an export) is where it shows numbers.");
    return out;
}

}  // namespace

void Editor::graphics_settings_reload() {
    graphicsDir_ = projectDir_;
    graphicsLoadError_.clear();
    graphicsMessage_.clear();
    graphicsSupportStale_ = true;  // opening and Revert ask the renderer again (what a vendor probe may touch is read once, not every few seconds)
    if (projectDir_.empty()) return;
    auto s = read_graphics_settings(projectDir_);
    if (s.ok()) {
        graphicsSaved_ = *s;
        graphicsWork_ = *s;
    } else {
        graphicsSaved_ = graphicsWork_ = GraphicsSettings{};
        graphicsLoadError_ = s.error().message + " " + s.error().hint;
    }
}

bool Editor::graphics_settings_save(std::string* error) {
    auto r = write_graphics_settings(projectDir_, graphicsWork_);
    if (!r.ok()) {
        graphicsMessage_ = r.error().message + " " + r.error().hint;
        if (error) *error = graphicsMessage_;
        return false;
    }
    graphicsSaved_ = graphicsWork_;
    graphicsMessage_.clear();
    project_files_changed();
    notify("Graphics settings saved.", 0);
    return true;
}

void Editor::draw_graphics_settings_panel() {
    first_floating_window(ImVec2(200, 80), ImVec2(520, 500));
    if (!ImGui::Begin("Graphics", &showGraphics_)) {
        ImGui::End();
        return;
    }
    if (projectDir_.empty() || !engine_) {
        ImGui::TextDisabled("Open a project to edit its graphics settings.");
        ImGui::End();
        return;
    }
    if (graphicsDir_ != projectDir_) graphics_settings_reload();
    ImGui::TextWrapped(
        "The preset, the upscaler, the dynamic resolution, the low-latency mode and the frame generation a run of this "
        "game starts with (factoria.json: render.graphicsPreset, render.upscaler, render.dynamicResolution, render.latency "
        "and render.frameGeneration). A game "
        "can let the player change them at run time (the menu kit's Graphics tab).");
    draw_play_banner(*this);
    if (!graphicsLoadError_.empty()) {
        ImGui::PushStyleColor(ImGuiCol_Text, kStatusFailed);
        ImGui::TextWrapped("factoria.json: %s", graphicsLoadError_.c_str());
        ImGui::PopStyleColor();
    }
    const auto track = [this](const std::string& id) { at_track(id); };
    GraphicsSettings& g = graphicsWork_;
    const std::vector<GraphicsSettingsProblem> problems = check_graphics_settings(g);
    auto problem_of = [&](const char* pointer) -> const GraphicsSettingsProblem* {
        for (const auto& p : problems)
            if (p.pointer == pointer) return &p;
        return nullptr;
    };
    auto show_problem = [&](const char* pointer) {
        if (const auto* p = problem_of(pointer)) {
            ImGui::PushStyleColor(ImGuiCol_Text, kStatusFailed);
            ImGui::TextWrapped("%s", p->message.c_str());
            ImGui::PopStyleColor();
        }
    };

    // The settings scroll in their own region, so a small window (or a few lines of problems under the fields) never pushes Save and
    // Revert out of reach: they stay in a footer under it.
    const float footer = ImGui::GetTextLineHeightWithSpacing() + ImGui::GetFrameHeightWithSpacing() +
                         ImGui::GetStyle().ItemSpacing.y * 3.0f;
    ImGui::BeginChild("##gfx_body", ImVec2(0.0f, -footer));
    ImGui::SeparatorText("Graphics preset");
    gfx_combo("Preset", g.preset, graphics_presets(),
              "render.graphicsPreset. low, medium, high and ultra lower what the scenes ask for (shadows, ambient "
              "occlusion, reflections, level-of-detail distances...), never raise it; custom, the default, is no "
              "layer: the game looks as its author made it.",
              "gfx:preset", track);
    show_problem("/render/graphicsPreset");

    ImGui::SeparatorText("Upscaler");
    gfx_combo("Mode", g.mode, upscaler_modes(),
              "render.upscaler.mode. stretch is the plain blit (the default); spatial is our edge-adaptive upscale "
              "plus sharpen; temporal accumulates jittered frames; metalfx is Apple's MetalFX (Metal only); dlss, "
              "xess and fsr are NVIDIA DLSS, Intel XeSS and AMD FSR 3.1 (Windows, each needs its SDK: `factoria setup "
              "streamline`, `xess` or `fidelityfx`); auto takes the GPU maker's own SDK when it is installed, else "
              "the best this GPU draws. A mode the GPU cannot draw draws as the next best one; read "
              "window.upscaler.effectiveMode in a script for what draws.",
              "gfx:mode", track);
    show_problem("/render/upscaler/mode");
    gfx_combo("Quality", g.quality, upscaler_qualities(),
              "render.upscaler.quality. How much smaller than the window the frame is drawn: native 1, quality 1/1.5, "
              "balanced 1/1.7, performance 1/2, ultraPerformance 1/3 of its width and height.",
              "gfx:quality", track);
    show_problem("/render/upscaler/quality");
    ImGui::BeginDisabled(g.mode == "stretch");
    float sharp = float(g.sharpness);
    if (ImGui::SliderFloat("Sharpness", &sharp, 0.0f, 1.0f, "%.2f"))
        g.sharpness = double(std::round(sharp * 100.0f)) / 100.0;
    at_track("gfx:sharpness", g.mode != "stretch");
    ImGui::EndDisabled();
    gfx_tip("render.upscaler.sharpness, 0 to 1. The contrast-adaptive sharpen of the spatial and temporal modes; the "
            "plain stretch has none.");
    show_problem("/render/upscaler/sharpness");

    ImGui::SeparatorText("Dynamic resolution");
    ImGui::Checkbox("Enabled", &g.dynamic.enabled);
    at_track("gfx:dynEnabled");
    gfx_tip(
        "render.dynamicResolution.enabled. The render scale follows the frame time so the game holds the target: it "
        "multiplies into the render scale and the upscaler's quality, between the two scales below, in steps and at "
        "most twice a second. Off (the default) draws at the fixed render scale. It runs in the player, not in the "
        "editor's own viewport.");
    ImGui::BeginDisabled(!g.dynamic.enabled);
    float target = float(g.dynamic.targetMs);
    if (ImGui::DragFloat("Target (ms)", &target, 0.1f, 0.0f, 100.0f, target == 0.0f ? "display refresh" : "%.1f ms"))
        g.dynamic.targetMs = double(std::round(target * 10.0f)) / 10.0;
    at_track("gfx:dynTarget", g.dynamic.enabled);
    gfx_tip("render.dynamicResolution.targetMs. The frame time to hold: 33.3 is 30 fps, 16.7 is 60 fps, 8.3 is 120 fps "
            "(4 to 100). 0, the default, follows one refresh of the display (the OS's rate, else an estimate from the "
            "frame times, else 60 Hz).");
    show_problem("/render/dynamicResolution/targetMs");
    float lo = g.dynamic.minScale, hi = g.dynamic.maxScale;
    if (ImGui::SliderFloat("Min scale", &lo, render::kDynamicScaleFloor, render::kDynamicScaleCeiling, "%.2f"))
        g.dynamic.minScale = std::round(lo * 100.0f) / 100.0f;
    at_track("gfx:dynMin", g.dynamic.enabled);
    gfx_tip(
        "render.dynamicResolution.minScale, 0.25 to 1. The smallest share of the render size's width and height the "
        "controller may use; 0.5 is a quarter of the pixels.");
    show_problem("/render/dynamicResolution/minScale");
    if (ImGui::SliderFloat("Max scale", &hi, render::kDynamicScaleFloor, render::kDynamicScaleCeiling, "%.2f"))
        g.dynamic.maxScale = std::round(hi * 100.0f) / 100.0f;
    at_track("gfx:dynMax", g.dynamic.enabled);
    gfx_tip("render.dynamicResolution.maxScale, 0.25 to 1. The largest share, and where the controller starts.");
    show_problem("/render/dynamicResolution/maxScale");
    ImGui::EndDisabled();

    if (!graphicsSupportPinned_ &&
        (graphicsSupport_.is_null() || graphicsSupportStale_ || time_ - graphicsSupportAt_ > kGraphicsSupportRefreshS)) {
        // The renderer's own table (what render.supports answers), not a command call: nothing is logged. A vendor probe behind it may touch
        // the disk, so it is asked when the window opens, on Revert and at most every kGraphicsSupportRefreshS seconds (an SDK installed
        // meanwhile shows up then), never on every frame.
        const Renderer* r = engine_->renderer();
        graphicsSupport_ = r ? r->supports_report() : Json::object();
        graphicsSupportAt_ = time_;
        graphicsSupportStale_ = false;
    }
    graphicsLatencyLine_ = draw_latency_group(
        g, graphicsSupport_, [this](const std::string& id, bool enabled) { at_track(id, enabled); }, show_problem);
    const FrameGenLines fg = draw_frame_gen_group(
        g, graphicsSupport_, engine_->profile_frame_generation(),
        [this](const std::string& id, bool enabled) { at_track(id, enabled); }, show_problem);
    graphicsFrameGenLine_ = fg.describe;
    graphicsFrameGenHint_ = fg.hint;
    graphicsFrameGenState_ = fg.state;
    ImGui::EndChild();

    ImGui::Separator();
    const bool dirty = !(g == graphicsSaved_);
    const bool bad = !problems.empty();
    if (!graphicsMessage_.empty())
        ImGui::TextColored(kStatusFailed, "%s", graphicsMessage_.c_str());
    else if (dirty)
        ImGui::TextColored(kStatusWarn, "Unsaved changes");
    else
        ImGui::TextDisabled("Everything is saved.");
    const bool canSave = dirty && !bad && graphicsLoadError_.empty();
    ImGui::BeginDisabled(!canSave);
    if (ImGui::Button("Save", ImVec2(110, 0))) graphics_settings_save();
    ImGui::EndDisabled();
    at_track("gfx:save", canSave);
    gfx_tip("Writes render.graphicsPreset, render.upscaler, render.dynamicResolution, render.latency and "
            "render.frameGeneration of factoria.json; nothing else "
            "in the file changes. "
            "Settings at their default are removed from the file.");
    ImGui::SameLine();
    ImGui::BeginDisabled(!dirty);
    if (ImGui::Button("Revert", ImVec2(110, 0))) graphics_settings_reload();
    ImGui::EndDisabled();
    at_track("gfx:revert", dirty);
    ImGui::End();
}

}  // namespace fa::editor
