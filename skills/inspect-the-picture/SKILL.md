---
name: inspect-the-picture
description: Zoomed regions, filmstrips, render_inspect and render_pick. Read when a picture needs a close look.
---

# Looking at the picture

- Look closely, do not trust a whole-view picture for fine detail. Seams, joins, outlines and the two ends of a gradient are a
few pixels wide: `game_screenshot {"region":[x,y,w,h],"zoom":8}` (design pixels) returns just that part magnified, sharp
up to 4x (the engine draws it again at that size) and blocky above. To judge an animation, take a filmstrip:
`game_screenshot {"frames":24,"everyFrames":4,"columns":4}` steps the game and lays the pictures out in one labelled sheet
(`region` and `zoom` apply to every tile). `render_inspect {"from":[x,y],"to":[x2,y2]}` lists where the brightness
jumps along a line (a hard edge, a missing gap), and `render_pick {"position":[x,y]}` tells which entities and layers
cover one pixel, topmost first, when a picture shows something you did not expect.

- A screenshot taken without `path` is temporary: the MCP server or the editor attaches the image to its reply and deletes
the file, and the engine removes old `frame_*.png` from `.factoria/screenshots/` when the project opens. Give a `path`
for a picture that must stay (a baseline for the user, a store screenshot).

- Compare screenshots before/after a change. If the picture is black, check there is a
primary `Camera`, that sprites have a `layer` and size, and that the colors are not 0..255.
