// Platform services: the catalog, the request dispatcher and the fake backend (fa/services/*.h).
#include <doctest.h>

#include <atomic>
#include <functional>
#include <thread>

#include "fa/services/fake_platform.h"
#include "fa/services/platform.h"

using namespace fa;

namespace {

const char* kCatalog = R"({
  "backend": "steam",
  "achievements": [
    { "id": "first_win", "name": "First win", "description": "Win one match.", "ids": { "steam": "ACH_WIN_ONE_GAME", "apple": "com.studio.game.first_win" } },
    { "id": "veteran", "name": "Veteran", "hidden": true }
  ],
  "stats": [ { "id": "wins", "type": "int", "ids": { "steam": "NumWins" } }, { "id": "distance", "type": "float" } ],
  "leaderboards": [ { "id": "high_score", "name": "High score", "ids": { "apple": "high_score_v2" } },
                    { "id": "best_time", "name": "Best time", "order": "ascending" } ],
  "products": [
    { "id": "gems_100", "type": "consumable", "title": "100 gems", "description": "A pile of gems.", "price": 0.99,
      "ids": { "apple": "com.studio.game.gems100" } },
    { "id": "remove_ads", "type": "nonConsumable", "title": "Remove ads", "price": 2.99, "currency": "EUR" }
  ]
})";

PlatformCatalog catalog(const char* text = kCatalog) {
    auto c = load_platform_catalog(Json::parse(text));
    REQUIRE_MESSAGE(c.ok(), c.error().to_string());
    return c.value();
}

// A PlatformServices with the sample catalog and a fake backend.
struct Game {
    PlatformServices ps;
    explicit Game(const char* text = kCatalog) {
        ps.set_catalog(catalog(text));
        ps.set_backend(std::make_unique<FakeBackend>());
    }
    FakeBackend& fake() { return *ps.fake(); }
    // The answer of a request the fake answers at once.
    PlatformAnswer ask(const std::string& method, const Json& args = Json::object()) {
        auto r = ps.start(method, args);
        REQUIRE_MESSAGE(r.ok(), r.error().to_string());
        REQUIRE(r->answer.has_value());
        return *r->answer;
    }
    Json ok(const std::string& method, const Json& args = Json::object()) {
        PlatformAnswer a = ask(method, args);
        INFO(method << ": " << a.error.code << " " << a.error.message);
        REQUIRE(a.ok);
        return a.result;
    }
    PlatformError fails(const std::string& method, const Json& args = Json::object()) {
        PlatformAnswer a = ask(method, args);
        REQUIRE_FALSE(a.ok);
        return a.error;
    }
    std::string mistake(const std::string& method, const Json& args) {
        auto r = ps.start(method, args);
        REQUIRE_FALSE(r.ok());
        return r.error().message + " | " + r.error().hint;
    }
};

bool has(const std::string& text, const char* part) { return text.find(part) != std::string::npos; }

// Records what it receives; answers by itself only when told to.
class Recorder final : public PlatformBackend {
public:
    std::string backendName = "steam";
    std::vector<std::string> offered = platform_services_all();
    struct Call {
        std::uint64_t id;
        std::string method;
        Json args;
    };
    std::vector<Call> calls;
    std::function<void(const Call&, const PlatformSink&)> handler;
    PlatformSink kept;
    int frames = 0;

    std::string name() const override { return backendName; }
    std::vector<std::string> services() const override { return offered; }
    void attach(const PlatformSink& sink) override { kept = sink; }
    void request(std::uint64_t id, const std::string& method, const Json& args, const PlatformSink& sink) override {
        calls.push_back({id, method, args});
        if (handler) handler(calls.back(), sink);
    }
    void frame() override { ++frames; }
};

}  // namespace

// ----------------------------------------------------------------------------------------------------- catalog ----
TEST_CASE("platform catalog: the sample parses into entries with their store ids") {
    PlatformCatalog c = catalog();
    CHECK(c.backend == "steam");
    CHECK(c.backend_for("windows") == "steam");
    REQUIRE(c.achievements.size() == 2);
    CHECK(c.achievements[0].name == "First win");
    CHECK(c.achievements[0].store_id("steam") == "ACH_WIN_ONE_GAME");
    CHECK(c.achievements[0].store_id("apple") == "com.studio.game.first_win");
    CHECK(c.achievements[0].store_id("fake") == "first_win");  // no entry: the id itself
    CHECK(c.achievements[1].hidden);
    CHECK(c.stats[0].type == "int");
    CHECK(c.stats[1].type == "float");
    CHECK(c.leaderboards[0].order == "descending");
    CHECK(c.leaderboards[1].order == "ascending");
    CHECK(c.products[0].price == doctest::Approx(0.99));
    CHECK(c.products[0].currency == "USD");
    CHECK(c.products[1].currency == "EUR");
    CHECK(c.find_product("gems_100")->title == "100 gems");
    CHECK(c.find_product("nope") == nullptr);
    CHECK(c.ids_json()["products"] == Json::parse(R"(["gems_100","remove_ads"])"));
}

TEST_CASE("platform catalog: an absent section is an empty catalog") {
    auto c = load_platform_catalog(Json());
    REQUIRE(c.ok());
    CHECK(c->empty());
    CHECK(c->backend.empty());
}

TEST_CASE("platform catalog: backend is a plugin name, \"auto\", or one per platform") {
    auto one = parse_platform_catalog(Json::parse(R"({"backend": "auto"})"));
    CHECK(one.ok());
    CHECK(one.catalog.backend.empty());
    auto per = parse_platform_catalog(Json::parse(R"({"backend": {"windows": "steam", "macos": "steam", "ios": "apple"}})"));
    REQUIRE(per.ok());
    CHECK(per.catalog.backend_for("windows") == "steam");
    CHECK(per.catalog.backend_for("ios") == "apple");
    CHECK(per.catalog.backend_for("linux").empty());
    REQUIRE(per.catalog.backendRefs.size() == 3);
    for (const auto& ref : per.catalog.backendRefs) {
        CHECK(ref.pointer.rfind("/platform/backend/", 0) == 0);
        CHECK((ref.name == "steam" || ref.name == "apple"));
    }
    auto bad = parse_platform_catalog(Json::parse(R"({"backend": {"windos": "steam"}})"));
    REQUIRE_FALSE(bad.ok());
    CHECK(has(bad.issues[0].message, "\"windos\" is not a platform"));
    CHECK(has(bad.issues[0].message, "did you mean \"windows\"?"));
    auto num = parse_platform_catalog(Json::parse(R"({"backend": 3})"));
    REQUIRE_FALSE(num.ok());
    CHECK(num.issues[0].pointer == "/platform/backend");
}

TEST_CASE("platform catalog: errors name the field, the problem and the fix") {
    auto first = [](const char* text) {
        auto c = load_platform_catalog(Json::parse(text));
        REQUIRE_FALSE(c.ok());
        return c.error().to_string();
    };
    // The example of the spec, character for character.
    CHECK(first(R"({"products": [{"id": "a", "type": "consumable", "title": "A"}, {"id": "b", "type": "consumable ", "title": "B"}]})") ==
          "factoria.json#/platform/products/1/type: \"consumable \" is not a product type; use one of \"consumable\", \"nonConsumable\", "
          "\"subscription\" (did you mean \"consumable\"?) (hint: Fix the value in factoria.json (docs/PLATFORM.md, \"The catalog\").)");
    CHECK(has(first(R"({"products": [{"id": "a", "title": "A"}]})"), "#/platform/products/0/type: missing \"type\"; use one of"));
    CHECK(has(first(R"({"achievements": [{"name": "A"}]})"), "#/platform/achievements/0/id: missing \"id\""));
    CHECK(has(first(R"({"achievements": [{"id": "has space", "name": "A"}]})"), "is not a valid id; use 1-64 letters, digits"));
    CHECK(has(first(R"({"achievements": [{"id": "a", "name": "A"}, {"id": "a", "name": "B"}]})"), "the id \"a\" is used twice (first at /platform/achievements/0/id)"));
    CHECK(has(first(R"({"achievements": [{"id": "a"}]})"), "#/platform/achievements/0/name: missing \"name\""));
    CHECK(has(first(R"({"achievements": [{"id": "a", "name": "A", "hidden": "yes"}]})"), "expected true or false"));
    CHECK(has(first(R"({"stats": [{"id": "a", "type": "flot"}]})"), "did you mean \"float\"?"));
    CHECK(has(first(R"({"leaderboards": [{"id": "a", "name": "A", "order": "desc"}]})"), "is not a leaderboard order"));
    CHECK(has(first(R"({"products": [{"id": "a", "type": "consumable", "title": "A", "price": -1}]})"), "#/platform/products/0/price: expected a number of at least 0"));
    CHECK(has(first(R"({"products": [{"id": "a", "type": "consumable", "title": "A", "ids": {"Steam": "x"}}]})"), "is not a backend name"));
    CHECK(has(first(R"({"products": [{"id": "a", "type": "consumable", "title": "A", "ids": {"steam": 3}}]})"), "expected the store's id as a non-empty string"));
    CHECK(has(first(R"({"achievements": {"id": "a"}})"), "#/platform/achievements: expected an array of achievements"));
    CHECK(has(first(R"("steam")"), "#/platform: expected an object"));
}

TEST_CASE("platform catalog: every problem is reported, unknown keys are warnings with a suggestion") {
    auto parsed = parse_platform_catalog(Json::parse(R"({
      "achievments": [],
      "stats": [{"id": "ok"}, {"id": "bad id"}, {"id": "ok2", "tpye": "int"}],
      "products": [{"id": "p", "type": "nope", "title": ""}]
    })"));
    CHECK_FALSE(parsed.ok());
    int errors = 0, warnings = 0;
    for (const PlatformIssue& i : parsed.issues) (i.warning ? warnings : errors)++;
    CHECK(errors == 3);    // the bad id, the product type, the empty title
    CHECK(warnings == 2);  // achievments, tpye
    bool suggested = false;
    for (const PlatformIssue& i : parsed.issues) suggested = suggested || has(i.message, "did you mean \"achievements\"?");
    CHECK(suggested);
    // What parsed is kept: the entries with an error are left out.
    CHECK(parsed.catalog.stats.size() == 2);
    CHECK(parsed.catalog.products.empty());
}

