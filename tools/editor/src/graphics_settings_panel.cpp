// The Graphics settings window (View > Graphics): the project's graphics preset, upscaler and dynamic resolution, the keys
// `render.graphicsPreset`, `render.upscaler` {mode, quality, sharpness} and `render.dynamicResolution` {enabled, targetMs,
// minScale, maxScale} of factoria.json (M76, docs/UPSCALING.md). It
// edits a working copy: Save writes only those three keys (graphics_settings_model.h, validated by the engine's own parsers),
// Revert reads the file again. It does not preview: the editor has no render-settings preview toggle, and what a mode or a
// preset looks like is seen by playing the project (Play) after Save, or by the player's own menu.
#include <algorithm>
#include <cmath>

#include "editor_internal.h"
#include "graphics_settings_model.h"
#include "imgui_internal.h"

namespace fa::editor {

namespace {

void gfx_tip(const char* text) {
    if (!ImGui::BeginItemTooltip()) return;
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

}  // namespace

void Editor::graphics_settings_reload() {
    graphicsDir_ = projectDir_;
    graphicsLoadError_.clear();
    graphicsMessage_.clear();
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
        "The preset, the upscaler and the dynamic resolution a run of this game starts with (factoria.json: "
        "render.graphicsPreset, render.upscaler and render.dynamicResolution). A game can let the player change them "
        "at run time (the menu kit's Graphics tab).");
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
              "plus sharpen; temporal accumulates jittered frames; metalfx is Apple's MetalFX (Metal only); auto "
              "takes the best this GPU draws. A mode the GPU cannot draw draws as the next best one; read "
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
    gfx_tip("Writes render.graphicsPreset, render.upscaler and render.dynamicResolution of factoria.json; nothing else "
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
