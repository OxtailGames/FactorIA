// Example project tool: "project.spawn_cube" / MCP tool "project_spawn_cube".
import { world } from "factoria";

export default {
  name: "spawn_cube",
  summary: "Spawn a colored cube at a position.",
  description: 'Example: {"x": 1, "y": 0.5, "z": -2, "size": 1}. Returns the new entity id. Units are meters, +Y is up.',
  input: {
    type: "object",
    properties: {
      x: { type: "number", default: 0, description: "World x (meters)." },
      y: { type: "number", default: 0.5, description: "World y (meters, up)." },
      z: { type: "number", default: 0, description: "World z (meters; the default camera looks toward -Z)." },
      size: { type: "number", default: 1, minimum: 0.01, description: "Edge length in meters." },
    },
  },
  readOnly: false,
  run({ x, y, z, size }) {
    const e = world.spawn({
      name: "Cube",
      tags: ["cube"],
      components: {
        Transform: { position: [x, y, z], scale: [size, size, size] },
        MeshRenderer: { mesh: "cube", color: [0.8, 0.8, 0.9, 1] },
      },
    });
    return { id: e.id };
  },
};
