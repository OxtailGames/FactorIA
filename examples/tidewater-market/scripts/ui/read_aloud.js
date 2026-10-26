// @ts-check
// "Read menus aloud": when the player turned the option on (Options > Audio), the widget that takes focus is said with
// the system's text to speech, in the game's language. The behaviours of the menus call readMenusAloud() once.
import { ui, i18n } from "factoria";
import * as settings from "../settings.js";

/** What to say for a focused widget (its text, already localized by the engine, plus its state), or "" for none. */
export function describe(entity) {
  if (entity.has("Button")) return entity.get("Button").text;
  if (entity.has("Toggle")) {
    const toggle = entity.get("Toggle");
    return `${toggle.label}, ${i18n.t(toggle.value ? "options.on" : "options.off")}`;
  }
  if (entity.has("Slider")) {
    const slider = entity.get("Slider");
    const percent = Math.round(((slider.value - slider.min) / (slider.max - slider.min)) * 100);
    return `${slider.label}, ${i18n.t("options.percent", { value: percent })}`;
  }
  if (entity.has("TextField")) return entity.get("TextField").placeholder;
  return "";
}

/** Says the focused widget while the option is on; interrupts, so moving quickly never queues old lines. */
export function readMenusAloud() {
  ui.on("focus", (e) => {
    if (!settings.load().readAloud) return;
    const text = describe(e.entity);
    if (text) ui.speak(text);
  });
}
