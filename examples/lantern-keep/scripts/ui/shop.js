// @ts-check
// The shop panel of the main menu (prefabs/ui/shop.prefab.json): the two cosmetic packs of factoria.json
// "platform.products" and the lantern colour the player picks. A purchase is granted first and finished after
// (scripts/cosmetics.js grant()); a cancelled purchase or a store error shows a message and grants nothing.
// The store's own prices (already formatted for the player's country) go on the buttons.
import { Behaviour, ui, platform, i18n } from "factoria";
import { PRODUCTS, owns, grant, available, chosen, choose } from "../cosmetics.js";
import { explain } from "./store_ui.js";

const BUTTONS = { lantern_colours: "shop_buy_colours", supporter: "shop_buy_supporter" };

/** The size a Button takes: its design size, or what its label needs (what `autoSize` makes it, but now, not next frame). */
function buttonSize(entity, design) {
  const button = entity.get("Button");
  const m = ui.measureText(button.text, { fontSize: button.fontSize, maxWidth: button.maxWidth });
  return [Math.max(design[0], Math.ceil(m.width + 40)), Math.max(design[1], Math.ceil(m.height + 16))];
}

export default class Shop extends Behaviour {
  onStart() {
    this.design = new Map(); // design size of each Button, read before autoSize grows it
    for (const id of [...Object.values(BUTTONS), "shop_colour", "shop_restore", "shop_back"]) this.design.set(id, [...this.world.find(id).get("Button").size]);
    this.busy = false; // a request is waiting for the store: the buttons do nothing meanwhile
    this.prices = {}; // product id -> the store's price text
    this.noStore = !platform.has("purchases");
    this.message = null; // the last status: a function that writes it (so a language change can write it again)
    for (const id of PRODUCTS) {
      ui.on("click", BUTTONS[id], () => this.buy(id));
      this.world.find(BUTTONS[id]).get("Button").interactable = !this.noStore; // greyed out: there is nothing to buy from
    }
    ui.on("click", "shop_colour", () => this.nextColour());
    ui.on("click", "shop_restore", () => this.restore());
    // Purchases that finish outside buy(): a parent approves an "ask to buy", or the store hands over one the last run left unfinished.
    if (!this.noStore) {
      platform.on("purchase", (p) => {
        if (p.status === "purchased") grant(p).then(() => this.say(() => i18n.t("shop.arrived"))).then(() => this.refresh());
      });
      platform.purchases.products().then(
        (list) => {
          for (const p of list) this.prices[p.id] = p.price;
          this.refresh();
        },
        (e) => this.say(() => explain("purchases", "shop.what", e)),
      );
    }
    i18n.on("change", () => this.refresh());
    this.refresh();
    this.say(this.noStore ? () => explain("purchases", "shop.what") : null);
  }

  /** Every time the panel is shown: the text size may have changed. */
  onEnable() {
    this.refresh();
  }

  /** Shows a status line. `fn` returns the text, so it can be written again when the language changes. */
  say(fn) {
    this.message = fn;
    this.world.find("shop_status").get("Text").text = fn ? fn() : "";
    this.layout();
  }

  /** Writes the texts this script owns: buttons (name, price or "owned") and the colour choice. */
  refresh() {
    for (const id of PRODUCTS) {
      const button = this.world.find(BUTTONS[id]).get("Button");
      const name = i18n.t(`shop.product.${id}`);
      button.text = owns(id) ? i18n.t("shop.owned", { name }) : this.prices[id] ? i18n.t("shop.buy", { name, price: this.prices[id] }) : name;
    }
    const colour = this.world.find("shop_colour").get("Button");
    colour.text = i18n.t("shop.colour", { colour: i18n.t(`shop.colours.${chosen().id}`) });
    if (this.message) this.world.find("shop_status").get("Text").text = this.message();
    this.layout();
  }

  /**
   * One column while it fits the screen; at a big text size the title and the note stand beside the buttons and the status
   * (the note is the longest text of the game's screens, and it must stay readable, not scroll).
   */
  layout() {
    const cols = this.world.find("shop_cols").get("Panel");
    const note = this.world.find("shop_note").get("Text");
    const status = this.world.find("shop_status").get("Text");
    cols.layout = "column";
    note.maxWidth = status.maxWidth = 740;
    if (this.contentHeight(this.entity) + 24 > 720) {
      cols.layout = "row";
      const buttons = Object.values(BUTTONS).concat(["shop_colour", "shop_restore", "shop_back"]);
      const right = Math.max(...buttons.map((id) => buttonSize(this.world.find(id), this.design.get(id))[0])); // the buttons set the right column's width
      status.maxWidth = right;
      note.maxWidth = Math.max(360, Math.min(740, 1280 - 2 * 24 - 2 * 24 - 14 - right)); // the note takes what the buttons leave
    }
  }

  /** The height an entity takes in a column: a Text measured at the player's text size, a Button by its size, a panel by its children. */
  contentHeight(entity) {
    if (entity.has("Text")) {
      const t = entity.get("Text");
      return t.text ? ui.measureText(t.text, { fontSize: t.fontSize, maxWidth: t.maxWidth || 0 }).height : 0;
    }
    if (entity.has("Panel") && entity.get("Panel").layout !== "none") {
      const p = entity.get("Panel");
      const heights = entity.children.filter((c) => c.active).map((c) => this.contentHeight(c));
      if (!heights.length) return 0;
      const inner = p.layout === "row" ? Math.max(...heights) : heights.reduce((a, b) => a + b, 0) + p.spacing * (heights.length - 1);
      const [, top, , bottom] = p.padding; // left, top, right, bottom
      return inner + top + bottom;
    }
    return entity.has("Button") ? buttonSize(entity, this.design.get(entity.id) ?? [0, 0])[1] : 0;
  }

  nextColour() {
    const list = available();
    choose(list[(list.findIndex((c) => c.id === chosen().id) + 1) % list.length].id);
    this.refresh();
  }

  async buy(productId) {
    if (this.busy) return;
    if (owns(productId)) return this.say(() => i18n.t("shop.alreadyOwned"));
    this.busy = true;
    this.say(() => i18n.t("shop.waiting"));
    try {
      const r = await platform.purchases.buy(productId);
      if (r.status === "purchased") {
        const finished = grant(r); // what was bought is in the wallet at once; telling the store it is done may take a moment
        this.refresh();
        this.say(() => i18n.t("shop.thanks"));
        await finished;
      } else if (r.status === "pending") {
        this.say(() => i18n.t("shop.pending")); // the "purchase" event grants it
      } else {
        this.say(() => i18n.t("shop.cancelled"));
      }
    } catch (e) {
      this.say(() => explain("purchases", "shop.what", e) || i18n.t("shop.failed"));
    } finally {
      this.busy = false;
    }
  }

  async restore() {
    if (this.busy) return;
    if (this.noStore) return this.say(() => explain("purchases", "shop.what"));
    this.busy = true;
    this.say(() => i18n.t("shop.asking"));
    try {
      let granted = 0;
      for (const owned of await platform.purchases.restore()) {
        // A restored purchase is owned already: no transaction to finish.
        if (PRODUCTS.includes(owned.productId) && (await grant({ productId: owned.productId }))) granted += 1;
      }
      this.refresh();
      this.say(() => i18n.t(granted > 0 ? "shop.restored" : "shop.nothingToRestore"));
    } catch (e) {
      this.say(() => explain("purchases", "shop.what", e) || i18n.t("shop.failed"));
    } finally {
      this.busy = false;
    }
  }
}
