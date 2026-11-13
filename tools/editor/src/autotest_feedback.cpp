// Autotest sections E2, E4 and R2: feedback sharing, rejected feedback and the retrospective.
// Split from autotest_tools.cpp: each section is an Editor::at_section_<id>(AtScript&) that adds its steps to the script,
// called by at_build_tools_script in the order of the full run (autotest_sections.h).
#include <algorithm>
#include <cctype>
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
#include "ui_backend.h"

namespace fa::editor {

using namespace at_support;

namespace {

namespace stdfs = std::filesystem;

// Section R2's scripted "model" for the retrospective: whatever it is asked, it answers with one efficiency entry for the candidate
// whose pattern is "failure" (the one transcript the section writes: scene.load failing with not_found), the way the fast role is asked to.
class RetrospectiveProvider : public ai::ChatProvider {
public:
    std::string name() const override { return "mock"; }
    Result<ai::ChatResponse> chat(const ai::ChatRequest& req, const ai::ChatHooks&, const ai::CancelFlag*) override {
        ai::ChatResponse r;
        r.message.role = ai::Role::Assistant;
        r.message.raw = Json::object();
        r.usage.inputTokens = 1200;
        r.usage.outputTokens = 200;
        // The prompt names the candidates c1, c2...; the one whose pattern is "failure" is the one to write up.
        std::string candidate = "c1";
        for (const ai::Message& m : req.messages) {
            const std::size_t at = m.text.find("  pattern: failure");
            const std::size_t line = at == std::string::npos ? at : m.text.rfind("\nc", at);
            if (line != std::string::npos) {
                candidate = "c" + std::to_string(std::atoi(m.text.c_str() + line + 2));
                break;
            }
        }
        const Json entry = Json::object(
            {{"candidate", candidate},
             {"category", "scene"},
             {"title", "Loading a scene by name keeps failing with not_found"},
             {"suggestion", "A scene guide that lists how scene names resolve to files before the first load"},
             {"waste", "Every load guessed a name and failed, so the run repeated the same call many times"},
             {"fixType", "guide"},
             {"appliesTo", "every-game"},
             {"saveShare", 0.9},
             {"saveWhy", "the guide gives the name rule"},
             {"whyNotCheaper", ""},
             {"searched", Json::array()},
             {"factLine", ""}});
        r.message.text = Json::object({{"entries", Json::array({entry})}, {"facts", Json::array()}}).dump();
        r.stopReason = ai::StopReason::EndTurn;
        return r;
    }
};

// Section E2's reviewer of a share text (the Send feedback window checks the texts it is about to send). It answers by what the text
// says: "glow" is something the engine already does (the check fails and says how to fix it), "gradient" passes with the text
// rewritten in engine terms, anything else passes as it is.
class ShareReviewProvider : public ai::ChatProvider {
public:
    std::string name() const override { return "mock"; }
    Result<ai::ChatResponse> chat(const ai::ChatRequest& req, const ai::ChatHooks& hooks,
                                  const ai::CancelFlag*) override {
        ai::ChatResponse r;
        r.message.role = ai::Role::Assistant;
        r.message.raw = Json::object();
        std::string asked = req.messages.empty() ? std::string() : req.messages.back().text;
        if (const std::size_t at = asked.find("## The share text to check"); at != std::string::npos)
            asked = asked.substr(at);
        for (char& c : asked) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
        const bool glow = asked.find("glow") != std::string::npos;
        const bool gradient = asked.find("gradient") != std::string::npos;
        std::string text =
            std::string("{\"real\":{\"ok\":") + (glow ? "false" : "true") + ",\"why\":\"" +
            (glow ? "The docs already list a bloom effect for lights." : "The docs list no way to do this.") +
            "\"},"
            "\"aboutEngine\":{\"ok\":true,\"why\":\"It names an engine feature only.\"},"
            "\"notPossibleYet\":{\"ok\":true,\"why\":\"No command or component does it.\",\"use\":\"\"},";
        if (gradient)
            text += "\"share\":{\"title\":\"SpriteRenderer lacks gradient tinting\","
                    "\"missing\":\"SpriteRenderer only has a flat tint color, so a gradient across one sprite needs a "
                    "custom material.\","
                    "\"suggestion\":\"Add a gradient field to SpriteRenderer.\"},";
        else
            text += "\"share\":null,";
        text += std::string("\"fix\":\"") + (glow ? "Use the bloom effect the engine already has." : "") + "\"}";
        r.message.text = text;
        if (hooks.onText) hooks.onText(r.message.text);
        r.stopReason = ai::StopReason::EndTurn;
        return r;
    }
};

}  // namespace

void Editor::at_section_E2(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // Feedback sharing (docs/EDITOR.md, "Feedback sharing"): the consent dialog (also what Send feedback shows while no mode is
    // chosen), the Send feedback window (every entry that would go, checked by default, with the exact text; a text without a share
    // is made from the entry; an AI check of each text against a mock model; uncheck, Send and Cancel), the Add feedback window,
    // the panel's share column, the closed entries going to the archive, Feedback Settings (GitHub sign-in with a code on screen,
    // sign-out, reset id, Send now against a server that is down and then up) and the mode radio buttons. The client talks to the
    // fake server of on_init: no network, and the settings and the outbox live in the autotest's own folder.
    {
        struct EState {
            std::string path, installBefore, alwaysId, projectSentId, projectAskId, projectAskKey;
            size_t reportsBeforeAsk = 0;
            std::optional<ai::AiConfig> savedConfig;
            ImGuiID row = 0,
                    sibling = 0;  // the dock row of the panel made taller for this section, and the one it took from
            float grown = 0;
            size_t reportsAtCancel = 0;
            stdfs::file_time_type stampBeforeAgent{};  // the file's time before the agent's writes, set back after them
            stdfs::file_time_type
                stampBeforePanelWrite{};  // the file's time before a write right after the panel's read
            std::string panelTitle;       // the first entry's title before that write
        };
        auto x = std::make_shared<EState>();
        // The bottom row of the dock gives the panel under 200 px on a small display (the macOS runner's 1024x642), where the
        // table leaves the detail a few pixels: the row grows to 440 px for this section and gets its height back after.
        auto grow_panel_row = [x](bool grow) {
            if (!grow) {
                ImGuiDockNode* row = ImGui::DockBuilderGetNode(x->row);
                ImGuiDockNode* sib = ImGui::DockBuilderGetNode(x->sibling);
                if (row && sib) row->SizeRef.y -= x->grown, sib->SizeRef.y += x->grown;
                x->grown = 0;
                return;
            }
            const ImGuiWindow* w = panel_window("Engine Feedback");
            ImGuiDockNode* row = w ? w->DockNode : nullptr;
            while (row && row->ParentNode && row->ParentNode->SplitAxis != ImGuiAxis_Y) row = row->ParentNode;
            if (!row || !row->ParentNode) return;  // floating: it has its own size
            ImGuiDockNode* sib =
                row->ParentNode->ChildNodes[0] == row ? row->ParentNode->ChildNodes[1] : row->ParentNode->ChildNodes[0];
            if (!sib) return;
            x->grown = std::clamp(440.0f - row->Size.y, 0.0f, std::max(0.0f, sib->Size.y - 120.0f));
            x->row = row->ID;
            x->sibling = sib->ID;
            row->SizeRef.y += x->grown;
            sib->SizeRef.y -= x->grown;
        };
        auto entry_of = [x](const std::string& id) -> Json {
            auto doc = load_feedback(x->path);
            if (doc && doc->contains("entries"))
                for (const Json& e : (*doc)["entries"])
                    if (e.value("id", std::string()) == id) return e;
            return Json::object();
        };
        auto shared_of = [entry_of](const std::string& id) {
            const Json e = entry_of(id);
            return e.contains("shared") ? e["shared"].value("status", std::string()) : std::string();
        };
        auto reports = [this] {
            std::lock_guard<std::mutex> lock(atShareNet_->mu);
            return atShareNet_->reportBodies.size();
        };
        auto all_reports = [this] {
            std::lock_guard<std::mutex> lock(atShareNet_->mu);
            std::string all;
            for (const std::string& b : atShareNet_->reportBodies) all += b;
            return all;
        };
        auto send_row = [this](const std::string& id) -> const ShareUi::SendRowUi* {
            for (const ShareUi::SendRowUi& r : share_.sendRows)
                if (r.row.id == id) return &r;
            return nullptr;
        };
        auto add_entry = [x](const std::string& title, const std::string& missing, const Json& share) {
            FeedbackInput in;
            in.category = feedback_categories().front();
            in.severity = "minor";
            in.title = title;
            in.missing = missing;
            in.workaround = "Edited the scene file by hand.";
            in.reporter = Json::object({{"kind", "human"}, {"agent", "factoria-editor"}});
            in.share = share;
            auto r = add_feedback_entry_to_file(x->path, in, "Autotest Platformer");
            return r ? r->id : std::string();
        };
        auto wait_until = [this, &step](std::function<bool()> cond) {
            step(1, [this, cond] {
                atWaitCount_ = 0;
                atWaitUntil_ = cond;
            });
        };
        step(2, [this, x, add_entry] {
            x->path = projectDir_ + "/" + engine_->project().feedbackFile;
            std::error_code ec;
            stdfs::remove(x->path, ec);
            stdfs::remove(projectDir_ + "/ENGINE_FEEDBACK.archive.json", ec);
            const ShareEnv& env = share_env();
            ShareSettings st = load_share_settings(env);
            st.mode = ShareMode::
                Unset;  // the harness starts the dialog's story: nothing chosen yet (only a click sets a mode in the product)
            (void)save_share_settings(env, st);
            (void)save_outbox(env, Outbox{});
            {
                std::lock_guard<std::mutex> lock(atShareNet_->mu);
                atShareNet_->urls.clear();
                atShareNet_->reportBodies.clear();
            }
            atShareNet_->authorize = false;
            atShareNet_->failReports = false;
            // No AI model for the first part: the Send window shows its texts as they are. (A dev machine's own key or CLI is never used.)
            aiFactory_ = [](const ai::ProviderConfig&) -> Result<std::shared_ptr<ai::ChatProvider>> {
                return make_error("The autotest has no AI model for the share check.",
                                  "Section E2 gives it one later.");
            };
            ShareUi& s = share_;
            s.consentOpen = s.consentLater = s.settingsOpen = s.sendOpen = false;
            s.sendLive = 0;
            s.sendAfterConsent = false;
            s.sendRows.clear();
            s.waiting.clear();
            s.notified.clear();
            s.mode = ShareMode::Unset;
            s.docFile.clear();
            s.docStamp = INT64_MIN;
            s.tickAt = -10;
            const Json one = Json::object({{"title", "No ladder climbing"},
                                           {"missing", "Nothing lets a body climb a vertical surface: a player cannot "
                                                       "go up a wall the way a ladder would allow."},
                                           {"suggestion", "Add a climbable surface type."}});
            const Json two = Json::object(
                {{"title", "Pause cannot stop particles"},
                 {"missing",
                  "ParticleEmitter keeps emitting while the game is paused and there is no way to freeze it."}});
            add_entry("Jump-through platforms are impossible",
                      "The player of SecretLevelName cannot jump up through its platforms.", one);
            add_entry("Pause menu cannot freeze particles", "Particles keep running in SecretLevelName while paused.",
                      two);
            add_entry("Autotest Platformer needs a screen shake helper",
                      "The Autotest Platformer game has no helper to shake the screen after a hit, so every script "
                      "rolls its own.",
                      Json());
            fbSelected_.clear();
            fbAddOpen_ = false;
            feedbackMtime_ = INT64_MIN;
            feedbackPolled_ = -10;
            showFeedback_ = true;
            focus_window("Engine Feedback");
        });
        step(2, [grow_panel_row] { grow_panel_row(true); });
        // ---- the consent dialog
        wait_until([this] { return share_.consentOpen; });
        step(3, [this] {
            at_check(
                at_visible("share:consent:always") && at_visible("share:consent:ask") &&
                    at_visible("share:consent:never") && at_visible("share:consent:later"),
                "a project with feedback entries and no answer asks: Always, Ask me each time, Never and Decide later");
            at_check(share_.consentEntries == 3 &&
                         share_.consentPreview.find("No ladder climbing") != std::string::npos &&
                         share_.consentPreview.find("Pause cannot stop particles") != std::string::npos,
                     "the dialog previews the next report: the texts of the three entries (the third one made from the "
                     "entry)");
            at_check(share_.consentPreview.find("SecretLevelName") == std::string::npos &&
                         share_.consentPreview.find("Edited the scene") == std::string::npos &&
                         share_.consentPreview.find("Autotest Platformer") == std::string::npos,
                     "...without the entries' own text, the project's name or its workaround");
            at_check(load_share_settings(share_env()).mode == ShareMode::Unset, "nothing is chosen until a click");
            std::lock_guard<std::mutex> lock(atShareNet_->mu);
            at_check(atShareNet_->urls.empty(), "the dialog sends nothing");
        });
        snap("editor_share_consent.png");
        click("share:consent:later");
        step(3, [this] {
            at_check(!share_.consentOpen && load_share_settings(share_env()).mode == ShareMode::Unset,
                     "Decide later closes the dialog and chooses nothing");
        });
        // ---- Send feedback while no mode is chosen: the dialog first, then the window
        wait_until([this] { return at_enabled("feedback:send") && at_visible("feedback:table"); });
        step(2, [this] {
            at_check(
                at_visible("feedback:add") && at_visible("feedback:row:FB-0001") &&
                    at_visible("feedback:row:FB-0002") && at_visible("feedback:row:FB-0003") &&
                    at_visible("feedback:share:FB-0003"),
                "the panel has Add feedback and Send feedback, and its table shows every entry with its share column");
            at_check(!at_visible("feedback:share:suggest") && !at_visible("feedback:settings") &&
                         !at_visible("feedback:archive"),
                     "...and no share editor, Sharing... or Archive closed button");
        });
        click("feedback:send");
        step(3, [this] {
            at_check(share_.consentOpen && share_.sendAfterConsent && !share_.sendOpen,
                     "Send feedback with no mode chosen asks first");
        });
        click("share:consent:ask");
        wait_until([this] { return share_.sendOpen && at_visible("send:check:FB-0001"); });
        // The AI check answers from a thread; with no AI set up it says so after the local servers refused to connect (slow
        // on Windows, where a refused connection is retried for a while).
        wait_until([this] {
            if (share_.sendAiAvailable || at_visible("send:reviewing:FB-0001")) return false;
            for (const ShareUi::SendRowUi& r : share_.sendRows)
                if (r.review == ShareUi::SendReview::Queued) return false;
            return true;
        });
        // ---- the Send feedback window
        step(3, [this, send_row, reports] {
            at_check(load_share_settings(share_env()).mode == ShareMode::Ask && !share_.consentOpen,
                     "Ask me each time writes the mode and the Send window opens");
            at_check(at_visible("send:check:FB-0002") && at_visible("send:check:FB-0003") && at_visible("send:ok") &&
                         at_visible("send:cancel"),
                     "the window lists the three open entries, each with a checkbox, and Send and Cancel");
            bool allChecked = true;
            for (const char* id : {"FB-0001", "FB-0002", "FB-0003"})
                allChecked = allChecked && send_row(id) && send_row(id)->checked;
            at_check(allChecked, "all of them are checked by default");
            const ShareUi::SendRowUi* three = send_row("FB-0003");
            at_check(three && three->row.madeHere &&
                         three->row.fields.title.find("Autotest Platformer") == std::string::npos &&
                         !three->row.fields.title.empty() && at_visible("send:text:FB-0003"),
                     "FB-0003 has no share text: its row shows the text made from the entry, with the project's name "
                     "taken out");
            std::string seen = std::string("sendAiAvailable=") + (share_.sendAiAvailable ? "true" : "false") +
                               ", reviewing shown=" + (at_visible("send:reviewing:FB-0001") ? "yes" : "no") +
                               ", review shown=" + (at_visible("send:review:FB-0001") ? "yes" : "no");
            for (const ShareUi::SendRowUi& r : share_.sendRows)
                seen += "; " + r.row.id + " review " + std::to_string(int(r.review)) +
                        (r.reviewNote.empty() ? "" : " '" + r.reviewNote + "'");
            at_check(!at_visible("send:reviewing:FB-0001") && !at_visible("send:review:FB-0001") &&
                         share_.sendAiAvailable == false,
                     "with no AI set up the texts are shown as they are, without a word about it (" + seen + ")");
            at_check(reports() == 0, "opening the window sends nothing");
        });
        snap("editor_share_send.png");
        click("send:check:FB-0001");
        step(3, [this, send_row, shared_of, entry_of] {
            at_check(send_row("FB-0001") && !send_row("FB-0001")->checked && send_row("FB-0002")->checked,
                     "the checkbox unchecks one entry");
            at_check(shared_of("FB-0001") != "skipped" && !entry_of("FB-0003").contains("share"),
                     "...and changes nothing in the file yet");
        });
        click("send:ok");
        step(1, [this, shared_of] {
            atWaitCount_ = 0;
            atWaitUntil_ = [shared_of] { return shared_of("FB-0002") == "sent" && shared_of("FB-0003") == "sent"; };
            atWaitWhat_ = "Send to write shared=sent into the file for FB-0002 and FB-0003";
        });
        step(3, [this, entry_of, shared_of, reports, all_reports, send_row] {
            const std::string body = all_reports();
            at_check(reports() >= 1 && body.find("Pause cannot stop particles") != std::string::npos &&
                         body.find("FB-0002") != std::string::npos && body.find("FB-0003") != std::string::npos,
                     "Send sends the checked entries");
            at_check(body.find("FB-0001") == std::string::npos &&
                         body.find("No ladder climbing") == std::string::npos &&
                         body.find("SecretLevelName") == std::string::npos &&
                         body.find("Edited the scene") == std::string::npos &&
                         body.find("Autotest Platformer") == std::string::npos,
                     "...and nothing of the unchecked one, the entries' own text or the project's name");
            at_check(shared_of("FB-0001") == "skipped", "the unchecked entry is marked skipped");
            const Json three = entry_of("FB-0003");
            at_check(three.contains("share") &&
                         three["share"].value("title", std::string()) ==
                             (send_row("FB-0003") ? send_row("FB-0003")->row.fields.title : std::string("?")),
                     "the text made for FB-0003 was stored in its entry when it was sent (" +
                         three.value("share", Json::object()).dump() + ")");
            at_check(load_share_settings(share_env()).mode == ShareMode::Ask, "sending changed no setting");
            at_check(at_visible("send:result:FB-0002") && at_visible("send:result:FB-0003") &&
                         at_visible("send:close") && !at_visible("send:ok"),
                     "each sent row says what happened, and the window offers Close");
            at_check(share_column(entry_of("FB-0001")).label == "skipped" &&
                         share_column(entry_of("FB-0002")).label == "sent" &&
                         share_column(entry_of("FB-0003")).label == "sent",
                     "the share column reads skipped, sent and sent (the file says shared = '" + shared_of("FB-0001") +
                         "', '" + shared_of("FB-0002") + "', '" + shared_of("FB-0003") + "')");
        });
        click("send:close");
        step(3, [this] { at_check(!share_.sendOpen && !at_visible("send:close"), "Close closes the window"); });
        // ---- Add feedback: Cancel saves nothing, Add checks the form and adds the entry
        click("feedback:add");
        step(3, [this] {
            at_check(share_.sendOpen == false && fbAddOpen_ && at_visible("add:category") &&
                         at_visible("add:severity") && at_visible("add:title") && at_visible("add:missing") &&
                         at_visible("add:workaround") && at_visible("add:suggestion") && at_visible("add:ok") &&
                         at_visible("add:cancel"),
                     "Add feedback opens a window with category, severity, title, what is missing, workaround, "
                     "suggestion, Add and Cancel");
            at_check(!at_visible("add:share") && !at_visible("add:share:title"), "...and no share boxes");
            fbNewTitle_ = "This one is cancelled";
            fbNewMissing_ = "Typed and then cancelled.";
        });
        snap("editor_feedback_add.png");
        click("add:cancel");
        step(3, [this, entry_of] {
            at_check(!fbAddOpen_ && !at_visible("add:ok") && fbNewTitle_.empty() && fbNewMissing_.empty(),
                     "Cancel closes the window and forgets the form");
            at_check(!entry_of("FB-0004").is_object() || entry_of("FB-0004").empty(), "...and saved nothing");
        });
        click("feedback:add");
        wait_until([this] { return at_visible("add:ok"); });
        click("add:ok");
        step(3, [this] {
            at_check(fbAddOpen_ && at_visible("add:message") && fbMessage_.find("Fill in the title") == 0,
                     "Add with an empty form says what is lacking (" + fbMessage_ + ")");
            fbNewTitle_ = "Sprites cannot be tinted by a gradient";
            fbNewMissing_ =
                "SpriteRenderer only has a flat tint color, so a gradient across one sprite needs a custom material.";
            fbNewWorkaround_ = "Split the sprite in strips and tint each one.";
        });
        click("add:ok");
        step(3, [this, entry_of] {
            const Json e = entry_of("FB-0004");
            at_check(!fbAddOpen_ && e.value("title", std::string()) == "Sprites cannot be tinted by a gradient" &&
                         !e.contains("share") && e.value("status", std::string()) == "open",
                     "Add stores the entry, closes the window and writes no share text");
            at_check(fbSelected_ == "FB-0004", "...and selects the new entry");
            at_check(!entry_of("FB-0005").is_object() || entry_of("FB-0005").empty(), "the cancelled one is not there");
        });
        // ---- the panel reads a file that changed right after its last read, within one step of the file clock (about 15 ms on
        // Windows, and the Windows file rules of fa::fs everywhere else): the time the write leaves is the one the read saw.
        step(1, [this] {
            feedbackMtime_ = INT64_MIN;
            feedbackPolled_ = -10;
        });
        wait_until([this] {
            return feedbackMtime_ == fs::modified_time(engine_->project().feedbackFile) && feedbackRecheck_;
        });
        step(1, [this] {
            at_check(feedbackMtime_ == fs::modified_time(engine_->project().feedbackFile) && feedbackRecheck_,
                     "the panel has read the file and will read it once more");
        });
        step(2, [this, x] {
            std::error_code ec;
            x->stampBeforePanelWrite = stdfs::last_write_time(x->path, ec);
            auto doc = load_json_file(x->path);
            at_check(doc.ok() && doc->contains("entries") && !(*doc)["entries"].empty(),
                     "the feedback file can be read back");
            if (!doc.ok() || !doc->contains("entries") || (*doc)["entries"].empty()) return;
            x->panelTitle = (*doc)["entries"][0].value("title", std::string());
            (*doc)["entries"][0]["title"] = "Written right after the panel read";
            at_check(fs::write_text(engine_->project().feedbackFile, doc->dump(2)).ok(),
                     "the feedback file can be rewritten");
            stdfs::last_write_time(x->path, x->stampBeforePanelWrite, ec);  // the time the panel's read saw
            at_check(!ec, "the file's time can be set back (" + ec.message() + ")");
            feedbackPolled_ = -10;
        });
        wait_until([this] {
            return feedbackDoc_.contains("entries") && !feedbackDoc_["entries"].empty() &&
                   feedbackDoc_["entries"][0].value("title", std::string()) == "Written right after the panel read";
        });
        step(1, [this] {
            at_check(feedbackDoc_.contains("entries") && !feedbackDoc_["entries"].empty() &&
                         feedbackDoc_["entries"][0].value("title", std::string()) ==
                             "Written right after the panel read",
                     "the panel lists a write made right after its last read, though the file's time did not move");
        });
        // The title is put back until the file has it: on Windows the read can meet the share tick replacing the file (a
        // sharing violation), and a tick that read the file before this write can write its older copy over it.
        auto restore_title = [this, x] {
            auto doc = load_json_file(x->path);
            if (!doc.ok() || !doc->contains("entries") || (*doc)["entries"].empty()) return;
            if ((*doc)["entries"][0].value("title", std::string()) == x->panelTitle) return;
            (*doc)["entries"][0]["title"] = x->panelTitle;
            (void)fs::write_text(engine_->project().feedbackFile, doc->dump(2));
            feedbackPolled_ = -10;
        };
        step(2, [restore_title] { restore_title(); });
        wait_until([this, x, restore_title] {
            if (feedbackDoc_.contains("entries") && !feedbackDoc_["entries"].empty() &&
                feedbackDoc_["entries"][0].value("title", std::string()) == x->panelTitle)
                return true;
            if (atWaitCount_ % 30 == 29) restore_title();
            return false;
        });
        step(1, [this, x] {
            at_check(feedbackDoc_.contains("entries") && !feedbackDoc_["entries"].empty() &&
                         feedbackDoc_["entries"][0].value("title", std::string()) == x->panelTitle,
                     "the panel lists the first entry as it was again");
        });
        // ---- the AI checks the texts: a pass with a rewrite, a fail that unchecks the row, a text that cannot be made
        // The share tick has just read the file as it is now (a change it saw, so one more read is due)...
        step(1, [this] {
            share_.docStamp = INT64_MIN;
            share_.tickAt = -10;
        });
        wait_until([this, x] {
            // the time the share tick compares (fs::modified_time: stepped like Windows' under the file rules)
            return share_.docStamp == fs::host_modified_time(x->path) && share_.docRecheck;
        });
        step(2, [this, x, add_entry] {
            std::error_code ec;
            x->stampBeforeAgent = stdfs::last_write_time(x->path, ec);
            aiFactory_ = [](const ai::ProviderConfig&) -> Result<std::shared_ptr<ai::ChatProvider>> {
                return std::shared_ptr<ai::ChatProvider>(std::make_shared<ShareReviewProvider>());
            };
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                x->savedConfig = aiConfig_;
                if (aiConfig_.providers.empty()) aiConfig_ = ai::default_config();
                for (const char* role : {ai::kRoleOrchestrator, ai::kRoleFast}) {
                    ai::RoleConfig& rc = aiConfig_.roles[role];
                    rc.provider = "anthropic";
                    rc.model = "mock";
                }
            }
            // an AI agent's report: it wrote a share text, which the AI check will refuse (the engine already does it)
            add_entry("Lights cannot glow through walls", "A lantern behind a wall shows no light on this side.",
                      Json::object({{"title", "Lights cannot glow through walls"},
                                    {"missing",
                                     "There is no option to let a lantern light glow past the colliders of a wall."}}));
            // a report with so little text that no share text can be made from it
            add_entry("Odd thing", "Odd one", Json());
            // ...and the agent's writes right after that read keep the time the read saw, as writes within one step of the file
            // clock do on Windows (about 15 ms): the tick must still see them.
            stdfs::last_write_time(x->path, x->stampBeforeAgent, ec);
            at_check(!ec, "the file's time can be set back (" + ec.message() + ")");
        });
        wait_until([this] { return at_visible("share:notify"); });
        click("share:notify");
        wait_until(
            [this] { return share_.sendOpen && at_visible("send:check:FB-0004") && at_visible("send:check:FB-0001"); });
        wait_until([this] {
            return !share_.aiRunning && at_visible("send:review:FB-0004") && at_visible("send:review:FB-0005");
        });
        step(3, [this, send_row] {
            const ShareUi::SendRowUi* gradient = send_row("FB-0004");
            const ShareUi::SendRowUi* glow = send_row("FB-0005");
            at_check(gradient && gradient->checked && gradient->rewritten &&
                         gradient->row.fields.title == "SpriteRenderer lacks gradient tinting" &&
                         gradient->reviewNote.find("rewritten") != std::string::npos,
                     "an AI check that passes with a rewrite replaces the text of the row" +
                         (gradient ? " (" + gradient->reviewNote + ")" : std::string()));
            at_check(glow && !glow->checked && glow->review == ShareUi::SendReview::Failed &&
                         glow->reviewNote.find("bloom") != std::string::npos,
                     "an AI check that fails unchecks the row and shows why" +
                         (glow ? " (" + glow->reviewNote + ")" : std::string()));
            const ShareUi::SendRowUi* one = send_row("FB-0001");
            at_check(one && !one->checked && one->row.leftOut && at_visible("send:text:FB-0001"),
                     "an entry left out last time is listed again, unchecked, and was not sent to the AI check");
            const ShareUi::SendRowUi* odd = send_row("FB-0006");
            at_check(
                odd && !odd->row.canSend && !odd->checked && at_visible("send:problem:FB-0006") &&
                    !at_enabled("send:check:FB-0006") && !send_row("FB-0002") && !send_row("FB-0003"),
                "a text that cannot be made is unchecked and disabled with the reason; sent entries are not listed");
        });
        snap("editor_share_send_ai.png");
        click("send:ok");
        wait_until([shared_of] { return shared_of("FB-0004") == "sent"; });
        step(3, [this, entry_of, shared_of, all_reports] {
            const Json e = entry_of("FB-0004");
            at_check(e.contains("share") &&
                         e["share"].value("title", std::string()) == "SpriteRenderer lacks gradient tinting" &&
                         e.value("reviewed", false),
                     "Send stores the checked AI-rewritten text and marks it reviewed (" +
                         e.value("share", Json::object()).dump() + ")");
            at_check(shared_of("FB-0005") == "skipped" && shared_of("FB-0001") == "skipped" &&
                         shared_of("FB-0006").empty(),
                     "the refused and the left-out rows are skipped; the one that could not be made is untouched");
            const std::string body = all_reports();
            at_check(body.find("SpriteRenderer lacks gradient tinting") != std::string::npos &&
                         body.find("glow") == std::string::npos,
                     "the report carries the rewritten text and not the refused one");
        });
        click("send:close");
        // ---- Cancel changes nothing
        step(2, [x, reports] { x->reportsAtCancel = reports(); });
        wait_until([this] { return at_enabled("feedback:send"); });
        click("feedback:send");
        wait_until([this] { return share_.sendOpen && at_visible("send:cancel"); });
        step(3, [this, send_row] {
            at_check(send_row("FB-0001") && send_row("FB-0005") && !send_row("FB-0004") &&
                         !send_row("FB-0001")->checked && !send_row("FB-0005")->checked,
                     "the entries that were left out are offered again, unchecked; the sent one is not");
        });
        click("send:cancel");
        step(3, [this, x, shared_of, reports] {
            at_check(!share_.sendOpen && reports() == x->reportsAtCancel && shared_of("FB-0001") == "skipped" &&
                         shared_of("FB-0005") == "skipped" && shared_of("FB-0006").empty(),
                     "Cancel sends nothing and changes nothing");
        });
        // ---- an entry that is not open goes to the archive by itself
        step(2, [this, x] {
            auto r = update_feedback_file(x->path, "FB-0006", "wont-fix", "");
            at_check(r.ok(), "FB-0006 is marked wont-fix");
        });
        wait_until([this, entry_of] {
            return !entry_of("FB-0006").contains("id") &&
                   stdfs::exists(projectDir_ + "/ENGINE_FEEDBACK.archive.json") && !at_visible("feedback:row:FB-0006");
        });
        step(3, [this, x] {
            auto archive = load_feedback(projectDir_ + "/ENGINE_FEEDBACK.archive.json");
            bool found = false;
            if (archive && archive->contains("entries"))
                for (const Json& e : (*archive)["entries"]) found = found || e.value("id", std::string()) == "FB-0006";
            at_check(found && !at_visible("feedback:row:FB-0006"),
                     "a closed entry is moved to the archive file, and the panel no longer lists it");
            aiFactory_ = nullptr;
            std::lock_guard<std::mutex> lock(aiMu_);
            if (x->savedConfig) aiConfig_ = std::move(*x->savedConfig);
            x->savedConfig.reset();
        });
        // ---- Feedback Settings: GitHub sign-in
        step(2, [this] { open_share_settings(); });
        wait_until([this] { return at_visible("share:settings:signin"); });
        step(3, [this] {
            at_check(share_.settingsOpen && at_visible("share:settings:mode:always") &&
                         at_visible("share:settings:mode:ask") && at_visible("share:settings:mode:never") &&
                         at_visible("share:settings:installid"),
                     "Feedback Settings has the three modes and the installation id");
        });
        click("share:settings:signin");
        wait_until([this] {
            std::lock_guard<std::mutex> lock(share_.mu);
            return share_.haveCode && at_visible("share:settings:code");
        });
        step(3, [this] {
            at_check(share_.code.userCode == "ABCD-1234" && at_visible("share:settings:url") &&
                         at_visible("share:settings:open") && at_visible("share:settings:cancel"),
                     "Sign in shows the device code, the address, a button that opens it and Cancel");
        });
        snap("editor_share_signin.png");
        click("share:settings:open");
        step(3, [this] {
            at_check(share_.settingsMessage.find("(autotest) would open https://github.com/login/device") !=
                         std::string::npos,
                     "Open in browser opens the address (not in the autotest: " + share_.settingsMessage + ")");
            atShareNet_->authorize = true;  // the person approved the code on github.com
        });
        wait_until([this] {
            return load_share_settings(share_env()).login == "octocat" && at_visible("share:settings:signout");
        });
        step(3, [this] {
            at_check(at_visible("share:settings:login") && !load_share_settings(share_env()).credential.empty(),
                     "the sign-in finishes by itself and shows the login");
            std::lock_guard<std::mutex> lock(atShareNet_->mu);
            int exchanges = 0;
            for (const std::string& u : atShareNet_->urls)
                if (u == "POST https://feedback.autotest.invalid/v1/auth/github") ++exchanges;
            at_check(exchanges == 1, "the GitHub token was exchanged once with the feedback server");
        });
        click("share:settings:signout");
        step(3, [this] {
            at_check(load_share_settings(share_env()).credential.empty() &&
                         load_share_settings(share_env()).login.empty(),
                     "Sign out forgets the credential and the login");
        });
        // ---- installation id
        step(2, [this, x] {
            x->installBefore = load_share_settings(share_env()).installId;
            at_check(is_uuid_v4(x->installBefore),
                     "the first report made an installation id (" + x->installBefore + ")");
        });
        wait_until([this] { return at_visible("share:settings:resetid") && at_enabled("share:settings:resetid"); });
        click("share:settings:resetid");
        step(3, [this, x] {
            const std::string now = load_share_settings(share_env()).installId;
            at_check(is_uuid_v4(now) && now != x->installBefore, "Reset id makes a new installation id");
        });
        // ---- Always, a server that is down, Send now
        step(2, [this, x, add_entry] {
            atShareNet_->failReports = true;
            x->alwaysId = add_entry(
                "Tilemaps cannot flip a single tile",
                "Tilemap has no per-tile flip flag, so a mirrored tile needs a second tileset image.",
                Json::object(
                    {{"title", "Tilemaps cannot flip a single tile"},
                     {"missing",
                      "Tilemap has no per-tile flip flag, so a mirrored tile needs a second tileset image."}}));
        });
        click("share:settings:mode:always");
        step(3, [this] {
            at_check(load_share_settings(share_env()).mode == ShareMode::Always,
                     "the Always radio button writes the mode");
        });
        wait_until([this] {
            const Json st = share_status(share_env());
            return st["outbox"]["failed"].size() == 1 && at_enabled("share:settings:sendnow");
        });
        step(3, [this, x, shared_of] {
            at_check(shared_of(x->alwaysId) == "pending" && at_visible("share:settings:outbox"),
                     "a server that is down leaves the entry in the outbox, which the window shows");
            atShareNet_->failReports = false;
        });
        click("share:settings:sendnow");
        wait_until([x, shared_of] { return shared_of(x->alwaysId) == "sent"; });
        step(3,
             [this, reports] { at_check(reports() >= 3, "Send now sent what was waiting once the server answered"); });
        // The upload thread ends a few frames after the entry reads "sent" (later on a slow Windows run); as it finishes, the
        // window's outbox rows change and move the radio buttons, so a click aimed at the old place would miss Never.
        wait_until([this] { return !share_.flushRunning; });
        step(2, [] {});
        click("share:settings:mode:never");
        step(3, [this, grow_panel_row] {
            at_check(load_share_settings(share_env()).mode == ShareMode::Never &&
                         load_outbox(share_env()).items.empty(),
                     "the Never radio button writes the mode and the outbox is empty");
            at_check(at_visible("feedback:send") && at_enabled("feedback:add") && !at_enabled("feedback:send"),
                     "with sharing off, Send feedback is disabled and Add feedback is not");
        });
        // ---- a mode for this project alone (feedback-sharing.json `projects`, never inside the project)
        scroll_to("share:settings:project:always", "Feedback Settings###share-settings");
        step(3, [this] {
            at_check(at_visible("share:settings:project") && at_visible("share:settings:project:default") &&
                         at_visible("share:settings:project:always") && at_visible("share:settings:project:ask") &&
                         at_visible("share:settings:project:never"),
                     "Feedback Settings has \"This project\" with Follow default, Always, Ask and Never");
            // On a small window the row wraps: every radio button has its centre inside the visible part of the window.
            at_check(
                at_shown("share:settings:project:default") && at_shown("share:settings:project:always") &&
                    at_shown("share:settings:project:ask") && at_shown("share:settings:project:never"),
                "the project's radio buttons wrap to the window's width: none of them is clipped at its right edge");
        });
        click("share:settings:project:always");
        step(3, [this, x, add_entry] {
            const ShareSettings st = load_share_settings(share_env());
            at_check(st.mode == ShareMode::Never && share_project_mode(st, projectDir_) == ShareMode::Always &&
                         effective_share_mode(st, projectDir_) == ShareMode::Always,
                     "the project's Always writes `projects` in the user's file and leaves the default (Never) alone");
            at_check(share_.mode == ShareMode::Always && at_enabled("feedback:send"),
                     "the project's mode is the one that applies: Send feedback is enabled again");
            at_check(!stdfs::exists(projectDir_ + "/.factoria/feedback-sharing.json"),
                     "nothing about the choice is written inside the project");
            // A report made now goes out although the default is Never: the project's own mode is the one that counts.
            x->projectSentId = add_entry(
                "Sprites cannot be skewed on one axis",
                "Sprite has no skew, so a slanted shadow needs a separate image for every angle.",
                Json::object(
                    {{"title", "Sprites cannot be skewed on one axis"},
                     {"missing", "Sprite has no skew, so a slanted shadow needs a separate image for every angle."}}));
        });
        wait_until([x, shared_of] { return shared_of(x->projectSentId) == "sent"; });
        step(3, [this, x, shared_of] {
            at_check(shared_of(x->projectSentId) == "sent" && load_share_settings(share_env()).mode == ShareMode::Never,
                     "with the default Never and the project Always, the project's new report was sent");
        });
        // The flush that sent the report above may still be applying its results (the outbox is saved after the entry is marked
        // sent): on a slow machine clicking Ask now would race with it. Wait until it is done and the outbox is empty.
        wait_until([this] { return !share_.flushRunning.load() && load_outbox(share_env()).items.empty(); });
        // Ask: a new report is queued with the project's key and waits; nothing goes until the person says yes.
        scroll_to("share:settings:project:ask", "Feedback Settings###share-settings");
        click("share:settings:project:ask");
        step(3, [this, x, add_entry, reports] {
            at_check(effective_share_mode(load_share_settings(share_env()), projectDir_) == ShareMode::Ask,
                     "the project's Ask is the mode that applies");
            x->reportsBeforeAsk = reports();
            x->projectAskId = add_entry(
                "Tilemaps have no animated tiles",
                "Tilemap cannot play a tile animation, so water needs one entity per tile.",
                Json::object(
                    {{"title", "Tilemaps have no animated tiles"},
                     {"missing", "Tilemap cannot play a tile animation, so water needs one entity per tile."}}));
        });
        wait_until([x] {
            for (const OutboxItem& it : load_outbox(share_env()).items)
                if (it.localId == x->projectAskId) return true;
            return false;
        });
        step(3, [this, x, reports, shared_of] {
            const Outbox box = load_outbox(share_env());
            const OutboxItem* item = nullptr;
            for (const OutboxItem& it : box.items)
                if (it.localId == x->projectAskId) item = &it;
            at_check(item && item->state == OutboxState::Waiting && item->projectKey == share_project_key(projectDir_),
                     "the report of a project set to Ask waits for the person's yes, and the outbox item stores the "
                     "project's key");
            if (item) x->projectAskKey = item->key;
            at_check(shared_of(x->projectAskId) == "pending" && reports() == x->reportsBeforeAsk,
                     "nothing of it was sent");
            at_check(share_status(share_env(), projectDir_)["outbox"].value("waitingForConfirmation", 0) == 1,
                     "the status counts it as waiting for the person's answer");
        });
        scroll_to("share:settings:project:never", "Feedback Settings###share-settings");
        click("share:settings:project:never");
        step(3, [this, x, reports, shared_of] {
            at_check(effective_share_mode(load_share_settings(share_env()), projectDir_) == ShareMode::Never &&
                         !at_enabled("feedback:send"),
                     "the project's Never disables Send feedback");
            at_check(load_outbox(share_env()).items.empty() && shared_of(x->projectAskId) == "skipped" &&
                         reports() == x->reportsBeforeAsk,
                     "the project's Never dropped the item that waited and marked its entry skipped; nothing was sent");
        });
        scroll_to("share:settings:project:default", "Feedback Settings###share-settings");
        click("share:settings:project:default");
        step(3, [this, grow_panel_row] {
            const ShareSettings st = load_share_settings(share_env());
            at_check(st.projects.empty() && !share_project_mode(st, projectDir_) && share_.mode == ShareMode::Never,
                     "Follow default removes the project's choice: the default (Never) applies again");
            share_.settingsOpen = false;
            grow_panel_row(false);
        });
    }
}

