// Sharing engine feedback with the engine developer (design: docs/design/FEEDBACK_SHARING.md, user docs: docs/ENGINE_FEEDBACK.md,
// "Sharing with the engine developer").
//
// A feedback entry may carry `share`: a generic copy of the gap written in engine terms only. This header turns that copy
// into something that may leave the machine, and sends it:
//
//   sanitize_share     the deterministic sanitizer: paths, file names, URLs, e-mail addresses, quoted text, the project's
//                      own names, control characters and runs of one character come out; a field under its minimum after
//                      cleaning stops the entry. The preview shows its result.
//   ShareSettings      <user config>/feedback-sharing.json: mode (unset | always | ask | never), installation id, GitHub
//                      credential, endpoint override. Only a person changes the mode (CLI, editor): no command does.
//   Outbox             <user config>/feedback-outbox.json: sanitized entries waiting to go, retried with backoff.
//   share_flush        one POST /v1/reports of up to 20 entries; every answer of the server is handled.
//   github_sign_in     optional identity: the GitHub device flow, then the server swaps the GitHub token for a credential.
//
// Nothing in here is simulation: it reads the clock, the environment and the network, through ShareEnv so tests replace all
// three and never touch the network or the real user folder.
#pragma once

#include <cstdint>
#include <functional>
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

// Field limits, the same on the server (docs/design/FEEDBACK_SHARING.md, "Field limits").
inline constexpr int kShareTitleMin = 8, kShareTitleMax = 120;
inline constexpr int kShareMissingMin = 20, kShareMissingMax = 1500;
inline constexpr int kShareSuggestionMax = 1500, kShareWorkaroundMax = 1500;
inline constexpr int kShareMaxEntriesPerRequest = 20;
inline constexpr int kShareMaxBodyBytes = 64 * 1024;
// The most times one entry is sent: the developer's ranking counts min(occurrences, 3) per installation.
inline constexpr int kMaxSharedOccurrences = 3;

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
    ShareMode mode = ShareMode::Unset;
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
// Only a person calls these two (the CLI, the editor's Settings): there is no command for them.
// Setting `never` also empties the outbox and marks its entries skipped.
Result<void> set_share_mode(const ShareEnv& env, ShareMode mode);
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
// localId, category, severity, effort, reporterKind and reviewed from the local entry.
Json build_share_entry(const Json& localEntry, const SanitizedShare& share);
// {format, engineVersion, platform, entries}.
Json build_share_payload(const ShareEnv& env, const std::vector<Json>& entries);

// ------------------------------------------------------------------------------------------------------------------- outbox

enum class OutboxState { Queued, Waiting };  // Waiting: mode `ask`, the user has not confirmed it yet

struct OutboxItem {
    std::string key;      // file + "#" + localId: an entry is in the outbox once
    std::string file;     // the project's ENGINE_FEEDBACK.json (kept locally to write `shared` back; never sent)
    std::string localId;  // FB-0003
    OutboxState state = OutboxState::Queued;
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
// the file. An entry already in the outbox is replaced by its new sanitized form.
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
    int sent = 0, merged = 0, rejected = 0, retryLater = 0, waiting = 0, notAllowed = 0;
    int requests = 0;
    std::string outcome;  // idle | sent | failed | rate_limited | banned | unavailable | off
    std::string message;
    Json results = Json::array();  // [{id, status, shareId?, reason?}]
};
// Sends the due items the mode allows (always: queued ones; ask: only confirmed ones, i.e. state Queued). Never throws.
FlushResult share_flush(const ShareEnv& env, const FlushOptions& options = {});
// True when share_flush would send something now.
bool share_has_due(const ShareEnv& env, const std::string& file = {});

// ask mode (the editor's confirmation, the CLI's `feedback share`): the entries waiting for the user's answer.
std::vector<OutboxItem> share_waiting(const ShareEnv& env, const std::string& file = {});
// The user said yes to these keys (empty = all waiting): they become Queued. Returns how many.
int share_confirm(const ShareEnv& env, const std::vector<std::string>& keys = {});
// The user said no: they leave the outbox and their entries are marked skipped. Returns how many.
int share_drop(const ShareEnv& env, const std::vector<std::string>& keys = {});

// The preview: {mode, entries: [{id, ok, sent?, reason?, removed}], note}. Nothing is queued, sent or written.
Json share_preview(const ShareEnv& env, const std::string& feedbackFile, const std::string& projectDir, const EngineNames& engine,
                   const std::vector<std::string>& ids = {});
// {mode, available, endpoint, signedIn, login?, warning?, howToFix?, howToTurnOn?, outbox{queued, waitingForConfirmation,
// failed[]}, lastSend?}.
Json share_status(const ShareEnv& env);

// What `feedback.report` tells the reporter about the share of the entry it just recorded (see register in feedback.cpp).
Json share_report_summary(const ShareEnv& env, const std::string& feedbackFile, const std::string& projectDir,
                          const std::string& entryId, const CommandRegistry* registry, bool shareGiven);

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
