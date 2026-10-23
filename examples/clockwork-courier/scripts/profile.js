// @ts-check
// The name screen (scenes/profile.scene.json): shown on the first Play (no name yet) and from "rename" on the level select.
// A TextField takes the keyboard (and the phone's own keyboard where the platform shows one); under it an on-screen grid of
// letters and digits made of plain Buttons, so touch and gamepad (d-pad, A) can type too. Keys: key_A..key_Z, key_0..key_9,
// key_space and key_back (delete). Done (or Enter) saves the name through progress.setName and goes on to session.profileReturn
// (the level select by default); Back / Esc goes back without saving (the title screen when there is no name yet).
//
//   typed text is cut to save_data.NAME_MAX characters; a name with nothing usable shows a hint and stays on the screen
import { Behaviour, ui, world, scene, session, input, i18n } from "factoria";
import * as progress from "./progress.js";
import * as saveData from "./save_data.js";
import { applyOnce } from "./settings.js";
import { installUiSounds } from "./ui/ui_sounds.js";

export const KEY_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

export default class Profile extends Behaviour {
  onStart() {
    applyOnce();
    installUiSounds();
    this.field = world.find("profile_field");
    const current = progress.name();
    if (current) this.field.get("TextField").text = current;
    this.buildKeys();
    ui.on("click", (e) => this.onClick(e.entity));
    ui.on("submit", "profile_field", () => this.done());
    ui.on("cancel", () => this.back());
    this.offBack = input.onBack(() => this.back());
    // The error line is written by script: write it again in the new language.
    this.offLanguage = i18n.on("change", () => this.setError(this.errorKey ? i18n.t(this.errorKey) : ""));
  }

  onDestroy() {
    this.offBack?.();
    this.offLanguage?.();
  }

  /** Spawns the letter grid (9 columns) as children of the grid Panel. */
  buildKeys() {
    for (const ch of KEY_CHARS) {
      world.spawn(
        { id: "key_" + ch, components: { Button: { size: [56, 56], text: ch, layer: 210, fontSize: 26, autoShrink: true, color: [0.24, 0.27, 0.36, 0.95] } } },
        { parent: "profile_keys" },
      );
    }
  }

  onClick(entity) {
    const id = entity.id;
    if (id === "profile_ok") return this.done();
    if (id === "profile_back") return this.back();
    if (id === "key_back") return this.edit((t) => Array.from(t).slice(0, -1).join(""));
    if (id === "key_space") return this.edit((t) => t + " ");
    if (/^key_[A-Z0-9]$/.test(id)) this.edit((t) => t + id.slice(4));
  }

  /** Applies `fn` to the field text, keeping it within the name limit. */
  edit(fn) {
    const f = this.field.get("TextField");
    f.text = Array.from(fn(f.text)).slice(0, saveData.NAME_MAX).join("");
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
