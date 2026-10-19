// @ts-check
// "Delete this slot?" (prefabs/ui/delete_confirm.prefab.json). The slot is session.pendingDelete, set by the slot screen.
// "Keep it" has the focus, so a stray A press deletes nothing.
import { Behaviour, ui, i18n, world, session } from "factoria";
import * as saves from "../saves.js";
import { MenuStack } from "./menu_stack.js";
import { fitWidgets } from "./text_fit.js";
import { refreshSlots } from "./slots.js";

export default class DeleteConfirm extends Behaviour {
  onStart() {
    ui.on("click", "confirm_yes", () => {
      saves.remove(session.pendingDelete);
      MenuStack.main.back();
      refreshSlots();
    });
    i18n.on("change", refreshConfirm);
  }
}

/** The slot screen calls this when it shows the screen. */
export function refreshConfirm() {
  world.find("confirm_title").get("Text").text = i18n.t("slots.confirm", { n: session.pendingDelete });
  fitWidgets(world.find("delete_confirm")); // "Keep it" and "Delete" as big as their text needs
}
