// @ts-check
// The shop panel of the main menu (scenes/menu.scene.json), shown by the Shop button when the run has a store. It sells
// the products of factoria.json "platform.products": gems (a consumable) and "Remove ads" (a non-consumable). A purchase
// is granted first and finished after: the store keeps a purchase "unfinished" and hands it over again on the next run
// until finish() is called, so a crash between the two never loses what the player paid for.
import { Behaviour, ui, platform, storage, i18n } from "factoria";

/** What the player owns, kept in storage under "wallet". `seen` holds the transactions already granted. */
function wallet() {
  return { gems: 0, noAds: false, seen: [], ...storage.get("wallet", {}) };
}

export default class Shop extends Behaviour {
  /** Gems one "gems_100" purchase gives. */
  gemsPerPack = 100;

  onStart() {
    this.busy = false; // a purchase is waiting for the store: the buttons do nothing meanwhile
    this.status = this.world.find("shop_status").get("Text");
    ui.on("click", "buy_gems", () => this.buy("gems_100"));
    ui.on("click", "buy_remove_ads", () => this.buy("remove_ads"));
    ui.on("click", "restore", () => this.restore());
    // Purchases that finish outside buy(): a parent approves an "ask to buy", or the store hands over a purchase the last run left
    // unfinished.
    platform.on("purchase", (p) => p.status === "purchased" && this.grant(p).then(() => this.say(i18n.t("shop.arrived"))));
    this.refresh();
    i18n.on("change", () => this.refresh()); // the gems line is written by this script, not translated by the engine
    // The store's own titles and prices (already formatted for the player's country) go on the buttons.
    platform.purchases.products().then((list) => {
      for (const p of list) {
        const button = this.world.find(p.id === "gems_100" ? "buy_gems" : "buy_remove_ads");
        button.get("Button").text = `${p.title} - ${p.price}`;
      }
    }, () => {});
  }

  say(message) {
    this.status.text = message;
  }

  refresh() {
    const w = wallet();
    this.world.find("gems_label").get("Text").text = i18n.t(w.noAds ? "shop.gemsNoAds" : "shop.gems", { count: w.gems });
  }

  /** Gives the player what the purchase bought, once per transaction, then tells the store it is done. */
  async grant(purchase) {
    const w = wallet();
    if (!w.seen.includes(purchase.transactionId)) {
      if (purchase.productId === "gems_100") w.gems += this.gemsPerPack;
      if (purchase.productId === "remove_ads") w.noAds = true;
      w.seen.push(purchase.transactionId);
      storage.set("wallet", w);
      this.refresh();
    }
    await platform.purchases.finish(purchase.transactionId);
  }

  async buy(productId) {
    if (this.busy) return;
    this.busy = true;
    this.say(i18n.t("shop.waiting"));
    try {
      const r = await platform.purchases.buy(productId);
      if (r.status === "purchased") {
        const finished = this.grant(r); // the wallet changes at once; telling the store it is done may take a moment
        this.say(i18n.t("shop.thanks"));
        await finished;
      } else if (r.status === "pending") {
        this.say(i18n.t("shop.pending")); // the "purchase" event grants it
      } else {
        this.say(i18n.t("shop.cancelled"));
      }
    } catch (e) {
      // e.code is "network", "unavailable", "notSignedIn"...; e.hint says what to try.
      this.say(i18n.t("shop.unreachable", { code: e.code, detail: e.hint ?? e.message }));
    } finally {
      this.busy = false;
    }
  }

  async restore() {
    if (this.busy) return;
    this.busy = true;
    this.say(i18n.t("shop.asking"));
    try {
      const w = wallet();
      for (const owned of await platform.purchases.restore()) if (owned.productId === "remove_ads") w.noAds = true;
      storage.set("wallet", w);
      this.refresh();
      this.say(i18n.t(w.noAds ? "shop.restored" : "shop.nothingToRestore"));
    } catch (e) {
      this.say(i18n.t("shop.unreachable", { code: e.code, detail: e.hint ?? e.message }));
    } finally {
      this.busy = false;
    }
  }
}
