// @ts-check
// The journal and the puzzle screens. One entity of every area scene (id "screens", added by assets/src/build_lodge.py) has
// this behaviour; it spawns all its UI itself, so the scenes need no UI of their own.
//
// The journal has three pages, switched by the tab buttons, Tab / PageUp / PageDown or the gamepad shoulders:
//   Items     what the porter carries. Pick one to read it and turn it in 3D (drag with the mouse or a finger, right stick or
//             Q / E; the + and - buttons, pinch, R / V or the gamepad triggers come closer or go farther). "Combine" joins two items by the table data/combos.json;
//             "Piece together" opens the torn-letter puzzle.
//   Notebook  every clue known (a clue is a set story flag, data/notebook.json) and every deduction made, in rich text. Click
//             an entry to find it on the board.
//   Board     the clues as cards. Pick two to link them: when data/notebook.json has a deduction for the pair, it is made and
//             a string is drawn. Undo (Z, gamepad left trigger) and Redo (Y, right trigger) take deductions back and forth.
// A puzzle screen (drawer, timetable, letter, fuse; the logic is scripts/puzzles.js) opens from the object in the lodge
// (interactable kind "puzzle") and, for the letter, from the Items page.
//
// Opening a screen locks the porter ("screen") and tells the camera script to ignore drags (scripts/ui/screen_state.js). Escape
// is ui_cancel and "pause" at once, so MenuStack.busy keeps the pause menu away while a screen is open and two frames after.
// Closing releases the porter two frames later too: the click or press that closed the screen must not also walk him.
//
// The 3D view of an item is a second perspective Camera, spawned at run time, that draws a small stage far from the lodge
// (y = 300) into the "hole" the Items page leaves in the UI: the UI draws over all cameras, so the page is four opaque bands around
// a clear rectangle. Nothing here is a draggable widget: the turning reads input.mouse, which also stays clear of
// ENGINE_FEEDBACK LL/FB-0001 (UiSystem::update_drag).
//
// The UI is rebuilt whenever its state changes (a dirty flag handled in onUpdate, never inside a click handler); every widget id
// carries the serial of the build, so ids never collide with the previous build that is still alive until the end of the frame.
// Tests find a widget with `world.find(screens.id("tab_board"))`.
//
// Fields tests read: `mode` (null | "journal" | "puzzle"), `tab`, `puzzle`, `selItem`, `sel` (board), `message`, `view` ({yaw,
// pitch, zoom, item}).
import { Behaviour, ui, input, world, i18n } from "factoria";
import { EVENTS } from "./events.js";
import { MenuStack } from "./ui/menu_stack.js";
import { screenState } from "./ui/screen_state.js";
import * as kit from "./ui/kit.js";
import * as items from "./items.js";
import * as puzzles from "./puzzles.js";
import * as notebook from "./notebook.js";

const GOLD = [0.91, 0.75, 0.35, 1];
const GREY = [0.62, 0.65, 0.72, 1];
const GOOD = [0.62, 0.85, 0.65, 1];
const DARK = [0.045, 0.055, 0.085, 1];
const TABS = ["items", "notebook", "board"];
/** The hole of the Items page where the 3D view shows, in design pixels: x, y, w, h. */
const HOLE = { x: 430, y: 84, w: 400, h: 360 };
/** Where the hole really is: the screens are mirrored in a right-to-left language (kit.mx), so is the 3D view. */
const hole = () => ({ x: kit.mx(HOLE.x, HOLE.w), y: HOLE.y, w: HOLE.w, h: HOLE.h });
/** Where the 3D stage stands: far above the lodge, so no lodge mesh or light reaches it. */
const STAGE_Y = 300;
const HINT_Y = 692;

/** The lodge lights are strong: the parts of an item are drawn darker so a pale one is not a white blot. */
const dim = (c) => [c[0] * 0.45, c[1] * 0.45, c[2] * 0.45, c[3]];
const clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, v));

export default class Screens extends Behaviour {
  onStart() {
    /** null | "journal" | "puzzle" */
    this.mode = null;
    this.tab = "items";
    this.puzzle = "";
    this.backToJournal = false;
    this.selItem = "";
    this.combineFrom = "";
    /** The node (clue or deduction id) picked on the board. */
    this.sel = "";
    this.message = "";
    this.strip = -1;
    this.dirty = false;
    this.serial = 0;
    this.p = "scr0_";
    this.handlers = {};
    this.root = null;
    this.releaseIn = 0;
    this.view = { yaw: 25, pitch: 15, zoom: 1, item: "" };
    this.viewParts = null;
    this.viewCam = null;
    this.viewLights = [];
    this.viewSerial = 0;
    this.dragging = false;
    this.pinchLast = 0;
    this.hudShown = null;

    this.makeHud();
    // The HUD buttons are written by this script (their text, and their side of the screen in Hebrew): again in the new language.
    i18n.on("change", () => {
      this.makeHud();
      this.dirty = true;
    });

    notebook.markSeen();
    world.on(EVENTS.flagChanged, () => this.announceClues());
    ui.on("click", (e) => this.onClick(e.entity.id));
    ui.on("cancel", () => this.mode && this.back());
  }

