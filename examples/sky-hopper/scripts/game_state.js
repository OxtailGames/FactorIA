// Shared game state. Module-level, so it survives scene loads (scenes drop all entities).
export const state = { lives: 3, coins: 0, level: 1, totalCoins: 0 };
export function resetState() {
  state.lives = 3;
  state.coins = 0;
  state.level = 1;
}
