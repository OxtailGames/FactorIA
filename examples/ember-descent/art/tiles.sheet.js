// The dungeon tileset: frame 0 = wall, 1 = floor, 2 = cracked floor. Drawn as SVG, one frame per tile (assets.animate_svg).
const S = 32;
const wall = `<rect width="${S}" height="${S}" fill="#2b2433"/>
  <rect x="1" y="1" width="30" height="14" rx="2" fill="#3d3349"/><rect x="1" y="17" width="14" height="14" rx="2" fill="#3d3349"/>
  <rect x="17" y="17" width="14" height="14" rx="2" fill="#463b54"/><path d="M4 4h10M18 20h9" stroke="#574a68" stroke-width="2"/>`;
const floor = `<rect width="${S}" height="${S}" fill="#6b5a4a"/><rect x="1" y="1" width="30" height="30" fill="#76644f"/>
  <path d="M0 16h32M16 0v32" stroke="#6b5a4a" stroke-width="1" opacity="0.7"/>`;
const cracked = `${floor}<path d="M6 8l6 5-3 6 7 4" fill="none" stroke="#54463a" stroke-width="2" stroke-linecap="round"/>
  <circle cx="24" cy="9" r="2" fill="#5f4f40"/>`;

export default function frame({ frame }) {
  const body = [wall, floor, cracked][frame] ?? floor;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${S}" height="${S}" viewBox="0 0 ${S} ${S}">${body}</svg>`;
}
