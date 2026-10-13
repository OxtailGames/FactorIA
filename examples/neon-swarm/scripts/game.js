// @ts-check
// Game manager: waves, score, combo, HUD, explosions, screen shake, game over.
import { Behaviour, world, rng, vec2, vec3, audio, storage, scene, time, math } from "factoria";

const COSTS = { chaser: 1, shooter: 2, splitter: 3 };

export default class Game extends Behaviour {
  baseBudget = 4;        // enemy budget of wave 1
  budgetPerWave = 3;     // extra budget per wave
  intermission = 2.0;    // seconds between waves
  comboWindow = 2.5;     // seconds to keep a combo alive
  maxAlive = 14;

  wave = 0;
  score = 0;
  highScore = 0;
  combo = 0;
  multiplier = 1;
  comboTimer = 0;
  state = "intermission"; // intermission | fighting | over
  timer = 1.0;
  pending = [];
  spawnTimer = 0;
  shake = 0;
  kills = 0;
  spawned = 0;
  gameOverTimer = 0;

  onStart() {
    this.highScore = storage.get("highScore", 0);
    this.camera = world.find("camera");
    this.hud = {
      score: world.find("hud_score").get("Text"),
      best: world.find("hud_best").get("Text"),
      wave: world.find("hud_wave").get("Text"),
      combo: world.find("hud_combo").get("Text"),
      banner: world.find("hud_banner").get("Text"),
    };
    this.pips = [];
    for (let i = 0; i < 8; i++) this.pips.push(world.find("pip_" + i));
    this.world.on("enemy_killed", (d) => this.onKilled(d));
    this.world.on("enemy_hit", () => audio.play("assets/sfx/hit.wav", { volume: 0.3 }));
    this.world.on("player_hit", () => {
      this.shake = Math.max(this.shake, 14);
      this.combo = 0; this.multiplier = 1;
      audio.play("assets/sfx/hurt.wav", { volume: 0.7 });
    });
    this.updateHud();
  }

  difficulty() { return Math.min(1 + 0.05 * (this.wave - 1), 1.8); }

  startWave() {
    this.wave++;
    const budget = this.baseBudget + this.budgetPerWave * (this.wave - 1);
    const kinds = ["chaser"];
    if (this.wave >= 2) kinds.push("shooter");
    if (this.wave >= 3) kinds.push("splitter");
    let left = budget;
    this.pending = [];
    while (left > 0) {
      const k = rng.pick(kinds);
      if (COSTS[k] > left) { this.pending.push("chaser"); left -= 1; continue; }
      this.pending.push(k); left -= COSTS[k];
    }
    this.state = "fighting";
    this.spawnTimer = 0.3;
    this.hud.banner.text = "WAVE " + this.wave;
    this.bannerTime = 1.5;
    audio.play("assets/sfx/wave.wav", { volume: 0.6 });
  }

  spawnEnemy(kind) {
    const player = world.find("player");
    let pos;
    for (let i = 0; i < 8; i++) {
      const edge = rng.int(0, 3);
      const x = edge < 2 ? (edge === 0 ? -550 : 550) : rng.range(-550, 550);
      const y = edge >= 2 ? (edge === 2 ? -270 : 270) : rng.range(-270, 270);
      pos = vec2(x, y);
      if (!player || pos.distance(player.position) > 280) break;
    }
    const e = world.spawnPrefab("prefabs/" + kind + ".prefab.json", { position: vec3(pos.x, pos.y, 0) });
    this.spawned++;
    return e;
  }

  aliveEnemies() { return world.findByTag("enemy").length; }