  /** The scene is going away (an area change, a chapter fade, a load): a screen left open must not leave the lodge locked. */
  onDestroy() {
    if (this.mode || this.releaseIn > 0) {
      screenState.open = false;
      MenuStack.busy = false;
    }
    this.mode = null;
    this.releaseIn = 0;
    this.destroyView();
  }

  /** The two HUD buttons, in the current language (a language change builds them again). */
  makeHud() {
    this.hudItems?.destroy();
    this.hudNotebook?.destroy();
    this.hudItems = world.spawn(this.hudButton("hud_items", 800, i18n.t("screens.hudItems"), 220));
    this.hudNotebook = world.spawn(this.hudButton("hud_notebook", 1030, i18n.t("screens.hudNotebook"), 240));
    this.hudItems.active = this.hudNotebook.active = this.hudShown ?? false;
  }

  hudButton(id, x, text, w) {
    const b = kit.button(id, x, 12, w, 40, text, { size: 20 });
    b.components.Button.layer = 200;
    b.components.Button.autoShrink = true; // at 200 % text the label shrinks inside the button
    b.components.Button.minFontSize = 8;
    b.components.Button.color = [0.1, 0.13, 0.2, 0.85];
    return b;
  }

  /** The full entity id of a widget of the current build: `name` as used in this file ("tab_board", "card_oil"). */
  id(name) {
    return this.p + name;
  }

  // ---------------------------------------------------------------------------------------------------- opening and closing
  get isOpen() {
    return this.mode !== null;
  }

  porterBehaviour() {
    return world.find("porter")?.behaviour ?? null;
  }

  /** Opens the journal on a page ("items" | "notebook" | "board"). Returns false when the porter is busy (a conversation). */
  open(tab = "items") {
    if (this.mode === "journal") {
      this.tab = tab;
      this.message = "";
      this.dirty = true;
      return true;
    }
    if (this.mode || this.releaseIn > 0 || this.porterBehaviour()?.locked) return false;
    this.begin();
    this.mode = "journal";
    this.tab = tab;
    this.message = "";
    this.combineFrom = "";
    const list = items.list();
    if (!list.includes(this.selItem)) this.selItem = list[0] ?? "";
    this.dirty = true;
    return true;
  }

  /** Opens a puzzle screen. Returns false when one is up already. */
  openPuzzle(id, backToJournal = false) {
    if (!puzzles.IDS.includes(id)) return false;
    if (this.mode === "journal" && backToJournal) {
      this.mode = "puzzle";
    } else if (this.mode) {
      return false;
    } else {
      if (this.releaseIn > 0) return false;
      this.begin();
      this.mode = "puzzle";
    }
    this.puzzle = id;
    this.backToJournal = backToJournal;
    this.message = "";
    this.strip = -1;
    this.dirty = true;
    return true;
  }

  begin() {
    this.releaseIn = 0;
    this.porterBehaviour()?.lock("screen");
    screenState.open = true;
    MenuStack.busy = true;
  }

  /** One step back: a puzzle opened from the Items page returns to it, anything else closes. */
  back() {
    if (this.mode === "puzzle" && this.backToJournal) {
      this.mode = "journal";
      this.tab = "items";
      this.message = "";
      this.dirty = true;
      return;
    }
    this.close();
  }

  close() {
    if (!this.mode) return;
    this.mode = null;
    this.destroyView();
    if (this.root) this.root.destroy();
    this.root = null;
    this.dirty = false;
    ui.focus(null);
    this.releaseIn = 2;
  }

  // ---------------------------------------------------------------------------------------------------------------- the HUD
  announceClues() {
    const fresh = notebook.takeNew();
    if (this.mode || fresh.length === 0) return;
    const hud = world.find("hud")?.behaviour;
    if (hud) hud.say("notebook.new", { name: i18n.t(notebook.titleKey(fresh[fresh.length - 1])) });
  }

  updateHud() {
    const show = !this.mode && this.releaseIn === 0 && !!this.porterBehaviour() && !this.porterBehaviour().locked;
    if (show === this.hudShown) return;
    this.hudShown = show;
    this.hudItems.active = show;
    this.hudNotebook.active = show;
  }

