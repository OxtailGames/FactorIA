// The fake platform backend (fa/services/fake_platform.h).
#include "fa/services/fake_platform.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <format>

#include "fa/core/strings.h"

namespace fa {

namespace {

constexpr std::size_t kMaxLoggedCalls = 500;
const char* const kPlayerId = "fake-player";

std::string in_quotes(const std::string& s) { return Json(s).dump(); }

Json player_json(bool signedIn) {
    return signedIn ? Json::object({{"id", kPlayerId}, {"name", "Player"}, {"signedIn", true}})
                    : Json::object({{"id", ""}, {"name", ""}, {"signedIn", false}});
}

// "$0.99" for dollars, "0.99 EUR" for the rest.
std::string format_price(double price, const std::string& currency) {
    const std::string amount = std::format("{:.2f}", price);
    return currency == "USD" ? "$" + amount : amount + " " + currency;
}

// Methods that answer with an array (or null): a scripted answer for them must be {"result": ...} or {"error": ...}.
bool answers_with_array(const std::string& method) {
    return method == "achievements.list" || method == "leaderboards.entries" || method == "cloud.list" || method == "purchases.products" ||
           method == "purchases.restore" || method == "remotePlay.sessions";
}

// The board a leaderboard request is about: the id, plus the period's key for a daily or weekly board.
std::string board_key(const Json& args) {
    const std::string key = args.value("periodKey", std::string());
    return args.value("id", std::string()) + (key.empty() ? std::string() : "@" + key);
}

Json number_json(double v, bool whole) { return whole ? Json(static_cast<long long>(v)) : Json(v); }

}  // namespace

FakeBackend::FakeBackend() { reset(); }

void FakeBackend::reset() {
    none_ = false;
    signedIn_ = true;
    delay_ = 0;
    frames_ = seq_ = callsDropped_ = 0;
    nextTx_ = nextIntegrity_ = 1;
    scripted_.clear();
    held_.clear();
    achievements_.clear();
    stats_.clear();
    bests_.clear();
    adOutcome_ = "watched";
    gdpr_ = "granted";
    tracking_ = "authorized";
    privacyOptions_ = "notRequired";
    adsShown_ = adsRewarded_ = adsPrivacyShown_ = 0;
    cloud_.clear();
    cloudModified_.clear();
    cloudClock_ = kCloudClockStart;
    guests_.clear();
    nextGuest_ = 1;
    owned_.clear();
    unfinished_.clear();
    presence_ = Json::object({{"text", ""}, {"data", Json::object()}});
    log_.clear();
}

void FakeBackend::set_signed_in(bool signedIn) {
    if (signedIn == signedIn_) return;
    signedIn_ = signedIn;
    sink_.emit("player", Json::object({{"id", kPlayerId}, {"name", "Player"}, {"signedIn", signedIn}}));  // the account, in or out
}

void FakeBackend::set_delay_frames(int frames) { delay_ = std::max(0, frames); }

// -------------------------------------------------------------------------------------------------------- hooks ----
Result<void> FakeBackend::respond(const std::string& method, const Json& answer, int times) {
    if (!find_platform_method(method)) {
        std::vector<std::string> names;
        for (const PlatformMethodInfo& m : platform_methods()) names.push_back(m.name);
        return make_error("platform.respond: " + in_quotes(method) + " is not a platform method", did_you_mean(method, names));
    }
    if (!answer.is_object())
        return make_error("platform.respond: the answer must be an object, got " + describe_json_value(answer),
                          "Use {\"error\": \"network\"} to reject, {\"result\": value} to resolve with exactly that value, or an object "
                          "such as {\"status\": \"cancelled\"} to change fields of the default result.");
    if (times < 1) return make_error("platform.respond: times must be at least 1, got " + std::to_string(times), "Use 1 for the next request only.");
    if (answer.contains("error") && answer.contains("result"))
        return make_error("platform.respond: the answer has both \"error\" and \"result\"", "Pick one: reject with the error, or resolve with the result.");
    if (answer.contains("error")) {
        const Json& code = answer["error"];
        if (!code.is_string() || !std::count(platform_error_codes().begin(), platform_error_codes().end(), code.get<std::string>()))
            return make_error("platform.respond: " + describe_json_value(code) + " is not an error code",
                              code.is_string() ? did_you_mean(code.get<std::string>(), platform_error_codes())
                                               : "Use one of " + join(platform_error_codes(), ", ") + ".");
        for (const char* key : {"message", "hint"})
            if (answer.contains(key) && !answer[key].is_string())
                return make_error(std::string("platform.respond: \"") + key + "\" must be a string, got " + describe_json_value(answer[key]));
    } else if (!answer.contains("result") && answers_with_array(method)) {
        return make_error("platform.respond: " + method + " answers with a list, so its default cannot be merged with fields",
                          "Script the whole list with {\"result\": [...]} or reject with {\"error\": \"network\"}.");
    }
    scripted_[method].push_back({answer, times});
    return {};
}

Result<void> FakeBackend::set_ad(const std::string& outcome, const std::string& gdpr, const std::string& tracking,
                                 const std::string& privacyOptions) {
    static const std::vector<std::string> outcomes = {"watched", "closedEarly", "consentRefused", "noFill"};
    static const std::vector<std::string> gdprs = {"granted", "denied", "notRequired", "unknown"};
    static const std::vector<std::string> trackings = {"authorized", "denied", "notDetermined", "restricted", "notRequired"};
    static const std::vector<std::string> privacy = {"required", "notRequired", "unknown"};
    auto check = [](const std::string& value, const std::vector<std::string>& allowed, const char* what) -> Result<void> {
        if (value.empty() || std::count(allowed.begin(), allowed.end(), value)) return {};
        return make_error("platform.set_ad: " + in_quotes(value) + " is not " + what, did_you_mean(value, allowed) + " Use one of " +
                                                                                           join(allowed, ", ") + ".");
    };
    if (auto r = check(outcome, outcomes, "an ad outcome"); !r.ok()) return r;
    if (auto r = check(gdpr, gdprs, "a GDPR consent state"); !r.ok()) return r;
    if (auto r = check(tracking, trackings, "a tracking permission state"); !r.ok()) return r;
    if (auto r = check(privacyOptions, privacy, "a privacy options state"); !r.ok()) return r;
    if (!outcome.empty()) adOutcome_ = outcome;
    if (outcome == "consentRefused") gdpr_ = tracking_ = "denied";
    if (!gdpr.empty()) gdpr_ = gdpr;
    if (!tracking.empty()) tracking_ = tracking;
    if (!privacyOptions.empty()) privacyOptions_ = privacyOptions;
    return {};
}

Result<void> FakeBackend::emit(const std::string& event, const Json& data) {
    if (!std::count(platform_events().begin(), platform_events().end(), event))
        return make_error("platform.emit: " + in_quotes(event) + " is not a platform event", did_you_mean(event, platform_events()));
    if (event == "remotePlay")
        return make_error("platform.emit: a \"remotePlay\" event comes with a session that platform.remote_play_connect keeps",
                          "Use game.platform.remotePlayConnect({ guestName: \"Ana\" }) and remotePlayDisconnect(id): they send the event and "
                          "update what remotePlay.sessions() answers.");
    if (!data.is_null() && !data.is_object())
        return make_error("platform.emit: the data must be an object, got " + describe_json_value(data), {});
    if (!sink_.alive()) return make_error("platform.emit: the fake backend is not attached to a running game", "Use it through an Engine.");
    Json d = data.is_null() ? Json::object() : data;
    if (event == "purchase") {
        if (!d.contains("productId") || !d["productId"].is_string())
            return make_error("platform.emit: a \"purchase\" event needs a \"productId\"",
                              "Example: {\"status\": \"purchased\", \"productId\": \"gems_100\"}; status is \"purchased\" (default), \"pending\" or \"cancelled\".");
        if (!d.contains("status")) d["status"] = "purchased";
        if (d["status"] == "purchased") {
            std::string tx = d.value("transactionId", std::string()), receipt = d.value("receipt", std::string());
            if (tx.empty()) tx = "fake-" + std::to_string(nextTx_++);
            if (receipt.empty()) receipt = "fake-receipt-" + tx.substr(tx.rfind('-') == std::string::npos ? 0 : tx.rfind('-') + 1);
            d["transactionId"] = tx;
            d["receipt"] = receipt;
            unfinished_.push_back({tx, d["productId"].get<std::string>(), receipt});
        }
    } else if (event == "overlay") {
        if (!d.contains("open") || !d["open"].is_boolean())
            return make_error("platform.emit: an \"overlay\" event needs \"open\": true or false", "Example: {\"open\": true}.");
    }
    sink_.emit(event, std::move(d));
    return {};
}

Result<Json> FakeBackend::connect_guest(const Json& info) {
    if (!sink_.alive())
        return make_error("platform.remote_play_connect: the fake backend is not attached to a running game", "Use it through an Engine.");
    if (!info.is_null() && !info.is_object())
        return make_error("platform.remote_play_connect: the guest's info must be an object, got " + describe_json_value(info),
                          "Example: {\"guestName\": \"Ana\", \"formFactor\": \"phone\"}.");
    static const std::vector<std::string> keys = {"guestName", "guestId", "deviceName", "formFactor", "resolution"};
    static const std::vector<std::string> forms = {"unknown", "phone", "tablet", "computer", "tv", "vr"};
    const Json in = info.is_null() ? Json::object() : info;
    for (auto it = in.begin(); it != in.end(); ++it)
        if (!std::count(keys.begin(), keys.end(), it.key()))
            return make_error("platform.remote_play_connect: " + in_quotes(it.key()) + " is not a field of a Remote Play session",
                              did_you_mean(it.key(), keys) + " Fields: " + join(keys, ", ") + ".");
    for (const char* key : {"guestName", "guestId", "deviceName"})
        if (in.contains(key) && !in[key].is_string())
            return make_error(std::string("platform.remote_play_connect: \"") + key + "\" must be a string, got " + describe_json_value(in[key]), {});
    if (in.contains("formFactor") &&
        (!in["formFactor"].is_string() || !std::count(forms.begin(), forms.end(), in["formFactor"].get<std::string>())))
        return make_error("platform.remote_play_connect: " + describe_json_value(in["formFactor"]) + " is not a form factor",
                          (in["formFactor"].is_string() ? did_you_mean(in["formFactor"].get<std::string>(), forms) + " " : std::string()) +
                              "Use one of " + join(forms, ", ") + ".");
    Json resolution = Json::object({{"width", 1920}, {"height", 1080}});
    if (in.contains("resolution")) {
        const Json& r = in["resolution"];
        auto dimension = [](const Json& v) { return v.is_number_integer() && v.get<long long>() > 0 && v.get<long long>() <= 65535; };
        if (!r.is_object() || !r.contains("width") || !r.contains("height") || !dimension(r["width"]) || !dimension(r["height"]))
            return make_error("platform.remote_play_connect: \"resolution\" must be {width, height} in whole pixels, got " + describe_json_value(r),
                              "Example: {\"width\": 1280, \"height\": 720}.");
        resolution = Json::object({{"width", r["width"]}, {"height", r["height"]}});
    }
    const long long id = nextGuest_++;
    const Json session = Json::object({{"id", id},
                                       {"guestName", in.value("guestName", "Guest " + std::to_string(id))},
                                       {"guestId", in.value("guestId", "fake-guest-" + std::to_string(id))},
                                       {"deviceName", in.value("deviceName", std::string("Fake device"))},
                                       {"formFactor", in.value("formFactor", std::string("computer"))},
                                       {"resolution", resolution}});
    guests_.push_back(session);
    sink_.emit("remotePlay", Json::object({{"status", "connected"}, {"session", session}}));
    return session;
}

Result<Json> FakeBackend::disconnect_guest(long long sessionId) {
    if (!sink_.alive())
        return make_error("platform.remote_play_disconnect: the fake backend is not attached to a running game", "Use it through an Engine.");
    for (auto it = guests_.begin(); it != guests_.end(); ++it) {
        if ((*it)["id"].get<long long>() != sessionId) continue;
        const Json session = *it;
        guests_.erase(it);
        sink_.emit("remotePlay", Json::object({{"status", "disconnected"}, {"session", session}}));
        return session;
    }
    std::string hint = guests_.empty() ? "No guest is connected: platform.remote_play_connect adds one." : "Connected session ids:";
    for (std::size_t i = 0; i < guests_.size(); ++i) hint += (i ? ", " : " ") + std::to_string(guests_[i]["id"].get<long long>());
    if (!guests_.empty()) hint += ".";
    return make_error("platform.remote_play_disconnect: no guest has the session id " + std::to_string(sessionId), hint);
}

Result<void> FakeBackend::set_cloud_clock(long long unixSeconds) {
    if (unixSeconds < 0)
        return make_error("platform.set_fake: cloudClock must be Unix seconds, 0 or more, got " + std::to_string(unixSeconds),
                          "Example: 1767225600 is 2026-01-01T00:00:00Z.");
    cloudClock_ = unixSeconds;
    return {};
}

Result<void> FakeBackend::revoke(const std::string& productId) {
    if (!sink_.alive()) return make_error("platform.revoke: the fake backend is not attached to a running game", "Use it through an Engine.");
    Transaction taken;
    bool found = false;
    if (const auto it = owned_.find(productId); it != owned_.end()) {
        taken = it->second;
        owned_.erase(it);
        found = true;
    }
    for (auto it = unfinished_.begin(); it != unfinished_.end();) {
        if (it->productId != productId) {
            ++it;
            continue;
        }
        if (!found) taken = *it;  // a consumable that was bought and not finished yet
        found = true;
        it = unfinished_.erase(it);
    }
    if (!found) {
        std::vector<std::string> have;
        for (const auto& [pid, t] : owned_) have.push_back(pid);
        const std::string best = did_you_mean(productId, have);
        std::string hint = best;
        if (have.empty()) hint += (hint.empty() ? "" : " ") + std::string("Nothing is owned: buy it first with platform.purchases.buy().");
        else hint += (hint.empty() ? "" : " ") + std::string("Owned: ") + join(have, ", ") + ".";
        return make_error("platform.revoke: " + in_quotes(productId) + " is not owned and has no unfinished purchase", hint);
    }
    sink_.emit("purchase", Json::object({{"status", "revoked"}, {"productId", productId}, {"transactionId", taken.transactionId},
                                         {"receipt", taken.receipt}}));
    return {};
}

// ----------------------------------------------------------------------------------------------------- requests ----
Json* FakeBackend::log_entry(std::uint64_t seq) {
    if (log_.empty()) return nullptr;
    const std::uint64_t first = log_.front()["seq"].get<std::uint64_t>();
    if (seq < first || seq - first >= log_.size()) return nullptr;
    return &log_[seq - first];
}

void FakeBackend::request(std::uint64_t id, const std::string& method, const Json& args, const PlatformSink& sink) {
    sink_ = sink;
    if (none_) {  // the "none" backend: only player.signIn is answered, as signed out
        if (method == "player.signIn") sink.complete(id, player_json(false));
        else sink.fail(id, {"unavailable", "the \"none\" backend answers nothing but player.signIn", {}});
        return;
    }
    const std::uint64_t seq = ++seq_;
    log_.push_back(Json::object({{"seq", seq}, {"frame", frames_}, {"method", method}, {"args", args}, {"answered", false}}));
    if (log_.size() > kMaxLoggedCalls) {
        log_.pop_front();
        ++callsDropped_;
    }
    if (delay_ <= 0) answer(id, seq, method, args);
    else held_.push_back({id, seq, frames_ + static_cast<std::uint64_t>(delay_), method, args});
}

void FakeBackend::frame() {
    ++frames_;
    if (held_.empty()) return;
    std::vector<Held> due;
    for (auto it = held_.begin(); it != held_.end();) {
        if (it->due <= frames_) {
            due.push_back(std::move(*it));
            it = held_.erase(it);
        } else {
            ++it;
        }
    }
    for (const Held& h : due) answer(h.id, h.seq, h.method, h.args);
}

void FakeBackend::answer(std::uint64_t id, std::uint64_t seq, const std::string& method, const Json& args) {
    // A scripted answer for this method goes first.
    Json scripted;
    if (auto it = scripted_.find(method); it != scripted_.end() && !it->second.empty()) {
        scripted = it->second.front().answer;
        if (--it->second.front().times <= 0) it->second.pop_front();
        if (it->second.empty()) scripted_.erase(it);
    }
    auto record = [&](bool ok, const Json& body) {
        if (Json* e = log_entry(seq)) {
            (*e)["answered"] = true;
            (*e)["ok"] = ok;
            (*e)[ok ? "result" : "error"] = body;
            if (!scripted.is_null()) (*e)["scripted"] = true;
        }
    };
    auto reject = [&](PlatformError error) {
        record(false, Json::object({{"code", error.code}, {"message", error.message}, {"hint", error.hint}}));
        sink_.fail(id, std::move(error));
    };

    if (scripted.is_object() && scripted.contains("error")) {
        reject({scripted["error"].get<std::string>(), scripted.value("message", "scripted by the test: platform.respond(" + in_quotes(method) + ", ...)"),
                scripted.value("hint", std::string())});
        return;
    }
    if (method == "http.fetch" && scripted.is_null()) {  // no network in the fake: the test says what the server answers
        reject({"network",
                "the fake backend never reaches the network, and no response is scripted for " + args.value("method", std::string("GET")) + " " +
                    args.value("url", std::string()),
                "Script the answer first: game.platform.respond(\"http.fetch\", { status: 200, json: { ... } }), or { error: \"network\" } for "
                "an offline player."});
        return;
    }
    if (scripted.is_null() && !signedIn_ && method != "player.signIn") {
        reject({"notSignedIn", "the player is not signed in", "Call platform.signIn() first; in a test, game.platform.set({ signedIn: true })."});
        return;
    }

    Outcome o = compute(method, args);
    if (!o.ok) {
        reject(std::move(o.error));
        return;
    }
    Json result = std::move(o.result);
    if (scripted.is_object()) {
        if (scripted.contains("result")) {
            result = scripted["result"];
        } else {
            if (result.is_null()) result = Json::object({{"key", args.value("key", std::string())}});  // cloud.load of a missing key
            for (auto it = scripted.begin(); it != scripted.end(); ++it) result[it.key()] = *it;
        }
        if (method == "http.fetch" && result.is_object()) {
            if (auto j = result.find("json"); j != result.end()) {  // a test's shorthand for a JSON answer
                result["text"] = j->dump();
                result.erase("json");
                if (result.contains("headers") && result["headers"].is_object() && !result["headers"].contains("content-type"))
                    result["headers"]["content-type"] = "application/json";
            }
            if (result.contains("headers") && result["headers"].is_object()) {  // header names come in lower case, as every backend gives them
                Json lowered = Json::object();
                for (auto h = result["headers"].begin(); h != result["headers"].end(); ++h) {
                    std::string name = h.key();
                    for (char& c : name) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
                    lowered[name] = *h;
                }
                result["headers"] = std::move(lowered);
            }
        }
    }
    if (o.commit) o.commit(result);
    record(true, result);
    sink_.complete(id, std::move(result));
}

FakeBackend::Outcome FakeBackend::compute(const std::string& method, const Json& args) {
    Outcome o;
    auto id = [&] { return args.value("id", std::string()); };

    if (method == "player.signIn") {
        o.result = player_json(signedIn_);
    } else if (method == "achievements.unlock") {
        const std::string aid = id();
        const auto it = achievements_.find(aid);
        const bool newly = it == achievements_.end() || !it->second.unlocked;
        o.result = Json::object({{"id", aid}, {"unlocked", true}, {"newly", newly}});
        o.commit = [this, aid](const Json&) { achievements_[aid] = {true, 1.0}; };
    } else if (method == "achievements.progress") {
        const std::string aid = id();
        const auto found = achievements_.find(aid);
        const Achievement prev = found == achievements_.end() ? Achievement{} : found->second;
        const double progress = std::max(prev.progress, args.value("progress", 0.0));
        const bool unlocked = prev.unlocked || progress >= 1.0;
        o.result = Json::object({{"id", aid}, {"progress", progress}, {"unlocked", unlocked}});
        o.commit = [this, aid, progress, unlocked](const Json&) { achievements_[aid] = {unlocked, unlocked ? 1.0 : progress}; };
    } else if (method == "achievements.list") {
        Json list = Json::array();
        for (const Json& a : args["achievements"]) {
            const std::string aid = a.value("id", std::string());
            const auto it = achievements_.find(aid);
            const Achievement st = it == achievements_.end() ? Achievement{} : it->second;
            list.push_back(Json::object({{"id", aid}, {"unlocked", st.unlocked}, {"progress", st.unlocked ? 1.0 : st.progress}}));
        }
        o.result = std::move(list);
    } else if (method == "achievements.reset") {
        o.result = Json::object();
        o.commit = [this](const Json&) { achievements_.clear(); };
    } else if (method == "stats.get") {
        const auto it = stats_.find(id());
        o.result = Json::object({{"id", id()}, {"value", number_json(it == stats_.end() ? 0.0 : it->second, args.value("type", std::string()) == "int")}});
    } else if (method == "stats.set") {
        const std::string sid = id();
        const double v = args.value("value", 0.0);
        o.result = Json::object({{"id", sid}, {"value", args["value"]}});
        o.commit = [this, sid, v](const Json&) { stats_[sid] = v; };
    } else if (method == "leaderboards.submit") {
        const std::string lid = board_key(args);
        const long long score = args.value("score", 0LL);
        const bool lower = args.value("order", std::string()) == "ascending";
        const auto it = bests_.find(lid);
        const long long best = it == bests_.end() ? score : (lower ? std::min(it->second, score) : std::max(it->second, score));
        o.result = Json::object({{"id", lid}, {"score", score}, {"best", best}});
        o.commit = [this, lid, best](const Json&) { bests_[lid] = best; };
    } else if (method == "leaderboards.entries") {
        Json list = Json::array();
        if (const auto it = bests_.find(board_key(args)); it != bests_.end())
            list.push_back(Json::object({{"rank", 1}, {"name", "Player"}, {"score", it->second}, {"playerId", kPlayerId}, {"isPlayer", true}}));
        o.result = std::move(list);
    } else if (method == "cloud.save") {
        const std::string key = args.value("key", std::string()), data = args.value("data", std::string());
        o.result = Json::object({{"key", key}, {"bytes", data.size()}});
        o.commit = [this, key, data](const Json&) {
            cloud_[key] = data;
            cloudModified_[key] = cloudClock_++;  // the save's time; then the clock moves on, so the next save is newer
        };
    } else if (method == "cloud.load") {
        const std::string key = args.value("key", std::string());
        const auto it = cloud_.find(key);
        o.result = it == cloud_.end() ? Json(nullptr) : Json::object({{"key", key}, {"data", it->second}});
    } else if (method == "cloud.list") {
        Json keys = Json::array();
        for (const auto& [key, text] : cloud_) keys.push_back(key);
        o.result = std::move(keys);
    } else if (method == "cloud.stat") {
        const std::string key = args.value("key", std::string());
        const auto it = cloud_.find(key);
        if (it == cloud_.end()) o.result = Json::object({{"exists", false}});
        else o.result = Json::object({{"exists", true}, {"size", it->second.size()}, {"modified", cloudModified_[key]}});
    } else if (method == "cloud.remove") {
        const std::string key = args.value("key", std::string());
        o.result = Json::object();
        o.commit = [this, key](const Json&) {
            cloud_.erase(key);
            cloudModified_.erase(key);
        };
    } else if (method == "remotePlay.sessions") {
        o.result = Json::array();
        for (const Json& g : guests_) o.result.push_back(g);
    } else if (method == "purchases.products") {
        Json list = Json::array();
        for (const Json& p : args["products"]) {
            const double price = p.value("price", 0.0);
            const std::string currency = p.value("currency", std::string("USD"));
            list.push_back(Json::object({{"id", p.value("id", std::string())}, {"title", p.value("title", std::string())},
                                         {"description", p.value("description", std::string())}, {"price", format_price(price, currency)},
                                         {"priceValue", price}, {"currency", currency}, {"type", p.value("type", std::string())}}));
        }
        o.result = std::move(list);
    } else if (method == "purchases.buy") {
        const std::string pid = id(), type = args.value("type", std::string());
        const std::string tx = "fake-" + std::to_string(nextTx_), receipt = "fake-receipt-" + std::to_string(nextTx_);
        o.result = Json::object({{"status", "purchased"}, {"productId", pid}, {"transactionId", tx}, {"receipt", receipt}});
        o.commit = [this, pid, type, tx, receipt](const Json& final) {
            if (final.value("status", std::string()) != "purchased") return;  // a cancelled or pending purchase owns nothing
            Transaction t{final.value("transactionId", tx), final.value("productId", pid), final.value("receipt", receipt)};
            if (t.transactionId == tx) ++nextTx_;  // the number made up for this answer is used
            if (type != "consumable") owned_[pid] = t;
            unfinished_.push_back(std::move(t));
        };
    } else if (method == "purchases.finish") {
        const std::string tx = args.value("transactionId", std::string());
        o.result = Json::object();
        o.commit = [this, tx](const Json&) {
            unfinished_.erase(std::remove_if(unfinished_.begin(), unfinished_.end(), [&](const Transaction& t) { return t.transactionId == tx; }),
                              unfinished_.end());
        };
    } else if (method == "purchases.restore") {
        Json list = Json::array();
        for (const Json& p : args["products"])
            if (const auto it = owned_.find(p.value("id", std::string())); it != owned_.end())
                list.push_back(Json::object({{"productId", it->first}, {"transactionId", it->second.transactionId}, {"receipt", it->second.receipt}}));
        o.result = std::move(list);
    } else if (method == "ads.available") {
        const bool ready = adOutcome_ != "noFill" && adOutcome_ != "consentRefused" && gdpr_ != "denied";
        o.result = Json::object({{"available", ready}});
    } else if (method == "ads.showRewarded") {
        std::string reason;
        if (gdpr_ == "denied" || adOutcome_ == "consentRefused") reason = "consentRefused";
        else if (adOutcome_ == "noFill") reason = "noFill";
        else if (adOutcome_ == "closedEarly") reason = "closedEarly";
        o.result = reason.empty() ? Json::object({{"rewarded", true}}) : Json::object({{"rewarded", false}, {"reason", reason}});
        o.commit = [this, reason](const Json& final) {
            if (reason != "consentRefused" && reason != "noFill") ++adsShown_;  // a test ad was on screen
            if (final.is_object() && final.value("rewarded", false)) ++adsRewarded_;
        };
    } else if (method == "ads.consent") {
        o.result = Json::object({{"gdpr", gdpr_}, {"tracking", tracking_}, {"canShowAds", gdpr_ != "denied"}, {"privacyOptions", privacyOptions_}});
    } else if (method == "ads.setUnderAge") {
        o.result = Json::object();
    } else if (method == "ads.privacyOptions") {
        const bool shown = privacyOptions_ == "required";  // the fake has no form: opening it counts as shown
        o.result = Json::object({{"shown", shown}});
        o.commit = [this](const Json& final) {
            if (final.is_object() && final.value("shown", false)) ++adsPrivacyShown_;
        };
    } else if (method == "http.fetch") {
        o.result = Json::object({{"status", 200}, {"headers", Json::object()}, {"text", ""}});  // merged with what the test scripted
    } else if (method == "overlay.open") {
        o.result = Json::object();
    } else if (method == "presence.set") {
        const Json p = Json::object({{"text", args.value("text", std::string())}, {"data", args.contains("data") ? args["data"] : Json::object()}});
        o.result = Json::object();
        o.commit = [this, p](const Json&) { presence_ = p; };
    } else if (method == "integrity.token") {
        const std::string token = "fake-integrity-" + std::to_string(nextIntegrity_);
        o.result = Json::object({{"token", token}});
        o.commit = [this, token](const Json& final) {
            // The number made up for this answer is used; a scripted token leaves the counter alone.
            if (final.is_object() && final.contains("token") && final.at("token") == token) ++nextIntegrity_;
        };
    } else {
        o.ok = false;
        o.error = {"failed", "the fake backend does not know " + method, "This is an engine bug; report it."};
    }
    return o;
}

// ------------------------------------------------------------------------------------------------------- state ----
Json FakeBackend::state() const {
    Json ach = Json::object(), stats = Json::object(), boards = Json::object(), cloud = Json::object(), scripted = Json::object();
    for (const auto& [id, a] : achievements_) ach[id] = Json::object({{"unlocked", a.unlocked}, {"progress", a.unlocked ? 1.0 : a.progress}});
    for (const auto& [id, v] : stats_) stats[id] = v;
    for (const auto& [id, v] : bests_) boards[id] = v;
    for (const auto& [key, text] : cloud_) cloud[key] = text;
    Json cloudModified = Json::object(), guests = Json::array();
    for (const auto& [key, at] : cloudModified_) cloudModified[key] = at;
    for (const Json& g : guests_) guests.push_back(g);
    for (const auto& [method, queue] : scripted_) {
        int n = 0;
        for (const Scripted& s : queue) n += s.times;
        scripted[method] = n;
    }
    Json owned = Json::array();
    for (const auto& [pid, t] : owned_) owned.push_back(pid);
    Json unfinished = Json::array();
    for (const Transaction& t : unfinished_)
        unfinished.push_back(Json::object({{"transactionId", t.transactionId}, {"productId", t.productId}, {"receipt", t.receipt}}));
    Json calls = Json::array();
    for (const Json& c : log_) calls.push_back(c);
    return Json::object({{"player", player_json(signedIn_)},
                         {"signedIn", signedIn_},
                         {"none", none_},
                         {"delayFrames", delay_},
                         {"frame", frames_},
                         {"achievements", ach},
                         {"stats", stats},
                         {"leaderboards", boards},
                         {"cloud", cloud},
                         {"cloudModified", cloudModified},
                         {"cloudClock", cloudClock_},
                         {"remotePlay", guests},
                         {"owned", owned},
                         {"unfinished", unfinished},
                         {"presence", presence_},
                         {"ads", Json::object({{"outcome", adOutcome_}, {"gdpr", gdpr_}, {"tracking", tracking_}, {"privacyOptions", privacyOptions_}, {"privacyShown", adsPrivacyShown_}, {"shown", adsShown_},
                                               {"rewarded", adsRewarded_}})},
                         {"scripted", scripted},
                         {"held", held_.size()},
                         {"calls", calls},
                         {"callsDropped", callsDropped_}});
}

}  // namespace fa
