// @ts-check
// The name screen (scenes/profile.scene.json): shown on the first Play (no name yet) and from "rename" on the level select.
// A TextField takes the keyboard, and the phone's own keyboard where the platform shows one. A player with only a gamepad
// gets the menu kit's on-screen keyboard (scripts/ui/keyboard.js on the "keyboard_host" entity, prefabs/ui/keyboard.prefab.json):
// it opens over the screen when the field has the focus, the d-pad walks the keys, A types, Done sends the same submit as Enter.
// Done (or Enter) saves the name through progress.setName and goes on to session.profileReturn
// (the level select by default); Back / Esc goes back without saving (the title screen when there is no name yet).
//
//   typed text is cut by the field (maxLength) and by progress.setName; a name with nothing usable shows a hint and stays on the screen
import { Behaviour, ui, world, scene, session, input, i18n } from "factoria";
import * as progress from "./progress.js";
import { applyOnce } from "./settings.js";
import { installUiSounds } from "./ui/ui_sounds.js";
import OnScreenKeyboard from "./ui/keyboard.js";

export default class Profile extends Behaviour {
  onStart() {
    applyOnce();
    installUiSounds();
    this.field = world.find("profile_field");
    const current = progress.name();
    if (current) this.field.get("TextField").text = current;
    ui.on("click", (e) => this.onClick(e.entity));
    ui.on("submit", "profile_field", () => this.done());
    ui.on("change", "profile_field", () => this.onChange());
    // B closes the on-screen keyboard first; the screen's own back waits for the next press.
    ui.on("cancel", () => { if (!OnScreenKeyboard.isOpen) this.back(); });
    this.offBack = input.onBack(() => this.back());
    // The error line is written by script: write it again in the new language.
    this.offLanguage = i18n.on("change", () => this.setError(this.errorKey ? i18n.t(this.errorKey) : ""));
  }

  onDestroy() {
    this.offBack?.();
    this.offLanguage?.();
  }

  onClick(entity) {
    const id = entity.id;
    if (id === "profile_ok") return this.done();
    if (id === "profile_back") return this.back();
  }

  /** The player typed (any keyboard): the error line goes away. */
  onChange() {
    this.errorKey = "";
    this.setError("");
  }

  done() {
    const clean = progress.setName(this.field.get("TextField").text);
    if (clean === "") {
      this.errorKey = "profile.empty";
      this.setError(i18n.t(this.errorKey));
      return;
    }
    scene.load(session.profileReturn ?? "scenes/level_select.scene.json");
    session.profileReturn = null;
  }

  back() {
    const target = progress.hasName() ? (session.profileReturn ?? "scenes/level_select.scene.json") : "scenes/main.scene.json";
    session.profileReturn = null;
    scene.load(target);
  }

  setError(text) {
    const e = world.find("profile_error");
    if (e) e.get("Text").text = text;
  }
}
