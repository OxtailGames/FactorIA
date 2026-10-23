// The `platform` object of the "factoria" module and `game.platform` of "factoria:test", run against the fake backend
// (fa_services) through the script test host. The dispatcher and the fake have their own tests in engine/services.
#include <doctest.h>

#include "test_host.h"

using namespace fa;
using namespace fa::test;

namespace {

Json settings() {
    return Json::parse(R"({
      "platform": {
        "achievements": [{"id": "first_win", "name": "First win"}, {"id": "veteran", "name": "Veteran"}],
        "stats": [{"id": "wins"}, {"id": "distance", "type": "float"}],
        "leaderboards": [
          {"id": "high_score", "name": "High score"},
          {"id": "daily_route", "name": "Daily route", "order": "ascending", "period": "daily"},
          {"id": "weekly_best", "name": "Weekly best", "period": "weekly"}
        ],
        "ads": {"placements": [{"id": "more_time", "type": "rewarded", "description": "20 s more"}, {"id": "double_coins"}]},
        "products": [
          {"id": "gems_100", "type": "consumable", "title": "100 gems", "price": 0.99},
          {"id": "remove_ads", "type": "nonConsumable", "title": "Remove ads", "price": 2.99, "currency": "EUR"}
        ]
      }
    })");
}

}  // namespace

TEST_CASE("platform api: calls answer through promises, in tests with await") {
    TestHost h("platform_await", settings());
    h.file("tests/platform.test.js", R"(
import { test, expect, game } from "factoria:test";
import { platform } from "factoria";

test("the fake backend is what tests talk to", async () => {
  expect(platform.backend).toBe("fake");
  expect(platform.has("purchases")).toBe(true);
  const player = await platform.signIn();
  expect(player).toEqual({ id: "fake-player", name: "Player", signedIn: true });
  expect(platform.player.name).toBe("Player");
});

test("achievements, stats and leaderboards", async () => {
  const unlocked = await platform.achievements.unlock("first_win");
  expect(unlocked).toEqual({ id: "first_win", unlocked: true, newly: true });
  expect((await platform.achievements.unlock("first_win")).newly).toBe(false);
  expect(await platform.achievements.progress("veteran", 0.5)).toEqual({ id: "veteran", progress: 0.5, unlocked: false });
  expect((await platform.achievements.list()).map((a) => a.id + ":" + a.unlocked)).toEqual(["first_win:true", "veteran:false"]);
  expect(await platform.stats.get("wins")).toBe(0);
  expect(await platform.stats.set("wins", 4)).toBe(4);
  expect(await platform.stats.add("wins", 3)).toBe(7);
  expect(await platform.stats.add("distance", 1.5)).toBe(1.5);
  expect((await platform.leaderboards.submit("high_score", 120)).best).toBe(120);
  const rows = await platform.leaderboards.entries("high_score", { range: "around", count: 3 });
  expect(rows.length).toBe(1);
  expect(rows[0].isPlayer).toBe(true);
});

test("cloud saves keep any JSON value", async () => {
  expect(await platform.cloud.load("slot1")).toBeUndefined();
  await platform.cloud.save("slot1", { level: 3, items: ["a", "b"], name: "Ann" });
  expect(await platform.cloud.load("slot1")).toEqual({ level: 3, items: ["a", "b"], name: "Ann" });
  expect(await platform.cloud.list()).toEqual(["slot1"]);
  await platform.cloud.remove("slot1");
  expect(await platform.cloud.load("slot1")).toBeUndefined();
});

test("purchases: buy, finish, restore", async () => {
  const products = await platform.purchases.products();
  expect(products.map((p) => p.id + " " + p.price)).toEqual(["gems_100 $0.99", "remove_ads 2.99 EUR"]);
  const bought = await platform.purchases.buy("gems_100");
  expect(bought.status).toBe("purchased");
  expect(bought.productId).toBe("gems_100");
  expect(bought.transactionId).toBe("fake-1");
  await platform.purchases.finish(bought.transactionId);
  await platform.purchases.buy("remove_ads");
  const owned = await platform.purchases.restore();
  expect(owned.map((o) => o.productId)).toEqual(["remove_ads"]);
});

test("overlay and presence", async () => {
  await platform.overlay.open("achievements", "first_win");
  await platform.presence.set("In level 3", { level: "3" });
  expect(game.platform.state().fake.presence).toEqual({ text: "In level 3", data: { level: "3" } });
  // The call log keeps every call of the file; the last two are the ones just made.
  expect(game.platform.calls().map((c) => c.method).slice(-2)).toEqual(["overlay.open", "presence.set"]);
});

test("integrity tokens answer { token }, numbered from 1 like transactions", async () => {
  expect(platform.has("integrity")).toBe(true);
  const challenge = "dGhpcy1pcy1hLW5vbmNl"; // what the game's server made
  expect(await platform.integrity.token(challenge)).toEqual({ token: "fake-integrity-1" });
  expect((await platform.integrity.token(challenge)).token).toBe("fake-integrity-2");
  const last = game.platform.calls().slice(-1)[0];
  expect(last.method).toBe("integrity.token");
  expect(last.args).toEqual({ challenge });
  game.platform.respond("integrity.token", { error: "unavailable", hint: "Install Google Play services." });
  let caught;
  await platform.integrity.token(challenge).catch((e) => { caught = e; });
  expect(caught.code).toBe("unavailable");
  game.platform.reset();
  expect((await platform.integrity.token(challenge)).token).toBe("fake-integrity-1");
});
)");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/platform.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 6);
}

