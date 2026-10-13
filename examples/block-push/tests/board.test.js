import { test, expect, game } from "factoria:test";
import { fa, ui } from "factoria";
import levels from "../levels/levels.json";

// Tiles are 64 px. Cell (col, row) of level 1 sits at world x = -192 + 64 * col, y = 128 - 64 * row.
const X = (col) => -192 + 64 * col;
const Y = (row) => 128 - 64 * row;
// The same cell in screen pixels (what clicks and touches use): the world origin is the centre of the 1280x720
// screen and +Y points down on screen.
/** @returns {[number, number]} */
const cell = (col, row) => [640 + X(col), 360 - Y(row)];

function player() {
  return game.world.findByTag("player")[0];
}
function box() {
  return game.world.findByTag("box")[0];
}
function hud() {
  return game.find("hud").get("Text").text;
}
function banner() {
  return game.find("banner").get("Text").text;
}
function bannerPanelWidth() {
  return game.find("banner_bg").get("Shape2D").size.x;
}
// game.load constructs the Board behaviour at once, but Board.onStart (which builds the level: the tiles, the boxes,
// the player, and the HUD text) runs on the first step. Every test below looks for those entities, so the helper
// steps one frame.
function load() {
  game.load("scenes/main.scene.json");
  game.step(1);
}

test("game.load creates the Board at once; its onStart builds the level on the first step", () => {
  game.load("scenes/main.scene.json");
  const board = game.find("board").behaviour;
  expect(board).not.toBeNull();
  expect(board.levelIndex).toBe(0);
  expect(game.world.findByTag("player").length).toBe(0); // onStart has not run yet
  expect(hud()).toBe("");
  game.step(1);
  expect(game.world.findByTag("player").length).toBe(1);
  expect(hud()).toContain("Level 1 of 3");
});

// Level 1 ("First push"): the player is at column 4, the box at column 3, the target at column 1.
test("one key press moves the player exactly one tile", () => {
  load();
  expect(player().position.x).toBeCloseTo(X(4), 3);
  game.tap("move_left");
  expect(player().position.x).toBeCloseTo(X(3), 3);
  expect(hud()).toContain("Moves: 1");
});

test("walking into a box pushes it one tile", () => {
  load();
  game.tap("move_left");
  expect(box().position.x).toBeCloseTo(X(2), 3);
  expect(box().position.y).toBeCloseTo(Y(2), 3);
  expect(player().position.x).toBeCloseTo(X(3), 3);
});

test("a wall blocks the player, and the blocked key is not a move", () => {
  load();
  game.tap("move_right"); // column 4 -> 5, open floor
  game.tap("move_right"); // column 5 -> 6 is the wall
  expect(player().position.x).toBeCloseTo(X(5), 3);
  expect(hud()).toContain("Moves: 1");
});

test("undo takes back the last move, push included", () => {
  load();
  game.tap("move_left");
  game.tap("undo");
  expect(player().position.x).toBeCloseTo(X(4), 3);
  expect(box().position.x).toBeCloseTo(X(3), 3);
  expect(hud()).toContain("Moves: 0");
});

test("R restarts the level from its start", () => {
  load();
  game.tap("move_left");
  game.tap("move_left");
  game.tap("restart");
  expect(player().position.x).toBeCloseTo(X(4), 3);
  expect(box().position.x).toBeCloseTo(X(3), 3);
  expect(hud()).toContain("Moves: 0");
  // the old pieces are removed with the level root, so only one player and one box remain
  expect(game.world.findByTag("player").length).toBe(1);
  expect(game.world.findByTag("box").length).toBe(1);
});

test("solving a level shows the banner, and Space starts the next level", () => {
  load();
  game.tap("move_left");
  game.tap("move_left"); // the box reaches the target
  expect(banner()).toContain("Level complete!");
  game.tap("confirm");
  expect(hud()).toContain("Level 2 of 3");
  expect(banner()).toBe("");
  // level 1 had one box; level 2 has two, and the old pieces are gone
  expect(game.world.findByTag("box").length).toBe(2);
  expect(game.world.findByTag("player").length).toBe(1);
});

test("undo also works after a solve, hides the banner, and the level can be solved again", () => {
  load();
  game.tap("move_left");
  game.tap("move_left");
  expect(banner()).toContain("Level complete!");
  game.tap("undo");
  expect(banner()).toBe("");
  expect(hud()).toContain("Moves: 1");
  game.tap("move_left");
  expect(banner()).toContain("Level complete!");
});

