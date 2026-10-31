// Feedback sharing, client side: environment, user settings, outbox, queue and send, and the commands
// (fa/tooling/feedback_share.h; contract: docs/design/FEEDBACK_SHARING.md).
#include "fa/tooling/feedback_share.h"

#include <algorithm>
#include <chrono>
#include <cstdio>
#include <filesystem>
#include <future>
#include <memory>
#include <random>
#include <thread>

#include "fa/core/strings.h"
#include "fa/runtime/project.h"
#include "fa/tooling/feedback.h"
#include "fa/tooling/feedback_fixed.h"
#include "util.h"

#ifndef FA_FEEDBACK_URL
#define FA_FEEDBACK_URL ""
#endif
#ifndef FA_FEEDBACK_GITHUB_CLIENT_ID
#define FA_FEEDBACK_GITHUB_CLIENT_ID ""
#endif
#ifndef FA_ENGINE_VERSION
#define FA_ENGINE_VERSION "0.0.0"
#endif

namespace fa {

namespace stdfs = std::filesystem;
using tooling_detail::arg_string;

namespace {
bool contains(const std::vector<std::string>& v, const std::string& s) { return std::find(v.begin(), v.end(), s) != v.end(); }
}  // namespace

std::string compiled_share_endpoint() { return FA_FEEDBACK_URL; }
std::string compiled_github_client_id() { return FA_FEEDBACK_GITHUB_CLIENT_ID; }

// ------------------------------------------------------------------------------------------------------------- environment

namespace {

std::int64_t system_now() {
    return std::chrono::duration_cast<std::chrono::seconds>(std::chrono::system_clock::now().time_since_epoch()).count();
}

// YYYY-MM-DD (UTC) of a time in seconds since 1970.
std::string date_utc(std::int64_t t) {
    std::int64_t days = t / 86400;
    if (t % 86400 < 0) --days;
    days += 719468;
    const std::int64_t era = (days >= 0 ? days : days - 146096) / 146097;
    const std::int64_t doe = days - era * 146097;
    const std::int64_t yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    const std::int64_t y = yoe + era * 400;
    const std::int64_t doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    const std::int64_t mp = (5 * doy + 2) / 153;
    const std::int64_t d = doy - (153 * mp + 2) / 5 + 1;
    const std::int64_t m = mp < 10 ? mp + 3 : mp - 9;
    char buf[16];
    std::snprintf(buf, sizeof buf, "%04lld-%02lld-%02lld", static_cast<long long>(y + (m <= 2)), static_cast<long long>(m),
                  static_cast<long long>(d));
    return buf;
}

ShareEnv g_env;

std::string header_of(const HttpResponse& r, const char* lowerName) {
    for (const auto& [k, v] : r.headers)
        if (k == lowerName) return v;
    return {};
}

}  // namespace

std::int64_t ShareEnv::clock() const { return now ? now() : system_now(); }

std::string ShareEnv::config_dir() const { return user_config_dir(env ? env : system_user_config_env()); }

std::string ShareEnv::os_platform() const {
    if (!platform.empty()) return platform;
#if defined(__APPLE__)
    return "macos";
#elif defined(_WIN32)
    return "windows";
#elif defined(__linux__)
    return "linux";
#else
    return "other";
#endif
}

std::string ShareEnv::version() const { return engineVersion.empty() ? std::string(FA_ENGINE_VERSION) : engineVersion; }

HttpResponse ShareEnv::send(const HttpRequest& request) const {
    if (transport) return transport(request);
    // The platform client is created once and kept for the life of the process: a request may still be finishing in it.
    static HttpClient* client = make_system_http_client().release();
    HttpResponse failure;
    if (!client->available()) {
        failure.error = "this machine cannot send HTTP requests: " + client->unavailable_reason();
        failure.hint = "Install libcurl (Linux) or check the network stack of the system.";
        return failure;
    }
    auto promise = std::make_shared<std::promise<HttpResponse>>();
    std::future<HttpResponse> answer = promise->get_future();
    client->send(request, [promise](HttpResponse r) { promise->set_value(std::move(r)); });
    if (answer.wait_for(std::chrono::duration<double>(request.timeoutSec + 5.0)) != std::future_status::ready) {
        failure.error = "the request to " + request.url + " did not finish in time";
        failure.hint = "Check the network connection; the entries stay in the outbox and are sent later.";
        failure.timedOut = true;
        return failure;
    }
    return answer.get();
}

ShareEnv& share_env() { return g_env; }

ScopedShareEnv::ScopedShareEnv(ShareEnv replacement) : saved_(g_env) { g_env = std::move(replacement); }
ScopedShareEnv::~ScopedShareEnv() { g_env = std::move(saved_); }

// ----------------------------------------------------------------------------------------------------------------- settings

const char* share_mode_name(ShareMode mode) {
    switch (mode) {
        case ShareMode::Always: return "always";
        case ShareMode::Ask: return "ask";
        case ShareMode::Never: return "never";
        case ShareMode::Unset: break;
    }
    return "unset";
}

std::optional<ShareMode> parse_share_mode(std::string_view name) {
    const std::string n = to_lower(trim(name));
    if (n == "unset") return ShareMode::Unset;
    if (n == "always") return ShareMode::Always;
    if (n == "ask") return ShareMode::Ask;
    if (n == "never") return ShareMode::Never;
    return std::nullopt;
}

std::string random_uuid_v4() {
    std::random_device rd;  // the operating system's source (getrandom, arc4random, BCryptGenRandom)
    unsigned char b[16];
    for (int i = 0; i < 16; i += 4) {
        const std::uint32_t v = rd();
        for (int k = 0; k < 4; ++k) b[i + k] = static_cast<unsigned char>(v >> (8 * k));
    }
    b[6] = static_cast<unsigned char>((b[6] & 0x0F) | 0x40);
    b[8] = static_cast<unsigned char>((b[8] & 0x3F) | 0x80);
    char buf[40];
    std::snprintf(buf, sizeof buf, "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x", b[0], b[1], b[2], b[3],
                  b[4], b[5], b[6], b[7], b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15]);
    return buf;
}

