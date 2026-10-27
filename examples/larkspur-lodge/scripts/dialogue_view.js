// @ts-check
// The dialogue box: shows the lines scripts/dialogue.js plays. One entity of every area scene has this behaviour (the build script
// assets/src/build_lodge.py adds it); it spawns prefabs/ui/dialogue.prefab.json on start, so the scenes need no UI of their own.
//
// A line shows the speaker's name and the text, revealed character by character at the player's text speed
// (settings.textSpeed, characters per second, 0 = at once). A press of Enter, Space, the gamepad's A, a click or a tap anywhere
// on the box completes the line first and goes on with the next press. When a line has choices they appear under the text once
// it is complete: click or tap one, move the focus with the arrows or the d-pad and press Enter / A, or press 1 to 4.
// The "dialogue_log" action (L, gamepad Y) or the Log button opens the backlog of past lines; Close, the same action again or
// ui_cancel (gamepad B) closes it. The porter is locked while a conversation runs (scripts/dialogue.js), so none of these
// presses also walks him or uses what he faces.
//
// Options (scripts/settings.js), read at start and again on EVENTS.settingsChanged: captionBackground sets the alpha of the box
// (clear, dark, solid), captionSpeakers off leaves the speaker's name out of the box and the log, and autoAdvance (off, slow,
// normal, fast) goes on to the next line by itself once a line without choices is complete and its reading
// time has passed (words at the speed's words per minute, plus 0.6 s, at least 1.2 s). A line with choices always waits for the player.
//
// Fields tests read: `shown` (the line on screen), `revealed`/`total` (characters), `choicesShown`, `logOpen`, `autoTimer` (seconds left before auto-advance, 0 = none).
import { Behaviour, ui, input, world, i18n } from "factoria";
import { EVENTS } from "./events.js";
import * as dialogue from "./dialogue.js";
import * as cutscene from "./cutscene.js";
import { cast } from "./dialogue_data.js";
import { load, CAPTION_BACKGROUNDS, AUTO_ADVANCE } from "./settings.js";
import { MenuStack } from "./ui/menu_stack.js";

/** Seconds after a line appears during which presses do nothing: the press that opened or ended the last line is still down. */
const SETTLE = 0.2;
/** Width in design pixels the text wraps at (the box is 1040 wide with 28 of padding). */
const TEXT_WIDTH = 980;
const FONT = 28;
/** Widgets whose click is the same as a click on the box itself. */
const BOX_IDS = new Set(["dlg_box", "dlg_stack", "dlg_speaker", "dlg_text", "dlg_footer", "dialogue_ui"]);
const NAME_COLOR = { porter: "#8fc7ff" };
const DEFAULT_NAME_COLOR = "#e8c070";
const rgba = (hex) => [parseInt(hex.slice(1, 3), 16) / 255, parseInt(hex.slice(3, 5), 16) / 255, parseInt(hex.slice(5, 7), 16) / 255, 1];

/** Breaks `text` into lines no wider than `width` (design pixels, at the current text size) with "\n", so a line never re-wraps while it is being revealed. */
export function wrap(text, width, fontSize = FONT) {
  const lines = [];
  let line = "";
  for (const word of String(text).split(" ")) {
    const trial = line === "" ? word : `${line} ${word}`;
    if (line !== "" && ui.measureText(trial, { fontSize }).width > width) {
      lines.push(line);
      line = word;
    } else {
      line = trial;
    }
  }
  lines.push(line);
  return lines.join("\n");
}

/** The name the box shows for a speaker id: a character's name, "You" for the porter, nothing for the narrator. */
export function speakerName(speaker) {
  if (speaker === "porter") return i18n.t("cast.porter.name");
  const c = cast.characters[speaker];
  return c ? i18n.t(c.nameKey) : "";
}

