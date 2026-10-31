// @ts-check
// The story data as the game and the tools read it: every dialogue table, the story registry and the cast, imported once.
// A new chapter file in data/dialogue/ is picked up by the glob import: nothing to add here.
import chapters from "../data/dialogue/*.json";
import story from "../data/story.json";
import cast from "../data/cast.json";

/** The tables by file path, as the validator names them. */
export const TABLES = Object.freeze(
  Object.fromEntries(Object.entries(chapters).map(([file, table]) => ["data/dialogue/" + file, table])),
);

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
