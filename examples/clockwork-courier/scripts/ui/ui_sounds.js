// @ts-check
// Interface sounds for every menu: a click on any widget, "back" buttons and ui_cancel. Call installUiSounds() once from
// a menu behaviour's onStart (handlers end with the scene, so every scene installs its own). Sounds play on the "ui" bus
// so the options panel's Interface volume controls them.
import { ui, audio } from "factoria";

/** Plays one of the interface sounds (file name without folder and extension) on the ui bus. */
export function playUi(name, volume = 0.7) {
  audio.play(`assets/audio/${name}.ogg`, { bus: "ui", volume });
}

export function installUiSounds() {
  ui.on("click", (e) => playUi(e.entity.hasTag("back") ? "back_001" : "click_001"));
  ui.on("cancel", () => playUi("back_001", 0.5));
}
