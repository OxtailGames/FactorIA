// @ts-check
// Sets the run's banked state before the camp or join screen builds, so a store screenshot shows a mid-run camp (cash and a few
// upgrades bought) instead of the empty first one. Only the store scenes (store/scenes/) use it. It must come before the
// camp's own script in the scene: that one reads the run in onStart.
import { Behaviour } from "factoria";
import { run } from "../scripts/game/run_state.js";

export default class StoreSetup extends Behaviour {
  /** Banked cash. */
  cash = 740;
  /** Stratum (0..2) and floor (1..3) the camp announces. */
  stratum = 1;
  floor = 1;
  /** Upgrades bought, by name (see BASE_UPGRADES). */
  upgrades = { pickTier: 1, pickSpeed: 1.25, lampOil: 150, lampRadius: 1.15, walkSpeed: 1, torches: 8 };

  onStart() {
    run.cash = this.cash;
    run.stratum = this.stratum;
    run.floor = this.floor;
    run.upgrades = { ...run.upgrades, ...this.upgrades };
  }
}