  onUpdate(dt) {
    const player = world.find("player");
    if (this.state !== "over" && (!player || player.behaviour.hp <= 0)) this.gameOver();

    if (this.state === "intermission") {
      this.timer -= dt;
      if (this.timer <= 0) this.startWave();
    } else if (this.state === "fighting") {
      this.spawnTimer -= dt;
      if (this.pending.length && this.spawnTimer <= 0 && this.aliveEnemies() < this.maxAlive) {
        this.spawnEnemy(this.pending.shift());
        this.spawnTimer = Math.max(0.2, 0.9 - 0.05 * this.wave);
      }
      if (!this.pending.length && this.aliveEnemies() === 0) {
        this.state = "intermission";
        this.timer = this.intermission;
        this.score += 50 * this.wave; // wave clear bonus
      }
    } else if (this.state === "over") {
      this.gameOverTimer -= dt;
      if (this.gameOverTimer <= 0 && !this.leaving) { this.leaving = true; scene.load("scenes/gameover.scene.json"); }
    }

    if (this.comboTimer > 0) {
      this.comboTimer -= dt;
      if (this.comboTimer <= 0) { this.combo = 0; this.multiplier = 1; }
    }
    if (this.bannerTime > 0) { this.bannerTime -= dt; if (this.bannerTime <= 0) this.hud.banner.text = ""; }
    this.updateHud();
  }

  onLateUpdate(dt) {
    if (!this.camera) return;
    this.shake = Math.max(0, this.shake - 40 * dt);
    this.camera.position.x = this.shake > 0 ? rng.range(-this.shake, this.shake) : 0;
    this.camera.position.y = this.shake > 0 ? rng.range(-this.shake, this.shake) : 0;
  }

  onKilled(d) {
    this.kills++;
    this.combo++;
    this.multiplier = Math.min(8, 1 + Math.floor(this.combo / 4));
    this.comboTimer = this.comboWindow;
    this.score += d.points * this.multiplier;
    if (this.score > this.highScore) this.highScore = this.score;
    this.explode(d.x, d.y, d.color, d.big ? 50 : 24);
    this.shake = Math.max(this.shake, d.big ? 9 : 4);
    audio.play("assets/sfx/explode.wav", { volume: 0.5, pitch: d.big ? 0.7 : 1 });
  }

  explode(x, y, c, count) {
    const e = world.spawn({
      name: "Explosion",
      components: {
        Transform: { position: [x, y, 0] },
        ParticleEmitter: {
          emitting: true, rate: 0, burst: count, maxParticles: count, lifetime: 0.7, speed: 300, speedVariance: 0.5,
          direction: 0, spread: 180, gravity: [0, 0, 0], startSize: 16, endSize: 2,
          startColor: [c[0], c[1], c[2], 1], endColor: [c[0], c[1], c[2], 0], blend: "additive", layer: 20,
        },
      },
    });
    this.after(1.2, () => e.destroy());
  }

  gameOver() {
    this.state = "over";
    this.gameOverTimer = 1.0;
    const p = world.find("player");
    if (p) { this.explode(p.position.x, p.position.y, [0.3, 1, 1], 80); p.get("Shape2D").color.a = 0; }
    this.shake = 18;
    if (this.score > storage.get("highScore", 0)) storage.set("highScore", this.score);
    storage.set("lastScore", this.score);
    storage.set("lastWave", this.wave);
    audio.stopMusic(0.5);
    audio.play("assets/sfx/gameover.wav", { volume: 0.7 });
  }

  updateHud() {
    this.hud.score.text = "SCORE " + this.score;
    this.hud.best.text = "BEST " + this.highScore;
    this.hud.wave.text = "WAVE " + Math.max(1, this.wave);
    this.hud.combo.text = this.multiplier > 1 ? "COMBO x" + this.multiplier + "  (" + this.combo + ")" : "";
    const player = world.find("player");
    const hp = player ? player.behaviour.hp : 0;
    for (let i = 0; i < this.pips.length; i++) {
      const s = this.pips[i].get("Shape2D");
      s.color = i < hp ? [0.2, 1, 0.9, 1] : [0.15, 0.2, 0.25, 1];
    }
  }
}
