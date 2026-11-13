// Autotest sections E3 to F2: the AI settings window, Extensions tab (plugins, hooks, token savers, skills, TokenEconomizer).
// Split from autotest_tools.cpp: each section is an Editor::at_section_<id>(AtScript&) that adds its steps to the script,
// called by at_build_tools_script in the order of the full run (autotest_sections.h).
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <memory>
#include <mutex>

#include "ai_project_edit.h"
#include "auto_play_job.h"
#include "autotest_common.h"
#include "editor_internal.h"
#include "fa/ai/command_hooks.h"
#include "fa/ai/extension_plan.h"
#include "fa/ai/savers.h"
#include "fa/core/date.h"
#include "fa/core/jobs.h"
#include "fa/tooling/feedback_share.h"
#include "fa/tooling/net.h"
#include "fa/tooling/qr.h"
#include "sokol_app.h"
#include "imgui_internal.h"

namespace fa::editor {

using namespace at_support;

namespace {

namespace stdfs = std::filesystem;

}  // namespace

void Editor::at_section_E3(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // The Extensions tab of the AI settings window (docs/EDITOR.md, "AI settings"): a plugin folder added with the form, hooks pasted,
    // a role switched off, Save writing only "extensions" (the other keys of ai.json stay, owner-only); then the project's own
    // file: a skill and hooks kept "only for this project", the hooks not running until Trust this project, and the trust dropped
    // when the file changes.
    {
        // The Skills table above the Add row pushes the form below the fold of the window: scroll to a widget of the body, then click it.
        const auto scroll_click = [&](const std::string& name, float dy = -6) {
            scroll_to(name, "AI settings###AiSettings", dy);
            click(name);
        };
        struct EState {
            std::string path, previousEnv, plugin, skill, projectFileText, claudeFile, claudeBackup;
            bool hadEnv = false, hadClaudeFile = false;
            std::vector<ai::ProviderStatus> savedStatus;
        };
        auto x = std::make_shared<EState>();
        auto set_env = [](const char* name, const std::string& value) {
#ifdef _WIN32
            _putenv_s(name, value.c_str());
#else
            setenv(name, value.c_str(), 1);
#endif
        };
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return aiDetected_.load() && !aiDetecting_.load(); };
        });
        step(2, [this, x, set_env] {
            x->path = atOutDir_ + "/ai_ext_scratch.json";
            x->plugin = atOutDir_ + "/ext_plugin";
            x->skill = projectDir_ + "/skills/autotest_gdd";
            const char* current = std::getenv("FACTORIA_AI_CONFIG");
            x->hadEnv = current != nullptr;
            x->previousEnv = current ? current : "";
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                atSavedConfig_ = aiConfig_;
                x->savedStatus = aiStatus_;
            }
            write_file(x->path, R"({
  "limits": { "maxConcurrentRuns": 3 },
  "roles": { "worker": { "provider": "anthropic", "model": "sonnet" } }
})");
            write_file(x->plugin + "/.claude-plugin/plugin.json", R"({"name":"ext_plugin","version":"1.0.0"})");
            write_file(x->skill + "/SKILL.md",
                       "---\nname: autotest-gdd\ndescription: A skill for the autotest.\n---\nBody.\n");
            std::error_code ec;
            stdfs::remove(projectDir_ + "/.factoria/extensions.json", ec);
            stdfs::remove(ai::extensions_trust_path(x->path), ec);
            // The project's own Claude Code settings run a program: the trust below covers them too.
            x->claudeFile = projectDir_ + "/.claude/settings.local.json";
            x->hadClaudeFile = stdfs::exists(x->claudeFile, ec);
            if (x->hadClaudeFile) x->claudeBackup = read_file(x->claudeFile);
            write_file(x->claudeFile,
                       R"j({"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"echo autotest"}]}]}})j");
            set_env("FACTORIA_AI_CONFIG", x->path);
            ai_refresh_providers();
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(2, [this] { focus_window("AI Assistant"); });
        click("menu:ai");
        click("menu:ai-settings");
        step(4, [this, x] {
            at_check(showAiSettings_ && aiSettings_.loaded && aiSettings_.path == x->path,
                     "AI > AI Settings... opens the window on the scratch file");
            aiSettingsTab_ = 4;  // Extensions
        });
        scroll_to("aiset:ext:hooks", "AI settings###AiSettings");
        step(3, [this] {
            at_check(aiSettings_.ext.user.empty() && aiSettings_.ext.project.empty(), "no extension yet");
            at_check(at_visible("aiset:ext:add") && at_visible("aiset:ext:hooks"),
                     "the Extensions tab shows Add and Paste hooks JSON");
        });
        // A plugin folder.
        step(3, [this, x] { aiSettings_.ext.addPath = x->plugin; });
        scroll_click("aiset:ext:add");
        step(3, [this, x] {
            const auto& u = aiSettings_.ext.user;
            at_check(u.size() == 1 && u[0].kind == ai::ExtensionKind::Plugin && u[0].name == "ext_plugin" &&
                         u[0].source == "user",
                     "Add puts the plugin folder in the list under the folder's name (" + aiSettings_.ext.addError +
                         ")");
            at_check(u.size() == 1 && ai::resolve_extension_path(u[0], "", ai::system_env()) ==
                                          stdfs::path(x->plugin).lexically_normal().string(),
                     "...with a path that leads back to the folder");
            at_check(aiSettings_.ext.addError.empty() && aiSettings_.ext.addPath.empty(),
                     "...and the add row is empty again");
        });
        // A relative path cannot be kept in ai.json: it teaches.
        step(3, [this] {
            aiSettings_.ext.addPath = "plugins/relative";
            aiSettings_.ext.addName = "rel";
        });
        scroll_click("aiset:ext:add");
        step(3, [this] {
            at_check(aiSettings_.ext.user.size() == 1 && aiSettings_.ext.addError.find("~/") != std::string::npos,
                     "a relative path is refused with the way to write it (" + aiSettings_.ext.addError + ")");
            aiSettings_.ext.addPath.clear();
            aiSettings_.ext.addName.clear();
            aiSettings_.ext.addError.clear();
        });
        // Pasted hooks.
        scroll_click("aiset:ext:hooks");
        scroll_to("aiset:ext:hooks-import", "AI settings###AiSettings");
        step(3, [this] {
            at_check(aiSettings_.ext.showHooks && at_visible("aiset:ext:hooks-import"),
                     "Paste hooks JSON opens the paste box");
            aiSettings_.ext.hooksText = R"({"hooks":{"PostToolUsee":[]}})";
        });
        scroll_click("aiset:ext:hooks-import");
        step(3, [this] {
            at_check(aiSettings_.ext.user.size() == 1 &&
                         aiSettings_.ext.hooksMessage.find("PostToolUse") != std::string::npos,
                     "hooks with a misspelled event are refused with the right name (" + aiSettings_.ext.hooksMessage +
                         ")");
            aiSettings_.ext.hooksText =
                R"({"hooks":{"PostToolUse":[{"matcher":"Edit|Write","hooks":[{"type":"command","command":"echo edited"}]}]}})";
            aiSettings_.ext.hooksName = "log";
        });
        scroll_click("aiset:ext:hooks-import");
        step(3, [this] {
            const auto& u = aiSettings_.ext.user;
            at_check(u.size() == 2 && u[1].kind == ai::ExtensionKind::Hooks && u[1].name == "log" &&
                         u[1].hooks.contains("PostToolUse"),
                     "Import hooks adds them (" + aiSettings_.ext.hooksMessage + ")");
        });
        // A role off.
        scroll_click("aiset:ext:role:plugin:ext_plugin:fast");
        step(3, [this] {
            const auto& r = aiSettings_.ext.user[0].roles;
            at_check(r.size() == 4 && std::ranges::find(r, std::string("fast")) == r.end() &&
                         std::ranges::find(r, std::string("worker")) != r.end(),
                     "switching fast off lists the other four default roles");
        });
        scroll_click("aiset:ext:inherit", -2);  // small steps: the page is long and one big step jumps over it
        step(3, [this] { at_check(!aiSettings_.ext.inherit, "the inherit box switches off"); });
        snap("editor_ai_extensions.png");
        click("aiset:ext:save");
        step(6, [this, x] {
            Json j = Json::parse(read_file(x->path), nullptr, false);
            at_check(j.is_object() && aiSettings_.ext.saveError.empty(),
                     "Save wrote a JSON object (" + aiSettings_.ext.saveError + ")");
            if (!j.is_object()) return;
            at_check(j["limits"]["maxConcurrentRuns"] == 3 && j["roles"]["worker"]["model"] == "sonnet",
                     "the other keys of the file stayed");
            const Json& e = j["extensions"];
            at_check(e.is_object() && e.value("inheritUserPlugins", true) == false,
                     "inheritUserPlugins: false is in the file");
            at_check(e.contains("plugins") && e["plugins"].contains("ext_plugin") &&
                         e["plugins"]["ext_plugin"]["roles"].size() == 4,
                     "the plugin is in the file with its roles");
            at_check(e.contains("hooks") &&
                         e["hooks"]["log"]["hooks"]["PostToolUse"][0]["hooks"][0]["command"] == "echo edited",
                     "the hooks are in the file");
#ifndef _WIN32
            std::error_code ec;
            const auto perms = stdfs::status(x->path, ec).permissions();
            at_check((perms & (stdfs::perms::group_all | stdfs::perms::others_all)) == stdfs::perms::none,
                     "the file is readable only by its owner");
#endif
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                at_check(aiConfig_.extensions.entries.size() == 2 && !aiConfig_.extensions.inheritUserPlugins,
                         "the editor's config was reloaded with the extensions");
            }
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        // The project's own file: a skill (text, needs no trust) and hooks (run a program, need it).
        step(3, [this, x] {
            at_check(aiSettings_.ext.saveError.empty() && aiSettings_.ext.user.size() == 2,
                     "the draft was rebuilt from the saved file");
            aiSettings_.ext.addKind = 1;
            aiSettings_.ext.addToProject = true;
            aiSettings_.ext.addPath = x->skill;
        });
        scroll_click("aiset:ext:add");
        step(3, [this] {
            const auto& p = aiSettings_.ext.project;
            at_check(p.size() == 1 && p[0].kind == ai::ExtensionKind::Skill && p[0].path == "skills/autotest_gdd" &&
                         p[0].source == "project",
                     "a skill added \"only for this project\" is kept relative to the project (" +
                         aiSettings_.ext.addError + ")");
            aiSettings_.ext.showHooks = true;
            aiSettings_.ext.hooksText = R"({"Stop":[{"hooks":[{"type":"command","command":"echo project-hook"}]}]})";
            aiSettings_.ext.hooksName = "stop-log";
        });
        scroll_click("aiset:ext:hooks-import");
        step(3, [this] {
            const auto& p = aiSettings_.ext.project;
            at_check(p.size() == 2 && p[1].kind == ai::ExtensionKind::Hooks && p[1].source == "project",
                     "pasted hooks can be kept for the project too");
        });
        click("aiset:ext:save");
        step(6, [this] {
            const ai::ProjectExtensions pe = ai::load_project_extensions(projectDir_);
            at_check(pe.exists && pe.error.empty() && pe.entries.size() == 2,
                     "Save wrote the project's .factoria/extensions.json (" + pe.error + ")");
            at_check(!aiSettings_.ext.projectTrusted, "a project's hooks are not trusted just because they were saved");
            aiSettings_.ext.statusAt = -10;
        });
        step(3, [this] {
            const auto it = aiSettings_.ext.status.find("hooks:project:stop-log");
            at_check(it != aiSettings_.ext.status.end() && it->second.find("not trusted") != std::string::npos,
                     "the hooks of the project show as not trusted");
            const auto skill = aiSettings_.ext.status.find("skill:project:autotest_gdd");
            at_check(skill != aiSettings_.ext.status.end() && skill->second.empty(),
                     "...while the skill (text) is ready");
        });
        scroll_click("aiset:ext:review");
        step(3, [this] {
            at_check(aiSettings_.ext.showTrust && at_visible("aiset:ext:trust"),
                     "Review what would run opens the list and the Trust button");
            at_check(aiSettings_.ext.claudeGrants.size() == 1 &&
                         aiSettings_.ext.claudeGrants[0].find("settings.local.json: hooks (SessionStart)") !=
                             std::string::npos,
                     "...which also lists what the project's .claude/settings.local.json would run");
            const ai::AiConfig cfg = [&] {
                std::lock_guard<std::mutex> lock(aiMu_);
                return aiConfig_;
            }();
            const ai::ExtensionPlan plan =
                ai::plan_extensions(cfg, ai::default_config().providers.at("claude-code"), "worker",
                                    ai::make_extension_context(cfg, projectDir_, ai::system_env()));
            at_check(plan.projectSettingsOff,
                     "until then a Claude Code run starts without the project's .claude settings");
        });
        scroll_to("aiset:ext:trust",
                  "AI settings###AiSettings");  // the list of what would run grew: the button is below the fold
        snap("editor_ai_extensions_trust.png");
        click("aiset:ext:trust");
        step(4, [this, x] {
            const ai::ProjectExtensions pe = ai::load_project_extensions(projectDir_);
            const ai::ClaudeProjectSettings claude = ai::load_claude_project_settings(projectDir_);
            at_check(aiSettings_.ext.projectTrusted && claude.needs_trust() &&
                         ai::project_extensions_trusted(ai::extensions_trust_path(x->path), projectDir_, pe.hash,
                                                        nullptr, false, claude.hash),
                     "Trust this project records the trust for both the extensions file and .claude/settings*.json (" +
                         aiSettings_.ext.trustMessage + ")");
            const ai::AiConfig cfg = [&] {
                std::lock_guard<std::mutex> lock(aiMu_);
                return aiConfig_;
            }();
            ai::ExtensionContext ctx = ai::make_extension_context(cfg, projectDir_, ai::system_env());
            const ai::ExtensionPlan plan =
                ai::plan_extensions(cfg, ai::default_config().providers.at("claude-code"), "worker", ctx);
            at_check(plan.hooks.is_object() && plan.hooks.contains("Stop"),
                     "a Claude Code run for the worker now gets the project's hooks");
            at_check(!plan.projectSettingsOff, "...and loads the project's own .claude settings");
            x->projectFileText = read_file(projectDir_ + "/.factoria/extensions.json");
        });
        // The file changes behind the editor's back (an AI edit): the trust ends.
        step(2, [this, x] {
            Json j = Json::parse(x->projectFileText);
            j["hooks"]["stop-log"]["hooks"]["Stop"][0]["hooks"][0]["command"] = "echo something-else";
            write_file(projectDir_ + "/.factoria/extensions.json", j.dump(2));
            const ai::ProjectExtensions pe = ai::load_project_extensions(projectDir_);
            at_check(!ai::project_extensions_trusted(ai::extensions_trust_path(x->path), projectDir_, pe.hash, nullptr,
                                                     false, ai::load_claude_project_settings(projectDir_).hash),
                     "an edited project file is no longer trusted");
            const ai::AiConfig cfg = [&] {
                std::lock_guard<std::mutex> lock(aiMu_);
                return aiConfig_;
            }();
            const ai::ExtensionPlan plan =
                ai::plan_extensions(cfg, ai::default_config().providers.at("claude-code"), "worker",
                                    ai::make_extension_context(cfg, projectDir_, ai::system_env()));
            at_check(!plan.hooks.is_object() || !plan.hooks.contains("Stop"), "...and a run does not get its hooks");
            at_check(plan.projectSettingsOff, "...nor the project's .claude settings, which the same trust covered");
        });
        // Remove everything, Save.
        step(3, [this] {
            aiSettings_.ext.user.clear();
            aiSettings_.ext.project.clear();
            aiSettings_.ext.inherit = true;
            aiSettings_.ext.projectError.clear();
        });
        click("aiset:ext:save");
        step(6, [this, x] {
            Json j = Json::parse(read_file(x->path), nullptr, false);
            at_check(j.is_object() && !j.contains("extensions") && j["roles"]["worker"]["model"] == "sonnet",
                     "Saving an empty list takes \"extensions\" out of the file and the other keys stay");
            at_check(!ai::load_project_extensions(projectDir_).exists, "...and removes the project's file");
        });
        click("aiset:ext:close");
        step(4, [this] {
            at_check(!showAiSettings_ && !aiSettings_.loaded, "Close closes the window and drops the draft");
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(2, [this, x, set_env] {
            set_env("FACTORIA_AI_CONFIG", x->hadEnv ? x->previousEnv : std::string());
            std::error_code ec;
            stdfs::remove(x->path, ec);
            stdfs::remove(ai::extensions_trust_path(x->path), ec);
            stdfs::remove_all(x->plugin, ec);
            stdfs::remove_all(projectDir_ + "/skills/autotest_gdd", ec);
            if (x->hadClaudeFile)
                write_file(x->claudeFile, x->claudeBackup);
            else {
                stdfs::remove(x->claudeFile, ec);
                stdfs::remove(projectDir_ + "/.claude", ec);  // only when it is empty
            }
            std::lock_guard<std::mutex> lock(aiMu_);
            if (atSavedConfig_) {
                aiConfig_ = std::move(*atSavedConfig_);
                atSavedConfig_.reset();
            }
            aiStatus_ = std::move(x->savedStatus);
        });
    }
}

void Editor::at_section_H2(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // The Hooks section of the Extensions tab (docs/HOOKS.md, docs/EDITOR.md): the saved hooks with where each handler runs, then the
    // recent runs of this editor with the failures marked. The handlers really run (ai::test_hooks, what `ai.hooks_test` calls): a
    // program that answers, one that exits with an error, a JavaScript module that blocks; Clear forgets the list.
    {
        struct HState {
            std::string path, previousEnv, module;
            bool hadEnv = false, hadHooksDir = false;
            std::vector<ai::ProviderStatus> savedStatus;
        };
        auto x = std::make_shared<HState>();
        auto set_env = [](const char* name, const std::string& value) {
#ifdef _WIN32
            _putenv_s(name, value.c_str());
#else
            setenv(name, value.c_str(), 1);
#endif
        };
        auto current_config = [this] {
            std::lock_guard<std::mutex> lock(aiMu_);
            return aiConfig_;
        };
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return aiDetected_.load() && !aiDetecting_.load(); };
        });
        step(2, [this, x, set_env] {
            x->path = atOutDir_ + "/ai_hooks_scratch.json";
            x->module = projectDir_ + "/hooks/autotest_gate.js";
            const char* current = std::getenv("FACTORIA_AI_CONFIG");
            x->hadEnv = current != nullptr;
            x->previousEnv = current ? current : "";
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                atSavedConfig_ = aiConfig_;
                x->savedStatus = aiStatus_;
            }
            std::error_code ec;
            x->hadHooksDir = stdfs::exists(projectDir_ + "/hooks", ec);
            write_file(x->module,
                       "export default {\n  PreToolUse(input) {\n    if (input.tool_name === \"scene_delete\") return "
                       "{ decision: \"block\", reason: \"autotest: no deletes\" };\n  },\n};\n");
            write_file(x->path, R"j({
  "extensions": {
    "hooks": {
      "audit": {
        "hooks": {
          "PostToolUse": [{ "matcher": "scene_*", "hooks": [{ "type": "command", "command": "echo audited" }] }],
          "beforeCommand": [{ "matcher": "scene.spawn", "hooks": [{ "type": "command", "command": "exit 3" }] }],
          "Stop": [{ "hooks": [{ "type": "http", "url": "https://example.invalid/stop" }] }]
        }
      },
      "gate": {
        "hooks": { "PreToolUse": [{ "matcher": "scene_delete", "hooks": [{ "type": "js", "module": "hooks/autotest_gate.js" }] }] }
      }
    }
  }
})j");
            ai::clear_recent_hook_runs();
            set_env("FACTORIA_AI_CONFIG", x->path);
            ai_refresh_providers();
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(2, [this] { focus_window("AI Assistant"); });
        click("menu:ai");
        click("menu:ai-settings");
        step(4, [this, x] {
            at_check(showAiSettings_ && aiSettings_.loaded && aiSettings_.path == x->path,
                     "AI > AI Settings... opens the window on the scratch file");
            aiSettingsTab_ = 4;  // Extensions
            aiSettings_.ext.hooksAt = -10;
        });
        // Nothing has run: the saved hooks are listed, the list of runs is empty.
        step(4, [this] {
            const Json& r = aiSettings_.ext.hooksReport;
            at_check(r.is_object() && r.value("entries", Json::array()).size() == 2,
                     "the saved report lists the two hooks entries");
            at_check(r.value("recentRuns", Json::array()).empty(), "no hook has run yet");
            at_check(at_visible("aiset:ext:hooks-clear") && !at_enabled("aiset:ext:hooks-clear"),
                     "Clear is there and disabled while the list is empty");
        });
        // Three real runs: a program that answers, a program that fails, a JavaScript module that blocks.
        step(3, [this, current_config] {
            const ai::AiConfig cfg = current_config();
            at_check(cfg.extensions.entries.size() == 2,
                     "the editor loaded the two hooks entries from the scratch file");
            const ai::ExtensionContext ctx = ai::make_extension_context(cfg, projectDir_, ai::system_env());
            auto post = ai::test_hooks(cfg, ctx, ai::HookEvent::PostToolUse, "scene_spawn",
                                       Json::object({{"tool_name", "scene_spawn"}, {"tool_input", Json::object()}}),
                                       "orchestrator", nullptr);
            at_check(post && (*post)["outcome"]["runs"].size() == 1 && !(*post)["outcome"]["failed"].get<bool>(),
                     "a PostToolUse program ran and answered");
            auto before = ai::test_hooks(cfg, ctx, ai::HookEvent::BeforeCommand, "scene.spawn",
                                         Json::object({{"command", "scene.spawn"}, {"args", Json::object()}}),
                                         "orchestrator", nullptr);
            at_check(before && (*before)["outcome"]["failed"].get<bool>(),
                     "a beforeCommand program that exits with 3 is a failed run");
            auto gate = ai::test_hooks(cfg, ctx, ai::HookEvent::PreToolUse, "scene_delete",
                                       Json::object({{"tool_name", "scene_delete"}, {"tool_input", Json::object()}}),
                                       "orchestrator", nullptr);
            at_check(gate && (*gate)["outcome"]["blocked"].get<bool>(),
                     "the JavaScript module blocked scene_delete (" +
                         (gate ? (*gate)["outcome"].dump() : gate.error().to_string()) + ")");
            aiSettings_.ext.hooksAt = -10;
        });
        step(4, [this] {
            const Json& r = aiSettings_.ext.hooksReport;
            const Json runs = r.value("recentRuns", Json::array());
            at_check(runs.size() == 3, "the tab reads the three runs (" + std::to_string(runs.size()) + ")");
            int failed = 0, blocked = 0;
            for (const Json& run : runs) {
                failed += run.value("failed", false) ? 1 : 0;
                blocked += run.value("decision", std::string()) == "block" ? 1 : 0;
            }
            at_check(failed == 1 && blocked == 1, "...one failed and one blocked");
            bool httpOnlyClaude = false;
            for (const Json& e : r.value("entries", Json::array()))
                if (e.value("name", std::string()) == "audit")
                    for (const Json& g : e["events"]["Stop"])
                        for (const Json& h : g["handlers"])
                            httpOnlyClaude = h.value("type", std::string()) == "http" && !h.value("runsHere", true);
            at_check(httpOnlyClaude, "an http handler is listed as one FactorIA does not run");
        });
        scroll_to("aiset:ext:hooks-clear", "AI settings###AiSettings");  // the Hooks section is the last of a long page
        step(3, [this] {
            at_check(at_shown("aiset:ext:hooks-clear") && at_enabled("aiset:ext:hooks-clear"),
                     "Clear is shown and enabled once there are runs");
            at_check(at_shown("aiset:ext:hookrun:first"), "the newest run is on screen");
        });
        snap("editor_ai_hooks.png");
        click("aiset:ext:hooks-clear");
        step(4, [this] {
            at_check(ai::recent_hook_runs().empty(), "Clear forgot the runs");
            at_check(aiSettings_.ext.hooksReport.value("recentRuns", Json::array()).empty(),
                     "...and the tab shows none");
        });
        click("aiset:ext:close");
        step(4, [this] {
            at_check(!showAiSettings_ && !aiSettings_.loaded, "Close closes the window and drops the draft");
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(2, [this, x, set_env] {
            set_env("FACTORIA_AI_CONFIG", x->hadEnv ? x->previousEnv : std::string());
            std::error_code ec;
            stdfs::remove(x->path, ec);
            stdfs::remove(x->module, ec);
            if (!x->hadHooksDir) stdfs::remove(projectDir_ + "/hooks", ec);  // only when it is empty
            ai::clear_recent_hook_runs();
            std::lock_guard<std::mutex> lock(aiMu_);
            if (atSavedConfig_) {
                aiConfig_ = std::move(*atSavedConfig_);
                atSavedConfig_.reset();
            }
            aiStatus_ = std::move(x->savedStatus);
        });
    }
}

