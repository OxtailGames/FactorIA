// Autotest sections O to W: the CLI agent, reverting an AI run, agent liveness, the program-updated notice, the layout kept, AI
// reviews and several AI chats at once.
// Split from autotest_tools.cpp: each section is an Editor::at_section_<id>(AtScript&) that adds its steps to the script,
// called by at_build_tools_script in the order of the full run (autotest_sections.h).
#include <algorithm>
#include <cctype>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <filesystem>
#include <memory>
#include <mutex>
#include <thread>

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
#include "ui_backend.h"

namespace fa::editor {

using namespace at_support;

namespace {

namespace stdfs = std::filesystem;
// Section P's scripted "model": in one turn it overwrites a script, writes a new one (fs.write, like an API provider) and
// spawns an entity (a scene edit), then says it is done.
class RevertProvider : public ai::ChatProvider {
public:
    std::string name() const override { return "mock"; }
    Result<ai::ChatResponse> chat(const ai::ChatRequest&, const ai::ChatHooks& hooks, const ai::CancelFlag*) override {
        ai::ChatResponse r;
        r.message.role = ai::Role::Assistant;
        r.message.raw = Json::object();
        r.usage.inputTokens = 900;
        r.usage.outputTokens = 60;
        if (turn_ == 0) {
            r.message.text = "Writing two scripts and adding a coin. ";
            if (hooks.onText) hooks.onText(r.message.text);
            auto call = [&](const char* id, const char* name, const char* input) {
                ai::ToolCall c;
                c.id = id;
                c.name = name;
                c.input = Json::parse(input);
                r.message.toolCalls.push_back(c);
            };
            call("w1", "fs_write", R"({"path":"scripts/revert_old.js","content":"new\n"})");
            call("w2", "fs_write", R"({"path":"scripts/revert_new.js","content":"added by the run\n"})");
            call("w3", "scene_spawn", R"({"name":"RevertCoin","position":[0,120],"components":{"Shape2D":{"shape":"circle","size":[28,28],"color":[1,0.85,0.1,1]}}})");
            r.stopReason = ai::StopReason::ToolUse;
        } else {
            r.message.text = "Done.";
            if (hooks.onText) hooks.onText(r.message.text);
            r.stopReason = ai::StopReason::EndTurn;
        }
        ++turn_;
        return r;
    }

private:
    int turn_ = 0;
};

// Section Q's worker: says something, takes `delayMs` to think (cancellable), then reports. Nothing else; no tool calls.
class SlowWorkerProvider : public ai::ChatProvider {
public:
    explicit SlowWorkerProvider(int delayMs) : delayMs_(delayMs) {}
    std::string name() const override { return "mock"; }
    Result<ai::ChatResponse> chat(const ai::ChatRequest&, const ai::ChatHooks& hooks, const ai::CancelFlag* cancel) override {
        ai::ChatResponse r;
        r.message.role = ai::Role::Assistant;
        r.message.raw = Json::object();
        r.usage.inputTokens = 300;
        r.usage.outputTokens = 30;
        if (hooks.onText) hooks.onText("Making the coin. ");
        for (int waited = 0; waited < delayMs_ && !(cancel && cancel->load()); waited += 25)
            std::this_thread::sleep_for(std::chrono::milliseconds(25));
        r.message.text = "Making the coin. Worker report: coin done";
        if (hooks.onText) hooks.onText("Worker report: coin done");
        r.stopReason = ai::StopReason::EndTurn;
        return r;
    }

private:
    int delayMs_;
};
// Section W's scripted "model" for several chats at once. The first user message carries a marker. [A], [B] and [L] work: they
// wait (1.2 s, 1.2 s, 3.5 s; cancellable), then write scripts/u_shared.js and their own scripts/u_<letter>.js and spawn a coin
// (UCoin<LETTER>). [S] only waits, 20 s (a run to Stop). Every run ends by saying "Finished <marker>".
class ConcurrentProvider : public ai::ChatProvider {
public:
    std::string name() const override { return "mock"; }
    Result<ai::ChatResponse> chat(const ai::ChatRequest& req, const ai::ChatHooks& hooks, const ai::CancelFlag* cancel) override {
        char marker = '?';
        for (const ai::Message& m : req.messages) {
            if (m.role != ai::Role::User) continue;
            const std::size_t at = m.text.find('[');
            if (at != std::string::npos && at + 2 < m.text.size() && m.text[at + 2] == ']') {
                marker = m.text[at + 1];
                break;
            }
        }
        ai::ChatResponse r;
        r.message.role = ai::Role::Assistant;
        r.message.raw = Json::object();
        r.usage.inputTokens = 500;
        r.usage.outputTokens = 40;
        const bool answered = !req.messages.empty() && !req.messages.back().toolResults.empty();
        if (!answered) {
            r.message.text = std::string("Working on ") + marker + ". ";
            if (hooks.onText) hooks.onText(r.message.text);
            const int delayMs = marker == 'S' ? 20000 : marker == 'L' ? 3500 : 1200;
            for (int waited = 0; waited < delayMs && !(cancel && cancel->load()); waited += 25)
                std::this_thread::sleep_for(std::chrono::milliseconds(25));
            if (marker != 'S' && !(cancel && cancel->load())) {
                const std::string lower(1, static_cast<char>(std::tolower(static_cast<unsigned char>(marker))));
                const std::string upper(1, marker);
                auto call = [&](const std::string& id, const char* name, const Json& input) {
                    ai::ToolCall c;
                    c.id = id;
                    c.name = name;
                    c.input = input;
                    r.message.toolCalls.push_back(c);
                };
                call("w1", "fs_write", Json::object({{"path", "scripts/u_shared.js"}, {"content", "from " + upper + "\n"}}));
                call("w2", "fs_write", Json::object({{"path", "scripts/u_" + lower + ".js"}, {"content", "only " + upper + "\n"}}));
                call("w3", "scene_spawn",
                     Json::parse("{\"name\":\"UCoin" + upper + "\",\"position\":[0,120],\"components\":{\"Shape2D\":{\"shape\":\"circle\","
                                 "\"size\":[28,28],\"color\":[1,0.85,0.1,1]}}}"));
                r.stopReason = ai::StopReason::ToolUse;
                return r;
            }
        }
        r.message.text = std::string("Finished ") + marker;
        if (hooks.onText) hooks.onText(r.message.text);
        r.stopReason = ai::StopReason::EndTurn;
        return r;
    }
};
// Section V's reviewer: no tool calls, one report that ends in the score block. It records the tools it was offered, so the
// test can see that a read-only role really is not given the ones that change the project.
std::vector<std::string> g_reviewToolsOffered;
class ReviewerProvider : public ai::ChatProvider {
public:
    std::string name() const override { return "mock"; }
    Result<ai::ChatResponse> chat(const ai::ChatRequest& req, const ai::ChatHooks& hooks, const ai::CancelFlag*) override {
        g_reviewToolsOffered.clear();
        for (const ai::ToolDef& t : req.tools) g_reviewToolsOffered.push_back(t.name);
        ai::ChatResponse r;
        r.message.role = ai::Role::Assistant;
        r.message.raw = Json::object();
        r.usage.inputTokens = 900;
        r.usage.outputTokens = 60;
        r.message.text =
            "The first minute is clear and the controls answer at once.\n\n```json\n"
            "{\"score\": 7.5, \"subScores\": {\"fun\": 8, \"polish\": 6}, \"summary\": \"Clear and quick\"}\n```";
        if (hooks.onText) hooks.onText(r.message.text);
        r.stopReason = ai::StopReason::EndTurn;
        return r;
    }
};

}  // namespace

void Editor::at_section_O(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // ----------------------------------------------------------------------------------- O. CLI agent (Claude Code)
    // A CLI agent runs its own loop in a child process; its tool calls come back through the editor's MCP endpoint. The
    // fake Claude Code of the AI tests calls scene_spawn there: the coin must land in THIS world, with an undo step, and
    // Play must wait meanwhile. Needs the fixture (the autotest runs from the repository root) and curl.
    step(1, [this] {  // the background detection writes aiConfig_ once: it must be done before the swap below (O alone runs early)
        atWaitCount_ = 0;
        atWaitUntil_ = [this] { return aiDetected_.load(); };
    });
    step(2, [this] {
#ifdef _WIN32
        stdfs::path fake = stdfs::absolute("tools/ai/tests/fixtures/fake_claude.cmd");
#else
        stdfs::path fake = stdfs::absolute("tools/ai/tests/fixtures/fake_claude.sh");
#endif
        if (!stdfs::exists(fake) || ai::which("curl").empty()) {
            atLog_.push_back("SKIP CLI agent through the editor's MCP endpoint (no " + fake.string() + " or no curl)");
            return;
        }
        ai::ProviderConfig cc;
        cc.name = "claude-code";
        cc.kind = ai::ProviderKind::ClaudeCode;
        cc.command = fake.make_preferred().string();
        cc.env["FAKE_MODE"] = "mcp_spawn";
        {
            std::lock_guard<std::mutex> lock(aiMu_);
            atSavedConfig_ = aiConfig_;
            aiConfig_.providers[cc.name] = cc;
            aiConfig_.roles[ai::kRoleOrchestrator] = ai::RoleConfig{cc.name};
        }
        atUndoBeforeAi_ = undo_depth();
        ai_start("Add a coin.");
        at_check(ai_running(), "a message to a Claude Code orchestrator starts the agent");
        play();
        at_check(play_state() == PlayState::Edit, "Play waits while the CLI agent is changing the scene");
        atWaitAi_ = true;
        atWaitCount_ = 0;
    });
    step(2, [this] {
        if (!atSavedConfig_) return;
        at_check(!ai_running(), "the CLI agent finished");
        at_check(!world().find("CliCoin").is_null(), "the CLI agent's tool call (scene_spawn over MCP) created the entity in the editor's world");
        at_check(undo_depth() > atUndoBeforeAi_, "the CLI agent's edit recorded an undo step");
        undo();
        at_check(world().find("CliCoin").is_null(), "Ctrl+Z (undo) removes the entity the CLI agent created");
        std::lock_guard<std::mutex> lock(aiMu_);
        aiConfig_ = std::move(*atSavedConfig_);
        atSavedConfig_.reset();
    });
}

void Editor::at_section_P(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // --------------------------------------------------------------------------------- P. Revert an AI run
    // A scripted AI run overwrites one script, adds another and spawns an entity. The transcript offers Revert; confirming it
    // puts the files back and the scene back as ONE Ctrl+Z step; Undo revert brings the run's state back.
    step(1, [this] {
        atWaitCount_ = 0;
        atWaitUntil_ = [this] { return aiDetected_.load(); };
    });
    step(2, [this, project_file] {
        write_file(project_file("scripts/revert_old.js"), "old\n");
        std::error_code ec;
        stdfs::remove(project_file("scripts/revert_new.js"), ec);
        aiFactory_ = [](const ai::ProviderConfig&) -> Result<std::shared_ptr<ai::ChatProvider>> {
            return std::shared_ptr<ai::ChatProvider>(std::make_shared<RevertProvider>());
        };
        {
            std::lock_guard<std::mutex> lock(aiMu_);
            atSavedConfig_ = aiConfig_;
            if (aiConfig_.providers.empty()) aiConfig_ = ai::default_config();
            ai::RoleConfig& orchestrator = aiConfig_.roles[ai::kRoleOrchestrator];
            orchestrator.provider = "anthropic";
            if (orchestrator.model.empty()) orchestrator.model = "mock";
        }
        chat_.clear();
        focus_window("AI Assistant");
        ai_start("Add a revert probe script and a coin.");
        atWaitAi_ = true;
        atWaitCount_ = 0;
    });
    step(4, [this, project_file] {
        at_check(!ai_running(), "the scripted run finished");
        at_check(read_file(project_file("scripts/revert_old.js")) == "new\n" && stdfs::exists(project_file("scripts/revert_new.js")) &&
                     !world().find("RevertCoin").is_null(),
                 "the run overwrote a script, added one and spawned an entity");
        const ChatItem* run = nullptr;
        for (const ChatItem& c : chat())
            if (c.kind == ChatItem::Kind::Run) run = &c;
        at_check(run && run->modified == std::vector<std::string>{"scripts/revert_old.js"} &&
                     run->added == std::vector<std::string>{"scripts/revert_new.js"} && run->sceneChanged,
                 "the transcript lists what the run changed: a modified file, an added file, the scene");
        at_check(at_visible("ai:revert") && at_enabled("ai:revert"), "the run offers a Revert button");
    });
    snap("editor_ai_run_changed.png");
    click("ai:revert");
    step(4, [this] { at_check(at_visible("ai:revert:confirm"), "Revert asks before it changes anything"); });
    snap("editor_ai_revert_confirm.png");
    click("ai:revert:confirm");
    step(6, [this, project_file] {
        at_check(read_file(project_file("scripts/revert_old.js")) == "old\n", "Revert writes the overwritten script back");
        at_check(!stdfs::exists(project_file("scripts/revert_new.js")), "Revert deletes the file the run added");
        at_check(world().find("RevertCoin").is_null() && !dirty(), "Revert puts the scene back as it was before the run");
        bool sawRevert = false;
        for (const ChatItem& c : chat()) sawRevert = sawRevert || (c.kind == ChatItem::Kind::Revert && !c.isUndo);
        at_check(sawRevert && at_visible("ai:undo-revert") && !at_visible("ai:revert"), "the transcript says so and offers Undo revert");
        undo();
        at_check(!world().find("RevertCoin").is_null(), "the scene went back as ONE Ctrl+Z step: Undo brings the coin back");
        redo();
        at_check(world().find("RevertCoin").is_null(), "...and Redo takes it away again");
    });
    snap("editor_ai_reverted.png");
    scroll_to("ai:undo-revert", "AI Assistant");
    click("ai:undo-revert");
    step(4, [this] { at_check(at_visible("ai:revert:confirm"), "Undo revert asks first too"); });
    click("ai:revert:confirm");
    step(6, [this, project_file] {
        at_check(read_file(project_file("scripts/revert_old.js")) == "new\n" && stdfs::exists(project_file("scripts/revert_new.js")),
                 "Undo revert brings the run's files back");
        at_check(!world().find("RevertCoin").is_null(), "...and the run's scene");
        at_check(at_visible("ai:revert"), "...and the run can be reverted again");
        std::error_code ec;
        stdfs::remove(project_file("scripts/revert_old.js"), ec);
        stdfs::remove(project_file("scripts/revert_new.js"), ec);
        aiFactory_ = nullptr;
        if (atSavedConfig_) {
            std::lock_guard<std::mutex> lock(aiMu_);
            aiConfig_ = std::move(*atSavedConfig_);
            atSavedConfig_.reset();
        }
        chat_.clear();
        focus_window("###Viewport");
    });
}

void Editor::at_section_Q(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // ------------------------------------------------------------------------- Q. The agent is never silent
    // The fake Claude Code of the AI tests stands in for a real orchestrator. (1) It stays silent for longer than
    // limits.stuckAfterSeconds: the panel warns, "Check activity" writes a verdict in the chat and quiets the warning, Stop
    // ends the run. (2) It calls ai_run (a worker, over the editor's MCP endpoint) and ends its turn without waiting for the
    // answer: the panel keeps showing the worker's progress, and when the worker finishes its report is in the chat and the
    // orchestrator is continued with it (once). (3) Stop while the worker runs ends both and sends no continuation.
    step(1, [this] {
        atWaitCount_ = 0;
        atWaitUntil_ = [this] { return aiDetected_.load(); };
    });
    step(2, [this, project_file] {
#ifdef _WIN32
        stdfs::path fake = stdfs::absolute("tools/ai/tests/fixtures/fake_claude.cmd");
#else
        stdfs::path fake = stdfs::absolute("tools/ai/tests/fixtures/fake_claude.sh");
#endif
        atQFake_.clear();
        if (!stdfs::exists(fake) || ai::which("curl").empty()) {
            atLog_.push_back("SKIP the agent is never silent (no " + fake.string() + " or no curl)");
            return;
        }
        atQFake_ = fake.make_preferred().string();
        atQArgv_ = (stdfs::temp_directory_path() / "fa_autotest_q_argv.txt").string();
        std::error_code ec;
        stdfs::remove(atQArgv_, ec);
        {
            std::lock_guard<std::mutex> lock(aiMu_);
            atSavedConfig_ = aiConfig_;
            if (aiConfig_.providers.empty()) aiConfig_ = ai::default_config();
            ai::ProviderConfig cc;
            cc.name = "claude-code";
            cc.kind = ai::ProviderKind::ClaudeCode;
            cc.command = atQFake_;
            cc.env["FAKE_ARGV_FILE"] = atQArgv_;
            cc.env["FAKE_SLEEP"] = "7";
            aiConfig_.providers[cc.name] = cc;
            aiConfig_.roles[ai::kRoleOrchestrator] = ai::RoleConfig{cc.name};
            ai::RoleConfig& worker = aiConfig_.roles[ai::kRoleWorker];
            worker.provider = "anthropic";
            worker.model = "mock";
            aiConfig_.limits.stuckAfterSeconds = 2;
        }
        aiFactory_ = [](const ai::ProviderConfig&) -> Result<std::shared_ptr<ai::ChatProvider>> {
            return std::shared_ptr<ai::ChatProvider>(std::make_shared<SlowWorkerProvider>(2500));
        };
        chat_.clear();
        focus_window("AI Assistant");
        ai_start("Think for a while.");
        atWaitCount_ = 0;
        atWaitUntil_ = [this] { return at_visible("ai:stuck"); };
    });
    step(2, [this] {
        if (atQFake_.empty()) return;
        at_check(ai_running(), "the agent is still running while it is silent");
        at_check(at_visible("ai:status"), "the panel shows the run's elapsed time and last activity");
        at_check(at_visible("ai:stuck") && at_visible("ai:stuck:stop") && at_visible("ai:stuck:check"),
                 "a silent agent gets a warning with Stop and Check activity");
    });
    snap("editor_ai_stuck.png");
    click("ai:stuck:check");
    step(3, [this] {
        if (atQFake_.empty()) return;
        const ChatItem* check = nullptr;
        for (const ChatItem& c : chat())
            if ((c.kind == ChatItem::Kind::Info || c.kind == ChatItem::Kind::Error) && c.text.rfind("Activity check:", 0) == 0) check = &c;
        at_check(check && check->text.find("Process:") != std::string::npos && check->text.find("Last event:") != std::string::npos,
                 "Check activity writes a verdict with what it saw in the chat");
        at_check(!at_visible("ai:stuck"), "...and quiets the warning");
    });
    step(2, [this] {
        if (atQFake_.empty()) return;
        atWaitAi_ = true;
        atWaitCount_ = 0;
    });
    step(2, [this] {
        if (atQFake_.empty()) return;
        at_check(!ai_running(), "the silent agent finished in the end");
        // A second silent run, ended with the warning's Stop.
        ai_start("Think for a while again.");
        atWaitCount_ = 0;
        atWaitUntil_ = [this] { return at_visible("ai:stuck"); };
    });
    click("ai:stuck:stop");
    step(2, [this] {
        if (atQFake_.empty()) return;
        atWaitAi_ = true;
        atWaitCount_ = 0;
    });
    step(2, [this] {
        if (atQFake_.empty()) return;
        at_check(!ai_running() && !ai_busy(), "Stop in the warning ends the run");
        // (2) the orchestrator delegates and ends its turn.
        {
            std::lock_guard<std::mutex> lock(aiMu_);
            ai::ProviderConfig& cc = aiConfig_.providers["claude-code"];
            cc.env["FAKE_MODE"] = "mcp_run_detach";
            cc.env.erase("FAKE_SLEEP");
            aiConfig_.limits.stuckAfterSeconds = 120;
        }
        std::error_code ec;
        stdfs::remove(atQArgv_, ec);
        chat_.clear();
        ai_start("Delegate the coin.");
        atWaitCount_ = 0;
        atWaitUntil_ = [this] {
            const AiRun* r = ai_run_of(chat_.current().id);
            return r && r->detached.load();
        };
    });
    step(3, [this] {
        if (atQFake_.empty()) return;
        {
            const AiRun* r = ai_run_of(chat_.current().id);
            at_check(ai_running() && r && !r->running.load(), "the orchestrator's turn ended and the run goes on for the worker");
        }
        at_check(at_visible("ai:detached"), "the panel says a worker is still running");
        bool live = false;
        for (const ChatItem& c : chat()) live = live || (c.kind == ChatItem::Kind::Assistant && c.depth == 1 && c.text.find("Making the coin") != std::string::npos);
        at_check(live, "the worker's progress is in the chat while it runs, one level in");
        play();
        at_check(play_state() == PlayState::Edit, "Play waits for the worker");
    });
    snap("editor_ai_worker_running.png");
    step(2, [this] {
        if (atQFake_.empty()) return;
        atWaitAi_ = true;
        atWaitCount_ = 0;
    });
    step(3, [this] {
        if (atQFake_.empty()) return;
        at_check(!ai_running() && !ai_busy(), "the run ended after the continuation");
        int reports = 0, continued = 0;
        for (const ChatItem& c : chat()) {
            if (c.kind == ChatItem::Kind::Assistant && c.depth == 1 && c.text.find("Worker report: coin done") != std::string::npos) ++reports;
            if (c.kind == ChatItem::Kind::Info && c.text.find("continuing the orchestrator") != std::string::npos) ++continued;
        }
        at_check(reports == 1, "the worker's report is in the chat once");
        at_check(continued == 1, "the transcript says the orchestrator was continued");
        const std::string argv = read_file(atQArgv_);
        std::size_t stdins = 0, resumes = 0;
        for (std::size_t at = argv.find("stdin:"); at != std::string::npos; at = argv.find("stdin:", at + 1)) ++stdins;
        for (std::size_t at = argv.find("--resume"); at != std::string::npos; at = argv.find("--resume", at + 1)) ++resumes;
        at_check(stdins == 2, "the orchestrator ran twice: its first turn and one continuation (" + std::to_string(stdins) + ")");
        at_check(resumes == 1, "the continuation resumed the same Claude Code session");
        at_check(argv.find("Worker report: coin done") != std::string::npos, "the continuation carried the worker's report");
        // (3) Stop while the worker runs.
        std::error_code ec;
        stdfs::remove(atQArgv_, ec);
        chat_.clear();
        aiFactory_ = [](const ai::ProviderConfig&) -> Result<std::shared_ptr<ai::ChatProvider>> {
            return std::shared_ptr<ai::ChatProvider>(std::make_shared<SlowWorkerProvider>(20000));
        };
        ai_start("Delegate the coin, slowly.");
        atWaitCount_ = 0;
        atWaitUntil_ = [this] {
            const AiRun* r = ai_run_of(chat_.current().id);
            return r && r->detached.load();
        };
    });
    click("ai:stop");
    step(2, [this] {
        if (atQFake_.empty()) return;
        atWaitAi_ = true;
        atWaitCount_ = 0;
    });
    step(3, [this] {
        if (atQFake_.empty()) return;
        at_check(!ai_running() && !ai_busy(), "Stop ends the run while the worker works");
        const std::string argv = read_file(atQArgv_);
        std::size_t stdins = 0;
        for (std::size_t at = argv.find("stdin:"); at != std::string::npos; at = argv.find("stdin:", at + 1)) ++stdins;
        at_check(stdins == 1, "...and no continuation is sent");
        bool continued = false;
        for (const ChatItem& c : chat()) continued = continued || c.text.find("continuing the orchestrator") != std::string::npos;
        at_check(!continued, "...and the transcript does not claim one");
        std::error_code ec;
        stdfs::remove(atQArgv_, ec);
        aiFactory_ = nullptr;
        if (atSavedConfig_) {
            std::lock_guard<std::mutex> lock(aiMu_);
            aiConfig_ = std::move(*atSavedConfig_);
            atSavedConfig_.reset();
        }
        chat_.clear();
        focus_window("###Viewport");
    });
}

void Editor::at_section_R(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // ------------------------------------------------------------------------------------ R. Updated on disk
    // The program is replaced on disk without the updater: a non-blocking notice offers Restart / Not now. The watch looks at a
    // fake program (two fingerprints written into files), so nothing real is replaced and Restart only records the click.
    {
        auto fake_program = [](const std::string& path, const std::string& version, const std::string& fingerprint, std::size_t pad) {
            std::string bytes = "MZ fake program " + std::string(pad, '.');
            bytes += std::string("FA-BUILD-") + "FINGERPRINT:" + fingerprint + ";";
            bytes += std::string("FA-ENGINE-") + "VERSION:" + version + ";";
            write_file(path, bytes);
        };
        step(2, [this, fake_program] {
            const std::string fake = atOutDir_ + "/fake_factoria";
            fake_program(fake, "0.1.0", "aaaaaaaaaaaa", 100);
            diskWatchOwn_ = std::make_unique<UpdateWatch>(fake, BuildId{"0.1.0", "aaaaaaaaaaaa"});
            diskDismissedSet_ = false;
            diskRestartRequested_ = false;
            diskSettling_ = false;
            diskPolled_ = -100;
        });
        step(3, [this] {
            at_check(!at_visible("update:disk"), "no notice while the program on disk is the one that runs");
            Json status = update_status_json(disk_watch());
            at_check(status.value("state", "") == "current" && status.value("restartDue", true) == false,
                     "engine.update_status says current: " + status.dump());
        });
        step(2, [this, fake_program] {  // the new files arrive (a different size, so a different stamp even within one second)
            fake_program(atOutDir_ + "/fake_factoria", "0.2.0", "bbbbbbbbbbbb", 400);
            diskPollNow_ = true;
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return at_visible("update:disk"); };  // seen twice alike (a second), then identified
        });
        step(3, [this] {
            at_check(at_visible("update:disk"), "the notice appears when the program changed on disk");
            at_check(at_enabled("update:restart") && at_visible("update:disknotnow"), "...with Restart and Not now");
            Json status = update_status_json(disk_watch());
            at_check(status.value("state", "") == "updated_on_disk" && status.value("restartDue", false) &&
                         status["onDisk"].value("version", "") == "0.2.0" && status["editor"].value("noticeShown", false),
                     "engine.update_status says an update is on disk and the notice is showing: " + status.dump());
            // A play session is not stopped silently: Restart is off, with the reason.
            play();
        });
        step(3, [this] {
            at_check(play_state() != PlayState::Edit, "a play session runs");
            at_check(!at_enabled("update:restart") && !disk_restart_blocker().empty(), "Restart is off while a play session runs (" + disk_restart_blocker() + ")");
        });
        snap("editor_update_disk.png");
        step(2, [this] {
            stop();
            at_check(disk_restart_blocker().empty(), "...and back on when it stops");
        });
        click("update:disknotnow");
        step(3, [this] {
            at_check(!at_visible("update:disk"), "Not now hides the notice");
            diskPollNow_ = true;
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !diskPollNow_; };
        });
        step(3, [this, fake_program] {
            at_check(!at_visible("update:disk"), "...and it stays quiet while the file does not change");
            fake_program(atOutDir_ + "/fake_factoria", "0.3.0", "cccccccccccc", 900);  // another build lands
            diskPollNow_ = true;
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return at_visible("update:disk"); };
        });
        step(3, [this] {
            at_check(at_visible("update:disk") && disk_watch().on_disk().version == "0.3.0", "...and comes back when the file changes again");
        });
        click("update:restart");
        step(3, [this] {
            at_check(diskRestartRequested_, "Restart asks to quit and reopen the editor");
            diskWatchOwn_.reset();
            diskRestartRequested_ = false;
            diskDismissedSet_ = false;
            diskSettling_ = false;
            std::error_code ec;
            stdfs::remove(atOutDir_ + "/fake_factoria", ec);
        });
    }
}

