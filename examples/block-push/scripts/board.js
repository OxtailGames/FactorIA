// @ts-check
// The Sokoban board. Reads the level text from levels/levels.json, spawns every tile, box and
// the player as entities, and applies the rules: push, undo, restart, click-to-step and
// level complete.
import { Behaviour, input, ui, world } from "factoria";
import levels from "../levels/levels.json";

const MAX_TILE = 64; // largest cell size, in design pixels
const AREA_W = 1180; // room the board may take, in design pixels
const AREA_H = 540;
const BANNER_PAD_X = 48; // margin between the banner text and the edge of its panel, in design pixels
const BANNER_PAD_Y = 32;

const COLOR = {
  floor: [0.13, 0.15, 0.22, 1],
  wall: [0.4, 0.45, 0.6, 1],
  goal: [0.3, 0.9, 0.85, 1],
  box: [0.9, 0.58, 0.26, 1],
  boxOnGoal: [0.45, 0.88, 0.48, 1],
  player: [0.98, 0.86, 0.3, 1],
};

// [action, column step, row step]. Row 0 is the top row, so "up" is -1 in rows.
/** @type {[string, number, number][]} */
const MOVES = [
  ["move_left", -1, 0],
  ["move_right", 1, 0],
  ["move_up", 0, -1],
  ["move_down", 0, 1],
];

export default class Board extends Behaviour {
  /** Index into levels to start from. Override in the scene via Script.props. */
  levelIndex = 0;

  onStart() {
    this.hud = world.find("hud");
    this.banner = world.find("banner");
    this.bannerBg = world.find("banner_bg");
    this.loadLevel(this.levelIndex);
  }

  onUpdate() {
    if (input.pressed("restart")) {
      this.loadLevel(this.levelIndex);
      return;
    }
    if (input.pressed("undo")) {
      this.undo();
      return;
    }
    if (this.complete) {
      if (input.pressed("confirm") || input.mouse.pressed("left")) {
        this.loadLevel((this.levelIndex + 1) % levels.length);
      }
      return;
    }
    for (const [action, dx, dy] of MOVES) {
      if (input.pressed(action)) {
        this.step(dx, dy);
        return;
      }
    }
    if (input.mouse.pressed("left")) this.clickCell(input.mouse.world);
    for (const t of input.touches) {
      if (t.pressed) this.clickCell(t.world);
    }
  }

  /** Builds level `index` from its text map, replacing whatever was on the board. */
  loadLevel(index) {
    const rows = levels[index].map;
    this.levelIndex = index;
    this.w = Math.max(...rows.map((r) => r.length));
    this.h = rows.length;
    this.tile = Math.min(MAX_TILE, Math.floor(Math.min(AREA_W / this.w, AREA_H / this.h)));
    // World position of the centre of cell (0, 0). The board is centred on the screen.
    this.x0 = (-(this.w - 1) * this.tile) / 2;
    this.y0 = ((this.h - 1) * this.tile) / 2;

    if (this.root) this.root.destroy(); // removes every piece of the previous level
    this.root = world.spawn({ name: "Level", components: { Transform: { position: [0, 0, 0] } } });

    this.wall = [];
    this.goal = [];
    this.boxes = [];
    this.player = null;
    for (let y = 0; y < this.h; y++) {
      this.wall.push([]);
      this.goal.push([]);
      for (let x = 0; x < this.w; x++) {
        const c = rows[y][x] ?? " ";
        this.wall[y][x] = c === "#";
        this.goal[y][x] = c === ".";
        if (c === "#") {
          this.spawnTile(x, y, this.tile, COLOR.wall, 2, "wall");
          continue;
        }
        this.spawnTile(x, y, this.tile - 4, COLOR.floor, 0, "floor");
        if (c === ".") this.spawnTile(x, y, this.tile * 0.36, COLOR.goal, 1, "goal");
        if (c === "$") {
          const e = this.spawnTile(x, y, this.tile - 12, COLOR.box, 3, "box", ["box"]);
          this.boxes.push({ x, y, e });
        }
        if (c === "@") {
          const e = this.spawnTile(x, y, this.tile - 20, COLOR.player, 4, "player", ["player"], "circle");
          this.player = { x, y, e };
        }
      }
    }
    if (!this.player) throw new Error(`level ${index + 1} has no player (@); run project.check_levels`);

    this.history = [];
    this.settle();
  }