  // ----------------------------------------------------------------------------------------------------------------- per frame
  onUpdate(dt) {
    if (this.releaseIn > 0 && --this.releaseIn === 0) {
      this.porterBehaviour()?.unlock("screen");
      screenState.open = false;
      MenuStack.busy = false;
    }
    this.updateHud();
    if (!this.mode) {
      if (this.releaseIn === 0) {
        if (input.pressed("inventory")) this.open("items");
        else if (input.pressed("notebook")) this.open("notebook");
      }
      return;
    }
    if (this.mode === "journal") {
      if (input.pressed("inventory")) this.tab === "items" ? this.close() : this.open("items");
      else if (input.pressed("notebook")) this.tab === "notebook" ? this.close() : this.open("notebook");
      else if (input.pressed("tab_next")) this.open(TABS[(TABS.indexOf(this.tab) + 1) % TABS.length]);
      else if (input.pressed("tab_prev")) this.open(TABS[(TABS.indexOf(this.tab) + TABS.length - 1) % TABS.length]);
      if (this.tab === "board") {
        if (input.pressed("board_undo")) this.undo();
        else if (input.pressed("board_redo")) this.redo();
      }
    }
    if (this.dirty && this.mode) this.build();
    if (this.mode === "journal" && this.tab === "items") this.turnItem(dt);
  }

  // ------------------------------------------------------------------------------------------------------------------- clicks
  on(name, fn) {
    this.handlers[name] = fn;
  }

  onClick(id) {
    if (id === "hud_items" || id === "hud_notebook") {
      ui.focus(null);
      this.open(id === "hud_items" ? "items" : "notebook");
      return;
    }
    if (!this.mode || !id.startsWith(this.p)) return;
    const fn = this.handlers[id.slice(this.p.length)];
    if (fn) fn();
  }

  say(key, args = {}) {
    this.message = key ? i18n.t(key, args) : "";
    this.dirty = true;
  }

  // -------------------------------------------------------------------------------------------------------------------- build
  build() {
    const focusName = this.focusName();
    if (this.root) this.root.destroy();
    this.serial++;
    this.p = `scr${this.serial}_`;
    this.handlers = {};
    this.dirty = false;
    this.defaultFocus = "";
    const children = this.mode === "puzzle" ? this.puzzleChildren() : this.journalChildren();
    this.root = world.spawn(kit.root(this.id("root"), children));
    if (this.mode === "journal" && this.tab === "items") this.syncView();
    else this.destroyView();
    // A button that is greyed out cannot take the focus (ui.focus throws): fall back to the default, then to the close button.
    const canFocus = (e) => !!e && (!e.has("Button") || e.get("Button").interactable);
    const pick = (name) => (name ? world.find(this.id(name)) : null);
    const want = [pick(focusName), pick(this.defaultFocus), pick("close")].find(canFocus);
    if (want) ui.focus(want);
  }

  /** The name (id without the build prefix) of the focused widget of the build that is going away. */
  focusName() {
    const f = ui.focused;
    return f && f.alive && f.id.startsWith(this.p) ? f.id.slice(this.p.length) : "";
  }

  // ----------------------------------------------------------------------------------------------------------------- journal
  journalChildren() {
    const out = [];
    if (this.tab === "items") {
      const { x, y, w, h } = HOLE;
      const solid = [0.045, 0.055, 0.085, 1];
      out.push(kit.rect(this.id("band_top"), 0, 0, kit.W, y, solid));
      out.push(kit.rect(this.id("band_left"), 0, y, x, kit.H - y, solid));
      out.push(kit.rect(this.id("band_right"), x + w, y, kit.W - x - w, kit.H - y, solid));
      out.push(kit.rect(this.id("band_bottom"), x, y + h, w, kit.H - y - h, solid));
      const gold = [0.78, 0.62, 0.28, 1];
      out.push(kit.rect(this.id("frame_t"), x - 3, y - 3, w + 6, 3, gold, kit.LAYER.frame));
      out.push(kit.rect(this.id("frame_b"), x - 3, y + h, w + 6, 3, gold, kit.LAYER.frame));
      out.push(kit.rect(this.id("frame_l"), x - 3, y - 3, 3, h + 6, gold, kit.LAYER.frame));
      out.push(kit.rect(this.id("frame_r"), x + w, y - 3, 3, h + 6, gold, kit.LAYER.frame));
    } else {
      out.push(kit.rect(this.id("bg"), 0, 0, kit.W, kit.H, DARK));
    }
    const names = { items: "screens.items", notebook: "screens.notebook", board: "screens.board" };
    TABS.forEach((t, i) => {
      out.push(kit.button(this.id(`tab_${t}`), 40 + i * 200, 16, 190, 52, i18n.t(names[t]), { accent: this.tab === t }));
      this.on(`tab_${t}`, () => this.open(t));
    });
    out.push(kit.button(this.id("close"), 1100, 16, 140, 52, i18n.t("screens.close")));
    this.on("close", () => this.close());
    out.push(kit.label(this.id("hint"), 40, HINT_Y, 1200, i18n.t("screens.hintJournal"), { size: 17, color: GREY, height: 26 }));
    if (this.tab === "items") out.push(...this.itemsChildren());
    else if (this.tab === "notebook") out.push(...this.notebookChildren());
    else out.push(...this.boardChildren());
    return out;
  }