void Editor::at_section_U(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // ------------------------------------------------------------------------------------ U. Layout kept
    // A layout the user changed (a panel floated, a tab moved to another dock, a column made wider) is in the layout file when the
    // editor goes down, and comes back when a project opens again: straight away, and after a visit to the welcome screen (which
    // has its own ImGui context, without the dock space). The test uses its own layout file; the real one is put back at the end.
    {
        auto reopen_wait = [this](bool viaWelcome) {
            const std::string dir = projectDir_;
            const std::uint64_t u0 = uiFrame_;
            if (viaWelcome) {
                close_project();
                atReopenDir_ = dir;
                atReopenIn_ = 10;
            } else {
                open_project(dir);
            }
            atWaitCount_ = 0;
            atWaitUntil_ = [this, u0, viaWelcome] { return engine_ && pendingOpen_.empty() && !pendingWelcome_ && atReopenIn_ == 0 && uiFrame_ >= u0 + 8 + (viaWelcome ? 10 : 0); };
        };
        step(2, [this, reopen_wait] {
            atIniSaved_ = iniPath_;
            iniPath_ = atOutDir_ + "/layout_test.ini";
            std::error_code ec;
            stdfs::remove(iniPath_, ec);
            reopen_wait(false);  // no layout file yet: the default layout, and the file is written when the UI goes down
        });
        step(2, [this] {
            at_check(!panel_floating("Console") && panel_node("Console") != 0, "no layout file: Console starts docked (the default layout)");
            at_check(panel_node("Project") == panel_node("Console"), "...in the same dock as Project");
            at_check(panel_node("Project") != panel_node("Hierarchy"), "...and Project is not with the Hierarchy");
            // The user's changes: Console floats, Project joins the Hierarchy and the left column gets wider.
            ImGuiContext& g = *GImGui;
            ImGuiWindow* console = panel_window("Console");
            ImGui::DockContextQueueUndockWindow(&g, console);
            ImGuiWindow* hier = panel_window("Hierarchy");
            if (hier && hier->DockNode && panel_window("Project"))
                ImGui::DockContextQueueDock(&g, hier->DockNode->HostWindow, hier->DockNode, panel_window("Project"), ImGuiDir_None, 0.0f, false);
            if (hier && hier->DockNode) {
                ImGuiDockNode* col = hier->DockNode->ParentNode;
                while (col && col->ParentNode && col->ParentNode->SplitAxis != ImGuiAxis_X) col = col->ParentNode;
                if (col && col->ParentNode) {  // the node of the left column inside the X split: take 200 px from its sibling
                    ImGuiDockNode* sib = col->ParentNode->ChildNodes[0] == col ? col->ParentNode->ChildNodes[1] : col->ParentNode->ChildNodes[0];
                    col->SizeRef.x += 200;
                    if (sib) sib->SizeRef.x = std::max(100.0f, sib->SizeRef.x - 200);
                }
            }
            showFeedback_ = false;  // a panel closed with its X, and one opened from the View menu
            showAudio_ = true;
            atLayoutWidth_ = panel_width("Hierarchy");
        });
        step(4, [] {
            ImGui::SetWindowPos("Console", ImVec2(300, 300));
            ImGui::SetWindowSize("Console", ImVec2(420, 210));
        });
        step(6, [this] {
            at_check(panel_floating("Console"), "the test floated Console");
            at_check(panel_node("Project") == panel_node("Hierarchy") && panel_node("Project") != 0, "the test moved Project next to the Hierarchy");
            at_check(panel_width("Hierarchy") > atLayoutWidth_ + 100, "the test made the left column wider (" + std::to_string(atLayoutWidth_) + " -> " +
                                                                        std::to_string(panel_width("Hierarchy")) + ")");
            atLayoutWidth_ = panel_width("Hierarchy");
        });
        step(2, [reopen_wait] { reopen_wait(false); });
        auto check_changed_layout = [this](const std::string& when) {
            at_check(!showFeedback_ && showAudio_ && showConsole_, "the closed panel (Engine Feedback) is still closed and the opened one (Audio) still open " + when);
            at_check(panel_floating("Console"), "Console is still floating " + when);
            const ImGuiWindow* c = panel_window("Console");
            at_check(c && std::fabs(c->Size.x - 420) < 3 && std::fabs(c->Size.y - 210) < 3, "...with the size the user gave it " + when);
            at_check(panel_node("Project") == panel_node("Hierarchy") && panel_node("Project") != 0, "Project is still next to the Hierarchy " + when);
            at_check(std::fabs(panel_width("Hierarchy") - atLayoutWidth_) < 6,
                     "the left column keeps its width " + when + " (" + std::to_string(panel_width("Hierarchy")) + " vs " + std::to_string(atLayoutWidth_) + ")");
        };
        step(2, [check_changed_layout] { check_changed_layout("after the project is opened again"); });
        step(2, [reopen_wait] { reopen_wait(true); });  // through the welcome screen: its context must not wipe the dock data
        step(2, [check_changed_layout] { check_changed_layout("after a visit to the welcome screen"); });
        step(2, [this] { resetLayout_ = true; });
        step(4, [this] {
            at_check(!panel_floating("Console") && panel_node("Console") == panel_node("Project"), "Reset layout puts Console back in the bottom dock");
            at_check(panel_node("Project") != panel_node("Hierarchy"), "...and Project away from the Hierarchy");
            at_check(showFeedback_ && !showAudio_, "...and the panels that are open by default again");
        });
        step(2, [this, reopen_wait] {  // the real layout file again (none in the autotest), through a last reopen
            iniPath_ = atIniSaved_;
            reopen_wait(false);
        });
    }
}

