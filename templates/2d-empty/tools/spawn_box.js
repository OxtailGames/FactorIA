// Example project tool. It becomes command "project.spawn_box" and MCP tool "project_spawn_box".
// Copy this file to add your own tools; they hot-reload and are visible to every AI client.
import { world } from "factoria";

export default {
  name: "spawn_box",
  summary: "Spawn a colored square at a position.",
  description: 'Example: {"x": 100, "y": 50, "size": 40}. Returns the new entity id.',
  input: {
    type: "object",
    properties: {
      x: { type: "number", default: 0, description: "World x (pixels, 0 = screen centre)." },
      y: { type: "number", default: 0, description: "World y (pixels, +Y up)." },
      size: { type: "number", default: 32, minimum: 1, description: "Side length in pixels." },
    },
  },
  readOnly: false,
  run({ x, y, size }) {
    const e = world.spawn({
      name: "Box",
      tags: ["box"],
      components: {
        Transform: { position: [x, y, 0] },
        Shape2D: { shape: "rectangle", size: [size, size], color: [0.3, 0.8, 0.5, 1] },
      },
    });
    return { id: e.id };
  },
};