  // ----------------------------------------------------------------------------------------------------------------- items
  itemsChildren() {
    const out = [];
    const list = items.list();
    if (!list.includes(this.selItem)) this.selItem = list[0] ?? "";
    if (list.length === 0) {
      out.push(kit.label(this.id("empty"), 50, 100, 340, i18n.t("screens.empty"), { size: 22, color: GREY, height: 60 }));
      return out;
    }
    const rows = list.map((id) => {
      const it = items.get(id);
      const name = i18n.t(it.nameKey);
      const b = kit.listButton(this.id(`item_${id}`), 340, name, { accent: id === this.selItem || id === this.combineFrom, height: 48 });
      this.on(`item_${id}`, () => this.pickItem(id));
      return b;
    });
    out.push(kit.list(this.id("list"), 40, 96, 370, 500, rows));
    this.defaultFocus = `item_${this.selItem}`;

    const it = items.get(this.selItem);
    const kinds = { key: "screens.kindKey", clue: "screens.kindClue", tool: "screens.kindTool" };
    out.push(kit.label(this.id("name"), 852, 96, 390, i18n.t(it.nameKey), { size: 30, color: GOLD, height: 40 }));
    out.push(kit.label(this.id("kind"), 852, 140, 390, i18n.t(kinds[it.kind] ?? "screens.kindTool"), { size: 18, color: GREY, height: 32 }));
    out.push(kit.label(this.id("desc"), 852, 176, 390, i18n.t(it.descriptionKey), { size: 21, height: 120 }));
    if (it.readKey) {
      let key = it.readKey;
      let args = {};
      if (this.selItem === puzzles.data.letter.item) {
        key = puzzles.solved("letter") ? `${it.readKey}Whole` : it.readKey;
        args = { strips: puzzles.letterKeys().map((k) => i18n.t(k)).join("\n") };
      }
      out.push(kit.label(this.id("read"), 852, 300, 390, i18n.t(key, args), { size: 19, markup: true, height: 280 }));
    }

    out.push(kit.label(this.id("viewhint"), HOLE.x + 4, HOLE.y + HOLE.h + 10, HOLE.w - 8, i18n.t("item.view.hint"), { size: 17, color: GREY, height: 70 }));
    const combining = this.combineFrom !== "";
    // Combine and Piece together sit under the list: the pad's Down from the last item reaches them.
    out.push(kit.button(this.id("combine"), 40, 606, 170, 52, i18n.t(combining ? "screens.cancel" : "screens.combine"), { enabled: combining || list.length >= 2, accent: combining }));
    this.on("combine", () => {
      if (this.combineFrom) {
        this.combineFrom = "";
        this.say("");
      } else {
        this.combineFrom = this.selItem;
        this.say("combo.pick", { name: i18n.t(items.get(this.selItem).nameKey) });
      }
    });
    if (this.selItem === puzzles.data.letter.item && !puzzles.solved("letter")) {
      out.push(kit.button(this.id("piece"), 220, 606, 190, 52, i18n.t("screens.pieceTogether")));
      this.on("piece", () => this.openPuzzle("letter", true));
    }
    out.push(kit.label(this.id("msg"), 440, 530, 390, this.message || " ", { size: 20, color: GOLD, height: 70 }));
    // Zoom buttons in the corner of the view, for a mouse or a finger without a pinch (a modal panel keeps the wheel for itself).
    out.push(kit.button(this.id("zoom_out"), HOLE.x + HOLE.w - 100, HOLE.y + HOLE.h - 52, 44, 44, "-", { size: 28 }));
    out.push(kit.button(this.id("zoom_in"), HOLE.x + HOLE.w - 50, HOLE.y + HOLE.h - 52, 44, 44, "+", { size: 28 }));
    this.on("zoom_out", () => this.zoom(0.15));
    this.on("zoom_in", () => this.zoom(-0.15));
    return out;
  }

