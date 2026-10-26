// @ts-check
// A small synchronous event bus: the contract between the game rules (this package) and everything that reacts to them
// (the view, the HUD, and later the economy, the people, the contracts, the achievements, the audio). Listeners run
// inside emit(), in the order they subscribed. A listener that throws is logged and does not stop the others.

export class Events {
  constructor() {
    /** @type {Map<string, Array<(data: any) => void>>} */
    this.listeners = new Map();
  }

  /**
   * @param {string} name  event name, for example "building.placed" ("*" hears every event as fn(data, name))
   * @param {(data: any, name?: string) => void} fn
   * @returns {() => void} unsubscribe
   */
  on(name, fn) {
    let list = this.listeners.get(name);
    if (!list) this.listeners.set(name, (list = []));
    list.push(fn);
    return () => {
      const i = list.indexOf(fn);
      if (i >= 0) list.splice(i, 1);
    };
  }

  /** @param {string} name @param {any} [data] */
  emit(name, data = {}) {
    for (const key of [name, "*"]) {
      const list = this.listeners.get(key);
      if (!list) continue;
      for (const fn of list.slice()) {
        try {
          fn(data, name);
        } catch (e) {
          console.error(`listener of '${name}' failed: ${e && e.message ? e.message : e}`);
        }
      }
    }
  }
}
