// @ts-check
// The online parts of the title screen (one entity of scenes/menu.scene.json): starts the services, shows the news, asks for the
// analytics consent the first time, shows the button prompts of the controller in use, and asks the server for the balance values.
//
//   news       `news_text` shows the newest item of the server's news (scripts/game/news.js); the last good answer is shown at once.
//   consent    `consent` (inactive card in the top-right corner): "Yes, send" / "No, thanks", shown (while the main menu shows) at every launch until one is
//              pressed. It does not take the focus or hide the menu: ignoring it is a no, nothing is sent.
//   hints      `hints` row: the picture of the button that selects and the one that goes back, for the pad that was used last
//              (scripts/game/glyphs.js); text only for a keyboard or a mouse.
//   boards     the Boards button itself is wired in main_menu.js (it opens the `boards` panel, scripts/ui/boards.js).
// Every answer that comes from a server is checked against this scene still being the current one before it is used.
import { Behaviour, ui, world, i18n } from "factoria";
import * as services from "./game/services.js";
import * as presence from "./game/presence.js";
import * as news from "./game/news.js";
import * as balance from "./game/balance.js";
import * as analytics from "./game/analytics.js";
import * as glyphs from "./game/glyphs.js";

export default class TitleOnline extends Behaviour {
  onStart() {
    services.start();
    presence.set({ kind: "menu" });
    this.hintKey = "";
    this.showNews(news.cached());
    news
      .refresh()
      .then((r) => this.entity.alive && this.showNews(r.items)) // the player may have left the title already
      .catch((e) => console.warn(`title: the news failed: ${e && e.message ? e.message : e}`));
    balance.refresh().catch((e) => console.warn(`title: the balance values failed: ${e && e.message ? e.message : e}`));
    if (!analytics.asked()) this.openConsent();
    ui.on("click", "consent_yes", () => this.answer(true));
    ui.on("click", "consent_no", () => this.answer(false));
    i18n.on("change", () => {
      this.showNews(this.items ?? []);
      presence.forget();
      presence.set(presence.current() ?? { kind: "menu" });
      this.hintKey = "";
    });
  }

  /** @param {Array<{title: string, body: string}>} items */
  showNews(items) {
    this.items = items;
    const text = world.find("news_text");
    const first = items[0];
    text.get("Text").text = first ? i18n.t("online.newsLine", { line: news.line(first) }) : "";
  }

  openConsent() {
    this.consentOpen = true; // a card in the corner: the menu keeps the focus, ignoring it is a no
    this.syncChrome();
  }

  /**
   * The corner card, the news line and the prompts belong to the main menu: they give way to Options, Boards and Credits.
   * At a big text size the card no longer fits in the corner next to the menu, so it takes the middle of the screen and the
   * menu waits behind it (parked) until the player answers or the size goes down again.
   */
  syncChrome() {
    const menu = world.find("main_menu");
    const card = world.find("consent");
    const big = ui.textScale > 1.25;
    const modal = !!this.consentOpen && big;
    if (modal && menu.active && !this.parked) {
      menu.active = false;
      this.parked = true;
      card.get("Panel").anchor = [0.5, 0.5];
      card.get("Panel").pivot = [0.5, 0.5];
      card.get("Transform").position = [0, 0, 0];
      world.find("consent_body").get("Text").maxWidth = 640;
      card.active = true;
      ui.layout();
      ui.focus("consent_yes");
    } else if (this.parked && !modal) {
      menu.active = true;
      this.parked = false;
      card.get("Panel").anchor = [1, 0];
      card.get("Panel").pivot = [1, 1];
      card.get("Transform").position = [-24, 24, 0];
      world.find("consent_body").get("Text").maxWidth = 326;
      if (this.consentOpen) ui.focus("play");
    }
    const main = menu.active || !!this.parked;
    card.active = main && !!this.consentOpen;
    world.find("news_text").active = menu.active;
    world.find("hints").active = main;
  }

  /** @param {boolean} yes */
  answer(yes) {
    analytics.setConsent(yes);
    this.consentOpen = false;
    this.syncChrome();
    ui.focus("play");
  }

  /** The prompts row, rebuilt when the device, the pad family or the language changes. */
  refreshHints() {
    const pick = glyphs.prompt("ui_submit");
    const back = glyphs.prompt("ui_cancel");
    const key = `${pick.device}|${pick.binding}|${back.binding}|${pick.family}|${i18n.language}`;
    if (key === this.hintKey) return;
    this.hintKey = key;
    const row = world.find("hints");
    for (const c of [...row.children]) c.destroy();
    for (const [p, label] of [[pick, "online.hintSelect"], [back, "online.hintBack"]]) {
      if (p.icon) world.spawn({ components: { Panel: { size: [32, 32], texture: p.icon, slice: [0, 0, 0, 0], color: [1, 1, 1, 1], layer: 12 } } }, { parent: row });
      const text = p.icon ? i18n.t(label) : i18n.t("online.hintLine", { button: p.label, action: i18n.t(label) });
      world.spawn({ components: { Text: { text, fontSize: 20, color: [0.8, 0.84, 0.92, 1], space: "screen", maxTextScale: 1.3, layer: 12 } } }, { parent: row });
    }
  }

  onUpdate() {
    this.syncChrome();
    this.refreshHints();
  }
}