export default class DialogueView extends Behaviour {
  onStart() {
    const root = world.spawnPrefab("prefabs/ui/dialogue.prefab.json");
    root.id = "dialogue_ui";
    root.active = false;
    this.root = root;
    this.box = world.find("dlg_box");
    this.speakerLabel = world.find("dlg_speaker").get("Text");
    this.textLabel = world.find("dlg_text").get("Text");
    this.choicesPanel = world.find("dlg_choices");
    this.choiceButtons = [1, 2, 3, 4].map((n) => world.find(`dlg_choice_${n}`));
    this.nextButton = world.find("dlg_next");
    this.logPanel = world.find("dlg_log_panel");
    this.logList = world.find("dlg_log_list");
    this.logPanel.active = false;

    /** The line on screen as { speaker, text, choices }, or null. */
    this.shown = null;
    /** The wrapped text of the line and how many of its characters show. */
    this.full = "";
    this.revealed = 0;
    this.total = 0;
    this.progress = 0;
    this.choicesShown = false;
    this.logOpen = false;
    this.settle = 0;
    this.logEntries = [];
    this.logScroll = 0;
    this.covered = false;
    this.autoTimer = 0;
    this.applyOptions();
    world.on(EVENTS.settingsChanged, () => this.applyOptions());

    world.on(EVENTS.dialogueLine, (line) => this.show(line));
    world.on(EVENTS.dialogueEnded, () => this.hide());
    ui.on("click", "dlg_next", () => this.press());
    ui.on("click", "dlg_log_button", () => this.toggleLog(true));
    ui.on("click", "dlg_log_close", () => this.toggleLog(false));
    this.choiceButtons.forEach((b, i) => ui.on("click", b.id, () => this.pick(i)));
    ui.on("cancel", () => this.logOpen && this.toggleLog(false));
  }

  /** The options that change how the box looks: its background and whether the speaker's name shows. */
  applyOptions() {
    const s = load();
    const bg = CAPTION_BACKGROUNDS.find((b) => b.name === s.captionBackground) ?? CAPTION_BACKGROUNDS[1];
    const panel = this.box.get("Panel");
    panel.color = [panel.color[0], panel.color[1], panel.color[2], bg.alpha];
    this.showNames = s.captionSpeakers;
    if (this.shown) this.speakerLabel.text = (this.showNames && speakerName(this.shown.speaker)) || " ";
  }

  /** Seconds the player needs to read `text` at the auto-advance speed (0 = auto-advance is off). */
  readingTime(text) {
    const wpm = (AUTO_ADVANCE.find((a) => a.name === load().autoAdvance) ?? AUTO_ADVANCE[0]).wpm;
    if (wpm <= 0) return 0;
    const words = text.split(/\s+/).filter(Boolean).length;
    return Math.max(1.2, (words / wpm) * 60 + 0.6);
  }

  // ------------------------------------------------------------------------------------------------------ the line
  show(line) {
    const speed = load().textSpeed;
    const name = load().captionSpeakers ? speakerName(line.speaker) : "";
    const color = NAME_COLOR[line.speaker] ?? DEFAULT_NAME_COLOR;
    this.speakerLabel.text = name || " ";
    this.speakerLabel.color = rgba(color);
    this.shown = { speaker: line.speaker, text: i18n.t(line.textKey), choices: line.choices };
    this.full = wrap(this.shown.text, TEXT_WIDTH);
    this.total = this.full.length;
    this.progress = speed > 0 ? 0 : this.total;
    this.revealed = Math.floor(this.progress);
    this.textLabel.text = this.visibleText(this.revealed);
    this.speed = speed;
    this.settle = SETTLE;
    this.autoTimer = 0;
    if (!this.root.active) world.find("hud")?.behaviour?.clearMessage(); // the box opens where the message line is
    this.root.active = !cutscene.active();
    this.hideChoices();
    this.nextButton.active = true;
    if (this.revealed >= this.total) this.revealDone();
  }

  /** The line with `n` characters showing, followed by one blank line for each line break still to come: the box keeps the height of the whole line. */
  visibleText(n) {
    if (n >= this.total) return this.full === "" ? " " : this.full;
    if (n > 0 && this.full[n - 1] === "\n") n++; // never end on a line break: the last line is not empty
    const rest = this.full.slice(n);
    const pad = (rest.match(/\n/g) ?? []).length;
    return (n > 0 ? this.full.slice(0, n) : " ") + "\n ".repeat(pad);
  }

  hide() {
    this.autoTimer = 0;
    this.shown = null;
    this.root.active = false;
    this.hideChoices();
    if (this.logOpen) this.toggleLog(false);
    this.settle = SETTLE;
  }

  /** The text is complete: the choices (if any) appear and the focus goes to the first one. */
  revealDone() {
    this.revealed = this.total;
    this.textLabel.text = this.full === "" ? " " : this.full;
    const choices = this.shown ? this.shown.choices : [];
    if (choices.length === 0) {
      this.nextButton.active = true;
      this.autoTimer = this.shown ? this.readingTime(this.shown.text) : 0;
      return;
    }
    this.nextButton.active = false;
    this.choicesShown = true;
    this.choiceButtons.forEach((b, i) => {
      b.active = i < choices.length;
      if (i < choices.length) b.get("Button").text = `${i + 1}.  ${i18n.t(choices[i].textKey)}`;
    });
    this.choicesPanel.active = true;
    ui.focus(this.choiceButtons[0]);
  }

