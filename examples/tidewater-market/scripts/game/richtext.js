// @ts-check
// Rich text for event cards, the order board and tooltips (pure: the layout takes a `measure` function, so tests need no engine).
//
// The engine's Text has one size, one colour and one font per entity and no inline pictures (ENGINE_FEEDBACK FB-0030), so a
// line with a green number, a bold word and the picture of a good is several entities placed by this file. The text is a small
// markup, written in the locale strings:
//
//   [b]bold[/b]            fake bold: the engine has no bold font in the project, the view draws the word twice, 1 px apart
//   [c:good]green[/c]      a colour: a name of COLORS below or #rrggbb
//   [icon:fish]            the picture of a good (atlas frame icon.fish); also icon:coin, icon:star, icon:pop
//   [[                     a literal [
//   a new line is \n
//
// parseMarkup(text) -> { tokens, errors }; layoutRich(tokens, { maxWidth, fontSize, measure }) -> { items, width, height }.
// An item is { kind: "text", text, x, y, w, color, bold } or { kind: "icon", name, x, y, w }; y is the top of the line.

/** Named colours (RGBA 0..1), also the tag names a locale string may use. */
export const COLORS = {
  normal: [0.92, 0.93, 0.95, 1],
  good: [0.5, 0.86, 0.5, 1],
  bad: [1, 0.48, 0.42, 1],
  gold: [1, 0.82, 0.29, 1],
  muted: [0.66, 0.69, 0.75, 1],
  sea: [0.45, 0.75, 1, 1],
};

/** @param {string} name @returns {number[] | null} */
export function colorOf(name) {
  if (COLORS[name]) return COLORS[name];
  const m = /^#([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})$/.exec(name);
  return m ? [parseInt(m[1], 16) / 255, parseInt(m[2], 16) / 255, parseInt(m[3], 16) / 255, 1] : null;
}

/**
 * @typedef {{ kind: "text", text: string, bold: boolean, color: string }
 *   | { kind: "icon", name: string }
 *   | { kind: "br" }} Token
 */

/**
 * Split markup into tokens. Never throws: a bad tag is reported in `errors` (with the position) and kept as plain text, so a
 * typo in a locale string shows up on screen and in `project.validate_data` instead of hiding a sentence.
 * @param {string} text
 * @returns {{ tokens: Token[], errors: string[] }}
 */
export function parseMarkup(text) {
  /** @type {Token[]} */
  const tokens = [];
  const errors = [];
  let bold = 0;
  /** @type {string[]} */
  const colors = [];
  let buf = "";
  const flush = () => {
    if (buf) tokens.push({ kind: "text", text: buf, bold: bold > 0, color: colors.length ? colors[colors.length - 1] : "normal" });
    buf = "";
  };
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    if (ch === "\n") {
      flush();
      tokens.push({ kind: "br" });
    } else if (ch === "[") {
      if (text[i + 1] === "[") {
        buf += "[";
        i++;
        continue;
      }
      const end = text.indexOf("]", i);
      if (end < 0) {
        errors.push(`position ${i}: '[' without ']' (write [[ for a literal bracket)`);
        buf += ch;
        continue;
      }
      const tag = text.slice(i + 1, end);
      flush();
      if (tag === "b") bold++;
      else if (tag === "/b") {
        if (bold === 0) errors.push(`position ${i}: [/b] without [b]`);
        else bold--;
      } else if (tag.startsWith("c:")) {
        const name = tag.slice(2);
        if (!colorOf(name)) errors.push(`position ${i}: unknown colour '${name}' (use ${Object.keys(COLORS).join(", ")} or #rrggbb)`);
        colors.push(colorOf(name) ? name : "normal");
      } else if (tag === "/c") {
        if (!colors.length) errors.push(`position ${i}: [/c] without [c:...]`);
        else colors.pop();
      } else if (tag.startsWith("icon:")) tokens.push({ kind: "icon", name: tag.slice(5) });
      else {
        errors.push(`position ${i}: unknown tag [${tag}] (tags: b, c:<colour>, icon:<name>)`);
        buf += text.slice(i, end + 1);
      }
      i = end;
    } else buf += ch;
  }
  flush();
  if (bold > 0) errors.push("[b] is never closed");
  if (colors.length) errors.push("[c:...] is never closed");
  return { tokens, errors };
}

/** The text of markup with no tags (what a screen reader, a toast or a test compares). Icons become their name in brackets. */
export function plainText(markup) {
  return parseMarkup(markup)
    .tokens.map((t) => (t.kind === "text" ? t.text : t.kind === "icon" ? `[${t.name}]` : "\n"))
    .join("");
}

