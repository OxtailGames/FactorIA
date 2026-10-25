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
         "Returns {backend, why, adsBackend, adsWhy, httpBackend, httpWhy, networkHosts, audience, underAge, services, player: {id, name, signedIn}, catalog: {achievements, stats, leaderboards, products, placements} (the "
         "ids factoria.json \"platform\" declares), pending (requests waiting for an answer), fake?} where `fake` (only when the "
         "backend is the fake) is {signedIn, delayFrames, frame, achievements: {id: {unlocked, progress}}, stats: {id: value}, "
         "leaderboards: {id: best} (a daily or weekly board: \"id@periodKey\"), cloud: {key: text}, cloudModified: {key: unix seconds}, cloudClock, remotePlay: [session], owned: [productId], unfinished: [{transactionId, productId, receipt}], "
         "presence: {text, data}, ads: {outcome, gdpr, tracking, shown, rewarded}, scripted: {method: answers queued}, held, calls: [{seq, frame, method, args, ok, result | error, "
         "scripted?}], callsDropped}. `calls` is every request the game made, with the arguments the backend got (store ids "
         "included) and how it was answered: assert on it after game.step. `adsBackend` is the backend that answers ads.* (an ads "
         "plugin such as admob, the store backend when it offers ads, or \"none\") and `adsWhy` says why; `audience` is factoria.json "
         "platform.ads.audience and `underAge` what platform.ads.setUnderAge answered (true for a children's game, null if not asked). "
         "`httpBackend` is what answers http.fetch (the system HTTP client such as curl or winhttp in a windowed run or a shipped game, the fake in tests and headless runs, or \"none\"), `httpWhy` says why (also why a client cannot run) and `networkHosts` is the hosts factoria.json \"network\" declares. "
         "Example: platform.state {}",
         schema(R"({"type":"object","properties":{}})"), true, "platform"},
        [&platform](const Json&) {
            Json out = platform.info();
            out["why"] = platform.backend_why();
            out["adsWhy"] = platform.ads_why();
            std::string httpWhy = platform.http_why();
            if (httpWhy.empty() && !platform.http_backend())
                httpWhy = platform.has_service("http")
                              ? "the " + out.value("backend", std::string()) +
                                    " backend answers from what game.platform.respond scripted; it never reaches the network"
                              : "no backend offers http.fetch";
            out["httpWhy"] = httpWhy;
            out["catalog"] = platform.catalog().ids_json();
            if (FakeBackend* fake = platform.fake()) out["fake"] = fake->state();
            return out;
        });

    commands.add(
        {"platform.reset",
         "Reset the fake platform backend: nothing unlocked, bought or saved, no scripted answers, signed in, an empty request log.",
         "Also numbers transactions from fake-1 and integrity tokens from fake-integrity-1 again, and forgets the answer of "
         "platform.ads.setUnderAge (the game asks the age again). Pending requests are not cancelled. Fails when the game runs a real store "
         "backend (the message says which and why). Tests start every file with a fresh fake already; use this between tests that "
         "share state. Example: platform.reset {}",
         schema(R"({"type":"object","properties":{}})"), false, "platform"},
        [&platform](const Json&) {
            need_fake(platform, "platform.reset").reset();
            platform.forget_under_age();
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
         "denied gdpr stops every ad. `privacyOptions` (\"required\", \"notRequired\", \"unknown\") is what ads.consent() answers for the "
         "privacy options form: with \"required\", platform.ads.privacyOptions() \"shows\" the form. Give any of them. platform.state's "
         "fake.ads counts the ads shown and rewarded and the privacy forms shown. Fails when "
         "the game runs a real store backend. Example: platform.set_ad {\"outcome\":\"closedEarly\"}",
         schema(R"({"type":"object","properties":{
             "outcome":{"type":"string","enum":["watched","closedEarly","noFill","consentRefused"],"description":"How the next ads end."},
             "gdpr":{"type":"string","enum":["granted","denied","notRequired","unknown"],"description":"What the GDPR (UMP) sheet answered."},
             "tracking":{"type":"string","enum":["authorized","denied","notDetermined","restricted","notRequired"],"description":"What the tracking (ATT) sheet answered."},
             "privacyOptions":{"type":"string","enum":["required","notRequired","unknown"],"description":"Whether the consent form for changing ad choices is required (ads.consent privacyOptions)."}}})"),
         false, "platform"},
        [&platform](const Json& a) {
            FakeBackend& fake = need_fake(platform, "platform.set_ad");
            static const std::vector<std::string> known = {"outcome", "gdpr", "tracking", "privacyOptions"};
            for (const auto& [key, value] : a.items()) {
                if (std::find(known.begin(), known.end(), key) != known.end()) continue;
                throw CommandError("invalid_argument", "platform.set_ad has no option " + Json(key).dump() + ".",
                                   did_you_mean(key, known) + " Options: outcome, gdpr, tracking, privacyOptions.");
            }
            auto r = fake.set_ad(a.value("outcome", std::string()), a.value("gdpr", std::string()), a.value("tracking", std::string()),
                                   a.value("privacyOptions", std::string()));
            if (!r.ok()) rethrow(r.error());
            return fake.state()["ads"];
        });

    commands.add(
        {"platform.remote_play_connect",
         "A guest joins the fake platform's Remote Play Together session, as Steam would tell the game.",
         "Adds a session that remotePlay.sessions() lists and sends the game {status: \"connected\", session} at the start of the next "
         "frame (game.step), which platform.on(\"remotePlay\", fn) listeners receive. `session` is {id (numbered from 1), guestName, "
         "guestId, deviceName, formFactor, resolution: {width, height}}; what you leave out is made up (\"Guest 1\", \"fake-guest-1\", "
         "\"Fake device\", \"computer\", 1920 x 1080). Returns the session. A guest's input is NOT simulated here: drive the pad the "
         "guest would use with game.gamepad(i). Fails when the game runs a real store backend. Example: "
         "platform.remote_play_connect {\"guestName\":\"Ana\",\"formFactor\":\"phone\"}",
         schema(R"({"type":"object","properties":{
             "guestName":{"type":"string","description":"The guest's name on the store (Steam's persona name)."},
             "guestId":{"type":"string","description":"The guest's account id on the store (a SteamID as decimal text)."},
             "deviceName":{"type":"string","description":"The name of the guest's device."},
             "formFactor":{"type":"string","enum":["unknown","phone","tablet","computer","tv","vr"],"description":"The kind of device the guest plays on."},
             "resolution":{"type":"object","description":"The guest's screen in pixels: {width, height}."}}})"),
         false, "platform"},
        [&platform](const Json& a) {
            auto r = need_fake(platform, "platform.remote_play_connect").connect_guest(a);
            if (!r.ok()) rethrow(r.error());
            return r.value();
        });

    commands.add(
        {"platform.remote_play_disconnect",
         "A guest leaves the fake platform's Remote Play Together session.",
         "Removes the session from remotePlay.sessions() and sends the game {status: \"disconnected\", session} (the session as it was) at "
         "the start of the next frame (game.step). Fails when no guest has that session id (the message lists the connected ones) or "
         "when the game runs a real store backend. Example: platform.remote_play_disconnect {\"id\":1}",
         schema(R"({"type":"object","required":["id"],"properties":{
             "id":{"type":"integer","description":"The session id platform.remote_play_connect returned."}}})"),
         false, "platform"},
        [&platform](const Json& a) {
            auto r = need_fake(platform, "platform.remote_play_disconnect").disconnect_guest(a.at("id").get<long long>());
            if (!r.ok()) rethrow(r.error());
            return r.value();
        });

    commands.add(
        {"platform.set_fake",
         "Change how the fake platform backend behaves: signed in or out, how many frames it holds its answers, and the time of its cloud saves.",
         "`signedIn: false` makes every method but player.signIn answer notSignedIn (and sends a `player` event); `delayFrames: n` "
         "holds each answer for n engine frames (0, the default, answers at once), so a test can look at the \"waiting\" state of a "
         "screen and game.step() until the answer arrives. Give any of them. `cloudClock: n` sets the time (Unix seconds) the next cloud.save gets as its modified time, which cloud.stat reports; it starts at 1767225600 (2026-01-01T00:00:00Z) and goes up by one second with each save, so saves are ordered without the wall clock. `backend: \"none\"` makes the fake behave as the none backend (platform.has false for every service, every call rejects `unavailable`, signIn answers signed out) until platform.reset. Fails when the game runs a real store backend. "
         "Example: platform.set_fake {\"delayFrames\":2}",
         schema(R"({"type":"object","properties":{
             "signedIn":{"type":"boolean","description":"false: the player is not signed in."},
             "backend":{"type":"string","enum":["fake","none"],"description":"\"none\": behave as the none backend until platform.reset."},
             "delayFrames":{"type":"integer","minimum":0,"maximum":10000,"description":"Frames each answer is held (0 = at once)."},
             "cloudClock":{"type":"integer","minimum":0,"description":"Unix seconds the next cloud.save is stamped with (cloud.stat's modified)."}}})"),
         false, "platform"},
        [&platform](const Json& a) {
            FakeBackend& fake = need_fake(platform, "platform.set_fake");
            static const std::vector<std::string> known = {"signedIn", "delayFrames", "backend", "cloudClock"};
            for (const auto& [key, value] : a.items()) {
                if (std::find(known.begin(), known.end(), key) != known.end()) continue;
                throw CommandError("invalid_argument", "platform.set_fake has no option " + Json(key).dump() + ".",
                                   did_you_mean(key, known) + " Options: signedIn, delayFrames, backend, cloudClock.");
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
            if (a.contains("cloudClock")) {
                auto r = fake.set_cloud_clock(a["cloudClock"].get<long long>());
                if (!r.ok()) rethrow(r.error());
            }
            return Json::object({{"signedIn", fake.signed_in()}, {"delayFrames", fake.delay_frames()}, {"backend", fake.name()},
                                 {"cloudClock", fake.cloud_clock()}});
        });
}

}  // namespace fa