bool is_uuid_v4(std::string_view t) {
    if (t.size() != 36) return false;
    for (std::size_t i = 0; i < t.size(); ++i) {
        const char c = t[i];
        if (i == 8 || i == 13 || i == 18 || i == 23) {
            if (c != '-') return false;
        } else if (!std::isxdigit(static_cast<unsigned char>(c))) {
            return false;
        }
    }
    if (t[14] != '4') return false;
    const char v = static_cast<char>(std::tolower(static_cast<unsigned char>(t[19])));
    return v == '8' || v == '9' || v == 'a' || v == 'b';
}

std::string share_settings_path(const ShareEnv& env) { return (stdfs::path(env.config_dir()) / kFeedbackSharingFile).string(); }

ShareSettings load_share_settings(const ShareEnv& env) {
    ShareSettings s;
    s.path = share_settings_path(env);
    auto text = tooling_detail::read_file(s.path);
    if (!text) return s;
    auto parsed = parse_json(*text, s.path);
    if (!parsed.ok() || !parsed.value().is_object()) {
        s.warning = s.path + " is not a JSON object, so sharing reads as not set up: fix or delete the file. " +
                    (parsed.ok() ? std::string() : parsed.error().message);
        return s;
    }
    s.raw = parsed.value();
    const std::string mode = tooling_detail::string_setting(s.raw, "mode", "unset");
    if (auto m = parse_share_mode(mode)) s.mode = *m;
    else s.warning = s.path + ": unknown mode '" + mode + "' (use always, ask or never): sharing reads as not set up.";
    if (const std::string id = tooling_detail::string_setting(s.raw, "installId", ""); is_uuid_v4(id)) s.installId = id;
    s.credential = tooling_detail::string_setting(s.raw, "credential", "");
    s.login = tooling_detail::string_setting(s.raw, "login", "");
    s.endpoint = tooling_detail::string_setting(s.raw, "endpoint", "");
    return s;
}

Result<void> save_share_settings(const ShareEnv& env, const ShareSettings& settings) {
    Json doc = settings.raw.is_object() ? settings.raw : Json::object();
    auto put = [&](const char* key, const std::string& value) {
        if (value.empty()) doc.erase(key);
        else doc[key] = value;
    };
    doc["mode"] = share_mode_name(settings.mode);
    put("installId", settings.installId);
    put("credential", settings.credential);
    put("login", settings.login);
    put("endpoint", settings.endpoint);
    const std::string path = share_settings_path(env);
    std::string err;
    if (!tooling_detail::write_file(path, dump_json(doc), &err))
        return make_error("Cannot write " + path + ": " + err, "Check the permissions of the folder.");
    std::error_code ec;  // the credential is a secret: owner only (no-op on Windows)
    stdfs::permissions(path, stdfs::perms::owner_read | stdfs::perms::owner_write, stdfs::perm_options::replace, ec);
    return {};
}

Result<std::string> ensure_install_id(const ShareEnv& env) {
    ShareSettings s = load_share_settings(env);
    if (!s.installId.empty()) return s.installId;
    s.installId = env.makeUuid ? env.makeUuid() : random_uuid_v4();
    if (auto r = save_share_settings(env, s); !r.ok()) return r.error();
    return s.installId;
}

std::string share_endpoint(const ShareEnv& env, const ShareSettings& settings) {
    std::string e(trim(settings.endpoint.empty() ? env.defaultEndpoint : settings.endpoint));
    while (!e.empty() && e.back() == '/') e.pop_back();
    return e;
}

std::string share_unavailable_message() {
    return "Sharing is not available in this build: it has no feedback server. Build the engine with "
           "-DFA_FEEDBACK_URL=<server url>, or set \"endpoint\" in " + std::string(kFeedbackSharingFile) +
           " in the user config folder (next to ai.json) to the URL of a server (tools/feedback-server).";
}

// -------------------------------------------------------------------------------------------------------------------- outbox

std::int64_t backoff_seconds(int attempts) {
    if (attempts <= 1) return 60;
    if (attempts == 2) return 600;
    if (attempts == 3) return 3600;
    return 86400;
}

namespace {

std::string outbox_path(const ShareEnv& env) { return (stdfs::path(env.config_dir()) / kFeedbackOutboxFile).string(); }

std::string item_key(const std::string& file, const std::string& id) { return file + "#" + id; }

}  // namespace

Outbox load_outbox(const ShareEnv& env) {
    Outbox box;
    box.path = outbox_path(env);
    auto text = tooling_detail::read_file(box.path);
    if (!text) return box;
    auto parsed = parse_json(*text, box.path);
    if (!parsed.ok() || !parsed.value().is_object()) return box;  // an unreadable outbox starts empty; it is rewritten on save
    const Json& doc = parsed.value();
    if (doc.contains("lastSend") && doc["lastSend"].is_object()) box.lastSend = doc["lastSend"];
    if (!doc.contains("items") || !doc["items"].is_array()) return box;
    for (const Json& j : doc["items"]) {
        if (!j.is_object() || !j.contains("entry") || !j["entry"].is_object()) continue;
        OutboxItem it;
        it.file = j.value("file", std::string());
        it.localId = j.value("localId", std::string());
        if (it.localId.empty()) continue;
        it.key = item_key(it.file, it.localId);
        it.state = j.value("state", std::string("queued")) == "waiting" ? OutboxState::Waiting : OutboxState::Queued;
        it.entry = j["entry"];
        it.attempts = j.value("attempts", 0);
        it.queuedAt = j.value("queuedAt", std::int64_t(0));
        it.nextAttempt = j.value("nextAttempt", std::int64_t(0));
        it.lastError = j.value("lastError", std::string());
        box.items.push_back(std::move(it));
    }
    return box;
}

