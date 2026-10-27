// @ts-check
// The screen of a cut-scene: the two black bars, the title card, the Skip button and the subtitles. One entity "cutscene_ui" of the
// HUD (prefabs/ui/hud.prefab.json, so every area scene has it) carries this behaviour; scripts/cutscene.js does the playing and
// calls begin() / end() / showCard() here, and this behaviour gives the player its clock (onUpdate) and hands the pause to it.
//
// The Skip button sits under "cutscene_ui", which therefore has a (clear) Panel: a screen-space Button whose parent is not a UI
// container crashes the engine when it is clicked (ENGINE_FEEDBACK FB-0001).
//
// The subtitles are the `captions` entity (a Captions component) of the same prefab; the options menu's Subtitles switch
// (scripts/settings.js applyScene) turns that entity off and on.
//
// Fields tests read: `shown` (the bars are up), `cardText`, `cardAlpha`, `skipVisible`.
import { Behaviour, world, ui, input, game, scene, i18n } from "factoria";
import * as cutscene from "./cutscene.js";
import { EVENTS } from "./events.js";
import * as glyphs from "./glyphs.js";

/** Seconds a card takes to fade in and out (each). */
const CARD_FADE = 0.6;

export default class CutsceneView extends Behaviour {
  /** The pause menu keeps working: this behaviour runs while the game is paused to tell the player. */
  runWhilePaused = true;

  onStart() {
    /** The scene this belongs to: events of another scene are not for it. */
    this.scenePath = scene.current;
    this.bars = [world.find("cs_bar_top"), world.find("cs_bar_bottom")];
    this.card = world.find("cs_card").get("Text");
    this.skipButton = world.find("cs_skip");
    this.shown = false;
    this.skippable = false;
    this.cardText = "";
    this.cardTime = -1;
    this.cardSeconds = 0;
    this.cardAlpha = 0;
    this.skipVisible = false;
    this.setShown(false);
    ui.on("click", "cs_skip", () => scene.current === this.scenePath && cutscene.skip());
    world.on(EVENTS.deviceChanged, () => this.labelSkip());
    world.on(EVENTS.settingsChanged, () => this.labelSkip());
    cutscene.attach(this);
  }

  /** The bars come up and the Skip button shows (when the cut-scene can be skipped). */
  begin(skippable) {
    this.skippable = skippable;
    this.setShown(true);
    this.labelSkip();
    this.card.text = "";
    this.cardTime = -1;
  }

  /** The bars go. */
  end() {
    this.setShown(false);
    this.cardTime = -1;
    this.cardAlpha = 0;
    this.card.text = "";
  }

  setShown(on) {
    this.shown = on;
    for (const b of this.bars) b.active = on;
    this.skipVisible = on && this.skippable;
    this.skipButton.active = this.skipVisible;
  }

  /** The Skip button says which key skips on the device in use; on a phone it is just "Skip" (tap it). */
  labelSkip() {
    if (!this.shown || !this.skippable) return;
    const key = glyphs.device() === "touch" ? "" : glyphs.label("skip_cutscene");
    this.skipButton.get("Button").text = key ? i18n.t("cutscene.hint", { key }) : i18n.t("cutscene.skip");
  }

  /** A card of big text in the middle of the screen for `seconds`, fading in and out. */
  showCard(text, seconds) {
    this.cardText = text;
    this.card.text = text;
    this.cardTime = 0;
    this.cardSeconds = seconds;
  }

  onUpdate(dt) {
    cutscene.pause(game.paused);
    if (!game.paused) cutscene.tick(dt);
    if (this.cardTime >= 0) {
      this.cardTime += game.paused ? 0 : dt;
      const t = this.cardTime;
      const f = Math.min(CARD_FADE, this.cardSeconds / 2);
      this.cardAlpha = t < f ? t / f : t > this.cardSeconds - f ? Math.max(0, (this.cardSeconds - t) / f) : 1;
      this.card.color = [1, 0.95, 0.85, this.cardAlpha];
      if (t >= this.cardSeconds) {
        this.cardTime = -1;
        this.cardAlpha = 0;
        this.card.text = "";
      }
    }
  }
}
