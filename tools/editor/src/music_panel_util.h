// Small pieces the Music panel's two files share (music_panel.cpp: roll and drums; music_mixer_panel.cpp: arrangement and mixer).
#pragma once

#include <cstdint>
#include <format>
#include <string>

#include "imgui.h"
#include "imgui_stdlib.h"

namespace fa::editor::music_ui {

constexpr float kGutter = 44.0f;   // the pitch names on the left of the roll
constexpr float kRowH = 12.0f;
constexpr float kRulerH = 16.0f;
constexpr float kVelH = 52.0f;
constexpr int kRows = 37;          // three octaves

const ImVec4 kBad(1.0f, 0.55f, 0.45f, 1);
const ImVec4 kWarn(1.0f, 0.8f, 0.4f, 1);

struct SnapChoice {
    const char* label;
    std::int64_t ticks;
};

inline bool toggle_button(const char* label, bool on, ImVec2 size = ImVec2(0, 0)) {
    if (on) ImGui::PushStyleColor(ImGuiCol_Button, ImGui::GetStyleColorVec4(ImGuiCol_ButtonActive));
    const bool clicked = ImGui::Button(label, size);
    if (on) ImGui::PopStyleColor();
    return clicked;
}

inline std::string seconds_text(double s) {
    return std::format("{:02}:{:04.1f}", int(s / 60.0), s - 60.0 * double(int(s / 60.0)));
}

// A text box over a std::string. True while the text changes.
inline bool text_field(const char* id, std::string& text, std::size_t /*maxLen*/ = 256) { return ImGui::InputText(id, &text); }

}  // namespace fa::editor::music_ui
