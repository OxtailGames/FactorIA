// PlatformServices: the request dispatcher between the game and a platform backend (fa/services/platform.h).
#include "fa/services/platform.h"

#include <algorithm>
#include <cmath>
#include <mutex>
#include <set>
#include <thread>
#include <utility>

#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "fa/core/utf8.h"
#include "fa/services/fake_platform.h"

namespace fa {

// ------------------------------------------------------------------------------------------------------ tables ----
const std::vector<std::string>& platform_services_all() {
    static const std::vector<std::string> v = {"achievements", "stats", "leaderboards", "cloudSave", "purchases", "overlay", "presence", "integrity"};
    return v;
}

const std::vector<std::string>& platform_events() {
    static const std::vector<std::string> v = {"purchase", "overlay", "player"};
    return v;
}

const std::vector<std::string>& platform_error_codes() {
    static const std::vector<std::string> v = {"unavailable", "notSignedIn", "notAllowed", "unknownId", "network", "failed"};
    return v;
}

const std::vector<PlatformMethodInfo>& platform_methods() {
    static const std::vector<PlatformMethodInfo> v = {
        {"player.signIn", "", "Sign the player in (or read who is signed in)."},
        {"achievements.unlock", "achievements", "Unlock one achievement."},
        {"achievements.progress", "achievements", "Report progress (0..1) toward an achievement; 1 or more unlocks it."},
        {"achievements.list", "achievements", "Read the state of every achievement of the catalog."},
        {"achievements.reset", "achievements", "Development only: lock every achievement again."},
        {"stats.get", "stats", "Read one stat."},
        {"stats.set", "stats", "Set one stat."},
        {"leaderboards.submit", "leaderboards", "Submit a score to a leaderboard."},
        {"leaderboards.entries", "leaderboards", "Read the top, the neighbours of the player, or the friends' entries."},
        {"cloud.save", "cloudSave", "Store a text under a key in the player's cloud."},
        {"cloud.load", "cloudSave", "Read the text stored under a key."},
        {"cloud.list", "cloudSave", "List the keys stored in the player's cloud."},
        {"cloud.remove", "cloudSave", "Delete a key from the player's cloud."},
        {"purchases.products", "purchases", "Read the store's titles and prices of products."},
        {"purchases.buy", "purchases", "Start the purchase of a product."},
        {"purchases.finish", "purchases", "Tell the store the game delivered what a purchase paid for."},
        {"purchases.restore", "purchases", "List the non-consumables and subscriptions the player owns."},
        {"overlay.open", "overlay", "Open a page of the store's overlay."},
        {"presence.set", "presence", "Set the rich presence text friends see."},
        {"integrity.token", "integrity",
         "Get a signed token that says this is the genuine app on a genuine device, for the game's own server to verify (args: challenge, "
         "the server's nonce; result: token)."},
    };
    return v;
}

const PlatformMethodInfo* find_platform_method(const std::string& name) {
    for (const PlatformMethodInfo& m : platform_methods())
        if (m.name == name) return &m;
    return nullptr;
}

namespace {

std::string in_quotes(const std::string& s) { return Json(s).dump(); }

bool contains(const std::vector<std::string>& v, const std::string& s) { return std::find(v.begin(), v.end(), s) != v.end(); }

bool valid_cloud_key(const std::string& s) {
    if (s.empty() || s.size() > 64) return false;
    return std::all_of(s.begin(), s.end(), [](unsigned char c) { return std::isalnum(c) || c == '_' || c == '.' || c == '-'; });
}

Json unknown_player() { return Json::object({{"id", ""}, {"name", ""}, {"signedIn", false}}); }

// The characters of integrity.token's challenge: URL-safe Base64 (A-Z a-z 0-9 - _ =).
bool challenge_char(unsigned char c) {
    return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '-' || c == '_' || c == '=';
}

// The character at byte `i` of `s` for a message: ASCII is quoted ("+", " ", "\n"), anything else is named only, so that
// the message is valid UTF-8 whatever bytes the string holds. `position` counts characters from 1.
std::string describe_char(const std::string& s, std::size_t i, std::size_t& position) {
    position = 1 + utf8_length(std::string_view(s).substr(0, i));
    const unsigned char c = static_cast<unsigned char>(s[i]);
    return c < 0x80 ? in_quotes(std::string(1, static_cast<char>(c))) : "a non-ASCII character";
}

// ---------------------------------------------------------------------------------------------- preparing requests --
// A programmer's mistake found before the request leaves the game. Thrown by the helpers below and caught in start();
// it never crosses the module.
struct Bad {
    std::string message, hint;
};

const Json& need(const Json& args, const char* key, const char* what) {
    auto it = args.find(key);
    if (it == args.end() || it->is_null()) throw Bad{std::string("the argument \"") + key + "\" is missing (" + what + ")", {}};
    return *it;
}

const std::string& need_string(const Json& args, const char* key, const char* what) {
    const Json& v = need(args, key, what);
    if (!v.is_string()) throw Bad{std::string("\"") + key + "\" must be a string (" + what + "), got " + describe_json_value(v), {}};
    return v.get_ref<const std::string&>();
}

double need_number(const Json& args, const char* key, const char* what) {
    const Json& v = need(args, key, what);
    if (!v.is_number() || !std::isfinite(v.get<double>()))
        throw Bad{std::string("\"") + key + "\" must be a finite number (" + what + "), got " + describe_json_value(v), {}};
    return v.get<double>();
}

bool is_whole(double v) { return std::floor(v) == v && std::fabs(v) < 9e15; }

template <class T>
std::vector<std::string> ids_of(const std::vector<T>& v) {
    std::vector<std::string> out;
    for (const T& e : v) out.push_back(e.id);
    return out;
}

// The catalog entry `id` of one section, or the teaching error. `phrase`: "an achievement", `section`: "achievements".
template <class T>
const T& lookup(const std::vector<T>& entries, const std::string& id, const char* phrase, const char* section, const char* example) {
    for (const T& e : entries)
        if (e.id == id) return e;
    const std::vector<std::string> ids = ids_of(entries);
    const std::string best = closest_match(id, ids);
    std::string message = in_quotes(id) + " is not " + phrase + " of this game";
    if (ids.empty()) message += ": the game declares none";
    if (!best.empty()) message += " (did you mean " + in_quotes(best) + "?)";
    message += "; declare it in factoria.json platform." + std::string(section);
    std::string hint;
    if (ids.empty()) {
        hint = std::string("Add it to factoria.json, e.g. \"platform\": {\"") + section + "\": [" + example + "]}.";
    } else {
        hint = std::string("The game's ") + section + ":";
        for (std::size_t i = 0; i < ids.size() && i < 12; ++i) hint += (i ? ", " : " ") + in_quotes(ids[i]);
        if (ids.size() > 12) hint += ", ... (" + std::to_string(ids.size() - 12) + " more)";
        hint += ".";
    }
    throw Bad{std::move(message), std::move(hint)};
}

struct PrepareContext {
    const PlatformCatalog& catalog;
    const std::string& backend;
    const std::map<std::string, std::string>& transactions;  // transactionId -> product id
};

Json id_pair(const PlatformEntry& e, const std::string& backend) { return Json::object({{"id", e.id}, {"storeId", e.store_id(backend)}}); }

template <class T>
Json id_pairs(const std::vector<T>& entries, const std::string& backend) {
    Json a = Json::array();
    for (const T& e : entries) a.push_back(id_pair(e, backend));
    return a;
}

Json product_args(const PlatformProduct& p, const std::string& backend, bool withCatalogData) {
    Json j = id_pair(p, backend);
    j["type"] = p.type;
    if (withCatalogData) {  // for backends that have no store to ask (the fake); real stores answer with their own
        j["title"] = p.title;
        j["description"] = p.description;
        j["price"] = p.price;
        j["currency"] = p.currency;
    }
    return j;
}

const char* kAchievementExample = "{\"id\": \"first_win\", \"name\": \"First win\"}";

// The arguments a backend receives for `method` (the table of docs/PLATFORM.md), from the ones the script gave.
Json prepare(const std::string& method, const Json& in, const PrepareContext& c) {
    const PlatformCatalog& cat = c.catalog;
    const std::string& be = c.backend;
    if (!in.is_object()) throw Bad{"the arguments must be an object, got " + describe_json_value(in), {}};

    if (method == "player.signIn") return Json::object();

    if (method == "achievements.unlock" || method == "achievements.progress") {
        const auto& a = lookup(cat.achievements, need_string(in, "id", "the id of an achievement"), "an achievement", "achievements",
                               kAchievementExample);
        Json out = id_pair(a, be);
        if (method == "achievements.progress") {
            const double p = need_number(in, "progress", "a fraction from 0 to 1");
            if (p < 0.0 || p > 1.0)
                throw Bad{"\"progress\" must be a fraction from 0 to 1, got " + describe_json_value(in["progress"]),
                          "Report 0.5 for half way; 1 unlocks the achievement."};
            out["progress"] = p;
        }
        return out;
    }
    if (method == "achievements.list" || method == "achievements.reset")
        return Json::object({{"achievements", id_pairs(cat.achievements, be)}});

    if (method == "stats.get" || method == "stats.set") {
        const auto& s = lookup(cat.stats, need_string(in, "id", "the id of a stat"), "a stat", "stats", "{\"id\": \"wins\", \"type\": \"int\"}");
        Json out = id_pair(s, be);
        out["type"] = s.type;
        if (method == "stats.set") {
            const double v = need_number(in, "value", "the new value of the stat");
            if (s.type == "int") {
                if (!is_whole(v))
                    throw Bad{"the stat " + in_quotes(s.id) + " is an int: \"value\" must be a whole number, got " + describe_json_value(in["value"]),
                              "Declare it with \"type\": \"float\" in factoria.json platform.stats to keep fractions."};
                out["value"] = static_cast<long long>(v);
            } else {
                out["value"] = v;
            }
        }
        return out;
    }

    if (method == "leaderboards.submit" || method == "leaderboards.entries") {
        const auto& l = lookup(cat.leaderboards, need_string(in, "id", "the id of a leaderboard"), "a leaderboard", "leaderboards",
                               "{\"id\": \"high_score\", \"name\": \"High score\"}");
        Json out = id_pair(l, be);
        out["order"] = l.order;
        if (method == "leaderboards.submit") {
            const double score = need_number(in, "score", "the score to submit");
            if (!is_whole(score))
                throw Bad{"\"score\" must be a whole number, got " + describe_json_value(in["score"]),
                          "Stores keep integer scores: submit a time in milliseconds (1234) instead of seconds (1.234)."};
            out["score"] = static_cast<long long>(score);
        } else {
            std::string range = "top";
            if (auto it = in.find("range"); it != in.end() && !it->is_null()) {
                const std::vector<std::string> ranges = {"top", "around", "friends"};
                if (!it->is_string() || !contains(ranges, it->get<std::string>())) {
                    const std::string best = it->is_string() ? closest_match(it->get<std::string>(), ranges) : std::string();
                    throw Bad{"\"range\" must be one of \"top\", \"around\", \"friends\", got " + describe_json_value(*it) +
                                  (best.empty() ? std::string() : " (did you mean " + in_quotes(best) + "?)"),
                              "\"top\" is the best entries, \"around\" the ones next to the player, \"friends\" the player's friends."};
                }
                range = it->get<std::string>();
            }
            double count = 10;
            if (auto it = in.find("count"); it != in.end() && !it->is_null()) count = need_number(in, "count", "how many entries");
            if (!is_whole(count) || count < 1 || count > 100)
                throw Bad{"\"count\" must be a whole number from 1 to 100, got " + describe_json_value(in["count"]),
                          "Ask for a page of entries, e.g. { count: 10 }."};
            out["range"] = range;
            out["count"] = static_cast<long long>(count);
        }
        return out;
    }

    if (method.rfind("cloud.", 0) == 0) {
        if (method == "cloud.list") return Json::object();
        const std::string& key = need_string(in, "key", "the name of the saved data");
        if (!valid_cloud_key(key))
            throw Bad{"the cloud key " + in_quotes(key) + " is not valid; use 1-64 letters, digits, '_', '.' or '-'",
                      "Example: platform.cloud.save(\"slot1\", data)."};
        Json out = Json::object({{"key", key}});
        if (method == "cloud.save") out["data"] = need_string(in, "data", "the saved value as JSON text");
        return out;
    }

    if (method == "purchases.products") {
        Json list = Json::array();
        if (auto it = in.find("ids"); it != in.end() && !it->is_null()) {
            if (!it->is_array()) throw Bad{"\"ids\" must be an array of product ids, got " + describe_json_value(*it), {}};
            for (const Json& id : *it) {
                if (!id.is_string()) throw Bad{"\"ids\" must hold product ids (strings), got " + describe_json_value(id), {}};
                list.push_back(product_args(lookup(cat.products, id.get<std::string>(), "a product", "products", "{\"id\": \"gems_100\", \"type\": \"consumable\", \"title\": \"100 gems\"}"), be, true));
            }
        } else {
            for (const PlatformProduct& p : cat.products) list.push_back(product_args(p, be, true));
        }
        return Json::object({{"products", list}});
    }
    if (method == "purchases.restore") {
        Json list = Json::array();
        for (const PlatformProduct& p : cat.products) list.push_back(product_args(p, be, false));
        return Json::object({{"products", list}});
    }
    if (method == "purchases.buy") {
        const auto& p = lookup(cat.products, need_string(in, "id", "the id of a product"), "a product", "products",
                               "{\"id\": \"gems_100\", \"type\": \"consumable\", \"title\": \"100 gems\"}");
        return product_args(p, be, false);
    }
    if (method == "purchases.finish") {
        const std::string& tx = need_string(in, "transactionId", "the transactionId of a purchase result or event");
        auto it = c.transactions.find(tx);
        if (it == c.transactions.end())
            throw Bad{"the transaction " + in_quotes(tx) + " is not one this game was told about",
                      "Pass the transactionId of a purchases.buy() result, a platform.on(\"purchase\") event or a restore() entry, and finish "
                      "each transaction once."};
        const PlatformProduct* p = cat.find_product(it->second);
        Json out = p ? product_args(*p, be, false) : Json::object({{"id", it->second}, {"storeId", it->second}, {"type", "consumable"}});
        out["transactionId"] = tx;
        return out;
    }

    if (method == "overlay.open") {
        const std::string& page = need_string(in, "page", "\"achievements\", \"leaderboards\", \"friends\" or \"store\"");
        const std::vector<std::string> pages = {"achievements", "leaderboards", "friends", "store"};
        if (!contains(pages, page)) {
            const std::string best = closest_match(page, pages);
            throw Bad{in_quotes(page) + " is not an overlay page; use \"achievements\", \"leaderboards\", \"friends\" or \"store\"" +
                          (best.empty() ? std::string() : " (did you mean " + in_quotes(best) + "?)"),
                      "Example: platform.overlay.open(\"achievements\")."};
        }
        Json out = Json::object({{"page", page}});
        if (auto it = in.find("id"); it != in.end() && !it->is_null()) {
            if (!it->is_string()) throw Bad{"\"id\" must be a string, got " + describe_json_value(*it), {}};
            const std::string& id = it->get_ref<const std::string&>();
            if (page == "friends") throw Bad{"the \"friends\" page takes no id", "Call platform.overlay.open(\"friends\")."};
            if (page == "achievements") out.update(id_pair(lookup(cat.achievements, id, "an achievement", "achievements", kAchievementExample), be));
            else if (page == "leaderboards")
                out.update(id_pair(lookup(cat.leaderboards, id, "a leaderboard", "leaderboards", "{\"id\": \"high_score\", \"name\": \"High score\"}"), be));
            else
                out.update(id_pair(lookup(cat.products, id, "a product", "products", "{\"id\": \"gems_100\", \"type\": \"consumable\", \"title\": \"100 gems\"}"), be));
        }
        return out;
    }

    if (method == "presence.set") {
        const std::string& text = need_string(in, "text", "the text friends see; \"\" clears it");
        Json data = Json::object();
        if (auto it = in.find("data"); it != in.end() && !it->is_null()) {
            if (!it->is_object()) throw Bad{"\"data\" must be an object of string values, got " + describe_json_value(*it), {}};
            for (auto di = it->begin(); di != it->end(); ++di)
                if (!di->is_string())
                    throw Bad{"presence data values must be strings; " + in_quotes(di.key()) + " is " + describe_json_value(*di),
                              "Write numbers as text: { score: String(score) }."};
            data = *it;
        }
        return Json::object({{"text", text}, {"data", data}});
    }

    if (method == "integrity.token") {
        const std::string hint =
            "Make the challenge on your server: 16 or more random bytes as URL-safe Base64 (a nonce), send it to the game, and check it "
            "inside the decoded token; a token without a fresh challenge can be replayed.";
        const auto it = in.find("challenge");
        if (it == in.end() || it->is_null())
            throw Bad{"the argument \"challenge\" is missing (a nonce from your server, 16 to 500 characters of URL-safe Base64)", hint};
        if (!it->is_string())
            throw Bad{"\"challenge\" must be a string (a nonce from your server, 16 to 500 characters of URL-safe Base64), got " + describe_json_value(*it), hint};
        const std::string& challenge = it->get_ref<const std::string&>();
        for (std::size_t i = 0; i < challenge.size(); ++i) {
            if (challenge_char(static_cast<unsigned char>(challenge[i]))) continue;
            std::size_t position = 0;
            const std::string what = describe_char(challenge, i, position);
            throw Bad{"the challenge has " + (what[0] == '"' ? "the character " : std::string()) + what + " at position " + std::to_string(position) +
                          "; only A-Z a-z 0-9 - _ = are allowed (URL-safe Base64)",
                      hint + (challenge[i] == '+' || challenge[i] == '/'
                                  ? " Standard Base64 writes + and /; URL-safe Base64 writes - and _ instead."
                                  : std::string())};
        }
        if (challenge.size() < 16 || challenge.size() > 500)
            throw Bad{"the challenge is too " + std::string(challenge.size() < 16 ? "short" : "long") + ": " + std::to_string(challenge.size()) +
                          " characters, it needs 16 to 500",
                      hint};
        return Json::object({{"challenge", challenge}});
    }

    throw Bad{"no preparation for " + method, "This is an engine bug; report it."};
}

}  // namespace

// ------------------------------------------------------------------------------------------------------- state ----
struct PlatformSink::State {
    std::mutex mutex;  // guards everything below: backends answer from any thread
    std::uint64_t generation = 1;  // of the current backend: a replaced backend's sink does nothing
    std::uint64_t nextId = 1;
    PlatformCatalog catalog;
    std::string backendName = "none";
    std::vector<std::string> services;

