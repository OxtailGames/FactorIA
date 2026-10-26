// @ts-check
// TradeUi: the screens of the trade (P5) and the glue between the trade logic (trade.js) and the game screen.
//
//   - turns the trade on for the scenario of the scene (scene prop `scenario`; `trade: false` keeps it off, as the test map does),
//   - draws the ships (ShipView), tells the store about achievements (StoreBridge),
//   - the HUD: one reputation item in the top bar (controller.addHudItem) and an Orders button under it (key O),
//   - the order board (prefabs/ui/order_board.prefab.json): one row per ship with its order, a Fill order button,
//   - the event / story card (prefabs/ui/event_card.prefab.json): modal, the clock waits while it is open,
//   - toasts for the ships, the orders, the reputation and the achievements.
//
// Everything is driven by the mouse: the Orders button, Fill order, a card's choice buttons, Continue and Close are all Buttons.
// Layers: the board and the card are 300+ (above the HUD at 200-210 and the toast at 220, below nothing).
import { Behaviour, world, ui, i18n, input, game, scene } from "factoria";
import { ShipView } from "./ship_view.js";
import { StoreBridge } from "./achievements.js";
import { amountText, coinsText, numberText } from "./format.js";
import { effectsMarkup, orderGoodsMarkup, shipName, amountMarkup } from "./trade_text.js";

const t = (key, args) => i18n.t(key, args);
const COLOR_BUTTON = [0.18, 0.26, 0.38, 1];
const COLOR_DISABLED = [0.14, 0.16, 0.2, 1];
/** The colour of rich text outside a [c:...] tag (the "normal" colour of the `text` section of factoria.json). */
const COLOR_TEXT = [0.92, 0.93, 0.95, 1];

/**
 * How far the text size option (ui.textScale) grows the text of a card or the order board: they are fixed sheets of paper, so
 * their text stops at 125 %, like Text.maxTextScale on any other heading.
 */
const RICH_CAP = 1.25;

/**
 * One block of rich text: a Text entity with `markup` ([b], [c:colour], [icon:name] of the `text` section of factoria.json),
 * wrapped at a width, with its top-left corner at a screen position. `set` rewrites it only when the markup or the box changed,
 * and returns the height the block takes (measured by the engine, so a longer translation or a bigger text size makes it taller).
 */
class RichBlock {
  /** @param {{ layer: number, parent?: any }} opts */
  constructor(opts) {
    this.layer = opts.layer;
    this.parent = opts.parent || null;
    /** @type {any} */ this.entity = null;
    /** The last markup + box, so an unchanged block costs nothing. */
    this.key = "";
    this.last = { height: 0 };
  }

  /** @param {string} markup @param {{ x: number, y: number, maxWidth: number, fontSize?: number }} box */
  set(markup, box) {
    const fontSize = box.fontSize || 20;
    const key = `${markup}|${box.x}|${box.y}|${box.maxWidth}|${fontSize}|${ui.textScale}`;
    if (key === this.key) return this.last;
    this.key = key;
    if (markup === "") {
      if (this.entity) this.entity.active = false;
      this.last = { height: 0 };
      return this.last;
    }
    if (!this.entity) {
      this.entity = world.spawn(
        {
          components: {
            Transform: { position: [0, 0, 0] },
            Text: { text: "", space: "screen", anchor: [0, 0], pivot: [0, 1], layer: this.layer + 1, markup: true, color: COLOR_TEXT, maxTextScale: RICH_CAP },
          },
        },
        this.parent ? { parent: this.parent } : undefined,
      );
    }
    const text = this.entity.get("Text");
    if (text.text !== markup) text.text = markup;
    text.fontSize = fontSize;
    text.maxWidth = box.maxWidth;
    this.entity.position = [box.x, box.y, 0];
    this.entity.active = true;
    const size = ui.measureText(markup, { fontSize, maxWidth: box.maxWidth, space: "screen", maxTextScale: RICH_CAP, markup: true });
    this.last = { height: Math.ceil(size.height) };
    return this.last;
  }

  /** Hide the block. */
  clear() {
    this.key = "";
    if (this.entity) this.entity.active = false;
    this.last = { height: 0 };
  }

  destroy() {
    if (this.entity) this.entity.destroy();
    this.entity = null;
    this.key = "";
  }
}

export default class TradeUi extends Behaviour {
  /** Turn the trade on. A scene prop `trade` overrides it; the test map and the stress scene leave it off unless the prop says so. */
  enabled = true;
  /** The scenario whose story is told (an id of data/scenarios.json; a scene prop `scenario` overrides it). */
  scenario = "sandbox";