TEST_CASE("platform api: a mistake in the call throws at once, a store failure rejects with code and hint") {
    TestHost h("platform_errors", settings());
    h.file("tests/errors.test.js", R"(
import { test, expect, game } from "factoria:test";
import { platform } from "factoria";

test("an undeclared id throws with a suggestion and where to declare it", () => {
  let message = "";
  try { platform.achievements.unlock("first_wn"); } catch (e) { message = e.message; }
  expect(message).toContain('platform.achievements.unlock("first_wn")');
  expect(message).toContain('"first_wn" is not an achievement of this game (did you mean "first_win"?)');
  expect(message).toContain("factoria.json platform.achievements");
  expect(() => platform.purchases.buy("gems_10")).toThrow("did you mean");
  expect(() => platform.stats.get("wins ")).toThrow("did you mean");
});

test("wrong arguments throw", async () => {
  expect(() => platform.achievements.progress("veteran", 2)).toThrow("fraction from 0 to 1");
  expect(() => platform.stats.set("wins", 1.5)).toThrow("is an int");
  expect(() => platform.leaderboards.submit("high_score", 1.5)).toThrow("whole number");
  expect(() => platform.leaderboards.entries("high_score", { range: "tops" })).toThrow('did you mean "top"');
  expect(() => platform.cloud.save("bad key", {})).toThrow("is not valid");
  expect(() => platform.cloud.save("k", undefined)).toThrow("cannot be saved");
  expect(() => platform.presence.set("x", { level: 3 })).toThrow("must be strings");
  expect(() => platform.overlay.open("achievments")).toThrow('did you mean "achievements"');
  expect(() => platform.stats.add("wins", "1")).toThrow("delta must be a finite number");
  // An unknown transaction is a store-like failure, not a mistake in the call: the Promise rejects with unknownId.
  let finishError;
  await platform.purchases.finish("nope").catch((e) => { finishError = e; });
  expect(finishError.code).toBe("unknownId");
  expect(finishError.message).toContain("is not one this game was told about");
});

test("a bad integrity challenge throws at once, naming the character and what to do", () => {
  expect(() => platform.integrity.token()).toThrow('the argument "challenge" is missing');
  expect(() => platform.integrity.token(12345)).toThrow("must be a string");
  expect(() => platform.integrity.token("too-short")).toThrow("too short: 9 characters, it needs 16 to 500");
  expect(() => platform.integrity.token("a".repeat(501))).toThrow("too long: 501 characters");
  let message = "";
  try { platform.integrity.token("abcdefg+hijklmnopqrstuv=="); } catch (e) { message = e.message; }
  expect(message).toContain('platform.integrity.token("abcdefg+hijklmnopqrstuv==")');
  expect(message).toContain('the character "+" at position 8');
  expect(message).toContain("Make the challenge on your server");
  expect(game.platform.calls().some((c) => c.method === "integrity.token")).toBe(false); // nothing was sent
});

test("unknown services and events throw with a suggestion", () => {
  expect(() => platform.has("purchase")).toThrow('did you mean "purchases"');
  expect(() => platform.on("purchased", () => {})).toThrow('did you mean "purchase"');
  expect(() => platform.on("purchase")).toThrow("expects a function");
});

test("a store failure rejects with an Error that has code and hint", async () => {
  game.platform.respond("purchases.buy", { error: "network", message: "no route to the store", hint: "check the connection" });
  let caught;
  await platform.purchases.buy("gems_100").catch((e) => { caught = e; });
  expect(caught.code).toBe("network");
  expect(caught.hint).toBe("check the connection");
  expect(caught.message).toBe('platform.purchases.buy("gems_100") failed: no route to the store (hint: check the connection)');
  // Nothing was bought.
  expect(game.platform.state().fake.owned).toEqual([]);
});

test("not signed in rejects everything but signIn", async () => {
  game.platform.set({ signedIn: false });
  let code = "";
  await platform.achievements.unlock("first_win").catch((e) => { code = e.code; });
  expect(code).toBe("notSignedIn");
  expect((await platform.signIn()).signedIn).toBe(false);
  game.platform.set({ signedIn: true });
  expect((await platform.achievements.unlock("first_win")).unlocked).toBe(true);
});

test("a rejection somebody handles is no script error", async () => {
  game.platform.respond("stats.get", { error: "unknownId" });
  const p = platform.stats.get("wins");
  let code = "";
  try { await p; } catch (e) { code = e.code; }
  expect(code).toBe("unknownId");
});
)");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/errors.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 7);
    CHECK(h.scripts.errors().empty());
}

