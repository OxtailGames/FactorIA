// The rewarded "more time" on the retry screen (scripts/more_time.js, scripts/ads.js, scripts/ad_stub.js): the stub ad, the
// skipped and the free path of "Remove ads", the once-per-attempt rule, a custom provider and the leaderboards.
import { test, describe, expect, game, beforeEach, afterEach } from "factoria:test";
import { Autoplay, YARD_ROUTE } from "./helpers/autoplay.js";
import * as ads from "../scripts/ads.js";
import * as store from "../scripts/store.js";
import * as svc from "../scripts/services.js";
import { StubAdProvider } from "../scripts/ad_stub.js";
import { fresh, cleanup, send, calls, record, loadYard, runDown } from "./helpers/store.js";

const flow = () => game.find("level").behaviour;
const spring = () => game.find("spring").behaviour;
const button = () => game.find("retry_more_time");
const retryUp = () => game.find("retry_panel").active;
const setup = () => {
  fresh();
  ads.setProvider(null);
  loadYard();
};

describe("the offer on the retry screen", () => {
  beforeEach(setup);
  afterEach(cleanup);

  test("when the spring runs down the retry screen offers 'Watch an ad' above Retry", () => {
    runDown();
    expect(retryUp()).toBe(true);
    expect(button().active).toBe(true);
    expect(button().get("Button").text).toContain("ad");
    expect(button().get("Button").text).toContain("20");
    const kids = game.find("retry_panel_box").children.map((c) => c.id);
    expect(kids.indexOf("retry_more_time")).toBeLessThan(kids.indexOf("retry_retry"));
  });

  test("a store without ads (backend none, no provider) shows no button", () => {
    game.platform.set({ backend: "none" });
    runDown();
    expect(retryUp()).toBe(true);
    expect(button().active).toBe(false);
    expect(ads.moreTimeOffer()).toEqual({ mode: "none" });
  });

  test("the button is not there while the level is being played", () => {
    expect(button().active).toBe(false);
  });
});

describe("the stub ad", () => {
  beforeEach(setup);
  afterEach(cleanup);

  test("the overlay counts down, then the reward can be claimed: +20 s and the courier carries on", () => {
    const log = record(["more_time_granted", "level_failed"]);
    runDown();
    const shown = StubAdProvider.shown;
    game.click("retry_more_time");
    game.step(3);
    expect(StubAdProvider.shown).toBe(shown + 1);
    expect(game.find("ad_overlay")).not.toBeNull();
    expect(retryUp()).toBe(false); // out of the way of the ad
    expect(game.find("ad_claim").active).toBe(false); // still counting down
    game.step(200);
    expect(game.find("ad_claim").active).toBe(true);
    game.click("ad_claim");
    game.step(5);
    expect(game.find("ad_overlay")).toBeNull();
    expect(retryUp()).toBe(false);
    expect(spring().left).toBeGreaterThan(18);
    expect(spring().left).toBeLessThanOrEqual(20);
    expect(flow().finished).toBe(false);
    expect(flow().continued).toBe(true);
    expect(game.find("courier").behaviour.locked).toBe(false);
    expect(log.filter((e) => e.name === "more_time_granted").map((e) => e.data.seconds)).toEqual([20]);
    expect(svc.stat("more_time_used")).toBe(1);
  });

  test("the courier can run again with the new time (the spring winds down once more)", () => {
    runDown();
    game.click("retry_more_time");
    game.step(200);
    game.click("ad_claim");
    game.step(5);
    const before = spring().left;
    game.step(120);
    expect(spring().left).toBeLessThan(before);
  });

  test("once per attempt: the next time the spring runs down there is no second offer", () => {
    runDown();
    game.click("retry_more_time");
    game.step(200);
    game.click("ad_claim");
    game.step(5);
    runDown();
    expect(retryUp()).toBe(true);
    expect(button().active).toBe(false);
  });

  test("Retry starts a new attempt with its own offer", () => {
    runDown();
    game.click("retry_more_time");
    game.step(200);
    game.click("ad_claim");
    game.step(5);
    runDown();
    game.click("retry_retry");
    game.step(30);
    runDown();
    expect(button().active).toBe(true);
  });

  test("skipping gives nothing: the retry screen comes back with the offer", () => {
    const log = record(["more_time_granted"]);
    runDown();
    game.click("retry_more_time");
    game.step(10);
    game.click("ad_skip");
    game.step(5);
    expect(game.find("ad_overlay")).toBeNull();
    expect(retryUp()).toBe(true);
    expect(button().active).toBe(true);
    expect(flow().finished).toBe(true);
    expect(log.length).toBe(0);
    expect(svc.stat("more_time_used")).toBe(0);
  });

  test("a second click while the ad is up does not show a second ad", () => {
    runDown();
    const shown = StubAdProvider.shown;
    game.click("retry_more_time");
    game.step(3);
    expect(StubAdProvider.shown).toBe(shown + 1);
    expect(flow().askingForTime).toBe(true);
  });
});