Result<void> save_outbox(const ShareEnv& env, const Outbox& outbox) {
    Json items = Json::array();
    for (const OutboxItem& it : outbox.items) {
        Json j = Json::object();
        j["localId"] = it.localId;
        j["file"] = it.file;
        j["state"] = it.state == OutboxState::Waiting ? "waiting" : "queued";
        j["entry"] = it.entry;
        j["attempts"] = it.attempts;
        j["queuedAt"] = it.queuedAt;
        j["nextAttempt"] = it.nextAttempt;
        if (!it.lastError.empty()) j["lastError"] = it.lastError;
        items.push_back(std::move(j));
    }
    Json doc = Json::object();
    doc["format"] = kFeedbackOutboxFormat;
    doc["items"] = std::move(items);
    if (outbox.lastSend.is_object()) doc["lastSend"] = outbox.lastSend;
    const std::string path = outbox_path(env);
    std::string err;
    if (!tooling_detail::write_file(path, dump_json(doc), &err))
        return make_error("Cannot write " + path + ": " + err, "Check the permissions of the folder.");
    return {};
}

bool entry_is_shareable(const Json& e) {
    if (!e.is_object() || e.value("status", std::string("open")) != "open") return false;
    if (!e.contains("share") || !e["share"].is_object()) return false;
    if (e.contains("shared") && e["shared"].is_object()) {
        const std::string st = e["shared"].value("status", std::string());
        if (st == "sent" || st == "rejected") return false;
    }
    return true;
}

namespace {

OutboxItem* find_item(Outbox& box, const std::string& key) {
    for (OutboxItem& it : box.items)
        if (it.key == key) return &it;
    return nullptr;
}

}  // namespace

// --------------------------------------------------------------------------------------------------------------------- payload

Json build_share_entry(const Json& local, const SanitizedShare& share) {
    Json e = Json::object();
    e["localId"] = local.value("id", std::string());
    e["category"] = local.value("category", std::string("other"));
    e["severity"] = local.value("severity", std::string("minor"));
    if (const std::string effort = local.value("effort", std::string()); !effort.empty()) e["effort"] = effort;
    e["title"] = share.title;
    e["missing"] = share.missing;
    if (!share.suggestion.empty()) e["suggestion"] = share.suggestion;
    if (!share.workaround.empty()) e["workaround"] = share.workaround;
    std::string kind = "ai";
    if (local.contains("reporter") && local["reporter"].is_object()) kind = local["reporter"].value("kind", std::string("ai"));
    e["reporterKind"] = kind == "human" ? "human" : "ai";
    e["reviewed"] = local.contains("reviewed") && local["reviewed"].is_boolean() && local["reviewed"].get<bool>();
    return e;
}

Json build_share_payload(const ShareEnv& env, const std::vector<Json>& entries) {
    Json doc = Json::object();
    doc["format"] = kFeedbackShareFormat;
    doc["engineVersion"] = env.version();
    doc["platform"] = env.os_platform();
    Json arr = Json::array();
    for (const Json& e : entries) arr.push_back(e);
    doc["entries"] = std::move(arr);
    return doc;
}

// ------------------------------------------------------------------------------------------------- shared in the local file

namespace {

Json shared_state(const ShareEnv& env, const std::string& status, const std::string& reason = {}, const std::string& shareId = {}) {
    Json s = Json::object();
    s["status"] = status;
    s["date"] = date_utc(env.clock());
    if (!shareId.empty()) s["shareId"] = shareId;
    if (!reason.empty()) s["reason"] = reason;
    return s;
}

// Sets or removes `shared` on entry `id` of a feedback document. True when something changed.
bool set_shared(Json& doc, const std::string& id, const Json& shared) {
    if (!doc.is_object() || !doc.contains("entries") || !doc["entries"].is_array()) return false;
    for (Json& e : doc["entries"]) {
        if (!e.is_object() || e.value("id", std::string()) != id) continue;
        if (shared.is_null()) {
            if (!e.contains("shared")) return false;
            e.erase("shared");
            return true;
        }
        if (e.contains("shared") && e["shared"] == shared) return false;
        e["shared"] = shared;
        return true;
    }
    return false;
}

}  // namespace

void write_entry_shared(const std::string& feedbackFile, const std::string& localId, const Json& shared) {
    for (const std::string& path : {feedbackFile, feedback_archive_path(feedbackFile)}) {
        if (!stdfs::exists(path)) continue;
        auto doc = load_feedback(path);
        if (!doc.ok()) continue;
        if (set_shared(doc.value(), localId, shared)) {
            (void)save_feedback(path, doc.value());
            return;
        }
    }
}

// ------------------------------------------------------------------------------------------------------------ queue and send

namespace {

ShareEntryReport report_for(const std::string& id, const std::string& status, const std::string& reason = {}) {
    ShareEntryReport r;
    r.id = id;
    r.status = status;
    r.reason = reason;
    return r;
}

std::string mode_off_reason(ShareMode mode) {
    return mode == ShareMode::Never ? "sharing is off (mode never)" : "sharing is not set up (the user chooses the mode)";
}

}  // namespace

