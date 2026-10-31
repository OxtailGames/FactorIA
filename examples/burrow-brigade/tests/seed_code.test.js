// Seed codes (a mine as eight readable characters) and the clipboard they travel through.
import { test, describe, expect, game } from "factoria:test";
import { ui, clipboard as engine } from "factoria";
import * as codes from "../scripts/game/seed_code.js";
import * as clipboard from "../scripts/game/clipboard.js";
import * as players from "../scripts/game/players.js";
import { run, startRun } from "../scripts/game/run_state.js";
import { live } from "../scripts/game/mine_map.js";
import { generate } from "../scripts/game/generator.js";
import { cleanBeforeEach } from "./helpers/world.js";
import { clearSlots, arrive, SHIFT, CAMP, TITLE, enterRun } from "./helpers/camp.js";

const text = (id) => game.find(id).get("Text").text;
/** Types into the code field of the title. */
function typeCode(value) {
  game.find("code_field").set("TextField", { text: value });
  game.step(1);
}
/** The title with the code panel open. */
function openCodePanel() {
  players.clear();
  game.load(TITLE);
  game.step(3);
  game.click("code_button");
  game.step(2);
}

describe("encode and decode", () => {
  cleanBeforeEach();

  test("a code is two groups of four characters and reads back to the same mine", () => {
    const code = codes.encode({ seed: 123456789, stratum: 1, floor: 2 });
    expect(code).toMatch(/^[0-9A-HJKMNP-TV-Z]{4}-[0-9A-HJKMNP-TV-Z]{4}$/);
    expect(codes.decode(code)).toEqual({ ok: true, seed: 123456789, stratum: 1, floor: 2 });
  });

  test("round trip over every floor and a spread of seeds, edges included", () => {
    const seeds = [0, 1, 31, 32, 1234, 99999, 0x7fffffff, 0x40000000, 987654321];
    for (let stratum = 0; stratum < 3; stratum++) {
      for (let floor = 1; floor <= 3; floor++) {
        for (const seed of seeds) {
          const back = codes.decode(codes.encode({ seed, stratum, floor }));
          expect(back).toEqual({ ok: true, seed, stratum, floor });
        }
      }
    }
  });

  test("case, dashes, spaces and look-alike letters do not matter", () => {
    const code = codes.encode({ seed: 4242, stratum: 0, floor: 3 });
    const sloppy = code.toLowerCase().replace("-", " ");
    expect(codes.decode(sloppy)).toEqual(codes.decode(code));
    expect(codes.normalize("o0il-uU")).toBe("0011VV");
    expect(codes.decode(`  ${code.replace("-", "")}  `).ok).toBe(true);
  });

  test("a single mistyped character is always caught by the check character", () => {
    const code = codes.encode({ seed: 777777, stratum: 2, floor: 1 }).replace("-", "");
    for (let i = 0; i < code.length; i++) {
      for (const other of codes.ALPHABET) {
        if (other === code[i]) continue;
        const wrong = code.slice(0, i) + other + code.slice(i + 1);
        expect(codes.decode(wrong).ok).toBe(false);
      }
    }
  });

  test("an invalid code gets an error that says what is wrong and what to do", () => {
    const empty = codes.decode("   ");
    expect(empty).toMatchObject({ ok: false });
    if (!empty.ok) {
      expect(empty.message).toContain("empty");
      expect(empty.hint).toContain(codes.EXAMPLE);
    }
    const chars = codes.decode("12?4-5678");
    if (chars.ok) throw new Error("must fail");
    expect(chars.message).toContain("'?'");
    const short = codes.decode("1234-567");
    if (short.ok) throw new Error("must fail");
    expect(short.message).toContain("7 characters");
    expect(short.hint).toContain("missing");
    const long = codes.decode("1234-56789");
    if (long.ok) throw new Error("must fail");
    expect(long.hint).toContain("extra");
    const good = codes.encode({ seed: 5, stratum: 0, floor: 1 });
    const flipped = good.slice(0, 7) + (good[7] === "0" ? "1" : "0") + good.slice(8);
    const check = codes.decode(flipped);
    if (check.ok) throw new Error("must fail");
    expect(check.message).toContain("check character");
    expect(check.hint).toContain("mistyped");
  });

  test("a code for a floor that does not exist is refused, and encode refuses what it cannot write", () => {
    // floor index 9 (the tenth floor) with a valid check character
    const values = [];
    let rest = 9 * 0x80000000 + 5;
    for (let i = 0; i < 7; i++) {
      values.unshift(rest % 32);
      rest = Math.floor(rest / 32);
    }
    const weights = [1, 3, 5, 7, 9, 11, 13];
    values.push(values.reduce((n, v, i) => n + v * weights[i], 0) % 32);
    const made = values.map((v) => codes.ALPHABET[v]).join("");
    const r = codes.decode(made);
    if (r.ok) throw new Error("must fail");
    expect(r.message).toContain("not a floor of this mine");
    expect(() => codes.encode({ seed: -1, stratum: 0, floor: 1 })).toThrow("seed");
    expect(() => codes.encode({ seed: 1, stratum: 3, floor: 1 })).toThrow("not a floor");
  });
});

