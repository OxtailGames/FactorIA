// @ts-check
// The flow of a game of Kindlewatch: three nights, each a little longer and hungrier than the last. During a night
// wolves come out of the forest; when the night ends the dawn drives them off, restocks the log piles and gives a heart
// back. Win: see the third dawn. Lose: the fire goes out, or the warden runs out of hearts.
//
// States (`state`): "intro" (the night banner), "night", "dawn", "won", "lost".
// Events it sends (world.emit): night_start {n}, dawn_start {n}, game_end {won, night, kills}, banner {key, args, seconds}.
// Events it listens to: wolf_down, fire_out, warden_down.
import { Behaviour, world, rng, ui, scene, audio } from "factoria";
import { ARENA, behaviourOf, flatDistance } from "./common.js";

/** The scene's night colours (the scene file's settings) and the colours the dawn turns them into. */
const NIGHT_SKY = { ambient: [0.17, 0.2, 0.34], sky: [0.03, 0.05, 0.14], horizon: [0.09, 0.12, 0.24], fog: [0.05, 0.07, 0.14] };
const DAWN_SKY = { ambient: [0.42, 0.38, 0.46], sky: [0.32, 0.4, 0.68], horizon: [0.95, 0.62, 0.45], fog: [0.5, 0.42, 0.5] };

export default class Game extends Behaviour {
  /**
   * The nights: length (seconds), burn (fuel per second the fire loses), interval (seconds between wolves), maxWolves
   * (wolves alive at once), alpha (the alpha comes at this second of the night, or -1).
   */
  nights = [
    { length: 45, burn: 1.7, interval: 7.5, maxWolves: 3, alpha: -1 },
    { length: 55, burn: 2.0, interval: 6, maxWolves: 4, alpha: -1 },
    { length: 65, burn: 2.3, interval: 5.5, maxWolves: 4, alpha: 10 },
  ];
  /** Seconds of the "Night n" banner before wolves come. */
  introTime = 3;
  /** Seconds of the dawn before the next night (or the end). */
  dawnTime = 5;
  /** No new wolf in the last seconds of a night. */
  quietTail = 6;

  onStart() {
    this.state = "intro";
    this.night = 1;
    this.timer = 0;
    this.spawnTimer = 3;
    this.kills = 0;
    this.nightKills = 0;
    this.alphaCalled = false;
    this.stateTime = 0;
    this.elapsed = 0;
    this.moon = world.find("moon");
    this.moonBase = this.moon ? this.moon.get("Light").intensity : 0.5;
    this.unsubscribes = [
      world.on("wolf_down", () => {
        this.kills++;
        this.nightKills++;
      }),
      world.on("fire_out", () => this.end(false, "fire")),
      world.on("warden_down", () => this.end(false, "hp")),
      ui.on("click", "retry", () => scene.reload()),
      ui.on("click", "to_menu", () => scene.load("scenes/menu.scene.json")),
    ];
    this.beginNight();
  }

  onDestroy() {
    for (const off of this.unsubscribes ?? []) off();
  }

  /** The numbers of the night being played. */
  get config() {
    return this.nights[Math.min(this.night, this.nights.length) - 1];
  }

  /** Seconds left of the night, or 0 outside a night. */
  get remaining() {
    return this.state === "night" ? Math.max(0, this.config.length - this.timer) : 0;
  }

  beginNight() {
    this.state = "intro";
    this.stateTime = 0;
    this.timer = 0;
    this.nightKills = 0;
    this.alphaCalled = false;
    this.spawnTimer = 2;
    const fire = behaviourOf("campfire");
    if (fire) fire.burnRate = 0;
    this.setMoon(0);
    world.emit("banner", { key: "game.night", args: { n: this.night, total: this.nights.length }, seconds: this.introTime });
    world.emit("night_start", { n: this.night });
  }

  onFixedUpdate(dt) {
    this.elapsed += dt;
    this.stateTime += dt;
    if (this.state === "intro") {
      if (this.stateTime >= this.introTime) {
        this.state = "night";
        this.timer = 0;
        const fire = behaviourOf("campfire");
        if (fire) fire.burnRate = this.config.burn;
      }
    } else if (this.state === "night") {
      this.timer += dt;
      const cfg = this.config;
      this.spawnTimer -= dt;
      const left = cfg.length - this.timer;
      if (this.spawnTimer <= 0 && left > this.quietTail && world.findByTag("wolf").length < cfg.maxWolves) {
        this.spawnWolf("wolf");
        this.spawnTimer = cfg.interval * rng.range(0.8, 1.2);
      }
      if (cfg.alpha >= 0 && !this.alphaCalled && this.timer >= cfg.alpha) {
        this.alphaCalled = true;
        this.spawnWolf("alpha");
        world.emit("banner", { key: "game.alpha", args: {}, seconds: 2.5 });
      }
      if (this.timer >= cfg.length) this.beginDawn();
    } else if (this.state === "dawn") {
      this.setMoon(Math.min(1, this.stateTime / this.dawnTime));
      if (this.stateTime >= this.dawnTime) {
        if (this.night >= this.nights.length) this.end(true, "dawn");
        else {
          this.night++;
          this.beginNight();
        }
      }
    }
  }

