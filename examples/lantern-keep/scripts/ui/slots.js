// @ts-check
// The save slot screen (prefabs/ui/slots.prefab.json), opened by the main menu's Play. An empty slot says "New game", a
// used one its summary; choosing one makes it the current slot and opens the level select. "Delete" asks first
// (delete_confirm). When the screen opens the cloud copies are compared with the local ones (saves.syncCloud).
import { Behaviour, ui, i18n, world, session } from "factoria";
import { fitWidgets } from "./text_fit.js";
import * as saves from "../saves.js";
import { MenuStack } from "./menu_stack.js";
import { refreshConfirm } from "./delete_confirm.js";
import { refreshSelect } from "./level_select.js";
import { formatTime } from "../time_format.js";

export default class Slots extends Behaviour {
  onStart() {
    for (const n of saves.SLOTS) {
      ui.on("click", `slot_${n}`, () => this.pick(n));
      ui.on("click", `delete_${n}`, () => {
        session.pendingDelete = n;
        MenuStack.main.show("delete_confirm");
        refreshConfirm();
      });
    }
    i18n.on("change", refreshSlots);
    refreshSlots();
  }

  pick(n) {
    if (saves.peek(n).status === "damaged") return; // the slot says so; Delete empties it
    saves.choose(n);
    MenuStack.main.show("level_select");
    refreshSelect();
  }
}

/** The main menu calls this when it shows the screen: draws the slots, then again if the cloud had better copies. */
export async function openSlots() {
  refreshSlots();
  if (await saves.syncCloud()) refreshSlots();
}

/** Writes the slot buttons from the saves (the screen is inactive until shown, so this is a function, not a method). */
export function refreshSlots() {
  let damaged = false;
  for (const n of saves.SLOTS) {
    const p = saves.peek(n);
    const text = {
      empty: () => i18n.t("slots.new", { n }),
      damaged: () => i18n.t("slots.damaged", { n }),
      used: () => i18n.t("slots.used", { n, ...p.summary, time: formatTime(p.summary?.time ?? 0) }),
    }[p.status]();
    world.find(`slot_${n}`).get("Button").text = breakLong(text, world.find(`slot_${n}`).get("Button").fontSize);
    world.find(`delete_${n}`).get("Button").interactable = p.status !== "empty";
    damaged ||= p.status === "damaged";
  }
  world.find("slots_note").get("Text").text = damaged ? i18n.t("slots.damagedNote") : "";
  fitWidgets(world.find("slots")); // the buttons as big as their text needs at this text size and language
}

/** The widest a slot line is before it goes on two lines (after "Slot 2:"), so the Delete button still fits beside it. */
const LINE = 640;

/** A slot line that would be too wide at this text size and language is broken after the slot's name: "Slot 2:" and the summary. */
function breakLong(text, fontSize) {
  const colon = text.indexOf(": ");
  if (colon < 0 || ui.measureText(text, { fontSize }).width <= LINE) return text;
  return `${text.slice(0, colon + 1)}\n${text.slice(colon + 2)}`;
}
