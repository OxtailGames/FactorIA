// @ts-check
// Builders for the entity JSON of the journal and puzzle screens (scripts/screens.js). Everything is placed in design pixels
// (1280 x 720, origin top-left) inside one full-screen Panel; every ancestor of every widget is a Panel, which also keeps clear
// of ENGINE_FEEDBACK LL/FB-0001 (a drag over a widget whose ancestor has no UI component crashes the engine; nothing here drags).
// The screens are rebuilt from these functions whenever their state changes, so a builder has no state of its own.

export const W = 1280;
export const H = 720;

/** Layers: backdrop pieces, lines, widgets, texts. The dialogue box uses 220-252, the HUD 210. */
export const LAYER = Object.freeze({ back: 300, line: 305, widget: 310, text: 320, frame: 330 });

const pos = (x, y) => [x - W / 2, y - H / 2, 0];

/** An empty container that holds the screen: modal, so the widgets behind it neither hover nor take the focus. */
export function root(id, children) {
  return {
    id,
    components: {
      Transform: { position: [0, 0, 0] },
      Panel: { size: [W, H], anchor: [0.5, 0.5], pivot: [0.5, 0.5], layer: LAYER.back - 1, color: [0, 0, 0, 0], layout: "none", modal: true },
    },
    children,
  };
}

/** A filled rectangle (a backdrop piece or a frame side). Not interactive. */
export function rect(id, x, y, w, h, color, layer = LAYER.back) {
  return {
    id,
    components: {
      Transform: { position: pos(x, y) },
      Panel: { size: [w, h], anchor: [0.5, 0.5], pivot: [0, 1], layer, color, layout: "none", padding: [0, 0, 0, 0] },
    },
  };
}

/** A block of text whose top-left corner is at (x, y), wrapped at `width`. */
export function label(id, x, y, width, text, opts = {}) {
  return {
    id,
    components: {
      Transform: { position: pos(x, y) },
      Panel: { anchor: [0.5, 0.5], pivot: [0, 1], layer: LAYER.text - 1, color: [0, 0, 0, 0], layout: "column", padding: [0, 0, 0, 0], align: "start", fit: true, minSize: [width, 0], maxSize: [width, 0] },
    },
    children: [
      {
        id: id + "_t",
        components: {
          Text: {
            text,
            fontSize: opts.size ?? 22,
            color: opts.color ?? [0.94, 0.93, 0.9, 1],
            maxWidth: width,
            markup: opts.markup ?? false,
            layer: LAYER.text,
            space: "screen",
          },
        },
      },
    ],
  };
}

/** A button with its top-left corner at (x, y). `opts`: size (font), markup, enabled, color, focus (autoFocus), accent (marks it as chosen). */
export function button(id, x, y, w, h, text, opts = {}) {
  const on = opts.enabled !== false;
  const color = opts.color ?? (opts.accent ? [0.34, 0.27, 0.12, 0.98] : [0.17, 0.2, 0.28, 0.98]);
  return {
    id,
    components: {
      Transform: { position: pos(x, y) },
      Button: {
        text,
        size: [w, h],
        anchor: [0.5, 0.5],
        pivot: [0, 1],
        layer: LAYER.widget,
        fontSize: opts.size ?? 22,
        color,
        textColor: on ? (opts.accent ? [1, 0.9, 0.55, 1] : [1, 1, 1, 1]) : [0.5, 0.52, 0.58, 1],
        interactable: on,
        autoFocus: !!opts.focus,
        markup: !!opts.markup,
        maxWidth: opts.maxWidth ?? 0,
      },
    },
  };
}

/** A line on the screen from (x1, y1) to (x2, y2). (Shape2D screen-space lines take the end offset with +Y up.) */
export function line(id, x1, y1, x2, y2, color, thickness = 2) {
  return {
    id,
    components: {
      Transform: { position: pos(x1, y1) },
      Shape2D: { shape: "line", size: [x2 - x1, -(y2 - y1)], color, thickness, layer: LAYER.line, space: "screen", anchor: [0.5, 0.5] },
    },
  };
}

/** A scrolling column of entries (buttons) at (x, y). Its children are given as `children`. */
export function list(id, x, y, w, h, children) {
  return {
    id,
    components: {
      Transform: { position: pos(x, y) },
      ScrollList: { size: [w, h], anchor: [0.5, 0.5], pivot: [0, 1], layer: LAYER.widget - 1, color: [0, 0, 0, 0.25], spacing: 8, padding: [6, 6, 6, 6] },
    },
    children,
  };
}

/** A button meant to live in a list (the list places it): no position. */
export function listButton(id, w, text, opts = {}) {
  const b = button(id, 0, 0, w, opts.height ?? 48, text, opts);
  delete b.components.Transform;
  const c = b.components.Button;
  c.anchor = [0, 0];
  c.pivot = [0.5, 0.5];
  if (opts.auto) {
    c.autoSize = true;
    c.maxWidth = w;
  }
  return b;
}
