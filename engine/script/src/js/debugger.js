// Helpers of the script debugger (docs/design/SCRIPT_DEBUGGER.md). Evaluated once per ScriptSystem that has a
// ScriptDebugger; the C++ side calls describe() and entries() to build the Variables view. Nothing here runs a getter of
// the inspected value: properties are read through descriptors. Never instrumented, never visible to scripts.
(function () {
  "use strict";
  const getProto = Object.getPrototypeOf;
  const getDesc = Object.getOwnPropertyDescriptor;
  const ownKeys = Reflect.ownKeys;
  const isView = ArrayBuffer.isView;
  const isArray = Array.isArray;
  const fnToString = Function.prototype.toString;
  const mapEntries = Map.prototype.entries, setValues = Set.prototype.values;
  const mapSize = Object.getOwnPropertyDescriptor(Map.prototype, "size").get;
  const setSize = Object.getOwnPropertyDescriptor(Set.prototype, "size").get;
  const MAX_STRING = 100, MAX_PREVIEW = 140;

  // One entry of a Map, shown as an object {key, value} that previews as `key => value`.
  class MapEntry {
    constructor(key, value) { this.key = key; this.value = value; }
  }

  function quote(s, max) {
    const cut = s.length > max;
    const q = JSON.stringify(cut ? s.slice(0, max) : s);
    return cut ? q.slice(0, -1) + "…\"" : q;
  }

  function ctorName(o) {
    for (let p = o, i = 0; p !== null && i < 30; p = getProto(p), i++) {
      const d = getDesc(p, "constructor");
      if (d && typeof d.value === "function") {
        const n = getDesc(d.value, "name");
        if (n && typeof n.value === "string" && n.value) return n.value;
      }
    }
    return null;
  }

  function isTyped(v) { return isView(v) && !(v instanceof DataView); }

  function fnPreview(f) {
    let src;
    try { src = fnToString.call(f); } catch (e) { return "ƒ"; }
    const nd = getDesc(f, "name");
    const name = nd && typeof nd.value === "string" ? nd.value : "";
    if (/^class[\s{]/.test(src)) return "class " + (name || "(anonymous)");
    let args;
    const single = /^(?:async\s+)?([A-Za-z_$][\w$]*)\s*=>/.exec(src);
    if (single) args = single[1];
    else {
      const m = /\(([^)]*)\)/.exec(src);
      args = m ? m[1].replace(/\s+/g, " ").trim() : "";
    }
    if (args.length > 40) args = args.slice(0, 40) + "…";
    return "ƒ " + name + "(" + args + ")";
  }

  // Short form of a value nested in another preview.
  function brief(v) {
    switch (typeof v) {
      case "object":
        if (v === null) return "null";
        if (isArray(v) || isTyped(v)) return (ctorName(v) || "Array") + "(" + v.length + ")";
        if (v instanceof Map) return "Map(" + mapSize.call(v) + ")";
        if (v instanceof Set) return "Set(" + setSize.call(v) + ")";
        if (v instanceof MapEntry) return "{…}";
        if (v instanceof Error) return v.name + ": " + v.message;
        { const n = ctorName(v); return n && n !== "Object" ? n + " {…}" : "{…}"; }
      case "function": return fnPreview(v);
      default: return pv(v, true);
    }
  }

  function pv(v, nested) {
    switch (typeof v) {
      case "string": return quote(v, nested ? 30 : MAX_STRING);
      case "number": return Object.is(v, -0) ? "-0" : String(v);
      case "bigint": return String(v) + "n";
      case "symbol": return v.toString();
      case "undefined": return "undefined";
      case "boolean": return String(v);
      case "function": return fnPreview(v);
    }
    if (v === null) return "null";
    if (v instanceof MapEntry) return pv(v.key, true) + " => " + pv(v.value, true);
    if (v instanceof Error) return v.name + ": " + v.message;
    if (isArray(v) || isTyped(v)) {
      const n = v.length, parts = [];
      for (let i = 0; i < n && i < 6; i++) parts.push(brief(v[i]));
      return (ctorName(v) || "Array") + "(" + n + ") [" + parts.join(", ") + (n > 6 ? ", …" : "") + "]";
    }
    if (v instanceof Map) {
      const n = mapSize.call(v), parts = [];
      for (const [k, x] of mapEntries.call(v)) { if (parts.length >= 3) break; parts.push(brief(k) + " => " + brief(x)); }
      return "Map(" + n + ") {" + parts.join(", ") + (n > 3 ? ", …" : "") + "}";
    }
    if (v instanceof Set) {
      const n = setSize.call(v), parts = [];
      for (const x of setValues.call(v)) { if (parts.length >= 5) break; parts.push(brief(x)); }
      return "Set(" + n + ") {" + parts.join(", ") + (n > 5 ? ", …" : "") + "}";
    }
    if (v instanceof Date) { try { return v.toISOString(); } catch (e) { return "Invalid Date"; } }
    if (v instanceof RegExp) return RegExp.prototype.toString.call(v);
    if (v instanceof Promise) return "Promise {…}";
    const proto = getProto(v);
    let prefix = "";
    if (proto === null) prefix = "[Object: null prototype] ";
    else { const n = ctorName(v); if (n && n !== "Object") prefix = n + " "; }
    const keys = ownKeys(v).filter((k) => typeof k === "string");
    const parts = [];
    let shown = 0;
    for (const k of keys) {
      if (shown >= 5) break;
      const d = getDesc(v, k);
      if (!d || !d.enumerable) continue;
      parts.push(k + ": " + ("value" in d ? brief(d.value) : "(getter)"));
      shown++;
    }
    let enumerable = shown;
    if (shown >= 5) { enumerable = 0; for (const k of keys) { const d = getDesc(v, k); if (d && d.enumerable) enumerable++; } }
    let out = prefix + "{" + parts.join(", ") + (enumerable > shown ? ", …" : "") + "}";
    if (out.length > MAX_PREVIEW) out = out.slice(0, MAX_PREVIEW - 2) + "…}";
    return out;
  }

  // [type, preview, expandable (0/1), indexedCount]
  function describe(v) {
    let preview, type = v === null ? "null" : typeof v, indexed = 0;
    try { preview = pv(v, false); } catch (e) { preview = "<unprintable>"; }
    const expandable = (typeof v === "object" && v !== null) || typeof v === "function" ? 1 : 0;
    try {
      if (isArray(v) || isTyped(v)) indexed = v.length;
      else if (v instanceof Map) indexed = mapSize.call(v);
      else if (v instanceof Set) indexed = setSize.call(v);
    } catch (e) { indexed = 0; }
    return [type, preview, expandable, indexed];
  }

  function isIndex(k) { return /^(0|[1-9]\d*)$/.test(k); }

  // The children of an object as [name, value, flag] (flag: 0 data, 1 getter, 2 setter only). Order: array elements by
  // index, then own string-keyed properties, then [[Prototype]]. [start, start + count) of that list; count 0 = all.
  function entries(o, start, count) {
    const end = count > 0 ? start + count : Infinity;
    const out = [];
    let n = 0;
    const rest = [];
    const arr = isArray(o), typed = isTyped(o);
    if (arr || typed) n = o.length;
    if (o instanceof Map) {
      let i = 0;
      for (const [k, x] of mapEntries.call(o)) rest.push(["[" + i++ + "]", new MapEntry(k, x), 0]);
    } else if (o instanceof Set) {
      let i = 0;
      for (const x of setValues.call(o)) rest.push(["[" + i++ + "]", x, 0]);
    } else if (typed || (arr && n > 5000)) {
      rest.push(["length", n, 0]);
    } else {
      for (const k of ownKeys(o)) {
        if (typeof k !== "string") continue;
        if (arr && isIndex(k)) continue;
        const d = getDesc(o, k);
        if (!d) continue;
        if ("value" in d) rest.push([k, d.value, 0]);
        else rest.push([k, undefined, d.get ? 1 : 2]);
      }
    }
    const proto = getProto(o);
    if (proto !== null) rest.push(["[[Prototype]]", proto, 0]);
    for (let i = start; i < n && i < end; i++) out.push([String(i), o[i], 0]);
    const from = Math.max(0, start - n);
    const to = Math.min(rest.length, end - n);
    for (let i = from; i < to; i++) out.push(rest[i]);
    return out;
  }

  return { describe, entries };
})()
