// The assets of this game are all made with engine commands: the recipe of every one is in assets.json (provenance.recipe),
// and none comes from an asset provider or from an imported file. These tests fail if one slips in, or if a baked output
// is older than the document it was baked from (change a document, then run `assets.regenerate {"stale":true}`).
import { test, expect } from "factoria:test";
import { fa } from "factoria";

/** The commands that make an asset without a provider and without a source file (M51-M59, plus the offline loop and icon makers). */
const OFFLINE_MAKERS = /^(image\.|sfx\.|audio\.|music\.|model\.|rig\.|skin3d\.|anim3d\.|assets\.generate_loop$|assets\.draw_icon$)/;

/** assets.provenance: every record of assets.json as { path, provenance }, and the art, sound and model files with no record. */
const provenance = () => fa.call("assets.provenance", {});
const records = () => provenance().assets;

test("every asset has a recipe of an engine command, none is imported or made by a provider", () => {
  const all = records();
  expect(all.length).toBeGreaterThan(60);
  for (const a of all) {
    const p = a.provenance;
    expect(p.ai, `${a.path} is marked as made with AI`).toBe(false);
    expect(p.origin, `${a.path} is not original`).toBe("original");
    const command = p.recipe && p.recipe.command;
    expect(command, `${a.path} has no recipe: make it with an engine command`).toBeTruthy();
    expect(OFFLINE_MAKERS.test(command), `${a.path} was made by '${command}', not by an offline maker`).toBe(true);
  }
});

test("every kind of asset the game uses is made by its own maker", () => {
  const made = new Set(records().map((a) => a.provenance.recipe.command.split(".")[0]));
  for (const family of ["image", "sfx", "music", "model", "rig"]) expect(made.has(family), `nothing was made with ${family}.*`).toBe(true);
});

test("every baked output is fresh: assets.regenerate {stale: true} has nothing to run", () => {
  const plan = fa.call("assets.regenerate", { stale: true, dryRun: true });
  const stale = plan.wouldRun.map((r) => (r.outputs || []).join(", ") || r.command);
  expect(stale, `stale outputs: ${stale.join("; ")} (run assets.regenerate {"stale":true})`).toEqual([]);
});

test("no picture, sound or model sits under assets/ without a record", () => {
  const { assets, withoutProvenance } = provenance();
  expect(assets.length).toBeGreaterThan(60);
  expect(withoutProvenance, `files with no recipe in assets.json: ${withoutProvenance.join(", ")}`).toEqual([]);
});