// ------------------------------------------------------------------------------------------ dispatcher: mistakes --
TEST_CASE("platform: a mistake is an error before the backend sees anything") {
    Game g;
    auto rec = std::make_unique<Recorder>();
    Recorder* r = rec.get();
    g.ps.set_backend(std::move(rec));

    std::string m = g.mistake("achievements.unlock", Json::parse(R"({"id": "first_wn"})"));
    CHECK(has(m, "\"first_wn\" is not an achievement of this game"));
    CHECK(has(m, "did you mean \"first_win\"?"));
    CHECK(has(m, "declare it in factoria.json platform.achievements"));
    CHECK(has(m, "The game's achievements: \"first_win\", \"veteran\"."));
    CHECK(has(g.mistake("purchases.buy", Json::parse(R"({"id": "gems_9"})")), "declare it in factoria.json platform.products"));
    CHECK(has(g.mistake("stats.get", Json::parse(R"({"id": "wins "})")), "did you mean \"wins\"?"));
    CHECK(has(g.mistake("achievements.unlock", Json::object()), "the argument \"id\" is missing"));
    CHECK(has(g.mistake("achievements.unlock", Json::parse(R"({"id": 3})")), "must be a string"));
    CHECK(has(g.mistake("achievements.progress", Json::parse(R"({"id": "first_win", "progress": 1.5})")), "fraction from 0 to 1"));
    CHECK(has(g.mistake("achievements.progress", Json::parse(R"({"id": "first_win", "progress": "half"})")), "must be a finite number"));
    CHECK(has(g.mistake("stats.set", Json::parse(R"({"id": "wins", "value": 1.5})")), "is an int"));
    CHECK(has(g.mistake("leaderboards.submit", Json::parse(R"({"id": "high_score", "score": 1.5})")), "whole number"));
    CHECK(has(g.mistake("leaderboards.entries", Json::parse(R"({"id": "high_score", "range": "tops"})")), "did you mean \"top\"?"));
    CHECK(has(g.mistake("leaderboards.entries", Json::parse(R"({"id": "high_score", "count": 101})")), "from 1 to 100"));
    CHECK(has(g.mistake("cloud.save", Json::parse(R"({"key": "my key", "data": "{}"})")), "is not valid"));
    CHECK(has(g.mistake("presence.set", Json::parse(R"({"text": "x", "data": {"level": 3}})")), "must be strings"));
    CHECK(has(g.mistake("overlay.open", Json::parse(R"({"page": "achievments"})")), "did you mean \"achievements\"?"));
    CHECK(has(g.mistake("overlay.open", Json::parse(R"({"page": "friends", "id": "x"})")), "takes no id"));
    {  // an unknown transaction is not a mistake in the call: the Promise rejects with unknownId
        auto r = g.ps.start("purchases.finish", Json::parse(R"({"transactionId": "t1"})"));
        REQUIRE(r.ok());
        REQUIRE(r->answer.has_value());
        CHECK_FALSE(r->answer->ok);
        CHECK(r->answer->error.code == "unknownId");
        CHECK(has(r->answer->error.message, "is not one this game was told about"));
        CHECK_FALSE(r->answer->error.hint.empty());
    }
    CHECK(has(g.mistake("purchases.buy", Json()), "arguments must be an object"));
    CHECK(has(g.mistake("achivements.unlock", Json::object()), "unknown platform method"));
    CHECK(has(g.mistake("achivements.unlock", Json::object()), "Did you mean 'achievements.unlock'?"));
    CHECK(r->calls.empty());  // nothing reached the backend
}

TEST_CASE("platform: an empty catalog says how to declare the first entry") {
    Game g("{}");
    std::string m = g.mistake("achievements.unlock", Json::parse(R"({"id": "x"})"));
    CHECK(has(m, "the game declares none"));
    CHECK(has(m, "\"platform\": {\"achievements\": ["));
}

TEST_CASE("platform: integrity.token checks the challenge before the request leaves the game") {
    Game g;
    auto rec = std::make_unique<Recorder>();
    Recorder* r = rec.get();
    g.ps.set_backend(std::move(rec));

    const std::string hint = "Make the challenge on your server: 16 or more random bytes as URL-safe Base64 (a nonce)";
    const std::string missing = g.mistake("integrity.token", Json::object());
    CHECK(has(missing, "the argument \"challenge\" is missing"));
    CHECK(has(missing, hint.c_str()));
    CHECK(has(missing, "check it inside the decoded token; a token without a fresh challenge can be replayed."));
    CHECK(has(g.mistake("integrity.token", Json::parse(R"({"challenge": null})")), "is missing"));
    CHECK(has(g.mistake("integrity.token", Json::parse(R"({"challenge": 42})")), "\"challenge\" must be a string"));
    CHECK(has(g.mistake("integrity.token", Json::parse(R"({"challenge": 42})")), "got number 42"));
    CHECK(has(g.mistake("integrity.token", Json::parse(R"({"challenge": "short"})")), "too short: 5 characters, it needs 16 to 500"));
    CHECK(has(g.mistake("integrity.token", Json::parse(R"({"challenge": ""})")), "too short: 0 characters"));
    CHECK(has(g.mistake("integrity.token", Json{{"challenge", std::string(501, 'a')}}), "too long: 501 characters, it needs 16 to 500"));
    CHECK(has(g.mistake("integrity.token", Json::parse(R"({"challenge": "short"})")), hint.c_str()));

    // A bad character is named with its position (from 1); standard Base64's + and / get the fix.
    const std::string plus = g.mistake("integrity.token", Json::parse(R"({"challenge": "abcdefg+hijklmnopqrstuv=="})"));
    CHECK(has(plus, "the challenge has the character \"+\" at position 8; only A-Z a-z 0-9 - _ = are allowed (URL-safe Base64)"));
    CHECK(has(plus, "URL-safe Base64 writes - and _ instead"));
    CHECK(has(g.mistake("integrity.token", Json::parse(R"({"challenge": "abc/defghijklmnopqrstuv"})")), "the character \"/\" at position 4"));
    CHECK(has(g.mistake("integrity.token", Json::parse(R"({"challenge": "abcdefghijklmnop qrstuv"})")), "the character \" \" at position 17"));
    CHECK(has(g.mistake("integrity.token", Json::parse(R"({"challenge": "abcdefghijklmnopqrstuv\n"})")), "the character \"\\n\" at position 23"));
    // Not ASCII: named without echoing it; the position counts characters, not bytes.
    const std::string accent = g.mistake("integrity.token", Json::parse("{\"challenge\": \"aaaa\\u00e9aaaaaaaaaaaaaaaa\"}"));
    CHECK(has(accent, "the challenge has a non-ASCII character at position 5"));
    // The first bad character is the one reported, even when the length is wrong too.
    CHECK(has(g.mistake("integrity.token", Json::parse(R"({"challenge": "a b"})")), "at position 2"));

    // 16 and 500 characters of the allowed alphabet pass, and the backend gets the challenge as it is.
    const std::string alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_=";
    CHECK(g.ps.start("integrity.token", Json{{"challenge", alphabet.substr(0, 16)}}).ok());
    CHECK(g.ps.start("integrity.token", Json{{"challenge", std::string(500, '_')}}).ok());
    REQUIRE(r->calls.size() == 2);
    CHECK(r->calls[0].method == "integrity.token");
    CHECK(r->calls[0].args == Json{{"challenge", alphabet.substr(0, 16)}});
    CHECK(r->calls[1].args["challenge"].get<std::string>().size() == 500);
    // Only the challenge is passed on: nothing else the script wrote.
    CHECK(g.ps.start("integrity.token", Json{{"challenge", alphabet.substr(0, 16)}, {"extra", 1}}).ok());
    CHECK(r->calls[2].args == Json{{"challenge", alphabet.substr(0, 16)}});
}

TEST_CASE("platform: integrity.token needs the integrity service, and its answer needs a token") {
    const Json args = Json{{"challenge", "AAAAAAAAAAAAAAAAAAAAAA"}};
    PlatformServices ps;
    ps.set_catalog(catalog());

    // Steam and Apple do not offer it: the engine answers.
    auto steam = std::make_unique<Recorder>();
    Recorder* sp = steam.get();
    steam->offered = {"achievements", "stats", "leaderboards", "cloudSave", "purchases", "overlay", "presence"};
    ps.set_backend(std::move(steam));
    auto r = ps.start("integrity.token", args);
    REQUIRE(r.ok());
    REQUIRE(r->answer.has_value());
    CHECK(r->answer->error.code == "unavailable");
    CHECK(has(r->answer->error.message, "the \"steam\" backend does not offer the \"integrity\" service"));
    CHECK(has(r->answer->error.hint, "platform.has(\"integrity\")"));
    CHECK(sp->calls.empty());
    CHECK_FALSE(ps.has_service("integrity"));

    // A backend that offers it answers {token}; an answer without a string token is a failure.
    auto play = std::make_unique<Recorder>();
    Recorder* pp = play.get();
    play->backendName = "google";
    pp->handler = [](const Recorder::Call& c, const PlatformSink& sink) {
        const std::string c0 = c.args["challenge"].get<std::string>();
        if (c0[0] == 'A') sink.complete(c.id, Json{{"token", "signed.token.1"}});
        else if (c0[0] == 'B') sink.complete(c.id, Json::object());
        else if (c0[0] == 'C') sink.complete(c.id, Json{{"token", 7}});
        else sink.complete(c.id, Json("signed"));
    };
    ps.set_backend(std::move(play));
    CHECK(ps.has_service("integrity"));
    r = ps.start("integrity.token", args);
    REQUIRE(r.ok());
    REQUIRE(r->answer.has_value());
    CHECK(r->answer->ok);
    CHECK(r->answer->result == Json{{"token", "signed.token.1"}});
    for (const char* c : {"BBBBBBBBBBBBBBBBBBBBBB", "CCCCCCCCCCCCCCCCCCCCCC", "DDDDDDDDDDDDDDDDDDDDDD"}) {
        r = ps.start("integrity.token", Json{{"challenge", c}});
        REQUIRE(r.ok());
        REQUIRE(r->answer.has_value());
        CHECK_FALSE(r->answer->ok);
        CHECK(r->answer->error.code == "failed");
        CHECK(has(r->answer->error.message, "the \"google\" backend answered integrity.token without a string \"token\""));
    }
}

