// The behaviour tree (scripts/game/behavior_tree.js): each node, and the way a running node is interrupted.
import { test, describe, expect } from "factoria:test";
import {
  Tree, SUCCESS, FAILURE, RUNNING, sequence, selector, condition, action, wait, cooldown, inverter, succeeder,
} from "../scripts/game/behavior_tree.js";

const ok = action(() => SUCCESS);
const no = action(() => FAILURE);
const busy = action(() => RUNNING);

describe("nodes", () => {
  test("condition: truthy is SUCCESS, falsy is FAILURE, and it reads the blackboard", () => {
    const t = new Tree(condition((bb) => bb.hungry), { hungry: false });
    expect(t.tick(0.1)).toBe(FAILURE);
    t.blackboard.hungry = true;
    expect(t.tick(0.1)).toBe(SUCCESS);
  });

  test("sequence: all must succeed, stops at the first failure, RUNNING while a child runs", () => {
    const calls = [];
    const mk = (name, st) => action(() => (calls.push(name), st));
    expect(new Tree(sequence(mk("a", SUCCESS), mk("b", SUCCESS))).tick(0.1)).toBe(SUCCESS);
    calls.length = 0;
    expect(new Tree(sequence(mk("a", SUCCESS), mk("b", FAILURE), mk("c", SUCCESS))).tick(0.1)).toBe(FAILURE);
    expect(calls).toEqual(["a", "b"]);
    expect(new Tree(sequence(ok, busy, no)).tick(0.1)).toBe(RUNNING);
  });

  test("a running sequence picks up at the running child without asking its conditions again", () => {
    const bb = { go: true, steps: 0 };
    const tree = new Tree(sequence(condition((b) => b.go), action((b) => (++b.steps >= 3 ? SUCCESS : RUNNING))), bb);
    expect(tree.tick(0.1)).toBe(RUNNING);
    bb.go = false; // the condition would fail now, but the sequence does not ask again
    expect(tree.tick(0.1)).toBe(RUNNING);
    expect(tree.tick(0.1)).toBe(SUCCESS);
    expect(bb.steps).toBe(3);
    expect(tree.tick(0.1)).toBe(FAILURE); // a new run starts from the first child
  });

  test("selector: the first child that does not fail, ticked from the first child every time", () => {
    expect(new Tree(selector(no, ok, busy)).tick(0.1)).toBe(SUCCESS);
    expect(new Tree(selector(no, no)).tick(0.1)).toBe(FAILURE);
    const bb = { alarm: false };
    const exits = [];
    const tree = new Tree(
      selector(
        sequence(condition((b) => b.alarm), action(() => RUNNING, { onExit: (b, st) => exits.push("alarm:" + st) })),
        action(() => RUNNING, { onExit: (b, st) => exits.push("idle:" + st) }),
      ),
      bb,
    );
    tree.tick(0.1);
    bb.alarm = true;
    tree.tick(0.1); // the important child interrupts the idle one
    expect(exits).toEqual(["idle:aborted"]);
    // the alarm sequence is RUNNING, so the next tick picks up at its action without asking the condition again (the pitfall
    // the file header warns about): it keeps going, and so does the exit list
    bb.alarm = false;
    expect(tree.tick(0.1)).toBe(RUNNING);
    expect(exits).toEqual(["idle:aborted"]);
  });

  test("action: onEnter once, onExit with the final status", () => {
    const log = [];
    let n = 0;
    const tree = new Tree(action(() => (++n >= 3 ? SUCCESS : RUNNING), { onEnter: () => log.push("enter"), onExit: (b, st) => log.push("exit:" + st) }));
    tree.tick(0.1);
    tree.tick(0.1);
    expect(log).toEqual(["enter"]);
    tree.tick(0.1);
    expect(log).toEqual(["enter", "exit:success"]);
  });

  test("wait: RUNNING for that long, then SUCCESS; it starts over after a tick it was not run", () => {
    const tree = new Tree(wait(0.5));
    let st = tree.tick(0.2);
    expect(st).toBe(RUNNING);
    expect(tree.tick(0.2)).toBe(RUNNING);
    expect(tree.tick(0.2)).toBe(SUCCESS);
    const gated = new Tree(sequence(condition((b) => b.on), wait(0.3)), { on: true });
    gated.tick(0.2);
    gated.blackboard.on = false;
    gated.tick(0.2); // sequence is fresh again, so is the wait
    gated.blackboard.on = true;
    expect(gated.tick(0.2)).toBe(RUNNING);
    expect(gated.tick(0.2)).toBe(SUCCESS);
  });

  test("cooldown: after the child finishes the node FAILS for that many seconds", () => {
    const hits = [];
    const tree = new Tree(cooldown(1, action(() => (hits.push(tree.clock), SUCCESS))));
    expect(tree.tick(0.25)).toBe(SUCCESS);
    expect(tree.tick(0.25)).toBe(FAILURE);
    expect(tree.tick(0.25)).toBe(FAILURE);
    expect(tree.tick(0.25)).toBe(FAILURE);
    expect(tree.tick(0.25)).toBe(SUCCESS);
    expect(hits.length).toBe(2);
  });

  test("inverter and succeeder", () => {
    expect(new Tree(inverter(ok)).tick(0.1)).toBe(FAILURE);
    expect(new Tree(inverter(no)).tick(0.1)).toBe(SUCCESS);
    expect(new Tree(inverter(busy)).tick(0.1)).toBe(RUNNING);
    expect(new Tree(succeeder(no)).tick(0.1)).toBe(SUCCESS);
    expect(new Tree(succeeder(busy)).tick(0.1)).toBe(RUNNING);
  });

  test("two trees from one description keep their own memory", () => {
    const desc = sequence(wait(0.3), action((b) => ((b.done = true), SUCCESS)));
    const a = new Tree(desc, { done: false });
    const b = new Tree(desc, { done: false });
    a.tick(0.2);
    a.tick(0.2);
    expect(a.blackboard.done).toBe(true);
    b.tick(0.2);
    expect(b.blackboard.done).toBe(false);
  });

  test("reset aborts the running action; an unknown node type fails with a message that teaches", () => {
    const exits = [];
    const tree = new Tree(action(() => RUNNING, { onExit: (b, st) => exits.push(st) }));
    tree.tick(0.1);
    tree.reset();
    expect(exits).toEqual(["aborted"]);
    expect(() => new Tree({ type: "bogus" }).tick(0.1)).toThrow(/unknown node type 'bogus'/);
  });
});
