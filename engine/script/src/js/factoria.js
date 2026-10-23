// FactorIA scripting prelude. Evaluated once per ScriptSystem as `(function (N) {...})`, where N is the object of
// native engine functions (script_natives.cpp). Everything user-facing ("factoria" and "factoria:test" modules) is
// built here on top of N. Keep this file dependency-free; it is baked into the binary.
(function (N) {
  "use strict";

  // ======================================================================================================== helpers
  const isObj = (v) => v !== null && typeof v === "object";
  const num = (v) => (typeof v === "number" ? v : Number(v));

  function editDistance(a, b) {
    a = String(a).toLowerCase(); b = String(b).toLowerCase();
    const dp = Array.from({ length: a.length + 1 }, (_, i) => [i]);
    for (let j = 1; j <= b.length; j++) dp[0][j] = j;
    for (let i = 1; i <= a.length; i++)
      for (let j = 1; j <= b.length; j++)
        dp[i][j] = Math.min(dp[i - 1][j] + 1, dp[i][j - 1] + 1, dp[i - 1][j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1));
    return dp[a.length][b.length];
  }
  function closest(name, candidates) {
    let best = "", bd = Infinity;
    for (const c of candidates) { const d = editDistance(name, c); if (d < bd) { bd = d; best = c; } }
    return bd <= Math.max(2, Math.floor(String(name).length / 3)) ? best : "";
  }

  // ======================================================================================================= console
  function inspect(x, depth = 0) {
    if (typeof x === "string") return x;
    if (x === undefined) return "undefined";
    if (typeof x === "function") return `[Function ${x.name || "anonymous"}]`;
    if (typeof x === "symbol" || typeof x === "bigint") return String(x);
    if (x instanceof Error) return x.stack ? String(x.stack) : `${x.name}: ${x.message}`;
    try {
      const seen = new WeakSet();
      const out = JSON.stringify(x, function (k, v) {
        if (v instanceof Entity) return `Entity(${v.id})`;
        if (typeof v === "function") return `[Function ${v.name || "anonymous"}]`;
        if (typeof v === "bigint") return String(v) + "n";
        if (typeof v === "object" && v !== null) {
          if (seen.has(v)) return "[Circular]";
          seen.add(v);
        }
        return v;
      });
      return out === undefined ? String(x) : out;
    } catch (e) {
      return String(x);
    }
  }
  const fmt = (args) => args.map((a) => inspect(a)).join(" ");
  const consoleObj = {
    log: (...a) => N.log(2, fmt(a)),
    info: (...a) => N.log(2, fmt(a)),
    debug: (...a) => N.log(1, fmt(a)),
    warn: (...a) => N.log(3, fmt(a)),
    error: (...a) => N.log(4, fmt(a)),
    assert: (c, ...a) => { if (!c) N.log(4, "Assertion failed: " + fmt(a)); },
    trace: (...a) => N.log(1, fmt(a) + "\n" + new Error().stack),
  };
  globalThis.console = consoleObj;

  // Determinism: Math.random uses the world RNG (seeded per run) instead of the wall clock.
  Math.random = () => N.rngFloat();

  // =================================================================================================== vector values
  const Vec2Methods = {
    set(x, y) { this.x = x; this.y = y; return this; },
    copy(v) { this.x = v.x; this.y = v.y; return this; },
    add(v) { return new Vec2(this.x + v.x, this.y + v.y); },
    sub(v) { return new Vec2(this.x - v.x, this.y - v.y); },
    mul(v) { return typeof v === "number" ? new Vec2(this.x * v, this.y * v) : new Vec2(this.x * v.x, this.y * v.y); },
    scale(s) { return new Vec2(this.x * s, this.y * s); },
    div(v) { return typeof v === "number" ? new Vec2(this.x / v, this.y / v) : new Vec2(this.x / v.x, this.y / v.y); },
    dot(v) { return this.x * v.x + this.y * v.y; },
    cross(v) { return this.x * v.y - this.y * v.x; },
    length() { return Math.hypot(this.x, this.y); },
    lengthSq() { return this.x * this.x + this.y * this.y; },
    normalized() { const l = Math.hypot(this.x, this.y); return l > 1e-6 ? new Vec2(this.x / l, this.y / l) : new Vec2(0, 0); },
    distance(v) { return Math.hypot(v.x - this.x, v.y - this.y); },
    lerp(v, t) { return new Vec2(this.x + (v.x - this.x) * t, this.y + (v.y - this.y) * t); },
    clone() { return new Vec2(this.x, this.y); },
    equals(v, eps = 1e-5) { return Math.abs(this.x - v.x) <= eps && Math.abs(this.y - v.y) <= eps; },
    angle() { return Math.atan2(this.y, this.x) * 180 / Math.PI; },
    rotated(deg) {
      const r = deg * Math.PI / 180, c = Math.cos(r), s = Math.sin(r);
      return new Vec2(this.x * c - this.y * s, this.x * s + this.y * c);
    },
    toArray() { return [this.x, this.y]; },
    toJSON() { return [this.x, this.y]; },
    toString() { return `vec2(${this.x}, ${this.y})`; },
  };
  const Vec3Methods = {
    set(x, y, z) { this.x = x; this.y = y; this.z = z; return this; },
    copy(v) { this.x = v.x; this.y = v.y; if (v.z !== undefined) this.z = v.z; return this; },
    add(v) { return new Vec3(this.x + v.x, this.y + v.y, this.z + (v.z || 0)); },
    sub(v) { return new Vec3(this.x - v.x, this.y - v.y, this.z - (v.z || 0)); },
    mul(v) { return typeof v === "number" ? new Vec3(this.x * v, this.y * v, this.z * v) : new Vec3(this.x * v.x, this.y * v.y, this.z * (v.z ?? 1)); },
    scale(s) { return new Vec3(this.x * s, this.y * s, this.z * s); },
    div(v) { return typeof v === "number" ? new Vec3(this.x / v, this.y / v, this.z / v) : new Vec3(this.x / v.x, this.y / v.y, this.z / (v.z ?? 1)); },
    dot(v) { return this.x * v.x + this.y * v.y + this.z * (v.z || 0); },
    cross(v) { return new Vec3(this.y * v.z - this.z * v.y, this.z * v.x - this.x * v.z, this.x * v.y - this.y * v.x); },
    length() { return Math.hypot(this.x, this.y, this.z); },
    lengthSq() { return this.x * this.x + this.y * this.y + this.z * this.z; },
    normalized() { const l = Math.hypot(this.x, this.y, this.z); return l > 1e-6 ? new Vec3(this.x / l, this.y / l, this.z / l) : new Vec3(0, 0, 0); },
    distance(v) { return Math.hypot(v.x - this.x, v.y - this.y, (v.z || 0) - this.z); },
    lerp(v, t) { return new Vec3(this.x + (v.x - this.x) * t, this.y + (v.y - this.y) * t, this.z + ((v.z || 0) - this.z) * t); },
    clone() { return new Vec3(this.x, this.y, this.z); },
    equals(v, eps = 1e-5) { return Math.abs(this.x - v.x) <= eps && Math.abs(this.y - v.y) <= eps && Math.abs(this.z - (v.z || 0)) <= eps; },
    toArray() { return [this.x, this.y, this.z]; },
    toJSON() { return [this.x, this.y, this.z]; },
    toString() { return `vec3(${this.x}, ${this.y}, ${this.z})`; },
  };
  const ColorMethods = {
    set(r, g, b, a = 1) { this.r = r; this.g = g; this.b = b; this.a = a; return this; },
    copy(c) { this.r = c.r; this.g = c.g; this.b = c.b; this.a = c.a ?? 1; return this; },
    clone() { return new Color(this.r, this.g, this.b, this.a); },
    withAlpha(a) { return new Color(this.r, this.g, this.b, a); },
    lerp(c, t) { return new Color(this.r + (c.r - this.r) * t, this.g + (c.g - this.g) * t, this.b + (c.b - this.b) * t, this.a + (c.a - this.a) * t); },
    mul(c) { return typeof c === "number" ? new Color(this.r * c, this.g * c, this.b * c, this.a) : new Color(this.r * c.r, this.g * c.g, this.b * c.b, this.a * c.a); },
    equals(c, eps = 1e-5) { return Math.abs(this.r - c.r) <= eps && Math.abs(this.g - c.g) <= eps && Math.abs(this.b - c.b) <= eps && Math.abs(this.a - c.a) <= eps; },
    toHex() {
      const h = (v) => Math.max(0, Math.min(255, Math.round(v * 255))).toString(16).padStart(2, "0");
      return "#" + h(this.r) + h(this.g) + h(this.b) + (this.a < 1 ? h(this.a) : "");
    },
    toArray() { return [this.r, this.g, this.b, this.a]; },
    toJSON() { return [this.r, this.g, this.b, this.a]; },
    toString() { return `color(${this.r}, ${this.g}, ${this.b}, ${this.a})`; },
  };

  class Vec2 {
    constructor(x = 0, y = 0) { this.x = x; this.y = y; }
    static fromAngle(deg) { const r = deg * Math.PI / 180; return new Vec2(Math.cos(r), Math.sin(r)); }
    static get zero() { return new Vec2(0, 0); }
    static get one() { return new Vec2(1, 1); }
  }
  class Vec3 {
    constructor(x = 0, y = 0, z = 0) { this.x = x; this.y = y; this.z = z; }
    get xy() { return new Vec2(this.x, this.y); }
    static get zero() { return new Vec3(0, 0, 0); }
    static get one() { return new Vec3(1, 1, 1); }
    static get up() { return new Vec3(0, 1, 0); }
  }
  class Color {
    constructor(r = 1, g = 1, b = 1, a = 1) { this.r = r; this.g = g; this.b = b; this.a = a; }
    static hex(s) { return parseColor(s); }
    static get white() { return new Color(1, 1, 1, 1); }
    static get black() { return new Color(0, 0, 0, 1); }
    static get red() { return new Color(1, 0, 0, 1); }
    static get green() { return new Color(0, 1, 0, 1); }
    static get blue() { return new Color(0, 0, 1, 1); }
    static get clear() { return new Color(0, 0, 0, 0); }
  }
  for (const [C, M] of [[Vec2, Vec2Methods], [Vec3, Vec3Methods], [Color, ColorMethods]])
    for (const k of Object.keys(M)) Object.defineProperty(C.prototype, k, { value: M[k], writable: true, configurable: true, enumerable: false });

  // Vectors, colours and rects are array-like too (live views included, they inherit this): v[1], [...v], destructuring,
  // for...of, Array.from(v). `length` is the count only where there is no length() method (Color, Rect); Vec2/Vec3/Vec4 keep
  // length() as the vector's magnitude. Not enumerable: Object.keys stays x y z w.
  function arrayLike(proto, keys) {
    keys.forEach((k, i) => Object.defineProperty(proto, i, {
      get() { return this[k]; }, set(v) { this[k] = v; }, configurable: true,
    }));
    Object.defineProperty(proto, Symbol.iterator, {
      value: function* () { for (const k of keys) yield this[k]; }, writable: true, configurable: true,
    });
    if (!("length" in proto)) Object.defineProperty(proto, "length", { value: keys.length, configurable: true });
  }
  arrayLike(Vec2.prototype, ["x", "y"]);
  arrayLike(Vec3.prototype, ["x", "y", "z"]);
  arrayLike(Color.prototype, ["r", "g", "b", "a"]);

  const NAMED_COLORS = {
    white: [1, 1, 1], black: [0, 0, 0], red: [1, 0, 0], green: [0, 0.5, 0], lime: [0, 1, 0], blue: [0, 0, 1],
    yellow: [1, 1, 0], cyan: [0, 1, 1], magenta: [1, 0, 1], gray: [0.5, 0.5, 0.5], grey: [0.5, 0.5, 0.5],
    orange: [1, 0.65, 0], purple: [0.5, 0, 0.5], pink: [1, 0.75, 0.8], brown: [0.65, 0.16, 0.16], transparent: [0, 0, 0, 0],
  };
  function parseColor(s) {
    if (typeof s !== "string") throw new Error(`color() expects a hex string like "#ffcc00" but got ${inspect(s)}`);
    const t = s.trim().toLowerCase();
    if (NAMED_COLORS[t]) { const c = NAMED_COLORS[t]; return new Color(c[0], c[1], c[2], c.length > 3 ? c[3] : 1); }
    let h = t.startsWith("#") ? t.slice(1) : t;
    if (!/^[0-9a-f]+$/.test(h) || ![3, 4, 6, 8].includes(h.length))
      throw new Error(`invalid color '${s}'. Use "#rgb", "#rrggbb", "#rrggbbaa" or a name like "red".`);
    if (h.length <= 4) h = h.split("").map((c) => c + c).join("");
    const v = (i) => parseInt(h.slice(i, i + 2), 16) / 255;
    return new Color(v(0), v(2), v(4), h.length === 8 ? v(6) : 1);
  }

  // Live views over engine memory --------------------------------------------------------------------------------
  function makeViewClass(Base, keys) {
    function View(h, t, f) { this.$h = h; this.$t = t; this.$f = f; Object.preventExtensions(this); }
    View.prototype = Object.create(Base.prototype, { constructor: { value: View, writable: true, configurable: true } });
    keys.forEach((k, i) => Object.defineProperty(View.prototype, k, {
      get() { return N.fgetn(this.$h, this.$t, this.$f, i); },
      set(v) { N.fsetn(this.$h, this.$t, this.$f, i, v); },
      enumerable: true, configurable: true,
    }));
    return View;
  }
  class Rect {
    constructor(x = 0, y = 0, w = 0, h = 0) { this.x = x; this.y = y; this.w = w; this.h = h; }
    contains(p) { return p.x >= this.x && p.y >= this.y && p.x <= this.x + this.w && p.y <= this.y + this.h; }
    toArray() { return [this.x, this.y, this.w, this.h]; }
    toJSON() { return [this.x, this.y, this.w, this.h]; }
  }
  arrayLike(Rect.prototype, ["x", "y", "w", "h"]);
  const Vec2View = makeViewClass(Vec2, ["x", "y"]);
  const Vec3View = makeViewClass(Vec3, ["x", "y", "z"]);
  const Vec4View = makeViewClass(Vec3, ["x", "y", "z", "w"]);
  const ColorView = makeViewClass(Color, ["r", "g", "b", "a"]);
  const RectView = makeViewClass(Rect, ["x", "y", "w", "h"]);
  arrayLike(Vec4View.prototype, ["x", "y", "z", "w"]);
  // Vec3 methods use .z only; Vec4 views keep w as an extra accessor.
  Object.defineProperty(Vec4View.prototype, "toJSON", { value() { return [this.x, this.y, this.z, this.w]; }, configurable: true });
  Object.defineProperty(Vec4View.prototype, "toArray", { value() { return [this.x, this.y, this.z, this.w]; }, configurable: true });

  function vec2(x, y) {
    if (x === undefined) return new Vec2(0, 0);
    if (typeof x === "number") return new Vec2(x, y === undefined ? x : y);
    if (Array.isArray(x)) return new Vec2(x[0] ?? 0, x[1] ?? 0);
    if (isObj(x)) return new Vec2(x.x ?? 0, x.y ?? 0);
    throw new Error(`vec2() expects numbers, an [x, y] array or an {x, y} object but got ${inspect(x)}`);
  }
  function vec3(x, y, z) {
    if (x === undefined) return new Vec3(0, 0, 0);
    if (typeof x === "number") return new Vec3(x, y === undefined ? x : y, z === undefined ? (y === undefined ? x : 0) : z);
    if (Array.isArray(x)) return new Vec3(x[0] ?? 0, x[1] ?? 0, x[2] ?? 0);
    if (isObj(x)) return new Vec3(x.x ?? 0, x.y ?? 0, x.z ?? 0);
    throw new Error(`vec3() expects numbers, an [x, y, z] array or an {x, y, z} object but got ${inspect(x)}`);
  }
  function color(r, g, b, a) {
    if (typeof r === "string") return parseColor(r);
    if (Array.isArray(r)) return new Color(r[0], r[1], r[2], r[3] ?? 1);
    if (isObj(r)) return new Color(r.r ?? 1, r.g ?? 1, r.b ?? 1, r.a ?? 1);
    if (r === undefined) return new Color(1, 1, 1, 1);
    if (g === undefined) return new Color(r, r, r, 1);
    return new Color(r, g, b, a ?? 1);
  }

  // Converts any script value into plain JSON-able data (entities -> ids, vectors -> arrays).
  function plain(v) {
    if (v === undefined) return null;
    if (v instanceof Entity) return v.id;
    if (Array.isArray(v)) return v.map(plain);
    if (isObj(v)) {
      if (typeof v.toJSON === "function") return plain(v.toJSON());
      const o = {};
      for (const k of Object.keys(v)) { if (v[k] !== undefined && typeof v[k] !== "function") o[k] = plain(v[k]); }
      return o;
    }
    return v;
  }

  // ===================================================================================================== components
  const types = N.types();
  const typeByName = new Map();
  for (const t of types) typeByName.set(t.name, t);
  const TRANSFORM = typeByName.get("Transform");
  const SETTINGS = typeByName.get("SceneSettings");
  const viewClasses = new Map();

  function typeOf(name) {
    const t = typeByName.get(name);
    if (t) return t;
    return types[N.compType(name)]; // throws with a "did you mean" message
  }

  const FIELD_VIEW = { vec2: Vec2View, vec3: Vec3View, vec4: Vec4View, color: ColorView, rect: RectView };
  const FIELD_N = { vec2: 2, vec3: 3, vec4: 4, color: 4, rect: 4 };
  const FIELD_KEYS = { vec2: ["x", "y"], vec3: ["x", "y", "z"], vec4: ["x", "y", "z", "w"], color: ["r", "g", "b", "a"], rect: ["x", "y", "w", "h"] };

  // Converts any accepted vector form (Vec2/Vec3 instance, plain {x, y(, z)} object, [x, y(, z)] array) into a
  // plain array of n numbers (n = 2 or 3). A missing z becomes `zDefault` (0 for positions, 1 for scale).
  function vecArr(v, n, label, zDefault = 0) {
    let x, y, z;
    if (Array.isArray(v)) { x = v[0]; y = v[1]; z = v[2]; }
    else if (isObj(v) && !(v instanceof Entity)) { x = v.x; y = v.y; z = v.z; }
    const ok = typeof x === "number" && typeof y === "number" && (z === undefined || typeof z === "number") &&
      Number.isFinite(x) && Number.isFinite(y) && (z === undefined || Number.isFinite(z));
    if (!ok)
      throw new Error(`${label} expects ${n === 2 ? "a 2D vector" : "a 2D or 3D vector"}: a Vec2/Vec3 (vec2(x, y)), a plain ` +
        `{ x, y${n === 3 ? ", z?" : ""} } object or an [x, y${n === 3 ? ", z?" : ""}] array of finite numbers, but got ${inspect(v)}`);
    return n === 2 ? [x, y] : [x, y, z === undefined ? zDefault : z];
  }
  const rectArr = (r, label) => {
    const a = Array.isArray(r) ? r : isObj(r) ? [r.x, r.y, r.w, r.h] : null;
    if (!a || a.length < 4 || !a.slice(0, 4).every((x) => typeof x === "number" && Number.isFinite(x)))
      throw new Error(`${label} expects a Rect, a plain { x, y, w, h } object or an [x, y, w, h] array, but got ${inspect(r)}`);
    return a.slice(0, 4);
  };

  function toFloats(v, kind, label) {
    if (kind === "vec2") return vecArr(v, 2, label);
    if (kind === "vec3") {
      if (typeof v === "number" && label === "Transform.rotation") return [0, 0, v];
      if (typeof v === "number" && label === "Transform.scale") return [v, v, v];
      return vecArr(v, 3, label, label === "Transform.scale" ? 1 : 0);
    }
    if (Array.isArray(v)) return v;
    if (typeof v === "string" && kind === "color") return parseColor(v).toArray();
    if (isObj(v)) {
      const keys = FIELD_KEYS[kind];
      const out = keys.map((k) => v[k]);
      if (kind === "vec2" && out[0] === undefined && v[0] !== undefined) return [v[0], v[1]];
      return out;
    }
    throw new Error(`${label} expects ${kind === "color" ? '{r, g, b, a}, [r, g, b, a] or "#rrggbb"' : "{" + FIELD_KEYS[kind].join(", ") + "} or an array"}, got ${inspect(v)}`);
  }

  function unknownField(t, k, names) {
    const sug = closest(k, names);
    return new Error(`${t.name} has no field '${String(k)}'.` + (sug ? ` Did you mean '${sug}'?` : "") + ` Fields: ${names.join(", ")}`);
  }

  function viewClassFor(t) {
    let C = viewClasses.get(t.id);
    if (C) return C;
    const names = t.fields.map((f) => f.name);
    C = function ComponentView(h) { this.$h = h; };
    Object.defineProperty(C, "name", { value: t.name + "View" });
    const proto = C.prototype;
    t.fields.forEach((f, fi) => {
      const label = `${t.name}.${f.name}`;
      const ti = t.id;
      let get, set;
      switch (f.kind) {
        case "vec2": case "vec3": case "vec4": case "color": case "rect": {
          const V = FIELD_VIEW[f.kind];
          get = function () { return new V(this.$h, ti, fi); };
          set = function (v) { N.fset(this.$h, ti, fi, toFloats(v, f.kind, label)); };
          break;
        }
        case "entity":
          get = function () { return entityOf(N.fget(this.$h, ti, fi)); };
          set = function (v) { N.fset(this.$h, ti, fi, v instanceof Entity ? v.$h : v); };
          break;
        case "json":
          get = function () { return N.fget(this.$h, ti, fi); };
          set = function (v) { N.fset(this.$h, ti, fi, plain(v)); };
          break;
        default:
          get = function () { return N.fget(this.$h, ti, fi); };
          set = function (v) { N.fset(this.$h, ti, fi, v); };
      }
      Object.defineProperty(proto, f.name, { get, set, enumerable: true, configurable: true });
    });
    Object.defineProperties(proto, {
      toJSON: { value() { return N.compJson(this.$h, t.id); }, configurable: true },
      toString: { value() { return `${t.name}(${this.$h < 0 ? "settings" : N.idOf(this.$h)})`; }, configurable: true },
      $type: { get() { return t.name; } },
    });
    const handler = {
      get(target, k) {
        if (typeof k === "symbol" || k in target) return target[k];
        if (typeof k === "string" && k !== "then" && !k.startsWith("$")) {
          const sug = closest(k, names);
          if (sug) throw unknownField(t, k, names);
        }
        return undefined;
      },
      set(target, k, v) {
        if (k in target && typeof k === "string" && !k.startsWith("$")) { target[k] = v; return true; }
        throw unknownField(t, k, names);
      },
      has(target, k) { return k in target; },
      ownKeys() { return names; },
      getOwnPropertyDescriptor(target, k) {
        return names.includes(k) ? { enumerable: true, configurable: true, value: target[k] } : undefined;
      },
    };
    const Factory = function (h) { return new Proxy(new C(h), handler); };
    viewClasses.set(t.id, Factory);
    return Factory;
  }
  function viewOf(h, t) { return viewClassFor(t)(h); }

  // Converts component fields written by a script into JSON for the engine: Entity -> id, vectors -> arrays
  // (any accepted vector form; 2D values get z = 0, scale z = 1, a number rotation means z degrees).
  function lookupType(name) {
    if (typeByName.has(name)) return typeByName.get(name);
    const l = String(name).toLowerCase();
    for (const t of types) if (t.name.toLowerCase() === l) return t;
    return undefined;
  }
  function fieldsPlain(typeName, fields) {
    if (!isObj(fields) || Array.isArray(fields)) return plain(fields);
    const t = lookupType(typeName);
    const out = {};
    for (const k of Object.keys(fields)) {
      const v = fields[k];
      if (v === undefined || typeof v === "function") continue;
      const f = t && t.fields.find((x) => x.name === k);
      if (f && (f.kind === "vec2" || f.kind === "vec3") && v !== null) out[k] = toFloats(v, f.kind, `${t.name}.${k}`);
      else out[k] = plain(v);
    }
    return out;
  }
  function entityPlain(j) {
    if (!isObj(j) || Array.isArray(j)) return plain(j);
    const out = {};
    for (const k of Object.keys(j)) {
      const v = j[k];
      if (v === undefined) continue;
      if (k === "components" && isObj(v)) {
        out.components = {};
        for (const c of Object.keys(v)) out.components[c] = fieldsPlain(c, v[c]);
      } else if (k === "children" && Array.isArray(v)) out.children = v.map(entityPlain);
      else out[k] = plain(v);
    }
    return out;
  }
  // position / rotation / scale / props options shared by world.spawn and world.spawnPrefab.
  function applySpawnOptions(ov, opts, what) {
    ov.components = ov.components || {};
    if (opts.position !== undefined || opts.rotation !== undefined || opts.scale !== undefined) {
      const tr = ov.components.Transform = ov.components.Transform || {};
      if (opts.position !== undefined) tr.position = vecArr(opts.position, 3, `${what} position`);
      if (opts.rotation !== undefined) tr.rotation = typeof opts.rotation === "number" ? [0, 0, opts.rotation] : vecArr(opts.rotation, 3, `${what} rotation (a number = degrees around z, or a vector)`);
      if (opts.scale !== undefined) tr.scale = typeof opts.scale === "number" ? [opts.scale, opts.scale, opts.scale] : vecArr(opts.scale, 3, `${what} scale`, 1);
    }
    if (opts.props !== undefined) {
      if (!isObj(opts.props) || Array.isArray(opts.props)) throw new Error(`${what} props must be an object merged into Script.props, e.g. { speed: 3 }`);
      const sc = ov.components.Script = ov.components.Script || {};
      sc.props = Object.assign({}, sc.props || {}, plain(opts.props));
    }
    return ov;
  }

  // ========================================================================================================= Entity
  const entityCache = new Map();
  function entityOf(h) {
    if (h === null || h === undefined) return null;
    let e = entityCache.get(h);
    if (e === undefined) { e = new Entity(h); entityCache.set(h, e); }
    return e;
  }
  function entityHandle(e, what) {
    if (e instanceof Entity) return e.$h;
    if (typeof e === "string") {
      const h = N.find(e);
      if (h === null) throw new Error(`${what}: no entity with id or name '${e}'`);
      return h;
    }
    throw new Error(`${what}: expected an Entity but got ${inspect(e)}`);
  }

  class Entity {
    constructor(h) { this.$h = h; }
    get id() { return N.idOf(this.$h); }
    set id(v) { N.setId(this.$h, v); }
    get name() { return N.getName(this.$h); }
    set name(v) { N.setName(this.$h, String(v)); }
    get tags() { return N.tags(this.$h); }
    set tags(v) { N.setTags(this.$h, v); }
    get active() { return N.getActive(this.$h); }
    set active(v) { N.setActive(this.$h, !!v); }
    get activeInHierarchy() { return N.activeInHierarchy(this.$h); }
    get alive() { return N.alive(this.$h); }
    get transform() { return viewOf(this.$h, TRANSFORM); }
    get position() { return viewOf(this.$h, TRANSFORM).position; }
    set position(v) { viewOf(this.$h, TRANSFORM).position = v; }
    get worldPosition() { const p = N.worldPos(this.$h); return new Vec3(p[0], p[1], p[2]); }
    set worldPosition(v) { N.setWorldPos(this.$h, vecArr(v, 3, "entity.worldPosition")); }
    get(name) {
      const t = typeOf(name);
      return N.hasComp(this.$h, t.name) ? viewOf(this.$h, t) : null;
    }
    has(name) { return N.hasComp(this.$h, name); }
    add(name, fields) { const ti = N.addComp(this.$h, name, fields === undefined ? null : fieldsPlain(name, fields)); return viewOf(this.$h, types[ti]); }
    set(name, fields) { N.patchComp(this.$h, name, fieldsPlain(name, fields)); return this.get(name); }
    remove(name) { return N.removeComp(this.$h, name); }
    components() { return N.compNames(this.$h); }
    destroy() { if (N.alive(this.$h)) N.destroy(this.$h); }
    get parent() { return entityOf(N.parent(this.$h)); }
    get children() { return N.children(this.$h).map(entityOf); }
    setParent(parent, keepWorld = false) {
      N.setParent(this.$h, parent === null || parent === undefined ? null : entityHandle(parent, "setParent"), keepWorld);
    }
    hasTag(t) { return N.hasTag(this.$h, t); }
    addTag(t) { N.addTag(this.$h, t); }
    removeTag(t) { N.removeTag(this.$h, t); }
    get behaviour() { return N.behaviour(this.$h); }
    send(method, ...args) {
      const b = N.behaviour(this.$h);
      if (b && typeof b[method] === "function") return b[method](...args);
      return undefined;
    }
    bounds() { const b = N.bounds(this.$h); return b === null ? null : new Rect(b[0], b[1], b[2], b[3]); }
    isGrounded(tolerance) { return N.isGrounded(this.$h, tolerance === undefined ? -1 : tolerance); }
    isTouching(direction, tolerance) { const d = vecArr(direction, 3, "entity.isTouching(direction)"); return N.isTouching(this.$h, d[0], d[1], d[2], tolerance === undefined ? (N.hasComp(this.$h, "RigidBody3D") || N.hasComp(this.$h, "Collider3D") ? 0.05 : 2) : tolerance); }
    emitBurst(count = 10) { N.particlesBurst(this.$h, count); }
    get animator() {
      if (!N.hasComp(this.$h, "Animator"))
        throw new Error(`entity '${this.id}' has no Animator component; add one next to a MeshRenderer with a skinned glTF: entity.add("Animator", {clip: "Idle"})`);
      return new AnimatorApi(this.$h);
    }
    toJSON() { return N.entityJson(this.$h, true, false); }
    toString() { return `Entity(${this.id})`; }
  }

  // ===================================================================================================== animator
  // entity.animator: skeletal animation of a skinned glTF. The Animator component (scene JSON) holds the state; the
  // engine advances it in the fixed step. Everything here is a thin wrapper over that component.
  class AnimatorApi {
    constructor(h) { this.$h = h; }
    get component() { return viewOf(this.$h, typeOf("Animator")); }
    play(clip, fadeSeconds = this.component.fade) { N.animCall(this.$h, "play", String(clip), fadeSeconds); }
    stop() { N.animCall(this.$h, "stop"); }
    set(name, value) { N.animCall(this.$h, "set", String(name), value); }
    get(name) {
      const c = this.component, v = c.values;
      if (name in v) return v[name];
      const p = c.params;
      if (name in p) return p[name];
      throw new Error(`the Animator has no parameter '${name}'${closest(name, Object.keys(p)) ? `; did you mean '${closest(name, Object.keys(p))}'?` : "; declare it in the Animator's params"}`);
    }
    trigger(name) { N.animCall(this.$h, "trigger", String(name)); }
    get clips() { return N.animCall(this.$h, "clips").map((c) => c.name); }
    duration(clip) {
      const c = N.animCall(this.$h, "clips").find((x) => x.name === clip);
      if (!c) throw new Error(`no animation clip '${clip}'; the model has: ${this.clips.join(", ") || "(none)"}${closest(clip, this.clips) ? `. Did you mean '${closest(clip, this.clips)}'?` : ""}`);
      return c.duration;
    }
    on(name, fn) {
      const id = N.idOf(this.$h);
      return addListener(name, (data, source) => { if (data && data.id === id) fn(data, source); }, null);
    }
    get state() { return this.component.state; }
    get clip() { return this.component.clip; }
    set clip(v) { this.component.clip = v; }
    get time() { return this.component.time; }
    set time(v) { this.component.time = v; }
    get speed() { return this.component.speed; }
    set speed(v) { this.component.speed = v; }
    get loop() { return this.component.loop; }
    set loop(v) { this.component.loop = v; }
    get playing() { return this.component.playing; }
    set playing(v) { this.component.playing = v; }
  }

  // ========================================================================================================= tween
  // tween(target, props, options): moves numbers, vectors and colors of any object (a component view, a vector, a plain
  // object) to new values over time, driven by the game clock (the fixed step and time.scale, never the wall clock).
  const bounceOut = (t) => {
    const n1 = 7.5625, d1 = 2.75;
    if (t < 1 / d1) return n1 * t * t;
    if (t < 2 / d1) return n1 * (t -= 1.5 / d1) * t + 0.75;
    if (t < 2.5 / d1) return n1 * (t -= 2.25 / d1) * t + 0.9375;
    return n1 * (t -= 2.625 / d1) * t + 0.984375;
  };
  const EASE_IN = {
    quad: (t) => t * t, cubic: (t) => t * t * t, quart: (t) => t * t * t * t, quint: (t) => t * t * t * t * t,
    sine: (t) => 1 - Math.cos(t * Math.PI / 2),
    expo: (t) => (t === 0 ? 0 : Math.pow(2, 10 * t - 10)),
    circ: (t) => 1 - Math.sqrt(1 - t * t),
    back: (t) => { const c1 = 1.70158; return (c1 + 1) * t * t * t - c1 * t * t; },
    elastic: (t) => (t === 0 ? 0 : t === 1 ? 1 : -Math.pow(2, 10 * t - 10) * Math.sin((t * 10 - 10.75) * (2 * Math.PI / 3))),
    bounce: (t) => 1 - bounceOut(1 - t),
  };
  const ease = { linear: (t) => t };
  for (const [name, f] of Object.entries(EASE_IN)) {
    ease[name + "In"] = f;
    ease[name + "Out"] = (t) => 1 - f(1 - t);
    ease[name + "InOut"] = (t) => (t < 0.5 ? f(2 * t) / 2 : 1 - f(2 - 2 * t) / 2);
  }
  const CHANNELS = ["x", "y", "z", "w", "r", "g", "b", "a"];

  const tweens = { list: [], cancelAll() { for (const t of this.list.slice()) t.cancel(); this.list = []; } };

  class Tween {
    constructor(target, props, o) {
      this.target = target; this.props = props; this.o = o;
      this.elapsed = 0; this.started = false; this.paused = false; this.done = false; this.cancelled = false;
      this.parts = []; this.nexts = [];
      this.finished = new Promise((res) => { this.$resolve = res; });
    }
    get active() { return !this.done && !this.cancelled; }
    get progress() { const d = this.o.duration * (this.o.repeat + 1); return d > 0 ? Math.min(1, Math.max(0, (this.elapsed - this.o.delay) / d)) : (this.done ? 1 : 0); }
    pause() { this.paused = true; return this; }
    resume() { this.paused = false; return this; }
    cancel() {
      if (this.done || this.cancelled) return this;
      this.cancelled = true;
      const i = tweens.list.indexOf(this); if (i >= 0) tweens.list.splice(i, 1);
      this.$resolve(false);
      for (const n of this.nexts) n.cancel();
      return this;
    }
    onComplete(fn) { this.o.onComplete = ((prev) => () => { if (prev) prev(this); fn(this); })(this.o.onComplete); return this; }
    next(target, props, options) {
      const t = makeTween(target, props, options);
      if (this.cancelled) { t.cancelled = true; t.$resolve(false); return t; }
      if (this.done) tweens.list.push(t); else this.nexts.push(t);
      return t;
    }
    $begin() {
      this.started = true;
      if (typeof this.target === "number") {
        this.from = this.o.from !== undefined ? this.o.from : this.target;
      } else {
        const t = this.target;
        for (const k of Object.keys(this.props)) {
          const end = this.props[k], cur = t[k];
          if (typeof end === "number" && typeof cur === "number") { this.parts.push({ k, num: true, a: this.o.from && k in this.o.from ? this.o.from[k] : cur, b: end }); continue; }
          if (cur === undefined || cur === null || typeof cur !== "object")
            throw new Error(`tween: the target has no numeric property '${k}'${isObj(t) && closest(k, Object.keys(t)) ? `; did you mean '${closest(k, Object.keys(t))}'?` : ""}. Vectors and colors can be tweened too: tween(sprite, { color: "#ff0000" }).`);
          const keys = CHANNELS.filter((c) => typeof cur[c] === "number");
          const e = typeof end === "string" ? parseColor(end) : end;
          const from = isObj(this.o.from) ? this.o.from[k] : undefined;
          const fv = from === undefined ? null : (typeof from === "string" ? parseColor(from) : from);
          const a = [], b = [];
          keys.forEach((c, i) => {
            const pick = (v, d) => (v === null || v === undefined ? d : Array.isArray(v) ? (v[i] ?? d) : (typeof v[c] === "number" ? v[c] : d));
            a.push(pick(fv, cur[c])); b.push(pick(e, cur[c]));
          });
          this.parts.push({ k, num: false, cur, keys, a, b });
        }
      }
      if (this.o.onStart) this.o.onStart(this);
    }
    $apply(f) {
      if (typeof this.target === "number") {
        const v = this.from + (this.props - this.from) * f;
        if (this.o.onUpdate) this.o.onUpdate(v, this);
        return;
      }
      for (const p of this.parts) {
        if (p.num) this.target[p.k] = p.a + (p.b - p.a) * f;
        else p.keys.forEach((c, i) => { p.cur[c] = p.a[i] + (p.b[i] - p.a[i]) * f; });
      }
      if (this.o.onUpdate) this.o.onUpdate(f, this);
    }
    $tick(dt) {
      if (this.paused) return;
      this.elapsed += dt;
      const o = this.o;
      const local = this.elapsed - o.delay;
      if (local < 0) return;
      if (!this.started) this.$begin();
      const total = o.duration * (o.repeat + 1);
      let p, cycle = 0, end = false;
      if (o.duration <= 0 || local >= total) { end = true; cycle = Number.isFinite(o.repeat) ? o.repeat : 0; p = 1; }
      else { cycle = Math.floor(local / o.duration); p = (local - cycle * o.duration) / o.duration; }
      if (o.yoyo && cycle % 2 === 1) p = 1 - p;
      this.$apply(p <= 0 ? 0 : p >= 1 ? 1 : o.ease(p));
      if (end) {
        this.done = true;
        const i = tweens.list.indexOf(this); if (i >= 0) tweens.list.splice(i, 1);
        if (o.onComplete) o.onComplete(this);
        this.$resolve(true);
        for (const n of this.nexts) tweens.list.push(n);
      }
    }
  }

  function makeTween(target, props, options) {
    const o = Object.assign({ duration: 1, delay: 0, ease: "linear", repeat: 0, yoyo: false }, options || {});
    if (typeof target === "number") {
      if (typeof props !== "number") throw new Error("tween(from, to, { onUpdate }): both values must be numbers, e.g. tween(0, 100, { duration: 2, onUpdate: (v) => label.text = String(v) })");
      if (typeof o.onUpdate !== "function") throw new Error("tween(from, to, options) needs options.onUpdate(value) to receive the value");
    } else if (!isObj(target) || !isObj(props)) {
      throw new Error(`tween(target, props, options) expects an object to move and an object of end values, e.g. tween(entity.position, { y: 5 }, { duration: 1 }), but got ${inspect(target)}`);
    }
    if (typeof o.ease === "string") {
      if (!ease[o.ease]) throw new Error(`tween: unknown ease '${o.ease}'${closest(o.ease, Object.keys(ease)) ? `; did you mean '${closest(o.ease, Object.keys(ease))}'?` : ""} Names: ${Object.keys(ease).join(", ")}`);
      o.ease = ease[o.ease];
    } else if (typeof o.ease !== "function") throw new Error("tween: options.ease is a name like \"quadOut\" or a function (t) => t");
    for (const k of ["duration", "delay"]) if (!(o[k] >= 0)) throw new Error(`tween: options.${k} must be a number of seconds >= 0 but is ${inspect(o[k])}`);
    if (!(o.repeat >= 0)) throw new Error("tween: options.repeat is the number of EXTRA plays (0 = once, Infinity = forever)");
    return new Tween(target, props, o);
  }

  function tween(target, props, options) {
    const t = makeTween(target, props, options);
    tweens.list.push(t);
    return t;
  }
  function tickTweens(dt) {
    if (tweens.list.length === 0) return;
    for (const t of tweens.list.slice()) {
      if (!t.active) continue;
      N.guardBegin("tween", 2.0);
      try { t.$tick(dt); } catch (e) {
        t.cancel();
        if (!/destroyed/.test(String(e && e.message))) N.reportError(e, "", "tween update");  // a destroyed target just ends its tween
      }
      N.guardEnd();
    }
  }
  function cancelTweens(target) {
    for (const t of tweens.list.slice()) if (target === undefined || t.target === target) t.cancel();
  }

  // ======================================================================================================== timers
  const timers = {
    list: [], nextId: 1, now: 0,
    add(owner, seconds, fn, repeat) {
      if (typeof fn !== "function") throw new Error("after/every expect a function as second argument");
      if (!(seconds >= 0)) throw new Error("after/every expect a duration in seconds >= 0");
      const t = { id: this.nextId++, owner, due: this.now + seconds, interval: seconds, repeat, fn, cancelled: false };
      this.list.push(t);
      return { cancel() { t.cancelled = true; }, get active() { return !t.cancelled; } };
    },
    tick(dt) {
      this.now += dt;
      if (this.list.length === 0) return;
      const due = this.list.filter((t) => !t.cancelled && t.due <= this.now).sort((a, b) => a.due - b.due || a.id - b.id);
      for (const t of due) {
        if (t.cancelled) continue;
        let guard = 0;
        do {
          if (t.repeat) t.due += Math.max(t.interval, 1e-4); else t.cancelled = true;
          N.guardBegin("timer callback", 2.0);
          try { t.fn(); } catch (e) { N.reportError(e, t.owner === null ? "" : N.idOf(t.owner), "timer"); }
          N.guardEnd();
        } while (t.repeat && !t.cancelled && t.due <= this.now && ++guard < 100);
      }
      this.list = this.list.filter((t) => !t.cancelled);
    },
    dropOwner(owner) { for (const t of this.list) if (t.owner === owner) t.cancelled = true; },
    reset() { this.list = []; },
  };

  // ======================================================================================================== events
  const backHandlers = [];  // input.onBack
  // Called by the engine when Back was pressed (ScriptSystem::dispatch_back): true when a handler consumed it.
  function deliverBack() {
    for (const handler of backHandlers.slice().reverse()) {
      if (!backHandlers.includes(handler)) continue;  // removed by a handler that ran before
      let result;
      N.guardBegin("input.onBack handler", 2.0);
      try { result = handler.fn(); } catch (e) { N.reportError(e, "", "input.onBack"); result = true; }  // reported; not a reason to quit
      N.guardEnd();
      if (result !== false) return true;
    }
    return false;
  }
  const listeners = new Map();
  function emitToListeners(name, data, source) {
    const arr = listeners.get(name);
    if (!arr) return;
    for (const l of arr.slice()) {
      if (l.dead) continue;
      N.guardBegin(`world.on('${name}') listener`, 2.0);
      try { l.fn(data, source); } catch (e) { N.reportError(e, l.owner ? N.idOf(l.owner) : "", `world.on('${name}')`); }
      N.guardEnd();
    }
  }
  function addListener(name, fn, owner) {
    if (typeof name !== "string" || typeof fn !== "function") throw new Error("world.on(name, fn) expects an event name and a function");
    let arr = listeners.get(name);
    if (!arr) { arr = []; listeners.set(name, arr); }
    const l = { fn, owner: owner ?? null, dead: false };
    arr.push(l);
    return () => { l.dead = true; const a = listeners.get(name); if (a) { const i = a.indexOf(l); if (i >= 0) a.splice(i, 1); } };
  }

  // ===================================================================================================== Behaviour
  let binding = null;
  class Behaviour {
    constructor() {
      if (!binding) throw new Error("Behaviour instances are created by the engine from a Script component; do not call `new` on them");
      Object.defineProperty(this, "entity", { value: binding, writable: false, enumerable: false, configurable: true });
      this.enabled = true;
      this.runWhilePaused = false;  // true: onUpdate/onLateUpdate keep running (with the real dt) while time.scale is 0
    }
    get world() { return world; }
    after(seconds, fn) { return timers.add(this.entity.$h, seconds, fn, false); }
    every(seconds, fn) { return timers.add(this.entity.$h, seconds, fn, true); }
    on(name, fn) { return addListener(name, fn, this.entity.$h); }
  }

  function isBehaviourClass(c) { return typeof c === "function" && c.prototype instanceof Behaviour; }

  // The lifecycle methods the engine calls by name (script_behaviours.cpp, script_system.cpp).
  const HOOKS = ["onStart", "onEnable", "onDisable", "onUpdate", "onFixedUpdate", "onLateUpdate", "onDestroy",
    "onCollisionEnter", "onCollisionExit", "onTriggerEnter", "onTriggerExit", "onEvent"];
  // Methods that were meant to be hooks but are never called: a hook without its `on` (update, fixedUpdate, Start) or a
  // near-miss of a name that starts with `on` (onupdate, onStrat). Helpers (loadLevel, clickCell) are not near a hook.
  function checkHooks(Cls) {
    if (!isBehaviourClass(Cls)) return [];
    const out = [];
    for (const m of Object.getOwnPropertyNames(Cls.prototype)) {
      if (HOOKS.includes(m) || typeof Object.getOwnPropertyDescriptor(Cls.prototype, m).value !== "function") continue;
      const hook = HOOKS.find((h) => h.toLowerCase() === "on" + m.toLowerCase()) ||
        (/^on/i.test(m) ? closest(m, HOOKS) : "");
      if (hook) out.push(`class ${Cls.name}: method '${m}()' is not a lifecycle hook, so the engine never calls it ` +
        `(did you mean '${hook}()'?). Rename it to ${hook}, or give a helper a name that is not close to a hook.`);
    }
    return out;
  }
  const checkedHookClasses = new WeakSet();

  const warnedProps = new Set();
  function unknownProps(inst, props) {
    const out = [];
    const own = Object.keys(inst);
    for (const k of Object.keys(props || {})) {
      if (Object.prototype.hasOwnProperty.call(inst, k)) continue;
      const sug = closest(k, own);
      out.push({ key: k, text: `Script.props '${k}' is not a field of ${inst.constructor.name}` + (sug ? ` (did you mean '${sug}'?)` : "") +
        `. Declare it as a class field: ${k} = <default>;` });
    }
    return out;
  }
  function instantiate(Cls, h, props, entityId, path) {
    if (!checkedHookClasses.has(Cls)) {  // once per class (a hot reload is a new class)
      checkedHookClasses.add(Cls);
      for (const t of checkHooks(Cls)) N.log(3, `${path}: ${t}`);
    }
    binding = entityOf(h);
    let inst;
    try { inst = new Cls(); } finally { binding = null; }
    const bad = unknownProps(inst, props);
    if (bad.length) {
      const key = `${path}|${bad.map((b) => b.key).join(",")}`;
      if (!warnedProps.has(key)) {
        warnedProps.add(key);
        N.log(3, `entity '${entityId}' (${path}): ` + bad.map((b) => b.text).join(" "));
      }
    }
    for (const k of Object.keys(props || {})) {
      let v = props[k];
      if (Object.prototype.hasOwnProperty.call(inst, k)) {
        const cur = inst[k];
        if (cur instanceof Vec2 && (Array.isArray(v) || isObj(v))) v = vec2(v);
        else if (cur instanceof Vec3 && (Array.isArray(v) || isObj(v))) v = vec3(v);
        else if (cur instanceof Color && (Array.isArray(v) || isObj(v) || typeof v === "string")) v = color(v);
      }
      inst[k] = v;
    }
    return inst;
  }
  // Side-effect free check used by `factoria validate`: constructs a throw-away instance.
  function checkProps(Cls, props, path) {
    if (!isBehaviourClass(Cls)) return [`${path}: the default export must extend Behaviour`];
    const dummy = new Entity(-2);
    binding = dummy;
    let inst;
    try { inst = new Cls(); } catch (e) { return [`${path}: the constructor threw while checking props: ${e && e.message}`]; }
    finally { binding = null; timers.dropOwner(-2); }
    return unknownProps(inst, props).map((b) => `${path}: ${b.text}`);
  }

  function makeInfo(is2d, px, py, pz, nx, ny, nz, impulse) {
    return is2d ? { point: new Vec2(px, py), normal: new Vec2(nx, ny), impulse }
                : { point: new Vec3(px, py, pz), normal: new Vec3(nx, ny, nz), impulse };
  }

  // ========================================================================================================= modules
  const world = {
    find(idOrName) { return entityOf(N.find(String(idOrName))); },
    findAll(name) { return N.findAll(name).map(entityOf); },
    findByTag(tag) { return N.findByTag(tag).map(entityOf); },
    entities() { return N.entities().map(entityOf); },
    spawn(entityJson, opts = {}) {
      const parent = opts && opts.parent ? entityHandle(opts.parent, "world.spawn parent") : null;
      const j = applySpawnOptions(entityPlain(entityJson), opts || {}, "world.spawn");
      return entityOf(N.spawn(j, parent));
    },
    spawnPrefab(path, opts = {}) {
      const ov = applySpawnOptions(opts.overrides ? entityPlain(opts.overrides) : {}, opts, "world.spawnPrefab");
      const parent = opts.parent ? entityHandle(opts.parent, "world.spawnPrefab parent") : null;
      return entityOf(N.spawnPrefab(path, parent, ov));
    },
    emit(name, data, source) { N.emit(name, data === undefined ? null : plain(data), source instanceof Entity ? source.$h : null); },
    on(name, fn) { return addListener(name, fn, null); },
    get settings() { return viewOf(-1, SETTINGS); },
    get time() { return N.timeInfo()[2]; },
    get frame() { return N.timeInfo()[3]; },
  };

  const KEY_DOC = null;
  const input = {
    down: (a) => N.inAction(0, a), pressed: (a) => N.inAction(1, a), released: (a) => N.inAction(2, a),
    // value(action): 0..1, analog for gamepad sticks and triggers (the action is "down" from 0.5). axis() and vector() are analog too.
    value: (a) => N.inValue(a),
    axis: (neg, pos) => N.inAxis(neg, pos),
    vector(l, r, d, u) { const v = N.inVector(l, r, d, u); return new Vec2(v[0], v[1]); },
    // gamepad(index = 0): one pad (0..3) for local multiplayer. axis() has the deadzone applied (what the bindings see),
    // rawAxis() is as the device reported it. Names: see GamepadButton / GamepadAxis in the typings.
    gamepad(index = 0) {
      N.inPad(0, index, "");  // validates the index
      return {
        get connected() { return N.inPad(0, index, ""); },
        // "xbox" | "playstation" | "nintendo" | "steamdeck" | "generic": the family of a connected pad, from its vendor id and name.
        get type() { return N.inPadType(index); },
        down: (b) => N.inPad(1, index, b), pressed: (b) => N.inPad(2, index, b), released: (b) => N.inPad(3, index, b),
        axis: (a) => N.inPad(4, index, a), rawAxis: (a) => N.inPad(5, index, a),
      };
    },
    // ---- settings an options menu needs (M10): text, rebinding, last input, button names, cursor, on-screen keyboard
    // Characters typed this frame (UTF-8), from the keyboard or the on-screen keyboard.
    get text() { return N.inText(); },
    showKeyboard(on = true) { N.inCursor(2, !!on); },
    get keyboardShown() { return N.inCursor(2); },
    // The system Back button or gesture (Android). Handlers run newest first at the start of the frame; the first one that
    // does not return false consumes the press. When none does (or there is none), the game quits, as Back always did.
    // Handlers end with the scene, like ui.on. Returns the function that removes the handler.
    onBack(fn) {
      if (typeof fn !== "function")
        throw new Error(`input.onBack(fn) expects a function, e.g. input.onBack(() => { if (menu.open) { menu.close(); return true; } return false; }), but got ${inspect(fn)}`);
      const handler = { fn };
      backHandlers.push(handler);
      return () => { const i = backHandlers.indexOf(handler); if (i >= 0) backHandlers.splice(i, 1); };
    },
    // One pulse of the vibration motor of a phone (iOS: a haptic tap for short ones, the system vibration for long ones).
    // A no-op on desktop; a headless run or test records it (game.vibrations()).
    vibrate(seconds = 0.1) {
      if (typeof seconds !== "number" || !(seconds > 0) || seconds > 5)
        throw new Error(`input.vibrate(seconds) expects a number above 0 and up to 5, e.g. input.vibrate(0.05) for a tap, but got ${inspect(seconds)}`);
      N.inVibrate(seconds);
    },
    // Rebinding. rebind() replaces an action's bindings and validates the names (an unknown action or binding throws with
    // a suggestion); resetBindings() goes back to factoria.json (one action, or all of them).
    actions: () => N.inActions(),
    bindings: (action) => N.inBindings(action),
    rebind(action, bindings) { N.inRebind(action, bindings); },
    resetBindings(action) { N.inResetBindings(action); },
    // The binding that went down this frame ("Space", "MouseLeft", "GamepadA"...) or null: for "press a key" screens.
    lastPressed: () => N.inLastPressed(),
    get lastDevice() { return N.inLastDevice(); },
    // The label a player sees for a binding or an action: "Space", "Cross" (PlayStation A), "ZL"...
    buttonName: (bindingOrAction, pad = 0) => N.inButtonName(bindingOrAction, pad),
    // Deadzone of sticks (radial) and triggers, from factoria.json input.deadzone (default 0.2). Assign to offer calibration.
    get deadzone() { return N.inDeadzone(); },
    set deadzone(v) { N.inDeadzone(v); },
    keyDown: (k) => N.inKey(0, k), keyPressed: (k) => N.inKey(1, k), keyReleased: (k) => N.inKey(2, k),
    mouse: {
      get position() { const m = N.inMouse().position; return new Vec2(m[0], m[1]); },
      get world() { return camera.screenToWorld(this.position); },
      get delta() { const m = N.inMouse().delta; return new Vec2(m[0], m[1]); },
      get wheel() { return N.inMouse().wheel; },
      down: (b = "left") => N.inMouseButton(0, b), pressed: (b = "left") => N.inMouseButton(1, b), released: (b = "left") => N.inMouseButton(2, b),
      // Cursor visibility (default true) and lock (hidden, held in the window, delta reports raw movement). A headless run
      // only records them.
      get visible() { return N.inCursor(0); },
      set visible(v) { N.inCursor(0, !!v); },
      get locked() { return N.inCursor(1); },
      set locked(v) { N.inCursor(1, !!v); },
    },
    get touches() {
      return N.inTouches().map((t) => {
        const position = new Vec2(t.position[0], t.position[1]);
        return { id: t.id, position, world: camera.screenToWorld(position), pressed: t.pressed };
      });
    },
  };

  // ---- window (M10): full screen, size, vsync and frame cap for options menus. Getters work everywhere (a run without a
  // window answers from factoria.json); every setter throws a teaching Error when there is no window (headless, tests).
  const winSet = (fn, kind, a, b) => {
    const err = N.windowSet(kind, a, b);
    if (err) throw new Error(`window.${fn}: ${err}`);
  };
  const needBool = (fn, v) => {
    if (typeof v !== "boolean") throw new Error(`window.${fn}(on) expects true or false, e.g. window.${fn}(true), but got ${inspect(v)}`);
  };
  const windowApi = {
    get available() { return N.windowInfo().available; },
    get fullscreen() { return N.windowInfo().fullscreen; },
    setFullscreen(on) { needBool("setFullscreen", on); winSet("setFullscreen", 0, on); },
    get size() { const w = N.windowInfo(); return new Vec2(w.width, w.height); },
    get displaySize() { const w = N.windowInfo(); return new Vec2(w.displayWidth, w.displayHeight); },
    setSize(width, height) {
      const ok = (v) => Number.isInteger(v) && v >= 160 && v <= 16384;
      if (!ok(width) || !ok(height)) {
        throw new Error(`window.setSize(width, height) expects whole numbers of pixels from 160 to 16384, e.g. window.setSize(1280, 720), but got ${inspect(width)} and ${inspect(height)}`);
      }
      winSet("setSize", 1, width, height);
    },
    // Common 16:9 and 16:10 sizes, plus the game's design size, that fit the monitor: [{ width, height }], smallest first.
    resolutions() {
      const w = N.windowInfo(), d = N.project().display || {};
      const all = [[640, 360], [960, 540], [1280, 720], [1600, 900], [1920, 1080], [2560, 1440], [3840, 2160],
                   [1280, 800], [1440, 900], [1680, 1050], [1920, 1200], [2560, 1600]];
      if (d.width > 0 && d.height > 0 && !all.some(([x, y]) => x === d.width && y === d.height)) all.push([d.width, d.height]);
      return all.filter(([x, y]) => x <= w.displayWidth && y <= w.displayHeight)
        .sort((a, b) => a[0] * a[1] - b[0] * b[1] || a[0] - b[0]).map(([width, height]) => ({ width, height }));
    },
    get vsync() { return N.windowInfo().vsync; },
    setVsync(on) { needBool("setVsync", on); winSet("setVsync", 2, on); },
    get frameCap() { return N.windowInfo().frameCap; },
    set frameCap(fps) {
      if (!Number.isInteger(fps) || (fps !== 0 && (fps < 15 || fps > 1000))) {
        throw new Error(`window.frameCap expects 0 (unlimited) or a whole number of frames per second from 15 to 1000, e.g. window.frameCap = 60, but got ${inspect(fps)}`);
      }
      winSet("frameCap", 3, fps);
    },
  };

  const audio = {
    // play(path, { volume, pitch, pan, loop, bus, caption, captionKey, speaker, captionSeconds }) -> voice id. A caption (plain
    // text, or a localization key that follows a language change) shows on the Captions component while the sound plays and goes
    // when it ends or is stopped; `speaker` is a name shown before the line; `captionSeconds` shows it for that long instead.
    // A looping sound never ends, so with `loop` a caption needs captionSeconds.
    play(path, o = {}) {
      if (o === null || typeof o !== "object") throw new Error(`audio.play(path, options): the second argument is an options object such as { volume: 0.5, caption: "Hello" }, but got ${inspect(o)}`);
      for (const k of ["caption", "captionKey", "speaker"])
        if (o[k] !== undefined && typeof o[k] !== "string") throw new Error(`audio.play(path, { ${k} }): ${k} must be a string, e.g. { caption: "Hello there.", captionKey: "intro.line1", speaker: "Mara" }, but got ${inspect(o[k])}`);
      if (o.captionSeconds !== undefined && !(typeof o.captionSeconds === "number" && o.captionSeconds > 0))
        throw new Error(`audio.play(path, { captionSeconds }): captionSeconds must be a number of seconds above 0, e.g. { captionSeconds: 4 }, but got ${inspect(o.captionSeconds)}`);
      const hasCaption = !!(o.caption || o.captionKey);
      if (!hasCaption && (o.speaker !== undefined || o.captionSeconds !== undefined))
        throw new Error(`audio.play(path, { ${o.speaker !== undefined ? "speaker" : "captionSeconds"} }) has no caption to apply it to: add caption: "text" or captionKey: "your.key" (a localization key, docs/TEXT.md, "Captions")`);
      if (hasCaption && o.loop && o.captionSeconds === undefined)
        throw new Error(`audio.play(${inspect(path)}, { loop: true, caption }): a looping sound never ends, so its caption would never go. Add captionSeconds: 5 (how long it shows), or play the sound without a caption`);
      return N.audioPlay(path, o.volume ?? 1, o.pitch ?? 1, o.pan ?? 0, !!o.loop, o.bus ?? "", o.caption ?? "", o.captionKey ?? "", o.speaker ?? "", o.captionSeconds ?? 0);
    },
    stop: (id) => N.audioStop(id), stopAll: () => N.audioStopAll(),
    music(path, o = {}) { N.audioMusic(path, o.volume ?? 0.6, o.fade ?? 0.5); },
    stopMusic: (fade = 0.5) => N.audioStopMusic(fade),
    setVolume: (bus, v) => N.audioVolume(bus, v),
    getVolume: (bus) => N.audioGetVolume(bus),
  };

  const maskOf = (o) => (o && typeof o.mask === "number" ? o.mask : -1);
  const ignoreOf = (o) => (o && o.ignore !== undefined && o.ignore !== null ? entityHandle(o.ignore, "physics option `ignore`") : null);
  const trigOf = (o) => !(o && o.ignoreTriggers === false);
  function hitOf(r, is2d) {
    if (!r) return null;
    const p = r.point, n = r.normal;
    return { entity: entityOf(r.entity), point: is2d ? new Vec2(p[0], p[1]) : new Vec3(p[0], p[1], p[2]),
             normal: is2d ? new Vec2(n[0], n[1]) : new Vec3(n[0], n[1], n[2]), distance: r.distance };
  }
  const is3dVec = (v) => (Array.isArray(v) ? v.length >= 3 : isObj(v) && v.z !== undefined && !(v instanceof Vec2));
  const physics = {
    // raycast(from, to, { mask, ignore, ignoreTriggers }): 2D when `from` is 2D, else 3D. Pass { ignore: this.entity }
    // when casting from a behaviour so the ray does not hit its own collider.
    raycast(from, to, o) {
      const is3d = is3dVec(from);
      if (!is3d) {
        const a = vecArr(from, 2, "physics.raycast(from, to) `from`"), b = vecArr(to, 2, "physics.raycast(from, to) `to`");
        return hitOf(N.raycast2d(a[0], a[1], b[0], b[1], maskOf(o), ignoreOf(o), trigOf(o)), true);
      }
      const a = vecArr(from, 3, "physics.raycast(from, to) `from`"), b = vecArr(to, 3, "physics.raycast(from, to) `to`");
      const d = [b[0] - a[0], b[1] - a[1], b[2] - a[2]];
      const len = Math.hypot(d[0], d[1], d[2]);
      if (len < 1e-6) return null;
      return hitOf(N.raycast3d(a[0], a[1], a[2], d[0] / len, d[1] / len, d[2] / len, len, maskOf(o), ignoreOf(o), trigOf(o)), false);
    },
    raycast3d(origin, dir, maxDistance = 1000, o) {
      const a = vecArr(origin, 3, "physics.raycast3d(origin, dir) `origin`"), d = vecArr(dir, 3, "physics.raycast3d(origin, dir) `dir`");
      return hitOf(N.raycast3d(a[0], a[1], a[2], d[0], d[1], d[2], maxDistance, maskOf(o), ignoreOf(o), trigOf(o)), false);
    },
    // shapeCast(shape, from, to, { mask, ignore, ignoreTriggers }): sweeps a shape from `from` to `to` (2D when `from` is 2D, else 3D)
    // and returns the first collider it touches like raycast does ({ entity, point, normal, distance } | null). distance = how far the
    // CENTRE travels before contact. shape: { shape: "circle", radius } or { shape: "box", size: [w, h] } in 2D;
    // { shape: "sphere", radius } or { shape: "box", size: [x, y, z] } in 3D. Bad shapes throw an Error that explains the fix.
    shapeCast(shape, from, to, o) {
      if (!is3dVec(from)) {
        const a = vecArr(from, 2, "physics.shapeCast(shape, from, to) `from`"), b = vecArr(to, 2, "physics.shapeCast(shape, from, to) `to`");
        return hitOf(N.shapeCast2d(shape, a[0], a[1], b[0], b[1], maskOf(o), ignoreOf(o), trigOf(o)), true);
      }
      const a = vecArr(from, 3, "physics.shapeCast(shape, from, to) `from`"), b = vecArr(to, 3, "physics.shapeCast(shape, from, to) `to`");
      return hitOf(N.shapeCast3d(shape, a[0], a[1], a[2], b[0], b[1], b[2], maskOf(o), ignoreOf(o), trigOf(o)), false);
    },
    overlapCircle(c, r, o) { const v = vecArr(c, 2, "physics.overlapCircle(center, r) `center`"); return N.overlapCircle(v[0], v[1], r, maskOf(o)).map(entityOf); },
    overlapBox(r, o) { const q = rectArr(r, "physics.overlapBox(rect)"); return N.overlapBox(q[0], q[1], q[2], q[3], maskOf(o)).map(entityOf); },
    overlapSphere(c, r, o) { const v = vecArr(c, 3, "physics.overlapSphere(center, r) `center`"); return N.overlapSphere(v[0], v[1], v[2], r, maskOf(o)).map(entityOf); },
    applyImpulse(e, v) { const a = vecArr(v, 3, "physics.applyImpulse(entity, v)"); N.physicsApply(0, entityHandle(e, "applyImpulse"), a[0], a[1], a[2]); },
    applyForce(e, v) { const a = vecArr(v, 3, "physics.applyForce(entity, v)"); N.physicsApply(1, entityHandle(e, "applyForce"), a[0], a[1], a[2]); },
    setVelocity(e, v) { const a = vecArr(v, 3, "physics.setVelocity(entity, v)"); N.physicsApply(2, entityHandle(e, "setVelocity"), a[0], a[1], a[2]); },
    // moveCharacter(entity, delta): moves an entity that has a CharacterController3D by `delta` (metres, this frame's walk plus
    // your own gravity/jump) with collide-and-slide, step climbing and ground snapping. Returns the result of the move.
    moveCharacter(e, delta) {
      const d = vecArr(delta, 3, "physics.moveCharacter(entity, delta) `delta`");
      const r = N.moveCharacter(entityHandle(e, "moveCharacter"), d[0], d[1], d[2]);
      return { position: new Vec3(r.position[0], r.position[1], r.position[2]), moved: new Vec3(r.moved[0], r.moved[1], r.moved[2]),
               isGrounded: r.isGrounded, groundNormal: new Vec3(r.groundNormal[0], r.groundNormal[1], r.groundNormal[2]),
               ground: entityOf(r.ground), hitWall: r.hitWall, hitCeiling: r.hitCeiling };
    },
  };

  let pausedScale = null; // time.scale to restore on game.paused = false, null when not paused through game.paused
  const time = {
    get dt() { return N.timeInfo()[0]; },
    get fixedDt() { return N.timeInfo()[1]; },
    get elapsed() { return N.timeInfo()[2]; },
    get frame() { return N.timeInfo()[3]; },
    get scale() { return N.timeInfo()[4]; },
    set scale(v) {
      if (pausedScale !== null && v > 0) pausedScale = v; // paused: the new scale is what game.paused = false restores
      else { pausedScale = null; N.setTimeScale(v); }
    },
    get unscaledDt() { return N.timeInfo()[5]; },
  };

  const camera = {
    get main() { return entityOf(N.cameraMain()); },
    worldToScreen(v) { const a = vecArr(v, 3, "camera.worldToScreen(v)"); const s = N.worldToScreen(a[0], a[1], a[2]); return new Vec2(s[0], s[1]); },
    screenToWorld(v, depth = 0) { const a = vecArr(v, 2, "camera.screenToWorld(v)"); const w = N.screenToWorld(a[0], a[1], depth); return new Vec3(w[0], w[1], w[2]); },
  };

  const colorArg = (c) => (c === undefined ? [1, 1, 1, 1] : toFloats(c, "color", "debug color"));
  const debug = {
    line(a, b, c) { const p = vecArr(a, 3, "debug.line(a, b) `a`"), q = vecArr(b, 3, "debug.line(a, b) `b`"); N.debugDraw(0, p[0], p[1], p[2], q[0], q[1], q[2], colorArg(c)); },
    // rect(x, y, w, h, color) or rect({x, y, w, h}, color)
    rect(x, y, w, h, c) {
      if (isObj(x)) { const q = rectArr(x, "debug.rect(rect)"); N.debugDraw(1, q[0], q[1], q[2], q[3], colorArg(y), false); }
      else N.debugDraw(1, x, y, w, h, colorArg(c), false);
    },
    circle(center, r, c) { const p = vecArr(center, 2, "debug.circle(center, r) `center`"); N.debugDraw(2, p[0], p[1], r, colorArg(c), false); },
    text(pos, str, c) { const p = vecArr(pos, 2, "debug.text(pos, str) `pos`"); N.debugDraw(3, p[0], p[1], String(str), colorArg(c)); },
    box(center, size, c) { const p = vecArr(center, 3, "debug.box(center, size) `center`"), q = vecArr(size, 3, "debug.box(center, size) `size`", 1); N.debugDraw(4, p[0], p[1], p[2], q[0], q[1], q[2], colorArg(c)); },
    sphere(center, r, c) { const p = vecArr(center, 3, "debug.sphere(center, r) `center`"); N.debugDraw(5, p[0], p[1], p[2], r, colorArg(c)); },
  };

  // scene.preload / assets.preload: a handle for a job the engine advances a little every frame (script_system.cpp
  // dispatch_platform -> preloadDeliver). The numbers only change between frames, so a script sees the same values in a test
  // on any machine.
  const preloadJobs = new Map();  // job id -> handle state
  class Preload {
    constructor(id, label) {
      this.$id = id;
      this.$label = label;
      this.$progress = 0; this.$done = false; this.$files = 0; this.$bytes = 0; this.$error = "";
      this.promise = new Promise((resolve, reject) => { this.$resolve = resolve; this.$reject = reject; });
      this.promise.catch(() => {});  // a script that only polls `done` is not reported for a failure it can read in `error`
    }
    /** How much of the work is done, 0..1. Grows by whole files; 1 when `done`. */
    get progress() { return this.$progress; }
    /** True once everything is read (or the job failed: see `error`). */
    get done() { return this.$done; }
    /** Files read so far (the scene counts as one). */
    get files() { return this.$files; }
    /** Bytes read so far. */
    get bytes() { return this.$bytes; }
    /** Why the job failed, or "". */
    get error() { return this.$error; }
    /** Gives the files that nobody has read yet back (and stops a job that is still running; its Promise rejects). */
    release() {
      N.preloadRelease(this.$id);
      preloadJobs.delete(this.$id);
      if (!this.$done) { this.$done = true; this.$error = "released before it finished"; this.$reject(new Error(`${this.$label}: ${this.$error}`)); }
    }
  }
  function preloadStart(kind, arg, label) {
    const r = N.preloadStart(kind, arg);
    if (r.mistake) {
      const e = new Error(r.mistake.message);
      e.hint = r.mistake.hint || "";
      throw e;
    }
    const h = new Preload(r.id, label);
    preloadJobs.set(r.id, h);
    return h;
  }
  function preloadDeliver(updates) {
    for (const u of updates) {
      const h = preloadJobs.get(u.id);
      if (!h) continue;
      h.$progress = u.total > 0 ? Math.min(1, u.done / u.total) : 1;
      h.$files = u.done; h.$bytes = u.bytes;
      if (!u.finished) continue;
      preloadJobs.delete(u.id);
      h.$done = true;
      if (u.error) {
        h.$error = u.error;
        const e = new Error(`${h.$label} failed: ${u.error}` + (u.hint ? ` (hint: ${u.hint})` : ""));
        e.hint = u.hint || "";
        h.$reject(e);
      } else {
        h.$progress = 1;
        h.$resolve({ files: h.$files, bytes: h.$bytes });
      }
    }
  }
  function preloadReset() { preloadJobs.clear(); }

  const scene = {
    preload(path) {
      if (typeof path !== "string" || path === "") throw new Error(`scene.preload(path) expects a scene path such as "scenes/level1.scene.json", got ${inspect(path)}`);
      return preloadStart(0, path, `scene.preload(${JSON.stringify(path)})`);
    },
    load(path) { N.requestScene(path); },
    reload() { N.requestScene(""); },
    get current() { return N.scenePath(); },
  };

  const APP_EVENTS = ["suspend", "resume", "focus", "blur"];
  const game = {
    quit() { N.quit(); },
    get paused() { return N.timeInfo()[4] === 0; },
    set paused(v) {
      const s = N.timeInfo()[4];
      if (v) { if (s > 0) pausedScale = s; N.setTimeScale(0); }
      else { N.setTimeScale(s === 0 ? (pausedScale || 1) : s); pausedScale = null; }
    },
    get project() { return Object.freeze(N.project()); },
    // The calendar date: { year, month, day, weekday (0 = Sunday), utcOffsetMinutes, iso: "YYYY-MM-DD" }. The player's real local
    // date in a game with a window; a fixed date (2026-01-01, or --date) in tests and headless runs; the recorded one in a replay.
    today() {
      const t = N.today();
      const pad = (n, w) => String(n).padStart(w, "0");
      return Object.freeze({ year: t[0], month: t[1], day: t[2], weekday: t[3], utcOffsetMinutes: t[4], iso: `${pad(t[0], 4)}-${pad(t[1], 2)}-${pad(t[2], 2)}` });
    },
    // True while the game's window has the focus (always true on a phone that is in the foreground).
    get focused() { return N.appState()[0]; },
    // on(event, fn): "suspend" (the app goes to the background), "resume" (comes back), "focus" and "blur" (the window gains or
    // loses the keyboard focus). fn gets no arguments. Returns the function that stops listening; listeners end with the scene,
    // like world.on. With factoria.json "pauseOnSuspend" (default true) the engine freezes the game and the music after the
    // "suspend" handlers ran (unless a handler paused it already) and unfreezes it before the "resume" handlers.
    on(event, fn) {
      if (!APP_EVENTS.includes(event)) {
        const sug = closest(String(event), APP_EVENTS);
        throw new Error(`game.on(event, fn): unknown event ${inspect(event)}${sug ? ` (did you mean "${sug}"?)` : ""}; use one of ${APP_EVENTS.map((n) => `"${n}"`).join(", ")}`);
      }
      if (typeof fn !== "function") throw new Error(`game.on("${event}", fn) expects a function, e.g. game.on("${event}", () => console.log("${event}")), but got ${inspect(fn)}`);
      return addListener("app." + event, () => fn(), null);
    },
    get screenSize() { const s = N.screenSize(); return new Vec2(s[0], s[1]); },
    notices() { return N.notices(); },
    get platform() { return N.platform(); },
    // The operating system's accessibility settings (read when the game starts and again when the window regains focus).
    get accessibility() {
      const a = N.accessibility();
      return Object.freeze({ textScale: a[0], reduceMotion: a[1], highContrast: a[2], screenReader: a[3] });
    },
  };

  // The screen in design pixels, origin top-left, +Y down. The safe area is what a notch, rounded corners and the system bars
  // of a phone leave (the whole screen on desktop); items with `safeArea: true` are anchored to it.
  const screen = {
    get size() { const s = N.screenSize(); return new Vec2(s[0], s[1]); },
    get insets() { const i = N.screenInsets(); return { left: i[0], top: i[1], right: i[2], bottom: i[3] }; },
    get safeArea() {
      const i = N.screenInsets(), s = N.screenSize();
      return new Rect(i[0], i[1], s[0] - i[0] - i[2], s[1] - i[1] - i[3]);
    },
  };

  const storage = {
    get(key, fallback) { const v = N.storageGet(key); return v === undefined ? fallback : v; },
    set(key, value) { N.storageSet(key, plain(value)); },
    remove(key) { N.storageRemove(key); },
    keys() { return N.storageKeys(); },
    clear() { N.storageClear(); },
    get corrupt() { return N.storageCorrupt(); },
  };

  // rng.create(seed): an independent seeded generator that never touches the world RNG (see rng in docs/SCRIPTING.md).
  // The algorithm is mulberry32 (32-bit state, one step per draw, 32-bit output / 2^32). The algorithm and the number of
  // draws each method consumes are documented as stable across engine versions, so a stored seed keeps giving the same
  // level, name or loot table: float/range/int/chance draw once per call, pick draws once (not for an empty array),
  // shuffle draws length - 1 times (Fisher-Yates from the end).
  function createRng(seed) {
    if (typeof seed !== "number" || !Number.isFinite(seed)) {
      throw new Error(`rng.create(seed) expects a finite number, e.g. rng.create(12345), but got ${inspect(seed)}`);
    }
    let state = seed >>> 0;
    const next = () => {
      state = (state + 0x6d2b79f5) >>> 0;
      let t = state;
      t = Math.imul(t ^ (t >>> 15), t | 1);
      t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
    const nums = (method, a, b) => {
      if (typeof a !== "number" || typeof b !== "number" || !Number.isFinite(a) || !Number.isFinite(b)) {
        throw new Error(`generator.${method}(min, max) expects two finite numbers, e.g. generator.${method}(1, 6), but got ${inspect(a)} and ${inspect(b)}`);
      }
    };
    return {
      float: () => next(),
      range(a, b) { nums("range", a, b); return a + (b - a) * next(); },
      int(a, b) {
        nums("int", a, b);
        const lo = Math.trunc(a), hi = Math.trunc(b);
        const r = next();  // always one draw, also for an empty range, so the sequence does not depend on the arguments
        return hi <= lo ? lo : lo + Math.floor(r * (hi - lo + 1));
      },
      chance(p = 0.5) { return next() < p; },
      pick(arr) { if (!arr || arr.length === 0) return undefined; return arr[Math.floor(next() * arr.length)]; },
      shuffle(arr) { const a = arr.slice(); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(next() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; },
      seed(n) {
        if (typeof n !== "number" || !Number.isFinite(n)) throw new Error(`generator.seed(n) expects a finite number, e.g. generator.seed(12345), but got ${inspect(n)}`);
        state = n >>> 0;
      },
    };
  }

  const rng = {
    float: () => N.rngFloat(),
    range: (a, b) => N.rngRange(a, b),
    int: (a, b) => N.rngInt(a, b),
    chance: (p = 0.5) => N.rngChance(p),
    pick(arr) { if (!arr || arr.length === 0) return undefined; return arr[N.rngInt(0, arr.length - 1)]; },
    seed(n) { if (typeof n !== "number" || !Number.isFinite(n)) throw new Error("rng.seed(n) expects a finite number, e.g. rng.seed(12345)"); N.rngSeed(n); },
    shuffle(arr) { const a = arr.slice(); for (let i = a.length - 1; i > 0; i--) { const j = N.rngInt(0, i); [a[i], a[j]] = [a[j], a[i]]; } return a; },
    create: (seed) => createRng(seed),
  };

  // Cross-scene game state: a plain object that survives scene loads for the whole run (reset per test file).
  const session = {};
  function resetSession() { for (const k of Object.keys(session)) delete session[k]; platformReset(); preloadReset(); }

  class ToolError extends Error {
    // Expected failure of a tool: `hint` says how to fix it, `data` (optional object) is reported with the error.
    constructor(message, hint = "", data = undefined) {
      super(message);
      this.name = "ToolError";
      this.hint = hint;
      if (data !== undefined) this.data = data;
    }
  }

  const particles = {
    // Immediately spawns `count` particles at the ParticleEmitter on `entity` (works with emitting = false).
    burst(entity, count = 10) { N.particlesBurst(entityHandle(entity, "particles.burst"), count); },
  };

  const UI_EVENTS = ["click", "change", "submit", "focus", "cancel"];
  const ui = {
    // Size of `text` laid out like Text rendering: { width, height }. Approximate (0.6 * fontSize per char) headless.
    // space: "screen" (default: a UI label or screen-space Text, drawn at fontSize * ui.textScale) or "world".
    // maxTextScale caps that scale; autoShrink (with minFontSize, maxHeight and maxWidth as the box) shrinks the font to fit,
    // exactly as Text does; `fontSize` in the result is the size it would be drawn at.
    measureText(text, o = {}) {
      const space = o.space ?? "screen";
      if (space !== "screen" && space !== "world") throw new Error(`ui.measureText(text, { space }): space must be "screen" or "world", got ${inspect(space)}`);
      const m = N.measureText(String(text), o.fontSize ?? 16, o.font ?? "", o.maxWidth ?? 0, space === "screen", o.maxTextScale ?? 0,
        o.autoShrink ?? false, o.minFontSize ?? 10, o.maxHeight ?? 0);
      return { width: m[0], height: m[1], fontSize: m[2] };
    },
    // True when the text of a Text entity (with a maxWidth / maxHeight box) or the label of a widget still does not fit its box at
    // the size it is drawn at (autoShrink and maxTextScale applied). Read it after game.step or ui.layout().
    overflowed(entityOrId) { return N.overflowed(entityHandle(entityOrId, "ui.overflowed")); },
    // Where a widget or a screen-space Text really is: a Rect { x, y, w, h } in design pixels, (x, y) the TOP-LEFT corner, y down,
    // the safe area included (not the +Y-up convention of entity.bounds()). Takes an Entity or an id/name; null for anything
    // that is neither (a world-space sprite). Layout runs each frame: read it after game.step or ui.layout().
    rectOf(entityOrId) {
      const r = N.screenRect(entityHandle(entityOrId, "ui.rectOf"));
      return r === null ? null : new Rect(r[0], r[1], r[2], r[3]);
    },
    // The player's "text size" option, 0.5 .. 3 (1 = normal): screen-space Text and the labels of UI widgets are drawn and
    // measured at their font size times this; world-space Text is not scaled. Not saved by the engine: store it with `storage`.
    // Setting a number outside 0.5 .. 3 throws.
    get textScale() { return N.textScale(); },
    set textScale(v) { N.setTextScale(v); },
    // on(type, fn) / on(type, target, fn): the widget events the engine sends as "ui.<type>" (see world.on), with the id
    // of the widget in `e.id` and, for "change" and "submit", the new value in `e.value`. `target` (an Entity or an entity
    // id) limits it to one widget. Returns the function that stops listening.
    on(type, a, b) {
      const fn = typeof a === "function" ? a : b, target = typeof a === "function" ? undefined : a;
      if (!UI_EVENTS.includes(type)) {
        const sug = closest(String(type), UI_EVENTS);
        throw new Error(`ui.on(type, fn): unknown event type ${inspect(type)}${sug ? ` (did you mean "${sug}"?)` : ""}; use one of ${UI_EVENTS.map((t) => `"${t}"`).join(", ")}`);
      }
      if (typeof fn !== "function") throw new Error(`ui.on("${type}", [target,] fn) expects a function as its last argument, e.g. ui.on("${type}", (e) => console.log(e.id)), but got ${inspect(fn)}`);
      let id = null;
      if (target !== undefined && target !== null) {
        if (target instanceof Entity) id = target.id;
        else if (typeof target === "string") { const h = N.find(target); id = h === null ? target : N.idOf(h); }
        else throw new Error(`ui.on("${type}", target, fn): target must be an Entity or an entity id such as "play_button", but got ${inspect(target)}`);
      }
      return addListener(`ui.${type}`, (data, source) => {
        if (id !== null && (!data || data.id !== id)) return;
        fn({ type, id: data?.id ?? null, entity: source, value: data?.value });
      }, null);
    },
    // Runs the UI layout now (autoSize sizes, fit sizes, positions, fallbackLayout), exactly what each frame does.
    layout() { N.uiLayout(); },
    // Says `text` aloud with the system's text to speech, in the current language (i18n.language). `interrupt` (default true) stops
    // what is being said first; false waits for it. A no-op (one warning per run) where the system has no speech. Headless runs
    // and tests say nothing and record the line: game.spoken().
    speak(text, o = {}) {
      if (typeof text !== "string") throw new Error(`ui.speak(text, { interrupt }) expects the text as a string, e.g. ui.speak(i18n.t("menu.play")), but got ${inspect(text)}`);
      if (o === null || typeof o !== "object") throw new Error(`ui.speak(text, { interrupt }): the second argument is an options object such as { interrupt: false }, but got ${inspect(o)}`);
      if (o.interrupt !== undefined && typeof o.interrupt !== "boolean") throw new Error(`ui.speak(text, { interrupt }): interrupt must be true (stop what is being said first, the default) or false (queue), but got ${inspect(o.interrupt)}`);
      N.speak(text, o.interrupt ?? true);
    },
    // caption(text, seconds = 3, { key, speaker }): shows a line on the Captions component for `seconds` of the game clock, for
    // dialogue or sounds without a sound file of their own (a sound's caption is audio.play(path, { caption })). `key` is a
    // localization key: the line is then the translation, and follows a language change while it shows (`text` is the fallback
    // and may be ""). `speaker` is a name drawn before the line. The newest Captions.maxLines lines show; with no Captions entity
    // the line is only tracked (game.captions() in tests).
    caption(text, seconds = 3, o = {}) {
      if (o === null || typeof o !== "object") throw new Error(`ui.caption(text, seconds, { key, speaker }): the third argument is an options object such as { speaker: "Mara" }, but got ${inspect(o)}`);
      if (typeof text !== "string") throw new Error(`ui.caption(text, seconds, { key, speaker }) expects the text as a string, e.g. ui.caption("Watch out!", 3), but got ${inspect(text)}. For a translated line use ui.caption("", 3, { key: "hint.watch_out" })`);
      if (typeof seconds !== "number" || !(seconds > 0)) throw new Error(`ui.caption(text, seconds): seconds must be a number above 0 (how long the line shows), e.g. ui.caption(${inspect(text)}, 3), but got ${inspect(seconds)}`);
      for (const k of ["key", "speaker"])
        if (o[k] !== undefined && typeof o[k] !== "string") throw new Error(`ui.caption(text, seconds, { ${k} }): ${k} must be a string, but got ${inspect(o[k])}`);
      if (text === "" && !o.key) throw new Error(`ui.caption("", seconds): there is nothing to show; pass the text or { key: "your.localization.key" }`);
      N.captionAdd(text, o.key ?? "", o.speaker ?? "", seconds);
    },
    // Removes every caption from the screen at once (also the ones that live with a sound; the sound keeps playing).
    clearCaptions() { N.captionClear(); },
    // Stops what is being said and drops what was queued.
    stopSpeaking() { N.stopSpeaking(); },
    // True when the system can speak (headless runs and tests: always true, they record). Hide a "read menus aloud" option when false.
    get speechAvailable() { return N.speechAvailable(); },
    // Gives keyboard / gamepad focus to a Button, Toggle, Slider or TextField (null clears it). Throws, saying why, when
    // the entity cannot take focus.
    focus(target) { N.uiFocus(target === null || target === undefined ? null : entityHandle(target, "ui.focus(target)")); },
    get focused() { return entityOf(N.uiState()[0]); },
    get hovered() { return entityOf(N.uiState()[1]); },
  };

  const assets = {
    // Reads the files ahead of time, a few per frame: returns a handle { progress, done, promise, ... } like scene.preload.
    preload(paths) {
      if (!Array.isArray(paths) || paths.length === 0 || paths.some((p) => typeof p !== "string" || p === ""))
        throw new Error(`assets.preload(paths) expects a non-empty array of project paths such as ["assets/hero.glb", "assets/theme.ogg"], got ${inspect(paths)}`);
      return preloadStart(1, paths, `assets.preload([${paths.length} files])`);
    },
    // Pixel size { width, height } of the texture file at `path` (project-relative), as the renderer and entity.bounds() see it.
    // 32 x 32 (the missing-texture checker) when the file is missing or unreadable.
    textureSize(path) {
      if (typeof path !== "string" || path === "") throw new Error(`assets.textureSize(path) expects a project path such as "assets/hero.png", got ${inspect(path)}`);
      const s = N.textureSize(path);
      return { width: s[0], height: s[1] };
    },
  };

  const math = {
    clamp: (v, lo, hi) => (v < lo ? lo : v > hi ? hi : v),
    lerp: (a, b, t) => a + (b - a) * t,
    inverseLerp: (a, b, v) => (b !== a ? (v - a) / (b - a) : 0),
    remap: (v, a0, a1, b0, b1) => b0 + (b1 - b0) * (a1 !== a0 ? (v - a0) / (a1 - a0) : 0),
    damp: (cur, target, smoothing, dt) => cur + (target - cur) * (1 - Math.exp(-smoothing * dt)),
    moveTowards: (cur, target, maxDelta) => (Math.abs(target - cur) <= maxDelta ? target : cur + Math.sign(target - cur) * maxDelta),
    approach: (cur, target, maxDelta) => (Math.abs(target - cur) <= maxDelta ? target : cur + Math.sign(target - cur) * maxDelta),
    sign: (v) => (v > 0 ? 1 : v < 0 ? -1 : 0),
    degToRad: (d) => d * Math.PI / 180,
    radToDeg: (r) => r * 180 / Math.PI,
    wrapAngle(a) { a = (a + 180) % 360; if (a < 0) a += 360; return a - 180; },
  };

  const fa = {
    call(name, args = {}) {
      const r = N.callCommand(name, plain(args));
      if (!r.ok) {
        const err = r.error || {};
        const e = new Error(`${name} failed: ${err.message || "unknown error"}` + (err.hint ? ` (hint: ${err.hint})` : ""));
        e.code = err.code; e.hint = err.hint;
        if (err.data !== undefined) e.data = err.data; // structured details, e.g. the report of a ToolError(message, hint, data)
        throw e;
      }
      return r.result;
    },
    commands() { return N.commands(); },
  };

  // plugins.<plugin>.<function>(...args): the functions of the game's native plugins (factoria.json "plugins",
  // docs/EXTENDING.md). A plugin not built for this platform is undefined; one that failed to load throws why on use.
  const plugins = {};
  for (const p of N.pluginList()) {
    const fns = {}, names = p.functions.map((f) => f.name);
    for (const f of names) {
      fns[f] = (...args) => {
        const r = N.pluginCall(p.name, f, plain(args));
        if (r.ok) return r.result;
        const e = new Error(`plugins.${p.name}.${f} failed: ${r.error.message}` + (r.error.hint ? ` (hint: ${r.error.hint})` : ""));
        e.hint = r.error.hint;
        throw e;
      };
    }
    plugins[p.name] = new Proxy(Object.freeze(fns), {
      get(target, key) {
        // `then` and `toJSON` are what await and JSON.stringify probe for: absent, not an error.
        if (typeof key === "symbol" || key in target || key === "then" || key === "toJSON") return target[key];
        if (p.error) throw new Error(`plugins.${p.name}.${key}: the native plugin '${p.name}' is not loaded: ${p.error}`);
        const near = closest(key, names);
        throw new Error(`plugins.${p.name}.${key}: the plugin '${p.name}' has no function '${key}'.` +
          (near ? ` Did you mean '${near}'?` : "") + ` It has: ${names.join(", ") || "no functions"}.`);
      },
    });
  }
  Object.freeze(plugins);

  // ====================================================================================================== platform
  // Store and platform services: achievements, stats, leaderboards, cloud saves, purchases, overlay, presence, integrity
  // (docs/PLATFORM.md). Every call returns a Promise. A programmer's mistake (an id the catalog in factoria.json does not
  // declare, a wrong argument) throws at once; a store failure rejects with an Error that has .code and .hint. Answers that
  // arrive later settle the promises, and events reach platform.on listeners, at the start of the next engine frame.
  const PLATFORM_SERVICES = ["achievements", "stats", "leaderboards", "cloudSave", "purchases", "overlay", "presence", "integrity", "ads"];
  const PLATFORM_EVENTS = ["purchase", "overlay", "player"];
  const platformPending = new Map();  // request id -> { resolve, reject, label, map }
  let purchaseBacklog = [];           // purchase events nobody was listening for: a paid transaction is never lost
  const quotedList = (names) => names.map((n) => `"${n}"`).join(", ");
  const platformArg = (v) => {
    const s = typeof v === "string" ? JSON.stringify(v) : inspect(v);
    return s.length > 40 ? s.slice(0, 37) + "..." : s;
  };
  const platformLabel = (name, args) => `platform.${name}(${args.filter((a) => a !== undefined).map(platformArg).join(", ")})`;

  function platformSettle(entry, a) {
    if (a.ok) {
      let value;
      try { value = entry.map ? entry.map(a.result) : a.result; }
      catch (e) { entry.reject(new Error(`${entry.label} failed: the answer could not be read (${e.message})`)); return; }
      entry.resolve(value);
      return;
    }
    const err = a.error || {};
    const e = new Error(`${entry.label} failed: ${err.message || "unknown error"}` + (err.hint ? ` (hint: ${err.hint})` : ""));
    e.code = err.code;
    e.hint = err.hint || "";
    entry.reject(e);
  }
  function platformCall(method, label, args, map) {
    const r = N.platformStart(method, plain(args));
    if (r.mistake) {
      const e = new Error(`${label}: ${r.mistake.message}` + (r.mistake.hint ? ` (hint: ${r.mistake.hint})` : ""));
      e.hint = r.mistake.hint || "";
      throw e;
    }
    return new Promise((resolve, reject) => {
      const entry = { resolve, reject, label, map };
      // Answered inside the call: no need to wait for a frame. It settles in the next microtask, so that a rejection never
      // happens before the caller could attach its handler (the engine reports a rejection nobody handles as a script error).
      if (r.answer) Promise.resolve().then(() => platformSettle(entry, r.answer));
      else platformPending.set(r.id, entry);
    });
  }
  const noResult = () => undefined;
  function deliverPlatformEvent(name, data) {
    const key = "platform." + name;
    const arr = listeners.get(key);
    if (arr && arr.length) emitToListeners(key, data, null);
    else if (name === "purchase" && purchaseBacklog.length < 100) purchaseBacklog.push({ name, data });
  }
  // Called by the engine at the start of every frame with what arrived since the last one.
  function platformDeliver(answers, events) {
    for (const a of answers) {
      const entry = platformPending.get(a.id);
      if (!entry) continue;  // asked before a reset: nobody is waiting
      platformPending.delete(a.id);
      platformSettle(entry, a);
    }
    const queue = purchaseBacklog.concat(events);
    purchaseBacklog = [];
    for (const ev of queue) deliverPlatformEvent(ev.name, ev.data);
  }
  function platformReset() { platformPending.clear(); purchaseBacklog = []; }

  const platformStats = {
    get(id) { return platformCall("stats.get", platformLabel("stats.get", [id]), { id }, (r) => r.value); },
    set(id, value) { return platformCall("stats.set", platformLabel("stats.set", [id, value]), { id, value }, (r) => r.value); },
    // get, then set: resolves with the new value. An int stat needs a whole delta.
    add(id, delta) {
      if (typeof delta !== "number" || !Number.isFinite(delta))
        throw new Error(`${platformLabel("stats.add", [id, delta])}: delta must be a finite number, e.g. platform.stats.add("wins", 1), got ${platformArg(delta)}`);
      return platformStats.get(id).then((v) => platformStats.set(id, v + delta));
    },
  };
  const platform = {
    // "fake" (development, tests), "none" (no store), or the backend plugin's name ("steam", "apple").
    get backend() { return N.platformInfo().backend; },
    // True in a shipped game, false in development runs and tests: switch off what is only for development with it.
    get release() { return N.platformInfo().release === true; },
    // Does the backend offer the service? One of "achievements", "stats", "leaderboards", "cloudSave", "purchases", "overlay",
    // "presence", "integrity", "ads".
    has(service) {
      if (!PLATFORM_SERVICES.includes(service)) {
        const sug = closest(String(service), PLATFORM_SERVICES);
        throw new Error(`platform.has(service): unknown service ${platformArg(service)}${sug ? ` (did you mean "${sug}"?)` : ""}; use one of ${quotedList(PLATFORM_SERVICES)}`);
      }
      return N.platformInfo().services.includes(service);
    },
    // The last known player { id, name, signedIn } (from signIn and "player" events).
    get player() { return N.platformInfo().player; },
    signIn() { return platformCall("player.signIn", "platform.signIn()", {}); },
    // on(event, fn): "purchase" { status, productId, transactionId, receipt }, "overlay" { open }, "player" { id, name, signedIn }.
    // Returns the function that stops listening. Listeners end with the scene, like ui.on.
    on(event, fn) {
      if (!PLATFORM_EVENTS.includes(event)) {
        const sug = closest(String(event), PLATFORM_EVENTS);
        throw new Error(`platform.on(event, fn): unknown event ${platformArg(event)}${sug ? ` (did you mean "${sug}"?)` : ""}; use one of ${quotedList(PLATFORM_EVENTS)}`);
      }
      if (typeof fn !== "function")
        throw new Error(`platform.on("${event}", fn) expects a function, e.g. platform.on("${event}", (e) => console.log(e)), but got ${platformArg(fn)}`);
      const off = addListener("platform." + event, (data) => fn(data), null);
      if (event === "purchase" && purchaseBacklog.length)  // transactions that arrived before anyone listened
        Promise.resolve().then(() => { const queue = purchaseBacklog; purchaseBacklog = []; for (const ev of queue) deliverPlatformEvent(ev.name, ev.data); });
      return off;
    },
    achievements: {
      unlock(id) { return platformCall("achievements.unlock", platformLabel("achievements.unlock", [id]), { id }); },
      // fraction 0..1; 1 unlocks it.
      progress(id, fraction) { return platformCall("achievements.progress", platformLabel("achievements.progress", [id, fraction]), { id, progress: fraction }); },
      list() { return platformCall("achievements.list", "platform.achievements.list()", {}); },
      // Development only: locks every achievement again.
      reset() { return platformCall("achievements.reset", "platform.achievements.reset()", {}, noResult); },
    },
    stats: platformStats,
    leaderboards: {
      submit(id, score) { return platformCall("leaderboards.submit", platformLabel("leaderboards.submit", [id, score]), { id, score }); },
      // range: "top" (default), "around" (the player's neighbours) or "friends"; count 1..100 (default 10).
      entries(id, options = {}) {
        const o = isObj(options) ? options : {};
        return platformCall("leaderboards.entries", platformLabel("leaderboards.entries", [id, options]), { id, range: o.range, count: o.count });
      },
    },
    cloud: {
      // value: anything JSON can hold. load resolves with it, or undefined when the key does not exist.
      save(key, value) {
        const data = value === undefined || typeof value === "function" ? undefined : JSON.stringify(plain(value));
        if (data === undefined) throw new Error(`${platformLabel("cloud.save", [key, "..."])}: ${platformArg(value)} cannot be saved; use anything JSON can hold (objects, arrays, strings, numbers, booleans, null)`);
        return platformCall("cloud.save", platformLabel("cloud.save", [key, "..."]), { key, data });
      },
      load(key) { return platformCall("cloud.load", platformLabel("cloud.load", [key]), { key }, (r) => (r === null || r === undefined ? undefined : JSON.parse(r.data))); },
      list() { return platformCall("cloud.list", "platform.cloud.list()", {}); },
      remove(key) { return platformCall("cloud.remove", platformLabel("cloud.remove", [key]), { key }, noResult); },
    },
    purchases: {
      // Titles and prices as the store shows them (ids: catalog ids; all products when omitted).
      products(ids) { return platformCall("purchases.products", platformLabel("purchases.products", [ids]), ids === undefined ? {} : { ids }); },
      // Resolves { status: "purchased" | "pending" | "cancelled", productId, transactionId?, receipt? }. Finish a purchased
      // transaction once the game delivered the goods.
      buy(id) { return platformCall("purchases.buy", platformLabel("purchases.buy", [id]), { id }); },
      finish(transactionId) { return platformCall("purchases.finish", platformLabel("purchases.finish", [transactionId]), { transactionId }, noResult); },
      restore() { return platformCall("purchases.restore", "platform.purchases.restore()", {}); },
    },
    overlay: {
      // page: "achievements", "leaderboards", "friends" or "store"; id: an achievement, leaderboard or product of the catalog.
      open(page, id) { return platformCall("overlay.open", platformLabel("overlay.open", [page, id]), { page, id }, noResult); },
    },
    presence: {
      // text: what friends see ("" clears it); data: an object of string values.
      set(text, data) { return platformCall("presence.set", platformLabel("presence.set", [text, data]), { text, data }, noResult); },
    },
    ads: {
      // Is a rewarded ad ready at this placement of factoria.json platform.ads.placements? Resolves true or false.
      available(placement) { return platformCall("ads.available", platformLabel("ads.available", [placement]), { placement }, (r) => r.available === true); },
      // Shows a rewarded ad. Resolves { rewarded, reason? }: rewarded true when the player watched it to the end (give the
      // reward only then); otherwise reason is "closedEarly", "noFill" or "consentRefused". It rejects when the network fails.
      showRewarded(placement) { return platformCall("ads.showRewarded", platformLabel("ads.showRewarded", [placement]), { placement }); },
      // What the consent sheets answered: { gdpr, tracking, canShowAds }.
      consent() { return platformCall("ads.consent", "platform.ads.consent()", {}); },
    },
    integrity: {
      // challenge: a nonce the game's server made (16 to 500 characters of URL-safe Base64). Resolves { token }: a signed
      // statement that this is the genuine app on a genuine device, for the server to verify and to check the challenge in.
      token(challenge) { return platformCall("integrity.token", platformLabel("integrity.token", [challenge]), { challenge }); },
    },
  };

  // ======================================================================================================= i18n
  // Localization (docs/LOCALIZATION.md): the string tables are locales/<language>.json, the languages are listed in factoria.json
  // "localization". Without that section the game is not localized: t(key) returns the key, languages is [].
  const I18N_EVENTS = ["change"];
  const i18n = {
    // t(key, args?): the text of `key` in the current language (else its base language, else the default language). {name}
    // placeholders come from args; a plural entry is chosen by args.count. A key no table has: returns the key, warns once.
    t(key, args) {
      if (typeof key !== "string")
        throw new Error(`i18n.t(key, args): key must be a string like "menu.play", but got ${platformArg(key)}`);
      if (args !== undefined && (!isObj(args) || Array.isArray(args)))
        throw new Error(`i18n.t("${key}", args): args must be an object like { count: 3, name: "Ana" }, but got ${platformArg(args)}`);
      return N.i18nT(key, args === undefined ? {} : plain(args));
    },
    // number(value, { decimals? }): the number written the way the current language writes it ("1,234.5", "1.234,5", "١٬٢٣٤٫٥"):
    // `decimals` digits after the separator (0-9; default: as many as the number has).
    number(value, options) {
      if (typeof value !== "number")
        throw new Error(`i18n.number(value, { decimals }): value must be a number like 1234.5, but got ${platformArg(value)}`);
      if (options !== undefined && (!isObj(options) || Array.isArray(options)))
        throw new Error(`i18n.number(${value}, options): options must be an object like { decimals: 1 }, but got ${platformArg(options)}`);
      const decimals = options && options.decimals !== undefined ? options.decimals : -1;
      if (decimals !== -1 && (!Number.isInteger(decimals) || decimals < 0 || decimals > 9))
        throw new Error(`i18n.number(${value}, { decimals }): decimals must be a whole number from 0 to 9, but got ${platformArg(decimals)}`);
      return N.i18nNumber(value, decimals);
    },
    // duration(seconds, { decimals? }): seconds as a time, "1:23.4" ("h:mm:ss.d" from an hour), `decimals` 0-3 (default 1).
    duration(seconds, options) {
      if (typeof seconds !== "number")
        throw new Error(`i18n.duration(seconds, { decimals }): seconds must be a number like 83.4, but got ${platformArg(seconds)}`);
      if (options !== undefined && (!isObj(options) || Array.isArray(options)))
        throw new Error(`i18n.duration(${seconds}, options): options must be an object like { decimals: 0 }, but got ${platformArg(options)}`);
      const decimals = options && options.decimals !== undefined ? options.decimals : 1;
      if (!Number.isInteger(decimals) || decimals < 0 || decimals > 3)
        throw new Error(`i18n.duration(${seconds}, { decimals }): decimals must be a whole number from 0 to 3, but got ${platformArg(decimals)}`);
      return N.i18nDuration(seconds, decimals);
    },
    // Is `key` in some table of the current language's fallback chain? (t never throws; has tells a real string from the key.)
    has(key) { return N.i18nHas(String(key)); },
    // The current language: one of `languages` ("" when the game has no localization).
    get language() { return N.i18nInfo().language; },
    // Switches now: every Text and widget with a `key` is rewritten, and the "change" listeners run. Accepts the tag as written in
    // factoria.json or close to it ("pt_br", "es-MX" -> "es"); an unknown language throws with a "did you mean". Not saved: a game
    // keeps the choice with `storage` and calls this at start.
    setLanguage(language) {
      const err = N.i18nSet(String(language));
      if (err) throw new Error(`i18n.setLanguage(${platformArg(language)}): ${err}`);
    },
    // The game's languages, as in factoria.json localization.languages (a copy).
    get languages() { return N.i18nInfo().languages; },
    get defaultLanguage() { return N.i18nInfo().defaultLanguage; },
    // "rtl" when the current language is written right to left (Arabic, Hebrew, Persian, Urdu...), else "ltr".
    get direction() { return N.i18nInfo().direction; },
    // The player's system languages, best first (BCP 47). Empty in headless runs and tests.
    get systemLanguages() { return N.i18nInfo().systemLanguages; },
    // The language's own name for a menu ("Español"): "$name" of its table, else the tag.
    name(language) { const names = N.i18nInfo().names; return Object.prototype.hasOwnProperty.call(names, language) ? names[language] : String(language); },
    // on("change", fn): fn({ language, previous }) after every language switch. Returns the function that stops listening.
    // Listeners end with the scene, like ui.on: register in onStart.
    on(event, fn) {
      if (!I18N_EVENTS.includes(event)) {
        const sug = closest(String(event), I18N_EVENTS);
        throw new Error(`i18n.on(event, fn): unknown event ${platformArg(event)}${sug ? ` (did you mean "${sug}"?)` : ""}; use one of ${quotedList(I18N_EVENTS)}`);
      }
      if (typeof fn !== "function")
        throw new Error(`i18n.on("${event}", fn) expects a function, e.g. i18n.on("${event}", (e) => console.log(e.language)), but got ${platformArg(fn)}`);
      return addListener("i18n." + event, (data) => fn(data), null);
    },
  };

  // ---- nav: path finding on the baked NavMesh3D (docs/NAVIGATION.md) ----
  const nav = {
    // findPath(from, to, { radius, snap, closest, mesh }): { found, points: Vec3[], length, complete, mesh } or
    // { found: false, reason, message, hint, nearest?, nearestDistance? }. Never throws for "no route".
    findPath(from, to, o) {
      const a = vecArr(from, 3, "nav.findPath(from, to) `from`"), b = vecArr(to, 3, "nav.findPath(from, to) `to`");
      const args = { from: [a[0], a[1], a[2] ?? 0], to: [b[0], b[1], b[2] ?? 0] };
      if (o) for (const k of ["radius", "snap", "closest", "mesh"]) if (o[k] !== undefined) args[k] = o[k];
      const r = N.navFindPath(args);
      const v = (p) => new Vec3(p[0], p[1], p[2]);
      const out = { found: r.found, points: r.found ? r.points.map(v) : [], length: r.length ?? 0,
                    complete: r.found ? r.complete : false, mesh: r.mesh };
      if (!r.found) {
        out.reason = r.reason; out.message = r.message; out.hint = r.hint;
        if (r.nearest) { out.nearest = v(r.nearest); out.nearestDistance = r.nearestDistance; }
      }
      return out;
    },
    // bake(mesh?): bakes now (autoBake does it by itself) and returns the stats.
    bake(mesh) { return N.navBake(mesh === undefined ? "" : String(mesh)); },
  };

  const factoria = {
    Behaviour, Entity, world, input, audio, physics, nav, time, camera, debug, scene, game, screen, storage, rng, fa,
    vec2, vec3, color, Vec2, Vec3, Color, math, session, ToolError, particles, ui, assets, plugins, platform, i18n,
    window: windowApi, tween, ease, cancelTweens,
  };

  // ============================================================================================ eval serialization
  function summarize(v, depth, seen) {
    if (v === undefined) return null;
    if (v === null || typeof v === "boolean" || typeof v === "string") return v;
    if (typeof v === "number") return Number.isFinite(v) ? v : String(v);
    if (typeof v === "bigint") return String(v) + "n";
    if (typeof v === "symbol") return String(v);
    if (typeof v === "function") return `[Function ${v.name || "anonymous"}]`;
    if (v instanceof Entity) {
      if (!v.alive) return { entity: v.id, alive: false };
      return { entity: v.id, name: v.name, tags: v.tags, components: v.components() };
    }
    if (v instanceof Error) return { error: `${v.name}: ${v.message}` };
    if (seen.has(v)) return "[Circular]";
    if (depth > 8) return "[...]";
    seen.add(v);
    let out;
    if (v instanceof Map) out = Object.fromEntries([...v].map(([k, x]) => [String(k), summarize(x, depth + 1, seen)]));
    else if (v instanceof Set) out = [...v].map((x) => summarize(x, depth + 1, seen));
    else if (Array.isArray(v)) out = v.map((x) => summarize(x, depth + 1, seen));
    else if (typeof v.toJSON === "function") out = summarize(v.toJSON(), depth + 1, seen);
    else { out = {}; for (const k of Object.keys(v)) out[k] = summarize(v[k], depth + 1, seen); }
    seen.delete(v);
    return out;
  }
  const serialize = (v) => JSON.stringify(summarize(v, 0, new WeakSet()));

  // ================================================================================================ factoria:test
  class AssertionError extends Error {
    constructor(message) { super(message); this.name = "AssertionError"; }
  }
  const short = (v) => {
    let s = inspect(v);
    if (typeof v === "string") s = JSON.stringify(v);
    return s.length > 240 ? s.slice(0, 237) + "..." : s;
  };
  function normalizeForEq(v) {
    if (v instanceof Entity) return v;
    if (isObj(v) && typeof v.toJSON === "function") return v.toJSON();
    return v;
  }
  function deepEqual(a, b) {
    a = normalizeForEq(a); b = normalizeForEq(b);
    if (Object.is(a, b)) return true;
    if (typeof a === "number" && typeof b === "number") return Math.abs(a - b) < 1e-6 * Math.max(1, Math.abs(a), Math.abs(b));
    if (!isObj(a) || !isObj(b)) return false;
    if (a instanceof Entity || b instanceof Entity) return a === b;
    if (Array.isArray(a) !== Array.isArray(b)) return false;
    const ka = Object.keys(a).filter((k) => a[k] !== undefined), kb = Object.keys(b).filter((k) => b[k] !== undefined);
    if (ka.length !== kb.length) return false;
    for (const k of ka) if (!deepEqual(a[k], b[k])) return false;
    return true;
  }

  let currentFile = "";
  let testCurrentName = "";
  function locate(err) {
    const stack = String((err && err.stack) || "");
    const lines = stack.split("\n");
    for (const l of lines) {
      if (currentFile && l.includes(currentFile)) {
        const m = l.match(/([^\s(]+:\d+(?::\d+)?)\)?\s*$/);
        if (m) return m[1].replace(/\?v=\d+/g, "");
      }
    }
    return "";
  }

  function makeMatchers(received, negate) {
    const fail = (matcher, expectedText, extra) => {
      const label = negate ? `expect(received).not.${matcher}(${expectedText})` : `expect(received).${matcher}(${expectedText})`;
      throw new AssertionError(`${label}\n  ${negate ? "expected NOT: " : "expected: "}${extra.expected}\n  received: ${extra.received === undefined ? short(received) : extra.received}`);
    };
    const check = (pass, matcher, expected, extra = {}) => {
      if (pass === negate) fail(matcher, expected === undefined ? "" : short(expected), { expected: extra.expectedText ?? short(expected), received: extra.received });
    };
    // expect(game.audioLog()).toContainPlayed(path, { times, bus, source }): `path` is a project-relative clip path, a
    // file name ("jump.wav" matches "assets/sfx/jump.wav") or a RegExp. Plays whose clip failed to load do not count.
    const played = (matcher, path, o = {}) => {
      if (!Array.isArray(received) || received.some((x) => !isObj(x) || typeof x.path !== "string")) {
        throw new AssertionError(`expect(log).${matcher}(path): the received value must be the array returned by game.audioLog(), ` +
          `e.g. expect(game.audioLog()).${matcher}("assets/sfx/jump.wav"), but got ${received === gameApi ? "the game object" : short(received)}`);
      }
      const want = path instanceof RegExp ? path : String(path).replace(/^\.\//, "");
      const pathOk = (p) => (want instanceof RegExp ? p.search(want) >= 0 : p === want || p.endsWith("/" + want));
      const source = o.source instanceof Entity ? o.source.id : o.source;
      const hits = received.filter((x) => x.ok !== false && pathOk(x.path) && (o.bus === undefined || x.bus === o.bus) &&
        (source === undefined || x.source === source));
      const pass = o.times === undefined ? hits.length > 0 : hits.length === o.times;
      let expectedText = `a play of ${want instanceof RegExp ? want : JSON.stringify(want)}`;
      if (o.times !== undefined) expectedText += ` exactly ${o.times} time(s)`;
      if (o.bus !== undefined) expectedText += ` on bus "${o.bus}"`;
      if (source !== undefined) expectedText += ` from entity "${source}"`;
      const groups = new Map();
      for (const x of received) {
        const key = x.path + (x.ok === false ? " (FAILED TO LOAD: see the audio error in the log)" : ` [${x.bus}]`);
        if (!groups.has(key)) groups.set(key, []);
        groups.get(key).push(x.frame);
      }
      const parts = [...groups].slice(0, 12).map(([k, frames]) => `${k} x${frames.length} (frame${frames.length > 1 ? "s" : ""} ${frames.slice(0, 5).join(", ")}${frames.length > 5 ? ", ..." : ""})`);
      if (groups.size > 12) parts.push(`... ${groups.size - 12} more clips`);
      const got = received.length === 0
        ? "no sounds played (the log is cleared before each test: step the game after the action that plays the sound)"
        : parts.join("; ");
      check(pass, matcher, want instanceof RegExp ? String(want) : want, { expectedText, received: got });
    };
    const m = {
      toBe(e) { check(Object.is(received, e), "toBe", e); },
      toEqual(e) { check(deepEqual(received, e), "toEqual", e); },
      toBeCloseTo(e, digits = 2) {
        const pass = typeof received === "number" && Math.abs(received - e) < Math.pow(10, -digits) / 2;
        check(pass, "toBeCloseTo", e, { expectedText: `${short(e)} (within ${Math.pow(10, -digits) / 2})` });
      },
      toBeGreaterThan(e) { check(received > e, "toBeGreaterThan", e, { expectedText: `> ${short(e)}` }); },
      toBeGreaterThanOrEqual(e) { check(received >= e, "toBeGreaterThanOrEqual", e, { expectedText: `>= ${short(e)}` }); },
      toBeLessThan(e) { check(received < e, "toBeLessThan", e, { expectedText: `< ${short(e)}` }); },
      toBeLessThanOrEqual(e) { check(received <= e, "toBeLessThanOrEqual", e, { expectedText: `<= ${short(e)}` }); },
      toBeTruthy() { check(!!received, "toBeTruthy", undefined, { expectedText: "a truthy value" }); },
      toBeFalsy() { check(!received, "toBeFalsy", undefined, { expectedText: "a falsy value" }); },
      toBeNull() { check(received === null, "toBeNull", null); },
      toBeUndefined() { check(received === undefined, "toBeUndefined", undefined, { expectedText: "undefined" }); },
      toBeDefined() { check(received !== undefined, "toBeDefined", undefined, { expectedText: "a defined value" }); },
      toBeNaN() { check(Number.isNaN(received), "toBeNaN", undefined, { expectedText: "NaN" }); },
      toContain(e) {
        let pass = false;
        if (typeof received === "string") pass = received.includes(e);
        else if (received && typeof received[Symbol.iterator] === "function") pass = [...received].some((x) => x === e || deepEqual(x, e));
        check(pass, "toContain", e, { expectedText: `to contain ${short(e)}` });
      },
      toHaveLength(n) {
        const len = received == null ? undefined : received.length;
        check(len === n, "toHaveLength", n, { expectedText: `length ${n}`, received: `length ${len} (${short(received)})` });
      },
      toMatch(re) {
        const pass = typeof received === "string" && (re instanceof RegExp ? re.test(received) : received.includes(re));
        check(pass, "toMatch", re instanceof RegExp ? String(re) : re, { expectedText: `to match ${re}` });
      },
      // toMatchObject(subset): every field of `subset` is in the received object with an equal value, recursively (an
      // object may have more fields; arrays must have the same length and each element matches its subset).
      toMatchObject(subset) {
        if (!isObj(received) || !isObj(subset)) throw new AssertionError(`expect(x).toMatchObject(subset): both the received value and the subset must be objects, got ${short(received)} and ${short(subset)}`);
        const sub = (a, b) => {
          a = normalizeForEq(a); b = normalizeForEq(b);
          if (!isObj(a) || !isObj(b) || a instanceof Entity || b instanceof Entity) return deepEqual(a, b);
          if (Array.isArray(b)) return Array.isArray(a) && a.length === b.length && b.every((x, i) => sub(a[i], x));
          return Object.keys(b).every((k) => b[k] === undefined ? true : k in a && sub(a[k], b[k]));
        };
        check(sub(received, subset), "toMatchObject", subset, { expectedText: `an object containing ${short(subset)}` });
      },
      toBeInstanceOf(C) { check(received instanceof C, "toBeInstanceOf", C.name, { expectedText: `instance of ${C.name}` }); },
      toContainPlayed(path, o) { played("toContainPlayed", path, o); },
      toHavePlayed(path, o) { played("toHavePlayed", path, o); },
      toThrow(expected) {
        let threw = false, error;
        if (typeof received !== "function") throw new AssertionError("expect(fn).toThrow(): the received value is not a function. Wrap the code: expect(() => ...).toThrow()");
        try { received(); } catch (e) { threw = true; error = e; }
        let pass = threw;
        if (threw && expected !== undefined) {
          const msg = String((error && error.message) ?? error);
          pass = expected instanceof RegExp ? expected.test(msg) : typeof expected === "string" ? msg.includes(expected) : error instanceof expected;
        }
        check(pass, "toThrow", expected, {
          expectedText: expected === undefined ? "the function to throw" : `to throw ${expected instanceof RegExp ? expected : typeof expected === "string" ? JSON.stringify(expected) : expected.name}`,
          received: threw ? `threw ${short(String((error && error.message) ?? error))}` : "did not throw",
        });
      },
    };
    return m;
  }
  function expect(received) {
    const m = makeMatchers(received, false);
    m.not = makeMatchers(received, true);
    return m;
  }

  // Test registry
  let suiteStack = [];
  let tests = [];
  function currentHooks(kind) {
    const out = [];
    for (const s of suiteStack) out.push(...s[kind]);
    return out;
  }
  function describe(name, fn) {
    const suite = { name, beforeEach: [], afterEach: [], skip: false };
    suiteStack.push(suite);
    try { fn(); } finally { suiteStack.pop(); }
  }
  describe.skip = (name, fn) => {
    const suite = { name, beforeEach: [], afterEach: [], skip: true };
    suiteStack.push(suite);
    try { fn(); } finally { suiteStack.pop(); }
  };
  function test(name, fn) {
    if (typeof fn !== "function") throw new Error(`test('${name}', fn): the second argument must be a function`);
    tests.push({
      name: [...suiteStack.map((s) => s.name), name].join(" > "),
      fn, skip: suiteStack.some((s) => s.skip),
      before: suiteStack.flatMap((s) => s.beforeEach), after: suiteStack.flatMap((s) => s.afterEach),
    });
  }
  test.skip = (name, fn) => { tests.push({ name: [...suiteStack.map((s) => s.name), name].join(" > "), fn, skip: true, before: [], after: [] }); };
  const beforeEach = (fn) => { if (suiteStack.length) suiteStack[suiteStack.length - 1].beforeEach.push(fn); else throw new Error("beforeEach must be called inside describe()"); };
  const afterEach = (fn) => { if (suiteStack.length) suiteStack[suiteStack.length - 1].afterEach.push(fn); else throw new Error("afterEach must be called inside describe()"); };

  const stepN = (n) => N.testStep(n);
  // A position, or a widget id / Entity: the centre of its laid-out rectangle (the safe area is included; a widget moves one
  // game.step after game.setSafeArea).
  const posArg = (p, what) => {
    if (typeof p === "string" || p instanceof Entity) {
      const r = N.screenRect(entityHandle(p, what));
      if (r === null) throw new Error(`${what}: ${inspect(p)} has no screen rectangle: pass a UI widget or a screen-space Text, or a position {x, y}`);
      return [r[0] + r[2] / 2, r[1] + r[3] / 2];
    }
    if (Array.isArray(p)) return [p[0], p[1]];
    if (isObj(p) && typeof p.x === "number") return [p.x, p.y];
    throw new Error(`${what} expects a screen position {x, y} or [x, y], got ${inspect(p)}`);
  };
  const gameApiBase = {
    get paused() { return game.paused; },
    set paused(v) { game.paused = v; },
    today() { return game.today(); },
    get focused() { return game.focused; },
    // setDate("2026-10-23"): the date game.today() answers until the test ends (every test starts from the date of the run:
    // 2026-01-01, or --date). An impossible date (2026-02-29) or a wrong shape throws and says what is wrong.
    setDate(iso) {
      if (typeof iso !== "string") throw new Error(`game.setDate(iso) expects a string like "2026-10-23", but got ${inspect(iso)}`);
      const err = N.testSetDate(iso);
      if (err) throw new Error(err);
    },
    // suspend() / resume(): the app goes to the background and comes back, as on a phone: sends the "suspend" / "resume" event to
    // game.on listeners at once and, with pauseOnSuspend (default), freezes the game and the music in between. focus() / blur():
    // the window gains or loses the focus (game.focused). Every test starts focused and running.
    suspend() { N.testAppEvent(0); },
    resume() { N.testAppEvent(1); },
    focus() { N.testAppEvent(2); },
    blur() { N.testAppEvent(3); },
    load(path) {
      const err = N.testLoad(path);
      if (err) throw new Error(`game.load('${path}') failed: ${err}`);
    },
    setStorageText(text) { N.testStorageText(text === null || text === undefined ? null : String(text)); },
    step(frames = 1) { stepN(frames); },
    press(action) { N.inSetAction(action, true); },
    release(action) { N.inSetAction(action, false); },
    tap(action) { N.inSetAction(action, true); stepN(1); N.inSetAction(action, false); stepN(1); },
    keyDown(key) { N.inKeyEvent(key, true); },
    keyUp(key) { N.inKeyEvent(key, false); },
    // Types text as a keyboard would: input.text shows it until the next step. Control characters are skipped, like the
    // real keyboard does; send Enter and Backspace with keyDown/keyUp.
    typeText(text) { for (const ch of String(text)) { const cp = ch.codePointAt(0); if (cp >= 32 && cp !== 127) N.testText(cp); } },
    // gamepad(index = 0): drives pad `index`. press/release/axis/connect/disconnect act now (like keyDown/keyUp); tap steps.
    // press, release and axis connect the pad if needed; disconnect releases what it held.
    gamepad(index = 0) {
      N.inPad(0, index, "");  // validates the index; press/axis/connect (not this call) connect the pad
      return {
        press(button) { N.testPad(0, index, button, 0); },
        release(button) { N.testPad(1, index, button, 0); },
        tap(button) { N.testPad(0, index, button, 0); stepN(1); N.testPad(1, index, button, 0); stepN(1); },
        axis(name, value) { N.testPad(2, index, name, value); },
        connect() { N.testPad(3, index, "", 0); },
        disconnect() { N.testPad(4, index, "", 0); },
        // Plugs the pad in as this family, for input.buttonName("jump") and input.gamepad(i).type: "xbox", "playstation",
        // "nintendo", "steamdeck" or "generic". Tests start with "generic" pads.
        setType(type) { N.testPad(5, index, type, 0); },
      };
    },
    // Presses the system Back button (Android). The input.onBack handlers run at the next step(); when none consumes it the
    // game asks to quit (game.quitRequested in game.state()).
    pressBack() { N.testBack(); },
    // Pretends the player's system has these accessibility settings: game.accessibility follows. Keys left out keep their
    // default (textScale 1, the others false). textScale is clamped to 0.5 - 4. Reset to the defaults before every test.
    setAccessibility(settings) {
      if (!isObj(settings)) throw new Error(`game.setAccessibility(settings) expects { textScale?, reduceMotion?, highContrast?, screenReader? }, e.g. game.setAccessibility({ textScale: 1.5 }), but got ${inspect(settings)}`);
      const keys = ["textScale", "reduceMotion", "highContrast", "screenReader"];
      for (const k of Object.keys(settings)) {
        if (keys.includes(k)) continue;
        const sug = closest(k, keys);
        throw new Error(`game.setAccessibility: unknown setting '${k}'${sug ? `; did you mean '${sug}'?` : ""} Use ${keys.join(", ")}.`);
      }
      const scale = settings.textScale ?? 1;
      if (typeof scale !== "number" || !Number.isFinite(scale) || scale <= 0) throw new Error(`game.setAccessibility: textScale must be a number above 0 (1 = 100 %), but got ${inspect(scale)}`);
      for (const k of keys.slice(1)) if (settings[k] !== undefined && typeof settings[k] !== "boolean") throw new Error(`game.setAccessibility: ${k} must be true or false, but got ${inspect(settings[k])}`);
      N.testAccessibility(scale, !!settings.reduceMotion, !!settings.highContrast, !!settings.screenReader);
    },
    // Pretends to be a phone with a notch, rounded corners or system bars: screen.safeArea, screen.insets and the items with
    // safeArea follow. Takes insets in design pixels ({ left, top, right, bottom }, 0 for those left out) or a profile name:
    // "none", "phone-portrait", "phone-landscape". Reset to none before every test.
    setSafeArea(insets) {
      if (typeof insets === "string") {
        const err = N.testSafeProfile(insets);
        if (err) throw new Error(`game.setSafeArea('${insets}'): ${err}`);
        return;
      }
      if (!isObj(insets)) throw new Error(`game.setSafeArea(insets) expects { left, top, right, bottom } in design pixels or a profile name like "phone-portrait", but got ${inspect(insets)}`);
      const side = (k) => {
        const v = insets[k] ?? 0;
        if (typeof v !== "number" || !(v >= 0)) throw new Error(`game.setSafeArea: '${k}' must be a number of design pixels, 0 or more, but got ${inspect(v)}`);
        return v;
      };
      N.testSafeInsets(side("left"), side("top"), side("right"), side("bottom"));
    },
    // The pulses input.vibrate() asked for since the test started (cleared before each test), in seconds, oldest first.
    vibrations() { return N.testVibrations(); },
    mouseMove(p) { const a = posArg(p, "game.mouseMove"); N.inMouseMove(a[0], a[1]); },
    click(p, button = "left") {
      const a = posArg(p, "game.click");
      N.inMouseMove(a[0], a[1]); N.inMouseEvent(button, true); stepN(1); N.inMouseEvent(button, false); stepN(1);
    },
    // Files the engine has read from disk since the run started (a file warmed by preload and read later does not count
    // again). Compare two values: expect(game.fileReads()).toBe(before) proves that a load read nothing.
    fileReads() { return N.testDiskReads(); },
    loadJson(scene) {
      const err = N.testLoadJson(plain(scene));
      if (err) throw new Error(`game.loadJson failed: ${err}`);
    },
    touchStart(p, id = 1) { const a = posArg(p, "game.touchStart"); N.testTouch(0, id, a[0], a[1]); },
    touchMove(p, id = 1) { const a = posArg(p, "game.touchMove"); N.testTouch(1, id, a[0], a[1]); },
    touchEnd(id = 1) { N.testTouch(2, id, 0, 0); },
    touch(p, frames = 1) {
      const a = posArg(p, "game.touch");
      N.testTouch(0, 1, a[0], a[1]); stepN(frames); N.testTouch(2, 1, 0, 0); stepN(1);
    },
    find(idOrName) { return world.find(idOrName); },
    get world() { return world; },
    get time() { return time; },
    screenshot(path, options) {
      const err = N.testScreenshot(path, options && options.scale !== undefined ? options.scale : 1,
        options && options.simulate !== undefined ? String(options.simulate) : "");
      if (err) throw new Error(`game.screenshot('${path}') failed: ${err}`);
    },
    state() { return N.testState(); },
    // Sounds played since the test started (cleared before each test): [{ seq, frame, time, path, volume, pitch, pan,
    // bus, loop, music, source, ok }], oldest first. Assert with expect(game.audioLog()).toContainPlayed(path).
    audioLog() { return N.audioLog(false); },
    clearAudioLog() { N.audioLog(true); },
    // What ui.speak was asked to say since the test started (cleared before each test): [{ text, language, interrupt }], oldest
    // first. Headless runs speak nothing, they only record. Assert with expect(game.spoken().map((l) => l.text)).toEqual([...]).
    spoken() { return N.spokenLog(false); },
    clearSpoken() { N.spokenLog(true); },
    // The captions on the list now (cleared before each test), oldest first: [{ text, speaker, key, source }]. `text` is in the
    // current language; `key` is "" for plain text; `source` is "audio:<clip path>" or "ui". The Captions component draws the
    // newest Captions.maxLines of them. Assert with expect(game.captions().map((c) => c.text)).toEqual([...]).
    captions() { return N.captionList(); },
    // The fake store, for tests (docs/PLATFORM.md, "Testing"): script its answers, send it events, look at what it holds.
    // They run the platform.* commands, so MCP clients and tests share one implementation.
    platform: {
      // respond(method, answer, times = 1): the next answer(s) to `method`: { error: "network", message?, hint? } rejects,
      // { result } resolves with exactly that, any other object is merged into the default result ({ status: "cancelled" }).
      respond(method, answer, times = 1) { fa.call("platform.respond", { method, answer: plain(answer), times }); },
      // emit(event, data): sends "purchase", "overlay" or "player" to platform.on listeners at the next game.step().
      emit(event, data = {}) { fa.call("platform.emit", { event, data: plain(data) }); },
      // revoke(productId): takes a purchase back like a refund: restore() no longer lists it and platform.on("purchase")
      // listeners get { status: "revoked", productId, transactionId, receipt } at the next game.step().
      revoke(productId) { fa.call("platform.revoke", { productId }); },
      // ad(outcome, options): how the fake's test ad ends from now on: "watched" (default), "closedEarly", "noFill" or
      // "consentRefused"; options { gdpr, tracking } are what platform.ads.consent() answers. reset() restores the defaults.
      ad(outcome, options = {}) { fa.call("platform.set_ad", { outcome, ...plain(options) }); },
      reset() { fa.call("platform.reset"); },
      // set({ signedIn, delayFrames, backend }): signedIn false rejects everything with notSignedIn; delayFrames holds each
      // answer; backend "none" behaves as a game without a store (platform.has false, calls reject unavailable) until reset().
      // An unknown option throws with a "did you mean".
      set(options) { fa.call("platform.set_fake", plain(options)); },
      state() { return fa.call("platform.state"); },
      // Every request the game made: [{ seq, frame, method, args, ok, result | error }], oldest first.
      calls() { const s = fa.call("platform.state"); return s.fake ? s.fake.calls : []; },
    },
  };
  // An unknown member (game.pasued) throws with a "did you mean" instead of being undefined.
  const gameApi = new Proxy(gameApiBase, {
    get(t, k, recv) {
      if (typeof k !== "string" || k in t || k === "then" || k === "toJSON") return Reflect.get(t, k, recv);
      const sug = closest(k, Object.keys(t));
      throw new Error(`the test game object has no member '${k}'${sug ? `; did you mean '${sug}'?` : ""} Members: ${Object.keys(t).join(", ")}`);
    },
  });
  const testApi = { test, describe, expect, game: gameApi, beforeEach, afterEach };

  function testBegin(file) { currentFile = file; tests = []; suiteStack = []; testCurrentName = ""; }
  function testCurrent() { return testCurrentName; }
  function testRun(filter) {
    const f = (filter || "").toLowerCase();
    const results = [];
    for (const t of tests) {
      if (f && !t.name.toLowerCase().includes(f)) continue;
      if (t.skip) { results.push({ name: t.name, skipped: true, passed: true, ms: 0 }); continue; }
      testCurrentName = t.name;
      N.resetInput();
      N.audioLog(true);
      N.spokenLog(true);
      N.captionClear();
      N.testAccessibility();
      N.setTimeScale(1); pausedScale = null;
      N.testAppReset();
      // The fake's test ad ends "watched" and the consent sheets say granted again (the rest of the fake lasts the file).
      try { fa.call("platform.set_ad", { outcome: "watched", gdpr: "granted", tracking: "authorized" }); } catch (e) { /* a real backend: nothing to reset */ }
      const start = N.nowMs();
      const seq0 = N.logSeq();
      let passed = true, message = "";
      N.guardBegin(`test '${t.name}'`, 60.0);
      try {
        for (const h of t.before) h();
        let r = t.fn();
        if (r && typeof r.then === "function") {
          let state = 0, err;
          r.then(() => { state = 1; }, (e) => { state = 2; err = e; });
          N.pumpJobs();
          if (state === 2) throw err;
          if (state === 0) throw new Error("the test returned a promise that never resolved. game.step() is synchronous: do not await timers or frames");
        }
        for (const h of t.after) h();
      } catch (e) {
        passed = false;
        const loc = locate(e);
        let caret = "";
        if (!(e instanceof AssertionError) && loc && /not a function/.test(String(e && e.message))) {
          const m = loc.match(/^(.*):(\d+):(\d+)$/);
          if (m) caret = N.sourceCaret(m[1], Number(m[2]), Number(m[3]));
        }
        if (e instanceof AssertionError) message = e.message + (loc ? `\n  at ${loc}` : "");
        else message = `${e && e.name ? e.name : "Error"}: ${e && e.message !== undefined ? e.message : String(e)}` + (loc ? `\n  at ${loc}` : "") + caret +
          "\n  (an exception was thrown inside the test; check the game scripts too: `factoria` logs script errors)";
      }
      N.guardEnd();
      results.push({ name: t.name, passed, message, ms: N.nowMs() - start, seq0, seq1: N.logSeq() });
    }
    N.resetInput();
    N.setTimeScale(1); pausedScale = null;
    testCurrentName = "";
    return results;
  }

  function resetScene() {
    timers.reset(); tweens.cancelAll(); listeners.clear(); entityCache.clear(); backHandlers.length = 0; pausedScale = null; // a scene load ends the pause bookkeeping: time.scale = v applies at once again
    timers.now = 0;
  }

  return {
    factoria, test: testApi,
    isBehaviourClass, instantiate, checkProps, checkHooks, resetSession, makeInfo, serialize, platformDeliver, preloadDeliver, back: deliverBack,
    tick: (dt) => { timers.tick(dt); tickTweens(dt); },
    resetScene,
    dropOwner: (h) => timers.dropOwner(h),
    entityDestroyed: (h) => { timers.dropOwner(h); entityCache.delete(h); },
    entity: (h) => entityOf(h),
    emit: emitToListeners,
    testBegin, testRun, testCurrent,
  };
})