// ------------------------------------------------------------------------------------- dispatcher: store ids ------
TEST_CASE("platform: the backend gets the store ids, and answers with a store id are mapped back") {
    PlatformServices ps;
    ps.set_catalog(catalog());
    auto rec = std::make_unique<Recorder>();
    Recorder* r = rec.get();
    rec->backendName = "apple";
    ps.set_backend(std::move(rec));

    CHECK(ps.start("achievements.unlock", Json::parse(R"({"id": "first_win"})")).ok());
    CHECK(r->calls.back().args == Json::parse(R"({"id": "first_win", "storeId": "com.studio.game.first_win"})"));
    CHECK(ps.start("leaderboards.submit", Json::parse(R"({"id": "high_score", "score": 120})")).ok());
    CHECK(r->calls.back().args == Json::parse(R"({"id": "high_score", "storeId": "high_score_v2", "name": "High score", "order": "descending", "period": "allTime", "periodKey": "", "date": "2026-01-01", "score": 120})"));
    CHECK(ps.start("stats.set", Json::parse(R"({"id": "wins", "value": 3})")).ok());
    CHECK(r->calls.back().args == Json::parse(R"({"id": "wins", "storeId": "wins", "type": "int", "value": 3})"));
    CHECK(ps.start("leaderboards.entries", Json::parse(R"({"id": "best_time"})")).ok());
    CHECK(r->calls.back().args == Json::parse(R"({"id": "best_time", "storeId": "best_time", "name": "Best time", "order": "ascending", "period": "allTime", "periodKey": "", "date": "2026-01-01", "range": "top", "count": 10})"));
    CHECK(ps.start("achievements.list", Json::object()).ok());
    CHECK(r->calls.back().args["achievements"].size() == 2);
    CHECK(ps.start("purchases.buy", Json::parse(R"({"id": "gems_100"})")).ok());
    CHECK(r->calls.back().args == Json::parse(R"({"id": "gems_100", "storeId": "com.studio.game.gems100", "type": "consumable"})"));

    // The store answers with ITS ids: the game gets the catalog's.
    const std::uint64_t buyId = r->calls.back().id;
    r->kept.complete(buyId, Json::parse(R"({"status": "purchased", "id": "com.studio.game.gems100", "transactionId": "T1", "receipt": "R1"})"));
    auto answers = ps.take_answers();
    REQUIRE(answers.size() == 1);
    CHECK(answers[0].result["productId"] == "gems_100");

    // finish() needs the product: the engine remembered it from the buy.
    CHECK(ps.start("purchases.finish", Json::parse(R"({"transactionId": "T1"})")).ok());
    CHECK(r->calls.back().args == Json::parse(R"({"id": "gems_100", "storeId": "com.studio.game.gems100", "type": "consumable", "transactionId": "T1"})"));
    r->kept.complete(r->calls.back().id, Json::object());
    ps.take_answers();
    {  // finished once
        auto again = ps.start("purchases.finish", Json::parse(R"({"transactionId": "T1"})"));
        REQUIRE(again.ok());
        REQUIRE(again->answer.has_value());
        CHECK(again->answer->error.code == "unknownId");
    }

    // products(): the catalog's own fields go along for backends that cannot ask a store.
    CHECK(ps.start("purchases.products", Json::parse(R"({"ids": ["remove_ads"]})")).ok());
    CHECK(r->calls.back().args["products"][0]["price"] == doctest::Approx(2.99));
    CHECK(r->calls.back().args["products"][0]["currency"] == "EUR");
    // achievements.list answered with store ids.
    CHECK(ps.start("achievements.list", Json::object()).ok());
    r->kept.complete(r->calls.back().id, Json::parse(R"([{"storeId": "com.studio.game.first_win", "unlocked": true, "progress": 1}])"));
    CHECK(ps.take_answers()[0].result[0]["id"] == "first_win");
}

// --------------------------------------------------------------------------------------- dispatcher: services ----
TEST_CASE("platform: a service the backend does not offer is answered by the engine") {
    PlatformServices ps;  // the "none" backend
    ps.set_catalog(catalog());
    auto r = ps.start("purchases.buy", Json::parse(R"({"id": "gems_100"})"));
    REQUIRE(r.ok());
    REQUIRE(r->answer.has_value());
    CHECK_FALSE(r->answer->ok);
    CHECK(r->answer->error.code == "unavailable");
    CHECK(has(r->answer->error.message, "the \"none\" backend does not offer the \"purchases\" service"));
    CHECK(has(r->answer->error.hint, "platform.has(\"purchases\")"));
    CHECK(ps.take_answers().empty());  // not queued
    // player.signIn is always allowed: "none" answers that nobody is signed in.
    auto s = ps.start("player.signIn", Json::object());
    REQUIRE(s.ok());
    REQUIRE(s->answer.has_value());
    CHECK(s->answer->ok);
    CHECK(s->answer->result["signedIn"] == false);
    CHECK(ps.info()["backend"] == "none");
    CHECK(ps.info()["services"].empty());

    // A backend with some services: the rest never reach it.
    auto rec = std::make_unique<Recorder>();
    Recorder* rp = rec.get();
    rec->offered = {"achievements"};
    ps.set_backend(std::move(rec));
    CHECK(ps.start("achievements.unlock", Json::parse(R"({"id": "first_win"})")).ok());
    auto cloud = ps.start("cloud.list", Json::object());
    REQUIRE(cloud.ok());
    REQUIRE(cloud->answer.has_value());
    CHECK(cloud->answer->error.code == "unavailable");
    CHECK(rp->calls.size() == 1);
    CHECK(ps.has_service("achievements"));
    CHECK_FALSE(ps.has_service("cloudSave"));
}

TEST_CASE("platform: answers the backend gives inside request() come back from start(); later ones are queued") {
    PlatformServices ps;
    ps.set_catalog(catalog());
    auto rec = std::make_unique<Recorder>();
    Recorder* r = rec.get();
    r->handler = [](const Recorder::Call& c, const PlatformSink& sink) {
        if (c.method == "cloud.list") sink.complete(c.id, Json::array({"slot1"}));
    };
    ps.set_backend(std::move(rec));
    auto now = ps.start("cloud.list", Json::object());
    REQUIRE(now.ok());
    REQUIRE(now->answer.has_value());
    CHECK(now->answer->result == Json::array({"slot1"}));
    CHECK(ps.pending() == 0);

    auto later = ps.start("cloud.load", Json::parse(R"({"key": "slot1"})"));
    REQUIRE(later.ok());
    CHECK_FALSE(later->answer.has_value());
    CHECK(ps.pending() == 1);
    CHECK(ps.take_answers().empty());
    r->kept.complete(later->id, Json::parse(R"({"key": "slot1", "data": "{}"})"));
    auto answers = ps.take_answers();
    REQUIRE(answers.size() == 1);
    CHECK(answers[0].id == later->id);
    CHECK(answers[0].method == "cloud.load");
    CHECK(ps.pending() == 0);

    // The first answer counts.
    r->kept.complete(later->id, Json::object());
    CHECK(ps.take_answers().empty());
}

TEST_CASE("platform: an unknown error code becomes failed, with a note") {
    PlatformServices ps;
    ps.set_catalog(catalog());
    auto rec = std::make_unique<Recorder>();
    Recorder* r = rec.get();
    ps.set_backend(std::move(rec));
    auto a = ps.start("cloud.list", Json::object());
    r->kept.fail(a->id, {"boom", "it broke", "restart"});
    auto answers = ps.take_answers();
    REQUIRE(answers.size() == 1);
    CHECK_FALSE(answers[0].ok);
    CHECK(answers[0].error.code == "failed");
    CHECK(has(answers[0].error.message, "it broke (the backend used the error code \"boom\""));
    CHECK(answers[0].error.hint == "restart");
}

TEST_CASE("platform: events are checked, the player is tracked, and unknown events are dropped") {
    PlatformServices ps;
    ps.set_catalog(catalog());
    auto rec = std::make_unique<Recorder>();
    Recorder* r = rec.get();
    rec->backendName = "apple";
    ps.set_backend(std::move(rec));
    CHECK(ps.player()["signedIn"] == false);
    r->kept.emit("player", Json::parse(R"({"id": "p1", "name": "Ann", "signedIn": true})"));
    r->kept.emit("overlay", Json::parse(R"({"open": true})"));
    r->kept.emit("purchase", Json::parse(R"({"status": "purchased", "productId": "com.studio.game.gems100", "transactionId": "T9", "receipt": "R"})"));
    r->kept.emit("rumble", Json::object());
    auto events = ps.take_events();
    REQUIRE(events.size() == 3);
    CHECK(events[0].name == "player");
    CHECK(events[2].data["productId"] == "gems_100");
    CHECK(ps.player()["name"] == "Ann");
    // The transaction of the event can be finished.
    CHECK(ps.start("purchases.finish", Json::parse(R"({"transactionId": "T9"})")).ok());
}

TEST_CASE("platform: replacing the backend drops its requests and silences its sink") {
    PlatformServices ps;
    ps.set_catalog(catalog());
    auto rec = std::make_unique<Recorder>();
    Recorder* r = rec.get();
    ps.set_backend(std::move(rec));
    auto a = ps.start("cloud.list", Json::object());
    PlatformSink old = r->kept;
    ps.set_backend(std::make_unique<FakeBackend>());
    CHECK(ps.pending() == 0);
    CHECK_FALSE(old.alive());
    old.complete(a->id, Json::array());
    old.emit("overlay", Json::parse(R"({"open": true})"));
    CHECK(ps.take_answers().empty());
    CHECK(ps.take_events().empty());
}