Result<QueueResult> share_queue(const ShareEnv& env, const std::string& feedbackFile, const std::string& projectDir,
                                const EngineNames& engine, const std::vector<std::string>& ids) {
    auto loaded = load_feedback(feedbackFile);
    if (!loaded.ok()) return loaded.error();
    Json doc = std::move(loaded.value());
    const ShareSettings settings = load_share_settings(env);
    const ProjectNames project = collect_project_names(projectDir);
    Outbox box = load_outbox(env);
    QueueResult result;
    bool docChanged = false, boxChanged = false;
    const std::int64_t now = env.clock();
    if (!doc.contains("entries") || !doc["entries"].is_array()) return result;
    for (Json& e : doc["entries"]) {
        if (!e.is_object()) continue;
        const std::string id = e.value("id", std::string());
        const bool wanted = ids.empty() || contains(ids, id);
        if (!wanted) continue;
        if (!entry_is_shareable(e)) {
            if (!ids.empty()) {
                std::string why = e.contains("share") ? "already sent or refused" : "it has no `share` (the generic copy in engine terms)";
                if (e.value("status", std::string("open")) != "open") why = "it is not open";
                result.entries.push_back(report_for(id, "none", why));
            }
            continue;
        }
        if (settings.mode == ShareMode::Unset || settings.mode == ShareMode::Never) {
            ShareEntryReport r = report_for(id, "skipped", mode_off_reason(settings.mode));
            if (settings.mode == ShareMode::Never) {
                const Json s = shared_state(env, "skipped", "sharing is off");
                if (!(e.contains("shared") && e["shared"].value("status", std::string()) == "skipped")) {
                    e["shared"] = s;
                    docChanged = true;
                }
            }
            ++result.skipped;
            result.entries.push_back(std::move(r));
            continue;
        }
        const SanitizedShare clean = sanitize_share(e["share"], engine, project);
        ShareEntryReport r;
        r.id = id;
        r.removed = clean.removed_json();
        if (!clean.ok) {
            r.status = "rejected";
            r.reason = clean.reason();
            e["shared"] = shared_state(env, "rejected", r.reason);
            docChanged = true;
            if (OutboxItem* old = find_item(box, item_key(feedbackFile, id))) {
                box.items.erase(box.items.begin() + (old - box.items.data()));
                boxChanged = true;
            }
            ++result.rejected;
            result.entries.push_back(std::move(r));
            continue;
        }
        r.entry = build_share_entry(e, clean);
        const std::string key = item_key(feedbackFile, id);
        OutboxItem* item = find_item(box, key);
        if (!item) {
            // The server is failing right now (an item is backing off): a new entry waits for the same time instead of
            // making every report try the network again.
            std::int64_t holdUntil = 0;
            for (const OutboxItem& other : box.items)
                if (other.attempts > 0 && other.nextAttempt > now) holdUntil = std::max(holdUntil, other.nextAttempt);
            box.items.emplace_back();
            item = &box.items.back();
            item->nextAttempt = holdUntil;
            item->key = key;
            item->file = feedbackFile;
            item->localId = id;
            item->queuedAt = now;
            item->state = settings.mode == ShareMode::Ask ? OutboxState::Waiting : OutboxState::Queued;
        } else if (settings.mode == ShareMode::Always) {
            item->state = OutboxState::Queued;
        }
        item->entry = r.entry;
        boxChanged = true;
        r.status = item->state == OutboxState::Waiting ? "waiting" : "queued";
        if (item->state == OutboxState::Waiting) ++result.waiting;
        else ++result.queued;
        const Json s = shared_state(env, "pending");
        if (!(e.contains("shared") && e["shared"].value("status", std::string()) == "pending")) {
            e["shared"] = s;
            docChanged = true;
        }
        result.entries.push_back(std::move(r));
    }
    if (boxChanged)
        if (auto s = save_outbox(env, box); !s.ok()) return s.error();
    if (docChanged)
        if (auto s = save_feedback(feedbackFile, doc); !s.ok()) return s.error();
    return result;
}

Json share_preview(const ShareEnv& env, const std::string& feedbackFile, const std::string& projectDir, const EngineNames& engine,
                   const std::vector<std::string>& ids) {
    Json out = Json::object();
    const ShareSettings settings = load_share_settings(env);
    out["mode"] = share_mode_name(settings.mode);
    Json entries = Json::array();
    auto loaded = load_feedback(feedbackFile);
    if (loaded.ok() && loaded.value().contains("entries") && loaded.value()["entries"].is_array()) {
        const ProjectNames project = collect_project_names(projectDir);
        for (const Json& e : loaded.value()["entries"]) {
            const std::string id = e.value("id", std::string());
            if (!ids.empty() && !contains(ids, id)) continue;
            if (!entry_is_shareable(e)) {
                if (!ids.empty()) {
                    Json j = Json::object({{"id", id}, {"ok", false}});
                    j["reason"] = e.contains("share") ? "already sent or refused, or not open" : "it has no `share` (the generic copy in engine terms)";
                    entries.push_back(std::move(j));
                }
                continue;
            }
            const SanitizedShare clean = sanitize_share(e["share"], engine, project);
            Json j = Json::object({{"id", id}, {"ok", clean.ok}});
            if (clean.ok) j["sent"] = build_share_entry(e, clean);
            else j["reason"] = clean.reason();
            j["removed"] = clean.removed_json();
            entries.push_back(std::move(j));
        }
    }
    out["entries"] = std::move(entries);
    out["note"] = "Exactly what would be sent (`sent`), with what the sanitizer removed. Nothing is sent by previewing.";
    return out;
}

