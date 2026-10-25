// @ts-check
// One miner: walks the tunnels, digs the tile it faces while the dig button is held, picks up ore and oil, carries a lamp
// whose oil runs down, and steps on the exit lift. It reads its player record (players.js) and the live map (mine_map.js),
// so four of these run side by side in co-op without knowing about each other.
// The prefab prefabs/miner.prefab.json carries the Sprite; the lamp, the target cursor and the crack are created here.
import { Behaviour, world, audio } from "factoria";
import * as players from "./players.js";
import * as events from "./events.js";
import { live } from "./mine_map.js";
import { readInput } from "./miner_input.js";
import { K, TILE, kindInfo, spriteRegion, SPRITE } from "./tiles.js";
import { run, lampOf, addOre, totalOre } from "./run_state.js";

/** Walking speed in world units per second (4.5 tiles). */
export const WALK_SPEED = 72;
/** Half the size of the miner's collision box: it fits a one-tile tunnel with room to turn. */
export const HALF = 5.5;
/** Seconds of oil one second of light burns. */
export const OIL_DRAIN = 1;
/** Share of a full lamp one oil can refills. */
export const OIL_CAN = 0.4;
/** Light radius (world units) of a lamp that is nearly dry and of a full one. */
export const LAMP_MIN = 20;
export const LAMP_MAX = 96;

export default class Miner extends Behaviour {
  /** Id of the player (players.js) this miner belongs to. */
  playerId = 0;

  onStart() {
    this.player = players.get(this.playerId);
    if (!this.player) {
      console.warn(`miner: player ${this.playerId} is not in the registry (players.add() first); this miner does nothing.`);
      this.enabled = false;
      return;
    }
    this.sprite = this.entity.get("Sprite");
    this.entity.set("Sprite", { region: spriteRegion(SPRITE.MINER[this.playerId % 4]) });
    this.facing = { x: 1, y: 0 };
    this.digTarget = null; // {tx, ty} the tile being dug
    this.digProgress = 0; // 0..1 of that tile
    this.blockedKey = ""; // the tile whose "cannot dig" notice was already given
    this.stepClock = 0;
    this.walkClock = 0;
    this.lampLight = world.spawn({ components: { Transform: { position: [0, 2, 0] }, Light2D: { type: "point", color: this.player.color, intensity: 1, radius: LAMP_MAX, falloff: 1.5, height: 40 } } }, { parent: this.entity });
    this.ring = world.spawn({ components: { Transform: { position: [0, -7, 0] }, Shape2D: { shape: "diamond", size: [12, 5], color: [this.player.color[0], this.player.color[1], this.player.color[2], 0.55], layer: 9 } } }, { parent: this.entity });
    this.cursor = world.spawn({ components: { Transform: {}, Sprite: { texture: "assets/sprites.png", region: spriteRegion(SPRITE.CURSOR), size: [TILE, TILE], layer: 20, color: [1, 1, 1, 0.8], lit: true } } });
    this.crack = world.spawn({ components: { Transform: {}, Sprite: { texture: "assets/sprites.png", region: spriteRegion(SPRITE.CRACK[0]), size: [TILE, TILE], layer: 19, lit: true } } });
    this.cursor.active = false;
    this.crack.active = false;
    this.updateLamp(lampOf(this.playerId));
  }

  onDestroy() {
    // the cursor and the crack are not children (a child's flip and scale would move them): they leave with the miner
    this.cursor?.destroy();
    this.crack?.destroy();
  }

  /** The tile the miner stands on. */
  get tile() {
    return live.map ? live.map.tileAt(this.entity.position.x, this.entity.position.y) : { tx: 0, ty: 0 };
  }

  /** The tile the miner is facing, one probe past the edge of its box. */
  get target() {
    const p = this.entity.position;
    const reach = HALF + 2;
    return /** @type {import("./mine_map.js").MineMap} */ (live.map).tileAt(p.x + this.facing.x * reach, p.y + this.facing.y * reach);
  }

