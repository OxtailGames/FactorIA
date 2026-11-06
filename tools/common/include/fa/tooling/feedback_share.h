// Sharing engine feedback with the engine developer (design: docs/design/FEEDBACK_SHARING.md, user docs: docs/ENGINE_FEEDBACK.md,
// "Sharing with the engine developer").
//
// A feedback entry may carry `share`: a generic copy of the gap written in engine terms only. This header turns that copy
// into something that may leave the machine, and sends it:
//
//   sanitize_share     the deterministic sanitizer: paths, file names, URLs, e-mail addresses, quoted text, the project's
//                      own names, control characters and runs of one character come out; a field under its minimum after
//                      cleaning stops the entry. The preview shows its result. (An efficiency entry's share text comes from its
//                      waste, cleaned the same way; its numbers and fix type travel as a separate block of fixed words and numbers.)
//   ShareSettings      <user config>/feedback-sharing.json: mode (unset | always | ask | never), installation id, GitHub
//                      credential, endpoint override, and `projects`: a mode per project folder that overrides `mode` for that
//                      project (kept here, in the USER's file, never inside the project). Only a person changes a mode (CLI,
//                      editor): no command does.
//   Outbox             <user config>/feedback-outbox.json: sanitized entries waiting to go, retried with backoff.
//   share_flush        one POST /v1/reports of up to 20 entries; every answer of the server is handled.
//   ShareLock          the cross-process lock every read-modify-write of the settings and the outbox takes (the editor and
//                      the CLI are separate processes); a request to the server is never made while it is held.
//   github_sign_in     optional identity: the GitHub device flow, then the server swaps the GitHub token for a credential.
//
// Nothing in here is simulation: it reads the clock, the environment and the network, through ShareEnv so tests replace all
// three and never touch the network or the real user folder.
#pragma once

#include <cstdint>
#include <filesystem>
#include <functional>
#include <map>
#include <memory>
#include <optional>
#include <set>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/core/types.h"
#include "fa/platform/http.h"
#include "fa/tooling/user_config.h"

namespace fa {

inline constexpr const char* kFeedbackShareFormat = "factoria.feedback-share/1";
inline constexpr const char* kFeedbackSharingFile = "feedback-sharing.json";
inline constexpr const char* kFeedbackOutboxFile = "feedback-outbox.json";
inline constexpr const char* kFeedbackOutboxFormat = "factoria.feedback-outbox/1";
inline constexpr const char* kFeedbackShareLockFile = "feedback-share.lock";

// Field limits, the same on the server (docs/design/FEEDBACK_SHARING.md, "Field limits").
inline constexpr int kShareTitleMin = 8, kShareTitleMax = 120;
inline constexpr int kShareMissingMin = 20, kShareMissingMax = 1500;
inline constexpr int kShareSuggestionMax = 1500, kShareWorkaroundMax = 1500;
inline constexpr int kShareMaxEntriesPerRequest = 20;
inline constexpr int kShareMaxVerdictIds = 100;  // shareIds in one POST /v1/verdicts
inline constexpr int kShareMaxBodyBytes = 64 * 1024;
// The most times one entry is sent: the developer's ranking counts min(occurrences, 3) per installation.
inline constexpr int kMaxSharedOccurrences = 3;
// An efficiency entry sends its running totals again after each new report (the server keeps the latest numbers of the installation
// instead of counting voices): at most this many sends per entry.
inline constexpr int kMaxSharedEfficiencySends = 20;

// ------------------------------------------------------------------------------------------------------------- environment

// Blocking HTTP: sends the request and waits for the answer. The system client by default.
using ShareTransport = std::function<HttpResponse(const HttpRequest&)>;

// What this build was configured with: cmake -DFA_FEEDBACK_URL=... and -DFA_FEEDBACK_GITHUB_CLIENT_ID=... ("" by default).
std::string compiled_share_endpoint();
std::string compiled_github_client_id();

struct ShareEnv {
    UserConfigEnv env = system_user_config_env();  // where the user config folder comes from
    ShareTransport transport;                      // empty = the system client (fa/platform/http.h), blocking
    std::function<std::int64_t()> now;             // seconds since 1970; empty = the system clock
    std::function<void(double seconds)> sleep;     // empty = really sleep
    std::function<std::string()> makeUuid;         // empty = a random UUID v4 from the operating system
    std::string defaultEndpoint = compiled_share_endpoint();               // "" = sharing is unavailable
    std::string githubClientId = compiled_github_client_id();              // "" = GitHub sign-in is unavailable
    std::string platform;                          // "" = the platform of this build (macos, windows, linux, other)
    std::string engineVersion;                     // "" = FA_ENGINE_VERSION
    double lockStaleSec = 10.0;                    // a lock file not refreshed for this long (or dated this far in the future) was left by a dead process: taken over
    double lockWaitSec = 12.0;                     // the longest wait for a busy lock (more than lockStaleSec: a dead holder is always beaten).
                                                   // The editor's UI thread uses 0.3 (ui_share_env in the editor): it never waits for seconds