  hideChoices() {
    this.choicesShown = false;
    this.choicesPanel.active = false;
    for (const b of this.choiceButtons) b.active = false;
  }

  // ----------------------------------------------------------------------------------------------------- the input
  /** Completes the line being revealed, else goes on to the next line. */
  press() {
    if (!this.shown || this.logOpen || this.settle > 0 || cutscene.active()) return;
    if (this.revealed < this.total) {
      this.revealDone();
      this.settle = 0.1;
      return;
    }
    if (this.choicesShown) return; // an answer has to be picked
    dialogue.advance();
  }

  pick(index) {
    if (!this.shown || this.logOpen || this.settle > 0 || !this.choicesShown || cutscene.active()) return;
    if (index >= this.shown.choices.length) return;
    dialogue.choose(index);
  }

  onUpdate(dt) {
    dialogue.tick(dt);
    if (this.busyFrames > 0 && --this.busyFrames === 0) MenuStack.busy = false;
    if (this.settle > 0) this.settle -= dt;
    // A cut-scene covers the conversation that asked for it: the box goes away and comes back (with the same line) when it is over.
    const covered = cutscene.active();
    if (covered !== this.covered) {
      this.covered = covered;
      this.root.active = !covered && this.shown !== null;
      if (!covered) this.settle = SETTLE;
    }
    if (covered) return;
    if (input.pressed("dialogue_log") && (this.shown || this.logOpen)) this.toggleLog(!this.logOpen);
    if (!this.shown) return;
    if (this.revealed < this.total && !this.logOpen) {
      this.progress += dt * this.speed;
      const n = Math.min(this.total, Math.floor(this.progress));
      if (n !== this.revealed) {
        this.revealed = n;
        this.textLabel.text = this.visibleText(n);
        if (n >= this.total) this.revealDone();
      }
    }
    if (this.autoTimer > 0 && this.revealed >= this.total && !this.choicesShown && !this.logOpen && this.settle <= 0) {
      this.autoTimer -= dt;
      if (this.autoTimer <= 0) {
        this.autoTimer = 0;
        dialogue.advance();
        return;
      }
    }
    if (this.choicesShown && !this.logOpen) {
      for (let i = 0; i < this.shown.choices.length; i++) if (input.pressed(`choice_${i + 1}`)) this.pick(i);
    }
    // A click or a tap on the box itself (not on a button) is the same as Next.
    const mouse = input.mouse;
    if (mouse.pressed("left") && !this.logOpen) {
      const p = mouse.position;
      const w = ui.widgetAt(p.x, p.y);
      if (!w || BOX_IDS.has(w.id)) this.press();
    }
    if (this.logScroll > 0) {
      this.logScroll--;
      this.logList.get("ScrollList").scroll = 1e6; // clamped to the end: the newest line shows
    }
  }

  // ----------------------------------------------------------------------------------------------------- the log
  toggleLog(open) {
    if (open === this.logOpen) return;
    if (open) this.focusBefore = ui.focused;
    this.logOpen = open;
    this.logPanel.active = open;
    // Escape is ui_cancel (closes the log) and "pause" at once: while the log is open, and for two frames after, the pause menu waits.
    if (open) MenuStack.busy = true;
    else this.busyFrames = 2;
    for (const e of this.logEntries) e.destroy();
    this.logEntries = [];
    if (!open) {
      // The focus goes back to what it was (the answer the player was on), not to the first one.
      const back = this.focusBefore;
      this.focusBefore = null;
      if (back && back.active && this.shown) ui.focus(back);
      return;
    }
    for (const entry of dialogue.log()) {
      const name = load().captionSpeakers ? speakerName(entry.speaker) : "";
      const color = NAME_COLOR[entry.speaker] ?? DEFAULT_NAME_COLOR;
      const text = i18n.t(entry.key);
      const e = world.spawn(
        {
          components: {
            Text: {
              text: name ? `[c:${color}]${name}[/c]  ${text}` : text,
              fontSize: 22,
              maxWidth: 840,
              markup: true,
              layer: 252,
              space: "screen",
              color: entry.speaker === "" || entry.speaker === "narrator" ? [0.75, 0.78, 0.85, 1] : [0.96, 0.95, 0.92, 1],
            },
          },
        },
        { parent: this.logList },
      );
      this.logEntries.push(e);
    }
    this.logScroll = 3;
  }
}
