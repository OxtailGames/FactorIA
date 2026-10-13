// Example project tool: "project.spawn_cube" / MCP tool "project_spawn_cube".
import { world, rng } from "factoria";

export default {
  name: "spawn_cube",
  summary: "Spawn a cube at a position, optionally with a repeatable random colour.",
  description: 'Example: {"x": 1, "y": 0.5, "z": -2, "size": 1, "seed": 7}. Returns the new entity id. Units are meters, +Y is up. With a seed the colour is random but the same for the same seed; without one the cube is light grey.',
  input: {
    type: "object",
    properties: {
      x: { type: "number", default: 0, description: "World x (meters)." },
      y: { type: "number", default: 0.5, description: "World y (meters, up)." },
      z: { type: "number", default: 0, description: "World z (meters; the default camera looks toward -Z)." },
      size: { type: "number", default: 1, minimum: 0.01, description: "Edge length in meters." },
      seed: { type: "integer", description: "Optional. Picks a random colour that is the same every time for this seed." },
    },
  },
  readOnly: false,
  run({ x, y, z, size, seed }) {
    let color = [0.8, 0.8, 0.9, 1];
    if (seed !== undefined) {
      // Anything that must repeat from a seed draws from its own rng.create(seed): the game's one `rng` is shared with
      // the running game, and Math.random is never allowed.
      const r = rng.create(seed);
      color = [r.range(0.2, 1), r.range(0.2, 1), r.range(0.2, 1), 1];
    }
    const e = world.spawn({
      name: "Cube",
      tags: ["cube"],
      components: {
        Transform: { position: [x, y, z], scale: [size, size, size] },
        MeshRenderer: { mesh: "cube", color },
      },
    });
    return { id: e.id };
  },
};
