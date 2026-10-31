// The on-screen keyboard (pad players naming a save) follows the language: Hebrew letters for he, Latin for the rest.
import { test, expect } from "factoria:test";
import { keysFor } from "../scripts/ui/keyboard.js";

test("the keys follow the language", () => {
  const he = keysFor("he");
  expect(he).toContain("א");
  expect(he).toContain("ת");
  expect(he).not.toContain("a");
  expect(he).toContain("7");
  expect(keysFor("de")).toContain("ß");
  expect(keysFor("es")).toContain("ñ");
  expect(keysFor("en")).toContain("q");
});

test("Korean: the keys are jamo and the input method makes syllables of them (FB-0905)", async () => {
  const { hangulIme } = await import("../scripts/ui/keyboard.js");
  const ko = keysFor("ko");
  expect(ko).toContain("ㅎ");
  expect(ko).toContain("ㅏ");
  expect(ko).not.toContain("a");
  expect(["ㅎ", "ㅏ", "ㄴ", "ㄱ", "ㅡ", "ㄹ"].reduce((text, ch) => hangulIme.compose(text, ch), "")).toBe("한글");
  expect(hangulIme.decompose("한글")).toBe("한그");
});