  onStart() {
    this.ready = false;
    this.cardUi = null;
    this.boardUi = null;
    this.heldSpeed = -1;
    this.off = [];
  }

  /** The controller creates the game state in its own onStart, which may run after ours: wait for it. */
  init() {
    const controller = world.find("controller");
    this.controller = controller && controller.behaviour;
    if (!this.controller || !this.controller.state || !this.controller.uiPanels) return;
    const props = game.sceneProps();
    const quiet = !!(props.testMap || props.stress);
    // P4: a game loaded from a save slot brings its trade with it (savegame.js restores it): keep it, do not start a new one
    const brought = this.controller.state.trade.enabled;
    const wantOn = props.trade !== undefined ? props.trade : brought || (this.enabled && !quiet);
    this.ready = true;
    if (!wantOn) return;
    this.tradeOn = true;
    this.state = this.controller.state;
    this.trade = this.state.trade;
        this.sceneId = scene.current;
    // the scenario of the game: the scene prop, else the one the slot screen picked (controller.run), else this script's own
    const run = this.controller.run;
    if (!brought) this.trade.start(props.scenario || (run && run.tracker ? run.scenario : this.scenario));
    this.ships = new ShipView(this.state);
    this.store = new StoreBridge(this.state);
    this.repText = this.controller.addHudItem("rep", "icon.star", "");
    this.ordersButton = world.spawn({
      id: "btn_orders",
      components: {
        Transform: { position: [14, 52, 0] },
        Button: { text: "", size: [150, 30], fontSize: 18, anchor: [0, 0], pivot: [0, 1], layer: 210, color: COLOR_BUTTON, autoShrink: true, minFontSize: 8, maxTextScale: 1.5 },
      },
    });
    const ev = this.state.events;
    const toast = (key, args) => this.controller.toast(t(key, args));
    this.off = [
      ev.on("trade.card", () => this.openCard()),
      ev.on("trade.card.closed", () => this.closeCard()),
      ev.on("trade.restored", () => this.resync()),
      ev.on("trade.ship.docked", (e) => toast("trade.toast.docked", { ship: shipName(e.ship, t) })),
      ev.on("trade.order.filled", (e) => toast("trade.toast.filled", { ship: shipName(e.ship, t), reward: coinsText(e.reward) })),
      ev.on("trade.order.missed", (e) =>
        toast("trade.toast.missed", { ship: shipName(e.ship, t), delta: this.trade.data.ships.reputation.missed }),
      ),
      ev.on("trade.class.unlocked", (e) => toast("trade.toast.unlocked", { class: t(`ship.class.${e.cls}`) })),
      ev.on("trade.achievement", (e) => toast("trade.toast.achievement", { name: t(`achievement.${e.id}.name`) })),
      ev.on("trade.story.finished", (e) => toast("trade.toast.story", { name: t(`story.${e.scenario}.name`) })),
      ui.on("click", (e) => this.onClick(e.id)),
      // the board and the card are written by this script: write them again when the language changes
      i18n.on("change", () => this.redraw()),
      // ... and when the text size changes: the card's layout depends on it
      ui.on("textScale", () => this.redraw()),
    ];
    this.refreshHud();
    if (this.trade.card) {
      // a game saved with a card open was saved at speed 0 (the card holds the clock): go on at x1 after the answer
      if (brought && this.state.clock.speed === 0 && this.heldSpeed < 0) this.heldSpeed = 1;
      this.openCard();
    }
  }

  onDestroy() {
    for (const off of this.off) off();
    this.off = [];
    this.closeBoard();
    this.closeCard(true);
    if (this.ships) this.ships.destroy();
    if (this.store) this.store.destroy();
    if (this.trade) this.trade.stop();
  }

  onUpdate() {
    if (!this.ready) this.init();
    if (!this.tradeOn) return;
    this.ships.update();
    // a card is modal: the clock waits until it is answered
    const clock = this.state.clock;
    if (this.trade.card && clock.speed !== 0) {
      if (this.heldSpeed < 0) this.heldSpeed = clock.speed;
      this.controller.setSpeed(0);
    } else if (!this.trade.card && this.heldSpeed >= 0) {
      // the clock goes on at the speed it had, unless the player changed it meanwhile
      if (clock.speed === 0) this.controller.setSpeed(this.heldSpeed);
      this.heldSpeed = -1;
    }
    if (input.pressed("order_board") && !this.trade.card) this.toggleBoard();
    this.refreshHud();
    if (this.boardUi) this.drawBoard();
  }