namespace {

bool item_matches(const OutboxItem& it, const FlushOptions& o) {
    if (!o.file.empty() && it.file != o.file) return false;
    if (!o.ids.empty() && !contains(o.ids, it.localId)) return false;
    return true;
}

std::int64_t parse_retry_after(const std::string& v, std::int64_t fallback) {
    if (v.empty()) return fallback;
    try {
        const long n = std::stol(v);
        return n > 0 ? n : fallback;
    } catch (...) {
        return fallback;
    }
}

std::string server_message(const Json& body, const std::string& fallback) {
    if (body.is_object() && body.contains("error") && body["error"].is_object()) {
        std::string m = body["error"].value("message", std::string());
        const std::string h = body["error"].value("hint", std::string());
        if (!m.empty()) return h.empty() ? m : m + " (" + h + ")";
    }
    return fallback;
}

}  // namespace

bool share_has_due(const ShareEnv& env, const std::string& file) {
    const ShareSettings settings = load_share_settings(env);
    if (settings.mode != ShareMode::Always && settings.mode != ShareMode::Ask) return false;
    if (share_endpoint(env, settings).empty()) return false;
    const Outbox box = load_outbox(env);
    const std::int64_t now = env.clock();
    for (const OutboxItem& it : box.items)
        if (it.state == OutboxState::Queued && it.nextAttempt <= now && (file.empty() || it.file == file)) return true;
    return false;
}

FlushResult share_flush(const ShareEnv& env, const FlushOptions& options) {
    FlushResult res;
    const ShareSettings settings = load_share_settings(env);
    auto finish = [&](const std::string& outcome, const std::string& message) {
        res.outcome = outcome;
        res.message = message;
        return res;
    };
    if (settings.mode != ShareMode::Always && settings.mode != ShareMode::Ask)
        return finish("off", settings.mode == ShareMode::Never ? "Sharing is off (mode never): nothing is sent."
                                                               : "Sharing is not set up: nothing is sent. The user turns it on in the "
                                                                 "editor (Settings > Feedback) or with `factoria feedback sharing always|ask`.");
    const std::string endpoint = share_endpoint(env, settings);
    if (endpoint.empty()) return finish("unavailable", share_unavailable_message());

    Outbox box = load_outbox(env);
    const std::int64_t startedAt = env.clock();
    bool first = true;
    for (int round = 0; round < 50; ++round) {
        const std::int64_t now = env.clock();
        std::vector<std::size_t> batch;
        std::size_t bytes = 256;
        for (std::size_t i = 0; i < box.items.size() && batch.size() < std::size_t(kShareMaxEntriesPerRequest); ++i) {
            const OutboxItem& it = box.items[i];
            if (!item_matches(it, options)) continue;
            if (it.state == OutboxState::Waiting) continue;
            if (!options.force && it.nextAttempt > now) continue;
            const std::size_t size = it.entry.dump().size() + 2;
            if (bytes + size > std::size_t(kShareMaxBodyBytes)) {
                if (batch.empty()) {  // one entry alone over the limit can never be accepted
                    // fall through: it is sent alone and the server answers
                } else {
                    break;
                }
            }
            bytes += size;
            batch.push_back(i);
        }
        for (const OutboxItem& it : box.items)
            if (item_matches(it, options) && it.state == OutboxState::Waiting && first) ++res.waiting;
        first = false;
        if (batch.empty()) break;

        auto install = ensure_install_id(env);
        if (!install.ok()) return finish("failed", install.error().message);
        std::vector<Json> entries;
        for (std::size_t i : batch) entries.push_back(box.items[i].entry);
        HttpRequest req;
        req.method = "POST";
        req.url = endpoint + "/v1/reports";
        req.timeoutSec = options.timeoutSec;
        req.maxResponseBytes = 256 * 1024;
        req.headers = {{"Content-Type", "application/json"}, {"Accept", "application/json"}, {"X-Factoria-Install", install.value()}};
        if (!settings.credential.empty()) req.headers.push_back({"Authorization", "Bearer " + settings.credential});
        req.body = build_share_payload(env, entries).dump();
        const HttpResponse resp = env.send(req);
        ++res.requests;

        auto retry_all = [&](const std::string& why, std::int64_t notBefore) {
            for (std::size_t i : batch) {
                OutboxItem& it = box.items[i];
                ++it.attempts;
                it.lastError = why;
                it.nextAttempt = std::max(now + backoff_seconds(it.attempts), notBefore);
                res.results.push_back(Json::object({{"id", it.localId}, {"status", "retry_later"}, {"reason", why}}));
                ++res.retryLater;
            }
        };
        std::vector<std::size_t> remove;
        auto reject_all = [&](const std::string& why) {
            for (std::size_t i : batch) {
                OutboxItem& it = box.items[i];
                write_entry_shared(it.file, it.localId, shared_state(env, "rejected", why));
                res.results.push_back(Json::object({{"id", it.localId}, {"status", "rejected"}, {"reason", why}}));
                ++res.rejected;
                remove.push_back(i);
            }
        };
        std::string outcome = "sent";
        std::string message;
        Json body = resp.ok ? Json::parse(resp.body, nullptr, false) : Json();
        if (!resp.ok) {
            const std::string why = resp.error.empty() ? "the request failed" : resp.error;
            retry_all(why, 0);
            outcome = "failed";
            message = "Could not reach the feedback server (" + why + "). The entries stay in the outbox and are retried later.";
        } else if (resp.status == 429) {
            const std::int64_t wait = parse_retry_after(header_of(resp, "retry-after"), 3600);
            retry_all("the server asked to wait (rate limit)", now + wait);
            outcome = "rate_limited";
            message = "The server's daily limit was reached; the entries are retried after " + std::to_string(wait) + " seconds.";
        } else if (resp.status == 403) {
            reject_all("the server refuses reports from this installation");
            outcome = "banned";
            message = "The server refuses reports from this installation; nothing more is sent for these entries.";
        } else if (resp.status >= 500 || resp.status == 0) {
            const std::string why = "the server answered " + std::to_string(resp.status);
            retry_all(why, 0);
            outcome = "failed";
            message = "The feedback server is having trouble (" + why + "); retried later.";
        } else if (resp.status >= 400) {
            const std::string why = server_message(body, "the server answered " + std::to_string(resp.status));
            reject_all(why);
            outcome = "failed";
            message = "The server refused the request: " + why;
        } else if (!body.is_object() || !body.value("ok", false) || !body.contains("results") || !body["results"].is_array()) {
            retry_all("the server's answer could not be understood", 0);
            outcome = "failed";
            message = "The server's answer could not be understood; retried later.";
        } else {
            for (std::size_t i : batch) {
                OutboxItem& it = box.items[i];
                const Json* found = nullptr;
                for (const Json& r : body["results"])
                    if (r.is_object() && r.value("localId", std::string()) == it.localId) found = &r;
                if (!found) {
                    ++it.attempts;
                    it.lastError = "the server did not answer for this entry";
                    it.nextAttempt = now + backoff_seconds(it.attempts);
                    res.results.push_back(Json::object({{"id", it.localId}, {"status", "retry_later"}, {"reason", it.lastError}}));
                    ++res.retryLater;
                    continue;
                }
                const std::string status = found->value("status", std::string());
                if (status == "accepted" || status == "merged") {
                    const std::string shareId = found->value("shareId", std::string());
                    write_entry_shared(it.file, it.localId, shared_state(env, "sent", {}, shareId));
                    Json r = Json::object({{"id", it.localId}, {"status", status}});
                    if (!shareId.empty()) r["shareId"] = shareId;
                    res.results.push_back(std::move(r));
                    if (status == "merged") ++res.merged;
                    ++res.sent;
                } else {
                    const std::string code = found->value("code", std::string("rejected"));
                    std::string why = found->value("reason", std::string());
                    why = why.empty() ? code : code + ": " + why;
                    write_entry_shared(it.file, it.localId, shared_state(env, "rejected", why));
                    res.results.push_back(Json::object({{"id", it.localId}, {"status", "rejected"}, {"reason", why}}));
                    ++res.rejected;
                }
                remove.push_back(i);
            }
            message = std::to_string(res.sent) + " sent" + (res.merged ? " (" + std::to_string(res.merged) + " merged with an earlier report)" : "") +
                      (res.rejected ? ", " + std::to_string(res.rejected) + " refused by the server" : "") + ".";
        }
        // Drop the finished items (highest index first).
        std::sort(remove.begin(), remove.end(), std::greater<>());
        for (std::size_t i : remove) box.items.erase(box.items.begin() + std::ptrdiff_t(i));
        box.lastSend = Json::object({{"at", startedAt}, {"outcome", outcome}, {"message", message}});
        res.outcome = outcome;
        res.message = message;
        if (outcome != "sent" || options.oneBatch) break;
    }
    if (res.requests == 0) {
        res.outcome = "idle";
        res.message = res.waiting ? std::to_string(res.waiting) + " entries wait for the user's confirmation; nothing else is due."
                                  : "Nothing is due: the outbox is empty or waiting for its next retry.";
    }
    if (res.requests > 0)
        if (auto s = save_outbox(env, box); !s.ok()) res.message += " (the outbox could not be saved: " + s.error().message + ")";
    return res;
}