  beginDawn() {
    this.state = "dawn";
    this.stateTime = 0;
    const fire = behaviourOf("campfire");
    if (fire) fire.burnRate = 0;
    for (const w of world.findByTag("wolf")) w.behaviour?.flee();
    for (const p of world.findByTag("pile")) p.behaviour?.restock();
    behaviourOf("warden")?.heal();
    world.emit("banner", { key: "game.dawnComes", args: {}, seconds: this.dawnTime - 0.5 });
    world.emit("dawn_start", { n: this.night });
  }

  /** The moon light warms up and grows with the dawn (0 = night, 1 = full dawn). */
  setMoon(f) {
    if (!this.moon) return;
    const L = this.moon.get("Light");
    L.intensity = this.moonBase + 0.7 * f;
    L.color = [0.45 + 0.55 * f, 0.55 + 0.3 * f, 0.95 - 0.25 * f, 1];
    // The sky of the scene turns from navy to a pink-gold horizon (world.settings is the scene's SceneSettings).
    const mix = (a, b) => [a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f, a[2] + (b[2] - a[2]) * f, 1];
    const s = world.settings;
    s.ambientLight = mix(NIGHT_SKY.ambient, DAWN_SKY.ambient);
    s.skyColor = mix(NIGHT_SKY.sky, DAWN_SKY.sky);
    s.horizonColor = mix(NIGHT_SKY.horizon, DAWN_SKY.horizon);
    s.fogColor = mix(NIGHT_SKY.fog, DAWN_SKY.fog);
  }

  /** A wolf (or "alpha") comes out of the forest at a free spot of the clearing's edge. Returns the entity. */
  spawnWolf(kind, near) {
    const trees = world.findByTag("tree");
    let pos = [0, 0, 0];
    for (let i = 0; i < 12; i++) {
      const a = rng.range(0, Math.PI * 2);
      const r = near ? rng.range(1.5, 3) : ARENA - 2.5;
      const cx = near ? near.x : 0;
      const cz = near ? near.z : 0;
      const x = Math.max(-ARENA + 1, Math.min(ARENA - 1, cx + Math.cos(a) * r));
      const z = Math.max(-ARENA + 1, Math.min(ARENA - 1, cz + Math.sin(a) * r));
      pos = [x, 0.05, z];
      if (!trees.some((t) => Math.hypot(t.position.x - x, t.position.z - z) < 1.6)) break;
    }
    return world.spawnPrefab(kind === "alpha" ? "prefabs/alpha_wolf.prefab.json" : "prefabs/wolf.prefab.json", { position: pos });
  }

  /** The alpha's howl is answered: n wolves come running out of the forest. */
  callWolves(n) {
    for (let i = 0; i < n; i++) this.spawnWolf("wolf");
  }

  /** The game is over: won, or lost because of "fire" or "hp". */
  end(won, why) {
    if (this.state === "won" || this.state === "lost") return;
    this.state = won ? "won" : "lost";
    this.why = why;
    const fire = behaviourOf("campfire");
    if (fire) fire.burnRate = 0;
    const warden = behaviourOf("warden");
    if (warden) warden.locked = true;
    if (!won) for (const w of world.findByTag("wolf")) w.behaviour?.flee();
    world.emit("game_end", { won, why, night: this.night, kills: this.kills });
    // The panel comes up after a moment so the last thing that happened can be seen.
    const gen = scene.generation;
    this.after(won ? 1.5 : 1.2, () => {
      if (scene.generation !== gen) return;
      this.showEnd();
    });
  }

  showEnd() {
    const panel = world.find("end_panel");
    if (!panel) return;
    const won = this.state === "won";
    const title = world.find("end_title");
    const sub = world.find("end_sub");
    title.get("Text").key = won ? "game.won" : this.why === "fire" ? "game.lostFire" : "game.lostHp";
    sub.get("Text").key = won ? "game.wonSub" : "game.lostSub";
    sub.get("Text").keyArgs = { n: this.night, wolves: this.kills };
    panel.active = true;
    world.emit("end_panel_shown", { won });
  }
}