TEST_CASE("platform api: delayed answers arrive at the start of a frame, events reach listeners") {
    TestHost h("platform_delay", settings());
    h.file("tests/delay.test.js", R"(
import { test, expect, game } from "factoria:test";
import { platform } from "factoria";

test("delayFrames holds an answer until the frame it is due", () => {
  game.platform.set({ delayFrames: 2 });
  let status = "waiting";
  platform.purchases.buy("gems_100").then((r) => { status = r.status; });
  game.step(1);
  expect(status).toBe("waiting");
  expect(game.platform.state().pending).toBe(1);
  game.step(1);
  // The continuation of a promise is a microtask: it runs when the frame's jobs run.
  expect(status).toBe("purchased");
  expect(game.platform.state().pending).toBe(0);
  game.platform.set({ delayFrames: 0 });
});

test("emit reaches platform.on at the next step, and the listener can stop", () => {
  const seen = [];
  const off = platform.on("overlay", (e) => seen.push(e.open));
  game.platform.emit("overlay", { open: true });
  expect(seen).toEqual([]);
  game.step(1);
  expect(seen).toEqual([true]);
  game.platform.emit("overlay", { open: false });
  game.step(1);
  expect(seen).toEqual([true, false]);
  off();
  game.platform.emit("overlay", { open: true });
  game.step(1);
  expect(seen).toEqual([true, false]);
});

test("a purchase nobody listens for is kept for the first listener", () => {
  game.platform.emit("purchase", { productId: "gems_100" });
  game.step(1);
  const got = [];
  platform.on("purchase", (e) => got.push(e.transactionId));
  game.step(1);  // the kept event is delivered right after the registration, when the jobs run
  expect(got).toEqual(["fake-2"]);
});

test("the player event updates platform.player", () => {
  game.platform.emit("player", { id: "p9", name: "Zed", signedIn: true });
  game.step(1);
  expect(platform.player.name).toBe("Zed");
});

test("scripted answers are used in order", async () => {
  game.platform.respond("achievements.unlock", { error: "network" }, 2);
  game.platform.respond("achievements.unlock", { newly: false });
  const codes = [];
  for (let i = 0; i < 3; i++) {
    await platform.achievements.unlock("first_win").then((r) => codes.push("ok:" + r.newly), (e) => codes.push(e.code));
  }
  expect(codes).toEqual(["network", "network", "ok:false"]);
});

test("revoke takes a purchase back: restore forgets it and the refund event arrives", async () => {
  game.platform.reset();
  const bought = await platform.purchases.buy("remove_ads");
  await platform.purchases.finish(bought.transactionId);
  expect((await platform.purchases.restore()).length).toBe(1);
  const seen = [];
  platform.on("purchase", (e) => seen.push(e.status + " " + e.productId + " " + e.transactionId));
  game.platform.revoke("remove_ads");
  expect(seen).toEqual([]);
  game.step(1);
  expect(seen).toEqual(["revoked remove_ads " + bought.transactionId]);
  expect(await platform.purchases.restore()).toEqual([]);
  expect(() => game.platform.revoke("remove_ads")).toThrow("is not owned");
});

test("each test file starts with a fresh fake", () => {
  expect(game.platform.state().fake.calls.length > 0).toBe(true);
  game.platform.reset();
  expect(game.platform.state().fake.calls).toEqual([]);
});
)");
    h.file("tests/fresh.test.js", R"(
import { test, expect, game } from "factoria:test";
test("nothing carried over from the other file", () => {
  expect(game.platform.state().fake.calls).toEqual([]);
  expect(game.platform.state().fake.unfinished).toEqual([]);
});
)");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/delay.test.js", "tests/fresh.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 8);
}

