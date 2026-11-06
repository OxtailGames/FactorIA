// Prices, limits and approval of paid asset generation (fa/ai/asset_cost.h).
#include "fa/ai/asset_cost.h"

#include <algorithm>
#include <cmath>
#include <ctime>
#include <format>
#include <map>
#include <mutex>
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
           "refused with a teaching error when it would pass one. A call estimated above limits.askAboveUsd (default $0.50) is NOT made: it returns "
           "{needsApproval:true, plan:{...}}. Tell the user what will be made, how many, with which provider and the estimate, and ask. Only when the user says yes, "
           "call again with the same arguments and approved:true. An AI must never set approved:true on its own, and never raise a limit itself. In the editor "
           "the user answers a card (Approve, Approve all for this run, Cancel) and the call just continues.";
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
    double spent = 0;
    bool approveAll = false;
};
std::mutex gRunMu;
std::map<std::string, RunLedger>& runs() {
    static std::map<std::string, RunLedger> m;
    return m;
}
thread_local std::string tRunKey;

}  // namespace

AssetRunScope::AssetRunScope(std::string key) : previous_(std::move(tRunKey)) { tRunKey = std::move(key); }
AssetRunScope::~AssetRunScope() { tRunKey = std::move(previous_); }
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

namespace {

// Adds `amount` to the run unless that passes `limit` (> 0). Returns false and leaves the total alone when it would.
bool run_reserve(const std::string& key, double amount, double limit) {
    std::lock_guard<std::mutex> lock(gRunMu);
    RunLedger& r = runs()[key];
    if (limit > 0 && r.spent + amount > limit + kEpsilon) return false;
    r.spent = round6(r.spent + amount);
    return true;
}
void run_refund(const std::string& key, double amount) {
    std::lock_guard<std::mutex> lock(gRunMu);
    RunLedger& r = runs()[key];
    r.spent = std::max(0.0, round6(r.spent - amount));
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

std::string today_text() { return local_date(share_env().clock()); }

struct SpendFile {
    Json doc = Json::object();
    std::string error;  // "" = readable (a file that does not exist is an empty total)
};

SpendFile read_spend(const std::string& path) {
    SpendFile out;
    if (!fs::exists(path)) return out;
    auto text = fs::read_text(path);
    if (!text) {
        out.error = "cannot read " + path + ": " + text.error().message;
        return out;
    }
    Json parsed = parse(*text);
    if (parsed.is_discarded() || !parsed.is_object()) {
        out.error = path + " is not a JSON object, so the day's asset spending cannot be counted";
        return out;
    }
    out.doc = std::move(parsed);
    return out;
}

double spent_in(const Json& doc, const std::string& date, const std::string& project) {
    const Json* days = child(doc, "days");
    const Json* day = days ? child(*days, date.c_str()) : nullptr;
    const Json* entry = day ? child(*day, project.c_str()) : nullptr;
    return entry ? num(*entry, "usd") : 0.0;
}

void add_spent(Json& doc, const std::string& date, const std::string& project, double delta, int calls) {
    doc["format"] = kSpendFormat;
    Json& days = doc["days"];
    if (!days.is_object()) days = Json::object();
    Json& entry = days[date][project];
    const double usd = std::max(0.0, round6(num(entry, "usd") + delta));
    const int n = std::max(0, static_cast<int>(num(entry, "calls")) + calls);
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
};

// Under the lock: reads the total, and adds `amount` unless that passes `limit`. Nothing is written when it is refused.
Result<DayReservation> day_reserve(const std::string& project, double amount, double limit) {
    ShareLock lock(share_env());
    if (!lock.held()) {
        return make_error("The asset spending of the day could not be updated: " + lock.error(),
                          "Another FactorIA program holds the lock of the user folder; try again in a moment.");
    }
    const std::string path = asset_spend_path();
    SpendFile file = read_spend(path);
    if (!file.error.empty()) return make_error(file.error, "Fix or delete the file; it only holds the totals of the last days.");
    const std::string date = today_text();
    DayReservation out;
    out.before = spent_in(file.doc, date, project);
    if (limit > 0 && out.before + amount > limit + kEpsilon) {
        out.exceeded = true;
        return out;
    }
    add_spent(file.doc, date, project, amount, 1);
    if (auto w = write_spend(path, file.doc); !w) return make_error("The asset spending of the day could not be saved: " + w.error().message, w.error().hint);
    return out;
}

void day_refund(const std::string& project, double amount) {
    ShareLock lock(share_env());
    if (!lock.held()) {
        FA_WARN("ai", "asset spending: the refund of {} was not recorded ({})", format_usd(amount), lock.error());
        return;
    }
    const std::string path = asset_spend_path();
    SpendFile file = read_spend(path);
    if (!file.error.empty()) {
        FA_WARN("ai", "asset spending: the refund of {} was not recorded ({})", format_usd(amount), file.error);
        return;
    }
    add_spent(file.doc, today_text(), project, -amount, -1);
    if (auto w = write_spend(path, file.doc); !w) FA_WARN("ai", "asset spending: the refund of {} was not saved ({})", format_usd(amount), w.error().message);
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

std::string asset_spend_path() { return share_env().config_dir() + "/asset-spend.json"; }

std::optional<double> asset_spent_today(const std::string& projectDir) {
    SpendFile file = read_spend(asset_spend_path());
    if (!file.error.empty()) return std::nullopt;
    return spent_in(file.doc, today_text(), project_key(projectDir));
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

AssetCostGuard::AssetCostGuard(AssetCostGuard&& o) noexcept
    : go_(o.go_), reserved_(o.reserved_), committed_(o.committed_), dayReserved_(o.dayReserved_), amount_(o.amount_),
      runKey_(std::move(o.runKey_)), projectDir_(std::move(o.projectDir_)), cost_(std::move(o.cost_)),
      needsApproval_(std::move(o.needsApproval_)), warnings_(std::move(o.warnings_)) {
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
        runKey_ = std::move(o.runKey_);
        projectDir_ = std::move(o.projectDir_);
        cost_ = std::move(o.cost_);
        needsApproval_ = std::move(o.needsApproval_);
        warnings_ = std::move(o.warnings_);
        o.reserved_ = o.dayReserved_ = false;
    }
    return *this;
}

AssetCostGuard::~AssetCostGuard() { release(); }

void AssetCostGuard::release() {
    if (committed_) return;
    if (reserved_) run_refund(runKey_, amount_);
    if (dayReserved_) day_refund(project_key(projectDir_), amount_);
    reserved_ = dayReserved_ = false;
}

void AssetCostGuard::commit() { committed_ = true; }

Json AssetCostGuard::cost_json() const {
    Json out = cost_;
    if (!out.is_object()) return Json::object();
    Json& cost = out["cost"];
    cost["spentThisRunUsd"] = round4(asset_run_spent(runKey_));
    if (auto today = asset_spent_today(projectDir_)) cost["spentTodayUsd"] = round4(*today);
    return out;
}

bool is_needs_approval(const Json& result) { return result.is_object() && flag(result, "needsApproval"); }

AssetCostGuard AssetCostGuard::begin(const Limits& limits, const AssetCall& call, bool approved) {
    AssetCostGuard g;
    g.runKey_ = asset_run_key();
    g.projectDir_ = call.projectDir;
    const AssetEstimate& e = call.estimate;
    g.cost_ = estimate_to_json(e);
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
        const std::optional<double> today = asset_spent_today(call.projectDir);
        if (!today) {
            throw CommandError("asset_cost_unavailable",
                               "The asset spending of today cannot be read, so limits.maxAssetCostUsd.perDay cannot be checked: " + asset_spend_path(),
                               "Fix or delete that file (it only holds the totals of the last days), then try again. Nothing was paid.");
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

    // Does the person have to say yes?
    const bool asks = unknown || amount > limits.askAboveUsd + kEpsilon;
    if (asks && !approved && !asset_run_approves_all(g.runKey_)) {
        Json plan = Json::object({{"command", call.command},
                                  {"what", what},
                                  {"kind", media_kind_name(call.kind)},
                                  {"provider", call.provider},
                                  {"count", e.count},
                                  {"estimatedCostUsd", unknown ? Json(nullptr) : Json(round4(amount))},
                                  {"basis", e.basis}});
        if (!call.model.empty()) plan["model"] = call.model;
        if (!call.prompt.empty()) plan["prompt"] = shortened(call.prompt, 300);
        if (!e.checked.empty()) plan["priceChecked"] = e.checked;
        if (!e.source.empty()) plan["priceSource"] = e.source;
        if (!e.verified) plan["priceUnverified"] = true;
        AssetApprover approver;
        {
            std::lock_guard<std::mutex> lock(gApproverMu);
            approver = approver_slot();
        }
        if (approver) {
            // The editor: its card asks the person while this (agent) thread waits.
            const AssetDecision answer = approver(AssetApprovalRequest{g.runKey_, plan, call.cancel});
            if (answer == AssetDecision::Cancel) {
                throw CommandError("asset_declined",
                                   std::format("The user did not approve {} ({}): nothing was generated or paid", what, unknown ? std::string("unknown price") : priceText),
                                   "Do not ask for the same thing again. Continue without it (use a placeholder or the offline tools), or ask the user what they want instead.",
                                   Json::object({{"plan", plan}}));
            }
            if (answer == AssetDecision::ApproveAll) asset_run_approve_all(g.runKey_);
        } else {
            std::string message = unknown ? std::format("{} from '{}' has an unknown price, so it needs the user's approval before anything is paid.", what, call.provider)
                                          : std::format("{} is estimated at {}, above the {} the project asks about (limits.askAboveUsd), so it needs the user's approval before anything is paid.",
                                                        what, format_usd(amount), format_usd(limits.askAboveUsd));
            g.needsApproval_ = Json::object(
                {{"needsApproval", true},
                 {"generated", false},
                 {"message", message},
                 {"plan", std::move(plan)},
                 {"next", "Nothing was generated or paid. Tell the user what will be made, how many, with which provider and the estimate above, and ask whether to go ahead. "
                          "Only if the user says yes, call the same command again with the same arguments and approved:true. Never set approved:true on your own, and do "
                          "not ask again for a call the user already approved."}});
            return g;
        }
    }

    // Count the money as spent now, so two calls at once cannot both pass the limit; a failed call gives it back.
    if (!unknown && amount > 0) {
        if (!run_reserve(g.runKey_, amount, perRun)) {
            throw CommandError("asset_cost_limit",
                               std::format("{} is refused: limits.maxAssetCostUsd.perRun is {} and this run has already spent an estimated {} on assets; this call is {} more",
                                           what, format_usd(perRun), format_usd(asset_run_spent(g.runKey_)), priceText),
                               limit_hint("perRun"),
                               Json::object({{"limit", "perRun"}, {"limitUsd", perRun}, {"estimatedUsd", round4(amount)}}));
        }
        g.reserved_ = true;
        auto day = day_reserve(project, amount, perDay);
        if (!day) {
            if (perDay > 0) {
                run_refund(g.runKey_, amount);
                g.reserved_ = false;
                throw CommandError("asset_cost_unavailable", day.error().message, day.error().hint + " Nothing was paid.");
            }
            g.warnings_.push_back("The day's asset spending was not recorded: " + day.error().message);
        } else if (day->exceeded) {
            run_refund(g.runKey_, amount);
            g.reserved_ = false;
            throw CommandError("asset_cost_limit",
                               std::format("{} is refused: limits.maxAssetCostUsd.perDay is {} and this project has already spent an estimated {} on assets today "
                                           "(counted across every editor, terminal and agent); this call is {} more",
                                           what, format_usd(perDay), format_usd(day->before), priceText),
                               limit_hint("perDay"),
                               Json::object({{"limit", "perDay"}, {"limitUsd", perDay}, {"spentUsd", round4(day->before)}, {"estimatedUsd", round4(amount)}}));
        } else {
            g.dayReserved_ = true;
        }
    }
    g.go_ = true;
    return g;
}

}  // namespace fa::ai
