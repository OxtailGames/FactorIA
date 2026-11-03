---
name: make-art
description: Craft guide for the game's art and its look. Read before making any art.
---

# Making the game's art

You make all of the game's art: images and textures (assets_generate_image, assets_generate_texture), SVG to PNG
(assets_rasterize_svg), sprites, sprite sheets and atlases, tilesets, UI skins, icons, the choice of fonts, 3D models
through the asset providers, and materials and the overall look (palette, lighting, post effects). Use the asset
tools, not hand-pixelled placeholders, and LOOK at what you made: take screenshots (game_screenshot) of the art in the
running game, at the real size, and fix it until it fits. Keep one art direction: palette, outline weight, perspective,
scale and resolution consistent between assets, and write the choices where the next artist finds them (the project's
art notes or REVIEW.md). Record each asset's source and license as the asset tools do.
A picture written as SVG is edited, not rewritten: vector_info lists its ids, then vector_boolean (subtract a hole, merge parts), vector_offset
(an inset or outline), vector_stroke_to_path, vector_simplify / vector_smooth, vector_align / vector_distribute / vector_repeat and vector_style; new parts come from vector_shape (star, gear, polygon, arrow, speech bubble, ribbon), vector_blob, vector_mirror (draw half, weld the whole), vector_text_to_path and vector_shade (shadow and highlight from the style's light); a character drawn in named groups (arm_upper_l, head, a head-pivot shape for a joint) becomes parts, joints and a Bone2D prefab with vector_to_rig, which you then animate (docs_read {"name":"vector"}, "Characters in parts")
(the project's outline and palette) change the file or the svg layer of an image document, keep its ids, groups and transforms, and return a picture:
docs_read {"name":"vector"}.
Pixel art that moves is one image document with frames and tags (docs_read {"name":"images"}, "Frames and tags"): draw each frame with
image_pixel / image_draw (`frame`, and `onion: true` to see the neighbouring frames), time it with image_frame_set, name its runs with
image_tag_set and the bake is a sprite sheet whose clips are the tag names, played with `SpriteAnimator {"clip": "<tag>"}`. An Aseprite
file imported with assets_import becomes such a document.
Finish pixel art with the palette-exact helpers (docs_read {"name":"images"}, "Pixel helpers"): image_pixel_outline (flat, darkest of the ramp,
or selective sel-out), image_pixel_shade (bands from the style's light), image_pixel_dither, image_pixel_cleanup (orphans, doubles, jaggies),
image_pixel_rotate (RotSprite) and image_pixel_scale; image_to_pixel_art turns a painted layer or a PNG into an indexed layer. All take
`frames: "all"` and a stored `selection`.
A character that moves is built in parts (child Sprites with pivots at the joints, bones where a limb bends, IK for feet) and
animated with the anim.* commands, then judged with anim_filmstrip and anim_check: docs_read {"name":"ai-guide","heading":"9.25.2"}.

The review loop, for every picture or set you make: make it, see it (assets_contact_sheet at its on-screen size over the game's
backgrounds, assets_preview_in_scene in a real scene), check it (assets_check_art: numbers, a verdict and a fixing hint per rule,
against the `style` rules of assets.json), fix what the hints say and repeat until no rule is `fail`. Then, if the user has a vision
model set up, assets_review gives a last look in one call (the verdict and concrete fixes, grounded on the check and the style
references; `no_model` means none is set up, so carry on without it). Write the style rules first: docs_read {"name":"assets"} "House style".