TEST_CASE("platform api: a host without platform services reports the none backend and explains every call") {
    struct NoPlatformHost : TestHost {
        using TestHost::TestHost;
        PlatformServices* platform_services() override { return nullptr; }
    };
    NoPlatformHost h("platform_none", settings());
    REQUIRE(h.start());
    auto backend = h.scripts.eval("platform.backend");
    REQUIRE(backend.ok());
    CHECK(backend.value() == "none");
    CHECK(h.scripts.eval("platform.has('stats')").value() == false);
    auto call = h.scripts.eval("platform.achievements.unlock('first_win')");
    REQUIRE_FALSE(call.ok());
    CHECK(call.error().message.find("this run has no platform services") != std::string::npos);
    h.scripts.dispatch_platform();  // harmless
}

TEST_CASE("platform api: rewarded ads pay only when watched to the end, and the consent is readable") {
    TestHost h("platform_ads", settings());
    h.file("tests/ads.test.js", R"(
import { test, expect, game } from "factoria:test";
import { platform } from "factoria";

test("a watched ad pays", async () => {
  expect(platform.release).toBe(false);
  expect(platform.has("ads")).toBe(true);
  expect(await platform.ads.available("more_time")).toBe(true);
  expect(await platform.ads.showRewarded("more_time")).toEqual({ rewarded: true });
  expect(game.platform.state().fake.ads.rewarded).toBe(1);  // the first test of the file
  const call = game.platform.calls().filter((c) => c.method === "ads.showRewarded")[0];
  expect(call.args.placement).toBe("more_time");
  expect(call.args.adUnitId).toBe("more_time");
});

test("an ad closed early does not pay, and the default is back in the next test", async () => {
  const before = game.platform.state().fake.ads;
  game.platform.ad("closedEarly");
  expect(await platform.ads.showRewarded("more_time")).toEqual({ rewarded: false, reason: "closedEarly" });
  const after = game.platform.state().fake.ads;
  expect(after.rewarded).toBe(before.rewarded);
  expect(after.shown).toBe(before.shown + 1);
});

test("fresh fake after a test", async () => {
  expect((await platform.ads.showRewarded("more_time")).rewarded).toBe(true);
});

test("a refused consent shows nothing and says so", async () => {
  game.platform.ad("consentRefused");
  expect(await platform.ads.available("more_time")).toBe(false);
  expect(await platform.ads.showRewarded("more_time")).toEqual({ rewarded: false, reason: "consentRefused" });
  expect(await platform.ads.consent()).toEqual({ gdpr: "denied", tracking: "denied", canShowAds: false });
  game.platform.ad("watched", { gdpr: "notRequired", tracking: "notDetermined" });
  expect(await platform.ads.consent()).toEqual({ gdpr: "notRequired", tracking: "notDetermined", canShowAds: true });
  expect((await platform.ads.showRewarded("more_time")).rewarded).toBe(true);
});

test("no fill", async () => {
  game.platform.ad("noFill");
  expect(await platform.ads.available("double_coins")).toBe(false);
  expect(await platform.ads.showRewarded("double_coins")).toEqual({ rewarded: false, reason: "noFill" });
});

test("a scripted network error rejects", async () => {
  game.platform.respond("ads.showRewarded", { error: "network" });
  let code = "";
  await platform.ads.showRewarded("more_time").catch((e) => { code = e.code; });
  expect(code).toBe("network");
});

test("mistakes teach", () => {
  expect(() => platform.ads.showRewarded("more_tiem")).toThrow('did you mean "more_time"');
  expect(() => game.platform.ad("closedErly")).toThrow("closedEarly");
  expect(() => game.platform.ad("watched", { gdpr: "maybe" })).toThrow("granted");
});

test("the none backend answers unavailable", async () => {
  game.platform.set({ backend: "none" });
  expect(platform.has("ads")).toBe(false);
  let code = "";
  await platform.ads.showRewarded("more_time").catch((e) => { code = e.code; });
  expect(code).toBe("unavailable");
});
)");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/ads.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 8);
}

