// @ts-check
// project.grow_town: let the bot (scripts/game/bot.js) grow a town from a fixed seed and report it. It is how a tool or an AI
// sees the economy without playing: the same seed gives the same town, so two reports can be compared.
import { ToolError } from "factoria";
import { growTown } from "../scripts/game/bot.js";

export default {
  name: "grow_town",
  summary: "Grow a town with the bot for some game days and report population, money, hunger and what it built.",
  description:
    "Runs the bot (a rule-based player) from the start state of a map seed for `days` game days (40 = one year) and returns " +
    "{ summary, history, built, stuck, ledger }: history has one row per day (population, housing, employed, jobs, hungry, " +
    "coins, buildings, hash), built lists what the bot placed and when, ledger the goods made and eaten, coins earned and paid. " +
    "Deterministic: no random numbers, the same seed and days give the same hash.",
  input: {
    type: "object",
    properties: {
      seed: { type: "integer", description: "Map seed (default 20261026, the seed of the pinned bot test)." },
      days: { type: "integer", description: "Game days to run, 1..160 (default 40 = one year of 4 seasons x 10 days)." },
      testMap: { type: "boolean", description: "Use the small 12 x 10 test map instead of a generated one." },
    },
  },
  readOnly: true,
  run(args) {
    const days = args.days ?? 40;
    if (!Number.isInteger(days) || days < 1 || days > 160) throw new ToolError("`days` must be a whole number from 1 to 160", "pass days: 40 for one year");
    const { state, bot, history, summary } = growTown({ seed: args.seed ?? 20261026, testMap: !!args.testMap, days });
    return {
      ok: true,
      summary,
      history,
      built: bot.built,
      stuck: [...bot.stuck],
      ledger: state.sim.ledger,
    };
  },
};
