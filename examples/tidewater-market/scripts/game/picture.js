// @ts-check
// The picture of a save slot: what the player saw when the game was saved (FB-0020), taken with render.captureTexture and kept in
// `storage` as PNG text next to the save (save_store.js, key <slot>.pic). A run with no renderer (graphics off) or a failed capture
// gives no picture, and the slot screen shows the run-length map of thumbnail.js instead, as for a save made before pictures.
//
//   takePicture()          // "iVBORw0KGgo..." (Base64 PNG, 156 x 156) or null
//   showPicture(png)       // a Texture to put on a Panel (texture.id), or null when the text is not a picture; destroy() it when done
import { render } from "factoria";

/** Pixels per side: 1.5 times the 104 px the slot screen draws, so the Panel's nearest-neighbour sampling stays sharp. */
export const PICTURE_SIZE = 156;

/**
 * The frame as the player sees it, cut to a square from the middle, as PNG text. Called during a frame it is the last drawn frame, so
 * a menu opened in this same frame is not on it (pause_menu.js takes it before the menu opens).
 * @returns {string | null}
 */
export function takePicture() {
  try {
    const tex = render.captureTexture({ width: PICTURE_SIZE, height: PICTURE_SIZE });
    try {
      return tex.placeholder ? null : tex.toPNG(); // a flat square would say nothing about the town
    } finally {
      tex.destroy(); // the PNG is all that is kept; the engine allows 32 textures at a time
    }
  } catch {
    return null;
  }
}

/**
 * @param {unknown} png the text takePicture gave
 * @returns {import("factoria").Texture | null} null: not a picture (damaged storage, a text from another game)
 */
export function showPicture(png) {
  if (typeof png !== "string" || !png) return null;
  try {
    return render.textureFromPNG(png);
  } catch {
    return null;
  }
}
