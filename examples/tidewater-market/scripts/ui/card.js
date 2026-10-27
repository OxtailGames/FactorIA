// @ts-check
// A choice card (prefabs/ui/card.prefab.json): a modal panel with a title, a wrapped body, choice buttons that each have a
// detail line, a choice that is greyed out with the reason shown, and a result stage with a Continue button. It is the
// event / story / dialogue card of a management game. The panel is `modal` (Panel.modal): while it is open only its widgets
// get the mouse, the wheel, the arrows and the pad, so the game under it neither hovers nor clicks, and the focus stays on the
// card. Mouse, keyboard and pad all work through the widgets: the arrows move between the choices that can be chosen, Enter,
// Space or gamepad A picks one.
import { world, ui, game, scene } from "factoria";

/** One choice of the card. `text` and `detail` are rich text (Text.markup: [b], [c:colour], [icon:name]). */
/** @typedef {{ id: string, text: string, detail?: string, disabled?: string | boolean }} CardChoice */

/** The colour of a disabled choice's reason: a built-in colour name, a colour of factoria.json text.colors or #rrggbb. */
const REASON_COLOR = "#ff8a80";
const COLOR_CHOICE = [0.18, 0.26, 0.38, 1];
const COLOR_DISABLED = [0.14, 0.16, 0.2, 1];

export class Card {
  /**
   * Opens the card (spawns the prefab). Fill it with ask(), then answer(), and end it with close().
   * @param {object} [options]
   * @param {(id: string) => void} [options.onChoose] the player picked the choice `id` (mouse, key or pad); disabled choices never get here
   * @param {() => void} [options.onContinue] the player pressed Continue on the result stage
   * @param {boolean} [options.holdClock] true: game.paused is true while the card is open (what was paused before stays paused)
   * @param {string} [options.reasonColor] colour of a disabled choice's reason (default a light red)
   * @param {string} [options.prefab] the card's prefab, when the game keeps its own copy
   */
  constructor(options = {}) {
    this.onChoose = options.onChoose || null;
    this.onContinue = options.onContinue || null;
    this.reasonColor = options.reasonColor || REASON_COLOR;
    this.sceneId = scene.current;
    this.root = world.spawnPrefab(options.prefab || "prefabs/ui/card.prefab.json");
    this.root.id = "card";
    /** @type {any[]} */ this.rows = [];
    this.stage = "none";
    this.heldPause = false;
    if (options.holdClock && !game.paused) {
      game.paused = true;
      this.heldPause = true;
    }
    // Listeners end with the scene; a click that arrives after the card was closed or the scene changed does nothing.
    this.off = ui.on("click", (e) => this.#click(e.id));
  }

  /** True while the card is on screen (not closed, and its scene is still the current one). */
  get isOpen() {
    return !!this.root && this.root.alive && scene.current === this.sceneId;
  }

  /**
   * The question stage: a title, a body and the choices. A choice with `disabled` (a reason, or true) cannot be picked, and
   * its detail line shows the reason; the first choice that can be picked has the focus.
   * @param {object} spec
   * @param {string} [spec.kind] small line over the title ("Event", "Story")
   * @param {string} spec.title
   * @param {string} [spec.body] rich text
   * @param {CardChoice[]} spec.choices
   */
  ask(spec) {
    if (!this.isOpen) return;
    this.stage = "choose";
    this.#text("card_kind", spec.kind || "");
    this.#text("card_title", spec.title);
    this.#text("card_body", spec.body || "");
    this.#text("card_effects", "");
    this.#clearRows();
    const parent = world.find("card_choices");
    parent.active = true;
    let first = true;
    for (const choice of spec.choices) {
      const reason = typeof choice.disabled === "string" ? choice.disabled : "";
      const disabled = !!choice.disabled;
      const row = world.spawn(
        { id: `choice_row_${choice.id}`, components: { Panel: { layer: 301, color: [0, 0, 0, 0], layout: "column", align: "start", spacing: 2, padding: [0, 0, 0, 0], fit: true } } },
        { parent },
      );
      world.spawn(
        {
          id: `choice_${choice.id}`,
          components: {
            Button: {
              text: choice.text,
              size: [592, 44],
              autoSize: true,
              maxWidth: 570,
              autoShrink: true,
              minFontSize: 10,
              maxTextScale: 1.25,
              markup: true,
              layer: 302,
              interactable: !disabled,
              color: disabled ? COLOR_DISABLED : COLOR_CHOICE,
              autoFocus: !disabled && first,
            },
          },
        },
        { parent: row },
      );
      if (!disabled) first = false;
      const detail = reason ? `[c:${this.reasonColor}]${reason}[/c]` : choice.detail || "";
      if (detail)
        world.spawn(
          {
            id: `choice_${choice.id}_detail`,
            components: { Text: { text: detail, fontSize: 18, space: "screen", align: "start", maxWidth: 570, maxTextScale: 1.25, markup: true, color: [0.75, 0.8, 0.9, 1], layer: 301 } },
          },
          { parent: row },
        );
      this.rows.push(row);
    }
    world.find("card_continue").active = false;
    this.#focusFirst();
  }

  /**
   * The result stage: what happened, the effects line, and a Continue button (it has the focus).
   * @param {object} spec
   * @param {string} spec.body rich text
   * @param {string} [spec.effects] rich text, drawn under the body in a larger size
   * @param {string} [spec.continueText] replaces the Continue label (otherwise the card.continue string)
   */
  answer(spec) {
    if (!this.isOpen) return;
    this.stage = "result";
    this.#text("card_body", spec.body);
    this.#text("card_effects", spec.effects || "");
    this.#clearRows();
    world.find("card_choices").active = false;
    const button = world.find("card_continue");
    button.active = true;
    if (spec.continueText) {
      button.get("Button").key = ""; // a key would replace the text
      button.get("Button").text = spec.continueText;
    }
    this.#focusFirst();
  }

  /** Closes the card: its panel goes, and the game goes on if the card paused it. Safe to call twice. */
  close() {
    this.off();
    if (this.root && this.root.alive) this.root.destroy();
    this.root = null;
    this.stage = "none";
    if (this.heldPause) {
      this.heldPause = false;
      game.paused = false;
    }
  }

  /** @param {string} id @param {string} text */
  #text(id, text) {
    const e = world.find(id);
    // Rich text is switched on here, not in the prefab: `factoria validate` warns about markup in a prefab of a game that has no bold font.
    if (id === "card_body" || id === "card_effects") e.get("Text").markup = true;
    e.get("Text").text = text;
    e.active = text !== "";
  }

  #clearRows() {
    for (const row of this.rows) {
      if (!row.alive) continue;
      row.active = false; // destroy() happens at the end of the frame: until then the old rows must not take room in the layout
      row.destroy();
    }
    this.rows = [];
  }

  #focusFirst() {
    const target = this.stage === "result" ? world.find("card_continue") : this.rows.map((r) => r.children[0]).find((b) => b.get("Button").interactable);
    if (target) ui.focus(target);
  }

  /** @param {string} id */
  #click(id) {
    if (!this.isOpen || typeof id !== "string") return;
    if (this.stage === "choose" && id.startsWith("choice_")) {
      const button = world.find(id);
      if (button?.get("Button")?.interactable) this.onChoose?.(id.slice("choice_".length));
    } else if (this.stage === "result" && id === "card_continue") {
      this.onContinue?.();
    }
  }
}
