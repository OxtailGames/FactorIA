// P7, release checks: the exact pixel size of the icon and the store files (assets.textureSize answers 32x32 for a missing
// file). The icons and the key art are in git, so a missing one fails. The screenshots and capsules are not
// (store/make_store_images.py writes them): they are checked when they are there.
import { test, describe, expect } from "factoria:test";
import { assets } from "factoria";

const IN_GIT = [
  ["assets/icon.png", 1024, 1024],
  ["assets/icon_fg.png", 432, 432],
  ["store/keyart.png", 1920, 1080],
];
const SHOTS = ["01_title", "02_first_harbour", "03_growing_town", "04_busy_town", "05_overlay", "06_goods"];
const GENERATED = SHOTS.map((s) => [`store/screenshots/${s}.png`, 1920, 1080]);
for (const [store, w, h] of [
  ["itch", 630, 500],
  ["steam", 748, 896], ["steam", 920, 430], ["steam", 1438, 810], ["steam", 1280, 720],
  ["steam", 600, 900], ["steam", 462, 174], ["steam", 3840, 1240], ["steam", 1232, 706],
]) GENERATED.push([`store/capsules/${store}/tidewater-market_${w}x${h}.png`, w, h]);

const missing = (t) => t.width === 32 && t.height === 32; // no store image is 32x32

describe("icon and store files", () => {
  for (const [path, w, h] of IN_GIT) {
    test(`${path} is ${w}x${h}`, () => {
      const t = assets.textureSize(path);
      expect(t.width).toBe(w);
      expect(t.height).toBe(h);
    });
  }
  for (const [path, w, h] of GENERATED) {
    test(`${path} is ${w}x${h} when it is there`, () => {
      const t = assets.textureSize(path);
      if (missing(t)) return;
      expect(t.width).toBe(w);
      expect(t.height).toBe(h);
    });
  }
});