TEST_CASE("platform api: a daily leaderboard is empty again the next day, a weekly one the next week") {
    TestHost h("platform_periods", settings());
    h.file("tests/periods.test.js", R"(
import { test, expect, game } from "factoria:test";
import { platform } from "factoria";

test("daily board starts over with game.setDate", async () => {
  game.setDate("2026-10-23");
  expect((await platform.leaderboards.submit("daily_route", 90000)).best).toBe(90000);
  expect((await platform.leaderboards.submit("daily_route", 95000)).best).toBe(90000);  // ascending: lower is better
  let rows = await platform.leaderboards.entries("daily_route");
  expect(rows.length).toBe(1);
  expect(rows[0].score).toBe(90000);
  game.setDate("2026-10-24");
  expect(await platform.leaderboards.entries("daily_route")).toEqual([]);
  expect((await platform.leaderboards.submit("daily_route", 99000)).best).toBe(99000);
  game.setDate("2026-10-23");
  rows = await platform.leaderboards.entries("daily_route");
  expect(rows[0].score).toBe(90000);
  const call = game.platform.calls().filter((c) => c.method === "leaderboards.submit")[0];
  expect(call.args.period).toBe("daily");
  expect(call.args.periodKey).toBe("2026-10-23");
});

test("weekly board lasts Monday to Sunday", async () => {
  game.setDate("2026-10-19");  // a Monday
  await platform.leaderboards.submit("weekly_best", 10);
  game.setDate("2026-10-25");  // the Sunday of that week
  expect((await platform.leaderboards.entries("weekly_best")).length).toBe(1);
  expect(game.platform.calls().filter((c) => c.method === "leaderboards.entries").pop().args.periodKey).toBe("2026-10-19");
  game.setDate("2026-10-26");  // the next Monday
  expect(await platform.leaderboards.entries("weekly_best")).toEqual([]);
});

test("an all-time board does not care about the date", async () => {
  await platform.leaderboards.submit("high_score", 5);
  game.setDate("2027-01-01");
  expect((await platform.leaderboards.entries("high_score")).length).toBe(1);
  expect(game.platform.calls().pop().args.periodKey).toBe("");
});

test("the date is the test's again", async () => {
  expect((await platform.leaderboards.entries("daily_route")).length).toBe(0);
});
)");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/periods.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 4);
}