    struct Pending {
        std::string method;
        Json args;  // as the backend got them
    };
    std::map<std::uint64_t, Pending> pending;
    std::vector<PlatformAnswer> answers;
    std::vector<PlatformEvent> events;
    Json player = unknown_player();
    std::map<std::string, std::string> transactions;  // transactionId -> catalog product id, until finished

    // The request start() is handing to the backend: an answer given on this thread, inside request(), is returned by
    // start() instead of being queued.
    std::uint64_t startingId = 0;
    std::thread::id startingThread;
    std::optional<PlatformAnswer> syncAnswer;

    bool warnedLate = false;
    std::set<std::string> warnedEvents;

    // The catalog id of a product as a backend wrote it: a store id, or already the catalog id.
    std::string product_id_from(const std::string& v) const {
        if (catalog.find_product(v)) return v;
        for (const PlatformProduct& p : catalog.products)
            if (p.store_id(backendName) == v) return p.id;
        return v;
    }

    // `productId` of a purchase result, event or restore entry is the catalog id; `fallback` is the product asked for.
    void fix_purchase(Json& o, const std::string& fallback) const {
        if (!o.is_object()) return;
        std::string pid = fallback;
        for (const char* key : {"productId", "id", "storeId"})
            if (auto it = o.find(key); it != o.end() && it->is_string() && !it->get<std::string>().empty()) {
                pid = it->get<std::string>();
                break;
            }
        if (pid.empty()) return;
        o["productId"] = product_id_from(pid);
        o.erase("id");  // the store's name for the product: the game gets the catalog's, as productId
        o.erase("storeId");
    }

