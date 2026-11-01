// Feedback sharing in the editor (docs/EDITOR.md, "Feedback sharing"): the consent dialog, File > Feedback Settings, the review
// list of the "Ask me each time" mode and the share part of the Engine Feedback panel. The client is fa/tooling/feedback_share.h;
// the rules the panel applies are feedback_share_model.h.
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

// The limits as the person sees them: "12 / 120". Red outside the limits.
void counter(const std::string& text, int min, int max) {
    const int n = text_chars(std::string(trim(text)));
    const bool bad = n > max || (n < min);
    ImGui::SameLine();
    ImGui::TextColored(bad ? kRed : kGrey, "%d / %d", n, max);
    if (min > 0) {
        ImGui::SameLine();
        ImGui::TextDisabled("(at least %d)", min);
    }
}

// One share field: label, counter, the box.
void share_field(const char* label, const char* id, std::string& text, int min, int max, float lines, const std::string& track,
                 Editor& ed) {
    ImGui::TextUnformatted(label);
    counter(text, min, max);
    if (lines <= 1.0f) {
        ImGui::SetNextItemWidth(-FLT_MIN);
        ImGui::InputText(id, &text);
    } else {
        ImGui::InputTextMultiline(id, &text, ImVec2(-FLT_MIN, ImGui::GetTextLineHeight() * lines + 8));
    }
    if (!track.empty()) ed.at_track(track);
}

// What a typed share text becomes when it is stored: the limits are checked, then the sanitizer cuts project names, paths, quotes,
// addresses. false = the limits are not met (`message` says which). true = `out` is what to store: the sanitized text, or the typed
// one when the sanitizer refuses it (kept so the person can edit it; it will not be sent while it is refused, and the share column
// says why).
bool prepare_share(const ShareFields& typed, const EngineNames& engine, const ProjectNames& project, ShareFields& out, std::string& message) {
    ShareFields t;
    t.title = std::string(trim(typed.title));
    t.missing = std::string(trim(typed.missing));
    t.suggestion = std::string(trim(typed.suggestion));
    t.workaround = std::string(trim(typed.workaround));
    if (std::string problem = share_fields_problem(t); !problem.empty()) {
        message = problem;
        return false;
    }
    const SanitizedShare clean = sanitize_share(t.to_json(), engine, project);
    if (!clean.ok) {
        out = t;
        message = "Saved, but it will not be sent as written: " + clean.reason();
        return true;
    }
    out.title = clean.title;
    out.missing = clean.missing;
    out.suggestion = clean.suggestion;
    out.workaround = clean.workaround;
    message = clean.removed.empty() ? "Saved." : "Saved. The sanitizer took out: " + removals_text(clean.removed) + ".";
    return true;
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
        case ShareMode::Always: notify("Feedback sharing: always. Share texts go to the engine developers as they are written.", 0); break;
        case ShareMode::Ask: notify("Feedback sharing: you are asked before anything is sent.", 0); break;
        case ShareMode::Never: notify("Feedback sharing is off. Nothing leaves this computer.", 0); break;
        default: break;
    }
}

// ---------------------------------------------------------------------------------------------------------------- threads