  zoom(by) {
    this.view.zoom = clamp(this.view.zoom + by, 0.45, 1.5);
    this.applyView();
  }

  pickItem(id) {
    if (this.combineFrom && id !== this.combineFrom) {
      const r = items.combine(this.combineFrom, id);
      this.combineFrom = "";
      if (r.ok && r.result) this.selItem = r.result;
      this.say(r.textKey);
      return;
    }
    if (this.combineFrom === id) return;
    this.selItem = id;
    this.message = "";
    this.dirty = true;
  }

  // ------------------------------------------------------------------------------------------------------- the 3D item view
  /** Makes the view camera, the stage and its lights for the item selected (idempotent). */
  syncView() {
    const it = items.get(this.selItem);
    if (!this.viewCam || !this.viewCam.alive) {
      this.viewSerial++;
      const s = `iv${this.viewSerial}`;
      this.viewCam = world.spawn({
        id: `${s}_cam`,
        components: {
          Transform: { position: [0, STAGE_Y, 3], rotation: [0, 0, 0] },
          Camera: {
            projection: "perspective",
            fov: 35,
            nearPlane: 0.05,
            farPlane: 40,
            primary: true,
            depth: 50,
            clear: true,
            clearColor: [0.09, 0.1, 0.15, 1],
            viewport: [hole().x / kit.W, HOLE.y / kit.H, HOLE.w / kit.W, HOLE.h / kit.H],
          },
        },
      });
      this.viewLights = [
        world.spawn({ id: `${s}_l1`, components: { Transform: { position: [2.2, STAGE_Y + 2.4, 4] }, Light: { type: "point", intensity: 3, range: 14, color: [1, 0.95, 0.85, 1] } } }),
        world.spawn({ id: `${s}_l2`, components: { Transform: { position: [-3, STAGE_Y - 1, 3] }, Light: { type: "point", intensity: 1.2, range: 14, color: [0.7, 0.8, 1, 1] } } }),
      ];
      this.view.item = "";
    }
    if (this.view.item !== this.selItem) {
      if (this.viewParts && this.viewParts.alive) {
        this.viewParts.active = false;
        this.viewParts.destroy();
      }
      this.viewParts = null;
      this.view.item = this.selItem;
      this.view.yaw = 25;
      this.view.pitch = 15;
      this.view.zoom = 1;
      if (it && it.view) {
        this.viewSerial++;
        const s = `iv${this.viewSerial}`;
        this.viewParts = world.spawn({
          id: `${s}_stage`,
          components: { Transform: { position: [0, STAGE_Y, 0], rotation: [this.view.pitch, this.view.yaw, 0] } },
          children: it.view.parts.map((part, i) => ({
            id: `${s}_p${i}`,
            components: {
              Transform: { position: part.position ?? [0, 0, 0], rotation: part.rotation ?? [0, 0, 0], scale: part.scale ?? [1, 1, 1] },
              MeshRenderer: {
                mesh: part.mesh,
                color: dim(part.color ?? [1, 1, 1, 1]),
                metallic: part.metallic ?? 0,
                roughness: part.roughness ?? 0.6,
                emissive: part.emissive ?? [0, 0, 0, 1],
                castShadows: false,
                receiveShadows: false,
              },
            },
          })),
        });
        this.viewDistance = it.view.distance;
      }
    }
    this.applyView();
  }

  destroyView() {
    for (const e of [this.viewCam, this.viewParts, ...this.viewLights]) {
      if (e && e.alive) {
        e.active = false;
        e.destroy();
      }
    }
    this.viewCam = null;
    this.viewParts = null;
    this.viewLights = [];
    this.view.item = "";
  }

  applyView() {
    if (this.viewParts && this.viewParts.alive) this.viewParts.get("Transform").rotation = [this.view.pitch, this.view.yaw, 0];
    if (this.viewCam && this.viewCam.alive) this.viewCam.position = [0, STAGE_Y, (this.viewDistance ?? 3) * 1.25 * this.view.zoom];
  }