  /** The language or the text size changed: lay the open card and board out again. */
  redraw() {
    if (!this.tradeOn) return;
    if (this.cardUi) this.renderCard();
    if (this.boardUi) {
      this.boardUi.footer.key = "";
      for (const v of this.boardUi.views) v.key = "";
      this.drawBoard();
    }
    this.refreshHud();
  }

  // ---- HUD ---------------------------------------------------------------------------------------------------------

  refreshHud() {
    const rep = String(this.trade.reputation);
    const text = this.repText.get("Text");
    if (text.text !== rep) text.text = rep;
    const docked = this.trade.ships.filter((s) => s.state === "docked").length;
    const label = docked ? t("trade.hud.ordersN", { count: docked }) : t("trade.hud.orders");
    const b = this.ordersButton.get("Button");
    if (b.text !== label) b.text = label;
    const color = this.boardUi ? [0.3, 0.5, 0.75, 1] : COLOR_BUTTON;
    if (this.shownOrdersColor !== this.boardUi) {
      this.shownOrdersColor = this.boardUi;
      b.color = color;
    }
  }

  // ---- clicks ------------------------------------------------------------------------------------------------------

  onClick(id) {
    if (!this.tradeOn || scene.current !== this.sceneId) return;
    if (id === "btn_orders") this.toggleBoard();
    else if (id === "board_close") this.closeBoard();
    else if (id.startsWith("fill_")) this.fill(Number(id.slice(5)));
    else if (id.startsWith("choice_")) this.choose(id.slice(7));
    else if (id === "card_continue") this.trade.dismiss();
  }

  fill(shipId) {
    const res = this.trade.fillOrder(shipId);
    if (!res.ok && res.code === "missing_goods") this.controller.toast(t("trade.board.missing", { list: this.plainList(res.missing) }));
  }

  /** "4 wood, 2 fish" for a list of goods (a toast is plain text). */
  plainList(list) {
    return amountText(list);
  }

  choose(choiceId) {
    const res = this.trade.choose(choiceId);
    if (res.ok) this.renderCard();
    else if (res.code === "cannot_afford") this.controller.toast(t("trade.card.cannot", { list: this.plainList(res.missing) }));
  }

  // ---- the order board ---------------------------------------------------------------------------------------------

  toggleBoard() {
    if (this.boardUi) this.closeBoard();
    else this.openBoard();
  }

  openBoard() {
    if (this.boardUi || this.trade.card) return;
    const root = world.spawnPrefab("prefabs/ui/order_board.prefab.json");
    this.controller.uiPanels.push(root);
    this.boardUi = { root, views: [], buttons: [], footer: new RichBlock({ layer: 300, parent: root }), key: "" };
    this.drawBoard();
    this.refreshHud();
  }

  closeBoard() {
    if (!this.boardUi) return;
    const root = this.boardUi.root;
    const i = this.controller.uiPanels.indexOf(root);
    if (i >= 0) this.controller.uiPanels.splice(i, 1);
    for (const v of this.boardUi.views) v.destroy();
    this.boardUi.footer.destroy();
    for (const b of this.boardUi.buttons) b.destroy();
    root.destroy();
    this.boardUi = null;
    this.refreshHud();
  }