const isCjk = (ch) => /[⺀-鿿豈-﫿＀-￯぀-ヿ가-힯]/.test(ch);
const noLineStart = "。、」）！？，．：；》,.!?:;)]";

/**
 * Cut tokens into atoms that cannot break inside: a word, one CJK character (a line may break between any two), an icon, a
 * space (which is where a line may break), or a line break.
 */
function atoms(tokens) {
  const out = [];
  for (const t of tokens) {
    if (t.kind === "br") out.push({ kind: "br" });
    else if (t.kind === "icon") out.push({ kind: "icon", name: t.name });
    else {
      const style = { bold: t.bold, color: t.color };
      let word = "";
      const flushWord = () => {
        if (word) out.push({ kind: "word", text: word, ...style });
        word = "";
      };
      for (const ch of t.text) {
        if (ch === " " || ch === "\t") {
          flushWord();
          out.push({ kind: "space", ...style });
        } else if (isCjk(ch)) {
          flushWord();
          out.push({ kind: "word", text: ch, cjk: true, ...style });
        } else word += ch;
      }
      flushWord();
    }
  }
  return out;
}

/**
 * Lay tokens out in lines no wider than `maxWidth`. A line breaks at a space or between two CJK characters, never inside a word
 * and never between a number and the icon glued to it ("+12[icon:wood]"); a closing punctuation mark never starts a line.
 * @param {Token[]} tokens
 * @param {{ maxWidth: number, fontSize: number, measure: (text: string) => number, iconSize?: number, lineHeight?: number }} opts
 * @returns {{ items: any[], width: number, height: number, lines: number }}
 */
export function layoutRich(tokens, opts) {
  const { maxWidth, fontSize, measure } = opts;
  const iconSize = opts.iconSize || Math.round(fontSize * 1.05);
  const lineHeight = opts.lineHeight || Math.round(fontSize * 1.35);
  const spaceW = measure(" ");
  // units: runs of atoms with no break inside
  /** @type {any[][]} */
  const units = [];
  let cur = [];
  const endUnit = () => {
    if (cur.length) units.push(cur);
    cur = [];
  };
  let prevCjk = false;
  for (const a of atoms(tokens)) {
    if (a.kind === "br" || a.kind === "space") {
      endUnit();
      units.push([a]);
      prevCjk = false;
    } else if (a.kind === "word" && a.cjk) {
      if (!(noLineStart.includes(a.text) && prevCjk)) endUnit();
      cur.push(a);
      prevCjk = true;
    } else {
      if (prevCjk && cur.length) endUnit();
      cur.push(a);
      prevCjk = false;
    }
  }
  endUnit();

  const items = [];
  let x = 0;
  let y = 0;
  let lines = 1;
  let widest = 0;
  const unitWidth = (u) => u.reduce((s, a) => s + (a.kind === "icon" ? iconSize : measure(a.text)), 0);
  const newLine = () => {
    widest = Math.max(widest, x);
    x = 0;
    y += lineHeight;
    lines++;
  };
  for (const u of units) {
    if (u[0].kind === "br") {
      newLine();
      continue;
    }
    if (u[0].kind === "space") {
      if (x > 0) x += spaceW;
      continue;
    }
    const w = unitWidth(u);
    if (x > 0 && x + w > maxWidth + 0.01) newLine();
    for (const a of u) {
      if (a.kind === "icon") {
        items.push({ kind: "icon", name: a.name, x, y: y + (lineHeight - iconSize) / 2, w: iconSize });
        x += iconSize;
      } else {
        const aw = measure(a.text);
        const last = items[items.length - 1];
        // join to the previous run when it is the same style and ends exactly here (fewer entities)
        if (last && last.kind === "text" && last.y === y && last.bold === a.bold && last.color === a.color && Math.abs(last.x + last.w - x) < 0.01) {
          last.text += a.text;
          last.w += aw;
        } else items.push({ kind: "text", text: a.text, x, y, w: aw, color: a.color, bold: a.bold });
        x += aw;
      }
    }
    // a space between two units of one style is part of the text run, so the run is one entity
    const next = units[units.indexOf(u) + 1];
    if (next && next[0].kind === "space") {
      const last = items[items.length - 1];
      if (last && last.kind === "text" && last.y === y && next[0].bold === last.bold && next[0].color === last.color) {
        const after = units[units.indexOf(u) + 2];
        if (after && after[0].kind === "word" && after[0].bold === last.bold && after[0].color === last.color && x + spaceW + unitWidth(after) <= maxWidth + 0.01) {
          last.text += " ";
          last.w += spaceW;
          x += spaceW;
          units.splice(units.indexOf(u) + 1, 1);
        }
      }
    }
  }
  widest = Math.max(widest, x);
  return { items, width: widest, height: y + lineHeight, lines };
}