describe("the clipboard", () => {
  cleanBeforeEach();

  test("copy writes the system clipboard (the engine's) and paste reads it back, also what another program put there", async () => {
    clipboard.reset();
    expect(clipboard.system()).toBe(true);
    expect(await clipboard.paste()).toBe("");
    expect(clipboard.copy("3K7Q-2XF9")).toEqual({ ok: true, system: true });
    expect(await clipboard.paste()).toBe("3K7Q-2XF9");
    expect(await engine.read()).toBe("3K7Q-2XF9");
    engine.write("from another program");
    expect(await clipboard.paste()).toBe("from another program");
  });

  test("on a phone (no clipboard for scripts) copy keeps the text for the session and says so", async () => {
    clipboard.reset();
    engine.write("from another program");
    clipboard.useSystem(false);
    expect(clipboard.system()).toBe(false);
    expect(clipboard.copy("ABCD-1234")).toEqual({ ok: true, system: false });
    expect(await clipboard.paste()).toBe("ABCD-1234");
    expect(await engine.read()).toBe("from another program"); // the system clipboard was not touched
    clipboard.reset();
  });

  test("Copy code in the camp copies the code on the screen and the message is honest about where it went", () => {
    clipboard.reset();
    players.clear();
    startRun({ seed: 31337, stratum: 1, floor: 3 });
    game.load(CAMP);
    game.step(3);
    const shown = text("camp_seed").replace("Mine code: ", "");
    game.click("copy_code");
    game.step(1);
    expect(text("camp_message")).toBe(`Code ${shown} copied to the clipboard.`);
    clipboard.useSystem(false); // a phone
    game.click("copy_code");
    game.step(1);
    expect(text("camp_message")).toBe(`Code ${shown} kept for this session only: this build has no system clipboard, so write it down.`);
    clipboard.reset();
  });
});

describe("seed codes at the title and on the results", () => {
  cleanBeforeEach();

  test("typing a code and pressing Play this mine plays that mine, in the 'normal' mode with no slot", () => {
    clearSlots();
    clipboard.reset();
    const code = codes.encode({ seed: 424242, stratum: 1, floor: 2 });
    openCodePanel();
    typeCode(code.toLowerCase());
    game.click("play_code");
    enterRun(SHIFT);
    expect(run).toMatchObject({ seed: 424242, stratum: 1, floor: 2, mode: "normal", dailyKey: null, slot: null, shiftNumber: 1 });
    expect(live.mine.hash).toBe(generate(424242, 1, 2).hash);
  });

  test("typing with the keyboard works: the field has the focus when the panel opens, and Enter plays", () => {
    openCodePanel();
    expect(ui.focused.id).toBe("code_field");
    expect(text("code_message")).toBe("Type the code, then press Enter."); // text_entry.hint (P5): how to type on this device
    game.typeText(codes.encode({ seed: 11, stratum: 0, floor: 1 }));
    game.step(2);
    game.keyDown("Enter");
    game.step(2);
    game.keyUp("Enter");
    enterRun(SHIFT);
    expect(run.seed).toBe(11);
  });

  test("an invalid code shows the error on the panel and starts nothing", () => {
    openCodePanel();
    typeCode("ABCD-EFG7");
    game.click("play_code");
    game.step(1);
    expect(text("code_message")).toContain("not a valid seed code");
    expect(text("code_message")).toContain("mistyped");
    typeCode("");
    game.click("play_code");
    game.step(1);
    expect(text("code_message")).toContain("empty");
    expect(game.find("code_panel").active).toBe(true);
  });

  test("Paste fills the field from the clipboard; with nothing copied it says so", () => {
    clipboard.reset();
    openCodePanel();
    game.click("paste_code");
    game.step(1);
    expect(text("code_message")).toContain("Nothing to paste");
    clipboard.copy("3K7Q-2XF9");
    game.click("paste_code");
    game.step(1);
    expect(game.find("code_field").get("TextField").text).toBe("3K7Q-2XF9");
  });

  test("the code of the results is the mine just played: copied, pasted at the title and played, it is the same mine", () => {
    clearSlots();
    clipboard.reset();
    players.clear();
    startRun({ seed: 2024, stratum: 0, floor: 1 });
    game.load(SHIFT);
    game.step(3);
    const played = live.mine.hash;
    const exit = live.mine.exit;
    const at = live.map.tileCenter(exit.tx, exit.ty);
    game.world.findByTag("miner")[0].position = [at.x, at.y, 0];
    game.step(130);
    const code = text("results_seed").replace("Mine code: ", "");
    expect(codes.decode(code)).toEqual({ ok: true, seed: 2024, stratum: 0, floor: 1 });
    game.click("copy_code");
    game.step(1);
    expect(text("results_message")).toContain(code);
    openCodePanel();
    game.click("paste_code");
    game.step(1);
    game.click("play_code");
    enterRun(SHIFT);
    expect(live.mine.hash).toBe(played);
  });
});
