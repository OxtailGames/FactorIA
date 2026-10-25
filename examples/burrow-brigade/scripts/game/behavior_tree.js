// @ts-check
// A small behaviour tree. FactorIA has none (the engine documents no AI module), so the enemies of the game run on this one;
// nothing in it knows about Burrow Brigade, so another game can copy the file.
//
//   const tree = new Tree(selector(
//     sequence(condition((bb) => bb.hungry), action((bb, dt) => (bb.eat(dt) ? SUCCESS : RUNNING))),
//     action((bb, dt) => { bb.wander(dt); return RUNNING; }),
//   ), blackboard);
//   tree.tick(dt);                       // once per frame
//
// A node returns SUCCESS, FAILURE or RUNNING each time it is ticked. The tree is built once and shared by nothing: every
// `Tree` keeps its own memory per node (the running child of a sequence, how long a wait has waited), so ten beetles can
// each run their own copy of the same tree description.
//
// Nodes:
//   sequence(...children)    Ticks the children in order; FAILURE as soon as one fails, RUNNING while one runs (it
//                            picks up at that child next tick), SUCCESS when all succeeded.
//   selector(...children)    Ticks the children in order from the FIRST one every tick (so a more important child can
//                            interrupt a less important one that was running); returns the first that does not fail.
//   condition(fn)            fn(blackboard) -> truthy: SUCCESS, falsy: FAILURE. Never RUNNING.
//   action(fn, hooks?)       fn(blackboard, dt, tree) -> SUCCESS | FAILURE | RUNNING. hooks.onEnter(blackboard) runs when
//                            it starts, hooks.onExit(blackboard, status) when it finishes or is interrupted (`status` is
//                            "aborted" in that case: a selector ticked an earlier child instead).
//   wait(seconds)            RUNNING for that long, then SUCCESS. Starts over when it was not ticked on the previous tick.
//   cooldown(seconds, child) Ticks the child; once it finishes (SUCCESS or FAILURE) the node FAILS for `seconds` without
//                            ticking it. Good for an attack that must not repeat at once.
//   inverter(child)          Swaps SUCCESS and FAILURE; RUNNING stays.
//   succeeder(child)         SUCCESS when the child finishes either way.
// "Visited" memory: a node that was not ticked on the previous tick starts fresh (a sequence goes back to its first child,
// a wait back to zero). That is what makes interrupting by a selector clean.

export const SUCCESS = "success";
export const FAILURE = "failure";
export const RUNNING = "running";

/** @typedef {"success"|"failure"|"running"} Status */
/**
 * @typedef {object} Node
 * @property {string} type
 * @property {Node[]} [children]
 * @property {Function} [fn]
 * @property {number} [seconds]
 * @property {{onEnter?: Function, onExit?: Function}} [hooks]
 */

/** @param {Node[]} children */
export function sequence(...children) {
  return /** @type {Node} */ ({ type: "sequence", children });
}
/** @param {Node[]} children */
export function selector(...children) {
  return /** @type {Node} */ ({ type: "selector", children });
}
/** @param {(bb: any) => any} fn */
export function condition(fn) {
  return /** @type {Node} */ ({ type: "condition", fn });
}
/**
 * @param {(bb: any, dt: number, tree: Tree) => Status} fn
 * @param {{onEnter?: (bb: any) => void, onExit?: (bb: any, status: Status|"aborted") => void}} [hooks]
 */
export function action(fn, hooks = {}) {
  return /** @type {Node} */ ({ type: "action", fn, hooks });
}
/** @param {number} seconds */
export function wait(seconds) {
  return /** @type {Node} */ ({ type: "wait", seconds });
}
/**
 * @param {number} seconds
 * @param {Node} child
 */
export function cooldown(seconds, child) {
  return /** @type {Node} */ ({ type: "cooldown", seconds, children: [child] });
}
/** @param {Node} child */
export function inverter(child) {
  return /** @type {Node} */ ({ type: "inverter", children: [child] });
}
/** @param {Node} child */
export function succeeder(child) {
  return /** @type {Node} */ ({ type: "succeeder", children: [child] });
}

