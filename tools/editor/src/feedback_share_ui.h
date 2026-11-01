// The editor's state for sharing feedback with the engine developer (docs/EDITOR.md, "Feedback sharing"): the consent dialog,
// the Feedback Settings window, the review list of the "Ask me each time" mode and the share part of the Engine Feedback panel.
// The drawing and the polling are feedback_share_ui.cpp; the rules (what a share column says, the limits, the suggestion) are
// feedback_share_model.h and run in unit tests.
//
// The blocking calls (GitHub sign-in, a flush of the outbox, ai.review_feedback) run on one thread each; what they produce
// waits under `mu` for the next frame. ~Editor joins all three.
#pragma once

#include <atomic>
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
    std::atomic<bool> failReports{false};   // the report server is down
    std::atomic<int> uuids{0};
};

struct ShareUi {
    // --- polling (once a second, only the files that changed are read again)
    double tickAt = -10;
    std::string docFile;               // the feedback file the numbers below are about
    std::int64_t docStamp = INT64_MIN; // its modification time when they were read
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

    // --- ask mode: the entries that wait for the person's answer
    bool reviewOpen = false;
    bool reviewFocus = false;
    std::vector<OutboxItem> waiting;
    std::set<std::string> notified;    // outbox keys the person was already told about

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
    std::string aiId;                  // the entry the review is about
    Json aiResult;                     // the answer of ai.review_feedback, or {error}
    bool aiNew = false;

    // --- the share part of the panel
    std::string editId;                // the entry the edit boxes hold
    ShareFields edit, base;            // what the boxes hold, and what the file held when they were filled
    Json baseShare;                    // the entry's `share` when they were filled (a change on disk refills untouched boxes)
    std::string editMessage;
    Json reviewShown;                  // the last review result of editId, shown under the buttons
    ShareFields newShare;              // the share text of the Add entry form

    ~ShareUi() { join_all(); }
    // Stops what can be stopped and waits for the threads (the sign-in polls for the code until its flag is set).
    void join_all() {
        signInCancel = true;
        for (std::thread* t : {&signInThread, &flushThread, &aiThread})
            if (t->joinable()) t->join();
    }
};

}  // namespace fa::editor
