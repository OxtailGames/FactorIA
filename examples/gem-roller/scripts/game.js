// @ts-check
// Game manager: countdown timer, gem counter, HUD, win / lose screens, restart.
import { Behaviour, input, audio, scene, fa, game } from "factoria";

export default class Game extends Behaviour {
  timeLimit = 90;
  gemCount = 8;
  seed = 7;
  fallPenalty = 5;

  onStart() {
    this.timeLeft = this.timeLimit;
    this.gems = 0;
    this.status = "playing"; // "playing" | "won" | "lost"
    if (this.gemCount > 0) {
      const r = fa.call("project.scatter_gems", { count: this.gemCount, seed: this.seed, clear: true });
      this.total = r.placed;
    } else {
      this.total = this.world.findByTag("gem").length;
    }
    this.hudTime = this.world.find("hud_time");
    this.hudGems = this.world.find("hud_gems");
    this.msg = this.world.find("hud_msg");
    this.sub = this.world.find("hud_sub");
    this.overlay = this.world.find("overlay");
    this.ball = this.world.find("ball");

    this.world.on("gem_collected", () => {
      if (this.status !== "playing") return;
      this.gems++;
      if (this.gems >= this.total) this.win();
      this.refresh();
    });
    this.world.on("ball_fell", () => {
      if (this.status !== "playing") return;
      this.timeLeft = Math.max(0, this.timeLeft - this.fallPenalty);
      this.flash = 0.5;
    });
    this.refresh();
  }

  win() {
    this.status = "won";
    audio.play("assets/sfx/win.wav");
    this.show("YOU WIN!", `All ${this.total} gems collected   -   press R to play again`, [0.1, 0.4, 0.2, 0.55], [0.6, 1, 0.6, 1]);
    this.lockBall();
  }

  lose() {
    this.status = "lost";
    this.timeLeft = 0;
    audio.play("assets/sfx/lose.wav");
    this.show("TIME'S UP", `${this.gems}/${this.total} gems   -   press R to try again`, [0.4, 0.05, 0.05, 0.6], [1, 0.5, 0.45, 1]);
    this.lockBall();
  }

  lockBall() {
    const b = this.ball && this.ball.behaviour;
    if (b) b.enabledInput = false;
  }

  show(title, sub, panel, color) {
    this.msg.get("Text").text = title;
    this.msg.get("Text").color = color;
    this.sub.get("Text").text = sub;
    const c = this.overlay.get("Shape2D").color;
    c.r = panel[0]; c.g = panel[1]; c.b = panel[2]; c.a = panel[3];
    this.overlay.get("Shape2D").size = [game.screenSize.x, game.screenSize.y]; // the overlay is centred (anchor 0.5)
  }

  refresh() {
    this.hudTime.get("Text").text = `Time ${this.timeLeft.toFixed(1)}`;
    this.hudGems.get("Text").text = `Gems ${this.gems}/${this.total}`;
  }

  onFixedUpdate(dt) {
    if (this.status === "playing") {
      this.timeLeft -= dt;
      if (this.timeLeft <= 0) this.lose();
    }
    this.refresh();
  }

  onUpdate(dt) {
    if (this.flash > 0) {
      this.flash -= dt;
      const col = this.hudTime.get("Text").color;
      col.g = col.b = this.flash > 0 ? 0.3 : 1;
    }
    if (input.pressed("restart")) scene.reload();
  }
}
