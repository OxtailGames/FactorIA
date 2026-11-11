// The assets of this game are all made with engine commands: the recipe of every one is in assets.json (provenance.recipe),
// and none comes from an asset provider or from an imported file. These tests fail if one slips in, or if a baked output
// is older than the document it was baked from (change a document, then run `assets.regenerate {"stale":true}`).
import { test, expect } from "factoria:test";
import { fa } from "factoria";

/** The commands that make an asset without a provider and without a source file (M51-M59, plus the offline loop and icon makers). */
const OFFLINE_MAKERS = /^(image\.|sfx\.|audio\.|music\.|model\.|rig\.|skin3d\.|anim3d\.|assets\.generate_loop$|assets\.draw_icon$)/;

const assetsJson = () => JSON.parse(fa.call("fs.read", { path: "assets.json" }).content).assets;
/** Every record of assets.json as { path, provenance }. */
const records = () => Object.entries(assetsJson()).map(([path, a]) => ({ path, provenance: a.provenance || {} }));

test("every asset has a recipe of an engine command, none is imported or made by a provider", () => {
  const all = records();
  expect(all.length).toBeGreaterThan(60);
  for (const a of all) {
    const p = a.provenance;
    expect(p.ai, `${a.path} is marked as made with AI`).toBe(false);
    expect(p.origin, `${a.path} is not original`).toBe("original");
    const command = p.recipe && p.recipe.command;
    // A record that says it has no recipe (a clip edited by hand) must not carry one: regenerate would overwrite the keys.
    if (/no recipe/i.test(String(p.notes))) expect(p.recipe, `${a.path} says it has no recipe but carries one`).toBeUndefined();
    // A clip keyed by hand (anim3d.create + anim3d.set_keys) has a record but no recipe: regenerating it would drop the keys.
    if (p.kind === "anim3d" && !command) {
      expect(String(p.provider), `${a.path} names no engine command as its provider`).toMatch(/^factoria anim3d\./);
      continue;
    }
    expect(command, `${a.path} has no recipe: make it with an engine command`).toBeTruthy();
    expect(OFFLINE_MAKERS.test(command), `${a.path} was made by '${command}', not by an offline maker`).toBe(true);
  }
});

test("every 3D clip under anim/ has a record, made by an anim3d command", () => {
  const known = assetsJson();
  const clips = fa.call("fs.list", { path: "anim", recursive: true }).entries.filter((e) => e.type === "file" && /\.anim\.json$/.test(e.path));
  expect(clips.length).toBeGreaterThan(10);
  const unknown = clips.map((e) => e.path).filter((p) => !(p in known));
  expect(unknown, `clips with no record in assets.json: ${unknown.join(", ")}`).toEqual([]);
});

test("every kind of asset the game uses is made by its own maker", () => {
  const made = new Set(records().filter((a) => a.provenance.recipe).map((a) => a.provenance.recipe.command.split(".")[0]));
  for (const family of ["image", "sfx", "music", "model", "rig"]) expect(made.has(family), `nothing was made with ${family}.*`).toBe(true);
});

test("every baked output is fresh: assets.regenerate {stale: true} has nothing to run", () => {
  const plan = fa.call("assets.regenerate", { stale: true, dryRun: true });
  const stale = plan.wouldRun.map((r) => (r.outputs || []).join(", ") || r.command);
  expect(stale, `stale outputs: ${stale.join("; ")} (run assets.regenerate {"stale":true})`).toEqual([]);
});

test("no picture, sound or model sits under assets/ without a record", () => {
  const known = assetsJson();
  const files = fa.call("fs.list", { path: "assets", recursive: true }).entries.filter((e) => e.type === "file" && /\.(png|wav|ogg|glb|gltf|mp3)$/.test(e.path));
  expect(files.length).toBeGreaterThan(60);
  const unknown = files.map((e) => e.path).filter((p) => !(p in known));
  expect(unknown, `files with no recipe in assets.json: ${unknown.join(", ")}`).toEqual([]);
});