void Editor::share_start_flush(bool force) {
    ShareUi& s = share_;
    if (s.flushRunning) return;
    if (s.flushThread.joinable()) s.flushThread.join();
    s.flushRunning = true;
    s.flushAt = time_;
    s.flushThread = std::thread([&s, env = share_env(), force] {
        FlushOptions o;
        o.force = force;
        o.oneBatch = false;
        o.timeoutSec = 15;
        const FlushResult r = share_flush(env, o);
        {
            std::lock_guard<std::mutex> lock(s.mu);
            s.flushMessage = r.message;
            s.flushSent = r.sent + r.merged;
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

// ai.review_feedback on a thread. The command is the real one, registered on a copy of the engine's command list whose handlers
// are never called: the review only reads the names and summaries (its engine reference). It reads and writes the feedback file and
// calls the model; it never sets the sharing mode and sends nothing.
void Editor::share_start_ai_review(const std::string& id) {
    ShareUi& s = share_;
    if (s.aiRunning) return;
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
    {
        std::lock_guard<std::mutex> lock(s.mu);
        s.aiId = id;
        s.aiResult = Json();
        s.aiNew = false;
    }
    s.reviewShown = Json();
    s.aiRunning = true;
    s.aiThread = std::thread([&s, reg, id] {
        const CommandResult res = reg->call("ai.review_feedback", Json::object({{"id", id}}));
        {
            std::lock_guard<std::mutex> lock(s.mu);
            if (res.ok) s.aiResult = res.result;
            else s.aiResult = Json::object({{"error", res.error.value("message", std::string("the review failed"))},
                                            {"hint", res.error.value("hint", std::string())}});
            s.aiId = id;
            s.aiNew = true;
        }
        s.aiRunning = false;
    });
}

// ------------------------------------------------------------------------------------------------------------------ tick

void Editor::feedback_share_tick() {
    ShareUi& s = share_;
    {  // what the threads handed over
        std::lock_guard<std::mutex> lock(s.mu);
        if (s.flushNew) {
            s.flushNew = false;
            if (s.flushSent > 0)
                notify("Shared " + std::to_string(s.flushSent) + (s.flushSent == 1 ? " feedback entry" : " feedback entries") +
                           " with the engine developers. Thank you.",
                       0);
            s.settingsPolled = -10;
            feedbackMtime_ = INT64_MIN;  // `shared` was written into the file
            feedbackPolled_ = -10;
        }
        if (!s.signedInAs.empty()) {
            s.settingsMessage = "Signed in as " + s.signedInAs + ".";
            s.signedInAs.clear();
            s.settingsPolled = -10;
        }
        if (s.aiNew) {
            s.aiNew = false;
            if (s.aiId == s.editId) s.reviewShown = s.aiResult;
            feedbackMtime_ = INT64_MIN;  // the review may have rewritten `share` and set `reviewed`
            feedbackPolled_ = -10;
        }
    }
    if (time_ - s.tickAt < 1.0) return;
    s.tickAt = time_;
    const ShareEnv& env = share_env();
    const ShareSettings settings = load_share_settings(env);
    s.mode = settings.mode;
    const bool haveProject = engine_ && !projectDir_.empty();

    std::string file;
    Json doc;
    bool docLoaded = false;
    if (haveProject) {
        file = fs::join(projectDir_, engine_->project().feedbackFile);
        const bool exists = fs::exists(engine_->project().feedbackFile);
        const std::int64_t stamp = exists ? fs::modified_time(engine_->project().feedbackFile) : 0;
        if (file != s.docFile || stamp != s.docStamp || s.mode != s.checkedMode) {
            s.docFile = file;
            s.docStamp = stamp;
            s.entryCount = 0;
            if (exists) {
                if (auto r = load_feedback(file); r && r->contains("entries") && (*r)["entries"].is_array()) {
                    doc = *r;
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
    if (s.mode != ShareMode::Unset && s.consentOpen) s.consentOpen = false;  // answered somewhere else (the terminal)

    // First time: a project with feedback entries and no answer yet. Where sharing is not available nothing could be sent, so
    // nothing is asked either (File > Feedback Settings says why).
    if (s.mode == ShareMode::Unset && s.entryCount > 0 && !s.consentLater && !s.consentOpen && docLoaded &&
        !share_endpoint(env, settings).empty()) {
        s.consentOpen = true;
        s.consentPreview.clear();
        s.consentEntries = 0;
        const std::vector<std::string> ids = entries_to_queue(doc);
        if (!ids.empty()) {
            const EngineNames engine = collect_engine_names(&engine_->commands());
            const Json preview = share_preview(env, file, projectDir_, engine, ids);
            std::vector<Json> sent;
            for (const Json& e : preview["entries"])
                if (e.contains("sent")) sent.push_back(e["sent"]);
            if (!sent.empty()) {
                s.consentEntries = int(sent.size());
                s.consentPreview = build_share_payload(env, sent).dump(2);
            }
        }
    }

    // always / ask: the entries with a share text and no answer yet go to the outbox (a rejection is written back with its reason).
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

    // ask: the entries that wait for the person's answer.
    if (s.mode == ShareMode::Ask) {
        s.waiting = share_waiting(env);
        int fresh = 0;
        for (const OutboxItem& it : s.waiting)
            if (s.notified.insert(it.key).second) ++fresh;
        if (fresh > 0 && !s.reviewOpen) {
            notify_action(std::to_string(s.waiting.size()) + (s.waiting.size() == 1 ? " feedback entry waits" : " feedback entries wait") +
                              " for your answer before anything is sent.",
                          "Review", [this] { share_.reviewOpen = share_.reviewFocus = true; }, "share:notify");
        }
    } else {
        s.waiting.clear();
    }

    // always / ask: send what is due (the confirmed ones, in ask mode), at most one flush every few seconds.
    if ((s.mode == ShareMode::Always || s.mode == ShareMode::Ask) && !s.flushRunning && time_ - s.flushAt > 5.0 && share_has_due(env))
        share_start_flush(false);
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
    ImGui::TextUnformatted("The share text of a feedback entry: a title and a description written in engine terms. Also its category, "
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
        ImGui::TextDisabled("None of your entries has a share text yet, so there is nothing to send now. The next report will look "
                            "like the one the Engine Feedback panel shows next to each entry.");
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
    ImGui::SetItemTooltip("Share texts go to the engine developers as they are written, in the background.");
    ImGui::SameLine();
    if (ImGui::Button("Ask me each time", ImVec2(150, 0))) share_choose_mode(ShareMode::Ask);
    at_track("share:consent:ask");
    ImGui::SetItemTooltip("You read each share text first and answer Send or Don't send.");
    ImGui::SameLine();
    if (ImGui::Button("Never", ImVec2(150, 0))) share_choose_mode(ShareMode::Never);
    at_track("share:consent:never");
    ImGui::SetItemTooltip("Nothing leaves this computer.");
    ImGui::SameLine();
    if (ImGui::SmallButton("Decide later")) {
        s.consentLater = true;
        s.consentOpen = false;
        ImGui::CloseCurrentPopup();
    }
    at_track("share:consent:later");
    ImGui::SetItemTooltip("Close this without choosing. Nothing is sent, and it is asked again the next time the editor starts.");
    if (!s.consentOpen) ImGui::CloseCurrentPopup();
    ImGui::EndPopup();
}

// ------------------------------------------------------------------------------------------------- ask mode: review list

void Editor::draw_share_review_window() {
    ShareUi& s = share_;
    if (!s.reviewOpen) return;
    ImGui::SetNextWindowSize(ImVec2(620, 460), ImGuiCond_FirstUseEver);
    if (s.reviewFocus) {
        ImGui::SetNextWindowFocus();
        s.reviewFocus = false;
    }
    if (!ImGui::Begin("Feedback waiting to be sent###share-review", &s.reviewOpen)) {
        ImGui::End();
        return;
    }
    ImGui::PushTextWrapPos(0);
    if (s.waiting.empty()) {
        ImGui::TextDisabled("Nothing waits for your answer.");
        at_track("share:review:empty");
    } else {
        ImGui::TextUnformatted("These share texts are exactly what would be sent. Nothing leaves this computer until you press Send.");
    }
    ImGui::PopTextWrapPos();
    if (!s.waiting.empty()) {
        if (ImGui::Button("Send all")) {
            share_confirm(share_env());
            s.flushAt = -100;
            s.tickAt = -10;
            s.waiting.clear();
        }
        at_track("share:review:sendall");
        ImGui::SameLine();
        if (ImGui::Button("Don't send any")) {
            share_drop(share_env());
            s.tickAt = -10;
            s.waiting.clear();
            feedbackMtime_ = INT64_MIN;
            feedbackPolled_ = -10;
        }
        at_track("share:review:dropall");
        ImGui::Separator();
    }
    ImGui::BeginChild("##sharereviewlist", ImVec2(0, 0));
    std::string answered, sendKey, dropKey;
    for (const OutboxItem& it : s.waiting) {
        ImGui::PushID(it.key.c_str());
        const Json& e = it.entry;
        ImGui::TextColored(ImVec4(0.6f, 0.8f, 1, 1), "%s", e.value("title", std::string()).c_str());
        ImGui::SameLine();
        ImGui::TextDisabled("[%s, %s]", e.value("category", std::string()).c_str(), e.value("severity", std::string()).c_str());
        ImGui::PushTextWrapPos(0);
        for (const char* key : {"missing", "suggestion", "workaround"}) {
            if (!e.contains(key) || !e[key].is_string()) continue;
            ImGui::TextDisabled("%s", key);
            ImGui::TextUnformatted(e[key].get<std::string>().c_str());
        }
        ImGui::PopTextWrapPos();
        if (ImGui::Button("Send")) sendKey = it.key;
        at_track("share:review:send:" + it.localId);
        ImGui::SameLine();
        if (ImGui::Button("Don't send")) dropKey = it.key;
        at_track("share:review:drop:" + it.localId);
        ImGui::Separator();
        ImGui::PopID();
    }
    ImGui::EndChild();
    if (!sendKey.empty()) {
        share_confirm(share_env(), {sendKey});
        s.flushAt = -100;
        s.tickAt = -10;
        s.waiting.erase(std::remove_if(s.waiting.begin(), s.waiting.end(), [&](const OutboxItem& i) { return i.key == sendKey; }), s.waiting.end());
    }
    if (!dropKey.empty()) {
        share_drop(share_env(), {dropKey});
        s.tickAt = -10;
        feedbackMtime_ = INT64_MIN;
        feedbackPolled_ = -10;
        s.waiting.erase(std::remove_if(s.waiting.begin(), s.waiting.end(), [&](const OutboxItem& i) { return i.key == dropKey; }), s.waiting.end());
    }
    ImGui::End();
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
    ImGui::TextDisabled("Tell the engine developers what the engine lacked. Only the share text of an entry leaves this computer, "
                        "after a program cut the names of your game out of it.");
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
        {ShareMode::Always, "Always", "Share texts go to the engine developers as they are written, in the background."},
        {ShareMode::Ask, "Ask me each time", "You read each share text first (a notification opens the list) and answer Send or Don't send."},
        {ShareMode::Never, "Never", "Nothing leaves this computer. What waits in the outbox is dropped."}};
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
    ImGui::Text("%d to send, %d waiting for your answer", queued, waiting);
    at_track("share:settings:outbox");
    if (waiting > 0) {
        ImGui::SameLine();
        if (ImGui::SmallButton("Review")) s.reviewOpen = s.reviewFocus = true;
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

void Editor::draw_feedback_share_cell(const Json& entry) {
    const ShareColumn c = share_column(entry);
    ImGui::TextColored(share_color(c.kind), "%s", c.label.c_str());
    if (ImGui::IsItemHovered()) ImGui::SetTooltip("%s", c.tooltip.c_str());
    at_track("feedback:share:" + entry.value("id", std::string()));
}

// ----------------------------------------------------------------------------------------- panel: the detail of one entry

void Editor::draw_feedback_share_detail(const Json& en, const std::string& path) {
    ShareUi& s = share_;
    const std::string id = en.value("id", std::string());
    const Json curShare = en.contains("share") ? en["share"] : Json();
    bool refill = false;
    if (s.editId != id) {
        s.editId = id;
        s.editMessage.clear();
        s.reviewShown = Json();
        refill = true;
    } else if (s.edit == s.base && s.baseShare != curShare) {  // untouched boxes follow the file (an AI or the review rewrote it)
        refill = true;
    }
    if (refill) {
        s.base = s.edit = ShareFields::from_entry(en);
        s.baseShare = curShare;
    }
    const bool hasShare = en.contains("share") && en["share"].is_object();
    const bool dirty = !(s.edit == s.base);

    ImGui::Spacing();
    ImGui::SeparatorText("Share with the engine developers");
    {
        const ShareColumn c = share_column(en);
        ImGui::TextDisabled("state:");
        ImGui::SameLine();
        ImGui::TextColored(share_color(c.kind), "%s", c.label.c_str());
        at_track("feedback:share:state");
        ImGui::SameLine();
        if (hasShare) ImGui::TextDisabled(en.value("reviewed", false) ? "- reviewed" : "- not reviewed");
        ImGui::PushTextWrapPos(0);
        ImGui::TextDisabled("%s", c.tooltip.c_str());
        ImGui::PopTextWrapPos();
    }
    if (!hasShare && !dirty) {
        ImGui::PushTextWrapPos(0);
        ImGui::TextDisabled("No share text: this entry stays on this computer. A share text is the same gap told in engine terms only "
                            "(no name of your game, no file); the sanitizer checks it again when you save.");
        ImGui::PopTextWrapPos();
    }
    const auto& limits = share_limits();
    share_field("title", "##sh_title", s.edit.title, limits[0].min, limits[0].max, 1, "feedback:share:title", *this);
    share_field("missing", "##sh_missing", s.edit.missing, limits[1].min, limits[1].max, 4, "feedback:share:missing", *this);
    share_field("suggestion (optional)", "##sh_sug", s.edit.suggestion, limits[2].min, limits[2].max, 2, "feedback:share:suggestion", *this);
    share_field("workaround (optional)", "##sh_work", s.edit.workaround, limits[3].min, limits[3].max, 2, "feedback:share:workaround", *this);

    const bool anyText = !s.edit.empty();
    ImGui::BeginDisabled(!dirty || !anyText);
    if (ImGui::Button("Save share text")) {
        const EngineNames names = collect_engine_names(&engine_->commands());
        const ProjectNames project = collect_project_names(projectDir_);
        ShareFields stored;
        if (prepare_share(s.edit, names, project, stored, s.editMessage)) {
            FeedbackShareEdit edit;
            edit.share = stored.to_json();
            if (auto r = set_feedback_share_file(path, id, edit); !r) {
                s.editMessage = r.error().to_string();
            } else {
                s.edit = s.base = stored;
                s.baseShare = Json();  // refilled from the file on the next frame
                feedbackMtime_ = INT64_MIN;
                feedbackPolled_ = -10;
                s.tickAt = -10;
            }
        }
    }
    at_track("feedback:share:save", dirty && anyText);
    ImGui::EndDisabled();
    ImGui::SetItemTooltip("Check the limits, cut the names of your game out, and keep the result. In Always and Ask mode it is queued.");
    ImGui::SameLine();
    if (ImGui::Button("Suggest")) {
        const EngineNames names = collect_engine_names(&engine_->commands());
        const ProjectNames project = collect_project_names(projectDir_);
        const ShareSuggestion sug = suggest_share(en, names, project);
        if (sug.ok) {
            s.edit.title = sug.fields.title;
            s.edit.missing = sug.fields.missing;
            s.edit.suggestion = sug.fields.suggestion;
            s.editMessage = sug.removed.empty() ? "Suggested from the entry. Read it and make it about the engine only, then Save."
                                                : "Suggested from the entry, without: " + removals_text(sug.removed) +
                                                      ". Read it and make it about the engine only, then Save.";
        } else {
            s.editMessage = "No suggestion: " + sug.reason;
        }
    }
    at_track("feedback:share:suggest");
    ImGui::SetItemTooltip("Fill the boxes from this entry's title, description and suggestion with project names removed. "
                          "Nothing is saved or sent until you press Save.");
    ImGui::SameLine();
    ImGui::BeginDisabled(!hasShare);
    if (ImGui::Button("Don't share")) {
        share_drop(share_env(), {path + "#" + id});  // out of the outbox first: it marks the entry skipped, clearing then removes that too
        FeedbackShareEdit edit;
        edit.clearShare = true;
        if (auto r = set_feedback_share_file(path, id, edit); !r) {
            s.editMessage = r.error().to_string();
        } else {
            s.edit = s.base = ShareFields{};
            s.baseShare = Json();
            s.editMessage = "Share text removed: this entry stays on this computer.";
            feedbackMtime_ = INT64_MIN;
            feedbackPolled_ = -10;
        }
    }
    at_track("feedback:share:clear");
    ImGui::EndDisabled();
    ImGui::SetItemTooltip("Remove the share text. The entry stays on this computer.");
    ImGui::SameLine();
    const bool canReview = hasShare && !dirty && !s.aiRunning;
    ImGui::BeginDisabled(!canReview);
    if (ImGui::Button("Review with AI")) share_start_ai_review(id);
    at_track("feedback:share:review", canReview);
    ImGui::EndDisabled();
    ImGui::SetItemTooltip("%s", !hasShare ? "Write a share text first."
                                : dirty    ? "Save the share text first: the review reads what is saved."
                                           : "An AI checks that the gap is real, about the engine and not something it can already do, "
                                             "and rewrites the text if needed. It sends nothing and changes no setting.");
    if (s.aiRunning) {
        ImGui::SameLine();
        ImGui::TextDisabled("reviewing...");
        at_track("feedback:share:reviewing");
    }
    if (!s.editMessage.empty()) {
        ImGui::PushTextWrapPos(0);
        ImGui::TextWrapped("%s", s.editMessage.c_str());
        ImGui::PopTextWrapPos();
        at_track("feedback:share:message");
    }
    if (s.reviewShown.is_object()) {
        const Json& r = s.reviewShown;
        ImGui::PushTextWrapPos(0);
        if (r.contains("error")) {
            ImGui::TextColored(kRed, "Review failed: %s %s", r.value("error", std::string()).c_str(), r.value("hint", std::string()).c_str());
            at_track("feedback:share:review-result");
        } else if (r.value("pass", false)) {
            ImGui::TextColored(kGreen, "Review passed%s: marked as reviewed.", r.value("rewritten", false) ? " (the text was rewritten)" : "");
            at_track("feedback:share:review-result");
        } else {
            ImGui::TextColored(kAmber, "Review did not pass:");
            at_track("feedback:share:review-result");
            if (r.contains("reasons") && r["reasons"].is_array())
                for (const Json& why : r["reasons"]) ImGui::BulletText("%s", why.get<std::string>().c_str());
            if (r.contains("fix") && r["fix"].is_string() && !r["fix"].get<std::string>().empty())
                ImGui::TextDisabled("How to fix it: %s", r["fix"].get<std::string>().c_str());
        }
        ImGui::PopTextWrapPos();
    }
}

// ---------------------------------------------------------------------------------------- panel: the Add entry form's share

// The share boxes of the Add entry form. Returns the share to store with the entry, or null; `problem` says why not when the
// limits are not met.
Json Editor::feedback_new_share(std::string& problem) {
    ShareUi& s = share_;
    problem.clear();
    if (s.newShare.empty()) return Json();
    ShareFields stored;
    std::string message;
    const EngineNames names = collect_engine_names(&engine_->commands());
    const ProjectNames project = collect_project_names(projectDir_);
    if (!prepare_share(s.newShare, names, project, stored, message)) {
        problem = message;
        return Json();
    }
    return stored.to_json();
}

void Editor::draw_feedback_new_share() {
    ShareUi& s = share_;
    ImGui::SeparatorText("Share with the engine developers (optional)");
    ImGui::PushTextWrapPos(0);
    ImGui::TextDisabled("The same gap told in engine terms only. Leave it empty and the entry stays on this computer.");
    ImGui::PopTextWrapPos();
    const auto& limits = share_limits();
    share_field("share title", "##nsh_title", s.newShare.title, limits[0].min, limits[0].max, 1, "feedback:new:share-title", *this);
    share_field("share missing", "##nsh_missing", s.newShare.missing, limits[1].min, limits[1].max, 3, "feedback:new:share-missing", *this);
    share_field("share suggestion (optional)", "##nsh_sug", s.newShare.suggestion, limits[2].min, limits[2].max, 2, "feedback:new:share-suggestion", *this);
    share_field("share workaround (optional)", "##nsh_work", s.newShare.workaround, limits[3].min, limits[3].max, 2, "feedback:new:share-workaround", *this);
    if (ImGui::Button("Suggest a share text")) {
        Json e = Json::object({{"title", fbNewTitle_}, {"missing", fbNewMissing_}, {"suggestion", fbNewSuggestion_}});
        const ShareSuggestion sug = suggest_share(e, collect_engine_names(&engine_->commands()), collect_project_names(projectDir_));
        if (sug.ok) {
            s.newShare = sug.fields;
            fbMessage_ = "Suggested from the entry's text. Read it and make it about the engine only.";
        } else {
            fbMessage_ = "No suggestion: " + sug.reason;
        }
    }
    at_track("feedback:new:suggest");
    ImGui::SetItemTooltip("Fill the boxes from the title, description and suggestion above, with project names removed.");
}

}  // namespace fa::editor
