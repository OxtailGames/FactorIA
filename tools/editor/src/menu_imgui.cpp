// The menu tree drawn with Dear ImGui: the in-window main menu bar of Windows and Linux (and of the autotest everywhere).
#include "imgui.h"
#include "menu_model.h"

namespace fa::editor::menu {

namespace {

using Track = std::function<void(const std::string&, bool)>;

void finish_item(const Item& it, const Track& track) {
    if (!it.atName.empty() && track) track(it.atName, it.enabled);
    if ((it.tooltipFn || !it.tooltip.empty()) && ImGui::IsItemHovered(ImGuiHoveredFlags_ForTooltip))
        ImGui::SetTooltip("%s", it.tooltip_text().c_str());
}

void draw_items(const std::vector<Item>& items, const Track& track) {
    for (const Item& it : items) {
        if (it.is_separator()) {
            ImGui::Separator();
        } else if (it.is_menu()) {
            const bool open = ImGui::BeginMenu(it.label.c_str(), it.enabled);
            finish_item(it, track);
            if (open) {
                draw_items(it.resolved_children(), track);  // a lazy menu builds its items only now, while it is open
                ImGui::EndMenu();
            }
        } else {
            const std::string shortcut = shortcut_label(it.shortcut_for(kApple), kApple);
            if (ImGui::MenuItem(it.label.c_str(), shortcut.empty() ? nullptr : shortcut.c_str(), it.checked, it.enabled) && it.action)
                it.action();
            finish_item(it, track);
        }
    }
}

}  // namespace

bool draw_imgui_bar(const MainMenu& menu, const Track& track) {
    if (!ImGui::BeginMainMenuBar()) return false;
    draw_items(menu.items, track);
    if (!menu.trailing.empty()) {
        // Text at the right end of the bar (the engine version), so it is always clear which FactorIA is running.
        const float width = ImGui::CalcTextSize(menu.trailing.c_str()).x + ImGui::GetStyle().ItemSpacing.x;
        if (ImGui::GetContentRegionAvail().x > width) {
            ImGui::SetCursorPosX(ImGui::GetCursorPosX() + ImGui::GetContentRegionAvail().x - width);
            ImGui::TextDisabled("%s", menu.trailing.c_str());
            if (!menu.trailingTooltip.empty()) ImGui::SetItemTooltip("%s", menu.trailingTooltip.c_str());
            if (!menu.trailingAtName.empty() && track) track(menu.trailingAtName, true);
        }
    }
    ImGui::EndMainMenuBar();
    return true;
}

}  // namespace fa::editor::menu
