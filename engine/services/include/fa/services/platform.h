// Platform services: achievements, stats, leaderboards, cloud saves, purchases, the store overlay and rich presence behind
// ONE request interface that every store backend implements (docs/PLATFORM.md). The scripts' `platform` object, the
// `platform.*` commands and the native-plugin ABI v2 (fa_plugin.h) are all views of this module.
//
//   script:  platform.purchases.buy("gems_100")
//     PlatformServices::start(method, args)    checks ids and arguments against the catalog (factoria.json "platform"),
//          |                                   adds the store ids, counts the request; a mistake is an Error right here
//          v
//     PlatformBackend::request(id, method, args, sink)       the fake, "none", or a store plugin (fa_runtime)
//          |
//          v  sink.complete / sink.fail / sink.emit          now (same thread) or later (any thread)
//     PlatformServices::take_answers / take_events           on the game thread, once per frame (the script layer)
//
// A request is (method, args) -> ONE answer: a result (JSON) or an error {code, message, hint}. The methods, their
// arguments and results are listed in platform_methods() and in docs/PLATFORM.md; the arguments a backend receives
// are exactly the ones in that table (ids already checked, `storeId` filled in).
#pragma once

#include <cstdint>
#include <map>
#include <memory>
#include <optional>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

// ------------------------------------------------------------------------------------------------------- catalog --
// The "platform" section of factoria.json: what the game declares, so that ids are checked before a request leaves the
// game and each store gets its own id for the same achievement, stat, leaderboard or product.

struct PlatformEntry {
    std::string id;                          // the id scripts use: [A-Za-z0-9_.-]{1,64}, unique within its section
    std::map<std::string, std::string> ids;  // backend name -> the id that store uses ("steam": "ACH_WIN_ONE_GAME")
    // The id `backend` uses: its entry in `ids`, else `id`.
    const std::string& store_id(const std::string& backend) const;
};

struct PlatformAchievement : PlatformEntry {
    std::string name, description;
    bool hidden = false;
};
struct PlatformStat : PlatformEntry {
    std::string type = "int";  // "int" | "float"
};
struct PlatformLeaderboard : PlatformEntry {
    std::string name;
    std::string order = "descending";  // "descending": higher is better; "ascending": lower is better (times)
};
struct PlatformProduct : PlatformEntry {
    std::string type;  // "consumable" | "nonConsumable" | "subscription"
    std::string title, description;
    double price = 0.0;  // only the fake backend uses it: real stores give their own
    std::string currency = "USD";
};

struct PlatformCatalog {
    std::vector<PlatformAchievement> achievements;
    std::vector<PlatformStat> stats;
    std::vector<PlatformLeaderboard> leaderboards;
    std::vector<PlatformProduct> products;

    // "backend": the plugin to use. `backend` is the plain string ("" = auto), `backendByPlatform` the per-platform
    // object ({"windows": "steam", "ios": "apple"}); the plugin names written in either are in `backendRefs` with their
    // JSON pointer, for the checks that need the project's plugins (`factoria validate`).
    std::string backend;
    std::map<std::string, std::string> backendByPlatform;
    struct BackendRef {
        std::string pointer, name;
    };
    std::vector<BackendRef> backendRefs;

    // The backend the file asks for on `platform` ("windows", "macos", ...): its entry, else the plain string; "" = auto.
    std::string backend_for(const std::string& platform) const;

    const PlatformAchievement* find_achievement(const std::string& id) const;
    const PlatformStat* find_stat(const std::string& id) const;
    const PlatformLeaderboard* find_leaderboard(const std::string& id) const;
    const PlatformProduct* find_product(const std::string& id) const;
    bool empty() const { return achievements.empty() && stats.empty() && leaderboards.empty() && products.empty(); }
    // {achievements: [id], stats: [id], leaderboards: [id], products: [id]}
    Json ids_json() const;
};

// One problem of the section. `pointer` is a JSON pointer into factoria.json ("/platform/products/1/type").
struct PlatformIssue {
    std::string pointer, message, hint;
    bool warning = false;  // unknown keys and the like: the catalog is still usable
    // "factoria.json#<pointer>: <message>" with the hint.
    Error to_error() const;
};

struct PlatformCatalogParse {
    PlatformCatalog catalog;  // everything that parsed; entries with an error are left out
    std::vector<PlatformIssue> issues;
    bool ok() const;  // no issue that is not a warning
};

// Parses the value of factoria.json "platform" (null / absent = an empty catalog). Reports EVERY problem, each with the
// field, what is wrong and how to fix it ("did you mean" for names). `factoria validate` uses this; the engine uses
// load_platform_catalog, which refuses a section with errors.
PlatformCatalogParse parse_platform_catalog(const Json& section);
// The catalog, or the first error.
Result<PlatformCatalog> load_platform_catalog(const Json& section);

// ------------------------------------------------------------------------------------------------------ protocol --

inline constexpr const char* kPlatformKey = "platform";  // the section of factoria.json

