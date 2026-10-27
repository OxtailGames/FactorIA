// @ts-check
// The save / load screen (prefabs/ui/slots.prefab.json) and the small dialog that names a save or asks before a delete
// (prefabs/ui/slot_dialog.prefab.json). Not a behaviour: the pause menu (save and load) and the title screen (load) each build one
// with their MenuStack and call tick() every frame.
//
//   const slots = new SlotScreen(menus, { getPic: () => this.pic });   // getPic: the picture to keep with a save (base64 PNG) or null
//   slots.open("save");  // or "load"
//
// Six rows: the autosave (never a save target) and the five slots, each with its picture, name, chapter and play time. Mouse, touch and
// gamepad all use the same Buttons. Saving a slot opens the dialog with a TextField for the name (the on-screen keyboard of
// scripts/ui/keyboard.js opens by itself for a gamepad player); Enter or Done saves, Cancel / Escape / B goes back.
// The cloud copies are compared when the screen opens (saves.syncCloud) and the rows are drawn again if one replaced a slot.
import { ui, i18n, world, scene, render } from "factoria";
import * as saves from "../saves.js";
import { MenuStack } from "./menu_stack.js";
import OnScreenKeyboard from "./keyboard.js";

export class SlotScreen {
  /**
   * @param {MenuStack} menus the host's panel stack
   * @param {{ getPic?: () => (string | null) }} [opts]
   */
  constructor(menus, opts = {}) {
    this.menus = menus;
    this.getPic = opts.getPic ?? (() => null);
    /** "save" | "load" */
    this.mode = "load";
    /** The line under the title: a result ("Saved to slot 2."), else why saving is not possible, else nothing. */
    this.message = "";
    /** @type {{ kind: "name" | "delete", id: any } | null} */
    this.dialog = null;
    /** Runtime textures of the pictures shown, freed before they are drawn again. */
    this.pics = [];
    this.kbWasOpen = false;
    for (const [id, prefab] of [["slots", "slots"], ["slot_dialog", "slot_dialog"], ["keyboard_host", "keyboard_host"]]) {
      const panel = world.spawnPrefab(`prefabs/ui/${prefab}.prefab.json`);
      panel.id = id; // MenuStack shows panels by id
      panel.active = prefab === "keyboard_host";
    }
    for (const id of saves.ALL) {
      ui.on("click", `slot_${id}`, () => this.pick(id));
      ui.on("click", `delete_${id}`, () => this.openDialog("delete", id));
    }
    ui.on("click", "dialog_confirm", () => this.confirm());
    ui.on("click", "dialog_cancel", () => this.closeDialog());
    ui.on("submit", "save_name", () => this.confirm());
    i18n.on("change", () => this.menus.top === "slots" && this.refresh());
  }

  /** Call every frame: remembers whether the on-screen keyboard was open before this frame's presses. */
  tick() {
    this.kbWasOpen = OnScreenKeyboard.isOpen;
  }

  /**
   * The host calls this for Escape / the pad's B: while the dialog is on top it closes it (but not when the on-screen keyboard was open
   * at the start of the frame: that press only closes the keyboard) and returns true, so the host does not also go back.
   */
  cancel() {
    if (!this.dialogOpen) return false;
    if (!this.kbWasOpen) this.closeDialog();
    return true;
  }

  /** True while the dialog is the panel on top. */
  get dialogOpen() {
    return this.menus.top === "slot_dialog";
  }

  /** Shows the screen in mode "save" or "load". */
  open(mode) {
    this.mode = mode;
    this.message = "";
    this.menus.show("slots");
    this.refresh();
    this.focusFirst();
    const path = scene.current;
    saves
      .syncCloud()
      .then((changed) => {
        if (changed && scene.current === path && this.menus.top === "slots") this.refresh(); // the scene may be gone by now
      })
      .catch(() => {});
  }

  focusFirst() {
    let first = "slots_back";
    if (this.mode === "save") {
      if (!saves.cannotSave()) first = "slot_1";
    } else {
      const id = saves.ALL.find((i) => saves.peek(i).status === "used");
      if (id !== undefined) first = `slot_${id}`;
    }
    ui.focus(world.find(first));
  }