TEST_CASE("platform: complete() may come from another thread") {
    PlatformServices ps;
    ps.set_catalog(catalog());
    auto rec = std::make_unique<Recorder>();
    Recorder* r = rec.get();
    ps.set_backend(std::move(rec));
    std::vector<std::uint64_t> ids;
    for (int i = 0; i < 50; ++i) {
        auto a = ps.start("cloud.list", Json::object());
        REQUIRE(a.ok());
        REQUIRE_FALSE(a->answer.has_value());
        ids.push_back(a->id);
    }
    std::thread worker([&] {
        for (std::uint64_t id : ids) r->kept.complete(id, Json::array());
        r->kept.emit("overlay", Json::parse(R"({"open": false})"));
    });
    worker.join();
    CHECK(ps.take_answers().size() == 50);
    CHECK(ps.take_events().size() == 1);
}

TEST_CASE("platform: answers after the PlatformServices is destroyed are ignored") {
    PlatformSink kept;
    std::uint64_t id = 0;
    {
        PlatformServices ps;
        ps.set_catalog(catalog());
        auto rec = std::make_unique<Recorder>();
        Recorder* r = rec.get();
        ps.set_backend(std::move(rec));
        id = ps.start("cloud.list", Json::object())->id;
        kept = r->kept;
        CHECK(kept.alive());
    }
    CHECK_FALSE(kept.alive());
    kept.complete(id, Json::array());  // no crash, nothing to deliver to
    kept.fail(id, {"failed", "late", ""});
    kept.emit("overlay", Json::parse(R"({"open": true})"));
    std::thread([&] { kept.complete(id, Json::array()); }).join();
}

TEST_CASE("platform: frame() reaches the backend") {
    PlatformServices ps;
    auto rec = std::make_unique<Recorder>();
    Recorder* r = rec.get();
    ps.set_backend(std::move(rec));
    ps.frame();
    ps.frame();
    CHECK(r->frames == 2);
}

// ------------------------------------------------------------------------------------------------- fake backend --
TEST_CASE("fake: sign in and the default answers of achievements, stats and leaderboards") {
    Game g;
    CHECK(g.ok("player.signIn") == Json::parse(R"({"id": "fake-player", "name": "Player", "signedIn": true})"));
    CHECK(g.ps.player()["name"] == "Player");  // tracked from the answer

    CHECK(g.ok("achievements.unlock", Json::parse(R"({"id": "first_win"})")) == Json::parse(R"({"id": "first_win", "unlocked": true, "newly": true})"));
    CHECK(g.ok("achievements.unlock", Json::parse(R"({"id": "first_win"})"))["newly"] == false);
    CHECK(g.ok("achievements.progress", Json::parse(R"({"id": "veteran", "progress": 0.4})")) == Json::parse(R"({"id": "veteran", "progress": 0.4, "unlocked": false})"));
    CHECK(g.ok("achievements.progress", Json::parse(R"({"id": "veteran", "progress": 0.1})"))["progress"] == doctest::Approx(0.4));  // never goes down
    CHECK(g.ok("achievements.progress", Json::parse(R"({"id": "veteran", "progress": 1})"))["unlocked"] == true);
    Json list = g.ok("achievements.list");
    REQUIRE(list.size() == 2);
    CHECK(list[0] == Json::parse(R"({"id": "first_win", "unlocked": true, "progress": 1.0, "name": "First win", "description": "Win one match."})"));
    CHECK(list[1]["unlocked"] == true);
    CHECK(g.ok("achievements.reset") == Json::object());
    CHECK(g.ok("achievements.list")[0]["unlocked"] == false);

    CHECK(g.ok("stats.get", Json::parse(R"({"id": "wins"})")) == Json::parse(R"({"id": "wins", "value": 0})"));
    CHECK(g.ok("stats.set", Json::parse(R"({"id": "wins", "value": 7})")) == Json::parse(R"({"id": "wins", "value": 7})"));
    CHECK(g.ok("stats.get", Json::parse(R"({"id": "wins"})"))["value"] == 7);
    g.ok("stats.set", Json::parse(R"({"id": "distance", "value": 12.5})"));
    CHECK(g.ok("stats.get", Json::parse(R"({"id": "distance"})"))["value"] == doctest::Approx(12.5));

    CHECK(g.ok("leaderboards.entries", Json::parse(R"({"id": "high_score"})")) == Json::array());
    CHECK(g.ok("leaderboards.submit", Json::parse(R"({"id": "high_score", "score": 100})")) == Json::parse(R"({"id": "high_score", "score": 100, "best": 100})"));
    CHECK(g.ok("leaderboards.submit", Json::parse(R"({"id": "high_score", "score": 40})"))["best"] == 100);  // higher is better
    CHECK(g.ok("leaderboards.submit", Json::parse(R"({"id": "high_score", "score": 250})"))["best"] == 250);
    CHECK(g.ok("leaderboards.submit", Json::parse(R"({"id": "best_time", "score": 9000})"))["best"] == 9000);
    CHECK(g.ok("leaderboards.submit", Json::parse(R"({"id": "best_time", "score": 8000})"))["best"] == 8000);  // ascending: lower wins
    CHECK(g.ok("leaderboards.submit", Json::parse(R"({"id": "best_time", "score": 9500})"))["best"] == 8000);
    CHECK(g.ok("leaderboards.entries", Json::parse(R"({"id": "high_score", "range": "around", "count": 5})")) ==
          Json::parse(R"([{"rank": 1, "name": "Player", "score": 250, "playerId": "fake-player", "isPlayer": true}])"));
}

TEST_CASE("fake: cloud saves") {
    Game g;
    CHECK(g.ok("cloud.list") == Json::array());
    CHECK(g.ok("cloud.load", Json::parse(R"({"key": "slot1"})")).is_null());
    // Outside CHECK: MSVC's preprocessor mangles a raw string that holds \" when it is a macro argument.
    const Json saved = Json::parse(R"({"key": "slot1", "data": "{\"level\":3}"})");
    CHECK(g.ok("cloud.save", saved) == Json::parse(R"({"key": "slot1", "bytes": 11})"));
    g.ok("cloud.save", Json::parse(R"({"key": "a", "data": "x"})"));
    CHECK(g.ok("cloud.load", Json::parse(R"({"key": "slot1"})")) == saved);
    CHECK(g.ok("cloud.list") == Json::parse(R"(["a", "slot1"])"));
    g.ok("cloud.remove", Json::parse(R"({"key": "slot1"})"));
    CHECK(g.ok("cloud.list") == Json::parse(R"(["a"])"));
}

TEST_CASE("fake: purchases, transactions and restore") {
    Game g;
    Json products = g.ok("purchases.products");
    REQUIRE(products.size() == 2);
    CHECK(products[0] == Json::parse(R"({"id": "gems_100", "title": "100 gems", "description": "A pile of gems.", "price": "$0.99",
                                         "priceValue": 0.99, "currency": "USD", "type": "consumable"})"));
    CHECK(products[1]["price"] == "2.99 EUR");
    CHECK(g.ok("purchases.products", Json::parse(R"({"ids": ["remove_ads"]})")).size() == 1);

    Json bought = g.ok("purchases.buy", Json::parse(R"({"id": "gems_100"})"));
    CHECK(bought == Json::parse(R"({"status": "purchased", "productId": "gems_100", "transactionId": "fake-1", "receipt": "fake-receipt-1"})"));
    Json second = g.ok("purchases.buy", Json::parse(R"({"id": "gems_100"})"));
    CHECK(second["transactionId"] == "fake-2");
    g.ok("purchases.buy", Json::parse(R"({"id": "remove_ads"})"));
    Json state = g.fake().state();
    CHECK(state["unfinished"].size() == 3);  // nothing is finished by itself
    CHECK(state["owned"] == Json::parse(R"(["remove_ads"])"));  // consumables are not owned

    CHECK(g.ok("purchases.finish", Json::parse(R"({"transactionId": "fake-1"})")) == Json::object());
    CHECK(g.fake().state()["unfinished"].size() == 2);
    // A non-consumable bought twice answers purchased again, with the same ownership.
    CHECK(g.ok("purchases.buy", Json::parse(R"({"id": "remove_ads"})"))["status"] == "purchased");
    CHECK(g.fake().state()["owned"].size() == 1);

    Json restored = g.ok("purchases.restore");
    REQUIRE(restored.size() == 1);
    CHECK(restored[0]["productId"] == "remove_ads");
    CHECK(restored[0]["transactionId"] == "fake-4");
    CHECK(restored[0]["receipt"] == "fake-receipt-4");
}

TEST_CASE("fake: overlay and presence") {
    Game g;
    CHECK(g.ok("overlay.open", Json::parse(R"({"page": "achievements"})")) == Json::object());
    CHECK(g.ok("overlay.open", Json::parse(R"({"page": "store", "id": "gems_100"})")) == Json::object());
    CHECK(g.ok("presence.set", Json::parse(R"({"text": "In level 3", "data": {"level": "3"}})")) == Json::object());
    CHECK(g.fake().state()["presence"] == Json::parse(R"({"text": "In level 3", "data": {"level": "3"}})"));
    auto calls = g.fake().state()["calls"];
    CHECK(calls[calls.size() - 2]["args"] == Json::parse(R"({"page": "store", "id": "gems_100", "storeId": "gems_100"})"));
}

