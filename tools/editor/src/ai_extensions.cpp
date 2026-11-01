// The "Extensions" tab of the AI settings window: the plugins, skill folders and hooks the AI agents load (Claude Code; hooks also the
// API providers), the skills every provider can read (engine, yours, the project's, with on/off per role), from the user's ai.json
// ("extensions") and from the open project's .factoria/extensions.json. Save writes only those two places
// (ai::save_extensions keeps every other key of ai.json) and reloads. A project's plugins and hooks run only after the user
// trusts the project here (docs/EDITOR.md "AI settings", docs/AI_PROVIDERS.md "Extensions"). The last section lists the hooks as
// saved (what `ai.hooks` returns) and the recent runs of this editor, failures in red (docs/HOOKS.md).
#include <algorithm>
#include <cfloat>
#include <ctime>
#include <filesystem>
#include <set>

#include "editor_internal.h"
#include "fa/ai/command_hooks.h"
#include "fa/ai/extension_plan.h"
#include "fa/core/strings.h"

namespace fa::editor {

namespace {

namespace stdfs = std::filesystem;

const char* const kRoleShort[] = {"Orch", "Work", "Fast", "Art", "Audio", "ArtC", "Rev"};

bool role_on(const ai::Extension& e, const char* role) {
    if (!e.roles.empty()) return std::ranges::find(e.roles, std::string(role)) != e.roles.end();
    return std::ranges::any_of(ai::kDefaultExtensionRoles, [&](const char* r) { return std::string_view(r) == role; });
}

// Switches one role of an entry; an entry that lists exactly the default roles goes back to listing none.
void toggle_role(ai::Extension& e, const char* role) {
    std::vector<std::string> now;
    for (const char* r : ai::kAllRoles)
        if (role_on(e, r)) now.push_back(r);
    const auto it = std::ranges::find(now, std::string(role));
    if (it != now.end()) now.erase(it);
    else now.push_back(role);
    std::set<std::string> have(now.begin(), now.end()), def;
    for (const char* r : ai::kDefaultExtensionRoles) def.insert(r);
    e.roles = have == def ? std::vector<std::string>{} : now;
}

std::string entry_key(const ai::Extension& e) { return std::string(ai::extension_kind_name(e.kind)) + ":" + e.source + ":" + e.name; }

// "name" for a folder: its last segment made of letters, digits, '_' and '-'.
std::string derive_name(const std::string& path) {
    std::string base = stdfs::path(path).filename().string();
    if (base.empty()) base = stdfs::path(path).parent_path().filename().string();
    if (const auto dot = base.rfind(".zip"); dot != std::string::npos && dot + 4 == base.size()) base.erase(dot);
    std::string out;
    for (char c : base) out += (std::isalnum(static_cast<unsigned char>(c)) || c == '_' || c == '-') ? c : '-';
    if (out.size() > ai::kMaxExtensionName) out.resize(ai::kMaxExtensionName);
    return out;
}

// ~/x for a path inside the home folder (what ai.json should hold: it works on every computer the file is copied to).
std::string with_tilde(const std::string& path) {
    const std::string home = home_dir();
    if (home.empty()) return path;
    std::error_code ec;
    const stdfs::path rel = stdfs::path(path).lexically_relative(home);
    if (rel.empty() || *rel.begin() == ".." || rel.is_absolute()) return path;
    return rel == "." ? "~" : "~/" + rel.generic_string();
}

// The commands a hooks object would run, one per line.
std::string hook_commands(const Json& hooks) {
    std::string out;
    if (!hooks.is_object()) return out;
    for (const auto& [event, groups] : hooks.items()) {
        if (!groups.is_array()) continue;
        for (const Json& group : groups) {
            if (!group.is_object() || !group.contains("hooks")) continue;
            for (const Json& h : group["hooks"]) {
                std::string what = h.value("command", h.value("prompt", h.value("url", std::string())));
                if (what.empty()) what = h.value("type", std::string("hook"));
                out += (out.empty() ? "" : "\n") + event + ": " + what;
            }
        }
    }
    return out;
}

std::size_t hook_events(const Json& hooks) { return hooks.is_object() ? hooks.size() : 0; }

std::string run_result(const Json& r) {
    if (r.value("timedOut", false)) return "timed out";
    if (r.value("failed", false)) return "failed";
    const std::string decision = r.value("decision", std::string());
    return decision.empty() ? "ok" : decision;
}

}  // namespace

// The "Hooks" section: every handler of the saved hooks entries with where it runs, then the recent runs of this editor.
void Editor::draw_ai_hooks_view(const Json& report) {
    const float em = ImGui::GetFontSize();
    ImGui::SeparatorText("Hooks");
    ImGui::TextDisabled("As saved, with the runs of this editor since it started. Claude Code's own runs are in its transcript, not here.");
    const Json entries = report.value("entries", Json::array());
    std::size_t handlers = 0;
    if (ImGui::BeginTable("##hookhandlers", 6, ImGuiTableFlags_SizingFixedFit | ImGuiTableFlags_NoSavedSettings | ImGuiTableFlags_RowBg)) {
        ImGui::TableSetupColumn("Entry", ImGuiTableColumnFlags_WidthFixed, em * 8.0f);
        ImGui::TableSetupColumn("Event", ImGuiTableColumnFlags_WidthFixed, em * 8.5f);
        ImGui::TableSetupColumn("Matcher", ImGuiTableColumnFlags_WidthFixed, em * 7.0f);
        ImGui::TableSetupColumn("Type", ImGuiTableColumnFlags_WidthFixed, em * 5.0f);
        ImGui::TableSetupColumn("Handler", ImGuiTableColumnFlags_WidthStretch);
        ImGui::TableSetupColumn("Runs in", ImGuiTableColumnFlags_WidthFixed, em * 11.0f);
        ImGui::TableHeadersRow();
        for (const Json& e : entries) {
            if (!e.is_object() || !e.contains("events")) continue;
            const std::string name = e.value("name", std::string()) + (e.value("source", std::string()) == "project" ? " (project)" : "");
            const std::string problem = e.value("problem", std::string());
            const bool off = !e.value("enabled", true) || !problem.empty();
            for (const auto& [event, groups] : e["events"].items()) {
                for (const Json& g : groups) {
                    for (const Json& h : g.value("handlers", Json::array())) {
                        ++handlers;
                        const std::string type = h.value("type", std::string());
                        const bool engineEvent = event == "beforeCommand" || event == "afterCommand";
                        ImGui::TableNextRow();
                        if (off) ImGui::PushStyleColor(ImGuiCol_Text, ImGui::GetStyleColorVec4(ImGuiCol_TextDisabled));
                        ImGui::TableNextColumn();
                        ImGui::TextUnformatted(name.c_str());
                        if (!problem.empty()) ImGui::SetItemTooltip("Not run: %s", problem.c_str());
                        else if (!e.value("enabled", true)) ImGui::SetItemTooltip("Switched off in the list above.");
                        ImGui::TableNextColumn();
                        ImGui::TextUnformatted(event.c_str());
                        ImGui::TableNextColumn();
                        const std::string matcher = g.value("matcher", std::string());
                        ImGui::TextUnformatted(matcher.empty() ? "(all)" : matcher.c_str());
                        ImGui::TableNextColumn();
                        ImGui::TextUnformatted(type.c_str());
                        ImGui::TableNextColumn();
                        ImGui::TextUnformatted(h.value("target", std::string()).c_str());
                        ImGui::SetItemTooltip("%s", h.value("target", std::string()).c_str());
                        ImGui::TableNextColumn();
                        ImGui::TextUnformatted(engineEvent                     ? "FactorIA, all callers"
                                               : h.value("runsHere", false) ? "Every provider"
                                                                            : "Claude Code only");
                        if (off) ImGui::PopStyleColor();
                    }
                }
            }
        }
        ImGui::EndTable();
    }
    if (handlers == 0) ImGui::TextDisabled("No hooks yet. Paste a hooks JSON above, or write them in .factoria/extensions.json (docs/HOOKS.md).");
    for (const Json& e : entries)
        if (e.is_object() && e.contains("problem") && e.contains("events") && !e["events"].empty() && e.value("enabled", true))
            ImGui::TextColored(kStatusWarn, "%s: %s", e.value("name", std::string()).c_str(), e.value("problem", std::string()).c_str());
    if (report.contains("projectFileError"))
        ImGui::TextColored(kStatusFailed, "The project's extensions file is ignored: %s", report["projectFileError"].get<std::string>().c_str());
    for (const Json& n : report.value("notRun", Json::array()))
        if (n.is_string()) ImGui::TextDisabled("%s", n.get<std::string>().c_str());

    // The recent runs, newest first.
    const Json runs = report.value("recentRuns", Json::array());
    std::size_t failed = 0;
    for (const Json& r : runs) failed += r.value("failed", false) ? 1 : 0;
    ImGui::AlignTextToFramePadding();
    ImGui::Text("Recent runs: %zu", runs.size());
    if (failed > 0) {
        ImGui::SameLine();
        ImGui::TextColored(kStatusFailed, "%zu failed", failed);
    }
    ImGui::SameLine();
    ImGui::BeginDisabled(runs.empty());
    if (ImGui::SmallButton("Clear")) {
        ai::clear_recent_hook_runs();
        aiSettings_.ext.hooksAt = -10;
    }
    ImGui::EndDisabled();
    at_track("aiset:ext:hooks-clear", !runs.empty());
    ImGui::SetItemTooltip("Forget the list of runs (the hooks stay).");
    if (runs.empty()) {
        ImGui::TextDisabled("No hook has run in this editor yet. A hook runs when the built-in AI (API providers) or a command of the engine reaches its event.");
        return;
    }
    if (ImGui::BeginTable("##hookruns", 6, ImGuiTableFlags_SizingFixedFit | ImGuiTableFlags_NoSavedSettings | ImGuiTableFlags_RowBg)) {
        ImGui::TableSetupColumn("When", ImGuiTableColumnFlags_WidthFixed, em * 4.5f);
        ImGui::TableSetupColumn("Event", ImGuiTableColumnFlags_WidthFixed, em * 8.5f);
        ImGui::TableSetupColumn("On", ImGuiTableColumnFlags_WidthFixed, em * 9.0f);
        ImGui::TableSetupColumn("Handler", ImGuiTableColumnFlags_WidthStretch);
        ImGui::TableSetupColumn("Result", ImGuiTableColumnFlags_WidthFixed, em * 5.5f);
        ImGui::TableSetupColumn("ms", ImGuiTableColumnFlags_WidthFixed, em * 3.5f);
        ImGui::TableHeadersRow();
        const i64 now = static_cast<i64>(std::time(nullptr));
        int row = 0;
        for (auto it = runs.rbegin(); it != runs.rend() && row < 25; ++it, ++row) {
            const Json& r = *it;
            const bool bad = r.value("failed", false);
            ImGui::TableNextRow();
            ImGui::TableNextColumn();
            ImGui::TextUnformatted(format_clock(r.value("startedMs", static_cast<i64>(0)) / 1000, now).c_str());
            if (row == 0) at_track("aiset:ext:hookrun:first");
            ImGui::TableNextColumn();
            ImGui::TextUnformatted(r.value("event", std::string()).c_str());
            ImGui::TableNextColumn();
            ImGui::TextUnformatted(r.value("matched", std::string()).c_str());
            ImGui::TableNextColumn();
            ImGui::TextUnformatted((r.value("extension", std::string()) + ": " + r.value("target", std::string())).c_str());
            std::string tip = r.value("extension", std::string()) + " (" + r.value("source", std::string()) + "): " + r.value("target", std::string());
            for (const char* key : {"error", "reason", "output", "stderr"})
                if (r.contains(key) && r[key].is_string() && !r[key].get<std::string>().empty()) tip += std::string("\n") + key + ": " + r[key].get<std::string>();
            if (r.contains("exitCode")) tip += "\nexit code " + std::to_string(r["exitCode"].get<int>());
            ImGui::SetItemTooltip("%s", tip.c_str());
            ImGui::TableNextColumn();
            if (bad) ImGui::PushStyleColor(ImGuiCol_Text, kStatusFailed);
            else if (r.value("decision", std::string()) == "block") ImGui::PushStyleColor(ImGuiCol_Text, kStatusWarn);
            ImGui::TextUnformatted(run_result(r).c_str());
            if (bad || r.value("decision", std::string()) == "block") ImGui::PopStyleColor();
            ImGui::TableNextColumn();
            ImGui::Text("%.0f", r.value("ms", 0.0));
        }
        ImGui::EndTable();
    }
}

void Editor::ai_extensions_load(const ai::AiConfig& cfg) {
    auto& x = aiSettings_.ext;
    x = AiSettingsDraft::ExtensionsDraft{};
    x.user = cfg.extensions.entries;
    x.userLoaded = x.user;
    x.inherit = cfg.extensions.inheritUserPlugins;
    if (projectDir_.empty()) return;
    ai::ProjectExtensions p = ai::load_project_extensions(projectDir_);
    x.projectExists = p.exists;
    x.projectError = p.error;
    x.projectHash = p.hash;
    x.project = p.entries;
    x.projectLoaded = p.entries;
    const ai::ClaudeProjectSettings claude = ai::load_claude_project_settings(projectDir_);
    x.claudeHash = claude.hash;
    x.claudeGrants = claude.describe();
    const std::string cfgPath = cfg.sourcePath.empty() ? ai::default_config_path() : cfg.sourcePath;
    x.projectTrusted = p.error.empty() &&
                       ai::project_extensions_trusted(ai::extensions_trust_path(cfgPath), projectDir_, p.hash, nullptr, false, claude.hash);
}

void Editor::draw_ai_extensions_tab(const ai::AiConfig& cfg, bool configReadable) {
    AiSettingsDraft& d = aiSettings_;
    auto& x = d.ext;
    const float em = ImGui::GetFontSize();
    const auto wrapped = [](const ImVec4& color, const std::string& text) {
        ImGui::PushStyleColor(ImGuiCol_Text, color);
        ImGui::TextWrapped("%s", text.c_str());
        ImGui::PopStyleColor();
    };
    const std::string cfgPath = d.path;
    const std::string trustPath = ai::extensions_trust_path(cfgPath);

    ImGui::PushStyleColor(ImGuiCol_Text, ImGui::GetStyleColorVec4(ImGuiCol_TextDisabled));
    ImGui::TextWrapped("Saved in %s (your own file outside any project)%s. Only the extensions are rewritten: your providers, roles and limits stay.",
                       d.path.c_str(), projectDir_.empty() ? "" : " and in this project's .factoria/extensions.json");
    ImGui::PopStyleColor();

    const float footerH = ImGui::GetFrameHeight() + ImGui::GetStyle().ItemSpacing.y * 3.0f + ImGui::GetTextLineHeightWithSpacing() * 2.0f;
    ImGui::BeginChild("##aiextbody", ImVec2(0, -footerH));
    ImGui::TextWrapped("Plugins, skills and hooks the AI agents load besides FactorIA's own tools: a plugin folder (or .zip, or one you installed "
                       "in Claude Code), a skill folder, hooks that run a program or a script on an event. Skills reach every provider: the "
                       "built-in loop reads them with skills_read, Claude Code loads them itself and Codex finds them in the project's "
                       ".agents/skills during the run. Plugins are for Claude Code; the API providers (anthropic, openai-compatible) run the "
                       "hooks, and so does the engine around its own commands; Codex takes no plugins or hooks, and the run says so.");

    // What stops each entry from loading, looked up once a second (it reads the disk).
    ai::ExtensionContext ctx;
    ctx.projectDir = projectDir_;
    ctx.trustPath = trustPath;
    ctx.dropStaleTrust = false;
    if (ImGui::GetTime() - x.statusAt > 1.0) {
        x.status.clear();
        if (!projectDir_.empty() && (x.projectExists || !x.claudeHash.empty())) {
            // A file may have changed on disk since this tab read it (an AI edited it): the trust is for the bytes that were read.
            const ai::ProjectExtensions disk = ai::load_project_extensions(projectDir_);
            const ai::ClaudeProjectSettings claude = ai::load_claude_project_settings(projectDir_);
            x.projectTrusted = x.projectTrusted && disk.hash == x.projectHash && claude.hash == x.claudeHash &&
                               ai::project_extensions_trusted(trustPath, projectDir_, disk.hash, nullptr, false, claude.hash);
        }
        for (const auto* list : {&x.user, &x.project}) {
            for (const ai::Extension& e : *list) {
                const ai::ExtensionItem item = ai::resolve_extension(e, ctx, x.projectTrusted);
                x.status[entry_key(e)] = item.problem;
            }
        }
        ai::SkillsContext sctx;
        sctx.projectDir = projectDir_;
        x.skills = ai::scan_skills(x.user, x.project, sctx);
        x.statusAt = ImGui::GetTime();
    }
    // The hooks as saved and the runs this editor made, looked up once a second as well (reads the disk).
    if (ImGui::GetTime() - x.hooksAt > 1.0) {
        x.hooksReport = ai::hooks_report(cfg, ctx, "", 40);
        x.hooksAt = ImGui::GetTime();
    }

    // ------------------------------------------------------------------------------------------------ the list
    ImGui::SeparatorText("Extensions");
    int remove = -1;
    bool removeProject = false;
    const std::size_t total = x.user.size() + x.project.size();
    if (total == 0) ImGui::TextDisabled("None yet. Add a plugin or skill folder, or paste hooks.");
    if (total > 0 && ImGui::BeginTable("##extensions", 5 + 7 + 2, ImGuiTableFlags_SizingFixedFit | ImGuiTableFlags_NoSavedSettings)) {
        ImGui::TableSetupColumn("On", ImGuiTableColumnFlags_WidthFixed, em * 2.5f);
        ImGui::TableSetupColumn("Kind", ImGuiTableColumnFlags_WidthFixed, em * 4.0f);
        ImGui::TableSetupColumn("Name", ImGuiTableColumnFlags_WidthFixed, em * 7.0f);
        ImGui::TableSetupColumn("From", ImGuiTableColumnFlags_WidthFixed, em * 4.2f);
        ImGui::TableSetupColumn("Where", ImGuiTableColumnFlags_WidthStretch);
        for (const char* r : kRoleShort) ImGui::TableSetupColumn(r, ImGuiTableColumnFlags_WidthFixed, em * 2.9f);
        ImGui::TableSetupColumn("##remove", ImGuiTableColumnFlags_WidthFixed, em * 4.6f);
        ImGui::TableSetupColumn("Status", ImGuiTableColumnFlags_WidthFixed, em * 8.0f);
        ImGui::TableHeadersRow();
        for (int pass = 0; pass < 2; ++pass) {
            std::vector<ai::Extension>& list = pass == 0 ? x.user : x.project;
            for (std::size_t i = 0; i < list.size(); ++i) {
                ai::Extension& e = list[i];
                ImGui::PushID(pass * 10000 + static_cast<int>(i));
                const std::string key = std::string(ai::extension_kind_name(e.kind)) + ":" + e.name;
                ImGui::TableNextRow();
                ImGui::TableNextColumn();
                ImGui::Checkbox("##enabled", &e.enabled);
                at_track("aiset:ext:enabled:" + key);
                ImGui::SetItemTooltip("Off: no agent loads it; its settings stay.");
                ImGui::TableNextColumn();
                ImGui::AlignTextToFramePadding();
                ImGui::TextUnformatted(ai::extension_kind_name(e.kind));
                ImGui::TableNextColumn();
                ImGui::TextUnformatted(e.name.c_str());
                ImGui::TableNextColumn();
                ImGui::TextDisabled("%s", pass == 0 ? "you" : "project");
                ImGui::SetItemTooltip("%s", pass == 0 ? "Your ai.json: every project you open." : "This project's .factoria/extensions.json: it travels with the project.");
                ImGui::TableNextColumn();
                std::string where = e.kind == ai::ExtensionKind::Hooks ? std::to_string(hook_events(e.hooks)) + (hook_events(e.hooks) == 1 ? " event" : " events")
                                    : !e.plugin.empty()                ? e.plugin
                                                                       : e.path;
                ImGui::TextUnformatted(where.c_str());
                const std::string tip = e.kind == ai::ExtensionKind::Hooks ? hook_commands(e.hooks) : where;
                ImGui::SetItemTooltip("%s", tip.c_str());
                for (const char* r : ai::kAllRoles) {
                    ImGui::TableNextColumn();
                    bool on = role_on(e, r);
                    if (ImGui::Checkbox((std::string("##role") + r).c_str(), &on)) toggle_role(e, r);
                    at_track(std::string("aiset:ext:role:") + key + ":" + r);
                    const bool review = std::string_view(r) == ai::kRoleArtCritic || std::string_view(r) == ai::kRoleReviewer;
                    ImGui::SetItemTooltip("%s%s", r, review ? ": reviewers only look at the game; load an extension for them only on purpose." : "");
                }
                ImGui::TableNextColumn();
                if (ImGui::SmallButton("Remove")) {
                    remove = static_cast<int>(i);
                    removeProject = pass == 1;
                }
                at_track("aiset:ext:remove:" + key);
                ImGui::TableNextColumn();
                const auto st = x.status.find(entry_key(e));
                const std::string problem = st == x.status.end() ? std::string() : st->second;
                if (!e.enabled) {
                    ImGui::TextDisabled("Off");
                } else if (!problem.empty()) {
                    const bool untrusted = problem.rfind("it comes from this project", 0) == 0;
                    ImGui::PushStyleColor(ImGuiCol_Text, untrusted ? kStatusWarn : kStatusFailed);
                    ImGui::TextUnformatted(untrusted ? "Not trusted" : "Cannot load");
                    ImGui::PopStyleColor();
                    ImGui::SetItemTooltip("%s", problem.c_str());
                } else {
                    ImGui::PushStyleColor(ImGuiCol_Text, kStatusReady);
                    ImGui::TextUnformatted("Ready");
                    ImGui::PopStyleColor();
                }
                ImGui::PopID();
            }
        }
        ImGui::EndTable();
    }
    if (remove >= 0) {
        auto& list = removeProject ? x.project : x.user;
        list.erase(list.begin() + remove);
        x.statusAt = -10;
    }


    // ------------------------------------------------------------------------------------------------ skills
    // Every skill a role can be offered (docs/SKILLS.md): FactorIA's own, ~/.factoria/skills, the project's skills/ folder and the
    // folders named by entries above. A change is kept as a skill entry of the list above, so Save writes it like any other.
    ImGui::SeparatorText("Skills");
    ImGui::TextDisabled("Topic guides the AI reads when the work needs them. On/off per role; Save keeps the choice.");
    const auto skill_entry = [&](const ai::SkillInfo& s) -> ai::Extension& {
        if (!s.entry.empty()) {
            for (ai::Extension& e : s.entryScope == "project" ? x.project : x.user)
                if (e.kind == ai::ExtensionKind::Skill && e.name == s.entry) return e;
        }
        const bool project = s.source == "project" && !projectDir_.empty();
        std::vector<ai::Extension>& list = project ? x.project : x.user;
        std::string name = s.name.substr(0, ai::kMaxExtensionName);
        for (int n = 2; std::ranges::any_of(list, [&](const ai::Extension& e) { return e.kind == ai::ExtensionKind::Skill && e.name == name; }); ++n)
            name = s.name.substr(0, ai::kMaxExtensionName - 4) + "-" + std::to_string(n);
        ai::Extension e;
        e.kind = ai::ExtensionKind::Skill;
        e.name = name;
        e.source = project ? "project" : "user";
        if (s.is_engine()) {
            e.path = s.dir;
        } else if (project) {
            e.path = stdfs::path(s.dir).lexically_relative(stdfs::path(projectDir_)).generic_string();
        } else {
            e.path = with_tilde(s.dir);
        }
        list.push_back(e);
        x.statusAt = -10;
        return list.back();
    };
    if (x.skills.empty()) ImGui::TextDisabled("No skills found.");
    if (!x.skills.empty() && ImGui::BeginTable("##skills", 4 + 7 + 1, ImGuiTableFlags_SizingFixedFit | ImGuiTableFlags_NoSavedSettings)) {
        ImGui::TableSetupColumn("On", ImGuiTableColumnFlags_WidthFixed, em * 2.5f);
        ImGui::TableSetupColumn("Skill", ImGuiTableColumnFlags_WidthFixed, em * 12.5f);
        ImGui::TableSetupColumn("From", ImGuiTableColumnFlags_WidthFixed, em * 4.2f);
        ImGui::TableSetupColumn("What it is for", ImGuiTableColumnFlags_WidthStretch);
        for (const char* r : kRoleShort) ImGui::TableSetupColumn(r, ImGuiTableColumnFlags_WidthFixed, em * 2.9f);
        ImGui::TableSetupColumn("Status", ImGuiTableColumnFlags_WidthFixed, em * 8.0f);
        ImGui::TableHeadersRow();
        // Copy: a change below adds an entry and the list is rescanned a frame later.
        const std::vector<ai::SkillInfo> shown = x.skills;
        for (std::size_t i = 0; i < shown.size(); ++i) {
            const ai::SkillInfo& s = shown[i];
            const bool usable = s.problem.empty() && s.shadowedBy.empty();
            const std::string key = s.name;
            ImGui::PushID(static_cast<int>(i));
            ImGui::TableNextRow();
            ImGui::TableNextColumn();
            ImGui::BeginDisabled(!usable);
            bool enabled = s.enabled;
            if (ImGui::Checkbox("##skillon", &enabled)) skill_entry(s).enabled = enabled;
            ImGui::EndDisabled();
            if (usable) at_track("aiset:ext:skill:enabled:" + key);
            ImGui::SetItemTooltip("Off: no role is offered this skill; its files stay.");
            ImGui::TableNextColumn();
            ImGui::AlignTextToFramePadding();
            ImGui::TextUnformatted(s.name.c_str());
            ImGui::TableNextColumn();
            ImGui::TextDisabled("%s", s.source == "engine" ? "engine" : s.source == "user" ? "you" : "project");
            ImGui::SetItemTooltip("%s", s.is_engine() ? "Ships inside FactorIA." : s.dir.c_str());
            ImGui::TableNextColumn();
            ImGui::TextUnformatted(s.description.c_str());
            ImGui::SetItemTooltip("%s", s.description.c_str());
            const std::vector<std::string> now = s.effective_roles();
            for (const char* r : ai::kAllRoles) {
                ImGui::TableNextColumn();
                ImGui::BeginDisabled(!usable);
                bool on = std::ranges::find(now, std::string(r)) != now.end();
                if (ImGui::Checkbox((std::string("##skillrole") + r).c_str(), &on)) {
                    std::vector<std::string> next;
                    for (const char* all : ai::kAllRoles) {
                        const bool wanted = std::string_view(all) == r ? on : std::ranges::find(now, std::string(all)) != now.end();
                        if (wanted) next.push_back(all);
                    }
                    const std::set<std::string> have(next.begin(), next.end()), def(s.defaultRoles.begin(), s.defaultRoles.end());
                    skill_entry(s).roles = have == def ? std::vector<std::string>{} : next;
                }
                ImGui::EndDisabled();
                if (usable) at_track(std::string("aiset:ext:skill:role:") + key + ":" + r);
                ImGui::SetItemTooltip("%s", r);
            }
            ImGui::TableNextColumn();
            if (!s.problem.empty()) {
                ImGui::PushStyleColor(ImGuiCol_Text, kStatusFailed);
                ImGui::TextUnformatted("Cannot load");
                ImGui::PopStyleColor();
                ImGui::SetItemTooltip("%s %s", s.problem.c_str(), s.fix.c_str());
            } else if (!s.shadowedBy.empty()) {
                ImGui::TextDisabled("Replaced");
                ImGui::SetItemTooltip("A %s with this name is used instead.", s.shadowedBy.c_str());
            } else if (!s.enabled) {
                ImGui::TextDisabled("Off");
            } else {
                ImGui::PushStyleColor(ImGuiCol_Text, kStatusReady);
                ImGui::TextUnformatted("Ready");
                ImGui::PopStyleColor();
            }
            ImGui::PopID();
        }
        ImGui::EndTable();
    }

    // ------------------------------------------------------------------------------------------------ add a folder
    ImGui::SeparatorText("Add");
    ImGui::AlignTextToFramePadding();
    ImGui::TextUnformatted("Add");
    ImGui::SameLine();
    ImGui::SetNextItemWidth(em * 15.0f);
    const char* kinds[] = {"Plugin folder or .zip", "Skill folder", "Installed Claude Code plugin"};
    if (ImGui::BeginCombo("##addkind", kinds[x.addKind])) {
        for (int i = 0; i < 3; ++i)
            if (ImGui::Selectable(kinds[i], x.addKind == i)) x.addKind = i;
        ImGui::EndCombo();
    }
    at_track("aiset:ext:addkind");
    ImGui::SetItemTooltip("A plugin is a folder with .claude-plugin/plugin.json (or its .zip). A skill folder holds a SKILL.md, or folders that do.\n"
                          "An installed plugin is one `claude plugin install name@marketplace` put on this computer.");
    ImGui::SameLine();
    ImGui::SetNextItemWidth(em * 22.0f);
    ImGui::InputTextWithHint("##addpath", x.addKind == 2 ? "superpowers@claude-plugins-official" : "~/my-plugins/notes", &x.addPath);
    at_track("aiset:ext:addpath");
    ImGui::SetItemTooltip("%s", x.addKind == 2 ? "name@marketplace, as `claude plugin list` shows it."
                                               : "The folder (or .zip). ~ is your home folder. In a project's file the path is relative to the project.");
    if (x.addKind != 2) {
        ImGui::SameLine();
        if (ImGui::Button("Browse...")) {
            const std::string picked = pick_folder(x.addKind == 1 ? "Skill folder" : "Plugin folder", x.addPath.empty() ? home_dir() : x.addPath);
            if (!picked.empty()) x.addPath = picked;
        }
        at_track("aiset:ext:browse");
    }
    ImGui::AlignTextToFramePadding();
    ImGui::TextUnformatted("Name");
    ImGui::SameLine();
    ImGui::SetNextItemWidth(em * 12.0f);
    ImGui::InputTextWithHint("##addname", "from the folder", &x.addName);
    at_track("aiset:ext:addname");
    ImGui::SetItemTooltip("What the extension is called in this list: letters, digits, '_' and '-'. Empty = taken from the folder.");
    ImGui::SameLine();
    ImGui::BeginDisabled(projectDir_.empty());
    ImGui::Checkbox("Only for this project", &x.addToProject);
    ImGui::EndDisabled();
    at_track("aiset:ext:addproject", !projectDir_.empty());
    ImGui::SetItemTooltip("Keep it in this project's .factoria/extensions.json instead of your ai.json. A project's plugin runs only after you trust the project.");
    ImGui::SameLine();
    if (ImGui::Button("Add")) {
        x.addError.clear();
        const std::string raw = std::string(trim(x.addPath));
        const bool project = x.addToProject && !projectDir_.empty();
        std::string path = raw;
        if (raw.empty()) {
            x.addError = x.addKind == 2 ? "Type the plugin as name@marketplace." : "Choose a folder (Browse...) or type its path.";
        } else if (x.addKind != 2) {
            if (project) {
                const stdfs::path abs = stdfs::path(ai::expand_home(raw, ai::system_env())).is_absolute() ? stdfs::path(ai::expand_home(raw, ai::system_env()))
                                                                                          : stdfs::path(projectDir_) / raw;
                const stdfs::path rel = abs.lexically_normal().lexically_relative(stdfs::path(projectDir_).lexically_normal());
                if (rel.empty() || *rel.begin() == "..") x.addError = "'" + raw + "' is outside the project. Keep it in your ai.json, or move it into the project.";
                else path = rel.generic_string();
            } else {
                path = with_tilde(stdfs::path(ai::expand_home(raw, ai::system_env())).is_absolute() ? ai::expand_home(raw, ai::system_env()) : raw);
            }
        }
        if (x.addError.empty()) {
            std::string name = std::string(trim(x.addName));
            if (name.empty()) name = x.addKind == 2 ? raw.substr(0, raw.find('@')) : derive_name(path);
            const ai::ExtensionKind kind = x.addKind == 1 ? ai::ExtensionKind::Skill : ai::ExtensionKind::Plugin;
            std::vector<ai::Extension>& list = project ? x.project : x.user;
            // The same name is replaced (re-adding a folder after moving it), another kind may share a name.
            Json entry = Json::object();
            if (x.addKind == 2) entry["plugin"] = raw;
            else entry["path"] = path;
            Json section = Json::object({{kind == ai::ExtensionKind::Skill ? "skills" : "plugins", Json::object({{name, entry}})}});
            auto parsed = ai::parse_extensions(section, "the new entry", project ? "project" : "user");
            if (!parsed) {
                x.addError = parsed.error().to_string();
            } else {
                ai::Extension added = parsed->entries[0];
                const auto same = std::ranges::find_if(list, [&](const ai::Extension& e) { return e.kind == added.kind && e.name == added.name; });
                if (same != list.end()) {
                    added.roles = same->roles;
                    added.note = same->note;
                    *same = added;
                } else {
                    list.push_back(added);
                }
                x.addPath.clear();
                x.addName.clear();
                x.statusAt = -10;
            }
        }
    }
    at_track("aiset:ext:add");
    ImGui::SetItemTooltip("Put it in the list. Save keeps the list.");
    if (!x.addError.empty()) wrapped(kStatusFailed, x.addError);

    if (ImGui::Button(x.showHooks ? "Hide hooks" : "Paste hooks JSON...")) {
        x.showHooks = !x.showHooks;
        x.hooksMessage.clear();
    }
    at_track("aiset:ext:hooks");
    ImGui::SetItemTooltip("Hooks run a program when something happens (before a tool, when the agent stops...). Paste the \"hooks\" of a Claude Code settings.json.");
    if (x.showHooks) {
        ImGui::InputTextMultiline("##hookstext", &x.hooksText, ImVec2(-FLT_MIN, em * 8.0f));
        at_track("aiset:ext:hooks-text");
        ImGui::AlignTextToFramePadding();
        ImGui::TextUnformatted("Name");
        ImGui::SameLine();
        ImGui::SetNextItemWidth(em * 12.0f);
        ImGui::InputTextWithHint("##hooksname", "hooks", &x.hooksName);
        at_track("aiset:ext:hooks-name");
        ImGui::SameLine();
        ImGui::Checkbox("Only for this project##hooksproject", &x.addToProject);
        ImGui::SameLine();
        if (ImGui::Button("Import hooks")) {
            x.hooksFailed = true;
            Json j = Json::parse(x.hooksText, nullptr, false);
            if (j.is_discarded()) {
                x.hooksMessage = "That is not JSON. Paste {\"hooks\": {\"PostToolUse\": [...]}} or the events object itself.";
            } else if (auto hooks = ai::parse_hooks_json(j)) {
                const bool project = x.addToProject && !projectDir_.empty();
                std::vector<ai::Extension>& list = project ? x.project : x.user;
                std::string name = std::string(trim(x.hooksName));
                if (name.empty()) name = "hooks";
                if (const std::string problem = ai::extension_name_problem(name); !problem.empty()) {
                    x.hooksMessage = "The name " + problem;
                } else {
                    ai::Extension e;
                    e.kind = ai::ExtensionKind::Hooks;
                    e.name = name;
                    e.source = project ? "project" : "user";
                    e.hooks = *hooks;
                    const auto same = std::ranges::find_if(list, [&](const ai::Extension& o) { return o.kind == e.kind && o.name == e.name; });
                    if (same != list.end()) {
                        e.roles = same->roles;
                        *same = e;
                    } else {
                        list.push_back(e);
                    }
                    x.hooksMessage = "Imported " + std::to_string(hook_events(*hooks)) + (hook_events(*hooks) == 1 ? " event" : " events") + " as '" + name +
                                     "'. Press Save to keep " + "it.";
                    x.hooksFailed = false;
                    x.hooksText.clear();
                    x.statusAt = -10;
                }
            } else {
                x.hooksMessage = hooks.error().to_string();
            }
        }
        at_track("aiset:ext:hooks-import");
        if (!x.hooksMessage.empty()) wrapped(x.hooksFailed ? kStatusFailed : kStatusReady, x.hooksMessage);
    }

    ImGui::Checkbox("Claude Code also loads my own plugins, skills and hooks", &x.inherit);
    at_track("aiset:ext:inherit");
    ImGui::SetItemTooltip("On (default): what you installed in Claude Code (~/.claude) keeps working in FactorIA's runs, and the list above is added to it.\n"
                          "Off: runs get only the list above, and none of your Claude Code settings (~/.claude: plugins, skills, hooks, permissions, env).");

    // ------------------------------------------------------------------------------------------------ trust
    ImGui::SeparatorText("This project");
    if (projectDir_.empty()) {
        ImGui::TextDisabled("No project is open.");
    } else {
        ImGui::TextDisabled("%s", (projectDir_ + "/" + ai::kProjectExtensionsFile).c_str());
        std::size_t programs = 0;
        for (const ai::Extension& e : x.project) programs += e.runs_program() ? 1 : 0;
        const bool claudeRuns = !x.claudeHash.empty();
        if (!x.projectError.empty()) {
            wrapped(kStatusFailed, "The project's extensions file is ignored: " + x.projectError);
        }
        if (x.projectError.empty() && !x.projectExists && x.project.empty() && !claudeRuns) {
            ImGui::TextDisabled("The project has no extensions file. Use \"Only for this project\" above to make one.");
        } else if (x.projectError.empty() || claudeRuns) {
            if (programs == 0 && !claudeRuns) {
                ImGui::TextDisabled("This project's extensions are skills (text only): nothing to trust.");
            } else if (x.projectTrusted) {
                wrapped(kStatusReady, "You trust this project's plugins, hooks and Claude Code settings (.claude/settings*.json). The trust ends when "
                                      "its extensions file or either settings file changes.");
                if (ImGui::Button("Stop trusting this project")) {
                    if (auto r = ai::forget_project_trust(trustPath, projectDir_); r) {
                        x.projectTrusted = false;
                        x.trustMessage = "No longer trusted.";
                    } else {
                        x.trustMessage = r.error().to_string();
                    }
                    x.statusAt = -10;
                }
                at_track("aiset:ext:untrust");
            } else {
                std::string what;
                if (programs > 0)
                    what = std::to_string(programs) + (programs == 1 ? " plugin or hooks entry" : " plugin or hooks entries") + " in its extensions file";
                if (claudeRuns) what += std::string(what.empty() ? "" : " and ") + "programs, env or allowed tools in its Claude Code settings (.claude/settings*.json)";
                wrapped(kStatusWarn, "This project has " + what + " that run programs or widen what the AI may do. They do not load until you trust the project" +
                                         (claudeRuns ? ": Claude Code starts without the project's .claude settings, so the rest of those files is not applied either." : "."));
                if (ImGui::Button(x.showTrust ? "Hide what would run" : "Review what would run...")) x.showTrust = !x.showTrust;
                at_track("aiset:ext:review");
                if (x.showTrust) {
                    for (const ai::Extension& e : x.project) {
                        if (!e.runs_program()) continue;
                        ImGui::BulletText("%s %s", ai::extension_kind_name(e.kind), e.name.c_str());
                        const std::string detail = e.kind == ai::ExtensionKind::Hooks ? hook_commands(e.hooks) : (!e.plugin.empty() ? e.plugin : e.path);
                        ImGui::Indent();
                        ImGui::TextDisabled("%s", detail.c_str());
                        ImGui::Unindent();
                    }
                    for (const std::string& line : x.claudeGrants) ImGui::BulletText("%s", line.c_str());
                    const bool saved = ai::extensions_to_json({x.project, true}, false) == ai::extensions_to_json({x.projectLoaded, true}, false);
                    const bool canTrust = saved && x.projectError.empty() && (x.projectExists || claudeRuns);
                    ImGui::BeginDisabled(!canTrust);
                    if (ImGui::Button("Trust this project")) {
                        // The user reviewed what this tab read: trust exactly that, not whatever the disk holds now.
                        const bool unchanged = ai::load_project_extensions(projectDir_).hash == x.projectHash &&
                                               ai::load_claude_project_settings(projectDir_).hash == x.claudeHash;
                        if (!unchanged) {
                            x.trustMessage = "A settings file changed on disk since this tab read it. Close AI settings, open them again and review it.";
                        } else if (auto r = ai::trust_project_extensions(trustPath, projectDir_, x.projectHash, x.claudeHash); r) {
                            x.projectTrusted = true;
                            x.showTrust = false;
                            x.trustMessage = "Trusted. The next AI run loads this project's plugins, hooks and Claude Code settings.";
                        } else {
                            x.trustMessage = r.error().to_string();
                        }
                        x.statusAt = -10;
                    }
                    ImGui::EndDisabled();
                    at_track("aiset:ext:trust", canTrust);
                    ImGui::SetItemTooltip("Remembered for this project folder and these exact files (the extensions file and .claude/settings*.json), in %s. If one changes (you, a teammate or the AI edits it) the trust ends.",
                                          trustPath.c_str());
                    if (!saved) ImGui::TextDisabled("Save your changes first: the trust applies to the saved file.");
                }
            }
            if (!x.trustMessage.empty()) ImGui::TextDisabled("%s", x.trustMessage.c_str());
        }
        // Deny rules in the project's Claude Code settings that take FactorIA's own tools away.
        for (const ai::DeniedTool& denied : ai::find_denied_factoria_tools(projectDir_)) wrapped(kStatusWarn, ai::format_denied_tool(denied));
    }
    draw_ai_hooks_view(x.hooksReport);
    ImGui::EndChild();

    // ------------------------------------------------------------------------------------------------ footer
    const auto changed = [&] {
        return ai::extensions_to_json({x.user, x.inherit}, true) != ai::extensions_to_json(cfg.extensions, true) ||
               ai::extensions_to_json({x.project, true}, false) != ai::extensions_to_json({x.projectLoaded, true}, false);
    };
    const bool dirty = changed();
    if (!x.saveError.empty()) {
        wrapped(kStatusFailed, x.saveError);
    } else if (dirty) {
        ImGui::TextColored(kStatusWarn, "Unsaved changes");
    } else {
        ImGui::TextDisabled("Saved. The next message to the AI uses these extensions.");
    }
    ImGui::BeginDisabled(!configReadable);
    if (ImGui::Button("Save")) {
        x.saveError.clear();
        ai::ExtensionsConfig out;
        out.entries = x.user;
        out.inheritUserPlugins = x.inherit;
        auto saved = ai::save_extensions(out, d.path);
        const bool projectChanged = ai::extensions_to_json({x.project, true}, false) != ai::extensions_to_json({x.projectLoaded, true}, false);
        if (saved && !projectDir_.empty() && (projectChanged || x.projectExists) && x.projectError.empty()) {
            if (projectChanged) {
                const ai::ProjectExtensions disk = ai::load_project_extensions(projectDir_);
                const ai::ClaudeProjectSettings claudeNow = ai::load_claude_project_settings(projectDir_);
                const bool wasTrusted = x.projectTrusted && disk.hash == x.projectHash && claudeNow.hash == x.claudeHash &&
                                        ai::project_extensions_trusted(trustPath, projectDir_, disk.hash, nullptr, false, claudeNow.hash);
                saved = ai::save_project_extensions(x.project, projectDir_);
                // The user just edited this file in the editor, with its content on screen: a trust they had given carries over.
                if (saved && wasTrusted) {
                    const ai::ProjectExtensions now = ai::load_project_extensions(projectDir_);
                    if (now.exists) saved = ai::trust_project_extensions(trustPath, projectDir_, now.hash, claudeNow.hash);
                }
            }
        }
        if (!saved) {
            x.saveError = saved.error().to_string();
        } else {
            auto loaded = ai::load_config(d.path);
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                if (loaded) aiConfig_ = *loaded;
                aiConfigError_ = loaded ? std::string() : loaded.error().to_string();
            }
            if (loaded) {
                ai_settings_load(*loaded, true, true);  // the other tabs keep what they had typed
                ai_extensions_load(*loaded);
                notify("Extensions saved. The next message to the AI uses them.");
            } else {
                x.saveError = "Saved, but ai.json no longer loads: " + loaded.error().to_string();
            }
            if (!aiDetecting_.load()) ai_refresh_providers();
        }
    }
    ImGui::EndDisabled();
    at_track("aiset:ext:save", configReadable);
    ImGui::SameLine();
    if (ImGui::Button("Close")) {
        showAiSettings_ = false;
        ai_settings_discard();
    }
    at_track("aiset:ext:close");
}

}  // namespace fa::editor