  /** Draw the rows (a row is up to three rich text lines and a button); only what changed is touched. */
  drawBoard() {
    const b = this.boardUi;
    const trade = this.trade;
    const X = 24; // children of a Panel are placed from its top-left corner
    const W = 672;
    let y = 66;
    const docks = trade.state.list("pier").length;
    // one row per ship, in the order they were sent
    const ships = trade.ships;
    while (b.views.length < ships.length * 3) b.views.push(new RichBlock({ layer: 300, parent: b.root }));
    let v = 0;
    const wanted = new Set();
    for (const ship of ships) {
      const title = `[b]${shipName(ship, t)}[/b]  [c:muted]${t("ship.class." + ship.cls)}[/c]`;
      const rowTop = y;
      const r1 = b.views[v++].set(title, { x: X, y, maxWidth: 520, fontSize: 24 });
      const goods = `${t("trade.board.wants")} ${orderGoodsMarkup(ship.order.goods)}   [c:gold]${t("trade.board.pays")}[/c] ${amountMarkup("coins", ship.order.reward)}`;
      const r2 = b.views[v++].set(goods, { x: X, y: rowTop + r1.height + 2, maxWidth: W - 160, fontSize: 22 });
      let status;
      if (ship.state === "arriving") status = `[c:sea]${t("trade.board.sailing")}[/c]`;
      else if (ship.state === "leaving") status = `[c:muted]${t("trade.board.leaving")}[/c]`;
      else {
        const left = trade.daysLeft(ship);
        const can = trade.canFill(ship.id);
        status = `[c:${left <= 1 ? "bad" : "muted"}]${left <= 1 ? t("trade.board.left1") : t("trade.board.left", { count: left, days: numberText(left) })}[/c]`;
        if (!can.ok && can.missing) {
          const list = Object.entries(can.missing).map(([k, n]) => amountMarkup(k, n)).join("  ");
          status += `   [c:bad]${t("trade.board.missing", { list: "" }).trim()}[/c] ${list}`;
        }
        wanted.add(ship.id);
        let btn = b.buttons.find((x) => x.id === `fill_${ship.id}`);
        if (!btn) {
          btn = world.spawn(
            {
              id: `fill_${ship.id}`,
              components: {
                Transform: { position: [X + W - 130, rowTop + 6, 0] },
                Button: { text: t("trade.board.fill"), size: [130, 38], fontSize: 20, anchor: [0, 0], pivot: [0, 1], layer: 302, autoShrink: true, minFontSize: 8, maxTextScale: RICH_CAP },
              },
            },
            { parent: b.root },
          );
          b.buttons.push(btn);
        }
        btn.position = [X + W - 130, rowTop + 6, 0];
        const bc = btn.get("Button");
        const fill = t("trade.board.fill"); // written again: the language may have changed since the button was made
        if (bc.text !== fill) bc.text = fill;
        bc.size = [130, Math.round(38 * Math.min(ui.textScale, RICH_CAP))];
        bc.interactable = can.ok;
        bc.color = can.ok ? [0.2, 0.45, 0.28, 1] : COLOR_DISABLED;
      }
      const r3 = b.views[v++].set(status, { x: X, y: rowTop + r1.height + r2.height + 4, maxWidth: W - 160, fontSize: 20 });
      // a row is as tall as its three lines (the text size option and a longer translation make them taller); the fill button may be taller than a short row
      y = rowTop + Math.max(r1.height + r2.height + r3.height + 4, 6 + Math.round(38 * Math.min(ui.textScale, RICH_CAP))) + 14;
    }
    for (let i = v; i < b.views.length; i++) b.views[i].clear();
    // buttons of ships that left
    for (let i = b.buttons.length - 1; i >= 0; i--) {
      const id = Number(b.buttons[i].id.slice(5));
      if (!wanted.has(id)) {
        b.buttons[i].destroy();
        b.buttons.splice(i, 1);
      }
    }
    // the foot: what comes next
    let foot;
    if (!docks) foot = `[c:muted]${t("trade.board.nopier")}[/c]`;
    else if (!ships.length) foot = `[c:muted]${t("trade.board.empty")}[/c]`;
    else foot = "";
    const lines = [foot];
    if (docks && trade.nextShipDay !== Infinity && trade.nextShipDay > this.state.clock.day) {
      lines.push(`[c:muted]${t("trade.board.next", { count: trade.nextShipDay - this.state.clock.day })}[/c]`);
    }
    const locked = Object.keys(trade.data.ships.classes)
      .filter((id) => trade.data.ships.classes[id].minReputation > trade.reputation)
      .sort((a, c) => trade.data.ships.classes[a].minReputation - trade.data.ships.classes[c].minReputation)[0];
    if (locked) {
      lines.push(`[c:muted]${t("trade.board.unlock", { value: trade.data.ships.classes[locked].minReputation, class: t(`ship.class.${locked}`) })}[/c]`);
    }
    lines.push(`[c:gold]${t("trade.reputation", { value: trade.reputation })}[/c][icon:star]`);
    const foot2 = b.footer.set(lines.filter(Boolean).join("\n"), { x: X, y: y + 6, maxWidth: W, fontSize: 20 });
    b.root.get("Panel").size = [720, Math.round(y + 6 + foot2.height + 24)];
  }

  // ---- the event / story card --------------------------------------------------------------------------------------

  openCard() {
    if (!this.trade.card) return;
    this.closeBoard();
    this.closeCard(true);
    const root = world.spawnPrefab("prefabs/ui/event_card.prefab.json");
    this.controller.uiPanels.push(root);
    this.cardUi = { root, views: [], buttons: [] };
    this.renderCard();
  }

