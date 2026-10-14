// Example project tool: "project.spawn_coin" / MCP tool "project_spawn_coin".
// Lets an AI place collectibles without hand-editing the scene. It spawns prefabs/coin.prefab.json into the RUNNING
// game. To put a coin in the level for good, add an `o` to the map in levels/level1.json and rebuild it.
import { world } from "factoria";

export default {
  name: "spawn_coin",
  summary: "Spawn a collectible coin (prefabs/coin.prefab.json) at a world position.",
  description: 'Example: {"x": 300, "y": 150}. Returns the new entity id. Coins are tagged "coin" and are collected when the player touches them. This changes the running game only, not the scene file.',
  input: {
    type: "object",
    required: ["x", "y"],
    properties: {
      x: { type: "number", description: "World x in pixels (the level starts at x = 0)." },
      y: { type: "number", description: "World y in pixels (+Y up; the ground top is at y = 128)." },
    },
  },
  readOnly: false,
  run({ x, y }) {
    const e = world.spawnPrefab("prefabs/coin.prefab.json", { position: [x, y] });
    return { id: e.id };
  },
};
