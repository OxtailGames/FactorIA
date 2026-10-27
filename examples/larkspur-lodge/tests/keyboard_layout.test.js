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