    void remember(const Json& o) {
        if (!o.is_object()) return;
        auto tx = o.find("transactionId");
        if (tx == o.end() || !tx->is_string() || tx->get<std::string>().empty()) return;
        transactions[tx->get<std::string>()] = o.value("productId", std::string());
    }

    void fix_result(const Pending& p, Json& result) {
        const std::string& m = p.method;
        if (m == "player.signIn") {
            if (result.is_object()) merge_player(result);
        } else if (m == "achievements.list" || m == "purchases.products") {
            if (!result.is_array()) return;
            for (Json& e : result) {
                if (!e.is_object() || e.contains("id") || !e.contains("storeId") || !e["storeId"].is_string()) continue;
                const std::string store = e["storeId"].get<std::string>();
                e["id"] = m == "purchases.products" ? product_id_from(store) : store_to_achievement(store);
            }
        } else if (m == "purchases.buy") {
            fix_purchase(result, p.args.value("id", std::string()));
            if (result.is_object() && result.value("status", std::string()) == "purchased") remember(result);
        } else if (m == "purchases.restore") {
            if (!result.is_array()) return;
            for (Json& e : result) {
                fix_purchase(e, std::string());
                remember(e);
            }
        } else if (m == "purchases.finish") {
            transactions.erase(p.args.value("transactionId", std::string()));
        }
    }