std::vector<OutboxItem> share_waiting(const ShareEnv& env, const std::string& file) {
    std::vector<OutboxItem> out;
    for (OutboxItem& it : load_outbox(env).items)
        if (it.state == OutboxState::Waiting && (file.empty() || it.file == file)) out.push_back(std::move(it));
    return out;
}

int share_confirm(const ShareEnv& env, const std::vector<std::string>& keys) {
    Outbox box = load_outbox(env);
    int n = 0;
    for (OutboxItem& it : box.items)
        if (it.state == OutboxState::Waiting && (keys.empty() || contains(keys, it.key))) {
            it.state = OutboxState::Queued;
            it.nextAttempt = 0;
            ++n;
        }
    if (n) (void)save_outbox(env, box);
    return n;
}

int share_drop(const ShareEnv& env, const std::vector<std::string>& keys) {
    Outbox box = load_outbox(env);
    int n = 0;
    for (std::size_t i = box.items.size(); i-- > 0;) {
        const OutboxItem& it = box.items[i];
        if (it.state != OutboxState::Waiting || !(keys.empty() || contains(keys, it.key))) continue;
        write_entry_shared(it.file, it.localId, shared_state(env, "skipped", "the user chose not to send it"));
        box.items.erase(box.items.begin() + std::ptrdiff_t(i));
        ++n;
    }
    if (n) (void)save_outbox(env, box);
    return n;
}