  onUpdate(dt) {
    const map = live.map;
    if (!map || !this.player) return;
    const lamp = lampOf(this.playerId);
    const playing = this.player.state === "active" || this.player.state === "lift";
    if (this.player.state === "down" || !run.inShift) {
      this.setDigVisuals(null, 0); // out of play, or the shift is over: the miner stands still
      this.updateLamp(lamp);
      return;
    }
    const inp = readInput(this.player);

    // walking
    const speed = WALK_SPEED * run.upgrades.walkSpeed;
    const p = this.entity.position;
    const moved = map.moveBox(p.x, p.y, HALF, HALF, inp.x * speed * dt, inp.y * speed * dt);
    p.x = moved.x;
    p.y = moved.y;
    const moving = Math.abs(inp.x) + Math.abs(inp.y) > 0.1;
    if (moving) {
      if (Math.abs(inp.x) >= Math.abs(inp.y)) this.facing = { x: Math.sign(inp.x), y: 0 };
      else this.facing = { x: 0, y: Math.sign(inp.y) };
      if (this.facing.x !== 0) this.sprite.flipX = this.facing.x < 0;
      this.walkClock += dt;
    }
    this.entity.transform.scale.y = moving ? 1 + 0.07 * Math.sin(this.walkClock * 16) : 1;

    // digging: hold the button facing a solid tile
    const t = this.target;
    const can = map.canDig(t.tx, t.ty, run.upgrades.pickTier);
    const solid = map.isSolid(t.tx, t.ty);
    const key = `${t.tx},${t.ty}`;
    if (!this.digTarget || this.digTarget.tx !== t.tx || this.digTarget.ty !== t.ty) {
      this.digTarget = { tx: t.tx, ty: t.ty };
      this.digProgress = 0;
    }
    if (inp.dig && solid && can.ok && this.player.state === "active") {
      this.digProgress += (dt * run.upgrades.pickSpeed) / kindInfo(map.kindAt(t.tx, t.ty)).digTime;
      this.stepClock -= dt;
      if (this.stepClock <= 0) {
        this.stepClock = 0.26;
        audio.play(this.digSoundFlip ? "assets/audio/dig.wav" : "assets/audio/dig2.wav", { volume: 0.5, bus: "sfx" });
        this.digSoundFlip = !this.digSoundFlip;
      }
      if (this.digProgress >= 1) this.finishDig(t.tx, t.ty);
    } else {
      this.digProgress = Math.max(0, this.digProgress - dt * 2); // an interrupted dig fills back in
      if (inp.dig && solid && !can.ok && this.blockedKey !== key && this.player.state === "active") {
        this.blockedKey = key;
        map.dig(t.tx, t.ty, { tier: run.upgrades.pickTier, by: this.playerId }); // refuses, and tells the bus why
        audio.play("assets/audio/blocked.wav", { volume: 0.6, bus: "sfx" });
      }
    }
    if (!inp.dig) this.blockedKey = "";
    this.setDigVisuals(solid ? t : null, this.digProgress);

    // what is under the feet
    const here = this.tile;
    const underfoot = map.kindAt(here.tx, here.ty);
    if (underfoot === K.OIL && playing) this.pickOil(here.tx, here.ty, lamp);
    if (this.player.state === "active" && underfoot === K.LIFT_EXIT) {
      players.setState(this.playerId, "lift");
      events.emit("liftReached", { player: this.playerId });
      audio.play("assets/audio/lift.wav", { volume: 0.7, bus: "sfx" });
    } else if (this.player.state === "lift" && underfoot !== K.LIFT_EXIT) {
      players.setState(this.playerId, "active"); // walked off the lift again
    }

    // the lamp burns while the miner is working
    if (this.player.state === "active" && run.inShift) this.burn(lamp, dt);
    this.updateLamp(lamp);
  }

