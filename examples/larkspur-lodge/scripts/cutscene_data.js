// @ts-check
// The cut-scene data as the game and the tools read it, imported once. The engine has no glob import for data/cutscenes/*.json
// (FB-0005 in ENGINE_FEEDBACK.json), so a new cut-scene file is added here by hand.
import intro from "../data/cutscenes/intro.cutscene.json";
import chapter2 from "../data/cutscenes/chapter_2.cutscene.json";
import chapter3 from "../data/cutscenes/chapter_3.cutscene.json";
import chapter4 from "../data/cutscenes/chapter_4.cutscene.json";
import chapter5 from "../data/cutscenes/chapter_5.cutscene.json";
import aditDescent from "../data/cutscenes/adit_descent.cutscene.json";
import aditRescue from "../data/cutscenes/adit_rescue.cutscene.json";
import endingDawn from "../data/cutscenes/ending_dawn.cutscene.json";
import endingQuiet from "../data/cutscenes/ending_quiet.cutscene.json";
import endingLong from "../data/cutscenes/ending_long.cutscene.json";
import rooms from "../data/cutscenes/rooms.json";
import voice from "../data/cutscenes/voice.json";
import voiceScript from "../data/cutscenes/voice_script.json";

/** The cut-scene files by path, as the validator names them. */
export const FILES = Object.freeze({
  "data/cutscenes/intro.cutscene.json": intro,
  "data/cutscenes/chapter_2.cutscene.json": chapter2,
  "data/cutscenes/chapter_3.cutscene.json": chapter3,
  "data/cutscenes/chapter_4.cutscene.json": chapter4,
  "data/cutscenes/chapter_5.cutscene.json": chapter5,
  "data/cutscenes/adit_descent.cutscene.json": aditDescent,
  "data/cutscenes/adit_rescue.cutscene.json": aditRescue,
  "data/cutscenes/ending_dawn.cutscene.json": endingDawn,
  "data/cutscenes/ending_quiet.cutscene.json": endingQuiet,
  "data/cutscenes/ending_long.cutscene.json": endingLong,
});

/** The cut-scenes by id. */
export const CUTSCENES = Object.freeze(Object.fromEntries(Object.values(FILES).map((c) => [c.id, c])));

export { rooms, voice, voiceScript };
