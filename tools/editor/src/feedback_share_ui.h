// The editor's state for sharing feedback with the engine developer (docs/EDITOR.md, "Sharing feedback"): the consent dialog,
// the Feedback Settings window, the Send feedback window and the share column of the Engine Feedback panel.
// The drawing and the polling are feedback_share_ui.cpp; the rules (what a share column says, which entries the Send window
// lists, what Send stores and queues) are feedback_share_model.h and run in unit tests.
//
// The blocking calls (GitHub sign-in, a flush of the outbox, the AI check of the texts in the Send window) run on one thread
// each; what they produce waits under `mu` for the next frame, tagged with the Send window session it belongs to so a result
// never lands on a window that was closed and opened again. ~Editor joins all three.
#pragma once

#include <atomic>
#include <map>
#include <mutex>
#include <set>
#include <string>
#include <thread>
#include <vector>

#include "feedback_share_model.h"
#include "fa/tooling/feedback_share.h"

namespace fa::editor {

// What the autotest's fake server (editor_app.cpp, on_init) records and is told: sections E2 reads the requests and decides when the
// GitHub authorization "happens" and whether the server answers. The autotest reaches no address.
struct ShareAutotestNet {
    std::mutex mu;
    std::vector<std::string> urls;          // "POST https://..." in the order they were made
    std::vector<std::string> reportBodies;  // the bodies of POST /v1/reports
    std::atomic<bool> authorize{false};     // the person approved the code on github.com
    std::map<std::string, std::string> verdicts;  // shareId -> reason: the reports the engine developers rejected (POST /v1/verdicts)
    std::atomic<bool> failReports{false};   // the report server is down
    std::atomic<int> uuids{0};
};

struct ShareUi {
    // --- polling (once a second, only the files that changed are read again)
    double tickAt = -10;
    ShareKeyCache folderCache{30.0};   // the folder facts of the outbox items (stat calls), kept between ticks for 30 s
    std::string docFile;               // the feedback file the numbers below are about
    std::int64_t docStamp = INT64_MIN; // its modification time when they were read
    bool docRecheck = false;            // read once more next tick: a write right after the read may have kept the same time
    ShareMode checkedMode = ShareMode::Unset;  // the mode the entries were last looked at under (a change reads them again)
    int entryCount = 0;                // entries in the file (the consent dialog's trigger)
    ShareMode mode = ShareMode::Unset;

    // --- consent dialog. The mode is set by this dialog and by Settings, and by nothing else: no command, MCP tool or script
    // may call set_share_mode, because a person decides whether anything leaves the computer.
    bool consentOpen = false;
    bool consentLater = false;         // "Decide later": not asked again until the editor is restarted; the mode stays unset
    std::string consentPreview;        // the next report as the server would receive it (pretty JSON), "" = nothing to send yet
    int consentEntries = 0;            // entries in that report

    // --- Feedback Settings window
    bool settingsOpen = false;
    bool settingsFocus = false;
    double settingsPolled = -10;
    ShareSettings settings;
    Json status;                       // share_status
    std::string settingsMessage;

    // --- ask mode: the entries that wait for the person's answer (the Send feedback window lists them; a notification opens it)
    std::vector<OutboxItem> waiting;
    std::set<std::string> notified;    // outbox keys the person was already told about
    std::string queueError;            // why the last share_queue of the tick failed ("" = it worked): told once, not every second
    double queueErrorAt = -1000;
    double queueRetryAt = 0;           // after a failed share_queue the tick waits until then before asking the lock again

    // --- the Send feedback window. One session per opening: everything that arrives later from a thread carries the session it was
    // started for and is dropped when the window is closed or was opened again since.
    enum class SendReview { None, Queued, Running, Passed, Failed, Error };
    struct SendRowUi {
        SendRow row;
        Json entry;                    // the local entry as it was when the window opened
        bool checked = false;
        SendReview review = SendReview::None;  // the AI check of the text: None = not done (reviewed already, or no AI)
        bool reviewPassed = false;
        bool rewritten = false;        // the AI check rewrote the text
        std::string reviewNote;        // its reasons, what it fixed, or why it could not run
        std::string result;            // after Send: the outcome shown in the row (sent, rejected + reason, waiting for a retry...)
        std::string resultKind;        // queued | sent | waiting | rejected | failed | skipped
    };
    bool sendOpen = false;
    bool sendFocus = false;
    std::uint64_t sendSession = 0;
    std::atomic<std::uint64_t> sendLive{0};  // the session whose results are still wanted (0 = none); read by the AI thread
    std::string sendFile;
    std::vector<SendRowUi> sendRows;
    enum class SendPhase { Choose, Sending, Done };
    SendPhase sendPhase = SendPhase::Choose;
    std::string sendMessage;           // under the buttons: why nothing was sent, or what happened
    bool sendAfterConsent = false;     // the person pressed Send feedback while the mode was unset: the window opens after they choose
    bool sendFlushWanted = false;      // Send queued rows: flush as soon as no flush is running
    std::uint64_t sendFlushSession = 0;  // the session that asked for the flush in flight
    bool sendAiAvailable = true;       // false once the AI check answered "no model": the rows are shown without it
    bool sendAiStart = false;          // a thread is to be started for aiJobs
    struct AiJob {
        std::uint64_t session = 0;
        std::string id;
        ShareFields text;
    };
    struct AiDone {
        std::uint64_t session = 0;
        std::string id;
        Json result;                   // the answer of ai.review_feedback, or {error, code, hint}
    };
    std::vector<AiJob> aiJobs;         // for the next thread (main thread only)
    std::vector<AiDone> aiDone;        // under mu
    std::uint64_t flushSession = 0;    // under mu: the session the finished flush was started for
    bool sharingAvailable = true;      // this build has an endpoint

    // --- background threads and what they hand over (under mu)
    std::mutex mu;
    std::thread signInThread;
    std::atomic<bool> signInRunning{false};
    std::atomic<bool> signInCancel{false};
    bool haveCode = false;
    DeviceCode code;
    std::string signInError;           // the last sign-in failed with this
    std::string signedInAs;            // set when a sign-in just finished
    std::thread flushThread;
    std::atomic<bool> flushRunning{false};
    double flushAt = -100;             // editor time of the last automatic flush
    std::string flushMessage;          // what the last flush did ("" = not read yet)
    int flushSent = 0;
    bool flushNew = false;
    std::thread aiThread;
    std::atomic<bool> aiRunning{false};
    // The engine developers' answers (verdicts): asked on the first tick and about every 30 minutes, on a thread of their own.
    std::thread verdictThread;
    std::atomic<bool> verdictRunning{false};
    double verdictAt = -1e9;           // editor time of the last question
    bool verdictNew = false;           // under mu: a thread finished
    VerdictResult verdictResult;       // under mu

    ~ShareUi() { join_all(); }
    // Stops what can be stopped and waits for the threads (the sign-in polls for the code until its flag is set).
    void join_all() {
        signInCancel = true;
        for (std::thread* t : {&signInThread, &flushThread, &aiThread, &verdictThread})
            if (t->joinable()) t->join();
    }
};

}  // namespace fa::editor
