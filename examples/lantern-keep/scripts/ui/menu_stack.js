// @ts-check
// A stack of menu panels. show(id) hides the current panel and shows another one over it; back() returns to the
// previous panel and gives the focus back to the widget that had it. Panels are entities shown and hidden with `active`;
// the first widget with autoFocus in a panel that appears takes the focus by itself (docs: UI focus rules).
import { world, ui } from "factoria";

export class MenuStack {
  /** True while a panel captures input for itself (options: "press a key"): back() does nothing then. */
  static busy = false;
  /** The main menu's stack, so its screens (save slots, level select) can open each other. */
  static main = null;

  /** @param {string | null} root the panel that is always there (the main menu), or null (gameplay: nothing open) */
  constructor(root) {
    this.root = root;
    /** @type {Array<{ id: string, focus: any }>} */
    this.open = root ? [{ id: root, focus: null }] : [];
  }

  /** Id of the panel on top, or null when nothing is open. */
  get top() {
    return this.open.length ? this.open[this.open.length - 1].id : null;
  }

  /** Shows panel `id` over the current one. */
  show(id) {
    const below = this.open[this.open.length - 1];
    if (below) {
      below.focus = ui.focused;
      world.find(below.id).active = false;
    }
    this.open.push({ id, focus: null });
    world.find(id).active = true;
  }

  /** Closes the top panel (never the root). Returns false when there was nothing to close. */
  back() {
    if (MenuStack.busy || this.open.length === 0 || (this.root && this.open.length === 1)) return false;
    world.find(this.open.pop().id).active = false;
    const below = this.open[this.open.length - 1];
    if (below) {
      world.find(below.id).active = true;
      if (below.focus && below.focus.alive) ui.focus(below.focus);
    }
    return true;
  }

  /** Closes every panel but the root. */
  closeAll() {
    while (this.back());
  }
}
