// The leaderboards screen (scripts/ui/leaderboards.js): every state it can be in, with the fake store signed in and out,
// slow, failing and absent, and the neighbours of the player's rank.
import { test, describe, expect, game, beforeEach, afterEach } from "factoria:test";
import * as progress from "../scripts/progress.js";
import { formatScore, BOARDS } from "../scripts/ui/leaderboards.js";
import { fresh, cleanup, loadTitle, calls, fake } from "./helpers/store.js";

const board = () => game.find("leaderboards").behaviour;
const status = () => game.find("board_status").get("Text").text;
const rows = () => game.find("board_list").children.map((c) => c.get("Text").text);
const open = () => {
  game.click("leaderboards_button");
  game.step(5);
};
const row = (rank, name, score, isPlayer = false) => ({ rank, name, score, isPlayer });
const setup = () => {
  fresh();
  loadTitle();
};

describe("opening the screen", () => {
  beforeEach(setup);
  afterEach(cleanup);

  test("the title button opens it on the first level's time and the back button closes it", () => {
    open();
    expect(game.find("leaderboards").active).toBe(true);
    expect(board().board.id).toBe("time_rooftops_1");
    game.click("board_back");
    game.step(3);
    expect(game.find("leaderboards").active).toBe(false);
  });

  test("the arrows walk over the 8 boards and wrap around", () => {
    open();
    expect(BOARDS.length).toBe(8);
    game.click("board_prev");
    game.step(3);
    expect(board().board.id).toBe("total_stars");
    game.click("board_next");
    game.step(3);
    expect(board().board.id).toBe("time_rooftops_1");
  });

  test("times show as m:ss.s and stars as a number", () => {
    expect(formatScore("time", 61250)).toBe("1:01.3");
    expect(formatScore("time", 42500)).toBe("0:42.5");
    expect(formatScore("stars", 12)).toBe("12");
  });
});

describe("states", () => {
  beforeEach(setup);
  afterEach(cleanup);

  test("empty: signed in with no score, says so", () => {
    open();
    expect(board().state).toBe("empty");
    expect(status()).toBe("Nobody has a score here yet. Win this level to be the first.");
    expect(calls("leaderboards.entries").length).toBeGreaterThan(0);
  });

  test("ready: the player's rank, the neighbours and the own row marked", () => {
    game.platform.respond("leaderboards.entries", {
      result: [row(11, "Ana", 40100), row(12, "Player", 42500, true), row(13, "Bo", 43900)],
    });
    open();
    expect(board().state).toBe("ready");
    expect(status()).toContain("12");
    expect(rows()).toEqual(["  #11   Ana   0:40.1", "> #12   Player   0:42.5", "  #13   Bo   0:43.9"]);
  });

  test("ready with the real fake store: a submitted score is the player's own row", () => {
    game.world.emit("level_completed", { level: "rooftops_1", time: 42.5, springLeft: 10, stars: 1, goals: {}, best: true });
    game.step(5);
    open();
    expect(fake().leaderboards.time_rooftops_1).toBe(42500);
    expect(board().state).toBe("ready");
    expect(rows().some((r) => r.startsWith(">") && r.includes("0:42.5"))).toBe(true);
  });

  test("the stars board shows plain numbers", () => {
    open();
    game.platform.respond("leaderboards.entries", { result: [row(1, "Player", 7, true)] });
    game.click("board_prev");
    game.step(3);
    expect(board().board.id).toBe("total_stars");
    expect(rows()[0]).toContain("Player   7");
  });

  test("loading: while the store is slow the screen says so, then the rows arrive", () => {
    game.platform.set({ delayFrames: 20 });
    game.platform.respond("leaderboards.entries", { result: [row(1, "Player", 50000, true)] });
    open();
    expect(board().state).toBe("loading");
    expect(status()).toBe("Loading...");
    game.step(30);
    expect(board().state).toBe("ready");
  });

  test("an old answer never overwrites the board the player moved to", () => {
    game.platform.set({ delayFrames: 10 });
    game.platform.respond("leaderboards.entries", { result: [row(1, "Old", 1000, true)] });
    open(); // first board asked, slow
    game.platform.respond("leaderboards.entries", { result: [row(1, "New", 2000, true)] });
    game.click("board_next");
    game.step(30);
    expect(rows().join("|")).toContain("New");
    expect(rows().join("|")).not.toContain("Old");
  });

  test("error: the message with the code and Try again, which asks again", () => {
    game.platform.respond("leaderboards.entries", { error: "network" });
    open();
    expect(board().state).toBe("error");
    expect(status()).toContain("network");
    expect(game.find("board_retry").active).toBe(true);
    game.platform.respond("leaderboards.entries", { result: [row(1, "Player", 50000, true)] });
    game.click("board_retry");
    game.step(5);
    expect(board().state).toBe("ready");
    expect(game.find("board_retry").active).toBe(false);
  });

  test("a store that forgot the player reads as signed out", () => {
    game.platform.respond("leaderboards.entries", { error: "notSignedIn" });
    open();
    expect(board().state).toBe("signedOut");
  });

  test("unavailable: a build without a store says there are no leaderboards", () => {
    game.platform.set({ backend: "none" });
    open();
    expect(board().state).toBe("unavailable");
    expect(status()).toContain("no leaderboards");
    expect(game.find("board_signin").active).toBe(false);
  });
});

describe("signed out", () => {
  afterEach(cleanup);
  beforeEach(() => {
    fresh();
    game.platform.set({ signedIn: false });
    loadTitle();
    game.platform.set({ signedIn: false });
  });

  test("explains it, shows the own best from the save and offers Sign in, which loads the board", () => {
    progress.record("rooftops_1", { time: 61.25, springLeft: 10, stars: 2, goals: {} });
    open();
    expect(board().state).toBe("signedOut");
    expect(status()).toContain("not signed in");
    expect(game.find("board_signin").active).toBe(true);
    expect(rows()[0]).toContain("1:01.3");
    game.platform.set({ signedIn: true });
    game.click("board_signin");
    game.step(10);
    expect(board().state).not.toBe("signedOut");
    expect(game.find("board_signin").active).toBe(false);
  });
});