void Editor::at_section_S2(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // The "Token savers" section of the Extensions tab (docs/AI_PROVIDERS.md, "Token savers"): the switches and the judge saved in
    // ai.json ("savers") without touching its other keys; the proposals a project's runs left in .factoria/ai/savers.json; AGENTS.md
    // and the project's tool groups unchanged until Load up front / Add to AGENTS.md, and a No thanks that changes nothing.
    {
        struct SState {
            std::string path, previousEnv, store, agents, agentsBefore;
            bool hadEnv = false, hadStore = false, hadAgents = false;
            std::string storeBefore;
            std::vector<ai::ProviderStatus> savedStatus;
        };
        auto x = std::make_shared<SState>();
        auto set_env = [](const char* name, const std::string& value) {
#ifdef _WIN32
            _putenv_s(name, value.c_str());
#else
            setenv(name, value.c_str(), 1);
#endif
        };
        const std::string factId = "scene.spawn:not_found";
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return aiDetected_.load() && !aiDetecting_.load(); };
        });
        step(2, [this, x, set_env, factId] {
            x->path = atOutDir_ + "/ai_savers_scratch.json";
            x->store = projectDir_ + "/" + ai::kSaversFile;
            x->agents = projectDir_ + "/AGENTS.md";
            const char* current = std::getenv("FACTORIA_AI_CONFIG");
            x->hadEnv = current != nullptr;
            x->previousEnv = current ? current : "";
            std::error_code ec;
            x->hadStore = stdfs::exists(x->store, ec);
            if (x->hadStore) x->storeBefore = read_file(x->store);
            x->hadAgents = stdfs::exists(x->agents, ec);
            if (x->hadAgents) x->agentsBefore = read_file(x->agents);
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                atSavedConfig_ = aiConfig_;
                x->savedStatus = aiStatus_;
            }
            write_file(x->path, R"({
  "limits": { "maxConcurrentRuns": 3 },
  "roles": { "worker": { "provider": "anthropic", "model": "sonnet" } }
})");
            write_file(x->agents, "# Autotest project\n\nSome notes.\n");
            Json store = Json::object();
            store["version"] = 1;
            store["runs"] = Json::object({{"worker", 3}});
            store["groups"] = Json::object(
                {{"worker",
                  Json::object(
                      {{"scene", Json::object({{"runs", 3}, {"commands", Json::object({{"scene.spawn", 3}})}})},
                       {"assets", Json::object({{"runs", 4}, {"commands", Json::object({{"assets.list", 4}})}})}})}});
            store["facts"] = Json::object(
                {{factId,
                  Json::object({{"command", "scene.spawn"},
                                {"code", "not_found"},
                                {"runs", 3},
                                {"line", "- `scene.spawn` fails with `not_found`; list the prefabs first."}})}});
            write_file(x->store, store.dump(2));
            set_env("FACTORIA_AI_CONFIG", x->path);
            ai_refresh_providers();
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(2, [this] { focus_window("AI Assistant"); });
        click("menu:ai");
        click("menu:ai-settings");
        step(4, [this, x] {
            at_check(showAiSettings_ && aiSettings_.loaded && aiSettings_.path == x->path,
                     "AI > AI Settings... opens the window on the scratch file");
            aiSettingsTab_ = 4;  // Extensions
            aiSettings_.ext.saversAt = -10;
        });
        step(3, [this, factId] {
            const ai::Savers& s = aiSettings_.ext.savers;
            at_check(s.loopGuard && s.learnedToolGroups && s.projectFacts && s.loopGuardJudge.empty(),
                     "the savers start on, without a judge");
            at_check(!s.retrospective && s.retrospectiveSteps == 150 && s.retrospectiveCostUsd == 3.0,
                     "...and the retrospective starts off, after 150 steps or $3");
            const Json& props = aiSettings_.ext.saversReport.value("proposals", Json::object());
            at_check(props.value("toolGroups", Json::array()).size() == 2,
                     "the report lists the two tool group proposals");
            const Json facts = props.value("facts", Json::array());
            at_check(facts.size() == 1 && facts[0].value("id", std::string()) == factId, "...and the one fact");
        });
        // One notch at a time: the Extensions tab's scroll area is about 270 px high on a 1024x642 display and a default 6-notch
        // wheel event moves it further than that, so the switch would skip over the visible part and end above it.
        scroll_to("aiset:saver:loopguard", "AI settings###AiSettings", -1);
        step(3, [this] {
            // (on a small display the window shows the first of them; the clicks below scroll to the others)
            at_check(at_shown("aiset:saver:loopguard") && at_visible("aiset:saver:groups") &&
                         at_visible("aiset:saver:facts") && at_visible("aiset:saver:retrospective"),
                     "the Token savers section is scrolled to the Loop guard switch and draws the other two and the "
                     "Retrospective switch");
        });
        // Switches off, a judge picked.
        click("aiset:saver:loopguard");
        step(3, [this] { at_check(!aiSettings_.ext.savers.loopGuard, "the Loop guard switch turned off"); });
        click("aiset:saver:loopguard");
        click("aiset:saver:judge");
        click("aiset:saver:judge:worker");
        click("aiset:saver:groups");
        click("aiset:saver:facts");
        scroll_to("aiset:saver:retrospective", "AI settings###AiSettings");
        click("aiset:saver:retrospective");
        step(3, [this] {
            const ai::Savers& s = aiSettings_.ext.savers;
            at_check(s.loopGuard && s.loopGuardJudge == "worker" && !s.learnedToolGroups && !s.projectFacts &&
                         s.retrospective,
                     "the judge is worker, learned groups and facts are off, the retrospective is on, the loop guard "
                     "is on again");
        });
        scroll_to("aiset:ext:save", "AI settings###AiSettings");
        click("aiset:ext:save");
        step(4, [this, x] {
            const std::string text = read_file(x->path);
            const Json j = Json::parse(text, nullptr, false);
            at_check(j.is_object() && j.contains("savers") &&
                         j["savers"].value("loopGuardJudge", std::string()) == "worker" &&
                         !j["savers"].value("learnedToolGroups", true) && !j["savers"].value("projectFacts", true) &&
                         j["savers"].value("retrospective", false) && !j["savers"].contains("loopGuard") &&
                         !j["savers"].contains("retrospectiveSteps"),
                     "Save wrote only the non-default savers keys: " + text);
            at_check(j.is_object() && j.contains("limits") && j.contains("roles"),
                     "...and kept the other keys of ai.json");
            aiSettings_.ext.saversAt = -10;
        });
        // Back on, then the answers.
        scroll_to("aiset:saver:groups", "AI settings###AiSettings");
        click("aiset:saver:groups");
        click("aiset:saver:facts");
        step(3, [this] {
            at_check(aiSettings_.ext.savers.learnedToolGroups && aiSettings_.ext.savers.projectFacts,
                     "learned groups and facts turned back on");
        });
        scroll_to("aiset:saver:group-accept:worker:scene", "AI settings###AiSettings");
        step(3, [this, x] {
            at_check(at_shown("aiset:saver:group-accept:worker:scene") &&
                         at_visible("aiset:saver:fact-accept:scene.spawn:not_found"),
                     "the proposals have their buttons");
            at_check(read_file(x->agents) == "# Autotest project\n\nSome notes.\n",
                     "AGENTS.md is untouched while the fact is only proposed");
        });
        snap("editor_ai_savers.png");
        click("aiset:saver:group-accept:worker:scene");
        step(4, [this, x] {
            const Json store = Json::parse(read_file(x->store), nullptr, false);
            at_check(store.is_object() &&
                         store["groups"]["worker"]["scene"].value("status", std::string()) == "accepted",
                     "Load up front stored the accepted group");
            at_check(store["groups"]["worker"]["assets"].value("status", std::string()).empty(),
                     "...and left the other group undecided");
            aiSettings_.ext.saversAt = -10;
        });
        scroll_to("aiset:saver:group-decline:worker:assets", "AI settings###AiSettings");
        click("aiset:saver:group-decline:worker:assets");
        step(4, [this, x] {
            const Json store = Json::parse(read_file(x->store), nullptr, false);
            at_check(store.is_object() &&
                         store["groups"]["worker"]["assets"].value("status", std::string()) == "declined",
                     "No thanks stored the declined group");
            at_check(read_file(x->agents) == "# Autotest project\n\nSome notes.\n", "AGENTS.md is still untouched");
            aiSettings_.ext.saversAt = -10;
        });
        scroll_to("aiset:saver:fact-accept:scene.spawn:not_found", "AI settings###AiSettings");
        click("aiset:saver:fact-accept:scene.spawn:not_found");
        step(4, [this, x] {
            const std::string agents = read_file(x->agents);
            at_check(agents.find("## Project facts") != std::string::npos &&
                         agents.find("`scene.spawn` fails with `not_found`") != std::string::npos,
                     "Add to AGENTS.md wrote the line under the heading");
            at_check(agents.find("Some notes.") != std::string::npos, "...and kept what was there");
            const Json report = aiSettings_.ext.saversReport;
            at_check(report.value("proposals", Json::object()).value("toolGroups", Json::array()).empty() &&
                         report.value("proposals", Json::object()).value("facts", Json::array()).empty(),
                     "nothing is proposed any more");
        });
        click("aiset:ext:close");
        step(4, [this] {
            at_check(!showAiSettings_ && !aiSettings_.loaded, "Close closes the window and drops the draft");
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(2, [this, x, set_env] {
            set_env("FACTORIA_AI_CONFIG", x->hadEnv ? x->previousEnv : std::string());
            std::error_code ec;
            stdfs::remove(x->path, ec);
            if (x->hadStore)
                write_file(x->store, x->storeBefore);
            else
                stdfs::remove(x->store, ec);
            if (x->hadAgents)
                write_file(x->agents, x->agentsBefore);
            else
                stdfs::remove(x->agents, ec);
            std::lock_guard<std::mutex> lock(aiMu_);
            if (atSavedConfig_) {
                aiConfig_ = std::move(*atSavedConfig_);
                atSavedConfig_.reset();
            }
            aiStatus_ = std::move(x->savedStatus);
        });
    }
}

