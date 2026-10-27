// @ts-check
// The story data as the game and the tools read it: every dialogue table, the story registry and the cast, imported once.
// The engine has no glob import for data/dialogue/*.json (ENGINE_FEEDBACK.json), so a new chapter file is added here by hand.
import ch1 from "../data/dialogue/ch1.json";
import ch2 from "../data/dialogue/ch2.json";
import ch3 from "../data/dialogue/ch3.json";
import ch4 from "../data/dialogue/ch4.json";
import ch5 from "../data/dialogue/ch5.json";
import story from "../data/story.json";
import cast from "../data/cast.json";

/** The tables by file path, as the validator names them. */
export const TABLES = Object.freeze({
  "data/dialogue/ch1.json": ch1,
  "data/dialogue/ch2.json": ch2,
  "data/dialogue/ch3.json": ch3,
  "data/dialogue/ch4.json": ch4,
  "data/dialogue/ch5.json": ch5,
});

/** All the conversations of all the tables in one object: { conversations: { id: conversation } }, the shape the runner takes. */
export const DIALOGUE = Object.freeze({
  conversations: Object.freeze(Object.assign({}, ...Object.values(TABLES).map((t) => t.conversations))),
});

export { story, cast };

/** The ids of the interactables of kind "door" in some scenes ({ path: parsed scene }); the story's "open.<id>" flags name them. */
export function doorIds(scenes) {
  const ids = [];
  for (const scene of Object.values(scenes)) {
    for (const e of scene.entities ?? []) {
      if (e?.components?.Script?.props?.kind === "door" && e.id) ids.push(e.id);
    }
  }
  return ids;
}