void Editor::at_section_E4(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // Rejected feedback (docs/EDITOR.md, "Rejected entries"): the engine rejects an entry that says the engine lacks what it has (with
    // the reason), a double click opens an entry in its own window (movable, resizable, every field), the status combo asks why before
    // an entry is rejected, "closed" lists the archive with the reason on the row, Copy puts the whole entry on the clipboard,
    // Delete asks first and the id is not given again, and the engine developers' verdict (a rejected report, asked of the fake
    // server) comes back as a rejected entry with their reason.
    {
        struct E4State {
            std::string path, archive;
            float doubleClickTime = 0.3f, singleClickDelay = 0.5f;
            ImGuiID row = 0,
                    sibling = 0;  // the dock row of the panel made taller for this section, and the one it took from
            float grown = 0;
        };
        auto x = std::make_shared<E4State>();
        // The bottom row of the dock gives the panel little room on a small display: it grows for this section (as in E2).
        auto grow_panel_row = [x](bool grow) {
            if (!grow) {
                ImGuiDockNode* row = ImGui::DockBuilderGetNode(x->row);
                ImGuiDockNode* sib = ImGui::DockBuilderGetNode(x->sibling);
                if (row && sib) row->SizeRef.y -= x->grown, sib->SizeRef.y += x->grown;
                x->grown = 0;
                return;
            }
            const ImGuiWindow* w = panel_window("Engine Feedback");
            ImGuiDockNode* row = w ? w->DockNode : nullptr;
            while (row && row->ParentNode && row->ParentNode->SplitAxis != ImGuiAxis_Y) row = row->ParentNode;
            if (!row || !row->ParentNode) return;
            ImGuiDockNode* sib =
                row->ParentNode->ChildNodes[0] == row ? row->ParentNode->ChildNodes[1] : row->ParentNode->ChildNodes[0];
            if (!sib) return;
            x->grown = std::clamp(440.0f - row->Size.y, 0.0f, std::max(0.0f, sib->Size.y - 120.0f));
            x->row = row->ID;
            x->sibling = sib->ID;
            row->SizeRef.y += x->grown;
            sib->SizeRef.y -= x->grown;
        };
        auto any_entry = [x](const std::string& id) -> Json {
            for (const std::string& file : {x->path, x->archive}) {
                auto doc = load_feedback(file);
                if (doc && doc->contains("entries"))
                    for (const Json& e : (*doc)["entries"])
                        if (e.value("id", std::string()) == id) return e;
            }
            return Json::object();
        };
        auto in_archive = [x](const std::string& id) {
            auto doc = load_feedback(x->archive);
            if (doc && doc->contains("entries"))
                for (const Json& e : (*doc)["entries"])
                    if (e.value("id", std::string()) == id) return true;
            return false;
        };
        auto wait_until = [this, &step](std::function<bool()> cond) {
            step(1, [this, cond] {
                atWaitCount_ = 0;
                atWaitUntil_ = cond;
            });
        };
        step(2, [this, x] {
            x->path = projectDir_ + "/" + engine_->project().feedbackFile;
            x->archive = projectDir_ + "/ENGINE_FEEDBACK.archive.json";
            std::error_code ec;
            stdfs::remove(x->path, ec);
            stdfs::remove(x->archive, ec);
            (void)set_share_mode(share_env(),
                                 ShareMode::Never);  // the harness; only a click sets the mode in the product
            ShareUi& s = share_;
            s.consentOpen = s.consentLater = s.settingsOpen = s.sendOpen = false;
            s.mode = ShareMode::Never;
            s.docFile.clear();
            s.docStamp = INT64_MIN;
            s.tickAt = -10;
            {
                std::lock_guard<std::mutex> lock(atShareNet_->mu);
                atShareNet_->verdicts.clear();
            }
            for (const char* title : {"No one-way platforms", "Rope bridges are not supported",
                                      "Weather changes are missing", "Boats cannot float on water"}) {
                FeedbackInput in;
                in.category = feedback_categories().front();
                in.severity = "minor";
                in.title = title;
                in.missing = std::string(title) == "No one-way platforms"
                                 ? "Collider2D has no one-way option, so a body cannot pass up through a platform and "
                                   "land on it."
                                 : std::string(title) + " in this game.";
                in.workaround = "Edited the scene file by hand.";
                in.reporter = Json::object({{"kind", "human"}, {"agent", "factoria-editor"}});
                auto r = add_feedback_entry_to_file(x->path, in, "Autotest Platformer");
                at_check(r.ok(), std::string("entry added: ") + title);
            }
            fbSelected_.clear();
            fbAddOpen_ = false;
            fbShowClosed_ = false;
            fbWindows_.clear();
            fbAsk_ = FbAsk{};
            feedbackMtime_ = INT64_MIN;
            feedbackPolled_ = -10;
            showFeedback_ = true;
            focus_window("Engine Feedback");
            x->doubleClickTime = ImGui::GetIO().MouseDoubleClickTime;
            x->singleClickDelay = ImGui::GetIO().MouseSingleClickDelay;
            ImGui::GetIO().MouseSingleClickDelay = 6.0f;  // (must stay above the double-click time)
            ImGui::GetIO().MouseDoubleClickTime =
                5.0f;  // two clicks a few frames apart are a double click, however slow the frames
        });
        step(2, [grow_panel_row] { grow_panel_row(true); });
        // ---- the engine rejects an entry that says the engine lacks what it has
        wait_until([in_archive] { return in_archive("FB-0001"); });
        step(3, [this, any_entry] {
            const Json e = any_entry("FB-0001");
            at_check(e.value("status", std::string()) == "rejected" && e.value("statusBy", std::string()) == "engine" &&
                         e.value("statusReason", std::string()).find("Collider2D.oneWay") != std::string::npos,
                     "an open entry that says Collider2D has no one-way option is rejected by the engine, with the "
                     "reason (" +
                         e.value("statusReason", std::string()) + ")");
            at_check(any_entry("FB-0004").value("status", std::string()) == "open" &&
                         !at_visible("feedback:row:FB-0001"),
                     "...the others stay open, and the closed one is not in the table");
        });
        // ---- "closed" lists the archive; a row with a reason is marked
        wait_until([this] { return at_visible("feedback:closed") && at_visible("feedback:row:FB-0004"); });
        click("feedback:closed");
        wait_until([this] { return at_visible("feedback:row:FB-0001"); });
        step(3, [this] {
            at_check(fbShowClosed_ && at_visible("feedback:status:FB-0001") && at_visible("feedback:row:FB-0004"),
                     "closed lists the archived entries too, each with its status (a rejected one carries a marker and "
                     "its reason in a tooltip)");
            const Json* e = feedback_entry("FB-0001");
            at_check(e && e->value("statusReason", std::string()).find("documented in") != std::string::npos,
                     "the panel holds the archived entry with its statusReason");
        });
        click("feedback:closed");
        wait_until([this] { return !at_visible("feedback:row:FB-0001") && at_shown("feedback:row:FB-0004"); });
        step(3, [] {});
        // ---- a double click opens the entry in a window
        click("feedback:row:FB-0004");
        click("feedback:row:FB-0004");
        wait_until([this] { return at_visible("feedback:win:FB-0004"); });
        step(3, [this] {
            ImGuiWindow* w = ImGui::FindWindowByName("Feedback FB-0004###fbwin-FB-0004");
            at_check(w && !(w->Flags & ImGuiWindowFlags_NoResize) && !(w->Flags & ImGuiWindowFlags_NoMove) &&
                         w->Size.x > 100,
                     "a double click on a row opens that entry in a window that can be moved and resized");
            at_check(fbWindows_.size() == 1 && at_visible("feedback:win:close") && at_visible("feedback:copy") &&
                         at_visible("feedback:status") && at_visible("feedback:delete"),
                     "...with the status, Copy, Delete and Close at its top");
            at_check(!at_enabled("feedback:delete"), "Delete is disabled for an open entry");
            if (w) {  // out of the table's way, whatever the display
                ImGui::SetWindowPos(w, ImVec2(8, 28));
                ImGui::SetWindowSize(w, ImVec2(480, 150));
            }
        });
        snap("editor_feedback_window.png");
        // ---- the status combo asks why before an entry is rejected
        click("feedback:status");
        wait_until([this] { return at_visible("feedback:status:item:rejected"); });
        click("feedback:status:item:rejected");
        wait_until([this] { return at_visible("feedback:reason:ok"); });
        step(3, [this] {
            at_check(fbAsk_.open && fbAsk_.id == "FB-0004" && at_visible("feedback:reason") &&
                         !at_enabled("feedback:reason:ok"),
                     "choosing rejected asks for the reason, and OK waits for one");
            fbAsk_.reason = "The engine has Tilemap and a Collider2D already; floating needs no new feature.";
        });
        snap("editor_feedback_reject.png");
        wait_until([this] { return at_enabled("feedback:reason:ok"); });
        click("feedback:reason:ok");
        wait_until([in_archive] { return in_archive("FB-0004"); });
        step(3, [this, any_entry] {
            const Json e = any_entry("FB-0004");
            at_check(e.value("status", std::string()) == "rejected" && e.value("statusBy", std::string()) == "user" &&
                         e.value("statusReason", std::string()) ==
                             "The engine has Tilemap and a Collider2D already; floating needs no new feature.",
                     "Reject stores the status, the reason and who decided; the entry moves to the archive");
            at_check(!fbAsk_.open && at_visible("feedback:win:FB-0004") && at_visible("feedback:win:reason"),
                     "...and its window stays, now showing the reason");
        });
        // ---- Copy: the whole entry on the clipboard
        click("feedback:copy");
        step(3, [this] {
            const char* clip = ImGui::GetClipboardText();
            const std::string text = clip ? clip : "";
            at_check(text.find("\"id\": \"FB-0004\"") != std::string::npos &&
                         text.find("\"statusReason\"") != std::string::npos &&
                         text.find("Boats cannot float on water") != std::string::npos &&
                         text.find("\"workaround\"") != std::string::npos,
                     "Copy puts the whole entry (every field, as JSON) on the clipboard");
        });
        // ---- Delete asks first; the id is not used again
        wait_until([this] { return at_enabled("feedback:delete"); });
        click("feedback:delete");
        wait_until([this] { return at_visible("feedback:delete:ok"); });
        click("feedback:delete:cancel");
        step(3, [this, any_entry] {
            at_check(!fbAsk_.open && any_entry("FB-0004").value("id", std::string()) == "FB-0004",
                     "Cancel keeps the entry");
        });
        click("feedback:delete");
        wait_until([this] { return at_visible("feedback:delete:ok"); });
        click("feedback:delete:ok");
        wait_until([any_entry] { return any_entry("FB-0004").value("id", std::string()).empty(); });
        step(3, [this, x] {
            at_check(fbWindows_.empty() && fbSelected_ != "FB-0004",
                     "Delete removes the entry from the archive and closes its window");
            FeedbackInput in;
            in.category = feedback_categories().front();
            in.severity = "minor";
            in.title = "Ocean currents are missing";
            in.missing = "Nothing pushes a floating body along a river.";
            in.workaround = "A script moves it.";
            auto r = add_feedback_entry_to_file(x->path, in, "Autotest Platformer");
            at_check(r.ok() && r->id == "FB-0005", "the deleted id is not given again (the next entry is " +
                                                       (r.ok() ? r->id : r.error().message) + ")");
        });
        // ---- the engine developers' verdict comes back as a rejected entry
        step(2, [this, x] {
            write_entry_shared(x->path, "FB-0003",
                               Json::object({{"status", "sent"}, {"shareId", "r_7"}, {"date", "2026-01-01"}}));
            {
                std::lock_guard<std::mutex> lock(atShareNet_->mu);
                atShareNet_->verdicts["r_7"] =
                    "Not a gap: weather is a particle effect plus a script, see the weather recipe.";
            }
            (void)set_share_mode(share_env(), ShareMode::Always);
            share_.verdictAt = -1e9;  // ask now, not in half an hour
            share_.docStamp = INT64_MIN;
            share_.tickAt = -10;
        });
        wait_until([in_archive] { return in_archive("FB-0003"); });
        step(3, [this, any_entry] {
            const Json e = any_entry("FB-0003");
            at_check(
                e.value("status", std::string()) == "rejected" && e.value("statusBy", std::string()) == "developer" &&
                    e.value("statusReason", std::string()).find("Not a gap") != std::string::npos,
                "the engine developers' verdict is stored as a rejected entry with their reason (" + e.dump() + ")");
            const ShareColumn c = share_column(e);
            at_check(c.label == "declined" && c.tooltip.find("Not a gap") != std::string::npos,
                     "...and its share column reads declined, with their reason on hover");
            at_check(any_entry("FB-0002").value("status", std::string()) == "open",
                     "an entry the developers said nothing about stays open");
        });
        // ---- leave the editor as the other sections expect it
        step(2, [this, x] {
            (void)set_share_mode(share_env(), ShareMode::Never);
            share_.mode = ShareMode::Never;
            fbShowClosed_ = false;
            fbWindows_.clear();
            fbAsk_ = FbAsk{};
            ImGui::GetIO().MouseDoubleClickTime = x->doubleClickTime;
            ImGui::GetIO().MouseSingleClickDelay = x->singleClickDelay;
            std::error_code ec;
            stdfs::remove(x->path, ec);
            stdfs::remove(x->archive, ec);
            feedbackMtime_ = INT64_MIN;
            feedbackPolled_ = -10;
        });
        step(2, [grow_panel_row] { grow_panel_row(false); });
    }
}

