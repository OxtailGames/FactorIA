// @ts-check
// Ember Descent: a four-floor roguelike. Every floor is a new level that `tilemap.generate` grows from the one drawn in
// levels/sample.json (Wave Function Collapse), so the dungeon looks hand-made and is different on every run. The run seed
// decides all four floors: the same seed is the same dungeon, so R replays it and a stored seed shares it.
//
// The generator places the walls, the coins (o), the traps (x), the player (@) and the stairs (>): the last two are not
// in the sample, `constraints.place` puts them on the finished floor (the player on any floor cell, the stairs as far
// from it as a walk goes). This script adds what a rule decides: the moves, the lives and the score.
import { Behaviour, input, rng, ui, world, tilemap } from "factoria";

const FLOORS = 4;
const LIVES = 3;
const FLOOR_RETRIES = 3; // fresh seeds tried for one floor before the run gives up
const COIN_SCORE = 10;
const FLOOR_SCORE = 50;
const SIZE = [36, 18]; // cells of a floor: 1152 x 576 px, leaves room for the HUD above and the help below
const TILE = 32;
const SOLID_TILES = [0];
const BANNER_PAD_X = 48;
const BANNER_PAD_Y = 32;

/** [action, column step, row step]; row 0 is the top row. */
/** @type {[string, number, number][]} */
const MOVES = [
  ["move_left", -1, 0],
  ["move_right", 1, 0],
  ["move_up", 0, -1],
  ["move_down", 0, 1],
];

export default class Dungeon extends Behaviour {
  /** The run seed. The four floors' seeds are drawn from it, so one number is one whole dungeon. */
  runSeed = 2026;

  onStart() {
    this.hud = world.find("hud");
    this.banner = world.find("banner");
    this.bannerBg = world.find("banner_bg");
    this.newRun(this.runSeed);
  }

  onUpdate() {
    if (input.pressed("restart")) {
      this.newRun(this.runSeed); // the same dungeon again
      return;
    }
    if (this.state === "generating") {
      this.pollGeneration();
      return;
    }
    if (this.state === "won" || this.state === "lost" || this.state === "failed") {
      if (input.pressed("confirm") || input.mouse.pressed("left") || input.touches.some((t) => t.pressed)) {
        this.newRun(rng.create(this.runSeed).int(1, 2147483647)); // a new dungeon
      }
      return;
    }
    for (const [action, dx, dy] of MOVES) {
      if (input.pressed(action)) {
        this.step(dx, dy);
        return;
      }
    }
    if (input.mouse.pressed("left")) this.tapStep(input.mouse.world);
    for (const t of input.touches) if (t.pressed) this.tapStep(t.world);
  }

  /** Starts a run: draws the four floor seeds from `seed` and digs floor 1. */
  newRun(seed) {
    this.cancelGeneration();
    this.runSeed = seed;
    const draw = rng.create(seed);
    this.floorSeeds = [];
    for (let i = 0; i < FLOORS; i++) this.floorSeeds.push(draw.int(0, 2147483647));
    this.floorNumber = 1;
    this.floorRetries = 0;
    this.lives = LIVES;
    this.coins = 0;
    this.score = 0;
    this.startFloor();
  }

  /** Clears the previous floor and starts growing the next one; the frames it takes do not matter to the rules. */
  startFloor() {
    this.clearFloor();
    this.state = "generating";
    this.player = null;
    this.job = tilemap.generate({
      sample: "levels/sample.json",
      size: SIZE,
      seed: this.floorSeeds[this.floorNumber - 1],
      n: 3,
      maxAttempts: 40,
      constraints: {
        border: { tile: "#" },
        counts: [{ tile: "o", min: 4, max: 12 }, { tile: "x", max: 8 }],
        place: [
          { tile: "@", on: [".", ","] },
          { tile: ">", where: "farthest", from: "@", on: [".", ","] },
        ],
      },
      reachability: { allConnected: true, solidTiles: SOLID_TILES },
      place: {
        entity: "floor",
        tilemap: { tileset: "assets/tiles.png", tileSize: [TILE, TILE], solidTiles: SOLID_TILES },
        position: [(-SIZE[0] * TILE) / 2, (SIZE[1] * TILE) / 2],
        anchor: "top-left",
      },
    });
    this.showBanner("");
    this.refresh();
  }

  /** The generation is polled, not awaited: it dies with this behaviour, so a scene load cannot leave a stale callback. */
  pollGeneration() {
    const job = this.job;
    if (!job) return;
    if (job.error !== "") {
      this.job = null;
      // A seed whose floor will not grow within its attempts is rare: dig again from a seed drawn from it (still
      // deterministic: the same run seed retries the same way) before giving up on the run.
      if (this.floorRetries < FLOOR_RETRIES) {
        this.floorRetries++;
        const i = this.floorNumber - 1;
        this.floorSeeds[i] = rng.create(this.floorSeeds[i]).int(0, 2147483647);
        this.startFloor();
        return;
      }
      this.state = "failed";
      this.showBanner(`The floor would not grow: ${job.error}\nPress Space or click for another dungeon`);
      return;
    }
    if (!job.done) {
      this.refresh();
      return;
    }
    this.job = null;
    this.buildFloor();
  }

