// @ts-check
// The achievements panel of the main menu (prefabs/ui/achievements.prefab.json): every achievement of factoria.json
// "platform.achievements" with its state and progress, as the store answers (platform.achievements.list()). It asks again
// each time the panel opens and on Refresh (which also signs in). Without a store, or when the store fails, it says so.
// ui_up/ui_down scroll the list.
import { Behaviour, ui, platform, input, i18n } from "factoria";
import { explain, trySignIn } from "./store_ui.js";

const GOLD = [1, 0.85, 0.4, 1];
const GREY = [0.75, 0.8, 0.9, 1];

export default class Achievements extends Behaviour {
  /** Scroll speed of ui_up/ui_down in pixels per second. */
  scrollSpeed = 500;

  rows = [];
  data = null; // the store's list, or null
  problem = null; // the rejection of the last request
  loads = 0;

  onStart() {
    ui.on("click", "ach_refresh", () => this.load(true));
    this.opened(); // the first time the panel is shown its script starts now; later the main menu calls opened()
    i18n.on("change", () => this.render()); // the lines are built here, not translated by the engine
  }

  /** The main menu calls this each time it shows the panel again (a hidden panel's scripts do not run): ask the store again. */
  opened() {
    this.load(false);
  }

  onUpdate(dt) {
    if (this.entity.active) this.list.get("ScrollList").scroll += input.axis("ui_up", "ui_down") * this.scrollSpeed * dt;
  }

  get list() {
    return this.world.find("ach_list");
  }

  async load(signIn) {
    const mine = ++this.loads;
    this.problem = null;
    this.data = null;
    if (platform.has("achievements")) {
      this.say(i18n.t("platform.loading"));
      try {
        if (signIn) await trySignIn();
        const data = await platform.achievements.list();
        if (mine === this.loads) this.data = data;
      } catch (e) {
        if (mine === this.loads) this.problem = e;
      }
    }
    if (mine === this.loads) this.render();
  }

  /** The line under the title: a message is shown only when there is one (an empty line would still take room). */
  say(message) {
    const status = this.world.find("ach_status");
    status.get("Text").text = message;
    status.active = message !== "";
  }

  render() {
    for (const row of this.rows) row.destroy();
    this.rows = [];
    const message = explain("achievements", "achievements.what", this.problem);
    const data = message ? null : this.data;
    this.say(message);
    const summary = this.world.find("ach_summary");
    summary.get("Text").text = data ? i18n.t("achievements.summary", { done: data.filter((a) => a.unlocked).length, total: data.length }) : "";
    summary.active = data !== null;
    for (const a of data ?? []) {
      const name = i18n.t(`achievements.${a.id}.name`);
      const description = i18n.t(`achievements.${a.id}.description`);
      const state = a.unlocked
        ? i18n.t("achievements.unlocked")
        : a.progress > 0
          ? i18n.t("achievements.progress", { percent: Math.floor(a.progress * 100) })
          : i18n.t("achievements.locked");
      this.rows.push(
        this.world.spawn(
          { components: { Text: { text: `${name}  -  ${state}\n${description}`, fontSize: 20, color: a.unlocked ? GOLD : GREY, space: "screen", maxWidth: 700, layer: 302 } } },
          { parent: this.list },
        ),
      );
    }
  }
}