  /** Turning and zooming the item: mouse drag inside the hole (a finger too), the right stick or Q / E, pinch, R / V, the triggers. */
  turnItem(dt) {
    if (!this.viewCam || !this.viewCam.alive) return;
    const m = input.mouse;
    const v = this.view;
    const hl = hole();
    const inside = (p) => p.x >= hl.x && p.x < hl.x + hl.w && p.y >= hl.y && p.y < hl.y + hl.h;
    const touches = input.touches;
    if (m.pressed("left") && inside(m.position) && touches.length < 2 && !ui.hovered?.has("Button")) this.dragging = true;
    if (!m.down("left")) this.dragging = false;
    if (this.dragging && touches.length < 2) {
      const d = m.delta;
      v.yaw += d.x * 0.7;
      v.pitch = clamp(v.pitch + d.y * 0.5, -80, 80);
    }
    const ax = input.axis("camera_left", "camera_right");
    const ay = input.axis("camera_up", "camera_down");
    v.yaw += ax * 140 * dt;
    v.pitch = clamp(v.pitch + ay * 100 * dt, -80, 80);
    const z = input.axis("view_zoom_out", "view_zoom_in");
    if (z !== 0) v.zoom = clamp(v.zoom - z * 0.8 * dt, 0.45, 1.5);
    if (touches.length >= 2) {
      const a = touches[0].position;
      const b = touches[1].position;
      const dist = Math.hypot(a.x - b.x, a.y - b.y);
      if (this.pinchLast > 0) v.zoom = clamp(v.zoom - (dist - this.pinchLast) * 0.004, 0.45, 1.5);
      this.pinchLast = dist;
    } else this.pinchLast = 0;
    this.applyView();
  }

  // --------------------------------------------------------------------------------------------------------------- notebook
  notebookChildren() {
    const entries = notebook.entries();
    if (entries.length === 0) return [kit.label(this.id("empty"), 50, 100, 1100, i18n.t("screens.noClues"), { size: 24, color: GREY, height: 60 })];
    const rows = entries.map((e) => {
      const color = e.deduction ? "#9fd9a5" : "#e8c070";
      const text = `[c:${color}][b]${i18n.t(e.titleKey)}[/b][/c]\n${i18n.t(e.textKey)}`;
      this.on(`note_${e.id}`, () => {
        this.sel = e.id;
        this.tab = "board";
        this.message = "";
        this.dirty = true;
      });
      return kit.listButton(this.id(`note_${e.id}`), 1150, text, { markup: true, auto: true, size: 21 });
    });
    this.defaultFocus = `note_${entries[0].id}`;
    return [kit.list(this.id("list"), 40, 84, 1200, 590, rows)];
  }

  // ------------------------------------------------------------------------------------------------------------------ board
  /** Where a card's centre is on the board: clue cards in a grid of three columns, deduction cards in a column on the right. */
  cardBox(id) {
    const ci = notebook.clues.findIndex((c) => c.id === id);
    if (ci >= 0) return { x: 40 + (ci % 3) * 240, y: 124 + Math.floor(ci / 3) * 58, w: 230, h: 48 };
    const di = notebook.deductions.findIndex((d) => d.id === id);
    return { x: 800, y: 124 + di * 58, w: 440, h: 48 };
  }

  boardChildren() {
    const out = [];
    out.push(kit.label(this.id("h_clues"), 40, 88, 400, i18n.t("screens.clues"), { size: 20, color: GREY, height: 34 }));
    out.push(kit.label(this.id("h_ded"), 800, 88, 400, i18n.t("screens.deductions"), { size: 20, color: GREY, height: 34 }));
    const centre = (id) => {
      const b = this.cardBox(id);
      return [b.x + b.w / 2, b.y + b.h / 2];
    };
    for (const id of notebook.made()) {
      const d = notebook.node(id);
      const [cx, cy] = centre(id);
      for (const end of [d.a, d.b]) {
        const [ex, ey] = centre(end);
        out.push(kit.line(this.id(`string_${id}_${end}`), ex, ey, cx, cy, [0.9, 0.7, 0.3, 0.9], 3));
      }
    }
    let first = "";
    for (const c of notebook.clues) {
      const b = this.cardBox(c.id);
      if (notebook.known(c.id)) {
        out.push(kit.button(this.id(`card_${c.id}`), b.x, b.y, b.w, b.h, i18n.t(notebook.titleKey(c.id)), { size: 19, accent: this.sel === c.id }));
        this.on(`card_${c.id}`, () => this.pickNode(c.id));
        if (!first) first = `card_${c.id}`;
      } else {
        out.push(kit.rect(this.id(`slot_${c.id}`), b.x, b.y, b.w, b.h, [0.08, 0.09, 0.13, 1]));
      }
    }
    for (const d of notebook.deductions) {
      const b = this.cardBox(d.id);
      if (notebook.known(d.id)) {
        out.push(kit.button(this.id(`card_${d.id}`), b.x, b.y, b.w, b.h, i18n.t(notebook.titleKey(d.id)), { size: 19, accent: this.sel === d.id, color: [0.14, 0.3, 0.2, 0.98] }));
        this.on(`card_${d.id}`, () => this.pickNode(d.id));
      } else {
        out.push(kit.rect(this.id(`slot_${d.id}`), b.x, b.y, b.w, b.h, [0.08, 0.09, 0.13, 1]));
      }
    }
    this.defaultFocus = first || "tab_board";
    if (this.sel && notebook.known(this.sel)) {
      out.push(kit.label(this.id("detail"), 40, 440, 720, `[c:#e8c070][b]${i18n.t(notebook.titleKey(this.sel))}[/b][/c]\n${i18n.t(notebook.textKey(this.sel))}`, { size: 20, markup: true, height: 230 }));
    }
    const undoable = notebook.made().length > 0;
    const redoable = notebook.redoable().length > 0;
    out.push(kit.button(this.id("undo"), 800, 570, 150, 48, i18n.t("screens.undo"), { enabled: undoable }));
    out.push(kit.button(this.id("redo"), 970, 570, 150, 48, i18n.t("screens.redo"), { enabled: redoable }));
    this.on("undo", () => this.undo());
    this.on("redo", () => this.redo());
    out.push(kit.label(this.id("msg"), 800, 630, 440, this.message || " ", { size: 20, color: GOLD, height: 56 }));
    return out;
  }