  /** The generator has placed the tiles, the coins, the traps, the player and the stairs: read where the player stands. */
  buildFloor() {
    this.floorRetries = 0;
    this.floor = world.find("floor");
    this.player = world.findByTag("player")[0];
    this.stairs = world.findByTag("stairs")[0];
    if (!this.floor || !this.player || !this.stairs) {
      this.state = "failed";
      this.showBanner("This floor has no player or stairs\nPress Space or click for another dungeon");
      return;
    }
    this.cell = this.cellOf(this.player);
    this.stairsCell = this.cellOf(this.stairs);
    this.state = "playing";
    this.refresh();
  }

  /** The [column, row] of the placed floor under an entity. */
  cellOf(entity) {
    const at = this.floor.tilemap.cellAt(entity.position);
    return [at.col, at.row];
  }

  /** The world point of the centre of a cell of the placed floor. */
  cellWorld(cell) {
    const p = world.find("floor").tilemap.cellToWorld(cell[0], cell[1]);
    return [p.x, p.y, 0];
  }

  isSolid(c, r) {
    return c < 0 || r < 0 || c >= SIZE[0] || r >= SIZE[1] || SOLID_TILES.includes(this.floor.tilemap.getTile(c, r));
  }

  /** The coin or trap entity standing in a cell, if any. */
  pickupAt(tag, c, r) {
    const floor = world.find("floor");
    if (!floor) return null;
    for (const e of world.findByTag(tag)) {
      const at = floor.tilemap.cellAt(e.position);
      if (at && at.col === c && at.row === r) return e;
    }
    return null;
  }

  /** Moves the player one cell and applies what is there. Returns false when a wall blocks the move. */
  step(dx, dy) {
    if (this.state !== "playing") return false;
    const c = this.cell[0] + dx;
    const r = this.cell[1] + dy;
    if (this.isSolid(c, r)) return false;
    this.cell = [c, r];
    const at = this.cellWorld(this.cell);
    this.player.position.x = at[0];
    this.player.position.y = at[1];
    const coin = this.pickupAt("coin", c, r);
    if (coin) {
      coin.destroy();
      this.coins++;
      this.score += COIN_SCORE;
    }
    const trap = this.pickupAt("trap", c, r);
    if (trap) {
      trap.destroy(); // a sprung trap is spent
      this.lives--;
      if (this.lives <= 0) {
        this.state = "lost";
        this.showBanner(`You fell on floor ${this.floorNumber}\nScore ${this.score}   seed ${this.runSeed}\nPress Space or click for a new dungeon, R to retry this one`);
      }
    }
    if (this.state === "playing" && c === this.stairsCell[0] && r === this.stairsCell[1]) this.descend();
    this.refresh();
    return true;
  }

  descend() {
    this.score += FLOOR_SCORE;
    if (this.floorNumber >= FLOORS) {
      this.state = "won";
      this.showBanner(`You reached the bottom!\nScore ${this.score}   seed ${this.runSeed}\nPress Space or click for a new dungeon, R to play this one again`);
      return;
    }
    this.floorNumber++;
    this.startFloor();
  }

  /** A tap or click beside the player steps that way (the stronger axis of the offset). */
  tapStep(p) {
    if (this.state !== "playing") return;
    const here = world.find("floor").tilemap.cellToWorld(this.cell[0], this.cell[1]);
    const dx = p.x - here.x;
    const dy = here.y - p.y;
    if (Math.abs(dx) >= Math.abs(dy)) this.step(dx >= 0 ? 1 : -1, 0);
    else this.step(0, dy >= 0 ? 1 : -1);
  }

  /** Drops the floor's entities: the tilemap, its coins and traps, the player and the stairs. */
  clearFloor() {
    for (const e of [...world.findByTag("coin"), ...world.findByTag("trap"), ...world.findByTag("player"), ...world.findByTag("stairs")]) e.destroy();
    const floor = world.find("floor");
    if (floor) floor.destroy();
    this.player = null;
    this.stairs = null;
  }

  cancelGeneration() {
    if (this.job) this.job.cancel();
    this.job = null;
  }

  onDestroy() {
    this.cancelGeneration();
  }

  showBanner(text) {
    this.banner.get("Text").text = text;
    this.bannerBg.active = text !== "";
    if (text === "") return;
    const t = this.banner.get("Text");
    const m = ui.measureText(t.text, { fontSize: t.fontSize, font: t.font });
    this.bannerBg.get("Shape2D").size = [Math.ceil(m.width) + 2 * BANNER_PAD_X, Math.ceil(m.height) + 2 * BANNER_PAD_Y];
  }

  refresh() {
    let line = `Floor ${this.floorNumber} of ${FLOORS}   Lives ${this.lives}   Coins ${this.coins}   Score ${this.score}`;
    if (this.state === "generating" && this.job) line += `\nDigging floor ${this.floorNumber}... ${Math.round(this.job.progress * 100)}%`;
    this.hud.get("Text").text = line;
  }
}
