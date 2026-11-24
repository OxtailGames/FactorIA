// The Graphics settings window (View > Graphics): the project's graphics preset and upscaler, the keys
// `render.graphicsPreset` and `render.upscaler` {mode, quality, sharpness} of factoria.json (M76, docs/UPSCALING.md). It
// edits a working copy: Save writes only those two keys (graphics_settings_model.h, validated by the engine's own parsers),
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
    first_floating_window(ImVec2(200, 80), ImVec2(520, 400));
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
        "The preset and the upscaler a run of this game starts with (factoria.json: render.graphicsPreset and "
        "render.upscaler). A game can let the player change them at run time (the menu kit's Graphics tab).");
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
    if (ImGui::SliderFloat("Sharpness", &sharp, 0.0f, 1.0f, "%.2f")) g.sharpness = double(std::round(sharp * 100.0f)) / 100.0;
    at_track("gfx:sharpness", g.mode != "stretch");
    ImGui::EndDisabled();
    gfx_tip("render.upscaler.sharpness, 0 to 1. The contrast-adaptive sharpen of the spatial and temporal modes; the "
            "plain stretch has none.");
    show_problem("/render/upscaler/sharpness");
    ImGui::TextDisabled("Dynamic resolution is not part of these settings yet.");

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
    gfx_tip("Writes render.graphicsPreset and render.upscaler of factoria.json; nothing else in the file changes. "
            "Settings at their default are removed from the file.");
    ImGui::SameLine();
    ImGui::BeginDisabled(!dirty);
    if (ImGui::Button("Revert", ImVec2(110, 0))) graphics_settings_reload();
    ImGui::EndDisabled();
    at_track("gfx:revert", dirty);
    ImGui::End();
}

}  // namespace fa::editor