  pickNode(id) {
    if (!this.sel || !notebook.known(this.sel)) {
      this.sel = id;
      this.say("board.picked", { name: i18n.t(notebook.titleKey(id)) });
      return;
    }
    if (this.sel === id) {
      this.sel = "";
      this.say("");
      return;
    }
    const r = notebook.link(this.sel, id);
    this.sel = r.made ?? "";
    this.say(r.key, r.args);
  }

  undo() {
    const r = notebook.undo();
    if (r.ok) this.sel = "";
    this.say(r.key, r.args);
  }

  redo() {
    const r = notebook.redo();
    this.say(r.key, r.args);
  }

  // ------------------------------------------------------------------------------------------------------------------ puzzles
  puzzleChildren() {
    const id = this.puzzle;
    const out = [];
    out.push(kit.rect(this.id("dim"), 0, 0, kit.W, kit.H, [0, 0, 0, 0.72]));
    out.push(kit.rect(this.id("win_f"), 237, 57, 806, 606, [0.78, 0.62, 0.28, 1], kit.LAYER.back + 1));
    out.push(kit.rect(this.id("win"), 240, 60, 800, 600, [0.07, 0.08, 0.12, 1], kit.LAYER.back + 2));
    out.push(kit.label(this.id("title"), 270, 76, 740, i18n.t(`puzzle.${id}.title`), { size: 32, color: GOLD, height: 44 }));
    out.push(kit.label(this.id("intro"), 270, 124, 740, i18n.t(`puzzle.${id}.intro`), { size: 20, height: 60 }));
    out.push(kit.label(this.id("msg"), 270, 574, 600, this.message || " ", { size: 20, color: GOLD, height: 50 }));
    out.push(kit.button(this.id("close"), 890, 604, 130, 44, i18n.t(this.backToJournal ? "screens.cancel" : "screens.close"), { size: 20 }));
    this.on("close", () => this.back());
    const parts = { drawer: () => this.drawerChildren(), timetable: () => this.timetableChildren(), letter: () => this.letterChildren(), fuse: () => this.fuseChildren() };
    out.push(...parts[id]());
    return out;
  }

  /** Runs a puzzle action and shows its line. */
  act(r) {
    this.say(r.key, r.args ?? {});
    return r;
  }

  drawerChildren() {
    const out = [];
    const solved = puzzles.solved("drawer");
    const dials = puzzles.state("drawer").dials;
    out.push(kit.label(this.id("hint"), 270, 190, 740, i18n.t("puzzle.drawer.hint"), { size: 18, color: GREY, height: 100 }));
    dials.forEach((digit, i) => {
      const x = 380 + i * 130;
      out.push(kit.button(this.id(`up_${i}`), x, 240, 100, 50, "+", { size: 28, enabled: !solved }));
      out.push(kit.rect(this.id(`dial_bg_${i}`), x, 296, 100, 70, [0.14, 0.12, 0.08, 1], kit.LAYER.back + 3));
      out.push(kit.label(this.id(`dial_${i}`), x + 33, 300, 60, String(digit), { size: 56, color: GOLD, height: 90 }));
      out.push(kit.button(this.id(`down_${i}`), x, 372, 100, 50, "-", { size: 28, enabled: !solved }));
      this.on(`up_${i}`, () => {
        puzzles.turnDial(i, 1);
        this.say("");
      });
      this.on(`down_${i}`, () => {
        puzzles.turnDial(i, -1);
        this.say("");
      });
    });
    out.push(kit.button(this.id("try"), 540, 450, 200, 52, i18n.t("puzzle.drawer.try"), { enabled: !solved }));
    this.on("try", () => this.act(puzzles.tryCode()));
    this.defaultFocus = "up_0";
    return out;
  }

