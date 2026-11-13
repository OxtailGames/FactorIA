// Autotest sections X, Q2 and D2: the AI settings window (asset providers, per-project files, External tools).
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

void Editor::at_section_X(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // ------------------------------------------------------------------------------------------------ X. AI settings window
    // AI > AI Settings... opens the window on the user's ai.json (here a scratch file: FACTORIA_AI_CONFIG
    // is set for the section and put back after). What a person types in the fields is set on the draft; Save and Close are
    // real clicks. A site that is not a web address stops Save with a message and leaves the file as it was; a good Save
    // rewrites only assets / assetSources / the provider fields the routes need (roles and limits stay), stores a typed key in
    // a file only the user can read and forgets it, and a stored key can be removed again. The fixture is an open project, so the
    // test presses Save as my defaults (what Save does without a project; section Q2 covers the project's own Save).
    {
        struct XState {
            std::string path, previousEnv;
            bool hadEnv = false;
            std::vector<ai::ProviderStatus> savedStatus;
            std::string before;
        };
        auto x = std::make_shared<XState>();
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
            x->path = atOutDir_ + "/ai_settings_scratch.json";
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
  "roles": { "worker": { "provider": "anthropic", "model": "sonnet" } },
  "assets": { "image": { "provider": "fake" } }
})");
            set_env("FACTORIA_AI_CONFIG", x->path);
            ai_refresh_providers();  // the panel and the window now read the scratch file
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(2, [this] { focus_window("AI Assistant"); });
        click("menu:ai");
        click("menu:ai-settings");
        step(4, [this, x] {
            at_check(showAiSettings_, "AI > AI Settings... opens the window");
            aiSettingsTab_ = 2;  // the Assets tab: the rest of this section works there
            at_check(aiSettings_.loaded && aiSettings_.path == x->path, "it works on the AI config file (" + aiSettings_.path + ")");
            at_check(aiSettings_.routes["image"].provider == "fake" && aiSettings_.routes["sound"].provider.empty(),
                     "the image row shows the provider of the file and the sound row none");
            at_check(!aiSettings_.sources.onlyListed && aiSettings_.sources.empty(), "no site yet: 'Use only these sites' is off");
            at_check(std::ranges::any_of(aiSettings_.status, [](const ai::ProviderStatus& s) { return s.name == "elevenlabs"; }),
                     "it knows the status of the providers (keys and programs found on this computer)");
            x->before = read_file(x->path);
        });
        // A site that is not a web address, a key and a program typed.
        step(2, [this] {
            AiSettingsDraft& d = aiSettings_;
            d.routes["sound"] = {"elevenlabs", "", ""};
            d.routes["music"] = {"elevenlabs", "", ""};
            d.routes["voice"] = {"elevenlabs", "", "21m00Tcm4TlvDq8ikWAM"};
            d.routes["model3d"] = {"asset-command", "", ""};
            d.command["asset-command"] = "python";
            d.args["asset-command"] = "/tools/gen3d.py --prompt {prompt} --out \"{output}\"";
            d.keys["elevenlabs"] = "xi-autotest-secret-key-123";
            d.sources.onlyListed = true;
            d.sources.images.push_back({"https://opengameart.org/art-search", "CC0 packs"});
            d.sources.models.push_back({"kenney.nl", ""});
            d.sources.fonts.push_back({"not a site", ""});
        });
        snap("editor_ai_settings.png");
        click("aiset:save-defaults");  // a project is open: Save would write the project's file, this one ai.json
        step(4, [this, x] {
            at_check(aiSettings_.saveError.find("not a web address") != std::string::npos,
                     "a site that is not a web address stops Save and says so (" + aiSettings_.saveError + ")");
            at_check(read_file(x->path) == x->before, "...and the file is left as it was");
            at_check(showAiSettings_ && !aiSettings_.keys.empty(), "...with the window and the typed values still there");
            aiSettings_.sources.fonts.clear();
        });
        click("aiset:save-defaults");  // a project is open: Save would write the project's file, this one ai.json
        step(6, [this, x] {
            const std::string text = read_file(x->path);
            Json j = Json::parse(text, nullptr, false);
            at_check(!j.is_discarded() && j.is_object(), "Save wrote a JSON object");
            if (!j.is_object()) return;
            at_check(aiSettings_.saveError.empty(), "Save reported no error (" + aiSettings_.saveError + ")");
            at_check(j["limits"]["maxConcurrentRuns"] == 3 && j["roles"]["worker"]["model"] == "sonnet",
                     "the roles and limits of the file stayed");
            at_check(j["assets"]["image"]["provider"] == "fake" && j["assets"]["sound"]["provider"] == "elevenlabs" &&
                         j["assets"]["voice"]["voice"] == "21m00Tcm4TlvDq8ikWAM" && j["assets"]["model3d"]["provider"] == "asset-command",
                     "the asset routes are in the file");
            at_check(j["assetSources"]["onlyListed"] == true && j["assetSources"]["images"][0]["url"] == "https://opengameart.org/art-search" &&
                         j["assetSources"]["images"][0]["note"] == "CC0 packs" && j["assetSources"]["models"][0]["url"] == "kenney.nl",
                     "the sites and 'Use only these sites' are in the file");
            at_check(j["providers"]["elevenlabs"]["apiKey"] == "xi-autotest-secret-key-123", "the typed key is stored under its provider");
            at_check(j["providers"]["asset-command"]["type"] == "asset-command" && j["providers"]["asset-command"]["command"] == "python" &&
                         j["providers"]["asset-command"]["argv"].size() == 5 && j["providers"]["asset-command"]["argv"][4] == "{output}",
                     "the program of the asset-command provider is stored with its arguments split");
#ifndef _WIN32
            std::error_code ec;
            const auto perms = stdfs::status(x->path, ec).permissions();
            at_check((perms & (stdfs::perms::group_all | stdfs::perms::others_all)) == stdfs::perms::none,
                     "the file with a key in it is readable only by its owner");
#endif
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                at_check(aiConfig_.assetSources.onlyListed && aiConfig_.assets.count("voice") && aiConfig_.assets.at("music").provider == "elevenlabs",
                         "the editor's config was reloaded with the new settings");
            }
            at_check(std::ranges::all_of(aiSettings_.keys, [](const auto& kv) { return kv.second.empty(); }), "the typed key is forgotten after Save");
            at_check(std::ranges::none_of(atLog_, [](const std::string& line) { return line.find("xi-autotest-secret-key-123") != std::string::npos; }),
                     "the key is in no line of the autotest log");
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        snap("editor_ai_settings_saved.png");
        // Remove the stored key, and a kind back to None.
        step(2, [this] {
            aiSettings_.removeKey.insert("elevenlabs");
            aiSettings_.routes["music"] = {};
        });
        click("aiset:save-defaults");  // a project is open: Save would write the project's file, this one ai.json
        step(6, [this, x] {
            Json j = Json::parse(read_file(x->path), nullptr, false);
            at_check(j.is_object() && (!j.contains("providers") || !j["providers"].contains("elevenlabs")),
                     "Remove stored key takes the key out of the file");
            at_check(j.is_object() && j.contains("assets") && !j["assets"].contains("music") && j["assets"].contains("sound") &&
                         j.contains("assetSources") && j["assetSources"].contains("images"), "a kind set to None leaves the file");
            at_check(j.is_object() && j["roles"]["worker"]["model"] == "sonnet", "the roles stayed again");
        });
        click("aiset:close");
        step(4, [this] {
            at_check(!showAiSettings_, "Close closes the window");
            at_check(aiSettings_.keys.empty() && !aiSettings_.loaded, "...and drops what was typed in it");
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(2, [this, x, set_env] {
            set_env("FACTORIA_AI_CONFIG", x->hadEnv ? x->previousEnv : std::string());
            std::error_code ec;
            stdfs::remove(x->path, ec);
            std::lock_guard<std::mutex> lock(aiMu_);
            if (atSavedConfig_) {
                aiConfig_ = std::move(*atSavedConfig_);
                atSavedConfig_.reset();
            }
            aiStatus_ = std::move(x->savedStatus);
        });
    }
}

void Editor::at_section_Q2(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // ------------------------------------------------------------------------------------------ Q2. AI settings per project
    // The AI settings window edits the open project's <project>/.factoria/ai/settings.json (docs/EDITOR.md, "AI settings"). Two
    // projects with different worker models: a file that came with a project waits for Accept (Ignore leaves it off, Save is locked
    // until then), then applies; switching project shows the other project's roles and the AI runs use them; Reset puts one row back
    // on the user's value; Save as my defaults writes ai.json and leaves the project's file with what still differs; an invalid
    // file shows its error and no Accept. ai.json is a scratch file (FACTORIA_AI_CONFIG, put back at the end).
    {
        struct Q2State {
            std::string root, userPath, dirA, dirB, fixtureDir, previousEnv, cameWith, nameA = "Q2 Project A", nameB = "Q2 Project B";
            bool hadEnv = false;
            std::vector<ai::ProviderStatus> savedStatus;
            std::unique_ptr<AiRun> run;  // the run whose proxy registry the ai.settings.set checks call
        };
        auto st = std::make_shared<Q2State>();
        auto set_env = [](const char* name, const std::string& value) {
#ifdef _WIN32
            _putenv_s(name, value.c_str());
#else
            setenv(name, value.c_str(), 1);
#endif
        };
        // The model an AI run of the open project would give a role: the config its loader reads (ai_project_config(true)).
        auto run_model = [this](const char* role) {
            auto c = ai_project_config(true);
            return c ? c->role(role).model : "(no config: " + c.error().message + ")";
        };
        auto reopen = [this](const std::string& name) {
            const std::uint64_t u0 = uiFrame_;
            atWaitCount_ = 0;
            atWaitUntil_ = [this, u0, name] {
                return engine_ && pendingOpen_.empty() && !pendingWelcome_ && atReopenIn_ == 0 && projectName_ == name && uiFrame_ >= u0 + 8;
            };
        };
        // The window shows the draft of the open project, with its resolution read.
        auto window_ready = [this](const std::string& name) {
            atWaitCount_ = 0;
            atWaitUntil_ = [this, name] {
                return showAiSettings_ && aiSettings_.loaded && aiSettings_.project == projectDir_ && projectName_ == name && aiProj_.have &&
                       aiProj_.dir == projectDir_ && !aiRolesOpen_ && aiDetected_.load() && !aiDetecting_.load();
            };
        };
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return aiDetected_.load() && !aiDetecting_.load(); };
        });
        step(2, [this, st, set_env] {
            std::error_code ec;
            st->root = atOutDir_ + "/q2";
            stdfs::remove_all(st->root, ec);
            stdfs::create_directories(st->root, ec);
            st->userPath = st->root + "/ai.json";
            st->fixtureDir = projectDir_;
            const char* current = std::getenv("FACTORIA_AI_CONFIG");
            st->hadEnv = current != nullptr;
            st->previousEnv = current ? current : "";
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                atSavedConfig_ = aiConfig_;
                st->savedStatus = aiStatus_;
            }
            write_file(st->userPath, R"({ "roles": { "worker": { "provider": "anthropic", "model": "sonnet" } } })");
            set_env("FACTORIA_AI_CONFIG", st->userPath);  // ai-trust.json is written next to it, never in the real ~/.factoria
            for (const auto& [dirKey, name] : {std::pair{&st->dirA, st->nameA}, std::pair{&st->dirB, st->nameB}}) {
                ScaffoldOptions so;
                so.name = name;
                const std::string where = st->root + (dirKey == &st->dirA ? "/project-a" : "/project-b");
                auto made = create_project(where, "2d-empty", so);
                at_check(bool(made), "a scratch project was created for " + name + (made ? "" : ": " + made.error().message));
                if (made) *dirKey = made->dir;
            }
            // A came with its own file (a copied project: nobody accepted it here); B's was saved on this computer through the editor.
            stdfs::create_directories(stdfs::path(st->dirA) / ".factoria" / "ai", ec);
            write_file(st->dirA + "/.factoria/ai/settings.json", R"({ "roles": { "worker": { "model": "a-worker-model" } } })");
            auto saved = ai::save_project_settings(st->dirB, Json::parse(R"({ "roles": { "worker": { "model": "b-worker-model" } } })"), st->userPath,
                                                   ai::system_env(), true);
            at_check(bool(saved), "B's file was saved with the trust recorded" + (saved ? std::string() : ": " + saved.error().message));
            ai_refresh_providers();  // the editor now reads the scratch ai.json
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(2, [this, st, reopen] {
            open_project(st->dirA);
            reopen(st->nameA);
        });
        step(2, [this] { open_ai_settings(true); });  // the Roles tab
        step(1, [window_ready, st] { window_ready(st->nameA); });
        step(4, [this, st, run_model] {
            at_check(aiSettings_.title == "AI settings - This project: " + st->nameA, "the title says which project this is (" + aiSettings_.title + ")");
            at_check(aiProj_.resolved.fileExists && aiProj_.resolved.pendingTrust && !aiProj_.resolved.invalidError,
                     "a file that came with the project waits for Accept");
            at_check(std::ranges::any_of(aiProj_.resolved.pending, [](const ai::SettingChange& c) { return c.pointer == "/roles/worker/model"; }),
                     "...and the pending list says it would change the worker's model");
            at_check(at_visible("aiset:project:accept") && at_visible("aiset:project:ignore"), "...with Accept and Ignore");
            at_check(run_model("worker") == "sonnet" && aiRolesEdit_["worker"].model == "sonnet",
                     "until it is accepted the project runs, and the window shows, the user's worker model (" + run_model("worker") + ")");
            at_check(at_visible("ai:roles:save") && !at_enabled("ai:roles:save"), "Save is locked while the file waits");
        });
        snap("editor_ai_project_pending.png");
        click("aiset:project:ignore");
        step(4, [this, run_model] {
            at_check(at_visible("aiset:project:review") && !at_visible("aiset:project:accept"), "Ignore hides the list and offers Review it");
            at_check(at_enabled("ai:roles:save") && run_model("worker") == "sonnet", "...Save works again and the file still has no effect");
        });
        click("aiset:project:review");
        step(4, [this] { at_check(at_visible("aiset:project:accept"), "Review it brings the list and Accept back"); });
        click("aiset:project:accept");
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return aiProj_.have && !aiProj_.resolved.pendingTrust && !aiRolesOpen_; };
        });
        step(4, [this, st, run_model] {
            at_check(aiProj_.resolved.applied && ai_group_source(aiProj_.resolved, "/roles/worker") == ai::SettingSource::Project,
                     "Accept applies the file: the worker row comes from this project");
            at_check(run_model("worker") == "a-worker-model", "...and the next AI run uses the project's worker model (" + run_model("worker") + ")");
            at_check(aiRolesEdit_["worker"].model == "a-worker-model", "...and the Roles tab shows it");
            at_check(at_visible("ai:roles:reset:worker") && !at_visible("ai:roles:reset:orchestrator"), "only the row the project sets has Reset");
            at_check(stdfs::exists(st->root + "/ai-trust.json"), "the acceptance is in ai-trust.json next to the scratch ai.json");
        });
        snap("editor_ai_project_applied.png");
        // Switching project: B's roles, then A's again, without closing the window.
        step(2, [this, st, reopen] {
            open_project(st->dirB);
            reopen(st->nameB);
        });
        step(1, [window_ready, st] { window_ready(st->nameB); });
        step(4, [this, st, run_model] {
            at_check(showAiSettings_ && aiSettings_.title == "AI settings - This project: " + st->nameB, "switching project retitles the open window (" + aiSettings_.title + ")");
            at_check(aiRolesEdit_["worker"].model == "b-worker-model", "...and shows the other project's worker model (" + aiRolesEdit_["worker"].model + ")");
            at_check(run_model("worker") == "b-worker-model", "...and the next AI run uses it (" + run_model("worker") + ")");
            at_check(aiProj_.resolved.applied && !aiProj_.resolved.pendingTrust, "a file saved here needs no Accept");
        });
        step(2, [this, st, reopen] {
            open_project(st->dirA);
            reopen(st->nameA);
        });
        step(1, [window_ready, st] { window_ready(st->nameA); });
        step(4, [this, run_model] {
            at_check(aiRolesEdit_["worker"].model == "a-worker-model" && run_model("worker") == "a-worker-model",
                     "back in the first project: its roles again (" + run_model("worker") + ")");
        });
        // Reset of one row.
        click("ai:roles:reset:worker");
        step(4, [this, st, run_model] {
            at_check(aiRolesEdit_["worker"].model == "sonnet", "Reset puts the worker row back on the user's value");
            at_check(run_model("worker") == "sonnet", "...and the next AI run uses it (" + run_model("worker") + ")");
            at_check(!at_visible("ai:roles:reset:worker") && ai_group_source(aiProj_.resolved, "/roles/worker") == ai::SettingSource::You,
                     "...the row says it comes from the user's defaults");
            const Json file = Json::parse(read_file(st->dirA + "/.factoria/ai/settings.json"), nullptr, false);
            at_check(json_at(file, "/roles/worker").is_null(),
                     "...and the project's file no longer says anything about the worker");
        });
        // Save as my defaults (in B, which sets the worker): ai.json gets the values, B's file keeps nothing that equals them.
        step(2, [this, st, reopen] {
            open_project(st->dirB);
            reopen(st->nameB);
        });
        step(1, [window_ready, st] { window_ready(st->nameB); });
        step(2, [this] { aiRolesEdit_["orchestrator"].model = "defaults-orchestrator"; });
        click("ai:roles:save-defaults");
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiRolesOpen_ && aiProj_.have; };
        });
        step(4, [this, st, run_model] {
            const Json user = Json::parse(read_file(st->userPath), nullptr, false);
            at_check(json_at(user, "/roles/orchestrator/model") == "defaults-orchestrator" &&
                         json_at(user, "/roles/worker/model") == "b-worker-model",
                     "Save as my defaults writes the roles into the user's ai.json");
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                at_check(aiConfig_.role("orchestrator").model == "defaults-orchestrator", "...and the editor's copy of ai.json is reloaded");
            }
            at_check(run_model("orchestrator") == "defaults-orchestrator" && run_model("worker") == "b-worker-model",
                     "...the project still runs with the same roles");
            at_check(ai_group_source(aiProj_.resolved, "/roles/worker") == ai::SettingSource::You,
                     "...and its rows now say Your defaults: its file keeps nothing that equals them");
            at_check(!aiProj_.resolved.pendingTrust, "...and its file needs no new Accept");
        });
        // A project that is not B any more is in step with the new defaults too.
        step(2, [this, st, reopen] {
            open_project(st->dirA);
            reopen(st->nameA);
        });
        step(1, [window_ready, st] { window_ready(st->nameA); });
        step(4, [this, run_model] {
            at_check(run_model("worker") == "b-worker-model" && aiRolesEdit_["worker"].model == "b-worker-model",
                     "a project without its own worker model starts from the new defaults (" + run_model("worker") + ")");
        });
        // A project's own Save writes its file only.
        step(2, [this] { aiRolesEdit_["worker"].model = "a-saved-model"; });
        click("ai:roles:save");
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiRolesOpen_ && aiProj_.have; };
        });
        step(4, [this, st, run_model] {
            const Json file = Json::parse(read_file(st->dirA + "/.factoria/ai/settings.json"), nullptr, false);
            at_check(json_at(file, "/roles/worker/model") == "a-saved-model" && json_at(file, "/roles/orchestrator").is_null(),
                     "Save writes the project's file with only what differs from the defaults");
            const Json user = Json::parse(read_file(st->userPath), nullptr, false);
            at_check(json_at(user, "/roles/worker/model") == "b-worker-model", "...and leaves ai.json alone");
            at_check(run_model("worker") == "a-saved-model" && !aiProj_.resolved.pendingTrust, "...the next run uses it, with no Accept asked for the user's own Save");
        });
        // The Assets tab: a route and a site saved in the project's file only, each row with its own Reset.
        step(2, [this] {
            aiSettingsTab_ = 2;
            atWaitCount_ = 0;
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return at_visible("aiset:provider:image") && at_visible("aiset:save"); };
        });
        step(2, [this] {
            aiSettings_.routes["image"] = {"openai", "", ""};
            aiSettings_.sources.images.push_back({"opengameart.org", "CC0"});
            at_check(at_visible("aiset:save") && at_enabled("aiset:save") && at_visible("aiset:save-defaults"), "the Assets tab has Save and Save as my defaults");
        });
        click("aiset:save");
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return aiProj_.have && ai_group_source(aiProj_.resolved, "/assets/image") == ai::SettingSource::Project; };
        });
        step(4, [this, st] {
            const Json file = Json::parse(read_file(st->dirA + "/.factoria/ai/settings.json"), nullptr, false);
            at_check(json_at(file, "/assets/image/provider") == "openai" && json_at(file, "/assetSources/images").size() == 1,
                     "Save in the Assets tab writes the route and the site into the project's file");
            const Json user = Json::parse(read_file(st->userPath), nullptr, false);
            at_check(user.is_object() && !user.contains("assets") && !user.contains("assetSources"), "...and not into ai.json");
            auto run = ai_project_config(true);
            at_check(run && run->assets.count("image") && run->assets.at("image").provider == "openai" && run->assetSources.images.size() == 1,
                     "...the next AI run uses them");
            at_check(at_visible("aiset:reset:image"), "...and the image row says it is the project's, with Reset");
        });
        click("aiset:reset:image");
        step(4, [this, st] {
            at_check(aiSettings_.routes["image"].provider.empty() && !aiSettings_.sources.images.empty(),
                     "Reset on the image row clears only that row (the site stays in the draft)");
            const Json file = Json::parse(read_file(st->dirA + "/.factoria/ai/settings.json"), nullptr, false);
            at_check(file.is_object() && json_at(file, "/assets/image").is_null() && file.contains("assetSources"),
                     "...and the project's file keeps the sites");
        });
        scroll_to("aiset:reset:images", "AI settings###AiSettings");
        click("aiset:reset:images");
        step(4, [this, st] {
            at_check(aiSettings_.sources.images.empty(), "Reset on a list of sites puts it back to the user's (empty)");
            auto run = ai_project_config(true);
            at_check(run && run->assetSources.images.empty() && !run->assets.count("image"), "...and the next AI run has neither the route nor the site");
        });
        // A file that cannot be accepted: its error, no Accept.
        step(2, [this, st] {
            write_file(st->dirA + "/.factoria/ai/settings.json", R"({ "roles": { "worker": { "command": "evil" } } })");
            ai_project_invalidate();
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return aiProj_.have && aiProj_.resolved.invalidError.has_value(); };
        });
        step(4, [this, run_model] {
            at_check(aiProj_.resolved.pendingTrust && aiProj_.resolved.invalidError.has_value() && !aiProj_.resolved.invalidError->message.empty(),
                     "a changed file that is not valid shows its error");
            at_check(!at_visible("aiset:project:accept") && at_visible("aiset:project:ignore") && at_visible("aiset:project:delete"),
                     "...with no Accept, and a way to ignore or delete it");
            at_check(run_model("worker") == "b-worker-model", "...and it changes nothing the project runs with (" + run_model("worker") + ")");
        });
        snap("editor_ai_project_invalid.png");
        // Delete the file: it asks first (Cancel keeps the file), and Delete removes it and forgets that it was accepted.
        step(2, [this, st] {
            const Json trust = Json::parse(read_file(st->root + "/ai-trust.json"), nullptr, false);
            at_check(json_at(trust, "/aiSettings").contains(ai::ai_settings_trust_key(st->dirA)),
                     "(before Delete) the project's file was accepted here once: ai-trust.json has its record");
            aiSettingsTab_ = 1;  // the Roles tab again: the Save of the next flow lives there
        });
        click("aiset:project:delete");
        step(4, [this, st] {
            at_check(at_visible("aiset:project:delete-ok") && at_visible("aiset:project:delete-cancel"),
                     "Delete the file asks for a confirmation (the popup is on screen)");
            at_check(stdfs::exists(st->dirA + "/.factoria/ai/settings.json"), "...and nothing was deleted yet");
        });
        snap("editor_ai_project_delete_confirm.png");
        click("aiset:project:delete-cancel");
        step(4, [this, st] {
            at_check(!at_visible("aiset:project:delete-ok") && stdfs::exists(st->dirA + "/.factoria/ai/settings.json"),
                     "Cancel closes the popup and keeps the file");
        });
        click("aiset:project:delete");
        step(4, [this] { at_check(at_visible("aiset:project:delete-ok"), "Delete the file opens the confirmation again"); });
        click("aiset:project:delete-ok");
        step(1, [this, st] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this, st] {
                return !stdfs::exists(st->dirA + "/.factoria/ai/settings.json") && aiProj_.have && !aiProj_.resolved.fileExists;
            };
        });
        step(4, [this, st, run_model] {
            const Json trust = Json::parse(read_file(st->root + "/ai-trust.json"), nullptr, false);
            at_check(!json_at(trust, "/aiSettings").contains(ai::ai_settings_trust_key(st->dirA)),
                     "Delete removes the file and forgets its acceptance in ai-trust.json");
            at_check(run_model("worker") == "b-worker-model" && aiProj_.actionError.empty(), "...the project runs with the user's defaults, no error");
        });
        // Save after Ignore replaces a file that came with the project: it asks, and keeps a copy of that file.
        step(2, [this, st] {
            st->cameWith = R"({ "roles": { "worker": { "model": "came-with-project" } } })";
            write_file(st->dirA + "/.factoria/ai/settings.json", st->cameWith);
            ai_project_invalidate();
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] {
                return aiProj_.have && aiProj_.resolved.pendingTrust && !aiProj_.resolved.invalidError && at_visible("aiset:project:ignore") &&
                       !aiRolesOpen_;
            };
        });
        click("aiset:project:ignore");
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return at_visible("aiset:project:review") && at_enabled("ai:roles:save"); };
        });
        step(2, [this] { aiRolesEdit_["worker"].model = "my-own-model"; });
        click("ai:roles:save");
        step(4, [this, st] {
            at_check(at_visible("aiset:project:replace-ok") && at_visible("aiset:project:replace-cancel"),
                     "Save after Ignore asks before it replaces the file that came with the project");
            at_check(read_file(st->dirA + "/.factoria/ai/settings.json") == st->cameWith && !stdfs::exists(st->dirA + "/.factoria/ai/settings.replaced.json"),
                     "...and nothing was written yet");
        });
        snap("editor_ai_project_replace_confirm.png");
        click("aiset:project:replace-cancel");
        step(4, [this, st] {
            at_check(!at_visible("aiset:project:replace-ok") && read_file(st->dirA + "/.factoria/ai/settings.json") == st->cameWith,
                     "Cancel closes the popup and leaves the file as it came");
        });
        click("ai:roles:save");
        step(4, [this] { at_check(at_visible("aiset:project:replace-ok"), "Save asks again"); });
        click("aiset:project:replace-ok");
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return aiProj_.have && !aiProj_.resolved.pendingTrust && aiProj_.resolved.applied && !aiRolesOpen_; };
        });
        step(4, [this, st, run_model] {
            const Json file = Json::parse(read_file(st->dirA + "/.factoria/ai/settings.json"), nullptr, false);
            at_check(json_at(file, "/roles/worker/model") == "my-own-model", "Replace saves the user's roles into the project's file");
            at_check(read_file(st->dirA + "/.factoria/ai/settings.replaced.json") == st->cameWith,
                     "...and the file that came with the project is kept as settings.replaced.json");
            at_check(run_model("worker") == "my-own-model", "...the next run uses the saved model (" + run_model("worker") + ")");
        });
        // ai.settings.set from an AI (the proxy registry of a run, as MCP and the agent use it): an MCP client cannot change the user's
        // defaults, a project-scope change reaches the windows, and a change the user's own caller makes (no scope) reloads them.
        step(2, [this, st] {
            st->run = std::make_unique<AiRun>("autotest-q2");
            auto proxy = make_proxy_registry(*st->run);
            const std::string before = read_file(st->userPath);
            CommandResult refused;
            {
                CommandCallerScope as(CommandCaller::Mcp);
                refused = proxy->call("ai.settings.set", Json::object({{"scope", "user"}, {"pointer", "/roles/orchestrator/model"}, {"value", "by-mcp"}}));
            }
            at_check(!refused.ok && refused.error.value("code", "") == "user_only" && read_file(st->userPath) == before,
                     "an MCP client cannot change the user's defaults (ai.json is untouched)");
            CommandResult project = proxy->call("ai.settings.set", Json::object({{"scope", "project"}, {"pointer", "/roles/artist/enabled"}, {"value", false}}));
            at_check(project.ok && project.result.value("needsAcceptance", false), "...but it can change the project's file (it then waits for the user)");
            CommandResult user = proxy->call("ai.settings.set", Json::object({{"scope", "user"}, {"pointer", "/roles/orchestrator/model"}, {"value", "by-user"}}));
            at_check(user.ok, "the user's own caller can change the user's defaults" + (user.ok ? std::string() : ": " + user.error.dump()));
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] {
                // A detection that was running can make this true one frame before the reload: wait until neither file's
                // change flag is pending (the reload consumes them) as well.
                return !aiDetecting_.load() && !aiRolesOpen_ && !aiUserFileChanged_.load() && !aiProjectFileChanged_.load() && aiProj_.have &&
                       aiProj_.resolved.pendingTrust && !aiProj_.resolved.invalidError;
            };
        });
        step(4, [this, run_model] {
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                at_check(aiConfig_.role("orchestrator").model == "by-user", "the editor reloaded ai.json after the command wrote it");
            }
            at_check(run_model("orchestrator") == "by-user" && aiRolesEdit_["orchestrator"].model == "by-user",
                     "...the next run and the Roles tab have the new value (" + run_model("orchestrator") + ")");
            at_check(aiProj_.resolved.pendingTrust, "...and a project-scope change shows up as a file that waits for Accept (the cache was dropped)");
        });
        // Put everything back.
        step(2, [this, st, set_env] {
            st->run.reset();
            showAiSettings_ = false;
            ai_settings_discard();
            set_env("FACTORIA_AI_CONFIG", st->hadEnv ? st->previousEnv : std::string());
            open_project(st->fixtureDir);
        });
        step(1, [this, st] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this, st] { return engine_ && pendingOpen_.empty() && !pendingWelcome_ && atReopenIn_ == 0 && projectDir_ == st->fixtureDir; };
        });
        step(2, [this, st] {
            ai_refresh_providers();
            std::error_code ec;
            stdfs::remove_all(st->root, ec);
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(2, [this, st] {
            ai_project_invalidate();
            std::lock_guard<std::mutex> lock(aiMu_);
            if (atSavedConfig_) {
                aiConfig_ = std::move(*atSavedConfig_);
                atSavedConfig_.reset();
            }
            aiStatus_ = std::move(st->savedStatus);
        });
    }
}

