import { test, expect, game } from "factoria:test";
import { fa } from "factoria";

// Tiles are 64 px. Cell (col, row) of level 1 sits at world x = -192 + 64 * col, y = 128 - 64 * row.
const X = (col) => -192 + 64 * col;
const Y = (row) => 128 - 64 * row;

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
// The board builds the level in its first update, so run one frame after loading the scene.
function load() {
  game.load("scenes/main.scene.json");
  game.step(1);
}

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

test("every level has a valid layout (project.check_levels)", () => {
  const report = fa.call("project.check_levels", {});
  expect(report.errors).toBe(0);
  expect(report.ok).toBe(true);
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