// The seven services a backend may offer: "achievements", "stats", "leaderboards", "cloudSave", "purchases", "overlay",
// "presence". `player.signIn` belongs to none: every backend answers it.
const std::vector<std::string>& platform_services_all();
// The events a backend sends: "purchase", "overlay", "player".
const std::vector<std::string>& platform_events();
// The only error codes: "unavailable", "notSignedIn", "notAllowed", "unknownId", "network", "failed".
const std::vector<std::string>& platform_error_codes();

struct PlatformMethodInfo {
    std::string name;     // "purchases.buy"
    std::string service;  // "purchases"; "" for player.signIn
    std::string summary;
};
// Every method, in docs/PLATFORM.md order.
const std::vector<PlatformMethodInfo>& platform_methods();
const PlatformMethodInfo* find_platform_method(const std::string& name);

struct PlatformError {
    std::string code, message, hint;
};

struct PlatformAnswer {
    std::uint64_t id = 0;
    std::string method;
    bool ok = true;
    Json result;          // when ok
    PlatformError error;  // when !ok
};

struct PlatformEvent {
    std::string name;  // one of platform_events()
    Json data;
};

// ------------------------------------------------------------------------------------------------------- backend --

// How a backend answers. A small copyable handle, safe to keep and to use from any thread, also after the
// PlatformServices it belongs to is gone (then every call does nothing). `complete`/`fail` answer request `id`; the first
// answer counts, a second one (or one for an unknown id) is ignored.
class PlatformSink {
public:
    PlatformSink() = default;
    void complete(std::uint64_t id, Json result) const;
    void fail(std::uint64_t id, PlatformError error) const;
    // Sends an event to the game: "purchase" {status, productId, transactionId, receipt}, "overlay" {open}, "player"
    // {id, name, signedIn}. An unknown event name is logged once and dropped.
    void emit(const std::string& event, Json data) const;
    bool alive() const;  // false once the PlatformServices (or its backend) is gone

    struct State;
    PlatformSink(std::weak_ptr<State> state, std::uint64_t generation) : state_(std::move(state)), generation_(generation) {}

private:
    std::weak_ptr<State> state_;
    std::uint64_t generation_ = 0;
};

// Implemented by the fake, "none" and the plugin adapter of fa_runtime.
class PlatformBackend {
public:
    virtual ~PlatformBackend() = default;
    virtual std::string name() const = 0;                   // "fake", "none", or the plugin backend's name ("steam")
    virtual std::vector<std::string> services() const = 0;  // the subset of platform_services_all() it offers
    // Called when the backend is set. Backends that send events on their own keep the sink.
    virtual void attach(const PlatformSink& sink) { (void)sink; }
    // Starts one request. Answer with sink.complete / sink.fail exactly once: now (same thread) or later (any thread).
    virtual void request(std::uint64_t id, const std::string& method, const Json& args, const PlatformSink& sink) = 0;
    virtual void frame() {}  // once per engine frame, on the game thread, before scripts run
};

// The backend of a game with no store: offers no service; player.signIn answers "not signed in".
std::unique_ptr<PlatformBackend> make_none_backend();

class FakeBackend;

class PlatformServices {
public:
    PlatformServices();
    ~PlatformServices();
    PlatformServices(const PlatformServices&) = delete;
    PlatformServices& operator=(const PlatformServices&) = delete;

    void set_catalog(PlatformCatalog catalog);
    const PlatformCatalog& catalog() const;
    // Replaces the backend (the default is "none"): requests still pending on the old one are dropped. `why` says in a
    // sentence why this backend runs (the `platform.*` commands quote it when they refuse to act on a real store).
    void set_backend(std::unique_ptr<PlatformBackend> backend, std::string why = {});
    PlatformBackend& backend() const;
    const std::string& backend_why() const { return why_; }
    FakeBackend* fake() const;  // the backend when it is the fake, else nullptr
    bool has_service(const std::string& service) const;

    struct StartInfo {
        std::uint64_t id = 0;
        // Set when the request is already answered: the backend answered inside request(), or the engine did (a service
        // the backend does not offer). It is not queued for take_answers.
        std::optional<PlatformAnswer> answer;
    };
    // Checks the request and hands it to the backend. A programmer's mistake (unknown method, an id that is not in the
    // catalog, a wrong argument) is an Error with a hint and a "did you mean": nothing reached the backend. Runtime
    // failures come back as answers. Game thread only.
    Result<StartInfo> start(const std::string& method, const Json& args);

    // Once per engine frame, before scripts: backend->frame() (the fake releases delayed answers there).
    void frame();
    // Answers and events that arrived since the last call, in the order they came (the script layer settles promises and
    // calls listeners at the start of a frame).
    std::vector<PlatformAnswer> take_answers();
    std::vector<PlatformEvent> take_events();

    // {backend, services, player: {id, name, signedIn}, pending} (player: what the last signIn answer or `player` event
    // said; signedIn false before any).
    Json info() const;
    Json player() const;
    std::size_t pending() const;
    // Forgets requests, answers, events and transactions, and resets the fake (a new test file starts like this).
    void reset_session();
    // The sink the backend got in attach(): for code that sends events on a backend's behalf.
    PlatformSink sink() const;

private:
    std::shared_ptr<PlatformSink::State> state_;
    std::unique_ptr<PlatformBackend> backend_;
    std::string why_;
};

}  // namespace fa
