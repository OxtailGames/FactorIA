// Example project tool: "project.spawn_coin" / MCP tool "project_spawn_coin".
// Lets an AI place collectibles without hand-editing the scene.
import { world } from "factoria";

export default {
  name: "spawn_coin",
  summary: "Spawn a collectible coin at a world position.",
  description: 'Example: {"x": 300, "y": -150}. Returns the new entity id. Coins are tagged "coin" and trigger collection when the player touches them.',
  input: {
    type: "object",
    required: ["x", "y"],
    properties: {
      x: { type: "number", description: "World x in pixels (0 = screen centre)." },
      y: { type: "number", description: "World y in pixels (+Y up)." },
    },
  },
  readOnly: false,
  run({ x, y }) {
    const e = world.spawn({
      name: "Coin",
      tags: ["coin"],
      components: {
        Transform: { position: [x, y, 0] },
        Shape2D: { shape: "circle", size: [24, 24], color: [1, 0.85, 0.2, 1], layer: 1 },
        RigidBody2D: { type: "static" },
        Collider2D: { shape: "circle", radius: 12, isTrigger: true },
      },
    });
    return { id: e.id };
  },
};