TEST_CASE("fake: integrity tokens are numbered from 1, restart on reset, and can be scripted") {
    Game g;
    const Json args = Json{{"challenge", "AAAAAAAAAAAAAAAAAAAAAA"}};
    CHECK(g.ps.has_service("integrity"));
    CHECK(g.ok("integrity.token", args) == Json{{"token", "fake-integrity-1"}});
    CHECK(g.ok("integrity.token", args)["token"] == "fake-integrity-2");

    // A scripted error uses no number; neither does a scripted token (the made-up one is still next).
    REQUIRE(g.fake().respond("integrity.token", Json::parse(R"({"error": "unavailable", "message": "Google Play services are missing"})")).ok());
    PlatformError e = g.fails("integrity.token", args);
    CHECK(e.code == "unavailable");
    CHECK(e.message == "Google Play services are missing");
    REQUIRE(g.fake().respond("integrity.token", Json::parse(R"({"token": "my.token"})")).ok());
    CHECK(g.ok("integrity.token", args)["token"] == "my.token");
    REQUIRE(g.fake().respond("integrity.token", Json::parse(R"({"result": {"token": "exact"}})")).ok());
    CHECK(g.ok("integrity.token", args) == Json{{"token", "exact"}});
    CHECK(g.ok("integrity.token", args)["token"] == "fake-integrity-3");
    // A scripted answer without a string token is a failure, as with a real backend.
    REQUIRE(g.fake().respond("integrity.token", Json::parse(R"({"result": {}})")).ok());
    CHECK(g.fails("integrity.token", args).code == "failed");
    CHECK(g.ok("integrity.token", args)["token"] == "fake-integrity-4");

    // The request log has every call with the challenge the backend got.
    Json calls = g.fake().state()["calls"];
    CHECK(calls[0]["method"] == "integrity.token");
    CHECK(calls[0]["args"] == args);
    CHECK(calls[0]["result"]["token"] == "fake-integrity-1");
    CHECK(calls[2]["error"]["code"] == "unavailable");

    // reset() numbers them from 1 again, next to the transactions.
    g.fake().reset();
    CHECK(g.ok("integrity.token", args)["token"] == "fake-integrity-1");
    CHECK(g.ok("purchases.buy", Json::parse(R"({"id": "gems_100"})"))["transactionId"] == "fake-1");

    // Not signed in: like every method but player.signIn.
    g.fake().set_signed_in(false);
    CHECK(g.fails("integrity.token", args).code == "notSignedIn");
}

TEST_CASE("fake: not signed in rejects everything but player.signIn") {
    Game g;
    g.fake().set_signed_in(false);
    PlatformError e = g.fails("achievements.unlock", Json::parse(R"({"id": "first_win"})"));
    CHECK(e.code == "notSignedIn");
    CHECK(has(e.hint, "signedIn: true"));
    CHECK(g.ok("player.signIn")["signedIn"] == false);
    // A player event told the game.
    auto events = g.ps.take_events();
    REQUIRE(events.size() == 1);
    CHECK(events[0].name == "player");
    CHECK(events[0].data["signedIn"] == false);
    g.fake().set_signed_in(true);
    CHECK(g.ok("achievements.unlock", Json::parse(R"({"id": "first_win"})"))["unlocked"] == true);
    CHECK(g.ps.take_events().size() == 1);
}

TEST_CASE("fake: respond() has three forms and answers first in, first out") {
    Game g;
    // {error}: reject, with a message and hint of your own, or defaults.
    REQUIRE(g.fake().respond("purchases.buy", Json::parse(R"({"error": "network", "message": "no route to the store", "hint": "retry"})")).ok());
    PlatformError e = g.fails("purchases.buy", Json::parse(R"({"id": "gems_100"})"));
    CHECK(e.code == "network");
    CHECK(e.message == "no route to the store");
    CHECK(e.hint == "retry");
    REQUIRE(g.fake().respond("purchases.buy", Json::parse(R"({"error": "notAllowed"})")).ok());
    e = g.fails("purchases.buy", Json::parse(R"({"id": "gems_100"})"));
    CHECK(e.code == "notAllowed");
    CHECK(has(e.message, "scripted by the test"));
    CHECK(g.fake().state()["owned"].empty());

    // {result}: exactly that.
    REQUIRE(g.fake().respond("stats.get", Json::parse(R"({"result": {"id": "wins", "value": 99}})")).ok());
    CHECK(g.ok("stats.get", Json::parse(R"({"id": "wins"})")) == Json::parse(R"({"id": "wins", "value": 99})"));
    CHECK(g.ok("stats.get", Json::parse(R"({"id": "wins"})"))["value"] == 0);  // back to the default

    // Anything else: merged into the default; a cancelled purchase owns and records nothing.
    REQUIRE(g.fake().respond("purchases.buy", Json::parse(R"({"status": "cancelled"})")).ok());
    Json cancelled = g.ok("purchases.buy", Json::parse(R"({"id": "remove_ads"})"));
    CHECK(cancelled["status"] == "cancelled");
    CHECK(cancelled["productId"] == "remove_ads");
    Json state = g.fake().state();
    CHECK(state["owned"].empty());
    CHECK(state["unfinished"].empty());
    CHECK(g.ok("purchases.buy", Json::parse(R"({"id": "remove_ads"})"))["transactionId"] == "fake-1");  // no number was used up

    // times, and a FIFO per method.
    REQUIRE(g.fake().respond("achievements.unlock", Json::parse(R"({"error": "network"})"), 2).ok());
    REQUIRE(g.fake().respond("achievements.unlock", Json::parse(R"({"newly": false})")).ok());
    CHECK(g.fake().state()["scripted"]["achievements.unlock"] == 3);
    CHECK(g.fails("achievements.unlock", Json::parse(R"({"id": "first_win"})")).code == "network");
    CHECK(g.fails("achievements.unlock", Json::parse(R"({"id": "first_win"})")).code == "network");
    CHECK(g.ok("achievements.unlock", Json::parse(R"({"id": "first_win"})"))["newly"] == false);
    CHECK(g.ok("achievements.unlock", Json::parse(R"({"id": "first_win"})"))["newly"] == false);  // default: unlocked by the merged one
    CHECK(g.fake().state()["scripted"].empty());
}

TEST_CASE("fake: respond() refuses mistakes with a suggestion") {
    Game g;
    auto bad = g.fake().respond("purchases.bye", Json::object());
    REQUIRE_FALSE(bad.ok());
    CHECK(has(bad.error().hint, "Did you mean 'purchases.buy'?"));
    bad = g.fake().respond("purchases.buy", Json::parse(R"({"error": "netwrk"})"));
    REQUIRE_FALSE(bad.ok());
    CHECK(has(bad.error().hint, "Did you mean 'network'?"));
    CHECK_FALSE(g.fake().respond("purchases.buy", Json(3)).ok());
    CHECK_FALSE(g.fake().respond("purchases.buy", Json::object(), 0).ok());
    CHECK_FALSE(g.fake().respond("purchases.buy", Json::parse(R"({"error": "network", "result": {}})")).ok());
    bad = g.fake().respond("achievements.list", Json::parse(R"({"unlocked": true})"));
    REQUIRE_FALSE(bad.ok());
    CHECK(has(bad.error().message, "answers with a list"));
    CHECK(g.fake().respond("achievements.list", Json::parse(R"({"result": []})")).ok());
}

TEST_CASE("fake: delayFrames holds answers for that many frames") {
    Game g;
    g.fake().set_delay_frames(2);
    auto a = g.ps.start("achievements.unlock", Json::parse(R"({"id": "first_win"})"));
    REQUIRE(a.ok());
    CHECK_FALSE(a->answer.has_value());
    CHECK(g.ps.pending() == 1);
    CHECK(g.fake().state()["held"] == 1);
    CHECK(g.fake().state()["achievements"].empty());  // nothing happened yet
    g.ps.frame();
    CHECK(g.ps.take_answers().empty());
    g.ps.frame();
    auto answers = g.ps.take_answers();
    REQUIRE(answers.size() == 1);
    CHECK(answers[0].id == a->id);
    CHECK(answers[0].result["unlocked"] == true);
    CHECK(g.ps.pending() == 0);
    CHECK(g.fake().state()["achievements"]["first_win"]["unlocked"] == true);

    // Answers come back in the order of the requests.
    auto b = g.ps.start("cloud.list", Json::object());
    auto c = g.ps.start("cloud.list", Json::object());
    g.ps.frame();
    g.ps.frame();
    auto both = g.ps.take_answers();
    REQUIRE(both.size() == 2);
    CHECK(both[0].id == b->id);
    CHECK(both[1].id == c->id);
}

TEST_CASE("fake: emit() sends events, and a purchased one records an unfinished transaction") {
    Game g;
    REQUIRE(g.fake().emit("overlay", Json::parse(R"({"open": true})")).ok());
    REQUIRE(g.fake().emit("purchase", Json::parse(R"({"productId": "gems_100"})")).ok());
    REQUIRE(g.fake().emit("purchase", Json::parse(R"({"status": "pending", "productId": "remove_ads"})")).ok());
    auto events = g.ps.take_events();
    REQUIRE(events.size() == 3);
    CHECK(events[1].data == Json::parse(R"({"productId": "gems_100", "status": "purchased", "transactionId": "fake-1", "receipt": "fake-receipt-1"})"));
    CHECK(events[2].data.value("transactionId", "") == "");
    CHECK(g.fake().state()["unfinished"].size() == 1);
    CHECK(g.ok("purchases.finish", Json::parse(R"({"transactionId": "fake-1"})")) == Json::object());
    CHECK(g.fake().state()["unfinished"].empty());

    auto bad = g.fake().emit("purchas", Json::object());
    REQUIRE_FALSE(bad.ok());
    CHECK(has(bad.error().hint, "Did you mean 'purchase'?"));
    CHECK_FALSE(g.fake().emit("purchase", Json::object()).ok());       // needs a productId
    CHECK_FALSE(g.fake().emit("overlay", Json::object()).ok());        // needs open
    CHECK_FALSE(g.fake().emit("overlay", Json(3)).ok());
}

TEST_CASE("fake: the request log and reset()") {
    Game g;
    g.ok("achievements.unlock", Json::parse(R"({"id": "first_win"})"));
    REQUIRE(g.fake().respond("stats.get", Json::parse(R"({"error": "network"})")).ok());
    g.fails("stats.get", Json::parse(R"({"id": "wins"})"));
    g.ps.frame();
    g.ok("cloud.list");
    Json calls = g.fake().state()["calls"];
    REQUIRE(calls.size() == 3);
    CHECK(calls[0]["seq"] == 1);
    CHECK(calls[0]["frame"] == 0);
    CHECK(calls[0]["method"] == "achievements.unlock");
    CHECK(calls[0]["args"]["storeId"] == "first_win");
    CHECK(calls[0]["ok"] == true);
    CHECK(calls[1]["ok"] == false);
    CHECK(calls[1]["error"]["code"] == "network");
    CHECK(calls[1]["scripted"] == true);
    CHECK(calls[2]["frame"] == 1);

    g.fake().set_delay_frames(3);
    g.fake().set_signed_in(false);
    g.fake().reset();
    Json fresh = g.fake().state();
    CHECK(fresh["calls"].empty());
    CHECK(fresh["signedIn"] == true);
    CHECK(fresh["delayFrames"] == 0);
    CHECK(fresh["achievements"].empty());
    CHECK(g.ok("purchases.buy", Json::parse(R"({"id": "gems_100"})"))["transactionId"] == "fake-1");  // numbering starts over
}

