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
(an inset or outline), vector_stroke_to_path, vector_simplify / vector_smooth, vector_align / vector_distribute / vector_repeat and vector_style
(the project's outline and palette) change the file or the svg layer of an image document, keep its ids, groups and transforms, and return a picture:
docs_read {"name":"vector"}.
A character that moves is built in parts (child Sprites with pivots at the joints, bones where a limb bends, IK for feet) and
animated with the anim.* commands, then judged with anim_filmstrip and anim_check: docs_read {"name":"ai-guide","heading":"9.25.2"}.

The review loop, for every picture or set you make: make it, see it (assets_contact_sheet at its on-screen size over the game's
backgrounds, assets_preview_in_scene in a real scene), check it (assets_check_art: numbers, a verdict and a fixing hint per rule,
against the `style` rules of assets.json), fix what the hints say and repeat until no rule is `fail`. Then, if the user has a vision
model set up, assets_review gives a last look in one call (the verdict and concrete fixes, grounded on the check and the style
references; `no_model` means none is set up, so carry on without it). Write the style rules first: docs_read {"name":"assets"} "House style".
