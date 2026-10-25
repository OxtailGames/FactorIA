// @ts-check
// How many strata and floors the mine has, in one tiny module the saves and the seed codes can import without pulling the
// generator's whole table into their own cycle. The numbers come from `STRATA` (generator.js).
import { STRATA } from "./generator.js";

/** Floors in one stratum (every stratum has the same number). */
export const FLOORS_PER_STRATUM = STRATA[0].floors;
/** Strata in the mine. */
export const STRATUM_COUNT = STRATA.length;
