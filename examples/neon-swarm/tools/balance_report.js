// project.balance_report: balancing metrics for the current Neon Swarm game state.
import { world, scene, storage } from "factoria";

const COSTS = { chaser: 1, shooter: 2, splitter: 3 };

export default {
  name: "balance_report",
  summary: "Balancing metrics of the running game: wave, enemies, player health, difficulty.",
  description: "Call after stepping the game (e.g. --frames-before 600). Returns wave number, enemy counts by kind, total enemy hp/threat, player health, score/combo, difficulty multiplier, next-wave budget and warnings.",
  input: { type: "object", properties: {} },
  readOnly: true,
  run() {
    const mgrEntity = world.find("manager");
    const playerEntity = world.find("player");
    if (!mgrEntity || !mgrEntity.behaviour) {
      return {
        ok: true,
        inGame: false,
        scene: scene.current,
        highScore: storage.get("highScore", 0),
        hint: "Not in the game scene, so there are no live metrics. Run with: factoria call project.balance_report '{}' --scene scenes/game.scene.json --frames-before 600 (or press 'action' on the title screen).",
      };
    }
    const m = mgrEntity.behaviour;
    const p = playerEntity && playerEntity.behaviour;
    const enemies = world.findByTag("enemy");
    const byKind = {};
    let totalHp = 0, threat = 0, nearest = null;
    for (const e of enemies) {
      const b = e.behaviour;
      if (!b) continue;
      byKind[b.kind] = (byKind[b.kind] || 0) + 1;
      totalHp += b.hp;
      threat += b.speed * (b.kind === "shooter" ? 1.5 : 1);
      if (playerEntity) {
        const dx = e.position.x - playerEntity.position.x, dy = e.position.y - playerEntity.position.y;
        const d = Math.sqrt(dx * dx + dy * dy);
        if (nearest === null || d < nearest) nearest = d;
      }
    }
    const nextWave = m.wave + 1;
    const nextBudget = m.baseBudget + m.budgetPerWave * (nextWave - 1);
    const playerDps = p ? (1 / p.fireDelay) : 0;
    const bullets = world.findByTag("bullet").length;
    const ebullets = world.findByTag("ebullet").length;
    const report = {
      ok: true,
      inGame: true,
      scene: scene.current,
      wave: m.wave,
      state: m.state,
      score: m.score,
      highScore: m.highScore,
      combo: m.combo,
      multiplier: m.multiplier,
      kills: m.kills,
      spawnedEnemies: m.spawned,
      pendingSpawns: m.pending.length,
      enemiesAlive: enemies.length,
      enemiesByKind: byKind,
      totalEnemyHp: totalHp,
      threatScore: Math.round(threat),
      nearestEnemyDistance: nearest === null ? null : Math.round(nearest),
      playerBullets: bullets,
      enemyBullets: ebullets,
      player: p ? { hp: p.hp, maxHp: p.maxHp, invuln: Math.round(p.invuln * 100) / 100, shots: p.shots, shotsPerSecond: Math.round(playerDps * 10) / 10 } : null,
      difficultyMultiplier: m.difficulty(),
      nextWave: { number: nextWave, budget: nextBudget, maxEnemyCost: nextWave >= 3 ? COSTS.splitter : nextWave >= 2 ? COSTS.shooter : COSTS.chaser },
      secondsToClearAllHp: playerDps ? Math.round((totalHp / playerDps) * 10) / 10 : null,
    };
    const warnings = [];
    if (p && p.hp <= 1 && enemies.length > 0) warnings.push("Player is on the last hit point with enemies alive.");
    if (enemies.length >= m.maxAlive) warnings.push("Enemy cap reached: spawning is throttled.");
    if (nearest !== null && nearest < 60) warnings.push("An enemy is in contact range.");
    if (report.secondsToClearAllHp !== null && report.secondsToClearAllHp > 20) warnings.push("Enemy hp pool takes more than 20 s of continuous fire to clear.");
    report.warnings = warnings;
    return report;
  },
};
