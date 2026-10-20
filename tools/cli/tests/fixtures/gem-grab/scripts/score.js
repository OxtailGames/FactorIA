import { Behaviour, scene } from "factoria";

export default class Score extends Behaviour {
  gems = 0;

  onStart() {
    this.total = this.world.findByTag("gem").length;
    this.world.on("gem_collected", () => {
      this.gems += 1;
      this.entity.get("Text").text = `Gems: ${this.gems} / ${this.total}`;
      if (this.gems === this.total) scene.load("scenes/win.scene.json");
    });
  }
}