  spawnTile(x, y, size, color, layer, name, tags = [], shape = "rectangle") {
    return world.spawn(
      {
        name,
        tags,
        components: {
          Transform: { position: [this.cellX(x), this.cellY(y), 0] },
          Shape2D: { shape, size: [size, size], color, layer },
        },
      },
      { parent: this.root },
    );
  }

  cellX(x) {
    return this.x0 + x * this.tile;
  }

  cellY(y) {
    return this.y0 - y * this.tile;
  }

  isWall(x, y) {
    return x < 0 || y < 0 || x >= this.w || y >= this.h || this.wall[y][x];
  }

  boxAt(x, y) {
    return this.boxes.find((b) => b.x === x && b.y === y) ?? null;
  }

  /** Moves the player one cell, pushing a box if one is in the way. Returns false if blocked. */
  step(dx, dy) {
    if (this.complete) return false;
    const nx = this.player.x + dx;
    const ny = this.player.y + dy;
    if (this.isWall(nx, ny)) return false;
    const box = this.boxAt(nx, ny);
    const bx = nx + dx;
    const by = ny + dy;
    if (box && (this.isWall(bx, by) || this.boxAt(bx, by))) return false;

    this.history.push({ px: this.player.x, py: this.player.y, boxes: this.boxes.map((b) => [b.x, b.y]) });
    if (box) {
      box.x = bx;
      box.y = by;
    }
    this.player.x = nx;
    this.player.y = ny;
    this.settle();
    return true;
  }

  /** Takes back the last move (a push is undone with the move). */
  undo() {
    const s = this.history.pop();
    if (!s) return false;
    this.player.x = s.px;
    this.player.y = s.py;
    this.boxes.forEach((b, i) => {
      b.x = s.boxes[i][0];
      b.y = s.boxes[i][1];
    });
    this.settle();
    return true;
  }

  /** A click on a neighbouring cell steps there (pushing a box if one is in that cell). */
  clickCell(p) {
    const col = Math.round((p.x - this.x0) / this.tile);
    const row = Math.round((this.y0 - p.y) / this.tile);
    const dx = col - this.player.x;
    const dy = row - this.player.y;
    if (Math.abs(dx) + Math.abs(dy) === 1) this.step(dx, dy);
  }

  /** Recomputes the level-complete state, shows or hides the banner, and refreshes everything. */
  settle() {
    this.complete = this.boxes.every((b) => this.goal[b.y][b.x]);
    this.bannerBg.active = this.complete;
    const last = this.levelIndex === levels.length - 1;
    let text = "";
    if (this.complete) {
      text = last ? "All levels solved!\nPress Space or click to play again" : "Level complete!\nPress Space or click for the next level";
    }
    this.banner.get("Text").text = text;
    if (text !== "") this.fitBannerPanel();
    this.refresh();
  }

  /**
   * Sizes the dark panel behind the banner from the measured banner text, so it always has the same margin
   * around the longest line whatever the wording, the font size or the font. The panel and the text are both
   * centred on the screen (anchor [0.5, 0.5] in the scene), so only the size needs to be set.
   */
  fitBannerPanel() {
    const text = this.banner.get("Text");
    const m = ui.measureText(text.text, { fontSize: text.fontSize, font: text.font });
    this.bannerBg.get("Shape2D").size = [Math.ceil(m.width) + 2 * BANNER_PAD_X, Math.ceil(m.height) + 2 * BANNER_PAD_Y];
  }

  /** Copies the rules state onto the entities: positions, box colours and the HUD text. */
  refresh() {
    const place = (e, x, y) => {
      const pos = e.position;
      pos.x = this.cellX(x);
      pos.y = this.cellY(y);
    };
    place(this.player.e, this.player.x, this.player.y);
    for (const b of this.boxes) {
      place(b.e, b.x, b.y);
      b.e.set("Shape2D", { color: this.goal[b.y][b.x] ? COLOR.boxOnGoal : COLOR.box });
    }
    const name = levels[this.levelIndex].name;
    this.hud.get("Text").text = `Level ${this.levelIndex + 1} of ${levels.length}: ${name}\nMoves: ${this.history.length}`;
  }
}