  timetableChildren() {
    const out = [];
    const solved = puzzles.solved("timetable");
    out.push(kit.label(this.id("notes"), 270, 186, 740, i18n.t("puzzle.timetable.notes"), { size: 18, color: GREY, height: 26 }));
    [1, 2, 3].forEach((n, i) => out.push(kit.label(this.id(`note${n}`), 270, 212 + i * 30, 740, i18n.t(`puzzle.timetable.note${n}`), { size: 20, color: [0.85, 0.82, 0.7, 1], height: 28 })));
    const order = puzzles.timetableOrder();
    order.forEach((sid, i) => {
      const y = 320 + i * 50;
      out.push(kit.rect(this.id(`row_bg_${i}`), 290, y, 300, 42, [0.15, 0.18, 0.26, 1], kit.LAYER.back + 3));
      out.push(kit.label(this.id(`row_${i}`), 304, y + 8, 280, `${i + 1}.  ${i18n.t(`puzzle.service.${sid}`)}`, { size: 22, height: 40 }));
      out.push(kit.button(this.id(`earlier_${i}`), 610, y, 130, 42, i18n.t("puzzle.timetable.up"), { size: 19, enabled: !solved && i > 0 }));
      out.push(kit.button(this.id(`later_${i}`), 750, y, 130, 42, i18n.t("puzzle.timetable.down"), { size: 19, enabled: !solved && i < order.length - 1 }));
      this.on(`earlier_${i}`, () => {
        puzzles.moveService(i, -1);
        this.say("");
      });
      this.on(`later_${i}`, () => {
        puzzles.moveService(i, 1);
        this.say("");
      });
    });
    out.push(kit.button(this.id("check"), 290, 524, 260, 44, i18n.t("puzzle.timetable.check"), { enabled: !solved, size: 20 }));
    this.on("check", () => this.act(puzzles.checkTimetable()));
    this.defaultFocus = solved ? "close" : "later_0";
    return out;
  }

  letterChildren() {
    const out = [];
    const solved = puzzles.solved("letter");
    const order = puzzles.letterOrder();
    order.forEach((strip, pos) => {
      out.push(kit.button(this.id(`strip_${pos}`), 270, 196 + pos * 74, 740, 60, i18n.t(puzzles.data.letter.strips[strip]), { size: 18, enabled: !solved, accent: this.strip === pos }));
      this.on(`strip_${pos}`, () => {
        if (this.strip < 0) {
          this.strip = pos;
          this.say("");
        } else if (this.strip === pos) {
          this.strip = -1;
          this.say("");
        } else {
          const r = puzzles.swapStrips(this.strip, pos);
          this.strip = -1;
          this.act(r);
        }
      });
    });
    this.defaultFocus = "strip_0";
    return out;
  }

  fuseChildren() {
    const out = [];
    const s = puzzles.state("fuse");
    const solved = puzzles.solved("fuse");
    const fitted = s.fitted || solved;
    out.push(kit.label(this.id("status"), 270, 200, 740, i18n.t("puzzle.fuse.status", { state: i18n.t(fitted ? "puzzle.fuse.stateFitted" : "puzzle.fuse.stateMissing") }), { size: 24, color: fitted ? GOOD : GOLD, height: 46 }));
    out.push(kit.button(this.id("fit"), 270, 250, 240, 52, i18n.t("puzzle.fuse.fit"), { enabled: !fitted }));
    this.on("fit", () => this.act(puzzles.fitFuse()));
    puzzles.breakers().forEach((sid, i) => {
      const at = s.thrown.indexOf(sid);
      const down = solved || at >= 0;
      const name = i18n.t(`puzzle.service.${sid}`);
      out.push(kit.button(this.id(`breaker_${sid}`), 270 + i * 190, 360, 170, 90, down ? `${name} (${(solved ? puzzles.breakerOrder().indexOf(sid) : at) + 1})` : name, { size: 20, accent: down }));
      this.on(`breaker_${sid}`, () => this.act(puzzles.throwBreaker(sid)));
    });
    this.defaultFocus = fitted ? `breaker_${puzzles.breakers()[0]}` : "fit";
    return out;
  }
}
