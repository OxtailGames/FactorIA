// @ts-check
// What the comfort and accessibility options do to a level (P5). applyToScene(s) writes the settings into the scene's own
// entities: the quality preset (sun shadows, lantern lights, view distance and fog), the touch controls (left-handed
// layout, size, opacity), the camera (sensitivity, invert Y, reduced motion) and the assist mode (spring, dogs, jump grace).
// It is safe to call again after every change in the options menu and in scenes without those entities (the title):
// whatever is missing is skipped.
//
// Nothing here imports settings.js (settings.js calls this file): the settings arrive as the argument.
import { world, scene, window } from "factoria";

/**
 * The graphics presets. `particles` multiplies every burst and ambient rate; `lights` is the share of lantern lights kept;
 * `renderScale` is window.renderScale (the picture is drawn at that share of the window's size and scaled up).
 */
export const QUALITY = {
  low: { shadows: false, particles: 0.4, lights: 0.34, farPlane: 0.45, fog: 1.7, renderScale: 0.7 },
  medium: { shadows: true, particles: 0.7, lights: 0.67, farPlane: 0.7, fog: 1.25, renderScale: 0.85 },
  high: { shadows: true, particles: 1, lights: 1, farPlane: 1, fog: 1, renderScale: 1 },
};

/** The assist mode, in numbers (tests read them). */
export const ASSIST = {
  /** Spring seconds that drain per second of play (1 = normal). */
  drainRate: 0.6,
  /** Multiplier of the dogs' chase speed. */
  dogSpeed: 0.75,
  /** Multiplier of the seconds a dog needs without seeing the courier to give up. */
  dogGiveUp: 0.5,
  /** Multiplier of the dogs' alert time (more time to get away). */
  dogAlert: 1.6,
  /** Jump grace: coyote time and jump buffer in seconds (normal 0.12 each). */
  coyoteTime: 0.25,
  jumpBuffer: 0.25,
};

/** Reduced motion: a slower, softer camera follow (the props that bob or spin read reducedMotion() themselves). */
export const REDUCED = { followSmoothing: 5, orbitSpeed: 90 };

/** The touch controls: `mirror` ones swap sides for a left-handed player (the pause button stays top right). */
const TOUCH = [
  { id: "touch_stick", comp: "TouchStick", mirror: true },
  { id: "touch_jump", comp: "TouchButton", mirror: true },
  { id: "touch_action", comp: "TouchButton", mirror: true },
  { id: "touch_pause", comp: "TouchButton", mirror: false },
];

/** Originals of the scene's entities (what the scene file says), by scene: options scale from these, never from the last result. */
const bases = new Map();

function baseOf(key, capture) {
  const k = `${scene.current}|${key}`;  if (!bases.has(k)) bases.set(k, capture());
  return bases.get(k);
}

/** The quality preset of the settings `s`. */
export function qualityOf(s) {
  return QUALITY[s.quality] ?? QUALITY.high;
}

/** True when the player wants less motion (the option, which starts from the system setting; reducedEffects is the older switch). */
export function reducedMotion(s) {
  return !!(s.reducedMotion || s.reducedEffects);
}

// --------------------------------------------------------------------------------------------------------------- quality
function applyQuality(s) {
  const q = qualityOf(s);
  if (window.supports("renderScale")) window.renderScale = q.renderScale;
  const sun = world.find("sun");
  if (sun && sun.has("Light")) sun.get("Light").castShadows = q.shadows;
  const camera = world.find("camera");
  if (camera && camera.has("Camera")) {
    const cam = camera.get("Camera");
    if (cam.projection === "perspective") {
      const b = baseOf("far", () => ({ far: cam.farPlane, fog: world.settings.fogDensity }));
      cam.farPlane = Math.max(40, b.far * q.farPlane);
      // A shorter view distance would show the far end of the level popping in: thicker fog hides it.
      world.settings.fogDensity = b.fog > 0 ? b.fog * q.fog : b.fog;
    }
  }
  // Lantern lights: keep a spread-out share (every third, two of three, all): the weak GPUs gain most from fewer lights.
  world.findByTag("lantern").forEach((lamp, i) => {
    const light = lamp.children.find((c) => c.name === "light");
    if (light) light.active = Math.floor((i + 1) * q.lights) > Math.floor(i * q.lights);
  });
}