  /** Dig time is up: the tile becomes floor, ore goes into the pockets. */
  finishDig(tx, ty) {
    const map = /** @type {import("./mine_map.js").MineMap} */ (live.map);
    const res = map.dig(tx, ty, { tier: run.upgrades.pickTier, by: this.playerId });
    this.digProgress = 0;
    if (!res.ok) return;
    this.puff(tx, ty, res.ore ? [1, 0.85, 0.3, 1] : res.kind === K.DIRT ? [0.7, 0.45, 0.28, 1] : [0.6, 0.65, 0.7, 1]);
    if (res.ore) {
      addOre(res.ore, 1);
      events.emit("orePicked", { ore: res.ore, value: res.value, by: this.playerId, total: totalOre() });
      audio.play("assets/audio/ore.wav", { volume: 0.7, bus: "sfx" });
    } else {
      audio.play("assets/audio/dug.wav", { volume: 0.6, bus: "sfx" });
    }
  }

  pickOil(tx, ty, lamp) {
    const map = /** @type {import("./mine_map.js").MineMap} */ (live.map);
    lamp.oil = Math.min(lamp.max, lamp.oil + lamp.max * OIL_CAN);
    lamp.out = false;
    if (lamp.oil > lamp.max * 0.25) lamp.low = false;
    map.setKind(tx, ty, K.FLOOR, "pickup");
    events.emit("oilPicked", { tx, ty, by: this.playerId, oil: lamp.oil });
    audio.play("assets/audio/oil.wav", { volume: 0.7, bus: "sfx" });
  }

  /** Burns oil; the lamp warns at a quarter and goes out at zero. */
  burn(lamp, dt) {
    if (lamp.out) return;
    lamp.oil = Math.max(0, lamp.oil - dt * OIL_DRAIN);
    if (!lamp.low && lamp.oil <= lamp.max * 0.25 && lamp.oil > 0) {
      lamp.low = true;
      events.emit("lampLow", { player: this.playerId, oil: lamp.oil });
    }
    if (lamp.oil <= 0) {
      lamp.out = true;
      events.emit("lampOut", { player: this.playerId });
      audio.play("assets/audio/lamp_out.wav", { volume: 0.8, bus: "sfx" });
    }
  }

  /** Light radius and strength follow the oil: a dry lamp gives no light at all. */
  updateLamp(lamp) {
    const f = lamp.max > 0 ? Math.max(0, Math.min(1, lamp.oil / lamp.max)) : 0;
    const radius = (LAMP_MIN + (LAMP_MAX - LAMP_MIN) * Math.pow(f, 0.6)) * run.upgrades.lampRadius;
    const light = this.lampLight.get("Light2D");
    light.radius = radius;
    light.intensity = Math.min(1, lamp.oil / 3); // the last three seconds fade out
    this.ring.active = this.player.state !== "down";
  }

  /** Shows the cursor on the faced solid tile and the crack that grows with the dig. */
  setDigVisuals(tile, progress) {
    const map = live.map;
    if (!tile || !map) {
      this.cursor.active = false;
      this.crack.active = false;
      return;
    }
    const c = map.tileCenter(tile.tx, tile.ty);
    this.cursor.active = true;
    this.cursor.position.x = c.x;
    this.cursor.position.y = c.y;
    if (progress > 0.04) {
      this.crack.active = true;
      this.crack.position.x = c.x;
      this.crack.position.y = c.y;
      this.crack.get("Sprite").region = spriteRegion(SPRITE.CRACK[Math.min(2, Math.floor(progress * 3))]);
    } else {
      this.crack.active = false;
    }
  }

  /** A few specks fly out of a dug tile (see puff.js). */
  puff(tx, ty, color) {
    const c = /** @type {import("./mine_map.js").MineMap} */ (live.map).tileCenter(tx, ty);
    for (let i = 0; i < 5; i++) {
      const a = ((i * 72 + ((tx * 31 + ty * 17) % 72)) * Math.PI) / 180;
      world.spawn({
        components: {
          Transform: { position: [c.x, c.y, 0] },
          Shape2D: { shape: "rectangle", size: [3, 3], color, layer: 30 },
          Script: { path: "scripts/game/puff.js", props: { vx: Math.cos(a) * 44, vy: Math.sin(a) * 44 + 12 } },
        },
      });
    }
  }
}