describe("Remove ads", () => {
  beforeEach(setup);
  afterEach(cleanup);

  test("with it the button is free: no overlay, no ad, still once per attempt", async () => {
    await store.grant({ productId: "remove_ads", transactionId: "t-ra" });
    const shown = StubAdProvider.shown;
    runDown();
    expect(button().active).toBe(true);
    expect(button().get("Button").text).toContain("free");
    game.click("retry_more_time");
    game.step(10);
    expect(game.find("ad_overlay")).toBeNull();
    expect(StubAdProvider.shown).toBe(shown);
    expect(spring().left).toBeGreaterThan(15);
    expect(flow().finished).toBe(false);
    runDown();
    expect(button().active).toBe(false);
  });

  test("it is also free on a store without ads: the player paid", async () => {
    await store.grant({ productId: "remove_ads", transactionId: "t-ra2" });
    game.platform.set({ backend: "none" });
    expect(ads.moreTimeOffer()).toEqual({ mode: "free" });
  });
});

describe("a provider of a real ad SDK", () => {
  beforeEach(setup);
  afterEach(cleanup);

  test("setProvider replaces the stub: its answer decides, the overlay never shows", () => {
    const asked = [];
    ads.setProvider({
      name: "fake sdk",
      available: () => true,
      showRewarded: (placement) => {
        asked.push(placement);
        return Promise.resolve({ rewarded: true });
      },
    });
    runDown();
    game.click("retry_more_time");
    game.step(10);
    expect(asked).toEqual(["more_time"]);
    expect(game.find("ad_overlay")).toBeNull();
    expect(flow().finished).toBe(false);
  });

  test("a provider that has no ad loaded hides the offer; one that fails gives the retry screen back", () => {
    ads.setProvider({ name: "empty", available: () => false, showRewarded: () => Promise.resolve({ rewarded: false, reason: "noFill" }) });
    runDown();
    expect(button().active).toBe(false);
    fresh();
    loadYard();
    ads.setProvider({ name: "broken", available: () => true, showRewarded: () => Promise.reject(new Error("sdk crashed")) });
    runDown();
    game.click("retry_more_time");
    game.step(10);
    expect(retryUp()).toBe(true);
    expect(flow().finished).toBe(true);
  });
});

describe("a continued run and the leaderboards", () => {
  beforeEach(setup);
  afterEach(cleanup);

  test("winning after the extra time is flagged, so its time stays off the boards", () => {
    const log = record(["level_completed"]);
    runDown();
    game.click("retry_more_time");
    game.step(200);
    game.click("ad_claim");
    game.step(5);
    expect(new Autoplay(game).run(YARD_ROUTE).reached).toBe(true);
    game.step(200);
    expect(log.length).toBe(1);
    expect(log[0].data.continued).toBe(true);
    expect(calls("leaderboards.submit").filter((c) => c.args.id.startsWith("time_")).length).toBe(0);
  });

  test("a normal win says continued false", () => {
    const log = record(["level_completed"]);
    expect(new Autoplay(game).run(YARD_ROUTE).reached).toBe(true);
    game.step(200);
    expect(log[0].data.continued).toBe(false);
  });

  test("the total of stars is still sent for a continued win", () => {
    game.load("scenes/rooftops_1.scene.json");
    game.step(10);
    send("level_completed", { level: "rooftops_1", time: 60, springLeft: 5, stars: 2, goals: {}, best: true, continued: true });
    expect(calls("leaderboards.submit").filter((c) => c.args.id === "total_stars").length).toBe(1);
    expect(calls("leaderboards.submit").filter((c) => c.args.id === "time_rooftops_1").length).toBe(0);
  });
});