void Editor::at_section_R2(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // The retrospective (docs/AI_PROVIDERS.md, "Retrospective"): the Feedback panel's button looks back at the transcripts of the open
    // project's runs and, with the fast role's model (a scripted one here), files an efficiency entry; the panel says what happened, lists
    // the entry and adds up what its fix would save. The button is off while it runs and without a project.
    {
        struct R2State {
            std::string path, archive, transcript;
            std::string envBefore;
        };
        auto x = std::make_shared<R2State>();
        step(2, [this, x] {
            x->path = projectDir_ + "/" + engine_->project().feedbackFile;
            x->archive = projectDir_ + "/ENGINE_FEEDBACK.archive.json";
            x->transcript = projectDir_ + "/.factoria/ai/sessions/at-retro.jsonl";
            std::error_code ec;
            stdfs::remove(x->path, ec);
            stdfs::remove(x->archive, ec);
            (void)set_share_mode(share_env(), ShareMode::Never);
            share_.mode = ShareMode::Never;
            // A run that called scene.load 20 times, a minute each, and got not_found every time.
            const std::int64_t t0 = 1'793'000'000'000;
            std::string text = Json::object({{"kind", "start"}, {"t", iso_utc_ms(t0)}}).dump() + "\n";
            for (int i = 0; i < 20; ++i) {
                const std::string id = "tu" + std::to_string(i + 1);
                const std::int64_t t = t0 + std::int64_t(i) * 60000;
                Json call = Json::object({{"type", "tool_use"},
                                          {"id", id},
                                          {"name", "tool_call"},
                                          {"input", Json::object({{"command", "scene.load"},
                                                                  {"arguments", Json::object({{"scene", "main"}})}})}});
                text += Json::object({{"kind", "assistant"},
                                      {"t", iso_utc_ms(t + 59999)},
                                      {"usage", Json::object({{"inputTokens", 4500}, {"outputTokens", 500}})},
                                      {"costUsd", 0.05},
                                      {"content", Json::array({call})}})
                            .dump() +
                        "\n";
                Json result = Json::object({{"toolUseId", id},
                                            {"isError", true},
                                            {"ms", 40},
                                            {"content", "{\"code\":\"not_found\",\"message\":\"no such scene\"}"}});
                text +=
                    Json::object(
                        {{"kind", "tool_results"}, {"t", iso_utc_ms(t + 60000)}, {"results", Json::array({result})}})
                        .dump() +
                    "\n";
            }
            stdfs::create_directories(utf8_path(projectDir_) / ".factoria" / "ai" / "sessions", ec);
            write_file(x->transcript, text);
            FeedbackInput
                in;  // an entry already there, so the file exists and the panel is not on "No feedback file yet"
            in.category = feedback_categories().front();
            in.severity = "minor";
            in.title = "Sprites cannot be tinted per frame";
            in.missing = "Animation frames have no tint, so a flash needs a second sprite for every frame.";
            in.workaround = "A second sprite.";
            in.reporter = Json::object({{"kind", "human"}, {"agent", "factoria-editor"}});
            at_check(add_feedback_entry_to_file(x->path, in, "Autotest Platformer").ok(), "the first entry is added");
            aiFactory_ = [](const ai::ProviderConfig&) -> Result<std::shared_ptr<ai::ChatProvider>> {
                return std::shared_ptr<ai::ChatProvider>(std::make_shared<RetrospectiveProvider>());
            };
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                atSavedConfig_ = aiConfig_;
                if (aiConfig_.providers.empty()) aiConfig_ = ai::default_config();
                ai::RoleConfig& fast = aiConfig_.roles[ai::kRoleFast];
                fast.provider = "anthropic";
                if (fast.model.empty()) fast.model = "mock";
            }
            fbSelected_.clear();
            fbShowClosed_ = false;
            fbMessage_.clear();
            feedbackMtime_ = INT64_MIN;
            feedbackPolled_ = -10;
            showFeedback_ = true;
            focus_window("Engine Feedback");
        });
        step(3, [this] {
            at_check(at_shown("feedback:retrospective"), "the Feedback panel has a Retrospective button");
            at_check(!at_visible("feedback:saving"), "no efficiency entry yet: no saving line");
        });
        click("feedback:retrospective");
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] {
                std::lock_guard<std::mutex> lock(fbRetro_->mu);
                return !fbRetro_->running && !fbRetro_->finished;
            };
        });
        step(1, [this, x] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this, x] {
                auto doc = load_feedback(x->path);
                if (!doc || !doc->contains("entries")) return false;
                for (const Json& e : (*doc)["entries"])
                    if (e.value("kind", std::string()) == "efficiency") return at_visible("feedback:saving");
                return false;
            };
        });
        step(3, [this, x] {
            auto doc = load_feedback(x->path);
            at_check(doc.ok(), "the feedback file reads");
            int efficiency = 0;
            Json entry = Json::object();
            if (doc.ok())
                for (const Json& e : (*doc)["entries"])
                    if (e.value("kind", std::string()) == "efficiency") ++efficiency, entry = e;
            at_check(efficiency == 1, "the retrospective filed one efficiency entry (" + std::to_string(efficiency) +
                                          "); the panel says: " + fbMessage_);
            at_check(entry.value("title", std::string()).find("scene by name") != std::string::npos &&
                         entry.contains("saving") && entry["saving"].value("minutes", 0.0) > 0,
                     "...with the model's title and a measured saving: " + entry.dump());
            at_check(entry.contains("reporter") && entry["reporter"].is_object(), "...and a reporter");
            at_check(at_visible("feedback:message") && fbMessage_.rfind("1 efficiency entry filed", 0) == 0,
                     "the panel says what the retrospective did: " + fbMessage_);
            at_check(at_visible("feedback:saving"), "the panel adds up what the open efficiency entries would save");
            at_check(share_.mode == ShareMode::Never, "the sharing mode is the one the person chose");
            at_check(stdfs::exists(utf8_path(x->transcript)), "the transcript is left as it was");
        });
        snap("editor_retrospective.png");
        // A second click finds nothing new: the entry counts the evidence.
        click("feedback:retrospective");
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] {
                std::lock_guard<std::mutex> lock(fbRetro_->mu);
                return !fbRetro_->running && !fbRetro_->finished;
            };
        });
        step(3, [this, x] {
            auto doc = load_feedback(x->path);
            int efficiency = 0;
            if (doc.ok())
                for (const Json& e : (*doc)["entries"])
                    if (e.value("kind", std::string()) == "efficiency") ++efficiency;
            at_check(efficiency == 1, "a second retrospective files nothing new (" + std::to_string(efficiency) + ")");
            at_check(fbMessage_.find("Nothing new") != std::string::npos ||
                         fbMessage_.find("already") != std::string::npos,
                     "...and says so: " + fbMessage_);
        });
        step(2, [this, x] {
            aiFactory_ = nullptr;
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                if (atSavedConfig_) {
                    aiConfig_ = std::move(*atSavedConfig_);
                    atSavedConfig_.reset();
                }
            }
            (void)set_share_mode(share_env(), ShareMode::Never);
            std::error_code ec;
            stdfs::remove(utf8_path(x->transcript), ec);
            stdfs::remove(utf8_path(x->path), ec);
            stdfs::remove(utf8_path(x->archive), ec);
            fbMessage_.clear();
            feedbackMtime_ = INT64_MIN;
            feedbackPolled_ = -10;
        });
    }
}

}  // namespace fa::editor
