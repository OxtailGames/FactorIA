// The `platform.*` commands (fa/services/platform_commands.h).
#include "fa/services/platform_commands.h"

#include <algorithm>

#include "fa/core/strings.h"
#include "fa/services/fake_platform.h"

namespace fa {

namespace {

Json schema(const char* text) { return Json::parse(text); }

// The fake backend, or the error that says which backend runs and why.
FakeBackend& need_fake(PlatformServices& platform, const char* command) {
    FakeBackend* fake = platform.fake();
    if (fake) return *fake;
    const std::string why = platform.backend_why();
    throw CommandError("unavailable",
                       std::string(command) + " only works with the fake backend, but this game runs the '" + platform.backend().name() +
                           "' backend" + (why.empty() ? std::string() : " (" + why + ")"),
                       "The fake backend runs in headless runs, tests, `factoria call` and the MCP server, and in `factoria run` "
                       "when no store plugin is declared (docs/PLATFORM.md, \"Which backend runs\").");
}

[[noreturn]] void rethrow(const Error& e) { throw CommandError("invalid_argument", e.message, e.hint); }

}  // namespace

void register_platform_commands(CommandRegistry& commands, PlatformServices& platform) {
    commands.add(
        {"platform.state",
         "Show which platform backend runs, its services, the player, the declared ids and, for the fake backend, everything it holds.",
         "Returns {backend, why, services, player: {id, name, signedIn}, catalog: {achievements, stats, leaderboards, products} (the "
         "ids factoria.json \"platform\" declares), pending (requests waiting for an answer), fake?} where `fake` (only when the "
         "backend is the fake) is {signedIn, delayFrames, frame, achievements: {id: {unlocked, progress}}, stats: {id: value}, "
         "leaderboards: {id: best}, cloud: {key: text}, owned: [productId], unfinished: [{transactionId, productId, receipt}], "
         "presence: {text, data}, ads: {outcome, gdpr, tracking, shown, rewarded}, scripted: {method: answers queued}, held, calls: [{seq, frame, method, args, ok, result | error, "
         "scripted?}], callsDropped}. `calls` is every request the game made, with the arguments the backend got (store ids "
         "included) and how it was answered: assert on it after game.step. Example: platform.state {}",
         schema(R"({"type":"object","properties":{}})"), true, "platform"},
        [&platform](const Json&) {
            Json out = platform.info();
            out["why"] = platform.backend_why();
            out["catalog"] = platform.catalog().ids_json();
            if (FakeBackend* fake = platform.fake()) out["fake"] = fake->state();
            return out;
        });

    commands.add(
        {"platform.reset",
         "Reset the fake platform backend: nothing unlocked, bought or saved, no scripted answers, signed in, an empty request log.",
         "Also numbers transactions from fake-1 and integrity tokens from fake-integrity-1 again. Pending requests are not cancelled. Fails when the game runs a real store "
         "backend (the message says which and why). Tests start every file with a fresh fake already; use this between tests that "
         "share state. Example: platform.reset {}",
         schema(R"({"type":"object","properties":{}})"), false, "platform"},
        [&platform](const Json&) {
            need_fake(platform, "platform.reset").reset();
            platform.refresh_backend();
            return Json::object();
        });

    commands.add(
        {"platform.respond",
         "Script the next answer(s) the fake platform backend gives to a method: an error, an exact result, or a change to the default.",
         "`method` is a platform method such as \"purchases.buy\" (docs/PLATFORM.md lists them all). `answer` is one of "
         "{\"error\": \"network\", \"message\"?, \"hint\"?} to reject (codes: unavailable, notSignedIn, notAllowed, unknownId, "
         "network, failed), {\"result\": value} to resolve with exactly that value, or any other object, which is merged into the "
         "default result: {\"status\": \"cancelled\"} cancels a purchase (and buys nothing). Answers are used first in, first out, "
         "one per request; `times` queues the same answer several times. Fails when the game runs a real store backend. Example: "
         "platform.respond {\"method\":\"purchases.buy\",\"answer\":{\"status\":\"cancelled\"}}",
         schema(R"({"type":"object","required":["method","answer"],"properties":{
             "method":{"type":"string","description":"The platform method, e.g. \"purchases.buy\", \"achievements.unlock\", \"cloud.save\"."},
             "answer":{"type":"object","description":"{error, message?, hint?} | {result} | an object merged into the default result."},
             "times":{"type":"integer","default":1,"minimum":1,"description":"How many requests get this answer."}}})"),
         false, "platform"},
        [&platform](const Json& a) {
            FakeBackend& fake = need_fake(platform, "platform.respond");
            const std::string method = a.at("method").get<std::string>();
            auto r = fake.respond(method, a.at("answer"), a.value("times", 1));
            if (!r.ok()) rethrow(r.error());
            return Json::object({{"method", method}, {"queued", fake.state()["scripted"].value(method, 0)}});
        });

    commands.add(
        {"platform.emit",
         "Send an event to the game as the store would: a purchase, the overlay opening or closing, a sign-in change.",
         "`event` is \"purchase\" ({productId, status?: \"purchased\" | \"pending\" | \"cancelled\" (default purchased), "
         "transactionId?, receipt?}; a purchased one also records an unfinished transaction, made up when not given), "
         "\"overlay\" ({open: bool}) or \"player\" ({id?, name?, signedIn}). Scripts get it through platform.on(event, fn) at the "
         "start of the next frame (game.step). Fails when the game runs a real store backend. Example: platform.emit "
         "{\"event\":\"overlay\",\"data\":{\"open\":true}}",
         schema(R"({"type":"object","required":["event"],"properties":{
             "event":{"type":"string","enum":["purchase","overlay","player"],"description":"The event name."},
             "data":{"type":"object","default":{},"description":"The event's data."}}})"),
         false, "platform"},
        [&platform](const Json& a) {
            auto r = need_fake(platform, "platform.emit").emit(a.at("event").get<std::string>(), a.value("data", Json::object()));
            if (!r.ok()) rethrow(r.error());
            return Json::object();
        });

    commands.add(
        {"platform.revoke",
         "Take a purchase back in the fake platform backend, as a refund does, and send the game the event a real store would.",
         "The product leaves purchases.restore() and its unfinished transaction is dropped; the game gets a \"purchase\" event "
         "{status: \"revoked\", productId, transactionId, receipt} at the start of the next frame (game.step), which "
         "platform.on(\"purchase\", fn) listeners receive. Fails when the player owns no such product (the message lists the owned "
         "ones) or when the game runs a real store backend. Example: platform.revoke {\"productId\":\"remove_ads\"}",
         schema(R"({"type":"object","required":["productId"],"properties":{
             "productId":{"type":"string","description":"The catalog id of the product to take back, e.g. \"remove_ads\"."}}})"),
         false, "platform"},
        [&platform](const Json& a) {
            const std::string id = a.at("productId").get<std::string>();
            auto r = need_fake(platform, "platform.revoke").revoke(id);
            if (!r.ok()) rethrow(r.error());
            return Json::object({{"productId", id}});
        });

    commands.add(
        {"platform.set_ad",
         "Script what the fake platform backend's test ad does: watched to the end, closed early, no ad to show, or consent refused.",
         "`outcome` decides how every ads.showRewarded() ends until changed (and platform.reset): \"watched\" (the default: "
         "{rewarded: true}), \"closedEarly\" ({rewarded: false, reason: \"closedEarly\"}), \"noFill\" (no ad: ads.available() is "
         "false and showRewarded gives reason \"noFill\") or \"consentRefused\" (also sets gdpr and tracking to \"denied\"; "
         "reason \"consentRefused\"). `gdpr` (\"granted\", \"denied\", \"notRequired\", \"unknown\") and `tracking` "
         "(\"authorized\", \"denied\", \"notDetermined\", \"restricted\", \"notRequired\") are what ads.consent() answers; a "
         "denied gdpr stops every ad. Give any of them. platform.state's fake.ads counts the ads shown and rewarded. Fails when "
         "the game runs a real store backend. Example: platform.set_ad {\"outcome\":\"closedEarly\"}",
         schema(R"({"type":"object","properties":{
             "outcome":{"type":"string","enum":["watched","closedEarly","noFill","consentRefused"],"description":"How the next ads end."},
             "gdpr":{"type":"string","enum":["granted","denied","notRequired","unknown"],"description":"What the GDPR (UMP) sheet answered."},
             "tracking":{"type":"string","enum":["authorized","denied","notDetermined","restricted","notRequired"],"description":"What the tracking (ATT) sheet answered."}}})"),
         false, "platform"},
        [&platform](const Json& a) {
            FakeBackend& fake = need_fake(platform, "platform.set_ad");
            static const std::vector<std::string> known = {"outcome", "gdpr", "tracking"};
            for (const auto& [key, value] : a.items()) {
                if (std::find(known.begin(), known.end(), key) != known.end()) continue;
                throw CommandError("invalid_argument", "platform.set_ad has no option " + Json(key).dump() + ".",
                                   did_you_mean(key, known) + " Options: outcome, gdpr, tracking.");
            }
            auto r = fake.set_ad(a.value("outcome", std::string()), a.value("gdpr", std::string()), a.value("tracking", std::string()));
            if (!r.ok()) rethrow(r.error());
            return fake.state()["ads"];
        });

    commands.add(
        {"platform.set_fake",
         "Change how the fake platform backend behaves: signed in or out, and how many frames it holds its answers.",
         "`signedIn: false` makes every method but player.signIn answer notSignedIn (and sends a `player` event); `delayFrames: n` "
         "holds each answer for n engine frames (0, the default, answers at once), so a test can look at the \"waiting\" state of a "
         "screen and game.step() until the answer arrives. Give any of them. `backend: \"none\"` makes the fake behave as the none backend (platform.has false for every service, every call rejects `unavailable`, signIn answers signed out) until platform.reset. Fails when the game runs a real store backend. "
         "Example: platform.set_fake {\"delayFrames\":2}",
         schema(R"({"type":"object","properties":{
             "signedIn":{"type":"boolean","description":"false: the player is not signed in."},
             "backend":{"type":"string","enum":["fake","none"],"description":"\"none\": behave as the none backend until platform.reset."},
             "delayFrames":{"type":"integer","minimum":0,"maximum":10000,"description":"Frames each answer is held (0 = at once)."}}})"),
         false, "platform"},
        [&platform](const Json& a) {
            FakeBackend& fake = need_fake(platform, "platform.set_fake");
            static const std::vector<std::string> known = {"signedIn", "delayFrames", "backend"};
            for (const auto& [key, value] : a.items()) {
                if (std::find(known.begin(), known.end(), key) != known.end()) continue;
                throw CommandError("invalid_argument", "platform.set_fake has no option " + Json(key).dump() + ".",
                                   did_you_mean(key, known) + " Options: signedIn, delayFrames, backend.");
            }
            if (a.contains("backend")) {
                const std::string b = a["backend"].get<std::string>();
                if (b != "fake" && b != "none")
                    throw CommandError("invalid_argument", "backend must be \"fake\" or \"none\", not " + Json(b).dump() + ".",
                                       "Use \"none\" to test a game without a store; platform.reset goes back.");
                fake.set_none(b == "none");
                platform.refresh_backend();
            }
            if (a.contains("signedIn")) fake.set_signed_in(a["signedIn"].get<bool>());
            if (a.contains("delayFrames")) fake.set_delay_frames(a["delayFrames"].get<int>());
            return Json::object({{"signedIn", fake.signed_in()}, {"delayFrames", fake.delay_frames()}, {"backend", fake.name()}});
        });
}

}  // namespace fa