TEST_CASE("fake: reset_session() forgets pending requests and transactions") {
    Game g;
    g.fake().set_delay_frames(5);
    REQUIRE(g.ps.start("cloud.list", Json::object()).ok());
    REQUIRE(g.fake().emit("overlay", Json::parse(R"({"open": true})")).ok());
    g.ps.reset_session();
    CHECK(g.ps.pending() == 0);
    CHECK(g.ps.take_events().empty());
    CHECK(g.fake().delay_frames() == 0);
}

TEST_CASE("fake: the log keeps the latest 500 calls") {
    Game g;
    for (int i = 0; i < 520; ++i) g.ok("cloud.list");
    Json s = g.fake().state();
    CHECK(s["calls"].size() == 500);
    CHECK(s["callsDropped"] == 20);
    CHECK(s["calls"][0]["seq"] == 21);
}

// ------------------------------------------------------------------------------------------ translated texts ----
TEST_CASE("platform: achievements and products list their text in the current language from one catalog") {
    const char* text = R"({
      "achievements": [ { "id": "first_win", "nameKey": "ach.first_win.name", "descriptionKey": "ach.first_win.desc" },
                        { "id": "veteran", "name": "Veteran", "nameKey": "ach.missing" } ],
      "products": [ { "id": "gems_100", "type": "consumable", "titleKey": "shop.gems_100", "price": 0.99 } ]
    })";
    Game g(text);
    std::string language = "en";
    const std::map<std::string, std::map<std::string, std::string>> tables = {
        {"en", {{"ach.first_win.name", "First win"}, {"ach.first_win.desc", "Win one match."}, {"shop.gems_100", "100 gems"}}},
        {"es", {{"ach.first_win.name", "Primera victoria"}, {"ach.first_win.desc", "Gana una partida."}, {"shop.gems_100", "100 gemas"}}}};
    g.ps.set_translator([&](const std::string& key) -> std::optional<std::string> {
        const auto& t = tables.at(language);
        auto it = t.find(key);
        if (it == t.end()) return std::nullopt;
        return it->second;
    });
    Json en = g.ok("achievements.list");
    CHECK(en[0]["name"] == "First win");
    CHECK(en[0]["description"] == "Win one match.");
    CHECK(en[1]["name"] == "Veteran");  // the key is unknown: the plain text
    CHECK(g.ok("purchases.products")[0]["title"] == "100 gems");
    language = "es";
    Json es = g.ok("achievements.list");
    CHECK(es[0]["name"] == "Primera victoria");
    CHECK(es[0]["description"] == "Gana una partida.");
    CHECK(g.ok("purchases.products")[0]["title"] == "100 gemas");
}

TEST_CASE("platform catalog: a text can be a locale key instead; errors name the field") {
    auto ok = parse_platform_catalog(Json::parse(R"({"achievements": [{"id": "a", "nameKey": "x.name"}],
                                                      "products": [{"id": "p", "type": "consumable", "titleKey": "x.title"}]})"));
    CHECK(ok.ok());
    REQUIRE(ok.catalog.textKeyRefs.size() == 2);
    CHECK(ok.catalog.textKeyRefs[0].pointer == "/platform/achievements/0/nameKey");
    CHECK(ok.catalog.textKeyRefs[1].key == "x.title");
    auto none = parse_platform_catalog(Json::parse(R"({"achievements": [{"id": "a"}]})"));
    REQUIRE(none.issues.size() == 1);
    CHECK(none.issues[0].pointer == "/platform/achievements/0/name");
    auto bad = parse_platform_catalog(Json::parse(R"({"achievements": [{"id": "a", "nameKey": 3}]})"));
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.issues[0].pointer == "/platform/achievements/0/nameKey");
}

TEST_CASE("fake: set_none() behaves as the none backend until reset()") {
    Game g;
    CHECK(g.ps.has_service("purchases"));
    g.fake().set_none(true);
    g.ps.refresh_backend();
    CHECK_FALSE(g.ps.has_service("purchases"));
    CHECK(g.ps.info()["backend"] == "none");
    PlatformError e = g.fails("achievements.unlock", Json::parse(R"({"id": "first_win"})"));
    CHECK(e.code == "unavailable");
    CHECK(g.ok("player.signIn")["signedIn"] == false);
    g.fake().reset();
    g.ps.refresh_backend();
    CHECK(g.ps.has_service("purchases"));
    CHECK(g.ps.info()["backend"] == "fake");
    CHECK(g.ok("achievements.unlock", Json::parse(R"({"id": "first_win"})"))["unlocked"] == true);
}

// ------------------------------------------------------------------------------------------------- revoke (M26.8) ----
TEST_CASE("fake: revoke() takes a purchase back and sends the refund event") {
    Game g;
    Json bought = g.ok("purchases.buy", Json::parse(R"({"id": "remove_ads"})"));
    CHECK(g.ok("purchases.restore").size() == 1);
    g.ps.take_events();

    REQUIRE(g.fake().revoke("remove_ads").ok());
    CHECK(g.ok("purchases.restore").empty());
    CHECK(g.fake().state()["owned"].empty());
    CHECK(g.fake().state()["unfinished"].empty());
    auto events = g.ps.take_events();
    REQUIRE(events.size() == 1);
    CHECK(events[0].name == "purchase");
    CHECK(events[0].data["status"] == "revoked");
    CHECK(events[0].data["productId"] == "remove_ads");
    CHECK(events[0].data["transactionId"] == bought["transactionId"]);

    // The refunded transaction is gone for good: finishing it rejects.
    CHECK(g.fails("purchases.finish", Json::object({{"transactionId", bought["transactionId"]}})).code == "unknownId");

    // A consumable bought and not finished can be taken back too; the second time there is nothing left.
    g.ok("purchases.buy", Json::parse(R"({"id": "gems_100"})"));
    REQUIRE(g.fake().revoke("gems_100").ok());
    auto none = g.fake().revoke("gems_100");
    REQUIRE_FALSE(none.ok());
    CHECK(has(none.error().message, "is not owned"));
}

TEST_CASE("fake: revoke() of a product that is not owned names what is") {
    Game g;
    g.ok("purchases.buy", Json::parse(R"({"id": "remove_ads"})"));
    auto bad = g.fake().revoke("remove_adz");
    REQUIRE_FALSE(bad.ok());
    CHECK(has(bad.error().hint, "remove_ads"));
    CHECK(g.ok("purchases.restore").size() == 1);  // nothing changed
}

// --------------------------------------------------------------------------------------- leaderboard names (M26.8) ----
TEST_CASE("platform: a leaderboard shows its name in the current language from nameKey") {
    const char* text = R"({
      "leaderboards": [ { "id": "high_score", "nameKey": "board.high_score" },
                        { "id": "best_time", "name": "Best time", "nameKey": "board.missing", "order": "ascending" } ]
    })";
    Game g(text);
    std::string language = "en";
    const std::map<std::string, std::map<std::string, std::string>> tables = {
        {"en", {{"board.high_score", "High score"}}}, {"es", {{"board.high_score", "Puntuacion maxima"}}}};
    g.ps.set_translator([&](const std::string& key) -> std::optional<std::string> {
        const auto& t = tables.at(language);
        auto it = t.find(key);
        if (it == t.end()) return std::nullopt;
        return it->second;
    });
    auto name_sent = [&](const char* id) {
        g.ok("leaderboards.entries", Json::parse(std::string("{\"id\": \"") + id + "\"}"));
        return g.fake().state()["calls"].back()["args"]["name"];
    };
    CHECK(name_sent("high_score") == "High score");
    CHECK(name_sent("best_time") == "Best time");  // unknown key: the plain text
    language = "es";
    CHECK(name_sent("high_score") == "Puntuacion maxima");

    auto ok = parse_platform_catalog(Json::parse(R"({"leaderboards": [{"id": "b", "nameKey": "x.name"}]})"));
    CHECK(ok.ok());
    REQUIRE(ok.catalog.textKeyRefs.size() == 1);
    CHECK(ok.catalog.textKeyRefs[0].pointer == "/platform/leaderboards/0/nameKey");
    auto none = parse_platform_catalog(Json::parse(R"({"leaderboards": [{"id": "b"}]})"));
    REQUIRE(none.issues.size() == 1);
    CHECK(none.issues[0].pointer == "/platform/leaderboards/0/name");
}

TEST_CASE("platform catalog: ads placements and leaderboard periods parse, and mistakes teach") {
    PlatformCatalog c = catalog(R"({
      "leaderboards": [{"id": "daily_route", "name": "Daily route", "period": "daily"}, {"id": "all", "name": "All"}],
      "ads": {"placements": [{"id": "more_time", "type": "rewarded", "description": "20 s", "ids": {"admob": "ca-app-pub-1/2"}}, {"id": "x"}]}
    })");
    CHECK(c.leaderboards[0].period == "daily");
    CHECK(c.leaderboards[1].period == "allTime");
    REQUIRE(c.placements.size() == 2);
    CHECK(c.placements[0].store_id("admob") == "ca-app-pub-1/2");
    CHECK(c.placements[0].store_id("fake") == "more_time");
    CHECK(c.placements[1].type == "rewarded");
    CHECK(c.find_placement("x") != nullptr);
    CHECK(c.ids_json()["placements"] == Json::parse(R"(["more_time","x"])"));
    CHECK_FALSE(c.empty());

    auto first = [](const char* text) {
        auto r = load_platform_catalog(Json::parse(text));
        REQUIRE_FALSE(r.ok());
        return r.error().to_string();
    };
    CHECK(has(first(R"({"leaderboards": [{"id": "a", "name": "A", "period": "dayly"}]})"), "#/platform/leaderboards/0/period: \"dayly\" is not a leaderboard period; use one of"));
    CHECK(has(first(R"({"leaderboards": [{"id": "a", "name": "A", "period": "dayly"}]})"), "did you mean \"daily\"?"));
    CHECK(has(first(R"({"ads": {"placements": [{"id": "a", "type": "banner"}]}})"), "#/platform/ads/placements/0/type: \"banner\" is not an ad type"));
    CHECK(has(first(R"({"ads": {"placements": [{"type": "rewarded"}]}})"), "#/platform/ads/placements/0/id: missing \"id\""));
    CHECK(has(first(R"({"ads": {"placements": [{"id": "a"}, {"id": "a"}]}})"), "the id \"a\" is used twice (first at /platform/ads/placements/0/id)"));
    CHECK(has(first(R"({"ads": [1]})"), "#/platform/ads: expected an object"));
    CHECK(has(first(R"({"ads": {"placements": {"id": "a"}}})"), "#/platform/ads/placements: expected an array of ad placements"));
    auto warned = parse_platform_catalog(Json::parse(R"({"ads": {"placement": []}})"));
    REQUIRE(warned.issues.size() == 1);
    CHECK(has(warned.issues[0].message, "did you mean \"placements\"?"));
}

