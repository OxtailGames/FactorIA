// Project command "project.scatter_gems": places N gems on top of the platforms (entities tagged "platform").
import { scatterGems } from "../scripts/scatter_gems.js";

export default {
  name: "scatter_gems",
  summary: "Place N collectible gems on top of the existing platforms, deterministically.",
  description:
    'Example: {"count": 8, "seed": 7}. Gems are spawned at random spots (inset from the edges) above entities tagged "platform", ' +
    'spread across platforms in proportion to their area. Same seed + same platforms = same positions. ' +
    '"clear" removes existing gems first. Returns {placed, gems:[{id, position:[x,y,z], platform}]}.',
  input: {
    type: "object",
    properties: {
      count: { type: "integer", minimum: 1, maximum: 200, default: 8, description: "Number of gems." },
      seed: { type: "integer", default: 1, description: "Layout seed." },
      clear: { type: "boolean", default: false, description: "Destroy existing gems (tag 'gem') first." },
      height: { type: "number", default: 1.0, description: "Gem center height above the platform top (meters)." },
      margin: { type: "number", default: 0.8, description: "Keep gems this far from platform edges (meters)." },
    },
  },
  readOnly: false,
  run(args) {
    return scatterGems(args);
  },
};
