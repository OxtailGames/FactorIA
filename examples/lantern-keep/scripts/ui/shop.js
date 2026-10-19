// @ts-check
// The shop panel of the main menu (prefabs/ui/shop.prefab.json): the two cosmetic packs of factoria.json
// "platform.products" and the lantern colour the player picks. A purchase is granted first and finished after
// (scripts/cosmetics.js grant()); a cancelled purchase or a store error shows a message and grants nothing.
// The store's own prices (already formatted for the player's country) go on the buttons.
import { Behaviour, ui, platform, i18n } from "factoria";
import { PRODUCTS, owns, grant, available, chosen, choose } from "../cosmetics.js";
import { explain } from "./store_ui.js";

const BUTTONS = { lantern_colours: "shop_buy_colours", supporter: "shop_buy_supporter" };

export default class Shop extends Behaviour {
  onStart() {
    this.busy = false; // a request is waiting for the store: the buttons do nothing meanwhile
    this.prices = {}; // product id -> the store's price text
    this.noStore = !platform.has("purchases");
    this.message = null; // the last status: a function that writes it (so a language change can write it again)
    for (const id of PRODUCTS) ui.on("click", BUTTONS[id], () => this.buy(id));
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

  /** Shows a status line. `fn` returns the text, so it can be written again when the language changes. */
  say(fn) {
    this.message = fn;
    this.world.find("shop_status").get("Text").text = fn ? fn() : "";
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
  }

  nextColour() {
    const list = available();
    choose(list[(list.findIndex((c) => c.id === chosen().id) + 1) % list.length].id);
    this.refresh();
  }

  async buy(productId) {
    if (this.busy) return;
    if (this.noStore) return this.say(() => explain("purchases", "shop.what"));
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
