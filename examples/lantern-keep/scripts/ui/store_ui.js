// @ts-check
// What the three store screens (achievements, leaderboards, shop) share: one plain sentence for every way the store can
// be missing or fail, so no screen is ever blank and none ever throws.
import { platform, i18n } from "factoria";

/**
 * The sentence a screen shows instead of its content, or "" when the store can do `service` and nothing went wrong.
 * `what` is the string key of the thing the screen shows ("achievements.what"); `problem` the rejection of the last request.
 */
export function explain(service, what, problem = null) {
  const name = i18n.t(what);
  if (!platform.has(service)) return i18n.t("platform.noStore", { what: name }); // the `none` backend, or a store without this service
  if (!problem) return "";
  if (problem.code === "notSignedIn") return i18n.t("platform.notSignedIn", { what: name });
  if (problem.code === "network") return i18n.t("platform.network", { what: name });
  return i18n.t("platform.failed", { what: name, code: problem.code ?? "error", detail: problem.hint ?? problem.message ?? "" });
}

/** Signs the player in (a failure is not an error here: the request that follows says what is wrong). */
export async function trySignIn() {
  try {
    await platform.signIn();
  } catch {
    // The request that follows reports it.
  }
}