    std::string store_to_achievement(const std::string& store) const {
        for (const PlatformAchievement& a : catalog.achievements)
            if (a.store_id(backendName) == store) return a.id;
        return store;
    }

    void merge_player(const Json& from) {
        for (const char* key : {"id", "name", "signedIn"})
            if (auto it = from.find(key); it != from.end()) player[key] = *it;
    }

    void complete(std::uint64_t gen, std::uint64_t id, bool ok, Json result, PlatformError error) {
        std::lock_guard<std::mutex> lock(mutex);
        if (gen != generation) return;
        auto it = pending.find(id);
        if (it == pending.end()) {  // answered twice, or nobody asked
            if (!warnedLate) {
                warnedLate = true;
                FA_WARN("platform", "backend '{}' answered request {} which is not pending (answered twice, or not asked): ignored", backendName, id);
            }
            return;
        }
        Pending p = std::move(it->second);
        pending.erase(it);
        // A game sends this answer to its server: one without a token is a failure here, not something to forward.
        if (ok && p.method == "integrity.token" && !(result.is_object() && result.contains("token") && result["token"].is_string())) {
            ok = false;
            error = {"failed", "the " + in_quotes(backendName) + " backend answered integrity.token without a string \"token\": got " + describe_json_value(result),
                     "This is a bug in the backend; the answer must be {\"token\": \"<string>\"}."};
        }
        PlatformAnswer a;
        a.id = id;
        a.method = p.method;
        a.ok = ok;
        if (ok) {
            fix_result(p, result);
            a.result = std::move(result);
        } else {
            if (!contains(platform_error_codes(), error.code)) {
                error.message += (error.message.empty() ? "" : " ") + std::string("(the backend used the error code ") + in_quotes(error.code) +
                                 ", which is not one of: " + join(platform_error_codes(), ", ") + ")";
                error.code = "failed";
            }
            if (error.message.empty()) error.message = "the " + in_quotes(backendName) + " backend reported a failure without a message";
            a.error = std::move(error);
        }
        if (id == startingId && std::this_thread::get_id() == startingThread) {
            syncAnswer = std::move(a);
            return;
        }
        answers.push_back(std::move(a));
    }

