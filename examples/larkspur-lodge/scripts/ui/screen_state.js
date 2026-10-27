// @ts-check
// One shared flag: true while the journal (items, notebook, board) or a puzzle screen is up. scripts/screens.js sets it;
// scripts/lodge_camera.js reads it so a drag or a stick tilt that turns an item does not also orbit the lodge camera.
// (A module's state is shared by every script of the game, and survives scene loads.)
export const screenState = { open: false };
