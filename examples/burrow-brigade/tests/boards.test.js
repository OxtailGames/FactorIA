// P5: the two leaderboards on the fake store: all-time best run cash, and the daily dig keyed by run.dailyKey.
import { test, describe, expect, game } from "factoria:test";
import * as events from "../scripts/game/events.js";
import * as boards from "../scripts/game/boards.js";
import { run, startRun } from "../scripts/game/run_state.js";
import { freshOnline, shift } from "./helpers/online.js";

const board = (id) => game.platform.state().fake.leaderboards[id];
const submitted = (id) => game.platform.calls().filter((c) => c.method === "leaderboards.submit" && c.args.id === id).map((c) => c.args.score);

describe("boards", () => {
  freshOnline();

  test("the catalog has an all-time and a daily board", () => {
    expect(game.platform.state().catalog.leaderboards).toEqual(["best_run_cash", "daily_run_cash"]);
  });

  test("a lift posts the run's cash to the all-time board; the next lift posts the sum of both", async () => {
    shift({ banked: 120 });
    await boards.idle();
    expect(submitted("best_run_cash")).toEqual([120]);
    shift({ banked: 80 });
    await boards.idle();
    expect(submitted("best_run_cash")).toEqual([120, 200]);
    expect(boards.status().runScore).toBe(200);
  });

  test("a shift in the dark or with everyone down posts nothing and adds nothing", async () => {
    shift({ banked: 0, outcome: "dark" });
    shift({ banked: 0, outcome: "allDown" });
    shift({ banked: 50 });
    await boards.idle();
    expect(submitted("best_run_cash")).toEqual([50]);
  });

  test("a new run starts the score again", async () => {
    shift({ banked: 300 });
    startRun({ seed: 11 });
    shift({ banked: 40 });
    await boards.idle();
    expect(submitted("best_run_cash")).toEqual([300, 40]);
    const rows = await boards.top("best_run_cash");
    expect(rows.length).toBe(1);
    expect(rows[0]).toMatchObject({ rank: 1, score: 300, isPlayer: true });
  });

  test("a normal run, or one that never set run.mode, does not touch the daily board", async () => {
    shift({ banked: 100 });
    delete run.mode;
    shift({ banked: 100 });
    await boards.idle();
    expect(submitted("daily_run_cash")).toEqual([]);
    expect(submitted("best_run_cash").length).toBe(2);
  });

  test("a daily dig posts to both boards, the daily one keyed by run.dailyKey", async () => {
    run.mode = "daily";
    run.dailyKey = "2026-10-25";
    const posted = [];
    events.on("boardPosted", (d) => posted.push(d));
    shift({ banked: 150 });
    await boards.idle();
    expect(submitted("best_run_cash")).toEqual([150]);
    expect(submitted("daily_run_cash")).toEqual([150]);
    expect(posted).toEqual([
      { board: "best_run_cash", score: 150, period: "allTime" },
      { board: "daily_run_cash", score: 150, period: "2026-10-25" },
    ]);
    expect(boards.status().lastPost.daily.best).toBe(150);
  });

  test("the daily board starts over each day; the all-time board does not", async () => {
    run.mode = "daily";
    run.dailyKey = "2026-10-25";
    shift({ banked: 150 });
    await boards.idle();
    game.setDate("2026-10-26");
    startRun({ seed: 12 });
    run.mode = "daily";
    run.dailyKey = "2026-10-26";
    shift({ banked: 60 });
    await boards.idle();
    expect((await boards.top("daily_run_cash")).map((r) => r.score)).toEqual([60]);
    expect((await boards.top("best_run_cash")).map((r) => r.score)).toEqual([150]);
  });

  test("a try that crossed midnight (its key a day before today) still posts; two days off: skipped and said so", async () => {
    run.mode = "daily";
    run.dailyKey = "2026-10-24";
    shift({ banked: 90 });
    await boards.idle();
    expect(submitted("daily_run_cash")).toEqual([90]);
    startRun({ seed: 13 });
    run.mode = "daily";
    run.dailyKey = "2026-10-23";
    shift({ banked: 70 });
    await boards.idle();
    expect(submitted("daily_run_cash")).toEqual([90]);
    expect(boards.status().lastPost.daily).toEqual({ skipped: "otherDay" });
    expect(submitted("best_run_cash")).toEqual([90, 70]);
  });

  test("a daily run without a valid dailyKey posts to the all-time board only", async () => {
    run.mode = "daily";
    run.dailyKey = "tomorrow";
    shift({ banked: 90 });
    await boards.idle();
    expect(submitted("daily_run_cash")).toEqual([]);
    expect(submitted("best_run_cash")).toEqual([90]);
  });

  test("top() answers [] when the store has no boards, and a failing store never throws into the game", async () => {
    game.platform.set({ backend: "none" });
    expect(await boards.top("best_run_cash")).toEqual([]);
    shift({ banked: 90 });
    await boards.idle();
    expect(game.platform.calls().length).toBe(0);
    game.platform.reset();
  });

  test("a score of zero is not posted", async () => {
    shift({ banked: 0 });
    await boards.idle();
    expect(submitted("best_run_cash")).toEqual([]);
    expect(board("best_run_cash")).toBeUndefined();
  });
});