  /** Frees the runtime textures (the host calls it when the scene goes). */
  dispose() {
    for (const id of saves.ALL) {
      const row = world.find(`pic_${id}`);
      if (row) row.get("Panel").texture = "";
    }
    for (const tex of this.pics) tex.destroy();
    this.pics = [];
  }

  /** Writes the rows from the slots. */
  refresh() {
    this.dispose();
    const reason = this.mode === "save" ? saves.cannotSave() : "";
    let damaged = false;
    for (const id of saves.ALL) {
      const p = saves.peek(id);
      const auto = id === saves.AUTO;
      const button = world.find(`slot_${id}`).get("Button");
      if (p.status === "used") {
        const r = p.record;
        button.text = i18n.t(auto ? "slots.usedAuto" : "slots.used", {
          n: id,
          name: r.name || i18n.t("slots.unnamed"),
          chapter: r.chapter,
          time: saves.formatTime(r.playTime),
        });
      } else if (p.status === "damaged") {
        button.text = i18n.t(auto ? "slots.damagedAuto" : "slots.damaged", { n: id });
        damaged = true;
      } else {
        button.text = i18n.t(auto ? "slots.emptyAuto" : "slots.empty", { n: id });
      }
      button.interactable = this.mode === "save" ? !auto && !reason : p.status === "used";
      world.find(`delete_${id}`).get("Button").interactable = p.status !== "empty";
      const pic = world.find(`pic_${id}`).get("Panel");
      if (p.status === "used" && p.record.pic) {
        try {
          const tex = render.textureFromPNG(p.record.pic);
          this.pics.push(tex);
          pic.texture = tex.id;
          pic.color = [1, 1, 1, 1];
        } catch (e) {
          console.warn(`slots: the picture of slot ${id} is not an image: ${e.message}`);
          pic.color = [0.08, 0.09, 0.12, 1];
        }
      } else pic.color = [0.08, 0.09, 0.12, 1];
    }
    world.find("slots_title").get("Text").text = i18n.t(this.mode === "save" ? "slots.titleSave" : "slots.titleLoad");
    const note = this.message || (reason ? i18n.t(reason) : damaged ? i18n.t("slots.damagedNote") : "");
    world.find("slots_note").get("Text").text = note;
  }

  pick(id) {
    const p = saves.peek(id);
    if (this.mode === "load") {
      if (p.status !== "used") return;
      this.dispose();
      const r = saves.load(id);
      if (!r.ok) {
        this.message = `${r.message}. ${r.hint}`;
        this.refresh();
      }
      return;
    }
    if (id === saves.AUTO || saves.cannotSave()) return;
    this.openDialog("name", id);
  }

  openDialog(kind, id) {
    this.dialog = { kind, id };
    const name = world.find("save_name");
    const field = name.get("TextField");
    if (kind === "name") {
      const p = saves.peek(id);
      field.text = p.status === "used" ? p.record.name : saves.defaultName();
      world.find("dialog_title").get("Text").text = i18n.t("slots.nameTitle", { n: id });
      world.find("dialog_confirm").get("Button").text = i18n.t("slots.confirmSave");
    } else {
      world.find("dialog_title").get("Text").text = i18n.t("slots.deleteTitle", { n: id === saves.AUTO ? i18n.t("slots.autoName") : id });
      world.find("dialog_confirm").get("Button").text = i18n.t("slots.confirmDelete");
    }
    this.menus.show("slot_dialog");
    name.active = kind === "name";
    ui.focus(world.find(kind === "name" ? "save_name" : "dialog_cancel"));
  }

  closeDialog() {
    this.dialog = null;
    this.menus.back(); // gives the focus back to the button that opened the dialog
    this.refresh();
  }

  confirm() {
    const d = this.dialog;
    if (!d || this.menus.top !== "slot_dialog") return;
    if (d.kind === "name") {
      const record = saves.write(d.id, { name: world.find("save_name").get("TextField").text, pic: this.getPic() });
      this.message = record ? i18n.t("slots.saved", { n: d.id }) : i18n.t(saves.cannotSave() || "slots.busy");
    } else {
      saves.remove(d.id);
      this.message = "";
    }
    this.closeDialog();
    if (d.kind === "name") ui.focus(world.find(`slot_${d.id}`));
    else this.focusFirst();
  }
}
