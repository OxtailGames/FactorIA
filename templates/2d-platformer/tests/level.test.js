import { test, expect } from "factoria:test";
import { fa } from "factoria";

// The ASCII map in levels/level1.json is the source of truth of the level. Importing it into the scene must change
// nothing: if this fails, rebuild the scene (`factoria call scene.import_ascii @levels/level1.json`) or fix the map.
test("scenes/main.scene.json is what levels/level1.json builds", () => {
  const args = JSON.parse(fa.call("fs.read", { path: "levels/level1.json" }).content);
  expect(args.path).toBe("scenes/main.scene.json"); // the map names the scene it builds
  const rebuilt = ".factoria/tmp/level1.rebuilt.scene.json"; // a scratch file: .factoria/tmp/ may be written and deleted
  const imported = fa.call("scene.import_ascii", { ...args, path: rebuilt, from: args.path });
  expect(imported.warnings).toEqual([]);
  const built = fa.call("fs.read", { path: rebuilt }).content;
  fa.call("fs.delete", { path: rebuilt });
  if (built !== fa.call("fs.read", { path: args.path }).content)
    throw new Error(`${args.path} is not what levels/level1.json builds. Rebuild it with \`factoria call scene.import_ascii @levels/level1.json\` (or undo the hand edit of the scene).`);
});

test("scenes and prefabs are in the canonical layout", () => {
  // `factoria call scene.format '{"paths":["prefabs","scenes"]}'` rewrites them; `{"check": true}` only lists the files that still need it.
  expect(fa.call("scene.format", { check: true }).notCanonical).toEqual([]);
});
