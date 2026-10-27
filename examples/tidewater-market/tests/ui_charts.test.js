// The charts panel draws its two charts with the engine's Chart widget; the sample under the pointer comes from ui.on("chartHover").
import { test, expect, game } from "factoria:test";
import { ui } from "factoria";
import { townScene } from "./ui_helper.js";
import { runDays } from "./town_helper.js";

test("charts: the money chart is a Chart widget, hovering a sample reports its index and the tooltip names the day", () => {
  const { hud } = townScene();
  runDays(hud.state, 6);
  game.click("btn_charts");
  game.step(3);
  expect(game.find("charts_panel").active).toBe(true);
  const area = hud.madeChart.area;
  expect(area.has("Chart")).toBe(true);
  const [rx, ry, rw, rh] = ui.rectOf(area);
  expect(rw).toBeGreaterThan(0);
  const seen = []; // the newest samples are drawn at the right edge; the left of the chart is empty until 40 days are recorded
  const off = ui.on("chartHover", (e) => seen.push({ id: e.id, index: e.index }));
  game.mouseMove({ x: rx + rw - 12, y: ry + rh * 0.5 });
  game.step(2);
  expect(seen.length).toBeGreaterThan(0);
  const hit = seen[seen.length - 1];
  expect(hit.index).toBe(hud.madeChart.points.length - 1); // the newest day
  expect(area.get("Chart").hoverIndex).toBe(hit.index);
  game.mouseMove({ x: 5, y: 5 });
  game.step(2);
  expect(seen[seen.length - 1].index).toBe(-1);
  if (typeof off === "function") off();
});