void Editor::at_section_V(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // ------------------------------------------------------------------------------------------------------ U. Reviews
    // A review runs only when its button is pressed: it opens a tab of its own, the reviewer is offered only tools that look
    // and play, the report is saved with its score, and nothing reaches the orchestrator until "Send to orchestrator".
    step(1, [this] {
        atWaitCount_ = 0;
        atWaitUntil_ = [this] { return aiDetected_.load(); };
    });
    step(2, [this, project_file] {
        std::error_code ec;
        stdfs::remove_all(project_file(".factoria/ai/reviews"), ec);
        aiReviewDirty_ = true;
        aiFactory_ = [](const ai::ProviderConfig&) -> Result<std::shared_ptr<ai::ChatProvider>> {
            return std::shared_ptr<ai::ChatProvider>(std::make_shared<ReviewerProvider>());
        };
        {
            std::lock_guard<std::mutex> lock(aiMu_);
            atSavedConfig_ = aiConfig_;
            if (aiConfig_.providers.empty()) aiConfig_ = ai::default_config();
            for (const char* role : {ai::kRoleOrchestrator, ai::kRoleReviewer, ai::kRoleArtCritic}) {
                ai::RoleConfig& rc = aiConfig_.roles[role];
                rc.provider = "anthropic";
                rc.model = "mock";
            }
        }
        while (chat_.tabs.size() > 1) chat_.close(0);
        chat_.clear();
        g_reviewToolsOffered.clear();
        focus_window("AI Assistant");
    });
    step(3, [this] {
        at_check(at_visible("ai:review:game") && at_visible("ai:review:art"), "the AI Assistant has an Art critique and a Game review button");
        at_check(chat().empty() && !ai_busy(), "nothing runs and nothing is asked until a button is pressed");
    });
    click("menu:ai");
    click("menu:ai-roles");
    step(3, [this] {
        at_check(showAiSettings_, "AI > Roles... opens the AI settings window");
        at_check(at_visible("ai:roles:enabled:orchestrator") && !at_enabled("ai:roles:enabled:orchestrator"),
                 "the Roles window shows the orchestrator's Enabled checkbox ticked and disabled");
        at_check(at_visible("ai:roles:enabled:artist") && at_enabled("ai:roles:enabled:artist") &&
                     at_visible("ai:roles:enabled:reviewer"),
                 "...and an Enabled checkbox for the other roles");
    });
    click("ai:roles:enabled:artist");
    step(3, [this] {
        at_check(!aiRolesEdit_[ai::kRoleArtist].enabled && aiRolesEdit_[ai::kRoleWorker].enabled,
                 "unticking Artist turns off that role only");
    });
    click("ai:roles:revert");
    step(3, [this] {
        {
            std::lock_guard<std::mutex> lock(aiMu_);
            at_check(aiConfig_.role_enabled(ai::kRoleArtist), "Revert leaves the configuration alone");
        }
        at_check(aiRolesEdit_[ai::kRoleArtist].enabled, "...and puts the Enabled checkbox back");
        showAiSettings_ = false;
        aiSettings_ = AiSettingsDraft{};
    });
    click("ai:review:game");
    step(3, [this] {
        at_check(at_visible("ai:review:start") && !aiReview_.active && !ai_busy() && chat().empty(),
                 "a review button asks first: nothing runs until Start is pressed");
    });
    click("ai:review:start");
    step(2, [this] {
        atWaitCount_ = 0;
        atWaitUntil_ = [this] { return !aiReview_.active && !ai_busy(); };
    });
    step(4, [this] {
        at_check(!aiReview_.active && !ai_running(), "the review finished");
        const auto saved = ai::list_reviews(projectDir_);
        at_check(saved.size() == 1 && saved[0].role == ai::kRoleReviewer && saved[0].score == 7.5 && saved[0].persona == "all-rounder",
                 "the report was saved with its score and persona (" + std::to_string(saved.size()) + " review(s))");
        at_check(saved.size() == 1 && stdfs::exists(saved[0].path) && saved[0].subScores.size() == 2 &&
                     saved[0].text.find("```") == std::string::npos,
                 "...with its sub-scores and the text without the score block");
        const bool hasLook = std::ranges::find(g_reviewToolsOffered, "scene_list_entities") != g_reviewToolsOffered.end();
        bool hasEdit = false;
        for (const char* t : {"scene_spawn", "fs_write", "scene_set_component", "ai_run", "agent_delegate"})
            hasEdit = hasEdit || std::ranges::find(g_reviewToolsOffered, t) != g_reviewToolsOffered.end();
        at_check(hasLook && !hasEdit, "the reviewer was offered tools that look, and none that change the project");
        bool onlyReview = chat().size() >= 2;
        for (const ChatItem& c : chat())
            if (c.kind == ChatItem::Kind::User) onlyReview = onlyReview && c.role == "review";
        at_check(onlyReview, "the review ran in its own tab: nothing was posted as a message to the orchestrator");
        at_check(aiReviewsShown_, "the AI reviews window opens with the report");
        at_check(play_state() == PlayState::Edit, "the project stays in edit mode");
    });
    snap("editor_ai_review.png");
    click("ai:review:send");
    step(2, [this] {
        atWaitCount_ = 0;
        atWaitUntil_ = [this] { return !ai_busy(); };
    });
    step(4, [this] {
        const AiChat& cur = chat_.current();
        bool sent = false;
        for (const ChatItem& c : cur.items)
            sent = sent || (c.kind == ChatItem::Kind::User && c.role != "review" && c.text.find("7.5") != std::string::npos);
        at_check(sent, "Send to orchestrator posts the report as a user message into an orchestrator chat");
        at_check(chat_.tabs.size() >= 2, "...in a new tab, because the active one was the review's own");
        std::error_code ec;
        stdfs::remove_all(projectDir_ + "/.factoria/ai/reviews", ec);
        aiReviewDirty_ = true;
        aiReviewsShown_ = false;
        aiFactory_ = nullptr;
        if (atSavedConfig_) {
            std::lock_guard<std::mutex> lock(aiMu_);
            aiConfig_ = std::move(*atSavedConfig_);
            atSavedConfig_.reset();
        }
        while (chat_.tabs.size() > 1) chat_.close(0);
        chat_.clear();
        focus_window("###Viewport");
    });
}