test("a click continues after a solved level", () => {
  load();
  game.tap("move_left");
  game.tap("move_left");
  game.click([640, 360]);
  expect(hud()).toContain("Level 2 of 3");
});

test("a box cannot be pushed into another box", () => {
  load();
  game.tap("move_left");
  game.tap("move_left");
  game.tap("confirm"); // level 2: the player is below a box that has another box above it
  expect(hud()).toContain("Level 2 of 3");
  game.tap("move_up");
  expect(hud()).toContain("Moves: 0");
});

test("a click on a neighbouring tile steps there; other clicks do nothing", () => {
  load();
  // Screen pixels: the centre of the screen is the world origin, +Y points down on screen.
  // The player is at world (64, 0). The box is at (0, 0), which is the tile to the left of the player.
  game.click([576, 360]); // world (-64, 0): two tiles away, so nothing happens
  expect(hud()).toContain("Moves: 0");
  game.click([640, 360]); // world (0, 0): the neighbour, so the player steps there and pushes the box
  expect(hud()).toContain("Moves: 1");
  expect(box().position.x).toBeCloseTo(X(2), 3);
});

// Touch. The board reads input.touches (a touch is `pressed` on its first frame only). game.touch* fills
// input.touches the way a finger does. On a phone the first finger also drives the mouse (see the device-tap test),
// so "continue after a solved level" is handled by the mouse branch and is covered by the click test above.
test("a tap on a neighbouring tile steps there and pushes the box", () => {
  load();
  game.touch(cell(3, 2)); // the box tile, left of the player
  expect(hud()).toContain("Moves: 1");
  expect(player().position.x).toBeCloseTo(X(3), 3);
  expect(box().position.x).toBeCloseTo(X(2), 3);
});

test("a tap on any other tile does nothing", () => {
  load();
  game.touch(cell(2, 2)); // two tiles away
  game.touch(cell(3, 1)); // diagonal
  game.touch(cell(4, 2)); // the player's own tile
  game.touch([5, 5]); // far outside the board
  expect(hud()).toContain("Moves: 0");
  expect(player().position.x).toBeCloseTo(X(4), 3);
  expect(box().position.x).toBeCloseTo(X(3), 3);
});

test("a tap on a wall tile is a blocked move", () => {
  load();
  game.touch(cell(5, 2)); // open floor, right of the player
  expect(hud()).toContain("Moves: 1");
  game.touch(cell(6, 2)); // the wall
  expect(hud()).toContain("Moves: 1");
  expect(player().position.x).toBeCloseTo(X(5), 3);
});

test("a swipe moves one tile: only the first frame of a touch counts", () => {
  load();
  game.touchStart(cell(3, 2)); // the finger lands on the tile next to the player
  game.step(1); // `pressed` frame: the player steps and pushes the box
  game.touchMove(cell(2, 2)); // drag over the next tiles while the finger stays down
  game.step(2);
  game.touchMove(cell(1, 2));
  game.step(2);
  game.touchEnd();
  game.step(1);
  expect(hud()).toContain("Moves: 1");
  expect(player().position.x).toBeCloseTo(X(3), 3);
  expect(box().position.x).toBeCloseTo(X(2), 3);
});

test("two taps solve level 1 and show the banner", () => {
  load();
  game.touch(cell(3, 2)); // player to column 3, box to column 2
  game.touch(cell(2, 2)); // player to column 2, box onto the target at column 1
  expect(banner()).toContain("Level complete!");
});

test("a device tap (the finger also presses the mouse in the same frame) moves exactly one tile", () => {
  load();
  game.touchStart(cell(3, 2));
  game.click(cell(3, 2)); // mouse button down for this frame, while the touch is fresh
  game.touchEnd();
  game.step(1);
  expect(hud()).toContain("Moves: 1");
  expect(player().position.x).toBeCloseTo(X(3), 3);
  expect(box().position.x).toBeCloseTo(X(2), 3);
});