TEST_CASE("fake: ads outcomes, consent, and the placement is checked against the catalog") {
    Game g(R"({"ads": {"placements": [{"id": "more_time", "ids": {"fake": "unit-1"}}]}})");
    CHECK(g.ps.info()["release"] == false);
    CHECK(g.ps.has_service("ads"));
    PlatformAnswer a = g.ask("ads.available", Json::parse(R"({"placement": "more_time"})"));
    CHECK(a.result == Json::parse(R"({"available": true})"));
    a = g.ask("ads.showRewarded", Json::parse(R"({"placement": "more_time"})"));
    CHECK(a.result == Json::parse(R"({"rewarded": true})"));
    CHECK(g.fake().state()["calls"][1]["args"] == Json::parse(R"({"placement": "more_time", "adUnitId": "unit-1", "type": "rewarded", "audience": "general", "underAge": null, "release": false})"));

    REQUIRE(g.fake().set_ad("closedEarly").ok());
    CHECK(g.ask("ads.showRewarded", Json::parse(R"({"placement": "more_time"})")).result == Json::parse(R"({"rewarded": false, "reason": "closedEarly"})"));
    REQUIRE(g.fake().set_ad("noFill").ok());
    CHECK(g.ask("ads.available", Json::parse(R"({"placement": "more_time"})")).result["available"] == false);
    CHECK(g.ask("ads.showRewarded", Json::parse(R"({"placement": "more_time"})")).result["reason"] == "noFill");
    REQUIRE(g.fake().set_ad("consentRefused").ok());
    CHECK(g.ask("ads.consent").result == Json::parse(R"({"gdpr": "denied", "tracking": "denied", "canShowAds": false, "privacyOptions": "notRequired"})"));
    REQUIRE(g.fake().set_ad("watched", "granted", "notRequired").ok());
    CHECK(g.ask("ads.consent").result == Json::parse(R"({"gdpr": "granted", "tracking": "notRequired", "canShowAds": true, "privacyOptions": "notRequired"})"));
    CHECK(g.fake().state()["ads"]["shown"] == 2);
    CHECK(g.fake().state()["ads"]["rewarded"] == 1);

    auto bad = g.ps.start("ads.showRewarded", Json::parse(R"({"placement": "more_tiem"})"));
    REQUIRE_FALSE(bad.ok());
    CHECK(has(bad.error().message, "did you mean \"more_time\"?"));
    CHECK(has(bad.error().message, "platform.ads.placements"));
    auto none = Game();
    auto undeclared = none.ps.start("ads.available", Json::parse(R"({"placement": "x"})"));
    REQUIRE_FALSE(undeclared.ok());
    CHECK(has(undeclared.error().hint, "\"ads\": {\"placements\""));

    auto r = g.fake().set_ad("closedErly");
    REQUIRE_FALSE(r.ok());
    CHECK(has(r.error().hint, "closedEarly"));
    g.fake().reset();
    CHECK(g.fake().state()["ads"]["outcome"] == "watched");
}

// ---------------------------------------------------------------------------------------------- the ads backend ----
namespace {

// A store backend (Steam-like, it even offers "ads") and a plugin backend that offers only "ads", both answering at once.
struct TwoBackends {
    PlatformServices ps;
    Recorder* store = nullptr;
    Recorder* ads = nullptr;
    explicit TwoBackends(const char* catalogText) {
        ps.set_catalog(catalog(catalogText));
        auto s = std::make_unique<Recorder>();
        s->backendName = "steam";
        s->offered = {"achievements", "overlay", "ads"};
        s->handler = [](const Recorder::Call& c, const PlatformSink& sink) { sink.complete(c.id, Json::object({{"from", "store"}})); };
        store = s.get();
        ps.set_backend(std::move(s), "test");
        auto a = std::make_unique<Recorder>();
        a->backendName = "admob";
        a->offered = {"ads"};
        a->handler = [](const Recorder::Call& c, const PlatformSink& sink) { sink.complete(c.id, Json::object({{"from", "ads"}})); };
        ads = a.get();
        ps.set_ads_backend(std::move(a), "platform.ads.backend is \"admob\"");
    }
    Json ask(const std::string& method, const Json& args = Json::object()) {
        auto r = ps.start(method, args);
        REQUIRE_MESSAGE(r.ok(), r.error().to_string());
        REQUIRE(r->answer.has_value());
        REQUIRE_MESSAGE(r->answer->ok, r->answer->error.message);
        return r->answer->result;
    }
};

const char* kAdsCatalog = R"({
  "achievements": [{"id": "first_win", "name": "First win", "ids": {"steam": "ACH_WIN"}}],
  "ads": {"placements": [{"id": "more_time", "ids": {"admob": "ca-app-pub-3940256099942544/5224354917", "steam": "not-an-ad"}}]}
})";

}  // namespace

TEST_CASE("platform: an ads-only plugin backend gets ads.*, the store backend gets the rest") {
    TwoBackends t(kAdsCatalog);
    CHECK(t.ask("ads.available", Json::parse(R"({"placement": "more_time"})"))["from"] == "ads");
    CHECK(t.ask("ads.consent")["from"] == "ads");
    CHECK(t.ask("achievements.unlock", Json::parse(R"({"id": "first_win"})"))["from"] == "store");
    REQUIRE(t.ads->calls.size() == 2);
    REQUIRE(t.store->calls.size() == 1);
    CHECK(t.store->calls[0].args["storeId"] == "ACH_WIN");
    // The ids are the ads backend's own: its name picks the placement's id, not the store's.
    CHECK(t.ads->calls[0].args["adUnitId"] == "ca-app-pub-3940256099942544/5224354917");

    // Both backends are told about every frame.
    t.ps.frame();
    CHECK(t.ads->frames == 1);
    CHECK(t.store->frames == 1);

    // What the game sees: the services of both, and which backend answers ads.
    const Json info = t.ps.info();
    CHECK(info["backend"] == "steam");
    CHECK(info["adsBackend"] == "admob");
    CHECK(t.ps.has_service("ads"));
    CHECK(t.ps.has_service("achievements"));
    CHECK(t.ps.ads_why() == "platform.ads.backend is \"admob\"");

    // An answer of the ads backend comes back through the engine like any other, once, with the method of the request.
    auto later = std::make_unique<Recorder>();
    later->backendName = "admob";
    later->offered = {"ads"};
    Recorder* lp = later.get();
    t.ps.set_ads_backend(std::move(later), "again");
    auto r = t.ps.start("ads.consent", Json::object());
    REQUIRE(r.ok());
    CHECK_FALSE(r->answer.has_value());  // the backend answers later
    REQUIRE(lp->calls.size() == 1);
    lp->kept.complete(lp->calls[0].id, Json::object({{"gdpr", "granted"}}));
    auto answers = t.ps.take_answers();
    REQUIRE(answers.size() == 1);
    CHECK(answers[0].method == "ads.consent");
    CHECK(answers[0].result["gdpr"] == "granted");
}

TEST_CASE("platform: without an ads plugin the store backend serves ads, or nothing does, and platform.state says which") {
    PlatformServices ps;
    ps.set_catalog(catalog(kAdsCatalog));
    auto store = std::make_unique<Recorder>();
    store->offered = {"achievements"};
    ps.set_backend(std::move(store));
    CHECK(ps.info()["adsBackend"] == "none");
    CHECK(has(ps.ads_why(), "no backend offers the ads service"));
    CHECK_FALSE(ps.has_service("ads"));

    auto withAds = std::make_unique<Recorder>();
    withAds->offered = {"achievements", "ads"};
    ps.set_backend(std::move(withAds));
    CHECK(ps.info()["adsBackend"] == "steam");
    CHECK(has(ps.ads_why(), "serves ads itself"));

    // The fake plays the ads too.
    Game g(kAdsCatalog);
    CHECK(g.ps.info()["adsBackend"] == "fake");
}

TEST_CASE("platform: setUnderAge reaches the backend, with the audience, and is kept for the requests that follow") {
    TwoBackends t(R"({"ads": {"audience": "general", "placements": [{"id": "more_time"}]}})");
    CHECK(t.ps.info()["underAge"].is_null());
    t.ask("ads.available", Json::parse(R"({"placement": "more_time"})"));
    CHECK(t.ads->calls.back().args["underAge"].is_null());
    CHECK(t.ads->calls.back().args["audience"] == "general");

    t.ask("ads.setUnderAge", Json::parse(R"({"underAge": true})"));
    CHECK(t.ads->calls.back().method == "ads.setUnderAge");
    CHECK(t.ads->calls.back().args["underAge"] == true);
    CHECK(t.store->calls.empty());  // the store backend never hears about the age
    CHECK(t.ps.info()["underAge"] == true);
    t.ask("ads.showRewarded", Json::parse(R"({"placement": "more_time"})"));
    CHECK(t.ads->calls.back().args["underAge"] == true);
    t.ask("ads.consent");
    CHECK(t.ads->calls.back().args["underAge"] == true);

    t.ask("ads.setUnderAge", Json::parse(R"({"underAge": false})"));
    CHECK(t.ps.info()["underAge"] == false);

    // A new session forgets the answer: the game asks again.
    t.ps.reset_session();
    CHECK(t.ps.info()["underAge"].is_null());

    auto bad = t.ps.start("ads.setUnderAge", Json::parse(R"({"underAge": "yes"})"));
    REQUIRE_FALSE(bad.ok());
    CHECK(has(bad.error().message, "must be true or false"));
    CHECK(has(bad.error().hint, "ageGate"));
    auto missing = t.ps.start("ads.setUnderAge", Json::object());
    REQUIRE_FALSE(missing.ok());
    CHECK(has(missing.error().message, "underAge"));
}