Result<void> set_share_mode(const ShareEnv& env, ShareMode mode) {
    ShareSettings s = load_share_settings(env);
    s.mode = mode;
    if (auto r = save_share_settings(env, s); !r.ok()) return r;
    Outbox box = load_outbox(env);
    bool changed = false;
    if (mode == ShareMode::Never) {
        for (const OutboxItem& it : box.items) write_entry_shared(it.file, it.localId, shared_state(env, "skipped", "sharing is off"));
        changed = !box.items.empty();
        box.items.clear();
    } else if (mode == ShareMode::Always) {
        for (OutboxItem& it : box.items)  // the user chose to send everything: what waited for a yes is a yes
            if (it.state == OutboxState::Waiting) {
                it.state = OutboxState::Queued;
                changed = true;
            }
    }
    if (changed) return save_outbox(env, box);
    return {};
}

// ------------------------------------------------------------------------------------------------------- report summary

namespace {

std::string how_to_turn_on() {
    return "Only the user can turn sharing on: in the editor (Settings > Feedback) or by typing `factoria feedback sharing "
           "always` (or `ask`, to confirm each batch) in a terminal. Do not try to change it.";
}

}  // namespace

Json share_report_summary(const ShareEnv& env, const std::string& feedbackFile, const std::string& projectDir,
                          const std::string& entryId, const CommandRegistry* registry, bool shareGiven) {
    Json out = Json::object();
    auto done = [&](const std::string& status, const std::string& message) {
        out["status"] = status;
        out["message"] = message;
        return out;
    };
    const ShareSettings settings = load_share_settings(env);
    const std::string endpoint = share_endpoint(env, settings);
    auto loaded = load_feedback(feedbackFile);
    const Json* entry = nullptr;
    if (loaded.ok() && loaded.value().contains("entries") && loaded.value()["entries"].is_array())
        for (const Json& e : loaded.value()["entries"])
            if (e.is_object() && e.value("id", std::string()) == entryId) entry = &e;
    if (!entry || !entry->contains("share")) {
        if (!shareGiven) return Json();
        return done("none", "No `share` was recorded, so nothing will be shared.");
    }
    if (endpoint.empty()) return done("unavailable", share_unavailable_message());
    if (settings.mode == ShareMode::Unset)
        return done("not_set_up", "Sharing with the engine developer is not set up, so nothing was sent. " + how_to_turn_on());
    if (settings.mode == ShareMode::Never) return done("off", "Sharing is off (the user chose never), so nothing was sent.");
    if (!entry_is_shareable(*entry)) {
        const std::string st = entry->contains("shared") ? (*entry)["shared"].value("status", std::string()) : std::string();
        return done(st.empty() ? "none" : st, st == "sent" ? "This entry was already sent." : "This entry is not shared.");
    }

    auto queued = share_queue(env, feedbackFile, projectDir, collect_engine_names(registry), {entryId});
    if (!queued.ok()) return done("failed", queued.error().message);
    if (queued->entries.empty()) return done("none", "Nothing to share.");
    const ShareEntryReport& r = queued->entries.front();
    out["removed"] = r.removed;
    if (r.status == "rejected")
        return done("rejected", "The `share` text was not accepted for sending: " + r.reason +
                                    ". The entry stays local. Rewrite `share` in engine terms only (no names, paths, quotes or file "
                                    "names from the game) and report again.");
    if (r.status == "waiting")
        return done("waiting", "Queued, waiting for the user's confirmation (mode ask): the user sees a preview in the editor or "
                               "with `factoria feedback share`.");
    FlushOptions fo;
    fo.file = feedbackFile;
    fo.timeoutSec = 3.0;
    fo.oneBatch = true;
    if (share_has_due(env, feedbackFile)) {
        const FlushResult f = share_flush(env, fo);
        for (const Json& jr : f.results)
            if (jr.value("id", std::string()) == entryId) {
                const std::string st = jr.value("status", std::string());
                if (st == "accepted" || st == "merged") return done("sent", "Shared with the engine developer. Thank you.");
                if (st == "rejected") return done("rejected", "The server refused it: " + jr.value("reason", std::string()));
            }
        return done("queued", "Queued; it could not be sent right now (" + f.message + ") and is retried later.");
    }
    return done("queued", "Queued; it is sent with the next report.");
}

// ---------------------------------------------------------------------------------------------------------------- commands

namespace {

std::string feedback_file_for(const std::string& projectDir) {
    std::string file = kFeedbackFileName;
    if (auto text = tooling_detail::read_file(stdfs::path(projectDir) / kProjectFileName)) {
        auto pj = parse_json(*text, kProjectFileName);
        if (pj.ok() && pj.value().is_object() && pj.value().contains("feedbackFile") && pj.value()["feedbackFile"].is_string())
            file = pj.value()["feedbackFile"].get<std::string>();
    }
    return (stdfs::path(projectDir) / file).string();
}

std::vector<std::string> ids_arg(const Json& args) {
    std::vector<std::string> ids;
    if (args.contains("ids") && args["ids"].is_array())
        for (const Json& v : args["ids"])
            if (v.is_string()) ids.push_back(v.get<std::string>());
    return ids;
}

Json ids_schema() {
    return Json::object({{"type", "object"},
                         {"properties", Json::object({{"ids", Json::object({{"type", "array"},
                                                                            {"items", Json::object({{"type", "string"}})},
                                                                            {"description", "Entry ids (FB-0003). Empty or missing = every shareable entry."}})}})}});
}

}  // namespace