// HUD and banner use anchor and pivot (screen space), so they stay glued to the corners and the centre on any
// aspect ratio. No absolute pixel position measured from a 1280x720 screenshot.
test("the HUD is pinned with anchor and pivot", () => {
  load();
  const vec = (v) => [v.x, v.y];
  const hudText = game.find("hud").get("Text");
  expect(hudText.space).toBe("screen");
  expect(vec(hudText.anchor)).toEqual([0, 0]); // top-left corner
  expect(vec(hudText.pivot)).toEqual([0, 1]); // the text box hangs from its own top-left
  const helpText = game.find("help").get("Text");
  expect(vec(helpText.anchor)).toEqual([0, 1]); // bottom-left corner
  expect(vec(helpText.pivot)).toEqual([0, 0]); // the text box stands on its own bottom-left
  expect(game.find("help").position.y).toBeLessThan(0); // an offset up from the bottom edge
  for (const id of ["banner", "banner_bg"]) {
    const e = game.find(id);
    const piece = e.has("Text") ? e.get("Text") : e.get("Shape2D");
    expect(piece.space).toBe("screen");
    expect(vec(piece.anchor)).toEqual([0.5, 0.5]); // the centre of the screen
    expect(vec(piece.pivot)).toEqual([0.5, 0.5]);
    expect(vec(e.position)).toEqual([0, 0]);
  }
});

test("every level has a valid layout (project.check_levels)", () => {
  const report = fa.call("project.check_levels", {});
  expect(report.errors).toBe(0);
  expect(report.ok).toBe(true);
  expect(report.levels.length).toBe(levels.length);
  expect(report.levels.map((l) => l.boxes)).toEqual([1, 2, 3]);
});

// The test imports the same levels.json module instance as the tool, so editing the level here is what the tool
// checks. The full report is error.data for `factoria call` and MCP; the Error that fa.call throws inside a script
// keeps the code, message and hint but not `data`, so this test reads the message.
test("a broken level makes project.check_levels fail, with the level and the problem in the message", () => {
  const saved = levels[1].map.slice();
  try {
    levels[1].map[3] = "#  $  #"; // level 2 loses a target: two boxes, one target
    let error = null;
    try {
      fa.call("project.check_levels", {});
    } catch (e) {
      error = e;
    }
    expect(error).not.toBeNull();
    expect(error.code).toBe("tool_error"); // an expected failure (ToolError), not a script bug
    expect(error.message).toContain("level 2 (Two crates)");
    expect(error.message).toContain("2 boxes ($) but 1 targets (.)");
    expect(error.hint).toContain("levels/levels.json");
  } finally {
    levels[1].map = saved;
  }
  expect(fa.call("project.check_levels", {}).ok).toBe(true); // restored
});

// Recorded solutions (found with a breadth-first search over the same rules).
const SOLUTIONS = [
  "LL", // level 1, 2 moves
  "LURLUURRDL", // level 2, 10 moves
  "LULLDRRRRDRUULUULLLDDLDRRRRLLDRR", // level 3, 32 moves
];
const KEYS = { L: "move_left", R: "move_right", U: "move_up", D: "move_down" };

test("all three levels can be solved, and the last one ends the game", () => {
  load();
  SOLUTIONS.forEach((moves, i) => {
    for (const m of moves) game.tap(KEYS[m]);
    expect(banner()).toContain(i === SOLUTIONS.length - 1 ? "All levels solved!" : "Level complete!");
    if (i < SOLUTIONS.length - 1) game.tap("confirm");
  });
  expect(hud()).toContain(`Moves: ${SOLUTIONS[2].length}`);
});

// The panel behind the banner is sized from ui.measureText (the same call the board makes). Headless runs measure
// with an approximation (0.6 x fontSize per character), so the test compares against the same call instead of
// a fixed number of pixels.
test("the banner panel is sized from the measured banner text", () => {
  load();
  for (const m of SOLUTIONS[0]) game.tap(KEYS[m]);
  expect(game.find("banner_bg").active).toBe(true);
  const text = game.find("banner").get("Text");
  const measured = ui.measureText(text.text, { fontSize: text.fontSize });
  const nextWidth = bannerPanelWidth();
  expect(nextWidth).toBeGreaterThan(measured.width); // wider than the longest line
  expect(game.find("banner_bg").get("Shape2D").size.y).toBeGreaterThan(measured.height);

  // The last level has shorter wording ("...to play again"), so its panel is narrower: the panel follows the text.
  game.tap("confirm");
  for (const m of SOLUTIONS[1]) game.tap(KEYS[m]);
  game.tap("confirm");
  for (const m of SOLUTIONS[2]) game.tap(KEYS[m]);
  expect(banner()).toContain("All levels solved!");
  const lastMeasured = ui.measureText(text.text, { fontSize: text.fontSize });
  expect(bannerPanelWidth()).toBeGreaterThan(lastMeasured.width);
  expect(bannerPanelWidth()).toBeLessThan(nextWidth);
});