// ------------------------------------------------------------------------------------------------------------ touch controls
function applyTouch(s) {
  const size = clamp(s.controlSize, 0.8, 1.4);
  const opacity = clamp(s.controlOpacity, 0.3, 1);
  for (const t of TOUCH) {
    const e = world.find(t.id);
    if (!e || !e.has(t.comp)) continue;
    const comp = e.get(t.comp);
    const b = baseOf(t.id, () => ({
      ax: comp.anchor.x,
      ay: comp.anchor.y,
      x: e.position.x,
      y: e.position.y,
      w: comp.size.x,
      h: comp.size.y,
      color: [...comp.color],
    }));
    const flip = !!s.leftHanded && t.mirror;
    comp.anchor = [flip ? 1 - b.ax : b.ax, b.ay];
    // The offset from the corner grows with the control, so a bigger button keeps its gap to the edge.
    e.position = [(flip ? -b.x : b.x) * size, b.y * size, e.position.z];
    comp.size = [b.w * size, b.h * size];
    comp.color = [b.color[0], b.color[1], b.color[2], b.color[3] * opacity];
  }
}

// ----------------------------------------------------------------------------------------------------------------- camera
function applyCamera(s) {
  const cam = world.find("camera")?.behaviour;
  if (!cam || typeof cam.orbit !== "function") return;
  const b = baseOf("camera", () => ({ followSmoothing: cam.followSmoothing, orbitSpeed: cam.orbitSpeed, sensitivity: cam.sensitivity }));
  const reduced = reducedMotion(s);
  cam.sensitivity = b.sensitivity * clamp(s.cameraSensitivity, 0.4, 2.5);
  cam.invertY = !!s.invertY;
  cam.followSmoothing = reduced ? Math.min(b.followSmoothing, REDUCED.followSmoothing) : b.followSmoothing;
  cam.orbitSpeed = reduced ? Math.min(b.orbitSpeed, REDUCED.orbitSpeed) : b.orbitSpeed;
}

// ------------------------------------------------------------------------------------------------------------ assist mode
function applyAssist(s) {
  const spring = world.find("spring")?.behaviour;
  if (spring) spring.drainRate = s.assist ? ASSIST.drainRate : 1;
  const courier = world.find("courier")?.behaviour;
  if (courier) {
    const b = baseOf("courier", () => ({ coyoteTime: courier.coyoteTime, jumpBuffer: courier.jumpBuffer }));
    courier.coyoteTime = s.assist ? Math.max(b.coyoteTime, ASSIST.coyoteTime) : b.coyoteTime;
    courier.jumpBuffer = s.assist ? Math.max(b.jumpBuffer, ASSIST.jumpBuffer) : b.jumpBuffer;
  }
  for (const dog of world.findByTag("dog")) {
    const d = dog.behaviour;
    if (!d) continue;
    const b = baseOf(`dog:${dog.id}`, () => ({ runSpeed: d.runSpeed, giveUpTime: d.giveUpTime, alertTime: d.alertTime }));
    d.runSpeed = s.assist ? b.runSpeed * ASSIST.dogSpeed : b.runSpeed;
    d.giveUpTime = s.assist ? b.giveUpTime * ASSIST.dogGiveUp : b.giveUpTime;
    d.alertTime = s.assist ? b.alertTime * ASSIST.dogAlert : b.alertTime;
  }
}

let reducedNow = false;

/** The reduced motion flag as of the last applyToScene(): cheap to read every frame (bobbing and spinning props use it). */
export function isReduced() {
  return reducedNow;
}

/** Puts the settings `s` into the scene's entities. */
export function applyToScene(s) {
  reducedNow = reducedMotion(s);
  applyQuality(s);
  applyTouch(s);
  applyCamera(s);
  applyAssist(s);
}

function clamp(v, lo, hi) {
  return Math.max(lo, Math.min(hi, Number.isFinite(v) ? v : 1));
}
