// P5: button pictures and labels per pad type (game.gamepad(i).setType), the keyboard fallback, and that every picture exists.
import { test, describe, expect, game, beforeEach } from "factoria:test";
import { assets } from "factoria";
import * as glyphs from "../scripts/game/glyphs.js";

describe("glyphs", () => {
  beforeEach(() => {
    game.gamepad(0).setType("xbox");
  });

  test("an Xbox pad shows Xbox buttons", () => {
    expect(glyphs.glyph("GamepadA")).toEqual({ family: "xbox", label: "A", icon: "assets/glyphs/xbox/a.png" });
    expect(glyphs.glyph("GamepadLeftShoulder").label).toBe("LB");
  });

  test("a PlayStation pad shows Cross, Circle...", () => {
    game.gamepad(0).setType("playstation");
    expect(glyphs.glyph("GamepadA")).toEqual({ family: "playstation", label: "Cross", icon: "assets/glyphs/playstation/cross.png" });
    expect(glyphs.glyph("GamepadB").label).toBe("Circle");
  });

  test("a Switch pad swaps A and B like the console does", () => {
    game.gamepad(0).setType("nintendo");
    const a = glyphs.glyph("GamepadA");
    expect(a.family).toBe("nintendo");
    expect(a.icon).toBe(`assets/glyphs/nintendo/${a.label.toLowerCase()}.png`);
  });

  test("the Steam Deck shows L1/R1 pictures", () => {
    game.gamepad(0).setType("steamdeck");
    const g = glyphs.glyph("GamepadLeftShoulder");
    expect(g.family).toBe("steamdeck");
    expect(g.label).toBe("L1");
    expect(g.icon).toBe("assets/glyphs/steamdeck/l1.png");
  });

  test("a generic pad counts as Xbox", () => {
    game.gamepad(0).setType("generic");
    expect(glyphs.family(0)).toBe("xbox");
  });

  test("prompt: a pad action with the pad as last device shows a glyph; with the keyboard it shows a key", () => {
    const pad = glyphs.prompt("ui_submit", 0, "gamepad");
    expect(pad.device).toBe("gamepad");
    expect(pad.icon).toBe("assets/glyphs/xbox/a.png");
    const key = glyphs.prompt("ui_submit", 0, "keyboard");
    expect(key.device).toBe("keyboard");
    expect(key.icon).toBe(null);
    expect(key.label.length).toBeGreaterThan(0);
  });

  test("every picture of every family exists and is 64x64", () => {
    for (const fam of glyphs.FAMILIES) {
      for (const slug of Object.values(glyphs.SLUGS[fam])) {
        const size = assets.textureSize(`assets/glyphs/${fam}/${slug}.png`);
        expect(size).toEqual({ width: 64, height: 64 });
      }
    }
  });
});
