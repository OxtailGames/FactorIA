// @ts-check
// The achievements screen (panel "achievements" of scenes/main.scene.json): every achievement of the catalog with its name and
// description in the player's language, unlocked ones first marked. It shows the union of the local save (scripts/services.js,
// always there, also offline) and what the store lists (platform.achievements.list(), e.g. unlocked on another device).
// ui_up / ui_down scroll the list.
import { Behaviour, world, input, i18n, platform } from "factoria";
import * as services from "../services.js";

export default class Achievements extends Behaviour {
  /** Scroll speed of ui_up / ui_down in pixels per second. */
  scrollSpeed = 500;

  onEnable() {
    this.remote = new Set();
    if (!this.offLanguage) this.offLanguage = i18n.on("change", () => this.entity.active && this.render());
    this.render();
    if (!platform.has("achievements")) return;
    const token = (this.token = (this.token ?? 0) + 1);
    platform.achievements
      .list()
      .then((list) => {
        if (token !== this.token || !this.entity.active) return;
        for (const a of list) if (a.unlocked) this.remote.add(a.id);
        this.render();
      })
      .catch(() => {}); // signed out or offline: the local list is shown
  }

  onDestroy() {
    this.offLanguage?.();
  }

  onUpdate(dt) {
    if (!this.entity.active) return;
    const list = world.find("achievements_list");
    if (list) list.get("ScrollList").scroll += input.axis("ui_up", "ui_down") * this.scrollSpeed * dt;
  }

  /** The rows: [{ id, name, description, unlocked }] in catalog order. */
  rows() {
    return services.ACHIEVEMENTS.map((id) => ({
      id,
      name: i18n.t(`ach.${id}.name`),
      description: i18n.t(`ach.${id}.desc`),
      unlocked: services.isUnlocked(id) || this.remote.has(id),
    }));
  }

  render() {
    const list = world.find("achievements_list");
    if (!list) return;
    for (const child of [...list.children]) child.destroy();
    const rows = this.rows();
    const n = rows.filter((r) => r.unlocked).length;
    const count = world.find("achievements_count");
    if (count) count.get("Text").text = i18n.t("ach.count", { unlocked: n, total: rows.length });
    for (const r of rows) {
      const text = `${r.unlocked ? "[x]" : "[ ]"}  ${r.name}\n${r.description}`;
      world.spawn(
        { components: { Text: { text, fontSize: 22, space: "screen", maxWidth: 640, layer: 302, color: r.unlocked ? [1, 0.88, 0.4, 1] : [0.6, 0.64, 0.72, 1] } } },
        { parent: list },
      );
    }
  }
}