  /** (Re)draw the open card: its question with the choices, or its result with Continue. */
  renderCard() {
    const c = this.cardUi;
    const card = this.trade.card;
    if (!c || !card) return;
    for (const v of c.views) v.destroy();
    for (const b of c.buttons) b.destroy();
    c.views = [];
    c.buttons = [];
    const rich = () => {
      const v = new RichBlock({ layer: 300, parent: c.root });
      c.views.push(v);
      return v;
    };
    const { def, base } = this.trade.cardDef(card);
    const X = 0; // children of a Panel are placed from its top-left corner (the panel itself is put at 320, 100 at the end)
    const Y = 0;
    const W = 640;
    const pad = 24;
    const kindText = world.find("card_kind");
    const titleText = world.find("card_title");
    kindText.get("Text").text = t(card.kind === "story" ? "trade.card.story" : "trade.card.event");
    const title = t(`${base}.title`);
    titleText.get("Text").text = title;
    // the text size option grows the card's text up to RICH_CAP: the title sits under the kind line, and a button is as tall as its text
    const k = Math.min(ui.textScale, RICH_CAP);
    const titleY = Y + 16 + Math.round(18 * k * 1.3) + 4;
    kindText.position = [X + pad, Y + 16, 0];
    titleText.position = [X + pad, titleY, 0];
    const buttonH = Math.round(38 * k);
    let y = titleY + ui.measureText(title, { fontSize: 32, maxWidth: W - pad * 2, space: "screen", maxTextScale: RICH_CAP }).height + 16;
    if (card.stage === "choose") {
      const body = rich().set(t(`${base}.body`), { x: X + pad, y, maxWidth: W - pad * 2, fontSize: 20 });
      y += body.height + 18;
      for (const choice of def.choices) {
        const can = this.trade.canChoose(choice);
        const btn = world.spawn(
          {
            id: `choice_${choice.id}`,
            components: {
              Transform: { position: [X + pad, y, 0] },
              Button: {
                text: t(`${base}.choice.${choice.id}`),
                size: [W - pad * 2, buttonH],
                fontSize: 20,
                anchor: [0, 0],
                pivot: [0, 1],
                layer: 302,
                autoShrink: true,
                minFontSize: 8,
                maxTextScale: RICH_CAP,
                interactable: can.ok,
                color: can.ok ? COLOR_BUTTON : COLOR_DISABLED,
              },
            },
          },
          { parent: c.root },
        );
        c.buttons.push(btn);
        y += buttonH + 4;
        let line;
        if (choice.outcomes) line = `[c:gold]${t("trade.card.risky")}[/c]`;
        else if (!can.ok) line = `[c:bad]${t("trade.card.cannot", { list: Object.entries(can.missing).map(([k, n]) => amountMarkup(k, n)).join("  ") })}[/c]`;
        else line = effectsMarkup(choice.effects, t) || `[c:muted]${t("trade.card.free")}[/c]`;
        const r = rich().set(line, { x: X + pad + 8, y, maxWidth: W - pad * 2 - 16, fontSize: 18 });
        y += Math.max(r.height, 24) + 12;
      }
    } else {
      const key = card.outcome === null || card.outcome === undefined ? `${base}.result.${card.choice}` : `${base}.result.${card.choice}.${card.outcome}`;
      const body = rich().set(t(key), { x: X + pad, y, maxWidth: W - pad * 2, fontSize: 20 });
      y += body.height + 14;
      const line = effectsMarkup(this.trade.resultEffects(card), t);
      if (line) {
        const r = rich().set(line, { x: X + pad, y, maxWidth: W - pad * 2, fontSize: 22 });
        y += r.height + 14;
      }
      c.buttons.push(
        world.spawn(
          {
            id: "card_continue",
            components: {
              Transform: { position: [X + W - pad - 160, y, 0] },
              Button: { text: t("trade.card.continue"), size: [160, buttonH], fontSize: 20, anchor: [0, 0], pivot: [0, 1], layer: 302, autoFocus: true, autoShrink: true, minFontSize: 8, maxTextScale: RICH_CAP },
            },
          },
          { parent: c.root },
        ),
      );
      y += buttonH + 4;
    }
    c.root.get("Panel").size = [W, y + pad];
    c.root.position = [320, 100, 0];
  }

  /** @param {boolean} [quiet] */
  closeCard(quiet) {
    const c = this.cardUi;
    if (!c) return;
    const i = this.controller.uiPanels.indexOf(c.root);
    if (i >= 0) this.controller.uiPanels.splice(i, 1);
    for (const v of c.views) v.destroy();
    for (const b of c.buttons) b.destroy();
    c.root.destroy();
    this.cardUi = null;
    void quiet;
  }

  /** The trade was restored from a save: draw what it holds now. */
  resync() {
    this.closeBoard();
    this.closeCard(true);
    if (this.trade.card) this.openCard();
  }
}
