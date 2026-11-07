// Prices, limits and approval of paid asset generation (fa/ai/asset_cost.h).
#include "fa/ai/asset_cost.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <ctime>
#include <format>
#include <map>
#include <mutex>
#include <thread>
#include <utility>
#include <vector>

#include "asset_providers.h"
#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/tooling/feedback_share.h"
#include "util.h"

namespace fa::ai {

using namespace util;

namespace {

// Money is carried in millionths of a dollar so sums do not drift.
double round6(double v) { return std::round(v * 1e6) / 1e6; }
double round4(double v) { return std::round(v * 1e4) / 1e4; }
constexpr double kEpsilon = 1e-9;

// Characters of UTF-8 text (a voice is priced per character, not per byte).
std::size_t utf8_length(const std::string& text) {
    std::size_t n = 0;
    for (unsigned char c : text) n += (c & 0xC0) != 0x80;
    return n;
}

bool is_local_server(const ProviderConfig& p) {
    if (p.preset == "ollama" || p.preset == "lmstudio") return true;
    for (const char* host : {"://localhost", "://127.", "://[::1]", "://0.0.0.0"}) {
        if (p.baseUrl.find(host) != std::string::npos) return true;
    }
    return false;
}

const char* kind_label(MediaKind k) {
    switch (k) {
        case MediaKind::Image: return "image";
        case MediaKind::Sound: return "sound effect";
        case MediaKind::Music: return "music";
        case MediaKind::Voice: return "voice";
        case MediaKind::Model3d: return "3D model";
    }
    return "asset";
}

bool is_unverified(const AssetPricing& p, MediaKind kind) {
    return std::find(p.unverified.begin(), p.unverified.end(), media_kind_name(kind)) != p.unverified.end();
}

// One picture: the table of the size the provider draws, then the quality asked for.
std::optional<double> image_price(const AssetPricing& p, const std::vector<std::string>& sizes, const std::string& quality,
                                  std::string& sizeUsed, std::string& qualityUsed) {
    const std::map<std::string, double>* bySize = nullptr;
    for (const std::string& size : sizes) {
        if (auto it = p.image.find(size); it != p.image.end()) {
            bySize = &it->second;
            sizeUsed = size;
            break;
        }
    }
    if (!bySize) {
        if (auto it = p.image.find("default"); it != p.image.end()) {
            bySize = &it->second;
            sizeUsed = "default";
        }
    }
    if (!bySize || bySize->empty()) return std::nullopt;
    for (const std::string& q : {quality.empty() ? std::string("auto") : quality, std::string("default")}) {
        if (auto it = bySize->find(q); it != bySize->end()) {
            qualityUsed = q;
            return it->second;
        }
    }
    // The quality asked for has no price in this table: the dearest one, so the estimate is not low.
    double best = 0;
    for (const auto& [q, usd] : *bySize) {
        if (usd >= best) {
            best = usd;
            qualityUsed = q;
        }
    }
    return best;
}

}  // namespace

const char* asset_cost_doc() {
    return " COST: the result carries estimatedCostUsd (an ESTIMATE from the provider's assetPricing, not an invoice; null when the price is unknown; 0 for the fake "
           "provider and local programs). Before the provider is called the call is checked against the project's limits.maxAssetCostUsd (per run, per day) and "
           "refused with a teaching error when it would pass one. A call estimated above limits.askAboveUsd (default $0.50), or small calls that add up above it since the user last said yes, is NOT made: it returns "
           "{needsApproval:true, plan:{...}}. Tell the user what will be made, how many, with which provider and the estimate, and ask. Only when the user says yes, "
           "call again with the same arguments and approved:true. An AI must never set approved:true on its own, and never raise a limit itself. In the editor "
           "the user answers a card (Approve, Approve all for this run, Cancel) and the call just continues; there the approved argument is ignored.";
}

std::string format_usd(double usd) {
    std::string s = std::format("{:.4f}", usd < 0 ? 0.0 : usd);
    const auto dot = s.find('.');
    while (s.size() - dot - 1 > 2 && s.back() == '0') s.pop_back();  // "0.1670" -> "0.167", "0.5000" -> "0.50"
    return "$" + s;
}

AssetEstimate estimate_asset_cost(const ProviderConfig& provider, const AssetRequest& request, int count) {
    AssetEstimate e;
    e.count = std::clamp(count, 1, 1000);
    const AssetPricing& p = provider.assetPricing;
    e.checked = p.checked;
    e.source = p.source;
    e.note = p.note;
    if (provider.kind == ProviderKind::Fake && p.empty()) {  // a fake provider with a price table is a stand-in for a paid one (tests, demos)
        e.free = true;
        e.usd = 0.0;
        e.checked.clear();
        e.source.clear();
        e.note.clear();
        e.basis = "the fake provider is free and offline";
        return e;
    }
    e.verified = !is_unverified(p, request.kind);
    const std::string unit = kind_label(request.kind);
    std::optional<double> each;  // per result
    std::string detail;
    switch (request.kind) {
        case MediaKind::Image: {
            std::vector<std::string> sizes;
            if (provider.kind == ProviderKind::OpenAICompatible) sizes.push_back(openai_image_size(request));
            else sizes.push_back(std::to_string(request.width) + "x" + std::to_string(request.height));
            std::string sizeUsed, qualityUsed;
            each = image_price(p, sizes, request.quality, sizeUsed, qualityUsed);
            if (each && !p.model.empty()) {
                // The table was read for one model; another model is billed by its own price list, which the engine did not read.
                const std::string model = request.model.empty() ? asset_default_model(provider, MediaKind::Image) : request.model;
                if (!model.empty() && model != p.model) {
                    e.verified = false;
                    e.note += std::string(e.note.empty() ? "" : " ") + "This picture is made with " + model + " but the figures are those of " + p.model +
                              ": the real price may differ.";
                }
            }
            if (each) detail = std::format("{} picture, {}{}{} at {}", unit, sizeUsed == "default" ? std::string("any size") : sizeUsed,
                                           qualityUsed == "default" ? "" : ", quality ", qualityUsed == "default" ? "" : qualityUsed, format_usd(*each));
            break;
        }
        case MediaKind::Voice:
            if (p.voicePer1000Chars) {
                const std::size_t chars = utf8_length(request.prompt);
                each = *p.voicePer1000Chars * static_cast<double>(chars) / 1000.0;
                detail = std::format("{} characters of speech at {} per 1000", chars, format_usd(*p.voicePer1000Chars));
            }
            break;
        case MediaKind::Sound:
        case MediaKind::Music: {
            const std::optional<double>& perSecond = request.kind == MediaKind::Sound ? p.soundPerSecond : p.musicPerSecond;
            if (perSecond) {
                const bool assumed = request.seconds <= 0;
                const double seconds = assumed ? (request.kind == MediaKind::Sound ? 10.0 : 60.0) : request.seconds;
                each = *perSecond * seconds;
                detail = std::format("{} s of {}{} at {} per second", seconds, unit, assumed ? " (assumed: the provider chooses the length)" : "",
                                     format_usd(*perSecond));
            }
            break;
        }
        case MediaKind::Model3d:
            if (p.model3d) {
                each = *p.model3d;
                detail = std::format("one {} at {}", unit, format_usd(*p.model3d));
            }
            break;
    }
    if (each) {
        e.usd = round6(*each * e.count);
        e.basis = (e.count > 1 ? std::to_string(e.count) + " x " : std::string()) + detail;
        return e;
    }
    // No price in the table.
    const bool local = provider.kind == ProviderKind::AssetCommand || is_local_server(provider);
    if (local) {
        e.free = true;
        e.usd = 0.0;
        e.basis = provider.kind == ProviderKind::AssetCommand ? "a local program runs; FactorIA does not charge for it"
                                                              : "a local server answers; FactorIA does not charge for it";
        return e;
    }
    e.basis = std::format("the price of {} from '{}' is not known: add assetPricing to the provider in ai.json to get an estimate", unit, provider.name);
    e.verified = false;
    return e;
}

Json estimate_to_json(const AssetEstimate& e) {
    Json cost = Json::object({{"basis", e.basis}, {"count", e.count}, {"free", e.free}});
    if (!e.checked.empty()) cost["priceChecked"] = e.checked;
    if (!e.source.empty()) cost["priceSource"] = e.source;
    if (!e.verified) cost["priceUnverified"] = true;
    if (!e.note.empty()) cost["priceNote"] = e.note;
    Json out = Json::object();
    out["estimatedCostUsd"] = e.usd ? Json(round4(*e.usd)) : Json(nullptr);
    out["costIsEstimate"] = true;
    out["cost"] = std::move(cost);
    return out;
}

// ---- runs -----------------------------------------------------------------------------------------------------------------------

namespace {

struct RunLedger {
    double spent = 0;       // estimated dollars of the calls that went ahead in this run
    double unapproved = 0;  // ...of those, what nobody was asked about since the last yes (calls under askAboveUsd add up: see begin())
    bool approveAll = false;
};
std::mutex gRunMu;
std::map<std::string, RunLedger>& runs() {
    static std::map<std::string, RunLedger> m;
    return m;
}
thread_local std::string tRunKey;
thread_local AssetApprover tApprover;
thread_local const ShareEnv* tSpendEnv = nullptr;

// Where the day total lives: the user folder of this thread's scope (an autotest, which must not touch the real one), else the process's.
const ShareEnv& spend_env() { return tSpendEnv ? *tSpendEnv : share_env(); }

}  // namespace

AssetRunScope::AssetRunScope(std::string key, AssetApprover approver, const ShareEnv* spendEnv)
    : previous_(std::move(tRunKey)), previousApprover_(std::move(tApprover)), previousEnv_(tSpendEnv) {
    tRunKey = std::move(key);
    tApprover = std::move(approver);
    if (spendEnv) tSpendEnv = spendEnv;
}
AssetRunScope::~AssetRunScope() {
    tRunKey = std::move(previous_);
    tApprover = std::move(previousApprover_);
    tSpendEnv = previousEnv_;
}
std::string asset_run_key() { return tRunKey; }

void asset_run_begin(const std::string& key) {
    std::lock_guard<std::mutex> lock(gRunMu);
    runs()[key] = {};
}
void asset_run_approve_all(const std::string& key, bool on) {
    std::lock_guard<std::mutex> lock(gRunMu);
    runs()[key].approveAll = on;
}
bool asset_run_approves_all(const std::string& key) {
    std::lock_guard<std::mutex> lock(gRunMu);
    auto it = runs().find(key);
    return it != runs().end() && it->second.approveAll;
}
double asset_run_spent(const std::string& key) {
    std::lock_guard<std::mutex> lock(gRunMu);
    auto it = runs().find(key);
    return it == runs().end() ? 0.0 : it->second.spent;
}
double asset_run_unapproved(const std::string& key) {
    std::lock_guard<std::mutex> lock(gRunMu);
    auto it = runs().find(key);
    return it == runs().end() ? 0.0 : it->second.unapproved;
}

namespace {

// What the run's ledger says about a call of `amount`, in one step under the lock, so two calls at once cannot both slip under the
// question or the limit:
//   Asks       the person has to say yes first (nothing was counted)
//   OverLimit  the run's limit would be passed (nothing was counted)
//   Counted    the amount is now spent; `addedUnapproved` is the part that also went into the "unapproved since the last yes" total
enum class Reserve { Asks, OverLimit, Counted };
Reserve run_reserve(const std::string& key, double amount, bool unknown, double perRun, double askAbove, bool yes, double& addedUnapproved) {
    std::lock_guard<std::mutex> lock(gRunMu);
    RunLedger& r = runs()[key];
    addedUnapproved = 0;
    const bool asks = !r.approveAll && (unknown || r.unapproved + amount > askAbove + kEpsilon);
    if (asks && !yes) return Reserve::Asks;
    if (!unknown && amount > 0) {
        if (perRun > 0 && r.spent + amount > perRun + kEpsilon) return Reserve::OverLimit;
        r.spent = round6(r.spent + amount);
    }
    if (yes) {
        r.unapproved = 0;  // a yes covers everything before it
    } else if (!r.approveAll && !unknown) {
        r.unapproved = round6(r.unapproved + amount);
        addedUnapproved = amount;
    }
    return Reserve::Counted;
}
void run_refund(const std::string& key, double amount, double unapproved) {
    std::lock_guard<std::mutex> lock(gRunMu);
    RunLedger& r = runs()[key];
    r.spent = std::max(0.0, round6(r.spent - amount));
    r.unapproved = std::max(0.0, round6(r.unapproved - unapproved));
}

// Notices that could not reach a result (a refund that failed after the command had returned): the next call's result carries them.
std::mutex gNoticeMu;
std::vector<std::string>& pending_notices() {
    static std::vector<std::string> v;
    return v;
}
void add_notice(const std::string& text) {
    std::lock_guard<std::mutex> lock(gNoticeMu);
    auto& v = pending_notices();
    if (v.size() < 8) v.push_back(text);  // (a safety net: the same failure repeats)
}
std::vector<std::string> take_notices() {
    std::lock_guard<std::mutex> lock(gNoticeMu);
    return std::exchange(pending_notices(), {});
}

// ---- the day total ----------------------------------------------------------------------------------------------------------

constexpr const char* kSpendFormat = "factoria.asset-spend/1";
constexpr std::size_t kKeepDays = 31;

std::string local_date(std::int64_t secondsSince1970) {
    const std::time_t t = static_cast<std::time_t>(secondsSince1970);
    std::tm tm{};
#if defined(_WIN32)
    localtime_s(&tm, &t);
#else
    localtime_r(&t, &tm);
#endif
    return std::format("{:04}-{:02}-{:02}", tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday);
}

std::string today_text() { return local_date(spend_env().clock()); }

struct SpendFile {
    Json doc = Json::object();
    std::string error;  // "" = readable (a file that does not exist is an empty total)
};

// The shape the file is written in: {"format", "days": {"2026-11-06": {"<project key>": {"usd": 1.2, "calls": 3}}}}. Another shape (a hand
// edit, another program) is not read: the message says what is wrong and where.
std::string spend_shape_problem(const Json& doc) {
    if (!doc.is_object()) return "it is not a JSON object";
    const auto days = doc.find("days");
    if (days == doc.end()) return "";
    if (!days->is_object()) return "/days is not an object";
    for (auto d = days->begin(); d != days->end(); ++d) {
        if (!d.value().is_object()) return "/days/" + d.key() + " is not an object";
        for (auto e = d.value().begin(); e != d.value().end(); ++e) {
            const std::string at = "/days/" + d.key() + "/" + e.key();
            if (!e.value().is_object()) return at + " is not an object";
            for (const char* key : {"usd", "calls"}) {
                const auto v = e.value().find(key);
                if (v != e.value().end() && !(v->is_number() && std::isfinite(v->get<double>()))) return at + "/" + key + " is not a number";
            }
        }
    }
    return "";
}

SpendFile read_spend_once(const std::string& path) {
    SpendFile out;
    if (!fs::exists(path)) return out;
    auto text = fs::read_text(path);
    if (!text) {
        out.error = "cannot read " + path + ": " + text.error().message;
        return out;
    }
    Json parsed = parse(*text);
    if (parsed.is_discarded()) {
        out.error = path + " is not valid JSON, so the day's asset spending cannot be counted";
        return out;
    }
    if (const std::string problem = spend_shape_problem(parsed); !problem.empty()) {
        out.error = path + " does not have the shape this version writes (" + problem + "), so the day's asset spending cannot be counted";
        return out;
    }
    out.doc = std::move(parsed);
    return out;
}

// Under the lock nothing else replaces the file, so one read is enough.
SpendFile read_spend(const std::string& path) { return read_spend_once(path); }

// Without the lock a writer may be replacing the file at that moment (on Windows the replace makes a reader fail): try again a few times
// (a fixed number of tries, not a time) before calling the file unreadable.
SpendFile read_spend_retry(const std::string& path) {
    constexpr int kTries = 6;
    SpendFile out;
    for (int i = 0; i < kTries; ++i) {
        out = read_spend_once(path);
        if (out.error.empty()) break;
        if (i + 1 < kTries) std::this_thread::sleep_for(std::chrono::milliseconds(15));
    }
    return out;
}

double spent_in(const Json& doc, const std::string& date, const std::string& project) {
    const Json* days = child(doc, "days");
    const Json* day = days ? child(*days, date.c_str()) : nullptr;
    const Json* entry = day ? child(*day, project.c_str()) : nullptr;
    return entry ? num(*entry, "usd") : 0.0;
}

// `doc` passed spend_shape_problem(): every level that exists is an object.
void add_spent(Json& doc, const std::string& date, const std::string& project, double delta, int calls) {
    doc["format"] = kSpendFormat;
    Json& days = doc["days"];
    if (!days.is_object()) days = Json::object();
    Json& entry = days[date][project];
    const double usd = std::max(0.0, round6((entry.is_object() ? num(entry, "usd") : 0.0) + delta));
    const int n = std::max(0, static_cast<int>(std::clamp(entry.is_object() ? num(entry, "calls") : 0.0, 0.0, 1e9)) + calls);
    entry = Json::object({{"usd", usd}, {"calls", n}});
    if (days.size() > kKeepDays) {
        std::vector<std::string> dates;  // "2026-11-06": the text order is the date order
        for (auto it = days.begin(); it != days.end(); ++it) dates.push_back(it.key());
        std::sort(dates.begin(), dates.end());
        for (std::size_t i = 0; i + kKeepDays < dates.size(); ++i) days.erase(dates[i]);
    }
}

Result<void> write_spend(const std::string& path, const Json& doc) { return fs::write_text(path, dump_pretty(doc)); }

struct DayReservation {
    bool exceeded = false;
    double before = 0;
    std::string date;  // the day the money was counted on (a refund after midnight goes back to that day)
};

std::string spend_hint() { return "Fix or delete the file; it only holds the totals of the last days."; }

// Under the lock: reads the total, and adds `amount` unless that passes `limit`. Nothing is written when it is refused.
Result<DayReservation> day_reserve(const std::string& project, double amount, double limit) {
    ShareLock lock(spend_env());
    if (!lock.held()) {
        return make_error("The asset spending of the day could not be updated: " + lock.error(),
                          "Another FactorIA program holds the lock of the user folder; try again in a moment.");
    }
    const std::string path = asset_spend_path();
    SpendFile file = read_spend(path);
    if (!file.error.empty()) return make_error(file.error, spend_hint());
    DayReservation out;
    out.date = today_text();
    out.before = spent_in(file.doc, out.date, project);
    if (limit > 0 && out.before + amount > limit + kEpsilon) {
        out.exceeded = true;
        return out;
    }
    add_spent(file.doc, out.date, project, amount, 1);
    if (auto w = write_spend(path, file.doc); !w) return make_error("The asset spending of the day could not be saved: " + w.error().message, w.error().hint);
    return out;
}

// Gives `amount` back on the day it was counted. "" = done; otherwise why the total still holds it.
std::string day_refund(const std::string& project, const std::string& date, double amount) {
    ShareLock lock(spend_env());
    if (!lock.held()) return lock.error();
    const std::string path = asset_spend_path();
    SpendFile file = read_spend(path);
    if (!file.error.empty()) return file.error;
    add_spent(file.doc, date, project, -amount, -1);
    if (auto w = write_spend(path, file.doc); !w) return w.error().message;
    return "";
}

std::string project_key(const std::string& projectDir) { return share_project_key(projectDir); }

std::string shortened(const std::string& text, std::size_t max) {
    if (text.size() <= max) return text;
    std::size_t cut = max;
    while (cut > 0 && (static_cast<unsigned char>(text[cut]) & 0xC0) == 0x80) --cut;
    return text.substr(0, cut) + "...";
}

std::string limit_hint(const char* key) {
    return std::string("The user decides whether to raise it: in the editor (AI > AI Settings, the project's limits), or in the project's "
                       ".factoria/ai/settings.json or ~/.factoria/ai.json as {\"limits\": {\"maxAssetCostUsd\": {\"") + key +
           "\": 2}}}. Do not raise a limit yourself. Cheaper ways: fewer or smaller results, a cheaper provider, or the offline tools "
           "(assets.generate_texture, assets.rasterize_svg, assets.synth_sound).";
}

}  // namespace

std::string asset_spend_path() { return spend_env().config_dir() + "/asset-spend.json"; }

namespace {
// What `projectDir` has spent today, or why that cannot be read (`why`).
std::optional<double> read_today(const std::string& projectDir, std::string& why) {
    SpendFile file = read_spend_retry(asset_spend_path());
    if (!file.error.empty()) {
        why = file.error;
        return std::nullopt;
    }
    return spent_in(file.doc, today_text(), project_key(projectDir));
}
}  // namespace

std::optional<double> asset_spent_today(const std::string& projectDir) {
    std::string why;
    return read_today(projectDir, why);
}

namespace {
std::mutex gApproverMu;
AssetApprover& approver_slot() {
    static AssetApprover a;
    return a;
}
}  // namespace

AssetApprover set_asset_approver(AssetApprover approver) {
    std::lock_guard<std::mutex> lock(gApproverMu);
    AssetApprover previous = std::move(approver_slot());
    approver_slot() = std::move(approver);
    return previous;
}

// ---- the guard --------------------------------------------------------------------------------------------------------------------

namespace {
// The guard may be destroyed or asked for its numbers on a thread without the scope it began in: the user folder it counted in is its own.
struct SpendEnvScope {
    const ShareEnv* previous;
    explicit SpendEnvScope(const ShareEnv* env) : previous(tSpendEnv) { tSpendEnv = env; }
    ~SpendEnvScope() { tSpendEnv = previous; }
    SpendEnvScope(const SpendEnvScope&) = delete;
    SpendEnvScope& operator=(const SpendEnvScope&) = delete;
};
}  // namespace

AssetCostGuard::AssetCostGuard(AssetCostGuard&& o) noexcept
    : go_(o.go_), reserved_(o.reserved_), committed_(o.committed_), dayReserved_(o.dayReserved_), amount_(o.amount_),
      unapprovedAdded_(o.unapprovedAdded_), runKey_(std::move(o.runKey_)), projectDir_(std::move(o.projectDir_)), dayDate_(std::move(o.dayDate_)),
      spendEnv_(o.spendEnv_), cost_(std::move(o.cost_)), needsApproval_(std::move(o.needsApproval_)), warnings_(std::move(o.warnings_)) {
    o.reserved_ = o.dayReserved_ = false;
}

AssetCostGuard& AssetCostGuard::operator=(AssetCostGuard&& o) noexcept {
    if (this != &o) {
        release();
        go_ = o.go_;
        reserved_ = o.reserved_;
        committed_ = o.committed_;
        dayReserved_ = o.dayReserved_;
        amount_ = o.amount_;
        unapprovedAdded_ = o.unapprovedAdded_;
        runKey_ = std::move(o.runKey_);
        projectDir_ = std::move(o.projectDir_);
        dayDate_ = std::move(o.dayDate_);
        spendEnv_ = o.spendEnv_;
        cost_ = std::move(o.cost_);
        needsApproval_ = std::move(o.needsApproval_);
        warnings_ = std::move(o.warnings_);
        o.reserved_ = o.dayReserved_ = false;
    }
    return *this;
}

AssetCostGuard::~AssetCostGuard() { release(); }

// A call that failed gives its money back. A refund that cannot be written leaves the day's total too high, which the user must hear
// about: the command has usually returned by now (this runs when the guard goes out of scope on the error), so the notice goes into the
// log and into the next result (take_notices in begin()).
void AssetCostGuard::release() {
    if (committed_) return;
    if (reserved_) run_refund(runKey_, amount_, unapprovedAdded_);
    if (dayReserved_) {
        std::string why;
        try {
            SpendEnvScope env(spendEnv_);
            why = day_refund(project_key(projectDir_), dayDate_, amount_);
        } catch (const std::exception& e) {
            why = e.what();
        }
        if (!why.empty()) {
            const std::string text = "The estimated " + format_usd(amount_) + " of a failed asset call was not taken off today's asset spending (" + why +
                                     "): the day's total in asset-spend.json is that much too high until the day ends.";
            FA_WARN("ai", "{}", text);
            warnings_.push_back(text);
            add_notice(text);
        }
    }
    reserved_ = dayReserved_ = false;
}

void AssetCostGuard::commit() { committed_ = true; }

double AssetCostGuard::commit_part(int made, int count) {
    if (committed_) return amount_;
    if (count <= 0 || made >= count) {
        commit();
        return amount_;
    }
    if (made <= 0) {
        release();
        return 0.0;
    }
    // Give back the share of the results that were not made; what release() refunds is exactly that share.
    const double share = double(count - made) / double(count);
    const double kept = round6(amount_ * (1.0 - share));
    const double keptUnapproved = unapprovedAdded_ * (1.0 - share);
    amount_ = round6(amount_ - kept);
    unapprovedAdded_ -= keptUnapproved;
    release();
    committed_ = true;
    amount_ = kept;
    unapprovedAdded_ = keptUnapproved;
    return kept;
}

Json AssetCostGuard::cost_json() const {
    Json out = cost_;
    if (!out.is_object()) return Json::object();
    Json& cost = out["cost"];
    cost["spentThisRunUsd"] = round4(asset_run_spent(runKey_));
    SpendEnvScope env(spendEnv_);
    if (auto today = asset_spent_today(projectDir_)) cost["spentTodayUsd"] = round4(*today);
    return out;
}

bool is_needs_approval(const Json& result) { return result.is_object() && flag(result, "needsApproval"); }

AssetCostGuard AssetCostGuard::begin(const Limits& limits, const AssetCall& call, bool approvedArg) {
    AssetCostGuard g;
    g.runKey_ = asset_run_key();
    g.projectDir_ = call.projectDir;
    g.spendEnv_ = tSpendEnv;
    const AssetEstimate& e = call.estimate;
    g.cost_ = estimate_to_json(e);
    for (std::string& notice : take_notices()) g.warnings_.push_back(std::move(notice));
    if (e.free) {
        g.go_ = true;
        return g;
    }
    const bool unknown = !e.usd;
    const double amount = round6(e.usd_or_zero());
    g.amount_ = amount;
    const double perRun = limits.maxAssetCostPerRunUsd, perDay = limits.maxAssetCostPerDayUsd;
    const std::string what = call.what.empty() ? call.command : call.what;
    const std::string priceText = unknown ? "an unknown price" : "an estimated " + format_usd(amount) + " (" + e.basis + ")";

    if (unknown && (perRun > 0 || perDay > 0)) {
        throw CommandError("asset_cost_unknown",
                           std::format("{} from '{}' is refused: its price is not known and limits.maxAssetCostUsd is set ({}{}{}), so the limit cannot be kept",
                                       what, call.provider, perRun > 0 ? "perRun " + format_usd(perRun) : std::string(),
                                       perRun > 0 && perDay > 0 ? ", " : "", perDay > 0 ? "perDay " + format_usd(perDay) : std::string()),
                           "Add assetPricing for this provider to ai.json (docs/AI_PROVIDERS.md, \"Asset prices\"), choose a provider whose price is known, or ask "
                           "the user to remove the limit.",
                           Json::object({{"provider", call.provider}, {"kind", media_kind_name(call.kind)}}));
    }
    const double spentRun = asset_run_spent(g.runKey_);
    if (perRun > 0 && spentRun + amount > perRun + kEpsilon) {
        throw CommandError("asset_cost_limit",
                           std::format("{} is refused: limits.maxAssetCostUsd.perRun is {} and this run has already spent an estimated {} on assets; this call is {} more",
                                       what, format_usd(perRun), format_usd(spentRun), priceText),
                           limit_hint("perRun"),
                           Json::object({{"limit", "perRun"}, {"limitUsd", perRun}, {"spentUsd", round4(spentRun)}, {"estimatedUsd", round4(amount)}}));
    }
    const std::string project = project_key(call.projectDir);
    if (perDay > 0) {
        std::string why;
        const std::optional<double> today = read_today(call.projectDir, why);
        if (!today) {
            throw CommandError("asset_cost_unavailable",
                               "The asset spending of today cannot be read, so limits.maxAssetCostUsd.perDay cannot be checked: " + why,
                               "Fix or delete " + asset_spend_path() + " (it only holds the totals of the last days), then try again. Nothing was paid.");
        }
        if (*today + amount > perDay + kEpsilon) {
            throw CommandError("asset_cost_limit",
                               std::format("{} is refused: limits.maxAssetCostUsd.perDay is {} and this project has already spent an estimated {} on assets today "
                                           "(counted across every editor, terminal and agent); this call is {} more",
                                           what, format_usd(perDay), format_usd(*today), priceText),
                               limit_hint("perDay"),
                               Json::object({{"limit", "perDay"}, {"limitUsd", perDay}, {"spentUsd", round4(*today)}, {"estimatedUsd", round4(amount)}}));
        }
    }

    // Who answers? The editor's approver (this thread's, else the process's). With one, the person's card is the only way to a yes: the
    // approved argument is something an AI can pass, so it counts only without an approver.
    AssetApprover approver = tApprover;
    if (!approver) {
        std::lock_guard<std::mutex> lock(gApproverMu);
        approver = approver_slot();
    }
    bool yes = call.userApproved || (!approver && approvedArg);

    // Count the money as spent now, so two calls at once cannot both pass the limit or the question; a failed call gives it back. A call
    // is asked about when it alone, or it together with the calls since the last yes, is above askAboveUsd: a batch cut into small
    // calls costs the same and is asked about like one.
    double addedUnapproved = 0;
    Reserve reserved = Reserve::Asks;
    for (int attempt = 0; attempt < 2; ++attempt) {
        reserved = run_reserve(g.runKey_, amount, unknown, perRun, limits.askAboveUsd, yes, addedUnapproved);
        if (reserved != Reserve::Asks) break;

        // The person has to say yes.
        const double before = asset_run_unapproved(g.runKey_);
        Json plan = Json::object({{"command", call.command},
                                  {"what", what},
                                  {"kind", media_kind_name(call.kind)},
                                  {"provider", call.provider},
                                  {"count", e.count},
                                  {"estimatedCostUsd", unknown ? Json(nullptr) : Json(round4(amount))},
                                  {"basis", e.basis}});
        if (before > kEpsilon) plan["earlierUnapprovedUsd"] = round4(before);
        if (!call.model.empty()) plan["model"] = call.model;
        if (!call.prompt.empty()) plan["prompt"] = shortened(call.prompt, 300);
        if (!e.checked.empty()) plan["priceChecked"] = e.checked;
        if (!e.source.empty()) plan["priceSource"] = e.source;
        if (!e.verified) plan["priceUnverified"] = true;
        if (!approver) {
            std::string message;
            if (unknown) message = std::format("{} from '{}' has an unknown price, so it needs the user's approval before anything is paid.", what, call.provider);
            else if (amount > limits.askAboveUsd + kEpsilon)
                message = std::format("{} is estimated at {}, above the {} the project asks about (limits.askAboveUsd), so it needs the user's approval before anything is paid.",
                                      what, format_usd(amount), format_usd(limits.askAboveUsd));
            else
                message = std::format("{} is estimated at {}; with the {} of the calls since the user last said yes that is {}, above the {} the project asks about "
                                      "(limits.askAboveUsd), so it needs the user's approval before anything is paid.",
                                      what, format_usd(amount), format_usd(before), format_usd(before + amount), format_usd(limits.askAboveUsd));
            g.needsApproval_ = Json::object(
                {{"needsApproval", true},
                 {"generated", false},
                 {"message", message},
                 {"plan", std::move(plan)},
                 {"next", "Nothing was generated or paid. Tell the user what will be made, how many, with which provider and the estimate above"
                          + std::string(before > kEpsilon ? " (and that it comes after " + format_usd(before) + " of earlier asset calls they were not asked about)" : "") +
                          ", and ask whether to go ahead. Only if the user says yes, call the same command again with the same arguments and approved:true. Never set "
                          "approved:true on your own, and do not ask again for a call the user already approved."}});
            return g;
        }
        if (approvedArg && !call.userApproved) {
            g.warnings_.push_back("The approved argument was ignored: in the editor the user answers the card themselves, an AI cannot answer for them.");
        }
        // The editor: its card asks the person while this (agent) thread waits.
        const AssetDecision answer = approver(AssetApprovalRequest{g.runKey_, plan, call.cancel});
        if (answer == AssetDecision::Stopped) {
            throw CommandError("cancelled", std::format("The run was stopped while {} ({}) waited for the user's approval: nothing was generated or paid", what, priceText),
                               "The user stopped the run. Do not start the call again unless they ask for it.", Json::object({{"plan", plan}}));
        }
        if (answer == AssetDecision::Cancel) {
            throw CommandError("asset_declined",
                               std::format("The user did not approve {} ({}): nothing was generated or paid", what, unknown ? std::string("unknown price") : priceText),
                               "Do not ask for the same thing again. Continue without it (use a placeholder or the offline tools), or ask the user what they want instead.",
                               Json::object({{"plan", plan}}));
        }
        if (answer == AssetDecision::ApproveAll) asset_run_approve_all(g.runKey_);
        yes = true;
    }
    if (reserved == Reserve::OverLimit) {
        throw CommandError("asset_cost_limit",
                           std::format("{} is refused: limits.maxAssetCostUsd.perRun is {} and this run has already spent an estimated {} on assets; this call is {} more",
                                       what, format_usd(perRun), format_usd(asset_run_spent(g.runKey_)), priceText),
                           limit_hint("perRun"),
                           Json::object({{"limit", "perRun"}, {"limitUsd", perRun}, {"estimatedUsd", round4(amount)}}));
    }
    g.unapprovedAdded_ = addedUnapproved;
    g.reserved_ = true;
    if (!unknown && amount > 0) {
        auto day = day_reserve(project, amount, perDay);
        if (!day) {
            if (perDay > 0) {
                run_refund(g.runKey_, amount, g.unapprovedAdded_);
                g.reserved_ = false;
                throw CommandError("asset_cost_unavailable", day.error().message, day.error().hint + " Nothing was paid.");
            }
            g.warnings_.push_back("The day's asset spending was not recorded: " + day.error().message);
        } else if (day->exceeded) {
            run_refund(g.runKey_, amount, g.unapprovedAdded_);
            g.reserved_ = false;
            throw CommandError("asset_cost_limit",
                               std::format("{} is refused: limits.maxAssetCostUsd.perDay is {} and this project has already spent an estimated {} on assets today "
                                           "(counted across every editor, terminal and agent); this call is {} more",
                                           what, format_usd(perDay), format_usd(day->before), priceText),
                               limit_hint("perDay"),
                               Json::object({{"limit", "perDay"}, {"limitUsd", perDay}, {"spentUsd", round4(day->before)}, {"estimatedUsd", round4(amount)}}));
        } else {
            g.dayReserved_ = true;
            g.dayDate_ = day->date;
        }
    }
    g.go_ = true;
    return g;
}

}  // namespace fa::ai