Json share_status(const ShareEnv& env) {
    const ShareSettings settings = load_share_settings(env);
    const std::string endpoint = share_endpoint(env, settings);
    Json out = Json::object();
    out["mode"] = share_mode_name(settings.mode);
    out["available"] = !endpoint.empty();
    out["endpoint"] = endpoint;
    out["signedIn"] = !settings.credential.empty();
    if (!settings.login.empty()) out["login"] = settings.login;
    if (!settings.warning.empty()) out["warning"] = settings.warning;
    if (endpoint.empty()) out["howToFix"] = share_unavailable_message();
    if (settings.mode == ShareMode::Unset) out["howToTurnOn"] = how_to_turn_on();
    const Outbox box = load_outbox(env);
    const std::int64_t now = env.clock();
    int queued = 0, waiting = 0;
    Json failed = Json::array();
    for (const OutboxItem& it : box.items) {
        if (it.state == OutboxState::Waiting) {
            ++waiting;
            continue;
        }
        ++queued;
        if (it.attempts > 0) {
            Json f = Json::object({{"id", it.localId}, {"attempts", it.attempts}, {"error", it.lastError}});
            f["retryInSeconds"] = std::max<std::int64_t>(0, it.nextAttempt - now);
            failed.push_back(std::move(f));
        }
    }
    out["outbox"] = Json::object({{"queued", queued}, {"waitingForConfirmation", waiting}, {"failed", failed}});
    if (box.lastSend.is_object()) out["lastSend"] = box.lastSend;
    return out;
}

void register_feedback_share_commands(CommandRegistry& registry, const std::string& projectDir) {
    register_feedback_fixed_commands(registry, projectDir);
    {
        CommandInfo info;
        info.name = "feedback.share_preview";
        info.category = "feedback";
        info.readOnly = true;
        info.summary = "Show exactly what sharing would send for the entries that have a `share`, and what the sanitizer removed.";
        info.description =
            "Runs the deterministic sanitizer on the `share` of each shareable entry and returns the entry as the engine developer's "
            "server would receive it (`sent`), plus `removed`: every path, file name, URL, e-mail address, quoted text and project "
            "name that was cut out. An entry whose text drops under its minimum after cleaning is `ok: false` with the reason: "
            "rewrite `share` in engine terms only. Nothing is sent and nothing is written. Example: {\"ids\":[\"FB-0003\"]}";
        info.inputSchema = ids_schema();
        registry.add(info, [&registry, projectDir](const Json& args) {
            const std::string file = feedback_file_for(projectDir);
            if (!stdfs::exists(file)) return Json::object({{"mode", share_mode_name(load_share_settings(share_env()).mode)},
                                                           {"entries", Json::array()}, {"note", "No ENGINE_FEEDBACK.json yet."}});
            return share_preview(share_env(), file, projectDir, collect_engine_names(&registry), ids_arg(args));
        });
    }
    {
        CommandInfo info;
        info.name = "feedback.share_status";
        info.category = "feedback";
        info.readOnly = true;
        info.summary = "Sharing with the engine developer: the mode, the server, whether the user signed in, and the outbox.";
        info.description =
            "Reports the mode the USER chose (unset, always, ask or never; no command changes it), whether this build has a feedback "
            "server, whether the user signed in with GitHub, and the outbox: entries queued, waiting for the user's confirmation, "
            "and failed ones with their reason and when they are retried. Use it to tell the user why a report was not sent.";
        info.inputSchema = Json::object({{"type", "object"}, {"properties", Json::object()}});
        registry.add(info, [](const Json&) { return share_status(share_env()); });
    }
    {
        CommandInfo info;
        info.name = "feedback.share";
        info.category = "feedback";
        info.readOnly = false;
        info.summary = "Send the queued feedback to the engine developer now (only what the user's mode allows).";
        info.description =
            "With mode `always`: queues the shareable entries of this project that are not queued yet and sends the outbox (one request "
            "of up to 20 entries; failed ones keep their retry time). With mode `ask`: entries wait for the user's confirmation, which only "
            "the user gives (editor, or `factoria feedback share`); nothing is sent here. With mode `unset` or `never` nothing is sent and the "
            "result says why. Result: counts, per-entry results and the outcome (sent, failed, rate_limited, banned, off, "
            "unavailable, idle). Example: {\"ids\":[\"FB-0003\"]}";
        info.inputSchema = ids_schema();
        registry.add(info, [&registry, projectDir](const Json& args) {
            const ShareEnv& env = share_env();
            const std::string file = feedback_file_for(projectDir);
            const std::vector<std::string> ids = ids_arg(args);
            const ShareSettings settings = load_share_settings(env);
            Json out = Json::object();
            if (settings.mode == ShareMode::Always || settings.mode == ShareMode::Ask) {
                if (stdfs::exists(file)) {
                    auto q = share_queue(env, file, projectDir, collect_engine_names(&registry), ids);
                    if (!q.ok()) throw CommandError("failed", q.error().message, q.error().hint);
                    Json rep = Json::array();
                    for (const ShareEntryReport& r : q->entries) {
                        Json j = Json::object({{"id", r.id}, {"status", r.status}});
                        if (!r.reason.empty()) j["reason"] = r.reason;
                        rep.push_back(std::move(j));
                    }
                    out["entries"] = std::move(rep);
                    out["queued"] = q->queued;
                    out["waiting"] = q->waiting;
                    out["rejected"] = q->rejected;
                }
            }
            FlushOptions fo;
            fo.ids = ids;
            fo.timeoutSec = 5.0;
            fo.oneBatch = true;
            const FlushResult f = share_flush(env, fo);
            out["outcome"] = f.outcome;
            out["message"] = f.message;
            out["sent"] = f.sent;
            out["merged"] = f.merged;
            out["refused"] = f.rejected;
            out["retryLater"] = f.retryLater;
            out["results"] = f.results;
            if (f.outcome == "off" && settings.mode == ShareMode::Unset) out["howToTurnOn"] = how_to_turn_on();
            return out;
        });
    }
}

}  // namespace fa