TEST_CASE("platform: audience \"children\" counts every player as a child; \"mixed\" waits for the age") {
    SUBCASE("children") {
        TwoBackends t(R"({"ads": {"audience": "children", "placements": [{"id": "more_time"}]}})");
        t.ask("ads.available", Json::parse(R"({"placement": "more_time"})"));
        CHECK(t.ads->calls.back().args["underAge"] == true);
        CHECK(t.ads->calls.back().args["audience"] == "children");
        CHECK(t.ps.info()["underAge"] == true);
        auto adult = t.ps.start("ads.setUnderAge", Json::parse(R"({"underAge": false})"));
        REQUIRE_FALSE(adult.ok());
        CHECK(has(adult.error().message, "every player counts as a child"));
        CHECK(has(adult.error().hint, "\"mixed\""));
        t.ask("ads.setUnderAge", Json::parse(R"({"underAge": true})"));  // saying the same thing is fine
    }
    SUBCASE("mixed") {
        TwoBackends t(R"({"ads": {"audience": "mixed", "placements": [{"id": "more_time"}]}})");
        // Before the game knows the age nothing reaches the network: no consent form, no ad.
        CHECK(t.ask("ads.available", Json::parse(R"({"placement": "more_time"})")) == Json::parse(R"({"available": false})"));
        CHECK(t.ask("ads.showRewarded", Json::parse(R"({"placement": "more_time"})")) ==
              Json::parse(R"({"rewarded": false, "reason": "consentRefused"})"));
        CHECK(t.ads->calls.empty());
        t.ask("ads.setUnderAge", Json::parse(R"({"underAge": false})"));
        CHECK(t.ask("ads.available", Json::parse(R"({"placement": "more_time"})"))["from"] == "ads");
        CHECK(t.ads->calls.back().args["underAge"] == false);
        CHECK(t.ads->calls.back().args["audience"] == "mixed");
    }
}

TEST_CASE("fake: setUnderAge is kept, and the privacy options form shows only when it is required") {
    Game g(R"({"ads": {"audience": "mixed", "placements": [{"id": "more_time"}]}})");
    CHECK(g.ps.info()["underAge"].is_null());
    CHECK(g.ask("ads.available", Json::parse(R"({"placement": "more_time"})")).result["available"] == false);  // age unknown
    g.ok("ads.setUnderAge", Json::parse(R"({"underAge": true})"));
    CHECK(g.ps.info()["underAge"] == true);
    CHECK(g.ask("ads.available", Json::parse(R"({"placement": "more_time"})")).result["available"] == true);
    CHECK(g.fake().state()["calls"][0]["method"] == "ads.setUnderAge");

    CHECK(g.ok("ads.consent")["privacyOptions"] == "notRequired");
    CHECK(g.ok("ads.privacyOptions") == Json::parse(R"({"shown": false})"));
    REQUIRE(g.fake().set_ad("watched", "", "", "required").ok());
    CHECK(g.ok("ads.consent")["privacyOptions"] == "required");
    CHECK(g.ok("ads.privacyOptions") == Json::parse(R"({"shown": true})"));
    CHECK(g.fake().state()["ads"]["privacyShown"] == 1);
    auto bad = g.fake().set_ad("", "", "", "needed");
    REQUIRE_FALSE(bad.ok());
    CHECK(has(bad.error().hint, "required"));
    g.fake().reset();
    CHECK(g.fake().state()["ads"]["privacyOptions"] == "notRequired");
}

TEST_CASE("platform catalog: ads appIds, audience and backend parse, and mistakes teach") {
    auto good = parse_platform_catalog(Json::parse(R"({"ads": {
        "appIds": {"android": "ca-app-pub-3940256099942544~3347511713"}, "audience": "mixed", "backend": "admob",
        "placements": [{"id": "more_time"}]}})"));
    REQUIRE_MESSAGE(good.ok(), std::string(good.issues.empty() ? "" : good.issues[0].message));
    CHECK(good.catalog.adsAppIds.at("android") == "ca-app-pub-3940256099942544~3347511713");
    CHECK(good.catalog.adsAudience == "mixed");
    CHECK(good.catalog.adsBackend == "admob");
    REQUIRE(good.catalog.backendRefs.size() == 1);  // validate checks the plugin exists
    CHECK(good.catalog.backendRefs[0].pointer == "/platform/ads/backend");

    auto defaults = parse_platform_catalog(Json::parse(R"({"ads": {"placements": [{"id": "p"}]}})"));
    CHECK(defaults.catalog.adsAudience == "general");
    CHECK(defaults.catalog.adsBackend.empty());
    CHECK(defaults.catalog.adsAppIds.empty());
    CHECK(parse_platform_catalog(Json::parse(R"({"ads": {"backend": "auto"}})")).catalog.adsBackend.empty());

    auto text = [](const char* json) {
        auto r = parse_platform_catalog(Json::parse(json));
        std::string all;
        for (const PlatformIssue& i : r.issues) all += i.pointer + " " + i.message + " | " + i.hint + "\n";
        return all;
    };
    const std::string audience = text(R"({"ads": {"audience": "kids"}})");
    CHECK(has(audience, "/platform/ads/audience"));
    CHECK(has(audience, "children"));
    const std::string slash = text(R"({"ads": {"appIds": {"android": "ca-app-pub-3940256099942544/5224354917"}}})");
    CHECK(has(slash, "/platform/ads/appIds/android"));
    CHECK(has(slash, "is not an AdMob app id"));
    CHECK(has(slash, "ad unit"));
    const std::string platformName = text(R"({"ads": {"appIds": {"androd": "ca-app-pub-3940256099942544~3347511713"}}})");
    CHECK(has(platformName, "did you mean \"android\""));
    CHECK(has(text(R"({"ads": {"appIds": "x"}})"), "expected an object"));
}

TEST_CASE("fake: leaderboards keep one board per day or week of the date source; a store backend gets the period too") {
    Game g(R"({"leaderboards": [{"id": "d", "name": "D", "order": "ascending", "period": "daily"},
                                {"id": "w", "name": "W", "period": "weekly"}, {"id": "a", "name": "A"}]})");
    std::string day = "2026-10-23";  // a Friday
    g.ps.set_date_source([&] { return parse_calendar_date(day).value(); });
    g.ask("leaderboards.submit", Json::parse(R"({"id": "d", "score": 5})"));
    g.ask("leaderboards.submit", Json::parse(R"({"id": "w", "score": 7})"));
    g.ask("leaderboards.submit", Json::parse(R"({"id": "a", "score": 9})"));
    CHECK(g.fake().state()["calls"][0]["args"]["periodKey"] == "2026-10-23");
    CHECK(g.fake().state()["calls"][1]["args"]["periodKey"] == "2026-10-19");  // that week's Monday
    CHECK(g.fake().state()["calls"][2]["args"]["periodKey"] == "");
    CHECK(g.ask("leaderboards.entries", Json::parse(R"({"id": "d"})")).result.size() == 1);
    day = "2026-10-25";  // Sunday: same week
    CHECK(g.ask("leaderboards.entries", Json::parse(R"({"id": "w"})")).result.size() == 1);
    CHECK(g.ask("leaderboards.entries", Json::parse(R"({"id": "d"})")).result.empty());
    day = "2026-10-26";
    CHECK(g.ask("leaderboards.entries", Json::parse(R"({"id": "w"})")).result.empty());
    CHECK(g.ask("leaderboards.entries", Json::parse(R"({"id": "a"})")).result.size() == 1);
    day = "2027-01-03";  // across the year: the Monday is 2026-12-28
    g.ask("leaderboards.submit", Json::parse(R"({"id": "w", "score": 1})"));
    CHECK(g.fake().state()["calls"].back()["args"]["periodKey"] == "2026-12-28");

    // A store backend is asked for a daily board like for any other: it gets the period and its key.
    struct Real : PlatformBackend {
        int calls = 0;
        Json last;
        std::string name() const override { return "steam"; }
        std::vector<std::string> services() const override { return {"leaderboards"}; }
        void request(std::uint64_t id, const std::string&, const Json& args, const PlatformSink& sink) override {
            ++calls;
            last = args;
            sink.complete(id, Json::object());
        }
    };
    auto real = std::make_unique<Real>();
    Real* rp = real.get();
    g.ps.set_backend(std::move(real));
    auto daily = g.ps.start("leaderboards.submit", Json::parse(R"({"id": "d", "score": 5})"));
    REQUIRE(daily.ok());
    if (daily->answer.has_value()) CHECK(daily->answer->ok);
    CHECK(rp->calls == 1);
    CHECK(rp->last["period"] == "daily");
    CHECK(rp->last["periodKey"] == "2027-01-03");
    CHECK(g.ps.start("leaderboards.submit", Json::parse(R"({"id": "a", "score": 5})")).ok());
    CHECK(rp->calls == 2);
}

TEST_CASE("platform: release is a flag of the run, and a backend without the ads service answers unavailable") {
    PlatformServices ps;
    ps.set_catalog(catalog(R"({"ads": {"placements": [{"id": "p"}]}})"));
    CHECK_FALSE(ps.release());
    ps.set_release(true);
    CHECK(ps.release());
    CHECK(ps.info()["release"] == true);
    auto r = ps.start("ads.showRewarded", Json::parse(R"({"placement": "p"})"));
    REQUIRE(r.ok());
    REQUIRE(r->answer.has_value());
    CHECK(r->answer->error.code == "unavailable");
    CHECK(has(r->answer->error.message, "does not offer the \"ads\" service"));
}
