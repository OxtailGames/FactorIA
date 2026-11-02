// Feedback sharing in the editor (docs/EDITOR.md, "Sharing feedback"): the consent dialog, File > Feedback Settings, the
// Send feedback window and the share column of the Engine Feedback panel. The client is fa/tooling/feedback_share.h; the rules
// the panel applies (which entries the window lists, the text it shows, what Send stores and queues) are feedback_share_model.h.
//
// THE SHARING MODE IS CHOSEN BY A PERSON, HERE AND ONLY HERE. share_choose_mode() is called by the consent dialog and by the
// radio buttons of Feedback Settings, both of which only a click can reach. No command, MCP tool, script or AI may set the mode
// (there is no command for it, and ai.review_feedback never touches it): do not add one.
#include <algorithm>
#include <sstream>

#include "editor_internal.h"
#include "fa/core/strings.h"

namespace fa::editor {

namespace {

const ImVec4 kRed(1, 0.45f, 0.4f, 1), kGreen(0.45f, 0.85f, 0.5f, 1), kAmber(1, 0.75f, 0.3f, 1), kGrey(0.62f, 0.65f, 0.72f, 1);

ImVec4 share_color(ShareKind k) {
    switch (k) {
        case ShareKind::Sent: return kGreen;
        case ShareKind::Waiting: return kAmber;
        case ShareKind::Rejected: return kRed;
        default: return kGrey;
    }
}

std::string removals_text(const std::vector<Removal>& removed) {
    std::string out;
    for (const Removal& r : removed) {
        if (!out.empty()) out += "; ";
        out += r.kind + " in " + r.field + " (\"" + r.text + "\")";
    }
    return out;
}

// The outbox as the Send window needs it: the ids of `file` that are queued (on their way) and those that wait for an answer.
SendOutbox outbox_of_file(const ShareEnv& env, const std::string& file) {
    SendOutbox out;
    for (const OutboxItem& it : load_outbox(env).items) {
        if (it.file != file) continue;
        (it.state == OutboxState::Waiting ? out.waiting : out.queued).insert(it.localId);
    }
    return out;
}

const Json* entry_in(const Json& doc, const std::string& id) {
    if (!doc.is_object() || !doc.contains("entries") || !doc["entries"].is_array()) return nullptr;
    for (const Json& e : doc["entries"])
        if (e.is_object() && e.value("id", std::string()) == id) return &e;
    return nullptr;
}

}  // namespace

// ------------------------------------------------------------------------------------------------------------ the mode

void Editor::share_choose_mode(ShareMode mode) {
    if (auto r = set_share_mode(share_env(), mode); !r) {
        notify(r.error().to_string(), 2);
        return;
    }
    share_.mode = mode;
    share_.consentOpen = false;
    share_.tickAt = -10;      // the next tick queues what the mode allows
    share_.flushAt = -100;    // ...and sends it at once
    share_.settingsPolled = -10;
    switch (mode) {
        case ShareMode::Always: notify("Feedback sharing: always. Entries with a share text go to the engine developers as they are written.", 0); break;
        case ShareMode::Ask: notify("Feedback sharing: you are asked before anything is sent (Send feedback in the Engine Feedback panel).", 0); break;
        case ShareMode::Never: notify("Feedback sharing is off. Nothing leaves this computer.", 0); break;
        default: break;
    }
    // Send feedback was pressed while the mode was unset: the window opens now that a person chose.
    const bool after = share_.sendAfterConsent;
    share_.sendAfterConsent = false;
    if (after && (mode == ShareMode::Always || mode == ShareMode::Ask)) open_send_window();
}

// ---------------------------------------------------------------------------------------------------------------- threads

void Editor::share_start_flush(bool force, std::uint64_t session) {
    ShareUi& s = share_;
    if (s.flushRunning) return;
    if (s.flushThread.joinable()) s.flushThread.join();
    s.flushRunning = true;
    s.flushAt = time_;
    s.flushThread = std::thread([&s, env = share_env(), force, session] {
        FlushOptions o;
        o.force = force;
        o.oneBatch = false;
        o.timeoutSec = 15;
        const FlushResult r = share_flush(env, o);
        {
            std::lock_guard<std::mutex> lock(s.mu);
            s.flushMessage = r.message;
            s.flushSent = r.sent + r.merged;
            s.flushSession = session;
            s.flushNew = true;
        }
        s.flushRunning = false;
    });
}

void Editor::share_start_sign_in() {
    ShareUi& s = share_;
    if (s.signInRunning) return;
    if (s.signInThread.joinable()) s.signInThread.join();
    {
        std::lock_guard<std::mutex> lock(s.mu);
        s.haveCode = false;
        s.signInError.clear();
        s.signedInAs.clear();
    }
    s.signInCancel = false;
    s.signInRunning = true;
    s.signInThread = std::thread([&s, env = share_env()] {
        auto r = github_sign_in(
            env,
            [&s](const DeviceCode& c) {
                std::lock_guard<std::mutex> lock(s.mu);
                s.code = c;
                s.haveCode = true;
            },
            [&s] { return s.signInCancel.load(); });
        {
            std::lock_guard<std::mutex> lock(s.mu);
            if (r) s.signedInAs = r->login.empty() ? std::string("GitHub") : r->login;
            else if (!s.signInCancel) s.signInError = r.error().to_string();
            s.haveCode = false;
        }
        s.signInRunning = false;
    });
}


// The AI check of the texts of the Send window: ai.review_feedback with a candidate `share`, one entry after the other on one thread.
// The command is the real one, registered on a copy of the engine's command list whose handlers are never called (the review only
// reads the names and summaries). Given a text it reads the feedback file and calls the model and writes nothing, and it never sets
// the sharing mode or sends anything. With no model configured the first answer is `no_model` and the rest is skipped.
void Editor::share_start_ai_checks() {
    ShareUi& s = share_;
    if (s.aiRunning || !s.sendAiStart) return;
    s.sendAiStart = false;
    std::vector<ShareUi::AiJob> jobs;
    jobs.swap(s.aiJobs);
    jobs.erase(std::remove_if(jobs.begin(), jobs.end(), [&](const ShareUi::AiJob& j) { return j.session != s.sendSession; }), jobs.end());
    if (jobs.empty()) return;
    if (s.aiThread.joinable()) s.aiThread.join();
    auto reg = std::make_shared<CommandRegistry>();
    for (const CommandInfo* ci : engine_->commands().list()) {
        if (ci->name.rfind("ai.", 0) == 0) continue;
        reg->add(*ci, [](const Json&) -> Json {
            throw CommandError("unavailable", "this command is not available inside the feedback review", "");
        });
    }
    ai::AiCommandOptions ao;
    ao.loadConfig = [this]() -> Result<ai::AiConfig> {
        std::lock_guard<std::mutex> lock(aiMu_);
        return aiConfig_.providers.empty() ? ai::default_config() : aiConfig_;
    };
    ao.projectDir = [dir = projectDir_] { return dir; };
    ao.providerFactory = aiFactory_;
    ai::register_ai_commands(*reg, ao);
    s.aiRunning = true;
    s.aiThread = std::thread([&s, reg, jobs] {
        for (const ShareUi::AiJob& job : jobs) {
            if (s.sendLive.load() != job.session) break;  // the window was closed: nobody wants the rest
            const CommandResult res = reg->call("ai.review_feedback", Json::object({{"id", job.id}, {"share", job.text.to_json()}}));
            const bool noModel = !res.ok && res.error.value("code", std::string()) == "no_model";
            {
                std::lock_guard<std::mutex> lock(s.mu);
                ShareUi::AiDone d;
                d.session = job.session;
                d.id = job.id;
                d.result = res.ok ? res.result
                                  : Json::object({{"error", res.error.value("message", std::string("the check failed"))},
                                                  {"hint", res.error.value("hint", std::string())},
                                                  {"code", res.error.value("code", std::string())}});
                s.aiDone.push_back(std::move(d));
            }
            if (noModel) break;  // no AI is set up: every other row would say the same
        }
        s.aiRunning = false;
    });
}

// ------------------------------------------------------------------------------------------------------------------ tick

namespace {
// The send window's view of an AI answer, applied to its row. Returns false when the answer says there is no model.
bool apply_ai_answer(ShareUi::SendRowUi& r, const Json& answer, const EngineNames& names, const ProjectNames& project) {
    if (answer.contains("error")) {
        if (answer.value("code", std::string()) == "no_model") return false;
        r.review = ShareUi::SendReview::Error;
        r.reviewNote = "The AI check could not run: " + answer.value("error", std::string()) + " " + answer.value("hint", std::string());
        return true;
    }
    if (!answer.value("pass", false)) {
        r.review = ShareUi::SendReview::Failed;
        r.checked = false;
        std::string note;
        if (answer.contains("reasons") && answer["reasons"].is_array())
            for (const Json& why : answer["reasons"])
                if (why.is_string()) note += (note.empty() ? "" : " ") + why.get<std::string>();
        const std::string fix = answer.value("fix", std::string());
        r.reviewNote = "The AI check did not pass: " + note + (fix.empty() ? "" : " How to fix it: " + fix);
        return true;
    }
    r.review = ShareUi::SendReview::Passed;
    r.reviewPassed = true;
    r.reviewNote = "Checked by AI.";
    if (answer.value("rewritten", false) && answer.contains("share") && answer["share"].is_object()) {
        std::string problem;
        const ShareFields rewritten = ShareFields::from_entry(Json::object({{"share", answer["share"]}}));
        if (!(rewritten == r.row.fields)) {
            if (set_send_text(r.row, r.entry, rewritten, names, project, problem)) {
                r.rewritten = true;
                r.reviewNote = "Checked by AI: the text was rewritten in engine terms.";
            } else {
                r.reviewNote = "Checked by AI. Its rewrite could not be used (" + problem + "), so the text is as it was.";
            }
        }
    }
    return true;
}
}  // namespace

void Editor::feedback_share_tick() {
    ShareUi& s = share_;
    std::vector<ShareUi::AiDone> answers;
    bool flushNewHere = false, flushForWindow = false, flushBusy = false;
    int flushSent = 0;
    std::string flushMessage;
    {  // what the threads handed over
        std::lock_guard<std::mutex> lock(s.mu);
        if (s.flushNew) {
            s.flushNew = false;
            flushNewHere = true;
            flushSent = s.flushSent;
            flushMessage = s.flushMessage;
            // The window that asked for this flush is still the one showing: it reports the outcome row by row.
            flushForWindow = s.flushSession != 0 && s.flushSession == s.sendSession && s.sendOpen && s.sendPhase == ShareUi::SendPhase::Sending;
        }
        flushBusy = s.flushNew;
        if (!s.signedInAs.empty()) {
            s.settingsMessage = "Signed in as " + s.signedInAs + ".";
            s.signedInAs.clear();
            s.settingsPolled = -10;
        }
        answers.swap(s.aiDone);
    }
    if (flushNewHere) {
        if (flushSent > 0 && !flushForWindow)
            notify("Shared " + std::to_string(flushSent) + (flushSent == 1 ? " feedback entry" : " feedback entries") +
                       " with the engine developers. Thank you.",
                   0);
        s.settingsPolled = -10;
        feedbackMtime_ = INT64_MIN;  // `shared` was written into the file
        feedbackPolled_ = -10;
        if (flushForWindow) send_window_finished(flushSent, flushMessage);
    }
    if (!answers.empty()) {
        const EngineNames names = collect_engine_names(&engine_->commands());
        const ProjectNames project = collect_project_names(projectDir_);
        for (const ShareUi::AiDone& d : answers) {
            if (d.session != s.sendSession || !s.sendOpen || s.sendPhase != ShareUi::SendPhase::Choose) continue;  // not this window's
            for (ShareUi::SendRowUi& r : s.sendRows) {
                if (r.row.id != d.id) continue;
                if (!apply_ai_answer(r, d.result, names, project)) {
                    s.sendAiAvailable = false;  // no AI is set up: the rows are shown as they are
                    for (ShareUi::SendRowUi& other : s.sendRows)
                        if (other.review == ShareUi::SendReview::Queued) other.review = ShareUi::SendReview::None;
                }
                break;
            }
        }
    }
    share_start_ai_checks();
    if (s.sendFlushWanted && !s.flushRunning && !flushBusy) {
        s.sendFlushWanted = false;
        share_start_flush(true, s.sendFlushSession);
    }
    if (time_ - s.tickAt < 1.0) return;
    s.tickAt = time_;
    const ShareEnv& env = share_env();
    const ShareSettings settings = load_share_settings(env);
    s.mode = settings.mode;
    s.sharingAvailable = !share_endpoint(env, settings).empty();
    const bool haveProject = engine_ && !projectDir_.empty();

    std::string file;
    Json doc;
    bool docLoaded = false;
    if (haveProject) {
        file = fs::join(projectDir_, engine_->project().feedbackFile);
        const bool exists = fs::exists(engine_->project().feedbackFile);
        std::int64_t stamp = exists ? fs::modified_time(engine_->project().feedbackFile) : 0;
        if (file != s.docFile || stamp != s.docStamp || s.mode != s.checkedMode) {
            s.docFile = file;
            s.docStamp = stamp;
            s.entryCount = 0;
            if (exists) {
                if (auto r = load_feedback(file); r && r->contains("entries") && (*r)["entries"].is_array()) {
                    doc = *r;
                    // Entries that are not open (fixed in the engine, won't fix, duplicate) go to the archive file next to this
                    // one as soon as they are seen: the panel and the Send window only deal with what is open.
                    bool anyClosed = false;
                    for (const Json& e : doc["entries"])
                        if (e.value("status", std::string("open")) != "open") anyClosed = true;
                    if (anyClosed) {
                        if (auto moved = archive_closed_feedback_file(file); moved && moved->moved > 0) {
                            if (auto again = load_feedback(file); again && again->contains("entries") && (*again)["entries"].is_array()) doc = *again;
                            stamp = fs::modified_time(engine_->project().feedbackFile);
                            s.docStamp = stamp;
                            feedbackMtime_ = INT64_MIN;
                            feedbackPolled_ = -10;
                        }
                    }
                    docLoaded = true;
                    s.entryCount = int(doc["entries"].size());
                }
            }
        }
    } else {
        s.docFile.clear();
        s.entryCount = 0;
    }
    s.checkedMode = s.mode;
    if (s.mode != ShareMode::Unset && s.consentOpen) {  // answered somewhere else (the terminal)
        s.consentOpen = false;
        const bool after = s.sendAfterConsent;
        s.sendAfterConsent = false;
        if (after && (s.mode == ShareMode::Always || s.mode == ShareMode::Ask)) open_send_window();
    }

    // First time: a project with feedback entries and no answer yet. Where sharing is not available nothing could be sent, so
    // nothing is asked either (File > Feedback Settings says why).
    if (s.mode == ShareMode::Unset && s.entryCount > 0 && !s.consentLater && !s.consentOpen && docLoaded && s.sharingAvailable) {
        s.consentOpen = true;
        share_fill_consent_preview(file, doc);
    }

    // always / ask: the entries with a share text and no answer yet go to the outbox (a rejection is written back with its reason).
    // An entry without a share text waits for Send feedback, which makes the text and asks.
    if (docLoaded && (s.mode == ShareMode::Always || s.mode == ShareMode::Ask)) {
        const std::vector<std::string> ids = entries_to_queue(doc);
        if (!ids.empty()) {
            const EngineNames engine = collect_engine_names(&engine_->commands());
            if (auto q = share_queue(env, file, projectDir_, engine, ids)) {
                if (q->rejected > 0)
                    notify(std::to_string(q->rejected) + (q->rejected == 1 ? " share text was" : " share texts were") +
                               " not accepted by the sanitizer. The Engine Feedback panel says why.",
                           1);
            }
            feedbackMtime_ = INT64_MIN;
            feedbackPolled_ = -10;
        }
    }

    // ask: the entries that wait for the person's answer (the Send feedback window lists them).
    if (s.mode == ShareMode::Ask) {
        s.waiting = share_waiting(env);
        int fresh = 0;
        for (const OutboxItem& it : s.waiting)
            if (s.notified.insert(it.key).second) ++fresh;
        if (fresh > 0 && !s.sendOpen) {
            notify_action(std::to_string(s.waiting.size()) + (s.waiting.size() == 1 ? " feedback entry waits" : " feedback entries wait") +
                              " for your answer before anything is sent.",
                          "Review", [this] { open_send_window(); }, "share:notify");
        }
    } else {
        s.waiting.clear();
    }

    // always / ask: send what is due (the confirmed ones, in ask mode), at most one flush every few seconds.
    if ((s.mode == ShareMode::Always || s.mode == ShareMode::Ask) && !s.flushRunning && time_ - s.flushAt > 5.0 && share_has_due(env))
        share_start_flush(false);
}

// What the consent dialog previews: the next report as the server would receive it, for the entries the Send feedback window would list.
void Editor::share_fill_consent_preview(const std::string& file, const Json& doc) {
    ShareUi& s = share_;
    s.consentPreview.clear();
    s.consentEntries = 0;
    if (!engine_) return;
    const EngineNames engine = collect_engine_names(&engine_->commands());
    const ProjectNames project = collect_project_names(projectDir_);
    std::vector<Json> sent;
    for (const SendRow& row : plan_send(doc, outbox_of_file(share_env(), file), engine, project))
        if (row.canSend) sent.push_back(row.sent);
    if (sent.empty()) return;
    s.consentEntries = int(sent.size());
    s.consentPreview = build_share_payload(share_env(), sent).dump(2);
}

// ------------------------------------------------------------------------------------------------------- consent dialog

void Editor::draw_share_consent() {
    ShareUi& s = share_;
    if (!s.consentOpen) return;
    const char* id = "Share feedback with the engine developers?###share-consent";
    if (!ImGui::IsPopupOpen(id)) ImGui::OpenPopup(id);
    ImGui::SetNextWindowPos(ImGui::GetMainViewport()->GetCenter(), ImGuiCond_Appearing, ImVec2(0.5f, 0.5f));
    if (!ImGui::BeginPopupModal(id, nullptr, ImGuiWindowFlags_AlwaysAutoResize | ImGuiWindowFlags_NoSavedSettings)) return;
    const float wrap = 680;
    ImGui::PushTextWrapPos(wrap);
    ImGui::TextUnformatted("FactorIA can tell the engine developers what the engine lacked when you made your game, so the next "
                           "version fixes it. Nothing is sent until you choose here.");
    ImGui::Spacing();
    ImGui::TextColored(kGreen, "What is sent");
    ImGui::TextUnformatted("For each entry you send: a title and a description written in engine terms (you read them in the Send "
                           "feedback window before they leave). Also its category, "
                           "severity and effort, whether a person or an AI wrote it, whether it was reviewed, the engine version, "
                           "your operating system, and a random installation id made on this computer (it is tied to no game and "
                           "to no name).");
    ImGui::Spacing();
    ImGui::TextColored(kAmber, "What is never sent");
    ImGui::TextUnformatted("The name of your game, its files, paths, scene, entity or script names, your code and assets, the text "
                           "an entry keeps for you (its own title, description, workaround and notes), your name and your e-mail. "
                           "A program also cuts project names, paths, quoted text, addresses and e-mail addresses out of the share "
                           "text before it leaves. Signing in with GitHub is optional and shares only your login.");
    ImGui::Spacing();
    if (s.consentPreview.empty()) {
        ImGui::TextDisabled("None of your entries could be sent now, so there is nothing to show. The Send feedback window lists "
                            "what would leave this computer, and you choose what to send.");
    } else {
        ImGui::Text("The next report, exactly as it would leave this computer (%d %s):", s.consentEntries,
                    s.consentEntries == 1 ? "entry" : "entries");
        ImGui::BeginChild("##consentpreview", ImVec2(wrap, 190), ImGuiChildFlags_Borders);
        ImGui::PushTextWrapPos(wrap - 24);
        ImGui::TextUnformatted(s.consentPreview.c_str());
        ImGui::PopTextWrapPos();
        ImGui::EndChild();
        at_track("share:consent:preview");
    }
    ImGui::Spacing();
    ImGui::TextDisabled("You can change this at any time in File > Feedback Settings, and read what waits to be sent.");
    ImGui::PopTextWrapPos();
    ImGui::Separator();
    if (ImGui::Button("Always", ImVec2(150, 0))) share_choose_mode(ShareMode::Always);
    at_track("share:consent:always");
    ImGui::SetItemTooltip("Entries that carry a share text go to the engine developers in the background. Send feedback sends the others, "
                          "after you read them.");
    ImGui::SameLine();
    if (ImGui::Button("Ask me each time", ImVec2(150, 0))) share_choose_mode(ShareMode::Ask);
    at_track("share:consent:ask");
    ImGui::SetItemTooltip("Nothing leaves until you press Send in Send feedback, where you read each text and choose what goes.");
    ImGui::SameLine();
    if (ImGui::Button("Never", ImVec2(150, 0))) share_choose_mode(ShareMode::Never);
    at_track("share:consent:never");
    ImGui::SetItemTooltip("Nothing leaves this computer.");
    ImGui::SameLine();
    if (ImGui::SmallButton("Decide later")) {
        s.consentLater = true;
        s.consentOpen = false;
        s.sendAfterConsent = false;
        ImGui::CloseCurrentPopup();
    }
    at_track("share:consent:later");
    ImGui::SetItemTooltip("Close this without choosing. Nothing is sent, and it is asked again the next time the editor starts.");
    if (!s.consentOpen) {
        s.sendAfterConsent = false;  // Decide later: no Send window
        ImGui::CloseCurrentPopup();
    }
    ImGui::EndPopup();
}


// ------------------------------------------------------------------------------------------------- the Send feedback window

// The button of the panel (and the notification of the ask mode): by the mode it opens the window, asks for consent first, or says why not.
void Editor::open_send_window() {
    ShareUi& s = share_;
    if (!engine_ || projectDir_.empty()) return;
    const ShareEnv& env = share_env();
    const ShareSettings settings = load_share_settings(env);
    s.mode = settings.mode;
    s.sharingAvailable = !share_endpoint(env, settings).empty();
    if (!s.sharingAvailable) {
        notify(share_unavailable_message(), 1);
        return;
    }
    if (s.mode == ShareMode::Never) {
        notify("Sharing is off. Turn it on in File > Feedback Settings to send feedback.", 1);
        return;
    }
    if (s.mode == ShareMode::Unset) {  // a person decides first: the consent dialog, then the window
        s.sendAfterConsent = true;
        s.consentLater = false;
        s.consentOpen = true;
        const std::string file = fs::join(projectDir_, engine_->project().feedbackFile);
        Json doc;
        if (auto r = load_feedback(file); r) doc = *r;
        share_fill_consent_preview(file, doc);
        return;
    }
    if (s.sendOpen && s.sendPhase == ShareUi::SendPhase::Choose) {  // already showing: keep the person's checks
        s.sendFocus = true;
        return;
    }
    build_send_window();
}

void Editor::build_send_window() {
    ShareUi& s = share_;
    const ShareEnv& env = share_env();
    const std::string file = fs::join(projectDir_, engine_->project().feedbackFile);
    auto loaded = load_feedback(file);
    if (!loaded.ok()) {
        notify(loaded.error().to_string(), 2);
        return;
    }
    const EngineNames names = collect_engine_names(&engine_->commands());
    const ProjectNames project = collect_project_names(projectDir_);
    s.sendLive = 0;  // anything still running for the window that was showing is not wanted any more
    s.sendSession++;
    s.sendLive = s.sendSession;
    {
        std::lock_guard<std::mutex> lock(s.mu);
        s.aiDone.clear();
    }
    s.sendFile = file;
    s.sendRows.clear();
    s.aiJobs.clear();
    s.sendPhase = ShareUi::SendPhase::Choose;
    s.sendMessage.clear();
    s.sendFlushWanted = false;
    s.sendAiAvailable = true;
    for (SendRow& row : plan_send(*loaded, outbox_of_file(env, file), names, project)) {
        ShareUi::SendRowUi r;
        if (const Json* e = entry_in(*loaded, row.id)) r.entry = *e;
        r.checked = row.checked;
        r.row = std::move(row);
        // The AI check of a text that is going out and was not checked before (an entry marked reviewed already was).
        if (r.checked && r.row.canSend && !r.row.reviewed) {
            r.review = ShareUi::SendReview::Queued;
            s.aiJobs.push_back({s.sendSession, r.row.id, r.row.fields});
        }
        s.sendRows.push_back(std::move(r));
    }
    s.sendAiStart = !s.aiJobs.empty();
    s.sendOpen = s.sendFocus = true;
}

// Send: the checked rows are stored and queued, the others are left out; then the outbox is flushed and the rows show the outcome.
void Editor::send_window_apply() {
    ShareUi& s = share_;
    std::vector<SendChoice> choices;
    // A row that cannot be sent has no text to leave out: it is not part of the choice and stays as it is.
    for (const ShareUi::SendRowUi& r : s.sendRows)
        if (r.row.canSend) choices.push_back({r.row.id, r.checked, r.row.fields, r.reviewPassed});
    const EngineNames names = collect_engine_names(&engine_->commands());
    const SendApplied applied = apply_send(share_env(), s.sendFile, projectDir_, names, choices);
    feedbackMtime_ = INT64_MIN;
    feedbackPolled_ = -10;
    s.tickAt = -10;
    if (!applied.error.empty()) {
        s.sendMessage = applied.error;
        return;
    }
    int queued = 0;
    for (ShareUi::SendRowUi& r : s.sendRows) {
        for (const SendRowResult& res : applied.rows) {
            if (res.id != r.row.id) continue;
            r.resultKind = res.status;
            if (res.status == "queued") {
                r.result = "sending...";
                ++queued;
            } else if (res.status == "rejected") {
                r.result = "Not sent: " + res.message;
            } else if (res.status == "failed") {
                r.result = "Not sent: " + res.message;
            } else {
                r.result = "Left out. It is offered again, unchecked, the next time.";
            }
        }
    }
    if (queued > 0) {
        s.sendPhase = ShareUi::SendPhase::Sending;
        s.sendFlushWanted = true;
        s.sendFlushSession = s.sendSession;
        s.sendMessage = "Sending...";
    } else {
        s.sendPhase = ShareUi::SendPhase::Done;
        s.sendMessage = "Nothing was sent.";
    }
}

// The flush Send asked for is over: what each queued row became is read from the feedback file.
void Editor::send_window_finished(int sent, const std::string& message) {
    ShareUi& s = share_;
    Json doc;
    if (auto r = load_feedback(s.sendFile); r) doc = *r;
    int ok = 0, left = 0;
    for (ShareUi::SendRowUi& r : s.sendRows) {
        if (r.resultKind != "queued") continue;
        const Json* e = entry_in(doc, r.row.id);
        const std::string status = e && e->contains("shared") && (*e)["shared"].is_object() ? (*e)["shared"].value("status", std::string()) : std::string();
        const std::string reason = e && e->contains("shared") && (*e)["shared"].is_object() ? (*e)["shared"].value("reason", std::string()) : std::string();
        if (status == "sent") {
            r.resultKind = "sent";
            r.result = "Sent. Thank you.";
            ++ok;
        } else if (status == "rejected") {
            r.resultKind = "rejected";
            r.result = "The server did not accept it: " + reason;
        } else {
            r.resultKind = "waiting";
            r.result = "Not sent yet" + (message.empty() ? std::string() : ": " + message) + ". It stays in the outbox and goes when the server answers.";
            ++left;
        }
    }
    s.sendPhase = ShareUi::SendPhase::Done;
    s.sendMessage = ok > 0 ? "Sent " + std::to_string(ok) + (ok == 1 ? " entry" : " entries") + " to the engine developers." +
                                 (left > 0 ? " " + std::to_string(left) + " could not be sent yet." : std::string())
                           : (left > 0 ? "Nothing could be sent yet." : "Nothing was sent.");
    (void)sent;
}

void Editor::draw_send_window() {
    ShareUi& s = share_;
    const char* id = "Send feedback###send-feedback";
    if (!s.sendOpen) {
        if (s.sendLive.load() != 0) s.sendLive = 0;
        return;
    }
    if (!ImGui::IsPopupOpen(id)) ImGui::OpenPopup(id);
    s.sendFocus = false;
    const ImVec2 display = ImGui::GetIO().DisplaySize;
    ImGui::SetNextWindowPos(ImGui::GetMainViewport()->GetCenter(), ImGuiCond_Appearing, ImVec2(0.5f, 0.5f));
    ImGui::SetNextWindowSize(ImVec2(std::min(760.0f, display.x - 40.0f), std::min(560.0f, display.y - 60.0f)), ImGuiCond_Appearing);
    bool open = true;
    if (!ImGui::BeginPopupModal(id, &open, ImGuiWindowFlags_NoSavedSettings)) {
        if (!ImGui::IsPopupOpen(id)) s.sendOpen = false;  // closed some other way
        return;
    }
    const bool choosing = s.sendPhase == ShareUi::SendPhase::Choose;
    ImGui::PushTextWrapPos(0);
    if (s.sendRows.empty()) {
        ImGui::TextDisabled("Nothing to send: every open entry was sent already or was refused by the server.");
        at_track("send:empty");
    } else if (choosing) {
        ImGui::TextUnformatted("These entries would be sent. Each text is exactly what leaves this computer: the names of your game are "
                               "already cut out. Uncheck what you do not want to send; Cancel sends nothing.");
    }
    ImGui::PopTextWrapPos();

    int checkedCount = 0;
    bool checking = false;
    for (const ShareUi::SendRowUi& r : s.sendRows) {
        if (r.checked && r.row.canSend) {
            ++checkedCount;
            if (r.review == ShareUi::SendReview::Queued) checking = true;
        }
    }

    const float footer = ImGui::GetFrameHeightWithSpacing() * 2.0f + ImGui::GetStyle().ItemSpacing.y * 2;
    ImGui::BeginChild("##sendrows", ImVec2(0, -footer), ImGuiChildFlags_Borders);
    for (ShareUi::SendRowUi& r : s.sendRows) {
        ImGui::PushID(r.row.id.c_str());
        const bool usable = r.row.canSend;
        ImGui::BeginDisabled(!usable || !choosing);
        ImGui::Checkbox("##send", &r.checked);
        at_track("send:check:" + r.row.id, usable && choosing);
        ImGui::EndDisabled();
        if (!usable) r.checked = false;
        ImGui::SameLine();
        ImGui::TextColored(ImVec4(0.6f, 0.8f, 1, 1), "%s", usable ? r.row.fields.title.c_str() : r.entry.value("title", std::string()).c_str());
        at_track("send:title:" + r.row.id);
        ImGui::SameLine();
        ImGui::TextDisabled("%s  [%s, %s]%s", r.row.id.c_str(), r.row.category.c_str(), r.row.severity.c_str(),
                            r.row.resend ? "  (sent before; it happened again)" : "");
        ImGui::Indent(ImGui::GetFrameHeight());
        ImGui::PushTextWrapPos(0);
        if (!usable) {
            ImGui::TextColored(kAmber, "It cannot be sent as it is: %s", r.row.problem.c_str());
            at_track("send:problem:" + r.row.id);
        } else {
            auto field = [&](const char* label, const std::string& text) {
                if (text.empty()) return;
                ImGui::TextDisabled("%s", label);
                ImGui::TextUnformatted(text.c_str());
            };
            field("missing", r.row.fields.missing);
            at_track("send:text:" + r.row.id);
            field("suggestion", r.row.fields.suggestion);
            field("workaround", r.row.fields.workaround);
            if (!r.row.removed.empty()) ImGui::TextDisabled("The sanitizer took out: %s.", removals_text(r.row.removed).c_str());
        }
        if (!r.row.note.empty()) ImGui::TextDisabled("%s", r.row.note.c_str());
        if (r.review == ShareUi::SendReview::Queued) {
            ImGui::TextColored(kAmber, "checking with AI...");
            at_track("send:reviewing:" + r.row.id);
        } else if (!r.reviewNote.empty()) {
            ImGui::TextColored(r.review == ShareUi::SendReview::Passed ? kGreen : r.review == ShareUi::SendReview::Failed ? kRed : kAmber, "%s",
                               r.reviewNote.c_str());
            at_track("send:review:" + r.row.id);
        }
        if (!r.result.empty()) {
            ImGui::TextColored(r.resultKind == "sent" ? kGreen : r.resultKind == "queued" || r.resultKind == "waiting" || r.resultKind == "skipped" ? kAmber : kRed,
                               "%s", r.result.c_str());
            at_track("send:result:" + r.row.id);
        }
        ImGui::PopTextWrapPos();
        ImGui::Unindent(ImGui::GetFrameHeight());
        ImGui::Separator();
        ImGui::PopID();
    }
    ImGui::EndChild();

    if (!s.sendMessage.empty()) {
        ImGui::PushTextWrapPos(0);
        ImGui::TextWrapped("%s", s.sendMessage.c_str());
        ImGui::PopTextWrapPos();
        at_track("send:message");
    }
    if (choosing) {
        const bool canSend = checkedCount > 0 && !checking;
        ImGui::BeginDisabled(!canSend);
        if (ImGui::Button("Send", ImVec2(110, 0))) send_window_apply();
        at_track("send:ok", canSend);
        ImGui::EndDisabled();
        if (!canSend) ImGui::SetItemTooltip("%s", checking ? "Wait for the AI check of the checked entries, or uncheck them." : "Check at least one entry.");
        ImGui::SameLine();
        if (ImGui::Button("Cancel", ImVec2(110, 0))) open = false;
        at_track("send:cancel");
        ImGui::SetItemTooltip("Close this window. Nothing is sent or changed.");
    } else {
        if (ImGui::Button("Close", ImVec2(110, 0))) open = false;
        at_track("send:close");
        if (s.sendPhase == ShareUi::SendPhase::Sending) {
            ImGui::SameLine();
            ImGui::TextDisabled("sending...");
        }
    }
    if (!open) {
        s.sendOpen = false;
        s.sendLive = 0;
        ImGui::CloseCurrentPopup();
    }
    ImGui::EndPopup();
}

// ------------------------------------------------------------------------------------------------------ Feedback Settings

void Editor::open_share_settings() {
    share_.settingsOpen = share_.settingsFocus = true;
    share_.settingsPolled = -10;
}

void Editor::draw_share_settings_window() {
    ShareUi& s = share_;
    if (!s.settingsOpen) return;
    const ShareEnv& env = share_env();
    if (time_ - s.settingsPolled > 1.0) {
        s.settingsPolled = time_;
        s.settings = load_share_settings(env);
        s.status = share_status(env);
    }
    ImGui::SetNextWindowSize(ImVec2(560, 560), ImGuiCond_FirstUseEver);
    if (s.settingsFocus) {
        ImGui::SetNextWindowFocus();
        s.settingsFocus = false;
    }
    if (!ImGui::Begin("Feedback Settings###share-settings", &s.settingsOpen)) {
        ImGui::End();
        return;
    }
    ImGui::PushTextWrapPos(0);
    ImGui::TextDisabled("Tell the engine developers what the engine lacked. You send feedback with Send feedback in the Engine Feedback "
                        "panel; only a short text in engine terms leaves this computer, after a program cut the names of your game out of it.");
    ImGui::PopTextWrapPos();
    const bool available = s.status.value("available", false);
    if (!available) {
        ImGui::PushTextWrapPos(0);
        ImGui::TextColored(kRed, "%s", s.status.value("howToFix", std::string("Sharing is not available in this build.")).c_str());
        ImGui::PopTextWrapPos();
        at_track("share:settings:unavailable");
    }
    if (!s.settings.warning.empty()) {
        ImGui::PushTextWrapPos(0);
        ImGui::TextColored(kAmber, "%s", s.settings.warning.c_str());
        ImGui::PopTextWrapPos();
    }

    ImGui::SeparatorText("Mode");
    struct Choice {
        ShareMode mode;
        const char* name;
        const char* tip;
    };
    const Choice choices[] = {
        {ShareMode::Always, "Always", "Entries that carry a share text (an AI writes one when it reports) go to the engine developers in the background. "
         "Send feedback sends the others, after you read them."},
        {ShareMode::Ask, "Ask me each time", "Nothing leaves until you press Send in Send feedback (a notification opens it), where you read each text and choose what goes."},
        {ShareMode::Never, "Never", "Nothing leaves this computer, and Send feedback is off. What waits in the outbox is dropped."}};
    for (const Choice& c : choices) {
        if (ImGui::RadioButton(c.name, s.settings.mode == c.mode) && s.settings.mode != c.mode) share_choose_mode(c.mode);
        at_track(std::string("share:settings:mode:") + share_mode_name(c.mode));
        ImGui::SetItemTooltip("%s", c.tip);
    }
    if (s.settings.mode == ShareMode::Unset) ImGui::TextDisabled("Not chosen yet: nothing is sent.");

    ImGui::SeparatorText("Installation id");
    ImGui::PushTextWrapPos(0);
    ImGui::TextDisabled("A random number that lets the developers count reports once. It is tied to no game and no name.");
    ImGui::PopTextWrapPos();
    ImGui::TextUnformatted(s.settings.installId.empty() ? "(made with the first report)" : s.settings.installId.c_str());
    at_track("share:settings:installid");
    ImGui::SameLine();
    ImGui::BeginDisabled(s.settings.installId.empty());
    if (ImGui::SmallButton("Reset id")) {
        ShareSettings fresh = load_share_settings(env);
        fresh.installId.clear();
        if (auto r = save_share_settings(env, fresh); !r) s.settingsMessage = r.error().to_string();
        else if (auto id = ensure_install_id(env); id) s.settingsMessage = "New installation id made.";
        s.settingsPolled = -10;
    }
    at_track("share:settings:resetid");
    ImGui::EndDisabled();
    ImGui::SetItemTooltip("Make a new random id: the developers cannot link new reports to the old ones.");

    ImGui::SeparatorText("GitHub (optional)");
    const bool signedIn = s.status.value("signedIn", false);
    bool haveCode = false;
    DeviceCode code;
    std::string signInError;
    {
        std::lock_guard<std::mutex> lock(s.mu);  // copied: the drawing below calls functions that take the lock themselves
        haveCode = s.haveCode;
        code = s.code;
        signInError = s.signInError;
    }
    {
        if (s.signInRunning) {
            if (haveCode) {
                ImGui::PushTextWrapPos(0);
                ImGui::TextUnformatted("Open the address below, enter this code and authorize FactorIA. This window finishes by itself.");
                ImGui::PopTextWrapPos();
                ImGui::Text("Code:");
                ImGui::SameLine();
                ImGui::TextColored(ImVec4(0.6f, 0.9f, 1, 1), "%s", code.userCode.c_str());
                at_track("share:settings:code");
                ImGui::Text("Address: %s", code.verificationUri.c_str());
                at_track("share:settings:url");
                if (ImGui::Button("Open in browser")) {
                    if (autotest_) s.settingsMessage = "(autotest) would open " + code.verificationUri;
                    else if (std::string why = open_url(code.verificationUri); !why.empty()) s.settingsMessage = why;
                }
                at_track("share:settings:open");
                ImGui::SameLine();
            } else {
                ImGui::TextDisabled("Asking GitHub for a code...");
            }
            if (ImGui::Button("Cancel")) s.signInCancel = true;
            at_track("share:settings:cancel");
        } else if (signedIn) {
            ImGui::Text("Signed in as %s. Your reports carry your GitHub login.", s.status.value("login", std::string("GitHub")).c_str());
            at_track("share:settings:login");
            if (ImGui::Button("Sign out")) {
                if (auto r = share_sign_out(env); !r) s.settingsMessage = r.error().to_string();
                else s.settingsMessage = "Signed out. New reports are anonymous.";
                s.settingsPolled = -10;
            }
            at_track("share:settings:signout");
        } else {
            ImGui::PushTextWrapPos(0);
            ImGui::TextDisabled("Not signed in: reports are anonymous. Signing in lets the developers thank you and ask what you meant.");
            ImGui::PopTextWrapPos();
            const bool canSignIn = available && !env.githubClientId.empty();
            ImGui::BeginDisabled(!canSignIn);
            if (ImGui::Button("Sign in with GitHub")) share_start_sign_in();
            at_track("share:settings:signin");
            ImGui::EndDisabled();
            if (!canSignIn) ImGui::SetItemTooltip("%s", available ? "This build has no GitHub sign-in." : "Sharing is not available in this build.");
        }
        if (!signInError.empty()) {
            ImGui::PushTextWrapPos(0);
            ImGui::TextColored(kRed, "%s", signInError.c_str());
            ImGui::PopTextWrapPos();
        }
    }

    ImGui::SeparatorText("Outbox");
    const Json outbox = s.status.contains("outbox") ? s.status["outbox"] : Json::object();
    const int queued = outbox.value("queued", 0), waiting = outbox.value("waitingForConfirmation", 0);
    ImGui::Text("%d to send, %d waiting for your answer (Send feedback)", queued, waiting);
    at_track("share:settings:outbox");
    if (waiting > 0) {
        ImGui::SameLine();
        if (ImGui::SmallButton("Review")) open_send_window();
        at_track("share:settings:review");
    }
    if (outbox.contains("failed") && outbox["failed"].is_array()) {
        for (const Json& f : outbox["failed"]) {
            ImGui::PushTextWrapPos(0);
            ImGui::TextColored(kAmber, "%s failed %d time(s); next try in %d s. %s", f.value("id", std::string()).c_str(),
                               f.value("attempts", 0), f.value("retryInSeconds", 0), f.value("error", std::string()).c_str());
            ImGui::PopTextWrapPos();
        }
    }
    if (s.status.contains("lastSend") && s.status["lastSend"].is_object()) {
        const Json& l = s.status["lastSend"];
        ImGui::PushTextWrapPos(0);
        ImGui::TextDisabled("Last attempt: %s. %s", l.value("outcome", std::string()).c_str(), l.value("message", std::string()).c_str());
        ImGui::PopTextWrapPos();
    }
    {
        const bool canSend = available && (s.settings.mode == ShareMode::Always || s.settings.mode == ShareMode::Ask) && queued > 0 &&
                             !s.flushRunning;
        ImGui::BeginDisabled(!canSend);
        if (ImGui::Button("Send now")) share_start_flush(true);
        at_track("share:settings:sendnow");
        ImGui::EndDisabled();
        ImGui::SetItemTooltip("%s", s.settings.mode == ShareMode::Ask
                                        ? "Sends what you confirmed, now, without waiting for a retry time."
                                        : "Sends what waits in the outbox, now, without waiting for a retry time.");
        if (s.flushRunning) {
            ImGui::SameLine();
            ImGui::TextDisabled("sending...");
        }
    }
    if (!s.settingsMessage.empty()) {
        ImGui::PushTextWrapPos(0);
        ImGui::TextWrapped("%s", s.settingsMessage.c_str());
        ImGui::PopTextWrapPos();
        at_track("share:settings:message");
    }
    ImGui::End();
}

// ---------------------------------------------------------------------------------------------------- panel: share column

void Editor::draw_feedback_share_cell(const Json& entry, const char* track) {
    const ShareColumn c = share_column(entry);
    ImGui::TextColored(share_color(c.kind), "%s", c.label.c_str());
    if (ImGui::IsItemHovered()) ImGui::SetTooltip("%s", c.tooltip.c_str());
    at_track(track ? std::string(track) : "feedback:share:" + entry.value("id", std::string()));
}

}  // namespace fa::editor
