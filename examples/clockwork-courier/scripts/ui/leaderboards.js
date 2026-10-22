// @ts-check
// The leaderboards screen (panel "leaderboards" of scenes/main.scene.json): pick a board with the arrows (best time of each
// level, total stars, daily route) and see the player's rank with the players around. It always says what it is doing:
//
//   state "loading"      the store has not answered yet
//   state "signedOut"    nobody is signed in: explains it and offers "Sign in"; the player's own best is shown from the save
//   state "unavailable"  this build has no leaderboards (backend "none")
//   state "empty"        signed in, no score on this board yet
//   state "error"        the store failed (network...): the message and "Try again"
//   state "ready"        rows: rank, name, score; the player's own row marked with ">"
//
// `state` is a field of the behaviour and the text of "board_status" shows it, so tests and players read the same thing.
// Times are stored in milliseconds on the platform (a leaderboard score is a whole number) and shown as m:ss.s.
import { Behaviour, world, ui, input, i18n, platform } from "factoria";
import * as levels from "../levels.js";
import * as progress from "../progress.js";
import * as services from "../services.js";
import * as fmt from "../fmt.js";

/** The boards of the screen: { id, nameKey or level, kind: "time" | "stars" }. */
export const BOARDS = [
  ...levels.LEVELS.map((l) => ({ id: services.timeBoard(l.id), level: l.id, kind: "time" })),
  { id: "daily_route", level: "", kind: "time" },
  { id: "total_stars", level: "", kind: "stars" },
];

/** Formats a score: milliseconds as m:ss.s, stars as a number. */
export function formatScore(kind, score) {
  if (kind !== "time") return `${score}`;
  return fmt.clock(score / 1000);
}

export default class Leaderboards extends Behaviour {
  /** Rows around the player (the player's own row included). */
  count = 5;
  /** Scroll speed of ui_up / ui_down in pixels per second. */
  scrollSpeed = 500;

  onStart() {
    this.setup();
  }

  onEnable() {
    this.setup();
    this.load();
  }

  onDestroy() {
    for (const off of this.offs ?? []) off();
  }

  setup() {
    if (this.ready) return;
    this.ready = true;
    this.index = 0;
    this.token = 0;
    /** One of the states in the file header. */
    this.state = "loading";
    /** The rows shown: [{ rank, name, score, isPlayer }]. */
    this.entries = [];
    this.offs = [
      ui.on("click", "board_prev", () => this.step(-1)),
      ui.on("click", "board_next", () => this.step(1)),
      ui.on("click", "board_signin", () => this.signIn()),
      ui.on("click", "board_retry", () => this.load()),
      platform.on("player", () => this.entity.active && this.load()),
      i18n.on("change", () => this.entity.active && this.show(this.state)), // name, status and rows are written by script
    ];
  }

  onUpdate(dt) {
    if (!this.entity.active) return;
    const list = world.find("board_list");
    if (list) list.get("ScrollList").scroll += input.axis("ui_up", "ui_down") * this.scrollSpeed * dt;
  }

  get board() {
    return BOARDS[this.index];
  }

  step(delta) {
    this.index = (this.index + delta + BOARDS.length) % BOARDS.length;
    this.load();
  }

  async signIn() {
    try {
      await platform.signIn();
    } catch (e) {
      /* stays signed out: load() says so */
    }
    this.load();
  }

  /** The text of the board's name. */
  boardName() {
    const b = this.board;
    if (b.level) return i18n.t("board.time", { level: i18n.t(levels.byId(b.level)?.nameKey ?? "") });
    return i18n.t(b.id === "daily_route" ? "board.daily" : "board.stars");
  }

  /** The player's own best from the local save (shown while signed out), as text, or "". */
  localBest() {
    const b = this.board;
    if (b.kind === "stars") return i18n.t("board.yourBest", { score: progress.totalStars() });
    const r = b.level ? progress.resultFor(b.level) : null;
    return r ? i18n.t("board.yourBest", { score: formatScore("time", Math.round(r.time * 1000)) }) : "";
  }

  /** Loads the board of the current index and sets the state. A late answer of an old board is ignored. */
  async load() {
    const token = ++this.token;
    this.entries = [];
    this.error = "";
    if (!platform.has("leaderboards")) return this.show("unavailable");
    if (!platform.player.signedIn) return this.show("signedOut");
    this.show("loading");
    try {
      const rows = await platform.leaderboards.entries(this.board.id, { range: "around", count: this.count });
      if (token !== this.token) return;
      this.entries = rows.map((e) => ({ rank: e.rank, name: e.name, score: e.score, isPlayer: e.isPlayer }));
      this.show(this.entries.length ? "ready" : "empty");
    } catch (e) {
      if (token !== this.token) return;
      this.error = e?.code ?? "error";
      // The store forgot who we are (a token that ran out): say so as signed out, not as a failure.
      this.show(e?.code === "notSignedIn" ? "signedOut" : "error");
    }
  }

  /** Sets the state and redraws. */
  show(state) {
    this.state = state;
    const name = world.find("board_name");
    if (name) name.get("Text").text = this.boardName();
    let message = "";
    if (state === "loading") message = i18n.t("board.loading");
    else if (state === "signedOut") message = i18n.t("board.signedOut");
    else if (state === "unavailable") message = i18n.t("board.unavailable");
    else if (state === "empty") message = i18n.t("board.empty");
    else if (state === "error") message = i18n.t("board.error", { code: this.error });
    else {
      const me = this.entries.find((e) => e.isPlayer);
      message = me ? i18n.t("board.rank", { rank: me.rank }) : i18n.t("board.noRank");
    }
    const status = world.find("board_status");
    if (status) status.get("Text").text = message;
    const sign = world.find("board_signin");
    if (sign) sign.active = state === "signedOut";
    const retry = world.find("board_retry");
    if (retry) retry.active = state === "error";
    this.renderRows();
  }

  renderRows() {
    const list = world.find("board_list");
    if (!list) return;
    for (const child of [...list.children]) child.destroy();
    const add = (text, color = [1, 1, 1, 1]) =>
      world.spawn({ components: { Text: { text, fontSize: 24, space: "screen", maxWidth: 560, layer: 302, color } } }, { parent: list });
    if (this.state === "ready") {
      for (const e of this.entries) {
        add(`${e.isPlayer ? ">" : " "} #${e.rank}   ${e.name}   ${formatScore(this.board.kind, e.score)}`, e.isPlayer ? [1, 0.88, 0.4, 1] : [0.85, 0.88, 0.95, 1]);
      }
    } else if (this.state === "signedOut" || this.state === "empty") {
      const mine = this.localBest();
      if (mine) add(mine, [0.85, 0.88, 0.95, 1]);
    }
  }
}