void Editor::at_section_W(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // ----------------------------------------------------------------------- W. Several AI chats at the same time
    // Two chats run at once against a scripted model that writes the same file and spawns a coin in both: both finish with their
    // own results, each chat is warned that the other changed the same file, Play names the chats that work, a third chat is
    // held back by limits.maxConcurrentRuns, Revert of one run keeps the other's changes. Then Stop on one run leaves the other going.
    {
        struct VState {
            std::string a, b, c;
        };
        auto v = std::make_shared<VState>();
        auto reset_chats = [this] {  // one blank tab, nothing of the previous scenario saved
            for (int i = static_cast<int>(chat_.tabs.size()) - 1; i >= 0; --i) {
                chat_.select(i);
                chat_.clear();
            }
            while (chat_.tabs.size() > 1) chat_.close(static_cast<int>(chat_.tabs.size()) - 1);
            aiTabForce_ = 2;
        };
        auto info_warnings = [](const AiChat* c) {
            int n = 0;
            for (const ChatItem& it : c->items)
                n += it.kind == ChatItem::Kind::Info && it.isError && it.text.find("also changed") != std::string::npos ? 1 : 0;
            return n;
        };
        auto said = [](const AiChat* c, const std::string& text) {
            for (const ChatItem& it : c->items)
                if (it.kind == ChatItem::Kind::Assistant && it.text.find(text) != std::string::npos) return true;
            return false;
        };
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return aiDetected_.load(); };
        });
        step(2, [this, v, project_file, reset_chats] {
            write_file(project_file("scripts/u_shared.js"), "old\n");
            std::error_code ec;
            for (const char* f : {"scripts/u_a.js", "scripts/u_b.js", "scripts/u_l.js", "scripts/u_s.js"}) stdfs::remove(project_file(f), ec);
            aiFactory_ = [](const ai::ProviderConfig&) -> Result<std::shared_ptr<ai::ChatProvider>> {
                return std::shared_ptr<ai::ChatProvider>(std::make_shared<ConcurrentProvider>());
            };
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                atSavedConfig_ = aiConfig_;
                if (aiConfig_.providers.empty()) aiConfig_ = ai::default_config();
                ai::RoleConfig& orchestrator = aiConfig_.roles[ai::kRoleOrchestrator];
                orchestrator.provider = "anthropic";
                if (orchestrator.model.empty()) orchestrator.model = "mock";
                aiConfig_.limits.maxConcurrentRuns = 2;
            }
            reset_chats();
            focus_window("AI Assistant");
            ai_start("Probe A [A]");
            v->a = chat_.current().id;
            chat_.add(static_cast<i64>(std::time(nullptr)));
            ai_start("Probe B [B]");
            v->b = chat_.current().id;
            chat_.add(static_cast<i64>(std::time(nullptr)));
            ai_start("Probe C [A]");  // the third: no slot
            v->c = chat_.current().id;
            aiTabForce_ = 2;
        });
        step(3, [this, v] {
            at_check(ai_run_count() == 2 && ai_chat_running(v->a) && ai_chat_running(v->b), "two chats run at the same time");
            at_check(!ai_chat_running(v->c) && chat_.find(v->c) && chat_.find(v->c)->items.empty(),
                     "a third chat is held back by limits.maxConcurrentRuns (it did not start, its message was not sent)");
            play();
            at_check(play_state() == PlayState::Edit, "Play waits while the assistant edits");
            const std::string note = ai_editing_note();
            at_check(note.find("Probe A") != std::string::npos && note.find("Probe B") != std::string::npos,
                     "...and the note names the chats that work: " + note);
        });
        step(2, [this] {
            atWaitAi_ = true;
            atWaitCount_ = 0;
        });
        step(3, [this, v, project_file, info_warnings, said] {
            at_check(!ai_running(), "both scripted runs finished");
            const AiChat* a = chat_.find(v->a);
            const AiChat* b = chat_.find(v->b);
            if (!a || !b) {
                at_check(false, "both chats are still open");
                return;
            }
            at_check(said(a, "Finished A") && !said(a, "Finished B") && said(b, "Finished B") && !said(b, "Finished A"),
                     "each chat has its own run's answer");
            at_check(a->usage.inputTokens > 0 && b->usage.inputTokens > 0, "each chat counted its own tokens");
            at_check(info_warnings(a) >= 1 && info_warnings(b) >= 1,
                     "each chat is warned that the other changed the same file (" + std::to_string(info_warnings(a)) + ", " +
                         std::to_string(info_warnings(b)) + ")");
            auto names = [&](const AiChat* c, const char* other, const char* file) {
                bool named = false, file_listed = false;
                for (const ChatItem& it : c->items) {
                    if (it.kind != ChatItem::Kind::Info || !it.isError) continue;
                    named = it.text.find(other) != std::string::npos;
                    file_listed = file_listed || it.text.find(file) != std::string::npos;
                }
                return named && file_listed;
            };
            at_check(names(a, "Probe B", "scripts/u_shared.js") && names(b, "Probe A", "scripts/u_shared.js"),
                     "...each warning names the other chat and the shared file");
            const ChatItem* ra = nullptr;
            const ChatItem* rb = nullptr;
            for (const ChatItem& it : a->items)
                if (it.kind == ChatItem::Kind::Run) ra = &it;
            for (const ChatItem& it : b->items)
                if (it.kind == ChatItem::Kind::Run) rb = &it;
            auto has = [](const std::vector<std::string>& list, const char* f) { return std::ranges::find(list, f) != list.end(); };
            at_check(ra && rb && has(ra->added, "scripts/u_a.js") && has(ra->modified, "scripts/u_shared.js") &&
                         !has(ra->added, "scripts/u_b.js") && has(rb->added, "scripts/u_b.js") && !has(rb->added, "scripts/u_a.js"),
                     "each Run item lists its own files, not the other chat's");
            at_check(!world().find("UCoinA").is_null() && !world().find("UCoinB").is_null(), "both runs' coins are in the scene");
            at_check(!read_file(project_file("scripts/u_a.js")).empty() && !read_file(project_file("scripts/u_b.js")).empty(),
                     "both runs' files are on disk");
            chat_.select(chat_.index_of(v->a));
            aiTabForce_ = 2;
        });
        step(3, [] {});
        scroll_to("ai:revert", "AI Assistant");  // A's warnings push it below the fold of a small display
        click("ai:revert");
        step(4, [this] {
            at_check(at_visible("ai:revert:confirm") && at_visible("ai:revert:confirm-all"),
                     "Revert of A asks, and offers to keep the other chat's changes or take those files back too");
        });
        click("ai:revert:confirm");
        step(6, [this, v, project_file] {
            at_check(!stdfs::exists(project_file("scripts/u_a.js")), "Revert of A removes the file only A added");
            at_check(stdfs::exists(project_file("scripts/u_b.js")), "...and leaves the file B added");
            at_check(read_file(project_file("scripts/u_shared.js")) != "old\n", "...and the file both changed stays as it is now");
            at_check(!world().find("UCoinA").is_null() && !world().find("UCoinB").is_null(),
                     "...and the scene stays too, since B edited it as well");
            const AiChat* a = chat_.find(v->a);
            bool scoped = false;
            if (a)
                for (const ChatItem& it : a->items) scoped = scoped || (it.kind == ChatItem::Kind::Revert && it.scoped);
            at_check(scoped, "A's transcript says only some files went back");
        });
        // Stop on one run leaves the other going.
        step(2, [this, v, project_file, reset_chats] {
            std::error_code ec;
            stdfs::remove(project_file("scripts/u_l.js"), ec);
            reset_chats();
            ai_start("Probe S [S]");
            v->a = chat_.current().id;
            chat_.add(static_cast<i64>(std::time(nullptr)));
            ai_start("Probe L [L]");
            v->b = chat_.current().id;
            chat_.select(chat_.index_of(v->a));
            aiTabForce_ = 2;
            atWaitCount_ = 0;
            atWaitUntil_ = [this, v] { return ai_chat_running(v->a) && ai_chat_running(v->b); };
        });
        step(3, [] {});
        click("ai:stop");
        step(2, [this, v] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this, v] { return !ai_chat_running(v->a); };
        });
        step(3, [this, v] {
            at_check(!ai_chat_running(v->a), "Stop ends the run of the chat it is pressed in");
            at_check(ai_chat_running(v->b), "...and the other chat's run goes on");
            atWaitAi_ = true;
            atWaitCount_ = 0;
        });
        step(3, [this, v, project_file, info_warnings, said] {
            const AiChat* b = chat_.find(v->b);
            at_check(b && said(b, "Finished L") && info_warnings(b) == 0, "the other run finished with its own result and no false warning");
            at_check(read_file(project_file("scripts/u_l.js")) == "only L\n", "...and its file is on disk");
            at_check(!stdfs::exists(project_file("scripts/u_s.js")), "the stopped run wrote nothing");
            at_check(!ai_running() && !ai_busy(), "no run is left");
            std::error_code ec;
            for (const char* f : {"scripts/u_shared.js", "scripts/u_a.js", "scripts/u_b.js", "scripts/u_l.js"}) stdfs::remove(project_file(f), ec);
            aiFactory_ = nullptr;
            if (atSavedConfig_) {
                std::lock_guard<std::mutex> lock(aiMu_);
                aiConfig_ = std::move(*atSavedConfig_);
                atSavedConfig_.reset();
            }
        });
        step(2, [this, reset_chats] {
            reset_chats();
            focus_window("###Viewport");
        });
    }
}

}  // namespace fa::editor
