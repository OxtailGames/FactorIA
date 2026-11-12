// The "Agents" tab of the AI settings window: the permission mode of each command-line agent (Claude Code, Codex), the
// "permissionMode" of its provider in the user's ai.json. A combo picks the mode and one line per value says what it allows; a
// dangerous mode (no permission checks, no sandbox) asks before Save writes it. Save writes only that key
// (ai::save_provider_permission_mode keeps every other key of ai.json). docs/AI_PROVIDERS.md, "Permission mode".
#include <algorithm>
#include <cfloat>

#include "editor_internal.h"

namespace fa::editor {

namespace {

const ai::PermissionMode* find_mode(const std::vector<ai::PermissionMode>& modes, const std::string& value) {
    const auto it = std::ranges::find_if(modes, [&](const ai::PermissionMode& m) { return value == m.value; });
    return it == modes.end() ? nullptr : &*it;
}

}  // namespace

void Editor::draw_ai_agents_tab(const ai::AiConfig& cfg, bool configReadable) {
    auto& d = aiSettings_;
    auto& a = d.agents;
    ImGui::TextWrapped("How much each command-line agent may do without asking you. It applies to the roles that run on that agent; a role "
                       "that only reads (a reviewer) is always held to read-only, whatever is chosen here.");
    ImGui::Spacing();
    bool any = false;
    for (const auto& [name, p] : cfg.providers) {
        const std::vector<ai::PermissionMode> modes = ai::permission_modes(p.kind);
        if (modes.empty()) continue;
        any = true;
        ImGui::PushID(name.c_str());
        const std::string saved = ai::effective_permission_mode(p);
        const auto picked = a.mode.find(name);
        const std::string shown = picked == a.mode.end() ? saved : picked->second;
        const ai::PermissionMode* current = find_mode(modes, shown);
        const bool explicitMode = !p.permissionMode.empty();
        const bool changed = shown != saved;

        ImGui::SeparatorText((name + (p.kind == ai::ProviderKind::ClaudeCode ? "  (Claude Code)" : "  (Codex)")).c_str());
        ImGui::AlignTextToFramePadding();
        ImGui::TextUnformatted("Permission mode");
        ImGui::SameLine();
        ImGui::SetNextItemWidth(ImGui::GetFontSize() * 14.0f);
        const std::string preview = shown + (current && current->dangerous ? "  (dangerous)" : (shown == ai::default_permission_mode(p.kind) ? "  (default)" : ""));
        if (ImGui::BeginCombo("##mode", preview.c_str())) {
            for (const ai::PermissionMode& m : modes) {
                const std::string label = std::string(m.value) + (m.dangerous ? "  (dangerous)" : (std::string(m.value) == ai::default_permission_mode(p.kind) ? "  (default)" : ""));
                if (m.dangerous) ImGui::PushStyleColor(ImGuiCol_Text, kStatusFailed);
                const bool chosen = ImGui::Selectable(label.c_str(), shown == m.value);
                if (m.dangerous) ImGui::PopStyleColor();
                if (chosen) {
                    if (std::string(m.value) == saved) a.mode.erase(name);
                    else a.mode[name] = m.value;
                    if (a.confirm == name) a.confirm.clear();
                    a.message.clear();
                }
            }
            ImGui::EndCombo();
        }
        at_track("aiset:agents:combo:" + name);
        ImGui::SetItemTooltip("Saved in your ai.json (not in a project): a project's file cannot change it.");

        // One line per value: what it allows. The one picked is marked.
        for (const ai::PermissionMode& m : modes) {
            const bool is = shown == m.value;
            const ImVec4 color = m.dangerous ? kStatusFailed : ImGui::GetStyleColorVec4(is ? ImGuiCol_Text : ImGuiCol_TextDisabled);
            ImGui::PushStyleColor(ImGuiCol_Text, color);
            ImGui::TextWrapped("%s %s%s: %s", is ? ">" : " ", m.value, m.dangerous ? " (dangerous)" : "", m.allows);
            ImGui::PopStyleColor();
        }
        if (!p.argv.empty()) {
            ImGui::TextDisabled("This provider has its own command line (argv): the flag below is added only when a mode is saved here, unless that line already has one.");
        }

        if (changed && current && current->dangerous) {
            ImGui::PushStyleColor(ImGuiCol_Text, kStatusFailed);
            ImGui::TextWrapped("%s lifts the guard rails: the agent can run any command and change any file it can reach without asking. "
                               "Use it only in a folder you can lose.", shown.c_str());
            ImGui::PopStyleColor();
        }

        ImGui::BeginDisabled(!changed || !configReadable);
        const bool dangerousPending = changed && current && current->dangerous;
        if (a.confirm == name) {
            if (ImGui::Button("Yes, allow it")) {
                a.confirm.clear();
                if (auto saved2 = ai::save_provider_permission_mode(name, shown, d.path); !saved2) {
                    a.message = saved2.error().to_string();
                    a.failed = true;
                } else {
                    a.message = name + ": permission mode " + shown + " saved.";
                    a.failed = false;
                    a.mode.erase(name);
                    ai_agents_reload();
                }
            }
            at_track("aiset:agents:confirm", changed);
            ImGui::SameLine();
            if (ImGui::Button("Cancel")) a.confirm.clear();
            at_track("aiset:agents:cancel", changed);
        } else {
            if (ImGui::Button(dangerousPending ? "Save..." : "Save")) {
                if (dangerousPending) {
                    a.confirm = name;
                } else if (auto saved2 = ai::save_provider_permission_mode(name, shown, d.path); !saved2) {
                    a.message = saved2.error().to_string();
                    a.failed = true;
                } else {
                    a.message = name + ": permission mode " + shown + " saved.";
                    a.failed = false;
                    a.mode.erase(name);
                    ai_agents_reload();
                }
            }
            at_track("aiset:agents:save:" + name, changed && configReadable);
            ImGui::SetItemTooltip("Writes this mode into your ai.json. The next message to the AI uses it.");
        }
        ImGui::EndDisabled();
        if (explicitMode) {
            ImGui::SameLine();
            ImGui::BeginDisabled(!configReadable);
            if (ImGui::Button("Use the default")) {
                if (auto removed = ai::save_provider_permission_mode(name, "", d.path); !removed) {
                    a.message = removed.error().to_string();
                    a.failed = true;
                } else {
                    a.message = name + ": back to the default (" + ai::default_permission_mode(p.kind) + ").";
                    a.failed = false;
                    a.mode.erase(name);
                    a.confirm.clear();
                    ai_agents_reload();
                }
            }
            ImGui::EndDisabled();
            at_track("aiset:agents:reset:" + name, configReadable);
            ImGui::SetItemTooltip("Takes the permission mode out of ai.json: the default of the agent applies (%s).", ai::default_permission_mode(p.kind).c_str());
        }
        ImGui::PopID();
    }
    if (!any) ImGui::TextDisabled("No Claude Code or Codex provider in ai.json.");
    if (!a.message.empty()) {
        ImGui::PushStyleColor(ImGuiCol_Text, a.failed ? kStatusFailed : kStatusReady);
        ImGui::TextWrapped("%s", a.message.c_str());
        ImGui::PopStyleColor();
    }
    ImGui::Spacing();
    if (ImGui::Button("Close")) {
        showAiSettings_ = false;
        ai_settings_discard();
    }
    at_track("aiset:agents:close");
}

// The file changed under the window: the editor's config follows it and the draft keeps what was typed in its other tabs.
void Editor::ai_agents_reload() {
    auto loaded = ai::load_config(aiSettings_.path);
    {
        std::lock_guard<std::mutex> lock(aiMu_);
        if (loaded) aiConfig_ = *loaded;
        aiConfigError_ = loaded ? std::string() : loaded.error().to_string();
    }
    ai_project_invalidate();
    if (loaded) {
        auto message = std::move(aiSettings_.agents.message);
        const bool failed = aiSettings_.agents.failed;
        ai_settings_load(*loaded, true, true);
        aiSettings_.agents.message = std::move(message);
        aiSettings_.agents.failed = failed;
        notify("Permission mode saved. The next message to the AI uses it.");
    } else {
        aiSettings_.agents.message = "Saved, but ai.json no longer loads: " + loaded.error().to_string();
        aiSettings_.agents.failed = true;
    }
    if (!aiDetecting_.load()) ai_refresh_providers();
}

}  // namespace fa::editor