    std::int64_t clock() const;
    std::string config_dir() const;
    std::string os_platform() const;
    std::string version() const;
    HttpResponse send(const HttpRequest& request) const;
};

// The environment the commands use. Tests replace it with a ScopedShareEnv.
ShareEnv& share_env();
struct ScopedShareEnv {
    explicit ScopedShareEnv(ShareEnv replacement);
    ~ScopedShareEnv();
    ScopedShareEnv(const ScopedShareEnv&) = delete;
    ScopedShareEnv& operator=(const ScopedShareEnv&) = delete;

private:
    ShareEnv saved_;
};

// ----------------------------------------------------------------------------------------------------------------- settings

enum class ShareMode { Unset, Always, Ask, Never };
const char* share_mode_name(ShareMode mode);                // "unset" | "always" | "ask" | "never"
std::optional<ShareMode> parse_share_mode(std::string_view name);

struct ShareSettings {
    ShareMode mode = ShareMode::Unset;  // the default: what every project without its own choice follows
    // The projects that chose their own mode (always, ask or never), by share_project_key. Absent = follow `mode`.
    std::map<std::string, ShareMode> projects;
    std::string installId;    // random UUID v4, created on the first send; tied to no project
    std::string credential;   // from the GitHub sign-in; "" = anonymous
    std::string login;        // GitHub login, shown to the user only
    std::string endpoint;     // overrides the compiled-in one (tests, self-hosting)
    std::string path;         // the file it was read from
    std::string warning;      // the file existed but could not be read: it reads as unset
    Json raw = Json::object();  // the whole file: keys this version does not know are written back
};

std::string share_settings_path(const ShareEnv& env);
ShareSettings load_share_settings(const ShareEnv& env);
Result<void> save_share_settings(const ShareEnv& env, const ShareSettings& settings);
// Changes the settings file the safe way: takes the lock, reads the file as it is now, lets `edit` change it, writes it. Use it
// instead of load + save wherever a second process may write at the same time (a stale copy would undo its change).
Result<void> update_share_settings(const ShareEnv& env, const std::function<void(ShareSettings&)>& edit);

// The lock of the settings and the outbox: held while the object lives. Every read-modify-write of those two files (set_share_mode,
// set_project_share_mode, share_queue, share_confirm, share_drop, share_skip, share_discard, ensure_install_id, the sign-in, the
// saves of share_flush) runs under it, so a flush in the editor and a mode change in the terminal cannot undo each other. A lock
// file next to the settings (feedback-share.lock) made with an exclusive create, so it works the same on Windows and POSIX:
//  - the file holds an owner token (process id + a random number); the holder deletes it only while it still holds its own token,
//    so a lock that was taken over is never deleted under its new owner;
//  - a lock file not written for ShareEnv::lockStaleSec (its process died), or dated further than that in the future (a clock set
//    back, a shared folder), is taken over, one waiter at a time (a second exclusive-create file serializes the takeover);
//  - a long change refreshes the file's time (ShareLock::keep_alive) so a live holder never looks dead;
//  - the wait for a busy lock ends after ShareEnv::lockWaitSec: held() is false and error() says why (nothing is then changed);
//  - the same thread may take it again while it holds it (nested use does not wait for itself).
// Reading is lock-free (files are replaced atomically). Never hold it across a network request. Never throws.
class ShareLock {
public:
    explicit ShareLock(const ShareEnv& env);
    ~ShareLock();
    ShareLock(const ShareLock&) = delete;
    ShareLock& operator=(const ShareLock&) = delete;
    bool held() const { return held_; }
    const std::string& error() const { return error_; }  // why it is not held; "" when it is
    const std::string& path() const { return path_; }    // the lock file, as text for messages (UTF-8)
    const std::filesystem::path& file() const { return file_; }
    // True when the lock failed because no file can be made in the folder (no permission, a read-only home, a folder that cannot be
    // created), not because another process holds it: the caller may take a lock somewhere else (FeedbackFileLock).
    bool unwritable() const { return unwritable_; }
    // Refreshes the time of the lock file this thread holds (a no-op when it holds none, or when the time is fresh). Call it inside a
    // loop that may take seconds (many entries written under the lock).
    static void keep_alive();

private:
    void acquire(const ShareEnv& env);
    void refresh();
    bool held_ = false, nested_ = false, unwritable_ = false;
    double staleSec_ = 10.0;
    std::string error_, path_, token_;
    std::filesystem::path file_;
};
// The lock of a read-modify-write of a project's ENGINE_FEEDBACK.json (or its archive) that the editor, the CLI, an agent and a
// retrospective may write at once. It is the ShareLock of the user's folder, so a write that also touches the outbox is covered by the
// same one; when that folder cannot be written (a read-only or missing home, a sandbox) the file is still written, under a lock of the
// same kind in the project's own `.factoria` folder (next to the feedback file), because the report of a gap must not need
// ~/.factoria. held() / error() are those of the lock that was taken; error() names the folder when neither could be.
class FeedbackFileLock {
public:
    FeedbackFileLock(const ShareEnv& env, const std::string& feedbackPath);
    bool held() const;
    const std::string& error() const { return error_; }
    // True when the user's folder was not writable and the project's folder holds the lock.
    bool in_project_folder() const { return local_ != nullptr; }
    ~FeedbackFileLock();
    FeedbackFileLock(const FeedbackFileLock&) = delete;
    FeedbackFileLock& operator=(const FeedbackFileLock&) = delete;

private:
    std::unique_ptr<ShareLock> user_, local_;
    std::string error_;
};
// For the span of its life no lock taken by this thread waits longer than `sec`, whatever ShareEnv::lockWaitSec says. The editor's UI
// thread uses it around commands it runs on its own thread (feedback.delete) so a frame never stalls on another process.
class ShareWaitCap {
public:
    explicit ShareWaitCap(double sec);
    ~ShareWaitCap();
    ShareWaitCap(const ShareWaitCap&) = delete;
    ShareWaitCap& operator=(const ShareWaitCap&) = delete;

private:
    double previous_;
};
// Only a person calls these (the CLI, the editor's Settings): there is no command for them.
// Changes the default, and the outbox items of the projects that FOLLOW it (a project with its own mode keeps its items as
// they are): `never` drops them and marks their entries skipped, `always` confirms the ones waiting for a yes (the person who
// chose always for everything also answers yes for what waited under the default), `ask` puts the queued ones back to waiting. Items an older version queued without a project are left alone, except by `never`, which
// drops them when their file's project has no mode of its own.
Result<void> set_share_mode(const ShareEnv& env, ShareMode mode);

// ---- per project. The choice lives in the user's feedback-sharing.json under `projects`, keyed by the project folder's
// normalized absolute path, so it is never read from the project: a project that arrives copied or downloaded does not
// inherit the choice and follows the default (a copy is another path). Moving or renaming the folder drops its choice back
// to the default.
// The key of a project folder (or of any path): absolute, symlinks resolved when the folder exists, forward slashes, UTF-8
// (also on Windows, where the file names are UTF-16), no trailing slash, and lower case (ASCII letters) where paths ignore
// case: always on Windows, and on a volume that proves it (macOS' default) for a folder that exists. `caseInsensitive` is
// for tests (the default function decides by the platform and, for an existing folder, by the volume).
std::string share_project_key(const std::string& projectDir, bool caseInsensitive);
std::string share_project_key(const std::string& projectDir);
// True when both paths have the same key (a normalized comparison of files and folders).
bool share_same_path(const std::string& a, const std::string& b);
// The key of the outbox item of entry `localId` in `feedbackFile` (OutboxItem::key; what share_confirm and share_drop take).
std::string share_item_key(const std::string& feedbackFile, const std::string& localId);
// The project folder a feedback file belongs to: the nearest folder at or above it with a factoria.json, else its own folder.
std::string share_project_dir_of_file(const std::string& feedbackFile);
// The project's own mode, if it has one. The key is looked up as share_project_key writes it; when it is not there, the folder
// is compared with every stored key that exists on disk (std::filesystem::equivalent: another case, macOS' NFC/NFD spelling,
// a symlink). Fails closed: a folder whose path cannot be resolved at all (a drive that is gone, no permission) reads as `ask`,
// never as the default.
std::optional<ShareMode> share_project_mode(const ShareSettings& settings, const std::string& projectDir);
// The mode that applies to a project: its own, else the default. An empty `projectDir` = the default.
ShareMode effective_share_mode(const ShareSettings& settings, const std::string& projectDir);
// The same for a key kept in the outbox (share_project_key of the project, stored when the entry was queued). An empty key
// (an item written by an older version, which did not know its project) is `ask`: it is never sent before the user says yes.
ShareMode effective_share_mode_of_key(const ShareSettings& settings, const std::string& projectKey);
// "project", "default" or "unresolved" (the folder's path cannot be resolved, so it asks): where effective_share_mode got its answer.
const char* effective_share_source(const ShareSettings& settings, const std::string& projectDir);
// Sets (or, with nullopt, removes) the project's own mode, then applies the mode that now holds for the project to its outbox
// items: `never` (also when it comes from the default after the project's choice was removed) drops them and marks their
// entries skipped; `always` confirms the ones that waited for a yes; `ask` puts the queued ones back to waiting for a yes
// (what was queued under `always` is not sent until the user confirms it). Only a person calls it.
Result<void> set_project_share_mode(const ShareEnv& env, const std::string& projectDir, std::optional<ShareMode> mode);
// The installation id, created and saved when there is none.
Result<std::string> ensure_install_id(const ShareEnv& env);
// The endpoint in use: the user's override, else the compiled-in one, without a trailing "/". "" = sharing is unavailable.
std::string share_endpoint(const ShareEnv& env, const ShareSettings& settings);
// "Sharing is not available in this build: ..." with how to fix it; used by every command when share_endpoint is "".
std::string share_unavailable_message();

// A random UUID v4 ("xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx") from the operating system's random source.
std::string random_uuid_v4();
bool is_uuid_v4(std::string_view text);

// --------------------------------------------------------------------------------------------------------------- sanitizer

// The names the engine itself defines: commands (and their areas), components, fields, enum values and the scripting
// API. They are the only quoted text that survives, and the project's names never remove them.
struct EngineNames {
    std::set<std::string> lower;  // lower case
    bool has(std::string_view name) const;
    // Every dot-separated part is an engine name, or the first one is (a proposed member of an engine type:
    // "Collider2D.oneWay").
    bool token_ok(std::string_view token) const;
};
// From the live registries: the command registry (when given), the reflected components, and the names the engine
// has published (tools/common/api_since.json: components, fields, commands, scripting API).
EngineNames collect_engine_names(const CommandRegistry* registry = nullptr);

// What belongs to the game: the project name and id, scene, prefab, entity and script names, file stems and localization
// keys. Read from the project folder.
struct ProjectNames {
    std::vector<std::string> names;  // as found, longest first
};
ProjectNames collect_project_names(const std::string& projectDir);

struct Removal {
    std::string field;  // title | missing | suggestion | workaround
    std::string kind;   // control | quote | url | email | path | file | project-name | repeat
    std::string text;   // what was removed (shortened)
    Json to_json() const;
};

struct SanitizedShare {
    bool ok = false;          // false: the entry is not sent (see reason)
    std::string title, missing, suggestion, workaround;
    std::vector<Removal> removed;
    std::vector<std::string> problems;  // why it is not ok, one sentence each
    std::string reason() const;         // problems joined; "" when ok
    Json fields() const;                // {title, missing, suggestion?, workaround?}
    Json removed_json() const;
};

// `share` is the entry's `share` object. Deterministic: the same input gives the same output.
SanitizedShare sanitize_share(const Json& share, const EngineNames& engine, const ProjectNames& project);
// One text on its own (the tests and the editor's live preview use it).
std::string sanitize_text(std::string_view field, std::string_view text, const EngineNames& engine,
                          const ProjectNames& project, std::vector<Removal>& removed);

// The entry as the server receives it (docs/design/FEEDBACK_SHARING.md, "POST /v1/reports"): the sanitized share plus
// localId, category, severity, effort, reporterKind and reviewed from the local entry. An efficiency entry adds an `efficiency` block (fix type,
// applies-to, measured and saved numbers: efficiency_share_block in fa/tooling/efficiency.h, never its waste text, evidence or session ids).
Json build_share_entry(const Json& localEntry, const SanitizedShare& share);
// {format, engineVersion, platform, entries}.
Json build_share_payload(const ShareEnv& env, const std::vector<Json>& entries);

// ------------------------------------------------------------------------------------------------------------------- outbox

enum class OutboxState { Queued, Waiting };  // Waiting: mode `ask`, the user has not confirmed it yet

struct OutboxItem {
    std::string key;      // share_project_key(file) + "#" + localId: an entry is in the outbox once
    std::string file;     // the project's ENGINE_FEEDBACK.json (kept locally to write `shared` back; never sent). Stored in UTF-8
                          // (a value an older version wrote in the system code page is read as it is)
    // share_project_key of the project, stored when the entry was queued (written as "project"): the mode of the item is the
    // one of this key, never one worked out again later. "" = an item an older version queued: it waits for the user's
    // answer (state Waiting) whatever the mode.
    std::string projectKey;
    std::string localId;  // FB-0003
    OutboxState state = OutboxState::Queued;
    // What made a Queued item sendable (written as "confirmedBy"): "always" = the mode always (when it was queued, or a person
    // chose always for its project or for the default), "user" = a person confirmed this item (share_confirm). The sender
    // checks it: an item of "always" is sent only while its project's mode is still always, else it goes back to
    // Waiting. "" for Waiting items; an older Queued item without the field reads as "always".
    std::string confirmedBy;
    Json entry;           // the sanitized entry, as sent
    int attempts = 0;
    std::int64_t queuedAt = 0;
    std::int64_t nextAttempt = 0;  // not before this time (seconds since 1970)
    std::string lastError;
};

struct Outbox {
    std::vector<OutboxItem> items;
    Json lastSend;  // {at, outcome, message} of the last attempt, for share_status
    std::string path;
};

// Seconds to wait after the n-th failed attempt (n >= 1): 1 min, 10 min, 1 h, then once a day.
std::int64_t backoff_seconds(int attempts);
Outbox load_outbox(const ShareEnv& env);
Result<void> save_outbox(const ShareEnv& env, const Outbox& outbox);

// The kind of entry the client may share: open, with a `share`, not refused, and not sent yet or hit again since it was
// sent (fewer sends than min(occurrences, kMaxSharedOccurrences)).
bool entry_is_shareable(const Json& entry);

// -------------------------------------------------------------------------------------------------------- queue and send

struct ShareEntryReport {
    std::string id;           // FB-0003
    std::string status;       // queued | waiting | sent | rejected | skipped | none
    std::string reason;       // why not (rejected, skipped)
    Json removed = Json::array();
    Json entry;               // the sanitized entry (when it passes)
};

struct QueueResult {
    std::vector<ShareEntryReport> entries;
    int queued = 0, waiting = 0, rejected = 0, skipped = 0;
};

// Sanitizes the shareable entries of the feedback file `feedbackFile` (`ids`: only those; empty = all) and, by the mode,
// queues them (always), puts them to wait for confirmation (ask) or marks them skipped (unset, never). Writes `shared` in
// the file. An entry already in the outbox is replaced by its new sanitized form and keeps its state: queueing never answers
// yes for an item that waits (a waiting item, also from an older version, is released only by the user: share_confirm).
Result<QueueResult> share_queue(const ShareEnv& env, const std::string& feedbackFile, const std::string& projectDir,
                                const EngineNames& engine, const std::vector<std::string>& ids = {});

struct FlushOptions {
    std::vector<std::string> ids;  // only these local ids (of `file` when set); empty = everything allowed
    std::string file;              // restrict to one feedback file; empty = all
    bool force = false;            // ignore the backoff times ("share now")
    double timeoutSec = 5.0;       // of the request
    bool oneBatch = true;          // at most one request (the automatic flush); false = until nothing is due
};
struct FlushResult {
    int sent = 0, merged = 0, rejected = 0, retryLater = 0, waiting = 0;
    int notAllowed = 0;  // due items left in the outbox because their project's mode is never (or not set up)
    int requests = 0;
    std::string outcome;  // idle | sent | failed | rate_limited | banned | unavailable | off
    std::string message;
    Json results = Json::array();  // [{id, status, shareId?, reason?}]
};
// Sends the due items the mode of their project allows (always: queued ones; ask: only the ones a person confirmed, confirmedBy
// "user"; never or not set up: none, and they stay in the outbox). Before each request the modes are read again under the lock,
// and an item queued by `always` whose project is no longer on always goes back to waiting instead of being sent. The request
// runs outside the lock; its results are applied to the outbox as it is by then (read again under the lock), so a mode changed
// meanwhile is never undone. A batch already on its way finishes; the next one follows the new mode. Never throws.
FlushResult share_flush(const ShareEnv& env, const FlushOptions& options = {});
// True when share_flush would send something now.
bool share_has_due(const ShareEnv& env, const std::string& file = {});

// ask mode (the editor's confirmation, the CLI's `feedback share`): the entries waiting for the user's answer (of `file`
// when given; empty = of every project).
std::vector<OutboxItem> share_waiting(const ShareEnv& env, const std::string& file = {});
// The user said yes to these keys (empty = all waiting): they become Queued (confirmedBy "user"). Returns how many. An item whose project is
// `never` is not confirmed. Callers that mean one project pass its keys (share_waiting(env, file)). An error (the lock is busy, the
// outbox cannot be written) changes nothing: the items stay as they were, waiting.
Result<int> share_confirm(const ShareEnv& env, const std::vector<std::string>& keys = {});
// The user said no: they leave the outbox and their entries are marked skipped. Returns how many. An error (the lock is busy, the
// outbox cannot be written) changes nothing: the items stay in the outbox and no entry is marked.
Result<int> share_drop(const ShareEnv& env, const std::vector<std::string>& keys = {});

// The user left these entries of `feedbackFile` out of a batch (the editor's Send feedback window): they leave the outbox and
// their `shared` says skipped with `reason` (an id that is not in the file is ignored). They are offered again, unchecked, the
// next time. Not for turning sharing off: that is set_share_mode. An error (the lock is busy, the outbox cannot be written) changes
// nothing: the entries stay in the outbox and none says skipped.
Result<void> share_skip(const ShareEnv& env, const std::string& feedbackFile, const std::vector<std::string>& ids,
                        const std::string& reason = "left out when sending feedback");

// The preview: {mode, entries: [{id, ok, sent?, reason?, removed}], note}. Nothing is queued, sent or written.
Json share_preview(const ShareEnv& env, const std::string& feedbackFile, const std::string& projectDir, const EngineNames& engine,
                   const std::vector<std::string>& ids = {});
// {mode (the effective one for `projectDir`), default, project?{dir, name (both UTF-8), mode (own, "default" = follows), source}, available,
// endpoint, signedIn, login?, warning?, howToFix?, howToTurnOn?, outbox{queued, waitingForConfirmation, blocked,
// failed[]}, lastSend?}. `blocked`: items whose project's mode is never or not set up (they are not sent). Without
// `projectDir`, `mode` is the default.
Json share_status(const ShareEnv& env, const std::string& projectDir = {});

// What `feedback.report` tells the reporter about the share of the entry it just recorded (see register in feedback.cpp).
Json share_report_summary(const ShareEnv& env, const std::string& feedbackFile, const std::string& projectDir,
                          const std::string& entryId, const CommandRegistry* registry, bool shareGiven);

// The entries of `feedbackFile` named by `ids` leave the outbox (the entry is being deleted): nothing is written to the file. An
// error (the lock is busy, the outbox cannot be written) leaves the outbox as it was: the caller must then NOT delete the entry,
// or it would stay sendable without being in the file (delete_feedback_file takes this as its `beforeWrite`).
Result<void> share_discard(const ShareEnv& env, const std::string& feedbackFile, const std::vector<std::string>& ids);

struct VerdictResult {
    int checked = 0;                  // shareIds asked about
    int declined = 0;                 // entries the engine developer rejected since the last time: now rejected here
    int restored = 0;                 // entries whose rejection was taken back: sent (and open) again
    std::vector<std::string> changed; // their ids
    std::string outcome;              // ok | idle | off | unavailable | unsupported | failed
    std::string message;
};
// Asks the server (POST /v1/verdicts, authenticated by the installation header) what the engine developers decided about the
// entries of `feedbackFile` (and its archive) that were sent, by their shareIds; only this installation's reports are answered.
// A rejection becomes `shared.status` "declined" and the entry's status rejected (statusBy developer, statusReason = the
// developer's reason); a rejection taken back puts the entry back to sent and open. A server without verdicts (404) changes
// nothing. Never throws; the editor calls it on its sharing tick, and `factoria feedback share --verdicts`.
VerdictResult share_sync_verdicts(const ShareEnv& env, const std::string& feedbackFile, double timeoutSec = 10.0);

// Writes `shared` ({status, date, shareId?, reason?}) into entry `localId` of the feedback file (or its archive).
// A null `shared` removes it.
void write_entry_shared(const std::string& feedbackFile, const std::string& localId, const Json& shared);

// ------------------------------------------------------------------------------------------------------------ GitHub sign-in

struct DeviceCode {
    std::string deviceCode, userCode, verificationUri;
    int expiresIn = 900;
    int interval = 5;
};
Result<DeviceCode> github_device_start(const ShareEnv& env);
// Polls until the user authorizes (the GitHub access token), is refused or the code expires. `progress` is told what
// happens ("waiting..."); `cancelled` (optional) is asked between polls.
Result<std::string> github_device_poll(const ShareEnv& env, const DeviceCode& code,
                                       const std::function<bool()>& cancelled = {});
struct ShareSignIn {
    std::string credential, login;
};
// POST <endpoint>/v1/auth/github {githubToken}: the server answers the credential; the token is discarded by the caller.
Result<ShareSignIn> exchange_github_token(const ShareEnv& env, const std::string& githubToken);
// Start + `show(code)` + poll + exchange + store credential and login. `show` tells the user the code and the address.
Result<ShareSignIn> github_sign_in(const ShareEnv& env, const std::function<void(const DeviceCode&)>& show,
                                   const std::function<bool()>& cancelled = {});
Result<void> share_sign_out(const ShareEnv& env);

// ------------------------------------------------------------------------------------------------------------------ commands

// feedback.share_preview, feedback.share_status, feedback.share (called by register_feedback_commands).
void register_feedback_share_commands(CommandRegistry& registry, const std::string& projectDir);

}  // namespace fa
