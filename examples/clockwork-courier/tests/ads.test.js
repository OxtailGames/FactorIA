// The rewarded "more time" on the retry screen (scripts/more_time.js, scripts/ads.js): the engine's test ad (game.platform.ad
// chooses how it ends), closed early, consent refused, no fill, the free path of "Remove ads", the once-per-attempt rule and
// the leaderboards.
import { platform } from "factoria";
import { test, describe, expect, game, beforeEach, afterEach } from "factoria:test";
import { Autoplay, YARD_ROUTE } from "./helpers/autoplay.js";
import * as ads from "../scripts/ads.js";
import * as store from "../scripts/store.js";
import * as svc from "../scripts/services.js";
import { fresh, cleanup, send, calls, record, loadYard, runDown } from "./helpers/store.js";

const flow = () => game.find("level").behaviour;
const spring = () => game.find("spring").behaviour;
const button = () => game.find("retry_more_time");
const shown = () => game.platform.state().fake.ads.shown;
const retryUp = () => game.find("retry_panel").active;
const setup = () => {
  fresh();
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

  test("a store without ads (backend none) shows no button", () => {
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

describe("the engine's test ad", () => {
  beforeEach(setup);
  afterEach(cleanup);

  test("watching the ad to the end pays: +20 s and the courier carries on", () => {
    const log = record(["more_time_granted", "level_failed"]);
    runDown();
    const before = shown();
    game.click("retry_more_time");
    game.step(5);
    expect(shown()).toBe(before + 1);
    expect(game.platform.calls().filter((c) => c.method === "ads.showRewarded").pop().args.placement).toBe("more_time");
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
    game.step(5);
    const before = spring().left;
    game.step(120);
    expect(spring().left).toBeLessThan(before);
  });

  test("once per attempt: the next time the spring runs down there is no second offer", () => {
    runDown();
    game.click("retry_more_time");
    game.step(5);
    runDown();
    expect(retryUp()).toBe(true);
    expect(button().active).toBe(false);
  });

  test("Retry starts a new attempt with its own offer", () => {
    runDown();
    game.click("retry_more_time");
    game.step(5);
    runDown();
    game.click("retry_retry");
    game.step(30);
    runDown();
    expect(button().active).toBe(true);
  });

  test("closing the ad early gives nothing: the retry screen comes back with the offer", () => {
    const log = record(["more_time_granted"]);
    runDown();
    game.platform.ad("closedEarly");
    game.click("retry_more_time");
    game.step(10);
    expect(retryUp()).toBe(true);
    expect(button().active).toBe(true);
    expect(flow().finished).toBe(true);
    expect(log.length).toBe(0);
    expect(svc.stat("more_time_used")).toBe(0);
  });

  test("a second click while the ad is up does not show a second ad", () => {
    runDown();
    game.platform.set({ delayFrames: 30 });
    const before = shown();
    game.click("retry_more_time");
    game.step(3);
    game.click("retry_more_time");
    game.step(60);
    expect(shown()).toBe(before + 1);
  });
});

describe("Remove ads", () => {
  beforeEach(setup);
  afterEach(cleanup);

  test("with it the button is free: no ad, still once per attempt", async () => {
    await store.grant({ productId: "remove_ads", transactionId: "t-ra" });
    const before = shown();
    runDown();
    expect(button().active).toBe(true);
    expect(button().get("Button").text).toContain("free");
    game.click("retry_more_time");
    game.step(10);
    expect(shown()).toBe(before);
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

describe("when no ad can be shown", () => {
  beforeEach(setup);
  afterEach(cleanup);

  test("no fill hides the offer", () => {
    game.platform.ad("noFill");
    runDown();
    expect(retryUp()).toBe(true);
    expect(button().active).toBe(false);
  });

  test("consent refused: the offer is hidden and nothing is granted", () => {
    game.platform.ad("consentRefused");
    runDown();
    expect(button().active).toBe(false);
    expect(flow().finished).toBe(true);
  });

  test("an ad the player refuses to finish after the offer shows gives the retry screen back", () => {
    runDown();
    game.platform.ad("consentRefused");
    game.click("retry_more_time");
    game.step(10);
    expect(retryUp()).toBe(true);
    expect(flow().finished).toBe(true);
    expect(svc.stat("more_time_used")).toBe(0);
  });

  test("the shipped game is not a development run: platform.release is false here", () => {
    expect(platform.release).toBe(false);
  });
});

describe("a continued run and the leaderboards", () => {
  beforeEach(setup);
  afterEach(cleanup);

  test("winning after the extra time is flagged, so its time stays off the boards", () => {
    const log = record(["level_completed"]);
    runDown();
    game.click("retry_more_time");
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