void Editor::at_section_K2(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // The Skills list of the AI settings' Extensions tab (docs/SKILLS.md): FactorIA's own skills, one of the project's, on/off per
    // role kept as skill entries (the engine skill by its "engine:<name>" path), Save writing them to ai.json and to the project's
    // .factoria/extensions.json, and a role then being offered exactly the skills left on for it.
    {
        struct KState {
            std::string path, previousEnv;
            bool hadEnv = false;
            std::vector<ai::ProviderStatus> savedStatus;
        };
        auto x = std::make_shared<KState>();
        auto set_env = [](const char* name, const std::string& value) {
#ifdef _WIN32
            _putenv_s(name, value.c_str());
#else
            setenv(name, value.c_str(), 1);
#endif
        };
        const std::string win = "AI settings###AiSettings";
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return aiDetected_.load() && !aiDetecting_.load(); };
        });
        step(2, [this, x, set_env] {
            x->path = atOutDir_ + "/ai_skills_scratch.json";
            const char* current = std::getenv("FACTORIA_AI_CONFIG");
            x->hadEnv = current != nullptr;
            x->previousEnv = current ? current : "";
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                atSavedConfig_ = aiConfig_;
                x->savedStatus = aiStatus_;
            }
            write_file(x->path, R"({ "limits": { "maxConcurrentRuns": 3 } })");
            write_file(projectDir_ + "/skills/autotest-notes/SKILL.md",
                       "---\nname: autotest-notes\ndescription: Notes for the autotest.\n---\nBody.\n");
            std::error_code ec;
            stdfs::remove(projectDir_ + "/.factoria/extensions.json", ec);
            stdfs::remove(ai::extensions_trust_path(x->path), ec);
            set_env("FACTORIA_AI_CONFIG", x->path);
            ai_refresh_providers();
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(2, [this] { focus_window("AI Assistant"); });
        click("menu:ai");
        click("menu:ai-settings");
        step(4, [this, x] {
            at_check(showAiSettings_ && aiSettings_.loaded && aiSettings_.path == x->path,
                     "AI > AI Settings... opens the window on the scratch file");
            aiSettingsTab_ = 4;  // Extensions
        });
        step(4, [this] {
            const auto find = [&](const char* name) -> const ai::SkillInfo* {
                for (const ai::SkillInfo& s : aiSettings_.ext.skills)
                    if (s.name == name && s.shadowedBy.empty()) return &s;
                return nullptr;
            };
            const ai::SkillInfo* art = find("make-art");
            const ai::SkillInfo* notes = find("autotest-notes");
            at_check(art && art->source == "engine" && art->offered_to("artist") && !art->offered_to("audio"),
                     "the list has FactorIA's own make-art skill, on for the artist and not for the audio role");
            at_check(notes && notes->source == "project" && notes->offered_to("worker"),
                     "...and the project's skills/autotest-notes, on for the worker");
            at_check(find("tile-levels") && find("review-ready") && find("make-audio"),
                     "...with the other engine skills");
            at_check(at_visible("aiset:ext:skill:enabled:tile-levels") ||
                         at_visible("aiset:ext:skill:enabled:make-art"),
                     "the Skills table shows an On box per skill");
        });
        // make-art also for the audio role: an entry "engine:make-art" with the roles listed.
        scroll_to("aiset:ext:skill:role:make-art:audio", win.c_str());
        click("aiset:ext:skill:role:make-art:audio");
        step(3, [this] {
            const auto& u = aiSettings_.ext.user;
            const auto it = std::ranges::find_if(u, [](const ai::Extension& e) {
                return e.kind == ai::ExtensionKind::Skill && e.path == "engine:make-art";
            });
            at_check(it != u.end() && it->roles.size() == 3 &&
                         std::ranges::find(it->roles, std::string("audio")) != it->roles.end() &&
                         std::ranges::find(it->roles, std::string("artist")) != it->roles.end(),
                     "the Audio box of make-art adds the role to an engine:make-art entry that lists the artist, the "
                     "orchestrator and audio");
        });
        // tile-levels off.
        scroll_to("aiset:ext:skill:enabled:tile-levels", win.c_str());
        click("aiset:ext:skill:enabled:tile-levels");
        step(3, [this] {
            const auto& u = aiSettings_.ext.user;
            const auto it =
                std::ranges::find_if(u, [](const ai::Extension& e) { return e.path == "engine:tile-levels"; });
            at_check(it != u.end() && !it->enabled,
                     "the On box of tile-levels switches it off in an engine:tile-levels entry");
        });
        // The project's skill: not for the worker. It is kept in the project's file, relative to the project.
        scroll_to("aiset:ext:skill:role:autotest-notes:worker", win.c_str());
        click("aiset:ext:skill:role:autotest-notes:worker");
        step(3, [this] {
            const auto& p = aiSettings_.ext.project;
            at_check(p.size() == 1 && p[0].kind == ai::ExtensionKind::Skill && p[0].path == "skills/autotest-notes" &&
                         p[0].source == "project" &&
                         std::ranges::find(p[0].roles, std::string("worker")) == p[0].roles.end(),
                     "a project skill switched off for the worker becomes an entry of the project's file, with its "
                     "path relative to the project");
        });
        step(2, [this] { aiSettings_.ext.statusAt = -10; });  // rescan now
        step(3, [this] {
            bool seenOff = false, seenNoWorker = false;
            for (const ai::SkillInfo& s : aiSettings_.ext.skills) {
                if (s.name == "tile-levels" && s.shadowedBy.empty()) seenOff = !s.enabled && !s.offered_to("worker");
                if (s.name == "autotest-notes" && s.shadowedBy.empty())
                    seenNoWorker = !s.offered_to("worker") && s.offered_to("orchestrator");
            }
            at_check(seenOff, "the list shows tile-levels as off");
            at_check(seenNoWorker, "...and autotest-notes as offered to the orchestrator but not the worker");
        });
        snap("editor_ai_skills.png");
        click("aiset:ext:save");
        step(6, [this, x] {
            Json j = Json::parse(read_file(x->path), nullptr, false);
            at_check(j.is_object() && aiSettings_.ext.saveError.empty(),
                     "Save wrote a JSON object (" + aiSettings_.ext.saveError + ")");
            if (!j.is_object()) return;
            at_check(j["limits"]["maxConcurrentRuns"] == 3, "the other keys of the file stayed");
            const Json& skills = j["extensions"]["skills"];
            bool art = false, tiles = false;
            for (const auto& [name, e] : skills.items()) {
                if (e.value("path", "") == "engine:make-art") art = e["roles"].size() == 3;
                if (e.value("path", "") == "engine:tile-levels") tiles = e.value("enabled", true) == false;
            }
            at_check(art && tiles, "ai.json keeps the make-art roles and tile-levels off as skill entries");
            const ai::ProjectExtensions pe = ai::load_project_extensions(projectDir_);
            at_check(pe.exists && pe.error.empty() && pe.entries.size() == 1 &&
                         pe.entries[0].path == "skills/autotest-notes",
                     "the project's .factoria/extensions.json keeps the project skill's roles (" + pe.error + ")");
            const ai::AiConfig cfg = [&] {
                std::lock_guard<std::mutex> lock(aiMu_);
                return aiConfig_;
            }();
            ai::SkillsContext sctx;
            sctx.projectDir = projectDir_;
            const std::vector<ai::SkillInfo> all = ai::scan_skills(cfg, sctx);
            const auto offered = [&](const char* role, const char* name) {
                for (const ai::SkillInfo* s : ai::skills_for_role(all, role))
                    if (s->name == name) return true;
                return false;
            };
            at_check(offered("audio", "make-art") && offered("artist", "make-art"),
                     "a role is now offered make-art: audio and the artist");
            at_check(!offered("worker", "tile-levels") && !offered("orchestrator", "tile-levels"),
                     "...and tile-levels by none");
            at_check(!offered("worker", "autotest-notes") && offered("orchestrator", "autotest-notes"),
                     "...and autotest-notes by the orchestrator, not the worker");
        });
        click("aiset:ext:close");
        step(4, [this] {
            at_check(!showAiSettings_ && !aiSettings_.loaded, "Close closes the window and drops the draft");
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(2, [this, x, set_env] {
            set_env("FACTORIA_AI_CONFIG", x->hadEnv ? x->previousEnv : std::string());
            std::error_code ec;
            stdfs::remove(x->path, ec);
            stdfs::remove(ai::extensions_trust_path(x->path), ec);
            stdfs::remove(projectDir_ + "/.factoria/extensions.json", ec);
            stdfs::remove_all(projectDir_ + "/skills/autotest-notes", ec);
            std::lock_guard<std::mutex> lock(aiMu_);
            if (atSavedConfig_) {
                aiConfig_ = std::move(*atSavedConfig_);
                atSavedConfig_.reset();
            }
            aiStatus_ = std::move(x->savedStatus);
        });
    }
}

void Editor::at_section_F2(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // Add TokenEconomizer in the Extensions tab (docs/AI_PROVIDERS.md, "Installing a plugin"): the tab asks a fake Claude Code CLI what is
    // installed, the button shows what will be installed and runs nothing until Install, the install runs the CLI's plugin commands
    // and adds the entry to ai.json (the other keys stay), Save keeps it, and with the entry removed but the plugin still installed
    // the button offers only the entry. The CLI is a script of the autotest's output folder; the real claude is never run.
    {
        struct FState {
            std::string path, dir, cli, python, previousEnv;
            bool hadEnv = false;
            std::vector<ai::ProviderStatus> savedStatus;
        };
        auto x = std::make_shared<FState>();
        auto set_env = [](const char* name, const std::string& value) {
#ifdef _WIN32
            _putenv_s(name, value.c_str());
#else
            setenv(name, value.c_str(), 1);
#endif
        };
        const auto scroll_click = [&](const std::string& name) {
            scroll_to(name, "AI settings###AiSettings");
            click(name);
        };
        const auto probed = [this] {
            std::lock_guard<std::mutex> lock(aiPluginJob_->mu);
            return aiPluginJob_->probeDone && !aiPluginJob_->running;
        };
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return aiDetected_.load() && !aiDetecting_.load(); };
        });
        step(2, [this, x, set_env] {
            x->dir = atOutDir_ + "/fake_plugin_cli";
            x->path = atOutDir_ + "/ai_eco_scratch.json";
            std::error_code ec;
            stdfs::remove_all(x->dir, ec);
            stdfs::create_directories(x->dir, ec);
            write_file(x->dir + "/marketplaces.json", "[]");
            write_file(x->dir + "/plugins.json", "[]");
#ifdef _WIN32
            std::string d = x->dir;
            std::replace(d.begin(), d.end(), '/', '\\');
            x->cli = x->dir + "/claude.cmd";
            x->python = x->dir + "/python.cmd";
            write_file(x->cli,
                       "@echo off\r\nset \"D=" + d +
                           "\"\r\necho %* >> \"%D%\\argv.log\"\r\n"
                           "if \"%1 %2 %3 %4\"==\"plugin marketplace list --json\" type \"%D%\\marketplaces.json\" & "
                           "exit /b 0\r\n"
                           "if \"%1 %2 %3\"==\"plugin list --json\" type \"%D%\\plugins.json\" & exit /b 0\r\n"
                           "if \"%1 %2 %3\"==\"plugin marketplace add\" echo "
                           "[{\"name\":\"tokeneconomizer\",\"repo\":\"microsoft/TokenEconomizer\"}]> "
                           "\"%D%\\marketplaces.json\" & exit /b 0\r\n"
                           "if \"%1 %2\"==\"plugin install\" echo [{\"id\":\"tokeneconomizer@tokeneconomizer\"}]> "
                           "\"%D%\\plugins.json\" & exit /b 0\r\n"
                           "if \"%1\"==\"--version\" echo 2.1.0 & exit /b 0\r\n"
                           "exit /b 9\r\n");
            write_file(x->python, "@echo off\r\necho Python 3.12.1\r\n");
#else
            x->cli = x->dir + "/claude";
            x->python = x->dir + "/python3";
            write_file(x->cli,
                       "#!/bin/sh\nD='" + x->dir + "'\necho \"$*\" >> \"$D/argv.log\"\ncase \"$*\" in\n"
                       "  \"plugin marketplace list --json\") cat \"$D/marketplaces.json\" ;;\n"
                       "  \"plugin list --json\") cat \"$D/plugins.json\" ;;\n"
                       "  \"plugin marketplace add \"*) echo '[{\"name\":\"tokeneconomizer\",\"repo\":\"microsoft/TokenEconomizer\"}]' > \"$D/marketplaces.json\"; echo added ;;\n"
                       "  \"plugin install \"*) echo '[{\"id\":\"tokeneconomizer@tokeneconomizer\"}]' > \"$D/plugins.json\"; echo installed ;;\n"
                       "  \"--version\") echo '2.1.0 (Claude Code)' ;;\n"
                       "  *) echo \"unexpected: $*\" >&2; exit 9 ;;\nesac\n");
            write_file(x->python, "#!/bin/sh\necho 'Python 3.12.1'\n");
            stdfs::permissions(x->cli, stdfs::perms::owner_all, stdfs::perm_options::add, ec);
            stdfs::permissions(x->python, stdfs::perms::owner_all, stdfs::perm_options::add, ec);
#endif
            const char* current = std::getenv("FACTORIA_AI_CONFIG");
            x->hadEnv = current != nullptr;
            x->previousEnv = current ? current : "";
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                atSavedConfig_ = aiConfig_;
                x->savedStatus = aiStatus_;
            }
            Json cfg = Json::object(
                {{"limits", Json::object({{"maxConcurrentRuns", 3}})},
                 {"roles", Json::object({{"worker", Json::object({{"provider", "anthropic"}, {"model", "sonnet"}})}})},
                 {"providers", Json::object({{"claude-code", Json::object({{"command", x->cli}})}})}});
            write_file(x->path, cfg.dump(2));
            aiPluginProbeInTest_ = true;
            aiPluginPython_ = {x->python};
            aiEconomizerMessage_.clear();
            aiEconomizerConfirm_ = false;
            set_env("FACTORIA_AI_CONFIG", x->path);
            ai_refresh_providers();
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(2, [this] { focus_window("AI Assistant"); });
        click("menu:ai");
        click("menu:ai-settings");
        step(4, [this, x] {
            at_check(showAiSettings_ && aiSettings_.loaded && aiSettings_.path == x->path,
                     "AI > AI Settings... opens the window on the scratch file");
            aiSettingsTab_ = 4;  // Extensions
        });
        step(1, [this, probed] {
            atWaitCount_ = 0;
            atWaitUntil_ = probed;
        });
        scroll_to("aiset:eco:add", "AI settings###AiSettings");
        step(3, [this, x] {
            at_check(at_shown("aiset:eco:add") && !at_visible("aiset:eco:installed"),
                     "the TokenEconomizer section offers Add TokenEconomizer...");
            at_check(read_file(x->dir + "/argv.log").find("marketplace add") == std::string::npos,
                     "the dry run asked the CLI to list only: nothing was added");
        });
        // The confirmation: what will be installed, and nothing has run.
        click("aiset:eco:add");
        scroll_to("aiset:eco:confirm", "AI settings###AiSettings");
        step(3, [this, x] {
            at_check(aiEconomizerConfirm_ && at_shown("aiset:eco:confirm") && at_enabled("aiset:eco:confirm"),
                     "the confirmation shows an Install button (Python 3.12.1 is enough)");
            at_check(at_shown("aiset:eco:cancel"), "...and a Cancel button");
            const std::string log = read_file(x->dir + "/argv.log");
            at_check(log.find("marketplace add") == std::string::npos &&
                         log.find("plugin install") == std::string::npos,
                     "the confirmation ran no install command");
            at_check(read_file(x->path).find("tokeneconomizer") == std::string::npos,
                     "...and wrote nothing to ai.json");
        });
        snap("editor_ai_economizer.png");
        click("aiset:eco:cancel");
        step(3, [this] { at_check(!aiEconomizerConfirm_, "Cancel closes the confirmation"); });
        scroll_click("aiset:eco:add");
        scroll_click("aiset:eco:confirm");
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] {
                std::lock_guard<std::mutex> lock(aiPluginJob_->mu);
                return !aiPluginJob_->running && !aiPluginJob_->finished && !aiEconomizerMessage_.empty();
            };
        });
        step(3, [this, x] {
            const std::string log = read_file(x->dir + "/argv.log");
            const auto add = log.find("plugin marketplace add microsoft/TokenEconomizer");
            const auto install = log.find("plugin install tokeneconomizer@tokeneconomizer");
            at_check(add != std::string::npos && install != std::string::npos && add < install,
                     "Install ran the marketplace add, then the plugin install");
            at_check(aiEconomizerOk_, "the result is a success: " + aiEconomizerMessage_);
            const Json j = Json::parse(read_file(x->path), nullptr, false);
            at_check(j.is_object() && j.contains("extensions") &&
                         j["extensions"]["plugins"]["tokeneconomizer"].value("plugin", std::string()) ==
                             "tokeneconomizer@tokeneconomizer",
                     "ai.json has the plugin entry");
            at_check(j.is_object() && j.contains("limits") && j.contains("roles") && j.contains("providers"),
                     "...and kept its other keys");
            const auto& u = aiSettings_.ext.user;
            at_check(std::ranges::count_if(
                         u, [](const ai::Extension& e) { return e.plugin == "tokeneconomizer@tokeneconomizer"; }) == 1,
                     "the tab's list has the entry once");
        });
        step(1, [this, probed] {
            atWaitCount_ = 0;
            atWaitUntil_ = probed;
        });
        scroll_to("aiset:eco:installed", "AI settings###AiSettings");
        step(3, [this] {
            at_check(at_shown("aiset:eco:installed") && !at_visible("aiset:eco:add"),
                     "the section now reads installed");
        });
        // Save keeps the entry and every other key.
        scroll_click("aiset:ext:save");
        step(4, [this, x] {
            const Json j = Json::parse(read_file(x->path), nullptr, false);
            at_check(j.is_object() && j.contains("limits") && j.contains("roles") && j.contains("providers") &&
                         j["extensions"]["plugins"].size() == 1 &&
                         j["extensions"]["plugins"].contains("tokeneconomizer"),
                     "Save kept the entry (once) and the other keys of ai.json");
        });
        // The entry removed, the plugin still installed: only the entry is offered.
        scroll_click("aiset:ext:remove:plugin:tokeneconomizer");
        scroll_click("aiset:ext:save");
        step(1, [this, probed] {
            atWaitCount_ = 0;
            atWaitUntil_ = probed;
        });
        step(3, [this, x] {
            const Json j = Json::parse(read_file(x->path), nullptr, false);
            at_check(j.is_object() && !j.contains("extensions"), "Remove and Save took the entry out of ai.json");
        });
        scroll_to("aiset:eco:entry", "AI settings###AiSettings");
        step(3, [this] {
            at_check(at_shown("aiset:eco:entry") && !at_visible("aiset:eco:add"),
                     "the section offers only the entry, since the plugin is installed");
        });
        click("aiset:eco:entry");
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] {
                std::lock_guard<std::mutex> lock(aiPluginJob_->mu);
                return !aiPluginJob_->running && !aiPluginJob_->finished && aiPluginJob_->probeDone;
            };
        });
        step(3, [this, x] {
            const std::string log = read_file(x->dir + "/argv.log");
            const auto first = log.find("plugin install ");
            at_check(first != std::string::npos && log.find("plugin install ", first + 1) == std::string::npos,
                     "adding only the entry did not install the plugin again");
            const Json j = Json::parse(read_file(x->path), nullptr, false);
            at_check(j.is_object() && j.contains("extensions") &&
                         j["extensions"]["plugins"].contains("tokeneconomizer"),
                     "ai.json has the entry again");
        });
        click("aiset:ext:close");
        step(4, [this] {
            at_check(!showAiSettings_ && !aiSettings_.loaded, "Close closes the window and drops the draft");
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(2, [this, x, set_env] {
            set_env("FACTORIA_AI_CONFIG", x->hadEnv ? x->previousEnv : std::string());
            aiPluginProbeInTest_ = false;
            aiPluginPython_.clear();
            aiEconomizerMessage_.clear();
            std::error_code ec;
            stdfs::remove(x->path, ec);
            stdfs::remove_all(x->dir, ec);
            std::lock_guard<std::mutex> lock(aiMu_);
            if (atSavedConfig_) {
                aiConfig_ = std::move(*atSavedConfig_);
                atSavedConfig_.reset();
            }
            aiStatus_ = std::move(x->savedStatus);
        });
    }
}

}  // namespace fa::editor
