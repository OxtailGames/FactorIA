import { test, expect, game } from "factoria:test";
import { audio, i18n, storage, world } from "factoria";
import { say } from "../scripts/dialogue.js";

// game.captions() lists what is on the caption list, oldest first; the "captions" entity draws the newest maxLines of them.
const shown = () => game.captions().map((c) => [c.speaker, c.text]);

test("a caption lives as long as its sound, in the language of the moment", () => {
  i18n.setLanguage("en");
  game.load("scenes/level.scene.json");
  game.step(2);
  say("captions.welcome", { sound: "assets/sfx/hello.wav", speaker: "captions.guide" }); // a 1 s sound
  game.step(10);
  expect(shown()).toEqual([["Guide", "Welcome, traveller."]]);
  expect(game.captions()[0].key).toBe("captions.welcome");
  expect(game.captions()[0].source).toBe("audio:assets/sfx/hello.wav");
  expect(world.find("captions").get("Captions").lines.length).toBe(1);

  i18n.setLanguage("es"); // while it is on screen: the line changes, the speaker was written when it started
  expect(shown()).toEqual([["Guide", "Bienvenido, viajero."]]);
  game.step(70); // the sound has ended
  expect(shown()).toEqual([]);
  expect(world.find("captions").get("Captions").lines.length).toBe(0);
});

test("a line without a sound runs for its seconds; clearCaptions and stop remove lines at once", () => {
  i18n.setLanguage("en"); // the language outlives scene loads and tests
  game.load("scenes/level.scene.json");
  game.step(2);
  say("captions.hint", { seconds: 2 });
  game.step(60);
  expect(shown()).toEqual([["", "Watch the edge!"]]);
  game.step(70);
  expect(shown()).toEqual([]);

  const voice = say("captions.welcome", { sound: "assets/sfx/hello.wav" });
  say("captions.hint", { seconds: 5 });
  expect(game.captions().length).toBe(2);
  audio.stop(voice); // the caption of a sound goes with it
  expect(shown()).toEqual([["", "Watch the edge!"]]);
  game.step(1);
  expect(game.captions().length).toBe(1);
});

test("Arabic: the same lines in a right-to-left language", () => {
  game.load("scenes/level.scene.json");
  i18n.setLanguage("ar");
  game.step(2);
  say("captions.welcome", { sound: "assets/sfx/hello.wav", speaker: "captions.guide" });
  game.step(3);
  expect(shown()).toEqual([["المرشدة", "مرحبًا أيها المسافر."]]);
  expect(world.find("captions").get("Captions").lines[0].text).toBe("مرحبًا أيها المسافر."); // drawn right to left by the engine
});

test("the Subtitles option hides the captions (the entity is inactive) but they are still tracked", () => {
  i18n.setLanguage("en");
  game.load("scenes/menu.scene.json");
  const pad = game.gamepad(0);
  game.step(2);
  expect(world.find("captions").active).toBe(true);
  pad.tap("DpadDown"); // Options
  pad.tap("A");
  pad.tap("DpadRight"); // the Audio tab
  pad.tap("A");
  for (let i = 0; i < 6; i++) pad.tap("DpadDown"); // Master, Music, Effects, Interface, Read menus aloud, Subtitles
  pad.tap("A");
  expect(storage.get("settings").subtitles).toBe(false);
  expect(world.find("captions").active).toBe(false);
  say("captions.hint", { seconds: 2 });
  expect(shown()).toEqual([["", "Watch the edge!"]]);

  pad.tap("A"); // on again
  expect(storage.get("settings").subtitles).toBe(true);
  expect(world.find("captions").active).toBe(true);
});

test("wrong calls teach", () => {
  expect(() => audio.play("assets/sfx/hello.wav", { loop: true, caption: "x" })).toThrow("captionSeconds");
  expect(() => audio.play("assets/sfx/hello.wav", { speaker: "Mara" })).toThrow("no caption");
  expect(() => audio.play("assets/sfx/hello.wav", { caption: 3 })).toThrow("must be a string");
});