export class Tree {
  /**
   * @param {Node} root
   * @param {any} [blackboard]  The object every condition and action receives: the state of the thing the tree drives.
   */
  constructor(root, blackboard = {}) {
    this.root = root;
    this.blackboard = blackboard;
    /** Seconds the tree has run (the sum of the `dt` it was ticked with). */
    this.clock = 0;
    this.count = 0;
    /** @type {Map<Node, any>} */
    this.memory = new Map();
    /** @type {Status} Result of the last tick. */
    this.status = FAILURE;
  }

  /**
   * Runs the tree one step.
   * @param {number} dt
   * @returns {Status}
   */
  tick(dt) {
    this.clock += dt;
    this.count++;
    this.dt = dt;
    this.status = this.run(this.root);
    // an action that was running last tick and was not reached this tick was interrupted
    for (const [node, mem] of this.memory) {
      if (node.type === "action" && mem.running && mem.seen !== this.count) {
        mem.running = false;
        node.hooks?.onExit?.(this.blackboard, "aborted");
      }
    }
    return this.status;
  }

  /** Forgets everything the nodes remember (and aborts the running actions). */
  reset() {
    for (const [node, mem] of this.memory) if (node.type === "action" && mem.running) node.hooks?.onExit?.(this.blackboard, "aborted");
    this.memory.clear();
  }

  /** Memory of a node, fresh when the node was not ticked last tick. */
  mem(node) {
    let m = this.memory.get(node);
    if (!m) {
      m = { seen: -10 };
      this.memory.set(node, m);
    }
    const fresh = m.seen !== this.count - 1 && m.seen !== this.count;
    if (fresh) {
      const keep = node.type === "cooldown" ? m.until : undefined;
      for (const k of Object.keys(m)) if (k !== "seen" && k !== "running") delete m[k];
      if (keep !== undefined) m.until = keep;
    }
    m.seen = this.count;
    return m;
  }

  /**
   * @param {Node} node
   * @returns {Status}
   */
  run(node) {
    const bb = this.blackboard;
    switch (node.type) {
      case "condition":
        this.mem(node);
        return /** @type {Function} */ (node.fn)(bb) ? SUCCESS : FAILURE;
      case "action": {
        const m = this.mem(node);
        if (!m.running) {
          m.running = true;
          node.hooks?.onEnter?.(bb);
        }
        const st = /** @type {Status} */ (/** @type {Function} */ (node.fn)(bb, this.dt, this));
        if (st !== RUNNING) {
          m.running = false;
          node.hooks?.onExit?.(bb, st);
        }
        return st;
      }
      case "sequence": {
        const m = this.mem(node);
        const children = /** @type {Node[]} */ (node.children);
        for (let i = m.index ?? 0; i < children.length; i++) {
          const st = this.run(children[i]);
          if (st === RUNNING) {
            m.index = i;
            return RUNNING;
          }
          if (st === FAILURE) {
            m.index = 0;
            return FAILURE;
          }
        }
        m.index = 0;
        return SUCCESS;
      }
      case "selector": {
        this.mem(node);
        for (const child of /** @type {Node[]} */ (node.children)) {
          const st = this.run(child);
          if (st !== FAILURE) return st;
        }
        return FAILURE;
      }
      case "wait": {
        const m = this.mem(node);
        m.waited = (m.waited ?? 0) + this.dt;
        if (m.waited >= /** @type {number} */ (node.seconds)) {
          m.waited = 0;
          return SUCCESS;
        }
        return RUNNING;
      }
      case "cooldown": {
        const m = this.mem(node);
        if (m.until !== undefined && this.clock < m.until) return FAILURE;
        const st = this.run(/** @type {Node[]} */ (node.children)[0]);
        if (st !== RUNNING) m.until = this.clock + /** @type {number} */ (node.seconds);
        return st;
      }
      case "inverter": {
        this.mem(node);
        const st = this.run(/** @type {Node[]} */ (node.children)[0]);
        return st === SUCCESS ? FAILURE : st === FAILURE ? SUCCESS : RUNNING;
      }
      case "succeeder": {
        this.mem(node);
        const st = this.run(/** @type {Node[]} */ (node.children)[0]);
        return st === RUNNING ? RUNNING : SUCCESS;
      }
    }
    throw new Error(`behavior_tree: unknown node type '${node.type}'. Build nodes with sequence, selector, condition, action, wait, cooldown, inverter or succeeder.`);
  }
}