void Editor::at_section_D2(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // The External tools tab of the AI settings window (docs/EDITOR.md, "AI settings"): a server added with the form (a name that
    // cannot be used stops Apply), Test against a fake MCP server (the key goes out in the header), a Claude Code style JSON pasted,
    // Save writes only "mcpServers" (the other keys of the file stay, owner-only, the key never in the log), Remove, Save again.
    {
        struct DState {
            std::string path, previousEnv;
            bool hadEnv = false;
            std::vector<ai::ProviderStatus> savedStatus;
            std::shared_ptr<std::string> auth = std::make_shared<std::string>();
        };
        auto x = std::make_shared<DState>();
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
            x->path = atOutDir_ + "/ai_tools_scratch.json";
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
  "inheritEnv": ["FA_AUTOTEST_*"],
  "roles": { "worker": { "provider": "anthropic", "model": "sonnet" } }
})");
            set_env("FACTORIA_AI_CONFIG", x->path);
            // A fake MCP server: initialize, tools/list, and it remembers the Authorization header it was given.
            auto auth = x->auth;
            aiToolTransport_ = [auth](const ai::HttpRequest& rq) -> ai::HttpResponse {
                ai::HttpResponse rs;
                rs.status = 200;
                if (rq.method == "DELETE") return rs;
                for (const auto& [k, v] : rq.headers) {
                    if (k == "Authorization") *auth = v;
                }
                const Json body = Json::parse(rq.body, nullptr, false);
                const std::string method = body.is_object() ? body.value("method", std::string()) : std::string();
                if (!body.is_object() || !body.contains("id")) {
                    rs.status = 202;
                    return rs;
                }
                Json result = Json::object();
                if (method == "initialize") {
                    result = Json::object({{"protocolVersion", "2025-06-18"},
                                           {"capabilities", Json::object({{"tools", Json::object()}})},
                                           {"serverInfo", Json::object({{"name", "FakeArt"}, {"version", "1.0"}})}});
                } else if (method == "tools/list") {
                    result = Json::object(
                        {{"tools", Json::array({Json::object({{"name", "generate_image"}, {"description", "Makes an image"},
                                                              {"inputSchema", Json::object({{"type", "object"}})}}),
                                                Json::object({{"name", "list_models"}, {"description", "Lists models"},
                                                              {"inputSchema", Json::object({{"type", "object"}})}})})}});
                }
                rs.headers["content-type"] = "application/json";
                rs.body = Json::object({{"jsonrpc", "2.0"}, {"id", body["id"]}, {"result", result}}).dump();
                return rs;
            };
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
            at_check(showAiSettings_ && aiSettings_.loaded && aiSettings_.path == x->path, "AI > AI Settings... opens the window on the scratch file");
            aiSettingsTab_ = 3;  // External tools
        });
        step(3, [this] {
            at_check(aiSettings_.tools.servers.empty(), "no tool server yet");
            at_check(at_visible("aiset:tools:add") && at_visible("aiset:tools:paste"), "the External tools tab shows Add server and Paste JSON");
        });
        click("aiset:tools:add");
        step(3, [this] {
            at_check(aiSettings_.tools.editing >= 0 && aiSettings_.tools.adding && at_visible("aiset:tools:apply"), "Add server opens the form");
            auto& e = aiSettings_.tools.edit;
            e.name = "factoria";  // reserved
            e.type = "http";
            e.url = "https://mcp.example.test/mcp";
            e.apiKey = "autotest-tool-key-987";
            e.note = "Makes pixel-art sprites; costs credits per image.";
            e.roles = {"worker", "artist"};
            aiSettings_.tools.editHeaders = "Authorization: Basic {key}";
        });
        scroll_to("aiset:tools:apply", "AI settings###AiSettings");
        click("aiset:tools:apply");
        step(3, [this] {
            at_check(aiSettings_.tools.servers.empty() && aiSettings_.tools.editing >= 0 &&
                         aiSettings_.tools.editError.find("factoria") != std::string::npos,
                     "a reserved name stops Apply and says why (" + aiSettings_.tools.editError + ")");
            aiSettings_.tools.edit.name = "scenario";
        });
        scroll_to("aiset:tools:apply", "AI settings###AiSettings");
        click("aiset:tools:apply");
        step(3, [this] {
            const auto& s = aiSettings_.tools.servers;
            at_check(s.size() == 1 && s[0].name == "scenario" && aiSettings_.tools.editing < 0, "Apply adds the server and closes the form");
            at_check(s.size() == 1 && s[0].headers.size() == 1 && s[0].headers[0].first == "Authorization" &&
                         s[0].headers[0].second == "Basic {key}" && s[0].roles.size() == 2,
                     "...with its header and roles");
            at_check(s.size() == 1 && s[0].inheritEnvGlobal == std::vector<std::string>{"FA_AUTOTEST_*"},
                     "...and ai.json's global inheritEnv, so its Test inherits it like a saved server");
        });
        scroll_to("aiset:tools:test:scenario", "AI settings###AiSettings");
        click("aiset:tools:test:scenario");
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiToolTestRunning_.load(); };
        });
        step(3, [this, x] {
            std::string text;
            {
                std::lock_guard<std::mutex> lock(aiSettings_.tools.tests->mu);
                text = aiSettings_.tools.tests->text["scenario"];
            }
            at_check(text.find("Connected to FakeArt") != std::string::npos && text.find("2 tools") != std::string::npos &&
                         text.find("generate_image") != std::string::npos,
                     "Test connects and lists the tools (" + text + ")");
            at_check(*x->auth == "Basic autotest-tool-key-987", "...and the key went out in the Authorization header");
        });
        // A Claude Code style JSON.
        click("aiset:tools:paste");
        step(3, [this] {
            at_check(aiSettings_.tools.showPaste && at_visible("aiset:tools:import"), "Paste JSON opens the paste box");
            aiSettings_.tools.pasteText = R"({"mcpServers":{"fs":{"command":"npx","args":["-y","some-mcp","--root","/tmp/my dir"],"env":{"MODE":"fast"},"disabled":true}}})";
        });
        click("aiset:tools:import");
        step(3, [this] {
            const auto& s = aiSettings_.tools.servers;
            at_check(s.size() == 2 && s[1].name == "fs" && s[1].is_stdio() && s[1].command == "npx" && s[1].args.size() == 4 &&
                         s[1].args[3] == "/tmp/my dir" && s[1].env.count("MODE"),
                     "Import adds the pasted stdio server (" + aiSettings_.tools.pasteMessage + ")");
            at_check(aiSettings_.tools.pasteMessage.find("disabled") != std::string::npos, "...and says which keys FactorIA does not use");
            at_check(s.size() == 2 && s[1].inheritEnvGlobal == std::vector<std::string>{"FA_AUTOTEST_*"}, "...with ai.json's global inheritEnv too");
        });
        snap("editor_ai_tools.png");
        click("aiset:tools:save");
        step(6, [this, x] {
            Json j = Json::parse(read_file(x->path), nullptr, false);
            at_check(j.is_object() && aiSettings_.tools.saveError.empty(), "Save wrote a JSON object (" + aiSettings_.tools.saveError + ")");
            if (!j.is_object()) return;
            at_check(j["limits"]["maxConcurrentRuns"] == 3 && j["roles"]["worker"]["model"] == "sonnet", "the other keys of the file stayed");
            at_check(j["mcpServers"]["scenario"]["url"] == "https://mcp.example.test/mcp" && j["mcpServers"]["scenario"]["apiKey"] == "autotest-tool-key-987" &&
                         j["mcpServers"]["scenario"]["headers"]["Authorization"] == "Basic {key}" && j["mcpServers"]["scenario"]["roles"].size() == 2,
                     "the server is in the file with its header, key and roles");
            at_check(j["mcpServers"]["fs"]["command"] == "npx" && j["mcpServers"]["fs"]["args"].size() == 4, "the program server is in the file");
#ifndef _WIN32
            std::error_code ec;
            const auto perms = stdfs::status(x->path, ec).permissions();
            at_check((perms & (stdfs::perms::group_all | stdfs::perms::others_all)) == stdfs::perms::none,
                     "the file with a key in it is readable only by its owner");
#endif
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                at_check(aiConfig_.toolServers.size() == 2, "the editor's config was reloaded with the servers");
            }
            at_check(std::ranges::none_of(atLog_, [](const std::string& line) { return line.find("autotest-tool-key-987") != std::string::npos; }),
                     "the key is in no line of the autotest log");
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        click("aiset:tools:remove:fs");
        click("aiset:tools:save");
        step(6, [this, x] {
            Json j = Json::parse(read_file(x->path), nullptr, false);
            at_check(j.is_object() && j["mcpServers"].contains("scenario") && !j["mcpServers"].contains("fs"), "Remove and Save take the server out of the file");
            at_check(j.is_object() && j["roles"]["worker"]["model"] == "sonnet", "the other keys stayed again");
        });
        // The Agents tab: the permission mode of Claude Code and Codex (docs/AI_PROVIDERS.md, "Permission mode").
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(2, [this] { aiSettingsTab_ = 5; });
        step(3, [this] {
            at_check(at_visible("aiset:agents:combo:claude-code") && at_visible("aiset:agents:combo:codex"),
                     "the Agents tab has a permission mode combo for Claude Code and for Codex");
            at_check(!at_enabled("aiset:agents:save:claude-code"), "Save waits for a change");
            aiSettings_.agents.mode["claude-code"] = "bypassPermissions";
        });
        step(2, [this] { at_check(at_enabled("aiset:agents:save:claude-code"), "picking another mode enables Save"); });
        click("aiset:agents:save:claude-code");
        step(3, [this, x] {
            at_check(aiSettings_.agents.confirm == "claude-code" && at_visible("aiset:agents:confirm") && at_visible("aiset:agents:cancel"),
                     "a dangerous mode asks before it is saved");
            Json j = Json::parse(read_file(x->path), nullptr, false);
            at_check(j.is_object() && !j.contains("providers"), "...and nothing is written yet");
        });
        click("aiset:agents:cancel");
        step(2, [this] { at_check(aiSettings_.agents.confirm.empty() && !at_visible("aiset:agents:confirm"), "Cancel closes the question"); });
        click("aiset:agents:save:claude-code");
        step(3, [this] { at_check(at_visible("aiset:agents:confirm"), "Save asks again"); });
        click("aiset:agents:confirm");
        step(6, [this, x] {
            Json j = Json::parse(read_file(x->path), nullptr, false);
            at_check(j.is_object() && j.contains("providers") && j["providers"]["claude-code"].value("permissionMode", std::string()) == "bypassPermissions",
                     "confirming writes permissionMode into the provider (" + aiSettings_.agents.message + ")");
            at_check(j.is_object() && j["roles"]["worker"]["model"] == "sonnet" && j["mcpServers"].contains("scenario") &&
                         j["inheritEnv"].size() == 1,
                     "the other keys of the file stayed");
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                const auto it = aiConfig_.providers.find("claude-code");
                at_check(it != aiConfig_.providers.end() && it->second.permissionMode == "bypassPermissions",
                         "the editor's config was reloaded with the mode");
            }
            at_check(aiSettings_.agents.mode.empty() && aiSettings_.tools.servers.size() == 1, "the draft shows the saved mode and kept the other tab");
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(2, [this] { aiSettings_.agents.mode["codex"] = "read-only"; });
        click("aiset:agents:save:codex");  // not dangerous: saved at once
        step(6, [this, x] {
            Json j = Json::parse(read_file(x->path), nullptr, false);
            at_check(j.is_object() && j.contains("providers") && j["providers"]["codex"].value("permissionMode", std::string()) == "read-only" &&
                         j["providers"]["claude-code"].value("permissionMode", std::string()) == "bypassPermissions",
                     "a safe mode is saved without a question, next to the first");
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(3, [this] { at_check(at_visible("aiset:agents:reset:claude-code"), "a provider with a saved mode offers Use the default"); });
        click("aiset:agents:reset:claude-code");
        step(6, [this, x] {
            Json j = Json::parse(read_file(x->path), nullptr, false);
            at_check(j.is_object() && j.contains("providers") && !j["providers"].contains("claude-code") && j["providers"].contains("codex"),
                     "Use the default takes the key (and the empty provider entry) out of the file");
            std::lock_guard<std::mutex> lock(aiMu_);
            const auto it = aiConfig_.providers.find("claude-code");
            at_check(it != aiConfig_.providers.end() && it->second.permissionMode.empty(),
                     "...and the editor's config follows (Use the default reloads it like a save)");
            at_check(aiSettings_.tools.inheritEnvGlobal == aiConfig_.inheritEnv,
                     "...and the tools draft has ai.json's global inheritEnv again");
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        click("aiset:agents:close");
        step(4, [this] {
            at_check(!showAiSettings_ && !aiSettings_.loaded && aiSettings_.tools.servers.empty(), "Close closes the window and drops the draft");
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !aiDetecting_.load(); };
        });
        step(2, [this, x, set_env] {
            aiToolTransport_ = nullptr;
            set_env("FACTORIA_AI_CONFIG", x->hadEnv ? x->previousEnv : std::string());
            std::error_code ec;
            stdfs::remove(x->path, ec);
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