    void emit(std::uint64_t gen, const std::string& event, Json data) {
        std::lock_guard<std::mutex> lock(mutex);
        if (gen != generation) return;
        if (!contains(platform_events(), event)) {
            if (warnedEvents.insert(event).second)
                FA_WARN("platform", "backend '{}' sent the event {} which games do not get (events: {}): dropped", backendName, in_quotes(event),
                        join(platform_events(), ", "));
            return;
        }
        if (event == "purchase" && data.is_object()) {
            fix_purchase(data, std::string());
            if (data.value("status", std::string()) == "purchased") remember(data);
        } else if (event == "player" && data.is_object()) {
            merge_player(data);
        }
        events.push_back({event, std::move(data)});
    }
};

// -------------------------------------------------------------------------------------------------------- sink ----
void PlatformSink::complete(std::uint64_t id, Json result) const {
    if (auto s = state_.lock()) s->complete(generation_, id, true, std::move(result), {});
}
void PlatformSink::fail(std::uint64_t id, PlatformError error) const {
    if (auto s = state_.lock()) s->complete(generation_, id, false, Json(), std::move(error));
}
void PlatformSink::emit(const std::string& event, Json data) const {
    if (auto s = state_.lock()) s->emit(generation_, event, std::move(data));
}
bool PlatformSink::alive() const {
    auto s = state_.lock();
    if (!s) return false;
    std::lock_guard<std::mutex> lock(s->mutex);
    return s->generation == generation_;
}

// ---------------------------------------------------------------------------------------------------- "none" ----
namespace {

class NoneBackend final : public PlatformBackend {
public:
    std::string name() const override { return "none"; }
    std::vector<std::string> services() const override { return {}; }
    void request(std::uint64_t id, const std::string& method, const Json&, const PlatformSink& sink) override {
        if (method == "player.signIn") sink.complete(id, unknown_player());
        else sink.fail(id, {"unavailable", "the \"none\" backend answers nothing but player.signIn", {}});
    }
};

}  // namespace

std::unique_ptr<PlatformBackend> make_none_backend() { return std::make_unique<NoneBackend>(); }

// ----------------------------------------------------------------------------------------------- the dispatcher --
PlatformServices::PlatformServices() : state_(std::make_shared<PlatformSink::State>()), backend_(make_none_backend()) {
    backend_->attach(sink());
}

PlatformServices::~PlatformServices() {
    // Sinks held by plugins and backends outlive this object: they must find it gone.
    std::lock_guard<std::mutex> lock(state_->mutex);
    ++state_->generation;
    state_->pending.clear();
}

void PlatformServices::set_catalog(PlatformCatalog catalog) {
    std::lock_guard<std::mutex> lock(state_->mutex);
    state_->catalog = std::move(catalog);
}

const PlatformCatalog& PlatformServices::catalog() const { return state_->catalog; }

void PlatformServices::set_backend(std::unique_ptr<PlatformBackend> backend, std::string why) {
    if (!backend) backend = make_none_backend();
    {
        std::lock_guard<std::mutex> lock(state_->mutex);
        ++state_->generation;
        state_->pending.clear();
        state_->answers.clear();
        state_->transactions.clear();
        state_->backendName = backend->name();
        state_->services = backend->services();
    }
    backend_ = std::move(backend);
    why_ = std::move(why);
    backend_->attach(sink());
}

PlatformBackend& PlatformServices::backend() const { return *backend_; }

FakeBackend* PlatformServices::fake() const { return dynamic_cast<FakeBackend*>(backend_.get()); }

bool PlatformServices::has_service(const std::string& service) const {
    std::lock_guard<std::mutex> lock(state_->mutex);
    return contains(state_->services, service);
}

PlatformSink PlatformServices::sink() const {
    std::lock_guard<std::mutex> lock(state_->mutex);
    return PlatformSink(state_, state_->generation);
}

Result<PlatformServices::StartInfo> PlatformServices::start(const std::string& method, const Json& args) {
    PlatformSink::State& s = *state_;
    const PlatformMethodInfo* info = find_platform_method(method);
    if (!info) {
        std::vector<std::string> names;
        for (const PlatformMethodInfo& m : platform_methods()) names.push_back(m.name);
        return make_error("unknown platform method " + in_quotes(method), did_you_mean(method, names));
    }

    StartInfo out;
    Json prepared;
    std::string backendName;
    bool offered = true;
    {
        std::lock_guard<std::mutex> lock(s.mutex);
        backendName = s.backendName;
        try {
            prepared = prepare(method, args, {s.catalog, s.backendName, s.transactions});
        } catch (const Bad& b) {
            return make_error(b.message, b.hint);
        }
        out.id = s.nextId++;
        offered = info->service.empty() || contains(s.services, info->service);
        if (offered) {
            s.pending[out.id] = {method, prepared};
            s.startingId = out.id;
            s.startingThread = std::this_thread::get_id();
            s.syncAnswer.reset();
        }
    }
    if (!offered) {
        PlatformAnswer a;
        a.id = out.id;
        a.method = method;
        a.ok = false;
        a.error.code = "unavailable";
        a.error.message = "platform." + method + " is not available: the " + in_quotes(backendName) + " backend does not offer the " +
                          in_quotes(info->service) + " service";
        a.error.hint = "Check platform.has(" + in_quotes(info->service) + ") before calling it. " +
                       (backendName == "none" ? "This game has no store backend here (exported games get one from a plugin; headless runs "
                                                "and tests use the fake backend): docs/PLATFORM.md."
                                              : "See the backend table in docs/PLATFORM.md.");
        out.answer = std::move(a);
        return out;
    }

    const PlatformSink handle = sink();
    try {
        backend_->request(out.id, method, prepared, handle);
    } catch (const std::exception& e) {  // a backend must not throw; the game still gets an answer
        handle.fail(out.id, {"failed", std::string("the ") + in_quotes(backendName) + " backend threw while handling " + method + ": " + e.what(), {}});
    }
    {
        std::lock_guard<std::mutex> lock(s.mutex);
        s.startingId = 0;
        out.answer = std::move(s.syncAnswer);
        s.syncAnswer.reset();
    }
    return out;
}

void PlatformServices::frame() { backend_->frame(); }

std::vector<PlatformAnswer> PlatformServices::take_answers() {
    std::lock_guard<std::mutex> lock(state_->mutex);
    return std::exchange(state_->answers, {});
}

std::vector<PlatformEvent> PlatformServices::take_events() {
    std::lock_guard<std::mutex> lock(state_->mutex);
    return std::exchange(state_->events, {});
}

Json PlatformServices::player() const {
    std::lock_guard<std::mutex> lock(state_->mutex);
    return state_->player;
}

std::size_t PlatformServices::pending() const {
    std::lock_guard<std::mutex> lock(state_->mutex);
    return state_->pending.size();
}

Json PlatformServices::info() const {
    std::lock_guard<std::mutex> lock(state_->mutex);
    Json services = Json::array();
    for (const std::string& s : state_->services) services.push_back(s);
    return Json::object({{"backend", state_->backendName}, {"services", services}, {"player", state_->player}, {"pending", state_->pending.size()}});
}

void PlatformServices::reset_session() {
    {
        std::lock_guard<std::mutex> lock(state_->mutex);
        state_->pending.clear();
        state_->answers.clear();
        state_->events.clear();
        state_->transactions.clear();
        state_->player = unknown_player();
    }
    if (FakeBackend* f = fake()) f->reset();
}

}  // namespace fa
